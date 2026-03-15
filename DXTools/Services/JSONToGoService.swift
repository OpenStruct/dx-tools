import Foundation

struct JSONToGoService {

    struct Options {
        var rootName: String = "Root"
        var inlineStructs: Bool = false
        var addOmitempty: Bool = false
        var usePointers: Bool = false
    }

    static func convert(_ jsonString: String, options: Options = Options()) -> Result<String, Error> {
        guard let data = jsonString.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return .failure(ConvertError.invalidUTF8)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            var structs: [GoStruct] = []
            _ = inferType(obj, name: options.rootName, structs: &structs, options: options)

            let output = structs.reversed().map { $0.render(options: options) }.joined(separator: "\n\n")
            return .success(output)
        } catch {
            return .failure(ConvertError.invalidJSON(error.localizedDescription))
        }
    }

    // MARK: - Type Inference

    private static func inferType(_ value: Any, name: String, structs: inout [GoStruct], options: Options) -> String {
        if let dict = value as? [String: Any] {
            let structName = goTypeName(name)
            var fields: [GoField] = []

            for key in dict.keys.sorted() {
                let val = dict[key]!
                let isNull = val is NSNull
                var fieldType = inferType(val, name: key, structs: &structs, options: options)
                if isNull && options.usePointers {
                    fieldType = "*string"
                } else if isNull {
                    fieldType = "interface{}"
                }
                fields.append(GoField(
                    jsonKey: key,
                    goName: goFieldName(key),
                    goType: fieldType,
                    nullable: isNull
                ))
            }

            structs.append(GoStruct(name: structName, fields: fields))
            return structName

        } else if let arr = value as? [Any] {
            if arr.isEmpty {
                return "[]interface{}"
            }

            // Check if all elements are same type
            if let firstDict = arr.first as? [String: Any] {
                // Merge all object keys for complete struct
                var merged: [String: Any] = [:]
                var nullableKeys: Set<String> = Set(firstDict.keys)

                for item in arr {
                    if let d = item as? [String: Any] {
                        for (k, v) in d {
                            if merged[k] == nil || merged[k] is NSNull {
                                merged[k] = v
                            }
                        }
                        nullableKeys = nullableKeys.union(Set(d.keys))
                    }
                }

                // Find keys that don't appear in all items
                let allKeys = merged.keys
                var optionalKeys: Set<String> = []
                for item in arr {
                    if let d = item as? [String: Any] {
                        for key in allKeys where d[key] == nil || d[key] is NSNull {
                            optionalKeys.insert(key)
                        }
                    }
                }

                let singularName = singularize(name)
                let structName = goTypeName(singularName)
                var fields: [GoField] = []

                for key in merged.keys.sorted() {
                    let val = merged[key]!
                    var fieldType = inferType(val, name: key, structs: &structs, options: options)
                    if optionalKeys.contains(key) && options.usePointers {
                        fieldType = "*" + fieldType
                    }
                    fields.append(GoField(
                        jsonKey: key,
                        goName: goFieldName(key),
                        goType: fieldType,
                        omitempty: optionalKeys.contains(key)
                    ))
                }

                structs.append(GoStruct(name: structName, fields: fields))
                return "[]" + structName

            } else {
                // Primitive array
                let elementType = inferPrimitiveType(arr.first!)
                let allSame = arr.allSatisfy { inferPrimitiveType($0) == elementType }
                return allSame ? "[]\(elementType)" : "[]interface{}"
            }

        } else {
            return inferPrimitiveType(value)
        }
    }

    private static func inferPrimitiveType(_ value: Any) -> String {
        if value is NSNull { return "interface{}" }
        if value is String { return "string" }
        if let num = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(num) { return "bool" }
            let str = "\(num)"
            if str.contains(".") { return "float64" }
            return "int64"
        }
        return "interface{}"
    }

    // MARK: - Naming

    private static let goAbbreviations: Set<String> = [
        "id", "url", "api", "http", "https", "html", "json", "xml", "sql",
        "ssh", "tcp", "udp", "ip", "dns", "tls", "ssl", "uuid", "eof",
        "os", "cpu", "gpu", "ram", "uri", "uid", "pid", "ttl", "jwt", "oauth"
    ]

    static func goFieldName(_ jsonKey: String) -> String {
        let parts = splitWords(jsonKey)
        return parts.map { part in
            let lower = part.lowercased()
            if goAbbreviations.contains(lower) {
                return lower.uppercased()
            }
            return part.prefix(1).uppercased() + part.dropFirst()
        }.joined()
    }

    static func goTypeName(_ name: String) -> String {
        goFieldName(name)
    }

    private static func splitWords(_ str: String) -> [String] {
        // Handle snake_case, camelCase, kebab-case
        var result: [String] = []
        var current = ""

        let replaced = str
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: ".", with: " ")

        for char in replaced {
            if char == " " {
                if !current.isEmpty { result.append(current); current = "" }
            } else if char.isUppercase && !current.isEmpty && current.last?.isUppercase == false {
                result.append(current)
                current = String(char)
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private static func singularize(_ word: String) -> String {
        let lower = word.lowercased()
        if lower.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if lower.hasSuffix("ses") || lower.hasSuffix("xes") || lower.hasSuffix("zes") {
            return String(word.dropLast(2))
        }
        if lower.hasSuffix("s") && !lower.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    // MARK: - Types

    struct GoStruct {
        let name: String
        let fields: [GoField]

        func render(options: Options) -> String {
            let maxNameLen = fields.map(\.goName.count).max() ?? 0
            let maxTypeLen = fields.map(\.goType.count).max() ?? 0

            var lines = ["type \(name) struct {"]
            for field in fields {
                let paddedName = field.goName.padding(toLength: maxNameLen, withPad: " ", startingAt: 0)
                var displayType = field.goType
                if options.usePointers && field.nullable && !displayType.hasPrefix("*") {
                    displayType = "*" + displayType
                }
                let paddedType = displayType.padding(toLength: maxTypeLen, withPad: " ", startingAt: 0)
                var tag = field.jsonKey
                if options.addOmitempty || field.omitempty {
                    tag += ",omitempty"
                }
                lines.append("\t\(paddedName) \(paddedType) `json:\"\(tag)\"`")
            }
            lines.append("}")
            return lines.joined(separator: "\n")
        }
    }

    struct GoField {
        let jsonKey: String
        let goName: String
        let goType: String
        var omitempty: Bool = false
        var nullable: Bool = false
    }

    enum ConvertError: LocalizedError {
        case invalidUTF8
        case invalidJSON(String)

        var errorDescription: String? {
            switch self {
            case .invalidUTF8: return "Input is not valid UTF-8"
            case .invalidJSON(let msg): return msg
            }
        }
    }
}

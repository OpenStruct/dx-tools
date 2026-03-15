import Foundation

struct JSONToSwiftService {

    struct Options {
        var rootName: String = "Root"
        var useLetProperties: Bool = true
        var addCodingKeys: Bool = false
        var optionalNulls: Bool = true
    }

    static func convert(_ jsonString: String, options: Options = Options()) -> Result<String, Error> {
        guard let data = jsonString.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return .failure(ConvertError.invalidUTF8)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            var structs: [SwiftStruct] = []
            _ = inferType(obj, name: options.rootName, structs: &structs, options: options)

            let header = "import Foundation\n"
            let body = structs.reversed().map { $0.render(options: options) }.joined(separator: "\n\n")
            return .success(header + "\n" + body)
        } catch {
            return .failure(ConvertError.invalidJSON(error.localizedDescription))
        }
    }

    private static func inferType(_ value: Any, name: String, structs: inout [SwiftStruct], options: Options) -> String {
        if let dict = value as? [String: Any] {
            let structName = swiftTypeName(name)
            var props: [SwiftProperty] = []

            for key in dict.keys.sorted() {
                let val = dict[key]!
                let propType = inferType(val, name: key, structs: &structs, options: options)
                let isNull = val is NSNull
                props.append(SwiftProperty(
                    jsonKey: key,
                    swiftName: swiftPropertyName(key),
                    swiftType: isNull && options.optionalNulls ? propType + "?" : propType,
                    isOptional: isNull
                ))
            }

            structs.append(SwiftStruct(name: structName, properties: props))
            return structName

        } else if let arr = value as? [Any] {
            if arr.isEmpty { return "[Any]" }

            if arr.first is [String: Any] {
                var merged: [String: Any] = [:]
                for item in arr {
                    if let d = item as? [String: Any] {
                        for (k, v) in d where merged[k] == nil || merged[k] is NSNull {
                            merged[k] = v
                        }
                    }
                }
                let singular = singularize(name)
                let type = inferType(merged, name: singular, structs: &structs, options: options)
                return "[\(type)]"
            } else {
                let elementType = inferPrimitiveType(arr.first!)
                return "[\(elementType)]"
            }

        } else {
            return inferPrimitiveType(value)
        }
    }

    private static func inferPrimitiveType(_ value: Any) -> String {
        if value is NSNull { return "Any" }
        if value is String { return "String" }
        if let num = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(num) { return "Bool" }
            let str = "\(num)"
            if str.contains(".") { return "Double" }
            return "Int" 
        }
        return "Any"
    }

    private static func swiftTypeName(_ name: String) -> String {
        let parts = splitWords(name)
        return parts.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }

    private static func swiftPropertyName(_ name: String) -> String {
        let parts = splitWords(name)
        guard let first = parts.first else { return name }
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return first.lowercased() + rest.joined()
    }

    private static func splitWords(_ str: String) -> [String] {
        var result: [String] = []
        var current = ""
        let replaced = str
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        for char in replaced {
            if char == " " {
                if !current.isEmpty { result.append(current); current = "" }
            } else if char.isUppercase && !current.isEmpty && current.last?.isUppercase == false {
                result.append(current); current = String(char)
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
        if lower.hasSuffix("ses") || lower.hasSuffix("xes") { return String(word.dropLast(2)) }
        if lower.hasSuffix("s") && !lower.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    struct SwiftStruct {
        let name: String
        let properties: [SwiftProperty]

        func render(options: Options) -> String {
            let keyword = options.useLetProperties ? "let" : "var"
            var lines = ["struct \(name): Codable {"]
            for prop in properties {
                lines.append("    \(keyword) \(prop.swiftName): \(prop.swiftType)")
            }

            if options.addCodingKeys {
                let needsCodingKeys = properties.contains { $0.jsonKey != $0.swiftName }
                if needsCodingKeys {
                    lines.append("")
                    lines.append("    enum CodingKeys: String, CodingKey {")
                    for prop in properties {
                        if prop.jsonKey == prop.swiftName {
                            lines.append("        case \(prop.swiftName)")
                        } else {
                            lines.append("        case \(prop.swiftName) = \"\(prop.jsonKey)\"")
                        }
                    }
                    lines.append("    }")
                }
            }

            lines.append("}")
            return lines.joined(separator: "\n")
        }
    }

    struct SwiftProperty {
        let jsonKey: String
        let swiftName: String
        let swiftType: String
        let isOptional: Bool
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

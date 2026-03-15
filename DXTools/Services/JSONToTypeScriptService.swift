import Foundation

struct JSONToTypeScriptService {

    struct Options {
        var rootName: String = "Root"
        var useInterface: Bool = true  // interface vs type
        var readOnly: Bool = false
    }

    static func convert(_ jsonString: String, options: Options = Options()) -> Result<String, Error> {
        guard let data = jsonString.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return .failure(ConvertError.invalidUTF8)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            var interfaces: [TSInterface] = []
            _ = inferType(obj, name: options.rootName, interfaces: &interfaces, options: options)

            let output = interfaces.reversed().map { $0.render(options: options) }.joined(separator: "\n\n")
            return .success(output)
        } catch {
            return .failure(ConvertError.invalidJSON(error.localizedDescription))
        }
    }

    private static func inferType(_ value: Any, name: String, interfaces: inout [TSInterface], options: Options) -> String {
        if let dict = value as? [String: Any] {
            let typeName = tsTypeName(name)
            var props: [TSProperty] = []

            for key in dict.keys.sorted() {
                let val = dict[key]!
                let propType = inferType(val, name: key, interfaces: &interfaces, options: options)
                props.append(TSProperty(
                    name: key,
                    type: val is NSNull ? propType + " | null" : propType,
                    optional: val is NSNull
                ))
            }

            interfaces.append(TSInterface(name: typeName, properties: props))
            return typeName

        } else if let arr = value as? [Any] {
            if arr.isEmpty { return "any[]" }

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
                let type = inferType(merged, name: singular, interfaces: &interfaces, options: options)
                return "\(type)[]"
            } else {
                let elementType = inferPrimitiveType(arr.first!)
                return "\(elementType)[]"
            }

        } else {
            return inferPrimitiveType(value)
        }
    }

    private static func inferPrimitiveType(_ value: Any) -> String {
        if value is NSNull { return "any" }
        if value is String { return "string" }
        if let num = value as? NSNumber {
            if CFBooleanGetTypeID() == CFGetTypeID(num) { return "boolean" }
            return "number"
        }
        return "any"
    }

    private static func tsTypeName(_ name: String) -> String {
        let parts = splitWords(name)
        return parts.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
    }

    private static func splitWords(_ str: String) -> [String] {
        var result: [String] = []
        var current = ""
        let replaced = str.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ")
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
        if lower.hasSuffix("s") && !lower.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    struct TSInterface {
        let name: String
        let properties: [TSProperty]

        func render(options: Options) -> String {
            let keyword = options.useInterface ? "interface" : "type"
            let readonly = options.readOnly ? "readonly " : ""
            let eq = options.useInterface ? "" : " ="
            var lines = ["export \(keyword) \(name)\(eq) {"]
            for prop in properties {
                let opt = prop.optional ? "?" : ""
                lines.append("  \(readonly)\(prop.name)\(opt): \(prop.type);")
            }
            lines.append("}")
            return lines.joined(separator: "\n")
        }
    }

    struct TSProperty {
        let name: String
        let type: String
        let optional: Bool
    }

    enum ConvertError: LocalizedError {
        case invalidUTF8
        case invalidJSON(String)
        var errorDescription: String? {
            switch self {
            case .invalidUTF8: return "Invalid UTF-8"
            case .invalidJSON(let msg): return msg
            }
        }
    }
}

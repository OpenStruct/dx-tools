import Foundation

struct JSONSchemaService {
    struct ValidationResult {
        let isValid: Bool
        let errors: [String]
    }

    static func validate(json jsonString: String, against schemaString: String) -> ValidationResult {
        guard let jsonData = jsonString.data(using: .utf8),
              let schemaData = schemaString.data(using: .utf8) else {
            return ValidationResult(isValid: false, errors: ["Invalid input encoding"])
        }

        let json: Any
        let schema: [String: Any]
        do {
            json = try JSONSerialization.jsonObject(with: jsonData)
            guard let s = try JSONSerialization.jsonObject(with: schemaData) as? [String: Any] else {
                return ValidationResult(isValid: false, errors: ["Schema must be a JSON object"])
            }
            schema = s
        } catch {
            return ValidationResult(isValid: false, errors: ["Parse error: \(error.localizedDescription)"])
        }

        var errors: [String] = []
        validateValue(json, against: schema, path: "$", errors: &errors)
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    private static func validateValue(_ value: Any, against schema: [String: Any], path: String, errors: inout [String]) {
        // Type check
        if let type = schema["type"] as? String {
            if !checkType(value, expected: type) {
                errors.append("\(path): expected type '\(type)', got '\(jsonType(value))'")
                return
            }
        }

        // Object validation
        if let obj = value as? [String: Any] {
            // Required fields
            if let required = schema["required"] as? [String] {
                for key in required {
                    if obj[key] == nil {
                        errors.append("\(path): missing required property '\(key)'")
                    }
                }
            }
            // Properties
            if let properties = schema["properties"] as? [String: [String: Any]] {
                for (key, propSchema) in properties {
                    if let propValue = obj[key] {
                        validateValue(propValue, against: propSchema, path: "\(path).\(key)", errors: &errors)
                    }
                }
            }
            // Min/max properties
            if let minProps = schema["minProperties"] as? Int, obj.count < minProps {
                errors.append("\(path): object has \(obj.count) properties, minimum is \(minProps)")
            }
            if let maxProps = schema["maxProperties"] as? Int, obj.count > maxProps {
                errors.append("\(path): object has \(obj.count) properties, maximum is \(maxProps)")
            }
        }

        // Array validation
        if let arr = value as? [Any] {
            if let items = schema["items"] as? [String: Any] {
                for (i, item) in arr.enumerated() {
                    validateValue(item, against: items, path: "\(path)[\(i)]", errors: &errors)
                }
            }
            if let minItems = schema["minItems"] as? Int, arr.count < minItems {
                errors.append("\(path): array has \(arr.count) items, minimum is \(minItems)")
            }
            if let maxItems = schema["maxItems"] as? Int, arr.count > maxItems {
                errors.append("\(path): array has \(arr.count) items, maximum is \(maxItems)")
            }
        }

        // String validation
        if let str = value as? String {
            if let minLen = schema["minLength"] as? Int, str.count < minLen {
                errors.append("\(path): string length \(str.count) is less than minimum \(minLen)")
            }
            if let maxLen = schema["maxLength"] as? Int, str.count > maxLen {
                errors.append("\(path): string length \(str.count) exceeds maximum \(maxLen)")
            }
            if let pattern = schema["pattern"] as? String {
                if (try? NSRegularExpression(pattern: pattern))?.firstMatch(in: str, range: NSRange(str.startIndex..., in: str)) == nil {
                    errors.append("\(path): string does not match pattern '\(pattern)'")
                }
            }
            if let enumValues = schema["enum"] as? [String], !enumValues.contains(str) {
                errors.append("\(path): value '\(str)' not in enum \(enumValues)")
            }
        }

        // Number validation
        if let num = value as? NSNumber, !(value is Bool) {
            let d = num.doubleValue
            if let minimum = schema["minimum"] as? Double, d < minimum {
                errors.append("\(path): value \(d) is less than minimum \(minimum)")
            }
            if let maximum = schema["maximum"] as? Double, d > maximum {
                errors.append("\(path): value \(d) exceeds maximum \(maximum)")
            }
        }
    }

    private static func checkType(_ value: Any, expected: String) -> Bool {
        switch expected {
        case "object": return value is [String: Any]
        case "array": return value is [Any]
        case "string": return value is String
        case "number": return (value is NSNumber) && !(value is Bool)
        case "integer":
            if let n = value as? NSNumber, !(value is Bool) {
                return n.doubleValue == Double(n.intValue)
            }
            return false
        case "boolean": return value is Bool
        case "null": return value is NSNull
        default: return true
        }
    }

    private static func jsonType(_ value: Any) -> String {
        if value is [String: Any] { return "object" }
        if value is [Any] { return "array" }
        if value is String { return "string" }
        if value is Bool { return "boolean" }
        if value is NSNumber { return "number" }
        if value is NSNull { return "null" }
        return "unknown"
    }
}

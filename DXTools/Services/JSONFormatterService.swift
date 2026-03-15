import Foundation

struct JSONFormatterService {

    enum IndentStyle: String, CaseIterable {
        case twoSpaces = "2 Spaces"
        case fourSpaces = "4 Spaces"
        case tabs = "Tabs"

        var indent: String {
            switch self {
            case .twoSpaces: return "  "
            case .fourSpaces: return "    "
            case .tabs: return "\t"
            }
        }
    }

    static func format(_ input: String, indent: IndentStyle = .twoSpaces) -> Result<String, FormatError> {
        guard let data = input.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return .failure(.invalidUTF8)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let prettyData = try JSONSerialization.data(
                withJSONObject: obj,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            guard var result = String(data: prettyData, encoding: .utf8) else {
                return .failure(.encodingFailed)
            }

            // Apply custom indent if not default 4-space
            if indent != .fourSpaces {
                result = result.replacingOccurrences(
                    of: "    ",
                    with: indent.indent
                )
            }
            return .success(result)
        } catch {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }

    static func minify(_ input: String) -> Result<String, FormatError> {
        guard let data = input.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return .failure(.invalidUTF8)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            let miniData = try JSONSerialization.data(
                withJSONObject: obj,
                options: [.withoutEscapingSlashes]
            )
            guard let result = String(data: miniData, encoding: .utf8) else {
                return .failure(.encodingFailed)
            }
            return .success(result)
        } catch {
            return .failure(.invalidJSON(error.localizedDescription))
        }
    }

    static func validate(_ input: String) -> ValidationResult {
        guard let data = input.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8) else {
            return ValidationResult(valid: false, error: "Invalid UTF-8 encoding", type: nil, count: nil, size: 0)
        }

        do {
            let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
            if let dict = obj as? [String: Any] {
                return ValidationResult(valid: true, error: nil, type: "Object", count: dict.count, size: data.count)
            } else if let arr = obj as? [Any] {
                return ValidationResult(valid: true, error: nil, type: "Array", count: arr.count, size: data.count)
            }
            return ValidationResult(valid: true, error: nil, type: "Value", count: nil, size: data.count)
        } catch {
            return ValidationResult(valid: false, error: error.localizedDescription, type: nil, count: nil, size: data.count)
        }
    }

    enum FormatError: LocalizedError {
        case invalidUTF8
        case invalidJSON(String)
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .invalidUTF8: return "Input is not valid UTF-8"
            case .invalidJSON(let msg): return msg
            case .encodingFailed: return "Failed to encode output"
            }
        }
    }

    struct ValidationResult {
        let valid: Bool
        let error: String?
        let type: String?
        let count: Int?
        let size: Int
    }
}

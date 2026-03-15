import Foundation

struct Base64Service {

    static func encode(_ input: String, urlSafe: Bool = false) -> String {
        let data = Data(input.utf8)
        return encodeData(data, urlSafe: urlSafe)
    }

    static func encodeData(_ data: Data, urlSafe: Bool = false) -> String {
        var encoded = data.base64EncodedString()
        if urlSafe {
            encoded = encoded
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
        return encoded
    }

    static func decode(_ input: String) -> Result<Data, Error> {
        var raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = 4 - raw.count % 4
        if pad < 4 { raw += String(repeating: "=", count: pad) }

        guard let data = Data(base64Encoded: raw) else {
            return .failure(Base64Error.invalidInput)
        }
        return .success(data)
    }

    static func decodeToString(_ input: String) -> Result<String, Error> {
        switch decode(input) {
        case .success(let data):
            if let str = String(data: data, encoding: .utf8) {
                return .success(str)
            }
            return .failure(Base64Error.notUTF8)
        case .failure(let err):
            return .failure(err)
        }
    }

    enum Base64Error: LocalizedError {
        case invalidInput
        case notUTF8
        var errorDescription: String? {
            switch self {
            case .invalidInput: return "Invalid Base64 input"
            case .notUTF8: return "Decoded data is not valid UTF-8 text"
            }
        }
    }
}

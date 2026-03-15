import Foundation

struct JWTService {

    struct DecodedJWT {
        let headerJSON: String
        let payloadJSON: String
        let signature: String
        let claims: [String: String]
        let expirationStatus: ExpirationStatus?
    }

    enum ExpirationStatus {
        case valid(remaining: String, expiresAt: Date)
        case expired(ago: String, expiredAt: Date)
    }

    static func decode(_ token: String) -> Result<DecodedJWT, Error> {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: ".")

        guard parts.count >= 2 else {
            return .failure(JWTError.invalidFormat)
        }

        guard let headerData = base64URLDecode(parts[0]),
              let headerObj = try? JSONSerialization.jsonObject(with: headerData),
              let headerPretty = try? JSONSerialization.data(withJSONObject: headerObj, options: [.prettyPrinted, .sortedKeys]),
              let headerStr = String(data: headerPretty, encoding: .utf8) else {
            return .failure(JWTError.invalidHeader)
        }

        guard let payloadData = base64URLDecode(parts[1]),
              let payloadObj = try? JSONSerialization.jsonObject(with: payloadData),
              let payloadPretty = try? JSONSerialization.data(withJSONObject: payloadObj, options: [.prettyPrinted, .sortedKeys]),
              let payloadStr = String(data: payloadPretty, encoding: .utf8) else {
            return .failure(JWTError.invalidPayload)
        }

        let signature = parts.count >= 3 ? parts[2] : ""

        // Extract claims
        var claims: [String: String] = [:]
        var expirationStatus: ExpirationStatus? = nil

        if let dict = payloadObj as? [String: Any] {
            if let sub = dict["sub"] as? String { claims["Subject"] = sub }
            if let iss = dict["iss"] as? String { claims["Issuer"] = iss }
            if let aud = dict["aud"] as? String { claims["Audience"] = aud }
            if let name = dict["name"] as? String { claims["Name"] = name }
            if let email = dict["email"] as? String { claims["Email"] = email }

            if let iat = dict["iat"] as? Double {
                claims["Issued At"] = formatDate(Date(timeIntervalSince1970: iat))
            }

            if let exp = dict["exp"] as? Double {
                let expDate = Date(timeIntervalSince1970: exp)
                claims["Expires At"] = formatDate(expDate)

                if expDate > Date() {
                    let remaining = formatDuration(expDate.timeIntervalSince(Date()))
                    expirationStatus = .valid(remaining: remaining, expiresAt: expDate)
                } else {
                    let ago = formatDuration(Date().timeIntervalSince(expDate))
                    expirationStatus = .expired(ago: ago, expiredAt: expDate)
                }
            }

            if let nbf = dict["nbf"] as? Double {
                claims["Not Before"] = formatDate(Date(timeIntervalSince1970: nbf))
            }
        }

        if let headerDict = headerObj as? [String: Any] {
            if let alg = headerDict["alg"] as? String { claims["Algorithm"] = alg }
            if let typ = headerDict["typ"] as? String { claims["Type"] = typ }
        }

        return .success(DecodedJWT(
            headerJSON: headerStr,
            payloadJSON: payloadStr,
            signature: signature,
            claims: claims,
            expirationStatus: expirationStatus
        ))
    }

    private static func base64URLDecode(_ str: String) -> Data? {
        var base64 = str
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = 4 - base64.count % 4
        if pad < 4 { base64 += String(repeating: "=", count: pad) }
        return Data(base64Encoded: base64)
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        f.timeZone = .current
        return f.string(from: date)
    }

    private static func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let days = total / 86400
        let hours = (total % 86400) / 3600
        let mins = (total % 3600) / 60
        var parts: [String] = []
        if days > 0 { parts.append("\(days)d") }
        if hours > 0 { parts.append("\(hours)h") }
        if mins > 0 { parts.append("\(mins)m") }
        return parts.isEmpty ? "<1m" : parts.joined(separator: " ")
    }

    enum JWTError: LocalizedError {
        case invalidFormat
        case invalidHeader
        case invalidPayload

        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "Invalid JWT format — expected 3 parts separated by '.'"
            case .invalidHeader: return "Could not decode JWT header"
            case .invalidPayload: return "Could not decode JWT payload"
            }
        }
    }
}

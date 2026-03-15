import ArgumentParser
import Foundation

struct JWTCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "jwt",
        abstract: "Decode & inspect JWT tokens"
    )
    
    @Argument(help: "JWT token string")
    var token: String?
    
    func run() throws {
        guard let token = token ?? readAllStdin()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            print(Style.error("No token provided"))
            throw ExitCode.failure
        }
        
        let parts = token.components(separatedBy: ".")
        guard parts.count >= 2 else {
            print(Style.error("Invalid JWT format — expected 3 parts separated by '.'"))
            throw ExitCode.failure
        }
        
        print(Style.header("🔓", "jwt decode"))
        
        // Header
        if let headerData = base64URLDecode(parts[0]),
           let headerObj = try? JSONSerialization.jsonObject(with: headerData),
           let headerPretty = try? JSONSerialization.data(withJSONObject: headerObj, options: .prettyPrinted),
           let headerStr = String(data: headerPretty, encoding: .utf8) {
            print("\n  \(Style.blue)\(Style.bold)HEADER\(Style.reset)")
            print(colorizeJSON(headerStr).split(separator: "\n").map { "  \($0)" }.joined(separator: "\n"))
        }
        
        // Payload
        if let payloadData = base64URLDecode(parts[1]),
           let payloadObj = try? JSONSerialization.jsonObject(with: payloadData),
           let payloadPretty = try? JSONSerialization.data(withJSONObject: payloadObj, options: [.prettyPrinted, .sortedKeys]),
           let payloadStr = String(data: payloadPretty, encoding: .utf8) {
            print("\n  \(Style.green)\(Style.bold)PAYLOAD\(Style.reset)")
            print(colorizeJSON(payloadStr).split(separator: "\n").map { "  \($0)" }.joined(separator: "\n"))
            
            // Check expiration
            if let dict = payloadObj as? [String: Any] {
                print("  \(Style.gray)───\(Style.reset)")
                
                if let exp = dict["exp"] as? Double {
                    let expDate = Date(timeIntervalSince1970: exp)
                    let now = Date()
                    let isExpired = expDate < now
                    let icon = isExpired ? "\(Style.red)⏰ EXPIRED" : "\(Style.green)✓ VALID"
                    print("  \(icon)\(Style.reset)")
                    print(Style.label("  Expires", formatDate(expDate)))
                    if isExpired {
                        let ago = RelativeDateTimeFormatter()
                        ago.unitsStyle = .full
                        print(Style.label("  Expired", ago.localizedString(for: expDate, relativeTo: now)))
                    } else {
                        let remaining = expDate.timeIntervalSince(now)
                        print(Style.label("  Remaining", formatDuration(remaining)))
                    }
                }
                
                if let iat = dict["iat"] as? Double {
                    print(Style.label("  Issued", formatDate(Date(timeIntervalSince1970: iat))))
                }
                
                if let sub = dict["sub"] as? String {
                    print(Style.label("  Subject", sub))
                }
                
                if let iss = dict["iss"] as? String {
                    print(Style.label("  Issuer", iss))
                }
            }
        }
        
        // Signature
        if parts.count >= 3 {
            print("\n  \(Style.magenta)\(Style.bold)SIGNATURE\(Style.reset)")
            let sig = parts[2]
            let truncated = sig.count > 40 ? String(sig.prefix(40)) + "..." : sig
            print("  \(Style.gray)\(truncated)\(Style.reset)")
        }
        
        print()
    }
}

func base64URLDecode(_ str: String) -> Data? {
    var base64 = str
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let pad = 4 - base64.count % 4
    if pad < 4 {
        base64 += String(repeating: "=", count: pad)
    }
    return Data(base64Encoded: base64)
}

func formatDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
    f.timeZone = .current
    return f.string(from: date)
}

func formatDuration(_ interval: TimeInterval) -> String {
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

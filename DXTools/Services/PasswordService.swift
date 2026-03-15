import Foundation
import Security

struct PasswordService {

    enum Strength: String {
        case weak = "Weak"
        case good = "Good"
        case strong = "Strong"

        var icon: String {
            switch self {
            case .weak: return "●○○"
            case .good: return "●●○"
            case .strong: return "●●●"
            }
        }
    }

    static func generatePassword(length: Int = 24, includeSpecial: Bool = true) -> String {
        let charset = includeSpecial
            ? "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
            : "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let chars = Array(charset)
        var password = ""
        for _ in 0..<length {
            var byte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
            password.append(chars[Int(byte) % chars.count])
        }
        return password
    }

    static func generatePassphrase(wordCount: Int = 4) -> String {
        let words = [
            "anchor", "breeze", "canyon", "drift", "ember", "frost", "grove", "haven",
            "ivory", "jasper", "karma", "lotus", "maple", "noble", "ocean", "prism",
            "quest", "river", "storm", "timber", "ultra", "vivid", "wander", "xenon",
            "yield", "zenith", "amber", "blaze", "coral", "delta", "eagle", "flame",
            "glint", "hover", "insight", "jewel", "kindle", "lunar", "mystic", "nexus",
            "orbit", "pulse", "quartz", "radiant", "solar", "throne", "unity", "vertex",
            "whisper", "pixel", "cipher", "beacon", "cobalt", "dusk", "echo", "forge",
            "galaxy", "harbor", "iron", "jade", "knight", "latch", "mirror", "nimbus",
            "onyx", "phantom", "quiver", "rustic", "shadow", "titan", "umbra", "vapor",
            "willow", "zephyr", "atlas", "bolt", "crest", "dome", "flux", "glyph",
            "haze", "ignite", "jungle", "keen", "lance", "magnet", "north", "opal",
            "plume", "reign", "spark", "trail", "vault", "wave", "arctic", "bloom",
            "chrome", "dawn", "flare", "granite", "horizon", "inferno", "keystone", "legend",
        ]

        let separators = ["-", ".", "_", "+"]
        var sepByte: UInt8 = 0
        _ = SecRandomCopyBytes(kSecRandomDefault, 1, &sepByte)
        let sep = separators[Int(sepByte) % separators.count]

        var selected: [String] = []
        for _ in 0..<wordCount {
            var byte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
            selected.append(words[Int(byte) % words.count])
        }
        return selected.joined(separator: sep)
    }

    static func evaluateStrength(_ password: String) -> Strength {
        var score = 0
        if password.count >= 12 { score += 1 }
        if password.count >= 20 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil { score += 1 }

        switch score {
        case 0...2: return .weak
        case 3...4: return .good
        default: return .strong
        }
    }
}

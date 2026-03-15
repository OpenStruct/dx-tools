import ArgumentParser
import Foundation

struct PassCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pass",
        abstract: "Generate strong passwords & passphrases"
    )
    
    @Option(name: .shortAndLong, help: "Password length")
    var length: Int = 24
    
    @Option(name: .shortAndLong, help: "Number of passwords to generate")
    var count: Int = 5
    
    @Flag(name: .long, help: "No special characters")
    var alphanumeric: Bool = false
    
    @Flag(name: .long, help: "Generate passphrase instead")
    var phrase: Bool = false
    
    @Option(name: .long, help: "Number of words in passphrase")
    var words: Int = 4
    
    func run() {
        print(Style.header("🔑", "pass"))
        print()
        
        if phrase {
            print("  \(Style.dim)Passphrases (\(words) words):\(Style.reset)")
            print("  \(Style.gray)───\(Style.reset)")
            for _ in 0..<count {
                let passphrase = generatePassphrase(wordCount: words)
                print("  \(Style.yellow)\(passphrase)\(Style.reset)")
            }
        } else {
            let charset = alphanumeric ? "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" :
                "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
            
            print("  \(Style.dim)\(length) chars · \(alphanumeric ? "alphanumeric" : "full charset")\(Style.reset)")
            print("  \(Style.gray)───\(Style.reset)")
            
            for _ in 0..<count {
                let password = generatePassword(length: length, charset: charset)
                let strength = passwordStrength(password)
                print("  \(Style.yellow)\(password)\(Style.reset)  \(strength)")
            }
        }
        
        print()
        print("  \(Style.dim)💡 Tip: Use \(Style.reset)\(Style.blue)dx pass | pbcopy\(Style.reset)\(Style.dim) to copy to clipboard\(Style.reset)")
        print()
    }
    
    func generatePassword(length: Int, charset: String) -> String {
        let chars = Array(charset)
        var password = ""
        for _ in 0..<length {
            var randomByte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
            password.append(chars[Int(randomByte) % chars.count])
        }
        return password
    }
    
    func generatePassphrase(wordCount: Int) -> String {
        let wordList = [
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
        
        var words: [String] = []
        for _ in 0..<wordCount {
            var randomByte: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)
            words.append(wordList[Int(randomByte) % wordList.count])
        }
        
        let separators = ["-", ".", "_", "+"]
        var sepByte: UInt8 = 0
        _ = SecRandomCopyBytes(kSecRandomDefault, 1, &sepByte)
        let sep = separators[Int(sepByte) % separators.count]
        
        return words.joined(separator: sep)
    }
    
    func passwordStrength(_ password: String) -> String {
        var score = 0
        if password.count >= 12 { score += 1 }
        if password.count >= 20 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil { score += 1 }
        
        switch score {
        case 0...2: return "\(Style.red)● weak\(Style.reset)"
        case 3...4: return "\(Style.yellow)●● good\(Style.reset)"
        default: return "\(Style.green)●●● strong\(Style.reset)"
        }
    }
}

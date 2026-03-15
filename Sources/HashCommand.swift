import ArgumentParser
import Foundation
import CryptoKit

struct HashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hash",
        abstract: "Hash strings & files (MD5, SHA1, SHA256, SHA512)"
    )
    
    @Argument(help: "String to hash, or file path")
    var input: String?
    
    @Option(name: .shortAndLong, help: "Algorithm: md5, sha1, sha256, sha512 (default: all)")
    var algo: String?
    
    func run() throws {
        guard let raw = input ?? readAllStdin()?.trimmingCharacters(in: .newlines) else {
            print(Style.error("No input. Pass a string, file path, or pipe via stdin"))
            throw ExitCode.failure
        }
        
        let data: Data
        let source: String
        if FileManager.default.fileExists(atPath: raw) {
            data = try Data(contentsOf: URL(fileURLWithPath: raw))
            source = "file: \(raw) (\(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)))"
        } else {
            data = Data(raw.utf8)
            source = "string: \"\(raw.prefix(50))\(raw.count > 50 ? "..." : "")\""
        }
        
        print(Style.header("🔐", "hash"))
        print(Style.label("Input", source))
        print("  \(Style.gray)───\(Style.reset)")
        
        let hashes: [(String, String)] = [
            ("MD5", Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("SHA1", Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("SHA256", SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()),
            ("SHA512", SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()),
        ]
        
        for (name, hash) in hashes {
            if let a = algo {
                if name.lowercased() == a.lowercased() {
                    print(Style.label(name.padding(toLength: 6, withPad: " ", startingAt: 0), "\(Style.yellow)\(hash)\(Style.reset)"))
                }
            } else {
                print(Style.label(name.padding(toLength: 6, withPad: " ", startingAt: 0), "\(Style.yellow)\(hash)\(Style.reset)"))
            }
        }
        print()
    }
}

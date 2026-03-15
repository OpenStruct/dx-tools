import ArgumentParser
import Foundation

struct Base64Command: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "base64",
        abstract: "Encode & decode Base64",
        subcommands: [Encode.self, Decode.self],
        defaultSubcommand: Encode.self
    )
    
    struct Encode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Encode to Base64")
        
        @Argument(help: "String or file path to encode")
        var input: String?
        
        @Flag(name: .shortAndLong, help: "URL-safe encoding")
        var urlSafe: Bool = false
        
        func run() throws {
            guard let raw = input ?? readAllStdin() else {
                print(Style.error("No input"))
                throw ExitCode.failure
            }
            
            let data: Data
            let source: String
            if FileManager.default.fileExists(atPath: raw) {
                data = try Data(contentsOf: URL(fileURLWithPath: raw))
                source = raw
            } else {
                data = Data(raw.utf8)
                source = "string"
            }
            
            var encoded = data.base64EncodedString()
            if urlSafe {
                encoded = encoded
                    .replacingOccurrences(of: "+", with: "-")
                    .replacingOccurrences(of: "/", with: "_")
                    .replacingOccurrences(of: "=", with: "")
            }
            
            print(Style.header("📦", "base64 encode"))
            print(Style.label("Source", source))
            print(Style.label("Size", "\(data.count) bytes → \(encoded.count) chars"))
            print("  \(Style.gray)───\(Style.reset)")
            print("  \(Style.green)\(encoded)\(Style.reset)")
            print()
        }
    }
    
    struct Decode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Decode from Base64")
        
        @Argument(help: "Base64 string to decode")
        var input: String?
        
        @Option(name: .shortAndLong, help: "Save decoded output to file")
        var output: String?
        
        func run() throws {
            guard var raw = (input ?? readAllStdin())?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                print(Style.error("No input"))
                throw ExitCode.failure
            }
            
            // Handle URL-safe base64
            raw = raw
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let pad = 4 - raw.count % 4
            if pad < 4 { raw += String(repeating: "=", count: pad) }
            
            guard let data = Data(base64Encoded: raw) else {
                print(Style.error("Invalid Base64 input"))
                throw ExitCode.failure
            }
            
            print(Style.header("📦", "base64 decode"))
            print(Style.label("Size", "\(raw.count) chars → \(data.count) bytes"))
            
            if let output = output {
                try data.write(to: URL(fileURLWithPath: output))
                print(Style.success("Saved to \(output)"))
            } else if let str = String(data: data, encoding: .utf8) {
                print("  \(Style.gray)───\(Style.reset)")
                print("  \(Style.green)\(str)\(Style.reset)")
            } else {
                print("  \(Style.dim)Binary data (\(data.count) bytes) — use -o to save\(Style.reset)")
            }
            print()
        }
    }
}

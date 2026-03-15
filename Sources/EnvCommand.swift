import ArgumentParser
import Foundation

struct EnvCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "env",
        abstract: "Manage .env files — view, diff, validate",
        subcommands: [View.self, Diff.self, Validate.self, Merge.self],
        defaultSubcommand: View.self
    )
    
    struct View: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "View .env file with masked secrets")
        
        @Argument(help: "Path to .env file")
        var file: String = ".env"
        
        @Flag(name: .shortAndLong, help: "Show actual values (unmask)")
        var reveal: Bool = false
        
        func run() throws {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let entries = parseEnv(content)
            
            print(Style.header("⚙️", "env view"))
            print(Style.label("File", file))
            print(Style.label("Variables", "\(entries.count)"))
            print("  \(Style.gray)───\(Style.reset)")
            
            let maxKey = entries.map { $0.key.count }.max() ?? 10
            let sensitiveWords = ["secret", "password", "key", "token", "api", "auth", "private", "credential", "pwd"]
            
            for entry in entries {
                let padded = entry.key.padding(toLength: maxKey, withPad: " ", startingAt: 0)
                let isSensitive = sensitiveWords.contains { entry.key.lowercased().contains($0) }
                
                let displayed: String
                if reveal || !isSensitive {
                    displayed = entry.value
                } else {
                    let len = entry.value.count
                    if len <= 4 {
                        displayed = String(repeating: "•", count: len)
                    } else {
                        displayed = String(entry.value.prefix(2)) + String(repeating: "•", count: len - 4) + String(entry.value.suffix(2))
                    }
                }
                
                let icon = isSensitive && !reveal ? "\(Style.red)🔒\(Style.reset)" : "  "
                print("  \(icon) \(Style.blue)\(padded)\(Style.reset) = \(Style.white)\(displayed)\(Style.reset)")
            }
            print()
        }
    }
    
    struct Diff: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Compare two .env files")
        
        @Argument(help: "First .env file")
        var file1: String
        
        @Argument(help: "Second .env file")
        var file2: String
        
        func run() throws {
            let content1 = try String(contentsOfFile: file1, encoding: .utf8)
            let content2 = try String(contentsOfFile: file2, encoding: .utf8)
            let env1 = Dictionary(uniqueKeysWithValues: parseEnv(content1).map { ($0.key, $0.value) })
            let env2 = Dictionary(uniqueKeysWithValues: parseEnv(content2).map { ($0.key, $0.value) })
            
            print(Style.header("⚙️", "env diff"))
            print(Style.label("File A", file1))
            print(Style.label("File B", file2))
            print("  \(Style.gray)───\(Style.reset)")
            
            let allKeys = Set(env1.keys).union(Set(env2.keys)).sorted()
            var added = 0, removed = 0, changed = 0, same = 0
            
            for key in allKeys {
                let v1 = env1[key]
                let v2 = env2[key]
                
                if v1 == nil {
                    print("  \(Style.green)+ \(key)\(Style.reset) = \(v2 ?? "")")
                    added += 1
                } else if v2 == nil {
                    print("  \(Style.red)- \(key)\(Style.reset) = \(v1 ?? "")")
                    removed += 1
                } else if v1 != v2 {
                    print("  \(Style.yellow)~ \(key)\(Style.reset)")
                    print("    \(Style.red)- \(v1 ?? "")\(Style.reset)")
                    print("    \(Style.green)+ \(v2 ?? "")\(Style.reset)")
                    changed += 1
                } else {
                    same += 1
                }
            }
            
            print("\n  \(Style.gray)───\(Style.reset)")
            print(Style.label("Same", "\(same)"))
            print(Style.label("Added", "\(Style.green)\(added)\(Style.reset)"))
            print(Style.label("Removed", "\(Style.red)\(removed)\(Style.reset)"))
            print(Style.label("Changed", "\(Style.yellow)\(changed)\(Style.reset)"))
            print()
        }
    }
    
    struct Validate: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Validate .env file against a template")
        
        @Argument(help: ".env file to validate")
        var file: String = ".env"
        
        @Option(name: .shortAndLong, help: "Template file (.env.example)")
        var template: String = ".env.example"
        
        func run() throws {
            let content = try String(contentsOfFile: file, encoding: .utf8)
            let tmplContent = try String(contentsOfFile: template, encoding: .utf8)
            let env = Set(parseEnv(content).map { $0.key })
            let tmpl = Set(parseEnv(tmplContent).map { $0.key })
            
            print(Style.header("⚙️", "env validate"))
            print(Style.label("File", file))
            print(Style.label("Template", template))
            print("  \(Style.gray)───\(Style.reset)")
            
            let missing = tmpl.subtracting(env).sorted()
            let extra = env.subtracting(tmpl).sorted()
            
            if missing.isEmpty && extra.isEmpty {
                print(Style.success("All variables present and accounted for!"))
            } else {
                if !missing.isEmpty {
                    print("  \(Style.red)\(Style.bold)Missing (\(missing.count)):\(Style.reset)")
                    for key in missing {
                        print("    \(Style.red)✗ \(key)\(Style.reset)")
                    }
                }
                if !extra.isEmpty {
                    print("  \(Style.yellow)\(Style.bold)Extra (\(extra.count)):\(Style.reset)")
                    for key in extra {
                        print("    \(Style.yellow)? \(key)\(Style.reset)")
                    }
                }
            }
            print()
        }
    }
    
    struct Merge: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Merge two .env files (B overrides A)")
        
        @Argument(help: "Base .env file")
        var file1: String
        
        @Argument(help: "Override .env file")
        var file2: String
        
        @Option(name: .shortAndLong, help: "Output file (default: stdout)")
        var output: String?
        
        func run() throws {
            let content1 = try String(contentsOfFile: file1, encoding: .utf8)
            let content2 = try String(contentsOfFile: file2, encoding: .utf8)
            var env = Dictionary(uniqueKeysWithValues: parseEnv(content1).map { ($0.key, $0.value) })
            let overrides = parseEnv(content2)
            
            for entry in overrides {
                env[entry.key] = entry.value
            }
            
            let result = env.keys.sorted().map { "\($0)=\(env[$0]!)" }.joined(separator: "\n")
            
            if let output = output {
                try result.write(toFile: output, atomically: true, encoding: .utf8)
                print(Style.header("⚙️", "env merge"))
                print(Style.success("Merged \(file1) + \(file2) → \(output)"))
                print(Style.label("Variables", "\(env.count)"))
            } else {
                print(result)
            }
        }
    }
}

struct EnvEntry {
    let key: String
    let value: String
}

func parseEnv(_ content: String) -> [EnvEntry] {
    content.components(separatedBy: .newlines).compactMap { line in
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
        guard let eqIdx = trimmed.firstIndex(of: "=") else { return nil }
        let key = String(trimmed[..<eqIdx]).trimmingCharacters(in: .whitespaces)
        var value = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespaces)
        // Remove surrounding quotes
        if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
            value = String(value.dropFirst().dropLast())
        }
        return EnvEntry(key: key, value: value)
    }
}

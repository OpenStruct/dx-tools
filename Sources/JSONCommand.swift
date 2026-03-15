import ArgumentParser
import Foundation

struct JSONCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "json",
        abstract: "Pretty-print, minify, validate & query JSON",
        subcommands: [Pretty.self, Mini.self, Validate.self, Query.self],
        defaultSubcommand: Pretty.self
    )
    
    struct Pretty: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Pretty-print JSON with syntax highlighting")
        
        @Argument(help: "JSON string or file path")
        var input: String?
        
        func run() throws {
            guard let raw = readInput(input) ?? readAllStdin() else {
                print(Style.error("No input. Pass JSON string, file path, or pipe via stdin"))
                throw ExitCode.failure
            }
            
            guard let data = raw.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data),
                  let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]) else {
                print(Style.error("Invalid JSON"))
                throw ExitCode.failure
            }
            
            print(Style.header("📦", "json pretty"))
            let str = String(data: pretty, encoding: .utf8) ?? ""
            print(colorizeJSON(str))
        }
    }
    
    struct Mini: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Minify JSON")
        
        @Argument(help: "JSON string or file path")
        var input: String?
        
        func run() throws {
            guard let raw = readInput(input) ?? readAllStdin() else {
                print(Style.error("No input"))
                throw ExitCode.failure
            }
            
            guard let data = raw.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data),
                  let mini = try? JSONSerialization.data(withJSONObject: obj, options: [.withoutEscapingSlashes]) else {
                print(Style.error("Invalid JSON"))
                throw ExitCode.failure
            }
            
            print(Style.header("📦", "json mini"))
            let original = raw.utf8.count
            let minified = mini.count
            let saved = original - minified
            let pct = original > 0 ? Double(saved) / Double(original) * 100 : 0
            
            print(String(data: mini, encoding: .utf8) ?? "")
            print("\n\(Style.gray)───\(Style.reset)")
            print(Style.label("Original", "\(original) bytes"))
            print(Style.label("Minified", "\(minified) bytes"))
            print(Style.label("Saved", "\(saved) bytes (\(String(format: "%.1f", pct))%)"))
        }
    }
    
    struct Validate: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Validate JSON")
        
        @Argument(help: "JSON string or file path")
        var input: String?
        
        func run() throws {
            guard let raw = readInput(input) ?? readAllStdin() else {
                print(Style.error("No input"))
                throw ExitCode.failure
            }
            
            print(Style.header("📦", "json validate"))
            
            guard let data = raw.data(using: .utf8) else {
                print(Style.error("Could not read input as UTF-8"))
                throw ExitCode.failure
            }
            
            do {
                let obj = try JSONSerialization.jsonObject(with: data)
                print(Style.success("Valid JSON"))
                
                if let dict = obj as? [String: Any] {
                    print(Style.label("Type", "Object"))
                    print(Style.label("Keys", "\(dict.count)"))
                    if dict.count <= 20 {
                        let keys = dict.keys.sorted().map { "\(Style.blue)\($0)\(Style.reset)" }
                        print(Style.label("Fields", keys.joined(separator: ", ")))
                    }
                } else if let arr = obj as? [Any] {
                    print(Style.label("Type", "Array"))
                    print(Style.label("Items", "\(arr.count)"))
                }
                
                print(Style.label("Size", "\(data.count) bytes"))
            } catch {
                print(Style.error("Invalid JSON"))
                print(Style.label("Error", error.localizedDescription))
                throw ExitCode.failure
            }
        }
    }
    
    struct Query: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Query JSON with dot notation (e.g., 'user.name')")
        
        @Argument(help: "Dot-notation path (e.g., 'users.0.name')")
        var path: String
        
        @Argument(help: "JSON string or file path")
        var input: String?
        
        func run() throws {
            guard let raw = readInput(input) ?? readAllStdin() else {
                print(Style.error("No input"))
                throw ExitCode.failure
            }
            
            guard let data = raw.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) else {
                print(Style.error("Invalid JSON"))
                throw ExitCode.failure
            }
            
            print(Style.header("📦", "json query"))
            print(Style.label("Path", path))
            print("\(Style.gray)───\(Style.reset)")
            
            let keys = path.components(separatedBy: ".")
            var current: Any = obj
            
            for key in keys {
                if let dict = current as? [String: Any], let val = dict[key] {
                    current = val
                } else if let arr = current as? [Any], let idx = Int(key), idx < arr.count {
                    current = arr[idx]
                } else {
                    print(Style.error("Path '\(path)' not found at '\(key)'"))
                    throw ExitCode.failure
                }
            }
            
            if JSONSerialization.isValidJSONObject(current),
               let resultData = try? JSONSerialization.data(withJSONObject: current, options: [.prettyPrinted, .sortedKeys]),
               let resultStr = String(data: resultData, encoding: .utf8) {
                print(colorizeJSON(resultStr))
            } else {
                print("  \(Style.yellow)\(current)\(Style.reset)")
            }
        }
    }
}

func colorizeJSON(_ json: String) -> String {
    var result = ""
    let lines = json.components(separatedBy: "\n")
    for line in lines {
        var colored = line
        // Color keys
        colored = colored.replacingOccurrences(
            of: "\"([^\"]+)\"\\s*:",
            with: "\(Style.blue)\"$1\"\(Style.reset):",
            options: .regularExpression
        )
        // Color string values
        colored = colored.replacingOccurrences(
            of: ":\\s*\"([^\"]*)\"",
            with: ": \(Style.green)\"$1\"\(Style.reset)",
            options: .regularExpression
        )
        // Color numbers
        colored = colored.replacingOccurrences(
            of: ":\\s*(-?\\d+\\.?\\d*)",
            with: ": \(Style.yellow)$1\(Style.reset)",
            options: .regularExpression
        )
        // Color booleans & null
        colored = colored.replacingOccurrences(
            of: ":\\s*(true|false|null)",
            with: ": \(Style.magenta)$1\(Style.reset)",
            options: .regularExpression
        )
        result += colored + "\n"
    }
    return result
}

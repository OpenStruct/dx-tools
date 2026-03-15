import ArgumentParser
import Foundation

@main
struct DX: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dx",
        abstract: """
        \u{001B}[38;5;214m⚡ dx\u{001B}[0m — Developer Experience Toolkit
        """,
        discussion: """
        \u{001B}[38;5;245m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\u{001B}[0m
        A Swiss Army knife for developers.
        One binary. Every tool you reach for daily.
        \u{001B}[38;5;245m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\u{001B}[0m

        \u{001B}[38;5;81m📦 DATA\u{001B}[0m        json · jwt · base64 · hash · uuid
        \u{001B}[38;5;156m🕐 TIME\u{001B}[0m        epoch
        \u{001B}[38;5;213m🎨 DESIGN\u{001B}[0m      color
        \u{001B}[38;5;222m⚙️  DEVOPS\u{001B}[0m      env
        \u{001B}[38;5;203m🔑 SECURITY\u{001B}[0m    pass
        """,
        version: "1.0.0",
        subcommands: [
            JSONCommand.self,
            JWTCommand.self,
            EpochCommand.self,
            EnvCommand.self,
            HashCommand.self,
            Base64Command.self,
            UUIDCommand.self,
            ColorCommand.self,
            PassCommand.self,
            PortCommand.self,
        ]
    )
}

// MARK: - Styling Helpers

enum Style {
    static let reset   = "\u{001B}[0m"
    static let bold    = "\u{001B}[1m"
    static let dim     = "\u{001B}[2m"
    
    static let red     = "\u{001B}[38;5;203m"
    static let green   = "\u{001B}[38;5;156m"
    static let yellow  = "\u{001B}[38;5;222m"
    static let blue    = "\u{001B}[38;5;81m"
    static let magenta = "\u{001B}[38;5;213m"
    static let orange  = "\u{001B}[38;5;214m"
    static let gray    = "\u{001B}[38;5;245m"
    static let white   = "\u{001B}[38;5;255m"
    
    static func header(_ icon: String, _ title: String) -> String {
        "\n\(orange)⚡ dx \(title)\(reset) \(icon)\n\(gray)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\(reset)"
    }
    
    static func success(_ msg: String) -> String {
        "\(green)✓\(reset) \(msg)"
    }
    
    static func error(_ msg: String) -> String {
        "\(red)✗\(reset) \(msg)"
    }
    
    static func label(_ key: String, _ value: String) -> String {
        "  \(gray)\(key):\(reset) \(white)\(value)\(reset)"
    }
    
    static func box(_ content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        let maxLen = lines.map { stripAnsi($0).count }.max() ?? 0
        let top = "\(gray)╭\(String(repeating: "─", count: maxLen + 2))╮\(reset)"
        let bot = "\(gray)╰\(String(repeating: "─", count: maxLen + 2))╯\(reset)"
        let body = lines.map { line in
            let pad = maxLen - stripAnsi(line).count
            return "\(gray)│\(reset) \(line)\(String(repeating: " ", count: pad)) \(gray)│\(reset)"
        }.joined(separator: "\n")
        return "\(top)\n\(body)\n\(bot)"
    }
    
    static func stripAnsi(_ str: String) -> String {
        str.replacingOccurrences(of: "\u{001B}\\[[0-9;]*m", with: "", options: .regularExpression)
    }
}

// MARK: - Input Helpers

func readInput(_ argument: String?) -> String? {
    if let argument = argument, !argument.isEmpty {
        // Check if it's a file path
        if FileManager.default.fileExists(atPath: argument) {
            return try? String(contentsOfFile: argument, encoding: .utf8)
        }
        return argument
    }
    // Read from stdin if available
    if isatty(fileno(stdin)) == 0 {
        return readLine(strippingNewline: false).map { _ in
            var result = ""
            while let line = readLine(strippingNewline: false) {
                result += line
            }
            return result
        }
    }
    return nil
}

func readAllStdin() -> String? {
    guard isatty(fileno(stdin)) == 0 else { return nil }
    var data = Data()
    let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
    defer { buf.deallocate() }
    while true {
        let count = fread(buf, 1, 4096, stdin)
        if count == 0 { break }
        data.append(buf, count: count)
    }
    return String(data: data, encoding: .utf8)
}

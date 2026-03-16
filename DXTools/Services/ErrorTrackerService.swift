import Foundation

struct ErrorTrackerService {
    struct ParsedError: Identifiable {
        var id: UUID = UUID()
        var type: String
        var message: String
        var stackTrace: [StackFrame]
        var source: ErrorSource
        var timestamp: Date?
        var level: ErrorLevel
        var raw: String
        var fingerprint: String
    }

    struct StackFrame {
        var file: String
        var function: String
        var line: Int?
        var column: Int?
        var isUserCode: Bool
    }

    enum ErrorSource: String, CaseIterable {
        case javascript = "JavaScript"
        case python = "Python"
        case swift = "Swift"
        case java = "Java"
        case go = "Go"
        case generic = "Generic"
    }

    enum ErrorLevel: String, CaseIterable {
        case fatal = "Fatal"
        case error = "Error"
        case warning = "Warning"
        case info = "Info"
    }

    struct ErrorGroup: Identifiable {
        var id: String
        var type: String
        var message: String
        var count: Int
        var firstSeen: Date
        var lastSeen: Date
        var occurrences: [ParsedError]
        var source: ErrorSource
        var level: ErrorLevel
    }

    // MARK: - Detection

    static func detectSource(_ text: String) -> ErrorSource {
        if text.contains("Traceback (most recent call last)") || text.contains("File \"") { return .python }
        if text.contains("at Object.") || text.contains("at Module.") || text.contains("TypeError:") && text.contains(".js:") { return .javascript }
        if text.contains("Fatal error:") || text.contains("EXC_BAD_ACCESS") || text.contains("Swift/") { return .swift }
        if text.contains("at com.") || text.contains("at java.") || text.contains("Exception") && text.contains(".java:") { return .java }
        if text.contains("goroutine") || text.contains("panic:") { return .go }
        return .generic
    }

    // MARK: - Parsing

    static func parse(_ logText: String) -> [ParsedError] {
        let source = detectSource(logText)
        switch source {
        case .javascript: return parseJavaScript(logText)
        case .python: return parsePython(logText)
        case .swift: return parseSwift(logText)
        case .java: return parseJava(logText)
        case .go: return parseGo(logText)
        case .generic: return parseGeneric(logText)
        }
    }

    static func parseJavaScript(_ text: String) -> [ParsedError] {
        var errors: [ParsedError] = []
        // Match patterns like "TypeError: message\n    at func (file:line:col)"
        let pattern = #"(TypeError|ReferenceError|SyntaxError|RangeError|Error|URIError|EvalError):\s*(.+?)(?:\n((?:\s+at .+\n?)*))"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            let type = extractGroup(text, match: match, group: 1) ?? "Error"
            let message = extractGroup(text, match: match, group: 2) ?? ""
            let stackText = extractGroup(text, match: match, group: 3) ?? ""
            let frames = parseJSStack(stackText)
            let fp = computeFingerprint(type: type, message: message, topFrame: frames.first)
            let raw = extractGroup(text, match: match, group: 0) ?? ""
            errors.append(ParsedError(type: type, message: message, stackTrace: frames, source: .javascript, level: .error, raw: raw, fingerprint: fp))
        }
        if errors.isEmpty && !text.isEmpty {
            return parseGeneric(text)
        }
        return errors
    }

    static func parsePython(_ text: String) -> [ParsedError] {
        var errors: [ParsedError] = []
        let blocks = text.components(separatedBy: "Traceback (most recent call last):")
        for block in blocks.dropFirst() {
            let lines = block.components(separatedBy: .newlines).filter { !$0.isEmpty }
            var frames: [StackFrame] = []
            var errorLine = ""
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("File \"") {
                    // File "app.py", line 42, in handler
                    let filePattern = #"File "(.+?)", line (\d+), in (.+)"#
                    if let regex = try? NSRegularExpression(pattern: filePattern),
                       let m = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) {
                        let file = extractGroup(trimmed, match: m, group: 1) ?? ""
                        let lineNum = Int(extractGroup(trimmed, match: m, group: 2) ?? "") ?? 0
                        let func_ = extractGroup(trimmed, match: m, group: 3) ?? ""
                        frames.append(StackFrame(file: file, function: func_, line: lineNum, column: nil, isUserCode: !file.contains("site-packages")))
                    }
                } else if !trimmed.hasPrefix("File") && !trimmed.isEmpty && trimmed.contains(":") && frames.count > 0 {
                    errorLine = trimmed
                }
            }
            if errorLine.isEmpty { errorLine = lines.last ?? "" }
            let parts = errorLine.components(separatedBy: ": ")
            let type = parts.first ?? "Error"
            let message = parts.dropFirst().joined(separator: ": ")
            let fp = computeFingerprint(type: type, message: message, topFrame: frames.first)
            errors.append(ParsedError(type: type, message: message, stackTrace: frames, source: .python, level: .error, raw: "Traceback (most recent call last):" + block, fingerprint: fp))
        }
        return errors
    }

    static func parseSwift(_ text: String) -> [ParsedError] {
        var errors: [ParsedError] = []
        // Fatal error: message: file File.swift, line 42
        let pattern = #"(Fatal error|Assertion failed|Precondition failed):\s*(.+?)(?::\s*file\s+(.+?),\s*line\s+(\d+))?"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(text.startIndex..., in: text)
            for match in regex.matches(in: text, range: range) {
                let type = extractGroup(text, match: match, group: 1) ?? "Fatal error"
                let message = extractGroup(text, match: match, group: 2) ?? ""
                let file = extractGroup(text, match: match, group: 3) ?? ""
                let line = Int(extractGroup(text, match: match, group: 4) ?? "")
                var frames: [StackFrame] = []
                if !file.isEmpty {
                    frames.append(StackFrame(file: file, function: "", line: line, column: nil, isUserCode: true))
                }
                let fp = computeFingerprint(type: type, message: message, topFrame: frames.first)
                errors.append(ParsedError(type: type, message: message, stackTrace: frames, source: .swift, level: .fatal, raw: extractGroup(text, match: match, group: 0) ?? "", fingerprint: fp))
            }
        }
        return errors
    }

    static func parseJava(_ text: String) -> [ParsedError] {
        var errors: [ParsedError] = []
        let pattern = #"([\w.]+Exception|[\w.]+Error):\s*(.+?)(?:\n((?:\s+at .+\n?)*))"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(text.startIndex..., in: text)
            for match in regex.matches(in: text, range: range) {
                let type = extractGroup(text, match: match, group: 1) ?? "Exception"
                let message = extractGroup(text, match: match, group: 2) ?? ""
                let stackText = extractGroup(text, match: match, group: 3) ?? ""
                let frames = parseJavaStack(stackText)
                let fp = computeFingerprint(type: type, message: message, topFrame: frames.first)
                errors.append(ParsedError(type: type, message: message, stackTrace: frames, source: .java, level: .error, raw: extractGroup(text, match: match, group: 0) ?? "", fingerprint: fp))
            }
        }
        return errors
    }

    static func parseGo(_ text: String) -> [ParsedError] {
        var errors: [ParsedError] = []
        let parts = text.components(separatedBy: "panic: ")
        for part in parts.dropFirst() {
            let lines = part.components(separatedBy: .newlines)
            let message = lines.first ?? ""
            var frames: [StackFrame] = []
            var i = 1
            while i < lines.count {
                let line = lines[i].trimmingCharacters(in: .whitespaces)
                if line.contains(".go:") {
                    let goPattern = #"(.+\.go):(\d+)"#
                    if let regex = try? NSRegularExpression(pattern: goPattern),
                       let m = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
                        let file = extractGroup(line, match: m, group: 1) ?? ""
                        let lineNum = Int(extractGroup(line, match: m, group: 2) ?? "")
                        let funcName = i > 1 ? lines[i-1].trimmingCharacters(in: .whitespaces) : ""
                        frames.append(StackFrame(file: file, function: funcName, line: lineNum, column: nil, isUserCode: !file.contains("runtime/")))
                    }
                }
                i += 1
            }
            let fp = computeFingerprint(type: "panic", message: message, topFrame: frames.first)
            errors.append(ParsedError(type: "panic", message: message, stackTrace: frames, source: .go, level: .fatal, raw: "panic: " + part, fingerprint: fp))
        }
        return errors
    }

    static func parseGeneric(_ text: String) -> [ParsedError] {
        var errors: [ParsedError] = []
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let upper = line.uppercased()
            var level: ErrorLevel?
            if upper.contains("FATAL") { level = .fatal }
            else if upper.contains("ERROR") { level = .error }
            else if upper.contains("WARN") { level = .warning }
            guard let lvl = level else { continue }
            let fp = computeFingerprint(type: lvl.rawValue, message: line, topFrame: nil)
            errors.append(ParsedError(type: lvl.rawValue, message: line.trimmingCharacters(in: .whitespaces), stackTrace: [], source: .generic, level: lvl, raw: line, fingerprint: fp))
        }
        return errors
    }

    // MARK: - Grouping

    static func group(_ errors: [ParsedError]) -> [ErrorGroup] {
        var groups: [String: [ParsedError]] = [:]
        for error in errors {
            groups[error.fingerprint, default: []].append(error)
        }
        return groups.map { fp, occurrences in
            let first = occurrences.first!
            let timestamps = occurrences.compactMap(\.timestamp)
            return ErrorGroup(
                id: fp, type: first.type, message: first.message,
                count: occurrences.count,
                firstSeen: timestamps.min() ?? Date(),
                lastSeen: timestamps.max() ?? Date(),
                occurrences: occurrences, source: first.source, level: first.level
            )
        }.sorted { $0.count > $1.count }
    }

    // MARK: - Helpers

    static func computeFingerprint(type: String, message: String, topFrame: StackFrame?) -> String {
        var input = "\(type):\(message)"
        if let frame = topFrame { input += ":\(frame.file):\(frame.function)" }
        var hash: UInt64 = 5381
        for byte in input.utf8 { hash = ((hash << 5) &+ hash) &+ UInt64(byte) }
        return String(hash, radix: 16)
    }

    private static func extractGroup(_ text: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard group < match.numberOfRanges else { return nil }
        let range = match.range(at: group)
        guard range.location != NSNotFound, let r = Range(range, in: text) else { return nil }
        return String(text[r])
    }

    private static func parseJSStack(_ text: String) -> [StackFrame] {
        var frames: [StackFrame] = []
        let pattern = #"at\s+(.+?)\s+\((.+?):(\d+):(\d+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            let func_ = extractGroup(text, match: match, group: 1) ?? ""
            let file = extractGroup(text, match: match, group: 2) ?? ""
            let line = Int(extractGroup(text, match: match, group: 3) ?? "")
            let col = Int(extractGroup(text, match: match, group: 4) ?? "")
            frames.append(StackFrame(file: file, function: func_, line: line, column: col, isUserCode: !file.contains("node_modules")))
        }
        return frames
    }

    private static func parseJavaStack(_ text: String) -> [StackFrame] {
        var frames: [StackFrame] = []
        let pattern = #"at\s+([\w.$]+)\(([\w.]+):(\d+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        for match in regex.matches(in: text, range: range) {
            let func_ = extractGroup(text, match: match, group: 1) ?? ""
            let file = extractGroup(text, match: match, group: 2) ?? ""
            let line = Int(extractGroup(text, match: match, group: 3) ?? "")
            frames.append(StackFrame(file: file, function: func_, line: line, column: nil, isUserCode: !func_.hasPrefix("java.") && !func_.hasPrefix("sun.")))
        }
        return frames
    }
}

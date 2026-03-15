import Foundation

struct PortProcess: Identifiable, Equatable {
    let id = UUID()
    let port: Int
    let pid: Int
    let processName: String
    let user: String
    let fd: String
    let type: String // IPv4/IPv6
    let protocol_: String // TCP/UDP
    let state: String
    let command: String

    static func == (lhs: PortProcess, rhs: PortProcess) -> Bool {
        lhs.port == rhs.port && lhs.pid == rhs.pid
    }

    var isSystemProcess: Bool {
        pid <= 1 || user == "root" || processName.hasPrefix("kernel") || processName.hasPrefix("launchd")
    }

    var portCategory: PortCategory {
        switch port {
        case 80, 443: return .web
        case 5432: return .database
        case 3306: return .database
        case 27017: return .database
        case 6379: return .database
        case 3000...3999: return .dev
        case 4000...4999: return .dev
        case 5000...5999: return .dev
        case 8000...8999: return .dev
        case 9000...9999: return .dev
        case 22: return .system
        case 53: return .system
        case 1...1023: return .system
        default: return .other
        }
    }

    enum PortCategory: String, CaseIterable {
        case web = "Web"
        case dev = "Development"
        case database = "Database"
        case system = "System"
        case other = "Other"

        var icon: String {
            switch self {
            case .web: return "globe"
            case .dev: return "hammer.fill"
            case .database: return "cylinder.fill"
            case .system: return "gearshape.fill"
            case .other: return "circle.fill"
            }
        }
    }
}

struct PortService {

    // MARK: - Public API

    /// List all listening ports using lsof
    static func listPorts() -> [PortProcess] {
        let output = shell("lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null")
        return parseLsofOutput(output)
    }

    /// List all ports (including established connections)
    static func listAllPorts() -> [PortProcess] {
        let output = shell("lsof -iTCP -P -n 2>/dev/null")
        return parseLsofOutput(output)
    }

    /// Kill process on a specific port
    static func killPort(_ port: Int) -> Result<String, PortError> {
        let processes = listPorts().filter { $0.port == port }
        guard !processes.isEmpty else {
            return .failure(.noProcessOnPort(port))
        }

        var killed: [Int] = []
        var errors: [String] = []

        // Dedupe PIDs — multiple FDs can point to same port
        let uniquePids = Array(Set(processes.map { $0.pid }))

        for pid in uniquePids {
            let proc = processes.first { $0.pid == pid }!
            if proc.isSystemProcess {
                errors.append("Skipped system process: \(proc.processName) (PID \(pid))")
                continue
            }

            let result = killPID(pid)
            switch result {
            case .success:
                killed.append(pid)
            case .failure(let err):
                errors.append(err.localizedDescription)
            }
        }

        if killed.isEmpty && !errors.isEmpty {
            return .failure(.killFailed(errors.joined(separator: "\n")))
        }

        let msg = "Killed \(killed.count) process(es) on port \(port)" +
            (errors.isEmpty ? "" : "\n⚠️ \(errors.joined(separator: "\n"))")
        return .success(msg)
    }

    /// Kill a specific PID
    static func killPID(_ pid: Int) -> Result<String, PortError> {
        // First try SIGTERM (graceful)
        let termResult = shell("kill -15 \(pid) 2>&1")
        // Give it a moment
        usleep(200_000) // 200ms

        // Check if still alive
        let check = shell("kill -0 \(pid) 2>&1")
        if check.contains("No such process") {
            return .success("Killed PID \(pid)")
        }

        // Force kill
        let result = shell("kill -9 \(pid) 2>&1")
        if result.isEmpty || result.contains("No such process") {
            return .success("Force killed PID \(pid)")
        }
        if result.contains("Operation not permitted") {
            return .failure(.killFailed("Permission denied for PID \(pid). Try: sudo kill -9 \(pid)"))
        }
        return .failure(.killFailed(result.trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    /// Check if a specific port is in use
    static func isPortInUse(_ port: Int) -> Bool {
        let output = shell("lsof -iTCP:\(port) -sTCP:LISTEN -P -n 2>/dev/null")
        return output.split(separator: "\n").count > 1
    }

    /// Get common dev ports to check
    static let commonDevPorts: [(Int, String)] = [
        (3000, "React / Next.js / Rails"),
        (3001, "React (alt)"),
        (4000, "Phoenix / Custom"),
        (4200, "Angular"),
        (5000, "Flask / .NET"),
        (5173, "Vite"),
        (5432, "PostgreSQL"),
        (3306, "MySQL"),
        (6379, "Redis"),
        (8000, "Django / Custom"),
        (8080, "Tomcat / Proxy"),
        (8888, "Jupyter"),
        (9000, "PHP-FPM / Custom"),
        (27017, "MongoDB"),
    ]

    // MARK: - Parsing (internal for testing)

    /// Parse lsof output into PortProcess array
    /// lsof -iTCP -sTCP:LISTEN -P -n format:
    /// COMMAND  PID USER  FD  TYPE  DEVICE  SIZE/OFF  NODE  NAME
    /// node    1234 nam  22u  IPv6  0xabc   0t0       TCP   *:3000 (LISTEN)
    ///
    /// Key issues:
    /// - COMMAND can contain escaped spaces like `Code\x20H`
    /// - NAME column has `addr:port` and STATE in parens after
    /// - Column count varies (9 header, 10+ data because of STATE)
    static func parseLsofOutput(_ output: String) -> [PortProcess] {
        let lines = output.components(separatedBy: "\n")
        guard lines.count > 1 else { return [] }

        var results: [PortProcess] = []
        var seen = Set<String>()

        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }

            // Extract state from parens at end: (LISTEN), (ESTABLISHED), etc.
            var state = "LISTEN"
            var cleanLine = line
            if let parenRange = line.range(of: "\\(([A-Z_]+)\\)\\s*$", options: .regularExpression) {
                let match = line[parenRange]
                state = String(match).replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").trimmingCharacters(in: .whitespaces)
                cleanLine = String(line[line.startIndex..<parenRange.lowerBound])
            }

            let cols = cleanLine.split(separator: " ", omittingEmptySubsequences: true).map(String.init)

            // Need at least: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
            guard cols.count >= 9 else { continue }

            // NAME is always the last column after removing state
            let nameCol = cols.last ?? ""

            // Extract port from NAME: *:3000 or 127.0.0.1:8080 or [::1]:5432
            guard let port = extractPort(from: nameCol), port > 0 else { continue }

            // Parse fixed columns - but COMMAND can have spaces
            // Work backwards from the known-format end columns
            // NODE is second to last (TCP/UDP), SIZE/OFF before that, etc.
            // Actually with split, the columns work if COMMAND has no spaces
            // For escaped names like Code\x20H, the split produces one token anyway

            let processName = cols[0]
            guard let pid = Int(cols[1]) else { continue }
            let user = cols[2]
            let fd = cols[3]
            let ipType = cols[4] // IPv4 or IPv6

            let key = "\(pid)-\(port)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            let command = getCommand(pid: pid)

            results.append(PortProcess(
                port: port,
                pid: pid,
                processName: processName.replacingOccurrences(of: "\\x20", with: " "),
                user: user,
                fd: fd,
                type: ipType,
                protocol_: "TCP",
                state: state,
                command: command
            ))
        }

        return results.sorted { $0.port < $1.port }
    }

    /// Extract port number from lsof NAME column
    /// Handles: *:3000, 127.0.0.1:8080, [::1]:5432, [::]:3000
    static func extractPort(from name: String) -> Int? {
        // Split on last colon — port is always after last ':'
        guard let lastColon = name.lastIndex(of: ":") else { return nil }
        let portStr = String(name[name.index(after: lastColon)...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(portStr)
    }

    // MARK: - Private

    private static func getCommand(pid: Int) -> String {
        let output = shell("ps -p \(pid) -o command= 2>/dev/null")
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    enum PortError: Error, LocalizedError, Equatable {
        case noProcessOnPort(Int)
        case killFailed(String)

        var errorDescription: String? {
            switch self {
            case .noProcessOnPort(let port): return "No process found on port \(port)"
            case .killFailed(let msg): return msg
            }
        }
    }
}

import ArgumentParser
import Foundation

struct PortCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "port",
        abstract: "Manage ports — list, check, kill",
        subcommands: [PortList.self, PortKill.self, PortCheck.self],
        defaultSubcommand: PortList.self
    )
}

struct PortList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all listening ports"
    )

    @Flag(name: .shortAndLong, help: "Show all connections, not just listening")
    var all = false

    @Option(name: .shortAndLong, help: "Filter by process name")
    var filter: String?

    func run() throws {
        print(Style.header("🔌", "port list"))
        let output = all
            ? shell("lsof -iTCP -P -n 2>/dev/null")
            : shell("lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null")

        let lines = output.components(separatedBy: "\n")
        guard lines.count > 1 else {
            print("\n  \(Style.green)✓ No ports in use\(Style.reset)\n")
            return
        }

        // Parse
        var entries: [(port: Int, pid: String, name: String, user: String, addr: String)] = []
        var seen = Set<String>()

        for line in lines.dropFirst() {
            guard !line.isEmpty else { continue }
            var cleanLine = line
            if let range = line.range(of: "\\([A-Z_]+\\)\\s*$", options: .regularExpression) {
                cleanLine = String(line[..<range.lowerBound])
            }
            let cols = cleanLine.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard cols.count >= 9 else { continue }

            let nameCol = cols.last ?? ""
            guard let lastColon = nameCol.lastIndex(of: ":") else { continue }
            let portStr = String(nameCol[nameCol.index(after: lastColon)...])
            guard let port = Int(portStr), port > 0 else { continue }

            let procName = cols[0].replacingOccurrences(of: "\\x20", with: " ")
            let pid = cols[1]
            let user = cols[2]

            let key = "\(pid)-\(port)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            if let f = filter, !procName.lowercased().contains(f.lowercased()) { continue }

            entries.append((port, pid, procName, user, nameCol))
        }

        entries.sort { $0.port < $1.port }

        if entries.isEmpty {
            print("\n  \(Style.green)✓ No matching ports\(Style.reset)\n")
            return
        }

        // Print table
        print("")
        print("  \(Style.gray)PORT    PID      PROCESS          USER     ADDRESS\(Style.reset)")
        print("  \(Style.gray)\(String(repeating: "─", count: 60))\(Style.reset)")

        for e in entries {
            let portColor = e.port < 1024 ? Style.yellow : (e.port >= 3000 && e.port <= 9999 ? Style.orange : Style.white)
            let portStr = String(e.port).padding(toLength: 7, withPad: " ", startingAt: 0)
            let pidStr = e.pid.padding(toLength: 8, withPad: " ", startingAt: 0)
            let nameStr = e.name.padding(toLength: 16, withPad: " ", startingAt: 0)
            let userStr = e.user.padding(toLength: 8, withPad: " ", startingAt: 0)
            print("  \(portColor)\(portStr)\(Style.reset) \(Style.dim)\(pidStr)\(Style.reset) \(Style.white)\(nameStr)\(Style.reset) \(Style.dim)\(userStr)\(Style.reset) \(Style.gray)\(e.addr)\(Style.reset)")
        }
        print("\n  \(Style.dim)\(entries.count) port(s)\(Style.reset)\n")
    }
}

struct PortKill: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kill",
        abstract: "Kill process on a port"
    )

    @Argument(help: "Port number to kill")
    var port: Int

    func run() throws {
        print(Style.header("💀", "port kill"))

        let output = shell("lsof -iTCP:\(port) -sTCP:LISTEN -P -n 2>/dev/null")
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else {
            print("\n  \(Style.yellow)⚠ No process on port \(port)\(Style.reset)\n")
            throw ExitCode.failure
        }

        var pids = Set<String>()
        for line in lines.dropFirst() {
            let cols = line.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            guard cols.count >= 2 else { continue }
            pids.insert(cols[1])
        }

        for pid in pids {
            let name = shell("ps -p \(pid) -o comm= 2>/dev/null").trimmingCharacters(in: .whitespacesAndNewlines)
            print("\n  Killing \(Style.orange)\(name)\(Style.reset) (PID \(pid)) on port \(Style.orange)\(port)\(Style.reset)...")

            let result = shell("kill -15 \(pid) 2>&1")
            usleep(300_000)

            let check = shell("kill -0 \(pid) 2>&1")
            if check.contains("No such process") {
                print("  \(Style.green)✓ Killed\(Style.reset)")
            } else {
                _ = shell("kill -9 \(pid) 2>&1")
                usleep(200_000)
                let check2 = shell("kill -0 \(pid) 2>&1")
                if check2.contains("No such process") {
                    print("  \(Style.green)✓ Force killed\(Style.reset)")
                } else {
                    print("  \(Style.red)✗ Failed — try: sudo kill -9 \(pid)\(Style.reset)")
                }
            }
        }
        print("")
    }
}

struct PortCheck: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "check",
        abstract: "Check if a port is in use"
    )

    @Argument(help: "Port number to check")
    var port: Int

    func run() throws {
        let output = shell("lsof -iTCP:\(port) -sTCP:LISTEN -P -n 2>/dev/null")
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

        if lines.count > 1 {
            let cols = lines[1].split(separator: " ", omittingEmptySubsequences: true).map(String.init)
            let name = cols.count >= 1 ? cols[0] : "unknown"
            let pid = cols.count >= 2 ? cols[1] : "?"
            print("\(Style.red)●\(Style.reset) Port \(Style.orange)\(port)\(Style.reset) is \(Style.red)in use\(Style.reset) by \(Style.white)\(name)\(Style.reset) (PID \(pid))")
        } else {
            print("\(Style.green)●\(Style.reset) Port \(Style.orange)\(port)\(Style.reset) is \(Style.green)available\(Style.reset)")
        }
    }
}

private func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]
    do {
        try task.run()
        task.waitUntilExit()
    } catch { return "" }
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

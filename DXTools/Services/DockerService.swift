import Foundation

struct DockerService {
    struct Container: Identifiable {
        let id: String
        let name: String
        let image: String
        let status: String
        let ports: String
        let created: String
        var isRunning: Bool { status.lowercased().contains("up") }
    }

    enum Runtime: String, CaseIterable {
        case docker = "docker"
        case podman = "podman"
        case nerdctl = "nerdctl"

        var displayName: String {
            switch self {
            case .docker: return "Docker"
            case .podman: return "Podman"
            case .nerdctl: return "nerdctl"
            }
        }
    }

    /// Detected runtime name for display (e.g. "Docker", "Podman")
    static var detectedRuntimeName: String {
        detectRuntime()?.displayName ?? "Container runtime"
    }

    /// Search common paths for a container runtime binary, returning the first one found.
    static func detectRuntime() -> Runtime? {
        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            NSHomeDirectory() + "/.docker/bin",
            NSHomeDirectory() + "/.rd/bin",           // Rancher Desktop
            "/Applications/OrbStack.app/Contents/MacOS", // OrbStack
        ]

        for runtime in Runtime.allCases {
            // First try `which` to respect the user's PATH
            let whichResult = shell("/usr/bin/which \(runtime.rawValue) 2>/dev/null")
            if !whichResult.isEmpty && FileManager.default.isExecutableFile(atPath: whichResult) {
                return runtime
            }
            // Then check common install locations
            for dir in searchPaths {
                let path = "\(dir)/\(runtime.rawValue)"
                if FileManager.default.isExecutableFile(atPath: path) {
                    return runtime
                }
            }
        }
        return nil
    }

    /// Resolve the full path to the runtime binary.
    private static func runtimePath() -> String? {
        guard let runtime = detectRuntime() else { return nil }
        let searchPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            NSHomeDirectory() + "/.docker/bin",
            NSHomeDirectory() + "/.rd/bin",
            "/Applications/OrbStack.app/Contents/MacOS",
        ]

        let whichResult = shell("/usr/bin/which \(runtime.rawValue) 2>/dev/null")
        if !whichResult.isEmpty && FileManager.default.isExecutableFile(atPath: whichResult) {
            return whichResult
        }
        for dir in searchPaths {
            let path = "\(dir)/\(runtime.rawValue)"
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return nil
    }

    /// Run a container runtime command using the detected binary.
    private static func run(_ arguments: String) -> String {
        guard let bin = runtimePath() else { return "" }
        return shell("\(bin) \(arguments)")
    }

    static func listContainers(all: Bool = true) -> [Container] {
        let flag = all ? "-a" : ""
        let output = run("ps \(flag) --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.CreatedAt}}' 2>/dev/null")
        guard !output.isEmpty else { return [] }

        return output.split(separator: "\n").compactMap { line in
            let cols = line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
            guard cols.count >= 6 else { return nil }
            return Container(
                id: cols[0],
                name: cols[1],
                image: cols[2],
                status: cols[3],
                ports: cols[4],
                created: cols[5]
            )
        }
    }

    static func start(_ containerId: String) -> Bool {
        let output = run("start \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func stop(_ containerId: String) -> Bool {
        let output = run("stop \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func restart(_ containerId: String) -> Bool {
        let output = run("restart \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func remove(_ containerId: String) -> Bool {
        let output = run("rm -f \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func logs(_ containerId: String, lines: Int = 100) -> String {
        run("logs --tail \(lines) \(containerId) 2>&1")
    }

    static func isDockerRunning() -> Bool {
        guard runtimePath() != nil else { return false }
        let output = run("info 2>&1")
        return output.contains("Server Version") || output.contains("Containers:")
            || output.contains("host")  // podman info output
    }

    private static func shell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

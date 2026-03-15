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

    static func listContainers(all: Bool = true) -> [Container] {
        let flag = all ? "-a" : ""
        let output = shell("docker ps \(flag) --format '{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.CreatedAt}}' 2>/dev/null")
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
        let output = shell("docker start \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func stop(_ containerId: String) -> Bool {
        let output = shell("docker stop \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func restart(_ containerId: String) -> Bool {
        let output = shell("docker restart \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func remove(_ containerId: String) -> Bool {
        let output = shell("docker rm -f \(containerId) 2>&1")
        return !output.isEmpty
    }

    static func logs(_ containerId: String, lines: Int = 100) -> String {
        shell("docker logs --tail \(lines) \(containerId) 2>&1")
    }

    static func isDockerRunning() -> Bool {
        let output = shell("docker info 2>&1")
        return output.contains("Server Version") || output.contains("Containers:")
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

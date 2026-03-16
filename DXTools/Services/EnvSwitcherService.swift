import Foundation

struct EnvSwitcherService {
    struct Project: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        var path: String
        var envFileName: String = ".env"
        var profiles: [EnvProfile] = []
        var activeProfileId: UUID?
        var lastSwitched: Date?
    }

    struct EnvProfile: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        var color: String
        var content: String
        var createdAt: Date = Date()
        var lastUsed: Date?
        var variables: Int
    }

    // MARK: - Parsing

    static func parseEnvContent(_ content: String) -> [(key: String, value: String)] {
        var result: [(key: String, value: String)] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            guard let eqIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[trimmed.startIndex..<eqIndex]).trimmingCharacters(in: .whitespaces)
            var value = String(trimmed[trimmed.index(after: eqIndex)...]).trimmingCharacters(in: .whitespaces)
            // Remove surrounding quotes
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            if !key.isEmpty {
                result.append((key: key, value: value))
            }
        }
        return result
    }

    // MARK: - Profile Management

    static func createProfile(name: String, color: String, content: String) -> EnvProfile {
        let vars = parseEnvContent(content)
        return EnvProfile(name: name, color: color, content: content, variables: vars.count)
    }

    // MARK: - Diff

    static func diffProfiles(_ a: EnvProfile, _ b: EnvProfile) -> [(key: String, inA: String?, inB: String?)] {
        let varsA = Dictionary(parseEnvContent(a.content).map { ($0.key, $0.value) }, uniquingKeysWith: { _, last in last })
        let varsB = Dictionary(parseEnvContent(b.content).map { ($0.key, $0.value) }, uniquingKeysWith: { _, last in last })
        let allKeys = Set(varsA.keys).union(Set(varsB.keys)).sorted()
        var diffs: [(key: String, inA: String?, inB: String?)] = []
        for key in allKeys {
            let valA = varsA[key]
            let valB = varsB[key]
            if valA != valB {
                diffs.append((key: key, inA: valA, inB: valB))
            }
        }
        return diffs
    }

    // MARK: - Conflicts

    static func findConflicts(_ profiles: [EnvProfile]) -> [String] {
        guard profiles.count > 1 else { return [] }
        var keyValues: [String: Set<String>] = [:]
        for profile in profiles {
            for (key, value) in parseEnvContent(profile.content) {
                keyValues[key, default: []].insert(value)
            }
        }
        return keyValues.filter { $0.value.count > 1 }.keys.sorted()
    }

    // MARK: - File Operations

    static func readEnvFile(at projectPath: String, fileName: String) -> String? {
        let fullPath = (projectPath as NSString).appendingPathComponent(fileName)
        return try? String(contentsOfFile: fullPath, encoding: .utf8)
    }

    static func writeEnvFile(at projectPath: String, fileName: String, content: String) -> Bool {
        let fullPath = (projectPath as NSString).appendingPathComponent(fileName)
        do {
            // Backup
            let backupPath = fullPath + ".backup"
            if FileManager.default.fileExists(atPath: fullPath) {
                try? FileManager.default.copyItem(atPath: fullPath, toPath: backupPath)
            }
            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
            return true
        } catch {
            return false
        }
    }

    static func detectEnvFile(in directory: String) -> String? {
        let candidates = [".env", ".env.local", ".env.development", ".env.dev"]
        for name in candidates {
            let path = (directory as NSString).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: path) {
                return name
            }
        }
        return nil
    }

    // MARK: - Persistence

    private static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DX Tools")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("env-profiles.json")
    }

    static func saveProjects(_ projects: [Project]) {
        guard let data = try? JSONEncoder().encode(projects) else { return }
        try? data.write(to: storageURL)
    }

    static func loadProjects() -> [Project] {
        guard let data = try? Data(contentsOf: storageURL),
              let projects = try? JSONDecoder().decode([Project].self, from: data) else { return [] }
        return projects
    }
}

import Foundation

struct SSHManagerService {

    // MARK: - Models

    struct SSHKeyInfo: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let publicKeyPath: String?
        let keyType: String
        let bits: String
        let fingerprint: String
        let comment: String
        let publicKeyContent: String?
        let privateKeyFirstLine: String
        let permissions: String
        let permissionsOK: Bool
        let createdDate: Date?
        let fileSize: Int
        let hasPassphrase: Bool?
        let isDefault: Bool
        let ageDays: Int

        var isStale: Bool { ageDays > 365 }
        var isAncient: Bool { ageDays > 730 }

        var ageDescription: String {
            if ageDays < 1 { return "Today" }
            if ageDays == 1 { return "Yesterday" }
            if ageDays < 30 { return "\(ageDays)d ago" }
            if ageDays < 365 { return "\(ageDays / 30)mo ago" }
            return "\(ageDays / 365)y ago"
        }

        /// Which SSH config hosts reference this key
        var linkedHosts: [String] = []
    }

    struct SSHHostConfig: Identifiable {
        let id = UUID()
        var alias: String
        var hostname: String
        var user: String
        var port: String
        var identityFile: String
        var otherOptions: [(key: String, value: String)]
        let raw: String
    }

    struct KnownHost: Identifiable {
        let id = UUID()
        let hostname: String
        let keyType: String
        let keyFingerprint: String
        let lineNumber: Int
    }

    struct SSHDirectoryInfo {
        let path: String
        let exists: Bool
        let permissions: String
        let permissionsOK: Bool
        let keyCount: Int
        let configExists: Bool
        let knownHostsCount: Int
        let authorizedKeysExists: Bool
        let staleKeyCount: Int
        let permIssueCount: Int
    }

    // MARK: - Directory

    static var sshDirectory: String {
        (NSHomeDirectory() as NSString).appendingPathComponent(".ssh")
    }

    static func ensureSSHDirectory() -> Bool {
        let fm = FileManager.default
        let path = sshDirectory
        if !fm.fileExists(atPath: path) {
            do {
                try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
                try fm.setAttributes([.posixPermissions: 0o700], ofItemAtPath: path)
                return true
            } catch { return false }
        }
        return true
    }

    static func scanDirectory() -> SSHDirectoryInfo {
        let fm = FileManager.default
        let path = sshDirectory
        let exists = fm.fileExists(atPath: path)

        var perms = ""
        var permsOK = false
        if exists, let attrs = try? fm.attributesOfItem(atPath: path),
           let posix = attrs[.posixPermissions] as? Int {
            perms = String(format: "%o", posix)
            permsOK = perms == "700"
        }

        let configExists = fm.fileExists(atPath: (path as NSString).appendingPathComponent("config"))
        let authKeysExists = fm.fileExists(atPath: (path as NSString).appendingPathComponent("authorized_keys"))
        let keys = scanKeys()
        let knownHosts = parseKnownHosts()

        return SSHDirectoryInfo(
            path: path, exists: exists, permissions: perms, permissionsOK: permsOK,
            keyCount: keys.count, configExists: configExists,
            knownHostsCount: knownHosts.count, authorizedKeysExists: authKeysExists,
            staleKeyCount: keys.filter(\.isStale).count,
            permIssueCount: keys.filter { !$0.permissionsOK }.count
        )
    }

    // MARK: - Key Scanning

    static func scanKeys() -> [SSHKeyInfo] {
        let fm = FileManager.default
        let sshDir = sshDirectory
        guard fm.fileExists(atPath: sshDir) else { return [] }

        var keys: [SSHKeyInfo] = []
        let contents = (try? fm.contentsOfDirectory(atPath: sshDir)) ?? []
        let pubFiles = Set(contents.filter { $0.hasSuffix(".pub") })
        let defaultNames = ["id_ed25519", "id_rsa", "id_ecdsa", "id_dsa", "id_ed25519_sk", "id_ecdsa_sk"]
        let skipFiles: Set<String> = ["config", "known_hosts", "known_hosts.old", "authorized_keys", "environment", "rc"]

        // Parse config to link keys → hosts
        let hosts = parseSSHConfig()

        for file in contents {
            let fullPath = (sshDir as NSString).appendingPathComponent(file)
            guard !file.hasSuffix(".pub"), !skipFiles.contains(file),
                  !file.hasPrefix("."), !file.hasSuffix(".bak"), !file.hasSuffix(".old"), !file.hasSuffix(".backup") else { continue }

            var isDir: ObjCBool = false
            fm.fileExists(atPath: fullPath, isDirectory: &isDir)
            if isDir.boolValue { continue }

            guard let firstLine = readFirstLine(fullPath),
                  firstLine.contains("PRIVATE KEY") || pubFiles.contains(file + ".pub") || defaultNames.contains(file) else { continue }

            let pubPath = fullPath + ".pub"
            let hasPub = fm.fileExists(atPath: pubPath)
            let pubContent = hasPub ? (try? String(contentsOfFile: pubPath, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) : nil

            var keyType = "unknown"
            var bits = ""
            var fingerprint = ""
            var comment = ""

            if hasPub {
                let fpInfo = getFingerprint(pubPath)
                fingerprint = fpInfo.fingerprint; bits = fpInfo.bits; keyType = fpInfo.keyType; comment = fpInfo.comment
            } else {
                if firstLine.contains("OPENSSH") { keyType = "openssh" }
                else if firstLine.contains("RSA") { keyType = "rsa" }
                else if firstLine.contains("EC") { keyType = "ecdsa" }
                else if firstLine.contains("DSA") { keyType = "dsa" }
            }

            var permissions = ""
            var permissionsOK = false
            var createdDate: Date?
            var fileSize = 0

            if let attrs = try? fm.attributesOfItem(atPath: fullPath) {
                if let posix = attrs[.posixPermissions] as? Int {
                    permissions = String(format: "%o", posix)
                    permissionsOK = permissions == "600" || permissions == "400"
                }
                createdDate = attrs[.creationDate] as? Date
                fileSize = (attrs[.size] as? Int) ?? 0
            }

            let ageDays: Int
            if let date = createdDate {
                ageDays = max(0, Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0)
            } else {
                ageDays = 0
            }

            // Find which config hosts reference this key
            let linked = hosts.filter { host in
                let identity = host.identityFile
                    .replacingOccurrences(of: "~", with: NSHomeDirectory())
                return identity.hasSuffix(file) || identity.hasSuffix(file + ".pub")
            }.map(\.alias)

            var info = SSHKeyInfo(
                name: file, path: fullPath, publicKeyPath: hasPub ? pubPath : nil,
                keyType: keyType, bits: bits, fingerprint: fingerprint, comment: comment,
                publicKeyContent: pubContent, privateKeyFirstLine: firstLine,
                permissions: permissions, permissionsOK: permissionsOK,
                createdDate: createdDate, fileSize: fileSize, hasPassphrase: nil,
                isDefault: defaultNames.contains(file), ageDays: ageDays
            )
            info.linkedHosts = linked
            keys.append(info)
        }

        return keys.sorted { a, b in
            if a.isDefault != b.isDefault { return a.isDefault }
            return a.name < b.name
        }
    }

    // MARK: - SSH Config Parsing

    static func parseSSHConfig() -> [SSHHostConfig] {
        let configPath = (sshDirectory as NSString).appendingPathComponent("config")
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return [] }
        return parseSSHConfigContent(content)
    }

    static func parseSSHConfigContent(_ content: String) -> [SSHHostConfig] {
        var hosts: [SSHHostConfig] = []
        var currentAlias = ""
        var currentOptions: [(String, String)] = []
        var rawLines: [String] = []

        func flush() {
            guard !currentAlias.isEmpty, currentAlias != "*" else { return }
            let hostname = currentOptions.first(where: { $0.0.lowercased() == "hostname" })?.1 ?? ""
            let user = currentOptions.first(where: { $0.0.lowercased() == "user" })?.1 ?? ""
            let port = currentOptions.first(where: { $0.0.lowercased() == "port" })?.1 ?? "22"
            let identity = currentOptions.first(where: { $0.0.lowercased() == "identityfile" })?.1 ?? ""
            let others = currentOptions.filter { !["hostname", "user", "port", "identityfile"].contains($0.0.lowercased()) }
            hosts.append(SSHHostConfig(alias: currentAlias, hostname: hostname, user: user, port: port,
                                       identityFile: identity, otherOptions: others, raw: rawLines.joined(separator: "\n")))
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            if trimmed.lowercased().hasPrefix("host ") && !trimmed.lowercased().hasPrefix("hostname") {
                flush()
                currentAlias = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                currentOptions = []; rawLines = [line]
            } else if !currentAlias.isEmpty {
                rawLines.append(line)
                let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
                if parts.count == 2 { currentOptions.append((parts[0], parts[1])) }
            }
        }
        flush()
        return hosts
    }

    // MARK: - SSH Config Editing

    static func addHostToConfig(alias: String, hostname: String, user: String, port: String, identityFile: String, extraOptions: [(String, String)] = []) -> Bool {
        let configPath = (sshDirectory as NSString).appendingPathComponent("config")
        var content = (try? String(contentsOfFile: configPath, encoding: .utf8)) ?? ""

        if !content.isEmpty && !content.hasSuffix("\n") { content += "\n" }
        content += "\n"
        content += "Host \(alias)\n"
        if !hostname.isEmpty { content += "    HostName \(hostname)\n" }
        if !user.isEmpty { content += "    User \(user)\n" }
        if port != "22" && !port.isEmpty { content += "    Port \(port)\n" }
        if !identityFile.isEmpty { content += "    IdentityFile \(identityFile)\n" }
        for (key, value) in extraOptions { content += "    \(key) \(value)\n" }

        do {
            try content.write(toFile: configPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: configPath)
            return true
        } catch { return false }
    }

    static func removeHostFromConfig(alias: String) -> Bool {
        let configPath = (sshDirectory as NSString).appendingPathComponent("config")
        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else { return false }

        var lines = content.components(separatedBy: .newlines)
        var newLines: [String] = []
        var skipping = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("host ") && !trimmed.lowercased().hasPrefix("hostname") {
                let hostAlias = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                skipping = hostAlias == alias
                if !skipping { newLines.append(line) }
            } else if skipping {
                // Skip indented lines belonging to the host
                if !trimmed.isEmpty && !trimmed.hasPrefix("#") && (line.hasPrefix(" ") || line.hasPrefix("\t")) {
                    continue
                } else if trimmed.isEmpty {
                    continue // skip blank lines after host block
                } else {
                    skipping = false
                    newLines.append(line)
                }
            } else {
                newLines.append(line)
            }
        }

        // Clean up trailing blank lines
        while newLines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true && newLines.count > 1 {
            newLines.removeLast()
        }

        do {
            try newLines.joined(separator: "\n").write(toFile: configPath, atomically: true, encoding: .utf8)
            return true
        } catch { return false }
    }

    static func updateHostInConfig(oldAlias: String, alias: String, hostname: String, user: String, port: String, identityFile: String) -> Bool {
        guard removeHostFromConfig(alias: oldAlias) else { return false }
        return addHostToConfig(alias: alias, hostname: hostname, user: user, port: port, identityFile: identityFile)
    }

    // MARK: - Key Management

    static func deleteKeyPair(name: String) -> Bool {
        let fm = FileManager.default
        let privatePath = (sshDirectory as NSString).appendingPathComponent(name)
        let publicPath = privatePath + ".pub"
        var success = true
        if fm.fileExists(atPath: privatePath) {
            do { try fm.removeItem(atPath: privatePath) } catch { success = false }
        }
        if fm.fileExists(atPath: publicPath) {
            do { try fm.removeItem(atPath: publicPath) } catch { success = false }
        }
        return success
    }

    static func renameKeyPair(oldName: String, newName: String) -> Bool {
        let fm = FileManager.default
        let oldPrivate = (sshDirectory as NSString).appendingPathComponent(oldName)
        let oldPublic = oldPrivate + ".pub"
        let newPrivate = (sshDirectory as NSString).appendingPathComponent(newName)
        let newPublic = newPrivate + ".pub"

        // Don't overwrite existing
        if fm.fileExists(atPath: newPrivate) || fm.fileExists(atPath: newPublic) { return false }

        do {
            if fm.fileExists(atPath: oldPrivate) { try fm.moveItem(atPath: oldPrivate, toPath: newPrivate) }
            if fm.fileExists(atPath: oldPublic) { try fm.moveItem(atPath: oldPublic, toPath: newPublic) }
            return true
        } catch { return false }
    }

    static func importKey(privateKeyContent: String, publicKeyContent: String?, name: String) -> Bool {
        let fm = FileManager.default
        guard ensureSSHDirectory() else { return false }
        let privatePath = (sshDirectory as NSString).appendingPathComponent(name)
        if fm.fileExists(atPath: privatePath) { return false }

        do {
            try privateKeyContent.write(toFile: privatePath, atomically: true, encoding: .utf8)
            try fm.setAttributes([.posixPermissions: 0o600], ofItemAtPath: privatePath)
            if let pub = publicKeyContent {
                let pubPath = privatePath + ".pub"
                try pub.write(toFile: pubPath, atomically: true, encoding: .utf8)
                try fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: pubPath)
            }
            return true
        } catch { return false }
    }

    // MARK: - Known Hosts

    static func parseKnownHosts() -> [KnownHost] {
        let khPath = (sshDirectory as NSString).appendingPathComponent("known_hosts")
        guard let content = try? String(contentsOfFile: khPath, encoding: .utf8) else { return [] }
        var entries: [KnownHost] = []
        for (i, line) in content.components(separatedBy: .newlines).enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            let parts = trimmed.split(separator: " ", maxSplits: 2).map(String.init)
            guard parts.count >= 2 else { continue }
            let fingerprint = parts.count >= 3 ? String(parts[2].prefix(20)) + "..." : ""
            entries.append(KnownHost(hostname: parts[0], keyType: parts[1], keyFingerprint: fingerprint, lineNumber: i + 1))
        }
        return entries
    }

    static func removeKnownHost(hostname: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        process.arguments = ["-R", hostname]
        process.standardOutput = Pipe(); process.standardError = Pipe()
        do { try process.run(); process.waitUntilExit(); return process.terminationStatus == 0 } catch { return false }
    }

    // MARK: - Agent

    static func addToAgent(keyPath: String) -> (success: Bool, output: String) {
        runProcess("/usr/bin/ssh-add", args: [keyPath])
    }

    static func removeFromAgent(keyPath: String) -> (success: Bool, output: String) {
        runProcess("/usr/bin/ssh-add", args: ["-d", keyPath])
    }

    static func addAllToAgent() -> (success: Bool, output: String) {
        runProcess("/usr/bin/ssh-add", args: ["-A"])
    }

    static func removeAllFromAgent() -> (success: Bool, output: String) {
        runProcess("/usr/bin/ssh-add", args: ["-D"])
    }

    static func listAgentKeys() -> [String] {
        let result = runProcess("/usr/bin/ssh-add", args: ["-l"])
        if result.output.contains("no identities") { return [] }
        return result.output.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    static func isKeyInAgent(fingerprint: String) -> Bool {
        let agentKeys = listAgentKeys()
        return agentKeys.contains { $0.contains(fingerprint) }
    }

    // MARK: - Connection Test

    static func testConnection(host: String) -> (success: Bool, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = ["-T", "-o", "ConnectTimeout=5", "-o", "StrictHostKeyChecking=no", host]
        let outPipe = Pipe(); let errPipe = Pipe()
        process.standardOutput = outPipe; process.standardError = errPipe
        do {
            try process.run(); process.waitUntilExit()
            let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let combined = (out + err).trimmingCharacters(in: .whitespacesAndNewlines)
            let isSuccess = process.terminationStatus == 0 || combined.lowercased().contains("successfully authenticated")
            return (isSuccess, combined)
        } catch { return (false, error.localizedDescription) }
    }

    // MARK: - Permissions

    static func fixPermissions(path: String, isDirectory: Bool = false) -> Bool {
        do {
            try FileManager.default.setAttributes([.posixPermissions: isDirectory ? 0o700 : 0o600], ofItemAtPath: path)
            return true
        } catch { return false }
    }

    static func fixAllPermissions() -> Int {
        var fixed = 0
        let _ = fixPermissions(path: sshDirectory, isDirectory: true)
        for key in scanKeys() {
            if !key.permissionsOK {
                if fixPermissions(path: key.path) { fixed += 1 }
            }
        }
        // Fix config permissions
        let configPath = (sshDirectory as NSString).appendingPathComponent("config")
        if FileManager.default.fileExists(atPath: configPath) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: configPath),
               let posix = attrs[.posixPermissions] as? Int, String(format: "%o", posix) != "644" {
                try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: configPath)
                fixed += 1
            }
        }
        return fixed
    }

    // MARK: - Helpers

    private static func readFirstLine(_ path: String) -> String? {
        guard let handle = FileHandle(forReadingAtPath: path) else { return nil }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: 256)
        guard let str = String(data: data, encoding: .utf8) else { return nil }
        return str.components(separatedBy: .newlines).first
    }

    static func getFingerprint(_ pubKeyPath: String) -> (fingerprint: String, bits: String, keyType: String, comment: String) {
        let result = runProcess("/usr/bin/ssh-keygen", args: ["-l", "-f", pubKeyPath])
        let output = result.output
        let parts = output.split(separator: " ", maxSplits: 2).map(String.init)
        let bits = parts.first ?? ""
        let fingerprint = parts.count > 1 ? parts[1] : ""
        let rest = parts.count > 2 ? parts[2] : ""
        var keyType = ""
        var comment = rest
        if let parenOpen = rest.lastIndex(of: "("), let parenClose = rest.lastIndex(of: ")") {
            keyType = String(rest[rest.index(after: parenOpen)..<parenClose]).lowercased()
            comment = String(rest[..<parenOpen]).trimmingCharacters(in: .whitespaces)
        }
        return (fingerprint, bits, keyType, comment)
    }

    private static func runProcess(_ path: String, args: [String]) -> (success: Bool, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = args
        let outPipe = Pipe(); let errPipe = Pipe()
        process.standardOutput = outPipe; process.standardError = errPipe
        do {
            try process.run(); process.waitUntilExit()
            let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            return (process.terminationStatus == 0, (out + err).trimmingCharacters(in: .whitespacesAndNewlines))
        } catch { return (false, error.localizedDescription) }
    }
}

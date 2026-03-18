import SwiftUI

@Observable
class SSHManagerViewModel {
    var keys: [SSHManagerService.SSHKeyInfo] = []
    var hosts: [SSHManagerService.SSHHostConfig] = []
    var knownHosts: [SSHManagerService.KnownHost] = []
    var agentKeys: [String] = []
    var directoryInfo: SSHManagerService.SSHDirectoryInfo?

    var selectedKey: SSHManagerService.SSHKeyInfo?
    var selectedHost: SSHManagerService.SSHHostConfig?

    var tab: Tab = .keys
    var isLoading: Bool = false
    var statusMessage: String = ""
    var statusIsError: Bool = false

    // Search & filter
    var searchText: String = ""
    var keyFilter: KeyFilter = .all

    // Sheets
    var showGenerateSheet: Bool = false
    var showImportSheet: Bool = false
    var showAddHostSheet: Bool = false
    var showEditHostSheet: Bool = false
    var showRenameSheet: Bool = false
    var showDeleteConfirm: Bool = false

    // Generate
    var genKeyType: SSHKeyService.KeyType = .ed25519
    var genComment: String = ""
    var genFileName: String = ""
    var genKeyPair: SSHKeyService.KeyPair?
    var isGenerating: Bool = false
    var genSaved: Bool = false
    var genError: String = ""

    // Import
    var importPrivateKey: String = ""
    var importPublicKey: String = ""
    var importName: String = ""

    // Add/Edit Host
    var editHostAlias: String = ""
    var editHostHostname: String = ""
    var editHostUser: String = ""
    var editHostPort: String = "22"
    var editHostIdentityFile: String = ""
    var editHostOriginalAlias: String = ""

    // Rename
    var renameName: String = ""

    // Connection test
    var testingHost: String?
    var testResult: String?
    var testSuccess: Bool = false

    enum Tab: String, CaseIterable {
        case keys = "Keys"
        case config = "Config"
        case knownHosts = "Known Hosts"
        case agent = "Agent"
    }

    enum KeyFilter: String, CaseIterable {
        case all = "All"
        case ed25519 = "Ed25519"
        case rsa = "RSA"
        case stale = "Stale"
        case permIssues = "⚠ Perms"
    }

    // MARK: - Filtered Keys

    var filteredKeys: [SSHManagerService.SSHKeyInfo] {
        var result = keys

        // Filter by type
        switch keyFilter {
        case .all: break
        case .ed25519: result = result.filter { $0.keyType.lowercased() == "ed25519" }
        case .rsa: result = result.filter { $0.keyType.lowercased() == "rsa" }
        case .stale: result = result.filter(\.isStale)
        case .permIssues: result = result.filter { !$0.permissionsOK }
        }

        // Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(q) ||
                $0.comment.lowercased().contains(q) ||
                $0.keyType.lowercased().contains(q) ||
                $0.fingerprint.lowercased().contains(q) ||
                $0.linkedHosts.joined(separator: " ").lowercased().contains(q)
            }
        }

        return result
    }

    // MARK: - Refresh

    func refresh() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let scannedKeys = SSHManagerService.scanKeys()
            let scannedHosts = SSHManagerService.parseSSHConfig()
            let scannedKnown = SSHManagerService.parseKnownHosts()
            let scannedAgent = SSHManagerService.listAgentKeys()
            let dirInfo = SSHManagerService.scanDirectory()
            DispatchQueue.main.async {
                self.keys = scannedKeys
                self.hosts = scannedHosts
                self.knownHosts = scannedKnown
                self.agentKeys = scannedAgent
                self.directoryInfo = dirInfo
                self.isLoading = false
                if self.selectedKey == nil { self.selectedKey = scannedKeys.first }
            }
        }
    }

    func showStatus(_ msg: String, isError: Bool = false) {
        statusMessage = msg
        statusIsError = isError
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            if self?.statusMessage == msg { self?.statusMessage = "" }
        }
    }

    // MARK: - Key Actions

    func copyPublicKey(_ key: SSHManagerService.SSHKeyInfo) {
        guard let content = key.publicKeyContent else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }

    func addToAgent(_ key: SSHManagerService.SSHKeyInfo) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHManagerService.addToAgent(keyPath: key.path)
            DispatchQueue.main.async {
                self.showStatus(result.success ? "Added to agent" : "Failed: \(result.output)", isError: !result.success)
                self.agentKeys = SSHManagerService.listAgentKeys()
            }
        }
    }

    func removeFromAgent(_ key: SSHManagerService.SSHKeyInfo) {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHManagerService.removeFromAgent(keyPath: key.path)
            DispatchQueue.main.async {
                self.showStatus(result.success ? "Removed from agent" : result.output, isError: !result.success)
                self.agentKeys = SSHManagerService.listAgentKeys()
            }
        }
    }

    func fixPermissions(_ key: SSHManagerService.SSHKeyInfo) {
        let success = SSHManagerService.fixPermissions(path: key.path)
        showStatus(success ? "Permissions fixed to 600" : "Failed to fix permissions", isError: !success)
        refresh()
    }

    func fixAllPermissions() {
        let count = SSHManagerService.fixAllPermissions()
        showStatus("Fixed \(count) permission issue\(count == 1 ? "" : "s")")
        refresh()
    }

    func deleteKey(_ key: SSHManagerService.SSHKeyInfo) {
        let success = SSHManagerService.deleteKeyPair(name: key.name)
        showStatus(success ? "Deleted \(key.name)" : "Failed to delete", isError: !success)
        if selectedKey?.path == key.path { selectedKey = nil }
        refresh()
    }

    func renameKey(_ key: SSHManagerService.SSHKeyInfo) {
        let newName = renameName.trimmingCharacters(in: .whitespaces)
        guard !newName.isEmpty else { return }
        let success = SSHManagerService.renameKeyPair(oldName: key.name, newName: newName)
        showStatus(success ? "Renamed to \(newName)" : "Failed — name may already exist", isError: !success)
        if success { selectedKey = nil }
        refresh()
        showRenameSheet = false
    }

    func isKeyInAgent(_ key: SSHManagerService.SSHKeyInfo) -> Bool {
        guard !key.fingerprint.isEmpty else { return false }
        return agentKeys.contains { $0.contains(key.fingerprint) }
    }

    // MARK: - Import

    func importKey() {
        let name = importName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !importPrivateKey.isEmpty else {
            showStatus("Name and private key are required", isError: true)
            return
        }
        let pub = importPublicKey.isEmpty ? nil : importPublicKey
        let success = SSHManagerService.importKey(privateKeyContent: importPrivateKey, publicKeyContent: pub, name: name)
        showStatus(success ? "Imported \(name) to ~/.ssh/" : "Failed — file may already exist", isError: !success)
        if success {
            showImportSheet = false
            importPrivateKey = ""; importPublicKey = ""; importName = ""
            refresh()
        }
    }

    // MARK: - SSH Config Editing

    func addHost() {
        let alias = editHostAlias.trimmingCharacters(in: .whitespaces)
        guard !alias.isEmpty else { return }
        let success = SSHManagerService.addHostToConfig(
            alias: alias, hostname: editHostHostname, user: editHostUser,
            port: editHostPort, identityFile: editHostIdentityFile
        )
        showStatus(success ? "Added host \(alias)" : "Failed to add host", isError: !success)
        if success { showAddHostSheet = false; clearHostForm(); refresh() }
    }

    func updateHost() {
        let alias = editHostAlias.trimmingCharacters(in: .whitespaces)
        guard !alias.isEmpty else { return }
        let success = SSHManagerService.updateHostInConfig(
            oldAlias: editHostOriginalAlias, alias: alias,
            hostname: editHostHostname, user: editHostUser,
            port: editHostPort, identityFile: editHostIdentityFile
        )
        showStatus(success ? "Updated \(alias)" : "Failed to update", isError: !success)
        if success { showEditHostSheet = false; clearHostForm(); refresh() }
    }

    func removeHost(_ host: SSHManagerService.SSHHostConfig) {
        let success = SSHManagerService.removeHostFromConfig(alias: host.alias)
        showStatus(success ? "Removed \(host.alias)" : "Failed to remove", isError: !success)
        refresh()
    }

    func startEditHost(_ host: SSHManagerService.SSHHostConfig) {
        editHostOriginalAlias = host.alias
        editHostAlias = host.alias
        editHostHostname = host.hostname
        editHostUser = host.user
        editHostPort = host.port
        editHostIdentityFile = host.identityFile
        showEditHostSheet = true
    }

    func clearHostForm() {
        editHostAlias = ""; editHostHostname = ""; editHostUser = ""
        editHostPort = "22"; editHostIdentityFile = ""; editHostOriginalAlias = ""
    }

    // MARK: - Known Hosts

    func removeKnownHost(_ host: SSHManagerService.KnownHost) {
        let success = SSHManagerService.removeKnownHost(hostname: host.hostname)
        showStatus(success ? "Removed \(host.hostname)" : "Failed to remove", isError: !success)
        knownHosts = SSHManagerService.parseKnownHosts()
    }

    // MARK: - Agent Bulk

    func addAllToAgent() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHManagerService.addAllToAgent()
            DispatchQueue.main.async {
                self.showStatus(result.success ? "All keys added to agent" : result.output, isError: !result.success)
                self.agentKeys = SSHManagerService.listAgentKeys()
            }
        }
    }

    func removeAllFromAgent() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHManagerService.removeAllFromAgent()
            DispatchQueue.main.async {
                self.showStatus(result.success ? "Agent cleared" : result.output, isError: !result.success)
                self.agentKeys = SSHManagerService.listAgentKeys()
            }
        }
    }

    // MARK: - Connection Test

    func testConnection(_ host: SSHManagerService.SSHHostConfig) {
        testingHost = host.alias; testResult = nil
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHManagerService.testConnection(host: host.alias)
            DispatchQueue.main.async {
                self.testResult = result.output; self.testSuccess = result.success; self.testingHost = nil
            }
        }
    }

    // MARK: - Generate

    var defaultFileName: String { "id_\(genKeyType.algorithm)" }
    var resolvedFileName: String { genFileName.trimmingCharacters(in: .whitespaces).isEmpty ? defaultFileName : genFileName.trimmingCharacters(in: .whitespaces) }
    var targetPrivatePath: String { (SSHManagerService.sshDirectory as NSString).appendingPathComponent(resolvedFileName) }
    var targetPublicPath: String { targetPrivatePath + ".pub" }
    var fileAlreadyExists: Bool { FileManager.default.fileExists(atPath: targetPrivatePath) || FileManager.default.fileExists(atPath: targetPublicPath) }

    func generateKey() {
        isGenerating = true; genSaved = false; genError = ""
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHKeyService.generate(type: genKeyType, comment: genComment)
            DispatchQueue.main.async {
                self.genKeyPair = result; self.isGenerating = false
                if result != nil { self.autoSaveToSSH() }
            }
        }
    }

    func autoSaveToSSH() {
        guard let kp = genKeyPair else { return }
        guard SSHManagerService.ensureSSHDirectory() else { genError = "Failed to create ~/.ssh"; return }
        let privPath = targetPrivatePath; let pubPath = targetPublicPath
        if FileManager.default.fileExists(atPath: privPath) || FileManager.default.fileExists(atPath: pubPath) {
            genError = "File already exists: \(resolvedFileName)"; return
        }
        do {
            try kp.privateKey.write(toFile: privPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: privPath)
            try kp.publicKey.write(toFile: pubPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: pubPath)
            genSaved = true; genError = ""; showStatus("Saved to ~/.ssh/\(resolvedFileName)"); refresh()
        } catch { genError = "Failed to save: \(error.localizedDescription)" }
    }

    func revealInFinder(_ path: String) {
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}

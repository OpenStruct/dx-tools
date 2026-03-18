import XCTest
@testable import DX_Tools

final class SSHManagerServiceTests: XCTestCase {

    // MARK: - Directory Scan

    func testScanDirectoryReturnsInfo() {
        let info = SSHManagerService.scanDirectory()
        XCTAssertFalse(info.path.isEmpty)
        XCTAssertTrue(info.path.hasSuffix(".ssh"))
    }

    func testScanDirectoryPathIsCorrect() {
        let info = SSHManagerService.scanDirectory()
        XCTAssertTrue(info.path.contains("/.ssh"))
    }

    // MARK: - Key Scanning

    func testScanKeysReturnsArray() {
        let keys = SSHManagerService.scanKeys()
        // May be empty on CI but should not crash
        XCTAssertNotNil(keys)
    }

    func testScanKeysHasValidFields() {
        let keys = SSHManagerService.scanKeys()
        for key in keys {
            XCTAssertFalse(key.name.isEmpty, "Key name should not be empty")
            XCTAssertFalse(key.path.isEmpty, "Key path should not be empty")
            XCTAssertTrue(FileManager.default.fileExists(atPath: key.path), "Key file should exist at \(key.path)")
        }
    }

    func testScanKeysDefaultKeysMarked() {
        let keys = SSHManagerService.scanKeys()
        let defaults = keys.filter(\.isDefault)
        // Default keys should have recognizable names
        for key in defaults {
            let defaultNames = ["id_ed25519", "id_rsa", "id_ecdsa", "id_dsa", "id_ed25519_sk", "id_ecdsa_sk"]
            XCTAssertTrue(defaultNames.contains(key.name), "\(key.name) marked as default but not in default names list")
        }
    }

    // MARK: - SSH Config Parsing

    func testParseSSHConfigReturnsArray() {
        let hosts = SSHManagerService.parseSSHConfig()
        // May be empty if no config exists
        XCTAssertNotNil(hosts)
    }

    func testParseSSHConfigHostsHaveAliases() {
        let hosts = SSHManagerService.parseSSHConfig()
        for host in hosts {
            XCTAssertFalse(host.alias.isEmpty, "SSH config host alias should not be empty")
            XCTAssertNotEqual(host.alias, "*", "Wildcard host should be filtered")
        }
    }

    // MARK: - Known Hosts

    func testParseKnownHostsReturnsArray() {
        let hosts = SSHManagerService.parseKnownHosts()
        XCTAssertNotNil(hosts)
    }

    func testParseKnownHostsHaveLineNumbers() {
        let hosts = SSHManagerService.parseKnownHosts()
        for host in hosts {
            XCTAssertGreaterThan(host.lineNumber, 0)
            XCTAssertFalse(host.hostname.isEmpty)
            XCTAssertFalse(host.keyType.isEmpty)
        }
    }

    // MARK: - Agent

    func testListAgentKeysReturnsArray() {
        let keys = SSHManagerService.listAgentKeys()
        XCTAssertNotNil(keys)
    }

    // MARK: - Permissions

    func testFixPermissionsOnTempFile() {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        FileManager.default.createFile(atPath: tmp.path, contents: Data("test".utf8))
        defer { try? FileManager.default.removeItem(at: tmp) }

        // Set wrong permissions first
        try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: tmp.path)

        let success = SSHManagerService.fixPermissions(path: tmp.path)
        XCTAssertTrue(success)

        // Verify
        let attrs = try? FileManager.default.attributesOfItem(atPath: tmp.path)
        let posix = attrs?[.posixPermissions] as? Int
        XCTAssertEqual(posix, 0o600)
    }

    // MARK: - Key Info Model

    func testSSHKeyInfoIdentifiable() {
        let key = SSHManagerService.SSHKeyInfo(
            name: "test_key", path: "/tmp/test", publicKeyPath: nil,
            keyType: "ed25519", bits: "256", fingerprint: "SHA256:test",
            comment: "test@host", publicKeyContent: nil,
            privateKeyFirstLine: "-----BEGIN OPENSSH PRIVATE KEY-----",
            permissions: "600", permissionsOK: true,
            createdDate: Date(), fileSize: 464, hasPassphrase: nil, isDefault: false, ageDays: 30
        )
        XCTAssertEqual(key.name, "test_key")
        XCTAssertEqual(key.keyType, "ed25519")
        XCTAssertTrue(key.permissionsOK)
        XCTAssertFalse(key.isDefault)
        XCTAssertFalse(key.isStale)
        XCTAssertEqual(key.ageDescription, "1mo ago")
    }

    // MARK: - SSH Host Config Model

    func testSSHHostConfigModel() {
        let host = SSHManagerService.SSHHostConfig(
            alias: "github", hostname: "github.com", user: "git",
            port: "22", identityFile: "~/.ssh/id_ed25519",
            otherOptions: [("ForwardAgent", "yes")],
            raw: "Host github\n  HostName github.com"
        )
        XCTAssertEqual(host.alias, "github")
        XCTAssertEqual(host.hostname, "github.com")
        XCTAssertEqual(host.user, "git")
        XCTAssertEqual(host.identityFile, "~/.ssh/id_ed25519")
        XCTAssertEqual(host.otherOptions.count, 1)
    }

    // MARK: - Key Age

    func testKeyAgeFresh() {
        let key = SSHManagerService.SSHKeyInfo(
            name: "fresh", path: "/tmp/test", publicKeyPath: nil, keyType: "ed25519",
            bits: "256", fingerprint: "", comment: "", publicKeyContent: nil,
            privateKeyFirstLine: "", permissions: "600", permissionsOK: true,
            createdDate: Date(), fileSize: 100, hasPassphrase: nil, isDefault: false, ageDays: 10
        )
        XCTAssertFalse(key.isStale)
        XCTAssertFalse(key.isAncient)
        XCTAssertEqual(key.ageDescription, "10d ago")
    }

    func testKeyAgeStale() {
        let key = SSHManagerService.SSHKeyInfo(
            name: "old", path: "/tmp/test", publicKeyPath: nil, keyType: "rsa",
            bits: "4096", fingerprint: "", comment: "", publicKeyContent: nil,
            privateKeyFirstLine: "", permissions: "600", permissionsOK: true,
            createdDate: nil, fileSize: 100, hasPassphrase: nil, isDefault: false, ageDays: 400
        )
        XCTAssertTrue(key.isStale)
        XCTAssertFalse(key.isAncient)
    }

    func testKeyAgeAncient() {
        let key = SSHManagerService.SSHKeyInfo(
            name: "ancient", path: "/tmp/test", publicKeyPath: nil, keyType: "dsa",
            bits: "1024", fingerprint: "", comment: "", publicKeyContent: nil,
            privateKeyFirstLine: "", permissions: "644", permissionsOK: false,
            createdDate: nil, fileSize: 100, hasPassphrase: nil, isDefault: false, ageDays: 800
        )
        XCTAssertTrue(key.isStale)
        XCTAssertTrue(key.isAncient)
    }

    // MARK: - SSH Config Parsing

    func testParseSSHConfigContent() {
        let config = """
        Host github
            HostName github.com
            User git
            IdentityFile ~/.ssh/id_ed25519

        Host prod-server
            HostName 10.0.0.1
            User deploy
            Port 2222
            IdentityFile ~/.ssh/id_rsa
        """
        let hosts = SSHManagerService.parseSSHConfigContent(config)
        XCTAssertEqual(hosts.count, 2)
        XCTAssertEqual(hosts[0].alias, "github")
        XCTAssertEqual(hosts[0].hostname, "github.com")
        XCTAssertEqual(hosts[0].user, "git")
        XCTAssertEqual(hosts[1].alias, "prod-server")
        XCTAssertEqual(hosts[1].port, "2222")
    }

    func testParseSSHConfigWildcardFiltered() {
        let config = """
        Host *
            AddKeysToAgent yes

        Host myhost
            HostName example.com
        """
        let hosts = SSHManagerService.parseSSHConfigContent(config)
        XCTAssertEqual(hosts.count, 1)
        XCTAssertEqual(hosts[0].alias, "myhost")
    }

    // MARK: - Key Import/Delete/Rename

    func testImportAndDeleteKey() {
        let name = "test_import_\(UUID().uuidString.prefix(8))"
        let privateKey = "-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----"
        let publicKey = "ssh-ed25519 AAAA test@test"

        let imported = SSHManagerService.importKey(privateKeyContent: privateKey, publicKeyContent: publicKey, name: name)
        XCTAssertTrue(imported)

        let privatePath = (SSHManagerService.sshDirectory as NSString).appendingPathComponent(name)
        XCTAssertTrue(FileManager.default.fileExists(atPath: privatePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: privatePath + ".pub"))

        // Check permissions
        if let attrs = try? FileManager.default.attributesOfItem(atPath: privatePath),
           let posix = attrs[.posixPermissions] as? Int {
            XCTAssertEqual(String(format: "%o", posix), "600")
        }

        // Duplicate should fail
        let duplicate = SSHManagerService.importKey(privateKeyContent: privateKey, publicKeyContent: publicKey, name: name)
        XCTAssertFalse(duplicate)

        // Delete
        let deleted = SSHManagerService.deleteKeyPair(name: name)
        XCTAssertTrue(deleted)
        XCTAssertFalse(FileManager.default.fileExists(atPath: privatePath))
    }

    func testRenameKey() {
        let oldName = "test_rename_old_\(UUID().uuidString.prefix(8))"
        let newName = "test_rename_new_\(UUID().uuidString.prefix(8))"
        let privateKey = "-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----"

        _ = SSHManagerService.importKey(privateKeyContent: privateKey, publicKeyContent: nil, name: oldName)
        let renamed = SSHManagerService.renameKeyPair(oldName: oldName, newName: newName)
        XCTAssertTrue(renamed)

        let newPath = (SSHManagerService.sshDirectory as NSString).appendingPathComponent(newName)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newPath))

        // Cleanup
        _ = SSHManagerService.deleteKeyPair(name: newName)
    }

    // MARK: - Integration

    func testSshDirectoryPath() {
        let dir = SSHManagerService.sshDirectory
        XCTAssertTrue(dir.hasSuffix("/.ssh"))
        XCTAssertTrue(dir.hasPrefix("/Users/") || dir.hasPrefix("/home/") || dir.hasPrefix("/root"))
    }
}

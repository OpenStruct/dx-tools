import Foundation

struct SSHKeyService {
    enum KeyType: String, CaseIterable {
        case ed25519 = "Ed25519"
        case rsa2048 = "RSA 2048"
        case rsa4096 = "RSA 4096"

        var algorithm: String {
            switch self {
            case .ed25519: return "ed25519"
            case .rsa2048, .rsa4096: return "rsa"
            }
        }

        var bits: Int? {
            switch self {
            case .ed25519: return nil
            case .rsa2048: return 2048
            case .rsa4096: return 4096
            }
        }
    }

    struct KeyPair {
        let privateKey: String
        let publicKey: String
        let fingerprint: String
        let type: KeyType
    }

    static func generate(type: KeyType, comment: String = "") -> KeyPair? {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let keyPath = tmpDir.appendingPathComponent("id_key").path
        var args = ["-t", type.algorithm, "-f", keyPath, "-N", ""]
        if let bits = type.bits {
            args += ["-b", "\(bits)"]
        }
        if !comment.isEmpty {
            args += ["-C", comment]
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        process.arguments = args
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }

            let privateKey = try String(contentsOfFile: keyPath, encoding: .utf8)
            let publicKey = try String(contentsOfFile: keyPath + ".pub", encoding: .utf8)

            // Get fingerprint
            let fpProcess = Process()
            fpProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
            fpProcess.arguments = ["-l", "-f", keyPath + ".pub"]
            let fpPipe = Pipe()
            fpProcess.standardOutput = fpPipe
            fpProcess.standardError = Pipe()
            try fpProcess.run()
            fpProcess.waitUntilExit()
            let fpData = fpPipe.fileHandleForReading.readDataToEndOfFile()
            let fingerprint = String(data: fpData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return KeyPair(privateKey: privateKey, publicKey: publicKey, fingerprint: fingerprint, type: type)
        } catch {
            return nil
        }
    }
}

import SwiftUI

@Observable
class SSHKeyViewModel {
    var keyType: SSHKeyService.KeyType = .ed25519
    var comment: String = ""
    var keyPair: SSHKeyService.KeyPair?
    var isGenerating: Bool = false

    func generate() {
        isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            let result = SSHKeyService.generate(type: keyType, comment: comment)
            DispatchQueue.main.async {
                self.keyPair = result
                self.isGenerating = false
            }
        }
    }

    func copyPrivate() {
        guard let kp = keyPair else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(kp.privateKey, forType: .string)
    }

    func copyPublic() {
        guard let kp = keyPair else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(kp.publicKey, forType: .string)
    }

    func saveKey(isPublic: Bool) {
        guard let kp = keyPair else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = isPublic ? "id_\(keyType.algorithm).pub" : "id_\(keyType.algorithm)"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            let content = isPublic ? kp.publicKey : kp.privateKey
            try? content.write(to: url, atomically: true, encoding: .utf8)
            if !isPublic {
                // Set correct permissions for private key
                try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            }
        }
    }
}

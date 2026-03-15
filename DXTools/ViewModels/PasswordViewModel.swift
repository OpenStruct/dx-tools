import SwiftUI

struct GeneratedPassword: Identifiable {
    let id = UUID()
    let value: String
    let strength: PasswordService.Strength
}

@Observable
class PasswordViewModel {
    var passwords: [GeneratedPassword] = []
    var count: Int = 5
    var length: Int = 24
    var includeSpecial: Bool = true
    var isPhrase: Bool = false
    var wordCount: Int = 4
    var copiedId: UUID? = nil

    func generate() {
        if isPhrase {
            passwords = (0..<count).map { _ in
                let phrase = PasswordService.generatePassphrase(wordCount: wordCount)
                return GeneratedPassword(value: phrase, strength: .strong)
            }
        } else {
            passwords = (0..<count).map { _ in
                let pass = PasswordService.generatePassword(length: length, includeSpecial: includeSpecial)
                let strength = PasswordService.evaluateStrength(pass)
                return GeneratedPassword(value: pass, strength: strength)
            }
        }
    }

    func copyOne(_ password: GeneratedPassword) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(password.value, forType: .string)
        copiedId = password.id
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if self?.copiedId == password.id { self?.copiedId = nil }
        }
    }

    func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(passwords.map(\.value).joined(separator: "\n"), forType: .string)
    }

    init() { generate() }
}

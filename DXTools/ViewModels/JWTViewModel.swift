import SwiftUI

@Observable
class JWTViewModel {
    var input: String = ""
    var decoded: JWTService.DecodedJWT?
    var errorMessage: String?

    func decode() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            decoded = nil; errorMessage = nil; return
        }
        switch JWTService.decode(input) {
        case .success(let result): decoded = result; errorMessage = nil
        case .failure(let error): decoded = nil; errorMessage = error.localizedDescription
        }
    }

    func clear() { input = ""; decoded = nil; errorMessage = nil }

    func paste() {
        if let s = NSPasteboard.general.string(forType: .string) { input = s; decode() }
    }

    func loadSample() {
        input = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ik5hbSIsImVtYWlsIjoibmFtQGV4YW1wbGUuY29tIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE5MDAwMDAwMDB9.signature"
        decode()
    }
}

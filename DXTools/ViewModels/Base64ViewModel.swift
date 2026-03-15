import SwiftUI

@Observable
class Base64ViewModel {
    var input: String = ""
    var output: String = ""
    var errorMessage: String?
    var isEncoding: Bool = true
    var urlSafe: Bool = false
    var stats: String = ""

    func process() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""; errorMessage = nil; stats = ""; return
        }
        if isEncoding {
            output = Base64Service.encode(input, urlSafe: urlSafe)
            errorMessage = nil
            stats = "\(input.utf8.count) bytes → \(output.count) chars"
        } else {
            switch Base64Service.decodeToString(input) {
            case .success(let result):
                output = result; errorMessage = nil
                stats = "\(input.count) chars → \(result.utf8.count) bytes"
            case .failure(let error):
                output = ""; errorMessage = error.localizedDescription; stats = ""
            }
        }
    }

    func clear() { input = ""; output = ""; errorMessage = nil; stats = "" }
    func copyOutput() { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(output, forType: .string) }
    func swap() { let tmp = output; output = input; input = tmp; isEncoding.toggle(); process() }
}

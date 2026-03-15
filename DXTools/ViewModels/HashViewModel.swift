import SwiftUI

@Observable
class HashViewModel {
    var input: String = ""
    var result: HashService.HashResult?
    var selectedFile: URL?
    var source: String = ""

    func hashInput() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result = nil; source = ""; return
        }
        result = HashService.hash(string: input)
        source = "String (\(input.utf8.count) bytes)"
    }

    func hashFile(url: URL) {
        selectedFile = url
        result = HashService.hash(fileURL: url)
        source = url.lastPathComponent
    }

    func clear() { input = ""; result = nil; selectedFile = nil; source = "" }

    func copyHash(_ hash: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(hash, forType: .string)
    }
}

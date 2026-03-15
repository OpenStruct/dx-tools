import SwiftUI

@Observable
class JSONFormatterViewModel {
    var input: String = ""
    var output: String = ""
    var errorMessage: String?
    var indentStyle: JSONFormatterService.IndentStyle = .twoSpaces
    var isValid: Bool? = nil
    var stats: String = ""

    func format() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""
            errorMessage = nil
            isValid = nil
            stats = ""
            return
        }

        switch JSONFormatterService.format(input, indent: indentStyle) {
        case .success(let result):
            output = result
            errorMessage = nil
            isValid = true
            updateStats()
        case .failure(let error):
            output = ""
            errorMessage = error.localizedDescription
            isValid = false
            stats = ""
        }
    }

    func minify() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        switch JSONFormatterService.minify(input) {
        case .success(let result):
            output = result
            errorMessage = nil
            isValid = true
            let saved = input.utf8.count - result.utf8.count
            let pct = Double(saved) / Double(input.utf8.count) * 100
            stats = "Minified: \(result.utf8.count) bytes (saved \(saved) bytes / \(String(format: "%.0f", pct))%)"
        case .failure(let error):
            output = ""
            errorMessage = error.localizedDescription
            isValid = false
        }
    }

    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = nil
        stats = ""
    }

    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }

    func pasteAndFormat() {
        if let str = NSPasteboard.general.string(forType: .string) {
            input = str
            format()
        }
    }

    func loadSample() {
        input = """
        {"users":[{"id":1,"name":"Nam","email":"nam@example.com","active":true,"scores":[98,85,92],"address":{"city":"London","country":"UK","zip":"EC1A"}},{"id":2,"name":"Alice","email":"alice@example.com","active":false,"scores":[100,97],"address":{"city":"New York","country":"US","zip":"10001"}}],"meta":{"total":2,"page":1,"per_page":20}}
        """
        format()
    }

    private func updateStats() {
        let validation = JSONFormatterService.validate(input)
        var parts: [String] = []
        if let type = validation.type { parts.append(type) }
        if let count = validation.count { parts.append("\(count) \(validation.type == "Array" ? "items" : "keys")") }
        parts.append("\(validation.size) bytes")
        stats = parts.joined(separator: " · ")
    }
}

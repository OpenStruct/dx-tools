import SwiftUI

@Observable
class CurlToCodeViewModel {
    var input: String = ""
    var output: String = ""
    var selectedLanguage: Language = .swift
    var errorMessage: String?

    enum Language: String, CaseIterable {
        case swift = "Swift"
        case go = "Go"
        case python = "Python"
        case javascript = "JavaScript"
        case ruby = "Ruby"
    }

    func convert() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""; return
        }
        let parsed = CurlToCodeService.parse(input)
        guard !parsed.url.isEmpty else {
            errorMessage = "Could not find a URL in the curl command"
            output = ""; return
        }
        errorMessage = nil
        switch selectedLanguage {
        case .swift: output = CurlToCodeService.toSwift(parsed)
        case .go: output = CurlToCodeService.toGo(parsed)
        case .python: output = CurlToCodeService.toPython(parsed)
        case .javascript: output = CurlToCodeService.toJavaScript(parsed)
        case .ruby: output = CurlToCodeService.toRuby(parsed)
        }
    }

    func loadSample() {
        input = """
        curl -X POST 'https://api.example.com/v1/users' \\
          -H 'Content-Type: application/json' \\
          -H 'Authorization: Bearer sk-1234567890' \\
          -d '{"name": "Nam", "email": "nam@example.com", "role": "admin"}'
        """
        convert()
    }

    func clear() { input = ""; output = ""; errorMessage = nil }
    func copyOutput() { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(output, forType: .string) }
    func pasteAndConvert() { if let s = NSPasteboard.general.string(forType: .string) { input = s; convert() } }
}

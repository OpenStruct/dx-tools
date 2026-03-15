import SwiftUI

@Observable
class JSONToSwiftViewModel {
    var input: String = ""
    var output: String = ""
    var errorMessage: String?
    var rootName: String = "Root"
    var useLetProperties: Bool = true
    var addCodingKeys: Bool = false

    func convert() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""; errorMessage = nil; return
        }
        let options = JSONToSwiftService.Options(
            rootName: rootName.isEmpty ? "Root" : rootName,
            useLetProperties: useLetProperties,
            addCodingKeys: addCodingKeys
        )
        switch JSONToSwiftService.convert(input, options: options) {
        case .success(let r): output = r; errorMessage = nil
        case .failure(let e): output = ""; errorMessage = e.localizedDescription
        }
    }

    func clear() { input = ""; output = ""; errorMessage = nil }
    func copyOutput() { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(output, forType: .string) }
    func pasteAndConvert() { if let s = NSPasteboard.general.string(forType: .string) { input = s; convert() } }
}

@Observable
class JSONToTypeScriptViewModel {
    var input: String = ""
    var output: String = ""
    var errorMessage: String?
    var rootName: String = "Root"
    var useInterface: Bool = true
    var readOnly: Bool = false

    func convert() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""; errorMessage = nil; return
        }
        let options = JSONToTypeScriptService.Options(
            rootName: rootName.isEmpty ? "Root" : rootName,
            useInterface: useInterface,
            readOnly: readOnly
        )
        switch JSONToTypeScriptService.convert(input, options: options) {
        case .success(let r): output = r; errorMessage = nil
        case .failure(let e): output = ""; errorMessage = e.localizedDescription
        }
    }

    func clear() { input = ""; output = ""; errorMessage = nil }
    func copyOutput() { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(output, forType: .string) }
    func pasteAndConvert() { if let s = NSPasteboard.general.string(forType: .string) { input = s; convert() } }
}

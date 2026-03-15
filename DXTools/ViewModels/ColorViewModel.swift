import SwiftUI

@Observable
class ColorViewModel {
    var input: String = "#FF5733"
    var result: ColorService.ColorResult?
    var errorMessage: String?

    func convert() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result = nil; errorMessage = nil; return
        }
        switch ColorService.parse(input) {
        case .success(let r): result = r; errorMessage = nil
        case .failure(let e): result = nil; errorMessage = e.localizedDescription
        }
    }

    func copyValue(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    init() { convert() }
}

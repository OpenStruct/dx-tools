import SwiftUI

@Observable
class TimestampViewModel {
    var input: String = ""
    var result: TimestampService.ConversionResult?
    var errorMessage: String?

    func convert() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result = nil
            errorMessage = nil
            return
        }
        if let r = TimestampService.convert(from: input) {
            result = r
            errorMessage = nil
        } else {
            result = nil
            errorMessage = "Could not parse timestamp"
        }
    }

    func now() {
        result = TimestampService.now()
        input = "\(Int(Date().timeIntervalSince1970))"
        errorMessage = nil
    }

    func copyValue(_ val: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(val, forType: .string)
    }
}

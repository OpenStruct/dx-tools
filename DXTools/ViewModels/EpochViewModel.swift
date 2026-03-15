import SwiftUI

@Observable
class EpochViewModel {
    var mode: Mode = .now
    var epochInput: String = ""
    var dateInput: String = ""
    var timeInfo: EpochService.TimeInfo?
    var errorMessage: String?

    enum Mode: String, CaseIterable {
        case now = "Now"
        case decode = "Epoch → Date"
        case encode = "Date → Epoch"
    }

    func refresh() {
        switch mode {
        case .now:
            timeInfo = EpochService.now()
            errorMessage = nil
        case .decode:
            guard let ts = Double(epochInput.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Enter a valid epoch timestamp"; timeInfo = nil; return
            }
            timeInfo = EpochService.fromEpoch(ts)
            errorMessage = nil
        case .encode:
            guard let date = EpochService.parseDate(dateInput.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                errorMessage = "Could not parse date. Use: YYYY-MM-DD HH:MM:SS"; timeInfo = nil; return
            }
            timeInfo = EpochService.fromDate(date)
            errorMessage = nil
        }
    }

    func copyValue(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    init() { refresh() }
}

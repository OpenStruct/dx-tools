import SwiftUI

@Observable
class UUIDViewModel {
    var uuids: [String] = []
    var count: Int = 5
    var uppercase: Bool = false
    var compact: Bool = false
    var copiedIndex: Int? = nil

    func generate() {
        uuids = (0..<count).map { _ in
            var uuid = UUID().uuidString
            if !uppercase { uuid = uuid.lowercased() }
            if compact { uuid = uuid.replacingOccurrences(of: "-", with: "") }
            return uuid
        }
    }

    func copyOne(_ uuid: String, index: Int) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(uuid, forType: .string)
        copiedIndex = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if self?.copiedIndex == index { self?.copiedIndex = nil }
        }
    }

    func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(uuids.joined(separator: "\n"), forType: .string)
    }

    init() { generate() }
}

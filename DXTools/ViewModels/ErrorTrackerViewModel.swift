import SwiftUI

@Observable
class ErrorTrackerViewModel {
    var logInput: String = ""
    var errors: [ErrorTrackerService.ParsedError] = []
    var groups: [ErrorTrackerService.ErrorGroup] = []
    var selectedGroupId: String?
    var showPasteSheet: Bool = false
    var resolvedIds: Set<String> = []

    var selectedGroup: ErrorTrackerService.ErrorGroup? {
        groups.first { $0.id == selectedGroupId }
    }

    var visibleGroups: [ErrorTrackerService.ErrorGroup] {
        groups.filter { !resolvedIds.contains($0.id) }
    }

    var sourceCounts: [(ErrorTrackerService.ErrorSource, Int)] {
        var counts: [ErrorTrackerService.ErrorSource: Int] = [:]
        for e in errors { counts[e.source, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }
    }

    func parseInput() {
        errors = ErrorTrackerService.parse(logInput)
        // Assign timestamps
        let now = Date()
        for i in errors.indices {
            errors[i].timestamp = now.addingTimeInterval(-Double(errors.count - i) * 2)
        }
        groups = ErrorTrackerService.group(errors)
        selectedGroupId = groups.first?.id
    }

    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .log]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            logInput = (try? String(contentsOf: url)) ?? ""
            parseInput()
        }
    }

    func clear() {
        logInput = ""
        errors = []
        groups = []
        selectedGroupId = nil
        resolvedIds = []
    }

    func resolve(_ groupId: String) {
        resolvedIds.insert(groupId)
        if selectedGroupId == groupId {
            selectedGroupId = visibleGroups.first?.id
        }
    }

    func copyStack(_ group: ErrorTrackerService.ErrorGroup) {
        let stack = group.occurrences.first?.stackTrace.map { frame in
            var s = "  at \(frame.function)"
            if !frame.file.isEmpty { s += " (\(frame.file)" }
            if let line = frame.line { s += ":\(line)" }
            if !frame.file.isEmpty { s += ")" }
            return s
        }.joined(separator: "\n") ?? ""
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("\(group.type): \(group.message)\n\(stack)", forType: .string)
    }
}

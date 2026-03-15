import SwiftUI

@Observable
class JSONDiffViewModel {
    var leftInput: String = ""
    var rightInput: String = ""
    var entries: [JSONDiffService.DiffEntry] = []
    var errorMessage: String?
    var hideSame: Bool = false

    var filteredEntries: [JSONDiffService.DiffEntry] {
        hideSame ? entries.filter { $0.type != .same } : entries
    }

    var stats: (added: Int, removed: Int, changed: Int, same: Int) {
        (
            entries.filter { $0.type == .added }.count,
            entries.filter { $0.type == .removed }.count,
            entries.filter { $0.type == .changed }.count,
            entries.filter { $0.type == .same }.count
        )
    }

    func diff() {
        guard !leftInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !rightInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            entries = []; errorMessage = nil; return
        }
        switch JSONDiffService.diff(left: leftInput, right: rightInput) {
        case .success(let r): entries = r; errorMessage = nil
        case .failure(let e): entries = []; errorMessage = e.localizedDescription
        }
    }

    func loadSample() {
        leftInput = """
        {
          "name": "DX Tools",
          "version": "1.0.0",
          "features": ["json", "hash", "uuid"],
          "config": {
            "theme": "dark",
            "fontSize": 14,
            "autoSave": true
          }
        }
        """
        rightInput = """
        {
          "name": "DX Tools",
          "version": "2.0.0",
          "features": ["json", "hash", "uuid", "regex"],
          "config": {
            "theme": "system",
            "fontSize": 14,
            "language": "en"
          }
        }
        """
        diff()
    }

    func clear() { leftInput = ""; rightInput = ""; entries = []; errorMessage = nil }
}

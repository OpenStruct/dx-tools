import Foundation

actor HistoryService {
    static let shared = HistoryService()
    private let maxItems = 50
    private let storageDir: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageDir = appSupport.appendingPathComponent("DXTools/History", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
    }

    struct HistoryItem: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let preview: String // First 100 chars
        let content: String
        let toolId: String

        init(content: String, toolId: String) {
            self.id = UUID()
            self.timestamp = Date()
            self.preview = String(content.prefix(100))
            self.content = content
            self.toolId = toolId
        }
    }

    func save(_ content: String, for toolId: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        var items = load(for: toolId)

        // Don't save duplicates
        if items.first?.content == content { return }

        items.insert(HistoryItem(content: content, toolId: toolId), at: 0)
        if items.count > maxItems { items = Array(items.prefix(maxItems)) }

        let file = storageDir.appendingPathComponent("\(toolId).json")
        if let data = try? JSONEncoder().encode(items) {
            try? data.write(to: file)
        }
    }

    func load(for toolId: String) -> [HistoryItem] {
        let file = storageDir.appendingPathComponent("\(toolId).json")
        guard let data = try? Data(contentsOf: file),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return []
        }
        return items
    }

    func clear(for toolId: String) {
        let file = storageDir.appendingPathComponent("\(toolId).json")
        try? FileManager.default.removeItem(at: file)
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: storageDir)
        try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
    }
}

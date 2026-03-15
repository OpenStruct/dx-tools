import SwiftUI

@Observable
class AppState {
    var selectedTool: Tool = .jsonFormatter
    var showWelcome: Bool = true
    var searchQuery: String = ""
    var toastMessage: String?
    var toastIcon: String = "checkmark.circle"

    // Overlays
    var showCommandPalette: Bool = false
    var showShortcutOverlay: Bool = false
    var showClipboardPopup: Bool = false
    var clipboardDetection: ClipboardDetection?

    // Tabs per tool
    var tabs: [Tool: [DXTab]] = [:]
    var selectedTabId: [Tool: UUID] = [:]

    // Settings
    var fontSize: Double = 13
    var defaultIndent: JSONFormatterService.IndentStyle = .twoSpaces

    // Favorites
    var favorites: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: "dx.favorites") ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: "dx.favorites") }
    }

    func toggleFavorite(_ tool: Tool) {
        if favorites.contains(tool.rawValue) {
            favorites.remove(tool.rawValue)
        } else {
            favorites.insert(tool.rawValue)
        }
    }

    func isFavorite(_ tool: Tool) -> Bool {
        favorites.contains(tool.rawValue)
    }

    var favoriteTools: [Tool] {
        Tool.allCases.filter { favorites.contains($0.rawValue) }
    }

    // Clipboard monitoring
    var lastClipboardContent: String = ""

    var filteredTools: [Tool] {
        if searchQuery.isEmpty { return Tool.allCases }
        let q = searchQuery.lowercased()
        return Tool.allCases.filter {
            $0.rawValue.lowercased().contains(q) || $0.searchTerms.contains(q)
        }
    }

    func showToast(_ message: String, icon: String = "checkmark.circle") {
        withAnimation(.spring(response: 0.3)) {
            toastMessage = message
            toastIcon = icon
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.toastMessage = nil
            }
        }
    }

    func selectTool(_ tool: Tool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedTool = tool
            showWelcome = false
        }
        // Ensure at least one tab exists
        if tabs[tool] == nil || tabs[tool]!.isEmpty {
            let tab = DXTab(title: "Tab 1", tool: tool)
            tabs[tool] = [tab]
            selectedTabId[tool] = tab.id
        }
    }

    func addTab(for tool: Tool) {
        let count = (tabs[tool]?.count ?? 0) + 1
        let tab = DXTab(title: "Tab \(count)", tool: tool)
        tabs[tool, default: []].append(tab)
        selectedTabId[tool] = tab.id
    }

    func closeTab(_ tabId: UUID, for tool: Tool) {
        tabs[tool]?.removeAll { $0.id == tabId }
        if selectedTabId[tool] == tabId {
            selectedTabId[tool] = tabs[tool]?.last?.id
        }
        if tabs[tool]?.isEmpty ?? true {
            let tab = DXTab(title: "Tab 1", tool: tool)
            tabs[tool] = [tab]
            selectedTabId[tool] = tab.id
        }
    }

    func checkClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string),
              content != lastClipboardContent,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        lastClipboardContent = content
        let detection = ClipboardDetection.detect(content)

        // Only show popup for interesting content
        if detection.type != .unknown {
            clipboardDetection = detection
            withAnimation(.spring(response: 0.3)) {
                showClipboardPopup = true
            }
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                withAnimation(.easeOut(duration: 0.3)) {
                    self?.showClipboardPopup = false
                }
            }
        }
    }
}

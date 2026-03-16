---
name: macos-app-architecture
description: Architecture patterns for macOS SwiftUI applications. Use when designing app structure, managing state, handling navigation, theming, and organizing code for native macOS developer tools. Covers MVVM, observable state, multi-window support, and keyboard-driven UIs.
---

# macOS App Architecture for Developer Tools

## Recommended Architecture: MVVM + Services

```
App
├── AppState (shared state, @Observable)
├── Views (SwiftUI views, thin, declarative)
├── ViewModels (@Observable classes, view logic)
├── Services (pure logic, parsing, conversion)
└── Models (data structs, Codable)
```

## State Management with @Observable (macOS 14+)

```swift
@Observable
class AppState {
    var selectedTool: Tool = .jsonFormatter
    var recentFiles: [URL] = []
    var preferences: Preferences = .default
}

@Observable
class JSONFormatterViewModel {
    var inputJSON: String = ""
    var outputJSON: String = ""
    var errorMessage: String?
    var indentSize: Int = 2
    
    func format() {
        // call service
    }
}
```

For macOS 13, use `ObservableObject` + `@Published`:

```swift
class AppState: ObservableObject {
    @Published var selectedTool: Tool = .jsonFormatter
}
```

## Multi-Tool Navigation Pattern

Perfect for a developer toolkit with sidebar navigation:

```swift
enum Tool: String, CaseIterable, Identifiable {
    case jsonFormatter = "JSON Formatter"
    case jsonToGo = "JSON → Go"
    case jsonToSwift = "JSON → Swift"
    case base64 = "Base64"
    case hashGenerator = "Hash"
    
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .jsonFormatter: return "curlybraces"
        case .jsonToGo: return "arrow.right.circle"
        case .jsonToSwift: return "swift"
        case .base64: return "lock.doc"
        case .hashGenerator: return "number.circle"
        }
    }
    
    var category: ToolCategory {
        switch self {
        case .jsonFormatter, .jsonToGo, .jsonToSwift: return .json
        case .base64, .hashGenerator: return .encoding
        }
    }
}

enum ToolCategory: String, CaseIterable {
    case json = "JSON"
    case encoding = "Encoding"
    
    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .encoding: return "lock.shield"
        }
    }
}
```

## Split Editor Layout

Common pattern for input → output tools:

```swift
struct ToolEditorLayout<InputToolbar: View, OutputToolbar: View>: View {
    @Binding var input: String
    @Binding var output: String
    var inputTitle: String
    var outputTitle: String
    @ViewBuilder var inputToolbar: () -> InputToolbar
    @ViewBuilder var outputToolbar: () -> OutputToolbar
    
    var body: some View {
        HSplitView {
            // Input pane
            VStack(spacing: 0) {
                EditorToolbar(title: inputTitle) { inputToolbar() }
                CodeEditor(text: $input)
            }
            
            // Output pane
            VStack(spacing: 0) {
                EditorToolbar(title: outputTitle) { outputToolbar() }
                CodeEditor(text: $output, isEditable: false)
            }
        }
    }
}
```

## Keyboard Shortcuts Strategy

Developer tools must be keyboard-driven:

```swift
// Global shortcuts via .commands {}
.commands {
    CommandMenu("Tools") {
        ForEach(Tool.allCases) { tool in
            Button(tool.rawValue) { selectedTool = tool }
                .keyboardShortcut(tool.shortcut, modifiers: .command)
        }
    }
    CommandMenu("Actions") {
        Button("Format") { viewModel.format() }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        Button("Copy Output") { viewModel.copyOutput() }
            .keyboardShortcut("c", modifiers: [.command, .shift])
        Button("Clear") { viewModel.clear() }
            .keyboardShortcut("k", modifiers: .command)
        Button("Paste & Format") { viewModel.pasteAndFormat() }
            .keyboardShortcut("v", modifiers: [.command, .shift])
    }
}
```

## Theme System

```swift
struct AppTheme {
    // Editor colors
    let editorBackground: Color
    let editorText: Color
    let lineNumbers: Color
    
    // Syntax colors
    let jsonKey: Color
    let jsonString: Color
    let jsonNumber: Color
    let jsonBoolean: Color
    let jsonNull: Color
    let jsonBrace: Color
    
    static let dark = AppTheme(
        editorBackground: Color(hex: "1E1E1E"),
        editorText: Color(hex: "D4D4D4"),
        lineNumbers: Color(hex: "858585"),
        jsonKey: Color(hex: "9CDCFE"),
        jsonString: Color(hex: "CE9178"),
        jsonNumber: Color(hex: "B5CEA8"),
        jsonBoolean: Color(hex: "569CD6"),
        jsonNull: Color(hex: "569CD6"),
        jsonBrace: Color(hex: "FFD700")
    )
}
```

## Performance Tips

1. **Large Text**: Use `NSTextView` wrapped via `NSViewRepresentable` for text > 10K lines
2. **Debounce Input**: Don't re-parse on every keystroke
3. **Background Processing**: Use `Task { }` for heavy conversions
4. **Lazy Loading**: Use `LazyVStack` for long output lists

```swift
func debounceInput() {
    inputTask?.cancel()
    inputTask = Task {
        try await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
        await MainActor.run { format() }
    }
}
```

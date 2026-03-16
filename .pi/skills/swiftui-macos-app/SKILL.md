---
name: swiftui-macos-app
description: Build native macOS desktop applications with SwiftUI. Use when creating, modifying, or debugging macOS apps with SwiftUI views, window management, menus, toolbars, sidebars, and macOS-specific APIs. Covers AppKit interop, sandboxing, notarization, and distribution.
---

# SwiftUI macOS App Development

## Project Structure

A well-structured macOS SwiftUI app follows this layout:

```
AppName/
├── AppName.xcodeproj/
├── AppName/
│   ├── AppNameApp.swift          # @main App entry point
│   ├── ContentView.swift         # Root view
│   ├── Info.plist
│   ├── AppName.entitlements
│   ├── Assets.xcassets/
│   ├── Models/                   # Data models
│   ├── Views/                    # SwiftUI views
│   │   ├── Sidebar/
│   │   ├── Detail/
│   │   └── Components/           # Reusable components
│   ├── ViewModels/               # ObservableObject classes
│   ├── Services/                 # Business logic, parsers
│   └── Utilities/                # Extensions, helpers
└── AppNameTests/
```

## Creating a New Xcode Project via CLI

```bash
# Use the xcode-project skill for project generation
# Or create manually with swift package + Xcode
mkdir -p AppName && cd AppName
swift package init --type executable --name AppName
```

For a proper macOS app, use Xcode project generation or the xcode-project skill.

## Key macOS SwiftUI Patterns

### App Entry Point
```swift
@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Tools") {
                Button("Format JSON") { appState.formatJSON() }
                    .keyboardShortcut("F", modifiers: [.command, .shift])
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}
```

### NavigationSplitView (Sidebar Pattern)
```swift
struct ContentView: View {
    @State private var selectedTool: Tool?
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedTool)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            if let tool = selectedTool {
                ToolDetailView(tool: tool)
            } else {
                WelcomeView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

### Code Editor View (TextEditor with Monospace)
```swift
struct CodeEditorView: View {
    @Binding var text: String
    var language: String = "json"
    
    var body: some View {
        TextEditor(text: $text)
            .font(.system(.body, design: .monospaced))
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
```

### Toolbar & Controls
```swift
.toolbar {
    ToolbarItemGroup(placement: .primaryAction) {
        Button(action: convert) {
            Label("Convert", systemImage: "arrow.right.circle.fill")
        }
        .keyboardShortcut(.return, modifiers: .command)
    }
    
    ToolbarItem(placement: .status) {
        Text(statusMessage)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
```

### Pasteboard (Copy/Paste)
```swift
func copyToClipboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}

func pasteFromClipboard() -> String? {
    NSPasteboard.general.string(forType: .string)
}
```

### File Import/Export
```swift
.fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
    if case .success(let url) = result {
        text = try? String(contentsOf: url)
    }
}

.fileExporter(isPresented: $showExporter, document: doc, contentType: .json) { result in
    // handle result
}
```

## macOS-Specific Considerations

1. **Window Size**: Use `.defaultSize()` and `.frame(minWidth:minHeight:)` 
2. **Dark Mode**: Use semantic colors (`Color.primary`, `Color(nsColor: .windowBackgroundColor)`)
3. **Keyboard Shortcuts**: Add `.keyboardShortcut()` to all main actions
4. **Menu Bar**: Use `.commands {}` modifier on WindowGroup
5. **Drag & Drop**: Support `.onDrop()` for file input
6. **Touch Bar**: Consider `.touchBar {}` for MacBook Pro
7. **Entitlements**: Configure sandboxing in `.entitlements` file

## Building & Running

```bash
# Build from command line
xcodebuild -project AppName.xcodeproj -scheme AppName -configuration Debug build

# Run
open -a AppName

# Or use swift build for SPM-based projects
swift build
```

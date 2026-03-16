---
name: dx-tools-feature
description: Build new tool features for the DX Tools macOS app. Use when adding any new developer tool — covers the full pipeline from service to view model to view, with testing, theming, and UI standards. Follow this skill for every new tool addition.
---

# DX Tools — Feature Development Guide

## Project Location & Commands

```bash
PROJECT=/Users/nam/Documents/cradx/dx
cd $PROJECT

# Regenerate after adding files
xcodegen generate

# Build
xcodebuild -project DXTools.xcodeproj -scheme DXTools -configuration Release build

# Test
xcodebuild -project DXTools.xcodeproj -scheme DXToolsTests -configuration Debug test

# Install & run
pkill -f "DX Tools" 2>/dev/null; sleep 1
rm -rf "/Applications/DX Tools.app"
APP=$(find ~/Library/Developer/Xcode/DerivedData/DXTools-*/Build/Products/Release -name "DX Tools.app" -maxdepth 1 2>/dev/null | head -1)
cp -R "$APP" /Applications/
open "/Applications/DX Tools.app"
```

## Architecture — 4 Files Per Tool

Every tool requires exactly 4 files:

```
1. DXTools/Services/{Name}Service.swift     — Pure logic, static methods, zero UI
2. DXTools/ViewModels/{Name}ViewModel.swift  — @Observable class, bridges service ↔ view
3. DXTools/Views/Tools/{Name}View.swift      — SwiftUI view with themed UI
4. DXToolsTests/{Name}ServiceTests.swift     — Unit tests for service layer
```

Plus registration in:
- `DXTools/Models/Tool.swift` — Add enum case + metadata
- `DXTools/Views/ToolRouter.swift` — Add routing case

## Step 1: Add Tool Enum Case

File: `DXTools/Models/Tool.swift`

```swift
// Add case in the appropriate category section
case nginxConfig

// Add to category computed property
case .nginxConfig: return .devops

// Add display metadata
case .nginxConfig: return "Nginx Config"      // displayName
case .nginxConfig: return "server.rack"        // icon (SF Symbol)
case .nginxConfig: return "Generate nginx configuration snippets for reverse proxy, static files, SSL, rate limiting"  // description
```

## Step 2: Service (Pure Logic)

File: `DXTools/Services/{Name}Service.swift`

**Rules:**
- `struct` with `static` methods only — NO state, NO UI imports
- Returns typed results, never crashes
- Import only `Foundation` (or `CryptoKit`, `Network` etc. — never `SwiftUI`)

```swift
import Foundation

struct NginxConfigService {
    enum Template: String, CaseIterable {
        case reverseProxy = "Reverse Proxy"
        case staticSite = "Static Site"
        case ssl = "SSL/TLS"
        case loadBalancer = "Load Balancer"
        case rateLimit = "Rate Limiting"
    }

    struct Config {
        let serverName: String
        let listenPort: Int
        let upstream: String
        let template: Template
    }

    static func generate(_ config: Config) -> String {
        // Pure logic here
    }
}
```

## Step 3: ViewModel (@Observable)

File: `DXTools/ViewModels/{Name}ViewModel.swift`

**Rules:**
- Use `@Observable` macro (NOT `ObservableObject`)
- Each `var` on its own line (macro limitation — no `var a = 1, b = 2`)
- Call service methods, manage UI state
- Import `SwiftUI` for `NSPasteboard`

```swift
import SwiftUI

@Observable
class NginxConfigViewModel {
    var serverName: String = "example.com"
    var listenPort: String = "80"
    var upstream: String = "localhost:3000"
    var template: NginxConfigService.Template = .reverseProxy
    var output: String = ""
    var copied: Bool = false

    func generate() {
        let config = NginxConfigService.Config(
            serverName: serverName,
            listenPort: Int(listenPort) ?? 80,
            upstream: upstream,
            template: template
        )
        output = NginxConfigService.generate(config)
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }

    func sample() {
        serverName = "api.example.com"
        listenPort = "443"
        upstream = "localhost:8080"
        template = .reverseProxy
        generate()
    }
}
```

## Step 4: View (SwiftUI)

File: `DXTools/Views/Tools/{Name}View.swift`

**Rules:**
- Access theme via `@Environment(\.theme) private var t`
- Access app state via `@Environment(AppState.self) private var appState`
- Use `ToolHeader` for the top bar
- Use themed components: `DXButton`, `SmallIconButton`, `ThemedPicker`, `EditorPaneHeader`
- Use `SplitEditorLayout` for input/output tools
- NEVER use `.pickerStyle(.segmented)` — use `ThemedPicker` instead
- Copy feedback: `appState.showToast("Copied", icon: "doc.on.doc")`

### Layout Patterns

**Split Editor (input → output):**
```swift
SplitEditorLayout(
    input: $vm.input,
    output: $vm.output,
    inputLanguage: "json",
    outputLanguage: "json",
    toolId: "myTool",
    inputHeader: {
        HStack(spacing: 8) {
            EditorPaneHeader(title: "INPUT", icon: "text.cursor") {}
            Spacer()
            DXButton(title: "Run", icon: "play.fill") { vm.run() }
        }
        .padding(.trailing, 8)
    },
    outputHeader: {
        HStack(spacing: 8) {
            EditorPaneHeader(title: "OUTPUT", icon: "checkmark.circle") {}
            Spacer()
            if !vm.output.isEmpty {
                SmallIconButton(title: "Copy", icon: "doc.on.doc") {
                    vm.copy()
                    appState.showToast("Copied", icon: "doc.on.doc")
                }
            }
        }
        .padding(.trailing, 8)
    }
)
```

**Custom Panel Layout (forms, tables, split panels):**
```swift
VStack(spacing: 0) {
    ToolHeader(title: "My Tool", icon: "wrench.fill") {
        // Controls in header — pickers, buttons
        ThemedPicker(selection: $vm.mode, options: Mode.allCases, label: { $0.rawValue })
        Spacer()
        DXButton(title: "Generate", icon: "play.fill") { vm.generate() }
    }

    HSplitView {
        // Left panel
        VStack(spacing: 0) {
            // Form controls, editor, etc.
        }
        .frame(minWidth: 300)

        // Right panel
        VStack(spacing: 0) {
            // Output, preview, etc.
        }
        .frame(minWidth: 300)
    }
}
.background(t.bg)
```

### Theme Colors Reference

```swift
t.bg              // Main background
t.bgSecondary     // Secondary panels
t.surface         // Control backgrounds
t.surfaceHover    // Hover states
t.glass           // Toolbar/header backgrounds
t.editorBg        // Code editor background
t.border          // Borders and dividers
t.accent          // Orange brand color (#FF8C42 dark / #E8722A light)
t.text            // Primary text
t.textSecondary   // Secondary text
t.textTertiary    // Dim text
t.textGhost       // Ghost/placeholder text
t.success         // Green
t.error           // Red
t.warning         // Yellow/amber
t.info            // Blue
```

### UI Components Available

```swift
// Primary action button (orange)
DXButton(title: "Format", icon: "text.alignleft") { action() }

// Secondary action button (subtle)
DXButton(title: "Clear", icon: "trash", style: .secondary) { action() }

// Small icon-only or icon+label button
SmallIconButton(title: "Copy", icon: "doc.on.doc") { action() }

// Themed picker (replaces .segmented)
ThemedPicker(selection: $value, options: MyEnum.allCases, label: { $0.rawValue })

// Pane header label
EditorPaneHeader(title: "INPUT", icon: "text.cursor") {}

// Tool header bar
ToolHeader(title: "My Tool", icon: "wrench.fill") { /* trailing controls */ }

// Toast notification
appState.showToast("Done!", icon: "checkmark.circle")
```

### Table/List Pattern (like Port Manager)

```swift
// Header row
HStack(spacing: 0) {
    Text("NAME").frame(maxWidth: .infinity, alignment: .leading)
    Text("STATUS").frame(width: 100, alignment: .leading)
    Text("").frame(width: 80) // actions column
}
.font(.system(size: 9.5, weight: .heavy, design: .rounded))
.foregroundStyle(t.textGhost).tracking(0.6)
.padding(.horizontal, 14).padding(.vertical, 8)
.background(t.glass)

// Data rows — use maxWidth: .infinity for flexible columns, fixed width only for small columns
HStack(spacing: 0) {
    Text(item.name)
        .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
        .lineLimit(1).truncationMode(.middle)
    // ...
}
.padding(.horizontal, 14).padding(.vertical, 7)
.background(RoundedRectangle(cornerRadius: 7).fill(isSelected ? t.accent.opacity(0.06) : Color.clear))
.onHover { isHovered = $0 }
```

### Empty State Pattern

```swift
VStack(spacing: 12) {
    Spacer()
    Image(systemName: "tray")
        .font(.system(size: 36, weight: .ultraLight))
        .foregroundStyle(t.textGhost)
    Text("No items")
        .font(.system(size: 13, weight: .semibold, design: .rounded))
        .foregroundStyle(t.textTertiary)
    Text("Description of what to do")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(t.textGhost)
    Spacer()
}
```

### Placeholder Text in TextEditor

```swift
ZStack(alignment: .topLeading) {
    TextEditor(text: $vm.input)
        .font(.system(size: 13, weight: .regular, design: .monospaced))
        .scrollContentBackground(.hidden)
        .background(t.editorBg)
    if vm.input.isEmpty {
        Text("Paste content here…")
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(t.textGhost)
            .padding(.horizontal, 5).padding(.vertical, 8)
            .allowsHitTesting(false)
    }
}
```

## Step 5: Register the Tool

File: `DXTools/Views/ToolRouter.swift`

```swift
case .nginxConfig: NginxConfigView()
```

## Step 6: Tests

File: `DXToolsTests/{Name}ServiceTests.swift`

**Rules:**
- Import `@testable import DX_Tools` (underscore, not space)
- Test service methods only (pure logic)
- Minimum 8-10 test cases per service
- Cover: valid input, edge cases, empty input, error cases

```swift
import XCTest
@testable import DX_Tools

final class NginxConfigServiceTests: XCTestCase {
    func testReverseProxy() {
        let config = NginxConfigService.Config(
            serverName: "api.example.com",
            listenPort: 80,
            upstream: "localhost:3000",
            template: .reverseProxy
        )
        let result = NginxConfigService.generate(config)
        XCTAssertTrue(result.contains("proxy_pass"))
        XCTAssertTrue(result.contains("api.example.com"))
    }

    func testSSLConfig() { /* ... */ }
    func testStaticSite() { /* ... */ }
    func testEmptyServerName() { /* ... */ }
    // ... more tests
}
```

## Step 7: Build, Test, Install

```bash
cd /Users/nam/Documents/cradx/dx

# 1. Regenerate Xcode project (picks up new files)
xcodegen generate

# 2. Build
xcodebuild -project DXTools.xcodeproj -scheme DXTools -configuration Release build 2>&1 | grep -E "error:|BUILD"

# 3. Run ALL tests (must stay at 300+ with 0 failures)
xcodebuild -project DXTools.xcodeproj -scheme DXToolsTests -configuration Debug test 2>&1 | grep "Executed.*tests"

# 4. Install and visually verify
pkill -f "DX Tools" 2>/dev/null; sleep 1
rm -rf "/Applications/DX Tools.app"
APP=$(find ~/Library/Developer/Xcode/DerivedData/DXTools-*/Build/Products/Release -name "DX Tools.app" -maxdepth 1 | head -1)
cp -R "$APP" /Applications/
open "/Applications/DX Tools.app"
```

## Critical Rules

1. **Orange accent is the brand** — NEVER change to blue or other colors
2. **`@Observable` var rules** — Each var on its own line, no `var a = 1, b = 2`
3. **No `.pickerStyle(.segmented)`** — Use `ThemedPicker` component
4. **Services are pure** — No SwiftUI imports, no state, static methods only
5. **Test the service** — Not the view model, not the view
6. **Flexible columns** — Use `maxWidth: .infinity` not fixed widths for table columns
7. **Hover-reveal actions** — Row actions fade in on hover (opacity 0.3 → 1.0)
8. **Toast for feedback** — `appState.showToast("Message", icon: "sf.symbol")`
9. **Hidden title bar** — App uses `.windowStyle(.hiddenTitleBar)`, all headers via `ToolHeader`
10. **Module name** — `@testable import DX_Tools` (underscore replaces space)

## Checklist Before Committing

```
[ ] Service created with static methods, no UI imports
[ ] ViewModel uses @Observable, each var on own line
[ ] View uses ToolHeader, themed components, no segmented pickers
[ ] Tool enum case added with displayName, icon, description
[ ] ToolRouter case added
[ ] 8+ tests written and passing
[ ] Full test suite still passes (300+ tests, 0 failures)
[ ] App builds and installs cleanly
[ ] UI looks good in both dark and light mode
[ ] Flexible layout — no truncation at reasonable window sizes
[ ] Empty states for when no data is present
[ ] Copy actions use appState.showToast()
```

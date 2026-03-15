import SwiftUI

@main
struct DXToolsApp: App {
    @State private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .adaptiveTheme()
                .preferredColorScheme(appState.appearanceOverride)
                .onAppear {
                    appDelegate.appState = appState
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Tab") {
                    appState.addTab(for: appState.selectedTool)
                }
                .keyboardShortcut("t", modifiers: .command)
            }

            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") {
                    appState.checkForUpdate()
                }
            }

            CommandGroup(after: .toolbar) {
                Button("Command Palette") {
                    appState.showCommandPalette.toggle()
                }
                .keyboardShortcut("k", modifiers: .command)

                Button("Keyboard Shortcuts") {
                    appState.showShortcutOverlay.toggle()
                }
                .keyboardShortcut("/", modifiers: .command)
            }

            CommandMenu("Tools") {
                Button("JSON Formatter") { appState.selectTool(.jsonFormatter) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("JSON → Go") { appState.selectTool(.jsonToGo) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("JSON → Swift") { appState.selectTool(.jsonToSwift) }
                    .keyboardShortcut("3", modifiers: .command)
                Button("JSON → TypeScript") { appState.selectTool(.jsonToTypeScript) }
                    .keyboardShortcut("4", modifiers: .command)
                Button("JSON Diff") { appState.selectTool(.jsonDiff) }
                    .keyboardShortcut("5", modifiers: .command)

                Divider()

                Button("JWT Decoder") { appState.selectTool(.jwtDecoder) }
                    .keyboardShortcut("6", modifiers: .command)
                Button("Base64") { appState.selectTool(.base64) }
                    .keyboardShortcut("7", modifiers: .command)
                Button("Hash Generator") { appState.selectTool(.hashGenerator) }
                    .keyboardShortcut("8", modifiers: .command)
                Button("UUID Generator") { appState.selectTool(.uuidGenerator) }
                    .keyboardShortcut("9", modifiers: .command)
                Button("Color Converter") { appState.selectTool(.colorConverter) }
                    .keyboardShortcut("0", modifiers: .command)

                Divider()

                ForEach([Tool.epochConverter, .passwordGenerator, .envManager, .curlToCode, .apiRequest, .regexTester, .markdownPreview, .loremGenerator], id: \.self) { tool in
                    Button(tool.rawValue) { appState.selectTool(tool) }
                }
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
                .adaptiveTheme()
                .preferredColorScheme(appState.appearanceOverride)
        }
    }
}

// MARK: - App Delegate (Menu Bar + Global Hotkey)

class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?
    var statusItem: NSStatusItem?
    var clipboardTimer: Timer?
    var lastClipboard: String = ""

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupClipboardMonitor()
        setupGlobalHotkey()

        // Register URL handler: dx://tool-name
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc func handleURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString),
              url.scheme == "dx" else { return }

        let toolName = url.host ?? ""
        let toolMap: [String: Tool] = Dictionary(uniqueKeysWithValues:
            Tool.allCases.map { tool in
                let key = tool.rawValue.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "→", with: "to")
                    .replacingOccurrences(of: " ", with: "")
                return (key, tool)
            }
        )

        if let tool = toolMap[toolName] {
            DispatchQueue.main.async {
                self.showApp()
                self.appState?.selectTool(tool)
            }
        }
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wrench.and.screwdriver.fill", accessibilityDescription: "DX Tools")
            button.image?.size = NSSize(width: 16, height: 16)
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "⚡ DX Tools", action: #selector(showApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Quick actions
        let uuidItem = NSMenuItem(title: "Generate UUID", action: #selector(quickUUID), keyEquivalent: "u")
        uuidItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(uuidItem)

        let epochItem = NSMenuItem(title: "Current Epoch", action: #selector(quickEpoch), keyEquivalent: "e")
        epochItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(epochItem)

        let passItem = NSMenuItem(title: "Generate Password", action: #selector(quickPassword), keyEquivalent: "p")
        passItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(passItem)

        menu.addItem(NSMenuItem.separator())

        // Clipboard detection
        let clipItem = NSMenuItem(title: "Clipboard: (watching…)", action: nil, keyEquivalent: "")
        clipItem.tag = 100
        menu.addItem(clipItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    func setupClipboardMonitor() {
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func checkClipboard() {
        guard let content = NSPasteboard.general.string(forType: .string),
              content != lastClipboard else { return }
        lastClipboard = content
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // Auto-detect clipboard content
        let detected = detectContent(trimmed)
        if let item = statusItem?.menu?.item(withTag: 100) {
            item.title = "📋 \(detected)"
        }
    }

    func detectContent(_ content: String) -> String {
        if content.components(separatedBy: ".").count == 3 && content.count > 30 && !content.contains(" ") {
            return "JWT Token detected"
        }
        if content.first == "{" || content.first == "[" {
            return "JSON detected"
        }
        if content.hasPrefix("curl ") || content.hasPrefix("curl\n") {
            return "cURL command detected"
        }
        if content.range(of: "^#[0-9a-fA-F]{3,8}$", options: .regularExpression) != nil {
            return "Color: \(content)"
        }
        if content.range(of: "^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$", options: [.regularExpression, .caseInsensitive]) != nil {
            return "UUID detected"
        }
        if let ts = Double(content), ts > 1_000_000_000 && ts < 99_999_999_999 {
            let date = Date(timeIntervalSince1970: ts)
            let f = DateFormatter()
            f.dateFormat = "MMM d, yyyy HH:mm"
            return "Epoch → \(f.string(from: date))"
        }
        if let data = Data(base64Encoded: content), data.count > 0, content.count > 10 {
            return "Base64 detected (\(data.count) bytes)"
        }
        return "Watching clipboard…"
    }

    func setupGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // ⌘⇧Space
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    self?.showApp()
                }
            }
        }
    }

    @objc func showApp() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }

    @objc func quickUUID() {
        let uuid = UUID().uuidString.lowercased()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(uuid, forType: .string)
        appState?.showToast("UUID copied: \(uuid.prefix(8))…", icon: "dice.fill")
    }

    @objc func quickEpoch() {
        let epoch = "\(Int(Date().timeIntervalSince1970))"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(epoch, forType: .string)
        appState?.showToast("Epoch copied: \(epoch)", icon: "clock.fill")
    }

    @objc func quickPassword() {
        let pass = PasswordService.generatePassword(length: 24, includeSpecial: true)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(pass, forType: .string)
        appState?.showToast("Password copied!", icon: "lock.shield.fill")
    }
}

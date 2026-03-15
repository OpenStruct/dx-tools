import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme
    @State private var clipboardTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "dx.onboarded")

    var body: some View {
        @Bindable var state = appState

        ZStack {
            NavigationSplitView {
                SidebarView(selection: $state.selectedTool)
                    .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
            } detail: {
                ZStack {
                    theme.bg.ignoresSafeArea()

                    if appState.showWelcome {
                        WelcomeView()
                    } else {
                        VStack(spacing: 0) {
                            // Tab bar
                            if let tabs = appState.tabs[appState.selectedTool], tabs.count > 1 {
                                TabBarView(
                                    tabs: Binding(
                                        get: { appState.tabs[appState.selectedTool] ?? [] },
                                        set: { appState.tabs[appState.selectedTool] = $0 }
                                    ),
                                    selectedTab: Binding(
                                        get: { appState.selectedTabId[appState.selectedTool] },
                                        set: { appState.selectedTabId[appState.selectedTool] = $0 }
                                    ),
                                    onClose: { id in appState.closeTab(id, for: appState.selectedTool) },
                                    onAdd: { appState.addTab(for: appState.selectedTool) }
                                )
                                Rectangle().fill(theme.border).frame(height: 1)
                            }

                            ToolRouter(tool: appState.selectedTool)
                        }
                    }

                    // Toast
                    ToastOverlay()

                    // Clipboard popup (bottom-right)
                    if appState.showClipboardPopup, let detection = appState.clipboardDetection {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ClipboardPopupView(
                                    detection: detection,
                                    isPresented: $state.showClipboardPopup
                                )
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .padding(16)
                            }
                        }
                    }
                }
            }
            .navigationSplitViewStyle(.balanced)

            // Command Palette overlay
            if appState.showCommandPalette {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { appState.showCommandPalette = false }
                    .transition(.opacity)

                VStack {
                    CommandPalette(isPresented: $state.showCommandPalette)
                        .padding(.top, 80)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Onboarding
            if showOnboarding {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                OnboardingView(isPresented: $showOnboarding)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }

            // Shortcut overlay
            if appState.showShortcutOverlay {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { appState.showShortcutOverlay = false }
                    .transition(.opacity)

                ShortcutOverlay(isPresented: $state.showShortcutOverlay)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showOnboarding)
        .animation(.spring(response: 0.25), value: appState.showCommandPalette)
        .animation(.spring(response: 0.25), value: appState.showShortcutOverlay)
        .animation(.spring(response: 0.3), value: appState.showClipboardPopup)
        .onDrop(of: [.fileURL, .text, .json], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
        .onReceive(clipboardTimer) { _ in
            appState.checkClipboard()
        }
        .onAppear {
            appState.checkForUpdate()
        }
        .alert("Update Available", isPresented: $state.showUpdateAlert) {
            Button("Download") {
                if let url = URL(string: appState.availableUpdate?.url ?? "") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Later", role: .cancel) {}
        } message: {
            if let update = appState.availableUpdate {
                Text("DX Tools v\(update.version) is available. You're on v\(UpdateService.currentVersion).")
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        DispatchQueue.main.async {
                            handleDroppedContent(content, filename: url.lastPathComponent)
                        }
                    }
                }
            }
        }
    }

    private func handleDroppedContent(_ content: String, filename: String?) {
        let ext = filename?.components(separatedBy: ".").last?.lowercased()
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        appState.pendingDropContent = content

        if ext == "json" || trimmed.first == "{" || trimmed.first == "[" {
            appState.selectTool(.jsonFormatter)
        } else if ext == "env" || filename?.hasPrefix(".env") == true {
            appState.selectTool(.envManager)
        } else if ext == "md" || ext == "markdown" {
            appState.selectTool(.markdownPreview)
        } else {
            appState.selectTool(.base64)
        }

        appState.showToast("Loaded: \(filename ?? "content")", icon: "doc.fill")
    }
}

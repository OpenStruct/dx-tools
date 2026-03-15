import SwiftUI
import UniformTypeIdentifiers

struct SplitEditorLayout<InputHeader: View, OutputHeader: View, InputFooter: View>: View {
    @Binding var input: String
    @Binding var output: String
    var inputLanguage: String = "json"
    var outputLanguage: String = "json"
    var toolId: String = ""
    @ViewBuilder var inputHeader: () -> InputHeader
    @ViewBuilder var outputHeader: () -> OutputHeader
    @ViewBuilder var inputFooter: () -> InputFooter
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState
    @State private var showHistory = false
    @State private var historyItems: [HistoryService.HistoryItem] = []
    @State private var isDragOver = false

    var body: some View {
        HSplitView {
            // ── Input ──
            VStack(spacing: 0) {
                inputHeader()
                Rectangle().fill(t.border).frame(height: 1)

                ZStack {
                    CodeEditor(text: $input, isEditable: true, language: inputLanguage)

                    if input.isEmpty {
                        emptyState(
                            icon: "square.and.arrow.down",
                            title: "Paste or drop content",
                            subtitle: "⌘V to paste · Drop files here"
                        )
                        .allowsHitTesting(false)
                    }

                    if isDragOver {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(t.accent, style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .background(t.accent.opacity(0.05))
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
                .background(t.editorBg)
                .onDrop(of: [.fileURL, .text, .plainText], isTargeted: $isDragOver) { providers in
                    loadDroppedContent(providers)
                    return true
                }

                if !toolId.isEmpty {
                    Rectangle().fill(t.border).frame(height: 0.5)
                    HistoryPanel(toolId: toolId) { restored in
                        input = restored
                    }
                }

                Rectangle().fill(t.border).frame(height: 1)
                inputFooter()
            }
            .frame(minWidth: 320)

            // ── Divider ──
            Rectangle()
                .fill(t.border)
                .frame(width: 1)

            // ── Output ──
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    outputHeader()
                    Spacer()
                    if !output.isEmpty {
                        HStack(spacing: 4) {
                            SmallIconButton(title: "Save", icon: "square.and.arrow.down") {
                                saveOutput()
                            }
                        }
                        .padding(.trailing, 8)
                    }
                }
                Rectangle().fill(t.border).frame(height: 1)

                ZStack {
                    CodeEditor(text: $output, isEditable: false, language: outputLanguage)

                    if output.isEmpty && input.isEmpty {
                        emptyState(
                            icon: "arrow.right.circle",
                            title: "Output",
                            subtitle: "Result will appear here"
                        )
                        .allowsHitTesting(false)
                    }
                }
                .background(t.editorBg)
            }
            .frame(minWidth: 320)
        }
        .background(t.editorBg)
        .onChange(of: output) { _, newVal in
            if !toolId.isEmpty && !newVal.isEmpty {
                Task { await HistoryService.shared.save(newVal, for: toolId) }
            }
        }
    }

    func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .ultraLight))
                .foregroundStyle(t.textGhost)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(t.textTertiary)
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(t.textGhost)
        }
    }

    private func loadDroppedContent(_ providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          let content = try? String(contentsOf: url, encoding: .utf8) else { return }
                    DispatchQueue.main.async {
                        input = content
                        appState.showToast("Loaded \(url.lastPathComponent)", icon: "doc.fill")
                    }
                }
                return
            }
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                    guard let str = item as? String else { return }
                    DispatchQueue.main.async {
                        input = str
                    }
                }
                return
            }
        }
    }

    private func saveOutput() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = outputLanguage == "json" ? [.json] : [.plainText]
        panel.nameFieldStringValue = "output.\(outputLanguage == "json" ? "json" : "txt")"
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try output.write(to: url, atomically: true, encoding: .utf8)
                appState.showToast("Saved to \(url.lastPathComponent)", icon: "checkmark.circle")
            } catch {
                appState.showToast("Save failed", icon: "xmark.circle")
            }
        }
    }
}

extension SplitEditorLayout where InputFooter == EmptyView {
    init(
        input: Binding<String>, output: Binding<String>,
        inputLanguage: String = "json", outputLanguage: String = "json",
        toolId: String = "",
        @ViewBuilder inputHeader: @escaping () -> InputHeader,
        @ViewBuilder outputHeader: @escaping () -> OutputHeader
    ) {
        self._input = input; self._output = output
        self.inputLanguage = inputLanguage; self.outputLanguage = outputLanguage
        self.toolId = toolId
        self.inputHeader = inputHeader; self.outputHeader = outputHeader
        self.inputFooter = { EmptyView() }
    }
}

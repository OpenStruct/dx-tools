import SwiftUI

struct SplitEditorLayout<InputHeader: View, OutputHeader: View, InputFooter: View>: View {
    @Binding var input: String
    @Binding var output: String
    var inputLanguage: String = "json"
    var outputLanguage: String = "json"
    @ViewBuilder var inputHeader: () -> InputHeader
    @ViewBuilder var outputHeader: () -> OutputHeader
    @ViewBuilder var inputFooter: () -> InputFooter
    @Environment(\.theme) private var t

    var body: some View {
        HSplitView {
            // ── Input ──
            VStack(spacing: 0) {
                inputHeader()
                Rectangle().fill(t.border).frame(height: 1)

                ZStack {
                    t.editorBg
                    CodeEditor(text: $input, isEditable: true, language: inputLanguage)

                    if input.isEmpty {
                        emptyState(
                            icon: "square.and.arrow.down",
                            title: "Paste or drop content",
                            subtitle: "⌘V to paste · Drop files here"
                        )
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
                outputHeader()
                Rectangle().fill(t.border).frame(height: 1)

                ZStack {
                    t.editorBg
                    CodeEditor(text: $output, isEditable: false, language: outputLanguage)

                    if output.isEmpty && input.isEmpty {
                        emptyState(
                            icon: "arrow.right.circle",
                            title: "Output",
                            subtitle: "Result will appear here"
                        )
                    }
                }
            }
            .frame(minWidth: 320)
        }
        .background(t.editorBg)
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
}

extension SplitEditorLayout where InputFooter == EmptyView {
    init(
        input: Binding<String>, output: Binding<String>,
        inputLanguage: String = "json", outputLanguage: String = "json",
        @ViewBuilder inputHeader: @escaping () -> InputHeader,
        @ViewBuilder outputHeader: @escaping () -> OutputHeader
    ) {
        self._input = input; self._output = output
        self.inputLanguage = inputLanguage; self.outputLanguage = outputLanguage
        self.inputHeader = inputHeader; self.outputHeader = outputHeader
        self.inputFooter = { EmptyView() }
    }
}

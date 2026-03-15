import SwiftUI

struct JSONFormatterView: View {
    @State private var vm = JSONFormatterViewModel()
    @Environment(\.theme) private var t

    var body: some View {
        SplitEditorLayout(
            input: $vm.input,
            output: $vm.output,
            inputLanguage: "json",
            outputLanguage: "json",
            toolId: "jsonFormatter",
            inputHeader: {
                EditorPaneHeader(title: "Input", icon: "arrow.down.doc") {
                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                    SmallIconButton(title: "Paste", icon: "doc.on.clipboard") { vm.pasteAndFormat() }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
            },
            outputHeader: {
                EditorPaneHeader(title: "Output", icon: "arrow.up.doc") {
                    if let valid = vm.isValid {
                        StatusBadge(text: valid ? "Valid" : "Error", style: valid ? .success : .error)
                    }
                    if !vm.output.isEmpty {
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyOutput() }
                    }
                }
            },
            inputFooter: {
                // ── Bottom toolbar ──
                HStack(spacing: 12) {
                    // Indent selector
                    HStack(spacing: 1) {
                        ForEach(JSONFormatterService.IndentStyle.allCases, id: \.self) { style in
                            Button {
                                vm.indentStyle = style
                            } label: {
                                Text(style.rawValue)
                                    .font(.system(size: 10, weight: vm.indentStyle == style ? .bold : .medium, design: .rounded))
                                    .foregroundStyle(vm.indentStyle == style ? t.accent : t.textTertiary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(vm.indentStyle == style ? t.accent.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(t.glass)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))

                    Spacer()

                    // Stats
                    if !vm.stats.isEmpty {
                        Text(vm.stats)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(t.textTertiary)
                    }

                    DXButton(title: "Minify", icon: "arrow.down.right.and.arrow.up.left", style: .secondary) {
                        vm.minify()
                    }

                    DXButton(title: "Format", icon: "text.alignleft") {
                        vm.format()
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial.opacity(0.3))
                .background(t.glass)
            }
        )
        .onChange(of: vm.indentStyle) { _, _ in
            if !vm.input.isEmpty { vm.format() }
        }
        .overlay(alignment: .bottom) {
            if let error = vm.errorMessage {
                errorBanner(error) { vm.errorMessage = nil }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: vm.errorMessage != nil)
    }

    // Reusable toolbar title
    func toolbarTitle(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(t.accent)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }

    // Reusable error banner
    func errorBanner(_ message: String, onDismiss: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(t.error)
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(t.textSecondary)
                .lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(t.textTertiary)
                    .padding(4)
                    .background(t.glass)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(t.error.opacity(0.06))
        .background(.ultraThinMaterial.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(t.error.opacity(0.15), lineWidth: 1))
        .padding(14)
    }
}

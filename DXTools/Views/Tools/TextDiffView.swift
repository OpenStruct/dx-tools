import SwiftUI

struct TextDiffView: View {
    @State private var vm = TextDiffViewModel()
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Text Diff", icon: "arrow.left.arrow.right.square")
            // Stats bar
            if let r = vm.result {
                HStack(spacing: 16) {
                    Label("\(r.stats.additions) added", systemImage: "plus.circle.fill")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(t.success)
                    Label("\(r.stats.deletions) removed", systemImage: "minus.circle.fill")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(t.error)
                    Label("\(r.stats.unchanged) unchanged", systemImage: "equal.circle.fill")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(t.textTertiary)
                    Spacer()
                    SmallIconButton(title: "Copy Unified", icon: "doc.on.doc") { vm.copyUnified() }
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(t.glass)
                Rectangle().fill(t.border).frame(height: 1)
            }

            HSplitView {
                // Left
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Original", icon: "doc.text") {
                        SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                        SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                    }
                    Rectangle().fill(t.border).frame(height: 1)
                    CodeEditor(text: $vm.leftInput, isEditable: true, language: "text")
                        .background(t.editorBg)
                }
                .frame(minWidth: 300)

                Rectangle().fill(t.border).frame(width: 1)

                // Right
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Modified", icon: "doc.text.fill") {
                        SmallIconButton(title: "Swap", icon: "arrow.triangle.2.circlepath") { vm.swap() }
                    }
                    Rectangle().fill(t.border).frame(height: 1)
                    CodeEditor(text: $vm.rightInput, isEditable: true, language: "text")
                        .background(t.editorBg)
                }
                .frame(minWidth: 300)
            }

            Rectangle().fill(t.border).frame(height: 1)

            // Diff output
            if let r = vm.result, !vm.leftInput.isEmpty || !vm.rightInput.isEmpty {
                VStack(spacing: 0) {
                    HStack {
                        Text("DIFF OUTPUT")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(t.textTertiary).tracking(0.8)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(t.glass)
                    Rectangle().fill(t.border).frame(height: 1)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(zip(r.leftLines, r.rightLines)), id: \.0.id) { left, right in
                                HStack(spacing: 0) {
                                    // Left side
                                    diffLine(left)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Rectangle().fill(t.border).frame(width: 1)
                                    // Right side
                                    diffLine(right)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            // Bottom bar
            HStack {
                Spacer()
                DXButton(title: "Compare", icon: "arrow.left.arrow.right") { vm.compare() }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(t.glass)
        }
        .background(t.bg)
    }

    func diffLine(_ line: TextDiffService.DiffLine) -> some View {
        HStack(spacing: 6) {
            if let num = line.lineNumber {
                Text("\(num)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(t.textGhost)
                    .frame(width: 24, alignment: .trailing)
            } else {
                Text("").frame(width: 24)
            }

            Text(line.content)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(line.type == .same ? t.textTertiary : t.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 8).padding(.vertical, 2)
        .background(bgForType(line.type))
    }

    func bgForType(_ type: TextDiffService.LineType) -> Color {
        switch type {
        case .added: return t.success.opacity(0.08)
        case .removed: return t.error.opacity(0.08)
        case .same, .header: return .clear
        }
    }
}

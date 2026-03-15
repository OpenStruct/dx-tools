import SwiftUI

struct JSONDiffView: View {
    @State private var vm = JSONDiffViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Inputs
            HSplitView {
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Left (Original)", icon: "doc") {
                        SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                    }
                    Divider()
                    CodeEditor(text: $vm.leftInput, isEditable: true, language: "json")
                }
                .frame(minWidth: 250)

                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Right (Modified)", icon: "doc.on.doc") {
                        SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }

                        Button {
                            vm.diff()
                        } label: {
                            Label("Diff", systemImage: "arrow.left.arrow.right")
                                .font(.caption).fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    Divider()
                    CodeEditor(text: $vm.rightInput, isEditable: true, language: "json")
                }
                .frame(minWidth: 250)
            }
            .frame(minHeight: 200)

            if !vm.entries.isEmpty || vm.errorMessage != nil {
                Divider()

                // Stats bar
                HStack(spacing: 12) {
                    Label("Diff Result", systemImage: "arrow.left.arrow.right")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                    Spacer()

                    let s = vm.stats
                    diffBadge("Same", s.same, .secondary)
                    diffBadge("Added", s.added, .green)
                    diffBadge("Removed", s.removed, .red)
                    diffBadge("Changed", s.changed, .orange)

                    Toggle("Hide same", isOn: $vm.hideSame)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.bar)
                Divider()

                if let error = vm.errorMessage {
                    Label(error, systemImage: "xmark.circle")
                        .foregroundStyle(.red).font(.caption)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 1) {
                            ForEach(vm.filteredEntries) { entry in
                                diffEntryRow(entry)
                            }
                        }
                        .padding(8)
                    }
                    .frame(minHeight: 150)
                }
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right").foregroundStyle(.tint)
                    Text("JSON Diff").fontWeight(.semibold)
                }
            }
        }
    }

    func diffEntryRow(_ entry: JSONDiffService.DiffEntry) -> some View {
        HStack(spacing: 8) {
            let indent = String(repeating: "  ", count: entry.depth)

            Text(diffIcon(entry.type))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(diffColor(entry.type))
                .frame(width: 16)

            Text(indent + entry.path)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            switch entry.type {
            case .same:
                Text(entry.oldValue ?? "")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            case .added:
                Text(entry.newValue ?? "")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.green)
                    .lineLimit(1)
            case .removed:
                Text(entry.oldValue ?? "")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.red)
                    .strikethrough()
                    .lineLimit(1)
            case .changed:
                HStack(spacing: 4) {
                    Text(entry.oldValue ?? "")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.red)
                        .strikethrough()
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    Text(entry.newValue ?? "")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.green)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(diffColor(entry.type).opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    func diffIcon(_ type: JSONDiffService.DiffType) -> String {
        switch type {
        case .added: return "+"
        case .removed: return "−"
        case .changed: return "~"
        case .same: return " "
        }
    }

    func diffColor(_ type: JSONDiffService.DiffType) -> Color {
        switch type {
        case .added: return .green
        case .removed: return .red
        case .changed: return .orange
        case .same: return .secondary
        }
    }

    func diffBadge(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text("\(count)").fontWeight(.semibold)
            Text(label)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

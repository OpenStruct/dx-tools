import SwiftUI

struct EnvManagerView: View {
    @State private var vm = EnvViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Mode picker
            HStack(spacing: 16) {
                Picker("", selection: $vm.mode) {
                    ForEach(EnvViewModel.Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)

                Spacer()

                if vm.mode == .view {
                    Toggle("Reveal secrets", isOn: $vm.revealed)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .font(.caption)

                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                } else {
                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadDiffSample() }
                }

                SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            Divider()

            if vm.mode == .view {
                viewMode
            } else {
                diffMode
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass").foregroundStyle(.tint)
                    Text("Env Manager").fontWeight(.semibold)
                }
            }
        }
    }

    var viewMode: some View {
        HSplitView {
            // Input
            VStack(spacing: 0) {
                EditorPaneHeader(title: ".env Input", icon: "doc.text") {
                    Button {
                        vm.parse()
                    } label: {
                        Label("Parse", systemImage: "play.fill")
                            .font(.caption).fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .keyboardShortcut(.return, modifiers: .command)
                }
                Divider()

                TextEditor(text: $vm.input)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }
            .frame(minWidth: 300)

            // Parsed view
            VStack(spacing: 0) {
                EditorPaneHeader(title: "Parsed (\(vm.entries.count) variables)", icon: "list.bullet") {
                    if !vm.entries.isEmpty {
                        StatusBadge(text: "\(vm.entries.count) vars", style: .info)
                    }
                }
                Divider()

                if vm.entries.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40)).foregroundStyle(.quaternary)
                        Text("Paste a .env file and click Parse")
                            .font(.caption).foregroundStyle(.quaternary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(vm.entries) { entry in
                                HStack(spacing: 8) {
                                    if entry.isSensitive {
                                        Image(systemName: "lock.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                            .frame(width: 14)
                                    } else {
                                        Color.clear.frame(width: 14, height: 1)
                                    }

                                    Text(entry.key)
                                        .font(.system(.caption, design: .monospaced))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.blue)
                                        .frame(minWidth: 120, alignment: .trailing)

                                    Text("=")
                                        .font(.caption)
                                        .foregroundStyle(.quaternary)

                                    Text(vm.revealed ? entry.value : entry.maskedValue)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .frame(minWidth: 300)
        }
    }

    var diffMode: some View {
        VStack(spacing: 0) {
            HSplitView {
                // Base
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Base (.env)", icon: "doc") { EmptyView() }
                    Divider()
                    TextEditor(text: $vm.diffBase)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                }
                .frame(minWidth: 250)

                // Compare
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Compare (.env.production)", icon: "doc.on.doc") {
                        Button {
                            vm.runDiff()
                        } label: {
                            Label("Diff", systemImage: "arrow.left.arrow.right")
                                .font(.caption).fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    Divider()
                    TextEditor(text: $vm.diffCompare)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                }
                .frame(minWidth: 250)
            }
            .frame(minHeight: 200)

            if let diff = vm.diffResult {
                Divider()
                // Diff results
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        Label("Diff Result", systemImage: "arrow.left.arrow.right")
                            .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                        Spacer()
                        diffBadge("Same", diff.same, .secondary)
                        diffBadge("Added", diff.added.count, .green)
                        diffBadge("Removed", diff.removed.count, .red)
                        diffBadge("Changed", diff.changed.count, .orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.bar)
                    Divider()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(diff.added, id: \.key) { key, value in
                                diffRow("+", key, value, .green)
                            }
                            ForEach(diff.removed, id: \.key) { key, value in
                                diffRow("−", key, value, .red)
                            }
                            ForEach(diff.changed, id: \.key) { key, old, new in
                                VStack(alignment: .leading, spacing: 2) {
                                    diffRow("~", key, old, .red, strikethrough: true)
                                    diffRow("~", key, new, .green)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
                .frame(minHeight: 150)
            }
        }
    }

    func diffBadge(_ label: String, _ count: Int, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Text("\(count)")
                .fontWeight(.semibold)
            Text(label)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    func diffRow(_ prefix: String, _ key: String, _ value: String, _ color: Color, strikethrough: Bool = false) -> some View {
        HStack(spacing: 6) {
            Text(prefix)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.bold)
                .foregroundStyle(color)
                .frame(width: 14)

            Text(key)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .strikethrough(strikethrough)

            Text("=")
                .font(.caption)
                .foregroundStyle(.quaternary)

            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .strikethrough(strikethrough)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

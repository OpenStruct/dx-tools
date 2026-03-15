import SwiftUI

struct RegexTesterView: View {
    @State private var vm = RegexViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Regex Tester", icon: "textformat.abc")
            // Pattern bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                TextField("Regular expression pattern...", text: $vm.pattern)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit { vm.test() }

                Toggle("i", isOn: $vm.flags.caseInsensitive)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help("Case insensitive")

                Toggle("m", isOn: $vm.flags.multiline)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help("Multiline")

                Toggle("g", isOn: $vm.flags.global)
                    .toggleStyle(.button)
                    .controlSize(.small)
                    .help("Global")

                SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.bar)

            if vm.showReplace {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.swap")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    TextField("Replacement (use $1, $2 for groups)", text: $vm.replacement)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Replace") { vm.replace() }
                        .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.bar)
            }

            Divider()

            HSplitView {
                // Input
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Test String", icon: "text.alignleft") {
                        Toggle("Replace", isOn: $vm.showReplace)
                            .toggleStyle(.checkbox)
                            .controlSize(.small)
                            .font(.caption)
                    }
                    Divider()
                    CodeEditor(text: $vm.input, isEditable: true, language: "text")
                }
                .frame(minWidth: 300)

                // Results
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Matches", icon: "list.bullet") {
                        if let result = vm.result {
                            StatusBadge(
                                text: "\(result.matchCount) match\(result.matchCount == 1 ? "" : "es")",
                                style: result.matchCount > 0 ? .success : .info
                            )
                            Text(String(format: "%.2fms", result.executionTime * 1000))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Divider()

                    if let error = vm.errorMessage {
                        VStack {
                            Spacer()
                            Label(error, systemImage: "xmark.circle")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else if let result = vm.result {
                        if result.matches.isEmpty {
                            VStack(spacing: 8) {
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .font(.title2).foregroundStyle(.quaternary)
                                Text("No matches found")
                                    .font(.caption).foregroundStyle(.quaternary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 6) {
                                    ForEach(result.matches) { match in
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text("Match \(match.index + 1)")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.secondary)
                                                Spacer()
                                            }

                                            Text(match.fullMatch)
                                                .font(.system(.caption, design: .monospaced))
                                                .padding(8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.accentColor.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                                .textSelection(.enabled)

                                            if !match.groups.isEmpty {
                                                ForEach(match.groups) { group in
                                                    HStack(spacing: 6) {
                                                        Text("$\(group.index)")
                                                            .font(.system(size: 10, design: .monospaced))
                                                            .foregroundStyle(.orange)
                                                            .frame(width: 24)
                                                        Text(group.value)
                                                            .font(.system(.caption, design: .monospaced))
                                                            .textSelection(.enabled)
                                                    }
                                                    .padding(.leading, 8)
                                                }
                                            }
                                        }
                                        .padding(8)
                                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }

                                    if let replaceResult = vm.replaceResult {
                                        Divider()
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("REPLACEMENT RESULT")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.green)
                                            Text(replaceResult)
                                                .font(.system(.caption, design: .monospaced))
                                                .textSelection(.enabled)
                                                .padding(8)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.green.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        .padding(8)
                                    }
                                }
                                .padding(12)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            Spacer()
                            Image(systemName: "textformat.abc")
                                .font(.system(size: 40)).foregroundStyle(.quaternary)
                            Text("Enter a pattern and test string")
                                .font(.caption).foregroundStyle(.quaternary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(minWidth: 280)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onChange(of: vm.pattern) { _, _ in vm.test() }
        .onChange(of: vm.input) { _, _ in vm.test() }
        .onChange(of: vm.flags.caseInsensitive) { _, _ in vm.test() }
        .onChange(of: vm.flags.multiline) { _, _ in vm.test() }
        .onChange(of: vm.flags.global) { _, _ in vm.test() }
    }
}

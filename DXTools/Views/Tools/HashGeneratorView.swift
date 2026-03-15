import SwiftUI

struct HashGeneratorView: View {
    @State private var vm = HashViewModel()
    @State private var showFileImporter = false

    var body: some View {
        HSplitView {
            // Input
            VStack(spacing: 0) {
                EditorPaneHeader(title: "Input", icon: "arrow.down.doc") {
                    SmallIconButton(title: "File", icon: "doc") { showFileImporter = true }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
                Divider()

                VStack(spacing: 0) {
                    TextEditor(text: $vm.input)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)

                    Divider()
                    HStack {
                        if !vm.source.isEmpty {
                            Text(vm.source)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button {
                            vm.hashInput()
                        } label: {
                            Label("Hash", systemImage: "number.circle.fill")
                                .font(.caption).fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.bar)
                }
            }
            .frame(minWidth: 300)

            // Output
            VStack(spacing: 0) {
                EditorPaneHeader(title: "Hashes", icon: "number.circle") {
                    if vm.result != nil {
                        StatusBadge(text: "Computed", style: .success)
                    }
                }
                Divider()

                if let result = vm.result {
                    ScrollView {
                        VStack(spacing: 12) {
                            hashRow("MD5", result.md5, warning: true)
                            hashRow("SHA-1", result.sha1, warning: true)
                            hashRow("SHA-256", result.sha256)
                            hashRow("SHA-512", result.sha512)
                        }
                        .padding(16)
                    }
                } else {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "number.circle")
                            .font(.system(size: 40))
                            .foregroundStyle(.quaternary)
                        Text("Enter text or select a file to hash")
                            .font(.caption)
                            .foregroundStyle(.quaternary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(minWidth: 300)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            if case .success(let url) = result {
                vm.hashFile(url: url)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "number.circle").foregroundStyle(.tint)
                    Text("Hash Generator").fontWeight(.semibold)
                }
            }
        }
    }

    func hashRow(_ name: String, _ hash: String, warning: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                if warning {
                    Text("insecure")
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.orange.opacity(0.1))
                        .clipShape(Capsule())
                }
                Spacer()
                Button {
                    vm.copyHash(hash)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
                .help("Copy")
            }

            Text(hash)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

import SwiftUI

struct Base64View: View {
    @State private var vm = Base64ViewModel()

    var body: some View {
        SplitEditorLayout(
            input: $vm.input,
            output: $vm.output,
            inputLanguage: "text",
            outputLanguage: "text",
            toolId: "base64",
            inputHeader: {
                EditorPaneHeader(title: vm.isEncoding ? "Plain Text" : "Base64 Input", icon: "arrow.down.doc") {
                    SmallIconButton(title: "Swap", icon: "arrow.triangle.2.circlepath") { vm.swap() }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
            },
            outputHeader: {
                EditorPaneHeader(title: vm.isEncoding ? "Base64 Output" : "Decoded Text", icon: "arrow.up.doc") {
                    if !vm.stats.isEmpty {
                        Text(vm.stats)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if !vm.output.isEmpty {
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyOutput() }
                    }
                }
            },
            inputFooter: {
                HStack(spacing: 12) {
                    ThemedPicker(
                        selection: $vm.isEncoding,
                        options: [true, false],
                        label: { $0 ? "Encode" : "Decode" }
                    )

                    Toggle("URL-safe", isOn: $vm.urlSafe)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .font(.caption)
                        .disabled(!vm.isEncoding)

                    Spacer()

                    if let error = vm.errorMessage {
                        Label(error, systemImage: "xmark.circle")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }

                    Button {
                        vm.process()
                    } label: {
                        Label(vm.isEncoding ? "Encode" : "Decode", systemImage: vm.isEncoding ? "lock" : "lock.open")
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
        )
        .onChange(of: vm.isEncoding) { _, _ in vm.process() }
        .onChange(of: vm.urlSafe) { _, _ in if !vm.input.isEmpty { vm.process() } }
    }
}

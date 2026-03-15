import SwiftUI

struct JSONToTypeScriptView: View {
    @State private var vm = JSONToTypeScriptViewModel()

    var body: some View {
        SplitEditorLayout(
            input: $vm.input,
            output: $vm.output,
            inputLanguage: "json",
            outputLanguage: "typescript",
            toolId: "jsonToTypeScript",
            inputHeader: {
                EditorPaneHeader(title: "JSON Input", icon: "curlybraces") {
                    SmallIconButton(title: "Paste", icon: "doc.on.clipboard") { vm.pasteAndConvert() }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
            },
            outputHeader: {
                EditorPaneHeader(title: "TypeScript", icon: "chevron.left.forwardslash.chevron.right") {
                    if !vm.output.isEmpty {
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyOutput() }
                    }
                }
            },
            inputFooter: {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("Root:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Root", text: $vm.rootName)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                            .frame(width: 80)
                    }

                    Picker("", selection: $vm.useInterface) {
                        Text("interface").tag(true)
                        Text("type").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)

                    Toggle("readonly", isOn: $vm.readOnly)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .font(.caption)

                    Spacer()

                    Button {
                        vm.convert()
                    } label: {
                        Label("Convert", systemImage: "arrow.right.circle.fill")
                            .font(.caption)
                            .fontWeight(.semibold)
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
        .onChange(of: vm.rootName) { _, _ in if !vm.input.isEmpty { vm.convert() } }
        .onChange(of: vm.useInterface) { _, _ in if !vm.input.isEmpty { vm.convert() } }
        .onChange(of: vm.readOnly) { _, _ in if !vm.input.isEmpty { vm.convert() } }
        .overlay {
            if let error = vm.errorMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                        Text(error).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(12)
                    .background(.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding()
                }
            }
        }
    }
}

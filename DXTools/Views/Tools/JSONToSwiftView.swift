import SwiftUI

struct JSONToSwiftView: View {
    @State private var vm = JSONToSwiftViewModel()

    var body: some View {
        SplitEditorLayout(
            input: $vm.input,
            output: $vm.output,
            inputLanguage: "json",
            outputLanguage: "swift",
            toolId: "jsonToSwift",
            inputHeader: {
                EditorPaneHeader(title: "JSON Input", icon: "curlybraces") {
                    SmallIconButton(title: "Paste", icon: "doc.on.clipboard") { vm.pasteAndConvert() }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
            },
            outputHeader: {
                EditorPaneHeader(title: "Swift Codable", icon: "swift") {
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

                    Toggle("let", isOn: $vm.useLetProperties)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .font(.caption)

                    Toggle("CodingKeys", isOn: $vm.addCodingKeys)
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
        .onChange(of: vm.useLetProperties) { _, _ in if !vm.input.isEmpty { vm.convert() } }
        .onChange(of: vm.addCodingKeys) { _, _ in if !vm.input.isEmpty { vm.convert() } }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "swift")
                        .foregroundStyle(.tint)
                    Text("JSON → Swift")
                        .fontWeight(.semibold)
                }
            }
        }
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

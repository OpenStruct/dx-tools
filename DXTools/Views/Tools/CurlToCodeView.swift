import SwiftUI

struct CurlToCodeView: View {
    @State private var vm = CurlToCodeViewModel()

    var body: some View {
        SplitEditorLayout(
            input: $vm.input,
            output: $vm.output,
            inputLanguage: "text",
            outputLanguage: "text",
            inputHeader: {
                EditorPaneHeader(title: "cURL Command", icon: "terminal") {
                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                    SmallIconButton(title: "Paste", icon: "doc.on.clipboard") { vm.pasteAndConvert() }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
            },
            outputHeader: {
                EditorPaneHeader(title: vm.selectedLanguage.rawValue, icon: "chevron.left.forwardslash.chevron.right") {
                    if !vm.output.isEmpty {
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyOutput() }
                    }
                }
            },
            inputFooter: {
                HStack(spacing: 12) {
                    Text("Language:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("", selection: $vm.selectedLanguage) {
                        ForEach(CurlToCodeViewModel.Language.allCases, id: \.self) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 400)

                    Spacer()

                    if let error = vm.errorMessage {
                        Label(error, systemImage: "xmark.circle")
                            .font(.caption2).foregroundStyle(.red)
                    }

                    Button {
                        vm.convert()
                    } label: {
                        Label("Convert", systemImage: "arrow.right.circle.fill")
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
        .onChange(of: vm.selectedLanguage) { _, _ in if !vm.input.isEmpty { vm.convert() } }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "terminal").foregroundStyle(.tint)
                    Text("cURL → Code").fontWeight(.semibold)
                }
            }
        }
    }
}

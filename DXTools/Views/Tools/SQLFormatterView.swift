import SwiftUI

struct SQLFormatterView: View {
    @State private var vm = SQLFormatterViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        SplitEditorLayout(
            input: $vm.input,
            output: $vm.output,
            inputLanguage: "sql",
            outputLanguage: "sql",
            toolId: "sqlFormatter",
            inputHeader: {
                HStack(spacing: 8) {
                    EditorPaneHeader(title: "SQL INPUT", icon: "text.cursor") {}
                    Spacer()

                    Picker("", selection: $vm.indent) {
                        ForEach(SQLFormatterService.IndentStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)

                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.sample() }
                    DXButton(title: "Format", icon: "text.alignleft") { vm.format() }
                    DXButton(title: "Minify", icon: "arrow.right.arrow.left", style: .secondary) { vm.minify() }
                }
                .padding(.trailing, 8)
            },
            outputHeader: {
                HStack(spacing: 8) {
                    EditorPaneHeader(title: "OUTPUT", icon: "checkmark.circle") {}
                    Spacer()
                    if !vm.output.isEmpty {
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") {
                            vm.copy()
                            appState.showToast("SQL copied", icon: "doc.on.doc")
                        }
                    }
                }
                .padding(.trailing, 8)
            }
        )
        .onChange(of: vm.indent) { _, _ in
            if !vm.output.isEmpty { vm.format() }
        }
    }
}

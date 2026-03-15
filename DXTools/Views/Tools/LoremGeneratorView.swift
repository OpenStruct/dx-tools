import SwiftUI

struct LoremGeneratorView: View {
    @State private var vm = LoremViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Lorem Generator", icon: "wand.and.stars")
            // Controls
            HStack(spacing: 16) {
                Picker("", selection: $vm.mode) {
                    ForEach(LoremViewModel.Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 140)

                HStack(spacing: 4) {
                    Text("Count:")
                        .font(.caption).foregroundStyle(.secondary)
                    TextField("", value: $vm.count, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .frame(width: 50)
                    Stepper("", value: $vm.count, in: 1...100)
                        .labelsHidden()
                        .controlSize(.small)
                }

                Spacer()

                Button {
                    vm.copy()
                } label: {
                    Label(vm.copied ? "Copied!" : "Copy", systemImage: vm.copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(vm.copied ? .green : .primary)

                Button {
                    vm.generate()
                } label: {
                    Label("Generate", systemImage: "wand.and.stars")
                        .font(.caption).fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            Divider()

            // Output
            ScrollView {
                Text(vm.output)
                    .font(.system(vm.mode == .json ? .caption : .body, design: vm.mode == .json ? .monospaced : .default))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }

            // Footer
            Divider()
            HStack {
                Text("\(vm.output.count) characters · \(vm.output.components(separatedBy: .whitespaces).count) words")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onChange(of: vm.mode) { _, _ in vm.generate() }
    }
}

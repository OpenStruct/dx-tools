import SwiftUI

struct UUIDGeneratorView: View {
    @State private var vm = UUIDViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Controls bar
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("Count:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("", value: $vm.count, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .frame(width: 50)
                    Stepper("", value: $vm.count, in: 1...100)
                        .labelsHidden()
                        .controlSize(.small)
                }

                Toggle("Uppercase", isOn: $vm.uppercase)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .font(.caption)

                Toggle("No dashes", isOn: $vm.compact)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .font(.caption)

                Spacer()

                Button {
                    vm.copyAll()
                } label: {
                    Label("Copy All", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(vm.uuids.isEmpty)

                Button {
                    vm.generate()
                } label: {
                    Label("Generate", systemImage: "dice.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            Divider()

            // UUID List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(vm.uuids.enumerated()), id: \.offset) { index, uuid in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 30, alignment: .trailing)

                            Text(uuid)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .textSelection(.enabled)

                            Spacer()

                            Button {
                                vm.copyOne(uuid, index: index)
                            } label: {
                                Image(systemName: vm.copiedIndex == index ? "checkmark" : "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(vm.copiedIndex == index ? .green : .secondary)
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(index % 2 == 0 ? Color.clear : Color(nsColor: .controlBackgroundColor).opacity(0.3))
                    }
                }
                .padding(.vertical, 8)
            }

            // Footer
            Divider()
            HStack {
                Label("Version 4 (random)", systemImage: "info.circle")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("·")
                    .foregroundStyle(.quaternary)
                Text("128-bit")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text("·")
                    .foregroundStyle(.quaternary)
                Text("Cryptographically secure")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onChange(of: vm.uppercase) { _, _ in vm.generate() }
        .onChange(of: vm.compact) { _, _ in vm.generate() }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "dice").foregroundStyle(.tint)
                    Text("UUID Generator").fontWeight(.semibold)
                }
            }
        }
    }
}

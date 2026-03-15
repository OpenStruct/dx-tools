import SwiftUI

struct EpochConverterView: View {
    @State private var vm = EpochViewModel()
    @State private var autoRefresh = true
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Epoch Converter", icon: "clock.fill")
            // Mode picker
            HStack(spacing: 16) {
                Picker("", selection: $vm.mode) {
                    ForEach(EpochViewModel.Mode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)

                Spacer()

                if vm.mode == .now {
                    Toggle("Auto-refresh", isOn: $autoRefresh)
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                        .font(.caption)
                }

                Button {
                    vm.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
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

            ScrollView {
                VStack(spacing: 20) {
                    // Input area for decode/encode modes
                    if vm.mode == .decode {
                        HStack(spacing: 8) {
                            Text("Epoch:")
                                .font(.caption).foregroundStyle(.secondary)
                            TextField("e.g., 1710460800", text: $vm.epochInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onSubmit { vm.refresh() }
                            Button("Decode") { vm.refresh() }
                                .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }

                    if vm.mode == .encode {
                        HStack(spacing: 8) {
                            Text("Date:")
                                .font(.caption).foregroundStyle(.secondary)
                            TextField("e.g., 2024-03-15 12:00:00", text: $vm.dateInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                                .onSubmit { vm.refresh() }
                            Button("Encode") { vm.refresh() }
                                .controlSize(.small)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }

                    if let error = vm.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                    }

                    if let info = vm.timeInfo {
                        // Time values
                        VStack(spacing: 2) {
                            timeRow("Epoch (seconds)", "\(info.epochSeconds)", highlight: true)
                            timeRow("Epoch (milliseconds)", "\(info.epochMilliseconds)", highlight: true)
                            Divider().padding(.horizontal, 16)
                            timeRow("ISO 8601", info.iso8601)
                            timeRow("Local", info.local)
                            timeRow("UTC", info.utc)
                            timeRow("Relative", info.relative)
                        }

                        // World Clocks
                        VStack(alignment: .leading, spacing: 8) {
                            Label("World Clocks", systemImage: "globe")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal, 16)

                            VStack(spacing: 2) {
                                ForEach(info.worldClocks, id: \.name) { clock in
                                    HStack {
                                        Text(clock.name)
                                            .font(.caption)
                                            .frame(width: 140, alignment: .leading)
                                        Text(clock.time)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onReceive(timer) { _ in
            if vm.mode == .now && autoRefresh { vm.refresh() }
        }
        .onChange(of: vm.mode) { _, _ in vm.refresh() }
    }

    func timeRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 160, alignment: .trailing)

            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(highlight ? .semibold : .regular)
                .foregroundStyle(highlight ? .primary : .secondary)
                .textSelection(.enabled)

            Spacer()

            Button {
                vm.copyValue(value)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

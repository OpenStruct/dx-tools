import SwiftUI

struct TimestampView: View {
    @State private var vm = TimestampViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Timestamp Converter", icon: "clock.fill")
            // Input bar
            HStack(spacing: 12) {
                Image(systemName: "clock.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                TextField("Epoch, ISO 8601, RFC 2822, or date string…", text: $vm.input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(t.text)
                    .onSubmit { vm.convert() }
                    .onChange(of: vm.input) { _, _ in vm.convert() }

                DXButton(title: "Now", icon: "clock.fill", style: .secondary) { vm.now() }
                DXButton(title: "Convert", icon: "arrow.right.circle.fill") { vm.convert() }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            if let error = vm.errorMessage {
                VStack { Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(t.error)
                        Text(error).font(.system(size: 12, weight: .medium)).foregroundStyle(t.error)
                    }
                    Spacer()
                }
            } else if let r = vm.result {
                ScrollView {
                    VStack(spacing: 16) {
                        // Main formats
                        HStack(spacing: 10) {
                            valueCard("EPOCH (s)", "\(r.epoch)", t.accent)
                            valueCard("EPOCH (ms)", "\(r.epochMs)", t.warning)
                        }

                        HStack(spacing: 10) {
                            valueCard("ISO 8601", r.iso8601, t.info)
                            valueCard("RFC 2822", r.rfc2822, t.success)
                        }

                        HStack(spacing: 10) {
                            valueCard("UTC", r.utc, Color.purple)
                            valueCard("LOCAL", r.local, t.accent)
                        }

                        HStack(spacing: 10) {
                            valueCard("RELATIVE", r.relative, t.info)
                            valueCard("DAY", r.dayOfWeek, t.success)
                        }

                        // Extra info
                        HStack(spacing: 10) {
                            miniCard("Week", "\(r.weekOfYear)")
                            miniCard("Day of Year", "\(r.dayOfYear)")
                            miniCard("Leap Year", r.isLeapYear ? "Yes" : "No")
                        }

                        // Quick formats
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc").font(.system(size: 9, weight: .bold)).foregroundStyle(t.accent)
                                Text("QUICK COPY").font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                            }

                            VStack(spacing: 3) {
                                copyRow("Unix", "\(r.epoch)")
                                copyRow("ISO", r.iso8601)
                                copyRow("RFC", r.rfc2822)
                                copyRow("UTC", r.utc)
                                copyRow("Local", r.local)
                            }
                        }
                    }
                    .padding(20)
                }
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "clock").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                    Text("Enter a timestamp to convert").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                    Text("Epoch · ISO 8601 · RFC 2822 · Date strings").font(.system(size: 10, weight: .medium)).foregroundStyle(t.textGhost)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(t.bg)
    }

    func valueCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
            Text(value).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(t.text).textSelection(.enabled).lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
        .onTapGesture {
            vm.copyValue(value)
            appState.showToast("Copied", icon: "doc.on.doc")
        }
    }

    func miniCard(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased()).font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(t.textGhost).tracking(0.6)
            Text(value).font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundStyle(t.text)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func copyRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(label).font(.system(size: 10, weight: .bold, design: .rounded)).foregroundStyle(t.textTertiary).frame(width: 40, alignment: .trailing)
            Text(value).font(.system(size: 11, weight: .medium, design: .monospaced)).foregroundStyle(t.text).lineLimit(1)
            Spacer()
            Button {
                vm.copyValue(value)
                appState.showToast("Copied", icon: "doc.on.doc")
            } label: {
                Image(systemName: "doc.on.doc").font(.system(size: 9, weight: .semibold)).foregroundStyle(t.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

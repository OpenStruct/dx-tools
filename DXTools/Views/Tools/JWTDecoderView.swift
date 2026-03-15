import SwiftUI

struct JWTDecoderView: View {
    @State private var vm = JWTViewModel()

    var body: some View {
        HSplitView {
            // Input
            VStack(spacing: 0) {
            ToolHeader(title: "JWT Decoder", icon: "key.horizontal.fill")
                EditorPaneHeader(title: "JWT Token", icon: "key.horizontal") {
                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                    SmallIconButton(title: "Paste", icon: "doc.on.clipboard") { vm.paste() }
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
                        Spacer()
                        Button {
                            vm.decode()
                        } label: {
                            Label("Decode", systemImage: "key.horizontal.fill")
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
            }
            .frame(minWidth: 300)

            // Output
            VStack(spacing: 0) {
                EditorPaneHeader(title: "Decoded", icon: "lock.open") {
                    if vm.decoded != nil {
                        if let status = vm.decoded?.expirationStatus {
                            switch status {
                            case .valid: StatusBadge(text: "Valid", style: .success)
                            case .expired: StatusBadge(text: "Expired", style: .error)
                            }
                        }
                    }
                }
                Divider()

                if let decoded = vm.decoded {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Expiration Banner
                            if let status = decoded.expirationStatus {
                                expirationBanner(status)
                            }

                            // Claims
                            if !decoded.claims.isEmpty {
                                sectionView("Claims", icon: "person.text.rectangle") {
                                    ForEach(decoded.claims.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                        claimRow(key, value)
                                    }
                                }
                            }

                            // Header
                            sectionView("Header", icon: "doc.text") {
                                codeBlock(decoded.headerJSON)
                            }

                            // Payload
                            sectionView("Payload", icon: "shippingbox") {
                                codeBlock(decoded.payloadJSON)
                            }

                            // Signature
                            sectionView("Signature", icon: "signature") {
                                let sig = decoded.signature
                                let display = sig.count > 50 ? String(sig.prefix(50)) + "..." : sig
                                Text(display)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                        .padding(16)
                    }
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.red.opacity(0.5))
                        Text(error)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "key.horizontal")
                            .font(.system(size: 40))
                            .foregroundStyle(.quaternary)
                        Text("Paste a JWT token to decode")
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
    }

    func expirationBanner(_ status: JWTService.ExpirationStatus) -> some View {
        HStack(spacing: 8) {
            switch status {
            case .valid(let remaining, _):
                Image(systemName: "checkmark.shield.fill").foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Token is valid").font(.caption).fontWeight(.semibold)
                    Text("Expires in \(remaining)").font(.caption2).foregroundStyle(.secondary)
                }
            case .expired(let ago, _):
                Image(systemName: "xmark.shield.fill").foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Token is expired").font(.caption).fontWeight(.semibold)
                    Text("Expired \(ago) ago").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(10)
        .background {
            switch status {
            case .valid: RoundedRectangle(cornerRadius: 8).fill(.green.opacity(0.1))
            case .expired: RoundedRectangle(cornerRadius: 8).fill(.red.opacity(0.1))
            }
        }
    }

    func sectionView<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    func claimRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .trailing)
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
            Spacer()
        }
    }

    func codeBlock(_ code: String) -> some View {
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .textSelection(.enabled)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

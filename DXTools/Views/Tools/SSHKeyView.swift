import SwiftUI

struct SSHKeyView: View {
    @State private var vm = SSHKeyViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "SSH Key Generator", icon: "key.horizontal.fill")
            // Controls
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Text("Type").font(.system(size: 10, weight: .bold)).foregroundStyle(t.textTertiary)
                    Picker("", selection: $vm.keyType) {
                        ForEach(SSHKeyService.KeyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }

                HStack(spacing: 6) {
                    Text("Comment").font(.system(size: 10, weight: .bold)).foregroundStyle(t.textTertiary)
                    TextField("user@host", text: $vm.comment)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.small)
                        .frame(width: 180)
                }

                Spacer()

                DXButton(title: vm.isGenerating ? "Generating…" : "Generate", icon: "key.fill") {
                    vm.generate()
                }
                .disabled(vm.isGenerating)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            if let kp = vm.keyPair {
                ScrollView {
                    VStack(spacing: 16) {
                        // Fingerprint
                        HStack(spacing: 8) {
                            Image(systemName: "hand.point.up.braille.fill")
                                .font(.system(size: 10)).foregroundStyle(t.accent)
                            Text(kp.fingerprint)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(t.textSecondary)
                                .textSelection(.enabled)
                            Spacer()
                        }
                        .padding(12)
                        .background(t.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Public Key
                        keySection(
                            title: "PUBLIC KEY",
                            content: kp.publicKey,
                            icon: "lock.open.fill",
                            color: t.success,
                            onCopy: {
                                vm.copyPublic()
                                appState.showToast("Public key copied", icon: "doc.on.doc")
                            },
                            onSave: { vm.saveKey(isPublic: true) }
                        )

                        // Private Key
                        keySection(
                            title: "PRIVATE KEY",
                            content: kp.privateKey,
                            icon: "lock.fill",
                            color: t.error,
                            onCopy: {
                                vm.copyPrivate()
                                appState.showToast("Private key copied", icon: "doc.on.doc")
                            },
                            onSave: { vm.saveKey(isPublic: false) }
                        )
                    }
                    .padding(20)
                }
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "key.horizontal")
                        .font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                    Text("Generate an SSH Key Pair")
                        .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                    Text("Ed25519 (recommended) or RSA")
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(t.textGhost)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(t.bg)
    }

    func keySection(title: String, content: String, icon: String, color: Color, onCopy: @escaping () -> Void, onSave: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(color)
                Text(title).font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                Spacer()
                SmallIconButton(title: "Copy", icon: "doc.on.doc", action: onCopy)
                SmallIconButton(title: "Save", icon: "square.and.arrow.down", action: onSave)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(t.surface)

            Rectangle().fill(t.border).frame(height: 0.5)

            Text(content)
                .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(t.editorBg)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
    }
}

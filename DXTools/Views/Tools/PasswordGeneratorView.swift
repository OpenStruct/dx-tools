import SwiftUI

struct PasswordGeneratorView: View {
    @State private var vm = PasswordViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──
            EditorPaneHeader(title: "Password Generator", icon: "lock.shield.fill") {
                HStack(spacing: 1) {
                    modeButton("Password", isActive: !vm.isPhrase) { vm.isPhrase = false; vm.generate() }
                    modeButton("Passphrase", isActive: vm.isPhrase) { vm.isPhrase = true; vm.generate() }
                }
                .padding(2)
                .background(t.glass)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))

                SmallIconButton(title: "Copy All", icon: "doc.on.doc") {
                    vm.copyAll()
                    appState.showToast("All copied", icon: "doc.on.doc")
                }

                DXButton(title: "Generate", icon: "arrow.clockwise") { vm.generate() }
            }
            Rectangle().fill(t.border).frame(height: 1)

            // ── Controls ──
            HStack(spacing: 20) {
                if vm.isPhrase {
                    controlGroup("Words") {
                        HStack(spacing: 6) {
                            Text("\(vm.wordCount)")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundStyle(t.accent)
                                .frame(width: 30)
                            Stepper("", value: $vm.wordCount, in: 2...10)
                                .labelsHidden()
                                .onChange(of: vm.wordCount) { _, _ in vm.generate() }
                        }
                    }
                } else {
                    controlGroup("Length") {
                        HStack(spacing: 6) {
                            Text("\(vm.length)")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundStyle(t.accent)
                                .frame(width: 30)
                            Slider(value: Binding(
                                get: { Double(vm.length) },
                                set: { vm.length = Int($0) }
                            ), in: 8...128, step: 1)
                            .frame(width: 120)
                            .tint(t.accent)
                            .onChange(of: vm.length) { _, _ in vm.generate() }
                        }
                    }

                    controlGroup("Special") {
                        Toggle("!@#$%", isOn: $vm.includeSpecial)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .tint(t.accent)
                            .onChange(of: vm.includeSpecial) { _, _ in vm.generate() }
                    }
                }

                controlGroup("Count") {
                    HStack(spacing: 6) {
                        Text("\(vm.count)")
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(t.accent)
                            .frame(width: 30)
                        Stepper("", value: $vm.count, in: 1...50)
                            .labelsHidden()
                            .onChange(of: vm.count) { _, _ in vm.generate() }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            // ── Password List ──
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(Array(vm.passwords.enumerated()), id: \.element.id) { index, password in
                        passwordRow(index: index, password: password)
                    }
                }
                .padding(10)
            }
            .background(t.editorBg)

            // ── Footer ──
            Rectangle().fill(t.border).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(t.success)
                Text("Cryptographically secure — SecRandomCopyBytes")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(t.textTertiary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(t.glass)
        }
        .background(t.bg)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 7) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                    Text("Password Generator").font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
        }
    }

    func passwordRow(index: Int, password: GeneratedPassword) -> some View {
        let isCopied = vm.copiedId == password.id
        @State var isHovered = false

        return HStack(spacing: 12) {
            // Index
            Text("\(index + 1)")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(t.textGhost)
                .frame(width: 20, alignment: .trailing)

            // Password with character coloring
            Text(attributedPassword(password.value))
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)

            Spacer(minLength: 8)

            // Strength
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .fill(strengthFill(password.strength, index: i))
                        .frame(width: 14, height: 4)
                }
                Text(password.strength.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(strengthColor(password.strength))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(strengthColor(password.strength).opacity(0.06))
            .clipShape(Capsule())

            // Copy button
            Button {
                vm.copyOne(password)
                appState.showToast("Copied", icon: "doc.on.doc")
            } label: {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isCopied ? t.success : t.textTertiary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? t.surfaceHover.opacity(0.5) : index % 2 == 0 ? t.surface.opacity(0.3) : Color.clear)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { isHovered = $0 }
    }

    func attributedPassword(_ password: String) -> AttributedString {
        var result = AttributedString(password)
        for (i, char) in password.enumerated() {
            let range = result.index(result.startIndex, offsetByCharacters: i)..<result.index(result.startIndex, offsetByCharacters: i + 1)
            if char.isLetter && char.isUppercase {
                result[range].foregroundColor = Color(t.accent)
            } else if char.isNumber {
                result[range].foregroundColor = Color(t.info)
            } else if !char.isLetter && !char.isNumber {
                result[range].foregroundColor = Color(t.warning)
            } else {
                result[range].foregroundColor = Color(t.text)
            }
        }
        return result
    }

    func strengthColor(_ strength: PasswordService.Strength) -> Color {
        switch strength {
        case .weak: return t.error
        case .good: return t.warning
        case .strong: return t.success
        }
    }

    func strengthFill(_ strength: PasswordService.Strength, index: Int) -> Color {
        let needed: Int
        switch strength {
        case .weak: needed = 1
        case .good: needed = 2
        case .strong: needed = 3
        }
        return index < needed ? strengthColor(strength) : t.textGhost
    }

    func controlGroup<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textTertiary)
                .tracking(0.8)
            content()
        }
    }

    func modeButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isActive ? .bold : .medium, design: .rounded))
                .foregroundStyle(isActive ? t.accent : t.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? t.accent.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

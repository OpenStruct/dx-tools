import SwiftUI

struct PasswordGeneratorView: View {
    @State private var vm = PasswordViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Password Generator", icon: "lock.shield.fill") {
                HStack(spacing: 1) {
                    modeButton("Password", isActive: !vm.isPhrase) { vm.isPhrase = false; vm.generate() }
                    modeButton("Passphrase", isActive: vm.isPhrase) { vm.isPhrase = true; vm.generate() }
                }
                .padding(2)
                .background(t.glass)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))

                Spacer()

                DXButton(title: "Generate", icon: "arrow.clockwise") { vm.generate() }
            }

            HSplitView {
                // ── Left: Config Panel ──
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if vm.isPhrase {
                            configSection("WORDS") {
                                HStack(spacing: 10) {
                                    Text("\(vm.wordCount)")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundStyle(t.accent)
                                        .frame(width: 40)
                                    Stepper("", value: $vm.wordCount, in: 2...10)
                                        .labelsHidden()
                                        .onChange(of: vm.wordCount) { _, _ in vm.generate() }
                                }
                            }
                        } else {
                            configSection("LENGTH") {
                                VStack(spacing: 8) {
                                    Text("\(vm.length)")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundStyle(t.accent)
                                    Slider(value: Binding(
                                        get: { Double(vm.length) },
                                        set: { vm.length = Int($0) }
                                    ), in: 8...128, step: 1)
                                    .tint(t.accent)
                                    .onChange(of: vm.length) { _, _ in vm.generate() }
                                    HStack {
                                        Text("8")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.textGhost)
                                        Spacer()
                                        Text("128")
                                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.textGhost)
                                    }
                                }
                            }

                            configSection("CHARACTER SET") {
                                VStack(spacing: 8) {
                                    charToggle("Special !@#$%", isOn: $vm.includeSpecial)
                                }
                            }
                        }

                        configSection("COUNT") {
                            HStack(spacing: 10) {
                                Text("\(vm.count)")
                                    .font(.system(size: 28, weight: .black, design: .rounded))
                                    .foregroundStyle(t.accent)
                                    .frame(width: 40)
                                Stepper("", value: $vm.count, in: 1...50)
                                    .labelsHidden()
                                    .onChange(of: vm.count) { _, _ in vm.generate() }
                            }
                        }

                        configSection("LEGEND") {
                            VStack(alignment: .leading, spacing: 5) {
                                legendRow(color: t.text, label: "Lowercase")
                                legendRow(color: t.accent, label: "Uppercase")
                                legendRow(color: t.info, label: "Numbers")
                                legendRow(color: t.warning, label: "Symbols")
                            }
                        }

                        // Security note
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(t.success)
                            Text("SecRandomCopyBytes")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(t.textGhost)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(t.success.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(16)
                }
                .background(t.bgSecondary)
                .frame(minWidth: 200, maxWidth: 230)

                // ── Right: Password Display ──
                VStack(spacing: 0) {
                    // Hero password
                    if let first = vm.passwords.first {
                        heroCard(first)
                    }

                    Rectangle().fill(t.border).frame(height: 1)

                    // Header
                    HStack {
                        EditorPaneHeader(title: "ALL PASSWORDS (\(vm.passwords.count))", icon: "list.bullet") {}
                        Spacer()
                        SmallIconButton(title: "Copy All", icon: "doc.on.doc.fill") {
                            vm.copyAll()
                            appState.showToast("All passwords copied", icon: "doc.on.doc")
                        }
                    }
                    .padding(.trailing, 8)
                    Rectangle().fill(t.border).frame(height: 1)

                    // Password list
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(Array(vm.passwords.enumerated()), id: \.element.id) { index, password in
                                passwordCard(index: index, password: password)
                            }
                        }
                        .padding(12)
                    }
                    .background(t.editorBg)
                }
                .frame(minWidth: 450)
            }
        }
        .background(t.bg)
    }

    // MARK: - Hero Card

    func heroCard(_ password: GeneratedPassword) -> some View {
        let isCopied = vm.copiedId == password.id
        return VStack(spacing: 12) {
            // Big password display
            Text(attributedPassword(password.value))
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)

            // Strength + entropy
            HStack(spacing: 16) {
                // Strength bar
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(strengthBarFill(password.strength, index: i))
                            .frame(width: 24, height: 5)
                    }
                    Text(password.strength.rawValue)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(strengthColor(password.strength))
                        .padding(.leading, 4)
                }

                // Entropy
                let entropy = entropyBits(password.value)
                HStack(spacing: 3) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(t.textGhost)
                    Text("\(entropy) bits")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(t.textTertiary)
                }

                // Length
                HStack(spacing: 3) {
                    Image(systemName: "textformat.size")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(t.textGhost)
                    Text("\(password.value.count) chars")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(t.textTertiary)
                }
            }

            // Copy button
            Button {
                vm.copyOne(password)
                appState.showToast("Password copied", icon: "doc.on.doc")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.system(size: 11, weight: .bold))
                    Text(isCopied ? "Copied!" : "Copy to Clipboard")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .foregroundStyle(isCopied ? t.success : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(isCopied ? t.success.opacity(0.15) : t.accent)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(t.surface.opacity(0.4))
        )
    }

    // MARK: - Password Card

    func passwordCard(index: Int, password: GeneratedPassword) -> some View {
        let isCopied = vm.copiedId == password.id

        return HStack(spacing: 0) {
            // Index pill
            Text("\(index + 1)")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
                .frame(width: 24, height: 24)
                .background(t.surface)
                .clipShape(Circle())

            // Password text
            Text(attributedPassword(password.value))
                .font(.system(size: 13.5, weight: .medium, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.leading, 12)

            Spacer(minLength: 12)

            // Strength dots
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(strengthDotFill(password.strength, index: i))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.trailing, 8)

            // Entropy
            Text("\(entropyBits(password.value))b")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(t.textGhost)
                .frame(width: 32, alignment: .trailing)
                .padding(.trailing, 10)

            // Copy
            Button {
                vm.copyOne(password)
                appState.showToast("Copied", icon: "doc.on.doc")
            } label: {
                Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isCopied ? t.success : t.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(isCopied ? t.success.opacity(0.1) : t.surface.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(index == 0 ? t.accent.opacity(0.04) : t.surface.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(index == 0 ? t.accent.opacity(0.15) : t.border.opacity(0.3), lineWidth: 0.5)
        )
    }

    // MARK: - Config Helpers

    func configSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
                .tracking(0.8)
            content()
        }
    }

    func charToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 8) {
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
                .tint(t.accent)
                .onChange(of: isOn.wrappedValue) { _, _ in vm.generate() }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(t.text)
            Spacer()
        }
    }

    func legendRow(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(t.textTertiary)
        }
    }

    // MARK: - Password Coloring

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

    // MARK: - Strength Helpers

    func strengthColor(_ strength: PasswordService.Strength) -> Color {
        switch strength {
        case .weak: return t.error
        case .good: return t.warning
        case .strong: return t.success
        }
    }

    func strengthBarFill(_ strength: PasswordService.Strength, index: Int) -> Color {
        let needed: Int = switch strength {
        case .weak: 1
        case .good: 2
        case .strong: 4
        }
        return index < needed ? strengthColor(strength) : t.textGhost.opacity(0.2)
    }

    func strengthDotFill(_ strength: PasswordService.Strength, index: Int) -> Color {
        let needed: Int = switch strength {
        case .weak: 1
        case .good: 2
        case .strong: 3
        }
        return index < needed ? strengthColor(strength) : t.textGhost.opacity(0.2)
    }

    func entropyBits(_ password: String) -> Int {
        var charsetSize = 0
        if password.contains(where: { $0.isLowercase }) { charsetSize += 26 }
        if password.contains(where: { $0.isUppercase }) { charsetSize += 26 }
        if password.contains(where: { $0.isNumber }) { charsetSize += 10 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { charsetSize += 32 }
        guard charsetSize > 0 else { return 0 }
        return Int(Double(password.count) * log2(Double(charsetSize)))
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

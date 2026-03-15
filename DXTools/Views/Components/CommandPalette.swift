import SwiftUI

struct CommandPaletteAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let icon: String
    let shortcut: String?
    let action: () -> Void
}

struct CommandPalette: View {
    @Binding var isPresented: Bool
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme
    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isFocused: Bool

    var allActions: [CommandPaletteAction] {
        var actions: [CommandPaletteAction] = []

        // Tools
        for tool in Tool.allCases {
            actions.append(CommandPaletteAction(
                title: tool.rawValue,
                subtitle: tool.category.rawValue,
                icon: tool.icon,
                shortcut: tool.shortcutLabel.isEmpty ? nil : tool.shortcutLabel,
                action: {
                    appState.selectTool(tool)
                    isPresented = false
                }
            ))
        }

        // Quick actions
        actions.append(CommandPaletteAction(
            title: "Generate UUID", subtitle: "Copies to clipboard",
            icon: "dice.fill", shortcut: nil,
            action: {
                let uuid = UUID().uuidString.lowercased()
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(uuid, forType: .string)
                appState.showToast("UUID copied", icon: "dice.fill")
                isPresented = false
            }
        ))

        actions.append(CommandPaletteAction(
            title: "Copy Current Epoch", subtitle: "Copies to clipboard",
            icon: "clock.fill", shortcut: nil,
            action: {
                let epoch = "\(Int(Date().timeIntervalSince1970))"
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(epoch, forType: .string)
                appState.showToast("Epoch copied: \(epoch)", icon: "clock.fill")
                isPresented = false
            }
        ))

        actions.append(CommandPaletteAction(
            title: "Generate Password", subtitle: "24 chars, copies to clipboard",
            icon: "lock.shield.fill", shortcut: nil,
            action: {
                let pass = PasswordService.generatePassword(length: 24, includeSpecial: true)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pass, forType: .string)
                appState.showToast("Password copied", icon: "lock.shield.fill")
                isPresented = false
            }
        ))

        actions.append(CommandPaletteAction(
            title: "Paste & Format JSON", subtitle: "Format clipboard JSON",
            icon: "text.alignleft", shortcut: nil,
            action: {
                appState.selectTool(.jsonFormatter)
                isPresented = false
            }
        ))

        actions.append(CommandPaletteAction(
            title: "Clear History", subtitle: "Remove all saved history",
            icon: "trash", shortcut: nil,
            action: {
                Task { await HistoryService.shared.clearAll() }
                appState.showToast("History cleared", icon: "trash")
                isPresented = false
            }
        ))

        return actions
    }

    var filteredActions: [CommandPaletteAction] {
        if query.isEmpty { return allActions }
        let q = query.lowercased()
        return allActions.filter {
            $0.title.lowercased().contains(q) ||
            ($0.subtitle?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "command")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.accent)

                TextField("Type a command…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(theme.text)
                    .focused($isFocused)
                    .onSubmit {
                        if let action = filteredActions[safe: selectedIndex] {
                            action.action()
                        }
                    }

                Text("ESC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.textGhost)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(theme.surfaceHover)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Rectangle().fill(theme.border).frame(height: 1)

            // Results
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(Array(filteredActions.enumerated()), id: \.element.id) { index, action in
                            commandRow(action, isSelected: index == selectedIndex)
                                .id(index)
                                .onTapGesture { action.action() }
                        }
                    }
                    .padding(6)
                }
                .onChange(of: selectedIndex) { _, newVal in
                    proxy.scrollTo(newVal, anchor: .center)
                }
            }
            .frame(maxHeight: 340)

            Rectangle().fill(theme.border).frame(height: 1)

            // Footer
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    keyBadge("↑↓")
                    Text("navigate")
                        .font(.system(size: 10)).foregroundStyle(theme.textTertiary)
                }
                HStack(spacing: 4) {
                    keyBadge("⏎")
                    Text("select")
                        .font(.system(size: 10)).foregroundStyle(theme.textTertiary)
                }
                HStack(spacing: 4) {
                    keyBadge("esc")
                    Text("close")
                        .font(.system(size: 10)).foregroundStyle(theme.textTertiary)
                }
                Spacer()
                Text("\(filteredActions.count) results")
                    .font(.system(size: 10)).foregroundStyle(theme.textGhost)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 30, y: 10)
        .frame(width: 520)
        .onAppear {
            query = ""
            selectedIndex = 0
            isFocused = true
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(filteredActions.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
        .onChange(of: query) { _, _ in selectedIndex = 0 }
    }

    func commandRow(_ action: CommandPaletteAction, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? theme.accent.opacity(0.15) : theme.surfaceHover)
                    .frame(width: 28, height: 28)
                Image(systemName: action.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? theme.accent : theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(action.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(theme.text)
                if let sub = action.subtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundStyle(theme.textTertiary)
                }
            }

            Spacer()

            if let shortcut = action.shortcut {
                Text(shortcut)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.textGhost)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(theme.surfaceHover)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? theme.accent.opacity(0.06) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(theme.textTertiary)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(theme.surfaceHover)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

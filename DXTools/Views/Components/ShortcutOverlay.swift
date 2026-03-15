import SwiftUI

struct ShortcutOverlay: View {
    @Binding var isPresented: Bool
    @Environment(\.theme) private var theme

    let shortcuts: [(section: String, items: [(keys: String, description: String)])] = [
        ("Navigation", [
            ("⌘1–9", "Switch to tool"),
            ("⌘0", "Color Converter"),
            ("⌘K", "Command Palette"),
            ("⌘⇧Space", "Quick Launcher"),
        ]),
        ("Editor", [
            ("⌘⏎", "Execute / Format / Convert"),
            ("⌘F", "Find in editor"),
            ("⌘Z", "Undo"),
            ("⌘⇧Z", "Redo"),
            ("⌘A", "Select all"),
        ]),
        ("Actions", [
            ("⌘⇧C", "Copy output"),
            ("⌘⇧V", "Paste & process"),
            ("⌘⇧K", "Clear all"),
        ]),
        ("Quick Generate", [
            ("Menu: ⌘⇧U", "Generate UUID"),
            ("Menu: ⌘⇧E", "Copy Epoch"),
            ("Menu: ⌘⇧P", "Generate Password"),
        ]),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .foregroundStyle(theme.accent)
                Text("Keyboard Shortcuts")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                Spacer()
                Text("ESC")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(theme.textGhost)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(theme.surfaceHover)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .padding(16)

            Rectangle().fill(theme.border).frame(height: 1)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(shortcuts, id: \.section) { section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.section)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.8)

                            ForEach(section.items, id: \.keys) { item in
                                HStack {
                                    Text(item.keys)
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(theme.textSecondary)
                                        .frame(width: 120, alignment: .trailing)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(theme.surfaceHover)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))

                                    Text(item.description)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(theme.text)

                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 30, y: 10)
        .frame(width: 420, height: 400)
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }
}

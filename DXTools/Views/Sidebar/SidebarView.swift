import SwiftUI

struct SidebarView: View {
    @Binding var selection: Tool
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var t
    @State private var hoveredTool: Tool?

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // ── Search ──
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(t.textTertiary)
                TextField("Search…", text: $state.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.text)
                if !appState.searchQuery.isEmpty {
                    Button { appState.searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(t.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(t.glass)
            .clipShape(RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(t.border, lineWidth: 1))
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // ── Tools ──
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Favorites section
                    if !appState.favoriteTools.isEmpty && appState.searchQuery.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(t.warning)
                                Text("FAVORITES")
                                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(t.textTertiary)
                                    .tracking(1.2)
                            }
                            .padding(.leading, 18)
                            .padding(.bottom, 2)

                            ForEach(appState.favoriteTools) { tool in
                                sidebarRow(tool)
                            }
                        }
                    }

                    ForEach(ToolCategory.allCases) { cat in
                        let tools = appState.filteredTools.filter { $0.category == cat }
                        if !tools.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(t.accent.opacity(0.5))
                                    Text(cat.rawValue.uppercased())
                                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                        .foregroundStyle(t.textTertiary)
                                        .tracking(1.2)
                                }
                                .padding(.leading, 18)
                                .padding(.bottom, 2)

                                ForEach(tools) { tool in
                                    sidebarRow(tool)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // ── Footer ──
            Rectangle().fill(t.border).frame(height: 1)
                .padding(.horizontal, 14)

            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(t.accentGradient)
                        .frame(width: 20, height: 20)
                        .shadow(color: t.accentGlow, radius: 6)
                    Text("DX")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                Text("DX")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(t.text) +
                Text(" Tools")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(t.textSecondary)

                Spacer()

                // Command palette hint
                Button { appState.showCommandPalette = true } label: {
                    HStack(spacing: 2) {
                        Text("⌘")
                            .font(.system(size: 9, weight: .bold))
                        Text("K")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(t.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(t.glass)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(t.bgSecondary)
    }

    @ViewBuilder
    func sidebarRow(_ tool: Tool) -> some View {
        let isSelected = selection == tool && !appState.showWelcome
        let isHovered = hoveredTool == tool

        Button {
            appState.selectTool(tool)
            selection = tool
        } label: {
            HStack(spacing: 10) {
                // Active indicator bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? t.accent : Color.clear)
                    .frame(width: 3, height: 18)
                    .shadow(color: isSelected ? t.accentGlow : .clear, radius: 4)

                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isSelected ? t.accent.opacity(0.12) : isHovered ? t.surfaceHover : t.glass)
                        .frame(width: 28, height: 28)
                    Image(systemName: tool.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(isSelected ? t.accent : t.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                }

                // Label
                Text(tool.rawValue)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? t.text : isHovered ? t.text : t.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                // Shortcut badge
                if !tool.shortcutLabel.isEmpty {
                    Text(tool.shortcutLabel)
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(t.textGhost)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(t.glass)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .opacity(isSelected || isHovered ? 1 : 0)
                }
            }
            .padding(.vertical, 5)
            .padding(.trailing, 10)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(isSelected ? t.surfaceActive.opacity(0.5) : isHovered ? t.surfaceHover.opacity(0.4) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .onHover { hoveredTool = $0 ? tool : nil }
        .contextMenu {
            Button {
                appState.toggleFavorite(tool)
            } label: {
                Label(
                    appState.isFavorite(tool) ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: appState.isFavorite(tool) ? "star.slash" : "star.fill"
                )
            }
        }
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }
}

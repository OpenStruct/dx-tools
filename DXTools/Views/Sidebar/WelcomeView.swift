import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var t
    @State private var animateIn = false
    @State private var glowPhase: CGFloat = 0
    @State private var hoveredTool: Tool?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                // ── Hero ──
                VStack(spacing: 20) {
                    ZStack {
                        // Glow rings
                        Circle()
                            .fill(t.accent.opacity(0.06))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                            .scaleEffect(animateIn ? 1.2 : 0.5)

                        Circle()
                            .fill(t.accentGradient)
                            .frame(width: 80, height: 80)
                            .shadow(color: t.accentGlow, radius: 20, y: 8)
                            .shadow(color: t.accent.opacity(0.1), radius: 40, y: 16)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animateIn ? 1 : 0.4)
                    .opacity(animateIn ? 1 : 0)

                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            Text("DX")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundStyle(t.text)
                            Text(" Tools")
                                .font(.system(size: 38, weight: .light, design: .rounded))
                                .foregroundStyle(t.textSecondary)
                        }

                        Text("Developer Experience Toolkit")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(t.textTertiary)
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 14)
                }
                .padding(.bottom, 40)

                // ── Tool Grid ──
                VStack(spacing: 28) {
                    ForEach(ToolCategory.allCases) { cat in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(t.accent)
                                Text(cat.rawValue.uppercased())
                                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(t.textTertiary)
                                    .tracking(1.2)
                                Rectangle()
                                    .fill(t.border)
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 4)

                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 160, maximum: 210), spacing: 8)
                            ], spacing: 8) {
                                ForEach(Tool.allCases.filter { $0.category == cat }) { tool in
                                    toolCard(tool)
                                }
                            }
                        }
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)
                    }
                }
                .padding(.horizontal, 36)

                // ── Tips ──
                HStack(spacing: 20) {
                    keyHint("⌘K", "Commands")
                    keyHint("⌘1-9", "Switch")
                    keyHint("⌘⏎", "Execute")
                    keyHint("⌘/", "Shortcuts")
                }
                .padding(.top, 36)
                .opacity(animateIn ? 0.7 : 0)

                Spacer(minLength: 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(t.bg)
        .background(t.meshGradient.opacity(0.5))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.72).delay(0.1)) {
                animateIn = true
            }
        }
    }

    func toolCard(_ tool: Tool) -> some View {
        let isHovered = hoveredTool == tool

        return Button {
            appState.selectTool(tool)
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isHovered ? t.accent.opacity(0.12) : t.glass)
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(isHovered ? t.accent.opacity(0.2) : t.border, lineWidth: 0.5)
                        )
                    Image(systemName: tool.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isHovered ? t.accent : t.textSecondary)
                        .symbolRenderingMode(.hierarchical)
                }

                Text(tool.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isHovered ? t.text : t.textSecondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHovered ? t.surfaceHover : t.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovered ? t.accent.opacity(0.15) : t.border, lineWidth: 0.5)
            )
            .shadow(color: isHovered ? t.accentGlow.opacity(0.3) : .clear, radius: 8, y: 2)
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hoveredTool = $0 ? tool : nil }
        .animation(.spring(response: 0.2), value: isHovered)
    }

    func keyHint(_ key: String, _ label: String) -> some View {
        VStack(spacing: 5) {
            Text(key)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(t.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(t.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 1))
                .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(t.textGhost)
        }
    }
}

import SwiftUI

// MARK: - Glass Toolbar Header

struct EditorPaneHeader<Actions: View>: View {
    let title: String
    let icon: String
    @Environment(\.theme) private var t
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(t.accent)
            Text(title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textTertiary)
                .tracking(0.8)
            Spacer()
            actions()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.5))
        .background(t.glass)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let text: String
    let style: BadgeStyle
    @Environment(\.theme) private var t

    enum BadgeStyle { case success, error, info }

    var body: some View {
        let c: Color = {
            switch style {
            case .success: return t.success
            case .error: return t.error
            case .info: return t.textSecondary
            }
        }()
        let icon: String = {
            switch style {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }()

        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
            Text(text)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
        }
        .foregroundStyle(c)
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(c.opacity(0.1))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(c.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: - Icon Button

struct SmallIconButton: View {
    let title: String
    let icon: String
    var shortcut: String? = nil
    let action: () -> Void
    @Environment(\.theme) private var t
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 10.5, weight: .semibold))
            }
            .foregroundStyle(isHovered ? t.text : t.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isHovered ? t.surfaceHover : t.glass)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .help(shortcut ?? title)
    }
}

// MARK: - Accent Button

struct DXButton: View {
    let title: String
    let icon: String
    var style: ButtonType = .primary
    let action: () -> Void
    @Environment(\.theme) private var t
    @State private var isHovered = false
    @State private var isPressed = false

    enum ButtonType { case primary, secondary }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(style == .primary ? .white : t.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background {
                if style == .primary {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(t.accentGradient)
                        .shadow(color: t.accentGlow, radius: isHovered ? 10 : 5, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? t.surfaceHover : t.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
                }
            }
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.2), value: isHovered)
        .animation(.spring(response: 0.15), value: isPressed)
    }
}

import SwiftUI

struct ToastOverlay: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var t

    var body: some View {
        if let message = appState.toastMessage {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: appState.toastIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(t.success)
                    Text(message)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(t.text)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .background(t.surface.opacity(0.8))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(t.border, lineWidth: 1))
                .shadow(color: .black.opacity(0.25), radius: 16, y: 8)
                .padding(.bottom, 20)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: appState.toastMessage != nil)
        }
    }
}

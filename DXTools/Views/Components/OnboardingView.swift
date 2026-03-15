import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.theme) private var t
    @State private var page = 0

    private let pages: [(icon: String, title: String, subtitle: String, features: [(String, String)])] = [
        (
            "bolt.fill",
            "Welcome to DX Tools",
            "28 developer tools in one native app.\nOffline, instant, keyboard-first.",
            [
                ("curlybraces", "JSON formatting, diffing & code gen"),
                ("key.horizontal", "JWT, Base64, Hash, UUID, Color tools"),
                ("network", "Port manager, DNS, Docker, Git stats"),
            ]
        ),
        (
            "keyboard.fill",
            "Keyboard-First",
            "Every action has a shortcut. Work at the speed of thought.",
            [
                ("command", "⌘K — Command palette to find anything"),
                ("star.fill", "Right-click sidebar to favorite tools"),
                ("doc.on.clipboard", "Smart clipboard auto-detects content"),
            ]
        ),
        (
            "menubar.dock.rectangle",
            "Menu Bar & More",
            "Quick actions without opening the app. Theme that adapts.",
            [
                ("menubar.dock.rectangle", "Generate UUID, epoch, password from menu bar"),
                ("moon.fill", "System / Dark / Light theme in Settings"),
                ("square.and.arrow.down", "Drag & drop files, save output to disk"),
            ]
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $page) {
                ForEach(0..<pages.count, id: \.self) { i in
                    onboardingPage(pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.automatic)

            // Dots + button
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? t.accent : t.textGhost)
                            .frame(width: 6, height: 6)
                    }
                }

                Spacer()

                if page < pages.count - 1 {
                    Button {
                        withAnimation { page += 1 }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next").font(.system(size: 13, weight: .semibold))
                            Image(systemName: "arrow.right").font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(t.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        UserDefaults.standard.set(true, forKey: "dx.onboarded")
                        withAnimation { isPresented = false }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Get Started").font(.system(size: 13, weight: .bold))
                            Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(t.accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: t.accentGlow, radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
        }
        .frame(width: 480, height: 400)
        .background(t.bg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(t.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 40, y: 10)
    }

    func onboardingPage(_ page: (icon: String, title: String, subtitle: String, features: [(String, String)])) -> some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle().fill(t.accentGradient).frame(width: 56, height: 56)
                Image(systemName: page.icon).font(.system(size: 24, weight: .semibold)).foregroundStyle(.white)
            }
            .shadow(color: t.accentGlow, radius: 16)

            Text(page.title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(t.text)

            Text(page.subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(t.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(page.features, id: \.1) { icon, text in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(t.accent)
                            .frame(width: 20)
                        Text(text)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(t.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

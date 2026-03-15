import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme

    var body: some View {
        @Bindable var state = appState

        TabView {
            Form {
                Section("Editor") {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Slider(value: $state.fontSize, in: 10...24, step: 1)
                            .frame(width: 200)
                        Text("\(Int(appState.fontSize))pt")
                            .font(.caption).foregroundStyle(.secondary)
                            .frame(width: 30)
                    }

                    Picker("Default Indent", selection: $state.defaultIndent) {
                        ForEach(JSONFormatterService.IndentStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                }

                Section("Menu Bar") {
                    Text("DX Tools runs in the menu bar for quick access")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("• Quick UUID, Epoch, Password generation")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("• Clipboard auto-detection")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { appState.appearanceMode },
                        set: { appState.setAppearance($0) }
                    )) {
                        Text("System").tag("system")
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("General", systemImage: "gearshape") }

            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    Circle().fill(theme.accentGradient).frame(width: 64, height: 64)
                    Image(systemName: "bolt.fill").font(.system(size: 28)).foregroundStyle(.white)
                }
                Text("DX Tools").font(.title2).fontWeight(.bold)
                Text("Developer Experience Toolkit").foregroundStyle(.secondary)
                Text("Version 2.0.0").font(.caption).foregroundStyle(.tertiary)
                Divider().frame(width: 200)
                Text("\(Tool.allCases.count) tools · Built with SwiftUI").font(.caption).foregroundStyle(.tertiary)
                Text("© 2024 OpenStruct").font(.caption2).foregroundStyle(.quaternary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 450, height: 320)
    }
}

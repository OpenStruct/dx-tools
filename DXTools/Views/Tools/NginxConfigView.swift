import SwiftUI

struct NginxConfigView: View {
    @State private var vm = NginxConfigViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Nginx Config", icon: "server.rack") {
                ThemedPicker(
                    selection: $vm.template,
                    options: NginxConfigService.Template.allCases,
                    label: { $0.rawValue }
                )

                Spacer()

                HStack(spacing: 4) {
                    ForEach(NginxConfigViewModel.Preset.allCases, id: \.self) { preset in
                        Button {
                            vm.loadPreset(preset)
                        } label: {
                            Text(preset.rawValue)
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.border, lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }

                DXButton(title: "Generate", icon: "play.fill") { vm.generate() }
            }

            HSplitView {
                // Left — Config form
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        formSection("Server") {
                            formField("Server Name", text: $vm.serverName, placeholder: "example.com")
                            formField("Listen Port", text: $vm.listenPort, placeholder: "80")
                        }

                        if vm.template != .staticSite {
                            formSection("Upstream") {
                                formField("Upstream", text: $vm.upstream, placeholder: "localhost:3000")
                            }
                        }

                        if vm.template == .staticSite {
                            formSection("Root") {
                                formField("Document Root", text: $vm.rootPath, placeholder: "/var/www/html")
                            }
                        }

                        if vm.template == .ssl {
                            formSection("SSL Certificates") {
                                formField("Certificate", text: $vm.sslCertPath, placeholder: "/etc/ssl/certs/cert.pem")
                                formField("Private Key", text: $vm.sslKeyPath, placeholder: "/etc/ssl/private/key.pem")
                            }
                        }

                        if vm.template == .redirect {
                            formSection("Redirect") {
                                formField("Target URL", text: $vm.redirectTarget, placeholder: "https://example.com")
                            }
                        }

                        if vm.template == .loadBalancer {
                            formSection("Upstream Servers") {
                                ForEach(Array(vm.upstreamServers.enumerated()), id: \.offset) { i, server in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(t.success)
                                            .frame(width: 5, height: 5)
                                        Text(server)
                                            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.text)
                                        Spacer()
                                        Button {
                                            vm.removeServer(at: i)
                                        } label: {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundStyle(t.textGhost)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(t.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }

                                HStack(spacing: 6) {
                                    TextField("host:port", text: $vm.newServer)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 11, design: .monospaced))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(t.editorBg)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5))
                                        .onSubmit { vm.addServer() }
                                    Button {
                                        vm.addServer()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundStyle(t.accent)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        formSection("Options") {
                            Toggle("Enable Gzip Compression", isOn: $vm.enableGzip)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .font(.system(size: 11, weight: .medium))
                            Toggle("Enable Access Logging", isOn: $vm.enableLogging)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .font(.system(size: 11, weight: .medium))
                        }
                    }
                    .padding(16)
                }
                .background(t.bgSecondary)
                .frame(minWidth: 260, maxWidth: 320)

                // Right — Output
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        EditorPaneHeader(title: "NGINX CONFIG", icon: "doc.text") {}
                        Spacer()
                        if !vm.output.isEmpty {
                            SmallIconButton(title: "Copy", icon: "doc.on.doc") {
                                vm.copy()
                                appState.showToast("Config copied", icon: "doc.on.doc")
                            }
                        }
                    }
                    .padding(.trailing, 8)
                    Rectangle().fill(t.border).frame(height: 1)

                    if vm.output.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "server.rack")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Configure and generate")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Text("Choose a template, fill in the fields, hit Generate")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        CodeEditor(text: .constant(vm.output), isEditable: false, language: "plain")
                    }

                    // Warnings
                    if !vm.warnings.isEmpty {
                        Rectangle().fill(t.border).frame(height: 1)
                        ScrollView {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(vm.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(t.warning)
                                            .padding(.top, 2)
                                        Text(warning)
                                            .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.text)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                }
                            }
                            .padding(6)
                        }
                        .frame(maxHeight: 100)
                        .background(t.warning.opacity(0.04))
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
        .onChange(of: vm.template) { _, _ in
            if !vm.output.isEmpty { vm.generate() }
        }
    }

    // MARK: - Form Helpers

    func formSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
                .tracking(0.8)
            content()
        }
    }

    func formField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(t.textTertiary)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(t.editorBg)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 0.5))
        }
    }
}

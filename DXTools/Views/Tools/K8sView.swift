import SwiftUI

struct K8sView: View {
    @State private var vm = K8sViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "K8s YAML", icon: "square.3.layers.3d") {
                ThemedPicker(
                    selection: $vm.resourceType,
                    options: K8sService.ResourceType.allCases,
                    label: { $0.rawValue }
                )

                Spacer()

                DXButton(title: "Full Stack", icon: "square.stack.3d.up", style: .secondary) { vm.generateFullStack() }
                DXButton(title: "Generate", icon: "play.fill") { vm.generate() }
            }

            HSplitView {
                // Left — Form
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        formSection("Metadata") {
                            formField("Name", text: $vm.name, placeholder: "my-app")
                            formField("Namespace", text: $vm.namespace, placeholder: "default")
                        }

                        switch vm.resourceType {
                        case .deployment:
                            deploymentForm
                        case .service:
                            serviceForm
                        case .ingress:
                            ingressForm
                        case .configMap, .secret:
                            keyValueForm
                        case .cronJob:
                            cronJobForm
                        case .pvc:
                            pvcForm
                        case .hpa:
                            hpaForm
                        }
                    }
                    .padding(16)
                }
                .background(t.bgSecondary)
                .frame(minWidth: 260, maxWidth: 320)

                // Right — YAML output
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        EditorPaneHeader(title: "YAML OUTPUT", icon: "doc.text") {}
                        Spacer()
                        if !vm.output.isEmpty {
                            SmallIconButton(title: "Copy", icon: "doc.on.doc") {
                                vm.copy()
                                appState.showToast("YAML copied", icon: "doc.on.doc")
                            }
                        }
                    }
                    .padding(.trailing, 8)
                    Rectangle().fill(t.border).frame(height: 1)

                    if vm.output.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "square.3.layers.3d")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Select a resource type")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Text("Fill in the form and hit Generate")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        CodeEditor(text: .constant(vm.output), isEditable: false, language: "plain")
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
        .onChange(of: vm.resourceType) { _, _ in
            if !vm.output.isEmpty { vm.generate() }
        }
    }

    // MARK: - Resource Forms

    var deploymentForm: some View {
        Group {
            formSection("Container") {
                formField("Image", text: $vm.image, placeholder: "nginx:1.25")
                formField("Replicas", text: $vm.replicas, placeholder: "3")
                formField("Port", text: $vm.containerPort, placeholder: "8080")
                formField("Health Path", text: $vm.healthPath, placeholder: "/healthz")
            }
            formSection("Resources") {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CPU Req").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary)
                        miniField(text: $vm.cpuReq, placeholder: "100m")
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mem Req").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary)
                        miniField(text: $vm.memReq, placeholder: "128Mi")
                    }
                }
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CPU Lim").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary)
                        miniField(text: $vm.cpuLim, placeholder: "500m")
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Mem Lim").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary)
                        miniField(text: $vm.memLim, placeholder: "512Mi")
                    }
                }
            }
        }
    }

    var serviceForm: some View {
        formSection("Service") {
            HStack(spacing: 6) {
                Text("Type").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary)
                ThemedPicker(selection: $vm.serviceType, options: K8sService.ServiceType.allCases, label: { $0.rawValue })
            }
            formField("Port", text: $vm.servicePort, placeholder: "80")
            formField("Target Port", text: $vm.containerPort, placeholder: "8080")
        }
    }

    var ingressForm: some View {
        Group {
            formSection("Routing") {
                formField("Host", text: $vm.host, placeholder: "app.example.com")
                formField("Path", text: $vm.ingressPath, placeholder: "/")
                formField("Service Port", text: $vm.servicePort, placeholder: "80")
            }
            formSection("TLS") {
                Toggle("Enable TLS", isOn: $vm.tlsEnabled)
                    .toggleStyle(.switch).controlSize(.small)
                    .font(.system(size: 11, weight: .medium))
                if vm.tlsEnabled {
                    formField("TLS Secret", text: $vm.tlsSecret, placeholder: "my-app-tls")
                }
            }
        }
    }

    var keyValueForm: some View {
        formSection("Data") {
            ForEach(Array(vm.configData.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 6) {
                    Text(item.key)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(t.accent)
                    Text("=")
                        .foregroundStyle(t.textGhost)
                    Text(vm.resourceType == .secret ? "••••••" : item.value)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(t.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Button { vm.removeKeyValue(at: i) } label: {
                        Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(t.textGhost)
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(t.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            HStack(spacing: 6) {
                miniField(text: $vm.newKey, placeholder: "key")
                miniField(text: $vm.newValue, placeholder: "value")
                Button { vm.addKeyValue() } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 14)).foregroundStyle(t.accent)
                }.buttonStyle(.plain)
            }
        }
    }

    var cronJobForm: some View {
        formSection("CronJob") {
            formField("Image", text: $vm.image, placeholder: "busybox:latest")
            formField("Schedule", text: $vm.schedule, placeholder: "0 */6 * * *")
            formField("Command", text: $vm.command, placeholder: "/bin/sh -c echo hello")
        }
    }

    var pvcForm: some View {
        formSection("Storage") {
            formField("Size", text: $vm.pvcSize, placeholder: "10Gi")
            formField("Storage Class", text: $vm.storageClass, placeholder: "standard")
        }
    }

    var hpaForm: some View {
        formSection("Autoscaling") {
            formField("Min Replicas", text: $vm.minReplicas, placeholder: "2")
            formField("Max Replicas", text: $vm.maxReplicas, placeholder: "10")
            formField("CPU Target %", text: $vm.cpuTarget, placeholder: "70")
        }
    }

    // MARK: - Helpers

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

    func miniField(text: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(t.editorBg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5))
    }
}

import SwiftUI

struct WebhookView: View {
    @State private var vm = WebhookViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Webhook Tester", icon: "antenna.radiowaves.left.and.right") {
                HStack(spacing: 4) {
                    Text("Port:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.textTertiary)
                    TextField("9999", text: $vm.port)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .frame(width: 50)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(t.editorBg)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.border, lineWidth: 0.5))
                }

                // Status indicator
                if vm.isRunning {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(t.success)
                            .frame(width: 7, height: 7)
                        Text("Running")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(t.success)
                    }
                }

                Spacer()

                if vm.isRunning {
                    DXButton(title: "Stop", icon: "stop.fill", style: .secondary) { vm.stopServer() }
                } else {
                    DXButton(title: "Start", icon: "play.fill") { vm.startServer() }
                }
            }

            // Endpoint URL bar
            if vm.isRunning {
                HStack(spacing: 8) {
                    Text("Endpoint:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.textGhost)
                    Text("http://localhost:\(vm.port)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(t.accent)
                        .textSelection(.enabled)
                    Button {
                        vm.copyEndpoint()
                        appState.showToast("URL copied", icon: "doc.on.doc")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(t.textGhost)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Response:")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(t.textGhost)
                        TextField("200", text: $vm.responseCode)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 35)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(t.editorBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        TextField("Body", text: $vm.responseBody)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(width: 120)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(t.editorBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(t.bgSecondary)
                Rectangle().fill(t.border).frame(height: 1)
            }

            HSplitView {
                // Left — Request list
                VStack(spacing: 0) {
                    HStack {
                        EditorPaneHeader(title: "REQUESTS (\(vm.requests.count))", icon: "arrow.down.circle") {}
                        Spacer()
                        if !vm.requests.isEmpty {
                            SmallIconButton(title: "Clear", icon: "trash") { vm.clearRequests() }
                        }
                    }
                    .padding(.trailing, 8)
                    Rectangle().fill(t.border).frame(height: 1)

                    if vm.requests.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text(vm.isRunning ? "Waiting for webhooks…" : "Start the server")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 3) {
                                ForEach(vm.requests) { req in
                                    requestRow(req)
                                }
                            }
                            .padding(6)
                        }
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 240, maxWidth: 300)

                // Right — Detail
                VStack(spacing: 0) {
                    if let req = vm.selectedRequest {
                        requestDetail(req)
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Select a request to inspect")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
    }

    // MARK: - Components

    func requestRow(_ req: WebhookService.WebhookRequest) -> some View {
        let isSelected = vm.selectedRequest?.id == req.id
        return HStack(spacing: 8) {
            methodBadge(req.method)
            VStack(alignment: .leading, spacing: 1) {
                Text(req.path)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(t.text)
                    .lineLimit(1)
                Text(req.timestamp.formatted(.dateTime.hour().minute().second()))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(t.textGhost)
            }
            Spacer()
            if req.bodySize > 0 {
                Text(formatBytes(req.bodySize))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(t.textGhost)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isSelected ? t.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture { vm.selectedRequest = req }
    }

    func requestDetail(_ req: WebhookService.WebhookRequest) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                methodBadge(req.method)
                Text(req.path)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(t.text)
                Spacer()
                SmallIconButton(title: "cURL", icon: "terminal") {
                    vm.copyAsCurl(req)
                    appState.showToast("cURL copied", icon: "doc.on.doc")
                }
                if !req.body.isEmpty {
                    SmallIconButton(title: "Copy Body", icon: "doc.on.doc") {
                        vm.copyBody(req)
                        appState.showToast("Body copied", icon: "doc.on.doc")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            Rectangle().fill(t.border).frame(height: 1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Info
                    HStack(spacing: 12) {
                        detailBadge("Time", value: req.timestamp.formatted(.dateTime.hour().minute().second()))
                        detailBadge("Source", value: req.sourceIP)
                        detailBadge("Size", value: formatBytes(req.bodySize))
                    }

                    // Query params
                    if !req.queryParams.isEmpty {
                        section("QUERY PARAMS") {
                            ForEach(Array(req.queryParams.enumerated()), id: \.offset) { _, param in
                                kvRow(param.key, param.value)
                            }
                        }
                    }

                    // Headers
                    section("HEADERS") {
                        ForEach(Array(req.headers.enumerated()), id: \.offset) { _, header in
                            kvRow(header.key, header.value)
                        }
                    }

                    // Body
                    if !req.body.isEmpty {
                        section("BODY") {
                            Text(req.body)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(t.text)
                                .textSelection(.enabled)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    func methodBadge(_ method: String) -> some View {
        let color: Color = switch method {
        case "GET": t.success
        case "POST": t.accent
        case "PUT": Color.blue
        case "DELETE": t.error
        case "PATCH": Color.purple
        default: t.textGhost
        }
        return Text(method)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    func kvRow(_ key: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                .foregroundStyle(t.accent)
            Text(value)
                .font(.system(size: 10.5, design: .monospaced))
                .foregroundStyle(t.textSecondary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }

    func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
                .tracking(0.8)
            content()
        }
    }

    func detailBadge(_ label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
            Text(value)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundStyle(t.text)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes)B" }
        if bytes < 1048576 { return String(format: "%.1fKB", Double(bytes) / 1024.0) }
        return String(format: "%.1fMB", Double(bytes) / 1048576.0)
    }
}

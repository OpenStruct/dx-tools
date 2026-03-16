import SwiftUI

struct HTTPProxyView: View {
    @State private var vm = HTTPProxyViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "HTTP Proxy", icon: "arrow.left.arrow.right.circle") {
                HStack(spacing: 4) {
                    Text("Port:")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.textTertiary)
                    TextField("8888", text: $vm.port)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .frame(width: 50)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(t.editorBg)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(t.border, lineWidth: 0.5))
                }
                Spacer()
                DXButton(title: "Demo", icon: "play.fill", style: .secondary) { vm.addDemoExchanges() }
                if !vm.exchanges.isEmpty {
                    DXButton(title: "Clear", icon: "trash", style: .secondary) { vm.clearTraffic() }
                }
            }

            // Filter bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(t.textGhost)
                TextField("Filter by URL, host, or body…", text: $vm.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium))

                HStack(spacing: 3) {
                    ForEach(["GET", "POST", "PUT", "DELETE"], id: \.self) { method in
                        let active = vm.filterMethods.contains(method)
                        Button { vm.toggleMethod(method) } label: {
                            Text(method)
                                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(active ? .white : t.textGhost)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(active ? methodColor(method) : t.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(t.bgSecondary)
            Rectangle().fill(t.border).frame(height: 1)

            // Traffic table + detail
            VSplitView {
                // Traffic list
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        tableHeader("#", width: 30)
                        tableHeader("Method", width: 60)
                        tableHeader("Host", width: nil)
                        tableHeader("Path", width: nil)
                        tableHeader("Status", width: 60)
                        tableHeader("Size", width: 60)
                        tableHeader("Time", width: 60)
                    }
                    .padding(.horizontal, 8)
                    .background(t.surface)
                    Rectangle().fill(t.border).frame(height: 1)

                    if vm.filteredExchanges.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "arrow.left.arrow.right.circle")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("No traffic captured")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Text("Configure your app to use http://localhost:\(vm.port) as proxy")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(Array(vm.filteredExchanges.enumerated()), id: \.element.id) { i, exchange in
                                    let selected = vm.selectedExchange?.id == exchange.id
                                    HStack(spacing: 0) {
                                        Text("\(i + 1)")
                                            .frame(width: 30, alignment: .center)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(t.textGhost)
                                        methodBadge(exchange.request.method)
                                            .frame(width: 60)
                                        Text(exchange.request.host)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(1)
                                        Text(exchange.request.path)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .lineLimit(1)
                                        if let res = exchange.response {
                                            statusBadge(res.statusCode)
                                                .frame(width: 60)
                                            Text(HTTPProxyService.formatSize(res.size))
                                                .frame(width: 60, alignment: .trailing)
                                        } else {
                                            Text("—").frame(width: 60)
                                            Text("—").frame(width: 60)
                                        }
                                        if let d = exchange.duration {
                                            Text(String(format: "%.0fms", d * 1000))
                                                .frame(width: 60, alignment: .trailing)
                                        } else {
                                            Text("—").frame(width: 60)
                                        }
                                    }
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundStyle(t.text)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(selected ? t.accent.opacity(0.1) : (i % 2 == 0 ? Color.clear : t.surface.opacity(0.3)))
                                    .contentShape(Rectangle())
                                    .onTapGesture { vm.selectedExchange = exchange }
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 150)

                // Detail
                if let exchange = vm.selectedExchange {
                    VStack(spacing: 0) {
                        Rectangle().fill(t.border).frame(height: 1)
                        HSplitView {
                            // Request
                            VStack(spacing: 0) {
                                HStack {
                                    EditorPaneHeader(title: "REQUEST", icon: "arrow.up.right") {}
                                    Spacer()
                                    SmallIconButton(title: "cURL", icon: "terminal") {
                                        vm.copyAsCurl()
                                        appState.showToast("cURL copied", icon: "doc.on.doc")
                                    }
                                }
                                .padding(.trailing, 8)
                                Rectangle().fill(t.border).frame(height: 1)
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\(exchange.request.method) \(exchange.request.url)")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(t.text)
                                            .textSelection(.enabled)
                                        headerList(exchange.request.headers)
                                        if let body = exchange.request.bodyString, !body.isEmpty {
                                            bodyBlock(body)
                                        }
                                    }
                                    .padding(12)
                                }
                            }
                            .background(t.editorBg)

                            // Response
                            VStack(spacing: 0) {
                                HStack {
                                    EditorPaneHeader(title: "RESPONSE", icon: "arrow.down.left") {}
                                    Spacer()
                                    SmallIconButton(title: "Copy Body", icon: "doc.on.doc") {
                                        vm.copyBody()
                                        appState.showToast("Body copied", icon: "doc.on.doc")
                                    }
                                }
                                .padding(.trailing, 8)
                                Rectangle().fill(t.border).frame(height: 1)
                                if let res = exchange.response {
                                    ScrollView {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 6) {
                                                statusBadge(res.statusCode)
                                                Text(res.statusText)
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundStyle(t.text)
                                            }
                                            headerList(res.headers)
                                            if let body = res.bodyString, !body.isEmpty {
                                                bodyBlock(body)
                                            }
                                        }
                                        .padding(12)
                                    }
                                } else {
                                    Spacer()
                                    Text("No response")
                                        .foregroundStyle(t.textGhost)
                                    Spacer()
                                }
                            }
                            .background(t.editorBg)
                        }
                    }
                    .frame(minHeight: 200)
                }
            }
        }
        .background(t.bg)
    }

    // MARK: - Helpers

    @ViewBuilder
    func tableHeader(_ title: String, width: CGFloat?) -> some View {
        if let w = width {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(t.textGhost)
                .frame(width: w, alignment: .leading)
                .padding(.vertical, 5)
        } else {
            Text(title)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(t.textGhost)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
        }
    }

    func methodBadge(_ method: String) -> some View {
        Text(method)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(methodColor(method))
    }

    func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return t.success
        case "POST": return t.accent
        case "PUT": return Color.blue
        case "DELETE": return t.error
        case "PATCH": return Color.purple
        default: return t.textGhost
        }
    }

    func statusBadge(_ code: Int) -> some View {
        let color: Color = switch code {
        case 200..<300: t.success
        case 300..<400: Color.blue
        case 400..<500: t.accent
        case 500..<600: t.error
        default: t.textGhost
        }
        return Text("\(code)")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
    }

    func headerList(_ headers: [(key: String, value: String)]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("HEADERS")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
                .tracking(0.5)
            ForEach(Array(headers.enumerated()), id: \.offset) { _, h in
                HStack(spacing: 4) {
                    Text(h.key + ":")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(t.accent)
                    Text(h.value)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(t.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    func bodyBlock(_ body: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("BODY")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundStyle(t.textGhost)
                .tracking(0.5)
            Text(body)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(t.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
}

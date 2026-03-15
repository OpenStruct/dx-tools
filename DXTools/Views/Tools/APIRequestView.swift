import SwiftUI

struct APIRequestView: View {
    @State private var vm = APIRequestViewModel()
    @State private var requestTab: RequestTab = .body
    @Environment(\.theme) private var theme

    enum RequestTab: String, CaseIterable {
        case body = "Body"
        case headers = "Headers"
        case params = "Params"
    }

    var body: some View {
        VStack(spacing: 0) {
            // URL bar
            HStack(spacing: 8) {
                // Method picker
                Menu {
                    ForEach(APIRequestService.methods, id: \.self) { method in
                        Button(method) { vm.request.method = method }
                    }
                } label: {
                    Text(vm.request.method)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(methodColor(vm.request.method))
                        .frame(width: 60)
                        .padding(.vertical, 6)
                        .background(methodColor(vm.request.method).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)

                // URL field
                TextField("https://api.example.com/v1/users", text: $vm.request.url)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.editorBg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.border, lineWidth: 0.5)
                    )
                    .onSubmit { vm.send() }

                // Send button
                Button {
                    vm.send()
                } label: {
                    HStack(spacing: 5) {
                        if vm.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 11))
                        }
                        Text("Send")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.accentGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: theme.accent.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .disabled(vm.isLoading)
                .keyboardShortcut(.return, modifiers: .command)

                SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(theme.glass)

            Rectangle().fill(theme.border).frame(height: 1)

            HSplitView {
                // Request pane
                VStack(spacing: 0) {
                    // Tabs
                    HStack(spacing: 0) {
                        ForEach(RequestTab.allCases, id: \.self) { tab in
                            Button {
                                requestTab = tab
                            } label: {
                                Text(tab.rawValue)
                                    .font(.system(size: 11, weight: requestTab == tab ? .semibold : .medium, design: .rounded))
                                    .foregroundStyle(requestTab == tab ? theme.accent : theme.textTertiary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(requestTab == tab ? theme.accent.opacity(0.08) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()

                        if requestTab == .headers {
                            SmallIconButton(title: "Add", icon: "plus") { vm.addHeader() }
                        }
                        if requestTab == .params {
                            SmallIconButton(title: "Add", icon: "plus") { vm.addParam() }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(theme.glass)
                    Rectangle().fill(theme.border).frame(height: 1)

                    switch requestTab {
                    case .body:
                        CodeEditor(text: $vm.request.body, isEditable: true, language: "json")
                    case .headers:
                        keyValueEditor(items: $vm.request.headers, onRemove: vm.removeHeader)
                    case .params:
                        keyValueEditor(items: $vm.request.queryParams, onRemove: vm.removeParam)
                    }
                }
                .frame(minWidth: 300)

                Rectangle().fill(theme.border).frame(width: 1)

                // Response pane
                VStack(spacing: 0) {
                    // Response header
                    HStack(spacing: 8) {
                        if let resp = vm.response {
                            statusBadge(resp.statusCode)

                            Text(String(format: "%.0fms", resp.duration * 1000))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(theme.textTertiary)

                            Text(ByteCountFormatter.string(fromByteCount: Int64(resp.size), countStyle: .memory))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(theme.textTertiary)
                        } else {
                            Text("Response")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.textTertiary)
                        }

                        Spacer()

                        if vm.response != nil {
                            ForEach(APIRequestViewModel.ResponseTab.allCases, id: \.self) { tab in
                                Button {
                                    vm.responseTab = tab
                                } label: {
                                    Text(tab.rawValue)
                                        .font(.system(size: 10, weight: vm.responseTab == tab ? .semibold : .medium))
                                        .foregroundStyle(vm.responseTab == tab ? theme.accent : theme.textTertiary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(vm.responseTab == tab ? theme.accent.opacity(0.08) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                            }

                            SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyResponse() }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.glass)
                    Rectangle().fill(theme.border).frame(height: 1)

                    if vm.isLoading {
                        VStack(spacing: 12) {
                            Spacer()
                            ProgressView()
                            Text("Sending request…")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else if let error = vm.errorMessage {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 28))
                                .foregroundStyle(theme.error)
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else if let resp = vm.response {
                        responseBody(resp)
                    } else {
                        VStack(spacing: 10) {
                            Spacer()
                            Image(systemName: "paperplane")
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(theme.textGhost)
                            Text("Send a request to see the response")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(minWidth: 300)
            }
        }
        .background(theme.editorBg)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Image(systemName: "paperplane").foregroundStyle(theme.accent)
                    Text("API Request Builder").fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    func responseBody(_ resp: APIRequestService.Response) -> some View {
        switch vm.responseTab {
        case .body:
            let body = Binding.constant(resp.prettyBody)
            CodeEditor(text: body, isEditable: false, language: resp.isJSON ? "json" : "text")
        case .headers:
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(resp.headers, id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(theme.accent)
                                .frame(minWidth: 140, alignment: .trailing)
                            Text(value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(theme.textSecondary)
                                .textSelection(.enabled)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                    }
                }
                .padding(.vertical, 8)
            }
        case .raw:
            let raw = Binding.constant(resp.body)
            CodeEditor(text: raw, isEditable: false, language: "text")
        }
    }

    func keyValueEditor(items: Binding<[(key: String, value: String, enabled: Bool)]>, onRemove: @escaping (Int) -> Void) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(items.wrappedValue.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        Toggle("", isOn: Binding(
                            get: { items.wrappedValue[i].enabled },
                            set: { items.wrappedValue[i].enabled = $0 }
                        ))
                        .toggleStyle(.checkbox)
                        .controlSize(.small)

                        TextField("Key", text: Binding(
                            get: { items.wrappedValue[i].key },
                            set: { items.wrappedValue[i].key = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(theme.surfaceHover)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        TextField("Value", text: Binding(
                            get: { items.wrappedValue[i].value },
                            set: { items.wrappedValue[i].value = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(theme.surfaceHover)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                        Button {
                            onRemove(i)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 8)
        }
    }

    func statusBadge(_ code: Int) -> some View {
        let color: Color = (200...299).contains(code) ? theme.success : (400...599).contains(code) ? theme.error : theme.warning
        return Text("\(code)")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    func methodColor(_ method: String) -> Color {
        switch method {
        case "GET": return theme.success
        case "POST": return Color(hex: "3B82F6")
        case "PUT": return theme.warning
        case "PATCH": return Color(hex: "8B5CF6")
        case "DELETE": return theme.error
        default: return theme.textSecondary
        }
    }
}

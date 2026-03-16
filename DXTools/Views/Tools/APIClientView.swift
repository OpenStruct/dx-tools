import SwiftUI

struct APIClientView: View {
    @State private var vm = APIClientViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "API Client", icon: "paperplane.fill") {
                if !vm.environments.isEmpty {
                    Picker("Env", selection: Binding(
                        get: { vm.activeEnvIndex ?? -1 },
                        set: { vm.activeEnvIndex = $0 >= 0 ? $0 : nil }
                    )) {
                        Text("No Environment").tag(-1)
                        ForEach(Array(vm.environments.enumerated()), id: \.element.id) { i, env in
                            Text(env.name).tag(i)
                        }
                    }
                    .frame(width: 150)
                }
                Spacer()
                DXButton(title: "Import cURL", icon: "square.and.arrow.down", style: .secondary) { vm.showImportCurl = true }
                DXButton(title: "New Request", icon: "plus") { vm.addRequest() }
            }

            HSplitView {
                // Left — Collections
                VStack(spacing: 0) {
                    HStack {
                        EditorPaneHeader(title: "COLLECTIONS", icon: "folder") {}
                        Spacer()
                        Button { vm.addCollection() } label: {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(t.textGhost)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 8)
                    }
                    Rectangle().fill(t.border).frame(height: 1)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 2) {
                            ForEach(Array(vm.collections.enumerated()), id: \.element.id) { ci, collection in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 9))
                                            .foregroundStyle(t.textGhost)
                                        Text(collection.name)
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(t.text)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                    .onTapGesture { vm.selectedCollectionIndex = ci }

                                    ForEach(Array(collection.requests.enumerated()), id: \.element.id) { ri, req in
                                        let selected = vm.selectedCollectionIndex == ci && vm.selectedRequestIndex == ri
                                        HStack(spacing: 6) {
                                            methodLabel(req.method)
                                            Text(req.name)
                                                .font(.system(size: 10.5, weight: .medium))
                                                .foregroundStyle(selected ? t.accent : t.textSecondary)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                        .background(selected ? t.accent.opacity(0.1) : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            vm.selectedCollectionIndex = ci
                                            vm.selectedRequestIndex = ri
                                            vm.response = nil
                                        }
                                    }
                                }
                            }
                        }
                        .padding(6)
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 180, maxWidth: 220)

                // Right — Editor
                if var request = vm.currentRequest {
                    VStack(spacing: 0) {
                        // URL bar
                        HStack(spacing: 6) {
                            Menu {
                                ForEach(APIClientService.HTTPMethod.allCases, id: \.self) { method in
                                    Button(method.rawValue) {
                                        vm.currentRequest?.method = method
                                        vm.save()
                                    }
                                }
                            } label: {
                                methodLabel(request.method)
                            }
                            .menuStyle(.borderlessButton)
                            .frame(width: 65)

                            TextField("https://api.example.com/endpoint", text: Binding(
                                get: { vm.currentRequest?.url ?? "" },
                                set: { vm.currentRequest?.url = $0; vm.save() }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(t.editorBg)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5))

                            DXButton(title: vm.isLoading ? "..." : "Send", icon: "paperplane.fill") {
                                Task { await vm.send() }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        Rectangle().fill(t.border).frame(height: 1)

                        VSplitView {
                            // Request tabs
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    ForEach(APIClientViewModel.RequestTab.allCases, id: \.self) { tab in
                                        Button {
                                            vm.activeTab = tab
                                        } label: {
                                            Text(tab.rawValue)
                                                .font(.system(size: 10, weight: vm.activeTab == tab ? .bold : .medium))
                                                .foregroundStyle(vm.activeTab == tab ? t.accent : t.textTertiary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Spacer()
                                }
                                .background(t.bgSecondary)
                                Rectangle().fill(t.border).frame(height: 1)

                                requestTabContent
                            }
                            .frame(minHeight: 120)

                            // Response
                            VStack(spacing: 0) {
                                Rectangle().fill(t.border).frame(height: 1)
                                responseView
                            }
                            .frame(minHeight: 150)
                        }
                    }
                    .background(t.editorBg)
                } else {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "paperplane")
                            .font(.system(size: 36, weight: .ultraLight))
                            .foregroundStyle(t.textGhost)
                        Text("Select or create a request")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(t.textTertiary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(t.editorBg)
                }
            }
        }
        .background(t.bg)
        .onAppear { vm.load() }
        .sheet(isPresented: $vm.showImportCurl) { importCurlSheet }
    }

    // MARK: - Request Tab Content

    @ViewBuilder var requestTabContent: some View {
        switch vm.activeTab {
        case .params:
            kvEditor(items: Binding(get: { vm.currentRequest?.queryParams ?? [] }, set: { vm.currentRequest?.queryParams = $0; vm.save() }),
                     addAction: { vm.addParamRow() })
        case .headers:
            kvEditor(items: Binding(get: { vm.currentRequest?.headers ?? [] }, set: { vm.currentRequest?.headers = $0; vm.save() }),
                     addAction: { vm.addHeaderRow() })
        case .auth:
            authEditor
        case .body:
            bodyEditor
        }
    }

    func kvEditor(items: Binding<[APIClientService.KeyValueItem]>, addAction: @escaping () -> Void) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(items) { $item in
                        HStack(spacing: 6) {
                            Toggle("", isOn: $item.enabled)
                                .toggleStyle(.checkbox)
                                .controlSize(.small)
                            TextField("key", text: $item.key)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, design: .monospaced))
                            TextField("value", text: $item.value)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, design: .monospaced))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                    }
                }
                .padding(8)
            }
            HStack {
                Button { addAction() } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.textTertiary)
                }
                .buttonStyle(.plain)
                .padding(8)
                Spacer()
            }
        }
    }

    var authEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Auth Type", selection: Binding(
                get: { vm.currentRequest?.authType ?? .none },
                set: { vm.currentRequest?.authType = $0; vm.save() }
            )) {
                ForEach(APIClientService.AuthType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .frame(width: 200)

            if vm.currentRequest?.authType == .bearer {
                TextField("Token", text: Binding(
                    get: { vm.currentRequest?.authToken ?? "" },
                    set: { vm.currentRequest?.authToken = $0; vm.save() }
                ))
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11, design: .monospaced))
            }
            if vm.currentRequest?.authType == .basic {
                TextField("Username", text: Binding(
                    get: { vm.currentRequest?.authUsername ?? "" },
                    set: { vm.currentRequest?.authUsername = $0; vm.save() }
                ))
                .textFieldStyle(.roundedBorder)
                SecureField("Password", text: Binding(
                    get: { vm.currentRequest?.authPassword ?? "" },
                    set: { vm.currentRequest?.authPassword = $0; vm.save() }
                ))
                .textFieldStyle(.roundedBorder)
            }
            Spacer()
        }
        .padding(12)
    }

    var bodyEditor: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                ForEach(APIClientService.BodyType.allCases, id: \.self) { type in
                    let active = vm.currentRequest?.bodyType == type
                    Button {
                        vm.currentRequest?.bodyType = type
                        vm.save()
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundStyle(active ? t.accent : t.textGhost)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(active ? t.accent.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(8)

            if vm.currentRequest?.bodyType != .none {
                CodeEditor(text: Binding(
                    get: { vm.currentRequest?.bodyContent ?? "" },
                    set: { vm.currentRequest?.bodyContent = $0; vm.save() }
                ), isEditable: true, language: "json")
            } else {
                Spacer()
            }
        }
    }

    // MARK: - Response

    @ViewBuilder var responseView: some View {
        if let res = vm.response {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    statusBadge(res.statusCode)
                    Text(String(format: "%.0fms", res.time * 1000))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(t.textGhost)
                    Text(formatSize(res.size))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(t.textGhost)
                    Spacer()
                    // Code gen
                    Menu {
                        ForEach(["cURL", "Swift", "Python", "JavaScript"], id: \.self) { lang in
                            Button(lang) {
                                vm.codeGenLanguage = lang
                                vm.generateCode()
                                vm.copyCode()
                                appState.showToast("\(lang) copied", icon: "doc.on.doc")
                            }
                        }
                    } label: {
                        Label("Code", systemImage: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 70)

                    SmallIconButton(title: "Copy", icon: "doc.on.doc") {
                        vm.copyResponse()
                        appState.showToast("Response copied", icon: "doc.on.doc")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(t.bgSecondary)
                Rectangle().fill(t.border).frame(height: 1)

                if let error = res.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(t.error)
                        Text(error)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(t.error)
                        Spacer()
                    }
                    .padding(12)
                    Spacer()
                } else {
                    CodeEditor(text: .constant(res.bodyString), isEditable: false, language: res.contentType.contains("json") ? "json" : "plain")
                }
            }
        } else if vm.isLoading {
            VStack {
                Spacer()
                ProgressView()
                    .controlSize(.small)
                Text("Sending…")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(t.textGhost)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 8) {
                Spacer()
                Text("Response will appear here")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(t.textGhost)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    func methodLabel(_ method: APIClientService.HTTPMethod) -> some View {
        let color: Color = switch method {
        case .get: t.success
        case .post: t.accent
        case .put: Color.blue
        case .delete: t.error
        case .patch: Color.purple
        default: t.textGhost
        }
        return Text(method.rawValue)
            .font(.system(size: 9, weight: .heavy, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
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
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes)B" }
        if bytes < 1048576 { return String(format: "%.1fKB", Double(bytes) / 1024.0) }
        return String(format: "%.1fMB", Double(bytes) / 1048576.0)
    }

    var importCurlSheet: some View {
        VStack(spacing: 12) {
            Text("Import cURL")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            TextEditor(text: $vm.importCurlText)
                .font(.system(size: 11, design: .monospaced))
                .frame(minHeight: 150)
                .border(Color.gray.opacity(0.3))
            HStack {
                Button("Cancel") { vm.showImportCurl = false }
                Spacer()
                Button("Import") { vm.importFromCurl() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 500)
    }
}

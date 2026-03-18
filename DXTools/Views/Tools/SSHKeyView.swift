import SwiftUI

struct SSHKeyView: View {
    @State private var vm = SSHManagerViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "SSH Manager", icon: "key.horizontal.fill") {
                ThemedPicker(selection: $vm.tab, options: SSHManagerViewModel.Tab.allCases, label: { $0.rawValue })
                Spacer()

                if vm.tab == .keys {
                    SmallIconButton(title: "Import", icon: "square.and.arrow.down") { vm.showImportSheet = true }
                }
                if vm.tab == .config {
                    SmallIconButton(title: "Add Host", icon: "plus") { vm.clearHostForm(); vm.showAddHostSheet = true }
                }
                DXButton(title: "Generate", icon: "plus.circle.fill") { vm.showGenerateSheet = true }
                SmallIconButton(title: "Refresh", icon: "arrow.clockwise") { vm.refresh() }
            }

            if let info = vm.directoryInfo { directoryStatusBar(info) }

            // Status toast
            if !vm.statusMessage.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: vm.statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 10)).foregroundStyle(vm.statusIsError ? t.error : t.success)
                    Text(vm.statusMessage).font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textSecondary).lineLimit(1)
                    Spacer()
                    Button { vm.statusMessage = "" } label: { Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundStyle(t.textGhost) }.buttonStyle(.plain)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(vm.statusIsError ? t.error.opacity(0.08) : t.success.opacity(0.08))
            }

            switch vm.tab {
            case .keys: keysTab
            case .config: configTab
            case .knownHosts: knownHostsTab
            case .agent: agentTab
            }
        }
        .background(t.bg)
        .onAppear { vm.refresh() }
        .sheet(isPresented: $vm.showGenerateSheet) { generateSheet }
        .sheet(isPresented: $vm.showImportSheet) { importSheet }
        .sheet(isPresented: $vm.showAddHostSheet) { hostFormSheet(isEdit: false) }
        .sheet(isPresented: $vm.showEditHostSheet) { hostFormSheet(isEdit: true) }
        .sheet(isPresented: $vm.showRenameSheet) { renameSheet }
        .alert("Delete Key?", isPresented: $vm.showDeleteConfirm) {
            Button("Delete", role: .destructive) { if let key = vm.selectedKey { vm.deleteKey(key) } }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This will permanently delete \(vm.selectedKey?.name ?? "") and its .pub file from ~/.ssh/") }
    }

    // MARK: - Status Bar

    func directoryStatusBar(_ info: SSHManagerService.SSHDirectoryInfo) -> some View {
        HStack(spacing: 12) {
            statusPill(icon: info.permissionsOK ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                       label: "~/.ssh", value: info.permissions, color: info.permissionsOK ? t.success : t.error)
            statusPill(icon: "key.fill", label: "Keys", value: "\(info.keyCount)", color: t.accent)
            if info.staleKeyCount > 0 {
                statusPill(icon: "clock.badge.exclamationmark", label: "Stale", value: "\(info.staleKeyCount)", color: t.warning)
            }
            if info.permIssueCount > 0 {
                Button { vm.fixAllPermissions() } label: {
                    statusPill(icon: "exclamationmark.triangle.fill", label: "Perm Issues", value: "\(info.permIssueCount)", color: t.error)
                }.buttonStyle(.plain).help("Fix all permissions")
            }
            Spacer()
            Button { vm.revealInFinder(info.path) } label: {
                HStack(spacing: 3) { Image(systemName: "folder").font(.system(size: 9)); Text("Reveal").font(.system(size: 9, weight: .semibold)) }.foregroundStyle(t.textTertiary)
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(t.surface)
        .overlay(alignment: .bottom) { Rectangle().fill(t.border).frame(height: 0.5) }
    }

    func statusPill(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8, weight: .bold)).foregroundStyle(color)
            Text(label).font(.system(size: 8.5, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.3)
            Text(value).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(t.text)
        }
        .padding(.horizontal, 8).padding(.vertical, 3).background(t.bg).clipShape(Capsule())
    }

    // MARK: - Keys Tab

    var keysTab: some View {
        HSplitView {
            VStack(spacing: 0) {
                // Search + filter bar
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass").font(.system(size: 10)).foregroundStyle(t.textGhost)
                        TextField("Search keys…", text: $vm.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                    }
                    .padding(5).background(t.surface).clipShape(RoundedRectangle(cornerRadius: 6))

                    ThemedPicker(selection: $vm.keyFilter, options: SSHManagerViewModel.KeyFilter.allCases, label: { $0.rawValue })
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .overlay(alignment: .bottom) { Rectangle().fill(t.border).frame(height: 0.5) }

                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(vm.filteredKeys) { key in
                            keyRow(key).onTapGesture { vm.selectedKey = key }
                        }
                        if vm.filteredKeys.isEmpty {
                            VStack(spacing: 6) {
                                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .ultraLight)).foregroundStyle(t.textGhost)
                                Text("No keys found").font(.system(size: 10, weight: .medium)).foregroundStyle(t.textTertiary)
                            }.padding(.top, 40).frame(maxWidth: .infinity)
                        }
                    }
                    .padding(8)
                }
            }
            .frame(minWidth: 280, idealWidth: 320)

            if let key = vm.selectedKey { keyDetail(key) }
            else {
                VStack { Spacer(); Image(systemName: "key.horizontal").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost); Text("Select a key").font(.system(size: 11, weight: .medium)).foregroundStyle(t.textTertiary); Spacer() }.frame(maxWidth: .infinity)
            }
        }
    }

    func keyRow(_ key: SSHManagerService.SSHKeyInfo) -> some View {
        let isSelected = vm.selectedKey?.path == key.path
        let inAgent = vm.isKeyInAgent(key)
        return HStack(spacing: 10) {
            ZStack {
                Circle().fill(keyTypeColor(key.keyType).opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: key.isDefault ? "key.horizontal.fill" : "key.horizontal").font(.system(size: 12, weight: .semibold)).foregroundStyle(keyTypeColor(key.keyType))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(key.name).font(.system(size: 11, weight: .bold)).foregroundStyle(isSelected ? t.accent : t.text).lineLimit(1)
                    if key.isDefault { pill("DEFAULT", color: t.accent) }
                    if key.isStale { pill(key.isAncient ? "OLD" : "STALE", color: key.isAncient ? t.error : t.warning) }
                    if inAgent { pill("AGENT", color: t.success) }
                }
                HStack(spacing: 6) {
                    Text(key.keyType.uppercased()).font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundStyle(keyTypeColor(key.keyType))
                    if !key.bits.isEmpty { Text(key.bits + "b").font(.system(size: 8, weight: .medium)).foregroundStyle(t.textGhost) }
                    Text(key.ageDescription).font(.system(size: 8, weight: .medium)).foregroundStyle(t.textGhost)
                    if !key.permissionsOK { Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 8)).foregroundStyle(t.warning) }
                    if !key.linkedHosts.isEmpty { Text("→ \(key.linkedHosts.joined(separator: ", "))").font(.system(size: 8, weight: .medium)).foregroundStyle(t.info).lineLimit(1) }
                }
            }
            Spacer()
            if key.publicKeyContent != nil {
                Button { vm.copyPublicKey(key); appState.showToast("Public key copied", icon: "doc.on.doc") } label: {
                    Image(systemName: "doc.on.doc").font(.system(size: 10)).foregroundStyle(t.textTertiary)
                }.buttonStyle(.plain).help("Copy public key")
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(isSelected ? t.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8)).contentShape(Rectangle())
    }

    func keyDetail(_ key: SSHManagerService.SSHKeyInfo) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(keyTypeColor(key.keyType).opacity(0.12)).frame(width: 48, height: 48)
                        Image(systemName: "key.horizontal.fill").font(.system(size: 20)).foregroundStyle(keyTypeColor(key.keyType))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(key.name).font(.system(size: 16, weight: .bold)).foregroundStyle(t.text)
                        HStack(spacing: 6) {
                            badge(key.keyType.uppercased(), color: keyTypeColor(key.keyType))
                            if !key.bits.isEmpty { badge(key.bits + " bit", color: t.textTertiary) }
                            badge(key.permissions, color: key.permissionsOK ? t.success : t.error)
                            badge(key.ageDescription, color: key.isStale ? t.warning : t.textTertiary)
                        }
                    }
                    Spacer()
                }

                // Linked hosts
                if !key.linkedHosts.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "link").font(.system(size: 9)).foregroundStyle(t.info)
                        Text("Used by:").font(.system(size: 9, weight: .bold)).foregroundStyle(t.textTertiary)
                        ForEach(key.linkedHosts, id: \.self) { host in
                            Text(host).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(t.info)
                                .padding(.horizontal, 6).padding(.vertical, 2).background(t.info.opacity(0.1)).clipShape(Capsule())
                        }
                    }
                }

                // Info grid
                VStack(spacing: 1) {
                    infoRow("Fingerprint", value: key.fingerprint, mono: true)
                    infoRow("Comment", value: key.comment.isEmpty ? "—" : key.comment)
                    infoRow("Path", value: key.path, mono: true)
                    infoRow("Permissions", value: key.permissions + (key.permissionsOK ? " ✓" : " ⚠ should be 600"))
                    if let date = key.createdDate { infoRow("Created", value: date.formatted(.dateTime.year().month().day().hour().minute())) }
                    infoRow("Age", value: "\(key.ageDays) days" + (key.isStale ? " ⚠ consider rotating" : ""))
                    infoRow("Size", value: ByteCountFormatter.string(fromByteCount: Int64(key.fileSize), countStyle: .file))
                }
                .clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))

                // Public key
                if let pubKey = key.publicKeyContent {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Image(systemName: "lock.open.fill").font(.system(size: 9)).foregroundStyle(t.success)
                            Text("PUBLIC KEY").font(.system(size: 9.5, weight: .heavy)).foregroundStyle(t.textTertiary).tracking(0.8)
                            Spacer()
                            SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyPublicKey(key); appState.showToast("Public key copied", icon: "doc.on.doc") }
                        }.padding(.horizontal, 12).padding(.vertical, 8).background(t.surface)
                        Rectangle().fill(t.border).frame(height: 0.5)
                        Text(pubKey).font(.system(size: 10, weight: .regular, design: .monospaced)).foregroundStyle(t.text).textSelection(.enabled).padding(12).frame(maxWidth: .infinity, alignment: .leading).background(t.editorBg)
                    }.clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
                }

                // Actions
                HStack(spacing: 8) {
                    if vm.isKeyInAgent(key) {
                        DXButton(title: "Remove from Agent", icon: "person.badge.minus") { vm.removeFromAgent(key); appState.showToast("Removed from agent", icon: "minus.circle") }
                    } else {
                        DXButton(title: "Add to Agent", icon: "person.badge.key.fill") { vm.addToAgent(key); appState.showToast("Added to SSH agent", icon: "checkmark") }
                    }
                    if !key.permissionsOK {
                        DXButton(title: "Fix Permissions", icon: "wrench.fill") { vm.fixPermissions(key); appState.showToast("Fixed", icon: "checkmark.shield") }
                    }
                    SmallIconButton(title: "Rename", icon: "pencil") { vm.renameName = key.name; vm.showRenameSheet = true }
                    SmallIconButton(title: "Reveal", icon: "folder") { vm.revealInFinder(key.path) }
                    Spacer()
                    Button { vm.showDeleteConfirm = true } label: {
                        HStack(spacing: 3) { Image(systemName: "trash").font(.system(size: 9)); Text("Delete").font(.system(size: 10, weight: .semibold)) }.foregroundStyle(t.error)
                    }.buttonStyle(.plain)
                }
            }.padding(20)
        }
    }

    // MARK: - Config Tab

    var configTab: some View {
        Group {
            if vm.hosts.isEmpty {
                VStack(spacing: 8) { Spacer(); Image(systemName: "doc.text").font(.system(size: 28, weight: .ultraLight)).foregroundStyle(t.textGhost); Text("No SSH Config").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.textTertiary); Text("Click 'Add Host' to create ~/.ssh/config entries").font(.system(size: 10)).foregroundStyle(t.textGhost); Spacer() }.frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) { ForEach(vm.hosts) { host in hostCard(host) } }.padding(16)
                }
            }
        }
    }

    func hostCard(_ host: SSHManagerService.SSHHostConfig) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "server.rack").font(.system(size: 12)).foregroundStyle(t.accent)
                Text(host.alias).font(.system(size: 13, weight: .bold)).foregroundStyle(t.text)
                Spacer()
                if vm.testingHost == host.alias { ProgressView().controlSize(.small) }
                else { SmallIconButton(title: "Test", icon: "antenna.radiowaves.left.and.right") { vm.testConnection(host) } }
                SmallIconButton(title: "Edit", icon: "pencil") { vm.startEditHost(host) }
                SmallIconButton(title: "Copy", icon: "doc.on.doc") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString("ssh \(host.alias)", forType: .string); appState.showToast("Copied: ssh \(host.alias)", icon: "doc.on.doc") }
                Button { vm.removeHost(host) } label: { Image(systemName: "trash").font(.system(size: 9)).foregroundStyle(t.error) }.buttonStyle(.plain)
            }.padding(12)
            Rectangle().fill(t.border).frame(height: 0.5)
            VStack(spacing: 1) {
                if !host.hostname.isEmpty { configRow("Host", host.hostname) }
                if !host.user.isEmpty { configRow("User", host.user) }
                configRow("Port", host.port)
                if !host.identityFile.isEmpty { configRow("Identity", host.identityFile) }
                ForEach(Array(host.otherOptions.enumerated()), id: \.offset) { _, opt in configRow(opt.key, opt.value) }
            }
            if let result = vm.testResult, vm.testingHost == nil {
                Rectangle().fill(t.border).frame(height: 0.5)
                HStack(spacing: 6) {
                    Image(systemName: vm.testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 10)).foregroundStyle(vm.testSuccess ? t.success : t.error)
                    Text(result).font(.system(size: 10, design: .monospaced)).foregroundStyle(t.textSecondary).lineLimit(2)
                }.padding(10)
            }
        }
        .background(t.surface).clipShape(RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
    }

    func configRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key).font(.system(size: 9.5, weight: .bold, design: .monospaced)).foregroundStyle(t.accent).frame(width: 80, alignment: .trailing)
            Text(value).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(t.text).textSelection(.enabled)
            Spacer()
        }.padding(.horizontal, 12).padding(.vertical, 4)
    }

    // MARK: - Known Hosts Tab

    var knownHostsTab: some View {
        Group {
            if vm.knownHosts.isEmpty {
                VStack(spacing: 8) { Spacer(); Image(systemName: "globe").font(.system(size: 28, weight: .ultraLight)).foregroundStyle(t.textGhost); Text("No Known Hosts").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.textTertiary); Spacer() }.frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    HStack { Text("\(vm.knownHosts.count) entries").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary); Spacer() }
                        .padding(.horizontal, 12).padding(.vertical, 6).background(t.surface).overlay(alignment: .bottom) { Rectangle().fill(t.border).frame(height: 0.5) }
                    List {
                        ForEach(vm.knownHosts) { host in
                            HStack(spacing: 8) {
                                Text("\(host.lineNumber)").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(t.textGhost).frame(width: 24, alignment: .trailing)
                                Text(host.hostname).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(t.text)
                                Text(host.keyType).font(.system(size: 9, weight: .medium)).foregroundStyle(t.textTertiary)
                                Spacer()
                                Button { vm.removeKnownHost(host); appState.showToast("Removed \(host.hostname)", icon: "trash") } label: { Image(systemName: "trash").font(.system(size: 9)).foregroundStyle(t.error) }.buttonStyle(.plain)
                            }.padding(.vertical, 2)
                        }
                    }.listStyle(.plain)
                }
            }
        }
    }

    // MARK: - Agent Tab

    var agentTab: some View {
        VStack(spacing: 0) {
            HStack {
                Text("SSH Agent").font(.system(size: 10, weight: .semibold)).foregroundStyle(t.textTertiary)
                Spacer()
                SmallIconButton(title: "Add All", icon: "plus.circle") { vm.addAllToAgent() }
                SmallIconButton(title: "Clear All", icon: "trash") { vm.removeAllFromAgent() }
                SmallIconButton(title: "Refresh", icon: "arrow.clockwise") { vm.agentKeys = SSHManagerService.listAgentKeys() }
            }.padding(.horizontal, 12).padding(.vertical, 8).background(t.surface).overlay(alignment: .bottom) { Rectangle().fill(t.border).frame(height: 0.5) }

            if vm.agentKeys.isEmpty {
                VStack(spacing: 8) { Spacer(); Image(systemName: "person.badge.key").font(.system(size: 28, weight: .ultraLight)).foregroundStyle(t.textGhost); Text("No Keys in Agent").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.textTertiary); Text("Use 'Add to Agent' or 'Add All'").font(.system(size: 10)).foregroundStyle(t.textGhost); Spacer() }.frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(vm.agentKeys.enumerated()), id: \.offset) { i, key in
                            HStack(spacing: 8) {
                                Text("\(i + 1)").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(t.textGhost).frame(width: 20, alignment: .trailing)
                                Text(key).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(t.text).lineLimit(1)
                                Spacer()
                            }.padding(.horizontal, 12).padding(.vertical, 6).background(t.surface).clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }.padding(12)
                }
            }
        }
    }

    // MARK: - Generate Sheet

    var generateSheet: some View {
        VStack(spacing: 16) {
            HStack { Text("Generate SSH Key").font(.system(size: 14, weight: .bold)).foregroundStyle(t.text); Spacer(); Button { vm.showGenerateSheet = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(t.textGhost) }.buttonStyle(.plain) }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) { Text("TYPE").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.8); ThemedPicker(selection: $vm.genKeyType, options: SSHKeyService.KeyType.allCases, label: { $0.rawValue }) }
                    VStack(alignment: .leading, spacing: 4) { Text("FILE NAME").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.8); TextField(vm.defaultFileName, text: $vm.genFileName).textFieldStyle(.roundedBorder).controlSize(.small) }
                }
                VStack(alignment: .leading, spacing: 4) { Text("COMMENT").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.8); TextField("user@host", text: $vm.genComment).textFieldStyle(.roundedBorder).controlSize(.small) }

                HStack(spacing: 4) {
                    Image(systemName: "folder.fill").font(.system(size: 9)).foregroundStyle(t.textGhost)
                    Text("~/.ssh/\(vm.resolvedFileName)").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(t.textSecondary)
                    if vm.fileAlreadyExists { pill("EXISTS", color: t.error) }
                    Spacer()
                }
            }

            DXButton(title: vm.isGenerating ? "Generating…" : "Generate & Save to ~/.ssh", icon: "key.fill") { vm.generateKey() }.disabled(vm.isGenerating || vm.fileAlreadyExists)

            if !vm.genError.isEmpty {
                HStack(spacing: 6) { Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundStyle(t.error); Text(vm.genError).font(.system(size: 10, weight: .medium)).foregroundStyle(t.error); Spacer() }.padding(8).background(t.error.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 6))
            }

            if let kp = vm.genKeyPair {
                VStack(spacing: 8) {
                    if vm.genSaved {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundStyle(t.success)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Saved to ~/.ssh/").font(.system(size: 11, weight: .bold)).foregroundStyle(t.success)
                                HStack(spacing: 4) { Text(vm.resolvedFileName).font(.system(size: 10, design: .monospaced)).foregroundStyle(t.text); Text("(600)").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(t.success); Text("+ .pub").font(.system(size: 10, design: .monospaced)).foregroundStyle(t.text); Text("(644)").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(t.success) }
                            }
                            Spacer()
                            SmallIconButton(title: "Reveal", icon: "folder") { vm.revealInFinder(vm.targetPrivatePath) }
                        }.padding(10).background(t.success.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    HStack(spacing: 6) { Image(systemName: "hand.point.up.braille.fill").font(.system(size: 9)).foregroundStyle(t.accent); Text(kp.fingerprint).font(.system(size: 10, design: .monospaced)).foregroundStyle(t.textSecondary).textSelection(.enabled); Spacer() }.padding(8).background(t.surface).clipShape(RoundedRectangle(cornerRadius: 8))
                    generatedKeyBox(title: "PUBLIC KEY — copy to GitHub / server", content: kp.publicKey, color: t.success)
                    generatedKeyBox(title: "PRIVATE KEY", content: kp.privateKey, color: t.error)
                }
            }
        }
        .padding(20).frame(width: 540).frame(minHeight: 200).background(t.bg)
        .onChange(of: vm.genKeyType) { vm.genFileName = "" }
    }

    // MARK: - Import Sheet

    var importSheet: some View {
        VStack(spacing: 16) {
            HStack { Text("Import SSH Key").font(.system(size: 14, weight: .bold)).foregroundStyle(t.text); Spacer(); Button { vm.showImportSheet = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(t.textGhost) }.buttonStyle(.plain) }
            VStack(alignment: .leading, spacing: 4) { Text("FILE NAME").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.8); TextField("id_deploy_prod", text: $vm.importName).textFieldStyle(.roundedBorder).controlSize(.small) }
            VStack(alignment: .leading, spacing: 4) { Text("PRIVATE KEY").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.8); TextEditor(text: $vm.importPrivateKey).font(.system(size: 10, design: .monospaced)).frame(height: 100).background(t.editorBg).clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5)) }
            VStack(alignment: .leading, spacing: 4) { Text("PUBLIC KEY (optional)").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost).tracking(0.8); TextEditor(text: $vm.importPublicKey).font(.system(size: 10, design: .monospaced)).frame(height: 60).background(t.editorBg).clipShape(RoundedRectangle(cornerRadius: 6)).overlay(RoundedRectangle(cornerRadius: 6).stroke(t.border, lineWidth: 0.5)) }
            DXButton(title: "Import to ~/.ssh/", icon: "square.and.arrow.down.fill") { vm.importKey() }
        }
        .padding(20).frame(width: 480).background(t.bg)
    }

    // MARK: - Host Form Sheet

    func hostFormSheet(isEdit: Bool) -> some View {
        VStack(spacing: 16) {
            HStack { Text(isEdit ? "Edit Host" : "Add SSH Host").font(.system(size: 14, weight: .bold)).foregroundStyle(t.text); Spacer(); Button { if isEdit { vm.showEditHostSheet = false } else { vm.showAddHostSheet = false } } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(t.textGhost) }.buttonStyle(.plain) }
            VStack(alignment: .leading, spacing: 4) { Text("ALIAS").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost); TextField("github-personal", text: $vm.editHostAlias).textFieldStyle(.roundedBorder).controlSize(.small) }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) { Text("HOSTNAME").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost); TextField("github.com", text: $vm.editHostHostname).textFieldStyle(.roundedBorder).controlSize(.small) }
                VStack(alignment: .leading, spacing: 4) { Text("USER").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost); TextField("git", text: $vm.editHostUser).textFieldStyle(.roundedBorder).controlSize(.small) }
                VStack(alignment: .leading, spacing: 4) { Text("PORT").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost); TextField("22", text: $vm.editHostPort).textFieldStyle(.roundedBorder).controlSize(.small).frame(width: 60) }
            }
            VStack(alignment: .leading, spacing: 4) { Text("IDENTITY FILE").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost); TextField("~/.ssh/id_ed25519", text: $vm.editHostIdentityFile).textFieldStyle(.roundedBorder).controlSize(.small) }
            DXButton(title: isEdit ? "Update Host" : "Add Host", icon: isEdit ? "checkmark.circle.fill" : "plus.circle.fill") { if isEdit { vm.updateHost() } else { vm.addHost() } }
        }
        .padding(20).frame(width: 460).background(t.bg)
    }

    // MARK: - Rename Sheet

    var renameSheet: some View {
        VStack(spacing: 16) {
            HStack { Text("Rename Key").font(.system(size: 14, weight: .bold)).foregroundStyle(t.text); Spacer(); Button { vm.showRenameSheet = false } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 14)).foregroundStyle(t.textGhost) }.buttonStyle(.plain) }
            VStack(alignment: .leading, spacing: 4) { Text("NEW NAME").font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textGhost); TextField("id_work_ed25519", text: $vm.renameName).textFieldStyle(.roundedBorder).controlSize(.small) }
            Text("Will rename both the private key and .pub file").font(.system(size: 10)).foregroundStyle(t.textGhost)
            DXButton(title: "Rename", icon: "pencil") { if let key = vm.selectedKey { vm.renameKey(key) } }
        }
        .padding(20).frame(width: 400).background(t.bg)
    }

    // MARK: - Helpers

    func generatedKeyBox(title: String, content: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Text(title).font(.system(size: 9, weight: .heavy)).foregroundStyle(t.textTertiary).tracking(0.8); Spacer(); SmallIconButton(title: "Copy", icon: "doc.on.doc") { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(content, forType: .string); appState.showToast("Copied!", icon: "doc.on.doc") } }.padding(8).background(t.surface)
            Rectangle().fill(t.border).frame(height: 0.5)
            Text(content).font(.system(size: 9.5, design: .monospaced)).foregroundStyle(t.text).textSelection(.enabled).lineLimit(4).padding(8).frame(maxWidth: .infinity, alignment: .leading).background(t.editorBg)
        }.clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))
    }

    func infoRow(_ label: String, value: String, mono: Bool = false) -> some View {
        HStack { Text(label).font(.system(size: 9.5, weight: .bold)).foregroundStyle(t.textTertiary).frame(width: 80, alignment: .trailing); Text(value).font(.system(size: mono ? 10 : 10.5, weight: .medium, design: mono ? .monospaced : .default)).foregroundStyle(t.text).textSelection(.enabled); Spacer() }.padding(.horizontal, 12).padding(.vertical, 5).background(t.surface)
    }

    func badge(_ text: String, color: Color) -> some View {
        Text(text).font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundStyle(color).padding(.horizontal, 5).padding(.vertical, 1.5).background(color.opacity(0.12)).clipShape(Capsule())
    }

    func pill(_ text: String, color: Color) -> some View {
        Text(text).font(.system(size: 7, weight: .heavy)).foregroundStyle(.white).padding(.horizontal, 4).padding(.vertical, 1).background(color).clipShape(Capsule())
    }

    func keyTypeColor(_ type: String) -> Color {
        switch type.lowercased() {
        case "ed25519": return t.success
        case "rsa": return t.info
        case "ecdsa": return t.warning
        default: return t.textTertiary
        }
    }
}

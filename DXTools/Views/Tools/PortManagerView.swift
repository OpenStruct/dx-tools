import SwiftUI

struct PortManagerView: View {
    @State private var vm = PortViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState


    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Port Manager", icon: "network")
            // ── Top Bar ──
            topBar
            Rectangle().fill(t.border).frame(height: 1)

            // ── Content ──
            HSplitView {
                // Left: Port list
                portList
                    .frame(minWidth: 480)

                // Right: Details + Quick actions
                rightPanel
                    .frame(minWidth: 280, maxWidth: 340)
            }
        }
        .background(t.bg)
        .onAppear { vm.refresh() }
        // Kill confirmation
        .alert("Kill Process", isPresented: Binding(
            get: { vm.killConfirmation != nil },
            set: { if !$0 { vm.killConfirmation = nil } }
        )) {
            Button("Cancel", role: .cancel) { vm.killConfirmation = nil }
            Button("Kill", role: .destructive) {
                if let proc = vm.killConfirmation {
                    vm.killProcess(proc)
                    vm.killConfirmation = nil
                }
            }
        } message: {
            if let proc = vm.killConfirmation {
                Text("Kill \(proc.processName) (PID \(proc.pid)) on port \(proc.port)?")
            }
        }
    }

    // MARK: - Top Bar

    var topBar: some View {
        HStack(spacing: 12) {
            // Search
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(t.textTertiary)
                TextField("Search ports, processes…", text: $vm.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                if !vm.searchQuery.isEmpty {
                    Button { vm.searchQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(t.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(t.glass)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
            .frame(maxWidth: 260)

            // Filter toggle
            HStack(spacing: 1) {
                filterPill("Listening", isActive: vm.showListeningOnly) {
                    vm.showListeningOnly = true; vm.refresh()
                }
                filterPill("All", isActive: !vm.showListeningOnly) {
                    vm.showListeningOnly = false; vm.refresh()
                }
            }
            .padding(2)
            .background(t.glass)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 0.5))

            Spacer()

            // Stats
            HStack(spacing: 14) {
                statPill("\(vm.portStats.total)", "Ports", t.accent)
                statPill("\(vm.portStats.dev)", "Dev", t.info)
                statPill("\(vm.portStats.db)", "DB", t.warning)
            }

            // Refresh
            DXButton(title: "Refresh", icon: "arrow.clockwise", style: .secondary) {
                vm.refresh()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.3))
        .background(t.glass)
    }

    // MARK: - Port List

    var portList: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                sortableHeader("Port", .port, width: 70)
                sortableHeader("Process", .process, width: 120)
                sortableHeader("PID", .pid, width: 65)
                sortableHeader("User", .user, width: 75)
                Text("Command")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(t.textTertiary)
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                Text("") // Action column
                    .frame(width: 80)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            // Rows
            if vm.isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning ports…")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                }
                Spacer()
            } else if vm.filteredProcesses.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 30, weight: .ultraLight))
                        .foregroundStyle(t.success.opacity(0.5))
                    Text("No ports in use")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                    Text("All clear — nothing listening")
                        .font(.system(size: 11))
                        .foregroundStyle(t.textGhost)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        ForEach(vm.filteredProcesses) { proc in
                            portRow(proc)
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.vertical, 4)
                    .animation(.spring(response: 0.3), value: vm.processes.count)
                }
            }

            // Status message
            if let msg = vm.statusMessage {
                Rectangle().fill(t.border).frame(height: 1)
                HStack(spacing: 8) {
                    Image(systemName: vm.statusIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(vm.statusIsError ? t.error : t.success)
                    Text(msg)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(t.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background((vm.statusIsError ? t.error : t.success).opacity(0.05))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(t.editorBg)
        .animation(.spring(response: 0.3), value: vm.statusMessage != nil)
    }

    // MARK: - Port Row

    func portRow(_ proc: PortProcess) -> some View {
        let isSelected = vm.selectedProcess == proc
        @State var isHovered = false

        return HStack(spacing: 0) {
            // Port
            HStack(spacing: 5) {
                Circle()
                    .fill(categoryColor(proc.portCategory))
                    .frame(width: 6, height: 6)
                    .shadow(color: categoryColor(proc.portCategory).opacity(0.4), radius: 3)
                Text("\(proc.port)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(t.text)
            }
            .frame(width: 70, alignment: .leading)

            // Process
            Text(proc.processName)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(t.text)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            // PID
            Text("\(proc.pid)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(t.textSecondary)
                .frame(width: 65, alignment: .leading)

            // User
            Text(proc.user)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(t.textTertiary)
                .frame(width: 75, alignment: .leading)

            // Command
            Text(proc.command)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(t.textTertiary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)

            // Actions
            HStack(spacing: 4) {
                SmallIconButton(title: "", icon: "doc.on.doc") {
                    vm.copyProcessInfo(proc)
                    appState.showToast("Copied", icon: "doc.on.doc")
                }

                Button {
                    vm.killConfirmation = proc
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("Kill")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(proc.isSystemProcess ? t.textGhost : t.error)
                    )
                    .opacity(proc.isSystemProcess ? 0.5 : 1)
                }
                .buttonStyle(.plain)
                .disabled(proc.isSystemProcess)
                .help(proc.isSystemProcess ? "System process — cannot kill" : "Kill PID \(proc.pid)")
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? t.accent.opacity(0.06) : isHovered ? t.surfaceHover.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { vm.selectedProcess = proc }
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
        .padding(.horizontal, 4)
    }

    // MARK: - Right Panel

    var rightPanel: some View {
        VStack(spacing: 0) {
            // Quick kill port
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(t.accent)
                    Text("QUICK KILL")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                        .tracking(0.8)
                }

                HStack(spacing: 6) {
                    TextField("Port #", text: $vm.checkPort)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(t.editorBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 1))
                        .onSubmit { vm.killPort() }

                    Button {
                        vm.checkPortStatus()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(t.textSecondary)
                            .padding(8)
                            .background(t.glass)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)

                    Button {
                        vm.killPort()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(t.error)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                if let result = vm.checkResult {
                    Text(result)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(result.contains("✓") ? t.success : t.warning)
                        .padding(.top, 2)
                }
            }
            .padding(16)

            Rectangle().fill(t.border).frame(height: 1)

            // Common dev ports
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(t.warning)
                    Text("COMMON PORTS")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                        .tracking(0.8)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 3) {
                        ForEach(PortService.commonDevPorts, id: \.0) { port, name in
                            let inUse = vm.processes.contains { $0.port == port }

                            HStack(spacing: 8) {
                                Circle()
                                    .fill(inUse ? t.error : t.success)
                                    .frame(width: 5, height: 5)
                                    .shadow(color: (inUse ? t.error : t.success).opacity(0.4), radius: 2)

                                Text("\(port)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(t.text)
                                    .frame(width: 45, alignment: .leading)

                                Text(name)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundStyle(t.textSecondary)
                                    .lineLimit(1)

                                Spacer()

                                if inUse {
                                    Button {
                                        vm.checkPort = "\(port)"
                                        vm.killPort()
                                    } label: {
                                        Text("Kill")
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundStyle(t.error)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(t.error.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("Free")
                                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                                        .foregroundStyle(t.success.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 7)
                                    .fill(inUse ? t.error.opacity(0.04) : Color.clear)
                            )
                        }
                    }
                }
            }
            .padding(16)

            Spacer()

            // Selected process detail
            if let proc = vm.selectedProcess {
                Rectangle().fill(t.border).frame(height: 1)
                processDetail(proc)
            }
        }
        .background(t.bgSecondary)
    }

    // MARK: - Process Detail

    func processDetail(_ proc: PortProcess) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(t.accent)
                Text("DETAILS")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(t.textTertiary)
                    .tracking(0.8)
                Spacer()
            }

            detailRow("Port", "\(proc.port)")
            detailRow("PID", "\(proc.pid)")
            detailRow("Process", proc.processName)
            detailRow("User", proc.user)
            detailRow("Protocol", proc.protocol_)
            detailRow("State", proc.state)

            if !proc.command.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Command")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(t.textGhost)
                    Text(proc.command)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundStyle(t.textSecondary)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(16)
    }

    func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(t.textGhost)
                .frame(width: 56, alignment: .trailing)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
        }
    }

    // MARK: - Helpers

    func filterPill(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: isActive ? .bold : .medium, design: .rounded))
                .foregroundStyle(isActive ? t.accent : t.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isActive ? t.accent.opacity(0.1) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    func statPill(_ value: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(t.textTertiary)
        }
    }

    func sortableHeader(_ title: String, _ option: PortViewModel.SortOption, width: CGFloat) -> some View {
        Button {
            if vm.sortBy == option {
                vm.sortAscending.toggle()
            } else {
                vm.sortBy = option
                vm.sortAscending = true
            }
        } label: {
            HStack(spacing: 3) {
                Text(title.uppercased())
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(vm.sortBy == option ? t.accent : t.textTertiary)
                    .tracking(0.6)
                if vm.sortBy == option {
                    Image(systemName: vm.sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(t.accent)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: width, alignment: .leading)
    }

    func categoryColor(_ cat: PortProcess.PortCategory) -> Color {
        switch cat {
        case .web: return t.info
        case .dev: return t.accent
        case .database: return t.warning
        case .system: return t.textTertiary
        case .other: return t.textGhost
        }
    }
}

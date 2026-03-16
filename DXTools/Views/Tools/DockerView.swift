import SwiftUI

struct DockerView: View {
    @State private var vm = DockerViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: vm.runtimeName, icon: "shippingbox.fill") {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.textTertiary)
                    TextField("Search…", text: $vm.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium))
                    if !vm.searchQuery.isEmpty {
                        Button { vm.searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 9)).foregroundStyle(t.textTertiary)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(t.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .frame(maxWidth: 180)

                Toggle("All", isOn: $vm.showAll)
                    .toggleStyle(.switch).controlSize(.small)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .onChange(of: vm.showAll) { _, _ in vm.refresh() }

                Spacer()

                if !vm.containers.isEmpty {
                    HStack(spacing: 8) {
                        let running = vm.containers.filter(\.isRunning).count
                        let stopped = vm.containers.count - running
                        statBadge("\(running)", "Running", t.success)
                        statBadge("\(stopped)", "Stopped", t.textGhost)
                    }
                }

                DXButton(title: "Refresh", icon: "arrow.clockwise", style: .secondary) { vm.refresh() }
            }

            if !vm.isDockerAvailable && !vm.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "shippingbox")
                        .font(.system(size: 36, weight: .ultraLight))
                        .foregroundStyle(t.textGhost)
                    Text("No container runtime found")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                    Text("Install Docker, Podman, or OrbStack and refresh")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(t.textGhost)
                    DXButton(title: "Refresh", icon: "arrow.clockwise", style: .secondary) { vm.refresh() }
                        .padding(.top, 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if vm.isLoading {
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView().controlSize(.small)
                    Text("Loading containers…")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                HSplitView {
                    containerList
                        .frame(minWidth: 360)

                    logsPanel
                        .frame(minWidth: 260)
                }
            }
        }
        .background(t.bg)
        .onAppear { vm.refresh() }
    }

    // MARK: - Container List

    var containerList: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("CONTAINER")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("IMAGE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("STATUS")
                    .frame(width: 100, alignment: .leading)
                Text("")
                    .frame(width: 90)
            }
            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
            .foregroundStyle(t.textGhost)
            .tracking(0.6)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 0.5)

            if vm.filtered.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundStyle(t.success.opacity(0.4))
                    Text("No containers")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(t.textGhost)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        ForEach(vm.filtered) { c in
                            containerRow(c)
                        }
                    }
                    .padding(4)
                }
            }
        }
        .background(t.editorBg)
    }

    func containerRow(_ c: DockerService.Container) -> some View {
        let isSelected = vm.selectedContainer?.id == c.id
        @State var isHovered = false

        return HStack(spacing: 0) {
            // Name
            HStack(spacing: 6) {
                Circle()
                    .fill(c.isRunning ? t.success : t.textGhost)
                    .frame(width: 6, height: 6)
                    .shadow(color: (c.isRunning ? t.success : Color.clear).opacity(0.4), radius: 3)
                Text(c.name)
                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(t.text)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Image
            Text(c.image)
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundStyle(t.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Status
            Text(c.status)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(c.isRunning ? t.success : t.textTertiary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)

            // Actions
            HStack(spacing: 4) {
                if c.isRunning {
                    SmallIconButton(title: "", icon: "stop.fill") { vm.stop(c) }
                    SmallIconButton(title: "", icon: "arrow.clockwise") { vm.restart(c) }
                } else {
                    SmallIconButton(title: "", icon: "play.fill") { vm.start(c) }
                    SmallIconButton(title: "", icon: "trash") { vm.remove(c) }
                }
                SmallIconButton(title: "", icon: "doc.text") { vm.loadLogs(c) }
            }
            .opacity(isHovered || isSelected ? 1 : 0.3)
            .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(isSelected ? t.accent.opacity(0.06) : isHovered ? t.surfaceHover.opacity(0.5) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture { vm.loadLogs(c) }
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.1), value: isHovered)
    }

    // MARK: - Logs Panel

    var logsPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(t.accent)
                Text("LOGS")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(t.textTertiary)
                    .tracking(0.8)
                if let c = vm.selectedContainer {
                    Text("— \(c.name)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(t.textGhost)
                        .lineLimit(1)
                }
                Spacer()
                if vm.selectedContainer != nil && !vm.logs.isEmpty {
                    SmallIconButton(title: "", icon: "doc.on.doc") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.logs, forType: .string)
                        appState.showToast("Logs copied", icon: "doc.on.doc")
                    }
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 0.5)

            ScrollView {
                if vm.logs.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 20, weight: .ultraLight))
                            .foregroundStyle(t.textGhost)
                        Text("Select a container")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(t.textGhost)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    Text(vm.logs)
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundStyle(t.text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
            }
            .background(t.editorBg)
        }
    }

    // MARK: - Helpers

    func statBadge(_ value: String, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(t.textTertiary)
        }
    }
}

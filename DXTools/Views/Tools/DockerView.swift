import SwiftUI

struct DockerView: View {
    @State private var vm = DockerViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                Image(systemName: "shippingbox.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                TextField("Search containers…", text: $vm.searchQuery)
                    .textFieldStyle(.plain).font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.text)

                Toggle("Show All", isOn: $vm.showAll)
                    .toggleStyle(.switch).controlSize(.small)
                    .font(.system(size: 10, weight: .semibold))
                    .onChange(of: vm.showAll) { _, _ in vm.refresh() }

                SmallIconButton(title: "Refresh", icon: "arrow.clockwise") { vm.refresh() }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            if !vm.isDockerAvailable && !vm.isLoading {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "shippingbox").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                    Text("Docker not running").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                    Text("Start Docker Desktop and refresh").font(.system(size: 10, weight: .medium)).foregroundStyle(t.textGhost)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                HSplitView {
                    // Container list
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("NAME").frame(width: 140, alignment: .leading)
                            Text("IMAGE").frame(width: 160, alignment: .leading)
                            Text("STATUS").frame(width: 120, alignment: .leading)
                            Spacer()
                        }
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.textGhost).tracking(0.8)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(t.glass)
                        Rectangle().fill(t.border).frame(height: 0.5)

                        ScrollView {
                            LazyVStack(spacing: 1) {
                                ForEach(vm.filtered) { c in
                                    containerRow(c)
                                }
                            }
                            .padding(4)
                        }
                    }
                    .frame(minWidth: 400)

                    // Logs panel
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "doc.text").font(.system(size: 9, weight: .bold)).foregroundStyle(t.accent)
                            Text("LOGS").font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
                            if let c = vm.selectedContainer {
                                Text("— \(c.name)").font(.system(size: 9, weight: .medium)).foregroundStyle(t.textGhost)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(t.glass)
                        Rectangle().fill(t.border).frame(height: 0.5)

                        ScrollView {
                            Text(vm.logs.isEmpty ? "Select a container to view logs" : vm.logs)
                                .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                                .foregroundStyle(vm.logs.isEmpty ? t.textGhost : t.text)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .background(t.editorBg)
                    }
                    .frame(minWidth: 300)
                }
            }
        }
        .background(t.bg)
        .onAppear { vm.refresh() }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 7) {
                    Image(systemName: "shippingbox.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                    Text("Docker").font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
        }
    }

    func containerRow(_ c: DockerService.Container) -> some View {
        HStack(spacing: 8) {
            Circle().fill(c.isRunning ? t.success : t.textGhost).frame(width: 6, height: 6)
            Text(c.name).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(t.text).frame(width: 130, alignment: .leading).lineLimit(1)
            Text(c.image).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(t.textSecondary).frame(width: 150, alignment: .leading).lineLimit(1)
            Text(c.status).font(.system(size: 10, weight: .medium)).foregroundStyle(c.isRunning ? t.success : t.textTertiary).frame(width: 110, alignment: .leading).lineLimit(1)
            Spacer()

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
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(vm.selectedContainer?.id == c.id ? t.accent.opacity(0.06) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture { vm.loadLogs(c) }
    }
}

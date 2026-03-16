import SwiftUI

struct ErrorTrackerView: View {
    @State private var vm = ErrorTrackerViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Error Tracker", icon: "exclamationmark.triangle.fill") {
                Spacer()
                DXButton(title: "Paste Logs", icon: "doc.on.clipboard", style: .secondary) { vm.showPasteSheet = true }
                DXButton(title: "Open File", icon: "folder", style: .secondary) { vm.openFile() }
                if !vm.errors.isEmpty {
                    DXButton(title: "Clear", icon: "trash", style: .secondary) { vm.clear() }
                }
            }

            if !vm.errors.isEmpty {
                // Stats bar
                HStack(spacing: 16) {
                    statBadge("\(vm.errors.count) errors", icon: "exclamationmark.circle", color: t.error)
                    statBadge("\(vm.visibleGroups.count) unique", icon: "square.stack", color: t.accent)
                    ForEach(vm.sourceCounts, id: \.0) { source, count in
                        statBadge("\(source.rawValue): \(count)", icon: "chevron.left.forwardslash.chevron.right", color: t.textTertiary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(t.bgSecondary)
                Rectangle().fill(t.border).frame(height: 1)
            }

            HSplitView {
                // Left — Error groups
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "ERROR GROUPS (\(vm.visibleGroups.count))", icon: "list.bullet") {}
                    Rectangle().fill(t.border).frame(height: 1)

                    if vm.groups.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Paste or open log files")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(t.textTertiary)
                            Text("Supports JS, Python, Swift, Java, Go")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 4) {
                                ForEach(vm.visibleGroups) { group in
                                    errorGroupRow(group)
                                }
                            }
                            .padding(8)
                        }
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 240, maxWidth: 300)

                // Right — Detail
                VStack(spacing: 0) {
                    if let group = vm.selectedGroup {
                        groupDetail(group)
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 36, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Select an error to view details")
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
        .sheet(isPresented: $vm.showPasteSheet) { pasteSheet }
    }

    // MARK: - Components

    func errorGroupRow(_ group: ErrorTrackerService.ErrorGroup) -> some View {
        let isSelected = vm.selectedGroupId == group.id
        let levelColor = levelColor(group.level)
        return HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(levelColor)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(group.type)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(levelColor)
                    Spacer()
                    Text("×\(group.count)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(t.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text(group.message)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(t.textSecondary)
                    .lineLimit(1)
                Text(group.source.rawValue)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(t.textGhost)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? t.accent.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .contentShape(Rectangle())
        .onTapGesture { vm.selectedGroupId = group.id }
    }

    func groupDetail(_ group: ErrorTrackerService.ErrorGroup) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                EditorPaneHeader(title: group.type, icon: "exclamationmark.triangle") {}
                Spacer()
                SmallIconButton(title: "Copy Stack", icon: "doc.on.doc") {
                    vm.copyStack(group)
                    appState.showToast("Stack copied", icon: "doc.on.doc")
                }
                SmallIconButton(title: "Resolve", icon: "checkmark.circle") {
                    vm.resolve(group.id)
                    appState.showToast("Error resolved", icon: "checkmark.circle")
                }
            }
            .padding(.trailing, 8)
            Rectangle().fill(t.border).frame(height: 1)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    // Message
                    Text(group.message)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(t.text)
                        .textSelection(.enabled)

                    // Stats
                    HStack(spacing: 16) {
                        statBadge("\(group.count) occurrences", icon: "number", color: t.accent)
                        statBadge(group.source.rawValue, icon: "chevron.left.forwardslash.chevron.right", color: t.textTertiary)
                    }

                    // Stack trace
                    if let firstError = group.occurrences.first, !firstError.stackTrace.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("STACK TRACE")
                                .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                                .foregroundStyle(t.textGhost)
                                .tracking(0.8)

                            ForEach(Array(firstError.stackTrace.enumerated()), id: \.offset) { _, frame in
                                HStack(spacing: 6) {
                                    Image(systemName: frame.isUserCode ? "chevron.right" : "minus")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(frame.isUserCode ? t.accent : t.textGhost)
                                        .frame(width: 12)
                                    Text(frame.function.isEmpty ? frame.file : frame.function)
                                        .font(.system(size: 11, weight: frame.isUserCode ? .semibold : .regular, design: .monospaced))
                                        .foregroundStyle(frame.isUserCode ? t.text : t.textTertiary)
                                    if !frame.file.isEmpty || frame.line != nil {
                                        Spacer()
                                        Text("\(frame.file)\(frame.line.map { ":\($0)" } ?? "")")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundStyle(t.textGhost)
                                    }
                                }
                                .padding(.vertical, 3)
                                .padding(.horizontal, 8)
                                .background(frame.isUserCode ? t.accent.opacity(0.05) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }

                    // Raw log
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RAW LOG")
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundStyle(t.textGhost)
                            .tracking(0.8)
                        Text(group.occurrences.first?.raw ?? "")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(t.textSecondary)
                            .textSelection(.enabled)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(t.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                    }
                }
                .padding(16)
            }
        }
    }

    func statBadge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
    }

    func levelColor(_ level: ErrorTrackerService.ErrorLevel) -> Color {
        switch level {
        case .fatal: return t.error
        case .error: return t.warning
        case .warning: return Color.yellow
        case .info: return t.accent
        }
    }

    var pasteSheet: some View {
        VStack(spacing: 12) {
            Text("Paste Log Output")
                .font(.system(size: 16, weight: .bold, design: .rounded))
            TextEditor(text: $vm.logInput)
                .font(.system(size: 11, design: .monospaced))
                .frame(minHeight: 300)
                .border(Color.gray.opacity(0.3))
            HStack {
                Button("Cancel") { vm.showPasteSheet = false }
                Spacer()
                Button("Parse") {
                    vm.parseInput()
                    vm.showPasteSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 600, height: 420)
    }
}

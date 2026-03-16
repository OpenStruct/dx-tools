import SwiftUI

struct DatabaseView: View {
    @State private var vm = DatabaseViewModel()
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Database", icon: "cylinder.split.1x2") {
                if vm.isConnected {
                    HStack(spacing: 6) {
                        Circle().fill(t.success).frame(width: 7, height: 7)
                        Text(vm.dbName)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(t.text)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if vm.isConnected {
                    DXButton(title: "Disconnect", icon: "xmark.circle", style: .secondary) { vm.disconnect() }
                }
                DXButton(title: "Connect SQLite", icon: "cylinder") { vm.connectFile() }
            }

            HSplitView {
                // Left — Tables
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "TABLES", icon: "tablecells") {}
                    Rectangle().fill(t.border).frame(height: 1)

                    if !vm.isConnected {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "cylinder.split.1x2")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(t.textGhost)
                            Text("Connect a database")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(t.textGhost)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 2) {
                                ForEach(vm.tables, id: \.self) { table in
                                    let selected = vm.selectedTable == table
                                    HStack(spacing: 6) {
                                        Image(systemName: "tablecells")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(selected ? t.accent : t.textGhost)
                                        Text(table)
                                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                            .foregroundStyle(selected ? t.accent : t.text)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selected ? t.accent.opacity(0.1) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .contentShape(Rectangle())
                                    .onTapGesture { vm.selectTable(table) }
                                }
                            }
                            .padding(8)
                        }
                    }

                    // Table info
                    if let info = vm.tableInfo {
                        Rectangle().fill(t.border).frame(height: 1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("COLUMNS")
                                .font(.system(size: 9, weight: .heavy, design: .rounded))
                                .foregroundStyle(t.textGhost)
                                .tracking(0.8)
                            ForEach(info.columns, id: \.name) { col in
                                HStack(spacing: 4) {
                                    if col.isPrimaryKey {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 8))
                                            .foregroundStyle(t.accent)
                                    }
                                    Text(col.name)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundStyle(t.text)
                                    Text(col.type)
                                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                                        .foregroundStyle(t.textGhost)
                                    Spacer()
                                }
                            }
                            Text("\(info.rowCount) rows")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(t.textGhost)
                        }
                        .padding(10)
                        .background(t.surface)
                    }
                }
                .background(t.bgSecondary)
                .frame(minWidth: 160, maxWidth: 200)

                // Right — Query + Results
                VStack(spacing: 0) {
                    // Query editor
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            EditorPaneHeader(title: "QUERY", icon: "chevron.left.forwardslash.chevron.right") {}
                            Spacer()
                            if let result = vm.queryResult, result.error == nil {
                                Text("\(String(format: "%.3f", result.executionTime))s")
                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(t.textGhost)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(t.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            SmallIconButton(title: "Run", icon: "play.fill") { vm.runQuery() }
                        }
                        .padding(.trailing, 8)
                        Rectangle().fill(t.border).frame(height: 1)
                        CodeEditor(text: $vm.queryInput, isEditable: true, language: "sql")
                            .frame(minHeight: 80, maxHeight: 120)
                    }

                    Rectangle().fill(t.border).frame(height: 1)

                    // Error
                    if let error = vm.error {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(t.error)
                            Text(error)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(t.error)
                            Spacer()
                        }
                        .padding(8)
                        .background(t.error.opacity(0.08))
                        Rectangle().fill(t.border).frame(height: 1)
                    }

                    // Results
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            EditorPaneHeader(title: "RESULTS", icon: "tablecells") {}
                            Spacer()
                            if vm.queryResult != nil {
                                SmallIconButton(title: "CSV", icon: "doc.text") {
                                    vm.copy(vm.exportCSV())
                                    appState.showToast("CSV copied", icon: "doc.on.doc")
                                }
                                SmallIconButton(title: "JSON", icon: "curlybraces") {
                                    vm.copy(vm.exportJSON())
                                    appState.showToast("JSON copied", icon: "doc.on.doc")
                                }
                                SmallIconButton(title: "SQL", icon: "cylinder") {
                                    vm.copy(vm.exportSQL())
                                    appState.showToast("SQL copied", icon: "doc.on.doc")
                                }
                            }
                        }
                        .padding(.trailing, 8)
                        Rectangle().fill(t.border).frame(height: 1)

                        if let result = vm.queryResult, result.error == nil {
                            resultGrid(result)

                            // Footer
                            HStack {
                                Text("\(result.rowCount) rows")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(t.textTertiary)
                                if result.affectedRows > 0 {
                                    Text("· \(result.affectedRows) affected")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(t.textGhost)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(t.bgSecondary)
                        } else if !vm.isConnected {
                            VStack(spacing: 12) {
                                Spacer()
                                Image(systemName: "cylinder.split.1x2")
                                    .font(.system(size: 36, weight: .ultraLight))
                                    .foregroundStyle(t.textGhost)
                                Text("Connect to a SQLite database")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(t.textTertiary)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 400)
            }
        }
        .background(t.bg)
    }

    func resultGrid(_ result: DatabaseService.QueryResult) -> some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(spacing: 0) {
                // Header row
                HStack(spacing: 0) {
                    ForEach(result.columns, id: \.self) { col in
                        Text(col)
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(t.text)
                            .frame(minWidth: 80, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                    }
                }
                .background(t.surface)
                Rectangle().fill(t.border).frame(height: 1)

                // Data rows
                ForEach(Array(result.rows.enumerated()), id: \.offset) { rowIdx, row in
                    HStack(spacing: 0) {
                        ForEach(Array(row.enumerated()), id: \.offset) { colIdx, value in
                            Text(value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(value == "NULL" ? t.textGhost : t.text)
                                .frame(minWidth: 80, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                        }
                    }
                    .background(rowIdx % 2 == 0 ? Color.clear : t.surface.opacity(0.3))
                }
            }
        }
    }
}

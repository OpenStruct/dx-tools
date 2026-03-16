import SwiftUI

@Observable
class DatabaseViewModel {
    var activeDB: OpaquePointer?
    var dbName: String = ""
    var dbPath: String = ""
    var tables: [String] = []
    var selectedTable: String?
    var tableInfo: DatabaseService.TableInfo?
    var queryInput: String = ""
    var queryResult: DatabaseService.QueryResult?
    var isConnected: Bool = false
    var error: String?

    func connectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.data]
        panel.allowsMultipleSelection = false
        panel.allowsOtherFileTypes = true
        panel.allowedFileTypes = ["db", "sqlite", "sqlite3", "sqlitedb"]
        panel.message = "Select a SQLite database file (.db, .sqlite, .sqlite3)"
        if panel.runModal() == .OK, let url = panel.url {
            connectTo(url.path, name: url.lastPathComponent)
        }
    }

    func connectTo(_ path: String, name: String) {
        disconnect()
        switch DatabaseService.connect(path) {
        case .success(let db):
            activeDB = db
            dbName = name
            dbPath = path
            isConnected = true
            tables = DatabaseService.listTables(db)
            error = nil
        case .failure(let err):
            error = err.message
        }
    }

    func disconnect() {
        if let db = activeDB {
            DatabaseService.disconnect(db)
        }
        activeDB = nil
        isConnected = false
        tables = []
        selectedTable = nil
        tableInfo = nil
        queryResult = nil
        dbName = ""
    }

    func selectTable(_ name: String) {
        guard let db = activeDB else { return }
        selectedTable = name
        tableInfo = DatabaseService.tableInfo(db, table: name)
        queryResult = DatabaseService.preview(db, table: name)
        error = queryResult?.error
    }

    func runQuery() {
        guard let db = activeDB else { return }
        let sql = queryInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sql.isEmpty else { return }
        queryResult = DatabaseService.execute(db, sql: sql)
        error = queryResult?.error
        // Refresh tables in case schema changed
        tables = DatabaseService.listTables(db)
    }

    func exportCSV() -> String {
        guard let result = queryResult else { return "" }
        return DatabaseService.exportCSV(result)
    }

    func exportJSON() -> String {
        guard let result = queryResult else { return "" }
        return DatabaseService.exportJSON(result)
    }

    func exportSQL() -> String {
        guard let result = queryResult else { return "" }
        return DatabaseService.exportInsertStatements(result, table: selectedTable ?? "table")
    }

    func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

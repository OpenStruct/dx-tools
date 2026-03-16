import Foundation
import SQLite3

struct DatabaseService {
    struct DBConnection: Identifiable {
        var id: UUID = UUID()
        var name: String
        var path: String
    }

    struct QueryResult {
        var columns: [String]
        var rows: [[String]]
        var rowCount: Int
        var executionTime: TimeInterval
        var error: String?
        var affectedRows: Int
    }

    struct TableInfo {
        var name: String
        var columnCount: Int
        var rowCount: Int
        var columns: [ColumnInfo]
    }

    struct ColumnInfo {
        var name: String
        var type: String
        var isPrimaryKey: Bool
        var isNotNull: Bool
        var defaultValue: String?
    }

    // MARK: - Connection

    struct DBError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func connect(_ path: String) -> Result<OpaquePointer, DBError> {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
        let result = sqlite3_open_v2(path, &db, flags, nil)
        if result == SQLITE_OK, let db = db {
            return .success(db)
        } else {
            let msg = db.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            if let db = db { sqlite3_close(db) }
            return .failure(DBError(message: msg))
        }
    }

    static func connectInMemory() -> Result<OpaquePointer, DBError> {
        return connect(":memory:")
    }

    static func disconnect(_ db: OpaquePointer) {
        sqlite3_close(db)
    }

    // MARK: - Schema

    static func listTables(_ db: OpaquePointer) -> [String] {
        let result = execute(db, sql: "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
        return result.rows.map { $0.first ?? "" }
    }

    static func tableInfo(_ db: OpaquePointer, table: String) -> TableInfo {
        let result = execute(db, sql: "PRAGMA table_info('\(table)')")
        let columns = result.rows.map { row in
            ColumnInfo(
                name: row.count > 1 ? row[1] : "",
                type: row.count > 2 ? row[2] : "",
                isPrimaryKey: row.count > 5 ? row[5] == "1" : false,
                isNotNull: row.count > 3 ? row[3] == "1" : false,
                defaultValue: row.count > 4 && row[4] != "NULL" ? row[4] : nil
            )
        }
        let countResult = execute(db, sql: "SELECT COUNT(*) FROM '\(table)'")
        let rowCount = Int(countResult.rows.first?.first ?? "0") ?? 0
        return TableInfo(name: table, columnCount: columns.count, rowCount: rowCount, columns: columns)
    }

    // MARK: - Queries

    static func execute(_ db: OpaquePointer, sql: String) -> QueryResult {
        var stmt: OpaquePointer?
        let start = Date()
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt else {
            return QueryResult(columns: [], rows: [], rowCount: 0,
                             executionTime: Date().timeIntervalSince(start),
                             error: String(cString: sqlite3_errmsg(db)), affectedRows: 0)
        }
        defer { sqlite3_finalize(stmt) }

        let colCount = Int(sqlite3_column_count(stmt))
        let columns = (0..<colCount).map { String(cString: sqlite3_column_name(stmt, Int32($0))) }

        var rows: [[String]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let row = (0..<colCount).map { i -> String in
                if let text = sqlite3_column_text(stmt, Int32(i)) {
                    return String(cString: text)
                }
                return "NULL"
            }
            rows.append(row)
        }

        let elapsed = Date().timeIntervalSince(start)
        return QueryResult(columns: columns, rows: rows, rowCount: rows.count,
                          executionTime: elapsed, error: nil, affectedRows: Int(sqlite3_changes(db)))
    }

    static func preview(_ db: OpaquePointer, table: String, limit: Int = 100) -> QueryResult {
        return execute(db, sql: "SELECT * FROM '\(table)' LIMIT \(limit)")
    }

    // MARK: - Export

    static func exportCSV(_ result: QueryResult) -> String {
        var csv = result.columns.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        for row in result.rows {
            csv += row.map { escapeCSV($0) }.joined(separator: ",") + "\n"
        }
        return csv
    }

    static func exportJSON(_ result: QueryResult) -> String {
        var records: [[String: String]] = []
        for row in result.rows {
            var record: [String: String] = [:]
            for (i, col) in result.columns.enumerated() {
                record[col] = i < row.count ? row[i] : ""
            }
            records.append(record)
        }
        guard let data = try? JSONSerialization.data(withJSONObject: records, options: [.prettyPrinted, .sortedKeys]) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    static func exportInsertStatements(_ result: QueryResult, table: String) -> String {
        var sql = ""
        for row in result.rows {
            let values = row.map { "'\($0.replacingOccurrences(of: "'", with: "''"))'" }.joined(separator: ", ")
            sql += "INSERT INTO \(table) (\(result.columns.joined(separator: ", "))) VALUES (\(values));\n"
        }
        return sql
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

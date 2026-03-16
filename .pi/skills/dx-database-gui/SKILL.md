---
name: dx-database-gui
description: Build the Database GUI tool for DX Tools. A lightweight SQL client supporting SQLite (native), with query editor, table browser, result grid, and export. Uses pure Foundation/Swift — no external database drivers. Follow dx-tools-feature skill for architecture.
---

# Database GUI — Lightweight SQL Client

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `databaseGUI`
- **Category**: `.devops`
- **Display name**: "Database"
- **Icon**: `"cylinder.split.1x2"`
- **Description**: "Lightweight SQL client — browse tables, run queries, export results (SQLite)"

## Important: Zero External Dependencies

DX Tools has zero runtime dependencies. For the database client:

- **SQLite**: Use macOS built-in `libsqlite3` via Swift's C interop — `import SQLite3`
- Do NOT use GRDB, SQLite.swift, or any SPM packages
- PostgreSQL/MySQL support can be added later with raw socket protocol, but SQLite first

## Service: `DatabaseService.swift`

### Connection Model

```swift
struct DBConnection {
    var id: UUID
    var name: String           // User-friendly name
    var path: String           // File path for SQLite
    var type: DatabaseType     // .sqlite
}

enum DatabaseType: String, CaseIterable {
    case sqlite = "SQLite"
}
```

### Query Result Model

```swift
struct QueryResult {
    var columns: [String]
    var rows: [[String]]       // Each row is array of string values
    var rowCount: Int
    var executionTime: TimeInterval
    var error: String?
    var affectedRows: Int      // For INSERT/UPDATE/DELETE
}
```

### Table Info Model

```swift
struct TableInfo {
    var name: String
    var columnCount: Int
    var rowCount: Int
    var columns: [ColumnInfo]
}

struct ColumnInfo {
    var name: String
    var type: String           // TEXT, INTEGER, REAL, BLOB
    var isPrimaryKey: Bool
    var isNotNull: Bool
    var defaultValue: String?
}
```

### Methods

```swift
// Connection
static func connect(_ connection: DBConnection) -> Result<OpaquePointer, String>
static func disconnect(_ db: OpaquePointer)

// Schema
static func listTables(_ db: OpaquePointer) -> [String]
static func tableInfo(_ db: OpaquePointer, table: String) -> TableInfo
static func tableRowCount(_ db: OpaquePointer, table: String) -> Int

// Queries
static func execute(_ db: OpaquePointer, sql: String) -> QueryResult
static func preview(_ db: OpaquePointer, table: String, limit: Int) -> QueryResult

// Export
static func exportCSV(_ result: QueryResult) -> String
static func exportJSON(_ result: QueryResult) -> String
static func exportInsertStatements(_ result: QueryResult, table: String) -> String
```

### SQLite C Interop Pattern

```swift
import SQLite3

static func connect(_ connection: DBConnection) -> Result<OpaquePointer, String> {
    var db: OpaquePointer?
    let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
    let result = sqlite3_open_v2(connection.path, &db, flags, nil)
    if result == SQLITE_OK, let db = db {
        return .success(db)
    } else {
        let msg = db.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
        if let db = db { sqlite3_close(db) }
        return .failure(msg)
    }
}

static func execute(_ db: OpaquePointer, sql: String) -> QueryResult {
    var stmt: OpaquePointer?
    let start = Date()

    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt else {
        return QueryResult(columns: [], rows: [], rowCount: 0,
                          executionTime: 0, error: String(cString: sqlite3_errmsg(db)), affectedRows: 0)
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
```

## ViewModel: `DatabaseViewModel.swift`

```swift
@Observable
class DatabaseViewModel {
    var connections: [DatabaseService.DBConnection] = []
    var activeConnection: DatabaseService.DBConnection?
    var activeDB: OpaquePointer?
    var tables: [String] = []
    var selectedTable: String?
    var tableInfo: DatabaseService.TableInfo?
    var queryInput: String = ""
    var queryResult: DatabaseService.QueryResult?
    var isConnected: Bool = false
    var error: String?
    var previewResult: DatabaseService.QueryResult?

    // ... methods for connect, disconnect, runQuery, selectTable, export
}
```

## View: `DatabaseView.swift`

### Layout: Three-panel

```
┌──────────────────────────────────────────────────────────┐
│ ToolHeader: "Database"  [Connect SQLite] [Disconnect]    │
├────────┬─────────────────────────────────────────────────┤
│ TABLES │  Query Editor (CodeEditor, editable, sql)       │
│        │  [Run ▶] [Format] [Clear]  Execution: 0.023s   │
│ users  ├─────────────────────────────────────────────────┤
│ orders │  Results Grid                                   │
│ items  │  ┌─────┬──────────┬───────────┐                │
│        │  │ id  │ name     │ email     │                │
│        │  ├─────┼──────────┼───────────┤                │
│        │  │ 1   │ Alice    │ a@b.com   │                │
│        │  │ 2   │ Bob      │ b@b.com   │                │
│        │  └─────┴──────────┴───────────┘                │
│        │  42 rows · 0.023s  [CSV] [JSON] [SQL]          │
└────────┴─────────────────────────────────────────────────┘
```

**Left sidebar** (width ~160):
- Connection status indicator (green/red dot)
- Table list — click to preview (SELECT * LIMIT 100)
- Table info tooltip or expand (columns, types, row count)
- Right-click table → Copy name, Preview, Count rows

**Top right — Query editor:**
- `CodeEditor` (editable, language "sql") for writing queries
- Run button (⌘⏎), Format button (uses SQLFormatterService), Clear
- Execution time badge after query runs

**Bottom right — Results:**
- Scrollable data grid with column headers
- Column headers show type (from SQLite column affinity)
- Sort by clicking column headers
- Row count + execution time in footer
- Export buttons: CSV, JSON, INSERT statements
- Error display (red banner) when query fails

### Connect Flow

- "Connect" button opens file picker (`.sqlite`, `.db`, `.sqlite3`)
- Or drag & drop a `.db` file onto the tool
- Recent connections saved (UserDefaults)

### Query Shortcuts

- Sample queries button: `SELECT * FROM {table} LIMIT 100`, `SELECT COUNT(*) FROM {table}`
- ⌘⏎ to execute
- History of recent queries (reuse HistoryPanel pattern)

## project.yml Addition

SQLite3 needs to be linked:

```yaml
# In the DXTools target settings
settings:
  base:
    OTHER_LDFLAGS: ["-lsqlite3"]
```

## Tests: `DatabaseServiceTests.swift`

Use in-memory SQLite for tests (path ":memory:"):

- `testConnectInMemory` — connects successfully
- `testCreateTable` — CREATE TABLE executes without error
- `testInsertAndSelect` — INSERT then SELECT returns data
- `testColumnInfo` — tableInfo returns correct column names and types
- `testListTables` — lists created tables
- `testInvalidSQL` — returns error, doesn't crash
- `testRowCount` — correct count after inserts
- `testExportCSV` — proper CSV format with headers
- `testExportJSON` — valid JSON array
- `testExecutionTime` — executionTime > 0
- `testNullValues` — NULL displayed as "NULL"
- `testMultipleStatements` — handles semicolon-separated queries

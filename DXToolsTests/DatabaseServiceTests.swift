import XCTest
@testable import DX_Tools

final class DatabaseServiceTests: XCTestCase {
    private func createDB() -> OpaquePointer {
        guard case .success(let db) = DatabaseService.connectInMemory() else {
            fatalError("Failed to connect in-memory")
        }
        return db
    }

    func testConnectInMemory() {
        let result = DatabaseService.connectInMemory()
        switch result {
        case .success(let db):
            DatabaseService.disconnect(db)
        case .failure(let err):
            XCTFail("Failed: \(err.message)")
        }
    }

    func testCreateTable() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        let result = DatabaseService.execute(db, sql: "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
        XCTAssertNil(result.error)
    }

    func testInsertAndSelect() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        _ = DatabaseService.execute(db, sql: "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
        _ = DatabaseService.execute(db, sql: "INSERT INTO users (name) VALUES ('Alice')")
        _ = DatabaseService.execute(db, sql: "INSERT INTO users (name) VALUES ('Bob')")
        let result = DatabaseService.execute(db, sql: "SELECT * FROM users")
        XCTAssertEqual(result.rowCount, 2)
        XCTAssertEqual(result.columns, ["id", "name"])
        XCTAssertEqual(result.rows[0][1], "Alice")
        XCTAssertEqual(result.rows[1][1], "Bob")
    }

    func testColumnInfo() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        _ = DatabaseService.execute(db, sql: "CREATE TABLE items (id INTEGER PRIMARY KEY, price REAL NOT NULL, name TEXT DEFAULT 'unnamed')")
        let info = DatabaseService.tableInfo(db, table: "items")
        XCTAssertEqual(info.columns.count, 3)
        XCTAssertEqual(info.columns[0].name, "id")
        XCTAssertTrue(info.columns[0].isPrimaryKey)
        XCTAssertEqual(info.columns[1].type, "REAL")
        XCTAssertTrue(info.columns[1].isNotNull)
    }

    func testListTables() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        _ = DatabaseService.execute(db, sql: "CREATE TABLE alpha (id INTEGER)")
        _ = DatabaseService.execute(db, sql: "CREATE TABLE beta (id INTEGER)")
        let tables = DatabaseService.listTables(db)
        XCTAssertEqual(tables.count, 2)
        XCTAssertTrue(tables.contains("alpha"))
        XCTAssertTrue(tables.contains("beta"))
    }

    func testInvalidSQL() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        let result = DatabaseService.execute(db, sql: "SELCT * FROM nonexistent")
        XCTAssertNotNil(result.error)
    }

    func testRowCount() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        _ = DatabaseService.execute(db, sql: "CREATE TABLE t (x INTEGER)")
        _ = DatabaseService.execute(db, sql: "INSERT INTO t VALUES (1)")
        _ = DatabaseService.execute(db, sql: "INSERT INTO t VALUES (2)")
        _ = DatabaseService.execute(db, sql: "INSERT INTO t VALUES (3)")
        let info = DatabaseService.tableInfo(db, table: "t")
        XCTAssertEqual(info.rowCount, 3)
    }

    func testExportCSV() {
        let result = DatabaseService.QueryResult(columns: ["id", "name"], rows: [["1", "Alice"], ["2", "Bob"]], rowCount: 2, executionTime: 0.01, error: nil, affectedRows: 0)
        let csv = DatabaseService.exportCSV(result)
        XCTAssertTrue(csv.contains("id,name"))
        XCTAssertTrue(csv.contains("1,Alice"))
    }

    func testExportJSON() {
        let result = DatabaseService.QueryResult(columns: ["id", "name"], rows: [["1", "Alice"]], rowCount: 1, executionTime: 0.01, error: nil, affectedRows: 0)
        let json = DatabaseService.exportJSON(result)
        XCTAssertTrue(json.contains("Alice"))
        XCTAssertTrue(json.contains("id"))
    }

    func testExecutionTime() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        _ = DatabaseService.execute(db, sql: "CREATE TABLE t (x INTEGER)")
        let result = DatabaseService.execute(db, sql: "SELECT * FROM t")
        XCTAssertTrue(result.executionTime >= 0)
    }

    func testNullValues() {
        let db = createDB()
        defer { DatabaseService.disconnect(db) }
        _ = DatabaseService.execute(db, sql: "CREATE TABLE t (x TEXT)")
        _ = DatabaseService.execute(db, sql: "INSERT INTO t VALUES (NULL)")
        let result = DatabaseService.execute(db, sql: "SELECT * FROM t")
        XCTAssertEqual(result.rows[0][0], "NULL")
    }
}

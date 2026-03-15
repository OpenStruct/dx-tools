import XCTest
@testable import DX_Tools

final class SQLFormatterServiceTests: XCTestCase {
    func testFormatSelect() {
        let sql = "SELECT id, name FROM users WHERE active = 1"
        let result = SQLFormatterService.format(sql)
        XCTAssertTrue(result.contains("SELECT"))
        XCTAssertTrue(result.contains("FROM"))
        XCTAssertTrue(result.contains("WHERE"))
        XCTAssertTrue(result.contains("\n"))
    }

    func testFormatJoin() {
        let sql = "SELECT u.id FROM users u INNER JOIN orders o ON u.id = o.user_id"
        let result = SQLFormatterService.format(sql)
        XCTAssertTrue(result.contains("INNER JOIN"))
        XCTAssertTrue(result.contains("ON"))
    }

    func testMinify() {
        let sql = "SELECT\n  id,\n  name\nFROM\n  users"
        let result = SQLFormatterService.minify(sql)
        XCTAssertFalse(result.contains("\n"))
        XCTAssertTrue(result.contains("SELECT"))
    }

    func testFormatWithGroupBy() {
        let sql = "SELECT dept, COUNT(*) FROM employees GROUP BY dept HAVING COUNT(*) > 5 ORDER BY dept"
        let result = SQLFormatterService.format(sql)
        XCTAssertTrue(result.contains("GROUP BY"))
        XCTAssertTrue(result.contains("HAVING"))
        XCTAssertTrue(result.contains("ORDER BY"))
    }

    func testEmptyInput() {
        let result = SQLFormatterService.format("")
        XCTAssertTrue(result.isEmpty)
    }

    func testIndentStyles() {
        let sql = "SELECT id FROM users"
        let two = SQLFormatterService.format(sql, indent: .twoSpaces)
        let four = SQLFormatterService.format(sql, indent: .fourSpaces)
        XCTAssertTrue(two.contains("  "))
        XCTAssertTrue(four.contains("    "))
    }

    func testPreservesStrings() {
        let sql = "SELECT * FROM users WHERE name = 'John Doe'"
        let result = SQLFormatterService.format(sql)
        XCTAssertTrue(result.contains("'John Doe'"))
    }
}

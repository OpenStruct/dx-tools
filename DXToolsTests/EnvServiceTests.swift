import XCTest
@testable import DX_Tools

final class EnvServiceTests: XCTestCase {

    func testParseBasic() {
        let env = """
        DB_HOST=localhost
        DB_PORT=5432
        """
        let entries = EnvService.parse(env)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].key, "DB_HOST")
        XCTAssertEqual(entries[0].value, "localhost")
        XCTAssertEqual(entries[1].key, "DB_PORT")
        XCTAssertEqual(entries[1].value, "5432")
    }

    func testParseQuotedValues() {
        let env = """
        NAME="John Doe"
        PATH='some/path'
        """
        let entries = EnvService.parse(env)
        XCTAssertEqual(entries[0].value, "John Doe")
        XCTAssertEqual(entries[1].value, "some/path")
    }

    func testParseSkipsComments() {
        let env = """
        # This is a comment
        KEY=value
        # Another comment
        """
        let entries = EnvService.parse(env)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].key, "KEY")
    }

    func testParseSkipsEmptyLines() {
        let env = """
        A=1

        B=2

        """
        let entries = EnvService.parse(env)
        XCTAssertEqual(entries.count, 2)
    }

    func testSensitiveDetection() {
        let env = """
        API_KEY=secret123
        DB_PASSWORD=pass456
        SECRET_TOKEN=tok789
        NORMAL_VAR=hello
        AUTH_TOKEN=abc
        """
        let entries = EnvService.parse(env)
        XCTAssertTrue(entries[0].isSensitive) // API_KEY
        XCTAssertTrue(entries[1].isSensitive) // DB_PASSWORD
        XCTAssertTrue(entries[2].isSensitive) // SECRET_TOKEN
        XCTAssertFalse(entries[3].isSensitive) // NORMAL_VAR
        XCTAssertTrue(entries[4].isSensitive) // AUTH_TOKEN
    }

    func testMaskedValue() {
        let env = "API_KEY=my_secret_key_12345"
        let entry = EnvService.parse(env)[0]
        XCTAssertTrue(entry.isSensitive)
        let masked = entry.maskedValue
        XCTAssertTrue(masked.contains("•"))
        XCTAssertNotEqual(masked, entry.value)
    }

    func testDiff() {
        let base = """
        A=1
        B=2
        C=3
        """
        let compare = """
        A=1
        B=changed
        D=4
        """
        let diff = EnvService.diff(base: base, compare: compare)
        XCTAssertEqual(diff.same, 1) // A
        XCTAssertEqual(diff.changed.count, 1) // B
        XCTAssertEqual(diff.changed[0].key, "B")
        XCTAssertEqual(diff.changed[0].oldValue, "2")
        XCTAssertEqual(diff.changed[0].newValue, "changed")
        XCTAssertEqual(diff.removed.count, 1) // C
        XCTAssertEqual(diff.added.count, 1) // D
    }

    func testValidate() {
        let env = """
        A=1
        B=2
        EXTRA=3
        """
        let template = """
        A=
        B=
        REQUIRED=
        """
        let (missing, extra) = EnvService.validate(env: env, template: template)
        XCTAssertEqual(missing, ["REQUIRED"])
        XCTAssertEqual(extra, ["EXTRA"])
    }

    func testParseEmpty() {
        XCTAssertTrue(EnvService.parse("").isEmpty)
    }

    func testParseValueWithEquals() {
        let env = "URL=https://example.com?q=1&b=2"
        let entries = EnvService.parse(env)
        XCTAssertEqual(entries[0].key, "URL")
        XCTAssertEqual(entries[0].value, "https://example.com?q=1&b=2")
    }
}

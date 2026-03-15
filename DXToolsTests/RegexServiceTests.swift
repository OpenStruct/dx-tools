import XCTest
@testable import DX_Tools

final class RegexServiceTests: XCTestCase {

    func testSimpleMatch() {
        let result = try! RegexService.test(pattern: "hello", input: "hello world").get()
        XCTAssertEqual(result.matchCount, 1)
        XCTAssertEqual(result.matches[0].fullMatch, "hello")
    }

    func testMultipleMatches() {
        let result = try! RegexService.test(pattern: "\\d+", input: "abc 123 def 456").get()
        XCTAssertEqual(result.matchCount, 2)
        XCTAssertEqual(result.matches[0].fullMatch, "123")
        XCTAssertEqual(result.matches[1].fullMatch, "456")
    }

    func testCaptureGroups() {
        let result = try! RegexService.test(pattern: "(\\w+)@(\\w+)", input: "user@host").get()
        XCTAssertEqual(result.matchCount, 1)
        XCTAssertEqual(result.matches[0].groups.count, 2)
        XCTAssertEqual(result.matches[0].groups[0].value, "user")
        XCTAssertEqual(result.matches[0].groups[1].value, "host")
    }

    func testNoMatch() {
        let result = try! RegexService.test(pattern: "xyz", input: "hello").get()
        XCTAssertEqual(result.matchCount, 0)
    }

    func testCaseInsensitive() {
        var flags = RegexService.Flags()
        flags.caseInsensitive = true
        let result = try! RegexService.test(pattern: "hello", input: "HELLO", flags: flags).get()
        XCTAssertEqual(result.matchCount, 1)
    }

    func testMultiline() {
        var flags = RegexService.Flags()
        flags.multiline = true
        let result = try! RegexService.test(pattern: "^line", input: "line1\nline2", flags: flags).get()
        XCTAssertEqual(result.matchCount, 2)
    }

    func testInvalidRegex() {
        let result = RegexService.test(pattern: "[invalid", input: "test")
        guard case .failure = result else { return XCTFail("Invalid regex should fail") }
    }

    func testReplace() {
        let result = try! RegexService.replace(pattern: "\\d+", input: "abc 123 def", replacement: "NUM").get()
        XCTAssertEqual(result, "abc NUM def")
    }

    func testReplaceAll() {
        let result = try! RegexService.replace(pattern: "\\d+", input: "a1 b2 c3", replacement: "X").get()
        XCTAssertEqual(result, "aX bX cX")
    }

    func testNonGlobalFirstOnly() {
        var flags = RegexService.Flags()
        flags.global = false
        let result = try! RegexService.test(pattern: "\\d+", input: "1 2 3", flags: flags).get()
        XCTAssertEqual(result.matchCount, 1)
    }

    func testExecutionTimeTracked() {
        let result = try! RegexService.test(pattern: ".", input: "test").get()
        XCTAssertGreaterThanOrEqual(result.executionTime, 0)
    }

    func testEmailPattern() {
        let pattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}"
        let result = try! RegexService.test(pattern: pattern, input: "contact user@test.com for info").get()
        XCTAssertEqual(result.matchCount, 1)
        XCTAssertEqual(result.matches[0].fullMatch, "user@test.com")
    }
}

import XCTest
@testable import DX_Tools

final class TextDiffServiceTests: XCTestCase {
    func testIdenticalTexts() {
        let r = TextDiffService.diff(left: "hello\nworld", right: "hello\nworld")
        XCTAssertEqual(r.stats.additions, 0)
        XCTAssertEqual(r.stats.deletions, 0)
        XCTAssertEqual(r.stats.unchanged, 2)
    }

    func testAddedLine() {
        let r = TextDiffService.diff(left: "a\nb", right: "a\nb\nc")
        XCTAssertEqual(r.stats.additions, 1)
        XCTAssertEqual(r.stats.deletions, 0)
    }

    func testRemovedLine() {
        let r = TextDiffService.diff(left: "a\nb\nc", right: "a\nc")
        XCTAssertEqual(r.stats.deletions, 1)
    }

    func testChangedLine() {
        let r = TextDiffService.diff(left: "a\nb\nc", right: "a\nB\nc")
        XCTAssertGreaterThan(r.stats.additions + r.stats.deletions, 0)
    }

    func testEmptyLeft() {
        let r = TextDiffService.diff(left: "", right: "hello")
        XCTAssertEqual(r.stats.additions, 1)
    }

    func testEmptyRight() {
        let r = TextDiffService.diff(left: "hello", right: "")
        XCTAssertEqual(r.stats.deletions, 1)
    }

    func testBothEmpty() {
        let r = TextDiffService.diff(left: "", right: "")
        XCTAssertEqual(r.stats.unchanged, 1) // single empty line
    }

    func testUnifiedDiff() {
        let u = TextDiffService.unifiedDiff(left: "a\nb", right: "a\nc")
        XCTAssertTrue(u.contains("---"))
        XCTAssertTrue(u.contains("+++"))
    }
}

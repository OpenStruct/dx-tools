import XCTest
@testable import DX_Tools

final class CronServiceTests: XCTestCase {
    func testEveryMinute() {
        let r = CronService.parse("* * * * *")
        XCTAssertTrue(r.isValid)
        XCTAssertTrue(r.description.lowercased().contains("every minute"))
        XCTAssertEqual(r.parts.count, 5)
    }
    func testEvery5Minutes() {
        let r = CronService.parse("*/5 * * * *")
        XCTAssertTrue(r.isValid)
        XCTAssertTrue(r.description.contains("5 minutes"))
    }
    func testDailyAtMidnight() {
        let r = CronService.parse("0 0 * * *")
        XCTAssertTrue(r.isValid)
        XCTAssertTrue(r.description.contains("12:00 AM"))
    }
    func testWeekdaysAt9() {
        let r = CronService.parse("0 9 * * 1-5")
        XCTAssertTrue(r.isValid)
        XCTAssertTrue(r.description.contains("9:00 AM"))
        XCTAssertTrue(r.description.contains("Monday") || r.description.contains("Friday"))
    }
    func testInvalidFieldCount() {
        let r = CronService.parse("* * *")
        XCTAssertFalse(r.isValid)
        XCTAssertNotNil(r.error)
    }
    func testNextRuns() {
        let r = CronService.parse("* * * * *")
        XCTAssertEqual(r.nextRuns.count, 10)
        // Each run should be 1 minute apart
        if r.nextRuns.count >= 2 {
            let diff = r.nextRuns[1].timeIntervalSince(r.nextRuns[0])
            XCTAssertEqual(diff, 60, accuracy: 1)
        }
    }
    func testFieldParts() {
        let r = CronService.parse("30 2 * * 0")
        XCTAssertEqual(r.parts[0].value, "30")
        XCTAssertEqual(r.parts[0].field, "Minute")
        XCTAssertEqual(r.parts[1].value, "2")
        XCTAssertEqual(r.parts[1].field, "Hour")
    }
    func testCommaValues() {
        let r = CronService.parse("0 9,17 * * *")
        XCTAssertTrue(r.isValid)
        XCTAssertTrue(r.parts[1].meaning.contains("9,17"))
    }
    func testMonthlyFirst() {
        let r = CronService.parse("0 0 1 * *")
        XCTAssertTrue(r.isValid)
        XCTAssertTrue(r.description.contains("day 1"))
    }
    func testExamples() {
        for ex in CronService.examples {
            let r = CronService.parse(ex.expression)
            XCTAssertTrue(r.isValid, "Example '\(ex.expression)' should be valid")
        }
    }
}

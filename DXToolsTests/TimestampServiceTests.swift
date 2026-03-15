import XCTest
@testable import DX_Tools

final class TimestampServiceTests: XCTestCase {
    func testEpochSeconds() {
        let r = TimestampService.convert(from: "1700000000")
        XCTAssertNotNil(r)
        XCTAssertEqual(r?.epoch, 1700000000)
        XCTAssertTrue(r?.iso8601.contains("2023") ?? false)
    }

    func testEpochMilliseconds() {
        let r = TimestampService.convert(from: "1700000000000")
        XCTAssertNotNil(r)
        XCTAssertEqual(r?.epoch, 1700000000)
    }

    func testISO8601() {
        let r = TimestampService.convert(from: "2023-11-14T22:13:20Z")
        XCTAssertNotNil(r)
        XCTAssertEqual(r?.epoch, 1700000000)
    }

    func testDateString() {
        let r = TimestampService.convert(from: "2023-11-14")
        XCTAssertNotNil(r)
        XCTAssertTrue(r?.iso8601.contains("2023-11-14") ?? false)
    }

    func testNow() {
        let r = TimestampService.now()
        XCTAssertGreaterThan(r.epoch, 1700000000)
        XCTAssertFalse(r.iso8601.isEmpty)
        XCTAssertFalse(r.rfc2822.isEmpty)
        XCTAssertFalse(r.dayOfWeek.isEmpty)
    }

    func testInvalidInput() {
        let r = TimestampService.convert(from: "not a date")
        XCTAssertNil(r)
    }

    func testEmptyInput() {
        let r = TimestampService.convert(from: "")
        XCTAssertNil(r)
    }

    func testLeapYear() {
        let r = TimestampService.convert(from: "2024-06-15")
        XCTAssertNotNil(r)
        XCTAssertTrue(r?.isLeapYear ?? false)
    }

    func testNonLeapYear() {
        let r = TimestampService.convert(from: "2023-06-15")
        XCTAssertNotNil(r)
        XCTAssertFalse(r?.isLeapYear ?? true)
    }
}

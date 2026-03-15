import XCTest
@testable import DX_Tools

final class EpochServiceTests: XCTestCase {

    func testNow() {
        let info = EpochService.now()
        let currentEpoch = Int(Date().timeIntervalSince1970)
        XCTAssertEqual(info.epochSeconds, currentEpoch, accuracy: 2)
        XCTAssertEqual(info.epochMilliseconds, currentEpoch * 1000, accuracy: 2000)
        XCTAssertFalse(info.iso8601.isEmpty)
        XCTAssertFalse(info.local.isEmpty)
        XCTAssertTrue(info.utc.hasSuffix("UTC"))
    }

    func testFromEpochSeconds() {
        let info = EpochService.fromEpoch(0)
        XCTAssertEqual(info.epochSeconds, 0)
        XCTAssertTrue(info.utc.contains("1970"))
    }

    func testFromEpochMilliseconds() {
        // 1000000000000 ms = 1000000000 seconds
        let info = EpochService.fromEpoch(1000000000000)
        XCTAssertEqual(info.epochSeconds, 1000000000)
    }

    func testFromEpochAutoDetectsMilliseconds() {
        let infoSec = EpochService.fromEpoch(1700000000)
        let infoMs = EpochService.fromEpoch(1700000000000)
        XCTAssertEqual(infoSec.epochSeconds, infoMs.epochSeconds)
    }

    func testWorldClocks() {
        let info = EpochService.now()
        XCTAssertEqual(info.worldClocks.count, 8)
        XCTAssertTrue(info.worldClocks.contains { $0.name.contains("Tokyo") })
        XCTAssertTrue(info.worldClocks.contains { $0.name.contains("London") })
        XCTAssertTrue(info.worldClocks.contains { $0.name.contains("New York") })
    }

    func testFromDate() {
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let info = EpochService.fromDate(date)
        XCTAssertEqual(info.epochSeconds, 1609459200)
        XCTAssertTrue(info.utc.contains("2021"))
        XCTAssertTrue(info.iso8601.contains("2021"))
    }

    func testParseISO8601() {
        let date = EpochService.parseDate("2021-01-01T00:00:00Z")
        XCTAssertNotNil(date)
        XCTAssertEqual(Int(date!.timeIntervalSince1970), 1609459200)
    }

    func testParseDateFormats() {
        XCTAssertNotNil(EpochService.parseDate("2021-01-01 00:00:00"))
        XCTAssertNotNil(EpochService.parseDate("2021-01-01 00:00"))
        XCTAssertNotNil(EpochService.parseDate("2021-01-01"))
        XCTAssertNotNil(EpochService.parseDate("01/01/2021"))
    }

    func testParseInvalidDate() {
        XCTAssertNil(EpochService.parseDate("not a date"))
        XCTAssertNil(EpochService.parseDate(""))
    }

    func testRelativeTime() {
        let info = EpochService.fromEpoch(0)
        XCTAssertFalse(info.relative.isEmpty)
    }
}

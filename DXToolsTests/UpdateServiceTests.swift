import XCTest
@testable import DX_Tools

final class UpdateServiceTests: XCTestCase {
    func testNewerMajor() {
        XCTAssertTrue(UpdateService.isNewer("3.0.0", than: "2.0.0"))
    }

    func testNewerMinor() {
        XCTAssertTrue(UpdateService.isNewer("2.1.0", than: "2.0.0"))
    }

    func testNewerPatch() {
        XCTAssertTrue(UpdateService.isNewer("2.0.1", than: "2.0.0"))
    }

    func testSameVersion() {
        XCTAssertFalse(UpdateService.isNewer("2.0.0", than: "2.0.0"))
    }

    func testOlderVersion() {
        XCTAssertFalse(UpdateService.isNewer("1.9.0", than: "2.0.0"))
    }

    func testDifferentLengths() {
        XCTAssertTrue(UpdateService.isNewer("2.1", than: "2.0.0"))
        XCTAssertFalse(UpdateService.isNewer("2.0", than: "2.0.1"))
    }

    func testCurrentVersionExists() {
        // Should return a valid version string
        let v = UpdateService.currentVersion
        XCTAssertFalse(v.isEmpty)
    }
}

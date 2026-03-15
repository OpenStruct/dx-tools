import XCTest
@testable import DX_Tools

final class HTTPStatusServiceTests: XCTestCase {
    func testAllCodesExist() {
        XCTAssertGreaterThan(HTTPStatusService.allCodes.count, 30)
    }

    func testSearchByCode() {
        let results = HTTPStatusService.search("404")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Not Found")
    }

    func testSearchByName() {
        let results = HTTPStatusService.search("teapot")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.code, 418)
    }

    func testSearchEmpty() {
        let results = HTTPStatusService.search("")
        XCTAssertEqual(results.count, HTTPStatusService.allCodes.count)
    }

    func testSearchNoResults() {
        let results = HTTPStatusService.search("999")
        XCTAssertTrue(results.isEmpty)
    }

    func testCategories() {
        let codes = HTTPStatusService.allCodes
        XCTAssertTrue(codes.contains { $0.category == .info })
        XCTAssertTrue(codes.contains { $0.category == .success })
        XCTAssertTrue(codes.contains { $0.category == .redirect })
        XCTAssertTrue(codes.contains { $0.category == .clientError })
        XCTAssertTrue(codes.contains { $0.category == .serverError })
    }
}

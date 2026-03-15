import XCTest
@testable import DX_Tools

final class JSONDiffServiceTests: XCTestCase {

    func testSameJSON() {
        let json = #"{"name":"John","age":30}"#
        let result = try! JSONDiffService.diff(left: json, right: json).get()
        let changed = result.filter { $0.type == .changed }
        XCTAssertEqual(changed.count, 0)
        let same = result.filter { $0.type == .same }
        XCTAssertEqual(same.count, 2)
    }

    func testAddedKey() {
        let left = #"{"a":1}"#
        let right = #"{"a":1,"b":2}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let added = result.filter { $0.type == .added }
        XCTAssertEqual(added.count, 1)
        XCTAssertEqual(added[0].path, "$.b")
    }

    func testRemovedKey() {
        let left = #"{"a":1,"b":2}"#
        let right = #"{"a":1}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let removed = result.filter { $0.type == .removed }
        XCTAssertEqual(removed.count, 1)
        XCTAssertEqual(removed[0].path, "$.b")
    }

    func testChangedValue() {
        let left = #"{"name":"John"}"#
        let right = #"{"name":"Jane"}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let changed = result.filter { $0.type == .changed }
        XCTAssertEqual(changed.count, 1)
        XCTAssertEqual(changed[0].oldValue, "\"John\"")
        XCTAssertEqual(changed[0].newValue, "\"Jane\"")
    }

    func testNestedDiff() {
        let left = #"{"user":{"name":"John","age":30}}"#
        let right = #"{"user":{"name":"Jane","age":30}}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let changed = result.filter { $0.type == .changed }
        XCTAssertEqual(changed.count, 1)
        XCTAssertEqual(changed[0].path, "$.user.name")
    }

    func testArrayDiff() {
        let left = #"{"items":[1,2,3]}"#
        let right = #"{"items":[1,2,4]}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let changed = result.filter { $0.type == .changed }
        XCTAssertEqual(changed.count, 1)
        XCTAssertTrue(changed[0].path.contains("[2]"))
    }

    func testArrayLengthDiff() {
        let left = #"{"items":[1,2]}"#
        let right = #"{"items":[1,2,3]}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let added = result.filter { $0.type == .added }
        XCTAssertEqual(added.count, 1)
    }

    func testInvalidLeftJSON() {
        let result = JSONDiffService.diff(left: "not json", right: "{}")
        guard case .failure = result else { return XCTFail() }
    }

    func testInvalidRightJSON() {
        let result = JSONDiffService.diff(left: "{}", right: "not json")
        guard case .failure = result else { return XCTFail() }
    }

    func testBooleanDiff() {
        let left = #"{"active":true}"#
        let right = #"{"active":false}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let changed = result.filter { $0.type == .changed }
        XCTAssertEqual(changed.count, 1)
        XCTAssertEqual(changed[0].oldValue, "true")
        XCTAssertEqual(changed[0].newValue, "false")
    }

    func testDepthTracked() {
        let left = #"{"a":{"b":{"c":1}}}"#
        let right = #"{"a":{"b":{"c":2}}}"#
        let result = try! JSONDiffService.diff(left: left, right: right).get()
        let changed = result.filter { $0.type == .changed }
        XCTAssertEqual(changed[0].depth, 3)
    }
}

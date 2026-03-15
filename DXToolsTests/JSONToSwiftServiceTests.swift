import XCTest
@testable import DX_Tools

final class JSONToSwiftServiceTests: XCTestCase {

    func testSimpleObject() {
        let json = #"{"name":"John","age":30,"active":true}"#
        let result = try! JSONToSwiftService.convert(json).get()
        XCTAssertTrue(result.contains("struct Root: Codable"))
        XCTAssertTrue(result.contains("let active: Bool"))
        XCTAssertTrue(result.contains("let name: String"))
        XCTAssertTrue(result.contains("let age: Int"))
    }

    func testNestedObject() {
        let json = #"{"user":{"name":"John"}}"#
        let result = try! JSONToSwiftService.convert(json).get()
        XCTAssertTrue(result.contains("struct User: Codable"))
        XCTAssertTrue(result.contains("let user: User"))
    }

    func testArray() {
        let json = #"{"users":[{"name":"A"},{"name":"B"}]}"#
        let result = try! JSONToSwiftService.convert(json).get()
        XCTAssertTrue(result.contains("[User]"))
        XCTAssertTrue(result.contains("struct User: Codable"))
    }

    func testNullBecomesOptional() {
        let json = #"{"value":null}"#
        let result = try! JSONToSwiftService.convert(json).get()
        XCTAssertTrue(result.contains("Any?"))
    }

    func testFloat() {
        let json = #"{"price":9.99}"#
        let result = try! JSONToSwiftService.convert(json).get()
        XCTAssertTrue(result.contains("Double"))
    }

    func testCustomRootName() {
        let json = #"{"name":"test"}"#
        let options = JSONToSwiftService.Options(rootName: "APIResponse")
        let result = try! JSONToSwiftService.convert(json, options: options).get()
        XCTAssertTrue(result.contains("struct APIResponse"))
    }

    func testVarProperties() {
        let json = #"{"name":"test"}"#
        let options = JSONToSwiftService.Options(useLetProperties: false)
        let result = try! JSONToSwiftService.convert(json, options: options).get()
        XCTAssertTrue(result.contains("var name: String"))
    }

    func testCodingKeys() {
        let json = #"{"user_name":"test"}"#
        let options = JSONToSwiftService.Options(addCodingKeys: true)
        let result = try! JSONToSwiftService.convert(json, options: options).get()
        XCTAssertTrue(result.contains("CodingKeys"))
        XCTAssertTrue(result.contains("case userName = \"user_name\""))
    }

    func testInvalidJSON() {
        let result = JSONToSwiftService.convert("not json")
        guard case .failure = result else { return XCTFail() }
    }

    func testImportFoundation() {
        let json = #"{"a":1}"#
        let result = try! JSONToSwiftService.convert(json).get()
        XCTAssertTrue(result.hasPrefix("import Foundation"))
    }
}

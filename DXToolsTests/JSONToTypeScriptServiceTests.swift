import XCTest
@testable import DX_Tools

final class JSONToTypeScriptServiceTests: XCTestCase {

    func testSimpleObject() {
        let json = #"{"name":"John","age":30,"active":true}"#
        let result = try! JSONToTypeScriptService.convert(json).get()
        XCTAssertTrue(result.contains("export interface Root"))
        XCTAssertTrue(result.contains("active: boolean"))
        XCTAssertTrue(result.contains("name: string"))
        XCTAssertTrue(result.contains("age: number"))
    }

    func testNestedObject() {
        let json = #"{"user":{"name":"John"}}"#
        let result = try! JSONToTypeScriptService.convert(json).get()
        XCTAssertTrue(result.contains("interface User"))
        XCTAssertTrue(result.contains("user: User"))
    }

    func testArray() {
        let json = #"{"users":[{"name":"A"}]}"#
        let result = try! JSONToTypeScriptService.convert(json).get()
        XCTAssertTrue(result.contains("User[]"))
    }

    func testTypeAlias() {
        let json = #"{"name":"test"}"#
        let options = JSONToTypeScriptService.Options(useInterface: false)
        let result = try! JSONToTypeScriptService.convert(json, options: options).get()
        XCTAssertTrue(result.contains("export type Root"))
    }

    func testReadonly() {
        let json = #"{"name":"test"}"#
        let options = JSONToTypeScriptService.Options(readOnly: true)
        let result = try! JSONToTypeScriptService.convert(json, options: options).get()
        XCTAssertTrue(result.contains("readonly name"))
    }

    func testNullable() {
        let json = #"{"value":null}"#
        let result = try! JSONToTypeScriptService.convert(json).get()
        XCTAssertTrue(result.contains("null"))
    }

    func testPrimitiveArray() {
        let json = #"{"tags":["a","b"]}"#
        let result = try! JSONToTypeScriptService.convert(json).get()
        XCTAssertTrue(result.contains("string[]"))
    }

    func testInvalidJSON() {
        let result = JSONToTypeScriptService.convert("nope")
        guard case .failure = result else { return XCTFail() }
    }
}

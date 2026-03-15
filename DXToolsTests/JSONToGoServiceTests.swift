import XCTest
@testable import DX_Tools

final class JSONToGoServiceTests: XCTestCase {

    func testSimpleObject() {
        let json = #"{"name":"John","age":30,"active":true}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("type Root struct"))
        XCTAssertTrue(result.contains("Active"))
        XCTAssertTrue(result.contains("bool"))
        XCTAssertTrue(result.contains("Name"))
        XCTAssertTrue(result.contains("string"))
        XCTAssertTrue(result.contains("Age"))
        XCTAssertTrue(result.contains("int64"))
    }

    func testNestedObject() {
        let json = #"{"user":{"name":"John","email":"john@test.com"}}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("type Root struct"))
        XCTAssertTrue(result.contains("type User struct"))
    }

    func testArray() {
        let json = #"{"items":[{"id":1,"name":"A"},{"id":2,"name":"B"}]}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("[]Item"))
        XCTAssertTrue(result.contains("type Item struct"))
    }

    func testCustomRootName() {
        let json = #"{"name":"test"}"#
        let options = JSONToGoService.Options(rootName: "MyStruct")
        let result = try! JSONToGoService.convert(json, options: options).get()
        XCTAssertTrue(result.contains("type MyStruct struct"))
    }

    func testJSONTags() {
        let json = #"{"user_name":"John"}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("`json:\"user_name\"`"))
    }

    func testFieldNaming() {
        XCTAssertEqual(JSONToGoService.goFieldName("user_name"), "UserName")
        XCTAssertEqual(JSONToGoService.goFieldName("id"), "ID")
        XCTAssertEqual(JSONToGoService.goFieldName("api_url"), "APIURL")
        XCTAssertEqual(JSONToGoService.goFieldName("http_method"), "HTTPMethod")
        XCTAssertEqual(JSONToGoService.goFieldName("created_at"), "CreatedAt")
    }

    func testFloatType() {
        let json = #"{"price":9.99}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("float64"))
    }

    func testNullValue() {
        let json = #"{"value":null}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("interface{}"))
    }

    func testInvalidJSON() {
        let result = JSONToGoService.convert("not json")
        guard case .failure = result else { return XCTFail() }
    }

    func testEmptyObject() {
        let json = "{}"
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("type Root struct"))
    }

    func testPrimitiveArray() {
        let json = #"{"tags":["a","b","c"]}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("[]string"))
    }

    func testBooleanArray() {
        let json = #"{"flags":[true,false,true]}"#
        let result = try! JSONToGoService.convert(json).get()
        XCTAssertTrue(result.contains("[]bool"))
    }
}

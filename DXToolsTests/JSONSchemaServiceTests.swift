import XCTest
@testable import DX_Tools

final class JSONSchemaServiceTests: XCTestCase {
    func testValidObject() {
        let json = """
        {"name": "Alice", "age": 30}
        """
        let schema = """
        {"type": "object", "required": ["name", "age"], "properties": {"name": {"type": "string"}, "age": {"type": "integer"}}}
        """
        let result = JSONSchemaService.validate(json: json, against: schema)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testMissingRequired() {
        let json = """
        {"name": "Alice"}
        """
        let schema = """
        {"type": "object", "required": ["name", "age"]}
        """
        let result = JSONSchemaService.validate(json: json, against: schema)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("age") })
    }

    func testWrongType() {
        let json = """
        {"name": 123}
        """
        let schema = """
        {"type": "object", "properties": {"name": {"type": "string"}}}
        """
        let result = JSONSchemaService.validate(json: json, against: schema)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.errors.contains { $0.contains("string") })
    }

    func testMinLength() {
        let json = """
        {"name": ""}
        """
        let schema = """
        {"type": "object", "properties": {"name": {"type": "string", "minLength": 1}}}
        """
        let result = JSONSchemaService.validate(json: json, against: schema)
        XCTAssertFalse(result.isValid)
    }

    func testNumberRange() {
        let json = """
        {"age": 200}
        """
        let schema = """
        {"type": "object", "properties": {"age": {"type": "integer", "maximum": 150}}}
        """
        let result = JSONSchemaService.validate(json: json, against: schema)
        XCTAssertFalse(result.isValid)
    }

    func testArrayValidation() {
        let json = """
        {"tags": ["a", 123]}
        """
        let schema = """
        {"type": "object", "properties": {"tags": {"type": "array", "items": {"type": "string"}}}}
        """
        let result = JSONSchemaService.validate(json: json, against: schema)
        XCTAssertFalse(result.isValid)
    }

    func testInvalidJSON() {
        let result = JSONSchemaService.validate(json: "{bad", against: "{}")
        XCTAssertFalse(result.isValid)
    }

    func testInvalidSchema() {
        let result = JSONSchemaService.validate(json: "{}", against: "not json")
        XCTAssertFalse(result.isValid)
    }
}

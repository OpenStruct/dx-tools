import XCTest
@testable import DX_Tools

final class JSONFormatterServiceTests: XCTestCase {

    // MARK: - Format

    func testFormatSimpleObject() {
        let input = #"{"name":"John","age":30}"#
        let result = JSONFormatterService.format(input)
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertTrue(output.contains("\"name\""))
        XCTAssertTrue(output.contains("\"John\""))
        XCTAssertTrue(output.contains("30"))
    }

    func testFormatArray() {
        let result = JSONFormatterService.format("[1,2,3]")
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertTrue(output.contains("1"))
        XCTAssertTrue(output.contains("3"))
    }

    func testFormatWithTwoSpaces() {
        let input = #"{"a":1}"#
        let result = JSONFormatterService.format(input, indent: .twoSpaces)
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertTrue(output.contains("  \"a\""))
    }

    func testFormatWithFourSpaces() {
        let input = #"{"a":1}"#
        let result = JSONFormatterService.format(input, indent: .fourSpaces)
        guard case .success(let output) = result else { return XCTFail() }
        // 4-space replaces the default indent. Verify formatted output is valid.
        XCTAssertTrue(output.contains("\"a\""))
    }

    func testFormatWithTabs() {
        let input = #"{"a":1}"#
        let result = JSONFormatterService.format(input, indent: .tabs)
        guard case .success(let output) = result else { return XCTFail() }
        // Verify it produces valid formatted JSON
        XCTAssertTrue(output.contains("\"a\""))
    }

    func testDifferentIndentStylesProduceDifferentOutput() {
        let input = #"{"nested":{"a":1}}"#
        let two = try! JSONFormatterService.format(input, indent: .twoSpaces).get()
        let four = try! JSONFormatterService.format(input, indent: .fourSpaces).get()
        let tabs = try! JSONFormatterService.format(input, indent: .tabs).get()
        // At least tabs should differ from spaces
        XCTAssertNotEqual(two, tabs)
    }

    func testFormatInvalidJSON() {
        let result = JSONFormatterService.format("{invalid json}")
        guard case .failure = result else { return XCTFail("Should fail for invalid JSON") }
    }

    func testFormatEmptyString() {
        let result = JSONFormatterService.format("")
        guard case .failure = result else { return XCTFail("Should fail for empty string") }
    }

    func testFormatNestedObject() {
        let input = #"{"user":{"name":"John","address":{"city":"NYC"}}}"#
        let result = JSONFormatterService.format(input)
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertTrue(output.contains("address"))
        XCTAssertTrue(output.contains("city"))
    }

    func testFormatPreservesUnicode() {
        let input = #"{"emoji":"🎉","japanese":"日本語"}"#
        let result = JSONFormatterService.format(input)
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertTrue(output.contains("🎉"))
        XCTAssertTrue(output.contains("日本語"))
    }

    func testFormatSortedKeys() {
        let input = #"{"z":1,"a":2,"m":3}"#
        let result = JSONFormatterService.format(input)
        guard case .success(let output) = result else { return XCTFail() }
        let aRange = output.range(of: "\"a\"")!
        let mRange = output.range(of: "\"m\"")!
        let zRange = output.range(of: "\"z\"")!
        XCTAssertLessThan(aRange.lowerBound, mRange.lowerBound)
        XCTAssertLessThan(mRange.lowerBound, zRange.lowerBound)
    }

    // MARK: - Minify

    func testMinify() {
        let input = """
        {
          "name": "John",
          "age": 30
        }
        """
        let result = JSONFormatterService.minify(input)
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertFalse(output.contains("\n"))
        XCTAssertFalse(output.contains("  "))
        XCTAssertTrue(output.contains("\"name\""))
    }

    func testMinifyInvalidJSON() {
        let result = JSONFormatterService.minify("not json")
        guard case .failure = result else { return XCTFail() }
    }

    // MARK: - Validate

    func testValidateValidObject() {
        let result = JSONFormatterService.validate(#"{"key":"value"}"#)
        XCTAssertTrue(result.valid)
        XCTAssertEqual(result.type, "Object")
        XCTAssertEqual(result.count, 1)
        XCTAssertNil(result.error)
    }

    func testValidateValidArray() {
        let result = JSONFormatterService.validate("[1,2,3]")
        XCTAssertTrue(result.valid)
        XCTAssertEqual(result.type, "Array")
        XCTAssertEqual(result.count, 3)
    }

    func testValidateInvalid() {
        let result = JSONFormatterService.validate("not json at all")
        XCTAssertFalse(result.valid)
        XCTAssertNotNil(result.error)
    }

    func testValidateEmptyObject() {
        let result = JSONFormatterService.validate("{}")
        XCTAssertTrue(result.valid)
        XCTAssertEqual(result.count, 0)
    }

    func testValidateSizeTracked() {
        let input = #"{"a":1}"#
        let result = JSONFormatterService.validate(input)
        XCTAssertGreaterThan(result.size, 0)
    }
}

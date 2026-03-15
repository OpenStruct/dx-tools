import XCTest
@testable import DX_Tools

final class URLCoderServiceTests: XCTestCase {
    func testEncode() {
        XCTAssertEqual(URLCoderService.encode("hello world"), "hello%20world")
    }
    func testEncodeSpecial() {
        let encoded = URLCoderService.encode("a=1&b=2")
        XCTAssertTrue(encoded.contains("%"))
    }
    func testDecode() {
        XCTAssertEqual(URLCoderService.decode("hello%20world"), "hello world")
    }
    func testDecodeAlreadyDecoded() {
        XCTAssertEqual(URLCoderService.decode("hello"), "hello")
    }
    func testRoundTrip() {
        let input = "key=hello world&foo=bar baz"
        XCTAssertEqual(URLCoderService.decode(URLCoderService.encode(input)), input)
    }
    func testDecomposeURL() {
        let parts = URLCoderService.decompose("https://example.com:8080/path?q=test&page=1#section")!
        XCTAssertEqual(parts.scheme, "https")
        XCTAssertEqual(parts.host, "example.com")
        XCTAssertEqual(parts.port, "8080")
        XCTAssertEqual(parts.path, "/path")
        XCTAssertEqual(parts.query.count, 2)
        XCTAssertEqual(parts.query[1].name, "page")
        XCTAssertEqual(parts.fragment, "section")
    }
    func testDecomposeSimple() {
        let parts = URLCoderService.decompose("example.com")!
        XCTAssertEqual(parts.host, "example.com")
    }
    func testDecomposeInvalid() {
        // Should handle gracefully
        let _ = URLCoderService.decompose("")
    }
}

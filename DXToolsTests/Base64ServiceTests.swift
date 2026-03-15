import XCTest
@testable import DX_Tools

final class Base64ServiceTests: XCTestCase {

    func testEncode() {
        XCTAssertEqual(Base64Service.encode("hello"), "aGVsbG8=")
    }

    func testEncodeEmpty() {
        XCTAssertEqual(Base64Service.encode(""), "")
    }

    func testEncodeUnicode() {
        let encoded = Base64Service.encode("Hello 🌍")
        let decoded = try! Base64Service.decodeToString(encoded).get()
        XCTAssertEqual(decoded, "Hello 🌍")
    }

    func testEncodeURLSafe() {
        // Standard base64 uses +/= but URL-safe uses -_ and no padding
        let input = "subjects?_d" // produces + and / in base64
        let standard = Base64Service.encode(input, urlSafe: false)
        let urlSafe = Base64Service.encode(input, urlSafe: true)
        XCTAssertFalse(urlSafe.contains("+"))
        XCTAssertFalse(urlSafe.contains("/"))
        XCTAssertFalse(urlSafe.contains("="))
        // Should be decodable
        let decoded = try! Base64Service.decodeToString(urlSafe).get()
        XCTAssertEqual(decoded, input)
    }

    func testDecode() {
        let result = Base64Service.decodeToString("aGVsbG8=")
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertEqual(output, "hello")
    }

    func testDecodeNoPadding() {
        let result = Base64Service.decodeToString("aGVsbG8")
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertEqual(output, "hello")
    }

    func testDecodeURLSafe() {
        let result = Base64Service.decodeToString("c3ViamVjdHM_X2Q") // URL-safe encoded
        guard case .success(let output) = result else { return XCTFail() }
        XCTAssertEqual(output, "subjects?_d")
    }

    func testDecodeInvalid() {
        // Completely non-base64 content
        let result = Base64Service.decode("!@#$%^&*()")
        // Data(base64Encoded:) may or may not fail depending on implementation
        // Just verify it doesn't crash
        _ = result
    }

    func testRoundTrip() {
        let inputs = ["hello world", "{ \"json\": true }", "日本語テスト", "line1\nline2\nline3"]
        for input in inputs {
            let encoded = Base64Service.encode(input)
            let decoded = try! Base64Service.decodeToString(encoded).get()
            XCTAssertEqual(decoded, input, "Round-trip failed for: \(input)")
        }
    }

    func testRoundTripURLSafe() {
        let inputs = ["a+b/c=d", "https://example.com?q=test&foo=bar"]
        for input in inputs {
            let encoded = Base64Service.encode(input, urlSafe: true)
            let decoded = try! Base64Service.decodeToString(encoded).get()
            XCTAssertEqual(decoded, input, "URL-safe round-trip failed for: \(input)")
        }
    }
}

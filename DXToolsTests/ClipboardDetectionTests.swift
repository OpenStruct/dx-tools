import XCTest
@testable import DX_Tools

final class ClipboardDetectionTests: XCTestCase {

    func testDetectJSON() {
        let d = ClipboardDetection.detect(#"{"name":"John"}"#)
        XCTAssertEqual(d.type, .json)
        XCTAssertFalse(d.actions.isEmpty)
    }

    func testDetectJSONArray() {
        let d = ClipboardDetection.detect("[1,2,3]")
        XCTAssertEqual(d.type, .json)
    }

    func testDetectJWT() {
        let jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
        let d = ClipboardDetection.detect(jwt)
        XCTAssertEqual(d.type, .jwt)
    }

    func testDetectCurl() {
        let d = ClipboardDetection.detect("curl https://api.example.com")
        XCTAssertEqual(d.type, .curl)
    }

    func testDetectCurlCaseInsensitive() {
        let d = ClipboardDetection.detect("CURL https://api.example.com")
        XCTAssertEqual(d.type, .curl)
    }

    func testDetectColor() {
        let d = ClipboardDetection.detect("#FF5733")
        XCTAssertEqual(d.type, .color)
    }

    func testDetectColor3() {
        let d = ClipboardDetection.detect("#F00")
        XCTAssertEqual(d.type, .color)
    }

    func testDetectUUID() {
        let d = ClipboardDetection.detect("550e8400-e29b-41d4-a716-446655440000")
        XCTAssertEqual(d.type, .uuid)
    }

    func testDetectEpoch() {
        let d = ClipboardDetection.detect("1700000000")
        XCTAssertEqual(d.type, .epoch)
        XCTAssertTrue(d.preview.contains("→"))
    }

    func testDetectURL() {
        let d = ClipboardDetection.detect("https://example.com/api/v1")
        XCTAssertEqual(d.type, .url)
    }

    func testDetectUnknown() {
        let d = ClipboardDetection.detect("just some regular text")
        XCTAssertEqual(d.type, .unknown)
    }

    func testDetectBase64() {
        let base64 = "SGVsbG8gV29ybGQgdGhpcyBpcyBhIGxvbmdlciBzdHJpbmc=" // "Hello World this is a longer string"
        let d = ClipboardDetection.detect(base64)
        XCTAssertEqual(d.type, .base64)
    }

    func testAllDetectionsHaveActions() {
        let inputs = [
            #"{"a":1}"#,
            "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.sig",
            "curl https://api.test.com",
            "#FF0000",
            "550e8400-e29b-41d4-a716-446655440000",
            "1700000000",
            "https://test.com",
            "random text here",
        ]
        for input in inputs {
            let d = ClipboardDetection.detect(input)
            XCTAssertFalse(d.actions.isEmpty, "No actions for: \(input)")
        }
    }

    func testJSONPrioritizedOverBase64() {
        // Valid JSON that could also be base64
        let d = ClipboardDetection.detect(#"{"valid":"json"}"#)
        XCTAssertEqual(d.type, .json, "JSON should be detected before base64")
    }

    func testJWTPrioritizedOverJSON() {
        // JWT looks like JSON when decoded but should be detected as JWT
        let jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.sig"
        let d = ClipboardDetection.detect(jwt)
        XCTAssertEqual(d.type, .jwt)
    }
}

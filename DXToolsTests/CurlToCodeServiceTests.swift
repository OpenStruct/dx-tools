import XCTest
@testable import DX_Tools

final class CurlToCodeServiceTests: XCTestCase {

    func testParseSimpleGET() {
        let parsed = CurlToCodeService.parse("curl https://api.example.com/users")
        XCTAssertEqual(parsed.url, "https://api.example.com/users")
        XCTAssertEqual(parsed.method, "GET")
        XCTAssertTrue(parsed.headers.isEmpty)
        XCTAssertNil(parsed.body)
    }

    func testParseWithMethod() {
        let parsed = CurlToCodeService.parse("curl -X POST https://api.example.com/users")
        XCTAssertEqual(parsed.method, "POST")
        XCTAssertEqual(parsed.url, "https://api.example.com/users")
    }

    func testParseWithHeaders() {
        let curl = """
        curl -H 'Content-Type: application/json' -H 'Authorization: Bearer token123' https://api.example.com
        """
        let parsed = CurlToCodeService.parse(curl)
        XCTAssertEqual(parsed.headers.count, 2)
        XCTAssertEqual(parsed.headers[0].key, "Content-Type")
        XCTAssertEqual(parsed.headers[0].value, "application/json")
        XCTAssertEqual(parsed.headers[1].key, "Authorization")
        XCTAssertEqual(parsed.headers[1].value, "Bearer token123")
    }

    func testParseWithBody() {
        let curl = #"curl -X POST -d '{"name":"John"}' https://api.example.com/users"#
        let parsed = CurlToCodeService.parse(curl)
        XCTAssertEqual(parsed.method, "POST")
        XCTAssertEqual(parsed.body, #"{"name":"John"}"#)
    }

    func testParseDataAutoSetsPost() {
        let curl = #"curl -d '{"data":true}' https://api.example.com"#
        let parsed = CurlToCodeService.parse(curl)
        XCTAssertEqual(parsed.method, "POST") // Auto-set when -d present
    }

    func testParseMultilineBackslash() {
        let curl = """
        curl \\
          -X POST \\
          -H 'Content-Type: application/json' \\
          https://api.example.com
        """
        let parsed = CurlToCodeService.parse(curl)
        XCTAssertEqual(parsed.method, "POST")
        XCTAssertFalse(parsed.url.isEmpty)
    }

    func testParseQuotedURL() {
        let parsed = CurlToCodeService.parse(#"curl "https://api.example.com/search?q=test""#)
        XCTAssertTrue(parsed.url.contains("api.example.com"))
    }

    func testToSwift() {
        let parsed = CurlToCodeService.ParsedCurl(
            url: "https://api.example.com",
            method: "GET",
            headers: [("Accept", "application/json")],
            body: nil
        )
        let code = CurlToCodeService.toSwift(parsed)
        XCTAssertTrue(code.contains("import Foundation"))
        XCTAssertTrue(code.contains("URLRequest"))
        XCTAssertTrue(code.contains("httpMethod"))
        XCTAssertTrue(code.contains("setValue"))
    }

    func testToGo() {
        let parsed = CurlToCodeService.ParsedCurl(url: "https://api.example.com", method: "GET")
        let code = CurlToCodeService.toGo(parsed)
        XCTAssertTrue(code.contains("package main"))
        XCTAssertTrue(code.contains("http.NewRequest"))
        XCTAssertTrue(code.contains("net/http"))
    }

    func testToPython() {
        let parsed = CurlToCodeService.ParsedCurl(url: "https://api.example.com", method: "GET")
        let code = CurlToCodeService.toPython(parsed)
        XCTAssertTrue(code.contains("import requests"))
        XCTAssertTrue(code.contains("requests.get"))
    }

    func testToJavaScript() {
        let parsed = CurlToCodeService.ParsedCurl(url: "https://api.example.com", method: "POST")
        let code = CurlToCodeService.toJavaScript(parsed)
        XCTAssertTrue(code.contains("fetch"))
        XCTAssertTrue(code.contains("POST"))
    }

    func testToRuby() {
        let parsed = CurlToCodeService.ParsedCurl(url: "https://api.example.com", method: "DELETE")
        let code = CurlToCodeService.toRuby(parsed)
        XCTAssertTrue(code.contains("Net::HTTP"))
        XCTAssertTrue(code.contains("Delete"))
    }

    func testAllLanguagesNonEmpty() {
        let parsed = CurlToCodeService.ParsedCurl(
            url: "https://api.example.com",
            method: "POST",
            headers: [("Content-Type", "application/json")],
            body: #"{"test":true}"#
        )
        XCTAssertFalse(CurlToCodeService.toSwift(parsed).isEmpty)
        XCTAssertFalse(CurlToCodeService.toGo(parsed).isEmpty)
        XCTAssertFalse(CurlToCodeService.toPython(parsed).isEmpty)
        XCTAssertFalse(CurlToCodeService.toJavaScript(parsed).isEmpty)
        XCTAssertFalse(CurlToCodeService.toRuby(parsed).isEmpty)
    }
}

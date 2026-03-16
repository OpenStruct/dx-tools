import XCTest
@testable import DX_Tools

final class WebhookServiceTests: XCTestCase {
    func testParseGETRequest() {
        let raw = "GET /health HTTP/1.1\r\nHost: localhost:9999\r\n\r\n"
        let data = Data(raw.utf8)
        let req = WebhookService.parseHTTPRequest(data)
        XCTAssertEqual(req.method, "GET")
        XCTAssertEqual(req.path, "/health")
        XCTAssertTrue(req.body.isEmpty)
    }

    func testParsePOSTWithJSON() {
        let raw = "POST /webhook HTTP/1.1\r\nHost: localhost:9999\r\nContent-Type: application/json\r\n\r\n{\"event\":\"push\"}"
        let data = Data(raw.utf8)
        let req = WebhookService.parseHTTPRequest(data)
        XCTAssertEqual(req.method, "POST")
        XCTAssertEqual(req.path, "/webhook")
        XCTAssertEqual(req.contentType, "application/json")
        XCTAssertTrue(req.body.contains("push"))
    }

    func testParseHeaders() {
        let raw = "GET / HTTP/1.1\r\nHost: localhost\r\nX-Custom: value\r\nAccept: */*\r\n\r\n"
        let data = Data(raw.utf8)
        let req = WebhookService.parseHTTPRequest(data)
        XCTAssertEqual(req.headers.count, 3)
        XCTAssertTrue(req.headers.contains { $0.key == "X-Custom" && $0.value == "value" })
    }

    func testParseQueryParams() {
        let raw = "GET /api?key=abc&page=2 HTTP/1.1\r\nHost: localhost\r\n\r\n"
        let data = Data(raw.utf8)
        let req = WebhookService.parseHTTPRequest(data)
        XCTAssertEqual(req.queryParams.count, 2)
        XCTAssertTrue(req.queryParams.contains { $0.key == "key" && $0.value == "abc" })
        XCTAssertTrue(req.queryParams.contains { $0.key == "page" && $0.value == "2" })
    }

    func testBuildHTTPResponse() {
        let response = WebhookService.buildHTTPResponse(statusCode: 200, body: "OK")
        let str = String(data: response, encoding: .utf8)!
        XCTAssertTrue(str.hasPrefix("HTTP/1.1 200 OK"))
        XCTAssertTrue(str.contains("Content-Length: 2"))
        XCTAssertTrue(str.hasSuffix("OK"))
    }

    func testBuildHTTPResponseCustomCode() {
        let response = WebhookService.buildHTTPResponse(statusCode: 404, body: "Not Found")
        let str = String(data: response, encoding: .utf8)!
        XCTAssertTrue(str.contains("404"))
    }

    func testBuildHTTPResponseWithHeaders() {
        let response = WebhookService.buildHTTPResponse(statusCode: 200, body: "", headers: [("X-Custom", "test")])
        let str = String(data: response, encoding: .utf8)!
        XCTAssertTrue(str.contains("X-Custom: test"))
    }

    func testCurlGeneration() {
        let req = WebhookService.WebhookRequest(
            method: "POST", path: "/webhook",
            headers: [("Content-Type", "application/json")],
            body: "{\"test\":true}", queryParams: [],
            contentType: "application/json", sourceIP: "127.0.0.1", bodySize: 13
        )
        let curl = WebhookService.generateCurl(req)
        XCTAssertTrue(curl.contains("-X POST"))
        XCTAssertTrue(curl.contains("Content-Type"))
        XCTAssertTrue(curl.contains("/webhook"))
    }

    func testEmptyBody() {
        let raw = "DELETE /items/1 HTTP/1.1\r\nHost: localhost\r\n\r\n"
        let data = Data(raw.utf8)
        let req = WebhookService.parseHTTPRequest(data)
        XCTAssertEqual(req.method, "DELETE")
        XCTAssertTrue(req.body.isEmpty)
        XCTAssertEqual(req.bodySize, 0)
    }
}

import XCTest
@testable import DX_Tools

final class HTTPProxyServiceTests: XCTestCase {
    func testParseHTTPRequest() {
        let raw = "GET /api/users HTTP/1.1\r\nHost: api.example.com\r\nAccept: application/json\r\n\r\n"
        let req = HTTPProxyService.parseRequest(Data(raw.utf8))
        XCTAssertEqual(req.method, "GET")
        XCTAssertEqual(req.host, "api.example.com")
        XCTAssertEqual(req.path, "/api/users")
    }

    func testParseHTTPResponse() {
        let raw = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"ok\":true}"
        let res = HTTPProxyService.parseResponse(Data(raw.utf8))
        XCTAssertEqual(res.statusCode, 200)
        XCTAssertEqual(res.statusText, "OK")
        XCTAssertTrue(res.bodyString?.contains("ok") ?? false)
    }

    func testFilterByMethod() {
        let get = HTTPProxyService.CapturedExchange(request: HTTPProxyService.CapturedRequest(method: "GET", url: "/a", host: "h", path: "/a", headers: [], contentType: "", size: 0))
        let post = HTTPProxyService.CapturedExchange(request: HTTPProxyService.CapturedRequest(method: "POST", url: "/b", host: "h", path: "/b", headers: [], contentType: "", size: 0))
        let result = HTTPProxyService.filter([get, post], search: "", methods: ["GET"])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].request.method, "GET")
    }

    func testFilterByHost() {
        let a = HTTPProxyService.CapturedExchange(request: HTTPProxyService.CapturedRequest(method: "GET", url: "/", host: "api.github.com", path: "/", headers: [], contentType: "", size: 0))
        let b = HTTPProxyService.CapturedExchange(request: HTTPProxyService.CapturedRequest(method: "GET", url: "/", host: "example.com", path: "/", headers: [], contentType: "", size: 0))
        let result = HTTPProxyService.filter([a, b], search: "github", methods: [])
        XCTAssertEqual(result.count, 1)
    }

    func testCurlGeneration() {
        let exchange = HTTPProxyService.CapturedExchange(
            request: HTTPProxyService.CapturedRequest(method: "POST", url: "https://api.example.com/data", host: "api.example.com", path: "/data",
                                                      headers: [("Content-Type", "application/json")], bodyString: "{\"key\":\"val\"}", contentType: "application/json", size: 100)
        )
        let curl = HTTPProxyService.generateCurl(exchange)
        XCTAssertTrue(curl.contains("-X POST"))
        XCTAssertTrue(curl.contains("Content-Type"))
    }

    func testStatusColor() {
        XCTAssertEqual(HTTPProxyService.statusColor(200), "green")
        XCTAssertEqual(HTTPProxyService.statusColor(301), "blue")
        XCTAssertEqual(HTTPProxyService.statusColor(404), "orange")
        XCTAssertEqual(HTTPProxyService.statusColor(500), "red")
    }

    func testSizeFormatting() {
        XCTAssertEqual(HTTPProxyService.formatSize(500), "500B")
        XCTAssertEqual(HTTPProxyService.formatSize(2048), "2.0KB")
        XCTAssertEqual(HTTPProxyService.formatSize(1048576), "1.0MB")
    }
}

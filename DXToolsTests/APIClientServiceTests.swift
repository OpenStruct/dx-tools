import XCTest
@testable import DX_Tools

final class APIClientServiceTests: XCTestCase {
    func testVariableInterpolation() {
        let env = APIClientService.APIEnvironment(name: "Dev", variables: [
            APIClientService.KeyValueItem(key: "host", value: "example.com"),
            APIClientService.KeyValueItem(key: "port", value: "3000"),
        ])
        let result = APIClientService.interpolateVariables("https://{{host}}:{{port}}/api", environment: env)
        XCTAssertEqual(result, "https://example.com:3000/api")
    }

    func testVariableInterpolationNoEnv() {
        let result = APIClientService.interpolateVariables("{{host}}/api", environment: nil)
        XCTAssertEqual(result, "{{host}}/api")
    }

    func testVariableInterpolationMissing() {
        let env = APIClientService.APIEnvironment(name: "Dev", variables: [])
        let result = APIClientService.interpolateVariables("{{missing}}", environment: env)
        XCTAssertEqual(result, "{{missing}}")
    }

    func testGenerateCurl() {
        var req = APIClientService.APIClientRequest()
        req.method = .post
        req.url = "https://api.example.com/data"
        req.headers = [APIClientService.KeyValueItem(key: "Content-Type", value: "application/json")]
        req.bodyContent = "{\"key\":\"value\"}"
        req.bodyType = .json
        let curl = APIClientService.generateCurl(req)
        XCTAssertTrue(curl.contains("-X POST"))
        XCTAssertTrue(curl.contains("Content-Type"))
        XCTAssertTrue(curl.contains("api.example.com"))
    }

    func testGenerateCurlWithAuth() {
        var req = APIClientService.APIClientRequest()
        req.url = "https://api.example.com"
        req.authType = .bearer
        req.authToken = "mytoken123"
        let curl = APIClientService.generateCurl(req)
        XCTAssertTrue(curl.contains("Bearer mytoken123"))
    }

    func testGenerateSwift() {
        var req = APIClientService.APIClientRequest()
        req.method = .get
        req.url = "https://api.example.com/users"
        let code = APIClientService.generateSwift(req)
        XCTAssertTrue(code.contains("URLRequest"))
        XCTAssertTrue(code.contains("URLSession"))
        XCTAssertTrue(code.contains("GET"))
    }

    func testGeneratePython() {
        var req = APIClientService.APIClientRequest()
        req.method = .post
        req.url = "https://api.example.com"
        let code = APIClientService.generatePython(req)
        XCTAssertTrue(code.contains("import requests"))
        XCTAssertTrue(code.contains("requests.post"))
    }

    func testImportCurl() {
        let curl = "curl -X POST -H 'Content-Type: application/json' -d '{\"key\":\"val\"}' 'https://api.example.com/data'"
        let req = APIClientService.importCurl(curl)
        XCTAssertNotNil(req)
        XCTAssertEqual(req?.method, .post)
        XCTAssertEqual(req?.url, "https://api.example.com/data")
        XCTAssertTrue(req?.headers.contains { $0.key == "Content-Type" } ?? false)
    }

    func testImportCurlGET() {
        let curl = "curl 'https://api.example.com/users'"
        let req = APIClientService.importCurl(curl)
        XCTAssertNotNil(req)
        XCTAssertEqual(req?.url, "https://api.example.com/users")
    }

    func testCollectionSerialization() {
        let collection = APIClientService.APICollection(name: "Test", requests: [APIClientService.APIClientRequest(name: "Get Users", url: "https://api.example.com")])
        let data = try! JSONEncoder().encode([collection])
        let decoded = try! JSONDecoder().decode([APIClientService.APICollection].self, from: data)
        XCTAssertEqual(decoded[0].name, "Test")
        XCTAssertEqual(decoded[0].requests[0].name, "Get Users")
    }

    func testEnvironmentSerialization() {
        let env = APIClientService.APIEnvironment(name: "Production", variables: [APIClientService.KeyValueItem(key: "host", value: "prod.com")])
        let data = try! JSONEncoder().encode([env])
        let decoded = try! JSONDecoder().decode([APIClientService.APIEnvironment].self, from: data)
        XCTAssertEqual(decoded[0].name, "Production")
        XCTAssertEqual(decoded[0].variables[0].value, "prod.com")
    }

    func testAuthBasic() {
        var req = APIClientService.APIClientRequest()
        req.url = "https://api.example.com"
        req.authType = .basic
        req.authUsername = "user"
        req.authPassword = "pass"
        let curl = APIClientService.generateCurl(req)
        XCTAssertTrue(curl.contains("-u 'user:pass'"))
    }
}

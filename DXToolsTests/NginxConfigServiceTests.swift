import XCTest
@testable import DX_Tools

final class NginxConfigServiceTests: XCTestCase {
    func testReverseProxy() {
        var c = NginxConfigService.Config()
        c.template = .reverseProxy
        c.serverName = "api.example.com"
        c.upstream = "localhost:3000"
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("proxy_pass http://localhost:3000"))
        XCTAssertTrue(result.contains("server_name api.example.com"))
        XCTAssertTrue(result.contains("proxy_set_header Host"))
    }

    func testStaticSite() {
        var c = NginxConfigService.Config()
        c.template = .staticSite
        c.rootPath = "/var/www/html"
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("root /var/www/html"))
        XCTAssertTrue(result.contains("try_files"))
        XCTAssertTrue(result.contains("index.html"))
    }

    func testSSL() {
        var c = NginxConfigService.Config()
        c.template = .ssl
        c.sslCertPath = "/etc/ssl/cert.pem"
        c.sslKeyPath = "/etc/ssl/key.pem"
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("ssl_certificate /etc/ssl/cert.pem"))
        XCTAssertTrue(result.contains("ssl_protocols TLSv1.2"))
        XCTAssertTrue(result.contains("Strict-Transport-Security"))
        XCTAssertTrue(result.contains("return 301 https://"))
    }

    func testLoadBalancer() {
        var c = NginxConfigService.Config()
        c.template = .loadBalancer
        c.upstreamServers = ["server1:3000", "server2:3000", "server3:3000"]
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("upstream backend"))
        XCTAssertTrue(result.contains("server server1:3000"))
        XCTAssertTrue(result.contains("server server2:3000"))
        XCTAssertTrue(result.contains("server server3:3000"))
        XCTAssertTrue(result.contains("proxy_pass http://backend"))
    }

    func testRateLimit() {
        var c = NginxConfigService.Config()
        c.template = .rateLimit
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("limit_req_zone"))
        XCTAssertTrue(result.contains("limit_req zone=api_limit"))
        XCTAssertTrue(result.contains("burst=20"))
    }

    func testWebSocket() {
        var c = NginxConfigService.Config()
        c.template = .websocket
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("Upgrade"))
        XCTAssertTrue(result.contains("Connection"))
        XCTAssertTrue(result.contains("proxy_http_version 1.1"))
    }

    func testCORS() {
        var c = NginxConfigService.Config()
        c.template = .cors
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("Access-Control-Allow-Origin"))
        XCTAssertTrue(result.contains("Access-Control-Allow-Methods"))
        XCTAssertTrue(result.contains("OPTIONS"))
    }

    func testGzipEnabled() {
        var c = NginxConfigService.Config()
        c.template = .reverseProxy
        c.enableGzip = true
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("gzip on"))
        XCTAssertTrue(result.contains("gzip_types"))
    }

    func testGzipDisabled() {
        var c = NginxConfigService.Config()
        c.template = .reverseProxy
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertFalse(result.contains("gzip on"))
    }

    func testLogging() {
        var c = NginxConfigService.Config()
        c.template = .reverseProxy
        c.enableLogging = true
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("access_log"))
        XCTAssertTrue(result.contains("error_log"))
    }

    func testLoggingDisabled() {
        var c = NginxConfigService.Config()
        c.template = .reverseProxy
        c.enableLogging = false
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("access_log off"))
    }

    func testValidationMissingSemicolon() {
        let config = "server {\n    listen 80\n}"
        let warnings = NginxConfigService.validate(config)
        XCTAssertTrue(warnings.contains { $0.contains("Missing semicolon") })
    }

    func testValidationBalancedBraces() {
        let config = "server {\n    listen 80;\n}"
        let warnings = NginxConfigService.validate(config)
        XCTAssertTrue(warnings.isEmpty || !warnings.contains { $0.contains("brace") })
    }

    func testBasicAuth() {
        var c = NginxConfigService.Config()
        c.template = .basicAuth
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("auth_basic"))
        XCTAssertTrue(result.contains("htpasswd"))
    }

    func testCaching() {
        var c = NginxConfigService.Config()
        c.template = .caching
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("proxy_cache_path"))
        XCTAssertTrue(result.contains("proxy_cache app_cache"))
        XCTAssertTrue(result.contains("X-Cache-Status"))
    }

    func testRedirect() {
        var c = NginxConfigService.Config()
        c.template = .redirect
        c.redirectTarget = "https://newsite.com"
        c.enableGzip = false
        let result = NginxConfigService.generate(c)
        XCTAssertTrue(result.contains("return 301"))
        XCTAssertTrue(result.contains("https://newsite.com"))
    }
}

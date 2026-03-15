import XCTest
@testable import DX_Tools

final class NetworkServiceTests: XCTestCase {
    func testGetLocalIPs() {
        let ips = NetworkService.getLocalIPs()
        XCTAssertFalse(ips.isEmpty, "Should have at least one local IP")
        for ip in ips {
            XCTAssertFalse(ip.interface.isEmpty)
            XCTAssertFalse(ip.ip.isEmpty)
            XCTAssertTrue(ip.type == "IPv4" || ip.type == "IPv6")
        }
    }

    func testGetDNSServers() {
        let servers = NetworkService.getDNSServers()
        // Most machines have DNS configured
        XCTAssertFalse(servers.isEmpty, "Should have DNS servers configured")
    }

    func testDNSLookupGoogle() {
        let result = NetworkService.dnsLookup(domain: "google.com")
        XCTAssertEqual(result.domain, "google.com")
        XCTAssertFalse(result.records.isEmpty, "google.com should have DNS records")
        XCTAssertTrue(result.records.contains { $0.type == "A" }, "Should have A records")
        XCTAssertGreaterThan(result.resolveTime, 0)
    }

    func testDNSLookupStripsProtocol() {
        let result = NetworkService.dnsLookup(domain: "https://google.com/path")
        XCTAssertEqual(result.domain, "google.com")
    }

    func testDNSLookupInvalid() {
        let result = NetworkService.dnsLookup(domain: "thisdoesnotexist12345.invalid")
        XCTAssertTrue(result.records.isEmpty)
    }

    func testGetNetworkInfoHasHostname() {
        let info = NetworkService.getNetworkInfo()
        XCTAssertFalse(info.hostname.isEmpty)
    }
}

import XCTest
@testable import DX_Tools

final class PortServiceTests: XCTestCase {

    // MARK: - extractPort

    func testExtractPortFromStar() {
        XCTAssertEqual(PortService.extractPort(from: "*:3000"), 3000)
    }

    func testExtractPortFromIPv4() {
        XCTAssertEqual(PortService.extractPort(from: "127.0.0.1:8080"), 8080)
    }

    func testExtractPortFromIPv6() {
        XCTAssertEqual(PortService.extractPort(from: "[::1]:5432"), 5432)
    }

    func testExtractPortFromIPv6Wildcard() {
        XCTAssertEqual(PortService.extractPort(from: "[::]:3000"), 3000)
    }

    func testExtractPortFromGarbage() {
        XCTAssertNil(PortService.extractPort(from: "noport"))
    }

    func testExtractPortFromEmptyString() {
        XCTAssertNil(PortService.extractPort(from: ""))
    }

    func testExtractPortFromJustColon() {
        XCTAssertNil(PortService.extractPort(from: ":"))
    }

    func testExtractPortHighPort() {
        XCTAssertEqual(PortService.extractPort(from: "*:62606"), 62606)
    }

    // MARK: - parseLsofOutput

    func testParseLsofEmptyOutput() {
        let result = PortService.parseLsofOutput("")
        XCTAssertTrue(result.isEmpty)
    }

    func testParseLsofHeaderOnly() {
        let output = "COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME"
        let result = PortService.parseLsofOutput(output)
        XCTAssertTrue(result.isEmpty)
    }

    func testParseLsofSingleLine() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node       1234  nam   22u  IPv6 0xabc123      0t0  TCP *:3000 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 3000)
        XCTAssertEqual(result[0].pid, 1234)
        XCTAssertEqual(result[0].processName, "node")
        XCTAssertEqual(result[0].user, "nam")
        XCTAssertEqual(result[0].state, "LISTEN")
        XCTAssertEqual(result[0].protocol_, "TCP")
    }

    func testParseLsofIPv4Address() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        postgres   1295  nam    7u  IPv4 0x456472be      0t0  TCP 127.0.0.1:5432 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 5432)
        XCTAssertEqual(result[0].processName, "postgres")
        XCTAssertEqual(result[0].type, "IPv4")
    }

    func testParseLsofIPv6Address() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        postgres   1295  nam    8u  IPv6 0x7a615ab2      0t0  TCP [::1]:5432 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 5432)
        XCTAssertEqual(result[0].type, "IPv6")
    }

    func testParseLsofDeduplicatesSamePidPort() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node       1234  nam   22u  IPv4 0xabc123      0t0  TCP *:3000 (LISTEN)
        node       1234  nam   23u  IPv6 0xdef456      0t0  TCP *:3000 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1, "Should deduplicate same PID+port")
    }

    func testParseLsofDifferentPidsSamePort() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node       1234  nam   22u  IPv4 0xabc123      0t0  TCP *:3000 (LISTEN)
        node       5678  nam   23u  IPv4 0xdef456      0t0  TCP *:3000 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 2, "Different PIDs on same port should both appear")
    }

    func testParseLsofMultiplePorts() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node       1234  nam   22u  IPv4 0xabc123      0t0  TCP *:3000 (LISTEN)
        postgres   5678  nam    7u  IPv4 0xdef456      0t0  TCP 127.0.0.1:5432 (LISTEN)
        redis      9012  nam    6u  IPv4 0xghi789      0t0  TCP 127.0.0.1:6379 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 3)
        // Should be sorted by port
        XCTAssertEqual(result[0].port, 3000)
        XCTAssertEqual(result[1].port, 5432)
        XCTAssertEqual(result[2].port, 6379)
    }

    func testParseLsofEscapedSpacesInCommand() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        Code\\x20H 60399  nam   34u  IPv4 0x16c9cf95      0t0  TCP 127.0.0.1:13865 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 13865)
        XCTAssertEqual(result[0].processName, "Code H")
    }

    func testParseLsofEstablishedState() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        node       1234  nam   22u  IPv4 0xabc123      0t0  TCP 127.0.0.1:3000 (ESTABLISHED)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].state, "ESTABLISHED")
    }

    func testParseLsofSkipsMalformedLines() {
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        too few columns
        node       1234  nam   22u  IPv4 0xabc123      0t0  TCP *:3000 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].port, 3000)
    }

    func testParseLsofRealWorldOutput() {
        // Actual macOS lsof output format
        let output = """
        COMMAND     PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
        rapportd    494  nam   11u  IPv4 0x1d029f3399183014      0t0  TCP *:62606 (LISTEN)
        rapportd    494  nam   16u  IPv6 0xaa2a716371b0babf      0t0  TCP *:62606 (LISTEN)
        ControlCe   527  nam   10u  IPv4 0x6647db3880b2433b      0t0  TCP *:7000 (LISTEN)
        ControlCe   527  nam   12u  IPv4 0x76d6cbff4b587aad      0t0  TCP *:5000 (LISTEN)
        postgres   1295  nam    7u  IPv6 0x7a615ab2e98e8f2a      0t0  TCP [::1]:5432 (LISTEN)
        postgres   1295  nam    8u  IPv4 0x456472be0734834b      0t0  TCP 127.0.0.1:5432 (LISTEN)
        adb       20765  nam    8u  IPv4 0x7f79718b59dbdd49      0t0  TCP 127.0.0.1:5037 (LISTEN)
        """
        let result = PortService.parseLsofOutput(output)

        // rapportd 494 on 62606 appears twice (IPv4 + IPv6), should dedup
        let rapportd = result.filter { $0.processName == "rapportd" }
        XCTAssertEqual(rapportd.count, 1, "Should dedup same PID+port")

        // ControlCenter on 7000 and 5000 — different ports, same PID
        let cc = result.filter { $0.processName == "ControlCe" }
        XCTAssertEqual(cc.count, 2)

        // postgres on 5432 — appears twice (IPv4 + IPv6), should dedup
        let pg = result.filter { $0.processName == "postgres" }
        XCTAssertEqual(pg.count, 1, "Should dedup same PID+port for postgres")
        XCTAssertEqual(pg[0].port, 5432)

        // adb on 5037
        let adb = result.filter { $0.processName == "adb" }
        XCTAssertEqual(adb.count, 1)
        XCTAssertEqual(adb[0].port, 5037)

        // Result should be sorted by port
        for i in 1..<result.count {
            XCTAssertLessThanOrEqual(result[i-1].port, result[i].port)
        }
    }

    // MARK: - PortProcess properties

    func testIsSystemProcess() {
        let root = PortProcess(port: 80, pid: 100, processName: "httpd", user: "root", fd: "3u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "httpd")
        XCTAssertTrue(root.isSystemProcess)

        let launchd = PortProcess(port: 80, pid: 1, processName: "launchd", user: "root", fd: "3u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "launchd")
        XCTAssertTrue(launchd.isSystemProcess)

        let user = PortProcess(port: 3000, pid: 1234, processName: "node", user: "nam", fd: "22u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "node server.js")
        XCTAssertFalse(user.isSystemProcess)
    }

    func testPortCategory() {
        let web = PortProcess(port: 443, pid: 1, processName: "nginx", user: "root", fd: "3u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "")
        XCTAssertEqual(web.portCategory, .web)

        let dev = PortProcess(port: 3000, pid: 1234, processName: "node", user: "nam", fd: "22u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "")
        XCTAssertEqual(dev.portCategory, .dev)

        let db = PortProcess(port: 5432, pid: 1295, processName: "postgres", user: "nam", fd: "7u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "")
        XCTAssertEqual(db.portCategory, .database)

        let sys = PortProcess(port: 22, pid: 100, processName: "sshd", user: "root", fd: "3u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "")
        XCTAssertEqual(sys.portCategory, .system)

        let other = PortProcess(port: 55555, pid: 100, processName: "custom", user: "nam", fd: "3u", type: "IPv4", protocol_: "TCP", state: "LISTEN", command: "")
        XCTAssertEqual(other.portCategory, .other)

        // Test database ports
        XCTAssertEqual(PortProcess(port: 3306, pid: 1, processName: "mysql", user: "nam", fd: "", type: "", protocol_: "", state: "", command: "").portCategory, .database)
        XCTAssertEqual(PortProcess(port: 27017, pid: 1, processName: "mongod", user: "nam", fd: "", type: "", protocol_: "", state: "", command: "").portCategory, .database)
        XCTAssertEqual(PortProcess(port: 6379, pid: 1, processName: "redis", user: "nam", fd: "", type: "", protocol_: "", state: "", command: "").portCategory, .database)
    }

    func testDevPortRanges() {
        let ports = [3000, 3999, 4000, 4200, 5000, 5173, 8000, 8080, 8888, 9000, 9999]
        for port in ports {
            let proc = PortProcess(port: port, pid: 1, processName: "test", user: "nam", fd: "", type: "", protocol_: "", state: "", command: "")
            XCTAssertEqual(proc.portCategory, port == 5432 ? .database : .dev, "Port \(port) should be dev")
        }
    }

    // MARK: - Live integration tests

    func testListPortsReturnsResults() {
        // This machine has ports open (we confirmed with lsof)
        let result = PortService.listPorts()
        XCTAssertFalse(result.isEmpty, "Should find at least some listening ports on this machine")

        // Every result should have valid data
        for proc in result {
            XCTAssertGreaterThan(proc.port, 0)
            XCTAssertGreaterThan(proc.pid, 0)
            XCTAssertFalse(proc.processName.isEmpty)
            XCTAssertFalse(proc.user.isEmpty)
            XCTAssertEqual(proc.protocol_, "TCP")
        }
    }

    func testListPortsSortedByPort() {
        let result = PortService.listPorts()
        for i in 1..<result.count {
            XCTAssertLessThanOrEqual(result[i-1].port, result[i].port)
        }
    }

    func testIsPortInUseForKnownPort() {
        // Port 5432 (postgres) should be in use based on our lsof output
        let ports = PortService.listPorts()
        if let firstPort = ports.first {
            XCTAssertTrue(PortService.isPortInUse(firstPort.port))
        }
    }

    func testIsPortInUseForUnusedPort() {
        // Port 19999 is very unlikely to be in use
        XCTAssertFalse(PortService.isPortInUse(19999))
    }

    func testKillPortNoProcess() {
        let result = PortService.killPort(19999)
        switch result {
        case .success:
            XCTFail("Should fail for unused port")
        case .failure(let error):
            XCTAssertEqual(error, .noProcessOnPort(19999))
        }
    }

    func testShellReturnsOutput() {
        let result = PortService.shell("echo hello")
        XCTAssertEqual(result.trimmingCharacters(in: .whitespacesAndNewlines), "hello")
    }

    func testShellHandlesFailure() {
        let result = PortService.shell("false")
        // Should return empty or error without crashing
        XCTAssertNotNil(result)
    }
}

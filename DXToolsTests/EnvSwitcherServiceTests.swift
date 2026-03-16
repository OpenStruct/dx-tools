import XCTest
@testable import DX_Tools

final class EnvSwitcherServiceTests: XCTestCase {
    func testParseEnvContent() {
        let content = "DB_HOST=localhost\nDB_PORT=5432\nAPI_KEY=abc123"
        let result = EnvSwitcherService.parseEnvContent(content)
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].key, "DB_HOST")
        XCTAssertEqual(result[0].value, "localhost")
        XCTAssertEqual(result[1].key, "DB_PORT")
        XCTAssertEqual(result[1].value, "5432")
    }

    func testParseEnvWithQuotes() {
        let content = "NAME=\"John Doe\"\nPATH='some/path'"
        let result = EnvSwitcherService.parseEnvContent(content)
        XCTAssertEqual(result[0].value, "John Doe")
        XCTAssertEqual(result[1].value, "some/path")
    }

    func testParseEnvWithComments() {
        let content = "# This is a comment\nKEY=value\n# Another comment"
        let result = EnvSwitcherService.parseEnvContent(content)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].key, "KEY")
    }

    func testParseEnvEmpty() {
        let result = EnvSwitcherService.parseEnvContent("")
        XCTAssertTrue(result.isEmpty)
    }

    func testDiffProfiles() {
        let a = EnvSwitcherService.EnvProfile(name: "Dev", color: "#00FF00", content: "DB=localhost\nPORT=3000", variables: 2)
        let b = EnvSwitcherService.EnvProfile(name: "Prod", color: "#FF0000", content: "DB=prod-server\nPORT=3000\nSSL=true", variables: 3)
        let diffs = EnvSwitcherService.diffProfiles(a, b)
        XCTAssertTrue(diffs.contains { $0.key == "DB" && $0.inA == "localhost" && $0.inB == "prod-server" })
        XCTAssertTrue(diffs.contains { $0.key == "SSL" && $0.inA == nil && $0.inB == "true" })
        XCTAssertFalse(diffs.contains { $0.key == "PORT" }) // same in both
    }

    func testDiffIdentical() {
        let content = "KEY=value"
        let a = EnvSwitcherService.EnvProfile(name: "A", color: "#000", content: content, variables: 1)
        let b = EnvSwitcherService.EnvProfile(name: "B", color: "#000", content: content, variables: 1)
        let diffs = EnvSwitcherService.diffProfiles(a, b)
        XCTAssertTrue(diffs.isEmpty)
    }

    func testCreateProfile() {
        let profile = EnvSwitcherService.createProfile(name: "Test", color: "#FF0000", content: "A=1\nB=2\nC=3")
        XCTAssertEqual(profile.name, "Test")
        XCTAssertEqual(profile.variables, 3)
        XCTAssertEqual(profile.color, "#FF0000")
    }

    func testFindConflicts() {
        let a = EnvSwitcherService.EnvProfile(name: "A", color: "#000", content: "DB=localhost\nPORT=3000", variables: 2)
        let b = EnvSwitcherService.EnvProfile(name: "B", color: "#000", content: "DB=prod\nPORT=3000", variables: 2)
        let conflicts = EnvSwitcherService.findConflicts([a, b])
        XCTAssertTrue(conflicts.contains("DB"))
        XCTAssertFalse(conflicts.contains("PORT"))
    }

    func testDetectEnvFile() {
        let tmpDir = NSTemporaryDirectory() + "env-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: tmpDir + "/.env", contents: nil)
        let result = EnvSwitcherService.detectEnvFile(in: tmpDir)
        XCTAssertEqual(result, ".env")
        try? FileManager.default.removeItem(atPath: tmpDir)
    }

    func testSaveLoadProjects() {
        let project = EnvSwitcherService.Project(name: "test", path: "/tmp/test")
        EnvSwitcherService.saveProjects([project])
        let loaded = EnvSwitcherService.loadProjects()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].name, "test")
        // Cleanup
        EnvSwitcherService.saveProjects([])
    }
}

import XCTest
@testable import DX_Tools

final class HashServiceTests: XCTestCase {

    func testMD5() {
        let result = HashService.hash(string: "hello")
        XCTAssertEqual(result.md5, "5d41402abc4b2a76b9719d911017c592")
    }

    func testSHA1() {
        let result = HashService.hash(string: "hello")
        XCTAssertEqual(result.sha1, "aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d")
    }

    func testSHA256() {
        let result = HashService.hash(string: "hello")
        XCTAssertEqual(result.sha256, "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
    }

    func testSHA512() {
        let result = HashService.hash(string: "hello")
        XCTAssertEqual(result.sha512, "9b71d224bd62f3785d96d46ad3ea3d73319bfbc2890caadae2dff72519673ca72323c3d99ba5c11d7c7acc6e14b8c5da0c4663475c2e5c3adef46f73bcdec043")
    }

    func testEmptyString() {
        let result = HashService.hash(string: "")
        XCTAssertEqual(result.md5, "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssertEqual(result.sha256, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testDifferentInputsDifferentHashes() {
        let hash1 = HashService.hash(string: "hello")
        let hash2 = HashService.hash(string: "world")
        XCTAssertNotEqual(hash1.md5, hash2.md5)
        XCTAssertNotEqual(hash1.sha256, hash2.sha256)
    }

    func testDeterministic() {
        let hash1 = HashService.hash(string: "test")
        let hash2 = HashService.hash(string: "test")
        XCTAssertEqual(hash1.md5, hash2.md5)
        XCTAssertEqual(hash1.sha256, hash2.sha256)
        XCTAssertEqual(hash1.sha512, hash2.sha512)
    }

    func testHashLengths() {
        let result = HashService.hash(string: "test")
        XCTAssertEqual(result.md5.count, 32)
        XCTAssertEqual(result.sha1.count, 40)
        XCTAssertEqual(result.sha256.count, 64)
        XCTAssertEqual(result.sha512.count, 128)
    }

    func testHashData() {
        let data = "hello".data(using: .utf8)!
        let fromData = HashService.hash(data: data)
        let fromString = HashService.hash(string: "hello")
        XCTAssertEqual(fromData.md5, fromString.md5)
        XCTAssertEqual(fromData.sha256, fromString.sha256)
    }
}

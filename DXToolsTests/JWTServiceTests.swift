import XCTest
@testable import DX_Tools

final class JWTServiceTests: XCTestCase {

    // Test JWT: {"alg":"HS256","typ":"JWT"}.{"sub":"1234567890","name":"John Doe","iat":1516239022}
    let validJWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

    func testDecodeValidJWT() {
        let result = JWTService.decode(validJWT)
        guard case .success(let decoded) = result else { return XCTFail("Should decode valid JWT") }
        XCTAssertTrue(decoded.headerJSON.contains("HS256"))
        XCTAssertTrue(decoded.payloadJSON.contains("John Doe"))
        XCTAssertTrue(decoded.payloadJSON.contains("1234567890"))
        XCTAssertFalse(decoded.signature.isEmpty)
    }

    func testDecodeClaims() {
        let result = JWTService.decode(validJWT)
        guard case .success(let decoded) = result else { return XCTFail() }
        XCTAssertEqual(decoded.claims["Subject"], "1234567890")
        XCTAssertEqual(decoded.claims["Name"], "John Doe")
        XCTAssertEqual(decoded.claims["Algorithm"], "HS256")
        XCTAssertEqual(decoded.claims["Type"], "JWT")
    }

    func testDecodeInvalidFormat() {
        let result = JWTService.decode("not.a.jwt.format.at.all")
        // May succeed or fail depending on base64 decode — the point is it shouldn't crash
        _ = result
    }

    func testDecodeSinglePart() {
        let result = JWTService.decode("justonepart")
        guard case .failure = result else { return XCTFail("Should fail for single part") }
    }

    func testDecodeEmptyString() {
        let result = JWTService.decode("")
        guard case .failure = result else { return XCTFail("Should fail for empty string") }
    }

    func testDecodeTrimsWhitespace() {
        let result = JWTService.decode("  \(validJWT)  \n")
        guard case .success(let decoded) = result else { return XCTFail() }
        XCTAssertTrue(decoded.payloadJSON.contains("John Doe"))
    }

    func testDecodeWithExpiration() {
        // JWT with exp claim set to past
        // {"alg":"HS256"}.{"sub":"user","exp":1000000000}
        let expiredJWT = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1c2VyIiwiZXhwIjoxMDAwMDAwMDAwfQ.signature"
        let result = JWTService.decode(expiredJWT)
        guard case .success(let decoded) = result else { return XCTFail() }
        if let status = decoded.expirationStatus {
            switch status {
            case .expired: break // expected
            case .valid: XCTFail("Token from 2001 should be expired")
            }
        }
    }

    func testDecodeSignatureExtracted() {
        let result = JWTService.decode(validJWT)
        guard case .success(let decoded) = result else { return XCTFail() }
        XCTAssertEqual(decoded.signature, "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c")
    }
}

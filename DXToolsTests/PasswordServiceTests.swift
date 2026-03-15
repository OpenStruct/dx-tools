import XCTest
@testable import DX_Tools

final class PasswordServiceTests: XCTestCase {

    func testGeneratePasswordLength() {
        XCTAssertEqual(PasswordService.generatePassword(length: 8).count, 8)
        XCTAssertEqual(PasswordService.generatePassword(length: 16).count, 16)
        XCTAssertEqual(PasswordService.generatePassword(length: 32).count, 32)
        XCTAssertEqual(PasswordService.generatePassword(length: 1).count, 1)
    }

    func testGeneratePasswordWithSpecial() {
        // Generate many passwords and check at least one contains special chars
        var hasSpecial = false
        for _ in 0..<50 {
            let pass = PasswordService.generatePassword(length: 24, includeSpecial: true)
            if pass.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil {
                hasSpecial = true
                break
            }
        }
        XCTAssertTrue(hasSpecial, "Should include special chars at least sometimes")
    }

    func testGeneratePasswordWithoutSpecial() {
        for _ in 0..<20 {
            let pass = PasswordService.generatePassword(length: 24, includeSpecial: false)
            XCTAssertNil(pass.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")))
        }
    }

    func testGeneratePasswordUniqueness() {
        let passwords = (0..<100).map { _ in PasswordService.generatePassword(length: 24) }
        let unique = Set(passwords)
        XCTAssertEqual(unique.count, 100, "100 passwords should all be unique")
    }

    func testGeneratePassphrase() {
        let phrase = PasswordService.generatePassphrase(wordCount: 4)
        // Should have separators (one of: - . _ +)
        let hasSeparator = phrase.contains("-") || phrase.contains(".") || phrase.contains("_") || phrase.contains("+")
        XCTAssertTrue(hasSeparator)
        let parts = phrase.components(separatedBy: CharacterSet(charactersIn: "-._+"))
        XCTAssertEqual(parts.count, 4)
    }

    func testGeneratePassphraseWordCount() {
        for count in [2, 3, 5, 6] {
            let phrase = PasswordService.generatePassphrase(wordCount: count)
            let parts = phrase.components(separatedBy: CharacterSet(charactersIn: "-._+"))
            XCTAssertEqual(parts.count, count)
        }
    }

    func testEvaluateStrengthWeak() {
        XCTAssertEqual(PasswordService.evaluateStrength("abc"), .weak)
        XCTAssertEqual(PasswordService.evaluateStrength("12345"), .weak)
    }

    func testEvaluateStrengthGood() {
        let result = PasswordService.evaluateStrength("Hello12345abcd")
        XCTAssertTrue(result == .good || result == .strong)
    }

    func testEvaluateStrengthStrong() {
        let result = PasswordService.evaluateStrength("H3llo!W0rld@SecurePass#2024")
        XCTAssertEqual(result, .strong)
    }

    func testStrengthDisplayValues() {
        XCTAssertEqual(PasswordService.Strength.weak.rawValue, "Weak")
        XCTAssertEqual(PasswordService.Strength.good.rawValue, "Good")
        XCTAssertEqual(PasswordService.Strength.strong.rawValue, "Strong")
    }
}

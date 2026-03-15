import XCTest
@testable import DX_Tools

final class LoremServiceTests: XCTestCase {

    func testGenerateWords() {
        let result = LoremService.generateWords(5)
        let words = result.split(separator: " ")
        XCTAssertEqual(words.count, 5)
    }

    func testGenerateWordsZero() {
        let result = LoremService.generateWords(0)
        XCTAssertEqual(result, "")
    }

    func testGenerateSentence() {
        let sentence = LoremService.generateSentence()
        XCTAssertTrue(sentence.hasSuffix("."))
        XCTAssertTrue(sentence.first!.isUppercase)
    }

    func testGenerateSentenceWordCount() {
        let sentence = LoremService.generateSentence(wordCount: 5)
        let words = sentence.dropLast().split(separator: " ") // drop period
        XCTAssertEqual(words.count, 5)
    }

    func testGenerateParagraph() {
        let para = LoremService.generateParagraph()
        XCTAssertFalse(para.isEmpty)
        // Should have multiple sentences (ends with .)
        let sentences = para.components(separatedBy: ". ")
        XCTAssertGreaterThan(sentences.count, 1)
    }

    func testGenerateParagraphs() {
        let result = LoremService.generateParagraphs(3)
        let paras = result.components(separatedBy: "\n\n")
        XCTAssertEqual(paras.count, 3)
    }

    func testGenerateName() {
        let name = LoremService.generateName()
        let parts = name.split(separator: " ")
        XCTAssertEqual(parts.count, 2)
        XCTAssertTrue(parts[0].first!.isUppercase)
        XCTAssertTrue(parts[1].first!.isUppercase)
    }

    func testGenerateEmail() {
        let email = LoremService.generateEmail()
        XCTAssertTrue(email.contains("@"))
        XCTAssertTrue(email.contains("."))
    }

    func testGeneratePhone() {
        let phone = LoremService.generatePhone()
        XCTAssertTrue(phone.hasPrefix("+1"))
        XCTAssertTrue(phone.contains("("))
    }

    func testGenerateAddress() {
        let address = LoremService.generateAddress()
        XCTAssertTrue(address.contains(","))
    }

    func testGenerateJSON() {
        let json = LoremService.generateJSON(count: 3)
        XCTAssertTrue(json.hasPrefix("["))
        XCTAssertTrue(json.hasSuffix("]"))
        // Should be valid JSON
        let data = json.data(using: .utf8)!
        let arr = try! JSONSerialization.jsonObject(with: data) as! [Any]
        XCTAssertEqual(arr.count, 3)
    }

    func testGenerateJSONFields() {
        let json = LoremService.generateJSON(count: 1)
        XCTAssertTrue(json.contains("\"name\""))
        XCTAssertTrue(json.contains("\"email\""))
        XCTAssertTrue(json.contains("\"id\""))
    }
}

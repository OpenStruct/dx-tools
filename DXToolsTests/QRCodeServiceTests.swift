import XCTest
@testable import DX_Tools

final class QRCodeServiceTests: XCTestCase {
    func testGenerateBasic() {
        let image = QRCodeService.generate(from: "hello world")
        XCTAssertNotNil(image)
    }

    func testGenerateURL() {
        let image = QRCodeService.generate(from: "https://github.com")
        XCTAssertNotNil(image)
    }

    func testGenerateEmpty() {
        let image = QRCodeService.generate(from: "")
        XCTAssertNil(image)
    }

    func testCorrectionLevels() {
        for level in QRCodeService.CorrectionLevel.allCases {
            let image = QRCodeService.generate(from: "test", correctionLevel: level)
            XCTAssertNotNil(image, "Failed for correction level \(level.rawValue)")
        }
    }

    func testSavePNG() {
        guard let image = QRCodeService.generate(from: "test") else {
            XCTFail("No image"); return
        }
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_qr.png")
        let result = QRCodeService.savePNG(image: image, to: tmpURL)
        XCTAssertTrue(result)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpURL.path))
        try? FileManager.default.removeItem(at: tmpURL)
    }
}

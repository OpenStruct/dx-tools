import XCTest
@testable import DX_Tools

final class ColorServiceTests: XCTestCase {

    func testParseHex6() {
        let result = try! ColorService.parse("#FF5733").get()
        XCTAssertEqual(result.hex, "#FF5733")
        XCTAssertEqual(result.r, 255, accuracy: 1)
        XCTAssertEqual(result.g, 87, accuracy: 1)
        XCTAssertEqual(result.b, 51, accuracy: 1)
    }

    func testParseHex3() {
        let result = try! ColorService.parse("#F00").get()
        XCTAssertEqual(result.hex, "#FF0000")
        XCTAssertEqual(result.r, 255, accuracy: 1)
        XCTAssertEqual(result.g, 0, accuracy: 1)
    }

    func testParseHexWithoutHash() {
        let result = try! ColorService.parse("FF5733").get()
        XCTAssertEqual(result.hex, "#FF5733")
    }

    func testParseRGB() {
        let result = try! ColorService.parse("rgb(255, 87, 51)").get()
        XCTAssertEqual(result.hex, "#FF5733")
        XCTAssertEqual(result.rgb, "rgb(255, 87, 51)")
    }

    func testParseHSL() {
        let result = try! ColorService.parse("hsl(0, 100%, 50%)").get()
        XCTAssertEqual(result.r, 255, accuracy: 2)
        XCTAssertEqual(result.g, 0, accuracy: 2)
        XCTAssertEqual(result.b, 0, accuracy: 2)
    }

    func testParseBlack() {
        let result = try! ColorService.parse("#000000").get()
        XCTAssertEqual(result.r, 0)
        XCTAssertEqual(result.g, 0)
        XCTAssertEqual(result.b, 0)
    }

    func testParseWhite() {
        let result = try! ColorService.parse("#FFFFFF").get()
        XCTAssertEqual(result.r, 255)
        XCTAssertEqual(result.g, 255)
        XCTAssertEqual(result.b, 255)
    }

    func testInvalidHex() {
        let result = ColorService.parse("#ZZZZZZ")
        guard case .failure = result else { return XCTFail("Should fail for invalid hex") }
    }

    func testInvalidFormat() {
        let result = ColorService.parse("not a color")
        guard case .failure = result else { return XCTFail("Should fail for unknown format") }
    }

    func testCodeGeneration() {
        let result = try! ColorService.parse("#FF5733").get()
        XCTAssertTrue(result.swiftCode.contains("Color(red:"))
        XCTAssertTrue(result.cssCode.contains("color:"))
        XCTAssertTrue(result.swiftUICode.contains("Color(hex:"))
        XCTAssertTrue(result.androidCode.contains("Color.rgb"))
        XCTAssertTrue(result.flutterCode.contains("Color(0xFF"))
    }

    func testShades() {
        let result = try! ColorService.parse("#FF0000").get()
        XCTAssertEqual(result.shades.count, 10)
        // First shade (10%) should be darkest
        XCTAssertEqual(result.shades[0].percent, 10)
        // Last shade (100%) should be original
        XCTAssertEqual(result.shades[9].percent, 100)
    }

    func testHSLValues() {
        let result = try! ColorService.parse("#FF0000").get()
        XCTAssertEqual(result.h, 0, accuracy: 1)
        XCTAssertEqual(result.s, 100, accuracy: 1)
        XCTAssertEqual(result.l, 50, accuracy: 1)
    }

    func testRGBToHSLRoundTrip() {
        let (h, s, l) = ColorService.rgbToHSL(r: 1.0, g: 0.0, b: 0.0)
        let (r, g, b) = ColorService.hslToRGB(h: h, s: s / 100, l: l / 100)
        XCTAssertEqual(r, 1.0, accuracy: 0.01)
        XCTAssertEqual(g, 0.0, accuracy: 0.01)
        XCTAssertEqual(b, 0.0, accuracy: 0.01)
    }
}

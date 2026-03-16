import XCTest
@testable import DX_Tools

final class IconGeneratorServiceTests: XCTestCase {
    private func createTestImage(size: CGFloat = 1024) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: NSSize(width: size, height: size)).fill()
        image.unlockFocus()
        return image
    }

    func testResizeImage() {
        let source = createTestImage()
        let resized = IconGeneratorService.resize(source, to: CGSize(width: 64, height: 64))
        XCTAssertEqual(resized.size.width, 64)
        XCTAssertEqual(resized.size.height, 64)
    }

    func testIOSSizeCount() {
        XCTAssertEqual(IconGeneratorService.iosSizes.count, 8)
    }

    func testMacOSSizeCount() {
        XCTAssertEqual(IconGeneratorService.macosSizes.count, 10)
    }

    func testAndroidSizeCount() {
        XCTAssertEqual(IconGeneratorService.androidSizes.count, 6)
    }

    func testWebSizeCount() {
        XCTAssertEqual(IconGeneratorService.webSizes.count, 6)
    }

    func testGenerateIcons() {
        let source = createTestImage()
        let config = IconGeneratorService.IconConfig(platforms: [.macos], cornerRadius: 0, padding: 0)
        let icons = IconGeneratorService.generate(from: source, config: config)
        XCTAssertEqual(icons.count, 10)
        for icon in icons {
            XCTAssertFalse(icon.data.isEmpty)
        }
    }

    func testContentsJSON() {
        let source = createTestImage()
        let config = IconGeneratorService.IconConfig(platforms: [.ios])
        let icons = IconGeneratorService.generate(from: source, config: config)
        let json = IconGeneratorService.generateContentsJSON(for: icons)
        XCTAssertTrue(json.contains("images"))
        XCTAssertTrue(json.contains("filename"))
    }

    func testValidateGoodImage() {
        let image = createTestImage(size: 1024)
        let result = IconGeneratorService.validateSourceImage(image)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.warnings.isEmpty)
    }

    func testValidateSmallImage() {
        let image = createTestImage(size: 256)
        let result = IconGeneratorService.validateSourceImage(image)
        XCTAssertFalse(result.isValid)
        XCTAssertTrue(result.warnings.contains { $0.contains("1024") })
    }

    func testCornerRadius() {
        let image = createTestImage()
        let result = IconGeneratorService.applyCornerRadius(image, radius: 0.2)
        XCTAssertEqual(result.size.width, 1024)
    }

    func testPadding() {
        let image = createTestImage()
        let result = IconGeneratorService.applyPadding(image, padding: 0.1, backgroundColor: nil)
        XCTAssertEqual(result.size.width, image.size.width)
    }

    func testPNGData() {
        let image = createTestImage(size: 64)
        let data = IconGeneratorService.pngData(image)
        XCTAssertNotNil(data)
        XCTAssertTrue(data!.count > 0)
    }

    func testAllPlatforms() {
        let source = createTestImage()
        let config = IconGeneratorService.IconConfig(platforms: Set(IconGeneratorService.Platform.allCases))
        let icons = IconGeneratorService.generate(from: source, config: config)
        let platforms = Set(icons.map { $0.size.platform })
        XCTAssertEqual(platforms.count, 4)
    }
}

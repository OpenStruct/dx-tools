import XCTest
@testable import DX_Tools

final class ScreenshotServiceTests: XCTestCase {
    private func createTestImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 200, height: 200))
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: NSSize(width: 200, height: 200)).fill()
        image.unlockFocus()
        return image
    }

    func testRenderEmptyAnnotations() {
        let image = createTestImage()
        let rendered = ScreenshotService.render(image, annotations: [])
        XCTAssertEqual(rendered.size, image.size)
    }

    func testRenderArrow() {
        let image = createTestImage()
        let annotation = ScreenshotService.Annotation(type: .arrow, from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 100))
        let rendered = ScreenshotService.render(image, annotations: [annotation])
        XCTAssertEqual(rendered.size, image.size)
    }

    func testRenderRectangle() {
        let image = createTestImage()
        let annotation = ScreenshotService.Annotation(type: .rectangle, from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 100))
        let rendered = ScreenshotService.render(image, annotations: [annotation])
        XCTAssertEqual(rendered.size, image.size)
    }

    func testRenderText() {
        let image = createTestImage()
        let annotation = ScreenshotService.Annotation(type: .text, from: CGPoint(x: 50, y: 50), to: CGPoint(x: 50, y: 50), text: "Hello")
        let rendered = ScreenshotService.render(image, annotations: [annotation])
        XCTAssertEqual(rendered.size, image.size)
    }

    func testRenderMultiple() {
        let image = createTestImage()
        let annotations = [
            ScreenshotService.Annotation(type: .arrow, from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 100)),
            ScreenshotService.Annotation(type: .rectangle, from: CGPoint(x: 20, y: 20), to: CGPoint(x: 80, y: 80)),
            ScreenshotService.Annotation(type: .number, from: CGPoint(x: 50, y: 50), to: CGPoint(x: 50, y: 50), number: 1),
        ]
        let rendered = ScreenshotService.render(image, annotations: annotations)
        XCTAssertEqual(rendered.size, image.size)
    }

    func testPNGData() {
        let image = createTestImage()
        let data = ScreenshotService.pngData(image)
        XCTAssertNotNil(data)
        XCTAssertTrue(data!.count > 0)
    }

    func testThumbnail() {
        let image = createTestImage()
        let thumb = ScreenshotService.thumbnail(image, maxSize: 40)
        XCTAssertTrue(thumb.size.width <= 40)
        XCTAssertTrue(thumb.size.height <= 40)
    }

    func testCaptureFromClipboard() {
        // Put an image on clipboard, then retrieve
        let image = createTestImage()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
        let retrieved = ScreenshotService.captureFromClipboard()
        XCTAssertNotNil(retrieved)
    }
}

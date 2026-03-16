import AppKit

struct ScreenshotService {
    struct Screenshot: Identifiable {
        var id: UUID = UUID()
        var image: NSImage
        var timestamp: Date = Date()
        var size: CGSize
        var annotations: [Annotation] = []
    }

    enum AnnotationType: String, CaseIterable {
        case arrow = "Arrow"
        case rectangle = "Rectangle"
        case text = "Text"
        case highlight = "Highlight"
        case number = "Number"
    }

    struct Annotation: Identifiable {
        var id: UUID = UUID()
        var type: AnnotationType
        var from: CGPoint
        var to: CGPoint
        var color: NSColor = .red
        var lineWidth: CGFloat = 2
        var text: String = ""
        var number: Int = 1
    }

    // MARK: - Capture

    static func captureFullScreen() -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            CGRect.null,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.boundsIgnoreFraming]
        ) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    static func captureRegion(_ rect: CGRect) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.boundsIgnoreFraming]
        ) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }

    static func captureFromClipboard() -> NSImage? {
        NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage
    }

    // MARK: - Rendering

    static func render(_ image: NSImage, annotations: [Annotation]) -> NSImage {
        let rendered = NSImage(size: image.size)
        rendered.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: image.size))
        for annotation in annotations {
            switch annotation.type {
            case .arrow:
                drawArrow(from: annotation.from, to: annotation.to, color: annotation.color, width: annotation.lineWidth)
            case .rectangle:
                drawRectangle(from: annotation.from, to: annotation.to, color: annotation.color, width: annotation.lineWidth)
            case .text:
                drawText(annotation.text, at: annotation.from, color: annotation.color)
            case .highlight:
                drawHighlight(from: annotation.from, to: annotation.to, color: annotation.color)
            case .number:
                drawNumber(annotation.number, at: annotation.from, color: annotation.color)
            }
        }
        rendered.unlockFocus()
        return rendered
    }

    // MARK: - Drawing

    private static func drawArrow(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat) {
        let path = NSBezierPath()
        path.move(to: from)
        path.line(to: to)
        path.lineWidth = width
        color.setStroke()
        path.stroke()

        // Arrowhead
        let angle = atan2(to.y - from.y, to.x - from.x)
        let headLength: CGFloat = 12
        let head = NSBezierPath()
        head.move(to: to)
        head.line(to: CGPoint(x: to.x - headLength * cos(angle - .pi / 6),
                              y: to.y - headLength * sin(angle - .pi / 6)))
        head.move(to: to)
        head.line(to: CGPoint(x: to.x - headLength * cos(angle + .pi / 6),
                              y: to.y - headLength * sin(angle + .pi / 6)))
        head.lineWidth = width
        head.stroke()
    }

    private static func drawRectangle(from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat) {
        let rect = NSRect(x: min(from.x, to.x), y: min(from.y, to.y),
                         width: abs(to.x - from.x), height: abs(to.y - from.y))
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
        path.lineWidth = width
        color.setStroke()
        path.stroke()
    }

    private static func drawText(_ text: String, at point: CGPoint, color: NSColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: color,
            .backgroundColor: NSColor.white.withAlphaComponent(0.8)
        ]
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    private static func drawHighlight(from: CGPoint, to: CGPoint, color: NSColor) {
        let rect = NSRect(x: min(from.x, to.x), y: min(from.y, to.y),
                         width: abs(to.x - from.x), height: abs(to.y - from.y))
        color.withAlphaComponent(0.3).setFill()
        NSBezierPath(rect: rect).fill()
    }

    private static func drawNumber(_ number: Int, at point: CGPoint, color: NSColor) {
        let size: CGFloat = 24
        let rect = NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
        color.setFill()
        NSBezierPath(ovalIn: rect).fill()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let str = "\(number)"
        let textSize = (str as NSString).size(withAttributes: attrs)
        (str as NSString).draw(at: CGPoint(x: point.x - textSize.width/2, y: point.y - textSize.height/2), withAttributes: attrs)
    }

    // MARK: - Export

    static func pngData(_ image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    static func copyToClipboard(_ image: NSImage) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    static func saveAsPNG(_ image: NSImage, to url: URL) throws {
        guard let data = pngData(image) else { throw NSError(domain: "ScreenshotService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG"]) }
        try data.write(to: url)
    }

    static func thumbnail(_ image: NSImage, maxSize: CGFloat = 80) -> NSImage {
        let ratio = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = NSSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let thumb = NSImage(size: newSize)
        thumb.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: newSize))
        thumb.unlockFocus()
        return thumb
    }
}

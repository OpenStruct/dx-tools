import SwiftUI
import AppKit

@Observable
class ScreenshotViewModel {
    var currentScreenshot: ScreenshotService.Screenshot?
    var history: [ScreenshotService.Screenshot] = []
    var selectedTool: ScreenshotService.AnnotationType = .arrow
    var drawingColor: NSColor = .red
    var lineWidth: CGFloat = 2
    var annotationText: String = "Label"
    var nextNumber: Int = 1

    var displayImage: NSImage? {
        guard let ss = currentScreenshot else { return nil }
        if ss.annotations.isEmpty { return ss.image }
        return ScreenshotService.render(ss.image, annotations: ss.annotations)
    }

    func captureFullScreen() {
        if let image = ScreenshotService.captureFullScreen() {
            setScreenshot(image)
        }
    }

    func captureFromClipboard() {
        if let image = ScreenshotService.captureFromClipboard() {
            setScreenshot(image)
        }
    }

    func loadFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        if panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
            setScreenshot(image)
        }
    }

    private func setScreenshot(_ image: NSImage) {
        let ss = ScreenshotService.Screenshot(image: image, size: image.size)
        currentScreenshot = ss
        history.insert(ss, at: 0)
        if history.count > 20 { history = Array(history.prefix(20)) }
        nextNumber = 1
    }

    func addAnnotation(from: CGPoint, to: CGPoint) {
        guard currentScreenshot != nil else { return }
        var annotation = ScreenshotService.Annotation(type: selectedTool, from: from, to: to, color: drawingColor, lineWidth: lineWidth)
        if selectedTool == .text { annotation.text = annotationText }
        if selectedTool == .number { annotation.number = nextNumber; nextNumber += 1 }
        currentScreenshot?.annotations.append(annotation)
    }

    func undoAnnotation() {
        guard currentScreenshot != nil, !(currentScreenshot?.annotations.isEmpty ?? true) else { return }
        currentScreenshot?.annotations.removeLast()
    }

    func clearAnnotations() {
        currentScreenshot?.annotations.removeAll()
        nextNumber = 1
    }

    func copy() {
        guard let image = displayImage else { return }
        ScreenshotService.copyToClipboard(image)
    }

    func save() {
        guard let image = displayImage else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "screenshot.png"
        if panel.runModal() == .OK, let url = panel.url {
            try? ScreenshotService.saveAsPNG(image, to: url)
        }
    }

    func selectFromHistory(_ ss: ScreenshotService.Screenshot) {
        currentScreenshot = ss
    }
}

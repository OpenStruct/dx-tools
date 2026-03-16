---
name: dx-screenshot-tool
description: Build the Screenshot Tool for DX Tools. Capture screen regions, annotate with arrows/text/blur, copy/save/share. Uses ScreenCaptureKit and AppKit drawing. Follow dx-tools-feature skill for architecture.
---

# Screenshot Tool

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `screenshotTool`
- **Category**: `.generators`
- **Display name**: "Screenshot"
- **Icon**: `"camera.viewfinder"`
- **Description**: "Capture, annotate, and share screenshots with one shortcut"

## Service: `ScreenshotService.swift`

### Models

```swift
struct Screenshot: Identifiable {
    var id: UUID
    var image: NSImage
    var timestamp: Date
    var size: CGSize
    var annotations: [Annotation]
}

enum Annotation: Identifiable {
    case arrow(id: UUID, from: CGPoint, to: CGPoint, color: NSColor, width: CGFloat)
    case rectangle(id: UUID, rect: CGRect, color: NSColor, width: CGFloat, filled: Bool)
    case text(id: UUID, position: CGPoint, content: String, font: NSFont, color: NSColor)
    case blur(id: UUID, rect: CGRect, radius: CGFloat)
    case highlight(id: UUID, rect: CGRect, color: NSColor)
    case number(id: UUID, position: CGPoint, number: Int, color: NSColor)

    var id: UUID { /* return the id from each case */ }
}

enum CaptureMode {
    case fullScreen
    case window
    case region
    case clipboard      // From pasteboard
}
```

### Capture Methods

Use `CGWindowListCreateImage` for screen capture (simpler than ScreenCaptureKit, works without entitlements in dev):

```swift
import AppKit

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
```

### Annotation Rendering

```swift
static func render(_ image: NSImage, annotations: [Annotation]) -> NSImage {
    let rendered = NSImage(size: image.size)
    rendered.lockFocus()

    // Draw original image
    image.draw(in: NSRect(origin: .zero, size: image.size))

    for annotation in annotations {
        switch annotation {
        case .arrow(_, let from, let to, let color, let width):
            drawArrow(from: from, to: to, color: color, width: width)
        case .rectangle(_, let rect, let color, let width, let filled):
            drawRectangle(rect, color: color, width: width, filled: filled)
        case .text(_, let pos, let content, let font, let color):
            drawText(content, at: pos, font: font, color: color)
        case .blur(_, let rect, let radius):
            drawBlur(in: rect, radius: radius)
        case .highlight(_, let rect, let color):
            drawHighlight(rect, color: color)
        case .number(_, let pos, let num, let color):
            drawNumberBadge(num, at: pos, color: color)
        }
    }

    rendered.unlockFocus()
    return rendered
}
```

### Export

```swift
static func saveAsPNG(_ image: NSImage, to url: URL) throws
static func copyToClipboard(_ image: NSImage)
static func pngData(_ image: NSImage) -> Data?
```

## View: `ScreenshotView.swift`

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ ToolHeader: "Screenshot"  [Capture ▼] [Paste] [Save] [Copy] │
├─────────┬────────────────────────────────────────────────────┤
│ TOOLS   │                                                    │
│         │         Screenshot Canvas                          │
│ ➡ Arrow │                                                    │
│ ▢ Rect  │    ┌──────────────────────────────┐               │
│ T Text  │    │                              │               │
│ ◉ Blur  │    │     Captured screenshot      │               │
│ █ High  │    │     with annotations         │               │
│ ① Num   │    │     rendered on top          │               │
│         │    │                              │               │
│ ─────── │    └──────────────────────────────┘               │
│ Color   │                                                    │
│ [■■■■]  │                                                    │
│ Width   │                                                    │
│ [==●=]  │    Undo ⌘Z  |  Redo ⌘⇧Z  |  Clear All           │
├─────────┴────────────────────────────────────────────────────┤
│ HISTORY: [thumb1] [thumb2] [thumb3] [thumb4]                │
└──────────────────────────────────────────────────────────────┘
```

**Left toolbar:**
- Annotation tools: Arrow, Rectangle, Text, Blur, Highlight, Number badge
- Active tool highlighted with accent color
- Color picker (preset swatches: red, orange, blue, green, white, black)
- Line width slider

**Center canvas:**
- Display captured screenshot
- Draw annotations interactively (click and drag)
- Zoom/pan support (scroll to zoom, drag with space)
- When no screenshot: large drop zone "Capture or paste a screenshot"

**Top actions:**
- Capture dropdown: Full Screen, Region (opens overlay), Window, From Clipboard
- Save (NSSavePanel, PNG)
- Copy to clipboard
- Share (NSSharingServicePicker)

**Bottom history:**
- Thumbnails of recent screenshots (kept in memory, max 20)
- Click to switch back to a previous screenshot

### Interactive Drawing

The canvas should use an `NSView`-based `NSViewRepresentable` for smooth drawing:
- `mouseDown` → start annotation
- `mouseDragged` → update annotation preview
- `mouseUp` → finalize annotation
- Support undo/redo stack

## Tests: `ScreenshotServiceTests.swift`

Since capture needs screen access, test the processing methods:

- `testAnnotationArrow` — renders without crash
- `testAnnotationRectangle` — renders without crash
- `testAnnotationText` — text drawn at position
- `testAnnotationBlur` — blur applied in region
- `testRenderEmptyAnnotations` — image unchanged
- `testRenderMultipleAnnotations` — all applied
- `testPNGData` — returns valid PNG data
- `testCopyToClipboard` — image on pasteboard
- `testCaptureFromClipboard` — retrieves image
- `testImageResize` — for thumbnail generation

---
name: dx-icon-generator
description: Build the Icon Generator tool for DX Tools. Generate app icons for all platforms (iOS, macOS, Android, Web) from one source image. Resize, round corners, apply padding, export all sizes. Uses CoreImage/AppKit — no external deps. Follow dx-tools-feature skill for architecture.
---

# Icon Generator

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `iconGenerator`
- **Category**: `.generators`
- **Display name**: "Icon Generator"
- **Icon**: `"app.dashed"`
- **Description**: "Generate app icons for iOS, macOS, Android, and web from one image"

## Service: `IconGeneratorService.swift`

Use `AppKit` (`NSImage`, `NSBitmapImageRep`) for image processing — no external libraries.

### Models

```swift
enum Platform: String, CaseIterable {
    case ios = "iOS"
    case macos = "macOS"
    case android = "Android"
    case web = "Web"
    case watchos = "watchOS"
}

struct IconSize {
    var width: Int
    var height: Int
    var scale: Int              // 1x, 2x, 3x
    var idiom: String           // "iphone", "ipad", "mac", "universal"
    var filename: String        // "icon_40x40@2x.png"
    var platform: Platform
}

struct IconConfig {
    var platforms: Set<Platform>
    var cornerRadius: CGFloat   // 0 = square, 0.2 = iOS style (% of size)
    var padding: CGFloat        // 0-20% padding inside
    var backgroundColor: NSColor?  // Optional background fill
    var includeContentsJSON: Bool   // Generate Contents.json for Xcode
}

struct GeneratedIcon {
    var image: NSImage
    var size: IconSize
    var data: Data              // PNG data
}
```

### Platform Sizes

```swift
static let iosSizes: [IconSize] = [
    // iPhone
    IconSize(width: 40, height: 40, scale: 2, idiom: "iphone", filename: "icon_40x40@2x.png", platform: .ios),
    IconSize(width: 40, height: 40, scale: 3, idiom: "iphone", filename: "icon_40x40@3x.png", platform: .ios),
    IconSize(width: 60, height: 60, scale: 2, idiom: "iphone", filename: "icon_60x60@2x.png", platform: .ios),
    IconSize(width: 60, height: 60, scale: 3, idiom: "iphone", filename: "icon_60x60@3x.png", platform: .ios),
    // iPad
    IconSize(width: 76, height: 76, scale: 1, idiom: "ipad", ...),
    IconSize(width: 76, height: 76, scale: 2, idiom: "ipad", ...),
    IconSize(width: 83, height: 83, scale: 2, idiom: "ipad", ...),  // 83.5 rounds
    // App Store
    IconSize(width: 1024, height: 1024, scale: 1, idiom: "ios-marketing", ...),
]

static let macosSizes: [IconSize] = [
    // 16, 32, 128, 256, 512 at 1x and 2x
    IconSize(width: 16, height: 16, scale: 1, idiom: "mac", ...),
    IconSize(width: 16, height: 16, scale: 2, idiom: "mac", ...),
    // ... all 10 sizes
]

static let androidSizes: [IconSize] = [
    // mdpi (48), hdpi (72), xhdpi (96), xxhdpi (144), xxxhdpi (192)
    // + Play Store (512)
    // Adaptive icon foreground/background (108dp per density)
]

static let webSizes: [IconSize] = [
    // favicon: 16, 32, 48, 192, 512
    // apple-touch-icon: 180
    // og:image: 1200x630 (optional)
]
```

### Methods

```swift
// Core generation
static func generate(from image: NSImage, config: IconConfig) -> [GeneratedIcon]
static func resize(_ image: NSImage, to size: CGSize) -> NSImage
static func applyCornerRadius(_ image: NSImage, radius: CGFloat) -> NSImage
static func applyPadding(_ image: NSImage, padding: CGFloat, backgroundColor: NSColor?) -> NSImage

// Export
static func exportToDirectory(_ icons: [GeneratedIcon], directory: URL, includeContentsJSON: Bool) throws
static func generateContentsJSON(for icons: [GeneratedIcon], platform: Platform) -> String
static func exportAsZip(_ icons: [GeneratedIcon]) -> Data?  // Using Foundation's compression

// Preview
static func generatePreview(from image: NSImage, platform: Platform) -> NSImage  // Grid preview of all sizes

// Validation
static func validateSourceImage(_ image: NSImage) -> (isValid: Bool, warnings: [String])
// Minimum 1024x1024, square, not transparent if iOS
```

### Image Processing (AppKit)

```swift
static func resize(_ image: NSImage, to size: CGSize) -> NSImage {
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    image.draw(in: NSRect(origin: .zero, size: size),
               from: NSRect(origin: .zero, size: image.size),
               operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return newImage
}

static func applyCornerRadius(_ image: NSImage, radius: CGFloat) -> NSImage {
    let size = image.size
    let newImage = NSImage(size: size)
    newImage.lockFocus()
    let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                            xRadius: size.width * radius,
                            yRadius: size.height * radius)
    path.addClip()
    image.draw(in: NSRect(origin: .zero, size: size))
    newImage.unlockFocus()
    return newImage
}
```

## View: `IconGeneratorView.swift`

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ ToolHeader: "Icon Generator" [iOS macOS Android Web] [Export]│
├───────────────────────────┬──────────────────────────────────┤
│   SOURCE IMAGE            │  GENERATED ICONS                 │
│                           │                                  │
│  ┌───────────────────┐    │  ┌────┐ ┌────┐ ┌────┐ ┌────┐   │
│  │                   │    │  │ 16 │ │ 32 │ │128 │ │256 │   │
│  │   Drop image      │    │  └────┘ └────┘ └────┘ └────┘   │
│  │   or click to     │    │  ┌────┐ ┌─────────┐            │
│  │   browse          │    │  │512 │ │  1024   │            │
│  │                   │    │  └────┘ └─────────┘            │
│  └───────────────────┘    │                                  │
│                           │  12 icons generated              │
│  Corner Radius: [===●==]  │                                  │
│  Padding:       [==●===]  │  [Export All] [Save to Folder]   │
│  Background:    [■ #000]  │  [Copy Contents.json]            │
│                           │                                  │
│  Validation:              │                                  │
│  ✓ 1024x1024, square     │                                  │
│  ⚠ Has transparency      │                                  │
└───────────────────────────┴──────────────────────────────────┘
```

**Left panel — Source & config:**
- Large drop zone for source image (drag & drop + click to browse)
- Image preview after loading
- Sliders: corner radius (0-50%), padding (0-20%)
- Color picker for background (optional)
- Source image validation warnings
- Platform checkboxes: iOS, macOS, Android, Web (select multiple)

**Right panel — Generated icons:**
- Grid of generated icons at actual sizes (with labels showing dimensions)
- Total count and platform breakdown
- Export buttons: Save to folder (NSOpenPanel), Export as ZIP
- Copy Contents.json button (for Xcode asset catalogs)
- Click individual icon to copy it to clipboard

## Tests: `IconGeneratorServiceTests.swift`

- `testResizeImage` — output is correct dimensions
- `testIOSSizeCount` — correct number of iOS icon sizes
- `testMacOSSizeCount` — correct number (10 sizes)
- `testAndroidSizeCount` — correct density buckets
- `testWebSizeCount` — favicon + touch icon sizes
- `testContentsJSON` — valid JSON with correct entries
- `testValidateGoodImage` — 1024x1024 square passes
- `testValidateSmallImage` — warning for < 1024
- `testValidateNonSquare` — warning for non-square
- `testCornerRadius` — doesn't crash, output is valid
- `testPadding` — output dimensions unchanged
- `testAllPlatforms` — generates icons for all selected platforms

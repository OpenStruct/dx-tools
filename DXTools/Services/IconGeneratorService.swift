import AppKit

struct IconGeneratorService {
    enum Platform: String, CaseIterable {
        case ios = "iOS"
        case macos = "macOS"
        case android = "Android"
        case web = "Web"
    }

    struct IconSize {
        var width: Int
        var height: Int
        var scale: Int
        var idiom: String
        var filename: String
        var platform: Platform
    }

    struct IconConfig {
        var platforms: Set<Platform> = [.ios, .macos]
        var cornerRadius: CGFloat = 0
        var padding: CGFloat = 0
        var backgroundColor: NSColor?
    }

    struct GeneratedIcon: Identifiable {
        var id: String { size.filename }
        var image: NSImage
        var size: IconSize
        var data: Data
    }

    // MARK: - Platform Sizes

    static let iosSizes: [IconSize] = [
        IconSize(width: 40, height: 40, scale: 2, idiom: "iphone", filename: "icon_40x40@2x.png", platform: .ios),
        IconSize(width: 40, height: 40, scale: 3, idiom: "iphone", filename: "icon_40x40@3x.png", platform: .ios),
        IconSize(width: 60, height: 60, scale: 2, idiom: "iphone", filename: "icon_60x60@2x.png", platform: .ios),
        IconSize(width: 60, height: 60, scale: 3, idiom: "iphone", filename: "icon_60x60@3x.png", platform: .ios),
        IconSize(width: 76, height: 76, scale: 1, idiom: "ipad", filename: "icon_76x76.png", platform: .ios),
        IconSize(width: 76, height: 76, scale: 2, idiom: "ipad", filename: "icon_76x76@2x.png", platform: .ios),
        IconSize(width: 83, height: 83, scale: 2, idiom: "ipad", filename: "icon_83.5x83.5@2x.png", platform: .ios),
        IconSize(width: 1024, height: 1024, scale: 1, idiom: "ios-marketing", filename: "icon_1024x1024.png", platform: .ios),
    ]

    static let macosSizes: [IconSize] = [
        IconSize(width: 16, height: 16, scale: 1, idiom: "mac", filename: "icon_16x16.png", platform: .macos),
        IconSize(width: 16, height: 16, scale: 2, idiom: "mac", filename: "icon_16x16@2x.png", platform: .macos),
        IconSize(width: 32, height: 32, scale: 1, idiom: "mac", filename: "icon_32x32.png", platform: .macos),
        IconSize(width: 32, height: 32, scale: 2, idiom: "mac", filename: "icon_32x32@2x.png", platform: .macos),
        IconSize(width: 128, height: 128, scale: 1, idiom: "mac", filename: "icon_128x128.png", platform: .macos),
        IconSize(width: 128, height: 128, scale: 2, idiom: "mac", filename: "icon_128x128@2x.png", platform: .macos),
        IconSize(width: 256, height: 256, scale: 1, idiom: "mac", filename: "icon_256x256.png", platform: .macos),
        IconSize(width: 256, height: 256, scale: 2, idiom: "mac", filename: "icon_256x256@2x.png", platform: .macos),
        IconSize(width: 512, height: 512, scale: 1, idiom: "mac", filename: "icon_512x512.png", platform: .macos),
        IconSize(width: 512, height: 512, scale: 2, idiom: "mac", filename: "icon_512x512@2x.png", platform: .macos),
    ]

    static let androidSizes: [IconSize] = [
        IconSize(width: 48, height: 48, scale: 1, idiom: "mdpi", filename: "ic_launcher_mdpi.png", platform: .android),
        IconSize(width: 72, height: 72, scale: 1, idiom: "hdpi", filename: "ic_launcher_hdpi.png", platform: .android),
        IconSize(width: 96, height: 96, scale: 1, idiom: "xhdpi", filename: "ic_launcher_xhdpi.png", platform: .android),
        IconSize(width: 144, height: 144, scale: 1, idiom: "xxhdpi", filename: "ic_launcher_xxhdpi.png", platform: .android),
        IconSize(width: 192, height: 192, scale: 1, idiom: "xxxhdpi", filename: "ic_launcher_xxxhdpi.png", platform: .android),
        IconSize(width: 512, height: 512, scale: 1, idiom: "playstore", filename: "ic_launcher_playstore.png", platform: .android),
    ]

    static let webSizes: [IconSize] = [
        IconSize(width: 16, height: 16, scale: 1, idiom: "favicon", filename: "favicon-16x16.png", platform: .web),
        IconSize(width: 32, height: 32, scale: 1, idiom: "favicon", filename: "favicon-32x32.png", platform: .web),
        IconSize(width: 48, height: 48, scale: 1, idiom: "favicon", filename: "favicon-48x48.png", platform: .web),
        IconSize(width: 180, height: 180, scale: 1, idiom: "apple-touch", filename: "apple-touch-icon.png", platform: .web),
        IconSize(width: 192, height: 192, scale: 1, idiom: "pwa", filename: "icon-192x192.png", platform: .web),
        IconSize(width: 512, height: 512, scale: 1, idiom: "pwa", filename: "icon-512x512.png", platform: .web),
    ]

    static func sizesFor(_ platform: Platform) -> [IconSize] {
        switch platform {
        case .ios: return iosSizes
        case .macos: return macosSizes
        case .android: return androidSizes
        case .web: return webSizes
        }
    }

    // MARK: - Generation

    static func generate(from image: NSImage, config: IconConfig) -> [GeneratedIcon] {
        var icons: [GeneratedIcon] = []
        for platform in config.platforms {
            for size in sizesFor(platform) {
                let pixelSize = CGSize(width: size.width * size.scale, height: size.height * size.scale)
                var processed = resize(image, to: pixelSize)
                if config.padding > 0 {
                    processed = applyPadding(processed, padding: config.padding, backgroundColor: config.backgroundColor)
                }
                if config.cornerRadius > 0 {
                    processed = applyCornerRadius(processed, radius: config.cornerRadius)
                }
                if let data = pngData(processed) {
                    icons.append(GeneratedIcon(image: processed, size: size, data: data))
                }
            }
        }
        return icons
    }

    // MARK: - Image Processing

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

    static func applyPadding(_ image: NSImage, padding: CGFloat, backgroundColor: NSColor?) -> NSImage {
        let size = image.size
        let padAmount = size.width * padding
        let newSize = NSSize(width: size.width, height: size.height)
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        if let bg = backgroundColor {
            bg.setFill()
            NSRect(origin: .zero, size: newSize).fill()
        }
        let insetRect = NSRect(x: padAmount, y: padAmount,
                               width: size.width - padAmount * 2,
                               height: size.height - padAmount * 2)
        image.draw(in: insetRect, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    static func pngData(_ image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    // MARK: - Validation

    static func validateSourceImage(_ image: NSImage) -> (isValid: Bool, warnings: [String]) {
        var warnings: [String] = []
        let size = image.size
        if size.width < 1024 || size.height < 1024 {
            warnings.append("Image should be at least 1024×1024 (current: \(Int(size.width))×\(Int(size.height)))")
        }
        if abs(size.width - size.height) > 1 {
            warnings.append("Image should be square (\(Int(size.width))×\(Int(size.height)))")
        }
        return (warnings.isEmpty, warnings)
    }

    // MARK: - Export

    static func exportToDirectory(_ icons: [GeneratedIcon], directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for icon in icons {
            let fileURL = directory.appendingPathComponent(icon.size.filename)
            try icon.data.write(to: fileURL)
        }
    }

    static func generateContentsJSON(for icons: [GeneratedIcon]) -> String {
        var images: [[String: String]] = []
        for icon in icons {
            images.append([
                "size": "\(icon.size.width)x\(icon.size.height)",
                "idiom": icon.size.idiom,
                "filename": icon.size.filename,
                "scale": "\(icon.size.scale)x"
            ])
        }
        let json: [String: Any] = [
            "images": images,
            "info": ["version": 1, "author": "DX Tools"]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) else { return "{}" }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

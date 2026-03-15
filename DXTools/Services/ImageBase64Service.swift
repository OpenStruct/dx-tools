import Foundation
import AppKit

struct ImageBase64Service {
    enum ImageFormat: String, CaseIterable {
        case png = "PNG"
        case jpeg = "JPEG"

        var mimeType: String {
            switch self {
            case .png: return "image/png"
            case .jpeg: return "image/jpeg"
            }
        }
    }

    static func imageToBase64(data: Data, format: ImageFormat = .png) -> String? {
        return data.base64EncodedString()
    }

    static func dataURI(data: Data, format: ImageFormat = .png) -> String {
        let b64 = data.base64EncodedString()
        return "data:\(format.mimeType);base64,\(b64)"
    }

    static func base64ToImage(_ base64: String) -> NSImage? {
        var cleaned = base64.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip data URI prefix
        if let range = cleaned.range(of: "base64,") {
            cleaned = String(cleaned[range.upperBound...])
        }
        guard let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters) else { return nil }
        return NSImage(data: data)
    }

    static func imageData(from url: URL, as format: ImageFormat = .png) -> Data? {
        guard let image = NSImage(contentsOf: url),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }

        switch format {
        case .png:
            return bitmap.representation(using: .png, properties: [:])
        case .jpeg:
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }
    }
}

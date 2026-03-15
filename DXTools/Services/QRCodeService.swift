import Foundation
import CoreImage
import AppKit

struct QRCodeService {
    enum CorrectionLevel: String, CaseIterable {
        case low = "L"
        case medium = "M"
        case quartile = "Q"
        case high = "H"

        var label: String {
            switch self {
            case .low: return "Low (7%)"
            case .medium: return "Medium (15%)"
            case .quartile: return "Quartile (25%)"
            case .high: return "High (30%)"
            }
        }
    }

    static func generate(from text: String, correctionLevel: CorrectionLevel = .medium, size: CGFloat = 512) -> NSImage? {
        guard !text.isEmpty else { return nil }
        guard let data = text.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let scale = size / ciImage.extent.width
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let rep = NSCIImageRep(ciImage: transformed)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }

    static func savePNG(image: NSImage, to url: URL) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let png = bitmap.representation(using: .png, properties: [:]) else { return false }
        do {
            try png.write(to: url)
            return true
        } catch {
            return false
        }
    }
}

import SwiftUI
import UniformTypeIdentifiers

@Observable
class ImageBase64ViewModel {
    var base64Output: String = ""
    var dataURIOutput: String = ""
    var base64Input: String = ""
    var previewImage: NSImage?
    var decodedImage: NSImage?
    var format: ImageBase64Service.ImageFormat = .png
    var fileName: String = ""
    var fileSize: String = ""
    var mode: Mode = .encode

    enum Mode: String, CaseIterable {
        case encode = "Image → Base64"
        case decode = "Base64 → Image"
    }

    func loadImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .gif, .bmp, .tiff]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            processImageFile(url)
        }
    }

    func processImageFile(_ url: URL) {
        fileName = url.lastPathComponent
        guard let data = ImageBase64Service.imageData(from: url, as: format) else { return }
        fileSize = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        previewImage = NSImage(contentsOf: url)
        base64Output = data.base64EncodedString()
        dataURIOutput = ImageBase64Service.dataURI(data: data, format: format)
    }

    func decodeBase64() {
        decodedImage = ImageBase64Service.base64ToImage(base64Input)
    }

    func copyBase64() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(base64Output, forType: .string)
    }

    func copyDataURI() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(dataURIOutput, forType: .string)
    }

    func saveDecodedImage() {
        guard let img = decodedImage else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "decoded.png"
        panel.allowedContentTypes = [.png]
        if panel.runModal() == .OK, let url = panel.url {
            if let tiff = img.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                try? png.write(to: url)
            }
        }
    }
}

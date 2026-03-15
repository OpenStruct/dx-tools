import SwiftUI

@Observable
class QRCodeViewModel {
    var input: String = ""
    var correctionLevel: QRCodeService.CorrectionLevel = .medium
    var qrImage: NSImage?

    func generate() {
        qrImage = QRCodeService.generate(from: input, correctionLevel: correctionLevel)
    }

    func copyImage() {
        guard let img = qrImage else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
    }

    func saveImage() {
        guard let img = qrImage else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "qrcode.png"
        panel.allowedContentTypes = [.png]
        if panel.runModal() == .OK, let url = panel.url {
            _ = QRCodeService.savePNG(image: img, to: url)
        }
    }
}

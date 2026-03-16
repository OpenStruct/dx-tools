import SwiftUI
import AppKit

@Observable
class IconGeneratorViewModel {
    var sourceImage: NSImage?
    var generatedIcons: [IconGeneratorService.GeneratedIcon] = []
    var selectedPlatforms: Set<IconGeneratorService.Platform> = [.ios, .macos]
    var cornerRadius: CGFloat = 0
    var padding: CGFloat = 0
    var validationWarnings: [String] = []
    var isGenerated: Bool = false

    func loadImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            sourceImage = NSImage(contentsOf: url)
            if let img = sourceImage {
                let result = IconGeneratorService.validateSourceImage(img)
                validationWarnings = result.warnings
            }
            isGenerated = false
            generatedIcons = []
        }
    }

    func loadFromClipboard() {
        if let img = NSPasteboard.general.readObjects(forClasses: [NSImage.self])?.first as? NSImage {
            sourceImage = img
            let result = IconGeneratorService.validateSourceImage(img)
            validationWarnings = result.warnings
            isGenerated = false
            generatedIcons = []
        }
    }

    func generate() {
        guard let image = sourceImage else { return }
        let config = IconGeneratorService.IconConfig(
            platforms: selectedPlatforms,
            cornerRadius: cornerRadius / 100,
            padding: padding / 100,
            backgroundColor: nil
        )
        generatedIcons = IconGeneratorService.generate(from: image, config: config)
        isGenerated = true
    }

    func togglePlatform(_ p: IconGeneratorService.Platform) {
        if selectedPlatforms.contains(p) {
            selectedPlatforms.remove(p)
        } else {
            selectedPlatforms.insert(p)
        }
    }

    func exportToFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        if panel.runModal() == .OK, let url = panel.url {
            let exportDir = url.appendingPathComponent("AppIcons")
            try? IconGeneratorService.exportToDirectory(generatedIcons, directory: exportDir)
            // Write Contents.json
            let json = IconGeneratorService.generateContentsJSON(for: generatedIcons)
            try? json.write(to: exportDir.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
        }
    }

    func copyContentsJSON() {
        let json = IconGeneratorService.generateContentsJSON(for: generatedIcons)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(json, forType: .string)
    }
}

import SwiftUI

@Observable
class LoremViewModel {
    var output: String = ""
    var mode: Mode = .paragraphs
    var count: Int = 3
    var copied: Bool = false

    enum Mode: String, CaseIterable {
        case paragraphs = "Paragraphs"
        case sentences = "Sentences"
        case words = "Words"
        case names = "Names"
        case emails = "Emails"
        case phones = "Phones"
        case addresses = "Addresses"
        case json = "JSON Data"
    }

    func generate() {
        switch mode {
        case .paragraphs: output = LoremService.generateParagraphs(count)
        case .sentences: output = (0..<count).map { _ in LoremService.generateSentence() }.joined(separator: "\n")
        case .words: output = LoremService.generateWords(count)
        case .names: output = (0..<count).map { _ in LoremService.generateName() }.joined(separator: "\n")
        case .emails: output = (0..<count).map { _ in LoremService.generateEmail() }.joined(separator: "\n")
        case .phones: output = (0..<count).map { _ in LoremService.generatePhone() }.joined(separator: "\n")
        case .addresses: output = (0..<count).map { _ in LoremService.generateAddress() }.joined(separator: "\n")
        case .json: output = LoremService.generateJSON(count: count)
        }
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.copied = false
        }
    }

    init() { generate() }
}

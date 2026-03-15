import SwiftUI

@Observable
class URLCoderViewModel {
    var input = ""
    var encoded = ""
    var decoded = ""
    var urlParts: URLCoderService.URLParts?
    var mode: Mode = .encode

    enum Mode: String, CaseIterable { case encode = "Encode", decode = "Decode", parse = "Parse URL" }

    func process() {
        switch mode {
        case .encode:
            encoded = URLCoderService.encode(input)
        case .decode:
            decoded = URLCoderService.decode(input)
        case .parse:
            urlParts = URLCoderService.decompose(input)
        }
    }

    func copyResult() {
        let text: String
        switch mode {
        case .encode: text = encoded
        case .decode: text = decoded
        case .parse: text = urlParts.map { "\($0.scheme)://\($0.host)\($0.path)" } ?? ""
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

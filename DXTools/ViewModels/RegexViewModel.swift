import SwiftUI

@Observable
class RegexViewModel {
    var pattern: String = ""
    var input: String = ""
    var replacement: String = ""
    var result: RegexService.Result?
    var replaceResult: String?
    var errorMessage: String?
    var showReplace: Bool = false
    var flags = RegexService.Flags()

    func test() {
        guard !pattern.isEmpty, !input.isEmpty else {
            result = nil; errorMessage = nil; return
        }
        switch RegexService.test(pattern: pattern, input: input, flags: flags) {
        case .success(let r): result = r; errorMessage = nil
        case .failure(let e): result = nil; errorMessage = e.localizedDescription
        }
    }

    func replace() {
        guard !pattern.isEmpty, !input.isEmpty else { return }
        switch RegexService.replace(pattern: pattern, input: input, replacement: replacement, flags: flags) {
        case .success(let r): replaceResult = r
        case .failure(let e): errorMessage = e.localizedDescription
        }
    }

    func loadSample() {
        pattern = "(\\w+)@(\\w+\\.\\w+)"
        input = """
        Contact us at support@example.com or sales@company.io
        Personal: john.doe@gmail.com, jane@outlook.com
        Invalid: not-an-email, @missing.com
        """
        replacement = "[$1 at $2]"
        test()
    }

    func clear() {
        pattern = ""; input = ""; replacement = ""
        result = nil; replaceResult = nil; errorMessage = nil
    }
}

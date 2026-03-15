import SwiftUI

@Observable
class SQLFormatterViewModel {
    var input: String = ""
    var output: String = ""
    var indent: SQLFormatterService.IndentStyle = .twoSpaces

    func format() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""
            return
        }
        output = SQLFormatterService.format(input, indent: indent)
    }

    func minify() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        output = SQLFormatterService.minify(input)
    }

    func sample() {
        input = "SELECT u.id, u.name, u.email, o.total FROM users u INNER JOIN orders o ON u.id = o.user_id WHERE u.active = 1 AND o.total > 100 ORDER BY o.total DESC LIMIT 10;"
        format()
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
}

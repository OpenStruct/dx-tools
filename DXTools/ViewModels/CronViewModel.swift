import SwiftUI

@Observable
class CronViewModel {
    var expression = "*/5 * * * *"
    var result: CronService.CronResult?

    init() { parse() }

    func parse() {
        result = CronService.parse(expression)
    }

    func loadExample(_ expr: String) {
        expression = expr
        parse()
    }

    func copyExpression() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(expression, forType: .string)
    }
}

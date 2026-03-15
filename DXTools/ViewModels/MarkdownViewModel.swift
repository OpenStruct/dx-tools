import SwiftUI

@Observable
class MarkdownViewModel {
    var input: String = ""
    var htmlOutput: String = ""

    func render() {
        let body = MarkdownService.toHTML(input)
        htmlOutput = MarkdownService.wrapInHTMLPage(body, darkMode: true)
    }

    func loadSample() {
        input = """
        # DX Tools

        A **Swiss Army knife** for developers. Built with *Swift*.

        ## Features

        - JSON Formatter with syntax highlighting
        - Code generation (Go, Swift, TypeScript)
        - JWT token decoder
        - ~~Boring CLI~~ Beautiful native app

        ### Code Example

        ```swift
        let dx = DXTools()
        dx.formatJSON(input)
        ```

        > "The best developer tool is the one you actually use." — Someone wise

        ## Links

        Check out [GitHub](https://github.com) for more tools.

        ---

        ### Quick Stats

        1. 12+ tools in one app
        2. Zero dependencies
        3. Native macOS performance
        4. Built with ***SwiftUI***

        Inline `code` looks like this.
        """
        render()
    }

    func copyHTML() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(htmlOutput, forType: .string)
    }

    func clear() { input = ""; htmlOutput = "" }
}

import Foundation

struct MarkdownService {

    static func toHTML(_ markdown: String) -> String {
        var lines = markdown.components(separatedBy: "\n")
        var html: [String] = []
        var inCodeBlock = false
        var codeBuffer: [String] = []
        var codeLang = ""

        for line in lines {
            // Fenced code blocks
            if line.hasPrefix("```") {
                if inCodeBlock {
                    html.append("<pre><code class=\"language-\(codeLang)\">\(escapeHTML(codeBuffer.joined(separator: "\n")))</code></pre>")
                    codeBuffer = []
                    inCodeBlock = false
                } else {
                    codeLang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    inCodeBlock = true
                }
                continue
            }
            if inCodeBlock {
                codeBuffer.append(line)
                continue
            }

            var processed = line

            // Headers
            if processed.hasPrefix("######") { processed = "<h6>\(String(processed.dropFirst(7)))</h6>" }
            else if processed.hasPrefix("#####") { processed = "<h5>\(String(processed.dropFirst(6)))</h5>" }
            else if processed.hasPrefix("####") { processed = "<h4>\(String(processed.dropFirst(5)))</h4>" }
            else if processed.hasPrefix("###") { processed = "<h3>\(String(processed.dropFirst(4)))</h3>" }
            else if processed.hasPrefix("##") { processed = "<h2>\(String(processed.dropFirst(3)))</h2>" }
            else if processed.hasPrefix("#") { processed = "<h1>\(String(processed.dropFirst(2)))</h1>" }
            // HR
            else if processed.trimmingCharacters(in: .whitespaces).hasPrefix("---") { processed = "<hr>" }
            // Blockquote
            else if processed.hasPrefix("> ") { processed = "<blockquote>\(String(processed.dropFirst(2)))</blockquote>" }
            // List items
            else if processed.hasPrefix("- ") || processed.hasPrefix("* ") { processed = "<li>\(String(processed.dropFirst(2)))</li>" }
            else if let numMatch = processed.range(of: "^\\d+\\. ", options: .regularExpression) {
                processed = "<li>\(String(processed[numMatch.upperBound...]))</li>"
            }
            // Empty line
            else if processed.trimmingCharacters(in: .whitespaces).isEmpty { processed = "" }
            // Paragraph
            else if !processed.hasPrefix("<") { processed = "<p>\(processed)</p>" }

            // Inline formatting
            processed = applyInlineFormatting(processed)

            html.append(processed)
        }

        return html.joined(separator: "\n")
    }

    private static func applyInlineFormatting(_ text: String) -> String {
        var result = text
        // Images
        result = regexReplace(result, "!\\[([^\\]]*)\\]\\(([^)]+)\\)", "<img src=\"$2\" alt=\"$1\">")
        // Links
        result = regexReplace(result, "\\[([^\\]]*)\\]\\(([^)]+)\\)", "<a href=\"$2\">$1</a>")
        // Bold+Italic
        result = regexReplace(result, "\\*\\*\\*(.+?)\\*\\*\\*", "<strong><em>$1</em></strong>")
        // Bold
        result = regexReplace(result, "\\*\\*(.+?)\\*\\*", "<strong>$1</strong>")
        // Italic
        result = regexReplace(result, "\\*(.+?)\\*", "<em>$1</em>")
        // Strikethrough
        result = regexReplace(result, "~~(.+?)~~", "<del>$1</del>")
        // Inline code
        result = regexReplace(result, "`([^`]+)`", "<code>$1</code>")
        return result
    }

    private static func regexReplace(_ input: String, _ pattern: String, _ template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }

    private static func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func wrapInHTMLPage(_ body: String, darkMode: Bool = true) -> String {
        let bg = darkMode ? "#1e1e1e" : "#ffffff"
        let fg = darkMode ? "#d4d4d4" : "#1e1e1e"
        let codeBg = darkMode ? "#2d2d2d" : "#f5f5f5"
        let borderColor = darkMode ? "#404040" : "#e0e0e0"
        let linkColor = darkMode ? "#6bb5ff" : "#0066cc"

        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
                font-size: 14px; line-height: 1.7; color: \(fg); background: \(bg);
                padding: 24px; max-width: 800px;
            }
            h1, h2, h3, h4, h5, h6 { margin: 20px 0 10px; font-weight: 600; }
            h1 { font-size: 28px; border-bottom: 1px solid \(borderColor); padding-bottom: 8px; }
            h2 { font-size: 22px; border-bottom: 1px solid \(borderColor); padding-bottom: 6px; }
            h3 { font-size: 18px; } h4 { font-size: 16px; }
            p { margin: 8px 0; }
            a { color: \(linkColor); text-decoration: none; }
            a:hover { text-decoration: underline; }
            code {
                font-family: 'SF Mono', Menlo, monospace; font-size: 13px;
                background: \(codeBg); padding: 2px 6px; border-radius: 4px;
            }
            pre { margin: 12px 0; }
            pre code {
                display: block; padding: 16px; border-radius: 8px;
                overflow-x: auto; background: \(codeBg); border: 1px solid \(borderColor);
            }
            blockquote {
                border-left: 3px solid \(linkColor); padding: 8px 16px;
                margin: 12px 0; font-style: italic; opacity: 0.85;
            }
            li { margin: 4px 0; padding-left: 8px; list-style-position: inside; }
            hr { border: none; border-top: 1px solid \(borderColor); margin: 20px 0; }
            img { max-width: 100%; border-radius: 8px; margin: 8px 0; }
            del { opacity: 0.5; }
        </style></head><body>\(body)</body></html>
        """
    }
}

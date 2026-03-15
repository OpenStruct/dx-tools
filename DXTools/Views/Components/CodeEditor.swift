import SwiftUI

struct CodeEditor: View {
    @Binding var text: String
    var isEditable: Bool = true
    var font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    var language: String = "json"
    @Environment(\.colorScheme) private var colorScheme

    private var lineCount: Int {
        max(text.components(separatedBy: "\n").count, 1)
    }

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: 0) {
            // Line numbers gutter
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...max(lineCount, 30), id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(isDark
                                ? Color(red: 0.29, green: 0.29, blue: 0.35)
                                : Color(red: 0.6, green: 0.6, blue: 0.66))
                            .frame(height: 18.5)
                    }
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
                .padding(.leading, 8)
            }
            .frame(width: 42)
            .background(isDark
                ? Color(red: 0.047, green: 0.047, blue: 0.055)
                : Color(red: 0.96, green: 0.96, blue: 0.97))

            // Divider
            Rectangle()
                .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.08))
                .frame(width: 0.5)

            // Editor
            if isEditable {
                TextEditor(text: $text)
                    .font(.system(size: CGFloat(font.pointSize), design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(isDark
                        ? Color(red: 0.059, green: 0.059, blue: 0.075)
                        : Color(red: 0.98, green: 0.98, blue: 0.99))
            } else {
                ScrollView {
                    Text(attributedText)
                        .font(.system(size: CGFloat(font.pointSize), design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .background(isDark
                    ? Color(red: 0.059, green: 0.059, blue: 0.075)
                    : Color(red: 0.98, green: 0.98, blue: 0.99))
            }
        }
    }

    // Syntax highlighting for read-only output
    private var attributedText: AttributedString {
        guard language == "json", !text.isEmpty else {
            var s = AttributedString(text)
            s.foregroundColor = isDark
                ? Color(red: 0.94, green: 0.94, blue: 0.96)
                : Color(red: 0.07, green: 0.07, blue: 0.09)
            return s
        }
        return highlightJSON(text)
    }

    private func highlightJSON(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        let defaultColor: Color = isDark
            ? Color(red: 0.94, green: 0.94, blue: 0.96)
            : Color(red: 0.07, green: 0.07, blue: 0.09)
        result.foregroundColor = defaultColor

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        let theme = isDark ? SyntaxTheme.dark : SyntaxTheme.light
        let patterns: [(String, Color)] = [
            ("\"([^\"\\\\]|\\\\.)*\"\\s*:", theme.key),
            ("(?<=:\\s)\"([^\"\\\\]|\\\\.)*\"", theme.string),
            ("(?<=[:\\[,\\s])-?\\d+\\.?\\d*(?=[,\\s\\]\\}])", theme.number),
            ("\\b(true|false|null)\\b", theme.boolean),
            ("[\\{\\}\\[\\]]", theme.brace),
        ]

        for (pattern, color) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            for match in regex.matches(in: text, range: fullRange) {
                if let range = Range(match.range, in: text),
                   let attrRange = Range<AttributedString.Index>(range, in: result) {
                    result[attrRange].foregroundColor = color
                }
            }
        }

        return result
    }
}



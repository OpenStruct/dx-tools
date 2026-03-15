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

            Rectangle()
                .fill(isDark ? Color.white.opacity(0.06) : Color.black.opacity(0.08))
                .frame(width: 0.5)

            if isEditable {
                HighlightedTextEditor(text: $text, language: language, isDark: isDark, fontSize: font.pointSize)
            } else {
                ScrollView {
                    Text(highlightedAttributedString(text, language: language, isDark: isDark))
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
}

// MARK: - NSTextView wrapper with syntax highlighting

struct HighlightedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var language: String
    var isDark: Bool
    var fontSize: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()

        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 6, height: 8)
        textView.drawsBackground = true
        textView.backgroundColor = isDark
            ? NSColor(red: 0.059, green: 0.059, blue: 0.075, alpha: 1)
            : NSColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
        textView.insertionPointColor = isDark ? .white : .black
        textView.textColor = isDark
            ? NSColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
            : NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)

        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false

        context.coordinator.textView = textView

        // Initial text
        DispatchQueue.main.async {
            textView.string = text
            context.coordinator.applyHighlighting()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }

        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            context.coordinator.applyHighlighting()
            // Restore cursor if valid
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(NSRange(location: min(selectedRange.location, textView.string.count), length: 0))
            }
        }

        // Update background for theme changes
        textView.backgroundColor = isDark
            ? NSColor(red: 0.059, green: 0.059, blue: 0.075, alpha: 1)
            : NSColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1)
        textView.insertionPointColor = isDark ? .white : .black
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: HighlightedTextEditor
        weak var textView: NSTextView?
        private var isUpdating = false

        init(_ parent: HighlightedTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let tv = textView else { return }
            parent.text = tv.string
            applyHighlighting()
        }

        func applyHighlighting() {
            guard let tv = textView else { return }
            let text = tv.string
            guard !text.isEmpty else { return }

            isUpdating = true
            let storage = tv.textStorage!
            let fullRange = NSRange(location: 0, length: storage.length)

            storage.beginEditing()

            // Default color
            let defaultColor: NSColor = parent.isDark
                ? NSColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
                : NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1)
            storage.addAttribute(.foregroundColor, value: defaultColor, range: fullRange)
            storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular), range: fullRange)

            let theme = parent.isDark ? SyntaxTheme.dark : SyntaxTheme.light

            let patterns: [(String, NSColor)] = [
                ("\"([^\"\\\\]|\\\\.)*\"\\s*:", nsColor(theme.key)),
                ("(?<=:\\s)\"([^\"\\\\]|\\\\.)*\"", nsColor(theme.string)),
                ("(?<=[:\\[,\\s])-?\\d+\\.?\\d*(?=[,\\s\\]\\}])", nsColor(theme.number)),
                ("\\b(true|false|null)\\b", nsColor(theme.boolean)),
                ("[\\{\\}\\[\\]]", nsColor(theme.brace)),
                ("//.*$", nsColor(.gray)), // line comments
                ("/\\*[\\s\\S]*?\\*/", nsColor(.gray)), // block comments
            ]

            for (pattern, color) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else { continue }
                for match in regex.matches(in: text, range: fullRange) {
                    storage.addAttribute(.foregroundColor, value: color, range: match.range)
                }
            }

            storage.endEditing()
            isUpdating = false
        }

        private func nsColor(_ swiftColor: Color) -> NSColor {
            NSColor(swiftColor)
        }
    }
}

// Shared highlighting function for read-only AttributedString
func highlightedAttributedString(_ text: String, language: String, isDark: Bool) -> AttributedString {
    guard language == "json" || language == "sql", !text.isEmpty else {
        var s = AttributedString(text)
        s.foregroundColor = isDark
            ? Color(red: 0.94, green: 0.94, blue: 0.96)
            : Color(red: 0.07, green: 0.07, blue: 0.09)
        return s
    }

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

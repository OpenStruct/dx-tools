import SwiftUI
import AppKit

struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    var isEditable: Bool = true
    var font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)
    var language: String = "json"
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        // Use Apple's factory method — properly sets up the full text system
        let scrollView = DXTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        // Replace with our subclass by swapping the text container
        let dxTextView = DXTextView()
        dxTextView.textStorage?.removeLayoutManager(dxTextView.layoutManager!)
        textView.textContainer.map { dxTextView.replaceTextContainer($0) }
        // Actually, we can't easily swap. Let's configure the existing textView instead.
        // We'll use the standard NSTextView and override via the coordinator.

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.font = font
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.usesFindPanel = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextCompletionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 14)
        textView.delegate = context.coordinator

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay

        // Line ruler
        let ruler = LineNumberRulerView(textView: textView)
        scrollView.hasVerticalRuler = true
        scrollView.verticalRulerView = ruler
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.lineRuler = ruler

        updateAppearance(textView, ruler)
        textView.string = text
        if !text.isEmpty && language == "json" {
            context.coordinator.applySyntaxHighlighting(textView)
        }

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionDidChange(_:)),
            name: NSTextView.didChangeSelectionNotification,
            object: textView
        )

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        let ruler = scrollView.verticalRulerView as? LineNumberRulerView

        textView.isEditable = isEditable
        updateAppearance(textView, ruler)

        if textView.string != text {
            let ranges = textView.selectedRanges
            context.coordinator.isUpdating = true
            textView.string = text
            textView.selectedRanges = ranges
            context.coordinator.isUpdating = false
            if language == "json" {
                context.coordinator.applySyntaxHighlighting(textView)
            }
            ruler?.needsDisplay = true
        }
    }

    private func updateAppearance(_ textView: NSTextView, _ ruler: LineNumberRulerView?) {
        let isDark = colorScheme == .dark
        textView.backgroundColor = isDark
            ? NSColor(red: 0.059, green: 0.059, blue: 0.075, alpha: 1.0)
            : NSColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
        textView.insertionPointColor = isDark
            ? NSColor(red: 1.0, green: 0.55, blue: 0.26, alpha: 1.0)
            : NSColor(red: 0.91, green: 0.45, blue: 0.1, alpha: 1.0)
        textView.selectedTextAttributes = [
            .backgroundColor: isDark
                ? NSColor(red: 1.0, green: 0.55, blue: 0.26, alpha: 0.12)
                : NSColor(red: 0.91, green: 0.45, blue: 0.1, alpha: 0.1)
        ]
        let defaultColor = isDark
            ? NSColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
            : NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: defaultColor
        ]

        if let ruler = ruler {
            ruler.backgroundColor = isDark
                ? NSColor(red: 0.047, green: 0.047, blue: 0.055, alpha: 1.0)
                : NSColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
            ruler.lineNumberColor = isDark
                ? NSColor(red: 0.29, green: 0.29, blue: 0.35, alpha: 1.0)
                : NSColor(red: 0.6, green: 0.6, blue: 0.66, alpha: 1.0)
            ruler.isDark = isDark
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditor
        weak var textView: NSTextView?
        weak var lineRuler: LineNumberRulerView?
        var isUpdating = false
        private var bracketHighlights: [NSRange] = []

        init(_ parent: CodeEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let tv = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = tv.string
            if parent.language == "json" {
                applySyntaxHighlighting(tv)
            }
            lineRuler?.needsDisplay = true
            isUpdating = false
        }

        // Handle tab key for 2-space indent
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("  ", replacementRange: textView.selectedRange())
                return true
            }
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                let text = textView.string as NSString
                let loc = textView.selectedRange().location
                let lineRange = text.lineRange(for: NSRange(location: loc, length: 0))
                let line = text.substring(with: lineRange)
                let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
                var extra = ""
                if loc > 0 {
                    let prev = text.character(at: loc - 1)
                    if prev == 123 || prev == 91 { extra = "  " }
                }
                textView.insertText("\n\(indent)\(extra)", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }

        @objc func selectionDidChange(_ notification: Notification) {
            guard let tv = textView else { return }
            highlightMatchingBracket(tv)
        }

        func highlightMatchingBracket(_ tv: NSTextView) {
            guard let storage = tv.textStorage else { return }
            for range in bracketHighlights where range.location + range.length <= storage.length {
                storage.removeAttribute(.backgroundColor, range: range)
            }
            bracketHighlights = []

            let str = tv.string as NSString
            let pos = tv.selectedRange().location
            guard pos > 0, pos <= str.length else { return }

            let pairs: [(Character, Character)] = [("{", "}"), ("[", "]"), ("(", ")")]
            let ch = Character(UnicodeScalar(str.character(at: pos - 1))!)

            for (open, close) in pairs {
                if ch == close, let m = findMatch(str as String, pos - 1, open, close, false) {
                    markBrackets(storage, [m, pos - 1], tv)
                } else if ch == open, let m = findMatch(str as String, pos - 1, open, close, true) {
                    markBrackets(storage, [pos - 1, m], tv)
                }
            }
        }

        private func findMatch(_ str: String, _ pos: Int, _ open: Character, _ close: Character, _ fwd: Bool) -> Int? {
            let chars = Array(str)
            var depth = 0
            if fwd {
                for i in pos..<chars.count {
                    if chars[i] == open { depth += 1 } else if chars[i] == close { depth -= 1 }
                    if depth == 0 { return i }
                }
            } else {
                for i in stride(from: pos, through: 0, by: -1) {
                    if chars[i] == close { depth += 1 } else if chars[i] == open { depth -= 1 }
                    if depth == 0 { return i }
                }
            }
            return nil
        }

        private func markBrackets(_ storage: NSTextStorage, _ positions: [Int], _ tv: NSTextView) {
            let isDark = tv.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let color = isDark
                ? NSColor(red: 1.0, green: 0.55, blue: 0.26, alpha: 0.2)
                : NSColor(red: 0.91, green: 0.45, blue: 0.1, alpha: 0.15)
            storage.beginEditing()
            for p in positions where p < storage.length {
                let r = NSRange(location: p, length: 1)
                storage.addAttribute(.backgroundColor, value: color, range: r)
                bracketHighlights.append(r)
            }
            storage.endEditing()
        }

        func applySyntaxHighlighting(_ textView: NSTextView) {
            let text = textView.string
            guard !text.isEmpty, let storage = textView.textStorage else { return }
            let full = NSRange(location: 0, length: storage.length)

            let isDark = textView.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            let theme = isDark ? SyntaxTheme.dark : SyntaxTheme.light
            let defaultColor = isDark
                ? NSColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1.0)
                : NSColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1.0)

            storage.beginEditing()
            storage.addAttribute(.foregroundColor, value: defaultColor, range: full)
            storage.addAttribute(.font, value: parent.font, range: full)

            hl(storage, "\"([^\"\\\\]|\\\\.)*\"\\s*:", text, NSColor(theme.key))
            hl(storage, "(?<=:\\s)\"([^\"\\\\]|\\\\.)*\"", text, NSColor(theme.string))
            hl(storage, "(?<=[:\\[,\\s])-?\\d+\\.?\\d*(?=[,\\s\\]\\}])", text, NSColor(theme.number))
            hl(storage, "\\b(true|false|null)\\b", text, NSColor(theme.boolean))
            hl(storage, "[\\{\\}\\[\\]]", text, NSColor(theme.brace))
            storage.endEditing()
        }

        private func hl(_ s: NSTextStorage, _ pattern: String, _ text: String, _ color: NSColor) {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
            let range = NSRange(location: 0, length: (text as NSString).length)
            for m in regex.matches(in: text, range: range) {
                s.addAttribute(.foregroundColor, value: color, range: m.range)
            }
        }
    }
}

// MARK: - DXTextView (only used for scrollableTextView factory)

class DXTextView: NSTextView {
}

// MARK: - Line Number Ruler

class LineNumberRulerView: NSRulerView {
    var lineNumberColor: NSColor = .secondaryLabelColor
    var backgroundColor: NSColor = .controlBackgroundColor
    var isDark: Bool = true
    private weak var tv: NSTextView?

    init(textView: NSTextView) {
        self.tv = textView
        super.init(scrollView: nil, orientation: .verticalRuler)
        self.ruleThickness = 42
        self.clientView = textView
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: NSText.didChangeNotification, object: textView)
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: NSView.boundsDidChangeNotification, object: nil)
    }
    required init(coder: NSCoder) { fatalError() }
    @objc func textChanged(_ n: Notification) { needsDisplay = true }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = tv,
              let lm = textView.layoutManager,
              let tc = textView.textContainer else { return }

        backgroundColor.setFill()
        rect.fill()

        let bc = isDark ? NSColor(white: 0.15, alpha: 1) : NSColor(white: 0.88, alpha: 1)
        bc.setStroke()
        let bp = NSBezierPath()
        bp.move(to: NSPoint(x: rect.maxX - 0.5, y: rect.minY))
        bp.line(to: NSPoint(x: rect.maxX - 0.5, y: rect.maxY))
        bp.lineWidth = 0.5
        bp.stroke()

        let visRect = scrollView?.contentView.bounds ?? .zero
        let font = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: lineNumberColor]

        let glyphRange = lm.glyphRange(forBoundingRect: visRect, in: tc)
        let charRange = lm.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        let nsStr = textView.string as NSString
        var lineNum = 1
        var i = 0
        while i < charRange.location && i < nsStr.length {
            if nsStr.character(at: i) == 10 { lineNum += 1 }
            i += 1
        }

        var gi = glyphRange.location
        while gi < NSMaxRange(glyphRange) {
            var lineRange = NSRange()
            let lineRect = lm.lineFragmentRect(forGlyphAt: gi, effectiveRange: &lineRange)
            let y = lineRect.origin.y - visRect.origin.y + textView.textContainerInset.height

            let s = "\(lineNum)" as NSString
            let sz = s.size(withAttributes: attrs)
            s.draw(at: NSPoint(x: ruleThickness - sz.width - 8, y: y + (lineRect.height - sz.height) / 2), withAttributes: attrs)

            lineNum += 1
            gi = NSMaxRange(lineRange)
        }
    }
}

import SwiftUI

// MARK: - Design System

struct DXTheme {
    // Surfaces
    let bg: Color
    let bgSecondary: Color
    let surface: Color
    let surfaceHover: Color
    let surfaceActive: Color
    let glass: Color
    let editorBg: Color

    // Text
    let text: Color
    let textSecondary: Color
    let textTertiary: Color
    let textGhost: Color

    // Accent
    let accent: Color
    let accentSecondary: Color
    let accentGlow: Color

    // Semantic
    let success: Color
    let error: Color
    let warning: Color
    let info: Color

    // Borders
    let border: Color
    let borderSubtle: Color

    // Syntax
    let syntaxKey: Color
    let syntaxString: Color
    let syntaxNumber: Color
    let syntaxBool: Color
    let syntaxBrace: Color

    // Gradients
    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var meshGradient: LinearGradient {
        LinearGradient(colors: [accent.opacity(0.08), accentSecondary.opacity(0.04), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let dark = DXTheme(
        bg:             Color(hex: "0C0C0F"),
        bgSecondary:    Color(hex: "111114"),
        surface:        Color(hex: "18181D"),
        surfaceHover:   Color(hex: "1F1F26"),
        surfaceActive:  Color(hex: "252530"),
        glass:          Color(hex: "FFFFFF").opacity(0.03),
        editorBg:       Color(hex: "0F0F13"),

        text:           Color(hex: "F0F0F5"),
        textSecondary:  Color(hex: "7C7C8A"),
        textTertiary:   Color(hex: "4A4A56"),
        textGhost:      Color(hex: "2C2C36"),

        accent:         Color(hex: "FF8C42"),
        accentSecondary:Color(hex: "FF6B2C"),
        accentGlow:     Color(hex: "FF8C42").opacity(0.25),

        success:        Color(hex: "4ADE80"),
        error:          Color(hex: "FB7185"),
        warning:        Color(hex: "FBBF24"),
        info:           Color(hex: "60A5FA"),

        border:         Color(hex: "FFFFFF").opacity(0.06),
        borderSubtle:   Color(hex: "FFFFFF").opacity(0.03),

        syntaxKey:      Color(hex: "7DD3FC"),
        syntaxString:   Color(hex: "FCA5A5"),
        syntaxNumber:   Color(hex: "86EFAC"),
        syntaxBool:     Color(hex: "93C5FD"),
        syntaxBrace:    Color(hex: "FDE68A")
    )

    static let light = DXTheme(
        bg:             Color(hex: "F5F5F7"),
        bgSecondary:    Color(hex: "EBEBEF"),
        surface:        Color(hex: "FFFFFF"),
        surfaceHover:   Color(hex: "F0F0F4"),
        surfaceActive:  Color(hex: "E8E8EE"),
        glass:          Color(hex: "000000").opacity(0.02),
        editorBg:       Color(hex: "FAFAFE"),

        text:           Color(hex: "111118"),
        textSecondary:  Color(hex: "6E6E7A"),
        textTertiary:   Color(hex: "A0A0AC"),
        textGhost:      Color(hex: "D4D4DA"),

        accent:         Color(hex: "E8722A"),
        accentSecondary:Color(hex: "D35F1A"),
        accentGlow:     Color(hex: "E8722A").opacity(0.15),

        success:        Color(hex: "16A34A"),
        error:          Color(hex: "DC2626"),
        warning:        Color(hex: "CA8A04"),
        info:           Color(hex: "2563EB"),

        border:         Color(hex: "000000").opacity(0.08),
        borderSubtle:   Color(hex: "000000").opacity(0.04),

        syntaxKey:      Color(hex: "0369A1"),
        syntaxString:   Color(hex: "BE123C"),
        syntaxNumber:   Color(hex: "047857"),
        syntaxBool:     Color(hex: "1D4ED8"),
        syntaxBrace:    Color(hex: "92400E")
    )
}

// MARK: - SyntaxTheme compat

struct SyntaxTheme {
    let key: Color, string: Color, number: Color, boolean: Color, null: Color, brace: Color, comment: Color
    static let dark = SyntaxTheme(
        key: DXTheme.dark.syntaxKey, string: DXTheme.dark.syntaxString, number: DXTheme.dark.syntaxNumber,
        boolean: DXTheme.dark.syntaxBool, null: DXTheme.dark.syntaxBool, brace: DXTheme.dark.syntaxBrace,
        comment: Color(hex: "6A9955")
    )
    static let light = SyntaxTheme(
        key: DXTheme.light.syntaxKey, string: DXTheme.light.syntaxString, number: DXTheme.light.syntaxNumber,
        boolean: DXTheme.light.syntaxBool, null: DXTheme.light.syntaxBool, brace: DXTheme.light.syntaxBrace,
        comment: Color(hex: "6A9955")
    )
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Environment

struct ThemeKey: EnvironmentKey { static let defaultValue: DXTheme = .dark }
extension EnvironmentValues {
    var theme: DXTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct AdaptiveTheme: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.environment(\.theme, colorScheme == .dark ? .dark : .light)
    }
}

extension View {
    func adaptiveTheme() -> some View { modifier(AdaptiveTheme()) }
}

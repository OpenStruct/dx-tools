import Foundation
import SwiftUI

struct ColorService {

    struct ColorResult {
        let r: Double, g: Double, b: Double
        let hex: String
        let rgb: String
        let hsl: String
        let h: Double, s: Double, l: Double
        let swiftCode: String
        let swiftUICode: String
        let cssCode: String
        let androidCode: String
        let flutterCode: String
        let tailwindCode: String
        let shades: [(percent: Int, hex: String, r: Int, g: Int, b: Int)]
        let color: Color
    }

    static func parse(_ input: String) -> Result<ColorResult, Error> {
        let raw = input.trimmingCharacters(in: .whitespaces)
        var r: Double = 0, g: Double = 0, b: Double = 0

        if raw.hasPrefix("#") || (raw.count == 6 && raw.allSatisfy({ $0.isHexDigit })) {
            var hex = raw.replacingOccurrences(of: "#", with: "")
            if hex.count == 3 {
                hex = hex.map { "\($0)\($0)" }.joined()
            }
            guard hex.count == 6, let val = UInt64(hex, radix: 16) else {
                return .failure(ColorError.invalidHex)
            }
            r = Double((val >> 16) & 0xFF)
            g = Double((val >> 8) & 0xFF)
            b = Double(val & 0xFF)
        } else if raw.lowercased().hasPrefix("rgb") {
            let nums = raw.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Double($0) }
            guard nums.count >= 3 else { return .failure(ColorError.invalidRGB) }
            r = nums[0]; g = nums[1]; b = nums[2]
        } else if raw.lowercased().hasPrefix("hsl") {
            let nums = raw.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).compactMap { Double($0) }
            guard nums.count >= 3 else { return .failure(ColorError.invalidHSL) }
            let (cr, cg, cb) = hslToRGB(h: nums[0], s: nums[1] / 100, l: nums[2] / 100)
            r = cr * 255; g = cg * 255; b = cb * 255
        } else {
            return .failure(ColorError.unknownFormat)
        }

        let ri = Int(r.rounded()), gi = Int(g.rounded()), bi = Int(b.rounded())
        let hex = String(format: "#%02X%02X%02X", ri, gi, bi)
        let (h, s, l) = rgbToHSL(r: r / 255, g: g / 255, b: b / 255)

        let shades = stride(from: 10, through: 100, by: 10).map { pct -> (Int, String, Int, Int, Int) in
            let factor = Double(pct) / 100.0
            let sr = Int(r * factor), sg = Int(g * factor), sb = Int(b * factor)
            return (pct, String(format: "#%02X%02X%02X", sr, sg, sb), sr, sg, sb)
        }

        let color = Color(red: r / 255, green: g / 255, blue: b / 255)

        return .success(ColorResult(
            r: r, g: g, b: b,
            hex: hex,
            rgb: "rgb(\(ri), \(gi), \(bi))",
            hsl: "hsl(\(Int(h.rounded())), \(Int(s.rounded()))%, \(Int(l.rounded()))%)",
            h: h, s: s, l: l,
            swiftCode: "Color(red: \(String(format: "%.3f", r/255)), green: \(String(format: "%.3f", g/255)), blue: \(String(format: "%.3f", b/255)))",
            swiftUICode: "Color(hex: \"\(hex)\")",
            cssCode: "color: \(hex.lowercased());",
            androidCode: "Color.rgb(\(ri), \(gi), \(bi))",
            flutterCode: "Color(0xFF\(hex.dropFirst()))",
            tailwindCode: "[\(hex.lowercased())]",
            shades: shades,
            color: color
        ))
    }

    static func rgbToHSL(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
        let cmax = max(r, g, b), cmin = min(r, g, b)
        let delta = cmax - cmin
        let l = (cmax + cmin) / 2
        guard delta > 0 else { return (0, 0, l * 100) }
        let s = delta / (1 - abs(2 * l - 1))
        var h: Double
        if cmax == r { h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6)) }
        else if cmax == g { h = 60 * (((b - r) / delta) + 2) }
        else { h = 60 * (((r - g) / delta) + 4) }
        if h < 0 { h += 360 }
        return (h, s * 100, l * 100)
    }

    static func hslToRGB(h: Double, s: Double, l: Double) -> (Double, Double, Double) {
        guard s > 0 else { return (l, l, l) }
        let c = (1 - abs(2 * l - 1)) * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = l - c / 2
        var r = 0.0, g = 0.0, b = 0.0
        switch h {
        case 0..<60:    r = c; g = x
        case 60..<120:  r = x; g = c
        case 120..<180: g = c; b = x
        case 180..<240: g = x; b = c
        case 240..<300: r = x; b = c
        default:        r = c; b = x
        }
        return (r + m, g + m, b + m)
    }

    enum ColorError: LocalizedError {
        case invalidHex, invalidRGB, invalidHSL, unknownFormat
        var errorDescription: String? {
            switch self {
            case .invalidHex: return "Invalid hex color"
            case .invalidRGB: return "Invalid RGB format. Use: rgb(255, 87, 51)"
            case .invalidHSL: return "Invalid HSL format. Use: hsl(11, 100%, 60%)"
            case .unknownFormat: return "Unknown format. Use #HEX, rgb(), or hsl()"
            }
        }
    }
}

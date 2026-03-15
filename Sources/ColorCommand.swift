import ArgumentParser
import Foundation

struct ColorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "color",
        abstract: "Convert colors between HEX, RGB, HSL"
    )
    
    @Argument(help: "Color value (e.g., '#FF5733', 'rgb(255,87,51)', 'hsl(11,100%,60%)')")
    var input: [String]
    
    func run() throws {
        let raw = input.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        
        var r: Double = 0, g: Double = 0, b: Double = 0
        
        if raw.hasPrefix("#") || raw.allSatisfy({ $0.isHexDigit }) {
            // HEX
            var hex = raw.replacingOccurrences(of: "#", with: "")
            if hex.count == 3 {
                hex = hex.map { "\($0)\($0)" }.joined()
            }
            guard hex.count == 6, let val = UInt64(hex, radix: 16) else {
                print(Style.error("Invalid hex color: \(raw)"))
                throw ExitCode.failure
            }
            r = Double((val >> 16) & 0xFF)
            g = Double((val >> 8) & 0xFF)
            b = Double(val & 0xFF)
        } else if raw.lowercased().hasPrefix("rgb") {
            let nums = raw.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Double($0) }
            guard nums.count >= 3 else {
                print(Style.error("Invalid RGB: \(raw)"))
                throw ExitCode.failure
            }
            r = nums[0]; g = nums[1]; b = nums[2]
        } else if raw.lowercased().hasPrefix("hsl") {
            let nums = raw.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted)
                .compactMap { Double($0) }
            guard nums.count >= 3 else {
                print(Style.error("Invalid HSL: \(raw)"))
                throw ExitCode.failure
            }
            let (cr, cg, cb) = hslToRGB(h: nums[0], s: nums[1] / 100, l: nums[2] / 100)
            r = cr * 255; g = cg * 255; b = cb * 255
        } else {
            print(Style.error("Unrecognized format: \(raw)"))
            print("  \(Style.dim)Use: #FF5733, rgb(255,87,51), or hsl(11,100%,60%)\(Style.reset)")
            throw ExitCode.failure
        }
        
        let ri = Int(r.rounded()), gi = Int(g.rounded()), bi = Int(b.rounded())
        let hex = String(format: "#%02X%02X%02X", ri, gi, bi)
        let (h, s, l) = rgbToHSL(r: r / 255, g: g / 255, b: b / 255)
        
        // Terminal color preview using ANSI true color
        let preview = "\u{001B}[48;2;\(ri);\(gi);\(bi)m      \u{001B}[0m"
        
        print(Style.header("🎨", "color"))
        print()
        print("  \(preview)  \(Style.bold)\(hex)\(Style.reset)")
        print()
        print(Style.label("HEX", "\(Style.yellow)\(hex)\(Style.reset)"))
        print(Style.label("HEX (lower)", "\(Style.yellow)\(hex.lowercased())\(Style.reset)"))
        print(Style.label("RGB", "\(Style.yellow)rgb(\(ri), \(gi), \(bi))\(Style.reset)"))
        print(Style.label("HSL", "\(Style.yellow)hsl(\(Int(h.rounded())), \(Int(s.rounded()))%, \(Int(l.rounded()))%)\(Style.reset)"))
        print()
        print("  \(Style.gray)───── Code Snippets ─────\(Style.reset)")
        print(Style.label("CSS", "\(Style.green)color: \(hex.lowercased());\(Style.reset)"))
        print(Style.label("Swift", "\(Style.green)Color(red: \(String(format: "%.3f", r/255)), green: \(String(format: "%.3f", g/255)), blue: \(String(format: "%.3f", b/255)))\(Style.reset)"))
        print(Style.label("SwiftUI", "\(Style.green)Color(hex: \"\(hex)\")\(Style.reset)"))
        print(Style.label("Android", "\(Style.green)Color.rgb(\(ri), \(gi), \(bi))\(Style.reset)"))
        print(Style.label("Flutter", "\(Style.green)Color(0xFF\(hex.dropFirst()))\(Style.reset)"))
        print(Style.label("Tailwind", "\(Style.green)[\(hex.lowercased())]\(Style.reset)"))
        print()
        
        // Show color variations
        print("  \(Style.gray)───── Shades ─────\(Style.reset)")
        for pct in stride(from: 0.2, through: 1.0, by: 0.2) {
            let sr = Int(r * pct), sg = Int(g * pct), sb = Int(b * pct)
            let swatch = "\u{001B}[48;2;\(sr);\(sg);\(sb)m    \u{001B}[0m"
            let label = "\(Int(pct * 100))%"
            print("  \(swatch) \(Style.gray)\(label.padding(toLength: 5, withPad: " ", startingAt: 0))\(Style.reset) \(String(format: "#%02X%02X%02X", sr, sg, sb))")
        }
        print()
    }
}

func rgbToHSL(r: Double, g: Double, b: Double) -> (Double, Double, Double) {
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

func hslToRGB(h: Double, s: Double, l: Double) -> (Double, Double, Double) {
    guard s > 0 else { return (l, l, l) }
    
    let c = (1 - abs(2 * l - 1)) * s
    let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
    let m = l - c / 2
    
    var r = 0.0, g = 0.0, b = 0.0
    switch h {
    case 0..<60:    r = c; g = x; b = 0
    case 60..<120:  r = x; g = c; b = 0
    case 120..<180: r = 0; g = c; b = x
    case 180..<240: r = 0; g = x; b = c
    case 240..<300: r = x; g = 0; b = c
    default:        r = c; g = 0; b = x
    }
    
    return (r + m, g + m, b + m)
}

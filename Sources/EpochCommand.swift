import ArgumentParser
import Foundation

struct EpochCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "epoch",
        abstract: "Convert between epoch timestamps and human dates",
        subcommands: [Now.self, Decode.self, Encode.self],
        defaultSubcommand: Now.self
    )
    
    struct Now: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Show current time in all formats")
        
        func run() {
            let now = Date()
            let epoch = now.timeIntervalSince1970
            
            print(Style.header("🕐", "epoch now"))
            print()
            print(Style.label("Epoch (s)", "\(Style.yellow)\(Int(epoch))\(Style.reset)"))
            print(Style.label("Epoch (ms)", "\(Style.yellow)\(Int(epoch * 1000))\(Style.reset)"))
            print(Style.label("ISO 8601", formatISO(now)))
            print(Style.label("Local", formatDate(now)))
            print(Style.label("UTC", formatUTC(now)))
            print(Style.label("Relative", relativeTime(now)))
            print()
            
            // Show other timezones
            print("  \(Style.gray)───── World Clocks ─────\(Style.reset)")
            let zones = [
                ("🇺🇸 New York", "America/New_York"),
                ("🇺🇸 LA", "America/Los_Angeles"),
                ("🇬🇧 London", "Europe/London"),
                ("🇯🇵 Tokyo", "Asia/Tokyo"),
                ("🇦🇺 Sydney", "Australia/Sydney"),
                ("🇮🇳 Mumbai", "Asia/Kolkata"),
            ]
            for (name, tz) in zones {
                let f = DateFormatter()
                f.dateFormat = "HH:mm:ss (EEE)"
                f.timeZone = TimeZone(identifier: tz)
                print(Style.label(name.padding(toLength: 14, withPad: " ", startingAt: 0), f.string(from: now)))
            }
            print()
        }
    }
    
    struct Decode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Convert epoch timestamp to human date")
        
        @Argument(help: "Epoch timestamp (seconds or milliseconds)")
        var timestamp: Double
        
        @Option(name: .shortAndLong, help: "Timezone (e.g., 'America/New_York', 'UTC')")
        var tz: String?
        
        func run() {
            // Auto-detect seconds vs milliseconds
            let ts = timestamp > 9999999999 ? timestamp / 1000 : timestamp
            let isMs = timestamp > 9999999999
            let date = Date(timeIntervalSince1970: ts)
            
            print(Style.header("🕐", "epoch decode"))
            print()
            if isMs {
                print("  \(Style.dim)Auto-detected: milliseconds\(Style.reset)")
            }
            print(Style.label("Input", "\(Style.yellow)\(Int(timestamp))\(Style.reset)"))
            print(Style.label("ISO 8601", formatISO(date)))
            print(Style.label("Local", formatDate(date)))
            print(Style.label("UTC", formatUTC(date)))
            print(Style.label("Relative", relativeTime(date)))
            
            if let tzName = tz, let timezone = TimeZone(identifier: tzName) {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
                f.timeZone = timezone
                print(Style.label("Custom TZ", f.string(from: date)))
            }
            print()
        }
    }
    
    struct Encode: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Convert date string to epoch")
        
        @Argument(help: "Date string (ISO 8601, or 'YYYY-MM-DD HH:MM:SS')")
        var date: [String]
        
        func run() throws {
            let input = date.joined(separator: " ")
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd",
                "MM/dd/yyyy HH:mm:ss",
                "MM/dd/yyyy",
                "dd-MM-yyyy",
            ]
            
            var parsed: Date?
            for format in formats {
                let f = DateFormatter()
                f.dateFormat = format
                f.locale = Locale(identifier: "en_US_POSIX")
                if let d = f.date(from: input) {
                    parsed = d
                    break
                }
            }
            
            // Also try ISO8601DateFormatter
            if parsed == nil {
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                parsed = iso.date(from: input)
            }
            
            guard let date = parsed else {
                print(Style.error("Could not parse date: '\(input)'"))
                print("  \(Style.dim)Supported: ISO 8601, YYYY-MM-DD HH:MM:SS, MM/DD/YYYY\(Style.reset)")
                throw ExitCode.failure
            }
            
            print(Style.header("🕐", "epoch encode"))
            print()
            print(Style.label("Input", input))
            print(Style.label("Epoch (s)", "\(Style.yellow)\(Int(date.timeIntervalSince1970))\(Style.reset)"))
            print(Style.label("Epoch (ms)", "\(Style.yellow)\(Int(date.timeIntervalSince1970 * 1000))\(Style.reset)"))
            print(Style.label("ISO 8601", formatISO(date)))
            print()
        }
    }
}

private func formatISO(_ date: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime]
    return f.string(from: date)
}

private func formatUTC(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    f.timeZone = TimeZone(identifier: "UTC")
    return f.string(from: date) + " UTC"
}

private func relativeTime(_ date: Date) -> String {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .full
    return f.localizedString(for: date, relativeTo: Date())
}

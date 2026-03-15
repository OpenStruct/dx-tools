import Foundation

struct TimestampService {
    struct ConversionResult {
        let epoch: Int
        let epochMs: Int64
        let iso8601: String
        let rfc2822: String
        let relative: String
        let utc: String
        let local: String
        let dayOfWeek: String
        let weekOfYear: Int
        let dayOfYear: Int
        let isLeapYear: Bool
    }

    static func convert(from input: String) -> ConversionResult? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var date: Date?

        // Try epoch (seconds)
        if let ts = Double(trimmed) {
            if ts > 1_000_000_000_000 {
                date = Date(timeIntervalSince1970: ts / 1000) // milliseconds
            } else if ts > 1_000_000_000 {
                date = Date(timeIntervalSince1970: ts) // seconds
            }
        }

        // Try ISO 8601
        if date == nil {
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = iso.date(from: trimmed)
            if date == nil {
                iso.formatOptions = [.withInternetDateTime]
                date = iso.date(from: trimmed)
            }
        }

        // Try RFC 2822
        if date == nil {
            let rfc = DateFormatter()
            rfc.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
            rfc.locale = Locale(identifier: "en_US_POSIX")
            date = rfc.date(from: trimmed)
        }

        // Try common formats
        if date == nil {
            let formats = [
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd",
                "MM/dd/yyyy HH:mm:ss",
                "MM/dd/yyyy",
                "dd/MM/yyyy HH:mm:ss",
                "dd-MMM-yyyy HH:mm:ss",
                "MMM dd, yyyy HH:mm:ss",
                "MMM dd, yyyy",
            ]
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            for fmt in formats {
                df.dateFormat = fmt
                if let d = df.date(from: trimmed) {
                    date = d
                    break
                }
            }
        }

        guard let d = date else { return nil }
        return format(date: d)
    }

    static func now() -> ConversionResult {
        format(date: Date())
    }

    private static func format(date: Date) -> ConversionResult {
        let epoch = Int(date.timeIntervalSince1970)
        let epochMs = Int64(date.timeIntervalSince1970 * 1000)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        let rfc = DateFormatter()
        rfc.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        rfc.locale = Locale(identifier: "en_US_POSIX")

        let utcFmt = DateFormatter()
        utcFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        utcFmt.timeZone = TimeZone(identifier: "UTC")

        let localFmt = DateFormatter()
        localFmt.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"

        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEEE"

        let cal = Calendar.current
        let weekOfYear = cal.component(.weekOfYear, from: date)
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: date) ?? 0
        let year = cal.component(.year, from: date)
        let isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)

        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .full

        return ConversionResult(
            epoch: epoch,
            epochMs: epochMs,
            iso8601: iso.string(from: date),
            rfc2822: rfc.string(from: date),
            relative: relative.localizedString(for: date, relativeTo: Date()),
            utc: utcFmt.string(from: date),
            local: localFmt.string(from: date),
            dayOfWeek: dayFmt.string(from: date),
            weekOfYear: weekOfYear,
            dayOfYear: dayOfYear,
            isLeapYear: isLeap
        )
    }
}

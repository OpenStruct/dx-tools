import Foundation

struct EpochService {

    struct TimeInfo {
        let epochSeconds: Int
        let epochMilliseconds: Int
        let iso8601: String
        let local: String
        let utc: String
        let relative: String
        let worldClocks: [(name: String, time: String)]
    }

    static func now() -> TimeInfo {
        return fromDate(Date())
    }

    static func fromEpoch(_ timestamp: Double) -> TimeInfo {
        let ts = timestamp > 9_999_999_999 ? timestamp / 1000 : timestamp
        return fromDate(Date(timeIntervalSince1970: ts))
    }

    static func fromDate(_ date: Date) -> TimeInfo {
        let epoch = date.timeIntervalSince1970

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        localFormatter.timeZone = .current

        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        utcFormatter.timeZone = TimeZone(identifier: "UTC")

        let relFormatter = RelativeDateTimeFormatter()
        relFormatter.unitsStyle = .full

        let zones: [(String, String)] = [
            ("🇺🇸 New York", "America/New_York"),
            ("🇺🇸 Los Angeles", "America/Los_Angeles"),
            ("🇬🇧 London", "Europe/London"),
            ("🇯🇵 Tokyo", "Asia/Tokyo"),
            ("🇦🇺 Sydney", "Australia/Sydney"),
            ("🇮🇳 Mumbai", "Asia/Kolkata"),
            ("🇩🇪 Berlin", "Europe/Berlin"),
            ("🇸🇬 Singapore", "Asia/Singapore"),
        ]

        let worldClocks = zones.map { (name, tz) -> (String, String) in
            let f = DateFormatter()
            f.dateFormat = "HH:mm:ss (EEE, MMM d)"
            f.timeZone = TimeZone(identifier: tz)
            return (name, f.string(from: date))
        }

        return TimeInfo(
            epochSeconds: Int(epoch),
            epochMilliseconds: Int(epoch * 1000),
            iso8601: isoFormatter.string(from: date),
            local: localFormatter.string(from: date),
            utc: utcFormatter.string(from: date) + " UTC",
            relative: relFormatter.localizedString(for: date, relativeTo: Date()),
            worldClocks: worldClocks
        )
    }

    static func parseDate(_ input: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy",
        ]

        for format in formats {
            let f = DateFormatter()
            f.dateFormat = format
            f.locale = Locale(identifier: "en_US_POSIX")
            if let d = f.date(from: input) { return d }
        }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: input)
    }
}

import Foundation

struct CronService {

    struct CronResult {
        let description: String
        let nextRuns: [Date]
        let parts: [CronPart]
        let isValid: Bool
        let error: String?
    }

    struct CronPart {
        let field: String   // minute, hour, etc.
        let value: String
        let meaning: String
    }

    static let fieldNames = ["Minute", "Hour", "Day of Month", "Month", "Day of Week"]
    static let fieldRanges = [0...59, 0...23, 1...31, 1...12, 0...6]

    static func parse(_ expression: String) -> CronResult {
        let parts = expression.trimmingCharacters(in: .whitespaces).split(separator: " ").map(String.init)
        guard parts.count == 5 else {
            return CronResult(description: "", nextRuns: [], parts: [], isValid: false,
                            error: "Expected 5 fields: minute hour day month weekday. Got \(parts.count).")
        }

        var cronParts: [CronPart] = []
        for (i, part) in parts.enumerated() {
            cronParts.append(CronPart(
                field: fieldNames[i],
                value: part,
                meaning: describeField(part, fieldIndex: i)
            ))
        }

        let description = buildDescription(parts)
        let nextRuns = calculateNextRuns(parts, count: 10)

        return CronResult(
            description: description,
            nextRuns: nextRuns,
            parts: cronParts,
            isValid: true,
            error: nil
        )
    }

    private static func describeField(_ value: String, fieldIndex: Int) -> String {
        let name = fieldNames[fieldIndex]
        if value == "*" { return "Every \(name.lowercased())" }
        if value.hasPrefix("*/") {
            let interval = String(value.dropFirst(2))
            return "Every \(interval) \(name.lowercased())\(interval == "1" ? "" : "s")"
        }
        if value.contains(",") {
            return "At \(name.lowercased()) \(value)"
        }
        if value.contains("-") {
            let range = value.split(separator: "-")
            return "\(name) \(range[0]) through \(range[1])"
        }
        if fieldIndex == 4 { // Day of week
            let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            if let idx = Int(value), idx >= 0 && idx < 7 { return "On \(days[idx])" }
        }
        if fieldIndex == 3 { // Month
            let months = ["", "January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
            if let idx = Int(value), idx >= 1 && idx <= 12 { return "In \(months[idx])" }
        }
        return "At \(name.lowercased()) \(value)"
    }

    private static func buildDescription(_ parts: [String]) -> String {
        let min = parts[0], hour = parts[1], dom = parts[2], month = parts[3], dow = parts[4]

        var desc: [String] = []

        // Time
        if min == "*" && hour == "*" {
            desc.append("Every minute")
        } else if min.hasPrefix("*/") {
            desc.append("Every \(min.dropFirst(2)) minutes")
        } else if hour.hasPrefix("*/") {
            desc.append("At minute \(min), every \(hour.dropFirst(2)) hours")
        } else if min != "*" && hour != "*" {
            let h = Int(hour) ?? 0
            let m = Int(min) ?? 0
            let ampm = h >= 12 ? "PM" : "AM"
            let h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h)
            desc.append("At \(h12):\(String(format: "%02d", m)) \(ampm)")
        } else if hour != "*" {
            desc.append("Every minute during hour \(hour)")
        } else {
            desc.append("At minute \(min)")
        }

        // Day filters
        if dom != "*" && dow != "*" {
            desc.append("on day \(dom) and weekday \(dow)")
        } else if dom != "*" {
            if dom.hasPrefix("*/") {
                desc.append("every \(dom.dropFirst(2)) days")
            } else {
                desc.append("on day \(dom) of the month")
            }
        } else if dow != "*" {
            let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
            if let idx = Int(dow), idx >= 0 && idx < 7 {
                desc.append("on \(days[idx])")
            } else if dow.contains(",") {
                let names = dow.split(separator: ",").compactMap { Int($0) }.filter { $0 >= 0 && $0 < 7 }.map { days[$0] }
                desc.append("on \(names.joined(separator: ", "))")
            } else if dow.contains("-") {
                let range = dow.split(separator: "-").compactMap { Int($0) }.filter { $0 >= 0 && $0 < 7 }
                if range.count == 2 { desc.append("from \(days[range[0]]) to \(days[range[1]])") }
            } else {
                desc.append("on weekday \(dow)")
            }
        }

        // Month filter
        if month != "*" {
            let months = ["", "January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]
            if let idx = Int(month), idx >= 1 && idx <= 12 {
                desc.append("in \(months[idx])")
            } else if month.hasPrefix("*/") {
                desc.append("every \(month.dropFirst(2)) months")
            } else {
                desc.append("in month \(month)")
            }
        }

        return desc.joined(separator: " ")
    }

    private static func calculateNextRuns(_ parts: [String], count: Int) -> [Date] {
        var results: [Date] = []
        let calendar = Calendar.current
        var current = Date()

        for _ in 0..<(count * 1500) { // Max iterations to prevent infinite loop
            guard results.count < count else { break }
            current = calendar.date(byAdding: .minute, value: 1, to: current)!

            let comps = calendar.dateComponents([.minute, .hour, .day, .month, .weekday], from: current)
            guard let minute = comps.minute, let hour = comps.hour,
                  let day = comps.day, let month = comps.month, let weekday = comps.weekday else { continue }

            let cronWeekday = weekday == 1 ? 0 : weekday - 1 // Convert to 0=Sun

            if matches(parts[0], value: minute, range: 0...59) &&
               matches(parts[1], value: hour, range: 0...23) &&
               matches(parts[2], value: day, range: 1...31) &&
               matches(parts[3], value: month, range: 1...12) &&
               matches(parts[4], value: cronWeekday, range: 0...6) {
                results.append(current)
            }
        }
        return results
    }

    private static func matches(_ pattern: String, value: Int, range: ClosedRange<Int>) -> Bool {
        if pattern == "*" { return true }
        if pattern.hasPrefix("*/") {
            guard let step = Int(pattern.dropFirst(2)), step > 0 else { return false }
            return value % step == 0
        }
        if pattern.contains(",") {
            let values = pattern.split(separator: ",").compactMap { Int($0) }
            return values.contains(value)
        }
        if pattern.contains("-") {
            let bounds = pattern.split(separator: "-").compactMap { Int($0) }
            guard bounds.count == 2 else { return false }
            return value >= bounds[0] && value <= bounds[1]
        }
        return Int(pattern) == value
    }

    static let examples: [(expression: String, description: String)] = [
        ("* * * * *", "Every minute"),
        ("0 * * * *", "Every hour"),
        ("0 0 * * *", "Daily at midnight"),
        ("0 9 * * 1-5", "Weekdays at 9 AM"),
        ("*/5 * * * *", "Every 5 minutes"),
        ("*/15 * * * *", "Every 15 minutes"),
        ("0 0 * * 0", "Weekly on Sunday"),
        ("0 0 1 * *", "Monthly on the 1st"),
        ("30 2 * * *", "Daily at 2:30 AM"),
        ("0 0 1 1 *", "Yearly on Jan 1st"),
    ]
}

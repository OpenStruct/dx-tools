import Foundation

struct RegexService {

    struct Match: Identifiable {
        let id = UUID()
        let fullMatch: String
        let range: Range<String.Index>
        let groups: [GroupMatch]
        let index: Int
    }

    struct GroupMatch: Identifiable {
        let id = UUID()
        let index: Int
        let value: String
    }

    struct Result {
        let matches: [Match]
        let matchCount: Int
        let executionTime: TimeInterval
    }

    static func test(pattern: String, input: String, flags: Flags = Flags()) -> Swift.Result<Result, Error> {
        let start = CFAbsoluteTimeGetCurrent()

        var options: NSRegularExpression.Options = []
        if flags.caseInsensitive { options.insert(.caseInsensitive) }
        if flags.multiline { options.insert(.anchorsMatchLines) }
        if flags.dotMatchesNewline { options.insert(.dotMatchesLineSeparators) }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let nsRange = NSRange(input.startIndex..., in: input)
            let nsMatches = regex.matches(in: input, range: nsRange)

            var matches: [Match] = []
            for (i, nsMatch) in nsMatches.enumerated() {
                guard let fullRange = Range(nsMatch.range, in: input) else { continue }

                var groups: [GroupMatch] = []
                for g in 1..<nsMatch.numberOfRanges {
                    if let groupRange = Range(nsMatch.range(at: g), in: input) {
                        groups.append(GroupMatch(index: g, value: String(input[groupRange])))
                    }
                }

                matches.append(Match(
                    fullMatch: String(input[fullRange]),
                    range: fullRange,
                    groups: groups,
                    index: i
                ))

                if !flags.global && i == 0 { break }
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - start
            return .success(Result(matches: matches, matchCount: matches.count, executionTime: elapsed))
        } catch {
            return .failure(error)
        }
    }

    static func replace(pattern: String, input: String, replacement: String, flags: Flags = Flags()) -> Swift.Result<String, Error> {
        var options: NSRegularExpression.Options = []
        if flags.caseInsensitive { options.insert(.caseInsensitive) }
        if flags.multiline { options.insert(.anchorsMatchLines) }
        if flags.dotMatchesNewline { options.insert(.dotMatchesLineSeparators) }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let nsRange = NSRange(input.startIndex..., in: input)
            let result = regex.stringByReplacingMatches(in: input, range: nsRange, withTemplate: replacement)
            return .success(result)
        } catch {
            return .failure(error)
        }
    }

    struct Flags {
        var global: Bool = true
        var caseInsensitive: Bool = false
        var multiline: Bool = false
        var dotMatchesNewline: Bool = false
    }
}

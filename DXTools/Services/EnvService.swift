import Foundation

struct EnvService {

    struct EnvEntry: Identifiable {
        let id = UUID()
        let key: String
        let value: String
        let isSensitive: Bool

        var maskedValue: String {
            guard isSensitive else { return value }
            let len = value.count
            if len <= 4 { return String(repeating: "•", count: len) }
            return String(value.prefix(2)) + String(repeating: "•", count: len - 4) + String(value.suffix(2))
        }
    }

    struct DiffResult {
        let added: [(key: String, value: String)]
        let removed: [(key: String, value: String)]
        let changed: [(key: String, oldValue: String, newValue: String)]
        let same: Int
    }

    private static let sensitiveWords = ["secret", "password", "key", "token", "api", "auth", "private", "credential", "pwd"]

    static func parse(_ content: String) -> [EnvEntry] {
        content.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return nil }
            guard let eqIdx = trimmed.firstIndex(of: "=") else { return nil }
            let key = String(trimmed[..<eqIdx]).trimmingCharacters(in: .whitespaces)
            var value = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespaces)
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }
            let isSensitive = sensitiveWords.contains { key.lowercased().contains($0) }
            return EnvEntry(key: key, value: value, isSensitive: isSensitive)
        }
    }

    static func diff(base: String, compare: String) -> DiffResult {
        let env1 = Dictionary(uniqueKeysWithValues: parse(base).map { ($0.key, $0.value) })
        let env2 = Dictionary(uniqueKeysWithValues: parse(compare).map { ($0.key, $0.value) })

        var added: [(String, String)] = []
        var removed: [(String, String)] = []
        var changed: [(String, String, String)] = []
        var same = 0

        for key in Set(env1.keys).union(Set(env2.keys)).sorted() {
            let v1 = env1[key]
            let v2 = env2[key]

            if v1 == nil { added.append((key, v2!)) }
            else if v2 == nil { removed.append((key, v1!)) }
            else if v1 != v2 { changed.append((key, v1!, v2!)) }
            else { same += 1 }
        }

        return DiffResult(added: added, removed: removed, changed: changed, same: same)
    }

    static func validate(env: String, template: String) -> (missing: [String], extra: [String]) {
        let envKeys = Set(parse(env).map(\.key))
        let tmplKeys = Set(parse(template).map(\.key))
        return (
            missing: tmplKeys.subtracting(envKeys).sorted(),
            extra: envKeys.subtracting(tmplKeys).sorted()
        )
    }
}

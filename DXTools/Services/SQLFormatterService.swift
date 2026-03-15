import Foundation

struct SQLFormatterService {
    enum IndentStyle: String, CaseIterable {
        case twoSpaces = "2 spaces"
        case fourSpaces = "4 spaces"
        case tab = "Tab"

        var indent: String {
            switch self {
            case .twoSpaces: return "  "
            case .fourSpaces: return "    "
            case .tab: return "\t"
            }
        }
    }

    private static let majorKeywords = [
        "SELECT", "FROM", "WHERE", "AND", "OR", "ORDER BY", "GROUP BY",
        "HAVING", "LIMIT", "OFFSET", "INSERT INTO", "VALUES", "UPDATE",
        "SET", "DELETE FROM", "CREATE TABLE", "ALTER TABLE", "DROP TABLE",
        "JOIN", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN",
        "LEFT OUTER JOIN", "RIGHT OUTER JOIN", "FULL OUTER JOIN",
        "CROSS JOIN", "ON", "UNION", "UNION ALL", "EXCEPT", "INTERSECT",
        "CASE", "WHEN", "THEN", "ELSE", "END", "AS", "IN", "NOT IN",
        "EXISTS", "NOT EXISTS", "BETWEEN", "LIKE", "IS NULL", "IS NOT NULL",
        "ASC", "DESC", "DISTINCT", "INTO", "WITH", "RETURNING"
    ]

    static func format(_ sql: String, indent: IndentStyle = .twoSpaces) -> String {
        let ind = indent.indent
        var result = ""
        var depth = 0
        var tokens = tokenize(sql)

        var i = 0
        while i < tokens.count {
            let token = tokens[i]
            let upper = token.uppercased()

            // Multi-word keywords
            var keyword = upper
            if i + 1 < tokens.count {
                let twoWord = "\(upper) \(tokens[i + 1].uppercased())"
                if majorKeywords.contains(twoWord) {
                    keyword = twoWord
                    i += 1
                }
                if i + 1 < tokens.count {
                    let threeWord = "\(keyword) \(tokens[i + 1].uppercased())"
                    if majorKeywords.contains(threeWord) {
                        keyword = threeWord
                        i += 1
                    }
                }
            }

            if keyword == "(" {
                depth += 1
                result += "(\n" + String(repeating: ind, count: depth)
            } else if keyword == ")" {
                depth = max(0, depth - 1)
                result += "\n" + String(repeating: ind, count: depth) + ")"
            } else if ["SELECT", "FROM", "WHERE", "ORDER BY", "GROUP BY", "HAVING",
                        "LIMIT", "UNION", "UNION ALL", "EXCEPT", "INTERSECT",
                        "INSERT INTO", "VALUES", "UPDATE", "SET", "DELETE FROM",
                        "CREATE TABLE", "ALTER TABLE", "DROP TABLE", "WITH",
                        "RETURNING"].contains(keyword) {
                if !result.isEmpty && !result.hasSuffix("\n") {
                    result += "\n"
                }
                result += String(repeating: ind, count: depth) + keyword + "\n" + String(repeating: ind, count: depth + 1)
            } else if ["JOIN", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN",
                        "LEFT OUTER JOIN", "RIGHT OUTER JOIN", "FULL OUTER JOIN",
                        "CROSS JOIN"].contains(keyword) {
                result += "\n" + String(repeating: ind, count: depth) + keyword + " "
            } else if ["AND", "OR"].contains(keyword) {
                result += "\n" + String(repeating: ind, count: depth + 1) + keyword + " "
            } else if keyword == "ON" {
                result += "\n" + String(repeating: ind, count: depth + 1) + keyword + " "
            } else if keyword == "," {
                result += ",\n" + String(repeating: ind, count: depth + 1)
            } else if keyword == "CASE" {
                result += "\n" + String(repeating: ind, count: depth + 1) + "CASE"
                depth += 1
            } else if ["WHEN", "THEN", "ELSE"].contains(keyword) {
                result += "\n" + String(repeating: ind, count: depth + 1) + keyword + " "
            } else if keyword == "END" {
                depth = max(0, depth - 1)
                result += "\n" + String(repeating: ind, count: depth + 1) + "END"
            } else {
                if result.hasSuffix("\n") || result.isEmpty {
                    result += token
                } else {
                    result += " " + token
                }
            }
            i += 1
        }

        // Clean up extra whitespace
        return result
            .components(separatedBy: "\n")
            .map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
            .joined(separator: "\n")
            .replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func minify(_ sql: String) -> String {
        sql.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func tokenize(_ sql: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inString = false
        var stringChar: Character = "'"
        let chars = Array(sql)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            if inString {
                current.append(c)
                if c == stringChar {
                    tokens.append(current)
                    current = ""
                    inString = false
                }
            } else if c == "'" || c == "\"" {
                if !current.isEmpty { tokens.append(current); current = "" }
                inString = true
                stringChar = c
                current.append(c)
            } else if c == "(" || c == ")" || c == "," || c == ";" {
                if !current.isEmpty { tokens.append(current); current = "" }
                tokens.append(String(c))
            } else if c.isWhitespace {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                current.append(c)
            }
            i += 1
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }
}

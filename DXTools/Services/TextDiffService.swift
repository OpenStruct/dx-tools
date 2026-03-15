import Foundation

struct TextDiffService {
    struct DiffLine: Identifiable {
        let id = UUID()
        let lineNumber: Int?
        let content: String
        let type: LineType
    }

    enum LineType {
        case same
        case added
        case removed
        case header
    }

    struct DiffResult {
        let leftLines: [DiffLine]
        let rightLines: [DiffLine]
        let stats: Stats
    }

    struct Stats {
        let additions: Int
        let deletions: Int
        let unchanged: Int
    }

    static func diff(left: String, right: String) -> DiffResult {
        let leftArr = left.components(separatedBy: "\n")
        let rightArr = right.components(separatedBy: "\n")

        let lcs = longestCommonSubsequence(leftArr, rightArr)

        var leftLines: [DiffLine] = []
        var rightLines: [DiffLine] = []
        var additions = 0
        var deletions = 0
        var unchanged = 0

        var li = 0, ri = 0, ci = 0

        while li < leftArr.count || ri < rightArr.count {
            if ci < lcs.count && li < leftArr.count && ri < rightArr.count &&
               leftArr[li] == lcs[ci] && rightArr[ri] == lcs[ci] {
                leftLines.append(DiffLine(lineNumber: li + 1, content: leftArr[li], type: .same))
                rightLines.append(DiffLine(lineNumber: ri + 1, content: rightArr[ri], type: .same))
                unchanged += 1
                li += 1; ri += 1; ci += 1
            } else if li < leftArr.count && (ci >= lcs.count || leftArr[li] != lcs[ci]) {
                leftLines.append(DiffLine(lineNumber: li + 1, content: leftArr[li], type: .removed))
                rightLines.append(DiffLine(lineNumber: nil, content: "", type: .header))
                deletions += 1
                li += 1
            } else if ri < rightArr.count && (ci >= lcs.count || rightArr[ri] != lcs[ci]) {
                leftLines.append(DiffLine(lineNumber: nil, content: "", type: .header))
                rightLines.append(DiffLine(lineNumber: ri + 1, content: rightArr[ri], type: .added))
                additions += 1
                ri += 1
            }
        }

        return DiffResult(
            leftLines: leftLines,
            rightLines: rightLines,
            stats: Stats(additions: additions, deletions: deletions, unchanged: unchanged)
        )
    }

    private static func longestCommonSubsequence(_ a: [String], _ b: [String]) -> [String] {
        let m = a.count, n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...max(m, 1) {
            for j in 1...max(n, 1) {
                guard i <= m && j <= n else { continue }
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        var result: [String] = []
        var i = m, j = n
        while i > 0 && j > 0 {
            if a[i - 1] == b[j - 1] {
                result.insert(a[i - 1], at: 0)
                i -= 1; j -= 1
            } else if dp[i - 1][j] > dp[i][j - 1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        return result
    }

    static func unifiedDiff(left: String, right: String, leftName: String = "original", rightName: String = "modified") -> String {
        let result = diff(left: left, right: right)
        var lines: [String] = []
        lines.append("--- \(leftName)")
        lines.append("+++ \(rightName)")

        for i in 0..<max(result.leftLines.count, result.rightLines.count) {
            if i < result.leftLines.count && result.leftLines[i].type == .removed {
                lines.append("- \(result.leftLines[i].content)")
            } else if i < result.rightLines.count && result.rightLines[i].type == .added {
                lines.append("+ \(result.rightLines[i].content)")
            } else if i < result.leftLines.count && result.leftLines[i].type == .same {
                lines.append("  \(result.leftLines[i].content)")
            }
        }
        return lines.joined(separator: "\n")
    }
}

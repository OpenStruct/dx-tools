import Foundation

struct GitService {
    struct RepoInfo {
        let path: String
        let branch: String
        let remoteName: String
        let remoteURL: String
        let lastCommit: CommitInfo?
        let recentCommits: [CommitInfo]
        let dirtyFiles: [FileStatus]
        let stats: RepoStats
    }

    struct CommitInfo: Identifiable {
        let id: String // hash
        let shortHash: String
        let message: String
        let author: String
        let date: String
        let relative: String
    }

    struct FileStatus: Identifiable {
        let id = UUID()
        let status: String
        let file: String
    }

    struct RepoStats {
        let totalCommits: Int
        let branches: Int
        let tags: Int
        let contributors: Int
    }

    static func getRepoInfo(at path: String) -> RepoInfo? {
        let branch = shell("cd '\(path)' && git branch --show-current 2>/dev/null").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branch.isEmpty else { return nil }

        let remoteName = shell("cd '\(path)' && git remote 2>/dev/null").components(separatedBy: "\n").first ?? ""
        let remoteURL = shell("cd '\(path)' && git remote get-url \(remoteName) 2>/dev/null").trimmingCharacters(in: .whitespacesAndNewlines)

        let logOutput = shell("cd '\(path)' && git log --oneline -20 --format='%H|%h|%s|%an|%ai|%ar' 2>/dev/null")
        let commits = logOutput.split(separator: "\n").compactMap { line -> CommitInfo? in
            let parts = line.split(separator: "|", maxSplits: 5, omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 6 else { return nil }
            return CommitInfo(id: parts[0], shortHash: parts[1], message: parts[2], author: parts[3], date: parts[4], relative: parts[5])
        }

        let statusOutput = shell("cd '\(path)' && git status --porcelain 2>/dev/null")
        let dirtyFiles = statusOutput.split(separator: "\n").map { line -> FileStatus in
            let s = String(line)
            let status = String(s.prefix(2)).trimmingCharacters(in: .whitespaces)
            let file = String(s.dropFirst(3))
            return FileStatus(status: status, file: file)
        }

        let totalCommits = Int(shell("cd '\(path)' && git rev-list --count HEAD 2>/dev/null").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let branchCount = shell("cd '\(path)' && git branch -a 2>/dev/null").split(separator: "\n").count
        let tagCount = shell("cd '\(path)' && git tag 2>/dev/null").split(separator: "\n").count
        let contributorCount = Int(shell("cd '\(path)' && git log --format='%an' | sort -u | wc -l 2>/dev/null").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        return RepoInfo(
            path: path,
            branch: branch,
            remoteName: remoteName,
            remoteURL: remoteURL,
            lastCommit: commits.first,
            recentCommits: commits,
            dirtyFiles: dirtyFiles,
            stats: RepoStats(totalCommits: totalCommits, branches: branchCount, tags: tagCount, contributors: contributorCount)
        )
    }

    private static func shell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

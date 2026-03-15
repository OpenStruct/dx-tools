import SwiftUI

struct GitView: View {
    @State private var vm = GitViewModel()
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "Git Stats", icon: "arrow.triangle.branch") {
                Image(systemName: "folder.fill").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                TextField("Repository path…", text: $vm.repoPath)
                    .textFieldStyle(.plain).font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(t.text)
                    .onSubmit { vm.refresh() }
                SmallIconButton(title: "Browse", icon: "folder") { vm.browse() }
                SmallIconButton(title: "Refresh", icon: "arrow.clockwise") { vm.refresh() }
            }


            if let info = vm.repoInfo {
                ScrollView {
                    VStack(spacing: 16) {
                        // Branch & remote
                        HStack(spacing: 12) {
                            statCard("Branch", info.branch, "arrow.triangle.branch", t.accent)
                            statCard("Remote", info.remoteURL.components(separatedBy: "/").last?.replacingOccurrences(of: ".git", with: "") ?? info.remoteName, "globe", t.info)
                        }

                        // Stats
                        HStack(spacing: 12) {
                            statCard("Commits", "\(info.stats.totalCommits)", "number.circle.fill", t.success)
                            statCard("Branches", "\(info.stats.branches)", "arrow.triangle.branch", t.warning)
                            statCard("Tags", "\(info.stats.tags)", "tag.fill", Color.purple)
                            statCard("Authors", "\(info.stats.contributors)", "person.2.fill", t.info)
                        }

                        // Dirty files
                        if !info.dirtyFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                sectionHeader("Working Tree — \(info.dirtyFiles.count) changes", icon: "exclamationmark.triangle.fill")

                                VStack(spacing: 2) {
                                    ForEach(info.dirtyFiles) { f in
                                        HStack(spacing: 8) {
                                            Text(f.status)
                                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                                .foregroundStyle(statusColor(f.status))
                                                .frame(width: 20)
                                            Text(f.file)
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundStyle(t.text)
                                                .lineLimit(1)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 10).padding(.vertical, 4)
                                        .background(t.surface)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                    }
                                }
                            }
                        }

                        // Recent commits
                        VStack(alignment: .leading, spacing: 6) {
                            sectionHeader("Recent Commits", icon: "clock.fill")

                            VStack(spacing: 2) {
                                ForEach(info.recentCommits) { commit in
                                    HStack(spacing: 10) {
                                        Text(commit.shortHash)
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundStyle(t.accent)
                                            .frame(width: 56, alignment: .leading)
                                        Text(commit.message)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(t.text)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(commit.relative)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(t.textGhost)
                                        Text(commit.author)
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(t.textTertiary)
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(t.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            } else if let err = vm.errorMessage {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(t.error)
                    Text(err).font(.system(size: 12, weight: .medium)).foregroundStyle(t.textSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "arrow.triangle.branch").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                    Text("Select a Git Repository").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                    Text("Browse or paste a path above").font(.system(size: 10, weight: .medium)).foregroundStyle(t.textGhost)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(t.bg)
    }

    func statCard(_ label: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(color)
                Text(label.uppercased()).font(.system(size: 8.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textGhost).tracking(0.6)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(t.text)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(t.border, lineWidth: 0.5))
    }

    func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(t.accent)
            Text(title.uppercased()).font(.system(size: 9.5, weight: .heavy, design: .rounded)).foregroundStyle(t.textTertiary).tracking(0.8)
        }
    }

    func statusColor(_ status: String) -> Color {
        switch status {
        case "M": return t.warning
        case "A", "??": return t.success
        case "D": return t.error
        case "R": return t.info
        default: return t.textTertiary
        }
    }
}

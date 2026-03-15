import SwiftUI

struct HistoryPanel: View {
    let toolId: String
    let onRestore: (String) -> Void
    @Environment(\.theme) private var t
    @State private var entries: [HistoryService.HistoryItem] = []
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Toggle
            Button {
                withAnimation(.spring(response: 0.25)) { isExpanded.toggle() }
                if isExpanded { loadEntries() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(t.accent)
                    Text("HISTORY")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.textTertiary).tracking(0.8)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(t.textGhost)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(t.glass)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Rectangle().fill(t.border).frame(height: 0.5)

                if entries.isEmpty {
                    Text("No history yet")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(t.textGhost)
                        .padding(12)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(entries) { entry in
                                Button {
                                    onRestore(entry.content)
                                } label: {
                                    HStack(spacing: 8) {
                                        Text(entry.preview.replacingOccurrences(of: "\n", with: " "))
                                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                                            .foregroundStyle(t.textSecondary)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(relativeTime(entry.timestamp))
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundStyle(t.textGhost)
                                    }
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(t.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 160)
                }
            }
        }
        .onAppear { loadEntries() }
    }

    func loadEntries() {
        Task {
            entries = await HistoryService.shared.load(for: toolId)
        }
    }

    func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

import SwiftUI

struct DXTab: Identifiable, Equatable {
    let id: UUID
    let title: String
    let tool: Tool

    init(title: String = "Untitled", tool: Tool) {
        self.id = UUID()
        self.title = title
        self.tool = tool
    }

    static func == (lhs: DXTab, rhs: DXTab) -> Bool {
        lhs.id == rhs.id
    }
}

struct TabBarView: View {
    @Binding var tabs: [DXTab]
    @Binding var selectedTab: UUID?
    var onClose: (UUID) -> Void
    var onAdd: () -> Void
    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(tabs) { tab in
                        tabButton(tab)
                    }
                }
                .padding(.horizontal, 4)
            }

            Spacer()

            // Add tab
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.textTertiary)
                    .padding(5)
                    .background(theme.surfaceHover.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .padding(.vertical, 4)
        .background(theme.glass)
    }

    func tabButton(_ tab: DXTab) -> some View {
        let isSelected = selectedTab == tab.id

        return HStack(spacing: 6) {
            Image(systemName: tab.tool.icon)
                .font(.system(size: 10))
                .foregroundStyle(isSelected ? theme.accent : theme.textTertiary)

            Text(tab.title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? theme.text : theme.textSecondary)
                .lineLimit(1)

            if tabs.count > 1 {
                Button {
                    onClose(tab.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(theme.textGhost)
                        .padding(2)
                }
                .buttonStyle(.plain)
                .opacity(isSelected ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? theme.surface : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? theme.border : Color.clear, lineWidth: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedTab = tab.id
        }
    }
}

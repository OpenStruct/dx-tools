import SwiftUI

struct ToolHeader<Controls: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var controls: () -> Controls
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                // Tool name
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(t.accent)
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(t.text)
                }

                Divider().frame(height: 14)

                controls()

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(t.glass)

            Rectangle().fill(t.border).frame(height: 1)
        }
    }
}

extension ToolHeader where Controls == EmptyView {
    init(title: String, icon: String) {
        self.title = title
        self.icon = icon
        self.controls = { EmptyView() }
    }
}

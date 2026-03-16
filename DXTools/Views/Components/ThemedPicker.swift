import SwiftUI

/// A themed segmented-style picker that respects the app's dark/light theme.
/// Replaces SwiftUI `.pickerStyle(.segmented)` which has a white system background.
struct ThemedPicker<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String
    @Environment(\.theme) private var t

    var body: some View {
        HStack(spacing: 1) {
            ForEach(options, id: \.self) { option in
                let isActive = selection == option
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.system(size: 10, weight: isActive ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isActive ? t.accent : t.textTertiary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isActive ? t.accent.opacity(0.12) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(t.surface)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(t.border, lineWidth: 0.5))
    }
}

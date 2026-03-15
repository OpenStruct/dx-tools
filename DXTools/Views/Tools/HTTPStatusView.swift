import SwiftUI

struct HTTPStatusView: View {
    @State private var searchQuery = ""
    @State private var selectedCode: HTTPStatusService.StatusCode?
    @Environment(\.theme) private var t
    @Environment(AppState.self) private var appState

    var filtered: [HTTPStatusService.StatusCode] {
        HTTPStatusService.search(searchQuery)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").font(.system(size: 10, weight: .bold)).foregroundStyle(t.accent)
                TextField("Search by code, name, or description…", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.text)
                if !searchQuery.isEmpty {
                    SmallIconButton(title: "", icon: "xmark.circle.fill") { searchQuery = "" }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .background(t.glass)
            Rectangle().fill(t.border).frame(height: 1)

            HSplitView {
                // List
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(HTTPStatusService.StatusCode.Category.allCases, id: \.rawValue) { cat in
                            let codes = filtered.filter { $0.category == cat }
                            if !codes.isEmpty {
                                HStack(spacing: 6) {
                                    Circle().fill(categoryColor(cat)).frame(width: 6, height: 6)
                                    Text(cat.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .foregroundStyle(t.textTertiary).tracking(0.8)
                                    Rectangle().fill(t.border).frame(height: 0.5)
                                }
                                .padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 4)

                                ForEach(codes) { code in
                                    codeRow(code)
                                }
                            }
                        }
                    }
                    .padding(6)
                }
                .frame(minWidth: 350)

                // Detail
                VStack(spacing: 0) {
                    if let code = selectedCode {
                        VStack(spacing: 20) {
                            Spacer()
                            HStack(spacing: 0) {
                                Text("\(code.code)")
                                    .font(.system(size: 56, weight: .black, design: .rounded))
                                    .foregroundStyle(categoryColor(code.category))
                            }

                            Text(code.title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(t.text)

                            Text(code.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(t.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .frame(maxWidth: 340)

                            HStack(spacing: 6) {
                                Circle().fill(categoryColor(code.category)).frame(width: 8, height: 8)
                                Text(code.category.rawValue)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(t.textTertiary)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(t.surface)
                            .clipShape(Capsule())

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 10) {
                            Spacer()
                            Image(systemName: "number.circle").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(t.textGhost)
                            Text("Select a status code").font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(t.textTertiary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(t.editorBg)
                .frame(minWidth: 300)
            }
        }
        .background(t.bg)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 7) {
                    Image(systemName: "number.circle.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
                    Text("HTTP Status Codes").font(.system(size: 13, weight: .bold, design: .rounded))
                }
            }
        }
    }

    func codeRow(_ code: HTTPStatusService.StatusCode) -> some View {
        let isSelected = selectedCode?.code == code.code
        return HStack(spacing: 10) {
            Text("\(code.code)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(categoryColor(code.category))
                .frame(width: 36, alignment: .leading)
            Text(code.title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(t.text)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(isSelected ? t.accent.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
        .onTapGesture { selectedCode = code }
    }

    func categoryColor(_ cat: HTTPStatusService.StatusCode.Category) -> Color {
        switch cat {
        case .info: return t.info
        case .success: return t.success
        case .redirect: return t.warning
        case .clientError: return t.error
        case .serverError: return Color.red
        }
    }
}

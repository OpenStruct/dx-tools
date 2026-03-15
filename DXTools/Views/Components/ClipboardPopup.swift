import SwiftUI

struct ClipboardDetection {
    let type: DetectedType
    let preview: String
    let actions: [(title: String, icon: String, tool: Tool?)]

    enum DetectedType: String {
        case json = "JSON"
        case jwt = "JWT Token"
        case curl = "cURL Command"
        case base64 = "Base64"
        case uuid = "UUID"
        case color = "Color"
        case epoch = "Epoch Timestamp"
        case url = "URL"
        case unknown = "Text"
    }

    static func detect(_ content: String) -> ClipboardDetection {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // JWT
        if trimmed.components(separatedBy: ".").count == 3 && trimmed.count > 30 && !trimmed.contains(" ") {
            return ClipboardDetection(
                type: .jwt, preview: String(trimmed.prefix(50)) + "…",
                actions: [
                    ("Decode JWT", "key.horizontal.fill", .jwtDecoder),
                ]
            )
        }

        // JSON
        if (trimmed.first == "{" || trimmed.first == "["),
           let data = trimmed.data(using: .utf8),
           (try? JSONSerialization.jsonObject(with: data)) != nil {
            return ClipboardDetection(
                type: .json, preview: String(trimmed.prefix(80)),
                actions: [
                    ("Format JSON", "text.alignleft", .jsonFormatter),
                    ("→ Go Struct", "arrow.right.circle", .jsonToGo),
                    ("→ Swift", "swift", .jsonToSwift),
                    ("→ TypeScript", "chevron.left.forwardslash.chevron.right", .jsonToTypeScript),
                ]
            )
        }

        // cURL
        if trimmed.lowercased().hasPrefix("curl ") {
            return ClipboardDetection(
                type: .curl, preview: String(trimmed.prefix(60)),
                actions: [
                    ("Convert to Code", "terminal", .curlToCode),
                    ("Send Request", "paperplane", .apiRequest),
                ]
            )
        }

        // Color
        if trimmed.range(of: "^#[0-9a-fA-F]{3,8}$", options: .regularExpression) != nil {
            return ClipboardDetection(
                type: .color, preview: trimmed,
                actions: [("Convert Color", "paintpalette.fill", .colorConverter)]
            )
        }

        // UUID
        if trimmed.range(of: "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", options: .regularExpression) != nil {
            return ClipboardDetection(
                type: .uuid, preview: trimmed,
                actions: [("UUID Generator", "dice.fill", .uuidGenerator)]
            )
        }

        // Epoch
        if let ts = Double(trimmed), ts > 1_000_000_000 && ts < 99_999_999_999 {
            let date = Date(timeIntervalSince1970: ts)
            let f = DateFormatter(); f.dateFormat = "MMM d, yyyy HH:mm:ss"
            return ClipboardDetection(
                type: .epoch, preview: "\(trimmed) → \(f.string(from: date))",
                actions: [("Convert Epoch", "clock.fill", .epochConverter)]
            )
        }

        // Base64
        if trimmed.count > 10,
           let data = Data(base64Encoded: trimmed.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")),
           data.count > 0 {
            return ClipboardDetection(
                type: .base64, preview: "\(trimmed.prefix(40))… (\(data.count) bytes)",
                actions: [("Decode Base64", "lock.open.fill", .base64)]
            )
        }

        // URL
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return ClipboardDetection(
                type: .url, preview: trimmed,
                actions: [("Send Request", "paperplane.fill", .apiRequest)]
            )
        }

        return ClipboardDetection(
            type: .unknown, preview: String(trimmed.prefix(60)),
            actions: [
                ("Hash", "number.circle", .hashGenerator),
                ("Base64 Encode", "lock.doc", .base64),
            ]
        )
    }
}

struct ClipboardPopupView: View {
    let detection: ClipboardDetection
    @Environment(AppState.self) private var appState
    @Environment(\.theme) private var theme
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Text("Clipboard: \(detection.type.rawValue)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.text)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(theme.textTertiary)
                        .padding(4)
                        .background(theme.surfaceHover)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Preview
            Text(detection.preview)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)

            Rectangle().fill(theme.border).frame(height: 1)

            // Actions
            VStack(spacing: 2) {
                ForEach(Array(detection.actions.enumerated()), id: \.offset) { _, action in
                    Button {
                        if let tool = action.tool {
                            appState.selectTool(tool)
                        }
                        isPresented = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: action.icon)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(theme.accent)
                                .frame(width: 20)
                            Text(action.title)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(theme.text)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9))
                                .foregroundStyle(theme.textGhost)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 16, y: 6)
        .frame(width: 320)
    }
}

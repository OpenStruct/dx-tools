import SwiftUI

struct URLCoderView: View {
    @State private var vm = URLCoderViewModel()
    @Environment(\.theme) private var t

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(title: "URL Encoder / Decoder", icon: "link") {
                HStack(spacing: 1) {
                    ForEach(URLCoderViewModel.Mode.allCases, id: \.self) { mode in
                        Button {
                            vm.mode = mode; vm.process()
                        } label: {
                            Text(mode.rawValue)
                                .font(.system(size: 10, weight: vm.mode == mode ? .bold : .medium, design: .rounded))
                                .foregroundStyle(vm.mode == mode ? t.accent : t.textTertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(vm.mode == mode ? t.accent.opacity(0.1) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(t.glass)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.border, lineWidth: 0.5))
            }
            Rectangle().fill(t.border).frame(height: 1)

            HSplitView {
                // Input
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Input", icon: "arrow.down.doc") {
                        SmallIconButton(title: "Paste", icon: "doc.on.clipboard") {
                            if let str = NSPasteboard.general.string(forType: .string) {
                                vm.input = str; vm.process()
                            }
                        }
                        SmallIconButton(title: "Clear", icon: "trash") { vm.input = ""; vm.encoded = ""; vm.decoded = "" }
                    }
                    Rectangle().fill(t.border).frame(height: 1)
                    CodeEditor(text: $vm.input, isEditable: true, language: "text")
                        .onChange(of: vm.input) { _, _ in vm.process() }
                }
                .frame(minWidth: 300)

                Rectangle().fill(t.border).frame(width: 1)

                // Output
                VStack(spacing: 0) {
                    EditorPaneHeader(title: "Result", icon: "arrow.up.doc") {
                        SmallIconButton(title: "Copy", icon: "doc.on.doc") { vm.copyResult() }
                    }
                    Rectangle().fill(t.border).frame(height: 1)

                    switch vm.mode {
                    case .encode:
                        CodeEditor(text: .constant(vm.encoded), isEditable: false, language: "text")
                    case .decode:
                        CodeEditor(text: .constant(vm.decoded), isEditable: false, language: "text")
                    case .parse:
                        if let parts = vm.urlParts {
                            urlPartsView(parts)
                        } else {
                            emptyState
                        }
                    }
                }
                .frame(minWidth: 300)
            }
        }
        .background(t.editorBg)
    }

    func urlPartsView(_ parts: URLCoderService.URLParts) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                partRow("Scheme", parts.scheme)
                partRow("Host", parts.host)
                if !parts.port.isEmpty { partRow("Port", parts.port) }
                if !parts.path.isEmpty { partRow("Path", parts.path) }
                if !parts.fragment.isEmpty { partRow("Fragment", parts.fragment) }
                if !parts.query.isEmpty {
                    Text("QUERY PARAMETERS")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(t.textTertiary)
                        .tracking(0.8)
                        .padding(.top, 8)
                    ForEach(Array(parts.query.enumerated()), id: \.offset) { _, param in
                        HStack {
                            Text(param.name)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(t.accent)
                            Text("=")
                                .foregroundStyle(t.textGhost)
                            Text(param.value)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(t.text)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    func partRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(t.textTertiary)
                .frame(width: 70, alignment: .trailing)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(t.text)
                .textSelection(.enabled)
        }
    }

    var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "link").font(.system(size: 24, weight: .ultraLight)).foregroundStyle(t.textGhost)
            Text("Enter a URL to parse").font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(t.textTertiary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func toolTitle(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).foregroundStyle(t.accent)
            Text(title).font(.system(size: 13, weight: .bold, design: .rounded))
        }
    }
}

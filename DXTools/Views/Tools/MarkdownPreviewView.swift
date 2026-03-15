import SwiftUI
import WebKit

struct MarkdownPreviewView: View {
    @State private var vm = MarkdownViewModel()

    var body: some View {
        HSplitView {
            // Editor
            VStack(spacing: 0) {
            ToolHeader(title: "Markdown Preview", icon: "text.document")
                EditorPaneHeader(title: "Markdown", icon: "text.document") {
                    SmallIconButton(title: "Sample", icon: "doc.text") { vm.loadSample() }
                    SmallIconButton(title: "Clear", icon: "trash") { vm.clear() }
                }
                Divider()
                CodeEditor(text: $vm.input, isEditable: true, language: "markdown")
            }
            .frame(minWidth: 300)

            // Preview
            VStack(spacing: 0) {
                EditorPaneHeader(title: "Preview", icon: "eye") {
                    if !vm.htmlOutput.isEmpty {
                        SmallIconButton(title: "Copy HTML", icon: "doc.on.doc") { vm.copyHTML() }
                    }
                }
                Divider()

                if vm.htmlOutput.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "text.document")
                            .font(.system(size: 40)).foregroundStyle(.quaternary)
                        Text("Write markdown to see preview")
                            .font(.caption).foregroundStyle(.quaternary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    WebView(html: vm.htmlOutput)
                }
            }
            .frame(minWidth: 300)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .onChange(of: vm.input) { _, _ in vm.render() }
    }
}

struct WebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

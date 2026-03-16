import SwiftUI

/// Tools that maintain running state (servers, connections) and must not be destroyed on switch
private let statefulTools: Set<Tool> = [.webhookTester, .httpProxy, .databaseGUI]

struct ToolRouter: View {
    let tool: Tool

    // Stateful tool views — kept alive across switches
    @State private var webhookCreated = false
    @State private var httpProxyCreated = false
    @State private var databaseCreated = false

    var body: some View {
        ZStack {
            // Stateful tools — always in ZStack, shown/hidden via opacity
            if webhookCreated || tool == .webhookTester {
                WebhookView()
                    .opacity(tool == .webhookTester ? 1 : 0)
                    .allowsHitTesting(tool == .webhookTester)
                    .onAppear { webhookCreated = true }
            }

            if httpProxyCreated || tool == .httpProxy {
                HTTPProxyView()
                    .opacity(tool == .httpProxy ? 1 : 0)
                    .allowsHitTesting(tool == .httpProxy)
                    .onAppear { httpProxyCreated = true }
            }

            if databaseCreated || tool == .databaseGUI {
                DatabaseView()
                    .opacity(tool == .databaseGUI ? 1 : 0)
                    .allowsHitTesting(tool == .databaseGUI)
                    .onAppear { databaseCreated = true }
            }

            // Non-stateful tools — recreated on switch (no running state to preserve)
            if !statefulTools.contains(tool) {
                nonStatefulView(for: tool)
                    .id(tool)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
    }

    @ViewBuilder
    func nonStatefulView(for tool: Tool) -> some View {
        switch tool {
        case .jsonFormatter: JSONFormatterView()
        case .jsonToGo: JSONToGoView()
        case .jsonToSwift: JSONToSwiftView()
        case .jsonToTypeScript: JSONToTypeScriptView()
        case .jsonDiff: JSONDiffView()
        case .jwtDecoder: JWTDecoderView()
        case .base64: Base64View()
        case .hashGenerator: HashGeneratorView()
        case .uuidGenerator: UUIDGeneratorView()
        case .colorConverter: ColorConverterView()
        case .epochConverter: EpochConverterView()
        case .passwordGenerator: PasswordGeneratorView()
        case .envManager: EnvManagerView()
        case .curlToCode: CurlToCodeView()
        case .apiRequest: APIRequestView()
        case .regexTester: RegexTesterView()
        case .markdownPreview: MarkdownPreviewView()
        case .loremGenerator: LoremGeneratorView()
        case .portManager: PortManagerView()
        case .networkInfo: NetworkView()
        case .urlCoder: URLCoderView()
        case .unixPermissions: UnixPermView()
        case .cronParser: CronView()
        case .textDiff: TextDiffView()
        case .sshKey: SSHKeyView()
        case .docker: DockerView()
        case .gitStats: GitView()
        case .timestampConverter: TimestampView()
        case .qrCode: QRCodeView()
        case .imageBase64: ImageBase64View()
        case .sqlFormatter: SQLFormatterView()
        case .jsonSchema: JSONSchemaView()
        case .httpStatus: HTTPStatusView()
        case .nginxConfig: NginxConfigView()
        case .k8sGenerator: K8sView()
        case .envSwitcher: EnvSwitcherView()
        case .errorTracker: ErrorTrackerView()
        case .iconGenerator: IconGeneratorView()
        case .screenshotTool: ScreenshotView()
        case .apiClient: APIClientView()
        // Stateful tools handled in ZStack above
        case .webhookTester, .httpProxy, .databaseGUI: EmptyView()
        }
    }
}

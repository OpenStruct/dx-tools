import SwiftUI

struct ToolRouter: View {
    let tool: Tool

    var body: some View {
        Group {
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
            }
        }
        .id(tool) // Force view recreation on tool switch
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

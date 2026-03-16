import SwiftUI

@Observable
class NginxConfigViewModel {
    var serverName: String = "example.com"
    var listenPort: String = "80"
    var upstream: String = "localhost:3000"
    var sslCertPath: String = "/etc/ssl/certs/cert.pem"
    var sslKeyPath: String = "/etc/ssl/private/key.pem"
    var template: NginxConfigService.Template = .reverseProxy
    var enableGzip: Bool = true
    var enableLogging: Bool = true
    var rootPath: String = "/var/www/html"
    var redirectTarget: String = "https://example.com"
    var upstreamServers: [String] = ["localhost:3001", "localhost:3002"]
    var newServer: String = ""
    var output: String = ""
    var warnings: [String] = []

    func generate() {
        let config = NginxConfigService.Config(
            serverName: serverName,
            listenPort: Int(listenPort) ?? 80,
            upstream: upstream,
            sslCertPath: sslCertPath,
            sslKeyPath: sslKeyPath,
            template: template,
            enableGzip: enableGzip,
            enableLogging: enableLogging,
            workerConnections: 1024,
            upstreamServers: upstreamServers,
            rootPath: rootPath,
            redirectTarget: redirectTarget
        )
        output = NginxConfigService.generate(config)
        warnings = NginxConfigService.validate(output)
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }

    func addServer() {
        let s = newServer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return }
        upstreamServers.append(s)
        newServer = ""
    }

    func removeServer(at index: Int) {
        guard upstreamServers.indices.contains(index) else { return }
        upstreamServers.remove(at: index)
    }

    func loadPreset(_ preset: Preset) {
        switch preset {
        case .development:
            serverName = "localhost"
            listenPort = "8080"
            upstream = "localhost:3000"
            template = .reverseProxy
            enableGzip = false
            enableLogging = true
        case .production:
            serverName = "api.example.com"
            listenPort = "443"
            upstream = "localhost:3000"
            template = .ssl
            enableGzip = true
            enableLogging = true
        case .dockerCompose:
            serverName = "app.local"
            listenPort = "80"
            upstream = "app:3000"
            template = .reverseProxy
            enableGzip = true
            enableLogging = true
            upstreamServers = ["app:3000", "worker:3000"]
        }
        generate()
    }

    enum Preset: String, CaseIterable {
        case development = "Dev"
        case production = "Prod"
        case dockerCompose = "Docker"
    }
}

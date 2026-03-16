import SwiftUI

@Observable
class WebhookViewModel {
    var server: WebhookServer?
    var requests: [WebhookService.WebhookRequest] = []
    var selectedRequest: WebhookService.WebhookRequest?
    var isRunning: Bool = false
    var port: String = "9999"
    var responseCode: String = "200"
    var responseBody: String = ""
    var error: String?

    func startServer() {
        let config = WebhookService.ServerConfig(
            port: Int(port) ?? 9999,
            responseStatusCode: Int(responseCode) ?? 200,
            responseBody: responseBody
        )
        let srv = WebhookServer(config: config)
        srv.onRequest = { [weak self] request in
            self?.requests.insert(request, at: 0)
            if self?.selectedRequest == nil {
                self?.selectedRequest = request
            }
        }
        do {
            try srv.start()
            server = srv
            isRunning = true
            error = nil
        } catch {
            self.error = "Failed to start: \(error.localizedDescription)"
        }
    }

    func stopServer() {
        server?.stop()
        server = nil
        isRunning = false
    }

    func clearRequests() {
        requests.removeAll()
        selectedRequest = nil
    }

    func copyEndpoint() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("http://localhost:\(port)", forType: .string)
    }

    func copyAsCurl(_ request: WebhookService.WebhookRequest) {
        let curl = WebhookService.generateCurl(request)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(curl, forType: .string)
    }

    func copyBody(_ request: WebhookService.WebhookRequest) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(request.body, forType: .string)
    }
}

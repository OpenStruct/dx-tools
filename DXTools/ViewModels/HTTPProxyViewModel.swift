import SwiftUI

@Observable
class HTTPProxyViewModel {
    var exchanges: [HTTPProxyService.CapturedExchange] = []
    var selectedExchange: HTTPProxyService.CapturedExchange?
    var isRunning: Bool = false
    var port: String = "8888"
    var error: String?
    var searchQuery: String = ""
    var filterMethods: Set<String> = []
    var isRecording: Bool = true

    var filteredExchanges: [HTTPProxyService.CapturedExchange] {
        HTTPProxyService.filter(exchanges, search: searchQuery, methods: filterMethods)
    }

    // Note: Full proxy requires NWListener implementation similar to WebhookServer.
    // For now, provides capture/display of manually added or imported exchanges.

    func addDemoExchanges() {
        let req1 = HTTPProxyService.CapturedRequest(
            method: "GET", url: "https://api.github.com/repos/OpenStruct/dx-tools",
            host: "api.github.com", path: "/repos/OpenStruct/dx-tools",
            headers: [("Accept", "application/json"), ("Authorization", "Bearer ...")],
            bodyString: nil, contentType: "application/json", size: 245
        )
        let res1 = HTTPProxyService.CapturedResponse(
            statusCode: 200, statusText: "OK",
            headers: [("Content-Type", "application/json"), ("Cache-Control", "max-age=60")],
            bodyString: "{\n  \"id\": 1,\n  \"name\": \"dx-tools\",\n  \"full_name\": \"OpenStruct/dx-tools\"\n}",
            contentType: "application/json", size: 1024
        )
        exchanges.insert(HTTPProxyService.CapturedExchange(
            request: req1, response: res1, duration: 0.245, state: .complete
        ), at: 0)
    }

    func clearTraffic() {
        exchanges.removeAll()
        selectedExchange = nil
    }

    func toggleMethod(_ method: String) {
        if filterMethods.contains(method) {
            filterMethods.remove(method)
        } else {
            filterMethods.insert(method)
        }
    }

    func copyAsCurl() {
        guard let exchange = selectedExchange else { return }
        let curl = HTTPProxyService.generateCurl(exchange)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(curl, forType: .string)
    }

    func copyBody() {
        guard let body = selectedExchange?.response?.bodyString else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(body, forType: .string)
    }
}

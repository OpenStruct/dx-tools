---
name: dx-webhook-tester
description: Build the Webhook Tester tool for DX Tools. A local RequestBin — starts an HTTP server to receive, inspect, and replay webhooks. Uses Foundation NWListener for the server. Follow dx-tools-feature skill for architecture.
---

# Webhook Tester

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `webhookTester`
- **Category**: `.devops`
- **Display name**: "Webhook Tester"
- **Icon**: `"antenna.radiowaves.left.and.right"`
- **Description**: "Receive, inspect, and replay webhooks — local RequestBin with zero setup"

## Important: Zero External Dependencies

Use Apple's `Network` framework (`NWListener`) for the HTTP server — no Vapor, no Swifter, no external packages.

## Service: `WebhookService.swift`

### Models

```swift
struct WebhookRequest: Identifiable {
    var id: UUID
    var timestamp: Date
    var method: String          // GET, POST, PUT, DELETE, PATCH
    var path: String            // /webhook, /api/callback, etc.
    var headers: [(key: String, value: String)]
    var body: String
    var queryParams: [(key: String, value: String)]
    var contentType: String
    var sourceIP: String
    var bodySize: Int           // bytes
}

struct ServerConfig {
    var port: Int               // default 9999
    var responseSatusCode: Int  // default 200
    var responseBody: String    // default ""
    var responseHeaders: [(key: String, value: String)]
}
```

### HTTP Server Implementation

Use `NWListener` from the `Network` framework:

```swift
import Network

class WebhookServer {
    private var listener: NWListener?
    private(set) var isRunning: Bool = false
    var onRequest: ((WebhookRequest) -> Void)?
    var config: ServerConfig

    init(config: ServerConfig) { self.config = config }

    func start() throws {
        let params = NWParameters.tcp
        listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: UInt16(config.port)))
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener?.stateUpdateHandler = { state in
            // Handle .ready, .failed, etc.
        }
        listener?.start(queue: .global(qos: .userInitiated))
        isRunning = true
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data, let self = self else { return }
            let request = self.parseHTTPRequest(data, from: connection)
            DispatchQueue.main.async {
                self.onRequest?(request)
            }
            // Send configured response
            let response = self.buildHTTPResponse()
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func parseHTTPRequest(_ data: Data, from connection: NWConnection) -> WebhookRequest {
        // Parse raw HTTP: method, path, headers, body
        // Split on \r\n\r\n for header/body boundary
        // Parse first line for method + path
        // Parse header lines for key: value pairs
    }

    private func buildHTTPResponse() -> Data {
        var response = "HTTP/1.1 \(config.responseSatusCode) OK\r\n"
        response += "Content-Type: text/plain\r\n"
        for (key, value) in config.responseHeaders {
            response += "\(key): \(value)\r\n"
        }
        response += "Content-Length: \(config.responseBody.utf8.count)\r\n"
        response += "\r\n"
        response += config.responseBody
        return Data(response.utf8)
    }
}
```

### Replay Method

```swift
static func replay(_ request: WebhookRequest, to url: String) async -> (statusCode: Int, body: String, error: String?) {
    // Rebuild the request and send via URLSession
    var urlRequest = URLRequest(url: URL(string: url)!)
    urlRequest.httpMethod = request.method
    for (key, value) in request.headers {
        urlRequest.setValue(value, forHTTPHeaderField: key)
    }
    urlRequest.httpBody = request.body.data(using: .utf8)
    // Send and return response
}
```

## ViewModel: `WebhookViewModel.swift`

```swift
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
    var replayURL: String = ""
    var filter: String = ""

    var filteredRequests: [WebhookService.WebhookRequest] { /* filter by method, path, body */ }

    func startServer() { /* create WebhookServer, set onRequest callback, start */ }
    func stopServer() { /* stop server, update state */ }
    func clearRequests() { requests.removeAll() }
    func replay(_ request: WebhookService.WebhookRequest) async { /* replay to replayURL */ }
    func copyAsCurl(_ request: WebhookService.WebhookRequest) -> String { /* build curl command */ }
}
```

## View: `WebhookView.swift`

### Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ToolHeader: "Webhook Tester"  Port:[9999] [▶ Start] [Stop] │
├───────────────────────────────┬─────────────────────────────┤
│ REQUESTS (12)         [Clear] │  REQUEST DETAIL             │
│                               │                             │
│ ● POST /webhook     12:34:05 │  POST /webhook              │
│ ● GET  /health      12:34:02 │  March 15, 2026 12:34:05    │
│ ● POST /callback    12:33:58 │                              │
│ ○ PUT  /api/data    12:33:55 │  HEADERS                    │
│                               │  Content-Type: application/ │
│                               │  X-Hook-ID: abc123          │
│                               │                             │
│                               │  BODY                       │
│                               │  { "event": "push", ...}    │
│                               │                             │
│                               │  [Copy cURL] [Replay] [Copy]│
├───────────────────────────────┴─────────────────────────────┤
│ Response Config: Status [200]  Body [OK]                    │
└─────────────────────────────────────────────────────────────┘
```

**Left panel — Request list:**
- Live-updating list as webhooks arrive
- Color-coded method badges: POST=orange, GET=green, PUT=blue, DELETE=red
- Timestamp, path, body size
- Click to view details
- Search/filter by method or path
- "Clear" button
- Empty state: "Waiting for webhooks…" with the endpoint URL to copy

**Right panel — Request detail:**
- Full request info: method, path, timestamp, source IP
- Headers list (key-value, monospaced)
- Body with syntax highlighting (auto-detect JSON)
- Query params (if any)
- Action buttons: Copy as cURL, Replay to URL, Copy body

**Bottom bar — Response config:**
- Status code field
- Response body field
- Custom response headers (expandable)
- These configure what the server responds with to incoming webhooks

### Key UX

- Show the webhook URL prominently: `http://localhost:9999` with copy button
- Green pulsing dot when server is running
- Request count badge
- Auto-scroll to latest request (with toggle to disable)

## Tests: `WebhookServiceTests.swift`

Since the server uses Network framework (needs runtime), test the parsing and utility methods:

- `testParseHTTPRequest` — parse raw HTTP bytes into WebhookRequest
- `testParseGETRequest` — method, path, no body
- `testParsePOSTWithJSON` — body extracted, content-type detected
- `testParseHeaders` — multiple headers parsed correctly
- `testParseQueryParams` — `?key=value&foo=bar` parsed
- `testBuildHTTPResponse` — correct HTTP response format
- `testBuildHTTPResponseCustomCode` — 201, 404, 500
- `testBuildHTTPResponseWithHeaders` — custom headers in response
- `testCurlGeneration` — generates valid cURL command from request
- `testEmptyBody` — handles requests with no body

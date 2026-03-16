---
name: dx-http-interceptor
description: Build the HTTP Interceptor/Proxy tool for DX Tools. A native Charles Proxy alternative — intercepts, inspects, and modifies HTTP/HTTPS traffic. Uses NWListener as a forward proxy. Follow dx-tools-feature skill for architecture.
---

# HTTP Interceptor / Proxy

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `httpInterceptor`
- **Category**: `.devops`
- **Display name**: "HTTP Proxy"
- **Icon**: `"arrow.left.arrow.right.circle"`
- **Description**: "Inspect and modify HTTP traffic — native Charles/Proxyman alternative"

## Scope

This is a **forward HTTP proxy** that captures traffic from apps configured to use it. It does NOT do MITM HTTPS interception (that requires code signing + trust certificates). Scope:

- HTTP traffic capture and display
- HTTPS traffic shows host/URL but not decrypted body (CONNECT tunnels)
- Request/response modification for HTTP
- Breakpoints (pause on matching requests)
- Traffic filtering and search

## Service: `HTTPProxyService.swift`

### Models

```swift
struct CapturedExchange: Identifiable {
    var id: UUID
    var timestamp: Date
    var request: CapturedRequest
    var response: CapturedResponse?
    var duration: TimeInterval?
    var state: ExchangeState     // .pending, .complete, .error, .blocked
}

struct CapturedRequest {
    var method: String
    var url: String
    var host: String
    var path: String
    var headers: [(key: String, value: String)]
    var body: Data?
    var bodyString: String?
    var contentType: String
    var size: Int
}

struct CapturedResponse {
    var statusCode: Int
    var statusText: String
    var headers: [(key: String, value: String)]
    var body: Data?
    var bodyString: String?
    var contentType: String
    var size: Int
}

enum ExchangeState: String {
    case pending = "Pending"
    case complete = "Complete"
    case error = "Error"
    case blocked = "Blocked"
}
```

### Proxy Server

Use `NWListener` to create a forward proxy:

```swift
class ProxyServer {
    private var listener: NWListener?
    var port: Int = 8888
    var isRunning: Bool = false
    var onExchange: ((CapturedExchange) -> Void)?
    var blockRules: [BlockRule] = []
    var breakpointRules: [BreakpointRule] = []

    func start() throws { /* NWListener on port, handle connections */ }
    func stop() { /* cancel listener */ }

    private func handleConnection(_ conn: NWConnection) {
        // 1. Read HTTP request from client
        // 2. Parse method, host, path, headers
        // 3. Check block rules — if blocked, return 403
        // 4. Check breakpoint rules — if hit, pause and notify
        // 5. Forward request to target server via URLSession
        // 6. Capture response
        // 7. Send response back to client
        // 8. Emit CapturedExchange
    }
}
```

For CONNECT tunnels (HTTPS):
```swift
// Respond with "200 Connection Established"
// Create a tunnel — relay bytes between client and server
// Record the host but not the encrypted content
```

### Filter / Search

```swift
struct TrafficFilter {
    var searchText: String
    var methods: Set<String>     // empty = all
    var statusCodes: Set<Int>    // empty = all
    var hosts: Set<String>       // empty = all
    var contentTypes: Set<String>
    var minSize: Int?
    var maxSize: Int?
}

static func filter(_ exchanges: [CapturedExchange], by: TrafficFilter) -> [CapturedExchange]
```

## ViewModel: `HTTPProxyViewModel.swift`

```swift
@Observable
class HTTPProxyViewModel {
    var proxy: ProxyServer?
    var exchanges: [HTTPProxyService.CapturedExchange] = []
    var selectedExchange: HTTPProxyService.CapturedExchange?
    var isRunning: Bool = false
    var port: String = "8888"
    var error: String?
    var searchQuery: String = ""
    var filterMethods: Set<String> = []
    var isRecording: Bool = true

    var filteredExchanges: [HTTPProxyService.CapturedExchange] { /* filter logic */ }

    func startProxy() { }
    func stopProxy() { }
    func clearTraffic() { }
    func toggleRecording() { }
    func exportHAR() -> String { /* HTTP Archive format */ }
    func copyAsCurl(_ exchange: HTTPProxyService.CapturedExchange) -> String { }
}
```

## View: `HTTPProxyView.swift`

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ ToolHeader: "HTTP Proxy"  Port:[8888] [▶ Start] [⏸ Pause]   │
│ [🔴 Recording] Filter: [________]  Methods: [GET POST ...]   │
├──────────────────────────────────────────────────────────────┤
│ # │ Method │ Host           │ Path        │ Status │ Size   │
│───┼────────┼────────────────┼─────────────┼────────┼────────│
│ 1 │ GET    │ api.github.com │ /repos/...  │ 200    │ 4.2KB  │
│ 2 │ POST   │ example.com    │ /api/data   │ 201    │ 128B   │
│ 3 │ GET    │ cdn.example.co │ /style.css  │ 304    │ 0B     │
├──────────────────────────────────────────────────────────────┤
│ REQUEST                    │ RESPONSE                        │
│ GET /repos/OpenStruct/...  │ 200 OK                          │
│                            │                                 │
│ Headers:                   │ Headers:                        │
│ Accept: application/json   │ Content-Type: application/json  │
│ Authorization: Bearer ...  │ Cache-Control: max-age=60       │
│                            │                                 │
│ Body: (none)               │ Body:                           │
│                            │ { "id": 1, "name": "dx" ... }  │
│ [Copy cURL]                │ [Copy Body]  [Format JSON]      │
└──────────────────────────────────────────────────────────────┘
```

**Top section — Traffic list:**
- Auto-scrolling table of captured exchanges
- Color-coded status: 2xx=green, 3xx=blue, 4xx=orange, 5xx=red
- Method badges with colors
- Size column (human-readable: B, KB, MB)
- Duration column (ms)
- Click to select and view details

**Bottom section — Detail (split request/response):**
- Request: method, URL, headers, body (with JSON formatting if applicable)
- Response: status, headers, body (with JSON formatting)
- Copy cURL button
- Copy body button
- Image preview for image responses

**Setup instructions panel** (shown when first opened):
- How to configure system proxy: System Preferences → Network → Proxies → HTTP Proxy → localhost:8888
- Or per-app: `http_proxy=http://localhost:8888 curl https://example.com`

## Tests: `HTTPProxyServiceTests.swift`

- `testParseHTTPRequest` — raw bytes to CapturedRequest
- `testParseHTTPResponse` — raw bytes to CapturedResponse  
- `testFilterByMethod` — filters GET only
- `testFilterByHost` — filters specific host
- `testFilterByStatus` — filters 4xx codes
- `testFilterBySearch` — text search across URL and body
- `testCurlGeneration` — valid cURL from captured exchange
- `testHARExport` — valid JSON HAR format
- `testStatusColor` — 2xx green, 4xx orange, 5xx red
- `testSizeFormatting` — bytes to human readable

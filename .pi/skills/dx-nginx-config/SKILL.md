---
name: dx-nginx-config
description: Build the Nginx Config Generator tool for DX Tools. Generates nginx configuration snippets for reverse proxy, static files, SSL/TLS, load balancing, rate limiting, WebSocket, and CORS. Follow dx-tools-feature skill for architecture.
---

# Nginx Config Generator

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `nginxConfig`
- **Category**: `.devops`
- **Display name**: "Nginx Config"
- **Icon**: `"server.rack"`
- **Description**: "Generate nginx configuration snippets for reverse proxy, SSL, static files, load balancing"

## Service: `NginxConfigService.swift`

### Templates to Support

```swift
enum Template: String, CaseIterable {
    case reverseProxy = "Reverse Proxy"
    case staticSite = "Static Site"
    case ssl = "SSL/TLS"
    case loadBalancer = "Load Balancer"
    case rateLimit = "Rate Limiting"
    case websocket = "WebSocket"
    case cors = "CORS"
    case redirect = "Redirect"
    case basicAuth = "Basic Auth"
    case caching = "Caching"
}
```

### Config Model

```swift
struct Config {
    var serverName: String        // e.g. "api.example.com"
    var listenPort: Int           // e.g. 80, 443
    var upstream: String          // e.g. "localhost:3000"
    var sslCertPath: String       // e.g. "/etc/ssl/certs/cert.pem"
    var sslKeyPath: String        // e.g. "/etc/ssl/private/key.pem"
    var template: Template
    var enableGzip: Bool
    var enableLogging: Bool
    var workerConnections: Int    // e.g. 1024
    var upstreamServers: [String] // for load balancer: ["server1:3000", "server2:3000"]
}
```

### Generation Logic

Each template should output a complete, production-ready nginx config block:

- **Reverse Proxy**: `server` block with `proxy_pass`, `proxy_set_header`, timeouts, buffer sizes
- **Static Site**: `root`, `index`, `try_files`, `location` blocks for assets with cache headers
- **SSL/TLS**: `ssl_certificate`, `ssl_protocols`, HSTS header, redirect HTTP→HTTPS
- **Load Balancer**: `upstream` block with multiple servers, `proxy_pass` to upstream, health checks
- **Rate Limiting**: `limit_req_zone`, `limit_req`, burst, nodelay
- **WebSocket**: `proxy_http_version 1.1`, `Upgrade`, `Connection` headers
- **CORS**: `add_header Access-Control-*`, preflight `OPTIONS` handling
- **Redirect**: 301/302 redirects, www→non-www or vice versa
- **Basic Auth**: `auth_basic`, `auth_basic_user_file`
- **Caching**: `proxy_cache_path`, `proxy_cache`, cache key, bypass rules

Also implement:
- `static func validate(_ config: String) -> [String]` — Returns warnings (missing semicolons, unclosed braces, deprecated directives)

## View: `NginxConfigView.swift`

### Layout: HSplitView

**Left panel — Config form:**
- `ThemedPicker` for template selection at top
- Form fields based on selected template:
  - Server name (TextField)
  - Listen port (TextField, numeric)
  - Upstream URL (TextField)
  - SSL cert/key paths (only for SSL template)
  - Upstream servers list (only for load balancer — add/remove rows)
  - Toggle: Enable Gzip, Enable Logging
- "Generate" button (`DXButton`)
- Quick presets row: "Development", "Production", "Docker Compose"

**Right panel — Generated config:**
- `CodeEditor` (read-only) showing the nginx config with syntax highlighting language "nginx" (falls back to plain text)
- Copy button, Save to file button
- Validation warnings at the bottom (if any)

### Presets

- **Development**: localhost:3000 reverse proxy, no SSL, gzip off
- **Production**: SSL + HSTS + gzip + rate limiting + caching
- **Docker Compose**: upstream by container name, internal network

## Tests: `NginxConfigServiceTests.swift`

Test each template generates valid output:
- `testReverseProxy` — contains `proxy_pass`, `server_name`
- `testStaticSite` — contains `root`, `try_files`
- `testSSL` — contains `ssl_certificate`, `ssl_protocols`, HSTS
- `testLoadBalancer` — contains `upstream` block with all servers
- `testRateLimit` — contains `limit_req_zone`, `limit_req`
- `testWebSocket` — contains `Upgrade`, `Connection` headers
- `testCORS` — contains `Access-Control-Allow-Origin`
- `testGzipEnabled` — contains `gzip on` when enabled
- `testValidation` — catches missing semicolons
- `testEmptyServerName` — handles gracefully

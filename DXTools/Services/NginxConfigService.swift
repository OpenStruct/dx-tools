import Foundation

struct NginxConfigService {
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

    struct Config {
        var serverName: String = "example.com"
        var listenPort: Int = 80
        var upstream: String = "localhost:3000"
        var sslCertPath: String = "/etc/ssl/certs/cert.pem"
        var sslKeyPath: String = "/etc/ssl/private/key.pem"
        var template: Template = .reverseProxy
        var enableGzip: Bool = true
        var enableLogging: Bool = true
        var workerConnections: Int = 1024
        var upstreamServers: [String] = ["localhost:3001", "localhost:3002"]
        var rootPath: String = "/var/www/html"
        var redirectTarget: String = "https://example.com"
    }

    static func generate(_ config: Config) -> String {
        var lines: [String] = []
        switch config.template {
        case .reverseProxy:
            lines = reverseProxy(config)
        case .staticSite:
            lines = staticSite(config)
        case .ssl:
            lines = sslConfig(config)
        case .loadBalancer:
            lines = loadBalancer(config)
        case .rateLimit:
            lines = rateLimit(config)
        case .websocket:
            lines = websocket(config)
        case .cors:
            lines = cors(config)
        case .redirect:
            lines = redirect(config)
        case .basicAuth:
            lines = basicAuth(config)
        case .caching:
            lines = caching(config)
        }
        if config.enableGzip {
            lines.insert(contentsOf: gzipBlock(), at: 0)
            lines.insert("", at: gzipBlock().count)
        }
        return lines.joined(separator: "\n")
    }

    static func validate(_ config: String) -> [String] {
        var warnings: [String] = []
        let lines = config.components(separatedBy: .newlines)
        var braceCount = 0
        for (i, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            braceCount += trimmed.filter { $0 == "{" }.count
            braceCount -= trimmed.filter { $0 == "}" }.count
            if !trimmed.hasSuffix("{") && !trimmed.hasSuffix("}") && !trimmed.hasPrefix("#") && !trimmed.hasSuffix(";") && !trimmed.isEmpty {
                if !trimmed.contains("{") && !trimmed.contains("}") {
                    warnings.append("Line \(i+1): Missing semicolon — \"\(trimmed)\"")
                }
            }
        }
        if braceCount > 0 { warnings.append("Unclosed brace(s): \(braceCount) opening without closing") }
        if braceCount < 0 { warnings.append("Extra closing brace(s): \(abs(braceCount))") }
        return warnings
    }

    // MARK: - Templates

    private static func reverseProxy(_ c: Config) -> [String] {
        return [
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_http_version 1.1;",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
            "        proxy_set_header X-Forwarded-Proto $scheme;",
            "",
            "        proxy_connect_timeout 60s;",
            "        proxy_send_timeout 60s;",
            "        proxy_read_timeout 60s;",
            "        proxy_buffering on;",
            "        proxy_buffer_size 4k;",
            "        proxy_buffers 8 4k;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func staticSite(_ c: Config) -> [String] {
        return [
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "    root \(c.rootPath);",
            "    index index.html index.htm;",
            "",
            logging(c),
            "",
            "    location / {",
            "        try_files $uri $uri/ /index.html;",
            "    }",
            "",
            "    # Static asset caching",
            "    location ~* \\.(js|css|png|jpg|jpeg|gif|ico|svg|woff2?)$ {",
            "        expires 30d;",
            "        add_header Cache-Control \"public, immutable\";",
            "    }",
            "",
            "    # Security headers",
            "    add_header X-Frame-Options \"SAMEORIGIN\";",
            "    add_header X-Content-Type-Options \"nosniff\";",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func sslConfig(_ c: Config) -> [String] {
        return [
            "# Redirect HTTP → HTTPS",
            "server {",
            "    listen 80;",
            "    server_name \(c.serverName);",
            "    return 301 https://$server_name$request_uri;",
            "}",
            "",
            "server {",
            "    listen 443 ssl http2;",
            "    server_name \(c.serverName);",
            "",
            "    ssl_certificate \(c.sslCertPath);",
            "    ssl_certificate_key \(c.sslKeyPath);",
            "",
            "    # Modern SSL configuration",
            "    ssl_protocols TLSv1.2 TLSv1.3;",
            "    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;",
            "    ssl_prefer_server_ciphers off;",
            "    ssl_session_cache shared:SSL:10m;",
            "    ssl_session_timeout 1d;",
            "",
            "    # HSTS",
            "    add_header Strict-Transport-Security \"max-age=63072000; includeSubDomains; preload\" always;",
            "",
            logging(c),
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
            "        proxy_set_header X-Forwarded-Proto $scheme;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func loadBalancer(_ c: Config) -> [String] {
        var block = [
            "upstream backend {",
        ]
        for server in c.upstreamServers {
            block.append("    server \(server);")
        }
        block += [
            "}",
            "",
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    location / {",
            "        proxy_pass http://backend;",
            "        proxy_http_version 1.1;",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
            "    }",
            "",
            "    location /health {",
            "        access_log off;",
            "        return 200 \"OK\";",
            "        add_header Content-Type text/plain;",
            "    }",
            "}",
        ]
        return block.flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func rateLimit(_ c: Config) -> [String] {
        return [
            "# Rate limiting zone — 10 requests/second per IP",
            "limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;",
            "",
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    location / {",
            "        limit_req zone=api_limit burst=20 nodelay;",
            "        limit_req_status 429;",
            "",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "    }",
            "",
            "    # Custom 429 error page",
            "    error_page 429 /429.html;",
            "    location = /429.html {",
            "        internal;",
            "        return 429 '{\"error\": \"Too Many Requests\"}';",
            "        add_header Content-Type application/json;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func websocket(_ c: Config) -> [String] {
        return [
            "map $http_upgrade $connection_upgrade {",
            "    default upgrade;",
            "    ''      close;",
            "}",
            "",
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_http_version 1.1;",
            "        proxy_set_header Upgrade $http_upgrade;",
            "        proxy_set_header Connection $connection_upgrade;",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "",
            "        proxy_read_timeout 86400s;",
            "        proxy_send_timeout 86400s;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func cors(_ c: Config) -> [String] {
        return [
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    # CORS headers",
            "    add_header Access-Control-Allow-Origin \"*\" always;",
            "    add_header Access-Control-Allow-Methods \"GET, POST, PUT, DELETE, OPTIONS\" always;",
            "    add_header Access-Control-Allow-Headers \"Authorization, Content-Type, X-Requested-With\" always;",
            "    add_header Access-Control-Max-Age 86400 always;",
            "",
            "    # Preflight requests",
            "    if ($request_method = OPTIONS) {",
            "        return 204;",
            "    }",
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func redirect(_ c: Config) -> [String] {
        return [
            "# Redirect www → non-www",
            "server {",
            "    listen \(c.listenPort);",
            "    server_name www.\(c.serverName);",
            "    return 301 \(c.redirectTarget)$request_uri;",
            "}",
            "",
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func basicAuth(_ c: Config) -> [String] {
        return [
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    auth_basic \"Restricted Area\";",
            "    auth_basic_user_file /etc/nginx/.htpasswd;",
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_set_header Host $host;",
            "        proxy_set_header X-Real-IP $remote_addr;",
            "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
            "    }",
            "",
            "    # Exclude health check from auth",
            "    location /health {",
            "        auth_basic off;",
            "        return 200 \"OK\";",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    private static func caching(_ c: Config) -> [String] {
        return [
            "proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=app_cache:10m max_size=1g inactive=60m;",
            "",
            "server {",
            "    listen \(c.listenPort);",
            "    server_name \(c.serverName);",
            "",
            logging(c),
            "",
            "    location / {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_set_header Host $host;",
            "",
            "        # Caching",
            "        proxy_cache app_cache;",
            "        proxy_cache_key $scheme$request_method$host$request_uri;",
            "        proxy_cache_valid 200 10m;",
            "        proxy_cache_valid 404 1m;",
            "        proxy_cache_use_stale error timeout updating;",
            "        proxy_cache_bypass $http_cache_control;",
            "        add_header X-Cache-Status $upstream_cache_status;",
            "    }",
            "",
            "    # Bypass cache for dynamic content",
            "    location /api/ {",
            "        proxy_pass http://\(c.upstream);",
            "        proxy_cache off;",
            "        proxy_set_header Host $host;",
            "    }",
            "}",
        ].flatMap { $0.contains("\n") ? $0.components(separatedBy: "\n") : [$0] }
    }

    // MARK: - Helpers

    private static func logging(_ c: Config) -> String {
        if c.enableLogging {
            return "    access_log /var/log/nginx/\(c.serverName).access.log;\n    error_log /var/log/nginx/\(c.serverName).error.log;"
        }
        return "    access_log off;"
    }

    private static func gzipBlock() -> [String] {
        return [
            "# Gzip compression",
            "gzip on;",
            "gzip_vary on;",
            "gzip_min_length 1024;",
            "gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;",
        ]
    }
}

import Foundation

struct HTTPProxyService {
    struct CapturedExchange: Identifiable {
        var id: UUID = UUID()
        var timestamp: Date = Date()
        var request: CapturedRequest
        var response: CapturedResponse?
        var duration: TimeInterval?
        var state: ExchangeState = .pending
    }

    struct CapturedRequest {
        var method: String
        var url: String
        var host: String
        var path: String
        var headers: [(key: String, value: String)]
        var bodyString: String?
        var contentType: String
        var size: Int
    }

    struct CapturedResponse {
        var statusCode: Int
        var statusText: String
        var headers: [(key: String, value: String)]
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

    // MARK: - Parsing

    static func parseRequest(_ data: Data) -> CapturedRequest {
        let raw = String(data: data, encoding: .utf8) ?? ""
        let parts = raw.components(separatedBy: "\r\n\r\n")
        let headerSection = parts.first ?? ""
        let body = parts.count > 1 ? parts.dropFirst().joined(separator: "\r\n\r\n") : nil

        let headerLines = headerSection.components(separatedBy: "\r\n")
        let requestLine = headerLines.first ?? ""
        let requestParts = requestLine.components(separatedBy: " ")
        let method = requestParts.first ?? "GET"
        let url = requestParts.count > 1 ? requestParts[1] : "/"

        var headers: [(key: String, value: String)] = []
        var contentType = ""
        var host = ""
        for line in headerLines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            headers.append((key: key, value: value))
            if key.lowercased() == "content-type" { contentType = value }
            if key.lowercased() == "host" { host = value }
        }

        let path = URL(string: url)?.path ?? url
        return CapturedRequest(method: method, url: url, host: host, path: path,
                              headers: headers, bodyString: body, contentType: contentType,
                              size: data.count)
    }

    static func parseResponse(_ data: Data) -> CapturedResponse {
        let raw = String(data: data, encoding: .utf8) ?? ""
        let parts = raw.components(separatedBy: "\r\n\r\n")
        let headerSection = parts.first ?? ""
        let body = parts.count > 1 ? parts.dropFirst().joined(separator: "\r\n\r\n") : nil

        let headerLines = headerSection.components(separatedBy: "\r\n")
        let statusLine = headerLines.first ?? ""
        let statusParts = statusLine.components(separatedBy: " ")
        let statusCode = statusParts.count > 1 ? Int(statusParts[1]) ?? 0 : 0
        let statusText = statusParts.count > 2 ? statusParts.dropFirst(2).joined(separator: " ") : ""

        var headers: [(key: String, value: String)] = []
        var contentType = ""
        for line in headerLines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            headers.append((key: key, value: value))
            if key.lowercased() == "content-type" { contentType = value }
        }

        return CapturedResponse(statusCode: statusCode, statusText: statusText,
                               headers: headers, bodyString: body, contentType: contentType,
                               size: data.count)
    }

    // MARK: - Filtering

    static func filter(_ exchanges: [CapturedExchange], search: String, methods: Set<String>) -> [CapturedExchange] {
        var result = exchanges
        if !search.isEmpty {
            let q = search.lowercased()
            result = result.filter {
                $0.request.url.lowercased().contains(q) ||
                $0.request.host.lowercased().contains(q) ||
                ($0.request.bodyString?.lowercased().contains(q) ?? false)
            }
        }
        if !methods.isEmpty {
            result = result.filter { methods.contains($0.request.method) }
        }
        return result
    }

    // MARK: - Export

    static func generateCurl(_ exchange: CapturedExchange) -> String {
        var curl = "curl -X \(exchange.request.method)"
        for (key, value) in exchange.request.headers {
            if key.lowercased() == "host" { continue }
            curl += " \\\n  -H '\(key): \(value)'"
        }
        if let body = exchange.request.bodyString, !body.isEmpty {
            curl += " \\\n  -d '\(body)'"
        }
        curl += " '\(exchange.request.url)'"
        return curl
    }

    static func statusColor(_ code: Int) -> String {
        switch code {
        case 200..<300: return "green"
        case 300..<400: return "blue"
        case 400..<500: return "orange"
        case 500..<600: return "red"
        default: return "gray"
        }
    }

    static func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes)B" }
        if bytes < 1048576 { return String(format: "%.1fKB", Double(bytes) / 1024.0) }
        return String(format: "%.1fMB", Double(bytes) / 1048576.0)
    }
}

import Foundation
import Network

struct WebhookService {
    struct WebhookRequest: Identifiable {
        var id: UUID = UUID()
        var timestamp: Date = Date()
        var method: String
        var path: String
        var headers: [(key: String, value: String)]
        var body: String
        var queryParams: [(key: String, value: String)]
        var contentType: String
        var sourceIP: String
        var bodySize: Int
    }

    struct ServerConfig {
        var port: Int = 9999
        var responseStatusCode: Int = 200
        var responseBody: String = ""
        var responseHeaders: [(key: String, value: String)] = []
    }

    // MARK: - HTTP Parsing

    static func parseHTTPRequest(_ data: Data, sourceIP: String = "127.0.0.1") -> WebhookRequest {
        let raw = String(data: data, encoding: .utf8) ?? ""
        let parts = raw.components(separatedBy: "\r\n\r\n")
        let headerSection = parts.first ?? ""
        let body = parts.count > 1 ? parts.dropFirst().joined(separator: "\r\n\r\n") : ""

        let headerLines = headerSection.components(separatedBy: "\r\n")
        let requestLine = headerLines.first ?? ""
        let requestParts = requestLine.components(separatedBy: " ")
        let method = requestParts.first ?? "GET"
        let fullPath = requestParts.count > 1 ? requestParts[1] : "/"

        // Parse path and query
        let pathComponents = fullPath.components(separatedBy: "?")
        let path = pathComponents.first ?? "/"
        var queryParams: [(key: String, value: String)] = []
        if pathComponents.count > 1 {
            let queryString = pathComponents[1]
            for param in queryString.components(separatedBy: "&") {
                let kv = param.components(separatedBy: "=")
                let key = kv.first ?? ""
                let value = kv.count > 1 ? kv[1] : ""
                queryParams.append((key: key, value: value))
            }
        }

        // Parse headers
        var headers: [(key: String, value: String)] = []
        var contentType = ""
        for line in headerLines.dropFirst() {
            guard let colonIndex = line.firstIndex(of: ":") else { continue }
            let key = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            headers.append((key: key, value: value))
            if key.lowercased() == "content-type" { contentType = value }
        }

        return WebhookRequest(
            method: method, path: path, headers: headers, body: body,
            queryParams: queryParams, contentType: contentType,
            sourceIP: sourceIP, bodySize: body.utf8.count
        )
    }

    static func buildHTTPResponse(statusCode: Int, body: String, headers: [(key: String, value: String)] = []) -> Data {
        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 201: statusText = "Created"
        case 204: statusText = "No Content"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        case 500: statusText = "Internal Server Error"
        default: statusText = "OK"
        }
        var response = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        response += "Content-Type: text/plain\r\n"
        response += "Content-Length: \(body.utf8.count)\r\n"
        for (key, value) in headers {
            response += "\(key): \(value)\r\n"
        }
        response += "Connection: close\r\n"
        response += "\r\n"
        response += body
        return Data(response.utf8)
    }

    static func generateCurl(_ request: WebhookRequest) -> String {
        var curl = "curl -X \(request.method)"
        for (key, value) in request.headers {
            curl += " -H '\(key): \(value)'"
        }
        if !request.body.isEmpty {
            curl += " -d '\(request.body)'"
        }
        let fullPath = request.path + (request.queryParams.isEmpty ? "" :
            "?" + request.queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&"))
        curl += " 'http://localhost:9999\(fullPath)'"
        return curl
    }
}

// MARK: - Server

class WebhookServer {
    private var listener: NWListener?
    private(set) var isRunning: Bool = false
    var onRequest: ((WebhookService.WebhookRequest) -> Void)?
    var config: WebhookService.ServerConfig

    init(config: WebhookService.ServerConfig = .init()) {
        self.config = config
    }

    func start() throws {
        let params = NWParameters.tcp
        listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: UInt16(config.port)))
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.isRunning = true
            case .failed, .cancelled:
                self?.isRunning = false
            default:
                break
            }
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
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data = data, let self = self else { return }
            let endpoint = connection.endpoint
            let sourceIP: String
            if case .hostPort(let host, _) = endpoint {
                sourceIP = "\(host)"
            } else {
                sourceIP = "unknown"
            }
            let request = WebhookService.parseHTTPRequest(data, sourceIP: sourceIP)
            DispatchQueue.main.async {
                self.onRequest?(request)
            }
            let response = WebhookService.buildHTTPResponse(
                statusCode: self.config.responseStatusCode,
                body: self.config.responseBody,
                headers: self.config.responseHeaders
            )
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }
}

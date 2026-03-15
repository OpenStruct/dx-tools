import Foundation

struct APIRequestService {

    struct Request {
        var method: String = "GET"
        var url: String = ""
        var headers: [(key: String, value: String, enabled: Bool)] = [
            ("Content-Type", "application/json", true)
        ]
        var body: String = ""
        var queryParams: [(key: String, value: String, enabled: Bool)] = []
    }

    struct Response {
        let statusCode: Int
        let statusText: String
        let headers: [(key: String, value: String)]
        let body: String
        let size: Int
        let duration: TimeInterval
        let isJSON: Bool

        var isSuccess: Bool { (200...299).contains(statusCode) }

        var prettyBody: String {
            guard isJSON, let data = body.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data),
                  let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
                  let str = String(data: pretty, encoding: .utf8) else { return body }
            return str
        }
    }

    static func send(_ request: Request) async throws -> Response {
        guard let baseURL = URL(string: request.url) else {
            throw RequestError.invalidURL
        }

        // Add query params
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) ?? URLComponents()
        let enabledParams = request.queryParams.filter(\.enabled)
        if !enabledParams.isEmpty {
            components.queryItems = enabledParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let finalURL = components.url else {
            throw RequestError.invalidURL
        }

        var urlRequest = URLRequest(url: finalURL)
        urlRequest.httpMethod = request.method
        urlRequest.timeoutInterval = 30

        for header in request.headers where header.enabled {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        if !request.body.isEmpty && ["POST", "PUT", "PATCH"].contains(request.method) {
            urlRequest.httpBody = request.body.data(using: .utf8)
        }

        let start = CFAbsoluteTimeGetCurrent()
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        let duration = CFAbsoluteTimeGetCurrent() - start

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RequestError.invalidResponse
        }

        let responseBody = String(data: data, encoding: .utf8) ?? ""
        let isJSON = httpResponse.value(forHTTPHeaderField: "Content-Type")?.contains("json") ?? false
            || responseBody.trimmingCharacters(in: .whitespacesAndNewlines).first == "{"
            || responseBody.trimmingCharacters(in: .whitespacesAndNewlines).first == "["

        let responseHeaders = httpResponse.allHeaderFields.compactMap { key, value -> (String, String)? in
            guard let k = key as? String, let v = value as? String else { return nil }
            return (k, v)
        }.sorted { $0.0 < $1.0 }

        return Response(
            statusCode: httpResponse.statusCode,
            statusText: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
            headers: responseHeaders,
            body: responseBody,
            size: data.count,
            duration: duration,
            isJSON: isJSON
        )
    }

    enum RequestError: LocalizedError {
        case invalidURL
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response"
            }
        }
    }

    static let methods = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
}

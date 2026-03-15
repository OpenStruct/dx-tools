import Foundation

struct HTTPStatusService {
    struct StatusCode: Identifiable {
        let code: Int
        let title: String
        let description: String
        let category: Category
        var id: Int { code }

        enum Category: String, CaseIterable {
            case info = "1xx Informational"
            case success = "2xx Success"
            case redirect = "3xx Redirection"
            case clientError = "4xx Client Error"
            case serverError = "5xx Server Error"
        }
    }

    static let allCodes: [StatusCode] = [
        // 1xx
        StatusCode(code: 100, title: "Continue", description: "Server received request headers, client should proceed to send body.", category: .info),
        StatusCode(code: 101, title: "Switching Protocols", description: "Server is switching protocols as requested (e.g., WebSocket upgrade).", category: .info),
        StatusCode(code: 102, title: "Processing", description: "Server has received and is processing the request (WebDAV).", category: .info),
        StatusCode(code: 103, title: "Early Hints", description: "Allows preloading resources while the server prepares a response.", category: .info),
        // 2xx
        StatusCode(code: 200, title: "OK", description: "Standard success response. The request has succeeded.", category: .success),
        StatusCode(code: 201, title: "Created", description: "Request fulfilled and new resource created. Common for POST requests.", category: .success),
        StatusCode(code: 202, title: "Accepted", description: "Request accepted for processing but not yet completed. Used for async operations.", category: .success),
        StatusCode(code: 203, title: "Non-Authoritative Info", description: "Request successful but returned metadata may be from another source.", category: .success),
        StatusCode(code: 204, title: "No Content", description: "Request successful but no content to return. Common for DELETE requests.", category: .success),
        StatusCode(code: 206, title: "Partial Content", description: "Server delivering part of the resource due to a Range header.", category: .success),
        StatusCode(code: 207, title: "Multi-Status", description: "Multiple status codes for multiple sub-requests (WebDAV).", category: .success),
        // 3xx
        StatusCode(code: 301, title: "Moved Permanently", description: "Resource permanently moved. Future requests should use new URL. Search engines update.", category: .redirect),
        StatusCode(code: 302, title: "Found", description: "Resource temporarily moved. Client should continue using original URL.", category: .redirect),
        StatusCode(code: 303, title: "See Other", description: "Response to request can be found at another URL using GET.", category: .redirect),
        StatusCode(code: 304, title: "Not Modified", description: "Resource not modified since last request. Used for caching.", category: .redirect),
        StatusCode(code: 307, title: "Temporary Redirect", description: "Like 302 but guarantees method and body won't change.", category: .redirect),
        StatusCode(code: 308, title: "Permanent Redirect", description: "Like 301 but guarantees method and body won't change.", category: .redirect),
        // 4xx
        StatusCode(code: 400, title: "Bad Request", description: "Server cannot process request due to client error (malformed syntax, invalid params).", category: .clientError),
        StatusCode(code: 401, title: "Unauthorized", description: "Authentication required. Client must provide valid credentials.", category: .clientError),
        StatusCode(code: 403, title: "Forbidden", description: "Server understood request but refuses to authorize it. Unlike 401, re-authenticating won't help.", category: .clientError),
        StatusCode(code: 404, title: "Not Found", description: "Requested resource could not be found. Most common error on the web.", category: .clientError),
        StatusCode(code: 405, title: "Method Not Allowed", description: "HTTP method not supported for this resource (e.g., POST on read-only endpoint).", category: .clientError),
        StatusCode(code: 406, title: "Not Acceptable", description: "Resource not available in format requested by Accept headers.", category: .clientError),
        StatusCode(code: 408, title: "Request Timeout", description: "Server timed out waiting for the request.", category: .clientError),
        StatusCode(code: 409, title: "Conflict", description: "Request conflicts with current state (e.g., duplicate resource, edit conflict).", category: .clientError),
        StatusCode(code: 410, title: "Gone", description: "Resource permanently deleted. Unlike 404, this is intentional and permanent.", category: .clientError),
        StatusCode(code: 413, title: "Payload Too Large", description: "Request entity exceeds server limits (e.g., file upload too large).", category: .clientError),
        StatusCode(code: 415, title: "Unsupported Media Type", description: "Server doesn't support the request's media type (check Content-Type).", category: .clientError),
        StatusCode(code: 418, title: "I'm a Teapot", description: "Server refuses to brew coffee because it is, permanently, a teapot (RFC 2324).", category: .clientError),
        StatusCode(code: 422, title: "Unprocessable Entity", description: "Request well-formed but semantically invalid (e.g., validation errors).", category: .clientError),
        StatusCode(code: 429, title: "Too Many Requests", description: "Rate limit exceeded. Check Retry-After header.", category: .clientError),
        // 5xx
        StatusCode(code: 500, title: "Internal Server Error", description: "Generic server error. Something went wrong on the server side.", category: .serverError),
        StatusCode(code: 501, title: "Not Implemented", description: "Server doesn't support the functionality required to fulfill the request.", category: .serverError),
        StatusCode(code: 502, title: "Bad Gateway", description: "Server received invalid response from upstream server.", category: .serverError),
        StatusCode(code: 503, title: "Service Unavailable", description: "Server temporarily unable to handle request (overloaded or maintenance).", category: .serverError),
        StatusCode(code: 504, title: "Gateway Timeout", description: "Upstream server didn't respond in time.", category: .serverError),
    ]

    static func search(_ query: String) -> [StatusCode] {
        if query.isEmpty { return allCodes }
        let q = query.lowercased()
        if let code = Int(q) {
            return allCodes.filter { $0.code == code || String($0.code).contains(q) }
        }
        return allCodes.filter {
            $0.title.lowercased().contains(q) ||
            $0.description.lowercased().contains(q) ||
            String($0.code).contains(q)
        }
    }
}

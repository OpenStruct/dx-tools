import Foundation

struct APIClientService {
    struct APICollection: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        var requests: [APIClientRequest] = []
    }

    struct APIClientRequest: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String = "New Request"
        var method: HTTPMethod = .get
        var url: String = ""
        var headers: [KeyValueItem] = []
        var queryParams: [KeyValueItem] = []
        var bodyContent: String = ""
        var bodyType: BodyType = .none
        var authType: AuthType = .none
        var authToken: String = ""
        var authUsername: String = ""
        var authPassword: String = ""
    }

    struct KeyValueItem: Identifiable, Codable {
        var id: UUID = UUID()
        var key: String = ""
        var value: String = ""
        var enabled: Bool = true
    }

    enum HTTPMethod: String, CaseIterable, Codable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
        case head = "HEAD"
        case options = "OPTIONS"
    }

    enum BodyType: String, CaseIterable, Codable {
        case none = "None"
        case json = "JSON"
        case formData = "Form"
        case raw = "Raw"
    }

    enum AuthType: String, CaseIterable, Codable {
        case none = "None"
        case bearer = "Bearer"
        case basic = "Basic"
    }

    struct APIResponse {
        var statusCode: Int
        var statusText: String
        var headers: [(key: String, value: String)]
        var bodyString: String
        var contentType: String
        var size: Int
        var time: TimeInterval
        var error: String?
    }

    struct APIEnvironment: Identifiable, Codable {
        var id: UUID = UUID()
        var name: String
        var variables: [KeyValueItem] = []
    }

    // MARK: - Request Execution

    static func send(_ request: APIClientRequest, environment: APIEnvironment? = nil) async -> APIResponse {
        let urlStr = interpolateVariables(request.url, environment: environment)
        var components = URLComponents(string: urlStr)

        // Query params
        let activeParams = request.queryParams.filter { $0.enabled && !$0.key.isEmpty }
        if !activeParams.isEmpty {
            var existingItems = components?.queryItems ?? []
            existingItems += activeParams.map {
                URLQueryItem(name: interpolateVariables($0.key, environment: environment),
                           value: interpolateVariables($0.value, environment: environment))
            }
            components?.queryItems = existingItems
        }

        guard let url = components?.url else {
            return APIResponse(statusCode: 0, statusText: "", headers: [], bodyString: "", contentType: "", size: 0, time: 0, error: "Invalid URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // Headers
        for header in request.headers where header.enabled && !header.key.isEmpty {
            urlRequest.setValue(interpolateVariables(header.value, environment: environment),
                             forHTTPHeaderField: interpolateVariables(header.key, environment: environment))
        }

        // Auth
        switch request.authType {
        case .bearer:
            let token = interpolateVariables(request.authToken, environment: environment)
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        case .basic:
            let user = interpolateVariables(request.authUsername, environment: environment)
            let pass = interpolateVariables(request.authPassword, environment: environment)
            let cred = Data("\(user):\(pass)".utf8).base64EncodedString()
            urlRequest.setValue("Basic \(cred)", forHTTPHeaderField: "Authorization")
        case .none:
            break
        }

        // Body
        switch request.bodyType {
        case .json:
            let body = interpolateVariables(request.bodyContent, environment: environment)
            urlRequest.httpBody = body.data(using: .utf8)
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        case .raw:
            urlRequest.httpBody = interpolateVariables(request.bodyContent, environment: environment).data(using: .utf8)
        case .formData, .none:
            break
        }

        let start = Date()
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            let elapsed = Date().timeIntervalSince(start)
            guard let httpResponse = response as? HTTPURLResponse else {
                return APIResponse(statusCode: 0, statusText: "", headers: [], bodyString: "", contentType: "", size: 0, time: elapsed, error: "Not an HTTP response")
            }
            let headers = httpResponse.allHeaderFields.compactMap { key, value -> (key: String, value: String)? in
                guard let k = key as? String, let v = value as? String else { return nil }
                return (key: k, value: v)
            }
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? ""
            return APIResponse(statusCode: httpResponse.statusCode, statusText: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode),
                             headers: headers, bodyString: bodyStr, contentType: contentType, size: data.count, time: elapsed)
        } catch {
            return APIResponse(statusCode: 0, statusText: "", headers: [], bodyString: "", contentType: "", size: 0,
                             time: Date().timeIntervalSince(start), error: error.localizedDescription)
        }
    }

    // MARK: - Variable Interpolation

    static func interpolateVariables(_ text: String, environment: APIEnvironment?) -> String {
        guard let env = environment else { return text }
        var result = text
        for v in env.variables where v.enabled && !v.key.isEmpty {
            result = result.replacingOccurrences(of: "{{\(v.key)}}", with: v.value)
        }
        return result
    }

    // MARK: - Code Generation

    static func generateCurl(_ request: APIClientRequest) -> String {
        var curl = "curl -X \(request.method.rawValue)"
        for h in request.headers where h.enabled && !h.key.isEmpty {
            curl += " \\\n  -H '\(h.key): \(h.value)'"
        }
        switch request.authType {
        case .bearer:
            curl += " \\\n  -H 'Authorization: Bearer \(request.authToken)'"
        case .basic:
            curl += " \\\n  -u '\(request.authUsername):\(request.authPassword)'"
        case .none: break
        }
        if request.bodyType == .json && !request.bodyContent.isEmpty {
            curl += " \\\n  -d '\(request.bodyContent)'"
        }
        var urlStr = request.url
        let params = request.queryParams.filter { $0.enabled && !$0.key.isEmpty }
        if !params.isEmpty {
            urlStr += "?" + params.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        }
        curl += " \\\n  '\(urlStr)'"
        return curl
    }

    static func generateSwift(_ request: APIClientRequest) -> String {
        var code = "import Foundation\n\n"
        code += "let url = URL(string: \"\(request.url)\")!\n"
        code += "var request = URLRequest(url: url)\n"
        code += "request.httpMethod = \"\(request.method.rawValue)\"\n"
        for h in request.headers where h.enabled && !h.key.isEmpty {
            code += "request.setValue(\"\(h.value)\", forHTTPHeaderField: \"\(h.key)\")\n"
        }
        if request.bodyType == .json && !request.bodyContent.isEmpty {
            code += "request.httpBody = \"\"\"\n\(request.bodyContent)\n\"\"\".data(using: .utf8)\n"
        }
        code += "\nlet (data, response) = try await URLSession.shared.data(for: request)\n"
        code += "let body = String(data: data, encoding: .utf8)!\n"
        code += "print(body)\n"
        return code
    }

    static func generatePython(_ request: APIClientRequest) -> String {
        var code = "import requests\n\n"
        let headers = request.headers.filter { $0.enabled && !$0.key.isEmpty }
        if !headers.isEmpty {
            code += "headers = {\n"
            for h in headers { code += "    '\(h.key)': '\(h.value)',\n" }
            code += "}\n\n"
        }
        code += "response = requests.\(request.method.rawValue.lowercased())(\n"
        code += "    '\(request.url)',\n"
        if !headers.isEmpty { code += "    headers=headers,\n" }
        if request.bodyType == .json && !request.bodyContent.isEmpty {
            code += "    json=\(request.bodyContent),\n"
        }
        code += ")\n\nprint(response.status_code)\nprint(response.text)\n"
        return code
    }

    static func generateJavaScript(_ request: APIClientRequest) -> String {
        var code = "const response = await fetch('\(request.url)', {\n"
        code += "  method: '\(request.method.rawValue)',\n"
        let headers = request.headers.filter { $0.enabled && !$0.key.isEmpty }
        if !headers.isEmpty {
            code += "  headers: {\n"
            for h in headers { code += "    '\(h.key)': '\(h.value)',\n" }
            code += "  },\n"
        }
        if request.bodyType == .json && !request.bodyContent.isEmpty {
            code += "  body: JSON.stringify(\(request.bodyContent)),\n"
        }
        code += "});\n\nconst data = await response.json();\nconsole.log(data);\n"
        return code
    }

    // MARK: - Import

    static func importCurl(_ curl: String) -> APIClientRequest? {
        var req = APIClientRequest()
        let parts = curl.replacingOccurrences(of: "\\\n", with: " ").components(separatedBy: " ").filter { !$0.isEmpty }
        guard parts.first == "curl" else { return nil }

        var i = 1
        while i < parts.count {
            let part = parts[i]
            switch part {
            case "-X":
                if i + 1 < parts.count {
                    req.method = HTTPMethod(rawValue: parts[i+1]) ?? .get
                    i += 1
                }
            case "-H":
                if i + 1 < parts.count {
                    let header = parts[i+1].trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                    if let colon = header.firstIndex(of: ":") {
                        let key = String(header[..<colon]).trimmingCharacters(in: .whitespaces)
                        let value = String(header[header.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                        req.headers.append(KeyValueItem(key: key, value: value))
                    }
                    i += 1
                }
            case "-d", "--data":
                if i + 1 < parts.count {
                    req.bodyContent = parts[i+1].trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                    req.bodyType = .json
                    i += 1
                }
            default:
                if part.hasPrefix("http") || part.hasPrefix("'http") || part.hasPrefix("\"http") {
                    req.url = part.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                }
            }
            i += 1
        }
        req.name = URL(string: req.url)?.lastPathComponent ?? "Imported"
        return req
    }

    // MARK: - Storage

    private static var storageDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DX Tools")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func saveCollections(_ collections: [APICollection]) {
        guard let data = try? JSONEncoder().encode(collections) else { return }
        try? data.write(to: storageDir.appendingPathComponent("api-collections.json"))
    }

    static func loadCollections() -> [APICollection] {
        let url = storageDir.appendingPathComponent("api-collections.json")
        guard let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([APICollection].self, from: data) else { return [] }
        return result
    }

    static func saveEnvironments(_ envs: [APIEnvironment]) {
        guard let data = try? JSONEncoder().encode(envs) else { return }
        try? data.write(to: storageDir.appendingPathComponent("api-environments.json"))
    }

    static func loadEnvironments() -> [APIEnvironment] {
        let url = storageDir.appendingPathComponent("api-environments.json")
        guard let data = try? Data(contentsOf: url),
              let result = try? JSONDecoder().decode([APIEnvironment].self, from: data) else { return [] }
        return result
    }
}

import Foundation

struct URLCoderService {

    static func encode(_ input: String, component: Bool = false) -> String {
        if component {
            return input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? input
        }
        // Full encode — even encode normally-allowed chars
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        return input.addingPercentEncoding(withAllowedCharacters: allowed) ?? input
    }

    static func decode(_ input: String) -> String {
        input.removingPercentEncoding ?? input
    }

    static func parseURL(_ input: String) -> URLComponents? {
        var raw = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !raw.contains("://") && !raw.hasPrefix("/") {
            raw = "https://" + raw
        }
        return URLComponents(string: raw)
    }

    struct URLParts {
        let scheme: String
        let host: String
        let port: String
        let path: String
        let query: [(name: String, value: String)]
        let fragment: String
    }

    static func decompose(_ input: String) -> URLParts? {
        guard let components = parseURL(input) else { return nil }
        return URLParts(
            scheme: components.scheme ?? "",
            host: components.host ?? "",
            port: components.port.map(String.init) ?? "",
            path: components.path,
            query: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") },
            fragment: components.fragment ?? ""
        )
    }
}

import Foundation

struct CurlToCodeService {

    struct ParsedCurl {
        var url: String = ""
        var method: String = "GET"
        var headers: [(key: String, value: String)] = []
        var body: String?
        var contentType: String?
    }

    static func parse(_ curl: String) -> ParsedCurl {
        var result = ParsedCurl()
        let input = curl.replacingOccurrences(of: "\\\n", with: " ")
            .replacingOccurrences(of: "\\\r\n", with: " ")

        // URL
        if let urlMatch = input.range(of: "(?:curl\\s+)?['\"]?(https?://[^'\"\\s]+)['\"]?", options: .regularExpression) {
            var url = String(input[urlMatch])
            url = url.replacingOccurrences(of: "curl ", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "'\" "))
            result.url = url
        }

        // Method
        if let methodMatch = input.range(of: "-X\\s+(\\w+)", options: .regularExpression) {
            let full = String(input[methodMatch])
            result.method = full.replacingOccurrences(of: "-X ", with: "").trimmingCharacters(in: .whitespaces)
        }

        // Headers
        let headerPattern = "-H\\s+['\"]([^'\"]+)['\"]"
        if let regex = try? NSRegularExpression(pattern: headerPattern) {
            let nsInput = input as NSString
            let matches = regex.matches(in: input, range: NSRange(location: 0, length: nsInput.length))
            for match in matches {
                let headerStr = nsInput.substring(with: match.range(at: 1))
                if let colonIdx = headerStr.firstIndex(of: ":") {
                    let key = String(headerStr[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                    let value = String(headerStr[headerStr.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                    result.headers.append((key, value))
                    if key.lowercased() == "content-type" { result.contentType = value }
                }
            }
        }

        // Body — handle -d, --data, --data-raw with single or double quotes
        // Must handle nested quotes in JSON like -d '{"name":"John"}'
        let bodyFlags = ["-d", "--data", "--data-raw"]
        for flag in bodyFlags {
            // Find the flag
            guard let flagRange = input.range(of: flag + " ", options: .literal) else { continue }
            let afterFlag = String(input[flagRange.upperBound...]).trimmingCharacters(in: .whitespaces)

            if afterFlag.hasPrefix("'") {
                // Single-quoted: find matching closing single quote
                if let endQuote = afterFlag.dropFirst().range(of: "'") {
                    result.body = String(afterFlag[afterFlag.index(after: afterFlag.startIndex)..<endQuote.lowerBound])
                }
            } else if afterFlag.hasPrefix("\"") {
                // Double-quoted: find matching closing double quote (handle escaped quotes)
                var i = afterFlag.index(after: afterFlag.startIndex)
                var body = ""
                while i < afterFlag.endIndex {
                    let c = afterFlag[i]
                    if c == "\\" && afterFlag.index(after: i) < afterFlag.endIndex {
                        body.append(c)
                        i = afterFlag.index(after: i)
                        body.append(afterFlag[i])
                    } else if c == "\"" {
                        break
                    } else {
                        body.append(c)
                    }
                    i = afterFlag.index(after: i)
                }
                result.body = body
            } else {
                // Unquoted: take until next space or flag
                let bodyStr = afterFlag.prefix(while: { !$0.isWhitespace })
                result.body = String(bodyStr)
            }

            if result.body != nil {
                if result.method == "GET" { result.method = "POST" }
                break
            }
        }

        return result
    }

    static func toSwift(_ curl: ParsedCurl) -> String {
        var lines: [String] = ["import Foundation", ""]
        lines.append("let url = URL(string: \"\(curl.url)\")!")
        lines.append("var request = URLRequest(url: url)")
        lines.append("request.httpMethod = \"\(curl.method)\"")
        for (key, value) in curl.headers {
            lines.append("request.setValue(\"\(value)\", forHTTPHeaderField: \"\(key)\")")
        }
        if let body = curl.body {
            lines.append("")
            lines.append("let body = \"\"\"\n\(body)\n\"\"\"")
            lines.append("request.httpBody = body.data(using: .utf8)")
        }
        lines.append("")
        lines.append("let (data, response) = try await URLSession.shared.data(for: request)")
        lines.append("let httpResponse = response as! HTTPURLResponse")
        lines.append("print(\"Status: \\(httpResponse.statusCode)\")")
        lines.append("print(String(data: data, encoding: .utf8) ?? \"\")")
        return lines.joined(separator: "\n")
    }

    static func toGo(_ curl: ParsedCurl) -> String {
        var lines: [String] = ["package main", "", "import (", "\t\"fmt\"", "\t\"io\"", "\t\"net/http\""]
        if curl.body != nil { lines.append("\t\"strings\"") }
        lines.append(")")
        lines.append("")
        lines.append("func main() {")
        if let body = curl.body {
            lines.append("\tbody := strings.NewReader(`\(body)`)")
            lines.append("\treq, err := http.NewRequest(\"\(curl.method)\", \"\(curl.url)\", body)")
        } else {
            lines.append("\treq, err := http.NewRequest(\"\(curl.method)\", \"\(curl.url)\", nil)")
        }
        lines.append("\tif err != nil { panic(err) }")
        for (key, value) in curl.headers {
            lines.append("\treq.Header.Set(\"\(key)\", \"\(value)\")")
        }
        lines.append("")
        lines.append("\tresp, err := http.DefaultClient.Do(req)")
        lines.append("\tif err != nil { panic(err) }")
        lines.append("\tdefer resp.Body.Close()")
        lines.append("")
        lines.append("\tdata, _ := io.ReadAll(resp.Body)")
        lines.append("\tfmt.Printf(\"Status: %d\\n\", resp.StatusCode)")
        lines.append("\tfmt.Println(string(data))")
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    static func toPython(_ curl: ParsedCurl) -> String {
        var lines: [String] = ["import requests", ""]
        lines.append("url = \"\(curl.url)\"")
        if !curl.headers.isEmpty {
            lines.append("headers = {")
            for (key, value) in curl.headers {
                lines.append("    \"\(key)\": \"\(value)\",")
            }
            lines.append("}")
        }
        if let body = curl.body {
            lines.append("data = '''\(body)'''")
        }
        lines.append("")
        var args = ["url"]
        if !curl.headers.isEmpty { args.append("headers=headers") }
        if curl.body != nil { args.append("data=data") }
        lines.append("response = requests.\(curl.method.lowercased())(\(args.joined(separator: ", ")))")
        lines.append("print(f\"Status: {response.status_code}\")")
        lines.append("print(response.text)")
        return lines.joined(separator: "\n")
    }

    static func toJavaScript(_ curl: ParsedCurl) -> String {
        var lines: [String] = []
        var optionsParts: [String] = []
        optionsParts.append("  method: \"\(curl.method)\"")
        if !curl.headers.isEmpty {
            var headerLines: [String] = ["  headers: {"]
            for (key, value) in curl.headers {
                headerLines.append("    \"\(key)\": \"\(value)\",")
            }
            headerLines.append("  }")
            optionsParts.append(headerLines.joined(separator: "\n"))
        }
        if let body = curl.body {
            optionsParts.append("  body: JSON.stringify(\(body))")
        }

        lines.append("const response = await fetch(\"\(curl.url)\", {")
        lines.append(optionsParts.joined(separator: ",\n"))
        lines.append("});")
        lines.append("")
        lines.append("const data = await response.json();")
        lines.append("console.log(`Status: ${response.status}`);")
        lines.append("console.log(data);")
        return lines.joined(separator: "\n")
    }

    static func toRuby(_ curl: ParsedCurl) -> String {
        var lines: [String] = ["require 'net/http'", "require 'uri'", "require 'json'", ""]
        lines.append("uri = URI.parse(\"\(curl.url)\")")
        lines.append("http = Net::HTTP.new(uri.host, uri.port)")
        lines.append("http.use_ssl = uri.scheme == 'https'")
        lines.append("")

        let className: String
        switch curl.method.uppercased() {
        case "POST": className = "Post"
        case "PUT": className = "Put"
        case "DELETE": className = "Delete"
        case "PATCH": className = "Patch"
        default: className = "Get"
        }
        lines.append("request = Net::HTTP::\(className).new(uri.request_uri)")
        for (key, value) in curl.headers {
            lines.append("request[\"\(key)\"] = \"\(value)\"")
        }
        if let body = curl.body {
            lines.append("request.body = '\(body)'")
        }
        lines.append("")
        lines.append("response = http.request(request)")
        lines.append("puts \"Status: #{response.code}\"")
        lines.append("puts response.body")
        return lines.joined(separator: "\n")
    }
}

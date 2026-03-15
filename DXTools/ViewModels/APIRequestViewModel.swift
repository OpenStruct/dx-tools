import SwiftUI

@Observable
class APIRequestViewModel {
    var request = APIRequestService.Request()
    var response: APIRequestService.Response?
    var isLoading: Bool = false
    var errorMessage: String?
    var responseTab: ResponseTab = .body

    enum ResponseTab: String, CaseIterable {
        case body = "Body"
        case headers = "Headers"
        case raw = "Raw"
    }

    func send() {
        guard !request.url.isEmpty else {
            errorMessage = "Enter a URL"; return
        }

        // Auto-prepend https
        if !request.url.hasPrefix("http") {
            request.url = "https://" + request.url
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let resp = try await APIRequestService.send(request)
                await MainActor.run {
                    response = resp
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    func addHeader() {
        request.headers.append(("", "", true))
    }

    func removeHeader(at index: Int) {
        request.headers.remove(at: index)
    }

    func addParam() {
        request.queryParams.append(("", "", true))
    }

    func removeParam(at index: Int) {
        request.queryParams.remove(at: index)
    }

    func copyResponse() {
        guard let body = response?.prettyBody else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(body, forType: .string)
    }

    func clear() {
        request = APIRequestService.Request()
        response = nil
        errorMessage = nil
    }

    func loadSample() {
        request.method = "GET"
        request.url = "https://jsonplaceholder.typicode.com/users/1"
        request.headers = [("Accept", "application/json", true)]
        send()
    }

    func generateCurl() -> String {
        var parts = ["curl"]
        if request.method != "GET" {
            parts.append("-X \(request.method)")
        }
        parts.append("'\(request.url)'")
        for h in request.headers where h.enabled {
            parts.append("-H '\(h.key): \(h.value)'")
        }
        if !request.body.isEmpty {
            parts.append("-d '\(request.body)'")
        }
        return parts.joined(separator: " \\\n  ")
    }
}

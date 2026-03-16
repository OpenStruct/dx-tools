import SwiftUI

@Observable
class APIClientViewModel {
    var collections: [APIClientService.APICollection] = []
    var environments: [APIClientService.APIEnvironment] = []
    var activeEnvIndex: Int?
    var selectedCollectionIndex: Int?
    var selectedRequestIndex: Int?
    var response: APIClientService.APIResponse?
    var isLoading: Bool = false
    var activeTab: RequestTab = .params
    var responseTab: ResponseTab = .body
    var codeGenLanguage: String = "cURL"
    var generatedCode: String = ""
    var showEnvEditor: Bool = false
    var showImportCurl: Bool = false
    var importCurlText: String = ""

    enum RequestTab: String, CaseIterable { case params = "Params", headers = "Headers", auth = "Auth", body = "Body" }
    enum ResponseTab: String, CaseIterable { case body = "Body", headers = "Headers" }

    var activeEnvironment: APIClientService.APIEnvironment? {
        guard let idx = activeEnvIndex, environments.indices.contains(idx) else { return nil }
        return environments[idx]
    }

    var currentRequest: APIClientService.APIClientRequest? {
        get {
            guard let ci = selectedCollectionIndex, collections.indices.contains(ci),
                  let ri = selectedRequestIndex, collections[ci].requests.indices.contains(ri) else { return nil }
            return collections[ci].requests[ri]
        }
        set {
            guard let ci = selectedCollectionIndex, collections.indices.contains(ci),
                  let ri = selectedRequestIndex, collections[ci].requests.indices.contains(ri),
                  let val = newValue else { return }
            collections[ci].requests[ri] = val
        }
    }

    func load() {
        collections = APIClientService.loadCollections()
        environments = APIClientService.loadEnvironments()
        if collections.isEmpty {
            collections.append(APIClientService.APICollection(name: "My Collection"))
        }
    }

    func save() {
        APIClientService.saveCollections(collections)
        APIClientService.saveEnvironments(environments)
    }

    func addCollection() {
        collections.append(APIClientService.APICollection(name: "New Collection"))
        save()
    }

    func addRequest() {
        guard let ci = selectedCollectionIndex, collections.indices.contains(ci) else {
            if collections.isEmpty { addCollection() }
            selectedCollectionIndex = 0
            return addRequest()
        }
        collections[ci].requests.append(APIClientService.APIClientRequest())
        selectedRequestIndex = collections[ci].requests.count - 1
        save()
    }

    func deleteRequest() {
        guard let ci = selectedCollectionIndex, let ri = selectedRequestIndex,
              collections[ci].requests.indices.contains(ri) else { return }
        collections[ci].requests.remove(at: ri)
        selectedRequestIndex = nil
        save()
    }

    func send() async {
        guard let request = currentRequest else { return }
        isLoading = true
        response = await APIClientService.send(request, environment: activeEnvironment)
        isLoading = false
    }

    func generateCode() {
        guard let request = currentRequest else { return }
        switch codeGenLanguage {
        case "cURL": generatedCode = APIClientService.generateCurl(request)
        case "Swift": generatedCode = APIClientService.generateSwift(request)
        case "Python": generatedCode = APIClientService.generatePython(request)
        case "JavaScript": generatedCode = APIClientService.generateJavaScript(request)
        default: generatedCode = APIClientService.generateCurl(request)
        }
    }

    func importFromCurl() {
        guard let req = APIClientService.importCurl(importCurlText) else { return }
        if selectedCollectionIndex == nil { selectedCollectionIndex = 0 }
        guard let ci = selectedCollectionIndex, collections.indices.contains(ci) else { return }
        collections[ci].requests.append(req)
        selectedRequestIndex = collections[ci].requests.count - 1
        importCurlText = ""
        showImportCurl = false
        save()
    }

    func addEnvironment() {
        environments.append(APIClientService.APIEnvironment(name: "New Environment"))
        save()
    }

    func addParamRow() {
        currentRequest?.queryParams.append(APIClientService.KeyValueItem())
    }

    func addHeaderRow() {
        currentRequest?.headers.append(APIClientService.KeyValueItem())
    }

    func copyResponse() {
        guard let body = response?.bodyString else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(body, forType: .string)
    }

    func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedCode, forType: .string)
    }
}

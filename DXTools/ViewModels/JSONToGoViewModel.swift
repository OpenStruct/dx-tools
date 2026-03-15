import SwiftUI

@Observable
class JSONToGoViewModel {
    var input: String = ""
    var output: String = ""
    var errorMessage: String?
    var rootName: String = "Root"
    var addOmitempty: Bool = false
    var usePointers: Bool = false

    func convert() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            output = ""
            errorMessage = nil
            return
        }

        let options = JSONToGoService.Options(
            rootName: rootName.isEmpty ? "Root" : rootName,
            addOmitempty: addOmitempty,
            usePointers: usePointers
        )

        switch JSONToGoService.convert(input, options: options) {
        case .success(let result):
            output = result
            errorMessage = nil
        case .failure(let error):
            output = ""
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        input = ""
        output = ""
        errorMessage = nil
    }

    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }

    func pasteAndConvert() {
        if let str = NSPasteboard.general.string(forType: .string) {
            input = str
            convert()
        }
    }

    func loadSample() {
        input = """
        {
          "id": 1,
          "username": "nam_dev",
          "email": "nam@example.com",
          "is_active": true,
          "profile": {
            "first_name": "Nam",
            "last_name": "Dev",
            "avatar_url": "https://example.com/avatar.jpg",
            "bio": null
          },
          "roles": ["admin", "developer"],
          "settings": {
            "theme": "dark",
            "notifications_enabled": true,
            "api_key": "sk-1234567890"
          },
          "created_at": "2024-01-15T10:30:00Z",
          "login_count": 42
        }
        """
        convert()
    }
}

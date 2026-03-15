import SwiftUI

enum ToolCategory: String, CaseIterable, Identifiable {
    case json = "JSON"
    case encoding = "Encoding"
    case generators = "Generators"
    case devops = "DevOps"
    case text = "Text"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .json: return "curlybraces"
        case .encoding: return "lock.shield"
        case .generators: return "wand.and.stars"
        case .devops: return "gearshape.2"
        case .text: return "doc.richtext"
        }
    }
}

enum Tool: String, CaseIterable, Identifiable {
    case jsonFormatter = "JSON Formatter"
    case jsonToGo = "JSON → Go"
    case jsonToSwift = "JSON → Swift"
    case jsonToTypeScript = "JSON → TypeScript"
    case jsonDiff = "JSON Diff"
    case jwtDecoder = "JWT Decoder"
    case base64 = "Base64"
    case hashGenerator = "Hash Generator"
    case uuidGenerator = "UUID Generator"
    case colorConverter = "Color Converter"
    case epochConverter = "Epoch Converter"
    case passwordGenerator = "Password Generator"
    case envManager = "Env Manager"
    case curlToCode = "cURL → Code"
    case apiRequest = "API Request"
    case regexTester = "Regex Tester"
    case markdownPreview = "Markdown Preview"
    case loremGenerator = "Lorem Generator"
    case portManager = "Port Manager"
    case networkInfo = "Network Info"
    case urlCoder = "URL Encoder"
    case unixPermissions = "Unix Permissions"
    case cronParser = "Cron Parser"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .jsonFormatter: return "text.alignleft"
        case .jsonToGo: return "arrow.right.circle"
        case .jsonToSwift: return "swift"
        case .jsonToTypeScript: return "chevron.left.forwardslash.chevron.right"
        case .jsonDiff: return "arrow.left.arrow.right"
        case .jwtDecoder: return "key.horizontal"
        case .base64: return "lock.doc"
        case .hashGenerator: return "number.circle"
        case .uuidGenerator: return "dice"
        case .colorConverter: return "paintpalette"
        case .epochConverter: return "clock"
        case .passwordGenerator: return "lock.shield"
        case .envManager: return "doc.text.magnifyingglass"
        case .curlToCode: return "terminal"
        case .apiRequest: return "paperplane"
        case .regexTester: return "textformat.abc"
        case .markdownPreview: return "text.document"
        case .loremGenerator: return "wand.and.stars"
        case .portManager: return "network"
        case .networkInfo: return "wifi"
        case .urlCoder: return "link"
        case .unixPermissions: return "lock.shield"
        case .cronParser: return "clock.badge.checkmark"
        }
    }

    var category: ToolCategory {
        switch self {
        case .jsonFormatter, .jsonToGo, .jsonToSwift, .jsonToTypeScript, .jsonDiff: return .json
        case .jwtDecoder, .base64, .hashGenerator: return .encoding
        case .uuidGenerator, .colorConverter, .epochConverter, .passwordGenerator: return .generators
        case .envManager, .curlToCode, .apiRequest, .portManager, .networkInfo: return .devops
        case .urlCoder: return .encoding
        case .unixPermissions, .cronParser: return .generators
        case .regexTester, .markdownPreview, .loremGenerator: return .text
        }
    }

    var shortcutLabel: String {
        switch self {
        case .jsonFormatter: return "⌘1"
        case .jsonToGo: return "⌘2"
        case .jsonToSwift: return "⌘3"
        case .jsonToTypeScript: return "⌘4"
        case .jsonDiff: return "⌘5"
        case .jwtDecoder: return "⌘6"
        case .base64: return "⌘7"
        case .hashGenerator: return "⌘8"
        case .uuidGenerator: return "⌘9"
        case .colorConverter: return "⌘0"
        default: return ""
        }
    }

    var searchTerms: String {
        switch self {
        case .jsonFormatter: return "json format pretty print beautify minify validate"
        case .jsonToGo: return "json go golang struct convert generate"
        case .jsonToSwift: return "json swift codable struct model"
        case .jsonToTypeScript: return "json typescript ts interface type"
        case .jsonDiff: return "json diff compare difference"
        case .jwtDecoder: return "jwt token decode json web token auth"
        case .base64: return "base64 encode decode binary"
        case .hashGenerator: return "hash md5 sha sha256 sha512 checksum"
        case .uuidGenerator: return "uuid guid generate random identifier"
        case .colorConverter: return "color hex rgb hsl convert picker"
        case .epochConverter: return "epoch timestamp unix time date convert"
        case .passwordGenerator: return "password passphrase generate secure random"
        case .envManager: return "env environment variables dotenv config"
        case .curlToCode: return "curl http request code convert api"
        case .apiRequest: return "api http request post get rest endpoint postman"
        case .regexTester: return "regex regular expression pattern match test"
        case .markdownPreview: return "markdown preview html render"
        case .loremGenerator: return "lorem ipsum fake data placeholder text generate"
        case .portManager: return "port kill process pid lsof network listen tcp terminate"
        case .networkInfo: return "network ip dns hostname interface wifi local public"
        case .urlCoder: return "url encode decode percent query parameter uri"
        case .unixPermissions: return "unix permission chmod rwx octal file directory"
        case .cronParser: return "cron schedule timer job interval expression"
        }
    }
}

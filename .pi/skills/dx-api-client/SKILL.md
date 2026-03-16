---
name: dx-api-client
description: Build the API Client tool for DX Tools — a local-first Postman alternative. Collections, environments, request history, response viewer, code generation. Enhances the existing API Request Builder into a full API testing workspace. Follow dx-tools-feature skill for architecture.
---

# API Client — Local-first Postman Alternative

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

This enhances the existing `APIRequestView` into a full-featured API client. It can either replace the existing tool or be a separate, more powerful tool.

## Tool Definition

- **Enum case**: `apiClient`
- **Category**: `.devops`
- **Display name**: "API Client"
- **Icon**: `"paperplane.fill"`
- **Description**: "Full API testing workspace — collections, environments, history, code gen. No account required."

## Service: `APIClientService.swift`

### Models

```swift
struct APICollection: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var requests: [APIRequest]
    var folders: [APIFolder]
    var createdAt: Date
}

struct APIFolder: Identifiable, Codable {
    var id: UUID
    var name: String
    var requests: [APIRequest]
}

struct APIRequest: Identifiable, Codable {
    var id: UUID
    var name: String
    var method: HTTPMethod
    var url: String
    var headers: [KeyValueItem]
    var queryParams: [KeyValueItem]
    var body: RequestBody
    var auth: AuthConfig
    var preRequestScript: String?   // Future: JS scripts
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

enum RequestBody: Codable {
    case none
    case json(String)
    case formData([KeyValueItem])
    case raw(String, contentType: String)
    case binary(Data)
}

enum AuthConfig: Codable {
    case none
    case bearer(String)
    case basic(username: String, password: String)
    case apiKey(key: String, value: String, location: AuthLocation)

    enum AuthLocation: String, Codable {
        case header, queryParam
    }
}

struct APIResponse {
    var statusCode: Int
    var statusText: String
    var headers: [(key: String, value: String)]
    var body: Data
    var bodyString: String
    var contentType: String
    var size: Int
    var time: TimeInterval
    var error: String?
}

struct APIEnvironment: Identifiable, Codable {
    var id: UUID
    var name: String
    var variables: [KeyValueItem]
    var isActive: Bool
}

struct RequestHistoryItem: Identifiable, Codable {
    var id: UUID
    var request: APIRequest
    var response: APIResponse?
    var timestamp: Date
}
```

### Core Methods

```swift
// Request execution
static func send(_ request: APIRequest, environment: APIEnvironment?) async -> APIResponse
static func interpolateVariables(_ text: String, environment: APIEnvironment?) -> String  // Replace {{var}} with values

// Code generation (from request)
static func generateCurl(_ request: APIRequest) -> String
static func generateSwift(_ request: APIRequest) -> String
static func generatePython(_ request: APIRequest) -> String
static func generateJavaScript(_ request: APIRequest) -> String
static func generateGo(_ request: APIRequest) -> String

// Import/Export
static func importPostmanCollection(_ json: String) -> APICollection?
static func importCurl(_ curl: String) -> APIRequest?
static func exportCollection(_ collection: APICollection) -> String  // JSON

// Storage
static func saveCollections(_ collections: [APICollection])
static func loadCollections() -> [APICollection]
static func saveEnvironments(_ envs: [APIEnvironment])
static func loadEnvironments() -> [APIEnvironment]
static func saveHistory(_ items: [RequestHistoryItem])
static func loadHistory() -> [RequestHistoryItem]
```

### Variable Interpolation

```swift
// Replace {{variable}} with environment values
static func interpolateVariables(_ text: String, environment: APIEnvironment?) -> String {
    guard let env = environment else { return text }
    var result = text
    for v in env.variables where v.enabled && !v.key.isEmpty {
        result = result.replacingOccurrences(of: "{{\(v.key)}}", with: v.value)
    }
    return result
}
```

## View: `APIClientView.swift`

### Layout: Three-panel workspace

```
┌────────────────────────────────────────────────────────────────────┐
│ ToolHeader: "API Client"   Env: [Development ▼]   [Import] [New] │
├──────────┬─────────────────────────────────────────────────────────┤
│COLLECTIONS│  [GET ▼] [https://api.example.com/users  ] [Send ▶]   │
│          │                                                         │
│▼ My API  │  Params │ Headers │ Auth │ Body │                       │
│  GET /users│  key       value                                      │
│  POST /user│  page      1                                          │
│  GET /user/│  limit     10                                         │
│▼ Testing  │                                                        │
│  POST /auth│─────────────────────────────────────────────────────── │
│           │  RESPONSE  200 OK  ·  423ms  ·  12.4KB                │
│HISTORY    │                                                        │
│ GET /users │  Body │ Headers │ Cookies │                           │
│ POST /auth │  {                                                    │
│ GET /items │    "users": [                                         │
│           │      { "id": 1, "name": "Alice" },                    │
│           │      { "id": 2, "name": "Bob" }                       │
│           │    ],                                                  │
│           │    "total": 42                                         │
│           │  }                                                     │
│           │  [Copy] [Format] [Generate Code ▼] [Save Response]    │
└──────────┴─────────────────────────────────────────────────────────┘
```

**Left sidebar (~200px):**
- Collections tree (expandable folders)
  - Drag to reorder
  - Right-click: Rename, Delete, Duplicate
  - Method badge color (GET=green, POST=orange, PUT=blue, DELETE=red, PATCH=purple)
- History section (recent 50 requests, grouped by date)
- Click any item to load it in the editor

**Right panel — Request editor (top):**
- URL bar: method picker (ThemedPicker or dropdown) + URL field + Send button
- Tab bar: Params, Headers, Auth, Body
  - Params: key-value editor with enable/disable toggles (uses KeyValueItem)
  - Headers: same key-value editor
  - Auth: picker (None, Bearer, Basic, API Key) with relevant fields
  - Body: picker (None, JSON, Form Data, Raw) + editor
- Variables highlighted in URL/values: `{{baseUrl}}` shown in accent color

**Right panel — Response viewer (bottom):**
- Status badge (color-coded), response time, size
- Tab bar: Body, Headers, Cookies
  - Body: CodeEditor with syntax highlighting (auto-detect JSON/XML/HTML)
  - Headers: key-value list
  - Cookies: parsed Set-Cookie headers
- Actions: Copy, Format JSON, Generate Code (dropdown: cURL, Swift, Python, JS, Go), Save

### Environment Management

- Dropdown in ToolHeader to switch active environment
- Environment editor (sheet/popover): name + key-value variable list
- Variables used as `{{variableName}}` anywhere in URL, headers, params, body
- Highlight unresolved variables in red

### Import Support

- Import Postman collection (JSON v2.1)
- Import cURL command (paste or drag)
- Import OpenAPI/Swagger spec (future)

## Storage

All data in `~/Library/Application Support/DX Tools/`:
- `api-collections.json`
- `api-environments.json`
- `api-history.json`

## Tests: `APIClientServiceTests.swift`

- `testVariableInterpolation` — `{{host}}/api` → `example.com/api`
- `testVariableInterpolationNoEnv` — returns original string
- `testVariableInterpolationMissing` — unresolved vars unchanged
- `testGenerateCurl` — valid cURL with method, headers, body
- `testGenerateCurlWithAuth` — bearer token in header
- `testGenerateSwift` — valid URLSession code
- `testGeneratePython` — valid requests code
- `testImportCurl` — parses cURL into APIRequest
- `testImportCurlWithHeaders` — headers parsed
- `testImportCurlWithData` — body extracted
- `testCollectionSerialization` — round-trip JSON
- `testEnvironmentSerialization` — round-trip JSON
- `testHTTPMethodColors` — all methods have assigned colors
- `testRequestBodyJSON` — JSON body correctly set
- `testAuthBearer` — Authorization header added
- `testAuthBasic` — Base64 encoded credentials

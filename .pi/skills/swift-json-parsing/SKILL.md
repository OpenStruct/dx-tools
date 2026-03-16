---
name: swift-json-parsing
description: Parse, format, validate, and transform JSON in Swift. Use when building JSON tools, converting JSON to code (Go structs, Swift Codable, TypeScript interfaces), pretty-printing, minifying, or querying JSON data in Swift applications.
---

# Swift JSON Parsing & Transformation

## JSON Formatting

### Pretty-Print JSON
```swift
func prettyPrint(_ json: String) -> String? {
    guard let data = json.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data),
          let pretty = try? JSONSerialization.data(
              withJSONObject: obj, 
              options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
          ) else { return nil }
    return String(data: pretty, encoding: .utf8)
}
```

### Minify JSON
```swift
func minify(_ json: String) -> String? {
    guard let data = json.data(using: .utf8),
          let obj = try? JSONSerialization.jsonObject(with: data),
          let mini = try? JSONSerialization.data(
              withJSONObject: obj, 
              options: [.withoutEscapingSlashes]
          ) else { return nil }
    return String(data: mini, encoding: .utf8)
}
```

### Validate JSON
```swift
func validate(_ json: String) -> (valid: Bool, error: String?) {
    guard let data = json.data(using: .utf8) else {
        return (false, "Invalid UTF-8")
    }
    do {
        _ = try JSONSerialization.jsonObject(with: data)
        return (true, nil)
    } catch {
        return (false, error.localizedDescription)
    }
}
```

## JSON to Go Struct Conversion

### Core Algorithm

1. Parse JSON into a tree structure
2. Infer types from values
3. Handle nested objects as separate structs
4. Handle arrays by examining element types
5. Generate Go struct with json tags

### Type Inference Rules

| JSON Value | Go Type |
|-----------|---------|
| `"string"` | `string` |
| `123` | `int64` |
| `12.5` | `float64` |
| `true/false` | `bool` |
| `null` | `interface{}` or `*Type` |
| `{}` | Named struct |
| `[]` | `[]Type` |
| Mixed array | `[]interface{}` |

### Key Naming Convention

Convert JSON keys to Go exported field names:
- `user_name` → `UserName` (snake_case to PascalCase)
- `firstName` → `FirstName` (camelCase to PascalCase)  
- `id` → `ID` (common abbreviation)
- `url` → `URL` (common abbreviation)
- `api_key` → `APIKey`

Common Go abbreviations to uppercase: `ID`, `URL`, `API`, `HTTP`, `HTML`, `JSON`, `XML`, `SQL`, `SSH`, `TCP`, `UDP`, `IP`, `DNS`, `TLS`, `SSL`, `UUID`, `EOF`, `OS`

### Handling Nested Objects

```json
{
  "user": {
    "name": "Nam",
    "address": {
      "city": "London"
    }
  }
}
```

Generates:
```go
type Root struct {
    User User `json:"user"`
}

type User struct {
    Name    string  `json:"name"`
    Address Address `json:"address"`
}

type Address struct {
    City string `json:"city"`
}
```

### Handling Arrays

- Empty array `[]` → `[]interface{}`
- Array of same type `[1,2,3]` → `[]int64`
- Array of objects → `[]StructName` (merge all object fields)
- Mixed types → `[]interface{}`

### Handling Nullable Fields

When a field appears as `null` in some array elements but has a value in others, use a pointer type:
```go
type User struct {
    Name  string  `json:"name"`
    Email *string `json:"email,omitempty"` // was null in some entries
}
```

## JSON to Other Languages

### JSON to Swift Codable
```swift
struct Root: Codable {
    let name: String
    let age: Int
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case name, age, email
    }
}
```

### JSON to TypeScript
```typescript
interface Root {
    name: string;
    age: number;
    email: string | null;
}
```

## Syntax Highlighting for JSON Display

For SwiftUI display, use `AttributedString` with colored spans for:
- **Keys**: Blue
- **Strings**: Green  
- **Numbers**: Orange/Yellow
- **Booleans/Null**: Purple
- **Braces/Brackets**: Gray

```swift
func highlightJSON(_ json: String) -> AttributedString {
    var result = AttributedString()
    // Use regex or character-by-character parsing
    // to apply colors to different token types
    return result
}
```

## Error Handling

Always provide line/column info for JSON errors:
```swift
func detailedValidation(_ json: String) -> JSONError? {
    // Count lines up to error position
    // Show context around the error
    // Suggest common fixes (missing comma, trailing comma, etc.)
}
```

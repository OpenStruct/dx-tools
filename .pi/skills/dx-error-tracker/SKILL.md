---
name: dx-error-tracker
description: Build the Error Tracker tool for DX Tools. Local error aggregation — paste or tail log files, auto-parse stack traces, group by error type, show frequency and timeline. No external services. Follow dx-tools-feature skill for architecture.
---

# Error Tracker — Local Error Aggregation

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `errorTracker`
- **Category**: `.devops`
- **Display name**: "Error Tracker"
- **Icon**: `"exclamationmark.triangle.fill"`
- **Description**: "Local error aggregation — parse logs, group by type, track frequency"

## Service: `ErrorTrackerService.swift`

### Models

```swift
struct ParsedError: Identifiable {
    var id: UUID
    var type: String               // "TypeError", "NullPointerException", "SIGABRT"
    var message: String            // "Cannot read property 'x' of undefined"
    var stackTrace: [StackFrame]
    var source: ErrorSource
    var timestamp: Date?
    var level: ErrorLevel
    var raw: String                // Original log line(s)
    var fingerprint: String        // Hash for grouping identical errors
}

struct StackFrame {
    var file: String
    var function: String
    var line: Int?
    var column: Int?
    var isUserCode: Bool           // vs library/framework code
}

enum ErrorSource: String, CaseIterable {
    case javascript = "JavaScript"
    case python = "Python"
    case swift = "Swift"
    case java = "Java"
    case go = "Go"
    case ruby = "Ruby"
    case generic = "Generic"
}

enum ErrorLevel: String, CaseIterable {
    case fatal = "Fatal"
    case error = "Error"
    case warning = "Warning"
    case info = "Info"
}

struct ErrorGroup: Identifiable {
    var id: String                 // fingerprint
    var type: String
    var message: String
    var count: Int
    var firstSeen: Date
    var lastSeen: Date
    var occurrences: [ParsedError]
    var source: ErrorSource
    var level: ErrorLevel
}
```

### Parsing Methods

```swift
// Auto-detect language and parse
static func parse(_ logText: String) -> [ParsedError]
static func detectSource(_ text: String) -> ErrorSource

// Language-specific parsers
static func parseJavaScript(_ text: String) -> [ParsedError]  // TypeError, ReferenceError, SyntaxError + V8/Node stack
static func parsePython(_ text: String) -> [ParsedError]       // Traceback (most recent call last) format
static func parseSwift(_ text: String) -> [ParsedError]        // Fatal error, EXC_BAD_ACCESS, assertion failures
static func parseJava(_ text: String) -> [ParsedError]         // java.lang.NullPointerException + at com.example...
static func parseGo(_ text: String) -> [ParsedError]           // panic: runtime error + goroutine stack
static func parseGeneric(_ text: String) -> [ParsedError]      // ERROR/FATAL/WARN level detection

// Grouping
static func group(_ errors: [ParsedError]) -> [ErrorGroup]
static func fingerprint(_ error: ParsedError) -> String  // Hash of type + message + top frame

// Statistics
static func timeline(_ errors: [ParsedError], buckets: Int) -> [(date: Date, count: Int)]
static func topErrors(_ groups: [ErrorGroup], limit: Int) -> [ErrorGroup]
```

### Pattern Examples

```swift
// JavaScript: "TypeError: Cannot read property 'name' of undefined\n    at Object.<anonymous> (/app/index.js:42:15)"
// Python: "Traceback (most recent call last):\n  File \"app.py\", line 42, in handler\n    result = process(data)\nValueError: invalid literal"
// Swift: "Fatal error: Unexpectedly found nil while unwrapping an Optional value: file MyApp/ViewModel.swift, line 42"
// Java: "java.lang.NullPointerException\n\tat com.example.MyClass.doWork(MyClass.java:42)"
// Go: "panic: runtime error: index out of range [3] with length 3\n\ngoroutine 1 [running]:\nmain.process(...)"
```

## View: `ErrorTrackerView.swift`

### Layout

```
┌──────────────────────────────────────────────────────────────────┐
│ ToolHeader: "Error Tracker"  [Paste Logs] [Open File] [Clear]   │
├──────────────────────────────────────────────────────────────────┤
│ 23 errors · 8 unique · JS: 15  Python: 5  Swift: 3              │
│ ████████████████░░░░░░░░░░░░░░ Timeline (last hour)             │
├──────────────────────────┬───────────────────────────────────────┤
│ ERROR GROUPS        (8)  │  TypeError: Cannot read 'name'       │
│                          │  ────────────────────────────         │
│ ⚠ TypeError        ×15  │  15 occurrences                       │
│   Cannot read 'name'    │  First: 2m ago  Last: 10s ago         │
│ ⚠ ValueError       ×5   │  Source: JavaScript                   │
│   invalid literal       │                                       │
│ ⚠ Fatal error      ×3   │  STACK TRACE                          │
│   found nil             │  → Object.<anonymous> index.js:42     │
│                          │    Module._compile internal:42        │
│                          │    Module.load internal:789           │
│                          │                                       │
│                          │  RAW LOG                              │
│                          │  TypeError: Cannot read property...   │
│                          │      at Object.<anonymous> (/app/...  │
│                          │                                       │
│                          │  [Copy Stack] [Copy Raw] [Resolve]    │
└──────────────────────────┴───────────────────────────────────────┘
```

**Top bar:**
- Stats: total errors, unique groups, breakdown by source
- Mini timeline chart (simple bar chart showing error frequency over time)

**Left panel — Error groups:**
- Grouped by fingerprint, sorted by count (most frequent first)
- Color-coded level: Fatal=red, Error=orange, Warning=yellow
- Shows: error type, truncated message, occurrence count
- Click to view details
- Badge for source language

**Right panel — Detail:**
- Error type and full message
- Occurrence stats: count, first seen, last seen
- Stack trace with syntax highlighting
  - User code frames highlighted (vs library code dimmed)
  - Click frame to copy file:line
- Raw log text (expandable)
- Actions: Copy stack trace, Copy raw, Mark as resolved (hides from list)

### Input Methods

- Paste button: opens text field to paste log output
- Open file: file picker for `.log`, `.txt` files
- Drag & drop log files onto the tool
- Auto-parse on input

## Tests: `ErrorTrackerServiceTests.swift`

- `testParseJavaScript` — TypeError parsed with stack frames
- `testParseJavaScriptSyntaxError` — SyntaxError with location
- `testParsePython` — Traceback format parsed
- `testParsePythonMultiError` — multiple errors in one log
- `testParseSwift` — Fatal error with file:line
- `testParseJava` — NullPointerException with stack
- `testParseGo` — panic with goroutine stack
- `testParseGeneric` — ERROR level detection in plain logs
- `testDetectSourceJS` — detects JavaScript from stack format
- `testDetectSourcePython` — detects Python from Traceback
- `testGrouping` — identical errors grouped together
- `testFingerprint` — same error produces same fingerprint
- `testDifferentFingerprint` — different errors have different fingerprints
- `testTimeline` — buckets contain correct counts
- `testEmptyInput` — returns empty array, no crash

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-000?logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/tools-23-FF8C42" />
  <img src="https://img.shields.io/badge/tests-245-4ADE80" />
  <img src="https://img.shields.io/badge/dependencies-0-blue" />
  <img src="https://img.shields.io/badge/size-2.3MB-purple" />
  <img src="https://img.shields.io/github/license/OpenStruct/dx-tools" />
</p>

# ⚡ DX Tools

**23 developer tools in one native macOS app.** JSON formatting, JWT decoding, port killing, DNS lookups, regex testing — all offline, instant, keyboard-first.

> No Electron. No web wrapper. Pure SwiftUI. 2.3 MB.

---

## Install

### macOS App (DMG)

Download the latest release:

```
https://github.com/OpenStruct/dx-tools/releases/latest
```

### CLI via Homebrew

```bash
brew tap openstruct/tap
brew install dx-tools
```

### Build from Source

```bash
git clone https://github.com/OpenStruct/dx-tools.git
cd dx-tools

# CLI
swift build -c release
cp .build/release/dx /usr/local/bin/

# macOS App
brew install xcodegen  # if not installed
xcodegen generate
xcodebuild -project DXTools.xcodeproj -scheme DXTools -configuration Release build
```

---

## Tools

### JSON
| Tool | Description |
|------|-------------|
| **JSON Formatter** | Format, minify, validate. Syntax highlighting, bracket matching |
| **JSON → Go** | Convert JSON to Go structs with json tags |
| **JSON → Swift** | Convert JSON to Swift Codable models |
| **JSON → TypeScript** | Convert JSON to TypeScript interfaces |
| **JSON Diff** | Side-by-side structural diff with path tracking |

### Encoding
| Tool | Description |
|------|-------------|
| **JWT Decoder** | Decode tokens, inspect claims, check expiration |
| **Base64** | Encode/decode, standard and URL-safe |
| **Hash Generator** | MD5, SHA-1, SHA-256, SHA-512 |
| **URL Encoder** | Percent-encode/decode, parse components |

### Generators
| Tool | Description |
|------|-------------|
| **UUID Generator** | v4 UUIDs, bulk generation, one-click copy |
| **Color Converter** | HEX ↔ RGB ↔ HSL, code gen for Swift/CSS/Flutter/Android/Tailwind |
| **Epoch Converter** | Unix timestamp ↔ human date, 6 world clocks |
| **Password Generator** | Secure passwords & passphrases, strength meter |
| **Unix Permissions** | chmod calculator, numeric ↔ symbolic, interactive checkboxes |
| **Cron Parser** | Human-readable descriptions, next 10 run times |

### DevOps
| Tool | Description |
|------|-------------|
| **Port Manager** | List listening ports, kill processes, search & sort |
| **Network Info** | Local/public IP, DNS lookup (A/AAAA/CNAME/MX/NS/TXT) |
| **API Request Builder** | Send HTTP requests, headers, body, response viewer |
| **Env Manager** | Parse .env files, mask secrets, diff two envs |
| **cURL → Code** | Paste cURL, get Swift/Go/Python/JS/Ruby |

### Text
| Tool | Description |
|------|-------------|
| **Regex Tester** | Live matching, capture groups, replace mode |
| **Markdown Preview** | Side-by-side editor and rendered preview |
| **Lorem Generator** | Words, sentences, paragraphs, fake data, JSON |

---

## CLI

10 subcommands, pipe-friendly, colored output.

```bash
# JSON
dx json format '{"a":1,"b":2}'
dx json validate data.json
dx json minify data.json
dx json query data.json '.users[0].name'

# Encoding
dx jwt decode eyJhbGciOiJIUzI1NiJ9...
dx base64 encode "hello world"
dx hash "hello world"
echo '{"key":"value"}' | dx base64 encode

# Generators
dx uuid
dx uuid --count 5
dx color "#FF5733"
dx epoch now
dx epoch 1700000000
dx pass --length 32

# DevOps
dx port list
dx port kill 3000
dx port check 8080
dx env show .env
dx env diff .env .env.production
```

---

## Features

- **⌘K Command Palette** — Jump to any tool by name
- **Smart Clipboard** — Auto-detects JWT, JSON, cURL, colors, UUIDs, epochs
- **Menu Bar** — Quick UUID, Epoch, Password without opening the app
- **Favorites** — Right-click to pin tools to sidebar
- **Dark / Light / System** — Theme toggle in Settings
- **Global Hotkey** — ⌘⇧Space to summon the app
- **Drag & Drop** — Drop files onto editors
- **Export** — Save output to file (⌘S)
- **History** — Per-tool history of recent operations

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘K` | Command Palette |
| `⌘1-9` | Switch Tool |
| `⌘⏎` | Execute |
| `⌘⇧Space` | Global Launch |
| `⌘⇧C` | Copy Output |
| `⌘S` | Save Output |
| `⌘T` | New Tab |
| `⌘/` | Show Shortcuts |

---

## Architecture

```
DXTools/
├── Models/          # Tool enum, Theme
├── Services/        # Pure logic (23 service files)
├── ViewModels/      # @Observable view models
├── Views/
│   ├── Components/  # CodeEditor, SplitLayout, Toast
│   ├── Sidebar/     # Navigation, Welcome
│   └── Tools/       # 23 tool views
└── DXToolsApp.swift # App entry, menu bar, clipboard

Sources/             # CLI (swift-argument-parser)
DXToolsTests/        # 245 tests across 21 suites
```

- **SwiftUI** with `@Observable` (macOS 14+)
- **MVVM** — Services are pure structs with static methods
- **Zero dependencies** — only swift-argument-parser for CLI
- **XcodeGen** for project generation

---

## Development

```bash
# Generate Xcode project
xcodegen generate

# Build & run
xcodebuild -project DXTools.xcodeproj -scheme DXTools build

# Run tests (245 tests)
xcodebuild -project DXTools.xcodeproj -scheme DXToolsTests test

# Build CLI
swift build -c release

# Build DMG
./scripts/build-dmg.sh
```

---

## License

MIT — see [LICENSE](LICENSE)

Built by [OpenStruct](https://github.com/OpenStruct)

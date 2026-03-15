<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-000?logo=apple&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/tools-33-FF8C42" />
  <img src="https://img.shields.io/badge/tests-300-4ADE80" />
  <img src="https://img.shields.io/badge/dependencies-0-blue" />
  <img src="https://img.shields.io/badge/size-~3MB-purple" />
  <img src="https://img.shields.io/github/license/OpenStruct/dx-tools" />
  <img src="https://img.shields.io/github/v/release/OpenStruct/dx-tools?color=FF8C42" />
</p>

# ⚡ DX Tools

**33 developer tools in one native macOS app.** JSON formatting, JWT decoding, port killing, QR codes, SQL formatting, API testing — all offline, instant, keyboard-first.

> No Electron. No web wrapper. Pure SwiftUI. ~3 MB.

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
| **JSON Schema Validator** | Validate JSON against a schema — type, required, min/max, pattern |

### Encoding
| Tool | Description |
|------|-------------|
| **JWT Decoder** | Decode tokens, inspect claims, check expiration |
| **Base64** | Encode/decode, standard and URL-safe |
| **Hash Generator** | MD5, SHA-1, SHA-256, SHA-512 |
| **URL Encoder** | Percent-encode/decode, parse components |
| **Image Base64** | Encode images to base64/data URI, decode back to image |

### Generators
| Tool | Description |
|------|-------------|
| **UUID Generator** | v4 UUIDs, bulk generation, one-click copy |
| **Color Converter** | HEX ↔ RGB ↔ HSL, code gen for Swift/CSS/Flutter/Android/Tailwind |
| **Epoch Converter** | Unix timestamp ↔ human date, 8 world clocks |
| **Password Generator** | Secure passwords & passphrases, strength meter |
| **Unix Permissions** | chmod calculator, numeric ↔ symbolic, interactive checkboxes |
| **Cron Parser** | Human-readable descriptions, next 10 run times |
| **QR Code Generator** | Generate from text/URL, 4 error correction levels, copy/save PNG |
| **SSH Key Generator** | RSA, Ed25519, ECDSA with custom comments, copy/export |
| **Timestamp Converter** | Unix ↔ ISO 8601 ↔ RFC 2822, timezone support |

### DevOps
| Tool | Description |
|------|-------------|
| **Port Manager** | List listening ports, kill processes, search & sort |
| **Network Info** | Local/public IP, DNS lookup (A/AAAA/CNAME/MX/NS/TXT) |
| **API Request Builder** | Send HTTP requests, headers, query params, body, response viewer |
| **Env Manager** | Parse .env files, mask secrets, diff two envs |
| **cURL → Code** | Paste cURL, get Swift/Go/Python/JS/Ruby |
| **Docker Manager** | Container list, start/stop/remove, image management |
| **Git Stats** | Repository stats, branch info, recent commits |
| **HTTP Status Codes** | Searchable reference, 35+ codes, color-coded categories |

### Text
| Tool | Description |
|------|-------------|
| **Regex Tester** | Live matching, capture groups, replace mode |
| **Markdown Preview** | Side-by-side editor and rendered preview |
| **Lorem Generator** | Words, sentences, paragraphs, fake data, JSON |
| **Text Diff** | LCS-based diff, unified output, side-by-side view |
| **SQL Formatter** | Format & minify SQL, 3 indent styles, JOINs/subqueries |

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
- **Syntax Highlighting** — Live JSON/SQL coloring in editors
- **History** — Per-tool history of recent operations
- **URL Handler** — `dx://tool-name` opens app to specific tool
- **Auto-Update** — Checks GitHub Releases on launch
- **Drag & Drop** — Drop files onto editors
- **Export** — Save output to file (⌘S)

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
├── Services/        # Pure logic (28 service files)
├── ViewModels/      # @Observable view models
├── Views/
│   ├── Components/  # CodeEditor, SplitLayout, ToolHeader, HistoryPanel
│   ├── Sidebar/     # Navigation, Welcome
│   └── Tools/       # 33 tool views
└── DXToolsApp.swift # App entry, menu bar, clipboard

Sources/             # CLI (swift-argument-parser)
DXToolsTests/        # 300 tests across 25 suites
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

# Run tests (300 tests)
xcodebuild -project DXTools.xcodeproj -scheme DXToolsTests test

# Build CLI
swift build -c release

# Build DMG
./scripts/build-dmg.sh
```

---

## Releasing

Releases follow a `dev` → `main` → tag workflow. CI builds, tests, and publishes automatically.

### Quick Release

```bash
# 1. Make sure you're on dev with everything committed
git checkout dev

# 2. Bump version in project.yml
#    MARKETING_VERSION: "X.Y.Z"

# 3. Regenerate Xcode project
xcodegen generate

# 4. Commit and push
git add -A && git commit -m "chore: bump version to X.Y.Z"
git push

# 5. Merge to main
git checkout main
git merge dev --no-ff -m "release: vX.Y.Z — description"
git push

# 6. Tag and push — this triggers CI release
git tag vX.Y.Z
git push origin vX.Y.Z

# 7. Go back to dev
git checkout dev
```

### What CI Does on Tag Push

1. **Builds CLI** — `swift build -c release` → uploads `dx` binary
2. **Builds macOS app** — XcodeGen → xcodebuild → `DX Tools.app`
3. **Runs 300 tests** — all must pass
4. **Packages DMG** — app + Applications symlink + volume icon
5. **Creates GitHub Release** — attaches `DXTools.dmg` + `dx` CLI binary
6. **Deploys website** — if `web/` changed, GitHub Pages updates automatically

### Release Checklist

```
[ ] Version bumped in project.yml (MARKETING_VERSION)
[ ] xcodegen generate ran
[ ] All 300 tests pass locally
[ ] Committed and pushed to dev
[ ] Merged dev → main
[ ] Tag pushed (vX.Y.Z)
[ ] CI green — check https://github.com/OpenStruct/dx-tools/actions
[ ] Release has both DXTools.dmg and dx assets
[ ] Website updated (if web/ changed)
```

### Hotfix

```bash
# Fix directly on dev, then follow normal release flow
git checkout dev
# ... make fix ...
git add -A && git commit -m "fix: description"
git push
# Then merge + tag as above
```

---

## License

MIT — see [LICENSE](LICENSE)

Built by [OpenStruct](https://github.com/OpenStruct)

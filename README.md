# ⚡ dx — Developer Experience Toolkit

A Swiss Army knife CLI for developers. One binary, every tool you reach for daily.

Built with Swift. Fast. Beautiful. Zero dependencies at runtime.

## Install

```bash
swift build -c release
cp .build/release/dx /usr/local/bin/dx
```

## Tools

### 📦 `dx json` — JSON Swiss Army Knife
```bash
dx json '{"name":"Nam","age":28}'          # Pretty-print with syntax highlighting
dx json mini data.json                      # Minify (shows bytes saved)
dx json validate response.json              # Validate + show structure
dx json query "users.0.name" data.json      # Query with dot notation
cat api.json | dx json                      # Pipe from stdin
```

### 🔓 `dx jwt` — JWT Token Inspector
```bash
dx jwt "eyJhbGciOi..."                     # Decode header + payload
                                            # Auto-checks expiration ⏰
                                            # Shows issuer, subject, timestamps
```

### 🕐 `dx epoch` — Time Converter
```bash
dx epoch                                    # Current time in all formats + world clocks
dx epoch decode 1710460800                  # Epoch → human (auto-detects ms vs s)
dx epoch encode "2024-03-15 12:00:00"       # Human → epoch
dx epoch decode 1710460800 --tz Asia/Tokyo  # With timezone
```

### ⚙️ `dx env` — .env File Manager
```bash
dx env                                      # View .env with masked secrets 🔒
dx env --reveal                             # Show actual values
dx env diff .env .env.production            # Compare two env files
dx env validate .env --template .env.example # Check for missing vars
dx env merge .env .env.local -o .env.merged  # Merge env files
```

### 🔐 `dx hash` — Hash Everything
```bash
dx hash "hello world"                       # MD5, SHA1, SHA256, SHA512
dx hash myfile.txt                          # Hash a file
dx hash "secret" -a sha256                  # Specific algorithm
```

### 📦 `dx base64` — Base64 Encode/Decode
```bash
dx base64 encode "hello"                    # Encode string
dx base64 encode image.png                  # Encode file
dx base64 decode "aGVsbG8="                # Decode
dx base64 decode "aGVsbG8=" -o output.txt  # Decode to file
dx base64 encode "data" --url-safe          # URL-safe encoding
```

### 🎲 `dx uuid` — UUID Generator
```bash
dx uuid                                     # Generate 1 UUID with details
dx uuid 10                                  # Generate 10 UUIDs
dx uuid --upper                             # Uppercase
dx uuid --compact                           # No dashes
```

### 🎨 `dx color` — Color Converter
```bash
dx color '#FF5733'                          # HEX → RGB, HSL + code snippets
dx color 'rgb(255,87,51)'                   # RGB input
dx color 'hsl(11,100%,60%)'                # HSL input
                                            # Shows: CSS, Swift, SwiftUI, Android,
                                            #        Flutter, Tailwind + shade palette
```

### 🔑 `dx pass` — Password Generator
```bash
dx pass                                     # 5 strong passwords (24 chars)
dx pass -l 32 -c 10                        # 10 passwords, 32 chars
dx pass --alphanumeric                      # No special characters
dx pass --phrase                            # Generate passphrases
dx pass --phrase --words 5                  # 5-word passphrases
dx pass | head -1 | pbcopy                  # Copy to clipboard
```

## Piping & Composition

```bash
curl -s api.example.com/users | dx json
curl -s api.example.com/users | dx json query "data.0.name"
echo $JWT_TOKEN | dx jwt
dx uuid | pbcopy
dx hash "$(dx pass -c 1 | tail -1)"
```

## Requirements

- macOS 13+
- Swift 5.9+

## License

MIT

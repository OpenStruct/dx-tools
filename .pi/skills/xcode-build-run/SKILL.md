---
name: xcode-build-run
description: Build, run, test, and debug macOS and iOS Xcode projects from the command line. Use when you need to compile, launch, check for build errors, run tests, or manage Xcode build artifacts without opening Xcode GUI.
---

# Xcode Build & Run from CLI

## Prerequisites

```bash
# Ensure Xcode CLI tools are installed
xcode-select --install

# Check current Xcode path
xcode-select -p

# Ensure xcodegen is available for project generation
brew install xcodegen
```

## Generating the Xcode Project

When using XcodeGen:
```bash
cd /path/to/project
xcodegen generate
```

## Building

### Debug Build
```bash
xcodebuild -project AppName.xcodeproj \
  -scheme AppName \
  -configuration Debug \
  build \
  2>&1 | tail -20
```

### Release Build
```bash
xcodebuild -project AppName.xcodeproj \
  -scheme AppName \
  -configuration Release \
  build
```

### Build and Show Errors Only
```bash
xcodebuild -project AppName.xcodeproj \
  -scheme AppName \
  build 2>&1 | grep -E "(error:|warning:|BUILD)"
```

### Find Build Output Path
```bash
xcodebuild -project AppName.xcodeproj \
  -scheme AppName \
  -showBuildSettings 2>/dev/null | grep -E "BUILT_PRODUCTS_DIR|FULL_PRODUCT_NAME"
```

## Running the App

```bash
# Build and get the app path, then open it
BUILD_DIR=$(xcodebuild -project AppName.xcodeproj -scheme AppName -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | awk '{print $3}')
APP_NAME=$(xcodebuild -project AppName.xcodeproj -scheme AppName -showBuildSettings 2>/dev/null | grep "FULL_PRODUCT_NAME" | awk '{print $3}')

# Build first
xcodebuild -project AppName.xcodeproj -scheme AppName build 2>&1 | tail -5

# Then launch
open "$BUILD_DIR/$APP_NAME"
```

### Quick Build & Run Script
```bash
#!/bin/bash
set -e
PROJECT="AppName.xcodeproj"
SCHEME="AppName"

echo "🔨 Building..."
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug build 2>&1 | tail -5

BUILD_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | awk '{print $3}')
APP=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null | grep "FULL_PRODUCT_NAME" | awk '{print $3}')

echo "🚀 Launching $APP..."
open "$BUILD_DIR/$APP"
```

## Testing

```bash
xcodebuild test -project AppName.xcodeproj \
  -scheme AppName \
  -destination 'platform=macOS' \
  2>&1 | grep -E "(Test Case|passed|failed|error:)"
```

## Cleaning

```bash
# Clean build
xcodebuild clean -project AppName.xcodeproj -scheme AppName

# Nuclear clean
rm -rf ~/Library/Developer/Xcode/DerivedData/AppName-*
rm -rf build/
```

## Common Build Errors

| Error | Fix |
|-------|-----|
| `No such module` | Check dependencies, run `swift package resolve` |
| `Signing requires a development team` | Set `DEVELOPMENT_TEAM` in build settings or disable signing |
| `Command CompileSwift failed` | Check Swift syntax errors in output |
| `Missing Info.plist` | Ensure path in build settings matches actual file |

## Disable Code Signing (for CLI builds)

Add to xcodebuild command:
```bash
xcodebuild ... CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

Or in project.yml for XcodeGen:
```yaml
settings:
  base:
    CODE_SIGN_IDENTITY: ""
    CODE_SIGNING_REQUIRED: "NO"
```

## List Available Schemes

```bash
xcodebuild -project AppName.xcodeproj -list
```

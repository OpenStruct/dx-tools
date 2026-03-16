---
name: xcode-project
description: Generate and manage Xcode projects for macOS and iOS apps from the command line. Use when creating new Xcode projects, modifying build settings, adding files to targets, managing schemes, or configuring signing. Handles pbxproj file generation without needing Xcode GUI.
---

# Xcode Project Management

## Generating a macOS App Xcode Project

Since we can't use Xcode GUI, we use `XcodeGen` to generate projects from a YAML spec.

### Install XcodeGen

```bash
brew install xcodegen
```

### Project Spec (project.yml)

```yaml
name: AppName
options:
  bundleIdPrefix: com.yourcompany
  deploymentTarget:
    macOS: "13.0"
  xcodeVersion: "15.0"
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "5.9"
    MACOSX_DEPLOYMENT_TARGET: "13.0"
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: 1

targets:
  AppName:
    type: application
    platform: macOS
    sources:
      - path: AppName
        excludes:
          - "*.xcassets/.*"
    resources:
      - path: AppName/Assets.xcassets
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.AppName
        INFOPLIST_FILE: AppName/Info.plist
        CODE_SIGN_STYLE: Automatic
        DEVELOPMENT_TEAM: ""
        PRODUCT_NAME: $(TARGET_NAME)
        COMBINE_HIDPI_IMAGES: YES
        ENABLE_HARDENED_RUNTIME: YES
    entitlements:
      path: AppName/AppName.entitlements
      properties:
        com.apple.security.app-sandbox: true
        com.apple.security.files.user-selected.read-write: true

  AppNameTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: AppNameTests
    dependencies:
      - target: AppName
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.AppNameTests
```

### Generate & Open

```bash
xcodegen generate
open AppName.xcodeproj
```

### Alternative: Swift Package with macOS App

For simpler projects, use Package.swift:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppName",
    platforms: [.macOS(.v13)],
    dependencies: [
        // Add dependencies here
    ],
    targets: [
        .executableTarget(
            name: "AppName",
            dependencies: [],
            path: "Sources"
        ),
    ]
)
```

Note: SPM-based macOS apps have limitations (no asset catalogs, no storyboards, no entitlements management). Use XcodeGen for full-featured apps.

## Common Operations

### Add a new Swift file to the project
Just create the file in the source directory and regenerate:
```bash
touch AppName/Views/NewView.swift
xcodegen generate
```

### Build from CLI
```bash
xcodebuild -project AppName.xcodeproj -scheme AppName build
```

### Run from CLI
```bash
xcodebuild -project AppName.xcodeproj -scheme AppName build
open "build/Debug/AppName.app"
```

### Clean
```bash
xcodebuild clean -project AppName.xcodeproj -scheme AppName
rm -rf ~/Library/Developer/Xcode/DerivedData/AppName-*
```

## Info.plist Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>AppName</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

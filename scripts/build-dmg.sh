#!/bin/bash
set -e

APP_NAME="DX Tools"
VERSION="2.0.0"
PROJECT="DXTools.xcodeproj"
SCHEME="DXTools"
DMG_NAME="DXTools-${VERSION}"
BUILD_DIR="build/release"
DMG_DIR="build/dmg"

echo "⚡ Building DX Tools v${VERSION}..."

# Clean
rm -rf build/

# Build release
xcodebuild -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath build/derived \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build 2>&1 | grep -E "(BUILD|error:)" || true

# Find the built app
APP_PATH=$(find build/derived -name "*.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
  echo "❌ Build failed - no .app found"
  exit 1
fi

echo "✅ Built: $APP_PATH"

# Create DMG staging
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"

# Create Applications symlink
ln -sf /Applications "$DMG_DIR/Applications"

# Create DMG
echo "📦 Creating DMG..."
hdiutil create -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov -format UDZO \
  "build/${DMG_NAME}.dmg"

echo ""
echo "🎉 Done!"
echo "   DMG: build/${DMG_NAME}.dmg"
echo "   Size: $(du -h "build/${DMG_NAME}.dmg" | cut -f1)"

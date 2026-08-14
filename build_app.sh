#!/bin/bash
# Creates a macOS .app bundle from the Swift build output
# This is needed for CoreLocation permissions and LSUIElement behavior

set -e

APP_NAME="SpeedTestBar"
BUILD_DIR=".build/debug"
APP_BUNDLE="$APP_NAME.app"

echo "🔨 Building..."
swift build

echo "📦 Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist and AppIcon
cp "Sources/$APP_NAME/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Sources/$APP_NAME/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Ad-hoc code sign (required for CoreLocation permissions on modern macOS)
echo "🔏 Code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Created $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"

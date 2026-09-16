#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Prefer Command Line Tools so building does not require the full Xcode app.
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Library/Developer/CommandLineTools ]; then
    export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
BUILD_ARCH="${ARCH:-arm64}"
APP_PATH="$PWD/dist/DockKeys.app"
mkdir -p build/module-cache "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

xcrun swiftc -swift-version 5 -O -sdk "$SDK_PATH" \
    -target "$BUILD_ARCH-apple-macosx13.0" -module-cache-path "$PWD/build/module-cache" \
    -framework AppKit -framework SwiftUI -framework Carbon -framework ServiceManagement \
    Sources/*.swift -o "$APP_PATH/Contents/MacOS/DockKeys"
cp Resources/Info.plist "$APP_PATH/Contents/Info.plist"

xcrun swiftc -sdk "$SDK_PATH" -module-cache-path "$PWD/build/module-cache" \
    scripts/make-icon.swift -o build/make-icon
build/make-icon "$PWD/build/AppIcon.iconset"
iconutil -c icns build/AppIcon.iconset -o "$APP_PATH/Contents/Resources/AppIcon.icns"
cp LICENSE "$APP_PATH/Contents/Resources/LICENSE"
codesign --force --sign "${CODE_SIGN_IDENTITY:--}" --timestamp=none "$APP_PATH"
codesign --verify --strict "$APP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "dist/DockKeys-$BUILD_ARCH.zip"
printf 'Built: %s\n' "$APP_PATH"

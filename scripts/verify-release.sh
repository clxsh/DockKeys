#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Library/Developer/CommandLineTools ]; then
    export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
mkdir -p build
CHECK_DIR=$(mktemp -d "$PWD/build/verify.XXXXXX")
MOUNTED=''
cleanup() {
    if [ -n "$MOUNTED" ]; then hdiutil detach "$MOUNTED" >/dev/null; fi
    rm -rf "$CHECK_DIR"
}
trap cleanup EXIT

verify_app() {
    local app="$1" expected_arch="$2"
    test "$(xcrun lipo -archs "$app/Contents/MacOS/DockKeys")" = "$expected_arch"
    test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" = "$VERSION"
    test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' "$app/Contents/Info.plist")" = AppIcon
    codesign --verify --strict "$app"
    cmp "$app/Contents/Resources/AppIcon.icns" dist/arm64/DockKeys.app/Contents/Resources/AppIcon.icns
    cmp "$app/Contents/Resources/LICENSE" LICENSE
}

(cd dist && shasum -a 256 -c SHA256SUMS.txt)
for BUILD_ARCH in arm64 x86_64; do
    PREFIX="dist/DockKeys-$VERSION-$BUILD_ARCH"
    ditto -x -k "$PREFIX.zip" "$CHECK_DIR/$BUILD_ARCH"
    verify_app "$CHECK_DIR/$BUILD_ARCH/DockKeys.app" "$BUILD_ARCH"
    hdiutil verify "$PREFIX.dmg"
    mkdir -p "$CHECK_DIR/mount"
    hdiutil attach -readonly -nobrowse -mountpoint "$CHECK_DIR/mount" "$PREFIX.dmg"
    MOUNTED="$CHECK_DIR/mount"
    verify_app "$MOUNTED/DockKeys.app" "$BUILD_ARCH"
    test "$(readlink "$MOUNTED/Applications")" = /Applications
    cmp "$MOUNTED/INSTALL.txt" docs/INSTALL.txt
    hdiutil detach "$MOUNTED"
    MOUNTED=''
    printf 'Verified DMG and ZIP: %s\n' "$BUILD_ARCH"
done

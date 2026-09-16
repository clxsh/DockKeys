#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)
mkdir -p build dist
STAGING=$(mktemp -d "$PWD/build/dmg.XXXXXX")
trap 'rm -rf "$STAGING"' EXIT

for BUILD_ARCH in arm64 x86_64; do
    ARCH="$BUILD_ARCH" ./scripts/build.sh
    PAYLOAD="$STAGING/$BUILD_ARCH"
    mkdir -p "$PAYLOAD"
    ditto "dist/$BUILD_ARCH/DockKeys.app" "$PAYLOAD/DockKeys.app"
    ln -s /Applications "$PAYLOAD/Applications"
    cp docs/INSTALL.txt "$PAYLOAD/INSTALL.txt"
    hdiutil create -ov -volname "DockKeys $VERSION ($BUILD_ARCH)" \
        -srcfolder "$PAYLOAD" -fs HFS+ -format UDZO \
        "dist/DockKeys-$VERSION-$BUILD_ARCH.dmg"
done

(
    cd dist
    shasum -a 256 "DockKeys-$VERSION-arm64.dmg" "DockKeys-$VERSION-arm64.zip" \
        "DockKeys-$VERSION-x86_64.dmg" "DockKeys-$VERSION-x86_64.zip" > SHA256SUMS.txt
)
printf 'Release assets: %s/dist\n' "$PWD"

#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ -z "${DEVELOPER_DIR:-}" ] && [ -d /Library/Developer/CommandLineTools ]; then
    export DEVELOPER_DIR=/Library/Developer/CommandLineTools
fi
mkdir -p build/module-cache
xcrun swiftc -swift-version 5 -module-cache-path "$PWD/build/module-cache" \
    Sources/DockModel.swift Tests/CoreTests.swift -o build/core-tests
build/core-tests
xcrun swiftc -swift-version 5 -module-cache-path "$PWD/build/module-cache" \
    Sources/DockModel.swift Sources/HotKeyManager.swift Tests/HotKeyTests.swift \
    -framework AppKit -framework Carbon -o build/hotkey-tests
build/hotkey-tests

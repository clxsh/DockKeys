<p align="center"><img src="docs/assets/dockkeys.png" width="88" height="88" alt="DockKeys" /></p>

# DockKeys

[简体中文](README.md) · **English**

**Reach your Dock apps with number shortcuts.**

DockKeys is a lightweight macOS menu bar app. Press `⌥ + 1` to launch or switch to the first pinned Dock app, `⌥ + 2` for the second, and so on. Reorder your Dock and the shortcuts follow automatically.

Swift / AppKit / SwiftUI · Apple Silicon and Intel · macOS 13+ · No third-party runtime dependencies · [MIT license](LICENSE)

## Why DockKeys exists

On Windows, `Win + number` launches or switches to an app by its position on the taskbar. For frequently used apps, this lets muscle memory replace searching by name or cycling through an app switcher.

[Snap for macOS](https://apps.apple.com/us/app/snap/id418073146?mt=12) offers a similar experience, but its App Store listing remains at version 1.5, released in 2012, and its app uses the Intel architecture. DockKeys brings that simple workflow to a native Apple Silicon implementation with source code you can build, inspect and maintain. A separate Intel build is also available.

The project focuses on three things: **following Dock order, keeping configuration simple, and keeping the code easy to maintain**. Its icon shows app tiles above a Dock shelf; the menu and settings window show which app each number targets.

## Features

| Feature | Behavior |
|---|---|
| Positional launch and switching | `⌥ + 1…9` targets the first nine pinned apps; `⌥ + 0` targets the tenth |
| Dock order synchronization | Refreshes automatically and rereads the order whenever a shortcut is triggered |
| Modifier selection | Option, Control, Command and preset combinations |
| Optional Finder slot | Include Finder in the first position; off by default |
| Press again to hide | Hide the target if it is already frontmost; on by default |
| Live mapping | View apps and shortcuts in the settings window and menu bar |
| Conflict feedback | Mark shortcuts that could not be registered; change the combination or release the conflict and retry |
| Empty slots | Unassigned positions do not reserve a shortcut |
| Pause and resume | Temporarily release all shortcuts |
| Launch at login | Uses the macOS login item service; off by default |

## Download and install

Download a DMG from [GitHub Releases](https://github.com/clxsh/DockKeys/releases/latest):

| Your Mac | Download |
|---|---|
| Apple Silicon (M-series) | `DockKeys-<version>-arm64.dmg` |
| Intel | `DockKeys-<version>-x86_64.dmg` |

1. Quit any older running copy of DockKeys.
2. Open the DMG and drag `DockKeys.app` into its `Applications` shortcut.
3. Open DockKeys from Applications, then eject the disk image.
4. Review the mapping in the settings window and press `Option + number` to launch or switch apps.

ZIP archives contain the same app for manual installation. To check downloaded files, place them beside `SHA256SUMS.txt` and run `shasum -a 256 -c SHA256SUMS.txt --ignore-missing`.

**The release is ad-hoc signed and has not been notarized by Apple.** If macOS blocks it, first verify the source and checksum, then follow [Apple's instructions for opening an app from an unknown developer](https://support.apple.com/en-sg/guide/mac-help/mh40616/mac). Packaging as a DMG does not replace signing or notarization.

Closing the settings window leaves DockKeys running in the menu bar. Click its app-tiles-and-shelf icon to reopen settings, pause shortcuts or quit.

For example, pinned apps ordered `Browser → Terminal → Editor` map to `⌥1 → ⌥2 → ⌥3`. Enabling Finder gives Finder `⌥1` and shifts the other apps one place. If Snap or another hotkey tool already uses the same combination, release that shortcut or choose another modifier in DockKeys. Quitting DockKeys releases its registered shortcuts.

## Requirements and privacy

- macOS 13 or later. Separate ARM64 and x86_64 builds are provided.
- Core functionality uses system hotkey registration and application launch APIs; it does not require Accessibility or Screen Recording permission.
- Launch at login uses the system login item service; settings provide a link when macOS requires approval.
- The app works offline and has no accounts, telemetry or automatic update service.
- ARM64 has been built and tested locally. The Intel build is cross-compiled and its architecture, signature and package contents are checked; it has not been run on an Intel Mac.

## Build and test

Install Xcode Command Line Tools or full Xcode.

```sh
git clone https://github.com/clxsh/DockKeys.git
cd DockKeys
./scripts/test.sh
./scripts/build.sh
open dist/arm64/DockKeys.app
```

The default target is ARM64. Build Intel with `ARCH=x86_64 ./scripts/build.sh`. Each architecture gets its own output directory so the builds do not overwrite each other.

To create both DMG and ZIP packages with checksums:

```sh
./scripts/release.sh
./scripts/verify-release.sh
```

```text
dist/
├── arm64/DockKeys.app
├── x86_64/DockKeys.app
├── DockKeys-<version>-arm64.dmg
├── DockKeys-<version>-arm64.zip
├── DockKeys-<version>-x86_64.dmg
├── DockKeys-<version>-x86_64.zip
└── SHA256SUMS.txt
```

The scripts prefer standalone Command Line Tools and respect `DEVELOPER_DIR`. Set `CODE_SIGN_IDENTITY` to use a Developer ID certificate with hardened runtime and a timestamp. Notarization and stapling are separate steps to complete before distributing a notarized release.

Tests cover Dock ordering, Finder numbering, empty slots, malformed entries, encoded paths, the ten-slot limit, hide behavior, and actual system hotkey conflicts and release. Hotkey tests require a logged-in macOS graphical session; restricted sandboxes and headless sessions may reject registration. Package verification checks both DMGs and extracted ZIP apps, architectures, versions, signatures, shared icons, Applications shortcuts and checksums.

Print the current Dock mapping without opening the UI:

```sh
dist/arm64/DockKeys.app/Contents/MacOS/DockKeys --diagnose
```

## Scope and limitations

- Only apps pinned to the Dock's application area are numbered, up to ten positions. Temporary running apps, recent apps, folders, documents and separators are excluded.
- Shortcuts use physical number-row keys, not the numeric keypad. Verify the positions on non-US layouts.
- Shortcuts target apps. Multiple windows are handled by the target app; window cycling and tiling are not implemented.
- Restoring minimized windows and switching across desktops or full-screen spaces follow the target app and macOS settings. DockKeys does not force windows to move.
- Global hotkey registration detects other registered global hotkeys, but cannot predict every app's menu shortcuts. Combinations such as `Command + number` may override browser tab shortcuts.
- Pinned Dock apps are read from system preferences. Future macOS changes to this format may require updates.
- The app's interface is currently Simplified Chinese. An English README does not change the UI language. Automatic updates and individually recorded per-app shortcuts are outside the current scope.

## Code layout

| File | Responsibility |
|---|---|
| `Sources/DockModel.swift` | Parsing, filtering, numbering and activation decisions |
| `Sources/DockReader.swift` | Refreshing and reading Dock preferences |
| `Sources/HotKeyManager.swift` | Registering and releasing hotkeys; reporting conflicts |
| `Sources/AppState.swift` | Preferences, mapping, launch/hide and login item state |
| `Sources/DockIcon.swift` | Shared app icon and menu bar symbol renderer |
| `Sources/SettingsView.swift` | Settings and live mapping UI |
| `Sources/Main.swift` | App lifecycle and menu bar |
| `Tests/` | Core logic and system hotkey integration tests |
| `scripts/` | Build, tests, icon generation, DMG packaging and package verification |

## Feedback and contributions

Use [Issues](https://github.com/clxsh/DockKeys/issues) to report problems. Include your macOS version, processor architecture, shortcut combination, Finder setting and reproduction steps. For switching issues, mention whether the target app is minimized, full screen or on another desktop.

Run `./scripts/test.sh` and `./scripts/build.sh` before submitting changes, and verify affected UI or system behavior. For packaging changes, also run `./scripts/release.sh` and `./scripts/verify-release.sh`.

## License

[MIT](LICENSE).

import Foundation

struct DockApp: Equatable, Identifiable {
    let url: URL
    let bundleID: String?
    let name: String
    var id: String { url.path }

    static let finder = DockApp(
        url: URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"),
        bundleID: "com.apple.finder", name: "Finder")
}

enum DockModel {
    static let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    // The Dock's stored order excludes Finder and includes non-app spacer tiles.
    static func apps(from entries: [[String: Any]], includeFinder: Bool) -> [DockApp] {
        var result: [DockApp] = includeFinder ? [.finder] : []
        var seen = Set(result.map(\.id))
        for entry in entries {
            guard entry["tile-type"] as? String == "file-tile",
                  let data = entry["tile-data"] as? [String: Any],
                  let file = data["file-data"] as? [String: Any],
                  let path = file["_CFURLString"] as? String else { continue }
            let url: URL?
            if path.hasPrefix("/") { url = URL(fileURLWithPath: path) }
            else { url = URL(string: path) }
            guard let url, url.isFileURL, url.pathExtension.lowercased() == "app" else { continue }
            let normalized = url.standardizedFileURL
            let bundleID = data["bundle-identifier"] as? String
            guard bundleID != "com.apple.finder", seen.insert(normalized.path).inserted else { continue }
            let name = (data["file-label"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                ?? normalized.deletingPathExtension().lastPathComponent
            result.append(DockApp(url: normalized, bundleID: bundleID, name: name))
        }
        return Array(result.prefix(digits.count))
    }

    static func app(at slot: Int, in apps: [DockApp]) -> DockApp? {
        guard apps.indices.contains(slot) else { return nil }
        return apps[slot]
    }
}

enum ActivationAction: Equatable { case open, hide }

func activationAction(isFrontmost: Bool, hideOnRepeat: Bool) -> ActivationAction {
    isFrontmost && hideOnRepeat ? .hide : .open
}

enum ModifierChoice: String, CaseIterable, Identifiable {
    case option, controlOption, commandOption, commandShift, command, control
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .option: return "⌥"
        case .controlOption: return "⌃⌥"
        case .commandOption: return "⌥⌘"
        case .commandShift: return "⇧⌘"
        case .command: return "⌘"
        case .control: return "⌃"
        }
    }
    var label: String {
        switch self {
        case .option: return "⌥  Option"
        case .controlOption: return "⌃⌥  Control + Option"
        case .commandOption: return "⌥⌘  Option + Command"
        case .commandShift: return "⇧⌘  Shift + Command"
        case .command: return "⌘  Command"
        case .control: return "⌃  Control"
        }
    }
}

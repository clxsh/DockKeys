import Foundation

enum DockReader {
    static func read(includeFinder: Bool) -> [DockApp] {
        let domain = "com.apple.dock" as CFString
        // Synchronize the preferences cache before each read; otherwise reordering
        // icons in a different process can leave the bindings on the old order.
        CFPreferencesSynchronize(domain, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        let entries = CFPreferencesCopyValue(
            "persistent-apps" as CFString, domain,
            kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? [[String: Any]] ?? []
        return DockModel.apps(from: entries, includeFinder: includeFinder)
    }
}

import AppKit
import Carbon

@main struct HotKeyTests {
    static func main() {
        _ = NSApplication.shared
        let first = HotKeyManager()
        let second = HotKeyManager()
        guard first.installError == noErr, second.installError == noErr else {
            fputs("FAIL: cannot install Carbon event handler\n", stderr); exit(1)
        }
        // Select one free modifier without disturbing existing registrations.
        guard let modifier = ModifierChoice.allCases.first(where: {
            let failures = first.register(count: 1, modifier: $0)
            if !failures.isEmpty { print("Registration \($0.rawValue): \(failures)") }
            return failures.isEmpty
        }) else {
            fputs("FAIL: no available shortcut for integration test\n", stderr); exit(1)
        }
        guard second.register(count: 1, modifier: modifier)[0] != nil else {
            fputs("FAIL: duplicate hotkey was not reported\n", stderr); exit(1)
        }
        print("PASS: occupied shortcut is reported")
        first.unregister()
        guard second.register(count: 1, modifier: modifier).isEmpty else {
            fputs("FAIL: hotkey was not released\n", stderr); exit(1)
        }
        print("PASS: released shortcut can be registered again")
        second.unregister()
        guard first.register(count: 0, modifier: modifier).isEmpty,
              second.register(count: 1, modifier: modifier).isEmpty else {
            fputs("FAIL: empty mapping reserves a hotkey\n", stderr); exit(1)
        }
        second.unregister()
        print("PASS: empty mapping leaves shortcut available")
    }
}

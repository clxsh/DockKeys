import Foundation

@main struct CoreTests {
    static func main() {
        var passed = 0
        func check(_ condition: @autoclosure () -> Bool, _ description: String) {
            guard condition() else { fputs("FAIL: \(description)\n", stderr); exit(1) }
            passed += 1
            print("PASS: \(description)")
        }
        func entry(_ name: String, id: String? = nil, path: String? = nil) -> [String: Any] {
            var data: [String: Any] = ["file-label": name, "file-data": ["_CFURLString": path ?? "file:///Applications/\(name).app/"]]
            if let id { data["bundle-identifier"] = id }
            return ["tile-type": "file-tile", "tile-data": data]
        }
        let edge = entry("Edge", id: "com.microsoft.edgemac")
        let terminal = entry("Terminal", id: "com.apple.Terminal")
        let first = DockModel.apps(from: [edge, terminal], includeFinder: false)
        check(first.map(\.name) == ["Edge", "Terminal"], "pinned order is preserved")
        check(DockModel.apps(from: [terminal, edge], includeFinder: false).first?.name == "Terminal", "reordered input updates slot one")
        check(DockModel.apps(from: [edge], includeFinder: true).map(\.name) == ["Finder", "Edge"], "Finder can occupy slot one")
        check(DockModel.apps(from: [], includeFinder: false).isEmpty, "empty Dock stays empty")
        check(DockModel.apps(from: [], includeFinder: true) == [.finder], "empty Dock can include Finder")
        check(DockModel.app(at: -1, in: first) == nil, "negative slot is ignored")
        check(DockModel.app(at: 2, in: first) == nil, "out-of-range slot is ignored")
        check(DockModel.app(at: 9, in: []) == nil, "empty slot ten is safe")
        let invalid: [[String: Any]] = [[:], ["tile-type": "spacer-tile"], entry("Web", path: "https://example.com/X.app"), entry("Folder", path: "file:///tmp/folder"), entry("Doc", path: "file:///tmp/a.pdf")]
        check(DockModel.apps(from: invalid, includeFinder: false).isEmpty, "malformed entries, spacers, URLs and documents are skipped")
        let encoded = entry("Visual Studio Code", path: "file:///Applications/Visual%20Studio%20Code.app/")
        check(DockModel.apps(from: [encoded], includeFinder: false).first?.url.path == "/Applications/Visual Studio Code.app", "percent-encoded paths are decoded")
        check(DockModel.apps(from: [entry("测试", path: "/Applications/测试.app")], includeFinder: false).first?.name == "测试", "Unicode filesystem paths work")
        check(DockModel.apps(from: [edge, edge], includeFinder: false).count == 1, "duplicate paths do not use two slots")
        let finder = entry("Finder", id: "com.apple.finder", path: DockApp.finder.url.absoluteString)
        check(DockModel.apps(from: [finder, edge], includeFinder: true).count == 2, "Finder is not duplicated")
        let many = (1...14).map { entry("App\($0)") }
        check(DockModel.apps(from: many, includeFinder: false).count == 10, "only ten applications are mapped")
        check(DockModel.apps(from: many, includeFinder: true).last?.name == "App9", "Finder consumes one of ten slots")
        check(DockModel.digits[9] == "0", "zero maps to the tenth slot")
        check(activationAction(isFrontmost: true, hideOnRepeat: true) == .hide, "active app hides when enabled")
        check(activationAction(isFrontmost: true, hideOnRepeat: false) == .open, "disabled hide preference keeps app open")
        check(activationAction(isFrontmost: false, hideOnRepeat: true) == .open, "background app opens instead of hiding")
        print("\(passed) core checks passed.")
    }
}

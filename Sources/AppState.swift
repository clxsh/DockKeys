import AppKit
import Combine
import ServiceManagement

final class AppState: ObservableObject {
    @Published private(set) var apps: [DockApp] = []
    @Published private(set) var failures: [Int: OSStatus] = [:]
    @Published private(set) var message: String?
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginNeedsApproval = false
    @Published var paused = false { didSet { updateRegistration(force: true) } }
    @Published var modifier: ModifierChoice {
        didSet { defaults.set(modifier.rawValue, forKey: "modifier"); updateRegistration(force: true) }
    }
    @Published var includeFinder: Bool {
        didSet { defaults.set(includeFinder, forKey: "includeFinder"); refresh() }
    }
    @Published var hideOnRepeat: Bool {
        didSet { defaults.set(hideOnRepeat, forKey: "hideOnRepeat") }
    }
    private let defaults: UserDefaults
    private let hotkeys = HotKeyManager()
    private var timer: Timer?
    private var registeredCount = -1
    private var opening = Set<String>()
    private var iconCache: [String: NSImage] = [:]
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        modifier = ModifierChoice(rawValue: defaults.string(forKey: "modifier") ?? "") ?? .option
        includeFinder = defaults.bool(forKey: "includeFinder")
        hideOnRepeat = defaults.object(forKey: "hideOnRepeat") as? Bool ?? true
        hotkeys.onPress = { [weak self] in self?.activate(slot: $0) }
    }

    func start() {
        refresh()
        refreshLoginStatus()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        hotkeys.unregister()
    }

    func refresh() {
        let latest = DockReader.read(includeFinder: includeFinder)
        if latest != apps {
            apps = latest
            iconCache = iconCache.filter { key, _ in latest.contains { $0.id == key } }
            onChange?()
        }
        updateRegistration()
    }

    func retryShortcuts() {
        refresh()
        updateRegistration(force: true)
    }

    private func updateRegistration(force: Bool = false) {
        let count = paused ? 0 : apps.count
        guard force || registeredCount != count else { return }
        failures = hotkeys.register(count: count, modifier: modifier)
        registeredCount = count
        onChange?()
    }

    func icon(for app: DockApp) -> NSImage {
        if let image = iconCache[app.id] { return image }
        let image = NSWorkspace.shared.icon(forFile: app.url.path)
        iconCache[app.id] = image
        return image
    }

    func shortcut(for slot: Int) -> String { modifier.symbol + " " + DockModel.digits[slot] }

    func activate(slot: Int) {
        guard !paused else { return }
        refresh()
        guard let app = DockModel.app(at: slot, in: apps) else { return }
        let frontmost = NSWorkspace.shared.frontmostApplication
        let isFrontmost = frontmost?.bundleURL?.standardizedFileURL == app.url.standardizedFileURL
        if activationAction(isFrontmost: isFrontmost, hideOnRepeat: hideOnRepeat) == .hide {
            if frontmost?.hide() != true { message = "无法隐藏 \(app.name)，请稍后重试。" }
            else { message = nil }
            return
        }
        guard !opening.contains(app.id) else { return }
        let target: URL
        if FileManager.default.fileExists(atPath: app.url.path) { target = app.url }
        else if let id = app.bundleID, let relocated = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            target = relocated
        } else {
            message = "找不到 \(app.name)。请从 Dock 移除失效图标，再重新添加应用。"
            return
        }
        opening.insert(app.id)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        // Opening a running application sends the standard reopen event, which
        // restores minimized windows according to that application's behavior.
        NSWorkspace.shared.openApplication(at: target, configuration: configuration) { [weak self] _, error in
            DispatchQueue.main.async {
                self?.opening.remove(app.id)
                self?.message = error.map { "打开 \(app.name) 失败：\($0.localizedDescription)" }
            }
        }
    }

    func refreshLoginStatus() {
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled || status == .requiresApproval
        loginNeedsApproval = status == .requiresApproval
    }

    func setLoginEnabled(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            message = nil
        } catch {
            message = "登录启动设置失败：\(error.localizedDescription)。建议先将应用放入“应用程序”文件夹。"
        }
        refreshLoginStatus()
    }

    func clearMessage() { message = nil }
}

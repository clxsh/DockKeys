import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let state = AppState()
    private var statusItem: NSStatusItem!
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "")
            .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = DockIcon.image()
        statusItem.button?.image?.isTemplate = true
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        state.onChange = { [weak self] in self?.updateStatus() }
        state.start()
        updateStatus()
        if !UserDefaults.standard.bool(forKey: "hasLaunched") || CommandLine.arguments.contains("--settings") {
            showSettings()
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
    }

    func applicationWillTerminate(_ notification: Notification) { state.stop() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }
    func applicationDidBecomeActive(_ notification: Notification) { state.refreshLoginStatus() }

    func updateStatus() {
        statusItem?.button?.appearsDisabled = state.paused
        statusItem?.button?.toolTip = state.paused ? "DockKeys · 已暂停" : "DockKeys · \(state.apps.count - state.failures.count) 个快捷键已启用"
    }

    func menuWillOpen(_ menu: NSMenu) {
        state.refresh()
        menu.removeAllItems()
        add("DockKeys 设置…", action: #selector(showSettings), to: menu)
        add(state.paused ? "恢复快捷键" : "暂停快捷键", action: #selector(togglePause), to: menu)
        menu.addItem(.separator())
        for (slot, app) in state.apps.enumerated() {
            let item = NSMenuItem(title: "\(state.shortcut(for: slot))    \(app.name)\(state.failures[slot] == nil ? "" : "  ⚠︎")",
                                  action: #selector(openMappedApp(_:)), keyEquivalent: "")
            item.target = self
            item.tag = slot
            item.isEnabled = !state.paused
            let image = state.icon(for: app).copy() as! NSImage
            image.size = NSSize(width: 18, height: 18)
            item.image = image
            menu.addItem(item)
        }
        menu.addItem(.separator())
        add("重新检查快捷键", action: #selector(retry), to: menu)
        add("退出 DockKeys", action: #selector(quit), to: menu)
    }

    private func add(_ title: String, action: Selector, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        menu.addItem(item)
    }

    @objc func showSettings() {
        if window == nil {
            let content = NSHostingView(rootView: SettingsView(state: state))
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 790, height: 625),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "DockKeys"
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.contentView = content
            window.center()
            self.window = window
        }
        state.refresh()
        state.refreshLoginStatus()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc private func openMappedApp(_ sender: NSMenuItem) { state.activate(slot: sender.tag) }
    @objc private func togglePause() { state.paused.toggle() }
    @objc private func retry() { state.retryShortcuts() }
    @objc private func quit() { NSApp.terminate(nil) }
}

@main struct DockKeysMain {
    static func main() {
        if CommandLine.arguments.contains("--diagnose") {
            let apps = DockReader.read(includeFinder: false)
            for (slot, app) in apps.enumerated() { print("\(DockModel.digits[slot])\t\(app.name)\t\(app.url.path)") }
            return
        }
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        application.delegate = delegate
        withExtendedLifetime(delegate) { application.run() }
    }
}

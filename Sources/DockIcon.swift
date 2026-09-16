import AppKit

enum DockIcon {
    // App tiles resting on a Dock rail. A template image adapts to the menu bar
    // appearance, including dark mode and the selected menu item highlight.
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            NSColor.black.setFill()
            for rect in [
                NSRect(x: 1, y: 6, width: 4, height: 4),
                NSRect(x: 7, y: 9, width: 4, height: 4),
                NSRect(x: 13, y: 6, width: 4, height: 4)
            ] {
                NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
            }
            NSBezierPath(roundedRect: NSRect(x: 1, y: 2.5, width: 16, height: 1.5),
                         xRadius: 0.75, yRadius: 0.75).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "DockKeys · Dock 应用快捷切换"
        return image
    }
}

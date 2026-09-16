import AppKit

enum DockIcon {
    // App tiles resting on a Dock rail. A template image adapts to the menu bar
    // appearance, including dark mode and the selected menu item highlight.
    static func image() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            drawMark(in: NSRect(x: 0, y: 0, width: 18, height: 18), color: .black)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "DockKeys · Dock 应用快捷切换"
        return image
    }

    static func appImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 128, height: 128), flipped: false) { rect in
            drawAppIcon(in: rect)
            return true
        }
        image.accessibilityDescription = "DockKeys"
        return image
    }

    // The app bundle, settings page and README all use this renderer.
    static func drawAppIcon(in rect: NSRect) {
        let tile = rect.insetBy(dx: rect.width * 0.078125, dy: rect.height * 0.078125)
        let path = NSBezierPath(roundedRect: tile, xRadius: rect.width * 0.1953125,
                               yRadius: rect.height * 0.1953125)
        NSGradient(starting: NSColor(srgbRed: 0.38, green: 0.48, blue: 1, alpha: 1),
                   ending: NSColor(srgbRed: 0.20, green: 0.24, blue: 0.67, alpha: 1))!
            .draw(in: path, angle: -70)
        drawMark(in: rect.insetBy(dx: rect.width * 0.21, dy: rect.height * 0.21), color: .white)
    }

    private static func drawMark(in rect: NSRect, color: NSColor) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let transform = NSAffineTransform()
        transform.translateX(by: rect.minX, yBy: rect.minY)
        transform.scaleX(by: rect.width / 18, yBy: rect.height / 18)
        transform.concat()
        color.setFill()
        for tile in [
            NSRect(x: 1, y: 6, width: 4, height: 4),
            NSRect(x: 7, y: 9, width: 4, height: 4),
            NSRect(x: 13, y: 6, width: 4, height: 4)
        ] {
            NSBezierPath(roundedRect: tile, xRadius: 1, yRadius: 1).fill()
        }
        NSBezierPath(roundedRect: NSRect(x: 1, y: 2.5, width: 16, height: 1.5),
                     xRadius: 0.75, yRadius: 0.75).fill()
    }
}

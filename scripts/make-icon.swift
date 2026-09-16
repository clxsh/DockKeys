import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
func drawIcon(size: Int) -> Data {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: size * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(size) / 1024
    let transform = AffineTransform(scale: scale)
    (transform as NSAffineTransform).concat()
    let rect = NSRect(x: 80, y: 80, width: 864, height: 864)
    let path = NSBezierPath(roundedRect: rect, xRadius: 200, yRadius: 200)
    NSGradient(starting: NSColor(srgbRed: 0.38, green: 0.48, blue: 1, alpha: 1),
               ending: NSColor(srgbRed: 0.20, green: 0.24, blue: 0.67, alpha: 1))!.draw(in: path, angle: -70)
    NSColor.white.withAlphaComponent(0.15).setFill()
    NSBezierPath(roundedRect: NSRect(x: 196, y: 242, width: 632, height: 154), xRadius: 52, yRadius: 52).fill()
    for (index, opacity) in [1.0, 0.48, 0.30].enumerated() {
        NSColor.white.withAlphaComponent(opacity).setFill()
        NSBezierPath(roundedRect: NSRect(x: 270 + index * 184, y: 277, width: 86, height: 86), xRadius: 24, yRadius: 24).fill()
    }
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let font = NSFont.systemFont(ofSize: 360, weight: .bold)
    ("1" as NSString).draw(in: NSRect(x: 196, y: 362, width: 632, height: 440), withAttributes: [
        .font: font, .foregroundColor: NSColor.white, .paragraphStyle: paragraph
    ])
    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])!
}
for points in [16, 32, 128, 256, 512] {
    for factor in [1, 2] {
        let suffix = factor == 1 ? "" : "@2x"
        try drawIcon(size: points * factor).write(to: output.appendingPathComponent("icon_\(points)x\(points)\(suffix).png"))
    }
}

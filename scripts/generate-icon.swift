import AppKit
let size = NSSize(width: 1024, height: 1024)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(srgbRed: 0.08, green: 0.36, blue: 0.31, alpha: 1).setFill()
NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
let book = NSImage(systemSymbolName: "book.closed.fill", accessibilityDescription: nil)!
let config = NSImage.SymbolConfiguration(pointSize: 580, weight: .regular).applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
book.withSymbolConfiguration(config)!.draw(in: NSRect(x: 232, y: 222, width: 560, height: 600))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "FinanceBuddy/Assets.xcassets/AppIcon.appiconset/AppIcon.png"))

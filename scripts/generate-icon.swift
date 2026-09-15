import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Run from the repository root: swift scripts/generate-icon.swift
// Keep the supplied artwork intact; Xcode generates device sizes and iOS masks corners.
let sourceURL = URL(fileURLWithPath: "docs/branding/app-icon-source.webp")
let outputURL = URL(fileURLWithPath: "FinanceBuddy/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      image.width == image.height else {
    fatalError("App icon source must be a readable square image: \(sourceURL.path)")
}

let size = 1024
let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                        bytesPerRow: 0, space: colorSpace,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
guard let icon = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not create app icon PNG")
}
CGImageDestinationAddImage(destination, icon, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("Could not save app icon PNG")
}
print("Generated opaque 1024 × 1024 sRGB icon at \(outputURL.path)")

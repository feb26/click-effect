#!/usr/bin/env swift
//
// Generate Resources/AppIcon.iconset/ from an SF Symbol.
//
// Usage: swift Tools/generate-icon.swift
//
// The script produces PNGs at the sizes required by iconutil. Invoked from
// build-app.sh before bundle assembly.

import AppKit
import CoreGraphics

let symbolName = "cursorarrow.rays"
let backgroundColor = NSColor(calibratedRed: 0.05, green: 0.55, blue: 0.75, alpha: 1.0) // deep cyan
let foregroundColor = NSColor.white
let cornerRadiusRatio: CGFloat = 0.22 // macOS Big Sur+ icon corner radius

// (file name, pixel size)
let entries: [(String, Int)] = [
    ("icon_16x16.png",       16),
    ("icon_16x16@2x.png",    32),
    ("icon_32x32.png",       32),
    ("icon_32x32@2x.png",    64),
    ("icon_128x128.png",    128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png",    256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png",    512),
    ("icon_512x512@2x.png", 1024),
]

let outputDir = "Resources/AppIcon.iconset"
try? FileManager.default.createDirectory(
    atPath: outputDir, withIntermediateDirectories: true
)

func renderIcon(size: Int) -> Data? {
    let pixelSize = CGFloat(size)
    let rect = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)

    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    // Squircle-ish rounded rect background.
    let radius = pixelSize * cornerRadiusRatio
    let path = CGPath(
        roundedRect: rect,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )
    context.addPath(path)
    context.setFillColor(backgroundColor.cgColor)
    context.fillPath()

    // Foreground symbol, scaled to ~62% of icon area.
    let glyphSize = pixelSize * 0.62
    let config = NSImage.SymbolConfiguration(pointSize: glyphSize, weight: .semibold)
    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
        .withSymbolConfiguration(config) else {
        fputs("error: SF Symbol '\(symbolName)' not available\n", stderr)
        return nil
    }

    // Render the symbol to a CGImage in foregroundColor.
    let tinted = NSImage(size: symbol.size, flipped: false) { bounds in
        foregroundColor.set()
        bounds.fill()
        symbol.draw(
            in: bounds,
            from: .zero,
            operation: .destinationIn,
            fraction: 1.0
        )
        return true
    }

    var imageRect = CGRect(
        x: (pixelSize - tinted.size.width) / 2,
        y: (pixelSize - tinted.size.height) / 2,
        width: tinted.size.width,
        height: tinted.size.height
    )
    guard let cgImage = tinted.cgImage(
        forProposedRect: &imageRect, context: nil, hints: nil
    ) else { return nil }

    context.draw(cgImage, in: imageRect)

    guard let cgResult = context.makeImage() else { return nil }
    let nsImage = NSImage(cgImage: cgResult, size: rect.size)
    guard let tiff = nsImage.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        return nil
    }
    return png
}

for (name, size) in entries {
    guard let data = renderIcon(size: size) else {
        fputs("error: failed to render \(name)\n", stderr)
        exit(1)
    }
    let path = "\(outputDir)/\(name)"
    try data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}

print("done")

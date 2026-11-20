// Robey Voice original artwork. Copyright (C) 2026 Jason Robey.
// SPDX-License-Identifier: GPL-3.0-only
// Run from the repository root: swift branding/GenerateBrand.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assets = root.appendingPathComponent("VoiceInk/Assets.xcassets")
let preview = root.appendingPathComponent(".review-build/branding")
try FileManager.default.createDirectory(at: preview, withIntermediateDirectories: true)

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
            green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: 1)
}

func waveform(in rect: NSRect, ink: NSColor) {
    ink.setFill()
    let heights: [CGFloat] = [190, 350, 510, 350, 190]
    for (index, height) in heights.enumerated() {
        let bar = NSRect(x: 250 + CGFloat(index) * 112, y: (1024 - height) / 2,
                         width: 76, height: height)
        let transformed = NSRect(x: rect.minX + bar.minX * rect.width / 1024,
                                 y: rect.minY + bar.minY * rect.height / 1024,
                                 width: bar.width * rect.width / 1024,
                                 height: bar.height * rect.height / 1024)
        NSBezierPath(roundedRect: transformed, xRadius: transformed.width / 2,
                     yRadius: transformed.width / 2).fill()
    }
}

func icon(in rect: NSRect) {
    NSGraphicsContext.saveGraphicsState()
    let scale = rect.width / 1024
    let tile = rect.insetBy(dx: 58 * scale, dy: 58 * scale)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 202 * scale, yRadius: 202 * scale)
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = 18 * scale
    shadow.shadowOffset = NSSize(width: 0, height: -8 * scale)
    shadow.set()
    color(0x102F3A).setFill()
    shape.fill()
    NSShadow().set()
    NSGradient(starting: color(0x173E48), ending: color(0x091F2A))!.draw(in: shape, angle: -90)
    color(0x90EFE1).withAlphaComponent(0.18).setStroke()
    shape.lineWidth = max(1, 2 * scale)
    shape.stroke()
    waveform(in: rect, ink: color(0x6DE7D5))
    NSGraphicsContext.restoreGraphicsState()
}

func bitmap(width: Int, height: Int, drawing: (NSRect) -> Void) -> NSBitmapImageRep {
    let result = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0,
                                  bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: result)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high
    drawing(NSRect(x: 0, y: 0, width: width, height: height))
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return result
}

func save(_ bitmap: NSBitmapImageRep, to path: URL) throws {
    try bitmap.representation(using: .png, properties: [:])!.write(to: path)
}

for size in [16, 32, 64, 128, 256, 512, 1024] {
    try save(bitmap(width: size, height: size, drawing: icon),
             to: assets.appendingPathComponent("AppIcon.appiconset/\(size)-mac.png"))
}
let menu = bitmap(width: 44, height: 44) { waveform(in: $0.insetBy(dx: -9, dy: -9), ink: .black) }
try save(menu, to: assets.appendingPathComponent("menuBarIcon.imageset/menuBarIcon.png"))
try save(bitmap(width: 1024, height: 1024, drawing: icon), to: preview.appendingPathComponent("app-icon.png"))
let sheet = bitmap(width: 1280, height: 800) { canvas in
    color(0xF3F7F6).setFill(); canvas.fill()
    color(0x111E26).setFill(); NSRect(x: 0, y: 0, width: 1280, height: 350).fill()
    icon(in: NSRect(x: 45, y: 500, width: 220, height: 220))
    let title: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 44, weight: .semibold), .foregroundColor: color(0x102F3A)]
    ("Robey Voice" as NSString).draw(at: NSPoint(x: 395, y: 625), withAttributes: title)
    ("Original waveform · native macOS · teal + ink" as NSString).draw(at: NSPoint(x: 398, y: 580), withAttributes: [.font: NSFont.systemFont(ofSize: 22), .foregroundColor: color(0x355962)])
    for (index, size) in [16, 32, 64, 128, 256].enumerated() {
        let x = CGFloat(60 + index * 215)
        for y in [CGFloat(95), CGFloat(405)] {
            icon(in: NSRect(x: x, y: y, width: CGFloat(size), height: CGFloat(size)))
        }
        ("\(size) px" as NSString).draw(at: NSPoint(x: x, y: 45), withAttributes: [.font: NSFont.monospacedSystemFont(ofSize: 16, weight: .regular), .foregroundColor: color(0xD2E8E5)])
    }
}
try save(sheet, to: preview.appendingPathComponent("brand-review.png"))
print("Generated seven app icon sizes, template menu mark, and .review-build/branding previews.")

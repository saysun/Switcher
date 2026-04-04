#!/usr/bin/env swift
import AppKit
import Foundation

let out = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Resources/dmg-background.png"

let w = 660
let h = 440

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: w,
    pixelsHigh: h,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 4 * w,
    bitsPerPixel: 32
) else {
    fputs("bitmap rep failed\n", stderr)
    exit(1)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
defer { NSGraphicsContext.restoreGraphicsState() }

let rect = NSRect(x: 0, y: 0, width: w, height: h)
NSColor(calibratedWhite: 0.93, alpha: 1).setFill()
NSBezierPath(rect: rect).fill()

// Icon positions from mkdmg.sh: app at x=175, Applications at x=430, both y=188 (from top).
// Icon size 112 → right edge of app icon ~231, left edge of Applications ~374.
// Gap center x = (231+374)/2 ≈ 302;  y in bottom-up coords = 440-188 = 252.
let cx: CGFloat = 302
let cy: CGFloat = 252
let chevronH: CGFloat = 18   // half-height
let chevronW: CGFloat = 11   // half-width (tip to midpoint)

let chevron = NSBezierPath()
chevron.move(to: NSPoint(x: cx - chevronW, y: cy + chevronH))
chevron.line(to: NSPoint(x: cx + chevronW, y: cy))
chevron.line(to: NSPoint(x: cx - chevronW, y: cy - chevronH))
chevron.lineWidth = 2.5
chevron.lineCapStyle = .round
chevron.lineJoinStyle = .round
NSColor(calibratedWhite: 0.58, alpha: 1).setStroke()
chevron.stroke()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fputs("Failed to encode PNG\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: out))
print(out)

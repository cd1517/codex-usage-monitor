#!/usr/bin/env swift

import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate-icon.swift OUTPUT_PNG\n", stderr)
    exit(2)
}

let canvasSize = NSSize(width: 1024, height: 1024)
let image = NSImage(size: canvasSize)
image.lockFocus()

NSColor.clear.setFill()
NSRect(origin: .zero, size: canvasSize).fill()

let backgroundRect = NSRect(x: 64, y: 64, width: 896, height: 896)
let backgroundPath = NSBezierPath(
    roundedRect: backgroundRect,
    xRadius: 205,
    yRadius: 205
)

NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
shadow.shadowBlurRadius = 38
shadow.shadowOffset = NSSize(width: 0, height: -18)
shadow.set()
NSColor(calibratedWhite: 0.965, alpha: 1).setFill()
backgroundPath.fill()
NSGraphicsContext.restoreGraphicsState()

NSColor.white.withAlphaComponent(0.72).setStroke()
backgroundPath.lineWidth = 5
backgroundPath.stroke()

let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 520, weight: .bold)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.systemBlue]))
guard let symbol = NSImage(
    systemSymbolName: "bolt.fill",
    accessibilityDescription: "Codex 用量"
)?.withSymbolConfiguration(symbolConfiguration) else {
    fputs("failed to create bolt.fill symbol\n", stderr)
    exit(1)
}

let targetHeight: CGFloat = 570
let targetWidth = targetHeight * symbol.size.width / symbol.size.height
let symbolRect = NSRect(
    x: (canvasSize.width - targetWidth) / 2,
    y: (canvasSize.height - targetHeight) / 2 + 8,
    width: targetWidth,
    height: targetHeight
)
symbol.draw(in: symbolRect)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("failed to encode icon PNG\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: export_resolved_icon <application> <output.png>")
}

let source = NSWorkspace.shared.icon(forFile: CommandLine.arguments[1])
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: 512,
    pixelsHigh: 512,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("could not create icon rendering context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
source.draw(
    in: NSRect(x: 0, y: 0, width: 512, height: 512),
    from: NSRect(origin: .zero, size: source.size),
    operation: .sourceOver,
    fraction: 1.0
)
context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("could not render resolved application icon")
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]))
print("Exported resolved icon: \(CommandLine.arguments[2])")

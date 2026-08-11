import CoreGraphics
import Foundation
import ImageIO

guard CommandLine.arguments.count == 3 else {
    fatalError("usage: convert_png_rgba <input.png> <output.png>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2]) as CFURL

guard let source = CGImageSourceCreateWithURL(inputURL, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let context = CGContext(
          data: nil,
          width: image.width,
          height: image.height,
          bitsPerComponent: 8,
          bytesPerRow: image.width * 4,
          space: CGColorSpaceCreateDeviceRGB(),
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      ) else {
    fatalError("could not decode input PNG")
}

context.interpolationQuality = .high
context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

guard let converted = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(outputURL, "public.png" as CFString, 1, nil) else {
    fatalError("could not create output PNG")
}

CGImageDestinationAddImage(destination, converted, nil)
guard CGImageDestinationFinalize(destination) else {
    fatalError("could not write output PNG")
}

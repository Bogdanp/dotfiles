// pad-icon: rebuild an .iconset from an .icns, scaling the artwork so its
// opaque bounding box spans TARGET pixels of a 1024-pixel canvas, centered.
// Used to generate Emacs-padded.icns; see ../../../README.md.
//
//   usage: pad-icon IN.icns OUT.iconset TARGET    (e.g. 824)

import AppKit
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("pad-icon: \(message)\n".utf8))
    exit(1)
}

/// The largest bitmap representation stored in an image file.
func largestBitmap(at path: String) -> CGImage? {
    NSImage(contentsOfFile: path)?.representations
        .compactMap { $0 as? NSBitmapImageRep }
        .max { $0.pixelsWide < $1.pixelsWide }?
        .cgImage
}

func rgbaContext(width: Int, height: Int) -> CGContext {
    guard let context = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { fail("cannot create a \(width)x\(height) bitmap") }
    context.interpolationQuality = .high
    return context
}

/// Bounding box of the pixels with alpha above a small threshold, in
/// Core Graphics coordinates (origin at the bottom-left).
func opaqueBounds(of image: CGImage) -> CGRect {
    let width = image.width, height = image.height
    let context = rgbaContext(width: width, height: height)
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let data = context.data else { fail("cannot read back bitmap") }
    let alpha = data.assumingMemoryBound(to: UInt8.self)

    // The bitmap is stored top-down, so `row` 0 is the top of the image.
    var minX = width, maxX = -1, minRow = height, maxRow = -1
    for row in 0..<height {
        for x in 0..<width where alpha[(row * width + x) * 4 + 3] > 8 {
            minX = min(minX, x); maxX = max(maxX, x)
            minRow = min(minRow, row); maxRow = max(maxRow, row)
        }
    }
    guard maxX >= 0 else { fail("image is fully transparent") }
    return CGRect(x: minX, y: height - maxRow - 1,
                  width: maxX - minX + 1, height: maxRow - minRow + 1)
}

/// `image` on a square canvas of `size` pixels, with `bounds` scaled to
/// `target` pixels of a 1024-pixel canvas and centered.
func render(_ image: CGImage, bounds: CGRect, target: CGFloat, size: Int) -> CGImage {
    let scale = CGFloat(size) / 1024 * target / max(bounds.width, bounds.height)
    let canvas = rgbaContext(width: size, height: size)
    let origin = CGPoint(x: CGFloat(size) / 2 - bounds.midX * scale,
                         y: CGFloat(size) / 2 - bounds.midY * scale)
    let extent = CGSize(width: CGFloat(image.width) * scale,
                        height: CGFloat(image.height) * scale)
    canvas.draw(image, in: CGRect(origin: origin, size: extent))
    guard let result = canvas.makeImage() else { fail("cannot render \(size)px image") }
    return result
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)
    else { fail("cannot create \(path)") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fail("cannot write \(path)") }
}

/// The representations `iconutil` expects in an .iconset.
let iconsetEntries: [(name: String, pixels: Int)] = [
    ("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64),
    ("128x128", 128), ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512),
    ("512x512", 512), ("512x512@2x", 1024),
]

let arguments = CommandLine.arguments
guard arguments.count == 4, let target = Double(arguments[3]), target > 0
else { fail("usage: pad-icon IN.icns OUT.iconset TARGET") }
let (input, output) = (arguments[1], arguments[2])

guard let image = largestBitmap(at: input) else { fail("cannot read \(input)") }
let bounds = opaqueBounds(of: image)
do {
    try FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)
} catch {
    fail("cannot create \(output): \(error.localizedDescription)")
}
for entry in iconsetEntries {
    let padded = render(image, bounds: bounds, target: CGFloat(target), size: entry.pixels)
    writePNG(padded, to: "\(output)/icon_\(entry.name).png")
}
print("\(image.width)x\(image.height) source, artwork \(Int(bounds.width))x\(Int(bounds.height)), "
      + "scaled to \(Int(target))/1024 in \(output)")

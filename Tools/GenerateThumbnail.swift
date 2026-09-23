import AppKit
import Foundation

func plasmaColor(x: Double, y: Double, width: Double, height: Double, time: Double) -> NSColor {
    var ux = (x / width - 0.5) * 8.0
    var uy = (y / width - 0.5) * 8.0
    var i0 = 1.0
    var i1 = 1.0
    var i2 = 1.0
    var i4 = 0.0

    for _ in 0..<7 {
        var rx = cos(uy * i0 - i4 + time / i1) / i2
        var ry = sin(ux * i0 - i4 + time / i1) / i2
        let oldX = rx
        rx += -ry * 0.3
        ry += oldX * 0.3
        ux += rx
        uy += ry
        i0 *= 1.93
        i1 *= 1.15
        i2 *= 1.7
        i4 += 0.05 + 0.1 * time * i1
    }

    let red = sin(ux - time) * 0.5 + 0.5
    let blue = sin(uy + time) * 0.5 + 0.5
    let green = sin((ux + uy + sin(time * 0.5)) * 0.5) * 0.5 + 0.5
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
}

func writeThumbnail(width: Int, height: Int, path: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "Thumbnail", code: 1)
    }

    for y in 0..<height {
        for x in 0..<width {
            bitmap.setColor(
                plasmaColor(
                    x: Double(x) + 0.5,
                    y: Double(y) + 0.5,
                    width: Double(width),
                    height: Double(height),
                    time: 1.75
                ),
                atX: x,
                y: y
            )
        }
    }

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Thumbnail", code: 2)
    }
    try png.write(to: URL(fileURLWithPath: path))
}

guard CommandLine.arguments.count == 2 else {
    fputs("usage: GenerateThumbnail.swift OUTPUT_DIRECTORY\n", stderr)
    exit(2)
}

let outputDirectory = CommandLine.arguments[1]
try FileManager.default.createDirectory(
    atPath: outputDirectory,
    withIntermediateDirectories: true
)
try writeThumbnail(width: 90, height: 58, path: outputDirectory + "/thumbnail.png")
try writeThumbnail(width: 180, height: 116, path: outputDirectory + "/thumbnail@2x.png")

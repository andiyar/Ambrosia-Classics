import BubbleTroubleRender
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Test-only: write a buffer as PNG (the golden frames go to the scratch dir for eyes, never into git).
enum PNGWriter {
    static func write(_ image: RGBAImage, to url: URL) -> Bool {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        for (i, p) in image.pixels.enumerated() {
            bytes[4 * i] = UInt8(p >> 16 & 0xFF); bytes[4 * i + 1] = UInt8(p >> 8 & 0xFF)
            bytes[4 * i + 2] = UInt8(p & 0xFF); bytes[4 * i + 3] = 0xFF
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let cg = CGImage(width: image.width, height: image.height, bitsPerComponent: 8, bitsPerPixel: 32,
                               bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                               provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return false }
        CGImageDestinationAddImage(dest, cg, nil)
        return CGImageDestinationFinalize(dest)
    }
}

import Foundation
import FerazelCore
import FerazelRender
#if canImport(ImageIO)
import CoreGraphics
import ImageIO
#endif

// ferazel-census — thin main over `FerazelRender.FerazelCensus` (plan docs/plans/2026-10-06-ferazel-phase1.md, C6).
//
//     ferazel-census <Resources/Ferazel dir> [--render <out dir>]
//
// Prints the census Markdown on stdout and exits 0 (all decoded) / 1 (any failure, each named) / 2 (bad arguments).
// `--render` writes `level1-start.png`, `pict-1020.png`, `pict-207.png` through ImageIO — the only Apple framework
// in Ferazel/Core, census-only, behind `#if canImport(ImageIO)` (plan invariant 1; G7 excludes this folder).

#if canImport(ImageIO)
enum RenderError: Error { case pngWriteFailed(String) }

/// One indexed frame → an opaque 8-bit RGBA PNG through its CLUT (each 16-bit channel's high byte).
func writePNG(_ frame: FerazelCensus.Frame, to url: URL) throws {
    var rgba = [UInt8](repeating: 255, count: frame.width * frame.height * 4)
    for (i, v) in frame.indices.enumerated() {
        let e = frame.clut.entries[Int(v)]
        rgba[4 * i] = UInt8(e.red >> 8); rgba[4 * i + 1] = UInt8(e.green >> 8); rgba[4 * i + 2] = UInt8(e.blue >> 8)
    }
    guard let provider = CGDataProvider(data: Data(rgba) as CFData),
          let image = CGImage(width: frame.width, height: frame.height, bitsPerComponent: 8, bitsPerPixel: 32,
                              bytesPerRow: frame.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
          let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        throw RenderError.pngWriteFailed(url.lastPathComponent)
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { throw RenderError.pngWriteFailed(url.lastPathComponent) }
}
#endif

var isDirectory: ObjCBool = false
guard let arguments = FerazelCensus.Arguments(parsing: Array(CommandLine.arguments.dropFirst())),
      FileManager.default.fileExists(atPath: arguments.dataDirectory, isDirectory: &isDirectory), isDirectory.boolValue else {
    FileHandle.standardError.write(Data(FerazelCensus.usage.utf8))
    exit(2)
}
let dataDirectory = URL(fileURLWithPath: arguments.dataDirectory, isDirectory: true)
let census = FerazelCensus.render(dataDirectory: dataDirectory)
FileHandle.standardOutput.write(Data(census.stdout.utf8))
var failed = census.failures > 0
if let renderDirectory = arguments.renderDirectory {
    #if canImport(ImageIO)
    do {
        let out = URL(fileURLWithPath: renderDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        for frame in try FerazelCensus.renderFrames(dataDirectory: dataDirectory) {
            try writePNG(frame, to: out.appendingPathComponent(frame.name))
        }
    } catch {
        FileHandle.standardError.write(Data("ferazel-census: --render failed: \(error)\n".utf8))
        failed = true
    }
    #else
    FileHandle.standardError.write(Data("ferazel-census: --render needs ImageIO (macOS)\n".utf8))
    failed = true
    #endif
}
exit(failed ? 1 : 0)

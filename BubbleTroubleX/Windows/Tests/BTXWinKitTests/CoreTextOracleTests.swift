#if canImport(CoreText)
@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import CoreGraphics
import CoreText
import Foundation
import XCTest

/// The Mac app's text path, re-derived here as the oracle (BubbleTroubleX/App/CoreTextRasterizer.swift, read-only to
/// this package): a CTLine drawn antialiased, unsmoothed, into an alpha-only mask clipped to `pad` columns either
/// side and ⌈ascent⌉ + 1 / ⌈descent⌉ + 1 rows, blended toward `rgb`, touched pixels opaque. "System-Bold" (the chrome's
/// face, not the compositor's) resolves as the baker does.
final class CoreTextOracle: TextRasterizer {
    private func ctFont(_ name: String, size: Int) -> CTFont {
        let s = CGFloat(size)
        switch name {
        case "System":
            return CTFontCreateUIFontForLanguage(.system, s, nil) ?? CTFontCreateWithName("Lucida Grande" as CFString, s, nil)
        case "System-Bold":
            return CTFontCreateUIFontForLanguage(.emphasizedSystem, s, nil)
                ?? CTFontCreateWithName("LucidaGrande-Bold" as CFString, s, nil)
        default:
            return CTFontCreateWithName(name as CFString, s, nil)
        }
    }

    private func line(_ s: String, font: CTFont) -> CTLine {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
        ]
        return CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attributes))
    }

    func width(_ s: String, font: String, size: Int) -> Int {
        Int(CTLineGetTypographicBounds(line(s, font: ctFont(font, size: size)), nil, nil, nil).rounded())
    }

    func rasterize(_ s: String, font: String, size: Int, rgb: UInt32, into image: inout RGBAImage,
                   at: (h: Int, v: Int), centredIn: QDRect?) {
        guard !s.isEmpty else { return }
        let l = line(s, font: ctFont(font, size: size))
        var ascent: CGFloat = 0, descent: CGFloat = 0
        let advance = Int(CTLineGetTypographicBounds(l, &ascent, &descent, nil).rounded())
        var h = at.h
        if let r = centredIn { h = Int(r.left) + (Int(r.right) - Int(r.left) - advance) / 2 }
        let pad = 2
        let above = Int(ascent.rounded(.up)) + 1, below = Int(descent.rounded(.up)) + 1
        let w = advance + 2 * pad, ht = above + below
        guard w > 0, ht > 0 else { return }
        var coverage = [UInt8](repeating: 0, count: w * ht)
        coverage.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: ht, bitsPerComponent: 8,
                                      bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { return }
            ctx.setShouldAntialias(true)
            ctx.setShouldSmoothFonts(false)
            ctx.setFillColor(CGColor(gray: 0, alpha: 1))
            ctx.textPosition = CGPoint(x: CGFloat(pad), y: CGFloat(below))
            CTLineDraw(l, ctx)
        }
        let red = (rgb >> 16) & 0xFF, green = (rgb >> 8) & 0xFF, blue = rgb & 0xFF
        for r in 0..<ht {
            let y = at.v - above + r
            guard y >= 0, y < image.height else { continue }
            for c in 0..<w {
                let a = UInt32(coverage[r * w + c])
                guard a != 0 else { continue }
                let x = h - pad + c
                guard x >= 0, x < image.width else { continue }
                let dst = image[x, y]
                func mix(_ src: UInt32, _ shift: UInt32) -> UInt32 {
                    let d = (dst >> shift) & 0xFF
                    return ((src * a + d * (255 - a) + 127) / 255) << shift
                }
                image[x, y] = 0xFF00_0000 | mix(red, 16) | mix(green, 8) | mix(blue, 0)
            }
        }
    }
}

final class CoreTextOracleTests: XCTestCase {
    static let faces: [(String, Int)] = [("Geneva", 9), ("Geneva", 10), ("System", 12), ("System-Bold", 12)]
    /// The info box's and the FPS readout's strings, every digit, a kerned pair, and the printable ASCII range.
    static let strings: [String] = {
        var s = ["Level 12", "Score: 123450", "FPS: ", "30", "FPS: 30", "Lives: 3", "Time: 59", "AV", "Wave", "To",
                 "0123456789", "Bubble Trouble X", "Paused — press any key", "Café crème, naïve façade ©®™ ß",
                 "12:30", "Difficulty: profile flip"]
        s += (0...9).map(String.init)
        s.append(String((0x20...0x7E).map { Character(Unicode.Scalar(UInt8($0))) }))
        return s
    }()

    let oracle = CoreTextOracle()
    var baked: BitmapFontRasterizer!

    override func setUpWithError() throws {
        baked = try BitmapFontRasterizer(fontsDirectory: fontsDirectory)
    }

    func testWidthsMatchCoreTextWithinOnePixel() {
        for (font, size) in Self.faces {
            for s in Self.strings {
                let a = baked.width(s, font: font, size: size), b = oracle.width(s, font: font, size: size)
                XCTAssertLessThanOrEqual(abs(a - b), 1, "\(font) \(size) \"\(s)\": baked \(a), CoreText \(b)")
            }
        }
    }

    func testUnknownCharacterAdvancesAsQuestionMark() {
        for (font, size) in Self.faces {
            XCTAssertEqual(baked.width("A中B", font: font, size: size), baked.width("A?B", font: font, size: size))
        }
    }

    /// Every MacRoman printable character alone renders exactly as CoreText draws it.
    func testEverySingleCharacterMatches() {
        for (font, size) in Self.faces {
            var mismatched: [String] = []
            for byte in (0x20...0xFF) where byte != 0x7F {
                let s = String(bytes: [UInt8(byte)], encoding: .macOSRoman)!
                let (d, _) = compare(s, font: font, size: size, at: (10, 20))
                if d != 0 { mismatched.append(s) }
                XCTAssertEqual(baked.width(s, font: font, size: size), oracle.width(s, font: font, size: size), s)
            }
            XCTAssertEqual(mismatched, [], "\(font) \(size)")
        }
    }

    /// Whole strings: pixels that differ from the CoreText render, as a share of pixels either touched, ≤ 2 % per face.
    func testRenderedPixelsMatchCoreTextPerFace() {
        var report: [String] = []
        for (font, size) in Self.faces {
            var differing = 0, touched = 0
            for s in Self.strings {
                for at in [(h: 10, v: 20), (h: 13, v: 17)] {
                    let (d, t) = compare(s, font: font, size: size, at: at)
                    differing += d; touched += t
                }
            }
            let share = 100 * Double(differing) / Double(max(1, touched))
            report.append("\(font) \(size): \(differing)/\(touched) = \(String(format: "%.3f", share)) %")
            XCTAssertLessThanOrEqual(share, 2, "\(font) \(size)")
        }
        print("W2 pixel difference vs CoreText — " + report.joined(separator: "; "))
    }

    /// Clipping at the image edges and centring follow the oracle exactly.
    func testClippingAndCentringMatch() {
        for (font, size) in Self.faces {
            for at in [(h: -4, v: 5), (h: 150, v: 33), (h: 60, v: 2)] {
                var a = RGBAImage(width: 160, height: 34, fill: 0xFF20_4060), b = a
                baked.rasterize("Score: 123450", font: font, size: size, rgb: 0xFFFF00, into: &a, at: at, centredIn: nil)
                oracle.rasterize("Score: 123450", font: font, size: size, rgb: 0xFFFF00, into: &b, at: at, centredIn: nil)
                XCTAssertEqual(a, b, "\(font) \(size) at \(at)")
            }
            var a = RGBAImage(width: 160, height: 34), b = a
            let r = QDRect(top: 0, left: 7, bottom: 30, right: 151)
            baked.rasterize("Level 12", font: font, size: size, rgb: 0xFFFFFF, into: &a, at: (0, 20), centredIn: r)
            oracle.rasterize("Level 12", font: font, size: size, rgb: 0xFFFFFF, into: &b, at: (0, 20), centredIn: r)
            XCTAssertEqual(a, b, "\(font) \(size) centred")
        }
    }

    func testOutputIsOpaqueOverATranslucentBuffer() {
        var img = RGBAImage(width: 200, height: 30, fill: 0x0000_0000)
        baked.rasterize("FPS: 30", font: "System", size: 12, rgb: 0xFF0000, into: &img, at: (5, 20), centredIn: nil)
        let touched = img.pixels.filter { $0 != 0 }
        XCTAssertFalse(touched.isEmpty)
        XCTAssertTrue(touched.allSatisfy { $0 >> 24 == 0xFF })
    }

    /// (differing pixels, pixels touched by either) for one string drawn on a mid-grey buffer.
    private func compare(_ s: String, font: String, size: Int, at: (h: Int, v: Int)) -> (Int, Int) {
        let background: UInt32 = 0xFF40_4040
        let width = max(40, oracle.width(s, font: font, size: size) + 40)
        var a = RGBAImage(width: width, height: 40, fill: background), b = a
        baked.rasterize(s, font: font, size: size, rgb: 0xFFFFFF, into: &a, at: at, centredIn: nil)
        oracle.rasterize(s, font: font, size: size, rgb: 0xFFFFFF, into: &b, at: at, centredIn: nil)
        var differing = 0, touched = 0
        for i in a.pixels.indices where a.pixels[i] != background || b.pixels[i] != background {
            touched += 1
            if a.pixels[i] != b.pixels[i] { differing += 1 }
        }
        return (differing, touched)
    }
}
#endif

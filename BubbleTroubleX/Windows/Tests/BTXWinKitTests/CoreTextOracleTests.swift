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

/// The oracle is live CoreText on the machine running the tests, while the faces were baked on one macOS version:
/// a later macOS that changes the system font (SF revisions) or CoreGraphics' rasterizer makes these tests fail
/// until the faces are re-baked (`swift run btx-bake-font Resources/Fonts`) — a re-bake signal, not a regression (M4).
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

    /// Every character at every phase it has: each phase segment is reached by drawing the character after a
    /// one- or two-character prefix whose pen lands in that segment (M7). Segments no prefix reaches are reported.
    func testEveryCharacterAtEveryReachablePhaseMatches() {
        var report: [String] = []
        for (font, size) in Self.faces {
            let f = baked.face(font, size: size)!
            let printable = (0x20...0xFF).filter { $0 != 0x7F }.map { String(bytes: [UInt8($0)], encoding: .macOSRoman)! }
            let prefixes = printable + ["i", "l", "1", "m", "W"].flatMap { a in printable.map { a + $0 } }
            // Each prefix's pen fraction for a following character, ignoring the pair's own kerning (checked below).
            var mismatched: [String] = [], reached = 0, segments = 0
            for c in printable {
                let g = f.glyphs[c.unicodeScalars.first!.value]!
                for (k, phase) in g.phases.enumerated() {
                    segments += 1
                    let end = k + 1 < g.phases.count ? g.phases[k + 1].start : 1
                    let hit = prefixes.lazy.map { $0 + c }.first { s in
                        let l = self.baked.layout(s, in: f)
                        guard l.glyphs.count == s.unicodeScalars.count, let x = l.glyphs.last?.x else { return false }
                        let fraction = x - x.rounded(.down)
                        return fraction >= phase.start && fraction < end
                    }
                    guard let s = hit else { continue }
                    reached += 1
                    if compare(s, font: font, size: size, at: (10, 20)).0 != 0 { mismatched.append(s) }
                }
            }
            report.append("\(font) \(size): \(reached)/\(segments) segments")
            XCTAssertEqual(mismatched, [], "\(font) \(size)")
        }
        print("W2 phase coverage — " + report.joined(separator: "; "))
    }

    /// CoreGraphics snaps a pen fraction ≥ 0.999 to the next pixel's phase 0 (I1): strings whose last pen lands there
    /// (found by search; the reviewer's "M 3x", "Wijx" among them) draw as CoreText does. System 12 has none: its pens
    /// are multiples of 1/512, so the nearest below 1 is 511/512 ≈ 0.998.
    func testPenJustBelowTheNextPixelMatches() {
        let probes: [(String, Int, [String])] = [
            ("Geneva", 9, ["ABsyx", "ABysx", "ARsdx", "ARspx"]),
            ("Geneva", 10, ["FGKsx", "FGsKx", "FKsGx", "Fmstx"]),
            ("System-Bold", 12, ["EVx", "Osx", "AMRx", "ANvx", "M 3x", "Wijx"]),
        ]
        for (font, size, strings) in probes {
            let f = baked.face(font, size: size)!
            for s in strings {
                let x = baked.layout(s, in: f).glyphs.last!.x
                XCTAssertGreaterThanOrEqual(x - x.rounded(.down), 0.999, "\(font) \(size) \(s): probe pen")
                XCTAssertEqual(compare(s, font: font, size: size, at: (10, 20)).0, 0, "\(font) \(size) \(s)")
            }
        }
    }

    /// Control characters: C0 and DEL take no width and draw nothing; a tab moves to the next 28 px stop (M2).
    func testControlCharactersMatchCoreText() {
        for (font, size) in Self.faces {
            for s in ["\u{0}", "A\u{0}V", "A\u{1}V\u{7F}", "\t", "\t\t", "AB\tx", "Score:\t12", "A\nB"] {
                XCTAssertEqual(baked.width(s, font: font, size: size), oracle.width(s, font: font, size: size),
                               "\(font) \(size) \(s.debugDescription)")
                XCTAssertEqual(compare(s, font: font, size: size, at: (10, 20)).0, 0, "\(font) \(size) \(s.debugDescription)")
            }
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

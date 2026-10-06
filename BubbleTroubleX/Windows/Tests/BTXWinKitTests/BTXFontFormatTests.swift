@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

/// The committed fonts directory (BubbleTroubleX/Windows/Resources/Fonts).
let fontsDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Resources/Fonts", isDirectory: true)

/// A tiny hand-made face: 'A' (advance 6, a 2×2 block that shifts one column from phase 0.5), '?' (advance 5), ' '
/// (advance 3, blank), 'B' (advance 2.5, a mark), with A→A kerned by −1 and "BB" a ligature (advance 4, the block).
func syntheticFont() -> BTXFont {
    let block = BTXFont.Bitmap(left: 0, top: -2, width: 2, height: 2, coverage: [255, 255, 255, 255])
    let shifted = BTXFont.Bitmap(left: 1, top: -2, width: 2, height: 2, coverage: [255, 128, 255, 128])
    let mark = BTXFont.Bitmap(left: 0, top: -3, width: 1, height: 3, coverage: [255, 0, 255])
    let a = BTXFont.Glyph(advance: 6, ascent: 9, descent: 2,
                          phases: [.init(start: 0, bitmap: 0), .init(start: 0.5, bitmap: 1)])
    let q = BTXFont.Glyph(advance: 5, ascent: 9, descent: 2, phases: [.init(start: 0, bitmap: 2)])
    let sp = BTXFont.Glyph(advance: 3, ascent: 9, descent: 2, phases: [.init(start: 0, bitmap: BTXFont.blank)])
    let b = BTXFont.Glyph(advance: 2.5, ascent: 9, descent: 2, phases: [.init(start: 0, bitmap: 2)])
    let bb = BTXFont.Glyph(advance: 4, ascent: 9, descent: 2, phases: [.init(start: 0, bitmap: 0)])
    return BTXFont(name: "Test", size: 9, ascent: 8.5, descent: 1.5, bitmaps: [block, shifted, mark],
                   glyphs: [0x41: a, 0x3F: q, 0x20: sp, 0x42: b], kerning: [BTXFont.Pair(0x41, 0x41): -1],
                   ligatures: [BTXFont.Pair(0x42, 0x42): bb])
}

final class BTXFontFormatTests: XCTestCase {
    func testRoundTrip() throws {
        let f = syntheticFont()
        let data = f.encoded()
        XCTAssertEqual(Array(data.prefix(4)), Array("BTXF".utf8))
        XCTAssertEqual(try BTXFont(data: data), f)
        XCTAssertEqual(try BTXFont(data: data).encoded(), data, "encoding is deterministic")
    }

    func testRejectsBadMagicVersionAndTruncation() {
        var data = syntheticFont().encoded()
        XCTAssertThrowsError(try BTXFont(data: data.prefix(data.count - 1))) {
            XCTAssertEqual($0 as? BTXFont.FormatError, .truncated)
        }
        data[4] = 9
        XCTAssertThrowsError(try BTXFont(data: data)) {
            XCTAssertEqual($0 as? BTXFont.FormatError, .unsupportedVersion(9))
        }
        data[0] = 0x58
        XCTAssertThrowsError(try BTXFont(data: data)) { XCTAssertEqual($0 as? BTXFont.FormatError, .badMagic) }
    }

    /// The committed faces load, cover every MacRoman printable character, and re-encode to the same bytes.
    func testCommittedFacesLoadAndRoundTrip() throws {
        let expected = ["Geneva-9", "Geneva-10", "System-12", "System-Bold-12"]
        for name in expected {
            let url = fontsDirectory.appendingPathComponent(name + ".btxfont")
            let data = try Data(contentsOf: url)
            let f = try BTXFont(data: data)
            XCTAssertEqual(BTXFont.fileName(name: f.name, size: f.size), name + ".btxfont")
            XCTAssertEqual(f.glyphs.count, 223, "\(name): 0x20–0xFF less DEL")
            XCTAssertEqual(f.encoded(), data, name)
        }
    }
}

final class BitmapFontRasterizerTests: XCTestCase {
    let r = BitmapFontRasterizer(fonts: [syntheticFont()])

    func testWidthSumsAdvancesAndKerning() {
        XCTAssertEqual(r.width("A", font: "Test", size: 9), 6)
        XCTAssertEqual(r.width("AA", font: "Test", size: 9), 11)
        XCTAssertEqual(r.width("A A", font: "Test", size: 9), 15)
        XCTAssertEqual(r.width("", font: "Test", size: 9), 0)
    }

    func testUnknownCharacterTakesTheQuestionMark() {
        XCTAssertEqual(r.width("Z", font: "Test", size: 9), r.width("?", font: "Test", size: 9))
        XCTAssertEqual(r.width("A€A", font: "Test", size: 9), 17)
        var a = RGBAImage(width: 20, height: 12), b = a
        r.rasterize("Z", font: "Test", size: 9, rgb: 0xFFFFFF, into: &a, at: (3, 8), centredIn: nil)
        r.rasterize("?", font: "Test", size: 9, rgb: 0xFFFFFF, into: &b, at: (3, 8), centredIn: nil)
        XCTAssertEqual(a, b)
    }

    func testDrawsAtThePenWithPhaseAndBlendsOpaque() {
        var img = RGBAImage(width: 20, height: 12, fill: 0x8000_0000)            // translucent black
        r.rasterize("AA", font: "Test", size: 9, rgb: 0xFF0000, into: &img, at: (2, 8), centredIn: nil)
        // First A at pen 0 (phase 0): block at columns 2–3, rows 6–7. Second at pen 5 (kerned): columns 7–8.
        for (x, y) in [(2, 6), (3, 7), (7, 6), (8, 7)] { XCTAssertEqual(img[x, y], 0xFFFF_0000, "(\(x),\(y))") }
        XCTAssertEqual(img[4, 6], 0x8000_0000, "untouched pixels keep their value")
        for p in img.pixels where p != 0x8000_0000 { XCTAssertEqual(p >> 24, 0xFF, "touched pixels are opaque") }
    }

    func testFractionalPenPicksThePhaseBitmap() {
        var img = RGBAImage(width: 20, height: 12)
        r.rasterize("BA", font: "Test", size: 9, rgb: 0xFFFFFF, into: &img, at: (2, 8), centredIn: nil)
        // A's origin is pad 2 + 2.5 = 4.5 in the mask: phase 0.5 → the shifted bitmap, one column right of 4.
        XCTAssertEqual(img[5, 6], 0xFFFF_FFFF)
        XCTAssertEqual(img[6, 6], 0xFF80_8080)
        XCTAssertEqual(img[4, 6], 0xFF00_0000)
        XCTAssertEqual(img[2, 5], 0xFFFF_FFFF, "B's mark")
    }

    func testLigatureDrawsAsOneUnit() {
        XCTAssertEqual(r.width("BB", font: "Test", size: 9), 4)
        XCTAssertEqual(r.width("BBB", font: "Test", size: 9), 7, "greedy: the ligature, then B (6.5 → 7)")
        var a = RGBAImage(width: 20, height: 12), b = a
        r.rasterize("BB", font: "Test", size: 9, rgb: 0xFFFFFF, into: &a, at: (2, 8), centredIn: nil)
        r.rasterize("A", font: "Test", size: 9, rgb: 0xFFFFFF, into: &b, at: (2, 8), centredIn: nil)
        XCTAssertEqual(a, b, "the ligature's bitmap is A's block")
    }

    func testCentringUsesTruncatingDivision() {
        var a = RGBAImage(width: 30, height: 12), b = a
        r.rasterize("A", font: "Test", size: 9, rgb: 0xFFFFFF, into: &a, at: (0, 8),
                    centredIn: QDRect(top: 0, left: 1, bottom: 12, right: 10))       // 1 + (9 − 6) / 2 = 2
        r.rasterize("A", font: "Test", size: 9, rgb: 0xFFFFFF, into: &b, at: (2, 8), centredIn: nil)
        XCTAssertEqual(a, b)
    }

    func testMissingFaceFallsBack() {
        XCTAssertEqual(r.width("A", font: "Test", size: 12), 6, "same name, nearest size")
        XCTAssertEqual(r.width("A", font: "Nope", size: 9), 6, "any face")
    }

    func testControlCharactersAreInvisibleAndTabsStopEvery28() {
        XCTAssertEqual(r.width("\u{0}", font: "Test", size: 9), 0)
        XCTAssertEqual(r.width("A\u{0}A", font: "Test", size: 9), 11, "transparent to kerning")
        XCTAssertEqual(r.width("A\u{1F}\u{7F}", font: "Test", size: 9), 6)
        XCTAssertEqual(r.width("\t", font: "Test", size: 9), 28)
        XCTAssertEqual(r.width("A\tA", font: "Test", size: 9), 34)
        XCTAssertEqual(r.width("\t\t", font: "Test", size: 9), 56)
        var a = RGBAImage(width: 20, height: 12), b = a
        r.rasterize("\u{0}\u{7}", font: "Test", size: 9, rgb: 0xFFFFFF, into: &a, at: (3, 8), centredIn: nil)
        XCTAssertEqual(a, b, "nothing drawn")
        r.rasterize("A\u{0}", font: "Test", size: 9, rgb: 0xFFFFFF, into: &a, at: (3, 8), centredIn: nil)
        r.rasterize("A", font: "Test", size: 9, rgb: 0xFFFFFF, into: &b, at: (3, 8), centredIn: nil)
        XCTAssertEqual(a, b)
    }

    func testEmptyOrMissingFontsDirectoryThrows() throws {
        let empty = FileManager.default.temporaryDirectory.appendingPathComponent("btx-empty-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: empty) }
        XCTAssertThrowsError(try BitmapFontRasterizer(fontsDirectory: empty)) {
            XCTAssertEqual($0 as? BitmapFontRasterizer.LoadError, .noFonts(empty.path))
        }
        XCTAssertThrowsError(try BitmapFontRasterizer(fontsDirectory: empty.appendingPathComponent("absent")))
    }

    func testLoadsTheFontsDirectory() throws {
        let loaded = try BitmapFontRasterizer(fontsDirectory: fontsDirectory)
        XCTAssertNotNil(loaded.face("Geneva", size: 9).flatMap { $0.size == 9 ? $0 : nil })
        XCTAssertEqual(loaded.face("System", size: 12)?.name, "System")
        XCTAssertEqual(loaded.face("System-Bold", size: 12)?.name, "System-Bold")
    }
}

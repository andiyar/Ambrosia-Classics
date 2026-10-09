import XCTest
import FerazelCore
@testable import FerazelRender

/// R6 (docs/plans/2026-10-06-ferazel-phase1.md): `.UpdateStatusBar(0, 0, 0)` at the start values — the status port
/// (PICT 132 under clut 199), `.UpdateHealthMagic`, `.UpdateTextStats`, `.UpdateItemStat` — as read in
/// spells-items §6 "⚑ Phase-1 note (R6)". A missing data file is a FAILURE, never a skip.
final class StatusBarTests: XCTestCase {

    /// A font-independent `TextRasterizer`: every character is a 5×7 box on the baseline, advance 6; calls recorded.
    final class BoxRasterizer: TextRasterizer {
        private(set) var calls: [String] = []

        func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
            -> (left: Int, top: Int, width: Int, height: Int, bits: [Bool]) {
            calls.append("\(text)|\(font)|\(size)|\(face)")
            let w = max(0, 6 * text.count - 1)
            let bits = (0..<7).flatMap { _ in (0..<w).map { $0 % 6 != 5 } }
            return (0, -7, w, 7, bits)
        }
    }

    func testStatusBarStartValues() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let L = try LevelFile.load(from: r, level: 1)
        let search = ColorSearch(model: .ruled)
        let c199 = try ColorLUT.load(id: 199, from: r, chain: .level)
        let c200 = try ColorLUT.load(id: 200, from: r, chain: .level)
        let c202 = try ColorLUT.load(id: 202, from: r, chain: .level)
        func picture(_ id: Int16, _ clut: ColorLUT) throws -> ConvertedPicture {
            try ConvertedPicture(source: try PictureSource.load(id: id, from: r, chain: .frontEnd), clut: clut,
                                 search: search)
        }
        let back = try picture(132, c199), hud = try picture(133, c200)
        let spellBig = try picture(700, c200), spellSmall = try picture(701, c200), itemSmall = try picture(703, c200)
        // `CopyBits` from a 200-seeded icon port: Color2Index(RGB under 200) against the screen device (202).
        let translate = c200.entries.map { search.index(of: RGB16($0.red, $0.green, $0.blue), in: c202) }
        let black = search.index(of: RGB16(0, 0, 0), in: c202), white = search.index(of: RGB16(0xffff, 0xffff, 0xffff), in: c202)
        XCTAssertEqual([black, white], [96, 0])            // clut 202 holds black at 96, 160, 254, 255 (.ruled: lowest)

        let text = BoxRasterizer()
        var bar = try StatusBar(resources: r, screenClut: c202, search: search, text: text)
        var screen = IndexedFrame(fill: 0x33)
        let start = GameGlobals(header: L.header).statusBar(levelName: L.header.name)
        XCTAssertEqual([start.health, start.breath, start.magic, start.score, start.coins], [560, 560, 560, 0, 0])
        bar.update(start, full: true, screen: &screen)
        let port = bar.port
        func at(_ x: Int, _ y: Int) -> UInt8 { port[y * StatusBar.width + x] }

        // `.UpdateTextStats`: bold (1) Times (20) 12 pt, white on a black PaintRect, pens (27, 19), (150, 19), (27, 46).
        XCTAssertEqual(text.calls, ["0|20|12|1", "0|20|12|1", "A Scent Of Peril|20|12|1"])
        for (rect, pen, n) in [((9, 25, 21, 133), (27, 19), 1), ((9, 148, 21, 192), (150, 19), 1),
                               ((36, 25, 49, 192), (27, 46), 16)] {
            for y in rect.0..<rect.2 { for x in rect.1..<rect.3 {
                let dx = x - pen.0, dy = y - pen.1
                let glyph = (-7..<0).contains(dy) && (0..<(6 * n - 1)).contains(dx) && dx % 6 != 5
                XCTAssertEqual(at(x, y), glyph ? white : black, "text (\(x), \(y))")
                XCTAssertEqual(screen[x, y + 392], at(x, y), "text copy (\(x), \(y))")
            } }
        }

        // `.UpdateHealthMagic` at 560/560/560 (>> 3 = 70): breath rows 9..18 over 70 px at x 214, past-max rows
        // 36..45 for the other 126; magic rows 18..27 over 70 px at x 419 (0x1ab − 8), past-max after it.
        func hudRow(_ row: Int, _ col: Int) -> UInt8 { hud.pixels[row * hud.width + col] }
        for y in 7..<16 {
            for x in 214..<284 { XCTAssertEqual(at(x, y), hudRow(y - 7 + 9, x - 214), "breath (\(x), \(y))") }
            for x in 284..<410 { XCTAssertEqual(at(x, y), hudRow(y - 7 + 36, x - 214), "past max (\(x), \(y))") }
            for x in 419..<489 { XCTAssertEqual(at(x, y), hudRow(y - 7 + 18, x - 419), "magic (\(x), \(y))") }
            for x in 489..<615 { XCTAssertEqual(at(x, y), hudRow(y - 7 + 36, x - 419), "past max (\(x), \(y))") }
            for x in (212..<412).chain(416..<616) { XCTAssertEqual(screen[x, y + 392], at(x, y)) }
        }

        // `.UpdateItemStat`: slot 0 (spell 0, selected) big from 700 and small from 701's top row; slot 1 (item 0)
        // small from 703's lower row; the first empty slot (2) painted black; slot 3 keeps `.InitGameGlobals`' 0xFF.
        func icon(_ p: ConvertedPicture, top: Int, left: Int, w: Int, h: Int, at x0: Int, _ y0: Int, _ what: String) {
            for y in 0..<h { for x in 0..<w {
                XCTAssertEqual(at(x0 + x, y0 + y), translate[Int(p.pixels[(top + y) * p.width + left + x])],
                               "\(what) (\(x), \(y))")
            } }
        }
        icon(spellBig, top: 0, left: 0, w: 44, h: 47, at: 215, 30, "big")
        icon(spellSmall, top: 0, left: 0, w: 23, h: 23, at: 266, 31, "slot 0")
        icon(itemSmall, top: 23, left: 0, w: 23, h: 23, at: 289, 31, "slot 1")
        for y in 31..<54 { for x in 312..<335 { XCTAssertEqual(at(x, y), black) }
                           for x in 335..<358 { XCTAssertEqual(at(x, y), 0xff) } }
        for y in 30..<76 { for x in (215..<267).chain(264..<616) { XCTAssertEqual(screen[x, y + 392], at(x, y)) } }

        // The full copy (`.CopyBitsCT`, raw): what no update touched is PICT 132 as converted under clut 199.
        for x in 0..<640 {
            XCTAssertEqual(at(x, 0), back.pixels[x])
            XCTAssertEqual(screen[x, 392], back.pixels[x])
            XCTAssertEqual(screen[x, 479], back.pixels[87 * 640 + x])
        }
        XCTAssertTrue(screen.pixels[0..<(392 * 640)].allSatisfy { $0 == 0x33 })

        // `.UpdateStatusBar(1, 0, 0)` with nothing changed draws nothing; a new score redraws the three text fields.
        let before = screen
        bar.update(start, full: false, screen: &screen)
        XCTAssertEqual(screen, before)
        XCTAssertEqual(text.calls.count, 3)
        var scored = start
        scored.score = 120
        bar.update(scored, full: false, screen: &screen)
        XCTAssertEqual(text.calls.suffix(3), ["120|20|12|1", "0|20|12|1", "A Scent Of Peril|20|12|1"])
    }
}

private extension Range where Bound == Int {
    func chain(_ other: Range<Int>) -> [Int] { Array(self) + Array(other) }
}

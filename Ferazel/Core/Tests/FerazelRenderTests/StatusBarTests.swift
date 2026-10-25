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
            -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
            calls.append("\(text)|\(font)|\(size)|\(face)")
            let w = max(0, 6 * text.count - 1)
            let coverage = (0..<7).flatMap { _ in (0..<w).map { $0 % 6 != 5 ? UInt8(255) : 0 } }
            return (0, -7, w, 7, coverage)
        }

        /// The fixed 6-px advance of every character (C2).
        func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int { 6 }

        /// The 7-px box over the baseline, 2 below, no leading: a 9-px TextEdit line (C2).
        func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) { (7, 2, 0) }
    }

    /// TX: every string (and character) is one row of pixels just above the baseline at the pen — coverage `row`
    /// (default 0, 128, 255) — advance `advance` (default 4).
    final class CoverageRasterizer: TextRasterizer {
        let row: [UInt8]
        let advance: Int
        init(row: [UInt8] = [0, 128, 255], advance: Int = 4) { self.row = row; self.advance = advance }
        func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
            -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) { (0, -1, row.count, 1, row) }
        func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int { advance }
        func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) { (1, 0, 0) }
    }

    /// TX: the text RGB `t` over the pixel's RGB `d` at coverage `c`/255, per 16-bit channel, rounded (`rounded:
    /// false` truncates — what the rounding asserts tell apart).
    static func mix(_ t: RGB16, _ d: RGB16, _ c: Int, rounded: Bool = true) -> RGB16 {
        let half = rounded ? 127 : 0
        func m(_ a: UInt16, _ b: UInt16) -> UInt16 { UInt16((Int(a) * c + Int(b) * (255 - c) + half) / 255) }
        return RGB16(m(t.red, d.red), m(t.green, d.green), m(t.blue, d.blue))
    }

    /// TX (Q6 note 1): `DrawString` smoothed as Mac OS 9 drew it — coverage 0 leaves the port's pixel, 255 is the
    /// white index as before, a partial pixel is `Color2Index` (the screen device's search) of white mixed with the
    /// pixel's colour under the screen CLUT (202 here), not under the port's own 199 or the icons' 200, rounded.
    func testTextSmoothingBlendsIntoTheStatusPort() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let search = ColorSearch(model: .ruled)
        let c199 = try ColorLUT.load(id: 199, from: r, chain: .level)
        let c200 = try ColorLUT.load(id: 200, from: r, chain: .level)
        let c202 = try ColorLUT.load(id: 202, from: r, chain: .level)
        var bar = try StatusBar(resources: r, screenClut: c202, search: search, text: CoverageRasterizer())
        bar.paint((50, 100, 60, 110), bar.black)
        // Under the coverage-0 pixel: index 7, whose colour 202's search answers with another index (3) — writing
        // it would show. Under the 128 pixel: index 165, whose colour differs across 199 / 200 / 202.
        bar.paint((55, 102, 56, 103), 7)
        bar.paint((55, 103, 56, 104), 165)
        XCTAssertNotEqual(search.index(of: RGB16(c202.entries[7]), in: c202), 7)
        let before = bar.port
        bar.drawString("A", x: 102, y: 56, font: 20, size: 12, face: 1)
        let row = 55 * StatusBar.width + 102
        let white = RGB16(0xffff, 0xffff, 0xffff)
        let want = search.index(of: Self.mix(white, RGB16(c202.entries[165]), 128), in: c202)
        XCTAssertEqual(want, 3)
        // Every wrong reading lands elsewhere: under black (no CLUT lookup), under 199, under 200, truncated, swapped.
        let wrong = [Self.mix(white, RGB16(0, 0, 0), 128), Self.mix(white, RGB16(c199.entries[165]), 128),
                     Self.mix(white, RGB16(c200.entries[165]), 128),
                     Self.mix(white, RGB16(c202.entries[165]), 128, rounded: false),
                     Self.mix(RGB16(c202.entries[165]), white, 128)].map { search.index(of: $0, in: c202) }
        XCTAssertFalse(wrong.contains(want), "\(wrong)")
        XCTAssertFalse([bar.black, bar.white, 165].contains(want))
        XCTAssertEqual(Array(bar.port[row..<row + 3]), [7, want, bar.white])
        var rest = bar.port
        rest.replaceSubrange(row + 1..<row + 3, with: before[row + 1..<row + 3])
        XCTAssertEqual(rest, before)          // only the two covered pixels changed
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

    // MARK: - HU: the bar from the game globals (M l. 4361–4921)

    private struct Fixture {
        let r: FerazelResources
        let search: ColorSearch
        let c202: ColorLUT
        let hud: ConvertedPicture
        let white: UInt8
        let black: UInt8
        let start: StatusBarState
        let itemSmall: ConvertedPicture
        let spellSmall: ConvertedPicture
        /// `Color2Index`(clut 200 entry i) against clut 202.
        let translate: [UInt8]
    }

    private func fixture() throws -> Fixture {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let L = try LevelFile.load(from: r, level: 1)
        let search = ColorSearch(model: .ruled)
        let c200 = try ColorLUT.load(id: 200, from: r, chain: .level)
        let c202 = try ColorLUT.load(id: 202, from: r, chain: .level)
        func picture(_ id: Int16) throws -> ConvertedPicture {
            try ConvertedPicture(source: try PictureSource.load(id: id, from: r, chain: .frontEnd), clut: c200,
                                 search: search)
        }
        return Fixture(r: r, search: search, c202: c202, hud: try picture(133),
                       white: search.index(of: RGB16(0xffff, 0xffff, 0xffff), in: c202),
                       black: search.index(of: RGB16(0, 0, 0), in: c202),
                       start: GameGlobals(header: L.header).statusBar(levelName: L.header.name),
                       itemSmall: try picture(703), spellSmall: try picture(701),
                       translate: c200.entries.map { search.index(of: RGB16($0.red, $0.green, $0.blue), in: c202) })
    }

    private static func item(_ id: Int16, _ count: Int16) -> InventorySlot {
        InventorySlot(id: id, count: count, field4: -1, field6: 0, isSpell: 0)
    }

    /// `.UpdateItemStat`'s counts (M l. 4719–4745, 4791–4814): the selected slot's count > 1 in Geneva (3) plain 9 pt —
    /// "x" (pstr 0x100a1531) at (0xf5, 0x3e), the number at (0xfb, 0x3e), or (0xf2 / 0xf8) from 10 on; each slot's
    /// count > 1 in Geneva bold 8 pt at the box bottom — "x" at left + 0xe, the number at left + 0x12 (+9 / +0xc from 10
    /// on); white (`ForeColor(0x1e)`), drawn over the icons. Exactly those pixels differ from the count-1 drawing.
    func testCountsDrawn() throws {
        let f = try fixture()
        func draw(_ count: Int16) throws -> (port: [UInt8], calls: [String]) {
            let text = BoxRasterizer()
            var bar = try StatusBar(resources: f.r, screenClut: f.c202, search: f.search, text: text)
            var s = f.start
            s.inventory[1] = Self.item(6, count)
            s.selectedSlot = 1
            var screen = IndexedFrame(fill: 0)
            bar.update(s, screen: &screen)
            return (bar.port, text.calls)
        }
        let one = try draw(1)
        // A glyph run of n characters at pen (x, y): BoxRasterizer's 5×7 boxes over the baseline, advance 6.
        func glyphs(_ pens: [(x: Int, y: Int, n: Int)]) -> Set<Int> {
            var set = Set<Int>()
            for p in pens { for dy in -7..<0 { for dx in 0..<(6 * p.n - 1) where dx % 6 != 5 {
                set.insert((p.y + dy) * StatusBar.width + p.x + dx)
            } } }
            return set
        }
        for (count, big, small) in [(Int16(3), [(0xf5, 0x3e, 1), (0xfb, 0x3e, 1)], [(0x121 + 0xe, 0x36, 1),
                                                                                   (0x121 + 0x12, 0x36, 1)]),
                                    (Int16(12), [(0xf2, 0x3e, 1), (0xf8, 0x3e, 2)], [(0x121 + 9, 0x36, 1),
                                                                                    (0x121 + 0xc, 0x36, 2)])] {
            let d = try draw(count)
            // The text calls after the three text fields: the big count (plain 9), then slot 1's (bold 8).
            XCTAssertEqual(Array(d.calls.dropFirst(3)), ["x|3|9|0", "\(count)|3|9|0", "x|3|8|1", "\(count)|3|8|1"])
            let pixels = glyphs((big + small).map { (x: $0.0, y: $0.1, n: $0.2) })
            for i in pixels { XCTAssertEqual(d.port[i], f.white, "count \(count): glyph pixel \(i % 640), \(i / 640)") }
            for i in 0..<d.port.count where !pixels.contains(i) {
                XCTAssertEqual(d.port[i], one.port[i], "count \(count): (\(i % 640), \(i / 640)) changed")
            }
            XCTAssertTrue(pixels.contains { one.port[$0] != f.white }, "the counts draw over the icons")
        }
        // The item flash on slot 1 (M l. 4767–4790): flash 3 → s = 2; mode 0 colourises with RGB (2·0x5dc ×3), mode 1
        // with (2·3000, 0, 0): each pixel (src & fg) | (~src & white) [MED]; mode 2 is a plain copy.
        func flashed(_ mode: Int) throws -> [UInt8] {
            var bar = try StatusBar(resources: f.r, screenClut: f.c202, search: f.search, text: BoxRasterizer())
            var s = f.start
            s.inventory[1] = Self.item(6, 1)
            s.itemFlash = 3
            s.itemFlashSlot = 1
            s.itemFlashMode = mode
            var screen = IndexedFrame(fill: 0)
            bar.update(s, screen: &screen)
            return bar.port
        }
        var plainBar = try StatusBar(resources: f.r, screenClut: f.c202, search: f.search, text: BoxRasterizer())
        var plainState = f.start
        plainState.inventory[1] = Self.item(6, 1)
        var plainScreen = IndexedFrame(fill: 0)
        plainBar.update(plainState, screen: &plainScreen)
        let grey = f.search.index(of: RGB16(3000, 3000, 3000), in: f.c202)
        let red = f.search.index(of: RGB16(6000, 0, 0), in: f.c202)
        XCTAssertNotEqual(grey, red)
        let box1 = (0x1f..<0x36).flatMap { y in (0x121..<0x138).map { y * StatusBar.width + $0 } }
        for (mode, fg) in [(0, grey), (1, red)] {
            let port = try flashed(mode)
            for (k, i) in box1.enumerated() {
                let src = f.translate[Int(f.itemSmall.pixels[(0x17 + k / 23) * f.itemSmall.width + 6 * 0x17 + k % 23])]
                XCTAssertEqual(port[i], (src & fg) | (~src & f.white), "mode \(mode) pixel \(k)")
            }
            XCTAssertTrue(box1.contains { port[$0] != plainBar.port[$0] }, "mode \(mode) colourises")
        }
        XCTAssertEqual(try flashed(2), plainBar.port)
    }

    /// `.UpdateItemStat`'s empty-box loop (M l. 4818–4830): only the **first** empty slot's box is painted black
    /// (`sVar11 = 0x1b` ends the loop) — a box emptied earlier keeps its icon.
    func testFirstEmptyBoxOnly() throws {
        let f = try fixture()
        var bar = try StatusBar(resources: f.r, screenClut: f.c202, search: f.search, text: BoxRasterizer())
        var screen = IndexedFrame(fill: 0)
        var s = f.start
        for k in 2..<5 { s.inventory[k] = Self.item(Int16(k), 1) }                 // 5 filled: boxes 0…4 have icons
        bar.update(s, screen: &screen)
        let before = bar.port
        s.inventory[3] = .empty
        s.inventory[4] = .empty                                                     // 3 filled
        bar.update(s, screen: &screen)
        func box(_ i: Int) -> [Int] {
            let b = StatusBar.box(i)
            return (b.0..<b.2).flatMap { y in (b.1..<b.3).map { y * StatusBar.width + $0 } }
        }
        XCTAssertTrue(box(3).allSatisfy { bar.port[$0] == f.black }, "box 3 painted black")
        XCTAssertTrue(box(4).contains { before[$0] != f.black }, "box 4 held an icon")
        for i in 4..<30 { for p in box(i) { XCTAssertEqual(bar.port[p], before[p], "box \(i) keeps its pixels") } }
        // Box 5 keeps the first drawing's black (its first empty box then); 6…29 still hold `.InitGameGlobals`' 0xFF.
        XCTAssertTrue(box(5).allSatisfy { bar.port[$0] == f.black })
        XCTAssertTrue((6..<30).allSatisfy { box($0).allSatisfy { bar.port[$0] == 0xff } })
        // Spell id 2 (`+8` 1) is drawn as 3 in the strip (M l. 4748–4750): box 2 from 701's column 3, lower row.
        s.inventory[2] = InventorySlot(id: 2, count: 1, field4: -1, field6: 0, isSpell: 1)
        bar.update(s, screen: &screen)
        for (k, p) in box(2).enumerated() {
            let src = f.spellSmall.pixels[(0x17 + k / 23) * f.spellSmall.width + 3 * 0x17 + k % 23]
            XCTAssertEqual(bar.port[p], f.translate[Int(src)], "spell 2 → icon 3, pixel \(k)")
        }
        XCTAssertTrue(box(2).enumerated().contains { k, p in
            bar.port[p] != f.translate[Int(f.spellSmall.pixels[(0x17 + k / 23) * f.spellSmall.width + 2 * 0x17 + k % 23])]
        }, "icons 2 and 3 differ")
        // An empty selected slot (3, after a removal compacted the strip): the big icon's rect (id −1) is clipped
        // away — nothing drawn there, no trap (M l. 4709–4718).
        let big = (0x1e..<0x4d).flatMap { y in (0xd7..<0x103).map { y * StatusBar.width + $0 } }
        let beforeBig = big.map { bar.port[$0] }
        s.selectedSlot = 3
        bar.update(s, screen: &screen)
        XCTAssertEqual(big.map { bar.port[$0] }, beforeBig)
    }

    /// `.UpdateHealthMagic` reads G's maxima (M l. 4442–4455, 4535–4542): max health 0x2a0 (>> 3 = 0x54) → the empty
    /// segment runs from the health (0x230 >> 3 = 0x46) to 0x54 and the past-max segment starts at x 0xd6 + 0x54 =
    /// 0x12a, not 0x11c; max magic 0x2a0 → its past-max segment at 0x1ab − 8 + 0x54.
    func testMaximaFromGlobals() throws {
        let f = try fixture()
        var bar = try StatusBar(resources: f.r, screenClut: f.c202, search: f.search, text: BoxRasterizer())
        var screen = IndexedFrame(fill: 0)
        var s = f.start
        s.maxHealth = 0x2a0
        s.maxMagic = 0x2a0
        bar.update(s, screen: &screen)
        func at(_ x: Int, _ y: Int) -> UInt8 { bar.port[y * StatusBar.width + x] }
        func hud(_ row: Int, _ col: Int) -> UInt8 { f.hud.pixels[row * f.hud.width + col] }
        XCTAssertNotEqual((0..<9).map { hud($0, 0x50) }, (0..<9).map { hud(36 + $0, 0x50) }, "rows 0 and 36 differ")
        for y in 7..<16 {
            for x in 0xd6..<0x11c { XCTAssertEqual(at(x, y), hud(y - 7 + 9, x - 0xd6), "breath (\(x), \(y))") }
            for x in 0x11c..<0x12a { XCTAssertEqual(at(x, y), hud(y - 7, x - 0xd6), "empty (\(x), \(y))") }
            for x in 0x12a..<0x19a { XCTAssertEqual(at(x, y), hud(y - 7 + 36, x - 0xd6), "past max (\(x), \(y))") }
            for x in 0x1a3..<0x1e9 { XCTAssertEqual(at(x, y), hud(y - 7 + 18, x - 0x1a3), "magic (\(x), \(y))") }
            for x in 0x1e9..<0x1f7 { XCTAssertEqual(at(x, y), hud(y - 7, x - 0x1a3), "magic empty (\(x), \(y))") }
            for x in 0x1f7..<0x267 { XCTAssertEqual(at(x, y), hud(y - 7 + 36, x - 0x1a3), "magic past (\(x), \(y))") }
        }
        // Maxima past 0xc4 << 3 (0x700 >> 3 = 0xe0): the empty rect (h, 0)–(0xe0, 9) is clipped to the 196-px piece and
        // the past-max rect (0xe0 … 0xc4) is empty — QuickDraw draws what lies inside, no trap.
        s.maxHealth = 0x700
        s.maxMagic = 0x700
        bar.update(s, screen: &screen)
        for y in 7..<16 {
            for x in 0x11c..<0x19a { XCTAssertEqual(at(x, y), hud(y - 7, x - 0xd6), "wide empty (\(x), \(y))") }
        }
    }
}

private extension Range where Bound == Int {
    func chain(_ other: Range<Int>) -> [Int] { Array(self) + Array(other) }
}

import XCTest
import FerazelCore
import HectorResources
@testable import FerazelRender

/// C2 (docs/plans/2026-10-14-ferazel-phase3.md): the conversation screen — PICT 4000 copied with mode 0x24 over the
/// game view, portraits, the Times 18 name and text, the 214-px wrap, the trail greys — as `ConversationRun` (C1) emits
/// it and `ConversationRenderer` draws it (conversations-mcnv §6, BC20; `.CopyConvToScreen @ 100797e4`,
/// `.DrawConvTextString @ 1007940c`, M l. 65470–65930). A missing data file is a FAILURE, never a skip.
final class ConversationRenderTests: XCTestCase {

    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return h
    }

    /// The level-1 renderer and session after iteration 1 drawn (`FrameGoldenTests.testFirstFrameGoldenLevel1`'s
    /// screen, hash 9db8f32f7e3d88b4): `.ruled`, lowest tie-break, error diffusion, the box rasterizer.
    private func levelOneFrame() throws -> (FrameRenderer, FerazelSession) {
        let r = try Self.resources.get()
        let frame = try FrameRenderer(resources: r, level: 1, search: ColorSearch(model: .ruled, tieBreak: .lowest),
                                      dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer())
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1, faceBounds: frame.faceBounds)
        try frame.addLights(s.lights)
        try frame.buildTintTable(s.tintTableDraws)
        try frame.apply(s.step(keys: KeyState()))
        XCTAssertEqual(String(fnv1a(frame.screen.pixels), radix: 16), "9db8f32f7e3d88b4")
        return (frame, s)
    }

    private func sign(_ text: [UInt8], world: SpriteWorld, measures: ConversationText) throws -> ConversationRun {
        ConversationRun(.simple(pict: 4020, name: MacRoman.bytes("Wooden Sign"), text: text), world: world,
                        resources: try Self.resources.get(), prefs: FerazelPrefs(), levelName: "",
                        text: measures)
    }

    /// Ticks `c` with no key until it waits for "press any key" (the text fully typed); every draw in order.
    private func typeOut(_ c: ConversationRun) -> [DrawOp] {
        var save = SaveBlock()
        var draws: [DrawOp] = []
        var t: UInt32 = 1000
        repeat {
            draws += c.tick(now: t, input: FrontInput(), save: &save).draws
            t += 1
        } while c.wait == .typing && t < 20000
        XCTAssertEqual(c.wait, .anyKey)
        return draws
    }

    /// Mcnv 200 (L1 rec 12's talker) driven to its first menu (line #3's replies, coins 0 as
    /// `ConversationTests.testEscapeAtAnyKeyStillRunsActions`): every key wait answered, the run left at the menu's key
    /// wait. The draws before the menu, and the menu's own (from the tick after #3's "press any key").
    private func toMenu(_ s: FerazelSession, measures: ConversationText) throws -> (ConversationRun, [DrawOp], [DrawOp]) {
        s.world.globals.coins = 0
        let c = ConversationRun(.conversation(id: 200, record: 12, sprite: 0), world: s.world,
                                resources: try Self.resources.get(), prefs: FerazelPrefs(), levelName: "", text: measures)
        var save = SaveBlock()
        var before: [DrawOp] = [], menu: [DrawOp] = []
        var t: UInt32 = 1000
        while c.wait != .menuKey && !c.isDone && t < 40000 {
            let answering = c.wait == .anyKey
            let keys = answering ? KeyState(pressed: [0x01]) : KeyState()
            if answering { before += menu; menu = [] }
            menu += c.tick(now: t, input: FrontInput(keys: keys), save: &save).draws
            t += 1
        }
        XCTAssertEqual(c.wait, .menuKey)
        XCTAssertEqual(c.shown, [1, 3])
        return (c, before, menu)
    }

    func testConversationFrameTransparent() throws {
        let (frame, s) = try levelOneFrame()
        let r = try Self.resources.get()
        let view = frame.screen
        let c = try sign(MacRoman.bytes("Hi"), world: s.world, measures: .unmeasured)
        var save = SaveBlock()
        let first = try XCTUnwrap(c.tick(now: 1000, input: FrontInput(), save: &save).draws.first)
        // `.CopyConvToScreen`: the 387×308 GWorld (0, 0)–(308, 387) to the origin (46, 126), mode 0x24.
        XCTAssertEqual(first, .copyPicture(id: 4000, chain: .level, source: Rect16(top: 0, left: 0, bottom: 308, right: 387),
                                           dest: Rect16(top: 46, left: 126, bottom: 354, right: 513), forceClut: nil,
                                           transparent: true))
        let renderer = ConversationRenderer(frame: frame, text: StatusBarTests.BoxRasterizer())
        try renderer.apply([first])

        // The GWorld's table: `NewGWorld(8, …, nil ctab)` at boot (M l. 65548) — the system's default 8-bit table:
        // the 6×6×6 cube (index 36·r + 6·g + b over FF CC 99 66 33 00), the red / green / blue / grey ramps, black last.
        let sys = ConversationRenderer.systemClut
        func rgb8(_ i: Int) -> [UInt16] { sys.entries[i].rgb.map { $0 >> 8 } }
        XCTAssertEqual(sys.entries.count, 256)
        // The game's own copy of it: clut 801 "System CLUT" (the light faces' and particles' table) is entry for entry
        // the same colours.
        XCTAssertEqual(try ColorLUT.load(id: 801, from: r, chain: .level).entries.map(\.rgb), sys.entries.map(\.rgb))
        XCTAssertEqual([rgb8(0), rgb8(1), rgb8(6), rgb8(36), rgb8(43), rgb8(214), rgb8(215), rgb8(224), rgb8(225),
                        rgb8(235), rgb8(245), rgb8(254), rgb8(255)],
                       [[0xff, 0xff, 0xff], [0xff, 0xff, 0xcc], [0xff, 0xcc, 0xff], [0xcc, 0xff, 0xff],
                        [0xcc, 0xcc, 0xcc], [0, 0, 0x33], [0xee, 0, 0], [0x11, 0, 0], [0, 0xee, 0], [0, 0, 0xee],
                        [0xee, 0xee, 0xee], [0x11, 0x11, 0x11], [0, 0, 0]])
        XCTAssertTrue(sys.entries.allSatisfy { e in e.rgb.allSatisfy { $0 & 0xff == $0 >> 8 } })
        let white = sys.entries.map { $0.red == 0xffff && $0.green == 0xffff && $0.blue == 0xffff }
        XCTAssertEqual(white.indices.filter { white[$0] }, [0])           // mode 0x24's white: GWorld index 0 alone

        // PICT 4000 is 32-bit: drawn into the GWorld (ditherCopy) under the system table; its pure-white pixels (the
        // source's (FF, FF, FF)) are where the view shows through; every other GWorld pixel goes by colour into the
        // level's screen CLUT.
        let source = try PictureSource.load(id: 4000, from: r, chain: .level)
        guard case .direct(let rgb) = source.pixels else { return XCTFail("PICT 4000 is a 32-bit picture") }
        XCTAssertEqual([rgb.width, rgb.height], [387, 308])
        let picture = try ConvertedPicture(source: source, clut: sys, search: frame.search, dither: frame.dither)
        let translate = sys.entries.map { frame.search.index(of: RGB16($0.red, $0.green, $0.blue), in: frame.screenClut) }
        var pureWhite = 0, transparent = 0
        for y in 0..<308 {
            for x in 0..<387 {
                let i = y * 387 + x
                let p = Int(picture.pixels[i])
                let screen = frame.screen[126 + x, 46 + y], under = view[126 + x, 46 + y]
                if rgb.rgb[3 * i] == 0xff && rgb.rgb[3 * i + 1] == 0xff && rgb.rgb[3 * i + 2] == 0xff {
                    pureWhite += 1
                    XCTAssertTrue(white[p], "white (\(x), \(y))")
                    XCTAssertEqual(screen, under, "view (\(x), \(y))")
                }
                if white[p] { transparent += 1 }
                XCTAssertEqual(screen, white[p] ? under : translate[p], "frame (\(x), \(y))")
            }
        }
        XCTAssertEqual(pureWhite, 18_627)
        // Measured 2026-10-24 (C2 review fix): under the system table only the pure whites reach GWorld index 0 — the
        // 4 near-white greys (E1…E8) that a one-step conversion under clut 202 took to white (18,631) dither to the
        // system grey ramp / cube here, so they are copied by colour, not skipped.
        XCTAssertEqual(transparent, 18_627)
        // Outside the frame rect nothing moved.
        for y in 0..<IndexedFrame.height {
            for x in 0..<IndexedFrame.width where !((126..<513).contains(x) && (46..<354).contains(y)) {
                XCTAssertEqual(frame.screen[x, y], view[x, y])
            }
        }

        // `.EraseConvNameAndText` (M l. 65910ff): the text rect (154, 29)–(372, 221) and the name rect (19, 260)–
        // (199, 300) copied back from the GWorld to the same place + the origin, mode 0x24 — exactly those pixels.
        let (_, _, menu) = try toMenu(s, measures: .unmeasured)
        let erases = menu.filter { if case .copyPicture(4000, _, _, _, _, true) = $0 { true } else { false } }
        let rects = [Rect16(top: 29, left: 154, bottom: 221, right: 372), Rect16(top: 260, left: 19, bottom: 300, right: 199)]
        XCTAssertEqual(erases, rects.map { q in
            .copyPicture(id: 4000, chain: .level, source: q, dest: Rect16(top: q.top + 46, left: q.left + 126,
                                                                          bottom: q.bottom + 46, right: q.right + 126),
                         forceClut: nil, transparent: true)
        })
        let sentinel: UInt8 = 0x33
        frame.surface.frame = IndexedFrame(fill: sentinel)
        try renderer.apply(erases)
        func gw(_ x: Int, _ y: Int) -> Int { Int(picture.pixels[y * 387 + x]) }
        for y in 0..<IndexedFrame.height {
            for x in 0..<IndexedFrame.width {
                let fx = x - 126, fy = y - 46
                let inside = rects.contains { (Int($0.left)..<Int($0.right)).contains(fx) && (Int($0.top)..<Int($0.bottom)).contains(fy) }
                let expected = inside && !white[gw(fx, fy)] ? translate[gw(fx, fy)] : sentinel
                XCTAssertEqual(frame.screen[x, y], expected, "erase (\(x), \(y))")
            }
        }
        // Every edge (inside and just outside) holds non-white GWorld pixels, so a rect one pixel off shows.
        for q in rects {
            let (t, l, b, rr) = (Int(q.top), Int(q.left), Int(q.bottom), Int(q.right))
            for (inner, outer) in [((l..<rr).map { ($0, t) }, (l..<rr).map { ($0, t - 1) }),
                                   ((l..<rr).map { ($0, b - 1) }, (l..<rr).map { ($0, b) }),
                                   ((t..<b).map { (l, $0) }, (t..<b).map { (l - 1, $0) }),
                                   ((t..<b).map { (rr - 1, $0) }, (t..<b).map { (rr, $0) })] {
                XCTAssertTrue(inner.contains { !white[gw($0.0, $0.1)] } && outer.contains { !white[gw($0.0, $0.1)] },
                              "edge of \(q)")
            }
        }
    }

    func testWrapAt214() throws {
        let (frame, s) = try levelOneFrame()
        let box = StatusBarTests.BoxRasterizer()
        let measures = TextLayout.conversationText(box)
        XCTAssertEqual(measures.charWidth(0x41), 6)
        // 60 bytes: the 36th (index 35, 'h') takes the running sum to 216 > 214; the last space before it is index 34.
        let text = MacRoman.bytes("Sparkly torches and rock piles may hide coins and other gems")
        XCTAssertEqual(text.count, 60)
        let draws = typeOut(try sign(text, world: s.world, measures: measures))
        let renderer = ConversationRenderer(frame: frame, text: box)
        // The trail: a glyph is drawn at its odd ages in grey (10 − age)·4000 — 'S' (280, 89) at ages 1, 3, 5, 7, 9.
        let greys = draws.compactMap { op -> UInt16? in
            if case .drawText(let run) = op, run.bytes == [0x53], run.h == 280, run.v == 89 { return run.rgb.red }
            return nil
        }
        XCTAssertEqual(greys, [36000, 28000, 20000, 12000, 4000])
        // Its first draw (age 1, grey 36000) on the screen — an index apart from age 9's 4000 (black, 96, in clut 202).
        let first = try XCTUnwrap(draws.firstIndex { if case .drawText(let run) = $0 { run.bytes.count == 1 } else { false } })
        try renderer.apply(Array(draws[...first]))
        let age1 = frame.search.index(of: RGB16(red: 36000, green: 36000, blue: 36000), in: frame.screenClut)
        XCTAssertNotEqual(age1, frame.search.index(of: RGB16(red: 4000, green: 4000, blue: 4000), in: frame.screenClut))
        for y in 82..<89 { for x in 280..<285 { XCTAssertEqual(frame.screen[x, y], age1, "age 1 (\(x), \(y))") } }
        try renderer.apply(Array(draws[(first + 1)...]))

        // The typed glyphs (trail draws: one byte each), baselines 46 + 0x1d + 0xe = 89 and + 18 = 107.
        let typed = draws.compactMap { op -> TextRun? in
            if case .drawText(let run) = op, run.bytes.count == 1, run.v != 322 { return run }
            return nil
        }
        XCTAssertEqual(Set(typed.map { $0.v }), [89, 107])
        let line1 = Array(text[0..<34]), line2 = Array(text[35...])
        // The last draw of each glyph is at age 9: grey 4000.
        let ink = frame.search.index(of: RGB16(red: 4000, green: 4000, blue: 4000), in: frame.screenClut)
        for (line, baseline) in [(line1, 89), (line2, 107)] {
            for (k, b) in line.enumerated() where b != 0x20 {
                let x0 = 126 + 0x9a + 6 * k
                XCTAssertTrue(typed.contains { $0.bytes == [b] && $0.h == x0 && $0.v == baseline }, "\(k) at \(baseline)")
                for y in (baseline - 7)..<baseline {
                    for x in x0..<(x0 + 5) { XCTAssertEqual(frame.screen[x, y], ink, "(\(x), \(y))") }
                }
            }
        }
        // Line 1 ends at the break: nothing typed past its 34 bytes on baseline 89, nothing on a third line.
        XCTAssertFalse(typed.contains { $0.v == 89 && $0.h >= 126 + 0x9a + 6 * 34 })
        XCTAssertFalse(typed.contains { $0.v > 107 })

        // `TextLayout.lineCount`: a line takes a character while the width to its end is ≤ the box (214 exactly fits).
        XCTAssertEqual(TextLayout.boxWidth, 214)
        XCTAssertEqual(TextLayout.lineCount([0x41, 0x41], width: { _ in 107 }), 1)
        XCTAssertEqual(TextLayout.lineCount([0x41, 0x41, 0x41], width: { _ in 107 }), 2)
        XCTAssertEqual(TextLayout.lineCount([0x41, 0x41], width: { _ in 108 }), 2)
        // `.CalcWrappedStringInBoxHeight` (M l. 31666): TextEdit's (nLines + 1) · lineHeight in the 214 × 400 box —
        // the box rasterizer's line is 7 + 2 + 0 = 9: 35 'A's (210 px) one line, 36 (216 px) two.
        XCTAssertEqual(measures.wrappedHeight([UInt8](repeating: 0x41, count: 35)), 18)
        XCTAssertEqual(measures.wrappedHeight([UInt8](repeating: 0x41, count: 36)), 27)

        // A menu (Mcnv 200 #3's replies, the erase under them): the row baselines from 46 + 0x2b by each reply's
        // wrapped height — reply 1 (47 bytes) is two lines (107, 125) and 27 px tall; every reply in grey 0x5555,
        // then the selection (0) again in black.
        let (menuFrame, s2) = try levelOneFrame()
        let (_, before, menu) = try toMenu(s2, measures: measures)
        let menuRenderer = ConversationRenderer(frame: menuFrame, text: box)
        try menuRenderer.apply(before)
        let rowsAt = try XCTUnwrap(menu.firstIndex { if case .drawText(let run) = $0 { run.h == 280 } else { false } })
        try menuRenderer.apply(Array(menu[..<rowsAt]))
        let under = menuFrame.screen
        try menuRenderer.apply(Array(menu[rowsAt...]))
        let rows = menu[rowsAt...].compactMap { op -> [Int]? in
            if case .drawText(let run) = op { return [run.h, run.v, Int(run.rgb.red), run.bytes.count] }
            return nil
        }
        XCTAssertEqual(rows, [[280, 89, 0x5555, 24], [280, 107, 0x5555, 33], [280, 125, 0x5555, 13],
                              [280, 134, 0x5555, 33], [280, 152, 0x5555, 27], [280, 89, 0, 24]])
        let grey = menuFrame.search.index(of: RGB16(red: 0x5555, green: 0x5555, blue: 0x5555), in: menuFrame.screenClut)
        let black = menuFrame.search.index(of: RGB16(red: 0, green: 0, blue: 0), in: menuFrame.screenClut)
        XCTAssertNotEqual(grey, black)
        // The first glyph of each row's first line: ink over baseline − 7 ..< baseline, the rows beside it untouched.
        for (baseline, ink) in [(89, black), (107, grey), (134, grey), (152, grey)] {
            for x in 280..<285 {
                for y in (baseline - 7)..<baseline { XCTAssertEqual(menuFrame.screen[x, y], ink, "row (\(x), \(y))") }
                XCTAssertEqual(menuFrame.screen[x, baseline], under[x, baseline], "below (\(x), \(baseline))")
                XCTAssertEqual(menuFrame.screen[x, baseline - 8], under[x, baseline - 8], "above (\(x), \(baseline))")
            }
        }
    }

    func testSignFrameGolden() throws {
        let (frame, s) = try levelOneFrame()
        let r = try Self.resources.get()
        let box = StatusBarTests.BoxRasterizer()
        // L1 sign rec 1 (p1 12): STR# 500 [12].
        let L = try LevelFile.load(from: r, level: 1)
        XCTAssertEqual(L.placements[1].p1, 12)
        let text = MacRoman.bytes(try XCTUnwrap(try StringList.load(from: r, id: 500).string(12)))
        let c = try sign(text, world: s.world, measures: TextLayout.conversationText(box))
        let draws = typeOut(c)
        // Portrait 4020 at the frame's (24, 49) + origin; the name "Wooden Sign" (66 px) centred: 126 + 57 + 19.
        let portraitRect = Rect16(top: 95, left: 150, bottom: 191, right: 246)
        let portrait = draws.contains { op in
            guard case .copyPicture(let id, _, _, let dest, _, let transparent) = op else { return false }
            return id == 4020 && dest == portraitRect && transparent
        }
        XCTAssertTrue(portrait)
        let name = TextRun(bytes: MacRoman.bytes("Wooden Sign"), font: 20, size: 18, face: 0, h: 202, v: 322,
                           rgb: RGB16(red: 0, green: 0, blue: 0))
        XCTAssertTrue(draws.contains(.drawText(name)))
        let renderer = ConversationRenderer(frame: frame, text: box)
        try renderer.apply(draws)
        // Self-derived 2026-10-24 (C2; re-derived in the C2 review fix, 45ccc55d61af45dc → c8e41941c1e4d6da, when the
        // frame and the portrait went through the GWorld's system 8-bit table): FNV-1a 64 of the 640×480 indices, the
        // sign fully typed over level 1's frame 1.
        XCTAssertEqual(String(fnv1a(frame.screen.pixels), radix: 16), "c8e41941c1e4d6da")

        // "Press any key", all keys up: the end's `_WrapCopyToScreen` puts the game view back (frame 1's screen —
        // the same ports, scroll point and prefs).
        var save = SaveBlock()
        var t: UInt32 = 30000
        while !c.isDone && t < 30100 {
            let keys = c.wait == ConversationRun.Wait.anyKey ? KeyState(pressed: [0x01]) : KeyState()
            try renderer.apply(c.tick(now: t, input: FrontInput(keys: keys), save: &save).draws)
            t += 1
        }
        XCTAssertTrue(c.isDone)
        XCTAssertEqual(String(fnv1a(frame.screen.pixels), radix: 16), "9db8f32f7e3d88b4")
    }
}

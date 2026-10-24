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

        // PICT 4000 is 32-bit: its pure-white pixels (the source's (FF, FF, FF)) are where the view shows through.
        let source = try PictureSource.load(id: 4000, from: r, chain: .level)
        guard case .direct(let rgb) = source.pixels else { return XCTFail("PICT 4000 is a 32-bit picture") }
        XCTAssertEqual([rgb.width, rgb.height], [387, 308])
        let picture = try ConvertedPicture(source: source, clut: frame.screenClut, search: frame.search,
                                           dither: frame.dither)
        let white = frame.screenClut.entries.map { $0.red == 0xffff && $0.green == 0xffff && $0.blue == 0xffff }
        let translate = frame.screenClut.entries.map { frame.search.index(of: RGB16($0.red, $0.green, $0.blue),
                                                                          in: frame.screenClut) }
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
        // Measured 2026-10-24 (C2): mode 0x24 tests the converted pixel, so 4 near-white source pixels (E1…E8 greys)
        // that error diffusion took to white under clut 202 are transparent too.
        XCTAssertEqual(transparent, 18_631)
        // Outside the frame rect nothing moved.
        for y in 0..<IndexedFrame.height {
            for x in 0..<IndexedFrame.width where !((126..<513).contains(x) && (46..<354).contains(y)) {
                XCTAssertEqual(frame.screen[x, y], view[x, y])
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
        try renderer.apply(draws)

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
        // Self-derived 2026-10-24 (C2): FNV-1a 64 of the 640×480 indices, the sign fully typed over level 1's frame 1.
        XCTAssertEqual(String(fnv1a(frame.screen.pixels), radix: 16), "45ccc55d61af45dc")

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

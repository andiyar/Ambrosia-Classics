import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// 6A-RP (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, card 6A-RP; docs/ferazel/phase6-engine-contracts.md
/// §2.5, §2.6, §5): the river backdrop of levels 11 and 18 — `.PaintFrameWrap`'s two ripple loops (M l. 9211–9226 on
/// every call, M l. 9255–9425 on drawn frames; raw `10011fe0..100126c8`) over `.BuildSineTable`'s 55-entry table (M l.
/// 17389–17397) — and the proof of the seven submerged-tint readers (6A-T11, built). The table and row tests are
/// synthetic (level 11's own `Mlvl`, no faces), the placement and switch-off tests run level 11's fixture, the data pin
/// reads the 24 level headers. The feature golden is `FeatureGoldenTests.testLevel11RippleFeatureGolden`.
/// A missing data file is a FAILURE, never a skip.
final class RippleTests: XCTestCase {

    /// Level 11's leave-out list (ENG §7.2; the card): the 27 records the port still refuses there — the Box scenery
    /// 2816, 2817, 2831, 2837, 2857, 2872, 2873, 2875, 2876 (26, 6A-BX1a) and the Nimbo NPC 2955 (1, 6A-BX1b), by type.
    /// A literal list, never computed from what the port refuses today.
    static let level11: [LevelFixture.LeaveOut] = [
        // The Box scenery (6A-BX1a).
        .type(2816), .type(2817), .type(2831), .type(2837), .type(2857), .type(2872), .type(2873), .type(2875),
        .type(2876),
        // The Nimbo NPC (6A-BX1b).
        .type(2955),
    ]

    /// Level 11's own `Mlvl` (the ripple flag set), unpatched.
    private func level(_ n: Int16) throws -> LevelFile { try LevelFile.load(from: try LevelFixture.base.get(), level: n) }

    /// A compositor for `L` with no faces (the producer reads none).
    private func blitter(_ L: LevelFile) throws -> ParallaxBlitter {
        try ParallaxBlitter(level: L, faceSlots: [[UInt8]?](repeating: nil, count: ParallaxBlitter.slotCount))
    }

    /// How many rows two tables differ in (a count, never a whole-table failure message); a size mismatch counts all.
    private func rowsDiffering(_ a: [Int32], _ b: [Int32]) -> Int {
        guard a.count == b.count else { return max(a.count, b.count) }
        return zip(a, b).filter { $0 != $1 }.count
    }

    /// The table after one drawn-frame fill at phase `t`.
    private func filled(_ L: LevelFile, phase t: Int32) throws -> [Int32] {
        var b = try blitter(L)
        try b.rippleFill(phase: t)
        return b.rippleTable
    }

    // MARK: - ENG §2.5

    /// `.BuildSineTable`'s second loop (M l. 17389–17397, raw `10020250..100202b8`): 55 i16 entries,
    /// fctiwz(f32(f32(sin(f32(i) · 0x3de9f678)) · 3.0f)) — re-derived outside Swift with f32 rounding at each `fmuls` /
    /// `frsp`. The constant is 0x3de9f678 as the data section holds it (unpacked `pidata` at `100a1724`), a hair under
    /// 2π/55 (0x3de9f685); 3.0f at `100a1720`.
    func testRippleSineTable55() {
        XCTAssertEqual(ParallaxBlitter.rippleSine.count, 55)
        XCTAssertEqual(ParallaxBlitter.rippleSine, [
            0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0, 0,
            -1, -1, -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -1, -1, 0, 0,
        ])
    }

    /// Rows 0x200…0x27f: fctiwz((1.9·(r − 0x200) + 32.0) · (S[(r + a) mod 55] − b)), `fmadd` then `fmul` (raw
    /// `10012070..1001209c`), a = t >> 8, b = t >> 7. Values re-derived outside Swift (exact rationals for the fused
    /// multiply-add).
    func testRippleRowsShallow() throws {
        let L = try level(11)
        XCTAssertEqual(L.header.parallaxRipple, 1)
        // t = 0x200 (the level start): a 2, b 4. Row 0x200: S[514 mod 55 = 19] = 2 → 32·(2 − 4) = −64; row 0x27f:
        // S[641 mod 55 = 36] = −2 → (1.9·127 + 32)·(−6) = −1639.8 → −1639 (toward zero).
        let t0 = try filled(L, phase: 0x200)
        XCTAssertEqual([t0[0x200], t0[0x201], t0[0x27f]], [-64, -67, -1639])
        // The next frame: t = 0x300, a 3, b 6.
        let t1 = try filled(L, phase: 0x300)
        XCTAssertEqual([t1[0x200], t1[0x201], t1[0x27f]], [-128, -135, -2186])
        // The add is fused (one rounding): at t = 0x7d100, row 0x221 the fused product is −378,800; a separate multiply
        // and add would give −378,799.
        let fused = try filled(L, phase: 0x7d100)
        XCTAssertEqual(fused[0x221], -378_800)
        // Every shallow row against the formula, written out here.
        for t: Int32 in [0x200, 0x300, 0x4567_00, 0x7d100] {
            let table = try filled(L, phase: t)
            let a = t >> 8, b = t >> 7
            for r in 0x200..<0x280 {
                let s = Int32(ParallaxBlitter.rippleSine[Int((Int32(r) + a) % 55)])
                let k = (32.0).addingProduct(1.9, Double(r - 0x200))
                XCTAssertEqual(table[r], ParallaxBlitter.fctiwz(k * Double(s - b)), "t \(t) row \(r)")
            }
        }
        // Nothing outside rows 0x200…0x47f is written.
        XCTAssertEqual(t0.count, 0x2000)
        XCTAssertEqual(t0[0x1ff], 0)
        XCTAssertEqual(t0[0x480], 0)
        // fctiwz saturates at ±2^31 (ENG §2.5 assert 3): at t = 0x7fffff00 (b = 0xffffff) the shallow products pass
        // −2^31 from row 0x27f up — a wrap would read positive.
        let late = try filled(L, phase: 0x7fff_ff00)
        XCTAssertEqual(late[0x27f], Int32.min)
        XCTAssertEqual(late[0x200], -536_870_816)
        XCTAssertEqual(ParallaxBlitter.fctiwz(3e9), Int32.max)
        XCTAssertEqual(ParallaxBlitter.fctiwz(-3e9), Int32.min)
        XCTAssertEqual(ParallaxBlitter.fctiwz(-2.9), -2)
        // The edges of `fctiwz` (PowerPC: NaN and ≥ 2^31 give the saturated words, never a trap).
        XCTAssertEqual(ParallaxBlitter.fctiwz(2_147_483_648.0), Int32.max)
        XCTAssertEqual(ParallaxBlitter.fctiwz(2_147_483_647.5), Int32.max)
        XCTAssertEqual(ParallaxBlitter.fctiwz(-2_147_483_648.5), Int32.min)
        XCTAssertEqual(ParallaxBlitter.fctiwz(.nan), Int32.min)
    }

    /// Rows 0x280…0x47f: fctiwz(275.2 · (S[(r + a) mod 55] − b)) (f64 275.2 at `100a15c8`).
    func testRippleRowsDeep() throws {
        let L = try level(11)
        // t = 0x200: row 0x280: S[642 mod 55 = 37] = −2 → 275.2·(−6) = −1651.2 → −1651; row 0x47f: S[1153 mod 55 = 53]
        // = 0 → 275.2·(−4) = −1100.8 → −1100.
        let t0 = try filled(L, phase: 0x200)
        XCTAssertEqual([t0[0x280], t0[0x47f]], [-1651, -1100])
        for t: Int32 in [0x200, 0x300, 0x4567_00] {
            let table = try filled(L, phase: t)
            let a = t >> 8, b = t >> 7
            for r in 0x280..<0x480 {
                let s = Int32(ParallaxBlitter.rippleSine[Int((Int32(r) + a) % 55)])
                XCTAssertEqual(table[r], ParallaxBlitter.fctiwz(275.2 * Double(s - b)), "t \(t) row \(r)")
            }
        }
        // Saturated (assert 3): every deep row at t = 0x7fffff00.
        let late = try filled(L, phase: 0x7fff_ff00)
        XCTAssertEqual(Set(late[0x280..<0x480]), [Int32.min])
        // The phase wrapped negative (2^23 frames in one level): the sine index would read before the table — refused.
        var b = try blitter(L)
        XCTAssertThrowsError(try b.rippleFill(phase: Int32.min)) {
            XCTAssertEqual($0 as? ParallaxBlitter.Refusal, .ripplePhase(Int32.min))
        }
        XCTAssertNoThrow(try b.rippleFill(phase: Int32.max))
    }

    /// b = t >> 7 grows by 2 a frame (raw `10012004 srawi r6,r0,7`, `1001205c subf r7,r6,r7`) while a = t >> 8 steps
    /// the sine by one row: each row's x offset −(entry >> 8) drifts as it wobbles — the river flows.
    func testRippleDriftsTwoPerFrame() throws {
        let L = try level(11)
        var tables: [[Int32]] = []
        for k in 0..<56 { tables.append(try filled(L, phase: 0x200 + 0x100 * Int32(k))) }
        // A deep row on consecutive frames: S − b recovered from the entry (275.2 · d truncated) — d falls by 2 a frame
        // less the sine's own step.
        for k in 0..<55 {
            for r in [0x280, 0x300, 0x47f] {
                let a = Int32(2 + k)
                let s0 = Int32(ParallaxBlitter.rippleSine[Int((Int32(r) + a) % 55)])
                let s1 = Int32(ParallaxBlitter.rippleSine[Int((Int32(r) + a + 1) % 55)])
                let d0 = s0 - (4 + 2 * Int32(k)), d1 = s1 - (6 + 2 * Int32(k))
                XCTAssertEqual(tables[k][r], ParallaxBlitter.fctiwz(275.2 * Double(d0)))
                XCTAssertEqual(tables[k + 1][r], ParallaxBlitter.fctiwz(275.2 * Double(d1)))
                XCTAssertEqual(d1 - d0, s1 - s0 - 2, "b + 2 per frame")
            }
        }
        // The drift on screen: row 0x280's offset −(entry >> 8) is 7 px at the start (−1651), 9 one frame later
        // (−2201), and after one sine period of 55 frames (the same S, b + 110) 125 (−31923): +118 px.
        func offset(_ e: Int32) -> Int32 { -(e >> 8) }
        XCTAssertEqual([tables[0][0x280], tables[1][0x280], tables[55][0x280]], [-1651, -2201, -31923])
        XCTAssertEqual([offset(tables[0][0x280]), offset(tables[1][0x280]), offset(tables[55][0x280])], [7, 9, 125])
        // The compositor reads the table through `ripple(_:)` (built): row r + v0b's offset.
        var b = try blitter(L)
        try b.rippleFill(phase: 0x300)
        XCTAssertEqual(b.ripple(0x280), -2201)
        XCTAssertEqual(b.ripple(0x2000), 0, "past the table reads 0")
    }

    /// M l. 9211–9226: rows 0x200…0x47f += `_DAT_1009ffbc`[r] (i16, a 32-bit add) — ffbc is 0 as shipped (cleared at
    /// `.InitGameGlobals` and `.SetupLevelSprites`, no other writer), so the add changes nothing; pinned 0. The add
    /// itself is transcribed: with a row set it adds, wraps at 32 bits, and touches no row outside 0x200…0x47f.
    func testRippleAddIsNoOp() throws {
        let L = try level(11)
        var b = try blitter(L)
        XCTAssertEqual(b.rippleAdd.count, 0x2000)
        XCTAssertEqual(Set(b.rippleAdd), [0], "ffbc is 0")
        try b.rippleFill(phase: 0x4567_00)
        let before = b.rippleTable
        b.rippleAddEveryCall()
        XCTAssertEqual(rowsDiffering(b.rippleTable, before), 0, "the shipped add is a no-op")
        XCTAssertNotEqual(before[0x200], 0)
        // The add with rows set (a test stand-in for a writer the dump does not have).
        b.rippleAdd[0x1ff] = 9
        b.rippleAdd[0x200] = 5
        b.rippleAdd[0x47f] = -3
        b.rippleAdd[0x480] = 9
        b.rippleTable[0x300] = Int32.max
        b.rippleAdd[0x300] = 1
        b.rippleAddEveryCall()
        XCTAssertEqual(b.rippleTable[0x200], before[0x200] + 5)
        XCTAssertEqual(b.rippleTable[0x47f], before[0x47f] - 3)
        XCTAssertEqual(b.rippleTable[0x300], Int32.min, "a 32-bit add")
        XCTAssertEqual([b.rippleTable[0x1ff], b.rippleTable[0x480]], [0, 0])
        // A level without the flag (level 1 — and every built level but 11: levels 1–5 checked here, level 10 in
        // `LevelTenTests`, header 0x26ca = 0): no table, no add, no fill — the compositor's offsets stay 0.
        for n: Int16 in 1...5 {
            let plain = try level(n)
            XCTAssertEqual(plain.header.parallaxRipple, 0, "level \(n)")
            var p = try blitter(plain)
            p.rippleAddEveryCall()
            try p.rippleFill(phase: 0x200)
            XCTAssertTrue(p.rippleTable.isEmpty && p.rippleAdd.isEmpty, "level \(n)")
            XCTAssertEqual(p.ripple(0x200), 0)
        }
    }

    /// The two loops' places in `.PaintFrameWrap`, on level 11's fixture run at "reduce frame rate" (prefs+0 = 1:
    /// every other call undrawn, `FerazelSession.step`; a tick then runs two calls): the fill (M l. 9255–9425) runs on
    /// drawn calls only, from the phase the call found (before its + 0x100 at M l. 9456, ENG §2.5 assert 2); the add
    /// (M l. 9211–9226) runs on every call, drawn or not (assert 1) — seen through a test value in ffbc's row 0x200. The
    /// ticks' level ops are applied one at a time, so the table is read at each call's end (its `.wrapEraseSprites`).
    func testRippleOnlyOnDrawnFrames() throws {
        var prefs = FerazelPrefs()
        prefs.reduceFrameRate = 1
        let (run, services) = try LevelFixtureServices.open(level: 11, leaveOut: Self.level11, prefs: prefs)
        let first = try services.firstPresentedFrame(run)
        let r = first.renderer
        let L = r.level
        XCTAssertEqual(Set(r.parallax.rippleAdd), [0], "ffbc 0 through the level start")
        // The first presented frame's table: the fill at the phase its drawn call found (the tick's last call).
        let phase0 = r.sprites.ripplePhase - 0x100
        XCTAssertEqual(rowsDiffering(r.parallax.rippleTable, try filled(L, phase: phase0)), 0)
        XCTAssertNotEqual(r.parallax.rippleTable[0x200], 0, "the first presented frame is filled")
        r.parallax.rippleAdd[0x200] = 7
        r.parallax.rippleAdd[0x480] = 7          // outside the loops' rows: never added
        var now = first.ticks, drawn = 0, undrawn = 0
        while (drawn < 6 || undrawn < 6) && now < first.ticks + 100 {
            let out = try run.tick(now: now, input: FrontInput())
            now += 1
            for g in out.segments where g.target == .level {
                var phase = r.sprites.ripplePhase, table = r.parallax.rippleTable, isDrawn = false, calls = 0
                for op in g.output.draws {
                    if case .wrapDrawWaterEffects = op {                  // a `.PaintFrameWrap` call begins
                        phase = r.sprites.ripplePhase
                        table = r.parallax.rippleTable
                        isDrawn = false
                        calls += 1
                    }
                    if case .drawParticles = op { isDrawn = true }
                    try r.apply(FrameOps(draws: [op]))
                    guard case .wrapEraseSprites = op, calls > 0 else { continue }
                    XCTAssertEqual(r.sprites.ripplePhase, phase &+ 0x100)
                    if isDrawn {
                        drawn += 1
                        // The add ran too, then the fill overwrote row 0x200: the drawn table is the fill alone, at the
                        // phase before this call's + 0x100.
                        XCTAssertEqual(rowsDiffering(r.parallax.rippleTable, try filled(L, phase: phase)), 0,
                                       "drawn, phase \(phase)")
                    } else {
                        undrawn += 1
                        var want = table
                        want[0x200] &+= 7
                        XCTAssertEqual(rowsDiffering(r.parallax.rippleTable, want), 0, "undrawn, phase \(phase)")
                    }
                    XCTAssertEqual(r.parallax.rippleTable[0x480], 0)
                }
            }
        }
        XCTAssertGreaterThanOrEqual(drawn, 6)
        XCTAssertGreaterThanOrEqual(undrawn, 6)
    }

    // MARK: - ENG §2.6 (6A-T11: built; the proof)

    /// One cell of a synthetic level: FG tile t, BG tile b, overlay (o1, o2) (−1 = none).
    struct Cell { var col: Int, row: Int, t: Int, b: Int, o1: Int = -1, o2: Int = -1 }

    /// Level 11's `Mlvl` with header `0x26c6` = `submerged`, FG kinds patched (`tile` → `kind`, the header table at
    /// 0x28e0) and the given cells written (BG low byte b + 1, FG t + 1, overlay (o1 + 1) | (o2 + 1) << 8).
    private func synthetic(_ base: LevelFile, data: Data, submerged: UInt8, kinds: [Int: Int16],
                           cells: [Cell]) throws -> LevelFile {
        var d = [UInt8](data)
        d[0x26c6] = submerged
        for (tile, kind) in kinds {
            d[0x28e0 + 2 * tile] = UInt8(UInt16(bitPattern: kind) >> 8)
            d[0x28e0 + 2 * tile + 1] = UInt8(UInt16(bitPattern: kind) & 0xff)
        }
        let h = base.header
        let w2 = Int(h.gridWidth), cells2 = w2 * Int(h.gridHeight)
        let grid = LevelFile.headerSize + 2 * (Int(h.pxBackWidth) * Int(h.pxBackHeight) + Int(h.pxMidWidth) * Int(h.pxMidHeight))
        func put(_ map: Int, _ c: Cell, _ v: UInt16) {
            let o = grid + 2 * map * cells2 + 2 * (c.row * w2 + c.col)
            d[o] = UInt8(v >> 8)
            d[o + 1] = UInt8(v & 0xff)
        }
        for c in cells {
            put(0, c, UInt16(c.b + 1))                                              // BG (light byte 0)
            put(1, c, UInt16(c.t + 1))                                              // FG (no crunch bits)
            put(3, c, UInt16(c.o1 + 1) | UInt16(c.o2 + 1) << 8)                     // overlay
        }
        return try LevelFile(id: base.id, data: Data(d))
    }

    /// The seven readers of hdr `0x26c6` (M l. 8825, 9618, 9635, 9728, 9957, 9982, 27043) at their five port sites
    /// (ENG §2.6): on a synthetic water cell of level 11, each site with `0x26c6` = 0 draws as the binary's "plain"
    /// arm and with 1 as its water-table arm. The oracle is the dump's call sequence on the primitive blitters
    /// (`TileBlitters.wrapDraw`) from a zeroed port — for `.RedrawScrollGrid` from its cell clear and BG draw (steps 1
    /// and 2 of `TileGridRenderer`) on — and each site's two arms are shown to differ on the chosen cell.
    func testSubmergedTintSitesMatchDump() throws {
        let res = try LevelFixture.base.get()
        let mlvl = try XCTUnwrap(res.world.resource(type: "Mlvl", id: 11))
        let base = try LevelFile(resource: mlvl)
        XCTAssertEqual(base.header.submergedFaces, 1, "level 11 sets the flag")
        let search = ColorSearch(model: .ruled)
        let fixed = try TileSets.Fixed(resources: res, search: search)
        let sets = try TileSets(level: base, fixed: fixed, resources: res, search: search)
        let tables = try LevelTables.forLevel(base.header, resources: res, search: search, random: { _ in 0 })
        let clear = try TileGridRenderer.loadClearFace(resources: res, search: search)

        // A BG tile of a water kind (200…205) with its table built, and two FG tiles below 0x50 (kind from the header
        // table) whose face and FG-water face draw something: t1 patched to kind 99 (no blend), t2 to kind 1 (blend 1).
        let b = try XCTUnwrap((0..<0x5f).first { (200...205).contains(base.bgKind(tile: $0)) })
        let w = base.bgKind(tile: b) - 200
        func draws(_ f: EncodedFace) throws -> Bool { try f.decode().contains { $0 != 0 } }
        let drawing = try (0..<0x50).filter { try draws(sets.fg.faces[$0]) && draws(sets.fgWater.sheet.faces[$0]) }
        XCTAssertGreaterThanOrEqual(drawing.count, 2)
        let t1 = drawing[0], t2 = drawing[1], k2 = 1
        let water = tables.water[w]
        let bgFace = sets.bg.faces[b]
        let A = Cell(col: 10, row: 6, t: t1, b: b), B = Cell(col: 12, row: 6, t: t2, b: b)
        let C = Cell(col: 14, row: 6, t: 0x5f, b: b), D = Cell(col: 16, row: 6, t: -1, b: b, o1: 100, o2: 0x5f)
        let E = Cell(col: 18, row: 6, t: -1, b: b, o1: 100, o2: t1)
        let scroll = TileBlitters.Scroll(h: 0, v: 0)
        func cellBytes(_ port: [UInt8], _ c: Cell) -> [UInt8] {
            (0..<32).flatMap { j in (0..<32).map { i in port[FramePorts.ringOffset(x: c.col * 32 + i, y: c.row * 32 + j)] } }
        }
        func oracle(_ c: Cell, _ ops: [(EncodedFace, TileBlitters.Op)]) -> [UInt8] {
            var port = [UInt8](repeating: 0, count: FramePorts.width * FramePorts.height)
            for (f, op) in ops { TileBlitters.wrapDraw(f, op, into: &port, x: c.col << 5, y: c.row << 5, scroll: scroll) }
            return cellBytes(port, c)
        }
        let fg = sets.fg.faces, fgWater = sets.fgWater.sheet.faces
        /// `.RedrawScrollGrid`'s tile-port steps before the FG rule (step 1 and 2 of `TileGridRenderer`): the cell
        /// cleared (PICT 1002's bool stamp), then the BG face when the FG face has a transparent pixel.
        func before(_ t: Int) -> [(EncodedFace, TileBlitters.Op)] {
            [(clear, .bool)] + (fg[t].hasTransparentPixel ? [(bgFace, .copy)] : [])
        }
        let periodSix = base.header.patternPeriodSix != 0
        let patternC = sets.pattern.faces[TileGridRenderer.patternTile(col: C.col, row: C.row, periodSix: periodSix)]
        let patternD = sets.pattern.faces[TileGridRenderer.patternTile(col: D.col, row: D.row, periodSix: periodSix)]
        var seen: [String: [[UInt8]]] = [:]          // each site's cell, flag 0 then 1

        for flag: UInt8 in [0, 1] {
            let L = try synthetic(base, data: mlvl.data, submerged: flag, kinds: [t1: 99, t2: Int16(k2)],
                                  cells: [A, B, C, D, E])
            XCTAssertEqual(L.header.submergedFaces, flag)
            XCTAssertEqual([L.fgKind(tile: t1) % 100, L.fgKind(tile: t2) % 100, L.bgKind(tile: b)], [99, k2, 200 + w])
            let grid = TileGridRenderer(level: L, sets: sets, fixed: fixed, tables: tables, clearFace: clear,
                                        drawnH: 0, drawnV: 0, effects: 3)
            let on = flag != 0
            let pattern = TileGridRenderer.patternTile(col: B.col, row: B.row, periodSix: L.header.patternPeriodSix != 0)

            // M l. 9957 (`.RedrawScrollGrid`, t < 95; TileGridRenderer.swift's FG rule): plain FG, or FG through table w.
            var ports = FramePorts()
            for c in [A, B, C] {
                try grid.redrawScrollGrid(top: c.row, left: c.col, right: c.col, bottom: c.row, h: 0, v: 0, ports: &ports)
            }
            func check(_ site: String, _ got: [UInt8], _ want: [UInt8]) {
                XCTAssertEqual(got, want, "M l. \(site), 0x26c6 = \(flag)")
                seen[site, default: []].append(got)
            }
            check("9957", cellBytes(ports.tiles, A), oracle(A, before(t1) + [(fg[t1], on ? .table(water) : .copy)]))
            // M l. 27043 (`.BlitEncFaceX`, mode 0x15 + w): the dry blend with 0x26c6 = 0 (then M l. 9957's arm draws the
            // FG-water face through table w after it), the water blend with 1.
            let blendB: [(EncodedFace, TileBlitters.Op)] = on
                ? [(fg[t2], .table(water)), (grid.blend.faces[k2], grid.blendOp(pattern: pattern, water: water))]
                : [(fg[t2], .copy), (grid.blend.faces[k2], grid.blendOp(pattern: pattern, water: nil)),
                   (fgWater[t2], .table(water))]
            check("27043", cellBytes(ports.tiles, B), oracle(B, before(t2) + blendB))
            // M l. 27043 without the port's `blendOp`: the dry op from the dump's tables (0154 / 015c / 0158 and the
            // plain pattern face), and `.BlitEncFaceTileBlendSpecial` (raw `1002aa00…`) as table w applied to
            // `.BlitEncFaceTileBlend`'s result on the pixels the blend face writes (`.erase` marks them 0xFF).
            let dryOp = TileBlitters.Op.blend(pattern: sets.patternPlain.faces[pattern],
                                              patternWidth: sets.patternPlain.arguments.cellWidth,
                                              quarter: tables.pair(.quarterSprite), half: tables.pair(.average),
                                              threeQuarter: tables.pair(.threeQuarterSprite), water: nil)
            let dry = oracle(B, before(t2) + [(fg[t2], on ? .table(water) : .copy), (grid.blend.faces[k2], dryOp)]
                                + (on ? [] : [(fgWater[t2], .table(water))]))
            let cover = oracle(B, [(grid.blend.faces[k2], .erase)])
            XCTAssertTrue(cover.contains(0xff) && cover.contains(0), "the blend face covers part of the cell")
            XCTAssertEqual(cellBytes(ports.tiles, B), on ? zip(dry, cover).map { $1 == 0xff ? water[Int($0)] : $0 } : dry,
                           "M l. 27043: TileBlend with 0x26c6 = 0, table w after it with 1 (flag \(flag))")
            // M l. 9982 (`.RedrawScrollGrid`, t = 95): the pattern tile plain, or through table w.
            check("9982", cellBytes(ports.tiles, C), oracle(C, before(0x5f) + [(patternC, on ? .table(water) : .copy)]))

            // M l. 9618 (`.PlainWrapFGTile`, t < 95; LightRenderer.swift): plain FG then the FG-water face through
            // table w, or the FG through table w.
            var plain = FramePorts()
            try grid.plainWrapFGTile(col: A.col, row: A.row, scroll: scroll, ports: &plain)
            check("9618", cellBytes(plain.tiles, A),
                  oracle(A, on ? [(fg[t1], .table(water))] : [(fg[t1], .copy), (fgWater[t1], .table(water))]))
            // M l. 27043 through `.PlainWrapFGTile` (M l. 9622–9626, mode (w + 0x15) << 16 | pattern; LightRenderer's
            // blend arm): cell B's tile (kind 1) — FG, the FG-water face, the dry blend with 0; FG through table w and
            // the water blend with 1.
            try grid.plainWrapFGTile(col: B.col, row: B.row, scroll: scroll, ports: &plain)
            let wetOp = TileBlitters.Op.blend(pattern: sets.patternPlain.faces[pattern],
                                              patternWidth: sets.patternPlain.arguments.cellWidth,
                                              quarter: tables.pair(.quarterSprite), half: tables.pair(.average),
                                              threeQuarter: tables.pair(.threeQuarterSprite), water: on ? water : nil)
            check("27043 plain", cellBytes(plain.tiles, B),
                  oracle(B, on ? [(fg[t2], .table(water)), (grid.blend.faces[k2], wetOp)]
                               : [(fg[t2], .copy), (fgWater[t2], .table(water)), (grid.blend.faces[k2], wetOp)]))
            // M l. 9635 (`.PlainWrapFGTile`, t = 95): the pattern tile plain, or through table w.
            try grid.plainWrapFGTile(col: C.col, row: C.row, scroll: scroll, ports: &plain)
            check("9635", cellBytes(plain.tiles, C), oracle(C, [(patternC, on ? .table(water) : .copy)]))
            // M l. 9728 (`.PlainWrapFGOverlayTile`, o2 = 95): the pattern tile plain, or through table w; o2 < 95 (M l.
            // 9715–9726) is tinted under water whatever the flag.
            try grid.plainWrapFGOverlayTile(col: D.col, row: D.row, scroll: scroll, ports: &plain)
            check("9728", cellBytes(plain.tiles, D), oracle(D, [(patternD, on ? .table(water) : .copy)]))
            try grid.plainWrapFGOverlayTile(col: E.col, row: E.row, scroll: scroll, ports: &plain)
            XCTAssertEqual(cellBytes(plain.tiles, E), oracle(E, [(fg[t1], .table(water))]), "M l. 9715, flag \(flag)")

            // M l. 8825 (`.WrapDrawWaterEffects`; WaterEffects.swift, its env from the header): the Enhanced FG-water
            // face only with 0x26c6 = 0 — with 1 the tile itself is tinted (above).
            // (Cell B's tile: its kind 1 is inside the reader's 0…0x5f gate.)
            var e = WaterEffects.Cell()
            e.fgTile = Int32(t2); e.fgKind = Int32(L.fgKind(tile: t2)); e.bgKind = Int32(200 + w)
            e.isWater = 1; e.waterKind = Int32(w); e.overlay1 = -1
            let env = WaterEffects.Env(effects: 1, parity: true, submergedFaces: L.header.submergedFaces, current: 0,
                                       surfaceFlag: 0)
            var rng = FastRand(seed: 1), pool = ParticlePool(), shape: Int16 = 0
            let face = WaterEffects.cell(e, col: B.col, row: B.row, scrollV: 0, env: env, overlay2: { -1 }, rng: &rng,
                                         particles: &pool, dustShape: &shape)
            XCTAssertEqual(face, on ? nil : WaterFaceDraw(cellX: B.col, cellY: B.row, tile: Int16(t2), waterKind: Int16(w)),
                           "8825 flag \(flag)")
            // The same reader with its env built from the header (`WaterEffects.run`, WaterEffects.swift:201): the
            // drawn pair (0, 0), the parity set, Effects 1 — cell B's face only with 0x26c6 = 0.
            let world = SpriteWorld(level: L, seed: 1)
            world.parity = true
            var we = WaterEffects()
            let faces = we.run(world: world, h: 0, v: 0, effects: 1)
            XCTAssertEqual(faces.contains { $0.cellX == B.col && $0.cellY == B.row }, !on, "8825 via the header, flag \(flag)")
        }
        // Wave 6A.2 fix round (D55, item 2): level 11's own header (0x26c6 = 1, not patched) — the light renderer's
        // redraw of a real water cell of the level (`.PlainWrapFGTile` M l. 9618) takes the water arm: the FG face
        // through table w (and a blend with the water table), not the plain face with the FG-water face over it (and
        // the dry blend); on the pattern tile (t = 95, M l. 9635) the pattern through table w, not plain. The cells: the
        // first in reading order with a water BG (kind 200…209) on which the two arms differ — one with an FG tile below
        // 95, one with the pattern tile.
        let real = TileGridRenderer(level: base, sets: sets, fixed: fixed, tables: tables, clearFace: clear,
                                    drawnH: 0, drawnV: 0, effects: 3)
        func arms(_ c: Cell) throws -> (on: [UInt8], off: [UInt8], scroll: TileBlitters.Scroll)? {
            guard (0...0x5f).contains(c.t), (0...0x5f).contains(c.b),
                  (200...209).contains(base.bgKind(tile: c.b)) else { return nil }
            let tw = tables.water[base.bgKind(tile: c.b) - 200]
            let at = TileBlitters.Scroll(h: c.col << 5, v: c.row << 5)
            func paint(_ ops: [(EncodedFace, TileBlitters.Op)]) -> [UInt8] {
                var port = [UInt8](repeating: 0, count: FramePorts.width * FramePorts.height)
                for (f, op) in ops { TileBlitters.wrapDraw(f, op, into: &port, x: c.col << 5, y: c.row << 5, scroll: at) }
                return cellBytes(port, c)
            }
            let pat = TileGridRenderer.patternTile(col: c.col, row: c.row, periodSix: base.header.patternPeriodSix != 0)
            let on: [UInt8], off: [UInt8]
            if c.t < 0x5f {
                let k = base.fgKind(tile: c.t) % 100
                let blend: (Bool) -> [(EncodedFace, TileBlitters.Op)] = { wet in
                    k >= 0 && k < 0x5f ? [(real.blend.faces[k], real.blendOp(pattern: pat, water: wet ? tw : nil))] : []
                }
                on = paint([(fg[c.t], .table(tw))] + blend(true))
                off = paint([(fg[c.t], .copy), (fgWater[c.t], .table(tw))] + blend(false))
            } else {
                on = paint([(sets.pattern.faces[pat], .table(tw))])
                off = paint([(sets.pattern.faces[pat], .copy)])
            }
            return on == off ? nil : (on, off, at)
        }
        var found: [Bool: (cell: Cell, on: [UInt8], off: [UInt8], scroll: TileBlitters.Scroll)] = [:]
        search: for row in 0..<Int(base.header.gridHeight) {
            for col in 0..<Int(base.header.gridWidth) {
                let c = Cell(col: col, row: row, t: base.fgTile(col: col, row: row), b: base.bgTile(col: col, row: row))
                if found[c.t < 0x5f] == nil, let a = try arms(c) { found[c.t < 0x5f] = (c, a.on, a.off, a.scroll) }
                if found.count == 2 { break search }
            }
        }
        for tile in [true, false] {
            let wet = try XCTUnwrap(found[tile], "level 11: a water cell, FG below 95 \(tile), whose two arms differ")
            var live = FramePorts()
            try real.plainWrapFGTile(col: wet.cell.col, row: wet.cell.row, scroll: wet.scroll, ports: &live)
            XCTAssertEqual(cellBytes(live.tiles, wet.cell), wet.on, "level 11's header: the water arm (\(wet.cell))")
            XCTAssertNotEqual(cellBytes(live.tiles, wet.cell), wet.off, "not the plain arm (\(wet.cell))")
        }
        // Each site's two arms draw different cells here (so each assert above tells the arms apart).
        XCTAssertEqual(seen.keys.sorted(), ["27043", "27043 plain", "9618", "9635", "9728", "9957", "9982"])
        for (site, cells) in seen.sorted(by: { $0.key < $1.key }) {
            XCTAssertEqual(cells.count, 2)
            XCTAssertNotEqual(cells.first, cells.last, "M l. \(site): the flag changes the cell")
        }
    }

    /// 6A-T11's switch-off check (ENG §2.6): level 11's fixture with the header patch forcing `0x26c6`
    /// (`submergedFaces`) to 0 — the feature golden's start and frame — changes the feature golden; levels 1–5 hold 0
    /// there (checked here; level 10 too, in `LevelTenTests` — of the built levels only 11 sets it), so nothing reads it
    /// on those levels and their goldens (FrameGoldenTests, Phase2GoldenTests, BootFacesTests) cannot move.
    func testLevel11SubmergedSwitchOff() throws {
        let res = try LevelFixture.base.get()
        for n: Int16 in 1...5 {
            XCTAssertEqual(try LevelFile.load(from: res, level: n).header.submergedFaces, 0, "level \(n)")
        }
        let golden = try FeatureGoldenTests.level11RippleFrame(header: [])
        let off = try FeatureGoldenTests.level11RippleFrame(header: [(offset: 0x26c6, bytes: [0])])
        XCTAssertEqual(off.renderer.level.header.submergedFaces, 0)
        XCTAssertEqual(golden.ticks, off.ticks)
        XCTAssertNotEqual(off.fnv, golden.fnv, "the submerged tint is in the golden's frame")
        XCTAssertEqual(String(golden.fnv, radix: 16), "c92fbe9fb87250c3", "the feature golden")
        // Measured at 6A-RP (FNV-1a 64 of the screen indices, the test colour model): the same tick, 0x26c6 forced to 0.
        XCTAssertEqual(String(off.fnv, radix: 16), "7c7042ee30a1f6d3", "level 11's ripple frame with 0x26c6 forced to 0")
    }

    // MARK: - ENG §5

    /// `.RipplePxBackOffsets` (M l. 8889–8925) is not the river: its only call (M l. 9197–9199) needs hdr `0x271e` ≠ 0,
    /// and all 24 levels hold 0 there (the routine is not transcribed).
    func testNoLevelSetsParallaxMode() throws {
        let res = try LevelFixture.base.get()
        let levels = res.world.resources(of: "Mlvl")
        XCTAssertEqual(levels.count, 24)
        for r in levels {
            let L = try LevelFile(resource: r)
            XCTAssertEqual(L.header.parallaxMode, 0, "level \(r.id)")
            XCTAssertEqual([UInt8](r.data)[0x271e ..< 0x2720], [0, 0], "level \(r.id)")
        }
        // The river's switch is 0x26ca, on levels 11 and 18 only.
        let rippled = try levels.filter { try LevelFile(resource: $0).header.parallaxRipple != 0 }.map(\.id).sorted()
        XCTAssertEqual(rippled, [11, 18])
    }
}

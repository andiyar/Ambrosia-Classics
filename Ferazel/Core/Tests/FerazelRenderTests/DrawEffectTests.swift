import XCTest
import FerazelCore
@testable import FerazelRender

/// E2 (docs/plans/2026-10-10-ferazel-phase2.md): the draw additions — `.WrapDrawSprites` steps 3–5 (draw-effects
/// §1.1: scale re-centring, the hurt flash, the water split), mode 6 (`.BlitEncFaceWaterRipple`, §2.4), the hurt-flash
/// tables (modes 3 / 4, §2.2), `.BlitEncFaceScale` / `.BlitEncFaceRot` (§2.9) with their erase twins, the occluder
/// clip (`.StandardSpriteCleanup` l. 32669–32700), `.DeathEffect @ 10005270` and the Monitor Tool gamma steps
/// (lighting-tables §10), on the committed level 1 (D26). The FNV-1a values are self-derived measurements
/// (2026-10-11, run twice). A missing data file is a FAILURE, never a skip.
final class DrawEffectTests: XCTestCase {

    private static let shared = Result { try TileGridTests.Fixture() }
    private func fixture() throws -> TileGridTests.Fixture { try Self.shared.get() }

    /// A w×h face: pixel (r, c) = 0x20 + ((7r + c) mod 0xc0), every pixel opaque except where `hole(r, c)`.
    private static func synthetic(_ pict: Int16, _ w: Int, _ h: Int, hole: (Int, Int) -> Bool = { _, _ in false })
        throws -> (Int16, FaceSheet) {
        let px = (0..<h).flatMap { r in (0..<w).map { c in hole(r, c) ? 0 : pixel(r, c) } }
        let face = try FaceEncoder.encode(pixels: px, width: w, height: h,
                                          rect: EncodedFace.Rect(top: 0, left: 0, bottom: Int16(h), right: Int16(w)),
                                          sourceId: pict)
        let a = try FaceSheet.Arguments(pict: pict, count: 1, cellWidth: w, cellHeight: h, columns: 1)
        return (pict, FaceSheet(arguments: a, faces: [face], shortCells: [:], clutId: 202))
    }
    private static func pixel(_ r: Int, _ c: Int) -> UInt8 { UInt8(0x20 + (7 * r + c) % 0xc0) }

    /// 8×6 (one transparent pixel at (2, 3)) and 12×40, opaque.
    private static let small = FaceRef(pict: 9101, index: 0, set: .encoded)
    private static let tall = FaceRef(pict: 9102, index: 0, set: .encoded)
    /// 1485's Setup face (`one(0x5cd)`, the radial ball) and the raft 1407 (platform set 0x578, face 7).
    private static let ball = FaceRef(pict: 0x5cd, index: 0, set: .encoded)
    private static let raft = FaceRef(pict: 0x578, index: 7, set: .encoded)
    private static let open = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)

    private static let loadedFaces = Result { () throws -> SpriteBlitter.Faces in
        let f = try TileGridTests.Fixture()
        var sheets = try SpriteBlitter.Faces([SetupFaces.sheet(pict: 0x5cd)!, SetupFaces.sheet(pict: 0x578)!],
                                             resources: f.resources, search: ColorSearch(model: .ruled)).sheets
        for (p, s) in [try synthetic(9101, 8, 6) { $0 == 2 && $1 == 3 }, try synthetic(9102, 12, 40)] { sheets[p] = s }
        return SpriteBlitter.Faces(sheets: sheets)
    }

    private func blitter(effects: Int16 = 3) throws -> SpriteBlitter {
        let f = try fixture()
        return SpriteBlitter(level: f.level, tables: f.tables, faces: try Self.loadedFaces.get(), effects: effects)
    }

    private func fnv1a(_ bytes: [UInt8]) -> String {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return String(h, radix: 16)
    }

    /// The pixels (x, y) where the mask holds 0 (what a draw covered), and their bounding box.
    private func footprint(_ ports: FramePorts) -> (count: Int, minX: Int, minY: Int, maxX: Int, maxY: Int) {
        var n = 0, x0 = Int.max, y0 = Int.max, x1 = Int.min, y1 = Int.min
        for (i, m) in ports.mask.enumerated() where m == 0 {
            let x = i % FramePorts.width, y = i / FramePorts.width
            n += 1; x0 = min(x0, x); y0 = min(y0, y); x1 = max(x1, x); y1 = max(y1, y)
        }
        return (n, x0, y0, x1, y1)
    }

    /// Draws `d` on ports filled with `fill`, then erases it the way the next frame's `.WrapEraseSprites` does (the
    /// sprite moved one pixel): the frame must be all `fill` again (restored from the tiles port), and no mask byte
    /// the draw zeroed may remain 0 (the erase stamps 0xFF there). Returns the drawn ports.
    private func drawAndErase(_ b: SpriteBlitter, _ d: SpriteDraw, fill: UInt8 = 0x33, line: UInt = #line,
                              afterDraw: (inout SpriteSlot) -> Void = { _ in }) throws -> FramePorts {
        var ports = FramePorts(fill: fill)
        try b.wrapDrawSprites([d], h: 0, v: 0, ports: &ports)
        var s = SpriteSlot(type: 1, x: d.x, y: d.y, face: d.face)
        s.mode = d.mode; s.mirrored = d.mirrored; s.clip = d.clip; s.lightOverlay = d.lightOverlay
        s.waterRow = Int32(d.waterRow); s.waterKind = d.waterKind; s.rotation = d.rotation; s.scale = d.scale
        s.noWaterSplit = d.noWaterSplit
        s.recordDrawn()
        s.x += 1
        afterDraw(&s)
        var erased = ports
        try b.wrapEraseSprites([s], h: 0, v: 0, ports: &erased)
        XCTAssertEqual(erased.frame.filter { $0 != fill }.count, 0, "frame restored", line: line)
        let left = zip(ports.mask, erased.mask).filter { $0.0 == 0 && $0.1 != 0xff }.count
        XCTAssertEqual(left, 0, "mask erased under the draw", line: line)
        return ports
    }

    // MARK: - the water split

    func testFullySubmergedDrawsMode6() throws {
        let f = try fixture()
        let b = try blitter()
        let face = try XCTUnwrap(b.faces.face(Self.small))
        // `+0x11c == 1`: one `.WrapDrawFace` with `0x60000 + +0x128` (`1001491c`) — the stored tint and the hurt flash
        // are not drawn.
        let d = SpriteDraw(face: Self.small, x: 200, y: 114, mode: 0x10008, clip: Self.open, waterRow: 1, flash: 5,
                           waterKind: 2)
        let plan = SpriteBlitter.faceCalls(d, face: face)
        XCTAssertEqual(plan.calls, [.init(srcV: 0, srcH: 0, dstV: 114, dstH: 200, w: 8, h: 6, word: 0x60002)])
        XCTAssertNil(plan.light)
        // `.BuildSineTable` (`100201e0..1002024c`): 0 ×5, 1 ×9, 0 ×8, −1 ×9, 0 ×4 (draw-effects §2.4).
        XCTAssertEqual(SpriteBlitter.rippleOffsets,
                       [0, 0, 0, 0, 0] + [Int](repeating: 1, count: 9) + [Int](repeating: 0, count: 8)
                       + [Int](repeating: -1, count: 9) + [0, 0, 0, 0])
        // Mode 6 at phase 0x200: port row y shifts by R[(2 + y) mod 35] — rows 114..116 → R[11..13] = 1, rows
        // 117..119 → R[14..16] = 0 — each pixel through water table 2; the mask pass with the same ripple. The column
        // counter starts at R too, so the window [0, 8) is tested on c + R: a shifted row loses its column 7.
        let ports = try drawAndErase(b, d, fill: 0x77)
        for r in 0..<6 {
            let shift = r < 3 ? 1 : 0
            for c in 0..<8 {
                let o = (114 + r) * FramePorts.width + 200 + c + shift
                if (r == 2 && c == 3) || c + shift >= 8 {
                    XCTAssertEqual([ports.frame[o], ports.mask[o]], [0x77, 0x77], "(\(r), \(c))")
                } else {
                    XCTAssertEqual(ports.frame[o], f.tables.water[2][Int(Self.pixel(r, c))], "(\(r), \(c))")
                    XCTAssertEqual(ports.mask[o], 0, "(\(r), \(c))")
                }
            }
            XCTAssertEqual(ports.frame[(114 + r) * FramePorts.width + 199 + shift], 0x77, "row \(r)")
        }
        XCTAssertEqual(footprint(ports).count, 8 * 6 - 1 - 3)
        // The phase moves the wave one row per frame (`100127ec..100127f4`): at 0x300 row 114 reads R[12] (still 1),
        // row 116 reads R[14] = 0.
        var later = b
        later.ripplePhase = 0x300
        var p2 = FramePorts(fill: 0x77)
        try later.wrapDrawSprites([d], h: 0, v: 0, ports: &p2)
        XCTAssertEqual(p2.frame[116 * FramePorts.width + 200], f.tables.water[2][Int(Self.pixel(2, 0))])
        XCTAssertEqual(p2.frame[115 * FramePorts.width + 201], f.tables.water[2][Int(Self.pixel(1, 0))])
        // Mirrored (`.BlitEncFaceFlipWaterRipple`): column c at x + 7 − c − R.
        var mirrored = d
        mirrored.mirrored = true
        let pm = try drawAndErase(b, mirrored, fill: 0x77)
        XCTAssertEqual(pm.frame[114 * FramePorts.width + 200 + 7 - 0 - 1], f.tables.water[2][Int(Self.pixel(0, 0))])
        XCTAssertEqual(pm.frame[119 * FramePorts.width + 200 + 7 - 5], f.tables.water[2][Int(Self.pixel(5, 5))])
        // `+0x18c` or a stored mode 0xe: no split, the effective word.
        var whole = d
        whole.noWaterSplit = true
        XCTAssertEqual(SpriteBlitter.faceCalls(whole, face: face).calls.map(\.word), [0x30005])
        // The erase reads the **last frame's** `+0x18d` (copied from `+0x18c` at the draw's tail, l. 10391) for the
        // split, and the **current** `+0x128` for the submerged word (l. 10540–10566, `*(short *)(iVar14 + 0x128)`):
        // a sprite drawn whole and cleared of `+0x18c` since is still erased whole (a ripple erase would leave the
        // unshifted rows). The kind only names the water table the back-scratch never reads — not observable.
        _ = try drawAndErase(b, whole, fill: 0x77) { $0.noWaterSplit = false; $0.waterKind = 5 }
        // The ripple index: the draw's `(uint)(…) % 0x23` (`mulhwu`) vs the back-scratch twins' signed `%`
        // (decompile l. 21818): with the phase past 2³¹ the draw still finds a row offset, the erase's index is
        // negative (reads before `_DAT_100a0118`) → refused.
        var wrapped = b
        wrapped.ripplePhase = Int32.min
        var pw = FramePorts(fill: 0x77)
        try wrapped.wrapDrawSprites([d], h: 0, v: 0, ports: &pw)
        var slot = SpriteSlot(type: 1, x: d.x, y: d.y, face: d.face)
        slot.clip = Self.open; slot.waterRow = 1; slot.waterKind = 2
        slot.recordDrawn()
        slot.x += 1
        XCTAssertThrowsError(try wrapped.wrapEraseSprites([slot], h: 0, v: 0, ports: &pw)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .ripplePhase(Int32.min))
        }
    }

    func testPartialWaterSplit() throws {
        let f = try fixture()
        let b = try blitter()
        let face = try XCTUnwrap(b.faces.face(Self.tall))
        // `+0x11c` 20: rows 0..19 with the effective word (height `+0x11c − +0x1bc`, `10014864`), then from row
        // max(20, top) at v − top + 20, height rows − 20, with `0x60000 + kind` (`100148e4`).
        let d = SpriteDraw(face: Self.tall, x: 300, y: 140, mode: 0x10008, clip: Self.open, waterRow: 20, waterKind: 1)
        XCTAssertEqual(SpriteBlitter.faceCalls(d, face: face).calls, [
            .init(srcV: 0, srcH: 0, dstV: 140, dstH: 300, w: 12, h: 20, word: 0x10008),
            .init(srcV: 20, srcH: 0, dstV: 160, dstH: 300, w: 12, h: 20, word: 0x60001),
        ])
        // With a top clip of 4 (burn-away): the upper call keeps height 20 − 4, the lower keeps rows − 20 = 16, as
        // written (rows = 36 visible).
        var burnt = d
        burnt.clip.top = 4
        XCTAssertEqual(SpriteBlitter.faceCalls(burnt, face: face).calls, [
            .init(srcV: 4, srcH: 0, dstV: 144, dstH: 300, w: 12, h: 16, word: 0x10008),
            .init(srcV: 20, srcH: 0, dstV: 160, dstH: 300, w: 12, h: 16, word: 0x60001),
        ])
        let ports = try drawAndErase(b, d)
        // Row 5 (port row 145): tint table 8, unshifted. Row 25 (port row 165): R[(2 + 165) mod 35] = R[27] = −1,
        // water table 1.
        // The counter starts at −1 there, so face column 0 fails the window test (c + R < 0) and is not drawn.
        for c in 0..<12 {
            XCTAssertEqual(ports.frame[145 * FramePorts.width + 300 + c], f.tables.tint[8][Int(Self.pixel(5, c))])
            if c > 0 {
                XCTAssertEqual(ports.frame[165 * FramePorts.width + 300 + c - 1],
                               f.tables.water[1][Int(Self.pixel(25, c))])
            }
        }
        XCTAssertEqual(ports.frame[165 * FramePorts.width + 299], 0x33)
        XCTAssertEqual(ports.frame[165 * FramePorts.width + 311], 0x33)
        // Port rows 160..179 read R[22..34], R[0..6]: 11 shifted rows lose one column each.
        XCTAssertEqual(footprint(ports).count, 12 * 40 - 11)
        // ⚑ P4 (the E2 carry; was "refused by name" `.underwaterLight(20)`): the light pass over a sprite with a water
        // row. No light slot on this fixture and level 1's hdr 0x2706 = 5 → `.DrawLightOverFace`'s closing darken
        // (l. 15106–15152): W 20 > 1 → `.BlitAmbDarkenOverFaceClip(…, min(20, 40), 0)` over rows 0…19, then rows from
        // v + 20, height 40 − 20, last argument 1 — the underwater variant shifts each row by the same R as the mode-6
        // draw (raw `1001e5f8..1001e624`: R[((phase >> 8) + port row) % 35]), so the darken lands on the drawn pixels.
        var lit = d
        lit.lightOverlay = true
        let lb = try blitter(effects: 1)
        var p = FramePorts(fill: 0x33)
        try lb.wrapDrawSprites([lit], h: 0, v: 0, ports: &p)
        let slab = lb.lights.ambientSlab(lb.lights.darkness(x: 300 + 6, y: 140 + 20))
        XCTAssertNotEqual(slab[0x33], 0x33)
        for c in 0..<12 {
            XCTAssertEqual(p.frame[145 * FramePorts.width + 300 + c], slab[Int(f.tables.tint[8][Int(Self.pixel(5, c))])])
            if c > 0 {
                XCTAssertEqual(p.frame[165 * FramePorts.width + 300 + c - 1],
                               slab[Int(f.tables.water[1][Int(Self.pixel(25, c))])], "c \(c)")
            }
        }
        XCTAssertEqual(p.frame[165 * FramePorts.width + 299], 0x33)
        XCTAssertEqual(p.frame[165 * FramePorts.width + 311], 0x33)        // an unshifted darken would reach it
        // With a light that meets the face (slot 0: a 64×64 light, pixel (r, c) = 0xf5 + c mod 8, at (312, 162) radius
        // 32 → light offset row 140 − 130 = 10, column 300 − 280 = 20; colour 0): `.BlitLightOverFaceClip` over rows
        // 0…19, then from row 20 with the last argument 1 (l. 15240–15270) — the destination and the column window
        // shift by R, the light column stays offCol + c (raw `1001dcb0..1001dce8`: `in_r11` and the port pointer take
        // R, `iVar10` restarts at offCol).
        var lb2 = lb
        let light = LightFace(pict: 1, width: 64, height: 64,
                              pixels: (0..<64 * 64).map { UInt8(0xf5 + ($0 % 64) % 8) })
        lb2.lights.slots[0].active = true
        lb2.lights.slots[0].face = light
        lb2.lights.slots[0].x = 312
        lb2.lights.slots[0].y = 162
        lb2.lights.slots[0].radius = 32
        var q = FramePorts(fill: 0x33)
        try lb2.wrapDrawSprites([lit], h: 0, v: 0, ports: &q)
        let D = lb2.lights.darkness(x: 306, y: 160)
        func lightened(_ lightRow: Int, _ lightCol: Int, _ d: UInt8) -> UInt8 {
            f.tables.light[D * 0x6e00 + (Int(light.pixel(row: lightRow, col: lightCol)) - 0xf5) * 0x100 + Int(d)]
        }
        for c in 0..<12 {
            XCTAssertEqual(q.frame[145 * FramePorts.width + 300 + c], lightened(15, 20 + c, f.tables.tint[8][Int(Self.pixel(5, c))]))
            if c > 0 {
                XCTAssertEqual(q.frame[165 * FramePorts.width + 300 + c - 1],
                               lightened(35, 20 + c, f.tables.water[1][Int(Self.pixel(25, c))]), "c \(c)")
            }
        }
        XCTAssertEqual(q.frame[165 * FramePorts.width + 311], 0x33)
    }

    // MARK: - the hurt flash

    func testHurtFlashTables() throws {
        let f = try fixture()
        // `+0xaa` 13, counted down by `.StandardSpriteHandles` (`10036880..10036890`) after each draw: n = min(`+0xaa`,
        // 7) → tables 7,7,7,7,7,7,7,6,5,4,3,2,1 (`0x30000 + n`), then the stored word again.
        let world = SpriteWorld(level: f.level)
        var slot = SpriteSlot(type: 1, x: 100, y: 100, face: Self.small)
        slot.mode = 0x10008
        slot.flash = 13
        let id = world.active.insert(slot)
        var tables: [UInt32] = []
        for _ in 0..<14 {
            let d = try XCTUnwrap(world.active.record(id: id)?.draw)
            tables.append(SpriteBlitter.effectiveWord(d))
            world.standardSpriteHandles(id)
        }
        XCTAssertEqual(tables, [7, 7, 7, 7, 7, 7, 7, 6, 5, 4, 3, 2, 1].map { 0x30000 + $0 } + [0x10008])
        // `+0x1b4`: `0x40000 + 2n` (redden B).
        var heavy = SpriteDraw(face: Self.small, x: 100, y: 100, clip: Self.open, flash: 9, flashTable: 1)
        XCTAssertEqual(SpriteBlitter.effectiveWord(heavy), 0x4000e)
        heavy.flash = 3
        XCTAssertEqual(SpriteBlitter.effectiveWord(heavy), 0x40006)
        // A `+0x89` sprite's light word overwrites the flash (`1001472c..100147bc`): Core passes flash 0.
        var lit = SpriteSlot(type: 1, x: 0, y: 0, face: Self.small)
        lit.dynamicLight = true
        lit.flash = 6
        XCTAssertEqual(lit.draw?.flash, 0)
        // The pixels: mode 3 sub n → redden A n, mode 4 sub 2n → redden B 2n (`.BlitEncFaceSpecial*` cases 3, 4).
        let b = try blitter()
        var pa = FramePorts(fill: 0x77), pb = FramePorts(fill: 0x77)
        try b.wrapDrawSprites([SpriteDraw(face: Self.small, x: 100, y: 50, clip: Self.open, flash: 5)], h: 0, v: 0,
                              ports: &pa)
        try b.wrapDrawSprites([SpriteDraw(face: Self.small, x: 100, y: 50, clip: Self.open, flash: 5, flashTable: 1)],
                              h: 0, v: 0, ports: &pb)
        for r in 0..<6 { for c in 0..<8 where !(r == 2 && c == 3) {
            let o = (50 + r) * FramePorts.width + 100 + c
            XCTAssertEqual(pa.frame[o], f.tables.reddenA[5][Int(Self.pixel(r, c))])
            XCTAssertEqual(pb.frame[o], f.tables.reddenB[10][Int(Self.pixel(r, c))])
            XCTAssertEqual(pa.mask[o], 0)
        } }
    }

    // MARK: - scale and rotation

    func testScaledFace() throws {
        let b = try blitter()
        let face = try XCTUnwrap(b.faces.face(Self.ball))
        var results: [String] = []
        for scale: Int16 in [149, 254] {
            let d = SpriteDraw(face: Self.ball, x: 260, y: 120, clip: Self.open, scale: scale)
            // Step 3: scale < 0x100 with no rotation moves the point by (extent · (0x100 − scale)) >> 9.
            let k = 0x100 - Int(scale)
            XCTAssertEqual(SpriteBlitter.faceCalls(d, face: face).calls,
                           [.init(srcV: 0, srcH: 0, dstV: 120 + (face.height * k) >> 9,
                                  dstH: 260 + (face.width * k) >> 9, w: face.width, h: face.height, word: 0)])
            let ports = try drawAndErase(b, d)
            let fp = footprint(ports)
            results.append("\(scale): \(fp.count) (\(fp.minX), \(fp.minY))–(\(fp.maxX), \(fp.maxY)) \(fnv1a(ports.frame + ports.mask))")
            // A reduction only: the image fits the re-centred window scaled by scale/256 (+1 row/column).
            XCTAssertLessThanOrEqual(fp.maxX - fp.minX + 1, face.width * Int(scale) / 256 + 1)
            XCTAssertLessThanOrEqual(fp.maxY - fp.minY + 1, face.height * Int(scale) / 256 + 2)
        }
        // Measured 2026-10-11 (E2, two runs): the ball (100 × 100, opaque bounds (18, 0, 81, 94)) at (260, 120). Drawn
        // unscaled it covers 3,495 pixels at (261, 138)–(352, 200); at 254 the first source pixel of each row only
        // primes the accumulator, so the image sits one column left with no pixel lost yet; at 149 it shrinks to
        // 54 × 37, re-centred by (100 · 107) >> 9 = 20.
        XCTAssertEqual([face.width, face.height], [100, 100])
        XCTAssertEqual(results, ["149: 1209 (280, 151)–(333, 187) 39a1dea3dda8e0e1",
                                 "254: 3495 (260, 138)–(351, 200) f5a8f5f74980bd6d"])
        // Scale > 0x100 cannot enlarge (`0x100 < scale` only forces the rotated-rect clip test): pixel for pixel the
        // unscaled draw.
        var unit = FramePorts(fill: 0x33), over = FramePorts(fill: 0x33)
        try b.wrapDrawSprites([SpriteDraw(face: Self.raft, x: 240, y: 150, clip: Self.open)], h: 0, v: 0, ports: &unit)
        try b.wrapDrawSprites([SpriteDraw(face: Self.raft, x: 240, y: 150, clip: Self.open, scale: 0x101)], h: 0, v: 0,
                              ports: &over)
        XCTAssertEqual(over, unit)
        // The accumulators compare as shorts (`extsh; cmpwi 0x100`, raw `1002c14c..50`, `1002c060..64`): a 200-px
        // skip at scale 0xff adds 51,000 — negative as a short — so the skip advances nothing and no later pixel of
        // the row passes 0xff either; at 0x80 the skip advances 100 columns and every 2nd pixel lands.
        let (_, longSkip) = try Self.synthetic(9103, 210, 1) { _, c in c < 200 }
        func columns(_ scale: Int16) -> [Int] {
            var at: [Int] = []
            SpriteBlitter.scaleWalk(longSkip.faces[0], src: (0, 0), dst: (10, 0), w: 210, h: 1, scale: scale) { o, _ in
                at.append(o - 10 * FramePorts.width)
            }
            return at
        }
        XCTAssertEqual(columns(0xff), [])
        XCTAssertEqual(columns(0x80), [100, 101, 102, 103, 104])
        // Mode 0xc under scale reads its table (the Scale switch, `0xc` arm); mode 5 has none → refused.
        var p = FramePorts()
        XCTAssertNoThrow(try b.wrapDrawSprites([SpriteDraw(face: Self.ball, x: 260, y: 120, mode: 0xc0300,
                                                           clip: Self.open, scale: 149)], h: 0, v: 0, ports: &p))
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ball, x: 260, y: 120, mode: 0x50002,
                                                               clip: Self.open, scale: 149)], h: 0, v: 0, ports: &p)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .mode(0x50002))
        }
    }

    func testRotatedFace() throws {
        let b = try blitter()
        let face = try XCTUnwrap(b.faces.face(Self.raft))
        XCTAssertEqual([face.width, face.height], [0x50, 0x29])
        // The cos/sin tables: (π·(2·i))/360 with π = 3.1415926535 as stored.
        XCTAssertEqual(SpriteBlitter.cosTable[0], 1)
        XCTAssertEqual(SpriteBlitter.sinTable[0], 0)
        var results: [String] = []
        for (rot, flip) in [(Int16(8), false), (Int16(352), false), (Int16(8), true)] {
            let d = SpriteDraw(face: Self.raft, x: 240, y: 150, mirrored: flip, clip: Self.open, rotation: rot)
            let ports = try drawAndErase(b, d)
            let fp = footprint(ports)
            results.append("\(rot)\(flip ? "f" : ""): \(fp.count) (\(fp.minX), \(fp.minY))–(\(fp.maxX), \(fp.maxY)) \(fnv1a(ports.frame + ports.mask))")
        }
        // Measured 2026-10-11 (E2, two runs): the raft face (80 × 41, opaque bounds (0, 1, 29, 78); unrotated 1,634
        // pixels at (242, 150)–(316, 178)) about its frame centre (40, 20), each source pixel written two wide.
        // Mirrored, 8° is drawn as 352° with x negated.
        XCTAssertEqual(results, ["8: 1518 (243, 146)–(316, 182) c7b3a31b79554f82",
                                 "352: 1517 (242, 148)–(318, 179) b25c25d2e5184a5b",
                                 "8f: 1517 (243, 148)–(319, 179) e8eea9a4d6c87293"])
        // The clip flag (`.BlitEncFaceX` l. 26862–26944): the frame at the point grown by S = 80 — top/bottom by
        // (int)(80·|sin 8°|) = 11.13…, left/right by 80·|cos 8°| = 79.22…, each edge `fctiwz` (toward zero) — must lie in
        // (0, 0, 416, 640). h 79 → left (int)(−0.22) = 0 holds, h 78 → −1 fails; v 11 → 0 holds, v 10 → −1 fails; right
        // 79.22 + h + 80: 640 at h 481 holds, 641 at 482 fails.
        func clip(_ v: Int, _ h: Int, rot: Int16 = 8, scale: Int16 = 0x100) throws -> Bool {
            try SpriteBlitter.clipFlag(face, src: (0, 0), dst: (v, h), w: 80, h: 41, mode: 0, rotation: rot, scale: scale)
        }
        XCTAssertEqual(try [clip(20, 80), clip(20, 79), clip(20, 78), clip(11, 100), clip(10, 100), clip(20, 481),
                            clip(20, 482), clip(364, 100), clip(365, 100)],
                       [false, false, true, false, true, false, true, false, true])
        // `0x100 < scale` (not ≥): at 0x100 no growth test, at 0x101 rotation 0 grows left/right by S·|cos 0| = 80.
        XCTAssertEqual(try [clip(20, 0, rot: 0, scale: 0x100), clip(20, 0, rot: 0, scale: 0x101),
                            clip(20, 80, rot: 0, scale: 0x101)], [false, true, false])
        XCTAssertTrue(try SpriteBlitter.clipFlag(face, src: (0, 1), dst: (20, 80), w: 79, h: 41, mode: 0, rotation: 0,
                                                 scale: 0x100))
        // The two-pixel write needs x < 639 (`cmpw r8,r16` raw `1002afe0`): at angle 0 the walk is the identity, so
        // the small face at h 633 puts column 5 at 638 (two wide) and column 6 at 639 (one, not into the next row).
        let small = try XCTUnwrap(b.faces.face(Self.small))
        var two: [Int: Bool] = [:]
        try SpriteBlitter.rotWalk(small, src: (0, 0), dst: (100, 633), w: 8, h: 6, rotation: 0, scale: 0x100,
                                  flip: false, clip: true, columns: 8) { o, t, _ in
            if o / FramePorts.width == 100 { two[o % FramePorts.width] = t }
        }
        XCTAssertEqual(two, [633: true, 634: true, 635: true, 636: true, 637: true, 638: true, 639: false])
        // A rotation outside the 360-entry tables is refused (the original reads past them).
        var p = FramePorts()
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.raft, x: 0, y: 0, clip: Self.open,
                                                               rotation: 360)], h: 0, v: 0, ports: &p)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .rotation(360))
        }
    }

    // MARK: - the occluder

    func testOccluderClipsFace() throws {
        let f = try fixture()
        // `.StandardSpriteCleanup` (l. 32669–32700): the sprite's centre left of the occluder's middle → `+0x1b8 =
        // +0x1be − x`; the draw keeps face columns < 5 (the step-2 window).
        let world = SpriteWorld(level: f.level)
        var slot = SpriteSlot(type: 1, x: 100, y: 50, face: Self.small)
        slot.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 6, right: 8)
        slot.occluder = SpriteSlot.Occluder(left: 105, right: 140, bottom: 80, top: 40)
        let id = world.active.insert(slot)
        world.standardSpriteCleanup(id, faceWidth: { _ in 8 })
        let d = try XCTUnwrap(world.active.record(id: id)?.draw)
        XCTAssertEqual(d.clip, SpriteClip(left: 0, right: 5, bottom: 32000, top: 0))
        XCTAssertEqual(d.occluder, SpriteSlot.Occluder(left: 105, right: 140, bottom: 80, top: 40))
        var ports = FramePorts(fill: 0x77)
        try blitter().wrapDrawSprites([d], h: 0, v: 0, ports: &ports)
        for r in 0..<6 { for c in 0..<8 {
            let o = (50 + r) * FramePorts.width + 100 + c
            XCTAssertEqual(ports.frame[o], c < 5 && !(r == 2 && c == 3) ? Self.pixel(r, c) : 0x77, "(\(r), \(c))")
        } }
        // Past the middle: `+0x1b6 = +0x1c0 − x` (≤ the face width) — the columns right of the occluder stay.
        var right = SpriteSlot(type: 1, x: 136, y: 50, face: Self.small)
        right.hotRect = slot.hotRect
        right.occluder = slot.occluder
        let id2 = world.active.insert(right)
        world.standardSpriteCleanup(id2, faceWidth: { _ in 8 })
        XCTAssertEqual(world.active.record(id: id2)?.clip, SpriteClip(left: 4, right: 32000, bottom: 32000, top: 0))
        // No occluder (the `.InitSprite` 32000s): nil in the seam, no clip.
        XCTAssertNil(SpriteSlot(type: 1, x: 0, y: 0, face: Self.small).draw?.occluder)
    }

    // MARK: - the death wipe and the gamma

    func testDeathEffectSteps() throws {
        let black: UInt8 = 0x60
        let wipe = DeathEffect(foreColor: black)
        var screen = IndexedFrame(fill: 7)
        var gammas: [DrawOp?] = []
        for k in 0..<DeathEffect.steps {
            var fresh = IndexedFrame(fill: 7)
            wipe.frame(step: k, on: &fresh)
            let i = 4 * k
            // Black bands at 8 + 4k (top), 392 − 4k (bottom), 16 + 4k (left), 624 − 4k (right), 4 px each.
            XCTAssertEqual(DeathEffect.blackBands(step: k), [
                .init(left: 16, top: 8 + i, right: 624, bottom: 12 + i),
                .init(left: 16, top: 388 - i, right: 624, bottom: 392 - i),
                .init(left: 16 + i, top: 8, right: 20 + i, bottom: 392),
                .init(left: 620 - i, top: 8, right: 624 - i, bottom: 392),
            ])
            for band in DeathEffect.blackBands(step: k) {
                for y in band.top..<band.bottom { for x in band.left..<band.right {
                    XCTAssertEqual(fresh[x, y], black, "step \(k) (\(x), \(y))")
                } }
            }
            // From step 2 the gray `qd+0xb2` patOr bands 8 px ahead of each black band: (x + y) even → black, odd
            // untouched (M l. 2706–2720); none before.
            let gray = DeathEffect.grayBands(step: k)
            XCTAssertEqual(gray.count, k > 1 ? 4 : 0)
            if k > 1 {
                // `OffsetRect` (l. 2708–2711): top (0, 8), bottom (0, −8), left (8, 0), right (−8, 0).
                XCTAssertEqual(gray, [.init(left: 16, top: 16 + i, right: 624, bottom: 20 + i),
                                      .init(left: 16, top: 380 - i, right: 624, bottom: 384 - i),
                                      .init(left: 24 + i, top: 8, right: 28 + i, bottom: 392),
                                      .init(left: 612 - i, top: 8, right: 616 - i, bottom: 392)])
                let y = gray[0].top + 1                                               // 17 + 4k: no black band
                XCTAssertEqual(fresh[321, y], black, "step \(k)")                      // (x + y) even
                XCTAssertEqual(fresh[320, y], 7, "step \(k)")
            } else {
                XCTAssertEqual(fresh[300, 8 + i + 9], 7)
            }
            gammas.append(wipe.frame(step: k, on: &screen))
        }
        // The last band is at 196 (i = 4·49); together the 50 steps blacken the whole 608×384 view.
        XCTAssertEqual(DeathEffect.blackBands(step: 49)[0].top, 8 + 196)
        for y in 8..<392 { for x in 16..<624 where screen[x, y] != black { return XCTFail("(\(x), \(y)) not black") } }
        XCTAssertEqual(screen[15, 8], 7)
        XCTAssertEqual(screen[16, 7], 7)
        XCTAssertEqual(screen[624, 391], 7)
        // `.GammaFadeOutAsync(0x30, black)` + one `.HandleAsyncGammaFade` per step: frames 0…48, none at 49.
        XCTAssertEqual(Array(gammas.prefix(49)), (0...48).map {
            Optional(DrawOp.gammaStep(numerator: $0, denominator: 0x30, toward: RGB16(0, 0, 0)))
        })
        XCTAssertNil(gammas[49])

        // On the renderer (the A3 seam): `deathEffectStep(k)` paints step k on `screen` and applies its gamma step.
        let f = try fixture()
        let r = try FrameRenderer(resources: f.resources, level: 1, search: ColorSearch(model: .ruled),
                                  dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer())
        XCTAssertThrowsError(try r.deathEffectStep(0)) {
            XCTAssertEqual($0 as? FrameRenderer.Refusal, .tintTableNotBuilt)
        }
        let s = try FerazelSession(resources: f.resources, prefs: FerazelPrefs(), level: 1, faceBounds: r.faceBounds)
        try r.buildTintTable(s.tintTableDraws)
        let painter = r.deathEffect
        XCTAssertEqual(painter.foreColor, ColorSearch(model: .ruled).index(of: RGB16(0, 0, 0), in: r.screenClut))
        var expected = r.screen
        var g = ScreenGamma.identity
        for k in 0..<DeathEffect.steps {
            try r.deathEffectStep(k)
            if case .gammaStep(let n, let d, let t)? = painter.frame(step: k, on: &expected) {
                g.step(numerator: n, denominator: d, toward: t)
            }
            XCTAssertEqual(r.executed, k <= 0x30 ? [.gamma(numerator: k, denominator: 0x30)] : [], "step \(k)")
        }
        XCTAssertEqual(r.screen, expected)
        XCTAssertEqual(r.gamma, g)
        XCTAssertTrue(r.presentedClut.entries.allSatisfy { $0.rgb == [0, 0, 0] })   // faded fully to black
        for k in [-1, DeathEffect.steps] {
            XCTAssertThrowsError(try r.deathEffectStep(k)) {
                XCTAssertEqual($0 as? FrameRenderer.Refusal, .deathEffectStep(k))
            }
        }
    }

    func testGammaStepScalesCLUT() throws {
        let f = try fixture()
        let c202 = try ColorLUT.load(id: 202, from: f.resources, chain: .level)
        let white = try XCTUnwrap(c202.entries.firstIndex { $0.rgb == [0xffff, 0xffff, 0xffff] })
        let black = RGB16(0, 0, 0)
        // `FadeToColor(black, j·100/N)`, compounding: 10/40 → 25 % (gain 0.75), then 20/40 → 50 % more (0.375).
        var g = ScreenGamma.identity
        g.step(numerator: 10, denominator: 40, toward: black)
        XCTAssertEqual(g.apply(c202).entries[white].rgb, [49151, 49151, 49151])   // trunc(0.75 · 65535)
        g.step(numerator: 20, denominator: 40, toward: black)
        XCTAssertEqual(g.apply(c202).entries[white].rgb, [24575, 24575, 24575])   // trunc(0.375 · 65535)
        // The C quotient: 1/3 → 33 %.
        var third = ScreenGamma.identity
        third.step(numerator: 1, denominator: 3, toward: black)
        XCTAssertEqual(third.apply(0xffff, channel: 0), 43908)                     // trunc(0.67 · 65535)
        // Toward a colour: 50 % to (0x8000, 0, 0) → v/2 + 0x4000 in red.
        var red = ScreenGamma.identity
        red.step(numerator: 1, denominator: 2, toward: RGB16(0x8000, 0, 0))
        XCTAssertEqual([red.apply(0xffff, channel: 0), red.apply(0xffff, channel: 1)], [49151, 32767])
        // The fade-in (`toward` nil) back to the original: at 100 % exactly the identity.
        g.step(numerator: 40, denominator: 40, toward: nil)
        XCTAssertEqual(g.apply(c202), c202)
        XCTAssertEqual(ScreenGamma.identity.apply(c202), c202)
        // Through the renderer: the op moves `gamma`; `presentedClut` and `rgba(through:gamma:)` show it; the 8-bit
        // screen is untouched; `.DeathEffect`'s fore colour is `Color2Index(black)` in the screen CLUT.
        let r = try FrameRenderer(resources: f.resources, level: 1, search: ColorSearch(model: .ruled),
                                  dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer())
        try r.buildTintTable(try FerazelSession(resources: f.resources, prefs: FerazelPrefs(), level: 1,
                                                faceBounds: r.faceBounds).tintTableDraws)
        let before = r.screen
        try r.apply(FrameOps(draws: [.gammaStep(numerator: 10, denominator: 40, toward: black)]))
        XCTAssertEqual(r.executed, [.gamma(numerator: 10, denominator: 40)])
        XCTAssertEqual(r.presentedClut.entries[white].rgb, [49151, 49151, 49151])
        XCTAssertEqual(r.presentedClut.entries.map(\.value), (0..<256).map(UInt16.init))
        XCTAssertEqual(r.screen, before)
        let frame = IndexedFrame(fill: UInt8(white))
        XCTAssertEqual(frame.rgba(through: r.screenClut, gamma: r.gamma)[0], 0xffbf_bfbf)
        XCTAssertEqual(frame.rgba(through: r.presentedClut)[0], 0xffbf_bfbf)
        XCTAssertEqual(r.deathEffect.foreColor, ColorSearch(model: .ruled).index(of: black, in: c202))
    }
}

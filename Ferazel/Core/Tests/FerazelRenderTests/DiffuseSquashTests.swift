import XCTest
import FerazelCore
@testable import FerazelRender

/// Draw modes 5 and 0xa (draw-effects §2.3, §2.6): `.BlitEncFaceDiffuse @ 10029988` / `.BlitEncFaceFlipDiffuse @
/// 10029c6c` — per literal pixel `FastRand(30) < n` → `0x99 + FastRand(6)`, else the source, the randoms drawn from the
/// game's one stream at `.WrapDrawSprites` time — and `.BlitEncFaceSpecialClipX @ 100271d4`'s mode-10 squash with
/// `.BlitEncBoolFaceClip @ 10023574`'s squashed mask. Synthetic faces over level 1's tables; then the player's
/// teleporter sparkle (level 1) and a springboard gauge (level 3) through the real session + renderer. A missing data
/// file is a FAILURE, never a skip.
final class DiffuseSquashTests: XCTestCase {

    private static let shared = Result { try TileGridTests.Fixture() }
    private func fixture() throws -> TileGridTests.Fixture { try Self.shared.get() }
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// An 8×6 face: pixel (r, c) = 0x20 + 8r + c, except (0, 0), (2, 3), (5, 7) transparent (0).
    private static let w = 8, h = 6
    private static func pixel(_ r: Int, _ c: Int) -> UInt8 {
        [(0, 0), (2, 3), (5, 7)].contains { $0 == (r, c) } ? 0 : UInt8(0x20 + 8 * r + c)
    }
    private static let ref = FaceRef(pict: 9001, index: 0, set: .encoded)
    private static let open = SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0)

    private func blitter(_ f: TileGridTests.Fixture) throws -> SpriteBlitter {
        let px = (0..<Self.h).flatMap { r in (0..<Self.w).map { c in Self.pixel(r, c) } }
        let face = try FaceEncoder.encode(pixels: px, width: Self.w, height: Self.h,
                                          rect: EncodedFace.Rect(top: 0, left: 0, bottom: Int16(Self.h),
                                                                 right: Int16(Self.w)), sourceId: 9001)
        let a = try FaceSheet.Arguments(pict: 9001, count: 1, cellWidth: Self.w, cellHeight: Self.h, columns: 1)
        let faces = SpriteBlitter.Faces(sheets: [9001: FaceSheet(arguments: a, faces: [face], shortCells: [:],
                                                                 clutId: 202)])
        return SpriteBlitter(level: f.level, tables: f.tables, faces: faces, effects: 3)
    }

    private func at(_ port: [UInt8], _ x: Int, _ y: Int) -> UInt8 { port[FramePorts.ringOffset(x: x, y: y)] }

    /// The FastRand steps from `seed` to `end` (nil past `limit`).
    private func steps(from seed: Int32, to end: Int32, limit: Int = 10_000) -> Int? {
        var r = FastRand(seed: seed)
        for k in 0...limit {
            if r.seed == end { return k }
            _ = r.next(30)
        }
        return nil
    }

    // MARK: - mode 5

    /// Each opaque pixel, in token order (rows down, source columns left to right — also when flipped), takes
    /// `FastRand(30)`; below n a second `FastRand(6)` gives 0x99 + r, else the source pixel. The mask pass writes 0
    /// under the silhouette. Window, flip and port clip as `.BlitEncFaceClipX`.
    func testDiffuseRuleOrderFlipAndClip() throws {
        let f = try fixture()
        let b = try blitter(f)
        let seed: Int32 = 0x1234_5678
        for (n, flip, x, top) in [(0, false, 200, 0), (7, false, 200, 0), (15, true, 200, 0), (30, false, 200, 0),
                                  (9, false, -3, 0), (9, true, -3, 2), (12, false, 600, 1)] {
            var ports = FramePorts(fill: 0x55)
            let clip = SpriteClip(left: 0, right: 32000, bottom: 32000, top: top)
            let d = SpriteDraw(face: Self.ref, x: x, y: 100, mode: 0x50000 | UInt32(n), mirrored: flip, clip: clip,
                               randomSeed: seed)
            try b.wrapDrawSprites([d], h: 0, v: 0, ports: &ports)
            // The expected picture: the stream replayed over the visible opaque pixels in token order.
            var rng = FastRand(seed: seed)
            var visited = 0
            for r in top..<Self.h {
                for c in 0..<Self.w {
                    let dc = flip ? Self.w - 1 - c : c, wx = x + dc, wy = 100 + r
                    let p = Self.pixel(r, c)
                    // `.WrapDrawFace` clips at the scroll's left edge (h = 0) and at h + 0x280 on the right.
                    let visible = p != 0 && wx >= 0 && wx < 0x280
                    if !visible { continue }
                    visited += 1
                    let want: UInt8 = rng.next(30) < Int16(n) ? UInt8(0x99 + Int(rng.next(6))) : p
                    XCTAssertEqual(at(ports.frame, wx, wy), want, "n \(n) flip \(flip) x \(x) (\(r), \(c))")
                    XCTAssertEqual(at(ports.mask, wx, wy), 0, "mask n \(n) (\(r), \(c))")
                    if n >= 30 { XCTAssertTrue((0x99...0x9e).contains(want)) }
                }
            }
            XCTAssertGreaterThan(visited, 10)
            // The dry run Core calls advances the stream exactly as far as the draw did.
            var dry = FastRand(seed: seed)
            b.diffuseRandoms(d, h: 0, v: 0, rng: &dry)
            XCTAssertEqual(dry.seed, rng.seed, "dry run n \(n) flip \(flip) x \(x)")
            if n == 0 { XCTAssertEqual(steps(from: seed, to: dry.seed), visited) }
            // The transparent (0, 0) keeps the fill.
            if top == 0 && x >= 0 { XCTAssertEqual(at(ports.frame, x + (flip ? Self.w - 1 : 0), 100), 0x55) }
        }
        // No seed handed over: refused, not drawn from another stream; a scaled mode-5 draw (Scale with an undefined
        // table register) stays refused.
        var ports = FramePorts()
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 0, y: 0, mode: 0x50003, clip: Self.open)],
                                                   h: 0, v: 0, ports: &ports)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .diffuseSeed)
        }
        XCTAssertThrowsError(try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 0, y: 0, mode: 0x50003, clip: Self.open,
                                                               scale: 0x80, randomSeed: 1)],
                                                   h: 0, v: 0, ports: &ports)) {
            XCTAssertEqual($0 as? SpriteBlitter.Refusal, .mode(0x50003))
        }
    }

    /// The dry run follows the draw over the ring copies, the view clip and the water split (the submerged rows are
    /// mode 6, no randoms): with n = 0 every visited pixel takes one `FastRand(30)`, so its step count is the number of
    /// mask bytes the draw zeroed in mode 5.
    func testDryRunMatchesDrawEverywhere() throws {
        let f = try fixture()
        let b = try blitter(f)
        // Ring copies: x mod 640 past 632 (a second copy at h − 640), y mod 416 past 410 (at v − 416), both.
        for (x, y, h, v, flip, water) in [(200, 100, 0, 0, false, 0), (636, 100, 100, 0, false, 0),
                                          (200, 412, 0, 100, true, 0), (637, 413, 100, 100, false, 0),
                                          (1270, 830, 640, 420, true, 0), (-4, -2, 0, 0, false, 0),
                                          (300, 200, 0, 0, false, 3), (605, 380, 0, 0, true, 0)] {
            var ports = FramePorts(fill: 0x55)
            let d = SpriteDraw(face: Self.ref, x: x, y: y, mode: 0x50000, mirrored: flip, clip: Self.open,
                               waterRow: water, randomSeed: 99)
            try b.wrapDrawSprites([d], h: h, v: v, ports: &ports)
            var dry = FastRand(seed: 99)
            b.diffuseRandoms(d, h: h, v: v, rng: &dry)
            // Mode-5 rows only: under a water split the submerged rows draw in mode 6 and zero the mask too.
            let zeroed = water == 0 ? ports.mask.filter { $0 == 0 }.count
                : (0..<water).reduce(0) { n, r in n + (0..<Self.w).filter { Self.pixel(r, $0) != 0 }.count }
            XCTAssertEqual(steps(from: 99, to: dry.seed), zeroed, "(\(x), \(y)) at (\(h), \(v))")
        }
    }

    // MARK: - mode 0xa

    /// The squash: source row j lands on destination row 0 (j = 0) or 1 + ⌊j·q/256⌋, raw (no table), opaque pixels
    /// only, later rows over earlier. The row counter after row j's token is a(j) = 1 + ⌊(j + 1)·q/256⌋: the colour
    /// pass draws row j while a(j) < h; the mask (`.BlitEncBoolFaceClip` with q) has no such test, and both end when
    /// a(j) > h — so at q 0xfa the last source row (a = 6 = h) zeroes the mask but draws no colour.
    func testSquashGeometryAndMask() throws {
        let f = try fixture()
        let b = try blitter(f)
        for q in [0x40, 0x80, 0xb0, 0xfa] {
            var ports = FramePorts(fill: 0x55)
            try b.wrapDrawSprites([SpriteDraw(face: Self.ref, x: 200, y: 100, mode: 0xa0000 | UInt32(q), clip: Self.open)],
                                  h: 0, v: 0, ports: &ports)
            var frame = [[UInt8]](repeating: [UInt8](repeating: 0x55, count: Self.w), count: Self.h)
            var mask = frame
            for j in 0..<Self.h {
                let row = j == 0 ? 0 : 1 + (j * q) >> 8, a = 1 + ((j + 1) * q) >> 8
                if a > Self.h { break }
                for c in 0..<Self.w where Self.pixel(j, c) != 0 {
                    if a < Self.h { frame[row][c] = Self.pixel(j, c) }
                    mask[row][c] = 0
                }
            }
            for r in -2..<(Self.h + 2) {
                for c in -2..<(Self.w + 2) {
                    let inside = (0..<Self.h).contains(r) && (0..<Self.w).contains(c)
                    XCTAssertEqual(at(ports.frame, 200 + c, 100 + r), inside ? frame[r][c] : 0x55, "q \(q) (\(r), \(c))")
                    XCTAssertEqual(at(ports.mask, 200 + c, 100 + r), inside ? mask[r][c] : 0x55, "mask q \(q) (\(r), \(c))")
                }
            }
            if q == 0xfa { XCTAssertEqual(at(ports.frame, 201, 105), 0x55); XCTAssertEqual(at(ports.mask, 201, 105), 0) }
        }
        // Clipped at the port's bottom (4 visible rows at port row 412, q 0xfa): rows 0…2 drawn; source row 3 would
        // land on row 3 (port row 415) but its token already counted the 4th row — the colour pass skips it, the
        // mask pass (no guard) zeroes it; row 4's token ends both.
        var ports = FramePorts(fill: 0x55)
        let face = try XCTUnwrap(b.faces.face(Self.ref))
        try b.blitEncFaceX(face, src: (0, 0), dst: (412, 200), w: Self.w, h: Self.h, word: 0xa00fa, flip: false,
                           rotation: 0, scale: 0x100, ports: &ports)
        for r in 0..<4 {
            for c in 0..<Self.w {
                let p = Self.pixel(r, c), o = (412 + r) * FramePorts.width + 200 + c
                XCTAssertEqual(ports.frame[o], r < 3 && p != 0 ? p : 0x55, "clipped (\(r), \(c))")
                XCTAssertEqual(ports.mask[o], p != 0 ? 0 : 0x55, "clipped mask (\(r), \(c))")
            }
        }
        // q = 0: the mask pass is the plain clip (`param_8 == 0`); the colour pass advances once (acc starts at 0x100)
        // and piles rows 1…5 on row 1.
        ports = FramePorts(fill: 0x55)
        try b.blitEncFaceX(face, src: (0, 0), dst: (100, 200), w: Self.w, h: Self.h, word: 0xa0000, flip: false,
                           rotation: 0, scale: 0x100, ports: &ports)
        for r in 0..<Self.h {
            for c in 0..<Self.w {
                let o = (100 + r) * FramePorts.width + 200 + c
                XCTAssertEqual(ports.mask[o], Self.pixel(r, c) != 0 ? 0 : 0x55, "q 0 mask (\(r), \(c))")
                let pile = (1..<Self.h).reversed().first { Self.pixel($0, c) != 0 }.map { Self.pixel($0, c) }
                let want: UInt8 = r == 0 ? (Self.pixel(0, c) != 0 ? Self.pixel(0, c) : 0x55) : r == 1 ? pile ?? 0x55 : 0x55
                XCTAssertEqual(ports.frame[o], want, "q 0 (\(r), \(c))")
            }
        }
        // Flipped (the flip twins have no mode-10 arm: undefined table) and scaled squashes stay refused.
        for d in [SpriteDraw(face: Self.ref, x: 0, y: 0, mode: 0xa0080, mirrored: true, clip: Self.open),
                  SpriteDraw(face: Self.ref, x: 0, y: 0, mode: 0xa0080, clip: Self.open, scale: 0x80)] {
            XCTAssertThrowsError(try b.wrapDrawSprites([d], h: 0, v: 0, ports: &ports)) {
                XCTAssertEqual($0 as? SpriteBlitter.Refusal, .mode(0xa0080))
            }
        }
    }

    // MARK: - end to end

    private func renderer(level: Int) throws -> FrameRenderer {
        try FrameRenderer(resources: try Self.resources.get(), level: level,
                          search: ColorSearch(model: .ruled, tieBreak: .lowest),
                          dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
    }

    /// The level's session at seed 1 with the renderer's faces (as `FerazelDriver.prepare` hands them); `diffuse`
    /// false leaves out the mode-5 walk, `attach` false skips handing the lights and tint draws to `r` again.
    private func session(_ r: FrameRenderer, level: Int, start: (x: Int, y: Int), diffuse: Bool = true,
                         attach: Bool = true) throws -> FerazelSession {
        let s = try FerazelSession(resources: try Self.resources.get(), prefs: FerazelPrefs(), level: level, seed: 1,
                                   faceBounds: r.faceBounds, particleFaces: r.particleFaces,
                                   diffuseRandoms: diffuse ? r.diffuseRandoms : nil, start: start)
        if attach {
            try r.addLights(s.lights)
            try r.buildTintTable(s.tintTableDraws)
        }
        return s
    }

    private func spriteDraws(_ ops: FrameOps) -> [SpriteDraw] {
        ops.draws.flatMap { op -> [SpriteDraw] in if case .wrapDrawSprites(let d) = op { d } else { [] } }
    }

    /// Level 1, the player standing on teleporter record 148: the charge climbs, the sparkle (`0x5000n`) is drawn
    /// through the real renderer frame after frame with no refusal, each mode-5 draw takes the stream's seed at its
    /// place and the stream moves on by the draw's randoms (a session with no renderer walk stays behind).
    func testTeleporterSparkleThroughTheRenderer() throws {
        let res = try Self.resources.get()
        let L = try LevelFile.load(from: res, level: 1)
        let p = L.placements[148]
        let start = (x: Int(p.x) + 0x10 - 50, y: Int(p.y) - 4 - 85 + 1)
        let r = try renderer(level: 1)
        let s = try session(r, level: 1, start: start)
        let bare = try session(r, level: 1, start: start, diffuse: false, attach: false)
        var sparkles = 0, firstSparkle: Int?
        for k in 0..<200 {
            let before = s.rngSeed
            XCTAssertEqual(before, bare.rngSeed, "streams agree before the first sparkle (frame \(k))")
            let ops = s.step(keys: KeyState())
            _ = bare.step(keys: KeyState())
            let diffuse = spriteDraws(ops).filter { $0.mode >> 16 == 5 }
            for d in diffuse { XCTAssertNotNil(d.randomSeed) }
            let lit = r.screen.pixels.filter { (0x99...0x9e).contains($0) }.count
            XCTAssertNoThrow(try r.apply(ops), "frame \(k)")
            if !diffuse.isEmpty {
                sparkles += 1
                firstSparkle = k
                // The sparkle colours reach the screen (n ≥ 1 over the player's few hundred pixels; the frame port's
                // copy is erased again at the iteration's end).
                XCTAssertGreaterThan(r.screen.pixels.filter { (0x99...0x9e).contains($0) }.count, lit)
                break
            }
            if ops.suspension != nil { break }
        }
        XCTAssertEqual(sparkles, 1, "the charge reached the sparkle")
        XCTAssertNotNil(firstSparkle)
        XCTAssertNotEqual(s.rngSeed, bare.rngSeed, "the draw consumed the game's stream")
        // Keep charging to the fire pulse: every sparkle frame draws.
        for k in 0..<100 {
            let ops = s.step(keys: KeyState())
            XCTAssertNoThrow(try r.apply(ops), "frame \(k)")
            if ops.suspension != nil { break }
        }
    }

    /// Level 3's springboard: its gauge draws `0xa0000 + q` (q 11 … 0xfa) through the real renderer with no refusal.
    func testSpringboardGaugeThroughTheRenderer() throws {
        let res = try Self.resources.get()
        let L = try LevelFile.load(from: res, level: 3)
        let boards = L.placements.filter { $0.type == 1420 }
        XCTAssertEqual(boards.count, 2)
        let b = try XCTUnwrap(boards.first)
        let r = try renderer(level: 3)
        let s = try session(r, level: 3, start: (x: Int(b.x) - 120, y: Int(b.y) - 100))
        var squashed = 0
        for k in 0..<40 {
            let ops = s.step(keys: KeyState())
            squashed += spriteDraws(ops).filter { $0.mode >> 16 == 0xa }.count
            XCTAssertNoThrow(try r.apply(ops), "frame \(k)")
            if ops.suspension != nil { break }
        }
        XCTAssertGreaterThan(squashed, 0, "the gauge drew squashed")
    }
}

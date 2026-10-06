import XCTest
@testable import DeimosCore
@testable import DeimosRender

/// `pl1o` decoded once per test process (plan Landmine e).
private enum ShippedSprites {
    static let pl1o: Result<SpriteGroup, Error> = Result {
        let index = try TagIndex(dataDirectory: DeimosData.dataDirectory())
        return try SpriteGroup.load(id: FourCC("pl1o")!, index: index)
    }
}

/// R2 — the sprite blitters, `COST` and the fade to black (plan R2; blit-pixel-rules §1–§5, sprite-geometry-draw §3.3,
/// `FUN_1001ec80` / `FUN_1000b9a0` listing reads in CostRect.swift / FadeToBlack.swift).
final class BlitTests: XCTestCase {

    private static let cost = FourCC("COST")!
    private static let face = FourCC("test")!

    private func rgb(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> UInt16 { (r << 10) | (g << 5) | b }

    private func pattern(width: Int, height: Int, seed: Int = 0) -> Pixmap555 {
        var p = Pixmap555(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                p[x, y] = UInt16(truncatingIfNeeded: (x &* 31 &+ y &* 977 &+ seed &* 7919 &+ 0x1234) & 0x7fff)
            }
        }
        return p
    }

    /// A synthetic frame. `map` rows use the loader's values (0…31, 32 skip, 1000 in column 0 of an empty row).
    private func frame(_ w: Int, _ h: Int, key: UInt16 = 0x03E0, pixels: [UInt16]? = nil,
                       map: [[UInt16]]? = nil) -> SpriteFrame {
        let px = pixels ?? (0..<(w * h)).map { UInt16(truncatingIfNeeded: (0x4210 &+ $0 &* 0x0421) & 0x7fff) }
        return SpriteFrame(rect: MacRect(top: 0, left: 0, bottom: Int32(h), right: Int32(w)), width: w, height: h,
                           key: key, pixels: px, alphaMap: map.map { $0.flatMap { $0 } })
    }

    private func command(x: Int32, y: Int32, flags: UInt32 = 0, alpha: UInt32 = 0, scale: Float = 1,
                         clip: MacRect = DrawCommand.template.clip, colour: UInt16 = 0x7fff) -> DrawCommand {
        var c = DrawCommand.template
        c.face = Self.face; c.x = x; c.y = y; c.flags = flags; c.alpha = alpha; c.scale = scale
        c.clip = clip; c.colour = colour; c.drawNow = true
        return c
    }

    // MARK: - Dispatch (FUN_10019570)

    func testDispatchSelection() {
        let f = frame(10, 6)
        // Nothing: face none (`10019594`), alpha 32 (`100195a4`).
        var none = command(x: 100, y: 100); none.face = .none
        XCTAssertEqual(SpriteBlitter.select(none, frame: f).path, .nothing)
        XCTAssertEqual(SpriteBlitter.select(command(x: 100, y: 100, alpha: 32), frame: f).path, .nothing)
        XCTAssertEqual(SpriteBlitter.select(command(x: 100, y: 100, alpha: 31), frame: f).path,
                       .unscaled(mode: 0, clipped: false))
        // Mode priority &1 > &2 > &4 (`100197d4…100197fc`); port by &8 (`10019708…10019730`).
        let modes: [(UInt32, Int)] = [(0, 0), (1, 1), (1 | 2 | 4, 1), (2, 2), (2 | 4, 2), (4, 3), (8, 0), (8 | 4, 3)]
        for (flags, mode) in modes {
            let s = SpriteBlitter.select(command(x: 100, y: 100, flags: flags), frame: f)
            XCTAssertEqual(s.path, .unscaled(mode: mode, clipped: false), "flags \(flags)")
            XCTAssertEqual(s.target, flags & 8 != 0 ? .terrain : .back, "flags \(flags)")
        }
        // Unscaled classification (`10019754…100197a8`), w 10 h 6 → left = X − 5, top = Y − 3; clip {0,0,480,416}.
        func path(_ x: Int32, _ y: Int32) -> SpriteBlitter.Path { SpriteBlitter.select(command(x: x, y: y), frame: f).path }
        XCTAssertEqual(path(410, 100), .unscaled(mode: 0, clipped: false))   // left 405, right edge 415 < 416
        XCTAssertEqual(path(411, 100), .unscaled(mode: 0, clipped: true))    // left 406: X + w == clipR → the twin
        XCTAssertEqual(path(420, 100), .unscaled(mode: 0, clipped: true))    // straddles the right edge
        XCTAssertEqual(path(421, 100), .nothing)                             // left 416 ≥ clipR
        XCTAssertEqual(path(5, 100), .unscaled(mode: 0, clipped: false))     // left 0 ≥ clipL
        XCTAssertEqual(path(4, 100), .unscaled(mode: 0, clipped: true))
        XCTAssertEqual(path(-5, 100), .unscaled(mode: 0, clipped: true))     // left −10: X + w == 0, not < clipL
        XCTAssertEqual(path(-6, 100), .nothing)                              // X + w = −1 < clipL
        XCTAssertEqual(path(100, 476), .unscaled(mode: 0, clipped: false))   // top 473, bottom 479
        XCTAssertEqual(path(100, 477), .unscaled(mode: 0, clipped: true))    // Y + h == clipB
        XCTAssertEqual(path(100, 483), .nothing)                             // top 480 ≥ clipB
        XCTAssertEqual(path(100, -3), .unscaled(mode: 0, clipped: true))     // Y + h == 0 == clipT
        XCTAssertEqual(path(100, -4), .nothing)
        // Scaled: no reject; unclipped leaves iff the clip is exactly {0,0,480,416} (`10019818…10019844`).
        XCTAssertEqual(SpriteBlitter.select(command(x: 100, y: 100, flags: 2, scale: 0.5), frame: f).path,
                       .scaled(mode: 2, clipped: false))
        XCTAssertEqual(SpriteBlitter.select(command(x: 5000, y: 5000, scale: 1.5), frame: f).path,
                       .scaled(mode: 0, clipped: false))
        XCTAssertEqual(SpriteBlitter.select(command(x: 100, y: 100, flags: 4, scale: 0.5,
                                                    clip: MacRect(top: 0, left: 0, bottom: 480, right: 417)),
                                            frame: f).path, .scaled(mode: 3, clipped: true))
        XCTAssertEqual(SpriteBlitter.select(command(x: 100, y: 100, scale: 1.0000001), frame: f).path,
                       .scaled(mode: 0, clipped: false))
        // COST (`100195c4…100195ec`, `100196e4…10019704`, `100197ac…100197c8`): never scaled; the command clip only
        // rejects; no frame is needed.
        var cost = command(x: 0, y: 0, alpha: 8, scale: 0.5)
        cost.face = Self.cost
        cost.costRect = MacRect(top: 117, left: 507, bottom: 132, right: 543)
        cost.clip = MacRect(top: 0, left: 0, bottom: 480, right: 640)
        XCTAssertEqual(SpriteBlitter.select(cost, frame: nil).path, .cost)
        cost.clip = MacRect(top: 0, left: 0, bottom: 480, right: 507)
        XCTAssertEqual(SpriteBlitter.select(cost, frame: nil).path, .nothing)          // X 507 ≥ clipR
        cost.clip = MacRect(top: 0, left: 0, bottom: 480, right: 508)
        XCTAssertEqual(SpriteBlitter.select(cost, frame: nil).path, .cost)
        cost.alpha = 32
        XCTAssertEqual(SpriteBlitter.select(cost, frame: nil).path, .nothing)
    }

    // MARK: - Unscaled leaves (blit-pixel-rules §3)

    func testUnscaledMode0() {
        let map: [[UInt16]] = [[0, 16, 32, 0], [1000, 32, 32, 32], [31, 0, 32, 1]]
        let f = frame(4, 3, map: map)
        let base = pattern(width: 64, height: 48)
        var buf = base
        // X 12, Y 21 → left 12 − 2 = 10, top 21 − 1 = 20. Mode 0 ignores the command alpha.
        SpriteBlitter.draw(command(x: 12, y: 21, alpha: 12), frame: f, into: &buf)
        func src(_ c: Int, _ r: Int) -> UInt16 { f.pixels[r * 4 + c] }
        func d(_ c: Int, _ r: Int) -> UInt16 { base[10 + c, 20 + r] }
        let want: [[UInt16]] = [
            [src(0, 0), Blend555.blend(d(1, 0), src(1, 0), a: 16), d(2, 0), src(3, 0)],
            [d(0, 1), d(1, 1), d(2, 1), d(3, 1)],                                   // 1000 → whole row skipped
            [Blend555.blend(d(0, 2), src(0, 2), a: 31), src(1, 2), d(2, 2), Blend555.blend(d(3, 2), src(3, 2), a: 1)],
        ]
        for r in 0..<3 { for c in 0..<4 { XCTAssertEqual(buf[10 + c, 20 + r], want[r][c], "(\(c), \(r))") } }
        assertUnchangedOutside(buf, base, MacRect(top: 20, left: 10, bottom: 23, right: 14))

        // Key path (no map): copy every pixel ≠ key.
        let key: UInt16 = 0x03E0
        let kf = frame(3, 2, key: key, pixels: [0x1111, key, 0x2222, key, 0x3333, 0x0001])
        var kb = base
        SpriteBlitter.draw(command(x: 31, y: 31, alpha: 20), frame: kf, into: &kb)   // left 30, top 30
        XCTAssertEqual([kb[30, 30], kb[31, 30], kb[32, 30], kb[30, 31], kb[31, 31], kb[32, 31]],
                       [0x1111, base[31, 30], 0x2222, base[30, 31], 0x3333, 0x0001])
        assertUnchangedOutside(kb, base, MacRect(top: 30, left: 30, bottom: 32, right: 33))
    }

    func testUnscaledMode1Additive() {
        let map: [[UInt16]] = [[0, 8, 15, 16, 20, 32], [1000, 32, 32, 32, 32, 32]]
        let f = frame(6, 2, map: map)
        let base = pattern(width: 64, height: 48, seed: 3)
        var buf = base
        SpriteBlitter.draw(command(x: 13, y: 11, flags: 1, alpha: 16), frame: f, into: &buf)   // left 10, top 10
        func src(_ c: Int) -> UInt16 { f.pixels[c] }
        func d(_ c: Int, _ r: Int = 0) -> UInt16 { base[10 + c, 10 + r] }
        // p 0 → α = a; else α = a + p, skipped once α ≥ 32 (`1001dc18 add; cmplwi 0x20; bge`).
        XCTAssertEqual(buf[10, 10], Blend555.blend(d(0), src(0), a: 16))
        XCTAssertEqual(buf[11, 10], Blend555.blend(d(1), src(1), a: 24))
        XCTAssertEqual(buf[12, 10], Blend555.blend(d(2), src(2), a: 31))
        XCTAssertEqual(buf[13, 10], d(3))
        XCTAssertEqual(buf[14, 10], d(4))
        XCTAssertEqual(buf[15, 10], d(5))
        for c in 0..<6 { XCTAssertEqual(buf[10 + c, 11], d(c, 1)) }
        assertUnchangedOutside(buf, base, MacRect(top: 10, left: 10, bottom: 12, right: 16))

        // Key path: every pixel ≠ key blends at the command alpha.
        let key: UInt16 = 0x7C1F
        let kf = frame(2, 1, key: key, pixels: [0x2345, key])
        var kb = base
        SpriteBlitter.draw(command(x: 41, y: 40, flags: 1, alpha: 5), frame: kf, into: &kb)   // left 40
        XCTAssertEqual(kb[40, 40], Blend555.blend(base[40, 40], 0x2345, a: 5))
        XCTAssertEqual(kb[41, 40], base[41, 40])
    }

    func testMode2AlphaTables() {
        // §3.1: α = trunc(fl32(p·fl32(0.032·p) + a)); skipped when α ≥ 32.
        let a20: [UInt32] = [20, 20, 20, 20, 20, 21, 21, 22, 22, 23, 23, 24, 25, 26, 27, 28, 29, 30, 31]
        XCTAssertEqual((1...19).map { SpriteBlitter.shadowAlpha(p: $0, a: 20) }, a20)
        for p in 20...31 { XCTAssertGreaterThanOrEqual(SpriteBlitter.shadowAlpha(p: p, a: 20), 32, "p \(p)") }
        let a0: [UInt32] = [0, 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 18, 20, 21, 23,
                            25, 26, 28, 30]
        XCTAssertEqual((1...31).map { SpriteBlitter.shadowAlpha(p: $0, a: 0) }, a0)

        // Pixels: p 0 → dst·a/32; p 5 → α 20; p 19 → α 31; p 20 skipped; key path dst·a/32.
        let f = frame(5, 1, map: [[0, 5, 19, 20, 32]])
        let base = pattern(width: 32, height: 16, seed: 5)
        var buf = base
        SpriteBlitter.draw(command(x: 12, y: 4, flags: 2, alpha: 20), frame: f, into: &buf)   // left 10, top 4
        XCTAssertEqual(buf[10, 4], Blend555.blend(base[10, 4], 0, a: 20))
        XCTAssertEqual(buf[11, 4], Blend555.blend(base[11, 4], 0, a: 20))
        XCTAssertEqual(buf[12, 4], Blend555.blend(base[12, 4], 0, a: 31))
        XCTAssertEqual(buf[13, 4], base[13, 4])
        XCTAssertEqual(buf[14, 4], base[14, 4])
        let key: UInt16 = 0x0001
        var kb = base
        SpriteBlitter.draw(command(x: 3, y: 9, flags: 2, alpha: 20), frame: frame(2, 1, key: key, pixels: [0x7FFF, key]),
                           into: &kb)                                                          // left 2
        XCTAssertEqual(kb[2, 9], Blend555.blend(base[2, 9], 0, a: 20))
        XCTAssertEqual(kb[3, 9], base[3, 9])
    }

    func testMode3Tint() {
        let colour: UInt16 = 0x7C00
        let f = frame(5, 1, map: [[0, 5, 21, 22, 32]])
        let base = pattern(width: 32, height: 16, seed: 9)
        var buf = base
        SpriteBlitter.draw(command(x: 12, y: 4, flags: 4, alpha: 10, colour: colour), frame: f, into: &buf)  // left 10
        // The colour replaces the source; p 0 → α = a, else α = a + p, skip ≥ 32 (`1001dfc8`).
        XCTAssertEqual(buf[10, 4], Blend555.blend(base[10, 4], colour, a: 10))
        XCTAssertEqual(buf[11, 4], Blend555.blend(base[11, 4], colour, a: 15))
        XCTAssertEqual(buf[12, 4], Blend555.blend(base[12, 4], colour, a: 31))
        XCTAssertEqual(buf[13, 4], base[13, 4])
        XCTAssertEqual(buf[14, 4], base[14, 4])
        let key: UInt16 = 0x0421
        var kb = base
        SpriteBlitter.draw(command(x: 3, y: 9, flags: 4, alpha: 0, colour: colour),
                           frame: frame(2, 1, key: key, pixels: [key, 0x1234]), into: &kb)     // left 2
        XCTAssertEqual(kb[2, 9], base[2, 9])
        XCTAssertEqual(kb[3, 9], colour)   // a 0: solid colour
    }

    func testClippedTwinsMatchUnclipped() {
        var rng = SplitMix(seed: 0x00DE_1305)
        let base = pattern(width: 96, height: 80, seed: 11)
        for trial in 0..<400 {
            let w = rng.int(1...24), h = rng.int(1...24)
            let mapped = rng.int(0...3) != 0
            let key: UInt16 = UInt16(rng.int(0...0x7fff))
            let pixels = (0..<(w * h)).map { _ in rng.int(0...3) == 0 ? key : UInt16(rng.int(0...0x7fff)) }
            var map: [[UInt16]]? = nil
            if mapped {
                map = (0..<h).map { _ in
                    if rng.int(0...7) == 0 { return [1000] + [UInt16](repeating: 32, count: w - 1) }
                    return (0..<w).map { _ in
                        switch rng.int(0...3) { case 0: return 0; case 1: return 32; default: return UInt16(rng.int(1...31)) }
                    }
                }
            }
            let f = frame(w, h, key: key, pixels: pixels, map: map)
            let mode = rng.int(0...3), alpha = rng.int(0...31)
            let colour = UInt16(rng.int(0...0x7fff))
            let left = rng.int(0...(96 - w)), top = rng.int(0...(80 - h))
            let cl = rng.int(0...95), ct = rng.int(0...79)
            let clip = MacRect(top: Int32(ct), left: Int32(cl), bottom: Int32(rng.int(ct...80)), right: Int32(rng.int(cl...96)))
            var a = base, b = base
            UnscaledLeaves.blit(f, into: &a, left: left, top: top, mode: mode, alpha: alpha, colour: colour, clip: nil)
            UnscaledLeaves.blit(f, into: &b, left: left, top: top, mode: mode, alpha: alpha, colour: colour, clip: clip)
            for y in 0..<80 {
                for x in 0..<96 {
                    let inClip = x >= cl && x < Int(clip.right) && y >= ct && y < Int(clip.bottom)
                    if b[x, y] != (inClip ? a[x, y] : base[x, y]) {
                        return XCTFail("trial \(trial): (\(x), \(y)) mode \(mode) mapped \(mapped)")
                    }
                }
            }
        }
        // A frame ending exactly on the clip's right edge takes the twin (strict `X + w < clipR`), same pixels.
        let f = frame(10, 6, map: (0..<6).map { r in (0..<10).map { UInt16(($0 + r) % 33) } })
        let cmd = command(x: 411, y: 100, flags: 1, alpha: 7)                                   // left 406, right 416
        XCTAssertEqual(SpriteBlitter.select(cmd, frame: f).path, .unscaled(mode: 1, clipped: true))
        let back = pattern(width: 640, height: 480, seed: 13)
        var viaTwin = back, viaInside = back
        SpriteBlitter.draw(cmd, frame: f, into: &viaTwin)
        UnscaledLeaves.blit(f, into: &viaInside, left: 406, top: 97, mode: 1, alpha: 7, colour: 0x7fff, clip: nil)
        XCTAssertEqual(viaTwin, viaInside)
        XCTAssertNotEqual(viaTwin, back)
    }

    // A twin with the frame crossing the port's left/top edge (negative origin) and a clip that reaches past the
    // port: the clip mask passes x, y < 0, the replica guard drops them. Oracle computed here, pixel by pixel.
    func testClippedTwinNegativeOrigin() {
        let base = pattern(width: 10, height: 8, seed: 21)
        let key: UInt16 = 0x0421
        let w = 6, h = 4, left = -3, top = -2
        let pixels = (0..<(w * h)).map { i in i % 5 == 0 ? key : UInt16(truncatingIfNeeded: (0x1111 &* (i + 1)) & 0x7fff) }
        let mapRows: [[UInt16]] = (0..<h).map { r in (0..<w).map { c in [0, 32, 7, 0, 19, 32][(c + r) % 6] } }
        let clip = MacRect(top: -5, left: -5, bottom: 7, right: 9)
        for mapped in [false, true] {
            let f = frame(w, h, key: key, pixels: pixels, map: mapped ? mapRows : nil)
            var port = base
            UnscaledLeaves.blit(f, into: &port, left: left, top: top, mode: 0, alpha: 0, colour: 0, clip: clip)
            for y in 0..<8 {
                for x in 0..<10 {
                    let c = x - left, r = y - top
                    var want = base[x, y]
                    if c >= 0, c < w, r >= 0, r < h, x < 9, y < 7 {
                        let src = pixels[r * w + c]
                        if mapped {
                            let p = Int(mapRows[r][c])
                            if p == 0 { want = src } else if p != 32 {
                                // ⌊(dst·p + src·(32 − p))/32⌋ per channel, computed here
                                func ch(_ v: UInt16, _ s: UInt16) -> UInt16 { (v >> s) & 31 }
                                let d = base[x, y]
                                want = [10, 5, 0].reduce(UInt16(0)) { acc, sh in
                                    acc | UInt16((Int(ch(d, UInt16(sh))) * p + Int(ch(src, UInt16(sh))) * (32 - p)) / 32) << UInt16(sh)
                                }
                            }
                        } else if src != key {
                            want = src
                        }
                    }
                    XCTAssertEqual(port[x, y], want, "mapped \(mapped) (\(x), \(y))")
                }
            }
        }
    }

    // a > 32 (reachable through COST's `cmd.alpha` and the public CostRect/Blend555 API): the original kernel
    // computes `subfic r4,a,0x20` (32 − a as a 32-bit word) and `mullw`, wrapping mod 2³², then unpacks with
    // `rlwinm …,0x1b,0x5,0x1f` / `andi. 0x7c1f` / `rlwimi …,0xc,0x16,0x1a` (FUN_1001ec80 `1001edc4…1001edf0`; the same
    // sequence in FUN_1001e9d0 `1001eb80…1001ebb4`). Only a == 32 returns early (`1001ec8c`). Hand-computed:
    // 0x7FFF·40: packed 0x01F07C1F × 40 = 0x4D9364D8 → 0x1806 | 0x00C0 = 0x18C6;
    // 0x7FFF·(32 − 40): 0x01F07C1F × 0xFFFFFFF8 = 0xF07C1F08 → 0x6018 | 0x0300 = 0x6318.
    func testBlendAlphaAboveThirtyTwoWraps() {
        XCTAssertEqual(Blend555.blend(0x7FFF, 0x0000, a: 40), 0x18C6)
        XCTAssertEqual(Blend555.blend(0x0000, 0x7FFF, a: 40), 0x6318)
        var port = Pixmap555(width: 3, height: 2)
        CostRect.fill(&port, rect: MacRect(top: 0, left: 1, bottom: 1, right: 3), colour: 0x7FFF, a: 40)
        XCTAssertEqual(port.pixels, [0, 0x6318, 0x6318, 0, 0, 0])
    }

    // MARK: - Scaled path (blit-pixel-rules §5)

    func testScaledHalfShipShadow() throws {
        let group = try ShippedSprites.pl1o.get()
        let f = group.frames[0]
        XCTAssertEqual([f.width, f.height], [53, 43])
        let map = try XCTUnwrap(f.alphaMap, "pl1o frame 0 has an alpha map")
        // The shadow of the ship at rest (plan derived: centre (184, 382), scale 0.5, darkness 20).
        let cmd = command(x: 184, y: 382, flags: 2, alpha: 20, scale: 0.5)
        XCTAssertEqual(SpriteBlitter.select(cmd, frame: f).path, .scaled(mode: 2, clipped: false))
        XCTAssertEqual(ScaledLeaves.geometry(x: 184, y: 382, width: 53, height: 43, scale: 0.5),
                       ScaledLeaves.Geometry(left: 170, top: 371, width: 26, height: 21))
        let base = pattern(width: 640, height: 480, seed: 17)
        var buf = base
        SpriteBlitter.draw(cmd, frame: f, into: &buf)
        assertUnchangedOutside(buf, base, MacRect(top: 371, left: 170, bottom: 392, right: 196))
        var darkened = 0
        for dy in 371..<392 {
            for dx in 170..<196 {
                let sx = (53 * (dx - 170)) / 26, sy = (43 * (dy - 371)) / 21
                let p = Int(map[sy * 53 + sx])
                let want: UInt16
                switch p {
                case 32, 1000: want = base[dx, dy]
                case 0: want = Blend555.blend(base[dx, dy], 0, a: 20)
                default:
                    let al = SpriteBlitter.shadowAlpha(p: p, a: 20)
                    want = al >= 32 ? base[dx, dy] : Blend555.blend(base[dx, dy], 0, a: Int(al))
                }
                XCTAssertEqual(buf[dx, dy], want, "(\(dx), \(dy))")
                if p == 0 { darkened += 1 }
            }
        }
        XCTAssertGreaterThan(darkened, 0)
    }

    func testScaledClampVersusClip() {
        let w = 20, h = 10
        let f = frame(w, h, map: [[UInt16]](repeating: [UInt16](repeating: 0, count: w), count: h))
        func src(_ sx: Int, _ sy: Int) -> UInt16 { f.pixels[sy * w + sx] }
        let base = pattern(width: 640, height: 480, seed: 19)
        // ×2 at x 410: W 40, left = trunc(410 − 20) = 390, right 430; H 20, top = trunc(100 − 10) = 90.
        XCTAssertEqual(ScaledLeaves.geometry(x: 410, y: 100, width: w, height: h, scale: 2),
                       ScaledLeaves.Geometry(left: 390, top: 90, width: 40, height: 20))
        var clamped = base
        SpriteBlitter.draw(command(x: 410, y: 100, scale: 2), frame: f, into: &clamped)
        var wide = base
        let wideClip = MacRect(top: 0, left: 0, bottom: 480, right: 640)
        SpriteBlitter.draw(command(x: 410, y: 100, scale: 2, clip: wideClip), frame: f, into: &wide)
        var narrow = base
        let narrowClip = MacRect(top: 95, left: 0, bottom: 480, right: 400)
        SpriteBlitter.draw(command(x: 410, y: 100, scale: 2, clip: narrowClip), frame: f, into: &narrow)
        for dy in 90..<110 {
            for dx in 390..<430 {
                let s = src((w * (dx - 390)) / 40, (h * (dy - 90)) / 20)
                XCTAssertEqual(clamped[dx, dy], dx < 416 ? s : base[dx, dy], "clamp (\(dx), \(dy))")   // `0x1a0`
                XCTAssertEqual(wide[dx, dy], s, "clip (\(dx), \(dy))")
                XCTAssertEqual(narrow[dx, dy], dx < 400 && dy >= 95 ? s : base[dx, dy], "narrow (\(dx), \(dy))")
            }
        }
        assertUnchangedOutside(clamped, base, MacRect(top: 90, left: 390, bottom: 110, right: 416))
        assertUnchangedOutside(wide, base, MacRect(top: 90, left: 390, bottom: 110, right: 430))
        // Left edge: x −5, ×2 → left = trunc(−5 − 20) = −25 (toward zero); the clamp to x ≥ 0 never shifts the
        // sampling: dst x 0 shows source column (20·25) div 40 = 12.
        var edge = base
        SpriteBlitter.draw(command(x: -5, y: 100, scale: 2), frame: f, into: &edge)
        for dx in 0..<15 { XCTAssertEqual(edge[dx, 95], src((w * (dx + 25)) / 40, (h * 5) / 20), "edge \(dx)") }
        XCTAssertEqual(edge[15, 95], base[15, 95])
        // Downscale 0.75 of 20 × 10 at (100, 100): W 15, left = trunc(100 − 7.5) = 92; H 7.5 → 7,
        // top = trunc(100 − 3.75) = 96; columns sx = (20·i) div 15.
        XCTAssertEqual(ScaledLeaves.geometry(x: 100, y: 100, width: w, height: h, scale: 0.75),
                       ScaledLeaves.Geometry(left: 92, top: 96, width: 15, height: 7))
        var down = base
        SpriteBlitter.draw(command(x: 100, y: 100, scale: 0.75), frame: f, into: &down)
        XCTAssertEqual((92..<107).map { down[$0, 96] }, (0..<15).map { src((20 * $0) / 15, 0) })
        assertUnchangedOutside(down, base, MacRect(top: 96, left: 92, bottom: 103, right: 107))
    }

    // MARK: - COST (FUN_1001ec80)

    func testCostRect() {
        let base = pattern(width: 640, height: 480, seed: 23)
        let bounds = MacRect(top: 0, left: 0, bottom: 480, right: 640)
        func cost(_ r: MacRect, alpha: UInt32 = 8, colour: UInt16 = 0, clip: MacRect = bounds) -> DrawCommand {
            var c = command(x: 0, y: 0, alpha: alpha, clip: clip)
            c.face = Self.cost; c.costRect = r; c.costColour = colour
            return c
        }
        // The shield-meter darkening (hud-scorebar §5 worked example): blend 8, colour 0 → ⌊c·8/32⌋.
        let meter = MacRect(top: 117, left: 507, bottom: 132, right: 543)
        var buf = base
        SpriteBlitter.draw(cost(meter), frame: nil, into: &buf)
        for y in 117..<132 { for x in 507..<543 { XCTAssertEqual(buf[x, y], Blend555.blend(base[x, y], 0, a: 8)) } }
        XCTAssertEqual(buf[507, 117], rgb((base[507, 117] >> 10 & 31) / 4, (base[507, 117] >> 5 & 31) / 4,
                                         (base[507, 117] & 31) / 4))
        assertUnchangedOutside(buf, base, meter)
        // A colour: dst weighted a, colour 32 − a.
        var tinted = base
        SpriteBlitter.draw(cost(meter, alpha: 16, colour: 0x7C00), frame: nil, into: &tinted)
        XCTAssertEqual(tinted[520, 120], Blend555.blend(base[520, 120], 0x7C00, a: 16))
        // The command clip only rejects (`10019754…100197a8`): a rect crossing it is drawn whole …
        var crossing = base
        SpriteBlitter.draw(cost(meter, clip: MacRect(top: 0, left: 0, bottom: 480, right: 520)), frame: nil, into: &crossing)
        XCTAssertEqual(crossing, buf)
        // … a rect wholly outside it draws nothing.
        var outside = base
        SpriteBlitter.draw(cost(meter, clip: MacRect(top: 0, left: 0, bottom: 480, right: 507)), frame: nil, into: &outside)
        XCTAssertEqual(outside, base)
        // Clamped to the port bounds (`1001ecac…1001ed60`).
        var corner = base
        let off = MacRect(top: 470, left: 630, bottom: 490, right: 650)
        SpriteBlitter.draw(cost(off), frame: nil, into: &corner)
        assertUnchangedOutside(corner, base, MacRect(top: 470, left: 630, bottom: 480, right: 640))
        XCTAssertEqual(corner[639, 479], Blend555.blend(base[639, 479], 0, a: 8))
        // The start address uses the UNclamped top/left (`1001ed78…1001ed9c`) with the clamped size: a rect with
        // left −5 writes 4 (= 4 − 0) pixels from x −5, i.e. the previous row's last 4 pixels in linear memory.
        var quirk = base
        SpriteBlitter.draw(cost(MacRect(top: 10, left: -5, bottom: 12, right: 4)), frame: nil, into: &quirk)
        let hit = [(635, 9), (636, 9), (637, 9), (638, 9), (635, 10), (636, 10), (637, 10), (638, 10)]
        for (x, y) in hit { XCTAssertEqual(quirk[x, y], Blend555.blend(base[x, y], 0, a: 8), "(\(x), \(y))") }
        let hitIndices = Set(hit.map { $0.1 * 640 + $0.0 })
        XCTAssertTrue(quirk.pixels.indices.allSatisfy { hitIndices.contains($0) || quirk.pixels[$0] == base.pixels[$0] })
    }

    func testCentreAnchorOddWidth() {
        let f = frame(5, 3, key: 0x7FFF, pixels: (0..<15).map { UInt16($0 + 1) })
        let base = pattern(width: 64, height: 48, seed: 29)
        var buf = base
        // left = X − ⌊5/2⌋ = 8 … 12 (the extra column lands on the right); top = Y − ⌊3/2⌋ = 9 … 11.
        SpriteBlitter.draw(command(x: 10, y: 10), frame: f, into: &buf)
        for r in 0..<3 { for c in 0..<5 { XCTAssertEqual(buf[8 + c, 9 + r], UInt16(r * 5 + c + 1)) } }
        assertUnchangedOutside(buf, base, MacRect(top: 9, left: 8, bottom: 12, right: 13))
        // X 1 → left −1: the twin draws source columns 1…4 at x 0…3.
        var edge = base
        SpriteBlitter.draw(command(x: 1, y: 10), frame: f, into: &edge)
        for c in 0..<4 { XCTAssertEqual(edge[c, 9], UInt16(c + 2)) }
        assertUnchangedOutside(edge, base, MacRect(top: 9, left: 0, bottom: 12, right: 4))
        // Scaled odd width: w 5 ×1.5 → W 7.5, w' 7, left = trunc(10 − 3.75) = 6.
        XCTAssertEqual(ScaledLeaves.geometry(x: 10, y: 10, width: 5, height: 3, scale: 1.5),
                       ScaledLeaves.Geometry(left: 6, top: 7, width: 7, height: 4))
    }

    // MARK: - Fade to black (FUN_1000b9a0)

    func testFadeToBlackCompounds() {
        XCTAssertEqual(DisplayBuffers.toBlackLevels, Array((0...32).reversed()))
        var d = DisplayBuffers()
        d.back = pattern(width: 640, height: 480, seed: 31)
        var expected = d.back
        d.fadeBegin(.toBlack)
        for a in DisplayBuffers.toBlackLevels {
            d.fadeStep(.toBlack, a: a, present: .gameLayout)
            // Each step scales the already-darkened buffer: c ← ⌊c·a/32⌋ per channel, compounding.
            for i in expected.pixels.indices {
                let p = expected.pixels[i]
                expected.pixels[i] = rgb((p >> 10 & 31) * UInt16(a) / 32, (p >> 5 & 31) * UInt16(a) / 32,
                                         (p & 31) * UInt16(a) / 32)
            }
            XCTAssertEqual(d.back, expected, "a \(a)")
            XCTAssertEqual(d.screen[32 + 100, 200], d.back[100, 200], "present a \(a)")
            XCTAssertEqual(d.screen[32 + 607, 479], d.back[607, 479], "present a \(a)")
        }
        d.fadeEnd()
        XCTAssertTrue(d.back.pixels.allSatisfy { $0 == 0 })
        // a = 32 is a no-op even on bit 15 (`1001ec8c cmplwi r29,0x20; beq`).
        var e = DisplayBuffers()
        e.back.fill(0xFFFF)
        e.fadeBegin(.toBlack)
        e.fadeStep(.toBlack, a: 32, present: .fullScreen)
        XCTAssertTrue(e.back.pixels.allSatisfy { $0 == 0xFFFF })
    }

    // MARK: - Helpers

    private func assertUnchangedOutside(_ buf: Pixmap555, _ base: Pixmap555, _ r: MacRect,
                                        file: StaticString = #filePath, line: UInt = #line) {
        for y in 0..<buf.height {
            for x in 0..<buf.width where !(x >= Int(r.left) && x < Int(r.right) && y >= Int(r.top) && y < Int(r.bottom)) {
                if buf[x, y] != base[x, y] { return XCTFail("changed outside \(r) at (\(x), \(y))", file: file, line: line) }
            }
        }
    }
}

/// SplitMix64 — a seeded, deterministic generator for the randomised twin test.
private struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func int(_ r: ClosedRange<Int>) -> Int { r.lowerBound + Int(next() % UInt64(r.count)) }
}

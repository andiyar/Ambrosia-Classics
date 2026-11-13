import XCTest
@testable import DeimosCore

/// Particles, debris and motion blur (plan C13; particles-debris-blur §1–§4, listing `10043340..10044834`,
/// `1002a6d0..1002a91c`, `10046840..100470f0`).
final class EffectsTests: XCTestCase {
    private func floats() throws -> [Float] { try AssetsTests.loaded.get().floats }

    private func system() throws -> ParticleSystem {
        let f = try floats()
        // The flli values every number below depends on (data-tags §3; §2.5, §2.7, §2.8).
        XCTAssertEqual(f[54], 416)
        XCTAssertEqual(f[55], 480)
        XCTAssertEqual(f[144], Float(0.96))
        XCTAssertEqual(f[145], Float(0.12))
        XCTAssertEqual(f[146], Float(0.6))
        XCTAssertEqual(f[148], 1)
        return ParticleSystem(floats: f)
    }

    private func request(_ type: String, x: Float = 200, y: Float = 240, colour: UInt16 = 0x7FFF,
                         delay: Int32 = 0, ground: Bool = false) -> ParticleRequest {
        ParticleRequest(x: x, y: y, colour: colour, delay: delay, ground: ground, type: FourCC(type)!)
    }

    /// §2.3 (`10043388..10043478`): N = 5/10/20/40, one `R(0,4)` per particle at the call (`1004378c`); `ci` →
    /// ring table; unknown / `none` / 0 → no group, no draw.
    func testBurstCountsAndDraws() throws {
        let base = try system()
        for (type, n) in [("tiny", 5), ("smal", 10), ("med ", 20), ("larg", 40)] {
            var s = base
            var rng = MSLRandom(seed: 0x469c2)
            s.emit(request(type), rng: &rng)
            XCTAssertEqual(rng.draws, UInt64(n), type)
            XCTAssertEqual(s.groups.count, 1, type)
            XCTAssertEqual(s.groups[0].particles.count, n, type)
            XCTAssertFalse(s.groups[0].ring, type)
            XCTAssertEqual(s.groups[0].smallSpeed, n <= 10, type)
            XCTAssertEqual(s.burstIndex, Int32(50 + n), type)
            XCTAssertEqual(s.ringIndex, 79, type)
        }
        // meci: 20 draws, ring table from entry 79; the index wraps at 99 → 0 (`100437e8..100437f8`).
        var ring = base
        var rng = MSLRandom(seed: 0x469c2)
        ring.emit(request("meci"), rng: &rng)
        XCTAssertEqual(rng.draws, 20)
        XCTAssertTrue(ring.groups[0].ring)
        XCTAssertFalse(ring.groups[0].smallSpeed)
        XCTAssertEqual(ring.ringIndex, 0)
        XCTAssertEqual(ring.burstIndex, 50)
        // particle 0 = ring[79] × 5.0 (fmuls).
        XCTAssertEqual(ring.groups[0].particles[0].vx, base.ringTable[79].x * 5)
        XCTAssertEqual(ring.groups[0].particles[0].vy, base.ringTable[79].y * 5)
        // Unknown IDs: nothing at all.
        for raw: UInt32 in [FourCC("none")!.rawValue, 0, FourCC("huge")!.rawValue] {
            var s = base
            var r = MSLRandom(seed: 1)
            s.emit(ParticleRequest(x: 1, y: 1, colour: 0, type: FourCC(rawValue: raw)), rng: &r)
            XCTAssertEqual(r.draws, 0)
            XCTAssertEqual(r.state, 1)
            XCTAssertTrue(s.groups.isEmpty)
            XCTAssertEqual(s, base)
        }
    }

    /// §2.7, p14, re-derived from `10043518..1004373c`: 0x7FFF → core channels 30, 27, 23, 19, 16 and fringe 18,
    /// 16, 14, 11, 9 for variants 0…4; each particle takes the variant of its own `R(0,4)`.
    func testColourVariants() throws {
        let f = try floats()
        let v = ParticleSystem.colourVariants(0x7FFF, variation: f[145], fringeAdjust: f[146])
        func grey(_ c: UInt16) -> UInt16 { c << 10 | c << 5 | c }
        XCTAssertEqual(v.core, [30, 27, 23, 19, 16].map(grey))
        XCTAssertEqual(v.fringe, [18, 16, 14, 11, 9].map(grey))
        XCTAssertEqual(v.core[0], 0x7BDE)
        XCTAssertEqual(v.fringe[0], 0x4A52)
        // The worked example's F898F8 → pix16 (31,19,31) (§ worked example).
        let psbu = ParticleSystem.colourVariants(31 << 10 | 19 << 5 | 31, variation: f[145], fringeAdjust: f[146])
        XCTAssertEqual(psbu.core, [0x7A5E, 0x6E1B, 0x5DD7, 0x4D93, 0x4130])
        XCTAssertEqual(psbu.fringe, [0x4972, 0x4150, 0x390E, 0x2CEB, 0x24A9])
        // Emit: particle k's colours are variant R(0,4)_k on the game generator.
        var s = try system()
        var rng = MSLRandom(seed: 0x469c2)
        var twin = rng
        s.emit(request("smal"), rng: &rng)
        for p in s.groups[0].particles {
            let k = Int(twin.range(Int32(0), Int32(4)))
            XCTAssertEqual(p.core, v.core[k])
            XCTAssertEqual(p.fringe, v.fringe[k])
            XCTAssertEqual(p.fade, 0)
            XCTAssertTrue(p.alive)
        }
        XCTAssertEqual(twin, rng)
    }

    /// §2.8 (`100438c0..10043b9c`): ×0.96 per axis per update (a drag, `fmuls`), move, fade 0 → 32 over 32 updates,
    /// removed on the 33rd; kill at x < −32, x + 7 > 448, y < 0, y + 7 > 480.
    func testParticleUpdateDragAndLife() throws {
        var s = try system()
        var rng = MSLRandom(seed: 3)
        s.emit(request("tiny", x: 200, y: 240), rng: &rng)
        let p0 = s.groups[0].particles[0]
        s.update(scrollDelta: 5)                                     // air group: the scroll does not move it
        let p1 = s.groups[0].particles[0]
        XCTAssertEqual(p1.vx.bitPattern, (p0.vx * Float(0.96)).bitPattern)
        XCTAssertEqual(p1.vy.bitPattern, (p0.vy * Float(0.96)).bitPattern)
        XCTAssertEqual(p1.x.bitPattern, (p0.x + p1.vx).bitPattern)
        XCTAssertEqual(p1.y.bitPattern, (p0.y + p1.vy).bitPattern)
        XCTAssertEqual(p1.fade, 1)
        for n in 2...32 {
            s.update(scrollDelta: 0)
            XCTAssertEqual(s.groups.count, 1, "update \(n)")
            XCTAssertEqual(s.groups[0].particles[0].fade, Int32(n))
        }
        XCTAssertTrue(s.groups[0].particles.allSatisfy { $0.alive && $0.fade == 32 })
        s.update(scrollDelta: 0)                                     // the 33rd
        XCTAssertTrue(s.groups.isEmpty)

        // Ground groups ride the scroll first (100439d8..10043a00).
        var g = try system()
        g.groups = [ParticleGroup(ground: true, particles: [Particle(x: 100, y: 100)])]
        g.update(scrollDelta: 3)
        XCTAssertEqual(g.groups[0].particles[0].y, 103)

        // Bounds, zero velocity: each pair is (killed, kept) on one edge.
        let cases: [(Float, Float, Bool)] = [
            (-32.5, 100, false), (-32, 100, true),                   // x < −32.0
            (441.5, 100, false), (441, 100, true),                   // x + 7 > 448
            (100, -0.5, false), (100, 0, true),                      // y < 0.0
            (100, 473.5, false), (100, 473, true),                   // y + 7 > 480 (ble keeps)
        ]
        // NaN: the x tests and the top test (`blt`/`bgt`) let it through; the bottom test keeps only on `ble`
        // (`10043aa8`), so a NaN y dies and a NaN x lives.
        let nan = Float.nan
        for (x, y, alive) in cases + [(nan, 100, true), (100, nan, false)] {
            var b = try system()
            b.groups = [ParticleGroup(particles: [Particle(x: x, y: y), Particle(x: 200, y: 200)])]
            b.update(scrollDelta: 0)
            XCTAssertEqual(b.groups[0].particles[0].alive, alive, "(\(x), \(y))")
            XCTAssertEqual(b.groups[0].particles[0].fade, alive ? 1 : 0)
        }
        var bounded = 0
        var c = try system()
        c.groups = [ParticleGroup(particles: [Particle(x: -40, y: 100)])]
        while !c.groups.isEmpty {
            bounded += 1
            if bounded > 64 { return XCTFail("group never freed (bound 64 updates)") }
            c.update(scrollDelta: 0)
        }
        XCTAssertEqual(bounded, 1)
    }

    /// §2.5 (`10044630..10044834`, `100431f0..10043244`): 300 table draws + 2 index draws from seed 1 → burst
    /// index 50, ring index 79; entries 50..54 as the bank's simulation.
    func testStartIndicesFromSeedOne() throws {
        let s = try system()
        XCTAssertEqual(s.appStartDraws, 302)
        XCTAssertEqual(s.burstIndex, 50)
        XCTAssertEqual(s.ringIndex, 79)
        XCTAssertEqual(s.burstTable.count, 100)
        XCTAssertEqual(s.ringTable.count, 100)
        let bank: [(Float, Float)] = [(0.3346, -0.4365), (-0.9206, -0.3905), (0.0, 0.85), (-0.5189, -0.1823),
                                      (-0.3003, -0.6323)]
        for (i, e) in bank.enumerated() {
            XCTAssertEqual(s.burstTable[50 + i].x, e.0, accuracy: 0.00006)
            XCTAssertEqual(s.burstTable[50 + i].y, e.1, accuracy: 0.00006)
        }
        // Entry 52 is exactly (0, 0.85): x = 208 hits the centre column, k = 1 (frsp of 1.0 × 0.85).
        XCTAssertEqual(s.burstTable[52].x, 0)
        XCTAssertEqual(s.burstTable[52].y.bitPattern, 0x3f59_999a)
        // Both tables locked bit-for-bit: FNV-1a 64 over each entry's x then y float bits, little-endian bytes
        // (golden from an independent Python float32 model of 10044630..10044818, MSL rand from seed 1).
        func fnv(_ t: [ParticleVector]) -> UInt64 {
            var h: UInt64 = 0xcbf2_9ce4_8422_2325
            for v in t {
                for f in [v.x, v.y] {
                    var bits = f.bitPattern
                    for _ in 0..<4 {
                        h ^= UInt64(bits & 0xff)
                        h = h &* 0x0000_0100_0000_01b3
                        bits >>= 8
                    }
                }
            }
            return h
        }
        XCTAssertEqual(fnv(s.burstTable), 0x1daa_1694_0f4c_13f2)
        XCTAssertEqual(fnv(s.ringTable), 0x6b6a_2a02_6564_cb96)
        // The ring table holds the unscaled unit vectors.
        for v in s.ringTable { XCTAssertEqual(v.x * v.x + v.y * v.y, 1, accuracy: 1e-5) }
        // The level reset keeps both indices.
        var t = s
        var rng = MSLRandom(seed: 9)
        t.emit(request("tiny"), rng: &rng)
        t.levelReset()
        XCTAssertTrue(t.groups.isEmpty)
        XCTAssertEqual(t.burstIndex, 55)
    }

    /// §2.9 (`10043d30..100444e8`): A = min(f+22,31), B = min(f+10,31), C = min(f+6,31), D = E = f, X = f > 6 ?
    /// f − 7 : f; E and X blend the core, A–D the fringe.
    func testStampWeights() {
        func grid(_ a: Int32, _ b: Int32, _ c: Int32, _ d: Int32, _ x: Int32) -> [Int32] {
            [a, a, b, b, b, a, a,
             a, b, c, c, c, b, a,
             b, c, d, d, d, c, b,
             b, c, d, x, d, c, b,
             b, c, d, d, d, c, b,
             a, b, c, c, c, b, a,
             a, a, b, b, b, a, a]
        }
        XCTAssertEqual(ParticleSystem.stampWeights(fade: 0).map(\.weight), grid(22, 10, 6, 0, 0))
        XCTAssertEqual(ParticleSystem.stampWeights(fade: 6).map(\.weight), grid(28, 16, 12, 6, 6))
        XCTAssertEqual(ParticleSystem.stampWeights(fade: 7).map(\.weight), grid(29, 17, 13, 7, 0), "centre snaps back")
        XCTAssertEqual(ParticleSystem.stampWeights(fade: 32).map(\.weight), grid(31, 31, 31, 32, 25))
        // The fades R4's tests use: 26 (caps), −1 (unsigned compares, word wrap — 0xFFFFFFFF + 22 = 21, X = −8).
        XCTAssertEqual(ParticleSystem.stampWeights(fade: 26).map(\.weight), grid(31, 31, 31, 26, 19))
        XCTAssertEqual(ParticleSystem.stampWeights(fade: -1).map(\.weight), grid(21, 9, 5, -1, -8))
        let core = ParticleSystem.stampWeights(fade: 0).enumerated().filter(\.element.core).map(\.offset)
        XCTAssertEqual(core, [17, 23, 24, 25, 31], "E at (2,3) (3,2) (3,4) (4,3), X at (3,3)")
    }

    /// §3 (`1002a6d0..1002a91c`): the rects ride the scroll (top/bottom only) and block inclusively; no RNG.
    func testDebrisRidesScrollAndBlocks() {
        var d = DebrisList()
        d.add(MacRect(top: 100, left: 50, bottom: 120, right: 80))
        d.add(MacRect(top: 300, left: 0, bottom: 310, right: 10))
        d.update(scrollDelta: 3)
        XCTAssertEqual(d.rects[0], MacRect(top: 103, left: 50, bottom: 123, right: 80))
        XCTAssertEqual(d.count, 2)
        let r = d.rects[0]
        // Touching each edge hits; one pixel off misses.
        XCTAssertTrue(d.hits(MacRect(top: 90, left: 60, bottom: r.top, right: 70)))
        XCTAssertFalse(d.hits(MacRect(top: 90, left: 60, bottom: r.top - 1, right: 70)))
        XCTAssertTrue(d.hits(MacRect(top: r.bottom, left: 60, bottom: 140, right: 70)))
        XCTAssertFalse(d.hits(MacRect(top: r.bottom + 1, left: 60, bottom: 140, right: 70)))
        XCTAssertTrue(d.hits(MacRect(top: 110, left: 40, bottom: 115, right: r.left)))
        XCTAssertFalse(d.hits(MacRect(top: 110, left: 40, bottom: 115, right: r.left - 1)))
        XCTAssertTrue(d.hits(MacRect(top: 110, left: r.right, bottom: 115, right: 90)))
        XCTAssertFalse(d.hits(MacRect(top: 110, left: r.right + 1, bottom: 115, right: 90)))
        // Never removed by scrolling off; only the level reset frees them.
        for _ in 0..<1000 { d.update(scrollDelta: 5) }
        XCTAssertEqual(d.count, 2)
        d.levelReset()
        XCTAssertEqual(d.count, 0)
        XCTAssertFalse(d.hits(MacRect(top: 0, left: 0, bottom: 10_000, right: 10_000)))
    }

    /// §4.3–§4.4: 50/10 stays in the blur list for 6 draw passes (vis 50, 40, 30, 20, 10, 0 — the vis-0 pass draws
    /// nothing, `FUN_10012f20` skips ≤ 0.0 at `10012f40..10012f48`) and is freed by the 6th update; +0x1a/+0x38
    /// forced 0, target 0.0; the glow stays stale without AllowGlow; the 1001st is refused, the message once.
    func testMotionBlurLifetime() throws {
        let f = try floats()
        var pool = MotionBlurPool()
        var e = GameObject()
        e.x = 120; e.y = 200; e.vx = 9
        e.face = FourCC("bu01")!
        e.adjustShadowForScaling = true
        e.drawShadow = true
        e.hitGlowOn = true; e.hitGlowLevel = 7
        XCTAssertEqual(pool.cachedFree, -1, "prealloc: scan")
        pool.levelReset()
        XCTAssertEqual(pool.cachedFree, 0, "FUN_10046d30 caches 0, not −1")
        XCTAssertEqual(pool.emit(MotionBlurRequest(object: e, initialVisibility: 50, visibilityDelta: 10)),
                       .emitted(slot: 0), "the level reset caches slot 0")
        let b = pool.slots[0]
        XCTAssertEqual(b.x, 120)
        XCTAssertEqual(b.y, 200)
        XCTAssertEqual(b.vx, 0, "velocity is not copied")
        XCTAssertEqual(b.face, e.face)
        XCTAssertFalse(b.adjustShadowForScaling)
        XCTAssertFalse(b.drawShadow)
        XCTAssertFalse(b.hitGlowOn, "glow fields stay stale without AllowGlow")
        XCTAssertEqual(b.hitGlowLevel, 0)
        XCTAssertEqual(b.visibility, 50)
        XCTAssertEqual(b.visibilityTarget, 0)
        XCTAssertEqual(b.visibilityStep, 10)

        var passes = 0, drawn = 0
        var guardCount = 0
        while !pool.list.isEmpty {
            guardCount += 1
            if guardCount > 20 { return XCTFail("blur never freed (bound 20 ticks)") }
            passes += 1
            if !pool.drawCommands(hOffset: 0, floats: f).isEmpty { drawn += 1 }
            pool.update()
        }
        XCTAssertEqual(passes, 6)
        XCTAssertEqual(drawn, 5)
        XCTAssertEqual(pool.count, 0)
        XCTAssertEqual(pool.cachedFree, 0)

        // AllowGlow copies the glow.
        XCTAssertEqual(pool.emit(MotionBlurRequest(object: e, initialVisibility: 100, visibilityDelta: 20,
                                                   allowGlow: true)), .emitted(slot: 0))
        XCTAssertTrue(pool.slots[0].hitGlowOn)
        XCTAssertEqual(pool.slots[0].hitGlowLevel, 7)

        // Capacity: 1000 in use, then refusals — the message only on the first (10046ed0..10046f14).
        var full = MotionBlurPool()
        full.levelReset()
        for i in 0..<MotionBlurPool.capacity {
            XCTAssertEqual(full.emit(MotionBlurRequest(object: e, initialVisibility: 50, visibilityDelta: 10)),
                           .emitted(slot: i))
        }
        XCTAssertEqual(full.emit(MotionBlurRequest(object: e, initialVisibility: 50, visibilityDelta: 10)),
                       .refused(postLimitMessage: true))
        XCTAssertEqual(full.emit(MotionBlurRequest(object: e, initialVisibility: 50, visibilityDelta: 10)),
                       .refused(postLimitMessage: false))
        XCTAssertEqual(full.count, 1000)
        full.levelReset()
        XCTAssertEqual(full.emit(MotionBlurRequest(object: e, initialVisibility: 50, visibilityDelta: 10)),
                       .emitted(slot: 0))
    }

    /// §2.9 (`10043c5c..10043d48`): delayed groups neither move nor draw; `sx = x − hOffset`; drawn only inside
    /// `sx ≥ 0, sx + 7 < 416, y ≥ 0, y + 7 < 480`; the stamp is top-left at (trunc sx, trunc y).
    func testStampsSkipDelayedAndOutside() throws {
        var s = try system()
        s.groups = [
            ParticleGroup(delay: 2, particles: [Particle(core: 1, fringe: 2, x: 100, y: 100, vx: 1)]),
            ParticleGroup(particles: [
                Particle(core: 3, fringe: 4, fade: 5, x: 130.9, y: 200.7),
                Particle(core: 0, fringe: 0, x: 29.5, y: 10),          // sx = −0.5
                Particle(core: 0, fringe: 0, x: 30, y: 10),            // sx = 0
                Particle(core: 0, fringe: 0, x: 438.5, y: 10),         // sx + 7 = 415.5
                Particle(core: 0, fringe: 0, x: 439, y: 10),           // sx + 7 = 416
                Particle(core: 0, fringe: 0, x: 100, y: -0.25),
                Particle(core: 0, fringe: 0, x: 100, y: 472.5),        // y + 7 = 479.5
                Particle(core: 0, fringe: 0, x: 100, y: 473),          // y + 7 = 480
                Particle(alive: false, core: 9, fringe: 9, x: 100, y: 100),
            ]),
        ]
        let stamps = s.stamps(hOffset: 30)
        XCTAssertEqual(stamps, [
            ParticleStamp(x: 100, y: 200, core: 3, fringe: 4, fade: 5),
            ParticleStamp(x: 0, y: 10, core: 0, fringe: 0, fade: 0),
            ParticleStamp(x: 408, y: 10, core: 0, fringe: 0, fade: 0),
            ParticleStamp(x: 70, y: 472, core: 0, fringe: 0, fade: 0),
        ])
        // The delayed group: delay 2 → 1 (still skipped, unmoved), then 0 → moves and draws.
        s.groups.removeLast()
        s.update(scrollDelta: 0)
        XCTAssertEqual(s.groups[0].delay, 1)
        XCTAssertEqual(s.groups[0].particles[0].x, 100)
        XCTAssertTrue(s.stamps(hOffset: 0).isEmpty)
        s.update(scrollDelta: 0)
        XCTAssertEqual(s.groups[0].delay, 0)
        XCTAssertEqual(s.groups[0].particles[0].x, 100 + Float(0.96))
        XCTAssertEqual(s.stamps(hOffset: 0).count, 1)
    }
}

import XCTest
import HectorResources
@testable import FerazelCore

/// EF (docs/plans/2026-10-24-ferazel-phase4.md): the Effect class's Setup and Handle arms — the explosion package
/// (`.SetupEffectSprite @ 10060680`, M l. 53688–53863), the explosion light schedule and the debris 3099
/// (`.HandleEffectSprite @ 10061160`, M l. 54024–54286; `.HitEffectTileSprite @ 100619a0`, M l. 54298–54324), the big
/// explosion's hurt (`.HitPlayerSprite`'s Effect arm, M l. 49763–49799), the mask flash (`.PaintFrameWrap` M l.
/// 9437–9447) and the camera shake (`.FindUpperLeftCorner` M l. 6147–6162). The expected draws are re-derived from a
/// copy of the stream at the call site; the geometry from the dump's arithmetic next to each assertion.
final class EffectTests: XCTestCase {

    private func level1() throws -> LevelFile {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        return try LevelFile.load(from: r, level: 1)
    }

    /// A 16×16 grid with a kind-3 FG floor on row 12 (FG kind = tile, BG empty), as `PlayerTileTests`.
    private func floorWorld() throws -> SpriteWorld {
        let w = SpriteWorld(level: try level1())
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    func testExplosionPackageDraws() throws {
        let w = SpriteWorld(level: try level1())
        var lights = LightTable()
        var rng = w.rng
        // Id 0 at (400, 300), prefs+6 = 1, no plume yet: 45 × (R(2000), R(2000), R(2)) → `.NewParticle(1, 0x96,
        // (y + 0x18, x + 0x10), r2 + 1, r1 − 1000, r0 − 1000, 0, 1)` (M l. 53774–53783), in this order.
        var expected: [ParticlePool.Record] = []
        for _ in 0..<0x2d {
            let r0 = Int32(rng.next(2000)), r1 = Int32(rng.next(2000)), r2 = Int16(rng.next(2))
            var p = ParticlePool.Record()
            p.alive = true
            p.shape = r2 + 1
            p.kind = 1
            p.gravity = 0x96
            p.x = 416 << 8
            p.y = 324 << 8
            p.vx = r1 - 1000
            p.vy = r0 - 1000
            p.mode = 1
            expected.append(p)
        }
        let id = try XCTUnwrap(EffectSprite.spawn(w, type: 0, x: 400, y: 300, layer: 0x14, effects: 1, lights: &lights))
        XCTAssertEqual(Array(w.particles.records.prefix(0x2d)), expected)
        XCTAssertEqual(w.particles.counters.count, 0x2d)
        XCTAssertEqual(w.rng.seed, rng.seed)                            // 135 draws, none after (plume, light)
        // The plume `MTNewSprite(0x4b6, x − 8, y − 0x5a, 0x14, −1, Setup)` (M l. 53788–53792): its Setup stores
        // layer 0xb and counts it (M l. 53740–53742); it is inserted before the explosion (made inside its Setup).
        XCTAssertEqual(w.active.sprites.map(\.type), [EffectSprite.plume, 0])
        let plume = w.active.sprites[0]
        XCTAssertEqual([plume.x, plume.y, Int(plume.layer)], [392, 210, 0xb])
        XCTAssertEqual(w.plumeCount, 1)
        // The light `.AddLight(PICT 813, (y + 0x18, x + 0x18), 0, 0, 0, 0x16)` → `+0x9a` (M l. 53794–53797).
        let e = try XCTUnwrap(w.active.record(id: id))
        XCTAssertEqual(e.light, 0)
        XCTAssertEqual(lights.slots[0].face, LightFaceRef(pict: 0x32d, width: 0x48, height: 0x48))
        XCTAssertEqual([lights.slots[0].x, lights.slots[0].y, lights.slots[0].colour], [424, 324, 0x16])
        XCTAssertEqual(lights.count, 1)
        XCTAssertEqual(Int(e.layer), 0xb)

        // Three plumes alive → none; prefs+6 = 2 → none (M l. 53786–53787).
        w.plumeCount = 3
        EffectSprite.spawn(w, type: 3, x: 0, y: 0, layer: 0xb, effects: 1, lights: &lights)
        w.plumeCount = 0
        EffectSprite.spawn(w, type: 3, x: 0, y: 0, layer: 0xb, effects: 2, lights: &lights)
        XCTAssertEqual(w.active.sprites.filter { $0.type == EffectSprite.plume }.count, 1)

        // Id 1090 (0x442): kind 4, no plume, no light, layer 0x7fbc (M l. 53768–53770, 53785, 53793, 53805).
        let w2 = SpriteWorld(level: try level1())
        var l2 = LightTable()
        let smoke = try XCTUnwrap(EffectSprite.spawn(w2, type: 0x442, x: 100, y: 100, layer: 0xb, effects: 1,
                                                     lights: &l2))
        XCTAssertEqual(Set(w2.particles.records.prefix(0x2d).map(\.kind)), [4])
        XCTAssertEqual(w2.particles.counters.count, 0x2d)
        XCTAssertEqual(w2.active.sprites.count, 1)
        XCTAssertEqual(w2.active.record(id: smoke)?.light, -1)
        XCTAssertEqual(l2.count, 0)
        XCTAssertEqual(w2.active.record(id: smoke)?.layer, 0x7fbc)
        // Id 2 → kind 9; id 1207 → kind 1 at the big centre (x + 0x20, y + 0x30), light at (x + 0x30, y + 0x30), no
        // plume; 3201 (≥ 0xc80) and the skip list → no draws, no light.
        let w3 = SpriteWorld(level: try level1())
        var l3 = LightTable()
        EffectSprite.spawn(w3, type: 2, x: 0, y: 0, layer: 0xb, effects: 2, lights: &l3)
        XCTAssertEqual(Set(w3.particles.records.prefix(0x2d).map(\.kind)), [9])
        w3.particles = ParticlePool()
        EffectSprite.spawn(w3, type: EffectSprite.bigExplosion, x: 100, y: 200, layer: 0xc, effects: 1, lights: &l3)
        XCTAssertEqual(Set(w3.particles.records.prefix(0x2d).map { [$0.kind, Int16($0.x >> 8), Int16($0.y >> 8)] }),
                       [[1, 132, 248]])
        XCTAssertEqual([l3.slots[1].x, l3.slots[1].y], [148, 248])
        XCTAssertEqual(w3.plumeCount, 0)
        let seed = w3.rng.seed
        w3.particles = ParticlePool()
        for t: Int16 in [0xc81, 0x4b1, 0x4ba, 0xcb2, 0xcb3] {
            EffectSprite.spawn(w3, type: t, x: 0, y: 0, layer: 0xb, effects: 1, lights: &l3)
        }
        XCTAssertEqual(w3.rng.seed, seed)
        XCTAssertEqual(w3.particles.counters.count, 0)
        XCTAssertEqual(l3.count, 2)
        // The balloons' layers: 3250 → 100, 3251… → 101 (M l. 53799–53804).
        XCTAssertEqual(w3.active.sprites.filter { $0.type >= 0xcb2 }.map(\.layer), [100, 101])
    }

    func testExplosionLightSchedule() throws {
        let w = SpriteWorld(level: try level1())
        var lights = LightTable()
        let id = try XCTUnwrap(EffectSprite.spawn(w, type: 0, x: 400, y: 300, layer: 0xb, effects: 2, lights: &lights))
        let slot = Int(try XCTUnwrap(w.active.record(id: id)).light)
        var faces: [Int16?] = [lights.slots[slot].face?.pict]
        var removed: [Int] = []
        var killed: [Int] = []
        for k in 1...26 {
            EffectSprite.handle(world: w, id: id, lights: &lights, effects: 2)
            let s = try XCTUnwrap(w.active.record(id: id))
            faces.append(lights.slots[slot].face?.pict)
            if lights.slots[slot].removing { removed.append(k) }
            if s.dead { killed.append(k) }
            // Face 0x4b0[`+0x46` >> 1] while `+0x46` < 0x1a, then none (M l. 54243–54255); id 0 is untinted.
            XCTAssertEqual(s.face, k < 26 ? FaceRef(pict: 0x4b0, index: k >> 1, set: .encoded) : nil, "frame \(k)")
            XCTAssertEqual(s.mode, 0)
        }
        // 813 → 812 at 2, 811 at 4, 810 at 6, 811 at 14, 812 at 17, 813 at 20, removed at 23 (M l. 54213–54241).
        let schedule: [Int16?] = [813, 813, 812, 812, 811, 811] + [Int16?](repeating: 810, count: 8)
            + [811, 811, 811, 812, 812, 812, 813, 813, 813] + [Int16?](repeating: nil, count: 4)
        XCTAssertEqual(faces, schedule)
        XCTAssertEqual(removed.first, 23)
        XCTAssertEqual(killed, [26])
        XCTAssertEqual(lights.count, 0)
        // Ids 1…15 draw tinted (`+0xb8 = 0x10000 + id`, M l. 54205–54207); 3201 runs the same arm with no light.
        var l2 = LightTable()
        let tinted = try XCTUnwrap(EffectSprite.spawn(w, type: 7, x: 0, y: 0, layer: 0xb, effects: 2, lights: &l2))
        let late = try XCTUnwrap(EffectSprite.spawn(w, type: 0xc81, x: 0, y: 0, layer: 0xb, effects: 2, lights: &l2))
        EffectSprite.handle(world: w, id: tinted, lights: &l2, effects: 2)
        EffectSprite.handle(world: w, id: late, lights: &l2, effects: 2)
        XCTAssertEqual(w.active.record(id: tinted)?.mode, 0x10007)
        XCTAssertEqual(w.active.record(id: late)?.mode, 0)
        XCTAssertEqual(w.active.record(id: late)?.face, FaceRef(pict: 0x4b0, index: 0, set: .encoded))
        // The plume 1206: `+0xb8 = 0xb0004`, face 0x4b6[`+0x46`] up to 33, killed at 34 with the count − 1.
        let w2 = SpriteWorld(level: try level1())
        var l3 = LightTable()
        EffectSprite.spawn(w2, type: 0, x: 400, y: 300, layer: 0xb, effects: 1, lights: &l3)
        let plume = try XCTUnwrap(w2.active.sprites.first?.id)
        for k in 1...34 {
            EffectSprite.handle(world: w2, id: plume, lights: &l3, effects: 1)
            let p = try XCTUnwrap(w2.active.record(id: plume))
            XCTAssertEqual(p.mode, 0xb0004)
            XCTAssertEqual(p.face, k < 34 ? FaceRef(pict: EffectSprite.plume, index: k, set: .encoded) : nil)
            XCTAssertEqual(p.dead, k == 34)
        }
        XCTAssertEqual(w2.plumeCount, 0)
    }

    func testBigExplosionHurtsEarly() throws {
        let w = try floorWorld()
        let pid = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
        var lights = LightTable()
        let e = try XCTUnwrap(EffectSprite.spawn(w, type: EffectSprite.bigExplosion, x: 80, y: 190, layer: 0xc,
                                                 effects: 2, lights: &lights))
        let big = try XCTUnwrap(w.active.record(id: e))
        // `SetRect(+0x34, 8, 8, 0x58, 0x58)`, `+0xeb = 2` (M l. 53737–53740).
        XCTAssertEqual(big.hotRect, IdleSprites.Rect(top: 8, left: 8, bottom: 0x58, right: 0x58))
        XCTAssertEqual(big.crunches, 2)
        // Frames 0…7 hurt: `.HurtSprite(player, 0x70, +300 (the effect's centre x is left of the player's), −0x640,
        // 0x3c, 0xc)` and the stun `_DAT_100a0748 = 1` (M l. 49763–49799); frame 8 does not.
        for n: Int16 in 0...8 {
            w.active.update(id: pid) { s in
                s.hp = 0x300; s.invulnerable = 0; s.flash = 0; s.vx = 0; s.vy = 0; s.centre = SpriteSlot.Point(x: 150, y: 250)
            }
            w.active.update(id: e) { s in s.phase = n; s.centre = SpriteSlot.Point(x: 128, y: 238) }
            w.player.stun = 0
            HitPlayerSprite.hit(w, player: pid, other: e)
            let p = try XCTUnwrap(w.active.record(id: pid))
            if n <= 7 {
                XCTAssertEqual([p.hp, Int16(p.vx), Int16(p.vy), p.invulnerable, p.flash, w.player.stun],
                               [0x300 - 0x70, 300, -0x640, 0x3c, 0xc, 1], "frame \(n)")
            } else {
                XCTAssertEqual([p.hp, Int16(p.vx), Int16(p.vy), p.invulnerable, w.player.stun], [0x300, 0, 0, 0, 0])
            }
        }
        // Right of the player → −300; an invulnerable player takes nothing and is not stunned; a 1201 never hurts.
        w.active.update(id: pid) { s in s.hp = 0x300; s.invulnerable = 0; s.vx = 0 }
        w.active.update(id: e) { s in s.phase = 3; s.centre = SpriteSlot.Point(x: 151, y: 238) }
        HitPlayerSprite.hit(w, player: pid, other: e)
        XCTAssertEqual(w.active.record(id: pid)?.vx, -300)
        w.player.stun = 0
        HitPlayerSprite.hit(w, player: pid, other: e)
        XCTAssertEqual([w.active.record(id: pid)?.hp, w.player.stun], [0x300 - 0x70, 0])
        w.active.update(id: pid) { s in s.invulnerable = 0 }
        w.active.update(id: e) { s in s.type = EffectSprite.dust; s.phase = 0 }
        HitPlayerSprite.hit(w, player: pid, other: e)
        XCTAssertEqual(w.active.record(id: pid)?.hp, 0x300 - 0x70)

        // The crunch pass (`.HitEffectTileSprite` layer 2, M l. 54318–54320; raw `10061a74..10061a84`):
        // `.CrunchTile(pos, +0xeb)` — strength 2 breaks a kind-2 cell (424); an effect without `+0xeb` does nothing.
        func crunchWorld() throws -> SpriteWorld {
            let c = SpriteWorld(level: try level1())
            var fg = [UInt16](repeating: 0, count: 16 * 16)
            fg[5 * 16 + 5] = 0x1200
            c.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: c.tiles.bg, fgKinds: c.tiles.fgKinds,
                               bgKinds: c.tiles.bgKinds)
            return c
        }
        let at = TilePos(x: 160, y: 160)
        let c = try crunchWorld()
        var cl = LightTable()
        let b = try XCTUnwrap(EffectSprite.spawn(c, type: EffectSprite.bigExplosion, x: 140, y: 140, layer: 0xc,
                                                 effects: 2, lights: &cl))
        EffectSprite.hitTile(TileSolver(world: c), id: b, pos: at, kind: 1, layer: .crunch)
        XCTAssertEqual(c.tiles.fg.cell(col: 5, row: 5) >> 12, 0)
        XCTAssertEqual(c.player.cues.map(\.snd), [424])
        let c2 = try crunchWorld()
        let plain = try XCTUnwrap(EffectSprite.spawn(c2, type: 0, x: 140, y: 140, layer: 0xb, effects: 2, lights: &cl))
        EffectSprite.hitTile(TileSolver(world: c2), id: plain, pos: at, kind: 1, layer: .crunch)
        XCTAssertEqual(c2.tiles.fg.cell(col: 5, row: 5), 0x1200)
        XCTAssertEqual(c2.player.cues, [])
    }

    func testDebrisBounces() throws {
        let w = try floorWorld()
        var lights = LightTable()
        var rng = w.rng
        let variant: Int32 = rng.next(100) < 0x33 ? 1 : 0
        let start = rng.next(8)
        // `.SetupEffectSprite`'s 0xc1b arm (M l. 53811–53823): R(100) < 0x33 → `+0x14c` 1; `+0x46` = R(8); gravity
        // 0x5a; `SetRect(+0x34, 10, 10, 0xe, 0xe)`; no package (3099 is in the skip list).
        let id = try XCTUnwrap(EffectSprite.spawn(w, type: EffectSprite.debris, x: 200, y: 250, layer: 0xb, effects: 1,
                                                  lights: &lights))
        let d = try XCTUnwrap(w.active.record(id: id))
        XCTAssertEqual([d.classTimer, Int32(d.phase), Int32(d.gravity)], [variant, Int32(start), 0x5a])
        XCTAssertEqual(d.hotRect, IdleSprites.Rect(top: 10, left: 10, bottom: 14, right: 14))
        XCTAssertEqual(w.rng.seed, rng.seed)
        XCTAssertEqual(w.particles.counters.count, 0)
        XCTAssertEqual(d.light, -1)
        // Falling onto the floor: each FG `.WallBounce(…, 0x80, rect, 0, 0x80)` hit counts in `+0x16c`
        // (`.HitEffectTileSprite`, M l. 54302–54309); killed in the Handle that sees `+0x16c` > 3 (M l. 54183); at
        // prefs+6 = 1 the fade by count: 0 → 0, 1 → 0xb0001, 2 → 0xb0000, ≥ 3 → 0xb0002 (M l. 54186–54199).
        let fade: [Int32: UInt32] = [0: 0, 1: 0xb0001, 2: 0xb0000, 3: 0xb0002]
        var phase = start
        var seen = Set<Int32>()
        var killedAt: Int32?
        for _ in 0..<400 where killedAt == nil {
            EffectSprite.handle(world: w, id: id, lights: &lights, effects: 1)
            let s = try XCTUnwrap(w.active.record(id: id))
            phase = phase + 1 > 7 ? 0 : phase + 1
            XCTAssertEqual(s.face, FaceRef(pict: EffectSprite.debris, index: Int(phase) + (variant != 0 ? 8 : 0),
                                           set: .encoded))
            let n = s.classWord16c
            seen.insert(n)
            XCTAssertEqual(s.mode, fade[min(n, 3)], "bounces \(n)")
            if s.dead { killedAt = n } else { XCTAssertLessThanOrEqual(n, 3) }
        }
        XCTAssertEqual(killedAt.map { $0 > 3 }, true)
        XCTAssertTrue(seen.contains(1))
        // The fade states by count directly (an airborne debris: no contact), and none at prefs+6 ≠ 1.
        for (n, m) in [(Int32(0), UInt32(0)), (1, 0xb0001), (2, 0xb0000), (3, 0xb0002), (4, 0xb0002)] {
            let a = try XCTUnwrap(EffectSprite.spawn(w, type: EffectSprite.debris, x: 100, y: 0, layer: 0xb, effects: 1,
                                                     lights: &lights))
            w.active.update(id: a) { $0.classWord16c = n; $0.mode = 0x123 }
            EffectSprite.handle(world: w, id: a, lights: &lights, effects: 1)
            XCTAssertEqual(w.active.record(id: a)?.mode, m, "count \(n)")
            XCTAssertEqual(w.active.record(id: a)?.dead, n == 4)
            w.active.update(id: a) { $0.dead = false; $0.mode = 0x123 }
            EffectSprite.handle(world: w, id: a, lights: &lights, effects: 2)
            XCTAssertEqual(w.active.record(id: a)?.mode, 0x123)
        }
    }

    func testFlashAlternates() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 1)
        _ = s.step(keys: KeyState())
        s.world.flash.count = 3
        func copies(_ ops: FrameOps) -> [String] {
            ops.draws.compactMap { op in
                switch op {
                case .copyToScreen: return "frame"
                case .copyMaskToScreen: return "mask"
                default: return nil
                }
            }
        }
        // Each drawn `.PaintFrameWrap`: count < 1 → toggle 0, else toggle = !toggle, count − 1; toggle on → the copy
        // reads the mask port `*_DAT_100a0008` (M l. 9437–9447).
        var seq: [String] = []
        var masks: [DrawOp] = []
        for _ in 0..<4 {
            let ops = s.step(keys: KeyState())
            XCTAssertTrue(ops.drawn)
            seq += copies(ops)
            masks += ops.draws.filter { if case .copyMaskToScreen = $0 { true } else { false } }
        }
        XCTAssertEqual(seq, ["mask", "frame", "mask", "frame"])
        XCTAssertEqual(s.world.flash, ScreenFlash(count: 0, on: false))
        let h = s.camera.scrollH, v = s.camera.scrollV
        XCTAssertEqual(masks.last, .copyMaskToScreen(h: h, v: v, graphicsMode: Int(s.prefs.graphics),
                                                     backdrop: s.prefs.plainCopy == 0))
        // The step alone.
        var f = ScreenFlash(count: 0, on: true)
        f.step()
        XCTAssertEqual(f, ScreenFlash(count: 0, on: false))
        f.count = -2
        f.step()
        XCTAssertEqual(f, ScreenFlash(count: -2, on: false))
    }

    func testCameraShake() throws {
        let L = try level1()
        func settled(graphics: Int16 = 1) throws -> Camera {
            var c = try Camera(header: L.header, spriteX: 1000, spriteY: 600)
            for _ in 0..<300 { c.findUpperLeftCorner(focusX: 1000, focusY: 700, graphics: graphics) }
            return c
        }
        var base = try settled()
        let v0 = base.scrollV
        base.findUpperLeftCorner(focusX: 1000, focusY: 700)
        XCTAssertEqual(base.scrollV, v0)
        XCTAssertEqual(v0 % 2, 0)
        XCTAssertTrue(20 < v0 && v0 < base.maxV - 20)
        // Shake 0x14, prefs+0 = 0: by the paint counter's bit 0 — even → v −= shake >> 1, odd → +=; shake − 1
        // (M l. 6147–6161). The eased pair is untouched, so each call offsets the same v.
        var c = try settled()
        c.shake = 0x14
        var got: [Int] = []
        for k in 0..<6 {
            c.findUpperLeftCorner(focusX: 1000, focusY: 700, counter: UInt32(k))
            got.append(c.scrollV - v0)
        }
        XCTAssertEqual(got, [-10, 9, -9, 8, -8, 7])
        XCTAssertEqual(c.shake, 0x14 - 6)
        XCTAssertEqual(c.v, base.v)
        // prefs+0 ≠ 0 (reduce frame rate): `& 3` instead of `& 1`.
        var r = try settled()
        r.shake = 0x14
        got = []
        for k: UInt32 in [0, 1, 2, 3, 4] {
            r.findUpperLeftCorner(focusX: 1000, focusY: 700, counter: k, reduceFrameRate: true)
            got.append(r.scrollV - v0)
        }
        XCTAssertEqual(got, [-10, 9, 9, 8, -8])
        // Run out: shake 0 → no offset, never below 0.
        var o = try settled()
        o.shake = 1
        o.findUpperLeftCorner(focusX: 1000, focusY: 700, counter: 0)
        XCTAssertEqual([o.scrollV - v0, Int(o.shake)], [0, 0])               // 1 >> 1 = 0, then 0
        o.findUpperLeftCorner(focusX: 1000, focusY: 700, counter: 0)
        XCTAssertEqual([o.scrollV - v0, Int(o.shake)], [0, 0])
        // Graphics 3 (and 2): the even-v rule after the shake rounds an odd v down.
        var g = try settled(graphics: 3)
        g.shake = 0x14
        got = []
        for k: UInt32 in 0..<4 {
            g.findUpperLeftCorner(focusX: 1000, focusY: 700, counter: k, graphics: 3)
            got.append(g.scrollV - v0)
        }
        XCTAssertEqual(got, [-10, 8, -10, 8])                                // −10, +9 → +8, −9 → −10, +8
    }
}

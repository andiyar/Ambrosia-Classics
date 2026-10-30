import XCTest
@testable import FerazelCore

/// WK1 (docs/plans/2026-10-30-ferazel-phase5.md): the Walker class for the thrower 1700 and the spear guard 1705 —
/// `.SetupWalkerSprite` (M l. 56898–57100), `.HandleWalkerSprite` (M l. 57507–58471), `.PopupGoblinCoins` (M l.
/// 57348–57506), `.HitWalkerSprite` (M l. 58506–58611), the corpse raft under `.HandlePlatformSprite` with
/// `.HandleFlotation` (M l. 38075–38124; enemies-ground-2 §1). A synthetic 40×16 grid over level 1's header: a floor of
/// FG kind 3 along row 12 (its surface at y 400); every expected draw is re-derived from a copy of the stream at the
/// call site.
final class WalkerTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The grid (floor row 12, kind 3; BG water — kind 200 — from row `waterRow` down when given) and the player's
    /// centre globals `*_DAT_1009fd94` / `fd90` at (`px`, `py`).
    private func world(px: Int16 = 600, py: Int16 = 340, waterRow: Int? = nil, floorKind: Int = 3,
                       floor: Bool = true) throws -> SpriteWorld {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        var fg = [UInt16](repeating: 0, count: 40 * 16), bg = fg
        if floor { for c in 0..<40 { fg[12 * 40 + c] = 4 } }            // tile 3 → `floorKind`
        if let r = waterRow { for row in r..<16 { for c in 0..<40 { bg[row * 40 + c] = 1 } } }
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[0] = 200
        var fgKinds = Array(0..<0x60)
        fgKinds[3] = floorKind
        w.tiles = TileGrid(fg: TileMap(width: 40, height: 16, cells: fg), bg: TileMap(width: 40, height: 16, cells: bg),
                           fgKinds: fgKinds, bgKinds: bgKinds)
        w.player.centreX = px
        w.player.centreY = py
        return w
    }

    /// A Walker of `type` placed (record 0) at (`x`, `y`) — `y` 330 stands the 1700's hot rect (bottom 70) on the floor —
    /// set up by `.SetupWalkerSprite` inside the counting window.
    private func walker(_ w: SpriteWorld, type: Int16 = 0x6a4, x: Int = 100, y: Int = 330, p1: Int16 = 0,
                        p2: Int16 = 0, p3: Int16 = 0) throws -> Int {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: 0, y: Int16(y),
                          x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = true
        let e = try SetupFaces.setup(p, context: c, lights: &lights, counting: &w.enemies, rng: &w.rng)
        w.enemies.window = false
        return w.active.insert(e.slot)
    }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One `.HandleWalkerSprite` call.
    @discardableResult
    private func frame(_ w: SpriteWorld, _ id: Int, _ solver: TileSolver,
                       faceBounds: @escaping (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) -> [DrawOp] {
        var lights = LightTable()
        return Walker.handle(world: w, id: id, solver: solver, lights: &lights, effects: 1, faceBounds: faceBounds)
    }

    /// The draws `.GoblinRandomCry` makes on `r` (no goblin voice playing): R(100), R(500), and at 50 R(10000).
    private func cry(_ r: inout FastRand) {
        _ = r.next(100)
        if r.next(500) == 0x32 { _ = r.next(10000) }
    }

    private func shots(_ w: SpriteWorld) -> [SpriteSlot] { w.active.sprites.filter { $0.handler == .enemyShot } }

    /// The first seed ≥ 1 whose stream makes `pick` true.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        var s: Int32 = 1
        while true {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
            s += 1
        }
    }

    // MARK: - Setup

    func testWalkerTierTable() throws {
        // enemies-ground §3.1 / M l. 57008–57078: (p3) → (`+0x158`, HP 1750, HP others, `+0xb8`, `+0x100`).
        let table: [Int16: (Int32, Int16, Int16, UInt32, Int32)] = [
            1: (16, 500, 250, 0x10010, 0), 2: (6, 1200, 675, 0x10011, 0), 3: (13, 1680, 950, 0x10012, 0),
            4: (4, 2000, 1500, 0x10013, 1), 5: (10, 1500, 850, 0x10014, 0), 6: (6, 1350, 750, 0x10015, 0),
        ]
        for p3: Int16 in -1...8 {
            for t: Int16 in [0x6a4, 0x6a9, 0x6d6, 0x6d7, 0x6e0] {
                let k = Walker.tier(p3: p3, type: t)
                guard let want = table[p3] else { XCTAssertNil(k, "p3 \(p3)"); continue }
                let got = try XCTUnwrap(k)
                XCTAssertEqual([Int(got.cooldown), Int(got.hp), Int(got.mode), Int(got.immune)],
                               [Int(want.0), Int(t == 0x6d6 ? want.1 : want.2), Int(want.3), Int(want.4)],
                               "p3 \(p3) type \(t)")
            }
        }
        // The Setup: the three draws in order, the class fields, the flip rule, the rect, the tier; no save write-back
        // flag (`+0x188`…`+0x18b`, `+0xea`: `.SetupWalkerSprite` stores none).
        let w = try world(px: 600)
        var r = w.rng
        let pitch = Int32(r.next(0x5fff)) * 2 + 0xbfff
        let reach = Int32(r.next(0x46)) + 0x78
        let w154 = Int32(r.next(400)) + 1000
        let a = try slot(w, try walker(w, x: 100, p3: 4))
        XCTAssertEqual(w.rng.seed, r.seed, "three draws")
        XCTAssertEqual([a.voicePitch, a.classTimer, a.classWord154, a.classWord150], [pitch, reach, w154, -1])
        XCTAssertEqual([Int(a.hp), Int(a.classWord158), Int(a.mode), Int(a.classWord100)], [1500, 4, 0x10013, 1])
        XCTAssertEqual([Int(a.subtype), Int(a.gravity), Int(a.layer), Int(a.counterA6)], [2, 0x151, 4, 0])
        XCTAssertEqual(a.handler, .walker)
        XCTAssertEqual([a.hasHit, a.hasTileHit, a.mirrored, a.setupDone, a.countedInTotals], [true, true, false, false, true])
        XCTAssertEqual([a.keepRecord, a.noWriteBack189, a.noWriteBack18a, a.keepRecordAtKill, a.killedForGood],
                       [false, false, false, false, false])
        XCTAssertEqual(a.hotRect, IdleSprites.Rect(top: 10, left: 0x28, bottom: 0x46, right: 0x3c))
        XCTAssertEqual(a.face, FaceRef(pict: 0x6a4, index: 0, set: .encoded))
        XCTAssertEqual(w.enemies.live, 1)
        // 1705, the player left of `+0xc + 0x32`: flip 1, state 5, tier 3; 0x6e0 is flipped whatever the player (M l.
        // 56945–56950), its range 0x6e1… only with the player right of `+0xc + 0x32`.
        let g = try slot(w, try walker(w, type: 0x6a9, x: 600, p3: 3))
        XCTAssertEqual([Int(g.subtype), Int(g.hp), Int(g.classWord158), Int(g.classWord100)], [5, 950, 13, 0])
        XCTAssertTrue(g.mirrored)
        XCTAssertEqual(g.hotRect, IdleSprites.Rect(top: 10, left: 0x4c, bottom: 0x47, right: 0x7c))
        let b = try slot(w, try walker(w, type: 0x6e0, x: 100))
        XCTAssertEqual([Int(b.subtype), Int(b.hp), Int(b.classWord158), Int(b.mode)], [5, 500, 8, 0])
        XCTAssertTrue(b.mirrored)
        XCTAssertEqual(b.hotRect, IdleSprites.Rect(top: 0x1e, left: 0x17, bottom: 0x55, right: 0x38))
        XCTAssertTrue(try slot(w, try walker(w, type: 0x6e0, x: 600)).mirrored)
        XCTAssertFalse(try slot(w, try walker(w, type: 0x6e1, x: 600)).mirrored)
        XCTAssertTrue(try slot(w, try walker(w, type: 0x6e1, x: 100)).mirrored)
        XCTAssertFalse(try slot(w, try walker(w, type: 0x6e1, x: 550)).mirrored, "550 + 0x32 < 600 is false")
        XCTAssertTrue(try slot(w, try walker(w, type: 0x6e1, x: 549)).mirrored)
        XCTAssertTrue(try slot(w, try walker(w, type: 0x6a4, x: 551)).mirrored, "playerX 600 < 551 + 0x32")
        XCTAssertFalse(try slot(w, try walker(w, type: 0x6a4, x: 550)).mirrored)
        XCTAssertThrowsError(try walker(w, type: 0x6d6, x: 100), "1750's Setup is WK2's")
    }

    // MARK: - the thrower 1700

    func testThrowerWalksToRange() throws {
        // The player far right: target = P.x − `+0x14c`; the walker left of it walks right at 1000 (`.SetSpriteSpeed`
        // (1000, 0x200)), facing right (flip 0), its counter forward; inside ±25 at counter 0 or 3 it stops, state 2.
        let w = try world(px: 700)
        let solver = TileSolver(world: w)
        let id = try walker(w, x: 100)
        let d = Int(try slot(w, id).classTimer)
        var stopped = false
        for n in 1...400 {
            let before = try slot(w, id)
            frame(w, id, solver)
            let s = try slot(w, id)
            if before.subtype == 1 && before.groundKind != 0 {
                let cx = before.centre.x, target = 700 - d
                if cx < target - 0x19 {
                    XCTAssertEqual(s.vx, 1000, "frame \(n)")
                    XCTAssertEqual(Int(s.phase), (Int(before.phase) + 1) & 0xf, "frame \(n): forward")
                } else if s.subtype == 2 {
                    XCTAssertTrue([0, 3].contains(before.phase), "frame \(n)")
                    XCTAssertTrue(abs(cx - target) <= 0x19, "frame \(n): \(cx) vs \(target)")
                    XCTAssertEqual([Int(s.vx), Int(s.phase)], [0, 0])
                    stopped = true
                    break
                }
                XCTAssertEqual(s.face, FaceRef(pict: 0x6a5, index: Int(s.phase >> 1), set: .encoded), "frame \(n)")
                XCTAssertFalse(s.mirrored, "frame \(n): faces the player")
            }
        }
        XCTAssertTrue(stopped)
        // Too close (the walker right of target + 25, the player still right): it walks left, away from its facing —
        // the counter runs backwards (0 → 15).
        let w2 = try world(px: 300)
        let id2 = try walker(w2, x: 200)
        let solver2 = TileSolver(world: w2)
        for _ in 0..<3 { frame(w2, id2, solver2) }                      // lands; state 2 → out of range → state 1
        w2.active.update(id: id2) { $0.phase = 0 }
        let b = try slot(w2, id2)
        XCTAssertEqual(b.subtype, 1)
        XCTAssertLessThan(Int(b.centre.x), 300)
        XCTAssertGreaterThan(Int(b.centre.x), 300 - Int(b.classTimer) + 0x19)
        frame(w2, id2, solver2)
        let a = try slot(w2, id2)
        XCTAssertEqual([Int(a.vx), Int(a.phase)], [-1000, 15])
        XCTAssertFalse(a.mirrored)
        XCTAssertEqual(a.face, FaceRef(pict: 0x6a5, index: 7, set: .encoded))
        // The player left (target = P.x + `+0x14c`, flip 1): far right of the target it walks left, forward (+1); left
        // of target − 25 (too close) it walks right, away from its facing — backwards (−1).
        for (px, vx, step) in [(100, -1000, 1), (440, 1000, -1)] as [(Int16, Int32, Int)] {
            let w3 = try world(px: px)
            let s3 = TileSolver(world: w3)
            let id3 = try walker(w3, x: 400)
            for _ in 0..<3 { frame(w3, id3, s3) }
            w3.active.update(id: id3) { $0.phase = 4; $0.subtype = 1 }
            let c = try slot(w3, id3)
            let target = Int(px) + Int(c.classTimer)
            XCTAssertTrue(step == 1 ? target + 0x19 < c.centre.x : c.centre.x < target - 0x19, "px \(px)")
            frame(w3, id3, s3)
            let t = try slot(w3, id3)
            XCTAssertEqual([Int(t.vx), Int(t.phase)], [Int(vx), 4 + step], "px \(px)")
            XCTAssertTrue(t.mirrored)
        }
    }

    func testThrowerNeverWalksP1() throws {
        // Record p1 1: never state 1, however far the player (M l. 57650–57653); p1 0 walks.
        for p1: Int16 in [1, 0] {
            let w = try world(px: 1200)
            let solver = TileSolver(world: w)
            let id = try walker(w, x: 100, p1: p1)
            var walked = false
            for _ in 0..<60 {
                frame(w, id, solver)
                if try slot(w, id).subtype == 1 { walked = true }
            }
            XCTAssertEqual(walked, p1 == 0, "p1 \(p1)")
            if p1 == 1 {
                XCTAssertEqual(try slot(w, id).x, 100, "never moved")
                XCTAssertFalse(shots(w).isEmpty, "it still throws")
            }
        }
        // The range edge: |cx − target| ≤ 25 stays (vx halved toward zero), 26 walks; airborne → face 0x6a5[6].
        for (off, stays) in [(25, true), (-25, true), (26, false), (-26, false)] {
            let w = try world(px: 900)
            let solver = TileSolver(world: w)
            let id = try walker(w, x: 200)
            for _ in 0..<2 { frame(w, id, solver) }
            let d = Int(try slot(w, id).classTimer)
            w.player.centreX = Int16(250 + d + off)                     // target = P.x − d = 250 + off
            w.active.update(id: id) { $0.subtype = 2; $0.counterA6 = 5; $0.phase = 0; $0.vx = -3 }
            frame(w, id, solver)
            let s = try slot(w, id)
            XCTAssertEqual(Int(s.subtype), stays ? 2 : 1, "off \(off)")
            XCTAssertEqual(Int(s.vx), stays ? -1 : -3, "off \(off): −3 / 2 toward zero")
        }
        let wa = try world(px: 900, floor: false)
        let ida = try walker(wa, x: 200, p1: 1)
        frame(wa, ida, TileSolver(world: wa))
        XCTAssertEqual(try slot(wa, ida).face, FaceRef(pict: 0x6a5, index: 6, set: .encoded))
    }

    func testThrowerThrowsAtStep8() throws {
        // In range, cooldown 0: face 0x6a6[`+0x46 >> 1`], `+0x46` + 1; at 8 snd 704, `+0xa6 = +0x158 + R(26)`, the axe
        // (type flip, the default EnemyShot arm: R(5)) at (x + 0x50 + 10, y + 0x14), vx 0x618 + R(0x1c2), vy −0x334 −
        // R(0x1c2), R(100) > 0x5a → + R(0x578) / − R(0x578). Then the throw finishes on the cooldown (face 0x6a4 at 12).
        let w = try world(px: 900)
        let solver = TileSolver(world: w)
        let id = try walker(w, x: 200, p3: 1)                           // `+0x158` 16
        for _ in 0..<2 { frame(w, id, solver) }
        let s0 = try slot(w, id)
        XCTAssertEqual(s0.centre.x, 250)
        w.player.centreX = Int16(250 + Int(s0.classTimer))              // exactly at range, the player right
        w.active.update(id: id) { $0.subtype = 2; $0.phase = 0; $0.counterA6 = 0 }
        for k in 0..<7 {
            frame(w, id, solver)
            let s = try slot(w, id)
            XCTAssertEqual(Int(s.phase), k + 1)
            XCTAssertEqual(s.face, FaceRef(pict: 0x6a6, index: k >> 1, set: .encoded))
            XCTAssertTrue(shots(w).isEmpty)
        }
        w.player.cues = []
        var r = w.rng
        cry(&r)
        let a6 = Int16(16) + r.next(0x1a)
        _ = r.next(5)
        var vx = Int32(r.next(0x1c2)) + 0x618
        var vy = -0x334 - Int32(r.next(0x1c2))
        if 0x5a < r.next(100) {
            vx += Int32(r.next(0x578))
            vy -= Int32(r.next(0x578))
        }
        let before = try slot(w, id)
        frame(w, id, solver)
        XCTAssertEqual(w.rng.seed, r.seed)
        let s = try slot(w, id)
        XCTAssertEqual([Int(s.phase), Int(s.counterA6)], [8, Int(a6)])
        XCTAssertEqual(s.face, FaceRef(pict: 0x6a6, index: 3, set: .encoded))
        XCTAssertEqual(w.player.cues.filter { $0.snd == 704 }.count, 1)
        let axe = try XCTUnwrap(shots(w).first)
        XCTAssertEqual(axe.type, 0)
        XCTAssertEqual([axe.oldPosition.x, axe.oldPosition.y], [before.x + 0x5a, before.y + 0x14])
        XCTAssertEqual([axe.vx, axe.vy], [vx, vy])
        for k in 9...12 {
            frame(w, id, solver)
            let t = try slot(w, id)
            XCTAssertEqual(Int(t.counterA6), Int(a6) - (k - 8))
            XCTAssertEqual(t.face, k == 12 ? FaceRef(pict: 0x6a4, index: 0, set: .encoded)
                                           : FaceRef(pict: 0x6a6, index: k >> 1, set: .encoded))
            XCTAssertEqual(Int(t.phase), k == 12 ? 0 : k)
        }
        XCTAssertEqual(shots(w).count, 1, "one axe per throw")
        // R(100) = 0x5b (just past 0x5a): the extra R(0x578) pair.
        w.active.update(id: id) { $0.phase = 7; $0.counterA6 = 0 }
        w.rng = FastRand(seed: seed { r in
            cry(&r)
            _ = r.next(0x1a); _ = r.next(5); _ = r.next(0x1c2); _ = r.next(0x1c2)
            return r.next(100) == 0x5b
        })
        r = w.rng
        cry(&r)
        _ = r.next(0x1a); _ = r.next(5)
        let ex = Int32(r.next(0x1c2)) + 0x618, ey = -0x334 - Int32(r.next(0x1c2))
        _ = r.next(100)
        let ax = Int32(r.next(0x578)), ay = Int32(r.next(0x578))
        frame(w, id, solver)
        let extra = try XCTUnwrap(shots(w).last)
        XCTAssertEqual([extra.vx, extra.vy], [ex + ax, ey - ay])
        // Facing the player left: type 1 from x + 10, vx negative.
        let w2 = try world(px: 0)
        let s2 = TileSolver(world: w2)
        let id2 = try walker(w2, x: 400, p1: 1)
        for _ in 0..<2 { frame(w2, id2, s2) }
        w2.active.update(id: id2) { $0.phase = 7; $0.counterA6 = 0 }
        let b2 = try slot(w2, id2)
        frame(w2, id2, s2)
        let axe2 = try XCTUnwrap(shots(w2).first)
        XCTAssertEqual([Int(axe2.type), axe2.oldPosition.x], [1, b2.x + 10])
        XCTAssertLessThan(axe2.vx, -0x617)
    }

    // MARK: - the spear guard 1705

    func testSpearGuardBlocksShot() throws {
        // State 5: a player shot (`+0xa6` 0, type ≠ 0x5a) → snd 303 vol 0x100, `.KillPlayerShot(o, 1, 1)`, `+0xb2 = 0`,
        // no damage; the seed 0x5a hurts; in state 2 it hurts; a type-1 shot turns it to stone in any state.
        let w = try world(px: 900)
        let id = try walker(w, type: 0x6a9, x: 200)
        w.active.update(id: id) { $0.subState = 9 }
        func shot(_ type: Int16) throws -> Int {
            try XCTUnwrap(w.newSprite(type: type, x: 250, y: 330, layer: 0xb, handler: .playerShot) { s in
                s.hp = 100
                s.vx = 0x600
                s.centre = SpriteSlot.Point(x: 260, y: 335)
            })
        }
        var lights = LightTable()
        let a = try shot(2)
        w.player.cues = []
        Walker.hit(w, id: id, other: a, lights: &lights)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.hp), Int(s.subState), Int(s.vx), Int(s.invulnerable)], [500, 0, 0, 0])
        XCTAssertEqual(w.player.cues.first?.snd, 303)
        XCTAssertEqual(w.player.cues.first?.volume, 0x100)
        XCTAssertEqual(w.player.cues.first?.position, SpriteSlot.Point(x: 260, y: 335))
        XCTAssertTrue(w.active.record(id: a)?.dead ?? true)
        // A shot with `+0xa6` ≠ 0 is no hit at all.
        let late = try shot(2)
        w.active.update(id: late) { $0.counterA6 = 1 }
        Walker.hit(w, id: id, other: late, lights: &lights)
        XCTAssertEqual(try slot(w, id).hp, 500)
        XCTAssertFalse(try slot(w, late).dead)
        // The seed 0x5a is not blocked: hurt (100), knocked back 0x600 / 3, −1000 up.
        let seed = try shot(0x5a)
        Walker.hit(w, id: id, other: seed, lights: &lights)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.hp), Int(s.vx), Int(s.vy), Int(s.invulnerable), Int(s.flash)], [400, 0x200, -1000, 4, 8])
        // Thrusting (state 2): no block.
        w.active.update(id: id) { $0.subtype = 2; $0.invulnerable = 0 }
        Walker.hit(w, id: id, other: try shot(2), lights: &lights)
        XCTAssertEqual(try slot(w, id).hp, 300)
        // An enemy shot of its own type never hits it; another type with `+0xa6` > 2 does (blocked in state 5).
        w.active.update(id: id) { $0.subtype = 5; $0.invulnerable = 0 }
        let own = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6a9, x: 250, y: 330, layer: 0))
        w.active.update(id: own) { $0.counterA6 = 3 }
        Walker.hit(w, id: id, other: own, lights: &lights)
        XCTAssertFalse(try slot(w, own).dead)
        let axe = try XCTUnwrap(EnemyShot.spawn(w, type: 0x6d6, x: 250, y: 330, layer: 0))
        w.player.cues = []
        Walker.hit(w, id: id, other: axe, lights: &lights)
        XCTAssertTrue(w.active.record(id: axe)?.dead ?? true)
        XCTAssertEqual(w.player.cues.first?.snd, 303)
        XCTAssertEqual(try slot(w, id).hp, 300)
        // Statue: type 1 in state 5.
        Walker.hit(w, id: id, other: try shot(1), lights: &lights)
        XCTAssertEqual(try slot(w, id).handler, .statue)
    }

    func testSpearGuardThrust() throws {
        // State 5's idle cycle by `+0xb2 >> 2`: 0, 1, 2, 1, then `+0xb2 = −(60 + R(60))` (face 1); the friction 0.9 for
        // p3 < 3, 0.7 from 3.
        for p3: Int16 in [2, 3] {
            let w = try world(px: 2000)
            let solver = TileSolver(world: w)
            let id = try walker(w, type: 0x6a9, x: 300, p3: p3)
            for _ in 0..<3 { frame(w, id, solver) }
            w.active.update(id: id) { $0.subState = 0; $0.vx = 1000 }
            var faces: [Int] = []
            for k in 1...15 {
                if k == 2 { XCTAssertEqual(Int(try slot(w, id).vx), p3 < 3 ? 900 : 700, "p3 \(p3)") }
                frame(w, id, solver)
                faces.append(try XCTUnwrap(try slot(w, id).face).index)
            }
            XCTAssertEqual(faces, [0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 1], "p3 \(p3)")
            var r = w.rng
            cry(&r)
            let back = -(Int(r.next(0x3c)) + 0x3c)
            frame(w, id, solver)
            XCTAssertEqual(Int(try slot(w, id).subState), back)
            XCTAssertEqual(try slot(w, id).face, FaceRef(pict: 0x6a9, index: 1, set: .encoded))
        }

        // The player left, close: flip 1, `+0xb4` −3 from the first Handle → state 2. b2 6 snd 304, b2 16 the swing 0x6a9
        // at (cx − 0x50, cy − 10) with vx −3000; faces 0x6ab[i] (i < 9), [17 − i] (i < 12), [0]; at i 13 back to 5.
        let w = try world(px: 2000, py: 340)
        let solver = TileSolver(world: w)
        let id = try walker(w, type: 0x6a9, x: 300)
        for _ in 0..<3 { frame(w, id, solver) }                         // lands; the player right, turning to 3
        XCTAssertEqual(try slot(w, id).classWordB4, 3)
        let cx = Int(try slot(w, id).centre.x), cy = Int(try slot(w, id).centre.y)
        w.player.centreX = Int16(cx - 100)                               // left, inside 0x78
        w.player.centreY = Int16(cy + 50)
        // Turning back: 3 → 2 → 1 → −1 → −2 (turn faces) → −3 (flip 1, face 0x6a9[0]) → the trigger.
        var turned: [Int16] = []
        for _ in 0..<5 {
            frame(w, id, solver)
            let s = try slot(w, id)
            turned.append(s.classWordB4)
            if s.classWordB4 > -3 {
                XCTAssertEqual(s.face, FaceRef(pict: 0x6aa, index: Int(abs(s.classWordB4)) - 1, set: .encoded))
            }
        }
        XCTAssertEqual(turned, [2, 1, -1, -2, -3])
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.subState)], [2, 0])
        XCTAssertTrue(s.mirrored)
        var swings = 0
        for b2 in 0...26 {
            w.player.cues = []
            let before = try slot(w, id)
            frame(w, id, solver)
            s = try slot(w, id)
            let i = b2 >> 1
            if i < 13 {
                XCTAssertEqual(s.face, FaceRef(pict: 0x6ab, index: i < 9 ? i : i < 12 ? 17 - i : 0, set: .encoded))
                XCTAssertEqual(w.player.cues.contains { $0.snd == 304 }, b2 == 6, "b2 \(b2)")
                XCTAssertEqual(Int(s.subState), b2 + 1)
            } else {
                XCTAssertEqual([Int(s.subtype), Int(s.subState)], [5, 1], "b2 \(b2)")
                break
            }
            if b2 == 16 {
                let sw = try XCTUnwrap(shots(w).first)
                XCTAssertEqual(sw.type, 0x6a9)
                XCTAssertEqual([sw.oldPosition.x, sw.oldPosition.y, Int(sw.vx)],
                               [before.centre.x - 0x50, before.centre.y - 10, -3000])
                swings += 1
            }
        }
        XCTAssertEqual(swings, 1)
    }

    // MARK: - hits and death

    func testWalkerKnockbackP2() throws {
        // `.HurtSprite(s, dmg, p2 == 0 ? (i16)(vx / 3) : 0, −1000, 4, 8)`; on a hurt n = max(1, dmg / 100): the hurt cry,
        // the shot killed, `.BloodSpray(s, o, 40n, 50n + 350, 150n, 2)`, HP > 0 → snd 701.
        for p2: Int16 in [0, 1] {
            let w = try world()
            let id = try walker(w, x: 200, p2: p2)
            let shot = try XCTUnwrap(w.newSprite(type: 2, x: 250, y: 330, layer: 0xb, handler: .playerShot) { s in
                s.x = 250                                               // past `.MTNewSprite`'s `+0xc` quirk
                s.y = 330
                s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
                s.hp = 250
                s.vx = -3001
            })
            var lights = LightTable()
            w.player.cues = []
            Walker.hit(w, id: id, other: shot, lights: &lights)
            let s = try slot(w, id)
            XCTAssertEqual([Int(s.hp), Int(s.vx), Int(s.vy), Int(s.invulnerable), Int(s.flash)],
                           [250, p2 == 0 ? -1000 : 0, -1000, 4, 8], "p2 \(p2)")
            XCTAssertTrue(w.active.record(id: shot)?.dead ?? true)
            XCTAssertTrue(w.player.cues.contains { $0.snd == 701 && $0.volume == 0x55 })
            XCTAssertEqual(w.particles.records.filter(\.alive).count, 80, "40·2 blood particles")
        }
        // A damaging surface (FG kind 203: material 2): HP − hdr+0x270e, `+0x116` 0x14, `+0xaa` 0x12, snd 701 vol 0x55.
        let wm = try world(floorKind: 203)
        let mid = try walker(wm, x: 200)
        let ms = TileSolver(world: wm)
        frame(wm, mid, ms)
        let m = try slot(wm, mid)
        XCTAssertEqual([Int(m.material), Int(m.hp), Int(m.invulnerable), Int(m.flash)],
                       [2, 500 - Int(wm.level.header.landingDamage), 0x14, 0x12])
        XCTAssertTrue(wm.player.cues.contains { $0.snd == 701 && $0.volume == 0x55 })
        // A landing after a fall faster than 2000 (`+0x30`, vy at the last draw): snd 601 at R(4000) + 40000, vol 0x55.
        for fast in [2001, 2000] as [Int32] {
            let wl = try world()
            let lid = try walker(wl, x: 200, y: 320)
            wl.active.update(id: lid) { $0.previousVY = fast; $0.vy = 0xc00 }
            wl.player.cues = []
            var q = wl.rng
            cry(&q)
            let land = Int32(q.next(4000)) + 40000
            frame(wl, lid, TileSolver(world: wl))
            let l = try slot(wl, lid)
            XCTAssertNotEqual(l.groundKind, 0)
            let cue = wl.player.cues.first { $0.snd == 601 }
            XCTAssertEqual(cue.map { Int($0.rate ?? 0) }, fast > 2000 ? Int(l.voicePitch + land - 0xffff) : nil)
        }
        // Dying (state 4): no hurt.
        let w = try world()
        let id = try walker(w, x: 200)
        w.active.update(id: id) { $0.subtype = 4 }
        let shot = try XCTUnwrap(w.newSprite(type: 2, x: 250, y: 330, layer: 0xb, handler: .playerShot) { $0.hp = 100 })
        var lights = LightTable()
        Walker.hit(w, id: id, other: shot, lights: &lights)
        XCTAssertEqual(try slot(w, id).hp, 500)
        XCTAssertFalse(try slot(w, shot).dead)
    }

    func testWalkerDeathCoinsAndScore() throws {
        // The death entry (HP < 1, not dying): 1700 → state 4, the cry, score + 500, rect (0x18, 0x32, 0x3c, 0x46) at
        // flip 0 and x − 24 (24.8), face 0x6a8[0]; the dying frames: `+0xea` 1, layer 1, face 0x6a8[min(b2 / 3, 7)],
        // snd 703 at b2 0, vy − 800 at b2 22; past 50 dry: `+0x15c` + 1, at 3 the burn (`+0x1a2 = 1`), the record's flag
        // cleared; the player near: no Kill.
        let w = try world(px: 300)
        let solver = TileSolver(world: w)
        let id = try walker(w, x: 200, p3: 4)
        for _ in 0..<2 { frame(w, id, solver) }
        w.active.update(id: id) { $0.hp = 0 }
        let x0 = try slot(w, id).x256
        w.rng = FastRand(seed: seed { r in cry(&r); return r.next(100) == 0x33 })   // 0x33: not < 0x33 → 465
        var r = w.rng
        cry(&r)
        let die = r.next(100)
        let pitch = Int32(r.next(10000)) + 50000
        frame(w, id, solver)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(die, 0x33)
        let dieCue = try XCTUnwrap(w.player.cues.first { $0.snd == 465 })
        XCTAssertEqual([Int(dieCue.rate ?? 0), Int(dieCue.volume)], [Int(try slot(w, id).voicePitch + pitch - 0xffff), 0xab])
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(w.globals.score)], [4, 0, 500])
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0x32, left: 0x18, bottom: 0x46, right: 0x3c))
        XCTAssertEqual([Int(s.vx), Int(s.x256)], [-1000, Int(x0) - 0x1800 - 1000], "its last walk step, then x − 24")
        XCTAssertEqual(s.face, FaceRef(pict: 0x6a8, index: 0, set: .encoded))
        XCTAssertTrue(w.player.cues.contains { $0.snd == (die < 0x33 ? 469 : 465) })
        for b2 in 0...51 {
            w.player.cues = []
            let vy0 = try slot(w, id).vy
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertEqual(s.face, FaceRef(pict: 0x6a8, index: min(b2 / 3, 7), set: .encoded), "b2 \(b2)")
            XCTAssertEqual([s.killedForGood, s.layer == 1], [true, true])
            XCTAssertEqual(w.player.cues.contains { $0.snd == 703 }, b2 == 0)
            if b2 == 22 { XCTAssertLessThan(s.vy, vy0) }
        }
        XCTAssertEqual([Int(s.subState), Int(s.classWord15c), Int(s.burnRow)], [52, 2, 0])
        XCTAssertEqual(w.records[0].flag, 0)
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.classWord15c), Int(s.burnRow), Int(s.killCount)], [3, 1, 0])
        // The coins: the burn row at the face's opaque top + 18 → `.PopupGoblinCoins` (p3 4: 0 / 10 / 20 / 30 / 40).
        let bounds = IdleSprites.Rect(top: 20, left: 10, bottom: 70, right: 60)
        w.active.update(id: id) { $0.burnRow = 20 + 0x12 }
        r = w.rng
        let pick = r.next(100)
        let before = w.active.sprites.count
        frame(w, id, solver) { _ in bounds }
        let drops = w.active.sprites.filter { $0.handler == .bonus }
        let want: [Int16] = pick > 60 ? [0x50d] : pick > 30 ? [0x50c] : pick > 10 ? [0x50c] : pick > 0 ? [0x516] : []
        XCTAssertEqual(Set(drops.map(\.type)), Set(want), "R(100) \(pick)")
        XCTAssertGreaterThan(w.active.sprites.count, before)
        for d in drops {
            XCTAssertEqual(Int(d.pickupDelay), 0xc - 1, "set 0xc, then its own Handle once")
            XCTAssertLessThanOrEqual(d.vy, -2000 + 0x151, "−2000 − R(1000), then its gravity")
        }
        // Every p3's bands (strict `<` from the top: big bag, 2–4 bags, one bag, 2–4 coins, nothing), straight from the
        // routine over a spread of streams: the drop types and counts.
        let weights: [Int16: [Int]] = [0: [70, 30, 8, 0, 0], 1: [70, 30, 0, 0, 0], 2: [35, 35, 20, 10, 0],
                                       3: [20, 30, 30, 20, 0], 4: [0, 10, 20, 30, 40], 5: [20, 30, 30, 20, 0],
                                       6: [20, 30, 40, 10, 0]]
        for (p3, wt) in weights.sorted(by: { $0.key < $1.key }) {
            for sd: Int32 in 1...30 {
                let wc = try world(px: 300)
                let cid = try walker(wc, x: 200, p3: p3)
                wc.active.update(id: cid) { $0.face = FaceRef(pict: 0x6a8, index: 3, set: .encoded) }
                wc.rng = FastRand(seed: sd)
                var q = wc.rng
                let total = wt.reduce(0, +)
                let pick = Int(q.next(Int16(total)))
                var edge = total - wt[4]
                var want: [Int16] = []
                if edge < pick { want = [0x50d] } else {
                    edge -= wt[3]
                    if edge < pick { want = Array(repeating: 0x50c, count: Int(q.next(3)) + 2) } else {
                        edge -= wt[2]
                        if edge < pick { want = [0x50c] }
                        else if edge - wt[1] < pick { want = Array(repeating: 0x516, count: Int(q.next(3)) + 2) }
                    }
                }
                var lights = LightTable()
                _ = Walker.popupCoins(wc, id: cid, solver: TileSolver(world: wc), lights: &lights, effects: 1,
                                      faceWidth: { _ in 0x5e }, faceBounds: { _ in bounds })
                XCTAssertEqual(wc.active.sprites.filter { $0.handler == .bonus }.map(\.type), want, "p3 \(p3) seed \(sd)")
            }
        }
        // 1705: type 0x6a4, score + 600, x + 35 (flip 0); the player far: the Kill (counted once).
        let w2 = try world(px: 3000, py: 340)
        let s2 = TileSolver(world: w2)
        let g = try walker(w2, type: 0x6a9, x: 200)
        for _ in 0..<2 { frame(w2, g, s2) }
        w2.active.update(id: g) { $0.hp = -5; $0.mirrored = false }
        let gx = try slot(w2, g).x256
        frame(w2, g, s2)
        let t = try slot(w2, g)
        XCTAssertEqual([Int(t.type), Int(t.subtype), Int(w2.globals.score)], [0x6a4, 4, 600])
        XCTAssertEqual(t.x256, gx + 0x2300)
        XCTAssertEqual(t.hotRect, IdleSprites.Rect(top: 0x32, left: 0x28, bottom: 0x46, right: 0x3c))
        w2.levelIndex = 1
        let live = w2.enemies.live
        for _ in 0..<52 { frame(w2, g, s2) }
        XCTAssertEqual(try slot(w2, g).killCount, 1)
        XCTAssertEqual(w2.enemies.live, live - 1)
        XCTAssertEqual(w2.globals.achieved[0][1], 1)
    }

    func testCorpseFloats() throws {
        // Past 50 with water contact: the corpse raft — counted, the Platform Handle with the Walker callbacks, rect
        // (0x10, 0x35, 0x42, 0x47), `+0x1a0` −6, one-way, `+0x13a` 0x20, `+0x138` 0x3c, `+0x17c` 1, no `+0xe9`. Then
        // `.HandlePlatformSprite`: buoyancy +1 when R(2) == 1 up to 0x50; `.HandleFlotation` to y = surface − 68.
        let w = try world(px: 300, waterRow: 8)                          // water from y 256 down
        let solver = TileSolver(world: w)
        w.levelIndex = 1
        let id = try walker(w, x: 200, y: 300)
        w.active.update(id: id) { s in
            s.hp = 0
            s.subtype = 4
            s.subState = 0x32
            s.waterRow = 1
        }
        let live = w.enemies.live
        frame(w, id, solver)
        var s = try slot(w, id)
        XCTAssertEqual(s.handler, .platform)
        XCTAssertTrue(s.walkerCallbacks)
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0x35, left: 0x10, bottom: 0x47, right: 0x42))
        XCTAssertEqual([Int(s.floatOffset), Int(s.sag), Int(s.pushMass), Int(s.subtype)], [-6, 0x20, 0x3c, 4])
        XCTAssertEqual([s.oneWay, s.setupDone, s.dead], [true, true, false])
        XCTAssertEqual(w.enemies.live, live - 1)
        XCTAssertEqual(w.globals.achieved[0][1], 1)
        var top: Int16 = 0
        for n in 0..<900 {
            let b0 = try slot(w, id).buoyancy
            var r = w.rng
            let grows = b0 < 0x50 && r.next(2) == 1
            PlatformSprite.handle(world: w, id: id, solver: solver)
            s = try slot(w, id)
            XCTAssertEqual(s.buoyancy, grows ? b0 + 1 : b0, "frame \(n)")
            top = max(top, s.buoyancy)
        }
        XCTAssertEqual(top, 0x50)
        XCTAssertEqual([s.y, Int(s.vy)], [256 - 68, 0], "rides at surface − 68")
        XCTAssertEqual(w.enemies.live, live - 1, "counted once")
    }
}

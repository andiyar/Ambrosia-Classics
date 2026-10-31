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
    /// set up by `.SetupWalkerSprite` inside the counting window (outside it when `counted` is false).
    private func walker(_ w: SpriteWorld, type: Int16 = 0x6a4, x: Int = 100, y: Int = 330, p1: Int16 = 0,
                        p2: Int16 = 0, p3: Int16 = 0, p4: Int16 = 0, counted: Bool = true) throws -> Int {
        let p = Placement(index: 0, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: p4, y: Int16(y),
                          x: Int16(x))
        w.records = [p]
        let c = SetupFaces.Context(level: w.level, playerX: Int(w.player.centreX), records: w.records)
        var lights = LightTable()
        w.enemies.window = counted
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
        // Record p4 ≠ 0: the four idle margins `+0x1c8`…`+0x1ce` = 0x5f4 (M l. 57084–57089); p4 0 leaves them.
        let m4 = try slot(w, try walker(w, x: 100, p4: 1)).margins
        XCTAssertEqual([m4.left, m4.right, m4.top, m4.bottom], [0x5f4, 0x5f4, 0x5f4, 0x5f4])
        XCTAssertEqual(a.margins, SpriteSlot(type: 0x6a4, x: 0, y: 0).margins)
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
        XCTAssertEqual(try slot(w, try walker(w, type: 0x6d6, x: 100)).subtype, 1, "the 1750 arm (WK2)")
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
        // The walk's edges (M l. 57592–57633): the player left (target = P.x + d), the centre at target − 25 is inside
        // (vx kept, the counter by vx: vx < 0 → +1, else −1), at target − 26 it walks right (1000, −1); the player right
        // (target = P.x − d), inside: vx < 1 → −1, else +1.
        for (left, off, vx0, vx, step) in [(true, 25, 0, 0, -1), (true, 26, 0, 1000, -1), (true, 25, -1, -1, 1),
                                           (false, 0, 0, 0, -1), (false, 0, 1, 1, 1)] as [(Bool, Int, Int32, Int32, Int)] {
            let we = try world(px: 900)
            let se = TileSolver(world: we)
            let ie = try walker(we, x: 400, p1: 1)
            for _ in 0..<3 { frame(we, ie, se) }
            let c = try slot(we, ie)
            let d = Int(c.classTimer)
            we.player.centreX = Int16(left ? c.centre.x + off - d : c.centre.x + d)     // target = cx + off / cx
            we.active.update(id: ie) { $0.subtype = 1; $0.phase = 4; $0.vx = vx0 }
            frame(we, ie, se)
            let t = try slot(we, ie)
            XCTAssertEqual([Int(t.vx), Int(t.phase)], [Int(vx), 4 + step], "left \(left) off \(off) vx \(vx0)")
        }
        // `.SetSpriteSpeed` (M l. 32815–32830): in water (`+0x11c ≠ 0`) both × 0.8, truncated; dry as given.
        var sp = SpriteSlot(type: 0x6a4, x: 0, y: 0)
        sp.waterRow = 1
        Walker.setSpriteSpeed(&sp, -1000, 0x200)
        XCTAssertEqual([sp.vx, sp.vy], [-800, 409])
        sp.waterRow = 0
        Walker.setSpriteSpeed(&sp, 1000, 0x200)
        XCTAssertEqual([sp.vx, sp.vy], [1000, 0x200])
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
        // Airborne, the walk face is the 1700's alone: the 1705 keeps its own (M l. 58464–58467, `+4 == 0x6a4`).
        let wg = try world(px: 900, floor: false)
        let ig = try walker(wg, type: 0x6a9, x: 200)
        frame(wg, ig, TileSolver(world: wg))
        XCTAssertEqual(try slot(wg, ig).face?.pict, 0x6a9)
        // The prologue (M l. 57562–57575): the first Handle sets `+0xb4` = flip ? −3 : 3 (once); layer 0xb every frame;
        // `+0x170 > 0` → `+0x16c = 0`, `+0x170` − 1. State 2 rewrites gravity 0x151 (M l. 57640); the tail zeroes
        // `+0x16c` before the separation (M l. 58410) — standing on kind 3 (no wall kind) leaves it 0.
        for flip in [false, true] {
            let wp = try world(px: flip ? 0 : 900)
            let sp = TileSolver(world: wp)
            let ip = try walker(wp, x: 200, p1: 1)
            XCTAssertEqual(try slot(wp, ip).mirrored, flip)
            wp.active.update(id: ip) { $0.layer = 4; $0.classWord170 = 3; $0.classWord16c = 7; $0.gravity = 0 }
            frame(wp, ip, sp)
            var q = try slot(wp, ip)
            XCTAssertEqual([Int(q.classWordB4), Int(q.layer), Int(q.classWord170), Int(q.classWord16c), Int(q.gravity)],
                           [flip ? -3 : 3, 0xb, 2, 0, 0x151], "flip \(flip)")
            wp.active.update(id: ip) { $0.classWordB4 = 1; $0.layer = 4; $0.classWord170 = 0; $0.classWord16c = 7; $0.gravity = 0 }
            frame(wp, ip, sp)
            q = try slot(wp, ip)
            XCTAssertNotEqual(q.groundKind, 0, "flip \(flip): standing")
            XCTAssertEqual([Int(q.classWordB4), Int(q.layer), Int(q.classWord170), Int(q.classWord16c), Int(q.gravity)],
                           [1, 0xb, 0, 0, 0x151], "flip \(flip): the second Handle")
        }
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
        // R(100) = 0x5a (not past it): no extra pair — the stream ends at R(100).
        w.active.update(id: id) { $0.phase = 7; $0.counterA6 = 0 }
        w.rng = FastRand(seed: seed { r in
            cry(&r)
            _ = r.next(0x1a); _ = r.next(5); _ = r.next(0x1c2); _ = r.next(0x1c2)
            return r.next(100) == 0x5a
        })
        r = w.rng
        cry(&r)
        _ = r.next(0x1a); _ = r.next(5)
        let px0 = Int32(r.next(0x1c2)) + 0x618, py0 = -0x334 - Int32(r.next(0x1c2))
        _ = r.next(100)
        frame(w, id, solver)
        XCTAssertEqual(w.rng.seed, r.seed, "no R(0x578) pair")
        let plain = try XCTUnwrap(shots(w).last)
        XCTAssertEqual([plain.vx, plain.vy], [px0, py0])
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
        // The friction's edge (M l. 57756–57764): |vx| ≤ 0x80 → 0, else (int)(vx · f) toward zero.
        for (v, f, want) in [(0x80, 9, 0), (0x81, 9, 116), (-0x80, 9, 0), (-0x81, 9, -116), (0x81, 7, 90)]
            as [(Int32, Int, Int32)] {
            var fs = SpriteSlot(type: 0x6a9, x: 0, y: 0)
            fs.vx = v
            Walker.friction(&fs, f == 9 ? Walker.friction9 : Walker.friction7)
            XCTAssertEqual(fs.vx, want, "vx \(v) × 0.\(f)")
        }
        // The turn's edges (M l. 57856–57926): turning right from −1, `+0xb4` 0 is skipped to 1 (face 0x6aa[0]); a turn
        // face flips by the idle counter `+0xb2` < 0 after its + 1 (−2 → −1 flips, −1 → 0 does not).
        for (b2, flip) in [(-2, true), (-1, false)] as [(Int16, Bool)] {
            let wt = try world(px: 2000)
            let st = TileSolver(world: wt)
            let it = try walker(wt, type: 0x6a9, x: 300)
            for _ in 0..<3 { frame(wt, it, st) }
            wt.active.update(id: it) { $0.classWordB4 = -1; $0.subState = b2 }
            frame(wt, it, st)
            let t = try slot(wt, it)
            XCTAssertEqual([Int(t.classWordB4), Int(t.subState)], [1, Int(b2) + 1], "b2 \(b2)")
            XCTAssertEqual(t.face, FaceRef(pict: 0x6aa, index: 0, set: .encoded), "b2 \(b2)")
            XCTAssertEqual(t.mirrored, flip, "b2 \(b2)")
        }
        // The trigger's edges (M l. 57927–57940): |cx − P.x| < 0x78 and |P.y − cy| < 100, the player in front at ±3.
        for (dx, dy, fires) in [(0x77, 0, true), (0x78, 0, false), (0x10, 99, true), (0x10, 100, false),
                                (0x10, -99, true), (0x10, -100, false)] {
            let wt = try world(px: 2000)
            let st = TileSolver(world: wt)
            let it = try walker(wt, type: 0x6a9, x: 300)
            for _ in 0..<3 { frame(wt, it, st) }
            let c = try slot(wt, it)
            XCTAssertEqual([Int(c.classWordB4), Int(c.subtype)], [3, 5])
            wt.player.centreX = Int16(c.centre.x + dx)
            wt.player.centreY = Int16(c.centre.y + dy)
            frame(wt, it, st)
            XCTAssertEqual(Int(try slot(wt, it).subtype), fires ? 2 : 5, "dx \(dx) dy \(dy)")
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
        // n = max(1, dmg / 100) (M l. 58555–58560): a 50 is n 1 — 40 blood particles. The 1750's knockback is / 3 again
        // (M l. 58548–58550): −3001 / 3 = −1000, / 3 = −333.
        for (type, dmg, vx, blood) in [(Int16(0x6a4), Int16(50), Int32(-1000), 40), (0x6d6, 250, -333, 80)] {
            let wn = try world()
            let nid = try walker(wn, x: 200)
            wn.active.update(id: nid) { $0.type = type }
            let ns = try XCTUnwrap(wn.newSprite(type: 2, x: 250, y: 330, layer: 0xb, handler: .playerShot) { s in
                s.x = 250
                s.y = 330
                s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
                s.hp = dmg
                s.vx = -3001
            })
            var nl = LightTable()
            Walker.hit(wn, id: nid, other: ns, lights: &nl)
            let n = try slot(wn, nid)
            XCTAssertEqual([Int(n.hp), Int(n.vx)], [500 - Int(dmg), Int(vx)], "type \(type)")
            XCTAssertEqual(wn.particles.records.filter(\.alive).count, blood, "type \(type)")
        }
        // `.WrapDrawSprites`' tail keeps vy as `+0x30` (M l. 10383) — the landing thud's test.
        var drawn = SpriteSlot(type: 0x6a4, x: 0, y: 0)
        drawn.vy = 2001
        drawn.recordDrawn()
        XCTAssertEqual(drawn.previousVY, 2001)
        // The other arms of `.HitWalkerSprite` (M l. 58590–58609): a Smite explosion 0x4b7 at `+0x46 < 8` or a geyser
        // 0x5a0 at `+0x14c` 1 / 2 → `.HurtGoblin(s, o, 100, 0, −1000, 4, 8)`; a Background 0x4b8, 0x5c8…0x5d1 with
        // `+0x170 == 1`, or 0x730…0x735 (0x113) — only with our `+0x100 == 0` (tier 4 passes them by).
        let wh = try world(floor: false)
        let hid = try walker(wh, x: 200)
        var hl = LightTable()
        func hurt(_ type: Int16, _ handler: SpriteHandler, immune: Int32 = 0, phase: Int16 = 0, timer: Int32 = 0,
                  harmful: Int32 = 0) throws -> Int {
            wh.active.update(id: hid) { $0.hp = 500; $0.invulnerable = 0; $0.vx = 0; $0.vy = 0; $0.classWord100 = immune }
            let o = try XCTUnwrap(wh.newSprite(type: type, x: 200, y: 330, layer: 1, handler: handler) { o in
                o.phase = phase
                o.classTimer = timer
                o.classWord170 = harmful
            })
            Walker.hit(wh, id: hid, other: o, lights: &hl)
            return Int(try slot(wh, hid).hp)
        }
        XCTAssertEqual(try hurt(0x4b7, .effect, phase: 7), 400, "Smite")
        let sm = try slot(wh, hid)
        XCTAssertEqual([Int(sm.vx), Int(sm.vy), Int(sm.invulnerable), Int(sm.flash)], [0, -1000, 4, 8])
        XCTAssertEqual(try hurt(0x4b7, .effect, phase: 8), 500)
        XCTAssertEqual(try hurt(0x5a0, .background, timer: 2), 400, "geyser")
        XCTAssertEqual(try hurt(0x5a0, .background, timer: 0), 500)
        XCTAssertEqual(try hurt(0x4b8, .background), 400)
        XCTAssertEqual(try hurt(0x5c8, .background, harmful: 1), 400)
        XCTAssertEqual(try hurt(0x5d1, .background, harmful: 1), 400)
        XCTAssertEqual(try hurt(0x5c8, .background, harmful: 0), 500)
        XCTAssertEqual(try hurt(0x730, .background), 500 - 0x113)
        XCTAssertEqual(try hurt(0x735, .background), 500 - 0x113)
        XCTAssertEqual(try hurt(0x72f, .background), 500)
        XCTAssertEqual(try hurt(0x736, .background), 500)
        XCTAssertEqual(try hurt(0x4b8, .background, immune: 1), 500, "tier 4")
        XCTAssertEqual(try hurt(0x730, .background, immune: 1), 500, "tier 4")
        XCTAssertEqual(try hurt(0x4b8, .inert), 500, "only under the Background Handle")
        // The crush (M l. 58578–58589): the walker rising into a Statue / Box / Platform solid's underside —
        // `.PlatformBounce` 2, measured on a twin world — → HP 0; not a one-way solid, not a pipe 0x5d2…0x5d6, not dying.
        func crush(_ handler: SpriteHandler, type: Int16 = 0xc12, oneWay: Bool = false,
                   dying: Bool = false) throws -> (bounce: Int16, hp: Int16) {
            func make() throws -> (SpriteWorld, Int, Int) {
                let wc = try world(floor: false)
                let c = try walker(wc, x: 200)
                wc.active.update(id: c) { $0.vy = -0x400; if dying { $0.subtype = 4 } }
                let box = try XCTUnwrap(wc.newSprite(type: type, x: 220, y: 310, layer: 2, handler: handler) { b in
                    b.x = 220
                    b.y = 310
                    b.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x40)
                    b.oneWay = oneWay
                })
                return (wc, c, box)
            }
            let (wa, ca, ba) = try make()
            let r = try slot(wa, ca).hotRect
            let centre = SpriteSlot.Point(x: r.left + ((r.right - r.left) >> 1), y: r.top + ((r.bottom - r.top) >> 1))
            let b = wa.platformBounce(mover: ca, solid: ba, centre: centre, factor: 0, rect: r, bounce: false)
            let (wb, cb, bb) = try make()
            Walker.hit(wb, id: cb, other: bb, lights: &hl)
            return (b, try slot(wb, cb).hp)
        }
        for h in [SpriteHandler.box, .platform, .statue] {
            let c = try crush(h)
            XCTAssertEqual([Int(c.bounce), Int(c.hp)], [2, 0], "\(h)")
        }
        XCTAssertEqual(try crush(.box, type: 0x5d4).hp, 500, "a pipe")
        XCTAssertEqual(try crush(.box, oneWay: true).hp, 500, "one-way")
        XCTAssertEqual(try crush(.box, dying: true).hp, 500, "dying")
        // `.HitWalkerTileSprite` (M l. 58650–58696): an FG hit `.WallBounce` reports (measured on a twin world; every
        // case below hits) counts `+0x16c` + 1 for kinds 0…2, 0x20…0x23, and by the facing 4 / 9 / 0x1b / 0x14 (flip 0),
        // 10 / 0x1c / 0x13 (flip 1), 7 (flip 1, or flip 0 with cx < pos.x + 16), 5 (flip 1 with pos.x + 16 < cx) — only
        // with `+0x170 == 0`.
        func wallHit(kind k: Int, flip: Bool, centreX: Int? = nil, lockout: Int32 = 0) throws -> (hit: Bool, count: Int32) {
            func make() throws -> (SpriteWorld, Int) {
                let wt = try world(floor: false)
                let it = try walker(wt, x: 200)
                wt.standardSpriteCleanup(it, faceWidth: { _ in 100 })           // the centre from the hot rect
                wt.active.update(id: it) { t in
                    t.mirrored = flip
                    t.classWord170 = lockout
                    if let centreX { t.centre.x = centreX }                     // `+0x10` from the last Cleanup
                }
                return (wt, it)
            }
            let (wa, ia) = try make()
            let r = try slot(wa, ia).hotRect
            var pos = TilePos(x: 240, y: 352)
            let hit = TileSolver(world: wa).wallBounce(ia, kind: k, tile: &pos, vCentre: r.top + ((r.bottom - r.top) >> 1),
                                                       factor: 0, rect: r, bounce: false)
            let (wb, ib) = try make()
            Walker.hitTile(TileSolver(world: wb), id: ib, pos: TilePos(x: 240, y: 352), kind: k, layer: .foreground)
            return (hit, try slot(wb, ib).classWord16c)
        }
        // At x 200 the centre is 250, left of pos.x + 16 = 256.
        let counts: [(Int, Int32, Int32)] = [(0, 1, 1), (1, 1, 1), (2, 1, 1), (3, 0, 0), (4, 1, 0), (5, 0, 0), (7, 1, 1),
                                             (9, 1, 0), (10, 0, 1), (0x13, 0, 1), (0x14, 1, 0), (0x1b, 1, 0), (0x1c, 0, 1),
                                             (0x1f, 0, 0), (0x20, 1, 1), (0x23, 1, 1), (0x24, 0, 0)]
        for (k, flip0, flip1) in counts {
            for (flip, want) in [(false, flip0), (true, flip1)] {
                let h = try wallHit(kind: k, flip: flip)
                XCTAssertTrue(h.hit, "kind \(k) flip \(flip): a hit")
                XCTAssertEqual(h.count, want, "kind \(k) flip \(flip)")
            }
        }
        // With the centre `+0x10` at 260 (moved since the last Cleanup), right of 256: 5 counts flipped, 7 no longer
        // unflipped.
        for (k, flip, want) in [(5, true, 1), (5, false, 0), (7, false, 0), (7, true, 1)] as [(Int, Bool, Int32)] {
            let h = try wallHit(kind: k, flip: flip, centreX: 260)
            XCTAssertTrue(h.hit, "cx 260 kind \(k) flip \(flip): a hit")
            XCTAssertEqual(h.count, want, "cx 260 kind \(k) flip \(flip)")
        }
        XCTAssertEqual(try wallHit(kind: 1, flip: false, lockout: 1).count, 0, "the lockout")
        // BG water (kind 200…209) → `.HandleUnderWater` (S 256 − y 300 → 1, kind 0, `+0x140` 1) unless `+0x140` is set.
        for done in [false, true] {
            let wu = try world(waterRow: 8, floor: false)
            let iu = try walker(wu, x: 200, y: 300)
            wu.active.update(id: iu) { $0.underwaterDone = done }
            Walker.hitTile(TileSolver(world: wu), id: iu, pos: TilePos(x: 224, y: 320), kind: 200, layer: .background)
            let u = try slot(wu, iu)
            XCTAssertEqual([Int(u.waterRow), u.underwaterDone ? 1 : 0], done ? [0, 1] : [1, 1], "+0x140 \(done)")
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
        // The drops' origin (M l. 57360–57376): the centre of the face's opaque bounds — `.FlipHRect` by the face width
        // when flipped — at (`+0xc`, `+0xa`); one stream, no tiles in reach, so a drop moves one for one with it.
        func dropXY(x: Int, flip: Bool, b: IdleSprites.Rect) throws -> [Int] {
            let wd = try world(px: 300, floor: false)
            let did = try walker(wd, x: x, p3: 4)
            wd.active.update(id: did) { $0.face = FaceRef(pict: 0x6a8, index: 3, set: .encoded); $0.mirrored = flip }
            wd.rng = FastRand(seed: 7)
            var dl = LightTable()
            _ = Walker.popupCoins(wd, id: did, solver: TileSolver(world: wd), lights: &dl, effects: 1,
                                  faceWidth: { _ in 0x5e }, faceBounds: { _ in b })
            return wd.active.sprites.filter { $0.handler == .bonus }.flatMap { [$0.x, $0.y] }
        }
        let base = try dropXY(x: 200, flip: false, b: bounds)
        XCTAssertFalse(base.isEmpty)
        func moved(_ dx: Int, _ dy: Int) -> [Int] { base.enumerated().map { $0.element + ($0.offset % 2 == 0 ? dx : dy) } }
        XCTAssertEqual(try dropXY(x: 207, flip: false, b: bounds), moved(7, 0), "+0xc")
        var wider = bounds
        wider.right += 20
        wider.bottom += 20
        XCTAssertEqual(try dropXY(x: 200, flip: false, b: wider), moved(10, 10), "the bounds' centre")
        // Flipped by 0x5e: (34, 84) — centre 59 against 35.
        XCTAssertEqual(try dropXY(x: 200, flip: true, b: bounds), moved(24, 0), "flipped")
        // The dry corpse's Kill distance (M l. 57775–57785): the player's centre within 450 px across and 350 px down /
        // up keeps it; 451 / 351 → `.KillWalker`.
        for (dx, dy, kills) in [(0x1c2, 0, false), (0x1c3, 0, true), (-0x1c3, 0, true), (0, 0x15e, false),
                                (0, 0x15f, true), (0, -0x15f, true), (-0x1c2, -0x15e, false)] {
            let wk = try world()
            let sk = TileSolver(world: wk)
            let ik = try walker(wk, x: 200)
            for _ in 0..<2 { frame(wk, ik, sk) }
            let c = try slot(wk, ik)
            wk.player.centreX = Int16(c.centre.x + dx)
            wk.player.centreY = Int16(c.centre.y + dy)
            wk.active.update(id: ik) { $0.hp = 0; $0.subtype = 4; $0.subState = 0x32 }
            frame(wk, ik, sk)
            XCTAssertEqual(try slot(wk, ik).dead, kills, "dx \(dx) dy \(dy)")
        }
        // The death entry's flipped arm and the 1760's (M l. 58307–58408), each against a twin that stays alive (free
        // fall, no tiles): 1700 flip 1 → right + 16, x + 24; 0x6e0 → the rect, top + 0x2a, type 0x6a4, flip inverted,
        // y + 20, x + 15 (new flip 1) or − 25, face 0x6a8[0], score + 400. Dying, the airborne walk face is not taken;
        // the alive 0x6e0 keeps its own face.
        for (type, flip) in [(Int16(0x6a4), true), (0x6e0, true), (0x6e0, false)] {
            func run(_ hp: Int16) throws -> (SpriteSlot, Int32) {
                // WK2: the 1760 arm faces the player first (flip = cx < P.x; cx 0 at the first Handle) — the player
                // right of 0 for the flipped row, at 0 for the other.
                let wf = try world(px: type == 0x6e0 && flip ? 3000 : 0, floor: false)
                let fid = try walker(wf, type: type, x: 200)
                wf.active.update(id: fid) { $0.mirrored = flip; $0.hp = hp }
                frame(wf, fid, TileSolver(world: wf))
                return (try slot(wf, fid), wf.globals.score)
            }
            let (alive, _) = try run(500)
            let (dead, score) = try run(0)
            XCTAssertEqual([Int(dead.type), Int(dead.subtype)], [0x6a4, 4], "\(type) flip \(flip)")
            XCTAssertEqual(dead.face, FaceRef(pict: 0x6a8, index: 0, set: .encoded), "\(type) flip \(flip)")
            if type == 0x6a4 {
                XCTAssertTrue(dead.mirrored)
                XCTAssertEqual(dead.hotRect, IdleSprites.Rect(top: 0x32, left: 0x28, bottom: 0x46, right: 0x4c))
                XCTAssertEqual([dead.x256 - alive.x256, dead.y256 - alive.y256, score], [0x1800, 0, 500])
                XCTAssertEqual(alive.face, FaceRef(pict: 0x6a5, index: 6, set: .encoded))
            } else {
                XCTAssertEqual(dead.mirrored, !flip)
                XCTAssertEqual(dead.hotRect, IdleSprites.Rect(top: 0x34, left: 0x28, bottom: 0x46, right: 0x3c))
                XCTAssertEqual([dead.x256 - alive.x256, dead.y256 - alive.y256, score],
                               [flip ? -0x1900 : 0xf00, 0x1400, 400], "0x6e0 flip \(flip)")
                XCTAssertEqual(alive.face?.pict, 0x6e0)
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
            s.invulnerable = 5
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
        // `+0x116 = 0` at the change, so the tail's liquids row hurts it at once (kind 0: `+0x116` 0xc, HP − 0x96, `+0xaa`
        // 0xc, M l. 58426–58443 — the invulnerability preset above would have blocked it).
        XCTAssertEqual([Int(s.invulnerable), Int(s.hp), Int(s.flash), Int(s.waterKind)], [0xc, -0x96, 0xc, 0])
        // Not counted (set up outside the window): no tally at the change.
        let wn = try world(px: 300, waterRow: 8)
        wn.levelIndex = 1
        let nid = try walker(wn, x: 200, y: 300, counted: false)
        wn.active.update(id: nid) { $0.hp = 0; $0.subtype = 4; $0.subState = 0x32; $0.waterRow = 1 }
        let nlive = wn.enemies.live
        frame(wn, nid, TileSolver(world: wn))
        XCTAssertEqual(try slot(wn, nid).handler, .platform)
        XCTAssertEqual(wn.enemies.live, nlive)
        XCTAssertEqual(wn.globals.achieved[0][1], 0)
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
        // The raft's tile callback is `.HitWalkerTileSprite` (`PlatformSprite.pass`): an FG kind-1 hit counts a wall hit.
        let pass = try XCTUnwrap(PlatformSprite.pass(s))
        w.active.update(id: id) { $0.classWord16c = 0; $0.classWord170 = 0 }
        pass(solver, id, TilePos(x: s.x + 0x10, y: s.y + 0x30), 1, .foreground)
        XCTAssertEqual(try slot(w, id).classWord16c, 1)
        // Its hit callback is `.HitWalkerSprite` (the session's dispatch): a type-1 player shot turns it to stone and is
        // killed by `.KillPlayerShot(o, 1, 1)` (M l. 58526) — its sound flag plays snd 301 (the Platform's hit plays none).
        let wh = try world(px: 300, waterRow: 8)
        let hid = try walker(wh, x: 200, y: 300)
        wh.active.update(id: hid) { $0.hp = 0; $0.subtype = 4; $0.subState = 0x32; $0.waterRow = 1 }
        frame(wh, hid, TileSolver(world: wh))
        XCTAssertEqual(try slot(wh, hid).handler, .platform)
        let stun = try XCTUnwrap(wh.newSprite(type: 1, x: 250, y: 330, layer: 0xb, handler: .playerShot) { $0.hp = 100 })
        wh.player.cues = []
        FerazelSession.hitCallback(wh, hid, stun)
        XCTAssertEqual(try slot(wh, hid).handler, .statue)
        XCTAssertTrue(wh.player.cues.contains { $0.snd == 301 }, "`.KillPlayerShot(o, 1, 1)`")
        // Its Kill proc is `.KillWalker` (M l. 58624–58630): `+0xe9 == 0 ∧ +0x1b5 ≠ 0` → counted again (as written),
        // `+0xe9 = 1`, no `+0xea` store.
        EnemyCommon.killProc(w, id: id)
        XCTAssertEqual(try slot(w, id).killCount, 1)
        XCTAssertEqual(w.enemies.live, live - 2)
        XCTAssertEqual(w.globals.achieved[0][1], 2)
    }

    // MARK: - the boulder thrower 1760 (WK2)

    /// A 1760 (type 0x6e0) set up at (300, 315) — its hot rect's bottom 0x55 on the floor's surface (y 400) — with
    /// record `p1`, three Handles with the player far right (out of reach: it stays in state 5).
    private func boulderThrower(_ w: SpriteWorld, p1: Int16 = 0) throws -> (Int, TileSolver) {
        let solver = TileSolver(world: w)
        let id = try walker(w, type: 0x6e0, x: 300, y: 315, p1: p1)
        for _ in 0..<3 { frame(w, id, solver) }
        return (id, solver)
    }

    /// The draws of `.SetupEnemyShotSprite` for a boulder 0x6e1 / 0x6e2 (M l. 51442–51611): R(5), R(2), R(100) and
    /// past 0x56 R(5); any other type R(5) only.
    private func shotSetupDraws(_ r: inout FastRand, boulder: Bool) {
        _ = r.next(5)
        guard boulder else { return }
        _ = r.next(2)
        if 0x56 < r.next(100) { _ = r.next(5) }
    }

    func test1760ThrowsBoulder() throws {
        // The 1760 arm (M l. 57995–58079): the ×0.7 friction; state 5 counts `+0xb2` up, faces the player and attacks
        // inside 500 px across with `+0xb2 ≥ 0` (state 2, `+0xb2 = 0`, no vertical test); state 2 faces 0x6e0[`+0xb2 >>
        // 1`], snd 304 at `+0xb2 == 6`, the boulder at 8 — `MTNewSprite(0x6e1 + p1, cx + (flip ? 0x1c : −0x1c) − 0x10,
        // cy − 0x26, layer + 1, −1, .SetupEnemyShotSprite)`, its `+0xa6 = −30`, vy −0x6a4 − R(0x28a), then vx −0x514 −
        // R(0x28a), negated when flipped; `+0xb2 >> 1` past 8 → state 5, `+0xb2 = −(R(0x50) + 0x28)`; then `+0xb2` + 1.
        let w = try world(px: 3000)
        let (id, solver) = try boulderThrower(w)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.subtype), Int(s.subState)], [5, 3], "out of reach: state 5, `+0xb2` counting up")
        XCTAssertNotEqual(s.groundKind, 0)
        let cx = s.centre.x, cy = s.centre.y
        // The reach: |cx − P.x| < 500, either side, the player far above (no vertical test).
        for (px, attacks) in [(cx + 500, false), (cx + 499, true), (cx - 500, false), (cx - 499, true)] {
            w.player.centreX = Int16(px)
            w.player.centreY = Int16(cy - 3000)
            w.active.update(id: id) { $0.subtype = 5; $0.subState = 7 }
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.subState)], attacks ? [2, 0] : [5, 8], "P.x \(px)")
        }
        // `+0xb2` below 0 holds the attack: −2 → −1 waits, −1 → 0 attacks.
        w.player.centreX = Int16(cx + 100)
        for (b2, attacks) in [(Int16(-2), false), (-1, true)] {
            w.active.update(id: id) { $0.subtype = 5; $0.subState = b2 }
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.subState)], attacks ? [2, 0] : [5, Int(b2) + 1], "b2 \(b2)")
        }
        // The throw, the player right (flip 1 from state 5): the boulder from cx + 0x1c − 0x10, vx positive.
        XCTAssertTrue(s.mirrored)
        w.player.cues = []
        for b2 in 0...17 {
            let before = try slot(w, id)
            XCTAssertEqual(Int(before.subState), b2)
            var r = w.rng
            cry(&r)
            var vx: Int32 = 0, vy: Int32 = 0
            if b2 == 8 {
                shotSetupDraws(&r, boulder: true)
                vy = -0x6a4 - Int32(r.next(0x28a))
                vx = 0x514 + Int32(r.next(0x28a))
            }
            let n = shots(w).count
            frame(w, id, solver)
            XCTAssertEqual(w.rng.seed, r.seed, "b2 \(b2)")
            s = try slot(w, id)
            XCTAssertEqual(s.face, FaceRef(pict: 0x6e0, index: b2 >> 1, set: .encoded), "b2 \(b2)")
            XCTAssertEqual([Int(s.subtype), Int(s.subState)], [2, b2 + 1], "b2 \(b2)")
            XCTAssertTrue(s.mirrored, "state 2 keeps the flip")
            XCTAssertEqual(w.player.cues.filter { $0.snd == 304 }.count, b2 < 6 ? 0 : 1, "b2 \(b2)")
            XCTAssertEqual(shots(w).count, n + (b2 == 8 ? 1 : 0), "b2 \(b2)")
            if b2 == 8 {
                let b = try XCTUnwrap(shots(w).last)
                XCTAssertEqual(b.type, 0x6e1)
                XCTAssertEqual([b.oldPosition.x, b.oldPosition.y, b.x, b.y],
                               [cx + 0xc, cy - 0x26, cx + 0xc, cy - 0x26])
                XCTAssertEqual([Int(b.layer), Int(b.counterA6), Int(b.vx), Int(b.vy)], [0xc, -30, Int(vx), Int(vy)])
                XCTAssertEqual([Int(b.hp), Int(b.gravity)], [200, 300], "the boulder's Setup (ES)")
            }
        }
        let thud = try XCTUnwrap(w.player.cues.first { $0.snd == 304 })
        XCTAssertEqual([thud.call == .threeD, thud.priority == 1, thud.volume == 0x100], [true, true, true])
        XCTAssertEqual(thud.position, SpriteSlot.Point(x: cx, y: cy))
        // `+0xb2 >> 1` = 9: state 5, `+0xb2 = −(R(0x50) + 0x28) + 1`, the face kept; R(0x50) pinned at 0 and 0x4f.
        for want in [0, 0x4f] as [Int16] {
            w.active.update(id: id) { $0.subtype = 2; $0.subState = 18; $0.face = FaceRef(pict: 0x6e0, index: 8, set: .encoded) }
            w.rng = FastRand(seed: seed { r in cry(&r); return r.next(0x50) == want })
            var r = w.rng
            cry(&r)
            _ = r.next(0x50)
            frame(w, id, solver)
            XCTAssertEqual(w.rng.seed, r.seed)
            s = try slot(w, id)
            XCTAssertEqual([Int(s.subtype), Int(s.subState)], [5, 1 - (Int(want) + 0x28)], "R(0x50) \(want)")
            XCTAssertEqual(s.face, FaceRef(pict: 0x6e0, index: 8, set: .encoded), "kept")
        }
        XCTAssertEqual(shots(w).count, 1, "one boulder a throw")
        // The friction, both states (M l. 57996–58005): |vx| ≤ 0x80 → 0, else (int)(vx · 0.7) — in the air, no tiles.
        let wf = try world(px: 3000, floor: false)
        let sf = TileSolver(world: wf)
        let fid = try walker(wf, type: 0x6e0, x: 300, y: 100)
        frame(wf, fid, sf)
        for (state, b2, vx, want) in [(Int16(5), Int16(-50), Int32(1000), 700), (2, 2, -1000, -700), (5, -50, 0x80, 0),
                                      (5, -50, -0x81, -90), (2, 2, 0x81, 90)] {
            wf.active.update(id: fid) { $0.subtype = state; $0.subState = b2; $0.vx = vx }
            frame(wf, fid, sf)
            XCTAssertEqual(Int(try slot(wf, fid).vx), want, "state \(state) vx \(vx)")
        }
        // No free record (Ruling 16): no boulder, no Setup draws — the speed pair still drawn, its stores dropped.
        while w.active.sprites.count < SpriteWorld.recordCount { _ = w.active.insert(SpriteSlot(type: 1, x: 0, y: 0)) }
        w.active.update(id: id) { $0.subtype = 2; $0.subState = 8 }
        var r = w.rng
        cry(&r)
        _ = r.next(0x28a)
        _ = r.next(0x28a)
        let count = w.active.sprites.count
        frame(w, id, solver)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.active.sprites.count, count)
        XCTAssertEqual(Int(try slot(w, id).subState), 9)
    }

    func test1760BombVariantP1() throws {
        // The thrown type is 0x6e1 + the record's p1 (M l. 58049–58053): p1 1 → the bomb boulder 0x6e2 (level 4's rec 119),
        // p1 2 → 0x6e3 (the default EnemyShot arm: rect (8, 8, 0x10, 0x10), one draw). Flip 0: from cx − 0x1c − 0x10,
        // vx −0x514 − R(0x28a).
        for (p1, type) in [(Int16(1), Int16(0x6e2)), (2, 0x6e3), (0, 0x6e1)] {
            let w = try world(px: 3000)
            let (id, solver) = try boulderThrower(w, p1: p1)
            let c = try slot(w, id)
            w.active.update(id: id) { $0.subtype = 2; $0.subState = 8; $0.mirrored = false }
            var r = w.rng
            cry(&r)
            shotSetupDraws(&r, boulder: type != 0x6e3)
            let vy = -0x6a4 - Int32(r.next(0x28a)), vx = -0x514 - Int32(r.next(0x28a))
            frame(w, id, solver)
            XCTAssertEqual(w.rng.seed, r.seed, "p1 \(p1)")
            let b = try XCTUnwrap(shots(w).first, "p1 \(p1)")
            XCTAssertEqual(b.type, type)
            XCTAssertEqual([b.x, b.y], [c.centre.x - 0x2c, c.centre.y - 0x26], "p1 \(p1)")
            XCTAssertEqual([Int(b.vx), Int(b.vy), Int(b.counterA6), Int(b.layer)], [Int(vx), Int(vy), -30, 0xc], "p1 \(p1)")
            XCTAssertEqual(b.hotRect, type == 0x6e3 ? IdleSprites.Rect(top: 8, left: 8, bottom: 0x10, right: 0x10)
                                                    : IdleSprites.Rect(top: 8, left: 8, bottom: 0x18, right: 0x18))
            XCTAssertEqual(Int(b.crunches), type != 0x6e3 ? 1 : 0, "the bombs' crunch flag `+0xeb`")
            XCTAssertEqual(try slot(w, id).face, FaceRef(pict: 0x6e0, index: 4, set: .encoded))
        }
        // The speeds pinned at their draws' ends: R(0x28a) = 0 → −0x6a4 / −0x514; R(0x28a) = 0x289 → −0x92d / −0x79d.
        for want in [0, 0x289] as [Int16] {
            let w = try world(px: 3000)
            let (id, solver) = try boulderThrower(w, p1: 1)
            w.active.update(id: id) { $0.subtype = 2; $0.subState = 8; $0.mirrored = true }
            w.rng = FastRand(seed: seed { r in
                cry(&r)
                shotSetupDraws(&r, boulder: true)
                return r.next(0x28a) == want && r.next(0x28a) == want
            })
            frame(w, id, solver)
            let b = try XCTUnwrap(shots(w).first)
            XCTAssertEqual([Int(b.vy), Int(b.vx)], want == 0 ? [-0x6a4, 0x514] : [-0x92d, 0x79d], "R \(want)")
        }
    }

    func test1760FacesLeftSheet() throws {
        // The sheet 0x6e0 faces left: `.SetupWalkerSprite` flips it (M l. 56943–56949, 56988–56994); its state 5 faces
        // the player every frame, flip = cx < P.x (M l. 58024–58029) — the player level or left: unflipped. The blink
        // (M l. 58010–58023): `+0xb4 < −20` → + 1, face 0x6e0[8], no draw; else + 1, R(25) == 1 with the stepped
        // `+0xb4 ≥ 0` → `+0xb4 = −28`, face [0] — eight frames of [8].
        let w = try world(px: 3000)
        let solver = TileSolver(world: w)
        let id = try walker(w, type: 0x6e0, x: 300, y: 315)
        XCTAssertTrue(try slot(w, id).mirrored)
        XCTAssertEqual(try slot(w, id).face, FaceRef(pict: 0x6e0, index: 0, set: .encoded))
        var r = w.rng
        cry(&r)
        _ = r.next(0x19)
        frame(w, id, solver)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(try slot(w, id).classWordB4, -2, "the first Handle's −3 (flipped), then the blink step")
        for _ in 0..<2 { frame(w, id, solver) }
        let cx = try slot(w, id).centre.x
        for (px, flip) in [(cx + 1, true), (cx, false), (cx - 1, false), (cx + 2000, true), (cx - 2000, false)] {
            w.player.centreX = Int16(px)
            w.active.update(id: id) { $0.subState = -100; $0.mirrored = !flip }
            frame(w, id, solver)
            XCTAssertEqual(try slot(w, id).mirrored, flip, "P.x \(px)")
        }
        w.player.centreX = Int16(cx + 2000)
        // The blink's edges: R(25) == 1 starts it only from a stepped `+0xb4 ≥ 0`; R(25) 0 / 2 never.
        for (b4, rand, want) in [(Int16(-1), Int16(1), Int16(-28)), (-2, 1, -1), (0, 1, -28), (0x50, 1, -28),
                                 (0, 0, 1), (0, 2, 1), (-20, 1, -19)] {
            w.active.update(id: id) { $0.classWordB4 = b4; $0.subState = -100 }
            w.rng = FastRand(seed: seed { r in cry(&r); return r.next(0x19) == rand })
            var q = w.rng
            cry(&q)
            _ = q.next(0x19)
            frame(w, id, solver)
            XCTAssertEqual(w.rng.seed, q.seed, "b4 \(b4)")
            let s = try slot(w, id)
            XCTAssertEqual(s.classWordB4, want, "b4 \(b4) R(25) \(rand)")
            XCTAssertEqual(s.face, FaceRef(pict: 0x6e0, index: 0, set: .encoded), "b4 \(b4)")
        }
        // R(25), not R(26): a stream on which the two differ (R(25) 1, R(26) 2) starts the blink.
        w.active.update(id: id) { $0.classWordB4 = 0; $0.subState = -100 }
        w.rng = FastRand(seed: seed { r in
            cry(&r)
            var q = r
            return r.next(0x19) == 1 && q.next(0x1a) == 2
        })
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).classWordB4, -28, "R(25) == 1")
        // −28 … −21: face [8], no draw; −20: face [0] and the draw.
        w.active.update(id: id) { $0.classWordB4 = -28; $0.subState = -100 }
        for k in 0..<9 {
            var q = w.rng
            cry(&q)
            if k == 8 { _ = q.next(0x19) }
            frame(w, id, solver)
            XCTAssertEqual(w.rng.seed, q.seed, "blink frame \(k)")
            let s = try slot(w, id)
            XCTAssertEqual(s.face, FaceRef(pict: 0x6e0, index: k < 8 ? 8 : 0, set: .encoded), "blink frame \(k)")
            XCTAssertEqual(Int(s.classWordB4), k < 8 ? -27 + k : -19, "blink frame \(k)")
        }
        // The cache marks: the 0x6e0 Setup marks its own set (M l. 56989); the renderer's sheet holds the nine cells
        // the Handle faces from (9 × 0x54×0x5c, one row).
        XCTAssertEqual(CachedFaces.marks(type: 0x6e0).sets, [0x6e0])
        XCTAssertEqual(CachedFaces.sheets(markedBy: [Int16(0x6e0)]),
                       [SetupFaces.Sheet(pict: 0x6e0, count: 9, cellWidth: 0x54, cellHeight: 0x5c, columns: 9, clut: 200)])
    }

    // MARK: - the Ax goblin 1750 (WK2)

    /// A 1750 (type 0x6d6) at (200, 308) — its hot rect's bottom 0x5c on the floor's surface (y 400) — after `settle`
    /// Handles, the player alive (`G+4` 100).
    private func axGoblin(_ w: SpriteWorld, p3: Int16 = 0, settle: Int = 3) throws -> (Int, TileSolver) {
        w.globals.health = 100
        let solver = TileSolver(world: w)
        let id = try walker(w, type: 0x6d6, x: 200, y: 308, p3: p3)
        for _ in 0..<settle { frame(w, id, solver) }
        return (id, solver)
    }

    /// `.AxGoblinCoreLogic` alone on a 1750 whose centre is (`cx`, `cy`), the player at (`px`, `py`), from a reset of
    /// the fields it reads (state 1, `+0xb2` 0, counters 0, HP 500, on ground, vx 77, vy 0), then `edit`.
    private func logic(_ w: SpriteWorld, _ id: Int, cx: Int, cy: Int, px: Int, py: Int,
                       _ edit: (inout SpriteSlot) -> Void = { _ in }) throws -> SpriteSlot {
        w.player.centreX = Int16(px)
        w.player.centreY = Int16(py)
        w.player.cues = []
        w.active.update(id: id) { s in
            s.centre = SpriteSlot.Point(x: cx, y: cy)
            s.subtype = 1
            s.subState = 0
            s.phase = 5
            s.classWord160 = 0
            s.launchSpeed = 0
            s.classWord174 = 0
            s.classWordB6 = 0
            s.classWord16c = 0
            s.classWord100 = 0
            s.hp = 500
            s.groundKind = 3
            s.vx = 77
            s.vy = 0
            s.bonusP4 = 0
            s.mirrored = false
            edit(&s)
        }
        AxGoblin.coreLogic(w, id: id)
        return try slot(w, id)
    }

    func testAxGoblinSwing() throws {
        // `.AxGoblinCoreLogic`'s swing (M l. 57188–57200): the target within 110 px across and 40 px up or down, chasing
        // (`+0xb6` 0), no wall jump → state 2, `+0xb2` 1, `+0x46` 0, `+0x160` = `+0x164` = 0, no draw.
        let w = try world()
        let (id, solver) = try axGoblin(w)
        for (dx, dy, swings) in [(109, 0, true), (110, 0, false), (-109, 39, true), (-110, 0, false), (0, -39, true),
                                 (50, 40, false), (50, -40, false), (0, 0, true)] {
            let seed0 = w.rng.seed
            let s = try logic(w, id, cx: 400, cy: 300, px: 400 + dx, py: 300 + dy) {
                $0.classWord160 = 2
                $0.launchSpeed = 9
                $0.phase = 4
            }
            if !swings { XCTAssertNotEqual(Int(s.subtype), 2, "dx \(dx) dy \(dy)") }
            if !swings && abs(dy) < 40 {
                // dx 110, no wall hit: past the near test — `+0x164` 9 → 8, nothing more (no jump, no draw).
                XCTAssertEqual([Int(s.subtype), Int(s.launchSpeed)], [1, 8], "dx \(dx)")
                XCTAssertEqual(w.rng.seed, seed0, "dx \(dx)")
            }
            if swings {
                XCTAssertEqual(Int(s.subtype), 2, "dx \(dx) dy \(dy)")
                XCTAssertEqual([Int(s.subState), Int(s.phase), Int(s.classWord160), Int(s.launchSpeed), Int(s.classWordB6)],
                               [1, 0, 0, 0, 0], "dx \(dx) dy \(dy)")
                XCTAssertEqual(w.rng.seed, seed0, "no draw")
                XCTAssertTrue(w.player.cues.isEmpty)
            }
        }
        // Fleeing (`+0xb6` 3: HP ≤ 200 within 600 px) or a wall jump (`+0x16c` > 0 with dx ≥ 110) never swings.
        XCTAssertNotEqual(try logic(w, id, cx: 400, cy: 300, px: 450, py: 300) { $0.hp = 200; $0.classWord16c = 1 }.subtype, 2)
        // The swing frames (the Handle's state 2, M l. 58117–58197): gravity 0x151, vx halved toward zero, the face by
        // `+0x46` (0 → 0x6d6; 1–2, 3–4, 5–6, 7–8, 9–11, 12–17 → 0x6d8[0…5]); `+0xa6 > 0` → − 1; at 0: `+0x46` + 1, at 5
        // snd 704 pitched 45000 (`.STPlay3DSoundPitched`, no draw), at 8 `+0xa6 = 10 + R(12)` and the axe hitbox
        // `MTNewSprite(0x6d6, x + (flip ? 3 : 0x99), y + 0x2c, 0, −1, .SetupEnemyShotSprite)`; else `+0x46` < 1 → face
        // 0x6d6; else + 1, past 14 → 0 and `.AxGoblinCoreLogic`. Facing only while `+0x46 == 0`.
        _ = solver
        let w2 = try world()
        let (gid, gs) = try axGoblin(w2)
        let c = try slot(w2, gid)
        XCTAssertNotEqual(c.groundKind, 0)
        w2.player.centreX = Int16(c.centre.x + 60)
        w2.player.centreY = Int16(c.centre.y)
        w2.active.update(id: gid) { $0.subtype = 1; $0.subState = 0; $0.phase = 0; $0.counterA6 = 0; $0.classWord16c = 0 }
        var r = w2.rng
        cry(&r)
        frame(w2, gid, gs)
        XCTAssertEqual(w2.rng.seed, r.seed, "the walk and the swing draw nothing")
        var s = try slot(w2, gid)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.phase), Int(s.vx)], [2, 1, 0, -1400],
                       "the walk step (away from the player at `+0xb2` 0), then the swing")
        XCTAssertEqual(s.face, FaceRef(pict: 0x6d7, index: 0, set: .encoded))
        XCTAssertFalse(s.mirrored, "facing at `+0x46` 0: the player right, `+0xb2` ≠ 2 → unflipped")
        let faces: [Int: Int] = [1: 0, 2: 0, 3: 1, 4: 1, 5: 2, 6: 2, 7: 3, 8: 3, 9: 4, 10: 4, 11: 4, 12: 5, 13: 5, 14: 5]
        let halves: [Int32] = [-700, -350, -175, -87, -43, -21, -10, -5, -2, -1, 0, 0, 0, 0, 0]
        w2.player.cues = []
        var a6 = 0
        var atThrow = c
        for k in 0..<15 {                                               // `+0x46` before: 0 … 14
            let before = try slot(w2, gid)
            if k == 7 { atThrow = before }
            XCTAssertEqual(Int(before.phase), k)
            w2.active.update(id: gid) { $0.gravity = 7 }
            r = w2.rng
            cry(&r)
            if k == 7 {
                a6 = Int(r.next(0xc)) + 10
                shotSetupDraws(&r, boulder: false)
            }
            if k == 3 { w2.player.centreX = Int16(c.centre.x - 60) }  // moved left mid-swing: no turn until `+0x46` 0
            frame(w2, gid, gs)
            XCTAssertEqual(w2.rng.seed, r.seed, "phase \(k)")
            s = try slot(w2, gid)
            XCTAssertEqual(s.face, k == 0 ? FaceRef(pict: 0x6d6, index: 0, set: .encoded)
                                          : FaceRef(pict: 0x6d8, index: faces[k]!, set: .encoded), "phase \(k)")
            XCTAssertEqual(Int(s.vx), Int(halves[k]), "phase \(k)")
            XCTAssertEqual(Int(s.gravity), 0x151)
            XCTAssertEqual(w2.player.cues.filter { $0.snd == 704 }.count, k < 4 ? 0 : 1, "phase \(k)")
            XCTAssertEqual(shots(w2).count, k < 7 ? 0 : 1, "phase \(k)")
            if k < 14 {
                XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.counterA6)], [2, k + 1, k < 7 ? 0 : a6 - (k - 7)],
                               "phase \(k)")
                XCTAssertFalse(s.mirrored, "phase \(k)")
            } else {
                // Past 14: `+0x46` 0 and `.AxGoblinCoreLogic` (the player 60 px left: the swing again), then facing:
                // the player left, `+0xb2` ≠ 2 → flipped.
                XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.subState), Int(s.counterA6)], [2, 0, 1, a6 - 7])
                XCTAssertTrue(s.mirrored)
            }
        }
        let swish = try XCTUnwrap(w2.player.cues.first { $0.snd == 704 })
        XCTAssertEqual([swish.call == .threeDPitched, swish.rate == 45000, swish.priority == 1, swish.volume == 0x100],
                       [true, true, true, true])
        let axe = try XCTUnwrap(shots(w2).first)
        XCTAssertEqual([Int(axe.type), axe.x, axe.y, Int(axe.layer)], [0x6d6, atThrow.x + 0x99, atThrow.y + 0x2c, 0])
        XCTAssertEqual([Int(axe.counterA6), Int(axe.hp), Int(axe.vx), Int(axe.vy)], [3, 0x70, 0, 0])
        XCTAssertEqual(axe.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0x18, right: 0x3c))
        // The cooldown at `+0x46` 0: `+0xa6` − 1, face 0x6d6 — until it reaches 0, when `+0x46` steps to 1 that frame.
        for left in stride(from: a6 - 8, through: 0, by: -1) {
            frame(w2, gid, gs)
            s = try slot(w2, gid)
            XCTAssertEqual([Int(s.counterA6), Int(s.phase)], [left, left == 0 ? 1 : 0], "a6 \(left)")
            XCTAssertEqual(s.face, FaceRef(pict: 0x6d6, index: 0, set: .encoded))
        }
        // R(12) pinned at its ends: 0 → `+0xa6` 10, 11 → 21.
        for (want, wantA6) in [(Int16(0), 10), (11, 21)] {
            let w3 = try world()
            let (g, s2) = try axGoblin(w3)
            w3.active.update(id: g) { $0.subtype = 2; $0.phase = 7; $0.counterA6 = 0; $0.mirrored = true }
            w3.rng = FastRand(seed: seed { r in cry(&r); return r.next(0xc) == want })
            let g0 = try slot(w3, g)
            frame(w3, g, s2)
            XCTAssertEqual(Int(try slot(w3, g).counterA6), wantA6, "R(12) \(want)")
            let ax = try XCTUnwrap(shots(w3).first)
            XCTAssertEqual([ax.x, ax.y], [g0.x + 3, g0.y + 0x2c], "flipped: x + 3")
        }
        // `+0x46` 1 under a running cooldown (no writer makes it so — synthetic): not below 1, so it steps on (→ 2) with
        // the face of `+0x46` 1, 0x6d8[0].
        w2.active.update(id: gid) { $0.subtype = 2; $0.phase = 1; $0.counterA6 = 5 }
        frame(w2, gid, gs)
        s = try slot(w2, gid)
        XCTAssertEqual([Int(s.phase), Int(s.counterA6)], [2, 4])
        XCTAssertEqual(s.face, FaceRef(pict: 0x6d8, index: 0, set: .encoded))
        // Past 14 under a running cooldown (M l. 58185–58190): `+0x46` 0, then `.AxGoblinCoreLogic` — the player far
        // right, no wall: `+0x160` −5 → −4, `+0x164` 1 → 0 → advance (state 1, `+0xb2` 1), `+0x46` left at the arm's 0;
        // then the facing (state 1 now): the player right, `+0xb2` ≠ 2 → unflipped.
        let gc = try slot(w2, gid).centre
        w2.player.centreX = Int16(gc.x + 400)
        w2.player.centreY = Int16(gc.y)
        w2.active.update(id: gid) { g in
            g.subtype = 2
            g.phase = 14
            g.counterA6 = 3
            g.launchSpeed = 1
            g.classWord160 = -5
            g.subState = 2
            g.classWord16c = 0
            g.mirrored = true
        }
        frame(w2, gid, gs)
        s = try slot(w2, gid)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.phase), Int(s.counterA6), Int(s.launchSpeed),
                        Int(s.classWord160)], [1, 1, 0, 2, 0, -4], "the swing's end hands back to the core logic")
        XCTAssertFalse(s.mirrored)
        // States 0, 3 and 5 are `.ReportError("Ax goblin error!")` (M l. 58083–58085): nothing but the facing and the tail.
        for state: Int16 in [0, 3, 5] {
            w2.active.update(id: gid) { $0.subtype = state; $0.phase = 3; $0.counterA6 = 4; $0.vx = 0 }
            r = w2.rng
            cry(&r)
            frame(w2, gid, gs)
            XCTAssertEqual(w2.rng.seed, r.seed)
            s = try slot(w2, gid)
            XCTAssertEqual([Int(s.subtype), Int(s.phase), Int(s.counterA6)], [Int(state), 3, 4], "state \(state)")
        }
        // The facing's edges (M l. 58297–58302), the arm alone in state 5 (nothing moves it): P.x == cx keeps the flip;
        // one px right → flip = (`+0xb2` == 2); one px left → flip = (`+0xb2` ≠ 2).
        for (dx, b2, before, want) in [(0, Int16(0), true, true), (0, 0, false, false), (0, 2, true, true),
                                       (0, 2, false, false), (1, 0, true, false), (1, 2, false, true),
                                       (-1, 0, false, true), (-1, 2, true, false)] {
            w2.active.update(id: gid) { g in
                g.subtype = 5
                g.subState = b2
                g.classWordB6 = 0
                g.centre = SpriteSlot.Point(x: 400, y: 300)
                g.mirrored = before
            }
            w2.player.centreX = Int16(400 + dx)
            AxGoblin.arm(w2, id: gid)
            XCTAssertEqual(try slot(w2, gid).mirrored, want, "dx \(dx) b2 \(b2) flip \(before)")
        }
    }

    func testAxGoblinJumpLand() throws {
        // `.AxGoblinCoreLogic`'s jump (M l. 57202–57270): the target not below (T.y < cy + 25) or a wall jump, with the
        // budget `+0x160` in 0…2: `+0xb2` 1, flip = T.x ≥ cx, snd 414 (`.STPlay3DSoundPitchedGob`, prio 0x14, vol 0x55,
        // R(4000) + 40000), R(100) > 0x50 → snd 610 (vol 0xab, R(4000) + 40000); state 6, `+0x46` 0; vy = wall ? −2000 −
        // R(3000) : −50·(short)(cy − T.y) − R(600), clamped to [−6250, −4800]; vx = wall ? ((R(30) + 30) / 10)·325 toward
        // T : ((cy − T.y) / 10)·(T.x − cx) + R(400) − 200; vx and `+0x168` clamped to ±4200; `+0xce` 0; `+0x160` + 1.
        let w = try world()
        let (id, solver) = try axGoblin(w)
        for (gate, cry610) in [(Int16(0x50), false), (0x51, true)] {
            w.rng = FastRand(seed: seed { r in
                _ = r.next(4000)
                guard r.next(100) == gate else { return false }
                var a = r, b = r                                        // the cry's R(4000) ≠ R(3999), R(4001)
                let v = r.next(4000)
                return !cry610 || (v != a.next(3999) && v != b.next(4001))
            })
            var r = w.rng
            let p414 = Int32(r.next(4000))
            _ = r.next(100)
            let p610 = cry610 ? Int32(r.next(4000)) : 0
            let vy = -5000 - Int32(r.next(600))
            let vx = 500 + Int32(r.next(400)) - 200
            let s = try logic(w, id, cx: 250, cy: 300, px: 300, py: 200)
            XCTAssertEqual(w.rng.seed, r.seed, "R(100) \(gate)")
            XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.phase), Int(s.groundKind), Int(s.classWord160)],
                           [6, 1, 0, 0, 1])
            XCTAssertEqual([Int(s.vy), Int(s.vx), Int(s.bonusP4)], [Int(vy), Int(vx), Int(vx)])
            XCTAssertTrue(s.mirrored, "T.x ≥ cx")
            let pitch = s.voicePitch
            XCTAssertEqual(w.player.cues.map { [Int($0.snd), Int($0.priority), Int($0.volume), Int($0.rate ?? 0)] },
                           [[414, 0x14, 0x55, Int(pitch + p414 + 40000 - 0xffff)]]
                            + (cry610 ? [[610, 0x14, 0xab, Int(pitch + p610 + 40000 - 0xffff)]] : []))
            XCTAssertTrue(w.player.cues.allSatisfy { $0.call == .threeDPitched })
        }
        // The vy clamps and the vx terms (the stream re-derived per call): d = cy − T.y; (d, T.x − cx) →
        //   (50, 50): −2500 − R(600) → −4800; vx 5·50 + R(400) − 200;  (109, 50): d / 10 = 10 (toward zero), vy −5450 − R;
        //   (140, 100): −7000 − R → −6250, vx 14·100 + R − 200;  (500, ±100): vx 50·(±100) + R − 200 → ±4200.
        for (d, dx, clampVY, vxBase, clampVX) in [(50, 50, true, 250, false), (109, 50, false, 500, false),
                                                  (140, 100, true, 1400, false), (500, 100, true, 5000, true),
                                                  (500, -100, true, -5000, true)] {
            var r = w.rng
            _ = r.next(4000)
            if 0x50 < r.next(100) { _ = r.next(4000) }
            let rv = Int32(r.next(600)), rx = Int32(r.next(400))
            let s = try logic(w, id, cx: 300 - dx, cy: 200 + d, px: 300, py: 200)
            XCTAssertEqual(w.rng.seed, r.seed)
            let rawVY = -50 * Int32(d) - rv
            XCTAssertEqual(Int(s.vy), clampVY ? (d < 100 ? -4800 : -6250) : Int(rawVY), "d \(d)")
            XCTAssertTrue(clampVY ? (rawVY > -4800 || rawVY < -6250) : true, "d \(d): the clamp is taken")
            let wantVX = clampVX ? (dx > 0 ? 4200 : -4200) : vxBase + Int(rx) - 200
            XCTAssertEqual([Int(s.vx), Int(s.bonusP4)], [wantVX, wantVX], "d \(d) dx \(dx)")
            XCTAssertEqual(s.mirrored, dx > 0)
        }
        // The wall jump (`+0x16c` > 0, dx ≥ 110): vy −2000 − R(3000) → −4800 below R 2800, else as drawn; vx (R(30) +
        // 30) / 10 · 325: R 9 → 975, 10 → 1300, 19 → 1300, 20 → 1625, 29 → 1625; negated with the target left.
        for (r30, want, r3000, wantVY) in [(Int16(9), 975, Int16(0), -4800), (10, 1300, 2799, -4800), (19, 1300, 2801, -4801),
                                          (20, 1625, 2999, -4999), (29, 1625, 1500, -4800)] {
            for left in [false, true] {
                w.rng = FastRand(seed: seed { r in
                    _ = r.next(4000)
                    if 0x50 < r.next(100) { _ = r.next(4000) }
                    return r.next(3000) == r3000 && r.next(0x1e) == r30
                })
                let s = try logic(w, id, cx: left ? 410 : 190, cy: 300, px: 300, py: 300) { $0.classWord16c = 1 }
                XCTAssertEqual([Int(s.subtype), Int(s.vy)], [6, wantVY], "R(3000) \(r3000)")
                XCTAssertEqual([Int(s.vx), Int(s.bonusP4)], [left ? -want : want, left ? -want : want], "R(30) \(r30)")
                XCTAssertEqual(s.mirrored, !left)
            }
        }
        // The jump's flip is T.x ≥ cx: the player straight above → flipped.
        XCTAssertTrue(try logic(w, id, cx: 300, cy: 300, px: 300, py: 200).mirrored)
        // Fleeing with the player level across (P.x == cx): T.x = −32000 (P.x < cx fails) — the wall jump goes left.
        let tie = try logic(w, id, cx: 300, cy: 300, px: 300, py: 300) { $0.hp = 200; $0.classWord16c = 1 }
        XCTAssertEqual([Int(tie.subtype), Int(tie.classWordB6)], [6, 3])
        XCTAssertLessThan(tie.vx, 0)
        XCTAssertFalse(tie.mirrored)
        // dx 109 with a wall hit is no wall jump: the plain jump's stream (R(600), R(400)).
        var r = w.rng
        _ = r.next(4000)
        if 0x50 < r.next(100) { _ = r.next(4000) }
        let pv = Int32(r.next(600))
        _ = r.next(400)
        let plain = try logic(w, id, cx: 191, cy: 300, px: 300, py: 250) { $0.classWord16c = 1 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(Int(plain.vy), -4800, "−2500 − R(600) \(pv) clamped")
        // The vy floor −6250 (M l. 57241–57243), each side: d 124 with R(600) 49 / 50 → −6249 / −6250; d 125 with 0 / 1
        // → −6250 / −6251 → −6250.
        for (d, rv, wantVY) in [(124, Int16(49), -6249), (124, 50, -6250), (125, 0, -6250), (125, 1, -6250)] {
            w.rng = FastRand(seed: seed { r in
                _ = r.next(4000)
                if 0x50 < r.next(100) { _ = r.next(4000) }
                return r.next(600) == rv
            })
            let t = try logic(w, id, cx: 290, cy: 200 + d, px: 300, py: 200)
            XCTAssertEqual([Int(t.subtype), Int(t.vy)], [6, wantVY], "d \(d) R(600) \(rv)")
        }
        // The ±4200 clamps of vx and `+0x168` (M l. 57263–57278), each side: d 400, T.x − cx ±105 → 40·(±105) + R(400)
        // − 200 with R 199 / 200 / 201 → 4199 / 4200 / 4201 → 4200 and −4201 → −4200 / −4200 / −4199.
        for (side, rx, want) in [(1, Int16(199), 4199), (1, 200, 4200), (1, 201, 4200), (-1, 199, -4200),
                                 (-1, 200, -4200), (-1, 201, -4199)] {
            w.rng = FastRand(seed: seed { r in
                _ = r.next(4000)
                if 0x50 < r.next(100) { _ = r.next(4000) }
                _ = r.next(600)
                return r.next(400) == rx
            })
            let t = try logic(w, id, cx: 300 - side * 105, cy: 600, px: 300, py: 200)
            XCTAssertEqual([Int(t.subtype), Int(t.vx), Int(t.bonusP4)], [6, want, want], "side \(side) R(400) \(rx)")
        }
        // The budget: 2 → jumps (→ 3); 3 → the retreat (state 1, `+0xb2` 2, `+0x164` 30, `+0x160` −30 − R(20)); −2 →
        // −1, nothing; −1 → 0 and the jump.
        XCTAssertEqual(try logic(w, id, cx: 250, cy: 300, px: 300, py: 200) { $0.classWord160 = 2 }.classWord160, 3)
        r = w.rng
        let back = -30 - Int(r.next(0x14))
        var s = try logic(w, id, cx: 250, cy: 300, px: 300, py: 200) { $0.classWord160 = 3 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.launchSpeed), Int(s.classWord160), Int(s.classWord174)],
                       [1, 2, 30, back, 0])
        XCTAssertTrue(w.player.cues.isEmpty)
        let seed0 = w.rng.seed
        s = try logic(w, id, cx: 250, cy: 300, px: 300, py: 200) { $0.classWord160 = -2; $0.phase = 9 }
        XCTAssertEqual([Int(s.subtype), Int(s.classWord160), Int(s.phase)], [1, -1, 9])
        XCTAssertEqual(w.rng.seed, seed0)
        XCTAssertEqual(try logic(w, id, cx: 250, cy: 300, px: 300, py: 200) { $0.classWord160 = -1 }.subtype, 6)
        // Fleeing (HP ≤ 200 within 600 px; T = (±32000, ±32000) away from the player, `+0xb6` 3) with a wall hit: the
        // wall jump away; at budget 3 the flee retreat — `+0x164` 70, `+0x160` −70 − R(20), `+0x174` −120 − R(60) (on a
        // stream where R(20) ≠ R(19), R(21) and R(60) ≠ R(59), R(61)).
        w.rng = FastRand(seed: seed { r in
            var a = r, b = r
            let v = r.next(0x14)
            guard v != a.next(0x13) && v != b.next(0x15) else { return false }
            var c = r, d = r
            let u = r.next(0x3c)
            return u != c.next(0x3b) && u != d.next(0x3d)
        })
        r = w.rng
        let f160 = -70 - Int(r.next(0x14)), f174 = -120 - Int(r.next(0x3c))
        s = try logic(w, id, cx: 400, cy: 300, px: 350, py: 300) { $0.hp = 200; $0.classWord16c = 1; $0.classWord160 = 3 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.classWordB6), Int(s.launchSpeed), Int(s.classWord160),
                        Int(s.classWord174)], [1, 2, 3, 70, f160, f174])
        s = try logic(w, id, cx: 400, cy: 300, px: 350, py: 300) { $0.hp = 200; $0.classWord16c = 1 }
        XCTAssertEqual([Int(s.subtype), Int(s.classWordB6)], [6, 3])
        XCTAssertGreaterThan(s.vx, 0, "away from the player (T.x 32000)")
        XCTAssertTrue(s.mirrored)
        // The flee T.y (M l. 57156–57161: P.y < cy → 32000, else −32000) reaches the arms when T.x lands within 110 px of
        // cx — a centre near x 32000 (cx 31950, P.x 31900 → T.x 32000, dx 50, no wall). P.y one above cy → T.y 32000:
        // the target-below arm (R(100) 99 → state 1, `+0xb2` 2, the second R(20)); P.y == cy → T.y −32000: the jump,
        // d = (short)(300 + 32000) = 32300 → vy −6250, vx 3230·50 + R(400) − 200 → 4200, flip (T.x ≥ cx).
        w.rng = FastRand(seed: seed { r in r.next(100) == 99 })
        r = w.rng
        _ = r.next(100)
        _ = r.next(0x14)
        let fj = -30 - Int(r.next(0x14))
        s = try logic(w, id, cx: 31950, cy: 300, px: 31900, py: 299) { $0.hp = 200 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.launchSpeed), Int(s.classWord160), Int(s.classWordB6)],
                       [1, 2, 30, fj, 3], "P.y < cy: T.y 32000, below")
        XCTAssertTrue(w.player.cues.isEmpty)
        r = w.rng
        _ = r.next(4000)
        if 0x50 < r.next(100) { _ = r.next(4000) }
        _ = r.next(600)
        _ = r.next(400)
        s = try logic(w, id, cx: 31950, cy: 300, px: 31900, py: 300) { $0.hp = 200 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.phase), Int(s.classWord160), Int(s.classWordB6),
                        Int(s.vy), Int(s.vx), Int(s.bonusP4)], [6, 1, 0, 1, 3, -6250, 4200, 4200], "P.y == cy: T.y −32000")
        XCTAssertTrue(s.mirrored)
        XCTAssertEqual(w.player.cues.first?.snd, 414)
        // T.y < cy + 25 (M l. 57208) at its edge, fleeing (no swing): cy 31975 → T.y 32000 = cy + 25, below (R(100) 99);
        // cy 31976 → the jump, d = (short)(31976 − 32000) = −24: vy 1200 − R(600) → −4800, vx (−24 / 10 = −2)·50 + R(400)
        // − 200.
        w.rng = FastRand(seed: seed { r in r.next(100) == 99 })
        r = w.rng
        _ = r.next(100)
        _ = r.next(0x14)
        let ej = -30 - Int(r.next(0x14))
        s = try logic(w, id, cx: 31950, cy: 31975, px: 31900, py: 31875) { $0.hp = 200 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.launchSpeed), Int(s.classWord160)], [1, 2, 30, ej],
                       "T.y == cy + 25: below")
        r = w.rng
        _ = r.next(4000)
        if 0x50 < r.next(100) { _ = r.next(4000) }
        _ = r.next(600)
        let ex = -300 + Int(r.next(400))
        s = try logic(w, id, cx: 31950, cy: 31976, px: 31900, py: 31876) { $0.hp = 200 }
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.classWord160), Int(s.vy), Int(s.vx), Int(s.bonusP4)],
                       [6, 1, 1, -4800, ex, ex], "T.y == cy + 24: the jump")
        // The target choice (M l. 57126–57162): flee while HP < 0xc9 ∧ `+0x174` == 0 (after its step) ∧ `+0x100` == 0 ∧
        // |cx − P.x| < 600, or while the player's health `G+4` ≤ 0; else chase, which stores `+0x174 = 0`.
        for (hp, l174, imm, px, health, flees) in [(200, 0, 0, 999, 100, true), (201, 0, 0, 999, 100, false),
                                                   (200, 0, 0, 1000, 100, false), (200, 0, 0, -199, 100, true),
                                                   (200, 0, 0, -200, 100, false), (200, -1, 0, 999, 100, true),
                                                   (200, -2, 0, 999, 100, false), (200, 0, 1, 999, 100, false),
                                                   (500, 0, 0, 999, 0, true), (500, 0, 0, 999, 1, false),
                                                   (500, -50, 0, 999, 1, false)] {
            w.globals.health = Int16(health)
            s = try logic(w, id, cx: 400, cy: 300, px: px, py: 300) {
                $0.hp = Int16(hp)
                $0.classWord174 = Int32(l174)
                $0.classWord100 = Int32(imm)
            }
            XCTAssertEqual(Int(s.classWordB6), flees ? 3 : 0, "hp \(hp) 174 \(l174) imm \(imm) px \(px) G+4 \(health)")
            if !flees { XCTAssertEqual(s.classWord174, 0, "chasing clears the lockout") }
            XCTAssertEqual([Int(s.subtype), Int(s.subState)], [1, 1], "far, no wall hit: advance")
        }
        w.globals.health = 100
        // `+0x164` steps down first: 2 → 1 holds the state; 1 → 0 advances (state 1, `+0xb2` 1).
        s = try logic(w, id, cx: 400, cy: 300, px: 600, py: 300) { $0.launchSpeed = 2; $0.subState = 2; $0.subtype = 7 }
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.launchSpeed)], [7, 2, 1])
        s = try logic(w, id, cx: 400, cy: 300, px: 600, py: 300) { $0.launchSpeed = 1; $0.subState = 2; $0.subtype = 7 }
        XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.launchSpeed)], [1, 1, 0])
        // The target below (T.y ≥ cy + 25, dx < 110): r = R(100), `+0x164` 30, `+0x160` −30 − R(20); r < 11 → hop with
        // `+0xb2` 2, < 21 → hop with 1 (state 6, `+0x46` 0, vy −2500 − R(3000) clamped to [−6000, −4000], vx kept); < 61
        // → state 1, `+0xb2` 1; else `+0xb2` 2 — both with a second `+0x160` −30 − R(20).
        for (pick, hop, b2) in [(Int16(10), true, 2), (11, true, 1), (20, true, 1), (21, false, 1), (60, false, 1),
                                (61, false, 2), (0, true, 2), (99, false, 2)] {
            // R(100), not R(99) / R(101): above each edge R(99) falls below it, below each edge R(101) reaches it.
            w.rng = FastRand(seed: seed { r in
                var a = r, b = r
                guard r.next(100) == pick else { return false }
                switch pick {
                case 11, 21, 61: return a.next(99) == pick - 1
                case 10, 20, 60: return b.next(101) == pick + 1
                default: return true
                }
            })
            r = w.rng
            _ = r.next(100)
            var j = -30 - Int(r.next(0x14))
            var vy = 0
            if hop { vy = -2500 - Int(r.next(3000)) } else { j = -30 - Int(r.next(0x14)) }
            s = try logic(w, id, cx: 300, cy: 300, px: 330, py: 400)
            XCTAssertEqual(w.rng.seed, r.seed, "R(100) \(pick)")
            XCTAssertEqual([Int(s.subtype), Int(s.subState), Int(s.launchSpeed), Int(s.classWord160)],
                           [hop ? 6 : 1, b2, 30, j], "R(100) \(pick)")
            XCTAssertEqual([Int(s.vx), Int(s.groundKind)], [77, 3], "vx kept, still on ground")
            if hop {
                XCTAssertEqual(Int(s.phase), 0)
                XCTAssertEqual(Int(s.vy), vy > -4000 ? -4000 : vy, "R(100) \(pick)")
            }
        }
        for (r3000, wantVY) in [(Int16(1499), -4000), (1500, -4000), (1501, -4001), (2999, -5499)] {
            w.rng = FastRand(seed: seed { r in
                guard r.next(100) == 5 else { return false }
                _ = r.next(0x14)
                return r.next(3000) == r3000
            })
            XCTAssertEqual(Int(try logic(w, id, cx: 300, cy: 300, px: 330, py: 400).vy), wantVY, "R(3000) \(r3000)")
        }
        // The airborne state 6 (M l. 58242–58298): `+0x46` steps up while rising (vy < 0, below 8) and down while falling
        // fast (vy > 2000, above 1); the face 0x6d9[(`+0x46` − 1) / 3] (toward zero; [0] below 0); airborne, vx moves
        // toward `+0x168` by |`+0x168`| / 6. In the air — no tiles.
        let wa = try world(floor: false)
        let (aid, sa) = try axGoblin(wa, settle: 1)
        func air(phase: Int16, vy: Int32, vx: Int32 = 0, target: Int32 = 0) throws -> SpriteSlot {
            wa.active.update(id: aid) { s in
                s.subtype = 6
                s.phase = phase
                s.vy = vy
                s.vx = vx
                s.bonusP4 = target
                s.groundKind = 0
            }
            frame(wa, aid, sa)
            return try slot(wa, aid)
        }
        for (p, vy, want) in [(Int16(7), Int32(-1), 8), (8, -1, 8), (0, -1, 1), (0, 100, 0), (5, 0, 5), (5, 2000, 5),
                              (5, 2001, 4),
                              (2, 2001, 1), (1, 2001, 1), (-3, 2001, -2)] {
            let s = try air(phase: p, vy: vy)
            XCTAssertEqual(Int(s.phase), want, "phase \(p) vy \(vy)")
            let cell = want < 0 ? 0 : (want - 1) / 3
            XCTAssertEqual(s.face, FaceRef(pict: 0x6d9, index: cell, set: .encoded), "phase \(p) vy \(vy)")
        }
        for (p, cell) in [(Int16(1), 0), (2, 0), (3, 0), (4, 1), (6, 1), (7, 2), (8, 2)] {
            XCTAssertEqual(try air(phase: p, vy: 100).face, FaceRef(pict: 0x6d9, index: cell, set: .encoded), "phase \(p)")
        }
        for (vx, target, want) in [(Int32(0), Int32(600), 100), (0, -600, -100), (5, 7, 6), (-5, -7, -6), (600, 600, 600),
                                   (700, 600, 600), (-700, -600, -600), (10, -6, 9), (-10, 6, -9)] {
            XCTAssertEqual(Int(try air(phase: 3, vy: 100, vx: vx, target: target).vx), want, "vx \(vx) → \(target)")
        }
        // The facing while fleeing inverts only at `+0x174` 0 (airborne: no core logic to change `+0xb6`): the player
        // right, `+0xb2` 0 → unflipped; inverted → flipped.
        for (l174, flip) in [(Int32(-50), false), (0, true)] {
            wa.player.centreX = Int16(try slot(wa, aid).centre.x + 300)
            wa.active.update(id: aid) { $0.classWordB6 = 3; $0.classWord174 = l174; $0.subState = 0; $0.mirrored = !flip }
            XCTAssertEqual(try air(phase: 3, vy: 100).mirrored, flip, "+0x174 \(l174)")
        }
        wa.active.update(id: aid) { $0.classWordB6 = 0; $0.classWord174 = 0 }
        // The walk's `.SetSpriteSpeed(±1400, 0x200)` stores vy 0x200: flagged on ground in the air, it falls from 0x200 —
        // the vy of a no-op state-5 twin given 0x200 (the player far: the core logic does nothing).
        func walkVY(_ state: Int16) throws -> Int32 {
            wa.player.centreX = Int16(try slot(wa, aid).centre.x + 2000)
            wa.active.update(id: aid) { s in
                s.subtype = state
                s.groundKind = 3
                s.vy = state == 1 ? 0 : 0x200
                s.launchSpeed = 50
                s.subState = 0
                s.classWord16c = 0
            }
            frame(wa, aid, sa)
            return try slot(wa, aid).vy
        }
        XCTAssertEqual(try walkVY(1), try walkVY(5))
        // −1 → 0: vy −5000 and `+0xce` 0 (as written — no writer of a negative `+0x46`), the same vy as a goblin set to
        // −5000 at `+0x46` 0 (which then steps to 1).
        let neg = try air(phase: -1, vy: 300)
        let twin = try air(phase: 0, vy: -5000)
        XCTAssertEqual([Int(neg.phase), Int(twin.phase), Int(neg.vy)], [0, 1, Int(twin.vy)])
        // That frame does not steer: `+0xce` was just cleared but `+0xcd` (last frame's ground) is set.
        let wg = try world(px: 3000)
        let (gg, sg) = try axGoblin(wg)
        wg.active.update(id: gg) { $0.subtype = 6; $0.phase = -1; $0.vx = 0; $0.bonusP4 = 600; $0.counterA6 = 0 }
        frame(wg, gg, sg)
        XCTAssertEqual([Int(try slot(wg, gg).phase), Int(try slot(wg, gg).vx)], [0, 0])
        // The landing (the tail, M l. 58412–58418): landed in state 6 → `+0xa6 = 2 + R(4)`, `+0x46` 0, face 0x6d6; R(4)
        // pinned at 0 and 3.
        for (r4, wantA6) in [(Int16(0), 2), (3, 5)] {
            let wl = try world(px: 3000)
            let (lid, sl) = try axGoblin(wl)
            wl.active.update(id: lid) { s in
                s.subtype = 6
                s.phase = 3
                s.groundKind = 0
                s.vx = 0
                s.vy = 0
                s.bonusP4 = 0
                s.counterA6 = 0
            }
            wl.rng = FastRand(seed: seed { r in cry(&r); return r.next(4) == r4 })
            var q = wl.rng
            cry(&q)
            _ = q.next(4)
            frame(wl, lid, sl)
            XCTAssertEqual(wl.rng.seed, q.seed, "R(4) \(r4)")
            var t = try slot(wl, lid)
            XCTAssertEqual([Int(t.subtype), Int(t.counterA6), Int(t.phase)], [6, wantA6, 0], "R(4) \(r4)")
            XCTAssertNotEqual(t.groundKind, 0)
            XCTAssertEqual(t.face, FaceRef(pict: 0x6d6, index: 0, set: .encoded))
            // On the ground in state 6: face 0x6d6, vx 0; `+0xa6 > 0` → `+0x170 = 50`, `+0xa6` − 1, `+0x16c` 0; at 0 (and
            // `+0x46 ≥ 0`) `.AxGoblinCoreLogic` — the player far right, no wall: advance (state 1, `+0xb2` 1).
            for left in stride(from: wantA6 - 1, through: 0, by: -1) {
                wl.active.update(id: lid) { $0.classWord16c = 4; $0.vx = 300 }
                frame(wl, lid, sl)
                t = try slot(wl, lid)
                XCTAssertEqual([Int(t.subtype), Int(t.counterA6), Int(t.classWord170), Int(t.classWord16c), Int(t.vx)],
                               [6, left, 50, 0, 0], "a6 → \(left)")
                XCTAssertEqual(t.face, FaceRef(pict: 0x6d6, index: 0, set: .encoded))
            }
            frame(wl, lid, sl)
            t = try slot(wl, lid)
            XCTAssertEqual([Int(t.subtype), Int(t.subState)], [1, 1], "R(4) \(r4): `.AxGoblinCoreLogic`")
            XCTAssertEqual(t.face, FaceRef(pict: 0x6d6, index: 0, set: .encoded), "the landed face (M l. 58277)")
            // `+0x46` below 0 on the ground with `+0xa6` 0: no `.AxGoblinCoreLogic` (it steps toward 0 instead).
            wl.active.update(id: lid) { $0.subtype = 6; $0.phase = -3; $0.counterA6 = 0; $0.subState = 2 }
            frame(wl, lid, sl)
            t = try slot(wl, lid)
            XCTAssertEqual([Int(t.subtype), Int(t.phase), Int(t.subState)], [6, -2, 2])
            XCTAssertEqual(t.face, FaceRef(pict: 0x6d6, index: 0, set: .encoded), "the landed face over 0x6d9[0]")
        }
        // The walk (state 1 on the ground, M l. 58089–58114): right iff P.x < cx, inverted at `+0xb2` 1 and again while
        // fleeing (`+0xb6` 3 ∧ `+0x174` 0); `.SetSpriteSpeed(±1400, 0x200)`; `+0x46` + 1 wrapped 0…15; face 0x6d7[`+0x46 >>
        // 1`]; then `.AxGoblinCoreLogic`. Facing (not dying, not mid-swing): P right → flip = (`+0xb2` == 2), P left →
        // flip = (`+0xb2` ≠ 2), inverted while fleeing.
        let ww = try world(px: 3000)
        let (wid, sw) = try axGoblin(ww)
        let wc = try slot(ww, wid).centre
        // (The fleeing rows keep HP 200 so the call's own target choice keeps `+0xb6` 3; at `+0x174` −9 it chases and
        // clears `+0xb6` before the facing.)
        for (pxSide, b2, b6, l174, vx, flip) in [(1, Int16(0), Int16(0), Int32(0), -1400, false), (-1, 0, 0, 0, 1400, true),
                                                 (1, 1, 0, 0, 1400, false), (-1, 1, 0, 0, -1400, true),
                                                 (1, 2, 0, 0, -1400, true), (-1, 2, 0, 0, 1400, false),
                                                 (1, 2, 3, 0, 1400, false), (-1, 2, 3, 0, -1400, true),
                                                 (1, 2, 3, -9, -1400, true), (0, 1, 0, 0, 1400, false)] {
            ww.player.centreX = Int16(wc.x + pxSide * 400)
            ww.player.centreY = Int16(wc.y)
            ww.globals.health = 100
            ww.active.update(id: wid) { s in
                s.subtype = 1
                s.subState = b2
                s.classWordB6 = b6
                s.classWord174 = l174
                s.phase = 15
                s.launchSpeed = 50
                s.hp = b6 == 3 ? 200 : 500
                s.classWord16c = 0
                s.mirrored = !flip
            }
            frame(ww, wid, sw)
            let t = try slot(ww, wid)
            XCTAssertEqual([Int(t.vx), Int(t.phase)], [vx, 0], "side \(pxSide) b2 \(b2) b6 \(b6) 174 \(l174)")
            XCTAssertEqual(t.face, FaceRef(pict: 0x6d7, index: 0, set: .encoded))
            if pxSide != 0 { XCTAssertEqual(t.mirrored, flip, "side \(pxSide) b2 \(b2) b6 \(b6) 174 \(l174)") }
        }
        // The walk's direction at P.x == cx (M l. 58088–58089, signed P.x < cx): left (−1400); one px left of cx: right.
        // The arm alone (nothing moves the centre first).
        for (dx, vx) in [(0, -1400), (-1, 1400)] {
            ww.active.update(id: wid) { s in
                s.subtype = 1
                s.groundKind = 3
                s.subState = 0
                s.classWordB6 = 0
                s.classWord174 = 0
                s.phase = 0
                s.launchSpeed = 50
                s.hp = 500
                s.centre = SpriteSlot.Point(x: 400, y: 300)
            }
            ww.player.centreX = Int16(400 + dx)
            ww.player.centreY = 300
            AxGoblin.arm(ww, id: wid)
            XCTAssertEqual(Int(try slot(ww, wid).vx), vx, "P.x − cx \(dx)")
        }
        // The walk face is 0x6d7[`+0x46 >> 1`]: 4 → 5 → [2]; 14 → 15 → [7] (no wrap at 15); below 0 it wraps to 15 → [7].
        for (p, want, cell) in [(Int16(4), 5, 2), (14, 15, 7), (-2, 15, 7)] {
            ww.player.centreX = Int16(wc.x + 2000)
            ww.active.update(id: wid) { $0.subtype = 1; $0.subState = 0; $0.phase = p; $0.launchSpeed = 50; $0.hp = 500 }
            frame(ww, wid, sw)
            let t = try slot(ww, wid)
            XCTAssertEqual(Int(t.phase), want, "phase \(p)")
            XCTAssertEqual(t.face, FaceRef(pict: 0x6d7, index: cell, set: .encoded), "phase \(p)")
        }
    }

    func testAxGoblinTierHP() throws {
        // `.SetupWalkerSprite`'s 1750 arm (M l. 56996–57007, types 0x6d6…0x6df): the marks 0x6d6 (single), 0x6d7 walk,
        // 0x6d9 jump, 0x6d8 swing, 0x6da death; state 1; face 0x6d6; flip while P.x < x + 0x32; rect (0x5e, 0x23, 0x7f,
        // 0x5c). The tier's HP column "1750" is type 0x6d6's alone (M l. 57008–57078); 0x6d7… take the others'.
        let hp1750: [Int16: Int] = [-1: 500, 0: 500, 1: 500, 2: 1200, 3: 1680, 4: 2000, 5: 1500, 6: 1350, 7: 500]
        let hpOthers: [Int16: Int] = [-1: 500, 0: 500, 1: 250, 2: 675, 3: 950, 4: 1500, 5: 850, 6: 750, 7: 500]
        let base: [Int16: (Int, Int, Int)] = [1: (16, 0x10010, 0), 2: (6, 0x10011, 0), 3: (13, 0x10012, 0),
                                              4: (4, 0x10013, 1), 5: (10, 0x10014, 0), 6: (6, 0x10015, 0)]
        for p3: Int16 in -1...7 {
            for type: Int16 in [0x6d6, 0x6d7, 0x6df] {
                let w = try world(px: 600)
                var r = w.rng
                let pitch = Int32(r.next(0x5fff)) * 2 + 0xbfff
                let reach = Int32(r.next(0x46)) + 0x78
                let w154 = Int32(r.next(400)) + 1000
                let s = try slot(w, try walker(w, type: type, x: 100, y: 280, p3: p3))
                XCTAssertEqual(w.rng.seed, r.seed)
                let k = base[p3] ?? (8, 0, 0)
                XCTAssertEqual([Int(s.hp), Int(s.classWord158), Int(s.mode), Int(s.classWord100)],
                               [type == 0x6d6 ? hp1750[p3]! : hpOthers[p3]!, k.0, k.1, k.2], "p3 \(p3) type \(type)")
                XCTAssertEqual([s.voicePitch, s.classTimer, s.classWord154, s.classWord150], [pitch, reach, w154, -1])
                XCTAssertEqual([Int(s.subtype), Int(s.gravity), Int(s.layer)], [1, 0x151, 4], "type \(type)")
                XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0x23, left: 0x5e, bottom: 0x5c, right: 0x7f))
                XCTAssertEqual(s.face, FaceRef(pict: 0x6d6, index: 0, set: .encoded))
                XCTAssertEqual([s.handler == .walker, s.hasHit, s.hasTileHit, s.mirrored, s.countedInTotals],
                               [true, true, true, false, true])
                XCTAssertEqual([s.keepRecord, s.noWriteBack189, s.noWriteBack18a, s.keepRecordAtKill, s.killedForGood],
                               [false, false, false, false, false], "no save write-back flag")
            }
        }
        // The flip: P.x 600 < x + 0x32 at x 551, not at 550.
        let wf = try world(px: 600)
        XCTAssertTrue(try slot(wf, try walker(wf, type: 0x6d6, x: 551)).mirrored)
        XCTAssertFalse(try slot(wf, try walker(wf, type: 0x6d6, x: 550)).mirrored)
        // The entry's sheet and source; the level cache: the marks and the five sheets (`.InitWalkerSprite` M l.
        // 56756, 56764–56767: the single 0x6d6; 0x6d7 8, 0x6d8 6, 0x6d9 3, 0x6da 6 cells of 0xd8×0x6e, one a row).
        let p = Placement(index: 0, flag: 1, byte1: 0, type: 0x6d6, p1: 0, p2: 0, p3: 0, p4: 0, y: 280, x: 100)
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: wf.level, playerX: 600, records: [p]))
        XCTAssertEqual(e.sheet, .single(0x6d6))
        XCTAssertEqual(e.source, .setupCached)
        for t: Int16 in [0x6d6, 0x6d9, 0x6df] {
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [0x6d7, 0x6d8, 0x6d9, 0x6da], "type \(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [0x6d6], "type \(t)")
        }
        // 0x6d5 is the Bat class's last 1740 type: its Setup marks the bat set (M l. 68286; BA), not the 1750's.
        XCTAssertEqual(CachedFaces.marks(type: 0x6d5).sets, [0x6cc])
        func set(_ pict: Int16, _ n: Int) -> SetupFaces.Sheet {
            SetupFaces.Sheet(pict: pict, count: n, cellWidth: 0xd8, cellHeight: 0x6e, columns: 1, clut: 200)
        }
        XCTAssertEqual(CachedFaces.sheets(markedBy: [Int16(0x6d6)]),
                       [set(0x6d7, 8), set(0x6d8, 6), set(0x6d9, 3), set(0x6da, 6), .single(0x6d6)])
        // `.LoadCachedSpriteFaces` over the registration rows (`.InitWalkerSprite` M l. 56755–56768: singles 0x6a4,
        // 0x6d6; sets 0x6ab 9, 0x6d7 8, 0x6d8 6, 0x6d9 3, 0x6da 6, 0x6e0 9; flag 0): n 43, q 86 → p 52, 60, 66, 69, 75,
        // 84, then 85, 86. A CLUT change reloads none of them (flag 0).
        var cache = CachedFaces()
        let need = CachedFaces.Needed(sets: [0x6ab, 0x6d7, 0x6d8, 0x6d9, 0x6da, 0x6e0], singles: [0x6a4, 0x6d6])
        XCTAssertEqual(cache.load(needed: need).map { [Int($0.0), Int($0.1)] },
                       [[52, 86], [60, 86], [66, 86], [69, 86], [75, 86], [84, 86], [85, 86], [86, 86]])
        XCTAssertEqual([cache.loadedSets, cache.loadedSingles], [need.sets, need.singles])
        cache.enterLevel(screenClut: 7)
        cache.enterLevel(screenClut: 9)
        XCTAssertTrue(cache.load(needed: need).isEmpty, "flag 0: kept across a CLUT change")
        // The death (the tail's 0x6d6 entry, then the 1750 path of state 4, M l. 58198–58241): `+0xb2` 0, state 4,
        // `+0x15c` 0, face 0x6da[0], the death cry, score + 800; then face 0x6da[min(`+0xb2` / 4, 5)], snd 703 at 0,
        // vy − 800 at `+0xb2` 20, layer 1, the ×0.9 friction, no `+0xea`; past 60: `+0x15c` + 1 (the burn past 2),
        // the record's flag cleared, the Kill when the player is 451 px across or 351 px up / down away.
        let w = try world(px: 300, floor: false)
        let (id, solver) = try axGoblin(w, settle: 1)
        w.active.update(id: id) { $0.hp = 0; $0.subtype = 5; $0.vx = 1000 }
        var r = w.rng
        cry(&r)
        _ = r.next(100)
        _ = r.next(10000)
        frame(w, id, solver)
        XCTAssertEqual(w.rng.seed, r.seed)
        var s = try slot(w, id)
        XCTAssertEqual([Int(s.type), Int(s.subtype), Int(s.subState), Int(s.classWord15c), Int(w.globals.score)],
                       [0x6d6, 4, 0, 0, 800])
        XCTAssertEqual(s.face, FaceRef(pict: 0x6da, index: 0, set: .encoded))
        XCTAssertEqual(s.vx, 1000, "the entry frame: no friction yet")
        var fall: Int32?
        for b2 in 0...60 {
            w.player.cues = []
            // The player 100 px right and the flip set: a dying goblin never turns to face (M l. 58295).
            let c0 = s.centre
            w.player.centreX = Int16(c0.x + 100)
            w.active.update(id: id) { $0.vy = 0; $0.mirrored = true }
            frame(w, id, solver)
            s = try slot(w, id)
            XCTAssertTrue(s.mirrored, "b2 \(b2): no facing while dying")
            XCTAssertEqual(s.face, FaceRef(pict: 0x6da, index: min(b2 / 4, 5), set: .encoded), "b2 \(b2)")
            XCTAssertEqual([Int(s.layer), Int(s.subState), Int(s.subtype)], [1, b2 + 1, 4], "b2 \(b2)")
            XCTAssertFalse(s.killedForGood, "b2 \(b2): no `+0xea` on the 1750 path")
            XCTAssertEqual(w.player.cues.contains {
                $0.snd == 703 && $0.volume == 0x100 && $0.priority == 1 && $0.call == .threeD && $0.position == c0
            }, b2 == 0, "b2 \(b2): `.STPlay3DSound(703, 1, 0x100, centre)` (M l. 58203)")
            if fall == nil { fall = s.vy }
            XCTAssertEqual(s.vy, try XCTUnwrap(fall) - (b2 == 20 ? 800 : 0), "b2 \(b2): from vy 0, − 800 at 20")
            if b2 == 0 { XCTAssertEqual(s.vx, 900) }
            XCTAssertEqual(Int(s.classWord15c), b2 == 60 ? 1 : 0, "b2 \(b2)")
            XCTAssertEqual(Int(w.records[0].flag), b2 == 60 ? 0 : 1, "b2 \(b2)")
        }
        w.active.update(id: id) { $0.vy = 0 }
        frame(w, id, solver)
        XCTAssertEqual(try slot(w, id).burnRow, 0)
        w.active.update(id: id) { $0.vy = 0 }
        frame(w, id, solver)
        s = try slot(w, id)
        XCTAssertEqual([Int(s.classWord15c), Int(s.burnRow), Int(s.killCount)], [3, 1, 0], "the player near: burning")
        // The Kill distance (M l. 58226–58238).
        for (dx, dy, kills) in [(0x1c2, 0, false), (0x1c3, 0, true), (-0x1c3, 0, true), (0, 0x15e, false),
                                (0, 0x15f, true), (0, -0x15e, false)] {
            let wk = try world(floor: false)
            let (ik, sk) = try axGoblin(wk, settle: 1)
            wk.levelIndex = 1
            let c = try slot(wk, ik)
            wk.player.centreX = Int16(c.centre.x + dx)
            wk.player.centreY = Int16(c.centre.y + dy)
            wk.active.update(id: ik) { $0.hp = 0; $0.subtype = 4; $0.subState = 0x3c }
            let live = wk.enemies.live
            frame(wk, ik, sk)
            XCTAssertEqual(try slot(wk, ik).dead, kills, "dx \(dx) dy \(dy)")
            XCTAssertEqual(wk.enemies.live, kills ? live - 1 : live, "dx \(dx) dy \(dy)")
        }
    }
}

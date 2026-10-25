import XCTest
import HectorResources
@testable import FerazelCore

/// SD (docs/plans/2026-10-24-ferazel-phase4.md): the Shadow Double — row 11 of `.HandlePlayerSprite` (M l.
/// 44674–44685), `.SetupShadowSprite @ 1004b7d4` (M l. 43167–43182), `.HandleShadowSprite @ 1004b4f0` (M l.
/// 43052–43166), `.ShadowBob @ 1004b410` (M l. 43008–43050), the pose ring `PTR_DAT_100a0520` row 42 writes (M l.
/// 46535–46614) and `.CastSpell`'s copies (M l. 46914–46973) — and the Pentashield orbs (`.UpdatePentSprites @
/// 1004ce64`, M l. 44127–44196; the orb shot 0x50 in `.KillPlayerShot`, M l. 51076–51215). Synthetic 16×16 grids over
/// level 1's header (as `CastTests`); every expected value is re-derived from the dump's arithmetic next to it.
final class ShadowPentaTests: XCTestCase {

    /// The player stands with his hot-rect bottom (`y + 0x55`) on the floor surface 400 (as `CastTests`).
    private let standY = 400 - 0x55

    /// A 16×16 grid with an FG kind-3 floor on row 12.
    private func world() throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    private static let empty = InventorySlot(id: -1, count: 0, field4: -1, field6: 0, isSpell: 0)
    private static func spell(_ id: Int16) -> InventorySlot {
        InventorySlot(id: id, count: 1, field4: -1, field6: 0, isSpell: 1)
    }

    private func stock(_ w: SpriteWorld, _ slots: [InventorySlot]) {
        var inv = [InventorySlot](repeating: Self.empty, count: GameGlobals.inventorySlots)
        for (k, s) in slots.enumerated() { inv[k] = s }
        w.globals.inventory = inv
        w.globals.selectedSlot = 0
        w.globals.magic = 560
        w.globals.maxMagic = 1000
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }
    private func shots(_ w: SpriteWorld) -> [SpriteSlot] { w.active.sprites.filter { $0.handler == .playerShot } }

    /// One `.MTHandleSprites` pass in list order: the player, the double, the shots (the session's handle-pass arms).
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = [], lights: inout LightTable) {
        w.handleSprites { w, id in
            switch w.active.record(id: id)?.handler {
            case .player?: Player.handle(world: w, keys: keys, solver: solver)
            case .shadow?: ShadowDouble.handle(world: w, id: id)
            case .playerShot?: PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2)
            default: break
            }
        }
    }

    /// What a ring entry holds, read off a record: (y, x) `+0xa`/`+0xc`, face `+0xc0`, mirror `+0x17e`.
    private struct Pose: Equatable {
        var x: Int, y: Int, face: FaceRef?, mirrored: Bool
    }
    private func pose(_ s: SpriteSlot) -> Pose { Pose(x: s.x, y: s.y, face: s.face, mirrored: s.mirrored) }

    // MARK: - the Shadow Double

    func testShadowReplaysPoses() throws {
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        // `.SetupPlayerSprite`'s ring (M l. 42855–42895): 14 × (y −1, x −1, airborne, face 0).
        XCTAssertEqual(w.player.shadowRing.count, 14)
        XCTAssertTrue(w.player.shadowRing.allSatisfy { $0.x == -1 && $0.y == -1 && !$0.grounded && $0.face == nil })
        let solver = TileSolver(world: w)
        var lights = LightTable()
        // 1330 as the pickup leaves it (M l. 49033–49036): timer 600, `0654` = 1.
        w.player.shadowTimer = 600
        w.player.shadowDouble = true
        // Frame 1, row 11 (M l. 44678–44684): `MTNewSprite(0x1b39, +0xc, +0xa, +0x80 − 1, −1, .SetupShadowSprite)`;
        // the Setup (M l. 43169–43182) clears both callbacks and installs the Handle. Layer 9 sorts before the player
        // (10), so the double is first handled on frame 2.
        var keys: [InputActions] = Array(repeating: .right, count: 12) + Array(repeating: .left, count: 20)
        keys += Array(repeating: [], count: 6)
        var poses: [Pose] = [], doubles: [SpriteSlot] = []
        for k in keys {
            frame(w, solver, k, lights: &lights)
            poses.append(pose(player(w)))
            doubles.append(try XCTUnwrap(w.player.shadowDoubleSprite.flatMap { w.active.sprite(id: $0) }))
        }
        let d = doubles[0]
        XCTAssertEqual([Int(d.type), Int(d.layer), Int(d.recordIndex)], [0x1b39, 9, -1])
        XCTAssertEqual(d.handler, .shadow)
        XCTAssertFalse(d.hasHit || d.hasTileHit)
        XCTAssertEqual(Set(doubles.map(\.id)).count, 1, "one double while the flag stays on")
        XCTAssertNil(d.face, "not handled on its first frame")
        // The double runs first and replays entry `0590 >> 1` = 0 (not riding): the pose row 42 recorded 13 frames
        // before the last one — 14 frames behind the player's pose at the end of a frame (M l. 43073, 46535–46613).
        // Until a real pose reaches entry 0 it shows the spawn entry: x −1 → face 0, at (−1, −1).
        for f in 2...14 {
            XCTAssertEqual(pose(doubles[f - 1]), Pose(x: -1, y: -1, face: nil, mirrored: false), "frame \(f)")
        }
        for f in 15...keys.count {
            XCTAssertEqual(pose(doubles[f - 1]), poses[f - 15], "frame \(f)")
            // Tint 0x1000b, no light overlay (M l. 43161–43163).
            XCTAssertEqual(doubles[f - 1].mode, 0x1000b)
            XCTAssertFalse(doubles[f - 1].lightOverlay)
        }
        XCTAssertNotEqual(poses[0].x, poses[11].x)
        XCTAssertTrue(poses.contains { $0.mirrored } && poses.contains { !$0.mirrored })
        XCTAssertTrue(doubles.contains { $0.mirrored } && doubles.contains { !$0.mirrored })

        // Riding (`PTR_DAT_100a0590` at 0x1b — the riding ramp is the replay index; `_DAT_100a05bc` 8): the newest
        // entry 13, x + (8 >> 1) (M l. 43158–43160).
        w.player.rideRamp = 0x1b
        w.player.rideRamp2 = 8
        let last = pose(player(w))
        frame(w, solver, lights: &lights)
        var dd = try XCTUnwrap(w.player.shadowDoubleSprite.flatMap { w.active.sprite(id: $0) })
        XCTAssertEqual(pose(dd), Pose(x: last.x + 4, y: last.y, face: last.face, mirrored: last.mirrored))
        XCTAssertEqual([w.player.rideRamp, w.player.rideRamp2], [0x19, 7], "row 42 ramps them back down")

        // Standing still (`PTR_DAT_100a0674`: two frames at the drawn position, M l. 46489–46513) freezes the ring
        // (M l. 46535). A jump in place, then still once landed: entry 0 is an airborne pose, so the double bobs —
        // `.ShadowBob` (M l. 43012–43050): the first call re-syncs (`0608` 0) on `table[phase]` against the bob 0 —
        // phase 0, |0 − 0| < 2 → phase 46, bob table[23] = −2; then phase 47 → 0 (0, 0, 2, 2, 4, …).
        w.player.rideRamp = 0
        w.player.rideRamp2 = 0
        for _ in 0..<20 { frame(w, solver, lights: &lights) }
        XCTAssertEqual(player(w).vx, 0)
        frame(w, solver, .jump, lights: &lights)
        var airborne = 0
        for _ in 0..<60 where player(w).groundKind == 0 {
            frame(w, solver, lights: &lights)
            airborne += 1
        }
        XCTAssertTrue((14...59).contains(airborne), "\(airborne)")
        func still() {
            w.active.update(id: w.playerID!) { s in
                s.drawnX = s.x
                s.drawnY = s.y
            }
            frame(w, solver, lights: &lights)
        }
        still()
        XCTAssertTrue(w.player.standingStill, "set on the first unmoved frame; that frame records nothing")
        let frozen = w.player.shadowRing
        XCTAssertFalse(frozen[0].grounded)
        var bobs: [Int] = []
        for _ in 0..<7 {
            still()
            dd = try XCTUnwrap(w.player.shadowDoubleSprite.flatMap { w.active.sprite(id: $0) })
            XCTAssertEqual(dd.x, Int(frozen[0].x))
            XCTAssertEqual(dd.face, frozen[0].face)
            bobs.append(dd.y - Int(frozen[0].y))
        }
        XCTAssertEqual(w.player.shadowRing, frozen, "no entry recorded while still")
        XCTAssertEqual(bobs, [-2, 0, 0, 2, 2, 4, 4])
    }

    func testShadowCopiesCast() throws {
        // A Fireball with the double (M l. 46914–46943): `MTNewSprite(id·256 + 1, …)` → id 0, power 1; at the shot's
        // spawn point moved by double − player; vx the shot's; vy the shot's − 0x44c (entry `0590 >> 1` grounded and
        // the shot has gravity 0xfa); `+0x17e` 0; no `+0xa4` store (damage 0).
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        var lights = LightTable()
        stock(w, [Self.spell(0)])
        w.player.shadowTimer = 600
        w.player.shadowDouble = true
        for _ in 0..<16 { frame(w, solver, .right, lights: &lights) }
        for _ in 0..<40 where player(w).vx != 0 { frame(w, solver, lights: &lights) }
        frame(w, solver, lights: &lights)
        XCTAssertEqual(player(w).vx, 0)
        let dID = try XCTUnwrap(w.player.shadowDoubleSprite)
        // The cast frame in list order: the double's Handle, then the player's (row 31 → `.CastSpell`).
        ShadowDouble.handle(world: w, id: dID)
        let d = try XCTUnwrap(w.active.sprite(id: dID))
        let p0 = player(w)
        XCTAssertNotEqual(d.x, p0.x, "the double is still catching up")
        XCTAssertTrue(w.player.shadowRing[0].grounded)
        XCTAssertFalse(d.mirrored)
        Player.handle(world: w, keys: .use, solver: solver)
        XCTAssertEqual(player(w).x, p0.x)
        var s = shots(w)
        XCTAssertEqual(s.count, 2)
        let (shot, copy) = (s[0], s[1])
        XCTAssertEqual([Int(copy.type), Int(copy.power), Int(copy.hp)], [0, 1, 0])
        XCTAssertEqual(shot.hp, 100)
        XCTAssertEqual(copy.oldPosition, SpriteSlot.Point(x: d.x + 0x26, y: d.y + 0x33))
        XCTAssertEqual([copy.x, copy.y], [copy.oldPosition.x, copy.oldPosition.y])
        XCTAssertEqual([copy.x256, copy.y256], [Int32(copy.x) << 8, Int32(copy.y) << 8])
        XCTAssertEqual(copy.vx, shot.vx)
        XCTAssertEqual(copy.vy, shot.vy - 0x44c)
        XCTAssertFalse(copy.mirrored)

        // A V Blade with the double facing left (walked left, then turned right): two copies, both `MTNewSprite(0x601,
        // …)` — the type is computed once (M l. 46915) —, each at its shot's point moved by double − player; vx the
        // shot's negated (the double's `+0x17e`, M l. 46940–46942, 46967–46969); gravity 0 → no −0x44c; damage 0 after
        // age 1 (`+0xa4 ×= power` of nothing, M l. 50466ff).
        let v = try world()
        XCTAssertNotNil(Player.spawn(world: v, x: 300, y: standY))
        let vs = TileSolver(world: v)
        stock(v, [Self.spell(6)])
        v.player.shadowTimer = 600
        v.player.shadowDouble = true
        for _ in 0..<16 { frame(v, vs, .left, lights: &lights) }
        for _ in 0..<3 { frame(v, vs, .right, lights: &lights) }
        for _ in 0..<40 where player(v).vx != 0 { frame(v, vs, lights: &lights) }
        frame(v, vs, lights: &lights)
        XCTAssertEqual(player(v).vx, 0)
        let vdID = try XCTUnwrap(v.player.shadowDoubleSprite)
        ShadowDouble.handle(world: v, id: vdID)
        let vd = try XCTUnwrap(v.active.sprite(id: vdID))
        let vp = player(v)
        XCTAssertTrue(vd.mirrored, "the double still replays a left-facing pose")
        XCTAssertFalse(vp.mirrored)
        Player.handle(world: v, keys: .use, solver: vs)
        XCTAssertEqual(player(v).x, vp.x)
        s = shots(v)
        XCTAssertEqual(s.count, 4)
        let (upper, lower, cu, cl) = (s[0], s[1], s[2], s[3])
        XCTAssertEqual([upper.type, lower.type, cu.type, cl.type].map(Int.init), [6, 0x3c, 6, 6])
        XCTAssertEqual([cu.power, cl.power], [1, 1])
        for (c, o) in [(cu, upper), (cl, lower)] {
            XCTAssertEqual(c.oldPosition, SpriteSlot.Point(x: o.oldPosition.x - (vp.x - vd.x),
                                                           y: o.oldPosition.y - (vp.y - vd.y)))
            XCTAssertEqual(c.vx, 0 - o.vx)
            XCTAssertEqual(c.vy, o.vy)
            XCTAssertFalse(c.mirrored)
        }
        for _ in 0..<2 {                                                // age −1 → 0 → 1
            for id in [cu.id, cl.id] { PlayerShot.handle(world: v, id: id, solver: vs, lights: &lights, effects: 2) }
        }
        XCTAssertEqual([cu.id, cl.id].compactMap { v.active.sprite(id: $0) }.map { [Int($0.shotAge), Int($0.hp)] },
                       [[1, 0], [1, 0]])
    }

    func testShadowEndsWithTimer() throws {
        // Row 14 ticks `064c` and sets `0654` = timer ≥ 1 ∧ the shared blink flag (M l. 44750–44756); row 11, earlier in
        // the Handle (M l. 44674–44685), reads last frame's flag: on with no double → a new one; off with one →
        // `+0xe9 = 1`, `_DAT_100a0658 = 0`. The blink toggles the flag at 210, 195, … 15 (`.TickTock`), so the double
        // vanishes at 210, 180, … 30 and comes back (a new sprite) at 195, 165, … 15; the timer's 0 on frame 600 turns
        // the flag off and frame 601's row 11 removes the double.
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        var lights = LightTable()
        w.player.shadowTimer = 600
        w.player.shadowDouble = true
        var made: [Int] = [], gaps = 0
        var last: Int?
        for _ in 1...600 {
            frame(w, solver, lights: &lights)
            let now = w.player.shadowDoubleSprite
            if let now, now != last { made.append(now) }
            if now == nil && last != nil {
                gaps += 1
                XCTAssertEqual(w.active.sprite(id: last!)?.killCount, 1)
            }
            last = now
        }
        XCTAssertEqual(made.count, 8, "the first double and its seven returns")
        XCTAssertEqual(gaps, 7)
        XCTAssertEqual(w.player.shadowTimer, 0)
        XCTAssertFalse(w.player.shadowDouble, "`0654` 0 once the timer is out")
        let final = try XCTUnwrap(w.player.shadowDoubleSprite)
        XCTAssertEqual(w.active.sprite(id: final)?.killCount, 0, "removed on the next row 11")
        frame(w, solver, lights: &lights)
        XCTAssertNil(w.player.shadowDoubleSprite)
        XCTAssertEqual(w.active.sprite(id: final)?.killCount, 1)
        frame(w, solver, lights: &lights)
        XCTAssertNil(w.player.shadowDoubleSprite, "no new double")
    }

    // MARK: - the Pentashield

    /// The 1338 pickup's orb table (`HitPlayerSprite.sphere`, M l. 49085–49112), as PK built it.
    private func pentashield(_ w: SpriteWorld) throws {
        var lights = LightTable()
        var s = SpriteSlot(type: 0x53a, x: 400, y: 100, recordIndex: -1)
        _ = try BonusSprite.setup(&s, x: 400, y: 100, level: w.level, records: w.records, effects: 1,
                                  lightCount: lights.count, counting: false, rng: &w.rng) { f, h, v, c in
            lights.add(face: f, x: Int16(h), y: Int16(v), vx: 0, vy: 0, accelY: 0, colour: c)
        }
        let id = w.active.insert(s)
        w.active.update(id: id) { $0.counterA6 = 0; $0.pickupDelay = 0 }
        HitPlayerSprite.hit(w, player: w.playerID!, other: id, keys: [], lights: &lights, effects: 1)
        w.active.update(id: id) { $0.dead = true }
    }

    private func orbs(_ w: SpriteWorld) -> [SpriteSlot] {
        w.player.orbs.compactMap { $0.sprite.flatMap { w.active.sprite(id: $0) } }
    }

    /// `.UpdatePentSprites`' placement (M l. 44171–44180): offset = radius · table[angle >> 8] divided by 256 toward
    /// zero (`srawi; addze`), as a short, + (centre − 10)·256; the cos table for x (`_DAT_100a021c`), sin for y (`_DAT_100a00e0`).
    private func place(_ angle: Int32, radius: Int32, centre: SpriteSlot.Point) -> (x256: Int32, y256: Int32) {
        let a = Int(angle >> 8)
        let ox = Int32(Int16(truncatingIfNeeded: (radius &* RadialTables.cosT[a]) / 256))
        let oy = Int32(Int16(truncatingIfNeeded: (radius &* RadialTables.sinT[a]) / 256))
        return (ox + Int32(centre.x - 10) * 0x100, oy + Int32(centre.y - 10) * 0x100)
    }

    func testPentashieldOrbs() throws {
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        var lights = LightTable()
        try pentashield(w)
        XCTAssertEqual(w.player.pentashieldCount, 5)
        XCTAssertTrue(orbs(w).isEmpty, "the pickup makes no sprite")
        // Frame 1: at the end of the player's Handle (M l. 46648) each orb in use without a sprite gets
        // `MTNewSprite(0x5001, 0, 0, +0x80 + 1, 0x1ff, .SetupPlayerShotSprite)` (id 0x50, power 1), `+0x164 = −10`;
        // angle += speed 0xa00. Layer 11 sorts between the player and the held item (the saved next), so the orbs'
        // own Handle first runs on frame 2.
        frame(w, solver, lights: &lights)
        var o = orbs(w)
        XCTAssertEqual(o.count, 5)
        XCTAssertTrue(o.allSatisfy { $0.type == 0x50 && $0.power == 1 && $0.layer == 11 && $0.recordIndex == 0x1ff })
        XCTAssertTrue(o.allSatisfy { $0.handler == .playerShot && $0.hp == 300 && $0.stackX == 3 && !$0.hasTileHit })
        XCTAssertEqual(o.map(\.stepY), [Int32](repeating: -10, count: 5))
        XCTAssertEqual(w.player.orbs.prefix(5).map(\.angle), (0..<5).map { Int32($0) * 72 * 0x100 + 0xa00 })
        let c = player(w).centre
        for (k, orb) in o.enumerated() {
            let at = place(w.player.orbs[k].angle, radius: 0x30, centre: c)
            XCTAssertEqual([orb.x256, orb.y256], [at.x256, at.y256], "orb \(k)")
            XCTAssertEqual([orb.x, orb.y], [Int(at.x256 >> 8), Int(at.y256 >> 8)])
        }
        // Frame 2: placed again (angle + 0xa00) around this frame's centre, then their first Handle (age −1 → 0: no
        // id arm yet, M l. 50483). Frame 3: age 1 — `+0x164` −10 → −9 (tint 0xb0002), face 1118 (M l. 50652–50676).
        frame(w, solver, lights: &lights)
        o = orbs(w)
        XCTAssertEqual(o.map(\.stepY), [Int32](repeating: -10, count: 5))
        XCTAssertEqual(w.player.orbs.prefix(5).map(\.angle), (0..<5).map { Int32($0) * 72 * 0x100 + 0x1400 })
        for (k, orb) in o.enumerated() {
            let at = place(w.player.orbs[k].angle, radius: 0x30, centre: player(w).centre)
            XCTAssertEqual([orb.x256, orb.y256], [at.x256, at.y256], "orb \(k)")
        }
        frame(w, solver, lights: &lights)
        o = orbs(w)
        XCTAssertEqual(o.map(\.stepY), [Int32](repeating: -9, count: 5))
        XCTAssertEqual(o.map(\.mode), [UInt32](repeating: 0xb0002, count: 5))
        XCTAssertEqual(o.map { $0.face?.pict }, [Int16?](repeating: 0x45e, count: 5))
        for _ in 0..<9 { frame(w, solver, lights: &lights) }
        XCTAssertEqual(orbs(w).map(\.stepY), [Int32](repeating: 0, count: 5), "the spawn flash counted out")
        // The angle wraps at 0x16800 (M l. 44164–44166): orb 4 from 288° + 12·10°.
        XCTAssertEqual(w.player.orbs[4].angle, 288 * 0x100 + 12 * 0xa00 - 0x16800)

        // A second sphere: 5 + 5 capped at 8; the five orb sprites killed (`+0xe9`) and dropped; eight new ones at
        // 45° spacing on the next frame.
        let old = orbs(w).map(\.id)
        try pentashield(w)
        XCTAssertEqual(w.player.pentashieldCount, 8, "not 10")
        XCTAssertEqual(old.compactMap { w.active.sprite(id: $0)?.killCount }, [1, 1, 1, 1, 1])
        frame(w, solver, lights: &lights)
        o = orbs(w)
        XCTAssertEqual(o.count, 8)
        XCTAssertTrue(Set(o.map(\.id)).isDisjoint(with: old))
        XCTAssertEqual(w.player.orbs.map(\.angle), (0..<8).map { Int32($0) * 45 * 0x100 + 0xa00 })
        XCTAssertEqual(w.player.pentashieldCount, 8)
    }

    func testOrbHitsAndPops() throws {
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        var lights = LightTable()
        try pentashield(w)
        for _ in 0..<3 { frame(w, solver, lights: &lights) }             // made; first Handle; age 1 (face 1118)
        let orb = try XCTUnwrap(w.player.orbs[0].sprite)
        // A crate (a Box, no one-way top): the shot side's Box arm → `.KillPlayerShot(s, 1, 1)` (M l. 51041–51052);
        // the orb case (M l. 51118–51135): `+0x168` − 1; ≥ 1 → snd 423 (`*_DAT_100a01e4`) at the centre, the orb lives.
        var crate = SpriteSlot(type: 0xc12, x: 0, y: 0)
        crate.handler = .box
        let crateID = w.active.insert(crate)
        func strike() -> [PlayerCue] {
            w.player.cues = []
            PlayerShotHits.hit(w, shot: orb, other: crateID, effects: 2, lights: &lights)
            return w.player.cues
        }
        func at(_ id: Int) -> SpriteSlot.Point { w.active.sprite(id: id)!.centre }
        var r = w.rng
        XCTAssertEqual(strike(), [PlayerCue(call: .threeDRand, snd: 423, priority: 1, volume: 0x100, position: at(orb),
                                            rate: r.soundRate())])
        XCTAssertEqual(w.active.sprite(id: orb).map { [Int($0.stackX), Int($0.killCount)] }, [2, 0])
        XCTAssertEqual(strike().map(\.snd), [423])
        XCTAssertEqual(w.active.sprite(id: orb)?.stackX, 1)
        // At < 1: snd 424 (`*_DAT_100a01e0`), `.ExplodeFaceIntoParticles(+0xc0, …, 0x50, 0x65)`, `+0xe9 = 1`.
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let orbFace = ParticleFace(frame: [0, 0, 1, 3], bounds: [0, 0, 1, 3],
                                   tokens: tok(1, 8) + tok(2, 3) + [10, 11, 12, 0] + tok(0, 0))
        w.particleFaces = ParticleFaces(sprite: { f in f.pict == 0x45e ? orbFace : nil })
        let particles0 = w.particles.counters.count
        XCTAssertEqual(strike().map(\.snd), [424])
        w.particleFaces = ParticleFaces()
        XCTAssertEqual(w.particles.counters.count - particles0, 2, "the burst")
        XCTAssertEqual(w.active.sprite(id: orb).map { [Int($0.stackX), Int($0.killCount)] }, [0, 1])
        // The next `.UpdatePentSprites` (M l. 44185–44189): a killed sprite → the slot out of use, `053c` − 1; the
        // other four orbit on.
        frame(w, solver, lights: &lights)
        XCTAssertFalse(w.player.orbs[0].active)
        XCTAssertNil(w.player.orbs[0].sprite)
        XCTAssertEqual(w.player.pentashieldCount, 4)
        XCTAssertEqual(orbs(w).count, 4)
        frame(w, solver, lights: &lights)
        XCTAssertNil(w.player.orbs[0].sprite, "no new sprite for a slot out of use")

        // Orbs open no containers: a rock pile 0x517 (`+0xb0` ≠ 0) — the Bonus side's container arm wants a shot that
        // is not 0x50 (M l. 53473–53475), the shot side's arm likewise (M l. 51034); a Fireball opens it.
        let o2 = try XCTUnwrap(w.player.orbs[1].sprite)
        var rock = SpriteSlot(type: 0x517, x: 0, y: 0)
        rock.handler = .bonus
        rock.pickupDelay = 1
        let rockID = w.active.insert(rock)
        let score = w.globals.score
        FerazelSession.hitCallback(w, rockID, o2, lights: &lights)
        FerazelSession.hitCallback(w, o2, rockID, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: rockID)?.killCount, 0)
        XCTAssertEqual(w.active.sprite(id: o2).map { [Int($0.stackX), Int($0.killCount)] }, [3, 0])
        XCTAssertEqual(w.globals.score, score)
        let fireball = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0001, x: 0, y: 0))
        FerazelSession.hitCallback(w, rockID, fireball, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: rockID)?.killCount, 1, "a spell's shot opens it")
        XCTAssertEqual(w.globals.score, score + 0x96)
    }
}

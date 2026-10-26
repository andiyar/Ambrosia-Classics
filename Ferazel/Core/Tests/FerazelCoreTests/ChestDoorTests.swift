import XCTest
import HectorResources
@testable import FerazelCore

/// BX2 (docs/plans/2026-10-24-ferazel-phase4.md): chests 0x51c, doors 0xb5e / 0xb5f and their keys, the thought
/// balloons — the Box arm of `.HitPlayerSprite` (M l. 49211–49277), `.HandleBoxSprite`'s chest arm (M l. 60101–60187)
/// and door arm (M l. 60803–60868), `.CreateBalloonSprite` / `.DestructBalloonSprite` (M l. 59921–59982). The levels'
/// own records on a synthetic grid (the chests and doors have gravity 0: no tile is read); every expected draw is
/// re-derived from a copy of the stream at its call site.
final class ChestDoorTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level `level` with a 16×16 empty grid and the player spawned at (100, 200).
    private func world(level: Int16 = 1) throws -> (SpriteWorld, Int) {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: level))
        let empty = [UInt16](repeating: 0, count: 16 * 16)
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: empty), bg: TileMap(width: 16, height: 16, cells: empty),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        let pid = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
        w.playerID = pid
        return (w, pid)
    }

    /// The record's Setup (`SetupFaces` → `BoxSprite.setup`) inserted with `.BoxClean`'s centre.
    private func add(_ w: SpriteWorld, record i: Int) throws -> Int {
        var s = try SetupFaces.setup(w.records[i], context: SetupFaces.Context(level: w.level, playerX: 0)).slot
        let r = s.hotRect
        s.centre = SpriteSlot.Point(x: s.x + r.left + ((r.right - r.left) >> 1), y: s.y + r.top + ((r.bottom - r.top) >> 1))
        return w.active.insert(s)
    }

    private func setRecord(_ w: SpriteWorld, _ i: Int, p1: Int16? = nil, p2: Int16? = nil, p3: Int16? = nil) {
        let q = w.records[i]
        w.records[i] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: q.type, p1: p1 ?? q.p1,
                                 p2: p2 ?? q.p2, p3: p3 ?? q.p3, p4: q.p4, y: q.y, x: q.x)
    }

    /// One contact of the player pass (`.HitPlayerSprite(player, box)`) with the player's vx; the cues it made.
    @discardableResult
    private func touch(_ w: SpriteWorld, _ pid: Int, _ box: Int, vx: Int32 = 0) -> [PlayerCue] {
        w.active.update(id: pid) { $0.vx = vx }
        w.player.cues = []
        HitPlayerSprite.hit(w, player: pid, other: box)
        return w.player.cues
    }

    private func frame(_ w: SpriteWorld, _ id: Int, _ lights: inout LightTable) {
        BoxSprite.handle(world: w, id: id, solver: TileSolver(world: w), lights: &lights, effects: 1)
    }

    private func reg(_ snd: Int16) -> PlayerCue { PlayerCue(call: .reg, snd: snd, priority: 1, volume: 0x100) }

    private func live(_ w: SpriteWorld, type t: Int16) -> [SpriteSlot] {
        w.active.sprites.filter { $0.type == t && !$0.dead }
    }

    /// The draws of a chest drop on a copy of the stream: the Bonus Setup's (`own`), then `vy = −2000 − R(1000)`,
    /// `vx = R(800) − 400` (M l. 60165–60168 — no p3 test, unlike `.KillCrate`).
    private func dropDraws(_ r: inout FastRand, setup own: (inout FastRand) -> Void) -> (vx: Int32, vy: Int32) {
        own(&r)
        let vy = -2000 - Int32(r.next(1000))
        let vx = Int32(r.next(800)) - 400
        return (vx, vy)
    }

    // MARK: -

    func testLevel1KeyChain() throws {
        let (w, pid) = try world()
        var lights = LightTable()
        // Level 1: chest 23 (3201 Steel Key × 1, unlocked) → locked chest 38 (key 1; 3202 Gold Key × 1) → door 55
        // (2910, key 2).
        XCTAssertEqual([w.records[23].type, w.records[23].p1, w.records[23].p2, w.records[23].p3], [1308, 0, 3201, 1])
        XCTAssertEqual([w.records[38].type, w.records[38].p1, w.records[38].p2, w.records[38].p3], [1308, 1, 3202, 1])
        XCTAssertEqual([w.records[55].type, w.records[55].p1, w.records[55].p4], [2910, 2, 0])
        let layer = try XCTUnwrap(w.active.sprite(id: pid)).layer

        func openChest(_ rec: Int, item: Int16) throws -> SpriteSlot {
            let chest = try add(w, record: rec)
            XCTAssertEqual(w.active.sprite(id: chest)?.counterA6, 4)                  // the Setup's `+0xa6 = 4`
            // Contact while `+0x46 == 0`, unlocked or the key held, p3 > 0 → snd 439 (`_DAT_100a03a0`), `+0x46 = 1`.
            XCTAssertEqual(touch(w, pid, chest), [reg(439)])
            XCTAssertEqual(w.active.sprite(id: chest)?.phase, 1)
            // A second contact (`+0x46 ≠ 0`): nothing more.
            XCTAssertEqual(touch(w, pid, chest), [])
            // `+0xa6` 4 → 0 over four Handles; the fourth makes the drop, `+0xa6 = 4`, record p3 − 1.
            for n in 1...3 {
                frame(w, chest, &lights)
                XCTAssertEqual(w.active.sprite(id: chest)?.counterA6, Int16(4 - n))
                XCTAssertTrue(live(w, type: item).isEmpty)
            }
            var r = w.rng
            let v = dropDraws(&r) { _ = $0.next(0x10); _ = $0.next(0x3c) }           // the item arm + tail (M l. 52665ff)
            let c = try XCTUnwrap(w.active.sprite(id: chest))
            frame(w, chest, &lights)
            XCTAssertEqual(w.rng.seed, r.seed)
            XCTAssertEqual(w.active.sprite(id: chest)?.counterA6, 4)
            XCTAssertEqual(w.records[rec].p3, 0)
            let drops = live(w, type: item)
            XCTAssertEqual(drops.count, 1)
            let d = try XCTUnwrap(drops.first)
            XCTAssertEqual(d.handler, .bonus)
            XCTAssertEqual(d.recordIndex, -1)
            // `MTNewSprite(p2, x + 0x10, y + 0xd, …)` re-centred by the rect (left 4, top 4, right 0x1c, bottom 0x12):
            // x − (4 + 0x1c) >> 1, y − (4 + 0x12) >> 1.
            XCTAssertEqual(d.hotRect, IdleSprites.Rect(top: 4, left: 4, bottom: 0x12, right: 0x1c))
            XCTAssertEqual([d.x, d.y, Int(d.x256 >> 8), Int(d.y256 >> 8)],
                           [c.x + 0x10 - 0x10, c.y + 0xd - 0xb, c.x + 0x10 - 0x10, c.y + 0xd - 0xb])
            XCTAssertEqual(d.layer, layer + 1)                                       // `.MTChangeSpriteLayer(player + 1)`
            XCTAssertEqual([d.vx, d.vy], [v.vx, v.vy])
            XCTAssertEqual(d.gravity, 200)                                           // the item's own (not 0: kept)
            XCTAssertEqual(d.pickupDelay, 0xc)
            XCTAssertNotEqual(d.light, -1)                                           // p3 1 (≤ 2): the light kept
            // p3 0: four more Handles drop nothing.
            for _ in 0..<4 { frame(w, chest, &lights) }
            XCTAssertEqual(live(w, type: item).count, 1)
            return d
        }

        // Chest 23: the Steel Key 3201 (item 1).
        _ = try openChest(23, item: 3201)
        _ = w.globals.addItem(1, count: 1)                                           // picked up
        // The locked chest 38 (key 1) with the Steel Key: `.RemoveItem(1)` (its `.UpdateItemStat`), record p1 kept.
        let draws0 = w.player.passDraws.count
        _ = try openChest(38, item: 3202)
        XCTAssertFalse(w.globals.hasItem(1))
        XCTAssertEqual(w.records[38].p1, 1)
        XCTAssertEqual(w.player.passDraws.count, draws0 + 1)
        _ = w.globals.addItem(2, count: 1)
        // Door 55 (key 2) with the Gold Key, moving right: `.RemoveItem(2)`, record p1 = 0, snd 437 (`_DAT_100a03a8`),
        // `+0x46 = 1`.
        let door = try add(w, record: 55)
        XCTAssertEqual(touch(w, pid, door, vx: 0x100), [reg(437)])
        XCTAssertFalse(w.globals.hasItem(2))
        XCTAssertEqual(w.records[55].p1, 0)
        XCTAssertEqual(w.active.sprite(id: door)?.phase, 1)
        // The Handle: face `|+0x46| >> 1`, then `+0x46` + 1; at 7 the rect zeroed; at 11 → 10 and record p4 = 1.
        var faces: [Int] = []
        let zero = IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
        for n in 1...11 {
            frame(w, door, &lights)
            let s = try XCTUnwrap(w.active.sprite(id: door))
            faces.append(s.face?.index ?? -1)
            XCTAssertEqual(s.face?.pict, 0xb5e)
            XCTAssertEqual(s.phase, n < 10 ? Int16(n + 1) : 10, "Handle \(n)")
            XCTAssertEqual(s.hotRect == zero, n >= 6, "Handle \(n)")
            XCTAssertEqual(w.records[55].p4, n >= 10 ? 1 : 0, "Handle \(n)")
        }
        XCTAssertEqual(faces, [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5])
        XCTAssertEqual(w.records[55].p1, 0)
    }

    func testDoorNeedsKeyAndDirection() throws {
        let (w, pid) = try world()
        var lights = LightTable()
        let door = try add(w, record: 55)                                            // 2910, key 2
        // No key (`.HaveItem(2)` false): nothing — no sound, p1 kept, closed.
        XCTAssertEqual(touch(w, pid, door, vx: 0x100), [])
        XCTAssertEqual(w.records[55].p1, 2)
        XCTAssertEqual(w.active.sprite(id: door)?.phase, 0)
        // A negative p1 needs the same key (`|p1|`).
        setRecord(w, 55, p1: -2)
        XCTAssertEqual(touch(w, pid, door, vx: 0x100), [])
        setRecord(w, 55, p1: 2)
        // With the key, moving left into a 2910: unlocked (key spent, p1 0, snd 437) but not opened.
        _ = w.globals.addItem(2, count: 1)
        XCTAssertEqual(touch(w, pid, door, vx: -0x100), [reg(437)])
        XCTAssertEqual(w.records[55].p1, 0)
        XCTAssertFalse(w.globals.hasItem(2))
        XCTAssertEqual(w.active.sprite(id: door)?.phase, 0)
        // Standing still (vx 0): snd 438 (`_DAT_100a03a4`, unlocked), still closed.
        XCTAssertEqual(touch(w, pid, door, vx: 0), [reg(438)])
        XCTAssertEqual(w.active.sprite(id: door)?.phase, 0)
        // Moving right: snd 438, opens.
        XCTAssertEqual(touch(w, pid, door, vx: 0x100), [reg(438)])
        XCTAssertEqual(w.active.sprite(id: door)?.phase, 1)
        // While opening (`+0x46 ≠ 0`) a contact still plays 438 and leaves `+0x46` alone (M l. 49233–49242).
        frame(w, door, &lights)
        XCTAssertEqual(touch(w, pid, door, vx: 0x100), [reg(438)])
        XCTAssertEqual(w.active.sprite(id: door)?.phase, 2)

        // Level 2 door 212: a 2911 (key 1) opens only for a player moving left.
        let (w2, pid2) = try world(level: 2)
        XCTAssertEqual([w2.records[212].type, w2.records[212].p1], [2911, 1])
        let d2 = try add(w2, record: 212)
        _ = w2.globals.addItem(1, count: 1)
        XCTAssertEqual(touch(w2, pid2, d2, vx: 0x100), [reg(437)])
        XCTAssertEqual(w2.active.sprite(id: d2)?.phase, 0)
        XCTAssertEqual(touch(w2, pid2, d2, vx: -0x100), [reg(438)])
        XCTAssertEqual(w2.active.sprite(id: d2)?.phase, 1)

        // The 2907 timer 0xb5b (placed on no level 1–4: record 72 retyped, p1 5) in a session: a contact with
        // `+0xa6 == 0` → `+0xa6 = 100`, `.STPlay3DSoundPitched(442, 1, 0x100, player centre, 44000)` (no draw) and
        // `iRam100a5110 = 5·30 − 1`, seen at the next iteration after its decrement (149 − 1); `+0xa6 ≠ 0`: nothing.
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1, seed: 1)
        let sw = s.world
        let q = sw.records[72]
        sw.records[72] = Placement(index: q.index, flag: q.flag, byte1: q.byte1, type: 0xb5b, p1: 5, p2: 0, p3: 0,
                                   p4: 0, y: q.y, x: q.x)
        var slot = SpriteSlot(type: 0xb5b, x: Int(q.x), y: Int(q.y), recordIndex: 72)
        BoxSprite.setup(&slot, record: sw.records[72], level: sw.level)
        XCTAssertEqual(slot.counterA6, 3)                                            // the head's `+0xa6 = 3`
        slot.counterA6 = 0
        let timer = sw.active.insert(slot)
        let sp = try XCTUnwrap(sw.playerID)
        let seed = sw.rng.seed
        let cues = touch(sw, sp, timer)
        XCTAssertEqual(sw.rng.seed, seed)
        XCTAssertEqual(cues, [PlayerCue(call: .threeDPitched, snd: 442, priority: 1, volume: 0x100,
                                        position: sw.active.sprite(id: sp)?.centre, rate: 44000)])
        XCTAssertEqual(sw.active.sprite(id: timer)?.counterA6, 100)
        XCTAssertEqual(sw.player.countdownStore, 5 * 30 - 1)
        XCTAssertEqual(s.countdown, -0x1e)                                           // not yet: the next iteration's
        XCTAssertEqual(touch(sw, sp, timer), [])                                     // `+0xa6` 100: no second start
        sw.player.cues = []
        _ = s.step(keys: KeyState())
        XCTAssertEqual(s.countdown, 5 * 30 - 1 - 1)
        XCTAssertNil(sw.player.countdownStore)
    }

    func testChestDropsEveryFourFrames() throws {
        let (w, pid) = try world()
        var lights = LightTable()
        // Level 1 chest 72: 1302 (0x516, a coin) × 20.
        XCTAssertEqual([w.records[72].p1, w.records[72].p2, w.records[72].p3], [0, 1302, 20])
        let chest = try add(w, record: 72)
        XCTAssertEqual(w.active.sprite(id: chest)?.face, FaceRef(pict: 0x51c, index: 0, set: .encoded))
        XCTAssertEqual(touch(w, pid, chest), [reg(439)])
        var dropFrames: [Int] = []
        var lids: [Int] = []
        var r = w.rng
        var want: [(vx: Int32, vy: Int32)] = []
        for _ in 0..<20 {
            // The coin arm (M l. 52571–52581: R(9), R(6), R(3)) and the tail's R(60).
            want.append(dropDraws(&r) { _ = $0.next(9); _ = $0.next(6); _ = $0.next(3); _ = $0.next(0x3c) })
        }
        for n in 1...84 {
            let before = live(w, type: 0x516).count
            frame(w, chest, &lights)
            if live(w, type: 0x516).count != before { dropFrames.append(n) }
            if n <= 12 { lids.append(w.active.sprite(id: chest)?.face?.index ?? -1) }
        }
        XCTAssertEqual(w.rng.seed, r.seed)
        // One coin each time `+0xa6` (4 at Setup, 4 after each drop) reaches 0.
        XCTAssertEqual(dropFrames, Array(stride(from: 4, through: 80, by: 4)))
        XCTAssertEqual(w.records[72].p3, 0)
        // The lid: `+0x46 / 3` before the increment, `+0x46` 1 → 11 and held there.
        XCTAssertEqual(lids, [0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3])
        XCTAssertEqual(w.active.sprite(id: chest)?.phase, 11)
        let coins = live(w, type: 0x516)
        XCTAssertEqual(coins.map(\.vx), want.map(\.vx))
        XCTAssertEqual(coins.map(\.vy), want.map(\.vy))
        // A coin's gravity 0x151 is the Bonus head's (not 0): kept.
        XCTAssertTrue(coins.allSatisfy { $0.gravity == 0x151 && $0.pickupDelay == 0xc })
        // The emptied chest after a reload (record p3 0, `+0x46` 0): the open face frame 3, and a contact does nothing.
        let again = try add(w, record: 72)
        frame(w, again, &lights)
        XCTAssertEqual(w.active.sprite(id: again)?.face, FaceRef(pict: 0x51c, index: 3, set: .encoded))
        XCTAssertEqual(touch(w, pid, again), [])
        XCTAssertEqual(w.active.sprite(id: again)?.phase, 0)
    }

    func testChestAlwaysBonusSetup() throws {
        let (w, pid) = try world()
        var lights = LightTable()
        let layer = try XCTUnwrap(w.active.sprite(id: pid)).layer
        // A chest with p2 1730 (an enemy type): the drop is still `MTNewSprite(p2, …, .SetupBonusSprite)` — no
        // `.GenerateSprite`, so it is a Bonus-class sprite of type 1730.
        setRecord(w, 72, p2: 1730, p3: 1)
        let chest = try add(w, record: 72)
        touch(w, pid, chest)
        for _ in 0..<3 { frame(w, chest, &lights) }
        // 1730 matches no Bonus arm: the default arm's item branch as written (M l. 52665–52710) — `FastRand(0x10)`, the
        // light, then the tail's `FastRand(0x3c)`; then the chest's R(1000), R(800).
        var r = w.rng
        let v = dropDraws(&r) { _ = $0.next(0x10); _ = $0.next(0x3c) }
        frame(w, chest, &lights)
        XCTAssertEqual(w.rng.seed, r.seed)
        let e = live(w, type: 1730)
        XCTAssertEqual(e.count, 1)
        XCTAssertEqual(e.first?.handler, .bonus)
        XCTAssertEqual(e.first?.layer, layer + 1)
        XCTAssertEqual(e.first?.pickupDelay, 0xc)
        XCTAssertEqual(e.first?.gravity, 200)                                        // the Bonus default arm's
        XCTAssertEqual([e.first?.vx, e.first?.vy], [v.vx, v.vy])
        XCTAssertNotEqual(e.first?.light, -1)                                        // the item arm's light (p3 1)
        XCTAssertNil(e.first?.face)                                                  // read outside `_DAT_100a08a0`
        XCTAssertEqual(e.first?.hotRect, IdleSprites.Rect(top: 4, left: 4, bottom: 0x12, right: 0x1c))   // < 0xc84: −6
        XCTAssertEqual(e.first?.friction, 6)
        XCTAssertEqual(lights.count, 1)
        XCTAssertEqual(w.records[72].p3, 0)
        // p3 > 2 at a drop: the drop's light removed (M l. 60161–60164); p3 2 and 1 keep theirs.
        setRecord(w, 23, p3: 3)
        let c2 = try add(w, record: 23)
        touch(w, pid, c2)
        var lightsAt: [Int16] = []
        for _ in 0..<12 {
            let before = live(w, type: 3201).count
            frame(w, c2, &lights)
            if let d = live(w, type: 3201).last, live(w, type: 3201).count != before { lightsAt.append(d.light) }
        }
        XCTAssertEqual(lightsAt.count, 3)
        XCTAssertEqual(lightsAt.first, -1)
        XCTAssertTrue(lightsAt.dropFirst().allSatisfy { $0 != -1 })
        // The 1730's light, then three key lights added and the first removed.
        XCTAssertEqual(lights.count, 3)
    }

    func testBalloonNearLockedChest() throws {
        let (w, pid) = try world()
        var lights = LightTable()
        _ = pid
        let chest = try add(w, record: 38)                                           // locked, key 1
        let c = try XCTUnwrap(w.active.sprite(id: chest))
        func near(_ dx: Int, _ dy: Int) {
            w.player.centreX = Int16(c.centre.x + dx)
            w.player.centreY = Int16(c.centre.y + dy)
        }
        // Within 0x4b px on both axes (|d| < 0x4b): a 0xcb2 balloon at (cx − 0x36, cy − 0x2d), layer 100, face PICT
        // 3250; inside it 0xcb2 + 1 at (+3, +3), layer 0x65, the key's item face (`_DAT_100a08a0[1]` = PICT 3201).
        near(0x4a, -0x4a)
        let seed = w.rng.seed
        frame(w, chest, &lights)
        XCTAssertEqual(w.rng.seed, seed)                                             // ids ≥ 3200 skip the package
        let b = try XCTUnwrap(live(w, type: 0xcb2).first)
        let inner = try XCTUnwrap(live(w, type: 0xcb3).first)
        XCTAssertEqual([b.x, b.y, Int(b.layer)], [c.centre.x - 0x36, c.centre.y - 0x2d, 100])
        XCTAssertEqual(b.face, FaceRef(pict: 0xcb2, index: 0, set: .encoded))
        XCTAssertEqual(b.handler, .effect)
        XCTAssertEqual([inner.x, inner.y, Int(inner.layer)], [c.centre.x - 0x36 + 3, c.centre.y - 0x2d + 3, 0x65])
        XCTAssertEqual(inner.face, FaceRef(pict: 0xc81, index: 0, set: .encoded))
        let bID = try XCTUnwrap(w.active.sprite(id: chest)?.siblings.first)
        XCTAssertEqual(w.active.sprite(id: bID)?.siblings.first.flatMap { w.active.sprite(id: $0) }?.type, 0xcb3)
        // Still in range: no second balloon.
        frame(w, chest, &lights)
        XCTAssertEqual(live(w, type: 0xcb2).count, 1)
        // At 0x4b px: `.DestructBalloonSprite` — both killed, the links cleared.
        near(0x4b, 0)
        frame(w, chest, &lights)
        XCTAssertTrue(live(w, type: 0xcb2).isEmpty)
        XCTAssertTrue(live(w, type: 0xcb3).isEmpty)
        XCTAssertNil(w.active.sprite(id: chest)?.siblings.first)
        near(0, 0x4b)
        frame(w, chest, &lights)
        XCTAssertTrue(live(w, type: 0xcb2).isEmpty)
        // An unlocked chest (23): none.
        let open = try add(w, record: 23)
        let o = try XCTUnwrap(w.active.sprite(id: open))
        w.player.centreX = Int16(o.centre.x)
        w.player.centreY = Int16(o.centre.y)
        frame(w, open, &lights)
        XCTAssertTrue(live(w, type: 0xcb2).isEmpty)
        // The locked door 55 (key 2): the balloon at (cx − 0x36, cy − 0x3c) with PICT 3202; gone once it opens.
        let door = try add(w, record: 55)
        let d = try XCTUnwrap(w.active.sprite(id: door))
        w.player.centreX = Int16(d.centre.x)
        w.player.centreY = Int16(d.centre.y)
        frame(w, door, &lights)
        let db = try XCTUnwrap(live(w, type: 0xcb2).first)
        XCTAssertEqual([db.x, db.y], [d.centre.x - 0x36, d.centre.y - 0x3c])
        XCTAssertEqual(live(w, type: 0xcb4).first?.face, FaceRef(pict: 0xc82, index: 0, set: .encoded))
        w.active.update(id: door) { $0.phase = 1 }
        frame(w, door, &lights)
        XCTAssertTrue(live(w, type: 0xcb2).isEmpty)
        XCTAssertTrue(live(w, type: 0xcb4).isEmpty)
        // A mirrored door (2911, level 2 rec 212, key 1): the balloon at cx + 6, its icon at + 0xd, both mirrored
        // only on the balloon (`+0x17e`).
        let (w2, _) = try world(level: 2)
        let m = try add(w2, record: 212)
        let ms = try XCTUnwrap(w2.active.sprite(id: m))
        XCTAssertTrue(ms.mirrored)
        w2.player.centreX = Int16(ms.centre.x)
        w2.player.centreY = Int16(ms.centre.y)
        frame(w2, m, &lights)
        let mb = try XCTUnwrap(live(w2, type: 0xcb2).first)
        let mi = try XCTUnwrap(live(w2, type: 0xcb3).first)
        XCTAssertEqual([mb.x, mb.y], [ms.centre.x + 6, ms.centre.y - 0x3c])
        XCTAssertEqual([mi.x, mi.y], [ms.centre.x + 6 + 0xd, ms.centre.y - 0x3c + 3])
        XCTAssertEqual([mb.mirrored, mi.mirrored], [true, false])
    }

    func testOpenDoorPersists() throws {
        let (w, pid) = try world()
        var lights = LightTable()
        _ = w.globals.addItem(2, count: 1)
        let door = try add(w, record: 55)
        touch(w, pid, door, vx: 0x100)
        for _ in 0..<10 { frame(w, door, &lights) }
        XCTAssertEqual([w.records[55].p1, w.records[55].p4], [0, 1])
        // A save point here (`.SavePointSave`: the live records and G), then the resume (`.SetupLevel` copies the
        // snapshot over the records, M l. 2405–2409).
        var block = SaveBlock()
        var g = w.globals
        block.savePointSave(level: 1, x: 100, y: 200, stamp: 0, date: 0, globals: &g, records: w.records)
        let (w2, pid2) = try world()
        w2.records = block.restoreSnapshot(level: 1)
        w2.globals = block.globals
        XCTAssertEqual([w2.records[55].p1, w2.records[55].p4], [0, 1])
        let d2 = try add(w2, record: 55)
        // The first Handle: p4 = 1 → the rect zeroed and `+0x46 = 10` (the face drawn this frame is still cell 0).
        frame(w2, d2, &lights)
        var s = try XCTUnwrap(w2.active.sprite(id: d2))
        XCTAssertEqual(s.phase, 10)
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0))
        XCTAssertEqual(s.face?.index, 0)
        frame(w2, d2, &lights)
        s = try XCTUnwrap(w2.active.sprite(id: d2))
        XCTAssertEqual([Int(s.phase), s.face?.index ?? -1], [10, 5])
        // The key stays spent; the unlocked door needs none (snd 438) and no balloon shows.
        XCTAssertFalse(w2.globals.hasItem(2))
        XCTAssertEqual(touch(w2, pid2, d2, vx: 0x100), [reg(438)])
        XCTAssertTrue(live(w2, type: 0xcb2).isEmpty)
    }
}

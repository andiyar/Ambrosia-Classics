import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-CH1 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-CH1`; docs/ferazel/phase6-boss-contracts.md
/// §3.1–§3.3, §3.6, §3.8, §3.10): the Goblin Chief's class — `.InitChiefSprite`'s records (M l. 75008–75028),
/// `.SetupChiefSprite` (M l. 75031–75115), `.HandleChiefSprite` (M l. 75162–75441), `.GoblinChiefRandomCry` (M l.
/// 75118–75159), `.HitChiefTileSprite` (M l. 75535–75567). Every test opens level 18 ("Goblin Chief") through the level
/// fixture (6A-FX) headless with nothing left out — the Chief is record 1 (type 1910, x 897, y 410, p4 1); level 18 is
/// not in `BuiltLevels` yet (6A-L18) and the fixture never consults it. The Handle is driven through the level runner
/// or called alone on the run's world; every expected draw is re-derived from a copy of the stream (`FastRand`), never
/// from the port's generator. A missing data file is a FAILURE, never a skip.
final class ChiefTests: XCTestCase {
    /// Level 18's leave-out list: empty (count asserted 0).
    static let level18: [LevelFixture.LeaveOut] = []

    /// The next tick's `now` for the run `open` made.
    private var now: UInt32 = 0

    private var left: Int { Int(FerazelPrefs().keys[0]) }

    /// Level 18's fixture through the level runner, ticked until its session exists (before its first iteration).
    private func open(seed: Int32 = 1) throws -> (run: LevelRun, session: FerazelSession) {
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 18)
        XCTAssertEqual(try LevelFixture.leftOut(real, Self.level18).count, 0, "nothing left out")
        let run = try LevelFixture.open(level: 18, leaveOut: Self.level18, seed: seed)
        now = 0
        while run.session == nil && now < 4000 {
            _ = try run.tick(now: now, input: FrontInput())
            now &+= 1
        }
        return (run, try XCTUnwrap(run.session, "level 18 opened within 4000 ticks"))
    }

    /// Ticks until the run's iteration count has grown by one.
    private func iterate(_ run: LevelRun, keys: [Int] = []) throws {
        let before = run.iterations
        for _ in 0..<400 {
            _ = try run.tick(now: now, input: FrontInput(keys: KeyState(pressed: keys)))
            now &+= 1
            if run.iterations > before { return }
        }
        XCTFail("no iteration within 400 ticks")
    }

    /// The active Chief (nil while he is idle).
    private func chief(_ w: SpriteWorld) -> SpriteSlot? { w.active.sprites.first { $0.handler == .chief } }

    private func slot(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }

    /// One Chief Handle call (the session's dispatch row, without the rest of the frame).
    private func handle(_ w: SpriteWorld, _ id: Int) {
        Chief.handle(world: w, id: id, solver: TileSolver(world: w))
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The first seed in 1…2,000,000 whose stream makes `pick` true; none → a failure, not a hang.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        for s: Int32 in 1...2_000_000 {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
        }
        XCTFail("no seed in 1…2,000,000 makes the pick true")
        return 1
    }

    /// LEFT held from the level start until the arena is locked and the Chief active and standing (`+0xcd`) — on
    /// level 18 he wakes for one frame at the start (the camera's pan from (0, 0)), sleeps again, and wakes for good
    /// ten frames after the lock (`testChiefFirstJumpAfterLock`). Returns the iteration.
    private func walkToChief(_ run: LevelRun, _ s: FerazelSession) throws -> Int {
        while !(s.world.arena.locked && (chief(s.world)?.onSprite ?? 0) != 0) && run.iterations < 3000 {
            try iterate(run, keys: [left])
        }
        XCTAssertNotNil(chief(s.world), "the Chief activates")
        return run.iterations
    }

    /// The Chief active and standing in the locked arena, the voices and the player's outputs drained — for the
    /// Handle-alone tests.
    private func ready(seed: Int32 = 1) throws -> (run: LevelRun, s: FerazelSession, id: Int) {
        let (run, s) = try open(seed: seed)
        _ = try walkToChief(run, s)
        let c = try XCTUnwrap(chief(s.world))
        XCTAssertNotEqual(c.onSprite, 0, "standing")
        _ = s.world.player.drainFrameOutputs()
        s.world.player.soundCalls = []
        s.world.voices = SoundVoices()
        return (run, s, c.id)
    }

    /// Level 18's record 1 as the file holds it.
    private func record() throws -> Placement {
        let L = try LevelFile.load(from: try LevelFixture.base.get(), level: 18)
        return L.placements[1]
    }

    // MARK: - 1

    func testChiefSetupWrites() throws {
        let p = try record()
        XCTAssertEqual([Int(p.type), Int(p.x), Int(p.y), Int(p.p4)], [1910, 897, 410, 1])
        // `.SetupChiefSprite` alone (M l. 75031–75115), every store in the dump's order.
        var rng = FastRand(seed: 77)
        var copy = rng
        var counting = EnemyCounting(window: true)
        var c = SpriteSlot(type: p.type, x: Int(p.x), y: Int(p.y), recordIndex: Int16(p.index))
        c.oldPosition = SpriteSlot.Point(x: Int(p.x), y: Int(p.y))
        c.x = Int(p.y)                                                   // `.MTNewSprite`'s quirk: `+0xc` = y
        c.y = 0
        let clears = Chief.setup(&c, record: p, rng: &rng, counting: &counting)
        _ = copy.next(10)
        XCTAssertEqual(rng.seed, copy.seed, "one draw: R(10), then overwritten (M l. 75098–75107)")
        XCTAssertTrue(clears, "p4 ≠ 0: `*_DAT_1009fed0 = 0`")
        XCTAssertEqual([c.particleOffsetY, c.particleOffsetX], [0, 0])
        XCTAssertEqual(c.layer, 0xc)
        XCTAssertEqual(c.handler, .chief)
        XCTAssertEqual([c.hasHit, c.hasTileHit], [true, true], "`+0x5c`, `+0x1f8`")
        XCTAssertEqual(c.classWord170, 1, "`+0x170` = p4")
        XCTAssertEqual(c.gravity, 0x276)
        XCTAssertNil(c.face, "`+0xc0 = 0`")
        XCTAssertEqual(c.burnSpeed, 1, "`+0x8d = 1`")
        XCTAssertEqual(c.hp, 2000)
        XCTAssertFalse(c.lightOverlay, "`+0x88 = 0`")
        XCTAssertEqual(c.bonusP4, 2000, "`+0x168` = HP")
        XCTAssertEqual([c.x, c.y], [897, 410], "the re-seat `+0xc ← +8`, `+0xa ← +6`")
        XCTAssertEqual(c.hotRect, IdleSprites.Rect(top: 0x55, left: 0x5e, bottom: 0xd4, right: 0xa5))
        XCTAssertEqual([c.subtype, c.subState, c.phase], [6, 0, 0], "state 6, `+0xb2` 0, `+0x46` 2 then 0")
        XCTAssertEqual(c.classTimer, 0)
        XCTAssertEqual(c.counterA6, -40, "`+0xa6` R(10), 0, then 0xffd8")
        XCTAssertEqual(c.classWord15c, 2, "the middle lane")
        XCTAssertEqual(c.launchSpeed, 0)
        XCTAssertTrue(c.mirrored, "`+0x17e = 1`")
        XCTAssertEqual(c.voicePitch, 0x1e)
        XCTAssertFalse(c.noWriteBack18a, "no `+0x18a`: his record follows him")
        XCTAssertEqual(c.flashTable, 0, "no `+0x1b4`")
        XCTAssertEqual([c.countedInTotals], [true])
        XCTAssertEqual(counting.live, 1, "counted inside the window (M l. 75108–75111)")
        XCTAssertEqual([c.x256, c.y256], [897 << 8, 410 << 8])
        // Outside the counting window: not counted. p4 = 0: HP 0x4b0, "no boss alive" and `+0x88` untouched.
        var r2 = FastRand(seed: 77)
        var outside = EnemyCounting(window: false)
        var d = SpriteSlot(type: p.type, x: 0, y: 0)
        d.oldPosition = SpriteSlot.Point(x: 10, y: 20)
        let q = Placement(index: 1, flag: 1, byte1: 0, type: p.type, p1: 0, p2: 0, p3: 0, p4: 0, y: 20, x: 10)
        XCTAssertFalse(Chief.setup(&d, record: q, rng: &r2, counting: &outside))
        XCTAssertEqual([Int(d.hp), Int(d.bonusP4), Int(d.classWord170)], [0x4b0, 0x4b0, 0])
        XCTAssertTrue(d.lightOverlay, "p4 = 0: `+0x88` left as `.InitSprite` set it")
        XCTAssertEqual([d.countedInTotals], [false])
        XCTAssertEqual(outside.live, 0)
        // The class row (`SpriteClassTable` `.chief`) installs his Handle for every type, as the sister classes pin
        // theirs; the Setup entry: idle, the face the Handle sets (`.handle`: `.AddIdleSprite` sees `+0xc0 = 0`, so the
        // app's idle rect is SetRect(0, 0, 64, 64), not the placeholder PICT 150's bounds), the cache single 0x776.
        for t in Int16(0x776)...0x77f { XCTAssertEqual(SpriteHandler.forClass(type: t), .chief, "\(t)") }
        let L18 = try LevelFile.load(from: try LevelFixture.base.get(), level: 18)
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: L18, playerX: 0))
        XCTAssertEqual(e.spawn, .idle)
        XCTAssertEqual(e.source, .handle)
        XCTAssertEqual([e.sheet?.pict, Int16(e.faceIndex)], [0x776, 0])
        XCTAssertEqual(e.sheet?.single, true)
        XCTAssertTrue(e.clearsNoBossAlive)

        // On the level (the fixture): `.GenerateSprite` queues him idle (`SpriteClassTable` `.idle`), with his Setup's
        // fields in the snapshot; "no boss alive" cleared by his Setup; the arena unlocked; counted in the level total.
        let (_, s) = try open()
        let w = s.world
        XCTAssertNil(chief(w), "spawned idle")
        let entry = try XCTUnwrap(w.idle.entries.compactMap { $0 }.first { $0.saved.type == 1910 })
        let saved = entry.saved
        XCTAssertEqual(saved.recordIndex, 1)
        XCTAssertEqual(saved.handler, .chief)
        XCTAssertEqual([saved.hp, saved.counterA6, saved.subtype], [2000, -40, 6])
        XCTAssertEqual([saved.x, saved.y], [897, 410])
        XCTAssertEqual(saved.face, f(Chief.standing, 0), "the entry carries the Handle's first face (`.handle`)")
        XCTAssertEqual(entry.faceRect, IdleSprites.Rect.noFace, "`+0xc0 = 0` at `.AddIdleSprite`: SetRect(0, 0, 64, 64)")
        XCTAssertEqual(w.arena.noBossAlive, 0)
        XCTAssertFalse(w.arena.locked)
        XCTAssertTrue(saved.countedInTotals)
        XCTAssertEqual(w.refusedSpawns, 0)
    }

    // MARK: - 2

    func testChiefCacheRegistration() throws {
        // `.InitChiefSprite` as 6A-CF registered it (M l. 75020–75026; LL §6 sets #60–#63, single #193): the four sets
        // after the Wizard's 0x728 (#59) and before the Demon's 0x780 (#64), each 4 × 0x100×0xfe, 4 a row; the single
        // 0x776 after the Wizard's 0x726 (#192); all five under the cache flag 1.
        let sets = CachedFaces.sets, singles = CachedFaces.singles
        XCTAssertEqual(sets[58].pict, 0x728)
        XCTAssertEqual(sets[59...62].map(\.pict), [0x777, 0x778, 0x779, 0x77a])
        XCTAssertEqual(sets[63].pict, 0x780)
        for r in sets[59...62] {
            XCTAssertEqual([r.faces, r.cellWidth, r.cellHeight, r.columns, Int(r.flag)], [4, 0x100, 0xfe, 4, 1], "\(r.pict)")
            XCTAssertTrue(r.present)
        }
        XCTAssertEqual(singles[191].pict, 0x726)
        XCTAssertEqual([Int(singles[192].pict), Int(singles[192].flag)], [0x776, 1])
        XCTAssertEqual(sets[42].pict, 0x77b, "the boulder set #43 (`.InitEnemyShotSprite`)")
        XCTAssertEqual(sets[42].flag, 0)
        // His Setup's marks (M l. 75067–75075): the single 0x776, the sets 0x777…0x77a and the boulder set 0x77b
        // (`_DAT_100a083c`) — for every Chief type; the sets in registration order, then the single.
        let marks: [CachedFaces.RecordKey] = [.set(42), .set(59), .set(60), .set(61), .set(62), .single(192)]
        for t in Int16(0x776)...0x77f {
            XCTAssertEqual(CachedFaces.markedRecords(type: t), marks, "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [0x77b, 0x777, 0x778, 0x779, 0x77a])
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [0x776])
        }
        XCTAssertEqual(CachedFaces.markedRecords(type: 0x775), [], "the dart trap 0x775 marks nothing")
        // On the fixture: level 18's load needs and loads them (the plants' singles beside them).
        let (run, s) = try open()
        let needed = CachedFaces.needed(by: s).records
        XCTAssertTrue(Set(marks).isSubset(of: needed))
        XCTAssertTrue(Set(marks).isSubset(of: run.carry.cachedFaces.loadedRecords), "loaded at the level's setup")
    }

    // MARK: - 3

    func testChiefFirstJumpAfterLock() throws {
        // LEFT held from the level start (seed 1). State 6 (M l. 75407–75418): vx 0 and face 0x776 every frame (3.10
        // item 3); `+0xa6` + 1 only on his locked Handle frames; `+0xa6 > 15` on the ground → state 1 — from −40, his
        // 56th locked Handle frame. On level 18 he is asleep (idle) at the lock: measured, he wakes for one frame at the
        // level start (the camera pans in from (0, 0)), sleeps from the next, the arena locks, and he wakes for good
        // ten frames later — so the first jump comes 66 frames after the lock, not 56 (BOS §3.3 counts from the lock).
        let (run, s) = try open()
        let w = s.world
        var firstActive: Int?, asleep: Int?, lock: Int?, awake: Int?, jump: Int?
        var lockedFrames = 0
        while jump == nil && run.iterations < 3000 {
            try iterate(run, keys: [left])
            if lock == nil && w.arena.locked { lock = run.iterations }
            guard let c = chief(w) else {
                if firstActive != nil && asleep == nil { asleep = run.iterations }
                continue
            }
            if firstActive == nil { firstActive = run.iterations }
            if asleep != nil && awake == nil { awake = run.iterations }
            if w.arena.locked { lockedFrames += 1 }
            if c.subtype == 6 {
                XCTAssertEqual(c.vx, 0, "state 6: vx 0")
                XCTAssertEqual(c.face, f(Chief.standing, 0), "state 6: face 0x776")
                XCTAssertEqual(Int(c.counterA6), -40 + lockedFrames, "counts only while locked")
                XCTAssertEqual(c.hotRect, IdleSprites.Rect(top: 0x73, left: 0x58, bottom: 0xd2, right: 0xac),
                               "the hot rect every live frame (3.10 item 2)")
            } else if c.subtype == 1 {
                jump = run.iterations
                XCTAssertEqual([c.counterA6, c.phase], [0, 0], "state 1 entered: its first frame is the next Handle's")
            }
        }
        let a = try XCTUnwrap(awake), j = try XCTUnwrap(jump)
        XCTAssertEqual(lockedFrames, 56, "state 1 on his 56th locked Handle frame")
        XCTAssertEqual(j - a + 1, 56)
        // These frames (wake 1, asleep 2, lock 111, awake 121, jump 176; the first landing 212 below) were measured
        // headless: the stub's wake rectangle for the re-idled Chief is the whole 256×254 cell, a superset of the opaque
        // bounds (`FerazelSession` headless `LevelServices`), so the real-game wake may come later — 6A-L18 re-measures
        // with the real face bounds.
        XCTAssertEqual([firstActive, asleep, lock, awake, jump], [1, 2, 111, 121, 176], "measured (seed 1)")

        // The twin with the arena open (the lock switched off by hand between his Handles): `+0xa6` stands, no jump
        // in 100 frames; locked again, it counts one a frame.
        let (_, s3, id3) = try ready()
        s3.world.active.update(id: id3) { c in
            c.subtype = 6
            c.counterA6 = -40
            c.vx = 0x300                                                 // pushed (6A-CH2's Hit): the wait stops him
        }
        for k in 0..<100 {
            s3.world.arena.locked = false
            handle(s3.world, id3)
            if k == 0 { XCTAssertEqual(try slot(s3.world, id3).vx, 0, "state 6: vx 0, even pushed (3.10 item 3)") }
        }
        XCTAssertEqual([try slot(s3.world, id3).counterA6, try slot(s3.world, id3).subtype], [-40, 6],
                       "unlocked: no count, no jump")
        s3.world.arena.locked = true
        for _ in 0..<3 { handle(s3.world, id3) }
        XCTAssertEqual(try slot(s3.world, id3).counterA6, -37, "locked: + 1 a frame")
        // `+0xa6 > 15` in the air holds the wait; on the ground it jumps.
        s3.world.active.update(id: id3) { c in
            c.counterA6 = 30
            c.y -= 200
            c.y256 = Int32(c.y) << 8
            c.groundKind = 0
        }
        handle(s3.world, id3)
        XCTAssertEqual([try slot(s3.world, id3).subtype, try slot(s3.world, id3).counterA6], [6, 31], "in the air: waits")

        // `+0xe9` or `+0x1b2` → nothing at all (3.10 item 1): not even `.StandardSpriteHandles` or the gravity.
        for (label, mark) in [("+0xe9", { (c: inout SpriteSlot) in c.dead = true }),
                              ("+0x1b2", { (c: inout SpriteSlot) in c.handleSkip = true })] {
            s3.world.active.update(id: id3) { c in
                c.dead = false
                c.handleSkip = false
                mark(&c)
                c.invulnerable = 5
                c.vy = 0x100
            }
            let held = try slot(s3.world, id3)
            handle(s3.world, id3)
            XCTAssertEqual(try slot(s3.world, id3), held, "\(label): nothing written")
        }
        // The gravity every live frame, 0x276 (3.10 item 20): in the air vy grows by 0x276.
        s3.world.active.update(id: id3) { c in
            c.dead = false
            c.handleSkip = false
            c.y -= 200
            c.y256 = Int32(c.y) << 8
            c.vy = 0
            c.subtype = 0
        }
        handle(s3.world, id3)
        XCTAssertEqual(try slot(s3.world, id3).vy, 0x276, "gravity 0x276")
    }

    // MARK: - 4

    func testChiefJumpDrawOrderAndLanes() throws {
        let (_, s, id) = try ready()
        let w = s.world
        // The take-off (M l. 75303–75355), state 1 alone: the new `+0x46` 3 → R(100) r, then R(6000) p; snd 414 pitched
        // (0x14, 0xab, centre, 35000 + p) (3.10 item 5); vy −0x2904; `+0xce = 0` (item 6); the lane change by r.
        let rows: [(lane: Int32, r: Int, vx: Int32, to: Int32)] = [
            (2, 0x20, -0x700, 1), (2, 0x21, 0, 2), (2, 0x41, 0, 2), (2, 0x42, 0x700, 3),
            (1, 0x20, 0, 1), (1, 0x21, 0x700, 2), (1, 0x41, 0x700, 2), (1, 0x42, 0xe00, 3),
            (3, 0x20, -0xe00, 1), (3, 0x21, -0x700, 2), (3, 0x41, -0x700, 2), (3, 0x42, 0, 3),
        ]
        for row in rows {
            let sd = seed { r in Int(r.next(100)) == row.r }
            w.rng = FastRand(seed: sd)
            var copy = w.rng
            let r = Int(copy.next(100)), p = Int32(copy.next(6000))
            XCTAssertEqual(r, row.r)
            var c = try slot(w, id)
            c.subtype = 1
            c.phase = 2
            c.classWord15c = row.lane
            c.vx = 0x123
            c.groundKind = 3
            c.centre = SpriteSlot.Point(x: 1000, y: 500)
            w.player.cues = []
            Chief.jump(w, &c)
            let tag = "lane \(row.lane) r \(row.r)"
            XCTAssertEqual(w.rng.seed, copy.seed, "\(tag): R(100) then R(6000), nothing else")
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 414, priority: 0x14, volume: 0xab,
                                                     position: SpriteSlot.Point(x: 1000, y: 500), rate: 35000 + p)], tag)
            XCTAssertEqual([c.vx, c.classWord15c], [row.vx, row.to], tag)
            XCTAssertEqual(c.vy, -0x2904, tag)
            XCTAssertEqual(c.groundKind, 0, "\(tag): `+0xce = 0`")
            XCTAssertEqual([c.phase, c.subtype], [3, 1], tag)
            XCTAssertEqual(c.face, f(Chief.jumpSet, 1), "\(tag): i = old 2 / 2")
        }
        // A lane outside 1…3: the draws and the sound, no lane change.
        for lane: Int32 in [0, 4] {
            var c = try slot(w, id)
            c.subtype = 1
            c.phase = 2
            c.classWord15c = lane
            c.vx = 0x123
            Chief.jump(w, &c)
            XCTAssertEqual([c.vx, c.classWord15c, c.vy], [0x123, lane, -0x2904], "lane \(lane)")
        }
        // The jump faces 0x779[min(old n / 2, 2)] (3.10 item 4) and the exit (item 7): the new n > 3 while falling →
        // `+0xa6 = 0`, n 0, state 3; rising (vy ≤ 0) it holds.
        var faces: [Int] = []
        for old: Int16 in 0...7 {
            var c = try slot(w, id)
            c.subtype = 1
            c.phase = old
            c.vy = -5
            Chief.jump(w, &c)
            faces.append(c.face?.index ?? -1)
            XCTAssertEqual(c.face?.pict, Chief.jumpSet)
            if old != 2 { XCTAssertEqual([c.phase, c.subtype], [old + 1, 1], "old \(old) rising") }
        }
        XCTAssertEqual(faces, [0, 0, 1, 1, 2, 2, 2, 2])
        for (old, vy, exits) in [(Int16(3), Int32(1), true), (3, 0, false), (4, 0x200, true), (2, 0x200, false)] {
            var c = try slot(w, id)
            c.subtype = 1
            c.phase = old
            c.vy = vy
            c.counterA6 = 9
            let seedBefore = w.rng.seed
            Chief.jump(w, &c)
            if exits {
                XCTAssertEqual([c.counterA6, c.phase, c.subtype], [0, 0, 3], "old \(old) vy \(vy)")
            } else {
                XCTAssertEqual(c.subtype, 1, "old \(old) vy \(vy)")
            }
            if old != 2 { XCTAssertEqual(w.rng.seed, seedBefore, "old \(old): no draw") }
        }

        // Through the Handle from state 6's exit: frames 1–2 rise nothing (J[0], J[0]), the third takes off — then the
        // gravity of the same Handle's `.ApplyGravityAndSeparateFromTiles` (vy −0x2904 + 0x276).
        s.world.active.update(id: id) { c in
            c.subtype = 1
            c.phase = 0
            c.classWord15c = 2
        }
        var take = 0
        for k in 1...3 {
            handle(w, id)
            let c = try slot(w, id)
            if c.vy < -0x2000 { take = k }
        }
        XCTAssertEqual(take, 3, "the third jump frame")
        XCTAssertEqual(try slot(w, id).vy, -0x2904 + 0x276)
    }

    // MARK: - 5

    func testChiefLandingShakeAndStagger() throws {
        let (_, s, id) = try ready()
        let w = s.world
        let pid = try XCTUnwrap(w.playerID)
        // In the air (`+0xcd == 0`): face 0x779[3], nothing else (3.10 item 8).
        var a = try slot(w, id)
        a.subtype = 3
        a.phase = 0
        a.onSprite = 0
        a.vx = 0x300
        let seed0 = w.rng.seed
        w.player.cues = []
        w.shakeStore = nil
        Chief.land(w, &a)
        XCTAssertEqual(a.face, f(Chief.jumpSet, 3))
        XCTAssertEqual([a.phase, a.subtype], [0, 3])
        XCTAssertEqual(a.vx, 0x300)
        XCTAssertEqual(w.rng.seed, seed0, "no draw in the air")
        XCTAssertEqual(w.player.cues, [])
        XCTAssertNil(w.shakeStore)

        // The landing frame (n 0, M l. 75367–75380): R(12000), snd 435 pitched (1, 0xab, centre, 40000 + R), the shake
        // 0x16, the stagger 0x18 only when the player's `+0xce` or `+0xcd` is set (M l. 75373), vx 0, face the player
        // (3.10 item 9).
        for (ground, onSprite, staggers) in [(UInt8(0), UInt8(0), false), (3, 0, true), (0, 1, true), (3, 1, true)] {
            for (px, right) in [(Int16(1200), true), (Int16(1000), false), (Int16(999), false)] {
                w.active.update(id: pid) { p in
                    p.groundKind = ground
                    p.onSprite = onSprite
                }
                w.player.bossGrab = 0
                w.player.centreX = px
                w.player.cues = []
                w.shakeStore = nil
                var c = try slot(w, id)
                c.subtype = 3
                c.phase = 0
                c.onSprite = 1
                c.vx = 0x300
                c.mirrored = !right
                c.centre = SpriteSlot.Point(x: 1000, y: 480)
                c.face = f(Chief.jumpSet, 3)                             // he lands wearing the fall face
                var copy = w.rng
                let r = Int32(copy.next(12000))
                Chief.land(w, &c)
                let tag = "player ground \(ground) on \(onSprite) x \(px)"
                XCTAssertEqual(w.rng.seed, copy.seed, tag)
                XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 435, priority: 1, volume: 0xab,
                                                         position: SpriteSlot.Point(x: 1000, y: 480), rate: 40000 + r)], tag)
                XCTAssertEqual(w.shakeStore, 0x16, tag)
                XCTAssertEqual(w.player.bossGrab, staggers ? 0x18 : 0, tag)
                XCTAssertEqual(c.vx, 0, tag)
                XCTAssertEqual(c.mirrored, right, "\(tag): facing right = player x > his centre x")
                XCTAssertEqual(c.face, f(Chief.standing, 0), tag)
                XCTAssertEqual(c.phase, 1, tag)
            }
        }
        // The landing faces (3.10 item 10): n 0–1 0x776, 2–4 0x777[0], 5–6 0x776; then at n 6: R(2) → `+0x158` = R + 2,
        // state 2, n 0, `+0xa6` 0; one draw.
        var c = try slot(w, id)
        c.subtype = 3
        c.phase = 1
        c.onSprite = 1
        c.counterA6 = 7
        var faces: [FaceRef?] = []
        for _ in 1...5 {
            Chief.land(w, &c)
            faces.append(c.face)
        }
        XCTAssertEqual(faces, [f(Chief.standing, 0), f(Chief.throwA, 0), f(Chief.throwA, 0), f(Chief.throwA, 0),
                               f(Chief.standing, 0)], "n 1…5")
        XCTAssertEqual(c.phase, 6)
        for (r2, throwsLeft) in [(0, 2), (1, 3)] {
            var t = c
            t.face = nil                                                 // n 6 writes its own face
            let sd = seed { r in r.next(2) == r2 }
            w.rng = FastRand(seed: sd)
            var copy = w.rng
            _ = copy.next(2)
            Chief.land(w, &t)
            XCTAssertEqual(w.rng.seed, copy.seed)
            XCTAssertEqual(t.face, f(Chief.standing, 0), "n 6: 0x776")
            XCTAssertEqual([Int(t.classWord158), Int(t.subtype), Int(t.phase), Int(t.counterA6)], [throwsLeft, 2, 0, 0])
        }

        // Through the run: the first landing after the first jump (seed 1, LEFT held throughout) —
        // the shake, and the standing player staggered: 0x18 after the Chief's Handle, 0x17 and the pose 1037[2] the
        // next frame (the arm's count 23: 23 mod 12 = 11 → 5 → +0x68).
        let (run, s2) = try open()
        let w2 = s2.world
        _ = try walkToChief(run, s2)
        var landed: Int?
        while landed == nil && run.iterations < 3000 {
            let was = chief(w2)?.subtype
            try iterate(run, keys: [left])
            let c = try XCTUnwrap(chief(w2))
            if was == 3 && c.phase == 1 && c.onSprite != 0 && c.subtype == 3 { landed = run.iterations }
        }
        let land = try XCTUnwrap(landed)
        let p = try slot(w2, pid)
        // Measured headless (the whole-cell wake rectangle; see `testChiefFirstJumpAfterLock`) — 6A-L18 re-measures.
        XCTAssertEqual(land, 212, "measured: the first landing (seed 1), 36 frames after the first jump's state 1")
        XCTAssertEqual(w2.player.bossGrab, 0x18, "the player on the ground (ground \(p.groundKind), on \(p.onSprite))")
        try iterate(run)
        XCTAssertEqual(w2.player.bossGrab, 0x17)
        XCTAssertEqual(try slot(w2, pid).face, FaceRef(pict: 1037, index: 2, set: .encoded))
    }

    // MARK: - 6

    func testChiefThrowBoulder() throws {
        let (_, s, id) = try ready()
        let w = s.world
        // n 7 (M l. 75222–75267): R(8000); snd 704 pitched (1, 0x5f, centre, 45000 + R); the boulder 0x77b at (x + 0xa1
        // facing right / x − 0x11 facing left, y + 0x33), layer `+0x80 − 1` = 0xb (3.10 item 12), its Setup's R(5)
        // between R(8000) and R(500) (item 15); `+0x17e` = his facing (item 13), `+0x46` 15, vx 4000 + R(500), vy −1200 −
        // R(150); |player x − his centre x| < 240 → vx × 0.8 (`fctiwz`), vy 2000; facing left → vx negated (item 14).
        for right in [true, false] {
            for (dx, near) in [(239, true), (240, false), (-239, true), (-240, false), (600, false)] {
                var c = try slot(w, id)
                c.subtype = 2
                c.phase = 7
                c.mirrored = right
                c.centre = SpriteSlot.Point(x: 1000, y: 470)
                w.active.update(id: id) { $0 = c }
                w.player.centreX = Int16(1000 + dx)
                w.player.cues = []
                var copy = w.rng
                let r8 = Int32(copy.next(8000))
                _ = copy.next(5)
                var vx = Int32(copy.next(500)) + 4000
                var vy = -0x4b0 - Int32(copy.next(0x96))
                if near {
                    vx = Int32((Double(vx) * 0.8).rounded(.towardZero))
                    vy = 2000
                }
                if !right { vx = -vx }
                let before = Set(w.active.sprites.map(\.id))
                Chief.throwing(w, id: id, &c)
                let tag = "right \(right) dx \(dx)"
                XCTAssertEqual(w.rng.seed, copy.seed, "\(tag): R(8000), R(5), R(500), R(0x96)")
                XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDPitched, snd: 704, priority: 1, volume: 0x5f,
                                                         position: SpriteSlot.Point(x: 1000, y: 470), rate: 45000 + r8)], tag)
                let new = w.active.sprites.filter { !before.contains($0.id) }
                XCTAssertEqual(new.count, 1, tag)
                let b = try XCTUnwrap(new.first)
                XCTAssertEqual(b.type, 0x77b, tag)
                XCTAssertEqual(b.handler, .enemyShot, tag)
                XCTAssertEqual(b.layer, 0xb, tag)
                XCTAssertEqual([b.x, b.y], [c.x + (right ? 0xa1 : -0x11), c.y + 0x33], tag)
                XCTAssertEqual(b.mirrored, right, tag)
                XCTAssertEqual(b.phase, 15, tag)
                XCTAssertEqual([b.vx, b.vy], [vx, vy], tag)
                XCTAssertEqual(c.phase, 8, tag)
                _ = w.active.remove(id: b.id)
            }
        }
        // Not handled on its spawn frame (BOS §1.1: layer 0xb < 0xc → in front of him): one whole iteration with the
        // Chief at n 7 — the boulder keeps `+0x46` 15 and the vy he gave it (its Handle would step `+0x46` and add 0x140).
        let (run2, s2, id2) = try ready()
        s2.world.active.update(id: id2) { c in
            c.subtype = 2
            c.phase = 7
            c.classWord158 = 5
        }
        try iterate(run2)
        let w2 = s2.world
        let b = try XCTUnwrap(w2.active.sprites.first { $0.type == 0x77b })
        XCTAssertEqual(b.phase, 15, "not handled on its spawn frame")
        XCTAssertTrue(b.vy == 2000 || (-0x4b0 - 0x95 ... -0x4b0).contains(b.vy), "vy as thrown: \(b.vy)")
        let order = w2.active.sprites.map(\.id)
        XCTAssertLessThan(try XCTUnwrap(order.firstIndex(of: b.id)), try XCTUnwrap(order.firstIndex(of: id2)))
        try iterate(run2)
        XCTAssertNotEqual(try slot(w2, b.id).phase, 15, "handled from the next frame")

        // No free record (known deviation 6, Ruling 16 widened): no Setup (no R(5)), the stores and reads dropped, R(500)
        // and R(0x96) still drawn; the frame goes on (n 8).
        var fillers: [Int] = []
        while w.active.sprites.count < SpriteWorld.recordCount {
            fillers.append(w.active.insert(SpriteSlot(type: 1, x: -5000, y: -5000, layer: 0)))
        }
        let refused = w.refusedSpawns
        var c = try slot(w, id)
        c.subtype = 2
        c.phase = 7
        var copy = w.rng
        _ = copy.next(8000)
        _ = copy.next(500)
        _ = copy.next(0x96)
        Chief.throwing(w, id: id, &c)
        XCTAssertEqual(w.rng.seed, copy.seed, "R(8000), R(500), R(0x96) — no R(5)")
        XCTAssertEqual(w.refusedSpawns, refused + 1)
        XCTAssertEqual(c.phase, 8)
        XCTAssertFalse(w.active.sprites.contains { $0.type == 0x77b })
        for f in fillers { _ = w.active.remove(id: f) }
    }

    // MARK: - 7

    func testChiefThrowCount() throws {
        // State 2 from a landing (M l. 75211–75292), through the Handle: the throw faces 0x777[i] (i < 4), 0x778[i − 4]
        // (i < 8), else 0x776, i = n >> 1 (3.10 item 11); n 0 faces the player and takes a throw, below 1 → state 6 with
        // `+0xa6 = 0` and face 0x776; n 7 throws; n 18 → n 0 (the 19-frame cycle, item 16). 2 throws left → one boulder,
        // back to state 6 on frame 20; 3 → two boulders (frames 8 and 27), state 6 on frame 39.
        for (left, boulders, back) in [(Int32(2), [8], 20), (3, [8, 27], 39)] {
            let (_, s, id) = try ready()
            let w = s.world
            // The player on his far side (right for 2 throws, left for 3): n 0 turns him to face the player (M l.
            // 75270–75272). The hot rect as the Setup left it: the Handle writes its own every live frame (3.10 item 2).
            let toRight = left == 2
            w.player.centreX = Int16(try slot(w, id).centre.x + (toRight ? 300 : -300))
            s.world.active.update(id: id) { c in
                c.subtype = 2
                c.phase = 0
                c.counterA6 = 9                                          // the landing leaves 0; 9 shows each reset
                c.classWord158 = left
                c.mirrored = !toRight
                c.hotRect = IdleSprites.Rect(top: 0x55, left: 0x5e, bottom: 0xd4, right: 0xa5)
            }
            var thrown: [Int] = [], state6: Int?
            var seen = Set(w.active.sprites.filter { $0.type == 0x77b }.map(\.id))
            for k in 1...45 where state6 == nil {
                let n = try slot(w, id).phase
                handle(w, id)
                let c = try slot(w, id)
                XCTAssertEqual(c.hotRect, IdleSprites.Rect(top: 0x73, left: 0x58, bottom: 0xd2, right: 0xac), "frame \(k)")
                XCTAssertEqual(c.mirrored, toRight, "frame \(k): facing the player since n 0")
                let fresh = w.active.sprites.filter { $0.type == 0x77b && !seen.contains($0.id) }
                if !fresh.isEmpty { thrown.append(k) }
                seen.formUnion(fresh.map(\.id))
                if c.subtype == 6 {
                    state6 = k
                    XCTAssertEqual(c.counterA6, 0)
                    XCTAssertEqual(c.face, f(Chief.standing, 0))
                    XCTAssertEqual(c.classWord158, 0)
                } else {
                    let i = Int(n >> 1)
                    let want = i < 4 ? f(Chief.throwA, i) : (i < 8 ? f(Chief.throwB, i - 4) : f(Chief.standing, 0))
                    XCTAssertEqual(c.face, want, "frame \(k) n \(n)")
                    XCTAssertEqual(c.phase, n == 18 ? 0 : n + 1, "frame \(k)")
                    XCTAssertEqual(c.counterA6, k < 19 ? 9 : 0, "frame \(k): `+0xa6 = 0` at the cycle's reset (n 18)")
                }
            }
            XCTAssertEqual(thrown, boulders, "throws \(left)")
            XCTAssertEqual(state6, back, "throws \(left)")
        }
    }

    // MARK: - 8

    func testChiefDeathCryDraws() throws {
        // HP < 1 with state ≠ 4 (M l. 75427–75436): state 4, `+0x46 = +0xa6 = 0`; R(100) < 0x3c → `.GoblinChiefRandomCry`
        // first — R(100) r, then (no 465 / 466 / 467 playing) R(10000) and r < 0x29 → 467 vol 0xc9, < 0x47 → 466, else
        // 465, vol 0xab, rate 42000 + R (3.10 item 23) — then snd 703 (3D, 1, 0x100, his centre as the Handle found it).
        let (_, s, id) = try ready()
        let w = s.world
        let centre = SpriteSlot.Point(x: 1010, y: 480)
        func die(_ sd: Int32, playing: Set<Int16> = []) throws -> (cues: [PlayerCue], c: SpriteSlot, copy: FastRand) {
            w.active.update(id: id) { c in
                c.hp = 0
                c.subtype = 6
                c.phase = 5
                c.counterA6 = 3
                c.centre = centre
            }
            w.rng = FastRand(seed: sd)
            w.voices = SoundVoices(playing: playing)
            w.player.cues = []
            w.player.soundCalls = []
            handle(w, id)
            return (w.player.cues, try slot(w, id), FastRand(seed: sd))
        }
        let death = PlayerCue(call: .threeD, snd: 703, priority: 1, volume: 0x100, position: centre)
        // No cry: R(100) ≥ 0x3c.
        let quiet = seed { r in r.next(100) >= 0x3c }
        var (cues, c, copy) = try die(quiet)
        _ = copy.next(100)
        XCTAssertEqual(w.rng.seed, copy.seed, "one R(100)")
        XCTAssertEqual(cues, [death])
        XCTAssertEqual([c.subtype, c.phase, c.counterA6], [4, 0, 0])
        // The gate's edge: R(100) 0x3c is quiet, 0x3b cries.
        for (r1, cries) in [(0x3c, false), (0x3b, true)] {
            (cues, c, copy) = try die(seed { r in Int(r.next(100)) == r1 })
            XCTAssertEqual(cues.count, cries ? 2 : 1, "R(100) \(r1)")
            XCTAssertEqual(cues.last, death, "R(100) \(r1)")
        }
        // The cry, each band at its edges.
        for (r2, snd, vol) in [(0x28, Int16(467), Int16(0xc9)), (0x29, 466, 0xab), (0x46, 466, 0xab), (0x47, 465, 0xab),
                               (0, 467, 0xc9), (99, 465, 0xab)] {
            let sd = seed { r in r.next(100) < 0x3c && Int(r.next(100)) == r2 }
            (cues, c, copy) = try die(sd)
            _ = copy.next(100)
            _ = copy.next(100)
            let rate = Int32(copy.next(10000)) + 42000
            XCTAssertEqual(w.rng.seed, copy.seed, "r2 \(r2)")
            XCTAssertEqual(cues, [PlayerCue(call: .threeDPitched, snd: snd, priority: 1, volume: vol, position: centre,
                                            rate: rate), death], "r2 \(r2)")
        }
        // The voice gate (3.10 item 22): any of 465, 466, 467 playing → R(100) only, no R(10000), no cry.
        for playing: Int16 in [465, 466, 467] {
            let sd = seed { r in r.next(100) < 0x3c }
            (cues, c, copy) = try die(sd, playing: [playing])
            _ = copy.next(100)
            _ = copy.next(100)
            XCTAssertEqual(w.rng.seed, copy.seed, "\(playing) playing")
            XCTAssertEqual(cues, [death], "\(playing) playing")
        }
        // HP 1 is alive; a dying Chief at HP 0 gets no second entry.
        w.active.update(id: id) { c in c.hp = 1; c.subtype = 6 }
        handle(w, id)
        XCTAssertEqual(try slot(w, id).subtype, 6)

        // Dying (M l. 75193–75209): vx × 0.9 (3.10 item 17), face 0x77a[min(n >> 2, 3)], n capped at 0x10 (item 18),
        // `+0xa6` + 1, the burn `+0x1a2 = 1` on dying frame 20.
        let (_, s2, id2) = try ready()
        let w2 = s2.world
        s2.world.active.update(id: id2) { c in
            c.hp = 0
            c.subtype = 6
        }
        handle(w2, id2)                                                  // the death entry
        s2.world.active.update(id: id2) { $0.vx = -1001 }
        var vxs: [Int32] = []
        for k in 1...21 {
            // Frame 21: a burn under way (row 5; headless has no face provider, so `.HandleBurn` leaves it) is not
            // restarted — the burn starts on `+0xa6 == 0x14` only.
            if k == 21 { s2.world.active.update(id: id2) { $0.burnRow = 5 } }
            let v = try slot(w2, id2).vx
            handle(w2, id2)
            let d = try slot(w2, id2)
            XCTAssertEqual(d.face, f(Chief.deathSet, min((k - 1) >> 2, 3)), "dying frame \(k)")
            XCTAssertEqual(d.phase, Int16(min(k, 0x10)), "dying frame \(k)")
            XCTAssertEqual(d.counterA6, Int16(k))
            XCTAssertEqual(d.burnRow != 0, k >= 20, "dying frame \(k): the burn on 20")
            if k == 21 { XCTAssertEqual(d.burnRow, 5, "frame 21: not restarted") }
            if k <= 3 { vxs.append(v) }
            XCTAssertEqual(d.subtype, 4)
        }
        XCTAssertEqual(vxs, [-1001, -900, -810], "vx × 0.9 (`fctiwz`: −900.9 → −900, not −901)")

        // The `+0xb2` counter (3.10 item 19): > 0 → < 5 ? + 1 : 0, every frame, whatever the state.
        let (_, s3, id3) = try ready()
        s3.world.active.update(id: id3) { $0.subState = 1 }
        var counters: [Int16] = []
        for _ in 0..<6 {
            handle(s3.world, id3)
            counters.append(try slot(s3.world, id3).subState)
        }
        XCTAssertEqual(counters, [2, 3, 4, 5, 0, 0])
        s3.world.active.update(id: id3) { $0.subState = -2 }
        handle(s3.world, id3)
        XCTAssertEqual(try slot(s3.world, id3).subState, -2)

        // No liquids (3.10 item 21): standing in a test-only lava pool (the level's BG tile 0 given kind 202, in memory)
        // his HP stands; the twin — the Warrior's liquids rows on the same frame — takes 100.
        let (_, s4, id4) = try ready()
        let w4 = s4.world
        let c4 = try slot(w4, id4)
        let g = w4.tiles
        var bg = g.bg.cells
        let col0 = max(0, (c4.x >> 5) - 2), row0 = max(1, (c4.y >> 5) - 3)
        for row in row0..<min(row0 + 14, g.bg.height) {
            for col in col0..<min(col0 + 14, g.bg.width) { bg[row * g.bg.width + col] = bg[row * g.bg.width + col] & 0xff00 | 1 }
        }
        var kinds = g.bgKinds
        kinds[0] = 202
        w4.tiles = TileGrid(fg: g.fg, bg: TileMap(width: g.bg.width, height: g.bg.height, cells: bg), fgKinds: g.fgKinds,
                            bgKinds: kinds)
        s4.world.active.update(id: id4) { c in c.hp = 1500; c.invulnerable = 0 }
        handle(w4, id4)
        let lava = try slot(w4, id4)
        XCTAssertEqual(lava.waterKind, 2, "in the lava")
        XCTAssertEqual(lava.hp, 1500, "no liquids test in his tail")
        EnemyCommon.liquids(w4, id: id4, class: .dillo)
        XCTAssertEqual(try slot(w4, id4).hp, 1400, "the twin: the liquids rows would take 100")
    }

    // MARK: - 9

    func testChiefTileCallbackIsCrawlerBody() throws {
        // `.HitChiefTileSprite` (M l. 75535–75567) is the Warrior's line for line and so the Crawler's body
        // (`CrawlerRoach.hitTile`): FG any kind and BG < 100 `.WallBounce`, BG 100…199 `.WallBounceBG(kind − 100)`, ≥ 200
        // water `.HandleUnderWater` unless `+0x140`.
        let cases: [(kind: Int, layer: TileLayer, done: Bool)] = [
            (3, .foreground, false), (150, .foreground, false), (3, .background, false), (99, .background, false),
            (100, .background, false), (0x7f, .background, false), (199, .background, false),
            (200, .background, false), (202, .background, false), (200, .background, true),
        ]
        let (_, a, aid) = try ready()
        let (_, b, bid) = try ready()
        let homeA = try slot(a.world, aid), homeB = try slot(b.world, bid)
        var writers: [Int] = []
        for c in cases {
            for (t, id, home) in [(a, aid, homeA), (b, bid, homeB)] {
                t.world.active.update(id: id) { w in
                    w = home
                    w.x = 640; w.y = 280; w.x256 = 640 << 8; w.y256 = 280 << 8
                    w.vx = 0x300; w.vy = 0x500
                    w.underwaterDone = c.done
                }
            }
            let before = try slot(a.world, aid)
            let pass = try XCTUnwrap(Chief.pass(before), "the Setup stored `+0x1f8`")
            pass(TileSolver(world: a.world), aid, TilePos(x: 720, y: 384), c.kind, c.layer)
            CrawlerRoach.hitTile(TileSolver(world: b.world), id: bid, pos: TilePos(x: 720, y: 384), kind: c.kind,
                                 layer: c.layer)
            let wa = try slot(a.world, aid), wb = try slot(b.world, bid)
            var wbAligned = wb
            wbAligned.id = wa.id
            XCTAssertEqual(wa, wbAligned, "kind \(c.kind) \(c.layer) done \(c.done)")
            if wa != before { writers.append(c.kind) }
            if c.done && c.kind >= 200 { XCTAssertEqual(wa, before, "`+0x140` set: no `.HandleUnderWater`") }
            if !c.done && c.kind >= 200 {
                XCTAssertEqual([wa.underwaterDone, wa.waterRow >= 1], [true, true], "kind \(c.kind): in the water")
            }
        }
        // At this geometry (the tile on his hot rect's top-left corner) four cases write: the FG wall 150 (pushed up),
        // the BG wall 0x7f (`.WallBounceBG` kind 0x1b: pushed left, vx 0) and both open-water cases.
        XCTAssertEqual(writers, [150, 0x7f, 200, 202], "the bands write")
        var none = homeA
        none.hasTileHit = false
        XCTAssertNil(Chief.pass(none), "`+0x1f8` 0 → no callback")
        // The Handle installs it: dropped from 200 px above, he lands on level 18's floor and stays there.
        a.world.active.update(id: aid) { w in
            w = homeA
            w.y -= 200
            w.y256 = Int32(w.y) << 8
            w.vy = 0
            w.subtype = 0
        }
        var ys: [Int] = []
        for _ in 0..<60 { handle(a.world, aid); ys.append(try slot(a.world, aid).y) }
        XCTAssertEqual(Array(Set(ys.suffix(20))), [homeA.y], "landed where the level stood him")
        XCTAssertNotEqual(try slot(a.world, aid).groundKind, 0, "on ground")
    }
}

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
        // 6A-CH2: `.LoadCachedSpriteFaces` converts a flag-1 record under the level+base CLUT (`*_DAT_1009ff8c`, M l.
        // 73806–73812 / 73843–73849) — level 18's is 224. The record cut carries it; with no CLUT given there is none.
        let L = try LevelFile.load(from: try LevelFixture.base.get(), level: 18)
        let lc = ColorLUT.screenClutId(L.header)
        XCTAssertEqual(lc, 224)
        for k in marks where CachedFaces.record(k).flag == 1 {
            XCTAssertEqual(CachedFaces.sheet(record: k, levelClut: lc)?.clut, lc, "\(k)")
            XCTAssertNil(CachedFaces.sheet(record: k), "\(k): no CLUT, no sheet")
        }
        XCTAssertEqual(CachedFaces.sheet(record: .set(42), levelClut: lc)?.clut, 200, "the boulder set (flag 0): clut 200")
        // The renderer's list (`FrameRenderer.spriteSheets`): the four sets come through the record cut under it — the
        // single 0x776 and the boulders through the Setup-face table and `handleSets`, as before.
        let cut = CachedFaces.sheets(markedBy: [Int16(0x776)], levelClut: lc).filter { (0x777...0x77a).contains($0.pict) }
        XCTAssertEqual(cut.map(\.pict), [0x777, 0x778, 0x779, 0x77a])
        XCTAssertEqual(Set(cut.map(\.clut)), [lc])
        XCTAssertTrue(CachedFaces.sheets(markedBy: [Int16(0x776)]).allSatisfy { !(0x777...0x77a).contains($0.pict) },
                      "no level CLUT: not loaded")
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

    // MARK: - 6A-CH2: the Hit, the Kill, the three pieces (BOS §3.4–§3.6, §3.8's 6A-CH2 list, §3.10 items 24–30)

    /// A player shot (type `type`, `+0xa4` = `damage`, `+0xa6` 0) with a 20×20 hot rect centred on the Chief's hot rect
    /// — inside it, so `.BloodSpray`'s `.SectRectFast` of the two rects is not empty (his stored centre, which `target()`
    /// sets as a marker, lies above his hot rect).
    private func shot(_ w: SpriteWorld, over id: Int, type: Int16 = 0, damage: Int16 = 100,
                      body: (inout SpriteSlot) -> Void = { _ in }) throws -> Int {
        let m = try slot(w, id)
        let c = SpriteSlot.Point(x: m.x + (m.hotRect.left + m.hotRect.right) / 2,
                                 y: m.y + (m.hotRect.top + m.hotRect.bottom) / 2)
        return try XCTUnwrap(w.newSprite(type: type, x: c.x - 10, y: c.y - 10, layer: 0xb, handler: .playerShot) { s in
            s.x = c.x - 10
            s.y = c.y - 10
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 20, right: 20)
            s.centre = c
            s.hp = damage
            s.vx = 1000
            body(&s)
        })
    }

    /// The Chief, ready, with a known centre and the fields a hit writes set to markers.
    private func target(hp: Int16 = 2000) throws -> (s: FerazelSession, id: Int) {
        let (_, s, id) = try ready()
        s.world.active.update(id: id) { c in
            c.hp = hp
            c.invulnerable = 0
            c.subState = 0
            c.flash = 0
            c.vx = 0x123
            c.vy = -0x45
            c.centre = SpriteSlot.Point(x: 1010, y: 480)
        }
        return (s, id)
    }

    // MARK: - 10

    func testChiefTakesShotDamage() throws {
        // `.HitChiefSprite`'s shot arm (M l. 75476–75497): `.KillPlayerShot(shot, 0, 0)` first — silent, no impact
        // effect — then `.HurtSprite(S, shot +0xa4, 0, 0, 2, 8)` (3.10 item 24: dvx = dvy = 0); on a hurt `+0x116 = 15`,
        // `+0xb2 = 1` (item 25), `.BloodSpray(S, shot, 0x28, 400, 0x96, 2)` (item 26), HP < 0xc9 → snd 702 else 701
        // (`.STPlay3DSound`, 1, 0x100, his centre), then R(100) < 0x3c → `.GoblinChiefRandomCry` (item 27). The twin does
        // the routines the Hit calls by hand, in the dump's order; the cry is re-derived from a copy of the stream.
        let cases: [(hp: Int16, damage: Int16, snd: Int16)] = [(2000, 100, 701), (301, 100, 701), (300, 100, 702),
                                                               (101, 100, 702), (100, 100, 702), (40, 100, 702)]
        var cried: Set<Bool> = []
        for c in cases {
            let tag = "HP \(c.hp) − \(c.damage)"
            let (s, id) = try target(hp: c.hp)
            let w = s.world
            let sid = try shot(w, over: id, damage: c.damage)
            let (t, tid) = try target(hp: c.hp)
            let tsid = try shot(t.world, over: tid, damage: c.damage)
            w.rng = FastRand(seed: Int32(40 + c.hp))
            t.world.rng = w.rng
            let fx0 = w.active.sprites.filter { $0.handler == .effect }.count
            let particles0 = w.particles.counters.count
            var spray = w.rng
            for _ in 0..<0x28 { _ = spray.next(0x96); _ = spray.next(0x96) }
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)
            // The twin, by hand.
            var lights = LightTable()
            PlayerShotHits.kill(t.world, shot: tsid, sound: false, effect: false, effects: 1, lights: &lights)
            XCTAssertTrue(HurtSprite.apply(t.world, id: tid, damage: c.damage, dvx: 0, dvy: 0, invulnerable: 2, flash: 8))
            t.world.active.update(id: tid) { u in u.invulnerable = 15; u.subState = 1 }
            BloodSpray.spray(t.world, victim: tid, attacker: tsid, count: 0x28, speed: 400, spread: 0x96, kind: 2)
            XCTAssertEqual(t.world.rng.seed, spray.seed, "\(tag): the spray draws R(0x96) twice for each of its 0x28")
            var e = t.world.rng
            let cry = e.next(100) < 0x3c
            cried.insert(cry)
            let centre = SpriteSlot.Point(x: 1010, y: 480)
            var want = [PlayerCue(call: .threeD, snd: c.snd, priority: 1, volume: 0x100, position: centre)]
            if cry {
                let r = e.next(100)
                let rate = Int32(e.next(10000)) + 42000
                let (snd, vol): (Int16, Int16) = r < 0x29 ? (467, 0xc9) : (r < 0x47 ? (466, 0xab) : (465, 0xab))
                want.append(PlayerCue(call: .threeDPitched, snd: snd, priority: 1, volume: vol, position: centre,
                                      rate: rate))
            }
            let m = try slot(w, id), shotAfter = try slot(w, sid)
            XCTAssertTrue(shotAfter.dead, "\(tag): the shot is killed")
            XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect }.count, fx0,
                           "\(tag): effect 0 — no impact sprite")
            XCTAssertEqual(Int(m.hp), Int(c.hp) - Int(c.damage), "\(tag): HP − the shot's `+0xa4`")
            XCTAssertEqual([m.invulnerable, m.flash, m.subState], [15, 8, 1], "\(tag): `+0x116` 15 over the hurt's 2")
            XCTAssertEqual([m.vx, m.vy], [0x123, -0x45], "\(tag): dvx = dvy = 0")
            XCTAssertEqual(w.particles, t.world.particles, "\(tag): the blood spray (0x28, 400, 0x96, 2)")
            XCTAssertEqual(w.particles.counters.count, particles0 + 0x28, "\(tag): 0x28 blood particles")
            XCTAssertEqual(w.rng.seed, e.seed, "\(tag): the kill (no draw), the spray, R(100) [, the cry]")
            XCTAssertEqual(w.player.cues, want, tag)
            var mt = try slot(t.world, tid)
            mt.id = m.id
            XCTAssertEqual(m, mt, tag)
        }
        XCTAssertEqual(cried, [false, true], "both sides of the cry's R(100) gate seen")
        // The gate at its edge: after the spray's 0x50 draws, R(100) = 0x3b cries, 0x3c does not.
        for (r, cries) in [(Int16(0x3b), true), (0x3c, false)] {
            let k = seed { g in
                for _ in 0..<0x50 { _ = g.next(0x96) }
                return g.next(100) == r
            }
            let (s, id) = try target()
            let sid = try shot(s.world, over: id)
            s.world.rng = FastRand(seed: k)
            s.world.player.cues = []
            FerazelSession.hitCallback(s.world, id, sid)
            XCTAssertEqual(s.world.player.cues.map(\.snd).count, cries ? 2 : 1, "R(100) = \(r)")
        }
        // The spray's speed is 400, not 401. Above, the shot lies right of and below his stored centre: the spray's
        // direction is a 10°/80° sector, where 400 and 401 truncate alike. A shot centred straight below his stored
        // centre (x 1010; `.FindDesiredDirectionGeneric` nudges the equal x by 1) aims it at sector 27, straight up,
        // whose component is the speed itself — there they differ.
        do {
            let below: (inout SpriteSlot) -> Void = { $0.x = 1010 - 10 }
            let (s, id) = try target()
            let sid = try shot(s.world, over: id, body: below)
            s.world.rng = FastRand(seed: 7)
            FerazelSession.hitCallback(s.world, id, sid)
            var twins: [Int16: ParticlePool] = [:]
            for speed: Int16 in [400, 401] {
                let (t, tid) = try target()
                let tsid = try shot(t.world, over: tid, body: below)
                t.world.rng = FastRand(seed: 7)
                var lights = LightTable()
                PlayerShotHits.kill(t.world, shot: tsid, sound: false, effect: false, effects: 1, lights: &lights)
                XCTAssertTrue(HurtSprite.apply(t.world, id: tid, damage: 100, dvx: 0, dvy: 0, invulnerable: 2, flash: 8))
                BloodSpray.spray(t.world, victim: tid, attacker: tsid, count: 0x28, speed: speed, spread: 0x96, kind: 2)
                twins[speed] = t.world.particles
            }
            XCTAssertNotEqual(twins[400], twins[401], "straight up: this geometry tells 400 from 401")
            XCTAssertEqual(s.world.particles, twins[400], "the blood spray's speed is 400")
        }
        // Fireball 100 → 20 landed hits from 2000 (BOS §3.4): 15 frames apart (the invulnerability counts down in his
        // `.StandardSpriteHandles`).
        let (s, id) = try target()
        var landed = 0, frames = 0
        while (try slot(s.world, id).hp) > 0 && frames < 2000 {
            if try slot(s.world, id).invulnerable == 0 {
                let sid = try shot(s.world, over: id)
                FerazelSession.hitCallback(s.world, id, sid)
                landed += 1
                _ = s.world.active.remove(id: sid)
            }
            s.world.standardSpriteHandles(id)
            frames += 1
        }
        XCTAssertEqual(landed, 20, "20 Fireballs")
        XCTAssertEqual(frames, 19 * 15 + 1, "one landed shot every 15th frame")
    }

    // MARK: - 11

    func testChiefInvulnerableWastesShots() throws {
        // A shot while `+0x116 ≠ 0`: `.KillPlayerShot` has already run, `.HurtSprite` refuses → return (M l. 75478–75482):
        // the shot is wasted — killed, nothing else (no HP, no `+0x116` / `+0xb2` change, no blood, no sound, no draw).
        for invulnerable: Int16 in [1, 15] {
            let (s, id) = try target()
            let w = s.world
            w.active.update(id: id) { $0.invulnerable = invulnerable }
            let sid = try shot(w, over: id)
            let before = try slot(w, id)
            let seed0 = w.rng.seed, pool0 = w.particles
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)
            XCTAssertTrue(try slot(w, sid).dead, "invul \(invulnerable): the shot is killed")
            XCTAssertEqual(try slot(w, id), before, "invul \(invulnerable): nothing else")
            XCTAssertEqual(w.particles, pool0)
            XCTAssertEqual(w.player.cues, [])
            XCTAssertEqual(w.rng.seed, seed0)
        }
        // 3.10 item 28: at HP ≤ 0 a shot is not killed (it goes to the solid test, which ignores it); likewise a shot
        // whose `+0xa6 ≠ 0` (M l. 75459–75461).
        for (a6, hp) in [(Int16(0), Int16(0)), (0, -60), (1, 2000), (-6, 2000)] {
            let (s, id) = try target(hp: hp)
            let w = s.world
            let sid = try shot(w, over: id) { $0.counterA6 = a6 }
            let before = try slot(w, id)
            let seed0 = w.rng.seed
            w.player.cues = []
            FerazelSession.hitCallback(w, id, sid)
            XCTAssertFalse(try slot(w, sid).dead, "a6 \(a6) HP \(hp): passes through")
            XCTAssertEqual(try slot(w, id), before)
            XCTAssertEqual(w.player.cues, [])
            XCTAssertEqual(w.rng.seed, seed0)
        }
        // A Statue-spell shot (type 1) is a shot like any other: no `.TurnIntoStatue` in a boss Hit — he takes its damage.
        let (s, id) = try target()
        let sid = try shot(s.world, over: id, type: 1, damage: 200)
        FerazelSession.hitCallback(s.world, id, sid)
        XCTAssertEqual(try slot(s.world, id).handler, .chief, "not turned to stone")
        XCTAssertEqual(try slot(s.world, id).hp, 1800)
    }

    // MARK: - 12

    func testChiefCrush200AndCry() throws {
        // `.HitChiefSprite`'s solid arm (M l. 75462–75475): a Statue or a Box other → `.PlatformBounce(S, solid, S's
        // hot-rect centre offset, 0, S +0x34, 0)` == 2 with the solid falling (`+0x2c > 0`) or S on ground (`+0xce`) →
        // `.HurtSprite(S, 200, solid.vx >> 1, −1000, 2, 8)` (3.10 item 29), `+0xf0 = 0`, `.KillBox(solid)` — its own draws
        // first —, R(10000) → snd 701 pitched at 42000 + R, then `.GoblinChiefRandomCry` (R(100) always, + R(10000) when
        // no goblin voice plays). A crate 0x433 sits 3 px into the top of his Handle rect (0x58, 0x73, 0xac, 0xd2),
        // centred over him; its face a 3-row synthetic face so `.KillBox`'s `.ExplodeFaceIntoParticles` emits.
        func tok(_ op: UInt32, _ n: Int) -> [UInt8] {
            let t = op << 24 | UInt32(n)
            return [UInt8(t >> 24), UInt8(t >> 16 & 0xff), UInt8(t >> 8 & 0xff), UInt8(t & 0xff)]
        }
        let face = ParticleFace(frame: [0, 0, 3, 4], bounds: [0, -1, 4, 6],
                                tokens: tok(1, 8) + tok(2, 3) + [10, 11, 12, 0] + tok(1, 12) + tok(3, 1) + tok(2, 2)
                                    + [20, 21, 0, 0] + tok(1, 8) + tok(2, 4) + [30, 31, 32, 33] + tok(0, 0))
        struct Case { let label: String; let vy: Int32; let ground: UInt8; let invulnerable: Int16; let crush: Bool
                      let playing: Set<Int16> }
        let cases = [Case(label: "falling", vy: 0x300, ground: 0, invulnerable: 0, crush: true, playing: []),
                     Case(label: "on ground, resting", vy: 0, ground: 3, invulnerable: 0, crush: true, playing: []),
                     Case(label: "a goblin voice playing", vy: 0x300, ground: 0, invulnerable: 0, crush: true,
                          playing: [466]),
                     Case(label: "invulnerable", vy: 0x300, ground: 0, invulnerable: 4, crush: true, playing: []),
                     Case(label: "resting, in the air", vy: 0, ground: 0, invulnerable: 0, crush: false, playing: [])]
        for c in cases {
            for handler in [SpriteHandler.box, .statue] {
                let tag = "\(c.label) \(handler)"
                let (s, id) = try target()
                let w = s.world
                w.particleFaces = ParticleFaces(sprite: { $0.pict == 0x42e ? face : nil })
                w.voices = SoundVoices(playing: c.playing)
                w.active.update(id: id) { m in
                    m.vx = 0
                    m.vy = 0
                    m.groundKind = c.ground
                    m.invulnerable = c.invulnerable
                    m.voicePitch = 0x1e
                    m.hotRect = IdleSprites.Rect(top: 0x73, left: 0x58, bottom: 0xd2, right: 0xac)
                }
                let m0 = try slot(w, id)
                let crate = try XCTUnwrap(Warrior.newCrate(w, x: m0.x + 0x82 - 0xe, y: m0.y + 0x73 + 3 - 0x1c))
                w.active.update(id: crate) { b in
                    b.handler = handler
                    b.vy = c.vy
                    b.vx = -1001
                    b.centre = SpriteSlot.Point(x: b.x + 0x10, y: b.y + 0xe)
                }
                let box0 = try slot(w, crate)
                var e = w.rng
                let pool0 = w.particles.counters.count
                w.player.cues = []
                FerazelSession.hitCallback(w, id, crate)
                let m = try slot(w, id)
                guard c.crush else {
                    XCTAssertEqual(m.hp, 2000, tag)
                    XCTAssertFalse(try slot(w, crate).dead, tag)
                    XCTAssertEqual(m.voicePitch, 0x1e, tag)
                    XCTAssertEqual(w.player.cues, [], tag)
                    XCTAssertEqual(w.rng.seed, e.seed, tag)
                    continue
                }
                let hurt = c.invulnerable == 0
                XCTAssertEqual(m.hp, hurt ? 1800 : 2000, "\(tag): 200 a crush")
                if hurt {
                    XCTAssertEqual([Int(m.invulnerable), Int(m.flash), Int(m.vx), Int(m.vy)], [2, 8, -501, -1000],
                                   "\(tag): `.HurtSprite(S, 200, solid.vx >> 1, −1000, 2, 8)` — no `+0x116 = 15` here")
                } else {
                    XCTAssertEqual([Int(m.invulnerable), Int(m.vx)], [Int(c.invulnerable), 0], "\(tag): refused")
                }
                XCTAssertEqual(m.voicePitch, 0, "\(tag): `+0xf0 = 0`")
                XCTAssertTrue(try slot(w, crate).dead, "\(tag): `.KillBox(solid)`")
                // `.KillBox`'s draws first — R(10000) for snd 424, four a pixel for its particles — then R(10000) (701),
                // then the cry: R(100) r, and (no 465 / 466 / 467 playing) R(10000).
                let n = w.particles.counters.count - pool0
                XCTAssertGreaterThan(n, 0, "\(tag): the crate face exploded")
                let r424 = e.soundRate()
                for _ in 0..<n { _ = e.next(20); _ = e.next(750); _ = e.next(100); _ = e.next(30) }
                let r701 = Int32(e.next(10000)) + 42000
                let r = e.next(100)
                var want = [
                    PlayerCue(call: .threeDRand, snd: 424, priority: 1, volume: 0x100, position: box0.centre, rate: r424),
                    PlayerCue(call: .threeDPitched, snd: 701, priority: 1, volume: 0x100, position: m.centre, rate: r701),
                ]
                if c.playing.isEmpty {
                    let rate = Int32(e.next(10000)) + 42000
                    let (snd, vol): (Int16, Int16) = r < 0x29 ? (467, 0xc9) : (r < 0x47 ? (466, 0xab) : (465, 0xab))
                    want.append(PlayerCue(call: .threeDPitched, snd: snd, priority: 1, volume: vol, position: m.centre,
                                          rate: rate))
                }
                XCTAssertEqual(w.rng.seed, e.seed, "\(tag): exactly those draws")
                XCTAssertEqual(w.player.cues, want, tag)
            }
        }
        // Beside him (not from below) or a Platform solid: nothing.
        for (dx, handler) in [(0xa0, SpriteHandler.box), (0, .platform)] {
            let (s, id) = try target()
            let m0 = try slot(s.world, id)
            let crate = try XCTUnwrap(Warrior.newCrate(s.world, x: m0.x + 0x82 - 0xe + dx, y: m0.y + 0x73 + 3 - 0x1c))
            s.world.active.update(id: crate) { $0.vy = 0x300; $0.handler = handler }
            let seed0 = s.world.rng.seed
            FerazelSession.hitCallback(s.world, id, crate)
            XCTAssertEqual(try slot(s.world, id).hp, 2000, "dx \(dx) \(handler)")
            XCTAssertFalse(try slot(s.world, crate).dead)
            XCTAssertEqual(s.world.rng.seed, seed0)
        }
        // `.PlatformBounce`'s result must be 2 and its bounce flag 0 (M l. 75468): falling onto a crate (its top 3 px into
        // the bottom of his Handle rect) he LANDS on it — result 1 — and rides it (`+0xce` 3, `+0xdc` the crate, vy 0):
        // no crush, nothing drawn.
        do {
            let (s, id) = try target()
            let w = s.world
            w.active.update(id: id) { m in
                m.vx = 0
                m.vy = 0x300
                m.groundKind = 0
                m.hotRect = IdleSprites.Rect(top: 0x73, left: 0x58, bottom: 0xd2, right: 0xac)
            }
            let m0 = try slot(w, id)
            let crate = try XCTUnwrap(Warrior.newCrate(w, x: m0.x + 0x82 - 0xe, y: m0.y + 0xd2 - 3))
            let seed0 = w.rng.seed
            w.player.cues = []
            FerazelSession.hitCallback(w, id, crate)
            let m = try slot(w, id)
            XCTAssertEqual([Int(m.hp), Int(m.groundKind), Int(m.vy)], [2000, 3, 0], "landed on the crate, not crushed")
            XCTAssertEqual(m.ridden, crate)
            XCTAssertFalse(try slot(w, crate).dead)
            XCTAssertEqual(w.player.cues, [])
            XCTAssertEqual(w.rng.seed, seed0)
        }
        // The centre offset passed to `.PlatformBounce` is his hot rect's (x 0x58 + (0xac − 0x58) >> 1 = 130, y 0x73 +
        // (0xd2 − 0x73) >> 1 = 162): `.RectBounce` picks the side from it. A falling crate deep in his chest (its rect at
        // (130 ± 14, 136…164)) is still met from below (the gaps) — crushed; one at (106…134, 137…165) is met from his
        // right — shoved, not crushed.
        for (dx, dy, crushed) in [(116, 136, true), (106, 137, false)] {
            let (s, id) = try target()
            let w = s.world
            w.active.update(id: id) { m in
                m.vx = 0
                m.vy = 0
                m.groundKind = 0
                m.hotRect = IdleSprites.Rect(top: 0x73, left: 0x58, bottom: 0xd2, right: 0xac)
            }
            let m0 = try slot(w, id)
            let crate = try XCTUnwrap(Warrior.newCrate(w, x: m0.x + dx, y: m0.y + dy))
            w.active.update(id: crate) { $0.vy = 0x300 }
            FerazelSession.hitCallback(w, id, crate)
            XCTAssertEqual(try slot(w, id).hp, crushed ? 1800 : 2000, "crate at (\(dx), \(dy))")
            XCTAssertEqual(try slot(w, crate).dead, crushed)
            if !crushed { XCTAssertEqual(try slot(w, id).x, m0.x + 134 - 0x58, "pushed out to the crate's right") }
        }
    }

    // MARK: - 13

    func testChiefKillTailAndGate() throws {
        // `.KillChief` (M l. 75502–75532), the Kill proc `+0x50` (`EnemyCommon.killProc`): the count head, `+0xe9 = 1`,
        // `+0xea = 1`; with `+0x170 ≠ 0` the boss-kill tail — snd 453 pitched (1, 0x100, +0xe, 48000; no draw), the shake
        // 0x1e, the flash 3, "no boss alive" 1. No score.
        let (_, s, id) = try ready()
        let w = s.world
        let me = try slot(w, id)
        XCTAssertTrue(me.countedInTotals)
        XCTAssertEqual(w.arena.noBossAlive, 0, "his Setup cleared it")
        let live0 = w.enemies.live, stat0 = w.globals.achieved[0][w.levelIndex], score0 = w.globals.score
        let seed0 = w.rng.seed
        w.player.cues = []
        w.shakeStore = nil
        w.flash.count = 0
        EnemyCommon.killProc(w, id: id)
        var k = try slot(w, id)
        XCTAssertEqual([k.dead, k.killedForGood], [true, true], "`+0xe9 = 1`, `+0xea = 1`")
        XCTAssertEqual(w.enemies.live, live0 - 1)
        XCTAssertEqual(w.globals.achieved[0][w.levelIndex], stat0 + 1)
        XCTAssertEqual(w.globals.score, score0, "no score")
        let thunder = PlayerCue(call: .threeDPitched, snd: 453, priority: 1, volume: 0x100, position: me.centre,
                                rate: 48000)
        XCTAssertEqual(w.player.cues, [thunder])
        XCTAssertEqual(w.shakeStore, 0x1e)
        XCTAssertEqual(w.flash.count, 3)
        XCTAssertEqual(w.arena.noBossAlive, 1)
        XCTAssertEqual(w.rng.seed, seed0, "no draw")
        // 3.10 item 30: a second call counts nothing but replays the tail.
        w.player.cues = []
        w.shakeStore = nil
        w.flash.count = 0
        w.arena.noBossAlive = 0
        EnemyCommon.killProc(w, id: id)
        k = try slot(w, id)
        XCTAssertEqual(w.enemies.live, live0 - 1, "counted once")
        XCTAssertEqual(w.globals.achieved[0][w.levelIndex], stat0 + 1)
        XCTAssertEqual(w.player.cues, [thunder], "the tail replays")
        XCTAssertEqual([Int(w.shakeStore ?? 0), Int(w.flash.count), Int(w.arena.noBossAlive)], [0x1e, 3, 1])
        // p4 = 0 (`+0x170 == 0`): the count and the flags, no tail.
        let (_, p, pid) = try ready()
        p.world.active.update(id: pid) { $0.classWord170 = 0 }
        let plive = p.world.enemies.live
        p.world.player.cues = []
        p.world.shakeStore = nil
        p.world.flash.count = 0
        EnemyCommon.killProc(p.world, id: pid)
        XCTAssertEqual([try slot(p.world, pid).dead, try slot(p.world, pid).killedForGood], [true, true])
        XCTAssertEqual(p.world.enemies.live, plive - 1)
        XCTAssertEqual(p.world.player.cues, [])
        XCTAssertNil(p.world.shakeStore)
        XCTAssertEqual([Int(p.world.flash.count), Int(p.world.arena.noBossAlive)], [0, 0])

        // Through the level runner: the real Kill opens level 18's gate — 2940 record 0 (x 628, y 520, p1 −1) rises from
        // the next gate Handle — and the loop rule fades to track 30. The player stands near the gate (start (700, 500)).
        let L = try LevelFile.load(from: try LevelFixture.base.get(), level: 18)
        let g = L.placements[0]
        XCTAssertEqual([g.type, g.p1, g.x, g.y], [2940, -1, 628, 520], "the gate (card: x 628)")
        let run = try LevelFixture.open(level: 18, leaveOut: Self.level18, start: (700, 500))
        var t: UInt32 = 0
        var plays: [Int] = []
        func tick(_ n: Int) throws {
            let goal = run.iterations + n
            var guardTicks = 0
            while run.iterations < goal && guardTicks < 20_000 {
                let out = try run.tick(now: t, input: FrontInput())
                t &+= 1
                guardTicks += 1
                plays += out.merged.music.compactMap { if case .play(let n) = $0 { n } else { nil } }
            }
        }
        try tick(20)
        let rs = try XCTUnwrap(run.session)
        XCTAssertTrue(rs.world.arena.locked, "x 700 < 1340: locked")
        let gate = try XCTUnwrap(rs.world.active.sprites.first { $0.recordIndex == 0 }, "the gate active near x 700")
        XCTAssertEqual(gate.y, 520, "shut")
        let cid = try XCTUnwrap(rs.world.active.sprites.first { $0.handler == .chief }?.id, "the Chief awake")
        XCTAssertFalse(plays.contains(30), "no track 30 while he stands")
        EnemyCommon.killProc(rs.world, id: cid)
        XCTAssertEqual(rs.world.arena.noBossAlive, 1)
        try tick(1)
        XCTAssertEqual(try XCTUnwrap(rs.world.active.sprites.first { $0.recordIndex == 0 }).y, 518,
                       "the next gate Handle lifts it 2 px")
        try tick(239)
        XCTAssertLessThan(try XCTUnwrap(rs.world.active.sprites.first { $0.recordIndex == 0 }).y, 520, "the gate rose")
        XCTAssertTrue(plays.contains(30), "the loop rule's track 30")
        XCTAssertEqual(run.music.currentTrack, 30)
    }

    // MARK: - 14

    func testChiefRecordWriteBack() throws {
        // No `+0x18a` (BOS §3.6): `.UpdateSprites` (M l. 4959–4966) copies his type / x / y into his own record (`+0x48`
        // = record 1) at the end of every frame — so a save mid-fight stores where he stands. The Kill's `+0xe9 = 1` clears
        // the record's active flag at the next `.UpdateSprites` (its `+0xe9` 1…3 arm, M l. 4982–5000: record `+4` = 0
        // unless `+0x188`, l. 4995–4997); the `+0xea` arm (l. 4970–4980, taken only while `+0xe9` is 0) is never reached
        // by a killed sprite.
        let (run, s) = try open()
        let w = s.world
        XCTAssertEqual([w.records[1].x, w.records[1].y], [897, 410], "the record as placed")
        var moved = false
        var checked = 0
        while checked < 150 && run.iterations < 3000 {
            try iterate(run, keys: [left])
            guard let c = chief(w) else { continue }
            XCTAssertEqual(c.recordIndex, 1)
            XCTAssertFalse(c.noWriteBack18a)
            let r = w.records[1]
            XCTAssertEqual([Int(r.type), Int(r.x), Int(r.y)], [Int(c.type), c.x, c.y], "frame \(run.iterations)")
            if c.x != 897 || c.y != 410 { moved = true }
            checked += 1
        }
        XCTAssertTrue(moved, "he jumped: the record followed")
        XCTAssertEqual(w.records[1].flag, 1)
        let id = try XCTUnwrap(chief(w)?.id)
        EnemyCommon.killProc(w, id: id)
        XCTAssertTrue(try slot(w, id).killedForGood, "`+0xea = 1`")
        try iterate(run, keys: [left])
        XCTAssertEqual(w.records[1].flag, 0, "cleared by `.UpdateSprites` after the Kill")
    }

    // MARK: - 15

    func testChiefContactAndSmite() throws {
        // `.HitPlayerSprite` step 7: the routing list (M l. 49514–49521) holds the Chief's Handle (0x100a04bc) — the
        // generic path; his damage row 0x70 (M l. 49849–49851), invulnerability 0x3c; damage 0x70 → R(100) > 0x50 → 3
        // coins, drawn before `.HurtPlayer`; then `.HurtPlayer(player, him, 0x70, blood 1, 0x3c, coins)`.
        for band in [0...0x50, 0x51...99] as [ClosedRange<Int16>] {
            let k = seed { g in band.contains(g.next(100)) }
            func make() throws -> (FerazelSession, Int, Int) {
                let (_, s, id) = try ready()
                let pid = try XCTUnwrap(s.world.playerID)
                s.world.active.update(id: pid) { $0.invulnerable = 0 }
                s.world.globals.coins = 20
                s.world.rng = FastRand(seed: k)
                return (s, id, pid)
            }
            let (s, id, pid) = try make()
            let hp0 = try slot(s.world, pid).hp
            var lights = LightTable()
            HitPlayerSprite.hit(s.world, player: pid, other: id, lights: &lights, effects: 1)
            let (t, tid, tpid) = try make()
            let coins: Int16 = 0x50 < t.world.rng.next(100) ? 3 : 0
            HurtPlayer.hurt(t.world, player: tpid, attacker: tid, damage: 0x70, blood: true, invulnerable: 0x3c,
                            coins: coins)
            let p = try slot(s.world, pid), q = try slot(t.world, tpid)
            XCTAssertEqual(s.world.rng.seed, t.world.rng.seed, "band \(band): R(100) first, then the hurt's draws")
            XCTAssertEqual(s.world.globals.coins, t.world.globals.coins)
            XCTAssertEqual([Int(p.hp), Int(p.invulnerable)], [Int(hp0) - 0x70, 0x3c], "band \(band)")
            XCTAssertEqual(s.world.globals.coins < 20, 0x50 < band.lowerBound, "band \(band): coins only above 0x50")
            XCTAssertEqual([q.hp, q.invulnerable], [p.hp, p.invulnerable])
        }
        // The Ring of Smiting (BOS §3.6: `.chief` appended to `Smite.enemyHandlers`; 0x100a04bc is in the walk's 15): a
        // seed at his stored centre − 4. Its hit kills the seed first (`.KillPlayerShot`: snd 435, flash 3, the big
        // explosion), then `.HurtSprite(S, seed +0xa4, …)`. Through one session frame the seed carries `+0xa4` 0: its
        // Setup stores none and its Handle gives it 800 only from age 1 (`PlayerShot.idArm`; age −1 → 0 on this first
        // frame), and it overlaps him at once — so the hurt is refused (damage < 1) and his HP stands. Dump over the
        // contract's "a seed hurts it with its `+0xa4`": the Chief's Hit has no effect arm, so neither the seed nor its
        // explosion hurts him.
        XCTAssertTrue(Smite.enemyHandlers.contains(.chief))
        let (_, s, id) = try ready()
        let c0 = try slot(s.world, id).centre
        let shots0 = Set(s.world.active.sprites.filter { $0.handler == .playerShot }.map(\.id))
        Smite.smiteEnemies(s.world)
        let seeds = s.world.active.sprites.filter { $0.handler == .playerShot && !shots0.contains($0.id) }
        XCTAssertEqual(seeds.map { [Int($0.type), $0.x, $0.y] }, [[Int(PlayerShot.seed), c0.x - 4, c0.y - 4]],
                       "one seed, at his stored centre − 4")
        let seedID = try XCTUnwrap(seeds.first?.id)
        s.world.player.cues = []
        _ = s.step(keys: KeyState())
        let seed = try slot(s.world, seedID)
        XCTAssertTrue(seed.dead, "the seed hit him on its first frame")
        XCTAssertEqual([seed.hp, Int16(seed.classTimer)], [0, 0], "`+0xa4` 0 at age 0")
        XCTAssertTrue(s.world.player.cues.contains { $0.snd == 435 }, "the seed's own kill")
        XCTAssertFalse(s.world.player.cues.contains { $0.snd == 701 || $0.snd == 702 }, "no hurt")
        XCTAssertEqual(try slot(s.world, id).hp, 2000, "the hurt refused: damage 0")
        // An aged seed (`+0xa4` 800, as its Handle sets it from age 1) hurts him by its `+0xa4`: its kill first, then 701.
        let (t, tid) = try target()
        let aged = try shot(t.world, over: tid, type: PlayerShot.seed, damage: 800) { $0.classTimer = 3 }
        t.world.player.cues = []
        FerazelSession.hitCallback(t.world, tid, aged)
        XCTAssertTrue(try slot(t.world, aged).dead)
        XCTAssertEqual(t.world.player.cues.first?.snd, 435, "the seed's own kill first")
        XCTAssertEqual(t.world.player.cues.dropFirst().first?.snd, 701, "then his hurt")
        XCTAssertEqual(t.world.flash.count, 3)
        XCTAssertEqual(try slot(t.world, tid).hp, 2000 - 800, "hurt by the seed's `+0xa4`")
        XCTAssertEqual(try slot(t.world, tid).invulnerable, 15)
    }

    // MARK: - 16

    func testLevel18ArenaBounds() throws {
        // Level 18's arena (BOS §3.6; built at LV5 as `BossArena`): header `+0x2724` v = −1400, `+0x272e` s = −640.
        // `.PlayerConstraints` locks when x < |v + 60| = 1340 (M l. 44045) and clamps x back to 1340 while locked;
        // `.FindUpperLeftCorner` (M l. 5937–6028) bounds the scroll point's h to [lo, hi − 0x260]: locked, hi = 1400 and
        // lo = 1400 − 0x260 while the pan runs, then −32000 raised to |s| = 640 by the second bound — the window [640,
        // 1400], h in 640…792. (Closes the Phase 5 carry "the second camera bound is untested".) v < 0, so the v > 0 arm
        // with its 0x7f60 bound during the pan is never taken on level 18: that carry stays open (no shipped level checked
        // here has v > 0).
        let L = try LevelFile.load(from: try LevelFixture.base.get(), level: 18)
        XCTAssertEqual([L.header.arenaBound, L.header.secondArenaBound], [-1400, -640])
        XCTAssertEqual(BossArena.lockLine(L.header.arenaBound), 1340)
        XCTAssertLessThan(L.header.arenaBound, 0, "the 0x7f60 arm (v > 0) is not reached on level 18")
        var a = BossArena(noBossAlive: 0, locked: true, panCounter: -40)
        var window: [[Int16]] = []
        for _ in 0..<41 {
            let b = a.cameraBounds(arenaBound: L.header.arenaBound, secondBound: L.header.secondArenaBound)
            window.append([b.lo, b.hi])
        }
        let shift39: Int16 = 16 * 39
        XCTAssertEqual(window.first, [1400 - 0x260 + shift39, 1400 + shift39], "the pan: lo = hi − 0x260, shifted")
        XCTAssertEqual(window[39], [1400 - 0x260, 1400], "the pan's last step")
        XCTAssertEqual(window[40], [640, 1400], "after the pan: the second bound raises lo to 640")
        XCTAssertFalse(window.contains { $0[1] == 0x7f60 })

        // Through the level runner, LEFT held from the level start: the lock on the first frame x < 1340; then RIGHT held,
        // x stays ≤ 1340 (clamped) and the scroll point's h ≤ 1400 − 0x260 = 792 once the pan is over.
        let (run, s) = try open()
        let w = s.world
        let pid = try XCTUnwrap(w.playerID)
        var lastX = try slot(w, pid).x
        var lockedAt: Int?
        while lockedAt == nil && run.iterations < 3000 {
            lastX = try slot(w, pid).x
            try iterate(run, keys: [left])
            if w.arena.locked { lockedAt = run.iterations }
        }
        XCTAssertEqual(lockedAt, 111, "measured (seed 1): the lock (`testChiefFirstJumpAfterLock`)")
        XCTAssertGreaterThanOrEqual(lastX, 1340, "not locked the frame before")
        XCTAssertLessThan(try slot(w, pid).x, 1340, "locked on the first frame x < 1340")
        XCTAssertEqual(w.arena.panCounter, -40)
        let right = Int(FerazelPrefs().keys[1])
        var xs: [Int] = [], hs: [Int] = []
        for _ in 0..<60 {
            try iterate(run, keys: [right])
            xs.append(try slot(w, pid).x)
            hs.append(s.camera.scrollH)
        }
        XCTAssertTrue(xs.allSatisfy { $0 <= 1340 }, "clamped at the lock line: \(xs)")
        XCTAssertTrue(xs.contains(1340), "pushed against it")
        XCTAssertTrue(hs.suffix(15).allSatisfy { $0 <= 1400 - 0x260 }, "h ≤ 792 after the pan: \(hs.suffix(15))")
        // Started at the far left (x 100, the arena locked at once): the second bound holds h at 640 after the pan.
        let left18 = try LevelFixture.open(level: 18, leaveOut: Self.level18, start: (100, 500))
        now = 0
        while left18.iterations < 60 { _ = try left18.tick(now: now, input: FrontInput()); now &+= 1 }
        let ls = try XCTUnwrap(left18.session)
        XCTAssertTrue(ls.world.arena.locked)
        XCTAssertEqual(ls.world.arena.panCounter, 0, "the pan is over")
        XCTAssertEqual(ls.camera.scrollH, 640, "the second bound: h ≥ |s| = 640")
    }
}

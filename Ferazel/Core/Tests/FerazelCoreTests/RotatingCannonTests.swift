import XCTest
@testable import FerazelCore

/// 6A-RC (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-RC`; docs/ferazel/phase6-engine-contracts.md
/// §2.3): the cannons 0x442…0x44a with record p1 101…106 — the Setup's p1 ≥ 1 arm (M l. 62120–62170), the Handle's
/// rotation (M l. 62983–63021) and the shot steering of `.HitBackgroundSprite` (M l. 63689–63709). Synthetic cannons
/// on level 1's world (no cannon there has p1 ≠ 0), each made per record through `SetupFaces.setup` with its write-back
/// put into the live record table by this file's `cannon` helper, as `.SetupLevelSprites` leaves it (the real
/// write-back, `SetupFaces.spawnLevelSprites`, is driven in `testCannon105WritesRecordP2`). A missing data file is a
/// FAILURE, never a skip.
final class RotatingCannonTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    /// `*_DAT_100a0308` = 485, the pause's click; `*_DAT_100a041c` = 303, the steering hit's clank (`SoundSlots`).
    private static let click: Int16 = 485, clank: Int16 = 303

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Level 1's world, nothing in it.
    private func world() throws -> SpriteWorld {
        SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
    }

    private func rec(_ type: Int16 = 1090, p1: Int16, p2: Int16 = 0, p3: Int16 = 0, p4: Int16 = 0, index: Int = 7,
                     x: Int16 = 400, y: Int16 = 600) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: p4, y: y, x: x)
    }

    /// The cannon of record `p` set up (`SetupFaces.setup`), its record as the Setup wrote it put into the live table
    /// (`*_DAT_100a0058`, where the Handle and the hit read p1 and p2), and inserted.
    private func cannon(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0))
        w.records[p.index] = e.record
        return w.active.insert(e.slot)
    }

    private static func width(_ f: FaceRef) -> Int { 0x80 }

    /// One `.HandleBackgroundSprite` of the cannon; its slot after.
    @discardableResult
    private func handle(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot {
        BackgroundSprite.handle(world: w, id: id, faceWidth: Self.width)
        return try XCTUnwrap(w.active.sprite(id: id))
    }

    /// A player shot of id `type` (power 1) at (2000, 1000) moving `vx` (the `BackgroundMoverTests` spring shot).
    private func shot(_ w: SpriteWorld, _ type: Int16, vx: Int32) -> Int {
        var s = SpriteSlot(type: type, x: 2000, y: 1000)
        s.handler = .playerShot
        s.power = 1
        s.vx = vx
        s.vy = 0x100
        s.hotRect = Rect(top: 3, left: 8, bottom: 0xc, right: 0xf)
        return w.active.insert(s)
    }

    /// The effect 0's Setup draws (`.SetupEffectSprite` kind 0: 45 × (R(2000), R(2000), R(2))).
    private func explosionPackage(_ r: inout FastRand) {
        for _ in 0..<0x2d { _ = r.next(2000); _ = r.next(2000); _ = r.next(2) }
    }

    // MARK: - the Setup (M l. 62120–62170)

    func testRotatingCannonSetupFields() throws {
        let w = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        // (p1, p3) → `+0x158` the turn length, `+0x15c` the step, `+0x160` the counter (= `+0x158`): p3 0 → 4, 1 → 8,
        // 2 → 16, any other keeps the first store's 4; 101 → +1, 102 → −1, 103 → +2, 104 → −2, 105 / 106 → 0; a step ≠ 0
        // divides the length by |step| (C division).
        let rows: [(p1: Int16, p3: Int16, length: Int32, step: Int32)] = [
            (101, 0, 4, 1), (101, 1, 8, 1), (101, 2, 16, 1), (101, 3, 4, 1), (101, -1, 4, 1),
            (102, 0, 4, -1), (102, 1, 8, -1), (102, 2, 16, -1),
            (103, 0, 2, 2), (103, 1, 4, 2), (103, 2, 8, 2), (103, 7, 2, 2),
            (104, 0, 2, -2), (104, 1, 4, -2), (104, 2, 8, -2),
            (105, 0, 4, 0), (105, 1, 8, 0), (105, 2, 16, 0), (105, 9, 4, 0),
            (106, 0, 4, 0), (106, 1, 8, 0), (106, 2, 16, 0),
        ]
        for r in rows {
            let e = try SetupFaces.setup(rec(1092, p1: r.p1, p2: 9, p3: r.p3), context: c)
            let s = e.slot
            XCTAssertEqual([s.classWord158, s.classWord15c, s.classWord160], [r.length, r.step, r.length],
                           "p1 \(r.p1) p3 \(r.p3)")
            // `+0xa6` = the record's p2 as the Setup leaves it: 105 writes 4 first (M l. 62122–62128).
            XCTAssertEqual(s.counterA6, r.p1 == 105 ? 4 : 9, "p1 \(r.p1)")
            // The common part before the arm (M l. 62061–62066) and the tail after it (M l. 62171–62182), as p1 0.
            XCTAssertEqual([Int(s.phase), Int(s.layer), Int(s.classTimer), Int(s.classWord150), Int(s.classWord154),
                            Int(s.hp), Int(s.classWord16c)], [8, 1000, 400, 600, 0, 6, 0])
            XCTAssertEqual(s.hotRect, Rect(top: 0x38, left: 0x35, bottom: 0x5b, right: 0x61))
            XCTAssertEqual([s.hasHit, s.hasTileHit], [true, false])
            XCTAssertEqual(s.handler, .background)
            XCTAssertEqual([s.x256, s.y256], [400 << 8, 600 << 8])
            XCTAssertEqual(e.spawn, .idle)
            XCTAssertEqual([Int(e.faceIndex)], [0])
            XCTAssertEqual(e.source, .handle)
        }
        // `+0x164` the launch speed = the record's p4 (i16, sign-extended), 0 → 9000, 1 → 0x1c20 (M l. 62162–62169) — the
        // p1 0 arm takes 9000 whatever p4 holds (M l. 62114).
        for (p4, speed): (Int16, Int32) in [(0, 9000), (1, 0x1c20), (2, 2), (7000, 7000), (-5, -5)] {
            XCTAssertEqual(try SetupFaces.setup(rec(p1: 101, p4: p4), context: c).slot.launchSpeed, speed, "p4 \(p4)")
            XCTAssertEqual(try SetupFaces.setup(rec(p1: 0, p4: p4), context: c).slot.launchSpeed, 9000, "p1 0, p4 \(p4)")
        }
        // The water test of the tail on the rotating arm too: L1 cell (188, 17) is kind 201.
        XCTAssertEqual(try SetupFaces.setup(rec(p1: 103, x: 188 * 32, y: 17 * 32), context: c).slot.classWord16c, 1)
        // A p2 read as an i16: a negative pause stays negative.
        XCTAssertEqual(try SetupFaces.setup(rec(p1: 101, p2: -3), context: c).slot.counterA6, -3)
        // The p1 0 arm is untouched: no rotating field written (`+0xa6` keeps the common part's 3).
        let still = try SetupFaces.setup(rec(p1: 0, p2: 9, p3: 2), context: c).slot
        XCTAssertEqual([still.classWord158, still.classWord15c, still.classWord160, Int32(still.counterA6)], [0, 0, 0, 3])
    }

    func testCannon105WritesRecordP2() throws {
        let w = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        // p1 105, or p1 106 with record p2 0 → record p2 = 4, written into the level record (M l. 62122–62126); `+0xa6`
        // is then read back from the record (M l. 62127–62128).
        let rows: [(p1: Int16, p2: Int16, written: Int16)] = [
            (105, 0, 4), (105, 9, 4), (105, -2, 4), (106, 0, 4), (106, 9, 9), (106, -2, -2), (101, 0, 0), (103, 0, 0),
            (104, 7, 7),
        ]
        for r in rows {
            let p = rec(p1: r.p1, p2: r.p2, p3: 1, p4: 1)
            let e = try SetupFaces.setup(p, context: c)
            XCTAssertEqual(e.record, Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1,
                                               p2: r.written, p3: p.p3, p4: p.p4, y: p.y, x: p.x), "p1 \(r.p1) p2 \(r.p2)")
            XCTAssertEqual(e.slot.counterA6, r.written)
        }
        // 106 with p2 ≠ 0 keeps it: no write-back at all.
        XCTAssertEqual(try SetupFaces.setup(rec(p1: 106, p2: 9), context: c).record, rec(p1: 106, p2: 9))
        // The shipped 105s: level 15's records 156 and 157 (1090, p1 105, p2 0), per record from the level file.
        let l15 = try LevelFile.load(from: try resources(), level: 15)
        let c15 = SetupFaces.Context(level: l15, playerX: 0)
        for i in [156, 157] {
            let p = l15.placements[i]
            XCTAssertEqual([p.type, p.p1, p.p2, p.p3, p.p4], [1090, 105, 0, 0, 0], "L15 record \(i)")
            let e = try SetupFaces.setup(p, context: c15)
            XCTAssertEqual(e.record.p2, 4, "L15 record \(i)")
            XCTAssertEqual([e.slot.counterA6, Int16(e.slot.classWord158), Int16(e.slot.classWord15c)], [4, 4, 0])
        }
        // Through `.SetupLevelSprites`' own write-back (`SetupFaces.spawnLevelSprites` `out.records[p.index] =
        // e.record`), not this file's `cannon` helper: the live table the level runs on holds 4 for a 105 and a 106
        // with p2 0, and keeps a 106's 9 and a 101's 0.
        let live = [rec(p1: 105, p2: 0, index: 0), rec(p1: 106, p2: 0, index: 1), rec(p1: 106, p2: 9, index: 2),
                    rec(p1: 101, p2: 0, index: 3)]
        let sp = try SetupFaces.spawnLevelSprites(context: SetupFaces.Context(level: w.level, playerX: 0,
                                                                              records: live)) { _ in .noFace }
        XCTAssertEqual(sp.records.map(\.p2), [4, 4, 9, 0])
        XCTAssertEqual(sp.records.map(\.p1), [105, 106, 106, 101])
        XCTAssertEqual(sp.created, [0, 1, 2, 3])
    }

    // MARK: - the Handle (M l. 62983–63021)

    func testRotatingCannonPauseAndStep() throws {
        let w = try world()
        // 101, p2 3, p3 0: the pause `+0xa6` 3 counts down (the click on reaching 0), then 4 frames of +1 each, the
        // counter `+0x160` 4 → 0, and at < 1 the pause again from the record's p2.
        let k = try cannon(w, rec(p1: 101, p2: 3))
        var aims: [Int16] = [], pauses: [Int16] = [], counters: [Int32] = [], clicks: [Int] = []
        for f in 1...16 {
            w.player.cues = []
            w.player.soundCalls = []                       // one `.GameLoop` iteration a frame: its calls are its own
            let s = try handle(w, k)
            aims.append(s.phase)
            pauses.append(s.counterA6)
            counters.append(s.classWord160)
            if w.player.cues.contains(where: { $0.snd == Self.click }) { clicks.append(f) }
        }
        XCTAssertEqual(aims, [0, 0, 0, 1, 2, 3, 4, 4, 4, 4, 5, 6, 7, 8, 8, 8])
        XCTAssertEqual(pauses, [2, 1, 0, 0, 0, 0, 3, 2, 1, 0, 0, 0, 0, 3, 2, 1])
        XCTAssertEqual(counters, [4, 4, 4, 3, 2, 1, 4, 4, 4, 4, 3, 2, 1, 4, 4, 4])
        XCTAssertEqual(clicks, [3, 10])

        // 104 (step −2, length 4 / 2 = 2), p2 1: the aim wraps below 0 into 0…31 (the fold after the arm).
        let w2 = try world()
        let k2 = try cannon(w2, rec(p1: 104, p2: 1))
        var aims2: [Int16] = []
        for _ in 1...9 { aims2.append(try handle(w2, k2).phase) }
        XCTAssertEqual(aims2, [0, 30, 28, 28, 26, 24, 24, 22, 20])
        // The face follows the aim as for p1 0 (built): 28 → face 8 − 7 = 1, mirrored; 30 → face 0 rotated.
        w2.active.update(id: k2) { $0.phase = 28; $0.counterA6 = 5 }
        let f28 = try handle(w2, k2)
        XCTAssertEqual([f28.face?.index, Int(f28.rotation)], [1, 0])
        XCTAssertTrue(f28.mirrored)

        // p2 0: the pause is 0 again at every turn's end — 102 never stops and never clicks.
        let w3 = try world()
        let k3 = try cannon(w3, rec(p1: 102, p2: 0))
        var aims3: [Int16] = []
        w3.player.cues = []
        for _ in 1...10 { aims3.append(try handle(w3, k3).phase) }
        XCTAssertEqual(aims3, [31, 30, 29, 28, 27, 26, 25, 24, 23, 22])
        XCTAssertTrue(w3.player.cues.isEmpty)

        // The pause re-reads the LIVE record's p2 (M l. 62991–62992): changed after the Setup, the next pause is 6.
        let w4 = try world()
        let k4 = try cannon(w4, rec(p1: 101, p2: 0))
        w4.records[7] = rec(p1: 101, p2: 6)
        for _ in 1...4 { try handle(w4, k4) }
        XCTAssertEqual(try XCTUnwrap(w4.active.sprite(id: k4)).counterA6, 6)

        // The captive fires only on an aim that is a multiple of 4 (`.HandleCannonedSprite` M l. 50062–50063): in a 103
        // cannon (p2 1, length 2) the aim moves 0, 2, 4, 4, 6, 8, … — a captive whose hold ends on aim 22 waits a frame.
        // Then the recoil eases home every frame after the step (M l. 63001–63020): 24.8 = (int)(0.8·pos + 0.2·home).
        let w5 = try world()
        let k5 = try cannon(w5, rec(p1: 103, p2: 1))
        for _ in 1...2 { try handle(w5, k5) }
        XCTAssertEqual(w5.active.sprite(id: k5)?.phase, 2)
        let walker = w5.active.insert(SpriteSlot(type: 0x6a4, x: 400, y: 600))
        BackgroundSprite.hit(w5, id: k5, other: walker)
        XCTAssertEqual(w5.active.sprite(id: walker)?.handler, .cannoned)
        XCTAssertEqual(w5.active.sprite(id: k5)?.classWord154, 6)
        var firedAt: Int16?, held: [Int16] = []
        for _ in 1...20 where firedAt == nil {
            let s = try handle(w5, k5)
            BackgroundSprite.handleCannoned(world: w5, id: walker, keys: [])
            let c = try XCTUnwrap(w5.active.sprite(id: walker))
            if c.handler != .cannoned { firedAt = s.phase } else if c.reentry < 1 { held.append(s.phase) }
        }
        XCTAssertEqual(held, [22])
        XCTAssertEqual(firedAt, 24)
        let recoiled = try XCTUnwrap(w5.active.sprite(id: k5))
        XCTAssertNotEqual([recoiled.x256, recoiled.y256], [400 << 8, 600 << 8], "the launch recoils the cannon")
        let eased = try handle(w5, k5)
        XCTAssertEqual(eased.x256, TileSolver.fctiwz(0.8 * Double(recoiled.x256) + 0.2 * Double(400 << 8)))
        XCTAssertEqual(eased.y256, TileSolver.fctiwz(0.8 * Double(recoiled.y256) + 0.2 * Double(600 << 8)))
        XCTAssertEqual([eased.x, eased.y], [SpriteWorld.pixel(eased.x256), SpriteWorld.pixel(eased.y256)])
        XCTAssertEqual(eased.counterA6, 0, "the step ran in the same frame (aim 24 → the pause → its click frame)")

        // A negative pause (record p2 read as an i16) never reaches 0 by the count-down: `+0xa6 == 0` is the turn test
        // (M l. 62985) and `== 0` after the − 1 the click's (M l. 62995–62996) — no turn, no click.
        let w6 = try world()
        let k6 = try cannon(w6, rec(p1: 101, p2: -3))
        w6.player.cues = []
        var neg: [[Int16]] = []
        for _ in 1...4 {
            let s = try handle(w6, k6)
            neg.append([s.phase, s.counterA6])
        }
        XCTAssertEqual(neg, [[0, -4], [0, -5], [0, -6], [0, -7]])
        XCTAssertTrue(w6.player.cues.isEmpty)
    }

    func testRotatingCannonClickNeedsSilentVoice() throws {
        // The pause's end: `FUN_100916dc(485) == 0` → `.STPlay3DSoundRand(485, 1, 0x41, +0xe)` with one R(10000)
        // (M l. 62995–62999; `SoundVoices`); a voice playing 485 → no call and no draw.
        func run(playing: Set<Int16>, earlier: [PlayerCue] = []) throws -> (cues: [PlayerCue], drew: Bool, at: SpriteSlot.Point) {
            let w = try world()
            let k = try cannon(w, rec(p1: 101, p2: 1))
            w.voices = SoundVoices(playing: playing)
            for c in earlier { w.player.cue(c) }
            w.player.cues = []
            let at = try XCTUnwrap(w.active.sprite(id: k)).centre
            let seed = w.rng.seed
            let s = try handle(w, k)
            XCTAssertEqual(s.counterA6, 0)
            return (w.player.cues, w.rng.seed != seed, at)
        }
        let silent = try run(playing: [])
        var r = FastRand(seed: 1)
        XCTAssertEqual(silent.cues, [PlayerCue(call: .threeDRand, snd: Self.click, priority: 1, volume: 0x41,
                                              position: silent.at, rate: r.soundRate())])
        XCTAssertTrue(silent.drew)
        // Another sound playing does not count (485 is a loaded handle: only its own voices).
        XCTAssertEqual(try run(playing: [484, 303]).cues.map(\.snd), [Self.click])
        // 485 playing: no call, no draw.
        let busy = try run(playing: [Self.click])
        XCTAssertTrue(busy.cues.isEmpty)
        XCTAssertFalse(busy.drew)
        // A 485 started earlier in the same iteration counts (the shell set plus the calls since).
        let same = try run(playing: [], earlier: [PlayerCue(call: .threeDRand, snd: Self.click, priority: 1,
                                                             volume: 0x41, position: SpriteSlot.Point(), rate: 0)])
        XCTAssertTrue(same.cues.isEmpty)
        XCTAssertFalse(same.drew)
        // Two cannons ending their pause in one iteration: the second hears the first.
        let w = try world()
        let a = try cannon(w, rec(p1: 101, p2: 1))
        let b = try cannon(w, rec(p1: 103, p2: 1, index: 8))
        w.player.cues = []
        try handle(w, a)
        try handle(w, b)
        XCTAssertEqual(w.player.cues.map(\.snd), [Self.click])
        // The count-down frame that does not reach 0 never asks.
        let w2 = try world()
        let k2 = try cannon(w2, rec(p1: 101, p2: 2))
        w2.player.cues = []
        let seed = w2.rng.seed
        XCTAssertEqual(try handle(w2, k2).counterA6, 1)
        XCTAssertTrue(w2.player.cues.isEmpty)
        XCTAssertEqual(w2.rng.seed, seed)
    }

    func testCannon105DoesNotSelfTurn() throws {
        // 105 / 106 skip the count-down (M l. 62995: `sVar18 != 0x69 && sVar18 != 0x6a` first): the pause never ends
        // by itself — no turn, no click, ever.
        for (p1, p2, pause): (Int16, Int16, Int16) in [(105, 0, 4), (105, 9, 4), (106, 0, 4), (106, 7, 7)] {
            let w = try world()
            let k = try cannon(w, rec(p1: p1, p2: p2))
            w.player.cues = []
            let seed = w.rng.seed
            for _ in 1...300 { try handle(w, k) }
            var s = try XCTUnwrap(w.active.sprite(id: k))
            XCTAssertEqual([Int(s.phase), Int(s.counterA6), Int(s.classWord160)], [0, Int(pause), 4], "p1 \(p1) p2 \(p2)")
            XCTAssertTrue(w.player.cues.isEmpty)
            XCTAssertEqual(w.rng.seed, seed)
            // A shot from the left (vx ≥ 0, aim 0 < 8) steers it +1: `+0x160` = the length, `+0xa6` 0 — it turns 4
            // frames, then pauses again at the record's p2 (4 for 105 and for 106 written from 0), and holds there.
            let sh = shot(w, 100, vx: 0x200)
            BackgroundSprite.hit(w, id: k, other: sh)
            s = try XCTUnwrap(w.active.sprite(id: k))
            XCTAssertEqual([Int(s.classWord15c), Int(s.classWord160), Int(s.counterA6)], [1, 4, 0])
            var aims: [Int16] = []
            for _ in 1...40 { aims.append(try handle(w, k).phase) }
            XCTAssertEqual(aims, [1, 2, 3, 4] + [Int16](repeating: 4, count: 36), "p1 \(p1) p2 \(p2)")
            s = try XCTUnwrap(w.active.sprite(id: k))
            XCTAssertEqual([Int(s.counterA6), Int(s.classWord160)], [Int(pause), 4])
            XCTAssertEqual(w.player.cues.map(\.snd), [Self.clank], "no click: the pause is never counted down")
            // A recoiled 105 / 106 (a captive fired) eases home as the others do (M l. 63001–63020, after the arm):
            // 24.8 x = (int)(0.8·(410 << 8) + 0.2·(400 << 8)) = 408 << 8.
            w.active.update(id: k) { $0.x256 = 410 << 8; $0.x = 410 }
            let e = try handle(w, k)
            XCTAssertEqual([e.x256, Int32(e.x)], [408 << 8, 408], "p1 \(p1)")
        }
    }

    // MARK: - `.HitBackgroundSprite`'s steering (M l. 63689–63709)

    func testShotSteersCannonLeftAndRight() throws {
        // A player shot into a paused 105 / 106: from the right (vx < 0) step −1 unless 12 ≤ aim ≤ 24; from the left
        // (vx ≥ 0, 0 included) step +1 unless 8 ≤ aim ≤ 23; 106 at any aim (M l. 63695–63708).
        func steered(_ p1: Int16, aim: Int16, vx: Int32) throws -> Int32? {
            let w = try world()
            let k = try cannon(w, rec(p1: p1, p2: 0))
            w.active.update(id: k) { $0.phase = aim }
            w.player.cues = []
            var r = w.rng
            let rate = r.soundRate()
            let at = try XCTUnwrap(w.active.sprite(id: k)).centre
            BackgroundSprite.hit(w, id: k, other: shot(w, 100, vx: vx))
            // Every qualifying hit: the clank `.STPlay3DSoundRand(303, 1, 0xab, cannon +0xe)` — one stream draw.
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: Self.clank, priority: 1, volume: 0xab,
                                                     position: at, rate: rate)])
            XCTAssertEqual(w.rng.seed, r.seed)
            let s = try XCTUnwrap(w.active.sprite(id: k))
            XCTAssertEqual(s.phase, aim)
            XCTAssertEqual(s.classWord154, 0, "never cannoned")
            if s.counterA6 == 4 {
                XCTAssertEqual([s.classWord15c, s.classWord160], [0, 4])
                return nil
            }
            XCTAssertEqual([Int(s.counterA6), Int(s.classWord160)], [0, 4])
            return s.classWord15c
        }
        var left: [Int16] = [], right: [Int16] = [], zero: [Int16] = []
        for aim: Int16 in 0...31 {
            if let s = try steered(105, aim: aim, vx: -1) { XCTAssertEqual(s, -1); left.append(aim) }
            if let s = try steered(105, aim: aim, vx: 0x300) { XCTAssertEqual(s, 1); right.append(aim) }
            if let s = try steered(105, aim: aim, vx: 0) { XCTAssertEqual(s, 1); zero.append(aim) }
            XCTAssertEqual(try steered(106, aim: aim, vx: -0x300), -1, "106 aim \(aim)")
            XCTAssertEqual(try steered(106, aim: aim, vx: 0x300), 1, "106 aim \(aim)")
        }
        XCTAssertEqual(left, Array(0...11) + Array(25...31))
        XCTAssertEqual(right, Array(0...7) + Array(24...31))
        XCTAssertEqual(zero, right)

        // `.KillPlayerShot(shot, 0, 1)` (M l. 63692): no sound, the effect — a fire shot (id 0) dies with no 301, its
        // effect 0 made (its Setup's draws first), then the clank's draw.
        let w = try world()
        let k = try cannon(w, rec(p1: 105, p2: 0))
        let fire = shot(w, 0, vx: -0x300)
        w.player.cues = []
        var r = w.rng
        explosionPackage(&r)
        let rate = r.soundRate()
        BackgroundSprite.hit(w, id: k, other: fire)
        XCTAssertEqual(w.active.sprite(id: fire)?.dead, true)
        XCTAssertEqual(w.player.cues.map(\.snd), [Self.clank])
        XCTAssertEqual(w.player.cues.first?.rate, rate)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.active.sprites.filter { $0.handler == .effect && $0.type == 0 }.count, 1)
        XCTAssertEqual(w.active.sprite(id: k)?.classWord15c, -1)
    }

    func testShotSteeringOnlyWhilePaused() throws {
        // `+0xa6 ≠ 0` gates the steering (M l. 63694): a turning 105 takes the shot (killed, the clank) but keeps its
        // step and counter.
        let w = try world()
        let k = try cannon(w, rec(p1: 105, p2: 0))
        BackgroundSprite.hit(w, id: k, other: shot(w, 100, vx: 0x300))
        try handle(w, k)
        var s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.phase), Int(s.counterA6), Int(s.classWord15c), Int(s.classWord160)], [1, 0, 1, 3])
        w.player.cues = []
        BackgroundSprite.hit(w, id: k, other: shot(w, 100, vx: -0x300))
        s = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([Int(s.phase), Int(s.counterA6), Int(s.classWord15c), Int(s.classWord160)], [1, 0, 1, 3])
        XCTAssertEqual(w.player.cues.map(\.snd), [Self.clank])
        XCTAssertEqual(s.classWord154, 0)
        // A negative pause is a pause (`+0xa6 ≠ 0`, M l. 63694): a 106 that kept its record p2 −2 is steered.
        let wn = try world()
        let kn = try cannon(wn, rec(p1: 106, p2: -2))
        BackgroundSprite.hit(wn, id: kn, other: shot(wn, 100, vx: 0x300))
        let sn = try XCTUnwrap(wn.active.sprite(id: kn))
        XCTAssertEqual([Int(sn.classWord15c), Int(sn.classWord160), Int(sn.counterA6)], [1, 4, 0])

        // Anything else that qualifies is cannoned, `+0x154 = 6` (M l. 63711–63713): a walker into a 105; a player shot
        // into a 101…104 cannon (now reachable with a turning cannon) and into a p1 0 one; an idled shot (`+0x4c` 0 is
        // not the shot's Handle) into a 105.
        func cannoned(_ p1: Int16, _ make: (SpriteWorld) -> Int) throws -> Bool {
            let w = try world()
            let k = try cannon(w, rec(p1: p1, p2: 5))
            let o = make(w)
            w.player.cues = []
            BackgroundSprite.hit(w, id: k, other: o)
            let got = w.active.sprite(id: o)?.handler == .cannoned
            XCTAssertEqual(w.active.sprite(id: k)?.classWord154, got ? 6 : 0, "p1 \(p1)")
            XCTAssertEqual(w.player.cues.map(\.snd), got ? [484] : [], "p1 \(p1)")
            XCTAssertEqual(w.active.sprite(id: k)?.counterA6, p1 == 105 ? 4 : (p1 == 0 ? 3 : 5), "p1 \(p1): no steering")
            return got
        }
        XCTAssertTrue(try cannoned(105) { $0.active.insert(SpriteSlot(type: 0x6a4, x: 400, y: 600)) })
        for p1: Int16 in [0, 101, 102, 103, 104] {
            XCTAssertTrue(try cannoned(p1) { self.shot($0, 1, vx: -0x300) }, "a player shot into p1 \(p1)")
        }
        XCTAssertTrue(try cannoned(105) { w in
            let id = self.shot(w, 1, vx: -0x300)
            w.active.update(id: id) { $0.handleCleared = true }
            return id
        })
        // An enemy shot is excluded before the steering test (M l. 63684): nothing.
        XCTAssertFalse(try cannoned(105) { w in
            var e = SpriteSlot(type: 0x46a, x: 400, y: 600)
            e.handler = .enemyShot
            return w.active.insert(e)
        })
    }

    // MARK: - p1 1…100 and > 106 (M l. 62954, 62984)

    func testCannonP1OutsideRangeTakesPath() throws {
        let w = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        // Only 0 and 101…106 set up. `SetupFaces` refuses the path cannons p1 < 0 (6B, ENG §3.1) and p1 1…100 / > 106:
        // no shipped cannon has those (ENG §2.3) — kept refused and pinned here as read (ENG §5), no owner.
        for p1: Int16 in [-2, -1, 1, 50, 100, 107, 200, .max] {
            XCTAssertThrowsError(try SetupFaces.setup(rec(p1: p1), context: c), "p1 \(p1)") {
                XCTAssertEqual($0 as? SetupFaces.Error, .notTranscribed(type: 1090))
            }
        }
        // As read: the Setup's p1 ≥ 1 arm takes them (M l. 62067: `p1 < 1` is the other arm) — length 4, step 0, no
        // record write, no path set up (`+0xf0` stays 0); the Handle's `p1 < 0x65 ∧ ≠ 0` / `> 0x6a` branch runs
        // `.HandleProgrammedPath` (mode 0: nothing) and then 24.8 += v (M l. 62975–62980) — no turn, no pause count, no
        // click, no ease home.
        for p1: Int16 in [1, 50, 100, 107, 200, .max] {
            let wp = try world()
            let p = rec(p1: p1, p2: 3, p3: 1, p4: 1)
            var s = SpriteSlot(type: p.type, x: Int(p.x), y: Int(p.y), recordIndex: Int16(p.index))
            BackgroundSprite.setupCommon(&s)
            let written = BackgroundSprite.setupCannon(&s, record: p, level: wp.level)
            XCTAssertEqual(written, p, "p1 \(p1)")
            XCTAssertEqual([s.classWord158, s.classWord15c, s.classWord160, s.launchSpeed, Int32(s.counterA6),
                            Int32(s.pathMode)], [8, 0, 8, 0x1c20, 3, 0], "p1 \(p1)")
            wp.records[7] = p
            s.vx = 0x180
            s.vy = -0x40
            let k = wp.active.insert(s)
            wp.player.cues = []
            var xs: [Int32] = [], ys: [Int32] = []
            for _ in 1...5 {
                let q = try handle(wp, k)
                XCTAssertEqual([Int(q.phase), Int(q.counterA6), Int(q.classWord160)], [0, 3, 8], "p1 \(p1)")
                XCTAssertEqual([q.x, q.y], [SpriteWorld.pixel(q.x256), SpriteWorld.pixel(q.y256)])
                xs.append(q.x256)
                ys.append(q.y256)
            }
            XCTAssertEqual(xs, (1...5).map { (400 << 8) + 0x180 * Int32($0) }, "p1 \(p1)")
            XCTAssertEqual(ys, (1...5).map { (600 << 8) - 0x40 * Int32($0) }, "p1 \(p1)")
            XCTAssertTrue(wp.player.cues.isEmpty)
        }
        // `.HandleProgrammedPath` runs before the add (M l. 62975): mode 2, direction 1, below `+0x104` → vx +=
        // `+0xfc >> 4` (ProgrammedPath M l. 39384–39468), then 24.8 += that vx in the same frame.
        let wm = try world()
        var sm = SpriteSlot(type: 1090, x: 400, y: 600, recordIndex: 7)
        BackgroundSprite.setupCommon(&sm)
        BackgroundSprite.setupCannon(&sm, record: rec(p1: 107), level: wm.level)
        sm.pathMode = 2
        sm.pathDirection = 1
        sm.pathSpeed = 0x100
        sm.pathHigh = .max
        wm.records[7] = rec(p1: 107)
        let qm = try handle(wm, wm.active.insert(sm))
        XCTAssertEqual([qm.vx, qm.x256], [0x10, (400 << 8) + 0x10])
        // The same velocity on a rotating cannon (101) and a still one (p1 0) never moves it: their arms add no v.
        for p1: Int16 in [0, 101] {
            let wr = try world()
            let k = try cannon(wr, rec(p1: p1, p2: 3))
            wr.active.update(id: k) { $0.vx = 0x180; $0.vy = -0x40 }
            for _ in 1...5 { try handle(wr, k) }
            let q = try XCTUnwrap(wr.active.sprite(id: k))
            XCTAssertEqual([q.x256, q.y256], [400 << 8, 600 << 8], "p1 \(p1)")
            if p1 == 0 {
                // A p1 0 cannon never takes the rotation: its `+0xa6` keeps the common part's 3, no aim change, no click.
                XCTAssertEqual([Int(q.phase), Int(q.counterA6)], [0, 3])
                XCTAssertTrue(wr.player.cues.isEmpty)
            }
        }
    }
}

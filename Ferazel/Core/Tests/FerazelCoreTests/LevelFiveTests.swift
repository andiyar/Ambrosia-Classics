import XCTest
import HectorResources
@testable import FerazelCore

/// LV5 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### LV5`): level 5 "Manditraki Warrior" enterable up
/// to the Warrior's arena — every one of its 32 records sets up (16 types; new: the Warrior 1820 and the decorations
/// 2822, 2826, 2829, 2840, 2841), the arena lock at x 1384 with the camera's 40-frame pan (`BossArena`, bosses §1.3),
/// the gate 2940 (p1 −1) shut while the Warrior is alive, the boss-music rule at both `.GameLoop` sites reading "no
/// boss alive" live, the Warrior (his Handle real since 6A-W1, his ◇ Hit until 6A-W2), and `BuiltLevels = 1...5`.
/// Against the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip.
final class LevelFiveTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func player(_ s: FerazelSession) throws -> SpriteSlot {
        try XCTUnwrap(s.world.playerID.flatMap { s.world.active.record(id: $0) })
    }

    /// The player put at whole-pixel x (both `+0xc` and `+0x14`), standing.
    private func place(_ s: FerazelSession, x: Int) throws {
        let pid = try XCTUnwrap(s.world.playerID)
        s.world.active.update(id: pid) { p in
            p.x = x
            p.x256 = Int32(x) << 8
            p.vx = 0
        }
    }

    func testLevel5SetsUpEveryRecord() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 5)
        XCTAssertEqual(L.activePlacements.count, 32)
        XCTAssertEqual(Set(L.activePlacements.map(\.type)).count, 16)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        var refused: [Int16] = []
        for p in L.activePlacements where (try? SetupFaces.setup(p, context: c)) == nil { refused.append(p.type) }
        XCTAssertEqual(refused, [])
        let sp = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        XCTAssertEqual(sp.created.count, 32)
        // `.SetupLevelSprites`: `fed4 = 0`, `fed0 = 1` (M l. 2016–2019), then the Warrior's Setup (p4 1) clears `fed0`.
        XCTAssertEqual(sp.arena, BossArena(noBossAlive: 0, locked: false, panCounter: 0))

        // The Warrior record 0: type 1820, p1…p4 0 0 0 1, (x 875, y 227) — bosses §1.1.
        let w = L.placements[0]
        XCTAssertEqual([w.type, w.p1, w.p2, w.p3, w.p4, w.x, w.y], [1820, 0, 0, 0, 1, 875, 227])
        // The two `FastRand`s in order: R(10) → `+0xa6`, then R(100) → `+0x17e` = (draw > 50) — the signed-compare idiom
        // (raw 10087a54..10087a68; the card's "< 51" read the first term alone). One seed of each facing.
        for seed: Int32 in [1, 2, 3, 4, 5, 6] {
            var rng = FastRand(seed: seed), expect = FastRand(seed: seed)
            let a6 = expect.next(10), roll = expect.next(100)
            let e = try SetupFaces.setup(w, context: c, rng: &rng)
            XCTAssertEqual(rng.seed, expect.seed, "seed \(seed): exactly two draws")
            XCTAssertEqual(e.slot.counterA6, a6, "seed \(seed)")
            XCTAssertEqual(e.slot.mirrored, 50 < roll, "seed \(seed): roll \(roll)")
        }
        var rolls: Set<Bool> = []
        for seed: Int32 in 1...40 { var g = FastRand(seed: seed); _ = g.next(10); rolls.insert(50 < g.next(100)) }
        XCTAssertEqual(rolls, [false, true], "the seeds above cover both facings")
        // The boundary: a roll of exactly 51 faces right (`+0x17e` 1), exactly 50 does not.
        for want: Int32 in [51, 50] {
            let seed = try XCTUnwrap((Int32(1)...20000).first { k in
                var g = FastRand(seed: k); _ = g.next(10); return g.next(100) == want
            }, "a seed rolling \(want)")
            var rng = FastRand(seed: seed)
            XCTAssertEqual(try SetupFaces.setup(w, context: c, rng: &rng).slot.mirrored, want == 51, "roll \(want)")
        }
        let e = try SetupFaces.setup(w, context: c)
        let s = e.slot
        XCTAssertEqual(e.record.p2, 0x96, "p2 written back 0 → 0x96 (M l. 73056–73059)")
        XCTAssertEqual([e.record.p1, e.record.p3, e.record.p4, e.record.x, e.record.y], [0, 0, 1, 875, 227])
        XCTAssertEqual(s.flashTable, 1, "+0x1b4")
        XCTAssertFalse(s.lightOverlay, "+0x88 = 0 (p4 ≠ 0)")
        XCTAssertEqual(s.classWord170, 1, "+0x170 = p4")
        XCTAssertEqual(s.layer, 12, "+0x80")
        XCTAssertEqual([s.particleOffsetY, s.particleOffsetX], [0, 0], "+0x84 / +0x86")
        XCTAssertEqual([s.x, s.y], [s.oldPosition.x, s.oldPosition.y], "+0xc / +0xa re-seated from +8 / +6")
        XCTAssertEqual([s.oldPosition.x, s.oldPosition.y], [875, 227])
        XCTAssertEqual([s.x256, s.y256], [875 << 8, 227 << 8])
        XCTAssertEqual([s.classWord15c, s.classWord160], [875 - 350, 875 + 350], "+0x15c / +0x160")
        XCTAssertEqual(s.bonusP4, 875, "+0x168 = +0xc (after the HP store)")
        XCTAssertEqual(s.launchSpeed, 0, "+0x164")
        // The four procs: Handle `+0x4c`, hit `+0x5c`, tile callback `+0x1f8`, Kill `+0x50` (the Kill arm of
        // `EnemyCommon.killProc` keys on the Handle and counts for good).
        XCTAssertEqual(s.handler, .warrior)
        XCTAssertEqual([s.hasHit, s.hasTileHit], [true, true])
        XCTAssertTrue(EnemyCounting.killsForGood(s.handler))
        XCTAssertTrue(Smite.isEnemy(s), "a Ring-of-Smiting target (`.SmiteEnemies` lists 0x100a0494)")
        XCTAssertTrue(s.noWriteBack18a, "+0x18a")
        XCTAssertEqual(s.hp, 2000)
        XCTAssertTrue(e.clearsNoBossAlive)
        XCTAssertEqual(s.gravity, 0x122)
        XCTAssertEqual(s.hotRect, IdleSprites.Rect(top: 0x17, left: 0x1a, bottom: 0x3a, right: 0x4a))
        XCTAssertEqual([s.classWord150, s.classTimer], [-1, 0])
        XCTAssertEqual([s.subtype, s.subState, s.phase], [6, 0, 2])
        XCTAssertEqual(s.voicePitch, 0x1e, "+0xf0")
        XCTAssertTrue(s.countedInTotals, "inside the counting window")
        XCTAssertEqual(s.face, FaceRef(pict: 0x71c, index: 0, set: .encoded))
        XCTAssertEqual([e.sheet, e.source] as [AnyHashable?], [Warrior.sheets[0], SetupFaces.FaceSource.setupCached])
        // Layer 12 decides the list place (the Setup runs inside `.MTNewSprite` before the insert): the Warrior (rec 0,
        // spawned before the upgrade 1340 rec 13, layer 1) ends after it — with the caller's layer 0 it would precede it.
        XCTAssertEqual(sp.active.sprites.map(\.type), [1403, 1403, 1403, 1403, 1340, 1820])

        // A synthetic p4 = 0 record: HP 0x4b0, no boss flag, `+0x88` untouched; the spawn leaves "no boss alive" 1.
        let plain = Placement(index: 0, flag: w.flag, byte1: w.byte1, type: w.type, p1: 0, p2: 0, p3: 0, p4: 0, y: w.y,
                              x: w.x)
        let p0 = try SetupFaces.setup(plain, context: c)
        XCTAssertEqual(p0.slot.hp, 0x4b0)
        XCTAssertFalse(p0.clearsNoBossAlive)
        XCTAssertTrue(p0.slot.lightOverlay)
        XCTAssertEqual(p0.slot.classWord170, 0)
        var records = L.placements
        records[0] = plain
        let c0 = SetupFaces.Context(level: L, playerX: c.playerX, records: records)
        XCTAssertEqual(try SetupFaces.spawnLevelSprites(context: c0) { _ in .noFace }.arena.noBossAlive, 1)

        // The session: "no boss alive" 0, the arena unlocked; the enemy total is the Warrior alone; the record
        // write-back reaches the live records.
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 5)
        XCTAssertEqual(session.world.arena, BossArena(noBossAlive: 0, locked: false, panCounter: 0))
        XCTAssertEqual(session.tallies.enemies, 1)
        XCTAssertEqual(session.world.records[0].p2, 0x96)
        // The level-load bar on a fresh cache: the Warrior's three sets 0x71c (8), 0x71d (8), 0x71e (6) — after the
        // Dillo's in registration order — then the decorations 0xb04, 0xb05, 0xb06, 0xb0a, 0xb0d, 0xb18, 0xb19:
        // n = 22 + 7 = 29, q = 58.
        var cache = CachedFaces()
        cache.enterLevel(screenClut: L.header.screenClut)
        let needed = CachedFaces.needed(by: session)
        XCTAssertEqual(needed.sets, [0x71c, 0x71d, 0x71e])
        XCTAssertEqual(needed.singles, [0xb04, 0xb05, 0xb06, 0xb0a, 0xb0d, 0xb18, 0xb19])
        let bars = cache.load(needed: needed)
        XCTAssertEqual(bars.map { $0.0 }, [37, 45, 51] + Array(52...58))
        XCTAssertEqual(Set(bars.map { $0.1 }), [58])
        // The registration order (`.InitSprites` M l. 106–145: …, Crab, Dillo, Warrior, Wizard, …, Floater, …): the
        // Warrior's three sets (`.InitWarriorSprite` M l. 72982–72984) right after the Dillo's last (0x751, LL §6 set
        // #54) and before the Wizard's first (0x727, #58); 6A-CF: the Wizard, Chief, Demon and Xichra records (#58–#84)
        // sit between them and the Floater's first (0x6f4, #85), after Xichra's last (0x7b9, #84).
        let picts = CachedFaces.sets.map(\.pict)
        let dillo = try XCTUnwrap(picts.firstIndex(of: 0x751))
        XCTAssertEqual(Array(picts[dillo...dillo + 4]), [0x751, 0x71c, 0x71d, 0x71e, 0x727])
        XCTAssertEqual(CachedFaces.sets[dillo + 1...dillo + 3].map(\.faces), [8, 8, 6])
        XCTAssertEqual(Array(picts[dillo + 30...dillo + 31]), [0x7b9, 0x6f4])

        // The Warrior hurts on contact: `.HitPlayerSprite` step 7, the generic path — 0x70 damage, invulnerability 60.
        let pid = try XCTUnwrap(session.world.playerID)
        let wid = try XCTUnwrap(session.world.active.sprites.first { $0.type == 1820 }?.id)
        session.world.active.update(id: pid) { p in p.hp = 0x300; p.invulnerable = 0 }
        HitPlayerSprite.hit(session.world, player: pid, other: wid)
        let hurt = try player(session)
        XCTAssertEqual([hurt.hp, hurt.invulnerable], [0x300 - 0x70, 0x3c], "the Warrior's contact damage")

        // No spawn refused for want of a record (known deviation 6's diagnostic): a fresh session's first 30 frames,
        // the Warrior's three crates among them.
        let run = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 5)
        for _ in 0..<30 { _ = run.step(keys: KeyState()) }
        XCTAssertEqual(run.world.refusedSpawns, 0)
    }

    func testArenaLocksAtX1384() throws {
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 5)
        XCTAssertEqual(BossArena.lockLine(-1444), 1384)
        // Before the lock, boss alive: the scroll's lower bound is |−1444| = 1444 (M l. 5941–5948); the map clamp
        // (32·64 − 0x280 = 1408) wins, so the view stays at the right edge.
        var probe = s.world.arena
        XCTAssertEqual(probe.cameraBounds(arenaBound: -1444, secondBound: 0).lo, 1444)
        for _ in 0..<5 { _ = s.step(keys: KeyState()) }
        XCTAssertEqual(s.camera.scrollH, 1408)
        // `.PlayerConstraints`' test is x < 1384 (M l. 44045): 1384 is not past the line, 1383 is.
        var line = s.world.arena
        XCTAssertNil(line.playerConstraints(arenaBound: -1444, x: 1384))
        XCTAssertEqual(line, s.world.arena, "x 1384: no lock")
        XCTAssertNil(line.playerConstraints(arenaBound: -1444, x: 1383))
        XCTAssertEqual(line, BossArena(noBossAlive: 0, locked: true, panCounter: -40), "x 1383: locked, the pan armed")
        XCTAssertFalse(s.world.arena.locked)
        try place(s, x: 1383)
        _ = s.step(keys: KeyState())
        XCTAssertTrue(s.world.arena.locked)
        XCTAssertEqual(s.world.arena.panCounter, -40, "stored by `.PlayerConstraints` after this frame's camera call")
        // The pan counter −40 → 0 over 40 frames (one step per `.FindUpperLeftCorner`); the player clamped at x ≤ 1384.
        var counts: [Int16] = []
        for k in 0..<40 {
            if k == 10 { try place(s, x: 1500) }
            _ = s.step(keys: KeyState())
            counts.append(s.world.arena.panCounter)
            if k == 10 {
                let p = try player(s)
                XCTAssertEqual([p.x, Int(p.x256)], [1384, 1384 << 8], "clamped to the lock line")
            }
        }
        XCTAssertEqual(counts, (1...40).map { Int16(-40 + $0) })
        _ = s.step(keys: KeyState())
        XCTAssertEqual(s.world.arena.panCounter, 0)
        XCTAssertTrue(s.world.arena.locked, "the lock stays (the second lock arm does not re-arm the pan)")
    }

    func testCameraWindowWhileLocked() throws {
        // `.FindUpperLeftCorner`'s bounds while locked (v −1444, no second bound): the pan counter read before the step
        // picks lo = 1444 − 0x260 (< 0) or −32000; hi = 1444; then both shift by 16·|counter after the step|.
        var a = BossArena(noBossAlive: 0, locked: true, panCounter: -40)
        var seen: [[Int16]] = []
        for _ in 0..<40 {
            let b = a.cameraBounds(arenaBound: -1444, secondBound: 0)
            seen.append([b.lo, b.hi, a.panCounter])
        }
        XCTAssertEqual(seen, (1...40).map { k in
            let shift = Int16(16 * (40 - k))
            return [1444 - 0x260 + shift, 1444 + shift, Int16(-40 + k)]
        })
        XCTAssertEqual(seen.last, [1444 - 0x260, 1444, 0])
        let after = a.cameraBounds(arenaBound: -1444, secondBound: 0)
        XCTAssertEqual([after.lo, after.hi], [-32000, 1444])
        // No boss (`fed0` 1) or no arena: the open bounds, the pan still steps.
        var open = BossArena(noBossAlive: 1, locked: true, panCounter: -2)
        let o = open.cameraBounds(arenaBound: -1444, secondBound: 0)
        XCTAssertEqual([o.lo, o.hi, open.panCounter], [-32000 + 16, 32000 + 16, -1])

        // In a level-5 session: locked at x 1383, the scroll point's h is forced to lo = hi − 0x260 during the pan
        // (under the map clamp 1408), and stays ≤ 1444 − 0x260 = 836 after it.
        let s = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 5)
        try place(s, x: 1383)
        _ = s.step(keys: KeyState())
        XCTAssertTrue(s.world.arena.locked)
        var hs: [Int] = []
        for _ in 0..<40 {
            _ = s.step(keys: KeyState())
            hs.append(s.camera.scrollH)
        }
        XCTAssertEqual(hs, (1...40).map { k in min(1408, 1444 - 0x260 + 16 * (40 - k)) })
        for _ in 0..<60 {
            _ = s.step(keys: KeyState())
            XCTAssertLessThanOrEqual(s.camera.scrollH, 1444 - 0x260)
        }
    }

    func testGateStaysShutWhileBossAlive() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 5)
        let g = L.placements[4]
        XCTAssertEqual([g.type, g.p1, g.x, g.y], [2940, -1, 416, 265])
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 5)
        func gate() throws -> SpriteSlot {
            try XCTUnwrap((s.world.active.sprites + s.world.idle.entries.compactMap { $0?.saved })
                .first { $0.recordIndex == 4 })
        }
        // The gate idles off-screen at the start; wake the whole level near it: the player at x 1383 locks the arena,
        // then stands by the gate (the clamp only pushes back right of the line).
        try place(s, x: 1383)
        _ = s.step(keys: KeyState())
        XCTAssertTrue(s.world.arena.locked)
        try place(s, x: 470)
        for _ in 0..<120 { _ = s.step(keys: KeyState()) }
        let shut = try gate()
        XCTAssertTrue(s.world.active.sprites.contains { $0.recordIndex == 4 }, "the gate is active near the player")
        XCTAssertEqual(shut.y, 265, "shut: no rise while the Warrior's Setup holds `fed0` at 0")
        XCTAssertEqual(Int(shut.classWord158), 265)
        XCTAssertEqual(s.world.arena.noBossAlive, 0)
        XCTAssertTrue(s.world.arena.locked)
    }

    func testSyntheticKillOpensGateAndTrack30() throws {
        let r = try resources()
        // (1) The session: a synthetic `fed0 = 1` (what `.KillWarrior` stores, M l. 73492) — the gate rises 2 px a
        // frame to 100 px above `+0x158`; the arena lets go (no clamp, open camera bounds).
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 5)
        try place(s, x: 1383)
        _ = s.step(keys: KeyState())
        try place(s, x: 470)
        for _ in 0..<60 { _ = s.step(keys: KeyState()) }
        s.world.arena.noBossAlive = 1
        var ys: [Int] = []
        for _ in 0..<60 {
            _ = s.step(keys: KeyState())
            ys.append(try XCTUnwrap(s.world.active.sprites.first { $0.recordIndex == 4 }).y)
        }
        XCTAssertEqual(ys, (1...60).map { max(265 - 2 * $0, 165) })
        XCTAssertNil(s.world.arena.playerConstraints(arenaBound: -1444, x: 1500), "no clamp with no boss alive")
        var released = s.world.arena
        let b = released.cameraBounds(arenaBound: -1444, secondBound: 0)
        XCTAssertEqual([b.lo, b.hi], [-32000, 32000])
        try place(s, x: 1500)
        _ = s.step(keys: KeyState())
        XCTAssertEqual(try player(s).x, 1500, "the arena let go")

        // (2) The flow: level 5 starts on its own track 23 (the Warrior cleared `fed0` before the loop) and the loop
        // rule never fires; with `fed0` = 1 the level's track fades out over 60 frames (`FadeAIFFMusicAsync(0, 60)`),
        // then track 30 starts and fades in.
        let rig = Rig(r, start: 5)
        rig.newGame(level: 5)
        XCTAssertEqual(rig.plays, [23])
        rig.drive { f in (f.levelRun?.iterations ?? 0) >= 120 }
        XCTAssertEqual(rig.plays, [23], "no boss-music rule while the Warrior stands")
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 23)
        let full = MusicFade.fullVolume(FerazelPrefs())
        XCTAssertEqual(Int(run.music.volume), full)
        run.session?.world.arena.noBossAlive = 1
        let before = rig.music.count
        rig.drive { _ in rig.plays.count > 1 }
        let cues = Array(rig.music[before...])
        let out = cues.prefix { $0 != .play(track: 30) }
        XCTAssertEqual(out.first, .volume(full), "the async fade-out's arming store (V)")
        XCTAssertEqual(Array(out.suffix(2)), [.volume(0), .stop], "faded out, then `SetAIFFMusic(30)`'s shut-down")
        XCTAssertEqual(rig.plays, [23, 30])
        XCTAssertEqual(run.music.currentTrack, 30)
        rig.drive { _ in run.music.asyncDone }
        XCTAssertEqual(Int(run.music.volume), full, "track 30 faded in")
        XCTAssertEqual(rig.plays, [23, 30], "the rule stops at track 30")
        // The rule's "track ≠ 0x1e" test holds it there: 80 more frames (longer than a 60-frame fade-out and the
        // restart after it) and track 30 is not played again.
        let settled = run.iterations
        rig.drive { _ in run.iterations >= settled + 80 }
        XCTAssertEqual(rig.plays, [23, 30], "track 30 is not re-played")
        XCTAssertEqual(run.music.currentTrack, 30)
        XCTAssertEqual(Int(run.music.volume), full)

        // (3) The level start with `fed0` = 1 (a visit where no Warrior clears it) picks track 30: set it after the
        // session is built (`.SetupLevel`) and before `.GameLoop`'s music store (M l. 5218–5221).
        let again = Rig(r, start: 5)
        again.drive { $0.state == .mainMenu }
        again.drive({ _ in [0x2d] }) { _ in true }
        again.drive { f in f.levelRun?.session != nil }
        XCTAssertEqual(again.plays, [])
        again.flow.levelRun?.session?.world.arena.noBossAlive = 1
        again.drive { f in (f.levelRun?.iterations ?? 0) >= 2 }
        XCTAssertEqual(again.plays, [30])
    }

    func testBuiltLevelsFive() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5])
        XCTAssertEqual(BuiltLevels.notBuiltReport(10), "Level 10 is not built yet (Phase 6).")
        let r = try resources()
        // `startLevel` 5 (the hidden `FerazelLevel` switch) is accepted: New Game at level 5, nothing asked.
        let rig = Rig(r, start: 5)
        rig.newGame(level: 5)
        XCTAssertEqual(rig.flow.levelNumber, 5)
        XCTAssertEqual(rig.levels.prepared, [5])
        XCTAssertEqual(rig.asked, [])
        let run = try XCTUnwrap(rig.flow.levelRun)
        let s = try XCTUnwrap(run.session)
        XCTAssertEqual(s.world.arena.noBossAlive, 0)
        // OX's owed pins on a real level-5 run: the renderer's turn-on once, at the level's set-up (before the level
        // start's grid redraws, which follow the player spawn), the update op on every drawn frame, the on-flag set.
        let turnOns = rig.draws.indices.filter { if case .omniPx(.turnOn(omniPxMode: 2)) = rig.draws[$0] { true } else { false } }
        XCTAssertEqual(turnOns.count, 1)
        let firstRedraw = rig.draws.firstIndex { if case .redrawEntireScrollGrid = $0 { true } else { false } }
        XCTAssertLessThan(try XCTUnwrap(turnOns.first), try XCTUnwrap(firstRedraw))
        // … and between the load bars as `.SetupLevel` runs them: `.LoadCachedSpriteFaces`' last bar (its 100 %, M l.
        // 73864; M l. 2537), then `.SetupOmniPx(0)` (M l. 2540), then `.SetupLevel`'s own 100 % (M l. 2569) — the last
        // load bar of the level start.
        let full = try XCTUnwrap(StageScreens.updateStageLoad(100, of: 100).draws.first)
        let bars = rig.draws.indices.filter { k in
            if case .fillRect(left: 0xac, top: 0xd5, right: _, bottom: 0xe0, rgb: _) = rig.draws[k] { true } else { false }
        }
        let on = try XCTUnwrap(turnOns.first), lastBar = try XCTUnwrap(bars.last)
        XCTAssertEqual(lastBar, on + 1, "M l. 2569's bar is the one draw after the turn-on, and the last bar")
        XCTAssertEqual([rig.draws[on - 1], rig.draws[lastBar]], [full, full])
        XCTAssertEqual(bars.filter { $0 < on }.last, on - 1, "the cache's last bar right before the turn-on")
        XCTAssertLessThan(lastBar, try XCTUnwrap(firstRedraw))
        let drawn = run.lastSteps.filter(\.drawn)
        XCTAssertFalse(drawn.isEmpty)
        for ops in drawn {
            XCTAssertEqual(ops.draws.filter { if case .omniPx(.update) = $0 { true } else { false } }.count, 1)
        }
        XCTAssertEqual(s.globals.omniPxActive, 1)
        // Level 5's exit p1 1 (record 26, x −93, beyond the gate) → node 10 → Return → "Level 10 is not built yet
        // (Phase 6)." and no level run; the level's end turned OmniPx off and killed it, and its counter runs on.
        let exit = try LevelFile.load(from: r, level: 5).placements[26]
        XCTAssertEqual([exit.type, exit.p1, exit.x], [3249, 1, -93])
        // The pan counter `_DAT_1009ff9c` runs on across the level exit (only `.InitGameGlobals` zeroes it, M l. 806):
        // armed far below 0 here, still counting up when the level ends.
        s.world.arena.panCounter = -1000
        try rig.exit(26, toNode: 10)
        XCTAssertEqual(rig.asked.last, .report(text: "Level 10 is not built yet (Phase 6)."))
        XCTAssertNil(rig.flow.levelRun)
        XCTAssertEqual(s.globals.omniPxActive, 0, "`.TurnOffOmniPx` at the level's end")
        XCTAssertTrue(s.omniPx.faces.allSatisfy { $0 == nil }, "`.KillOmniPx` at the level's end")
        XCTAssertGreaterThan(s.omniPx.counter, 0)
        XCTAssertEqual(rig.flow.levelCarry.omniPxCounter, s.omniPx.counter)
        XCTAssertEqual(rig.levels.prepared, [5])
        // The pan counter left at the exit is the flow's carry and the next level's session starts on it; New Game's
        // `.InitGameGlobals` zeroes it (M l. 806, 822).
        XCTAssertLessThan(s.world.arena.panCounter, 0)
        XCTAssertEqual(rig.flow.levelCarry.panCounter, s.world.arena.panCounter)
        let next = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 5, carry: rig.flow.levelCarry)
        XCTAssertEqual(next.world.arena.panCounter, s.world.arena.panCounter)
        rig.flow.initGameGlobals()
        XCTAssertEqual(rig.flow.levelCarry.panCounter, 0)
    }

    // MARK: - the flow

    private final class NoFiles: FrontFiles {
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { throw SavedGameError.notASavedGame }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    private final class Levels: LevelServices {
        var prepared: [Int] = []
        func prepare(level: Int) throws -> LevelFaces { prepared.append(level); return LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    /// A flow with the hidden `FerazelLevel` switch at `start`, collecting the dialogs, draws and music cues it puts out.
    private final class Rig {
        let levels = Levels()
        let flow: GameFlow
        var t: UInt32 = 1000
        var asked: [FerazelDialog] = []
        var draws: [DrawOp] = []
        var music: [MusicCue] = []
        var plays: [Int] { music.compactMap { if case .play(let n) = $0 { n } else { nil } }.filter { $0 != 0 } }
        init(_ r: FerazelResources, start: Int) {
            flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: NoFiles(), levels: levels)
            flow.startLevel = start
        }
        func drive(_ keys: (GameFlow) -> [Int] = { _ in [] }, until: (GameFlow) -> Bool) {
            for _ in 0..<6000 {
                if case .loading = flow.state { flow.loadFinished() }
                let out = flow.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys(flow))))
                asked += out.requests.compactMap { if case .dialog(let d) = $0 { return d }; return nil }
                if flow.levelRun != nil {
                    draws += out.draws
                    music += out.music
                }
                t &+= 1
                if until(flow) { return }
            }
            XCTFail("the flow did not reach the condition (state \(flow.state))")
        }
        func newGame(level n: Int) {
            drive { $0.state == .mainMenu }
            drive({ _ in [0x2d] }) { _ in true }
            drive { f in f.levelRun?.levelNumber == n && (f.levelRun?.iterations ?? 0) >= 45 }
        }
        /// The level's exit `record` touched → the map's auto-walk to the node of `level` → Return.
        func exit(_ record: Int, toNode level: Int) throws {
            try touchExit(try XCTUnwrap(flow.levelRun?.session), record: record)
            drive { f in (f.worldMap.map { $0.iterations >= 2 && $0.walkStep == 0 && $0.result == nil }) ?? false }
            let m = try XCTUnwrap(flow.worldMap)
            XCTAssertEqual(m.cur, try XCTUnwrap(m.map.findCurrNode(level: Int16(level))).index)
            let before = asked.count
            drive({ f in f.worldMap?.result == nil ? [0x24] : [] }) { f in f.worldMap == nil || self.asked.count > before }
        }
    }
}

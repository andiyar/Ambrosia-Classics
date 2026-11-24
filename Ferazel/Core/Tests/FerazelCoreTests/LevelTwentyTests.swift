import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L20 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L20`): level 20 "Hangnabit" enterable —
/// every one of its 333 records sets up (26 types; LL §4 "Level 20"; the clouds, the blades and the path maces built by
/// 6A-CL / 6A-BD / 6A-MP, none refused), the clouds' 328 draws in the spawn's stream (from its 2nd draw to its 421st,
/// the Xichron crystals' 92 among them), its header as read (music 15, no chapter card, the start, every other switch 0), the picture cache's marks
/// and load bar, `BuiltLevels.list` = [1…5, 10, 11, 15, 18, 20] (+ 21 at 6A-L21), the way on (level 20's exit to node 21),
/// the hang glider's marks and the wind. The parameter trace ("Every level task"): every built type placed here whose
/// p1…p4 take a value no level 1–5, 10, 11, 15 or 18 record of that type has, and the types the card names, each
/// traced through its Setup / Handle arm in the dump and pinned by one assert inside `testLevel20SetsUpEveryRecord`.
/// The level's first frame is `LevelFrameGoldenTests.testLevel20FirstFrameGolden`. A lit blade on this level's "no
/// light" grid — any dynamic-light sprite — is drawn unlit (D67.1, known deviation 7: `SpriteDrawTests.testBladeLitOnNoLightCellDrawsUnlit`).
/// Against the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip. Proof-B rules:
/// plain Swift, no `@MainActor` class, no Foundation string search.
final class LevelTwentyTests: XCTestCase {

    /// The steps of the game's stream from seed `a` to seed `b` (nil past `limit`).
    private func steps(from a: Int32, to b: Int32, limit: Int = 200_000) -> Int? {
        var r = FastRand(seed: a)
        var n = 0
        while r.seed != b {
            guard n < limit else { return nil }
            _ = r.next(1)
            n += 1
        }
        return n
    }

    func testLevel20SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 20)
        let census = try TenEleven.census(r, level: 20)
        XCTAssertEqual(census.records, 333)
        XCTAssertEqual(census.types, 26)
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record (the card's 209 are built)")
        XCTAssertEqual(census.created, 333)
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")
        var perType: [Int16: Int] = [:]
        for p in L.activePlacements { perType[p.type, default: 0] += 1 }
        XCTAssertEqual([perType[2890], perType[2891], perType[2892], perType[2893], perType[3060], perType[1485],
                        perType[1480], perType[1770], perType[3050]], [44, 44, 32, 44, 28, 16, 4, 6, 1])

        // The header (LL §4 "Level 20" item 1: the music is the only switch new against levels 1–5), as read.
        let h = L.header
        XCTAssertEqual(h.name, "Hangnabit")
        XCTAssertEqual([h.music, h.chapter, h.levelClut, h.screenClut], [15, 0, 211, 212], "0x284a / 0x273c")
        XCTAssertEqual([h.startX, h.startY, Int16(h.startFacingLeft)], [86, 886, 0], "the start, facing right")
        XCTAssertEqual([Int(h.parallaxRipple), Int(h.omniPxMode), Int(h.waterSurfaceEffect), Int(h.submergedFaces),
                        Int(h.inLiquid)], [0, 0, 0, 0, 0], "0x26ca / 0x26c7 / 0x26c9 / 0x26c6 / 0x26cd")
        XCTAssertEqual([h.sidePush, h.stripPict, h.autoScrollEnable, h.flameMode, h.darknessEnable, h.cameraOffsetX,
                        h.cameraOffsetY, h.landingDamage, h.iceSlipperiness, h.waterCurrent, h.arenaBound,
                        h.secondArenaBound], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual([Int(h.gridWidth), Int(h.gridHeight)], [600, 32])
        // Every light byte −1 ("no light", 19,200 cells): the D67.1 grid.
        var bytes = Set<Int>()
        for row in 0..<Int(h.gridHeight) { for col in 0..<Int(h.gridWidth) { bytes.insert(L.lightByte(col: col, row: row)) } }
        XCTAssertEqual(bytes, [-1])
        // The music: New Game at level 20 (the hidden `FerazelLevel` switch) plays the level's own track 15; no
        // chapter card; the player starts facing right (hdr 0x26c8 0).
        let rig = TenElevenRig(r, start: 20)
        rig.newGame(level: 20)
        XCTAssertEqual(rig.plays, [15])
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 15)
        let session = try XCTUnwrap(run.session)
        XCTAssertEqual([session.globals.startFacing, session.world.player.facing], [0, 2], "facing right")

        // The clouds' Setups (6A-CL, R(60) then R(50) each, M l. 62526–62567) start at the stream's 2nd draw: in spawn
        // order only records 0 (the hang glider) and 1 (a Gremlin) set up ahead of them, with one draw between them.
        // The 328 cloud draws are not back to back (run 66's "draws 2…329" is wrong by the crystals among them).
        do {
            let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(h))
            var rng = FastRand(seed: 1), lights = 0
            var at = 0, ahead: [Int] = [], cloudDraws: [Int] = [], between: [Int16: Int] = [:]
            for p in SetupFaces.spawnOrder(L.placements) {
                let before = rng.seed
                let e = try SetupFaces.setup(p, context: c, lightsInUse: lights, rng: &rng)
                if e.light != nil { lights += 1 }
                let n = try XCTUnwrap(steps(from: before, to: rng.seed))
                if (0xb4a...0xb4d).contains(p.type) {
                    cloudDraws.append(at)
                    XCTAssertEqual(n, 2, "cloud record \(p.index)")
                } else if cloudDraws.isEmpty {
                    ahead.append(p.index)
                } else if cloudDraws.count < 164 && n > 0 {
                    between[p.type, default: 0] += n
                }
                at += n
            }
            XCTAssertEqual(ahead, [0, 1])
            XCTAssertEqual(cloudDraws.count, 164)
            XCTAssertEqual(cloudDraws.first, 1, "the first cloud's R(60) is the stream's 2nd draw")
            // Measured: the last cloud's pair is the stream's 420th and 421st draws; the 92 draws among the clouds are
            // the Xichron crystals' 1055 (placed among the cloud records, four draws each: three in its arm, M l.
            // 52435–52439, and the Setup tail's `+0x14c = R(60)`).
            XCTAssertEqual([cloudDraws.last ?? 0, between.values.reduce(0, +)], [419, 92])
            XCTAssertEqual(between.sorted { $0.key < $1.key }.map { [Int($0.key), $0.value] }, [[1055, 92]])
        }

        // The picture cache (LL §4 item 6, the new types' marks as 1-based list positions — `.set(n − 1)` here): every
        // one is marked; the opened session needs exactly the Setups' marks; the bar is `CachedFacesTests
        // .testLevel20LoadBarMarks`' last re-derived count and total (6A-MP): [16, 57, 114, 16].
        let expected: [CachedFaces.RecordKey] = [
            .set(0), .set(1), .set(2), .set(3), .set(28), .set(88), .set(89), .set(90),
            .single(131), .single(132), .single(133), .single(134), .single(135), .single(150),
        ]
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(h))
        let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
        XCTAssertEqual(setUp.count, L.activePlacements.count)
        let marks = Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) })
        for k in expected { XCTAssertTrue(marks.contains(k), "\(k)") }
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 20)
        let needed = CachedFaces.needed(by: s)
        XCTAssertEqual(Set(needed.records), marks, "the opened session needs the Setups' marks")
        var cache = CachedFaces()
        cache.enterLevel(screenClut: h.screenClut)
        let bars = cache.load(needed: needed)
        let q = Int(bars.first?.1 ?? 0), n = needed.records.reduce(0) { $0 + CachedFaces.record($1).faces }
        XCTAssertEqual([needed.records.count, n, q, bars.count], [16, 57, 114, 16],
                       "`testLevel20LoadBarMarks`' count and total (needed records, n, q, steps)")
        XCTAssertEqual([bars.first?.0, bars.last?.0], [63, 114], "measured: the first step; the last fills the bar")

        try traceLevel20(r, L)
    }

    /// The parameter trace of level 20 (the script's list and each value's dump line are in the commit body). One
    /// assert each.
    private func traceLevel20(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 20)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }
        /// Record `i` with p1…p4 replaced (all 0 by default).
        func with(_ i: Int, _ p1: Int16 = 0, _ p2: Int16 = 0, _ p3: Int16 = 0, _ p4: Int16 = 0) -> Placement {
            let p = rec(i)
            return Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p1, p2: p2, p3: p3, p4: p4,
                             y: p.y, x: p.x)
        }
        /// The Setup of record `i` with p1…p4 zeroed, in the live records too (a Bonus reads its own record from them).
        func zeroed(_ i: Int) throws -> SetupFaces.Entry {
            var all = L.placements
            all[i] = with(i)
            let c0 = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header), records: all)
            return try SetupFaces.setup(with(i), context: c0)
        }

        // The rotating cannon 1092 p1 103, p2 10 (record 288; levels 10, 11: p1 0 / 101, p2 0 / 15): the Setup's p1 ≥ 1
        // arm (M l. 62120–62170) — step `+0x15c` = 2 (103), `+0x158` = 4 / 2 = 2 (p3 0), `+0x160` = `+0x158`, the first
        // pause `+0xa6` = p2 = 10, `+0x164` = 9000 (p4 0). Its Handle turns it +2 a frame (6A-RC, `RotatingCannonTests`).
        do {
            XCTAssertEqual([Int(rec(288).type), Int(rec(288).p1), Int(rec(288).p2)], [1092, 103, 10])
            let k = try setup(288).slot
            XCTAssertEqual([Int(k.classWord15c), Int(k.classWord158), Int(k.classWord160), Int(k.counterA6),
                            Int(k.launchSpeed)], [2, 2, 2, 10, 9000])
        }
        // The cannons 1092 (records 280, 281), 1094 (289) and 1096 (290, 291), p1 0 (as on levels 10 and 11): the p1 < 1
        // arm (M l. 62116–62119) — launch speed 9000, no turn.
        for i in [280, 281, 289, 290, 291] {
            XCTAssertEqual(rec(i).p1, 0, "cannon \(i)")
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.launchSpeed), Int(k.classWord15c)], [9000, 0], "cannon \(i)")
        }
        // The big crystals 1290 / 1291 (0x50a / 0x50b, first built here): p1 ≠ 0 → gravity 0 (M l. 52496–52500), p1 0
        // keeps the default.
        for i in [234, 235, 236, 260, 319, 237, 238, 258, 259, 272, 320] {
            let k = try setup(i).slot
            XCTAssertEqual(k.gravity == 0, rec(i).p1 != 0, "crystal \(i) (type \(rec(i).type), p1 \(rec(i).p1))")
        }
        // The money bag 1293 (0x50d) p1 1 (record 261; levels 1–5, 15: p1 0): the bags' arm (M l. 52508–52527) reads no
        // record word, nor do its Handle (the glint) and its pickup (`.HitPlayerSprite` 0x50d: 0x19 coins) — the same
        // Setup as p1 0. Likewise the magic upgrade 1341 (0x53d) p1 1 (record 312; level 5: p1 0): the upgrades' arm
        // (M l. 52650–52663) and pickup (M l. 48810–48916) read no record word.
        for i in [261, 312] {
            XCTAssertEqual([Int(rec(i).p1)], [1], "record \(i)")
            let a = try setup(i), b = try zeroed(i)
            XCTAssertEqual([a.slot] + a.children, [b.slot] + b.children, "record \(i)")
            XCTAssertEqual(a.light, b.light, "record \(i)")
        }
        // The items 3206 (0xc86, records 327, 328) and 3219 (0xc93, records 223, 277, 278): the items' arm (M l.
        // 52665–52710) — gravity 0 only for p1 ≠ 0 (M l. 52704–52706); 0xc86's rect top + 6.
        for i in [327, 328, 223, 277, 278] {
            let k = try setup(i).slot
            XCTAssertEqual(k.gravity == 0, rec(i).p1 != 0, "item \(i) (type \(rec(i).type), p1 \(rec(i).p1))")
        }
        // The candelabra 3102 (0xc1e, records 330, 331), p4 0: the candelabras' arm (M l. 52740–52794) — gravity 0, the
        // pickup delay 1 and the hit callback (p4 0), its light point (x + 0x11, y + 8).
        for i in [330, 331] {
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.gravity), Int(k.pickupDelay), k.hasHit ? 1 : 0], [0, 1, 1], "candelabra \(i)")
        }
        // The radial maces 1480 (0x5c8, records 315–318, first built here) p1 10, p2 150, p3 1500, p4 0: the radial branch
        // (M l. 62362–62427) — mode 10, `.MakeRadial(r = p2, speed = p3, angle = p4)` and p2 / 16 = 9 chain links 0x59a
        // each, made at the level spawn.
        for i in 315...318 {
            XCTAssertEqual([Int(rec(i).p1), Int(rec(i).p2), Int(rec(i).p3), Int(rec(i).p4)], [10, 150, 1500, 0])
            let ball = try XCTUnwrap(s.world.active.sprites.first { $0.recordIndex == i && $0.type == 1480 }, "mace \(i)")
            let rad = try XCTUnwrap(ball.radial, "mace \(i)")
            XCTAssertEqual([Int(ball.subtype), Int(rad.radius), Int(rad.speed)], [10, 150 << 8, 1500], "mace \(i)")
        }
        XCTAssertEqual(s.world.active.sprites.filter { $0.type == ChainSprite.maceChain }.count, 4 * 9)
        // The path maces 1485 (16, every one mode 1: 6A-MP, `MacePathTests` record by record): p1 1 → the programmed
        // path in y (M l. 62338–62361).
        XCTAssertEqual(Set(L.activePlacements.filter { $0.type == 1485 }.map(\.p1)), [1])
        // The Gremlins 1770 (records 1, 239, 240, 292–294) p1 1, p2 300 / 390, p3 1000 / 1700, p4 0 / 300 (level 15: p2
        // 150 / 200, p3 600, p4 0 / 150): `.SetupGremlinSprite` reads its record only through `.SetupProgrammedPath(s,
        // −1, 0)` (M l. 69226; 39288–39381) — mode 1, `+0x100` = y256 + 8·p3, `+0x104` = y256 + 256·p2 − 8·p3, vy = p3;
        // p4 is read by no arm (the twin with p4 0 sets up the same).
        for i in [1, 239, 240, 292, 293, 294] {
            let p = rec(i)
            let k = try setup(i).slot
            let y256 = Int32(p.y) << 8
            XCTAssertEqual([k.pathMode, k.pathLow, k.pathHigh, k.vy],
                           [1, y256 + 8 * Int32(p.p3), y256 + 256 * Int32(p.p2) - 8 * Int32(p.p3), Int32(p.p3)],
                           "Gremlin \(i)")
        }
        do {
            XCTAssertEqual(rec(240).p4, 300)
            let a = try setup(240).slot
            let b = try SetupFaces.setup(with(240, rec(240).p1, rec(240).p2, rec(240).p3, 0), context: c).slot
            XCTAssertEqual(a, b, "Gremlin 240: p4 300 sets up as p4 0")
        }
    }

    func testBuiltLevelsTwenty() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21])   // 6A-L21: + 21
        XCTAssertTrue(BuiltLevels.contains(20))
        for n in [12, 16, 19, 22, 40] { XCTAssertFalse(BuiltLevels.contains(n), "level \(n)") }
        XCTAssertEqual(BuiltLevels.notBuiltReport(22), "Level 22 is not built yet (Phase 6).")
        let r = try TenEleven.resources()
        // `startLevel` 20 (the hidden `FerazelLevel` switch) is accepted: New Game there, nothing asked.
        let rig = TenElevenRig(r, start: 20)
        rig.newGame(level: 20)
        XCTAssertEqual(rig.flow.levelNumber, 20)
        XCTAssertEqual(rig.levels.prepared, [20])
        XCTAssertEqual(rig.asked, [])
        // The map: node 20's links [15, 21] (node 15's [10, 20, 30]: level 15's exit 61 unlocks it, `LevelFifteenTests`).
        let map = try WorldMap.load(from: r)
        XCTAssertEqual(try XCTUnwrap(map.findCurrNode(level: 20)).links, [15, 21, 0, 0, 0, 0, 0])
        // Level 20's exit p1 1 (record 311, at x 15546) → node 21 (links[1]) → Return → level 21 entered (before
        // 6A-L21: "Level 21 is not built yet (Phase 6).").
        let L = try LevelFile.load(from: r, level: 20)
        XCTAssertEqual([Int(L.placements[311].type), Int(L.placements[311].p1)], [3249, 1])
        try rig.exit(311, toNode: 21)
        rig.drive { f in f.levelRun?.levelNumber == 21 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(rig.asked, [])
        XCTAssertEqual(rig.levels.prepared, [20, 21])
        // A save made on level 20 (a save point's block, the level's own records) continues there through
        // `.ContinueGame`: level 20 runs, nothing asked.
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 20, x: L.header.startX, y: L.header.startY,
                           stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L.placements)
        let cont = TenElevenRig(r, start: 1)
        cont.files.block = save
        cont.drive { $0.state == .mainMenu }
        cont.drive({ _ in [0x0f] }) { _ in true }                          // R: Continue
        cont.drive { _ in cont.askedFile }
        cont.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/twenty"),
                                                displayName: "twenty")))
        cont.drive { f in f.levelRun?.levelNumber == 20 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(cont.asked, [])
        XCTAssertEqual(cont.flow.levelNumber, 20)
        XCTAssertEqual(cont.levels.prepared, [20])
    }

    /// The hang glider 3050 (record 0, LL §4 "Level 20": its four Player sets marked — 6A-CF) and the wind (2,899
    /// cells — 6A-WD) on the opened level.
    func testLevel20GliderMarksAndWind() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 20)
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 20)
        // The glider: `.SetupBonusSprite` 0xbea (M l. 52611–52627) — gravity 0, its face, the write-back flags `+0x18b`
        // and `+0x188`, and the four glider entries' "needed" bytes (M l. 52622–52625): the opened level needs the
        // Player sets #1–#4, and only because of it (the twin without record 0 does not).
        XCTAssertEqual([Int(L.placements[0].type), Int(L.placements[0].p1)], [3050, 0])
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        let glider = try SetupFaces.setup(L.placements[0], context: c).slot
        XCTAssertEqual([Int(glider.gravity), glider.keepRecordAtKill ? 1 : 0, glider.keepRecord ? 1 : 0], [0, 1, 1])
        XCTAssertEqual(glider.face, FaceRef(pict: 0xbea, index: 0, set: .encoded))
        let needed = Set(CachedFaces.needed(by: s).records)
        let sets: Set<CachedFaces.RecordKey> = [.set(0), .set(1), .set(2), .set(3)]
        XCTAssertTrue(sets.isSubset(of: needed), "the four Player sets")
        let noGlider = try FerazelSession(resources: try LevelFixture.resources(level: 20, leaveOut: [.record(0)]),
                                          prefs: FerazelPrefs(), level: 20)
        XCTAssertTrue(sets.isDisjoint(with: Set(CachedFaces.needed(by: noGlider).records)), "no glider, no Player set")

        // The wind: the overlay cells with o1 0…15 and o2 > 0 (`.StandardSpriteHandles`' wind branch, M l.
        // 32489–32574), 36 of them crossed gates (o1 10…15).
        var wind: [(col: Int, row: Int)] = [], crossed = 0
        for row in 0..<L.overlay.height {
            for col in 0..<L.overlay.width {
                let o1 = L.overlay1(col: col, row: row)
                guard 0 <= o1 && o1 <= 15, L.overlay2(col: col, row: row) > 0 else { continue }
                wind.append((col, row))
                if o1 >= 10 { crossed += 1 }
            }
        }
        XCTAssertEqual([wind.count, crossed], [2899, 36])
        // The player (wind scale 0x100) with his centre in the first wind cell in reading order, at rest: one
        // `.StandardSpriteHandles` step sets `+0x92` and pushes him (measured); out of the wind, nothing.
        let w = s.world
        let pid = try XCTUnwrap(w.playerID)
        let cell = try XCTUnwrap(wind.first)
        func put(col: Int, row: Int) -> SpriteSlot {
            w.active.update(id: pid) { p in
                p.x = col * 32; p.y = row * 32
                p.x256 = Int32(col * 32) << 8; p.y256 = Int32(row * 32) << 8
                p.centre = SpriteSlot.Point(x: col * 32 + 16, y: row * 32 + 16)
                p.vx = 0; p.vy = 0
            }
            let before = w.active.sprite(id: pid)!
            w.standardSpriteHandles(pid)
            return before
        }
        XCTAssertEqual(w.active.sprite(id: pid)?.windScale, 0x100)
        // Review leg 2 — the twin out of the wind, first (no ramp carried in). Every cell with o1 0…15 has o2 > 0 here,
        // so the twin is the first cell in reading order whose o1 is past 15 (an overlay the branch passes over): no
        // `+0x92`, no push.
        var calm: (col: Int, row: Int)?
        for row in 0..<L.overlay.height where calm == nil { for col in 0..<L.overlay.width where calm == nil {
            let o1 = L.overlay1(col: col, row: row)
            if o1 > 15 { calm = (col, row) }
        } }
        let still = try XCTUnwrap(calm)
        let beforeCalm = put(col: still.col, row: still.row)
        let afterCalm = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertFalse(afterCalm.inWind)
        XCTAssertEqual([still.col, still.row, Int(afterCalm.x256 - beforeCalm.x256), Int(afterCalm.vy - beforeCalm.vy)],
                       [153, 3, 0, 0], "measured: the calm cell; no push")
        let before = put(col: cell.col, row: cell.row)
        let after = try XCTUnwrap(w.active.sprite(id: pid))
        XCTAssertTrue(after.inWind)
        XCTAssertEqual([cell.col, cell.row, Int(L.overlay1(col: cell.col, row: cell.row)),
                        Int(L.overlay2(col: cell.col, row: cell.row)), Int(after.x256 - before.x256), Int(after.vy - before.vy)],
                       [325, 0, 9, 50, 0, -700], "measured: the cell, its o1 / o2, the push")
    }
}

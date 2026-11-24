import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L18 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L18`): level 18 "Goblin Chief" enterable —
/// every one of its 34 records sets up (15 types; LL §4 "Level 18"; none refused since 6A-BG1c and 6A-CH1), its header
/// switches as read (the ripple 6A-RP built, the camera offset, the landing damage, the ice, the current, the arena
/// bounds 6A-CH2 reached, the facing, the music and its boss rule), the picture cache's marks,
/// `BuiltLevels.list` = [1…5, 10, 11, 15, 18], and the map's way in (level 11's exit) and on (level 18's exit to node
/// 40, not built). The parameter trace ("Every level task"): every built type placed here whose p1…p4 take a value no
/// level 1–5, 10, 11 or 15 record of that type has, each traced through its Setup / Handle arm in the dump and pinned
/// by one assert inside `testLevel18SetsUpEveryRecord`. The Chief's activation frame on the real level, with real
/// pictures, is `LevelFrameGoldenTests.testLevel18ChiefActivationFrame` (the wake rectangle is his picture's). Against
/// the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip. Proof-B rules: plain Swift,
/// no `@MainActor` class, no Foundation string search.
final class LevelEighteenTests: XCTestCase {

    func testLevel18SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 18)
        let census = try TenEleven.census(r, level: 18)
        XCTAssertEqual(census.records, 34)
        XCTAssertEqual(census.types, 15)
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record (the card's 6 are built)")
        XCTAssertEqual(census.created, 34)
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")

        // The header switches new against levels 1–5 (LL §4 "Level 18" item 1), as read.
        let h = L.header
        XCTAssertEqual(h.name, "Goblin Chief")
        XCTAssertEqual([Int(h.parallaxRipple), Int(h.startFacingLeft)], [1, 1], "0x26ca / 0x26c8")
        XCTAssertEqual([h.cameraOffsetY, h.landingDamage, h.iceSlipperiness, h.waterCurrent], [-108, 150, 80, -512],
                       "0x270c / 0x270e / 0x2710 / 0x2714")
        XCTAssertEqual([h.arenaBound, h.secondArenaBound, h.music], [-1400, -640, 23], "0x2724 / 0x272e / 0x284a")
        XCTAssertEqual([h.levelClut, h.screenClut], [223, 224])
        XCTAssertEqual([Int(h.omniPxMode), Int(h.waterSurfaceEffect), Int(h.submergedFaces), Int(h.inLiquid)],
                       [0, 0, 0, 0], "0x26c7 / 0x26c9 / 0x26c6 / 0x26cd")
        XCTAssertEqual([h.sidePush, h.stripPict, h.autoScrollEnable, h.flameMode, h.chapter, h.darknessEnable,
                        h.cameraOffsetX], [0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual([h.startX, h.startY], [1996, 605], "the start: right of the arena, which is entered walking left")
        // The music: New Game at level 18 (the hidden `FerazelLevel` switch) plays the level's own track 23 (the
        // Chief's Setup clears `fed0`, so the loop's boss rule does not fire); no chapter card (hdr 0x273c 0); the player
        // starts facing left (hdr 0x26c8 1). With no boss alive (`fed0` = 1, the Kill's store) the rule fades to track 30.
        let rig = TenElevenRig(r, start: 18)
        rig.newGame(level: 18)
        XCTAssertEqual(rig.plays, [23])
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 23)
        let session = try XCTUnwrap(run.session)
        XCTAssertEqual([session.globals.startFacing, session.world.player.facing], [1, 1], "facing left (level 15: 0 / 2)")
        XCTAssertEqual(session.world.arena.noBossAlive, 0, "the Chief's Setup cleared `fed0`")
        session.world.arena.noBossAlive = 1
        rig.drive { _ in rig.plays.count > 1 }
        XCTAssertEqual(rig.plays, [23, 30])
        XCTAssertEqual(run.music.currentTrack, 30)
        // The landing damage and the ice at level 18's own values: the damaging surface takes 0x270e = 150 HP (`Player
        // .surfaceMaterial`, row 28 with material 2); ice (material 3) with 0x2710 = 80: `0694` = (0x100 − 80) · 0x320 >>
        // 8 = 550, the player's `+0x112` = 80 >> 4 = 5 (level 15, 0x2710 0: 800 / 0). The current (0x2714 −512) has no
        // water cell of BG kind 200 / 205 to show its motes on (`TenEleven.headerBehaviour`'s probe finds none here).
        var waterCells = 0
        for row in 0..<Int(h.gridHeight) {
            for col in 0..<Int(h.gridWidth) {
                let b = L.bgTile(col: col, row: row)
                if b >= 0, [200, 205].contains(L.bgKind(tile: b)) { waterCells += 1 }
            }
        }
        XCTAssertEqual(waterCells, 0, "no water cell of BG kind 200 / 205 on level 18")
        do {
            let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 18)
            let w = s.world
            let pid = try XCTUnwrap(w.playerID)
            w.active.update(id: pid) { $0.material = 3 }
            Player.surfaceMaterial(w, id: pid)
            XCTAssertEqual([Int(w.player.ice), Int(try XCTUnwrap(w.active.record(id: pid)).slip)], [550, 5], "measured")
            w.active.update(id: pid) { $0.material = 2; $0.invulnerable = 0 }
            let hp0 = try XCTUnwrap(w.active.record(id: pid)).hp
            Player.surfaceMaterial(w, id: pid)
            XCTAssertEqual(hp0 - (try XCTUnwrap(w.active.record(id: pid)).hp), 150)
        }

        // The picture cache (LL §4 item 6, the new types' marks as 1-based list positions — `.set(n − 1)` here): every
        // one is marked; the opened session needs exactly the Setups' marks; the bar on a fresh cache, measured.
        let expected: [CachedFaces.RecordKey] = [
            .set(42), .set(59), .set(60), .set(61), .set(62), .single(160), .single(161), .single(162), .single(192),
        ]
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(h))
        let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
        XCTAssertEqual(setUp.count, L.activePlacements.count)
        let marks = Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) })
        for k in expected { XCTAssertTrue(marks.contains(k), "\(k)") }
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 18)
        let needed = CachedFaces.needed(by: s)
        XCTAssertEqual(Set(needed.records), marks, "the opened session needs the Setups' marks")
        var cache = CachedFaces()
        cache.enterLevel(screenClut: h.screenClut)
        let bars = cache.load(needed: needed)
        // n counted from the needed records' own face counts (a set its faces, a single 1), not from q.
        let q = Int(bars.first?.1 ?? 0), n = needed.records.reduce(0) { $0 + CachedFaces.record($1).faces }
        XCTAssertEqual([marks.count, n, q, bars.count], [13, 40, 80, 13], "measured (needed records, n, q, steps)")
        // The bar's own steps: p starts at n and grows by each record's faces, so the last step fills it (p = q).
        XCTAssertEqual([bars.first?.0, bars.last?.0], [56, 80], "measured: the first step; the last fills the bar")

        try traceLevel18(r, L)
    }

    /// The parameter trace of level 18 (the script's list and each value's dump line are in the commit body). One
    /// assert each.
    private func traceLevel18(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 18)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }
        /// Record `i` with p1…p4 replaced (all 0 by default).
        func with(_ i: Int, _ p1: Int16 = 0, _ p2: Int16 = 0, _ p3: Int16 = 0, _ p4: Int16 = 0) -> Placement {
            let p = rec(i)
            return Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p1, p2: p2, p3: p3, p4: p4,
                             y: p.y, x: p.x)
        }

        // The gates 2940 (0xb7c) p1 0 (records 3–6, at the level's two ends; levels 1–5, 10, 11, 15: p1 −1, 90, 142,
        // 201, 270): the gate arm of `.HandleBoxSprite` (M l. 61016–61064) — p1 ≥ 0 opens when record [p1]'s p4 is 1
        // (M l. 61029–61031). Record 0 is the arena's own gate (2940 p1 −1, p4 0), and nothing writes its p4: these four
        // stay shut. The twin with record 0's p4 planted 1 opens them (2 px a frame up from the start, the clip with it).
        XCTAssertEqual([Int(rec(0).type), Int(rec(0).p1), Int(rec(0).p4)], [2940, -1, 0])
        for i in [3, 4, 5, 6] {
            XCTAssertEqual([Int(rec(i).type), Int(rec(i).p1), Int(rec(i).p2)], [2940, 0, 0], "gate \(i)")
            let id = s.world.active.insert(try setup(i).slot)
            let y0 = try XCTUnwrap(s.world.active.record(id: id)).y
            for _ in 0..<3 { BoxSprite.gateArm(s.world, id: id) }
            let shut = try XCTUnwrap(s.world.active.record(id: id))
            XCTAssertEqual([shut.y, shut.clip.top], [y0, 7], "gate \(i): shut")
            let p0 = s.world.records[0]
            s.world.records[0] = Placement(index: p0.index, flag: p0.flag, byte1: p0.byte1, type: p0.type, p1: p0.p1,
                                           p2: p0.p2, p3: p0.p3, p4: 1, y: p0.y, x: p0.x)
            for _ in 0..<3 { BoxSprite.gateArm(s.world, id: id) }
            s.world.records[0] = p0
            let opened = try XCTUnwrap(s.world.active.record(id: id))
            XCTAssertEqual([opened.y, opened.clip.top], [y0 - 6, 13], "gate \(i): record 0's p4 1 opens it")
            _ = s.world.active.remove(id: id)
        }
        // The decorations 2820 (0xb04, records 11, 12, 17), 2821 (0xb05, 13) and 2822 (0xb06, 14, 15), p2 11 (levels
        // 1–5, 10, 11, 15: 0 / 10): the decorations arm of `.SetupBoxSprite` (M l. 59674–59677) — `+0xb8` = p2 +
        // 0x10000 = 0x1000b; p1 1 mirrored (M l. 59670–59673).
        for i in [11, 12, 13, 14, 15, 17] {
            let k = try setup(i).slot
            XCTAssertEqual(rec(i).p2, 11, "decoration \(i)")
            XCTAssertEqual([Int(k.mode), k.mirrored ? 1 : 0], [0x1000b, Int(rec(i).p1)], "decoration \(i)")
        }
        // The scroll 2000 p1 4 (record 21; levels 1–5, 10, 11, 15: 1, 5): the Setup (M l. 52723–52735) — gravity 0 (M
        // l. 52724), and again for p1 ≠ 0 (M l. 52732–52734); picked up, `.HitPlayerSprite`'s scroll arm (M l.
        // 48939–48976) reads the spell from the record's p1 (type 2000): spell 4 learned into the first free slot, the
        // scroll killed.
        do {
            let e = try setup(21)
            XCTAssertEqual([Int(rec(21).type), Int(rec(21).p1), Int(e.slot.gravity)], [2000, 4, 0])
            XCTAssertFalse(s.world.globals.inventory.contains { $0.id == 4 }, "spell 4 not owned at the start")
            let id = s.world.active.insert(e.slot)
            HitPlayerSprite.hit(s.world, player: try XCTUnwrap(s.world.playerID), other: id)
            XCTAssertTrue(s.world.globals.inventory.contains { $0.id == 4 && $0.isSpell == 1 }, "spell 4 learned")
            XCTAssertEqual(try XCTUnwrap(s.world.active.record(id: id)).killCount, 1)
            _ = s.world.active.remove(id: id)
        }
        // The health upgrade 1340 (0x53c) p1 1 (record 23; level 5: p1 0): the upgrades arm (M l. 52650–52663) and the
        // pickup arm (M l. 48810–48916) read no record word — the same Setup as p1 0. `BonusSprite.setup` reads its
        // record from the live records (`Context.records`, else the file's), never the placement handed in, so the twin
        // zeroes record 23 there too; the sprite, its light and its children compared (the record itself differs).
        XCTAssertEqual([Int(rec(23).type), Int(rec(23).p1)], [1340, 1])
        var zeroed = L.placements
        zeroed[23] = with(23)
        let c0 = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header), records: zeroed)
        let up1 = try setup(23), up0 = try SetupFaces.setup(with(23), context: c0)
        XCTAssertEqual([up1.slot] + up1.children, [up0.slot] + up0.children)
        XCTAssertEqual(up1.light, up0.light)
    }

    func testBuiltLevelsEighteen() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21])   // 6A-L20: + 20; 6A-L21: + 21
        XCTAssertTrue(BuiltLevels.contains(18))
        for n in [12, 16, 19, 22, 40] { XCTAssertFalse(BuiltLevels.contains(n), "level \(n)") }
        let r = try TenEleven.resources()
        // `startLevel` 18 (the hidden `FerazelLevel` switch) is accepted: New Game there, nothing asked.
        let rig = TenElevenRig(r, start: 18)
        rig.newGame(level: 18)
        XCTAssertEqual(rig.flow.levelNumber, 18)
        XCTAssertEqual(rig.levels.prepared, [18])
        XCTAssertEqual(rig.asked, [])
        // Level 11's exit p1 1 (record 133) → node 18 (node 11's links [10, 18]) → Return → level 18 entered (before
        // 6A-L18: "Level 18 is not built yet (Phase 6).").
        let eleven = TenElevenRig(r, start: 11)
        eleven.newGame(level: 11)
        XCTAssertEqual(try LevelFile.load(from: r, level: 11).placements[133].p1, 1)
        try eleven.exit(133, toNode: 18)
        eleven.drive { f in f.levelRun?.levelNumber == 18 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(eleven.asked, [])
        XCTAssertEqual(eleven.levels.prepared, [11, 18])
        // Level 18's exit p1 1 (record 16, x −76, beyond the arena's gate) → node 40 (node 18's links [11, 40]) → Return
        // → the not-built report, still on the map.
        let L = try LevelFile.load(from: r, level: 18)
        XCTAssertEqual([Int(L.placements[16].type), Int(L.placements[16].p1)], [3249, 1])
        try eleven.exit(16, toNode: 40)
        XCTAssertEqual(eleven.asked.last, .report(text: "Level 40 is not built yet (Phase 6)."))
        XCTAssertNil(eleven.flow.levelRun)
        XCTAssertEqual(eleven.levels.prepared, [11, 18])
        // A save made on level 18 (a save point's block, the level's own records) continues there through
        // `.ContinueGame`: level 18 runs, nothing asked.
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 18, x: L.header.startX, y: L.header.startY,
                           stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L.placements)
        let cont = TenElevenRig(r, start: 1)
        cont.files.block = save
        cont.drive { $0.state == .mainMenu }
        cont.drive({ _ in [0x0f] }) { _ in true }                          // R: Continue
        cont.drive { _ in cont.askedFile }
        cont.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/eighteen"),
                                                displayName: "eighteen")))
        cont.drive { f in f.levelRun?.levelNumber == 18 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(cont.asked, [])
        XCTAssertEqual(cont.flow.levelNumber, 18)
        XCTAssertEqual(cont.levels.prepared, [18])
    }
}

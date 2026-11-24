import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L21 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L21`): level 21 "Obfuscation & Edification"
/// enterable — every one of its 325 records sets up (62 types; LL §4 "Level 21"; the Box scenery, faces and talkers
/// built by 6A-BX1a / 6A-BX1b, the pipes' level spawn by 6A-PS, none refused), its header as read (music 9, no chapter
/// card, the start, the darkness switch 0x2706 = 2 — a value no earlier built level has (levels 1 and 4: 5; 2, 3 and 10:
/// 1; 5, 11, 15, 18, 20: 0) — over a light grid whose every byte is 0…14, inside the ambient table's 16 rows, and the
/// first shipped outcrop on a cell darker than 7, record 98), the picture cache's marks and load bar, the insects 1860
/// (first placed here: an idle head's body, a record-0x200 child, keeps its link and keeps running — Hazards "Idle
/// children"), the teleporters' pair ids, the conversations, and `BuiltLevels.list` = [1…5, 10, 11, 15, 18, 20, 21] with
/// the way in (level 20's exit) and on. The parameter trace ("Every level task"): every built type placed here whose
/// p1…p4 take a value no level 1–5, 10, 11, 15, 18 or 20 record of that type has, and the types the card names, each
/// traced through its Setup / Handle arm in the dump and pinned inside `testLevel21SetsUpEveryRecord`. The level's
/// first frame is `LevelFrameGoldenTests.testLevel21FirstFrameGolden`. Every test opens the level fresh (a restart gives
/// the pipes another touch area, D69.1). Against the committed `Resources/Ferazel` (D26); a missing data file is a
/// FAILURE, never a skip. Proof-B rules: plain Swift, no `@MainActor` class, no Foundation string search.
final class LevelTwentyOneTests: XCTestCase {

    func testLevel21SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 21)
        let census = try TenEleven.census(r, level: 21)
        XCTAssertEqual(census.records, 325, "records")
        XCTAssertEqual(census.types, 62, "types")
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record (the card's 30 are built)")
        XCTAssertEqual(census.created, 325, "records created")
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")
        var perType: [Int16: Int] = [:]
        for p in L.activePlacements { perType[p.type, default: 0] += 1 }
        XCTAssertEqual([1061, 1490, 1491, 1492, 1493, 1860, 1742, 1487, 2962, 1308].map { perType[Int16($0)] ?? 0 },
                       [14, 1, 3, 1, 1, 5, 1, 1, 1, 4], "records per type")

        // The header (LL §4 "Level 21" item 1: the darkness switch's value 2 and the music 9 are the values new against
        // 1–5; levels 1 and 4 have the switch at 5, levels 2 and 3 at 1).
        let h = L.header
        XCTAssertEqual(h.name, "Obfuscation & Edification", "the name")
        XCTAssertEqual([h.music, h.chapter, h.levelClut, h.screenClut], [9, 0, 211, 212], "0x284a / 0x273c")
        XCTAssertEqual([h.startX, h.startY, Int16(h.startFacingLeft)], [100, 1678, 0], "the start, facing right")
        XCTAssertEqual([Int(h.parallaxRipple), Int(h.omniPxMode), Int(h.waterSurfaceEffect), Int(h.submergedFaces),
                        Int(h.inLiquid)], [0, 0, 0, 0, 0], "0x26ca / 0x26c7 / 0x26c9 / 0x26c6 / 0x26cd")
        XCTAssertEqual([h.sidePush, h.stripPict, h.autoScrollEnable, h.flameMode, h.darknessEnable, h.cameraOffsetX,
                        h.cameraOffsetY, h.landingDamage, h.iceSlipperiness, h.waterCurrent, h.arenaBound,
                        h.secondArenaBound], [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0], "0x2706 = 2, the others 0")
        XCTAssertEqual([Int(h.gridWidth), Int(h.gridHeight)], [350, 65], "the grid")
        // The darkness grid: every light byte 0…14 (no −1, none past the ambient table's 16 rows), so the tile light
        // pass (`.GetAmbDarkVal`, M l. 13643–13652) reads a defined ambient row on every cell (measured counts).
        var bytes: [Int: Int] = [:]
        for row in 0..<Int(h.gridHeight) { for col in 0..<Int(h.gridWidth) { bytes[L.lightByte(col: col, row: row), default: 0] += 1 } }
        XCTAssertEqual(bytes.keys.sorted(), Array(0...14), "every light byte 0…14 occurs")
        XCTAssertEqual([bytes[0], bytes[14]], [9709, 36], "measured: the unlit and the darkest cells")
        // The music: New Game at level 21 (the hidden `FerazelLevel` switch) plays the level's own track 9; no chapter
        // card; the player starts facing right; `.SetupLevel` copies the darkness switch into G+0x22 (M l. 2377).
        let rig = TenElevenRig(r, start: 21)
        rig.newGame(level: 21)
        XCTAssertEqual(rig.plays, [9], "the music")
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 9, "the music")
        let session = try XCTUnwrap(run.session)
        XCTAssertEqual([session.globals.startFacing, session.world.player.facing], [0, 2], "facing right")
        XCTAssertEqual([Int(session.world.globals.savedDarkness), Int(session.world.globals.darknessOverride)], [2, 0],
                       "G+0x22 the switch, no override")

        // The picture cache (LL §4 item 6, the new types' marks as 1-based list positions — `.set(n − 1)` here): every
        // one is marked; the opened session needs exactly the Setups' marks; the bar on a fresh cache (6A-PS: 40 steps).
        let expected: [CachedFaces.RecordKey] = [
            .set(27), .set(43), .set(44), .set(45), .single(5), .single(6), .single(7), .single(8), .single(31),
            .single(35), .single(37), .single(38), .single(40), .single(66), .single(80), .single(117), .single(127),
            .single(128), .single(157),
        ]
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(h))
        let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
        XCTAssertEqual(setUp.count, L.activePlacements.count, "every record sets up")
        let marks = Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) })
        for k in expected { XCTAssertTrue(marks.contains(k), "\(k)") }
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 21)
        let needed = CachedFaces.needed(by: s)
        XCTAssertEqual(Set(needed.records), marks, "the opened session needs the Setups' marks")
        var cache = CachedFaces()
        cache.enterLevel(screenClut: h.screenClut)
        let bars = cache.load(needed: needed)
        let q = Int(bars.first?.1 ?? 0), n = needed.records.reduce(0) { $0 + CachedFaces.record($1).faces }
        XCTAssertEqual([needed.records.count, n, q, bars.count], [40, 150, 300, 40], "measured (needed records, n, q, steps)")

        try insects(r)
        try conversations(r)
        try traceLevel21(r, L)
    }

    /// The insects 1860 (0x744, records 68, 69, 70, 312, 319; first placed here). `.SetupBatSprite`'s insect arm makes
    /// its body by `.MTNewSprite(type, x, y, layer − 1, 0x200, .SetupInsectBodySprite)` and links it at `+0x1d4` (M l.
    /// 68212–68238): a record-0x200 child, never an idle entry, never counted. The level spawn idles every head; the
    /// first frame (the camera's first place) brings 68, 69 and 70 in for one frame, whose Handles copy each head onto
    /// its body (M l. 68478–68496), and idles them again; 312 and 319 stay idle throughout, so their bodies keep
    /// `.MTNewSprite`'s pixel copies (`+0xc` = y, `+0xa` = 0 — `SpriteWorld.newSprite`'s quirk). Over the idle frames
    /// every snapshot keeps its `+0x1d4` and every body keeps running its own Handle (`.HandleInsectBodySprite`, M l.
    /// 68917–68925: `.StandardSpriteHandles` + `.StandardSpriteCleanup`) — measured: the centre written from its first
    /// frame, and an invulnerability count given at frame 30 counted down one a frame. Then one head is brought in: it
    /// comes back (no Setup re-run) with the same body linked and copies itself onto it again.
    private func insects(_ r: FerazelResources) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 21, seed: 1)
        let w = s.world
        let heads = [68, 69, 70, 312, 319]
        func entry(_ rec: Int) throws -> IdleSprites.Entry {
            try XCTUnwrap(w.idle.entries.compactMap { $0 }.first { Int($0.saved.recordIndex) == rec }, "insect \(rec)")
        }
        var bodies: [Int] = []
        for rec in heads {
            let e = try entry(rec)
            XCTAssertNil(e.activeID, "insect \(rec): idle at the spawn")
            XCTAssertEqual(e.saved.type, 0x744)
            let b = try XCTUnwrap(e.saved.siblings.first, "insect \(rec): `+0x1d4` kept in the snapshot")
            let body = try XCTUnwrap(w.active.record(id: b), "insect \(rec): its body is active")
            XCTAssertEqual([Int(body.recordIndex), Int(body.type)], [0x200, 0x744])
            XCTAssertEqual(body.handler, .insectBody)
            XCTAssertFalse(body.countedInTotals, "a body is never counted")
            XCTAssertEqual([body.x, body.y, body.centre.x, body.centre.y], [e.saved.y, 0, 0, 0], "insect \(rec)")
            bodies.append(b)
        }
        XCTAssertFalse(w.idle.entries.contains { $0?.saved.recordIndex == 0x200 }, "no body is an idle entry")
        _ = s.step(keys: KeyState())
        XCTAssertEqual(try heads.map { try entry($0).activeID != nil }, [true, true, true, false, false],
                       "measured: the first frame brings 68, 69, 70 in")
        var invulnerable: [[Int]] = []
        for f in 2...61 {
            _ = s.step(keys: KeyState())
            for (rec, b) in zip(heads, bodies) {
                let e = try entry(rec)
                XCTAssertNil(e.activeID, "frame \(f): insect \(rec) idle")
                XCTAssertEqual(e.saved.siblings.first, b, "frame \(f): insect \(rec) keeps its link")
                let body = try XCTUnwrap(w.active.record(id: b), "frame \(f): insect \(rec)'s body still runs")
                XCTAssertEqual([body.centre.x, body.centre.y], [body.x, body.y], "frame \(f): its cleanup's centre")
            }
            if f == 30 { for b in bodies { w.active.update(id: b) { $0.invulnerable = 20 } } }
            if [31, 49, 50, 61].contains(f) { invulnerable.append(bodies.map { Int(w.active.record(id: $0)?.invulnerable ?? -1) }) }
        }
        XCTAssertEqual(invulnerable, [[19, 19, 19, 19, 19], [1, 1, 1, 1, 1], [0, 0, 0, 0, 0], [0, 0, 0, 0, 0]],
                       "each body's `.StandardSpriteHandles` counts down while its head is idle")
        // Measured: 68, 69, 70's bodies where their one active frame put them (each head's spawn point); 312, 319's
        // still at the pixel copies.
        XCTAssertEqual(try bodies.map { b -> [Int] in let k = try XCTUnwrap(w.active.record(id: b)); return [k.x, k.y] },
                       [[881, 660], [938, 749], [658, 698], [2027, 0], [83, 0]])
        // Insect 319 brought in (the player put on its spawn point): the head comes back (`.IdleToActiveSprite`, M l.
        // 4215–4275, no Setup) with the same body at `+0x1d4`, and its Handle copies itself onto it.
        let e319 = try entry(319)
        let pid = try XCTUnwrap(w.playerID)
        w.active.update(id: pid) { p in
            p.x = e319.saved.x; p.y = e319.saved.y; p.x256 = Int32(p.x) << 8; p.y256 = Int32(p.y) << 8; p.vx = 0; p.vy = 0
        }
        var k = 0
        while try entry(319).activeID == nil && k < 200 { _ = s.step(keys: KeyState()); k += 1 }
        let head = try XCTUnwrap(w.active.record(id: try XCTUnwrap(try entry(319).activeID)))
        XCTAssertEqual(head.siblings.first, bodies[4], "insect 319: the same body")
        let body = try XCTUnwrap(w.active.record(id: bodies[4]))
        XCTAssertEqual([body.x, body.y, k], [head.x, head.y, 1], "measured: in on the first frame; the head's Handle copies its position to the body")
        XCTAssertEqual(body.face, FaceRef(pict: Bat.insectSet, index: 8, set: .encoded), "insect 319: its body's face")
    }

    /// Level 21's three conversations (LL §5: 261 on record 89, 260 on 207, 300 on 318) use no action, so nothing on
    /// level 21 arms a record. Record 283 is level 11's dormant Dimbo (type 2956, spawn byte 99), armed in level 11's
    /// snapshot by action 10 of level 22's conversation 221 (`LaterConversationTests`: the save write). The run-55 carry —
    /// that the armed record appears on a revisit — is shown here on level 11 through the level runner: a revisit
    /// (`hasSnapshot[11]` 1) restores the snapshot (`.SetupLevel` M l. 2405–2409) and `.SetupLevelSprites` spawns record
    /// 283; the twin with the record left dormant (spawn byte 99) spawns none.
    private func conversations(_ r: FerazelResources) throws {
        let L21 = try LevelFile.load(from: r, level: 21)
        for (rec, id) in [(89, Int16(261)), (207, 260), (318, 300)] {
            XCTAssertEqual(L21.placements[rec].p1, id, "record \(rec)")
            let lines = try Conversation.load(from: r, id: id).lines
            XCTAssertEqual(Set(lines.flatMap { [$0.action1.type, $0.action2.type] }).subtracting([0]), [], "Mcnv \(id)")
        }
        let L11 = try LevelFile.load(from: r, level: 11)
        XCTAssertEqual([Int(L11.placements[283].type), Int(L11.placements[283].flag)], [2956, 99], "level 11 record 283")
        func revisit(armed: Bool) throws -> SpriteWorld {
            var g = GameGlobals(header: L11.header)
            g.hasSnapshot[11] = 1
            var save = SaveBlock()
            var records = L11.placements
            if armed {
                let p = records[283]
                records[283] = Placement(index: p.index, flag: 1, byte1: p.byte1, type: p.type, p1: p.p1, p2: p.p2,
                                         p3: p.p3, p4: p.p4, y: p.y, x: p.x)
            }
            save.snapshots[11] = records.enumerated().map { i, p in p.reindexed(i).moved(by: -6) }
            var carry = LevelCarry()
            carry.globals = g
            let prefs = FerazelPrefs()
            let run = try LevelRun(resources: r, prefs: prefs, level: 11, seed: 1, carry: carry, save: save,
                                   fade: ScreenFade(), music: MusicFade(), services: LevelFixture.Headless(),
                                   sounds: StageSounds(prefs: prefs, lengths: [:]))
            var now: UInt32 = 0
            while run.session == nil && now < 4000 { _ = try run.tick(now: now, input: FrontInput()); now &+= 1 }
            XCTAssertTrue(run.revisit, "a revisit (armed: \(armed))")
            return try XCTUnwrap(run.session).world
        }
        func dimbo(_ w: SpriteWorld) -> [Int] {
            w.active.sprites.filter { $0.recordIndex == 283 }.map { Int($0.type) }
                + w.idle.entries.compactMap { $0 }.filter { $0.saved.recordIndex == 283 }.map { Int($0.saved.type) }
        }
        let armed = try revisit(armed: true), dormant = try revisit(armed: false)
        XCTAssertEqual(dimbo(armed), [2956], "the armed record appears on the revisit")
        XCTAssertEqual(dimbo(dormant), [], "dormant, it does not")
        // The snapshot stored −6 comes back +6 (`SaveBlock.restoreSnapshot`, `.SetupLevel` M l. 2405–2409): the live
        // record 283 is at the level file's place, its spawn byte as stored, and the armed Dimbo spawns there.
        let p283 = L11.placements[283]
        for (w, flag) in [(armed, 1), (dormant, 99)] {
            let q = w.records[283]
            XCTAssertEqual([Int(q.type), Int(q.flag), Int(q.x), Int(q.y)], [2956, flag, Int(p283.x), Int(p283.y)],
                           "record 283 restored (spawn byte \(flag))")
        }
        let spawned = try XCTUnwrap(armed.active.sprites.first { $0.recordIndex == 283 }?.oldPosition
                                    ?? armed.idle.entries.compactMap { $0 }.first { $0.saved.recordIndex == 283 }?.saved.oldPosition)
        XCTAssertEqual([Int(spawned.x), Int(spawned.y)], [Int(p283.x), Int(p283.y)], "the Dimbo at its record's place")
    }

    /// The parameter trace of level 21 (the script's list and each value's dump line are in the commit body). One
    /// assert each.
    private func traceLevel21(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 21, seed: 1)
        let w = s.world
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }
        /// Record `i`'s Setup slot put on the session's list (its record index kept), as a Handle finds it.
        func put(_ i: Int) throws -> Int {
            var slot = try setup(i).slot
            slot.recordIndex = Int16(i)
            return w.active.insert(slot)
        }

        // The teleporters 1061 (0x425, 14 records; first placed here): p1 is the partner's record index, read by the
        // landing's teleport (`.HitPlayerSprite` M l. 49418–49462, the live record's `+8`) against every in-use idle
        // entry. Each p1 names another 1061 of the level, and exactly one entry holds it at the spawn. Six pairs, and
        // one chain of four: 57 → 60, 58 → 57, 59 → 60, 60 → 59.
        let teleporters = L.activePlacements.filter { $0.type == 1061 }.map(\.index)
        XCTAssertEqual(teleporters, [57, 58, 59, 60, 138, 143, 170, 171, 179, 180, 193, 200, 235, 236], "teleporters")
        XCTAssertEqual(teleporters.map { Int(rec($0).p1) }, [60, 57, 60, 59, 143, 138, 171, 170, 180, 179, 200, 193, 236, 235],
                       "teleporters' p1")
        for i in teleporters {
            let partner = rec(i).p1
            XCTAssertEqual(rec(Int(partner)).type, 1061, "teleporter \(i)")
            XCTAssertEqual(w.idle.inUseEntries(record: partner).count, 1, "teleporter \(i): one entry holds \(partner)")
        }
        // …and the port's teleport reads them (`HitPlayerSprite.teleportMove`, M l. 49418–49462): each teleporter, its
        // record index kept, moves the player to the one entry holding its p1 — the chain included — the player's
        // offset from the teleporter kept. On a session of its own (the move leaves the player there).
        do {
            let ts = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 21, seed: 1)
            let tw = ts.world
            let pid = try XCTUnwrap(tw.playerID)
            let home = try XCTUnwrap(tw.active.record(id: pid))
            for i in teleporters {
                var slot = try setup(i).slot
                slot.recordIndex = Int16(i)
                let tel = tw.active.insert(slot)
                tw.active.update(id: pid) { $0 = home }
                let p0 = try XCTUnwrap(tw.active.record(id: pid)), o = try XCTUnwrap(tw.active.record(id: tel))
                tw.player.teleportTail = tel
                let matched = HitPlayerSprite.teleportMove(tw, player: pid) {}
                XCTAssertEqual(matched.map { tw.idle.entries[$0]?.saved.recordIndex }, [rec(i).p1], "teleporter \(i)")
                let e = try XCTUnwrap(tw.idle.entries[try XCTUnwrap(matched.first, "teleporter \(i)")])
                let p1 = try XCTUnwrap(tw.active.record(id: pid))
                XCTAssertEqual([p1.x - e.saved.x, p1.y - e.saved.y], [p0.x - o.x, p0.y - o.y],
                               "teleporter \(i) → \(rec(i).p1): the offset kept")
                tw.player.teleportTail = nil
                _ = tw.active.remove(id: tel)
            }
        }
        // The passages 2900 (0xb54, records 313 / 314; levels 1–5, 10, 11, 15, 18, 20: p1 another pair, p3 0): p1 the
        // partner (M l. 49594–49683), p3 ≠ 0 → no face (the Handle, M l. 63281–63288: `+0xc` of the record).
        XCTAssertEqual([rec(313).p1, rec(314).p1, rec(313).p3, rec(314).p3], [314, 313, 1, 0], "passages")
        for i in [313, 314] {
            XCTAssertEqual(w.idle.inUseEntries(record: rec(i).p1).count, 1, "passage \(i)")
            let id = try put(i)
            BackgroundSprite.passage(w, id: id)
            XCTAssertEqual(w.active.record(id: id)?.face, i == 313 ? nil : FaceRef(pict: 0xb54, index: 0, set: .encoded),
                           "passage \(i)")
            _ = w.active.remove(id: id)
        }
        // The decoration 2821 (0xb05) p1 1 (record 88; elsewhere p1 0): `+0x17e = 1` (M l. 59668), mirrored.
        XCTAssertEqual([try setup(88).slot.mirrored, try setup(83).slot.mirrored], [true, false], "decorations 88, 83")
        // The rock outcrop 2850 (0xb22, record 98): `.SetupBoxSprite`'s outcrop arm reads `.GetAmbDarkVal(x, y)` (M l.
        // 59688–59695) — the switch 2 gives the cell's light byte 10 (> 7 → 0x10007; levels 1 and 3's outcrops sit on
        // 6 / 7 → 0x10006, `SpriteListTests` holds the thresholds). The twin with hdr 0x2706 patched to 0 reads D 0:
        // no mode.
        do {
            let p = rec(98)
            XCTAssertEqual([Int(p.type), L.lightByte(col: Int(p.x) >> 5, row: Int(p.y) >> 5)], [2850, 10], "outcrop 98")
            XCTAssertEqual(try setup(98).slot.mode, 0x10007, "outcrop 98: D 10 under the switch 2")
            var data = try XCTUnwrap(r.world.resource(type: "Mlvl", id: 21)).data
            data[data.startIndex + 0x2706] = 0
            data[data.startIndex + 0x2707] = 0
            let off = try LevelFile(id: 21, data: data)
            XCTAssertEqual(off.header.darknessEnable, 0, "the twin's switch")
            let c0 = SetupFaces.Context(level: off, playerX: SetupFaces.Context.levelStartPlayerX(off.header))
            XCTAssertEqual(try SetupFaces.setup(off.placements[98], context: c0).slot.mode, 0, "outcrop 98, switch 0")
        }
        // The graves 2833 / 2834 and the NPC 2962: p1 is their conversation (`.HitPlayerSprite`'s talker arms hand it on;
        // `conversations` above). The grave 2836 p1 1: mirrored (6A-BX1a's `.FlipHRect`).
        XCTAssertEqual([rec(207).p1, rec(89).p1, rec(318).p1, rec(90).p1], [260, 261, 300, 1], "graves and the NPC")
        XCTAssertTrue(try setup(90).slot.mirrored, "grave 90")
        // The door 2911 (0xb5f, record 152) p1 0 (levels 1–5: p1 ≥ 1): unlocked — no balloon (M l. 60803–60868). The
        // balloon block runs only with the player within 0x4b of the door's centre (`BoxSprite.playerNear`), so the
        // player's centre is put on the door's; the twin, the locked door 2910 (record 22, p1 1 — key 1), shows its
        // balloon there.
        do {
            XCTAssertEqual([rec(152).type, rec(152).p1, rec(22).type, rec(22).p1], [2911, 0, 2910, 1], "doors 152, 22")
            var lights = LightTable()
            let saved = (w.player.centreX, w.player.centreY)
            for (i, locked) in [(152, false), (22, true)] {
                let id = try put(i)
                let d = try XCTUnwrap(w.active.record(id: id))
                w.player.centreX = Int16(truncatingIfNeeded: d.centre.x)
                w.player.centreY = Int16(truncatingIfNeeded: d.centre.y)
                BoxSprite.doorArm(w, id: id, lights: &lights, effects: 1)
                let b = w.active.record(id: id)?.siblings.first
                XCTAssertEqual(b != nil, locked, locked ? "door \(i): the key balloon" : "door \(i): no key balloon")
                if let b {
                    if let icon = w.active.record(id: b)?.siblings.first { _ = w.active.remove(id: icon) }
                    _ = w.active.remove(id: b)
                }
                _ = w.active.remove(id: id)
            }
            (w.player.centreX, w.player.centreY) = saved
        }
        // The chests 1308 (0x51c): record 109 p2 1300 (the crystal 0x514), p3 4; record 237 p2 1302, p3 30. The opened
        // chest's drop (M l. 60101–60187): `MTNewSprite(p2, …, .SetupBonusSprite)`, p3 > 2 with a light → its light
        // removed, record p3 − 1.
        for (i, type) in [(109, Int16(0x514)), (237, 0x516)] {
            var lights = LightTable()
            let id = try put(i)
            w.active.update(id: id) { $0.phase = 1; $0.counterA6 = 1 }
            let before = Set(w.active.sprites.map(\.id))
            BoxSprite.chestArm(w, id: id, lights: &lights, effects: 1)
            let drop = try XCTUnwrap(w.active.sprites.first { !before.contains($0.id) }, "chest \(i)")
            XCTAssertEqual([Int(drop.type), Int(drop.light), Int(w.records[i].p3)],
                           [Int(type), -1, Int(rec(i).p3) - 1], "chest \(i)")
            _ = w.active.remove(id: drop.id)
            _ = w.active.remove(id: id)
        }
        // The spikes 1840 / 1841 / 1843 (0x730 / 0x731 / 0x733; p2 60 / 30 / 50, p3 100 / 30 / 20, p4 0 / 80 / 10 / 20 —
        // new against 10, 11): `+0x150` = p2, `+0x154` = p3, `+0xa6` = p4, out (`+0x46` 0) when p4 < p2, else in (0xb)
        // (M l. 61982–62015, 62279–62309, 62459–62490).
        // The p2-0 spikes (records 1–4, 49–52) included: `+0x150` = 32000, never retracting (M l. 62459–62490).
        for p in L.activePlacements where (1840...1843).contains(p.type) {
            let k = try SetupFaces.setup(p, context: c).slot
            let out = p.p2 == 0 ? 32000 : Int(p.p2)
            XCTAssertEqual([Int(k.classWord150), Int(k.classWord154), Int(k.counterA6), Int(k.phase)],
                           [out, Int(p.p3), Int(p.p4), Int(p.p4) < out ? 0 : 0xb], "spike \(p.index)")
        }
        // The swarm 1869 (0x74d, record 103) p2 9 (levels 10, 11: 8 / 6 / 12): nine members (M l. 68160–68213).
        do {
            let e = try XCTUnwrap(w.idle.entries.compactMap { $0 }.first { $0.saved.recordIndex == 103 })
            XCTAssertEqual([Int(e.saved.swarm?.total ?? 0), e.saved.swarm?.members.count ?? 0], [9, 9], "swarm 103")
        }
        // The path bats 1741 (0x6cd, records 53, 54) and 1742 (0x6ce, record 55; first placed here, → 0x6cd with
        // `+0x154` = R(0x50) + 0x32), p1 1, p2 100 / 60, p3 768 / 512 (level 3: p2 / p3 others): `.SetupProgrammedPath`
        // (M l. 68287–68300, 39288–39381) — mode 1, `+0x100` = y256 + 8·p3, `+0x104` = y256 + 256·p2 − 8·p3, vy = p3.
        for i in [53, 54, 55] {
            let p = rec(i)
            let k = try setup(i).slot
            let y256 = Int32(p.y) << 8
            XCTAssertEqual([Int32(k.type), k.pathMode, k.pathLow, k.pathHigh, k.vy],
                           [0x6cd, 1, y256 + 8 * Int32(p.p3), y256 + 256 * Int32(p.p2) - 8 * Int32(p.p3), Int32(p.p3)],
                           "bat \(i)")
        }
        // The mace 1487 (0x5cf, record 263; first placed here) p1 13, p2 80, p3 2800, p4 200: modes 10…14 (M l.
        // 62362–62427) — persp 1 (13), `.MakeRadial(r = 80, speed = 2800, angle = 200)`, 80 / 16 = 5 links 0x59a.
        do {
            XCTAssertEqual([rec(263).p1, rec(263).p2, rec(263).p3, rec(263).p4], [13, 80, 2800, 200], "mace 263")
            let ball = try XCTUnwrap(w.active.sprites.first { $0.recordIndex == 263 }
                                     ?? w.idle.entries.compactMap { $0 }.first { $0.saved.recordIndex == 263 }?.saved)
            let rad = try XCTUnwrap(ball.radial)
            XCTAssertEqual([Int(ball.subtype), Int(rad.radius), Int(rad.speed), Int(rad.persp), Int(rad.spokeCount)],
                           [13, 80 << 8, 2800, 1, 5], "mace 263")
            XCTAssertFalse(ball.lightOverlay, "persp ≠ 0 clears `+0x88`")
        }
        // The platforms (their Setup is the first Handle's `.DoSetupPlatformSprite`, M l. 54541–55025): 1400 (0x578)
        // records 0, 48 mode 6 (→ 2, sag 0, `+0x15c` 1; the horizontal shuttle, M l. 54665–54677); 165, 177 mode 1 (the
        // vertical shuttle, M l. 54652–54664); 1403 (0x57b) records 5, 6 mode 7 (→ 1, sag 0, `+0x15c` = `+0x158` = 1;
        // y += 256·p4); 1401 (0x579) records 110…120 mode 52 (blinking, M l. 54931–54948); 1400 records 91…95 mode 51
        // (crumbling, M l. 54965–54979; p4 1…5 → the pitched break-up sound, M l. 55275–55354); 1403 record 149 mode 20
        // (a wheel of three, p2 55 → 55 / 12 = 4 links each, M l. 54697–54746).
        func doSetup(_ i: Int) throws -> SpriteSlot {
            let id = try put(i)
            PlatformSprite.doSetup(w, id: id)
            return try XCTUnwrap(w.active.record(id: id))
        }
        for i in [0, 48, 165, 177, 5, 6] {
            let p = rec(i)
            let before = try setup(i).slot
            let k = try doSetup(i)
            let horizontal = p.p1 == 6
            let v: Int = Int(horizontal ? before.x256 : before.y256)
            let p2 = Int(p.p2), p3 = Int(p.p3), p4 = Int(p.p4)
            let got: [Int] = [Int(k.subtype), Int(k.sag), Int(k.classWord15c), Int(k.classWord158), Int(k.classWord150),
                              Int(k.classWord154), Int(horizontal ? k.vx : k.vy)]
            let want: [Int] = [horizontal ? 2 : 1, 0, p.p1 == 1 ? 0 : 1, p.p1 == 7 ? 1 : 0,
                               v + 8 * p3, v + 256 * p2 - 8 * p3, p3]
            XCTAssertEqual(got, want, "platform \(i)")
            XCTAssertEqual(Int(horizontal ? k.x256 : k.y256), v + 256 * p4, "platform \(i): p4")
            _ = w.active.remove(id: k.id)
        }
        for i in 110...120 {
            let p = rec(i)
            let k = try doSetup(i)
            XCTAssertEqual([Int(k.subtype), Int(k.classTimer), Int(k.classWord150), Int(k.classWord154), Int(k.counterA6),
                            Int(k.phase)], [0x34, 52, 25, 250, Int(p.p4), p.p4 < 25 ? 0 : 0x14], "blinking \(i)")
            _ = w.active.remove(id: k.id)
        }
        for i in 91...95 {
            let p = rec(i)
            let k = try doSetup(i)
            XCTAssertEqual([Int(k.subtype), Int(k.classTimer), Int(k.classWord150)], [0x33, 2, 0x2d], "crumbling \(i)")
            w.active.update(id: k.id) { $0.counterA6 = 0 }
            _ = w.player.drainFrameOutputs()
            PlatformSprite.crumble(w, id: k.id)
            let cue = try XCTUnwrap(w.player.drainFrameOutputs().cues.first { $0.snd == 461 }, "crumbling \(i)")
            XCTAssertEqual([Int(cue.volume), Int(cue.rate ?? 0)], [0x100, Int(p.p4) * 0xf3b + 0x10000], "crumbling \(i)")
            _ = w.active.remove(id: k.id)
        }
        do {
            let before = Set(w.active.sprites.map(\.id))
            let k = try doSetup(149)
            XCTAssertEqual([rec(149).p1, rec(149).p2], [20, 55], "platform 149")
            let made = w.active.sprites.filter { !before.contains($0.id) && $0.id != k.id }
            XCTAssertEqual([made.filter { $0.type == 0x57b }.count, made.filter { $0.type == ChainSprite.link }.count],
                           [2, 12], "two siblings; 4 links on each of the three")
        }
        // The rope 3022 (0xbce, record 156) p1…p4 7694, 1533, 8113, 1460 — its two ends: `.SetupRopeSegArray` (M l.
        // 71245–71455) — span 419 → (419 + 12) / 24 = 17 segments of 24 = 408, dy = 1460 − 1533 = −73.
        do {
            let id = try put(156)
            RopeSprite.setupSegArray(w, id: id)
            let k = try XCTUnwrap(w.active.record(id: id))
            XCTAssertEqual([Int(k.classWord150), Int(k.classTimer), Int(k.rope?.dy ?? 0)], [17, 408, -73], "rope 156")
        }
        // The Bonus 1291 (records 285–288), 1293 (301), 3206 (305…), 3219 (302), all p1 0 here: the default gravity (p1 ≠ 0
        // alone zeroes it — M l. 52496–52500, 52704–52706).
        for p in L.activePlacements where [1291, 1293, 3206, 3219].contains(p.type) {
            XCTAssertEqual(p.p1, 0, "Bonus \(p.index)")
            XCTAssertNotEqual(try SetupFaces.setup(p, context: c).slot.gravity, 0, "Bonus \(p.index)")
        }
    }

    func testBuiltLevelsTwentyOne() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21], "the built levels")
        XCTAssertTrue(BuiltLevels.contains(21), "level 21")
        for n in [12, 16, 19, 22, 25, 40] { XCTAssertFalse(BuiltLevels.contains(n), "level \(n)") }
        XCTAssertEqual(BuiltLevels.notBuiltReport(22), "Level 22 is not built yet (Phase 6).", "level 22's report")
        let r = try TenEleven.resources()
        // `startLevel` 21 (the hidden `FerazelLevel` switch) is accepted: New Game there, nothing asked.
        let rig = TenElevenRig(r, start: 21)
        rig.newGame(level: 21)
        XCTAssertEqual(rig.flow.levelNumber, 21, "New Game at 21")
        XCTAssertEqual(rig.levels.prepared, [21], "level 21 prepared")
        XCTAssertEqual(rig.asked, [], "nothing asked")
        // The map: node 21's links [20, 22, 70] (node 20's [15, 21]: level 20's exit 311 → node 21, `LevelTwentyTests`).
        let map = try WorldMap.load(from: r)
        XCTAssertEqual(try XCTUnwrap(map.findCurrNode(level: 21)).links, [20, 22, 70, 0, 0, 0, 0], "node 21's links")
        // Level 21's exit p1 1 (record 140) → node 22 (links[1]) → Return → the not-built report, still on the map.
        let L = try LevelFile.load(from: r, level: 21)
        XCTAssertEqual(L.activePlacements.filter { $0.type == 3249 }.map { [$0.index, Int($0.p1)] },
                       [[139, 0], [140, 1], [260, -1], [315, 2]], "level 21's exits")
        try rig.exit(140, toNode: 22)
        XCTAssertEqual(rig.asked.last, .report(text: "Level 22 is not built yet (Phase 6)."), "the not-built report")
        XCTAssertNil(rig.flow.levelRun, "still on the map")
        XCTAssertEqual(rig.levels.prepared, [21], "no level prepared after 21")
        // A save made on level 21 (a save point's block, the level's own records) continues there through
        // `.ContinueGame`: level 21 runs, nothing asked.
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 21, x: L.header.startX, y: L.header.startY,
                           stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L.placements)
        let cont = TenElevenRig(r, start: 1)
        cont.files.block = save
        cont.drive { $0.state == .mainMenu }
        cont.drive({ _ in [0x0f] }) { _ in true }                          // R: Continue
        cont.drive { _ in cont.askedFile }
        cont.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/twentyOne"),
                                                displayName: "twentyOne")))
        cont.drive { f in f.levelRun?.levelNumber == 21 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(cont.asked, [], "Continue: nothing asked")
        XCTAssertEqual(cont.flow.levelNumber, 21, "Continue: level 21")
        XCTAssertEqual(cont.levels.prepared, [21], "Continue: level 21 prepared")
    }
}

import XCTest
import HectorResources
@testable import FerazelCore

/// LV4 (docs/plans/2026-10-24-ferazel-phase4.md): level 4 "Eastern Reaches" enterable — every one of its 250 records
/// sets up (its new types are the switch blocks 1250, the spouts 1450 / 1453, the Buttons 1320 / 1322, the Bonus 1331,
/// 1334, 1340, 3216 and the Platform 1410, all built by earlier tasks), `BuiltLevels = 1...4`, and the not-built
/// report names "(Phases 5-6)" (Ruling 2): level 5 (Manditraki Warrior) is a boss and stays refused — until LV5, which
/// builds level 5 (`BuiltLevels = 1...5`, the report "(Phase 6)."): level 4's exit p1 1 now enters level 5. Against
/// the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip.
final class LevelFourTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    func testLevel4SetsUpEveryRecord() throws {
        let r = try resources()
        let L = try LevelFile.load(from: r, level: 4)
        XCTAssertEqual(L.activePlacements.count, 250)
        XCTAssertEqual(Set(L.activePlacements.map(\.type)).count, 33)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        // Every record sets up: no `notTranscribed` (nor any other refusal).
        var refused: [Int16] = []
        for p in L.activePlacements where (try? SetupFaces.setup(p, context: c)) == nil { refused.append(p.type) }
        XCTAssertEqual(refused, [])
        let sp = try SetupFaces.spawnLevelSprites(context: c) { _ in .noFace }
        XCTAssertEqual(sp.created.count, 250)
        XCTAssertEqual(sp.active.sprites.filter { $0.recordIndex >= 0 }.count + sp.idle.entries.compactMap { $0 }.count, 250)
        // The level's enemy total (`*_DAT_1009ffb4`): 11 Walkers, 6 Crawlers, 6 Frogs, 6 Bats, 1 Blob, 5 Roaches — every
        // enemy Setup counts once (the Phase-1 face stubs, Ruling 3): 35.
        let classes = L.activePlacements.compactMap { SpriteClassTable.classify(type: $0.type, p1Negative: $0.p1 < 0)?.0 }
        XCTAssertEqual([.walker, .crawler, .frog, .bat, .blob, .roach].map { k in classes.filter { $0 == k }.count },
                       [11, 6, 6, 6, 1, 5])
        XCTAssertEqual(sp.tallies.enemies, 35)
        let session = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 4)
        XCTAssertEqual(session.tallies.enemies, 35)
        XCTAssertEqual(session.level.id, 4)

        func entry(_ rec: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(L.placements[rec], context: c) }
        func f(_ pict: Int16, _ i: Int = 0) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }
        func set(_ pict: Int16, _ n: Int, _ w: Int, _ h: Int, _ cols: Int) -> SetupFaces.Sheet {
            SetupFaces.Sheet(pict: pict, count: n, cellWidth: w, cellHeight: h, columns: cols, clut: 200)
        }
        // The new types' entries (Research note 1): the switch block 1250 (rec 53: p1 2, p2 57 — Button 57's), the spouts
        // 1450 (rec 28) and 1453 (rec 68, cell 3 of the set 1450), the Buttons 1320 (rec 63) / 1322 (rec 30), the Bonus
        // 1331 (rec 39), 1334 (rec 74), the upgrade 1340 (rec 32), the gold ring 3216 (rec 161), the Platform 1410 (rec
        // 29) and the Walker 1760 with p1 1 (rec 119, the 0x6e0 arm whatever its p1 — M l. 56989–56995).
        var e = try entry(53)
        XCTAssertEqual([e.slot.handler, e.slot.face, e.sheet] as [AnyHashable?], [SpriteHandler.box, f(1250),
                                                                                  set(1250, 21, 36, 36, 7)])
        e = try entry(28)
        XCTAssertEqual([e.slot.handler, e.slot.face, e.sheet] as [AnyHashable?], [SpriteHandler.box, f(1450),
                                                                                  set(1450, 4, 32, 32, 4)])
        e = try entry(68)
        XCTAssertEqual([e.slot.face, e.sheet] as [AnyHashable?], [f(1450, 3), set(1450, 4, 32, 32, 4)])
        e = try entry(63)
        XCTAssertEqual([e.slot.handler, e.sheet] as [AnyHashable?], [SpriteHandler.button, set(1320, 6, 14, 12, 6)])
        e = try entry(30)
        XCTAssertEqual([e.slot.handler, e.sheet] as [AnyHashable?], [SpriteHandler.button, set(1322, 8, 32, 21, 8)])
        for (rec, pict) in [(39, 1331), (74, 1334), (161, 3216)] as [(Int, Int16)] {
            e = try entry(rec)
            XCTAssertEqual([e.slot.handler, e.slot.face, e.sheet] as [AnyHashable?],
                           [SpriteHandler.bonus, f(pict), SetupFaces.Sheet.single(pict)], "rec \(rec)")
        }
        e = try entry(32)
        XCTAssertEqual([e.slot.handler, e.slot.face, e.sheet] as [AnyHashable?], [SpriteHandler.bonus, f(1340),
                                                                                  set(1340, 6, 44, 42, 6)])
        e = try entry(29)
        XCTAssertEqual([e.slot.handler, e.sheet] as [AnyHashable?], [SpriteHandler.platform, set(1410, 7, 216, 200, 1)])
        e = try entry(119)
        XCTAssertEqual(L.placements[119].p1, 1)
        // WK1 (seat ruling): 1760 is a Walker type — `.walker`, and `.SetupWalkerSprite` installs its hit callback
        // `+0x5c = .HitWalkerSprite` (M l. 56925–56929). WK2: its Handle's 1760 arm (`Walker.boulderArm`) throws
        // 0x6e1 + p1 = 0x6e2, the bomb boulder (M l. 58049–58053) — its Setup entry is unchanged.
        XCTAssertEqual([e.slot.handler, e.slot.face, e.sheet] as [AnyHashable?], [SpriteHandler.walker, f(1760),
                                                                                  set(1760, 9, 84, 92, 9)])
        XCTAssertEqual([e.slot.countedInTotals, e.slot.hasHit], [true, true])
        XCTAssertEqual(e.source, .setupCached)
        // The chests' drops (Research note 3): rec 55 the Steel Key 3201, 112 ten 1305s, 179 twenty coins 1302; no
        // crate. None is a candelabra 0xc25 or an item past 0xc9a (the two `notTranscribed` Bonus arms).
        let drops = L.activePlacements.filter { $0.type == BoxSprite.chest || BoxSprite.crates.contains($0.type) }
            .map { [Int($0.index), Int($0.p2), Int($0.p3)] }
        XCTAssertEqual(drops, [[55, 3201, 1], [112, 1305, 10], [179, 1302, 20]])
        XCTAssertFalse(L.activePlacements.contains { $0.type == 0xc25 || (0xc9b...0xcb0).contains($0.type) })
        // The level-load bar (`.LoadCachedSpriteFaces` M l. 73769–73868) on a fresh cache: level 4's placed types add
        // no mark of their own (the switch blocks and the spouts face from the boot sets `_DAT_100a0a54` / `0a4c`, M l.
        // 59584 / 59597; Buttons, the Platform 1410 and the Bonus types mark nothing) — the sets in registration order,
        // Crawler 0x6ae, 0x6af, 0x6b1 (6 each), Roach 0x6b8, 0x6b9 (6 each), Walker 0x6a5 (8), 0x6a6 (6), 0x6a9 (3),
        // 0x6aa (2), 0x6ab (9), 0x6e0 (9), Bat 0x6cc (11), Blob 0x6c2 (16), Frog 0x708 (8): 102 faces — then 4 singles
        // (Walker 0x6a4, the NPC 0xb88, the bridge 0x5b8, the sign 0xb54): n = 106, q = 212, 18 steps.
        var cache = CachedFaces()
        cache.enterLevel(screenClut: L.header.screenClut)
        let needed = CachedFaces.needed(by: session)
        XCTAssertEqual(needed.sets, [0x6ae, 0x6af, 0x6b1, 0x6b8, 0x6b9, 0x6a5, 0x6a6, 0x6a9, 0x6aa, 0x6ab, 0x6e0, 0x6cc,
                                     0x6c2, 0x708])
        XCTAssertEqual(needed.singles, [0x6a4, 0xb88, 0x5b8, 0xb54])
        let bars = cache.load(needed: needed)
        XCTAssertEqual(bars.map { $0.0 }, [112, 118, 124, 130, 136, 144, 150, 153, 155, 164, 173, 184, 200, 208]
                        + Array(209...212))
        XCTAssertEqual(Set(bars.map { $0.1 }), [212])
    }

    // MARK: - the map and the switch

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

    /// A flow with the hidden `FerazelLevel` switch at `start`; `drive` ticks it until `until` holds, collecting the
    /// dialogs asked.
    private final class Rig {
        let levels = Levels()
        let flow: GameFlow
        var t: UInt32 = 1000
        var asked: [FerazelDialog] = []
        init(_ r: FerazelResources, start: Int) {
            flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: NoFiles(), levels: levels)
            flow.startLevel = start
        }
        func drive(_ keys: (GameFlow) -> [Int] = { _ in [] }, until: (GameFlow) -> Bool) {
            for _ in 0..<6000 {
                if case .loading = flow.state { flow.loadFinished() }
                let out = flow.tick(now: t, input: FrontInput(keys: KeyState(pressed: keys(flow))))
                asked += out.requests.compactMap { if case .dialog(let d) = $0 { return d }; return nil }
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
        /// The level's exit `record` touched → the map's auto-walk to the node of `level` → Return; the map walked.
        @discardableResult
        func exit(_ record: Int, toNode level: Int) throws -> WorldMapRun {
            try touchExit(try XCTUnwrap(flow.levelRun?.session), record: record)
            drive { f in (f.worldMap.map { $0.iterations >= 2 && $0.walkStep == 0 && $0.result == nil }) ?? false }
            let m = try XCTUnwrap(flow.worldMap)
            XCTAssertEqual(m.cur, try XCTUnwrap(m.map.findCurrNode(level: Int16(level))).index)
            let before = asked.count
            drive({ f in f.worldMap?.result == nil ? [0x24] : [] }) { f in f.worldMap == nil || self.asked.count > before }
            return m
        }
    }

    func testBuiltLevelsFour() throws {
        XCTAssertTrue(BuiltLevels.contains(4))
        let r = try resources()
        // Level 2's exit p1 2 (record 98) → node 4 → Return → level 4 runs, its every record set up by the session.
        let rig = Rig(r, start: 2)
        rig.newGame(level: 2)
        try rig.exit(98, toNode: 4)
        XCTAssertEqual(rig.asked, [])
        rig.drive { f in f.levelRun?.levelNumber == 4 && (f.levelRun?.iterations ?? 0) >= 45 }
        XCTAssertEqual(rig.flow.levelNumber, 4)
        XCTAssertEqual(rig.flow.levelRun?.session?.tallies.enemies, 35)
        XCTAssertEqual(rig.levels.prepared, [2, 4])
        // Level 4's exit p1 1 (record 71; Research note 2: 4 → [2, 5]) → node 5 → Return → level 5 runs (LV5: built),
        // nothing asked, its every record set up by the session — the Warrior its one counted enemy.
        let exit = try LevelFile.load(from: r, level: 4).placements[71]
        XCTAssertEqual([exit.type, exit.p1], [3249, 1])
        try rig.exit(71, toNode: 5)
        rig.drive { f in f.levelRun?.levelNumber == 5 && (f.levelRun?.iterations ?? 0) >= 45 }
        XCTAssertEqual(rig.asked, [])
        XCTAssertEqual(rig.flow.levelNumber, 5)
        XCTAssertEqual(rig.flow.levelRun?.session?.tallies.enemies, 1)
        XCTAssertEqual(rig.levels.prepared, [2, 4, 5])
    }

    func testStartLevelSwitch() throws {
        // The hidden `FerazelLevel` switch (`GameFlow.startLevel`, GameFlow.swift:170): 4 → New Game at level 4; 5 →
        // level 5 (LV5: in `BuiltLevels.list`; before it, `NewGame`'s clamp sent it to level 1).
        let r = try resources()
        let four = Rig(r, start: 4)
        four.newGame(level: 4)
        XCTAssertEqual(four.flow.levelNumber, 4)
        XCTAssertEqual(four.levels.prepared, [4])
        XCTAssertEqual(four.asked, [])
        let five = Rig(r, start: 5)
        five.newGame(level: 5)
        XCTAssertEqual(five.flow.levelNumber, 5)
        XCTAssertEqual(five.levels.prepared, [5])
        XCTAssertEqual(five.asked, [])
    }
}

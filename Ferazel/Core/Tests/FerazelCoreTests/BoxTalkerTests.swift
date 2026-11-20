import XCTest
@testable import FerazelCore

/// 6A-BX1b (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-BX1b`; docs/ferazel/later-levels-ledger.md
/// §8(a), §6): the Box faces and talkers of levels 10–22 — the teleporters 1060 / 1061 (`.SetupBoxSprite` M l.
/// 58950–58995: `+0xc0` = the boot singles 0x424 / 0x425, `.InitBoxSprite` M l. 58737–58740), the furniture 2921 (M l.
/// 59603–59640) and the NPCs 2955, 2956, 2962 (M l. 59715–59721): their faces in the Setup-face table, the cache
/// singles their Setups mark, and the conversations the NPCs open through `.HitPlayerSprite`'s NPC arm (M l.
/// 49199–49210). Records are read per record through `SetupFaces.setup` and met on synthetic contacts (levels 21 and
/// 22 still hold other refused records, so no level is opened). A missing data file is a FAILURE, never a skip.
final class BoxTalkerTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The later levels the world file holds in 10…22.
    private static let levels: [Int16] = [10, 11, 15, 18, 20, 21, 22]

    private static let teleporters: [Int16] = [1060, 1061]
    private static let furniture: Int16 = 2921
    private static let npcs: [Int16] = [2955, 2956, 2962]

    /// LL §6's singles (list positions, 1-based) the furniture and NPC Setups mark: `_DAT_100a0a04[type − 0xb68]`
    /// (M l. 59604, registered `.InitBoxSprite` M l. 58830) and `_DAT_100a0a6c[type − 0xb86]` (M l. 59716, M l. 58781).
    private static let positions: [Int16: Int] = [2921: 118, 2955: 60, 2956: 61, 2962: 67]

    /// The NPC records of levels 10–22 (World Data): (level, record, type, flag, p1 = the Mcnv id).
    private static let talkers: [(level: Int16, record: Int, type: Int16, flag: UInt8, p1: Int16)] = [
        (11, 135, 2955, 1, 206), (11, 283, 2956, 99, 220), (21, 318, 2962, 1, 300), (22, 405, 2956, 1, 221),
    ]

    /// A world on `L` holding a player (no level opened: `.SetupLevel` is not run).
    private func world(_ L: LevelFile) throws -> (SpriteWorld, Int) {
        let w = SpriteWorld(level: L)
        let p = try XCTUnwrap(Player.spawn(world: w, x: 2000, y: 1000))
        w.playerID = p
        return (w, p)
    }

    // MARK: - the teleporters

    func testTeleporterFacesFromBootSingles() throws {
        let r = try resources()
        var byLevel: [Int16: [Int16: Int]] = [:]
        var modes: [String: UInt32] = [:]
        for level in Self.levels {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in L.activePlacements where Self.teleporters.contains(p.type) {
                byLevel[level, default: [:]][p.type, default: 0] += 1
                let what = "L\(level) record \(p.index) type \(p.type)"
                let e: SetupFaces.Entry
                do { e = try SetupFaces.setup(p, context: c) } catch {
                    XCTFail("\(what): \(error)")
                    continue
                }
                let s = e.slot
                // `+0xc0` = `*_DAT_100a0ab0` (0x424, M l. 58985) / `*_DAT_100a0aac` (0x425, M l. 58954): the boot singles
                // `.Load1EncFaceFromPICT(0x424 / 0x425)` (M l. 58737–58740) — faced at Setup, cell 0, clut 200.
                XCTAssertEqual(e.sheet, SetupFaces.Sheet.single(p.type), what)
                XCTAssertEqual(e.source, .setup, what)
                XCTAssertEqual(e.faceIndex, 0, what)
                XCTAssertEqual(s.face, FaceRef(pict: p.type, index: 0, set: .encoded), what)
                XCTAssertEqual(e.spawn, .idle, what)
                XCTAssertEqual(e.spriteClass, .box, what)
                XCTAssertEqual(e.record, p, "\(what): nothing written back")
                // `+0x110 = 0`, `+0x185 = 1`, `SetRect(+0x34, 0, −4, 0x20, 0x1a)` (M l. 58955–58957, 58986–58988).
                XCTAssertEqual(s.gravity, 0, what)
                XCTAssertTrue(s.oneWay, what)
                XCTAssertEqual(s.hotRect, Rect(top: -4, left: 0, bottom: 0x1a, right: 0x20), what)
                XCTAssertEqual(s.layer, 2, what)
                // The `.IsWaterTile` test at (x >> 5, (y + 0xc) >> 5) → `+0xb8 = 0x90000` (M l. 58958–58963): the same
                // test as the built teleporter 0x426's (M l. 59017–59022) at the same place.
                let q = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: 0x426, p1: p.p1, p2: p.p2,
                                  p3: p.p3, p4: p.p4, y: p.y, x: p.x)
                let e3 = try SetupFaces.setup(q, context: c)
                XCTAssertEqual(s.mode, e3.slot.mode, what)
                XCTAssertTrue(s.mode == 0 || s.mode == 0x90000, what)
                modes["\(level):\(p.index)"] = s.mode
            }
        }
        // The water test is live, measured per record: level 21's records 193 (x 5384, y 1906) and 200 (x 9658, y 1941)
        // stand on a liquid BG cell (kind 200…209) → `+0xb8 = 0x90000` (M l. 58958–58963); the other 20 teleporters of
        // 10–22 are dry (mode 0) — level 21 record 57 (x 116, y 375) named as one.
        XCTAssertEqual(modes.count, 22)
        XCTAssertEqual(modes.filter { $0.value != 0 }, ["21:193": 0x90000, "21:200": 0x90000])
        XCTAssertEqual(modes["21:57"], 0)
        // The test reads the cell at (x >> 5, (y + 0xc) >> 5): in record 193's column 168 the liquid starts at row 54
        // (row 53 empty), so the record moved up to y 1716 reads row 54 (wet) and at y 1715 row 53 (dry) — the `+ 0xc`
        // as read (y >> 5 is 53 for both).
        let L21 = try LevelFile.load(from: r, level: 21)
        let r193 = L21.placements[193]
        for (y, mode) in [(Int16(1716), UInt32(0x90000)), (1715, 0)] {
            let moved = Placement(index: r193.index, flag: r193.flag, byte1: r193.byte1, type: r193.type, p1: r193.p1,
                                  p2: r193.p2, p3: r193.p3, p4: r193.p4, y: y, x: r193.x)
            let e = try SetupFaces.setup(moved, context: SetupFaces.Context(level: L21, playerX: 0))
            XCTAssertEqual(e.slot.mode, mode, "record 193 at y \(y)")
        }
        // LL §4: 1061 × 14 on level 21, 1060 × 8 on level 22; none elsewhere in 10–22.
        XCTAssertEqual(byLevel, [21: [1061: 14], 22: [1060: 8]])
        // The faces are boot singles: in the boot list (`BootFaces`) and the Setup-face table; the Setups mark no
        // cache record (`.Load1EncFaceFromPICT`, not a cache registration).
        for t in Self.teleporters {
            XCTAssertTrue(BootFaces.sheets.contains(.single(t)), "\(t)")
            XCTAssertEqual(SetupFaces.sheet(pict: t), .single(t), "\(t)")
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [], "\(t)")
            XCTAssertFalse(CachedFaces.singles.contains { $0.pict == t }, "\(t)")
            XCTAssertFalse(CachedFaces.sets.contains { $0.pict == t }, "\(t)")
        }
        // The built teleporter 0x426 keeps its arm and face.
        XCTAssertEqual(SetupFaces.sheet(pict: 0x426), .single(0x426))
    }

    // MARK: - the furniture and the NPCs

    func testFurnitureAndNpcFacesSetUp() throws {
        let r = try resources()
        var byLevel: [Int16: [Int16: Int]] = [:]
        let types = [Self.furniture] + Self.npcs
        for level in Self.levels {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in L.activePlacements where types.contains(p.type) {
                byLevel[level, default: [:]][p.type, default: 0] += 1
                let what = "L\(level) record \(p.index) type \(p.type)"
                let e: SetupFaces.Entry
                do { e = try SetupFaces.setup(p, context: c) } catch {
                    XCTFail("\(what): \(error)")
                    continue
                }
                let s = e.slot
                // `+0xc0` stays 0 at Setup: the Handle faces them from their cache single (clut 200, flag 0).
                XCTAssertEqual(e.sheet, SetupFaces.Sheet.single(p.type), what)
                XCTAssertEqual(e.source, .handle, what)
                XCTAssertEqual(e.faceIndex, 0, what)
                XCTAssertEqual(s.face, FaceRef(pict: p.type, index: 0, set: .encoded), what)
                XCTAssertEqual(e.spawn, .idle, what)
                XCTAssertEqual(e.spriteClass, .box, what)
                XCTAssertEqual(e.record, p, "\(what): nothing written back")
                // `+0x46 = 0`, `+0x110 = 0`, layer `+0x80 = 0` (M l. 59605–59607, 59717–59719).
                XCTAssertEqual(s.gravity, 0, what)
                XCTAssertEqual(s.layer, 0, what)
                XCTAssertEqual(s.phase, 0, what)
                if p.type == Self.furniture {
                    // 0xb69: `SetRect(+0x34, 5, 1, 0x32, 0x3a)`, no `+0x185` (M l. 59612–59613).
                    XCTAssertEqual(s.hotRect, Rect(top: 1, left: 5, bottom: 0x3a, right: 0x32), what)
                    XCTAssertFalse(s.oneWay, what)
                } else {
                    // NPCs: `+0x185 = 1` (M l. 59720); the rect comes from the Handle's face.
                    XCTAssertTrue(s.oneWay, what)
                }
            }
        }
        // LL §4: 2955 × 1 on level 11; 2921 × 2 and 2962 × 1 on level 21; 2956 × 1 on level 22 (level 11's 2956,
        // record 283, has flag 99: not active).
        XCTAssertEqual(byLevel, [11: [2955: 1], 21: [2921: 2, 2962: 1], 22: [2956: 1]])
        // The marks: each type's own cache single (LL §6), flag 0, present in the data; no other type marks one.
        var talkers = Set<CachedFaces.RecordKey>()
        for t in types {
            XCTAssertEqual(SetupFaces.sheet(pict: t), .single(t), "\(t)")
            let k = CachedFaces.RecordKey.single(Self.positions[t]! - 1)
            talkers.insert(k)
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
            XCTAssertEqual(CachedFaces.markedRecords(type: t, p1: 1), [k], "\(t) p1 1")
            XCTAssertEqual(CachedFaces.record(k).pict, t, "\(t)")
            XCTAssertEqual(CachedFaces.record(k).flag, 0, "\(t)")
            XCTAssertTrue(CachedFaces.record(k).present, "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [t], "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [], "\(t)")
        }
        for t in Int16(0)...0x0d00 where !types.contains(t) {
            XCTAssertTrue(Set(CachedFaces.markedRecords(type: t)).isDisjoint(with: talkers), "\(t)")
        }
        // Level by level, the singles these records mark (every record sets up, per record).
        let expected: [Int16: Set<Int16>] = [11: [2955], 21: [2921, 2962], 22: [2956]]
        for level in Self.levels {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            var marked = Set<CachedFaces.RecordKey>()
            for p in L.activePlacements where types.contains(p.type) {
                _ = try SetupFaces.setup(p, context: c)
                marked.formUnion(CachedFaces.markedRecords(type: p.type, p1: p.p1))
            }
            XCTAssertEqual(CachedFaces.Needed(records: marked).singles, expected[level] ?? [], "level \(level)")
            XCTAssertTrue(CachedFaces.Needed(records: marked).sets.isEmpty, "level \(level)")
        }
    }

    // MARK: - the conversations

    func testNpcConversationIds() throws {
        let r = try resources()
        // Every NPC record (any flag) of levels 10–22 is one of the four.
        var found: [String] = []
        for level in Self.levels {
            for p in try LevelFile.load(from: r, level: level).placements where HitPlayerSprite.npcs.contains(p.type) {
                found.append("\(level):\(p.index)")
            }
        }
        XCTAssertEqual(found, Self.talkers.map { "\($0.level):\($0.record)" })
        for t in Self.talkers {
            let L = try LevelFile.load(from: r, level: t.level)
            let p = L.placements[t.record]
            let what = "L\(t.level) record \(t.record)"
            XCTAssertEqual([p.type, p.p1, p.p4], [t.type, t.p1, 0], what)
            XCTAssertEqual(p.flag, t.flag, what)
            XCTAssertNoThrow(try Conversation.load(from: r, id: t.p1), "Mcnv \(t.p1)")
            let spawned = SetupFaces.spawnOrder(L.placements).contains { $0.index == t.record }
            if t.flag != 1 {
                // Record 283 (flag 99) is dormant: `.SetupLevelSprites` spawns flag-1 records only (M l. 1940–2101), so
                // no sprite stands for it and it does not talk; Mcnv 221's action 10 arms it in the save snapshot.
                XCTAssertFalse(spawned, what)
                XCTAssertFalse(L.activePlacements.contains { $0.index == t.record }, what)
                continue
            }
            XCTAssertTrue(spawned, what)
            // A synthetic contact: the NPC arm → `.Conversation(p1, +0x48, the sprite)`, cooldown 150, p4 untouched.
            let (w, pid) = try world(L)
            let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: L, playerX: 0))
            let id = w.active.insert(e.slot)
            XCTAssertEqual(w.player.countdown06cc, 0)
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertEqual(w.suspension, .conversation(id: t.p1, record: t.record, sprite: id), what)
            XCTAssertEqual(w.player.countdown06cc, 0x96, what)      // `*PTR_DAT_100a06cc = 0x96` (M l. 49207): 150, as read
            XCTAssertEqual(w.records[t.record].p4, 0, what)
            // In the cooldown: nothing more.
            w.suspension = nil
            HitPlayerSprite.hit(w, player: pid, other: id)
            XCTAssertNil(w.suspension, "\(what): cooldown")
        }
        // The dormant record armed (flag 1, as Mcnv 221's action 10 leaves level 11's snapshot) sets up and talks 220.
        let L11 = try LevelFile.load(from: r, level: 11)
        let d = L11.placements[283]
        let armed = Placement(index: d.index, flag: 1, byte1: d.byte1, type: d.type, p1: d.p1, p2: d.p2, p3: d.p3,
                              p4: d.p4, y: d.y, x: d.x)
        var records = L11.placements
        records[283] = armed
        let w = SpriteWorld(level: L11, records: records)
        let pid = try XCTUnwrap(Player.spawn(world: w, x: 2000, y: 1000))
        w.playerID = pid
        let e = try SetupFaces.setup(armed, context: SetupFaces.Context(level: L11, playerX: 0))
        XCTAssertEqual(e.sheet, .single(2956))
        let id = w.active.insert(e.slot)
        HitPlayerSprite.hit(w, player: pid, other: id)
        XCTAssertEqual(w.suspension, .conversation(id: 220, record: 283, sprite: id))
    }

    // MARK: - the sheets

    func testTeleporterSheetsSpawnable() throws {
        // `FaceTests.testEverySpawnableTypeHasSheet`'s rule for the six types: every face a sprite of theirs is drawn
        // from resolves to a sheet the level loads — the teleporters' boot singles (`BootFaces`, loaded at boot) and
        // the furniture's and NPCs' cache singles (registered, present, marked by their Setups) — and each picture is
        // in the data with a non-empty frame (`FerazelSession.frameRect`, the session's width reader).
        // Carry: this is a hand copy of the rule in Core. The real load rule is `FrameRenderer.spriteSheets` (the boot
        // list + the entries' sheets + `CachedFaces.sheets(markedBy:)` …) in the Render target, which Core cannot call;
        // `FaceTests` checks it there. The negative half (no other type marks these singles) is
        // `testFurnitureAndNpcFacesSetUp`'s disjointness loop.
        let r = try resources()
        for t in Self.teleporters + [Self.furniture] + Self.npcs {
            let sheet = try XCTUnwrap(SetupFaces.sheet(pict: t), "\(t)")
            XCTAssertEqual(sheet, .single(t), "\(t)")
            XCTAssertEqual([sheet.count, sheet.columns, Int(sheet.clut)], [1, 1, 200], "\(t)")
            let f = FerazelSession.frameRect(FaceRef(pict: t, index: 0, set: .encoded), resources: r)
            XCTAssertGreaterThan(f.right - f.left, 0, "\(t)")
            XCTAssertGreaterThan(f.bottom - f.top, 0, "\(t)")
            if Self.teleporters.contains(t) {
                XCTAssertTrue(BootFaces.sheets.contains(.single(t)), "\(t)")
            } else {
                let k = CachedFaces.RecordKey.single(Self.positions[t]! - 1)
                XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
                XCTAssertEqual(CachedFaces.sheets(markedBy: [t]).map(\.pict), [t], "\(t)")
            }
            // The class table spawns them idle in the Box class (`.GenerateSprite`).
            let k = SpriteClassTable.classify(type: t, p1Negative: false)
            XCTAssertEqual(k?.0, .box, "\(t)")
            XCTAssertEqual(k?.1, .idle, "\(t)")
            // The Handle runs for every one of them (no `// later:` arm). Weak: `handleBuilt` is false for six types only.
            XCTAssertTrue(BoxSprite.handleBuilt(t), "\(t)")
        }
        // Every record of the six types on all 24 levels (any flag, outside 10–22 too) sets up without a refusal, per
        // record through `SetupFaces.setup` — the later levels' carries (1060 on 31, 1061 on 40, 2921 on 30, 2956 on 70)
        // included, though no test pins their state.
        let six = Self.teleporters + [Self.furniture] + Self.npcs
        var all: [Int16: [Int16: Int]] = [:]
        for level: Int16 in [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22, 25, 30, 31, 40, 45, 50, 51, 52, 55, 62, 67, 70] {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in L.placements where six.contains(p.type) {
                all[level, default: [:]][p.type, default: 0] += 1
                XCTAssertNoThrow(try SetupFaces.setup(p, context: c), "L\(level) record \(p.index) type \(p.type)")
            }
        }
        // 45 records (World Data, every flag): level 11's flag-99 2956 (record 283) is the only one not active.
        XCTAssertEqual(all, [11: [2955: 1, 2956: 1], 21: [1061: 14, 2921: 2, 2962: 1], 22: [1060: 8, 2956: 1],
                             30: [2921: 3], 31: [1060: 4], 40: [1061: 9], 70: [2956: 1]])
        XCTAssertEqual(all.values.reduce(0) { $0 + $1.values.reduce(0, +) }, 45)
    }
}

import XCTest
@testable import FerazelCore

/// 6A-BG1c (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-BG1c`; docs/ferazel/later-levels-ledger.md
/// §8(a), §6): the plants of levels 15 and 18 — types 2700, 2701, 2702, 2705, 2711 (faces 0xa8c, 0xa8d, 0xa8e, 0xa91,
/// 0xa97). The Setup arm of `.SetupBackgroundSprite` (M l. 62629–62668) was already built (`case 0xa8c...0xaef`); this
/// task puts their faces into the Setup-face table and marks their picture-cache singles (registered by
/// `.InitBackgroundSprite` under flag 1, M l. 61908–61914: LL §6 singles #161, #162, #163, #166, #172). Records are read
/// per record through `SetupFaces.setup` — level 18 still holds the Chief, so no level is opened. A missing data file is
/// a FAILURE, never a skip.
final class PlantTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The five plant types this task builds (LL §8(a), 6A-BG1c).
    private static let plants: [Int16] = [2700, 2701, 2702, 2705, 2711]

    /// The plant types built before this task (levels 1–3): 2710, 2713, 2714 (0xa96, 0xa99, 0xa9a).
    private static let earlier: [Int16] = [2710, 2713, 2714]

    /// Their cache singles: LL §6's list positions (1-based) — 0xa8c + i at #161 + i.
    private static let positions: [Int16: Int] = [2700: 161, 2701: 162, 2702: 163, 2705: 166, 2711: 172]

    private func rec(_ type: Int16, p1: Int16 = 0, p2: Int16 = 0, p3: Int16 = 0) -> Placement {
        Placement(index: 7, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: 0, y: 900, x: 3000)
    }

    // MARK: - the Setups and their faces

    func testPlantFacesSetUp() throws {
        // The Setup-face table: each plant's own single, named under 202 (the level+base CLUT replaces it at Setup:
        // flag 1 — `SetupFaces.levelClutCache`, `.LoadCachedSpriteFaces` raw `1008901c..1008903c`).
        for t in Self.plants {
            XCTAssertEqual(SetupFaces.sheet(pict: t), SetupFaces.Sheet.single(t, clut: 202), "\(t)")
            XCTAssertTrue(SetupFaces.levelClutCache(t), "\(t)")
        }
        // Synthetic records on level 15's and level 18's world: every combination of the three parameters the arm
        // reads (p1 mirror, p2 tint, p3 front layer), the values level 15 and 18 place (p2 6 and 22) and others.
        let r = try resources()
        for level: Int16 in [15, 18] {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            let clut = ColorLUT.screenClutId(L.header)
            for t in Self.plants {
                for p1: Int16 in [0, 1, -1] {
                    for p2: Int16 in [0, 6, 22, -3] {
                        for p3: Int16 in [0, 1] {
                            let p = rec(t, p1: p1, p2: p2, p3: p3)
                            let what = "L\(level) type \(t) p1 \(p1) p2 \(p2) p3 \(p3)"
                            let e = try SetupFaces.setup(p, context: c)
                            let s = e.slot
                            // `+0xc0 = _DAT_100a0ad8[type − 0xa8c] + 4` (M l. 62636–62637): the cached single, faced at
                            // Setup, under the level's CLUT.
                            XCTAssertEqual(e.sheet, SetupFaces.Sheet.single(t, clut: clut), what)
                            XCTAssertEqual(e.source, .setupCached, what)
                            XCTAssertEqual(e.faceIndex, 0, what)
                            XCTAssertEqual(s.face, FaceRef(pict: t, index: 0, set: .encoded), what)
                            XCTAssertEqual(e.spriteClass, .background, what)
                            XCTAssertEqual(e.spawn, .idle, what)
                            XCTAssertEqual(e.record, p, "\(what): nothing written back")
                            XCTAssertNil(e.light, what)
                            XCTAssertTrue(e.children.isEmpty, what)
                            XCTAssertEqual(s.handler, .background, what)
                            XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false], what)
                            // M l. 62632: layer −100 (`+0x80 = 0xffffff9c`); p3 ≠ 0 → 10000 (M l. 62667–62669).
                            XCTAssertEqual(s.layer, p3 != 0 ? 10000 : -100, what)
                            // M l. 62633: `+0x88 = 1`, the light overlay.
                            XCTAssertTrue(s.lightOverlay, what)
                            // M l. 62659–62661: p1 ≠ 0 → `+0x17e = 1` (mirrored).
                            XCTAssertEqual(s.mirrored, p1 != 0, what)
                            // M l. 62663–62666: p2 ≠ 0 → `+0xb8 = p2 + 0x10000`.
                            XCTAssertEqual(s.mode, p2 != 0 ? UInt32(truncatingIfNeeded: Int(p2) + 0x10000) : 0, what)
                            // M l. 62634: the empty rect. With p1 ≠ 0 the dump's `.FlipHRect` (M l. 62661) makes it
                            // (top 0, left w, bottom 0, right w); the port keeps (0, 0, 0, 0) — the same recorded
                            // deviation as 6A-BX1a's decorations (still empty). This pins the port's value.
                            XCTAssertEqual(s.hotRect, Rect(top: 0, left: 0, bottom: 0, right: 0),
                                           p1 != 0 ? "\(what): port deviation (the dump's is (0, w, 0, w))" : what)
                        }
                    }
                }
            }
        }
    }

    // MARK: - the picture cache (`_DAT_100a0ad8`)

    func testPlantCacheMarksFlagOne() throws {
        // `.SetupBackgroundSprite` marks `_DAT_100a0ad8[type − 0xa8c]` (`rec + 1 = 1`, M l. 62635): the single of the
        // plant's own picture, registered by `.InitBackgroundSprite`'s loop under flag 1 (M l. 61908–61914).
        var plants = Set<CachedFaces.RecordKey>()
        for t in Self.plants {
            let k = CachedFaces.RecordKey.single(Self.positions[t]! - 1)
            plants.insert(k)
            XCTAssertEqual(Int(t - 0xa8c) + 161, Self.positions[t]!, "\(t): #161 + i")
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
            XCTAssertEqual(CachedFaces.markedRecords(type: t, p1: 1), [k], "\(t) p1 1")
            XCTAssertEqual(CachedFaces.markedRecords(type: t, p1: -1), [k], "\(t) p1 −1")
            XCTAssertEqual(CachedFaces.record(k).pict, t, "\(t)")
            XCTAssertEqual(CachedFaces.record(k).flag, 1, "\(t): flag 1")
            XCTAssertEqual(CachedFaces.record(k).faces, 1, "\(t)")
            XCTAssertTrue(CachedFaces.record(k).present, "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).singles, [t], "\(t)")
            XCTAssertEqual(CachedFaces.marks(type: t).sets, [], "\(t)")
        }
        // The earlier plants keep their own singles (#171, #174, #175), also flag 1.
        for t in Self.earlier {
            let k = CachedFaces.RecordKey.single(Int(t - 0xa8c) + 160)
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
            XCTAssertEqual(CachedFaces.record(k).flag, 1, "\(t)")
        }
        // No other type marks one of the five plant records.
        for t in Int16(0)...0x0d00 where !Self.plants.contains(t) {
            XCTAssertTrue(Set(CachedFaces.markedRecords(type: t)).isDisjoint(with: plants), "\(t)")
            XCTAssertTrue(Set(CachedFaces.markedRecords(type: t, p1: -1)).isDisjoint(with: plants), "\(t) p1 −1")
        }
        // Level by level, the singles the placed plants mark (every plant record sets up, per record), and a loaded
        // flag-1 single takes the level+base CLUT the Setup named.
        let r = try resources()
        let expected: [Int16: Set<Int16>] = [15: [2700, 2701, 2702, 2705, 2710, 2711, 2713, 2714],
                                             18: [2700, 2701, 2702]]
        for level: Int16 in [15, 18] {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            var marked = Set<CachedFaces.RecordKey>()
            for p in L.activePlacements where (0xa8c...0xaef).contains(p.type) {
                let e = try SetupFaces.setup(p, context: c)
                XCTAssertEqual(e.sheet?.clut, ColorLUT.screenClutId(L.header), "L\(level) record \(p.index)")
                marked.formUnion(CachedFaces.markedRecords(type: p.type, p1: p.p1))
            }
            XCTAssertEqual(CachedFaces.Needed(records: marked).singles, expected[level], "level \(level)")
            XCTAssertTrue(CachedFaces.Needed(records: marked).sets.isEmpty, "level \(level)")
            XCTAssertTrue(marked.allSatisfy { CachedFaces.record($0).flag == 1 }, "level \(level): flag 1")
        }
        // Loading the five: one face each (n 5, q 10), one step each, the five records loaded.
        var cache = CachedFaces()
        let bars = cache.load(needed: CachedFaces.Needed(records: plants))
        XCTAssertEqual(bars.map { [Int($0.0), Int($0.1)] }, [[6, 10], [7, 10], [8, 10], [9, 10], [10, 10]])
        XCTAssertEqual(cache.loadedRecords, plants)
        XCTAssertEqual(cache.loadedSingles, Set(Self.plants))
    }

    // MARK: - levels 15 and 18 (per record, no level opened)

    func testPlantsOnLevels15And18() throws {
        let r = try resources()
        var byLevel: [Int16: [Int16: Int]] = [:]
        var setUp: [Int16: Int] = [:]
        for level: Int16 in [15, 18] {
            let L = try LevelFile.load(from: r, level: level)
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in L.activePlacements where (0xa8c...0xaef).contains(p.type) {
                byLevel[level, default: [:]][p.type, default: 0] += 1
                let what = "L\(level) record \(p.index) type \(p.type)"
                let e: SetupFaces.Entry
                do { e = try SetupFaces.setup(p, context: c) } catch {
                    XCTFail("\(what): \(error)")
                    continue
                }
                setUp[level, default: 0] += 1
                XCTAssertEqual(e.slot.face, FaceRef(pict: p.type, index: 0, set: .encoded), what)
                XCTAssertEqual(e.source, .setupCached, what)
                XCTAssertEqual(e.slot.mirrored, p.p1 != 0, what)
                XCTAssertEqual(e.slot.layer, p.p3 != 0 ? 10000 : -100, what)
                XCTAssertEqual(e.slot.mode, p.p2 != 0 ? UInt32(truncatingIfNeeded: Int(p.p2) + 0x10000) : 0, what)
            }
        }
        // Measured from World Data (Mlvl 15 and 18): the five types' records — 22 on 15 and 5 on 18 (LL §4) — beside
        // level 15's eight earlier plants (2710 ×1, 2713 ×2, 2714 ×5).
        XCTAssertEqual(byLevel[15], [2700: 4, 2701: 8, 2702: 6, 2705: 3, 2711: 1, 2710: 1, 2713: 2, 2714: 5])
        XCTAssertEqual(byLevel[18], [2700: 2, 2701: 1, 2702: 2])
        XCTAssertEqual(Self.plants.map { byLevel[15]?[$0] ?? 0 }.reduce(0, +), 22)
        XCTAssertEqual(Self.plants.map { byLevel[18]?[$0] ?? 0 }.reduce(0, +), 5)
        // Every plant record sets up: 30 on 15, 5 on 18.
        XCTAssertEqual(setUp, [15: 30, 18: 5])
        // The tints level 15 places (p2): 6 and 22 only; level 18's plants have none.
        let L15 = try LevelFile.load(from: r, level: 15), L18 = try LevelFile.load(from: r, level: 18)
        XCTAssertEqual(Set(L15.activePlacements.filter { (0xa8c...0xaef).contains($0.type) && $0.p2 != 0 }.map(\.p2)),
                       [6, 22])
        XCTAssertTrue(L18.activePlacements.filter { (0xa8c...0xaef).contains($0.type) }.allSatisfy { $0.p2 == 0 })
    }
}

@testable import FerazelCore
import Foundation
import HectorResources
import XCTest

/// 6A-CF (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-CF`): the level-load picture cache in full —
/// `.InitSprites`' whole registration list (M l. 103–145; `.CacheEncFaceSetFromPICT` / `.Cache1EncFaceFromPICT` M l.
/// 73870–73956), 285 records keyed by record (list position), transcribed from the later-levels ledger §6
/// (`docs/ferazel/later-levels-ledger.md`, the `LL:cache` table), with the marks of built types the port missed (LL §1
/// finding 8) and picture 0x46a's three records (ENG §2.14). Against the committed `Resources/Ferazel` (D26); a missing
/// data file is a FAILURE, never a skip. Plain Swift only (Proof B: no Foundation string search or trim, no regular
/// expressions).
final class CachedFacesTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// One row of LL §6's table, as the ledger prints it.
    private struct LedgerRow {
        let set: Bool
        let number: Int
        let pict: Int16
        let faces: Int
        let cellWidth: Int
        let cellHeight: Int
        let columns: Int
        let flag: Int16
        let present: Bool
    }

    /// The decimal digit runs of `s`, in order.
    private static func digitRuns(_ s: Substring) -> [Int] {
        var runs: [Int] = []
        var cur: Int?
        for ch in s {
            if let a = ch.asciiValue, a >= 48, a <= 57 {
                cur = (cur ?? 0) * 10 + Int(a - 48)
            } else if let c = cur {
                runs.append(c)
                cur = nil
            }
        }
        if let c = cur { runs.append(c) }
        return runs
    }

    /// LL §6's rows between `<!-- LL:cache -->` and `<!-- /LL:cache -->`.
    private func ledgerRows() throws -> [LedgerRow] {
        let url = URL(fileURLWithPath: #filePath).resolvingSymlinksInPath().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("docs/ferazel/later-levels-ledger.md")
        let text = try String(contentsOf: url, encoding: .utf8)
        var rows: [LedgerRow] = []
        var inside = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line == "<!-- LL:cache -->" { inside = true; continue }
            if line == "<!-- /LL:cache -->" { break }
            guard inside else { continue }
            let cells = line.split(separator: "|", omittingEmptySubsequences: false).map {
                String($0.filter { $0 != " " && $0 != "*" })
            }
            guard cells.count > 7, cells[2] == "set" || cells[2] == "single" else { continue }
            let set = cells[2] == "set"
            let number = Self.digitRuns(Substring(cells[1])), pict = Self.digitRuns(Substring(cells[3]))
            let faces = Self.digitRuns(Substring(cells[4])), flag = Self.digitRuns(Substring(cells[5]))
            // A mangled row fails here instead of trapping the test process.
            guard number.count >= 1, pict.count >= 1, flag.count >= 1, faces.count >= (set ? 4 : 1) else {
                XCTFail("LL §6 row unreadable: \(line)")
                continue
            }
            rows.append(LedgerRow(set: set, number: number[0], pict: Int16(pict[0]), faces: faces[0],
                                  cellWidth: set ? faces[1] : 0, cellHeight: set ? faces[2] : 0,
                                  columns: set ? faces[3] : 1, flag: Int16(flag[0]), present: cells[6] == "yes"))
        }
        return rows
    }

    func testCacheRegistrationListInFull() throws {
        // 285 records — 92 sets, 193 singles — 805 faces.
        XCTAssertEqual(CachedFaces.sets.count, 92)
        XCTAssertEqual(CachedFaces.singles.count, 193)
        XCTAssertEqual(CachedFaces.sets.count + CachedFaces.singles.count, 285)
        XCTAssertEqual(CachedFaces.sets.reduce(0) { $0 + $1.faces } + CachedFaces.singles.reduce(0) { $0 + $1.faces },
                       805)
        // Every row in LL §6's order, with its geometry, its CLUT flag and whether the data holds its PICT.
        let rows = try ledgerRows()
        XCTAssertEqual(rows.count, 285)
        let sets = rows.filter(\.set), singles = rows.filter { !$0.set }
        XCTAssertEqual(sets.map(\.number), Array(1...92))
        XCTAssertEqual(singles.map(\.number), Array(1...193))
        for (row, r) in zip(sets, CachedFaces.sets) {
            XCTAssertEqual([Int(r.pict), r.faces, r.cellWidth, r.cellHeight, r.columns, Int(r.flag)],
                           [Int(row.pict), row.faces, row.cellWidth, row.cellHeight, row.columns, Int(row.flag)],
                           "set #\(row.number)")
            XCTAssertEqual(r.present, row.present, "set #\(row.number)")
        }
        for (row, r) in zip(singles, CachedFaces.singles) {
            XCTAssertEqual([Int(r.pict), r.faces, Int(r.flag)], [Int(row.pict), 1, Int(row.flag)], "single #\(row.number)")
            XCTAssertEqual(r.present, row.present, "single #\(row.number)")
        }
        // The 23 absent PICTs (2805–2807, 2950, 2966–2969, 1489, 2718–2729, 1790, 1791): the data holds no file for
        // them — and every other record's PICT is there (the sprite chain the cache loads from).
        let r = try resources()
        let all = CachedFaces.sets + CachedFaces.singles
        XCTAssertEqual(all.filter { !$0.present }.map(\.pict).sorted(),
                       [1489, 1790, 1791] + Array(2718...2729) + [2805, 2806, 2807, 2950] + Array(2966...2969))
        for rec in all {
            XCTAssertEqual(r.resource(type: "PICT", id: rec.pict, chain: .frontEnd) != nil, rec.present, "\(rec.pict)")
        }
        // `.CountNeededCachedSpriteFaces` has no presence test (M l. 73749–73764): a marked absent record counts its
        // faces in n (q = 2n), makes no step and is never marked loaded (M l. 73822–73832, 73852–73859) — and counts
        // again at the next load. The absent set 0x6fe (#86, 8 faces) and single 2805 (#10) beside the present 0x6a4.
        var cache = CachedFaces()
        let absentSet = CachedFaces.RecordKey.set(85), absentSingle = CachedFaces.RecordKey.single(9)
        XCTAssertEqual([CachedFaces.record(absentSet).pict, CachedFaces.record(absentSingle).pict], [0x6fe, 2805])
        let need = CachedFaces.Needed(records: [absentSet, absentSingle, .single(0)])
        let bars = cache.load(needed: need)
        XCTAssertEqual(bars.map { [Int($0.0), Int($0.1)] }, [[11, 20]], "n = 8 + 1 + 1, one step (0x6a4)")
        XCTAssertEqual(cache.loadedRecords, [.single(0)])
        XCTAssertEqual(cache.load(needed: need).map { [Int($0.0), Int($0.1)] }, [], "n 9 again, q 18, no step")
        XCTAssertEqual(cache.loadedRecords, [.single(0)])
        XCTAssertEqual(cache.load(needed: CachedFaces.Needed(records: need.records.union([.single(1)])))
                           .map { [Int($0.0), Int($0.1)] }, [[11, 20]],
                       "the absent records counted again: n = 8 + 1 + 1")
        // No placed type on the world's 24 levels marks an absent record (a data pin: unreachable as shipped).
        let levels = r.world.resources(of: "Mlvl")
        XCTAssertEqual(levels.count, 24)
        for res in levels {
            let L = try LevelFile(resource: res)
            for p in L.placements where p.type != 0 {
                for k in CachedFaces.markedRecords(type: p.type, p1: p.p1) {
                    XCTAssertTrue(CachedFaces.record(k).present, "level \(res.id) type \(p.type) marks \(k)")
                }
            }
        }
    }

    /// The records `SetupFaces.setup` sets up on `level` (spawn order) and their record-keyed marks — read from the
    /// level file per record; no level opened.
    private func levelMarks(_ level: Int16) throws -> (setUp: [Placement], records: Set<CachedFaces.RecordKey>,
                                                         L: LevelFile) {
        let L = try LevelFile.load(from: try resources(), level: level)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
        return (setUp, Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) }), L)
    }

    /// The load bar on a fresh cache: (needed records, n, q, steps).
    private func bar(_ records: Set<CachedFaces.RecordKey>, _ L: LevelFile) -> [Int] {
        var cache = CachedFaces()
        cache.enterLevel(screenClut: L.header.screenClut)
        let bars = cache.load(needed: CachedFaces.Needed(records: records))
        let q = Int(bars.first?.1 ?? 0)
        return [records.count, q / 2, q, bars.count]
    }

    func testLevel20LoadBarMarks() throws {
        let m = try levelMarks(20)
        let types = Set(m.setUp.map(\.type))
        // The hang glider 3050 marks the four Player sets #1–#4 (`.SetupBonusSprite` M l. 52616–52625, LL §6 marks
        // 52622–52625).
        XCTAssertTrue(types.contains(3050))
        XCTAssertEqual(CachedFaces.markedRecords(type: 3050), [.set(0), .set(1), .set(2), .set(3)])
        XCTAssertEqual(CachedFaces.sets[0...3].map(\.pict), [0x41a, 0x41b, 0x41c, 0x41d])
        // The PICT-valued sheets of its marks come through the record cut (`sheet(record:)`), clut 200.
        XCTAssertEqual(CachedFaces.sheets(markedBy: [Int16(3050)])
                           .map { [Int($0.pict), $0.count, $0.columns, Int($0.clut)] },
                       [[0x41a, 6, 3, 200], [0x41b, 4, 4, 200], [0x41c, 6, 3, 200], [0x41d, 4, 4, 200]])
        // The cannons 1092 / 1094 / 1096 mark set 0x442 (#29; M l. 62058–62061, LL §6 mark 62061).
        for t: Int16 in [1092, 1094, 1096] {
            XCTAssertTrue(types.contains(t), "\(t)")
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [.set(28)], "\(t)")
        }
        XCTAssertEqual(CachedFaces.record(.set(28)).pict, 0x442)
        XCTAssertTrue(m.records.isSuperset(of: [.set(0), .set(1), .set(2), .set(3), .set(28)]))
        // Measured at CF's point (6A-CF): needed records, n, q, steps — the four Player sets (20 faces), 0x442 (5), the
        // Gremlin's three (24), the tunnel single 3002 and the mace single 1480. Every later task that adds a mark on
        // level 20 or makes one of its records set up re-derives these (RC, CL, BD, MP).
        XCTAssertEqual(bar(m.records, m.L), [10, 51, 102, 10])
    }

    func testLevel22LoadBarMarks() throws {
        let m = try levelMarks(22)
        let types = Set(m.setUp.map(\.type))
        // The cannons 1091 / 1094 / 1096 mark set 0x442 (#29).
        for t: Int16 in [1091, 1094, 1096] {
            XCTAssertTrue(types.contains(t), "\(t)")
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [.set(28)], "\(t)")
        }
        // Each mace / ball 0x5c8…0x5d1 marks its own single (`PTR_DAT_100a09f4[type·0x10 − 0x5c7f] = 1`, M l.
        // 62312–62321; singles #151…#160).
        let maces = types.filter { (0x5c8...0x5d1).contains($0) }.sorted()
        XCTAssertEqual(maces, [1480, 1485])
        for t in maces {
            let k = CachedFaces.RecordKey.single(150 + Int(t - 0x5c8))
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [k], "\(t)")
            XCTAssertEqual(CachedFaces.record(k).pict, t)
            XCTAssertTrue(m.records.contains(k), "\(t)")
        }
        XCTAssertTrue(m.records.contains(.set(28)))
        // Measured at CF's point (6A-CF): needed records, n, q, steps (24 sets, 9 singles). Every later task that adds
        // a mark on level 22 or makes one of its records set up re-derives these (BX1b, BD, MP, CP).
        XCTAssertEqual(bar(m.records, m.L), [33, 168, 336, 33])
    }

    func testShot46bReadsRecord0844() throws {
        // `.InitEnemyShotSprite` registers 0x46a three times (M l. 51434–51436): `_DAT_100a0848` 6 × 48×48 (#40),
        // `0844` and `0840` 6 × 64×64 (#41, #42). The Handle's arms read 0x46a ← `0848` (M l. 51822–51845), 0x46b ←
        // `0844` (51846–51853), 0x46c ← `0840` (51854–51861).
        XCTAssertEqual([CachedFaces.fireball0848, CachedFaces.fireball0844, CachedFaces.fireball0840],
                       [.set(39), .set(40), .set(41)])
        XCTAssertEqual([39, 40, 41].map { CachedFaces.sets[$0].cellWidth }, [0x30, 0x40, 0x40])
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1))
        func faceAfterArm(_ type: Int16) throws -> FaceRef {
            let id = try XCTUnwrap(EnemyShot.spawn(w, type: type, x: 300, y: 100, layer: 0))
            w.active.update(id: id) { $0.phase = 2 }
            var lights = LightTable()
            var flame = false
            EnemyShot.typeArm(w, id: id, lights: &lights, effects: 1, faceBounds: { _ in .noFace }, flame: &flame)
            return try XCTUnwrap(w.active.record(id: id)?.face)
        }
        let b = try XCTUnwrap(CachedFaces.recordCell(of: try faceAfterArm(0x46b)))
        XCTAssertEqual(b.record, CachedFaces.fireball0844)
        XCTAssertEqual(b.cell, 3)
        // ENG §2.14's first assert: 0x46c reads `0840`, not `0844`.
        let c = try XCTUnwrap(CachedFaces.recordCell(of: try faceAfterArm(0x46c)))
        XCTAssertEqual(c.record, CachedFaces.fireball0840)
        XCTAssertNotEqual(c.record, CachedFaces.fireball0844)
        XCTAssertEqual(c.cell, 3)
        let a = try XCTUnwrap(CachedFaces.recordCell(of: try faceAfterArm(0x46a)))
        XCTAssertEqual([a.record], [CachedFaces.fireball0848])
        XCTAssertEqual(a.cell, 3)
    }

    func testCacheMarksPerRecord() throws {
        // Only picture 0x46a is registered more than once (#40–#42); every other PICT names one record of its list.
        var byPict: [Int16: [Int]] = [:]
        for (i, r) in CachedFaces.sets.enumerated() { byPict[r.pict, default: []].append(i) }
        XCTAssertEqual(byPict.filter { $0.value.count > 1 }.mapValues { $0 }, [0x46a: [39, 40, 41]])
        XCTAssertEqual(Set(CachedFaces.singles.map(\.pict)).count, 193)
        // A Setup that marks record #k marks no other record of the same PICT: no type's marks repeat a record, and
        // the PICT-valued view is exactly the record-keyed marks' PICTs (sets, then singles, in mark order).
        for t in Int16(0)...0x0d00 {
            for p1: Int16 in [0, -1] {
                let ks = CachedFaces.markedRecords(type: t, p1: p1)
                XCTAssertEqual(Set(ks).count, ks.count, "type \(t)")
                let m = CachedFaces.marks(type: t, p1: p1)
                XCTAssertEqual(m.sets, ks.compactMap { if case .set = $0 { return CachedFaces.record($0).pict }; return nil })
                XCTAssertEqual(m.singles,
                               ks.compactMap { if case .single = $0 { return CachedFaces.record($0).pict }; return nil })
            }
        }
        // Keyed by record: marking 0x46a's record `0844` loads that record alone — 6 faces, one step — not its
        // neighbours of the same picture.
        var cache = CachedFaces()
        let bars = cache.load(needed: CachedFaces.Needed(records: [CachedFaces.fireball0844]))
        XCTAssertEqual(bars.map { [Int($0.0), Int($0.1)] }, [[12, 12]])
        XCTAssertEqual(cache.loadedRecords, [CachedFaces.fireball0844])
        XCTAssertEqual(cache.loadedSets, [0x46a])
        // Then `0848` too: only it is new (n 6), and `0844` stays loaded.
        let more = cache.load(needed: CachedFaces.Needed(records: [CachedFaces.fireball0844, CachedFaces.fireball0848]))
        XCTAssertEqual(more.map { [Int($0.0), Int($0.1)] }, [[12, 12]])
        XCTAssertEqual(cache.loadedRecords, [CachedFaces.fireball0844, CachedFaces.fireball0848])
        // Then `0848` alone: `0844` is disposed by record, `0848` stays.
        XCTAssertEqual(cache.load(needed: CachedFaces.Needed(records: [CachedFaces.fireball0848])).count, 0)
        XCTAssertEqual(cache.loadedRecords, [CachedFaces.fireball0848])
        // CF's marks of built types (LL §1 finding 8), every type of each arm: the cannons 0x442…0x44a (M l.
        // 62057–62061), the springs 0x47e…0x481 (62046–62047, 62186–62210), the maces 0x5c8…0x5d1 (62312–62321),
        // the passage 0xb55 (62585–62587).
        for t in Int16(0x442)...0x44a { XCTAssertEqual(CachedFaces.markedRecords(type: t), [.set(28)], "\(t)") }
        XCTAssertEqual([Int16(0x47e), 0x47f, 0x480, 0x481].map { CachedFaces.marks(type: $0).sets },
                       [[0x47e], [0x47f], [0x480], [0x480]])
        for t in Int16(0x5c8)...0x5d1 {
            XCTAssertEqual(CachedFaces.markedRecords(type: t), [.single(150 + Int(t - 0x5c8))], "\(t)")
        }
        XCTAssertEqual(CachedFaces.marks(type: 0xb55).singles, [0xb55])
        // No built type marks a record of a shared PICT yet — the first boss task that marks a 0x46a record (6B-WZ /
        // the Demon / Xichra) re-derives this. The record cut is nil for a flag-1 record (#58) and an absent one (#86).
        XCTAssertTrue(CachedFaces.recordSheets(markedBy: Int16(0)...0x0d00).isEmpty)
        XCTAssertNil(CachedFaces.sheet(record: .set(57)))
        XCTAssertNil(CachedFaces.sheet(record: .set(85)))
        // A PICT-valued `Needed` marks every record of the PICT: 0x46a's three — 18 faces, three steps.
        var fresh = CachedFaces()
        XCTAssertEqual(CachedFaces.Needed(sets: [0x46a]).records,
                       [CachedFaces.fireball0848, CachedFaces.fireball0844, CachedFaces.fireball0840])
        XCTAssertEqual(fresh.load(needed: CachedFaces.Needed(sets: [0x46a])).map { Int($0.0) }, [24, 30, 36])
        // Each record's own face: cell c of record #k is (the PICT, the cells of the PICT's earlier records + c).
        XCTAssertEqual(CachedFaces.face(record: CachedFaces.fireball0848, cell: 5), FaceRef(pict: 0x46a, index: 5, set: .encoded))
        XCTAssertEqual(CachedFaces.face(record: CachedFaces.fireball0844, cell: 0), FaceRef(pict: 0x46a, index: 6, set: .encoded))
        XCTAssertEqual(CachedFaces.face(record: CachedFaces.fireball0840, cell: 5), FaceRef(pict: 0x46a, index: 17, set: .encoded))
        XCTAssertNil(CachedFaces.recordCell(of: FaceRef(pict: 0x46a, index: 18, set: .encoded)))
        // A single-record PICT keeps its plain face refs.
        XCTAssertEqual(CachedFaces.face(record: .set(28), cell: 3), FaceRef(pict: 0x442, index: 3, set: .encoded))
    }
}

import XCTest
@testable import CytheraCore

/// C4 (docs/plans/2026-10-06-cythera-phase0.md): the 20 world globals 0xF000–0xF016 (data-format §5, §3.4,
/// §6.1, §6.3; open-items-2026-10-06 §5; combat.md §4). Numbers: p03 (sizes), p11 (contents). The 0xF001
/// shape (8 records, terminator at 64, nothing after it) is the orchestrator's 2026-10-07 ruling.
final class WorldGlobalsTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    static let sizes: [(UInt16, Int)] = [
        (0xF000, 2048), (0xF001, 66), (0xF002, 32768), (0xF004, 5786), (0xF005, 16), (0xF007, 167),
        (0xF008, 2048), (0xF009, 16384), (0xF00A, 1024), (0xF00B, 5448), (0xF00C, 4096), (0xF00D, 500),
        (0xF00F, 1024), (0xF010, 16384), (0xF011, 32768), (0xF012, 32768), (0xF013, 131072), (0xF014, 123),
        (0xF015, 179), (0xF016, 8192),
    ]

    /// The 20 shipped globals in a mutable store, for hostile copies.
    private func globalsStore(_ file: SegmentFile) -> MemorySegmentStore {
        MemorySegmentStore(Dictionary(uniqueKeysWithValues: WorldGlobals.ids.map { ($0, file.segment($0)!) }))
    }

    func testGlobalsPresentAndSizes() throws {
        let file = try segmentFile()
        let ids = file.ids.filter { $0 >> 8 == 0xF0 }
        XCTAssertEqual(ids, Self.sizes.map(\.0))
        XCTAssertEqual(WorldGlobals.ids, Self.sizes.map(\.0))
        for (id, size) in Self.sizes { XCTAssertEqual(file.entry(id)?.length, size, String(id, radix: 16)) }
        XCTAssertNoThrow(try WorldGlobals(file: file))

        // Hostile copies (Invariants 4, 5): each global one byte short throws a named error. 0xF004 keeps
        // 6 unread bytes after its terminator, so it is cut inside the terminator instead.
        for id in WorldGlobals.ids {
            let store = globalsStore(file)
            let full = file.segment(id)!
            store.write(id, data: id == 0xF004 ? full.prefix(5779) : full.prefix(full.count - 1))
            XCTAssertThrowsError(try WorldGlobals(store: store), String(id, radix: 16)) { e in
                XCTAssertTrue(e is WorldGlobalsError, "\(String(id, radix: 16)): \(e)")
            }
        }
        // A missing global; 0xF001 with bytes after its terminator; 0xF001 with no terminator.
        let missing = globalsStore(file); missing.write(0xF00C, data: Data())
        XCTAssertThrowsError(try WorldGlobals(store: missing)) { e in
            XCTAssertEqual(e as? WorldGlobalsError, .missing(0xF00C))
        }
        let trailing = globalsStore(file); trailing.write(0xF001, data: file.segment(0xF001)! + Data([0, 0]))
        XCTAssertThrowsError(try WorldGlobals(store: trailing)) { e in
            XCTAssertEqual(e as? WorldGlobalsError, .trailingBytes(id: 0xF001, after: 66, count: 2))
        }
        let unterminated = globalsStore(file); unterminated.write(0xF001, data: file.segment(0xF001)!.prefix(64))
        XCTAssertThrowsError(try WorldGlobals(store: unterminated)) { e in
            XCTAssertEqual(e as? WorldGlobalsError, .missingTerminator(0xF001))
        }
        // A schedule table whose counts do not fill the segment exactly.
        let sched = globalsStore(file); sched.write(0xF00B, data: file.segment(0xF00B)! + Data(count: 8))
        XCTAssertThrowsError(try WorldGlobals(store: sched)) { e in
            XCTAssertEqual(e as? WorldGlobalsError, .lengthMismatch(id: 0xF00B, expected: 5448, actual: 5456))
        }
    }

    func testBaseTilesAndAnimations() throws {
        let g = try WorldGlobals(file: try segmentFile())
        XCTAssertEqual(g.baseTiles.count, 1024)
        XCTAssertEqual(g.baseTiles.filter { $0 != 0 }.count, 395)
        XCTAssertEqual(g.baseTiles.max(), 4863)
        XCTAssertEqual(g.animations.count, 8)
        XCTAssertEqual(g.animationTerminatorOffset, 64)
        XCTAssertEqual(g.animationTerminatorOffset + 2, 66)       // nothing follows the terminator
        let expected: [(Int16, Int16, Int16, Int16)] = [
            (987, 987, 4, 2), (2161, 2161, 4, 1), (1275, 1274, 2, 4), (1180, 1180, 4, 1),
            (1176, 1176, 4, 1), (1172, 1172, 4, 1), (1168, 1168, 4, 1), (902, 902, 4, 1),
        ]
        for (a, e) in zip(g.animations, expected) {
            XCTAssertEqual(a.tile, e.0); XCTAssertEqual(a.base, e.1)
            XCTAssertEqual(a.frameCount, e.2); XCTAssertEqual(a.divisor, e.3)
        }
        // `LoadGlobals`: ptr[f][tile] = base + ((f / divisor) mod nframes) — tile 0x3DB: 3DB 3DB 3DC 3DC 3DD …
        XCTAssertEqual((0..<8).map { g.animations[0].tile(forFrame: $0) }, [987, 987, 988, 988, 989, 989, 990, 990])
        XCTAssertEqual((0..<8).map { g.animations[2].tile(forFrame: $0) }, [1274, 1274, 1274, 1274, 1275, 1275, 1275, 1275])
    }

    func testTileFlagsAndLightBits() throws {
        let g = try WorldGlobals(file: try segmentFile())
        XCTAssertEqual(g.tileFlags.count, 8192)
        XCTAssertEqual(g.tileFlags.filter { $0 != 0 }.count, 2125)
        var light: [UInt32: Int] = [:]
        for f in g.tileFlags where f & 3 != 0 { light[f & 3, default: 0] += 1 }
        XCTAssertEqual(light, [1: 42, 2: 5, 3: 12])
        XCTAssertEqual(g.tileFlags.filter { $0 & 0x10000 != 0 }.count, 45)
    }

    func testTileNames() throws {
        let g = try WorldGlobals(file: try segmentFile())
        let t = g.tileNames
        XCTAssertEqual(t.entries.count, 547)
        XCTAssertEqual(t.entries.last?.lastTile, 5247)
        XCTAssertEqual(t.entries.last?.name, "earthen wall")
        XCTAssertEqual(t.terminator, 0x7FFF)
        XCTAssertEqual(t.terminatorOffset, 5778)
        XCTAssertEqual(t.trailing.count, 6)
        // §4.5 join: tile f000[39] + 3 = 1123 is "portcullis"; a tile takes the next higher entry's name.
        XCTAssertEqual(Int(g.baseTiles[39]) + 3, 1123)
        XCTAssertEqual(t.name(forTile: 1123), "portcullis")
        XCTAssertNil(t.name(forTile: 5248))
    }

    func testCreaturesAndCharacters() throws {
        let g = try WorldGlobals(file: try segmentFile())
        XCTAssertEqual(g.creatures.count, 128)
        XCTAssertEqual(g.creatures.firstIndex { $0.objectType == 0 }, 50)
        let used = g.creatures.filter { $0.objectType != 0 }
        XCTAssertEqual(used.count, 50)
        XCTAssertTrue(used.allSatisfy { $0.byte7 == 0 })
        XCTAssertEqual(g.creatureTail.count, 0)
        XCTAssertEqual(g.creatures[0].objectType, 32); XCTAssertEqual(g.creatures[0].corpse, 0x111B)  // combat.md §4

        XCTAssertEqual(g.characters.count, 512)
        XCTAssertTrue(g.characters[256...].allSatisfy(\.isEmpty))
        let live = g.characters.filter { !$0.isEmpty }
        XCTAssertEqual(live.count, 131)
        XCTAssertEqual(live.filter(\.isAlive).count, 128)
        XCTAssertEqual(live.filter(\.isPartyMember).count, 1)
        var align: [UInt8: Int] = [:], behaviour: [UInt8: Int] = [:]
        for c in live { align[c.alignment, default: 0] += 1; behaviour[c.behaviour, default: 0] += 1 }
        XCTAssertEqual(align, [0: 128, 1: 2, 2: 1])
        XCTAssertEqual(behaviour, [0: 11, 2: 1, 3: 7, 4: 7, 5: 1, 6: 5, 7: 8, 8: 91])
        XCTAssertTrue(live.allSatisfy {
            $0.busyTicks == 0 && $0.subStep == 0 && $0.conditionFlagsHigh == 0 && $0.food == 0
                && $0.training == 0 && $0.spawnScale == 0
        })
        let c2 = g.characters[2]
        XCTAssertEqual(c2.bytes.map { String(format: "%02x", $0) }.joined(),
                       "03013015242200010014141425809090242400082422960000000000000f0600")
        XCTAssertEqual(c2.location, WorldLocation(level: 3, x: 19, y: 21))
        XCTAssertEqual(c2.typeFrame, 0x2422); XCTAssertEqual(c2.type, 34)
        XCTAssertEqual(c2.status, 1); XCTAssertEqual(c2.flags, 0)
        XCTAssertEqual([c2.body, c2.reflex, c2.mind], [20, 20, 20])
        XCTAssertEqual(c2.experience, 9600)
        XCTAssertEqual([c2.health, c2.healthMax, c2.magic, c2.magicMax], [144, 144, 36, 36])
        XCTAssertEqual(c2.level, 8); XCTAssertEqual(c2.home, 0x2422); XCTAssertEqual(c2.activity, 0x96)
        XCTAssertEqual(c2.markup, 0); XCTAssertEqual(c2.characterClass, 0x0F); XCTAssertEqual(c2.behaviour, 6)
    }

    func testSchedules() throws {
        let g = try WorldGlobals(file: try segmentFile())
        let s = g.schedules
        XCTAssertEqual(s.counts.count, 256)
        let total = s.entries.reduce(0) { $0 + $1.count }
        XCTAssertEqual(total, 617)
        XCTAssertEqual(0x200 + 8 * total, 5448)
        XCTAssertEqual(s.entries.filter { !$0.isEmpty }.count, 114)
        XCTAssertEqual(s.entries[0].count, 1)
        XCTAssertEqual(s.entries[0][0].hour, 9)
        XCTAssertEqual(s.entries[0][0].location, WorldLocation(level: 1, x: 0, y: 0))
        let e = s.entries[2][0]
        XCTAssertEqual(e.hour, 0); XCTAssertEqual(e.activity, 0x96)
        XCTAssertEqual(e.conditionOp, 3); XCTAssertEqual(e.conditionArg, 0)
        XCTAssertEqual(e.location, WorldLocation(level: 3, x: 19, y: 21))
        var ops: [UInt8: Int] = [:]
        for list in s.entries { for x in list { ops[x.conditionOp, default: 0] += 1 } }
        let top = ops.sorted { $0.value > $1.value }.prefix(4).map { [Int($0.key), $0.value] }
        XCTAssertEqual(top, [[0, 539], [1, 28], [131, 11], [132, 8]])
    }

    func testTeleportsAndSmallGlobals() throws {
        let file = try segmentFile()
        let g = try WorldGlobals(file: file)
        XCTAssertEqual(g.teleports.count, 1024)
        let used = g.teleports.filter { $0 != 0 }.map(WorldLocation.init(packed:))
        XCTAssertEqual(used.count, 190)
        XCTAssertEqual(used.map(\.level).min(), 1); XCTAssertEqual(used.map(\.level).max(), 41)
        XCTAssertEqual(WorldLocation(packed: g.teleports[5]), WorldLocation(level: 1, x: 199, y: 58))

        XCTAssertEqual(g.wallSubstitutions.count, 50)
        XCTAssertEqual(g.wallSubstitutions.prefix(3).map(\.tile), [144, 145, 146])

        XCTAssertEqual(g.arrivalTransitions.count, 1024)
        var arrival: [UInt8: Int] = [:]
        for b in g.arrivalTransitions { arrival[b, default: 0] += 1 }
        XCTAssertEqual(arrival, [0: 981, 14: 30, 2: 6, 13: 3, 1: 2, 3: 1, 4: 1])

        XCTAssertEqual(g.tilePseudoProps.count, 8192)
        XCTAssertEqual(g.tilePseudoProps.filter { $0 != 0 }.count, 114)
        for offsets in [g.spriteOffsetsX, g.spriteOffsetsY] {
            XCTAssertEqual(offsets.count, 16384)
            XCTAssertEqual(offsets.filter { $0 != 0 }.count, 39)
            XCTAssertEqual(offsets.max(), 5140)
        }
        XCTAssertEqual(g.compoTiles.count, 4096)
        XCTAssertEqual(g.compoTiles.filter { !$0.isEmpty }.count, 264)

        XCTAssertEqual(g.filterIDs.count, 8192)
        var filters: [UInt8: Int] = [:]
        for b in g.filterIDs where b != 0 { filters[b, default: 0] += 1 }
        XCTAssertEqual(filters.values.reduce(0, +), 124)
        XCTAssertEqual(filters, [128: 72, 131: 30, 134: 12, 129: 4, 130: 3, 133: 3])

        XCTAssertEqual(g.frameVariableNames.entries.count, 10)
        XCTAssertEqual(g.frameVariableNames.byteCount, 123)
        XCTAssertEqual(g.frameVariableNames.entries.first?.value, 259)
        XCTAssertEqual(g.frameVariableNames.entries.first?.name, "Od_Shutter1")
        XCTAssertEqual(g.objectNames.entries.count, 13)
        XCTAssertEqual(g.objectNames.byteCount, 179)
        XCTAssertEqual(g.objectNames.entries.first?.name, "Cad_Bellows1")

        XCTAssertEqual(g.f00A.count, 1024)
        XCTAssertTrue(g.f00A.allSatisfy { $0 == 0 })

        XCTAssertEqual(g.paletteCycles.map { [Int($0.first), Int($0.count), Int($0.byte2)] },
                       [[0xD0, 8, 1], [0xD8, 8, 1], [0xE0, 4, 1], [0xE4, 4, 1], [0xE8, 4, 1]])
        XCTAssertEqual(file.segment(0xF005)!.last, 0)

        XCTAssertEqual(g.f007.count, 167)
        let f007 = [UInt8](g.f007)
        XCTAssertEqual(Int(f007[0]) << 8 | Int(f007[1]), 33)
        XCTAssertEqual(2 + 33 * 5, 167)
    }
}

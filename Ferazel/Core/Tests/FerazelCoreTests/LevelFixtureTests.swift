import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-FX (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-FX`, "Verification-model additions for 6A";
/// docs/ferazel/phase6-engine-contracts.md §7.2; DECISIONS D46.3): the level fixture (`LevelFixture.swift`, linked into
/// both test targets), proven headless on level 21 — LL §4 "Level 21": no strip and no OmniPx mode in its header, and it
/// opens once its 30 refused records are left out. A missing data file is a FAILURE, never a skip.
final class LevelFixtureTests: XCTestCase {

    /// The six data files the fixture reads (`FerazelData.open`), as they are on disk now.
    private func dataOnDisk() throws -> [String: Data] {
        let dir = try FerazelData.dataDirectory()
        var files: [String: Data] = [:]
        for name in [FerazelData.appFile, FerazelData.worldFile, FerazelData.backgroundsFile, FerazelData.spritesFile,
                     FerazelData.soundsFile, FerazelData.titlesFile] {
            files[name] = try Data(contentsOf: dir.appendingPathComponent(name))
        }
        return files
    }

    /// The byte offsets where `a` and `b` (equal lengths) differ.
    private func diff(_ a: Data, _ b: Data) -> [Int] {
        let x = [UInt8](a), y = [UInt8](b)
        return x.indices.filter { x[$0] != y[$0] }
    }

    /// Ticks `run` (headless: nothing drawn) until `.SetupLevel` has built its session.
    private func session(_ run: LevelRun) throws -> FerazelSession {
        var t: UInt32 = 0
        while run.session == nil && t < 4000 {
            _ = try run.tick(now: t, input: FrontInput())
            t &+= 1
        }
        return try XCTUnwrap(run.session, "the level opened within 4000 ticks")
    }

    func testLevelFixtureOpensLevel21Headless() throws {
        let base = try LevelFixture.base.get()
        let diskBefore = try dataOnDisk()
        let file = try XCTUnwrap(base.world.resource(type: "Mlvl", id: 21)).data
        let real = try LevelFile(id: 21, data: file)

        // The header switches no strip and no OmniPx mode (LL §4 "Level 21": only darkness 2 and music 9 are new).
        XCTAssertEqual(real.header.stripPict, 0)
        XCTAssertEqual(real.header.omniPxMode, 0)
        XCTAssertEqual(real.activePlacements.count, 325, "LL §4: 325 active records")

        // The literal list (by type, every record of each type): 13 types naming 30 records, as LL §4 counts them.
        let list = LevelFixture.level21
        XCTAssertEqual(list.count, 13)
        let out = try LevelFixture.leftOut(real, list)
        XCTAssertEqual(out.count, 30, "the 30 refused records")
        var byType: [Int16: Int] = [:]
        for i in out { byType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(byType, [1061: 14, 2921: 2, 2962: 1,                       // faces and talkers
                                1490: 1, 1491: 3, 1492: 1, 1493: 1,               // the L21 pipes
                                2827: 1, 2831: 2, 2833: 1, 2834: 1, 2836: 1, 2850: 1])   // Box scenery
        XCTAssertTrue(out.allSatisfy { real.placements[$0].flag == 1 })
        // By placement index too (level 10's 1090 records use it): one active record alone, and deduped against its
        // type; a misuse throws, never patches. Type 0 has 186 records on level 21, none active.
        XCTAssertEqual(try LevelFixture.leftOut(real, [.record(out[0])]), [out[0]])
        XCTAssertEqual(try LevelFixture.leftOut(real, [.record(out[0])] + list), out)
        let inactive = try XCTUnwrap(real.placements.firstIndex { $0.flag != 1 })
        XCTAssertThrowsError(try LevelFixture.leftOut(real, [.record(inactive)])) {
            XCTAssertEqual($0 as? LevelFixture.Misuse, .recordNotActive(inactive))
        }
        XCTAssertThrowsError(try LevelFixture.leftOut(real, [.record(LevelFile.placementCount)])) {
            XCTAssertEqual($0 as? LevelFixture.Misuse, .recordNotActive(LevelFile.placementCount))
        }
        XCTAssertThrowsError(try LevelFixture.leftOut(real, [.type(0)])) {
            XCTAssertEqual($0 as? LevelFixture.Misuse, .typeNotPlaced(0))
        }
        // A refusal is named by record as well as by type: every active record of the refused type on the level.
        XCTAssertEqual(LevelFixture.describe(SetupFaces.Error.notTranscribed(type: 1491), level: real),
                       "notTranscribed(type: 1491) — level 21: active records [35, 36, 135] of type 1491")
        XCTAssertEqual(LevelFixture.describe(LevelFixture.Misuse.noLevel(9), level: real), "noLevel(9)")

        // The patched `Mlvl` differs from the file only in the 30 records' active flag (record i's byte 4 + 16·i,
        // 1 → 0); every other record, every header byte and the maps after the header as the level has them.
        let res = try LevelFixture.resources(level: 21, leaveOut: list)
        let patched = try XCTUnwrap(res.world.resource(type: "Mlvl", id: 21)).data
        XCTAssertEqual(patched.count, file.count)
        let changed = diff(file, patched)
        XCTAssertEqual(changed, out.map { 4 + 16 * $0 })
        XCTAssertTrue(changed.allSatisfy { patched[patched.startIndex + $0] == 0 })
        XCTAssertTrue(changed.allSatisfy { $0 < LevelFile.headerSize }, "the maps (the stream after the header) untouched")
        // Every other World Data resource as the file has it; the other files are the same collections.
        for type in base.world.types() {
            for r in base.world.resources(of: type) where !(type == "Mlvl" && r.id == 21) {
                XCTAssertEqual(res.world.resource(type: type, id: r.id)?.data, r.data, "\(type) \(r.id)")
            }
        }
        XCTAssertEqual(res.world.types(), base.world.types())
        XCTAssertEqual(res.musicDirectory, base.musicDirectory)

        // A one-byte `header:` patch changes that byte only (0x26c6, the submerged-faces switch: 0 on level 21).
        XCTAssertEqual(file[file.startIndex + 0x26c6], 0)
        let headerOnly = try LevelFixture.resources(level: 21, leaveOut: [], header: [(offset: 0x26c6, bytes: [1])])
        let h = try XCTUnwrap(headerOnly.world.resource(type: "Mlvl", id: 21)).data
        XCTAssertEqual(diff(file, h), [0x26c6])
        XCTAssertEqual(h[h.startIndex + 0x26c6], 1)
        let both = try LevelFixture.resources(level: 21, leaveOut: list, header: [(offset: 0x26c6, bytes: [1])])
        let b = try XCTUnwrap(both.world.resource(type: "Mlvl", id: 21)).data
        XCTAssertEqual(diff(file, b), (out.map { 4 + 16 * $0 } + [0x26c6]).sorted())
        // A header patch past the header, or inside the placement table (where it could switch a left-out record back
        // on), throws; so does a level with no `Mlvl`.
        XCTAssertThrowsError(try LevelFixture.resources(level: 21, leaveOut: [],
                                                        header: [(offset: LevelFile.headerSize - 1, bytes: [0, 0])])) {
            XCTAssertEqual($0 as? LevelFixture.Misuse, .headerOutOfRange(offset: LevelFile.headerSize - 1, count: 2))
        }
        XCTAssertThrowsError(try LevelFixture.resources(level: 21, leaveOut: [.record(out[0])],
                                                        header: [(offset: 4 + 16 * out[0], bytes: [1])])) {
            XCTAssertEqual($0 as? LevelFixture.Misuse, .headerInPlacementTable(offset: 4 + 16 * out[0], count: 1))
        }
        XCTAssertThrowsError(try LevelFixture.resources(level: 999, leaveOut: [])) {
            XCTAssertEqual($0 as? LevelFixture.Misuse, .noLevel(999))
        }
        // `level:` and `header:` reach the run: level 1 with its 0x26c6 byte flipped opens as that level, patched.
        let file1 = try XCTUnwrap(base.world.resource(type: "Mlvl", id: 1)).data
        var patched1 = file1
        patched1[patched1.startIndex + 0x26c6] ^= 1
        let flipped = patched1[patched1.startIndex + 0x26c6]
        let one = try LevelFixture.open(level: 1, leaveOut: [], header: [(offset: 0x26c6, bytes: [flipped])])
        XCTAssertEqual(one.levelNumber, 1)
        let oneMlvl = try XCTUnwrap(one.resources.world.resource(type: "Mlvl", id: 1)).data
        XCTAssertTrue(one.levelFile == (try LevelFile(id: 1, data: patched1)),
                      "the run reads level 1 as patched; its Mlvl differs at \(LevelFixture.firstDifferences(oneMlvl, patched1))")

        // The level opens through `LevelRun` with `prefs:` and `carry:` as passed: every active record set up (a
        // refused one throws `notTranscribed` from the session init), none of the left-out ones.
        var prefs = FerazelPrefs()
        prefs.musicVolume = 3
        XCTAssertNotEqual(prefs, FerazelPrefs())
        var carry = LevelCarry()
        var g = GameGlobals(header: real.header)
        g.score = 4321
        carry.globals = g
        let run = try LevelFixture.open(level: 21, leaveOut: list, prefs: prefs, carry: carry)
        XCTAssertEqual(run.levelNumber, 21)
        let runMlvl = try XCTUnwrap(run.resources.world.resource(type: "Mlvl", id: 21)).data
        XCTAssertTrue(run.levelFile == (try LevelFile(id: 21, data: patched)),
                      "the run reads the patched level; its Mlvl differs at \(LevelFixture.firstDifferences(runMlvl, patched))")
        XCTAssertEqual(run.prefs, prefs)
        XCTAssertEqual(run.carry, carry, "the carry as passed")
        let s: FerazelSession
        do { s = try session(run) } catch let e as SetupFaces.Error {
            return XCTFail("level 21 refused a record the list does not leave out: "
                           + LevelFixture.describe(e, level: run.levelFile))
        }
        XCTAssertEqual(s.prefs, prefs)
        XCTAssertEqual(s.world.globals.score, 4321, "the carried G")
        let active = Set(run.levelFile.activePlacements.map(\.index))
        XCTAssertEqual(active.count, 325 - 30)
        XCTAssertTrue(active.isDisjoint(with: out))
        let fromRecords = Set(s.world.active.sprites.map { Int($0.recordIndex) }
                              + s.world.idle.entries.compactMap { $0.map { Int($0.saved.recordIndex) } })
        XCTAssertTrue(fromRecords.isDisjoint(with: out), "no sprite for a left-out record")
        XCTAssertEqual(fromRecords.intersection(active), active, "every active record set up")
        // `start:` nil → the header's start (`.NewGame`: hdr+0x2848 − 32, hdr+0x2846 − 32).
        XCTAssertEqual(s.startX, Int(real.header.startX) - 0x20)
        XCTAssertEqual(s.startY, Int(real.header.startY) - 0x20)
        XCTAssertEqual(Int(s.world.player.pixelX), s.startX)
        XCTAssertEqual(Int(s.world.player.pixelY), s.startY)

        // A given start puts the player there.
        let at = (x: Int(real.header.startX) + 300, y: Int(real.header.startY) - 64)
        let moved = try session(try LevelFixture.open(level: 21, leaveOut: list, start: at))
        XCTAssertEqual(moved.startX, at.x)
        XCTAssertEqual(moved.startY, at.y)
        XCTAssertEqual(Int(moved.world.player.pixelX), at.x)
        XCTAssertEqual(Int(moved.world.player.pixelY), at.y)
        XCTAssertEqual(moved.prefs, FerazelPrefs(), "prefs default to FerazelPrefs()")
        XCTAssertEqual(moved.world.globals.score, 0, "carry defaults to a new game's")
        // `seed:` reaches the run: seed 7 leaves the stream elsewhere after the Setups than the default seed 1.
        let seeded = try session(try LevelFixture.open(level: 21, leaveOut: list, seed: 7))
        XCTAssertNotEqual(seeded.seedAfterSetups, s.seedAfterSetups, "the seed as passed")

        // The game data stays read-only: the patch was made in memory (the six files the fixture reads, byte for byte).
        let diskAfter = try dataOnDisk()
        XCTAssertEqual(diskAfter.count, 6)
        for (name, bytes) in diskBefore { XCTAssertTrue(diskAfter[name] == bytes, "\(name) unchanged on disk") }
        XCTAssertEqual(try XCTUnwrap(LevelFixture.base.get().world.resource(type: "Mlvl", id: 21)).data, file)
    }
}

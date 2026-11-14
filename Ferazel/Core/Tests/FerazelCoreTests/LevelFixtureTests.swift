import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-FX (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-FX`, "Verification-model additions for 6A";
/// docs/ferazel/phase6-engine-contracts.md §7.2; DECISIONS D46.3): the level fixture (`LevelFixture.swift`, linked into
/// both test targets), proven headless on level 21 — LL §4 "Level 21": no strip and no OmniPx mode in its header, and it
/// opens once its 30 refused records are left out. A missing data file is a FAILURE, never a skip.
final class LevelFixtureTests: XCTestCase {

    /// FNV-1a 64 (the data file's fingerprint before and after).
    private func fnv(_ bytes: Data) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x100000001b3 }
        return h
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
        let disk = try FerazelData.dataDirectory().appendingPathComponent(FerazelData.worldFile)
        let diskBefore = fnv(try Data(contentsOf: disk))
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
        XCTAssertEqual(run.levelFile, try LevelFile(id: 21, data: patched), "the run reads the patched level")
        XCTAssertEqual(run.prefs, prefs)
        XCTAssertEqual(run.carry, carry, "the carry as passed")
        let s: FerazelSession
        do { s = try session(run) } catch let e as SetupFaces.Error {
            return XCTFail("level 21 refused a record the list does not leave out: \(e)")
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

        // The game data stays read-only: the patch was made in memory.
        XCTAssertEqual(fnv(try Data(contentsOf: disk)), diskBefore)
        XCTAssertEqual(try XCTUnwrap(LevelFixture.base.get().world.resource(type: "Mlvl", id: 21)).data, file)
    }
}

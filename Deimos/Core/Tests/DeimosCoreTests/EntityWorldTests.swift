import XCTest
import HectorResources
@testable import DeimosCore

/// The entity world (spawn-and-waves.md §1.2–§1.3, §8; micro-wave-2026-10-06.md §3.7; listings
/// `10032e60..1003308c`, `100385d0..10038838`, `100333a4..10033518`) and `GameState`'s reset.
final class EntityWorldTests: XCTestCase {
    private let bu01 = FourCC("bu01")!

    func testLevelResetIds() throws {
        var world = EntityWorld()
        XCTAssertEqual(world.groups.count, 1)
        XCTAssertEqual(world.groups[0].unit, EntityGroup.perm)
        XCTAssertEqual(world.groups[0].id, 20_000_000)
        XCTAssertEqual([world.groups[0].requested, world.groups[0].live, world.groups[0].destroyed], [0, 0, 0])
        XCTAssertEqual(world.nextGroupID, 20_000_001)
        XCTAssertEqual(world.nextSerial, 1000)
        XCTAssertEqual(world.takeSerial(), 1000)                               // 10035d78..10035d84 post-increment
        XCTAssertEqual(world.takeSerial(), 1001)
        _ = world.openGroup(unit: bu01, size: 3, ownerGroupID: nil, editorHeading: 0, stationary: false,
                            terrainEffects: false)
        _ = world.allocate()
        world.groundCount = 4
        world.noticesShown = [Array("Boss".utf8)]
        world.levelReset()
        XCTAssertEqual(world.groups.count, 1)
        XCTAssertEqual(world.groups[0].id, 20_000_000)
        XCTAssertEqual(world.nextGroupID, 20_000_001)
        XCTAssertEqual(world.nextSerial, 1000)
        XCTAssertEqual(world.liveCount, 0)
        XCTAssertEqual(world.freeHint, 0)                                      // FUN_10038450 stores 0, not −1
        XCTAssertFalse(world.inUse.contains(true))
        XCTAssertEqual(world.groundCount, 0)
        XCTAssertTrue(world.noticesShown.isEmpty)
        // pendingLevelObjects: FUN_10032e60's last call FUN_10035900 frees and rebuilds it — C8's.

        // GameState: a fresh world and buffers, the level reset clears the entity-limit latch (-0x6110).
        let assets = try TestAssets.loaded.get()
        var state = GameState(assets: assets, prefs: DeimosPrefs.fresh, seed: 0x469c2)
        XCTAssertEqual(state.players.count, 2)
        XCTAssertEqual(state.rng.state, 0x469c2)
        XCTAssertEqual(state.world.groups.count, 1)
        XCTAssertTrue(state.tickOps.isEmpty)
        XCTAssertNil(state.film)
        XCTAssertNil(state.trace)
        XCTAssertTrue(state.flags.drawShadows)
        XCTAssertEqual(state.flags.numPlayers, 0)
        XCTAssertEqual(state.flags.framesPresented, 0)
        XCTAssertFalse(state.flags.gameOverNoticed)
        XCTAssertEqual(state.tally.coin.count, 2)
        XCTAssertFalse(state.players[0].cheated)                               // constructor 100262e0
        XCTAssertEqual(state.players[0].multiplierIndicator, -1)               // constructor 100262d8
        state.entityLimitWarned = true
        state.world.nextSerial = 1234
        state.levelResetEntities()
        XCTAssertFalse(state.entityLimitWarned)
        XCTAssertEqual(state.world.nextSerial, 1000)

        // FilmCursor: FUN_100097a0 reads bytes 0…frames−1, then byte `frames` (0, past the recording) and
        // advances; once cursor > frames (signed) nothing is read or advanced. FUN_10009750 = signed P1
        // cursor > frames. Scores are recorded per read, by consumed byte index.
        var cursor = FilmCursor(film: try Self.film(inputs: [5, 6, 7]))
        XCTAssertEqual(cursor.next(player: 0, score: 10), 5)
        XCTAssertEqual(cursor.next(player: 0, score: 20), 6)
        XCTAssertEqual(cursor.next(player: 0, score: 30), 7)
        XCTAssertFalse(cursor.finished)                                        // cursor 3 == frames: not over
        XCTAssertEqual(cursor.next(player: 0, score: 40), 0)                   // the read one past the recording
        XCTAssertEqual(cursor.cursors[0], 4)
        XCTAssertTrue(cursor.finished)                                         // 4 > 3
        XCTAssertEqual(cursor.next(player: 0, score: 50), 0)                   // no read, no advance, no record
        XCTAssertEqual(cursor.cursors[0], 4)
        XCTAssertEqual(cursor.readScores[0], [10, 20, 30, 40])
        XCTAssertEqual(cursor.score(player: 0, atRead: 2), 30)                 // the last recorded byte's read
        XCTAssertEqual(cursor.score(player: 0, atRead: 3), 40)
        XCTAssertNil(cursor.score(player: 0, atRead: 4))
        XCTAssertEqual(cursor.scoreAtRead[0], 40)
        XCTAssertNil(cursor.scoreAtRead[1])
        cursor.cursors[0] = -1                                                 // signed: −1 > 3 is false
        XCTAssertFalse(cursor.finished)
        cursor.cursors[0] = Int32.max
        XCTAssertTrue(cursor.finished)
    }

    /// A one-player film image (`Film` layout): version 0x2715, P1 block with `inputs`, zero padding.
    private static func film(inputs: [UInt8]) throws -> Film {
        var b = [UInt8](repeating: 0, count: Film.size)
        func put(_ v: UInt32, _ at: Int) {
            b[at] = UInt8(v >> 24); b[at + 1] = UInt8(v >> 16 & 0xff); b[at + 2] = UInt8(v >> 8 & 0xff)
            b[at + 3] = UInt8(v & 0xff)
        }
        put(Film.version, 0)
        put(0x469c2, 4)
        put(FourCC("le07")!.rawValue, 8)
        b[0x0c] = 1
        put(UInt32(inputs.count), 0x10)
        put(Film.scoreBias, 0x14)
        for (i, v) in inputs.enumerated() { b[0x1c + i] = v }
        return try Film(data: Data(b))
    }

    func testPoolCapAndHint() {
        var world = EntityWorld()
        var slots: [Int] = []
        for _ in 0..<EntityWorld.capacity {                                    // bounded: 1000 allocations
            guard let s = world.allocate() else { return XCTFail("refused before 1000 live") }
            slots.append(s)
        }
        XCTAssertEqual(slots, Array(0..<1000))                                 // first free slot, in order
        XCTAssertEqual(world.liveCount, 1000)
        XCTAssertNil(world.allocate())                                         // 10038600: count ≥ 1000 → NULL
        XCTAssertEqual(world.liveCount, 1000)

        // FUN_10038810: free → hint = that slot; the next allocation takes it.
        // The count check is `count >= 1000` (10038600 cmpwi r4,0x3e8; blt): with 1000 in use it refuses even
        // when a slot's byte reads free (a `>` slip would hand out slot 999 here).
        world.inUse[999] = false
        XCTAssertNil(world.allocate())
        world.freeHint = 999
        XCTAssertNil(world.allocate())
        world.inUse[999] = true
        world.freeHint = -1

        world.entities[417].shields = 2.5                                      // a field FUN_100142f0 keeps
        world.entities[417].deleted = true
        // The object reset FUN_10012650 writes none of +0x64, +0x75, +0x78, +0x7c, +0x80 (micro-wave §3.6).
        world.entities[417].object.glowTintColour = 0x1234
        world.entities[417].object.hitGlowOn = true
        world.entities[417].object.hitGlowFalling = true
        world.entities[417].object.hitGlowLevel = 12
        world.entities[417].object.hitGlowStep = 6
        world.entities[417].object.hitGlowColour = 0x7fff
        world.entities[417].object.x = 99
        world.free(417)
        XCTAssertEqual(world.freeHint, 417)
        XCTAssertEqual(world.allocate(), 417)
        XCTAssertEqual(world.freeHint, -1)
        let e = world.entities[417]
        XCTAssertEqual(e.slot, 417)                                            // +0x148
        XCTAssertFalse(e.deleted)                                              // reset
        XCTAssertEqual([e.serial, e.groupID, e.state], [-1, -1, -1])
        XCTAssertEqual([e.ownerPlayer, e.killer, e.trackedPlayer], [-1, -1, -1])
        XCTAssertNil(e.owner)
        XCTAssertEqual(e.ownerSerial, -1)
        XCTAssertEqual(e.shownWeapon, .none)
        XCTAssertEqual(e.shields, 2.5)                                         // not reset: stale, as in the pool
        XCTAssertEqual(e.object.glowTintColour, 0x1234)
        XCTAssertTrue(e.object.hitGlowFalling)
        XCTAssertEqual(e.object.hitGlowLevel, 12)
        XCTAssertEqual(e.object.hitGlowStep, 6)
        XCTAssertEqual(e.object.hitGlowColour, 0x7fff)
        XCTAssertFalse(e.object.hitGlowOn)                                     // +0x74 = 0 (1001272c)
        XCTAssertEqual(e.object.x, 0)                                          // +0x00 = 0.0 (10012674)

        // Two frees: the most recent wins; once used, the lowest free slot is next.
        world.free(10)
        world.free(5)
        XCTAssertEqual(world.allocate(), 5)
        XCTAssertEqual(world.allocate(), 10)
        XCTAssertNil(world.allocate())
    }

    func testPermMembershipRule() {
        var world = EntityWorld()
        // 1 member, no owner → PERM (index 0): +0xa4 = n (stored), +0xa8 += n.
        XCTAssertEqual(world.openGroup(unit: bu01, size: 1, ownerGroupID: nil, editorHeading: 0, stationary: false,
                                       terrainEffects: false), 0)
        XCTAssertEqual(world.openGroup(unit: bu01, size: 1, ownerGroupID: nil, editorHeading: 0, stationary: false,
                                       terrainEffects: false), 0)
        XCTAssertEqual(world.groups[0].requested, 1)
        XCTAssertEqual(world.groups[0].live, 2)
        XCTAssertEqual(world.groups[0].unit, EntityGroup.perm)
        // 2 members → a new group at the tail, id from the counter.
        let g = world.openGroup(unit: bu01, size: 2, ownerGroupID: nil, editorHeading: 45, stationary: true,
                                terrainEffects: true)
        XCTAssertEqual(g, 1)
        XCTAssertEqual(world.groups[1].id, 20_000_001)
        XCTAssertEqual(world.groups[1].unit, bu01)
        XCTAssertEqual([world.groups[1].requested, world.groups[1].live, world.groups[1].destroyed], [2, 2, 0])
        XCTAssertEqual(world.groups[1].editorHeading, 45)
        XCTAssertTrue(world.groups[1].stationary && world.groups[1].terrainEffects)
        // 1 member with an owner outside PERM → a new group; with an owner in PERM (id 20000000) → PERM.
        XCTAssertEqual(world.openGroup(unit: bu01, size: 1, ownerGroupID: 20_000_001, editorHeading: 0,
                                       stationary: false, terrainEffects: false), 2)
        XCTAssertEqual(world.groups[2].id, 20_000_002)
        XCTAssertEqual(world.openGroup(unit: bu01, size: 1, ownerGroupID: 20_000_000, editorHeading: 0,
                                       stationary: false, terrainEffects: false), 0)
        XCTAssertEqual(world.groups[0].live, 3)
        // PERM persists empty (10036384..1003639c): an emptied group is freed unless it is PERM.
        world.groups[0].live = 0
        world.groups[1].live = 0
        XCTAssertFalse(world.groups[0].freedWhenEmpty)
        XCTAssertTrue(world.groups[1].freedWhenEmpty)
        world.levelReset()
        XCTAssertEqual(world.groups.count, 1)
        XCTAssertFalse(world.groups[0].freedWhenEmpty)
    }

    func testSamePassAppendIsVisited() {
        var world = EntityWorld()
        let a = world.allocate()!, b = world.allocate()!
        world.groups[0].members = [a, b]
        var walk = EntityWorld.Walk()
        var visited: [Int] = []
        var appended = false
        var steps = 0
        while let i = walk.next(in: world) {
            steps += 1
            if steps > 10 { return XCTFail("walk did not terminate") }
            visited.append(i)
            if i == a && !appended {
                // Mid-pass: one member appended to PERM's tail and a new group at the list's tail.
                appended = true
                let c = world.allocate()!
                world.groups[0].members.append(c)
                let g = world.openGroup(unit: bu01, size: 2, ownerGroupID: nil, editorHeading: 0, stationary: false,
                                        terrainEffects: false)
                let d = world.allocate()!
                world.groups[g].members.append(d)
            }
        }
        XCTAssertEqual(visited, [0, 1, 2, 3])                                  // INDEX #38: counts re-read
    }
}

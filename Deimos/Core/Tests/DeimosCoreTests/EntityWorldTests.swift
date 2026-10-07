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
        XCTAssertTrue(world.pendingLevelObjects.isEmpty)

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
        state.entityLimitWarned = true
        state.world.nextSerial = 1234
        state.levelResetEntities()
        XCTAssertFalse(state.entityLimitWarned)
        XCTAssertEqual(state.world.nextSerial, 1000)
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
        world.entities[417].shields = 2.5                                      // a field FUN_100142f0 keeps
        world.entities[417].deleted = true
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

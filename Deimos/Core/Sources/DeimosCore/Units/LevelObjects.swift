import Foundation
import HectorResources

/// Level objects: the pending list, the spawn at a map row, the load pass (level-scroll-objects.md §2, §3,
/// §6.2–§6.4, HIGH; plan C8).
///
/// Listing reads for C8:
/// - `FUN_10035900(objectList) @ 10035900` (`10035900..10035af8`): frees the old list (`FUN_10035810`), a new
///   list at −0x6104; per object in file order: unit `'none'` → skipped silently; no `unde` definition
///   (`FUN_1003d2f0`) → "NOTE: An invalid Unit ID…" and skipped; else `FUN_1003e680` (resource load, not
///   modelled) and a 0xbc record appended: +0x98 unit, +0x94 = −1, +0xb0 = 0, +0xa4/+0xa8/+0xac = 0, +0xb4
///   heading, +0xb8 stationary, +0xb9 terrain effects, +0x9c = float(xLoc), +0xa0 = float(yLoc), then
///   **x −= 32.0** (`*(float*)(0x100d7204 + 0xc)`, `fsubs`) when the unit's layer (+0x08) is `grnd`.
/// - `FUN_10033090(row) @ 10033090` (`10033090..10033210`): row < 0 → nothing (`10033098 or.; blt`); for each
///   pending record (the initial count; an unlink backs the iterator up, so every record is visited once):
///   `fctiwz(+0xa0) == row` → a request from the level template `0x100eb41c` (runtime: +0x24 = −1) with unit,
///   x, y, **+0x0c = 1**, +0x18 heading, +0x1c/+0x1d options; `FUN_10033220(&req, 0, 0)`; then the record is
///   unlinked and freed **unconditionally** (`100331b8..100331ec`). Same-row objects spawn in file order.
/// - `FUN_1000fa10 @ 1000fa10` (`1000fa10..1000fa8c`): unless spawning is disabled (the console-only byte
///   −0x6204, never set here), rows `bottom − i` for i in 0 ..< bottom − (top − 65), i.e. bottom down to
///   top − 64, each through `FUN_10033090`.
extension GameState {
    /// `FUN_32e60`'s level start as far as the entity world goes: `levelResetEntities` (C7) then the pending list
    /// `FUN_10035900(level objects)`.
    public mutating func levelStartEntities(level: LevelDefinition,
                                            include: ((LevelDefinition.Object) -> Bool)? = nil) {
        levelResetEntities()
        buildPendingLevelObjects(level, include: include)
    }

    /// `FUN_10035900` — rebuild `world.pendingLevelObjects` from the level's placements. `include` is a
    /// test-only placement filter (nil = every placement, the original).
    public mutating func buildPendingLevelObjects(_ level: LevelDefinition,
                                                  include: ((LevelDefinition.Object) -> Bool)? = nil) {
        world.pendingLevelObjects = []                                         // 1003591c..10035940
        for o in level.objects {                                               // 10035990..10035ae4
            if let include, !include(o) { continue }
            guard o.unit != .none else { continue }                            // 100359a4..100359b0
            guard let ui = assets.unitIndex[o.unit] else { continue }          // 100359b4..100359f0
            var g = EntityGroup()
            g.unit = o.unit                                                    // 10035a4c
            g.id = -1                                                          // 10035a58
            g.requested = 0; g.live = 0; g.destroyed = 0                       // 10035a60..10035a68
            g.editorHeading = o.headingDegrees                                 // 10035a74
            g.stationary = o.isStationary                                      // 10035a80
            g.terrainEffects = o.enableTerrainEffects                          // 10035a88
            g.x = Float(o.xLoc)                                                // 10035a8c..10035aa0
            g.y = Float(o.yLoc)                                                // 10035aa4..10035ab8
            if assets.definitions.units[ui].layer == UnitDefinition.ground {   // 10035abc..10035ac8
                g.x = g.x - Float(32)                                          // 10035acc..10035ad8
            }
            world.pendingLevelObjects.append(g)
        }
    }

    /// `FUN_10033090(row)` — request every pending object placed on map row `row`, in file order, and drop it.
    public mutating func spawnLevelObjects(row: Int32, log: ((SpawnEvent) -> Void)? = nil) {
        guard row >= 0 else { return }                                         // 10033098..100330a8
        var matches: [EntityGroup] = []
        var keep: [EntityGroup] = []
        for g in world.pendingLevelObjects {                                   // 100330e0..100331fc
            if EntityDraw.fctiwz(g.y) == row { matches.append(g) } else { keep.append(g) }   // 100330f4..10033108
        }
        // Every match is unlinked and freed (100331c4..100331ec) whatever the request does; no request can reach
        // the pending list, so unlinking them all first is the same.
        world.pendingLevelObjects = keep
        for g in matches {
            var req = SpawnRequest.template                                    // 1003310c..10033178
            req.unit = g.unit                                                  // 1003317c..10033180
            req.x = g.x                                                        // 10033184..10033188
            req.y = g.y                                                        // 1003318c..10033190
            req.yIsMapRow = true                                               // 10033194
            req.editorHeading = g.editorHeading                                // 10033198..1003319c
            req.stationary = g.stationary                                      // 100331a0..100331a4
            req.terrainEffects = g.terrainEffects                              // 100331a8..100331ac
            spawn(req, log: log)                                               // 100331b0 FUN_10033220(&req, 0, 0)
        }
    }

    /// `FUN_1000fa10` — the load pass: rows window bottom down to window top − 64.
    public mutating func spawnLoadPassLevelObjects(log: ((SpawnEvent) -> Void)? = nil) {
        let top = scroll.window.top, bottom = scroll.window.bottom             // 1000fa38..1000fa40
        let n = bottom &- (top &- 65)                                          // 1000fa48..1000fa4c
        var i: Int32 = 0
        while i < n {                                                          // 1000fa58..1000fa70
            spawnLevelObjects(row: bottom &- i, log: log)
            i &+= 1
        }
    }
}

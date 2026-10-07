import Foundation
import HectorResources

/// Removal: the deletion sweep, the member removal with coins and children, the direct removers and the wreck
/// stamp (damage-health-death.md §4.3, spawn-and-waves.md §5, loose-ends-combat.md §4.1–§4.2,
/// sprite-geometry-draw.md §3.2; plan C11b).
///
/// Listing reads (`disasm-review3-all.txt`):
/// - `FUN_10036610 @ 10036610` (`10036610..10036928`): group count taken **once** (`10036628..10036634`); per group
///   the member count **once** (`1003667c..10036688`); every member visited once in list order (the iterator is
///   fixed up by the unlink `FUN_10000c00`, so members/groups appended during the sweep are not reached). For a
///   member with +0xcb: (1) `includeInGroundAccuracyCount` → −0x6118 −= 1; (2) `destructDrawToTerrain` (+0x4b2) →
///   +0x36 = 1, +0x35 = 0, +0x38 = `castsShadows` (+0x11e), `FUN_10012f20`; (3) +0xda ∧ the current state's
///   `destroyOwnerOnDestruction` (+0x32d) ∧ `FUN_10036ab0(+0x140)` ∧ owner +0xcb == 0 → `FUN_10016300(owner,
///   +0xd9, game time)`; (4) `deletionSpawn_ID` (+0x2dc) ≠ `none` ∧ ¬+0xda ∧ `FUN_10016880` → the template
///   r2+0x50ec (`0x100eb41c`) with the ID, `FUN_100128d0` position, +0x14 = +0xd8, +0x20 = e, +0x24 = +0x9c →
///   `FUN_10033220`; (5) `FUN_10036120(group, e, +0xda, +0xd9 ≠ −1)`; unlink; `FUN_10038810` (pool free); when
///   `FUN_10036120` said empty and the group is not `PERM` → unlink and destroy the group and go to the next one.
/// - `FUN_10036120(group, e, destroyed, byPlayer) @ 10036120` (`10036120..100363b8`): +0x13e → (destroyed ∧
///   `destructDestroyChildren` +0x4b0 → `FUN_100363c0(e)`); `destructDeleteChildren` +0x4b1 → `FUN_100364f0(e)`.
///   Destroyed → group +0xac += 1, group kill = +0xac == +0xa4. byPlayer ∧ destroyed ∧ ¬+0xca → (`destructCoin_ID`
///   +0x4a8 ≠ `none` ∧ `destructNumCoinsToRelease` +0x4a4 > 0 → that many requests from the template r2+0x50ec, one
///   struct reused, count read once at `10036270`); then (group not `PERM` ∧ group kill ∧ `destructCoinOnGroupKill_ID`
///   +0x4ac ≠ `none`) → one request. The coin requests keep the template's +0x14 = 0xff. Destroyed →
///   `FUN_10016300(e, +0xd9, game time)` (a no-op when +0xcb is already set). +0xcb = 1; group +0xa8 −= 1; returns
///   +0xa8 ≤ 0 ∧ not `PERM`. **No +0xcb guard** — a directly removed entity runs it again in the sweep.
/// - `FUN_100363c0(e)` / `FUN_100364f0(e)` (`100363c0..100364ec`, `100364f0..10036600`): every group member (counts
///   once) other than e whose +0x144 == e's +0x9c: `canBeDestroyedOnOwnerDestruction` (+0x329) →
///   `FUN_10036120(g, m, 1, m.+0xd9 ≠ −1)` / `canBeDeletedOnOwnerDeletion` (+0x32a) → `FUN_10036120(g, m, 0, 0)`.
/// - `FUN_10034b90(player)`, `FUN_10034de0(serial)` (`10034b90..10034cd4`, `10034de0..10034ed8`): counts once
///   (`10034bc0`/`10034c14`, `10034e04`/`10034e58`), byPlayer 0. `FUN_10036be0` stays in Units/Spawn.swift
///   (`removeEntities(ofUnit:ownedBy:)`), now calling `removeMember`.
extension GameState {
    // MARK: - FUN_10036610

    /// `FUN_10036610` — the deletion sweep after the entity loop (see the type's comment). Terrain stamps go to
    /// `tickOps`.
    public mutating func sweepDeleted() {
        let groupCount = world.groups.count                                  // 10036628..10036634
        var visitedGroups = 0
        var g = 0
        while visitedGroups < groupCount, g < world.groups.count {
            let memberCount = world.groups[g].members.count                  // 1003667c..10036688
            var visited = 0
            var k = 0
            var groupFreed = false
            while visited < memberCount, k < world.groups[g].members.count {
                visited += 1
                let e = world.groups[g].members[k]
                guard world.entities[e].deleted else { k += 1; continue }    // 100366bc..100366c8
                let u = assets.definitions.units[world.entities[e].unit]
                if u.includeInGroundAccuracyCount {                          // 100366cc..100366e0
                    world.groundCount &-= 1
                }
                if u.destructDrawToTerrain {                                 // 100366e4..1003670c
                    world.entities[e].object.drawToTerrain = true
                    world.entities[e].object.drawNow = false
                    world.entities[e].object.drawShadow = u.castsShadows
                    tickOps += terrainStamp(e).map { .draw($0) }
                }
                if world.entities[e].destroyed, let st = currentState(e),    // 10036714..10036734
                   st.destroyOwnerOnDestruction, ownerLinkValid(e),          // 10036738..10036744
                   let o = world.entities[e].owner, !world.entities[o].deleted {   // 10036748..10036754
                    destroyEntity(o, killer: world.entities[e].killer, now: flags.gameTime)   // 10036758..1003676c
                }
                if u.deletionSpawn != .none, !world.entities[e].destroyed,   // 10036774..1003678c
                   mediaGate(e) {                                            // 10036790..100367a0
                    spawn(childRequest(e, unit: u.deletionSpawn))            // 100367a4..1003683c (r2+0x50ec)
                }
                let byPlayer = world.entities[e].killer != -1                // 10036840..10036860
                let empty = removeMember(group: g, entity: e, destroyed: world.entities[e].destroyed,
                                         byPlayer: byPlayer)                 // 10036864
                world.groups[g].members.remove(at: k)                        // 1003686c..10036878 FUN_10000c00
                world.free(e)                                                // 10036880..1003688c FUN_10038810
                if empty && world.groups[g].unit != EntityGroup.perm {       // 10036890..100368a4
                    world.groups.remove(at: g)                               // 100368a8..100368f4
                    groupFreed = true
                    break                                                    // 100368fc
                }
            }
            visitedGroups += 1                                               // 1003690c
            if !groupFreed { g += 1 }
        }
    }

    // MARK: - FUN_10036120 and the child walkers

    /// `FUN_10036120(group, e, destroyed, byPlayer)` — returns true when the group is now empty and not `PERM`.
    @discardableResult
    mutating func removeMember(group g: Int, entity e: Int, destroyed: Bool, byPlayer: Bool) -> Bool {
        let u = assets.definitions.units[world.entities[e].unit]             // 10036150 (r31)
        if world.entities[e].hasSpawnRecords {                               // 1003614c..10036158
            if destroyed && u.destructDestroyChildren {                      // 1003615c..1003616c
                destroyChildren(of: e)                                       // 10036170..10036174 FUN_100363c0
            }
            if u.destructDeleteChildren {                                    // 10036178..10036180
                deleteChildren(of: e)                                        // 10036184..10036188 FUN_100364f0
            }
        }
        var groupKill = false
        if destroyed {                                                       // 1003618c..10036190
            world.groups[g].destroyed &+= 1                                  // 10036194..1003619c
            groupKill = world.groups[g].destroyed == world.groups[g].requested   // 100361a0..100361b0
        }
        if byPlayer && destroyed && !world.entities[e].collected {           // 100361b4..100361cc
            if u.destructCoin != .none && u.destructNumCoinsToRelease > 0 {  // 100361d0..100361e8
                var req = SpawnRequest.template                              // 100361ec..10036254 (r2+0x50ec)
                req.unit = u.destructCoin
                req.x = world.entities[e].object.x                           // 10036258 FUN_100128d0
                req.y = world.entities[e].object.y
                req.owner = e                                                // 10036260
                req.ownerSerial = world.entities[e].serial                   // 10036268..1003626c
                let n = u.destructNumCoinsToRelease                          // 10036270 (read once)
                var c: Int32 = 0
                while c < n {                                                // 10036274..10036290
                    spawn(req)
                    c &+= 1
                }
            }
            if world.groups[g].unit != EntityGroup.perm, groupKill,          // 10036294..100362a8
               u.destructCoinOnGroupKill != .none {                          // 100362ac..100362b8
                var req = SpawnRequest.template                              // 100362bc..10036324
                req.unit = u.destructCoinOnGroupKill
                req.x = world.entities[e].object.x                           // 10036328 FUN_100128d0
                req.y = world.entities[e].object.y
                req.owner = e                                                // 10036330
                req.ownerSerial = world.entities[e].serial                   // 1003633c..10036344
                spawn(req)                                                   // 10036348
            }
        }
        if destroyed {                                                       // 1003634c..10036350
            destroyEntity(e, killer: world.entities[e].killer, now: flags.gameTime)   // 10036354..10036368
        }
        world.entities[e].deleted = true                                     // 10036370..10036374
        world.groups[g].live &-= 1                                           // 10036378..10036380
        return world.groups[g].freedWhenEmpty                                // 10036384..100363a0
    }

    /// `FUN_100363c0(e)` — every other member owned (+0x144) by e whose state has
    /// `canBeDestroyedOnOwnerDestruction` is removed as destroyed, byPlayer = its own +0xd9 ≠ −1.
    mutating func destroyChildren(of e: Int) {
        let serial = world.entities[e].serial                                // 10036478
        let groupCount = world.groups.count                                  // 100363d8..100363e4
        var g = 0
        while g < groupCount {
            let memberCount = world.groups[g].members.count                  // 1003642c..10036438
            var k = 0
            while k < memberCount {
                let m = world.groups[g].members[k]
                if m != e, world.entities[m].ownerSerial == serial,          // 1003646c..10036480
                   let st = currentState(m), st.canBeDestroyedOnOwnerDestruction {   // 10036484..10036498
                    removeMember(group: g, entity: m, destroyed: true,
                                 byPlayer: world.entities[m].killer != -1)   // 1003649c..100364c0
                }
                k += 1
            }
            g += 1
        }
    }

    /// `FUN_100364f0(e)` — every other member owned (+0x144) by e whose state has `canBeDeletedOnOwnerDeletion` is
    /// removed, not destroyed, byPlayer 0.
    mutating func deleteChildren(of e: Int) {
        let serial = world.entities[e].serial                                // 100365a0
        let groupCount = world.groups.count                                  // 10036508..10036514
        var g = 0
        while g < groupCount {
            let memberCount = world.groups[g].members.count                  // 10036558..10036564
            var k = 0
            while k < memberCount {
                let m = world.groups[g].members[k]
                if m != e, world.entities[m].ownerSerial == serial,          // 10036594..100365a8
                   let st = currentState(m), st.canBeDeletedOnOwnerDeletion {   // 100365ac..100365c0
                    removeMember(group: g, entity: m, destroyed: false, byPlayer: false)   // 100365c4..100365d4
                }
                k += 1
            }
            g += 1
        }
    }

    // MARK: - Direct removers

    /// `FUN_10034b90 @ 10034b90(player)` (`10034ba4..10034cc0`): player −1 → nothing; every group member (group list
    /// order, member order) whose `+0xd8` == player: its state's `canBeDestroyedOnOwnerDestruction` (+0x329) →
    /// `FUN_10036120(group, e, 1, 0)`, else `canBeDeletedOnOwnerDeletion` (+0x32a) → `FUN_10036120(group, e, 0, 0)`.
    /// Both counts are taken once (`10034bb8..10034bc0`, `10034c08..10034c14`).
    mutating func destroyEntitiesOwned(byPlayer player: Int8) {
        guard player != -1 else { return }                                   // 10034ba4..10034bb0
        let groupCount = world.groups.count                                  // 10034bb8..10034bc0 (counted once)
        var g = 0
        while g < groupCount {
            let memberCount = world.groups[g].members.count                  // 10034c08..10034c14 (counted once)
            var k = 0
            while k < memberCount {
                let e = world.groups[g].members[k]
                if world.entities[e].ownerPlayer == player, let st = currentState(e) {   // 10034c48..10034c60
                    if st.canBeDestroyedOnOwnerDestruction {                 // 10034c68..10034c84
                        removeMemberStub(group: g, entity: e, destroyed: true)
                    } else if st.canBeDeletedOnOwnerDeletion {               // 10034c8c..10034ca8
                        removeMemberStub(group: g, entity: e, destroyed: false)
                    }
                }
                k += 1
            }
            g += 1
        }
    }

    /// `FUN_10034de0 @ 10034de0(serial)` (`10034df8..10034ec4`): the first group member (group list order, member
    /// order) whose serial `+0x9c` matches → `FUN_10036120(group, e, 0, 0)`, then return. No deleted-flag test.
    /// Both counts are taken once (`10034dfc..10034e04`, `10034e50..10034e58`).
    mutating func removeEntity(serial: Int32) {
        let groupCount = world.groups.count
        for g in 0..<groupCount {
            let memberCount = world.groups[g].members.count
            for k in 0..<memberCount {
                let e = world.groups[g].members[k]
                guard world.entities[e].serial == serial else { continue }   // 10034e88..10034e94
                removeMemberStub(group: g, entity: e, destroyed: false)      // 10034e98..10034ea4
                return
            }
        }
    }

    /// `FUN_10036120(group, e, destroyed, 0)` — the direct removers' call (byPlayer 0); the name is C14's (plan C11b
    /// amendment: moved here under the same name and wired to the real `removeMember`).
    mutating func removeMemberStub(group g: Int, entity e: Int, destroyed: Bool) {
        removeMember(group: g, entity: e, destroyed: destroyed, byPlayer: false)
    }

    // MARK: - The wreck stamp

    /// `FUN_10012f20(e)` with +0x36 set (sprite-geometry-draw §3.2; listing `10012fc4..1001308c`, `10013264..100132a4`,
    /// `10013380..10013404`, `10013484..100134c0`, `1001387c..10013948`, `10013f50..1001401c`): nothing when +0x68 ≤
    /// 0.0; the shadow when +0x38 and the SHADOWS byte (G+0x28), then the sprite passes when +0x37. With +0x36 no view
    /// offset is subtracted; the sprite command is at (`fctiwz(x)` + 32, `fctiwz(y)` + window top) (int adds), the
    /// shadow at (`fctiwz(32 + ((x + dx) − 0))`, `fctiwz(top + (y + dy))`) (single adds, dx/dy the shadow offsets of
    /// `FUN_10013460`); every command gets flags |8 and the clip = the terrain buffer's bounds (`FUN_1000a530`
    /// on display+0x6c = the map image = `#background_RECT`'s size); the sprite passes go to layer 1, the shadow to
    /// layer 0; +0x35 = 0 → queued.
    /// The sprite's layer-1 / |8 / clip branch is taken only when game time > the object's +0x90 (last stamp time),
    /// which the replica does not store (no field; parallel wave): from the sweep it always holds, because +0x90 is
    /// written only by a stamp at an earlier tick of the slot's occupants (a slot freed by the sweep is first
    /// reallocated at the same tick but swept no earlier than the next).
    func terrainStamp(_ e: Int) -> [DrawCommand] {
        var o = world.entities[e].object
        guard o.visibility > 0 else { return [] }                            // 10012f3c..10012f48
        let top = scroll.window.top                                          // FUN_1000fec0
        let bg = scroll.backgroundRect
        let bounds = MacRect(top: 0, left: 0, bottom: bg.bottom &- bg.top, right: bg.right &- bg.left)
        o.pansWithView = false                                               // +0x36: the view offset is skipped
        var out: [DrawCommand] = []
        if o.drawShadow && flags.drawShadows {                               // 10012f4c..10012f6c
            var c = EntityDraw.shadowCommand(&o, hOffset: 0, floats: assets.floats)
            let airRow = c.layer == 6 || (c.layer == 7 && o.air)            // the shadow row FUN_10013460 chose
            let k: Float = airRow ? (o.adjustShadowForScaling ? c.scale : Float(0.5)) : c.scale
            let fx = EntityDraw.fctiwz(assets.floats[airRow ? 48 : 50])
            let fy = EntityDraw.fctiwz(assets.floats[airRow ? 49 : 51])
            let dx = EntityDraw.fctiwz(k * Float(fx)), dy = EntityDraw.fctiwz(k * Float(fy))
            var sx: Float = o.x + Float(dx)                                  // fadds
            sx = sx - Float(0)                                               // fsubs (view offset 0)
            c.x = EntityDraw.fctiwz(Float(32) + sx)                          // fadds; fctiwz
            c.y = EntityDraw.fctiwz(Float(top) + (o.y + Float(dy)))          // fadds; fadds; fctiwz
            c.layer = 0                                                      // 100138a8 / 10013f7c
            c.flags |= 8                                                     // 100138c0 / 10013f94
            c.clip = bounds                                                  // 10013944 / 10014018 FUN_1000a530
            out.append(c)
        }
        if o.drawSprite {                                                    // 10012f74..10012f84
            for var c in EntityDraw.spriteCommands(&o, hOffset: 0) {
                c.x = c.x &+ 32                                              // 10013070
                c.y = c.y &+ top                                             // 10013088
                c.layer = 1                                                  // 10013290
                c.flags |= 8                                                 // 1001328c / 10013394 / 100133f4
                c.clip = bounds                                              // 1001329c FUN_1000a530
                out.append(c)
            }
        }
        return out
    }
}

import Foundation
import HectorResources

/// The spawn-set executor `FUN_10015b40(e, now) @ 10015b40` (spawn-and-waves.md §2.3–§2.5, units-movement.md §9;
/// plan C10). Its first call, the rotation gate `FUN_10017150` (`10015b64`, units-movement §8.2, spawn-and-waves
/// §2.4), is C9's (parallel wave): **C12 calls C9's gate immediately before `runSpawnSets`**, which is the rest of
/// the function (`10015b6c..1001619c`).
///
/// Listing read for C10, per set k of the current state's list (`state+0x5dc`, record list `+0x19c + 4·state`
/// re-read per set at `10015bc8..10015be0`; the count is taken once, `10015ba4`):
/// 1. `Spawn_ID` `none` (`10015be8..10015bf8`), inactive +0x14 (`10015bfc`), rate +0x00 < 0 (`10015c08`), or
///    fleeing +0xcc without `SpawnIfFleeing` (`10015c14..10015c28`) → next set, nothing advances.
/// 2. `Don'tSpawnOffscreen` and 0 < remaining ≥ volley and not `FUN_10016bd0` → remaining = 0, next
///    (`10015c2c..10015c6c`).
/// 3. remaining > 0: countdown > 0 → countdown − 1 (`10015c80..10015c90`); still > 0 → next; else remaining − 1
///    and **draw `10015cb8`** countdown = `R(DelayMin, DelayMax)`, then the request.
/// 4. remaining ≤ 0: not `RepeatSpawns` → inactive (`10015cc8..10015cdc`); `now < last + rate` (signed) → next;
///    else the re-arm: last = now, **draw `10015d00`** countdown = `R(Delay…)`, **draw `10015d14`** volley =
///    `R(NumInVolley…)`, remaining = volley, **draw `10015d30`** rate = `R(Rate…)`; `PauseAnyRotationWhileSpawning`
///    and `TimeToPause` > +0xc4 (signed) → +0xc4 = `TimeToPause` (`10015d3c..10015d58`). No request this tick.
/// 5. The request (`10015d64..10016188`): u = the unit of `Spawn_ID` (may be nil); u with `terrainEffect`
///    (+0x132) needs the spawner not stationary (+0x13c) and with terrain effects (+0x13d), else no request
///    (the countdown was already redrawn). The template `0x100e64b0` (`r2+0x180`; runtime +0x24 = −1), unit =
///    `Spawn_ID`; position per spawn-and-waves §2.5 — **except** that the rotation uses the facing **plus**
///    `HeadingDegrees` when `SetHeading` (`10015f8c or r19,r3,r3` … `10015f9c add r19,r19,r0` … `10015fb4 or
///    r3,r19,r19; bl FUN_10042ee0`): the sum (one −360 when > 359) is both the rotation angle and the request
///    heading (bank correction for B1; the bank says the rotation uses the facing alone). Heading supplied =
///    `SetHeading`; heading = that sum in the rotated `SetHeading` case, else `HeadingDegrees`
///    (`10016140..10016154`); owner = the spawner and its serial, player = +0xd8, stationary / terrain = the set's
///    options (`10016158..10016184`); `FUN_10033220(&req, 0, u)` (`10016188`) — its draws happen here, before the
///    next set's.
extension GameState {
    /// `FUN_10015b40` after its `FUN_10017150` call (see the type comment) for entity `i` at game time `now`.
    public mutating func runSpawnSets(_ i: Int, now: Int32) {
        guard world.entities[i].hasSpawnSets, let st = currentState(i) else { return }   // 10015b6c..10015b74
        let count = recordsOfCurrentState(i).count                            // 10015b78..10015bac
        var k = 0
        while k < count {                                                      // 10015bb0..10016198
            defer { k += 1 }
            let set = st.spawnSets[k]                                          // 10015bb8..10015bc4
            let s = Int(world.entities[i].state)                               // 10015bc8..10015be0
            var r = world.entities[i].spawnRecords[s][k]
            guard set.stateSpawnSetSpawn != .none, r.active, r.rate >= 0 else { continue }   // 10015be8..10015c10
            if world.entities[i].fleeing && !set.stateSpawnSetSpawnIfFleeing { continue }    // 10015c14..10015c28
            if set.stateSpawnSetDontSpawnOffscreen, r.remaining > 0, r.remaining >= r.volley,
               !isOnScreen(i) {                                                // 10015c2c..10015c60
                r.remaining = 0                                                // 10015c64..10015c68
                world.entities[i].spawnRecords[s][k] = r
                continue
            }
            var issue = false
            if r.remaining > 0 {                                               // 10015c70..10015c7c
                if r.countdown > 0 { r.countdown &-= 1 }                       // 10015c80..10015c90
                if r.countdown > 0 {                                           // 10015c94..10015c9c
                    world.entities[i].spawnRecords[s][k] = r
                    continue
                }
                r.remaining &-= 1                                              // 10015ca0..10015cac
                issue = true
                r.countdown = rng.range(set.stateSpawnSetDelayBetweenEntitiesMin,
                                        set.stateSpawnSetDelayBetweenEntitiesMax)   // 10015cb0..10015cc0
            } else {
                if !set.stateSpawnSetRepeatSpawns {                            // 10015cc8..10015cdc
                    r.active = false
                    world.entities[i].spawnRecords[s][k] = r
                    continue
                }
                if now < r.lastArm &+ r.rate {                                 // 10015ce0..10015cf0
                    continue
                }
                r.lastArm = now                                                // 10015cf4
                r.countdown = rng.range(set.stateSpawnSetDelayBetweenEntitiesMin,
                                        set.stateSpawnSetDelayBetweenEntitiesMax)   // 10015cf8..10015d08
                r.volley = rng.range(set.stateSpawnSetNumInVolleyMin, set.stateSpawnSetNumInVolleyMax)   // 10015d0c..10015d1c
                r.remaining = r.volley                                         // 10015d20..10015d24
                r.rate = rng.range(set.stateSpawnSetRateMin, set.stateSpawnSetRateMax)   // 10015d28..10015d38
                if set.stateSpawnSetPauseAnyRotationWhileSpawning,
                   set.stateSpawnSetTimeToPauseRotationAfterSpawning > world.entities[i].rotationPause {   // 10015d3c..10015d54
                    world.entities[i].rotationPause = set.stateSpawnSetTimeToPauseRotationAfterSpawning   // 10015d58
                }
            }
            world.entities[i].spawnRecords[s][k] = r
            if issue { issueSpawnSetRequest(i, set: set) }                     // 10015d5c..10016188
        }
    }

    /// The current state's spawn-record list (`+0x19c + 4·state`; empty outside the slots).
    private func recordsOfCurrentState(_ i: Int) -> [SpawnRecord] {
        let s = Int(world.entities[i].state)
        return world.entities[i].spawnRecords.indices.contains(s) ? world.entities[i].spawnRecords[s] : []
    }

    /// The request of `FUN_10015b40` (`10015d64..10016188`, see the type comment).
    private mutating func issueSpawnSetRequest(_ i: Int, set: SpawnSet) {
        let id = set.stateSpawnSetSpawn
        guard id != .none else { return }                                      // 10015d64..10015d70 (kept: the listing re-tests it; unreachable after step 1)
        let ui = assets.unitIndex[id]                                          // 10015d74..10015d84 FUN_1003d550
        let u = ui.map { assets.definitions.units[$0] }
        if let u, u.terrainEffect {                                            // 10015d88..10015d94
            if world.entities[i].stationary { return }                         // 10015d98..10015da0
            if !world.entities[i].terrainEffects { return }                    // 10015da4..10015dac
        }
        let e = world.entities[i]
        var req = SpawnRequest.template                                        // 10015db0..10015e0c
        req.unit = id                                                          // 10015e10..10015e14
        let xo = Float(set.stateSpawnSetXOffset), yo = Float(set.stateSpawnSetYOffset)   // magic − magic, fsubs
        let s = e.object.scale                                                 // +0x84
        let scaled = Float(1) != s && (u?.adjustInitialLocForOwnerScale ?? false)   // 10015e40..10015e64 / 10015fd0..10015ff4
        var headingFromRotation = false
        if !set.stateSpawnSetAdjustOffsetForUnitRotation {                     // 10015e18..10015e20
            if !set.stateSpawnSetAbsoluteCoordinates {                         // 10015e24..10015e3c
                req.x = e.object.x; req.y = e.object.y
            }
            if scaled {                                                        // 10015e68..10015ec4
                let ys: Float = yo * s, xs: Float = xo * s
                req.y = req.y + ys
                req.x = req.x + xs
            }
            if set.stateSpawnSetAbsoluteCoordinates {                          // 10015ec8..10015ed0, 10015f34..10015f74
                req.x = xo; req.y = yo
            } else if !scaled {                                                // 10015ed4..10015f2c
                req.x = req.x + xo
                req.y = req.y + yo
            }
        } else {
            var h = facing(of: i)                                              // 10015f7c..10015f80 FUN_100161c0
            if set.stateSpawnSetSetHeading {                                   // 10015f88..10015fb0
                h = h &+ set.stateSpawnSetHeadingDegrees
                if h > 359 { h &-= 360 }
                req.heading = h
                headingFromRotation = true
            }
            let c = Trig.cos(h)                                                // 10015fb4..10015fc0 FUN_10042ee0
            let n = Trig.sin(h)                                                // 10015fc4..10015fc8 FUN_10042f00
            let xr: Float = scaled ? xo * s : xo                               // 10016030..10016044 / 100160a4..100160d4
            let yr: Float = scaled ? yo * s : yo
            let yn: Float = yr * n                                             // 1001603c / 100160a8
            let yc: Float = yr * c                                             // 10016040 / 100160bc
            let dx = EntityDraw.fctiwz((-yn).addingProduct(xr, c))             // 10016048 / 100160d0 fmsubs; fctiwz
            let dy = EntityDraw.fctiwz(yc.addingProduct(xr, n))                // 1001604c / 100160dc fmadds; fctiwz
            req.x = e.object.x + Float(dx)                                     // 100160f4..10016130
            req.y = e.object.y + Float(dy)                                     // 10016134..1001613c
        }
        req.headingSupplied = set.stateSpawnSetSetHeading                      // 10016140..10016148
        if !headingFromRotation { req.heading = set.stateSpawnSetHeadingDegrees }   // 1001614c..10016154
        req.owner = i                                                          // 10016158
        req.ownerSerial = e.serial                                             // 10016164..1001616c
        req.player = e.ownerPlayer                                             // 10016170..10016174
        req.stationary = set.stateSpawnSetStationaryOption                     // 10016178..1001617c
        req.terrainEffects = set.stateSpawnSetTerrainEffectsOption             // 10016180..10016184
        spawn(req, unit: ui)                                                   // 10016188 FUN_10033220(&req, 0, u)
    }
}

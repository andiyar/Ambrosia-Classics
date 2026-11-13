import Foundation
import HectorResources

/// Fire timing, the bomb salvo and the launchers (weapons-projectiles.md §2.4, §2.7, §3.2; loose-ends-combat §6.6;
/// plan C15). The handler never draws from the RNG itself; every launch is a `spawn` (its creation draws, in
/// request order).
///
/// Listing reads (`disasm-review3-all.txt`):
/// - `FUN_1003bf80(h, now) @ 1003bf80` (`1003bf80..1003bfe0`): now > +0x5c + `delayBetweenLaunches` (`cmpw; ble`)
///   and (`autoRepeat` or fire air was up last tick, +0x0a) → +0x68 + 1, +0x5c = +0x60 = now, return 1.
/// - `FUN_1003bff0(h, now) @ 1003bff0` (`1003c00c..1003c0b8`): the same rule per aux record (record +0x04, the
///   record weapon's delay / autoRepeat, the handler's +0x0a); each passing record: +0x10 + 1, +0x04 = +0x08 = now;
///   returns any-fired.
/// - `FUN_1003beb0(h, now) @ 1003beb0` (`1003bed0..1003bf5c`): now > +0x78 + `delayBetweenLaunches` → n = sector
///   (`FUN_10005cd0`) + trunc(flli 151) − 1 → +0x84; > trunc(flli 152) → that; +0x84 − 1, +0x78 = +0x7c = now,
///   return 1; else 0.
/// - `FUN_1003c4f0(h, player) @ 1003c4f0` (ground, `1003c510..1003c79c`): per spawn record of +0x74 with unit ≠
///   none: x = player x + (float)XLoc, y = player y + (float)YLoc (`fadds`), +0x0d = SetHeading, +0x10 = Angle,
///   +0x14 = +0x122, crosshair position `FUN_100128d0(h+0x8c)`, +0x28 = (float)max(0, trunc(h.y − crosshair.y)) /
///   (float)abs(crosshairYOffset) (`fsubs; fctiwz` · `bl 0x1004ee30` · `fdivs`); `FUN_10033220(req, 0, 0)`. Then
///   `crosshairSpawnOnActivation_ID` ≠ none → a request at the crosshair position, owned.
/// - `FUN_1003c7a0(h, player) @ 1003c7a0` (air, `1003c7bc..1003c928`): only when +0x68 ≥ 1; per spawn record of
///   +0x58 likewise, speed multiplier left at the template's 1.0.
/// - `FUN_1003c940(h, player) @ 1003c940` (aux, `1003c960..1003cb14`): per aux record with +0x10 ≥ 1, its weapon's
///   spawn records likewise.
extension GameState {
    /// `FUN_1003bf80` — the air shot's timing; true = launch this tick.
    mutating func fireAirTiming(_ i: Int, now: Int32) -> Bool {
        let h = players[i].handler
        guard now > h.lastAirLaunch &+ h.air.delayBetweenLaunches else { return false }   // 1003bf88..1003bf98
        guard h.air.autoRepeat || !h.previousFireAir else { return false }  // 1003bf9c..1003bfc0
        players[i].handler.airLaunches &+= 1                                 // 1003bfc4..1003bfd0
        players[i].handler.lastAirLaunch = now                               // 1003bfd4 (+0x60 too, 1003bfd8)
        return true
    }

    /// `FUN_1003bff0` — the aux weapons' timing; true = some record fired.
    mutating func fireAuxTiming(_ i: Int, now: Int32) -> Bool {
        var fired = false
        let previous = players[i].handler.previousFireAir
        for k in players[i].handler.aux.indices {                            // 1003c03c..1003c0b4
            let r = players[i].handler.aux[k]
            guard now > r.lastLaunch &+ r.weapon.delayBetweenLaunches else { continue }   // 1003c050..1003c068
            guard r.weapon.autoRepeat || !previous else { continue }         // 1003c06c..1003c090
            players[i].handler.aux[k].count &+= 1                            // 1003c094..1003c0a0
            players[i].handler.aux[k].lastLaunch = now                       // 1003c0a4..1003c0a8
            fired = true                                                     // 1003c098
        }
        return fired
    }

    /// `FUN_1003beb0` — a new bomb salvo on a fresh fire-ground press; true = launch the first bomb now.
    mutating func startBombSalvo(_ i: Int, now: Int32) -> Bool {
        let h = players[i].handler
        guard now > h.lastSalvo &+ h.ground.delayBetweenLaunches else { return false }   // 1003bed0..1003bee8
        var n = flags.sector &+ EntityDraw.fctiwz(assets.floats[151]) &- 1   // 1003beec..1003bf1c
        let cap = EntityDraw.fctiwz(assets.floats[152])                      // 1003bf20..1003bf34
        if n > cap { n = cap }                                               // 1003bf38..1003bf40
        players[i].handler.bombsPending = n &- 1                             // 1003bf44..1003bf50
        players[i].handler.lastSalvo = now                                   // 1003bf54
        players[i].handler.lastBomb = now                                    // 1003bf58
        return true
    }

    /// One spawn record of a weapon as a request at the player (`1003c578..1003c64c` / `1003c838..1003c910`).
    private func launchRequest(_ i: Int, _ s: WeaponDefinition.Spawn) -> SpawnRequest {
        let o = players[i].object
        var req = weaponRequest(i, unit: s.unit, x: o.x + Float(s.xLoc), y: o.y + Float(s.yLoc))
        req.headingSupplied = s.setHeading                                   // +0x0d
        req.heading = s.angle                                                // +0x10
        return req
    }

    /// `FUN_1003c4f0` — the ground launcher (see the extension's comment).
    mutating func launchGround(_ i: Int) {
        let spawns = players[i].handler.ground.spawns                        // 1003c510..1003c528
        for s in spawns where s.unit != .none {                              // 1003c550..1003c574
            var req = launchRequest(i, s)
            let h = players[i].handler
            let cy = h.crosshair.y                                           // 1003c650 FUN_100128d0
            var d = EntityDraw.fctiwz(h.y - cy)                              // 1003c658..1003c66c
            if d < 0 { d = 0 }                                               // 1003c670..1003c678
            let yo = h.ground.crosshairYOffset                               // 1003c67c..1003c680
            let a = yo < 0 ? 0 &- yo : yo                                    // 1003c684 abs
            req.speedMultiplier = Float(d) / Float(a)                        // 1003c68c..1003c6d0
            spawn(req)                                                       // 1003c6d4
        }
        let c = players[i].handler.ground.crosshairSpawnOnActivation         // 1003c6e8..1003c6f8
        guard c != .none else { return }
        let x = players[i].handler.crosshair
        spawn(weaponRequest(i, unit: c, x: x.x, y: x.y))                     // 1003c6fc..1003c784
    }

    /// `FUN_1003c7a0` — the air launcher (see the extension's comment).
    mutating func launchAir(_ i: Int) {
        guard players[i].handler.airLaunches >= 1 else { return }            // 1003c7bc..1003c7c4
        let spawns = players[i].handler.air.spawns                           // 1003c7c8..1003c7e4
        for s in spawns where s.unit != .none {                              // 1003c810..1003c834
            spawn(launchRequest(i, s))                                       // 1003c838..1003c914
        }
    }

    /// `FUN_1003c940` — the aux launcher (see the extension's comment).
    mutating func launchAux(_ i: Int) {
        let records = players[i].handler.aux                                 // 1003c960..1003c98c
        for r in records where r.count >= 1 {                                // 1003c9a0..1003c9ac
            for s in r.weapon.spawns where s.unit != .none {                 // 1003c9f0..1003ca14
                spawn(launchRequest(i, s))                                   // 1003ca18..1003caf4
            }
        }
    }
}

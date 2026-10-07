import Foundation
import HectorResources

/// The power-up machines (weapons-projectiles.md §2.5, loose-ends-combat §6.1; plan C15): the air machine
/// `FUN_1003c0d0` and the ground copy inlined in `FUN_1003b3c0` (`1003b4f4..1003b8a4`). Neither draws from the RNG
/// itself; the activation and release spawns go through `spawn` (its creation draws, in call order).
///
/// Listing reads (`disasm-review3-all.txt`):
/// - `FUN_1003c0d0(h, now, player, def = h+0x58, &code) @ 1003c0d0` (`1003c0f8..1003c4d8`): both `ActivationSpawn_ID`
///   and `ReleaseSpawn_ID` `none` → nothing. State 0 (`1003c148..1003c22c`): held +0x2c ≥ `TimeUntilActivation`
///   (`cmpw; blt exit`) → held 0; activation ID ≠ none → a request from the weapon template `0x100ecd14` (r2+0x69e4)
///   at the player's x, y, +0x14 = +0x122, `FUN_10033220(req, out, 0)`, +0x18 = out serial (`1003c200..1003c204`);
///   then state 1, +0x14 = +0x1c = +0x28 = now, level 0, percent 0.0 (`r2−0x6e6c` → `0x100d72b0` {0.0, 100.0}).
///   State 1 (`1003c230..1003c358`): OverloadTime > 0 ∧ now > +0x14 + OverloadTime → code 1, state 2, +0x14 = now;
///   then only if still state 1: now > +0x1c + TBPLC → level + 1, percent (below), level > max (`cmpw; ble`) →
///   level = max, percent 100.0, DoRelease → state 3, +0x14 = now, `FUN_10034ce0(now, +0x18)`, code 2 (+0x1c
///   unchanged); else +0x1c = now. State 2 → nothing. State 3 (`1003c35c..1003c4d4`): level ≤ 0 → state 0, +0x14 =
///   now, level 0, percent 0.0, pending air applied (`FUN_1003b180(h, 'PEAA', +0x50)`, +0x50 = 0); else now >
///   +0x28 + TBRS → a request for `ReleaseSpawn_ID` at the player, +0x28 = now, level − 1, percent. State ≥ 4 →
///   nothing.
/// - Percent (`1003c280..1003c300`): `fdivs` (float)level / (float)max in single, `fmul` by the double 100.0
///   (`0x100d72b8`), `frsp`; stored, reloaded, then < 1.0 (double, `0x100d72c0`) → 0.0, > 100.0 → 100.0.
/// - The ground copy (`1003b4f4..1003b8a4`) runs when either ground ID ≠ none, on +0x31…+0x4c and the
///   `#powerup_Ground_*` block; it has **no overload test** (+0x1f8 is never read) and **never sets the code**.
extension GameState {
    /// The percent of `FUN_1003c0d0` (`1003c280..1003c300`), clamped: < 1.0 → 0.0, > 100.0 → 100.0.
    static func powerPercent(level: Int32, max: Int32) -> Float {
        let q: Float = Float(level) / Float(max)                             // fsubs ×2 (exact), fdivs
        var p = Float(100.0 * Double(q))                                     // fmul f4 (double 100.0), frsp
        if p < 1.0 { p = 0 } else if p > 100.0 { p = 100 }                   // fcmpo 1.0 / 100.0
        return p
    }

    /// A weapon-template request (`0x100ecd14`, runtime +0x24 = −1) for `unit` at (x, y), owned by the handler's
    /// player (+0x14 = handler +0x122).
    func weaponRequest(_ i: Int, unit: FourCC, x: Float, y: Float) -> SpawnRequest {
        var req = SpawnRequest(unit: unit, x: x, y: y)
        req.player = players[i].handler.owner
        return req
    }

    /// `FUN_1003c0d0 @ 1003c0d0` — the air power-up / overload machine for player `i`'s current air weapon (see the
    /// extension's comment). Writes 1 (overload) or 2 (released at max) into `code`.
    mutating func airPowerUp(_ i: Int, now: Int32, code: inout UInt8) {
        let w = players[i].handler.air                                       // r6 = h+0x58 at the call
        let pu = w.powerupAir
        guard pu.activationSpawn != .none || pu.releaseSpawn != .none else { return }   // 1003c0f8..1003c118
        switch players[i].handler.airPower.state {                           // 1003c11c..1003c144
        case 0:
            guard players[i].handler.airPower.held >= pu.timeUntilActivation else { return }   // 1003c148..1003c154
            players[i].handler.airPower.held = 0                             // 1003c158..1003c15c
            if pu.activationSpawn != .none {                                 // 1003c160..1003c16c
                let o = players[i].object
                let out = spawn(weaponRequest(i, unit: pu.activationSpawn, x: o.x, y: o.y))   // 1003c170..1003c1f8
                // The out-parameter is an uninitialised local when nothing was created; −1 matches no serial.
                players[i].handler.airPower.serial = out?.serial ?? -1      // 1003c200..1003c204
            }
            var a = players[i].handler.airPower
            a.state = 1                                                      // 1003c208..1003c210
            a.start = now                                                    // 1003c218
            a.lastStep = now                                                 // 1003c21c
            a.level = 0                                                      // 1003c220
            a.lastRelease = now                                              // 1003c224
            a.percent = 0                                                    // 1003c228
            players[i].handler.airPower = a
        case 1:
            var a = players[i].handler.airPower
            if pu.overloadTime > 0 && now > a.start &+ pu.overloadTime {    // 1003c230..1003c248
                code = 1                                                     // 1003c24c..1003c250
                a.state = 2                                                  // 1003c254..1003c258
                a.start = now                                                // 1003c25c
            }
            guard a.state == 1, now > a.lastStep &+ pu.timeBetweenPowerLevelChanges else {   // 1003c260..1003c27c
                players[i].handler.airPower = a
                return
            }
            a.level &+= 1                                                    // 1003c280..1003c294
            a.percent = Self.powerPercent(level: a.level, max: pu.maxPowerLevel)   // 1003c298..1003c300
            if a.level > pu.maxPowerLevel {                                  // 1003c304..1003c310
                a.level = pu.maxPowerLevel                                   // 1003c314
                a.percent = 100                                              // 1003c318..1003c31c
                if pu.doReleaseOnMaxPowerLevel {                             // 1003c320..1003c328
                    a.state = 3                                              // 1003c32c..1003c330
                    a.start = now                                            // 1003c338
                    players[i].handler.airPower = a
                    releasePowerup(serial: a.serial, now: now)               // 1003c33c..1003c340 FUN_10034ce0
                    code = 2                                                 // 1003c348..1003c34c
                    return
                }
            } else {
                a.lastStep = now                                             // 1003c354
            }
            players[i].handler.airPower = a
        case 3:
            if players[i].handler.airPower.level <= 0 {                      // 1003c35c..1003c364
                var a = players[i].handler.airPower
                a.state = 0                                                  // 1003c49c..1003c4a4
                a.start = now                                                // 1003c4a8
                a.level = 0                                                  // 1003c4ac
                a.percent = 0                                                // 1003c4b0
                players[i].handler.airPower = a
                if let p = players[i].handler.pendingAir {                   // 1003c4b4..1003c4bc
                    players[i].handler.switchWeapon(type: FourCC("PEAA")!, to: p)   // 1003c4cc
                    players[i].handler.pendingAir = nil                      // 1003c4d0..1003c4d4
                }
            } else if now > players[i].handler.airPower.lastRelease &+ pu.timeBetweenReleaseSpawns {   // 1003c368..1003c378
                let o = players[i].object
                spawn(weaponRequest(i, unit: pu.releaseSpawn, x: o.x, y: o.y))   // 1003c37c..1003c408
                var a = players[i].handler.airPower
                a.lastRelease = now                                          // 1003c410
                a.level &-= 1                                                // 1003c41c..1003c42c
                a.percent = Self.powerPercent(level: a.level, max: pu.maxPowerLevel)   // 1003c430..1003c494
                players[i].handler.airPower = a
            }
        default:
            break                                                            // 2 (overloaded), ≥ 4
        }
    }

    /// The ground power-up, inlined in `FUN_1003b3c0` (`1003b4f4..1003b8a4`): the air machine on +0x31…+0x4c and
    /// `#powerup_Ground_*`, run when either ground ID ≠ none, with no overload test and no return code.
    /// Unreachable with shipped data (Plasma Bomb has both IDs `none`).
    mutating func groundPowerUp(_ i: Int, now: Int32) {
        let pu = players[i].handler.ground.powerupGround                     // 1003b4f4
        guard pu.activationSpawn != .none || pu.releaseSpawn != .none else { return }   // 1003b4f8..1003b514
        switch players[i].handler.groundPower.state {                        // 1003b518..1003b540
        case 0:
            guard players[i].handler.groundPower.held >= pu.timeUntilActivation else { return }   // 1003b544..1003b550
            players[i].handler.groundPower.held = 0                          // 1003b554..1003b558
            if pu.activationSpawn != .none {                                 // 1003b55c..1003b56c
                let o = players[i].object
                let out = spawn(weaponRequest(i, unit: pu.activationSpawn, x: o.x, y: o.y))   // 1003b570..1003b5f8
                players[i].handler.groundPower.serial = out?.serial ?? -1   // 1003b600..1003b604
            }
            var g = players[i].handler.groundPower
            g.state = 1                                                      // 1003b608..1003b610
            g.start = now                                                    // 1003b618
            g.lastStep = now                                                 // 1003b61c
            g.level = 0                                                      // 1003b620
            g.lastRelease = now                                              // 1003b624
            g.percent = 0                                                    // 1003b628
            players[i].handler.groundPower = g
        case 1:
            var g = players[i].handler.groundPower
            guard now > g.lastStep &+ pu.timeBetweenPowerLevelChanges else { return }   // 1003b630..1003b640
            g.level &+= 1                                                    // 1003b644..1003b658
            g.percent = Self.powerPercent(level: g.level, max: pu.maxPowerLevel)   // 1003b65c..1003b6c8
            if g.level > pu.maxPowerLevel {                                  // 1003b6cc..1003b6dc
                g.level = pu.maxPowerLevel                                   // 1003b6e0
                g.percent = 100                                              // 1003b6e4..1003b6e8
                if pu.doReleaseOnMaxPowerLevel {                             // 1003b6ec..1003b6f8
                    g.state = 3                                              // 1003b6fc..1003b700
                    g.start = now                                            // 1003b708
                    players[i].handler.groundPower = g
                    releasePowerup(serial: g.serial, now: now)               // 1003b70c..1003b710 FUN_10034ce0
                    return
                }
            } else {
                g.lastStep = now                                             // 1003b71c
            }
            players[i].handler.groundPower = g
        case 3:
            if players[i].handler.groundPower.level <= 0 {                   // 1003b724..1003b72c
                var g = players[i].handler.groundPower
                g.state = 0                                                  // 1003b86c..1003b874
                g.start = now                                                // 1003b878
                g.level = 0                                                  // 1003b87c
                g.percent = 0                                                // 1003b880
                players[i].handler.groundPower = g
                if let p = players[i].handler.pendingGround {                // 1003b884..1003b88c
                    players[i].handler.switchWeapon(type: FourCC("PEAG")!, to: p)   // 1003b89c
                    players[i].handler.pendingGround = nil                   // 1003b8a0..1003b8a4
                }
            } else if now > players[i].handler.groundPower.lastRelease &+ pu.timeBetweenReleaseSpawns {   // 1003b730..1003b740
                let o = players[i].object
                spawn(weaponRequest(i, unit: pu.releaseSpawn, x: o.x, y: o.y))   // 1003b744..1003b7d4
                var g = players[i].handler.groundPower
                g.lastRelease = now                                          // 1003b7dc
                g.level &-= 1                                                // 1003b7e8..1003b7f8
                g.percent = Self.powerPercent(level: g.level, max: pu.maxPowerLevel)   // 1003b7fc..1003b864
                players[i].handler.groundPower = g
            }
        default:
            break                                                            // 2, ≥ 4
        }
    }
}

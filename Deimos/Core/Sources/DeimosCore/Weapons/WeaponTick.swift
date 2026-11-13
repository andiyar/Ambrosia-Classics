import Foundation
import HectorResources

/// The weapon handler tick `FUN_1003b3c0(h, player, fireGround +0x200, fireAir +0x201, select +0x202, now,
/// &switched) @ 1003b3c0`, called by the player update in state 4 when `+0x84 == 1.0` (`100290d0..100290fc`)
/// (weapons-projectiles.md §2.3, loose-ends-combat §6.1; plan C15 — replaces C14's stub).
///
/// Listing read (`disasm-review3-all.txt` `1003b3c0..1003baa0`), in order:
/// 1. held counters: +0x2c = fire air ? +0x2c + 1 : 0; +0x4c likewise on fire ground (`1003b404..1003b448`);
/// 2. release: fire air up and air state ∈ {1, 2} → state 3, +0x14 = now, `FUN_10034ce0(now, +0x18)`, code 2; the
///    same on the ground block (`1003b44c..1003b4c8`);
/// 3. the air weapon's `autoRepeat` == 0 → `FUN_1003c0d0` (`1003b4cc..1003b4f0`; PowerUp.swift);
/// 4. the ground power-up copy (`1003b4f4..1003b8a4`; PowerUp.swift);
/// 5. select on its rising edge (`select ∧ ¬+0x0b`): `FUN_1002adb0('PEAA', +0x58 id, sector)` → if found
///    `FUN_1003b180(h, 'PEAA', next)`; then always +0x08 = 1, switched = 1, `FUN_10047670(gaso 18, 0x4b, 100, 1)`
///    (`1003b8a8..1003b924`). Otherwise fire air ∧ air state 0 → `FUN_1003bf80` (air) and `FUN_1003bff0` (aux)
///    (`1003b928..1003b960`) — a select press suppresses the air shot;
/// 6. bombs: a salvo running (+0x84 > 0) → when now > +0x7c + `delayBetweenLoadLaunches`: +0x84 − 1, launch,
///    +0x7c = +0x78 = now; else fire ground ∧ ¬+0x09 ∧ ground state 0 → `FUN_1003beb0` (`1003b964..1003b9d0`);
/// 7. +0x09/+0x0a/+0x0b = this tick's buttons (`1003b9d4..1003b9e8`); crosshair: +0x120 = 1, face/frame ← the ground
///    weapon's +0x168/+0x16c, +0x121 = 0, crosshair +0x38 = 0, `FUN_10012940` on it, its `FUN_10012750` unless its
///    face is `none` (`1003b9ec..1003ba30`);
/// 8. launch ground `FUN_1003c4f0`, air `FUN_1003c7a0`, aux `FUN_1003c940` (`1003ba34..1003ba78`), then
///    `FUN_1003bab0(h, 0)` (`1003ba7c..1003ba84`); return the code byte (`1003ba8c`).
/// The switched flag is consumed by the player update right after the call (`10029104..10029118`, `FUN_10029f60`);
/// here the tick calls `refreshFaceFromWeapon` itself before returning (nothing runs in between).
extension GameState {
    /// One handler tick of player `i` (see the extension's comment). Returns 0, 1 (overload begins — the player
    /// starts its warning) or 2 (power-up released — the warning is cancelled).
    mutating func tickWeapons(_ i: Int, input: PlayerInput) -> Int {
        let now = flags.gameTime
        let fireGround = input.contains(.fireGround)                         // r24
        let fireAir = input.contains(.fireAir)                               // r25
        let select = input.contains(.select)                                 // r26
        var code: UInt8 = 0                                                  // 1003b40c
        var switched = false                                                 // 1003b410

        // 1. Held counters.
        players[i].handler.airPower.held = fireAir ? players[i].handler.airPower.held &+ 1 : 0          // 1003b404..1003b428
        players[i].handler.groundPower.held = fireGround ? players[i].handler.groundPower.held &+ 1 : 0 // 1003b42c..1003b448

        // 2. Release.
        if !fireAir, players[i].handler.airPower.state == 1 || players[i].handler.airPower.state == 2 {  // 1003b44c..1003b464
            players[i].handler.airPower.state = 3                            // 1003b468..1003b46c
            players[i].handler.airPower.start = now                          // 1003b474
            releasePowerup(serial: players[i].handler.airPower.serial, now: now)   // 1003b478..1003b47c
            code = 2                                                         // 1003b484..1003b488
        }
        if !fireGround, players[i].handler.groundPower.state == 1 || players[i].handler.groundPower.state == 2 {   // 1003b48c..1003b4a4
            players[i].handler.groundPower.state = 3                         // 1003b4a8..1003b4ac
            players[i].handler.groundPower.start = now                       // 1003b4b4
            releasePowerup(serial: players[i].handler.groundPower.serial, now: now)   // 1003b4b8..1003b4bc
            code = 2                                                         // 1003b4c4..1003b4c8
        }

        // 3–4. The power-up machines.
        if !players[i].handler.air.autoRepeat {                              // 1003b4cc..1003b4d8
            airPowerUp(i, now: now, code: &code)                             // 1003b4ec FUN_1003c0d0
        }
        groundPowerUp(i, now: now)                                           // 1003b4f4..1003b8a4

        // 5. Select, else the air shot.
        var launchGroundNow = false, launchAirNow = false, launchAuxNow = false   // r31, r30, r29
        if select && !players[i].handler.previousSelect {                    // 1003b8a8..1003b8b8
            let cur = players[i].handler.air                                 // 1003b8bc
            if let next = Player.nextWeapon(type: FourCC("PEAA")!, after: cur.id, sector: flags.sector,
                                            weapons: assets.definitions.weapons) {   // 1003b8c0..1003b8e4 FUN_1002adb0
                players[i].handler.switchWeapon(type: FourCC("PEAA")!, to: next)   // 1003b8e8..1003b8f4
            }
            players[i].handler.iconsDirty = true                             // 1003b8f8..1003b8fc
            switched = true                                                  // 1003b904
            cues.sounds.append(SoundPlay.perm(assets.sounds[0x12], priority: 0x4b, volume: 100,
                                              allowMultiple: true))          // 1003b900..1003b91c
        } else if fireAir && players[i].handler.airPower.state == 0 {        // 1003b928..1003b938
            launchAirNow = fireAirTiming(i, now: now)                        // 1003b944 FUN_1003bf80
            launchAuxNow = fireAuxTiming(i, now: now)                        // 1003b958 FUN_1003bff0
        }

        // 6. Bombs.
        if players[i].handler.bombsPending > 0 {                             // 1003b964..1003b96c
            let h = players[i].handler
            if now > h.lastBomb &+ h.ground.delayBetweenLoadLaunches {       // 1003b970..1003b984
                players[i].handler.bombsPending = h.bombsPending &- 1        // 1003b988..1003b98c
                launchGroundNow = true                                       // 1003b990
                players[i].handler.lastBomb = now                            // 1003b994
                players[i].handler.lastSalvo = now                           // 1003b998
            }
        } else if fireGround && !players[i].handler.previousFireGround
                    && players[i].handler.groundPower.state == 0 {           // 1003b9a0..1003b9bc
            launchGroundNow = startBombSalvo(i, now: now)                    // 1003b9c8 FUN_1003beb0
        }

        // 7. The previous-button bytes and the crosshair.
        players[i].handler.previousFireGround = fireGround                   // 1003b9d4
        players[i].handler.previousFireAir = fireAir                         // 1003b9e0
        players[i].handler.previousSelect = select                           // 1003b9e8
        players[i].handler.crosshairShown = true                             // 1003b9ec
        players[i].handler.crosshair.face = players[i].handler.ground.crosshairFace   // 1003b9f0..1003b9f8
        players[i].handler.crosshair.frame = players[i].handler.ground.crosshairFrame // 1003b9fc..1003ba04
        players[i].handler.crosshairLocked = false                           // 1003ba08
        players[i].handler.crosshair.drawShadow = false                      // 1003ba0c
        let a = assets
        players[i].handler.crosshair.refreshSize { Player.frameSize(a, $0, $1, $2) }   // 1003ba10
        if players[i].handler.crosshair.face != .none {                      // 1003ba18..1003ba24
            players[i].handler.crosshair.stepRamps()                         // 1003ba2c
        }

        // 8. Launch, then the crosshair back to unlocked.
        if launchGroundNow { launchGround(i) }                               // 1003ba34..1003ba44 FUN_1003c4f0
        if launchAirNow { launchAir(i) }                                     // 1003ba4c..1003ba5c FUN_1003c7a0
        if launchAuxNow { launchAux(i) }                                     // 1003ba64..1003ba74 FUN_1003c940
        players[i].handler.setCrosshairLock(false)                           // 1003ba7c..1003ba84 FUN_1003bab0(h, 0)
        if switched { players[i].refreshFaceFromWeapon() }                   // 10029104..10029118 FUN_10029f60
        return Int(code)                                                     // 1003ba8c
    }
}

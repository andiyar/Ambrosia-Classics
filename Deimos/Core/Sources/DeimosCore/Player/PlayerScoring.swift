import Foundation
import HectorResources

/// Score, lives, multiplier, money and shield pickups (scoring-bonuses.md §3–§5, player-physics.md §6.1, §7,
/// loose-ends-combat.md §3.2; plan C14). The obfuscated stores (score +0x5532a3e, lives +0x1524dcef, money
/// +0xb2cce) are integer and lossless, kept plain on `Player`; 32-bit wrapping arithmetic throughout.
///
/// Listing reads (`disasm-review3-all.txt`): `FUN_10029a10` (`10029a28..10029af8`), `FUN_10026d70`
/// (`10026d84..10026e80`), `FUN_10029b20` (`10029b2c..10029bb0`, jump table `r2+0x3090` = `0x100e93c0` read from
/// `mem/100de330.bin`: 1→2, 2→3, 3→4, 4→5, 5→10, 0 and 6…10 → unchanged), `FUN_10029fe0` (`10029ff4..1002a138`,
/// table `r2+0x30bc` = `0x100e93ec`: 2/3/4/5/10 → PermObjectID 35/36/37/38/39, every other value → `none`),
/// `FUN_100275b0` (`100275cc..100275e8`), `FUN_10027490` (`100274bc..1002750c`), the defence bonus in
/// `FUN_10028170` (`10028f3c..10029034`).
extension GameState {
    /// `FUN_10029a10 @ 10029a10(p, pts, raw)` — the only score adder. Not in game → nothing; add = raw ? pts : pts
    /// × multiplier; pts > 0: not raw and new > threshold (strict) → `addLife(p, fx 1)`, threshold +=
    /// `life_AdditionalRequiredScore`, threshold += step, step += trunc(flli 182); raw → step = new + trunc(flli 182).
    /// Then score = new (negative adds included; no clamp).
    public mutating func addScore(_ i: Int, _ pts: Int32, raw: Bool = false) {
        guard players[i].inGame else { return }                              // 10029a28..10029a30
        var new = players[i].score                                           // 10029a34..10029a40
        new = raw ? new &+ pts : new &+ pts &* Int32(players[i].multiplier)  // 10029a44..10029a58
        if pts > 0 {                                                         // 10029a5c..10029a60
            let adjust = EntityDraw.fctiwz(assets.floats[182])
            if !raw {
                if new > players[i].extraLifeThreshold {                     // 10029a6c..10029a74
                    addLife(i, showEffects: true)                            // 10029a78..10029a80
                    players[i].extraLifeThreshold &+= players[i].definition.lifeAdditionalRequiredScore   // 10029a84..10029a98
                    players[i].extraLifeThreshold &+= players[i].extraLifeStep   // 10029a9c..10029aa8
                    players[i].extraLifeStep &+= adjust                      // 10029aac..10029ac8
                }
            } else {
                players[i].extraLifeStep = new &+ adjust                     // 10029ad0..10029aec
            }
        }
        players[i].score = new                                               // 10029af0..10029af8
    }

    /// `FUN_10026d70 @ 10026d70(p, fx)` — one life: in game only; new = lives + 1, capped at `life_MaxNum` when that
    /// is > 0; new > lives → (`life_Spawn_ID` ≠ none and fx → the request at the ship, owned) and lives = new.
    public mutating func addLife(_ i: Int, showEffects: Bool) {
        guard players[i].inGame else { return }                              // 10026d84..10026d8c
        let d = players[i].definition
        let lives = players[i].lives
        var new = lives &+ 1                                                 // 10026d94..10026da8
        if d.lifeMaxNum > 0 && new > d.lifeMaxNum { new = d.lifeMaxNum }     // 10026da0..10026db8
        guard new > lives else { return }                                    // 10026dbc..10026dc0
        if showEffects { spawnAtPlayer(i, d.lifeSpawn, owned: true) }        // 10026dc4..10026e70
        players[i].lives = new                                               // 10026e78..10026e80
    }

    /// `FUN_10029b20 @ 10029b20(p)` — the multiplier step (the `mult` pickup, cheats): state 4 only; 1→2→3→4→5→10,
    /// each followed by `FUN_10029fe0`; 10 (and any other value) stays, with no indicator call.
    public mutating func stepMultiplier(_ i: Int) {
        guard players[i].lifeState == 4 else { return }                      // 10029b2c..10029b34
        let next: UInt8
        switch players[i].multiplier {                                       // 10029b38..10029b54 (0x100e93c0)
        case 1: next = 2
        case 2: next = 3
        case 3: next = 4
        case 4: next = 5
        case 5: next = 10
        default: return
        }
        players[i].multiplier = next                                         // 10029b58..10029bac
        showMultiplierIndicator(i)                                           // 10029b60..10029bb0
    }

    /// `FUN_10029fe0 @ 10029fe0(p)` — the multiplier indicator: state 4 only; the multiplier's PermObjectID (2/3/4/5/10
    /// → 35…39 = `mux2 mux3 mux4 mux5 muxx`; else `none` → nothing); the previous indicator removed by serial
    /// (`FUN_10034de0(+0xb8)`); a request at the ship owned by the player; `+0xb8` = the out-parameter's serial.
    /// When the request creates nothing the original stores an uninitialised stack word (`1002a134` reads
    /// `r1+0x3c`, which `FUN_10033220` writes only on success); here −1 — a disclosed divergence (the stack word is
    /// unknowable; −1 matches no serial, so the next `FUN_10034de0` removes nothing, as a stale serial would not either
    /// unless it happened to equal a live one).
    mutating func showMultiplierIndicator(_ i: Int) {
        guard players[i].lifeState == 4 else { return }                      // 10029ff4..10029ffc
        let perm: Int
        switch players[i].multiplier {                                       // 1002a000..1002a084 (0x100e93ec)
        case 2: perm = 35
        case 3: perm = 36
        case 4: perm = 37
        case 5: perm = 38
        case 10: perm = 39
        default: return
        }
        let unit = assets.objects.indices.contains(perm) ? assets.objects[perm] : .none   // FUN_100201f0
        guard unit != .none else { return }                                  // 1002a088..1002a090
        removeEntity(serial: players[i].multiplierIndicator)                 // 1002a094..1002a098 FUN_10034de0
        let out = spawnAtPlayer(i, unit, owned: true)                        // 1002a0a0..1002a12c
        players[i].multiplierIndicator = out?.serial ?? -1                   // 1002a134..1002a138
    }

    /// `FUN_100275b0(p, v)` — money += v, in game only.
    public mutating func addMoney(_ i: Int, _ v: Int32) {
        guard players[i].inGame else { return }                              // 100275cc..100275d4
        players[i].money &+= v                                               // 100275d8..100275e8
    }

    /// `FUN_10027490(p, delta)` — shield = clamp(shield + delta, 0.0, 100.0) (`fadds`); in game and delta ≠ 0.0 only.
    public mutating func addShield(_ i: Int, _ delta: Float) {
        guard players[i].inGame, delta != 0 else { return }                  // 100274bc..100274d4
        var v: Float = players[i].shield + delta                             // 100274d8..100274e0
        if v > 100 { v = 100 } else if v < 0 { v = 0 }                       // 100274e4..10027504
        players[i].shield = v                                                // 1002750c
    }

    /// The defence bonus (player-physics §6.1, scoring-bonuses §6.1; `10028f50..10029034`), run by the update when
    /// G+0x39 is set and `+0xd0` is clear: `+0xd0` = 1; `active_DefenceBonusObject_ID` at the ship (owned) unless
    /// `none`; `addScore(trunc(flli 184) × sector, raw 0)` — so × multiplier too.
    mutating func payDefenceBonus(_ i: Int) {
        players[i].hitThisLevel = true                                       // 10028f50..10028f54
        spawnAtPlayer(i, players[i].definition.activeDefenceBonusObject, owned: true)   // 10028f58..10028ff8
        let base = EntityDraw.fctiwz(assets.floats[184])                     // 1002900c..10029028
        addScore(i, base &* flags.sector)                                    // 10029000..10029030 (FUN_10005cd0)
    }
}

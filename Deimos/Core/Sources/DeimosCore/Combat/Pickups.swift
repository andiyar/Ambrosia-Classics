import Foundation
import HectorResources

/// The pickup switch (damage-health-death.md §6, loose-ends-combat.md §3.1–§3.2, scoring-bonuses.md §3.3, §4, §5.1;
/// HIGH; plan C11a). Listing read: `FUN_10037580` (`10037580..100376f0`) — a binary compare tree on
/// `pickup_Type_ID` (unit +0x4d4); r31 = 1 on entry is the return value (1 = consumed).
extension GameState {
    /// `FUN_10037580(player, e) @ 10037580` — player slot `p` touches pickup entity `i`: the unit's
    /// `pickup_Type_ID` (+0x4d4) and `pickup_Value_INT` (+0x4dc) through `applyPickup`. The caller destroys a
    /// consumed pickup and marks it collected (`collideWithPlayers`).
    public mutating func collectPickup(player p: Int, entity i: Int) -> Bool {
        let u = assets.definitions.units[world.entities[i].unit]            // 1003759c..100375a8
        return applyPickup(player: p, type: u.pickupType, value: u.pickupValue)
    }

    /// The switch body of `FUN_10037580` for one type and value:
    /// - `grnd` / `air ` → 0 when the player is invulnerable (+0xce, `FUN_10027dd0`), else 1; no other effect
    ///   (`10037630..1003765c`);
    /// - `coin` → value ≠ 0: `addMoney` (`FUN_100275b0`) then the ship's hit glow 0x7fff, step 6, not forced
    ///   (`FUN_10012bc0`) (`10037660..1003768c`);
    /// - `exli` → `addLife(p, fx 1)` (`FUN_10026d70`, `1003769c..100376a8`);
    /// - `mult` → `stepMultiplier` (`FUN_10029b20`, `10037690..10037698`);
    /// - `shie` → `addShield(p, (float)value)` (int → float via the magic, `fsubs`; `FUN_10027490`, `100376ac..100376d0`);
    /// - `spec` and every other type → nothing (`1003761c..1003762c`, `100376d8`).
    public mutating func applyPickup(player p: Int, type: FourCC, value: Int32) -> Bool {
        switch type {
        case FourCC("grnd")!, FourCC("air ")!:                              // 100375a0..100375b0, 100375cc..100375d8
            return !players[p].invulnerable                                  // 10037630..10037658 FUN_10027dd0
        case FourCC("coin")!:                                                // 100375b8..100375c4
            if value != 0 {                                                  // 10037660..10037668
                addMoney(p, value)                                           // 1003766c FUN_100275b0
                players[p].object.startHitGlow(colour: 0x7fff, step: 6, force: false)   // 10037674..10037684
            }
        case FourCC("exli")!:                                                // 100375e0..100375ec
            addLife(p, showEffects: true)                                    // 1003769c..100376a0
        case FourCC("mult")!:                                                // 10037608..10037614
            stepMultiplier(p)                                                // 10037690
        case FourCC("shie")!:                                                // 100375f4..10037600
            addShield(p, Float(value))                                       // 100376ac..100376d0
        default:                                                             // 'spec' (1003761c..1003762c) and the rest
            break
        }
        return true                                                          // 100376d8 (r31 = 1)
    }
}

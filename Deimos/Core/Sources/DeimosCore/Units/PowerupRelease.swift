import Foundation
import HectorResources

/// The power-up release (micro-wave-2026-10-06.md §3.3, spawn-and-waves.md §5; plan C10): the weapon handler
/// (`FUN_1003b3c0`, `FUN_1003c0d0`, C15) releases a held power-up entity by its serial.
extension GameState {
    /// `FUN_10034ce0(now, id) @ 10034ce0` — the first member (groups `*(r2−0x6108)` then members, list order;
    /// deleted members included) whose serial +0x9c == `serial` (`10034d8c..10034d94`) goes through
    /// `FUN_10014670(e, now)` (`10034d98..10034d9c`) and the walk stops (`10034da4`). No match → nothing.
    public mutating func releasePowerup(serial: Int32, now: Int32) {
        for g in world.groups.indices {                                        // 10034d14..10034dbc
            for slot in world.groups[g].members where world.entities[slot].serial == serial {
                enterPowerupReleaseState(slot, now: now)
                return
            }
        }
    }

    /// `FUN_10014670(e, now) @ 10014670` — the first state s < `numStates` (U+0x14, `100146c8..100146d4`) flagged
    /// `stateUseThisStateOnWeaponPowerupRelease` (state +0x355, `10014688..10014694`) is entered **by its name**
    /// (U+0x97c + s·0x5e0) with spawning 0 and `now` → +0xa4 (`10014698..100146b4`); its out-bytes (locals
    /// `r1+0x39`/`r1+0x38`) are discarded. No flagged state → nothing.
    mutating func enterPowerupReleaseState(_ i: Int, now: Int32) {
        let u = assets.definitions.units[world.entities[i].unit]
        for s in 0..<min(Int(u.numStates), u.states.count) where u.states[s].stateUseThisStateOnWeaponPowerupRelease {
            enterState(i, named: u.states[s].stateName, spawning: false, now: now)
            return
        }
    }
}

import Foundation
import HectorResources

/// The weapon handler tick `FUN_1003b3c0(h, player, fireGround +0x200, fireAir +0x201, select +0x202, now,
/// &switched)`, called by the player update in state 4 when `+0x84 == 1.0` (`100290d0..100290fc`).
/// ◇ stub — C15 fills (plan invariant 14; ownership passes to C15). C15's contract: weapons-projectiles §2.3 order;
/// return 1 = start the player's overload, 2 = cancel it (loose-ends-combat §6.1); when a select happened
/// (`switched`, `local_1a8`) C15 calls `players[i].refreshFaceFromWeapon()` (`FUN_10029f60`) before returning, which
/// is where the update calls it (`10029104..10029118`, before the return code is examined).
extension GameState {
    /// ◇ stub — C15 fills. Runs only the crosshair part of `FUN_1003b3c0` that Phase 1 already ran
    /// (`1003b9ec..1003ba30`: `+0x120` = 1, the crosshair face/frame from the ground weapon `+0x168/+0x16c`, `+0x121`
    /// = 0, crosshair draw-shadow 0, `FUN_10012940` on it, its `FUN_10012750` unless its face is `none`) so the
    /// crosshair keeps showing; fires nothing, returns 0.
    mutating func tickWeapons(_ i: Int, input: PlayerInput) -> Int {
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
        return 0
    }
}

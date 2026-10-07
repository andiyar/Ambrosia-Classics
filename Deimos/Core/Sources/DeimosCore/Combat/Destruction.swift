import Foundation
import HectorResources

/// Entity destruction (damage-health-death.md, spawn-and-waves.md §5; plan C11b).
extension GameState {
    /// `FUN_10016300(e, killer, now) @ 10016300` — destroy entity `i` (score, coins, spawns, random bonus), the
    /// target of a state timer's or rule's `"Destroy"` (`10033cc8`, `10033d54`, `10033df0`, all with killer −1
    /// and now = the game time, which C11b reads from `flags.gameTime`).
    /// ◇ stub — C11b fills: here only the flags the removal sweep reads — +0xcb deleted, +0xd9 killer,
    /// +0xda destroyed (plan invariant 14; review leg B I5).
    public mutating func destroyEntity(_ i: Int, killer: Int8) {
        world.entities[i].deleted = true
        world.entities[i].killer = killer
        world.entities[i].destroyed = true
    }
}

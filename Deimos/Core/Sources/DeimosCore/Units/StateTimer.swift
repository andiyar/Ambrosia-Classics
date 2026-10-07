import Foundation
import HectorResources

/// The state timer and the scroll-pause flag of the entity update (`FUN_10033850`, waves-and-enemies.md §3 steps
/// 4–6, bosses.md §2.2; plan C10). The entity update itself (spawn-in countdown, sounds, particles, animation,
/// motion, collisions, the reaper) is C12's; it calls, for an entity whose spawn-in countdown is over, in the
/// listing's order: `stepStateTimer` (`10033c58..10033d6c`) → `pausesScrolling` (`10033d70..10033d80`) → the
/// animation step `FUN_10015930` (`10033d8c`, C9) → `applyRules` (`10033d94..10033e08`). A `true` from the timer
/// or the rules means the entity was removed this tick (`b 0x10034598`: the rest of its update is skipped, and
/// the pause flag is not read).
///
/// Listing read for C10 (`disasm-review3-all.txt`, `FUN_10033850`): `10033c58..10033c60` both out-bytes = 0;
/// `10033c64..10033c74` `gameTime == +0xa4 + +0xb8` (`cmpw; bne` — equality only, no ≥) else straight to the
/// flag; `10033c78..10033ca0` `strcmp(target, "Delete")` → +0xcb = 1, +0xd9 = −1; `10033ca4..10033cd0`
/// `"Destroy"` → `FUN_10016300(e, −1, now)`; `10033cd4..10033ce0` an empty target (first byte 0) → the flag;
/// `10033ce4..10033cf8` `strcmp(target, *(r2−0x6ef4))` = `"none"` (data image) → the flag; else
/// `FUN_100146f0(e, 0, target, now, &del, &destroy)` (`10033d14`), del → +0xcb/+0xd9 (`10033d28..10033d34`),
/// destroy → `FUN_10016300(e, −1, now)` (`10033d48..10033d54`), else the state is re-read (`10033d60..10033d6c`)
/// so the **new** state's `statePauseVerticalScrolling` (+0x346) is the one tested at `10033d70`. No draws of its
/// own (the entry's draws are `FUN_100146f0`'s, C8).
extension GameState {
    /// The timer step of `FUN_10033850` for entity `i` at game time `now`. Returns true when the entity was
    /// deleted or destroyed (the caller skips the rest of its update).
    @discardableResult
    public mutating func stepStateTimer(_ i: Int, now: Int32) -> Bool {
        guard let st = currentState(i) else { return false }
        let e = world.entities[i]
        guard now == e.stateStart &+ e.timer else { return false }             // 10033c64..10033c74
        return applyTimerTarget(i, st.stateOnTimerChangeTo, now: now)
    }

    /// The fired timer's target `name` applied to entity `i` (`10033c78..10033d6c`; separate so the targets the
    /// shipped data never uses — `"none"` — can be tested). Returns true when the entity was removed.
    @discardableResult
    mutating func applyTimerTarget(_ i: Int, _ name: String, now: Int32) -> Bool {
        if name == "Delete" {                                                  // 10033c78..10033ca0
            removeByStateMachine(i, StateEntryOutcome(delete: true))
            return true
        }
        if name == "Destroy" {                                                 // 10033ca4..10033cd0
            removeByStateMachine(i, StateEntryOutcome(destroy: true))
            return true
        }
        if name.isEmpty || name == "none" { return false }                     // 10033cd4..10033cf8
        let outcome = enterState(i, named: name, spawning: false, now: now)    // 10033cfc..10033d14
        return removeByStateMachine(i, outcome)                                // 10033d1c..10033d6c
    }

    /// `FUN_100146f0`'s out-bytes as `FUN_10033850` handles them after the timer (`10033d1c..10033d5c`) and the
    /// rules (`10033db8..10033df8`): delete → +0xcb = 1, +0xd9 = −1 (not destroyed); destroy →
    /// `FUN_10016300(e, −1, now)`. Returns true when either was set (delete is tested first).
    @discardableResult
    mutating func removeByStateMachine(_ i: Int, _ outcome: StateEntryOutcome) -> Bool {
        if outcome.delete {
            world.entities[i].deleted = true
            world.entities[i].killer = -1
            return true
        }
        if outcome.destroy {
            destroyEntity(i, killer: -1)
            return true
        }
        return false
    }

    /// `10033d60..10033d80` — the current state's `statePauseVerticalScrolling` (+0x346): any entity that reaches
    /// this point makes `FUN_10033850` return 1 and the scroll stops next tick (bosses.md §2.1–§2.2). Read after
    /// the timer step (so a timer switch counts the new state) and before the rules (a rule that deletes the
    /// entity still leaves this tick paused).
    public func pausesScrolling(_ i: Int) -> Bool {
        currentState(i)?.statePauseVerticalScrolling ?? false
    }
}

// Enemy actions — Task 9c. SEAMS (plan §Tasks 9a–9c seam rule): `_FigureEnemyMove` / `_MoveEnemyRandomly`
// (Task 9b) call them; Task 9c replaces these bodies. Task 9b's tests never reach them (no pending action is set,
// piranhas never try a balloon or a push, and every homing case turns or has the pop window closed).
//
// The direction is `Direction?` (nil = 0) because the pending-action dispatch passes the raw `+0x23` byte, which can
// be 0 there (e.g. after `_ToastBubble` popped a bubble without setting a direction), and each original handles 0 its
// own way: `_TryRemoveGo @ 0001305e` → `_LocationErrorInt(0x7d8,3)`; `_TryEnemyPushBlock @ 000131fd` →
// `_LocationErrorInt(0x7d8,5)`; `_TryEnemyCreateBalloon @ 00013441` returns 0 first when the hero is trapped
// (`hero+0x4c`), else `_LocationErrorInt(0x7d8,5)`.

extension GameState {
    /// `_TryRemoveGo(i, d) @ 0001305e` — not yet transcribed (Task 9c).
    mutating func tryRemoveGo(_ slot: Int, _ dir: Direction?) -> Bool {
        preconditionFailure("Task 9c")
    }

    /// `_TryEnemyPushBlock(i, d) @ 000131fd` — not yet transcribed (Task 9c).
    mutating func tryEnemyPushBlock(_ slot: Int, _ dir: Direction?) -> Bool {
        preconditionFailure("Task 9c")
    }

    /// `_TryEnemyCreateBalloon(i, d) @ 00013441` — not yet transcribed (Task 9c).
    mutating func tryEnemyCreateBalloon(_ slot: Int, _ dir: Direction?) -> Bool {
        preconditionFailure("Task 9c")
    }

    /// `_ToastBubble(i) @ 00012ef2` — not yet transcribed (Task 9c).
    mutating func toastBubble(_ slot: Int) {
        preconditionFailure("Task 9c")
    }
}

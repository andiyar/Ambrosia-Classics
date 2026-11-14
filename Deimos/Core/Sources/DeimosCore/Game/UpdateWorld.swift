import Foundation
import HectorResources

/// One step of `FUN_10006b50`, for order tests (plan C12 `testUpdateWorldOrder`; step logs are closure parameters,
/// never stored — invariant 13).
public enum WorldUpdateStep: Equatable, Sendable {
    /// `10006b7c` `FUN_1004aa20` — the ISp input cleared.
    case inputClear
    /// `10006b84..10006b90` `FUN_1002d190` — the console is open (true → no ISp read this tick).
    case consoleTest(open: Bool)
    /// `10006b94` `FUN_1004aa90` — the ISp read.
    case inputRead
    /// `10006b9c..10006bc4` — the P1-active byte after its update.
    case p1Active(Bool)
    /// `10006bd0` `FUN_10018320(G+0x1c)` — the notice slot.
    case notices
    /// `10006bd8` `FUN_1002a770` — the debris rects.
    case debris
    /// `10006be0` `FUN_100438c0` — the particles.
    case particles
    /// `10006be8` `FUN_10046a10` — the motion blurs.
    case blurs
    /// `10006c14` `FUN_10028170` for player p.
    case player(Int)
    /// `10006c34` `FUN_100317e0` — the score bar.
    case scoreBar
    /// `10006c3c..10006d98` — the game-over branch (`gameOverStep`).
    case gameOver
    /// `10006d9c` `FUN_10010000` — the scroll step and its level-end result.
    case scrollStep(atEnd: Bool)
    /// `10010068..10010080` — inside the scroll step: `FUN_10033090(window top − 64)`.
    case spawnRow(Int32)
    /// A spawn request made by that row (`spawnLevelObjects`'s log).
    case spawn(SpawnEvent)
    /// `10006da4..10007024` — the level-end branch (`levelEndStep`).
    case levelEnd(atEnd: Bool)
    /// An event of the game-over / level-end branches (`LevelEndEvent`), in its place.
    case levelEndEvent(LevelEndEvent)
    /// `1000702c` `FUN_10033850` and its pause flag.
    case entities(paused: Bool)
    /// `1000703c` `FUN_1000ffe0` — scroll speed 0.
    case scrollPause
    /// `10007048` `FUN_1000ffc0` — scroll speed 1 (refused once the level has ended).
    case scrollResume
}

/// The world update `FUN_10006b50(&p1Active, film, &gameOverNoticed, —) @ 10006b50` (listing `10006b50..10007060`, the
/// dump block `// ==== FUN_10006b50`; engine-loop.md §3, level-scroll-objects.md §8; plan C12). The two stack bytes
/// of `FUN_100051a0` it updates by pointer are `GameFlags.p1Active` (r22) and `GameFlags.gameOverNoticed` (r27).
///
/// **Order** (`now` = G+0x1c, read through r28):
/// 1. `10006b7c` input clear `FUN_1004aa20`; `10006b84` console open `FUN_1002d190`; closed → `10006b94` the ISp read
///    `FUN_1004aa90`. Here the keys are the caller's (`FrameKeys.beginFrame` withholds them on a tick frame while the
///    console is open — `FrameKeysResult.inputWithheld`): withheld → every player reads no keys.
/// 2. `10006b9c..10006bc4` `p1Active` clear and P1 in life state 4 (`FUN_10026c60(P1, 4)`) → set; never cleared here.
/// 3. `10006bd0` notices `FUN_10018320(now)` → `10006bd8` debris `FUN_1002a770` → `10006be0` particles `FUN_100438c0`
///    → `10006be8` blurs `FUN_10046a10` (the scroll delta they read is the previous tick's — the scroll steps later).
/// 4. `10006bf0..10006c28` players P1 then P2 `FUN_10028170` (`updatePlayer`).
/// 5. `10006c2c..10006c34` the score bar `FUN_100317e0(P1, P2)`.
/// 6. `10006c3c..10006d98` game over (`gameOverStep`).
/// 7. `10006d9c` the scroll step `FUN_10010000` (`ScrollState.step`), whose spawn row `10010068..10010080` —
///    reached only when the speed is not 0 and the level did not end this tick, the console-only "spawning disabled"
///    byte −0x6204 being 0 — is `spawnLevelObjects(row: window top − 64)`.
/// 8. `10006da4..10007024` the level end (`levelEndStep(atEnd:)`): the first tick (`10006dd4..10006f44`), then the
///    accuracy tally (`10006f58`) and the coin bonus (`10006f7c..10006ff4`, G+0x09 at `10007024`).
/// 9. `1000702c` the entities `FUN_10033850(now)` (`updateEntities`) → its byte set: `1000703c` pause
///    `FUN_1000ffe0`; else `10007048` resume `FUN_1000ffc0`.
/// The level complete `FUN_10007170` and the game time + 1 are the caller's (C18a's pass), after this.
extension GameState {
    /// `FUN_10006b50` at game time `flags.gameTime`. `inputs` = the players' keys (the ISp read, index 0 = P1);
    /// `inputWithheld` = the console was open on this tick (no ISp read). A film's inputs come from the film inside
    /// the player update (`readPlayerInput`), not from `inputs`.
    public mutating func updateWorld(inputs: [PlayerInput], inputWithheld: Bool = false,
                                     log: ((WorldUpdateStep) -> Void)? = nil) {
        // 1. Input.
        var keys: [PlayerInput] = [[], []]                                   // 10006b7c FUN_1004aa20
        log?(.inputClear)
        log?(.consoleTest(open: inputWithheld))                              // 10006b84..10006b90 FUN_1002d190
        if !inputWithheld {
            for p in 0..<min(2, inputs.count) { keys[p] = inputs[p] }        // 10006b94 FUN_1004aa90
            log?(.inputRead)
        }
        // 2. P1 active.
        if !flags.p1Active && players[0].lifeState == 4 {                    // 10006b9c..10006bbc
            flags.p1Active = true                                            // 10006bc0..10006bc4
        }
        log?(.p1Active(flags.p1Active))
        // 3. Notices, debris, particles, blurs.
        notice.tick(gameTime: flags.gameTime, rng: &rng, cues: &cues)        // 10006bcc..10006bd0 FUN_10018320
        log?(.notices)
        debris.update(scrollDelta: scroll.scrolled)                          // 10006bd8 FUN_1002a770
        log?(.debris)
        particles.update(scrollDelta: scroll.scrolled)                       // 10006be0 FUN_100438c0
        log?(.particles)
        blurs.update()                                                       // 10006be8 FUN_10046a10
        log?(.blurs)
        // 4. Players.
        for p in 0..<2 {                                                     // 10006bf0..10006c28
            updatePlayer(p, input: keys[p])                                  // 10006c14 FUN_10028170
            log?(.player(p))
        }
        // 5. Score bar.
        scoreBar.update(players: players)                                    // 10006c2c..10006c34 FUN_100317e0
        log?(.scoreBar)
        // 6. Game over.
        log?(.gameOver)
        gameOverStep(log: log.map { l in { l(.levelEndEvent($0)) } })        // 10006c3c..10006d98
        // 7. The scroll step and its spawn row.
        let atEnd = scroll.step()                                            // 10006d9c FUN_10010000 (10010014..10010064)
        log?(.scrollStep(atEnd: atEnd))
        if !atEnd && scroll.speed != 0 {                                     // 10010018..10010048 → 10010068
            let row = scroll.window.top &- 64                                // 10010074..1001007c
            log?(.spawnRow(row))
            spawnLevelObjects(row: row, log: log.map { l in { l(.spawn($0)) } })   // 10010080 FUN_10033090
        }
        // 8. The level end.
        log?(.levelEnd(atEnd: atEnd))
        levelEndStep(atEnd: atEnd, log: log.map { l in { l(.levelEndEvent($0)) } })   // 10006da4..10007024
        // 9. The entities, then the scroll pause / resume.
        let paused = updateEntities()                                        // 10007028..1000702c FUN_10033850
        log?(.entities(paused: paused))
        if paused {                                                          // 10007034..10007038
            scroll.pause()                                                   // 1000703c FUN_1000ffe0
            log?(.scrollPause)
        } else {
            scroll.resume()                                                  // 10007048 FUN_1000ffc0
            log?(.scrollResume)
        }
    }
}

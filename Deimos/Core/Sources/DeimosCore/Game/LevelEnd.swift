import Foundation
import HectorResources

/// One step of the end-of-level / game-over branches, for order tests (plan C17 `testLevelEndSequenceOrder`; step logs
/// are closure parameters, never stored — invariant 13).
public enum LevelEndEvent: Equatable, Sendable {
    /// `gameOverStep` ran (`10006c3c`).
    case gameOverChecked
    /// A notice request (`nogo` / `nole` / `noal`) was made (`FUN_10033220`; logged whether or not it creates).
    case notice(FourCC)
    /// `FUN_10027de0(p, 1, 0)` for player p.
    case invulnerable(Int)
    /// `FUN_100072c0`.
    case accuracyTier
    /// `FUN_100075e0` and its result.
    case accuracyTally(done: Bool)
    /// `FUN_10027670` for player p.
    case coinSetup(Int)
    /// `FUN_10027930` for player p and its result.
    case coinTally(Int, done: Bool)
    /// G+0x09 set (`10007024`).
    case levelComplete
}

/// The level-end and game-over branches of `FUN_10006b50` and level complete `FUN_10007170` (level-scroll-objects.md
/// §8, engine-loop.md §3, scoring-bonuses.md §6; plan C17). C12's `updateWorld` calls `gameOverStep` after the score
/// bar and `levelEndStep` with the scroll step's result; C18a's pass calls `levelCompleteStep` after `updateWorld`.
///
/// Listing reads (`disasm-review3-all.txt`; `FUN_10026c10(p)` = player `+0xc4` in game; the notice request is the game
/// template `r2−0x268c` = `0x100e3ca4` — runtime `SpawnRequest.template` — at (flli 54 × 0.5, flli 55 × 0.5) =
/// (208, 240), `fmuls` by `*(r2−0x73b0)` + 8 = 0.5, then `FUN_10033220(req, 0, 0)`):
/// - game over `10006c3c..10006d98`: see `gameOverStep`.
/// - level end `10006d9c..10007024`: see `levelEndStep`.
/// - `FUN_10007170` (`10007194..10007268`): see `levelCompleteStep`.
extension GameState {
    /// The notice request at (flli 54 × 0.5, flli 55 × 0.5) for PermObjectID `perm` unless it is `none`.
    private mutating func spawnCentreNotice(_ perm: Int, log: ((LevelEndEvent) -> Void)?) {
        let unit = assets.objects[perm]                                      // FUN_100201f0
        guard unit != .none else { return }                                  // subis 0x6e6f; cmplwi 0x6e65; beq
        let half: Float = 0.5                                                // *(0x100d6354 + 8)
        let x: Float = assets.floats[54] * half                              // li r3,0x36; fmuls
        let y: Float = assets.floats[55] * half                              // li r3,0x37; fmuls
        log?(.notice(unit))
        spawn(SpawnRequest(unit: unit, x: x, y: y))                          // FUN_10033220(req, 0, 0)
    }

    /// `FUN_10006b50` `10006c3c..10006d98` — game over, after the score bar. Some player in game (`FUN_10026c10`, first
    /// found) → nothing. Else G+0x0a = 1; the first such tick (`gameOverNoticed` clear): `nogo` (PermObjectID 24) at
    /// (208, 240) unless `none`, then the latch = 1 and G+0x34 = game time (both even when `none`); later ticks: game
    /// time > G+0x34 + int(flli 13 = 110) (`cmpw; ble`) → running = 0 — on start + 111.
    public mutating func gameOverStep(log: ((LevelEndEvent) -> Void)? = nil) {
        log?(.gameOverChecked)
        guard !players.contains(where: \.inGame) else { return }             // 10006c3c..10006c7c
        flags.noPlayerAlive = true                                           // 10006c80..10006c84
        if !flags.gameOverNoticed {                                          // 10006c88..10006c90
            spawnCentreNotice(24, log: log)                                  // 10006c94..10006d4c
            flags.gameOverNoticed = true                                     // 10006d54..10006d58
            flags.gameOverStart = flags.gameTime                             // 10006d5c..10006d60
        } else if flags.gameTime > flags.gameOverStart &+ EntityDraw.fctiwz(assets.floats[13]) {   // 10006d68..10006d90
            flags.running = false                                            // 10006d94..10006d98
        }
    }

    /// `FUN_10006b50` `10006da4..10007024` — the level end, given `FUN_10010000`'s result `atEnd` (the scroll step at
    /// `10006d9c`, C10/C12's). Not at the end → nothing. Else G+0x39 = 1 every tick, then:
    /// - first tick (G+0x29 clear): nobody alive (G+0x0a) → G+0x29 = 1 only (`10006f4c`). Else sector ==
    ///   `FUN_10011de0` (12) and levels started == 12 → G+0x0d = 1; `noal` (PermObjectID 23) if G+0x0d else `nole`
    ///   (22) at (208, 240) unless `none`; G+0x29 = 1, G+0x2c = game time; each player in game `FUN_10027de0(p, 1, 0)`
    ///   (invulnerable, not sticky); `FUN_100072c0(game time)`.
    /// - later ticks: `FUN_100075e0(game time)`; done → all = 1, stacked = 0; each player in game whose coin tally has
    ///   not started (`FUN_10027db0`): stacked = `FUN_10027670(p, time, stacked)`, all = 0; then each player in game:
    ///   `FUN_10027930(p, time)` false → all = 0; all → G+0x09 = 1 (also when no player is in game).
    public mutating func levelEndStep(atEnd: Bool, log: ((LevelEndEvent) -> Void)? = nil) {
        guard atEnd else { return }                                          // 10006da4..10006dac
        flags.levelEnding = true                                             // 10006db0..10006db4
        let now = flags.gameTime                                             // r28 = G+0x1c
        if !flags.levelEndHandled {                                          // 10006db8..10006dc4
            guard !flags.noPlayerAlive else {                                // 10006dc8..10006dd0
                flags.levelEndHandled = true                                 // 10006f4c (stb r3 = 1)
                return
            }
            let levels = Int32(assets.levelOrder.levels.count)               // 10006dd4..10006de0 FUN_10011de0 ×2
            if flags.sector == levels && flags.levelsStarted == levels {     // 10006de8..10006dfc
                flags.allLevels = true                                       // 10006e00..10006e04
            }
            spawnCentreNotice(flags.allLevels ? 23 : 22, log: log)           // 10006e08..10006ee4
            flags.levelEndHandled = true                                     // 10006eec..10006ef0
            flags.levelEndTime = now                                         // 10006efc..10006f00
            for p in 0..<2 where players[p].inGame {                         // 10006f08..10006f3c
                log?(.invulnerable(p))
                setInvulnerable(p, true, sticky: false)                      // 10006f1c..10006f28
            }
            log?(.accuracyTier)
            accuracyTier(now: now)                                           // 10006f40..10006f44
            return
        }
        let done = accuracyTally(now: now)                                   // 10006f54..10006f58
        log?(.accuracyTally(done: done))
        guard done else { return }                                           // 10006f5c..10006f60
        var all = true                                                       // 10006f68
        var stacked = false                                                  // 10006f6c
        for p in 0..<2 where players[p].inGame && !coinTallyStarted(p) {     // 10006f78..10006f9c
            log?(.coinSetup(p))
            stacked = coinTallySetup(p, now: now, stacked: stacked)          // 10006fa0..10006fb4
            all = false                                                      // 10006fb8
        }
        for p in 0..<2 where players[p].inGame {                             // 10006fd8..10006fe8
            let d = coinTally(p, now: now)                                   // 10006fec..10006ff4
            log?(.coinTally(p, done: d))
            if !d { all = false }                                            // 10006ffc..10007004
        }
        if all {                                                             // 10007018..1000701c
            flags.levelComplete = true                                       // 10007020..10007024
            log?(.levelComplete)
        }
    }

    /// `FUN_10007170 @ 10007170(controller, film, info)` — level complete, after `updateWorld` in the same tick. G+0x09
    /// clear → nothing. No player in game (`FUN_10026c10`, first found) → running = 0. A film (`film` = the session's
    /// film flag, G+0x20) → running = 0 (a film holds one level). Else: music stop (`FUN_10048120(0)`), `tran`
    /// (PermSoundID 3; priority 75, volume 100, multiple 1), [the fade to black `FUN_1000b9a0(display, 1)` — ◇ Phase 3],
    /// G+0x09 = G+0x39 = 0, the level-transition reset `FUN_100302e0` (`FrameKeys.levelTransitionReset`), then
    /// `FUN_100064d0(0, info)` → the next sector — **◇ S9.1:** the session ends instead (running = 0; Phase 3 starts
    /// the next sector).
    public mutating func levelCompleteStep(controller c: inout FrameController, console: inout Console, ticks: UInt32) {
        guard flags.levelComplete else { return }                            // 10007194..1000719c
        guard players.contains(where: \.inGame) else {                       // 100071a0..100071e4
            flags.running = false                                            // 10007264..10007268
            return
        }
        if flags.filmPlaying {                                               // 100071e8..100071ec
            flags.running = false                                            // 100071f0..100071f4
            return
        }
        cues.music.append(.stop)                                             // 10007200..10007204 (the bne at 100071fc is never taken)
        cues.sounds.append(SoundPlay.perm(assets.sounds[3], priority: 0x4b, volume: 100,
                                          allowMultiple: true))              // 1000720c..10007224
        // ◇ Phase 3: FUN_1000b9a0(display, 1), the 33-step fade to black (1000722c..10007234).
        flags.levelComplete = false                                          // 1000723c..10007240
        flags.levelEnding = false                                            // 10007248
        FrameKeys.levelTransitionReset(controller: &c, console: &console, game: &self, ticks: ticks)   // 10007244..1000724c
        // ◇ S9.1: FUN_100064d0(0, info) (10007254..1000725c) → the session ends; the driver starts a new game.
        flags.running = false
    }
}

// Time (level) bonus (plan §Task 7b.1; Research note 44; Invariant 9), transcribed from
// `_TimeBonus_Process @ 00006a15`, `_TimeBonus_Increase @ 000069cd` and `_Jewels_TurnToBlocks @ 0001c705`.
// `_TimeBonus_Reset` lives in `LevelBuild.swift`. Sounds, the "Hurry up" notice (`_PrepareNotice`,
// `_GetCurrentNotice`), `gTimeBonusHasChanged` and the screen/background restores are presentation only (no RNG).

extension GameState {
    /// `_TimeBonus_Process @ 00006a15`, once per frame. End of level → nothing. Bonus < 1 → only the notice
    /// bookkeeping (not modelled); the timer is untouched. Otherwise: hero state ≠ 2 → timer = frame; state 2 and
    /// `timer + 0x1e < frame` → bonus −50, timer = frame, then bonus **exactly** 0 → `_Jewels_TurnToBlocks`, else
    /// bonus < 500 → flash on, flash timer = frame.
    mutating func timeBonusProcess() {
        guard !isEndOfLevel else { return }
        guard 0 < timeBonus else { return }      // the notice timeout (`_PrepareNotice(0)`) — presentation only
        let now = frame
        guard hero.state == 2 else {
            timeBonusTimer = now
            return
        }
        guard Int(timeBonusTimer) + 0x1e < Int(now) else { return }
        timeBonus &-= 0x32
        timeBonusTimer = now
        if timeBonus == 0 {
            jewelsTurnToBlocks()
        } else if timeBonus < 500 {
            timeBonusFlash = true
            timeBonusFlashTimer = frame
        }
    }

    /// `_TimeBonus_Increase(v, flash) @ 000069cd` (every caller passes flash = 1): bonus = bonus + v, capped at
    /// 0x1866e (99950) when the sum exceeds it; flash = 1, flash timer = frame.
    mutating func timeBonusIncrease(_ v: Int32) {
        let sum = timeBonus &+ v
        timeBonus = sum < 0x1866f ? sum : 0x1866e
        timeBonusFlash = true
        timeBonusFlashTimer = frame
    }

    /// `_Jewels_TurnToBlocks @ 0001c705`: unless `gJewelsDone`, every maze cell (rows 0…10, cols 0…15) holding a
    /// jewel (20) or a cluster (30) becomes a normal bubble (10) with `_NewStarGroup(col·40, row·40, 0)` (motion-0
    /// stars, no draws); then `gJewelsDone` = 1.
    mutating func jewelsTurnToBlocks() {
        guard !jewelsDone else { return }
        for row in 0..<Maze.rows {
            for col in 0..<Maze.columns {
                let cell = maze[col, row]
                guard cell == CellCode.jewel || cell == CellCode.cluster else { continue }
                maze[col, row] = CellCode.normal
                stars.newGroup(x: Int16(col * 0x28), y: Int16(row * 0x28), group: 0, hero: heroAnchor, frame: frame,
                               prefs: config.prefs, rng: &rng)
            }
        }
        jewelsDone = true
    }
}

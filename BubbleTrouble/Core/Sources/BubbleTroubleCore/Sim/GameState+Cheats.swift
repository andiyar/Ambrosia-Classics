// The simulation calls the pause cheats make (plan 2026-10-04 btx-playable C8), each transcribed from its call in
// `_PauseGame @ 0001767b` — the pause runs between frames, so these act on the state as the last frame left it. They
// reuse the simulation's own transcriptions (`_AddHero`, `_AddToScore`, `_EXTRA_Change`, …); their cues land in the
// sound buffer and their draw calls in `presentation.ops`, which the session drains at once (`takeSounds`,
// `takeCheatOps`). Never reached in demo (no pause) — FILM replays are unaffected.

extension GameState {
    /// `_ResetScore(0) @ 00028085`: `_SetScore(0)`, `gScoreHasChanged = 1`, `gNextExtraLifeScore = 10000`, `gScoreRect`
    /// = (446, 132, 476, 132) — the next `_DrawScore` erases only up to that right edge (replicated).
    public mutating func cheatResetScore() {
        score = 0
        presentation.scoreHasChanged = true
        nextExtraLifeScore = 10000
        presentation.scoreRect = QDRect(top: 0x1be, left: 0x84, bottom: 0x1dc, right: 0x84)
    }

    /// 00017a7f: `_NewStarGroup((char)hero[0x28]·40, (char)hero[0x34]·40, 10)` with `gOrbit_Table` = `orbitTable`
    /// (`_LoadOrbitData`; nil → no table, nothing created).
    public mutating func cheatStarBurst(orbitTable: [Int16]?) {
        guard let orbitTable else { return }
        stars.orbitTable = orbitTable
        stars.newGroup(x: Int16(hero.col) &* 0x28, y: Int16(hero.row) &* 0x28, group: 10, hero: heroAnchor,
                       frame: frame, prefs: config.prefs, rng: &rng)
    }

    /// 00017bd1 `_RegenerateBlocks`.
    public mutating func cheatRegenerateBlocks() {
        regenerateBlocks()
    }

    /// 00017c05: `gEndOfLevelTime = gFrameCounter` (u16), `gIsEndOfLevel = 1` — `_PlayGame`'s end-of-level block
    /// then runs its 70-frame wait as for a cleared maze.
    public mutating func cheatEndLevel() {
        endOfLevelTime = frame
        isEndOfLevel = true
    }

    /// 00017c64: `_gGhostIcons = !_gGhostIcons`.
    public mutating func cheatToggleGhostIcons() {
        presentation.ghostIcons.toggle()
    }

    /// 00017d3e `_AddHero(1, 1)` (lives + 1 capped at 9, "Extra Life" ×2).
    public mutating func cheatAddHero() {
        addHero()
    }

    /// 00017d81 `_AddToScore(v, 0)`: not multiplied (the extra-life threshold still applies).
    public mutating func cheatAddToScore(_ v: Int32) {
        addToScore(v, multiply: false)
    }

    /// 00017db9 `_SetHeroInvisibility(1)`.
    public mutating func cheatSetHeroInvisibility() {
        setHeroInvisibility(true)
    }

    /// 00017dea `_Balloons_CaptureAllEnemies` (its `GetRandomFast(4,7)` draws and snd 15 included).
    public mutating func cheatCaptureAllEnemies() {
        balloonsCaptureAllEnemies()
    }

    /// 00017ec3 `_EXTRA_Change(letter, 0)` — bonus slot 0 (the completed-EXTRA path re-types slot 0 if armed).
    public mutating func cheatEXTRAChange(_ letter: Int) {
        extraChange(letter: letter, bonusSlot: 0)
    }

    /// 00017fab / 0001801a `_Multiplier_Change(v)`.
    public mutating func cheatMultiplierChange(_ v: Int16) {
        multiplierChange(v)
    }

    /// The draw calls recorded since the last frame (a cheat's `_EXTRA_Draw`, `_Multiplier_Draw`, …), drained.
    mutating func takeCheatOps() -> [DrawOp] {
        defer { presentation.ops = [] }
        return presentation.ops
    }
}

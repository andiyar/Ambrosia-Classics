extension GameState {
    /// LEVL w15/w16 (balloon flash / release frames) by level, as shipped (Research note 9): 140/170 (L1), 130/160
    /// (L2), 120/150 (L3), 110/140 (L4–12), 100/130 (L13–15), 90/120 (L16 and up).
    static func shippedBalloonTimes(level: Int) -> (flash: Int16, release: Int16) {
        switch level {
        case ...1: (140, 170)
        case 2: (130, 160)
        case 3: (120, 150)
        case 4...12: (110, 140)
        case 13...15: (100, 130)
        default: (90, 120)
        }
    }

    /// The internal no-files factory every synthetic test uses (plan §Task 4.1, A4/B2). ZERO RNG draws
    /// (`rng.drawCount == 0` on return).
    ///
    /// Synthetic LEVL = the level-1 words (`1, 912, 1, 1, 1, 1, 4, 2, 50, 2, 10, 20, 3, 10, 20, 140, 170, 300, 4,
    /// 0…`) with w0 = level, w6 = totalEnemies, w7 = maxActive, w12 = jewelCount, w15/w16 from the shipped step table
    /// for `level`, w18…w23 = pool, stored with `_LoadLevel`'s clamps. `mazeCopy = maze`. Runs `_ResetBlocks`
    /// (numNormalBlocks = 100), `_TimeBonus_Reset`, `_InitHero` (start-cell rules of Research note 13), then
    /// `hero.state = heroState`, stateStart 0, visible. Jewels NOT placed; pools empty and NOT reset (tables zero);
    /// frame 0; lives 3; score 0; next extra life 10000; multiplier 1; levelForEffect 50; playing = true. The
    /// licence-derived flags follow `config` (hero `+0x3a`, per-enemy registered bytes, `gAIRegistered`).
    static func testWorld(maze: Maze, level: Int = 1, seed: UInt32 = 1, jewelCount: Int = 3,
                          totalEnemies: Int = 4, maxActive: Int = 2, pool: [Int16] = [4, 0, 0, 0, 0, 0],
                          heroState: Int16 = 2, mode: GameMode = .demo,
                          config: SessionConfig = SessionConfig()) -> GameState {
        precondition(pool.count == 6, "pool holds LEVL w18…w23 (6 words)")
        var state = GameState(config: config, mode: mode, seed: seed)
        state.level = level
        var words: [Int16] = [1, 912, 1, 1, 1, 1, 4, 2, 50, 2, 10, 20, 3, 10, 20, 140, 170, 300, 4]
        words += Array(repeating: 0, count: LevelRecord.wordCount - words.count)
        words[0] = Int16(truncatingIfNeeded: level)
        words[6] = Int16(truncatingIfNeeded: totalEnemies)
        words[7] = Int16(truncatingIfNeeded: maxActive)
        words[12] = Int16(truncatingIfNeeded: jewelCount)
        let balloon = shippedBalloonTimes(level: level)
        words[15] = balloon.flash
        words[16] = balloon.release
        for i in 0..<6 { words[18 + i] = pool[i] }
        state.levelRecord.words = loadLevelWords(words)
        state.maze = maze
        state.mazeCopy = maze
        state.resetBlocks()
        state.timeBonusReset()
        state.initHero()
        state.hero.state = heroState
        state.hero.stateStart = 0
        state.hero.visible = true
        state.hero.licenceValid = true                    // _ResetHeroLives sets +0x24 = 1
        for i in state.enemyRegistered.indices { state.enemyRegistered[i] = config.registeredValidLicence }
        state.enemyLastColour = 1
        state.aiRegistered = config.registeredValidLicence
        state.lives = 3
        state.score = 0
        state.nextExtraLifeScore = 10000
        state.multiplier = 1
        state.levelForEffect = 50
        state.playing = true
        return state
    }
}

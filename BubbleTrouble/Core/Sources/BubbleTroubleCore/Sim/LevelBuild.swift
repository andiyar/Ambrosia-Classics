/// Draw-count checkpoints inside `_NewLevel` (test hook for `testNewLevelDrawCheckpoints`): the cumulative
/// `rng.drawCount` right after each RNG-consuming sub-step.
enum LevelBuildCheckpoint: Hashable, Sendable {
    /// After `_PositionJewels` (2 draws per jewel).
    case jewels
    /// After `_Bubbles_Init` / `_Bubbles_CreateRandomLUT` (109).
    case bubbleLUT
    /// After `_InitStars` (42).
    case stars
    /// After `_InitPoints` (8).
    case points
    /// After `_Bonus_Init`.
    case bonus
}

// MARK: - _PlayGame prologue and _NewLevel

extension GameState {
    /// `_PlayGame @ 00018247`'s prologue (Research note 11) followed by `_NewLevel`: install `seed`
    /// (`SetQDGlobalsRandomSeed` — demo: `FILM.seed`; play: the caller's tick count), `SetLevel(level − 1)`,
    /// `ResetHeroLives`, `ResetScore(0)`, `Multiplier_Reset`, `EXTRA_Reset`, `_NewLevel` (which advances to `level`).
    /// The FILM sample pointer (`gRecordingCounter = 0`) belongs to the input source (Task 6).
    public static func newGame(level: Int, mode: GameMode, seed: UInt32, files: BTXResourceFiles,
                               config: SessionConfig = SessionConfig()) throws -> GameState {
        var unused: [LevelBuildCheckpoint: Int] = [:]
        return try newGame(level: level, mode: mode, seed: seed, files: files, config: config, checkpoints: &unused)
    }

    /// `newGame` with the `_NewLevel` draw-count checkpoints recorded (test hook).
    static func newGame(level: Int, mode: GameMode, seed: UInt32, files: BTXResourceFiles,
                        config: SessionConfig = SessionConfig(),
                        checkpoints: inout [LevelBuildCheckpoint: Int]) throws -> GameState {
        var state = GameState(config: config, mode: mode, seed: seed)   // SetQDGlobalsRandomSeed(seed)
        state.playing = true                                             // gPlayGame = 1
        state.level = level - 1                                          // _SetLevel(id − 1)
        // _ResetHeroLives @ 000218a7: _SetLives(3); hero[0x24] = 1.
        state.lives = 3
        state.hero.licenceValid = true
        // _ResetScore(0) @ 00028085: score 0, gNextExtraLifeScore = 10000.
        state.score = 0
        state.nextExtraLifeScore = 10000
        // _Multiplier_Reset @ 00019e68: gBonusMultiplier = 1.
        state.multiplier = 1
        // _EXTRA_Reset @ 0001a128: all five letters cleared.
        state.extraLetters = Array(repeating: false, count: 5)
        try state.newLevel(files: files, checkpoints: &checkpoints)
        state.firstAppearance = true                                     // loop-local `first = true`
        return state
    }

    /// `_NewLevel @ 0001735f`, in its exact order (Research note 12).
    mutating func newLevel(files: BTXResourceFiles) throws {
        var unused: [LevelBuildCheckpoint: Int] = [:]
        try newLevel(files: files, checkpoints: &unused)
    }

    /// `_NewLevel @ 0001735f` with the draw-count checkpoints recorded. Display-only calls (`_RequestDrawReserveHero`,
    /// `_WipeScreen`, score/time/multiplier/EXTRA draws, notices, music, sounds) and the licence copies into the
    /// `gBogusReg*` globals are omitted — none touches the RNG or the simulation.
    mutating func newLevel(files: BTXResourceFiles, checkpoints: inout [LevelBuildCheckpoint: Int]) throws {
        isEndOfLevel = false
        frame = 0
        level += 1                                          // _NextLevel
        try loadLevel(level, files: files)                  // _LoadLevel(_GetLevel()) — draws only for level ≥ 51
        resetBlocks()
        resetHurtBlockList()
        timeBonusReset()
        try loadMaze(levelRecord.mazeID, files: files)      // failure → the original's _CleanUp (quit)
        initHero()
        positionJewels()
        checkpoints[.jewels] = rng.drawCount
        splats.reset()                                      // _Splats_Init
        airBubbles.reset(rng: &rng)                         // _Bubbles_Init (109 draws)
        checkpoints[.bubbleLUT] = rng.drawCount
        balloonsInit()
        stars.reset(rng: &rng)                              // _InitStars (42 draws)
        checkpoints[.stars] = rng.drawCount
        points.reset(rng: &rng)                             // _InitPoints (8 draws)
        checkpoints[.points] = rng.drawCount
        initEnemies()
        // _InitEnemyAI @ 00012591 is empty.
        bonusInit()
        checkpoints[.bonus] = rng.drawCount
        // _DrawMaze @ 00025daa: `gAIRegistered = RT3_GetLicenseCode() != 0` (no RNG; the rest is drawing).
        aiRegistered = config.registeredValidLicence
        soundsInitDelayedSounds()                           // _Sounds_InitDelayedSounds @ 00026888 (after the draws)
    }
}

// MARK: - _NewLevel's sub-steps

extension GameState {
    /// The words `_LoadLevel` stores into `level`: w6 clamped (`sVar8 = 0x1e; if (w6 < 0x1f) sVar8 = w6;`) and w12
    /// clamped to 3…4 (`sVar8 = 3; if (2 < w12) sVar8 = w12; … if (4 < sVar8) 4`); every other word raw.
    static func loadLevelWords(_ raw: [Int16]) -> [Int16] {
        var words = raw
        words[6] = raw[6] < 0x1f ? raw[6] : 0x1e
        var jewels: Int16 = 3
        if 2 < raw[12] { jewels = raw[12] }
        if 4 < jewels { jewels = 4 }
        words[12] = jewels
        return words
    }

    /// `_LoadLevel @ 00002ef7`: levels ≥ 51 load a random LEVL `GetRandomFast(0x15,0x32)` (never for 1…50); ≥ 100
    /// first sets the level number to 99 (`_SetCurrLevelNum(99)`). Copies the record with the w6/w12 clamps. A pool
    /// sum Σw18…w23 ≠ clamped w6 is the original's `_LocationError(0x7de,1)` (quits) → `.originalWouldAbort`.
    /// (The high-level pref and the integrity checks `_OtherLevCheck`/`_CheckLevelReroute` have no simulation effect
    /// on the shipped data and are omitted.)
    mutating func loadLevel(_ requested: Int, files: BTXResourceFiles) throws {
        var id = requested
        if id >= 100 {
            level = 99
        }
        if id >= 0x33 {
            id = rng.fast(0x15, 0x32)
        }
        var record = try files.level(id)
        record.words = Self.loadLevelWords(record.words)
        let poolSum = record.words[18...23].reduce(0) { $0 + Int($1) }
        if poolSum != Int(record.words[6]) {
            pendingStops.insert(.originalWouldAbort("LocationError 0x7de/1: LEVL \(id) pool sum \(poolSum) != w6"))
        }
        levelRecord = record
    }

    /// `_ResetBlocks @ 0001b90e`: clear each slot's state byte, `_gNumActiveBlocks = 0`, `gJewelsDone = 0`,
    /// `gJewelAnimDir = 1`, `gNumNormalBlocks = 100` (the sentinel — C6).
    mutating func resetBlocks() {
        for i in blocks.indices { blocks[i].state = 0 }
        numActiveBlocks = 0
        jewelsDone = false
        jewelAnimDir = true
        numNormalBlocks = 100
    }

    /// `_ResetHurtBlockList @ 0001b6b9`: clear every entry's active byte.
    mutating func resetHurtBlockList() {
        for i in hurtBlocks.indices { hurtBlocks[i].active = false }
    }

    /// `_TimeBonus_Reset @ 00006930`: level < 5 → 2500; < 10 → 3000; < 15 → 3500; else 4000. Timer and flash timer =
    /// frame, flash off.
    mutating func timeBonusReset() {
        if level < 5 {
            timeBonus = 0x9c4
        } else if level < 10 {
            timeBonus = 3000
        } else {
            timeBonus = 0xdac
            if 0xe < level { timeBonus = 4000 }
        }
        timeBonusTimer = frame
        timeBonusFlash = false
        timeBonusFlashTimer = frame
    }

    /// `_LoadMaze @ 0002626e`: `gMaze` and `gMazeCopy` both become the MAZE resource (0xb0 bytes).
    mutating func loadMaze(_ id: Int, files: BTXResourceFiles) throws {
        let loaded = try files.maze(id)
        maze = loaded
        mazeCopy = loaded
    }

    /// `_InitHero @ 000217b3`: state 1, stateStart = frame, invisibility off (+0x50) with its start (+0x52) = frame,
    /// speed-up off (+0x5f), trap off (+0x4c) with its start (+0x4e) = frame, last-bubble frame (+0x0c) = frame,
    /// speed 5 (+0x66), push flag off (+0x40), then `_ResetHeroPosition`. (Reserve-hero display fields omitted.)
    mutating func initHero() {
        hero.state = 1
        hero.stateStart = frame
        hero.invisible = false
        hero.invisibleStart = frame
        hero.speedUp = false
        hero.trapped = false
        hero.trapStart = frame
        hero.lastBubbleFrame = frame
        hero.speed = 5
        hero.frozen = false
        resetHeroPosition()
    }

    /// `_ResetHeroPosition @ 0002165f` (Research note 13): (7,6) if `gMaze[0x67] == 0`; else the first empty cell of
    /// rows 5…7 × cols 6…8 (row-major); else the first cell of that scan that is not a jewel (0x14) or cluster
    /// (0x1e); else the original quits ("can't find good starting loc") → `.originalWouldAbort`, position unchanged.
    /// Then aligned, offsets 0, `+0x3a = RT3_IsRegistered()`, rect = prevRect = cell, facing 3, sprite set 1,
    /// frame 3, push flag, death-bubble flag and trap cleared.
    mutating func resetHeroPosition() {
        if maze.cells[0x67] == 0 {
            hero.col = 7
            hero.row = 6
        } else if let cell = heroStartScan({ $0 == CellCode.empty })
                    ?? heroStartScan({ $0 != CellCode.jewel && $0 != CellCode.cluster }) {
            hero.col = cell.col
            hero.row = cell.row
        } else {
            pendingStops.insert(.originalWouldAbort("ResetHeroPosition: can't find good starting loc"))
        }
        hero.aligned = true
        hero.xOffset = 0
        hero.registered = config.registeredValidLicence
        hero.yOffset = 0
        hero.rect = QDRect.cell(col: Int(hero.col), row: Int(hero.row))
        hero.prevRect = hero.rect
        hero.facing = .left
        hero.spriteSet = 1
        hero.spriteFrame = 3
        hero.frozen = false
        hero.deathBubblesEmitted = false
        hero.trapped = false
    }

    /// The 3×3 start scan of `_ResetHeroPosition`: rows 5…7, cols 6…8, row-major.
    private func heroStartScan(_ accept: (UInt8) -> Bool) -> CellRef? {
        for row in 5...7 {
            for col in 6...8 where accept(maze[col, row]) {
                return CellRef(col: Int8(col), row: Int8(row))
            }
        }
        return nil
    }

    /// `_PositionJewels @ 0001c6a6`: `gJewelFound = 0`, target (0xff, 0xff), `gJewelCount = 0`, `gNumJewels` = the
    /// clamped LEVL w12, then `_PositionSingleJewel(j)` for each jewel (2 draws each).
    mutating func positionJewels() {
        jewelFound = false
        targetJewel = nil
        jewelCount = 0
        numJewels = Int(Int8(truncatingIfNeeded: levelRecord.words[12]))
        var j = 0
        while j < numJewels {
            positionSingleJewel(j)
            j += 1
        }
    }

    /// `_PositionSingleJewel @ 0001c544` (Research note 14): `c = GetRandomFast(1,14); r = GetRandomFast(1,9)`, then
    /// walk until a normal bubble (10) is accepted. Rejected: (7,6); any jewel (0x14) in row r while `tries < 151`;
    /// any jewel in column c while `tries < 151`. Advance: while `tries < 501` cols 1…14 × rows 1…9 (wrapping), after
    /// that the whole grid. Only jewels block — not clusters. `tries` is the original's `short` (wraps; a level with
    /// fewer candidate cells than jewels loops forever, as the original does).
    mutating func positionSingleJewel(_ index: Int) {
        var c = Int8(truncatingIfNeeded: rng.fast(1, 0xe))
        var r = Int8(truncatingIfNeeded: rng.fast(1, 9))
        var tries: Int16 = 0
        while true {
            tries &+= 1
            if maze[Int(c), Int(r)] == CellCode.normal {
                var reject = c == 7 && r == 6
                for col in 0..<Maze.columns where maze[col, Int(r)] == CellCode.jewel {
                    if tries < 0x97 { reject = true }
                    break
                }
                var columnHit = false
                for row in 0..<Maze.rows where maze[Int(c), row] == CellCode.jewel {
                    if tries < 0x97 { columnHit = true }
                    break
                }
                if !columnHit && !reject {
                    maze[Int(c), Int(r)] = CellCode.jewel
                    jewelCells[index] = CellRef(col: c, row: r)
                    return
                }
            }
            if tries < 0x1f5 {
                c += 1
                if 0xe < c {
                    r += 1
                    c = 1
                    if r >= 10 { r = 1 }
                }
            } else {
                c += 1
                if 0xf < c {
                    r += 1
                    c = 0
                    if r >= 11 { r = 0 }
                }
            }
        }
    }

    /// `_InitEnemies @ 0001111b`: clear each slot's state byte and record `RT3_IsRegistered()` per slot
    /// (`gREGCHECK1registered`); `gNumEnemiesSquished = 0`, `gNumEnemiesActive = 0` (the per-slot decrement is
    /// overwritten), `gEnemy_LastColour = 1`.
    mutating func initEnemies() {
        for i in enemies.indices {
            enemies[i].state = 0
            enemyRegistered[i] = config.registeredValidLicence
        }
        numEnemiesSquished = 0
        numEnemiesActive = 0
        enemyLastColour = 1
    }

    /// `_Balloons_Init @ 00024260`: clear each slot's state byte; `_gBalloons_NumActive = 0`.
    mutating func balloonsInit() {
        for i in balloons.indices { balloons[i].state = 0 }
        numActiveBalloons = 0
    }

    /// `_Bonus_Init @ 00019734` (Research note 17), in its exact draw order: `slot0.armed = 1`,
    /// `slot1.armed = GetRandomFast(0,100) < 0x32`; `gBonus_NumEnemiesSquishedAtOnce` zeroed on level 1 only; always
    /// `slot0.launch = (0xdc,600)`, `slot1.launch = (0x1c2,0x3b6)`; per armed slot: fields reset, `left =
    /// (0x46,0x212)`, rect (440, left, 480, left + 40), `type = (1,14)` with 3 → 14 and 5…8 → `(9,13)`; type 14 draws
    /// its value index by level ((0,1) L<3, (0,2) L<6, (1,3) L<11, else (2,6)) into 500…5000 (icon frame 0xe + index);
    /// then 21 × `(0,4)` drift; multiplier/EXTRA animation reset. The value switch's `default` returns from the whole
    /// function (skipping the drift table) — unreachable with these ranges, replicated.
    mutating func bonusInit() {
        let currentLevel = level
        bonus[0].armed = true
        bonus[1].armed = rng.fast(0, 100) < 0x32
        if currentLevel == 1 { bonusSquishedAtOnce = 0 }
        bonus[0].launchFrame = UInt16(truncatingIfNeeded: rng.fast(0xdc, 600))
        bonus[1].launchFrame = UInt16(truncatingIfNeeded: rng.fast(0x1c2, 0x3b6))
        for i in bonus.indices where bonus[i].armed {
            var b = bonus[i]
            b.dead = false
            b.popped = false
            b.poppedFrame = frame
            b.visible = true
            b.riseSpeed = 2
            b.snakeIndex = 0
            b.timeValue = -1
            b.animTimer = frame
            b.shellFrame = 1
            let left = Int16(truncatingIfNeeded: rng.fast(0x46, 0x212))
            b.rect = QDRect(top: 0x1b8, left: left, bottom: 0x1e0, right: left &+ 0x28)
            b.prevRect = b.rect
            b.type = Int16(truncatingIfNeeded: rng.fast(1, 0xe))
            var timeValueBonus = false
            if b.type < 9 {
                if b.type < 5 {
                    if b.type == 3 {
                        b.type = 0xe
                        timeValueBonus = true
                    }
                } else {
                    b.type = Int16(truncatingIfNeeded: rng.fast(9, 0xd))
                }
            } else if b.type == 0xe {
                timeValueBonus = true
            }
            if timeValueBonus {
                let range: (lo: Int, hi: Int)
                if currentLevel < 3 {
                    range = (0, 1)
                } else if currentLevel < 6 {
                    range = (0, 2)
                } else if currentLevel < 0xb {
                    range = (1, 3)
                } else {
                    range = (2, 6)
                }
                let index = rng.fast(range.lo, range.hi)
                let values: [Int16] = [500, 800, 1000, 2000, 3000, 4000, 5000]
                guard index < values.count else {           // switchD_000198f9_default: return
                    bonus[i] = b
                    return
                }
                b.timeValue = values[index]
                b.iconFrame = Int16(0xe + index)
            }
            b.iconSet = 0x1a
            if b.type != 0xe { b.iconFrame = b.type }
            bonus[i] = b
        }
        for k in bonusDrift.indices {
            bonusDrift[k] = Int16(truncatingIfNeeded: rng.fast(0, 4))
        }
        bonusDriftIndex = 0
        multiplierAnimating = false
        multiplierTimer = frame
        multiplierAnimCounter = 0
        extraAnimating = false
        extraTimer = frame
        extraAnimCounter = 0
    }
}

// The frame step (plan §Task 10.1; Invariants 5, 8, 9, 14; Research notes 19–21), transcribed from one iteration of
// `_PlayGame @ 00018247`'s `do { … } while (true)` loop, with `_FinishLevel @ 00010eb7`, `_SubtractLife @ 0001058a`,
// `_AreAllEnemiesSquished @ 00010e9b`, `_SetHeroSpeed @ 00021c31` and the freeing halves of the draw pass
// (`_DrawHurtBlocksToComp @ 0001b8b1`, `_DrawHeroToComp @ 00022b8b`, `_DrawEnemiesToComp @ 00011170`,
// `_Balloons_DrawToComp @ 00024280`, `_DrawBlocksToComp @ 0001c315`, `_Splats_DrawToComp @ 00002c79`,
// `_Bonus_Draw @ 00019a94`, `_DrawStarsToComp`, `_DrawPointsToComp`, `_Bubbles_DrawToComp`).
//
// Not modelled (no RNG, no simulation state): the timer/event wait, `_ResetNumBgndRects`/`_ResetNumScrnRects`, sounds,
// music, notices, reserve-hero/score/time-bonus drawing, `_EraseOuch`/`_DrawOuchToComp`, the pause key (ignored in
// demo; Scope), the escape key, `_CheckForHacking`, the licence parity check and the Cmd-key `_CleanUp`.

/// What one `stepFrame` call leaves behind (plan §Task 10.1).
public struct FrameReport: Equatable, Sendable {
    /// `gFrameCounter` after this frame's increment.
    public let frame: UInt16
    /// RNG draws made during this frame.
    public let drawsThisFrame: Int
    /// `rng.drawCount` at the end of the frame.
    public let totalDraws: Int
    /// `gRecordingCounter` at the end of the frame.
    public let samplesConsumed: Int
    public let heroState: Int16
    public let heroCell: CellRef
    public let score: Int32
    public let lives: Int16
    /// `_HeroCaught` ran during this frame.
    public let heroCaughtThisFrame: Bool
    /// Every stop reason recorded so far (Invariant 14) — non-empty only on the final frame.
    public let stops: Set<StopReason>
    /// This frame's `_PlayMySnd` calls in order (plan 2026-10-04 btx-playable S2) — always empty until task C2.
    public let sounds: [SoundCue]
    /// This frame's QuickDraw calls in order (S2) — always empty until task C3. Replays ignore both fields.
    public let drawOps: [DrawOp]

    init(frame: UInt16, drawsThisFrame: Int, totalDraws: Int, samplesConsumed: Int, heroState: Int16,
         heroCell: CellRef, score: Int32, lives: Int16, heroCaughtThisFrame: Bool, stops: Set<StopReason>,
         sounds: [SoundCue] = [], drawOps: [DrawOp] = []) {
        self.frame = frame
        self.drawsThisFrame = drawsThisFrame
        self.totalDraws = totalDraws
        self.samplesConsumed = samplesConsumed
        self.heroState = heroState
        self.heroCell = heroCell
        self.score = score
        self.lives = lives
        self.heroCaughtThisFrame = heroCaughtThisFrame
        self.stops = stops
        self.sounds = sounds
        self.drawOps = drawOps
    }
}

extension GameState {
    /// One `_PlayGame` loop iteration, in Research note 19's order. Returns the report; `playing` turns false when
    /// any stop fired (it takes effect before the next call — the caller stops calling).
    ///
    /// Order (`_PlayGame` 00018767–00018f4e): `frame &+= 1` → the hero state machine (state 2 → `_CheckNewEnemies`
    /// when `stateStart + 10 < frame`; 1 → appear; 3 → 4; 4 → stop/respawn) → (pause: not modelled) →
    /// `gNumNormalBlocks > 0` → recount, and 0 → +2000 ×mult, star group 2, point 12/12, `_FinishLevel` →
    /// `_Bubbles` → `_ProcessEnemies` → `_ProcessHero` → `_Splats_Process` → `_Bubbles_Process` →
    /// `_Balloons_Process` → `_Bonus_Process` → `_ProcessBlocks` → `_ProcessStars` → `_ProcessPoints` →
    /// `_TimeBonus_Process` → the draw pass (the only place slots are freed — Invariant 8) → the end-of-level check
    /// → the demo FILM-count check.
    ///
    /// A call made once `playing` is false (or with a stop already pending) is the loop-top `gPlayGame == 0` exit:
    /// nothing runs, the frame does not advance, and `playing` is false on return.
    public mutating func stepFrame<I: InputSource>(input: inout I) -> FrameReport {
        let drawsBefore = rng.drawCount
        guard playing, pendingStops.isEmpty else {
            playing = false
            return report(input: input, drawsBefore: drawsBefore)
        }
        heroCaughtThisFrame = false
        frame &+= 1                                              // gTimerFired = 0; gFrameCounter++ (u16, Invariant 9)

        runHeroStateMachine()

        // `if (0 < gNumNormalBlocks)`: recount; reaching 0 is the "all bubbles gone" award.
        if 0 < numNormalBlocks {
            numNormalBlocks = normalBlockCount()
            if numNormalBlocks == 0 {
                addToScore(2000, multiply: true)                 // _AddToScore(0x7d0, 1)
                stars.newGroup(x: Int16(hero.col) &* 0x28, y: Int16(hero.row) &* 0x28, group: 2, hero: heroAnchor,
                               frame: frame, prefs: config.prefs, rng: &rng)
                points.newPoint(x: hero.rect.left, y: hero.rect.top, sprite: 0xc, delay: 0xc, level: level,
                                notRegistered: config.pointsNotRegistered)
                finishLevel()
            }
        }

        var anchor = heroAnchor                                  // _Bubbles writes hero+0x0c back
        airBubbles.launch(frame: frame, hero: &anchor, prefs: config.prefs, rng: &rng)
        heroAnchor = anchor
        processEnemies()
        processHero(input: &input)
        splats.process(frame: frame)
        airBubbles.process(frame: frame)
        balloonsProcess()
        bonusProcess()
        processBlocks()
        stars.process(frame: frame)
        points.process()
        timeBonusProcess()

        if !runDrawPass() {
            pendingStops.insert(.originalWouldAbort("DrawPointsToComp: hacked-copy trap (StdError → ExitToShell)"))
            playing = false
            return report(input: input, drawsBefore: drawsBefore)
        }

        checkEndOfLevel()

        // `if (gGameMode == 1 && gRecording.count <= gRecordingCounter) gPlayGame = 0` — after the draw pass, since
        // `readSample` never guards the count itself.
        if mode == .demo && input.isExhausted {
            pendingStops.insert(.countExhausted)
        }

        if !pendingStops.isEmpty {
            playing = false
        }
        return report(input: input, drawsBefore: drawsBefore)
    }

    private func report<I: InputSource>(input: I, drawsBefore: Int) -> FrameReport {
        FrameReport(frame: frame, drawsThisFrame: rng.drawCount - drawsBefore, totalDraws: rng.drawCount,
                    samplesConsumed: input.samplesConsumed, heroState: hero.state,
                    heroCell: CellRef(col: hero.col, row: hero.row), score: score, lives: lives,
                    heroCaughtThisFrame: heroCaughtThisFrame, stops: pendingStops)
    }

    /// `_PlayGame`'s hero state machine at the top of the frame (Research note 20; 000187a7–000189a3). Timer tests
    /// promote to `Int` without wrapping (Invariant 9).
    ///
    /// - State 2: `if (hero+4 + 10 < frame) _CheckNewEnemies()` — this is the ONLY `_CheckNewEnemies` call site in the
    ///   loop (it is not a separate unconditional loop-top call); it precedes the normal-block recount and `_Bubbles`.
    /// - State 1: delay = lives < 1 ? 0x5f : (first ? 0x46 : 0x3c); when `stateStart + delay < frame`: lives < 1 →
    ///   `gPlayGame = 0` (every mode); else `gMaze[col + 16·row] = 0`, state 2, stateStart = frame, visible
    ///   (`+0x4a = 1`), `_SetHeroInvisibility(0)`, `_SetHeroSpeed(5)` (speed-up off, speed 5),
    ///   `_NewStarGroup(col·40, row·40, 0)`, `_Blocks_DeactivateRubberBlocks`. `first = false` either way.
    /// - State 3: `stateStart + 0x1e < frame` → state 4, stateStart = frame, `_SubtractLife`, `+0x3e` (sprite frame)
    ///   = 1, `+0x42` (freeze counter, the death-animation tick) = 0, `+0x48` (death counter) = 0,
    ///   `_MakeAllEnemiesDisappear`.
    /// - State 4: `stateStart + 0x41 < frame` → demo: `gPlayGame = 0`; play: state 1, stateStart = frame,
    ///   `_ResetHeroPosition` (clears the push/trap/death-bubble flags), `_Multiplier_Reset`. `heroKeys` persist.
    private mutating func runHeroStateMachine() {
        let now = frame
        switch hero.state {
        case 2:
            if Int(hero.stateStart) + 10 < Int(now) {
                checkNewEnemies()
            }
        case 1:
            let delay = lives < 1 ? 0x5f : (firstAppearance ? 0x46 : 0x3c)
            guard Int(hero.stateStart) + delay < Int(now) else { return }
            if lives < 1 {
                pendingStops.insert(.gameOverNoLives)
            } else {
                maze.cells[Int(hero.col) + Int(hero.row) * Maze.columns] = CellCode.empty
                hero.state = 2
                hero.stateStart = now
                hero.visible = true
                setHeroInvisibility(false)
                hero.speedUp = false                            // _SetHeroSpeed(5)
                hero.speed = 5
                stars.newGroup(x: Int16(hero.col) &* 0x28, y: Int16(hero.row) &* 0x28, group: 0, hero: heroAnchor,
                               frame: now, prefs: config.prefs, rng: &rng)
                blocksDeactivateRubberBlocks()
            }
            firstAppearance = false
        case 3:
            guard Int(hero.stateStart) + 0x1e < Int(now) else { return }
            hero.state = 4
            hero.stateStart = now
            subtractLife()
            hero.spriteFrame = 1
            hero.freezeCounter = 0
            hero.deathCounter = 0
            makeAllEnemiesDisappear()
        case 4:
            guard Int(hero.stateStart) + 0x41 < Int(now) else { return }
            switch mode {
            case .demo:
                pendingStops.insert(.heroDeathAnimationDone)
            case .play:
                hero.state = 1
                hero.stateStart = now
                resetHeroPosition()
                multiplierReset()
            }
        default:
            break
        }
    }

    /// `_FinishLevel @ 00010eb7`: `gNumEnemiesSquished = (char)level.w6`.
    mutating func finishLevel() {
        numEnemiesSquished = Int8(truncatingIfNeeded: levelRecord.words[6])
    }

    /// `_SubtractLife @ 0001058a`: `gStackLives -= 1` (the `gELives` mirror is not modelled).
    mutating func subtractLife() {
        lives &-= 1
    }

    /// `_AreAllEnemiesSquished @ 00010e9b`: `level.w6 <= (short)gNumEnemiesSquished` (signed `char` widened).
    func areAllEnemiesSquished() -> Bool {
        levelRecord.words[6] <= Int16(numEnemiesSquished)
    }

    /// The non-drawing half of `_PlayGame`'s draw pass, in call order (Invariant 8: the only place slots are freed).
    /// Returns false when `_DrawPointsToComp`'s trap fired (the original exits inside the pass — nothing after runs).
    private mutating func runDrawPass() -> Bool {
        // _DrawHurtBlocksToComp @ 0001b8b1: every active entry is drawn and cleared.
        for i in hurtBlocks.indices where hurtBlocks[i].active {
            hurtBlocks[i].active = false
        }
        // _DrawHeroToComp @ 00022b8b: `+0x1c = +0x14` unconditionally (every state).
        hero.prevRect = hero.rect
        // _DrawEnemiesToComp @ 00011170: per non-free slot 0…29, dead (`+0x47`) → state 0 and gNumEnemiesActive--;
        // else prevRect = rect.
        for i in enemies.indices where enemies[i].state != 0 {
            if enemies[i].dead {
                enemies[i].state = 0
                numEnemiesActive &-= 1
            } else {
                enemies[i].prevRect = enemies[i].rect
            }
        }
        // _Balloons_DrawToComp @ 00024280 (skipped when `_gBalloons_NumActive == 0`): per non-free slot, a visible
        // balloon loses `+0x20` when its BOX (`+0x24` top/`+0x26` left/`+0x28` bottom/`+0x2a` right — the decompile
        // tests `+0x26 < 0`, `0x280 < +0x2a`, `+0x24 < 0`, `0x1b8 < +0x28`, not the sprite rect at +0x08) leaves
        // 0…640 × 0…440; then dead (`+0x21`) → state 0 and NumActive--, else prevRect = rect.
        if numActiveBalloons != 0 {
            for i in balloons.indices where balloons[i].state != 0 {
                if balloons[i].visible {
                    let box = balloons[i].box
                    if box.left < 0 || 0x280 < box.right || box.top < 0 || 0x1b8 < box.bottom {
                        balloons[i].visible = false
                    }
                }
                if balloons[i].dead {
                    balloons[i].state = 0
                    numActiveBalloons -= 1
                } else {
                    balloons[i].prevRect = balloons[i].rect
                }
            }
        }
        // _DrawBlocksToComp @ 0001c315 (skipped when `_gNumActiveBlocks == 0`): per non-free slot 0…34, prevRect =
        // rect, then retired (`+0x28`) → state 0 and `_gNumActiveBlocks--`.
        if numActiveBlocks != 0 {
            for i in blocks.indices where blocks[i].state != 0 {
                blocks[i].prevRect = blocks[i].rect
                if blocks[i].retired {
                    blocks[i].state = 0
                    numActiveBlocks -= 1
                }
            }
        }
        splats.drawPassFree()                                    // _Splats_DrawToComp @ 00002c79
        // _Bonus_Draw @ 00019a94: per armed slot 0…1, dead (`+1`) → armed (`+0`) = 0, else prevRect = rect.
        // `_Bonus_DoesHeroTouch`/`_Bonus_WasHit` do not test `dead`, so this unarming is load-bearing.
        for i in bonus.indices where bonus[i].armed {
            if bonus[i].dead {
                bonus[i].armed = false
            } else {
                bonus[i].prevRect = bonus[i].rect
            }
        }
        stars.drawPassFree()                                     // _DrawStarsToComp
        if points.drawPass(rng: &rng) {                          // _DrawPointsToComp — the only draw-pass RNG site
            return false
        }
        airBubbles.drawPassFree()                                // _Bubbles_DrawToComp
        return true
    }

    /// `_PlayGame`'s end-of-level block (00018cb4–00018ea4; Research note 21). Not yet at the end and hero state
    /// 1/2 → `_AreAllEnemiesSquished` sets `gIsEndOfLevel` with `gEndOfLevelTime = frame`; then (state 1/2) lives > 0,
    /// `gIsEndOfLevel` and `gEndOfLevelTime + 0x46 < frame` → demo: `gPlayGame = 0`; play: time and flag cleared,
    /// `_EXTRA_Reset` only while `gEXTRA_Animate` is set — the rest of the play-mode transition
    /// (`_TimeBonus_CountDown`, the licence-table draw, the unregistered level-7 stop, `_NewLevel`) is deferred to
    /// the play-loop plan (Known delta 7).
    private mutating func checkEndOfLevel() {
        let inPlay = hero.state == 1 || hero.state == 2        // `(ushort)(state - 1) < 2`
        guard inPlay else { return }
        if !isEndOfLevel && areAllEnemiesSquished() {
            endOfLevelTime = frame
            isEndOfLevel = true
        }
        guard 0 < lives, isEndOfLevel, Int(endOfLevelTime) + 0x46 < Int(frame) else { return }
        switch mode {
        case .demo:
            pendingStops.insert(.levelCompleted)
        case .play:
            endOfLevelTime = 0
            isEndOfLevel = false
            if extraAnimating {
                extraReset()
            }
        }
    }
}

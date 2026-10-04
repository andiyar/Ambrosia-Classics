// The frame step (plan §Task 10.1; Invariants 5, 8, 9, 14; Research notes 19–21), transcribed from one iteration of
// `_PlayGame @ 00018247`'s `do { … } while (true)` loop, with `_FinishLevel @ 00010eb7`, `_SubtractLife @ 0001058a`,
// `_AreAllEnemiesSquished @ 00010e9b`, `_SetHeroSpeed @ 00021c31` and the freeing halves of the draw pass
// (`_DrawHurtBlocksToComp @ 0001b8b1`, `_DrawHeroToComp @ 00022b8b`, `_DrawEnemiesToComp @ 00011170`,
// `_Balloons_DrawToComp @ 00024280`, `_DrawBlocksToComp @ 0001c315`, `_Splats_DrawToComp @ 00002c79`,
// `_Bonus_Draw @ 00019a94`, `_DrawStarsToComp`, `_DrawPointsToComp`, `_Bubbles_DrawToComp`).
//
// Sounds: every `_PlayMySnd` site of the loop body (`Sounds.swift` lists them) and `_Sounds_CheckDelayedSounds` after
// `_TimeBonus_Process` fill `FrameReport.sounds` (plan 2026-10-04 btx-playable C2).
//
// Draw ops: the OS X draw pass, `_ResetNumBgndRects`, the notices set in the frame, `_EraseNotice`, `_EraseOuch` /
// `_DrawOuchToComp` and the pause check (00018a7e) fill `FrameReport.drawOps` / `.pauseRestoreNotice` (C3 —
// `DrawOps.swift`, `HUD.swift`). Not modelled here (the session's — C4): the timer/event wait, music, the escape key,
// `_PauseGame` itself; nor `_CheckForHacking`, the licence parity check and the Cmd-key `_CleanUp`.

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
    /// This frame's `ST_PlaySound` calls in call order (plan 2026-10-04 btx-playable S2, C2): every immediate
    /// `_PlayMySnd` plus every delayed one `_Sounds_CheckDelayedSounds` released this frame. Each plays now.
    public let sounds: [SoundCue]
    /// This frame's QuickDraw calls in order (S2) — always empty until task C3. Replays ignore both fields.
    public let drawOps: [DrawOp]
    /// The pause check at 00018a7e fired this frame (play only): `_PauseGame` is due after the frame, restoring this
    /// notice (`local_e9`); nil = no pause.
    public let pauseRestoreNotice: Int?

    init(frame: UInt16, drawsThisFrame: Int, totalDraws: Int, samplesConsumed: Int, heroState: Int16,
         heroCell: CellRef, score: Int32, lives: Int16, heroCaughtThisFrame: Bool, stops: Set<StopReason>,
         sounds: [SoundCue] = [], drawOps: [DrawOp] = [], pauseRestoreNotice: Int? = nil) {
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
        self.pauseRestoreNotice = pauseRestoreNotice
    }
}

extension GameState {
    /// One `_PlayGame` loop iteration, in Research note 19's order. Returns the report; `playing` turns false when
    /// any stop fired (it takes effect before the next call — the caller stops calling).
    ///
    /// Order (`_PlayGame` 00018767–00018f4e): `frame &+= 1` → the hero state machine (state 2 → `_CheckNewEnemies`
    /// when `stateStart + 10 < frame`; 1 → appear; 3 → 4; 4 → stop/respawn) → the pause check (play only) →
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
        soundsThisFrame = []
        presentation.ops = []
        guard playing, pendingStops.isEmpty else {
            playing = false
            return report(input: input, drawsBefore: drawsBefore, pause: nil)
        }
        heroCaughtThisFrame = false
        frame &+= 1                                              // gTimerFired = 0; gFrameCounter++ (u16, Invariant 9)
        presentation.bgndRects = []                              // _ResetNumBgndRects (_ResetNumScrnRects: unused on OS X)

        runHeroStateMachine()

        // 00018a7e: `_PauseKey() || local_ea` → (not demo) `local_e9 = _GetCurrentNotice()`, `_PrepareNotice(3)`,
        // `bVar2` — `_PauseGame` runs at the end of this loop iteration (the session's).
        var pauseRestoreNotice: Int?
        if input.pauseRequested && mode != .demo {
            pauseRestoreNotice = notices.current
            prepareNotice(3)
        }

        // `if (0 < gNumNormalBlocks)`: recount; reaching 0 is the "all bubbles gone" award.
        if 0 < numNormalBlocks {
            numNormalBlocks = normalBlockCount()
            if numNormalBlocks == 0 {
                playMySnd(0x21, priority: 0x14)                  // 00018af5 "All Jewels Joined"
                addToScore(2000, multiply: true)                 // _AddToScore(0x7d0, 1)
                stars.newGroup(x: Int16(hero.col) &* 0x28, y: Int16(hero.row) &* 0x28, group: 2, hero: heroAnchor,
                               frame: frame, prefs: config.prefs, rng: &rng)
                points.newPoint(x: hero.rect.left, y: hero.rect.top, sprite: 0xc, delay: 0xc, level: level,
                                notRegistered: config.pointsNotRegistered)
                finishLevel()
            }
        }

        var anchor = heroAnchor                                  // _Bubbles writes hero+0x0c back
        let bubbleSound = airBubbles.launch(frame: frame, hero: &anchor, prefs: config.prefs, rng: &rng)
        heroAnchor = anchor
        if let bubbleSound {                                     // _Bubbles_NewGroup's tail `jmp _PlayMySnd`
            playMySnd(bubbleSound.slot, priority: bubbleSound.priority)
        }
        processEnemies()
        processHero(input: &input)
        splats.process(frame: frame)
        // _Splats_Process 00002c47: every active slot, `_AddRectToBgnd(prevRect)`.
        for s in splats.slots where s.active { addRectToBgnd(s.prevRect) }
        let bubblesToRestore = airBubbles.activeCount == 0 ? [] : airBubbles.slots.indices.filter {
            airBubbles.slots[$0].active && !airBubbles.slots[$0].delayed
        }
        airBubbles.process(frame: frame)
        // _Bubbles_Process 00016cbc: every active slot that was not delayed on entry, `_AddRectToBgnd(prevRect)`.
        for i in bubblesToRestore { addRectToBgnd(airBubbles.slots[i].prevRect) }
        balloonsProcess()
        bonusProcess()
        processBlocks()
        let starsToRestore = stars.activeCount == 0 ? [] : stars.slots.indices.filter {
            stars.slots[$0].active && !stars.slots[$0].delayed
        }
        stars.process(frame: frame)
        // _ProcessStars 00004d9c: every active slot not delayed on entry, `_AddRectToBgnd(prevRect)`.
        for i in starsToRestore { addRectToBgnd(stars.slots[i].prevRect) }
        let pointsToRestore = points.activeCount == 0 ? [] : points.slots.indices.filter {
            points.slots[$0].active && !points.slots[$0].delayed
        }
        points.process()
        // _ProcessPoints 0000261e: every active slot not delayed on entry, `_AddRectToBgnd(rect)` (after the rise).
        for i in pointsToRestore { addRectToBgnd(points.slots[i].rect) }
        timeBonusProcess()
        soundsCheckDelayedSounds()                               // _Sounds_CheckDelayedSounds @ 000268a1
        eraseNotice()                                            // _EraseNotice @ 0002784e

        if !runDrawPass() {
            pendingStops.insert(.originalWouldAbort("DrawPointsToComp: hacked-copy trap (StdError → ExitToShell)"))
            playing = false
            return report(input: input, drawsBefore: drawsBefore, pause: pauseRestoreNotice)
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
        return report(input: input, drawsBefore: drawsBefore, pause: pauseRestoreNotice)
    }

    /// Builds the report and empties the frame's op buffer (the report owns them; nothing can re-read them stale).
    private mutating func report<I: InputSource>(input: I, drawsBefore: Int, pause: Int?) -> FrameReport {
        defer { presentation.ops = [] }
        return FrameReport(frame: frame, drawsThisFrame: rng.drawCount - drawsBefore, totalDraws: rng.drawCount,
                    samplesConsumed: input.samplesConsumed, heroState: hero.state,
                    heroCell: CellRef(col: hero.col, row: hero.row), score: score, lives: lives,
                    heroCaughtThisFrame: heroCaughtThisFrame, stops: pendingStops, sounds: soundsThisFrame,
                    drawOps: presentation.ops, pauseRestoreNotice: pause)
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
                if mode != .demo {
                    prepareNotice(0)                             // 0001888e
                }
                requestDrawReserveHero(animate: false)           // 0001889a
                stars.newGroup(x: Int16(hero.col) &* 0x28, y: Int16(hero.row) &* 0x28, group: 0, hero: heroAnchor,
                               frame: now, prefs: config.prefs, rng: &rng)
                if mode != .demo {
                    playMySnd(8, priority: 0x14)                 // 000188ef "Hahohaho"
                }
                playMySnd(0x1b, priority: 10)                    // 0001890b "Bubbles"
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
            playMySnd(0x22, priority: 0x14)                      // 0001898d "Hero Death Groan" (every mode)
            requestDrawReserveHero(animate: true)                // 0001899e
            eraseOuch()                                          // 000189a3
        case 4:
            guard Int(hero.stateStart) + 0x41 < Int(now) else { return }
            switch mode {
            case .demo:
                pendingStops.insert(.heroDeathAnimationDone)
            case .play:
                hero.state = 1
                hero.stateStart = now
                resetHeroPosition()
                multiplierReset(draw: true)                      // 00018a0f `_Multiplier_Reset(1)`
                if lives < 1 {
                    prepareNotice(2)                             // 00018a5d FIN!
                    playMySnd(3, priority: 0x1e)                 // 00018a74 "Game Over!"
                } else if !isEndOfLevel {
                    playMySnd(2, priority: 0x14)                 // 00018a3e "Get Ready!"
                    prepareNotice(1)                             // 00018a4f GET READY!
                }
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

    /// `_PlayGame`'s draw pass, in call order (00018bac–00018c2b; Invariant 8: the only place slots are freed), with
    /// each routine's QuickDraw calls recorded BEFORE its slot is freed (Invariant 2; OS X path — `DrawOps.swift`):
    /// `_RestoreBgnd(0)` → hurt blocks → hero → enemies → balloons → blocks → splats → bonus → stars → "Erk!" → points
    /// → air bubbles → `_DrawScore(0)` → `_TimeBonus_Draw(0)` → `_DrawReserveInfo` → `_DrawNotice`. A slot freed in
    /// this pass is drawn on its freeing frame exactly when its routine's own flag says so: enemies test only the
    /// drawn flag (a dead-but-drawn enemy IS plotted once more), balloons / bonus / splats / stars / points / air
    /// bubbles test their visible flag (which their deaths clear, so they are not), blocks test only the sprite set.
    /// Returns false when `_DrawPointsToComp`'s trap fired (the original exits inside the pass — nothing after runs).
    private mutating func runDrawPass() -> Bool {
        restoreBgndToScreen()                                    // _RestoreBgnd(0) after _SetToScreen
        // _DrawHurtBlocksToComp @ 0001b8b1: every active entry is drawn (set +8, frame +0xa at +4, +2) and cleared.
        for i in hurtBlocks.indices where hurtBlocks[i].active {
            let b = hurtBlocks[i]
            spriteToComp(Int(b.spriteSet), Int(b.frame), h: Int(b.left), v: Int(b.top), target: .screen)
            hurtBlocks[i].active = false
        }
        // _DrawHeroToComp @ 00022b8b: states 2/3 → visible (+0x4a) → `_SpriteToComp`, or `_TransSpriteToComp` while
        // drawing transparent (+0x51); state 4 → while the death counter (+0x48) < 16 and visible → `_SpriteToComp`.
        // Then `+0x1c = +0x14` unconditionally (every state).
        switch hero.state {
        case 2, 3:
            if hero.visible {
                if hero.drawTransparent {
                    transSpriteToComp(Int(hero.spriteSet), Int(hero.spriteFrame), h: Int(hero.rect.left),
                                      v: Int(hero.rect.top), target: .screen)
                } else {
                    spriteToComp(Int(hero.spriteSet), Int(hero.spriteFrame), h: Int(hero.rect.left),
                                 v: Int(hero.rect.top), target: .screen)
                }
            }
        case 4:
            if hero.deathCounter < 0x10 && hero.visible {
                spriteToComp(Int(hero.spriteSet), Int(hero.spriteFrame), h: Int(hero.rect.left),
                             v: Int(hero.rect.top), target: .screen)
            }
        default:
            break
        }
        hero.prevRect = hero.rect
        // _DrawEnemiesToComp @ 00011170: per non-free slot 0…29, drawn (+0x46) → sprite (set +0x3a, frame +0x40);
        // then dead (`+0x47`) → state 0 and gNumEnemiesActive--; else prevRect = rect.
        for i in enemies.indices where enemies[i].state != 0 {
            if enemies[i].drawn {
                spriteToComp(Int(enemies[i].spriteSet), Int(enemies[i].animFrame), h: Int(enemies[i].rect.left),
                             v: Int(enemies[i].rect.top), target: .screen)
            }
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
        // 0…640 × 0…440, and one still visible is drawn (set +0x1a, frame +0x1c); then dead (`+0x21`) → state 0 and
        // NumActive--, else prevRect = rect.
        if numActiveBalloons != 0 {
            for i in balloons.indices where balloons[i].state != 0 {
                if balloons[i].visible {
                    let box = balloons[i].box
                    if box.left < 0 || 0x280 < box.right || box.top < 0 || 0x1b8 < box.bottom {
                        balloons[i].visible = false
                    }
                    if balloons[i].visible {
                        spriteToComp(Int(balloons[i].spriteSet), Int(balloons[i].frame),
                                     h: Int(balloons[i].rect.left), v: Int(balloons[i].rect.top), target: .screen)
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
        // _DrawBlocksToComp @ 0001c315 (skipped when `_gNumActiveBlocks == 0`): per non-free slot 0…34, set (+0x1e)
        // ≠ −1 → sprite (frame +0x20); prevRect = rect, then retired (`+0x28`) → state 0 and `_gNumActiveBlocks--`.
        if numActiveBlocks != 0 {
            for i in blocks.indices where blocks[i].state != 0 {
                if blocks[i].spriteSet != -1 {
                    spriteToComp(Int(blocks[i].spriteSet), Int(blocks[i].frame), h: Int(blocks[i].rect.left),
                                 v: Int(blocks[i].rect.top), target: .screen)
                }
                blocks[i].prevRect = blocks[i].rect
                if blocks[i].retired {
                    blocks[i].state = 0
                    numActiveBlocks -= 1
                }
            }
        }
        // _Splats_DrawToComp @ 00002c79: per active slot 0…11, visible (+0x1c) → sprite (set +0x16, frame +0x18).
        for s in splats.slots where s.active && s.visible {
            spriteToComp(Int(s.spriteSet), Int(s.frame), h: Int(s.rect.left), v: Int(s.rect.top), target: .screen)
        }
        splats.drawPassFree()
        // _Bonus_Draw @ 00019a94: per armed slot 0…1, visible (+3) and the rect inside 0…640 × 0…440 → the icon
        // (set +0x1a, frame +0x1c), then — not popped — the shell (set 0x19, frame +0x20); then dead (`+1`) →
        // armed (`+0`) = 0, else prevRect = rect. `_Bonus_DoesHeroTouch`/`_Bonus_WasHit` do not test `dead`, so
        // this unarming is load-bearing.
        for i in bonus.indices where bonus[i].armed {
            let b = bonus[i]
            if b.visible && 0 <= b.rect.left && b.rect.right < 0x281 && 0 <= b.rect.top && b.rect.bottom < 0x1b9 {
                spriteToComp(Int(b.iconSet), Int(b.iconFrame), h: Int(b.rect.left), v: Int(b.rect.top),
                             target: .screen)
                if !b.popped {
                    spriteToComp(0x19, Int(b.shellFrame), h: Int(b.rect.left), v: Int(b.rect.top), target: .screen)
                }
            }
            if bonus[i].dead {
                bonus[i].armed = false
            } else {
                bonus[i].prevRect = bonus[i].rect
            }
        }
        // _DrawStarsToComp @ 00004de0 (skipped when NumActive == 0): per active slot 0…59, visible (+0x25) and the
        // rect inside 0…640 × 0…440 → kind 7 `_TransSpriteToComp`, else `_SpriteToComp` (set +0x1c, frame +0x1e).
        if stars.activeCount != 0 {
            for s in stars.slots where s.active && s.visible {
                guard 0 <= s.rect.left, s.rect.right <= 0x280, 0 <= s.rect.top, s.rect.bottom <= 0x1b8 else { continue }
                if s.kind == 7 {
                    transSpriteToComp(Int(s.spriteSet), Int(s.frame), h: Int(s.rect.left), v: Int(s.rect.top),
                                      target: .screen)
                } else {
                    spriteToComp(Int(s.spriteSet), Int(s.frame), h: Int(s.rect.left), v: Int(s.rect.top),
                                 target: .screen)
                }
            }
        }
        stars.drawPassFree()
        drawOuch()                                               // _DrawOuchToComp @ 00022d03
        // _DrawPointsToComp @ 00002641 (skipped when NumActive == 0): per active slot 0…7, visible (+0x15) → sprite
        // (set +0xa, frame +0xc) at (+4, +2); then the trap draw and the free (`PointPool.drawPass`).
        if points.activeCount != 0 {
            for p in points.slots where p.active && p.visible {
                spriteToComp(Int(p.spriteSet), Int(p.frame), h: Int(p.rect.left), v: Int(p.rect.top), target: .screen)
            }
        }
        if points.drawPass(rng: &rng) {                          // _DrawPointsToComp — the only draw-pass RNG site
            return false
        }
        // _Bubbles_DrawToComp @ 00016d25 (skipped when NumActive == 0): per active slot 0…7, visible (+0x20) and the
        // rect inside 0…640 × 0…440 → sprite (set +0x1c, frame +0x1e).
        if airBubbles.activeCount != 0 {
            for b in airBubbles.slots where b.active && b.visible {
                guard 0 <= b.rect.left, b.rect.right < 0x281, 0 <= b.rect.top, b.rect.bottom < 0x1b9 else { continue }
                spriteToComp(Int(b.spriteSet), Int(b.frame), h: Int(b.rect.left), v: Int(b.rect.top), target: .screen)
            }
        }
        airBubbles.drawPassFree()
        drawScore(force: false)                                  // _DrawScore(0) @ 00018c15
        timeBonusDraw(force: false)                              // _TimeBonus_Draw(0) @ 00018c21
        drawReserveInfo()                                        // _DrawReserveInfo @ 00018c26
        drawNotice()                                             // _DrawNotice @ 00018c2b
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
            if mode != .demo {
                playMySnd(0x23, priority: 0x1e)                  // 00018d19 "End of Level"
            }
        }
        guard 0 < lives, isEndOfLevel, Int(endOfLevelTime) + 0x46 < Int(frame) else { return }
        switch mode {
        case .demo:
            pendingStops.insert(.levelCompleted)
        case .play:
            endOfLevelTime = 0
            isEndOfLevel = false
            if extraAnimating {
                extraReset(draw: true)                           // 00018da3 `_EXTRA_Reset(1)`
            }
        }
    }
}

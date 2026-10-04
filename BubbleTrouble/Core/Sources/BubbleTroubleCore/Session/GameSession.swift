// The play loop around the frame step (plan 2026-10-04 btx-playable C4, amended R2–R4, R7, R8; FI §3, §5), transcribed
// from `_RequestGame @ 0000a9a1` (its game half), `_PlayGame @ 00018247` (everything outside the frame body that
// `GameState.stepFrame` models), `_NewLevel @ 0001735f` (its presentation half), `_LoadLevel @ 00002ef7` (prefs),
// `_StopMusic @ 0001afac`, `_TimeBonus_CountDown @ 00006dcb` and `_PauseGame @ 0001767b`.
//
// Time bases (Invariant 4): `frame(keys:)` is one 0.033 s timer fire (phase `.playing` only); `tick(now:keys:)` is
// TickCount (1/60 s) for the blocking sequences — the level-start wipe, the `_StopMusic` fade, the count-down and the
// pause — during which input is ignored except as each blocking loop reads it.
//
// Sound sites emitted here (slot, priority, delay) — everything else is in `FrameReport.sounds` (C2):
//   `_NewLevel` 00017658 (2, 20, 0) not demo · `_PlayGame` 00018dc9 (27, 30, 0) after the count-down ·
//   `_PlayGame` 00019304 (27, 30, 0) on game exit · `_TimeBonus_CountDown` 00006e16 / 00006e8c / 00006f07 and
//   `_Multiplier_Flash` 00019d90 (`TimeBonusCountdown.swift`) · `_PauseGame` 00017712 (22, 30, 0) at entry.
//   Not here: `_PauseGame`'s cheat confirmations (C8); `_ResumeGame @ 0000a28e` 0000a32d (13, 20, 0) is the
//   main-menu registration thank-you (unregistered path, not built).
// Music: `_LoadMusic(1)` (`_NewLevel`, not demo), `_StartMusic` at hero appear, `_StopMusicWithoutFade` at death,
// `_StopMusic` (fade) at level end and ⌘Q, `_UnloadMusic` after the count-down and at exit, pause/resume. Never demo.

/// Where a `GameSession` stands (plan S2).
public enum SessionPhase: Equatable, Sendable {
    /// `_NewLevel`'s `_WipeScreen(12)` reveal (tick-driven).
    case wipe
    /// Frames run (`wantsFrameTimer`).
    case playing
    /// `_StopMusic`'s blocking fade, −5 per tick (R4).
    case musicFade
    /// `_TimeBonus_CountDown` (R3).
    case countdown
    /// `_PauseGame`.
    case paused
    /// The game ended (see `SessionOutput.ended`) or the app is quitting.
    case ended
}

/// One game or demo, from `_RequestGame` to the `_PlayGame` exit (plan S2). Main-actor use by the App; not Sendable.
public final class GameSession {
    /// `_WipeScreen(12)`: the bands advance 12 rows per tick until `2·12 + 240` rows → 22 advances.
    static let wipeStep = 12
    static let wipeAdvances = (2 * 12 + 0xf0) / 12

    public let mode: GameMode
    public internal(set) var state: GameState
    /// The prefs as the game leaves them (`_LoadLevel` raises short 0x3a); the App saves them on `.savePrefs`.
    public private(set) var prefs: BTXPrefs
    public private(set) var phase: SessionPhase
    public private(set) var notices = NoticeBoard()
    /// `gPlayerIsCheating` (`_RequestGame`: start level > 1; C8 cheats set it too) — no high score when set.
    public internal(set) var playerIsCheating: Bool
    /// `gMusicLoaded` / "the music channel is playing" as far as the session has driven it.
    public private(set) var musicLoaded = false
    public private(set) var musicPlaying = false
    /// Why the game ended, once it has.
    public private(set) var endReason: SessionEnd?

    /// True only while frames run (plan C4 item 9).
    public var wantsFrameTimer: Bool { phase == .playing }

    private let data: BTXGameData
    private var filmInput: FilmInput?
    private var keyboard: KeyboardInput
    private var pending = SessionOutput()

    private var wipeDone = 0
    private var wipeLastTick: UInt32?
    private var wipeStartsGame = true

    private enum AfterFade { case countdown, quit }
    private var fadeVolume = 0
    private var fadeThen = AfterFade.countdown
    private var fadeLastTick: UInt32?

    private var countdown: TimeBonusCountdown?
    private var pause: PauseState?
    /// `bVar2` + `local_e9`: `_PauseGame` is due at the end of this loop iteration, restoring this notice.
    private var pauseDue: (previous: Int, deactivated: Bool)?
    /// `local_ea`: the app was deactivated during play (pauses at the next frame).
    private var deactivated = false
    /// `gPlayGame = 0` set by the session (Esc, demo interruption) with the reason.
    private var exitReason: SessionEnd?
    /// `gEscapeKeyFrames`.
    private var escapeFrames = 0

    /// `_RequestGame(level, mode)` → `_PlayGame`'s prologue → `_NewLevel` up to its `_WipeScreen(12)`. Play: `seed` is
    /// the caller's TickCount, `startLevel` 1…; demo: `film` is required and gives both (level = FILM id, seed =
    /// FILM.seed; replay-oracle §3) — `startLevel` and `seed` are ignored. The first `tick` returns the opening
    /// output; the wipe then runs on ticks.
    public init(data: BTXGameData, prefs: BTXPrefs, mode: GameMode, startLevel: Int, seed: UInt32,
                film: Film?) throws {
        var level = startLevel, seed = seed
        if mode == .demo {
            guard let film else { preconditionFailure("GameSession(mode: .demo) needs a FILM") }
            level = film.id
            seed = film.seed
            filmInput = FilmInput(film: film)
        }
        self.mode = mode
        self.data = data
        self.prefs = prefs
        playerIsCheating = 1 < level                                    // _RequestGame: gPlayerIsCheating = 1 < level
        keyboard = KeyboardInput(keySet: prefs.currentKeySet)
        var config = SessionConfig()
        config.prefs = prefs.cosmetic
        // _LoadLevel's first draw (levels ≥ 51 only) is the first draw of the game: peek it on a fresh stream.
        var probe = GameRandom(seed: seed, step: config.rngStep)
        let firstID = level >= 0x33 ? probe.fast(0x15, 0x32) : level
        state = try GameState.newGame(level: level, mode: mode, seed: seed, files: data.levels, config: config)
        phase = .wipe
        // _RequestGame: DisableMenuCommand('abou'); _HideMyCursor (not demo). _LoadLevel: prefs raise + save.
        pending.requests.append(.disableAbout(true))
        if mode == .play { pending.requests.append(.hideCursor) }
        raiseLevelSelectMax(loadedID: firstID)
        pending.requests.append(.savePrefs)
        pending.drawOps = state.levelStartOps() + [.wipe(step: Self.wipeStep)]
    }

    // MARK: - Driving

    /// One 0.033 s frame (`_PlayGame`'s loop iteration). Outside `.playing` it only flushes pending output.
    public func frame(keys: HeldKeys) -> SessionOutput {
        var out = takePending()
        guard phase == .playing else { return out }

        // Loop top: `if (gPlayGame == 0)` → the exit sequence.
        if !state.playing || exitReason != nil {
            out.append(exitGame())
            return out
        }

        keyboard.keys = keys
        let transition = state.upcomingHeroTransition
        let wasEndOfLevel = state.isEndOfLevel

        // The hero state machine's notices (000187a7…): appear → `_PrepareNotice(0)` (not demo); respawn → 2 / 1.
        switch transition {
        case .appear:
            if mode == .play { notices.prepare(0) }
        case .respawn(let livesLeft, let endOfLevel):
            if livesLeft < 1 {
                notices.prepare(2)
            } else if !endOfLevel {
                notices.prepare(1)
            }
        case .death, nil:
            break
        }

        // 00018a7e: `_PauseKey() || local_ea` → (not demo) remember the notice, `_PrepareNotice(3)`, pause after the
        // frame.
        if (keys.capsLock || deactivated) && mode == .play {
            pauseDue = (notices.current, deactivated)
            notices.prepare(3)
        }

        let report: FrameReport
        if mode == .demo, var input = filmInput {
            report = state.stepFrame(input: &input)
            filmInput = input
        } else {
            report = state.stepFrame(input: &keyboard)
        }

        // `_TimeBonus_Process` (inside the frame): bonus reaching exactly 0 → `_PrepareNotice(5)`; at 0 with HURRY UP!
        // up for > 60 frames → `_PrepareNotice(0)`. Derived from the state the frame left:
        // the −50 step ran this frame iff the hero is in state 2 and the timer was just set to this frame.
        if !wasEndOfLevel {
            let decremented = state.hero.state == 2 && state.timeBonusTimer == state.frame
            if state.timeBonus == 0 && decremented {
                notices.prepare(5)
            } else if state.timeBonus < 1 && notices.current == 5
                        && Int(state.timeBonusTimer) + 0x3c < Int(state.frame) {
                notices.prepare(0)
            }
        }

        // Music of the hero state machine (FrameReport carries no music).
        switch transition {
        case .appear:                                                   // _StartMusic (returns in demo)
            if mode == .play && musicLoaded {
                out.music.append(.start)
                musicPlaying = true
            }
        case .death:                                                    // _StopMusicWithoutFade
            if musicLoaded {
                out.music.append(.stopNow)
                musicPlaying = false
            }
        default:
            break
        }

        // Draw: `_EraseNotice` (before the draw pass) → the frame's ops → `_DrawNotice` → the screen flush.
        let erased = notices.erase()
        let drawn = notices.draw(level: Int(state.level))
        out.sounds += report.sounds
        out.drawOps += erased.restore.map { .restoreBgnd($0) } + report.drawOps + drawn.ops
            + (erased.flush + drawn.flush).map { .compToScreen($0) }

        // 00018c71: Esc ends the game at once, or after > 30 held frames when bool 0x3d is set.
        if keys.codes.contains(0x35) {
            if !prefs.holdEscapeToExit {
                exitReason = .escaped
            } else {
                escapeFrames += 1
                if 0x1e < escapeFrames { exitReason = .escaped }
            }
        } else {
            escapeFrames = 0
        }

        // 00018d1e: the end-of-level transition the core just made (play) → `_StopMusic` → count-down → `_NewLevel`.
        if mode == .play && wasEndOfLevel && !state.isEndOfLevel {
            out.append(stopMusic(then: .countdown))
            return out                                   // ⌘Q and the pause follow `_NewLevel` (finishNewLevel)
        }

        out.append(afterLevelChecks(keys: keys))
        return out
    }

    /// One TickCount tick (1/60 s) for the blocking phases. Outside them it only flushes pending output.
    public func tick(now: UInt32, keys: HeldKeys) -> SessionOutput {
        var out = takePending()
        switch phase {
        case .wipe:
            if let last = wipeLastTick {
                if last < now {
                    wipeDone += 1
                    wipeLastTick = now
                }
            } else {
                wipeLastTick = now
            }
            if Self.wipeAdvances <= wipeDone {
                out.append(finishNewLevel(keys: keys))
            }
        case .musicFade:
            if let last = fadeLastTick, now <= last { break }
            fadeLastTick = now
            if 0 <= fadeVolume {
                out.music.append(.volume(fadeVolume))
                fadeVolume -= 5
            } else {
                out.append(endFade(now: now, keys: keys))
            }
        case .countdown:
            out.append(runCountdown(now: now, keys: keys))
        case .paused:
            if !keys.capsLock && pause?.mayResume == true {                // null event: !PauseKey && local_61
                out.append(exitPause())
            }
        case .playing, .ended:
            break
        }
        return out
    }

    // MARK: - Shell events

    /// A key-down / mouse-down / activate event (kind 1) while a demo runs: `gPlayGame = 0`.
    public func interrupt() {
        if mode == .demo && phase == .playing && exitReason == nil {
            exitReason = .demoInterrupted
        }
    }

    /// The app was deactivated (event kind 2): demo → `_SuspendGame` and the demo ends; play → paused at the next
    /// frame (`local_ea`); while paused → `_InGameSuspend`, the pause then needs a reactivation to end.
    public func appDeactivated() {
        switch phase {
        case .playing:
            if mode == .demo {
                if exitReason == nil { exitReason = .demoInterrupted }
            } else {
                deactivated = true
            }
        case .paused:
            pause?.mayResume = false
        default:
            break
        }
    }

    /// The app was reactivated (event kind 1 inside `_PauseGame`): `local_61 = true`; Caps Lock off → resume.
    public func appActivated(keys: HeldKeys) -> SessionOutput {
        guard phase == .paused else { return SessionOutput() }
        pause?.mayResume = true
        return keys.capsLock ? SessionOutput() : exitPause()
    }

    /// A character typed while paused (event kind 3): the cheat buffer shifts in `char` — the hash check and its
    /// effects are task C8's hook here.
    public func pauseKeyTyped(_ char: UInt8) -> SessionOutput {
        guard phase == .paused, var p = pause else { return SessionOutput() }
        p.cheatBuffer.removeFirst()
        p.cheatBuffer.append(char)
        pause = p
        return SessionOutput()
    }

    // MARK: - Sequences

    /// After the end-of-level block (00018ea4): ⌘Q (`GameKeyDown(0xc)` + ⌘ → `_StopMusic`, `_CleanUp`: quit, no prefs
    /// save — R7), then the pause.
    private func afterLevelChecks(keys: HeldKeys) -> SessionOutput {
        if keys.codes.contains(0x0c) && keys.command {
            pauseDue = nil
            return stopMusic(then: .quit)
        }
        if let due = pauseDue {
            pauseDue = nil
            deactivated = false                                  // local_ea = 0 after _PauseGame
            return enterPause(previous: due.previous, deactivated: due.deactivated)
        }
        return SessionOutput()
    }

    /// `_StopMusic @ 0001afac`: when the music is loaded, its volume pref is not 1 (off), the game is running (or
    /// bool 0x40) and it is playing → the blocking fade from 0x40 / 0x80 / 0x100 (pref 2 / 3 / 4), one `volume` per
    /// tick, the first now; then `_StopMusicWithoutFade`.
    private func stopMusic(then next: AfterFade) -> SessionOutput {
        var out = SessionOutput()
        fadeThen = next
        let start: Int? = switch prefs.musicVolume {
        case 2: 0x40
        case 3: 0x80
        case 4: 0x100
        default: nil
        }
        let running = state.playing && exitReason == nil
        if musicLoaded, let start, running || prefs.titleMusic, musicPlaying {
            out.music.append(.volume(start))
            fadeVolume = start - 5
            fadeLastTick = nil
            phase = .musicFade
            return out
        }
        // No fade: `_StopMusicWithoutFade` at once.
        if musicLoaded { out.music.append(.stopNow) }
        musicPlaying = false
        switch next {
        case .countdown:
            countdown = TimeBonusCountdown(state: state)
            phase = .countdown                                      // its first step runs on the next tick
        case .quit:
            out.requests.append(.quitNow)
            phase = .ended
        }
        return out
    }

    /// The fade loop ended: `_StopMusicWithoutFade`, then the count-down or the quit.
    private func endFade(now: UInt32, keys: HeldKeys) -> SessionOutput {
        var out = SessionOutput()
        if musicLoaded { out.music.append(.stopNow) }
        musicPlaying = false
        switch fadeThen {
        case .countdown:
            countdown = TimeBonusCountdown(state: state)
            phase = .countdown
            out.append(runCountdown(now: now, keys: keys))
        case .quit:
            out.requests.append(.quitNow)
            phase = .ended
        }
        return out
    }

    private func runCountdown(now: UInt32, keys: HeldKeys) -> SessionOutput {
        guard var c = countdown else { return SessionOutput() }
        var out = c.run(now: now, state: &state)
        countdown = c
        guard c.isDone else { return out }
        countdown = nil
        // 00018dc9: snd 27; `_UnloadMusic` (not demo); (unregistered level > 7 nag — not built); `_NewLevel`.
        out.sounds.append(SoundCue(slot: 0x1b, priority: 0x1e, delayFrames: 0))
        if mode == .play && musicLoaded {
            out.music.append(.unload)
            musicLoaded = false
        }
        out.append(beginNewLevel(now: now))
        return out
    }

    /// `_NewLevel @ 0001735f` for the next level: the simulation half (`advanceLevel`), `_LoadLevel`'s prefs raise
    /// and save, `_DrawMaze` and the wipe.
    private func beginNewLevel(now: UInt32) -> SessionOutput {
        var out = SessionOutput()
        let id = state.levelIDToLoad(state.level + 1)
        raiseLevelSelectMax(loadedID: id)
        out.requests.append(.savePrefs)
        do {
            try state.advanceLevel(data: data)
        } catch {
            // `_ResourceError` / `_LoadMaze` failure → `_CleanUp` (the original quits).
            endReason = .originalWouldQuit("NewLevel: \(error)")
            out.ended = endReason
            out.requests.append(.quitNow)
            phase = .ended
            return out
        }
        out.drawOps = state.levelStartOps() + [.wipe(step: Self.wipeStep)]
        phase = .wipe
        wipeDone = 0
        wipeLastTick = now
        wipeStartsGame = false
        return out
    }

    /// `_NewLevel` after `_WipeScreen`: the score bar, `_ResetNotices` + notice 6 (demo: 4), `_LoadMusic(1)` and snd 2
    /// (not demo). At game start `_PlayGame` then hides the cursor (not demo) and disables Prefs + Full Screen; after
    /// a level change the loop's ⌘Q / pause checks follow.
    private func finishNewLevel(keys: HeldKeys) -> SessionOutput {
        var out = SessionOutput()
        out.drawOps = state.reserveInfoOps() + state.scoreOps() + state.timeBonusOps() + state.multiplierOps()
            + state.extraOps()
        notices.reset()
        notices.prepare(mode == .demo ? 4 : 6)
        if mode == .play {
            out.music.append(.load(set: state.levelMusicSet))
            musicLoaded = true
            out.sounds.append(SoundCue(slot: 2, priority: 0x14, delayFrames: 0))     // 00017658 "Get Ready!"
        }
        phase = .playing
        if wipeStartsGame {
            if mode == .play { out.requests.append(.hideCursor) }
            out.requests.append(.enableMenus(false))
        } else {
            out.append(afterLevelChecks(keys: keys))
        }
        return out
    }

    private func enterPause(previous: Int, deactivated: Bool) -> SessionOutput {
        pause = PauseState(previousNotice: previous, deactivated: deactivated)
        phase = .paused
        return PauseState.entryOutput(musicPlaying: musicPlaying)
    }

    private func exitPause() -> SessionOutput {
        guard let p = pause else { return SessionOutput() }
        let out = PauseState.exitOutput(musicLoaded: musicLoaded, musicPlaying: musicPlaying)
        if musicLoaded { musicPlaying = true }
        notices.prepare(p.previousNotice)
        pause = nil
        phase = .playing
        return out
    }

    /// `_PlayGame`'s exit (00019189…) and `_RequestGame`'s cursor: menus re-enabled; (not demo) mouse restored, cursor
    /// shown, music unloaded, `ST_HaltSound`; snd 27; `_ShowMyCursor`; About re-enabled.
    private func exitGame() -> SessionOutput {
        var out = SessionOutput()
        out.requests.append(.enableMenus(true))
        if mode == .play {
            out.requests += [.restoreMousePosition, .showCursor]
            if musicLoaded {
                out.music += [.stopNow, .unload]
                musicLoaded = false
                musicPlaying = false
            }
            out.requests.append(.haltAllSound)
        }
        out.sounds.append(SoundCue(slot: 0x1b, priority: 0x1e, delayFrames: 0))        // 00019304 "Bubbles"
        if mode == .demo { out.requests.append(.showCursor) }
        out.requests.append(.disableAbout(false))
        let reason = exitReason ?? endFromStops(state.pendingStops)
        endReason = reason
        out.ended = reason
        phase = .ended
        return out
    }

    private func endFromStops(_ stops: Set<StopReason>) -> SessionEnd {
        for case .originalWouldAbort(let message) in stops {
            return .originalWouldQuit(message)
        }
        switch mode {
        case .play:
            return .gameOver
        case .demo:
            return stops.contains(.levelCompleted) ? .levelCompleted : .demoStopped(stops)
        }
    }

    /// `_LoadLevel`: `if (short 0x3a < id && id < 31) short 0x3a = id` (id = the LEVL actually loaded).
    private func raiseLevelSelectMax(loadedID id: Int) {
        if prefs.levelSelectMax < id && id < 0x1f {
            prefs.levelSelectMax = id
        }
    }

    private func takePending() -> SessionOutput {
        defer { pending = SessionOutput() }
        return pending
    }
}

extension SessionOutput {
    /// Appends `other` after this output, field by field (`ended` = the later one when set).
    mutating func append(_ other: SessionOutput) {
        sounds += other.sounds
        music += other.music
        drawOps += other.drawOps
        requests += other.requests
        if let e = other.ended { ended = e }
    }
}

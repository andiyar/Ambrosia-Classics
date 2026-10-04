// The main-menu loop, its buttons and keys, the attract mode, demos, games and level select (plan 2026-10-04
// btx-playable C6; FI §1b, §2, §3a), transcribed from `_Interface @ 0000b500`, `_HandleMSMouse @ 0000b001`,
// `_NewGameButton @ 0000ac76`, `_DemoButton @ 0000af71`, `_ScoresButton @ 0000adb9`, `_CreditsButton @ 0000ae16`,
// `_DoLevelSelect @ 0000d31e`, `_DisplayPoem @ 0000ce2b`, `_DisplayQuote @ 0000ceb4` and `_RequestGame
// @ 0000a9a1` (the menu half; the game half is `GameSession`, C4). The scores, credits and high-score-entry
// screens themselves are C7's: C6 hands over to `makeScoresScreen` / `makeCreditsScreen` / `makeHighScoreCheck`.

extension FrontEnd {
    /// `_Interface`: idle 0x4b0 ticks → `_FlashButton` + Demo / Scores, alternately (first Demo).
    static let idleTicks: UInt32 = 0x4b0

    // MARK: - The loop body

    /// One iteration of `_Interface`'s loop with no blocking step pending.
    func menuIteration(keys: HeldKeys) -> SessionOutput {
        var out = SessionOutput()
        if redrawAt != 0 && redrawAt < now {                       // gDidToggleFullscreen + 10 ticks
            out.drawOps += drawMainMenuOps() + [.compToScreen(MainMenu.screenRect)]
            redrawAt = 0
        }
        if !suspended {
            if msgCounter < 4 {
                if infoTimer &+ InfoBox.cycleTicks < now {
                    infoTimer = now
                    out.drawOps += [.spriteWorldToComp(src: InfoBox.srcTextRect, dst: InfoBox.textRect),
                                    .infoText(infoMessage(), colour: InfoBox.colour),
                                    .compToScreen(InfoBox.textRect)]
                    msgCounter = msgCounter + 1 < 4 ? msgCounter + 1 : 0
                }
            } else {
                // An egg message (option-click): drawn by a full `_DrawMainMenu`, then the cycle restarts at 0
                // 120 ticks late.
                infoTimer = now &+ 0x78
                out.drawOps += drawMainMenuOps() + [.compToScreen(MainMenu.screenRect)]
                msgCounter = 0
            }
        }
        if doPrefsNow {
            // `if (_gDoPrefsNow) { _PrefsDialog(); _gDoPrefsNow = 0; }` — then the iteration carries on.
            push([.run { SessionOutput(requests: [.prefsDialog]) },
                  .dialog(then: { [unowned self] _ in
                      doPrefsNow = false
                      return [.run { [unowned self] in menuIterationIdle(keys: keys) }]
                  })])
            ticked = true
            return out + runSteps(keys: keys)
        }
        out.append(menuIterationIdle(keys: keys))
        return out
    }

    /// From the idle attract check on.
    func menuIterationIdle(keys: HeldKeys) -> SessionOutput {
        if idleStart &+ Self.idleTicks < now && !suspended {
            let scores = idleShowsScores
            idleShowsScores.toggle()
            var seq = scores ? flashSteps(.scores) + scoresButtonSteps() : flashSteps(.demo) + demoButtonSteps()
            seq.append(.run { [unowned self] in idleStart = now; return menuIterationTail(keys: keys) })
            push(seq)
            ticked = true
            return runSteps(keys: keys)
        }
        return menuIterationTail(keys: keys)
    }

    /// The rest of the iteration: music upkeep, the stars, one event.
    func menuIterationTail(keys: HeldKeys) -> SessionOutput {
        var out = SessionOutput()
        if !musicPlaying && !suspended { out.append(startMusic()) }
        if musicPaused && foreground { out.append(resumeMusic()) }
        if !suspended { out.drawOps += stars.process(now: now, mouse: mouse, random: &random) }
        guard !events.isEmpty else { return out }
        let event = events.removeFirst()
        switch event {
        case let .key(chars, modifiers):
            out.append(handleKey(chars: chars, modifiers: modifiers))
        case let .mouseDown(h, v, modifiers):
            out.append(handleMouseDown(h: h, v: v, modifiers: modifiers))
        case .activated:                                           // kind 1: local_3c = TickCount; _ResumeGame
            idleStart = now
            out.append(resumeGame())
        case .deactivated:                                         // kind 2: _SuspendGame
            out.append(suspendGame())
        }
        if !steps.isEmpty {
            ticked = true
            out.append(runSteps(keys: keys))
        }
        return out
    }

    func infoMessage() -> String {
        let (m, d) = today()
        return info.message(msgCounter, occasion: InfoBox.occasion(month: m, day: d))
    }

    func drawMainMenuOps() -> [DrawOp] {
        menu.drawOps(info: infoMessage())
    }

    /// `FlushEvents(0x3e)`: mouse and key events go; the class 'appl' (activate / deactivate) events stay.
    func flushEvents() {
        events.removeAll { $0 != .activated && $0 != .deactivated }
    }

    /// After a key / mouse action returns to the loop: `local_3c = TickCount` (+ `gInfoTimer` for keys).
    private func afterEvent(key: Bool) -> Step {
        .run { [unowned self] in
            idleStart = now
            if key { infoTimer = now }
            return SessionOutput()
        }
    }

    // MARK: - Keys (`_Interface`'s switch on the character code)

    func handleKey(chars: String, modifiers: KeyModifiers) -> SessionOutput {
        var seq: [Step] = []
        let click = SoundCue(slot: 0x11, priority: 10, delayFrames: 0)
        // ⌘ held (`gEvent.modifiers & cmdKey`): ignored.
        if !modifiers.command, let c = chars.unicodeScalars.first?.value {
            switch c {
            case 0x03, 0x0d, 0x4e, 0x6e:                               // Enter, Return, N, n
                seq = [Self.sound(click)] + flashSteps(.newGame) + newGameButtonSteps()
            case 0x42, 0x62:                                           // B: "Squeak squeak"
                seq = [Self.sound(SoundCue(slot: 0x2f, priority: 0x1e, delayFrames: 0))]
            case 0x43, 0x63:                                           // C
                seq = [Self.sound(click)] + flashSteps(.credits) + creditsButtonSteps(modifiers: modifiers)
            case 0x44, 0x64:                                           // D
                seq = flashSteps(.demo) + demoButtonSteps()
            case 0x4c, 0x6c:                                           // L
                seq = [Self.sound(SoundCue(slot: 0x16, priority: 10, delayFrames: 0))] + levelSelectSteps()
            case 0x50, 0x70:                                           // P
                seq = [Self.sound(click)] + flashSteps(.prefs) + prefsSteps()
            case 0x51, 0x71:                                           // Q
                seq = [Self.sound(click)] + flashSteps(.quit) + quitSteps()
            case 0x53, 0x73:                                           // S
                seq = flashSteps(.scores) + scoresButtonSteps()
            case 0x57, 0x77:                                           // W: "Non the dog"
                seq = [Self.sound(SoundCue(slot: 0x2e, priority: 0x1e, delayFrames: 0))]
            case 0x58, 0x78:                                           // X: `_DisplayPoem`
                seq = [.run { SessionOutput(requests: [.modalDialog(id: 290)]) }, .dialog(then: { _ in [] })]
            case 0x5a, 0x7a:                                           // Z: `_DisplayQuote`
                seq = quoteSteps()
            default:
                break                                                  // R (Register) — registered build: nothing
            }
        }
        push(seq + [afterEvent(key: true)])
        return SessionOutput()
    }

    static func sound(_ cue: SoundCue) -> Step {
        .run { SessionOutput(sounds: [cue]) }
    }

    // MARK: - Mouse (`_HandleMSMouse(1)`, content region)

    func handleMouseDown(h: Int, v: Int, modifiers: KeyModifiers) -> SessionOutput {
        // Option-click in the info box → an easter-egg message (shown by the loop's `msgCounter ≥ 4` branch).
        if modifiers.option && Self.ptInRect(h, v, InfoBox.textRect) {
            msgCounter = random.fast(3, 0x21)
            push([afterEvent(key: false)])
            return SessionOutput(sounds: [SoundCue(slot: 0, priority: 10, delayFrames: 0)])
        }
        // Any modifier-click on the logo (inset 5) → credits.
        var logo = MainMenu.logoRect
        logo.inset(dx: 5, dy: 5)
        if (modifiers.option || modifiers.shift || modifiers.command || modifiers.control)
            && Self.ptInRect(h, v, logo) {
            push([Self.sound(SoundCue(slot: 0x11, priority: 10, delayFrames: 0))]
                 + creditsButtonSteps(modifiers: modifiers)
                 + [.run { [unowned self] in infoTimer = now; return SessionOutput() }, afterEvent(key: false)])
            return SessionOutput()
        }
        guard let button = menu.button(at: h, v) else {
            push([afterEvent(key: false)])
            return SessionOutput()
        }
        infoTimer = now
        trackLit = false
        trackFirst = true
        released = nil
        push([.track(button, modifiers: modifiers), afterEvent(key: false)])
        return SessionOutput(sounds: [SoundCue(slot: 0x11, priority: 10, delayFrames: 0)],
                             drawOps: [.pict(id: MainMenu.buttonsPict, dst: MainMenu.buttonsPictRect, target: .bgnd)])
    }

    /// One pass of the `StillDown` loop: stars, highlight on entering / leaving, and on release the action when the
    /// mouse is still inside. Returns the steps that replace the tracking step once the button is released.
    func trackIteration(_ b: MainMenu.Button, modifiers: KeyModifiers, out: inout SessionOutput) -> [Step]? {
        let dst = menu.destinations[b]!
        out.drawOps += stars.process(now: now, mouse: mouse, random: &random)
        if Self.ptInRect(mouse.h, mouse.v, dst) {
            if !trackLit || trackFirst {
                out.drawOps += menu.drawButtonOps(b.rawValue, hit: &hitButtons)
                trackLit = true
                trackFirst = false
            }
        } else if trackLit || trackFirst {
            out.drawOps += menu.drawButtonOps(0, hit: &hitButtons)
            trackLit = false
            trackFirst = false
        }
        let up = released
        guard up != nil || !mouse.button else { return nil }
        released = nil
        out.drawOps += menu.drawButtonOps(0, hit: &hitButtons)
        out.drawOps += stars.process(now: now, mouse: mouse, random: &random)
        let (h, v) = up.map { ($0.h, $0.v) } ?? (mouse.h, mouse.v)
        let mods = up?.modifiers ?? modifiers
        guard Self.ptInRect(h, v, dst) else { return [] }
        switch b {
        case .newGame: return newGameButtonSteps()
        case .demo: return demoButtonSteps()
        case .scores:
            guard mods.option else { return scoresButtonSteps() }
            // Option: `_HiScoreEraseDialog`; Reset → snd 39 + 18, `_LoadDefaultHiScores`, then the scores; Cancel →
            // back to the menu.
            return [.run { SessionOutput(requests: [.hiScoreEraseDialog]) },
                    .dialog(then: { [unowned self] answer in
                        guard answer == .erase(true) else { return [] }
                        return [.run { [unowned self] in
                            if let factory = try? HighScoreTable.factory(from: data) { highScores = factory }
                            return SessionOutput(sounds: [SoundCue(slot: 0x27, priority: 10, delayFrames: 0),
                                                          SoundCue(slot: 0x12, priority: 10, delayFrames: 0)])
                        }] + scoresButtonSteps()
                    })]
        case .prefs: return prefsSteps()
        case .credits: return creditsButtonSteps(modifiers: mods)
        case .quit: return quitSteps()
        }
    }

    // MARK: - Buttons

    /// `_FlashButton(b)`: lit, `_ProcessMenuStars`, `_WaitFor(10)`, unlit, `_ProcessMenuStars`.
    func flashSteps(_ b: MainMenu.Button) -> [Step] {
        [.run { [unowned self] in
            SessionOutput(drawOps: menu.flashOnOps(b) + stars.process(now: now, mouse: mouse, random: &random))
         },
         .waitTicks(10),
         .run { [unowned self] in
            SessionOutput(drawOps: menu.flashOffOps(b) + stars.process(now: now, mouse: mouse, random: &random))
         }]
    }

    /// `_NewGameButton`: snd 36, `_StopMusic`, `_UnloadMusic`, `_RequestGame(1, play)`, `_ResetMenuStars`,
    /// `_LoadMusic(0)`, `_StartMusic` unless playing or suspended.
    func newGameButtonSteps() -> [Step] {
        [Self.sound(SoundCue(slot: 0x24, priority: 0x14, delayFrames: 0))]
            + stopMusicSteps()
            + [.run { [unowned self] in unloadMusic() }]
            + requestGameSteps(level: 1, mode: .play)
            + [.run { [unowned self] in
                stars.reset(now: now, mouse: mouse)
                var out = loadTitleMusic()
                if !musicPlaying && !suspended { out.append(startMusic()) }
                return out
            }]
    }

    /// `_DemoButton`: FILM `gFilmCounter + 1`, `_RequestGame(film, demo)`, `_ResetMenuStars`.
    func demoButtonSteps() -> [Step] {
        [.run { [unowned self] in
            push(requestGameSteps(level: filmCounter + 1, mode: .demo))
            return SessionOutput()
        },
         .run { [unowned self] in
            stars.reset(now: now, mouse: mouse)
            return SessionOutput()
        }]
    }

    /// `_ScoresButton`: `_UpdateScreen`, `_DisplayHiScores` (C7; N → `_NewGameButton`), `FlushEvents(0x3e)`,
    /// `_DrawMainMenu`, `_WipeScreen(12)`, `_ResetMenuStars`.
    func scoresButtonSteps() -> [Step] {
        [.run { SessionOutput(drawOps: [.compToScreen(MainMenu.screenRect)]) },
         .screen(make: { [unowned self] in makeScoresScreen(newEntryRank: nil) }, then: { [unowned self] r in
            r == .newGame ? newGameButtonSteps() : []
         })] + returnToMenuSteps(flush: true)
    }

    /// `_CreditsButton`: the secret set by the modifier held (control 1 → snd 38, option 2 → 40, ⌘ 3 → 44, shift 4 →
    /// 39, none 0 → 19; priority 0x14), `_UpdateScreen`, `_DisplayCredits(secret)` (C7; N → `_NewGameButton`), then
    /// as `_ScoresButton`.
    func creditsButtonSteps(modifiers: KeyModifiers) -> [Step] {
        let (secret, slot) = Self.creditsSecret(modifiers)
        return [.run { SessionOutput(sounds: [SoundCue(slot: slot, priority: 0x14, delayFrames: 0)],
                                     drawOps: [.compToScreen(MainMenu.screenRect)]) },
                .screen(make: { [unowned self] in makeCreditsScreen(secret: secret) }, then: { [unowned self] r in
                    r == .newGame ? newGameButtonSteps() : []
                })] + returnToMenuSteps(flush: true)
    }

    static func creditsSecret(_ m: KeyModifiers) -> (secret: Int, slot: Int) {
        if m.control { return (1, 0x26) }
        if m.option { return (2, 0x28) }
        if m.command { return (3, 0x2c) }
        if m.shift { return (4, 0x27) }
        return (0, 0x13)
    }

    /// `FlushEvents(0x3e)` (scores / credits), `_DrawMainMenu`, `_WipeScreen(12)`, `_ResetMenuStars`.
    func returnToMenuSteps(flush: Bool) -> [Step] {
        [.run { [unowned self] in
            if flush { flushEvents() }
            return SessionOutput(drawOps: drawMainMenuOps() + [.wipe(step: 12)])
         },
         .advances(DrawOp.wipeSteps(12)),
         .run { [unowned self] in
            stars.reset(now: now, mouse: mouse)
            return SessionOutput()
         }]
    }

    /// `_PrefsButton`: `_PrefsDialog`, then `_UpdateMusicVolume` (the App's).
    func prefsSteps() -> [Step] {
        [.run { SessionOutput(requests: [.prefsDialog]) }, .dialog(then: { _ in [] })]
    }

    /// `gFinished = 1` → the loop's exit: `_StopMusic`, then `_main` saves the prefs and quits.
    func quitSteps() -> [Step] {
        stopMusicSteps() + [.run { [unowned self] in
            phase = .quit
            steps = []
            return SessionOutput(requests: [.quit])
        }]
    }

    /// `_DisplayQuote`: `_StopMusic`, DLOG 291 until a key / click, `_ResumeMusic`.
    func quoteSteps() -> [Step] {
        stopMusicSteps() + [.run { SessionOutput(requests: [.modalDialog(id: 291)]) },
                            .dialog(then: { [unowned self] _ in [.run { [unowned self] in resumeMusic() }] })]
    }

    // MARK: - Level select (`_Interface` 'L' + `_DoLevelSelect`)

    /// The level `_DoLevelSelect` returns for `typed` on OK: 2…short 0x3a, else 0 after `SysBeep(1)`.
    public static func levelSelectChoice(typed: Int, max: Int) -> Int? {
        typed < 2 || max < typed ? nil : typed
    }

    func levelSelectSteps() -> [Step] {
        [.run { [unowned self] in
            SessionOutput(sounds: [SoundCue(slot: 0x16, priority: 10, delayFrames: 0)],
                          requests: [.levelSelectDialog(max: prefs.levelSelectMax)])
         },
         .dialog(then: { [unowned self] answer in
            guard case .levelSelect(let typed?) = answer else {
                return [.run { SessionOutput(requests: [.closeDialog]) }]           // Cancel: disposed at once
            }
            // OK: out of range → `SysBeep(1)` with the dialog up; `_WaitFor(0x1e)`; `_DisposeDialog`; return.
            let level = Self.levelSelectChoice(typed: typed, max: prefs.levelSelectMax)
            let hold: [Step] = [.run { SessionOutput(requests: level == nil ? [.beep] : []) },
                                .waitTicks(0x1e),
                                .run { SessionOutput(requests: [.closeDialog]) }]
            guard let level else { return hold }
            // Back in `_Interface`: snd 36, `_StopMusic`, `_UnloadMusic`, `_RequestGame(level, play)`,
            // `_ResetMenuStars`, `_LoadMusic(0)`, `_StartMusic` unless playing.
            return hold + [Self.sound(SoundCue(slot: 0x24, priority: 0x14, delayFrames: 0))]
                + stopMusicSteps()
                + [.run { [unowned self] in unloadMusic() }]
                + requestGameSteps(level: level, mode: .play)
                + [.run { [unowned self] in
                    stars.reset(now: now, mouse: mouse)
                    var out = loadTitleMusic()
                    if !musicPlaying { out.append(startMusic()) }
                    return out
                }]
         })]
    }

    // MARK: - `_RequestGame`

    /// `_RequestGame(level, mode)`: `_UpdateScreen`, the session (its prologue: About disabled, cursor hidden in
    /// play; the FILM counter advances in a demo), the game, then the menu half of the epilogue.
    func requestGameSteps(level: Int, mode: GameMode) -> [Step] {
        [.run { [unowned self] in
            var out = SessionOutput(drawOps: [.compToScreen(MainMenu.screenRect)])
            do {
                let film: Film? = mode == .demo ? try data.levels.film(level) : nil
                if mode == .demo {
                    // `_PlayGame`: `gFilmCounter = (gFilmCounter + 1) mod gNumFilmsAvailable`.
                    let next = filmCounter + 1
                    filmCounter = next != numFilms ? next : 0
                }
                session = try GameSession(data: data, prefs: storedPrefs, mode: mode, startLevel: level, seed: now,
                                          film: film, latches: latches ?? .fromProcessSeedOne)
                session!.showFPS = showFPS
                push([.game(then: { [unowned self] s in afterGameSteps(s, startLevel: level) })])
                // The session's opening output arrives with its first tick, this tick.
                lastSessionTick = now
                out.append(session!.tick(now: now, keys: HeldKeys()))
            } catch {
                // A FILM / level that fails to load: the original `_ResourceError`s and quits.
                phase = .quit
                steps = []
                out.requests.append(.quitNow)
            }
            return out
        }]
    }

    /// The session just ended this call: ⌘Q (`.quitNow`) or a load failure → quit.
    func checkGameEnd(_ out: SessionOutput) -> SessionOutput {
        guard let s = session, s.phase == .ended else { return SessionOutput() }
        var extra = SessionOutput()
        if case .originalWouldQuit? = s.endReason, !out.requests.contains(.quitNow) {
            extra.requests.append(.quitNow)
        }
        if out.requests.contains(.quitNow) || !extra.requests.isEmpty {
            phase = .quit
            steps = []
        }
        return extra
    }

    /// `_RequestGame` after `_PlayGame`: `_ShowMyCursor`; (play, started at level 1, not cheating) `_CheckHiScore`
    /// (C7); then either `_DrawMainMenu`, About on, `crsr 200`, cursor, `_WipeScreen(12)` — or, when a score was
    /// entered, `FlushEvents`, `_DrawCompPattern`, About on, `_UpdateScreen`, cursor, snd 19, `_DisplayHiScores`
    /// (N → `_NewGameButton`), `_DrawMainMenu`, `_WipeScreen(12)`, `FlushEvents`.
    func afterGameSteps(_ s: GameSession, startLevel: Int) -> [Step] {
        // The shared QuickDraw seed carries on from the game; prefs come back with short 0x3a raised.
        random = GameRandom(seed: s.state.rng.seed)
        storedPrefs = s.prefs
        showFPS = s.showFPS
        let checkScore = s.mode == .play && startLevel <= 1 && !s.playerIsCheating
        let score = s.state.score, level = Int(s.state.level)
        session = nil
        var seq: [Step] = [.run { SessionOutput(requests: [.showCursor]) }]
        let menuPath: [Step] = [
            .run { [unowned self] in
                SessionOutput(drawOps: drawMainMenuOps() + [.wipe(step: 12)],
                              requests: [.disableAbout(false), .setCursor(id: 200), .showCursor])
            },
            .advances(DrawOp.wipeSteps(12)),
        ]
        guard checkScore else { return seq + menuPath }
        seq.append(.screen(make: { [unowned self] in makeHighScoreCheck(score: Int(score), level: level) },
                           then: { [unowned self] r in
            guard case .highScoreEntered(rank: let rank?) = r else { return menuPath }
            return [.run { [unowned self] in
                        flushEvents()
                        return SessionOutput(
                            sounds: [SoundCue(slot: 0x13, priority: 0x14, delayFrames: 0)],
                            drawOps: [.pict(id: MainMenu.compPatternPict, dst: menu.compPatternRect, target: .comp),
                                      .compToScreen(MainMenu.screenRect)],
                            requests: [.disableAbout(false), .setCursor(id: 200), .showCursor])
                    },
                    .screen(make: { [unowned self] in makeScoresScreen(newEntryRank: rank) }, then: { [unowned self] r in
                        r == .newGame ? newGameButtonSteps() : []
                    }),
                    .run { [unowned self] in SessionOutput(drawOps: drawMainMenuOps() + [.wipe(step: 12)]) },
                    .advances(DrawOp.wipeSteps(12)),
                    .run { [unowned self] in flushEvents(); return SessionOutput() }]
        }))
        return seq
    }

    // MARK: - C7 hand-over

    /// `_DisplayHiScores` (C7); `newEntryRank` = the row `_CheckHiScore` filled (it flashes). C6 placeholder:
    /// returns at once.
    func makeScoresScreen(newEntryRank: Int?) -> FrontEndScreen {
        PlaceholderScreen(.finished)
    }

    /// `_DisplayCredits(secret)` (C7). C6 placeholder: returns at once.
    func makeCreditsScreen(secret: Int) -> FrontEndScreen {
        PlaceholderScreen(.finished)
    }

    /// `_CheckHiScore` (C7): the pattern overlay, DLOG 1000 (answered via `FrontEnd.highScoreNameEntered`), the
    /// insert into `highScores`. C6 placeholder: no entry.
    func makeHighScoreCheck(score: Int, level: Int) -> FrontEndScreen {
        PlaceholderScreen(.highScoreEntered(rank: nil))
    }
}

extension SessionOutput {
    static func + (a: SessionOutput, b: SessionOutput) -> SessionOutput {
        var r = a
        r.append(b)
        return r
    }
}

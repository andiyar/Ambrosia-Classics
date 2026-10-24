import Foundation

/// F1b: `.NewGame @ 1000b11c` (M l. 5704–5874) and the parts `.ContinueGame` shares with it — the level ⇄ map loop
/// (`LevelRun` ⇄ `WorldMapRun`), the after-loop death test → `.AskToContinue` (`DeathScreen`), the menu return (bank
/// save-continue §1, §4, §5; plan F1b).
///
/// **New Game:** `FlushEvents`, `KillAllSprites`, `.InitGameGlobals` (`initGameGlobals()`), `fe00 = 0`; `fd5c` is 1
/// (the callers set it) → `OpenDefaultWorld` + `.InitMapLevelNames` (the resources are open; STR# 1000 is
/// `WorldMapRun`'s); Option held (debug flag `_DAT_100a0064` 0) → "Ferazel sez:\rNo more cheating!" (0x100a2e31); the
/// **literal level 1** (raw `1000b2b8..1000b2cc`; `startLevel` with the hidden `FerazelLevel` switch); a nil level →
/// "An unexpected error occurred -- the level could not be loaded from the world file!" (0x100a2e76) and back;
/// `5106 = 0`, `0088 = 0`, `fd54 = 0`; the loop (M l. 5815–5841) while not `5106`: `FadeAIFFMusic(0, 4)`,
/// `ShutDownAIFFMusic`, `ResetCursor`, `G+0x16 ← hdr[0x26c8]` (the session's `refreshFacing`),
/// `.GameLoop(hdr+0x2848 − 32, hdr+0x2846 − 32, 0, 1)`; completed ∧ no victory → `.ShowWorldMap`: < 0 →
/// `GammaFadeOut(10)` + `5106 = 1`, else `OpenDefaultWorldLevel(n)` (◇ `BuiltLevels`: outside → the not-built report,
/// the map again at that node); `fd50` → `.Quit`; not aborted → `save+0xc / +0x10 ←` the next level's start − 32.
/// `.GameLoop` itself also opens with `FadeAIFFMusic(0, 4)` + `ShutDownAIFFMusic` (M l. 5161–5163, inside `LevelRun`)
/// — after `.NewGame`'s pair they find no music loaded and do nothing; Continue has only those.
///
/// **After the loop (M l. 5842–5874):** died (New Game: G+4 < 1; Continue: `ffa8`) → `.AskToContinue`: yes →
/// `fd48 = 1` and return (the menu loop's `fd48` → `.ContinueGame(fd18)`); no → `fd48 = 0`, `MTRedraw`; else
/// `fd48 = 0`; `.Victory` (// later: Phase 6); the menu return: `GammaFadeOut(6)`, `.DrawMainMenu`, then New Game
/// `SetAIFFMusic(24)`, `FadeAIFFMusic(1, 4)`, `.UpdateMenus`, `MTRedraw` / Continue `.UpdateMenus`, `MTRedraw`,
/// `SetAIFFMusic(24)`, `FadeAIFFMusic(1, 4)`; `GammaFadeIn(6)`; `ShowCursorSafe`.
extension GameFlow {
    /// 0x100a2e76.
    public static let levelLoadError =
        "An unexpected error occurred -- the level could not be loaded from the world file!"
    /// 0x100a2e31.
    public static let noMoreCheating = "Ferazel sez:\rNo more cheating!"
    /// `.IsOptionPressed`: the Option key (0x3a).
    static let optionKey = 0x3a
    /// `SetAIFFMusic(0x18)` at the menu return.
    static let menuTrack = 0x18

    /// `.InitGameGlobals @ 10001498` (M l. 582–866): SV1's G part (`GameGlobals.initGameGlobals(previous:)`, the
    /// fields it never writes from the live G), then the tail (M l. 815–825): `*ffac`, `*ffb0`, `*ffb4` (the Setups'
    /// tallies), `*ffa8` (died), `*ffa4`, `*ffa0` (the shake counter), `*ff9c` = 0 — in the replica all but `ffa8` are
    /// the session's, fresh per level — then `save+6 = 0` (the block always exists, `NewHandleClear` at boot); then
    /// `.InitPlayerMapData` (M l. 864): the node table re-read (`WorldMapRun` reads it per run) and the node-sprite
    /// count 0 (M l. 66610); `*ff90 = 0` (the fallback branch's flag, never set in the replica).
    func initGameGlobals() {
        globals = GameGlobals.initGameGlobals(previous: globals)
        died = false
        saveBlock.isCheckpoint = 0
        mapSprites = []
    }

    /// `.NewGame` (the menu has set `fd5c = 1`).
    func newGame(_ out: inout FrontOutput) {
        state = .newGame
        run([
            { f, _, input, out in
                // `FlushEvents(0xff7f, 0)`, `KillAllSprites` (none outside a level), `.InitGameGlobals`, `fe00 = 0`,
                // `ReportMem`; `OpenDefaultWorld` + `.InitMapLevelNames` (M l. 5747–5757).
                f.initGameGlobals()
                f.savedThisGame = false
                if input.keys.isPressed(Self.optionKey) { f.report(Self.noMoreCheating, &out) }
            },
            { f, _, _, out in
                // `OpenDefaultWorldLevel(1)` (`_DAT_100ab9ba = *feac = 1`); a nil level → the report, `ReportMem`, return.
                let n = BuiltLevels.range.contains(f.startLevel) ? f.startLevel : 1
                f.levelNumber = n
                guard f.levelExists(n) else {
                    f.report(Self.levelLoadError, &out)
                    f.run([{ f, _, _, _ in f.state = .mainMenu }])
                    return
                }
                // `DAT_100a5106 = 0`, `*0088 = 0`, `*fd54 = 0` (M l. 5813–5815).
                f.loopEnded = false
                f.levelComplete = false
                f.saveFileKnown = false
                f.run(f.loopIteration(continuing: false))
            },
        ])
    }

    /// `OpenDefaultWorldLevel(n)` finds `Mlvl n`.
    func levelExists(_ n: Int) -> Bool {
        (try? LevelFile.load(from: resources, level: Int16(truncatingIfNeeded: n))) != nil
    }

    // MARK: - The loop body

    /// One pass of the `while (DAT_100a5106 == 0)` loop: New Game's `FadeAIFFMusic(0, 4)` + `ShutDownAIFFMusic`
    /// first (Continue's loop body has neither, M l. 7044–7064), then `ResetCursor` and the level.
    func loopIteration(continuing: Bool) -> [Work] {
        var items: [Work] = []
        if !continuing {
            items.append { f, now, _, out in
                f.block(f.toggles.music.fadeAIFFMusic(direction: 0, ticks: 4, prefs: f.toggles.live), now, &out)
            }
            items.append { f, _, _, out in out.music += f.toggles.music.shutDown() }
        }
        items.append { f, _, _, out in f.openLevel(continuing: continuing, &out) }
        items.append { f, now, _, out in f.levelEnded(continuing: continuing, now, &out) }
        return items
    }

    /// `ResetCursor` (the arrow — nothing to send), then `.GameLoop`: New Game `(hdr+0x2848 − 32, hdr+0x2846 − 32, 0,
    /// 1)` with `G+0x16 ← hdr[0x26c8]`; Continue `((short) save+0xc, (short) save+0x10, 0, 0)` without it.
    private func openLevel(continuing: Bool, _ out: inout FrontOutput) {
        var carry = levelCarry
        carry.globals = globals
        carry.crunchLog = globals.crunchLog
        let start: (x: Int, y: Int)? = continuing
            ? (Int(Int16(truncatingIfNeeded: saveBlock.playerX)), Int(Int16(truncatingIfNeeded: saveBlock.playerY)))
            : nil
        do {
            let run = try LevelRun(resources: resources, prefs: toggles.live, level: levelNumber, seed: rng.seed,
                                   carry: carry, save: saveBlock, fade: fade, music: toggles.music, services: levels,
                                   sounds: StageSounds(prefs: toggles.live, lengths: soundLengths), start: start,
                                   param3: 0, param4: !continuing, refreshFacing: !continuing,
                                   skipStageComplete: skipStageComplete, date: dateTime, files: files,
                                   saveState: SaveGameState(savedThisGame: savedThisGame, saveFileKnown: saveFileKnown,
                                                            lastReply: lastReply))
            // P1: ⌘P's Options inside the level uses the flow's key names and its last captured modifier.
            run.keyCharacter = keyCharacter
            run.lastModifier = lastModifier
            levelRun = run
            levelComplete = false                                       // `.GameLoop`: `*0088 = 0` (M l. 5151)
            wait = .level
        } catch {
            levelFailed = true
        }
    }

    /// After `.GameLoop` returned: the run's state taken back, then the map (a completed level) or the loop's end.
    private func levelEnded(continuing: Bool, _ now: UInt32, _ out: inout FrontOutput) {
        if let run = levelRun {
            levelCarry = run.carry
            if let g = levelCarry.globals { globals = g }
            saveBlock = run.save
            fade = run.fade
            toggles.music = run.music
            skipStageComplete = run.skipStageComplete
            lastModifier = run.lastModifier
            // S1: what the level's save points left — fe00 / fd54 / fd18 and the live prefs (`.SaveSG`'s prefs+0x42,
            // `.UpdateSGString`'s `.MakeCurrPrefs`: the record live, `5107`, `510c`, `fd20 = +0x0c`; its music cues
            // already went through `run.music`) — and P1's in-level `.MakeCurrPrefs` (⌘P's Options, the pause's ⌘M / ⌘F).
            savedThisGame = run.saveState.savedThisGame
            saveFileKnown = run.saveState.saveFileKnown
            lastReply = run.saveState.lastReply
            if run.livePrefs != toggles.live {
                toggles.live = run.livePrefs
                toggles.wrapCopyFlag = run.livePrefs.plainCopy == 0
                toggles.soundScale = Int(run.livePrefs.soundVolume) * 0x1c
                toggles.appliedMusicOn = run.livePrefs.musicOn
            }
            if let s = run.session {
                rng = FastRand(seed: s.rngSeed)
                deathScroll = (s.camera.h, s.camera.v)
            }
            if run.died { died = true }                                 // `*ffa8 = 1` (M l. 5303)
            deathEntry255 = Self.entry255(resources, level: run.levelFile.header)
        }
        let end = levelRun?.end
        levelRun = nil
        if levelFailed {
            levelFailed = false
            loopEnded = true
            report(Self.levelLoadError, &out)
            run([{ f, now, _, out in f.afterLoop(continuing: continuing, now, &out) }])
            return
        }
        switch end {
        case .completed(let e1, let e2)?:
            // `*0088` set; `*_DAT_1009ffc4` (victory) 0 — `.Victory` is Phase 6's.
            levelComplete = true
            exit1 = e1
            exit2 = e2
            let h = levelHeader(levelNumber)
            openMap(level: h?.mapNodeLevel ?? Int16(truncatingIfNeeded: levelNumber), name: h?.name ?? "", &out)
            run([{ f, now, _, out in f.mapEnded(continuing: continuing, now, &out) }])
            return
        case .quit?:
            // ⌘Q's OK inside the level (`.CheckGameLoopKeys`, P1): `.Quit` — it never returns.
            loopEnded = true
            quitRequested = true
            quit()
            return
        case .died?, .aborted?, nil:
            loopEnded = true                                            // `DAT_100a5106 = 1` ended `.GameLoop`
        }
        run([{ f, now, _, out in f.afterLoop(continuing: continuing, now, &out) }])
    }

    private func levelHeader(_ n: Int) -> LevelHeader? {
        try? LevelFile.load(from: resources, level: Int16(truncatingIfNeeded: n)).header
    }

    /// Entry 255 of the level's working CLUT (`.TurnGray` sends all 256, D1).
    static func entry255(_ r: FerazelResources, level h: LevelHeader) -> RGB16 {
        guard let c = try? ColorLUT.load(id: ColorLUT.screenClutId(h), from: r, chain: .level),
              c.entries.count > 255 else { return RGB16(0, 0, 0) }
        let e = c.entries[255]
        return RGB16(e.red, e.green, e.blue)
    }

    // MARK: - The map

    /// `.ShowWorldMap()` with the flow's globals (`level` = hdr+0x26c4 of the finished level, `name` its hdr+0x25c4).
    private func openMap(level: Int16, name: String, _ out: inout FrontOutput) {
        do {
            let m = try WorldMapRun(resources: resources, prefs: toggles.live, globals: globals, level: level,
                                    levelName: name, exit1: exit1, exit2: exit2, levelComplete: levelComplete,
                                    seed: rng.seed, fade: fade, music: toggles.music, sprites: mapSprites,
                                    files: files)
            worldMap = m
            wait = .map
        } catch {
            levelFailed = true
        }
    }

    /// After `.ShowWorldMap` returned (M l. 5825–5840 / 7049–7063).
    private func mapEnded(continuing: Bool, _ now: UInt32, _ out: inout FrontOutput) {
        guard let m = worldMap else {
            levelFailed = false
            loopEnded = true
            report(Self.levelLoadError, &out)
            run([{ f, now, _, out in f.afterLoop(continuing: continuing, now, &out) }])
            return
        }
        globals = m.globals
        rng = m.rng
        fade = m.fade
        toggles.music = m.music
        if m.prefs != toggles.live {
            // P1: the pause's ⌘M / ⌘F on the map re-made the prefs current (`fd20 = +0x0c` with them).
            toggles.live = m.prefs
            toggles.wrapCopyFlag = m.prefs.plainCopy == 0
            toggles.soundScale = Int(m.prefs.soundVolume) * 0x1c
            toggles.appliedMusicOn = m.prefs.musicOn
        }
        // P1: File ▸ Abort Game's OK while paused on the map set `DAT_100a5106` — the loop test after the map ends it.
        if m.loopEndRequested { loopEnded = true }
        exit1 = m.exit1
        exit2 = m.exit2
        mapSprites = m.sprites
        aborted = m.aborted
        quitRequested = m.quitRequested
        worldMap = nil
        guard let n = m.result else {
            // `.FindCurrNode`'s `ExitToShell` (M l. 67155): the map has sent `.quit`; nothing returns.
            state = .quit
            wait = .later
            return
        }
        var items: [Work] = []
        if n < 0 {
            // `GammaFadeOut(10)`, `DAT_100a5106 = 1` (M l. 5827–5828).
            gammaFadeOut(now, &out, 10)
            loopEnded = true
        } else if !BuiltLevels.range.contains(n) {
            // ◇ D35: the level is not built yet — the report, then the map again at the node the player chose, nothing
            // new unlocked (the exits are −1 since the map's loop began). // later: Phases 4–6.
            report(BuiltLevels.notBuiltReport(n), &out)
            run([
                { f, _, _, out in f.openMap(level: Int16(truncatingIfNeeded: n), name: m.levelName, &out) },
                { f, now, _, out in f.mapEnded(continuing: continuing, now, &out) },
            ])
            return
        } else {
            // `OpenDefaultWorldLevel(n)`, `*feac = n`.
            levelNumber = n
        }
        items.append { f, _, _, _ in if f.quitRequested { f.quit() } }   // `fd50` → `.Quit` (never returns)
        items.append { f, _, _, out in
            // Not aborted (`fd4c == 0`): `save+0xc / +0x10 ←` the next level's start − 32 (M l. 5838–5839).
            if !f.aborted, let h = f.levelHeader(f.levelNumber) {
                f.saveBlock.playerX = Int32(h.startX) - 0x20
                f.saveBlock.playerY = Int32(h.startY) - 0x20
            }
            f.run(f.loopEnded ? [{ f, now, _, out in f.afterLoop(continuing: continuing, now, &out) }]
                              : f.loopIteration(continuing: continuing))
        }
        run(items)
    }

    // MARK: - After the loop

    /// The death test, `.AskToContinue`, the menu return.
    func afterLoop(continuing: Bool, _ now: UInt32, _ out: inout FrontOutput) {
        let dead = continuing ? died : globals.health < 1
        guard dead else {
            continueRequested = false
            run(menuReturn(continuing: continuing))
            return
        }
        // `.RestorePreExistingWindowBackground` (empty, raw `10005ec8`), then `.AskToContinue`.
        deathScreen = try? DeathScreen(saved: savedThisGame, prefs: toggles.live, resources: resources,
                                       scrollH: deathScroll.h, scrollV: deathScroll.v, entry255: deathEntry255)
        wait = .death
        run([{ f, _, _, out in
            let yes = f.deathScreen?.continues ?? false
            f.lastAskToContinue = yes
            f.deathScreen = nil
            if yes {
                // `*fd48 = 1`; return (no `ShowCursorSafe`): the menu loop's next `fd48` test runs Continue.
                f.continueRequested = true
                f.state = .mainMenu
                return
            }
            f.continueRequested = false
            out.present = true                                          // `MTRedraw`
            f.run(f.menuReturn(continuing: continuing))
        }])
    }

    /// The menu return (New Game M l. 5859–5873, Continue M l. 7083–7098), then `ShowCursorSafe`.
    private func menuReturn(continuing: Bool) -> [Work] {
        let music: [Work] = [
            { f, _, _, out in out.music += f.toggles.music.setAIFFMusic(Self.menuTrack) },
            { f, now, _, out in
                f.block(f.toggles.music.fadeAIFFMusic(direction: 1, ticks: 4, prefs: f.toggles.live), now, &out)
            },
        ]
        let menus: Work = { f, _, _, out in
            f.updateMenus(&out)
            out.present = true                                          // `MTRedraw`
        }
        var items: [Work] = [
            { f, now, _, out in f.gammaFadeOut(now, &out) },
            { f, _, _, out in f.drawMainMenu(&out) },
        ]
        items += continuing ? [menus] + music : music + [menus]
        items.append { f, now, _, out in f.gammaFadeIn(now, &out) }
        items.append { f, _, _, out in
            out.requests.append(.showCursor)
            f.state = .mainMenu
        }
        return items
    }
}

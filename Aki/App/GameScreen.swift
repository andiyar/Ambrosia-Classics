import AppKit
import AkiCore
import HectorShell

/// The game screen: `_CustomGameScreen` @ 0x12dbc (DC:7422) and the game branches of the controller's
/// mouse / key / redraw / pause entry points (method-map §1). P2.9 lands the stored state and the drawing
/// (`GameScreenDrawing.swift`, the QuickDraw pipeline of `_DrawGameTiles` DC:6244 … `_SelectCGButton`
/// DC:7729); the level lifecycle, the event executor and `pauseGame` are P2.10's, the input and the rest of
/// pause P2.11's. Every rect comes from `AkiGameArt`; the buffers are the original GWorlds — scratch2c the
/// composed screen, scratch3c the board buffer.
@MainActor final class GameScreen: AkiScreen {
    unowned let controller: AkiController

    /// The level being played (the board, the clock and the rule-only `_g` fields). Set by P2.10's
    /// `startLevel`; nil until then, and every drawing method returns at once while it is nil.
    private(set) var game: AkiGame?                                                       // P2.9

    init(controller: AkiController) {                                                     // P2.9
        self.controller = controller
    }

    /// The drawing routines that mutate `_g` in the original — `_CountOpenPairs` (g+0x60), the
    /// `_RedrawCustomTimeBar` step, the `_RedrawCustomGameScreen` time-bar tail (DC:6527), `_RedrawNoMorePairs`
    /// (DC:6420) — call the matching `AkiGame` mutator through here at the same point (Phase 2 ownership rule),
    /// so `game`'s setter stays private. nil (nothing run) while no level is loaded.
    /// Internal, not private: the drawing extension is a second file and P2.10's `startLevel` sets the game;
    /// S3's `private(set)` intent is "only GameScreen mutates".
    func updateGame<R>(_ body: (inout AkiGame) -> R) -> R? {
        guard game != nil else { return nil }
        return body(&game!)
    }

    // MARK: - Level start (P2.10)

    /// `_AnimationMapScreenToCustom` @ 0x10f5f (DC:6550–6658), then `_LoadLayout`'s tail (DC:7649–7650). The
    /// game is stored first (every drawing routine returns while it is nil). The music switches to the last
    /// game track; `background<g+0x8e>.png` replaces the background GWorld; LevelStart.aiff; the slide-in —
    /// the map (scratch2c, as the map loop left it) parts outward over the background; then g+0x66 = 1 (game),
    /// g+0x67/0x85/0x86/0x87 = 0, g+0x88 = 2 (DC:6626–6632); the clock starts (a8 = now, ac/b0/b4/c0 = 0,
    /// b8 = 150, g+0x84 = 0 and g+0x4c — `startClock`, DC:6628, DC:6633–6643); `_RedrawCustomGameScreen(0)`;
    /// then `_DrawGameTiles` (greyed reads g+0x60) and `_RedrawEntireWindow`. The trailing `_DrawToGWorld` after the
    /// slide loop (DC:6624, empty rects at s = 400) is not transcribed; the menu enabling and the "Give Up"
    /// title (DC:6644–6656) follow from `validateMenuItem` reading g.mode.
    func startLevel(_ game: AkiGame) {                                                    // P2.10
        self.game = game
        let g = controller.g
        let gw = controller.gworlds!
        controller.music.startGameTrack()
        do {
            gw.background = try controller.assets.png("background\(g.background)")
        } catch {
            fatalError("Aki: cannot load background\(g.background).png: \(error)")   // _CreateGWorld
        }
        controller.sound.play(.levelStart, volume: 0x100)
        slide(middle: gw.background, offset: AkiGameArt.slideIn(ticks:))
        g.mode = .game
        g.paused = false
        g.noPairsFlash = false
        g.pauseFlash = false
        g.flashFalling = false
        g.flashPhase = 2
        self.game?.startClock(now: ShellClock.ticks())
        redrawCustomGameScreen(tiles: false)
        drawGameTiles(greyed: self.game?.openPairs == 0)
        redrawEntireWindow()
    }

    // MARK: - Level end (P2.10)

    /// The leave branch of `_CustomGameScreen` (DC:7525–7539) then `_AnimationCustomGameScreenToMap` @ 0xdca0
    /// (DC:5481–5665). The board goes first (g+0x1ec = 0, the selected / hinted flags, `_DeleteAllCGTiles`,
    /// `_DeleteAllSTTiles` — and with it g+0x60 = 0, g+0xb4 = 0, g+0x1f1 = 0 of DC:5634–5648). Then tick.mp3
    /// stops (DC:5507); the track bookkeeping (map theme next, DC:5515–5521); map → scratch2c (DC:5562);
    /// GameOver.aiff when g+0x7d (DC:5564); the lit lantern of every unlocked level — all twelve flags
    /// p+0x200…0x20b (DC:5567–5590) — into scratch2c; background → scratch30 (DC:5594); the map theme starts if
    /// Music is on (DC:5596–5604); the slide-out — the map closes in over the background (scratch30,
    /// DC:5605–5631); then g+100 = 0, g+0x66 = 0 (map), g+0x68 = 0 (DC:5636–5638) and `_RedrawMapScreen`
    /// (DC:5663; the proverb when g.lost, P1.7). Not transcribed: g+0xc4 (the demo timer, Known delta 1), the
    /// level-2 demo alert (DC:7540–7583), the "Replay" retitle (Phase 3), the menu enabling (`validateMenuItem`).
    func leaveLevel() {                                                                   // P2.10
        game = nil
        let g = controller.g
        let gw = controller.gworlds!
        let p = controller.p
        let full = AkiGameArt.screenRect
        controller.sound.stop(.tick)
        controller.music.returnToMapTrack()
        QD.drawToGWorld(gw.map, gw.scratch2c, mask: gw.map, srcRect: full, dstRect: full, maskRect: full, mode: -9)
        if g.lost {
            controller.sound.play(.gameOver, volume: 0x100)
        }
        for i in 0..<12 where p.isUnlocked(i) {
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiMap.lanternSprite,
                            dstRect: AkiMap.litLanternDestination(i), maskRect: AkiMap.lanternStaticMask, mode: 1)
        }
        QD.drawToGWorld(gw.background, gw.scratch30, mask: gw.background, srcRect: full, dstRect: full,
                        maskRect: full, mode: -9)
        controller.music.startCurrentIfMusicOn()
        slide(middle: gw.scratch30, offset: AkiGameArt.slideOut(ticks:))
        g.quitRequested = false
        g.mode = .map
        g.endLevel = false
        controller.mapScreen.redrawMapScreen()
    }

    /// The slide loops of `_AnimationMapScreenToCustom` (DC:6597–6623) and `_AnimationCustomGameScreenToMap`
    /// (DC:5605–5631), a busy loop paced by the tick count alone: s from the unsigned tick delta (clamped to 60
    /// by `offset`); left and right from scratch2c, the middle from `middle`, flushed on the third copy only;
    /// until the clamped delta reaches 60. `CATransaction.flush()` puts each frame on screen (as `runFade`).
    private func slide(middle: ShellBitmap, offset: (Int) -> Int) {
        let gw = controller.gworlds!
        let start = ShellClock.ticks()
        var delta: Int
        repeat {
            delta = Int(ShellClock.ticks() &- start)
            let r = AkiGameArt.slideRects(offset(delta))
            controller.drawToWindow(gw.scratch2c, srcRect: r[0].src, dstRect: r[0].dst, flush: false)
            controller.drawToWindow(middle, srcRect: r[1].src, dstRect: r[1].dst, flush: false)
            controller.drawToWindow(gw.scratch2c, srcRect: r[2].src, dstRect: r[2].dst, flush: true)
            CATransaction.flush()
        } while delta < 60
    }

    // MARK: - The event executor (P2.10)

    /// Executes an `AkiGame` method's events in order. Re-entrant: the drawing routines call it
    /// (`redrawTimeBar`, `redrawNoMorePairs`), and `.redrawGameScreen` / `.pauseGame` reach those again. The
    /// game is always mutated in place (`self.game?.…`) and never held across a nested call or a modal run.
    func perform(_ events: [GameEvent]) {                                                 // P2.10
        let g = controller.g
        for event in events {
            switch event {
            case .playSound(let id, let volume): controller.sound.play(id, volume: volume)
            case .stopSound(let id): controller.sound.stop(id)
            case .stopMusic: controller.music.stopCurrent()
            case .startMusic: controller.music.startCurrentIfMusicOn()      // its p+0x20e > 1 test is DC:7712's
            case .playMovie(let volume): controller.music.playMovie(volume)
            case .redrawTile(let index): redrawTile(index)
            case .fade(let job): runFade(job)
            case .undoRedraw(let job): undoRedraw(job)
            case .redrawOpenPairs(let flush): redrawOpenPairs(flush: flush)
            case .redrawGameScreen(let tiles): redrawCustomGameScreen(tiles: tiles)
            case .flashButton(let n, let glow): flashButton(n, glow: glow)
            case .pressButton(let k): pressButton(k)
            case .pauseGame(let on): pauseGame(on)
            case .dialog(let id):
                // `_CreateNewDialog(0x47)` (DC:8005), "Tile Stacked" — the only dialog AkiGame emits.
                if id == 0x47 { _ = CarbonDialog.run("Stacked", controller: controller) }
            case .setNoPairsFlash(let on): g.noPairsFlash = on
            case .setLost: g.lost = true
            case .setCustomLost: g.customLost = true
            case .setEndLevel: g.endLevel = true
            case .recordLoss(let level): Stats.recordLoss(&controller.p, level: level)
            case .savePrefs: controller.savePrefs()
            case .applyMatchBonus: self.game?.applyMatchBonus()
            }
        }
    }

    // MARK: - Pause

    /// `_PauseGame(paused)` @ 0xd34b (DC:5123): g+0x7f = 0, g+0x67 = `on`, g+0x86 = `on`, then the clock /
    /// tick / music / redraw core (`pauseChange`). The tail's `_PlayMovie()` runs only in the editor
    /// (g+0x80, DC:5168–5171) — never on this screen.
    func pauseGame(_ on: Bool) {                                                          // P2.11 (landed in P2.10)
        let g = controller.g
        g.pausedBeforeExternal = false
        g.paused = on
        g.pauseFlash = on
        guard let events = self.game?.pauseChange(paused: on, now: ShellClock.ticks()) else { return }
        perform(events)
    }

    // MARK: AkiScreen

    /// `_CustomGameScreen` @ 0x12dbc (DC:7422–7590), one idle tick. The flash block every 5+ ticks
    /// (DC:7449–7464): the pause button while g+0x86 (tick.mp3 stopped first); unpaused, the hint button
    /// while there are pairs and g+0x84 (then cleared), the reshuffle button while g+0x85. The game block
    /// every 1+ ticks (DC:7466–7584): no tiles left → the win (not gated by pause, DC:7469–7508); then ONE
    /// g+0x68 test (DC:7510–7539) — not ended: unpaused → the clock, the elapsed time and the bar; ended →
    /// leave the level. A win therefore leaves in the same call, a time-out (ended by the bar's events) on the
    /// next game tick. Then `_LoopSound` while b8 < 15 (DC:7585; b8 survives the leave, so its last value is
    /// read) and `_LoopMusic(0)` (DC:7588). The leading `_GetMouseLocation` (DC:7446) has an unused result.
    func idle() {                                                                         // P2.10
        guard game != nil else { return }
        let g = controller.g
        if AkiGame.flashDue(now: ShellClock.ticks(), last: controller.flash) {
            if g.pauseFlash {
                controller.sound.stop(.tick)
                flashButton(5, glow: true)
            }
            if !g.paused {
                if (game?.openPairs ?? 0) != 0 && game?.idleHintFlash == true {
                    flashButton(1, glow: true)
                    self.game?.idleHintFlash = false
                }
                if g.noPairsFlash {
                    flashButton(3, glow: true)
                }
            }
            controller.flash = ShellClock.ticks()
        }
        var leftRemaining: Int?                    // g+0xb8 as the leave left it
        if AkiGame.gameTickDue(now: ShellClock.ticks(), last: controller.updateTimeCount) {
            if game?.tilesLeft == 0, let level = game?.levelIndex, let elapsed = game?.clock.elapsed {
                controller.music.stopCurrent()
                controller.sound.play(.levelComplete, volume: 0x100)
                Stats.recordWin(&controller.p, level: level, elapsed: elapsed,
                                difficulty: controller.p.difficulty ?? .medium)   // DC tests p+0x20c != 3
                controller.savePrefs()                                            // DC:7495 and DC:7503
                g.endLevel = true
                if controller.p.difficultyRaw != 3 && level > 11 {
                    g.guideFlag = false                                           // DC:7504–7506
                }
            }
            if !g.endLevel {
                if !g.paused {
                    let t = ShellClock.ticks()
                    self.game?.tickClock(now: t)
                    controller.updateTimeCount = ShellClock.ticks()
                    redrawTimeAccumulated(flush: false)
                    redrawTimeBar(now: t, flush: true)
                }
            } else {
                leftRemaining = game?.clock.remaining
                leaveLevel()
            }
        }
        if let remaining = leftRemaining ?? game?.clock.remaining, remaining < 15 {
            controller.sound.loopTick()
        }
        controller.music.loopMusic()
    }

    // MARK: AkiScreen (bodies land in P2.11; map-safe no-ops so the target builds)

    func mouseDown(at point: ShellPoint, event: NSEvent) {}
    func keyDown(_ event: NSEvent) {}
    func redrawWindow() {}
    func pause() {}
    func unpause() {}
    func shouldTerminate() -> Bool { true }
}

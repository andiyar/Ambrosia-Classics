import AkiCore
import Foundation
import HectorShell
import QuartzCore

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
    /// game is stored first (every drawing routine returns while it is nil). `background<g+0x8e>.png` replaces
    /// the background GWorld (DC:6582–6585), then the music switches to the last game track (the stop/switch
    /// of DC:6572–6579 and the start of DC:6586–6595 — stop-before-load is unobservable, so they are one call
    /// after the load); LevelStart.aiff; the slide-in —
    /// the map (scratch2c, as the map loop left it) parts outward over the background; then g+0x66 = 1 (game),
    /// g+0x67/0x85/0x86/0x87 = 0, g+0x88 = 2 (DC:6626–6632); the clock starts (a8 = now, ac/b0/b4/c0 = 0,
    /// b8 = 150, g+0x84 = 0 — `startClock`, DC:6628, DC:6633–6640); `_RedrawCustomGameScreen(0)`; g+0x4c = a
    /// fresh TickCount after it (DC:6641–6643); then `_DrawGameTiles` (greyed reads g+0x60) and `_RedrawEntireWindow`. The trailing `_DrawToGWorld` after the
    /// slide loop (DC:6624, empty rects at s = 400) is not transcribed; the menu enabling and the "Give Up"
    /// title (DC:6644–6656) follow from `validateMenuItem` reading g.mode.
    func startLevel(_ fresh: AkiGame) {                                                   // P2.10
        game = fresh
        let g = controller.g
        let gw = controller.gworlds!
        do {
            // gw's art scale (D11); a bad hd file falls back to the original at k = 1 (U3 review)
            gw.background = try controller.assets.artPNG("background\(g.background)", scale: gw.scale)
        } catch {
            fatalError("Aki: cannot load background\(g.background).png: \(error)")   // _CreateGWorld
        }
        controller.music.startGameTrack()
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
        self.game?.lastClickTick = ShellClock.ticks()                       // DC:6641–6643
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
    /// The proverb is a modal (C2): `next` — what the caller runs after the leave — runs once it closes.
    func leaveLevel(then next: @escaping () -> Void) {                                    // P2.10
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
        controller.mapScreen.redrawMapScreen(then: next)
    }

    /// The slide loops of `_AnimationMapScreenToCustom` (DC:6597–6623) and `_AnimationCustomGameScreenToMap`
    /// (DC:5605–5631), a busy loop paced by the tick count alone: s from the unsigned tick delta (clamped to 60
    /// by `offset`); left and right from scratch2c, the middle from `middle`, flushed on the third copy only;
    /// until the clamped delta reaches 60. `CATransaction.flush()` puts each frame on screen (as `runFade`,
    /// which also waits a tick per present). A pass whose clamped delta equals the last drawn one is skipped —
    /// its frame would be bit-identical — so the first pass and the final (delta 60) frame are always drawn;
    /// each pass drains its own pool.
    private func slide(middle: ShellBitmap, offset: (Int) -> Int) {
        let gw = controller.gworlds!
        let start = ShellClock.ticks()
        var drawn = -1
        var clamped = 0
        repeat {
            autoreleasepool {
                let delta = Int(ShellClock.ticks() &- start)
                clamped = (delta < 0 || delta > 60) ? 60 : delta        // the clamp of `slideIn` / `slideOut`
                guard clamped != drawn else { return }
                drawn = clamped
                let r = AkiGameArt.slideRects(offset(clamped))
                controller.drawToWindow(gw.scratch2c, srcRect: r[0].src, dstRect: r[0].dst, flush: false)
                controller.drawToWindow(middle, srcRect: r[1].src, dstRect: r[1].dst, flush: false)
                controller.drawToWindow(gw.scratch2c, srcRect: r[2].src, dstRect: r[2].dst, flush: true)
                CATransaction.flush()
            }
        } while clamped < 60
    }

    // MARK: - The event executor (P2.10)

    /// Executes an `AkiGame` method's events in order. Re-entrant: the drawing routines call it
    /// (`redrawTimeBar`, `redrawNoMorePairs`), and `.redrawGameScreen` / `.pauseGame` reach those again. The
    /// game is always mutated in place (`self.game?.…`) and never held across a nested call or a modal run.
    /// A `.dialog` STOPS the run: the events after it (`events[i+1...]`) resume in the dialog's completion
    /// (C2) — on the Mac before `runDialog` returns, so the order is the straight-through one.
    func perform(_ events: [GameEvent]) {                                                 // P2.10
        perform(events[...])
    }

    private func perform(_ events: ArraySlice<GameEvent>) {
        let g = controller.g
        for i in events.indices {
            switch events[i] {
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
                // `_CreateNewDialog(0x47)` (DC:8005), "Tile Stacked" — the only dialog AkiGame emits, only from
                // `selectTile` (followed by `.setLost, .setEndLevel[, .setCustomLost]`), whose events are only
                // ever run by the top-level `perform` in `selectTile(at:)` ← `mouseDown`, never a nested one.
                if id == 0x47 {
                    let rest = events[(i + 1)...]
                    controller.host.runDialog("Stacked", texts: [:]) { [self] _ in
                        perform(rest)
                    }
                    return
                } else {
                    assertionFailure("unexpected dialog id \(id)")
                }
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
    /// (g+0x80, DC:5168–5171) — never on this screen. `_HandleMenuCommand` case 9 calls it on the map too
    /// (DC:5194–5204): there the three flags are set and the core is skipped — no level, g+0x60 == 0, so the
    /// original draws and plays nothing (its `b8 < 15 → _StopSound(tick)` is silent: tick.mp3 stopped at the leave).
    func pauseGame(_ on: Bool) {                                                          // P2.11 (landed in P2.10)
        let g = controller.g
        g.pausedBeforeExternal = false
        g.paused = on
        g.pauseFlash = on
        guard let events = self.game?.pauseChange(paused: on, now: ShellClock.ticks()) else { return }
        perform(events)
    }

    // MARK: - Give Up (P2.11)

    /// `-[Controller abortGame]` @ 0x3cbc (DC:972–995): the "LoadLevel" dialog (`_CreateNewDialog(0x57)`, "Are
    /// you sure you want to end this game?"); `ok  ` (g+0x81) → g+0x81 = 0, g+0x68 = 1, the current music track
    /// stops, give-ups[g+0x90] += 1 (built-in levels only, in `Stats`; g+0x90 survives a leave, DC:990–993),
    /// `_SavePrefs`, YES; else NO. The game is not paused under the dialog (Q25) and no proverb follows
    /// (rules §14); the next game tick leaves the level (`idle`'s g+0x68 branch). Everything after the dialog
    /// runs in its completion (C2); `completion` gets the YES / NO.
    func abortGame(completion: @escaping (Bool) -> Void) {                               // P2.11
        let g = controller.g
        controller.host.runDialog("LoadLevel", texts: [:]) { [self] _ in
            guard g.dialogOK else { completion(false); return }
            g.dialogOK = false
            g.endLevel = true
            controller.music.stopCurrent()
            if let level = g.levelIndex {
                Stats.recordGiveUp(&controller.p, level: level)
            }
            controller.savePrefs()
            completion(true)
        }
    }

    // MARK: - Menu commands (P2.11)

    /// `_HandleMenuCommand` case 3 in the game (DC:5248–5261): raw difficulty > 1 ∧ b8 ≠ 0 → the "no more
    /// pairs" thaw and `_UndoLastCGMove` — gate, thaw and undo are all `AkiGame.undo`. No paused gate.
    func menuUndo() {                                                                     // P2.11
        guard let events = self.game?.undo(now: ShellClock.ticks()) else { return }
        perform(events)
    }

    /// `_HandleMenuCommand` case 4 (DC:5263–5266): g+0x60 ≠ 0 ∧ !g+0x67 → `_ShowNextCGHint`.
    func menuHint() {                                                                     // P2.11
        guard (game?.openPairs ?? 0) != 0, !controller.g.paused,
              let events = self.game?.showNextHint() else { return }
        perform(events)
    }

    /// `_HandleMenuCommand` case 6 (DC:5268–5278): !g+0x67 → (g+0x60 == 0: the unguarded thaw) and
    /// `_ReshuffleCustomTiles` — both `AkiGame.reshuffle(fromButton: false, …)`.
    func menuReshuffle() {                                                                // P2.11
        guard !controller.g.paused else { return }
        var rng = SystemRandomNumberGenerator()
        guard let events = self.game?.reshuffle(fromButton: false, now: ShellClock.ticks(), using: &rng) else { return }
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
    /// The leave can show the proverb (a modal, C2): the `_LoopSound` / `_LoopMusic` tail then runs in its
    /// continuation, after the proverb closes — as on the Mac, where the modal ran inside the leave.
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
                let leftRemaining = game?.clock.remaining              // g+0xb8 as the leave left it
                leaveLevel { [self] in
                    idleTail(remaining: leftRemaining)
                }
                return
            }
        }
        idleTail(remaining: game?.clock.remaining)
    }

    /// `_CustomGameScreen`'s tail (DC:7585–7588): `_LoopSound` while b8 < 15, then `_LoopMusic(0)`.
    private func idleTail(remaining: Int?) {
        if let remaining, remaining < 15 {
            controller.sound.loopTick()
        }
        controller.music.loopMusic()
    }

    /// The game branch of `-[Controller mouseDown:]` @ 0x4489 (DC:1347–1388); `point` is `_GetMouseLocation`.
    /// g+0x4c = now, and the idle hint flash (g+0x84) if on is cleared and its button drawn up (DC:1348–1353).
    /// v 555…587 (`(ushort)(v − 0x22b) < 0x21`, DC:1354) → `_SelectCGButton` (DC:1356). Else, unpaused
    /// (DC:1363): a click within `GetDblTime() >> 1` ticks of the last remembered one (DC:1368–1371) selects only
    /// when it moved > 1 px in both v and h from the remembered point and there are pairs, and is not
    /// remembered (DC:1372–1378); any other click is remembered — ivar 0x44 = now, select when there are pairs,
    /// then ivar 0x50 = the point (DC:1381–1386). The editor's `_CreateTile` / `_SelectLevelButton` arms are P3.4's.
    func mouseDown(at point: ShellPoint, click: ShellClick) {                             // P2.11
        guard game != nil else { return }
        let g = controller.g
        if self.game?.noteClick(now: ShellClock.ticks()) == true {
            flashButton(1, glow: false)
        }
        if (555...587).contains(point.v) {
            var rng = SystemRandomNumberGenerator()
            guard let events = self.game?.buttonClick(h: point.h, paused: g.paused, now: ShellClock.ticks(),
                                                      using: &rng) else { return }
            perform(events)
        } else if !g.paused {
            let doubleClickTicks = controller.host.doubleClickTicks                       // GetDblTime (Q29)
            if AkiGame.isRepeatClick(now: ShellClock.ticks(), lastTick: controller.lastTick,
                                     doubleClickTicks: doubleClickTicks) {
                let last = controller.lastMouse
                if AkiGame.movedEnough(h: point.h, v: point.v, lastH: last.h, lastV: last.v),
                   (game?.openPairs ?? 0) > 0 {
                    selectTile(at: point)
                }
            } else {
                controller.lastTick = ShellClock.ticks()
                if (game?.openPairs ?? 0) > 0 {
                    selectTile(at: point)
                }
                // Left after `selectTile` although its run can stop at the Stacked dialog (C2): the write is
                // independent of the dialog (a fixed point) and unobservable while it is up — ivar 0x50 is read
                // only by this method, and no click reaches a screen under a modal (AkiHost) — so on a host
                // that returns before the dialog closes the state the next click sees is the same.
                controller.lastMouse = point
            }
        }
    }

    /// `_SelectCGTile(point)` (DC:8023) with the Tile Animation preference (p+0x213).
    private func selectTile(at point: ShellPoint) {
        let animate = controller.p.tileAnimation != 0
        guard let events = self.game?.selectTile(h: point.h, v: point.v, tileAnimation: animate) else { return }
        perform(events)
    }

    /// The game branch of `-[Controller keyDown:]` @ 0x42eb (DC:1265–1285): the first character U+001B (Esc)
    /// → `abortGame`; every other key does nothing (menu key equivalents arrive through the menu).
    func keyDown(_ key: ShellKey) {                                                       // P2.11
        guard key.characters.utf16.first == 0x1B else { return }
        abortGame { _ in }                                         // nothing follows
    }

    /// A Remaster switch in the game (D11, `AkiController.setRemastered`): the new GWorlds hold no board and no
    /// frame. The board buffer (scratch3c) is rebuilt by `_DrawGameTiles` — inside the recompose when unpaused;
    /// explicitly first when paused, where the screen leaves the tiles off but later partial redraws
    /// (`_RedrawTile`, the fade) copy from it — with the greyed look read as `_RedrawCustomGameScreen` reads it
    /// (g+0x60 == 0). Then `composeCustomGameScreen(tiles: !g+0x67)`: `_redrawWindow`'s draws exactly — the pause
    /// scroll, the "no more pairs" scroll over greyed tiles, the selected and hinted tiles, the plate, the time
    /// bar, the open pairs and the elapsed clock as they were — with NO game or clock writes (U3 review, pixels
    /// only: the full redraw's `enterNoMorePairs`, Practice a8 reset and cap penalty would change the game).
    func redrawForArtChange() {
        guard let game else { return }
        if controller.g.paused {
            drawGameTiles(greyed: game.openPairs == 0)
        }
        composeCustomGameScreen(tiles: !controller.g.paused)
    }

    /// The switch's synchronous art decode ran on wall time: `ticks` of it are discounted from a running level
    /// clock (`AkiGame.discountTicks`), so the remaining / elapsed time read as if the switch took no time.
    func discountArtSwitch(ticks: UInt32) {
        updateGame { $0.discountTicks(ticks) }
    }

    /// `-[Controller _redrawWindow]` @ 0x3bde (DC:932, R6): `_RedrawCustomGameScreen(!g+0x67)`.
    func redrawWindow() {                                                                 // P2.11
        guard game != nil else { return }
        redrawCustomGameScreen(tiles: !controller.g.paused)
    }

    /// `-[Controller pause]` @ 0x3c1f (DC:948–969): b8 < 16 → tick.mp3 stops; with pairs, unpaused →
    /// `_PauseGame(1)`, already paused → g+0x7f = 1 (so `unpause` leaves the player's own pause alone).
    func pause() {                                                                        // P2.11
        guard let remaining = game?.clock.remaining, let openPairs = game?.openPairs else { return }
        let g = controller.g
        if remaining < 16 {
            controller.sound.stop(.tick)
        }
        guard openPairs != 0 else { return }
        if !g.paused {
            pauseGame(true)
        } else {
            g.pausedBeforeExternal = true
        }
    }

    /// `-[Controller unpause]` @ 0x3c85 (R6): with pairs and g+0x7f == 0 → `_PauseGame(0)`.
    func unpause() {                                                                      // P2.11
        guard let openPairs = game?.openPairs, openPairs != 0, !controller.g.pausedBeforeExternal else { return }
        pauseGame(false)
    }

    /// The game branch of `-[Controller applicationShouldTerminate:]` (DC:226): `abortGame` decides.
    func shouldTerminate(_ completion: @escaping (Bool) -> Void) {                        // P2.11
        abortGame(completion: completion)
    }
}

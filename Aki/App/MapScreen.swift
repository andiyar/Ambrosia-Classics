import AkiCore
import HectorShell

/// The map: `_MapScreen` @ 0x6652 (the idle loop, DC:2355), `_RedrawMapScreen` @ 0x70cd (DC:2606),
/// `_SelectMapArea` @ 0x78c2 (DC:2782), `_SelectMenuOptions` @ 0x8041 (DC:2949) and the map branch of
/// `-[Controller mouseDown:]` (DC:1312). Every rect comes from `AkiMap`; the buffers are the original
/// GWorlds — scratch2c is the composed frame, scratch30 the clean map (lit lanterns, bar) it restores from.
@MainActor final class MapScreen: AkiScreen {
    private unowned let controller: AkiController

    /// `LastColor` / `ColorDown` (Controller ivars 0x48 / 0x4d): the blinking lantern's ping-pong phase.
    var blink = AkiMap.Blink()
    /// The previewed lantern (Controller ivar 0x4e), nil = −9 (none).
    var lastPreview: Int?

    private static let full = QDRect(left: 0, top: 0, right: 800, bottom: 600)

    init(controller: AkiController) {
        self.controller = controller
    }

    // MARK: _RedrawMapScreen

    /// `_RedrawMapScreen`: map → scratch2c; both bar arrows at rest; the static lit lanterns below the
    /// blinking one (75×73 sprite into 74×72, QuickDraw stretch); the difficulty word; scratch2c →
    /// scratch30. No window draw. Then the proverb when `g.lost` (a modal, C2): `g.lost = false` and `next` — the
    /// caller's following code — run once it closes. Only `GameScreen.leaveLevel` can arrive with `g.lost` set
    /// (it is set by the game's events and cleared here on the way back to the map); the launch and the
    /// difficulty arrows (`selectMenuOptions`) always see it false, so their `next` runs before this returns.
    func redrawMapScreen(then next: @escaping () -> Void) {
        composeMapBuffers()

        let g = controller.g
        let finish = {
            g.lost = false
            // The customLost / tryAgainOK tail (`_CreateNewDialog(0x53)`, `_LoadCustomLevel`) is P3.6's.
            next()
        }
        if g.lost {
            controller.host.showRandomProverb(completion: finish)   // _RandomProverbScreen (g.lost is set from Phase 2 on)
        } else {
            finish()
        }
    }

    /// The drawing half of `_RedrawMapScreen` (no state, no window draw): map, arrows, lit lanterns and the
    /// difficulty word into scratch2c, then scratch2c → scratch30.
    private func composeMapBuffers() {
        let gw = controller.gworlds!
        let p = controller.p
        let full = Self.full
        QD.drawToGWorld(gw.map, gw.scratch2c, mask: gw.map, srcRect: full, dstRect: full, maskRect: full, mode: -9)
        QD.drawToGWorld(gw.arrow, gw.scratch2c, mask: gw.arrow, srcRect: AkiMap.leftArrowSprite,
                        dstRect: AkiMap.leftArrowRest, maskRect: AkiMap.leftArrowMask, mode: 1)
        QD.drawToGWorld(gw.arrow, gw.scratch2c, mask: gw.arrow, srcRect: AkiMap.rightArrowSprite,
                        dstRect: AkiMap.rightArrowRest, maskRect: AkiMap.rightArrowMask, mode: 1)
        for i in 0..<AkiMap.litLanternCount(settings: p) where p.isUnlocked(i) {
            QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiMap.lanternSprite,
                            dstRect: AkiMap.litLanternDestination(i), maskRect: AkiMap.lanternStaticMask, mode: 1)
        }
        let d = Int(p.difficultyRaw)
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiMap.difficultyWord(d),
                        dstRect: AkiMap.difficultyWordDestination, maskRect: AkiMap.difficultyWordMask(d), mode: 1)
        QD.drawToGWorld(gw.scratch2c, gw.scratch30, mask: gw.scratch2c, srcRect: full, dstRect: full, maskRect: full, mode: -9)
    }

    /// A Remaster switch on the map (D11, `AkiController.setRemastered`): the new GWorlds hold no frame yet, so
    /// the map is recomposed as `_RedrawMapScreen` composes it (without its proverb / continuation — `g.lost` is
    /// never set on the map), then the state the idle loop has drawn over it since is redrawn as it stands — the
    /// blinking lantern at its CURRENT phase (no step) and the current hover preview (no Preview.aiff, no
    /// `lastPreview` change) — and the frame is presented. The next idle tick carries on from here unchanged.
    func redrawForArtChange() {
        composeMapBuffers()
        let gw = controller.gworlds!
        let p = controller.p
        let blinkRect = AkiMap.blinkDestination(AkiMap.blinkingLantern(settings: p))
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiMap.lanternSprite,
                        dstRect: blinkRect, maskRect: AkiMap.blinkMasks[blink.phase], mode: 1)
        if let preview = lastPreview {
            let strip = AkiMap.previewStrip(preview)
            QD.drawToGWorld(gw.previews, gw.scratch2c, mask: gw.previews, srcRect: strip,
                            dstRect: AkiMap.previewDestination, maskRect: strip, mode: -9)
            if !p.isUnlocked(preview) {
                QD.drawToGWorld(gw.notavail, gw.scratch2c, mask: gw.notavail, srcRect: AkiMap.lockedOverlay,
                                dstRect: AkiMap.lockedOverlayDestination, maskRect: AkiMap.lockedOverlayMask, mode: 1)
            }
        }
        controller.drawToWindow(gw.scratch2c, srcRect: Self.full, dstRect: Self.full, flush: true)
    }

    // MARK: _MapScreen (one idle tick)

    func idle() {
        let mouse = controller.getMouseLocation()
        guard AkiMap.tickDue(now: ShellClock.ticks(), last: controller.lastTimeCount) else { return }
        let gw = controller.gworlds!
        let p = controller.p

        // The blinking lantern: step the phase, restore its rect from the clean map, deep-mask the sprite.
        let lantern = AkiMap.blinkingLantern(settings: p)
        blink.step()
        let blinkRect = AkiMap.blinkDestination(lantern)
        QD.drawToGWorld(gw.scratch30, gw.scratch2c, mask: gw.scratch30, srcRect: blinkRect,
                        dstRect: blinkRect, maskRect: blinkRect, mode: -9)
        QD.drawToGWorld(gw.misc, gw.scratch2c, mask: gw.misc, srcRect: AkiMap.lanternSprite,
                        dstRect: blinkRect, maskRect: AkiMap.blinkMasks[blink.phase], mode: 1)
        controller.lastTimeCount = ShellClock.ticks()

        // The hover preview: the LAST lantern box holding the mouse.
        if let hover = AkiMap.hoverIndex(h: mouse.h, v: mouse.v) {
            if hover != lastPreview {
                controller.sound.play(.preview, volume: 0x80)
                let strip = AkiMap.previewStrip(hover)
                QD.drawToGWorld(gw.previews, gw.scratch2c, mask: gw.previews, srcRect: strip,
                                dstRect: AkiMap.previewDestination, maskRect: strip, mode: -9)
                if !p.isUnlocked(hover) {
                    QD.drawToGWorld(gw.notavail, gw.scratch2c, mask: gw.notavail, srcRect: AkiMap.lockedOverlay,
                                    dstRect: AkiMap.lockedOverlayDestination, maskRect: AkiMap.lockedOverlayMask, mode: 1)
                }
                lastPreview = hover
            }
        } else {
            let restore = AkiMap.previewRestore
            QD.drawToGWorld(gw.map, gw.scratch2c, mask: gw.map, srcRect: restore, dstRect: restore,
                            maskRect: restore, mode: -9)
            lastPreview = nil
        }

        controller.music.loopMusic()
        controller.drawToWindow(gw.scratch2c, srcRect: Self.full, dstRect: Self.full, flush: true)
    }

    // MARK: Input

    /// The map branch of `-[Controller mouseDown:]`: the bottom bar → `_SelectMenuOptions`, else `_SelectMapArea`
    /// (with the click's modifiers: the Option key the original polled). Nothing follows either call.
    func mouseDown(at point: ShellPoint, click: ShellClick) {
        if AkiMap.isBarClick(v: point.v) {
            selectMenuOptions(point)
        } else {
            selectMapArea(point, optionDown: click.modifiers.contains(.option))
        }
    }

    /// `-[Controller keyDown:]` has no map branch (method-map §1): menu key equivalents arrive through the menu.
    func keyDown(_ key: ShellKey) {}

    /// `_SelectMapArea` @ 0x78c2 (DC:2782, Research note 13): one "Unavailable" dialog
    /// (`_CreateNewDialog(0x28)`) per locked lantern hit; the chosen level is the last unlocked hit (Option
    /// bypasses the locks — levels.md §4 MED, Q51); then the "guide" splash while level 2 is locked and
    /// g+0x22b is set; the Practice alert (`alertWithMessageText:…`, Cancel → g+0x7c); the Level
    /// Description when p+0x214 is set; and `_LoadLayout` unless one of them cancelled — else g+0x7c is
    /// cleared. The trailing `_g`+0xc4 bookkeeping is not replicated (INDEX NOT RESOLVED #3, never read).
    /// Every modal is completion style (C2), so the steps are one continuation chain — the same order, the same
    /// `g.levelIndex` / `g.cancelStart` writes and `p` reads at the same points.
    func selectMapArea(_ point: ShellPoint, optionDown: Bool) {
        let g = controller.g
        g.levelIndex = nil
        let selection = AkiMap.select(h: point.h, v: point.v, optionDown: optionDown, settings: controller.p)
        runUnavailableDialogs(selection.unavailableDialogs) { [self] in
            guard let chosen = selection.chosen else { return }
            g.levelIndex = chosen
            showGuideIfNeeded { [self] in
                practiceAlertIfNeeded(level: chosen) { [self] in
                    guard !g.cancelStart else {
                        g.cancelStart = false
                        return
                    }
                    levelDescriptionIfNeeded(level: chosen) { [self] in
                        if !g.cancelStart {
                            controller.loadLayout()
                            return
                        }
                        g.cancelStart = false
                    }
                }
            }
        }
    }

    /// `_SelectMapArea`: one "Unavailable" dialog (`_CreateNewDialog(0x28)`) per locked lantern hit, in turn.
    private func runUnavailableDialogs(_ count: Int, then next: @escaping () -> Void) {
        guard count > 0 else { return next() }
        controller.host.runDialog("Unavailable", texts: [:]) { [self] _ in
            runUnavailableDialogs(count - 1, then: next)
        }
    }

    /// `_SelectMapArea`: the "guide" splash while level 2 is locked and g+0x22b is set.
    private func showGuideIfNeeded(then next: @escaping () -> Void) {
        guard AkiMap.showsGuide(settings: controller.p, guideFlag: controller.g.guideFlag) else { return next() }
        controller.host.showSplash(named: "guide", timeout: 0, completion: next)
    }

    /// `_SelectMapArea`: the Practice alert when the level needs it; g+0x7c = (alternate) — Cancel.
    private func practiceAlertIfNeeded(level: Int, then next: @escaping () -> Void) {
        guard AkiMap.needsPracticeAlert(level: level, settings: controller.p) else { return next() }
        let g = controller.g
        controller.host.runPracticeAlert { cancelled in
            g.cancelStart = cancelled
            next()
        }
    }

    /// `_SelectMapArea`: the Level Description when p+0x214 is set (its Cancel sets g+0x7c).
    private func levelDescriptionIfNeeded(level: Int, then next: @escaping () -> Void) {
        guard controller.p.showDescription != 0 else { return next() }
        controller.host.runLevelDescription(layout: level, custom: false, completion: next)
    }

    /// `_SelectMenuOptions`: Preferences, Quit, or a difficulty arrow (flash the pressed arrow into the
    /// window, `tilehit.mp3`, cycle, redraw the map buffers, save). The pressed look stays on screen until
    /// the next map tick copies scratch2c to the window.
    func selectMenuOptions(_ point: ShellPoint) {
        let up: Bool
        switch AkiMap.barAction(h: point.h) {
        case .preferences:
            controller.host.showPreferences()
            return
        case .quit:
            // On the Mac `terminate:` on the map does not return (the map's `shouldTerminate` is YES); the flag
            // write is kept after it, as in the original.
            controller.host.quit()
            controller.g.quitRequested = true
            return
        case .difficultyPrevious:
            flashArrow(rest: AkiMap.rightArrowRest, sprite: AkiMap.rightArrowSprite,
                       mask: AkiMap.rightArrowMask, pressed: AkiMap.rightArrowPressed)
            up = false
        case .difficultyNext:
            flashArrow(rest: AkiMap.leftArrowRest, sprite: AkiMap.leftArrowSprite,
                       mask: AkiMap.leftArrowMask, pressed: AkiMap.leftArrowPressed)
            up = true
        case nil:
            return
        }
        controller.p.difficultyRaw = AkiMap.cycleDifficulty(controller.p.difficultyRaw, up: up)
        redrawMapScreen { [self] in                     // g.lost is false on the map: no proverb, runs inline
            controller.savePrefs()
        }
    }

    private func flashArrow(rest: QDRect, sprite: QDRect, mask: QDRect, pressed: QDRect) {
        let gw = controller.gworlds!
        QD.drawToGWorld(gw.map, gw.scratch2c, mask: gw.map, srcRect: rest, dstRect: rest, maskRect: rest, mode: -9)
        QD.drawToGWorld(gw.arrow, gw.scratch2c, mask: gw.arrow, srcRect: sprite, dstRect: pressed, maskRect: mask, mode: 1)
        controller.drawToWindow(gw.scratch2c, srcRect: rest, dstRect: rest, flush: true)
        controller.sound.play(.tilehit, volume: 0x100)
    }

    // MARK: AkiScreen (map: no-ops)

    /// `-[Controller _redrawWindow]` returns at once on the map.
    func redrawWindow() {}
    /// `-[Controller pause]` / `unpause` act only in the game.
    func pause() {}
    func unpause() {}
    /// `applicationShouldTerminate:` on the map: terminate now.
    func shouldTerminate(_ completion: @escaping (Bool) -> Void) { completion(true) }
}

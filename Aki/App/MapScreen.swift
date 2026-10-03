import AppKit
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
    /// scratch30. No window draw.
    func redrawMapScreen() {
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

        let g = controller.g
        if g.lost {
            // P1.8 (`AkiSplash`) — `_RandomProverbScreen()` belongs here; g.lost is never set before Phase 2.
        }
        g.lost = false
        // The customLost / tryAgainOK tail (`_CreateNewDialog(0x53)`, `_LoadCustomLevel`) is P3.6's.
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

    /// The map branch of `-[Controller mouseDown:]`: the bottom bar → `_SelectMenuOptions`, else `_SelectMapArea`.
    func mouseDown(at point: ShellPoint, event: NSEvent) {
        if AkiMap.isBarClick(v: point.v) {
            selectMenuOptions(point)
        } else {
            selectMapArea(point)
        }
    }

    /// `-[Controller keyDown:]` has no map branch (method-map §1): menu key equivalents arrive through the menu.
    func keyDown(_ event: NSEvent) {}

    /// `_SelectMapArea`, Phase 1 / P1.7 part: only the chosen-level path (`_LoadLayout`). The Unavailable
    /// dialog, guide splash, Practice alert and Level Description are P1.10's.
    func selectMapArea(_ point: ShellPoint) {
        let g = controller.g
        g.levelIndex = nil
        let selection = AkiMap.select(h: point.h, v: point.v, optionDown: NSEvent.modifierFlags.contains(.option),
                                      settings: controller.p)
        guard let chosen = selection.chosen else { return }
        g.levelIndex = chosen
        controller.loadLayout()
    }

    /// `_SelectMenuOptions`: Preferences, Quit, or a difficulty arrow (flash the pressed arrow into the
    /// window, `tilehit.mp3`, cycle, redraw the map buffers, save). The pressed look stays on screen until
    /// the next map tick copies scratch2c to the window.
    func selectMenuOptions(_ point: ShellPoint) {
        let up: Bool
        switch AkiMap.barAction(h: point.h) {
        case .preferences:
            controller.showPreferences(nil)
            return
        case .quit:
            NSApp.terminate(nil)
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
        redrawMapScreen()
        controller.savePrefs()
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
    func shouldTerminate() -> Bool { true }
}

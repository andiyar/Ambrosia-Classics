@testable import BubbleTroubleCore
import Foundation
import XCTest

/// C6 — the front end (plan 2026-10-04 btx-playable §C6; FI §1–§2) against `_InitMac @ 0000563c`, `_Interface
/// @ 0000b500`, `_DrawMainMenu @ 00009eb3`, `_HandleMSMouse @ 0000b001`, `_FlashButton @ 000078e0`, `_DrawInterfaceText
/// @ 0000898d`, `_ProcessMenuStars @ 0001075d`, `_DemoButton @ 0000af71`, `_DoLevelSelect @ 0000d31e`.
/// Data-gated on `HECTORKIT_DATA_BTX` (always set under G1).
final class FrontEndTests: XCTestCase {

    // MARK: Helpers

    private func gameData() throws -> BTXGameData {
        try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
    }

    private func frontEnd(_ data: BTXGameData, prefs: BTXPrefs = .defaults, today: (Int, Int) = (3, 3))
        -> FrontEnd {
        FrontEnd(data: data, prefs: prefs, highScores: .empty, registeredName: "Ben", today: { (today.0, today.1) })
    }

    private static let away = MousePoint(h: 600, v: 20, button: false)

    /// Ticks `n` times; returns the outputs, one per tick.
    @discardableResult
    private func ticks(_ fe: FrontEnd, _ n: Int, now: inout UInt32, mouse: MousePoint = away,
                       keys: HeldKeys = HeldKeys()) -> [SessionOutput] {
        (0..<n).map { _ in
            defer { now += 1 }
            return fe.tick(now: now, keys: keys, mouse: mouse)
        }
    }

    /// Ticks until `condition` fails; returns everything emitted.
    @discardableResult
    private func ticks(_ fe: FrontEnd, now: inout UInt32, mouse: MousePoint = away, limit: Int = 3000,
                       while condition: (FrontEnd) -> Bool) -> SessionOutput {
        var all = SessionOutput()
        var n = 0
        while condition(fe) && n < limit {
            all.append(fe.tick(now: now, keys: HeldKeys(), mouse: mouse))
            now += 1
            n += 1
        }
        XCTAssertLessThan(n, limit, "tick loop did not finish")
        return all
    }

    /// Splash → menu.
    private func toMenu(_ fe: FrontEnd, now: inout UInt32) {
        ticks(fe, now: &now) { $0.phase != .menu }
    }

    /// Runs a started demo: its wipe on ticks, `frames` frames, then `interrupt` (key) and the return to the menu.
    private func runDemo(_ fe: FrontEnd, now: inout UInt32, frames: Int = 3) -> SessionOutput {
        var all = SessionOutput()
        all.append(ticks(fe, now: &now) { $0.session?.phase == .wipe })
        for _ in 0..<frames { all.append(fe.frame(keys: HeldKeys())) }
        _ = fe.key(0x00, chars: "a", modifiers: KeyModifiers())
        all.append(fe.frame(keys: HeldKeys()))
        all.append(ticks(fe, now: &now) { $0.phase != .menu })
        return all
    }

    private func sounds(_ outs: [SessionOutput]) -> [SoundCue] { outs.flatMap(\.sounds) }

    // MARK: Splash

    func testSplashTimings() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        let outs = ticks(fe, 400, now: &now)
        func at(_ t: UInt32) -> SessionOutput { outs[Int(t - 1000)] }
        let logo = MainMenu.centred(data: data, pict: 200)
        XCTAssertEqual(logo, QDRect(top: 69, left: 170, bottom: 410, right: 470))        // 300 × 341 centred
        XCTAssertEqual(at(1000).drawOps, [.fillBlack(target: .screen), .fillBlack(target: .comp),
                                          .pict(id: 200, dst: logo, target: .comp), .wipeOut(step: 4)])
        // `_WipeScreenOut(4)` = 63 advances, then held until 130 ticks after it began → black wiped in at 1130.
        XCTAssertEqual(FrontEnd.wipeOutAdvances4, 63)
        for t in UInt32(1001)..<1130 { XCTAssertEqual(at(t), SessionOutput(), "tick \(t)") }
        XCTAssertEqual(at(1130).drawOps, [.fillBlack(target: .comp), .wipe(step: 4)])
        // `_WipeScreen(4)` = 62 advances → the title at 1192; 63 more → the bar + intro sound at 1255.
        XCTAssertEqual(at(1192).drawOps, [.fillBlack(target: .comp),
                                          .pict(id: 9011, dst: MainMenu.centred(data: data, pict: 9011), target: .comp),
                                          .wipeOut(step: 4)])
        let bar = at(1255)
        XCTAssertEqual(bar.sounds, [SoundCue(slot: 27, priority: 0x14, delayFrames: 0)])
        XCTAssertEqual(bar.drawOps.first, .frameRect(QDRect(top: 443, left: 248, bottom: 453, right: 392),
                                                     rgb: 0x007f7f, target: .screen))
        let fills = bar.drawOps.filter { if case .fillRect(_, 0xffdf00, .screen) = $0 { return true }; return false }
        XCTAssertEqual(fills.count, 1 + data.sprites.setCount + 1 + 1 + 48 + 1)
        XCTAssertEqual(fills.first, .fillRect(QDRect(top: 445, left: 250, bottom: 451, right: 251), rgb: 0xffdf00,
                                              target: .screen))                     // 140 · 1/95 → 1 px
        XCTAssertEqual(fills.last, .fillRect(FrontEnd.progressRect, rgb: 0xffdf00, target: .screen))   // clamped
        // ≥ 60 ticks after the bar: `_Interface` — title music, the menu, `_WipeScreen(6)` (42 advances).
        for t in UInt32(1256)..<1315 { XCTAssertEqual(at(t), SessionOutput(), "tick \(t)") }
        XCTAssertEqual(at(1315).music, [.load(set: 3)])
        XCTAssertEqual(at(1315).drawOps.last, .wipe(step: 6))
        XCTAssertEqual(at(1357 - 1).music, [])
        XCTAssertEqual(at(1357).music, [.start])
        XCTAssertEqual(at(1357).drawOps.first, .compToScreen(MainMenu.screenRect))
        XCTAssertEqual(fe.phase, .menu)
        XCTAssertEqual(fe.latches, SessionConfig().latches)                // process seed 1 → u 1, L 15

        // Full screen: CGDisplayFades instead of wipes, pictures straight to the screen.
        var full = BTXPrefs.defaults
        full.fullScreen = true
        full.sfxVolume = 1                                                 // SFX off: no intro sound
        let fs = frontEnd(data, prefs: full)
        now = 1000
        let fouts = ticks(fs, 300, now: &now)
        XCTAssertEqual(fouts[0].requests, [.hideCursor, .displayFade(toBlack: true, seconds: 0.1)])
        XCTAssertEqual(fouts[6].requests, [.displayFade(toBlack: false, seconds: 0.6)])
        XCTAssertEqual(fouts[6].drawOps.last, .pict(id: 200, dst: logo, target: .screen))
        XCTAssertEqual(fouts[136].requests, [.displayFade(toBlack: true, seconds: 0.6)])      // 1006 + 130
        XCTAssertEqual(fouts[172].requests, [.displayFade(toBlack: false, seconds: 0.6)])
        XCTAssertTrue(fouts[208].sounds.isEmpty)
        XCTAssertEqual(fouts[268].music, [.load(set: 3)])

        // A birthday (17 Sep): DLOG 3001 first, the splash waits for it.
        let bd = frontEnd(data, today: (9, 17))
        now = 1000
        let b0 = ticks(bd, 5, now: &now)
        XCTAssertEqual(b0[0].requests, [.modalDialog(id: 3001)])
        XCTAssertTrue(b0[1...].allSatisfy { $0 == SessionOutput() })
        XCTAssertEqual(bd.dialogDone().drawOps.last, .wipeOut(step: 4))
    }

    // MARK: Main menu

    func testMenuButtonRectsAndSources() throws {
        let data = try gameData()
        let menu = MainMenu(data: data)
        XCTAssertEqual(menu.destinations, MainMenu.fallbackDestinations)            // Rect 1–6, L,T,R,B order
        XCTAssertEqual(menu.backdropRect, MainMenu.screenRect)                      // PICT 913 is 640 × 480
        XCTAssertEqual(MainMenu.sourceRects[.newGame], QDRect(top: 0, left: 0, bottom: 34, right: 150))
        XCTAssertEqual(MainMenu.sourceRects[.quit], QDRect(top: 170, left: 0, bottom: 204, right: 67))
        let ops = menu.drawOps(info: "x")
        XCTAssertEqual(Array(ops.prefix(4)), [
            .pict(id: 913, dst: MainMenu.screenRect, target: .comp),
            .compToSpriteWorld(src: QDRect(top: 425, left: 157, bottom: 445, right: 482),
                               dst: QDRect(top: 92, left: 0, bottom: 112, right: 325)),
            .pict(id: 9100, dst: QDRect(top: 0, left: 0, bottom: 300, right: 300), target: .bgnd),
            .pict(id: 9012, dst: QDRect(top: 187, left: 229, bottom: 201, right: 411), target: .comp),
        ])
        XCTAssertEqual(ops[4], .pictSlice(id: 9100, src: QDRect(top: 0, left: 0, bottom: 34, right: 150),
                                          dst: QDRect(top: 228, left: 165, bottom: 262, right: 315), target: .comp))
        XCTAssertEqual(ops.count, 4 + 6 + 1)                                        // no Register button
        XCTAssertEqual(ops.last, .infoText("x", colour: 0x111))
        // `_FlashButton(2)`: the highlighted source is offset 150 right.
        XCTAssertEqual(menu.flashOnOps(.demo)[1],
                       .pictSlice(id: 9100, src: QDRect(top: 34, left: 150, bottom: 68, right: 221),
                                  dst: QDRect(top: 276, left: 165, bottom: 310, right: 236), target: .comp))
        XCTAssertEqual(menu.button(at: 165, 228), .newGame)
        XCTAssertNil(menu.button(at: 315, 240))                                     // right edge excluded
        XCTAssertNil(menu.button(at: 300, 380))                                     // Register's rect: not built
        // `_DrawButton`: lighting New over a lit Demo restores Demo first only when param ≠ 1 (flag value 1).
        var hit: Set<MainMenu.Button> = [.demo]
        XCTAssertEqual(menu.drawButtonOps(1, hit: &hit).count, 1 + 1 + 1)           // pict, New lit, flush New
        XCTAssertEqual(hit, [.demo, .newGame])
        XCTAssertEqual(menu.drawButtonOps(0, hit: &hit).count, 1 + 2 + 2)           // both restored + flushed
        XCTAssertEqual(hit, [])
    }

    func testKeyNStartsGame() throws {
        let data = try gameData()
        for chars in ["n", "N", "\r", "\u{3}"] {
            let fe = frontEnd(data)
            var now: UInt32 = 1000
            toMenu(fe, now: &now)
            _ = fe.key(0x2d, chars: chars, modifiers: KeyModifiers())
            let start = now
            let outs = ticks(fe, 10, now: &now)
            XCTAssertEqual(outs[0].sounds, [SoundCue(slot: 17, priority: 10, delayFrames: 0)], chars)
            XCTAssertEqual(Array(outs[0].drawOps.prefix(3)), MainMenu(data: data).flashOnOps(.newGame))
            XCTAssertTrue(outs[1...].allSatisfy { $0.sounds.isEmpty }, "_WaitFor(10)")
            // The flash ends at +10: snd 36 and the title music fades from 0x100 (prefs: music 4, title music on).
            let off = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away)
            XCTAssertEqual(now - start, 10)
            now += 1
            XCTAssertEqual(off.sounds, [SoundCue(slot: 0x24, priority: 0x14, delayFrames: 0)])
            XCTAssertEqual(off.music, [.volume(0x100)])
            let fade = ticks(fe, now: &now) { $0.session == nil }
            XCTAssertEqual(fade.music.count, 51 + 2)                    // 0x100 − 5k ≥ 0 (51 more), stopNow, unload
            XCTAssertEqual(Array(fade.music.suffix(2)), [.stopNow, .unload])
            let s = try XCTUnwrap(fe.session)
            XCTAssertEqual(s.mode, .play)
            XCTAssertEqual(s.state.level, 1)
            XCTAssertEqual(s.state.lives, 3)
            XCTAssertFalse(s.playerIsCheating)
            XCTAssertEqual(fe.phase, .game)
        }
    }

    func testCommandHeldKeysIgnored() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        ticks(fe, 100, now: &now)
        for c in ["n", "d", "q", "b", "l"] {
            _ = fe.key(0x00, chars: c, modifiers: KeyModifiers(command: true))
        }
        let outs = ticks(fe, 30, now: &now)
        XCTAssertTrue(sounds(outs).isEmpty)
        XCTAssertTrue(outs.allSatisfy { $0.requests.isEmpty })
        XCTAssertNil(fe.session)
        XCTAssertEqual(fe.phase, .menu)
        // Still an event: the idle and info timers restart.
        XCTAssertEqual(fe.idleStart, now - 26)
        XCTAssertEqual(fe.infoTimer, now - 26)
    }

    func testButtonActsOnReleaseInside() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        let menu = MainMenu(data: data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        let inDemo = MousePoint(h: 200, v: 290, button: true)
        let outside = MousePoint(h: 20, v: 290, button: true)
        // Press on Demo: snd 17, PICT 9100 into bgnd, lit.
        _ = fe.mouseDown(h: inDemo.h, v: inDemo.v, modifiers: KeyModifiers())
        var o = fe.tick(now: now, keys: HeldKeys(), mouse: inDemo); now += 1
        XCTAssertEqual(o.sounds, [SoundCue(slot: 17, priority: 10, delayFrames: 0)])
        var none = Set<MainMenu.Button>()
        let lit = menu.drawButtonOps(2, hit: &none)
        XCTAssertTrue(o.drawOps.contains(lit[1]))
        XCTAssertEqual(fe.hitButtons, [.demo])
        // Held: nothing new; dragged out: unlit; released outside: nothing happens.
        o = fe.tick(now: now, keys: HeldKeys(), mouse: inDemo); now += 1
        XCTAssertFalse(o.drawOps.contains(lit[1]))
        o = fe.tick(now: now, keys: HeldKeys(), mouse: outside); now += 1
        XCTAssertEqual(fe.hitButtons, [])
        _ = fe.mouseUp(h: outside.h, v: outside.v, modifiers: KeyModifiers())
        ticks(fe, 5, now: &now, mouse: MousePoint(h: 20, v: 290, button: false))
        XCTAssertNil(fe.session)
        XCTAssertEqual(fe.phase, .menu)
        // Press and release inside: the demo starts (no `_FlashButton`, no second snd 17).
        _ = fe.mouseDown(h: inDemo.h, v: inDemo.v, modifiers: KeyModifiers())
        o = fe.tick(now: now, keys: HeldKeys(), mouse: inDemo); now += 1
        _ = fe.mouseUp(h: inDemo.h, v: inDemo.v, modifiers: KeyModifiers())
        o = fe.tick(now: now, keys: HeldKeys(), mouse: MousePoint(h: 200, v: 290, button: false)); now += 1
        XCTAssertTrue(o.sounds.isEmpty)
        let s = try XCTUnwrap(fe.session)
        XCTAssertEqual(s.mode, .demo)
        XCTAssertEqual(fe.phase, .game)
    }

    func testIdleAlternatesDemoScores() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        let entry = fe.idleStart
        // 0x4b0 idle ticks: `idleStart + 1200 < now` → the Demo button flashes, then FILM 1 plays.
        ticks(fe, Int(entry + 1200 - now) + 1, now: &now)
        XCTAssertNil(fe.session)
        var o = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1
        XCTAssertEqual(Array(o.drawOps.prefix(3)), MainMenu(data: data).flashOnOps(.demo))
        ticks(fe, now: &now) { $0.session == nil }
        XCTAssertEqual(fe.session?.mode, .demo)
        XCTAssertEqual(fe.session?.state.level, 1)
        _ = runDemo(fe, now: &now)
        // The idle clock restarts when the demo returns; next time it is Scores.
        let back = fe.idleStart
        XCTAssertEqual(back, now - 1)
        ticks(fe, Int(back + 1200 - now) + 1, now: &now)
        o = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1
        XCTAssertEqual(Array(o.drawOps.prefix(3)), MainMenu(data: data).flashOnOps(.scores))
        // (The scores screen is C7's; the placeholder returns at once: menu redrawn, `_WipeScreen(12)`.)
        let ret = ticks(fe, now: &now) { $0.phase != .menu }
        XCTAssertTrue(ret.drawOps.contains(.wipe(step: 12)))
        XCTAssertNil(fe.session)
        // And Demo again (FILM 2).
        ticks(fe, Int(fe.idleStart + 1200 - now) + 1, now: &now)
        ticks(fe, now: &now) { $0.session == nil }
        XCTAssertEqual(fe.session?.state.level, 2)
    }

    func testFilmCounterCycles1to4() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        XCTAssertEqual(fe.numFilms, 4)
        XCTAssertEqual(fe.filmCounter, 0)
        var levels: [Int] = []
        for _ in 0..<5 {
            _ = fe.key(0x02, chars: "d", modifiers: KeyModifiers())
            ticks(fe, now: &now) { $0.session == nil }
            let s = try XCTUnwrap(fe.session)
            levels.append(s.state.level)
            // Seeded from its FILM: the same stream as a session built straight from that FILM.
            let film = try data.levels.film(s.state.level)
            let direct = try GameSession(data: data, prefs: .defaults, mode: .demo, startLevel: 0, seed: 0, film: film)
            XCTAssertEqual(s.state.rng.seed, direct.state.rng.seed)
            XCTAssertEqual(s.state.rng.drawCount, direct.state.rng.drawCount)
            let o = runDemo(fe, now: &now)
            XCTAssertEqual(o.ended, .demoInterrupted)
            // The process stream carries on from the demo's.
            XCTAssertNotEqual(fe.random.seed, 1)
        }
        XCTAssertEqual(levels, [1, 2, 3, 4, 1])
        XCTAssertEqual(fe.filmCounter, 1)
    }

    func testInfoBoxCycles180Ticks() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        let t0 = fe.infoTimer
        var texts: [(UInt32, String)] = []
        while now < t0 + 950 {
            let o = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away)
            for case let .infoText(s, colour) in o.drawOps {
                XCTAssertEqual(colour, 0x111)
                XCTAssertEqual(o.drawOps.first, .spriteWorldToComp(src: InfoBox.srcTextRect, dst: InfoBox.textRect))
                XCTAssertEqual(o.drawOps.last, .compToScreen(InfoBox.textRect))
                texts.append((now, s))
            }
            now += 1
        }
        // `gInfoTimer + 0xb4 < TickCount`: every 181 ticks; message 0 (already drawn by `_DrawMainMenu`) first.
        XCTAssertEqual(texts.map(\.0), [t0 + 181, t0 + 362, t0 + 543, t0 + 724, t0 + 905])
        XCTAssertEqual(texts.map(\.1), [
            "Copyright 1995-2008 Alex Metcalf/David Wareing & Ambrosia", "Version 1.1.0",
            "Registered To:  Ben  [1 copy]", "Thanks for supporting Shareware!",
            "Copyright 1995-2008 Alex Metcalf/David Wareing & Ambrosia",
        ])
        // Message 3 alternates "Thanks…" / "Visit us…" each time it is drawn; occasions replace it.
        var box = InfoBox(registeredName: "A", licenceCopies: 2)
        XCTAssertEqual(box.message(3, occasion: 0), "Thanks for supporting Shareware!")
        XCTAssertEqual(box.message(3, occasion: 0), "Visit us at http://www.AmbrosiaSW.com/games/bt/")
        XCTAssertEqual(box.message(2, occasion: 0), "Registered To:  A  [2 copies]")
        XCTAssertEqual(box.message(3, occasion: InfoBox.occasion(month: 12, day: 25)), "Merry Christmas to your family!")
        XCTAssertEqual(box.message(3, occasion: InfoBox.occasion(month: 10, day: 31)), "Trick or Treat?")
        XCTAssertEqual(InfoBox.occasion(month: 7, day: 4), 0)
        XCTAssertEqual(box.message(4, occasion: 0), "A man he hears what he wants to hear, and disregards the rest.")
        XCTAssertEqual(box.message(0x21, occasion: 0), "Pleased to meet you, hope you guess my name.")
        XCTAssertEqual(Set(InfoBox.eggMessages.keys), Set(4...0x21))
        // Option-click in the box: snd 0, an egg 3…33 drawn at once by `_DrawMainMenu`.
        _ = fe.mouseDown(h: 300, v: 430, modifiers: KeyModifiers(option: true))
        let click = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1
        XCTAssertEqual(click.sounds, [SoundCue(slot: 0, priority: 10, delayFrames: 0)])
        let egg = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1
        let shown = egg.drawOps.compactMap { op -> String? in if case let .infoText(s, _) = op { return s }; return nil }
        XCTAssertEqual(shown.count, 1)
        XCTAssertEqual(egg.drawOps.last, .compToScreen(MainMenu.screenRect))
        XCTAssertEqual(fe.msgCounter, 0)
        XCTAssertEqual(fe.infoTimer, now - 1 + 0x78)
    }

    func testMenuStarsSpawnAndAnimate() {
        var stars = MenuStars()
        var rng = GameRandom(seed: 1)
        stars.reset(now: 100, mouse: MousePoint(h: 200, v: 200, button: false))
        // Not more than 1 tick since the reset: no spawn even though the mouse moved.
        XCTAssertEqual(stars.process(now: 101, mouse: MousePoint(h: 250, v: 250, button: false), random: &rng), [])
        // Moved, 2 ticks on: one star at mouse − 13 + GetRandomFast(0, 20) − 10 (h first, then v).
        var expect = GameRandom(seed: 1)
        let dh = expect.fast(0, 0x14), dv = expect.fast(0, 0x14)
        let ops = stars.process(now: 102, mouse: MousePoint(h: 250, v: 250, button: false), random: &rng)
        XCTAssertEqual(rng.seed, expect.seed)
        let h = 237 + dh - 10, v = 237 + dv - 10
        let r = QDRect(top: Int16(v), left: Int16(h), bottom: Int16(v + 26), right: Int16(h + 26))
        XCTAssertEqual(ops, [.compToBgnd(r), .spriteToBgnd(set: 0x28, frame: 1, h: h, v: v), .bgndToScreen(r)])
        // Same mouse: no spawn. Frames advance one per > 3 ticks; frame 6 plots nothing; past 6 the slot frees.
        var frames: [Int] = []
        var t: UInt32 = 103
        while stars.stars[0].frame != 0 {
            _ = stars.process(now: t, mouse: MousePoint(h: 250, v: 250, button: false), random: &rng)
            frames.append(stars.stars[0].frame)
            t += 1
        }
        XCTAssertEqual(Array(Set(frames)).sorted(), [1, 2, 3, 4, 5, 6, 0].sorted())
        XCTAssertEqual(t, 103 + 4 * 6)                                   // 4 ticks per frame, 1→7
        XCTAssertEqual(rng.seed, expect.seed, "no draw without movement")
        stars.reset(now: 200, mouse: MousePoint(h: 0, v: 0, button: false))
        var n: UInt32 = 202
        // A frame-6 star is erased but not plotted.
        var six = MenuStars()
        six.reset(now: 0, mouse: MousePoint(h: 0, v: 0, button: false))
        _ = six.process(now: 2, mouse: MousePoint(h: 100, v: 100, button: false), random: &rng)
        for k in 1...5 { _ = six.process(now: 2 + UInt32(4 * k), mouse: MousePoint(h: 100, v: 100, button: false), random: &rng) }
        XCTAssertEqual(six.stars[0].frame, 6)
        let sixOps = six.process(now: 23, mouse: MousePoint(h: 100, v: 100, button: false), random: &rng)
        XCTAssertEqual(sixOps.count, 2)                                  // compToBgnd + bgndToScreen
        // Clamped to 0…614 / 0…454; the ring wraps after 30.
        for i in 0..<31 {
            _ = stars.process(now: n, mouse: MousePoint(h: 639 - (i & 1), v: 479, button: false), random: &rng)
            n += 2
        }
        XCTAssertEqual(stars.next, 1)
        XCTAssertTrue(stars.stars.allSatisfy { $0.frame == 0 || ($0.h <= 614 && $0.v <= 454) })
        XCTAssertTrue(stars.stars.contains { $0.h == 614 && $0.v == 454 })
    }

    func testHiddenKeysSounds() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        _ = fe.key(0x0b, chars: "b", modifiers: KeyModifiers())
        _ = fe.key(0x0d, chars: "W", modifiers: KeyModifiers())
        let bw = ticks(fe, 3, now: &now)
        XCTAssertEqual(sounds(bw), [SoundCue(slot: 47, priority: 30, delayFrames: 0),
                                    SoundCue(slot: 46, priority: 30, delayFrames: 0)])
        // X: DLOG 290 until dismissed.
        _ = fe.key(0x07, chars: "x", modifiers: KeyModifiers())
        var o = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1
        XCTAssertEqual(o.requests, [.modalDialog(id: 290)])
        ticks(fe, 20, now: &now)
        XCTAssertEqual(fe.phase, .busy)
        _ = fe.dialogDone()
        ticks(fe, 2, now: &now)
        XCTAssertEqual(fe.phase, .menu)
        // Z: `_StopMusic` (fade), DLOG 291, then `_ResumeMusic` restarts the title music.
        _ = fe.key(0x06, chars: "z", modifiers: KeyModifiers())
        o = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1
        XCTAssertEqual(o.music, [.volume(0x100)])
        let fade = ticks(fe, now: &now) { $0.musicPlaying }
        XCTAssertEqual(fade.music.count, 51 + 1)                         // 0x100 … 1, then stopNow
        XCTAssertEqual(fade.music.last, .stopNow)
        XCTAssertEqual(fade.requests, [.modalDialog(id: 291)])           // same tick as the stop
        ticks(fe, 5, now: &now)
        XCTAssertEqual(fe.phase, .busy)
        XCTAssertEqual(fe.dialogDone().music, [.resume, .start])
        // R (Register) does nothing in the registered build; Q fades the music and quits through `_main`.
        _ = fe.key(0x0f, chars: "r", modifiers: KeyModifiers())
        XCTAssertTrue(sounds(ticks(fe, 3, now: &now)).isEmpty)
        _ = fe.key(0x0c, chars: "q", modifiers: KeyModifiers())
        let quit = ticks(fe, 100, now: &now)
        XCTAssertEqual(sounds(quit), [SoundCue(slot: 17, priority: 10, delayFrames: 0)])
        XCTAssertEqual(quit.flatMap(\.requests).last, .quit)
        XCTAssertEqual(fe.phase, .quit)
    }

    func testLevelSelectRangeAndCheatFlag() throws {
        let data = try gameData()
        XCTAssertEqual(FrontEnd.levelSelectChoice(typed: 2, max: 10), 2)
        XCTAssertEqual(FrontEnd.levelSelectChoice(typed: 10, max: 10), 10)
        XCTAssertNil(FrontEnd.levelSelectChoice(typed: 1, max: 10))
        XCTAssertNil(FrontEnd.levelSelectChoice(typed: 11, max: 10))
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        func open() -> SessionOutput {
            _ = fe.key(0x25, chars: "l", modifiers: KeyModifiers())
            defer { now += 1 }
            return fe.tick(now: now, keys: HeldKeys(), mouse: Self.away)
        }
        // L: snd 22 from `_Interface`, snd 22 again as `_DoLevelSelect` opens DLOG 160 (range 2…short 0x3a = 10).
        var o = open()
        XCTAssertEqual(o.sounds, [SoundCue(slot: 22, priority: 10, delayFrames: 0),
                                  SoundCue(slot: 22, priority: 10, delayFrames: 0)])
        XCTAssertEqual(o.requests, [.levelSelectDialog(max: 10)])
        XCTAssertEqual(fe.levelSelectDone(typed: 11).requests, [.beep])          // out of range → SysBeep, no game
        ticks(fe, 3, now: &now)
        XCTAssertNil(fe.session)
        _ = open()
        XCTAssertEqual(fe.levelSelectDone(typed: 1).requests, [.beep])
        _ = open()
        XCTAssertEqual(fe.levelSelectDone(typed: nil), SessionOutput())         // Cancel
        ticks(fe, 3, now: &now)
        XCTAssertEqual(fe.phase, .menu)
        // OK with 5: snd 36, the title music stops, the game starts at level 5 — cheating, so no high score.
        _ = open()
        o = fe.levelSelectDone(typed: 5)
        XCTAssertEqual(o.sounds, [SoundCue(slot: 0x24, priority: 0x14, delayFrames: 0)])
        ticks(fe, now: &now) { $0.session == nil }
        let s = try XCTUnwrap(fe.session)
        XCTAssertEqual(s.state.level, 5)
        XCTAssertTrue(s.playerIsCheating)
        XCTAssertFalse(fe.musicLoaded)
    }

    func testDemoEndsOnKey() throws {
        let data = try gameData()
        let fe = frontEnd(data)
        var now: UInt32 = 1000
        toMenu(fe, now: &now)
        _ = fe.key(0x02, chars: "D", modifiers: KeyModifiers())
        ticks(fe, now: &now) { $0.session == nil }
        let s = try XCTUnwrap(fe.session)
        ticks(fe, now: &now) { $0.session?.phase == .wipe }
        XCTAssertTrue(fe.wantsFrameTimer)
        for _ in 0..<5 { XCTAssertNil(fe.frame(keys: HeldKeys()).ended) }
        // Any key: `gPlayGame = 0`, the demo exits on the next frame; no music cue, title music stays loaded.
        _ = fe.key(0x31, chars: " ", modifiers: KeyModifiers())
        XCTAssertEqual(fe.phase, .game)
        let end = fe.frame(keys: HeldKeys())
        XCTAssertEqual(end.ended, .demoInterrupted)
        XCTAssertEqual(s.phase, .ended)
        XCTAssertTrue(end.requests.contains(.showCursor))
        XCTAssertTrue(end.music.isEmpty)
        XCTAssertFalse(fe.wantsFrameTimer)
        // `_RequestGame`'s epilogue: the menu redrawn, About back, `_WipeScreen(12)`; then `_ResetMenuStars`.
        let back = end + ticks(fe, now: &now) { $0.phase != .menu }
        XCTAssertTrue(back.drawOps.contains(.wipe(step: 12)))
        XCTAssertTrue(back.requests.contains(.disableAbout(false)))
        XCTAssertNil(fe.session)
        XCTAssertTrue(fe.musicLoaded)
        // A mouse-down ends a demo too.
        _ = fe.key(0x02, chars: "d", modifiers: KeyModifiers())
        ticks(fe, now: &now) { $0.session == nil }
        ticks(fe, now: &now) { $0.session?.phase == .wipe }
        _ = fe.frame(keys: HeldKeys())
        _ = fe.mouseDown(h: 10, v: 10, modifiers: KeyModifiers())
        XCTAssertEqual(fe.frame(keys: HeldKeys()).ended, .demoInterrupted)
    }
}

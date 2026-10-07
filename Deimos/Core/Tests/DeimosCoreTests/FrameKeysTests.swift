import XCTest
import HectorResources
@testable import DeimosCore

/// Begin-frame keys (timing-frame §2.1, §2.6; messages-notices-console §2.5, §4.4; sound-music §4.3; front-end §8) —
/// plan C19. Every assertion is on `FrameKeysResult` / the controller / `GameState`, never on session pass output
/// (review leg B I6). Listing `disasm-review3-all.txt`: `FUN_10030360`, `FUN_10030910`, `FUN_10030570`,
/// `FUN_10030870`, `FUN_10022ef0`, `FUN_100305e0`, `FUN_10030640`, `FUN_10030bc0` (`10030bf4..10030c90`).
final class FrameKeysTests: XCTestCase {
    private func game() throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
        s.flags.gameTime = 77
        return s
    }

    private func started(film: Bool = false, _ g: inout GameState, _ console: inout Console,
                         ticks: UInt32 = 0) -> FrameController {
        var c = FrameController(fpsMaxRate: EntityDraw.fctiwz(g.assets.floats[32]))
        FrameKeys.startSession(controller: &c, console: &console, game: &g, filmPlayback: film,
                               gameScreenLayout: true, autoInterlaceAllowed: true, ticks: ticks)
        return c
    }

    /// Caps Lock held, not paused, not a film → paused + the "Press Caps Lock" notice (`10030400..100304dc`); the
    /// end-frame wrapper's `FUN_10030870` → console reset, `FUN_10022ef0`: halt at the current sound index
    /// (`10022f24`), gaso 8 `incl` (0x32, 100, 1) (`10022f2c..10022f44`), music pause (`10022f4c`), the wait,
    /// music resume (`10022fb4`), then the notice clear and paused = 0 (`100308c0..100308dc`). None in a film.
    func testCapsLockPauseResult() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        var c = started(&g, &con)
        XCTAssertEqual(g.assets.sounds[8], FourCC("incl"))

        let quiet = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys())
        XCTAssertFalse(quiet.pauseStarted)
        XCTAssertNil(FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(), ticks: 0))

        // The console is open when the pause starts: the pause screen resets (closes) it.
        _ = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys(held: [0x32]))
        XCTAssertTrue(con.isOpen)
        g.cues = CueBuffer()
        let r = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys(capsLock: true))
        XCTAssertTrue(r.pauseStarted)
        XCTAssertTrue(con.isOpen, "begin frame leaves the console open")
        XCTAssertTrue(r.tick, "the pause frame still ticks")
        XCTAssertTrue(c.paused)
        XCTAssertTrue(g.notice.active)
        XCTAssertEqual(g.notice.text, g.assets.gameStrings[0])
        XCTAssertEqual(MacRoman.decode(g.notice.text), "Press Caps Lock")
        XCTAssertEqual(g.notice.alpha, 0, "fade-in forced off: opaque at once")
        XCTAssertEqual(g.notice.alignment, .centerInGameArea, "fc+4 = 1 → CEGA")
        XCTAssertEqual(g.notice.start, 77, "posted at game time")
        XCTAssertTrue(g.cues.sounds.isEmpty && g.cues.music.isEmpty, "begin frame makes no cue")

        let earlier = SoundPlay.perm(FourCC("exsl")!, priority: 10, volume: 100, allowMultiple: true)
        g.cues.sounds.append(earlier)
        let wait = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(capsLock: true),
                                             ticks: 0)
        XCTAssertEqual(wait, PauseScreen(present: .gameScreen, musicAfterWait: [.resume]))
        XCTAssertEqual(wait?.musicAfterWait, [.resume], "the resume comes after the wait — the next pass's music")
        XCTAssertEqual(g.cues.haltEffectsAt, 1, "the halt cuts what came before it in the pass")
        XCTAssertEqual(g.cues.sounds, [earlier, SoundPlay.perm(FourCC("incl")!, priority: 50, volume: 100,
                                                              allowMultiple: true)])
        XCTAssertEqual(g.cues.music, [.pause], "only the pause before the wait is in this pass")
        XCTAssertFalse(c.paused)
        XCTAssertTrue(g.notice.fadingOut, "cleared: fades out over 8 ticks")
        XCTAssertFalse(con.isOpen, "console reset by FUN_10030870")
        XCTAssertFalse(con.visible)

        // Released → paused stays 0; a fresh press pauses again.
        XCTAssertFalse(FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys()).pauseStarted)
        XCTAssertFalse(c.paused)
        XCTAssertNil(FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(), ticks: 0))
        let again = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys(capsLock: true))
        XCTAssertTrue(again.pauseStarted)
        XCTAssertTrue(c.paused)
        XCTAssertTrue(g.notice.active && !g.notice.fadingOut, "the notice is posted afresh")
        XCTAssertNotNil(FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g,
                                                  keys: HeldKeys(capsLock: true), ticks: 0))

        // A film: no pause, no notice, no cue.
        var f = try game()
        var fcon = try Console(assets: f.assets)
        var fc = started(film: true, &f, &fcon)
        let fr = FrameKeys.beginFrame(controller: &fc, console: &fcon, game: &f, keys: HeldKeys(capsLock: true))
        XCTAssertFalse(fr.pauseStarted)
        XCTAssertFalse(fc.paused)
        XCTAssertFalse(f.notice.active)
        XCTAssertNil(FrameKeys.endFrameWrapper(controller: &fc, console: &fcon, game: &f, keys: HeldKeys(capsLock: true),
                                               ticks: 0))
        XCTAssertEqual(f.cues, CueBuffer())
    }

    /// Q4 RULED (D31): the Mac OS X path of `FUN_10030910` only — `-` (0x1B) / `=` (0x18) are edge-latched
    /// (+0x0e / +0x0f) and run `FUN_10047990` / `FUN_10047a30` (int pref 0 ∓ 10, clamped, stored only when it
    /// moves), but `FUN_100461b0` is true, so no device gain, no gaso 7 click and no message (`100309ec..100309f8`).
    func testVolumeKeysOSX() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        var c = started(&g, &con)
        func frame(_ held: Set<UInt16>) -> FrameKeysResult {
            let r = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys(held: held))
            _ = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(held: held), ticks: 0)
            return r
        }
        XCTAssertEqual(g.prefs.intPrefs[0], 50)
        XCTAssertEqual(frame([0x1B]).volume, 40)
        XCTAssertEqual(g.prefs.intPrefs[0], 40)
        XCTAssertNil(frame([0x1B]).volume, "held: edge only")
        XCTAssertNil(frame([0x1B]).volume, "still held: the latch follows the key")
        XCTAssertEqual(g.prefs.intPrefs[0], 40)
        XCTAssertNil(frame([]).volume)
        XCTAssertEqual(frame([0x1B]).volume, 30)

        g.prefs.intPrefs[0] = 100
        g.prefs.intPrefs[0] = 70
        XCTAssertEqual(frame([0x18]).volume, 80)
        XCTAssertNil(frame([0x18]).volume, "`=` held: edge only")
        XCTAssertNil(frame([0x18]).volume, "`=` still held: the latch follows the key")
        XCTAssertEqual(g.prefs.intPrefs[0], 80)
        _ = frame([])
        g.prefs.intPrefs[0] = 100
        XCTAssertEqual(frame([0x18]).volume, 100, "at 100 `=` stays 100")
        XCTAssertEqual(g.prefs.intPrefs[0], 100)
        _ = frame([])
        g.prefs.intPrefs[0] = 95
        XCTAssertEqual(frame([0x18]).volume, 100, "95 + 10 clamps to 100")
        _ = frame([])
        g.prefs.intPrefs[0] = 0
        XCTAssertEqual(frame([0x1B]).volume, 0, "at 0 `-` stays 0")
        XCTAssertEqual(g.prefs.intPrefs[0], 0)
        _ = frame([])
        g.prefs.intPrefs[0] = 5
        XCTAssertEqual(frame([0x1B]).volume, 0, "5 − 10 clamps to 0")

        XCTAssertTrue(g.cues.sounds.isEmpty, "no click on OS X")
        XCTAssertTrue(g.cues.music.isEmpty)
        XCTAssertTrue(g.messages.messages.isEmpty, "no Sound Volume message on OS X")
    }

    /// F6 (0x61, latch +0x10): message GameString 17 if pref 5 was 0 else 18 (type 0), THEN pref 5 toggled, then
    /// gaso 7 via `FUN_10047670(id, 100, 100, 1)` (`10030aa4..10030b64`). Edge only.
    func testF6Interlace() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        var c = started(&g, &con)
        XCTAssertEqual(g.prefs.bytePrefs[5], 0)
        let click = SoundPlay.perm(g.assets.sounds[7], priority: 100, volume: 100, allowMultiple: true)
        XCTAssertEqual(g.assets.sounds[7], FourCC("incl"))

        let r = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys(held: [0x61]))
        XCTAssertTrue(r.interlaceToggled)
        XCTAssertEqual(g.prefs.bytePrefs[5], 1)
        XCTAssertEqual(g.messages.messages.map { MacRoman.decode($0.text) }, ["Interlacing      ON"])
        XCTAssertEqual(g.messages.messages.first?.kind, .normal)
        XCTAssertEqual(g.cues.sounds, [click])

        let held = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys(held: [0x61]))
        XCTAssertFalse(held.interlaceToggled, "edge only")
        XCTAssertEqual(g.prefs.bytePrefs[5], 1)
        _ = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys())
        XCTAssertTrue(FrameKeys.beginFrame(controller: &c, console: &con, game: &g,
                                           keys: HeldKeys(held: [0x61])).interlaceToggled)
        XCTAssertEqual(g.prefs.bytePrefs[5], 0)
        XCTAssertEqual(g.messages.messages.last?.text, g.assets.gameStrings[18])
        XCTAssertEqual(g.cues.sounds, [click, click])
    }

    /// FPS monitor (`FUN_100305e0` init: +0x24 = 30; `FUN_10030640` on tick frames: when TickCount > +0x18 + 60
    /// (unsigned) publish +0x20 into +0x24, count a deficient window when +0x20 < 30, reset) and the pref-9
    /// counter in end frame (`10030bf4..10030c90`: `"%i"` of +0x24, format 39 when ≥ 30 else 40, +0x110 = 0,
    /// layer 15).
    func testFPSCounterText() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        var c = started(&g, &con, ticks: 1000)
        XCTAssertEqual(c.fpsShown, 30)
        XCTAssertNil(FrameKeys.fpsCounterRequest(controller: c, prefs: g.prefs, formats: g.assets.formats),
                     "pref 9 off → nothing")
        g.prefs.bytePrefs[9] = 1
        XCTAssertEqual(FrameKeys.fpsCounterRequest(controller: c, prefs: g.prefs, formats: g.assets.formats)?.format,
                       g.assets.formats[39])

        // Window 1 starts from +0x20 = 30 (the init stores 30 into the frame counter too, `1003061c`): 31 frames,
        // one every 2 ticks — the check at 1060 fails (not > 1060), at 1062 it publishes 30 + 31.
        XCTAssertEqual(c.windowFrames, 30)
        for k in 1...31 {
            _ = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys())
            _ = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(),
                                          ticks: 1000 + 2 * UInt32(k))
            if k == 30 { XCTAssertEqual(c.fpsShown, 30, "1060 is not > 1060") }
        }
        XCTAssertEqual(c.fpsShown, 61)
        XCTAssertEqual(c.windowFrames, 0)
        XCTAssertEqual(c.fpsWindowStart, 1062)
        // Window 2: 31 frames → "31".
        for k in 1...31 {
            _ = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys())
            _ = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(),
                                          ticks: 1062 + 2 * UInt32(k))
        }
        XCTAssertEqual(c.fpsShown, 31)
        XCTAssertEqual(c.deficientWindows, 0)
        var t = try XCTUnwrap(FrameKeys.fpsCounterRequest(controller: c, prefs: g.prefs, formats: g.assets.formats))
        XCTAssertEqual(MacRoman.decode(t.text), "31")
        XCTAssertEqual(t.format, g.assets.formats[39])
        XCTAssertEqual(t.layer, 15)
        XCTAssertFalse(t.drawNow)
        XCTAssertFalse(t.keepTemplateClip, "10030c08..10030c90 writes no +0x10d (the census MED claim does not hold)")

        // 29 frames in the next window (> 60 ticks): deficient → format 40.
        for k in 1...29 {
            _ = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys())
            _ = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(),
                                          ticks: k == 29 ? 1185 : 1124 + UInt32(k))
        }
        XCTAssertEqual(c.fpsShown, 29)
        XCTAssertEqual(c.deficientWindows, 1)
        t = try XCTUnwrap(FrameKeys.fpsCounterRequest(controller: c, prefs: g.prefs, formats: g.assets.formats))
        XCTAssertEqual(MacRoman.decode(t.text), "29")
        XCTAssertEqual(t.format, g.assets.formats[40])
        XCTAssertEqual(g.prefs.bytePrefs[5], 0, "auto-interlace needs pref 6 (never set in a stock install)")

        // Auto-interlace (`100306c0..10030754`): with +3 and byte pref 6, the 10th deficient window (cumulative —
        // `deficientWindows` is never reset by a good window) sets byte pref 5 and posts GameString 17.
        g.messages.reset()
        var now: UInt32 = 1185
        func deficientWindow() {
            for k in 1...20 {
                _ = FrameKeys.beginFrame(controller: &c, console: &con, game: &g, keys: HeldKeys())
                _ = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(),
                                              ticks: k == 20 ? now + 61 : now + UInt32(k))
            }
            now += 61
        }
        for w in 2...9 {
            deficientWindow()
            XCTAssertEqual(c.deficientWindows, Int32(w))
        }
        deficientWindow()
        XCTAssertEqual(c.deficientWindows, 0, "the 10th window resets the count")
        XCTAssertEqual(g.prefs.bytePrefs[5], 0, "byte pref 6 off: no auto-interlace")
        XCTAssertTrue(g.messages.messages.isEmpty)
        g.prefs.bytePrefs[6] = 1
        for w in 1...9 {
            deficientWindow()
            XCTAssertEqual(c.deficientWindows, Int32(w))
        }
        XCTAssertEqual(g.prefs.bytePrefs[5], 0)
        deficientWindow()
        XCTAssertEqual(c.deficientWindows, 0, "reset at flli 34 = 10")
        XCTAssertEqual(g.prefs.bytePrefs[5], 1)
        XCTAssertEqual(g.messages.messages.map(\.text), [g.assets.gameStrings[17]])
        // Already on: the next 10th window does nothing more.
        g.messages.reset()
        for _ in 1...10 { deficientWindow() }
        XCTAssertTrue(g.messages.messages.isEmpty, "pref 5 already on: no second message")
    }
}

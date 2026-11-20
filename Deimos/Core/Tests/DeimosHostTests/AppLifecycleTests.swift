import XCTest
@testable import DeimosHost
@testable import DeimosCore
import DeimosRender
import DeimosAudio

/// Phase 4 S8a AW — the app's life through the driver as the app runs it: the boot entry (no direct start), the
/// settings written at quit, the hidden `-film` switch, the cold start's timeline, and the small decisions the app
/// leaves to `DeimosHost` (the gamepad's context and keys, the pictures). Every loop names a bound in simulated
/// seconds and fails on it (G11).
final class AppLifecycleTests: XCTestCase {

    private static let poll = 0.004
    private static let typeOne = KeyEvent(charCode: 0x31, keyCode: 0x12)
    private static let typeQ = KeyEvent(charCode: 0x51, keyCode: 0x0C)
    private static let publ = FourCC("publ")!
    private static let inmu = FourCC("inmu")!

    /// A driver on the app's boot entry and a clock the test owns (the app's Mac OS X 60 Hz TickCount).
    private struct Rig {
        var driver: DeimosDriver
        var seconds: Double
        let sink: ClockedSink?
        private(set) var requests: [ShellRequest] = []

        init(_ frontEnd: FrontEnd, sink: ClockedSink? = ClockedSink(), settings: any SettingsStore = NoSettingsStore(),
             lastFilm: any LastFilmStore = NoLastFilmStore(), startTick: UInt32 = 1_000) {
            driver = DeimosDriver(frontEnd: frontEnd, rate: .osx, audio: sink, settingsStore: settings,
                                  lastFilmStore: lastFilm)
            seconds = (Double(startTick) + 0.5) / TickRate.osx.perSecond
            self.sink = sink
        }

        var ticks: UInt32 { MacTicks.ticks(seconds: seconds, rate: TickRate.osx.perSecond) }

        /// One app idle at the clock's time (returned: the tick it ran at), then the clock moves one poll on.
        @discardableResult
        mutating func idle(_ keys: HeldKeys = HeldKeys()) -> UInt32 {
            let at = ticks
            sink?.now = at
            requests += driver.idle(seconds: seconds, keys: keys).requests
            seconds += AppLifecycleTests.poll
            return at
        }

        /// Idles with `keys` until `done` (handed the driver and the tick of the idle just run); false when `bound`
        /// simulated seconds pass first.
        mutating func run(_ keys: HeldKeys = HeldKeys(), bound: Double,
                          until done: (DeimosDriver, UInt32) -> Bool) -> Bool {
            let end = seconds + bound
            var at = ticks
            while !done(driver, at) {
                guard seconds < end else { return false }
                at = idle(keys)
            }
            return true
        }

        /// The main menu is up and between passes (its entry's fade done, no wait or fade in hand).
        static func menuSettled(_ d: DeimosDriver, _: UInt32) -> Bool {
            d.frontEnd.screens == [.mainMenu] && d.waitingOn == nil && !d.isFading
        }
    }

    private func assets() throws -> DeimosAssets { try ShippedAssets.get() }

    // MARK: - The three named tests

    /// Question 4, plan ruling 6: the settings reach the disk at quit only, and every quit writes them — here the
    /// menu's own Quit after a game. A launch boots to the menu (no game starts by itself); `1` starts a game
    /// through the level select (player 1's select key accepts sector 1); in the game F6 and `-` change the session's
    /// prefs (interlace, the volume); Esc ends it and the front end keeps that game's prefs; nothing is written yet;
    /// `Q` quits through the menu's flash and fade, and the pass that asks the shell to quit writes the session's
    /// changes once. The gamepad's context follows the screen on top along the way. Bound: 120 simulated s a stage.
    func testQuitWritesSessionChanges() throws {
        let store = RecordingSettingsStore()
        var rig = Rig(try FrontEnd(assets: try assets(), prefs: .fresh), settings: store)
        rig.idle()
        XCTAssertEqual(rig.driver.frontEnd.screens.first, .boot, "the launch boots")
        XCTAssertEqual(rig.driver.padContext, .screens, "the boot takes the screens' pad layout")
        guard rig.run(bound: 120, until: Rig.menuSettled) else { return XCTFail("bound: no menu") }
        XCTAssertEqual(rig.driver.frontEnd.state.gamesStarted, 0, "no game starts by itself")
        XCTAssertEqual(rig.driver.padContext, .mainMenu)

        rig.idle(HeldKeys(keyEvents: [Self.typeOne]))
        guard rig.run(bound: 120, until: { d, _ in d.frontEnd.screens.last == .levelSelect })
        else { return XCTFail("bound: 1 never reached the level select") }
        XCTAssertEqual(rig.driver.padContext, .levelSelect)
        let select = KeyTable(prefs: .fresh).codes[6]                   // player 1's select key (Space)
        guard rig.run(HeldKeys(held: [select]), bound: 120, until: { d, _ in d.frontEnd.state.gameRunning })
        else { return XCTFail("bound: the level select started no game") }
        rig.idle()
        XCTAssertEqual(rig.driver.padContext, .playing)

        guard rig.run(HeldKeys(held: [FrameKeys.f6Key, FrameKeys.minusKey]), bound: 120,
                      until: { d, _ in d.frontEnd.session?.prefs.bytePrefs[5] == 1 })
        else { return XCTFail("bound: F6 never reached the game") }
        XCTAssertEqual(rig.driver.frontEnd.session?.prefs.intPrefs[0], 40, "the volume key in the same pass")
        guard rig.run(HeldKeys(held: [FrameKeys.escKey]), bound: 120, until: { d, _ in !d.frontEnd.state.gameRunning }),
              rig.run(bound: 120, until: Rig.menuSettled)
        else { return XCTFail("bound: Esc never brought the menu back") }
        XCTAssertEqual(rig.driver.prefs.bytePrefs[5], 1, "the ended game's F6 is the live prefs'")
        XCTAssertEqual(rig.driver.prefs.intPrefs[0], 40, "and its volume")
        XCTAssertEqual(store.saved, [], "nothing is written before the quit")
        XCTAssertFalse(rig.driver.settingsSaved)

        rig.idle(HeldKeys(keyEvents: [Self.typeQ]))
        guard rig.run(bound: 120, until: { d, _ in d.frontEnd.isFinished }) else { return XCTFail("bound: Q never quit") }
        XCTAssertEqual(rig.requests.filter { $0 == .quit }.count, 1, "the shell is asked to quit once")
        XCTAssertEqual(store.saved.count, 1, "the quit writes the settings once")
        XCTAssertEqual(store.saved.first?.bytePrefs[5], 1, "with the session's F6")
        XCTAssertEqual(store.saved.first?.intPrefs[0], 40, "and its volume")
        XCTAssertTrue(rig.driver.settingsSaved)
        for _ in 0..<100 { rig.idle() }
        XCTAssertEqual(store.saved.count, 1, "nothing more")
    }

    /// Ruling 10: `-film deNN` takes the boot entry — the boot runs, the menu comes up, then the film plays as a demo
    /// does (no settings saved for it, no Last Film), and when it ends the menu is back and stays up: no second run
    /// of the film, no game, no quit. The pad's layout during the film is the demo's. Bound: 120 simulated s for the
    /// boot, 400 for the film, 60 for the return.
    func testFilmSwitchReturnsToMenu() throws {
        let a = try assets()
        let film = try FilmLookup.film("de01", in: a)
        let films = RecordingLastFilmStore()
        var rig = Rig(try FrontEnd(assets: a, prefs: .fresh, film: film), lastFilm: films)
        var sawMenu = false
        guard rig.run(bound: 120, until: { d, _ in
            if d.frontEnd.screens.first == .mainMenu { sawMenu = true }
            return d.frontEnd.state.gameRunning
        }) else { return XCTFail("bound: the film never started") }
        XCTAssertTrue(sawMenu, "the menu came up first")
        XCTAssertFalse(rig.driver.frontEnd.screens.contains(.boot), "after the boot")
        XCTAssertEqual(rig.driver.frontEnd.session?.start.film, film, "the film's own start")
        XCTAssertEqual(rig.driver.padContext, .demo)

        guard rig.run(bound: 400, until: { d, _ in !d.frontEnd.state.gameRunning })
        else { return XCTFail("bound: the film never ended") }
        XCTAssertEqual(rig.driver.frontEnd.session?.result?.end, .filmEnded, "it played to its own end")
        guard rig.run(bound: 60, until: Rig.menuSettled) else { return XCTFail("bound: the menu never came back") }
        let settle = rig.ticks &+ 300
        guard rig.run(bound: 10, until: { _, t in t >= settle }) else { return XCTFail("cap") }
        XCTAssertEqual(rig.driver.frontEnd.screens, [.mainMenu], "the menu stays up")
        XCTAssertEqual(rig.driver.frontEnd.state.gamesStarted, 1, "the film once, nothing after it")
        XCTAssertEqual(films.saved, [], "a film is not the Last Film")
        XCTAssertFalse(rig.requests.contains(.quit))
    }

    /// The whole cold start to the menu in ticks (grounding A §1, `front-end.md`'s worked example; X's 16-pass list
    /// fades, `osx-build.md` D1), measured from T = the launch's first pass (the display open; load time excluded):
    /// the 5-tick wait and the 33-step fade of black → the publisher logo and `publ` at 38, its 9-step fade in;
    /// with sound the hold lasts until `publ`'s voice ends (no floor, no cap — here a voice of 322 ticks, A §1's
    /// measured length), without sound (or muted: no audio output) 130 ticks after 38; the fade to black (33) → the
    /// developer logo and `inmu` (not without sound) at 393 (203 silent), held to 240 after it; the fade (33) → the
    /// loading screen fades in (9) at 666 → 675; then the loading lines, each new line a 32-tick fade (five lines
    /// on a first launch, four on a later one — no unit names, Ben 2026-11-20), the lines' fade-out (16 in X) and
    /// the menu's entry; its copyright line first flips 241 ticks after the entry. Bound: 120 simulated s a case.
    func testColdStartTimeline() throws {
        let a = try assets()
        /// `menu`: the menu's entry tick measured at this test's 4 ms poll — the item names are one screen update
        /// each, at most one per app idle (question 7), so this part of the count is the poll's, not the original's.
        struct Case { let first: Bool; let sound: Bool; let menu: UInt32 }
        var menuAt: [Bool: UInt32] = [:]
        for c in [Case(first: true, sound: true, menu: 946), Case(first: false, sound: true, menu: 822),
                  Case(first: true, sound: false, menu: 749)] {
            let label = "first launch \(c.first), sound \(c.sound)"
            let sink: ClockedSink? = c.sound ? ClockedSink(voiceLengths: [Self.publ: 322]) : nil
            var rig = Rig(try FrontEnd(assets: a, prefs: .fresh, soundAvailable: c.sound, firstLaunch: c.first),
                          sink: sink)
            let t0 = rig.ticks
            var loadingFadedIn: UInt32?
            guard rig.run(bound: 120, until: { d, t in
                // The boot's first counted present is the first loading line's full present, once that line's
                // fade (32 steps a tick apart, from the idle the `back` fade-in ended) is done: 31 ticks on.
                if loadingFadedIn == nil && d.presentCount > 0 { loadingFadedIn = t &- 31 }
                return d.frontEnd.screens == [.mainMenu]
            }) else { return XCTFail("\(label): bound: no menu") }
            let menu = rig.driver.frontEnd.state.copyrightClock &- t0     // the menu's t0 (its entry pass)
            menuAt[c.first] = c.sound ? menu : menuAt[c.first]
            if let sink {
                XCTAssertEqual(sink.firstStart[Self.publ].map { $0 &- t0 }, 38, "\(label): publ with the logo")
                XCTAssertEqual(sink.musicStart[Self.inmu].map { $0 &- t0 }, 393, "\(label): inmu with the Swoop logo")
            }
            let backIn = try XCTUnwrap(loadingFadedIn, label) &- t0
            XCTAssertEqual(backIn, c.sound ? 675 : 675 - 192, "\(label): the loading screen is up")
            let lines: UInt32 = c.first ? 5 : 4
            XCTAssertGreaterThanOrEqual(menu, backIn + 32 * lines + 16, "\(label): each line's 32-tick fade, the fade-out")
            XCTAssertEqual(menu, c.menu, "\(label): the item names one update each, at this poll")

            let entry = rig.driver.frontEnd.state.copyrightClock
            guard rig.run(bound: 10, until: { d, _ in d.frontEnd.state.copyrightClock != entry })
            else { return XCTFail("\(label): bound: the copyright line never flipped") }
            XCTAssertEqual(rig.driver.frontEnd.state.copyrightClock &- entry, 241, "\(label): the first flip")
        }
        let first = try XCTUnwrap(menuAt[true]), later = try XCTUnwrap(menuAt[false])
        XCTAssertGreaterThanOrEqual(first - later, 32 + 387 / 5, "the unit names' line only on the first launch")
    }

    // MARK: - The app's small decisions (DeimosHost)

    /// The gamepad's context by the screen on top (the S7 handoff's items 2 and 4; the seat's ruling: the pad is off
    /// in the controls window), and the keys a pad press types (item 3: never an auto-repeat).
    func testPadContextAndKeys() {
        func ctx(_ top: FrontEndScreen.Kind?, paused: Bool = false,
                 game: (film: Bool, paused: Bool)? = nil) -> DeimosPadLayout.Context? {
            PadContext.choose(top: top, levelSelectPaused: paused, game: game)
        }
        XCTAssertEqual(ctx(.mainMenu), .mainMenu)
        XCTAssertEqual(ctx(.levelSelect), .levelSelect)
        XCTAssertEqual(ctx(.levelSelect, paused: true), .paused, "plus is the latch on the level select")
        XCTAssertEqual(ctx(.startReturn), .screens, "start/return's fades, no game running")
        XCTAssertEqual(ctx(.startReturn, game: (film: false, paused: false)), .playing)
        XCTAssertEqual(ctx(.startReturn, game: (film: false, paused: true)), .paused)
        XCTAssertEqual(ctx(.startReturn, game: (film: true, paused: false)), .demo)
        XCTAssertEqual(ctx(.startReturn, game: (film: true, paused: true)), .demo)
        XCTAssertNil(ctx(.controlsDialog), "the pad is off in the controls window")
        for top: FrontEndScreen.Kind? in [.boot, .scores, .nameEntry, .credits, .films, .configDialog, nil] {
            XCTAssertEqual(ctx(top), .screens, "\(String(describing: top))")
        }

        XCTAssertEqual(PadKeys.keyEvent(forPadKey: 0x24), KeyEvent(charCode: 0x0D, keyCode: 0x24), "Return")
        XCTAssertEqual(PadKeys.keyEvent(forPadKey: 0x35), KeyEvent(charCode: 0x1B, keyCode: 0x35), "Esc")
        XCTAssertEqual(PadKeys.keyEvent(forPadKey: 0x7E)?.charCode, Console.upArrow, "↑ as the keyboard types it")
        XCTAssertEqual([0x7D, 0x7B, 0x7C].map { PadKeys.keyEvent(forPadKey: $0)?.charCode }, [0x1F, 0x1C, 0x1D])
        XCTAssertEqual(PadKeys.keyEvent(forPadKey: 0x31)?.charCode, 0x20, "Space")
        for code: UInt16 in [0x37, 0x3A, 0x38, 0x3B] {
            XCTAssertNil(PadKeys.keyEvent(forPadKey: code), "a modifier key types nothing (\(code))")
        }
        XCTAssertFalse(PadKeys.charCodes.keys.contains { PadKeys.keyEvent(forPadKey: $0)?.autoRepeat ?? true },
                       "a pad key never repeats")
        // Every key a pad layout binds outside play types its key.
        for context in [DeimosPadLayout.Context.mainMenu, .screens] {
            for binding in DeimosPadLayout.mapping(keySet: KeyTable(prefs: .fresh), context: context).bindings.values {
                if case let .key(code) = binding {
                    XCTAssertNotNil(PadKeys.keyEvent(forPadKey: code), "\(context): \(code)")
                }
            }
        }
    }

    /// The system's Quit request while the app is in the background (D10): the app pumps the driver unseen, with no
    /// live input (nothing held, the mouse button up, no position), and `BackgroundQuitPump` says when to stop. At the
    /// level select the request is taken (the quit flag) but nothing there reads it: the pump stops at once. At the
    /// menu it runs on to the shell's quit (the menu acts on the flag unseen: its quit flash clears it, then the fade
    /// and the quit). In a game the driver holds the game for the resume (D11) and the request stays queued: the pump
    /// stops, and after the return the game's first pass hands it to the front end, which holds it for the menu. With
    /// no request at all, the hard bound stops it. Bound: 120 simulated s a stage; the pump itself is bounded by `BackgroundQuitPump.maxTurns`.
    func testBackgroundQuitPumpStops() throws {
        /// Pumps `rig` as the app does in the background — the request in the first turn, nothing live after — until
        /// the pump says stop; returns the turns it ran (nil: the pump outran its own bound, a failure).
        func pump(_ rig: inout Rig, request: Bool = true) -> Int? {
            var p = BackgroundQuitPump()
            var keys = HeldKeys(events: request ? [.quitRequested] : [])
            for turn in 1...(BackgroundQuitPump.maxTurns + 1) {
                rig.idle(keys)
                keys = HeldKeys()
                if p.shouldStop(after: rig.driver) { return turn }
            }
            return nil
        }
        let a = try assets()

        // The level select: taken, never read — the pump stops as soon as the flag is set.
        var select = Rig(try FrontEnd(assets: a, prefs: .fresh))
        guard select.run(bound: 120, until: Rig.menuSettled) else { return XCTFail("bound: no menu") }
        select.idle(HeldKeys(keyEvents: [Self.typeOne]))
        guard select.run(bound: 120, until: { d, _ in d.frontEnd.screens.last == .levelSelect && !d.isFading })
        else { return XCTFail("bound: 1 never reached the level select") }
        select.driver.suspend()
        let selectTurns = try XCTUnwrap(pump(&select), "the pump never stopped at the level select")
        XCTAssertLessThan(selectTurns, 60, "it stops once the flag is set, not at the bound")
        XCTAssertTrue(select.driver.frontEnd.state.quit, "the request was taken")
        XCTAssertEqual(select.driver.frontEnd.screens.last, .levelSelect, "and nothing read it")
        XCTAssertEqual(select.driver.frontEnd.state.gamesStarted, 0, "no level started unseen")
        XCTAssertFalse(select.requests.contains(.quit))

        // The menu: the pump runs through the menu's quit to the shell's.
        var menu = Rig(try FrontEnd(assets: a, prefs: .fresh))
        guard menu.run(bound: 120, until: Rig.menuSettled) else { return XCTFail("bound: no menu (2)") }
        menu.driver.suspend()
        let menuTurns = try XCTUnwrap(pump(&menu), "the pump never stopped at the menu")
        XCTAssertLessThan(menuTurns, BackgroundQuitPump.maxTurns, "the menu's quit, not the bound")
        XCTAssertTrue(menu.driver.frontEnd.isFinished, "the menu quit unseen")
        XCTAssertEqual(menu.requests.filter { $0 == .quit }.count, 1, "the shell is asked to quit")

        // A game: held for the resume, the request queued — the pump stops, the game is not ended.
        var game = Rig(try FrontEnd(assets: a, prefs: .fresh))
        guard game.run(bound: 120, until: Rig.menuSettled) else { return XCTFail("bound: no menu (3)") }
        game.idle(HeldKeys(keyEvents: [Self.typeOne]))
        guard game.run(bound: 120, until: { d, _ in d.frontEnd.screens.last == .levelSelect }),
              game.run(HeldKeys(held: [KeyTable(prefs: .fresh).codes[6]]), bound: 120,
                       until: { d, _ in d.frontEnd.state.gameRunning })
        else { return XCTFail("bound: no game") }
        for _ in 0..<50 { game.idle() }
        game.driver.suspend()
        let gameTurns = try XCTUnwrap(pump(&game), "the pump never stopped in a game")
        XCTAssertLessThan(gameTurns, 60)
        XCTAssertTrue(game.driver.gameHeldWhileSuspended)
        XCTAssertEqual(game.driver.shellEventQueue, [.quitRequested], "the request waits in the driver's queue")
        XCTAssertFalse(game.driver.frontEnd.state.quit)
        XCTAssertFalse(game.requests.contains(.quit))
        game.driver.resume()
        let passes = game.driver.passCount
        guard game.run(bound: 10, until: { d, _ in d.passCount > passes }) else { return XCTFail("bound: no pass") }
        XCTAssertTrue(game.driver.frontEnd.quitRequestPending, "after the return: held for the menu")
        XCTAssertTrue(game.driver.frontEnd.state.gameRunning, "the game plays on")

        // No request taken or held anywhere: the hard bound.
        var idle = Rig(try FrontEnd(assets: a, prefs: .fresh))
        guard idle.run(bound: 120, until: Rig.menuSettled) else { return XCTFail("bound: no menu (4)") }
        idle.driver.suspend()
        XCTAssertEqual(pump(&idle, request: false), BackgroundQuitPump.maxTurns, "stopped by the bound")
    }

    /// Ruling 9: a decoded picture (RGBA, row 0 at the top) as the game's x1R5G5B5 pixels — each channel's top five
    /// bits, alpha dropped — and a picture whose byte count is wrong refused.
    func testShellPictureFromRGBA() throws {
        let rgba: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF,   0x00, 0x00, 0x00, 0x00,   0xF8, 0x07, 0x08, 0x80,
                             0x10, 0x87, 0xFF, 0xFF,   0x7F, 0x80, 0x0F, 0xFF,   0x08, 0x10, 0x18, 0xFF]
        let p = try XCTUnwrap(ShellPictures.picture(width: 3, height: 2, rgba: rgba))
        XCTAssertEqual(p.width, 3)
        XCTAssertEqual(p.height, 2)
        XCTAssertEqual(p.pixels, [0x7FFF, 0x0000, 0x7C01,
                                  0x0A1F, 0x3E01, 0x0443])
        XCTAssertNil(ShellPictures.picture(width: 3, height: 2, rgba: Array(rgba.dropLast())))
        XCTAssertEqual(ShellPictures.picture(width: 0, height: 0, rgba: [])?.pixels, [])
    }
}

/// A sink on the test's clock (single-threaded tests): an effect "sounds" for its `voiceLengths` ticks from the
/// tick its cue arrived (`now`, set by the test before each idle); ids with no length never sound. The first
/// arrival of each effect and of each music `.play` is recorded with its tick.
final class ClockedSink: DeimosAudioSink, @unchecked Sendable {
    var now: UInt32 = 0
    let voiceLengths: [FourCC: UInt32]
    private(set) var firstStart: [FourCC: UInt32] = [:]
    private(set) var musicStart: [FourCC: UInt32] = [:]

    init(voiceLengths: [FourCC: UInt32] = [:]) { self.voiceLengths = voiceLengths }

    func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?) {
        for s in sounds where firstStart[s.id] == nil { firstStart[s.id] = now }
        for case let .play(id, _) in music where musicStart[id] == nil { musicStart[id] = now }
    }

    func isPlaying(_ id: FourCC) -> Bool {
        guard let t = firstStart[id], let n = voiceLengths[id] else { return false }
        return now < t &+ n
    }

    func isMusicFading() -> Bool { false }
}

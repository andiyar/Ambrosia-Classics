import XCTest
@testable import DeimosCore

/// Phase 4 S1b SK-b — the front end's frame (plan S1b; grounding B §1, §5, §6; D Part 2 §7, Part 3): the `FrontEnd`
/// state machine, its stub screens and the direct start, stepped pass by pass without a host. The waits (a tick
/// wait, an event wait) and the quit inside the Caps Lock wait are run by the host, so those three tests are in
/// `DeimosHostTests.DriverTests` under their names.
final class FrontEndSkeletonTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let escKey: UInt16 = 0x35
    private static let f6Key: UInt16 = 0x61
    private static let minusKey: UInt16 = 0x1b
    private static let one = SessionStart(sector: 1, players: 1, film: nil)

    /// Passes until `done` holds after one; fails at `bound` (G11). Returns the outputs.
    @discardableResult
    private func passes(_ fe: inout FrontEnd, keys: HeldKeys = HeldKeys(), ticks: inout UInt32, bound: Int,
                        until done: (FrontEnd, PassOutput) -> Bool) -> [PassOutput]? {
        var outs: [PassOutput] = []
        for _ in 0..<bound {
            let out = fe.pass(keys: keys, ticks: ticks)
            ticks &+= 2
            outs.append(out)
            if done(fe, out) { return outs }
        }
        XCTFail("bound: \(bound) passes")
        return nil
    }

    /// The real boot (Phase 4 S6 BT, `BootTests`): passes at `ticks` until the main menu is the top screen — six with
    /// fresh prefs, the configuration window's stub running inside the first — so the menu's entry runs at `ticks`,
    /// as the boot stub's single pass did. `first` is the first pass's input (it reaches the boot). Returns the last
    /// pass's output (the boot's return chained into the menu's entry). Bound: 10 passes (G11).
    @discardableResult
    private func bootToMenu(_ fe: inout FrontEnd, first: HeldKeys = HeldKeys(), ticks: UInt32) -> PassOutput {
        var out = fe.pass(keys: first, ticks: ticks)
        for _ in 1..<10 where fe.screens.last != .mainMenu { out = fe.pass(keys: HeldKeys(), ticks: ticks) }
        if fe.screens.last != .mainMenu { XCTFail("bound: the menu is not up within 10 boot passes") }
        return out
    }

    /// Exactly `n` passes with `keys`.
    private func run(_ fe: inout FrontEnd, _ n: Int, keys: HeldKeys = HeldKeys(), ticks: inout UInt32) {
        for _ in 0..<n {
            _ = fe.pass(keys: keys, ticks: ticks)
            ticks &+= 2
        }
    }

    /// The `1` key as a player types it on the main menu (1 PLAYER; `front-end.md` §2.8).
    private static let typeOne = HeldKeys(keyEvents: [KeyEvent(charCode: 0x31, keyCode: 0x12)])

    /// The bound on the level select's frames between player 1's select and its exit (the accept flash: 16).
    private static let maxLevelSelectFrames = 40
    /// The pass on which start/return called the level select (its music stop and `ammu`, the level select's entry),
    /// as `startFromMenu` last saw it.
    private var levelSelectCall = PassOutput()

    /// The real menu (S2 MM) is up and waits for the player. A pass with `1` typed flashes 1 PLAYER and calls
    /// start/return; the flash drew, so the chain stops there. Start/return's start sequence (S3a SR,
    /// `StartReturnTests.testStartSequence`) then takes two passes — the cursor hidden and the element fade-out, then
    /// the fade to black — and the third (input `startKeys`) calls the level select (S3b LS), whose entry draws (kept
    /// in `levelSelectCall`). Its first live frame has player 1's select key held: sector 1 is accepted, and passes
    /// run until the level select has left (bound: `maxLevelSelectFrames`). The next pass hands its sector to
    /// start/return, which starts the game. Returns that game-starting pass's output.
    @discardableResult
    private func startFromMenu(_ fe: inout FrontEnd, ticks: inout UInt32, startKeys: HeldKeys = HeldKeys(),
                               _ label: String) -> PassOutput {
        XCTAssertEqual(fe.screens, [.mainMenu], "\(label): the menu is up")
        let started = fe.state.gamesStarted
        let flash = fe.pass(keys: Self.typeOne, ticks: ticks)
        ticks &+= 2
        XCTAssertTrue(flash.ops.contains(.hostWait(.ticks(10))), "\(label): 1 flashes 1 PLAYER")
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn], "\(label): 1 calls start/return")
        XCTAssertEqual(fe.state.gamesStarted, started, "\(label): the flash drew, so the chain stopped there")
        for n in 0..<2 {
            let out = fe.pass(keys: HeldKeys(), ticks: ticks)
            ticks &+= 2
            XCTAssertEqual(out.requests, n == 0 ? [.hideCursor] : [],
                           "\(label): the start sequence hides the cursor on its first pass")
            XCTAssertEqual(fe.state.gamesStarted, started, "\(label): the start sequence's pass \(n + 1)")
        }
        levelSelectCall = fe.pass(keys: startKeys, ticks: ticks)
        ticks &+= 2
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn, .levelSelect], "\(label): the level select is up")
        let select = KeyTable(prefs: fe.state.prefs).codes[6]                 // player 1's select (Space)
        _ = fe.pass(keys: HeldKeys(held: [select]), ticks: ticks)
        ticks &+= 2
        for _ in 0..<Self.maxLevelSelectFrames where fe.screens.last == .levelSelect {
            _ = fe.pass(keys: HeldKeys(), ticks: ticks)
            ticks &+= 2
        }
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn],
                       "\(label): bound: the level select did not leave within \(Self.maxLevelSelectFrames) frames")
        XCTAssertEqual(fe.state.gamesStarted, started, "\(label): the level select's exit pass drew")
        let out = fe.pass(keys: HeldKeys(), ticks: ticks)
        ticks &+= 2
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn], "\(label): the level select returned")
        XCTAssertEqual(fe.state.gamesStarted, started + 1, "\(label): start/return starts a game")
        XCTAssertTrue(fe.session?.running ?? false, label)
        return out
    }

    /// After a game that made no table, start/return's return sequence (S3a SR,
    /// `StartReturnTests.testReturnAfterGameOverSequence`): passes until the menu is the top screen again (bound: 4),
    /// then the menu's own return step — a pass of its own, since start/return's last pass draws — which outputs
    /// nothing. Returns start/return's last pass.
    @discardableResult
    private func backToMenu(_ fe: inout FrontEnd, ticks: inout UInt32, _ label: String) -> PassOutput {
        var last = PassOutput()
        for _ in 0..<4 where fe.screens != [.mainMenu] {
            last = fe.pass(keys: HeldKeys(), ticks: ticks)
            ticks &+= 2
        }
        XCTAssertEqual(fe.screens, [.mainMenu], "\(label): bound: not back on the menu within 4 passes")
        XCTAssertEqual(fe.pass(keys: HeldKeys(), ticks: ticks), PassOutput(), "\(label): the menu's return step")
        ticks &+= 2
        return last
    }

    /// The boot entry's first pass walks boot → main menu, whose entry draws, so the chain stops with the menu up and
    /// waiting (that pass's queued input reached only the boot). The player types `1`: the menu flashes 1 PLAYER and
    /// calls start/return, whose start sequence hides the cursor and fades out on its first pass and fades to black
    /// on its second (S3a SR); its third calls the level select (S3b), and that pass's queued input — typed, a key
    /// event, a mouse-down, a shell event — reaches only its first step (start/return): the level select, reached by a
    /// chained step, and the game after it are handed the held state alone. Player 1's select chooses sector 1; the
    /// pass after the level select leaves starts the game, whose first pass is the bare session's with the music
    /// already playing (start/return's stop and `ammu` rode the third pass), seeded with that pass's ticks (its frame
    /// controller's FPS clock too). When the game ends, start/return runs its return sequence, hands its result
    /// back and shows the cursor, and the menu waits again; `1` starts the next game. Every other stub returns at once with its
    /// declared value and an empty output. The shell's resources reach the shared state; a game with an empty
    /// recording, or a film session, leaves the Last Film alone. Bound: 3,000 passes.
    func testStubScreensPassThrough() throws {
        let a = try assets()
        let dialog = ShellResourceKey(FourCC("DITL")!, 190)
        var fe = try FrontEnd(assets: a, prefs: .fresh, shellResources: [dialog: [0x00, 0x13]])
        XCTAssertEqual(fe.state.shellResources, [dialog: [0x00, 0x13]], "the shell's resources reach the state")
        XCTAssertEqual(fe.state.menuElements, ElementList(), "the menu's list is empty until the menu builds it")
        XCTAssertNil(fe.state.menuLit)
        XCTAssertEqual(fe.screens, [.boot])
        XCTAssertNil(fe.session, "no game before the first pass")
        let t0: UInt32 = 5_000
        let queued = HeldKeys(typed: [0x61], mouseDowns: [MousePoint(h: 10, v: 20)],
                              keyEvents: [KeyEvent(charCode: 0x61, keyCode: 0x00)], events: [.aboutChosen])
        bootToMenu(&fe, first: queued, ticks: t0)
        XCTAssertEqual(fe.screens, [.mainMenu],
                       "boot returned; the menu is up (the queued About went to the boot, the first step, not the menu)")
        XCTAssertNil(fe.session, "the menu waits for the player")
        XCTAssertEqual(fe.state.gamesStarted, 0)

        // The player types 1: the menu flashes 1 PLAYER and calls start/return; the level select chooses sector 1.
        var ticks = t0 &+ 2
        let t1 = t0 &+ 44                                             // the game-starting pass
        let first = startFromMenu(&fe, ticks: &ticks, startKeys: queued, "the first game")
        let s = try XCTUnwrap(fe.session)
        XCTAssertEqual(s.sector, 1)
        XCTAssertEqual(s.players.filter(\.inGame).count, 1)
        XCTAssertNil(s.start.film)
        XCTAssertEqual(fe.state.gamesStarted, 1)
        let afterSelect = SessionStart(sector: 1, players: 1, film: nil, musicAlreadyPlaying: true)
        XCTAssertEqual(s.start, afterSelect)
        var bare = try DeimosSession(assets: a, prefs: .fresh, start: afterSelect, seed: t1, ticks: t1)
        let reference = bare.pass(keys: HeldKeys(), ticks: t1)
        XCTAssertEqual(first.ops, reference.ops, "the game's first pass is the bare session's (seed = its ticks)")
        XCTAssertEqual(levelSelectCall.music, [.stop, .play(FourCC("ammu")!, loop: true)],
                       "start/return's music stop and ammu, on the pass that calls the level select")
        XCTAssertEqual(first.music, reference.music, "then the game's")
        XCTAssertEqual(first.requests, [], "the cursor was hidden on the start sequence's first pass (startFromMenu)")
        XCTAssertEqual(fe.session?.rng, bare.rng)
        XCTAssertEqual(fe.session?.controller, bare.controller,
                       "its frame controller's FPS clock starts at that pass's ticks (FUN_100305e0)")
        XCTAssertEqual(fe.state.game?.lastKeys, HeldKeys(),
                       "the queued input went to start/return (the first step); the chained game saw none of it")

        // Esc ends the game; the next pass returns its result to the menu, which waits; 1 starts another.
        run(&fe, 100, ticks: &ticks)
        guard let escOuts = passes(&fe, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                                   until: { _, out in out.sessionEnded }) else { return }
        XCTAssertEqual(fe.session?.result?.end, .escape)
        let recorded = try XCTUnwrap(fe.session?.result).recordedFilm
        XCTAssertEqual(fe.state.lastFilm, recorded, "the recording (S5) is kept as the Last Film")
        XCTAssertEqual(escOuts.flatMap { $0.requests.filter { if case .saveLastFilm = $0 { true } else { false } } },
                       [.saveLastFilm(recorded)])
        let back = backToMenu(&fe, ticks: &ticks, "the first game")
        XCTAssertEqual(back.requests, [.showCursor], "start/return shows the cursor; the menu is up again")
        XCTAssertEqual(fe.screens, [.mainMenu])
        XCTAssertEqual(fe.state.gamesStarted, 1, "the menu starts no game by itself")
        let again = startFromMenu(&fe, ticks: &ticks, "the second game")
        XCTAssertEqual(again.requests, [], "the next game hid the cursor on its start sequence's first pass")
        XCTAssertEqual(fe.state.gamesStarted, 2)
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn])
        XCTAssertTrue(fe.session?.running ?? false)

        // The other stubs, one pass each.
        var state = fe.state
        func check<R: Equatable>(_ step: ScreenStep<R>, _ value: R, _ label: String) {
            XCTAssertEqual(step.finished, value, label)
            XCTAssertEqual(step.output, PassOutput(), "\(label): a stub draws nothing")
        }
        // The boot is no longer a stub (Phase 4 S6 built it): BootTests and ConfigDialogTests pin it.
        // Scores and name entry are built (Phase 4 S4 HS): ScoresScreenTests, NameEntryTests.
        // (The credits are no longer a stub — S2 CR: CreditsTests owns them.)
        // Films is built (Phase 4 S5 DM): FilmsTests.
        var config = ConfigDialog(firstLaunch: true)
        check(config.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), false, "configuration window")
        var controls = ControlsDialog()
        check(controls.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), false, "controls window")
        XCTAssertEqual(state.prefs, fe.state.prefs, "no stub touches the prefs")

        // Start/return in play mode calls the level select first, on the third pass of its start sequence (S3a SR);
        // the menu with the quit flag set runs its quit
        // sequence (MainMenuTests.testMenuQuitSequence) and returns, calling no screen, in exactly 5 passes: the entry,
        // the QUIT flash, the rest of that turn, the fade-out, then the free and the music stop. Bound: 10 passes.
        var play = StartReturn(mode: .play, players: 2)
        for n in 0..<2 {
            XCTAssertNil(play.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state).callee, "start pass \(n + 1)")
        }
        let call = play.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state)
        XCTAssertEqual(call.callee, .levelSelect)
        var menu = MainMenu()
        state.quit = true
        var menuState = state
        var menuDone: ScreenDone?
        var menuPasses = 0
        for t in UInt32(0)..<10 {
            menuPasses += 1
            let step = menu.pass(keys: HeldKeys(), ticks: t, returned: nil, state: &menuState)
            XCTAssertNil(step.callee, "main menu, quit set: no screen called")
            if let done = step.finished { menuDone = done; break }
        }
        XCTAssertEqual(menuDone, ScreenDone(), "main menu, quit set: it returns (bound: 10 passes)")
        XCTAssertEqual(menuPasses, 5, "main menu, quit set: entry, flash, rest of the turn, fade-out, free")

        // A film session (start/return in demo mode, de01) that ends with a recording leaves the Last Film alone.
        let index = try RealData.index()
        let film = try Film(data: index.data(for: XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC("de01")!))))
        var demo = StartReturn(mode: .demo, players: 1, film: film)
        state.lastFilm = [0x01]
        state.recordedFilmForTests = [0x02]
        var demoEnded = false
        for _ in 0..<1_000 {
            let step = demo.pass(keys: HeldKeys(held: [Self.escKey]), ticks: ticks, returned: nil, state: &state)
            ticks &+= 2
            XCTAssertFalse(step.output.requests.contains { if case .saveLastFilm = $0 { true } else { false } })
            if step.output.sessionEnded { demoEnded = true; break }
        }
        XCTAssertTrue(demoEnded, "bound: 1,000 passes")
        XCTAssertEqual(state.game?.session.result?.isFilm, true)
        XCTAssertEqual(state.lastFilm, [0x01], "a film session leaves the Last Film alone")
    }

    /// The direct start's first pass starts its game as that pass's first step, and the session start's FlushEvents
    /// (`FUN_10030210`) empties the OS queue the game is handed — typed, key events, mouse-downs — keeping the shell's
    /// events. The system's Quit request reaching a game is held, not taken (grounding B §5: the Quit Apple event
    /// waits in the queue for the menu's pump; Phase 4 S8a CR): the quit flag stays clear and the game plays on. When
    /// the game ends, the direct start (the menu's stand-in) takes the held request, asks the shell to quit and starts
    /// no new game; through the boot entry (a game started from the menu with `1`), start/return comes back to the
    /// menu, which takes it, runs its quit sequence and returns, and the front end asks the shell to quit. A request
    /// during the boot: the menu comes up, takes it on its first turn, leaves the same way and never starts a game.
    /// Bound: 1,000 passes per wait, 10 for each way out.
    func testQuitRequestReachesFrontEnd() throws {
        let a = try assets()
        var ticks: UInt32 = 9_000

        // The direct start.
        var direct = try FrontEnd(direct: Self.one, assets: a, prefs: .fresh)
        _ = direct.pass(keys: HeldKeys(typed: [0x61], mouseDowns: [MousePoint(h: 10, v: 20)],
                                       keyEvents: [KeyEvent(charCode: 0x61, keyCode: 0x00)], events: [.aboutChosen]),
                        ticks: ticks)
        ticks &+= 2
        XCTAssertEqual(direct.state.game?.lastKeys, HeldKeys(events: [.aboutChosen]),
                       "a game's start flushes the OS queue (FUN_10030210); the shell's events stay")
        run(&direct, 19, ticks: &ticks)
        XCTAssertFalse(direct.state.quit)
        let quitPass = direct.pass(keys: HeldKeys(events: [.quitRequested]), ticks: ticks)
        XCTAssertFalse(direct.state.quit, "held, not taken, in a game")
        XCTAssertTrue(direct.quitRequestPending)
        XCTAssertEqual(direct.state.game?.lastKeys.events, [], "the game is not handed the held request")
        XCTAssertFalse(quitPass.sessionEnded, "a Quit does not end the game in play")
        XCTAssertEqual(quitPass.requests, [])
        for _ in 0..<50 { XCTAssertFalse(direct.pass(keys: HeldKeys(), ticks: ticks).sessionEnded) }
        XCTAssertTrue(direct.session?.running ?? false)
        guard passes(&direct, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                     until: { _, out in out.sessionEnded }) != nil else { return }
        let after = direct.pass(keys: HeldKeys(), ticks: ticks)
        XCTAssertEqual(after.requests, [.quit], "the shell is asked to quit")
        XCTAssertEqual(after.ops, [])
        XCTAssertEqual(direct.state.gamesStarted, 1, "no new game")
        XCTAssertTrue(direct.isFinished)
        for _ in 0..<5 { XCTAssertEqual(direct.pass(keys: HeldKeys(), ticks: ticks), PassOutput()) }

        // The boot entry: the system's Quit request during the game.
        var boot = try FrontEnd(assets: a, prefs: .fresh)
        bootToMenu(&boot, ticks: ticks)
        ticks &+= 2
        startFromMenu(&boot, ticks: &ticks, "boot entry")
        run(&boot, 17, ticks: &ticks)
        _ = boot.pass(keys: HeldKeys(events: [.quitRequested]), ticks: ticks)
        XCTAssertFalse(boot.state.quit, "held in the game")
        XCTAssertTrue(boot.quitRequestPending)
        guard passes(&boot, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                     until: { _, out in out.sessionEnded }) != nil else { return }
        // backToMenu ends with the menu's return step: the menu is the top screen there, so the held request reaches
        // it (b8) on that pass, as the queued Apple event reaches the menu's pump.
        let back = backToMenu(&boot, ticks: &ticks, "boot entry")
        XCTAssertEqual(back.requests, [.showCursor], "back to the menu (start/return shows the cursor)")
        XCTAssertTrue(boot.state.quit, "taken at the menu")
        XCTAssertFalse(boot.quitRequestPending)
        // The menu, its quit flag set, runs its quit sequence (MainMenuTests.testMenuQuitSequence) and leaves; then
        // the shutdown.
        guard let leaving = passes(&boot, ticks: &ticks, bound: 10, until: { fe, _ in fe.isFinished }) else { return }
        XCTAssertEqual(leaving.last?.requests, [.quit], "the menu leaves; then the shutdown")
        // The QUIT flash, the rest of that turn, the fade-out, the free and music stop, the frame's shutdown request.
        XCTAssertEqual(leaving.count, 5, "the quit sequence's passes")
        XCTAssertEqual(([back] + leaving).flatMap(\.requests).filter { $0 == .quit }.count, 1, "one shutdown")
        XCTAssertFalse(leaving.flatMap(\.requests).contains(.hideCursor), "no new game")
        XCTAssertEqual(boot.state.gamesStarted, 1)
        XCTAssertEqual(boot.screens, [])
        XCTAssertTrue(boot.isFinished)

        // The boot entry: the request during the boot, before any game. Held through the boot; the menu comes up,
        // takes it on its first turn (the next pass), runs its quit sequence and never starts a game.
        var early = try FrontEnd(assets: a, prefs: .fresh)
        let out = bootToMenu(&early, first: HeldKeys(events: [.quitRequested]), ticks: ticks)
        ticks &+= 2
        XCTAssertFalse(early.state.quit, "held during the boot")
        XCTAssertTrue(early.quitRequestPending)
        XCTAssertEqual(early.screens, [.mainMenu])
        XCTAssertEqual(out.requests, [.showCursor], "the menu's entry")
        XCTAssertFalse(out.ops.isEmpty, "the menu's entry draws")
        guard let rest = passes(&early, ticks: &ticks, bound: 10, until: { fe, _ in fe.isFinished }) else { return }
        XCTAssertEqual(rest.last?.requests, [.quit], "then the shutdown")
        XCTAssertEqual(rest.count, 5, "flash, rest of the turn, fade-out, free and music stop, shutdown request")
        XCTAssertEqual(rest.last?.ops, [])
        XCTAssertEqual(rest.flatMap(\.requests).filter { $0 == .quit }.count, 1, "one shutdown")
        XCTAssertEqual(early.state.gamesStarted, 0)
        XCTAssertNil(early.session)
    }

    /// From the menu with `1` to the level select's first live frame (`startFromMenu`'s first four passes).
    private func toLevelSelect(_ fe: inout FrontEnd, ticks: inout UInt32, _ label: String) {
        _ = fe.pass(keys: Self.typeOne, ticks: ticks)
        ticks &+= 2
        run(&fe, 3, ticks: &ticks)
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn, .levelSelect], "\(label): the level select is up")
    }

    /// `event` at the level select takes b8 at once (X: the level select pumps one event per frame, X `1002ec5c` →
    /// X `10023300`, whose Quit Apple event case sets the flag, X `10023374`; `osx-build.md` D10 — the menu-bar or ⌘Q
    /// Quit reaches it as the application menu's Quit, a Quit Apple event): nothing is held and the level select goes
    /// on, since it never reads the flag. Esc held leaves it ('none'); back at the menu, the menu runs its quit
    /// sequence and the shell is asked to quit; no game was started. Bound: 200 passes to the menu, 12 to the quit.
    private func quitAtLevelSelect(_ event: ShellEvent, _ a: DeimosAssets, ticks: inout UInt32) throws {
        let label = "level select \(event)"
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        bootToMenu(&fe, ticks: ticks)
        ticks &+= 2
        toLevelSelect(&fe, ticks: &ticks, label)
        _ = fe.pass(keys: HeldKeys(events: [event]), ticks: ticks)
        ticks &+= 2
        XCTAssertTrue(fe.state.quit, "\(label): b8 at once")
        XCTAssertFalse(fe.quitRequestPending, label)
        XCTAssertEqual(fe.screens.last, .levelSelect, "\(label): the level select goes on")
        guard passes(&fe, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 200,
                     until: { fe, _ in fe.screens == [.mainMenu] }) != nil else { return }
        guard let out = passes(&fe, ticks: &ticks, bound: 12, until: { fe, _ in fe.isFinished }) else { return }
        XCTAssertEqual(out.last?.requests, [.quit], "\(label): the menu quits")
        XCTAssertEqual(fe.state.gamesStarted, 0, label)
    }

    /// ⌘Q / the menu-bar Quit (`ShellEvent.quitChosen`) is ignored in a game, as the original (grounding B §5: the
    /// quit flag's setters are reached only from the menu loop's event pump, and no pump runs in play; Ben
    /// 2026-11-20): the quit flag stays clear, nothing is held, the game is not handed it and plays on; its end
    /// returns to the menu, which stays up. The same during the boot (the loading lines' X pump acts on suspend and
    /// resume only, D17): the Quit is dropped there, and that drop is what keeps the menu up — the menu's entry does
    /// not clear b8 (it keeps it, `MainMenu`). The pause's wait is the host's
    /// (`DriverTests.testQuitInsideCapsLockWait`). Bound: 1,000 passes per wait; 30 menu passes.
    func testQuitChosenIgnoredInGame() throws {
        let a = try assets()
        var ticks: UInt32 = 30_000
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        bootToMenu(&fe, first: HeldKeys(events: [.quitChosen]), ticks: ticks)
        ticks &+= 2
        XCTAssertFalse(fe.state.quit, "the boot: ignored")
        XCTAssertFalse(fe.quitRequestPending, "the boot: dropped, not held")
        startFromMenu(&fe, ticks: &ticks, "ignored")
        run(&fe, 17, ticks: &ticks)
        let out = fe.pass(keys: HeldKeys(events: [.quitChosen]), ticks: ticks)
        ticks &+= 2
        XCTAssertFalse(fe.state.quit, "the game: ignored")
        XCTAssertFalse(fe.quitRequestPending, "the game: dropped, not held")
        XCTAssertFalse(out.sessionEnded)
        XCTAssertEqual(fe.state.game?.lastKeys.events, [], "the game is not handed it")
        for _ in 0..<50 {
            XCTAssertFalse(fe.pass(keys: HeldKeys(), ticks: ticks).sessionEnded)
            ticks &+= 2
        }
        XCTAssertTrue(fe.session?.running ?? false, "the game plays on")
        guard passes(&fe, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                     until: { _, out in out.sessionEnded }) != nil else { return }
        backToMenu(&fe, ticks: &ticks, "ignored")
        for _ in 0..<30 {
            XCTAssertFalse(fe.pass(keys: HeldKeys(), ticks: ticks).requests.contains(.quit))
            ticks &+= 2
        }
        XCTAssertEqual(fe.screens, [.mainMenu], "the menu stays up")
        XCTAssertFalse(fe.state.leave)
        XCTAssertFalse(fe.isFinished)
    }

    /// The system's Quit request (`ShellEvent.quitRequested`, the Quit Apple event) waits for the menu (grounding B
    /// §5; Phase 4 S8a CR): it is held through a screen whose loop reads no Apple event — here the credits — with the
    /// flag clear, and the menu takes it on its first pass back; the app having been suspended meanwhile, the menu's
    /// pump resumes first (code 8: resume if suspended, then b8; the cursor shown), then runs its quit sequence and
    /// the shell is asked to quit. At the level select it is taken at once (`quitAtLevelSelect`). The game's case is
    /// `testQuitRequestReachesFrontEnd`. Bound: 200 passes to the menu, 12 to the quit.
    func testQuitRequestedWaitsForMenu() throws {
        let a = try assets()
        var ticks: UInt32 = 40_000
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        bootToMenu(&fe, ticks: ticks)
        ticks &+= 2
        _ = fe.pass(keys: HeldKeys(events: [.aboutChosen]), ticks: ticks)
        ticks &+= 2
        XCTAssertEqual(fe.screens, [.mainMenu, .credits], "About opens the credits")
        _ = fe.pass(keys: HeldKeys(events: [.quitRequested]), ticks: ticks)
        ticks &+= 2
        XCTAssertFalse(fe.state.quit, "held in the credits")
        XCTAssertTrue(fe.quitRequestPending)
        _ = fe.pass(keys: HeldKeys(events: [.suspend]), ticks: ticks)
        ticks &+= 2
        XCTAssertTrue(fe.state.suspended)
        XCTAssertEqual(fe.screens, [.mainMenu, .credits], "the credits go on")
        let x = HeldKeys(keyEvents: [KeyEvent(charCode: 0x78, keyCode: 0x07)])
        guard passes(&fe, keys: x, ticks: &ticks, bound: 200, until: { fe, _ in fe.screens == [.mainMenu] }) != nil
        else { return }
        XCTAssertTrue(fe.quitRequestPending, "still held until the menu's own pass")
        guard let out = passes(&fe, ticks: &ticks, bound: 12, until: { fe, _ in fe.isFinished }) else { return }
        XCTAssertFalse(fe.quitRequestPending)
        XCTAssertFalse(fe.state.suspended, "the menu's pump resumed first")
        XCTAssertTrue(out.flatMap(\.requests).contains(.showCursor), "the resume handler's cursor")
        XCTAssertEqual(out.last?.requests, [.quit], "then the shutdown")
        XCTAssertEqual(out.flatMap(\.requests).filter { $0 == .quit }.count, 1)

        try quitAtLevelSelect(.quitRequested, a, ticks: &ticks)
    }

    /// ⌘Q / the menu-bar Quit at the menu still quits (`FUN_10023330(2)`: b8 — the QUIT flash on that pass, the rest of
    /// the turn, the fade-out, the music stop, the shutdown request: five passes, `MainMenuTests
    /// .testMenuQuitSequence`), and at the level select it takes b8 at once, as the system's request does
    /// (`quitAtLevelSelect`). Bound: 10 passes.
    func testQuitChosenAtMenuStillQuits() throws {
        let a = try assets()
        var ticks: UInt32 = 50_000
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        bootToMenu(&fe, ticks: ticks)
        ticks &+= 2
        let flash = fe.pass(keys: HeldKeys(events: [.quitChosen]), ticks: ticks)
        ticks &+= 2
        XCTAssertTrue(flash.ops.contains(.hostWait(.ticks(10))), "the QUIT flash on the same pass")
        XCTAssertTrue(fe.state.leave, "b9")
        XCTAssertFalse(fe.state.quit, "b8 cleared by the flash")
        guard let rest = passes(&fe, ticks: &ticks, bound: 10, until: { fe, _ in fe.isFinished }) else { return }
        XCTAssertEqual(rest.count, 4, "five passes in all")
        XCTAssertEqual(rest.last?.requests, [.quit])

        try quitAtLevelSelect(.quitChosen, a, ticks: &ticks)
    }

    /// The front end owns the live prefs (grounding B §6; ◇ stand-in 6 retired): a game starts from them and hands
    /// its own back on the pass that ends it — F6 (byte pref 5) and `-` (int pref 0, 50 → 40) survive an Esc and a
    /// game over into the next games, by the direct start and by the boot entry. `livePrefs` (what the shutdown
    /// saves) is the running game's while one runs. Each game's recorded film (a test stand-in until S5's recorder)
    /// becomes the Last Film in memory and is handed to the shell on the pass that ends it (plan ruling 7).
    /// Bound: 6,000 passes per wait.
    func testPrefsCarriedThroughSessions() throws {
        let a = try assets()
        var ticks: UInt32 = 20_000
        for entry in ["direct", "boot"] {
            var fe = entry == "direct" ? try FrontEnd(direct: Self.one, assets: a, prefs: .fresh)
                                       : try FrontEnd(assets: a, prefs: .fresh)
            if entry == "direct" {
                run(&fe, 20, ticks: &ticks)
            } else {
                bootToMenu(&fe, ticks: ticks)
                ticks &+= 2
                startFromMenu(&fe, ticks: &ticks, entry)
                run(&fe, 17, ticks: &ticks)
            }
            _ = fe.pass(keys: HeldKeys(held: [Self.f6Key, Self.minusKey]), ticks: ticks)
            XCTAssertEqual(fe.session?.prefs.bytePrefs[5], 1, entry)
            XCTAssertEqual(fe.session?.prefs.intPrefs[0], 40, entry)
            XCTAssertEqual(fe.state.prefs.intPrefs[0], 50, "\(entry): the game hands its prefs back when it ends")
            XCTAssertEqual(fe.livePrefs.intPrefs[0], 40, "\(entry): the live prefs are the running game's")

            // The Last Film (plan ruling 7): a non-film game that ends with a recording keeps it in memory and asks
            // the shell to save it, on its ending pass. (The recorder lands in S5: the test stands in for it.)
            let firstFilm: [UInt8] = [0xF1, 0x1A, 0x01]
            fe.state.recordedFilmForTests = firstFilm
            XCTAssertEqual(fe.state.lastFilm, [], entry)
            guard let escOuts = passes(&fe, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                                       until: { _, out in out.sessionEnded }) else { return }
            XCTAssertEqual(fe.state.lastFilm, firstFilm, "\(entry): the Last Film, in memory")
            XCTAssertEqual(escOuts.last?.requests.filter { $0 == .saveLastFilm(firstFilm) }.count, 1,
                           "\(entry): saved on the ending pass")
            XCTAssertEqual(escOuts.dropLast().flatMap(\.requests)
                .filter { if case .saveLastFilm = $0 { true } else { false } }, [], "\(entry): only then")
            XCTAssertEqual(fe.state.prefs.bytePrefs[5], 1, "\(entry): carried on the ending pass: F6")
            XCTAssertEqual(fe.state.prefs.intPrefs[0], 40, "\(entry): carried: the volume")
            XCTAssertEqual(fe.livePrefs, fe.state.prefs)
            if entry == "boot" {
                backToMenu(&fe, ticks: &ticks, entry)
                XCTAssertEqual(fe.state.gamesStarted, 1, "\(entry): back on the menu, which waits")
                startFromMenu(&fe, ticks: &ticks, entry)
            } else {
                _ = fe.pass(keys: HeldKeys(), ticks: ticks)
            }
            XCTAssertEqual(fe.state.gamesStarted, 2, entry)
            XCTAssertTrue(fe.session?.restoreInterlace ?? false, "\(entry): the next level start saw pref 5 set")
            XCTAssertEqual(fe.session?.prefs.intPrefs[0], 40, entry)

            // No input: the pilot dies; game over ends the second game, and the third starts from its prefs.
            let secondFilm: [UInt8] = [0xF1, 0x1A, 0x02]
            fe.state.recordedFilmForTests = secondFilm
            // (By the boot entry the game over returns to the menu, which waits; 1 starts the third game.)
            guard var overOuts = passes(&fe, ticks: &ticks, bound: 6_000, until: { fe, _ in
                entry == "direct" ? fe.state.gamesStarted == 3 : fe.screens == [.mainMenu]
            }) else { return }
            if entry == "boot" {
                XCTAssertEqual(fe.state.gamesStarted, 2, "\(entry): the menu starts no game by itself")
                XCTAssertEqual(fe.pass(keys: HeldKeys(), ticks: ticks), PassOutput(), "\(entry): the menu's return step")
                ticks &+= 2
                overOuts.append(startFromMenu(&fe, ticks: &ticks, entry))
                XCTAssertEqual(fe.state.gamesStarted, 3, entry)
            }
            XCTAssertEqual(fe.state.lastFilm, secondFilm, "\(entry): the game over's recording replaces it")
            XCTAssertEqual(overOuts.flatMap(\.requests).filter { if case .saveLastFilm = $0 { true } else { false } },
                           [.saveLastFilm(secondFilm)], "\(entry): one save, at the game over")
            XCTAssertEqual(fe.state.prefs.bytePrefs[5], 1, "\(entry): carried again (restored at the appear)")
            XCTAssertEqual(fe.state.prefs.intPrefs[0], 40, entry)
            XCTAssertEqual(fe.session?.prefs.intPrefs[0], 40, entry)
        }
    }
}

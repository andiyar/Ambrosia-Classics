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

    /// Exactly `n` passes with `keys`.
    private func run(_ fe: inout FrontEnd, _ n: Int, keys: HeldKeys = HeldKeys(), ticks: inout UInt32) {
        for _ in 0..<n {
            _ = fe.pass(keys: keys, ticks: ticks)
            ticks &+= 2
        }
    }

    /// The boot entry walks boot → main menu → start/return → level select (sector 1) → a running game, all in the
    /// first pass (no stub draws, so the steps chain); the game's first pass is the bare session's, seeded with that
    /// pass's ticks (its frame controller's FPS clock too), and carries the cursor hide. That pass's queued input —
    /// typed, a key event, a mouse-down, a shell event — reaches only its first step (the boot): the game, reached
    /// by chained steps, is handed the held state alone. When the game ends, start/return hands its result back and shows the
    /// cursor, and the menu stub starts the next game in the same pass. Every other stub returns at once with its
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
        let first = fe.pass(keys: queued, ticks: t0)
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn], "boot returned; the level select returned")
        let s = try XCTUnwrap(fe.session)
        XCTAssertEqual(s.sector, 1)
        XCTAssertEqual(s.players.filter(\.inGame).count, 1)
        XCTAssertNil(s.start.film)
        XCTAssertEqual(fe.state.gamesStarted, 1)
        var bare = try DeimosSession(assets: a, prefs: .fresh, start: Self.one, seed: t0, ticks: t0)
        let reference = bare.pass(keys: HeldKeys(), ticks: t0)
        XCTAssertEqual(first.ops, reference.ops, "the game's first pass is the bare session's (seed = its ticks)")
        XCTAssertEqual(first.music, reference.music)
        XCTAssertEqual(first.requests, [.hideCursor], "the front end hides the cursor on the pass that starts a game")
        XCTAssertEqual(fe.session?.rng, bare.rng)
        XCTAssertEqual(fe.session?.controller, bare.controller,
                       "its frame controller's FPS clock starts at that pass's ticks (FUN_100305e0)")
        XCTAssertEqual(fe.state.game?.lastKeys, HeldKeys(),
                       "the queued input went to the boot (the first step); the chained game saw none of it")

        // Esc ends the game; the next pass returns its result to the menu, which starts another.
        var ticks = t0 &+ 2
        run(&fe, 100, ticks: &ticks)
        guard let escOuts = passes(&fe, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                                   until: { _, out in out.sessionEnded }) else { return }
        XCTAssertEqual(fe.session?.result?.end, .escape)
        XCTAssertEqual(fe.state.lastFilm, [], "an empty recording changes nothing")
        XCTAssertFalse(escOuts.contains { $0.requests.contains { if case .saveLastFilm = $0 { true } else { false } } })
        let back = fe.pass(keys: HeldKeys(), ticks: ticks)
        XCTAssertEqual(back.requests, [.showCursor, .hideCursor], "start/return shows the cursor; the next game hides it")
        XCTAssertEqual(fe.state.gamesStarted, 2)
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn])
        XCTAssertTrue(fe.session?.running ?? false)

        // The other stubs, one pass each.
        var state = fe.state
        func check<R: Equatable>(_ step: ScreenStep<R>, _ value: R, _ label: String) {
            XCTAssertEqual(step.finished, value, label)
            XCTAssertEqual(step.output, PassOutput(), "\(label): a stub draws nothing")
        }
        var boot = Boot()
        check(boot.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), ScreenDone(), "boot")
        var levelSelect = LevelSelect()
        check(levelSelect.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), 1, "level select")
        var scores = Scores()
        check(scores.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), .leave, "scores")
        var nameEntry = NameEntry(player: 0, slot: 3, prefs: .fresh)
        check(nameEntry.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), .fresh, "name entry")
        var credits = Credits()
        check(credits.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), .leave, "credits")
        for kind in [Films.Kind.demo, .lastFilm] {
            var films = Films(kind: kind)
            check(films.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), ScreenDone(), "films \(kind)")
        }
        var config = ConfigDialog(firstLaunch: true)
        check(config.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), false, "configuration window")
        var controls = ControlsDialog()
        check(controls.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), false, "controls window")
        XCTAssertEqual(state.prefs, fe.state.prefs, "no stub touches the prefs")

        // Start/return in play mode calls the level select first; the menu with the quit flag set returns.
        var play = StartReturn(mode: .play, players: 2)
        let call = play.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state)
        XCTAssertEqual(call.callee, .levelSelect)
        var menu = MainMenu()
        state.quit = true
        check(menu.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &state), ScreenDone(), "main menu, quit set")

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
    /// events. A Quit (menu command or the system's request) reaching a pass sets the front end's quit flag; it does
    /// not end the game in play. When the game ends, the direct start asks the shell to quit and starts no new game; through
    /// the boot entry, start/return comes back to the menu stub, which returns, and the front end asks the shell to
    /// quit. A Quit before the first game: the menu stub never starts one. Bound: 1,000 passes per wait.
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
        XCTAssertTrue(direct.state.quit)
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

        // The boot entry: Quit chosen during the game.
        var boot = try FrontEnd(assets: a, prefs: .fresh)
        run(&boot, 20, ticks: &ticks)
        _ = boot.pass(keys: HeldKeys(events: [.quitChosen]), ticks: ticks)
        XCTAssertTrue(boot.state.quit)
        guard passes(&boot, keys: HeldKeys(held: [Self.escKey]), ticks: &ticks, bound: 1_000,
                     until: { _, out in out.sessionEnded }) != nil else { return }
        let back = boot.pass(keys: HeldKeys(), ticks: ticks)
        XCTAssertEqual(back.requests, [.showCursor, .quit], "back to the menu, which leaves; then the shutdown")
        XCTAssertEqual(boot.state.gamesStarted, 1)
        XCTAssertEqual(boot.screens, [])
        XCTAssertTrue(boot.isFinished)

        // The boot entry: Quit before any game.
        var early = try FrontEnd(assets: a, prefs: .fresh)
        let out = early.pass(keys: HeldKeys(events: [.quitRequested]), ticks: ticks)
        XCTAssertEqual(out.requests, [.quit])
        XCTAssertEqual(out.ops, [])
        XCTAssertEqual(early.state.gamesStarted, 0)
        XCTAssertNil(early.session)
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
            run(&fe, 20, ticks: &ticks)
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
            _ = fe.pass(keys: HeldKeys(), ticks: ticks)
            XCTAssertEqual(fe.state.gamesStarted, 2, entry)
            XCTAssertTrue(fe.session?.restoreInterlace ?? false, "\(entry): the next level start saw pref 5 set")
            XCTAssertEqual(fe.session?.prefs.intPrefs[0], 40, entry)

            // No input: the pilot dies; game over ends the second game, and the third starts from its prefs.
            let secondFilm: [UInt8] = [0xF1, 0x1A, 0x02]
            fe.state.recordedFilmForTests = secondFilm
            guard let overOuts = passes(&fe, ticks: &ticks, bound: 6_000,
                                        until: { fe, _ in fe.state.gamesStarted == 3 }) else { return }
            XCTAssertEqual(fe.state.lastFilm, secondFilm, "\(entry): the game over's recording replaces it")
            XCTAssertEqual(overOuts.flatMap(\.requests).filter { if case .saveLastFilm = $0 { true } else { false } },
                           [.saveLastFilm(secondFilm)], "\(entry): one save, at the game over")
            XCTAssertEqual(fe.state.prefs.bytePrefs[5], 1, "\(entry): carried again (restored at the appear)")
            XCTAssertEqual(fe.state.prefs.intPrefs[0], 40, entry)
            XCTAssertEqual(fe.session?.prefs.intPrefs[0], 40, entry)
        }
    }
}

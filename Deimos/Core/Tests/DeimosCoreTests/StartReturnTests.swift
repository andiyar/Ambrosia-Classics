import XCTest
@testable import DeimosCore

/// Phase 4 S3a SR — start a game and return to the menu, `FUN_100234d0(mode, players)` as the OS X build runs it
/// (X `100238c0`; grounding B §1a–§1e, §8; `front-end.md` §3; `osx-build.md` D7, D9, D13): the start sequence, the
/// return by the kind of end, the post-game gates (pref 3, the high-score table) and the menu music. Start/return is
/// stepped pass by pass, either alone over a state whose menu entry ran (to hand it what the level select or name
/// entry returned) or inside a `FrontEnd` (to see the menu around it). Every loop names its bound and fails on it
/// (G11).
final class StartReturnTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let escKey: UInt16 = 0x35
    private static let typeOne = HeldKeys(keyEvents: [KeyEvent(charCode: 0x31, keyCode: 0x12)])
    private static let inmu = FourCC("inmu")!
    private static let ammu = FourCC("ammu")!
    /// TGA `back` into the back and save buffers.
    private static let backBoth: [RenderOp] = [
        .loadImage(image: FourCC("back")!, into: .back, dst: MacRect(top: 0, left: 0, bottom: 480, right: 640)),
        .loadImage(image: FourCC("back")!, into: .terrain, dst: MacRect(top: 0, left: 0, bottom: 480, right: 640)),
    ]

    /// gaso 3 `tran` (multiple 1): 0x4b leaving the menu, 0x32 coming back.
    private static func tran(_ a: DeimosAssets, _ priority: Int32) -> SoundCue {
        SoundPlay.perm(a.sounds[3], priority: priority, volume: 100, allowMultiple: true)
    }

    private static func fadeOut(_ s: FrontEndState) -> [RenderOp] {
        s.menuElements.fadeOut(rate: ElementList.fadeRate(floats: s.assets.floats), text: s.text, assets: s.assets)
    }

    /// The element fade-in `FUN_10025840` and the redraw `FUN_10024810(0)` of the menu's list.
    private static func fadeInRedraw(_ s: FrontEndState) -> [RenderOp] {
        s.menuElements.fadeIn(rate: ElementList.fadeRate(floats: s.assets.floats), text: s.text, assets: s.assets)
            + [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false)]
            + s.menuElements.drawOnce(restoreText: false, present: false, text: s.text, assets: s.assets)
            + [.present(.fullScreen)]
    }

    /// R1 when a game ran: the 33-step fade to black of the last game frame, `back`, the 9-step fade in.
    private static let gameFades: [RenderOp] = [.fade(.toBlack, .gameLayout)] + backBoth + [.fade(.fromBlack, .fullScreen)]

    /// 11b after R1 (`10023978..10023ae4`): `back`, a present, (`tran`), `back` again, fade-in, redraw.
    private static func menuOps(_ s: FrontEndState) -> [RenderOp] {
        backBoth + [.present(.fullScreen)] + backBoth + fadeInRedraw(s)
    }

    /// A state whose menu entry ran at 1,000 (the menu's element list built, as the menu leaves it before a call).
    private func menuState(_ a: DeimosAssets, prefs: DeimosPrefs = .fresh) throws -> FrontEndState {
        var s = try FrontEndState(assets: a, prefs: prefs)
        var menu = MainMenu()
        _ = menu.pass(keys: HeldKeys(), ticks: 1_000, returned: nil, state: &s)
        XCTAssertEqual(s.menuElements.count, 9, "the menu's list is built")
        return s
    }

    /// The real boot (Phase 4 S6 BT, `BootTests`): passes at `ticks` until the main menu is the top screen — six with
    /// fresh prefs, the configuration window's stub running inside the first — so the menu's entry runs at `ticks`,
    /// as the boot stub's single pass did. Returns the last pass's output (the boot's return chained into the menu's
    /// entry). Bound: 10 passes (G11).
    @discardableResult
    private func bootToMenu(_ fe: inout FrontEnd, ticks: UInt32) -> PassOutput {
        var out = fe.pass(keys: HeldKeys(), ticks: ticks)
        for _ in 1..<10 where fe.screens.last != .mainMenu { out = fe.pass(keys: HeldKeys(), ticks: ticks) }
        if fe.screens.last != .mainMenu { XCTFail("bound: the menu is not up within 10 boot passes") }
        return out
    }

    private func step(_ sr: inout StartReturn, _ s: inout FrontEndState, _ ticks: inout UInt32,
                      keys: HeldKeys = HeldKeys(), returned: ScreenResult? = nil) -> ScreenStep<StartReturn.Result> {
        let st = sr.pass(keys: keys, ticks: ticks, returned: returned, state: &s)
        ticks &+= 2
        return st
    }

    /// Play mode up to the level select's answer `sector`: the three start passes (the third calls the level select),
    /// then the pass it returns on. Returns that last step (the game's first pass when a sector was chosen).
    private func startPlay(_ sr: inout StartReturn, _ s: inout FrontEndState, _ ticks: inout UInt32,
                           sector: Int?) -> ScreenStep<StartReturn.Result> {
        for _ in 0..<2 { XCTAssertNil(step(&sr, &s, &ticks).callee) }
        XCTAssertEqual(step(&sr, &s, &ticks).callee, .levelSelect, "the third pass calls the level select")
        return step(&sr, &s, &ticks, returned: .levelSelect(sector))
    }

    /// Esc held until the game ends (pref 8 = 0: at once). Bound: 200 passes.
    @discardableResult
    private func escape(_ sr: inout StartReturn, _ s: inout FrontEndState, _ ticks: inout UInt32) -> Bool {
        for _ in 0..<200 {
            let st = step(&sr, &s, &ticks, keys: HeldKeys(held: [Self.escKey]))
            XCTAssertTrue(stays(st), "the game's passes stay")
            if st.output.sessionEnded { return true }
        }
        XCTFail("bound: Esc did not end the game within 200 passes")
        return false
    }

    private func stays(_ st: ScreenStep<StartReturn.Result>) -> Bool {
        if case .stay = st.next { return true }
        return false
    }

    private func entry(_ st: ScreenStep<StartReturn.Result>) -> NameEntry? {
        if case let .call(.nameEntry(e)) = st.next { return e }
        return nil
    }

    /// The bound on the passes from the level select's call to the game's first pass (its entry, the select, the
    /// accept flash's 16 frames, the pass that hands the sector back).
    private static let maxLevelSelectPasses = 40

    /// Through the real level select (S3b LS) inside a front end: passes until start/return has started a game,
    /// player 1's select key held on the level select's first live frame (the pass after the one that called it).
    /// Returns the game's first pass and the ticks it ran at; fails on the bound.
    private func throughLevelSelect(_ fe: inout FrontEnd, _ t: inout UInt32,
                                    _ label: String) -> (game: PassOutput, ticks: UInt32)? {
        let started = fe.state.gamesStarted
        let select = HeldKeys(held: [KeyTable(prefs: fe.state.prefs).codes[6]])   // Space
        var pressed = false
        for _ in 0..<Self.maxLevelSelectPasses {
            let live = fe.screens.last == .levelSelect && !pressed
            if live { pressed = true }
            let at = t
            let out = fe.pass(keys: live ? select : HeldKeys(), ticks: t)
            t += 2
            if fe.state.gamesStarted > started { return (out, at) }
        }
        XCTFail("\(label): bound: no game within \(Self.maxLevelSelectPasses) passes of the level select")
        return nil
    }

    // MARK: - The start

    /// B §1a through the front end: `1` on the menu flashes 1 PLAYER and calls start/return. Pass 1: the music
    /// paused, a full present, the cursor hidden, the menu's element fade-out (`10023518..10023558`). Pass 2: `tran`
    /// (0x4b, 100, 1) and the fade to black on full-screen presents (`1002355c..10023584`). Pass 3: the music stopped
    /// and `ammu` looped, and the level select's entry (S3b); player 1's select there chooses sector 1, and once the
    /// level select has left, the game — its first pass the bare session's with the music already playing, seeded with
    /// that pass's ticks. Two players reach the game too.
    func testStartSequence() throws {
        let a = try assets()
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        var t: UInt32 = 3_000
        bootToMenu(&fe, ticks: t)
        t += 2
        let flash = fe.pass(keys: Self.typeOne, ticks: t)
        t += 2
        XCTAssertTrue(flash.ops.contains(.hostWait(.ticks(10))), "1 flashes 1 PLAYER")
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn])
        let list = fe.state

        let one = fe.pass(keys: HeldKeys(), ticks: t)
        t += 2
        XCTAssertEqual(one.music, [.pause])
        XCTAssertEqual(one.sounds, [])
        XCTAssertEqual(one.requests, [.hideCursor])
        XCTAssertEqual(one.ops, [.present(.fullScreen)] + Self.fadeOut(list))
        XCTAssertEqual(fe.state.gamesStarted, 0)

        let two = fe.pass(keys: HeldKeys(), ticks: t)
        t += 2
        XCTAssertEqual(two.sounds, [Self.tran(a, 0x4b)])
        XCTAssertEqual(two.music, [])
        XCTAssertEqual(two.requests, [])
        XCTAssertEqual(two.ops, [.fade(.toBlack, .fullScreen)])
        XCTAssertEqual(fe.state.gamesStarted, 0)

        let three = fe.pass(keys: HeldKeys(), ticks: t)
        t += 2
        XCTAssertEqual(three.music, [.stop, .play(Self.ammu, loop: true)], "the music stopped, ammu looped")
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn, .levelSelect], "the third pass calls the level select")
        XCTAssertEqual(fe.state.gamesStarted, 0)
        let (first, at) = try XCTUnwrap(throughLevelSelect(&fe, &t, "1 PLAYER"))
        XCTAssertEqual(at, 3_044, "the game's pass: after the select, 15 flash frames and the exit (was 3_008)")
        XCTAssertEqual(fe.state.gamesStarted, 1)
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn])
        let start = SessionStart(sector: 1, players: 1, film: nil, musicAlreadyPlaying: true)
        XCTAssertEqual(fe.session?.start, start, "sector 1, one player, the music already playing")
        var bare = try DeimosSession(assets: a, prefs: .fresh, start: start, seed: at, ticks: at)
        let reference = bare.pass(keys: HeldKeys(), ticks: at)
        XCTAssertEqual(first.music, reference.music)
        XCTAssertFalse(reference.music.contains(.play(Self.ammu, loop: true)), "the game does not start ammu again")
        XCTAssertEqual(first.sounds, reference.sounds)
        XCTAssertEqual(first.ops, reference.ops)
        XCTAssertEqual(first.requests, [])
        XCTAssertEqual(fe.session?.rng, bare.rng)

        // 2 PLAYER: the same start; the game has both players.
        var s = try menuState(a)
        var sr = StartReturn(mode: .play, players: 2)
        var ticks: UInt32 = 5_000
        let game = startPlay(&sr, &s, &ticks, sector: 1)
        XCTAssertNil(game.callee)
        XCTAssertEqual(s.game?.session.start, SessionStart(sector: 1, players: 2, film: nil, musicAlreadyPlaying: true))
        XCTAssertEqual(s.game?.session.players.filter(\.inGame).count, 2)
    }

    // MARK: - The return

    /// B §1b after a game over, through the front end. The ending pass: the halt and the music stop, the Last Film
    /// saved. Not on the table: R1 — the fade to black of the last frame (game layout), `back`, the fade in; then
    /// `back`, a present, `tran` (0x32), `back`, the element fade-in, the redraw, the cursor shown, b6; the menu's first
    /// turn plays `inmu` from the start (the stream was stopped). On the table (P1 poked to 20,000): R1; `tran` and
    /// name entry for player 1 at row 0; Return, then a key; the cursor shown, `back`, the fade-in, the redraw, a full
    /// present; then a pass that flushes, sets b6 and returns. Bounds: 3,500 passes to the game over, 6 to the menu.
    func testReturnAfterGameOverSequence() throws {
        let a = try assets()
        for onTable in [false, true] {
            let label = onTable ? "on the table" : "not on the table"
            var fe = try FrontEnd(assets: a, prefs: .fresh)
            fe.state.recordedFilmForTests = [0xF1]
            var t: UInt32 = 7_000
            func pass(_ keys: HeldKeys = HeldKeys()) -> PassOutput {
                let out = fe.pass(keys: keys, ticks: t)
                t += 2
                return out
            }
            bootToMenu(&fe, ticks: t)
            t += 2
            _ = pass(Self.typeOne)
            XCTAssertNotNil(throughLevelSelect(&fe, &t, label), label)
            XCTAssertEqual(fe.state.gamesStarted, 1, label)
            if onTable { fe.session?.game.players[0].score = 20_000 }
            var ending: PassOutput?
            for _ in 0..<3_500 {
                let out = pass()
                if out.sessionEnded { ending = out; break }
            }
            let end = try XCTUnwrap(ending, "\(label): bound: no game over within 3,500 passes")
            let result = try XCTUnwrap(fe.session?.result)
            XCTAssertEqual(result.end, .gameOver, label)
            XCTAssertNotNil(end.haltEffectsAt, "\(label): the halt")
            XCTAssertEqual(end.music.last, .stop, "\(label): the music stop")
            XCTAssertEqual(end.requests, [.saveLastFilm([0xF1])], "\(label): the Last Film")
            let menu = fe.state

            let r1 = pass()
            XCTAssertEqual(r1.ops, Self.gameFades, label)
            XCTAssertEqual(r1.sounds, [], label)
            XCTAssertEqual(r1.music, [], label)
            XCTAssertEqual(r1.requests, [], label)
            XCTAssertEqual(fe.screens, [.mainMenu, .startReturn], label)

            if !onTable {
                XCTAssertLessThanOrEqual(result.scores[0], 1_000, "\(label): below the 15th row")
                let r2 = pass()
                XCTAssertEqual(r2.sounds, [Self.tran(a, 0x32)])
                XCTAssertEqual(r2.music, [])
                XCTAssertEqual(r2.ops, Self.menuOps(menu))
                XCTAssertEqual(r2.requests, [.showCursor])
            } else {
                let r2 = pass(HeldKeys(keyEvents: [KeyEvent(charCode: 0x41, keyCode: 0)]))
                XCTAssertEqual(fe.screens, [.mainMenu, .startReturn, .nameEntry])
                XCTAssertEqual(r2.sounds.first, Self.tran(a, 0x32), "tran, then name entry's silent gaso 9")
                XCTAssertEqual(r2.music, [])
                XCTAssertFalse(r2.ops.isEmpty, "name entry draws its table")
                XCTAssertFalse(r2.sounds.contains(SoundPlay.perm(a.sounds[0], priority: 0x32, volume: 100,
                                                                 allowMultiple: true)),
                               "the key queued before name entry was flushed (10023890): no letter typed")
                _ = pass(HeldKeys(keyEvents: [KeyEvent(charCode: 0x0d, keyCode: 0x24)]))   // Return
                t += 30                                                                    // past F79 = 25 ticks
                let left = pass()
                XCTAssertEqual(left.ops, [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false),
                                          .present(.fullScreen)], "name entry leaves")
                XCTAssertEqual(fe.state.prefs.highScores[0], result.scores[0])
                XCTAssertEqual(fe.state.prefs.highScoreNames[0], "Player 1")
                let r3 = pass()
                XCTAssertEqual(r3.requests, [.showCursor])
                XCTAssertEqual(r3.sounds, [])
                XCTAssertEqual(r3.music, [])
                XCTAssertEqual(r3.ops, Self.backBoth + Self.fadeInRedraw(menu) + [.present(.fullScreen)])
                XCTAssertEqual(fe.screens, [.mainMenu, .startReturn])
                XCTAssertFalse(fe.state.menuMusic, "b6 waits for the last FlushEvents")
                let r4 = pass(Self.typeOne)
                XCTAssertEqual(r4, PassOutput(), "the flush pass, then the menu's return step")
                XCTAssertEqual(fe.screens, [.mainMenu])
                XCTAssertTrue(fe.state.menuMusic)
            }
            XCTAssertEqual(fe.screens, [.mainMenu], label)
            XCTAssertTrue(fe.state.menuMusic, "\(label): b6")
            XCTAssertFalse(fe.state.musicAlive, "\(label): the game stopped the stream")
            var music: [MusicCue] = []
            for _ in 0..<3 where music.isEmpty { music = pass().music }
            XCTAssertEqual(music, [.play(Self.inmu, loop: true)], "\(label): inmu from the start")
            XCTAssertEqual(fe.state.gamesStarted, 1, "\(label): the flushed 1 started nothing")
        }
    }

    /// Esc does not set the quit flag (`10023674` reads b8 only): an Esc-ended game with 20,000 reaches the gates and
    /// the table — name entry for player 1 at row 0, over the inserted copy (20,000, "Player 1", le07's name).
    func testEscStillEntersHighScores() throws {
        let a = try assets()
        var s = try menuState(a)
        var sr = StartReturn(mode: .play, players: 1)
        var t: UInt32 = 9_000
        _ = startPlay(&sr, &s, &t, sector: 1)
        s.game?.session.game.players[0].score = 20_000
        escape(&sr, &s, &t)
        XCTAssertEqual(s.game?.session.result?.end, .escape)
        XCTAssertFalse(s.quit)
        let r1 = step(&sr, &s, &t)
        XCTAssertEqual(r1.output.ops, Self.gameFades)
        XCTAssertNil(r1.callee)
        let r2 = step(&sr, &s, &t)
        XCTAssertEqual(r2.output.sounds, [Self.tran(a, 0x32)])
        XCTAssertEqual(r2.output.ops, [])
        let e = try XCTUnwrap(entry(r2), "name entry: \(String(describing: r2.callee))")
        XCTAssertEqual(e.player, 0)
        XCTAssertEqual(e.slot, 0)
        XCTAssertNil(e.player2Slot)
        XCTAssertTrue(e.fromGame)
        XCTAssertEqual(e.prefs.highScores[0], 20_000)
        XCTAssertEqual(e.prefs.highScores[1], 15_000, "the old first row moves down")
        XCTAssertEqual(e.prefs.highScoreNames[0], "Player 1")
        XCTAssertEqual(e.prefs.highScoreSectorNames[0], a.definitions.levels.first { $0.id == FourCC("le07")! }?.name)
        XCTAssertEqual(s.prefs.intPrefs[3], 1, "best 1 − 1, at least 1: pref 3 stays")
    }

    /// INDEX #54: a film keeps the menu music. Through the front end's `-film` path (the menu plays it as DEMOS does):
    /// the start pauses nothing and hides no cursor (D13); `tran` (0x4b) and the fade to black; the film; Esc. The
    /// return: no `tran`, no b6, the whole of 11b in R1's pass — the fade to black, `back`, the fade in, `back`, a
    /// present, `back`, the fade-in, the redraw, the cursor shown — and no music cue from start to the menu's turns
    /// after (the film session's own engine level aside). A film that fails to load: the same return, result zero.
    /// Bounds: 200 passes for Esc, 5 menu passes after.
    func testFilmReturnKeepsMenuMusic() throws {
        let a = try assets()
        let index = try RealData.index()
        let film = try Film(data: index.data(for: XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC("de01")!))))
        var fe = try FrontEnd(assets: a, prefs: .fresh, film: film)
        var t: UInt32 = 11_000
        var outs: [PassOutput] = []
        func pass(_ keys: HeldKeys = HeldKeys()) -> PassOutput {
            let out = fe.pass(keys: keys, ticks: t)
            t += 2
            outs.append(out)
            return out
        }
        outs.append(bootToMenu(&fe, ticks: t))
        t += 2
        let list = fe.state
        let one = pass()
        XCTAssertEqual(fe.screens, [.mainMenu, .startReturn])
        XCTAssertEqual(one.ops, [.present(.fullScreen)] + Self.fadeOut(list))
        XCTAssertEqual(one.requests, [], "a film keeps the cursor (D13)")
        XCTAssertEqual(one.music, [], "a film pauses nothing")
        let two = pass()
        XCTAssertEqual(two.sounds, [Self.tran(a, 0x4b)])
        XCTAssertEqual(two.ops, [.fade(.toBlack, .fullScreen)])
        var ended = false
        for _ in 0..<200 where !ended { ended = pass(HeldKeys(held: [Self.escKey])).sessionEnded }
        XCTAssertTrue(ended, "bound: the film did not end within 200 passes")
        XCTAssertEqual(fe.session?.result?.isFilm, true)
        let back = pass()
        XCTAssertEqual(back.ops, Self.gameFades + Self.menuOps(list))
        XCTAssertEqual(back.sounds, [], "no tran")
        XCTAssertEqual(back.requests, [.showCursor])
        XCTAssertEqual(fe.screens, [.mainMenu])
        XCTAssertFalse(fe.state.menuMusic, "no b6")
        for _ in 0..<5 { _ = pass() }
        XCTAssertEqual(outs.flatMap(\.music).filter { if case .level = $0 { false } else { true } }, [],
                       "no stop, play, pause or resume: inmu plays on")
        XCTAssertEqual(fe.state.gamesStarted, 1)

        // The film that fails to load (`100056dc..100056f0`): no game; fades 33 + 9 and the menu, no tran, no b6. A
        // film whose game cannot be built (prefs one byte short; no original counterpart) returns the same.
        for unbuildable in [false, true] {
            let label = unbuildable ? "a film game that cannot be built" : "no film"
            var s = try menuState(a)
            if unbuildable { s.prefs.bytePrefs.removeLast() }
            var sr = unbuildable ? StartReturn(mode: .demo, players: 1, film: film)
                                 : StartReturn(mode: .lastFilm, players: 1, film: nil)
            var ticks: UInt32 = 13_000
            _ = step(&sr, &s, &ticks)
            _ = step(&sr, &s, &ticks)
            let failed = step(&sr, &s, &ticks)
            let zero: SessionResult? = .filmLoadFailed(startSector: 0)
            XCTAssertEqual(failed.finished, zero, label)
            XCTAssertEqual(failed.output.ops, Self.gameFades + Self.menuOps(s), label)
            XCTAssertEqual(failed.output.sounds, [], label)
            XCTAssertEqual(failed.output.music, [], label)
            XCTAssertEqual(failed.output.requests, [.showCursor], label)
            XCTAssertNil(s.game, "\(label): no game ran")
            XCTAssertFalse(s.menuMusic, label)
        }
    }

    /// The level select cancelled (`none`, r26 = 0; `10023768..10023774`, `1002377c`): no game, no gates; the music
    /// (`ammu`) stopped; no fade to black — `back` and the 9-step fade in; then 11b with `tran` and b6, so the menu's
    /// next turn restarts `inmu`. Returns nil. The menu's lit button (2 here) stays lit through R1 and is unlit by 11b
    /// (`FUN_10024a00(0)`, before the fade-in). A play game that cannot be built (prefs one byte short; no original
    /// counterpart) returns exactly as the cancel does.
    func testCancelledLevelSelectNoFadeOut() throws {
        let a = try assets()
        for unbuildable in [false, true] {
            let label = unbuildable ? "a game that cannot be built" : "cancelled"
            var s = try menuState(a)
            s.prefs.intPrefs[3] = 4
            s.menuLit = 2
            if unbuildable { s.prefs.bytePrefs.removeLast() }
            var sr = StartReturn(mode: .play, players: 1)
            var t: UInt32 = 15_000
            let r1 = startPlay(&sr, &s, &t, sector: unbuildable ? 1 : nil)
            XCTAssertNil(r1.callee, label)
            XCTAssertTrue(stays(r1), "\(label): the return goes on")
            XCTAssertEqual(r1.output.music, [.stop], label)
            XCTAssertEqual(r1.output.sounds, [], label)
            XCTAssertEqual(r1.output.ops, Self.backBoth + [.fade(.fromBlack, .fullScreen)], "\(label): no fade to black")
            XCTAssertEqual(r1.output.requests, [], label)
            XCTAssertNil(s.game, "\(label): no game ran")
            XCTAssertEqual(s.menuLit, 2, "\(label): R1 unlights nothing")
            let r2 = step(&sr, &s, &t)
            guard case .finish(nil) = r2.next else { return XCTFail("\(label): returns nil: \(r2.next)") }
            XCTAssertEqual(r2.output.sounds, [Self.tran(a, 0x32)], label)
            XCTAssertEqual(r2.output.ops, Self.menuOps(s), label)
            XCTAssertEqual(r2.output.requests, [.showCursor], label)
            XCTAssertNil(s.menuLit, "\(label): 11b unlights every button")
            XCTAssertTrue(s.menuMusic, "\(label): b6: inmu restarts")
            XCTAssertEqual(s.prefs.intPrefs[3], 4, "\(label): no gates")
        }
    }

    /// The finale (G+0x0d) from a sector-1 start (the level select's 1; the running game then set to the last sector
    /// by FinaleTests' recipe): best = le09's sector 12 with no −1 → pref 3 = 12 (`10023710`); R1's fade to black,
    /// `back` and fade in; no credits; nobody on a table of maximal scores → 11b. Bound: 3,000 passes.
    func testFinaleSetsBestSectorTwelve() throws {
        let a = try assets()
        var prefs = DeimosPrefs.fresh
        prefs.highScores = Array(repeating: Int32.max, count: HighScoreTable.rowCount)
        var s = try menuState(a, prefs: prefs)
        var sr = StartReturn(mode: .play, players: 1)
        var t: UInt32 = 17_000
        _ = startPlay(&sr, &s, &t, sector: 1)
        var last = try DeimosSession(assets: a, prefs: s.prefs, start: SessionStart(sector: 12, players: 1, film: nil),
                                     seed: 0x469c2)
        last.game.flags.levelsStarted = 12
        last.game.setInvulnerable(0, true, sticky: true)
        last.game.scroll.window.top = 250
        last.game.scroll.window.bottom = 730
        last.game.scroll.progress = 3351
        s.game?.session = last
        var ended = false
        for _ in 0..<3_000 where !ended { ended = step(&sr, &s, &t).output.sessionEnded }
        XCTAssertTrue(ended, "bound: no finale within 3,000 passes")
        let result = try XCTUnwrap(s.game?.session.result)
        XCTAssertEqual(result.end, .finale)
        XCTAssertTrue(result.allLevels)
        XCTAssertEqual(result.levels[0], FourCC("le09"))
        XCTAssertGreaterThan(result.scores[0], 0)
        XCTAssertEqual(s.prefs.intPrefs[3], 1)
        let r1 = step(&sr, &s, &t)
        XCTAssertEqual(s.prefs.intPrefs[3], 12, "best 12, no −1")
        XCTAssertEqual(r1.output.ops, Self.gameFades)
        XCTAssertNil(r1.callee, "no credits")
        let r2 = step(&sr, &s, &t)
        XCTAssertNil(r2.callee, "no table")
        XCTAssertEqual(r2.finished, .some(result))
        XCTAssertEqual(r2.output.sounds, [Self.tran(a, 0x32)])
    }

    /// B §1d / §8 as one table (`10023674..10023764`, `1002383c..1002386c`; HighScoreTable over the fresh rows 15,000 …
    /// 1,000). Each row: the level select's sector, both players' scores and sectors (poked just before Esc), a cheat,
    /// the quit flag, pref 3 before; then pref 3 after and the name entry called (player, row, player 2's row) or none.
    /// The worked example is `loose-ends-session.md`'s (B §8): P1 at le02 (sector 3) with 12,500, P2 at le06 (sector 2)
    /// with 600 → best 3, pref 3 = 2, P1 alone at row 3. Starts at sector 1 and 2 pin r25's "above 1" (`100235dc`).
    func testPostGameGatesTable() throws {
        let a = try assets()
        XCTAssertEqual(a.levelOrder.level(sector: 3), FourCC("le02"))
        XCTAssertEqual(a.levelOrder.level(sector: 2), FourCC("le06"))
        struct Row {
            var label: String
            var start = 1
            var players = 2
            var scores: [Int32]
            var sectors: [Int]
            var cheat = false
            var quit = false
            var pref3: Int32 = 1
            var wantPref3: Int32
            var wantEntry: (player: Int, slot: Int, slot2: Int?)?
        }
        let rows = [
            Row(label: "best minus one (P2's 0 not counted)", scores: [12_500, 0], sectors: [3, 5], wantPref3: 2,
                wantEntry: (0, 3, nil)),
            Row(label: "the worked example (P1 le02 12,500, P2 le06 600)", scores: [12_500, 600], sectors: [3, 2],
                wantPref3: 2, wantEntry: (0, 3, nil)),
            Row(label: "both on the table", scores: [12_500, 8_000], sectors: [3, 5], wantPref3: 4,
                wantEntry: (0, 3, 9)),
            Row(label: "player 2 alone", scores: [0, 8_000], sectors: [6, 2], wantPref3: 1, wantEntry: (1, 8, nil)),
            Row(label: "one player, at least 1", players: 1, scores: [1_500, 0], sectors: [1, 1], wantPref3: 1,
                wantEntry: (0, 14, nil)),
            Row(label: "pref 3 already higher", scores: [12_500, 0], sectors: [3, 5], pref3: 9, wantPref3: 9,
                wantEntry: (0, 3, nil)),
            Row(label: "a later start writes no pref and no table", start: 3, scores: [12_500, 0], sectors: [7, 5],
                wantPref3: 1, wantEntry: nil),
            Row(label: "sector 2 is already a later start (r25: above 1)", start: 2, scores: [12_500, 0],
                sectors: [7, 5], wantPref3: 1, wantEntry: nil),
            Row(label: "a cheat skips the gates", scores: [12_500, 0], sectors: [3, 5], cheat: true, wantPref3: 1,
                wantEntry: nil),
            Row(label: "the quit flag skips the gates", scores: [12_500, 0], sectors: [3, 5], quit: true, wantPref3: 1,
                wantEntry: nil),
            Row(label: "below the 15th row", scores: [1_000, 0], sectors: [4, 5], wantPref3: 3, wantEntry: nil),
        ]
        var t: UInt32 = 20_000
        for row in rows {
            var prefs = DeimosPrefs.fresh
            prefs.intPrefs[3] = row.pref3
            var s = try menuState(a, prefs: prefs)
            var sr = StartReturn(mode: .play, players: row.players)
            _ = startPlay(&sr, &s, &t, sector: row.start)
            XCTAssertEqual(s.game?.session.sector, row.start, row.label)
            for p in 0..<2 {
                s.game?.session.game.players[p].levelRef = a.levelOrder.level(sector: row.sectors[p])
                s.game?.session.game.players[p].score = row.scores[p]
            }
            if row.cheat { s.game?.session.game.players[0].cheated = true }
            s.quit = row.quit
            escape(&sr, &s, &t)
            let result = try XCTUnwrap(s.game?.session.result, row.label)
            XCTAssertEqual(result.scores, row.scores, "\(row.label): the scores as poked")
            let r1 = step(&sr, &s, &t)
            XCTAssertEqual(r1.output.ops, Self.gameFades, row.label)
            XCTAssertEqual(s.prefs.intPrefs[3], row.wantPref3, "\(row.label): pref 3")
            let r2 = step(&sr, &s, &t)
            XCTAssertEqual(r2.output.sounds, [Self.tran(a, 0x32)], row.label)
            if let want = row.wantEntry {
                let e = try XCTUnwrap(entry(r2), "\(row.label): name entry: \(String(describing: r2.callee))")
                XCTAssertEqual(e.player, want.player, row.label)
                XCTAssertEqual(e.slot, want.slot, row.label)
                XCTAssertEqual(e.player2Slot, want.slot2, row.label)
                XCTAssertEqual(e.prefs, HighScoreTable.insert(result, into: s.prefs, assets: a).prefs,
                               "\(row.label): the inserted copy A")
            } else {
                XCTAssertNil(r2.callee, row.label)
                XCTAssertEqual(r2.finished, .some(result), "\(row.label): 11b returns")
                XCTAssertEqual(s.prefs.highScores, DeimosPrefs.fresh.highScores, "\(row.label): no table")
            }
        }
    }
}

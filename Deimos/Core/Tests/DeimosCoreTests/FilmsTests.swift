import XCTest
import HectorResources
@testable import DeimosCore

/// The films from the menu and how a film ends (Phase 4 S5 DM; grounding B §3, §4b): the demo choice
/// `FUN_100069b0` mode 2 (dump `4157..4215`) over the tag index's `film` records whose name holds "Demo", by the
/// counter G+0x24 (`FrontEndState.demoCounter`, never reset by a game); `F` = mode 1 = tag `last`; a film ends after
/// the draw on the mouse button (`10005a24` `FUN_10048e60` = `Button()`, live state) or its recording running out
/// (`10005a38`), then `FUN_100064c0` (`10005a48`: G+0x08 = 0 and nothing else); Esc ends it in the begin frame
/// (`10005904`); no other key does. A film skips the session end's halt and stop (`10005ad0`, r21 = film).
final class FilmsTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }
    private struct NoCall: Error {}

    private static func shipped(_ id: String) throws -> Film {
        let index = try RealData.index()
        let record = try XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC(id)!), "film \(id)")
        return try Film(data: index.data(for: record))
    }

    /// One whole run of the films screen: its first pass calls start/return with the film it chose; handed
    /// start/return's result, it returns to its caller.
    private static func play(_ kind: Films.Kind, _ s: inout FrontEndState) throws -> StartReturn {
        var f = Films(kind: kind)
        let first = f.pass(keys: HeldKeys(), ticks: 100, returned: nil, state: &s)
        guard case let .call(.startReturn(sr)) = first.next else {
            XCTFail("the films screen calls start/return first")
            throw NoCall()
        }
        let back = f.pass(keys: HeldKeys(), ticks: 200, returned: .startReturn(nil), state: &s)
        XCTAssertNotNil(back.finished, "start/return's return ends the films screen")
        return sr
    }

    /// The passes from the menu key to the game's first pass: start/return's start sequence (3), and in play mode the
    /// level select's entry, select, accept flash and hand-back (about 18 more).
    private static let maxStartPasses = 60

    /// One menu key through the real front end (boot → menu, S2; start/return, S3a; the level select, S3b): the key
    /// typed on the menu, passes until start/return has started its game — player 1's select key held on the level
    /// select's first live frame, when there is one (bound `maxStartPasses`) — Esc held until that game ends (bound
    /// 400), passes until the menu is the top screen again (bound 10), then the menu's own return step. Returns the
    /// game's start.
    private func fromMenu(_ fe: inout FrontEnd, _ charCode: UInt8, ticks: inout UInt32,
                          _ label: String) throws -> SessionStart {
        XCTAssertEqual(fe.screens, [.mainMenu], "\(label): the menu is up")
        let started = fe.state.gamesStarted
        _ = fe.pass(keys: HeldKeys(keyEvents: [KeyEvent(charCode: charCode, keyCode: 0)]), ticks: ticks)
        ticks &+= 2
        let select = HeldKeys(held: [KeyTable(prefs: fe.state.prefs).codes[6]])   // Space
        var pressed = false
        for _ in 0..<Self.maxStartPasses where fe.state.gamesStarted == started {
            let live = fe.screens.last == .levelSelect && !pressed
            if live { pressed = true }
            _ = fe.pass(keys: live ? select : HeldKeys(), ticks: ticks)
            ticks &+= 2
        }
        XCTAssertEqual(fe.state.gamesStarted, started + 1,
                       "\(label): bound: no game within \(Self.maxStartPasses) passes")
        let start = try XCTUnwrap(fe.session?.start, label)
        for _ in 0..<400 where fe.session?.running ?? false {
            _ = fe.pass(keys: HeldKeys(held: [FrameKeys.escKey]), ticks: ticks)
            ticks &+= 2
        }
        XCTAssertEqual(fe.session?.running, false, "\(label): bound: the game did not end within 400 passes")
        for _ in 0..<10 where fe.screens != [.mainMenu] {
            _ = fe.pass(keys: HeldKeys(), ticks: ticks)
            ticks &+= 2
        }
        XCTAssertEqual(fe.screens, [.mainMenu], "\(label): bound: not back on the menu within 10 passes")
        _ = fe.pass(keys: HeldKeys(), ticks: ticks)
        ticks &+= 2
        return start
    }

    /// DEMOS / `D` play de01 (le07), de02 (le06), de03 (le02), de04 (le08), then de01 again — Game.pak's zip order,
    /// the only `film` names holding "Demo" (Local's `Last Film` does not). Position = G+0x24, then +1; none at that
    /// position → 0, the first, 1. All through the real front end from the menu: `D` twice, a normal game (`1`, then
    /// Esc) that leaves the counter alone (the session reset `10005500..1000555c` does not store G+0x24, and nothing
    /// on start/return's way out or back touches it), `D`, `F` (that game's recording, held in memory; the counter
    /// stands), then `D` twice more to the wrap.
    func testDemoCycleOrderAndWrap() throws {
        let a = try assets()
        var fe = try FrontEnd(assets: a, prefs: .fresh)
        var ticks: UInt32 = 5_000
        _ = fe.pass(keys: HeldKeys(), ticks: ticks)
        ticks &+= 2
        XCTAssertEqual(fe.state.demoCounter, 0, "the first demo after launch is de01")
        let D: UInt8 = 0x44, F: UInt8 = 0x46, one: UInt8 = 0x31

        func demo(_ i: Int, _ id: String, _ level: String, counter: Int) throws {
            let start = try fromMenu(&fe, D, ticks: &ticks, "demo \(i)")
            let film = try XCTUnwrap(start.film, "demo \(i): a film was played")
            XCTAssertEqual(film, try Self.shipped(id), "demo \(i) is \(id)")
            XCTAssertEqual(film.level, FourCC(level), "demo \(i)'s level")
            XCTAssertEqual(fe.session?.result?.isFilm, true, "demo \(i)")
            XCTAssertEqual(fe.state.demoCounter, counter, "the counter after demo \(i)")
        }
        try demo(0, "de01", "le07", counter: 1)
        try demo(1, "de02", "le06", counter: 2)

        // A normal game between two demos (1 PLAYER: level select, sector 1, ended by Esc): the counter stands.
        let game = try fromMenu(&fe, one, ticks: &ticks, "the game")
        XCTAssertNil(game.film)
        XCTAssertEqual(fe.session?.result?.end, .escape)
        XCTAssertEqual(fe.session?.result?.isFilm, false)
        XCTAssertEqual(fe.state.demoCounter, 2, "a game does not reset the demo counter")
        XCTAssertFalse(fe.state.lastFilm.isEmpty, "the normal game recorded a Last Film")
        let recorded = try Film(data: Data(fe.state.lastFilm))

        try demo(2, "de03", "le02", counter: 3)

        // `F` plays that game's recording, held in memory, and leaves the counter.
        let last = try fromMenu(&fe, F, ticks: &ticks, "F")
        XCTAssertEqual(last.film, recorded)
        XCTAssertEqual(last.film?.level, FourCC("le07"))
        XCTAssertEqual(fe.session?.result?.isFilm, true)
        XCTAssertEqual(fe.state.demoCounter, 3)

        try demo(3, "de04", "le08", counter: 4)
        try demo(4, "de01", "le07", counter: 1)

        // The films screen alone: with no game recorded yet, `F` plays the index's `last` (the shipped copy of de01);
        // a recording that does not decode hands start/return no film (its result is then the load failure).
        var fresh = try FrontEndState(assets: a, prefs: .fresh)
        XCTAssertEqual(try Self.play(.lastFilm, &fresh).mode, .lastFilm)
        XCTAssertEqual(try Self.play(.lastFilm, &fresh).film, try Self.shipped("last"))
        XCTAssertEqual(fresh.demoCounter, 0)
        fresh.lastFilm = [1, 2, 3]
        XCTAssertNil(try Self.play(.lastFilm, &fresh).film)
    }

    /// The mouse button, held at a film pass, ends the film in that pass (`10005a24..10005a30` → `10005a48`): the
    /// pass still ticks and draws, the end is the film's own (`.filmEnded`), and there is no halt and no `.stop`
    /// (`10005ad0`: a film skips them; `FUN_100064c0` only clears G+0x08). A normal game ignores the button
    /// (`10005a1c`: the check is film-only).
    func testMouseButtonEndsFilm() throws {
        let a = try assets()
        var s = try DeimosSession(assets: a, prefs: .fresh,
                                  start: SessionStart(sector: 1, players: 1, film: Self.shipped("de01")), seed: 0)
        let warm = 300
        for p in 0..<warm {
            let out = s.pass(keys: HeldKeys(), ticks: UInt32(p))
            XCTAssertFalse(out.sessionEnded, "pass \(p): de01 runs past \(warm) passes")
        }
        XCTAssertTrue(s.running)
        let out = s.pass(keys: HeldKeys(mouseButton: true), ticks: UInt32(warm))
        XCTAssertTrue(out.sessionEnded, "the mouse button ends the film in that pass")
        XCTAssertFalse(s.running)
        XCTAssertTrue(out.ticked, "the pass ticked before the check")
        XCTAssertFalse(out.ops.isEmpty, "the pass drew")
        XCTAssertEqual(s.result?.end, .filmEnded)
        XCTAssertEqual(s.result?.isFilm, true)
        XCTAssertFalse(out.music.contains(.stop), "no music stop for a film")
        XCTAssertNil(out.haltEffectsAt, "no halt for a film")
        XCTAssertEqual(s.pass(keys: HeldKeys(), ticks: UInt32(warm + 1)), PassOutput(sessionEnded: true))

        var game = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                     seed: 0x469c2)
        for p in 0..<100 {
            let o = game.pass(keys: HeldKeys(mouseButton: true), ticks: UInt32(p))
            XCTAssertFalse(o.sessionEnded, "pass \(p): the mouse button does not end a game")
        }
        XCTAssertTrue(game.running)
    }

    /// No key but Esc ends a film: every other key code held, Caps Lock down, typed characters, key events and
    /// mouse-down events queued with the button up (the session reads `Button()`'s live state only), pass after
    /// pass — the film runs on, and never pauses (B §3: the Caps Lock pause is refused in a film, `10030408..1003041c`:
    /// no pause wait, no music pause, no halt). Bound: 400 passes (de01 runs 4,809 recorded ticks).
    func testKeysDoNotEndFilm() throws {
        var s = try DeimosSession(assets: assets(), prefs: .fresh,
                                  start: SessionStart(sector: 1, players: 1, film: Self.shipped("de01")), seed: 0)
        var every = Set<UInt16>(0..<0x80)
        every.remove(FrameKeys.escKey)
        let keys = HeldKeys(held: every, capsLock: true, typed: [0x61, 0x1b, 0x0d],
                            mouse: MousePoint(h: 320, v: 240), mouseButton: false, mouseDowns: [MousePoint(h: 320, v: 240)],
                            keyEvents: [KeyEvent(charCode: 0x61, keyCode: 0x00)])
        let bound = 400
        for p in 0..<bound {
            let out = s.pass(keys: keys, ticks: UInt32(p))
            XCTAssertFalse(out.sessionEnded, "pass \(p): a key other than Esc ended the film")
            XCTAssertFalse(out.ops.contains { if case .pauseWait = $0 { true } else { false } },
                           "pass \(p): Caps Lock paused the film")
            XCTAssertFalse(out.music.contains(.pause), "pass \(p): Caps Lock paused the music")
            XCTAssertNil(out.haltEffectsAt, "pass \(p): no halt")
            if out.sessionEnded { break }
        }
        XCTAssertTrue(s.running)
        XCTAssertNil(s.result)
    }

    /// Esc ends a film in the begin frame (`10005904` → `1000591c`, not film-gated): `.escape`, and still no halt and
    /// no `.stop` (`10005ad0`).
    func testEscEndsFilm() throws {
        var s = try DeimosSession(assets: assets(), prefs: .fresh,
                                  start: SessionStart(sector: 1, players: 1, film: Self.shipped("de01")), seed: 0)
        let warm = 300
        for p in 0..<warm {
            let out = s.pass(keys: HeldKeys(), ticks: UInt32(p))
            XCTAssertFalse(out.sessionEnded, "pass \(p): de01 runs past \(warm) passes")
        }
        let out = s.pass(keys: HeldKeys(held: [FrameKeys.escKey]), ticks: UInt32(warm))
        XCTAssertTrue(out.sessionEnded, "Esc ends the film in that pass")
        XCTAssertEqual(s.result?.end, .escape)
        XCTAssertEqual(s.result?.isFilm, true)
        XCTAssertFalse(out.music.contains(.stop))
        XCTAssertNil(out.haltEffectsAt)
    }
}

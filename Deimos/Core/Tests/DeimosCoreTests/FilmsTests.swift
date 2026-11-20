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

    /// DEMOS / `D` play de01 (le07), de02 (le06), de03 (le02), de04 (le08), then de01 again — Game.pak's zip order,
    /// the only `film` names holding "Demo" (Local's `Last Film` does not). Position = G+0x24, then +1; none at that
    /// position → 0, the first, 1. A normal game between two demos leaves the counter alone (the session reset
    /// `10005500..1000555c` does not store G+0x24).
    func testDemoCycleOrderAndWrap() throws {
        let a = try assets()
        var s = try FrontEndState(assets: a, prefs: .fresh)
        XCTAssertEqual(s.demoCounter, 0, "the first demo after launch is de01")
        let order = ["de01", "de02", "de03", "de04", "de01"]
        let levels = ["le07", "le06", "le02", "le08", "le07"]
        let counters = [1, 2, 3, 4, 1]
        for (i, id) in order.enumerated() {
            let sr = try Self.play(.demo, &s)
            XCTAssertEqual(sr.mode, .demo, "demo \(i)")
            XCTAssertEqual(sr.players, 1, "demo \(i)")
            let film = try XCTUnwrap(sr.film, "demo \(i): a film was chosen")
            XCTAssertEqual(film, try Self.shipped(id), "demo \(i) is \(id)")
            XCTAssertEqual(film.level, FourCC(levels[i]), "demo \(i)'s level")
            XCTAssertEqual(s.demoCounter, counters[i], "the counter after demo \(i)")

            if i == 1 {
                // A normal game between two demos (one player, sector 1, ended by Esc): the counter stands.
                try s.startGame(SessionStart(sector: 1, players: 1, film: nil), ticks: 300)
                let bound = 400
                var passes = 0
                while s.gameRunning {
                    if passes >= bound { return XCTFail("bound \(bound) game passes reached") }
                    let held: Set<UInt16> = passes >= 200 ? [FrameKeys.escKey] : []
                    _ = s.gamePass(keys: HeldKeys(held: held), ticks: 300 + UInt32(passes))
                    passes += 1
                }
                XCTAssertEqual(s.game?.session.result?.end, .escape)
                XCTAssertEqual(s.game?.session.result?.isFilm, false)
                XCTAssertEqual(s.demoCounter, 2, "a game does not reset the demo counter")
            }
        }

        // `F` after that game plays its recording, held in memory (the game's seed is its first pass's TickCount),
        // and leaves the counter.
        XCTAssertFalse(s.lastFilm.isEmpty, "the normal game recorded a Last Film")
        let last = try Self.play(.lastFilm, &s)
        XCTAssertEqual(last.mode, .lastFilm)
        XCTAssertEqual(last.players, 1)
        let replay = try XCTUnwrap(last.film)
        XCTAssertEqual(replay, try Film(data: Data(s.lastFilm)))
        XCTAssertEqual(replay.seed, 300)
        XCTAssertEqual(replay.level, FourCC("le07"))
        XCTAssertEqual(s.demoCounter, 1)
        // With no game recorded yet, `F` plays the index's `last` (the shipped copy of de01).
        var fresh = try FrontEndState(assets: a, prefs: .fresh)
        XCTAssertEqual(try Self.play(.lastFilm, &fresh).film, try Self.shipped("last"))
        XCTAssertEqual(fresh.demoCounter, 0)
        // A recording that does not decode: start/return is handed no film (its result is then the load failure).
        s.lastFilm = [1, 2, 3]
        XCTAssertNil(try Self.play(.lastFilm, &s).film)
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

    /// No key but Esc ends a film: every other key code held, typed characters, key events and mouse-down events
    /// queued with the button up (the session reads `Button()`'s live state only), pass after pass — the film runs
    /// on. Bound: 400 passes (de01 runs 4,809 recorded ticks).
    func testKeysDoNotEndFilm() throws {
        var s = try DeimosSession(assets: assets(), prefs: .fresh,
                                  start: SessionStart(sector: 1, players: 1, film: Self.shipped("de01")), seed: 0)
        var every = Set<UInt16>(0..<0x80)
        every.remove(FrameKeys.escKey)
        let keys = HeldKeys(held: every, typed: [0x61, 0x1b, 0x0d], mouse: MousePoint(h: 320, v: 240),
                            mouseButton: false, mouseDowns: [MousePoint(h: 320, v: 240)],
                            keyEvents: [KeyEvent(charCode: 0x61, keyCode: 0x00)])
        let bound = 400
        for p in 0..<bound {
            let out = s.pass(keys: keys, ticks: UInt32(p))
            XCTAssertFalse(out.sessionEnded, "pass \(p): a key other than Esc ended the film")
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

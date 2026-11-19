import XCTest
import HectorResources
@testable import DeimosCore

/// Phase 4 SK-a — `SessionResult` (plan S1a; grounding B §1c; listing `10005b38..10005c18`): built by the pass that
/// ends the session and carried by it; the ended session keeps it.
final class SessionResultTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let escKey: UInt16 = 0x35

    /// Holds Esc until the session ends (pref 8 may ask for a 16-frame hold, timing-frame §2.5); returns the ending
    /// pass. Bound: 200 passes.
    private func escape(_ s: inout DeimosSession) -> PassOutput? {
        for _ in 0..<200 {
            let out = s.pass(keys: HeldKeys(held: [Self.escKey]), ticks: 0)
            if out.sessionEnded { return out }
            XCTAssertNil(out.result, "only the ending pass carries the result")
        }
        XCTFail("bound: Esc did not end the session within 200 passes")
        return nil
    }

    /// One player, Esc after 100 passes: both slots present (`FUN_10026c90` reads +0xcc, which the set-up writes for
    /// both players, `10026438`), P1's decoded score and level, P2's score 0 and level `none` (never level-started,
    /// `100269c4`), no film, sector 1. The ending pass carries it; a later empty pass does not, the session keeps it.
    func testSessionResultOnePlayerBothSlotsPresent() throws {
        var s = try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                  seed: 0x469c2)
        for _ in 0..<100 { _ = s.pass(keys: HeldKeys(), ticks: 0) }
        XCTAssertNil(s.result, "no result while the session runs")
        s.game.players[0].score = 4321          // poke a non-zero score so the slot's value is seen
        guard let out = escape(&s) else { return }
        let r = try XCTUnwrap(out.result)
        XCTAssertEqual(r.end, .escape)
        XCTAssertFalse(r.isFilm)
        XCTAssertEqual(r.startSector, 1)
        XCTAssertEqual(r.present, [true, true], "both slots present in a one-player game")
        XCTAssertEqual(r.scores, [4321, 0])
        XCTAssertEqual(r.levels, [FourCC("le07")!, .none])
        XCTAssertFalse(r.allLevels)
        XCTAssertFalse(r.cheated)
        XCTAssertEqual(r.recordedFilm, [], "empty until the recorder lands (S5)")
        XCTAssertEqual(s.result, r)

        let after = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertTrue(after.sessionEnded)
        XCTAssertNil(after.result)
        XCTAssertEqual(s.result, r)

        // The film that fails to load leaves the zeroed result (10023610..10023638, 100056dc..100056f0).
        let z = SessionResult.filmLoadFailed(startSector: 1)
        XCTAssertEqual(z.end, .filmLoadFailed)
        XCTAssertTrue(z.isFilm)
        XCTAssertEqual(z.present, [false, false])
        XCTAssertEqual(z.scores, [0, 0])
        XCTAssertEqual(z.levels, [FourCC(rawValue: 0), FourCC(rawValue: 0)])
    }

    /// The finale (FinaleTests' recipe: sector 12 with eleven levels already started, P1 invulnerable, the scroll near
    /// the map's end): the session ends at the campaign end with G+0x0d set → end `.finale`, allLevels (+0x14), P1's
    /// level `le09`, start sector 12. Bound: 3,000 passes.
    func testSessionResultAfterFinale() throws {
        var s = try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: 12, players: 1, film: nil),
                                  seed: 0x469c2)
        XCTAssertEqual(s.level, FourCC("le09"))
        s.game.flags.levelsStarted = 12
        s.game.setInvulnerable(0, true, sticky: true)
        s.game.scroll.window.top = 250
        s.game.scroll.window.bottom = 730
        s.game.scroll.progress = 3351
        var ending: PassOutput?
        for _ in 0..<3000 {
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            if out.sessionEnded { ending = out; break }
        }
        let out = try XCTUnwrap(ending, "bound: the session still runs after 3,000 passes")
        let r = try XCTUnwrap(out.result)
        XCTAssertEqual(r.end, .finale)
        XCTAssertTrue(r.allLevels)
        XCTAssertTrue(s.game.flags.allLevels)
        XCTAssertEqual(s.level, .none)
        XCTAssertEqual(r.startSector, 12)
        XCTAssertFalse(r.isFilm)
        XCTAssertEqual(r.present, [true, true])
        XCTAssertEqual(r.levels, [FourCC("le09")!, .none])
        XCTAssertEqual(r.scores, [s.players[0].score, 0])
        XCTAssertGreaterThan(r.scores[0], 0)
        XCTAssertFalse(r.cheated)
    }

    /// Cheated (+0x15) = any PRESENT slot's +0xbd (`10005ba4..10005bbc`) — player 2's slot counts in a one-player
    /// game, since it is present; a clean game reports false. Bound: Esc's 200 passes each.
    func testSessionResultCheated() throws {
        let a = try assets()
        var clean = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 3, players: 1, film: nil),
                                      seed: 7)
        guard let c = escape(&clean)?.result else { return XCTFail("no result") }
        XCTAssertFalse(c.cheated)
        XCTAssertEqual(c.startSector, 3)
        XCTAssertEqual(c.levels[0], a.levelOrder.level(sector: 3))

        for slot in 0..<2 {
            var s = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                      seed: 7)
            _ = s.pass(keys: HeldKeys(), ticks: 0)
            s.game.players[slot].cheated = true                 // FUN_10029bf0(p, 1), as every console cheat
            guard let r = escape(&s)?.result else { return XCTFail("no result") }
            XCTAssertTrue(r.cheated, "player \(slot + 1)'s cheat flag")
            XCTAssertEqual(r.end, .escape)
        }

        // An absent slot's flag is not read: the index byte −1 makes the slot absent (10005b74..10005b7c → 10005bc4).
        var s = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                  seed: 7)
        s.game.players[1].index = -1
        s.game.players[1].cheated = true
        s.game.players[1].score = 99
        guard let r = escape(&s)?.result else { return XCTFail("no result") }
        XCTAssertEqual(r.present, [true, false])
        XCTAssertFalse(r.cheated)
        XCTAssertEqual(r.scores[1], 0)
        XCTAssertEqual(r.levels[1], .none)
    }
}

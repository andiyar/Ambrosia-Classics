import XCTest
import HectorResources
@testable import DeimosCore

/// The early de01 check (plan C18b; early warning, NOT the replay gate G4 — that is H3's `DeimosReplayTests`):
/// the shipped demo film de01 played by `DeimosSession` (Phase 2, film playback `FUN_100069b0`) to game time 1,700,
/// with no keys and no rendering. It asserts only data-driven facts that hold whatever the pilot does — level 1's
/// first level object `bsgr` (map row 2978) is requested from the scroll's spawn row (`FUN_10033090`, top − 64) at
/// game time 77 at (371, −64) (the position its group receives after the y conversion, `1003351c..10033570`,
/// read from the spawn row's log); level 1's first pausing controller `01m1` (yLoc 1395) is created at 1660 (no unit
/// can pause the scroll before it) — and prints a first-divergence report: P1's deaths, RNG draws per 100 ticks, and
/// the entities created at each game time.
final class EarlyReplayTests: XCTestCase {
    func testEarlyDemo01Report() throws {
        let assets = try TestAssets.loaded.get()
        let index = try RealData.index()
        let film = try Film(data: index.data(for: XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC("de01")!))))
        var s = try DeimosSession(assets: assets, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: film),
                                  seed: 0)
        XCTAssertTrue(s.game.flags.filmPlaying)
        XCTAssertEqual(s.level, FourCC("le07"))

        let bsgr = FourCC("bsgr")!, m1 = FourCC("01m1")!
        let units = assets.definitions.units
        func pendingBsgr(_ g: GameState) -> Int { g.world.pendingLevelObjects.filter { $0.unit == bsgr }.count }
        var bsgrRequest: (t: Int32, x: Float?, y: Float?)?
        var m1CreatedAt: Int32?
        var deaths: [(t: Int32, lives: Int32)] = []
        var drawsAt100: [UInt64] = [s.rng.draws]
        var spawns: [(t: Int32, units: [FourCC])] = []

        let bound = 2_000
        var passes = 0
        var ended = false
        while s.gameTime < 1_700 {
            if passes >= bound { XCTFail("bound \(bound) passes reached at game time \(s.gameTime)"); break }
            let t = s.gameTime                                        // this pass's tick runs at game time t
            let stateBefore = s.players[0].lifeState
            let pendingBefore = pendingBsgr(s.game)
            let serialBefore = s.game.world.nextSerial
            let gameBefore: GameState? = bsgrRequest == nil ? s.game : nil   // for the spawn-row probe below
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            passes += 1
            let g = s.game
            // The entities created this pass (serials serialBefore…), in creation order.
            let born = g.world.entities.indices
                .filter { g.world.inUse[$0] && g.world.entities[$0].serial >= serialBefore }
                .sorted { g.world.entities[$0].serial < g.world.entities[$1].serial }
            if !born.isEmpty || g.world.nextSerial != serialBefore {
                spawns.append((t, born.map { units[g.world.entities[$0].unit].id }))
            }
            if bsgrRequest == nil && pendingBsgr(g) < pendingBefore, var probe = gameBefore {
                // The request's group position is overwritten later in the same tick (bsgr is a singleton, so it
                // joins PERM, and its own first update requests `bsbu` into PERM at its scrolled position), so it
                // is read from the spawn row's log: this pass's world update re-run on a copy of the state the pass
                // began with (no keys; the film supplies P1's input; the console is shut, so nothing is withheld).
                var sizedUnit = FourCC.none
                var at: (x: Float, y: Float)?
                probe.updateWorld(inputs: [[], []], inputWithheld: false) { step in
                    guard case let .spawn(ev) = step else { return }
                    switch ev {
                    case let .sized(u, _): sizedUnit = u
                    case let .group(_, x, y): if sizedUnit == bsgr && at == nil { at = (x, y) }
                    default: break
                    }
                }
                // The probe is this pass's tick: the same draws, serials and film read as the session's.
                XCTAssertEqual(probe.rng, g.rng, "probe RNG at game time \(t)")
                XCTAssertEqual(probe.world.nextSerial, g.world.nextSerial, "probe serials at game time \(t)")
                XCTAssertEqual(probe.film?.cursors, g.film?.cursors, "probe film cursor at game time \(t)")
                let member = born.first { units[g.world.entities[$0].unit].id == bsgr }
                let group = member.flatMap { m in g.world.groups.first { $0.members.contains(m) } }
                bsgrRequest = (t, at?.x, at?.y)
                print("bsgr at game time \(t): request (\(at.map { "\($0.x), \($0.y)" } ?? "none")); its group (\(group?.unit.description ?? "none")) "
                      + "after the pass at (\(group.map { "\($0.x), \($0.y)" } ?? "-"))")
            }
            if m1CreatedAt == nil, born.contains(where: { units[g.world.entities[$0].unit].id == m1 }) {
                m1CreatedAt = t
            }
            if stateBefore != 3 && g.players[0].lifeState == 3 { deaths.append((t, g.players[0].lives)) }
            if out.ticked && (t + 1) % 100 == 0 { drawsAt100.append(g.rng.draws) }
            if out.sessionEnded { ended = true; break }
        }

        // The report (information for H3 / F1; not asserted).
        var report = "EARLY de01 REPORT — passes \(passes), game time \(s.gameTime), cursor \(s.game.film?.cursors[0] ?? -1)"
        report += ", ended \(ended), P1 score \(s.players[0].score), lives \(s.players[0].lives)\n"
        report += "P1 deaths (game time, lives after): "
        report += deaths.isEmpty ? "none" : deaths.map { "\($0.t) (\($0.lives))" }.joined(separator: ", ")
        report += "\nRNG draws per 100 ticks: "
        report += zip(drawsAt100.dropFirst(), drawsAt100).enumerated()
            .map { "\($0.offset * 100)–\($0.offset * 100 + 99): \($0.element.0 - $0.element.1)" }.joined(separator: ", ")
        report += "\nEntities created by game time (live at the end of the pass):\n"
        report += spawns.map { "  \($0.t): " + $0.units.map(\.description).joined(separator: " ") }
            .joined(separator: "\n")
        print(report)

        // The data-driven facts.
        XCTAssertFalse(ended, "the session ended before game time 1,700")
        XCTAssertEqual(bsgrRequest?.t, 77, "the first bsgr record leaves the pending list")
        XCTAssertEqual(bsgrRequest?.x, 371, "the bsgr request x (spawn-row log)")
        XCTAssertEqual(bsgrRequest?.y, -64, "the bsgr request y (spawn-row log)")
        XCTAssertEqual(m1CreatedAt, 1660, "01m1 created")
    }
}

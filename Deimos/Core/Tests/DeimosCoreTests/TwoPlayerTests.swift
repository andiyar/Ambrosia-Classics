import XCTest
import HectorResources
@testable import DeimosCore

/// Two players in the core (plan TP; appendix B §1): the duo behaviours no other suite pins — the shared view shift
/// (`10029504..10029524`, each player's update calling `FUN_100100b0`), the respawn at the multi start whoever is
/// left (`10029d00..10029da0`, +0xcd fixed for the session), the game going on while either player is in
/// (`10006c3c..10006c7c`) and the game over once neither is (`10006c80..10006d98`), the level start's one
/// `R(400, 2000)` per in-game player (`10026a9c`), the two-player score bar drawn active (hud §8) and the mission
/// bonus paid to both (`10007c88..10007cd0`).
///
/// Everything runs on a real `DeimosSession` (or, for the tally, the `GameState` the level end runs on), with the
/// players' keys going through the fresh prefs' key table. Not repeated here (CR pins them): an out player staying
/// out across a transition, its score-bar record there, and the crossing's single draw with P2 out.
final class TwoPlayerTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private func session(sector: Int = 1, players: Int = 2) throws -> DeimosSession {
        try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: sector, players: players, film: nil),
                          seed: 0x469c2)
    }

    /// The fresh prefs' key table (`1000515c..10005194`): P1 ← →, P2 keypad 4 / 6 (left / right).
    private static let p1Left: UInt16 = 0x7B
    private static let p1Right: UInt16 = 0x7C
    private static let p2Left: UInt16 = 0x56
    private static let p2Right: UInt16 = 0x58

    /// Runs passes until game time is `t` (the next pass ticks at `t`). Bound: 3,000 passes.
    private func run(_ s: inout DeimosSession, to t: Int32, keys: HeldKeys = HeldKeys(),
                     file: StaticString = #filePath, line: UInt = #line) {
        var n = 0
        while s.gameTime < t {
            _ = s.pass(keys: keys, ticks: 0)
            n += 1
            if n > 3000 { return XCTFail("bound: game time \(t) not reached in 3,000 passes", file: file, line: line) }
        }
    }

    /// One pass that must tick (the tick flag set): returns its output.
    @discardableResult
    private func tick(_ s: inout DeimosSession, keys: HeldKeys = HeldKeys(),
                      file: StaticString = #filePath, line: UInt = #line) -> PassOutput {
        let t = s.gameTime
        let out = s.pass(keys: keys, ticks: 0)
        XCTAssertTrue(out.ticked, "the pass at game time \(t) ticked", file: file, line: line)
        return out
    }

    /// Takes player `i` out of the game as the life-state step leaves an eliminated player (1002a264): out of lives,
    /// state 1, +0xc4 = 0, shield 0.
    private static func eliminate(_ s: inout DeimosSession, _ i: Int) {
        s.game.players[i].lives = 0
        s.game.players[i].setLifeState(1, now: s.gameTime)
        s.game.players[i].inGame = false
        s.game.players[i].shield = 0
    }

    /// The serials of the live (in use, not deleted) entities whose unit is `id`.
    private static func live(_ g: GameState, _ id: FourCC) -> [Int32] {
        let units = g.assets.definitions.units
        return g.world.entities.indices
            .filter { g.world.inUse[$0] && !g.world.entities[$0].deleted && units[g.world.entities[$0].unit].id == id }
            .map { g.world.entities[$0].serial }
    }

    /// Every stored field of a player but its shared assets, as text (as CR's): "byte-equal" for a non-`Equatable`.
    private static func fields(_ p: Player) -> [String] {
        Mirror(reflecting: p).children.filter { $0.label != "assets" }.map { "\($0.label ?? "?")=\(String(reflecting: $0.value))" }
    }

    // MARK: - The shared view shift

    /// `10029504..10029524`: inside each player's update (P1 then P2, `10006bf0..10006c28`), left → `FUN_100100b0(0)`,
    /// else right → `(1)` — one shared offset, so the same direction moves 2 px a tick and opposite directions cancel;
    /// the clamp [−32, 31] is per call (`100100b8..`), so the last call's step is what +lastShift keeps.
    func testDuoViewShiftDoublesAndCancels() throws {
        var base = try session()
        run(&base, to: 56)                                                   // both respawn at 56 (> 0 + 55)
        XCTAssertEqual(base.scroll.offset, 0)
        let bothLeft = HeldKeys(held: [Self.p1Left, Self.p2Left])

        // Control: one player alone shifts 1 px a tick — P1 alone, then P2 alone (P2's keys reach the shift).
        var p1Only = base, p2Only = base
        for k in Int32(1)...3 {
            tick(&p1Only, keys: HeldKeys(held: [Self.p1Left]))
            tick(&p2Only, keys: HeldKeys(held: [Self.p2Left]))
            XCTAssertEqual(p1Only.scroll.offset, -k)
            XCTAssertEqual(p2Only.scroll.offset, -k)
        }
        XCTAssertEqual(p1Only.players[0].lifeState, 4)
        XCTAssertEqual(p2Only.players[1].lifeState, 4)

        // Both left: −2 a tick; tick 16 lands on −32 by two unclamped calls; tick 17 clamps both.
        var left = base
        for k in Int32(1)...17 {
            tick(&left, keys: bothLeft)
            XCTAssertEqual(left.scroll.offset, max(-32, -2 * k), "both left, tick \(k)")
            XCTAssertEqual(left.scroll.lastShift, k <= 16 ? -1 : 0, "both left, tick \(k)")
        }

        // Both right: +2 a tick to 31 — at tick 16 P1's call reaches 31 and P2's clamps (the range is [−32, 31]).
        var right = base
        for k in Int32(1)...16 {
            tick(&right, keys: HeldKeys(held: [Self.p1Right, Self.p2Right]))
            XCTAssertEqual(right.scroll.offset, min(31, 2 * k), "both right, tick \(k)")
            XCTAssertEqual(right.scroll.lastShift, k <= 15 ? 1 : 0, "both right, tick \(k)")
        }

        // Opposite: cancel every tick, and the last step is P2's (P2 updates after P1).
        var cancel = base, cancel2 = base
        for k in 1...5 {
            tick(&cancel, keys: HeldKeys(held: [Self.p1Left, Self.p2Right]))
            tick(&cancel2, keys: HeldKeys(held: [Self.p1Right, Self.p2Left]))
            XCTAssertEqual(cancel.scroll.offset, 0, "tick \(k)")
            XCTAssertEqual(cancel.scroll.lastShift, 1, "P2's right is the last call, tick \(k)")
            XCTAssertEqual(cancel2.scroll.offset, 0, "tick \(k)")
            XCTAssertEqual(cancel2.scroll.lastShift, -1, "P2's left is the last call, tick \(k)")
        }

        // The clamp is per call: at −32, P1's left clamps (no move) and P2's right moves on to −31; then each tick
        // −31 → −32 → −31, so opposite keys at the edge do not cancel.
        XCTAssertEqual(left.scroll.offset, -32)
        for k in 1...3 {
            tick(&left, keys: HeldKeys(held: [Self.p1Left, Self.p2Right]))
            XCTAssertEqual(left.scroll.offset, -31, "at the edge, tick \(k)")
            XCTAssertEqual(left.scroll.lastShift, 1)
        }
    }

    // MARK: - Respawn, one out, both out

    /// `FUN_10029cc0` places by +0xcd (`10029d00..10029da0`): 1 → the solo start, else the multi start — +0xcd is
    /// the session's player count and never changes, so a duo survivor respawns at ITS multi start even with the
    /// partner out: P1 at (104, 330), P2 at (312, 330), never the solo (208, 330). The death costs a life (the gate,
    /// P1 having reached state 4, is set) and the respawn comes on the first tick past enter + dyingTime.
    func testDuoRespawnAtMultiStart() throws {
        var base = try session()
        run(&base, to: 60)
        XCTAssertTrue(base.game.flags.p1Active)
        for (dies, out) in [(0, 1), (1, 0)] {
            var s = base
            Self.eliminate(&s, out)
            let d = s.players[dies].definition
            XCTAssertEqual([d.entrySoloStartX, d.entrySoloStartY], [208, 330])
            XCTAssertEqual([d.entryMultiStartX, d.entryMultiStartY], dies == 0 ? [104, 330] : [312, 330])
            XCTAssertEqual(s.players[dies].playerCount, 2)
            XCTAssertEqual(s.players[dies].lives, 3)
            // Away from the start, then destroyed.
            s.game.players[dies].object.x = 150
            s.game.players[dies].object.y = 200
            let killed = s.gameTime
            s.game.killPlayer(dies, now: killed)
            XCTAssertEqual(s.players[dies].lifeState, 3)
            XCTAssertGreaterThan(d.dyingTime, 0)
            run(&s, to: killed + d.dyingTime + 1)                            // ticks through enter + dyingTime
            XCTAssertEqual(s.players[dies].lifeState, 3, "now > enter + dyingTime is strict (1002a2b8..1002a2c4)")
            tick(&s)
            let p = s.players[dies]
            XCTAssertEqual(p.lifeState, 4, "player \(dies + 1) respawned")
            XCTAssertEqual(p.stateEntered, killed + d.dyingTime + 1)
            XCTAssertEqual(p.lives, 2)
            XCTAssertTrue(p.inGame)
            XCTAssertEqual(p.object.x.bitPattern, Float(d.entryMultiStartX).bitPattern, "player \(dies + 1)")
            XCTAssertEqual(p.object.y.bitPattern, Float(330).bitPattern)
            XCTAssertNotEqual(p.object.x.bitPattern, Float(d.entrySoloStartX).bitPattern)
            XCTAssertFalse(s.players[out].inGame, "the partner is still out")
            XCTAssertTrue(s.running)
        }
    }

    /// `10006c3c..10006c7c`: the game-over step returns while EITHER player is in the game (the first found) — with
    /// P2 eliminated through the life-state step (state 1 past `gameOverTime`, 1002a264), or with P1 out, the game
    /// runs on: no `nogo`, G+0x0a and the latch clear, the remaining player updated, the out player untouched.
    func testDuoOneOutGameContinues() throws {
        var base = try session()
        run(&base, to: 60)
        let nogo = try XCTUnwrap(FourCC("nogo"))
        XCTAssertEqual(base.game.assets.objects[24], nogo)

        // P2's last life ends: state 1 with 0 lives, out of the game on the first tick past enter + gameOverTime.
        var s = base
        s.game.players[1].lives = 0
        s.game.players[1].setLifeState(1, now: s.gameTime)
        let entered = s.gameTime
        let wait = s.players[1].definition.gameOverTime
        XCTAssertGreaterThan(wait, 0)
        run(&s, to: entered + wait + 1)                                      // ticks through enter + gameOverTime
        XCTAssertTrue(s.players[1].inGame, "still in during the wait (1002a24c..1002a260 strict)")
        XCTAssertFalse(s.scoreBar.records[1].drawActive, "out of lives: the record retired (FUN_10026c20)")
        tick(&s)
        XCTAssertFalse(s.players[1].inGame, "out on enter + gameOverTime + 1 (1002a264)")

        // P1 out from the start of the run (as an earlier game over leaves it), P2 playing.
        var t = base
        Self.eliminate(&t, 0)

        for (name, out, keep) in [("P2 out", 1, 0), ("P1 out", 0, 1)] {
            var g = name == "P2 out" ? s : t
            let frozen = Self.fields(g.players[out])
            let x0 = g.players[keep].object.x
            // The remaining player steers right for 10 ticks (its update runs), then drifts.
            for n in 0..<300 {
                let keys = n < 10 ? HeldKeys(held: [keep == 0 ? Self.p1Right : Self.p2Right]) : HeldKeys()
                let out2 = tick(&g, keys: keys)
                XCTAssertFalse(out2.sessionEnded, "\(name), pass \(n)")
                XCTAssertTrue(g.running, "\(name), pass \(n)")
                XCTAssertFalse(g.game.flags.noPlayerAlive, "\(name): G+0x0a clear, pass \(n)")
                XCTAssertFalse(g.game.flags.gameOverNoticed, "\(name): no game-over latch, pass \(n)")
                XCTAssertTrue(Self.live(g.game, nogo).isEmpty, "\(name): no nogo, pass \(n)")
                XCTAssertFalse(g.players[out].inGame)
                XCTAssertTrue(g.players[keep].inGame)
                XCTAssertEqual(g.players[keep].lifeState, 4, "\(name), pass \(n)")
                if n == 9 { XCTAssertGreaterThan(g.players[keep].object.x, x0, "\(name): the remaining player moved") }
            }
            XCTAssertEqual(Self.fields(g.players[out]), frozen, "\(name): the out player is not updated (100269a0)")
            XCTAssertFalse(g.scoreBar.records[out].drawActive)
            XCTAssertEqual(g.scoreBar.records[out].dirty, [], "\(name): retired once, then left alone")
            XCTAssertTrue(g.scoreBar.records[keep].drawActive)
        }
    }

    /// `10006c80..10006d98`: no player in the game → G+0x0a = 1; the first such tick spawns `nogo` (PermObjectID 24)
    /// and sets the latch and G+0x34 = game time; running clears on the tick at G+0x34 + int(flli 13 = 110) + 1. With
    /// P1 already out, P2's game-over wait still counts as "in"; the step runs after both players in the same tick
    /// (`10006c3c` follows `10006c28`), so G+0x34 is the very tick P2 leaves.
    func testDuoBothOutGameOver() throws {
        var s = try session()
        run(&s, to: 60)
        let nogo = try XCTUnwrap(FourCC("nogo"))
        Self.eliminate(&s, 0)
        s.game.players[1].lives = 0
        s.game.players[1].setLifeState(1, now: s.gameTime)
        let leaves = s.gameTime + s.players[1].definition.gameOverTime + 1
        XCTAssertEqual(EntityDraw.fctiwz(s.game.assets.floats[13]), 110)
        var n = 0
        while s.gameTime < leaves {
            tick(&s)
            XCTAssertTrue(s.players[1].inGame)
            XCTAssertFalse(s.game.flags.noPlayerAlive, "P2 waiting is still in the game, game time \(s.gameTime - 1)")
            XCTAssertFalse(s.game.flags.gameOverNoticed)
            XCTAssertTrue(Self.live(s.game, nogo).isEmpty)
            n += 1
            if n > 1000 { return XCTFail("bound: P2 never left within 1,000 passes") }
        }
        tick(&s)                                                             // the tick at `leaves`
        XCTAssertFalse(s.players[1].inGame)
        XCTAssertTrue(s.game.flags.noPlayerAlive)
        XCTAssertTrue(s.game.flags.gameOverNoticed)
        XCTAssertEqual(s.game.flags.gameOverStart, leaves, "the same tick P2 left")
        let serial = Self.live(s.game, nogo)
        XCTAssertEqual(serial.count, 1, "nogo spawned")
        var seen = Set(serial)
        for t in (leaves + 1)...(leaves + 110) {
            let out = tick(&s)
            XCTAssertTrue(s.running, "game time \(t)")
            XCTAssertFalse(out.sessionEnded, "game time \(t)")
            seen.formUnion(Self.live(s.game, nogo))
        }
        XCTAssertEqual(seen.count, 1, "nogo spawned once")
        let last = tick(&s)                                                  // the tick at leaves + 111
        XCTAssertFalse(s.running)
        XCTAssertTrue(last.sessionEnded)
        XCTAssertEqual(last.music.last, .stop, "the session end's music stop (10005ae4)")
        XCTAssertEqual(s.game.flags.gameOverStart, leaves)
    }

    // MARK: - The level start's draws

    /// `FUN_100269a0` (P1 then P2, `10006798..100067b8`) returns at once for a player out of the game; an in-game
    /// player draws one `R(400, 2000)` (`10026a9c`) and only P1 keeps it (+0x234 = now + R, +0x238 = 0;
    /// `10026aac..10026ab8`). At a real crossing 1 → 2: both in → 2 draws beyond the crossing tick's own, P1's the
    /// first; P1 out with P2 playing → 1 draw, P2's, kept by nobody — and the transition still happens, P2 alone in
    /// the game (`FUN_10007170` 100071a0..100071e4 looks for any in-game player).
    func testDuoLevelStartDrawsPerInGamePlayer() throws {
        for p1Out in [false, true] {
            var s = try session()
            if p1Out { Self.eliminate(&s, 0) }
            let keep = p1Out ? 1 : 0
            // To the pass that crosses (the scroll poked one row from the end; the level end runs on its own).
            s.game.scroll.progress = 3599
            var pre: DeimosSession?
            for _ in 0..<3000 {
                let before = s
                let out = s.pass(keys: HeldKeys(), ticks: 0)
                if s.game.flags.levelsStarted != before.game.flags.levelsStarted { pre = before; break }
                if out.sessionEnded { break }
            }
            var g = try XCTUnwrap(pre, "p1Out \(p1Out): a transition within 3,000 passes")
            XCTAssertEqual(g.players[0].inGame, !p1Out)
            XCTAssertTrue(g.players[1].inGame)
            g.game.players[0].integrityCheckTick = 1234
            g.game.players[0].integrityPasses = 5
            g.game.players[1].integrityCheckTick = 4321
            g.game.players[1].integrityPasses = 3
            let p1Before = Self.fields(g.players[0])

            // The crossing tick's own draws: a copy whose remaining coin tally is held one more tick (no crossing).
            var held = g
            held.game.tally.coin[keep].stateTimer = held.gameTime
            _ = held.pass(keys: HeldKeys(), ticks: 0)
            XCTAssertEqual(held.game.flags.levelsStarted, g.game.flags.levelsStarted, "the held copy did not cross")
            let tickDraws = held.rng.draws &- g.rng.draws

            let rng = g.rng
            let started = g.game.flags.levelsStarted
            let out = g.pass(keys: HeldKeys(), ticks: 0)
            XCTAssertEqual(g.game.flags.levelsStarted, started + 1, "p1Out \(p1Out): crossed")
            XCTAssertEqual(g.sector, 2)
            XCTAssertFalse(out.sessionEnded)
            XCTAssertTrue(g.running)
            let levelDraws = g.rng.draws &- rng.draws &- tickDraws
            XCTAssertEqual(levelDraws, p1Out ? 1 : 2, "p1Out \(p1Out): one R(400, 2000) per in-game player")

            // Replay the level start's draws: the pass's last ones.
            var r = rng
            for _ in 0..<tickDraws { _ = r.rand() }
            let first = r.range(Int32(400), Int32(2000))
            if !p1Out { _ = r.range(Int32(400), Int32(2000)) }
            XCTAssertEqual(r, g.rng)
            let p2 = g.players[1]
            XCTAssertEqual(p2.integrityCheckTick, 4321, "P2's draw is not kept (10026ab4)")
            XCTAssertEqual(p2.integrityPasses, 3)
            XCTAssertEqual(p2.lifeState, 2, "P2's level start ran")
            XCTAssertEqual(p2.stateEntered, 0)
            XCTAssertEqual(p2.object.x.bitPattern, Float(312).bitPattern)
            if p1Out {
                XCTAssertEqual(Self.fields(g.players[0]), p1Before, "the out P1 is not touched")
            } else {
                XCTAssertEqual(g.players[0].integrityCheckTick, 0 + first, "P1 keeps the first draw (10026ae4)")
                XCTAssertEqual(g.players[0].integrityPasses, 0)
            }
        }
    }

    // MARK: - The score bar

    /// hud §8: with both players in, P2's record is drawn ACTIVE — the level start's `FUN_10031400` sets +0x12e =
    /// +0x12f = +0xc4 for each — at R8…R15 and P2's flli: the lives symbol at F114/F115 undimmed, the score in tefo
    /// 44 undimmed, the reserve count in tefo 46 or (active, 0 left) the red 48, all three weapon icons at
    /// F134…F139 (drawn only when active), the meters at F118/119 and F124/125; and the per-tick update
    /// `FUN_100317e0` keeps P2's record live (followers, score), where a solo game's P2 is drawn once and frozen.
    func testDuoScoreBarBothActive() throws {
        let a = try assets()
        let f = a.floats
        var s = try session(sector: 3)                                       // three air weapons, one life each
        let r2 = s.scoreBar.records[1]
        XCTAssertTrue(r2.drawActive)
        XCTAssertTrue(r2.pendingRetire)
        XCTAssertEqual(r2.dirty, .all)
        XCTAssertEqual(r2.lastLives, 1)
        XCTAssertEqual(r2.localRects, Array(a.rects[8..<16]))
        XCTAssertEqual(r2.icons, s.scoreBar.records[0].icons)
        XCTAssertFalse(r2.icons.contains(.none), "three icons at sector 3")
        let air = s.players[1].handler.effectiveAir
        XCTAssertEqual(r2.icons[0], ScoreBarState.Icon(face: air.scoreBarPreviewFace, frame: air.scoreBarPreviewFrame))

        func rect(_ t: Int32, _ l: Int32, _ b: Int32, _ r: Int32) -> MacRect { MacRect(top: t, left: l, bottom: b, right: r) }
        func restore(_ local: MacRect) -> RenderOp {
            .copy(from: .scoreSave, to: .back, src: local,
                  dst: rect(local.top, local.left + 416, local.bottom, local.right + 416), interlaced: false)
        }
        func hud(_ face: FourCC, _ frame: Int, _ x: Int32, _ y: Int32, flags: UInt32 = 0, alpha: UInt32 = 0,
                 scale: Float = 1) -> RenderOp {
            .draw(DrawCommand(face: face, frame: frame, x: x, y: y, flags: flags, scale: scale, alpha: alpha,
                              clip: rect(0, 0, 480, 640), layer: 7, drawNow: true, colour: 0x7fff))
        }
        func cost(_ r: MacRect) -> RenderOp {
            .draw(DrawCommand(face: FourCC("COST")!, alpha: 8, clip: rect(0, 0, 480, 640), drawNow: true,
                              costRect: r, costColour: 0))
        }
        func flli(_ i: Int, file: StaticString = #filePath, line: UInt = #line) -> Int32 {
            XCTAssertEqual(f[i].rounded(.towardZero), f[i], "flli \(i) is whole", file: file, line: line)
            return Int32(f[i])
        }
        let text = try TextLayout(assets: a)
        func words(_ fmt: Int, _ str: String) -> [RenderOp] {
            var t = TextRequest(format: a.formats[fmt], text: str)
            t.drawNow = true
            return text.draw(t).map { .draw($0) }
        }
        let scoreXs: [Int32] = [466, 476, 486, 496, 506, 516, 526]
        let digits = scoreXs.map {
            RenderOp.draw(DrawCommand(face: FourCC("tesm")!, frame: 61, x: $0, y: 324, flags: 4, scale: 1, alpha: 0,
                                      clip: rect(0, 0, 480, 640), layer: 8, drawNow: true, colour: 0x4B7C))
        }
        XCTAssertEqual(words(44, "0000000"), digits, "tefo 44, undimmed (alpha 0; dimmed it is 16)")
        XCTAssertNotEqual(words(48, "0"), words(46, "0"), "the red count is a different format")
        // The icons' places are P2's own, not P1's (F128…F133).
        XCTAssertNotEqual([flli(134), flli(135)], [flli(128), flli(129)])

        let play = try XCTUnwrap(FourCC("play")), shme = try XCTUnwrap(FourCC("shme"))
        var expected: [RenderOp] = [restore(rect(317, 25, 333, 135))] + digits
        expected += [restore(rect(257, 98, 297, 138)), hud(play, 1, 534, 276)]          // F114/F115, no dim
        XCTAssertEqual([flli(114), flli(115)], [534, 276])
        expected.append(restore(rect(263, 56, 307, 102)))
        expected += words(48, "0")                                                       // 1 life: 0 left, red
        let iconRects = [rect(416, 33, 451, 65), rect(423, 76, 445, 95), rect(423, 103, 445, 124)]
        for k in 0..<3 {
            expected.append(restore(iconRects[k]))
            let icon = r2.icons[k]
            expected.append(hud(icon.face, Int(icon.frame), flli(134 + 2 * k), flli(135 + 2 * k), flags: 1,
                                alpha: UInt32(flli(k == 0 ? 141 : 140)), scale: k == 0 ? 1 : f[142]))
        }
        expected += [restore(rect(353, 31, 368, 127)), hud(shme, 0, 495, 359), cost(rect(353, 447, 368, 543))]
        expected += [restore(rect(388, 31, 403, 127)), hud(shme, 1, 495, 394), cost(rect(388, 447, 403, 543))]
        XCTAssertEqual([flli(118), flli(119), flli(124), flli(125)], [495, 359, 495, 394])

        // P2's part of the level start's draw (P1's elements clean, so only P2's are emitted).
        var bar = s.scoreBar
        bar.records[0].dirty = []
        let ops = try ScoreBarDraw(assets: a).drawOps(state: bar, blitToScreen: false)
        XCTAssertEqual(ops.count, expected.count)
        for (i, (got, want)) in zip(ops, expected).enumerated() { XCTAssertEqual(got, want, "P2 op \(i)") }
        // … and the session's first pass emits that sequence as part of the level start's ops.
        let first = tick(&s)
        let found = (0...max(0, first.ops.count - expected.count)).contains {
            Array(first.ops[$0..<($0 + expected.count)]) == expected
        }
        XCTAssertTrue(found, "the level start's ops carry P2's active elements")

        // The update keeps P2's record live: its shield follower rises with P2's respawn like P1's.
        run(&s, to: 56)
        XCTAssertEqual(s.scoreBar.records[1].shownShield.bitPattern, Float(0).bitPattern)
        for t in Int32(56)...60 {
            tick(&s)
            XCTAssertEqual(s.players[1].lifeState, 4)
            XCTAssertEqual(s.scoreBar.records[1].shownShield.bitPattern, Float(2 * (t - 55)).bitPattern, "t \(t)")
            XCTAssertTrue(s.scoreBar.records[1].dirty.contains(.shield))
            XCTAssertTrue(s.scoreBar.records[1].drawActive)
        }
        // P2 scores: the next tick stores it and redraws P2's score (R8) — P1's score element stays clean.
        s.game.players[1].score = 5_000
        let next = tick(&s)
        XCTAssertEqual(s.scoreBar.records[1].lastScore, 5_000)
        XCTAssertTrue(s.scoreBar.records[1].dirty.contains(.score))
        XCTAssertFalse(s.scoreBar.records[0].dirty.contains(.score))
        let r8 = rect(317, 25, 333, 135)
        XCTAssertTrue(next.ops.contains {
            if case .copy(.scoreSave, .back, let src, _, _) = $0 { return src == r8 } else { return false }
        }, "P2's score element redrawn")
        XCTAssertTrue(next.ops.contains(.draw(DrawCommand(face: FourCC("tesm")!, frame: 61, x: 466, y: 324, flags: 4,
                                                          scale: 1, alpha: 0, clip: rect(0, 0, 480, 640), layer: 8,
                                                          drawNow: true, colour: 0x4B7C))),
                      "\"0005000\" begins with an undimmed 0 in P2's row")
    }

    // MARK: - The mission bonus

    /// The mission bonus (`10007c88..10007cd0`): each payment, `FUN_10029a10(p, int(flli 205), raw 1)` for player 0
    /// then 1 — 100,000 to EACH player, raw (no multiplier; the raw branch sets the extra-life step to the new score
    /// + trunc(flli 182), 10029ad0..10029aec), ten times (flli 208); the tier before it pays each player times their
    /// own multiplier. A player out of the game is skipped (10029a28..10029a30).
    func testDuoMissionBonusPaysBoth() throws {
        let a = try assets()
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[205]), 100_000)
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[208]), 10)
        for p2Out in [false, true] {
            var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
            s.flags.numPlayers = 2
            s.flags.sector = 12
            s.flags.level = FourCC("le07")!
            s.flags.running = true
            s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
            try s.setupPlayer(0)
            try s.setupPlayer(1)
            s.playerLevelStart(0)
            s.playerLevelStart(1)
            s.tally.reset()
            if p2Out { s.players[1].inGame = false }
            s.players[0].multiplier = 3
            s.players[1].multiplier = 2
            s.flags.perfectLevels = 11                                       // this level makes 12 of 12
            s.flags.groundDestroyed = 4
            s.flags.groundCreated = 4
            s.accuracyTier(now: 0)
            let start = s.players.map(\.score)
            var atMission: [Int32]?, livesAtMission: [Int32] = []
            var payments: Int32 = 0
            var done = false
            for t in Int32(1)...4000 {
                let before = s.players.map(\.score), paid = s.tally.missionPayments
                done = s.accuracyTally(now: t)
                if atMission == nil && s.tally.missionBonus {
                    atMission = before
                    livesAtMission = s.players.map(\.lives)
                }
                let delta = zip(s.players.map(\.score), before).map { $0 - $1 }
                if s.tally.missionPayments != paid {
                    payments += 1
                    XCTAssertEqual(s.tally.missionPayments, paid + 1)
                    XCTAssertEqual(delta, [100_000, p2Out ? 0 : 100_000], "p2Out \(p2Out): payment \(payments), raw")
                } else if atMission != nil {
                    XCTAssertEqual(delta, [0, 0], "p2Out \(p2Out): nothing between payments, t \(t)")
                }
                if done { break }
            }
            XCTAssertTrue(done, "p2Out \(p2Out): the tally finished within 4,000 ticks")
            XCTAssertEqual(payments, 10)
            XCTAssertFalse(s.tally.missionBonus)
            let mission = try XCTUnwrap(atMission, "p2Out \(p2Out): the mission bonus began")
            let tier: [Int32] = [5000 * 12 * 3, p2Out ? 0 : 5000 * 12 * 2]  // flli 189 × sector × each multiplier
            XCTAssertEqual(zip(mission, start).map { $0 - $1 }, tier, "p2Out \(p2Out): the tier")
            XCTAssertEqual(zip(s.players.map(\.score), mission).map { $0 - $1 }, [1_000_000, p2Out ? 0 : 1_000_000])
            XCTAssertEqual(s.players.map(\.lives), livesAtMission, "raw payments give no extra life")
            let adjust = EntityDraw.fctiwz(a.floats[182])
            XCTAssertEqual(s.players[0].extraLifeStep, s.players[0].score &+ adjust, "the raw branch (10029ad0)")
            if !p2Out {
                XCTAssertEqual(s.players[1].extraLifeStep, s.players[1].score &+ adjust, "P2 paid raw too")
            }
        }
    }
}

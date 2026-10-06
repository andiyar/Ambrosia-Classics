import XCTest
import HectorResources
@testable import DeimosCore

/// The player's Phase-1 subset (plan C4): setup `FUN_10026410`, level start `FUN_100269a0`, and the ◇
/// `updatePhase1` stub in `FUN_10028170`'s order (player-physics.md §2, §4, §7; gameplay-leftovers.md §2.1;
/// loose-ends-combat.md §6.2).
final class PlayerPhase1Tests: XCTestCase {
    static let loaded: Result<DeimosAssets, Error> = Result { try DeimosAssets.load(index: RealData.index()) }
    private func assets() throws -> DeimosAssets { try Self.loaded.get() }

    /// A level-1 world as `FUN_100051a0` + `FUN_100064d0` build it: setup P1/P2, level start P1 then P2
    /// at game time 0, the score bar's level start, the scroll's level start.
    struct World {
        var players: [Player]
        var bar: ScoreBarState
        var scroll = ScrollState()
        var rng: MSLRandom
        var now: Int32 = 0

        init(assets: DeimosAssets, players count: Int = 1, seed: UInt32 = 0x469c2) throws {
            var p0 = Player(assets: assets), p1 = Player(assets: assets)
            try p0.setup(index: 0, players: count, sector: 1)
            try p1.setup(index: 1, players: count, sector: 1)
            rng = MSLRandom(seed: seed)
            p0.levelStart(now: 0, rng: &rng)
            p1.levelStart(now: 0, rng: &rng)
            players = [p0, p1]
            bar = ScoreBarState(assets: assets)
            bar.levelStart(players: players)
            scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        }

        /// One logic tick's player + score-bar part (`FUN_10006b50` order: P1, P2, score bar), then time + 1.
        mutating func tick(_ p1: PlayerInput = [], _ p2: PlayerInput = []) {
            players[0].updatePhase1(now: now, input: p1, scroll: &scroll, scoreBar: &bar)
            players[1].updatePhase1(now: now, input: p2, scroll: &scroll, scoreBar: &bar)
            bar.update(players: players)
            now += 1
        }

        /// Runs ticks until `now == t` (exclusive), i.e. the next tick runs at `t`.
        mutating func run(to t: Int32, _ input: PlayerInput = []) {
            while now < t { tick(input) }
        }
    }

    func testLevelStartPlayerOne() throws {
        let a = try assets()
        var p = Player(assets: a)
        try p.setup(index: 0, players: 1, sector: 1)
        XCTAssertTrue(p.inGame)
        XCTAssertEqual(p.lives, 3)
        XCTAssertEqual(p.score, 0)
        XCTAssertEqual(p.shield, 100)
        XCTAssertEqual(p.lifeState, 2)
        XCTAssertEqual(p.handler.air.id, FourCC("aiic"))
        XCTAssertEqual(p.handler.ground.id, FourCC("plbo"))
        // Setup at another sector: 1 life.
        var later = Player(assets: a)
        try later.setup(index: 0, players: 1, sector: 2)
        XCTAssertEqual(later.lives, 1)

        p.object.visibility = 55; p.lastBankingTick = 9; p.object.frame = 3; p.appearing = true
        var rng = MSLRandom(seed: 0x469c2)
        p.levelStart(now: 0, rng: &rng)
        XCTAssertEqual(p.object.face, FourCC("pl1o"))
        XCTAssertEqual(p.object.frame, 0)
        XCTAssertEqual(p.lastBankingTick, 0)
        XCTAssertEqual(p.object.layer, FourCC("play"))
        XCTAssertEqual(p.object.x, 208)
        XCTAssertEqual(p.object.y, 330)
        XCTAssertEqual(p.object.vx, 0)
        XCTAssertEqual(p.object.vy, 0)
        XCTAssertEqual(p.lifeState, 2)
        XCTAssertEqual(p.stateEntered, 0)
        XCTAssertFalse(p.appearing)
        XCTAssertEqual(p.object.visibility, 0)
        XCTAssertEqual(p.object.visibilityTarget, 100)
        XCTAssertEqual(p.object.visibilityStep, 2)
        XCTAssertEqual(p.handler.crosshair.visibility, 0)
        XCTAssertEqual(p.handler.crosshair.visibilityTarget, 100)
        XCTAssertEqual(p.handler.crosshair.visibilityStep, 6)
        XCTAssertEqual(p.shield, 100)
        XCTAssertTrue(p.handler.iconsDirty)
        // Exactly one draw: R(400, 2000) = 1446 after srand(0x469c2); stored for P1 (+0x234 = now + draw).
        var check = MSLRandom(seed: 0x469c2)
        XCTAssertEqual(check.range(Int32(400), Int32(2000)), 1446)
        XCTAssertEqual(rng, check)
        XCTAssertEqual(p.integrityCheckTick, 1446)

        // Two-player: P1 at (104, 330), P2 at (312, 330) with pl2o; P2 draws too but stores nothing.
        let w = try World(assets: a, players: 2)
        XCTAssertEqual(w.players[0].object.x, 104)
        XCTAssertEqual(w.players[1].object.x, 312)
        XCTAssertEqual(w.players[1].object.y, 330)
        XCTAssertEqual(w.players[1].object.face, FourCC("pl2o"))
        var two = MSLRandom(seed: 0x469c2)
        _ = two.range(Int32(400), Int32(2000)); _ = two.range(Int32(400), Int32(2000))
        XCTAssertEqual(w.rng, two)
        XCTAssertEqual(w.players[1].integrityCheckTick, 0)
    }

    func testSoloPlayerTwoMakesNoDraw() throws {
        let a = try assets()
        var p2 = Player(assets: a)
        try p2.setup(index: 1, players: 1, sector: 1)
        XCTAssertFalse(p2.inGame)
        XCTAssertEqual(p2.lives, 0)
        XCTAssertEqual(p2.shield, 0)
        XCTAssertEqual(p2.lifeState, 1)
        let before = p2
        var rng = MSLRandom(seed: 0x469c2)
        p2.levelStart(now: 0, rng: &rng)
        XCTAssertEqual(rng, MSLRandom(seed: 0x469c2))
        XCTAssertEqual(p2.object, before.object)
        XCTAssertEqual(p2.lifeState, 1)
        // And it never updates.
        var w = try World(assets: a, players: 1)
        let p2Start = w.players[1]
        w.run(to: 120, .left)
        XCTAssertEqual(w.players[1].object, p2Start.object)
        XCTAssertEqual(w.players[1].handler, p2Start.handler)
    }

    func testEntersActiveAtTick56() throws {
        var w = try World(assets: try assets())
        for t: Int32 in 0...55 {
            w.tick(.left)
            XCTAssertEqual(w.players[0].lifeState, 2, "t \(t)")
            XCTAssertEqual(w.players[0].stateEntered, 0)
            XCTAssertEqual(w.players[0].input, [], "no input in state 2")
        }
        w.tick(.left)                                   // t 56: now > 0 + 55
        let p = w.players[0]
        XCTAssertEqual(p.lifeState, 4)
        XCTAssertEqual(p.stateEntered, 56)
        XCTAssertEqual(p.input, .left)
        XCTAssertEqual(p.object.x, 208)
        XCTAssertEqual(p.object.y, 330)
        XCTAssertEqual(p.object.halfWidth, 26)          // pl1o frame 0 is 53×43
        XCTAssertEqual(p.object.halfHeight, 21)
        XCTAssertEqual(p.object.scaledWidth, 53)
        XCTAssertEqual(p.object.scaledHeight, 43)
    }

    func testAppearFade() throws {
        var w = try World(assets: try assets())
        w.run(to: 56)
        for t: Int32 in 56...105 {
            w.tick()
            XCTAssertEqual(w.players[0].object.visibility, Float(2 * (t - 55)), "t \(t)")
            XCTAssertEqual(w.players[0].appearing, t < 105, "+0xc5 at t \(t)")
        }
        w.tick()
        XCTAssertEqual(w.players[0].object.visibility, 100)

        // FUN_10012750 overshoot clamps (synthetic), both ramps.
        var o = GameObject()
        o.visibility = 99; o.visibilityTarget = 100; o.visibilityStep = 2
        o.tint = 5; o.tintTarget = 3; o.tintStep = 4
        o.stepRamps()
        XCTAssertEqual(o.visibility, 100)               // rising: capped at the target
        XCTAssertEqual(o.tint, 3)                       // falling: 1 < 3 → target
        o.visibility = 3; o.visibilityTarget = -5; o.visibilityStep = 4
        o.tint = 0; o.tintTarget = 10; o.tintStep = 4
        o.stepRamps()
        XCTAssertEqual(o.visibility, 0)                 // falling: −1 < 0 → 0 (not the −5 target)
        XCTAssertEqual(o.tint, 4)
        o.visibility = 7; o.visibilityTarget = 7; o.visibilityStep = 4
        o.stepRamps()
        XCTAssertEqual(o.visibility, 7)                 // equal: unchanged
    }

    func testBankingTables() throws {
        // The three 7-entry jump tables (r2+0x3074 / +0x3058 / +0x303c, player-physics §2.4).
        XCTAssertEqual(Player.bankingNone, [0, 0, 1, 2, 0, 4, 5])
        XCTAssertEqual(Player.bankingLeft, [1, 2, 3, 3, 3, 4, 5])
        XCTAssertEqual(Player.bankingRight, [4, 0, 1, 2, 5, 6, 6])

        var w = try World(assets: try assets())
        w.run(to: 56, .left)
        XCTAssertEqual(w.players[0].object.frame, 0)
        var frames: [Int32] = []
        for _ in 0..<8 { w.tick(.left); frames.append(w.players[0].object.frame) }
        // t 56…63: an opportunity every 2 ticks (k = flli 166 = 1; `now > +0xd4 + 1`).
        XCTAssertEqual(frames, [1, 1, 2, 2, 3, 3, 3, 3])
        frames = []
        for _ in 0..<14 { w.tick(.right); frames.append(w.players[0].object.frame) }
        // t 64…77: opportunities at 64, 66, …, 76 → 2, 1, 0, 4, 5, 6, 6.
        XCTAssertEqual(frames, [2, 2, 1, 1, 0, 0, 4, 4, 5, 5, 6, 6, 6, 6])
        // Left from frame 4 jumps straight to 3 (quirk).
        var v = try World(assets: try assets())
        v.run(to: 56)
        v.tick(.right)                                  // t 56: 0 → 4
        XCTAssertEqual(v.players[0].object.frame, 4)
        v.tick(.left)                                   // t 57: no opportunity
        XCTAssertEqual(v.players[0].object.frame, 4)
        v.tick(.left)                                   // t 58: 4 → 3
        XCTAssertEqual(v.players[0].object.frame, 3)
    }

    func testViewShiftFromInput() throws {
        var w = try World(assets: try assets())
        w.run(to: 56, .left)
        XCTAssertEqual(w.scroll.offset, 0, "nothing before t 56")
        for _ in 0..<40 { w.tick(.left) }
        XCTAssertEqual(w.scroll.offset, -32)
        // Left wins over right.
        var v = try World(assets: try assets())
        v.run(to: 56)
        for _ in 0..<5 { v.tick([.left, .right]) }
        XCTAssertEqual(v.scroll.offset, -5)
        for _ in 0..<3 { v.tick(.right) }
        XCTAssertEqual(v.scroll.offset, -2)
    }

    func testCrosshair() throws {
        var w = try World(assets: try assets())
        for t: Int32 in 0...55 {
            w.tick()
            XCTAssertFalse(w.players[0].handler.crosshairShown, "t \(t)")
        }
        w.tick()                                        // t 56
        var c = w.players[0].handler
        XCTAssertTrue(c.crosshairShown)
        XCTAssertEqual(c.crosshair.face, FourCC("pbta"))
        XCTAssertEqual(c.crosshair.frame, 0)
        XCTAssertEqual(c.crosshair.x, 208)
        XCTAssertEqual(c.crosshair.y, 209)
        XCTAssertEqual(c.crosshair.visibility, 6)
        XCTAssertFalse(c.crosshair.drawShadow)
        XCTAssertEqual(c.crosshair.halfHeight, 6)           // pbta frame 0 is 14×13: the cy floor
        w.run(to: 72)
        w.tick()                                        // t 72: 17 steps of 6 → 100
        c = w.players[0].handler
        XCTAssertEqual(c.crosshair.visibility, 100)
        XCTAssertEqual(w.players[0].crosshairAdjust, 0)
    }
}

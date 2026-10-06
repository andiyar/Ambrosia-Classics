import XCTest
import HectorResources
@testable import DeimosCore

/// The shipped assets, loaded once for every suite that needs them.
enum TestAssets {
    static let loaded: Result<DeimosAssets, Error> = Result { try DeimosAssets.load(index: RealData.index()) }
}

/// A level-1 world as `FUN_100051a0` + `FUN_100064d0` build it: setup P1/P2, level start P1 then P2
/// at game time 0, the score bar's level start, the scroll's level start. Shared by the player, score-bar,
/// entity-draw, text and session suites.
struct TestWorld {
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

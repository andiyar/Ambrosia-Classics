import XCTest
import HectorResources
@testable import DeimosCore

/// The shipped assets, loaded once for every suite that needs them.
enum TestAssets {
    static let loaded: Result<DeimosAssets, Error> = Result { try DeimosAssets.load(index: RealData.index()) }
}

/// A level-1 world as `FUN_100051a0` + `FUN_100064d0` build it: setup P1/P2, level start P1 then P2
/// at game time 0 (`le07`, sector 1), the score bar's level start, the scroll's level start. Shared by the player,
/// score-bar, entity-draw, text and session suites. A `GameState` underneath; the fields the suites read are
/// forwarding accessors.
struct TestWorld {
    var state: GameState
    var players: [Player] {
        get { state.players }
        set { state.players = newValue }
    }
    var bar: ScoreBarState {
        get { state.scoreBar }
        set { state.scoreBar = newValue }
    }
    var scroll: ScrollState {
        get { state.scroll }
        set { state.scroll = newValue }
    }
    var rng: MSLRandom {
        get { state.rng }
        set { state.rng = newValue }
    }
    var now: Int32 {
        get { state.flags.gameTime }
        set { state.flags.gameTime = newValue }
    }

    init(assets: DeimosAssets, players count: Int = 1, seed: UInt32 = 0x469c2) throws {
        var s = GameState(assets: assets, prefs: DeimosPrefs.fresh, seed: seed)
        s.flags.numPlayers = UInt8(count)
        s.flags.sector = 1
        s.flags.level = FourCC("le07")!
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        s.scoreBar.levelStart(players: s.players, sector: 1)
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        state = s
    }

    /// One logic tick's player + score-bar part (`FUN_10006b50` order: P1 and P2 through `GameState.updatePlayer`,
    /// score bar), then time + 1. The P1-active gate (`10006b9c..10006bc4`) is not run: no TestWorld suite reaches
    /// the dying-state end it guards (whole-tick order is `updateWorld`'s, tested there).
    mutating func tick(_ p1: PlayerInput = [], _ p2: PlayerInput = []) {
        state.updatePlayer(0, input: p1)
        state.updatePlayer(1, input: p2)
        state.scoreBar.update(players: state.players, sector: 1)
        state.flags.gameTime += 1
    }

    /// Runs ticks until `now == t` (exclusive), i.e. the next tick runs at `t`.
    mutating func run(to t: Int32, _ input: PlayerInput = []) {
        while now < t { tick(input) }
    }
}

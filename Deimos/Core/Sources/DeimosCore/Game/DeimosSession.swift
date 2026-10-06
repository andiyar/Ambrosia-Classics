import Foundation
import HectorResources

/// How a session starts (the `FUN_100051a0` request: level, players, film). ★ LOCKED (plan S2).
public struct SessionStart: Equatable, Sendable {
    /// 1…12, the play order of `LevelOrder`.
    public var sector: Int
    /// 1…2.
    public var players: Int
    /// A replay to play back — unused in Phase 1.
    public var film: Film?

    public init(sector: Int, players: Int, film: Film?) {
        self.sector = sector
        self.players = players
        self.film = film
    }
}

public enum SessionError: Error, Equatable, Sendable {
    /// `LevelOrder` has no level for the sector, or no `leve` definition carries the tag.
    case noLevel(sector: Int)
    /// PermFloats 54/55 (VisibleGameWidth/Height) are not the 416 × 480 that `ScrollState` hard-codes, or the
    /// float list is too short to hold them (reported as 0).
    case visibleArea(width: Float, height: Float)
    /// The prefs' byte-pref block is shorter than `DeimosPrefs.bytePrefCount`.
    case shortBytePrefs(count: Int)
}

/// One game session of G_Game.cc (`FUN_100051a0`, engine-loop §3, level-scroll-objects §8) — the Phase-1
/// subset: one level, the players' Phase-1 stub, the scroll, the score bar; no entities, sound, music,
/// console, pause or film. ★ LOCKED (plan S2).
///
/// Listing reads for plan C6 (`disasm-review3-all.txt`):
/// - Set-up (`100057c8..100058a0`): `srand(TickCount())` (`100057d4`; the pre-seed `FUN_10046580(400, 2000)`
///   draw at the top of the function is overwritten by the seed and not modelled — invariant 6); film record
///   `FUN_10009710`; `FUN_1000c3f0`/`FUN_1000c2a0` (window plumbing, no op); game +0x08 = 1, +0x0a/+0x09/+0x39
///   = 0, +0x18 = level, +0x14 = sector `FUN_10011e30`; level info `FUN_10011fd0`; `FUN_10026410` for index 0
///   then 1 (`10005860..10005888`, now = game +0x1c); `FUN_1004a990(1)` (input, no op); `FUN_100064d0`. The
///   frame controller (`FUN_10030190` + `FUN_10030210(ctrl, film, 1, 1)`) is set up before the film branch.
/// - Level start `FUN_100064d0` (`100064d0..10006984`), Phase-1 subset: game time = 0 (`10006500`), +0x29 = 0,
///   +0x2c = 0, appeared +0x38 = 0 (`10006510`); [accuracy counters, `FUN_1003e510`]; first level → the tag
///   at +0x18; levels started +0x10 += 1 (`1000667c..10006684`); +0x14 = sector (`100066e8`);
///   [`FUN_1002b3a0`]; terrain buffer `FUN_10009d70(D+0x6c, flli 52, 53, 56)` (`1000674c`, superseded by the
///   map load's resize — no op); [music]; each player `FUN_100269a0(p, tag, gameTime)` P1 then P2
///   (`10006798..100067b8`); [message/debris/particle resets]; `FUN_1000fa90` (`100067ec`: the scroll's level
///   start, whose `FUN_1000fbc0` is `.loadTerrain`); [entity groups, object list, notices]; `FUN_100189f0`
///   (`10006824`: clears the layer counts — nothing is queued yet, so no op); [`FUN_1000fa10` load-time spawns,
///   the `Notice_Level_NN` spawn `1000682c..100068f8`]; `FUN_10009f00(D+0x68, black)` (`1000690c` →
///   `.fill(.back, 0)`); `FUN_10031ad0(0)`, `FUN_10031400(p1, p2)`, `FUN_10031ad0(1)` (`10006914..10006934`:
///   the score bar's level start with the screen blits off); byte pref 5 set → game +0x0f = 1 and pref 5
///   cleared, else +0x0f = 0 (`1000693c..10006970`); `FUN_10010120` (`10006974`: the first terrain blit, with
///   pref 5 as just left). Game +0x0f restores pref 5 when the game appears (`10005990..100059b0`). With fresh
///   prefs (pref 5 = 0) the dance is moot; it is kept because `prefs` may say otherwise.
public struct DeimosSession: Sendable {
    public let assets: DeimosAssets
    public private(set) var prefs: DeimosPrefs
    public let start: SessionStart
    /// `_DAT_100e032c`.
    public private(set) var rng: MSLRandom
    /// The stack-local frame controller (`auStack_9a0`).
    public private(set) var controller: FrameController
    /// Game +0x00 / +0x04.
    public private(set) var players: [Player]
    public private(set) var scoreBar: ScoreBarState
    public private(set) var scroll = ScrollState()
    /// Game +0x18: the current level tag.
    public let level: FourCC
    /// Game +0x14: the current sector.
    public let sector: Int
    /// Game +0x1c: game time (logic ticks since level start).
    public private(set) var gameTime: Int32 = 0
    /// Game +0x38: the game has appeared (fade in done; presents and score-bar screen blits on).
    public private(set) var appeared = false
    /// Game +0x08: the session is running (the `while` condition).
    public private(set) var running = true
    /// Game +0x0f: byte pref 5 (interlacing) was suspended at level start, restore at appear.
    public private(set) var restoreInterlace = false
    /// The level start's ops, handed out by the first `pass`.
    private var pendingOps: [RenderOp] = []
    private let scoreBarDraw: ScoreBarDraw
    /// `fctiwz(PermFloat 18)`: the game time at which the game appears (`10005930..1000595c`).
    private let appearTime: Int32

    /// `FUN_100051a0`'s set-up subset, then the level start `FUN_100064d0` (see the type's comment).
    public init(assets: DeimosAssets, prefs: DeimosPrefs, start: SessionStart, seed: UInt32) throws {
        // ScrollState hard-codes PermFloats 54/55 (VisibleGameWidth/Height); the pass reads 18 and 32 too.
        let f = assets.floats
        guard f.count > 55, f[54] == Float(ScrollState.visibleWidth), f[55] == Float(ScrollState.visibleHeight) else {
            throw SessionError.visibleArea(width: f.count > 54 ? f[54] : 0, height: f.count > 55 ? f[55] : 0)
        }
        guard prefs.bytePrefs.count >= DeimosPrefs.bytePrefCount else {
            throw SessionError.shortBytePrefs(count: prefs.bytePrefs.count)
        }
        self.assets = assets
        self.prefs = prefs
        self.start = start
        scoreBarDraw = try ScoreBarDraw(assets: assets)
        appearTime = EntityDraw.fctiwz(f[18])

        let tag = assets.levelOrder.level(sector: start.sector)
        guard tag != .none, let info = assets.definitions.levels.first(where: { $0.id == tag }) else {
            throw SessionError.noLevel(sector: start.sector)
        }
        level = tag
        sector = start.sector

        // Frame controller: FUN_10030190 + FUN_10030210(ctrl, film, 1, 1).
        controller = FrameController(fpsMaxRate: EntityDraw.fctiwz(f[32]))
        controller.startSession(filmPlayback: start.film != nil, gameScreenLayout: true, autoInterlaceAllowed: true)

        rng = MSLRandom(seed: seed)                                  // 100057d4 srand(TickCount())

        var made: [Player] = []
        for i in 0..<2 {                                             // 10005860..10005888 FUN_10026410
            var p = Player(assets: assets)
            try p.setup(index: i, players: start.players, sector: start.sector, now: 0)
            made.append(p)
        }
        players = made
        scoreBar = ScoreBarState(assets: assets)
        pendingOps = levelStart(info)
    }

    /// `FUN_100064d0` (level start), the Phase-1 subset (see the type's comment); returns its ops.
    private mutating func levelStart(_ info: LevelDefinition) -> [RenderOp] {
        var ops: [RenderOp] = []
        gameTime = 0                                                 // 10006500
        appeared = false                                             // 10006510
        for i in 0..<2 {                                             // 10006798..100067b8 FUN_100269a0
            players[i].levelStart(now: gameTime, rng: &rng, levelRef: level)
        }
        ops.append(.loadTerrain(image: info.backgroundImage))        // 100067ec FUN_1000fa90 → FUN_1000fbc0
        scroll.levelStart(rect: info.background)
        ops.append(.fill(.back, colour: 0))                          // 1000690c FUN_10009f00
        scoreBar.levelStart(players: players)                        // 10006914..10006934 (blits off)
        ops += scoreBarDraw.levelStartOps(state: scoreBar)
        if bytePref(5) {                                             // 1000693c..10006968
            restoreInterlace = true
            setBytePref(5, false)
        } else {
            restoreInterlace = false                                 // 1000696c..10006970
        }
        ops.append(scroll.terrainBlit(interlaced: bytePref(5)))      // 10006974 FUN_10010120
        return ops
    }

    /// One iteration of the `FUN_100051a0` loop (`100058f8..10005ab0`), Phase-1 subset, in this order:
    ///
    /// 1. Begin frame `FUN_10030360` (`10030360..10030564`): [music service `FUN_10047f50`] → `FUN_100189f0`
    ///    (`10030388`, `.clearLayers`) → [console open/update/aging, `FUN_10030910` volume and F6, `GetMouse`,
    ///    Caps Lock — Phase 2] → Esc `FUN_100307c0` (`100304f4`) → if the tick flag: input read (`1003052c..
    ///    10030544`, here `keys` through the prefs `KeyTable`). Quit → `FUN_100064c0` (`1000591c`: game +0x08 =
    ///    0 only) — this pass still runs to the end and reports `sessionEnded`.
    /// 2. If the tick flag (`10005920..10005928`): appear check (`10005930..100059b8`: not appeared and game
    ///    time == `fctiwz(flli 18)` → [music `FUN_10047f90`], `FUN_1000ba70(display, 1)` = `.fade(.fromBlack,
    ///    .gameLayout)`, pref 5 restored if game +0x0f, appeared = 1); update world `FUN_10006b50` (`100059cc`)
    ///    subset: each player `FUN_10028170` (P1, P2) → score bar `FUN_100317e0` → scroll `FUN_10010000` (no
    ///    entities: pauses are never requested); [`FUN_10007170` level complete — Phase 2]; game time += 1
    ///    (`100059e0..100059f0`).
    /// 3. Draw world `FUN_10007070` (`10005a18`, every pass): [entity groups `FUN_100345f0`, blurs
    ///    `FUN_10046ae0`] → `FUN_100298c0` P1, P2 (`100070a8..100070c0`) → [tally `FUN_10007d60`, notices
    ///    `FUN_100184b0`] → score bar `FUN_10031ae0` (`100070f0`), its screen blits off when not appeared
    ///    (`FUN_10031ad0(0)` / `(1)` bracket, `100070d0..10007108`).
    /// 4. [Film overlay `10005a1c..10005aa0` — no film.] End frame `FUN_10030570(ctrl, 1, appeared)` →
    ///    `FUN_10030bc0` (`10030bec..10030dc4`): [messages, FPS counter, console] → `FUN_10018b20(0)` → terrain
    ///    blit `FUN_10010120` (pref 5) → `FUN_10018b20(1)` → [particles `FUN_10043ba0`] → `FUN_10018b20(2)` →
    ///    `.limit` when byte pref 10 → counters/divider → `FUN_1000beb0` (`.present(.gameScreen)`, controller +4
    ///    = 1) only when appeared; then the wrapper's second Esc check (`10030590`, result discarded).
    ///
    /// The loop condition (game +0x08) is tested after the pass; once it is clear, `pass` returns an empty
    /// output with `sessionEnded` set.
    public mutating func pass(keys: HeldKeys) -> PassOutput {
        guard running else { return PassOutput(sessionEnded: true) }
        var ops = pendingOps
        pendingOps = []
        let escDown = keys.held.contains(Self.escKey)
        let begin = beginFrame(escDown: escDown, ops: &ops)
        if begin.tick {
            tick(inputs: KeyTable(prefs: prefs).inputs(keys), ops: &ops)
        }
        drawWorld(ops: &ops)
        endFrame(escDown: escDown, ops: &ops)
        return PassOutput(ops: ops, ticked: begin.tick, sessionEnded: !running)
    }

    /// 1. Begin frame `FUN_10030360`, the Phase-1 subset. Input is read (step 2's `inputs`) only on a tick.
    private mutating func beginFrame(escDown: Bool, ops: inout [RenderOp]) -> FrameController.Begin {
        ops.append(.clearLayers)                                     // 10030388 FUN_100189f0
        let begin = controller.beginFrame(escDown: escDown, escHoldPref: bytePref(8))   // 100304f4 FUN_100307c0
        if begin.quit { running = false }                            // 1000591c FUN_100064c0
        return begin
    }

    /// 2. The tick: appear check, update world `FUN_10006b50` subset, game time + 1.
    private mutating func tick(inputs: [PlayerInput], ops: inout [RenderOp]) {
        if !appeared && gameTime == appearTime {                     // 10005930..1000595c
            ops.append(.fade(.fromBlack, .gameLayout))               // 10005984 FUN_1000ba70(display, 1)
            if restoreInterlace {                                    // 10005990..100059b0
                setBytePref(5, true)
                restoreInterlace = false
            }
            appeared = true                                          // 100059b4..100059b8
        }
        for i in 0..<2 {                                             // FUN_10006b50: FUN_10028170 P1, P2
            players[i].updatePhase1(now: gameTime, input: inputs[i], scroll: &scroll, scoreBar: &scoreBar)
        }
        scoreBar.update(players: players)                            // FUN_100317e0
        _ = scroll.step()                                            // FUN_10010000
        gameTime &+= 1                                               // 100059e0..100059f0
    }

    /// 3. Draw world `FUN_10007070`.
    private mutating func drawWorld(ops: inout [RenderOp]) {
        for i in 0..<2 {                                             // 100070a8..100070c0 FUN_100298c0
            ops += EntityDraw.playerOps(&players[i], hOffset: scroll.offset, floats: assets.floats)
        }
        ops += scoreBarDraw.drawOps(state: scoreBar, blitToScreen: appeared)   // 100070d0..10007108
    }

    /// 4. End frame `FUN_10030570` → `FUN_10030bc0`, then the wrapper's second Esc check.
    private mutating func endFrame(escDown: Bool, ops: inout [RenderOp]) {
        ops.append(.flushLayers(0...1))                              // 10030ca4
        ops.append(scroll.terrainBlit(interlaced: bytePref(5)))      // 10030cb4
        ops.append(.flushLayers(2...5))                              // 10030cc0
        ops.append(.flushLayers(6...15))                             // 10030cdc
        if bytePref(10) { ops.append(.limit) }                       // 10030ce4..10030d30
        if appeared { ops.append(.present(.gameScreen)) }            // 10030d94..10030dc4
        // 10030d34..10030d8c counters/divider, then 10030590 Esc (result discarded). The counters are
        // arithmetic only, so running them after the present op is emitted keeps the op order.
        controller.endFrameWrapper(escDown: escDown, escHoldPref: bytePref(8))
    }

    /// Mac virtual key code of Esc (`FUN_100307c0`).
    static let escKey: UInt16 = 0x35

    /// `FUN_10004ef0(n)`. `n` < `DeimosPrefs.bytePrefCount`, which `init` guarantees the block holds.
    func bytePref(_ n: Int) -> Bool { prefs.bytePrefs[n] != 0 }

    /// `FUN_10004ab0(n, v)`.
    mutating func setBytePref(_ n: Int, _ v: Bool) { prefs.bytePrefs[n] = v ? 1 : 0 }
}

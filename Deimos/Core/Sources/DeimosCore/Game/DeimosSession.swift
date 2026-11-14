import Foundation
import HectorResources

/// How a session starts (the `FUN_100051a0` request: level, players, film). ★ LOCKED (plan S2).
public struct SessionStart: Equatable, Sendable {
    /// 1…12, the play order of `LevelOrder`. Ignored when `film` is set (the film names its level).
    public var sector: Int
    /// 1…2. Ignored when `film` is set (the film names its player count).
    public var players: Int
    /// A replay to play back (`FUN_100069b0`): seed, level and player count come from it.
    public var film: Film?

    public init(sector: Int, players: Int, film: Film?) {
        self.sector = sector
        self.players = players
        self.film = film
    }
}

public enum SessionError: Error, Equatable, Sendable {
    /// `LevelOrder` has no level for the sector, or no `leve` definition carries the tag (a film's level not in
    /// the order is reported as sector 0).
    case noLevel(sector: Int)
    /// PermFloats 54/55 (VisibleGameWidth/Height) are not the 416 × 480 that `ScrollState` hard-codes, or the
    /// float list is too short to hold them (reported as 0).
    case visibleArea(width: Float, height: Float)
    /// The prefs' byte-pref block is shorter than `DeimosPrefs.bytePrefCount`.
    case shortBytePrefs(count: Int)
}

/// One game session of G_Game.cc (`FUN_100051a0`, engine-loop §3, level-scroll-objects §8, timing-frame §2) — Phase 2
/// (plan C18a): the whole simulation is one `GameState` (`game`); the session adds what the original keeps on
/// `FUN_100051a0`'s stack or in other modules — the frame controller (`auStack_9a0`), the console, the key table and
/// the drawers. ★ LOCKED (plan S2).
///
/// Listing reads (`disasm-review3-all.txt`):
/// - **Set-up** (`100051a0..100058a0`). The pre-seed draw `FUN_10046580(400, 2000)` at `100051d8` precedes the
///   seed and is not modelled (standing rule 5). G is fresh (`FUN_1000cd90(G, 0x180)`, +0x28 = 1 — `GameFlags()`);
///   the stack bytes p1Active / gameOverNoticed clear (`10005618`/`10005620`); `FUN_1003e510` (unit resources, no
///   model); film flag G+0x20 = start has a film (`10005670..1000568c`); the frame controller `FUN_10030190` +
///   `FUN_10030210(ctrl, film, 1, 1)` (`FrameKeys.startSession`). Film (`FUN_100069b0`): level, player count and seed
///   from the film (`FUN_10009680`), `srand(seed)`; the cursors are 0 (`FUN_10009970`). Not a film: level = the
///   start's sector's, G+0x21 = players (`10005770`), `srand(TickCount())` (`100057c8..100057d4`, here `seed`), the
///   recorder `FUN_10009710` (not modelled). Then G+0x08 = 1, +0x0a = +0x09 = +0x39 = 0, +0x18 = level
///   (`1000580c..1000582c`), +0x14 = sector `FUN_10011e30` (`10005844`), level info `FUN_10011fd0`, `FUN_10026410`
///   for P1 then P2 (`10005860..10005888`, `GameState.setupPlayer`), `FUN_1004a990(1)` (input, no op), `FUN_100064d0`.
/// - **Level start** `FUN_100064d0(film, info)` (`100064d0..10006984`), in this order: game time = 0 (`10006500`),
///   +0x29 = 0, +0x2c = game time, appeared = 0 (`10006504..10006510`); cheat counters `FUN_10007130`
///   (`10006514`); ground counts `FUN_10007150` (`10006518`); accuracy counters `FUN_10007280` (`1000651c`,
///   `TallyState.reset`); +0x0c = +0x0b, +0x0b = 0 (`10006524..10006544`); [`FUN_1003e510` unit resources]; levels
///   started == 0 → the level of +0x18 (`10006564..10006588`; the next-level branch `10006594..1000661c` is Phase 3);
///   [the unregistered limit `1000663c..10006678` — this is the registered game]; levels started += 1
///   (`1000667c..10006684`); [level `none` → Phase 3]; +0x14 = sector (`100066e8`); [`FUN_1002b3a0` weapon resource
///   preload; the terrain buffer `FUN_10009d70` (`1000674c`), superseded by the map load's resize]; not a film and
///   the music not paused (`FUN_10047f80`) → `FUN_10048120(0)` stop + `FUN_10047f90('ammu', 1, 0)`
///   (`1000676c..10006788` — ◇ stand-in 4, emitted as `.play(ammu, loop: true)`: `FUN_10047f90` itself stops any
///   playing music first, so the explicit stop is subsumed); `FUN_100269a0` P1 then P2 (`10006798..100067b8`,
///   `GameState.playerLevelStart`: P1's `R(400, 2000)` at `10026a9c`); not a film → `FUN_10048120(0)`
///   (`100067c4..100067c8`, `.stop`); then `.level(int pref 1)` — the engine starts at level 100, so the session
///   sends the real one (seam, no original call); messages reset `FUN_1002db50` (`100067d0`); debris reset
///   `FUN_1002a660` (`100067d8`); particles reset `FUN_100432d0` (`100067e0`); the scroll's level start
///   `FUN_1000fa90` (`100067ec`) incl. `FUN_1000fbc0` = `.loadTerrain` and the media mask (`_DAT_100e0138`, scale
///   `_DAT_100e0134` = map width / mask width); `FUN_10032e60` (`100067f8`, `levelStartEntities`: the entity reset
///   and the pending list `FUN_10035900`); [`FUN_10012170` frees the object list]; blurs reset `FUN_100467c0`
///   (`1000680c`); [`FUN_1004a950` input reset]; notice reset `FUN_10018130` (`1000681c`); [`FUN_100189f0` clear
///   layers (`10006824`) — nothing is queued yet: no op]; the load pass `FUN_1000fa10` (`1000682c`); the
///   `Notice_Level_NN` request (PermObjectID sector + 9, `no01` at sector 1) at (flli 54 × 0.5, flli 55 × 0.5) =
///   (208, 240) unless `none` (`1000683c..100068f4`); back ← black `FUN_10009f00` (`1000690c`); the score bar's
///   level start with its screen blits off (`FUN_10031ad0(0)`, `FUN_10031400`, `FUN_10031ad0(1)`,
///   `10006914..10006934`); byte pref 5 set → +0x0f = 1 and pref 5 cleared, else +0x0f = 0 (`1000693c..10006970`);
///   the first terrain blit `FUN_10010120` (`10006974`); [`FUN_1000c2a0` window].
public struct DeimosSession: Sendable {
    public let assets: DeimosAssets
    public let start: SessionStart
    /// The whole simulation: G, the players, the world, the effects, the cues (`GameState`). Tests may poke it.
    public internal(set) var game: GameState
    /// The stack-local frame controller (`auStack_9a0`).
    public private(set) var controller: FrameController
    /// G_Console.cc's console (the session's: `GameState` holds no session-only state).
    public private(set) var console: Console
    /// The level info `FUN_10011fd0` filled (`auStack_7e0`): the music (+0x27c) the appear plays.
    public let levelInfo: LevelDefinition
    /// The level start's ops, handed out by the first `pass`.
    private var pendingOps: [RenderOp] = []
    /// The shell requests handed out by the first `pass`: `.hideCursor` — ◇ the front end's `HideCursor` just
    /// before the game (`FUN_100234d0` step 2, `10023550 bl FUN_1000b6e0`; front-end.md §3). `FUN_100051a0` itself
    /// never touches the cursor; the session stands in for the front end's start-game path until Phase 4. The
    /// matching `InitCursor` after the game (`100238b4` / `10023ad0`) belongs to the menu, which the ◇ restart
    /// replaces with an immediate new session (which hides it again), so no pass emits `.showCursor`.
    private var pendingRequests: [ShellRequest] = [.hideCursor]
    /// The prefs' key table (`KeyTable`), built once — `setBytePref` never changes it.
    private let keyTable: KeyTable
    private let scoreBarDraw: ScoreBarDraw
    private let text: TextLayout
    /// `fctiwz(PermFloat 18)`: the game time at which the game appears (`10005930..1000595c`).
    private let appearTime: Int32

    // MARK: - Forwarding accessors (standing rule 7: the Phase-1 properties stay)

    /// The prefs (byte prefs change in play: F6, the FPS monitor, the pref-5 dance).
    public var prefs: DeimosPrefs { game.prefs }
    /// `_DAT_100e032c`.
    public var rng: MSLRandom { game.rng }
    /// G+0x00 / G+0x04.
    public var players: [Player] { game.players }
    public var scoreBar: ScoreBarState { game.scoreBar }
    public var scroll: ScrollState { game.scroll }
    /// G+0x18: the current level tag.
    public var level: FourCC { game.flags.level }
    /// G+0x14: the current sector — the one sector source (C18a), set from the film or the start.
    public var sector: Int { Int(game.flags.sector) }
    /// G+0x1c: game time (logic ticks since level start).
    public var gameTime: Int32 { game.flags.gameTime }
    /// G+0x38: the game has appeared (fade in done; presents and score-bar screen blits on).
    public var appeared: Bool { game.flags.appeared }
    /// G+0x08: the session is running (the `while` condition).
    public var running: Bool { game.flags.running }
    /// G+0x0f: byte pref 5 (interlacing) was suspended at level start, restore at appear.
    public var restoreInterlace: Bool { game.flags.restoreInterlace }

    /// `FUN_100051a0`'s set-up, then the level start `FUN_100064d0` (see the type's comment). `seed` is
    /// `TickCount()` at `100057c8` (ignored for a film, whose seed is used); `ticks` is the `TickCount()` the frame
    /// controller's FPS monitor starts from (`FUN_100305e0` inside `FUN_10030210`).
    public init(assets: DeimosAssets, prefs: DeimosPrefs, start: SessionStart, seed: UInt32,
                ticks: UInt32 = 0) throws {
        // ScrollState hard-codes PermFloats 54/55 (VisibleGameWidth/Height); the pass reads 18 and 32 too.
        let f = assets.floats
        guard f.count > 55, f[54] == Float(ScrollState.visibleWidth), f[55] == Float(ScrollState.visibleHeight) else {
            throw SessionError.visibleArea(width: f.count > 54 ? f[54] : 0, height: f.count > 55 ? f[55] : 0)
        }
        guard prefs.bytePrefs.count >= DeimosPrefs.bytePrefCount else {
            throw SessionError.shortBytePrefs(count: prefs.bytePrefs.count)
        }
        self.assets = assets
        self.start = start
        scoreBarDraw = try ScoreBarDraw(assets: assets)
        text = try TextLayout(assets: assets)
        appearTime = EntityDraw.fctiwz(f[18])
        keyTable = KeyTable(prefs: prefs)

        // Level, sector, players: from the film (FUN_100069b0 → FUN_10009680) or the start (10005758..10005770).
        let tag: FourCC
        let sector: Int
        let players: Int
        if let film = start.film {
            tag = film.level
            guard let s = assets.levelOrder.sector(of: tag) else { throw SessionError.noLevel(sector: 0) }
            sector = s                                                // 10005830 FUN_10011e30
            players = film.playerCount
        } else {
            tag = assets.levelOrder.level(sector: start.sector)
            sector = start.sector
            players = start.players
        }
        guard tag != .none, let info = assets.definitions.levels.first(where: { $0.id == tag }) else {
            throw SessionError.noLevel(sector: start.film == nil ? start.sector : 0)
        }
        levelInfo = info

        // srand: the film's seed (FUN_100069b0 → FUN_10055400) or TickCount (100057d4).
        var g = GameState(assets: assets, prefs: prefs, seed: start.film?.seed ?? seed)
        g.flags.filmPlaying = start.film != nil                      // 10005670..1000568c (G+0x20)
        g.film = start.film.map(FilmCursor.init(film:))              // FUN_100069b0: cursors 0 (FUN_10009970)
        g.flags.numPlayers = UInt8(truncatingIfNeeded: players)      // FUN_10009680 / 10005770 (G+0x21)

        // Frame controller: FUN_10030190 + FUN_10030210(ctrl, film, 1, 1) (10005690..100056ac).
        var c = FrameController(fpsMaxRate: EntityDraw.fctiwz(f[32]))
        var con = try Console(assets: assets)
        FrameKeys.startSession(controller: &c, console: &con, game: &g, filmPlayback: start.film != nil,
                               gameScreenLayout: true, autoInterlaceAllowed: true, ticks: ticks)

        g.flags.running = true                                       // 1000580c..10005814
        g.flags.noPlayerAlive = false                                // 10005820
        g.flags.levelComplete = false                                // 10005824
        g.flags.levelEnding = false                                  // 10005828
        g.flags.level = tag                                          // 1000582c
        g.flags.sector = Int32(sector)                               // 10005844
        for i in 0..<2 {                                             // 10005860..10005888 FUN_10026410
            try g.setupPlayer(i)
        }
        game = g
        controller = c
        console = con
        pendingOps = try levelStart(info)                            // 100058a0 FUN_100064d0
    }

    /// `FUN_100064d0(film, info)` — the level start, in the order of the type's comment; returns its ops.
    private mutating func levelStart(_ info: LevelDefinition) throws -> [RenderOp] {
        var ops: [RenderOp] = []
        let film = game.flags.filmPlaying
        game.flags.gameTime = 0                                      // 10006500
        game.flags.levelEndHandled = false                           // 10006504
        game.flags.levelEndTime = game.flags.gameTime                // 1000650c
        game.flags.appeared = false                                  // 10006510
        game.flags.cheatLife = 0; game.flags.cheatFunds = 0          // 10006514 FUN_10007130
        game.flags.cheatScore = 0; game.flags.cheatShields = 0; game.flags.cheatMult = 0
        game.flags.groundCreated = 0                                 // 10006518 FUN_10007150
        game.flags.groundDestroyed = 0
        game.tally.reset()                                           // 1000651c FUN_10007280
        game.flags.rewardArmed = false                               // 10006524..10006528
        if game.flags.perfectThisLevel {                             // 1000652c..10006538
            game.flags.perfectThisLevel = false                      // 1000653c
            game.flags.rewardArmed = true                            // 10006544
        }
        game.flags.levelsStarted &+= 1                               // 1000667c..10006684
        // 100066e8: +0x14 = sector — the set-up's value (levels started was 0, the level of +0x18).
        if !film {                                                   // 10006750..10006768 (FUN_10047f80: not paused)
            game.cues.music.append(.play(FourCC("ammu")!, loop: true))   // 1000676c..10006788 ◇ stand-in 4
        }
        for i in 0..<2 {                                             // 10006798..100067b8 FUN_100269a0
            game.playerLevelStart(i)
        }
        if !film {
            game.cues.music.append(.stop)                            // 100067c4..100067c8 FUN_10048120(0)
        }
        game.cues.music.append(.level(game.prefs.intPrefs[1]))       // seam: the engine's level (int pref 1)
        game.messages.reset()                                        // 100067d0 FUN_1002db50
        game.debris.levelReset()                                     // 100067d8 FUN_1002a660
        game.particles.levelReset()                                  // 100067e0 FUN_100432d0
        ops.append(.loadTerrain(image: info.backgroundImage))        // 100067ec FUN_1000fa90 → FUN_1000fbc0
        game.mask = try Self.loadMask(info, assets: assets)          // FUN_1000fbc0: _DAT_100e0138 / _DAT_100e0134
        game.scroll.levelStart(rect: info.background)                // FUN_1000fa90
        game.levelStartEntities(level: info)                         // 100067f8 FUN_10032e60 (+ FUN_10035900)
        game.blurs.levelReset()                                      // 1000680c FUN_100467c0
        game.notice.reset()                                          // 1000681c FUN_10018130
        game.spawnLoadPassLevelObjects()                             // 1000682c FUN_1000fa10
        let notice = assets.objects[Int(game.flags.sector) + 9]      // 10006830..10006848 FUN_100201f0(+0x14 + 9)
        if notice != .none {
            let half: Float = 0.5                                    // *(0x100d6354 + 8)
            let x: Float = assets.floats[54] * half                  // 1000688c..100068c4
            let y: Float = assets.floats[55] * half                  // 100068c8..100068ec
            game.spawn(SpawnRequest(unit: notice, x: x, y: y))       // 100068f4 FUN_10033220(req, 0, 0)
        }
        ops.append(.fill(.back, colour: 0))                          // 1000690c FUN_10009f00
        game.scoreBar.levelStart(players: game.players, sector: game.flags.sector)   // 10006914..10006934 (blits off)
        ops += scoreBarDraw.levelStartOps(state: game.scoreBar)
        if bytePref(5) {                                             // 1000693c..10006968
            game.flags.restoreInterlace = true
            setBytePref(5, false)
        } else {
            game.flags.restoreInterlace = false                      // 1000696c..10006970
        }
        ops.append(game.scroll.terrainBlit(interlaced: bytePref(5)))   // 10006974 FUN_10010120
        return ops
    }

    /// `FUN_1000fbc0`'s media mask: `info.mediaMask` (`+0x280`) as an im16 TGA, row-major top-down
    /// (`cells.count == width × height`, the index rule of `MediaMask.isWater`); `_DAT_100e0134` = map width / mask
    /// width (`divw`), where the map width is the background rect's right edge (the dimension check at `1000fbc0`
    /// requires the map image to match it).
    static func loadMask(_ info: LevelDefinition, assets: DeimosAssets) throws -> MediaMask {
        let type = FourCC("im16")!
        guard let r = assets.index.record(type: type, id: info.mediaMask) else {
            throw DeimosAssetsError.missingTag(type: "im16", id: info.mediaMask.description)
        }
        let tga = try TGAImage(data: assets.index.data(for: r))
        let w = Int32(tga.width), h = Int32(tga.height)
        return MediaMask(width: w, height: h, cells: tga.pixels, scale: w > 0 ? info.background.right / w : 0)
    }

    /// One iteration of the `FUN_100051a0` loop (`100058b0..10005ab8`), in this order:
    ///
    /// 0. [The unregistered limit `100058b0..100058f4`, before the begin frame: not yet armed, not a film, game time
    ///    == the pre-seed draw `FUN_10046580(400, 2000)` (`100051d8`), the registration byte `-0x6234(r2)`
    ///    (`FUN_10010f90`, `100051f8`) clear and the level outside the demo four (`FUN_10011b30`) → arm the cut-off
    ///    (`-0x6233(r2)` = 1) — this is the registered game: unmodelled.]
    /// 1. Begin frame `FUN_10030360` (`10005904`): [music service] → `FUN_100189f0` (`10030388`, `.clearLayers`)
    ///    → the console, message aging, the volume keys and F6, Caps Lock, Esc, the tick flag's input
    ///    (`FrameKeys.beginFrame`); G+0x30 = its result (`10005910`); quit → `FUN_100064c0` (`1000591c`: G+0x08 = 0
    ///    only) — this pass still runs to the end and reports `sessionEnded`.
    /// 2. If the tick flag (`10005920..10005928`): the appear check (`10005930..100059b8`: not appeared and game time
    ///    == `fctiwz(flli 18)` → not a film: `FUN_10047f90(info+0x27c, 1, 0)` = `.play(music, loop: true)`
    ///    (`10005960..10005974`); `FUN_1000ba70(display, 1)` = `.fade(.fromBlack, .gameLayout)` (`10005984`);
    ///    pref 5 restored if +0x0f (`10005990..100059b0`); appeared = 1); the world update `FUN_10006b50`
    ///    (`100059cc`, `GameState.updateWorld`; the console-open withholding from begin frame); level complete
    ///    `FUN_10007170` (`100059dc`, `levelCompleteStep`); game time += 1 (`100059e0..100059f0`); [the unregistered
    ///    limit `100059f4..10005a10`].
    /// 3. The tick's render ops (`GameState.tickOps`, terrain stamps made during the update) are drained, then the
    ///    draw world `FUN_10007070` (`10005a18`, every pass): entity groups `FUN_100345f0` (`1000708c`) → blurs
    ///    `FUN_10046ae0` (`10007094`) → `FUN_100298c0` P1, P2 incl. the coin-tally text (`100070a8..100070c0`) → the
    ///    accuracy tally text `FUN_10007d60` (`100070c4`) → the notice `FUN_100184b0` (`100070c8`) → the score bar
    ///    `FUN_10031ae0` (`100070f0`), its screen blits off when not appeared (`100070d0..10007108`).
    /// 4. A film (`10005a1c..10005aa0`): `FUN_10048e60` (the mouse button — ◇ stand-in 8, `HeldKeys` has no mouse)
    ///    or `FUN_10009750` (P1's cursor > frames) → `FUN_100064c0` and no banner (`10005a48 → 10005aa4`); else the
    ///    REPLAY banner (`10005a50..10005a9c`: format 0x26, GameString 9, +0x10c = 15, +0x10d = 1, +0x110 = 0,
    ///    `FUN_1000d380(rec, 0)`).
    /// 5. End frame `FUN_10030570(ctrl, 1, appeared)` (`10005ab0`) → `FUN_10030bc0` (`10030bec..10030dc4`): messages
    ///    `FUN_1002dea0` (`10030bec`) → the FPS counter (byte pref 9, `10030bf4..10030c90`) → the console
    ///    `FUN_1002d410` (`10030c98`) → `FUN_10018b20(0)` layers 0–1 (`10030ca4`) → the terrain blit `FUN_10010120`
    ///    (`10030cb4`) → `FUN_10018b20(1)` layers 2–5 (`10030cc0`) → the particles `FUN_10043ba0` (`10030cd0`) →
    ///    `FUN_10018b20(2)` layers 6–15 (`10030cdc`) → `.limit` when byte pref 10 (`10030ce4..10030d24`) →
    ///    counters / divider (`10030d28..10030d8c`) → when appeared the present by +4 (`10030d90..10030dc4`:
    ///    `FUN_1000beb0` game screen, `FUN_1000bc60` full screen); then the wrapper (`FrameKeys.endFrameWrapper`):
    ///    Esc again (discarded), the pause screen (`FUN_10030870`: halt, `gaso 8`, music pause, `.pauseWait`,
    ///    the resume after the wait), the FPS monitor.
    /// 6. The loop condition G+0x08 (`10005ab8..10005ac0`). Once clear: `FUN_1000c440(window)` (`10005ac4..10005ac8`
    ///    → `FUN_1000abd0(window, 0)`: window +0xe = 0, a byte nothing reads — unmodelled); then, not a film
    ///    (`10005ad0`): `FUN_100476a0` (halt every effect, `10005ad8`) and `FUN_10048120(0)` (music stop,
    ///    `10005ae4`) — at the end of this pass's cues.
    ///
    /// **Cues: one holder.** `game.cues` collects every cue of the pass (and of the level start, before the first
    /// pass); the pass moves them into its output and clears them. The pause screen's resume (`PauseScreen
    /// .musicAfterWait`) is left in `game.cues` for the next pass, first in its music (that pass begins only after
    /// the host's wait — at most one frame late). `FrameKeysResult.volume` never becomes a gain cue (Ben, 2026-10-07).
    ///
    /// **Pause and session end in one pass** (Caps Lock and, say, Esc). The original runs the pause wrapper to the
    /// end — halt, `gaso 8`, music pause, the wait, the resume (`10022fb4`) — and only then leaves the loop for the
    /// halt and the stop (`10005ad8`, `10005ae4`). There is no next pass, so the resume goes into this pass's music
    /// ahead of the stop (`[… .pause, .resume, .stop]`), and the halt index stays the pause's, so `gaso 8` is not cut
    /// in the same apply. ◇ Inexact until H2 (the real wait): `PassOutput` holds one halt, so the session end's halt
    /// after the wait is not expressed (`gaso 8` plays out instead of being cut when Caps Lock comes up), and the
    /// resume and the stop reach the audio with the pass's other cues, before the host's wait rather than after it
    /// (the music is silent either way: paused in the original, stopped here). A film never pauses (`10030408..
    /// 1003041c`), and still skips the halt and the stop (`10005ad0`).
    ///
    /// The first pass also returns the level start's ops (before its own) and `.hideCursor`. Once the session has
    /// ended, `pass` returns an empty output with `sessionEnded` set. `ticks` = `TickCount()` (the FPS monitor's clock).
    public mutating func pass(keys: HeldKeys, ticks: UInt32) -> PassOutput {
        guard game.flags.running else { return PassOutput(sessionEnded: true) }
        var ops = pendingOps
        pendingOps = []
        let requests = pendingRequests
        pendingRequests = []
        let film = game.flags.filmPlaying

        // 1. Begin frame.
        ops.append(.clearLayers)                                     // 10030388 FUN_100189f0
        let begin = FrameKeys.beginFrame(controller: &controller, console: &console, game: &game, keys: keys)
        game.flags.framesPresented = begin.framesPresented           // 10005910
        if begin.quit { game.flags.running = false }                 // 1000591c FUN_100064c0

        // 2. The tick.
        if begin.tick {                                              // 10005920..10005928
            tick(keys: keys, withheld: begin.inputWithheld, ticks: ticks, ops: &ops)
        }

        // 3. The tick's ops, then the draw world.
        ops += game.tickOps
        game.tickOps = []
        drawWorld(ops: &ops)

        // 4. The film overlay.
        if film {                                                    // 10005a1c..10005a20
            if game.film?.finished ?? true {                         // 10005a24..10005a44 (FUN_10048e60: ◇ no mouse)
                game.flags.running = false                           // 10005a48 FUN_100064c0
            } else {
                var banner = TextRequest(format: assets.formats[0x26], text: assets.gameStrings[9])   // 10005a50..10005a74
                banner.drawNow = false                               // 10005a7c..10005a84 (+0x110)
                banner.layer = 15                                    // 10005a80..10005a8c (+0x10c)
                banner.keepTemplateClip = true                       // 10005a88..10005a98 (+0x10d)
                ops += text.draw(banner).map { .draw($0) }           // 10005a9c FUN_1000d380(rec, 0)
            }
        }

        // 5. End frame.
        let pause = endFrame(keys: keys, ticks: ticks, ops: &ops)

        // 6. The loop condition; the session end's audio (not a film). A pause in a pass that also ends the session
        // ran to completion inside the end frame (10022fb4, after the wait) before the loop test: its resume goes
        // here, ahead of the stop, and its halt index stands (see `pass`'s comment, "Pause and session end").
        if let pause, !game.flags.running {
            game.cues.music += pause.musicAfterWait                  // 10022fb4 FUN_10048220(0), after the wait
        }
        if !game.flags.running && !film {                            // 10005ab8..10005ad4
            if pause == nil { game.cues.haltEffects() }              // 10005ad8 FUN_100476a0
            game.cues.music.append(.stop)                            // 10005ae0..10005ae4 FUN_10048120(0)
        }
        let cues = game.cues
        game.cues = CueBuffer()
        if let pause, game.flags.running {
            game.cues.music = pause.musicAfterWait                   // 10022fb4 FUN_10048220(0), after the wait
        }
        return PassOutput(ops: ops, sounds: cues.sounds, music: cues.music, requests: requests, ticked: begin.tick,
                          sessionEnded: !game.flags.running, haltEffectsAt: cues.haltEffectsAt)
    }

    /// The Phase-1 entry point, kept for the driver (standing rule 7): `pass(keys:ticks:)` with a TickCount of 0
    /// (the FPS monitor's window never closes).
    public mutating func pass(keys: HeldKeys) -> PassOutput { pass(keys: keys, ticks: 0) }

    /// 2. The tick: the appear check, the world update `FUN_10006b50`, level complete `FUN_10007170`, game time + 1.
    private mutating func tick(keys: HeldKeys, withheld: Bool, ticks: UInt32, ops: inout [RenderOp]) {
        if !game.flags.appeared && game.flags.gameTime == appearTime {   // 10005930..1000595c
            if !game.flags.filmPlaying {                             // 10005960..10005964
                game.cues.music.append(.play(levelInfo.music, loop: true))   // 10005968..10005974 FUN_10047f90
            }
            ops.append(.fade(.fromBlack, .gameLayout))               // 10005984 FUN_1000ba70(display, 1)
            if game.flags.restoreInterlace {                         // 10005990..100059b0
                setBytePref(5, true)
                game.flags.restoreInterlace = false
            }
            game.flags.appeared = true                               // 100059b4..100059b8
        }
        game.updateWorld(inputs: keyTable.inputs(keys), inputWithheld: withheld)   // 100059cc FUN_10006b50
        game.levelCompleteStep(controller: &controller, console: &console, ticks: ticks)   // 100059dc FUN_10007170
        game.flags.gameTime &+= 1                                    // 100059e0..100059f0
    }

    /// 3. The draw world `FUN_10007070`.
    private mutating func drawWorld(ops: inout [RenderOp]) {
        let h = game.scroll.offset                                   // FUN_100100a0
        let floats = assets.floats
        ops += game.groupCommands(hOffset: h).map { .draw($0) }      // 1000708c FUN_100345f0
        ops += game.blurs.drawCommands(hOffset: h, floats: floats).map { .draw($0) }   // 10007094 FUN_10046ae0
        for i in 0..<2 {                                             // 100070a8..100070c0 FUN_100298c0
            let coin = game.tally.coin[i]
            ops += EntityDraw.playerCommands(&game.players[i], hOffset: h, floats: floats, coinTally: coin,
                                             text: text).map { .draw($0) }
        }
        ops += game.tallyTextCommands(text: text).map { .draw($0) }  // 100070c4 FUN_10007d60
        ops += game.notice.drawCommands(text: text, formats: assets.formats).map { .draw($0) }   // 100070c8 FUN_100184b0
        ops += scoreBarDraw.drawOps(state: game.scoreBar, blitToScreen: game.flags.appeared)   // 100070d0..10007108
    }

    /// 5. End frame `FUN_10030570(ctrl, 1, appeared)` → `FUN_10030bc0`, then the wrapper's Esc, pause screen and FPS
    /// monitor. Returns the pause screen when it ran (its `.pauseWait` is already the last op).
    private mutating func endFrame(keys: HeldKeys, ticks: UInt32, ops: inout [RenderOp]) -> PauseScreen? {
        ops += game.messages.drawCommands(text: text, formats: assets.formats).map { .draw($0) }   // 10030bec FUN_1002dea0
        if let fps = FrameKeys.fpsCounterRequest(controller: controller, prefs: game.prefs,
                                                 formats: assets.formats) {   // 10030bf4..10030c88
            ops += text.draw(fps).map { .draw($0) }                  // 10030c90 FUN_1000d380
        }
        ops += console.drawCommands(text: text, formats: assets.formats).map { .draw($0) }   // 10030c98 FUN_1002d410
        ops.append(.flushLayers(0...1))                              // 10030ca4 FUN_10018b20(0)
        ops.append(game.scroll.terrainBlit(interlaced: bytePref(5))) // 10030cb4 FUN_10010120
        ops.append(.flushLayers(2...5))                              // 10030cc0 FUN_10018b20(1)
        ops.append(.particles(game.particles.stamps(hOffset: game.scroll.offset)))   // 10030cd0 FUN_10043ba0
        ops.append(.flushLayers(6...15))                             // 10030cdc FUN_10018b20(2)
        if bytePref(10) { ops.append(.limit) }                       // 10030ce4..10030d24
        // 10030d28..10030d8c counters / divider: arithmetic only, run by the wrapper below (`FrameController.endFrame`),
        // which keeps the op order.
        if game.flags.appeared {                                     // 10030d90
            ops.append(.present(controller.gameScreenLayout ? .gameScreen : .fullScreen))   // 10030d98..10030dc4
        }
        let pause = FrameKeys.endFrameWrapper(controller: &controller, console: &console, game: &game, keys: keys,
                                              ticks: ticks)          // 10030584..100305bc
        if let pause { ops.append(.pauseWait(pause.present)) }       // 10022ef0 (the host waits, then presents)
        return pause
    }

    /// Mac virtual key code of Esc (`FUN_100307c0`).
    static let escKey: UInt16 = 0x35

    /// `FUN_10004ef0(n)`. `n` < `DeimosPrefs.bytePrefCount`, which `init` guarantees the block holds.
    func bytePref(_ n: Int) -> Bool { game.prefs.bytePrefs[n] != 0 }

    /// `FUN_10004ab0(n, v)`.
    mutating func setBytePref(_ n: Int, _ v: Bool) { game.prefs.bytePrefs[n] = v ? 1 : 0 }
}

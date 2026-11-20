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
    /// The music is already playing as the session starts (`FUN_10047f80`, `DAT_100e02a0`: a stream exists and is
    /// not paused) — the level select's `ammu` (plan Phase 4 correction; ruling: the level select passes true).
    /// The first level start then skips its stop-and-play of `ammu` (`10006754..1000678c`) and only stops
    /// (`100067c4..100067c8`). Default false: no music playing, the branch every earlier phase built (stand-in 4).
    /// Not read for a film (the whole branch is skipped). Phase 4 (plan S1a).
    public var musicAlreadyPlaying: Bool

    public init(sector: Int, players: Int, film: Film?, musicAlreadyPlaying: Bool = false) {
        self.sector = sector
        self.players = players
        self.film = film
        self.musicAlreadyPlaying = musicAlreadyPlaying
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
///   recorder `FUN_10009710(film, level, G+0x21, seed)` (`100057ec`, `GameState.recorder`, Phase 4 S5). Then
///   G+0x08 = 1, +0x0a = +0x09 = +0x39 = 0, +0x18 = level (`1000580c..1000582c`), +0x14 = sector `FUN_10011e30` (`10005844`), level info `FUN_10011fd0`, `FUN_10026410`
///   for P1 then P2 (`10005860..10005888`, `GameState.setupPlayer`), `FUN_1004a990(1)` (input, no op), `FUN_100064d0`.
/// - **Level start** `FUN_100064d0(film, info)` (`100064d0..10006984`) — split in two (plan LT, ruling 5): its STATE
///   part is `GameState.levelStart(film:)`, which `levelCompleteStep` also calls for the next sector; its DRAWING
///   part (the `.loadTerrain`, the fill, the score bar's level-start ops, the first terrain blit) is
///   `levelStartOps`, emitted by the session in the pass that started the level. In this order: game time = 0
///   (`10006500`), +0x29 = 0, +0x2c = game time, appeared = 0 (`10006504..10006510`); cheat counters `FUN_10007130`
///   (`10006514`); ground counts `FUN_10007150` (`10006518`); accuracy counters `FUN_10007280` (`1000651c`,
///   `TallyState.reset`); +0x0c = +0x0b, +0x0b = 0 (`10006524..10006544`); [`FUN_1003e510` unit resources]; levels
///   started == 0 → the level of +0x18 (`10006564..10006588`), else sector(+0x18) + 1, `none` above the order's 12
///   (`10006594..10006628`), the level info reloaded (`100065dc`); [the unregistered limit `1000663c..10006678` —
///   this is the registered game]; levels started += 1 (`1000667c..10006684`); level `none` → music resume, running
///   = 0, return (`10006688..100066c8`); +0x14 = sector (`100066e8`); [`FUN_1002b3a0` weapon resource
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
    /// The level info `FUN_10011fd0` filled (`auStack_7e0`): the music (+0x27c) the appear plays. The level start
    /// replaces it (`100065dc`); stored in the game state (`GameState.levelInfo`), forwarded here (standing rule 7).
    public var levelInfo: LevelDefinition { game.levelInfo }
    /// The level start's ops, handed out by the first `pass`.
    private var pendingOps: [RenderOp] = []
    /// The prefs' key table (`KeyTable`), built once — `setBytePref` never changes it.
    private let keyTable: KeyTable
    private let scoreBarDraw: ScoreBarDraw
    private let text: TextLayout
    /// `fctiwz(PermFloat 18)`: the game time at which the game appears (`10005930..1000595c`).
    private let appearTime: Int32
    /// The sector the session started at (`10005844`: the film's level's or the start's) — `SessionResult`.
    private let startSector: Int
    /// The session's result, once it has ended (Phase 4, plan S1a): built by the pass that ended it, which also
    /// carries it (`PassOutput.result`).
    public private(set) var result: SessionResult?

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
    /// controller's FPS monitor starts from (`FUN_100305e0` inside `FUN_10030210`). `levels` = an earlier session's
    /// loaded `game.levels` over the same `assets` (a restart): reused as is, skipping the decode of the twelve masks;
    /// nil (or empty) → loaded and validated here.
    public init(assets: DeimosAssets, prefs: DeimosPrefs, start: SessionStart, seed: UInt32,
                ticks: UInt32 = 0, levels: LevelSet? = nil) throws {
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
        guard tag != .none, assets.definitions.levels.contains(where: { $0.id == tag }) else {
            throw SessionError.noLevel(sector: start.film == nil ? start.sector : 0)
        }
        startSector = sector

        // srand: the film's seed (FUN_100069b0 → FUN_10055400) or TickCount (100057d4).
        var g = GameState(assets: assets, prefs: prefs, seed: start.film?.seed ?? seed)
        if let levels, !levels.isEmpty {                             // a restart: the ended session's load
            g.levels = levels
        } else {
            try g.loadLevels()                                       // plan LT: every level start in a pass is safe
        }
        g.flags.filmPlaying = start.film != nil                      // 10005670..1000568c (G+0x20)
        g.film = start.film.map(FilmCursor.init(film:))              // FUN_100069b0: cursors 0 (FUN_10009970)
        g.flags.numPlayers = UInt8(truncatingIfNeeded: players)      // FUN_10009680 / 10005770 (G+0x21)
        if start.film == nil {                                       // 10005634 FUN_10009390 + 100057ec FUN_10009710
            g.recorder = FilmRecorder(seed: seed, level: tag, players: Int(g.flags.numPlayers))
        }

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
        game.levelStart(film: start.film != nil,                     // 100058a0 FUN_100064d0: the state part
                        musicPlaying: start.musicAlreadyPlaying)     // 1000675c FUN_10047f80
        pendingOps = levelStartOps()                                 // … and its drawing part
    }

    /// `FUN_100064d0`'s DRAWING part (plan LT, ruling 5), read from the state its state part
    /// (`GameState.levelStart`) left: the scroll's level start loads the map (`100067ec FUN_1000fa90` →
    /// `FUN_1000fbc0`); back ← black (`1000690c FUN_10009f00`); the score bar's level start with its screen blits off
    /// (`10006914..10006934`: `FUN_10031ad0(0)`, `FUN_10031400`, `FUN_10031ad0(1)`); the first terrain blit with byte
    /// pref 5 as the pref-5 dance left it (`10006974 FUN_10010120`). No state op between them makes a render op (the
    /// level start's spawns stamp nothing), so emitting them together keeps the original's op order.
    private func levelStartOps() -> [RenderOp] {
        var ops: [RenderOp] = [.loadTerrain(image: game.levelInfo.backgroundImage)]   // 100067ec
        ops.append(.fill(.back, colour: 0))                          // 1000690c
        ops += scoreBarDraw.levelStartOps(state: game.scoreBar)      // 10006914..10006934
        ops.append(game.scroll.terrainBlit(interlaced: bytePref(5))) // 10006974
        return ops
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
    /// in the same apply. `PassOutput` holds that one halt; the host expresses the rest (H2, `DeimosDriver`): it
    /// sends the cues through the `.pause` when the pass begins, the resume when its wait sees Caps Lock up, and the
    /// session end's halt (index 0, cutting `gaso 8`) and stop as a second apply once the pass's ops are done. Read
    /// without a host, the pass's `music` alone still carries them in one list. A film never pauses
    /// (`10030408..1003041c`), and still skips the halt and the stop (`10005ad0`).
    ///
    /// The first pass also returns the level start's ops (before its own). No pass makes a shell request:
    /// `FUN_100051a0` never touches the cursor — the front end hides it before the game (`FUN_100234d0` step 2,
    /// `10023550`) and shows it after (Phase 4 S1b, grounding D S17). Once the session has ended, `pass` returns an
    /// empty output with `sessionEnded` set. `ticks` = `TickCount()` (the FPS monitor's clock).
    public mutating func pass(keys: HeldKeys, ticks: UInt32) -> PassOutput {
        guard game.flags.running else { return PassOutput(sessionEnded: true) }
        var ops = pendingOps
        pendingOps = []
        let film = game.flags.filmPlaying

        // 1. Begin frame.
        ops.append(.clearLayers)                                     // 10030388 FUN_100189f0
        let begin = FrameKeys.beginFrame(controller: &controller, console: &console, game: &game, keys: keys)
        game.flags.framesPresented = begin.framesPresented           // 10005910
        // The rule that clears G+0x08 first in this pass (`SessionResult.End`).
        var end: SessionResult.End?
        if begin.quit {
            game.flags.running = false                               // 1000591c FUN_100064c0
            end = .escape
        }

        // 2. The tick.
        var levelStarted = false
        if begin.tick {                                              // 10005920..10005928
            levelStarted = tick(keys: keys, withheld: begin.inputWithheld, ticks: ticks, ops: &ops)
        }
        if end == nil && !game.flags.running {
            // The tick cleared it: a film's level end (`100071e8..100071f8`) or lost pilots end the film; else the
            // campaign end finds level `none` (`10006620..100066c8`); else the game over.
            end = film ? .filmEnded : (game.flags.level == .none ? .finale : .gameOver)
        }

        // 3. The tick's ops (its terrain stamps, then a transition's fade to black and layer clear), the drawing part
        // of a level start the tick ran (plan LT), then the draw world.
        ops += game.tickOps
        game.tickOps = []
        if levelStarted { ops += levelStartOps() }                  // 10007254..1000725c → FUN_100064d0
        drawWorld(ops: &ops)

        // 4. The film overlay.
        if film {                                                    // 10005a1c..10005a20
            if game.film?.finished ?? true {                         // 10005a24..10005a44 (FUN_10048e60: ◇ no mouse)
                game.flags.running = false                           // 10005a48 FUN_100064c0
                if end == nil { end = .filmEnded }
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
        let fadeMark = game.fadeToBlackCues
        game.fadeToBlackCues = nil
        if let pause, game.flags.running {
            game.cues.music = pause.musicAfterWait                   // 10022fb4 FUN_10048220(0), after the wait
        }
        if !game.flags.running {                                     // 10005b38..10005c18
            // `end` is set on every path that clears G+0x08 in a pass (begin frame, tick, film branch above); an end
            // none of them explains is a bug, not an Esc.
            guard let end else {
                preconditionFailure("DeimosSession.pass: the running flag (G+0x08) cleared by no known rule — not the "
                                    + "begin frame's quit, the tick, or the film branch")
            }
            result = makeResult(end: end)
        }
        return PassOutput(ops: ops, sounds: cues.sounds, music: cues.music, ticked: begin.tick,
                          sessionEnded: !game.flags.running, haltEffectsAt: cues.haltEffectsAt,
                          fadeToBlackAt: fadeMark, result: result)
    }

    /// The result `FUN_100051a0` fills after its loop (`10005b38..10005c18`; `SessionResult`'s comment): per slot,
    /// present = index byte +0xcc ≠ −1; present → the decoded score, the level +0xc0 and the cheat flag +0xbd; absent →
    /// score 0, level `none`; then all-levels G+0x0d. The film flag and the start sector are the session's; the recorded
    /// film is the recorder's image (Phase 4 S5: the film object `FUN_100095b0(film, 'last')` saves), empty for a film.
    private func makeResult(end: SessionResult.End) -> SessionResult {
        var present: [Bool] = [], scores: [Int32] = [], levels: [FourCC] = []
        var cheated = false
        for p in game.players.prefix(2) {                            // 10005b48..10005c04
            let here = p.index != -1                                 // 10005b54..10005b70 FUN_10026c90
            present.append(here)
            if here {
                scores.append(p.score)                               // 10005b80..10005b90 FUN_100299f0
                levels.append(p.levelRef)                            // 10005b94..10005ba0 FUN_10029cb0
                if p.cheated { cheated = true }                      // 10005ba4..10005bbc FUN_10029be0 → +0x15
            } else {
                scores.append(0)                                     // 10005bc4..10005bd0
                levels.append(.none)                                 // 10005bcc..10005bd8
            }
        }
        return SessionResult(end: end, isFilm: game.flags.filmPlaying, startSector: startSector, present: present,
                             scores: scores, levels: levels, allLevels: game.flags.allLevels,   // 10005c08..10005c10
                             cheated: cheated, recordedFilm: game.recorder?.image ?? [])
    }

    /// The Phase-1 entry point, kept for the driver (standing rule 7): `pass(keys:ticks:)` with a TickCount of 0
    /// (the FPS monitor's window never closes).
    public mutating func pass(keys: HeldKeys) -> PassOutput { pass(keys: keys, ticks: 0) }

    /// 2. The tick: the appear check, the world update `FUN_10006b50`, level complete `FUN_10007170`, game time + 1.
    /// Returns whether `FUN_10007170` started a level (the next sector — not level `none`), whose drawing part the
    /// pass then emits. The level start sets game time 0 and the `+= 1` here follows it, so the new level's first
    /// tick runs at game time 1 (ruling 4, `100059e0..100059f0`).
    private mutating func tick(keys: HeldKeys, withheld: Bool, ticks: UInt32, ops: inout [RenderOp]) -> Bool {
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
        let started = game.flags.levelsStarted
        game.levelCompleteStep(controller: &controller, console: &console, ticks: ticks)   // 100059dc FUN_10007170
        game.flags.gameTime &+= 1                                    // 100059e0..100059f0
        return game.flags.levelsStarted != started && game.flags.level != .none
    }

    /// The host's word that a transition's fade to black has presented its last step (plan LT): `FUN_100302e0`'s FPS
    /// init `FUN_100305e0` (`10030314`) runs after the fade (`10007234`) and reads `TickCount` then, while this pass
    /// ran when it began — so the FPS window restarts at `ticks`, the tick the fade ended. The rest of that init
    /// (frames = the max rate, shown, deficient windows 0) is as the pass left it; nothing between depends on it.
    public mutating func transitionFadeEnded(ticks: UInt32) {
        controller.fpsWindowStart = ticks
    }

    /// The pause's wait let go on the quit flag b8 (Phase 4 S1b; grounding B §5 `10022f8c..10022fa8`, D S14; X
    /// `10023228..10023244`): it returns "quit", skipping the music resume (`10022fb0` branches past `10022fb4`), and
    /// the paused-frame hook sets the frame controller's +2 (X `10030cb8`), so the next pass's begin frame reports
    /// quit and the session ends (`1000591c`). The resume the pause left for the next pass (`PauseScreen
    /// .musicAfterWait`, the only music queued between passes) is dropped. Called by the host, between passes.
    public mutating func quitDuringPause() {
        controller.quitChosen = true                                 // X 10030cb8 (+0x02)
        game.cues.music.removeAll { $0 == .resume }                  // 10022fb0: no FUN_10048220(0)
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

extension GameState {
    /// `FUN_100064d0(film, info)` — the level start's STATE part (plan LT, ruling 5; the order of `DeimosSession`'s
    /// comment). The session's set-up calls it for the first level and `levelCompleteStep` for the next one, inside
    /// the same game; its drawing part is the session's (`DeimosSession.levelStartOps`, read from the state left
    /// here). `film` = the caller's film flag (G+0x20 at the set-up; `FUN_10007170` passes its own, 0 on that path).
    /// `musicPlaying` = `FUN_10047f80()` (`1000675c`, the music-playing byte `DAT_100e02a0`): the session's set-up
    /// passes `SessionStart.musicAlreadyPlaying`; `FUN_10007170` has just stopped the music (`10007204`), so the
    /// default false holds there (Phase 4, plan S1a).
    /// Levels started == 0 → the level of +0x18 (`10006560..10006588`); else sector(+0x18) + 1 (`10006594..100065a8`),
    /// level `none` above the order's count (`100065ac..100065bc`, `10006620..10006628`), else that sector's tag and
    /// level info (`100065c4..100065dc`). Levels started += 1 BEFORE the `none` test (`1000667c..10006684`); `none` →
    /// music resume, running = 0, return before any player or world reset (`10006688..100066c8`). The first level
    /// start needs G+0x18 (`flags.level`) set to a tag of the order.
    public mutating func levelStart(film: Bool, musicPlaying: Bool = false) {
        flags.gameTime = 0                                           // 10006500
        flags.levelEndHandled = false                                // 10006504
        flags.levelEndTime = flags.gameTime                          // 10006508..1000650c
        flags.appeared = false                                       // 10006510
        flags.cheatLife = 0; flags.cheatFunds = 0                    // 10006514 FUN_10007130
        flags.cheatScore = 0; flags.cheatShields = 0; flags.cheatMult = 0
        flags.groundCreated = 0                                      // 10006518 FUN_10007150
        flags.groundDestroyed = 0
        tally.reset()                                                // 1000651c FUN_10007280
        flags.rewardArmed = false                                    // 10006524..10006528
        if flags.perfectThisLevel {                                  // 1000652c..10006538
            flags.perfectThisLevel = false                           // 1000653c
            flags.rewardArmed = true                                 // 10006544
        }
        // [10006548 FUN_1003e510 unit resources; 10006554 the object list's constructor]
        if levels.isEmpty {                                          // a bare game state: the session loaded them
            do { try loadLevels() } catch {
                preconditionFailure("GameState.levelStart: the levels do not load (\(error))")
            }
        }
        let order = assets.levelOrder
        var sector = order.sector(of: flags.level) ?? 0              // FUN_10011e30 (0 when absent)
        if flags.levelsStarted == 0 {                                // 10006560..10006568
            precondition(sector >= 1, "GameState.levelStart: the first level start needs flags.level (G+0x18) set "
                         + "to a tag of the level order; it is \(flags.level)")
            levelInfo = levels.definitions[sector - 1]               // 10006580..10006588 FUN_10011fd0
        } else {
            sector += 1                                              // 10006598..100065a8
            if sector > order.levels.count {                         // 100065ac..100065bc FUN_10011de0
                flags.level = .none                                  // 10006620..10006628
            } else {
                flags.level = order.level(sector: sector)            // 100065c0..100065cc FUN_10011f00
                levelInfo = levels.definitions[sector - 1]           // 100065d0..100065dc FUN_10011fd0
            }
        }
        // [100065e4..1000661c, 1000663c..10006678, 100066cc..100066e0: the unregistered limits — registered game]
        flags.levelsStarted &+= 1                                    // 1000667c..10006684
        if flags.level == .none {                                    // 10006688..10006694
            cues.music.append(.resume)                               // 10006698..1000669c FUN_10048220(0)
            flags.running = false                                    // 100066c0..100066c4 (+0x0e: registered)
            return                                                   // 100066c8 → 10006988
        }
        flags.sector = Int32(sector)                                 // 100066e8
        // [100066f0 FUN_1002b3a0 resource preload; 100066f8..1000674c the terrain buffer, superseded by the map load]
        if !film && !musicPlaying {                                  // 10006754..10006768 (FUN_10047f80)
            cues.music.append(.play(FourCC("ammu")!, loop: true))    // 1000676c..10006788 ◇ stand-in 4
        }
        for i in 0..<2 {                                             // 10006798..100067b8 FUN_100269a0
            playerLevelStart(i)
        }
        if !film {
            cues.music.append(.stop)                                 // 100067bc..100067c8 FUN_10048120(0)
        }
        cues.music.append(.level(prefs.intPrefs[1]))                 // seam: the engine's level (int pref 1)
        messages.reset()                                             // 100067d0 FUN_1002db50
        debris.levelReset()                                          // 100067d8 FUN_1002a660
        particles.levelReset()                                       // 100067e0 FUN_100432d0
        mask = levels.masks[sector - 1]                              // 100067ec FUN_1000fa90 → FUN_1000fbc0
        scroll.levelStart(rect: levelInfo.background)                // FUN_1000fa90
        levelStartEntities(level: levelInfo)                         // 100067f8 FUN_10032e60 (+ FUN_10035900)
        // [10006804 FUN_10012170 frees the object list]
        blurs.levelReset()                                           // 1000680c FUN_100467c0
        // [10006814 FUN_1004a950 input reset: no op]
        notice.reset()                                               // 1000681c FUN_10018130
        // [10006824 FUN_100189f0 clear layers: nothing is queued since begin frame's / FUN_100302e0's clear — no op]
        spawnLoadPassLevelObjects()                                  // 1000682c FUN_1000fa10
        let noticeUnit = assets.objects[Int(flags.sector) + 9]       // 10006834..10006848 FUN_100201f0(+0x14 + 9)
        if noticeUnit != .none {
            let half: Float = 0.5                                    // *(0x100d6354 + 8)
            let x: Float = assets.floats[54] * half                  // 1000688c..100068d0
            let y: Float = assets.floats[55] * half                  // 100068c8..100068f0
            spawn(SpawnRequest(unit: noticeUnit, x: x, y: y))        // 100068f4 FUN_10033220(req, 0, 0)
        }
        // [1000690c back ← black: the drawing part]
        scoreBar.levelStart(players: players, sector: flags.sector)  // 10006914..10006934 (blits off)
        if prefs.bytePrefs[5] != 0 {                                 // 1000693c..1000694c FUN_10004ef0(5)
            flags.restoreInterlace = true                            // 10006950..10006954
            prefs.bytePrefs[5] = 0                                   // 10006958..10006960 FUN_10004ab0(5, 0)
        } else {
            flags.restoreInterlace = false                           // 1000696c..10006970
        }
        // [10006974 the first terrain blit: the drawing part; 10006980 FUN_1000c2a0 window]
    }
}

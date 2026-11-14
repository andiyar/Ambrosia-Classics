import Foundation
import HectorResources

/// One level of the game, stepped one `.GameLoop @ 10009d48` iteration at a time (engine §3–§4; plan S2). Core records
/// the original's calls at their call sites (`FrameOps`); FerazelRender executes them.
///
/// **Level start** (returned with the first `step`), in the binary's order:
/// - `.SetupLevel @ 1000430c`: `.SetScreenClut(level+base)` (l. 2571), `.DrawPICTToBackScreen(0x81, …)` (l. 2574),
///   the scroll point zeroed and `.RedrawEntireScrollGrid` at (0, 0) (l. 2577–2582); `.SetupLevelSprites` inside it
///   spawns the placed sprites (`SetupFaces`, with playerX = `fd94` = origin x + 0x32: l. 5149, 5164) and their lights.
/// - `.GameLoop`: the player `MTNewSprite(0, x, y, 10)` (l. 5181), the camera at the origin − 0xd0 (l. 5168–5195),
///   `_HideCursorSafe` (l. 5203), `.FindUpperLeftCorner` (l. 5209), `.SetScrollLocation` (l. 5210),
///   `.RedrawEntireScrollGrid` (l. 5211), `.UpdateStatusBar(0, 0, 0)` (l. 5216), `.SetAIFFMusic(hdr+0x284a)` (l. 5221).
///   The menu bar was hidden before `.GameLoop` by the front end — on a new game by `.main` (l. 8280) and
///   `.MainMenu @ 1000e618` (l. 7349); on a resume by `.ContinueGame` (l. 6877). Phase 1 has no front end, so the
///   request rides the level start. Not built here: `.FadeAIFFMusic(1, 4)`, the gamma fades, `.ChapterScreen`
///   (hdr 0x273c, l. 5222–5226) — L1's `LevelRun` hosts the session (`hostedByLevelRun`) and runs them, emitting the
///   level start itself (the session's `startOps()`); a directly built session keeps this Phase-2 level start.
/// - P3: the player is `Player.spawn` (`.SetupPlayerSprite`, with its held-item and five trail sprites), then the
///   countdown sprite `MTNewSprite(0x4c4, x, y, 800, −1, .SetupEffectSprite)` (l. 5184) into `*_DAT_1009fd7c` with its
///   six digit sprites 0x4c5; `iRam100a5110 = −0x1e` (l. 5186), so the countdown stays hidden (its only other writer
///   is the 2907 timer's contact in `.HitPlayerSprite`, l. 49275 — BX2, handed over in `PlayerState.countdownStore`).
///   No `FastRand` in any of them.
///
/// **Each iteration** (l. 5224–5290): `.FindUpperLeftCorner`, the countdown sprite's Handle called directly (raw
/// `1000a148..1000a158`: `if (*_DAT_1009fd7c) (*(+0x4c))()`), then `.PaintFrameWrap(draw, odd) @ 10011cf8` with
/// draw = 0 iff prefs[0] and not odd (odd starts false, toggles at the end — so with prefs[0] the FIRST iteration
/// skips): `.SetScrollLocation`, `.DrawLightsOntoTiles` unless prefs+6 == 3, `.WrapDrawSprites` unconditionally; only
/// the `if (param_1 != 0)` block (l. 9254–9450) with `.WrapCopyToScreen(port, h, v, 0x10, 8, prefs+9 == 0,
/// prefs+2 == 3, 0)` (l. 9443/9447) is skipped — and with it the parity flip `*_DAT_1009fd30` (`SpriteWorld.parity`,
/// l. 9435–9440, before the copy); then always `.HandleIdleSprites`, `.HandleSprites` (the items' light twinkle from
/// `.HandleBonusSprite` — `BonusSprite.handle`, its light calls as `changeLightFace` ops (BN) — the player's `.HandlePlayerSprite` (`Player`) with
/// its look-ahead and `.PlayerScroll` moving the camera focus (P5), and the Effect Handles), `.WrapEraseSprites`
/// (l. 9452–9456); after it `.UpdateStatusBar(1, 0, 0)`.
///
/// **Map writes** (P3, the P2 carry): `.SetFGTile`/`.SetFGCrunchDirTile` are followed by `.ChangedTile @ 10012a50` =
/// `.RedrawScrollGrid` of the cell, which draws into the tile port at once — inside the Handle that crunched (the
/// player's tile callback or the crumble overlay's Handle). So each Handle's `DrawOp.setTile`s are appended right
/// after that Handle, at its place in the handle pass (after `.WrapCopyToScreen`, interleaved in list order with the
/// other Handles' ops — e.g. a Bonus twinkle's `changeLightFace`, which the redrawn cell's light pass reads — and
/// before `.WrapEraseSprites`); the cues are drained once after `.MTHandleSprites` (`frameCues`).
///
/// F2: the sprites live in a `SpriteWorld`. `.HandleSprites` is its three passes (Invariant 3): `handleSprites`
/// walks the active list (each sprite's Handle at its list position: the player slot runs `Player.handle` (with
/// `.PlayerScroll`), an Effect its `EffectSprite.handle`, a Bonus its `BonusSprite.handle`), then
/// `collideSprites`, then `collideSpecial`.
public final class FerazelSession {
    public let resources: FerazelResources
    /// The live prefs (`_DAT_1009fe44`). P1: settable — the flow writes it after an in-level `.MakeCurrPrefs` (⌘P's
    /// Options, the pause's ⌘M / ⌘F), so the rest of the level reads the new keys, volumes and graphics.
    public var prefs: FerazelPrefs
    /// The sprite physics world: active list, idle table, `FastRand` stream, game globals, level.
    public let world: SpriteWorld
    public var level: LevelFile { world.level }
    public var globals: GameGlobals { world.globals }
    /// The active sprite list (the player included).
    public var active: ActiveList { world.active }
    /// The idle-sprite table.
    public var idle: IdleSprites { world.idle }
    /// The lights the Setups added, in `.AddLight` (= `.SetupLevel`) order — the light slots 0… a renderer fills.
    public let lights: [SetupFaces.Light]
    /// LT: the light table `_DAT_100a0128` — the single source of truth: fresh at `.SetupLevel` (`.RemoveAllLights`),
    /// the Setup lights added through it in `.SetupLevelSprites` order, every later light call made on it at its call
    /// site; handed to the renderer once per `.PaintFrameWrap` (`DrawOp.lightTable`).
    public internal(set) var lightTable: LightTable
    /// The player's `ActiveList` id (`*_DAT_1009fdd8`).
    public let playerID: Int
    /// The player's globals (`world.player`).
    public var player: PlayerState { world.player }
    /// `*_DAT_1009fd7c`: the countdown sprite 0x4c4 (nil when `.MTNewSprite` found no record).
    public let countdownID: Int?
    /// `iRam100a5110`: the countdown (−0x1e = hidden; `.GameLoop` decrements it only while > −0x1e) — held by the world
    /// (`SpriteWorld.countdown`, BT: the gate's −2 arm reads it inside its Handle).
    public var countdown: Int32 { world.countdown }
    /// The player cues of the last iteration, in call order (`PlayerState.drainFrameOutputs` after `.MTHandleSprites`).
    /// The `SoundCue`s come from `PlayerState.soundCalls` instead (S1: converted at the end of the same iteration).
    public private(set) var frameCues: [PlayerCue] = []
    public private(set) var camera: Camera
    /// The stream's current state (`_DAT_100a17e8`; the stream is `world.rng`, plan Invariant 4).
    public var rngSeed: Int32 { world.rng.seed }
    /// The stream's state right after `.SetupLevelSprites` (before the post-Setup level-start draws).
    public let seedAfterSetups: Int32
    /// `.BuildTintTable @ 10020a5c`'s 510 `FastRand(5000)` for tint table 0xa, in draw order — B, then R, for each of
    /// entries 0..0xfe (raw `10021d04`, `10021d14`; l. 18258–18259). Drawn from this session's stream at level start;
    /// a renderer builds its table 0xa from them (`FrameRenderer.buildTintTable`), so Core keeps the one stream and
    /// never sees a colour.
    public let tintTableDraws: [Int16]
    /// The `.GameLoop` parity flag `bVar23`.
    public private(set) var odd = false
    /// `.WrapDrawWaterEffects`' tile cache (`_DAT_100a00f0`, its origin) and the dust's `local_6a` (E1b). The cache,
    /// the origin and the flag `*_DAT_100a00f4` are globals that run on from the previous level (`LevelCarry`, E1b
    /// review fix): a first walk at the old origin with the flag set walks the old cells; `local_6a` starts at 0.
    public private(set) var waterEffects = WaterEffects()
    /// OX: OmniPx's state (`OmniPx`: the mode, faces, layer arrays, factor backup) and its counter `c`, which runs on
    /// from the previous level (`LevelCarry.omniPxCounter`). The on-flag is G+0x174 (`world.globals.omniPxActive`).
    public internal(set) var omniPx = OmniPx()
    /// OX: the renderer's `.TurnOnOmniPx` (`DrawOp.omniPx(.turnOn)`) when `.SetupOmniPx(0)` turned OmniPx on (modes 2,
    /// 4, 5) — empty on a mode-0 level. `.SetupLevel` M l. 2540: `LevelRun.setupLevel` emits it after its last load
    /// bar; an unhosted session puts it first in its level-start block (before `.SetScreenClut`, M l. 2571).
    public private(set) var omniPxStartOps: [DrawOp] = []
    /// The level loaded (`Mlvl` id).
    public let levelNumber: Int
    /// `Mmap 200`, read by `LevelFlow` when the level exit is touched.
    public let map: WorldMap
    /// The request that ended the game loop (W4): `.deathEffect` or `.loadLevel(n)`, emitted once with the iteration
    /// that ended it; nil while the loop runs.
    public private(set) var ended: ShellRequest?
    /// Iterations run.
    public private(set) var iterations = 0
    /// L1: the game loop's exit test held after the last iteration (`DAT_100a5106` or `*_DAT_100a0088`, M l. 5229) —
    /// set for every session; a hosted one (`hostedByLevelRun`) asks nothing of the shell then (`LevelRun` builds
    /// `LevelEnd` from the end state).
    public private(set) var loopEnded = false
    /// L1: `LevelRun` hosts the session — it emits the level start itself at the binary's places (`.SetupLevel`'s
    /// tail, `startOps()`, `MusicFade`), so `step` omits the iteration-0 block and the loop end adds no request.
    public let hostedByLevelRun: Bool
    /// `.GameLoop`'s `param_1` / `param_2` (M l. 5146–5148), the start position — the first value of `*_DAT_1009fe68`
    /// / `*_DAT_1009fe64`, which `.HandlePlayerSprite` rewrites every frame (M l. 46367–46376; `PlayerState.pixelX/Y`),
    /// so `.EndLevelSGUpdate`'s save +0xc / +0x10 (M l. 6541–6542) are the player's position at the exit, not these.
    public let startX: Int
    public let startY: Int
    /// L1: the three `.SetupLevelSprites` tallies (`SetupFaces.Tallies`) — `.SetupLevel`'s first-visit totals.
    public let tallies: SetupFaces.Tallies
    /// L1 (hosted only): the `setTile`s of `.SetupLevel`'s crunch-log re-apply (M l. 2382–2393), made before
    /// `.SetupLevelSprites` and before any redraw — `LevelRun` emits them at that place.
    public let setupLevelTileOps: [DrawOp]

    private let faceBounds: (FaceRef) -> IdleSprites.Rect
    /// The renderer's mode-5 walk (`DiffuseRandoms`); nil takes no draw-time randoms.
    private let diffuseRandoms: DiffuseRandoms?
    /// SP: the walk at the renderer's scroll point and drawn pair (`DiffuseRandomsAt`); when set, used instead.
    private let diffuseRandomsAt: DiffuseRandomsAt?
    /// SP: the scroll point and drawn pair the renderer holds, from the scroll ops this session emitted
    /// (`noteRendererScroll`).
    private(set) var rendererScroll = RendererScroll()
    /// The tile solver over `world` (one per level).
    private let solver: TileSolver
    /// - Parameter seed: the `FastRand` seed (tests fix it; the app seeds from the clock like `.InitAppGlobals`).
    /// - Parameter carry: what the previous level's session hands on (`carry`; W4) — the parity and the crunch log.
    /// - Parameter faceBounds: a face's opaque bounds (`face +8`), which `.ActiveToIdleSprite` stores and
    ///   `.HandleIdleSprites` tests. Core has no face pixels; without it each face's frame (sheet cell, or the PICT's
    ///   frame for a single face) is used — a superset of the opaque bounds [MED].
    /// - Parameter particleFaces: the face pixels the face emitters walk (E1a: `.ExplodeFaceIntoParticles`,
    ///   `.ParticleGlow`) — FerazelRender's (`FrameRenderer.particleFaces`); none by default (no particles, no draws).
    /// - Parameter diffuseRandoms: the mode-5 draw walk (`FrameRenderer.diffuseRandoms`): each mode-5 draw of
    ///   `.WrapDrawSprites` takes its randoms from `rng` at its list place (`diffuseSeeds`); nil → none (Core tests).
    /// - Parameter diffuseRandomsAt: SP — the same walk asked at the renderer's scroll point and drawn pair for that
    ///   op (`FrameRenderer.diffuseRandomsAt`); when set, `diffuseRandoms` is not called. Nil → exactly the above.
    /// - Parameter start: `.GameLoop`'s (x, y) (`param_1`, `param_2`); nil → hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, as
    ///   `.NewGame` passes (M l. 5823). Continue passes save +0xc / +0x10 (M l. 7044–7064; F1b).
    /// - Parameter refreshFacing: on a carried G, `+0x16 ← hdr+0x26c8` (`.NewGame`'s next-level loop, M l. 5821; W4);
    ///   Continue's loop passes false (M l. 7044–7064).
    /// - Parameter records: the live placement records to start from (L1: `SaveBlock.restoreSnapshot`, which
    ///   `.SetupLevel` copies over the level's records on a revisit, M l. 2395–2516); nil → the file's.
    /// - Parameter hostedByLevelRun: L1 — `LevelRun` drives the session: `step` omits the iteration-0 block, the loop
    ///   end appends no request, and `.SetupLevel`'s in-session parts run here (the crunch-log re-apply on a revisit,
    ///   `unlocked[L] = 1` before the player spawn). False (every caller before L1) = Phase 2's behaviour exactly.
    public init(resources: FerazelResources, prefs: FerazelPrefs, level: Int, seed: Int32 = 1,
                carry: LevelCarry = LevelCarry(), faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil,
                particleFaces: ParticleFaces = ParticleFaces(), diffuseRandoms: DiffuseRandoms? = nil,
                diffuseRandomsAt: DiffuseRandomsAt? = nil, start: (x: Int, y: Int)? = nil,
                refreshFacing: Bool = true, records: [Placement]? = nil, hostedByLevelRun: Bool = false) throws {
        self.resources = resources
        self.prefs = prefs
        self.hostedByLevelRun = hostedByLevelRun
        levelNumber = level
        map = try WorldMap.load(from: resources)
        let L = try LevelFile.load(from: resources, level: Int16(level))
        let world = SpriteWorld(level: L, seed: seed, records: records)
        // W4 (P3 carries): the parity `_DAT_1009fd30` and the G-resident crunch log run on from the previous level.
        world.parity = carry.parity
        // W4 review fix: after a level exit G runs on whole (`.InitGameGlobals` is `.NewGame`'s only, M l. 5747); the
        // next-level loop re-writes `+0x16` from the new header (l. 5821) — not Continue's (L1 `refreshFacing`).
        if let g = carry.globals {
            world.globals = g
            if refreshFacing { world.globals.startFacing = Int16(L.header.startFacingLeft) }
        }
        world.globals.crunchLog = carry.crunchLog
        world.statusBar = carry.statusBar
        // EF review fix: the flash, the paint counter and the plume count run on (`LevelCarry`).
        world.flash = carry.flash
        world.paintCounter = carry.paintCounter
        world.plumeCount = carry.plumeCount
        // `.InitParticles` (`.SetupLevel`, `bl` 10004fc0) clears byte +0 of every record and keeps the count, hint and
        // high-water mark (particles §1.1): they run on from the previous level (E1a).
        world.particles = ParticlePool(counters: carry.particles)
        world.particles.initParticles()
        world.particleFaces = particleFaces
        world.signTexts = try StringList.load(from: resources, id: 500)   // C1: the 2902 sign's `GetIndString(500, p1)`
        self.world = world
        let bounds = faceBounds ?? { Self.frameRect($0, resources: resources) }
        self.faceBounds = bounds
        self.diffuseRandoms = diffuseRandoms
        self.diffuseRandomsAt = diffuseRandomsAt
        // `.GameLoop(hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, 0, 1)` (`.NewGame` l. 5823), or the caller's `start` (L1).
        let px = start?.x ?? Int(L.header.startX) - 0x20, py = start?.y ?? Int(L.header.startY) - 0x20
        startX = px
        startY = py
        camera = try Camera(header: L.header, spriteX: px, spriteY: py)
        camera.shake = carry.shake                                     // EF review fix: the shake runs on (`LevelCarry`)
        // playerX = `fd94` = origin x + 0x32 (`.GameLoop` l. 5149, before `.SetupLevel`).
        let context = SetupFaces.Context(level: L, playerX: px + 0x32, effects: prefs.effects, records: records)
        // `.ClearCrunchSprites` (`.GameLoop` l. 5160, before `.SetupLevel`): the 40-slot overlay table — already empty
        // in this fresh world; W4's level flow keeps the order when a world is reused.
        world.player.crunchSprites = [Int?](repeating: nil, count: 0x28)
        // E1b review fix: the water-effects cache, origin and flag `*_DAT_100a00f4` run on (`LevelCarry`); the player
        // Setup keeps the flag (`Player.spawn`).
        world.player.tileCacheValid = carry.tileCacheValid
        // SD review fix: the pose ring's mirror bytes run on (`LevelCarry.shadowMirrors`); the player Setup keeps them.
        for (k, m) in carry.shadowMirrors.enumerated() where world.player.shadowRing.indices.contains(k) {
            world.player.shadowRing[k].mirrored = m
        }
        waterEffects = WaterEffects(cells: carry.waterCells, originCol: carry.waterOriginCol,
                                    originRow: carry.waterOriginRow)
        // L1 (hosted): `.SetupLevel`'s revisit re-apply (M l. 2382–2393, raw `1000483c..100048a0`) — with
        // `G+0x176 + 2L == 1` (`LevelRun` has already cleared it when F4 was held), every crunch-log entry of this
        // level: `.DestroyCrunchTile(col +0x60fa, row +0x60f8, .GetFGCrunchDirTile(col, row), explode 0, clearDir 1)`
        // (raw `10004850..10004880`: r6 = 0, r7 = 1) — no `.ExplodeCrunchedTile`, so no `FastRand` (BC12). Before
        // `.SetupLevelSprites` (l. 2526): the Setups see the reshaped map.
        if hostedByLevelRun, world.globals.hasSnapshot[level] == 1 {
            for e in world.globals.crunchLog where Int(e.level) == level {
                let col = Int(e.col), row = Int(e.row)
                CrunchTiles.destroyCrunchTile(world, col: col, row: row, dir: world.tiles.crunchDir(col: col, row: row),
                                              explode: false, clearDir: true)
            }
        }
        setupLevelTileOps = world.player.tileOps
        world.player.tileOps = []
        // EC: `.SetupLevel` zeroes the tallies, sets the counting window, runs `.SetupLevelSprites` and clears it
        // (M l. 2521–2526, raw `10004da4..10004dc0`); the live count stays the world's (`EnemyCounting`).
        world.enemies = EnemyCounting(window: true)
        let spawned = try SetupFaces.spawnLevelSprites(context: context, rng: &world.rng,
                                                       counting: &world.enemies) { e in
            // `.ActiveToIdleSprite`: the bounds of the face `+0xc0` holds at `.AddIdleSprite` time — none for a
            // Handle-faced type, the placeholder for a class-cache face (`SetupFaces` header).
            switch e.source {
            case .none, .handle: return .noFace
            case .setupCached:
                return bounds(FaceRef(pict: SetupFaces.placeholderPict, index: 0, set: .encoded))
            case .setup: return e.slot.face.map(bounds) ?? .noFace
            }
        }
        world.enemies.window = false
        lights = spawned.lights
        lightTable = spawned.lightTable
        tallies = spawned.tallies
        world.pendingTallies = spawned.tallies                          // BN: `*_DAT_1009ffb0` / `*_DAT_1009ffac`
        world.levelIndex = level                                        // BN: `*_DAT_1009feac`
        world.active = spawned.active
        world.idle = spawned.idle
        world.records = spawned.records                                  // the Setups' write-backs (W2a)
        // LV5: `.SetupLevelSprites`' `fed4 = 0`, `fed0 = 1` (M l. 2016–2019) and the Warrior's `fed0 = 0`; the pan
        // counter `_DAT_1009ff9c` runs on from the previous level (`LevelCarry.panCounter`; only `.InitGameGlobals`
        // zeroes it, M l. 806).
        world.arena.locked = spawned.arena.locked
        world.arena.noBossAlive = spawned.arena.noBossAlive
        world.arena.panCounter = carry.panCounter
        // OX: `c` runs on (`LevelCarry.omniPxCounter`). `.SetupLevel`'s `G+0x174 = 0` and `.SetupOmniPx(0)` (M l.
        // 2539–2540) — inside `.SetupLevel`, so before the player `MTNewSprite` (`.GameLoop` M l. 5165 → 5181), hosted
        // or not (nothing `LevelRun.setupLevel` does after the session init reads OmniPx or the PxBack factors). The
        // renderer's turn-on is `omniPxStartOps`: `LevelRun` emits it at M l. 2540's place, an unhosted session at the
        // head of its level-start block.
        var omni = OmniPx(counter: carry.omniPxCounter)
        var lv = world.level, g = world.globals
        g.omniPxActive = 0
        omni.setup(level: &lv, globals: &g)
        world.level = lv
        world.globals = g
        omniPx = omni
        omniPxStartOps = g.omniPxActive != 0 ? [.omniPx(.turnOn(omniPxMode: omni.omniPxMode))] : []
        // L1 (hosted): `*(G + L·2 + 0x23e) = 1` — `unlocked[L]` — right before the player `MTNewSprite` (M l. 5180–5181).
        if hostedByLevelRun { world.globals.unlocked[level] = 1 }
        // The player `MTNewSprite(0, x, y, 10, −1, .SetupPlayerSprite)` (l. 5181), then the countdown
        // `MTNewSprite(0x4c4, x, y, 800, −1, .SetupEffectSprite)` (l. 5184); `+0x46` of the player = param_3 = 0.
        guard let pid = Player.spawn(world: world, x: px, y: py) else { throw SessionError.noPlayerRecord }
        playerID = pid
        countdownID = Self.spawnCountdown(world, x: px, y: py)
        solver = TileSolver(world: world)

        // The level start's draws after `.SetupLevelSprites`, in the binary's order (plan F1 ⚑ note, E2 carry):
        // (1) `.RedrawEntireScrollGrid` inside `.SetupLevel` (l. 2582): none. Its `.WrapDrawFace` words are 9 + water
        //     kind and 0x14/0x15 + kind (raw `1001394c`, `100139b4`, `10013b14`, `10013bc8`); `.BlitEncFaceX` reaches
        //     `.BlitEncFaceDiffuse`/`FlipDiffuse` (the only FastRand sites in its closure, `10029b64/7c`, `10029e5c/74`)
        //     for mode 5 only (`cmpwi r23,0x5` raw `1002d130`), which no tile draw passes.
        //     The player and 0x4c4 `MTNewSprite`s (l. 5181–5183): none (F1 note).
        seedAfterSetups = world.rng.seed
        // (2) `.AnimateCLUT @ 1001180c` (`10009fb8`), with `_DAT_1009fd98` = 0 (l. 5144) and the parity flag
        //     `_DAT_1009fd30` as the last level left it (not reset by `.GameLoop`; false on a first start — W4 carry).
        //     The values recolour the working CLUT, which `LevelTables` does not model (levels 50, 51, 67); the draws
        //     are consumed.
        let h = L.header
        for _ in 0..<Self.animateCLUTDraws(mode: h.clutAnimMode, count: h.clutAnimCount, effects: prefs.effects,
                                           frameCounter: 0, parity: carry.parity) {
            _ = world.rng.next(4000)
        }
        // (3) `.BuildTintTable @ 10020a5c` (`10009fc0`): table 0xa, 255 entries × (B, R).
        tintTableDraws = (0..<(0xff * 2)).map { _ in world.rng.next(5000) }
        // `.BuildReddenTable` (`10009fc8`), `.FindUpperLeftCorner`: none. (4) `.SetScrollLocation` and
        // `.RedrawEntireScrollGrid` in `.GameLoop` (l. 5210–5211): none, as (1).
        world.passageView = PassageView(snap: { [unowned self] _ in self.passageSnap() },
                                        redraw: { [unowned self] _ in self.passageRedraw() })
    }

    /// L1: `.GameLoop`'s level-start draws after the player spawn (M l. 5209–5216): `.FindUpperLeftCorner`,
    /// `.SetScrollLocation`, `.RedrawEntireScrollGrid`, `.UpdateStatusBar(0, 0, 0)` — the iteration-0 block's part
    /// that `LevelRun` emits for a hosted session, at its place (after `HideCursorSafe`, before `.SetAIFFMusic`).
    /// `.AnimateCLUT`, `.BuildTintTable` and `.BuildReddenTable` (M l. 5206–5208) drew in `init` (`tintTableDraws`).
    /// HU: `keys` is the poll the status bar's key step reads (live in the original); the call's suffocation tick
    /// (snd 442) is in the output.
    public func startOps(keys: KeyState = KeyState()) -> FrontOutput {
        findUpperLeftCorner(graphics: prefs.graphics)
        var out = updateStatusBar(.levelStart, keys: keys)
        out.draws = [scrollOp(.redrawScrollGrid(h: camera.scrollH, v: camera.scrollV)),
                     scrollOp(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV))] + out.draws
        return out
    }

    /// `.UpdateStatusBar` at `site` (HU, `StatusBarCalls` on the world's flow-wide `statusBar`): `.UpdateHealthMagic`'s
    /// G writes and caches, the selection step on G with actions 8 / 7 of `keys` (the live `IsInputKeyPressed` reads).
    /// Returns the op and the suffocation tick (snd 442, `.STPlayRegSound(…, 1, 0x100)`, M l. 4492) as made at the
    /// call — for a call outside the frame loop (the level start, the chapter card, the save point's redraw), whose
    /// sound goes out with that call, not with the next frame's sound calls.
    public func updateStatusBar(_ site: StatusBarCalls.Site, keys: KeyState) -> FrontOutput {
        let made = statusBarCall(site, keys: keys)
        var out = FrontOutput(draws: [made.op])
        if let call = made.tick, case .play(let cue)? = SoundCues.convert(call, prefs: prefs) { out.sounds.append(cue) }
        return out
    }

    /// A call inside a frame (the loop's and `.CheckGameLoopKeys`' sites; a directly built session's start block, in
    /// its first step): the tick joins the frame's sound calls in call order.
    private func statusBarInFrame(_ site: StatusBarCalls.Site, keys: KeyState) -> DrawOp {
        let made = statusBarCall(site, keys: keys)
        if let call = made.tick { world.player.soundCalls.append(call) }
        return made.op
    }

    private func statusBarCall(_ site: StatusBarCalls.Site,
                               keys: KeyState) -> (op: DrawOp, tick: PlayerState.SoundCall?) {
        var g = world.globals
        let made = world.statusBar.update(site, globals: &g, actions: InputActions(keys: keys, prefs: prefs),
                                          levelName: level.header.name)
        world.globals = g
        guard made.suffocationTick else { return (made.op, nil) }
        return (made.op, PlayerState.SoundCall(
            cue: PlayerCue(call: .reg, snd: StatusBarCalls.suffocationSound, priority: 1, volume: 0x100),
            scrollH: camera.scrollH, scrollV: camera.scrollV))
    }

    /// `.AnimateCLUT @ 1001180c`'s `FastRand(4000)` count (l. 8961–9062, raw `10011bc4`): with header `0x2732` (count)
    /// ≠ 0 and the Effects gate open (prefs+6 ≠ 3; 2 → `_DAT_1009fd98 & 3 == 0`; 1 → `_DAT_1009fd30 == 0`), the loop
    /// runs entries `0xff − count ..< 0xff`, and mode `0x2730` == 6 draws once per entry.
    public static func animateCLUTDraws(mode: Int16, count: Int16, effects: Int16, frameCounter: Int32,
                                        parity: Bool) -> Int {
        guard count != 0, mode == 6, effects != 3 else { return 0 }
        if effects == 2 && frameCounter & 3 != 0 { return 0 }
        if effects == 1 && parity { return 0 }
        return max(0, Int(count))
    }

    /// The level could not be set up.
    public enum SessionError: Error, Equatable {
        /// `.MTNewSprite` found no free record for the player (the original's `*_DAT_1009fdd8 = 0`).
        case noPlayerRecord
    }

    /// The countdown digit sprites' type (`.SetupDigitSprite`).
    public static let digitType: Int16 = 0x4c5
    /// The countdown sprite's type.
    public static let countdownType: Int16 = 0x4c4

    /// `MTNewSprite(0x4c4, x, y, 800, −1, .SetupEffectSprite)` (l. 5184): the Effect Setup's common part
    /// (`EffectSprite.setup`; 0x4c4 is in the list that skips the `FastRand(8)` package, l. 53748), then its own arm
    /// (l. 53826–53860): the Effect Handle, hit and tile callbacks 0, layer 0x7fff (the sort key), `+0x88` 0, a 0x1c-byte
    /// block `+0x9c` holding six `MTNewSprite(0x4c5, +0xc, +0xa, 0x7fff, −1, .SetupDigitSprite)` — each `.InitSprite`,
    /// `+0x88` 0, layer 0x7fff, the digit Handle `.anon_10060c78` (`.StandardSpriteHandles` + `.StandardSpriteCleanup`
    /// of a faceless sprite: `.inert` here). The digits are inserted before the 0x4c4 itself (its Setup runs first).
    /// `.UpdateDigits @ 10060d04` (the 0x4c4 arm of `.HandleEffectSprite`) leaves every face 0 while `iRam100a5110`
    /// < −0x1d — always on levels 1–4 (`EffectSprite.handle`'s default arm: the faces stay nil). // later: Phase 6
    /// (the 2907 timer, level 40). No `FastRand`.
    static func spawnCountdown(_ w: SpriteWorld, x: Int, y: Int) -> Int? {
        w.newSprite(type: countdownType, x: x, y: y, layer: 800, handler: .effect) { s in
            EffectSprite.setup(&s)
            s.hasHit = false
            s.layer = 0x7fff
            s.lightOverlay = false
            for _ in 0..<6 {
                // `.inert`: the digit Handle `.anon_10060c78` (SSH + SSC of a faceless sprite) // later: `.UpdateDigits`
                // (gives the digits faces once the countdown shows; the 2907 timer's store is built, BX2 — none on
                // levels 1–4).
                w.newSprite(type: digitType, x: s.x, y: s.y, layer: 0x7fff, handler: .inert) { d in
                    d.lightOverlay = false
                    d.layer = 0x7fff
                }
            }
        }
    }

    /// One `.GameLoop` iteration (the first call also carries the level start). S1: when the special pass reaches a
    /// modal moment (`FrameSuspension`), the ops so far are returned with `suspension` set and the frame waits for
    /// `resume(_:)`; a `step` while suspended is a precondition failure. P1: `capsLock` is `.CapsLockDown()` for the
    /// hosted session's `.CheckGameLoopKeys` (a session not hosted by `LevelRun` runs no `.CheckGameLoopKeys`: Phase 2's
    /// frame exactly). VS: `playing` is the shell's playing set at the iteration's start (`SoundVoices`; the idle-only
    /// calls ask `world.isSoundPlaying(_:)`).
    public func step(keys: KeyState, capsLock: Bool = false, playing: Set<Int16> = []) -> FrameOps {
        precondition(world.suspension == nil, "FerazelSession.step while the frame is suspended — resume(_:) first")
        world.voices = SoundVoices(playing: playing, prefs: prefs)
        var ops = FrameOps()
        let graphics = prefs.graphics
        if iterations == 0 && !hostedByLevelRun {
            ops.draws.append(contentsOf: omniPxStartOps)                  // OX: `.SetupOmniPx(0)` (M l. 2540)
            ops.draws.append(.setScreenClut(id: ColorLUT.screenClutId(level.header)))
            ops.draws.append(.drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0))
            ops.draws.append(scrollOp(.redrawEntireScrollGrid(h: 0, v: 0)))
            ops.requests.append(.hideMenuBar)
            ops.requests.append(.hideCursor)
            findUpperLeftCorner(graphics: graphics)
            ops.draws.append(scrollOp(.redrawScrollGrid(h: camera.scrollH, v: camera.scrollV)))
            ops.draws.append(scrollOp(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV)))
            ops.draws.append(statusBarInFrame(.levelStart, keys: keys))
            ops.music.append(.play(track: Int(level.header.music)))
        }
        iterations += 1
        // `_HideCursorSafe()` at the top of every iteration (M l. 5233; L1 review fix 2). Hosted only: a directly built
        // session (Core tests) keeps its expectations (Invariant 10) — its one hide is the start block's above; the app
        // runs hosted sessions only since A1a.
        if hostedByLevelRun { ops.requests.append(.hideCursor) }
        // `*piVar5 += 1` (`_DAT_1009fd98`, l. 5236).
        world.frameCounter &+= 1

        // BX2: the 2907 timer's store into `iRam100a5110` during the last iteration's player pass (`PlayerState.countdownStore`).
        if let t = world.player.countdownStore {
            world.countdown = t
            world.player.countdownStore = nil
        }
        // `if (-0x1e < iRam100a5110) iRam100a5110 -= 1` (l. 5237–5239).
        if -0x1e < world.countdown { world.countdown -= 1 }
        findUpperLeftCorner(graphics: graphics)
        // The countdown's Handle, called directly before `.PaintFrameWrap` (raw `1000a148..1000a158`).
        if let c = countdownID, world.active.record(id: c) != nil { EffectSprite.handle(world: world, id: c, lights: &lightTable, effects: prefs.effects) }
        let draw = prefs.reduceFrameRate == 0 || odd
        let actions = InputActions(keys: keys, prefs: prefs)
        frameKeys = keys
        frameCapsLock = capsLock
        frameActions = actions
        frameDraw = draw
        afterSpecial = .mainPaint
        // IU: a hint inside the player's Handle stops the frame inside the handle pass (`resume(.hint)`).
        guard paintFrameWrap(draw: draw, actions: actions, nested: false, into: &ops) else {
            return suspendHandlePass(ops, nested: false)
        }
        guard world.collideSpecial(hitPlayer: hitPlayer, hit: hit) else { return suspend(ops) }
        return finishFrame(ops)
    }

    /// `.PaintFrameWrap(draw, odd) @ 10011cf8` up to `.MTCollideSprites` (M l. 9104–9460; the special pass and the
    /// tail are the caller's): `.SetScrollLocation`, the lights, `.WrapDrawWaterEffects` (its parameter is unused),
    /// `.WrapDrawSprites`, on a drawn pass the particles, the parity flip and `.WrapCopyToScreen`, then
    /// `.HandleIdleSprites` and `.HandleSprites`. `nested` (P1): a call from `.CheckGameLoopKeys` / `.Pause` — its
    /// Handle-pass cues join the iteration's. IU: false when a Handle suspended the handle pass (a hint inside the
    /// player's Handle) — the rest (`afterHandlePass`) runs at the resume.
    private func paintFrameWrap(draw: Bool, actions: InputActions, nested: Bool, into ops: inout FrameOps) -> Bool {
        let graphics = prefs.graphics
        let h = camera.scrollH, v = camera.scrollV
        world.paintDraw = draw                                     // r19 = param_1 (raw `10011d04`; BT gate arm)
        // LT: the table as `.SetScrollLocation`'s strip redraw and `.DrawLightsOntoTiles` read it (before
        // `.HandleLights`, M l. 9200–9205), handed over right before the strip; also when Effects == 3 skips the latter.
        ops.draws.append(.lightTable(lightTable))
        ops.draws.append(scrollOp(.redrawScrollGrid(h: h, v: v)))
        if prefs.effects != 3 { ops.draws.append(.drawLightsOntoTiles) }
        // `.HandleLights` (M l. 9205): after `.DrawLightsOntoTiles` and before `.WrapDrawWaterEffects`, unconditional.
        lightTable.handleLights()
        let table = lightTable, bounds0 = faceBounds, res = resources, lvl = level
        // `.WrapDrawWaterEffects(odd)` (l. 9206): every iteration, drawn or not, with the parity before this
        // iteration's flip — its bubbles, motes and wind dust into the pool, its Enhanced water faces into the op (E1b).
        ops.draws.append(.wrapDrawWaterEffects(waterEffects.run(world: world, h: h, v: v, effects: prefs.effects)))
        ops.draws.append(.wrapDrawSprites(diffuseSeeds(world.active.wrapDrawSprites { s in
            Self.dynamicLight(s, level: lvl, lights: table, bounds: bounds0) { Self.frameRect($0, resources: res) }
        }, h: h, v: v)))
        // `*_DAT_1009fd2c += 1` (M l. 9250): every pass, before the draw block (EF; the shake reads it).
        world.paintCounter &+= 1
        if draw {
            // EF: the flash step (M l. 9426–9432), before `.DrawParticles`.
            world.flash.step()
            // `.DrawParticles` (l. 9433): the colour-0 kills here, on drawn iterations only (`ParticlePool.draw`).
            ops.draws.append(.drawParticles(world.particles.draw()))
            // OX: `.UpdateOmniPx` (M l. 9434) at the scroll point of this pass — an op only while OmniPx is on.
            if let f = omniPx.update(globals: world.globals, h: h, v: v) { ops.draws.append(.omniPx(.update(f))) }
            // Then the parity flip (raw `10012710..1001272c`).
            world.parity.toggle()
            // `.WrapCopyToScreen` of the frame port, or of the mask port while the flash toggle is on (M l. 9441–9447).
            let backdrop = prefs.plainCopy == 0
            ops.draws.append(world.flash.on
                ? .copyMaskToScreen(h: h, v: v, graphicsMode: Int(graphics), backdrop: backdrop)
                : .copyToScreen(h: h, v: v, graphicsMode: Int(graphics), backdrop: backdrop))
            // `.EraseParticles` (l. 9449).
            ops.draws.append(.eraseParticles)
        }
        // `.HandleIdleSprites`: the window takes the live player's (`*_DAT_1009fdd8`) `+0x34` rect at its `+0xc`/`+0xa`
        // (l. 4302–4308).
        let bounds = faceBounds
        let playerRect = world.playerID.flatMap { world.active.record(id: $0) }.map { p in
            IdleSprites.Rect(top: p.y + p.hotRect.top, left: p.x + p.hotRect.left, bottom: p.y + p.hotRect.bottom,
                             right: p.x + p.hotRect.right)
        }
        world.idle.handle(h: h, v: v, playerHotRect: playerRect, active: &world.active, faceRect: bounds)
        // `.HandleSprites`: `.MTHandleSprites` — each sprite's Handle at its list position.
        guard world.handleSprites({ world, id in handleOne(world, id, actions: actions, ops: &ops) }) else {
            return false
        }
        afterHandlePass(nested: nested)
        return true
    }

    /// `.HandleSprites` after `.MTHandleSprites`: the cues the Handles made (once per frame, P2 review ruling 1), then
    /// `.MTCollideSprites` (the player pass `.MTCollideSpecialSprite` is the caller's).
    private func afterHandlePass(nested: Bool) {
        let cues = world.player.drainFrameOutputs().cues
        if nested { frameCues += cues } else { frameCues = cues }
        world.collideSprites(hit)
    }

    /// One sprite's Handle in the handle pass, dispatched by the record's `+0x4c` (`SpriteSlot.handler`).
    private func handleOne(_ world: SpriteWorld, _ id: Int, actions: InputActions, ops: inout FrameOps) {
        let effects = prefs.effects
        let solver = self.solver
        let bounds = faceBounds, res = resources
        guard let handler = world.active.record(id: id)?.handler else { return }   // the record's `+0x4c`
        defer {
            // `.ChangedTile`'s redraw happens inside the Handle that wrote the map: its ops go here (header).
            ops.draws.append(contentsOf: world.player.tileOps)
            world.player.tileOps = []
        }
        switch handler {
        case .player:
            // `.HandlePlayerSprite` (its look-ahead row and `.PlayerScroll` move the focus, P5).
            Player.handle(world: world, keys: actions, solver: solver)
        case .effect:
            EffectSprite.handle(world: world, id: id, lights: &self.lightTable, effects: effects)
        case .bonus:
            // `.HandleBonusSprite @ 1005e934` (BN, `BonusSprite.handle`) — M6: dispatched by the record's Handle
            // (`handler == .bonus`), not by the type's class; its `.ChangeLightFace`s land in `lightTable` and go
            // out as ops at its place in the pass.
            ops.draws.append(contentsOf: BonusSprite.handle(world: world, id: id, solver: solver, effects: effects,
                                                            lights: &self.lightTable) {
                Self.frameRect($0, resources: res).right
            })
        case .playerShot:
            // `.HandlePlayerShotSprite @ 10059704` (CS, `PlayerShot.handle`): its lights land in `lightTable`, the
            // liquid rule's effect 5 takes prefs+6.
            PlayerShot.handle(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                              faceWidth: { Self.frameRect($0, resources: res).right }, faceBounds: bounds)
        case .inert:
            break                                       // the four bosses not placed on levels 1–5 // later: Phase 6
        case .enemyShot:
            // `.HandleEnemyShotSprite @ 1005bffc` (ES, `EnemyShot.handle`): its Kills' Effects take `lightTable` and
            // prefs+6; the Chief boulder's hot rect reads the face bounds.
            EnemyShot.handle(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                             faceWidth: { Self.frameRect($0, resources: res).right }, faceBounds: bounds)
        case .walker:
            // `.HandleWalkerSprite @ 100683b8` (WK1, `Walker.handle`): the shots' and the coins' Setups take
            // `lightTable` and prefs+6; the coins' trigger row and origin read the face bounds.
            ops.draws.append(contentsOf: Walker.handle(world: world, id: id, solver: solver, lights: &self.lightTable,
                                                       effects: effects,
                                                       faceWidth: { Self.frameRect($0, resources: res).right },
                                                       faceBounds: bounds))
        case .crawler:
            // `.HandleCrawlerSprite @ 10065c00` (CR, `CrawlerRoach.handleCrawler`): the coins' Setups take `lightTable`
            // and prefs+6.
            CrawlerRoach.handleCrawler(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                                       faceWidth: { Self.frameRect($0, resources: res).right })
        case .roach:
            // `.HandleRoachSprite @ 10077a88` (CR, `CrawlerRoach.handleRoach`).
            CrawlerRoach.handleRoach(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                                     faceWidth: { Self.frameRect($0, resources: res).right })
        case .bat:
            // `.HandleBatSprite @ 1007e6b0` (BA, `Bat.handle`): the coins' and the spit's Setups take `lightTable` and
            // prefs+6.
            Bat.handle(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                       faceWidth: { Self.frameRect($0, resources: res).right })
        case .swarmMember:
            // `.HandleSwarmMemberSprite @ 1007e2c8` (BA).
            Bat.handleSwarmMember(world: world, id: id) { Self.frameRect($0, resources: res).right }
        case .insectBody:
            // `.HandleInsectBodySprite @ 1007f4a0` (BA).
            Bat.handleInsectBody(world: world, id: id) { Self.frameRect($0, resources: res).right }
        case .frog:
            // `.HandleFrogSprite @ 1008214c` (FR, `FrogSalamander.handleFrog`).
            FrogSalamander.handleFrog(world: world, id: id, solver: solver) { Self.frameRect($0, resources: res).right }
        case .salamander:
            // `.HandleSalamanderSprite @ 10083074` (FR, `FrogSalamander.handleSalamander`).
            FrogSalamander.handleSalamander(world: world, id: id, solver: solver) {
                Self.frameRect($0, resources: res).right
            }
        case .blob:
            // `.HandleBlobSprite @ 1007d044` (BL, `BlobCrab.handleBlob`).
            BlobCrab.handleBlob(world: world, id: id, solver: solver) { Self.frameRect($0, resources: res).right }
        case .deadBlob:
            // `.HandleDeadBlobSprite @ 1007cf64` (BL): no `+0xe9` test, no motion; its `+0x5c` is 0.
            BlobCrab.handleDeadBlob(world: world, id: id)
        case .crab:
            // `.HandleCrabSprite @ 10089828` (BL, `BlobCrab.handleCrab`): the claw and its links' places.
            BlobCrab.handleCrab(world: world, id: id) { Self.frameRect($0, resources: res).right }
        case .crabSegment:
            // `.HandleCrabSegSprite @ 10089dec` (BL): the face only; no hit (`+0x5c` 0).
            BlobCrab.handleCrabSegment(world: world, id: id)
        case .gremlin:
            // `.HandleGremlinSprite @ 1007feec` (GF, `GremlinFloater.handleGremlin`): the body, its back layer and the
            // rider by `+0xec`; the coins' and the rider's shot's Setups take `lightTable` and prefs+6.
            GremlinFloater.handleGremlin(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                                         faceWidth: { Self.frameRect($0, resources: res).right })
        case .floater:
            // `.HandleFloaterSprite @ 100816d8` (GF, `GremlinFloater.handleFloater`).
            GremlinFloater.handleFloater(world: world, id: id, solver: solver) { Self.frameRect($0, resources: res).right }
        case .dillo:
            // `.HandleDilloSprite @ 1008697c` (DL, `Dillo.handle`): the egg's x reads the face bounds.
            Dillo.handle(world: world, id: id, solver: solver, faceWidth: { Self.frameRect($0, resources: res).right },
                         faceBounds: bounds)
        case .geyserSegment:
            // `.HandleGeyserSegSprite @ 10060cd8` (GY, `Geyser.handleSegment`): empty — the column moves the segments.
            Geyser.handleSegment(world: world, id: id)
        case .warrior:
            // `.HandleWarriorSprite @ 10087c04` (6A-W1, `Warrior.handle`): the crates, the glow, the state machine, the
            // fall through `solver` with the Crawler-body tile callback, the liquids, `.StandardSpriteCleanup`.
            Warrior.handle(world: world, id: id, solver: solver) { Self.frameRect($0, resources: res).right }
        case .button:
            // `.HandleButtonSprite @ 10070e60` (BT, `ButtonSprite.handle`).
            ButtonSprite.handle(world: world, id: id) { Self.frameRect($0, resources: res).right }
        case .trail:
            // `.HandleTrailSprite @ 1004b354` (PU): `.StandardSpriteHandles` + `.StandardSpriteCleanup`.
            world.standardSpriteHandles(id)
            world.standardSpriteCleanup(id) { Self.frameRect($0, resources: res).right }
        case .heldItem:
            // `.HandleHeldItemSprite @ 1004be74` (IU, `HeldItem.handle`): the hot rect from the face's bounds.
            HeldItem.handle(world: world, id: id, faceBounds: bounds)
        case .shadow:
            ShadowDouble.handle(world: world, id: id)                         // `.HandleShadowSprite` (SD)
        case .platform:
            PlatformSprite.handle(world: world, id: id, solver: solver)       // `.HandlePlatformSprite` (W1)
        case .chain:
            ChainSprite.handle(world: world, id: id)                          // `.HandleChainSprite` (W1)
        case .seeSawSegment:
            ChainSprite.handleSeeSawSegment(world: world, id: id, solver: solver,
                                            faceWidth: PlatformSprite.faceWidth)
        case .background:
            // `.HandleBackgroundSprite` (W2a: radial bars / balls, the re-face tail; W2b: cannons, springs, passages).
            BackgroundSprite.handle(world: world, id: id) { Self.frameRect($0, resources: res).right }
        case .statue:
            // `.HandleStatueSprite @ 100664a8` (SW, `StatueSprite.handle`): its `.AddLight` / `.RemoveLight` on `lightTable`.
            StatueSprite.handle(world: world, id: id, lights: &self.lightTable)
        case .cannoned:
            // `.HandleCannonedSprite` (W2b).
            BackgroundSprite.handleCannoned(world: world, id: id, keys: actions, lights: &self.lightTable)
        case .box:
            // `.HandleBoxSprite` (W3; C1 NPCs; BX1 the arms and the tail — the fall through `solver`, `.KillCrate`'s
            // effects and drops on `lightTable`).
            BoxSprite.handle(world: world, id: id, solver: solver, lights: &self.lightTable, effects: effects,
                             faceBounds: bounds)
        case .rope:
            RopeSprite.handle(world: world, id: id)                           // `.HandleRopeSprite` (W3)
        case .ropeSegment:
            RopeSprite.handleSegment(world: world, id: id) { Self.frameRect($0, resources: res).right }
        }
    }

    /// IU: the handle pass stopped inside the player's Handle (a hint at the item switch): the frame so far goes out
    /// with `suspension` set; `nested` = inside a `.CheckGameLoopKeys` / `.Pause` redraw (`suspendedInNestedPass`).
    private func suspendHandlePass(_ ops: FrameOps, nested: Bool) -> FrameOps {
        suspendedInNestedPass = nested
        return suspend(ops)
    }

    /// IU: the pending hint was raised inside a nested `.PaintFrameWrap` (the pause's or `.CheckGameLoopKeys`' redraw)
    /// — its resume finishes that pass, then hands back to the outer modal's state machine. False otherwise.
    public private(set) var suspendedInNestedPass = false

    /// IU: `resume(.hint)` — the player's Handle on from the switch (`Player.resumeAfterHint`, with the resumed keys),
    /// its map writes' ops, the handle pass from the player's saved `next`, `.MTCollideSprites`, the special pass, then
    /// the frame's (or the nested pass's) end.
    private func continueHandlePass(_ ops: FrameOps) -> FrameOps {
        var ops = ops
        let nested = suspendedInNestedPass
        suspendedInNestedPass = false
        Player.resumeAfterHint(world: world, keys: frameActions, solver: solver)
        ops.draws.append(contentsOf: world.player.tileOps)
        world.player.tileOps = []
        let actions = frameActions
        guard world.continueHandleSprites({ world, id in handleOne(world, id, actions: actions, ops: &ops) }) else {
            return suspendHandlePass(ops, nested: nested)
        }
        afterHandlePass(nested: nested)
        guard world.collideSpecial(hitPlayer: hitPlayer, hit: hit) else { return suspend(ops) }
        return afterSpecialPass(ops)
    }

    /// The suspended frame's modal moment (S1), nil while none is pending.
    public var suspension: FrameSuspension? { world.suspension }

    /// S1: finishes the suspended frame with the modal's answer — the rest of the arm that suspended
    /// (`HitPlayerSprite.savePointDone`), then the special pass from the **next** contact (its iteration state kept),
    /// then the frame's end (passage draws, particles, erase, status bar, `.UpdateSprites`, the async gamma step, the
    /// sounds). Returns those ops — suspended again when a later contact is modal too.
    ///
    /// P1: a `.gameLoopKeys` suspension goes on with `.CheckGameLoopKeys`' branch tail (`GameLoopKeys`), which may run a
    /// nested `.PaintFrameWrap` — whose own special pass can suspend at a save point: its `resume(.savePoint)` then
    /// finishes that nested pass and goes on where it was called.
    ///
    /// VS: `playing` is the playing set of the tick that resumes (`SoundVoices`); a nested `.PaintFrameWrap` run from
    /// here reads it plus its own calls.
    public func resume(_ outcome: FrameSuspension.Outcome, playing: Set<Int16> = []) -> FrameOps {
        guard let pending = world.suspension else { preconditionFailure("FerazelSession.resume without a suspension") }
        world.suspension = nil
        world.voices = SoundVoices(playing: playing, prefs: prefs)
        var ops = FrameOps()
        switch (pending, outcome) {
        case (.savePoint(let record), .savePoint(let saved)):
            let tail = HitPlayerSprite.savePointDone(world, record: record, saved: saved)
            ops.draws += tail.draws
            ops.requests += tail.requests
        case (.gameLoopKeys(let event), .gameLoopKeys(let answer)):
            return keysAnswered(event, answer, ops)
        case (.conversation, .conversation(let keys, let capsLock)), (.sign, .sign(let keys, let capsLock)):
            // C1: `.Conversation` / `.SimpleConv` returned; a sign / grave arm goes on with its `+0x15c` gate and
            // `.PlatformBounce` (`talkDone`; the NPC arm has returned already). The rest of the frame — the later
            // contacts' `.IsInputKeyPressed`, `.CheckGameLoopKeys` — reads the input polled at the return (live in
            // the original: `_IsPressed` is `GetKeys`), not the frame start's.
            frameKeys = keys
            frameCapsLock = capsLock
            frameActions = InputActions(keys: keys, prefs: prefs)
            if let p = world.playerID { HitPlayerSprite.talkDone(world, player: p) }
        case (.upgrade, .upgrade(let keys, let capsLock)):
            // PK: the arm returns after its loops; the rest of the frame reads the input polled at the resume tick
            // (live in the original, as after a conversation).
            frameKeys = keys
            frameCapsLock = capsLock
            frameActions = InputActions(keys: keys, prefs: prefs)
        case (.hint, .hint(let keys, let capsLock)):
            // IU: `.SimpleConv` returned inside the player's Handle: the rest of the Handle, the handle pass and the
            // frame read the input polled at the return (live in the original).
            frameKeys = keys
            frameCapsLock = capsLock
            frameActions = InputActions(keys: keys, prefs: prefs)
            return continueHandlePass(ops)
        case (.teleport(let record, 1), .teleport(let keys, let capsLock)):
            // TP: the out-mosaic returned — the move, the camera re-seat (120 passes), `.HandleIdleSprites`,
            // `.WrapDrawSprites`, snd 420 (`_DAT_100a03e0`, M l. 49463–49465), then the in-mosaic: suspended again.
            frameKeys = keys
            frameCapsLock = capsLock
            frameActions = InputActions(keys: keys, prefs: prefs)
            if let p = world.playerID {
                HitPlayerSprite.teleportMove(world, player: p) { passageSnap(passes: Self.teleportPasses) }
            }
            idleAndSprites()
            world.player.cue(PlayerCue(call: .reg, snd: 420, priority: 1, volume: 0x100))
            world.suspension = .teleport(record: record, stage: 2)
            return suspend(ops)
        case (.teleport, .teleport(let keys, let capsLock)):
            // TP: the in-mosaic returned — `.RedrawEntireScrollGrid`, `0708 = 0`, the charge −59 (M l. 49467–49469);
            // the rest of the frame reads the input polled at the resume tick (live in the original).
            frameKeys = keys
            frameCapsLock = capsLock
            frameActions = InputActions(keys: keys, prefs: prefs)
            world.player.passDraws.append(scrollOp(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV)))
            HitPlayerSprite.teleportDone(world)
        case (.savePoint, _), (.gameLoopKeys, _), (.conversation, _), (.sign, _), (.upgrade, _), (.hint, _),
             (.teleport, _):
            preconditionFailure("FerazelSession.resume: the outcome does not answer \(pending)")
        }
        guard world.continueSpecialPass(hitPlayer: hitPlayer, hit: hit) else { return suspend(ops) }
        return afterSpecialPass(ops)
    }

    /// The frame's `.IsInputKeyPressed` answers and draw flag, kept across a suspension (S1).
    private var frameActions: InputActions = []
    private var frameDraw = true

    // MARK: P1 — `.CheckGameLoopKeys`

    /// `DAT_100a5106`: set by ⌘Q / ⌘W / Esc OK and File ▸ Abort Game while paused — the loop ends after this iteration
    /// (`LevelRun` reports `.aborted`).
    public private(set) var loopAborted = false
    /// `PTR_DAT_1009fe14`: the pause debounce — decremented while > 0, zeroed by `.Pause`'s exit; never set > 0 (BC15).
    /// (`*_DAT_1009fddc`, the other counter, has no reader: not modelled.)
    public private(set) var pauseDebounce: Int16 = 0
    /// The polled input of the frame (and, after an answer, of the answer's tick): `.CheckGameLoopKeys` reads the keys
    /// and `.CapsLockDown()` live.
    private var frameKeys = KeyState()
    private var frameCapsLock = false
    /// QT (D40, Ben's Q5 — a departure from the original, which queues the quit event): a system Quit (Dock / app
    /// menu) asked for while the level runs free. The next `.CheckGameLoopKeys` past its gates takes the ⌘Q branch
    /// (`.confirmQuit`) as if ⌘Q were down — no key is faked, so no other key read sees it — and clears the request.
    public private(set) var systemQuitPending = false

    /// QT: `LevelRun.systemQuit` — raise the ⌘Q confirm at the next `.CheckGameLoopKeys`.
    func requestSystemQuit() {
        systemQuitPending = true
    }

    /// Where a finished special pass goes on: the frame's own `.PaintFrameWrap`, or a nested one (P1) and what follows
    /// it in `.CheckGameLoopKeys` / `.Pause`.
    private enum AfterSpecial {
        case mainPaint
        case nestedPaint(NestedTail)
    }

    private enum NestedTail {
        /// ⌘Q / ⌘W / Esc OK: `DrawBlackLines`, `DAT_100a5106 = 1`, `.UpdateStatusBar(0, 0, 0)` (+ ⌘Q `.Quit`).
        case confirmOK(GameLoopKeyEvent)
        /// Esc Cancel: `.UpdateStatusBar(0, 0, 0)`.
        case escapeCancel
        /// `.Pause`'s `.PaintFrameWrap(1, 0)`: back to the flow (`.paused`).
        case pausePaint
    }

    private var afterSpecial = AfterSpecial.mainPaint

    private func afterSpecialPass(_ ops: FrameOps) -> FrameOps {
        switch afterSpecial {
        case .mainPaint:
            return finishFrame(ops)
        case .nestedPaint(let tail):
            afterSpecial = .mainPaint
            var ops = ops
            paintTail(&ops)
            return nestedDone(tail, ops)
        }
    }

    /// `.CheckGameLoopKeys @ 10007684` from its start (M l. 3880ff; `GameLoopKeys`), after the frame's
    /// `.PaintFrameWrap`: the gates, the key branch (suspends for the flow), else the counters and Caps Lock.
    private func checkGameLoopKeys(_ ops: FrameOps) -> FrameOps {
        guard !world.gammaFade.fadedOut, world.gammaFade.done else { return loopTail(ops) }
        let asked: GameLoopKeyEvent? = systemQuitPending ? .confirmQuit : nil
        systemQuitPending = false
        guard let e = asked ?? GameLoopKeys.branch(frameKeys) else { return keysCounters(ops) }
        var ops = ops
        // `.RestoreWindowBackground` (`DrawBlackLines` in mode 3), `ShowCursorSafe`, `FlushEvents`, `InputActivate(0,
        // 0)` (⌘P: `FlushEvents` before `ShowCursorSafe`).
        drawBlackLines(&ops)
        ops.requests.append(.showCursor)
        world.suspension = .gameLoopKeys(e)
        return suspend(ops)
    }

    /// The debounce counters, then `CapsLockDown() && fe14 == 0` → `.Pause` (its own gate `DAT_100a53d6`, M l. 3171 —
    /// a nested pass may have started an async fade).
    private func keysCounters(_ ops: FrameOps) -> FrameOps {
        if 0 < pauseDebounce { pauseDebounce -= 1 }
        if frameCapsLock && pauseDebounce == 0 && world.gammaFade.done {
            world.suspension = .gameLoopKeys(.pause)
            return suspend(ops)
        }
        return loopTail(ops)
    }

    /// The flow answered a `.gameLoopKeys` suspension (`GameLoopKeys` header for each tail).
    private func keysAnswered(_ event: GameLoopKeyEvent, _ answer: GameLoopKeyAnswer, _ ops: FrameOps) -> FrameOps {
        var ops = ops
        frameKeys = answer.keys
        frameCapsLock = answer.capsLock
        let h = camera.scrollH, v = camera.scrollV
        switch (event, answer.reply) {
        case (.confirmQuit, .confirm(ok: true)), (.confirmAbort, .confirm(ok: true)):
            return nestedPaintFrameWrap(then: .confirmOK(event), ops)
        case (.confirmQuit, .confirm(ok: false)), (.confirmAbort(escape: false), .confirm(ok: false)):
            ops.draws.append(scrollOp(.redrawEntireScrollGrid(h: h, v: v)))
            drawBlackLines(&ops)
            ops.draws.append(statusBarInFrame(.confirmCancel, keys: frameKeys))      // M l. 3977, 4002
            return keysCounters(ops)
        case (.confirmAbort(escape: true), .confirm(ok: false)):
            ops.draws.append(scrollOp(.redrawEntireScrollGrid(h: h, v: v)))
            drawBlackLines(&ops)
            return nestedPaintFrameWrap(then: .escapeCancel, ops)
        case (.options, .optionsClosed):
            // `.SetScrollLocation`, `.RedrawEntireScrollGrid`, `.UpdateStatusBar(0, 0, 0)`, `fe0c = 1`, `511e = 1` (no
            // Core reader), `DrawBlackLines` (mode 3).
            ops.draws.append(scrollOp(.redrawScrollGrid(h: h, v: v)))
            ops.draws.append(scrollOp(.redrawEntireScrollGrid(h: h, v: v)))
            ops.draws.append(statusBarInFrame(.optionsClosed, keys: frameKeys))      // M l. 3956
            drawBlackLines(&ops)
            return keysCounters(ops)
        case (.pause, .pausePaint):
            return nestedPaintFrameWrap(then: .pausePaint, ops)
        case (.paused, .pauseEnded(let aborted)):
            // `.AbortGame`'s OK inside the pause: `DAT_100a5106 = 1`; `.Pause`'s exit: `fe14 = 0`. `.CheckGameLoopKeys`
            // returns after `.Pause`.
            if aborted { loopAborted = true }
            pauseDebounce = 0
            return loopTail(ops)
        default:
            preconditionFailure("FerazelSession.resume: \(answer.reply) does not answer \(event)")
        }
    }

    /// A nested `.PaintFrameWrap(1, odd)` inside `.CheckGameLoopKeys` / `.Pause`: a whole drawn pass — the Handles, the
    /// collisions, the special pass (which can suspend at a save point), the particles and the erase — on the frame's
    /// scroll point, with the live keys.
    private func nestedPaintFrameWrap(then tail: NestedTail, _ ops: FrameOps) -> FrameOps {
        var ops = ops
        let actions = InputActions(keys: frameKeys, prefs: prefs)
        frameActions = actions
        afterSpecial = .nestedPaint(tail)
        // IU: its handle pass can reach the player's item switch too (a hint with USE held on a key / shield / Red
        // Xichron): suspended the same way, finished by `resume(.hint)`, which then goes on with `tail`.
        guard paintFrameWrap(draw: true, actions: actions, nested: true, into: &ops) else {
            return suspendHandlePass(ops, nested: true)
        }
        guard world.collideSpecial(hitPlayer: hitPlayer, hit: hit) else { return suspend(ops) }
        afterSpecial = .mainPaint
        paintTail(&ops)
        return nestedDone(tail, ops)
    }

    /// `if (prefs+2 == 3) _DrawBlackLines()` — the session is never on the map (`fe2c` 0).
    private func drawBlackLines(_ ops: inout FrameOps) {
        if prefs.graphics == 3 { ops.draws.append(.drawBlackLines) }
    }

    private func nestedDone(_ tail: NestedTail, _ ops: FrameOps) -> FrameOps {
        var ops = ops
        switch tail {
        case .confirmOK(let event):
            // `DrawBlackLines` (mode 3), `DAT_100a5106 = 1`, `FlushEvents`, `.UpdateStatusBar(0, 0, 0)`.
            drawBlackLines(&ops)
            loopAborted = true
            ops.draws.append(statusBarInFrame(.confirmOK, keys: frameKeys))          // M l. 3928, 3986, 4011
            if event == .confirmQuit {
                // `.Quit()` never returns: the frame stops here.
                world.suspension = .gameLoopKeys(.quit)
                return suspend(ops)
            }
            return keysCounters(ops)
        case .escapeCancel:
            ops.draws.append(statusBarInFrame(.escapeCancel, keys: frameKeys))       // M l. 3919
            return keysCounters(ops)
        case .pausePaint:
            world.suspension = .gameLoopKeys(.paused)
            return suspend(ops)
        }
    }

    /// `.HitPlayerSprite` with the frame's key snapshot.
    /// PK: on a copy of `lightTable` written back after the call — the passage arm's `PassageView` reads the table
    /// inside the call (`passageRedraw`), which an `inout` of the stored table would make an exclusivity conflict.
    private func hitPlayer(_ w: SpriteWorld, _ p: Int, _ c: Int) {
        var table = lightTable
        HitPlayerSprite.hit(w, player: p, other: c, keys: frameActions, lights: &table, effects: prefs.effects)
        lightTable = table
    }

    /// The frame so far, handed out at a suspension (S1): the pass's draws and requests so far (`drainPass`), the sound calls
    /// made so far (the Sound Tool has already started them), and — for a save point — `ShowCursorSafe` (raw
    /// `100577a4`, made before `.SavePointSave`).
    private func suspend(_ ops: FrameOps) -> FrameOps {
        var ops = ops
        drainPass(&ops)
        SoundCues.emit(world.player.soundCalls, prefs: prefs, into: &ops)
        world.player.soundCalls = []
        ops.drawn = frameDraw
        ops.suspension = world.suspension
        if case .savePoint? = world.suspension { ops.requests.append(.showCursor) }
        return ops
    }

    /// The frame after the special pass (unchanged order; S1 split it out so `resume` can finish a frame): the end of
    /// `.PaintFrameWrap`, then (P1, hosted) `.CheckGameLoopKeys`, then the rest of the iteration.
    private func finishFrame(_ ops: FrameOps) -> FrameOps {
        var ops = ops
        paintTail(&ops)
        return hostedByLevelRun ? checkGameLoopKeys(ops) : loopTail(ops)
    }

    /// The draws and requests the player pass made (`PlayerState.passDraws` / `passRequests`), in call order: a
    /// passage jump's (`PassageView`, W2b) and the pickup arms' status bar calls (PK) share one list — the original
    /// draws each to the screen as it is made, so they interleave in contact order; the upgrade's cursor hide.
    private func drainPass(_ ops: inout FrameOps) {
        ops.draws.append(contentsOf: world.player.passDraws)
        world.player.passDraws = []
        ops.requests.append(contentsOf: world.player.passRequests)
        world.player.passRequests = []
    }

    /// `.PaintFrameWrap`'s end after the special pass.
    private func paintTail(_ ops: inout FrameOps) {
        drainPass(&ops)
        // `.HandleParticles` (l. 9454), after `.HandleSprites` and before `.WrapEraseSprites`.
        world.particles.handle(tiles: world.tiles)
        // `.WrapEraseSprites` reads the live scroll point (`PTR_DAT_1009fe78`, l. 10452–10458): on a passage jump the
        // snap and its 90 `.FindUpperLeftCorner` passes (inside `.MTCollideSpecialSprite`) have just moved it.
        ops.draws.append(.wrapEraseSprites(sprites: world.active.sprites, h: camera.scrollH, v: camera.scrollV))
    }

    /// `.GameLoop` after `.CheckGameLoopKeys` (M l. 5252–5294): `.UpdateSprites`, `.UpdateStatusBar(1, 0, 0)`, the
    /// async gamma step, the loop test.
    private func loopTail(_ ops: FrameOps) -> FrameOps {
        var ops = ops
        let draw = frameDraw
        ops.draws.append(statusBarInFrame(.loopIteration, keys: frameKeys))          // M l. 5280
        ops.drawn = draw
        odd.toggle()
        // `.GameLoop`'s boss-music block reads "no boss alive" here, before `.UpdateSprites` (M l. 5266–5275).
        noBossAliveAtMusicRule = world.arena.noBossAlive
        // Back in `.GameLoop` after the events, keys, sounds and track map: `.UpdateSprites` (raw `1000a298`).
        world.updateSprites(lights: &lightTable)
        // `.HandleAsyncGammaFade` (l. 5282, after `.UpdateStatusBar(1, 0, 0)`; W2b — the passages start the fades).
        let fadingIn = !world.gammaFade.done && world.gammaFade.fadingIn
        if let g = world.gammaFade.handle() { ops.draws.append(g) }
        // A fade-in's end call: `_ShowCursorSafe()` (M l. 31945; L1 review fix) — the next iteration's top hides it
        // again. Hosted only: the non-hosted path sends no per-iteration hide, so a show there would linger.
        if hostedByLevelRun && fadingIn && world.gammaFade.done { ops.requests.append(.showCursor) }
        // `while (DAT_100a5106 == 0 && *_DAT_100a0088 == 0)` (l. 5229): game over or level complete ends the loop
        // after this iteration (W4); P1: `DAT_100a5106` from ⌘Q / ⌘W / Esc OK or the pause's Abort Game.
        let endsNow = !loopEnded && (world.player.gameOver || world.player.levelDone || loopAborted)
        if endsNow {
            loopEnded = true
            if !hostedByLevelRun {
                let request = loopEnd()
                ended = request
                ops.requests.append(request)
            }
            // The player pass's cues (the exit's snd 421) start at once in the original (the Sound Tool); the loop
            // ends before the next Handle pass would hand them out, so the last iteration hands them out after its
            // Handle pass's cues. Normal iterations keep the once-per-frame drain above.
            frameCues += world.player.cues
            world.player.cues = []
        }
        // S1: the iteration's sound calls — the handle pass's and the player pass's, in call order, each under the
        // scroll point it was made at — as the Sound Tool takes them (`SoundCues`).
        SoundCues.emit(world.player.soundCalls, prefs: prefs, into: &ops)
        world.player.soundCalls = []
        if endsNow {
            // After the loop (l. 5300–5310): `FUN_10091504` of 452 (`*_DAT_1009fe24`) and 511 (`*_DAT_1009fe20`);
            // G+4 ≥ 1 with the level complete (`*_DAT_100a0088`) stops 452, 453 (`*_DAT_1009fd68`) and 511 again.
            for snd: Int16 in [452, 511] { ops.stopSound(snd) }
            if globals.health >= 1 && world.player.levelDone { for snd: Int16 in [452, 453, 511] { ops.stopSound(snd) } }
        }
        return ops
    }

    /// After the loop (l. 5296–5322), for a session not hosted by `LevelRun` (a directly built one — Core tests): G+4 < 1
    /// → `*_DAT_1009ffa8 = 1` and `.deathEffect`; else level complete → `.loadLevel` of the level the exit unlocks
    /// (`LevelFlow.next`; the current level when it unlocks none). The stage-complete screen, `.EndLevelSGUpdate` and
    /// the world map are `LevelRun`'s / `GameFlow`'s (the app's path from A1a). A game over with G+4 ≥ 1 takes the
    /// death path too.
    private func loopEnd() -> ShellRequest {
        if globals.health < 1 {
            world.playerDead = true
            return .deathEffect
        }
        if world.player.levelDone {
            let next = LevelFlow.next(level: level.header.mapNodeLevel, exit: world.player.exitIndex, map: map)
            return .loadLevel(next.map(Int.init) ?? levelNumber)
        }
        return .deathEffect
    }

    /// OX: `.TurnOffOmniPx` then `.KillOmniPx` at `.GameLoop`'s exit (M l. 5321–5322; `OmniPx.turnOff`, `kill`).
    public func turnOffAndKillOmniPx() {
        var L = world.level, g = world.globals
        omniPx.turnOff(level: &L, globals: &g)
        omniPx.kill()
        world.level = L
        world.globals = g
    }

    /// LV5 fix round: `*_DAT_1009fed0` ("no boss alive", `BossArena.noBossAlive`) as `.GameLoop`'s in-loop
    /// boss-music block reads it — after the events, keys, sounds, track map and FPS, before `_UpdateSprites` (M l.
    /// 5266–5275); `LevelRun`'s rule, which runs at the iteration's end, reads this rather than the live flag.
    public private(set) var noBossAliveAtMusicRule: UInt8 = 1

    /// What the next level's session takes (`init(…carry:)`, W4): the parity, the particle counters (E1a), the
    /// water-effects cache, origin and flag (E1b), the flash, paint counter, plume count and shake (EF), the Shadow-Double ring's mirror bytes (SD), and the live G with its crunch log (A1a: the flow decides when a
    /// game starts from a fresh G — New Game's `.InitGameGlobals` — never the session).
    public var carry: LevelCarry {
        var c = LevelCarry(parity: world.parity, crunchLog: world.globals.crunchLog, globals: world.globals)
        c.particles = world.particles.counters
        c.waterCells = waterEffects.cells
        c.waterOriginCol = waterEffects.originCol
        c.waterOriginRow = waterEffects.originRow
        c.tileCacheValid = world.player.tileCacheValid
        c.statusBar = world.statusBar
        c.flash = world.flash
        c.paintCounter = world.paintCounter
        c.plumeCount = world.plumeCount
        c.shake = world.shakeStore ?? camera.shake                     // CS: a store the camera has not yet taken
        c.shadowMirrors = world.player.shadowRing.map(\.mirrored)        // SD review fix
        c.omniPxCounter = omniPx.counter                                 // OX: `c` runs on (BSS)
        c.panCounter = world.arena.panCounter                            // LV5 fix round: `*_DAT_1009ff9c` runs on
        return c
    }

    /// `PassageView.snap` (`.HitPlayerSprite` l. 49659–49672, W2b): the camera snapped to (player x − 0x142, y − 0xc0),
    /// then 90 `.FindUpperLeftCorner` passes with the focus the arm just set (`*_DAT_1009fec4`, the auto-scroll mode, is
    /// saved, zeroed and restored around them — auto-scroll is refused by `Camera.init`, so it is 0 throughout); the
    /// scroll location `_DAT_1009fe74/fe70` takes the scroll point (`DrawOp.setDrawnScroll`: the renderer's grid
    /// redraws the window there); `.RedrawEntireScrollGrid`.
    /// TP: the teleport's re-seat is the same code with 120 passes (`sVar36 < 0x78`, M l. 49451), `+0xdc = 0` set by
    /// the arm before it (`HitPlayerSprite.teleportMove`).
    private func passageSnap(passes: Int = FerazelSession.passagePasses) {
        guard let p = world.playerID.flatMap({ world.active.record(id: $0) }) else { return }
        camera.snap(playerX: p.x, playerY: p.y)
        world.player.scrollH = camera.scrollH
        world.player.scrollV = camera.scrollV
        for _ in 0..<passes { findUpperLeftCorner(graphics: prefs.graphics) }
        // `*piVar17 = scroll h; *piVar47 = scroll v` (`_DAT_1009fe74/fe70`, the grid's drawn location): the
        // `.RedrawEntireScrollGrid` after it redraws the window at the new view, not at the last strip redraw's.
        world.player.passDraws.append(scrollOp(.setDrawnScroll(h: camera.scrollH, v: camera.scrollV)))
        world.player.passDraws.append(scrollOp(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV)))
    }

    /// The passage jump's `.FindUpperLeftCorner` passes (`sVar36 < 0x5a`, l. 49666).
    public static let passagePasses = 0x5a
    /// TP: the teleport's (`sVar36 < 0x78`, M l. 49451).
    public static let teleportPasses = 0x78

    /// `PassageView.redraw` (l. 49676–49678): `.HandleIdleSprites` at the new view (the live player's rect),
    /// `.WrapDrawSprites`, `.RedrawEntireScrollGrid`.
    private func passageRedraw() {
        idleAndSprites()
        world.player.passDraws.append(scrollOp(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV)))
    }

    /// `.HandleIdleSprites` at the current view (the live player's rect) and `.WrapDrawSprites` into the pass's draws —
    /// the passage jump's (before its `.RedrawEntireScrollGrid`) and the teleport's (M l. 49461–49462).
    private func idleAndSprites() {
        let playerRect = world.playerID.flatMap { world.active.record(id: $0) }.map { p in
            IdleSprites.Rect(top: p.y + p.hotRect.top, left: p.x + p.hotRect.left, bottom: p.y + p.hotRect.bottom,
                             right: p.x + p.hotRect.right)
        }
        world.idle.handle(h: camera.scrollH, v: camera.scrollV, playerHotRect: playerRect, active: &world.active,
                          faceRect: faceBounds)
        world.player.passDraws.append(wrapDrawSpritesOp())
    }

    /// `.WrapDrawSprites` of the active list as it stands (the passage's and the teleport's; TP: `.MosaicTransition`'s
    /// own, `LevelRun`), each sprite's dynamic light from the light table.
    func wrapDrawSpritesOp() -> DrawOp {
        let table = lightTable, bounds0 = faceBounds, res = resources, lvl = level
        return .wrapDrawSprites(diffuseSeeds(world.active.wrapDrawSprites { s in
            Self.dynamicLight(s, level: lvl, lights: table, bounds: bounds0) { Self.frameRect($0, resources: res) }
        }, h: camera.scrollH, v: camera.scrollV))
    }

    /// Mode 5's draw-time randoms (draw-effects §2.3): `.BlitEncFaceDiffuse` calls `.FastRand` per drawn pixel inside
    /// `.WrapDrawSprites`, between the frame's logic before it and the Handles after it, in list order. Each mode-5
    /// draw takes the stream's seed at its place (`SpriteDraw.randomSeed`, which the renderer replays) and the stream
    /// moves on by the renderer's walk of that draw. Nothing else in `.WrapDrawSprites` draws a random, so seeding
    /// after the Core pass keeps the binary's order.
    /// SP: with `diffuseRandomsAt` the walk is asked at the renderer's own scroll point and drawn pair for this op
    /// (`rendererScroll`, from the scroll ops emitted so far — the op is drawn right after them), so the two take the
    /// same count by construction; without it, `diffuseRandoms` at (h, v), the caller's camera pair (before SP).
    private func diffuseSeeds(_ draws: [SpriteDraw], h: Int, v: Int) -> [SpriteDraw] {
        let at = rendererScroll
        return draws.map { d in
            guard d.mode >> 16 == 5 else { return d }
            var d = d
            d.randomSeed = world.rng.seed
            if let walk = diffuseRandomsAt {
                walk(d, at.h, at.v, at.drawnH, at.drawnV, &world.rng)
            } else {
                diffuseRandoms?(d, h, v, &world.rng)
            }
            return d
        }
    }

    /// SP: what the renderer's scroll state becomes after `op` (`FrameRenderer.apply`): `.redrawScrollGrid` → the
    /// scroll point (h, v) as passed and the drawn pair `.SetScrollLocation`'s clamp of it (M l. 9488–9499:
    /// negative → 0, `(h + 0x280) >> 5 > 0x200` → 0x3da0, `(v + 0x1a0) >> 5 > 0x200` → 16000; then
    /// `*_DAT_1009fe74/fe70` = the clamped pair, M l. 9532–9533; `TileGridRenderer.setScrollLocation`); `.redrawEntireScrollGrid` → the scroll point only;
    /// `.setDrawnScroll` → the drawn pair only (the re-seat, M l. 49453–49456 / 49669–49671). Both start at (0, 0), as
    /// the renderer's do. The binary's blits read the live scroll point `PTR_DAT_1009fe78` (the camera,
    /// `.FindUpperLeftCorner`'s); the session emits every scroll op at the camera before any `.WrapDrawSprites` reads
    /// it, so this equals the camera at every site the session reaches today.
    struct RendererScroll: Equatable {
        var h = 0, v = 0, drawnH = 0, drawnV = 0

        mutating func note(_ op: DrawOp) {
            switch op {
            case .redrawScrollGrid(let h, let v):
                self.h = h
                self.v = v
                var ch = max(h, 0), cv = max(v, 0)
                if (ch + 0x280) >> 5 > 0x200 { ch = 0x3da0 }
                if (cv + 0x1a0) >> 5 > 0x200 { cv = 16000 }
                drawnH = ch
                drawnV = cv
            case .redrawEntireScrollGrid(let h, let v):
                self.h = h
                self.v = v
            case .setDrawnScroll(let h, let v):
                drawnH = h
                drawnV = v
            default:
                break
            }
        }
    }

    /// SP: a scroll op this session emits, noted (`rendererScroll`) as it is made.
    private func scrollOp(_ op: DrawOp) -> DrawOp {
        noteRendererScroll(op)
        return op
    }

    /// SP: the renderer's scroll state follows `op` (the session's own scroll ops come through here).
    func noteRendererScroll(_ op: DrawOp) { rendererScroll.note(op) }

    /// A sprite's hit callback `+0x5c` (`SpriteWorld` calls it only when `hasHit`): `.HitPlatformSprite` (W1); the
    /// Effect class's `.HitEffectSprite` is empty; `.HitBackgroundSprite` (W2b: cannons, springs, wall tunnels);
    /// `.HitBonusSprite` (BN; its container arm SH); `.HitPlayerShotSprite` (SH); the Box class's `.HitBoxSprite` (SH:
    /// the stalactite's shot case; BX1 the rest; SW: a Statue's hit is the Box class's, `.TurnIntoStatue`);
    /// `.HitButtonSprite` (BT); `.HitEnemyShotSprite` (ES); `.HitWalkerSprite` (WK1; also the corpse raft's, kept
    /// under the Platform Handle); `.HitCrawlerSprite` / `.HitRoachSprite` (CR); `.HitBatSprite` /
    /// `.HitSwarmMemberSprite` (BA); `.HitFrogSprite` / `.HitSalamanderSprite` (FR); `.HitBlobSprite` / `.HitCrabSprite`
    /// (BL); `.HitGremlinSprite` / `.HitFloaterSprite` (GF); `.HitDilloSprite` (DL); ◇ `.HitWarriorSprite` (LV5: an
    /// empty body; the other side of each pair still gets its own hit). // later: Phase 6 (the bosses). The session's
    /// form:
    /// `hitCallback` on `lightTable`.
    private func hit(_ w: SpriteWorld, _ a: Int, _ b: Int) {
        let res = resources
        Self.hitCallback(w, a, b, lights: &lightTable, effects: prefs.effects,
                         faceWidth: { Self.frameRect($0, resources: res).right }, faceBounds: faceBounds)
    }

    /// The test-only form (no light table): its light calls go to a scratch table.
    static func hitCallback(_ w: SpriteWorld, _ a: Int, _ b: Int) {
        var scratch = LightTable()
        hitCallback(w, a, b, lights: &scratch)
    }

    /// LT: `hitCallback` with the light calls made on `lights` (`.TurnIntoCannoned`'s `.RemoveLight`). CS: `effects`
    /// (prefs+6), `faceWidth` and `faceBounds` reach `.KillPlayerShot` (the spring arm; its effect sprite's Setup, its
    /// `.StandardSpriteCleanup` and its clip test).
    static func hitCallback(_ w: SpriteWorld, _ a: Int, _ b: Int, lights: inout LightTable, effects: Int16 = 1,
                            faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                            faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: a) else { return }
        switch s.handler {
        case .platform where s.walkerCallbacks:                                         // the corpse raft (WK1)
            Walker.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                       faceBounds: faceBounds)
        case .platform: PlatformSprite.hit(w, id: a, other: b)
        case .walker:                                                                   // `.HitWalkerSprite` (WK1)
            Walker.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                       faceBounds: faceBounds)
        case .crawler:                                                                  // `.HitCrawlerSprite` (CR)
            CrawlerRoach.hitCrawler(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                    faceBounds: faceBounds)
        case .roach:                                                                    // `.HitRoachSprite` (CR)
            CrawlerRoach.hitRoach(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                  faceBounds: faceBounds)
        case .bat:                                                                      // `.HitBatSprite` (BA)
            Bat.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth, faceBounds: faceBounds)
        case .swarmMember:                                                              // `.HitSwarmMemberSprite` (BA)
            Bat.hitSwarmMember(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                               faceBounds: faceBounds)
        case .frog:                                                                     // `.HitFrogSprite` (FR)
            FrogSalamander.hitFrog(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                   faceBounds: faceBounds)
        case .salamander:                                                               // `.HitSalamanderSprite` (FR)
            FrogSalamander.hitSalamander(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                         faceBounds: faceBounds)
        case .blob:                                                                     // `.HitBlobSprite` (BL)
            BlobCrab.hitBlob(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                             faceBounds: faceBounds)
        case .crab:                                                                     // `.HitCrabSprite` (BL)
            BlobCrab.hitCrab(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                             faceBounds: faceBounds)
            // The dead Blob (`+0x5c` cleared in state 4) and the Crab's links (`+0x5c` 0) have no hit callback.
        case .gremlin:                                                                  // `.HitGremlinSprite` (GF)
            GremlinFloater.hitGremlin(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                      faceBounds: faceBounds)
        case .floater:                                                                  // `.HitFloaterSprite` (GF)
            GremlinFloater.hitFloater(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                      faceBounds: faceBounds)
        case .dillo:                                                                    // `.HitDilloSprite` (DL)
            Dillo.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth, faceBounds: faceBounds)
        case .warrior: break                    // ◇ `.HitWarriorSprite` (LV5: `+0x5c` stored) // later: Phase 6
        case .background:                                                               // `.HitBackgroundSprite` (W2b)
            BackgroundSprite.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                                 faceBounds: faceBounds)
        case .bonus:                                                                    // `.HitBonusSprite` (BN, SH)
            BonusSprite.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                            faceBounds: faceBounds)
        case .playerShot:                                                               // `.HitPlayerShotSprite` (SH)
            PlayerShotHits.hit(w, shot: a, other: b, effects: effects, lights: &lights, faceWidth: faceWidth,
                               faceBounds: faceBounds)
        case .box, .statue:                     // `.HitBoxSprite` (SH, BX1; SW: the Statue's hit `PTR_PTR_100a01f4`)
            BoxSprite.hit(w, id: a, other: b, lights: &lights, effects: effects, faceWidth: faceWidth,
                          faceBounds: faceBounds)
        case .button: ButtonSprite.hit(w, id: a, other: b)                              // `.HitButtonSprite` (BT)
        case .enemyShot:                                                                // `.HitEnemyShotSprite` (ES)
            EnemyShot.hit(w, shot: a, other: b, lights: &lights, effects: effects)
        default: break
        }
    }

    /// The `+0x89` inputs of `.WrapDrawSprites` (l. 10282–10297; raw `1001472c..100147bc`): L = `.GetLightTile(+0x10 >>
    /// 5, +0xe >> 5)` (the BG cell's high byte − 1, `LevelFile.lightByte`; the hot-rect centre, `srawi`), F =
    /// `.GetFakeLight` (`fakeLight`). `SpriteSlot.applyDynamicLight` turns them into `+0xb8`. The original computes them
    /// only for a sprite whose face passes the draw's cull (`SectRectFast`, l. 10261–10265); Core asks for every `+0x89`
    /// sprite with a face [MED: an off-view raft's word is refreshed one draw early].
    /// The test-only list form (PlatformTests): the Setup lights as a fresh table; the session uses the table form.
    static func dynamicLight(_ s: SpriteSlot, level: LevelFile, lights: [SetupFaces.Light],
                             bounds: (FaceRef) -> IdleSprites.Rect,
                             frame: (FaceRef) -> IdleSprites.Rect) -> (lightTile: Int, fakeLight: Int) {
        dynamicLight(s, level: level, lights: table(lights), bounds: bounds, frame: frame)
    }

    /// The Setup lights `list` as `.AddLight` puts them into a fresh table (slot order = list order).
    static func table(_ list: [SetupFaces.Light]) -> LightTable {
        var t = LightTable()
        for l in list {
            t.add(face: LightFaceRef(pict: l.pict, width: l.width, height: l.height), x: Int16(truncatingIfNeeded: l.x),
                  y: Int16(truncatingIfNeeded: l.y), vx: 0, vy: 0, accelY: 0, colour: Int16(truncatingIfNeeded: l.colour))
        }
        return t
    }

    /// LT: `dynamicLight` over the light table (the live `_DAT_100a0128`).
    static func dynamicLight(_ s: SpriteSlot, level: LevelFile, lights: LightTable,
                             bounds: (FaceRef) -> IdleSprites.Rect,
                             frame: (FaceRef) -> IdleSprites.Rect) -> (lightTile: Int, fakeLight: Int) {
        let L = level.lightByte(col: Int(Int16(truncatingIfNeeded: s.centre.x) >> 5),
                                row: Int(Int16(truncatingIfNeeded: s.centre.y) >> 5))
        guard let f = s.face else { return (L, 0) }
        // The drawn width / height (`iVar12` / `iVar15`, l. 10285–10298): face `+6` − left clip, less what the right
        // clip cuts; face `+4` − top clip, less what the bottom clip cuts.
        let fr = frame(f)
        let fw = fr.right, fh = fr.bottom
        var w = fw - s.clip.left
        if s.clip.right < fw { w -= fw - s.clip.right }
        var h = fh - s.clip.top
        if s.clip.bottom < fh { h -= fh - s.clip.bottom }
        return (L, fakeLight(x: s.x, y: s.y, width: w, height: h, faceBounds: bounds(f), lights: lights))
    }

    /// `.GetFakeLight(face, …, w, h, pos, &out) @ 1001d708` (decompile l. 15290–15360; lighting-tables §7.5): the first
    /// active light in slot order (LT: the light table's slots) that passes
    /// the bounding pre-test (it is skipped only when |x + w/2 − lx| ≥ lx + r + w/2 **and** |y + h/2 − ly| ≥ ly + r + h/2
    /// — the light's own coordinate added, as written), has radius `+0x14` > 0x20 and whose face rect (`+0x58` = (0, 0,
    /// height, width) offset by (lx − r, ly − r)) contains the centre of the sprite face's opaque bounds (face `+8` at
    /// (x, y); `PtInRect`, half-open): v = 11 − (`.PEDistance`(lx − px, ly − py)·11) / r (i16, C division), accepted for
    /// 0 ≤ v < 12 → v + the light's colour. Otherwise 0.
    /// The test-only list form (PlatformTests) of `fakeLight` over the table.
    static func fakeLight(x: Int, y: Int, width w: Int, height h: Int, faceBounds b: IdleSprites.Rect,
                          lights: [SetupFaces.Light]) -> Int {
        fakeLight(x: x, y: y, width: w, height: h, faceBounds: b, lights: table(lights))
    }

    /// LT: `fakeLight` over the light table. A slot pending removal (`+0` still set, face nil, radius 0) fails the
    /// `radius > 0x20` test (the binary reads its nil face's rect first; nothing of it is used).
    static func fakeLight(x: Int, y: Int, width w: Int, height h: Int, faceBounds b: IdleSprites.Rect,
                          lights: LightTable) -> Int {
        let s16 = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        for l in lights.slots where l.active {
            let r = Int(l.radius), lx = Int(l.x), ly = Int(l.y)
            let ax = abs(x + (w >> 1) - lx)
            if lx + r + (w >> 1) <= ax {
                let ay = abs(y + (h >> 1) - ly)
                if ly + r + (h >> 1) <= ay { continue }
            }
            guard let face = l.face else { continue }
            let top = ly - r, left = lx - r
            let px = s16(x + ((b.left + b.right) >> 1)), py = s16(y + ((b.top + b.bottom) >> 1))
            guard 0x20 < r, left <= px, px < left + face.width, top <= py, py < top + face.height else { continue }
            let d = peDistance(lx - px, ly - py)
            let v = s16(0xb - s16((d * 0xb) / r))
            if 0 <= v && v < 0xc { return s16(v + Int(l.colour)) }
        }
        return 0
    }

    /// `.PEDistance(a, b) @ 10047648` (decompile l. 40638–40684): max(|a|, |b|) + min(|a|, |b|) / 3.
    static func peDistance(_ a: Int, _ b: Int) -> Int {
        let x = abs(a), y = abs(b)
        return max(x, y) + min(x, y) / 3
    }

    /// `.FindUpperLeftCorner` on the player's globals: the focus `(fd44, fd40)`, vx `fd3c`, `uRam100a5114`, and the
    /// snap vetoes read through `*_DAT_1009fdd8` (`+0xdc` → type 0x57a, `+0x11c`, `+0x120`) and `*_DAT_1009fd34`
    /// (cleared by the snap test). The scroll point it leaves (`PTR_DAT_1009fe78`) is what `.PlayerScroll` reads.
    private func findUpperLeftCorner(graphics: Int16) {
        if let v = world.shakeStore {                                   // CS: a Handle's or hit's `*_DAT_1009ffa0 = v`
            camera.shake = v
            world.shakeStore = nil
        }
        let p = world.player
        let s = world.playerID.flatMap { world.active.record(id: $0) }   // the live `*_DAT_1009fdd8`, not `playerID`
        let ridden = s?.ridden.flatMap { world.active.record(id: $0) }
        world.player.cameraSnapVeto = camera.findUpperLeftCorner(
            focusX: Int(p.focusX), focusY: Int(p.focusY), playerVX: Int(p.lastVX), snapArmed: p.snapArmed,
            ridingVeto: ridden?.type == Camera.snapVetoRiddenType,
            inWater: (s?.waterRow ?? 0) != 0 || (s?.lastWater ?? 0) != 0, latch: p.cameraSnapVeto,
            counter: world.paintCounter, reduceFrameRate: prefs.reduceFrameRate != 0, graphics: graphics,
            arena: &world.arena)
        world.player.scrollH = camera.scrollH
        world.player.scrollV = camera.scrollV
    }

    /// A face's frame at the origin: the sheet cell for a level-1 face set, else the PICT's picFrame (`.frontEnd`
    /// chain, as R4's tests read it); `.noFace` when the PICT is absent.
    static func frameRect(_ f: FaceRef, resources: FerazelResources) -> IdleSprites.Rect {
        if let s = SetupFaces.sheet(pict: f.pict), !s.single {
            return IdleSprites.Rect(top: 0, left: 0, bottom: s.cellHeight, right: s.cellWidth)
        }
        guard let res = resources.resource(type: "PICT", id: f.pict, chain: .frontEnd), res.data.count >= 10 else {
            return .noFace
        }
        let b = [UInt8](res.data)
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        return IdleSprites.Rect(top: 0, left: 0, bottom: i16(6) - i16(2), right: i16(8) - i16(4))
    }
}

/// The async gamma fade (lighting-tables §10; decompile l. 31872–31950), W2b: `.GammaFadeOutAsync(N, rgb) @ 100356c0`,
/// `.GammaFadeInAsync(N) @ 1003565c` and the per-iteration `.HandleAsyncGammaFade @ 10035788` (`.GameLoop` l. 5282,
/// after `.UpdateSprites` and `.UpdateStatusBar(1, 0, 0)`). Core keeps the state and emits each step as
/// `DrawOp.gammaStep` (E2's `ScreenGamma` executes it):
/// - fade-out — only while `*_DAT_1009fde8` (faded out) is 0: `DAT_100a53d6` (done) 0, step `_DAT_100a17ee` 0,
///   direction `_DAT_100a17ec` 0, N `_DAT_100a17d0`, the target rgb at `100a024c`;
/// - fade-in — only while faded out: done 0, step 0, N, direction 1;
/// - each iteration while not done: `MT_FadeToColor(rgb or nil, step·100 / N, 0, 1)` (`gammaStep(step, N, toward)`),
///   step += 1; past N: done, and the end state — fade-out `FadeToColor(rgb, 100)` + faded out 1, fade-in
///   `FadeToColor(nil, 0)` + faded out 0 + `_ShowCursorSafe` (a `.showCursor` request, L1). Neither end call moves
///   the gamma `ScreenGamma` models (100 % toward the colour just reached; 0 %), so no op is emitted for them.
/// `DAT_100a53c2` (gamma available) is taken as set. The level-start fades of `.GameLoop` are not built (session
/// header), so a level starts with no fade pending (done) and not faded out [MED: `DAT_100a53d6`'s value at a level
/// start depends on those unbuilt fades].
public struct AsyncGammaFade: Equatable, Sendable {
    /// `DAT_100a53c2`: fading enabled — every async call is gated on it (M l. 31878, 31899, 31922). True for a
    /// directly built session (Phase 2); `LevelRun` hands `ScreenFade`'s value over (L1).
    public private(set) var fadingEnabled = true
    /// `DAT_100a53d6`.
    public private(set) var done = true
    /// `_DAT_100a17ec`: 0 out, 1 in.
    public private(set) var fadingIn = false
    /// `_DAT_100a17ee` / `_DAT_100a17d0`.
    public private(set) var step: Int16 = 0
    public private(set) var steps: Int16 = 0
    /// `100a024c`: the fade-out colour.
    public private(set) var toward = RGB16(red: 0, green: 0, blue: 0)
    /// `*_DAT_1009fde8`: the screen is faded out.
    public private(set) var fadedOut = false

    public init() {}

    /// L1: the global fade state as `ScreenFade` holds it when a `LevelRun` starts the session's loop (`*_DAT_1009fde8`
    /// faded, `DAT_100a53d6` no async fade running, `DAT_100a53c2` fading enabled).
    public init(fadedOut: Bool, done: Bool, fadingEnabled: Bool) {
        self.fadedOut = fadedOut
        self.done = done
        self.fadingEnabled = fadingEnabled
    }

    /// `.GammaFadeOutAsync(N, rgb) @ 100356c0` (M l. 31896–31912): only when fading is enabled and not faded out.
    /// Returns whether it armed — the arm is where it calls `HideCursorSafe` (M l. 31905), even when it re-arms to the
    /// state it was already in.
    @discardableResult
    public mutating func fadeOut(steps n: Int16, toward rgb: RGB16) -> Bool {
        guard fadingEnabled, !fadedOut else { return false }
        done = false
        step = 0
        fadingIn = false
        steps = n
        toward = rgb
        return true
    }

    /// `.GammaFadeInAsync(N) @ 1003565c` (M l. 31875–31890): only when fading is enabled and faded out.
    public mutating func fadeIn(steps n: Int16) {
        guard fadingEnabled, fadedOut else { return }
        done = false
        step = 0
        steps = n
        fadingIn = true
    }

    /// `.HandleAsyncGammaFade`: the step's op, nil when no fade runs.
    public mutating func handle() -> DrawOp? {
        guard !done, fadingEnabled else { return nil }
        let op = DrawOp.gammaStep(numerator: Int(step), denominator: Int(steps), toward: fadingIn ? nil : toward)
        step &+= 1
        if steps < step {
            done = true
            fadedOut = !fadingIn
        }
        return op
    }
}

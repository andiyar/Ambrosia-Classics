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
///   request rides the level start. Not built: `.FadeAIFFMusic(1, 4)`, the gamma fades, `.ChapterScreen`
///   (hdr 0x273c, l. 5222–5226).
/// - P3: the player is `Player.spawn` (`.SetupPlayerSprite`, with its held-item and five trail sprites), then the
///   countdown sprite `MTNewSprite(0x4c4, x, y, 800, −1, .SetupEffectSprite)` (l. 5184) into `*_DAT_1009fd7c` with its
///   six digit sprites 0x4c5; `iRam100a5110 = −0x1e` (l. 5186), so the countdown stays hidden (its only other writer
///   is the timer pickup in `.HitPlayerSprite`, l. 49275 — // later: Phase 3–4). No `FastRand` in any of them.
///
/// **Each iteration** (l. 5224–5290): `.FindUpperLeftCorner`, the countdown sprite's Handle called directly (raw
/// `1000a148..1000a158`: `if (*_DAT_1009fd7c) (*(+0x4c))()`), then `.PaintFrameWrap(draw, odd) @ 10011cf8` with
/// draw = 0 iff prefs[0] and not odd (odd starts false, toggles at the end — so with prefs[0] the FIRST iteration
/// skips): `.SetScrollLocation`, `.DrawLightsOntoTiles` unless prefs+6 == 3, `.WrapDrawSprites` unconditionally; only
/// the `if (param_1 != 0)` block (l. 9254–9450) with `.WrapCopyToScreen(port, h, v, 0x10, 8, prefs+9 == 0,
/// prefs+2 == 3, 0)` (l. 9443/9447) is skipped — and with it the parity flip `*_DAT_1009fd30` (`SpriteWorld.parity`,
/// l. 9435–9440, before the copy); then always `.HandleIdleSprites`, `.HandleSprites` (the items' light twinkle from
/// `.HandleBonusSprite` — `BonusHandle`, as `changeLightFace` ops — the player's `.HandlePlayerSprite` (`Player`) with
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
/// `.PlayerScroll`), an Effect its `EffectSprite.handle`, an inert Bonus item its `BonusHandle` twinkle), then
/// `collideSprites`, then `collideSpecial`.
public final class FerazelSession {
    public let resources: FerazelResources
    public let prefs: FerazelPrefs
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
    /// The player's `ActiveList` id (`*_DAT_1009fdd8`).
    public let playerID: Int
    /// The player's globals (`world.player`).
    public var player: PlayerState { world.player }
    /// `*_DAT_1009fd7c`: the countdown sprite 0x4c4 (nil when `.MTNewSprite` found no record).
    public let countdownID: Int?
    /// `iRam100a5110`: the countdown (−0x1e = hidden; `.GameLoop` decrements it only while > −0x1e).
    public private(set) var countdown: Int32 = -0x1e
    /// The player cues of the last iteration, in call order (`PlayerState.drainFrameOutputs` after `.MTHandleSprites`;
    /// S1 turns them into `SoundCue`s).
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
    /// The level loaded (`Mlvl` id).
    public let levelNumber: Int
    /// `Mmap 200`, read by `LevelFlow` when the level exit is touched.
    public let map: WorldMap
    /// The request that ended the game loop (W4): `.deathEffect` or `.loadLevel(n)`, emitted once with the iteration
    /// that ended it; nil while the loop runs.
    public private(set) var ended: ShellRequest?
    /// `deathEffectDone()` was called: the restart takes fresh globals (D33), so `carry` drops the crunch log.
    private var restartWithFreshGlobals = false
    /// Iterations run.
    public private(set) var iterations = 0

    private let faceBounds: (FaceRef) -> IdleSprites.Rect
    /// The tile solver over `world` (one per level).
    private let solver: TileSolver
    /// The draws a passage jump makes inside the player pass (`PassageView`, W2b), appended after it.
    private var passageOps: [DrawOp] = []

    /// - Parameter seed: the `FastRand` seed (tests fix it; the app seeds from the clock like `.InitAppGlobals`).
    /// - Parameter carry: what the previous level's session hands on (`carry`; W4) — the parity and the crunch log.
    /// - Parameter faceBounds: a face's opaque bounds (`face +8`), which `.ActiveToIdleSprite` stores and
    ///   `.HandleIdleSprites` tests. Core has no face pixels; without it each face's frame (sheet cell, or the PICT's
    ///   frame for a single face) is used — a superset of the opaque bounds [MED].
    public init(resources: FerazelResources, prefs: FerazelPrefs, level: Int, seed: Int32 = 1,
                carry: LevelCarry = LevelCarry(), faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil) throws {
        self.resources = resources
        self.prefs = prefs
        levelNumber = level
        map = try WorldMap.load(from: resources)
        let L = try LevelFile.load(from: resources, level: Int16(level))
        let world = SpriteWorld(level: L, seed: seed)
        // W4 (P3 carries): the parity `_DAT_1009fd30` and the G-resident crunch log run on from the previous level.
        world.parity = carry.parity
        // W4 review fix: after a level exit G runs on whole (`.InitGameGlobals` is `.NewGame`'s only, M l. 5747); the
        // next-level loop re-writes `+0x16` from the new header (l. 5821).
        if let g = carry.globals {
            world.globals = g
            world.globals.startFacing = Int16(L.header.startFacingLeft)
        }
        world.globals.crunchLog = carry.crunchLog
        self.world = world
        let bounds = faceBounds ?? { Self.frameRect($0, resources: resources) }
        self.faceBounds = bounds
        // `.GameLoop(hdr+0x2848 − 0x20, hdr+0x2846 − 0x20, 0, 1)` (`.NewGame` l. 5823).
        let px = Int(L.header.startX) - 0x20, py = Int(L.header.startY) - 0x20
        camera = try Camera(header: L.header, spriteX: px, spriteY: py)
        // playerX = `fd94` = origin x + 0x32 (`.GameLoop` l. 5149, before `.SetupLevel`).
        let context = SetupFaces.Context(level: L, playerX: px + 0x32, effects: prefs.effects)
        // `.ClearCrunchSprites` (`.GameLoop` l. 5160, before `.SetupLevel`): the 40-slot overlay table — already empty
        // in this fresh world; W4's level flow keeps the order when a world is reused.
        world.player.crunchSprites = [Int?](repeating: nil, count: 0x28)
        let spawned = try SetupFaces.spawnLevelSprites(context: context, rng: &world.rng) { e in
            // `.ActiveToIdleSprite`: the bounds of the face `+0xc0` holds at `.AddIdleSprite` time — none for a
            // Handle-faced type, the placeholder for a class-cache face (`SetupFaces` header).
            switch e.source {
            case .none, .handle: return .noFace
            case .setupCached:
                return bounds(FaceRef(pict: SetupFaces.placeholderPict, index: 0, set: .encoded))
            case .setup: return e.slot.face.map(bounds) ?? .noFace
            }
        }
        lights = spawned.lights
        world.active = spawned.active
        world.idle = spawned.idle
        world.records = spawned.records                                  // the Setups' write-backs (W2a)
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
    /// < −0x1d — always in Phase 2 (`EffectSprite.handle`'s default arm: the faces stay nil). No `FastRand`.
    static func spawnCountdown(_ w: SpriteWorld, x: Int, y: Int) -> Int? {
        w.newSprite(type: countdownType, x: x, y: y, layer: 800, handler: .effect) { s in
            EffectSprite.setup(&s)
            s.hasHit = false
            s.layer = 0x7fff
            s.lightOverlay = false
            for _ in 0..<6 {
                // `.inert`: the digit Handle `.anon_10060c78` (SSH + SSC of a faceless sprite) // later: Phase 3–4
                // (the timer pickup shows the countdown; then `.UpdateDigits` gives the digits faces).
                w.newSprite(type: digitType, x: s.x, y: s.y, layer: 0x7fff, handler: .inert) { d in
                    d.lightOverlay = false
                    d.layer = 0x7fff
                }
            }
        }
    }

    /// One `.GameLoop` iteration (the first call also carries the level start).
    public func step(keys: KeyState) -> FrameOps {
        var ops = FrameOps()
        let graphics = prefs.graphics
        if iterations == 0 {
            ops.draws.append(.setScreenClut(id: ColorLUT.screenClutId(level.header)))
            ops.draws.append(.drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0))
            ops.draws.append(.redrawEntireScrollGrid(h: 0, v: 0))
            ops.requests.append(.hideMenuBar)
            ops.requests.append(.hideCursor)
            findUpperLeftCorner(graphics: graphics)
            ops.draws.append(.redrawScrollGrid(h: camera.scrollH, v: camera.scrollV))
            ops.draws.append(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV))
            ops.draws.append(.statusBar(globals.statusBar(levelName: level.header.name)))
            ops.music.append(.play(track: Int(level.header.music)))
        }
        iterations += 1

        // `if (-0x1e < iRam100a5110) iRam100a5110 -= 1` (l. 5237–5239).
        if -0x1e < countdown { countdown -= 1 }
        findUpperLeftCorner(graphics: graphics)
        // The countdown's Handle, called directly before `.PaintFrameWrap` (raw `1000a148..1000a158`).
        if let c = countdownID, world.active.record(id: c) != nil { EffectSprite.handle(world: world, id: c) }
        let draw = prefs.reduceFrameRate == 0 || odd
        let h = camera.scrollH, v = camera.scrollV
        ops.draws.append(.redrawScrollGrid(h: h, v: v))
        if prefs.effects != 3 { ops.draws.append(.drawLightsOntoTiles) }
        let lightList = lights, bounds0 = faceBounds, res = resources, lvl = level
        ops.draws.append(.wrapDrawSprites(world.active.wrapDrawSprites { s in
            Self.dynamicLight(s, level: lvl, lights: lightList, bounds: bounds0) { Self.frameRect($0, resources: res) }
        }))
        if draw {
            // later: E1a `.DrawParticles`, `.UpdateOmniPx`; then the parity flip (raw `10012710..1001272c`).
            world.parity.toggle()
            ops.draws.append(.copyToScreen(h: h, v: v, graphicsMode: Int(graphics), backdrop: prefs.plainCopy == 0))
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
        let actions = InputActions(keys: keys, prefs: prefs)
        let effects = prefs.effects
        let solver = self.solver
        world.handleSprites { world, id in
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
                EffectSprite.handle(world: world, id: id)
            case .inert:
                // `.HandleBonusSprite @ 1005e934` (decompile l. 52832–52840), as far as Phase 2 builds it: `+0xe9` →
                // return, `+0x1b2` → return, `.StandardSpriteHandles`, (`+0xa6 < 0` counts up // later: Phase 4 — no
                // Phase-2 writer), then the item-light twinkle (`BonusHandle`). The other inert classes (enemies,
                // buttons) stay Handle-less until Phase 4/5.
                guard let s0 = world.active.record(id: id),
                      SpriteClassTable.classify(type: s0.type, p1Negative: false)?.0 == .bonus,
                      !s0.dead, !s0.handleSkip else { return }
                world.standardSpriteHandles(id)
                world.active.update(id: id) { s in
                    if let op = BonusHandle.twinkle(&s, effects: effects) { ops.draws.append(op) }
                }
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
            case .cannoned:
                BackgroundSprite.handleCannoned(world: world, id: id, keys: actions)   // `.HandleCannonedSprite` (W2b)
            case .box:
                BoxSprite.handle(world: world, id: id)                            // `.HandleBoxSprite` (W3)
            case .rope:
                RopeSprite.handle(world: world, id: id)                           // `.HandleRopeSprite` (W3)
            case .ropeSegment:
                RopeSprite.handleSegment(world: world, id: id) { Self.frameRect($0, resources: res).right }
            }
        }
        // The cues the Handles made, once per frame after `.MTHandleSprites` (P2 review ruling 1).
        frameCues = world.player.drainFrameOutputs().cues
        // `.MTCollideSprites`, then the player pass `.MTCollideSpecialSprite(player, .HitPlayerSprite)`.
        world.collideSprites(Self.hitCallback)
        world.collideSpecial(hitPlayer: { w, p, c in HitPlayerSprite.hit(w, player: p, other: c, keys: actions) },
                             hit: Self.hitCallback)
        // A passage jump's draws (`PassageView`, W2b), made inside the player pass.
        ops.draws.append(contentsOf: passageOps)
        passageOps = []
        // later: E1a `.HandleParticles`
        // `.WrapEraseSprites` reads the live scroll point (`PTR_DAT_1009fe78`, l. 10452–10458): on a passage jump the
        // snap and its 90 `.FindUpperLeftCorner` passes (inside `.MTCollideSpecialSprite`) have just moved it.
        ops.draws.append(.wrapEraseSprites(sprites: world.active.sprites, h: camera.scrollH, v: camera.scrollV))
        ops.draws.append(.statusBar(globals.statusBar(levelName: level.header.name)))
        ops.drawn = draw
        odd.toggle()
        // Back in `.GameLoop` after the events, keys, sounds and track map: `.UpdateSprites` (raw `1000a298`).
        world.updateSprites()
        // `.HandleAsyncGammaFade` (l. 5282, after `.UpdateStatusBar(1, 0, 0)`; W2b — the passages start the fades).
        if let g = world.gammaFade.handle() { ops.draws.append(g) }
        // `while (DAT_100a5106 == 0 && *_DAT_100a0088 == 0)` (l. 5229): game over or level complete ends the loop
        // after this iteration (W4).
        if ended == nil, world.player.gameOver || world.player.levelDone {
            let request = loopEnd()
            ended = request
            ops.requests.append(request)
            // The player pass's cues (the exit's snd 421) start at once in the original (the Sound Tool); the loop
            // ends before the next Handle pass would hand them out, so the last iteration hands them out after its
            // Handle pass's cues. Normal iterations keep the once-per-frame drain above.
            frameCues += world.player.cues
            world.player.cues = []
        }
        return ops
    }

    /// After the loop (l. 5296–5322): G+4 < 1 → `*_DAT_1009ffa8 = 1`, `.FadeAIFFMusic(0, 2)`, `.DeathEffect` (the
    /// shell's, `ShellRequest.deathEffect`); else level complete → the stage-complete screen and the world map, which
    /// Phase 2 replaces by `LevelFlow` (◇ D33). // later: Phase 3 — `.EndLevelSGUpdate`, `.StageCompleteEffect`, the
    /// fades, `.ShowWorldMap` (and its unlock of the second exit `_DAT_100a5118`). A game over with G+4 ≥ 1 has no
    /// Phase-2 writer (the dying arm follows HP < 1); it takes the death path too (◇).
    private func loopEnd() -> ShellRequest {
        if globals.health < 1 {
            world.playerDead = true
            return .deathEffect
        }
        if world.player.levelDone {
            return LevelFlow.exitRequest(level: level.header.mapNodeLevel, exit: world.player.exitIndex, map: map,
                                         current: levelNumber)
        }
        return .deathEffect
    }

    /// W4 (◇ D33): the shell reports that `.DeathEffect`'s wipe ended → restart the current level from its start with
    /// fresh globals (`carry` then keeps only the parity). The shell rebuilds the session with `rngSeed` and `carry`.
    public func deathEffectDone() -> ShellRequest {
        restartWithFreshGlobals = true
        return .loadLevel(levelNumber)
    }

    /// What the next level's session takes (`init(…carry:)`, W4): the parity always; the crunch log unless the restart
    /// after death takes fresh globals (D33).
    public var carry: LevelCarry {
        LevelCarry(parity: world.parity, crunchLog: restartWithFreshGlobals ? [] : world.globals.crunchLog,
                   globals: restartWithFreshGlobals ? nil : world.globals)
    }

    /// `PassageView.snap` (`.HitPlayerSprite` l. 49659–49672, W2b): the camera snapped to (player x − 0x142, y − 0xc0),
    /// then 90 `.FindUpperLeftCorner` passes with the focus the arm just set (`*_DAT_1009fec4`, the auto-scroll mode, is
    /// saved, zeroed and restored around them — auto-scroll is refused by `Camera.init`, so it is 0 throughout); the
    /// scroll location `_DAT_1009fe74/fe70` takes the scroll point (Core's draws read `camera.scrollH/V`);
    /// `.RedrawEntireScrollGrid`.
    private func passageSnap() {
        guard let p = world.playerID.flatMap({ world.active.record(id: $0) }) else { return }
        camera.snap(playerX: p.x, playerY: p.y)
        world.player.scrollH = camera.scrollH
        world.player.scrollV = camera.scrollV
        for _ in 0..<Self.passagePasses { findUpperLeftCorner(graphics: prefs.graphics) }
        passageOps.append(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV))
    }

    /// The passage jump's `.FindUpperLeftCorner` passes (`sVar36 < 0x5a`, l. 49666).
    public static let passagePasses = 0x5a

    /// `PassageView.redraw` (l. 49676–49678): `.HandleIdleSprites` at the new view (the live player's rect),
    /// `.WrapDrawSprites`, `.RedrawEntireScrollGrid`.
    private func passageRedraw() {
        let playerRect = world.playerID.flatMap { world.active.record(id: $0) }.map { p in
            IdleSprites.Rect(top: p.y + p.hotRect.top, left: p.x + p.hotRect.left, bottom: p.y + p.hotRect.bottom,
                             right: p.x + p.hotRect.right)
        }
        world.idle.handle(h: camera.scrollH, v: camera.scrollV, playerHotRect: playerRect, active: &world.active,
                          faceRect: faceBounds)
        let lightList = lights, bounds0 = faceBounds, res = resources, lvl = level
        passageOps.append(.wrapDrawSprites(world.active.wrapDrawSprites { s in
            Self.dynamicLight(s, level: lvl, lights: lightList, bounds: bounds0) { Self.frameRect($0, resources: res) }
        }))
        passageOps.append(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV))
    }

    /// A sprite's hit callback `+0x5c` (`SpriteWorld` calls it only when `hasHit`): `.HitPlatformSprite` (W1); the
    /// Effect class's `.HitEffectSprite` is empty; `.HitBackgroundSprite` (W2b: cannons, springs, wall tunnels). // later:
    /// Phase 4 — the Box class's `.HitBoxSprite` (box vs box / statue / platform; W3 builds the boxes standing still),
    /// Phase 4–5 (enemies, shots).
    static func hitCallback(_ w: SpriteWorld, _ a: Int, _ b: Int) {
        guard let s = w.active.record(id: a) else { return }
        switch s.handler {
        case .platform: PlatformSprite.hit(w, id: a, other: b)
        case .background: BackgroundSprite.hit(w, id: a, other: b)        // `.HitBackgroundSprite` (W2b)
        default: break
        }
    }

    /// The `+0x89` inputs of `.WrapDrawSprites` (l. 10282–10297; raw `1001472c..100147bc`): L = `.GetLightTile(+0x10 >>
    /// 5, +0xe >> 5)` (the BG cell's high byte − 1, `LevelFile.lightByte`; the hot-rect centre, `srawi`), F =
    /// `.GetFakeLight` (`fakeLight`). `SpriteSlot.applyDynamicLight` turns them into `+0xb8`. The original computes them
    /// only for a sprite whose face passes the draw's cull (`SectRectFast`, l. 10261–10265); Core asks for every `+0x89`
    /// sprite with a face [MED: an off-view raft's word is refreshed one draw early].
    static func dynamicLight(_ s: SpriteSlot, level: LevelFile, lights: [SetupFaces.Light],
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
    /// active light in slot order (the Setup lights, `lights`, in `.AddLight` order — Phase 2 removes none) that passes
    /// the bounding pre-test (it is skipped only when |x + w/2 − lx| ≥ lx + r + w/2 **and** |y + h/2 − ly| ≥ ly + r + h/2
    /// — the light's own coordinate added, as written), has radius `+0x14` > 0x20 and whose face rect (`+0x58` = (0, 0,
    /// height, width) offset by (lx − r, ly − r)) contains the centre of the sprite face's opaque bounds (face `+8` at
    /// (x, y); `PtInRect`, half-open): v = 11 − (`.PEDistance`(lx − px, ly − py)·11) / r (i16, C division), accepted for
    /// 0 ≤ v < 12 → v + the light's colour. Otherwise 0.
    static func fakeLight(x: Int, y: Int, width w: Int, height h: Int, faceBounds b: IdleSprites.Rect,
                          lights: [SetupFaces.Light]) -> Int {
        let s16 = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
        for l in lights {
            let r = l.radius
            let ax = abs(x + (w >> 1) - l.x)
            if l.x + r + (w >> 1) <= ax {
                let ay = abs(y + (h >> 1) - l.y)
                if l.y + r + (h >> 1) <= ay { continue }
            }
            let top = l.y - r, left = l.x - r
            let px = s16(x + ((b.left + b.right) >> 1)), py = s16(y + ((b.top + b.bottom) >> 1))
            guard 0x20 < r, left <= px, px < left + l.width, top <= py, py < top + l.height else { continue }
            let d = peDistance(l.x - px, l.y - py)
            let v = s16(0xb - s16((d * 0xb) / r))
            if 0 <= v && v < 0xc { return s16(v + l.colour) }
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
        let p = world.player
        let s = world.playerID.flatMap { world.active.record(id: $0) }   // the live `*_DAT_1009fdd8`, not `playerID`
        let ridden = s?.ridden.flatMap { world.active.record(id: $0) }
        world.player.cameraSnapVeto = camera.findUpperLeftCorner(
            focusX: Int(p.focusX), focusY: Int(p.focusY), playerVX: Int(p.lastVX), snapArmed: p.snapArmed,
            ridingVeto: ridden?.type == Camera.snapVetoRiddenType,
            inWater: (s?.waterRow ?? 0) != 0 || (s?.lastWater ?? 0) != 0, latch: p.cameraSnapVeto, graphics: graphics)
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
///   `FadeToColor(nil, 0)` + faded out 0 (`_ShowCursorSafe`). Neither end call moves the gamma `ScreenGamma` models
///   (100 % toward the colour just reached; 0 %), so no op is emitted for them.
/// `DAT_100a53c2` (gamma available) is taken as set. The level-start fades of `.GameLoop` are not built (session
/// header), so a level starts with no fade pending (done) and not faded out [MED: `DAT_100a53d6`'s value at a level
/// start depends on those unbuilt fades].
public struct AsyncGammaFade: Equatable, Sendable {
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

    /// `.GammaFadeOutAsync(N, rgb)`.
    public mutating func fadeOut(steps n: Int16, toward rgb: RGB16) {
        guard !fadedOut else { return }
        done = false
        step = 0
        fadingIn = false
        steps = n
        toward = rgb
    }

    /// `.GammaFadeInAsync(N)`.
    public mutating func fadeIn(steps n: Int16) {
        guard fadedOut else { return }
        done = false
        step = 0
        steps = n
        fadingIn = true
    }

    /// `.HandleAsyncGammaFade`: the step's op, nil when no fade runs.
    public mutating func handle() -> DrawOp? {
        guard !done else { return nil }
        let op = DrawOp.gammaStep(numerator: Int(step), denominator: Int(steps), toward: fadingIn ? nil : toward)
        step &+= 1
        if steps < step {
            done = true
            fadedOut = !fadingIn
        }
        return op
    }
}

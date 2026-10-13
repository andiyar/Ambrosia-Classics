import Foundation
import FerazelCore

/// Executes `FrameOps` — the original's draw calls as `FerazelSession.step` records them, in `.PaintFrameWrap @
/// 10011cf8` order (engine §3–§4; D26 "As built (R5)") — on the persistent 8-bit ports and the 640×480 screen, and
/// presents through the current screen CLUT (design §5). One renderer per level start.
///
/// Per op:
/// - `setScreenClut(id)`: the screen CLUT (`.SetScreenClut @ 1000faa8`, `value` = index); the next status-bar op is the
///   level start's full `.UpdateStatusBar(0, 0, 0)`.
/// - `drawPicture(id, chain, h, v)`: `.DrawPICTToBackScreen(0x81, &DAT_100a266c)` (`.SetupLevel` l. 2574; the rect at
///   `100a266c` is (0, 0, 480, 640)): the PICT converted under the screen CLUT into the back screen, whose CLUT
///   `.SetScreenClut` set to the same colours (l. 7999–8000), then `.MTRedraw`'s `CopyBits` to the window — differing
///   seeds, so each index goes through `Color2Index` of its own colour [MED].
/// - `redrawScrollGrid` / `redrawEntireScrollGrid` (`TileGridRenderer`): the scroll point `PTR_DAT_1009fe78` becomes
///   (h, v) as passed; `drawLightsOntoTiles` at that point.
/// - `wrapDrawWaterEffects` (E1a): first `.HandleLights @ 1001bff0` (`.PaintFrameWrap` l. 9205, after
///   `.DrawLightsOntoTiles` and before `.WrapDrawWaterEffects` l. 9206, unconditional — not an op of the seam; the
///   session emits this op on every `.PaintFrameWrap` iteration): every active slot not pending removal copies its
///   face, point, radius and colour to the "previous" fields and clears `+1` (new); the speeds are 0 for every
///   level-1 light, so nothing moves; the row-redraw counter `*_DAT_100a012c` has no writer (its only TOC load is
///   `1001bff8`), so its redraw never runs. Then the op itself is recorded only — its water faces // later: E1b (the
///   list is empty until then).
/// - `wrapDrawSprites`: `SpriteBlitter.wrapDrawSprites` at the scroll point, culled by the grid's drawn pair. A passage
///   jump's own `.WrapDrawSprites` (`.HitPlayerSprite` l. 49677) has no `.HandleLights` before it.
/// - `drawParticles` / `eraseParticles` (E1a): `ParticleRenderer.draw` into the frame port at the scroll point, and
///   its erase after the copy.
/// - `copyToScreen`: `ParallaxBlitter.copyToScreen` from the frame port into the screen (prefs+4 = parallax).
/// - `changeLightFace(slot, …)`: `.ChangeLightFace @ 1001bdbc` — the slot's face and radius; the next
///   `.DrawLightsOntoTiles` sees the face differ from its previous one and redraws the cells it covers.
/// - `wrapEraseSprites`: `SpriteBlitter.wrapEraseSprites` with the grid's mask re-stamp.
/// - `statusBar`: `StatusBar.update` — full after a `setScreenClut` (the level start), incremental otherwise (D26 R5:
///   the seam does not carry the flag).
/// - `gammaStep(j, N, toward)`: one `.HandleAsyncGammaFade` step on `gamma` (`ScreenGamma`); `presentedClut` shows it.
/// - `setTile(col, row, fg)` (P2): the FG cell of the renderer's level becomes `fg` (`.SetFGTile` /
///   `.SetFGCrunchDirTile` as Core made them), then `.ChangedTile @ 10012a50` = `.RedrawScrollGrid` of that one cell
///   at the current scroll point (into the tile port, then its rect into the frame port).
/// After each `wrapEraseSprites` the water-ripple phase `*_DAT_1009fd74` advances by 0x100 (0x200 at level start).
///
/// The light slots: `.SetupLevelSprites` (inside `.SetupLevel`, l. 2526, before its `.RedrawEntireScrollGrid`
/// l. 2582) `.AddLight`s the Setup lights — the session's `FerazelSession.lights` (D26 R4: 68 on level 1 at
/// Effects 1), handed over with `addLights` before the first `apply` — into the first free slots in order — `.AddLight @ 1001bc08`: `+0` active, `+1` new, `+2` 0, `+4` face,
/// `+8` previous face nil, `+0x14` radius = face width >> 1, `+0xc` the point, `+0x18` colour; the other previous
/// fields keep their (zero) contents. The light faces load with `LightFace.load` (clut 801).
public final class FrameRenderer {

    /// What the renderer refuses instead of reading memory the original would have.
    public enum Refusal: Error, Equatable {
        /// A `setScreenClut` other than the level CLUT the tables were built against.
        case screenClut(Int16, tablesBuiltFor: Int16)
        /// `.AddLight` with all 200 slots in use (the original's `ReportError`).
        case lightSlotsFull
        /// `buildTintTable` with other than `.BuildTintTable`'s 510 draws.
        case tintTableDraws(Int)
        /// `apply` or `deathEffectStep` before `buildTintTable`: table 0xa has no draws yet (the session's
        /// `tintTableDraws` must be handed over first — the renderer is built before the session, which needs its
        /// `faceBounds`, so the hand-off cannot be an init argument).
        case tintTableNotBuilt
        /// `deathEffectStep` outside `.DeathEffect`'s loop, k = 0 … 49.
        case deathEffectStep(Int)
    }

    /// What `apply` executed, in order (the test oracle of the op order).
    enum Executed: Equatable {
        case screenClut(Int16), picture(Int16), entireGrid(h: Int, v: Int), strip(h: Int, v: Int), lightsOntoTiles
        case handleLights, sprites(Int), copy(h: Int, v: Int), lightFace(Int), erase(Int), statusBar(full: Bool)
        case gamma(numerator: Int, denominator: Int)
        case tile(col: Int, row: Int)
        case waterEffects(Int), particles(Int), eraseParticles
    }

    public let resources: FerazelResources
    /// The level as loaded, with the `setTile` writes applied (the grid, light and sprite renderers draw from it).
    public private(set) var level: LevelFile
    /// The `Mlvl` resource bytes `level` was parsed from (`setTile` patches its FG cell and re-parses).
    private var levelData: Data
    /// The fixed tile faces (`TileGridRenderer` takes its blend sheet from them when rebuilt by `setTile`).
    private let fixed: TileSets.Fixed
    public let prefs: FerazelPrefs
    public let search: ColorSearch
    public let dither: DitherModel
    public private(set) var tables: LevelTables
    /// The screen (the main device's 640×480 pixels).
    public private(set) var screen: IndexedFrame
    /// The CLUT the screen shows through (`.SetScreenClut`); present with `screen.rgba(through: screenClut,
    /// gamma: gamma)`, or through `presentedClut`.
    public private(set) var screenClut: ColorLUT
    /// The screen gamma the Monitor Tool fades leave (`DrawOp.gammaStep`; lighting-tables §10).
    public private(set) var gamma = ScreenGamma.identity
    /// `screenClut` through `gamma` — what the screen shows; presentation only (the app's MacGamma goes on top).
    public var presentedClut: ColorLUT { gamma.apply(screenClut) }
    public private(set) var ports: FramePorts
    public private(set) var grid: TileGridRenderer
    public private(set) var sprites: SpriteBlitter
    public let parallax: ParallaxBlitter
    public private(set) var statusBar: StatusBar
    /// `_DAT_100a0128`: the light slots the grid and the sprite light pass read.
    public private(set) var lights: LightRenderer
    /// The particle colour rows, draw and erase (E1a).
    public private(set) var particles: ParticleRenderer
    /// `PTR_DAT_1009fe78`.
    public private(set) var scroll: (h: Int, v: Int) = (0, 0)
    /// The level+base CLUT the tables were built on (working copy, lighting source and search CLUT; `LevelTables`).
    private let levelClut: ColorLUT
    /// `buildTintTable` ran (until then `apply` refuses).
    public private(set) var tintTableBuilt = false
    /// The ops of the last `apply`, as executed.
    private(set) var executed: [Executed] = []
    private var statusBarFull = true
    /// The light faces loaded so far, by (pict, width, height).
    private var lightFaces: [[Int]: LightFace] = [:]

    /// The level's renderer: tile sets, tables, parallax, sprite faces (every level-1 Setup sheet plus the player's
    /// `.InitPlayerSprite` sets and the Platform class's `.InitPlatformSprite` sets — 0x578, 0x2c7, 0x582, 0x58c…0x58e,
    /// 0x599…0x59c, `SetupFaces.platformSheets`, W1 — and the Background class's radial bars and balls 1480…1488,
    /// `SetupFaces.backgroundSheets`, W2a; the mace chains 1434 / 1436 are the platform sets'; W2b: the springs and
    /// passages, `SetupFaces.backgroundW2bSheets` — the cannon set 0x442 and the tunnels 3000…, plants 2700… come with
    /// the placed types' sheets; W4: the level-2 types' sheets come with them, plus the stalactite child's set 0xb74,
    /// `SetupFaces.boxChildSheets`), empty light slots (`addLights`), the status bar under the level
    /// CLUT.
    /// - Parameter prefs: prefs+4 (parallax) and +6 (Effects) for the blitters; the Setup lights depend on Effects.
    public init(resources: FerazelResources, level: Int, search: ColorSearch, dither: DitherModel,
                text: any TextRasterizer, prefs: FerazelPrefs = FerazelPrefs()) throws {
        self.resources = resources
        self.prefs = prefs
        self.search = search
        self.dither = dither
        guard let mlvl = resources.world.resource(type: "Mlvl", id: Int16(level)) else {
            throw WorldDataError.missing(type: "Mlvl", id: Int16(level))
        }
        let L = try LevelFile(resource: mlvl)
        self.level = L
        levelData = mlvl.data
        let clut = try ColorLUT.load(id: ColorLUT.screenClutId(L.header), from: resources, chain: .level)
        screenClut = clut
        levelClut = clut
        // Tint table 0xa takes `.BuildTintTable`'s draws from the session's stream: built here with 0s, rebuilt by
        // `buildTintTable(session.tintTableDraws)` before the first `apply` (as `addLights`).
        tables = try LevelTables.forLevel(L.header, resources: resources, search: search, random: { _ in 0 })
        let fixed = try TileSets.Fixed(resources: resources, search: search, dither: dither)
        self.fixed = fixed
        let sets = try TileSets(level: L, fixed: fixed, resources: resources, search: search, dither: dither)
        let clear = try TileGridRenderer.loadClearFace(resources: resources, search: search, dither: dither)
        parallax = try ParallaxBlitter(level: L, sets: sets)

        let context = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header),
                                         effects: prefs.effects)
        let entries = try L.activePlacements.map { try SetupFaces.setup($0, context: context) }
        let faces = try SpriteBlitter.Faces(Set(entries.compactMap(\.sheet)).union(Self.playerSheets)
                                                .union(Self.effectSheets).union(SetupFaces.platformSheets)
                                                .union(SetupFaces.backgroundSheets)
                                                .union(SetupFaces.backgroundW2bSheets)
                                                .union(SetupFaces.boxChildSheets),
                                            resources: resources, search: search, dither: dither)
        let lights = LightRenderer(level: L, tables: tables)
        self.lights = lights
        grid = TileGridRenderer(level: L, sets: sets, fixed: fixed, tables: tables, clearFace: clear, drawnH: 0,
                                drawnV: 0, effects: prefs.effects, lights: lights)
        sprites = SpriteBlitter(level: L, tables: tables, faces: faces, effects: prefs.effects, lights: lights)
        statusBar = try StatusBar(resources: resources, screenClut: clut, search: search, dither: dither, text: text)
        // `.InitParticles` → `.InitParticleColors` (`.SetupLevel` l. 2572, after `.SetScreenClut(level+base)`): clut
        // 801 entries through `Color2Index` against the level+base CLUT; lit kinds through ambient row hdr 0x2706.
        particles = ParticleRenderer(system: try ColorLUT.load(id: 801, from: resources, chain: .frontEnd),
                                     screenClut: clut, search: search, tables: tables,
                                     darkness: L.header.darknessEnable, effects: prefs.effects)
        screen = IndexedFrame()
        ports = FramePorts()
    }

    /// `.InitPlayerSprite @ 1004a284` (l. 42427–42484): the player's face sets — `FaceSheet.playerSheets`, the one
    /// table (29 sets: every face the state machine selects, P3), at boot under clut 200 (`.InitSprites`, l. 118). Not
    /// loaded: the cached glider sets 1050–1053 (// later: Phase 4) and the held-item singles 0x2ee…0x308
    /// (`_DAT_100a5f68`, l. 42490; // later: the phase that shows the held item).
    static let playerSheets: Set<SetupFaces.Sheet> = Set(FaceSheet.playerSheets.map { loader -> SetupFaces.Sheet in
        switch loader {
        case .single(let pict): return .single(pict)
        case .set(let a):
            return SetupFaces.Sheet(pict: a.pict, count: a.count, cellWidth: a.cellWidth, cellHeight: a.cellHeight,
                                    columns: a.columns, clut: 200)
        }
    })

    /// `.InitEffectSprite @ 10060378` (l. 53639–53686), at boot under clut 200 like the player's: the landing dust
    /// 1201 (6 × 56×8, `.CheckGroundCeilingHitEffects`), the crumble overlay 1210 (3 × 32×32, `.MakeCrunchSprite`) and
    /// the bubble 1040 (`LoadEncFaceSetFromPICT(0x410, 4, 8, 8, 4, …)`, l. 53656: 4 × 8×8, `.EmitBubble`, P4) — the
    /// effects Phase 2 spawns — and W2b's cannon smoke 0x442 (`LoadEncFaceSetFromPICT(0x4b0, 13, 48, 48, 13, …)`,
    /// l. 53646). // later: E1a / Phase 3–5 — the other effect sets.
    static let effectSheets: Set<SetupFaces.Sheet> = [
        SetupFaces.Sheet(pict: 0x4b0, count: 0xd, cellWidth: 0x30, cellHeight: 0x30, columns: 0xd, clut: 200),
        SetupFaces.Sheet(pict: 0x4b1, count: 6, cellWidth: 0x38, cellHeight: 8, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: 0x4ba, count: 3, cellWidth: 0x20, cellHeight: 0x20, columns: 3, clut: 200),
        SetupFaces.Sheet(pict: 0x410, count: 4, cellWidth: 8, cellHeight: 8, columns: 4, clut: 200),
    ]

    /// `.AddLight @ 1001bc08` for each light, in order (the session's `lights`, `.SetupLevelSprites` order): the first
    /// free slot gets `+0` active, `+1` new, `+2` 0, `+4` the face (`LightFace.load`, clut 801), `+8` nil, `+0x14`
    /// the face width >> 1, `+0xc` the point, `+0x18` the colour.
    /// - Throws: `Refusal.lightSlotsFull`; `LightFaceError` / `PictureSourceError` for a face that does not load.
    public func addLights(_ list: [SetupFaces.Light]) throws {
        for l in list {
            let face = try lightFace(pict: l.pict, width: l.width, height: l.height)
            guard let i = lights.slots.firstIndex(where: { !$0.active }) else { throw Refusal.lightSlotsFull }
            var s = LightSlot()
            s.active = true
            s.isNew = true
            s.face = face
            s.x = l.x
            s.y = l.y
            s.radius = face.width >> 1
            s.colour = l.colour
            lights.slots[i] = s
        }
    }

    /// `.BuildTintTable @ 10020a5c`'s table 0xa from the session's stream (`FerazelSession.tintTableDraws`: 510
    /// `FastRand(5000)`, B then R per entry 0..0xfe, raw `10021d04/14`) — the one RNG stream stays Core's (plan
    /// Invariant 4); the renderer only resolves the colours. Required before the first `apply` (which otherwise throws
    /// `Refusal.tintTableNotBuilt`). Only the sprite
    /// blitter reads the tint bank (mode 1); the grid and the light renderer read water, ambient and light tables.
    /// - Throws: `Refusal.tintTableDraws` unless there are exactly 510 draws.
    public func buildTintTable(_ draws: [Int16]) throws {
        guard draws.count == 0xff * 2 else { throw Refusal.tintTableDraws(draws.count) }
        tables = tables.replacingRandomTint(draws, workingClut: levelClut, screenClut: levelClut, search: search)
        sprites.tables = tables
        tintTableBuilt = true
    }

    /// `.DeathEffect`'s painter for this screen: `ForeColor(blackColor)` = `Color2Index` of black in the screen CLUT.
    public var deathEffect: DeathEffect {
        DeathEffect(foreColor: search.index(of: DeathEffect.fadeColour, in: screenClut))
    }

    /// One `.DeathEffect @ 10005270` step k (0 … 49) on `screen`, with its `.HandleAsyncGammaFade` step applied to
    /// `gamma` (none after k = 0x30) — what the app (A3) runs once per tick for the 50 steps, then
    /// `session.deathEffectDone()`; `executed` holds the gamma step.
    /// - Throws: `Refusal.deathEffectStep` for k outside 0 … 49, `Refusal.tintTableNotBuilt` before the hand-off.
    public func deathEffectStep(_ k: Int) throws {
        guard (0..<DeathEffect.steps).contains(k) else { throw Refusal.deathEffectStep(k) }
        let op = deathEffect.frame(step: k, on: &screen)
        try apply(FrameOps(draws: op.map { [$0] } ?? []))
    }

    /// The light face `.Load1LightFaceFromPICT(pict, width, height)`, loaded once.
    private func lightFace(pict: Int16, width: Int, height: Int) throws -> LightFace {
        let key = [Int(pict), width, height]
        if let f = lightFaces[key] { return f }
        let face = try LightFace.load(pict: pict, width: width, height: height, from: resources, search: search,
                                      dither: dither)
        lightFaces[key] = face
        return face
    }

    /// A face's opaque bounds (`face +8`) — what `FerazelSession(faceBounds:)` asks (`.ActiveToIdleSprite`).
    public func faceBounds(_ ref: FaceRef) -> IdleSprites.Rect {
        guard let b = sprites.faces.face(ref)?.bounds else { return .noFace }
        return IdleSprites.Rect(top: Int(b.top), left: Int(b.left), bottom: Int(b.bottom), right: Int(b.right))
    }

    /// The face pixels for Core's face emitters (`FerazelSession(…particleFaces:)`, E1a): a loaded sprite face, and
    /// FG tile t of the level's FG set (`*_DAT_1009ff88`, `TileSets.fg`).
    public var particleFaces: ParticleFaces {
        let faces = sprites.faces, fg = grid.sets.fg
        @Sendable func convert(_ f: EncodedFace) -> ParticleFace {
            ParticleFace(frame: [f.frame.top, f.frame.left, f.frame.bottom, f.frame.right],
                         bounds: [f.bounds.top, f.bounds.left, f.bounds.bottom, f.bounds.right], tokens: f.data)
        }
        return ParticleFaces(sprite: { ref in faces.face(ref).map(convert) },
                             fgTile: { t in fg.faces.indices.contains(t) ? convert(fg.faces[t]) : nil })
    }

    /// Executes one iteration's draw ops (sounds, music and shell requests are the shell's).
    /// - Throws: `SpriteBlitter.Refusal` for a sprite shape outside the census, `Refusal.screenClut` for a CLUT the
    ///   tables were not built against, `ColorLUTError` / `PictureSourceError` for a missing CLUT or picture.
    public func apply(_ ops: FrameOps) throws {
        guard tintTableBuilt else { throw Refusal.tintTableNotBuilt }
        executed = []
        for op in ops.draws {
            switch op {
            case .setScreenClut(let id):
                guard id == tables.screenClutId else {
                    throw Refusal.screenClut(id, tablesBuiltFor: tables.screenClutId)
                }
                screenClut = try ColorLUT.load(id: id, from: resources, chain: .level)
                statusBarFull = true
                executed.append(.screenClut(id))
            case .drawPicture(let id, let chain, let h, let v):
                try drawPicture(id: id, chain: chain, h: h, v: v)
                executed.append(.picture(id))
            case .redrawScrollGrid(let h, let v):
                grid.lights = lights
                grid.setScrollLocation(h: h, v: v, ports: &ports)
                scroll = (h, v)
                executed.append(.strip(h: h, v: v))
            case .redrawEntireScrollGrid(let h, let v):
                grid.lights = lights
                grid.redrawEntireScrollGrid(h: h, v: v, ports: &ports)
                scroll = (h, v)
                executed.append(.entireGrid(h: h, v: v))
            case .drawLightsOntoTiles:
                grid.lights = lights
                grid.drawLightsOntoTiles(h: scroll.h, v: scroll.v, ports: &ports)
                executed.append(.lightsOntoTiles)
            case .wrapDrawSprites(let draws):
                sprites.lights = lights
                try sprites.wrapDrawSprites(draws, h: scroll.h, v: scroll.v, drawn: (grid.drawnH, grid.drawnV),
                                            ports: &ports)
                executed.append(.sprites(draws.count))
            case .copyToScreen(let h, let v, let graphicsMode, let backdrop):
                parallax.copyToScreen(ports: ports, h: h, v: v, graphicsMode: graphicsMode, backdrop: backdrop,
                                      parallax: Int(prefs.parallax), screen: &screen.pixels)
                executed.append(.copy(h: h, v: v))
            case .changeLightFace(let slot, let pict, let width, let height):
                // `.ChangeLightFace @ 1001bdbc`: slots outside 0…199 are ignored; `+4` face, `+0x14` = width >> 1.
                if lights.slots.indices.contains(slot) {
                    let face = try lightFace(pict: pict, width: width, height: height)
                    lights.slots[slot].face = face
                    lights.slots[slot].radius = face.width >> 1
                }
                executed.append(.lightFace(slot))
            case .wrapEraseSprites(let list, let h, let v):
                grid.lights = lights
                try sprites.wrapEraseSprites(list, h: h, v: v, ports: &ports, grid: grid)
                // `*_DAT_1009fd74 += 0x100` right after `.WrapEraseSprites` (`.PaintFrameWrap` raw `100127ec..100127f4`).
                sprites.ripplePhase &+= 0x100
                executed.append(.erase(list.count))
            case .gammaStep(let numerator, let denominator, let toward):
                gamma.step(numerator: numerator, denominator: denominator, toward: toward)
                executed.append(.gamma(numerator: numerator, denominator: denominator))
            case .setTile(let col, let row, let fg):
                try setTile(col: col, row: row, fg: fg)
                executed.append(.tile(col: col, row: row))
            case .wrapDrawWaterEffects(let list):
                // `.HandleLights` (l. 9205) runs just before `.WrapDrawWaterEffects` (l. 9206).
                handleLights()
                executed.append(.handleLights)
                executed.append(.waterEffects(list.count))
            case .drawParticles(let list):
                particles.draw(list, scroll: scroll, ports: &ports)
                executed.append(.particles(list.count))
            case .eraseParticles:
                particles.erase(scroll: scroll, ports: &ports)
                executed.append(.eraseParticles)
            case .statusBar(let state):
                let full = statusBarFull
                statusBar.update(state, full: full, screen: &screen)
                statusBarFull = false
                executed.append(.statusBar(full: full))
            }
        }
    }

    /// `DrawOp.setTile`: the FG cell (col, row) of `level` (`Mlvl` §3.1 layout: header, PxBack, PxMid, BG, then FG)
    /// becomes `fg`; the grid, light and sprite renderers are rebuilt on the new level keeping their state (drawn
    /// pair, effects, light slots, ripple phase); then `.ChangedTile`'s one-cell `.RedrawScrollGrid` at `scroll`.
    /// A cell outside the grid (Core clamps as `.ConstrainXY`, so none comes) is ignored.
    private func setTile(col: Int, row: Int, fg: UInt16) throws {
        let hdr = level.header
        let w0 = Int(hdr.pxBackWidth), h0 = Int(hdr.pxBackHeight), w1 = Int(hdr.pxMidWidth), h1 = Int(hdr.pxMidHeight)
        let w2 = Int(hdr.gridWidth), h2 = Int(hdr.gridHeight)
        guard (0..<w2).contains(col), (0..<h2).contains(row) else { return }
        let offset = LevelFile.headerSize + 2 * (w0 * h0 + w1 * h1) + 2 * w2 * h2 + 2 * (row * w2 + col)
        var data = levelData
        data[data.startIndex + offset] = UInt8(fg >> 8)
        data[data.startIndex + offset + 1] = UInt8(fg & 0xff)
        let new = try LevelFile(id: level.id, data: data)
        levelData = data
        level = new
        var light = LightRenderer(level: new, tables: tables)
        light.slots = lights.slots
        lights = light
        grid = TileGridRenderer(level: new, sets: grid.sets, fixed: fixed, tables: tables, clearFace: grid.clearFace,
                                drawnH: grid.drawnH, drawnV: grid.drawnV, effects: grid.effects, lights: light)
        var blitter = SpriteBlitter(level: new, tables: sprites.tables, faces: sprites.faces, effects: sprites.effects,
                                    lights: light)
        blitter.ripplePhase = sprites.ripplePhase
        sprites = blitter
        grid.redrawScrollGrid(top: row, left: col, right: col, bottom: row, h: scroll.h, v: scroll.v, ports: &ports)
    }

    /// `.DrawPICTToBackScreen(id, (0, 0, 480, 640))` + `.MTRedraw`, the picture at (h, v).
    private func drawPicture(id: Int16, chain: ResourceChain, h: Int, v: Int) throws {
        let picture = try ConvertedPicture(source: try PictureSource.load(id: id, from: resources, chain: chain),
                                           clut: screenClut, search: search, dither: dither)
        redrawToWindow(picture, h: h, v: v)
    }

    /// `.MTRedraw`'s `CopyBits` from the back screen to the window: every index through `Color2Index` of its own
    /// colour under the screen CLUT (seeds differ), the picture at (h, v), clipped to the screen.
    func redrawToWindow(_ picture: ConvertedPicture, h: Int, v: Int) {
        let prepared = search.prepared(for: screenClut)
        let redraw = screenClut.entries.map { prepared.index(of: RGB16($0.red, $0.green, $0.blue)) }
        for y in 0..<picture.height where (0..<IndexedFrame.height).contains(v + y) {
            for x in 0..<picture.width where (0..<IndexedFrame.width).contains(h + x) {
                screen[h + x, v + y] = redraw[Int(picture.pixels[y * picture.width + x])]
            }
        }
    }

    /// `.HandleLights @ 1001bff0` for lights without speed: removal-pending slots go inactive; the rest remember
    /// this frame's face, point, radius and colour and stop being new.
    private func handleLights() {
        for i in lights.slots.indices where lights.slots[i].active {
            if lights.slots[i].removePending {
                lights.slots[i].active = false
            } else {
                lights.slots[i].isNew = false
                lights.slots[i].previousFace = lights.slots[i].face
                lights.slots[i].previousX = lights.slots[i].x
                lights.slots[i].previousY = lights.slots[i].y
                lights.slots[i].previousRadius = lights.slots[i].radius
                lights.slots[i].previousColour = lights.slots[i].colour
            }
        }
    }
}

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
/// - `wrapDrawSprites`: first `.HandleLights @ 1001bff0` (`.PaintFrameWrap` l. 9205, between `.DrawLightsOntoTiles`
///   and `.WrapDrawSprites`, unconditional — not an op of the seam): every active slot not pending removal copies its
///   face, point, radius and colour to the "previous" fields and clears `+1` (new); the speeds are 0 for every
///   level-1 light, so nothing moves; the row-redraw counter `*_DAT_100a012c` has no writer (its only TOC load is
///   `1001bff8`), so its redraw never runs. `.WrapDrawWaterEffects` (bubbles, particles) is not built. Then
///   `SpriteBlitter.wrapDrawSprites` at the scroll point, culled by the grid's drawn pair.
/// - `copyToScreen`: `ParallaxBlitter.copyToScreen` from the frame port into the screen (prefs+4 = parallax).
/// - `wrapEraseSprites`: `SpriteBlitter.wrapEraseSprites` with the grid's mask re-stamp.
/// - `statusBar`: `StatusBar.update` — full after a `setScreenClut` (the level start), incremental otherwise (D26 R5:
///   the seam does not carry the flag).
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
    }

    /// What `apply` executed, in order (the test oracle of the op order).
    enum Executed: Equatable {
        case screenClut(Int16), picture(Int16), entireGrid(h: Int, v: Int), strip(h: Int, v: Int), lightsOntoTiles
        case handleLights, sprites(Int), copy(h: Int, v: Int), erase(Int), statusBar(full: Bool)
    }

    public let resources: FerazelResources
    public let level: LevelFile
    public let prefs: FerazelPrefs
    public let search: ColorSearch
    public let dither: DitherModel
    public let tables: LevelTables
    /// The screen (the main device's 640×480 pixels).
    public private(set) var screen: IndexedFrame
    /// The CLUT the screen shows through (`.SetScreenClut`); present with `screen.rgba(through: screenClut)`.
    public private(set) var screenClut: ColorLUT
    public private(set) var ports: FramePorts
    public private(set) var grid: TileGridRenderer
    public private(set) var sprites: SpriteBlitter
    public let parallax: ParallaxBlitter
    public private(set) var statusBar: StatusBar
    /// `_DAT_100a0128`: the light slots the grid and the sprite light pass read.
    public private(set) var lights: LightRenderer
    /// `PTR_DAT_1009fe78`.
    public private(set) var scroll: (h: Int, v: Int) = (0, 0)
    /// The ops of the last `apply`, as executed.
    private(set) var executed: [Executed] = []
    private var statusBarFull = true
    /// The light faces loaded so far, by (pict, width, height).
    private var lightFaces: [[Int]: LightFace] = [:]

    /// The level's renderer: tile sets, tables, parallax, sprite faces (every level-1 Setup sheet plus the player's
    /// `.InitPlayerSprite` sets), empty light slots (`addLights`), the status bar under the level CLUT.
    /// - Parameter prefs: prefs+4 (parallax) and +6 (Effects) for the blitters; the Setup lights depend on Effects.
    public init(resources: FerazelResources, level: Int, search: ColorSearch, dither: DitherModel,
                text: any TextRasterizer, prefs: FerazelPrefs = FerazelPrefs()) throws {
        self.resources = resources
        self.prefs = prefs
        self.search = search
        self.dither = dither
        let L = try LevelFile.load(from: resources, level: Int16(level))
        self.level = L
        let clut = try ColorLUT.load(id: ColorLUT.screenClutId(L.header), from: resources, chain: .level)
        screenClut = clut
        // `.FastRand` for tint table 0xa is not modelled (R1's tests pass 0 too) [MED].
        tables = try LevelTables.forLevel(L.header, resources: resources, search: search, random: { _ in 0 })
        let fixed = try TileSets.Fixed(resources: resources, search: search, dither: dither)
        let sets = try TileSets(level: L, fixed: fixed, resources: resources, search: search, dither: dither)
        let clear = try TileGridRenderer.loadClearFace(resources: resources, search: search, dither: dither)
        parallax = try ParallaxBlitter(level: L, sets: sets)

        let context = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header),
                                         effects: prefs.effects)
        let entries = try L.activePlacements.map { try SetupFaces.setup($0, context: context) }
        let faces = try SpriteBlitter.Faces(Set(entries.compactMap(\.sheet)).union(Self.playerSheets),
                                            resources: resources, search: search, dither: dither)
        let lights = LightRenderer(level: L, tables: tables)
        self.lights = lights
        grid = TileGridRenderer(level: L, sets: sets, fixed: fixed, tables: tables, clearFace: clear, drawnH: 0,
                                drawnV: 0, effects: prefs.effects, lights: lights)
        sprites = SpriteBlitter(level: L, tables: tables, faces: faces, effects: prefs.effects, lights: lights)
        statusBar = try StatusBar(resources: resources, screenClut: clut, search: search, dither: dither, text: text)
        screen = IndexedFrame()
        ports = FramePorts()
    }

    /// `.InitPlayerSprite @ 1004a284` (l. 42428–42460): the Phase-1 pose's sets — stand 1003, fidgets 1028 / 1029,
    /// turn 1030, walk 1020, run 1024 — 100×120 cells, at boot under clut 200 (`.InitSprites`, l. 118).
    static let playerSheets: Set<SetupFaces.Sheet> = [
        SetupFaces.Sheet(pict: 0x3eb, count: 4, cellWidth: 100, cellHeight: 0x78, columns: 4, clut: 200),
        SetupFaces.Sheet(pict: 0x3fc, count: 0x10, cellWidth: 100, cellHeight: 0x78, columns: 4, clut: 200),
        SetupFaces.Sheet(pict: 0x400, count: 0xc, cellWidth: 100, cellHeight: 0x78, columns: 4, clut: 200),
        SetupFaces.Sheet(pict: 0x404, count: 10, cellWidth: 100, cellHeight: 0x78, columns: 10, clut: 200),
        SetupFaces.Sheet(pict: 0x405, count: 6, cellWidth: 100, cellHeight: 0x78, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: 0x406, count: 3, cellWidth: 100, cellHeight: 0x78, columns: 3, clut: 200),
    ]

    /// `.AddLight @ 1001bc08` for each light, in order (the session's `lights`, `.SetupLevelSprites` order): the first
    /// free slot gets `+0` active, `+1` new, `+2` 0, `+4` the face (`LightFace.load`, clut 801), `+8` nil, `+0x14`
    /// the face width >> 1, `+0xc` the point, `+0x18` the colour.
    /// - Throws: `Refusal.lightSlotsFull`; `LightFaceError` / `PictureSourceError` for a face that does not load.
    public func addLights(_ list: [SetupFaces.Light]) throws {
        for l in list {
            let key = [Int(l.pict), l.width, l.height]
            let face: LightFace
            if let f = lightFaces[key] { face = f } else {
                face = try LightFace.load(pict: l.pict, width: l.width, height: l.height, from: resources,
                                          search: search, dither: dither)
                lightFaces[key] = face
            }
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

    /// A face's opaque bounds (`face +8`) — what `FerazelSession(faceBounds:)` asks (`.ActiveToIdleSprite`).
    public func faceBounds(_ ref: FaceRef) -> IdleSprites.Rect {
        guard let b = sprites.faces.face(ref)?.bounds else { return .noFace }
        return IdleSprites.Rect(top: Int(b.top), left: Int(b.left), bottom: Int(b.bottom), right: Int(b.right))
    }

    /// Executes one iteration's draw ops (sounds, music and shell requests are the shell's).
    /// - Throws: `SpriteBlitter.Refusal` for a sprite shape outside the census, `Refusal.screenClut` for a CLUT the
    ///   tables were not built against, `ColorLUTError` / `PictureSourceError` for a missing CLUT or picture.
    public func apply(_ ops: FrameOps) throws {
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
                handleLights()
                executed.append(.handleLights)
                sprites.lights = lights
                try sprites.wrapDrawSprites(draws, h: scroll.h, v: scroll.v, drawn: (grid.drawnH, grid.drawnV),
                                            ports: &ports)
                executed.append(.sprites(draws.count))
            case .copyToScreen(let h, let v, let graphicsMode, let backdrop):
                parallax.copyToScreen(ports: ports, h: h, v: v, graphicsMode: graphicsMode, backdrop: backdrop,
                                      parallax: Int(prefs.parallax), screen: &screen.pixels)
                executed.append(.copy(h: h, v: v))
            case .wrapEraseSprites(let list, let h, let v):
                grid.lights = lights
                try sprites.wrapEraseSprites(list, h: h, v: v, ports: &ports, grid: grid)
                executed.append(.erase(list.count))
            case .statusBar(let state):
                let full = statusBarFull
                statusBar.update(state, full: full, screen: &screen)
                statusBarFull = false
                executed.append(.statusBar(full: full))
            }
        }
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

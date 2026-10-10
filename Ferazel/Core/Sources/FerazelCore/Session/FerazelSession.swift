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
///   (hdr 0x273c, l. 5222–5226), the countdown effect sprite 0x4c4 (l. 5183) and the player's held-item / trail
///   sprites (faceless at their Setups).
///
/// **Each iteration** (l. 5224–5290): `.FindUpperLeftCorner`, then `.PaintFrameWrap(draw, odd) @ 10011cf8` with
/// draw = 0 iff prefs[0] and not odd (odd starts false, toggles at the end — so with prefs[0] the FIRST iteration
/// skips): `.SetScrollLocation`, `.DrawLightsOntoTiles` unless prefs+6 == 3, `.WrapDrawSprites` unconditionally; only
/// the `if (param_1 != 0)` block (l. 9254–9450) with `.WrapCopyToScreen(port, h, v, 0x10, 8, prefs+9 == 0,
/// prefs+2 == 3, 0)` (l. 9443/9447) is skipped; then always `.HandleIdleSprites`, `.HandleSprites` (the items' light
/// twinkle from `.HandleBonusSprite` — `BonusHandle`, as `changeLightFace` ops — and the ◇ player pose and ◇ focus
/// driver standing in for the player Handle), `.WrapEraseSprites` (l. 9452–9456); after it
/// `.UpdateStatusBar(1, 0, 0)`.
public final class FerazelSession {
    public let resources: FerazelResources
    public let prefs: FerazelPrefs
    public let level: LevelFile
    public private(set) var globals: GameGlobals
    /// The active sprite list (the player included).
    public private(set) var active: ActiveList
    /// The idle-sprite table.
    public private(set) var idle: IdleSprites
    /// The lights the Setups added, in `.AddLight` (= `.SetupLevel`) order — the light slots 0… a renderer fills.
    public let lights: [SetupFaces.Light]
    /// The player's `ActiveList` id.
    public let playerID: Int
    public private(set) var pose: PlayerPose
    public private(set) var camera: Camera
    public private(set) var focusDriver: CameraFocusDriver
    /// The `.GameLoop` parity flag `bVar23`.
    public private(set) var odd = false
    /// Iterations run.
    public private(set) var iterations = 0

    private let faceBounds: (FaceRef) -> IdleSprites.Rect

    /// - Parameter faceBounds: a face's opaque bounds (`face +8`), which `.ActiveToIdleSprite` stores and
    ///   `.HandleIdleSprites` tests. Core has no face pixels; without it each face's frame (sheet cell, or the PICT's
    ///   frame for a single face) is used — a superset of the opaque bounds [MED].
    public init(resources: FerazelResources, prefs: FerazelPrefs, level: Int,
                faceBounds: ((FaceRef) -> IdleSprites.Rect)? = nil) throws {
        self.resources = resources
        self.prefs = prefs
        let L = try LevelFile.load(from: resources, level: Int16(level))
        self.level = L
        globals = GameGlobals(header: L.header)
        let bounds = faceBounds ?? { Self.frameRect($0, resources: resources) }
        self.faceBounds = bounds
        let p = PlayerPose(header: L.header)
        pose = p
        focusDriver = CameraFocusDriver(spriteX: p.x, spriteY: p.y, width: Int(L.header.gridWidth) * 0x20,
                                        height: Int(L.header.gridHeight) * 0x20)
        camera = try Camera(header: L.header, spriteX: p.x, spriteY: p.y)
        let context = SetupFaces.Context(level: L, playerX: focusDriver.pointX, effects: prefs.effects)
        var spawned = try SetupFaces.spawnLevelSprites(context: context) { e in
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
        playerID = spawned.active.insert(p.slot)
        active = spawned.active
        idle = spawned.idle
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
            camera.findUpperLeftCorner(focusX: focusDriver.focusX, focusY: focusDriver.focusY,
                                       playerVX: focusDriver.vx, graphics: graphics)
            ops.draws.append(.redrawScrollGrid(h: camera.scrollH, v: camera.scrollV))
            ops.draws.append(.redrawEntireScrollGrid(h: camera.scrollH, v: camera.scrollV))
            ops.draws.append(.statusBar(globals.statusBar(levelName: level.header.name)))
            ops.music.append(.play(track: Int(level.header.music)))
        }
        iterations += 1

        camera.findUpperLeftCorner(focusX: focusDriver.focusX, focusY: focusDriver.focusY, playerVX: focusDriver.vx,
                                   graphics: graphics)
        let draw = prefs.reduceFrameRate == 0 || odd
        let h = camera.scrollH, v = camera.scrollV
        ops.draws.append(.redrawScrollGrid(h: h, v: v))
        if prefs.effects != 3 { ops.draws.append(.drawLightsOntoTiles) }
        ops.draws.append(.wrapDrawSprites(active.wrapDrawSprites()))
        if draw {
            ops.draws.append(.copyToScreen(h: h, v: v, graphicsMode: Int(graphics), backdrop: prefs.plainCopy == 0))
        }
        // `.HandleIdleSprites`, then `.HandleSprites`: the player Handle (pose, then `.PlayerScroll`'s focus).
        let bounds = faceBounds
        idle.handle(h: h, v: v, playerHotRect: pose.hotRect, active: &active, faceRect: bounds)
        // The Bonus Handles' item-light twinkle (`BonusHandle`), active-list order.
        for id in active.sprites.map(\.id) {
            active.update(id: id) { s in
                if let op = BonusHandle.twinkle(&s, effects: prefs.effects) { ops.draws.append(op) }
            }
        }
        let held = CameraFocusDriver.Held(keys: keys, prefs: prefs)
        pose.step(left: held.left, right: held.right, run: held.run)
        let p = pose
        active.update(id: playerID) { s in
            s.face = p.face
            s.mirrored = p.mirrored
        }
        focusDriver.step(held)
        ops.draws.append(.wrapEraseSprites(sprites: active.sprites, h: h, v: v))
        ops.draws.append(.statusBar(globals.statusBar(levelName: level.header.name)))
        ops.drawn = draw
        odd.toggle()
        return ops
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

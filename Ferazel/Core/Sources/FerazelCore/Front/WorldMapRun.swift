import Foundation

// MARK: - What the map draws (M1 → M2)

/// The three surfaces `.ShowWorldMap` draws on (M2's `MapRenderer` keeps the two offscreen ports).
///
/// The ports are 640×416 slop-8 blit ports (`NewBlitPortSlop(640, 416, 0, 8)`, plan hazard "Slop-8 ports"): their
/// QuickDraw coordinates are **map coordinates** (the 608×384 PICT 7000 at (0, 0)), and a face blitted at (x, y) lands
/// with its top-left at port (x + 8, y + 8). The visible map is the port rect `WorldMapRun.viewRect` (0, 0, 608, 384)
/// copied to the screen offset by (16, 8) — map point (h, v) is screen (h + 16, v + 8).
public enum MapPort: Equatable, Sendable {
    /// `*_DAT_100a0004`: PICT 7000 and the links (`.DrawLink`) — what `.EraseNodeSprites` restores from.
    case background
    /// `*_DAT_100a000c`: the background's copy, the node sprites, the `.DrawNewLink` flashes and `.RedrawLinks`.
    case work
    /// The screen (`*(_DAT_1009ff58 + 4)`), 640×480.
    case screen
}

/// One map link as `.DrawLink(from, to)` / `.DrawLinkScratch(from, to)` draws it: from node `from`'s (h, v) to node
/// `to`'s, in map (port) coordinates.
public struct MapLink: Equatable, Sendable {
    public var h1: Int
    public var v1: Int
    public var h2: Int
    public var v2: Int

    public init(h1: Int, v1: Int, h2: Int, v2: Int) {
        self.h1 = h1
        self.v1 = v1
        self.h2 = h2
        self.v2 = v2
    }
}

/// A node sprite's face (`+0x8`): face `index` of a `FrontFaceSet`, and its size (the face record's `+6` width,
/// `+4` height — what the erase and copy rects use).
public struct MapFace: Equatable, Sendable {
    public var set: FrontFaceSet
    public var index: Int
    public var width: Int
    public var height: Int

    public init(set: FrontFaceSet, index: Int, width: Int, height: Int) {
        self.set = set
        self.index = index
        self.width = width
        self.height = height
    }
}

/// One record of the node-sprite list (`_DAT_100a0c30`, 16 bytes each, count `*_DAT_100a0c50`; `.AddNodeSprite @
/// 1007ae3c`, M l. 66668–66692).
public struct MapSprite: Equatable, Sendable {
    /// `+0` / `+2`: the blit position (x, y) — node sprites at (h − 20, v − 20), so a 24×24 face is centred on (h, v).
    public var h: Int
    public var v: Int
    /// `+4`: 0 level node, 1 boss node (the node's `+0x116`), 0x45 the player marker, 100 the ambient sprite.
    public var type: Int16
    /// `+6`: the animation counter.
    public var counter: Int16
    /// `+8`: the face drawn (nil = none; `.DrawNodeSprites` skips it).
    public var face: MapFace?
    /// `+0xd`: drawing this sprite calls `.RedrawLinks` (only the ambient sprite, while it has a face). `+0xc` (set
    /// with it, and by `.AddNodeSprite`) has no reader and is not kept. The array is static data (zero at launch) and
    /// only type-100 records write `+0xd`, so every other record's is 0.
    public var redrawsLinks: Bool

    public init(h: Int, v: Int, type: Int16, counter: Int16, face: MapFace? = nil, redrawsLinks: Bool = false) {
        self.h = h
        self.v = v
        self.type = type
        self.counter = counter
        self.face = face
        self.redrawsLinks = redrawsLinks
    }
}

/// One draw call of the map, in the original's order (M2 executes them).
public enum MapOp: Equatable, Sendable {
    /// A `DrawOp` on one surface. The map uses: on `.screen` — `setScreenClut`, `drawPicture` (PICT 129),
    /// `statusBar`, `screenGamma` (the fades); on `.background` — `copyPicture` (PICT 7000, `MTGetandDrawPICTResInRect`
    /// into (0, 0, 608, 384)); on `.work` — `drawFace` (a node sprite at its record's blit position (`h`, `v`): top-left
    /// at port (h + 8, v + 8), `BlitEncFaceClipX`) and `drawLine` (one `.DrawNewLink` flash line, pen 1×1, in its
    /// `RGBForeColor` [MED: `ColorSearch` under clut 700]).
    case draw(DrawOp, port: MapPort)
    /// `.ChangeBlitPortClut(port, clut)` on the work port, `*_DAT_100a0008` and the background (M l. 67498–67500).
    case portsClut(id: Int16)
    /// `.ReInitWorldMapGraphics @ 1007b560` (M l. 66962–67001): 20×20 and 12×12 blit ports with PICTs 600 and 601 —
    /// loaded for parity; nothing the map draws comes from them.
    case loadMapGraphics
    /// `.DrawLink @ 1007b7c8` (M l. 67057–67095) into the **background**, pen 1×1: ForeColor 33 (black) the centre
    /// line, then +1/+1, then −1/−1; ForeColor 30 (white) the centre line again; ForeColor 33.
    case drawLink(MapLink)
    /// `.RedrawLinks @ 1007afd8` (M l. 66743–66783): every visible link through `.DrawLinkScratch` (the same four strokes
    /// as `.DrawLink`, PenPat black) into the **work** port, in node then slot order — both ends of each link.
    case redrawLinks([MapLink])
    /// `CopyBits(from, to, source, dest, srcCopy)` (dest = source offset by (16, 8) when `to` is the screen).
    case copy(from: MapPort, to: MapPort, source: Rect16, dest: Rect16)
}

/// One `WorldMapRun.tick`'s work: the draws in order (`ops`), and the tick's sounds, music, requests and `present`
/// (`output.draws` is always empty — every draw is in `ops`, the screen's as `.draw(_, port: .screen)`).
public struct WorldMapOutput: Equatable, Sendable {
    public var ops: [MapOp]
    public var output: FrontOutput

    public init(ops: [MapOp] = [], output: FrontOutput = FrontOutput()) {
        self.ops = ops
        self.output = output
    }

    /// `other` after this tick's work.
    public mutating func append(_ other: WorldMapOutput) {
        ops += other.ops
        output.append(other.output)
    }

    /// A front-end output (a fade, a music cue): its draws go to the screen.
    mutating func append(_ front: FrontOutput) {
        ops += front.draws.map { .draw($0, port: .screen) }
        var rest = front
        rest.draws = []
        output.append(rest)
    }

    mutating func add(_ op: MapOp) {
        ops.append(op)
        output.present = true
    }
}

// MARK: - The run

/// `.ShowWorldMap @ 1007c494` (plan S2 `WorldMapRun`, M1; M l. 67432–67658) and its callees as a tick machine over
/// absolute 60 Hz ticks (Invariant 3); world-data §4.2 (+ BC14, BC24). It returns (`result`) the level to enter, or −1
/// when the game was aborted (`quitRequested` then says whether ⌘Q's OK also asked to quit).
///
/// **Entry (M l. 67493–67565):** `*_DAT_100a0088` (level complete) clear, or no node table (`Mmap` handle nil or empty)
/// → `ReportError("Error showing world map")`, return **1**; cur = `.FindCurrNode(hdr+0x26c4)` (none → "Current node
/// could not be found!" + `ExitToShell`: `quitRequested`, no `result`);
/// clut 700 on the three ports and the screen; PICT 129 (0, 0, 640, 480); `UpdateStatusBar(0,0,0)`;
/// `.ReInitWorldMapGraphics`; PICT 7000 into the background (0, 0, 608, 384); the unlock of exit1 / exit2 (≥ 0);
/// the ambient sprite (100 at (38, 168), counter −4); `.MakeNodeSprites`; the marker (0x45); `.UpdateNodeSprites`; the
/// background into the work port and to the screen; draw / copy / erase the sprites; `UpdateStatusBar(0,0,0)`;
/// `SetAIFFMusic(25)`, `FadeAIFFMusic(1, 2)` (48 ticks), `GammaFadeIn(15)`; walk target = cur, step 0; exit1 ≥ 0 →
/// the unlock again + `.DrawNewLink(cur, exit1)` (auto-walk); exit2 ≥ 0 → the unlock again, `.DrawNewLink(cur,
/// exit2)`, walk target = cur, step 0 (no auto-walk); exit1 = exit2 = −1; abort = 0; on-map = 1; `InputActivate(1,1)`.
///
/// **Loop (M l. 67567–67650), one iteration per tick:** runs while (no Return 0x24, no Enter 0x4c, no action 6, no
/// action 5) or step ≠ 0, and not aborted. `.FindPlayerNodeLoc`; step 0 → `.CheckPlayerNodeMovement` and the level
/// name (`STR# 1000[node[cur].level]` → hdr+0x25c4) + `UpdateStatusBar(0,0,0)`; the marker at the walk position − 20;
/// draw, copy to the screen; `UpdateStatusBar(1,0,0)`; the wait (≥ 1 tick from the iteration's start); Caps Lock →
/// `.Pause` (// later: P1); ⌘ (0x37) or Esc (0x35) held: + Q (0x0c) → the quit confirm, else + W (0x0d) or Esc → the
/// abort confirm; `.UpdateNodeSprites`, `.EraseNodeSprites`. The polled keys of an iteration's tail (Caps Lock, ⌘, Esc)
/// and of the next iteration's loop test are read on the same tick — the held-⌘ quirk: an idle ⌘ (action 6) ends the
/// loop before ⌘Q can be seen unless Q goes down on the same tick [MED, gate card].
///
/// **Exit (M l. 67651–67657):** `FadeAIFFMusic(0, 2)`, the node-sprite count 0, on-map 0; aborted → −1, else
/// `node[cur].level`.
///
/// The flow owns what the original keeps in globals and hands it in; it takes it back from here after the run:
/// `globals` (G: the unlocks), `rng` (`FastRand`, Invariant 5: one `FastRand(15)` per visible node, 150 per
/// `.DrawNewLink`), `fade` / `music`, and the exits `sRam100a5116` / `_DAT_100a5118` — globals only `.ShowWorldMap`
/// resets (to −1, M l. 67561): `exit1` / `exit2` here are −1 once the map loop has started.
public final class WorldMapRun {
    /// clut 700 (`*_DAT_100a0024`, `GetCTable(700)` at boot, M l. 396).
    public static let mapClut: Int16 = 700
    /// The map picture (app fork; the `.frontEnd` chain resolves the right copy — plan hazard "Two PICT 7000s").
    public static let mapPicture: Int16 = 7000
    /// `SetAIFFMusic(0x19)` (M l. 67540).
    public static let mapTrack = 0x19
    /// `*_DAT_100a03e0` = snd 0x1a4 (`.InitSounds`, M l. 39787–39788): `.DrawNewLink`'s sound.
    public static let newLinkSound: Int16 = 420
    /// `SetRect(0, 0, 0x260, 0x180)`: the map in port coordinates (M l. 67507).
    public static let viewRect = Rect16(top: 0, left: 0, bottom: 0x180, right: 0x260)
    /// `OffsetRect(…, 0x10, 8)`: where the port rect lands on the screen.
    public static let viewOffset = (h: 16, v: 8)
    /// Sprite types (`+4`).
    public static let markerType: Int16 = 0x45
    public static let ambientType: Int16 = 100

    static let errorShowingMap = "Error showing world map"            // 0x100a6d51
    static let nodeNotFound = "Current node could not be found!"       // 0x100a6d30
    static let quitText = "Are you sure you want to quit?"             // 0x100a6d69
    static let abortText = "Are you sure you want to abort this game?" // 0x100a6d88

    /// The node table (`*_DAT_100a043c`); an empty map when the world file has no `Mmap 200` (`mapMissing`).
    public let map: WorldMap
    /// No node table: the entry reports "Error showing world map" and returns 1 (M l. 67492–67496).
    public let mapMissing: Bool
    /// `STR# 1000` (`.InitMapLevelNames @ 1007ad84`, M l. 66644–66664: `GetIndString(1000, i)` for i < 100, from the
    /// world file).
    public let levelNames: StringList
    public let prefs: FerazelPrefs

    /// G (the flow's): `.ShowWorldMap` writes `unlocked` (+0x23e).
    public private(set) var globals: GameGlobals
    /// The game's one random stream (Invariant 5).
    public private(set) var rng: FastRand
    public private(set) var fade: ScreenFade
    public private(set) var music: MusicFade
    /// `sRam100a5116` (the exit sprite's p1) and `_DAT_100a5118` (p2): −1 = none; reset to −1 at M l. 67561.
    public private(set) var exit1: Int16
    public private(set) var exit2: Int16
    /// hdr+0x25c4: the status bar's level name — the finished level's Mlvl name until the loop's first name update.
    public private(set) var levelName: String
    /// `local_6e`: the node the player is on (a slot index).
    public private(set) var cur = 0
    /// `*_DAT_100a0c1c`: the walk's target node (= `cur` when not walking).
    public private(set) var walkTarget: Int16 = 0
    /// `*_DAT_100a0c18`: the walk's step (0 = not walking; the loop tests it).
    public private(set) var walkStep: Int16 = 0
    /// The node-sprite list (`_DAT_100a0c30` / count `*_DAT_100a0c50`): a global — the entry appends to it as the last
    /// run left it (`.ShowWorldMap` never clears it on entry); emptied on exit (M l. 67652).
    public private(set) var sprites: [MapSprite] = []
    /// `*_DAT_1009fd4c`: the game was aborted (an OK in either confirm).
    public private(set) var aborted = false
    /// `*_DAT_1009fd50`: ⌘Q's OK — the flow quits. Also set (with a `.quit` request and no `result`) when the current
    /// node is not found: `.FindCurrNode` calls `ExitToShell` and never returns (M l. 67154–67155).
    public private(set) var quitRequested = false
    /// `*PTR_DAT_1009fe2c`: on the map (set before the loop, cleared on exit).
    public private(set) var onMap = false
    /// The map loop's iterations run.
    public private(set) var iterations = 0
    /// `.ShowWorldMap`'s return value; nil while it runs.
    public private(set) var result: Int?

    private let level: Int16
    private let levelComplete: Bool
    private let markerFace: MapFace
    private let mapPictureFrame: Rect16
    /// The marker's index in `sprites` (`sVar14`).
    private var marker = 0

    private enum Stage: Equatable {
        case enter, musicIn, gammaIn, walkInit, newLink(exit: Int16, second: Bool), newLinkEnd(target: Int16, second: Bool)
        case loopStart, exitMusic, finish
    }

    private enum Pending {
        case mapError, noNode, confirm(quit: Bool)
    }

    private enum LoopPhase {
        /// The loop test and the iteration's drawing half.
        case head
        /// The rest of the iteration, on or after `due` (the one-tick wait).
        case tail(due: UInt32)
    }

    private var stages: [Stage] = [.enter]
    private var blocking: MapBlock?
    private var pending: Pending?
    private var answer: Bool?
    private var playing = false
    private var phase = LoopPhase.head

    /// - Parameters:
    ///   - globals: the flow's G.
    ///   - level: hdr+0x26c4 of the level just finished (`.FindCurrNode`'s argument).
    ///   - levelName: hdr+0x25c4 — that level's Mlvl name.
    ///   - exit1 / exit2: the exit globals (`sRam100a5116`, `_DAT_100a5118`).
    ///   - levelComplete: `*_DAT_100a0088`.
    ///   - seed: the game's `FastRand` seed.
    ///   - fade / music: the flow's gamma and music state.
    ///   - sprites: the node-sprite list as the previous map run left it (`sprites` after its exit — empty, M l. 67652).
    public init(resources: FerazelResources, prefs: FerazelPrefs, globals: GameGlobals, level: Int16, levelName: String,
                exit1: Int16, exit2: Int16, levelComplete: Bool, seed: Int32, fade: ScreenFade,
                music: MusicFade, sprites: [MapSprite] = []) throws {
        // `(int *)*_DAT_100a043c == 0 || *(int *)*_DAT_100a043c == 0` → the entry's error (M l. 67492–67493).
        if resources.world.resource(type: "Mmap", id: 200) == nil {
            map = try WorldMap(data: Data(count: WorldMap.length))
            mapMissing = true
        } else {
            map = try WorldMap.load(from: resources)
            mapMissing = false
        }
        self.sprites = sprites
        levelNames = try StringList.load(from: resources, id: 1000)
        self.prefs = prefs
        self.globals = globals
        rng = FastRand(seed: seed)
        self.fade = fade
        self.music = music
        self.exit1 = exit1
        self.exit2 = exit2
        self.levelName = levelName
        self.level = level
        self.levelComplete = levelComplete
        // `Load1EncFaceFromPICT(8000)` (`.InitMapFaces`, M l. 66629): one face the size of the PICT's frame.
        let markerSize = ChapterScreenRun.frameSize(
            resources.resource(type: "PICT", id: 8000, chain: .frontEnd)?.data) ?? (0x18, 0x18)
        markerFace = MapFace(set: .mapMarker, index: 0, width: markerSize.width, height: markerSize.height)
        let frame = ChapterScreenRun.frameSize(
            resources.resource(type: "PICT", id: Self.mapPicture, chain: .frontEnd)?.data) ?? (0x260, 0x180)
        mapPictureFrame = Rect16(top: 0, left: 0, bottom: Int16(truncatingIfNeeded: frame.height),
                                 right: Int16(truncatingIfNeeded: frame.width))
    }

    /// The answer to the dialog the last `tick` requested (`ShellRequest.dialog`): OK (true) or Cancel. The run goes
    /// on at the next `tick`.
    public func dialogDone(ok: Bool) {
        answer = ok
    }

    /// One tick at absolute 60 Hz `now` with this tick's polled input.
    public func tick(now: UInt32, input: FrontInput) -> WorldMapOutput {
        var out = WorldMapOutput()
        while result == nil {
            if var b = blocking {
                out.append(b.tick(now: now))
                guard b.isDone(now: now) else {
                    blocking = b
                    return out
                }
                blocking = nil
            }
            if let p = pending {
                guard let ok = answer else { return out }
                answer = nil
                pending = nil
                answered(p, ok: ok, out: &out)
                continue
            }
            if playing {
                guard loop(now: now, input: input, out: &out) else { return out }
                continue
            }
            guard !stages.isEmpty else { return out }
            run(stages.removeFirst(), now: now, out: &out)
        }
        return out
    }

    private func block(_ b: MapBlock) {
        if !b.isEmpty { blocking = b }
    }

    // MARK: Entry and exit

    private func run(_ stage: Stage, now: UInt32, out: inout WorldMapOutput) {
        switch stage {
        case .enter:
            enter(out: &out)
        case .musicIn:
            // `_SetAIFFMusic(0x19)`, `_FadeAIFFMusic(1, 2)` (M l. 67540–67541).
            out.append(FrontOutput(music: music.setAIFFMusic(Self.mapTrack)))
            block(MapBlock(music.fadeAIFFMusic(direction: 1, ticks: 2, prefs: prefs), start: now))
        case .gammaIn:
            block(MapBlock(fade.gammaFadeIn(0xf), start: now))                     // M l. 67542
        case .walkInit:
            // `*psVar17 = local_6e; *psVar10 = 0` (M l. 67543–67544).
            walkTarget = Int16(truncatingIfNeeded: cur)
            walkStep = 0
            if exit1 >= 0 {
                stages.insert(.newLink(exit: exit1, second: false), at: 0)
            } else if exit2 >= 0 {
                stages.insert(.newLink(exit: exit2, second: true), at: 0)
            }
        case .newLink(let exit, let second):
            // The unlock again (idempotent, M l. 67545–67559), then `.DrawNewLink(cur, exit)`.
            unlock(exit: exit)
            let target = link(exit: exit)
            block(drawNewLink(to: target, start: now))
            var next: [Stage] = [.newLinkEnd(target: target, second: second)]
            if !second, exit2 >= 0 { next.append(.newLink(exit: exit2, second: true)) }
            stages.insert(contentsOf: next, at: 0)
        case .newLinkEnd(let target, let second):
            // `.DrawNewLink`'s end: `*_DAT_100a0c1c = links[exit]`, `*_DAT_100a0c18 = 1` (M l. 67271–67272); after the
            // exit2 link the walk is cancelled (`*psVar17 = local_6e; *psVar10 = 0`, M l. 67558–67559).
            walkTarget = target
            walkStep = 1
            if second {
                walkTarget = Int16(truncatingIfNeeded: cur)
                walkStep = 0
            }
        case .loopStart:
            // `_DAT_100a5118 = −1; sRam100a5116 = −1; *fd4c = 0; *fe2c = 1; _InputActivate(1, 1)` (M l. 67561–67565).
            // InputSprocket is never active in the replica: no op.
            exit2 = -1
            exit1 = -1
            aborted = false
            onMap = true
            playing = true
            phase = .head
        case .exitMusic:
            block(MapBlock(music.fadeAIFFMusic(direction: 0, ticks: 2, prefs: prefs), start: now))  // M l. 67651
        case .finish:
            // `*_DAT_100a0c50 = 0; *fe2c = 0` (M l. 67652–67653); return −1 if aborted, else node[cur].level.
            sprites = []
            onMap = false
            result = aborted ? -1 : Int(levelOf(slot: cur))
        }
    }

    /// M l. 67493–67539: the checks, the screen, the unlocks, the sprites, the first frame.
    private func enter(out: inout WorldMapOutput) {
        guard levelComplete && !mapMissing else {
            // `_ReportError(&DAT_100a6d51, 0); return 1` (M l. 67492–67496).
            out.output.requests.append(.dialog(.error(text: Self.errorShowingMap, code: 0)))
            pending = .mapError
            return
        }
        guard let node = map.findCurrNode(level: level) else {
            // `.FindCurrNode`: `_ReportError(&DAT_100a6d30, 0); ExitToShell()` (M l. 67154–67155).
            out.output.requests.append(.dialog(.error(text: Self.nodeNotFound, code: 0)))
            pending = .noNode
            return
        }
        cur = node.index
        // The clut on the work port, `_DAT_100a0008`, the background, then the screen (M l. 67498–67501).
        out.add(.portsClut(id: Self.mapClut))
        out.add(.draw(.setScreenClut(id: Self.mapClut), port: .screen))
        // `_MTGetandDrawPICTResInRect(0x81, (0, 0, 640, 480))`, `_UpdateStatusBar(0, 0, 0)` (M l. 67504–67505).
        out.add(.draw(.drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0), port: .screen))
        out.add(.draw(.statusBar(statusBar()), port: .screen))
        out.add(.loadMapGraphics)                                                // M l. 67506
        // PICT 7000 into the background at (0, 0, 608, 384) (M l. 67507–67512).
        out.add(.draw(.copyPicture(id: Self.mapPicture, chain: .frontEnd, source: mapPictureFrame, dest: Self.viewRect,
                                   forceClut: nil, transparent: false), port: .background))
        // The unlocks (M l. 67513–67524).
        if exit1 >= 0 { unlock(exit: exit1) }
        if exit2 >= 0 { unlock(exit: exit2) }
        // `_AddNodeSprite(0x26, 0xa8, 100, −4, 0)`, `.MakeNodeSprites`, the marker at cur (M l. 67525–67529) —
        // appended at the count the last exit left (no reset here).
        addSprite(MapSprite(h: 0x26, v: 0xa8, type: Self.ambientType, counter: -4))
        makeNodeSprites(out: &out)
        marker = addSprite(MapSprite(h: Int(node.h) - 0x14, v: Int(node.v) - 0x14, type: Self.markerType, counter: 0))
        updateNodeSprites()                                                      // M l. 67530
        // The background into the work port and onto the screen (M l. 67531–67535).
        out.add(.copy(from: .background, to: .work, source: Self.viewRect, dest: Self.viewRect))
        out.add(.copy(from: .background, to: .screen, source: Self.viewRect, dest: Self.toScreen(Self.viewRect)))
        drawNodeSprites(out: &out)                                               // M l. 67536–67538
        copyNodeSpritesToScreen(out: &out)
        eraseNodeSprites(out: &out)
        out.add(.draw(.statusBar(statusBar()), port: .screen))                   // M l. 67539
        stages = [.musicIn, .gammaIn, .walkInit, .loopStart]
    }

    private func answered(_ p: Pending, ok: Bool, out: inout WorldMapOutput) {
        switch p {
        case .mapError:
            result = 1
        case .noNode:
            // `ExitToShell()` (M l. 67155): the original never returns (the decompile's `return 0` is unreachable) —
            // no level result; the run stops here.
            out.output.requests.append(.quit)
            quitRequested = true
        case .confirm(let quit):
            // `_ConfirmAbortGameDialog()`: OK → abort (+ the quit flag); Cancel → `_HideCursorSafe()`; then the map
            // view copied back over the dialog (M l. 67602–67646).
            if ok {
                aborted = true
                if quit { quitRequested = true }
            } else {
                out.output.requests.append(.hideCursor)
            }
            out.add(.copy(from: .work, to: .screen, source: Self.viewRect, dest: Self.toScreen(Self.viewRect)))
            iterationEnd(out: &out)
            phase = .head
        }
    }

    // MARK: The loop

    /// The loop's part of a tick: false when it waits for a later tick.
    private func loop(now: UInt32, input: FrontInput, out: inout WorldMapOutput) -> Bool {
        switch phase {
        case .head:
            let keys = input.keys
            let actions = InputActions(keys: keys, prefs: prefs)
            // The loop test (M l. 67567–67570).
            let select = keys.isPressed(0x24) || keys.isPressed(0x4c) || actions.contains(.use)
                || actions.contains(.jump)
            guard (!select || walkStep != 0) && !aborted else {
                playing = false
                stages = [.exitMusic, .finish]
                return true
            }
            iterations += 1
            let at = findPlayerNodeLoc()                                         // M l. 67572
            if walkStep == 0 {
                // M l. 67575–67579.
                let target = Self.checkPlayerNodeMovement(map: map, node: cur, globals: globals, keys: keys,
                                                          prefs: prefs)
                if target != 0 {
                    walkTarget = target
                    walkStep = 1
                }
                levelName = levelNames.string(Int(levelOf(slot: cur))) ?? ""
                out.add(.draw(.statusBar(statusBar()), port: .screen))
            }
            // The marker at the walk position (M l. 67580–67581), draw, copy, `_UpdateStatusBar(1, 0, 0)`.
            sprites[marker].h = at.h - 0x14
            sprites[marker].v = at.v - 0x14
            drawNodeSprites(out: &out)
            copyNodeSpritesToScreen(out: &out)
            out.add(.draw(.statusBar(statusBar()), port: .screen))
            // `_DeadTime()`, then wait until `TickCount − 1 ≥ start` (M l. 67585–67588).
            phase = .tail(due: now &+ 1)
            return false
        case .tail(let due):
            guard Int32(bitPattern: now &- due) >= 0 else { return false }
            let keys = input.keys
            // `_CapsLockDown() && *(short *)PTR_DAT_1009fe14 == 0` → the work port copied aside, `.Pause`, copied back
            // (M l. 67590–67600). // later: P1 — `.Pause` is P1's (`PauseRun`); the debounce `fe14` is never set > 0
            // (BC15).
            // ⌘ or Esc held (M l. 67602–67646).
            if keys.isPressed(0x37) || keys.isPressed(0x35) {
                var quit: Bool?
                if keys.isPressed(0x0c) {
                    quit = true
                } else if keys.isPressed(0x0d) || keys.isPressed(0x35) {
                    quit = false
                }
                if let q = quit {
                    // `FlushEvents(0xff7f, 0)` (no event queue in Core), `_ShowCursorSafe()`, `ParamText`, the confirm.
                    out.output.requests += [.showCursor, .dialog(.confirm(text: q ? Self.quitText : Self.abortText))]
                    pending = .confirm(quit: q)
                    return false
                }
            }
            iterationEnd(out: &out)
            phase = .head
            return true
        }
    }

    /// `_UpdateNodeSprites(); _EraseNodeSprites();` (M l. 67648–67649).
    private func iterationEnd(out: inout WorldMapOutput) {
        updateNodeSprites()
        eraseNodeSprites(out: &out)
    }

    // MARK: Callees

    /// `.FindPlayerNodeLoc(&loc, &cur) @ 1007b674` (M l. 67008–67054, raw `1007b674..1007b788`): not walking
    /// (`cur == walkTarget`) → cur's (h, v); else step += 1 first, each axis `trunc(cur·(30 − step)/30) +
    /// trunc(tgt·step/30)` (each product divided separately, truncating), and step ≥ 30 (`0x1d < step`) → cur =
    /// target, step = 0 in the same call. Walks therefore draw 29 frames, steps 2…30 (BC24).
    private func findPlayerNodeLoc() -> (h: Int, v: Int) {
        let c = map.node(cur)
        guard Int16(truncatingIfNeeded: cur) != walkTarget else { return (Int(c?.h ?? 0), Int(c?.v ?? 0)) }
        walkStep &+= 1
        let s = Int(walkStep)
        let t = map.node(Int(walkTarget))
        func axis(_ a: Int16?, _ b: Int16?) -> Int {
            Int(Int16(truncatingIfNeeded: Int(a ?? 0) * (30 - s) / 30 + Int(b ?? 0) * s / 30))
        }
        let at = (h: axis(c?.h, t?.h), v: axis(c?.v, t?.v))
        if s > 0x1d {
            cur = Int(walkTarget)
            walkStep = 0
        }
        return at
    }

    /// `.CheckPlayerNodeMovement(node) @ 1007bfdc` (M l. 67281–67429): the node a held direction moves to (0 =
    /// none). Per non-zero link slot, a primary and a secondary direction (1 left, 2 right, 3 up, 4 down): target above
    /// (`tgt.v < cur.v` strictly) and left (`tgt.h < cur.h`) → (1, 3) when |dv| < |dh| else (3, 1); above-right → (2, 3)
    /// / (3, 2); level or below: (1, 4) / (4, 1), (2, 4) / (4, 2) — a tie makes the vertical primary, equal h takes the
    /// right branch. Keys: left = action 0 or 0x7b, right = action 1 or 0x7c, up = action 2 or 0x7e, down = action 3 or
    /// 0x7d. Pass 1 tries the primaries in slot order, pass 2 (only when pass 1 found none) the secondaries; the first
    /// held direction whose target exists and whose level is unlocked wins. (A zero slot's directions are uninitialised
    /// stack in the original — any match reaches node 0, which does not exist; here they are 0 and never match.)
    public static func checkPlayerNodeMovement(map: WorldMap, node: Int, globals: GameGlobals, keys: KeyState,
                                               prefs: FerazelPrefs) -> Int16 {
        guard let c = map.node(node) else { return 0 }
        var primary = [Int](repeating: 0, count: 7), secondary = [Int](repeating: 0, count: 7)
        for (i, l) in c.links.enumerated() where l != 0 {
            let t = map.node(Int(l))
            let tv = Int(t?.v ?? 0), th = Int(t?.h ?? 0)
            let dv = Int(Int16(truncatingIfNeeded: abs(Int(c.v) - tv)))
            let dh = Int(Int16(truncatingIfNeeded: abs(Int(c.h) - th)))
            let horizontal = th < Int(c.h) ? 1 : 2
            let vertical = tv < Int(c.v) ? 3 : 4
            (primary[i], secondary[i]) = dv < dh ? (horizontal, vertical) : (vertical, horizontal)
        }
        let a = InputActions(keys: keys, prefs: prefs)
        let held = [
            1: a.contains(.left) || keys.isPressed(0x7b), 2: a.contains(.right) || keys.isPressed(0x7c),
            3: a.contains(.up) || keys.isPressed(0x7e), 4: a.contains(.down) || keys.isPressed(0x7d),
        ]
        for dirs in [primary, secondary] {
            for (i, d) in dirs.enumerated() where held[d] == true {
                let l = c.links[i]
                if let t = map.node(Int(l)), isUnlocked(globals, t.level) { return l }
            }
        }
        return 0
    }

    /// `.DrawNewLink(cur, exit) @ 1007bc28` (M l. 67171–67274, raw `1007bc28..1007bfd8`) as a blocking 100-tick loop:
    /// snd 420 (`STPlayRegSound(…, 1, 0x100)`) once; 50 iterations, each starting ≥ 2 ticks after the previous one's
    /// start (`TickCount − 2 < start` → `DeadTime`): three `FastRand(32000) << 1` (R, G, B, as shorts), the three lines
    /// cur → target in that colour into the work port — centre, −1/−1, +1/+1 (`.DrawLink`'s order differs) —,
    /// `.DrawNodeSprites`, the dirty rect (bbox ± 10) copied to the screen at (+16, +8), `.EraseNodeSprites`; then
    /// `.DrawNodeSprites`, the rect restored from the background, `.DrawNodeSprites`, the copy to the screen. The
    /// draws are made when the loop starts (nothing else draws from the stream while it blocks).
    private func drawNewLink(to target: Int16, start: UInt32) -> MapBlock {
        let c = map.node(cur), t = map.node(Int(target))
        let h1 = Int(c?.h ?? 0), v1 = Int(c?.v ?? 0), h2 = Int(t?.h ?? 0), v2 = Int(t?.v ?? 0)
        var events: [MapBlock.Event] = []
        var sound = FrontOutput()
        if prefs.soundOn != 0 {
            sound.sounds.append(SoundCues.regSound(snd: Self.newLinkSound, priority: 1, volume: 0x100,
                                                   global: SoundCues.globalVolume(prefs)))
        }
        let rect = Rect16(top: Int16(truncatingIfNeeded: min(v1, v2) - 10),
                          left: Int16(truncatingIfNeeded: min(h1, h2) - 10),
                          bottom: Int16(truncatingIfNeeded: max(v1, v2) + 10),
                          right: Int16(truncatingIfNeeded: max(h1, h2) + 10))
        for k in 0..<0x32 {
            var o = WorldMapOutput()
            if k == 0 { o.append(sound) }
            let r = UInt16(bitPattern: rng.next(32000) &<< 1)
            let g = UInt16(bitPattern: rng.next(32000) &<< 1)
            let b = UInt16(bitPattern: rng.next(32000) &<< 1)
            let rgb = RGB16(red: r, green: g, blue: b)
            for d in [0, -1, 1] {
                o.add(.draw(.drawLine(h1: h1 + d, v1: v1 + d, h2: h2 + d, v2: v2 + d, rgb: rgb), port: .work))
            }
            drawNodeSprites(out: &o)
            o.add(.copy(from: .work, to: .screen, source: rect, dest: Self.toScreen(rect)))
            eraseNodeSprites(out: &o)
            events.append(.init(at: 2 * k, out: o))
        }
        var end = WorldMapOutput()
        drawNodeSprites(out: &end)
        end.add(.copy(from: .background, to: .work, source: rect, dest: rect))
        drawNodeSprites(out: &end)
        end.add(.copy(from: .work, to: .screen, source: rect, dest: Self.toScreen(rect)))
        events.append(.init(at: 2 * 0x32, out: end))
        return MapBlock(events: events, duration: 2 * 0x32, start: start)
    }

    /// `.AddNodeSprite @ 1007ae3c` (M l. 66668–66692): appended; returns its index.
    @discardableResult
    private func addSprite(_ s: MapSprite) -> Int {
        sprites.append(s)
        return sprites.count - 1
    }

    /// `.MakeNodeSprites @ 1007aea4` (M l. 66696–66739): over slots 0…127, each existing node whose level is unlocked
    /// → `FastRand(15)` (before `.AddNodeSprite`), a sprite at (h − 20, v − 20) of type node `+0x116` with that
    /// counter, then `.DrawLink(node, link)` for every link slot > 0 whose target's level is unlocked (the target's
    /// existence is not checked; each link is drawn from both ends).
    private func makeNodeSprites(out: inout WorldMapOutput) {
        for n in map.nodes where Self.isUnlocked(globals, n.level) {
            let c = rng.next(15)
            addSprite(MapSprite(h: Int(n.h) - 0x14, v: Int(n.v) - 0x14, type: n.face, counter: c))
            for l in n.links where l > 0 && Self.isUnlocked(globals, levelOf(slot: Int(l))) {
                out.add(.drawLink(mapLink(from: n, to: Int(l))))
            }
        }
    }

    /// `.RedrawLinks`' list (M l. 66743–66783): the same walk as `.MakeNodeSprites`' links.
    private func visibleLinks() -> [MapLink] {
        var links: [MapLink] = []
        for n in map.nodes where Self.isUnlocked(globals, n.level) {
            for l in n.links where l > 0 && Self.isUnlocked(globals, levelOf(slot: Int(l))) {
                links.append(mapLink(from: n, to: Int(l)))
            }
        }
        return links
    }

    /// `.UpdateNodeSprites @ 1007b0dc` (M l. 66786–66851): type 0 / 1 → counter + 1, wrapping to 0 past 15, face
    /// `c >> 1` of PICT 8001 / 8002; 0x45 → the marker face; 100 → counter + 1, wrapping to 0 past 127, face `c >> 4`
    /// of PICT 8004 when c ≥ 0 else none, `+0xd` = face ≠ nil. Other types are left as they are.
    private func updateNodeSprites() {
        for i in sprites.indices {
            var s = sprites[i]
            switch s.type {
            case Self.markerType:
                s.face = markerFace
            case 0, 1:
                s.counter &+= 1
                if s.counter > 0xf { s.counter = 0 }
                s.face = MapFace(set: s.type == 1 ? .mapBoss : .mapNode, index: Int(s.counter) >> 1, width: 0x18,
                                 height: 0x18)
            case Self.ambientType:
                s.counter &+= 1
                if s.counter > 0x7f { s.counter = 0 }
                // `LoadEncFaceSetFromPICT(0x1f44, 8, 0x40, 0x56, …)` (M l. 66637): 64 wide, 86 high.
                s.face = s.counter < 0 ? nil : MapFace(set: .mapAmbient, index: Int(s.counter) >> 4, width: 0x40,
                                                       height: 0x56)
                s.redrawsLinks = s.face != nil
            default:
                break
            }
            sprites[i] = s
        }
    }

    /// `.DrawNodeSprites @ 1007b268` (M l. 66855–66884): each sprite with a face, in list order, blitted into the work
    /// port at (`+0`, `+2`); `+0xd` set → `.RedrawLinks` right after it.
    private func drawNodeSprites(out: inout WorldMapOutput) {
        for s in sprites {
            guard let f = s.face else { continue }
            out.add(.draw(.drawFace(set: f.set, index: f.index, h: s.h, v: s.v), port: .work))
            if s.redrawsLinks { out.add(.redrawLinks(visibleLinks())) }
        }
    }

    /// `.EraseNodeSprites @ 1007b344` (M l. 66888–66917): each sprite with a face except type 100, the rect
    /// `SetRect(x + 4, y + 4, x + w + 12, y + h + 12)` copied from the background into the work port.
    private func eraseNodeSprites(out: inout WorldMapOutput) {
        for s in sprites where s.type != Self.ambientType {
            guard let r = Self.spriteRect(s) else { continue }
            out.add(.copy(from: .background, to: .work, source: r, dest: r))
        }
    }

    /// `.CopyNodeSpritesToScreen @ 1007b438` (M l. 66921–66958): each sprite with a face, the same rect from the work
    /// port to the screen at (+16, +8).
    private func copyNodeSpritesToScreen(out: inout WorldMapOutput) {
        for s in sprites {
            guard let r = Self.spriteRect(s) else { continue }
            out.add(.copy(from: .work, to: .screen, source: r, dest: Self.toScreen(r)))
        }
    }

    // MARK: Lookups

    /// `SetRect(x + 4, y + 4, x + face.width + 12, y + face.height + 12)` (l, t, r, b).
    static func spriteRect(_ s: MapSprite) -> Rect16? {
        guard let f = s.face else { return nil }
        return Rect16(top: Int16(truncatingIfNeeded: s.v + 4), left: Int16(truncatingIfNeeded: s.h + 4),
                      bottom: Int16(truncatingIfNeeded: s.v + f.height + 12),
                      right: Int16(truncatingIfNeeded: s.h + f.width + 12))
    }

    /// `OffsetRect(r, 0x10, 8)`.
    static func toScreen(_ r: Rect16) -> Rect16 {
        Rect16(top: r.top &+ Int16(viewOffset.v), left: r.left &+ Int16(viewOffset.h),
               bottom: r.bottom &+ Int16(viewOffset.v), right: r.right &+ Int16(viewOffset.h))
    }

    /// `*(short *)(G + 0x23e + 2·level) != 0`; a level outside 0…99 reads as locked.
    static func isUnlocked(_ g: GameGlobals, _ level: Int16) -> Bool {
        g.unlocked.indices.contains(Int(level)) && g.unlocked[Int(level)] != 0
    }

    /// Slot `slot`'s +0x102 level; an empty slot reads 0 [LOW: an empty slot's bytes taken as zero, as `.InitWorldMap`
    /// leaves a fresh map — never reached with the shipped data].
    private func levelOf(slot: Int) -> Int16 { map.node(slot)?.level ?? 0 }

    /// `node[cur].links[exit]` (`+0x108 + 2·exit`); an exit outside the seven slots reads 0 [LOW: the original reads
    /// past them — never in the data].
    private func link(exit: Int16) -> Int16 {
        guard let c = map.node(cur), (0..<c.links.count).contains(Int(exit)) else { return 0 }
        return c.links[Int(exit)]
    }

    /// `unlocked[node[node[cur].links[exit]].level] = 1` (M l. 67513–67524, 67545–67557).
    private func unlock(exit: Int16) {
        let l = levelOf(slot: Int(link(exit: exit)))
        if globals.unlocked.indices.contains(Int(l)) { globals.unlocked[Int(l)] = 1 }
    }

    private func mapLink(from n: WorldMap.Node, to slot: Int) -> MapLink {
        let t = map.node(slot)
        return MapLink(h1: Int(n.h), v1: Int(n.v), h2: Int(t?.h ?? 0), v2: Int(t?.v ?? 0))
    }

    /// What `.UpdateStatusBar` draws, with hdr+0x25c4 = `levelName`.
    private func statusBar() -> StatusBarState { globals.statusBar(levelName: levelName) }
}

/// A blocking map loop (`FrontTimeline`'s rule, with map draws): each event's work at `at` ticks after `start`; the
/// run is blocked for `duration` ticks.
struct MapBlock {
    struct Event {
        var at: Int
        var out: WorldMapOutput
    }

    var events: [Event]
    var duration: Int
    let start: UInt32
    private var next = 0

    init(events: [Event], duration: Int, start: UInt32) {
        self.events = events
        self.duration = duration
        self.start = start
    }

    /// A front-end timeline (a fade, a music fade): its draws go to the screen.
    init(_ t: FrontTimeline, start: UInt32) {
        self.init(events: t.events.map { e in
            var o = WorldMapOutput()
            o.append(e.output)
            return Event(at: e.at, out: o)
        }, duration: t.duration, start: start)
    }

    var isEmpty: Bool { events.isEmpty && duration == 0 }

    mutating func tick(now: UInt32) -> WorldMapOutput {
        var out = WorldMapOutput()
        let t = Int(now &- start)
        while next < events.count, events[next].at <= t {
            out.append(events[next].out)
            next += 1
        }
        if !out.ops.isEmpty { out.output.present = true }
        return out
    }

    func isDone(now: UInt32) -> Bool { next == events.count && Int(now &- start) >= duration }
}

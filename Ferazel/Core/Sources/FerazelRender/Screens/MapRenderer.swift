import Foundation
import FerazelCore

/// The world map's drawing (plan S4 / M2): executes `WorldMapRun`'s `MapOp`s (M1) on the two offscreen map ports and the
/// shared `ScreenSurface` (through `screen`, the front-end `ScreenRenderer`).
///
/// - **Ports.** `background` (`*_DAT_100a0004`) and `work` (`*_DAT_100a000c`) are `NewBlitPortSlop(640, 416, 0, 8)`
///   ports (`.NewBlitPortSlop @ 10034650`, M l. 31446–31523): a 656×432 GWorld whose QuickDraw rect is (0, 0, 656, 432)
///   and whose blit base is `baseAddr + rowBytes·8 + 8` (M l. 31490) — so QuickDraw (lines, `CopyBits`) addresses
///   `Port` by QuickDraw point, and a face blitted at (x, y) lands with its top-left at (x + 8, y + 8), clipped to the
///   blit rect 640×416 (`+0x50`/`+0x54`, `.BlitEncFaceClipX @ 10024998`, M l. 20436ff). The ports are the level's
///   persistent ports in the original; nothing the map shows reads their old contents (PICT 7000 covers the view
///   (0, 0, 608, 384) of the background, which is copied whole into the work port before any sprite), so they start 0.
/// - **`portsClut(id)`** (`.ChangeBlitPortClut`, M l. 67498–67500): the ports' colour table (entries and seed copied,
///   pixels kept). Lines and pictures take their indices in it.
/// - **Faces** (`.InitMapFaces @ 1007ac38`, M l. 66617–66640): loaded with the conversion CLUT `*_DAT_1009ff94` swapped
///   to clut 700 (`*_DAT_100a0024`) — PICT 8000 one face (`Load1EncFaceFromPICT`), 8001 / 8002 eight 24×24 faces
///   (`LoadEncFaceSetFromPICT(id, 8, 0x18, 0x18, 8, …)`), 8004 eight 64×86 faces (`(0x1f44, 8, 0x40, 0x56, 8, …)`), from
///   the Sprites file (`.frontEnd`). 8003 (`Load1EncFaceFromPICT(0x1f43)` into `_DAT_100a0c40`) has no reader: not loaded.
///   Each face set loads on its first `drawFace`.
/// - **`drawFace` on `.work`** (`.DrawNodeSprites @ 1007b268`, M l. 66855–66884): `BlitEncFaceClipX(face, work, (0, 0),
///   (x, y), w, h)` — the token stream's copy runs written raw (clut-700 indices into a clut-700 port), skips leave the
///   port. A node sprite at (h − 20, v − 20) puts a 24×24 face at QuickDraw (h − 12 … h + 11): centred on (h, v).
/// - **`drawLink`** (`.DrawLink @ 1007b7c8`, M l. 67057–67095) into the **background**, and **`redrawLinks`** (each
///   through `.DrawLinkScratch @ 1007b998`, M l. 67102–67133, `PenPat(black)`) into the **work** port: pen 1×1,
///   `ForeColor(blackColor)` (33) the centre line (h1, v1)→(h2, v2), then +1/+1, then −1/−1; `ForeColor(whiteColor)`
///   (30) the centre line again. `ForeColor`'s classic colours resolve to RGB black / white through `Color2Index` in the
///   port's CLUT [MED: the GWorld's device takes the port's colour table].
/// - **`drawLine` on `.work`** (`.DrawNewLink`'s flash lines, M l. 67171–67274): `RGBForeColor(rgb)` → `Color2Index`
///   in the port CLUT (clut 700) [MED: QuickDraw `RGBForeColor`].
/// - Lines (`linePixels`): one pixel per step, both end points, Bresenham [MED: QuickDraw's line rasterisation is ROM
///   code], drawn from the upper end point (the lower `v`; on a tie the left one) so a link drawn from both of its ends
///   (`.MakeNodeSprites` draws each one twice) lands on the same pixels [MED]; clipped to the port.
/// - **`copyPicture` on `.background`** (PICT 7000, `MTGetandDrawPICTResInRect`, M l. 67507–67512): the picture
///   converted under the port CLUT (`ConvertedPicture`), stretched by nearest row / column as `ScreenRenderer.copyBits`.
/// - **`copy(from, to, source, dest)`**: `CopyBits` srcCopy. Port → port: raw (one CLUT). Port → screen: each index by
///   colour — `Color2Index` of its port-CLUT colour in the screen CLUT (the port's seed is clut 700's, the screen
///   device's differs) [MED]; nearest stretch (the map's rects never change size); clipped to both.
/// - **`.draw(op, port: .screen)`**: `screen.apply([op])`, except `statusBar` — the bar the map shows over PICT 129
///   (`.UpdateStatusBar`, its level name in Times (20) 12 bold white `0xffff` at `MoveTo(27, 46)` in the status port,
///   `.UpdateTextStats` M l. 4612–4666) through the existing `StatusBar` path, built on the screen CLUT of the moment.
///   Every map bar is drawn as `UpdateStatusBar(0, 0, 0)` (full) [MED]: the op carries no flag; the idle loop and the
///   entry call (0, 0, 0), only walking iterations call (1, 0, 0) — and with the same state a full redraw paints the
///   pixels the incremental one leaves (no map rect reaches the bar's rows 392…479 with the shipped nodes).
/// - **`loadMapGraphics`** (`.ReInitWorldMapGraphics`): PICTs 600 / 601 into two blit ports nothing draws from — no op.
public final class MapRenderer {

    public enum Refusal: Error, Equatable {
        /// A `DrawOp` the map never sends to that port (the op's name, the port).
        case unexpected(String, MapPort)
    }

    /// One slop-8 map port, addressed by QuickDraw point (0…655, 0…431).
    public struct Port: Sendable, Equatable {
        public static let width = 0x290
        public static let height = 0x1b0
        /// `NewBlitPortSlop`'s slop: blit (x, y) is QuickDraw (x + 8, y + 8).
        public static let slop = 8
        /// The blit rect `+0x50` / `+0x54` (640 × 416).
        public static let blitWidth = 0x280
        public static let blitHeight = 0x1a0

        /// Row-major `width × height`.
        public var pixels: [UInt8]

        public init(fill: UInt8 = 0) {
            pixels = [UInt8](repeating: fill, count: Self.width * Self.height)
        }

        public subscript(x: Int, y: Int) -> UInt8 {
            get { pixels[y * Self.width + x] }
            set { pixels[y * Self.width + x] = newValue }
        }

        static func contains(_ x: Int, _ y: Int) -> Bool { (0..<width).contains(x) && (0..<height).contains(y) }
    }

    /// The front-end renderer the screen ops go to (its surface is the screen).
    public let screen: ScreenRenderer
    /// `*_DAT_100a0004`: PICT 7000 and the links.
    public internal(set) var background = Port()
    /// `*_DAT_100a000c`: the background's copy, the sprites, the flashes, `.RedrawLinks`.
    public internal(set) var work = Port()
    /// The ports' CLUT (`.portsClut`); nil before the map's first op.
    public private(set) var portClut: ColorLUT?

    private var faceSets: [FrontFaceSet: FaceSheet] = [:]
    private var statusBar: StatusBar?
    private var statusBarClut: ColorLUT?

    public init(screen: ScreenRenderer) {
        self.screen = screen
    }

    /// Executes `ops` in order.
    /// - Throws: `Refusal.unexpected`, `ScreenRenderer.Refusal`, missing CLUT / picture errors.
    public func apply(_ ops: [MapOp]) throws {
        for op in ops {
            switch op {
            case .draw(let d, let port):
                try draw(d, on: port)
            case .portsClut(let id):
                portClut = try ColorLUT.load(id: id, from: screen.resources, chain: screen.chain)
            case .loadMapGraphics:
                break
            case .drawLink(let l):
                try drawLink(l, into: &background)
            case .redrawLinks(let links):
                for l in links { try drawLink(l, into: &work) }
            case .copy(let from, let to, let source, let dest):
                try copy(from: from, to: to, source: source, dest: dest)
            }
        }
    }

    /// Face `index` of `set` (`.InitMapFaces`, under clut 700).
    public func face(_ set: FrontFaceSet, _ index: Int) throws -> EncodedFace {
        if faceSets[set] == nil {
            let loader: FaceSheet.Loader
            switch set {
            case .mapMarker:
                loader = .single(pict: set.pict)
            case .mapNode, .mapBoss:
                loader = .set(try FaceSheet.Arguments(pict: set.pict, count: 8, cellWidth: 0x18, cellHeight: 0x18,
                                                      columns: 8))
            case .mapAmbient:
                loader = .set(try FaceSheet.Arguments(pict: set.pict, count: 8, cellWidth: 0x40, cellHeight: 0x56,
                                                      columns: 8))
            }
            let c700 = try ColorLUT.load(id: WorldMapRun.mapClut, from: screen.resources, chain: .frontEnd)
            faceSets[set] = try FaceSheet.load(loader, from: screen.resources, chain: .frontEnd, clut: c700,
                                               search: screen.search, dither: screen.dither)
        }
        let faces = faceSets[set]?.faces ?? []
        guard faces.indices.contains(index) else { throw FaceSheetError.cellOutOfRange(index: index, count: faces.count) }
        return faces[index]
    }

    // MARK: - Ops

    private func draw(_ op: DrawOp, on port: MapPort) throws {
        switch (op, port) {
        case (.statusBar(let state), .screen):
            let clut = screen.surface.clut
            if statusBar == nil || statusBarClut != clut {
                statusBar = try StatusBar(resources: screen.resources, screenClut: clut, search: screen.search,
                                          dither: screen.dither, text: screen.text)
                statusBarClut = clut
            }
            statusBar?.update(state, full: true, screen: &screen.surface.frame)
        case (_, .screen):
            try screen.apply([op])
        case (.drawFace(let set, let index, let h, let v), .work):
            Self.blit(try face(set, index), into: &work, x: h, y: v)
        case (.drawFace(let set, let index, let h, let v), .background):
            Self.blit(try face(set, index), into: &background, x: h, y: v)
        case (.drawLine(let h1, let v1, let h2, let v2, let rgb), .work):
            let index = screen.search.index(of: rgb, in: try clut())
            Self.stroke(h1: h1, v1: v1, h2: h2, v2: v2, index: index, into: &work)
        case (.copyPicture(let id, let chain, let source, let dest, let forceClut, let transparent), .background):
            let c = try forceClut.map { try ColorLUT.load(id: $0, from: screen.resources, chain: chain) } ?? clut()
            let picture = try ConvertedPicture(source: try PictureSource.load(id: id, from: screen.resources, chain: chain),
                                               clut: c, search: screen.search, dither: screen.dither)
            let rows = ScreenRenderer.sampleRows(source: source.height, dest: dest.height)
            let cols = ScreenRenderer.sampleRows(source: source.width, dest: dest.width)
            let white = c.entries.map { $0.red == 0xffff && $0.green == 0xffff && $0.blue == 0xffff }
            for (dy, sy) in rows.enumerated() {
                for (dx, sx) in cols.enumerated() {
                    let x = Int(dest.left) + dx, y = Int(dest.top) + dy
                    guard Port.contains(x, y) else { continue }
                    let p = picture.pixel(x: Int(source.left) + sx, y: Int(source.top) + sy)
                    if transparent && white[Int(p)] { continue }
                    background[x, y] = p
                }
            }
        default:
            throw Refusal.unexpected(String(describing: op).prefix { $0 != "(" }.description, port)
        }
    }

    private func clut() throws -> ColorLUT {
        if let portClut { return portClut }
        return screen.surface.clut
    }

    /// `.DrawLink` / `.DrawLinkScratch`: black centre, +1/+1, −1/−1, then the white centre.
    private func drawLink(_ l: MapLink, into port: inout Port) throws {
        let c = try clut()
        let prepared = screen.search.prepared(for: c)
        let black = prepared.index(of: RGB16(0, 0, 0))
        let white = prepared.index(of: RGB16(0xffff, 0xffff, 0xffff))
        for d in [0, 1, -1] {
            Self.stroke(h1: l.h1 + d, v1: l.v1 + d, h2: l.h2 + d, v2: l.v2 + d, index: black, into: &port)
        }
        Self.stroke(h1: l.h1, v1: l.v1, h2: l.h2, v2: l.v2, index: white, into: &port)
    }

    private func copy(from: MapPort, to: MapPort, source: Rect16, dest: Rect16) throws {
        let src: Port
        switch from {
        case .background: src = background
        case .work: src = work
        case .screen: throw Refusal.unexpected("copy", from)
        }
        let rows = ScreenRenderer.sampleRows(source: source.height, dest: dest.height)
        let cols = ScreenRenderer.sampleRows(source: source.width, dest: dest.width)
        func each(_ body: (Int, Int, UInt8) -> Void) {
            for (dy, sy) in rows.enumerated() {
                let syy = Int(source.top) + sy
                for (dx, sx) in cols.enumerated() {
                    let sxx = Int(source.left) + sx
                    guard Port.contains(sxx, syy) else { continue }
                    body(Int(dest.left) + dx, Int(dest.top) + dy, src[sxx, syy])
                }
            }
        }
        switch to {
        case .background:
            each { x, y, p in if Port.contains(x, y) { background[x, y] = p } }
        case .work:
            each { x, y, p in if Port.contains(x, y) { work[x, y] = p } }
        case .screen:
            let prepared = screen.search.prepared(for: screen.surface.clut)
            let translate = try clut().entries.map { prepared.index(of: RGB16($0.red, $0.green, $0.blue)) }
            let surface = screen.surface
            each { x, y, p in
                guard (0..<IndexedFrame.width).contains(x), (0..<IndexedFrame.height).contains(y) else { return }
                surface.frame[x, y] = translate[Int(p)]
            }
        }
    }

    // MARK: - Primitives

    /// `BlitEncFaceClipX(face, port, (0, 0), (x, y), face width, face height)`: the copy runs at QuickDraw
    /// (x + 8 + column, y + 8 + row), clipped to the blit rect (0…639, 0…415 in blit coordinates).
    static func blit(_ face: EncodedFace, into port: inout Port, x: Int, y: Int) {
        guard let tokens = try? face.tokens() else { return }
        var row = -1, col = 0
        for token in tokens {
            switch token {
            case .row:
                row += 1
                col = 0
            case .skip(let n):
                col += n
            case .copy(let bytes):
                let by = y + row
                if (0..<Port.blitHeight).contains(by) {
                    for (k, b) in bytes.enumerated() {
                        let bx = x + col + k
                        guard (0..<Port.blitWidth).contains(bx) else { continue }
                        port[bx + Port.slop, by + Port.slop] = b
                    }
                }
                col += bytes.count
            case .end:
                return
            }
        }
    }

    /// The pixels of a 1×1-pen QuickDraw line (h1, v1)→(h2, v2), both end points: Bresenham from the upper end point
    /// (lower v; on a tie the left one) [MED].
    public static func linePixels(h1: Int, v1: Int, h2: Int, v2: Int) -> [(x: Int, y: Int)] {
        let swap = v2 < v1 || (v2 == v1 && h2 < h1)
        let (x0, y0, x1, y1) = swap ? (h2, v2, h1, v1) : (h1, v1, h2, v2)
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx + dy, x = x0, y = y0
        var out: [(x: Int, y: Int)] = []
        while true {
            out.append((x, y))
            if x == x1 && y == y1 { return out }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
    }

    static func stroke(h1: Int, v1: Int, h2: Int, v2: Int, index: UInt8, into port: inout Port) {
        for p in linePixels(h1: h1, v1: v1, h2: h2, v2: v2) where Port.contains(p.x, p.y) {
            port[p.x, p.y] = index
        }
    }
}

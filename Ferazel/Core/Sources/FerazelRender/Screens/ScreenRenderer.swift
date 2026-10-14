import Foundation
import FerazelCore
import HectorResources

/// The level-less executor of the front-end `DrawOp`s (plan S4, FE0) onto the shared `ScreenSurface`:
/// - CLUTs resolve as the original's `GetCTable` does: along the resource chain open at the call. `copyPicture`'s
///   `forceClut` walks the op's `chain` (the chain its picture is fetched on); `setScreenClut` carries no chain, so it
///   walks `chain` (the renderer's open chain: `.frontEnd`, `.level` when a front-end screen is drawn mid-level, e.g.
///   `.Pause`'s `SetScreenClut(level clut)`).
/// - `setScreenClut(id)`: `.SetScreenClut` — the surface's CLUT (`GetCTable` along `chain`); the gamma stays.
/// - `drawPicture(id, chain, h, v)`: `.DrawPICTToBackScreen` + `.MTRedraw` — the PICT converted under the screen CLUT
///   (`ConvertedPicture`), then each index through `Color2Index` of its own colour (as `FrameRenderer`), at (h, v)
///   (a full-screen picture at (0, 0)), clipped to the screen.
/// - `copyPicture(id, chain, source, dest, forceClut, transparent)`: `CopyBits` from the picture's port (converted under
///   `forceClut` = `CopyBitsCTForce`, else under the screen CLUT) into `dest`, every source pixel copied by colour
///   (`Color2Index` in the screen CLUT); a size change stretches by nearest row / column, dest row y sampling source
///   row `y · srcH / dstH` [MED: QuickDraw's stretch sampling is ROM code]; `transparent` = mode 0x24: source pixels
///   whose colour is white are skipped (raw `10079870`) [MED].
/// - `fillRect`: `RGBForeColor` + `PaintRect` (right/bottom exclusive), the colour through `Color2Index`.
/// - `drawLine`: a 1-pixel QuickDraw line, pen 1×1, both end points drawn [MED: QuickDraw's line rasterisation is ROM
///   code; Bresenham].
/// - `drawText(run)`: the injected `TextRasterizer`'s mask at the pen (`run.h`, `run.v`), srcOr: only glyph pixels
///   change, to `Color2Index(run.rgb)`.
/// - `screenGamma(op)`: `.tint` → `ScreenGamma.tintFade` (the unfaded gamma scaled, `.TintFadeProc`); `.fadeToColor` →
///   `ScreenGamma.fade` (compounding); `.timedFadeToColor` → the gamma captured at its tick 0 moved the tick's absolute
///   fraction (`ScreenSurface.timedFadeStart`, non-compounding); `.identity` → the original gamma; `.clut` (`.TurnGray`) // later: D1.
/// - `gammaStep`: one `.HandleAsyncGammaFade` step (`ScreenGamma.step`).
/// - `drawFace` // later: M2; `restoreView` // later: C2 — accepted as no-ops.
/// - The level ops (grid, lights, sprites, copy, erase, status bar, tiles, water, particles) are `FrameRenderer`'s:
///   `Refusal.levelOp`.
public final class ScreenRenderer {

    public enum Refusal: Error, Equatable {
        /// A level op given to the level-less renderer (the op's name).
        case levelOp(String)
    }

    public let surface: ScreenSurface
    public let resources: FerazelResources
    public let search: ColorSearch
    public let dither: DitherModel
    public let text: any TextRasterizer
    /// The resource chain open (`CurResFile`'s chain) for the ops that carry none (`setScreenClut`).
    public var chain: ResourceChain

    public init(surface: ScreenSurface, resources: FerazelResources, search: ColorSearch,
                dither: DitherModel = .errorDiffusion, text: any TextRasterizer, chain: ResourceChain = .frontEnd) {
        self.chain = chain
        self.surface = surface
        self.resources = resources
        self.search = search
        self.dither = dither
        self.text = text
    }

    /// Executes the ops in order on `surface`.
    /// - Throws: `Refusal.levelOp`, `ColorLUTError` / `PictureSourceError` for a missing CLUT or picture.
    public func apply(_ ops: [DrawOp]) throws {
        for op in ops {
            switch op {
            case .setScreenClut(let id):
                surface.clut = try ColorLUT.load(id: id, from: resources, chain: chain)
            case .drawPicture(let id, let chain, let h, let v):
                let picture = try ConvertedPicture(source: try PictureSource.load(id: id, from: resources, chain: chain),
                                                   clut: surface.clut, search: search, dither: dither)
                copyBits(picture, clut: surface.clut,
                         source: Rect16(top: 0, left: 0, bottom: Int16(picture.height), right: Int16(picture.width)),
                         dest: Rect16(top: Int16(v), left: Int16(h), bottom: Int16(v + picture.height),
                                      right: Int16(h + picture.width)),
                         transparent: false)
            case .copyPicture(let id, let chain, let source, let dest, let forceClut, let transparent):
                let clut = try forceClut.map { try ColorLUT.load(id: $0, from: resources, chain: chain) } ?? surface.clut
                let picture = try ConvertedPicture(source: try PictureSource.load(id: id, from: resources, chain: chain),
                                                   clut: clut, search: search, dither: dither)
                copyBits(picture, clut: clut, source: source, dest: dest, transparent: transparent)
            case .fillRect(let left, let top, let right, let bottom, let rgb):
                fillRect(left: left, top: top, right: right, bottom: bottom, index: search.index(of: rgb, in: surface.clut))
            case .drawLine(let h1, let v1, let h2, let v2, let rgb):
                drawLine(h1: h1, v1: v1, h2: h2, v2: v2, index: search.index(of: rgb, in: surface.clut))
            case .drawText(let run):
                drawText(run)
            case .screenGamma(let g):
                if case .timedFadeToColor(let tick, let ms, let rgb) = g {
                    if tick == 0 || surface.timedFadeStart == nil { surface.timedFadeStart = surface.gamma }
                    var next = surface.timedFadeStart ?? surface.gamma
                    next.fade(toward: rgb, fraction: ScreenGamma.timedFraction(tick: tick, milliseconds: ms))
                    surface.gamma = next
                    break
                }
                surface.timedFadeStart = nil
                switch g {
                case .tint(let mode, let percent): surface.gamma = .tintFade(mode: mode, percent: percent)
                case .fadeToColor(let percent, let rgb): surface.gamma.fade(toward: rgb, percent: percent)
                case .timedFadeToColor: break   // handled above
                case .identity: surface.gamma = .identity
                case .clut: break   // later: D1 (`.TurnGray`'s SetEntries)
                }
            case .gammaStep(let numerator, let denominator, let toward):
                surface.timedFadeStart = nil
                surface.gamma.step(numerator: numerator, denominator: denominator, toward: toward)
            case .drawFace:
                break   // later: M2 (the map's node / marker / boss / ambient faces)
            case .restoreView:
                break   // later: C2 (`.WrapCopyToScreen` of the last drawn level frame)
            case .redrawScrollGrid: throw Refusal.levelOp("redrawScrollGrid")
            case .redrawEntireScrollGrid: throw Refusal.levelOp("redrawEntireScrollGrid")
            case .drawLightsOntoTiles: throw Refusal.levelOp("drawLightsOntoTiles")
            case .wrapDrawSprites: throw Refusal.levelOp("wrapDrawSprites")
            case .copyToScreen: throw Refusal.levelOp("copyToScreen")
            case .changeLightFace: throw Refusal.levelOp("changeLightFace")
            case .wrapEraseSprites: throw Refusal.levelOp("wrapEraseSprites")
            case .statusBar: throw Refusal.levelOp("statusBar")
            case .setTile: throw Refusal.levelOp("setTile")
            case .wrapDrawWaterEffects: throw Refusal.levelOp("wrapDrawWaterEffects")
            case .drawParticles: throw Refusal.levelOp("drawParticles")
            case .eraseParticles: throw Refusal.levelOp("eraseParticles")
            }
        }
    }

    /// The source row (or column) each of `dest` destination rows samples in a `CopyBits` stretch from `source` rows:
    /// `y · source / dest` (nearest, top-anchored) [MED]. Equal sizes → the identity.
    public static func sampleRows(source: Int, dest: Int) -> [Int] {
        guard dest > 0 else { return [] }
        return (0..<dest).map { $0 * source / dest }
    }

    /// `CopyBits(picture port, screen, source, dest, mode)`: `picture` holds indices under `clut`; each pixel goes to the
    /// screen as `Color2Index` of its colour in the screen CLUT; nearest-row/column stretch; `transparent` (mode 0x24)
    /// skips white source pixels. Pixels outside the picture read 0 (`ConvertedPicture.pixel`); dest is clipped to the
    /// screen.
    public func copyBits(_ picture: ConvertedPicture, clut: ColorLUT, source: Rect16, dest: Rect16, transparent: Bool) {
        let prepared = search.prepared(for: surface.clut)
        let translate = clut.entries.map { prepared.index(of: RGB16($0.red, $0.green, $0.blue)) }
        let white = clut.entries.map { $0.red == 0xffff && $0.green == 0xffff && $0.blue == 0xffff }
        let rows = Self.sampleRows(source: source.height, dest: dest.height)
        let cols = Self.sampleRows(source: source.width, dest: dest.width)
        for (dy, sy) in rows.enumerated() {
            let y = Int(dest.top) + dy
            guard (0..<IndexedFrame.height).contains(y) else { continue }
            for (dx, sx) in cols.enumerated() {
                let x = Int(dest.left) + dx
                guard (0..<IndexedFrame.width).contains(x) else { continue }
                let p = Int(picture.pixel(x: Int(source.left) + sx, y: Int(source.top) + sy))
                if transparent && white[p] { continue }
                surface.frame[x, y] = translate[p]
            }
        }
    }

    private func fillRect(left: Int, top: Int, right: Int, bottom: Int, index: UInt8) {
        let x0 = max(0, left), x1 = min(IndexedFrame.width, right)
        let y0 = max(0, top), y1 = min(IndexedFrame.height, bottom)
        guard x0 < x1, y0 < y1 else { return }
        for y in y0..<y1 { for x in x0..<x1 { surface.frame[x, y] = index } }
    }

    private func plot(_ x: Int, _ y: Int, _ index: UInt8) {
        guard (0..<IndexedFrame.width).contains(x), (0..<IndexedFrame.height).contains(y) else { return }
        surface.frame[x, y] = index
    }

    private func drawLine(h1: Int, v1: Int, h2: Int, v2: Int, index: UInt8) {
        let dx = abs(h2 - h1), dy = -abs(v2 - v1)
        let sx = h1 < h2 ? 1 : -1, sy = v1 < v2 ? 1 : -1
        var err = dx + dy, x = h1, y = v1
        while true {
            plot(x, y, index)
            if x == h2 && y == v2 { break }
            let e2 = 2 * err
            if e2 >= dy { err += dy; x += sx }
            if e2 <= dx { err += dx; y += sy }
        }
    }

    /// srcOr only: the binary imports no `TextMode` (0 hits in `ghidra/ferazel/` main, handlers and disasm), so every
    /// `DrawString` (e.g. M l. 3351, 4589, 4666) draws in the port's default `txMode` srcOr — the only mode `TextRun`
    /// defines; `run.mode` is therefore not consulted.
    private func drawText(_ run: TextRun) {
        let mask = text.rasterize(MacRoman.decode(run.bytes), font: run.font, size: run.size, face: run.face)
        let index = search.index(of: run.rgb, in: surface.clut)
        for y in 0..<mask.height {
            for x in 0..<mask.width where mask.bits[y * mask.width + x] {
                plot(run.h + mask.left + x, run.v + mask.top + y, index)
            }
        }
    }
}

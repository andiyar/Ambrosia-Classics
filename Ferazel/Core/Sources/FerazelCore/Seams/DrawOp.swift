import Foundation

/// One draw call of the original, at its call site, in `.PaintFrameWrap @ 10011cf8` order (plan S3, LOCKED;
/// engine §3 "Draw order per frame", rendering-omnipx-titles §1.1).
public enum DrawOp: Equatable, Sendable {
    /// `.SetupLevel` → `.SetScreenClut(level+base)` (lighting-tables §1.2).
    case setScreenClut(id: Int16)
    /// PICT 129 'Game Screen' at level start.
    case drawPicture(id: Int16, chain: ResourceChain, h: Int, v: Int)
    /// `.SetScrollLocation` → `.RedrawScrollGrid` (the tile layer).
    case redrawScrollGrid(h: Int, v: Int)
    /// `.RedrawEntireScrollGrid @ 10013fd0`: the whole cell window (level start, `.GameLoop` l. 5211; full redraws,
    /// e.g. decompile l. 3265, 3914, 6259).
    case redrawEntireScrollGrid(h: Int, v: Int)
    /// `.DrawLightsOntoTiles`; the caller skips it when prefs+6 (Effects) == 3.
    case drawLightsOntoTiles
    /// `.WrapDrawSprites`, active-list order (draw-effects §1.1).
    case wrapDrawSprites([SpriteDraw])
    /// `.WrapCopyToScreen` (rendering-omnipx-titles §1.1).
    case copyToScreen(h: Int, v: Int, graphicsMode: Int, backdrop: Bool)
    /// `.ChangeLightFace @ 1001bdbc` from a sprite Handle (`.HandleSprites`, after `.WrapDrawSprites` and before
    /// `.WrapEraseSprites`): light slot `slot` (0…199) gets the light face `.Load1LightFaceFromPICT(pict, width,
    /// height)` and radius width / 2. Phase 1: the item twinkle (`BonusHandle`).
    case changeLightFace(slot: Int, pict: Int16, width: Int, height: Int)
    /// `.WrapEraseSprites @ 10014a58` (`.PaintFrameWrap` l. 9456, drawn frame or not): the dirty-rect restore over the
    /// active list after the sprite Handles, at scroll (h, v); each sprite carries its last-frame copies.
    case wrapEraseSprites(sprites: [SpriteSlot], h: Int, v: Int)
    /// `.UpdateStatusBar(1, 0, 0)`.
    case statusBar(StatusBarState)
    /// One `.HandleAsyncGammaFade @ 10035788` step of `.GammaFadeOutAsync(N, rgb)` / `.GammaFadeInAsync(N)`
    /// (lighting-tables §10): `MT_FadeToColor(toward, numerator·100 / denominator, 0, 1)` — the current gamma moved
    /// that percentage toward `toward` (nil = the original gamma, the fade-in), compounding. Presentation only.
    case gammaStep(numerator: Int, denominator: Int, toward: RGB16? = nil)
    /// A map write of `.CrunchTile`'s machinery (plan S3, P2) at its call site in the sprite Handles: the FG cell
    /// (col, row) — already clamped as `.ConstrainXY` — now holds `fg` (the whole u16: tile + 1 in bits 0–7, crunch
    /// kind 8–11, crunch direction 12–15). Emitted for `.ChangeFGTile` (`.SetFGTile` + `.ChangedTile`, the one-cell
    /// `.RedrawScrollGrid`) and for `.SetFGCrunchDirTile` (no redraw in the original; the renderer's redraw of an
    /// unchanged tile byte paints the same cell). The renderer applies it to its copy of the level and redraws the cell.
    case setTile(col: Int, row: Int, fg: UInt16)
    /// `.WrapDrawWaterEffects(odd) @ 10010fac` (`.PaintFrameWrap` l. 9206, after `.HandleLights` and before
    /// `.WrapDrawSprites`), every iteration, drawn or not (E1a adds the case with an empty list; E1b fills it).
    case wrapDrawWaterEffects([WaterFaceDraw])
    /// `.DrawParticles @ 10031aa4` (l. 9433), drawn iterations only, before `.UpdateOmniPx`, the parity flip and
    /// `.WrapCopyToScreen`: the records Core left alive after its colour-0 kills, in pool order (possibly empty).
    case drawParticles([ParticleDraw])
    /// `.EraseParticles @ 10031d6c` (l. 9449), drawn iterations only, right after `.WrapCopyToScreen`: what the last
    /// `drawParticles` drew is restored from the tile port by each record's erase mode `+0x1d`.
    case eraseParticles

    // MARK: Front end (Phase 3, FE0 — every case added up front; FerazelRender.ScreenRenderer executes them)

    /// `RGBForeColor(rgb)` + `PaintRect` (right and bottom exclusive): the colour through `Color2Index` in the screen
    /// CLUT.
    case fillRect(left: Int, top: Int, right: Int, bottom: Int, rgb: RGB16)
    /// `CopyBits` of PICT `id`'s `source` rect into the screen's `dest` rect (stretched when the sizes differ);
    /// `forceClut` = `CopyBitsCTForce` (the picture converted under that CLUT, then copied by colour into the screen
    /// CLUT); `transparent` = transfer mode 0x24 (white source pixels skipped, raw `10079870`).
    case copyPicture(id: Int16, chain: ResourceChain, source: Rect16, dest: Rect16, forceClut: Int16?,
                     transparent: Bool)
    /// A world-map face (node / marker / boss / ambient) centred per the slop-8 port (M2).
    case drawFace(set: FrontFaceSet, index: Int, h: Int, v: Int)
    /// A 1-pixel QuickDraw line (pen 1×1) from (h1, v1) to (h2, v2) in `rgb` (map links, M2).
    case drawLine(h1: Int, v1: Int, h2: Int, v2: Int, rgb: RGB16)
    /// `DrawString` / `DrawText` (`TextRun`).
    case drawText(TextRun)
    /// `.WrapCopyToScreen` of the last drawn level frame (C2).
    case restoreView
    /// A Monitor-Tool gamma change (`ScreenGammaOp`): tint-fade percent, `FadeToColor` percent, identity, a CLUT.
    case screenGamma(ScreenGammaOp)
}

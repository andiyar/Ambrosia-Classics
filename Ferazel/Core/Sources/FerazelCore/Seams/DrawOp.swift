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
    /// `.DrawLightsOntoTiles`; the caller skips it when prefs+6 (Effects) == 3.
    case drawLightsOntoTiles
    /// `.WrapDrawSprites`, active-list order (draw-effects §1.1).
    case wrapDrawSprites([SpriteDraw])
    /// `.WrapCopyToScreen` (rendering-omnipx-titles §1.1).
    case copyToScreen(h: Int, v: Int, graphicsMode: Int, backdrop: Bool)
    /// `.UpdateStatusBar(1, 0, 0)`.
    case statusBar(StatusBarState)
}

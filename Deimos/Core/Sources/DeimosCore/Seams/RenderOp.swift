import Foundation

/// The game's persistent pixel buffers (display-window-present; engine-loop §5). ★ LOCKED seam (plan S3).
public enum BufferID: Sendable {
    /// `D+0x68`, the 640×480 back buffer.
    case back
    /// `D+0x6c`, the level map.
    case terrain
    /// `D+0x70`, the 160×480 score-bar save buffer.
    case scoreSave
}

/// The three ways the back buffer reaches the screen. ★ LOCKED seam (plan S3).
public enum PresentKind: Sendable {
    /// `FUN_1000beb0`: borders black, game area → x 32..447, score bar → 448..607.
    case gameScreen
    /// `FUN_1000bd80`.
    case gameLayout
    /// `FUN_1000bc60`.
    case fullScreen
}

/// The blocking fades. ★ LOCKED seam (plan S3).
public enum FadeKind: Sendable {
    /// `FUN_1000ba70`, 9 steps.
    case fromBlack
    /// `FUN_1000b9a0`, 33 steps.
    case toBlack
}

/// One original draw-side call, recorded by Core at its call site, in pass order; DeimosRender executes it
/// on persistent buffers (`.fade` and `.limit` are host waits). ★ LOCKED seam (plan S3) — cases may be added,
/// never renamed.
public enum RenderOp: Equatable, Sendable {
    /// `FUN_1000fbc0`: terrain buffer ← the level's im16 map, resized.
    case loadTerrain(image: FourCC)
    /// `FUN_10009f00`: PaintRect over the buffer's portRect (level start: back ← 0, `1000690c`).
    case fill(BufferID, colour: UInt16)
    /// `FUN_10031400` (`'scor'`): an im16 image into a buffer at `dst`.
    case loadImage(image: FourCC, into: BufferID, dst: MacRect)
    /// `FUN_10009fd0`: CopyBits between buffers (nil rect = the whole portRect).
    case copy(from: BufferID, to: BufferID, src: MacRect?, dst: MacRect?, interlaced: Bool)
    /// `FUN_10019570` (draw now) or the layer queue `FUN_1001a450`.
    case draw(DrawCommand)
    /// `FUN_100189f0`.
    case clearLayers
    /// `FUN_10018b20`: layers 0...1, 2...5, 6...15.
    case flushLayers(ClosedRange<Int>)
    /// `FUN_1000bbd0`: back buffer → screen (HUD dirty rects).
    case screenBlit(src: MacRect, dst: MacRect)
    /// Blocking; the host steps it.
    case fade(FadeKind, PresentKind)
    /// The FPS limiter point (the host waits).
    case limit
    /// The end-frame present.
    case present(PresentKind)
}

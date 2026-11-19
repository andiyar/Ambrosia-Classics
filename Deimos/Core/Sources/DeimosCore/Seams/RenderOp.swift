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
/// on persistent buffers (`.fade`, `.limit`, `.pauseWait` and `.hostWait` are host waits). ★ LOCKED seam (plan S3) —
/// cases may be added, never renamed.
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
    /// `FUN_10043ba0` at `10030cd0`: the pass's particle stamps, written into the back buffer between flush
    /// 2…5 and flush 6…15 (particles-debris-blur §2.9). Phase 2 (plan S3).
    case particles([ParticleStamp])
    /// `FUN_10030870` → `FUN_10022ef0`: blocking; the host waits for Caps Lock up, then presents. Phase 2 (plan S3).
    case pauseWait(PresentKind)
    /// A front-end wait (`FrontEndWaits.swift`): blocking in the original; the host holds the op stream there and
    /// queues every input that arrives meanwhile. Phase 4 (plan S1a).
    case hostWait(HostWait)
    /// `FUN_10044c30` / a DITL picture item: `DrawPicture` of the app's resource-fork PICT `id` into the buffer,
    /// its top-left at (`left`, `top`), at its own size, clipped to the buffer. The shell decodes the PICT and hands
    /// it to Core as a plain image (ruling 9, `DeimosAssets.shellPictures`); a picture the shell did not supply
    /// draws nothing (`GetPicture` nil → the error log, `10044c5c`, no draw). Phase 4 (plan S1a).
    case drawPicture(id: Int16, into: BufferID, top: Int32, left: Int32)
    /// `FUN_1001d1b0` — the opaque scaled copy (the level select's middle preview while its flash scale ≠ 1,
    /// `1002f9f8..1002fb80`): the WHOLE `image` (an `im16`, the preview; its width and height are the source size)
    /// point-sampled into `dst` of the buffer, written only inside `clip` (the caller passes the unscaled preview
    /// rect). Per destination pixel x ∈ [left, right), y ∈ [top, bottom) with clip.left ≤ x < clip.right and
    /// clip.top ≤ y < clip.bottom: source x = srcW·(x − left) / (right − left), y = srcH·(y − top) / (bottom − top),
    /// integer division truncating (`divw`); the 16-bit pixel is copied as is (`lhzx` / `sthx`). Phase 4.
    case scaledCopy(image: FourCC, into: BufferID, dst: MacRect, clip: MacRect)

    /// The ops the host steps itself (`DeimosRenderer.apply` traps on them): `.fade`, `.limit`, `.pauseWait`,
    /// `.hostWait`.
    public static func isHostOp(_ op: RenderOp) -> Bool {
        switch op {
        case .fade, .limit, .pauseWait, .hostWait: return true
        default: return false
        }
    }
}

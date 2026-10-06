import Foundation
import DeimosCore

/// QuickDraw `CopyBits(…, srcCopy, maskRgn NULL)` between 16-bit buffers, and the game's two wrappers
/// (display-window-present §2.1).
///
/// Scope: only equal-size source and destination rects (every Phase-1 caller; the original never asks for a
/// stretch on these paths as far as the bank reads). A size mismatch is a precondition failure rather than a
/// guessed QuickDraw stretch. Clipping: the dst rect is intersected with the dst bounds (the port's portRect) and the
/// src rect with the src bounds, each trimming the other by the same offset — pixels with no source or no
/// destination are left alone.
public enum CopyBits {

    /// `FUN_10009fd0(src, dst, srcRect*, dstRect*, interlaced)` (listing `10009fd0…1000a184`):
    /// - `srcRect` nil → the **src** bounds (`1000a02c`);
    /// - `dstRect` nil → **also the src bounds** (`1000a0a0`) — the dst's own bounds are never consulted;
    /// - not interlaced: the original issues two identical `CopyBits(srcCopy)` (`1000a12c`, `1000a14c`). The second
    ///   rewrites the same pixels with the same values (src and dst are distinct buffers — Swift exclusivity
    ///   guarantees it here), so it is a no-op and is performed once;
    /// - interlaced: one `FUN_100450e0` with the src buffer's parity word (`+0x2c`), which it toggles.
    public static func copyBuffer(from src: inout Pixmap555, to dst: inout Pixmap555,
                                  srcRect: MacRect?, dstRect: MacRect?, interlaced: Bool) {
        let sr = srcRect ?? src.bounds
        let dr = dstRect ?? src.bounds
        if interlaced {
            copyInterlaced(from: src, to: &dst, srcRect: sr, dstRect: dr, parity: &src.interlaceParity)
        } else {
            copy(from: src, to: &dst, srcRect: sr, dstRect: dr)
        }
    }

    /// One `CopyBits(srcCopy)`, equal-size rects, clipped as described on the type.
    public static func copy(from src: Pixmap555, to dst: inout Pixmap555, srcRect: MacRect, dstRect: MacRect) {
        checkSameSize(srcRect, dstRect)
        let h = Int(srcRect.rectHeight)
        for k in 0..<max(h, 0) {
            copyRow(from: src, to: &dst, srcY: Int(srcRect.top) + k, dstY: Int(dstRect.top) + k,
                    srcLeft: Int(srcRect.left), dstLeft: Int(dstRect.left), width: Int(srcRect.rectWidth))
        }
    }

    /// `FUN_100450e0(srcBits, dstBits, srcRect*, dstRect*, &parity)` (listing `100450e0…100455f4`; the bank row is
    /// MED, the arithmetic re-read for R1): both bitmaps get doubled rowBytes and halved rects/bounds; on odd parity
    /// both base addresses advance one row (`10045424`, `1004542c`) and an odd rect height is trimmed by one
    /// (`10045444`, `10045460`), on even parity it is padded by one (`10045480`, `1004549c`); a rect top at an odd
    /// row relative to the bounds steps the base back a row (`100454c8…100454f4`). The net effect, for each rect:
    /// rows `top + p, top + p + 2, …` (p = parity & 1) below `bottom`, src row k paired with dst row k. One
    /// `CopyBits(srcCopy)`, then `parity ^= 1` (`100455e8…100455f4`).
    public static func copyInterlaced(from src: Pixmap555, to dst: inout Pixmap555,
                                      srcRect: MacRect, dstRect: MacRect, parity: inout UInt32) {
        checkSameSize(srcRect, dstRect)
        let p = Int(parity & 1)
        let h = Int(srcRect.rectHeight)
        var k = p
        while k < h {
            copyRow(from: src, to: &dst, srcY: Int(srcRect.top) + k, dstY: Int(dstRect.top) + k,
                    srcLeft: Int(srcRect.left), dstLeft: Int(dstRect.left), width: Int(srcRect.rectWidth))
            k += 2
        }
        parity ^= 1
    }

    private static func checkSameSize(_ s: MacRect, _ d: MacRect) {
        precondition(s.rectWidth == d.rectWidth && s.rectHeight == d.rectHeight,
                     "CopyBits: stretching (src \(s) → dst \(d)) is not replicated")
    }

    @inline(__always)
    private static func copyRow(from src: Pixmap555, to dst: inout Pixmap555, srcY: Int, dstY: Int,
                                srcLeft: Int, dstLeft: Int, width: Int) {
        guard srcY >= 0, srcY < src.height, dstY >= 0, dstY < dst.height, width > 0 else { return }
        // Columns valid in both: i with 0 ≤ srcLeft + i < src.width and 0 ≤ dstLeft + i < dst.width.
        let lo = max(0, -srcLeft, -dstLeft)
        let hi = min(width, src.width - srcLeft, dst.width - dstLeft)
        guard hi > lo else { return }
        let sBase = srcY * src.width + srcLeft
        let dBase = dstY * dst.width + dstLeft
        for i in lo..<hi { dst.pixels[dBase + i] = src.pixels[sBase + i] }
    }
}

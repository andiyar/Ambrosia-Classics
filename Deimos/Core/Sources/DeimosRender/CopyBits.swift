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
        let width = Int(srcRect.rectWidth), srcLeft = Int(srcRect.left), dstLeft = Int(dstRect.left)
        withRows(src, &dst) { s, d in
            for k in 0..<max(h, 0) {
                copyRow(s, d, srcY: Int(srcRect.top) + k, dstY: Int(dstRect.top) + k,
                        srcLeft: srcLeft, dstLeft: dstLeft, width: width)
            }
        }
    }

    /// `FUN_100450e0(srcBits, dstBits, srcRect*, dstRect*, &parity)` (listing `100450e0…100455f4`), transcribed
    /// for each bitmap/rect pair:
    /// 1. bounds top and bottom − 2, base − 2·rowBytes (`10045374…10045410`; the pair addresses the same rows);
    /// 2. odd parity: base + rowBytes (`10045424`, `1004542c`), an odd rect height trimmed by one (`10045444`,
    ///    `10045460`); even parity: an odd rect height padded by one (`10045480`, `1004549c`);
    /// 3. `(rect.top − bounds.top) & 1` set: base − rowBytes (`100454b8…100454f4`);
    /// 4. rowBytes doubled; bounds top/bottom `>> 1`; rect top/bottom = `((r − bounds.top) >> 1) + (bounds.top >> 1)
    ///    + (step 3's bit)` (`100454f8…100455dc`, `srawi` = floor);
    /// 5. one `CopyBits(srcCopy)` of the halved rects (`100455e0`), clipped to the halved bounds; `parity ^= 1`
    ///    (`100455e8…100455f4`).
    /// The halved row Y addresses original row `2Y + parity − (rect.top & 1)` (bounds top 0). The rect rows come out
    /// as `top + p, top + p + 2, …` below `bottom` (p = parity & 1), src row k paired with dst row k — but the halved
    /// bounds are those of the −2-shifted bitmap: a 480-row buffer halves to [−1, 239) while its full rect halves to
    /// [0, 240), so the last field row (478 even, 479 odd) is clipped. Replicated as the original computes it.
    public static func copyInterlaced(from src: Pixmap555, to dst: inout Pixmap555,
                                      srcRect: MacRect, dstRect: MacRect, parity: inout UInt32) {
        checkSameSize(srcRect, dstRect)
        let p = Int(parity & 1)
        let sf = Field(rect: srcRect, height: src.height, parity: p)
        let df = Field(rect: dstRect, height: dst.height, parity: p)
        let width = Int(srcRect.rectWidth), srcLeft = Int(srcRect.left), dstLeft = Int(dstRect.left)
        withRows(src, &dst) { s, d in
            // Equal rect heights (checked) made even by step 2 halve to equal field heights.
            for k in 0..<max(sf.y1 - sf.y0, 0) {
                let ys = sf.y0 + k, yd = df.y0 + k
                guard ys >= sf.boundsTop, ys < sf.boundsBottom, yd >= df.boundsTop, yd < df.boundsBottom else { continue }
                copyRow(s, d, srcY: sf.row(ys), dstY: df.row(yd), srcLeft: srcLeft, dstLeft: dstLeft, width: width)
            }
        }
        parity ^= 1
    }

    /// One bitmap + rect after `FUN_100450e0`'s field transform (steps 1–4 above), vertical only (columns are
    /// untouched). Buffers have bounds top 0.
    struct Field {
        /// The halved bounds.
        let boundsTop: Int, boundsBottom: Int
        /// The halved rect.
        let y0: Int, y1: Int
        /// The original row of halved row `boundsTop`.
        let firstRow: Int

        init(rect: MacRect, height: Int, parity p: Int) {
            let bt = 0 - 2, bb = height - 2                              // step 1
            let top = Int(rect.top)
            var bottom = Int(rect.bottom)
            if (bottom - top) & 1 != 0 { bottom += p == 1 ? -1 : 1 }     // step 2
            let odd = (top - bt) & 1                                     // step 3
            boundsTop = bt >> 1
            boundsBottom = bb >> 1
            y0 = ((top - bt) >> 1) + boundsTop + odd                     // step 4
            y1 = ((bottom - bt) >> 1) + boundsTop + odd
            firstRow = bt + p - odd                                      // base − 2·rb + p·rb − odd·rb
        }

        /// Halved row Y → original row (doubled rowBytes from `firstRow`).
        func row(_ y: Int) -> Int { firstRow + 2 * (y - boundsTop) }
    }

    private static func checkSameSize(_ s: MacRect, _ d: MacRect) {
        precondition(s.rectWidth == d.rectWidth && s.rectHeight == d.rectHeight,
                     "CopyBits: stretching (src \(s) → dst \(d)) is not replicated")
    }

    /// The two buffers' pixels for a run of `copyRow`s (src read-only; dst is unique once mutably accessed).
    private struct Rows {
        let base: UnsafePointer<UInt16>?
        let width: Int, height: Int
    }
    private struct MutableRows {
        let base: UnsafeMutablePointer<UInt16>?
        let width: Int, height: Int
    }

    @inline(__always)
    private static func withRows(_ src: Pixmap555, _ dst: inout Pixmap555, _ body: (Rows, MutableRows) -> Void) {
        let (sw, sh, dw, dh) = (src.width, src.height, dst.width, dst.height)
        src.pixels.withUnsafeBufferPointer { s in
            dst.pixels.withUnsafeMutableBufferPointer { d in
                body(Rows(base: s.baseAddress, width: sw, height: sh),
                     MutableRows(base: d.baseAddress, width: dw, height: dh))
            }
        }
    }

    /// One row of a `srcCopy`: the columns valid in both buffers, as one block copy.
    @inline(__always)
    private static func copyRow(_ src: Rows, _ dst: MutableRows, srcY: Int, dstY: Int,
                                srcLeft: Int, dstLeft: Int, width: Int) {
        guard srcY >= 0, srcY < src.height, dstY >= 0, dstY < dst.height, width > 0,
              let s = src.base, let d = dst.base else { return }
        // Columns valid in both: i with 0 ≤ srcLeft + i < src.width and 0 ≤ dstLeft + i < dst.width.
        let lo = max(0, -srcLeft, -dstLeft)
        let hi = min(width, src.width - srcLeft, dst.width - dstLeft)
        guard hi > lo else { return }
        (d + dstY * dst.width + dstLeft + lo).update(from: s + srcY * src.width + srcLeft + lo, count: hi - lo)
    }
}

extension DisplayBuffers {
    /// `FUN_10009fd0` between two buffers of this display (R3's `.terrain` → `.back` and the like). The src is taken
    /// as a copy (copy-on-write: its pixels are shared, not duplicated), so the copy never holds two overlapping
    /// `inout` accesses into `self` — which would trip dynamic exclusivity when `self` lives in a class — and the
    /// toggled interlace parity is written back to the src buffer afterwards. `src == dst` copies from the
    /// pre-copy pixels (QuickDraw's overlapping `CopyBits` moves correctly).
    public mutating func copyBuffer(from srcID: BufferID, to dstID: BufferID, srcRect: MacRect?, dstRect: MacRect?,
                                    interlaced: Bool) {
        var src = buffer(srcID)
        switch dstID {
        case .back:
            CopyBits.copyBuffer(from: &src, to: &back, srcRect: srcRect, dstRect: dstRect, interlaced: interlaced)
        case .terrain:
            CopyBits.copyBuffer(from: &src, to: &terrain, srcRect: srcRect, dstRect: dstRect, interlaced: interlaced)
        case .scoreSave:
            CopyBits.copyBuffer(from: &src, to: &scoreSave, srcRect: srcRect, dstRect: dstRect, interlaced: interlaced)
        }
        switch srcID {
        case .back: back.interlaceParity = src.interlaceParity
        case .terrain: terrain.interlaceParity = src.interlaceParity
        case .scoreSave: scoreSave.interlaceParity = src.interlaceParity
        }
    }
}

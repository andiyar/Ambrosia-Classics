import Foundation
import DeimosCore

/// The game's one blend kernel (blit-pixel-rules §2; `FUN_1001e9d0`, loose-ends-session §6).
///
/// `out_c = ⌊(A_c·a + B_c·(32 − a))/32⌋` per 5-bit channel — a floor, no rounding term. The listing packs R|B with
/// `andi. 0x7c1f` and moves G to bits 20–24 (`rlwimi …,0xf,0x7,0xb`), so all three fields share one `mullw`; each
/// field is 10 bits wide and a sum is at most 31·32 = 992, so nothing carries between fields. Unpacked with
/// `>> 5`, `andi. 0x7c1f`, and G back from bits 25–29 (`rlwimi …,0xc,0x16,0x1a`). Bit 15 of either input is
/// dropped; the output's bit 15 is 0 (listing `1001eb80…1001ebb4`).
public enum Blend555 {
    /// One pixel: A weighted by `a`, B by `32 − a`. Every shipped `a` is in 0…32; any other value (reachable
    /// through a command's 32-bit alpha) follows the original's 32-bit word arithmetic: `subfic r4,a,0x20` and both
    /// `mullw` wrap mod 2³², the unpack is the same shift-and-mask (`1001eb84…1001ebb0`, `1001edc8…1001edf0`) — so a
    /// weight outside 0…32 is reproduced by wrapping, never trapping.
    @inline(__always)
    public static func blend(_ pa: UInt16, _ pb: UInt16, a: Int) -> UInt16 {
        let wa = UInt32(truncatingIfNeeded: a), wb = UInt32(truncatingIfNeeded: 32 &- a)
        let ua = UInt32(pa), ub = UInt32(pb)
        let packedA = (ua & 0x7c1f) | ((ua & 0x03e0) << 15)
        let packedB = (ub & 0x7c1f) | ((ub & 0x03e0) << 15)
        let sum = packedA &* wa &+ packedB &* wb
        return UInt16(((sum >> 5) & 0x7c1f) | ((sum >> 20) & 0x03e0))
    }

    /// `FUN_1001e9d0(srcA, srcB, dst, rect, a)`: `dst = blend(A, B, a)`. The rect is rejected when it lies wholly
    /// outside the dst bounds (`1001ea04…1001ea40`); w × h is the rect clipped to them (`1001ea44…1001ea8c`), an
    /// empty one draws nothing (`1001ea9c…1001eab0`). ⚑ All three buffers are then addressed from the UNCLIPPED
    /// top/left — `base + rect.top·rowBytes + 2·rect.left` (`1001eac8/ead8`, `1001eb0c/eb14`, `1001eb44/eb48`) —
    /// each stepping its own `rowBytes − 2w` per row (`1001ec54…1001ec5c`), the same quirk as `FUN_1001ec80`
    /// (CostRect.swift). For a rect inside the dst (every shipped caller: the fade passes `&back.bounds` and clones
    /// of the back buffer) this is the clipped rect; one starting left of / above the dst lands earlier in linear
    /// memory. The replica walks the same linear indices (rowBytes = 2·width) and drops a pixel when any of the three
    /// falls outside its buffer (the original would read/write outside it).
    public static func blend(_ srcA: Pixmap555, _ srcB: Pixmap555, into dst: inout Pixmap555, rect: MacRect, a: Int) {
        let b = dst.bounds
        if rect.left > b.right || rect.right < b.left || rect.top > b.bottom || rect.bottom < b.top { return }
        let w = Int(min(rect.right, b.right)) - Int(max(rect.left, b.left))
        let h = Int(min(rect.bottom, b.bottom)) - Int(max(rect.top, b.top))
        guard w > 0, h > 0 else { return }
        let top = Int(rect.top), left = Int(rect.left)
        var ia = top * srcA.width + left, ib = top * srcB.width + left, id = top * dst.width + left
        let strideA = srcA.width, strideB = srcB.width, strideD = dst.width
        srcA.pixels.withUnsafeBufferPointer { pa in
            srcB.pixels.withUnsafeBufferPointer { pb in
                dst.pixels.withUnsafeMutableBufferPointer { pd in
                    for _ in 0..<h {
                        // Columns i in 0..<w with all three indices inside their buffers.
                        let lo = max(0, -ia, -ib, -id)
                        let hi = min(w, pa.count - ia, pb.count - ib, pd.count - id)
                        if lo < hi {
                            for i in lo..<hi { pd[id + i] = blend(pa[ia + i], pb[ib + i], a: a) }
                        }
                        ia += strideA; ib += strideB; id += strideD
                    }
                }
            }
        }
    }
}

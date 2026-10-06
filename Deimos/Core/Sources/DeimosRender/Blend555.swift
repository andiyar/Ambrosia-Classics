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
    /// One pixel: A weighted by `a`, B by `32 − a` (`a` in 0…32).
    @inline(__always)
    public static func blend(_ pa: UInt16, _ pb: UInt16, a: Int) -> UInt16 {
        let wa = UInt32(a), wb = UInt32(32 - a)
        let ua = UInt32(pa), ub = UInt32(pb)
        let packedA = (ua & 0x7c1f) | ((ua & 0x03e0) << 15)
        let packedB = (ub & 0x7c1f) | ((ub & 0x03e0) << 15)
        let sum = packedA &* wa &+ packedB &* wb
        return UInt16(((sum >> 5) & 0x7c1f) | ((sum >> 20) & 0x03e0))
    }

    /// `FUN_1001e9d0(srcA, srcB, dst, rect, a)`: `dst = blend(A, B, a)` over `rect`. The rect is rejected when it lies
    /// wholly outside the dst bounds (`1001ea04…1001ea40`), else intersected with them (`1001ea44…1001ea8c`); an empty
    /// result draws nothing (`1001ea9c…1001eab0`). A and B are read at the same coordinates through their own row
    /// strides and are not clipped separately (the callers pass clones of the dst).
    public static func blend(_ srcA: Pixmap555, _ srcB: Pixmap555, into dst: inout Pixmap555, rect: MacRect, a: Int) {
        let r = rect.clipped(to: dst.bounds)
        guard r.right > r.left, r.bottom > r.top else { return }
        for y in Int(r.top)..<Int(r.bottom) {
            for x in Int(r.left)..<Int(r.right) {
                dst[x, y] = blend(srcA[x, y], srcB[x, y], a: a)
            }
        }
    }
}

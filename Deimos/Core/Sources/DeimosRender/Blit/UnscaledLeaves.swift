import Foundation
import DeimosCore

/// The eight unscaled leaves (blit-pixel-rules §3–§4; HIGH):
///
/// | mode | inside (unclipped) | clipped twin |
/// |---|---|---|
/// | 0 copy  | `FUN_1001d9f0` | `FUN_1001e0d0` |
/// | 1 fade  | `FUN_1001db50` | `FUN_1001e2b0` |
/// | 2 shadow| `FUN_1001dd20` | `FUN_1001e4f0` |
/// | 3 tint  | `FUN_1001df00` | `FUN_1001e770` |
///
/// Each leaf holds both paths: the map path when the frame has an alpha map, the colour-key path otherwise. Map path,
/// per row: a first entry of 1000 skips the whole row (`1001da50 cmplwi r0,0x3e8`); otherwise each pixel follows
/// `SpriteBlitter.mapPixel`. A twin is its sibling's kernel instruction for instruction plus (a) an early reject
/// (redundant with the dispatcher), (b) a running (x, y) — y advances on 1000 rows too — and (c) a per-pixel mask
/// `clipL ≤ x < clipR && clipT ≤ y < clipB` before anything is read (§4) — so one body serves both, the twin passing
/// its clip. The 1000-row test runs before the clip test in the twins (`1001e1d8`), which changes nothing.
enum UnscaledLeaves {

    /// Draw `f` with its top-left at (`left`, `top`). `clip` nil = the inside leaf; else the twin's mask
    /// (the command clip, right/bottom exclusive). `alpha` is ignored in mode 0 (the leaf takes none).
    static func blit(_ f: SpriteFrame, into port: inout Pixmap555, left: Int, top: Int, mode: Int, alpha: Int,
                     colour: UInt16, clip: MacRect?) {
        guard (0...3).contains(mode) else { return }
        let w = f.width, h = f.height
        // Twin early reject (`1001e0d4…1001e108`): X > clipR || X+w < clipL || Y > clipB || Y+h < clipT.
        var cl = Int.min, ct = Int.min, cr = Int.max, cb = Int.max
        if let c = clip {
            cl = Int(c.left); ct = Int(c.top); cr = Int(c.right); cb = Int(c.bottom)
            if left > cr || left + w < cl || top > cb || top + h < ct { return }
        }
        // The per-pixel masks — the twin's clip and the replica guard (SpriteBlitter) — are rectangles, so they are
        // hoisted to one column range and one row range (no pixel outside them is read or written either way).
        let xLo = max(cl, 0), xHi = min(cr, port.width)
        let yLo = max(ct, 0), yHi = min(cb, port.height)
        let c0 = max(0, xLo - left), c1 = min(w, xHi - left)
        let r0 = max(0, yLo - top), r1 = min(h, yHi - top)
        guard c0 < c1, r0 < r1 else { return }
        let pw = port.width
        f.pixels.withUnsafeBufferPointer { src in
            port.pixels.withUnsafeMutableBufferPointer { dst in
                if let alphaMap = f.alphaMap {
                    alphaMap.withUnsafeBufferPointer { map in
                        for r in r0..<r1 {
                            let row = r * w
                            if map[row] == 1000 { continue }       // `1001da50`: a first entry of 1000 skips the row
                            let d = (top + r) * pw + left
                            for c in c0..<c1 {
                                if let v = SpriteBlitter.mapPixel(mode: mode, p: Int(map[row + c]), a: alpha,
                                                                  src: src[row + c], dst: dst[d + c], colour: colour,
                                                                  scaledClamp: false) {
                                    dst[d + c] = v
                                }
                            }
                        }
                    }
                } else {
                    for r in r0..<r1 {
                        let row = r * w
                        let d = (top + r) * pw + left
                        for c in c0..<c1 {
                            if let v = SpriteBlitter.keyPixel(mode: mode, a: alpha, src: src[row + c], key: f.key,
                                                              dst: dst[d + c], colour: colour) {
                                dst[d + c] = v
                            }
                        }
                    }
                }
            }
        }
    }
}

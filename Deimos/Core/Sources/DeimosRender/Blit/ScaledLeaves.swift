import Foundation
import DeimosCore

/// The scaled path: the two scaled dispatchers and their 16 leaves (blit-pixel-rules §1.3, §5; HIGH).
///
/// | clip | source | mode 0 | mode 1 | mode 2 | mode 3 |
/// |---|---|---|---|---|---|
/// | game area (`FUN_1001a6f0`) | alpha map | `FUN_1001b7d0` | `FUN_1001ba40` | `FUN_1001bcf0` | `FUN_1001bfd0` |
/// | game area (`FUN_1001a6f0`) | colour key | `FUN_1001c270` | `FUN_1001c480` | `FUN_1001c6c0` | `FUN_1001c8f0` |
/// | other (`FUN_1001aa90`) | alpha map | `FUN_1001cb40` | `FUN_1001cc60` | `FUN_1001cdc0` | `FUN_1001cf80` |
/// | other (`FUN_1001aa90`) | colour key | `FUN_1001d0e0` | `FUN_1001d270` | `FUN_1001d370` | `FUN_1001d460` |
///
/// Geometry (§5.1, `1001a738…1001a7f4` / `1001aae8…1001aba4`), all single precision: `W = (float)w · s`,
/// `w′ = fctiwz(W)`, `left = fctiwz(X − 0.5f·W)` (`fnmsubs`, one rounding), likewise H, h′, top; right = left + w′,
/// bottom = top + h′; w′ ≤ 0 or h′ ≤ 0 → nothing. Mode byte ≥ 4 → nothing (`1001a824`).
///
/// Sampling (§5.2): nearest neighbour, left/top aligned, `sx = (w·(dx − left)) div w′`, `sy = (h·(dy − top)) div h′`
/// (`divw`, dx − left ≥ 0), always from the UNclamped left/top. The game-area leaves clamp the destination by
/// immediates to x ∈ [max(left, 0), min(right, 416)), y ∈ [max(top, 0), min(bottom, 480)) (`1001b808…1001b828`);
/// the other leaves walk the whole rect column-major and mask each pixel with the command clip (§5.3) — every
/// destination pixel is written at most once, so the visiting order does not matter and rows are walked here.
/// Map leaves test p == 32 and p == 1000 per pixel (`1001bc28`, `1001bc30`); the per-mode rules equal the unscaled
/// ones except that modes 1/3 clamp `a + p` to 32 and blend instead of skipping (§5.4) — `SpriteBlitter.mapPixel`
/// with `scaledClamp`. The alpha reaches the leaves as `(float)alpha` and back through `FUN_1004d5c0` (truncate),
/// exact for 0…31.
public enum ScaledLeaves {

    public struct Geometry: Equatable, Sendable {
        public var left: Int32
        public var top: Int32
        public var width: Int32
        public var height: Int32
        public init(left: Int32, top: Int32, width: Int32, height: Int32) {
            self.left = left; self.top = top; self.width = width; self.height = height
        }
    }

    /// The destination clamp of the game-area leaves: `0x1a0` = 416, `0x1e0` = 480 (`1001b81c`, `1001b828`).
    static let clampRight = 416
    static let clampBottom = 480

    /// The anchor/size arithmetic of `1001a738…1001a7f4`.
    public static func geometry(x: Int32, y: Int32, width: Int, height: Int, scale: Float) -> Geometry {
        let half = Float(0.5)                       // `lfs f5,0x8(r10)` → 0x100d6d3c
        let fw = Float(width) * scale               // `1001a77c fmuls`
        let fh = Float(height) * scale              // `1001a794 fmuls`
        let l = Float(x).addingProduct(-fw, half)   // `1001a7ac fnmsubs` = X − W·0.5, one rounding
        let t = Float(y).addingProduct(-fh, half)   // `1001a7c4 fnmsubs`
        return Geometry(left: fctiwz(l), top: fctiwz(t), width: fctiwz(fw), height: fctiwz(fh))
    }

    /// PowerPC `fctiwz`: round toward zero, saturating; NaN → 0x80000000.
    static func fctiwz(_ v: Float) -> Int32 {
        if v.isNaN { return Int32.min }
        if v >= 2147483648 { return Int32.max }
        if v < -2147483648 { return Int32.min }
        return Int32(v.rounded(.towardZero))
    }

    /// Draw `f` centred on (`x`, `y`) at `scale`. `clip` nil = the game-area leaves (clamped), else the clipped
    /// leaves masked by `clip`.
    static func blit(_ f: SpriteFrame, into port: inout Pixmap555, x: Int32, y: Int32, scale: Float, mode: Int,
                     alpha: Int, colour: UInt16, clip: MacRect?) {
        guard (0...3).contains(mode) else { return }
        let g = geometry(x: x, y: y, width: f.width, height: f.height, scale: scale)
        let left = Int(g.left), top = Int(g.top)
        let right = left + Int(g.width), bottom = top + Int(g.height)   // `1001a7d8`, `1001a7e8` (32-bit adds)
        guard right - left > 0, bottom - top > 0 else { return }         // `1001a7e0 subf.; ble`, `1001a7f0`
        let dstW = right - left, dstH = bottom - top
        var x0 = left, x1 = right, y0 = top, y1 = bottom
        var cl = Int.min, ct = Int.min, cr = Int.max, cb = Int.max
        if let c = clip {
            cl = Int(c.left); ct = Int(c.top); cr = Int(c.right); cb = Int(c.bottom)
        } else {
            x0 = max(left, 0); y0 = max(top, 0)
            x1 = min(right, clampRight); y1 = min(bottom, clampBottom)
        }
        guard x1 > x0, y1 > y0 else { return }
        let sw = f.width, sh = f.height
        let pw = port.width, ph = port.height
        // The column table (`1001b864…1001b880`): sx per absolute dx.
        let columns = (x0..<x1).map { (sw * ($0 - left)) / dstW }
        port.pixels.withUnsafeMutableBufferPointer { dst in
            for dy in y0..<y1 {
                guard dy >= ct, dy < cb else { continue }
                guard dy >= 0, dy < ph else { continue }                       // replica guard (SpriteBlitter)
                let sRow = ((sh * (dy - top)) / dstH) * sw                      // `1001b970…1001b980`
                for (k, sx) in columns.enumerated() {
                    let dx = x0 + k
                    guard dx >= cl, dx < cr else { continue }
                    guard dx >= 0, dx < pw else { continue }
                    let i = dy * pw + dx
                    let src = f.pixels[sRow + sx]
                    let v: UInt16?
                    if let map = f.alphaMap {
                        let p = Int(map[sRow + sx])
                        v = p == 1000 ? nil
                            : SpriteBlitter.mapPixel(mode: mode, p: p, a: alpha, src: src, dst: dst[i], colour: colour,
                                                     scaledClamp: true)
                    } else {
                        v = SpriteBlitter.keyPixel(mode: mode, a: alpha, src: src, key: f.key, dst: dst[i], colour: colour)
                    }
                    if let v { dst[i] = v }
                }
            }
        }
    }
}

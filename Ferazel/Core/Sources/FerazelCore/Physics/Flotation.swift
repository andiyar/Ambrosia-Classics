import Foundation

/// `.HandleFlotation(s, surfaceY) @ 10042d04` (decompile l. 38079–38123; physics-sprites §8.6), called by
/// `.HandleUnderWater` when `+0x19e > 0` (rafts and floes from W1, springboards, the dying player's body). Plan P4.
public enum Flotation {
    /// 0.93 (f64 `0x100a17f0`, rising) / 0.86 (f64 `0x100a17f8`, sinking) — `tools/const.py`.
    static let rising = Double(bitPattern: 0x3fed_c28f_5c28_f5c3)
    static let sinking = Double(bitPattern: 0x3feb_851e_b851_eb85)

    /// b = `+0x19e` (i16); target T = `+0x1a0` + (S − (top + ((bottom − top) >> 1))) on the hot rect `+0x34`/`+0x38`
    /// (i16, srawi); y = y256 >> 8 (srawi); b > 0x15e → 0x15e; T − y < 0 → b = −b; vy += b; then vy = (int)(vy · 0.93)
    /// when b < 1, else (int)(vy · 0.86) (f64 multiply, fctiwz); T == y and |vy| < 0x46 → vy 0, y256 = T · 0x100.
    public static func handle(world w: SpriteWorld, id: Int, surfaceY: Int32) {
        w.active.update(id: id) { s in
            var b = Int32(s.buoyancy)
            let top = Int32(Int16(truncatingIfNeeded: s.hotRect.top))
            let bottom = Int32(Int16(truncatingIfNeeded: s.hotRect.bottom))
            let target = Int32(s.floatOffset) &+ (surfaceY &- (top &+ ((bottom &- top) >> 1)))
            let y = s.y256 >> 8
            if 0x15e < b { b = 0x15e }
            if target &- y < 0 { b = 0 &- b }
            s.vy &+= b
            s.vy = TileSolver.fctiwz(Double(s.vy) * (b < 1 ? rising : sinking))
            if target == y {
                let m = s.vy < 1 ? 0 &- s.vy : s.vy
                if m < 0x46 {
                    s.vy = 0
                    s.y256 = target &* 0x100
                }
            }
        }
    }
}

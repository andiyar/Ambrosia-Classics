import Foundation

/// The trig module `FUN_10042920…FUN_100431e8` (units-movement.md §2.2–§2.3, loose-ends-combat.md §1, HIGH):
/// the four start-up tables and the heading helpers. ★ LOCKED (plan S2).
///
/// **Build listing `FUN_10042920` (`10042978..10042a6c`), read for C7.** Constants: TOC r2−0x6e2c →
/// `0x100d7318` (floats {0.017453292 = 0x3c8efa35, 0.0, 180.0, 90.0, 270.0}); r2−0x6e20 → `0x100d732c`
/// (doubles {0.01, 57.2957795, 2^52+2^31 magic, 57.29577951308232, 180.0, 360.0, 270.0, 0.0, 100.0}).
/// - atan, 1024 ints (r2−0x6e24): `10042978..100429bc` — i → double exactly (magic `fsub`), `fmul` by the
///   double 0.01, MathLib `atan` (`bl 0x100d5754`), `fmul` by the double **57.2957795** (the truncated literal
///   `0x404ca5dc1a47a9e3`, not 180/π), `fctiwz`. All double precision. `cmpwi r24,0x3ff; ble` → i = 0…1023.
/// - sqrt, 16384 floats (r2−0x6e28): `100429cc..10042a00` — `fsubs` (i → float), MathLib `sqrt`
///   (`0x100d576c`, the float promoted to double), `frsp`.
/// - cos (r2−0x6e30) and sin (r2−0x6e34), 360 floats each: `10042a18..10042a6c` — `fsubs` (i → float), then
///   **`fmuls f30, f31, f0`: the angle is the single-precision product fl32(0.017453292f · i)**, passed
///   (as a double holding that float) to MathLib `cos` (`0x100d5784`) and `sin` (`0x100d579c`), each `frsp`.
///
/// **Reproducing the MathLib values bit-exactly (the film-replay risk, INDEX #45).** The replica computes
/// the same expressions with Foundation (`sin`, `cos`, `atan`, `sqrt` on `Double`). Proof that the results
/// cannot depend on which libm computes them (emulation over the listing's precision with 200-bit mpmath,
/// 2026-10-07): every true sin/cos value lies **≥ 150,821 double ulps** from a float32 rounding boundary
/// (worst: sin at 210), every true atan product lies **≥ 1,446,053 double ulps** from an integer (worst:
/// i = 100, 44.99999998972517 → 44), and every non-square sqrt lies **≥ 953 double ulps** from a float32
/// boundary (worst n = 6577). So any `sin`/`cos`/`atan` within 150,000 ulps and any `sqrt` within 953 ulps
/// — MathLib, Darwin libm, glibc, MSVC — yields these exact tables. `TrigTests` pins bit patterns and
/// whole-table sums. **Not provable:** the run-time `atan` of `headingOf` (`FUN_10042cd0`) on arbitrary
/// inputs — it is rounded to float before use, so a MathLib/libm difference matters only when its result
/// lies within an ulp of a float32 midpoint (MED, loose-ends-combat §1.3; the round trip of the table's
/// own unit vectors is ≥ 765,136 ulps safe).
public enum Trig {
    /// `*(float*)0x100d7318` = 0x3c8efa35 (= fl32(π/180)).
    public static let degreesToRadians = Float(bitPattern: 0x3c8e_fa35)
    /// `*(double*)0x100d732c` = 0.01 (0x3f847ae147ae147b).
    static let atanStep = Double(bitPattern: 0x3f84_7ae1_47ae_147b)
    /// `*(double*)0x100d7334` = 57.2957795 (0x404ca5dc1a47a9e3) — the atan table's scale.
    static let atanScale = Double(bitPattern: 0x404c_a5dc_1a47_a9e3)
    /// `*(double*)0x100d7344` = 57.29577951308232 (0x404ca5dc1a63c1f8) — `FUN_10042cd0`'s scale.
    static let radiansToDegrees = Double(bitPattern: 0x404c_a5dc_1a63_c1f8)

    /// r2−0x6e34 → BSS `0x10106790`: `sin(fl32(0.017453292f · i))`, i = 0…359.
    public static let sinTable: [Float] = (0..<360).map { i in
        Float(Foundation.sin(Double(degreesToRadians * Float(i))))
    }
    /// r2−0x6e30 → BSS `0x10106d30`: `cos(fl32(0.017453292f · i))`, i = 0…359.
    public static let cosTable: [Float] = (0..<360).map { i in
        Float(Foundation.cos(Double(degreesToRadians * Float(i))))
    }
    /// r2−0x6e24 → BSS `0x101172d0`: `fctiwz(atan(0.01 · i) · 57.2957795)`, i = 0…1023, all double.
    public static let atanTable: [Int32] = (0..<1024).map { i in
        fctiwz(Foundation.atan(atanStep * Double(i)) * atanScale)
    }
    /// r2−0x6e28 → BSS `0x101072d0`: `(float)sqrt((double)(float)n)`, n = 0…16383.
    public static let sqrtTable: [Float] = (0..<16384).map { n in squareRoot(Int32(n)) }

    /// `FUN_10042f00` — S[h]; h = 360 → 0 (`cmpwi r3,0x168`). No other range check in the original: an index
    /// outside 0…360 reads neighbouring BSS (the other table, or whatever lies beyond). **Callers must keep
    /// headings in 0…360** (every heading the bank reads is wrapped there first); here an out-of-range index
    /// is a precondition failure (the array traps) rather than a silent read of the wrong memory.
    public static func sin(_ h: Int32) -> Float { sinTable[h == 360 ? 0 : Int(h)] }

    /// `FUN_10042ee0` — C[h]; h = 360 → 0. Same precondition as `sin`.
    public static func cos(_ h: Int32) -> Float { cosTable[h == 360 ? 0 : Int(h)] }

    /// `FUN_10043040` — compass → internal heading, `h' = (180 − h) mod 360` for 0…360 (an involution):
    /// `cmpwi r3,0xb4; bgt` → h ≤ 180: `abs(h − 180)` (`subi`, `FUN_1004ee30` = abs); else `540 − h`
    /// (`subfic r0,r3,0x21c`). Compass: 0 = up, 90 = right; internal: 0 = down, 180 = up.
    public static func internalHeading(_ compass: Int32) -> Int32 {
        if compass <= 180 {
            let d = compass &- 180
            return d < 0 ? 0 &- d : d
        }
        return 540 &- compass
    }

    /// `FUN_10042b30` — (S[h'], C[h']) for an internal heading.
    public static func unitVector(heading: Int32) -> (x: Float, y: Float) {
        (sin(heading), cos(heading))
    }

    /// `FUN_10042b80(h', speed, out)` — `(speed·S[h'], speed·C[h'])`, each one `fmuls` (`10042bac`, `10042bc0`).
    /// For a compass heading h the screen velocity is `vector(heading: internalHeading(h), speed:)`.
    public static func vector(heading: Int32, speed: Float) -> (x: Float, y: Float) {
        (speed * sin(heading), speed * cos(heading))
    }

    /// `FUN_10042ad0(x, y, tx, ty)` — compass heading from (x, y) toward (tx, ty): `a = x − tx`, `b = y − ty`
    /// (`subf r7,r5,r3`; `subf r0,r6,r4`, wrapping int), each converted exactly to double (magic `fsub`), then
    /// `FUN_10043090(a, b)`.
    public static func headingTo(x: Int32, y: Int32, tx: Int32, ty: Int32) -> Int32 {
        compassAngle(a: Double(x &- tx), b: Double(y &- ty))
    }

    /// `FUN_10043090(f1 = a, f2 = b)` (listing `10043090..100431e8`, read for C7), double precision:
    /// 1. `|b|`, `|a|` by `fcmpo x, 0.0; ble → fneg` (so −0.0 and NaN are negated, not kept).
    /// 2. `|a| < |b|` (`fcmpo f0,f3; bge`) → `r = a / b` else `r = b / a` (`fdiv`), then `r ≤ 0 → −r`.
    /// 3. `idx = fctiwz(100.0 · r)` (`*(double*)0x100d736c` = 100.0), clamped to 0…1023 (`cmpwi 0; bge`,
    ///    `cmpwi 0x3ff; ble`); `t = |atan[idx]|` (`srawi; xor; subf`).
    /// 4. `|a| < |b|` → `t = 90 − t` (`1004317c subfic r3,r3,0x5a`).
    /// 5. `a < 0 ∧ b ≥ 0` → `t = 180 − t`; `a < 0 ∧ b < 0` → `t += 180`; `a ≥ 0 ∧ b < 0` → `t = −t`
    ///    (`10043180..100431cc`; `cror eq,gt,eq` = "≥").
    /// 6. `t −= 90`; `t < 0 → += 360`; `t ≥ 360 → −= 360` (`100431d0..100431e4`).
    /// a = b = 0: r = 0/0 = NaN, `fctiwz` NaN = 0x80000000 → index 0 → result 270 (kept as read).
    public static func compassAngle(a: Double, b: Double) -> Int32 {
        let absB = b > 0 ? b : -b
        let absA = a > 0 ? a : -a
        let aSmaller = absA < absB
        var r = aSmaller ? a / b : b / a
        if !(r > 0) { r = -r }
        var idx = fctiwz(100.0 * r)
        if idx < 0 { idx = 0 }
        if idx > 0x3ff { idx = 0x3ff }
        let v = atanTable[Int(idx)]
        var t = v < 0 ? 0 &- v : v
        if aSmaller { t = 90 &- t }
        if a < 0 && b >= 0 { t = 180 &- t }
        if a < 0 && b < 0 { t = t &+ 180 }
        if a >= 0 && b < 0 { t = 0 &- t }
        t = t &- 90
        if t < 0 { t = t &+ 360 }
        if t >= 360 { t = t &- 360 }
        return t
    }

    /// `FUN_10042cd0(&v)` — the internal heading of a vector (loose-ends-combat §1.2, listing `10042cd0..10042e8c`):
    /// the cardinal branches by `fcmpu`/`fcmpo` against 0.0, else per quadrant `t = fl32(atan(fl32(p / q)))`
    /// (`fdivs`, MathLib `atan`, `frsp`) and `fl32(57.29577951308232 · t)` (`fmul`, `frsp`) or `fl32(C − 57.29…·t)`
    /// with C = 180 / 360 / 270 (`fnmsub` — fused, one rounding — then `frsp`); `fctiwz`; ≥ 360 → 0.
    /// NaN in either component takes no branch → 0. The inverse of `vector` in the internal system, up to the
    /// truncation quirk (§1.3).
    public static func headingOf(vx: Float, vy: Float) -> Int32 {
        var f: Float = 0                                             // 10042ce0 lfs f1,0x4(r4) = 0.0
        if vx == 0 && vy == 0 {                                      // 10042cf4..10042d00
            f = 0
        } else if vx == 0 && vy > 0 {                                // 10042d04..10042d14
            f = 0
        } else if vx == 0 && vy < 0 {                                // 10042d18..10042d2c
            f = 180
        } else if vy == 0 && vx > 0 {                                // 10042d34..10042d4c
            f = 90
        } else if vy == 0 && vx < 0 {                                // 10042d50..10042d68
            f = 270
        } else if vx > 0 && vy > 0 {                                 // 10042d6c..10042d9c
            let t = Double(Float(Foundation.atan(Double(vx / vy))))
            f = Float(radiansToDegrees * t)
        } else if vx > 0 && vy < 0 {                                 // 10042da0..10042ddc
            let t = Double(Float(Foundation.atan(Double(vx / Swift.abs(vy)))))
            f = Float(Double(180).addingProduct(-radiansToDegrees, t))
        } else if vx < 0 && vy > 0 {                                 // 10042de0..10042e1c
            let t = Double(Float(Foundation.atan(Double(Swift.abs(vx) / vy))))
            f = Float(Double(360).addingProduct(-radiansToDegrees, t))
        } else if vx < 0 && vy < 0 {                                 // 10042e20..10042e60
            let t = Double(Float(Foundation.atan(Double(Swift.abs(vy) / Swift.abs(vx)))))
            f = Float(Double(270).addingProduct(-radiansToDegrees, t))
        }
        let h = EntityDraw.fctiwz(f)                                 // 10042e64
        return h < 360 ? h : 0                                       // 10042e70..10042e78
    }

    /// `FUN_10042f20(n)` — `n < 0x4000 ? sqrtTable[n] : (float)sqrt((double)(float)n)` (`cmpwi r3,0x4000`
    /// signed; `10042f44..10042f6c`: `fsubs` → float n, MathLib `sqrt`, `frsp`). Precondition n ≥ 0: a negative
    /// n would index before the table in the original (into the cos table's BSS); every caller passes
    /// `fctiwz` of a sum of squares.
    public static func root(_ n: Int32) -> Float {
        n < 0x4000 ? sqrtTable[Int(n)] : squareRoot(n)
    }

    /// `FUN_10042e90(p r3, q r4)` — `root(fctiwz(fmadds(dx, dx, dy·dy)))` with `dy = q.y − p.y`,
    /// `dx = q.x − p.x` (`fsubs`), `dy·dy` (`fmuls`), the `fmadds` fused (one rounding). Every distance in the
    /// units code is this.
    public static func distance(x0: Float, y0: Float, x1: Float, y1: Float) -> Float {
        let dy = y1 - y0
        let dx = x1 - x0
        let sum = (dy * dy).addingProduct(dx, dx)
        return root(EntityDraw.fctiwz(sum))
    }

    /// The sqrt expression of the table build and of `FUN_10042f20`'s large branch.
    private static func squareRoot(_ n: Int32) -> Float {
        Float(Foundation.sqrt(Double(Float(n))))
    }

    /// `fctiwz` of a double: truncation toward zero, saturating like the PPC instruction (NaN → 0x80000000).
    static func fctiwz(_ d: Double) -> Int32 {
        if d.isNaN { return Int32.min }
        if d >= 2_147_483_648 { return .max }
        if d <= -2_147_483_649 { return .min }
        return Int32(d.rounded(.towardZero))
    }
}

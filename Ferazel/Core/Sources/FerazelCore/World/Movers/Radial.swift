import Foundation

/// The radial block a sprite's `+0x198` points at (`.MakeRadial @ 1003d718`, a 0xa4-byte `NewPtrClear`; `+0x187` =
/// has-radial) — platforms-ropes-radial §1.2 (W1, plan S2). Angles are degrees·256, positions 24.8.
public struct Radial: Equatable, Sendable {
    /// `+0x00` / `+0x04`: the hub centre (24.8).
    public var hubX: Int32 = 0
    public var hubY: Int32 = 0
    /// `+0x08` / `+0x0c`: the hub velocity, added to the hub each frame.
    public var hubVX: Int32 = 0
    public var hubVY: Int32 = 0
    /// `+0x10`: the hub-velocity damping /256 (applied when > 0); < 0x100 also lets the hub roll (`.RadialWheelStep`).
    public var hubDamp: Int32 = 0
    /// `+0x14`: angular speed (1/256° per frame).
    public var speed: Int32 = 0
    /// `+0x18`: the angle (1/256°), wrapped into [0, 0x16800) by `.UpdateRadialPos`.
    public var angle: Int32 = 0
    /// `+0x1c` (never read) and `+0x20`: radius·256.
    public var radiusCopy: Int32 = 0
    public var radius: Int32 = 0
    /// `+0x2c` / `+0x2e`: the angle limits max° / min° (both 0 = none); `+0x30`: the limit bounce /256.
    public var maxDegrees: Int16 = 0
    public var minDegrees: Int16 = 0
    public var limitBounce: Int16 = 0
    /// `+0x32` / `+0x34`: spoke count and spoke face size (`.MakeRadiusSprites`).
    public var spokeCount: Int16 = 0
    public var spokeSize: Int16 = 0
    /// `+0x36`: the pull toward 270° (1/256° per frame²); `+0x38`: angular-speed damping /256 (when > 0).
    public var gravity: Int16 = 0
    public var damp: Int16 = 0
    /// `+0x3a`: projection (0 plane circle, 1 x fixed, 2 y fixed).
    public var persp: Int16 = 0
    /// `+0x3c` the draw scale /256, `+0x3e` the far-side floor (`.MakeRadial`: 0x100 / 0x96), `+0x40` depth·256.
    public var drawScale: Int16 = 0x100
    public var farScale: Int16 = 0x96
    public var depth: Int16 = 0
    /// The spoke pointers `+0x44 + 4j` (j = 0 …): `.MakeRadiusSprites` stores spoke k at `+0x40 + 4(n − k)`, so
    /// entry j holds spoke k = n − 1 − j. Ids in the `ActiveList` (nil = 0).
    public var spokes: [Int?] = []

    public init() {}
}

/// `.MakeRadialTables @ 1003d5c4` (decompile l. 35693–35731; raw `1003d65c fmul; fmul; frsp; fctiwz`;
/// platforms-ropes-radial §1.1): for i = 0 … 359, θ = (π·2.0·i) / 360.0 with **π = 3.1415926535** (f64
/// `0x100a18e8`), `cosT[i] = (int)(float)(256·cos θ·256)`, `sinT[i] = −(int)(float)(256·sin θ·256)` (already negated:
/// "up" on screen is a positive angle).
public enum RadialTables {
    public static let pi = 3.1415926535
    public static let cosT: [Int32] = (0..<360).map { i in
        let theta = (pi * 2.0 * Double(i)) / 360.0
        return Int32(Float(256.0 * Foundation.cos(theta) * 256.0).rounded(.towardZero))
    }
    public static let sinT: [Int32] = (0..<360).map { i in
        let theta = (pi * 2.0 * Double(i)) / 360.0
        return 0 &- Int32(Float(256.0 * Foundation.sin(theta) * 256.0).rounded(.towardZero))
    }

    /// The angle `a >> 8` folded into 0 … 359 by ±360 loops (as `short`).
    @inline(__always) static func degrees(_ angle: Int32) -> Int {
        var a = Int(Int16(truncatingIfNeeded: angle >> 8))
        while a < 0 { a += 0x168 }
        while a > 0x167 { a -= 0x168 }
        return a
    }
}

/// The radial routines (platforms-ropes-radial §1.2–§1.7) on a sprite of a `SpriteWorld`.
public enum RadialMotion {
    /// `.MakeRadial(s, cx, cy, r, speed, angle, g, damp, hubDamp, persp) @ 1003d718` (decompile l. 35737–35767): no-op
    /// when `+0x187` is set; else the block with hub (cx·256, cy·256), radius r·256 (both `+0x1c` and `+0x20`),
    /// `+0x14 = speed`, `+0x18 = angle·256`, `+0x36 = g`, `+0x38 = damp`, `+0x10 = hubDamp`, `+0x3a = persp`,
    /// `+0x3c = 0x100`, `+0x3e = 0x96`. (The tables are built once, `RadialTables`.)
    public static func make(_ w: SpriteWorld, id: Int, cx: Int16, cy: Int16, radius: Int16, speed: Int16, angle: Int16,
                            gravity: Int16, damp: Int16, hubDamp: Int16, persp: Int16) {
        w.active.update(id: id) { s in
            guard s.radial == nil else { return }
            var b = Radial()
            b.hubX = Int32(cx) << 8
            b.hubY = Int32(cy) << 8
            b.radiusCopy = Int32(radius) << 8
            b.radius = Int32(radius) << 8
            b.speed = Int32(speed)
            b.angle = Int32(angle) << 8
            b.gravity = gravity
            b.damp = damp
            b.hubDamp = Int32(hubDamp)
            b.persp = persp
            s.radial = b
        }
    }

    /// `.FindUpdatedRadialSpeed(block, angle, speed, wheel, noDamp) @ 1003dde4` (decompile l. 35981–36016): with
    /// g = `+0x36` > 0 and a = angle >> 8: a < 180 → a = 360 if a < 90 else 180; then 90 ≤ a ≤ 270 (`a < 0x10f ∧
    /// 0x59 < a`) → speed += g, else speed −= g (a triangle-wave pull toward 270°). Then `+0x38 > 0` and no noDamp →
    /// `speed = speed·damp >> 8`. `wheel` adds `.FindRadWheelStepSpeedMod(angle >> 8)` (never: `.UpdateRadialPos`
    /// passes 0).
    public static func updatedSpeed(_ b: Radial, angle: Int32, speed: Int32, wheel: Bool = false,
                                    noDamp: Bool = false) -> Int32 {
        var speed = speed
        let g = b.gravity
        var a = angle >> 8
        if 0 < g {
            if a < 0xb4 { a = a < 0x5a ? 0x168 : 0xb4 }
            if a < 0x10f && 0x59 < a { speed &+= Int32(g) } else { speed &-= Int32(g) }
        }
        if 0 < b.damp && !noDamp { speed = (speed &* Int32(b.damp)) >> 8 }
        if wheel { speed &+= Int32(wheelStepMod(Int16(truncatingIfNeeded: angle >> 8))) }
        return speed
    }

    /// `.FindRadWheelStepSpeedMod(a) @ 1003e32c` (decompile l. 36163–36191): a folded into 0 … 359; a − 90 for
    /// a < 180, 270 − a for a ≥ 180 (−90 at 0°, +90 at 180°).
    public static func wheelStepMod(_ angle: Int16) -> Int16 {
        var a = angle
        while a < 0 { a &+= 0x168 }
        while 0x167 < a { a &-= 0x168 }
        var positive = true
        var t: Int16
        if a < 0x5a || 0x10e < a {
            positive = false
            t = a
            if 0x59 < a, 0x10e < a { t = 0x168 - a }
        } else if a < 0xb4 {
            t = 0xb4 - a
        } else {
            t = a - 0xb4
        }
        return positive ? 0x5a - t : 0 - (0x5a - t)
    }

    /// `.RadialWheelStep(s, k) @ 1003e3e8` (decompile l. 36179–36196): speed += (mod(angle >> 8)·k) >> 8; then
    /// `+0x10 < 0x100` → hub vx = −speed.
    public static func wheelStep(_ w: SpriteWorld, id: Int, k: Int32) {
        w.active.update(id: id) { s in
            guard var b = s.radial else { return }
            let mod = Int32(wheelStepMod(Int16(truncatingIfNeeded: b.angle >> 8)))
            b.speed &+= (mod &* k) >> 8
            if b.hubDamp < 0x100 { b.hubVX = 0 &- b.speed }
            s.radial = b
        }
    }

    /// `.UpdateRadialPos(s) @ 1003debc` (decompile l. 36020–36157; raw `1003debc..1003e304`; platforms-ropes-radial
    /// §1.3): speed = `updatedSpeed`; angle += speed; hub += hub velocity; `+0x10 > 0` → hvx = hvx·d >> 8 (0 when
    /// unchanged), hvy = hvy·d >> 8; the angle wrapped into [0, 0x16800); the limits (`+0x2c`/`+0x2e`, either ≠ 0):
    /// the test side by max > min (`angle < 0xb401` → min side … as the dump's carry arithmetic), a clamp sets
    /// speed = −(speed·`+0x30` >> 8); then a = angle >> 8 (0 … 359), R = (i16)(`+0x20` >> 8), dx/dy =
    /// `((R·cosT[a]) / 256) >> 8`, `((R·sinT[a]) / 256) >> 8` (`srawi 8; addze` = division toward 0, then `srawi`). persp 0: `+0xc = hubX' + dx − (+0x10 − +0xc)`, `+0xa = hubY' + dy − (+0xe − +0xa)` —
    /// the stored centre `+0x10`/`+0xe`, which `.StandardSpriteCleanup` last wrote (0 before a sprite's first
    /// Cleanup: the first-frame radial position is the quirk the plan keeps, Invariant 7). persp ≠ 0: the depth,
    /// scale `+0x3c`/`+0x1ae` and the effect word `+0xb8` (f32/f64 as written), one axis held at the hub. Last
    /// `+0x14 = +0xc << 8`, `+0x1c = +0xa << 8` (sub-pixel discarded). hubX'/hubY' = the hub **after** this frame's
    /// hub step (`sVar9`/`sVar6` are read after the `+=`).
    public static func updatePosition(_ w: SpriteWorld, id: Int) {
        w.active.update(id: id) { s in
            guard var b = s.radial else { return }
            b.speed = updatedSpeed(b, angle: b.angle, speed: b.speed)
            b.angle &+= b.speed
            b.hubX &+= b.hubVX
            b.hubY &+= b.hubVY
            if 0 < b.hubDamp {
                let old = b.hubVX
                b.hubVX = (old &* b.hubDamp) >> 8
                if b.hubVX == old { b.hubVX = 0 }
                b.hubVY = (b.hubVY &* b.hubDamp) >> 8
            }
            let hx = Int(Int16(truncatingIfNeeded: b.hubX >> 8))          // `sVar9`
            let hy = Int(Int16(truncatingIfNeeded: b.hubY >> 8))          // `sVar6`
            let R = Int32(Int16(truncatingIfNeeded: b.radius >> 8))       // `iVar5`
            while b.angle < 0 { b.angle &+= 0x16800 }
            while 0x167ff < b.angle { b.angle &-= 0x16800 }
            if b.maxDegrees != 0 || b.minDegrees != 0 {
                let u = UInt32(bitPattern: b.angle)
                // `uVar7 = (u < 0xb401) − (~u >> 31)` when max > min, else `(0xb3ff < u) − (~u >> 31)` (raw
                // `1003dffc..1003e0d4`); bit 0 clear → the min test, set → the max test.
                let below = Int32(b.minDegrees) < Int32(b.maxDegrees) ? u < 0xb401 : 0xb3ff < u
                let v7 = UInt32(below ? 1 : 0) &- UInt32(bitPattern: Int32(bitPattern: ~u) >> 31)
                let maxSide = v7 & 1 != 0
                if !maxSide {
                    let lo = Int32(b.minDegrees) << 8
                    if b.angle < lo {
                        b.angle = lo
                        b.speed = 0 &- ((b.speed &* Int32(b.limitBounce)) >> 8)
                    }
                } else {
                    let hi = Int32(b.maxDegrees) << 8
                    if hi < b.angle {
                        b.angle = hi
                        b.speed = 0 &- ((b.speed &* Int32(b.limitBounce)) >> 8)
                    }
                }
            }
            let a = RadialTables.degrees(b.angle)
            let dx32 = (R &* RadialTables.cosT[a]) / 256                  // `iVar8` (srawi 8; addze)
            let dy32 = (R &* RadialTables.sinT[a]) / 256                  // `iVar5`
            let dx = Int(Int16(truncatingIfNeeded: dx32 >> 8))            // `sVar10`
            let dy = Int(Int16(truncatingIfNeeded: dy32 >> 8))            // `sVar2`
            let h = { (v: Int) in Int(Int16(truncatingIfNeeded: v)) }
            if b.persp == 0 {
                s.x = h(hx + dx - (s.centre.x - s.x))
                s.y = h(hy + dy - (s.centre.y - s.y))
            } else {
                // f = (float)((float)(R256 − D) / (2.0 · (float)R256)), D = dx32 (persp 1) or dy32 (persp 2).
                let D = b.persp == 1 ? dx32 : dy32
                let num = Double(Float(b.radius &- D))
                let f = Float(num / (2.0 * Double(Float(b.radius))))
                let f3 = Float(256.0) * f                                 // `_DAT_100a18d4 * fVar1`
                b.depth = Int16(truncatingIfNeeded: Int32(f3.rounded(.towardZero)))
                let scale = Int16(truncatingIfNeeded: TileSolver.fctiwz(
                    Double(Float(255.0) - f * Float(0x100 - Int32(b.farScale)))))
                b.drawScale = scale
                s.scale = scale
                let level = Int16(truncatingIfNeeded: TileSolver.fctiwz(0.05 * Double(f3)))
                s.mode = UInt32(bitPattern: Int32(level) &* 0x100 &+ 0xc0000)
                if b.persp == 1 {
                    s.x = h(hx - (s.centre.x - s.x))
                    s.y = h(hy + dy - (s.centre.y - s.y))
                } else {
                    s.x = h(hx + dx - (s.centre.x - s.x))
                    s.y = h(hy - (s.centre.y - s.y))
                }
            }
            s.x256 = Int32(Int16(truncatingIfNeeded: s.x)) << 8
            s.y256 = Int32(Int16(truncatingIfNeeded: s.y)) << 8
            s.radial = b
        }
    }

    /// `.MakeRadiusSprites(s, n, layer, type, size, setup) @ 1003d854` (decompile l. 35771–35803): only with a block;
    /// n capped at 0x18; `+0x32 = n`, `+0x34 = size`; for k = 0 … n−1 `MTNewSprite(type, s+0xc, s+0xa, layer, −1,
    /// setup)` stored at `+0x40 + 4(n − k)`, with spoke `+0x1d4 = s`, `+0x14c = k`, `+0x150 = n`, `+0x154 = R`; then
    /// `.UpdateRadiusSprites(s, 0, 0)`.
    public static func makeSpokes(_ w: SpriteWorld, id: Int, count nIn: Int16, layer: Int16, type: Int16, size: Int16,
                                  handler: SpriteHandler, setup: @escaping (inout SpriteSlot) -> Void) {
        guard let s = w.active.record(id: id), var b = s.radial else { return }
        let n = min(nIn, 0x18)
        b.spokeCount = n
        b.spokeSize = size
        b.spokes = Array(repeating: nil, count: max(Int(n), 0))
        w.active.update(id: id) { $0.radial = b }
        let R = b.radius >> 8
        for k in 0..<max(Int(n), 0) {
            guard let cur = w.active.record(id: id) else { return }
            let spoke = w.newSprite(type: type, x: cur.x, y: cur.y, layer: layer, handler: handler, setup: setup)
            let j = Int(n) - k - 1
            w.active.update(id: id) { $0.radial?.spokes[j] = spoke }
            if let sp = spoke {
                w.active.update(id: sp) { c in
                    c.siblings.first = id
                    c.classTimer = Int32(k)                               // `+0x14c`
                    c.classWord150 = Int32(n)                             // `+0x150`
                    c.classWord154 = R                                    // `+0x154`
                }
            }
        }
        updateSpokes(w, id: id, slopeMode: false, base: 0)
    }

    /// `.SetRadiusSpritesEffect(s, word) @ 1003d980`: `+0xb8 = word` on every spoke.
    public static func setSpokesEffect(_ w: SpriteWorld, id: Int, _ word: UInt32) {
        guard let b = w.active.record(id: id)?.radial else { return }
        for case let sp? in b.spokes { w.active.update(id: sp) { $0.mode = word } }
    }

    /// `.UpdateRadiusSprites(s, slopeMode, base) @ 1003da00` (decompile l. 35837–35977; platforms-ropes-radial §1.7):
    /// a = angle >> 8 (0 … 359), R = (i16)(`+0x20` >> 8), dx/dy as `.UpdateRadialPos`; for j = 0 … n−1 (entry
    /// `+0x44 + 4j`): persp 0 → spoke `+0xb0 = a`; persp ≠ 0 → the projected axis 0, `+0x1ae = s0 + (j·(i16)(2(+0x3c −
    /// s0)))/n` (s0 = (`+0x3e` + 0x100) / 2, C division), `+0x88 = 0`, `+0xb8 = (i16)(0.05·((f32)depth·j/n + (f32)(((n −
    /// j)·0xc0)/n)))·0x100 + 0xc0000`, `+0xb0 = −90`. Each spoke at `+0xc = hub + (dx·j)/n − size >> 1`, `+0xa = hub +
    /// (dy·j)/n − size >> 1` (each offset 0 when its d is 0; C division). The 24.8 position is not written. slopeMode:
    /// t = (dy·size) / dx (dx = 0 when persp ≠ 0), every spoke `+0xd2 = base + size >> 1 − t >> 1 + t`, `+0xd4 =
    /// base + size >> 1 − t >> 1`.
    public static func updateSpokes(_ w: SpriteWorld, id: Int, slopeMode: Bool, base: Int16) {
        guard let s = w.active.record(id: id), let b = s.radial else { return }
        let n = Int32(b.spokeCount)
        let hx = Int16(truncatingIfNeeded: b.hubX >> 8)
        let hy = Int16(truncatingIfNeeded: b.hubY >> 8)
        let R = Int32(Int16(truncatingIfNeeded: b.radius >> 8))
        let a = RadialTables.degrees(b.angle)
        let cosR = (R &* RadialTables.cosT[a]) / 256
        let sinR = (R &* RadialTables.sinT[a]) / 256
        let dx0 = cosR >> 8, dy0 = sinR >> 8
        let half = b.spokeSize >> 1
        for j in 0..<max(Int(n), 0) where j < b.spokes.count {
            guard let sp = b.spokes[j] else { continue }
            var dx = dx0, dy = dy0
            let J = Int32(j)
            w.active.update(id: sp) { c in
                if b.persp == 0 {
                    c.subtype = Int16(a)
                } else {
                    if b.persp == 1 { dx = 0 } else { dy = 0 }
                    let u = Int32(b.farScale) + 0x100
                    let s0 = Int16(truncatingIfNeeded: u / 2)
                    let span = Int32(Int16(truncatingIfNeeded: (Int32(b.drawScale) - Int32(s0)) * 2))
                    c.scale = s0 &+ Int16(truncatingIfNeeded: (J * span) / n)
                    c.lightOverlay = false
                    let depth = Float(Int32(b.depth))
                    let mix = depth * Float(J) / Float(n) + Float(((n - J) * 0xc0) / n)
                    let level = Int16(truncatingIfNeeded: TileSolver.fctiwz(0.05 * Double(mix)))
                    c.mode = UInt32(bitPattern: Int32(level) &* 0x100 &+ 0xc0000)
                    c.subtype = -90
                }
                let ox: Int16 = dx != 0 ? Int16(truncatingIfNeeded: (dx &* J) / n) : 0
                let oy: Int16 = dy != 0 ? Int16(truncatingIfNeeded: (dy &* J) / n) : 0
                c.x = Int(hx &+ ox &- half)
                c.y = Int(hy &+ oy &- half)
            }
        }
        if slopeMode {
            let dx = b.persp != 0 ? 0 : dx0
            let t = SpriteSlot.divw(dy0 &* Int32(b.spokeSize), dx)
            let right = base &+ half &- Int16(truncatingIfNeeded: t >> 1)
            let left = right &+ Int16(truncatingIfNeeded: t)
            for case let sp? in b.spokes.prefix(max(Int(n), 0)) {
                w.active.update(id: sp) { c in
                    c.surfaceLeft = left
                    c.surfaceRight = right
                }
            }
        }
    }

    /// `.BounceRadial(s, tileCentreX) @ 10061ac8` (decompile l. 54333–54409; f64 −0.75 `0x100a1a80`; platforms-ropes-radial
    /// §1.6): no-op for s = 0. speed = (int)(speed·−0.75), magnitude raised to 0x100 when below (sign kept, 0 → +);
    /// hvx the same; hvy = (int)(hvy·−0.75). Then `s+0x10 ≤ tileCentreX` → speed = +|speed|, hvx = −|hvx|; else
    /// speed = −|speed|, hvx = +|hvx|.
    public static func bounce(_ w: SpriteWorld, id: Int?, tileCentreX: Int16) {
        guard let id else { return }
        w.active.update(id: id) { s in
            guard var b = s.radial else { return }
            func damp(_ v: Int32) -> Int32 { TileSolver.fctiwz(Double(v) * -0.75) }
            func floor(_ v: Int32) -> Int32 {
                let m = v < 1 ? 0 &- v : v
                guard m < 0x100 else { return v }
                return (v < 0 ? -1 : 1) << 8
            }
            b.speed = floor(damp(b.speed))
            b.hubVX = floor(damp(b.hubVX))
            b.hubVY = damp(b.hubVY)
            let ms = b.speed < 1 ? 0 &- b.speed : b.speed
            let mh = b.hubVX < 1 ? 0 &- b.hubVX : b.hubVX
            if Int16(truncatingIfNeeded: s.centre.x) <= tileCentreX {
                b.speed = ms
                b.hubVX = 0 &- mh
            } else {
                b.speed = 0 &- ms
                b.hubVX = mh
            }
            s.radial = b
        }
    }
}

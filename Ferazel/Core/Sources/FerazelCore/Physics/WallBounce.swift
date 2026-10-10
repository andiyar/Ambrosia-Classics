import Foundation

/// The ice-slide arithmetic and the small helpers both solvers share (plan Invariant 5: f64 constants applied as the
/// dump does — `fmadd` / `fnmsub` are fused, one rounding — then `fctiwz`, truncation toward zero).
extension TileSolver {
    /// f64 slide factors (`tools/const.py`): 7.07 `0x100a1910`, 3.82 `0x100a1908`, 9.23 `0x100a1900`, 2.86 `0x100a18f8`.
    static let slide45 = Double(bitPattern: 0x401c_47ae_147a_e148)
    static let slide12 = Double(bitPattern: 0x400e_8f5c_28f5_c28f)
    static let slide21 = Double(bitPattern: 0x4022_75c2_8f5c_28f6)
    static let slide14 = Double(bitPattern: 0x4006_e147_ae14_7ae1)

    /// `fctiwz`: truncation toward zero, saturating at the i32 range (NaN → the most negative word).
    static func fctiwz(_ d: Double) -> Int32 {
        if d.isNaN { return Int32.min }
        if d >= 2147483647 { return Int32.max }
        if d <= -2147483648 { return Int32.min }
        return Int32(d.rounded(.towardZero))
    }

    /// `vx = (int)(f·slip + vx)` (`fmadd`) — the downhill-right slides.
    static func slidePlus(_ vx: Int32, _ slip: Int16, _ f: Double) -> Int32 {
        fctiwz(Double(vx).addingProduct(f, Double(slip)))
    }

    /// `vx = (int)−(f·slip − vx)` (`fnmsub`) = `(int)(vx − f·slip)` rounded once — the downhill-left slides.
    static func slideMinus(_ vx: Int32, _ slip: Int16, _ f: Double) -> Int32 {
        fctiwz(-((-Double(vx)).addingProduct(f, Double(slip))))
    }

    /// `.LimitValueToRange @ 10036804` on a short.
    static func limit(_ v: Int, _ lo: Int, _ hi: Int) -> Int { v < lo ? lo : (v <= hi ? v : hi) }

    /// `(short)((uint)v >> 8)`: the low 16 bits of `v >> 8`.
    static func short8(_ v: Int32) -> Int { Int(Int16(truncatingIfNeeded: v >> 8)) }

    /// `|v|` as the dump writes it (`v < 1 → −v`, wrapping).
    static func magnitude(_ v: Int32) -> Int32 { v < 1 ? 0 &- v : v }
}

extension TileSolver {
    /// `.WallBounce(s, kind, pos, vCentre, factor, rect, _, bounce) @ 10037a54` (decompile l. 33080–34112;
    /// player-states-2 §9). Returns the hit flag (the dump's `uVar15 & 0xff`).
    ///
    /// - Pre-processing (§9.1): the hundreds become the material; `k < 0 ∨ k > 0x3c` → no collision. Centring for every
    ///   kind but 0, 2, 8, 0xb, 0xd, 0xe, 0x24…0x2b: left = `(rect.left + rect.right) >> 1` (kind 4 keeps its left),
    ///   right = that + 1 (kind 7 keeps its right). Integer x/y refreshed from 24.8. `k < 0x30`: the (centred) mover
    ///   rect must meet `hotRects.perTile[k]` at (X, Y) — indexed by **kind** (§14 item 1). `k == 0x3c` → kind 3 and
    ///   `pos.y −= 8` (the caller's point, `param_3`).
    /// - The kind table (§9.2, §9.3) as the dump; kinds 4–7 revert x/y to `+0x8`/`+0x6` — the position the current
    ///   `.SeparateFromTiles2` call wrote at its entry (Bank correction A6). Composites recurse with the base kind
    ///   (no hundreds) and the original rect.
    /// - On a hit: the player (`isPlayer`) after an ice slide in this call without bounce gets `vy < 0 → 0` and
    ///   `y += 2`, `vy += 0x200` when `vy > 0` (`y += 1` for 0x13/0x14, unreachable); `+0xd0 = 0`; 24.8 re-synced
    ///   only for an integer that changed; material > 0 → `+0xd8`.
    ///
    /// `+0xcf` stores the kind byte in the dump; its only reader tests ≠ 0 (`100546cc`), so `ceilingHit` = true.
    /// The 7th argument (`param_7`) is only forwarded by the recursions and is not kept.
    @discardableResult
    public func wallBounce(_ id: Int, kind kindIn: Int, tile pos: inout TilePos, vCentre: Int, factor: Int16,
                           rect r: IdleSprites.Rect, bounce: Bool) -> Bool {
        let h = Self.h
        guard var s = world.active.sprite(id: id) else { return false }
        var k = Int(Int16(truncatingIfNeeded: kindIn))
        var material = 0
        while k > 99 { k -= 100; material += 1 }
        guard k >= 0, k <= 0x3c else { return false }

        var lc = r.left, rc = r.right
        let centred = k != 0 && k != 2 && !(0xd...0xe).contains(k) && !(0x24...0x2b).contains(k) && k != 8 && k != 0xb
        if centred {
            let mid = h((r.left + r.right) >> 1)
            if k != 4 { lc = mid }
            if k != 7 { rc = h(mid + 1) }
        }
        let entryX256 = s.x256, entryY256 = s.y256
        s.x = SpriteWorld.pixel(s.x256)
        s.y = SpriteWorld.pixel(s.y256)
        // `sStack_86..80`: the (centred) mover rect at the refreshed position, built only for k < 0x30.
        let M = IdleSprites.Rect(top: h(r.top + s.y), left: h(lc + s.x), bottom: h(r.bottom + s.y), right: h(rc + s.x))
        if k < 0x30 {
            let e = hotRects.perTile[k]
            let tileRect = IdleSprites.Rect(top: h(pos.y + e.top), left: h(pos.x + e.left), bottom: h(pos.y + e.bottom),
                                            right: h(pos.x + e.right))
            guard M.intersects(tileRect) else {
                world.active.update(id: id) { $0 = s }
                return false
            }
        }
        if k == 0x3c {
            k = 3
            pos.y = h(pos.y - 8)
        }
        let X = pos.x, Y = pos.y
        let X16 = X + 0x10, Y16 = Y + 0x10                             // iVar4, iVar13
        let X16h = h(X16), Y16h = h(Y16)                               // iVar9, iVar10
        let y0 = s.y                                                   // iVar8
        let kindByte = UInt8(truncatingIfNeeded: k)
        let f = Int32(factor)
        var hit = false
        var slid = false

        // The bounce arms (never taken by the player: factor 0, bounce 0 — §9 notation).
        func bounceSide() { s.vx = 0 &- ((s.vx &* f) >> 8); s.vy = (s.vy &* f) >> 8 }
        func bounceVertical() { s.vx = (s.vx &* f) >> 8; s.vy = 0 &- ((s.vy &* f) >> 8) }
        func ceiling() {
            if s.vy < 0 && bounce { bounceVertical() }
            if s.vy < 0 { s.ceilingHit = true; s.vy = 0 }
        }
        func floorStop() {
            if s.vy > 0 && bounce { s.vy = 0 &- ((s.vy &* f) >> 8) }
            if s.vy > 0 { s.vy = 0; s.groundKind = kindByte }
        }
        func restore() { s.x = s.oldPosition.x; s.y = s.oldPosition.y }
        /// A composite: write the sprite back, recurse with the base kind and the original rect, read it back.
        func recurse(_ base: Int) -> Bool {
            world.active.update(id: id) { $0 = s }
            let result = wallBounce(id, kind: base, tile: &pos, vCentre: vCentre, factor: factor, rect: r, bounce: bounce)
            s = world.active.sprite(id: id) ?? s
            return result
        }

        switch k {
        case 0:
            if s.x < X16 - lc {
                if s.vx < 0 && bounce { bounceSide() }
                if s.vx < 0 { s.vx = 0 }
                hit = true
                s.x = h(X16 - lc)
            }
        case 1:
            if y0 + r.top < Y16 {
                ceiling()
                hit = true
                s.y = h(Y16 - r.top)
            }
        case 2:
            if X16 - rc < s.x {
                if s.vx > 0 && bounce { bounceSide() }
                if s.vx > 0 { s.vx = 0 }
                hit = true
                s.x = h(X16 - rc)
            }
        case 3:
            if Y16 < y0 + r.bottom {
                floorStop()
                hit = true
                s.y = h(Y16 - r.bottom)
            }
        case 4:
            restore()
            let vx0 = s.vx
            if h((Y + 0x20) - (M.bottom - Self.short8(s.vy))) < h(((r.left + s.x) - Self.short8(vx0)) - X) && vx0 < 1 {
                if vx0 < 0 && bounce { s.vx = 0 &- ((vx0 &* f) >> 8); s.vy = (s.vy &* f) >> 8 }
                s.vx = 0
                s.x = h(X16 - r.left)
            } else {
                floorStop()
                s.y = h(Y16 - r.bottom)
            }
            hit = true
        case 5:
            restore()
            if h(M.top - Y) < h(M.left - X) {
                if s.vx < 0 && bounce { bounceSide() }
                s.vx = 0
                s.x = h(X16 - lc)
            } else {
                ceiling()
                s.y = h(Y16 - r.top)
            }
            hit = true
        case 6:
            restore()
            if h(M.top - Y) < h((X + 0x20) - M.right) {
                if s.vx > 0 && bounce { bounceSide() }
                s.vx = 0
                s.x = h(X16 - rc)
            } else {
                ceiling()
                s.y = h(Y16 - r.top)
            }
            hit = true
        case 7:
            restore()
            let vx0 = s.vx, vy0 = s.vy
            if h((Y + 0x20) - (M.bottom - Self.short8(vy0))) < h((X + 0x20) - ((s.x + r.right) - Self.short8(vx0))) {
                if vx0 > 0 && bounce { s.vx = 0 &- ((vx0 &* f) >> 8); s.vy = (s.vy &* f) >> 8 }
                s.vx = 0
                s.x = h(X16 - r.right)
            } else {
                if vy0 > 0 && bounce { s.vy = 0 &- ((vy0 &* f) >> 8) }
                if s.vy > 0 { s.vy = 0; s.groundKind = kindByte }
                s.y = h(Y16 - r.bottom)
            }
            hit = true
        case 8:
            // `(X, Y, X+32, Y+16)` (its bottom is the prologue's register, raw `10037c5c`) and `(X+16, Y, X+32, Y+32)`.
            let a = IdleSprites.Rect(top: Y, left: X, bottom: Y16h, right: X + 0x20)
            let b = IdleSprites.Rect(top: Y, left: X + 0x10, bottom: Y + 0x20, right: X + 0x20)
            if M.intersects(a) || M.intersects(b) {
                if h((X + 0x20) - M.right) < h(M.top - Y) {
                    if s.vx > 0 && bounce { bounceSide() }
                    if s.vx > 0 { s.vx = 0 }
                    s.x = h(X16 - rc)
                } else {
                    if s.vy < 0 && bounce { bounceVertical() }
                    if s.vy < -1 { s.vy = -1 }
                    s.y = h(Y16 - r.top)
                }
                if X16 - rc < s.x { s.x = h(X16 - rc) }
                if s.y < Y16 - r.top { s.y = h(Y16 - r.top) }
                hit = true
            }
        case 9:
            let a = IdleSprites.Rect(top: Y16h, left: X, bottom: Y + 0x20, right: X + 0x20)
            let b = IdleSprites.Rect(top: Y, left: X + 0x10, bottom: Y + 0x20, right: X + 0x20)
            if M.intersects(a) || M.intersects(b) {
                if h((X + 0x20) - M.right) < h((Y + 0x20) - M.bottom) {
                    if s.vx > 0 && bounce { bounceSide() }
                    if s.vx > 0 { s.vx = 0 }
                    s.x = h(X16 - rc)
                } else {
                    if s.vy > 0 && bounce { bounceVertical() }
                    if s.vy > 0 { s.vy = 0; s.groundKind = kindByte }
                    s.y = h(Y16 - r.bottom)
                }
                if X16 - rc < s.x { s.x = h(X16 - rc) }
                if Y16 - r.bottom < s.y { s.y = h(Y16 - r.bottom) }
                hit = true
            }
        case 0xa:
            let a = IdleSprites.Rect(top: Y, left: X, bottom: Y + 0x20, right: X16h)
            let b = IdleSprites.Rect(top: Y + 0x10, left: X, bottom: Y + 0x20, right: X + 0x20)
            if M.intersects(a) || M.intersects(b) {
                if h(M.left - X) < h((Y + 0x20) - M.bottom) {
                    if s.vx < 0 && bounce { bounceSide() }
                    if s.vx < 0 { s.vx = 0 }
                    s.x = h(X16 - lc)
                } else {
                    if s.vy > 0 && bounce { bounceVertical() }
                    if s.vy > 0 { s.vy = 0; s.groundKind = kindByte }
                    s.y = h(Y16 - r.bottom)
                }
                if s.x < X16 - lc { s.x = h(X16 - lc) }
                if Y16 - r.bottom < s.y { s.y = h(Y16 - r.bottom) }
                hit = true
            }
        case 0xb:
            let a = IdleSprites.Rect(top: Y, left: X, bottom: Y16h, right: X + 0x20)     // same register bottom as 8
            let b = IdleSprites.Rect(top: Y, left: X, bottom: Y + 0x20, right: X + 0x10)
            if M.intersects(a) || M.intersects(b) {
                if h(M.left - X) < h(M.top - Y) {
                    if s.vx < 0 && bounce { bounceSide() }
                    if s.vx < 0 { s.vx = 0 }
                    s.x = h(X16 - lc)
                } else {
                    if s.vy < 0 && bounce { bounceVertical() }
                    if s.vy < -1 { s.vy = -1 }
                    s.y = h(Y16 - r.top)
                }
                if s.x < X16 - lc { s.x = h(X16 - lc) }
                if s.y < Y16 - r.top { s.y = h(Y16 - r.top) }
                hit = true
            }
        case 0xc:
            let sf = Self.limit(h((s.x + lc) - X), 0, 0x20)
            if sf + Y < y0 + r.bottom {
                if s.vy > 0 && bounce { bounceVertical() }
                if s.vy > 0 { s.vy = Self.magnitude(s.vx) &+ 0x100; s.groundKind = kindByte }
                s.y = h(Y + sf - r.bottom)
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slidePlus(s.vx, s.slip, Self.slide45)
                    if s.vx < 0 { s.vy = s.vx &+ 0x300 }
                }
                hit = true
            }
        case 0xd:
            let sf = Self.limit(h(0x20 - ((s.x + lc) - X)), 0, 0x20)
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0xe:
            let sf = Self.limit(h((s.x + rc) - X), 0, 0x20)
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0xf:
            let sf = Self.limit(h(0x20 - ((s.x + rc) - X)), 0, 0x20)
            if sf + Y < y0 + r.bottom {
                if s.vy > 0 && bounce { bounceVertical() }
                if s.vy > 0 { s.vy = Self.magnitude(s.vx) &+ 0x100; s.groundKind = kindByte }
                s.y = h(Y + sf - r.bottom)
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slideMinus(s.vx, s.slip, Self.slide45)
                    if s.vx > 0 { s.vy = 0x260 &- s.vx }
                }
                hit = true
            }
        case 0x10...0x1f:
            // §9.3: L / R = the centred left / right, T = the top; X16h / Y16h = `iVar9` / `iVar10`.
            let L = s.x + lc, R = s.x + rc, T = y0 + r.top
            switch k {
            case 0x10: hit = recurse(L < X16h ? 3 : 0xc)
            case 0x11: hit = recurse(Y16h < T ? 0xd : 0)
            case 0x12: hit = recurse(X16h < R ? 1 : 0xe)
            case 0x13:
                if R < X16h {
                    hit = recurse(2)
                } else if 0x10 < h(s.y + vCentre) + r.bottom {           // absolute y vs 16 (§14 item 2)
                    hit = recurse(0xf)
                }
            case 0x14: hit = recurse(X16h < L ? 0 : 0xc)
            case 0x15: hit = recurse(L < X16h ? 1 : 0xd)
            case 0x16: hit = recurse(T < Y16h ? 2 : 0xe)
            case 0x17: hit = recurse(X16h < R ? 3 : 0xf)
            case 0x18: hit = recurse(X16h < L ? 3 : 0xc)
            case 0x19: hit = recurse(L < X16h ? 0 : 0xd)
            case 0x1a: hit = recurse(R < X16h ? 1 : 0xe)
            case 0x1b: hit = recurse(X16h < R ? 2 : 0xf)
            case 0x1c: hit = recurse(L < X16h ? 0 : 0xc)
            case 0x1d: hit = recurse(X16h < L ? 1 : 0xd)
            case 0x1e: hit = recurse(X16h < R ? 2 : 0xe)
            default: hit = recurse(R < X16h ? 3 : 0xf)                 // 0x1f
            }
        case 0x20, 0x21:
            var sf = h((s.x + lc) - X) >> 1
            if k == 0x20 { sf = Self.limit(sf, 0, 0x10) } else { sf = Self.limit(h(sf + 0x10), 0x10, 0x20) }
            if sf + Y < y0 + r.bottom {
                if s.vy > 0 && bounce { bounceVertical() }
                if s.vy > 0 { s.vy = (Self.magnitude(s.vx) >> 1) &+ 0x100; s.groundKind = kindByte }
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slidePlus(s.vx, s.slip, Self.slide12)
                    let half = s.vx >> 1
                    if s.vy < half && !bounce { s.vy = half }
                }
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x22, 0x23:
            var sf = h((s.x + rc) - X) >> 1
            if k == 0x22 { sf = Self.limit(h(0x20 - sf), 0x10, 0x20) } else { sf = Self.limit(h(0x10 - sf), 0, 0x10) }
            sf = Self.limit(sf, 0, 0x20)
            if sf + Y < y0 + r.bottom {
                if s.vy > 0 && bounce { bounceVertical() }
                if s.vy > 0 { s.vy = (Self.magnitude(s.vx) >> 1) &+ 0x100; s.groundKind = kindByte }
                if s.slip > 0 && !s.slideLatch && !bounce {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slideMinus(s.vx, s.slip, Self.slide12)
                    let up = 0 &- (s.vx >> 1)
                    if up < s.vy { s.vy = up }
                }
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x24, 0x25:
            var sf = h((s.x + lc) - X) >> 1
            if k == 0x24 { sf = Self.limit(h(0x20 - sf), 0x10, 0x20) } else { sf = Self.limit(h(0x10 - sf), 0, 0x10) }
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x26, 0x27:
            var sf = h((s.x + rc) - X) >> 1
            if k == 0x26 { sf = Self.limit(sf, 0, 0x10) } else { sf = Self.limit(h(sf + 0x10), 0x10, 0x20) }
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x28, 0x29:
            let t = h((s.x + lc) - X)
            let v = k == 0x28 ? h(t - 0x10) : t
            let sf = Self.limit(h(v * -2 + 0x20), 0, 0x20)
            if (k != 0x29 || t < 0x11) && y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x2a, 0x2b:
            let t = h((s.x + rc) - X)
            let v = k != 0x2a ? h(t - 0x10) : t
            let sf = Self.limit(h(v * 2), 0, 0x20)
            if (k != 0x2b || 0xf < t) && y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x2c, 0x2d:
            let t = h((s.x + lc) - X)
            let v = k != 0x2d ? h(t - 0x10) : t
            let sf = Self.limit(h(v * 2), 0, 0x20)
            if (k != 0x2d || t < 0x11) && sf + Y < y0 + r.bottom {
                if bounce { bounceVertical() }
                // No `vy > 0` test: a rising sprite is snapped onto the surface (§14 item 4, raw `10039824..10039844`).
                s.vy = Self.magnitude(s.vx) &* 2 &+ 0x100
                s.groundKind = kindByte
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slidePlus(s.vx, s.slip, Self.slide21)
                    if s.vy < s.vy << 1 { s.vy = s.vx << 1 }
                }
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x2e, 0x2f:
            let t = h((s.x + rc) - X)
            let v = k != 0x2e ? h(t - 0x10) : t
            let sf = Self.limit(h(v * -2 + 0x20), 0, 0x20)
            if (k != 0x2f || 0xf < t) && sf + Y < y0 + r.bottom {
                if bounce { bounceVertical() }
                s.vy = Self.magnitude(s.vx) &* 2 &+ 0x100
                s.groundKind = kindByte
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slideMinus(s.vx, s.slip, Self.slide21)
                    if s.vy &* -2 < s.vy { s.vy = s.vx &* -2 }
                }
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x32...0x35:
            let t = h((s.x + lc) - X)                                  // not clamped
            let sf: Int
            switch k {
            case 0x32: sf = t >> 2
            case 0x33: sf = h((t + 0x20) >> 2)
            case 0x34: sf = h((t + 0x40) >> 2)
            default: sf = h((t + 0x60) >> 2)
            }
            if sf + Y < y0 + r.bottom {
                if s.vy > 0 && bounce { bounceVertical() }
                if s.vy > 0 { s.vy = (Self.magnitude(s.vx) >> 1) &+ 0x100; s.groundKind = kindByte }
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slidePlus(s.vx, s.slip, Self.slide14)
                    let half = s.vx >> 1
                    if s.vy < half && !bounce { s.vy = half }
                }
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x36...0x39:
            let t = h((s.x + lc) - X)
            let base = h((0x20 - t) >> 2)
            let sf: Int
            switch k {
            case 0x36: sf = h(base + 0x18)
            case 0x37: sf = h(base + 0x10)
            case 0x38: sf = h(base + 8)
            default: sf = base
            }
            if sf + Y < y0 + r.bottom {
                if s.vy > 0 && bounce { bounceVertical() }
                if s.vy > 0 { s.vy = (Self.magnitude(s.vx) >> 1) &+ 0x100; s.groundKind = kindByte }
                if s.slip > 0 && !s.slideLatch {
                    s.slideLatch = true
                    slid = true
                    s.vx = Self.slideMinus(s.vx, s.slip, Self.slide14)
                    let half = s.vx >> 1                               // not mirrored (§9.2)
                    if s.vy < half && !bounce { s.vy = half }
                }
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        default:
            // 0x30, 0x31, 0x3a, 0x3b: no case. (The `0xb < k < 0x20` copy into `+0x8`/`+0x6` is unreachable.)
            break
        }

        if hit {
            if slid && !bounce && world.playerID == id {               // `cmplw r31, *_DAT_1009fdd8`
                if s.vy < 0 { s.vy = 0 }
                if (0x13...0x14).contains(k) {
                    s.y = h(s.y + 1)
                } else {
                    s.y = h(s.y + 2)
                    if s.vy > 0 { s.vy &+= 0x200 }
                }
            }
            s.oneWayLanded = false
            if entryX256 >> 8 != Int32(s.x) { s.x256 = Int32(s.x) << 8 }
            if entryY256 >> 8 != Int32(s.y) { s.y256 = Int32(s.y) << 8 }
            if material > 0 { s.material = Int16(material) }
        }
        world.active.update(id: id) { $0 = s }
        return hit
    }
}

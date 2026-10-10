import Foundation

extension TileSolver {
    /// `.WallBounceBG(s, kind, pos, vCentre, factor, rect, _, bounce) @ 1003a2e8` (decompile l. 34114–34792;
    /// player-states-2 §10.1): the one-way BG solver the tile callbacks call with `kind − 100` for BG kinds 100…199.
    ///
    /// - No hundreds loop; `k < 0 ∨ k > 0x3c` → no collision. Integer x/y refreshed from 24.8. The mover rect is the
    ///   **uncentred** rect at the refreshed position; `k < 0x30`: it must meet `hotRects.perTile[k]` at (X, Y) (the
    ///   kind-indexed quirk). `k == 0x3c` → kind 3 at `pos.y − 8`.
    /// - Floors land only from above: kind 3 needs `Bprev = y + bottom − (vy >> 8) ≤ Y + 17`; slopes 0xc, 0xf,
    ///   0x20…0x23, 0x2c…0x2f need `Bprev ≤ Y + s + 3` and sample the surface at the previous x (`x − (vx >> 8)`; kind
    ///   0xc takes `vy >> 8`, §14 item 3); they land with `.WallBounce`'s `vy` rule only when `vy > 0` and slide on ice
    ///   with no `vy` coupling.
    /// - Kinds 4 / 7 revert x/y to `+0x8`/`+0x6` first; `(Y+32 − B) < (L − X)` (4) / `(X+32 − R)` (7) on the pre-revert
    ///   rect → return "hit" at once with only that revert (no `+0xd0`, no re-sync); else, when `y + bottom > Y + 16`,
    ///   land on Y + 16 if `Bprev ≤ Y + 19` or report no hit; otherwise (`y + bottom ≤ Y + 16`) a hit with the revert.
    /// - Ceilings 0xd, 0xe, 0x24…0x2b two-way as `.WallBounce`, at the previous x. Composites 0x10…0x1f choose a base
    ///   kind (tests below, the dump's) and call `.WallBounce` (the two-way solver).
    /// - Other kinds (0, 1, 2, 5, 6, 8…0xb, 0x30…0x3b): no collision.
    /// - On a hit: `+0xd0 = 1` and both 24.8 coordinates re-synced from the integers (sub-pixel lost).
    @discardableResult
    public func wallBounceBG(_ id: Int, kind kindIn: Int, tile pos: inout TilePos, vCentre: Int, factor: Int16,
                             rect r: IdleSprites.Rect, bounce: Bool) -> Bool {
        let h = Self.short16
        guard var s = world.active.sprite(id: id) else { return false }
        var k = Int(Int16(truncatingIfNeeded: kindIn))
        guard k >= 0, k <= 0x3c else { return false }
        s.x = SpriteWorld.pixel(s.x256)
        s.y = SpriteWorld.pixel(s.y256)
        // `auStack_7e`: the uncentred mover rect at the refreshed (pre-revert) position.
        let M = IdleSprites.Rect(top: h(r.top + s.y), left: h(r.left + s.x), bottom: h(r.bottom + s.y),
                                 right: h(r.right + s.x))
        if k < 0x30 {
            let e = hotRects.perTile[k]
            let tileRect = IdleSprites.Rect(top: h(pos.y + e.top), left: h(pos.x + e.left), bottom: h(pos.y + e.bottom),
                                            right: h(pos.x + e.right))
            guard M.intersects(tileRect) else {
                put(id) { $0 = s }
                return false
            }
        }
        if k == 0x3c {
            k = 3
            pos.y = h(pos.y - 8)
        }
        let X = pos.x, Y = pos.y
        let y0 = s.y                                                   // iVar1
        let Y16 = Y + 0x10                                             // iVar4
        let Y16h = h(Y16)                                              // iVar8
        let X16h = h(X + 0x10)                                         // sVar3
        let kindByte = UInt8(truncatingIfNeeded: k)
        let f = Int32(factor)
        var hit = false

        func bounceVertical() { s.vx = (s.vx &* f) >> 8; s.vy = 0 &- ((s.vy &* f) >> 8) }
        func ceiling() {
            if s.vy < 0 && bounce { bounceVertical() }
            if s.vy < 0 { s.ceilingHit = kindByte; s.vy = 0 }
        }
        /// `rect.bottom + (y − (vy >> 8)) ≤ limit` — the previous bottom (`vy >> 8` as an int).
        func fromAbove(_ limit: Int) -> Bool { r.bottom + (s.y - Int(s.vy >> 8)) <= limit }
        /// The previous left / right edge offset from X: `rect.edge + (x − (short)(vx >> 8)) − X`.
        func prevEdge(_ edge: Int) -> Int { h(edge + (s.x - Self.short8(s.vx)) - X) }
        func recurse(_ base: Int) -> Bool {
            put(id) { $0 = s }
            let result = wallBounce(id, kind: base, tile: &pos, vCentre: vCentre, factor: factor, rect: r, bounce: bounce)
            s = world.active.sprite(id: id) ?? s
            return result
        }
        func land(_ vyRule: (Int32) -> Int32) {
            if s.vy > 0 && bounce { bounceVertical() }
            if s.vy > 0 { s.vy = vyRule(Self.magnitude(s.vx)); s.groundKind = kindByte }
        }
        func slide(plus: Bool, _ factor: Double) {
            guard s.slip > 0, !s.slideLatch else { return }
            s.slideLatch = true
            s.vx = plus ? Self.slidePlus(s.vx, s.slip, factor) : Self.slideMinus(s.vx, s.slip, factor)
        }

        switch k {
        case 3:
            if Y16 < y0 + r.bottom && fromAbove(Y + 0x11) {
                if s.vy > 0 && bounce { s.vy = 0 &- ((s.vy &* f) >> 8) }
                if s.vy > 0 { s.vy = 0; s.groundKind = kindByte }
                hit = true
                s.y = h(Y16 - r.bottom)
            }
        case 4, 7:
            hit = true
            s.x = s.oldPosition.x
            s.y = s.oldPosition.y
            let wall = k == 4 ? h(M.left - X) : h((X + 0x20) - M.right)
            if h((Y + 0x20) - M.bottom) < wall {
                put(id) { $0 = s }                 // `return uVar2`: the revert only
                return true
            }
            if Y + 0x10 < s.y + r.bottom {
                if Y + 0x13 < r.bottom + (s.y - Int(s.vy >> 8)) {
                    hit = false
                } else {
                    if s.vy > 0 && bounce { s.vy = 0 &- ((s.vy &* f) >> 8) }
                    if s.vy > 0 { s.vy = 0; s.groundKind = kindByte }
                    hit = true
                    s.y = h(Y16 - r.bottom)
                }
            }
        case 0xc:
            // The previous x is taken with **vy** (`lwz r5,0x2c`, raw `1003a708`) — §14 item 3.
            let sf = Self.limit(h(r.left + (s.x - Self.short8(s.vy)) - X), 0, 0x20)
            if sf + Y < y0 + r.bottom && fromAbove(sf + Y + 3) {
                land { $0 &+ 0x100 }
                slide(plus: true, Self.slide45)
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0xd:
            let sf = Self.limit(h(0x20 - prevEdge(r.left)), 0, 0x20)
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0xe:
            let sf = Self.limit(prevEdge(r.right), 0, 0x20)
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0xf:
            let sf = Self.limit(h(0x20 - prevEdge(r.right)), 0, 0x20)
            if sf + Y < y0 + r.bottom && fromAbove(sf + Y + 3) {
                land { $0 &+ 0x100 }
                slide(plus: false, Self.slide45)
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x10...0x1f:
            // The dump's tests: previous-x edges (`x − (vx >> 8)`, int) for the column tests; y-based for 0x11, 0x13,
            // 0x14, 0x16.
            let pL = r.left + (s.x - Int(s.vx >> 8)), pR = r.right + (s.x - Int(s.vx >> 8))
            let T = y0 + r.top, B = y0 + r.bottom
            switch k {
            case 0x10: hit = recurse(pL < X16h ? 3 : 0xc)
            case 0x11: hit = recurse(Y16h < T ? 0xd : 0)
            case 0x12: hit = recurse(X16h < pR ? 1 : 0xe)
            case 0x13:
                if Y16h < B {
                    hit = recurse(2)
                } else if 0x10 < h(s.y + vCentre) + r.bottom {
                    hit = recurse(0xf)
                }
            case 0x14: hit = recurse(Y16h < B ? 0 : 0xc)
            case 0x15: hit = recurse(pL < X16h ? 1 : 0xd)
            case 0x16: hit = recurse(T < Y16h ? 2 : 0xe)
            case 0x17: hit = recurse(X16h < pR ? 3 : 0xf)
            case 0x18: hit = recurse(X16h < pL ? 3 : 0xc)
            case 0x19: hit = recurse(pL < X16h ? 0 : 0xd)
            case 0x1a: hit = recurse(pR < X16h ? 1 : 0xe)
            case 0x1b: hit = recurse(X16h < pR ? 2 : 0xf)
            case 0x1c: hit = recurse(pL < X16h ? 0 : 0xc)
            case 0x1d: hit = recurse(X16h < pL ? 1 : 0xd)
            case 0x1e: hit = recurse(X16h < pR ? 2 : 0xe)
            default: hit = recurse(pR < X16h ? 3 : 0xf)                // 0x1f
            }
        case 0x20, 0x21:
            var sf = prevEdge(r.left) >> 1
            if k == 0x20 { sf = Self.limit(sf, 0, 0x10) } else { sf = Self.limit(h(sf + 0x10), 0x10, 0x20) }
            if sf + Y < y0 + r.bottom && fromAbove(sf + Y + 3) {
                land { ($0 >> 1) &+ 0x100 }
                slide(plus: true, Self.slide12)
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x22, 0x23:
            var sf = prevEdge(r.right) >> 1
            if k == 0x22 { sf = Self.limit(h(0x20 - sf), 0x10, 0x20) } else { sf = Self.limit(h(0x10 - sf), 0, 0x10) }
            sf = Self.limit(sf, 0, 0x20)
            if sf + Y < y0 + r.bottom && fromAbove(sf + Y + 3) {
                land { ($0 >> 1) &+ 0x100 }
                slide(plus: false, Self.slide12)
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x24, 0x25:
            var sf = prevEdge(r.left) >> 1
            if k == 0x24 { sf = Self.limit(h(0x20 - sf), 0x10, 0x20) } else { sf = Self.limit(h(0x10 - sf), 0, 0x10) }
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x26, 0x27:
            var sf = prevEdge(r.right) >> 1
            if k == 0x26 { sf = Self.limit(sf, 0, 0x10) } else { sf = Self.limit(h(sf + 0x10), 0x10, 0x20) }
            if y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x28, 0x29:
            let t = prevEdge(r.left)
            let v = k == 0x28 ? h(t - 0x10) : t
            let sf = Self.limit(h(v * -2 + 0x20), 0, 0x20)
            if (k != 0x29 || t < 0x11) && y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x2a, 0x2b:
            let t = prevEdge(r.right)
            let v = k != 0x2a ? h(t - 0x10) : t
            let sf = Self.limit(h(v * 2), 0, 0x20)
            if (k != 0x2b || 0xf < t) && y0 + r.top < sf + Y {
                ceiling()
                hit = true
                s.y = h(Y + sf - r.top)
            }
        case 0x2c, 0x2d:
            let t = prevEdge(r.left)
            let v = k != 0x2d ? h(t - 0x10) : t
            let sf = Self.limit(h(v * 2), 0, 0x20)
            if (k != 0x2d || t < 0x11) && sf + Y < y0 + r.bottom && fromAbove(sf + Y + 3) {
                land { $0 &* 2 &+ 0x100 }
                slide(plus: true, Self.slide21)
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        case 0x2e, 0x2f:
            let t = prevEdge(r.right)
            let v = k != 0x2e ? h(t - 0x10) : t
            let sf = Self.limit(h(v * -2 + 0x20), 0, 0x20)
            if (k != 0x2f || 0xf < t) && sf + Y < y0 + r.bottom && fromAbove(sf + Y + 3) {
                land { $0 &* 2 &+ 0x100 }
                slide(plus: false, Self.slide21)
                hit = true
                s.y = h(Y + sf - r.bottom)
            }
        default:
            break
        }

        if hit {
            s.oneWayLanded = true
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
        }
        put(id) { $0 = s }
        return hit
    }
}

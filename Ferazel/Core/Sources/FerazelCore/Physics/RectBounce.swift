import Foundation

/// Sprite-vs-sprite solids (physics-sprites §8.1): `.PlatformBounce @ 100377c4` → `.RectBounce @ 1003e490`, the
/// call every mover's hit callback makes against a solid. Rects are QuickDraw (top, left, bottom, right); `+0x34` is
/// the hot rect in face-local px; all coordinate arithmetic is i16 as the dump's `short`s.
extension SpriteWorld {
    @inline(__always) private static func h(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    /// `.RectBounce(mover, solid, centre, f, rect, bounce) @ 1003e490` (decompile l. 36196–36442). `centre` is
    /// `param_3` (the mover's centre offset, [0] = y, [1] = x), `rect` `param_5` (the mover's rect in face-local px).
    /// Returns 1 landed (from above with vy > 0, bounce clear — M l. 36296–36300), 2 hit from below, else 0.
    ///
    /// - Push `P = (m+0x13c · ((s+0x138 · (m.vx − s.vx)) >> 8)) >> 8` from the entry velocities.
    /// - Height of the solid's top above its bottom: flat `s.bottom − s.top`; sloped (`+0xd2`/`+0xd4` ≠ −1000)
    ///   `(d2·(w − o) + d4·o) / w` with o = the mover's rect centre x − the solid's left, w = the rect width, and the
    ///   slack 0x20 instead of 8 (l. 36239–36247).
    /// - One-way (`+0x185`): only when the mover's previous bottom `rect.bottom + y − (vy >> 8)` ≤ slack + the top.
    /// - Solid rect (bottom forced ≥ top + 1) meets the mover rect (`.SectRectFast`), else 0. The side is chosen from
    ///   the mover's previous centre `pos + centre − (v >> 8)` against the solid's centre lines and the gaps of the
    ///   previous hot rect (`+0x34..+0x3a`): from a side → if moving in, the solid is pushed by P (`+0x138 > 0`), vx 0
    ///   (bounce: vx = −vx·f >> 8, vy = vy·f >> 8), x snapped (not on a one-way solid); from above → vy > 0: vy 0, 1
    ///   (bounce: vx = vx·f >> 8, vy = −vy·f >> 8), y on the top unless a one-way miss; from below (not one-way) →
    ///   vy < 0: vy 0 (or bounce), 2, y under the bottom. A moved pixel coordinate resets its 24.8 copy.
    /// - Landed on a sloped top: `+0xd6 = ((d2 − d4) ± 1) << 8 / w` (i16), 0 when d2 == d4.
    @discardableResult
    public func rectBounce(mover mID: Int, solid sID: Int, centre c: SpriteSlot.Point, factor f: Int32,
                           rect r: IdleSprites.Rect, bounce: Bool) -> Int16 {
        guard var m = active.sprite(id: mID), var s = active.sprite(id: sID) else { return 0 }
        let h = Self.h
        var result: Int16 = 0
        var width = 0                                                  // iVar16
        var slack = 8                                                  // sVar13
        let bottomRel = s.hotRect.bottom                               // iVar11
        // iVar17 (l. 36233–36235): `1003e4d8 mullw` mass·Δvx, `1003e4ec srawi 8`, `1003e4f4 mullw` F·t,
        // `1003e500 srawi 8`. Parenthesised in full: Swift's `>>` binds tighter than `&*`.
        let t = (Int32(s.pushMass) &* (m.vx &- s.vx)) >> 8
        let push = (Int32(m.pushForce) &* t) >> 8
        var height = bottomRel - s.hotRect.top                         // iVar12
        let sloped = s.surfaceLeft != -1000 || s.surfaceRight != -1000
        if sloped {
            let o = h(h(m.x + h((r.left + r.right) >> 1)) - s.hotRect.left - s.x)
            width = s.hotRect.right - s.hotRect.left
            height = width == 0 ? 0 : (Int(s.surfaceLeft) * (width - o) + Int(s.surfaceRight) * o) / width
            slack = 0x20
        }
        let previousBottom = r.bottom + (m.y - Int(m.vy >> 8))
        guard !s.oneWay || previousBottom <= slack + ((h(s.y) + bottomRel) - h(height)) else { return 0 }

        let solidBottom = h(s.y) + bottomRel
        var solid = IdleSprites.Rect(top: h(solidBottom - height), left: h(s.x + s.hotRect.left),
                                     bottom: h(solidBottom), right: h(s.x + s.hotRect.right))
        if solid.bottom <= solid.top { solid.bottom = solid.top + 1 }
        let moving = IdleSprites.Rect(top: h(m.y + r.top), left: h(m.x + r.left), bottom: h(m.y + r.bottom),
                                      right: h(m.x + r.right))
        if moving.intersects(solid) {
            let vx0 = m.vx                                             // iVar11
            let sx = s.x, sy = s.y                                     // sVar2, sVar3
            let solidLeft = h(sx + s.hotRect.left)                     // sVar7
            let mx = m.x, my = m.y                                     // sVar4, sVar5
            let dxPrev = h(Int(vx0 >> 8))                              // sVar6
            let solidTop = h(sy + s.hotRect.top)                       // sVar8
            let solidMidY = h(solidTop + h((s.hotRect.bottom - s.hotRect.top) >> 1))     // sVar15
            let dyPrev = h(Int(m.vy >> 8))                             // sVar9
            let prevMidY = h(my + c.y - dyPrev)                        // sVar14
            let prevMidX = h(mx + c.x - dxPrev)
            let solidMidX = h(solidLeft + h((s.hotRect.right - s.hotRect.left) >> 1))
            let gapAbove = h(solidTop - (m.hotRect.bottom + (my - dyPrev)))
            let gapBelow = h((m.hotRect.top + (my - dyPrev)) - (sy + s.hotRect.bottom))
            let gapLeft = h((solidLeft - (m.hotRect.right + (mx - dxPrev))) - 1)
            let gapRight = h(((m.hotRect.left + (mx - dxPrev)) - (sx + s.hotRect.right)) - 1)

            func sideStop() {
                if s.pushMass > 0 { s.vx &+= push }
                if !bounce {
                    m.vx = 0
                } else {
                    m.vx = (0 &- (m.vx &* f)) >> 8
                    m.vy = (m.vy &* f) >> 8
                }
            }
            func fromLeft() {
                guard !s.oneWay else { return }
                if m.vx > 0 { sideStop() }
                m.x = h(solid.left - r.right)
            }
            func fromRight() {
                guard !s.oneWay else { return }
                if m.vx < 0 { sideStop() }
                m.x = h(solid.right - r.left)
            }
            func fromAbove() {
                if m.vy > 0 {
                    if !bounce {
                        m.vy = 0
                        result = 1
                    } else {
                        m.vx = (vx0 &* f) >> 8
                        m.vy = (0 &- (m.vy &* f)) >> 8
                    }
                }
                if result == 1 || !s.oneWay { m.y = h(solid.top - r.bottom) }
            }
            func fromBelow() {
                if m.vy < 0 {
                    if !bounce {
                        m.vy = 0
                    } else {
                        m.vx = (vx0 &* f) >> 8
                        m.vy = (0 &- (m.vy &* f)) >> 8
                    }
                }
                result = 2
                m.y = h(solid.bottom - r.top)
            }

            if prevMidX < solidMidX {
                if prevMidY < solidMidY {
                    if gapAbove < gapLeft { fromLeft() } else { fromAbove() }
                } else if gapBelow < gapLeft {
                    fromLeft()
                } else if !s.oneWay {
                    fromBelow()
                }
            } else if prevMidY < solidMidY {
                if gapAbove < gapRight { fromRight() } else { fromAbove() }
            } else if !s.oneWay {
                if gapBelow < gapRight { fromRight() } else { fromBelow() }
            }
            if mx != m.x { m.x256 = Int32(m.x) << 8 }
            if my != m.y { m.y256 = Int32(m.y) << 8 }
        }
        if result == 1 && sloped {
            if s.surfaceLeft == s.surfaceRight {
                m.slope = 0
            } else {
                var v = Int16(truncatingIfNeeded: Int(s.surfaceLeft) - Int(s.surfaceRight))
                v = v < 0 ? v &- 1 : v &+ 1
                v = Int16(truncatingIfNeeded: Int(v) << 8)
                m.slope = width == 0 ? 0 : Int16(truncatingIfNeeded: Int(v) / width)
            }
        }
        active.update(id: sID) { $0 = s }
        active.update(id: mID) { $0 = m }
        return result
    }

    /// `.PlatformBounce(mover, solid, centre, f, rect, bounce) @ 100377c4` (decompile l. 32985–33078). `centre` nil →
    /// the mover's hot-rect centre offset. With a surface function (`solid+0x1e8`, `surface`): the solid's top
    /// `+0x34` is replaced by `surface(solid, moverCentreX − solid.x)` while the mover's hot rect is tested against the
    /// solid there — a miss is no contact — and restored after `.RectBounce`. On a landing (1, bounce clear): mover
    /// `+0xd0 = 1` if the solid is one-way; with a surface function `+0xd6 = −0x100 / 0 / 0x100` by vx < −0x100 /
    /// ≤ 0x100 / above; the mover's 24.8 x **restored** (a landing never shoves sideways) and `+0xc`/`+0xa`
    /// refreshed; `+0xcd = 1`, `+0xce = 3`, `+0xdc = solid`; solid `+0xe0 = mover`, `+0x186 = 1`; solid sag
    /// `vy += entry vy · +0x13a >> 8` when `+0x13a > 0` and the entry vy > 0x200. Return 2 sets `+0xcf = 1`.
    /// - Parameter surface: `solid+0x1e8` // later: W3 (ropes, rope bridge).
    @discardableResult
    public func platformBounce(mover mID: Int, solid sID: Int, centre: SpriteSlot.Point? = nil, factor f: Int32,
                               rect r: IdleSprites.Rect, bounce: Bool,
                               surface: ((SpriteWorld, Int, Int) -> Int16)? = nil) -> Int16 {
        guard let m0 = active.sprite(id: mID), let s0 = active.sprite(id: sID) else { return 0 }
        let h = Self.h
        var result: Int16 = 0
        var contact = true
        let entryVY = m0.vy                                            // iVar10
        let savedTop = s0.hotRect.top                                  // uVar1
        let mr = m0.hotRect
        let c = centre ?? SpriteSlot.Point(x: h(mr.left + h((mr.right - mr.left) >> 1)),
                                           y: h(mr.top + h((mr.bottom - mr.top) >> 1)))
        if let surface {
            let moving = IdleSprites.Rect(top: h(m0.y + mr.top), left: h(m0.x + mr.left), bottom: h(m0.y + mr.bottom),
                                          right: h(m0.x + mr.right))
            let top = surface(self, sID, (m0.x + c.x) - s0.x)
            active.update(id: sID) { $0.hotRect.top = Int(top) }
            let s = active.sprite(id: sID) ?? s0
            let solid = IdleSprites.Rect(top: h(s.y + s.hotRect.top), left: h(s.x + s.hotRect.left),
                                         bottom: h(s.y + s.hotRect.bottom), right: h(s.x + s.hotRect.right))
            if !moving.intersects(solid) {
                active.update(id: sID) { $0.hotRect.top = savedTop }
                contact = false
            }
        }
        guard contact else { return 0 }
        let savedX = m0.x256                                           // uVar8
        result = rectBounce(mover: mID, solid: sID, centre: c, factor: f, rect: r, bounce: bounce)
        active.update(id: sID) { $0.hotRect.top = savedTop }
        if !bounce && result == 1 {
            let solid = active.sprite(id: sID)
            active.update(id: mID) { m in
                if solid?.oneWay == true { m.oneWayLanded = true }
                if surface != nil {
                    m.slope = m.vx < -0x100 ? -0x100 : (m.vx < 0x101 ? 0 : 0x100)
                }
                m.x256 = savedX
                m.x = Self.pixel(m.x256)
                m.y = Self.pixel(m.y256)
                m.onSprite = 1
                m.groundKind = 3
                m.ridden = sID
            }
            active.update(id: sID) { s in
                s.rider = mID
                s.ridingLatch = true
                if s.sag > 0 && entryVY > 0x200 { s.vy &+= (entryVY &* Int32(s.sag)) >> 8 }
            }
        } else if result == 2 {
            active.update(id: mID) { $0.ceilingHit = true }
        }
        return result
    }
}

import Foundation

/// The per-sprite routines most Handles call at their start and end, and the two velocity helpers (physics §2;
/// plan F2). Positions are 24.8 (`+0x14`/`+0x1c`), the pixel copies `+0xc`/`+0xa` are `(i16)(pos >> 8)`.
extension SpriteWorld {
    /// `(short)((uint)pos >> 8)`: the pixel copy of a 24.8 position.
    @inline(__always) static func pixel(_ pos: Int32) -> Int { Int(Int16(truncatingIfNeeded: pos >> 8)) }

    /// `.StandardSpriteHandles @ 10036854` (decompile l. 32420–32610), at the start of most Handles. In order:
    /// - `+0x116` (invulnerable) and `+0xaa` (flash) count down to 0; a negative `+0x130` (re-entry) counts up.
    /// - The draw clips reset (`+0x1bc` 0, `+0x1b6` 0, `+0x1ba` 32000, `+0x1b8` 32000), `+0x1b3 = 0`,
    ///   `+0xcd = +0xce`, `+0x180 = 0`, `+0x92 = 0`.
    /// - While `+0x118 < 0x1d`: the **water current** — in water last frame (`+0x11c ≠ 0`), water kind `+0x128 == 0`
    ///   and `+0x8a`: `+0x94` < 33 → `+0x94 += 1`, push = hdr`+0x2714`·`+0x94` / 33 (C division, i16), else the full
    ///   hdr`+0x2714`; no push while riding (`+0xdc`); `+0x14 += push`. Otherwise `+0x94` counts down to 0. Then
    ///   `+0x120 = +0x11c` and `+0x11c = 0`.
    /// - While `+0x90 > 0`: wind from the FG overlay cell under the centre (`.GetFGOverlay1Tile` 0…15,
    ///   `.LookupModedImpulse`). // later: wind — no overlay wind cell on levels 1–2 (first on level 10, 103 cells;
    ///   probe 2026-10-10) and no Phase-2 task builds `.LookupModedImpulse`; the branch is skipped here.
    /// - **Carry** while riding (`+0xdc`): `+0xce = 3`; `+0x14 += (solid.x − solid.drawnX)·256`;
    ///   `+0x1c = (solid.y − solid.drawnY)·256 + +0x1c + 0x100`; `+0xc`/`+0xa` refreshed; the siblings `+0x1d4`,
    ///   `+0x1d8` get the same x delta (x only). drawnX/drawnY = the solid's `+0xc6`/`+0xc4`, i.e. its `previous`
    ///   copy (0 before its first draw, `.InitSprite`).
    /// - `+0x140 = 0`, `+0xd8 = 0`.
    public func standardSpriteHandles(_ id: Int) {
        guard var s = active.sprite(id: id) else { return }
        if s.invulnerable > 0 { s.invulnerable -= 1 }
        if s.flash > 0 { s.flash -= 1 }
        if s.reentry < 0 { s.reentry += 1 }
        s.clip.top = 0
        s.clip.left = 0
        s.clip.bottom = 32000
        s.clip.right = 32000
        s.burning = false
        s.onSprite = s.groundKind
        s.radialLatch = false
        s.inWind = false
        if s.waterGate < 0x1d {
            if s.waterRow == 0 || s.waterKind != 0 || !s.currentApplies {
                if s.currentRamp > 0 { s.currentRamp -= 1 }
            } else {
                let current = level.header.waterCurrent                 // `*(*_DAT_100a0058) + 0x2714`
                var push: Int16
                if s.currentRamp < 0x21 {
                    s.currentRamp += 1
                    push = Int16(truncatingIfNeeded: (Int32(current) * Int32(s.currentRamp)) / 0x21)
                } else {
                    push = current
                }
                if s.ridden != nil { push = 0 }
                s.x256 &+= Int32(push)
            }
            s.lastWater = s.waterRow
            s.waterRow = 0
        }
        if s.windScale > 0 {
            // later: wind (`.GetFGOverlay1Tile`/`2Tile` at the centre cell, `.LookupModedImpulse`, the `+0x96` ramp
            // to 33, `+0x98`, `+0x92 = 1`; decompile l. 32490–32570). Unreached on levels 1–2.
        }
        if let solidID = s.ridden {
            let solid = active.sprite(id: solidID)
            let sx = solid?.x ?? 0, sy = solid?.y ?? 0
            let drawnX = solid?.previous?.x ?? 0, drawnY = solid?.previous?.y ?? 0
            let dx = Int32(truncatingIfNeeded: Int(Int16(truncatingIfNeeded: sx)) - Int(Int16(truncatingIfNeeded: drawnX)))
            let dy = Int32(truncatingIfNeeded: Int(Int16(truncatingIfNeeded: sy)) - Int(Int16(truncatingIfNeeded: drawnY)))
            s.groundKind = 3
            s.x256 &+= dx &* 0x100
            s.y256 = dy &* 0x100 &+ s.y256 &+ 0x100
            s.x = Self.pixel(s.x256)
            s.y = Self.pixel(s.y256)
            active.update(id: id) { $0 = s }
            for sib in [s.siblings.first, s.siblings.second].compactMap({ $0 }) {
                active.update(id: sib) { c in
                    c.x256 &+= dx &* 0x100
                    c.x = Self.pixel(c.x256)
                }
            }
            s = active.sprite(id: id) ?? s
        }
        s.underwaterDone = false
        s.material = 0
        active.update(id: id) { $0 = s }
    }

    /// `.StandardSpriteCleanup @ 10036e0c` (decompile l. 32627–32700), at the end of most Handles:
    /// - w = the face's width (face `+6`), 0x80 without a face.
    /// - Left the water this frame (`+0x120 ≠ 0`, `+0x11c == 0`): `.Splash(s, 4)` (`exitSplash`) and `+0x144 = 0`.
    /// - The centre `+0x10 = x + r.left + (r.right − r.left) >> 1`, `+0xe = y + r.top + (r.bottom − r.top) >> 1`.
    /// - `+0xdc = 0`; `+0xe0 = 0` unless `+0x186`; `+0xd6 = 0`.
    /// - `+0x1a2 ≠ 0` → `.HandleBurn` // later: burn-away (no Phase-2 writer of `+0x1a2`).
    /// - `+0x1a8 ≠ 0` with a face → `.ParticleGlow` // later: particles (only the player sets `+0x1a8`, by spells).
    /// - The occluder clip: when x + w + 8 ≥ `+0x1be`, x − 8 ≤ `+0x1c0` and `+0x1c4` ≤ cy ≤ `+0x1c2`: a sprite whose
    ///   centre x + w/2 is left of the occluder's middle gets `+0x1b8 = +0x1be − x` (32000 when beyond the face
    ///   width, ≥ 0), else `+0x1b6 = +0x1c0 − x` (≤ the face width, ≥ 0); the clamps only with a face.
    ///   The occluder is set by W2b (wall tunnels); E2 draws the clip.
    ///
    /// - Parameter faceWidth: a face's width (face `+6`) — Core has no face records [MED: the session passes the
    ///   frame width].
    /// - Parameter exitSplash: `.Splash(s, 4)` // later: E1a.
    public func standardSpriteCleanup(_ id: Int, faceWidth: (FaceRef) -> Int,
                                      exitSplash: (SpriteWorld, Int) -> Void = { _, _ in }) {
        guard let start = active.sprite(id: id) else { return }
        var w = 0x80
        if let f = start.face { w = faceWidth(f) }
        if start.lastWater != 0 && start.waterRow == 0 {
            exitSplash(self, id)
            active.update(id: id) { $0.quicksandDepth = 0 }
        }
        guard var s = active.sprite(id: id) else { return }
        let r = s.hotRect
        s.centre.x = Int(Int16(truncatingIfNeeded: s.x + r.left + ((r.right - r.left) >> 1)))
        s.centre.y = Int(Int16(truncatingIfNeeded: s.y + r.top + ((r.bottom - r.top) >> 1)))
        s.ridden = nil
        if !s.ridingLatch { s.rider = nil }
        s.slope = 0
        if s.burnRow != 0 {
            // later: `.HandleBurn` (burn-away; no Phase-2 writer of `+0x1a2`).
        }
        if s.glowChance != 0, s.face != nil {
            // later: `.ParticleGlow` (no Phase-2 writer of `+0x1a8`).
        }
        let x = s.x
        let o = s.occluder
        if Int(o.left) <= x + w + 8, x - 8 <= Int(o.right), o.top <= Int16(truncatingIfNeeded: s.centre.y),
           Int16(truncatingIfNeeded: s.centre.y) <= o.bottom {
            if x + (w >> 1) < (Int(o.left) + Int(o.right)) >> 1 {
                s.clip.right = Int(Int16(truncatingIfNeeded: Int(o.left) - x))
                if let f = s.face {
                    if faceWidth(f) < s.clip.right { s.clip.right = 32000 }
                    if s.clip.right < 0 { s.clip.right = 0 }
                }
            } else {
                s.clip.left = Int(Int16(truncatingIfNeeded: Int(o.right) - x))
                if let f = s.face {
                    let fw = faceWidth(f)
                    if fw < s.clip.left { s.clip.left = fw }
                    if s.clip.left < 0 { s.clip.left = 0 }
                }
            }
        }
        active.update(id: id) { $0 = s }
    }
}

extension SpriteSlot {
    /// `.ApplyFriction @ 100370c4 (s, f)`: vx moves toward 0 by f and stops at 0 (no overshoot).
    public mutating func applyFriction(_ f: Int16) {
        if vx > 0 {
            vx &-= Int32(f)
            if vx < 0 { vx = 0 }
        } else if vx < 0 {
            vx &+= Int32(f)
            if vx > 0 { vx = 0 }
        }
    }

    /// `.EnforceMaxSpeed @ 1003f0f0 (s, m)` (raw `1003f0f0..1003f1f0`): |vx| > m → vy = vy·m / |vx| (`mullw`,
    /// `divw`), vx = ±m; then |vy| > m → vx = vx·m / |vy|, vy = ±m (signs from the entry value of each test).
    public mutating func enforceMaxSpeed(_ m: Int32) {
        let ax = vx > 0 ? vx : 0 &- vx
        if ax > m {
            if vx > 0 {
                vy = Self.divw(vy &* m, vx)
                vx = m
            } else {
                vy = Self.divw(vy &* m, 0 &- vx)
                vx = 0 &- m
            }
        }
        let ay = vy > 0 ? vy : 0 &- vy
        if ay > m {
            if vy > 0 {
                vx = Self.divw(vx &* m, vy)
                vy = m
            } else {
                vx = Self.divw(vx &* m, 0 &- vy)
                vy = 0 &- m
            }
        }
    }

    /// `divw` (truncating; the overflow case wraps instead of trapping).
    static func divw(_ a: Int32, _ b: Int32) -> Int32 {
        b == 0 ? 0 : a.dividedReportingOverflow(by: b).partialValue
    }
}

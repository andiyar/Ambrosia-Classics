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
    /// - While `+0x90 > 0`: **wind** (6A-WD; M l. 32489–32574, raw `100369b0..10036c5c`; ENG §2.2) from the FG
    ///   overlay cell under the centre (`+0x10 >> 5`, `+0xe >> 5`; every sprite with a wind scale, not only the
    ///   player). o1 = `.GetFGOverlay1Tile` outside 0…15 → **leaving**: `+0x96 > 0` → `+0x96 − 1`, then
    ///   `+0x14 += (+0x98 · +0x96) / 33` (C division). Else o2 = `.GetFGOverlay2Tile` ≤ 0 → nothing (no ramp-down).
    ///   Else m = (o1 + 18) mod 36; the **test** impulse `.LookupModedImpulse(m, 15·o2)` opens the gates
    ///   (`windGates`, crossed on h < 0, v < 0 as the binary has them); neither → nothing. Else the **push**
    ///   `.LookupModedImpulse(m, 14·o2)`, both halves `(· +0x90) >> 8` when `+0x90 < 0xff`; `+0x96 < 33` → `+0x96 + 1`
    ///   and the x push = h′·`+0x96` / 33 (C division, i16), else h′; `+0x98 = h′` (un-ramped), `+0x92 = 1`; the
    ///   x-gate → `+0x14 += push`, the y-gate → `+0x2c += v′` (no ramp on the vertical). No random draw. Levels 1–5
    ///   have no overlay cell with o1 in 0…15, so there the branch only runs the leaving arm with `+0x96` = 0.
    /// - **Carry** while riding (`+0xdc`): `+0xce = 3`; `+0x14 += (solid.x − solid.drawnX)·256`;
    ///   `+0x1c = (solid.y − solid.drawnY)·256 + +0x1c + 0x100`; `+0xc`/`+0xa` refreshed; the siblings `+0x1d4`,
    ///   `+0x1d8` get the same x delta (x only). drawnX/drawnY = the solid's `+0xc6`/`+0xc4` (`SpriteSlot.drawnX`/
    ///   `drawnY`, copied at every draw, face or not; 0 before its first draw, `.InitSprite`). The original reads the
    ///   `+0xdc` record whether or not it is still linked (an idled solid stays linked with `+0x4c = 0` until
    ///   `.UpdateSprites` kills it, and a killed record keeps its fields): Core reads it through
    ///   `ActiveList.record(id:)`. A record Core no longer holds (dropped past `ActiveList.recordLimit`) reads as 0s —
    ///   in the original that slot may already be reused by `.MTNewSprite` (`MemoryClear`) [LOW: no Phase-2 path].
    /// - `+0x140 = 0`, `+0xd8 = 0`.
    public func standardSpriteHandles(_ id: Int) {
        guard var s = active.record(id: id) else { return }
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
        if s.windScale > 0 {                                          // `lha 0x90; cmpwi 0; ble` (raw `100369b0`)
            let col = Int(Int16(truncatingIfNeeded: s.centre.x) >> 5)
            let row = Int(Int16(truncatingIfNeeded: s.centre.y) >> 5)
            let o1 = level.overlay1(col: col, row: row)
            if o1 < 0 || 0xf < o1 {
                // Leaving (raw `10036c1c..10036c5c`): the ramp runs down on `+0x98`.
                if s.windRamp > 0 {
                    s.windRamp -= 1
                    s.x256 &+= (Int32(s.windLast) &* Int32(s.windRamp)) / 0x21
                }
            } else {
                let o2 = Int16(truncatingIfNeeded: level.overlay2(col: col, row: row))
                if o2 > 0 {
                    let m = Int16(truncatingIfNeeded: (o1 + 0x12) % 0x24)
                    let test = WaterEffects.lookupModedImpulse(mode: m, amount: o2 &* 0xf)
                    let gate = Self.windGates(v: test.v, h: test.h, vx: s.vx, vy: s.vy)
                    if gate.x || gate.y {
                        let push = WaterEffects.lookupModedImpulse(mode: m, amount: o2 &* 0xe)
                        var h = Int32(push.h), v = Int32(push.v)
                        let scale = Int32(s.windScale)
                        if scale < 0xff {                              // `cmpwi 0xff; bge` (raw `10036b80..10036b88`)
                            h = (h &* scale) >> 8
                            v = (v &* scale) >> 8
                        }
                        let dx: Int16
                        if s.windRamp < 0x21 {
                            s.windRamp += 1
                            dx = Int16(truncatingIfNeeded: (h &* Int32(s.windRamp)) / 0x21)
                        } else {
                            dx = Int16(truncatingIfNeeded: h)
                        }
                        s.windLast = Int16(truncatingIfNeeded: h)       // `+0x98` un-ramped (raw `10036be0`)
                        s.inWind = true
                        if gate.x { s.x256 &+= Int32(dx) }
                        if gate.y { s.vy &+= v }
                    }
                }
            }
        }
        if let solidID = s.ridden {
            let solid = active.record(id: solidID)
            let sx = solid?.x ?? 0, sy = solid?.y ?? 0
            let drawnX = solid?.drawnX ?? 0, drawnY = solid?.drawnY ?? 0
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
            s = active.record(id: id) ?? s
        }
        s.underwaterDone = false
        s.material = 0
        active.update(id: id) { $0 = s }
    }

    /// The wind gates (raw `10036a58..10036b44`, the signed-compare idiom `srawi`/`srwi`, `subfc`, `adde`): from the
    /// **test** impulse (v, h) and the sprite's vx `+0x24` / vy `+0x2c`, the flags that allow the x push (`r29`) and
    /// the vy push (`r28`). h ≥ 0: x-gate h ≥ vx; h < 0, v ≥ 0: x-gate vx ≥ h; v ≥ 0: y-gate v ≥ vy; h ≥ 0, v < 0:
    /// y-gate vy ≥ v. **h < 0, v < 0 is crossed, as written**: `10036a98 rlwinm r29,r6` puts the vy test (vy ≥ v)
    /// into the x-gate and `10036a9c rlwinm r28,r0` the vx test (vx ≥ h) into the y-gate (ENG §2.2 step 4; reached by
    /// o1 10…15). The h < 0, v ≥ 0 row is unreachable from a cell (o1 0…15 give modes 18…33).
    static func windGates(v: Int16, h: Int16, vx: Int32, vy: Int32) -> (x: Bool, y: Bool) {
        let v = Int32(v), h = Int32(h)
        if h < 0 {
            if v < 0 { return (vy >= v, vx >= h) }                      // crossed (raw `10036a70..10036aa0`)
            return (vx >= h, v >= vy)
        }
        if v < 0 { return (h >= vx, vy >= v) }
        return (h >= vx, v >= vy)
    }

    /// `.StandardSpriteCleanup @ 10036e0c` (decompile l. 32627–32700), at the end of most Handles:
    /// - w = the face's width (face `+6`), 0x80 without a face.
    /// - Left the water this frame (`+0x120 ≠ 0`, `+0x11c == 0`): `.Splash(s, 4)` (`exitSplash`) and `+0x144 = 0`.
    /// - The centre `+0x10 = x + r.left + (r.right − r.left) >> 1`, `+0xe = y + r.top + (r.bottom − r.top) >> 1`.
    /// - `+0xdc = 0`; `+0xe0 = 0` unless `+0x186`; `+0xd6 = 0`.
    /// - `+0x1a2 ≠ 0` → `.HandleBurn` (`Burn.handle`, EC): the top clip `+0x1bc`, the row particles, the Kill proc.
    /// - `+0x1a8 ≠ 0` with a face → `.ParticleGlow(+0xc0, (+0xa, +0xc), +0x1a6, +0x1a8, +0x17e) @ 10043ad0`
    ///   (l. 32664–32668; `ParticleGlow`, E1a; its `FastRand` draws need the face's pixels, `particleFaces`). Only the
    ///   player sets `+0x1a8`: row 36 writes 0x10 while blinking with `+0x116` > 60 and 8 under a power-up tint (P3),
    ///   spells later — so a hit with invulnerability > 60 (W2a/P4) reaches it in Phase 2.
    /// - The occluder clip: when x + w + 8 ≥ `+0x1be`, x − 8 ≤ `+0x1c0` and `+0x1c4` ≤ cy ≤ `+0x1c2`: a sprite whose
    ///   centre x + w/2 is left of the occluder's middle gets `+0x1b8 = +0x1be − x` (32000 when beyond the face
    ///   width, ≥ 0), else `+0x1b6 = +0x1c0 − x` (≤ the face width, ≥ 0); the clamps only with a face.
    ///   The occluder is set by W2b (wall tunnels); E2 draws the clip.
    ///
    /// - Parameter faceWidth: a face's width (face `+6`) — Core has no face records [MED: the session passes the
    ///   frame width].
    /// - Parameter exitSplash: `.Splash(s, 4)` (l. 32645; `Splash`, E1a).
    public func standardSpriteCleanup(_ id: Int, faceWidth: (FaceRef) -> Int,
                                      exitSplash: (SpriteWorld, Int) -> Void = { w, id in Splash.splash(w, id: id, mode: 4) }) {
        guard let start = active.record(id: id) else { return }
        var w = 0x80
        if let f = start.face { w = faceWidth(f) }
        if start.lastWater != 0 && start.waterRow == 0 {
            exitSplash(self, id)
            active.update(id: id) { $0.quicksandDepth = 0 }
        }
        guard var s = active.record(id: id) else { return }
        let r = s.hotRect
        s.centre.x = Int(Int16(truncatingIfNeeded: s.x + r.left + ((r.right - r.left) >> 1)))
        s.centre.y = Int(Int16(truncatingIfNeeded: s.y + r.top + ((r.bottom - r.top) >> 1)))
        s.ridden = nil
        if !s.ridingLatch { s.rider = nil }
        s.slope = 0
        if s.burnRow != 0 {
            Burn.handle(self, &s)                                           // `.HandleBurn(s)` (M l. 32661–32663)
        }
        if s.glowChance != 0, let f = s.face {
            ParticleGlow.glow(self, face: particleFaces.sprite(f), v: Int16(truncatingIfNeeded: s.y),
                              h: Int16(truncatingIfNeeded: s.x), kind: s.glowKind, chance: s.glowChance,
                              flip: s.mirrored)
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

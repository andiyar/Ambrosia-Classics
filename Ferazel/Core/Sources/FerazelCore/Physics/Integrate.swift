import Foundation

/// What `.ApplySpeedAndSeparateFromTiles` hands back to the player's Handle (there is no `PlayerState` before P1a).
public struct ApplySpeedResult: Equatable, Sendable {
    /// `_DAT_100a0764 = 0` — the jump counter is zeroed (raw `1004b998..1004b9c8`; Bank correction A3).
    public var zeroJumpCounter: Bool
    /// `*_DAT_1009fe68` / `*_DAT_1009fe64`: the player's whole-px x / y as last written before a separation (the
    /// pre-separation pixels of the last step; `.HandlePlayerSprite` rewrites them later in the frame, save-continue).
    ///
    /// Extra surface, not a return value in the binary: the routine stores these two **globals** (raw `1004b974`,
    /// `1004b98c`), and their home, P1a's `PlayerState`, does not exist yet in F3 — so they are handed back for the
    /// caller to store. P1a may store them directly and stop reading these fields.
    public var playerX: Int16
    public var playerY: Int16

    public init(zeroJumpCounter: Bool, playerX: Int16, playerY: Int16) {
        self.zeroJumpCounter = zeroJumpCounter
        self.playerX = playerX
        self.playerY = playerY
    }
}

extension TileSolver {
    /// `.ApplySpeedAndSeparateFromTiles @ 1004b83c` (decompile l. 43183–43245; raw `1004b83c..1004b9dc`; physics §2),
    /// the player's integration step:
    /// - `+0x14 += vx` once.
    /// - `vy ≤ 0x400` (rising included): `+0x1c += vy`, pixel copies, one `.SeparateFromTiles2`; then if `vy == 0`,
    ///   `+0xce == 0` and the climb global `_DAT_100a0758 == 0` the jump counter `_DAT_100a0764` is zeroed — a head
    ///   bump (a ceiling zeroed vy) or the apex — returned as `zeroJumpCounter` (Bank correction A3).
    /// - `vy > 0x400`: repeat { remaining −= 0x400; `+0x1c += 0x400`; pixel copies; separate; vy ≠ the entry vy → stop
    ///   (no remainder); remaining < 0x400 → stop }; if vy never changed: `+0x1c += remaining`, pixel copies, one more
    ///   separation (M l. 43226–43245). A free fall at vy 0x1000 separates 5 times (the last with a zero remainder).
    ///
    /// - Parameter climb: reads `*_DAT_100a0758` (the cling/climb state, P1a's `PlayerState`). A closure, not a
    ///   value: the dump loads it **after** the separation (`lwz r3,-0x70e8(r2); lha r0,0(r3)`, raw `1004b9b0..bc`,
    ///   after the `bl 0x1003c804` at `1004b990`), and `.HitPlayerTileSprite` (the `pass` callback, P2) can set it to 1
    ///   during that separation. No default: every caller says where climb lives.
    /// - Parameter pass: the player's tile callback (`.HitPlayerTileSprite`, P2).
    @discardableResult
    public func applySpeedAndSeparate(_ id: Int, climb: () -> Int16, pass: TileHit?) -> ApplySpeedResult {
        guard let s0 = world.active.sprite(id: id) else {
            return ApplySpeedResult(zeroJumpCounter: false, playerX: 0, playerY: 0)
        }
        let entryVY = s0.vy                                             // r27
        var result = ApplySpeedResult(zeroJumpCounter: false, playerX: 0, playerY: 0)
        put(id) { $0.x256 &+= $0.vx }

        /// `+0x1c += dy`, then `+0x8 = +0xc = *_DAT_1009fe68 = x px`, `+0x6 = +0xa = *_DAT_1009fe64 = y px`, separate.
        func step(_ dy: Int32) {
            put(id) { s in
                s.y256 &+= dy
                let px = SpriteWorld.pixel(s.x256), py = SpriteWorld.pixel(s.y256)
                s.oldPosition = SpriteSlot.Point(x: px, y: py)
                s.x = px
                s.y = py
                result.playerX = Int16(truncatingIfNeeded: px)
                result.playerY = Int16(truncatingIfNeeded: py)
            }
            separateFromTiles(id, pass: pass)
        }

        if entryVY <= 0x400 {
            step(entryVY)
            // `lwz r0,0x2c` / `lbz r0,0xce` / `lha` of `*_DAT_100a0758`, in that order, all after the separation.
            if let s = world.active.sprite(id: id), s.vy == 0, s.groundKind == 0, climb() == 0 {
                result.zeroJumpCounter = true
            }
        } else {
            var remaining = entryVY                                     // r29
            var changed = false                                         // r25
            var done = false                                            // r26
            while !done {
                remaining &-= 0x400
                step(0x400)
                if world.active.sprite(id: id)?.vy != entryVY {
                    changed = true
                    done = true
                }
                if remaining < 0x400 { done = true }
            }
            if !changed { step(remaining) }
        }
        return result
    }

    /// `.ApplyGravityAndSeparateFromTiles @ 100375b0` (decompile l. 32922–32980; physics §2), most non-player sprites:
    /// g = `+0x110`; in water (`+0x11c ≠ 0`, read at entry — so only a second call in a frame sees it) g =
    /// `(i16)(int)(g · 0.7)` (f64 `0x100a1938`), at least 0x100; `+0xce = 0`; separate; `vy += g`; `x += vx`; y moves
    /// by vy in steps of at most 0xc00 either way with a separation after each (the last with the remainder); then
    /// `+0x8 = +0xc`, `+0x6 = +0xa` from 24.8 and the centre `+0x10`/`+0xe`.
    public func applyGravityAndSeparate(_ id: Int, pass: TileHit?) {
        guard let s0 = world.active.sprite(id: id) else { return }
        var g = s0.gravity
        if s0.waterRow != 0 {
            g = Int16(truncatingIfNeeded: Self.fctiwz(Double(s0.gravity) * Double(bitPattern: 0x3fe6_6666_6666_6666)))
            if g < 0x100 { g = 0x100 }
        }
        put(id) { $0.groundKind = 0 }
        separateFromTiles(id, pass: pass)
        put(id) { s in
            s.vy &+= Int32(g)
            s.x256 &+= s.vx
        }
        var vy = world.active.sprite(id: id)?.vy ?? 0
        func step(_ dy: Int32) {
            put(id) { $0.y256 &+= dy }
            separateFromTiles(id, pass: pass)
        }
        if vy > 0xc00 {
            while vy > 0xc00 { step(0xc00); vy &-= 0xc00 }
            step(vy)
        } else if vy < -0xc00 {
            while vy < -0xc00 { step(-0xc00); vy &+= 0xc00 }
            step(vy)
        } else {
            step(vy)
        }
        put(id) { s in
            let px = SpriteWorld.pixel(s.x256), py = SpriteWorld.pixel(s.y256)
            s.oldPosition = SpriteSlot.Point(x: px, y: py)
            s.x = px
            s.y = py
            let r = s.hotRect
            s.centre.x = Int(Int16(truncatingIfNeeded: s.x + r.left + Int(Int16(truncatingIfNeeded: (r.right - r.left) >> 1))))
            s.centre.y = Int(Int16(truncatingIfNeeded: s.y + r.top + Int(Int16(truncatingIfNeeded: (r.bottom - r.top) >> 1))))
        }
    }
}

extension TileSolver {
    /// `.AccelerateSprite` on sprite `id` (plan S2 name; `SpriteSlot.accelerateSprite`).
    public func accelerateSprite(_ id: Int, ax: Int32, ay: Int32, maxX: Int32, maxY: Int32) {
        put(id) { $0.accelerateSprite(ax: ax, ay: ay, maxX: maxX, maxY: maxY) }
    }

    /// `.AccelerateBasedOnSlope` on sprite `id` (plan S2 name; `SpriteSlot.accelerateBasedOnSlope`).
    public func accelerateBasedOnSlope(_ id: Int, _ a: Int16, cap: Int32) {
        put(id) { $0.accelerateBasedOnSlope(a, cap: cap) }
    }

    /// `.ApplyFriction` on sprite `id` (plan S2 name; `SpriteSlot.applyFriction`, F2).
    public func applyFriction(_ id: Int, _ f: Int16) {
        put(id) { $0.applyFriction(f) }
    }

    /// `.EnforceMaxSpeed` on sprite `id` (plan S2 name; `SpriteSlot.enforceMaxSpeed`, F2).
    public func enforceMaxSpeed(_ id: Int, _ m: Int32) {
        put(id) { $0.enforceMaxSpeed(m) }
    }
}

extension SpriteSlot {
    /// 0.8 (f64 `0x100a1928`): the in-water factor of `.AccelerateSprite` and `.AccelerateBasedOnSlope`.
    static let waterFactor = Double(bitPattern: 0x3fe9_9999_9999_999a)
    /// The uphill factors of `.AccelerateBasedOnSlope` — **f32** (`lfs`): 0.707 `0x100a1920`, 0.923 `0x100a191c`,
    /// 0.382 `0x100a1918`.
    static let slope45 = Float(bitPattern: 0x3f34_fdf4)
    static let slope12 = Float(bitPattern: 0x3f6c_49ba)
    static let slope21 = Float(bitPattern: 0x3ec3_9581)

    /// `.AccelerateSprite @ 1003713c (s, ax, ay, maxX, maxY)` (raw `1003713c..100372ac`): in water (`+0x11c ∨ +0x120`)
    /// all four arguments become `fctiwz(arg · 0.8)` (f64); `vx += ax`, `vy += ay`; then |vx| > maxX → ±maxX (maxX ≠ 0)
    /// and |vy| > maxY → ±maxY (maxY ≠ 0), the sign from `v > 0` (`v ≤ 0` takes −max).
    public mutating func accelerateSprite(ax: Int32, ay: Int32, maxX: Int32, maxY: Int32) {
        var ax = ax, ay = ay, maxX = maxX, maxY = maxY
        if waterRow != 0 || lastWater != 0 {
            ax = TileSolver.fctiwz(Double(ax) * Self.waterFactor)
            ay = TileSolver.fctiwz(Double(ay) * Self.waterFactor)
            maxX = TileSolver.fctiwz(Double(maxX) * Self.waterFactor)
            maxY = TileSolver.fctiwz(Double(maxY) * Self.waterFactor)
        }
        vx &+= ax
        vy &+= ay
        if maxX != 0 {
            let m = vx > 0 ? vx : 0 &- vx
            if m > maxX { vx = vx > 0 ? maxX : 0 &- maxX }
        }
        if maxY != 0 {
            let m = vy > 0 ? vy : 0 &- vy
            if m > maxY { vy = vy > 0 ? maxY : 0 &- maxY }
        }
    }

    /// `.AccelerateBasedOnSlope @ 10037350 (s, a, cap)` (raw `10037350..10037580`; physics §2):
    /// - cap₃₂ = `f32(cap)`. In water — **`+0x11c` only** (`lwz r0,0x11c`, raw `10037354`; never true for the player,
    ///   whose `+0x11c` is zeroed by `.StandardSpriteHandles` before its Handle runs — Bank correction A5): cap₃₂ =
    ///   `f32(f64(cap₃₂) · 0.8)` (`fmul; frsp`), cap = `fctiwz(cap · 0.8)`, a = `(i16)fctiwz(a · 0.8)`.
    /// - Uphill on a slope kind `+0xce` the factor F (f32) applies: 0xc (a < 0) / 0xf (a > 0) 0.707; 0x20, 0x21 (a < 0)
    ///   / 0x22, 0x23 (a > 0) 0.923; 0x2c, 0x2d (a < 0) / 0x2e, 0x2f (a > 0) 0.382. Then `vx += fctiwz(f32(a)·F)` and
    ///   cap₃₂ = `f32(f32(cap)·F)` — both `fmuls` (single precision). Otherwise `vx += a`.
    /// - `f32(|vx|) > cap₃₂` → `vx = ±fctiwz(cap₃₂)` (sign from `vx > 0`).
    public mutating func accelerateBasedOnSlope(_ a: Int16, cap: Int32) {
        var a = a, cap = cap
        var cap32 = Float(cap)                                          // `fsubs f5`
        if waterRow != 0 {
            cap32 = Float(Double(cap32) * Self.waterFactor)             // `fmul f5,f5,f2; frsp`
            cap = TileSolver.fctiwz(Double(cap) * Self.waterFactor)
            a = Int16(truncatingIfNeeded: TileSolver.fctiwz(Double(a) * Self.waterFactor))
        }
        var factor: Float?
        switch groundKind {
        case 0xc where a < 0, 0xf where a > 0: factor = Self.slope45
        case 0x20...0x21 where a < 0, 0x22...0x23 where a > 0: factor = Self.slope12
        case 0x2c...0x2d where a < 0, 0x2e...0x2f where a > 0: factor = Self.slope21
        default: factor = nil
        }
        if let F = factor {
            vx &+= TileSolver.fctiwz(Double(Float(a) * F))              // `fmuls f0,f0,f4; fctiwz`
            cap32 = Float(cap) * F                                      // `fsubs f0,f1,f2; fmuls f5,f0,f4`
        } else {
            vx &+= Int32(a)
        }
        let m = vx > 0 ? vx : 0 &- vx
        if Float(m) > cap32 {                                           // `fsubs f0; fcmpo f0,f5; blelr`
            vx = vx > 0 ? TileSolver.fctiwz(Double(cap32)) : TileSolver.fctiwz(Double(-cap32))
        }
    }
}

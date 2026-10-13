import Foundation

/// The radial spokes (platforms-ropes-radial §2.3, §1.7; W1): chain links 0x596 (`.SetupChainSprite @ 100652c0`,
/// `.HandleChainSprite @ 10065374`; also the Background maces' chains 0x59a/0x59c, W2a) and the see-saw segments 0x59b
/// (`.SetupSeeSawSegSprite @ 10065508`, `.HandleSeeSawSegSprite @ 100655c8`).
public enum ChainSprite {
    /// 0x596 chain link, 0x59a / 0x59c the mace chains (singles), 0x59b the see-saw segment.
    public static let link: Int16 = 0x596
    public static let maceChain: Int16 = 0x59a
    public static let maceChain2: Int16 = 0x59c
    public static let seeSawSegment: Int16 = 0x59b

    /// `.SetupChainSprite` (decompile l. 55946–55963): `.InitSprite`, the chain Handle, rect (0, 0, 0x18, 0x18) for
    /// 0x59a else (0, 0, 0x10, 0x10), the tile callback `.HitChainTileSprite` (`+0x1f8`; never reached — the chain
    /// Handle does not separate), `+0x13f = 0` (not kept). No hit callback (`.InitSprite` 0), no face, the layer the
    /// caller passed (−2 for platform chains, raw `10062610 li r5,-0x2`).
    public static func setup(_ s: inout SpriteSlot) {
        s.handler = .chain
        s.hasHit = false
        s.hasTileHit = true
        if s.type == maceChain {
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x18, right: 0x18)
        } else {
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x10, right: 0x10)
        }
    }

    /// `.HandleChainSprite` (decompile l. 55967–56018): no `.StandardSpriteHandles` / Cleanup. 0x596: face = set 0x599
    /// (60 × 16×16) index `+0xb0 / 6` (signed division; < 0 → 0x3b, ≥ 0x3c → 0), `+0x88 = 1`. 0x59a / 0x59c: the
    /// single face, `.MTChangeSpriteLayer(+0x1ae − 0x100)`, rotation `+0x1aa = (+0xb0 + 90) % 360` (C remainder),
    /// `+0x88 = 0`; 0x59a with scale 0x100 → `+0x89 = 1`.
    public static func handle(world w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        switch s.type {
        case link:
            var i = Int(s.subtype) / 6
            if i < 0x3c {
                if i < 0 { i = 0x3b }
            } else {
                i = 0
            }
            w.active.update(id: id) { c in
                c.lightOverlay = true
                c.face = FaceRef(pict: 0x599, index: i, set: .encoded)
            }
        case maceChain, maceChain2:
            w.active.update(id: id) { $0.face = FaceRef(pict: s.type, index: 0, set: .encoded) }
            w.changeLayer(id: id, layer: s.scale &- 0x100)
            let a = Int(s.subtype) + 0x5a
            w.active.update(id: id) { c in
                c.rotation = Int16(truncatingIfNeeded: a % 0x168)
                c.lightOverlay = false
                if s.type == maceChain && c.scale == 0x100 { c.dynamicLight = true }
            }
        default:
            break
        }
    }

    /// `.SetupSeeSawSegSprite` (decompile l. 56022–56044): `.InitSprite`, one-way `+0x185 = 1`, the segment Handle,
    /// no hit callback, tile callback `.HitChainTileSprite`, `+0x13f = 0`, rect (0, 0, 0x18, 0x58), `+0xd2 = +0xd4 =
    /// 0x57`. Layer as passed (0, raw `10062fc0 li r5,0x0`).
    public static func setupSeeSawSegment(_ s: inout SpriteSlot) {
        s.handler = .seeSawSegment
        s.oneWay = true
        s.hasHit = false
        s.hasTileHit = true
        s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x58, right: 0x18)
        s.surfaceLeft = 0x57
        s.surfaceRight = 0x57
    }

    /// `.HitChainTileSprite @ 10065798` (decompile l. 56096–56108): BG/crunch layers only — a water kind with
    /// `+0x140` clear → `.HandleUnderWater`.
    public static func hitTile(_ solver: TileSolver, id: Int, pos: TilePos, kind: Int, layer: TileLayer) {
        guard layer != .foreground, UnderWater.isWaterTile(kind),
              solver.world.active.record(id: id)?.underwaterDone == false else { return }
        UnderWater.handle(world: solver.world, id: id, pos: pos)
    }

    /// `.HandleSeeSawSegSprite` (decompile l. 56048–56092): `.StandardSpriteHandles`; for 0x59b: u = `+0xb0`, b =
    /// u > 180 → u = 360 − u; u > 89 → u = 179 − u, b = !b; `+0x88 = 1`, face set 0x59b index u / 2, `+0x17e = b`; ridden
    /// (`+0x186`) with `+0xb2 == 1` → `+0x186 = 0`, the arm (`+0x1d4`) ridden and its lever `+0x150 = ((n − (k+1))·256)
    /// / n` (n = (i16)`+0x150`, k = (i16)`+0x14c`); `+0x154 = 0`; tilted (u in 6 … 179, or 180 … 354 as written) → the
    /// 24.8 position from the pixel copies, the rect bottom lowered to max(b − d2, b − d4) + 8 for one
    /// `.SeparateFromTiles2`, then restored; `.StandardSpriteCleanup`.
    public static func handleSeeSawSegment(world w: SpriteWorld, id: Int, solver: TileSolver,
                                           faceWidth: (FaceRef) -> Int) {
        w.standardSpriteHandles(id)
        guard let s = w.active.record(id: id) else { return }
        if s.type == seeSawSegment {
            var u = s.subtype
            var b = 0xb4 < u
            if b { u = 0 &- (u &- 0x168) }
            if 0x59 < u {
                u = 0x59 &- (u &- 0x5a)
                b = !b
            }
            let mirrored = b
            w.active.update(id: id) { c in
                c.lightOverlay = true
                c.face = FaceRef(pict: seeSawSegment, index: Int(u / 2), set: .encoded)
                c.mirrored = mirrored
            }
            if s.ridingLatch && s.subState == 1, let arm = s.siblings.first {
                let n = Int32(Int16(truncatingIfNeeded: s.classWord150))
                let k1 = Int32(Int16(truncatingIfNeeded: s.classTimer) &+ 1)
                w.active.update(id: id) { $0.ridingLatch = false }
                w.active.update(id: arm) { a in
                    a.ridingLatch = true
                    a.classWord150 = SpriteSlot.divw((n - k1) &* 0x100, n)
                }
            }
            w.active.update(id: id) { $0.classWord154 = 0 }
            if (u < 0xb4 && 5 < u) || (0xb3 < u && u < 0x163) {
                guard let c0 = w.active.record(id: id) else { return }
                let saved = c0.hotRect
                let i4 = c0.hotRect.bottom - Int(c0.surfaceLeft)
                var i6 = c0.hotRect.bottom - Int(c0.surfaceRight)
                if i6 < i4 { i6 = i4 }
                w.active.update(id: id) { c in
                    c.x256 = Int32(Int16(truncatingIfNeeded: c.x)) << 8
                    c.y256 = Int32(Int16(truncatingIfNeeded: c.y)) << 8
                    c.hotRect.bottom = Int(Int16(truncatingIfNeeded: i6 + 8))
                }
                solver.separateFromTiles(id) { sv, i, c, k, l in hitTile(sv, id: i, pos: c, kind: k, layer: l) }
                w.active.update(id: id) { $0.hotRect = saved }
            }
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }
}

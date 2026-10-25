import Foundation

/// The player's shots (spells-items §2, spells-detail §3.1–§3.2, §3.8, spells-detail-2 §2–§5): `.InitPlayerShotSprite
/// @ 10058fac` (M l. 50226–50264, the sheets), `.SetupPlayerShotSprite @ 1005925c` (M l. 50265–50430, `setup`) and
/// `.HandlePlayerShotSprite @ 10059704` (M l. 50431–50946, `handle`). The spawn type is `id·256 + power`; the Setup
/// splits it — `+0x170` = power, `+4` = the id (plan hazard "`+0x04` vs `+0x170`") — so every reader after the Setup
/// sees the id in `type`.
///
/// The tile callback `.HitPlayerShotTileSprite` is `hitTile` (SH); the hit callback `.HitPlayerShotSprite` and
/// `.KillPlayerShot` are `PlayerShotHits.hit` / `.kill`.
public enum PlayerShot {
    /// `.InitPlayerShotSprite`'s face sets (M l. 50235–50256; boot loads, CLUT 200): 1100…1105 the Fireball / Statue /
    /// Ice Crystals pairs (6 × 24×15, right / left), 1113 the Boomerang (6 × 32×32), 1114 the V Blade (20 × 32×40, 10
    /// per row: 0…9 upper, 10…19 lower), 1115 Ice Wall (6 × 28×28, ids 3 and 7), 1116 the seeds (8 × 12×12) and the
    /// single 1118 (the Pentashield orb). PICT 1117 is `.InitEnemyShotSprite`'s (M l. 51418), not a player face.
    public static let sheets: [SetupFaces.Sheet] = [
        SetupFaces.Sheet(pict: 0x44c, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x44d, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x44e, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x44f, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x450, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x451, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x459, count: 6, cellWidth: 0x20, cellHeight: 0x20, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: 0x45a, count: 0x14, cellWidth: 0x20, cellHeight: 0x28, columns: 10, clut: 200),
        SetupFaces.Sheet(pict: 0x45b, count: 6, cellWidth: 0x1c, cellHeight: 0x1c, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: 0x45c, count: 8, cellWidth: 0xc, cellHeight: 0xc, columns: 8, clut: 200),
        .single(0x45e),
    ]

    /// The light faces: `_DAT_100a0800` = PICT 810 (72×72, M l. 50257) and `_DAT_100a07fc` = PICT 822 (52×52, V Blade,
    /// M l. 50259).
    static let light = LightFaceRef(pict: 0x32a, width: 0x48, height: 0x48)
    static let vBladeLight = LightFaceRef(pict: 0x336, width: 0x34, height: 0x34)

    /// The non-spell shot ids (spells-detail §3.8): V Blade's lower half, the Pentashield orb, the thrown seeds.
    public static let vBladeLower: Int16 = 0x3c, orb: Int16 = 0x50, seed: Int16 = 0x5a

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    /// A face of sheet `pict`.
    static func face(_ pict: Int16, _ index: Int) -> FaceRef { FaceRef(pict: pict, index: index, set: .encoded) }

    /// A face's cell at the origin (the sheet's; `.noFace` for the single) — the Core-only stand-in for the face's
    /// width and opaque bounds when no renderer is attached (the session passes its own).
    public static func cellRect(_ f: FaceRef) -> IdleSprites.Rect {
        guard let s = SetupFaces.sheet(pict: f.pict), !s.single else { return .noFace }
        return IdleSprites.Rect(top: 0, left: 0, bottom: s.cellHeight, right: s.cellWidth)
    }

    /// `MTNewSprite(type, x, y, 0xb, −1, .SetupPlayerShotSprite)`: nil when no record is free (Ruling 16: no Setup, no
    /// draws — the caller's stores to it are dropped).
    @discardableResult
    public static func spawn(_ w: SpriteWorld, type: Int16, x: Int, y: Int) -> Int? {
        w.newSprite(type: type, x: x, y: y, layer: 0xb, handler: .playerShot) { s in setup(w, &s) }
    }

    // MARK: - Setup

    /// `.SetupPlayerShotSprite` (M l. 50265–50430; raw `1005925c..100596ff`), inside `.MTNewSprite` before the insert:
    /// - `.InitSprite` (the record's defaults), `+0xeb` 1, `+0x88` 0, `+0x84`/`+0x86` 0, `+0x46 = FastRand(5)`, layer
    ///   0xb, the Handle, the hit callback `.HitPlayerShotSprite` and the tile callback `.HitPlayerShotTileSprite`
    ///   installed (`+0x5c`, `+0x1f8`), `+0xa6` 0, `+0x90` 0x100, `+0x158` 1, hot rect `SetRect(8, 3, 15, 12)`;
    /// - the split: `+0x170 = (short)type & 0xff`, `+4 = (char)(type >> 8)`; face 0; `+0xc = +8`, `+0xa = +6`, 24.8 from
    ///   them; `+0xe4` 1 (the dead second loop's gate in `.SeparateFromTiles2`, not kept);
    /// - per id (spells-detail §3.1): 0, 1, 3, 4 gravity 0xfa; 2 gravity 0; 5 rect (10, 10, 22, 22), 0; 6 rect
    ///   (8, 8, 24, 32), 0; 7 rect (6, 6, 22, 22), 0xfa; 0x3c rect (−10, 0, 24, 6), 0; 0x50 rect (0, 0, 20, 20), 0,
    ///   `+0xa4` 300, `+0x168` 3, `+0x16c = FastRand(14)`, no tile callback; 0x5a rect (2, −6, 10, 6), 0xfa, `+0x158` 2;
    /// - power 0 (a follower): no hit, no tile callback, gravity 0;
    /// - power ≥ 2: step (10, 0) for ids 6 / 0x3c, else (0, 6) into `+0x160`/`+0x164`; stack offset (power − 1)·step/2
    ///   (`srawi; addze`) into `+0x168`/`+0x16c` — from the **unclamped** power (raw `10059544..10059564`, before the
    ///   clamp at `1005956c`); power clamped to 5; power − 1 followers `MTNewSprite((short)(id << 8), x + offX − k·sx,
    ///   y + offY − k·sx, 0xb, −1, Setup)` — **both** coordinates step by the x step (raw `100595d4`/`100595d8`: `subf`
    ///   of r30 = k·`+0x160` from each; the y step is never used here) — the first into `+0x1d4` (raw
    ///   `1005960c..10059628`; the decompile's `+0x1d4 = 0` misreads the loop); then the main moves by the offset (24.8
    ///   from it) and its hot rect moves back by it, so the hit rect stays at the stack's centre;
    /// - `+0x14c` (age) −1.
    static func setup(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        s.crunches = 1
        s.lightOverlay = false
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.phase = w.rng.next(5)
        s.layer = 0xb
        s.handler = .playerShot
        s.hasHit = true                                                 // `.HitPlayerShotSprite` (`PlayerShotHits.hit`)
        s.hasTileHit = true                                             // `.HitPlayerShotTileSprite` (`hitTile`)
        s.counterA6 = 0
        s.windScale = 0x100
        s.crunchStrength = 1
        s.hotRect = IdleSprites.Rect(top: 3, left: 8, bottom: 0xc, right: 0xf)
        s.power = Int32(s.type) & 0xff
        s.type = Int16(Int8(truncatingIfNeeded: UInt16(bitPattern: s.type) >> 8))
        s.face = nil
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        switch s.type {
        case 0, 1, 3, 4:
            s.gravity = 0xfa
        case 2:
            s.gravity = 0
        case 5:
            s.hotRect = IdleSprites.Rect(top: 10, left: 10, bottom: 0x16, right: 0x16)
            s.gravity = 0
        case 6:
            s.hotRect = IdleSprites.Rect(top: 8, left: 8, bottom: 0x20, right: 0x18)
            s.gravity = 0
        case 7:
            s.hotRect = IdleSprites.Rect(top: 6, left: 6, bottom: 0x16, right: 0x16)
            s.gravity = 0xfa
        case vBladeLower:
            s.hotRect = IdleSprites.Rect(top: 0, left: -10, bottom: 6, right: 0x18)
            s.gravity = 0
        case orb:
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x14, right: 0x14)
            s.gravity = 0
            s.hp = 300
            s.stackX = 3                                                // `+0x168`: the orb's hits left
            s.stackY = Int32(w.rng.next(0xe))                           // `+0x16c`: its tint phase
            s.hasTileHit = false
        case seed:
            s.hotRect = IdleSprites.Rect(top: -6, left: 2, bottom: 6, right: 10)
            s.gravity = 0xfa
            s.crunchStrength = 2
        default:
            break
        }
        if s.power < 2 {
            if s.power == 0 {
                s.hasHit = false
                s.hasTileHit = false
                s.gravity = 0
            }
        } else {
            let sx: Int32 = s.type == 6 || s.type == vBladeLower ? 10 : 0
            let sy: Int32 = sx == 0 ? 6 : 0
            s.stepX = sx
            s.stepY = sy
            let offX = Int32(Int16(truncatingIfNeeded: (s.power &- 1) &* (sx / 2)))
            let offY = Int32(Int16(truncatingIfNeeded: (s.power &- 1) &* (sy / 2)))
            s.stackX = offX
            s.stackY = offY
            if 4 < s.power { s.power = 5 }
            var made: [Int?] = [nil, nil, nil, nil]
            let ftype = Int16(truncatingIfNeeded: Int32(s.type) << 8)
            let x0 = h16(s.x), y0 = h16(s.y)
            var step = Int(sx)
            var k = 1
            while k <= Int(s.power) - 1 {
                made[k - 1] = spawn(w, type: ftype, x: x0 + Int(offX) - step, y: y0 + Int(offY) - step)
                step += Int(sx)
                k += 1
            }
            s.siblings = SpriteSlot.Siblings(first: made[0], second: made[1], third: made[2], fourth: made[3])
            s.x = h16(s.x + Int(offX))
            s.y = h16(s.y + Int(offY))
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.hotRect.left = h16(s.hotRect.left - Int(offX))
            s.hotRect.right = h16(s.hotRect.right - Int(offX))
            s.hotRect.top = h16(s.hotRect.top - Int(offY))
            s.hotRect.bottom = h16(s.hotRect.bottom - Int(offY))
        }
        s.shotAge = -1
    }

    // MARK: - Handle

    /// The followers `+0x1d4…+0x1e0` in order.
    static func followers(_ s: SpriteSlot) -> [Int?] {
        [s.siblings.first, s.siblings.second, s.siblings.third, s.siblings.fourth]
    }

    /// `.HandlePlayerShotSprite(s)` (M l. 50431–50946; raw `10059704..1005a7f8`), in order:
    /// 1. `+0xe9 ≠ 0` → return; `.StandardSpriteHandles`;
    /// 2. power > 1: the stack offset taken off the position (pixel and 24.8) and given back to the hot rect;
    /// 3. age `+0x14c` + 1 while < 200 (no lifetime);
    /// 4. age ≥ 1, by id (`idArm`): faces, the particles of ids 2 / 3 / 4, the Boomerang's steering, V Blade's ±500 px
    ///    rule, the orb's tints, the seed's damage;
    /// 5. age 1 with power > 0: a mid-handler `.StandardSpriteCleanup`, `+0xa4 ×= power` (16-bit), and — unless the
    ///    face is entirely hidden in a wall tunnel (face bounds right ≤ `+0x1b6` or `+0x1b8` ≤ left; spells-detail-2
    ///    §2) — the light (`ageOneLight`);
    /// 6. `vy += gravity`, `x256 += vx`, `y256 += vy`; `.ChangeLightSpeed(+0x9a, vx, vy)`;
    /// 7. `.SeparateFromTiles2` for ids < 100, 0x5a, and 100 with `+0x158 > 0` (the tile callback `hitTile` when
    ///    installed);
    /// 8. the liquid rule (M l. 50789–50818): `+0x11c > 0`, id < 100, id ≠ 6 → `MTNewSprite(5, x − 8, y − 0xc, 0xb, −1,
    ///    .SetupEffectSprite)`, `.ChangeLightColor(effect +0x9a, 0)` (unguarded in the binary: dropped when no record is
    ///    free, Ruling 16), `+0xe9 = 1`; id 3 in water (`+0x128 == 0`) → `.CalcCenterPos` and the ice floe
    ///    `MTNewSprite(0x57c, …)` // later: SW; power > 1 → the four followers flagged;
    /// 9. the level-bottom rule: `hdr+0xb282 << 5 < +0xa` → `+0xe9 = 1`;
    /// 10. ids < 100: `+8 = +0xc = x256 >> 8`, `+6 = +0xa = y256 >> 8`; else `+6/+8 ← +0xa/+0xc`; the centre `+0x10`/`+0xe`
    ///     from the hot rect;
    /// 11. gravity > 0: the draw angle `+0x1aa = 10·dir`, dir = `.FindDesiredDirectionGeneric(+0xc4, (y, x) + the stack
    ///     offset)`, + 18 when vx < 0, − 36 past 35;
    /// 12. power > 1: follower k (k = 1…4, `+0x1d4…`) at (x + `+0x168` − k·`+0x160`, y + `+0x16c` − k·`+0x164`) with the
    ///     main's vx; the main moves by the offset again (its hot rect back); the followers take the angle;
    /// 13. `.StandardSpriteCleanup`; a face entirely hidden in a wall tunnel → `.RemoveLight(+0x9a)` (for good: only
    ///     age 1 adds one).
    /// The Handle never re-tests `+0xe9` after step 1, so a shot killed this frame finishes its call (its followers are
    /// placed once more, spells-detail-2 §5).
    /// - Parameters: `lights` the session's table; `effects` prefs+6 (the effect 5's Setup); `faceWidth` / `faceBounds`
    ///   a face's width (face `+6`) and opaque bounds (face `+8`) — Core has no face records.
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                              effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                              faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s0 = w.active.record(id: id), s0.killCount == 0 else { return }
        w.standardSpriteHandles(id)
        // 2.
        if 1 < s0.power {
            w.active.update(id: id) { s in
                s.x = h16(s.x - Int(s.stackX))
                s.y = h16(s.y - Int(s.stackY))
                s.x256 &+= s.stackX &* -0x100
                s.y256 &+= s.stackY &* -0x100
                s.hotRect.left = h16(s.hotRect.left + Int(s.stackX))
                s.hotRect.right = h16(s.hotRect.right + Int(s.stackX))
                s.hotRect.top = h16(s.hotRect.top + Int(s.stackY))
                s.hotRect.bottom = h16(s.hotRect.bottom + Int(s.stackY))
            }
        }
        // 3.
        w.active.update(id: id) { s in if s.shotAge < 200 { s.shotAge += 1 } }
        // 4.
        if let s = w.active.record(id: id), 0 < s.shotAge { idArm(w, id: id) }
        // 5.
        if let s = w.active.record(id: id), s.shotAge == 1, 0 < s.power {
            w.standardSpriteCleanup(id, faceWidth: faceWidth)
            var visible = true
            if let t = w.active.record(id: id), let f = t.face {
                let b = faceBounds(f)
                if b.right <= t.clip.left || t.clip.right <= b.left { visible = false }
            }
            w.active.update(id: id) { t in
                t.hp = Int16(truncatingIfNeeded: Int32(t.hp) &* Int32(Int16(truncatingIfNeeded: t.power)))
            }
            if visible, let t = w.active.record(id: id) {
                let slot = ageOneLight(t, lights: &lights)
                if let slot { w.active.update(id: id) { $0.light = slot } }
            }
        }
        // 6.
        w.active.update(id: id) { s in
            s.vy &+= Int32(s.gravity)
            s.x256 &+= s.vx
            s.y256 &+= s.vy
        }
        if let s = w.active.record(id: id) { lights.changeSpeed(s.light, vx: s.vx, vy: s.vy) }
        // 7.
        if let s = w.active.record(id: id),
           s.type < 100 || s.type == seed || (s.type == 100 && 0 < s.crunchStrength) {
            if s.hasTileHit {
                // The callback reaches `.KillPlayerShot` (the session's light table, prefs+6, the face reads).
                withoutActuallyEscaping({ (sv: TileSolver, i: Int, c: TilePos, k: Int, l: TileLayer) in
                    hitTile(sv, i, c, k, l, lights: &lights, effects: effects, faceWidth: faceWidth,
                            faceBounds: faceBounds)
                }) { pass in solver.separateFromTiles(id, pass: pass) }
            } else {
                solver.separateFromTiles(id, pass: nil)
            }
        }
        // 8.
        if let s = w.active.record(id: id), 0 < s.waterRow, s.type < 100, s.type != 6 {
            if let e = EffectSprite.spawn(w, type: 5, x: h16(s.x) - 8, y: h16(s.y) - 0xc, layer: 0xb, effects: effects,
                                          lights: &lights),
               let light = w.active.record(id: e)?.light {
                lights.changeColor(light, 0)
            }
            w.active.update(id: id) { $0.dead = true }
            if s.type == 3 && s.waterKind == 0 {
                // `.CalcCenterPos(s)` (its centre is recomputed at step 10 the same way), then the floe
                // `MTNewSprite(0x57c, +0xc − 10, +0xe − 4, 2, −1, .SetupPlatformSprite)` with `+0xa6 = 0xb4`, `+0xb0 = 4`,
                // `+0x13a = 4` (M l. 50797–50803). // later: SW (the ice floe)
                w.active.update(id: id) { t in
                    let r = t.hotRect
                    t.centre.x = h16(t.x + r.left + h16((r.right - r.left) >> 1))
                    t.centre.y = h16(t.y + r.top + h16((r.bottom - r.top) >> 1))
                }
            }
            if 1 < s.power {
                for f in followers(s).compactMap({ $0 }) { w.active.update(id: f) { $0.dead = true } }
            }
        }
        // 9.
        if let s = w.active.record(id: id), Int(w.level.header.gridHeight) << 5 < h16(s.y) {
            w.active.update(id: id) { $0.dead = true }
        }
        // 10.
        w.active.update(id: id) { s in
            if s.type < 100 {
                s.x = SpriteWorld.pixel(s.x256)
                s.y = SpriteWorld.pixel(s.y256)
                s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            } else {
                s.oldPosition = SpriteSlot.Point(x: s.x, y: s.y)
            }
            let r = s.hotRect
            s.centre.x = h16(s.x + r.left + h16((r.right - r.left) >> 1))
            s.centre.y = h16(s.y + r.top + h16((r.bottom - r.top) >> 1))
        }
        // 11.
        if let s = w.active.record(id: id), 0 < s.gravity {
            var to = (v: Int16(truncatingIfNeeded: s.y), h: Int16(truncatingIfNeeded: s.x))
            if 1 < s.power {
                to.v &+= Int16(truncatingIfNeeded: s.stackY)
                to.h &+= Int16(truncatingIfNeeded: s.stackX)
            }
            var dir = BloodSpray.direction(target: (v: Int16(truncatingIfNeeded: s.drawnY),
                                                    h: Int16(truncatingIfNeeded: s.drawnX)), from: to)
            if s.vx < 0 { dir += 0x12 }
            if 0x23 < dir { dir -= 0x24 }
            w.active.update(id: id) { $0.rotation = Int16(dir * 10) }
        }
        // 12.
        if let s = w.active.record(id: id), 1 < s.power {
            for (k, f) in followers(s).enumerated() {
                guard let f else { continue }
                let n = Int32(k + 1)
                let fx = h16(h16(s.x) + h16(Int(s.stackX)) - h16(Int(s.stepX &* n)))
                let fy = h16(h16(s.y) + h16(Int(s.stackY)) - h16(Int(s.stepY &* n)))
                let vx = s.vx
                w.active.update(id: f) { t in
                    t.x = fx
                    t.y = fy
                    t.x256 = Int32(fx) << 8
                    t.y256 = Int32(fy) << 8
                    t.vx = vx
                }
            }
            w.active.update(id: id) { t in
                t.x = h16(t.x + Int(t.stackX))
                t.y = h16(t.y + Int(t.stackY))
                t.x256 &+= t.stackX &* 0x100
                t.y256 &+= t.stackY &* 0x100
                t.hotRect.left = h16(t.hotRect.left - Int(t.stackX))
                t.hotRect.right = h16(t.hotRect.right - Int(t.stackX))
                t.hotRect.top = h16(t.hotRect.top - Int(t.stackY))
                t.hotRect.bottom = h16(t.hotRect.bottom - Int(t.stackY))
            }
            let angle = s.rotation
            for f in followers(s).compactMap({ $0 }) { w.active.update(id: f) { $0.rotation = angle } }
        }
        // 13.
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        if let s = w.active.record(id: id), let f = s.face {
            let b = faceBounds(f)
            if b.right <= s.clip.left || s.clip.right <= b.left {
                w.active.update(id: id) { t in lights.remove(&t.light) }
            }
        }
    }

    /// Step 4's per-id arm (M l. 50485–50697; raw `100597c4..10059f5c`): the frame counter `+0x46` wraps at 6 (10 for
    /// ids 6 / 0x3c, 8 for 0x5a), the face by id and — for 0 / 1 / 2 — by vx (vx < 1 → the left sheet 1101 / 1103 /
    /// 1105). Per frame:
    /// - id 2: 2 × `NewParticle(200, 0xfa, (y + 5 + R(6), x + 10 + R(6)), R(2) + 1, R(400) − 200 − `+0x86`, max(0,
    ///   R(400) − 200 − `+0x84`), 0, 1)` — draws R(400) (vy), R(6), R(6), R(400) (vx), R(2) (raw `1005998c..10059a30`);
    /// - id 3: 5 × `NewParticle(3, 0x15e, (y + 5 + R(6), x + 10 + R(6)), R(2) + 1, R(400) − 200 − `+0x86`, R(800) + vy
    ///   − 400, 0, 1)` — a **first R(400) whose result is never read** (raw `10059a88..10059a90`), then R(6), R(6),
    ///   R(800), R(400), R(2);
    /// - id 4 (no face): 7 × `NewParticle(9, 0, (y + 4 + R(8), x + 9 + R(8)), R(2) + 1, R(400) − 200 − `+0x86`, R(400) −
    ///   200, 0, 1)` — again a discarded first R(400) (raw `10059b6c..10059b74`), then R(8), R(8), R(400) (vy), R(400)
    ///   (vx), R(2);
    /// - id 5 with age > 12: `FUN_1003f218(s, .FindDesiredDirectionGeneric(player centre − (4, 0), s centre), 800)`,
    ///   `.EnforceMaxSpeed(s, 0x1450)` (spells-detail-2 §3);
    /// - ids 6 / 0x3c: `+0xe9 = 1` when the centre y is more than 500 px from `*_DAT_1009fd90` (the player's centre y);
    /// - 0x50: face 1118, `+0x16c` + 1 mod 16, `+0x88` 0, `+0xb8` by `+0x16c >> 1` (0…1 → 0, 2…3 and 6…7 → 0x10008,
    ///   4…5 → 0x10009); a negative `+0x164` counts up with 0xb0002 (−9…−7), 0xb0000 (−6…−4), 0xb0001 (−3…−1), else 0;
    /// - 0x5a: face 1116 (none while `+0xf0`), `+0xa6` 0, `+0xa4` 800 — 0x578 with `+0xb8 = 0x10004` while `+0xf4`.
    static func idArm(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        func advance(_ wrap: Int16) -> Int {
            var p: Int16 = 0
            w.active.update(id: id) { t in
                t.phase &+= 1
                if wrap < t.phase { t.phase = 0 }
                p = t.phase
            }
            return Int(p)
        }
        func setFace(_ f: FaceRef?) { w.active.update(id: id) { $0.face = f } }
        func particle(_ kind: Int, _ gravity: Int, v: Int, h: Int, shape: Int, vx: Int, vy: Int) {
            w.particles.newParticle(kind: kind, gravity: gravity, v: v, h: h, shape: shape, vx: vx, vy: vy, delay: 0,
                                    mode: 1)
        }
        let x = h16(s.x), y = h16(s.y)
        switch s.type {
        case 0, 1, 2:
            let p = advance(5)
            let sheet: (left: Int16, right: Int16) = s.type == 0 ? (0x44d, 0x44c) : s.type == 1 ? (0x44f, 0x44e)
                : (0x451, 0x450)
            setFace(face(s.vx < 1 ? sheet.left : sheet.right, p))
            guard s.type == 2 else { return }
            for _ in 0..<2 {
                var vy = Int(w.rng.next(400)) - 200 - Int(s.particleOffsetY)
                let rx = Int(w.rng.next(6))
                let ry = Int(w.rng.next(6))
                if Int16(truncatingIfNeeded: vy) < 0 { vy = 0 }               // `extsh.; bge`
                let vx = Int(w.rng.next(400)) - 200 - Int(s.particleOffsetX)
                let shape = Int(w.rng.next(2)) + 1
                particle(200, 0xfa, v: y + ry + 5, h: x + rx + 10, shape: shape, vx: vx, vy: vy)
            }
        case 3, 7:
            setFace(face(0x45b, advance(5)))
            guard s.type == 3 else { return }
            for _ in 0..<5 {
                _ = w.rng.next(400)                                             // drawn, never read
                let rx = Int(w.rng.next(6))
                let ry = Int(w.rng.next(6))
                let vy = Int(w.rng.next(800)) + Int(s.vy) - 400
                let vx = Int(w.rng.next(400)) - 200 - Int(s.particleOffsetX)
                let shape = Int(w.rng.next(2)) + 1
                particle(3, 0x15e, v: y + ry + 5, h: x + rx + 10, shape: shape, vx: vx, vy: vy)
            }
        case 4:
            _ = advance(5)
            for _ in 0..<7 {
                _ = w.rng.next(400)                                             // drawn, never read
                let rx = Int(w.rng.next(8))
                let ry = Int(w.rng.next(8))
                let vy = Int(w.rng.next(400)) - 200
                let vx = Int(w.rng.next(400)) - 200 - Int(s.particleOffsetX)
                let shape = Int(w.rng.next(2)) + 1
                particle(9, 0, v: y + ry + 4, h: x + rx + 9, shape: shape, vx: vx, vy: vy)
            }
        case 5:
            setFace(face(0x459, advance(5)))
            guard 0xc < s.shotAge, let pID = w.playerID, let p = w.active.record(id: pID) else { return }
            let target = (v: Int16(truncatingIfNeeded: p.centre.y) &- 4, h: Int16(truncatingIfNeeded: p.centre.x))
            let from = (v: Int16(truncatingIfNeeded: s.centre.y), h: Int16(truncatingIfNeeded: s.centre.x))
            let dir = BloodSpray.direction(target: target, from: from)
            w.active.update(id: id) { t in
                addDirImpulse(&t, dir: dir, magnitude: 800)
                t.enforceMaxSpeed(0x1450)
            }
        case 6, vBladeLower:
            let p = advance(9)
            setFace(face(0x45a, s.type == 6 ? p : p + 10))
            let cy = Int(Int16(truncatingIfNeeded: s.centre.y)), py = Int(w.player.centreY)
            if cy < py - 500 || py + 500 < cy { w.active.update(id: id) { $0.dead = true } }
        case orb:
            w.active.update(id: id) { t in
                t.face = face(0x45e, 0)
                t.stackY &+= 1
                if 0xf < t.stackY { t.stackY = 0 }
                t.lightOverlay = false
                switch t.stackY >> 1 {
                case 0...1: t.mode = 0
                case 2...3, 6...7: t.mode = 0x10008
                case 4...5: t.mode = 0x10009
                default: break
                }
                if t.stepY < 0 {                                                // `+0x164`: the orb's flash timer
                    t.stepY &+= 1
                    switch t.stepY {
                    case -9 ... -7: t.mode = 0xb0002
                    case -6 ... -4: t.mode = 0xb0000
                    case -3 ... -1: t.mode = 0xb0001
                    default: t.mode = 0
                    }
                }
            }
        case seed:
            let p = advance(7)
            w.active.update(id: id) { t in
                t.face = face(0x45c, p)
                if t.seedHidden != 0 { t.face = nil }
                t.counterA6 = 0
                if t.classWordF4 == 0 {
                    t.hp = 800
                } else {
                    t.hp = 0x578
                    t.mode = 0x10004
                }
            }
        default:
            break
        }
    }

    /// Step 5's light (M l. 50709–50776): at (y + 8, x + 0xc + (vx >> 8)) — x / y the pixel position after the
    /// un-shift — `.AddLight(810, point, (short)vx, (short)vy, gravity, colour)`: id 0 → 0x16; 1, 2 → 0x21; 3 → 0x4d;
    /// 4 → 0x42; 5 → 0x16 at (y + 0x10, x + 0x10 + vx >> 8); 7 → 0x21 at (y + 0xe, x + 0xe + vx >> 8); 6 and 0x3c →
    /// face 822, 0x2c at (y + 0x14, x + 0x10 + vx >> 8); any other id none. Returns the slot for `+0x9a` (nil: no call).
    static func ageOneLight(_ s: SpriteSlot, lights: inout LightTable) -> Int16? {
        let x = Int16(truncatingIfNeeded: s.x), y = Int16(truncatingIfNeeded: s.y)
        let dvx = Int16(truncatingIfNeeded: s.vx >> 8)
        let vx = Int16(truncatingIfNeeded: s.vx), vy = Int16(truncatingIfNeeded: s.vy)
        func add(_ f: LightFaceRef, _ v: Int16, _ h: Int16, _ colour: Int16) -> Int16 {
            lights.add(face: f, x: h, y: v, vx: vx, vy: vy, accelY: s.gravity, colour: colour)
        }
        let v8 = y &+ 8, h12 = x &+ 0xc &+ dvx
        switch s.type {
        case 0: return add(light, v8, h12, 0x16)
        case 1, 2: return add(light, v8, h12, 0x21)
        case 3: return add(light, v8, h12, 0x4d)
        case 4: return add(light, v8, h12, 0x42)
        case 5: return add(light, y &+ 0x10, x &+ 0x10 &+ dvx, 0x16)
        case 7: return add(light, y &+ 0xe, x &+ 0xe &+ dvx, 0x21)
        case 6, vBladeLower: return add(vBladeLight, y &+ 0x14, x &+ 0x10 &+ dvx, 0x2c)
        default: return nil
        }
    }

    /// `FUN_1003f218(s, dir, m) @ 1003f218` (spells-detail-2 §3; raw `1003f218..1004047c`, jump table `0x100a5694`):
    /// nothing for dir > 35; dir 0 / 9 / 18 / 27 → vx − m / vy + m / vx + m / vy − m (integer); any other dir k = 10·d
    /// degrees from the left, clockwise through down: vx += −cos·m, vy += sin·m with the table doubles 0.174, 0.342,
    /// 0.5, 0.643, 0.766, 0.866, 0.94, 0.985 (`100a18c0` … `100a18c8`), each as one `fmadd` / `fnmsub` (fused) on the
    /// double of the field, then `fctiwz`. The decompile and the raw (entry 12 at `10040120`) agree on every case.
    static func addDirImpulse(_ s: inout SpriteSlot, dir: Int, magnitude m: Int32) {
        guard (0...0x23).contains(dir) else { return }
        switch dir {
        case 0: s.vx &-= m; return
        case 9: s.vy &+= m; return
        case 0x12: s.vx &+= m; return
        case 0x1b: s.vy &-= m; return
        default: break
        }
        // sin(10k°), k = 1…8, as stored.
        let sine: [Double] = [0, 0.174, 0.342, 0.5, 0.643, 0.766, 0.866, 0.94, 0.985]
        let q = dir / 9, k = dir % 9
        let c = sine[9 - k], sn = sine[k]                                   // cos(10k°) = sin(10(9 − k)°)
        // (x, y) signs per quadrant: 1…8 (−cos, +sin), 10…17 (+sin, +cos), 19…26 (+cos, −sin), 28…35 (−sin, −cos).
        let (ax, ay): (Double, Double)
        switch q {
        case 0: (ax, ay) = (-c, sn)
        case 1: (ax, ay) = (sn, c)
        case 2: (ax, ay) = (c, -sn)
        default: (ax, ay) = (-sn, -c)
        }
        let md = Double(m)
        s.vx = fctiwz(Double(s.vx).addingProduct(ax, md))
        s.vy = fctiwz(Double(s.vy).addingProduct(ay, md))
    }

    /// `fctiwz`: toward zero, saturating at the int range.
    static func fctiwz(_ d: Double) -> Int32 {
        if d.isNaN { return Int32.min }
        if d >= 2_147_483_647 { return Int32.max }
        if d <= -2_147_483_648 { return Int32.min }
        return Int32(d.rounded(.towardZero))
    }

    // MARK: - the tile callback

    /// `.HitPlayerShotTileSprite(s, pos, kind, layer) @ 1005b0bc` (M l. 51219–51392; raw `1005b0bc..1005b66c`;
    /// spells-detail §3.3). Nothing when `+0xe9 ≠ 0` (or the debug key 0x32 held — debug mode off here); ids 6 / 0x3c
    /// take only the crunch layer (M l. 51257). The factor is 0xa0 for the seed 0x5a (bounce flag set), else 0 (M l.
    /// 51248–51251); vCentre is the hot rect's vertical centre offset (`sStack_50`). By layer:
    /// - FG (id ≠ 100, M l. 51259–51327): unless the orb, `.WallBounce(s, kind, &pos, vCentre, f, +0x34, 0, seed)`; on
    ///   a contact: id 3 with the side test (M l. 51263–51297: kind 4…5 / 6…7 need vx 0) makes a wall ledge
    ///   `MTNewSprite(0x57c, …)` // later: SW (`.SetupPlatformSprite` draws nothing, M l. 54497–54536); then, unless id
    ///   4 grounded (`+0xce`), the contact rule (`contact`); id 4 grounded: the trunk (`trunkLanding`);
    /// - BG (id ≠ 100) kind < 100 (M l. 51330–51347): as FG without the ledge and trunk; 100…199 (M l. 51348–51372):
    ///   `.WallBounceBG(s, kind − 100, …)`, a contact with id 4 grounded makes a trunk bottom `MTNewSprite(0x2c8, +0x10
    ///   − 8, +0xe − 6, 2, −1, .SetupBoxSprite)` with `+0xa6 = 0x78` // later: SW (no draws, no sound), then the contact
    ///   rule; ≥ 200: a liquid (`.IsWaterTile`) with `+0x140` clear → `.HandleUnderWater(s, pos)` (M l. 51374–51378);
    /// - crunch (M l. 51380–51386): `.CrunchTile(pos, (short)+0x158)` processed (≠ 0) and the id not 6 / 0x3c →
    ///   `.KillPlayerShot(s, 1, 1)`.
    /// The contact rule (M l. 51298–51311): the seed dies only when `|vy| < 0x200` after the bounce; every other id
    /// `.KillPlayerShot(s, 1, 1)`. `.KillPlayerShot`'s stale r29 here is the factor — 0 for every id it can recolour —
    /// low memory [LOW]: no light changed.
    static func hitTile(_ solver: TileSolver, _ id: Int, _ posIn: TilePos, _ kind: Int, _ layer: TileLayer,
                        lights: inout LightTable, effects: Int16,
                        faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                        faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        let w = solver.world
        guard let s = w.active.record(id: id), s.killCount == 0 else { return }
        let t = s.type
        guard (t != 6 && t != vBladeLower) || layer == .crunch else { return }
        let seedShot = t == seed
        let factor: Int16 = seedShot ? 0xa0 : 0
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        var pos = posIn
        func killShot() {
            PlayerShotHits.kill(w, shot: id, sound: true, effect: true, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds)
        }
        func contact() {
            guard let c = w.active.record(id: id) else { return }
            if c.type == seed {
                if TileSolver.magnitude(c.vy) < 0x200 { killShot() }
            } else {
                killShot()
            }
        }
        switch layer {
        case .foreground:
            guard t != 100, t != orb,
                  solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: factor, rect: r,
                                    bounce: seedShot) else { return }
            // id 3: the wall ledge // later: SW.
            guard let c = w.active.record(id: id) else { return }
            if c.groundKind == 0 || c.type != 4 {
                contact()
            } else {
                trunkLanding(w, shot: id, effects: effects, lights: &lights)
            }
        case .background:
            guard t != 100 else { return }
            let k = Int16(truncatingIfNeeded: kind)
            if k < 100 {
                guard t != orb, solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: factor, rect: r,
                                                  bounce: seedShot) else { return }
                contact()
            } else if k < 200 {
                guard t != orb, solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: factor,
                                                    rect: r, bounce: seedShot) else { return }
                // id 4 grounded: the trunk bottom // later: SW.
                contact()
            } else if UnderWater.isWaterTile(kind) && !s.underwaterDone {
                UnderWater.handle(world: w, id: id, pos: pos)
            }
        case .crunch:
            let strength = UInt8(truncatingIfNeeded: Int16(truncatingIfNeeded: s.crunchStrength))
            guard CrunchTiles.crunchTile(w, pos: pos, strength: strength) != 0, t != 6, t != vBladeLower else { return }
            killShot()
        }
    }

    /// The Tree Trunk landing on an FG floor (M l. 51312–51327; raw `1005b2c0..1005b3dc`; spells-detail §3.5): the trunk
    /// bottom `MTNewSprite(0x2c8, +0x10 − 8, +0xe − 6, 2, −1, .SetupBoxSprite)` with `+0xa6 = *_DAT_1009fd30 + 0x78`
    /// // later: SW (the trunk; its Setup draws nothing, M l. 58975–58980); `MTNewSprite(2, trunk +0xc − 6, trunk +0xa
    /// − 9, 0xb, −1, .SetupEffectSprite)` (its package draws), `+0x46 = 8`, `.ChangeLightColor(+0x9a, 0x42)`; the shot
    /// `+0xe9 = 1` directly (the followers fly on, spells-detail-2 §5); `.STPlay3DSound(302, 1, 0x100, shot +0xe)`.
    static func trunkLanding(_ w: SpriteWorld, shot id: Int, effects: Int16, lights: inout LightTable) {
        guard let c = w.active.record(id: id) else { return }
        let bx = h16(c.centre.x - 8), by = h16(c.centre.y - 6)                 // the trunk's `+0xc` / `+0xa`
        if let e = EffectSprite.spawn(w, type: 2, x: bx - 6, y: by - 9, layer: 0xb, effects: effects, lights: &lights) {
            w.active.update(id: e) { $0.phase = 8 }
            if let light = w.active.record(id: e)?.light { lights.changeColor(light, 0x42) }
        }
        w.active.update(id: id) { $0.dead = true }
        w.player.cue(PlayerCue(call: .threeD, snd: PlayerShotHits.trunkSound, priority: 1, volume: 0x100,
                               position: c.centre))
    }
}

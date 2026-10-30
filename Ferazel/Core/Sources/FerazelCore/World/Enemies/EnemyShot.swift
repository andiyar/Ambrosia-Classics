import Foundation

/// The EnemyShot class (plan S2 `EnemyShot`, ES; enemy-shots-and-damage §1, enemy-shots-and-damage-2 §4.1–§4.3, §4.6):
/// `.InitEnemyShotSprite @ 1005b670` (M l. 51393–51439, the faces), `.SetupEnemyShotSprite @ 1005ba5c` (M l.
/// 51442–51611, `setup`), `.HandleEnemyShotSprite @ 1005bffc` (M l. 51614–51908, `handle`), `.HitEnemyShotSprite @
/// 1005c9a8` (M l. 51911–51964, `hit`), `.KillEnemyShot @ 1005cc08` (M l. 51967–52091, `kill`) and
/// `.HitEnemyShotTileSprite @ 1005d034` (M l. 52094–52258, `hitTile`); `.ShieldBlock @ 10055434` (M l. 48359–48444,
/// `shieldBlock`). No placement uses the class: every shot is `MTNewSprite(type, x, y, layer, −1,
/// .SetupEnemyShotSprite)` from a spawner (`spawn`). The type numbers reuse the spawner type space — the class is the
/// Handle (`SpriteHandler.enemyShot`), never the type. Every type of §1.2 is built, the boss types' arms (0x46a…0x46c,
/// 0x71f, 0x753, 0x771 / 0x772 with `+0x16c`, 0x77b) as read: their spawners are Phase 6's.
///
/// Fields (`SpriteSlot`): `+0x14c` lifetime `classTimer`; `+0x150` the bounce budget `bounceCount` (`classWord150`);
/// `+0x154` the once-a-frame bounce gate `classWord154`; `+0x15c` 0x753's fuse / 0x77b's spin reversal
/// `classWord15c`; `+0x160` a reflected Wraith shot `classWord160`; `+0x164` a shard's age `shardAge` (`launchSpeed`);
/// `+0x16c` passes walls (Xichra's darts) `classWord16c`; `+0xa6` the age `counterA6`; `+0xa4` the damage `hp`.
public enum EnemyShot {
    /// The types the arms name (enemy-shots-and-damage §1.2).
    public static let swing: Int16 = 0x6a9, axSwing: Int16 = 0x6d6, boulder: Int16 = 0x6e1, bomb: Int16 = 0x6e2,
                      shard: Int16 = 0x6e6, wraith: Int16 = 0x6f4, frogSpit: Int16 = 0x709, spit: Int16 = 0x712,
                      warriorShot: Int16 = 0x71f, egg: Int16 = 0x753, spine: Int16 = 0x754, fireball: Int16 = 0x46a,
                      chiefBoulder: Int16 = 0x77b

    /// `.InitEnemyShotSprite`'s boot loads (M l. 51402–51432; clut 200), the sets `_DAT_100a0888` … `_DAT_100a084c`:
    /// 0x6a7 (8 × 24×24, 4 a row — the axes and the default face), 0x6e1 / 0x6e2 (8 × 32×32), 0x6e6 (8 × 16×16),
    /// 0x454…0x457 (6 × 24×15, one a row — the spits), 0x45d (15 × 24×24, the Wraith shot), 0x754 (8 × 18×18), the
    /// single 0x753, 0x71f (16 × 48×48, 8 a row), the singles 0x771…0x774 (the darts). `BootFaces` holds them.
    public static let sheets: [SetupFaces.Sheet] = [
        SetupFaces.Sheet(pict: 0x6a7, count: 8, cellWidth: 0x18, cellHeight: 0x18, columns: 4, clut: 200),
        SetupFaces.Sheet(pict: 0x6e1, count: 8, cellWidth: 0x20, cellHeight: 0x20, columns: 8, clut: 200),
        SetupFaces.Sheet(pict: 0x6e2, count: 8, cellWidth: 0x20, cellHeight: 0x20, columns: 8, clut: 200),
        SetupFaces.Sheet(pict: 0x6e6, count: 8, cellWidth: 0x10, cellHeight: 0x10, columns: 8, clut: 200),
        SetupFaces.Sheet(pict: 0x454, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x455, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x456, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x457, count: 6, cellWidth: 0x18, cellHeight: 0xf, columns: 1, clut: 200),
        SetupFaces.Sheet(pict: 0x45d, count: 0xf, cellWidth: 0x18, cellHeight: 0x18, columns: 0xf, clut: 200),
        SetupFaces.Sheet(pict: 0x754, count: 8, cellWidth: 0x12, cellHeight: 0x12, columns: 8, clut: 200),
        .single(0x753),
        SetupFaces.Sheet(pict: 0x71f, count: 0x10, cellWidth: 0x30, cellHeight: 0x30, columns: 8, clut: 200),
        .single(0x771), .single(0x772), .single(0x773), .single(0x774),
    ]

    /// `.InitEnemyShotSprite`'s level-load caches (`.CacheEncFaceSetFromPICT`, M l. 51434–51437; `CachedFaces`):
    /// 0x46a as 6 × 48×48 (`_DAT_100a0848`, the fireball) and twice as 6 × 64×64 (`_DAT_100a0844` / `0840`, the dead
    /// types 0x46b / 0x46c, enemy-shots-and-damage-2 §4.1), and 0x77b 16 × 112×112, 4 a row (`_DAT_100a083c`, the
    /// Chief's boulder). Only the boss Setups mark them needed (M l. 74412–74416, 75070, 75629, 76343–76347: Demon,
    /// Chief, Wizard, Xichra) — none placed on levels 1–5. // later: Phase 6 — the boss Setups' marks.
    public static let cachedSheets: [SetupFaces.Sheet] = [
        SetupFaces.Sheet(pict: fireball, count: 6, cellWidth: 0x30, cellHeight: 0x30, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: fireball, count: 6, cellWidth: 0x40, cellHeight: 0x40, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: fireball, count: 6, cellWidth: 0x40, cellHeight: 0x40, columns: 6, clut: 200),
        SetupFaces.Sheet(pict: chiefBoulder, count: 0x10, cellWidth: 0x70, cellHeight: 0x70, columns: 4, clut: 200),
    ]

    /// The snd slots (`SoundSlots`): `*_DAT_100a03ac` 436 'Object Hit', `*_DAT_1009fdec` 435 'explosion',
    /// `*_DAT_100a0420` 301, `*_DAT_100a041c` 303 'metal hit'.
    static let objectHitSound: Int16 = 436, explosionSound: Int16 = 435, hitSound: Int16 = 301, metalSound: Int16 = 303

    /// −0.38 (f64 `0x100a1a18`, the shield's reflection), −0.15 (`0x100a1a00`, the Chief boulder's rebound), 0.9
    /// (`0x100a1a58`, the egg's roll) — read from the PEF data section.
    static let reflect = Double(bitPattern: 0xbfd8_51eb_851e_b852)
    static let rebound = Double(bitPattern: 0xbfc3_3333_3333_3333)
    static let roll = Double(bitPattern: 0x3fec_cccc_cccc_cccd)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    /// A face of sheet `pict`.
    static func face(_ pict: Int16, _ index: Int) -> FaceRef { FaceRef(pict: pict, index: index, set: .encoded) }

    /// `(int)((double)v · f)` (`fctiwz`).
    static func scaled(_ v: Int32, _ f: Double) -> Int32 { PlayerShot.fctiwz(Double(v) * f) }

    /// `MTNewSprite(type, x, y, layer, −1, .SetupEnemyShotSprite)`: nil when no record is free (Ruling 16: no Setup, no
    /// draws — the caller's stores to it are dropped, its later draws still made).
    @discardableResult
    public static func spawn(_ w: SpriteWorld, type: Int16, x: Int, y: Int, layer: Int16) -> Int? {
        w.newSprite(type: type, x: x, y: y, layer: layer, handler: .enemyShot) { s in setup(w, &s) }
    }

    // MARK: - Setup

    /// `.SetupEnemyShotSprite` (M l. 51442–51611; raw `1005ba5c..1005bfd0`), inside `.MTNewSprite` before the insert:
    /// `.InitSprite`; `+0x84`/`+0x86` 0; `+0x46 = FastRand(5)`; the Handle, hit and tile callbacks; `+0xa6` 0; `+0x90`
    /// 0x100; gravity 0xaf; face 0; `+0x8c` 1; then by type —
    /// - 0x6a9: layer 0x14, rect (0, 0, 0x5a, 0xe), `+0x14c` 2, gravity 0;
    /// - 0x6e1 / 0x6e2: rect (8, 8, 0x18, 0x18), gravity 300, `+0x150 = −2 − R(2)`, HP 200, `R(100) > 0x56` →
    ///   `+0x150 −= 3 − R(5)`, `+0xeb` 1;
    /// - 0x6e6: rect (6, 6, 10, 10); 0x709 (the first arm, raw `1005bbd0` — the later `+0xa4 = 0x38` arm is dead) and
    ///   0x712: gravity 0, rect (8, 3, 0xf, 0xc);
    /// - 0x6d6: face 0, rect (0, 0, 0x3c, 0x18), `+0xa6` 3, HP 0x70;
    /// - 0x6f4: face 0, rect (5, 5, 0x12, 0xc), `+0x46 = R(0xf)`, gravity 0, HP 0x70, `+0x88` 0, `+0xa6` 0;
    /// - 0x753: rect (4, 0, 0x14, 0xe), HP 0x1c0, `+0x46` 6, R(100) → `+0x17e = R > 0x32` (raw `1005bd08..1005bd24`:
    ///   `eqv; subfc; addze` — the signed `0x32 < R`), `+0x15c` 0xf0;
    /// - 0x754: rect (8, 3, 10, 8), layer 0xc, gravity 0; 0x71f: rect (0x12, 0x12, 0x1e, 0x1e), `+0x46` 0, gravity 0;
    /// - 0x771 / 0x772: rect (2, −4, 0x3a, 4), HP 0x38, `+0x46` 0, gravity 0, the single face; 0x773 / 0x774: rect
    ///   (0, 0xc, 8, 0x30), the same;
    /// - 0x77b: rect (0x20, 0x20, 0x50, 0x38), gravity 0x140, `+0x15c` 0, **no tile callback** (`+0x1f8` 0);
    /// - 0x46a: layer 8, rect (6, 6, 0x2a, 0x1a), gravity 0, `+0x46 = R(5)`, `+0x88` 0; 0x46b / 0x46c: layer 8, rect
    ///   (8, 8, 0x38, 0x32), the same;
    /// - any other type: rect (8, 8, 0x10, 0x10).
    /// Then `+0xc ← +8`, `+0xa ← +6` and the 24.8 position from those shorts. (`SetRect(r, left, top, right, bottom)`.)
    static func setup(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        func rect(_ l: Int, _ t: Int, _ r: Int, _ b: Int) { s.hotRect = IdleSprites.Rect(top: t, left: l, bottom: b, right: r) }
        s.particleOffsetY = 0
        s.particleOffsetX = 0
        s.phase = w.rng.next(5)
        s.handler = .enemyShot
        s.hasHit = true                                                 // `+0x5c` = `.HitEnemyShotSprite`
        s.hasTileHit = true                                             // `+0x1f8` = `.HitEnemyShotTileSprite`
        s.counterA6 = 0
        s.windScale = 0x100
        s.gravity = 0xaf
        s.face = nil
        s.burnPitched = true                                            // `+0x8c = 1`
        let t = s.type
        switch t {
        case swing:
            s.layer = 0x14
            rect(0, 0, 0x5a, 0xe)
            s.classTimer = 2
            s.gravity = 0
        case boulder, bomb:
            rect(8, 8, 0x18, 0x18)
            s.gravity = 300
            s.bounceCount = -2 &- Int32(w.rng.next(2))
            s.hp = 200
            if 0x56 < w.rng.next(100) {
                s.bounceCount &-= 3 &- Int32(w.rng.next(5))
            }
            s.crunches = 1
        case shard:
            rect(6, 6, 10, 10)
        case frogSpit, spit:
            s.gravity = 0
            rect(8, 3, 0xf, 0xc)
        case axSwing:
            s.face = nil
            rect(0, 0, 0x3c, 0x18)
            s.counterA6 = 3
            s.hp = 0x70
        case wraith:
            s.face = nil
            rect(5, 5, 0x12, 0xc)
            s.phase = w.rng.next(0xf)
            s.gravity = 0
            s.hp = 0x70
            s.lightOverlay = false
            s.counterA6 = 0
        case egg:
            rect(4, 0, 0x14, 0xe)
            s.hp = 0x1c0
            s.phase = 6
            s.mirrored = 0x32 < w.rng.next(100)
            s.classWord15c = 0xf0
        case spine:
            rect(8, 3, 10, 8)
            s.layer = 0xc
            s.gravity = 0
        case warriorShot:
            rect(0x12, 0x12, 0x1e, 0x1e)
            s.phase = 0
            s.gravity = 0
        case 0x771, 0x772:
            rect(2, -4, 0x3a, 4)
            s.hp = 0x38
            s.phase = 0
            s.gravity = 0
            s.face = face(t, 0)
        case 0x773, 0x774:
            rect(0, 0xc, 8, 0x30)
            s.phase = 0
            s.gravity = 0
            s.hp = 0x38
            s.face = face(t, 0)
        case chiefBoulder:
            rect(0x20, 0x20, 0x50, 0x38)
            s.gravity = 0x140
            s.classWord15c = 0
            s.hasTileHit = false
        case fireball:
            s.layer = 8
            rect(6, 6, 0x2a, 0x1a)
            s.gravity = 0
            s.phase = w.rng.next(5)
            s.lightOverlay = false
        case 0x46b, 0x46c:
            s.layer = 8
            rect(8, 8, 0x38, 0x32)
            s.gravity = 0
            s.phase = w.rng.next(5)
            s.lightOverlay = false
        default:
            rect(8, 8, 0x10, 0x10)
        }
        s.x = s.oldPosition.x
        s.y = s.oldPosition.y
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
    }

    // MARK: - Handle

    /// `.HandleEnemyShotSprite(s)` (M l. 51614–51908; raw `1005bffc..1005c9a4`), unless `+0xe9` or `+0x1b2`:
    /// 1. `.StandardSpriteHandles`; `+0xa6` + 1 (every type; raw `1005c050`); `+0x14c > 0` → − 1, at 0 `+0xe9 = 1`;
    ///    type 1 → `+0x46` − 1, type 0 → + 1;
    /// 2. the type arm (`typeArm`);
    /// 3. `.ApplyGravityAndSeparateFromTiles` (the tile callback `hitTile` while `+0x1f8`); `+0x154 > 0` → − 1;
    ///    `hdr+0xb282 << 5 < +0xa` → `+0xe9 = 1`; `.StandardSpriteCleanup`;
    /// 4. 0x46a with a flame level (`hdr+0x2722 ≠ 0`): at (x + 0x18 − camX, (y + 0x18 − camY) / 4) inside 0…0x26f ×
    ///    0…0x5d, 26 columns of two `.FlameAddSpark(buf, h, v (+1), FastRand(0x18) + 0xe6)` — the draws made, the flame
    ///    buffer // later: Phase 6 (no flame level and no fireball before level 6);
    /// 5. camX − x ≥ 1001, or x − (camX + 640) > 1000 → `+0xe9 = 1` (camX the scroll point `PTR_DAT_1009fe78 + 2`).
    /// A shot killed during the call (lifetime, the egg's fuse, a tile kill) finishes it.
    /// - Parameters: `faceWidth` (face `+6`, the Cleanup) and `faceBounds` (face `+8`, 0x77b's hot rect) — Core has no
    ///   face records; `lights` / `effects` reach `.KillEnemyShot`'s Effects.
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver, lights: inout LightTable,
                              effects: Int16, faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                              faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.handleSkip else { return }
        w.standardSpriteHandles(id)
        w.active.update(id: id) { s in
            s.counterA6 &+= 1
            if 0 < s.classTimer {
                s.classTimer &-= 1
                if s.classTimer == 0 { s.dead = true }
            }
            if s.type == 1 { s.phase &-= 1 } else if s.type == 0 { s.phase &+= 1 }
        }
        var flame = false
        typeArm(w, id: id, lights: &lights, effects: effects, faceBounds: faceBounds, flame: &flame)
        if let s = w.active.record(id: id), s.hasTileHit {
            withoutActuallyEscaping({ (sv: TileSolver, i: Int, c: TilePos, k: Int, l: TileLayer) in
                hitTile(sv, i, c, k, l, lights: &lights, effects: effects)
            }) { pass in solver.applyGravityAndSeparate(id, pass: pass) }
        } else {
            solver.applyGravityAndSeparate(id, pass: nil)
        }
        w.active.update(id: id) { s in
            if 0 < s.classWord154 { s.classWord154 &-= 1 }
            if Int(w.level.header.gridHeight) << 5 < h16(s.y) { s.dead = true }
        }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        guard let s = w.active.record(id: id) else { return }
        if flame && w.level.header.flameMode != 0 {
            var h = h16(h16(s.x) + 0x18 - w.player.scrollH)
            let dv = h16(s.y) + 0x18 - w.player.scrollV
            let v = h16(dv / 4)                                         // `srawi 2; addze`: toward zero
            if 0 <= h && h < 0x270 && 0 <= v && v < 0x5e {
                for _ in 0..<0x1a {
                    _ = w.rng.next(0x18)                                // `.FlameAddSpark(buf, h, v, R + 0xe6)`
                    _ = w.rng.next(0x18)                                // `.FlameAddSpark(buf, h, v + 1, R + 0xe6)`
                    h += 1                                              // // later: Phase 6 — the flame buffer
                }
            }
        }
        let camX = h16(w.player.scrollH), x = h16(s.x)
        if camX - x < 0x3e9 {
            if 1000 < x - (camX + 0x280) { w.active.update(id: id) { $0.dead = true } }
        } else {
            w.active.update(id: id) { $0.dead = true }
        }
    }

    /// The Handle's type arm (M l. 51667–51879). Faces are the boot sets by cell (`+0x46`), or a cache's (0x46a…0x46c,
    /// 0x77b):
    /// - 0x6a9: face 0; 0x6d6: `+0xa6` − 1, below 1 `+0xe9 = 1` (the + 1 above makes it never time out);
    /// - 0x6e1 / 0x6e2 / 0x6e6: `+0x46` + 1, wrapped 0…7; 0x6e6 also `+0x164` + 1; the face of its own set;
    /// - 0x6f4: the tint by `+0xa6` (< 3 0xb0002, < 5 0xb0000, < 7 0xb0001, else 0); `+0xa6 < 0x14` → `FUN_1003f218(s,
    ///   .FindDesiredDirectionGeneric((pcy + 8, pcx), (y + 0xc, x + 0xc)), 0x8c)` (the player's centre `*_DAT_1009fd90`
    ///   / `fd94`); `+0x46` + 1, past 0xe → 0; face 0x45d;
    /// - 0x709: `+0x46` + 1, past 5 → 0; vx < 1 → 0x455, else 0x454; 0x712: `+0x88` 0, the same with 0x457 / 0x456;
    /// - 0x71f: `+0x46` + 1, past 0xf → 0; `+0x17e = vx > 0` (raw `1005c408..1005c428`: `eqv; subfc; addze`); 0x71f;
    /// - 0x753: gravity 0x100; the single 0x753; `+0x46` − 1, below 1 → `+0xaa` 5, `+0x46` 0x2d; `+0x15c` − 1, below 1
    ///   → `.KillEnemyShot` (and on); vx = (int)(vx · 0.9); grounded (`+0xce`) → vx 0;
    /// - 0x754: face 0x754[`+0x46`]; 0x76c…0x775: nothing;
    /// - 0x77b: `+0x46` ± 1 (− while `+0x15c`), wrapped 0…0xf; the cache face; the hot rect = the face's bounds (face
    ///   `+8`) with top + 4, left + 4, right − 4, bottom − 3; `hdr+0xb282·0x20 + 0x20 < +0xa` → `+0xe9 = 1`;
    /// - 0x46a: `+0x46` + 1, past 5 → 0; the cache face; with no flame level (`hdr+0x2722 == 0`) n = R(3) + 5
    ///   particles: R(0x24) (dh), R(0x24) (dv), R(2) → `NewParticle(1, 0xbe, (y + vy >> 8 + 6 + dv, x + vx >> 8 + 6 +
    ///   dh), R + 1, 0, 0, 0, 1)`; the flame sparks after the Cleanup (`flame`); 0x46b / 0x46c: `+0x46` + 1, past 5 → 0,
    ///   their cache's face;
    /// - any other type: `+0x46` wrapped 0…7 (no step: types 0 / 1 stepped above), face 0x6a7.
    /// The three 0x46a caches share one PICT (`FaceRef` keys a face by PICT and cell): the 64×64 pair of the dead
    /// types is faced from the same PICT's cells [LOW: dead types].
    static func typeArm(_ w: SpriteWorld, id: Int, lights: inout LightTable, effects: Int16,
                        faceBounds: (FaceRef) -> IdleSprites.Rect, flame: inout Bool) {
        guard let s = w.active.record(id: id) else { return }
        func wrap8(_ t: inout SpriteSlot) {
            if t.phase < 8 {
                if t.phase < 0 { t.phase = 7 }
            } else {
                t.phase = 0
            }
        }
        switch s.type {
        case swing:
            w.active.update(id: id) { $0.face = nil }
        case axSwing:
            w.active.update(id: id) { t in
                t.counterA6 &-= 1
                if t.counterA6 < 1 { t.dead = true }
            }
        case boulder, bomb, shard:
            w.active.update(id: id) { t in
                t.phase &+= 1
                wrap8(&t)
                if t.type == shard { t.shardAge &+= 1 }
                t.face = face(t.type, Int(t.phase))
            }
        case wraith:
            w.active.update(id: id) { t in
                let age = t.counterA6
                t.mode = age < 3 ? 0xb0002 : age < 5 ? 0xb0000 : age < 7 ? 0xb0001 : 0
            }
            if let t = w.active.record(id: id), t.counterA6 < 0x14 {
                let from = (v: Int16(truncatingIfNeeded: t.y + 0xc), h: Int16(truncatingIfNeeded: t.x + 0xc))
                let target = (v: w.player.centreY &+ 8, h: w.player.centreX)
                let dir = BloodSpray.direction(target: target, from: from)
                w.active.update(id: id) { PlayerShot.addDirImpulse(&$0, dir: dir, magnitude: 0x8c) }
            }
            w.active.update(id: id) { t in
                t.phase &+= 1
                if 0xe < t.phase { t.phase = 0 }
                t.face = face(0x45d, Int(t.phase))
            }
        case frogSpit, spit:
            w.active.update(id: id) { t in
                if t.type == spit { t.lightOverlay = false }
                t.phase &+= 1
                if 5 < t.phase { t.phase = 0 }
                let sheet: Int16 = t.type == frogSpit ? (t.vx < 1 ? 0x455 : 0x454) : (t.vx < 1 ? 0x457 : 0x456)
                t.face = face(sheet, Int(t.phase))
            }
        case warriorShot:
            w.active.update(id: id) { t in
                t.phase &+= 1
                if 0xf < t.phase { t.phase = 0 }
                t.mirrored = 0 < t.vx
                t.face = face(warriorShot, Int(t.phase))
            }
        case egg:
            w.active.update(id: id) { t in
                t.gravity = 0x100
                t.face = face(egg, 0)
                t.phase &-= 1
                if t.phase < 1 {
                    t.flash = 5
                    t.phase = 0x2d
                }
                t.classWord15c &-= 1
            }
            if let t = w.active.record(id: id), t.classWord15c < 1 { kill(w, shot: id, lights: &lights, effects: effects) }
            w.active.update(id: id) { t in
                t.vx = scaled(t.vx, roll)
                if t.groundKind != 0 { t.vx = 0 }
            }
        case spine:
            w.active.update(id: id) { $0.face = face(spine, Int($0.phase)) }
        case 0x76c...0x775:
            break
        case chiefBoulder:
            w.active.update(id: id) { t in
                if t.classWord15c == 0 { t.phase &+= 1 } else { t.phase &-= 1 }
                if 0xf < t.phase { t.phase = 0 }
                if t.phase < 0 { t.phase = 0xf }
                t.face = face(chiefBoulder, Int(t.phase))
            }
            if let t = w.active.record(id: id), let f = t.face {
                let b = faceBounds(f)
                w.active.update(id: id) { u in
                    u.hotRect = IdleSprites.Rect(top: h16(b.top + 4), left: h16(b.left + 4), bottom: h16(b.bottom - 3),
                                                 right: h16(b.right - 4))
                    if Int(w.level.header.gridHeight) * 0x20 + 0x20 < h16(u.y) { u.dead = true }
                }
            }
        case fireball:
            w.active.update(id: id) { t in
                t.phase &+= 1
                if 5 < t.phase { t.phase = 0 }
                t.face = face(fireball, Int(t.phase))
            }
            flame = true
            if w.level.header.flameMode == 0, let t = w.active.record(id: id) {
                let n = Int(w.rng.next(3)) + 5
                for _ in 0..<n {
                    let dh = Int(w.rng.next(0x24))
                    let dv = Int(w.rng.next(0x24))
                    let ph = h16(h16(t.x) + Int(Int16(truncatingIfNeeded: t.vx >> 8)) + 6 + dh)
                    let pv = h16(h16(t.y) + Int(Int16(truncatingIfNeeded: t.vy >> 8)) + 6 + dv)
                    let shape = Int(w.rng.next(2)) + 1
                    w.particles.newParticle(kind: 1, gravity: 0xbe, v: pv, h: ph, shape: shape, vx: 0, vy: 0, delay: 0,
                                            mode: 1)
                }
            }
        case 0x46b, 0x46c:
            w.active.update(id: id) { t in
                t.phase &+= 1
                if 5 < t.phase { t.phase = 0 }
                t.face = face(fireball, Int(t.phase))
            }
        default:
            w.active.update(id: id) { t in
                wrap8(&t)
                t.face = face(0x6a7, Int(t.phase))
            }
        }
    }

    // MARK: - hits

    /// `.HitEnemyShotSprite(shot, other)` (M l. 51911–51964; raw `1005c9a8..1005cc04`), nothing once `+0xe9` or `+0x1b2`:
    /// - other the player (`PTR_PTR_100a052c`) and the type none of 0x6e6, 0x709, 0x712, 0x76c…0x775, 0x6f4, 0x753,
    ///   0x754, 0x71f, 0, 1, 0x77b, 0x46a…0x46c — or the type 0x6e1 / 0x6e2 / 0x753 and other a player shot
    ///   (`PTR_PTR_100a04e8`) → `.KillEnemyShot` unless the type is 1, 0x6a9 or 0x6d6;
    /// - else other a Platform (`_DAT_100a0200`) of type 0x584 → `.PlatformBounce(s, other, 0, 0, +0x34, 0)` (the
    ///   centre from the rect, `centre` nil);
    /// - else other a Statue (`PTR_PTR_100a01f8`) or a Box (`PTR_PTR_100a0484`) outside 0x5aa…0x5b3 (the spouts keep
    ///   their own bombs), with `+0x16c == 0`: no one-way top (`+0x185`) and no surface function (`+0x1e8`, `rope`) →
    ///   `.KillEnemyShot` unless 0x6e6; with one → unless 0x6e6, `.PlatformBounce(s, other, the rect centre, 0, +0x34,
    ///   0)`, a contact (≠ 0) → `.KillEnemyShot`.
    /// Every Handle comparison is `+0x4c ==`: an idled record matches none (`BackgroundSprite.runs`).
    public static func hit(_ w: SpriteWorld, shot id: Int, other oID: Int, lights: inout LightTable, effects: Int16) {
        guard let s = w.active.record(id: id), !s.dead, !s.handleSkip, let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        let t = s.type
        let spared: Bool = {
            switch t {
            case shard, frogSpit, spit, 0x76c...0x775, wraith, egg, spine, warriorShot, 0, 1, chiefBoulder, 0x46a...0x46c:
                return true
            default:
                return false
            }
        }()
        if (runs(o, .player) && !spared) || ((t == boulder || t == bomb || t == egg) && runs(o, .playerShot)) {
            if t != 1 && t != swing && t != axSwing { kill(w, shot: id, lights: &lights, effects: effects) }
        } else if runs(o, .platform) && o.type == 0x584 {
            w.platformBounce(mover: id, solid: oID, centre: nil, factor: 0, rect: s.hotRect, bounce: false)
        } else if (runs(o, .statue) || (runs(o, .box) && !(0x5aa...0x5b3).contains(o.type))) && s.classWord16c == 0 {
            if !o.oneWay && o.rope == nil {
                if t != shard { kill(w, shot: id, lights: &lights, effects: effects) }
            } else {
                let r = s.hotRect
                let centre = SpriteSlot.Point(x: h16(r.left + h16((r.right - r.left) >> 1)),
                                              y: h16(r.top + h16((r.bottom - r.top) >> 1)))
                if t != shard && w.platformBounce(mover: id, solid: oID, centre: centre, factor: 0, rect: r,
                                                  bounce: false) != 0 {
                    kill(w, shot: id, lights: &lights, effects: effects)
                }
            }
        }
    }

    /// `.HitEnemyShotTileSprite(s, pos, kind, layer)` (M l. 52094–52258; raw `1005d034..1005d4ec`), nothing while
    /// `+0x16c` (or the debug key 0x32 with the debug flag — off). The contact rule (`contact`): `fast` = |vx| ≥ 0x1195
    /// or |vy| ≥ 0x1965 (before the bounce); `.WallBounce(s, kind, &pos, &vCentre, 0xa0, +0x34, 0, 1)` (restitution
    /// 160/256, enemy-shots-and-damage-2 §4.6); a contact → 0x753: |vy| < 300 → vx = vy = 0, gravity 0x200; any other
    /// type: 0x6e1 / 0x6e2 `.STPlay3DSoundRand(436, 1, 0x55, +0xe)`, `+0x154 == 0` → `+0x150` + 1, `+0x154 = 1`,
    /// `+0x150 ≥ 0` or `fast` → `.KillEnemyShot`. By layer:
    /// - FG (1): only while `+0x154 == 0`, the contact rule;
    /// - BG (0) and crunch (2), types outside 0x46a…0x46f: kind < 100 → the contact rule; 100…199 →
    ///   `.WallBounceBG(s, kind − 100, …)` and the rule's tail as if it hit (its answer is not read); ≥ 200: a liquid
    ///   (`.IsWaterTile`) with `+0x140` clear → `.HandleUnderWater(s, pos)`. A crunch callback (`+0xeb` bombs) carries
    ///   the nibble 1…15 as the kind.
    /// vCentre is the hot rect's vertical centre offset (`sStack_48`).
    public static func hitTile(_ solver: TileSolver, _ id: Int, _ posIn: TilePos, _ kind: Int, _ layer: TileLayer,
                               lights: inout LightTable, effects: Int16) {
        let w = solver.world
        guard let s = w.active.record(id: id), s.classWord16c == 0 else { return }
        let r = s.hotRect
        let vCentre = h16(r.top + h16((r.bottom - r.top) >> 1))
        var pos = posIn
        func isFast(_ c: SpriteSlot) -> Bool {
            TileSolver.magnitude(c.vx) >= 0x1195 || TileSolver.magnitude(c.vy) >= 0x1965
        }
        /// The rule's tail after a contact.
        func tail(fast: Bool) {
            guard let c = w.active.record(id: id) else { return }
            if c.type == egg {
                if TileSolver.magnitude(c.vy) < 300 {
                    w.active.update(id: id) { u in
                        u.vy = 0
                        u.gravity = 0x200
                        u.vx = 0
                    }
                }
                return
            }
            if c.type == boulder || c.type == bomb {
                w.player.cue(PlayerCue(call: .threeDRand, snd: objectHitSound, priority: 1, volume: 0x55,
                                       position: c.centre, rate: w.rng.soundRate()))
            }
            w.active.update(id: id) { u in
                if u.classWord154 == 0 { u.bounceCount &+= 1 }
                u.classWord154 = 1
            }
            if let u = w.active.record(id: id), 0 <= u.bounceCount || fast {
                kill(w, shot: id, lights: &lights, effects: effects)
            }
        }
        if layer == .foreground {
            guard s.classWord154 == 0 else { return }
            let fast = isFast(s)
            if solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0xa0, rect: r, bounce: true) {
                tail(fast: fast)
            }
        } else if s.type < 0x46a || 0x46f < s.type {
            let k = Int16(truncatingIfNeeded: kind)
            if k < 100 {
                let fast = isFast(s)
                if solver.wallBounce(id, kind: kind, tile: &pos, vCentre: vCentre, factor: 0xa0, rect: r, bounce: true) {
                    tail(fast: fast)
                }
            } else if k < 200 {
                let fast = isFast(s)
                solver.wallBounceBG(id, kind: kind - 100, tile: &pos, vCentre: vCentre, factor: 0xa0, rect: r,
                                    bounce: true)
                tail(fast: fast)
            } else if UnderWater.isWaterTile(kind) && !s.underwaterDone {
                UnderWater.handle(world: w, id: id, pos: pos)
            }
        }
    }

    // MARK: - Kill

    /// `.KillEnemyShot(s)` (M l. 51967–52091; raw `1005cc08..1005d030`). It does not test `+0xe9`. In order:
    /// 1. 0x6e1 / 0x6e2: n = R(3) + 3 shards; shard i = 1…n: R(16) (dy), R(16) (dx), `MTNewSprite(0x6e6, x + dx, y + dy,
    ///    (short) layer, −1, .SetupEnemyShotSprite)` (its R(5)), `+0x154 = +0x150 = 1`, R(200i) → vx = parent vx + R −
    ///    100i, R(200i) → vy = parent vy + R − 100i (raw `1005cc68..1005cd14`; the stores dropped with no record);
    /// 2. by type — 0x6e1: `+0xe9 = 1`; 0x6e2: `.STPlay3DSoundRand(435, 1, 0x100, +0xe)`, the Effect 0x4b7 at (x − 0x20,
    ///    y − 0x20), layer 0xc, `+0xe9 = 1`; 0x712: `.STPlay3DSoundRand(301, …)`, the Effect 0 at (x − 8, y − 0xc), layer
    ///    0xb, `+0xe9 = 1`; 0x753: snd 435, the Effect 0x4b7 at (x − 0x2a, y − 0x2a), layer 0xc, then the 4 × 4 walk over
    ///    (x − 4 + 8i, y − 10 + 8j), i outer, a counter from 0 that spawns at every second cell `MTNewSprite(0x442, cx −
    ///    0x18, cy − 0x18, 0xc, −1, .SetupEffectSprite)`, R(0x96), `FUN_1003f218(smoke, .FindDesiredDirectionGeneric((cy,
    ///    cx), +0xe), R + 400)`, smoke `+0x46 = R(7)`; `+0xe9 = 1`; 0x76c…0x775 and 0x754: `+0xe9 = 1`,
    ///    `.ExplodeFaceIntoParticles(+0xc0, +0xa, 1, 1, 1, 100, 100)`; 0x6f4: `+0xe9 = 1`, particles (1, 1, 1, 0, 0x65);
    ///    0x46a: R(13000), `.STPlay3DSoundPitched(301, 1, 0x100, +0xe, R + 44000)`, particles (2, 2, 2, 0x96, 0x66),
    ///    `+0xe9 = 1`; any other: `+0xe9 = 1`.
    public static func kill(_ w: SpriteWorld, shot id: Int, lights: inout LightTable, effects: Int16) {
        guard let s = w.active.record(id: id) else { return }
        let x = h16(s.x), y = h16(s.y)
        let t = s.type
        if t == boulder || t == bomb {
            let n = Int(w.rng.next(3)) + 3
            var i = 1
            while i <= n {
                let dy = Int(w.rng.next(0x10))
                let dx = Int(w.rng.next(0x10))
                let k = spawn(w, type: shard, x: h16(x + dx), y: h16(y + dy), layer: Int16(truncatingIfNeeded: s.layer))
                if let k {
                    w.active.update(id: k) { u in
                        u.classWord154 = 1
                        u.bounceCount = 1
                    }
                }
                let span = Int16(truncatingIfNeeded: 200 * i), half = Int32(100 * i)
                let pvx = w.active.record(id: id)?.vx ?? s.vx
                let ax = Int32(w.rng.next(span)) &- half
                let pvy = w.active.record(id: id)?.vy ?? s.vy
                let ay = Int32(w.rng.next(span)) &- half
                if let k {
                    w.active.update(id: k) { u in
                        u.vx = pvx &+ ax
                        u.vy = pvy &+ ay
                    }
                }
                i += 1
            }
        }
        func dead() { w.active.update(id: id) { $0.dead = true } }
        func play(_ snd: Int16) {
            w.player.cue(PlayerCue(call: .threeDRand, snd: snd, priority: 1, volume: 0x100, position: s.centre,
                                   rate: w.rng.soundRate()))
        }
        func effect(_ type: Int16, _ ex: Int, _ ey: Int, layer: Int16) -> Int? {
            EffectSprite.spawn(w, type: type, x: ex, y: ey, layer: layer, effects: effects, lights: &lights)
        }
        func explode(xStep: Int16, yStep: Int16, shape: Int16, gravity: Int16, style: Int16) {
            ExplodeFace.explode(w, face: s.face.flatMap(w.particleFaces.sprite), v: Int16(truncatingIfNeeded: y),
                                h: Int16(truncatingIfNeeded: x), xStep: xStep, yStep: yStep, shape: shape,
                                gravity: gravity, style: style)
        }
        switch t {
        case boulder:
            dead()
        case bomb:
            play(explosionSound)
            _ = effect(EffectSprite.bigExplosion, x - 0x20, y - 0x20, layer: 0xc)
            dead()
        case spit:
            play(hitSound)
            _ = effect(0, x - 8, y - 0xc, layer: 0xb)
            dead()
        case egg:
            play(explosionSound)
            _ = effect(EffectSprite.bigExplosion, x - 0x2a, y - 0x2a, layer: 0xc)
            var counter: Int16 = 0
            for i in 0..<4 {
                for j in 0..<4 {
                    counter -= 1
                    let cx = Int16(truncatingIfNeeded: x + 8 * i - 4), cy = Int16(truncatingIfNeeded: y + 8 * j - 10)
                    guard counter < 1 else { continue }
                    counter = 2
                    let smoke = effect(EffectSprite.smoke, Int(cx) - 0x18, Int(cy) - 0x18, layer: 0xc)
                    let m = Int32(w.rng.next(0x96)) + 400
                    let dir = BloodSpray.direction(target: (v: cy, h: cx),
                                                   from: (v: Int16(truncatingIfNeeded: s.centre.y),
                                                          h: Int16(truncatingIfNeeded: s.centre.x)))
                    if let smoke { w.active.update(id: smoke) { PlayerShot.addDirImpulse(&$0, dir: dir, magnitude: m) } }
                    let phase = w.rng.next(7)
                    if let smoke { w.active.update(id: smoke) { $0.phase = phase } }
                }
            }
            dead()
        case 0x76c...0x775, spine:
            dead()
            explode(xStep: 1, yStep: 1, shape: 1, gravity: 100, style: 100)
        case wraith:
            dead()
            explode(xStep: 1, yStep: 1, shape: 1, gravity: 0, style: 0x65)
        case fireball:
            let p = Int32(w.rng.next(13000))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: hitSound, priority: 1, volume: 0x100, position: s.centre,
                                   rate: p + 44000))
            explode(xStep: 2, yStep: 2, shape: 2, gravity: 0x96, style: 0x66)
            dead()
        default:
            dead()
        }
    }

    // MARK: - the shield

    /// `.ShieldBlock(player, shot) @ 10055434` (M l. 48359–48444; enemy-shots-and-damage §3.6): ax = shot `+0x10` − (vx
    /// >> 8); side 2 when ax > player `+0xc` + rect right − 10, side 1 when ax < player `+0xc` + rect left + 10 (the
    /// later wins). Blocks — answers true — only when the shot runs the EnemyShot Handle (M l. 48389), a side matched,
    /// it is the facing `_DAT_100a5f5a` and the counter `PTR_DAT_100a05e8 > 2`; then the counter = 7 and:
    /// - darts 0x76c…0x775 and spines 0x754: `.STPlay3DSound(303, 1, 0x100, player +0xe)`, `.HasItem(0xf)` → `+0x1a2 =
    ///   1` (the burn-away, `Burn`); vx = (int)(vx · −0.38), vy likewise, vy − 0x5dc, gravity 0x100;
    /// - 0x6f4 with `.HasItem(0xf)`: once (`+0x160 == 0`) snd 303, vx and vy negated, vy + 0x140, `+0x160 = 1`,
    ///   `.ExplodeFaceIntoParticles(+0xc0, +0xa, 1, 1, 1, 100, 0x65)` — not killed;
    /// - every other shot: snd 303, `.KillEnemyShot`.
    /// The non-shot arm of the body (the Kill proc `+0x50` / `+0xe9 = 1`, M l. 48429–48434) sits behind the same
    /// EnemyShot test and is unreachable — not built.
    @discardableResult
    public static func shieldBlock(_ w: SpriteWorld, player pID: Int, shot oID: Int, lights: inout LightTable,
                                   effects: Int16) -> Bool {
        guard let p = w.active.record(id: pID), let o = w.active.record(id: oID) else { return false }
        let ax = h16(o.centre.x) - Int(o.vx >> 8)
        let right = h16(p.x) + p.hotRect.right - 10 < ax
        let left = ax < h16(p.x) + p.hotRect.left + 10
        let side: Int16? = left ? 1 : right ? 2 : nil
        guard BackgroundSprite.runs(o, .enemyShot), let side, side == w.player.facing, 2 < w.player.shieldRaise else {
            return false
        }
        w.player.shieldRaise = 7
        let metal = PlayerCue(call: .threeD, snd: metalSound, priority: 1, volume: 0x100, position: p.centre)
        let t = o.type
        if (0x76c...0x775).contains(t) || t == spine {
            w.player.cue(metal)
            let magic = w.globals.hasItem(0xf)
            w.active.update(id: oID) { u in
                if magic { EnemyCommon.startBurn(&u) }
                u.vx = scaled(u.vx, reflect)
                u.vy = scaled(u.vy, reflect)
                u.vy &-= 0x5dc
                u.gravity = 0x100
            }
        } else if t == wraith && w.globals.hasItem(0xf) {
            if o.classWord160 == 0 {
                w.player.cue(metal)
                w.active.update(id: oID) { u in
                    u.vx = 0 &- u.vx
                    u.vy = 0 &- u.vy
                    u.vy &+= 0x140
                    u.classWord160 = 1
                }
                ExplodeFace.explode(w, face: o.face.flatMap(w.particleFaces.sprite), v: Int16(truncatingIfNeeded: o.y),
                                    h: Int16(truncatingIfNeeded: o.x), xStep: 1, yStep: 1, shape: 1, gravity: 100,
                                    style: 0x65)
            }
        } else {
            w.player.cue(metal)
            kill(w, shot: oID, lights: &lights, effects: effects)
        }
        return true
    }
}

extension SpriteSlot {
    /// ES: `+0x150` an enemy shot's bounce budget (`.SetupEnemyShotSprite` −6…−1 for the boulders; 0 = dies on the
    /// first counted contact) = `classWord150`.
    public var bounceCount: Int32 {
        get { classWord150 }
        set { classWord150 = newValue }
    }

    /// ES: `+0x164` a shard 0x6e6's age (+ 1 a Handle; step 7 hurts only while ≤ 1) = `launchSpeed`.
    public var shardAge: Int32 {
        get { launchSpeed }
        set { launchSpeed = newValue }
    }
}

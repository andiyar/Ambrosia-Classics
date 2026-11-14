import Foundation

/// The Manditraki Warrior (types 0x71c…0x725, level 5's boss; bosses §2, phase6-boss-contracts §2): the Setup
/// (`.SetupWarriorSprite @ 100878ac`, M l. 72989–73079; LV5), the Handle (6A-W1: `.HandleWarriorSprite`,
/// `.WarriorLayEgg`, `.RandomWarriorAttack`, the tile callback `.HitWarriorTileSprite`), the Hit and the Kill (6A-W2:
/// `.HitWarriorSprite`, `.KillWarrior`). Field map: `+0x170` the boss
/// flag (record p4) = `classWord170`; `+0x15c` / `+0x160` the patrol bounds = `classWord15c` / `classWord160`; `+0x168`
/// the home x = `bonusP4`; `+0x164` = `launchSpeed`; `+0xf0` the wounded-glow timer = `voicePitch`; `+0x17e` facing
/// right = `mirrored`; `+0xb0` the state `subtype`; `+0x46` the face counter `phase`; `+0xa6` the timer `counterA6`;
/// `+0x14c` run / swings left `classTimer`; `+0x154` the egg mark `classWord154`; `+0x16c` the crate timer
/// `classWord16c`; `+0x1d4` / `+0x1d8` / `+0x1dc` the crate slots `siblings.first` / `.second` / `.third`; `+0xb8` the
/// glow tint `mode`.
public enum Warrior {
    /// `.InitWarriorSprite @ 100877d0` (M l. 72975–72988): three cache sets, 0xb4×0xa0 cells, one row each, flag 0 —
    /// `PTR_DAT_100a0d50` 0x71c walk (8), `_DAT_100a0d4c` 0x71d attack (8), `_DAT_100a0d48` 0x71e death (6). The Setup
    /// marks all three (M l. 73029–73031; `CachedFaces`).
    public static let walkSet: Int16 = 0x71c, attackSet: Int16 = 0x71d, deathSet: Int16 = 0x71e

    /// The cache sets' geometry (`.CacheEncFaceSetFromPICT(…, n, 0xb4, 0xa0, n, …)`).
    public static let sheets: [SetupFaces.Sheet] = [
        SetupFaces.Sheet(pict: walkSet, count: 8, cellWidth: 0xb4, cellHeight: 0xa0, columns: 8, clut: 200),
        SetupFaces.Sheet(pict: attackSet, count: 8, cellWidth: 0xb4, cellHeight: 0xa0, columns: 8, clut: 200),
        SetupFaces.Sheet(pict: deathSet, count: 6, cellWidth: 0xb4, cellHeight: 0xa0, columns: 6, clut: 200),
    ]

    // MARK: - Setup

    /// `.SetupWarriorSprite(s)` (M l. 72989–73079) after `.InitSprite`, inside `.MTNewSprite` before `.MTInsertSprite`
    /// (M l. 30711–30719) — so its layer decides the list place. `+8` / `+6` (`oldPosition`) hold the spawn point. In
    /// the dump's order: `+0x84` / `+0x86` 0, layer `+0x80 = 0xc`; the Handle `+0x4c` (0x100a0494), hit `+0x5c`
    /// (0x100a0d44), tile callback `+0x1f8` (0x100a0d40), Kill `+0x50` (0x100a0d3c); `+0x18a = 1`; the three sets marked;
    /// `+0x170` = record p4 (`+0xe`); gravity 0x122; `+0xc0 = 0`; p4 ≠ 0 → HP 2000, `*_DAT_1009fed0 = 0` (returned:
    /// `clearsNoBossAlive`) and `+0x88 = 0`; p4 = 0 → HP 0x4b0, no boss flag; `+0x1b4 = 1`; `+0x168` = HP; the re-seat
    /// `+0xc ← +8`, `+0xa ← +6` (M l. 73046–73047: `.MTNewSprite` left `+0xc` = y, `+0xa` = 0); hot rect
    /// SetRect(0x1a, 0x17, 0x4a, 0x3a); `+0x150 = −1`; state `+0xb0` 6, `+0xb2 = 0`, `+0x46 = 2`, `+0x14c = 0`;
    /// `+0xa6 = R(10)`; the live record's p2 0 → 0x96 written back; `+0x15c` / `+0x160` = `+0xc` ∓ 350; `+0x168 = +0xc`;
    /// `+0x164 = 0`; `+0x17e` = R(100) ≥ 51 (the signed-compare idiom — raw `10087a54..10087a68`: `eqv`, `subfc
    /// r4,r5,0x32`, `addze` → 1 iff the draw > 0x32; the card's "< 51" read the first term alone); `+0xc0` = the
    /// 0x71c set's face 0; `+0xf0 = 0x1e`; the counting window; `+0x14` / `+0x1c` = `+8` / `+6` << 8.
    /// Returns the record as left and whether the Setup cleared "no boss alive".
    public static func setup(_ s: inout SpriteSlot, record p: Placement, rng: inout FastRand,
                             counting: inout EnemyCounting) -> (record: Placement, clearsNoBossAlive: Bool) {
        s.particleOffsetY = 0                                           // `+0x84`
        s.particleOffsetX = 0                                           // `+0x86`
        s.layer = 0xc
        s.handler = .warrior
        s.hasHit = true                                                 // `+0x5c` = `.HitWarriorSprite` (`hit`)
        s.hasTileHit = true                                             // `+0x1f8` = `.HitWarriorTileSprite`
        s.noWriteBack18a = true                                         // `+0x18a = 1`
        s.classWord170 = Int32(p.p4)                                    // `+0x170` = record `+0xe`
        s.gravity = 0x122
        s.face = nil                                                    // `+0xc0 = 0`
        var clears = false
        if s.classWord170 == 0 {
            s.hp = 0x4b0
        } else {
            s.hp = 2000
            clears = true                                               // `*_DAT_1009fed0 = 0`
            s.lightOverlay = false                                      // `+0x88 = 0`
        }
        s.flashTable = 1                                                // `+0x1b4 = 1`
        s.bonusP4 = Int32(s.hp)                                         // `+0x168` = HP
        s.x = s.oldPosition.x                                           // `+0xc ← +8`
        s.y = s.oldPosition.y                                           // `+0xa ← +6`
        s.hotRect = IdleSprites.Rect(top: 0x17, left: 0x1a, bottom: 0x3a, right: 0x4a)
        s.classWord150 = -1
        s.subtype = 6
        s.subState = 0
        s.phase = 2
        s.classTimer = 0
        s.counterA6 = rng.next(10)
        var record = p
        if p.p2 == 0 {                                                  // M l. 73056–73059
            record = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p.p1, p2: 0x96,
                               p3: p.p3, p4: p.p4, y: p.y, x: p.x)
        }
        let x = Int32(Int16(truncatingIfNeeded: s.x))
        s.classWord15c = x - 0x15e
        s.classWord160 = x + 0x15e
        s.bonusP4 = x                                                   // `+0x168 = +0xc`
        s.launchSpeed = 0                                               // `+0x164`
        s.mirrored = 0x32 < rng.next(100)
        s.face = FaceRef(pict: walkSet, index: 0, set: .encoded)        // `*(PTR_DAT_100a0d50 + 4)`
        s.voicePitch = 0x1e                                             // `+0xf0`
        counting.countIfWindow(&s)                                      // M l. 73070–73074
        s.x256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.x)) << 8
        s.y256 = Int32(Int16(truncatingIfNeeded: s.oldPosition.y)) << 8
        return (record, clears)
    }

    // MARK: - Handle

    /// The snd slots (`SoundSlots`): `*_DAT_100a0268` 704 (the swing), `*_DAT_100a026c` 703 'crawler death'.
    static let swingSound: Int16 = 704, deathSound: Int16 = 703

    /// The crate type 1075 (a Box rock, `BoxSprite.isBoulder`) and its face, the boot single 0x42e (`.SetupBoxSprite`
    /// M l. 59054–59055: `*_DAT_100a0aa4` for 0x42e, 0x433 and 0x434).
    static let crate: Int16 = 0x433, crateFace: Int16 = 0x42e

    /// f64 `0x100a1c40` 0.5 (state 6), `0x100a1c38` 0.4 (state 2), `0x100a1c30` 0.9 (state 4) — bosses §2 (`lfd
    /// -0x5c00` 10088044, `-0x5c08` 100881f0, `-0x5c10` 1008837c).
    static let half = Double(bitPattern: 0x3fe0_0000_0000_0000)
    static let swingDrag = Double(bitPattern: 0x3fd9_9999_9999_999a)
    static let friction90 = Double(bitPattern: 0x3fec_cccc_cccc_cccd)

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }
    @inline(__always) static func face(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    /// The tile callback `+0x1f8` (nil = 0): `.HitWarriorTileSprite @ 10088834` (M l. 73498–73530) — the Crawler's body
    /// (`CrawlerRoach.hitTile`): FG (layer 1) or a kind < 100 → `.WallBounce(s, kind, &pos, vCentre, 0, +0x34, 0, 0)`;
    /// < 200 → `.WallBounceBG(kind − 100, …)`; water with `+0x140 == 0` → `.HandleUnderWater`.
    static func pass(_ s: SpriteSlot) -> TileHit? {
        guard s.hasTileHit else { return nil }
        return { solver, id, cell, kind, layer in CrawlerRoach.hitTile(solver, id: id, pos: cell, kind: kind, layer: layer) }
    }

    /// `.HandleWarriorSprite @ 10087c04` (M l. 73115–73419). `+0xe9` or `+0x1b2` → return; `.StandardSpriteHandles`;
    /// the hot rect SetRect(0x2a, 0x3c, 0x89, 0x88), left − 10 facing left, right + 10 facing right (M l. 73144–73150);
    /// with `+0x170` (the boss flag) the crates and the glow (`bossBlock`, M l. 73151–73213, whatever the lock); the
    /// state (`+0xb0`): 2 `attack`, 4 `dying`, 7 `walk`, 6 the decide state — face 0x71c[0], `+0xa6 > 0` → − 1, then
    /// **the arena unlocked (`*PTR_DAT_1009fed4 == 0`) → return** (no death test, no gravity, no liquids, no Cleanup),
    /// `+0xa6 < 1` → `decide`, then vx × 0.5 (M l. 73333–73390); states 0, 1, 3, 5 and > 7 nothing. Then HP < 1 with
    /// state ≠ 4 → state 4, `+0x46 = +0xa6 = 0`, snd 703 (3D, 1, 0x100; M l. 73393–73398);
    /// `.ApplyGravityAndSeparateFromTiles` with `pass`; the liquids (`EnemyCommon.liquids`, the Dillo's rows, M l.
    /// 73400–73416); `.StandardSpriteCleanup`. His HP falls by the Hit's crate crush (`hit`) and the liquids; the burn
    /// the dying state starts ends in `kill` (`EnemyCommon.killProc`).
    public static func handle(world w: SpriteWorld, id: Int, solver: TileSolver,
                              faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right }) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.emerging else { return }
        w.standardSpriteHandles(id)
        w.active.update(id: id) { s in
            var r = IdleSprites.Rect(top: 0x3c, left: 0x2a, bottom: 0x88, right: 0x89)
            if s.mirrored { r.right += 10 } else { r.left -= 10 }
            s.hotRect = r
        }
        if let b = w.active.record(id: id), b.classWord170 != 0 { bossBlock(w, id: id) }
        guard var s = w.active.record(id: id) else { return }
        switch s.subtype {
        case 2: attack(w, id: id, &s)
        case 4: dying(&s)
        case 7: walk(w, &s)
        case 6:
            s.face = face(walkSet, 0)
            if 0 < s.counterA6 { s.counterA6 &-= 1 }
            guard w.arena.locked else {                                 // M l. 73338–73340
                w.active.update(id: id) { $0 = s }
                return
            }
            if s.counterA6 < 1 { decide(w, &s) }
            s.vx = TileSolver.fctiwz(Double(s.vx) * half)
        default:
            break
        }
        if s.hp < 1 && s.subtype != 4 {                                 // M l. 73393–73398
            s.subtype = 4
            s.phase = 0
            s.counterA6 = 0
            w.player.cue(PlayerCue(call: .threeD, snd: deathSound, priority: 1, volume: 0x100, position: s.centre))
        }
        w.active.update(id: id) { $0 = s }
        solver.applyGravityAndSeparate(id, pass: pass(s))
        EnemyCommon.liquids(w, id: id, class: .dillo)
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
    }

    /// The boss-mode block (`+0x170 ≠ 0`, M l. 73151–73213). The crate slots `+0x1d4` / `+0x1d8` / `+0x1dc`
    /// (`siblings.first` / `.second` / `.third`, record ids): a slot whose sprite has `+0xe9` set is emptied (a record
    /// Core no longer holds reads as 0s, as `.StandardSpriteHandles` reads its solid — unreachable while his Handle runs
    /// every frame, bosses §2.8). Any slot empty → `+0x16c` − 1, and below 1 every empty slot in order gets
    /// `MTNewSprite(0x433, +0x168 + d, +0xa − h, 9, −1, .SetupBoxSprite)` (`newCrate`) with (d, h) = (−0xba, 400),
    /// (0x46, 500), (0x146, 400) — the y from his current `+0xa`; all three present → `+0x16c = 15`. A spawn with no
    /// free record (known deviation 6) leaves the slot 0: it re-tries every frame while `+0x16c` counts on below 1.
    /// Then the wounded glow: `+0xf0` − 1; 1…3 → `+0xb8 = 0x10008`, 4…6 → `0x10009` (each only with HP < 1001); ≤ 0 →
    /// `+0xf0` = 15 (HP < 501) or 30 and `+0xb8 = 0`.
    static func bossBlock(_ w: SpriteWorld, id: Int) {
        guard var s = w.active.record(id: id) else { return }
        func dead(_ c: Int?) -> Bool { c.map { (w.active.record(id: $0)?.killCount ?? 0) != 0 } ?? false }
        if dead(s.siblings.first) { s.siblings.first = nil }
        if dead(s.siblings.second) { s.siblings.second = nil }
        if dead(s.siblings.third) { s.siblings.third = nil }
        if s.siblings.first == nil || s.siblings.second == nil || s.siblings.third == nil {
            s.classWord16c &-= 1
            if s.classWord16c < 1 {
                // No `SpriteSlot` copy across a spawn (`SpriteWorld` rule 2): write back, spawn, store the slot, re-read.
                w.active.update(id: id) { $0 = s }
                let home = Int(s.bonusP4), y = h16(s.y)
                if s.siblings.first == nil {
                    let c = newCrate(w, x: home - 0xba, y: y - 400)
                    w.active.update(id: id) { $0.siblings.first = c }
                }
                if s.siblings.second == nil {
                    let c = newCrate(w, x: home + 0x46, y: y - 500)
                    w.active.update(id: id) { $0.siblings.second = c }
                }
                if s.siblings.third == nil {
                    let c = newCrate(w, x: home + 0x146, y: y - 400)
                    w.active.update(id: id) { $0.siblings.third = c }
                }
                guard let t = w.active.record(id: id) else { return }
                s = t
            }
        } else {
            s.classWord16c = 0xf
        }
        s.voicePitch &-= 1
        let v = s.voicePitch
        if 0 < v && v < 4 {
            if s.hp < 0x3e9 { s.mode = 0x10008 }
        } else if 3 < v && v < 7 {
            if s.hp < 0x3e9 { s.mode = 0x10009 }
        } else if v < 1 {
            s.voicePitch = s.hp < 0x1f5 ? 0xf : 0x1e
            s.mode = 0
        }
        w.active.update(id: id) { $0 = s }
    }

    /// `MTNewSprite(0x433, x, y, 9, −1, .SetupBoxSprite)`: the Box Setup's rock arm stores layer 2 (M l. 58939) over the
    /// argument 9, the face the boot single 0x42e; it draws nothing. Nil when no record is free (Ruling 16).
    static func newCrate(_ w: SpriteWorld, x: Int, y: Int) -> Int? {
        let none = Placement(index: -1, flag: 0, byte1: 0, type: crate, p1: 0, p2: 0, p3: 0, p4: 0, y: 0, x: 0)
        return w.newSprite(type: crate, x: h16(x), y: h16(y), layer: 9, handler: .box) { c in
            c.x = c.oldPosition.x
            c.y = c.oldPosition.y
            BoxSprite.setup(&c, record: none, level: w.level)
            c.face = face(crateFace, 0)
        }
    }

    /// The decide (M l. 73341–73387): r = R(100); |playerCY − cy| < 0x50 → T = 0x41 and face the player (facing right =
    /// playerCX > cx, the signed-compare idiom), else T = 0x13; the game-over flag `*_DAT_1009ffa8` → T = −1. r > T →
    /// state 7, `+0x46 = 1`, face 0x71c[0], `+0xa6 = R(3) + 2`; R(100) > 100 − T → run (`+0x14c = 1`), else walk
    /// (`+0x14c = 0`) and R(100) > 0x50 → `layEgg`; then x > `+0x160` → facing left, else x < `+0x15c` → right. Else
    /// `randomAttack`.
    static func decide(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let r = Int(w.rng.next(100))
        var d = Int(w.player.centreY) - h16(s.centre.y)
        if d < 1 { d = -d }
        var t: Int
        if d < 0x50 {
            t = 0x41
            s.mirrored = Int16(truncatingIfNeeded: s.centre.x) < w.player.centreX
        } else {
            t = 0x13
        }
        if w.playerDead { t = -1 }
        guard t < r else {
            randomAttack(w, &s)
            return
        }
        s.subtype = 7
        s.phase = 1
        s.face = face(walkSet, 0)
        s.counterA6 = w.rng.next(3) + 2
        if 100 - t < Int(w.rng.next(100)) {
            s.classTimer = 1
        } else {
            s.classTimer = 0
            if 0x50 < w.rng.next(100) { layEgg(w, &s) }
        }
        let x = Int32(h16(s.x))
        if s.classWord160 < x {
            s.mirrored = false
        } else if x < s.classWord15c {
            s.mirrored = true
        }
    }

    /// `.WarriorLayEgg(s) @ 10087afc` (M l. 73080–73092): `+0x154 = 2` (no reader), `+0xa6 = 5`, `+0x14c = R(2) + 1` —
    /// the walk becomes a run.
    static func layEgg(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        s.classWord154 = 2
        s.counterA6 = 5
        s.classTimer = Int32(w.rng.next(2)) + 1
    }

    /// `.RandomWarriorAttack(s) @ 10087b6c` (M l. 73095–73112): R(100) drawn and discarded (raw `10087b7c..10087b84`,
    /// bosses D1); state 2, `+0x46 = 0` (both stored twice); `+0x154 = 0`; `+0xa6 = 0x10`; `+0x14c = R(2) + 1` swings.
    static func randomAttack(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        _ = w.rng.next(100)
        s.subtype = 2
        s.phase = 0
        s.classWord154 = 0
        s.counterA6 = 0x10
        s.classTimer = Int32(w.rng.next(2)) + 1
    }

    /// State 7 (M l. 73283–73332): walk (`+0x14c == 0`) face 0x71c[`+0x46 >> 1`], past 14 the cycle's end, vx ±0x600;
    /// run face 0x71c[`+0x46`], past 6, vx ±0xc00. The cycle's end: `+0x46 = 0`, `+0xa6` − 1, x outside [`+0x15c`,
    /// `+0x160`] → 0; at 0 → state 6, `+0xa6 = R(9) + 4`. Then `+0x46` + 1; vx by the facing.
    static func walk(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        let run = s.classTimer != 0
        s.face = face(walkSet, run ? Int(s.phase) : Int(s.phase >> 1))
        if (run ? 6 : 0xe) < s.phase {
            s.phase = 0
            s.counterA6 &-= 1
            let x = Int32(h16(s.x))
            if s.classWord160 < x || x < s.classWord15c { s.counterA6 = 0 }
            if s.counterA6 == 0 {
                s.subtype = 6
                s.counterA6 = w.rng.next(9) + 4
            }
        }
        s.phase &+= 1
        let v: Int32 = run ? 0xc00 : 0x600
        s.vx = s.mirrored ? v : -v
    }

    /// State 2 (M l. 73221–73265): vx × 0.4; `+0x46 < 2` → face 0x71c[0] and face the player; else `+0x46 == 7` →
    /// R(6000), snd 704 pitched (1, 0x100, centre, 50000 + R); face = word `+0x46 >> 1` of the 0x71d set (no `+4`: attack
    /// face (n >> 1) − 1); `+0x46 == 9` → `MTNewSprite(0x71f, cx ± 0x30 − 0x18, cy − 0x25, 0, −1, .SetupEnemyShotSprite)`
    /// (its Setup draws R(5) and keeps layer 0) and its vx 0xb00, negated facing left — no null test (M l. 73249–73252):
    /// with no free record the store is dropped; `+0x46 > 16` → `+0x46 = 0`, `+0x14c` − 1, below 1 → state 6, `+0xa6 =
    /// R(9) + 4`. Then `+0x46` + 1.
    static func attack(_ w: SpriteWorld, id: Int, _ s: inout SpriteSlot) {
        s.vx = TileSolver.fctiwz(Double(s.vx) * swingDrag)
        if s.phase < 2 {
            s.face = face(walkSet, 0)
            s.mirrored = Int16(truncatingIfNeeded: s.centre.x) < w.player.centreX
        } else {
            if s.phase == 7 {
                let r = Int32(w.rng.next(6000))
                w.player.cue(PlayerCue(call: .threeDPitched, snd: swingSound, priority: 1, volume: 0x100,
                                       position: s.centre, rate: r + 50000))
            }
            s.face = face(attackSet, Int(s.phase >> 1) - 1)
            if s.phase == 9 {
                let dx = s.mirrored ? 0x30 : -0x30
                let x = h16(h16(s.centre.x) + dx - 0x18), y = h16(h16(s.centre.y) - 0x25)
                w.active.update(id: id) { $0 = s }
                let shot = EnemyShot.spawn(w, type: EnemyShot.warriorShot, x: x, y: y, layer: 0)
                s = w.active.record(id: id) ?? s
                if let shot {
                    let right = s.mirrored
                    w.active.update(id: shot) { $0.vx = right ? 0xb00 : -0xb00 }
                }
            }
            if 0x10 < s.phase {
                s.phase = 0
                s.classTimer &-= 1
                if s.classTimer < 1 {
                    s.subtype = 6
                    s.counterA6 = w.rng.next(9) + 4
                }
            }
        }
        s.phase &+= 1
    }

    /// State 4 (M l. 73267–73280): vx × 0.9; face 0x71e[`+0x46 >> 2`]; `+0x46` + 1, capped at 0x17; `+0xa6` + 1; at
    /// 0x2d `+0x1a2 = 1` (the burn; the Kill `+0x50` at its end, `EnemyCommon.killProc`).
    static func dying(_ s: inout SpriteSlot) {
        s.vx = TileSolver.fctiwz(Double(s.vx) * friction90)
        s.face = face(deathSet, Int(s.phase >> 2))
        s.phase &+= 1
        if 0x17 < s.phase { s.phase = 0x17 }
        s.counterA6 &+= 1
        if s.counterA6 == 0x2d { EnemyCommon.startBurn(&s) }
    }

    // MARK: - Hit

    /// snd slots: `*_DAT_100a041c` 303 (the shot's clank), `*_DAT_100a0274` 701 (Crawler Ouch), `_DAT_100a0320`[0…1]
    /// 477 / 478 (monster1 / 2), `*_DAT_1009fd68` 453 (the boss-kill thunder).
    static let clankSound: Int16 = 303, ouchSound: Int16 = 701, monsterSounds: [Int16] = [477, 478]
    static let thunderSound: Int16 = 453

    /// `.HitWarriorSprite(s, other) @ 1008854c` (M l. 73422–73462; raw `1008854c..10088710`). Every Handle comparison
    /// is `+0x4c ==` (`BackgroundSprite.runs`):
    /// - a player shot (`PTR_PTR_100a04e8`) with `+0xa6 == 0` while HP `+0xa4` > 0 → `.KillPlayerShot(o, 0, 1)` (no hit
    ///   sound, the impact effect), then `.STPlay3DSound(303, 1, 0x100, o +0xe)` — the shot's centre as the kill's
    ///   Cleanup left it. Immune. With effect 1 `.KillPlayerShot`'s stale-slot path (the caller's r29 + 0x9a, taken only
    ///   when the effect is off, `PlayerShotHits.kill`) is never reached: `staleSlot` nil. A shot with `+0xa6 ≠ 0`, or a
    ///   Warrior at HP ≤ 0, passes through. The Statue spell (type 1) is an ordinary shot (no `.TurnIntoStatue`);
    /// - else a Statue (`PTR_PTR_100a01f8`) or a Box (`PTR_PTR_100a0484`): `.PlatformBounce(s, o, s's hot-rect centre
    ///   offset (v = top + (bottom − top) >> 1), 0, s +0x34, 0)` == 2 and (o `+0x2c` > 0 or s `+0xce` ≠ 0), both read
    ///   after the bounce → `.HurtSprite(s, 200, (i16)(o.vx >> 1), −1000, 2, 8)` (whether or not it lands), `+0xf0 = 0`,
    ///   `.KillBox(o)` (its own draws: snd 424's R(10000), the face's particles), then R(10000) → `.STPlay3DSoundPitched
    ///   (701, 1, 0x100, s +0xe, 42000 + R)`, R(10000), R(2) → `.STPlay3DSoundPitched(_DAT_100a0320[R2], 1, 0x100, s
    ///   +0xe, 42000 + R)`. 2000 / 200 = 10 crate hits.
    /// No environmental-hazard arm (no 0x4b7 / 0x5a0 test).
    public static func hit(_ w: SpriteWorld, id: Int, other oID: Int, lights: inout LightTable, effects: Int16 = 1,
                           faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                           faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard let s = w.active.record(id: id), let o = w.active.record(id: oID) else { return }
        let runs = BackgroundSprite.runs
        if runs(o, .playerShot) && o.counterA6 == 0 && 0 < s.hp {
            PlayerShotHits.kill(w, shot: oID, sound: false, effect: true, effects: effects, lights: &lights,
                                faceWidth: faceWidth, faceBounds: faceBounds, staleSlot: nil)
            let c = (w.active.record(id: oID) ?? o).centre                 // `lwz r6,0xe(r31)` after the kill
            w.player.cue(PlayerCue(call: .threeD, snd: clankSound, priority: 1, volume: 0x100, position: c))
        } else if runs(o, .statue) || runs(o, .box) {
            let r = s.hotRect
            let centre = SpriteSlot.Point(x: h16(r.left + h16((r.right - r.left) >> 1)),
                                          y: h16(r.top + h16((r.bottom - r.top) >> 1)))
            let b = w.platformBounce(mover: id, solid: oID, centre: centre, factor: 0, rect: r, bounce: false)
            guard b == 2, let m = w.active.record(id: id), let solid = w.active.record(id: oID),
                  0 < solid.vy || m.groundKind != 0 else { return }
            HurtSprite.apply(w, id: id, damage: 200, dvx: Int16(truncatingIfNeeded: solid.vx >> 1), dvy: -1000,
                             invulnerable: 2, flash: 8)
            w.active.update(id: id) { $0.voicePitch = 0 }                  // `+0xf0 = 0`
            BoxSprite.killBox(w, id: oID)
            let at = (w.active.record(id: id) ?? m).centre                 // `+0xe`
            let r1 = Int32(w.rng.next(10000))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: ouchSound, priority: 1, volume: 0x100, position: at,
                                   rate: r1 + 42000))
            let r2 = Int32(w.rng.next(10000))
            let k = Int(w.rng.next(2))
            w.player.cue(PlayerCue(call: .threeDPitched, snd: monsterSounds[k], priority: 1, volume: 0x100,
                                   position: at, rate: r2 + 42000))
        }
    }

    // MARK: - Kill

    /// `.KillWarrior(s) @ 1008874c` (M l. 73465–73495), the Kill proc `+0x50`: the counting head (`+0xe9 == 0 ∧
    /// +0x1b5` → live − 1 and `G+0x306+2L` + 1 — guarding the count only), `+0xe9 = 1`, `+0xea = 1`; then with `+0x170
    /// ≠ 0` the boss-kill tail (M l. 73486–73493): `.STPlay3DSoundPitched(453, 1, 0x100, +0xe, 48000)` (no draw), the
    /// shake `*_DAT_1009ffa0 = 0x1e`, the mask flash `*_DAT_100a00fc = 3`, `*_DAT_1009fed0 = 1` (no boss alive: the gate
    /// 2940 p1 −1 opens from its next Handle, the loop rule fades to track 30). No score. A second call counts nothing
    /// and replays the tail.
    static func kill(_ w: SpriteWorld, _ s: inout SpriteSlot) {
        w.enemies.kill(&s, globals: &w.globals, level: w.levelIndex, forGood: true)
        guard s.classWord170 != 0 else { return }
        w.player.cue(PlayerCue(call: .threeDPitched, snd: thunderSound, priority: 1, volume: 0x100, position: s.centre,
                               rate: 48000))
        w.shakeStore = 0x1e
        w.flash.count = 3
        w.arena.noBossAlive = 1
    }
}

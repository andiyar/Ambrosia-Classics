import Foundation

/// The Manditraki Warrior (types 0x71c…0x725, level 5's boss; bosses §2) — LV5's stand-in: the whole Setup
/// (`.SetupWarriorSprite @ 100878ac`, M l. 72989–73079) and a ◇ Handle. Field map: `+0x170` the boss flag (record p4) =
/// `classWord170`; `+0x15c` / `+0x160` the patrol bounds = `classWord15c` / `classWord160`; `+0x168` the home x =
/// `bonusP4`; `+0x164` = `launchSpeed`; `+0xf0` the wounded-glow timer = `voicePitch`; `+0x17e` facing right =
/// `mirrored`.
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
        s.hasHit = true                                                 // `+0x5c` = `.HitWarriorSprite` (◇ body)
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

    // MARK: - Handle ◇

    /// ◇ `.HandleWarriorSprite @ 10087c04` (M l. 73115–73420), the stand-in (Ruling 3): `+0xe9` or `+0x1b2` → return;
    /// `.StandardSpriteHandles`; the hot rect SetRect(0x2a, 0x3c, 0x89, 0x88) widened 10 px on the facing side (left
    /// −10 facing left, right +10 facing right; M l. 73143–73150); then the decision state 6's head: the 0x71c set's
    /// face 0 and `+0xa6` > 0 → − 1 (M l. 73334–73337) — where the original, with the arena unlocked, returns (M l.
    /// 73338–73340). The stand-in stops there whatever the lock.
    /// // later: Phase 6 — the boss-mode crates and wounded glow (M l. 73151–73212), the state machine (decide, walk,
    /// run, attack with its shot 0x71f, dying), the death at HP < 1, gravity, the liquids and `.StandardSpriteCleanup`;
    /// the Hit (`.HitWarriorSprite`) and Kill (`.KillWarrior`: thunder, shake 0x1e, flash 3, `*_DAT_1009fed0 = 1`)
    /// bodies. Smiting may take its HP below 1 (`Smite.enemyHandlers` lists it): it stays standing.
    public static func handle(world w: SpriteWorld, id: Int) {
        guard let s0 = w.active.record(id: id), !s0.dead, !s0.emerging else { return }
        w.standardSpriteHandles(id)
        w.active.update(id: id) { s in
            var r = IdleSprites.Rect(top: 0x3c, left: 0x2a, bottom: 0x88, right: 0x89)
            if s.mirrored { r.right += 10 } else { r.left -= 10 }
            s.hotRect = r
            s.face = FaceRef(pict: walkSet, index: 0, set: .encoded)
            if 0 < s.counterA6 { s.counterA6 -= 1 }
        }
    }
}

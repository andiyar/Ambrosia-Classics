import Foundation

/// The player's held item (held-item-melee §1; pickups-boxes §3.1–§3.3): `.SetupHeldItemSprite @ 1004bdd0` /
/// `.HandleHeldItemSprite @ 1004be74` (M l. 43406–43459), `.SetHeldItemPos @ 1004bf2c` (M l. 43460–43533) and
/// `.HandleItemUse @ 1004d054` (M l. 44197–44301) — the dagger / Ice Pick / Vorpal Dirk stab and the thrown seeds that
/// `.HandleKeys`' item switch starts (`_DAT_100a0698 = 1`).
///
/// One held-item sprite per level: `.SetupPlayerSprite` makes it (`Player.spawn`, `PlayerState.heldItem`); row 31
/// zeroes its face every frame (M l. 45141), so outside a swing it is invisible where the last swing left it.
public enum HeldItem {
    /// `_DAT_100a07cc` = PICT 1021 (5 × 100×120, the stab) and `_DAT_100a078c` = PICT 1035 (the crouching stab)
    /// (`.InitPlayerSprite` M l. 42444–42445, 42476–42477).
    public static let meleeSet: Int16 = 1021, crouchMeleeSet: Int16 = 1035

    /// `0x100a5f68 + 4·item`: `.InitPlayerSprite`'s `Load1EncFaceFromPICT(0x2ee + i, …)` for i < 27 (M l. 42478–42482)
    /// — a null face where the PICT is absent; the shipped data holds 750 (dagger), 756 (fire seeds), 768 (Ice Pick),
    /// 771 (Vorpal Dirk) only (held-item-melee §1.3; `ItemUseTests` checks the data). −1 (no item) → none.
    static let facePicts: Set<Int16> = [750, 756, 768, 771]
    public static func face(item: Int16) -> FaceRef? {
        guard 0 <= item, item < 0x1b, facePicts.contains(750 + item) else { return nil }
        return FaceRef(pict: 750 + item, index: 0, set: .encoded)
    }

    /// The held faces' singles (CLUT 200, `.InitSprites`' boot loads) — FerazelRender loads them with the player's sets.
    public static let sheets: [SetupFaces.Sheet] = facePicts.sorted().map { .single($0) }

    /// `0x5a01`: the thrown seed's spawn type (id 0x5a, power 1; `.SetupPlayerShotSprite` splits it).
    public static let seedType: Int16 = 0x5a01

    @inline(__always) static func h16(_ v: Int) -> Int { Int(Int16(truncatingIfNeeded: v)) }

    // MARK: - Setup and Handle

    /// `.SetupHeldItemSprite` (M l. 43406–43425), inside `.MTNewSprite` (`Player.spawn`): `.InitSprite`, type 100, face
    /// 0, (y, x) = (0, 0), layer 0x14, hit and tile callbacks 0, the Handle `.HandleHeldItemSprite`
    /// (`PTR_PTR_100a04f8`), `SetRect(+0x34, −2, 2, 0x1a, 0x16)`.
    static func setup(_ h: inout SpriteSlot) {
        h.type = Player.heldItemType
        h.face = nil
        h.y = 0
        h.x = 0
        h.layer = 0x14
        h.hasHit = false
        h.hasTileHit = false
        h.handler = .heldItem
        h.hotRect = IdleSprites.Rect(top: 2, left: -2, bottom: 0x16, right: 0x1a)
    }

    /// `.HandleHeldItemSprite` (M l. 43431–43458; raw `1004be74..1004bf00`): vy = vx = 0, `+0x14 = +0xc << 8`, `+0x1c =
    /// +0xa << 8`, `+8 = +0xc`, `+6 = +0xa`, layer `+0x80 = 0x14` (a direct store: no re-sort), type 100; a face →
    /// the hot rect = the face's bounds (face `+8..+0xf`) with left + 1 and right − 1 (16-bit); `+0xa6 < 0` → + 1. No
    /// `.StandardSpriteHandles`, no move, no `FastRand`.
    /// - Parameter faceBounds: a face's opaque bounds (face `+8`) — Core has no face records (the session's).
    public static func handle(world w: SpriteWorld, id: Int, faceBounds: (FaceRef) -> IdleSprites.Rect) {
        guard let s = w.active.record(id: id) else { return }
        let bounds = s.face.map(faceBounds)
        w.active.update(id: id) { h in
            h.vy = 0
            h.vx = 0
            h.x256 = Int32(Int16(truncatingIfNeeded: h.x)) << 8
            h.y256 = Int32(Int16(truncatingIfNeeded: h.y)) << 8
            h.oldPosition = SpriteSlot.Point(x: h.x, y: h.y)
            h.layer = 0x14
            h.type = Player.heldItemType
            if let b = bounds {
                h.hotRect = IdleSprites.Rect(top: b.top, left: h16(b.left + 1), bottom: b.bottom, right: h16(b.right - 1))
            }
            if h.counterA6 < 0 { h.counterA6 += 1 }
        }
    }

    // MARK: - the swing

    /// `.SetHeldItemPos(player, held)` (M l. 43460–43533; raw `1004bf2c..1004c0b8`): (dx, dy) by |c| (c =
    /// `_DAT_100a0698`): 3 → (0x42, 0x18); 1 → (0x2d, 0x1e); 2 → (0x35, 0x1c); 4 → (0x47, 0x16); 5 and 0 → (0x54, 0x11)
    /// (the tests' fall-through); crouch `_DAT_100a071c ≠ 0` → dy + 0xc. Held x = (player x256 >> 8) + dx — or
    /// + (100 − dx) when the side flag `PTR_DAT_100a04f4` is set (the facing at the press) — y = (y256 >> 8) + dy +
    /// 0x16 (16-bit). The player's water contact (`+0x11c` or `+0x120` ≠ 0) → held `+0x11c` = (short)max(`+0x120`,
    /// `+0x11c`) − (player `+0xa` − held `+0xa`), at least 1. Held `+0x17e` = the player's (its **current** mirror —
    /// two sources, as written); set → x − 0x20. Then the held 24.8 position from its pixels.
    public static func setPos(_ w: SpriteWorld, player pid: Int, held hid: Int) {
        guard let p = w.active.record(id: pid) else { return }
        let c = Int(w.player.itemUse), m = c < 1 ? -c : c
        var dx: Int, dy: Int
        if m == 3 {
            (dx, dy) = (0x42, 0x18)
        } else if m < 3 && m == 1 {
            (dx, dy) = (0x2d, 0x1e)
        } else if m < 3 && 0 < m {
            (dx, dy) = (0x35, 0x1c)
        } else if 3 < m && m < 5 {
            (dx, dy) = (0x47, 0x16)
        } else {
            (dx, dy) = (0x54, 0x11)
        }
        if w.player.crouch != 0 { dy += 0xc }
        let px = h16(Int(p.x256 >> 8)), py = h16(Int(p.y256 >> 8))
        let x = h16(px + (w.player.heldLeft ? 100 - dx : dx))
        let y = h16(py + dy + 0x16)
        let wet = p.waterRow != 0 || p.lastWater != 0
        var depth = p.lastWater
        if depth < p.waterRow { depth = p.waterRow }
        let playerY = Int32(Int16(truncatingIfNeeded: p.y))
        w.active.update(id: hid) { h in
            h.x = x
            h.y = y
            if wet {
                h.waterRow = Int32(Int16(truncatingIfNeeded: depth)) &- (playerY &- Int32(y))
                if h.waterRow < 1 { h.waterRow = 1 }
            }
            h.mirrored = p.mirrored
            if h.mirrored { h.x = h16(h.x - 0x20) }
            h.x256 = Int32(Int16(truncatingIfNeeded: h.x)) << 8
            h.y256 = Int32(Int16(truncatingIfNeeded: h.y)) << 8
        }
    }

    /// `.HandleItemUse(player)` (M l. 44197–44301; raw `1004d054..1004d36c`), from row 33's melee arm (M l. 45817–45820)
    /// and its swim arm (M l. 45727–45729), with c = `_DAT_100a0698` ≠ 0:
    /// 1. idle `_DAT_100a068c` > 0 → idle = fidgets `_DAT_100a0688`;
    /// 2. the player's face 1021[|c| − 1], crouching (`_DAT_100a071c ≠ 0`) 1035[|c| − 1];
    /// 3. the held face of the in-use item `_DAT_100a5fd8` (`face(item:)`; none for −1); held `+0x158 = −1`, `+0xeb = 0`;
    /// 4. c ∈ {3, 4, 5} (raw `1004d154..1004d194`: the `eqv/subfc/addze` idiom, signed c ≥ 3) → the held sprite carries
    ///    the player-shot Handle, hit and tile callbacks (`PTR_PTR_100a04e8`, `04e4`, `04e0`); else the held Handle
    ///    (`PTR_PTR_100a04f8`) and no hit callback (the tile callback left as it was);
    /// 5. `.SetHeldItemPos`;
    /// 6. by item: 0 → `+0xa4` 100; 0x12 → 300, `+0x158` 4, `+0xeb` 1; 0x15 → 200, 1, 1; 6 / 0x1a at c == 5 →
    ///    `MTNewSprite(0x5a01, held +0x10, held +0xe − 4, 0xb, −1, .SetupPlayerShotSprite)` — the held centre its last
    ///    Handle computed — `+0xf4 = 1` for 0x1a, vx 0x60e (side flag: −0x60e and x256 + 0xc00) + the player's vx, vy
    ///    −0x60e + the player's vy when > 0 (the stores dropped when no record is free, Ruling 16), in-use = −1;
    /// 7. c + 1, 6 → −5.
    public static func handleItemUse(_ w: SpriteWorld, player pid: Int) {
        if 0 < w.player.idle { w.player.idle = w.player.fidgets }
        let c = w.player.itemUse
        let m = Int(c < 1 ? 0 &- c : c)
        let set = w.player.crouch == 0 ? meleeSet : crouchMeleeSet
        w.active.update(id: pid) { $0.face = FaceRef(pict: set, index: m - 1, set: .encoded) }
        let item = w.player.meleeItem
        if let hid = w.player.heldItem, w.active.record(id: hid) != nil {
            let striking = 3 <= c
            w.active.update(id: hid) { h in
                h.face = face(item: item)
                h.crunchStrength = -1
                h.crunches = 0
                if striking {
                    h.handler = .playerShot
                    h.hasHit = true
                    h.hasTileHit = true
                } else {
                    h.handler = .heldItem
                    h.hasHit = false
                }
            }
            setPos(w, player: pid, held: hid)
            switch item {
            case 0:
                w.active.update(id: hid) { $0.hp = 100 }
            case 6, 0x1a:
                if c == 5 { throwSeed(w, player: pid, held: hid, ziridium: item == 0x1a) }
            case 0x12:
                w.active.update(id: hid) { h in
                    h.hp = 300
                    h.crunchStrength = 4
                    h.crunches = 1
                }
            case 0x15:
                w.active.update(id: hid) { h in
                    h.hp = 200
                    h.crunchStrength = 1
                    h.crunches = 1
                }
            default:
                break
            }
        }
        w.player.itemUse = c &+ 1
        if w.player.itemUse == 6 { w.player.itemUse = -5 }
    }

    /// Step 6's seed (M l. 44262–44283).
    static func throwSeed(_ w: SpriteWorld, player pid: Int, held hid: Int, ziridium: Bool) {
        guard let h = w.active.record(id: hid) else { return }
        let x = h16(h.centre.x), y = h16(h.centre.y) - 4
        if let k = PlayerShot.spawn(w, type: seedType, x: x, y: y), let p = w.active.record(id: pid) {
            let left = w.player.heldLeft
            w.active.update(id: k) { s in
                if ziridium { s.classWordF4 = 1 }
                s.vx = 0x60e
                s.vy = -0x60e
                if left {
                    s.vx = 0 &- s.vx
                    s.x256 &+= 0xc00
                }
                s.vx &+= p.vx
                if 0 < p.vy { s.vy &+= p.vy }
            }
        }
        w.player.meleeItem = -1
    }
}

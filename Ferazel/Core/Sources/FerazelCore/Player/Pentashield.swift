import Foundation

/// The Pentashield (sphere 1338; spells-detail §3.8, pickups-boxes §3.3): `.UpdatePentSprites(player) @ 1004ce64`
/// (M l. 44127–44196), called last in `.HandlePlayerSprite` (M l. 46648). The orbs are player shots of id 0x50
/// (`PlayerShot`): 300 damage, 3 hits (`+0x168`, `.KillPlayerShot` counts them, `PlayerShotHits.kill`), no tile
/// callback, no gravity, no light; they open no containers (`BonusSprite.container`, `PlayerShotHits.hit`). Against
/// enemy shots — `.KillEnemyShot` on contact (M l. 50997–51001; `PlayerShotHits.hit` step 2, ES). The pickup's orb
/// table is `HitPlayerSprite.sphere`'s (M l. 49085–49112).
public enum Pentashield {
    /// The orb's spawn type `0x5001` (id 0x50, power 1).
    static let spawnType: Int16 = 0x5001

    /// `.UpdatePentSprites` (raw `1004ce64..1004d050`), for each of the eight orb records `PTR_DAT_100a0514` in order:
    /// - not in use (`+4` 0): a sprite → its `+0xe9 = 1`, the pointer 0;
    /// - in use with a sprite whose `+0xe9 ≠ 0` (struck out, or killed by the pickup's re-deal): out of use, pointer
    ///   0, the count `PTR_DAT_100a053c` − 1;
    /// - in use otherwise: no sprite → `MTNewSprite(0x5001, 0, 0, player +0x80 + 1, 0x1ff, .SetupPlayerShotSprite)`
    ///   (its Setup's `FastRand(5)` and `FastRand(14)`, inside this loop) and its `+0x164 = −10` (the spawn flash; the
    ///   stores to a failed spawn are dropped, Ruling 16); angle += speed, past 0x167ff − 0x16800; then the orb's 24.8
    ///   position = radius · `cosT` / `sinT`[angle >> 8] divided by 256 toward zero (`srawi; addze`) as a short, +
    ///   (player centre `+0x10` / `+0xe` − 10)·256, and `+0xc` / `+0xa` its pixel (`>> 8`).
    /// An orb record whose sprite left the list reads as struck out (the unlinked record keeps its `+0xe9`; Core never
    /// reuses records).
    static func update(_ w: SpriteWorld, player id: Int) {
        guard let p = w.active.record(id: id) else { return }
        let layer = Int16(truncatingIfNeeded: p.layer + 1)
        for i in 0..<w.player.orbs.count {
            var orb = w.player.orbs[i]
            if !orb.active {
                if let s = orb.sprite {
                    w.active.update(id: s) { $0.killCount = 1 }
                    orb.sprite = nil
                }
                w.player.orbs[i] = orb
                continue
            }
            if let s = orb.sprite, w.active.record(id: s).map({ $0.killCount != 0 }) ?? true {
                orb.active = false
                orb.sprite = nil
                w.player.orbs[i] = orb
                w.player.pentashieldCount &-= 1
                continue
            }
            if orb.sprite == nil {
                orb.sprite = w.newSprite(type: spawnType, x: 0, y: 0, layer: layer, handler: .playerShot,
                                         record: 0x1ff) { PlayerShot.setup(w, &$0) }
                if let s = orb.sprite { w.active.update(id: s) { $0.stepY = -10 } }   // `+0x164`
            }
            orb.angle &+= orb.speed
            if 0x167ff < orb.angle { orb.angle &-= 0x16800 }
            // `angle >> 8` is 0…359 for every angle the pickup deals and this loop steps (speed 0xa00).
            let a = RadialTables.degrees(orb.angle)
            let ux = orb.radius &* RadialTables.cosT[a], uy = orb.radius &* RadialTables.sinT[a]
            let cx = Int32(Int16(truncatingIfNeeded: p.centre.x)), cy = Int32(Int16(truncatingIfNeeded: p.centre.y))
            let x256 = Int32(Int16(truncatingIfNeeded: ux / 0x100)) &+ (cx &- 10) &* 0x100
            let y256 = Int32(Int16(truncatingIfNeeded: uy / 0x100)) &+ (cy &- 10) &* 0x100
            if let s = orb.sprite {
                w.active.update(id: s) { o in
                    o.x256 = x256
                    o.y256 = y256
                    o.x = Int(Int16(truncatingIfNeeded: x256 >> 8))
                    o.y = Int(Int16(truncatingIfNeeded: y256 >> 8))
                }
            }
            w.player.orbs[i] = orb
        }
    }
}

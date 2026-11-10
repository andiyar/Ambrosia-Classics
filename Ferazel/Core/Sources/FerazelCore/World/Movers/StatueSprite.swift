import Foundation

/// The Statue spell's petrified sprite (SW; enemies-ground §2.2): `.TurnIntoStatue @ 10043138` (M l. 38244–38272) and
/// `.HandleStatueSprite @ 100664a8` (M l. 56521–56555). Its callers: the platform site of `.HitPlatformSprite`
/// (M l. 55798–55803, `PlatformSprite.hit`) and the enemies' eleven Hit sites (`EnemyCommon.turnIntoStatue`).
/// While petrified the sprite runs `.statue` with the Box class's hit (`.HitBoxSprite`, `FerazelSession.hitCallback`)
/// and tile callback (`.HitBoxTileSprite` — the Statue Handle never separates, so it is never called).
public enum StatueSprite {
    /// `*_DAT_100a01fc` = 302 'statue hit' (pickups-boxes-2 §1.2).
    static let sound: Int16 = 302
    /// `*_DAT_100a099c`: the light face `.InitCrawlerSprite` loads at boot, `.Load1LightFaceFromPICT(0x334, 0x80, 0x80)`
    /// (M l. 56145–56146; PICT 820).
    static let light = LightFaceRef(pict: 0x334, width: 0x80, height: 0x80)

    /// `.TurnIntoStatue(s)` (M l. 38244–38272), in order: `.STPlay3DSound(302, 1, 0x32, +0xe)` (no draw); the Handle
    /// `+0x4c`, hit `+0x5c` and tile callback `+0x1f8` saved into `+0x1ec` / `+0x1f0` / `+0x1f4`; `+0x130 = 0x78`;
    /// `+0x134 = +0xb8`; the Statue's Handle and the Box hit / tile callbacks installed; vy = vx = 0.
    /// A saved `+0x4c` of 0 (an idled record, `handleCleared`) is kept as such and comes back at the thaw.
    public static func turnIntoStatue(_ w: SpriteWorld, id: Int) {
        guard let s = w.active.record(id: id) else { return }
        w.player.cue(PlayerCue(call: .threeD, snd: sound, priority: 1, volume: 0x32, position: s.centre))
        w.active.update(id: id) { s in
            s.savedHandler = s.handler
            s.savedHandleCleared = s.handleCleared
            s.savedHasHit = s.hasHit
            s.savedHasTileHit = s.hasTileHit
            s.reentry = 0x78
            s.statueSavedMode = s.mode
            s.handler = .statue
            s.handleCleared = false
            s.hasHit = true                                     // `PTR_PTR_100a01f4` = `.HitBoxSprite`
            s.hasTileHit = true                                 // `PTR_PTR_100a01f0` = `.HitBoxTileSprite`
            s.vy = 0
            s.vx = 0
        }
    }

    /// `.HandleStatueSprite(s)` (M l. 56521–56555), every frame (no `+0xe9` test, no `.StandardSpriteHandles`, no
    /// cleanup): no light (`+0x9a == −1`) → `+0x9a = .AddLight(light 820, the centre (+0xe, +0x10), 0, 0, 0, 0x21)`;
    /// `+0xb8 = 0x1000b` (the colour-remap table 11); `+0x130 − 1`; v = 0; `+0x80 = 2` stored (no re-sort); the count
    /// below 20 and odd → `+0xb8 = 0` (the blink); below 1 → the saved Handle, callbacks and `+0xb8` restored, **HP
    /// −200**, `.RemoveLight(+0x9a)`.
    public static func handle(world w: SpriteWorld, id: Int, lights: inout LightTable) {
        guard w.active.record(id: id) != nil else { return }
        w.active.update(id: id) { s in
            if s.light == -1 {
                s.light = lights.add(face: light, x: Int16(truncatingIfNeeded: s.centre.x),
                                     y: Int16(truncatingIfNeeded: s.centre.y), vx: 0, vy: 0, accelY: 0, colour: 0x21)
            }
            s.mode = 0x1000b
            s.reentry &-= 1
            s.vy = 0
            s.vx = 0
            s.layer = 2
            if s.reentry < 0x14 && UInt32(bitPattern: s.reentry) & 1 != 0 { s.mode = 0 }
            if s.reentry < 1 {
                s.handler = s.savedHandler ?? s.handler
                s.handleCleared = s.savedHandleCleared
                s.hasHit = s.savedHasHit
                s.hasTileHit = s.savedHasTileHit
                s.mode = s.statueSavedMode
                s.hp &-= 200
                lights.remove(&s.light)
            }
        }
    }
}

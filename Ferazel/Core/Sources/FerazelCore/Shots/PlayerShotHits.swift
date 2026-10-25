import Foundation

/// What happens to a player shot when it hits something. `.KillPlayerShot` is built (CS fix round 2) for its first
/// built caller, the spring arm of `.HitBackgroundSprite` (M l. 63718–63720). // later: SH — `.HitPlayerShotSprite`
/// (M l. 50947–51068) and the other arms of `.HitPlayerShotTileSprite` (M l. 51219–51392) go here and call `kill`.
public enum PlayerShotHits {
    /// The snd slots `.KillPlayerShot` reads (`SoundSlots`): `*_DAT_100a0420` = 301 (the generic hit), `*_DAT_100a01e4`
    /// = 423 (the orb struck), `*_DAT_100a01e0` = 424 (the orb broken), `*_DAT_1009fdec` = 435 (the seed bursts),
    /// `*_DAT_100a03e4` = 419 (an id ≥ 100).
    static let hitSound: Int16 = 301, orbHitSound: Int16 = 423, orbBreakSound: Int16 = 424, seedSound: Int16 = 435,
               highSound: Int16 = 419

    /// `.KillPlayerShot(shot, sound, effect) @ 1005ac34` (M l. 51076–51215; raw `1005ac34..1005b094`), in order:
    /// 1. `.StandardSpriteCleanup(shot)` (raw `1005ac58`, r3 = the shot — the decompile drops the argument);
    /// 2. id 100: nothing more;
    /// 3. power `+0x170` > 1: the four followers `+0x1d4…+0x1e0` get `+0xe9 = 1` (every id but 100, the orb included);
    /// 4. id ≥ 100 (≠ 0x5a — always true): `+0xa6 == 0` → `.STPlay3DSoundRand(419, 1, 0xab, +0xa)` (the position, not
    ///    the centre; no `sound` test); then `+0xa6 = −6`. The shot is **not** killed;
    /// 5. ids < 100: the effect flag is cleared when the face `+0xc0` is wholly outside the clip window
    ///    (`+0x1b6 ≥ face right` or `+0x1b8 ≤ face left`, the face's `+0xe` / `+0xa`), then by id —
    ///    - 0: `sound` → snd 301 at the centre `+0xe`; `effect` → `MTNewSprite(0, x − 8, y − 0xc, 0xb, −1,
    ///      .SetupEffectSprite)`; killed;
    ///    - 0x50 (the orb): `+0x168` − 1; below 1 → `sound` → snd 424, `.ExplodeFaceIntoParticles(+0xc0, +0xa, 2, 1, 7,
    ///      0x50, 0x65)`, killed; else `sound` → snd 423 and the orb lives (neither flag gates more);
    ///    - 0x5a (the seed): snd 435 (no `sound` test), the mask flash `*_DAT_100a00fc = 3`, the shake `*_DAT_1009ffa0
    ///      = 0x14`, `MTNewSprite(0x4b7, x − 0x2a, y − 0x2a, 0xc, −1, .SetupEffectSprite)` (`+0xf4` → its `+0xb8 =
    ///      0x10004`); `+0xf0` clear → a 4 × 4 walk over (x − 4 + 8i, y − 10 + 8j), i outer, a counter from 0 that spawns
    ///      at every second cell: `MTNewSprite(0x442, cx − 0x18, cy − 0x18, 0xc, −1, .SetupEffectSprite)`, `FastRand(
    ///      0x96)`, `FUN_1003f218(smoke, .FindDesiredDirectionGeneric((cy, cx), centre), R + 400)`, smoke `+0x46 =
    ///      FastRand(7)`; killed (no `effect` test);
    ///    - any other id: effect type 5 (id 4: 2); `sound` → snd 301; `effect` → `MTNewSprite(type, x − 5, y − 0xc, 0xb,
    ///      −1, .SetupEffectSprite)`; ids 1 / 2 → `.ChangeLightColor(effect +0x9a, 0x21)`, 3 → 0x4d, 4 → 0x42; killed.
    /// Every `.STPlay3DSoundRand` draws its `FastRand(10000)` at the call (Invariant 4). A spawn that finds no free
    /// record (Ruling 16) runs no Setup and its stores are dropped; the later draws are still made.
    /// Ids 1…4 with the effect flag clear: the binary changes the colour of the light named by `r29 + 0x9a` — r29 still
    /// holds the caller's value (the spring arm's: the Background Handle's descriptor `PTR_PTR_100a0480`), a stale
    /// read [LOW: no light is changed here].
    /// - Parameters: `sound` / `effect` the two flags; `effects` prefs+6 (the effect's Setup); `faceWidth` (face `+6`,
    ///   the Cleanup) and `faceBounds` (face `+8`, the clip test) — Core has no face records.
    public static func kill(_ w: SpriteWorld, shot id: Int, sound: Bool, effect effectFlag: Bool, effects: Int16,
                            lights: inout LightTable,
                            faceWidth: (FaceRef) -> Int = { PlayerShot.cellRect($0).right },
                            faceBounds: (FaceRef) -> IdleSprites.Rect = PlayerShot.cellRect) {
        guard w.active.record(id: id) != nil else { return }
        w.standardSpriteCleanup(id, faceWidth: faceWidth)
        guard let s = w.active.record(id: id), s.type != 100 else { return }
        if 1 < s.power {
            for f in PlayerShot.followers(s).compactMap({ $0 }) { w.active.update(id: f) { $0.dead = true } }
        }
        let x = PlayerShot.h16(s.x), y = PlayerShot.h16(s.y)
        func play(_ snd: Int16, volume: Int16 = 0x100, at position: SpriteSlot.Point) {
            w.player.cue(PlayerCue(call: .threeDRand, snd: snd, priority: 1, volume: volume, position: position,
                                   rate: w.rng.soundRate()))
        }
        func killed() { w.active.update(id: id) { $0.dead = true } }
        func spawn(_ type: Int16, _ x: Int, _ y: Int, layer: Int16) -> Int? {
            EffectSprite.spawn(w, type: type, x: x, y: y, layer: layer, effects: effects, lights: &lights)
        }
        guard s.type < 100 || s.type == PlayerShot.seed else {
            // 4.
            if s.counterA6 == 0 { play(highSound, volume: 0xab, at: SpriteSlot.Point(x: x, y: y)) }   // the i16 pair `+0xa`/`+0xc`
            w.active.update(id: id) { $0.counterA6 = -6 }
            return
        }
        // 5.
        var effect = effectFlag
        if let f = s.face {
            let b = faceBounds(f)
            if b.right <= s.clip.left || s.clip.right <= b.left { effect = false }
        }
        switch s.type {
        case 0:
            if sound { play(hitSound, at: s.centre) }
            if effect { _ = spawn(0, x - 8, y - 0xc, layer: 0xb) }
            killed()
        case PlayerShot.orb:
            w.active.update(id: id) { $0.stackX &-= 1 }
            if w.active.record(id: id)!.stackX < 1 {
                if sound { play(orbBreakSound, at: s.centre) }
                ExplodeFace.explode(w, face: s.face.flatMap(w.particleFaces.sprite), v: Int16(truncatingIfNeeded: y),
                                    h: Int16(truncatingIfNeeded: x), xStep: 2, yStep: 1, shape: 7, gravity: 0x50,
                                    style: 0x65)
                killed()
            } else if sound {
                play(orbHitSound, at: s.centre)
            }
        case PlayerShot.seed:
            play(seedSound, at: s.centre)
            w.flash.count = 3
            w.shakeStore = 0x14
            let big = spawn(EffectSprite.bigExplosion, x - 0x2a, y - 0x2a, layer: 0xc)
            if s.classWordF4 != 0, let big { w.active.update(id: big) { $0.mode = 0x10004 } }
            if s.seedHidden == 0 {
                var counter: Int16 = 0
                for i in 0..<4 {
                    for j in 0..<4 {
                        counter -= 1
                        let cx = Int16(truncatingIfNeeded: x + 8 * i - 4), cy = Int16(truncatingIfNeeded: y + 8 * j - 10)
                        guard counter < 1 else { continue }
                        counter = 2
                        let smoke = spawn(EffectSprite.smoke, Int(cx) - 0x18, Int(cy) - 0x18, layer: 0xc)
                        let m = Int32(w.rng.next(0x96)) + 400
                        let dir = BloodSpray.direction(target: (v: cy, h: cx),
                                                       from: (v: Int16(truncatingIfNeeded: s.centre.y),
                                                              h: Int16(truncatingIfNeeded: s.centre.x)))
                        if let smoke { w.active.update(id: smoke) { PlayerShot.addDirImpulse(&$0, dir: dir, magnitude: m) } }
                        let phase = w.rng.next(7)
                        if let smoke { w.active.update(id: smoke) { $0.phase = phase } }
                    }
                }
            }
            killed()
        default:
            let type: Int16 = s.type == 4 ? 2 : 5
            if sound { play(hitSound, at: s.centre) }
            var e: Int?
            if effect { e = spawn(type, x - 5, y - 0xc, layer: 0xb) }
            let colour: Int16? = s.type == 3 ? 0x4d : s.type == 4 ? 0x42 : (1...2).contains(s.type) ? 0x21 : nil
            if let colour, let e, let light = w.active.record(id: e)?.light { lights.changeColor(light, colour) }
            killed()
        }
    }
}

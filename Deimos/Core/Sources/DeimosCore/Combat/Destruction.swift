import Foundation
import HectorResources

/// One observable step of `destroyEntity`, in call order — the optional step log of the destroy path (plan
/// invariant 13: logs are closure parameters, never stored).
public enum DestroyStep: Equatable, Sendable {
    /// `FUN_10012c00`: the hit glow off.
    case glowOff
    /// `FUN_1002a6d0`: the bounding box joined the debris list.
    case obstacle(MacRect)
    /// `FUN_10043340`: the destruct particles were requested.
    case particles(FourCC)
    /// The media gate `FUN_10016880` was asked; `allowed` is its answer.
    case mediaGate(allowed: Bool)
    /// `FUN_10033220`: the destruct spawn was requested.
    case spawn(FourCC)
    /// `FUN_100181e0`: the destruct notice was posted.
    case notice
    /// `FUN_100475e0(rec, 1)`: the destruct sound (the cue, when one was made).
    case sound(FourCC)
    /// `10016500..10016504`: +0xcb, +0xd9, +0xda written.
    case flags
    /// `FUN_10006200`: G+0x40 += 1.
    case accuracyCount
    /// `10016528..10016530`: the bonus draw `R(0, 100)` and the object it chose (`none` → no request).
    case randomBonus(r: Int32, object: FourCC)
}

/// Entity destruction (damage-health-death.md §4.1, scoring-bonuses.md §7, spawn-and-waves.md §5; plan C11b).
///
/// Listing read (`disasm-review3-all.txt`), `FUN_10016300(e, killer r4, now r5) @ 10016300` (`10016300..10016874`):
/// - `10016320..10016328` +0xcb set → return. `10016330` `FUN_10012c00` (+0x74 = 0).
/// - `10016338..10016364` +0x19 == 0 (not air) and `destructCreateObstacle` (+0x4b3) → `FUN_10012a00` (the Mac
///   bounding box) → `FUN_1002a6d0` (debris list).
/// - `1001636c..100163c4` `destructParticle_ID` (+0x47c) ≠ `none` → `FUN_10043340` {+0 x, +4 y, +8 colour +0x480,
///   +0xc 0, +0x10 unit +8 == `grnd`, +0x14 the ID}.
/// - `100163cc..10016488` `destructSpawn_ID` (+0x478) ≠ `none` and `FUN_10016880(e)` → the template r2+0x180
///   (`0x100e64b0`, runtime +0x24 = −1) with +0x00 the ID, +0x04/+0x08 the position, +0x14 = +0xd8, +0x20 = e,
///   +0x24 = +0x9c → `FUN_10033220(req, 0, 0)`.
/// - `10016490..100164d0` `destructNotice_STR` (+0x482) non-empty and `strcmp(·, "none")` ≠ 0 → a local record
///   {+0 text, +4 hold 0, +5 fade-in 0} → `FUN_100181e0(rec, now)`. **The record's +8 delay, +0xc sound and +0x24
///   alignment are never written** (uninitialised stack, r1+0x94…+0xb3); dead in shipped data (no unit has a
///   destruct notice — messages-notices-console §4.4); here delay 0, sound `none`, alignment `CEGA` (the reset's).
/// - `100164d8..100164f0` `destructSound_ID` (+0x4bc) ≠ `none` → `FUN_100475e0(rec, 1)`.
/// - `100164f8..10016504` +0xcb = 1, +0xd9 = killer, +0xda = 1.
/// - `10016508..10016514` `includeInGroundAccuracyCount` (+0x134) → `FUN_10006200` (G+0x40 += 1).
/// - `1001651c..1001685c` `destructReleaseRandomBonus` (+0x4b4) → **draw `10016530`** r = `R(0, 100)`; the ladder
///   (each test `r < fctiwz(flli n)`, `cmpw; bge next`): see `randomBonusObject`; a non-`none` object → the
///   template r2+0x180 with +0x00 the object, +0x04/+0x08 the position, +0x14 = +0xd8, +0x20 = e, +0x24 = +0x9c →
///   `FUN_10033220` (`100167c8..1001685c`).
/// No score here (the kill score is `FUN_10014f10`'s), no coins (the sweep's `FUN_10036120`).
extension GameState {
    /// `FUN_10016300(e, killer, now) @ 10016300` — destroy entity `i` (see the type's comment for the order). The
    /// target of a state timer's or rule's `"Destroy"` (killer −1), of a damage kill (`FUN_10014f10`), a pickup
    /// (`FUN_10033850`), the owner chain of the sweep and `FUN_10036120`'s destroyed tail. `now` is the caller's
    /// game time (r5); only the notice reads it.
    public mutating func destroyEntity(_ i: Int, killer: Int8, now: Int32, log: ((DestroyStep) -> Void)? = nil) {
        guard !world.entities[i].deleted else { return }                     // 10016320..10016328
        let u = assets.definitions.units[world.entities[i].unit]             // 1001632c (r30)
        world.entities[i].object.hitGlowOn = false                           // 10016330 FUN_10012c00
        log?(.glowOff)
        if !world.entities[i].object.air && u.destructCreateObstacle {       // 10016338..1001634c
            let r = boundingBox(i)                                           // 10016350..10016358 FUN_10012a00
            debris.add(r)                                                    // 10016360..10016364 FUN_1002a6d0
            log?(.obstacle(r))
        }
        if u.destructParticle != .none {                                     // 1001636c..10016378
            let o = world.entities[i].object
            particles.emit(ParticleRequest(x: o.x, y: o.y, colour: u.destructParticleColor, delay: 0,
                                           ground: u.layer == UnitDefinition.ground, type: u.destructParticle),
                           rng: &rng)                                        // 1001637c..100163c4 FUN_10043340
            log?(.particles(u.destructParticle))
        }
        if u.destructSpawn != .none {                                        // 100163cc..100163d8
            let allowed = mediaGate(i)                                       // 100163dc..100163ec FUN_10016880
            log?(.mediaGate(allowed: allowed))
            if allowed {
                spawn(childRequest(i, unit: u.destructSpawn))               // 100163f0..10016488
                log?(.spawn(u.destructSpawn))
            }
        }
        if !u.destructNotice.isEmpty && u.destructNotice != "none" {         // 10016490..100164b4
            let text = Array((MacRoman.encode(u.destructNotice, lossy: true) ?? []).prefix(63))
            notice.post(NoticeSlot.Post(text: text, hold: false, fadeIn: false, delay: 0, sound: SoundRecord(),
                                        alignment: .centerInGameArea), now: now)   // 100164b8..100164d0 FUN_100181e0
            log?(.notice)
        }
        if u.destructSound.id != .none {                                     // 100164d8..100164e4
            if let cue = SoundPlay.record(u.destructSound, allowMultiple: true, rng: &rng) {   // 100164e8..100164f0
                cues.sounds.append(cue)
            }
            log?(.sound(u.destructSound.id))
        }
        world.entities[i].deleted = true                                     // 100164f8..100164fc
        world.entities[i].killer = killer                                    // 10016500
        world.entities[i].destroyed = true                                   // 10016504
        log?(.flags)
        if u.includeInGroundAccuracyCount {                                  // 10016508..10016510
            flags.groundDestroyed &+= 1                                      // 10016514 FUN_10006200
            log?(.accuracyCount)
        }
        guard u.destructReleaseRandomBonus else { return }                   // 1001651c..10016524
        let r = rng.range(Int32(0), 100)                                     // 10016528..10016530
        let object = randomBonusObject(r)                                    // 1001653c..100167b8
        log?(.randomBonus(r: r, object: object))
        guard object != .none else { return }                                // 100167bc..100167c4
        spawn(childRequest(i, unit: object))                                 // 100167c8..1001685c
    }

    /// The request every entity-sourced spawn of this module builds from the template r2+0x180 (`0x100e64b0`,
    /// runtime): +0x00 `unit`, +0x04/+0x08 the entity's position (+0x00/+0x04), +0x14 = +0xd8, +0x20 = the entity,
    /// +0x24 = its serial +0x9c (`10016460..10016484`, `10016834..10016858`, `10016b78..10016b9c`).
    func childRequest(_ i: Int, unit: FourCC) -> SpawnRequest {
        let e = world.entities[i]
        var req = SpawnRequest.template
        req.unit = unit
        req.x = e.object.x
        req.y = e.object.y
        req.player = e.ownerPlayer
        req.owner = i
        req.ownerSerial = e.serial
        return req
    }

    /// The random-bonus ladder of `FUN_10016300` (`1001653c..100167b8`; scoring-bonuses §7) for the draw `r`, with
    /// `F(n)` = `fctiwz(flli n)` and `O(k)` = `idli gaob` item k (`FUN_100201f0`):
    /// r < F(209) → reward armed (`FUN_10005d00`, G+0x0c) ∧ r < F(218) → O(30) and the reward disarmed
    /// (`FUN_10005d10`), else O(25); r < F(210) → O(26); F(211) → O(27); F(212) → O(28); F(213) → O(29); F(214) →
    /// O(30); F(215) → O(31); F(216) → O(32); then sector (`FUN_10005cd0`, G+0x14) < F(219) → O(32); r < F(217) →
    /// O(33); else O(34).
    mutating func randomBonusObject(_ r: Int32) -> FourCC {
        func f(_ n: Int) -> Int32 { EntityDraw.fctiwz(assets.floats[n]) }
        func o(_ k: Int) -> FourCC { assets.objects.indices.contains(k) ? assets.objects[k] : .none }
        if r < f(209) {                                                      // 1001653c..10016558
            if flags.rewardArmed {                                           // 1001655c..10016568
                if r < f(218) {                                              // 1001656c..10016588
                    let object = o(30)                                       // 1001658c..10016598
                    flags.rewardArmed = false                                // 1001659c FUN_10005d10
                    return object
                }
                return o(25)                                                 // 100165a8..100165b4
            }
            return o(25)                                                     // 100165bc..100165c8
        }
        let rungs: [(flli: Int, object: Int)] = [(210, 26), (211, 27), (212, 28), (213, 29), (214, 30),
                                                (215, 31), (216, 32)]       // 100165d0..10016738
        for rung in rungs where r < f(rung.flli) { return o(rung.object) }
        if flags.sector < f(219) { return o(32) }                            // 1001673c..10016774
        return r < f(217) ? o(33) : o(34)                                    // 10016778..100167b8
    }
}

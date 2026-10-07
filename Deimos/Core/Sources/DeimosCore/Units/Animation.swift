import Foundation
import HectorResources

/// The animation step, the rotation gate and the turn (units-movement.md §8; loose-ends-combat.md §7.1; plan C9).
/// Listings read for C9: `FUN_10015930` (`10015930..10015b34`), `FUN_10017150` (`10017150..100172c4`),
/// `FUN_100172d0` (`100172d0..10017504`). The heading helpers are C8's `facing(of:)` (`FUN_100161c0`) and
/// `frame(of:forHeading:)` (`FUN_10016230`, StateEntry.swift).
///
/// **RNG draw (C9 owns it, invariant 6; plan review leg A C-1):** `10015a0c` — a `ContinuousFrameRandomisation`
/// state draws `R(base, last)` on **every** step the gate passes (no draw when base == last — one frame per
/// direction — because `FUN_10046580` makes none for min == max).
extension GameState {
    /// `FUN_10015930(e, now) @ 10015930` — the animation step (units-movement §8.1). Gate: +0xc8 (animates),
    /// `FrameDelta` (+0x31c) > 0, not `DoRotateToTarget` (+0x303), `now > +0xbc + FrameDelay` (`10015990 cmpw;
    /// ble`, signed). Row: dir = `fctiwz(fl32(float(NumDirections) · fl32(float(+0x138) / 360.0)))` (`fdivs`,
    /// `fmuls` — the compass heading, **truncated**, unlike `FUN_10016230`'s rounding), base = dir · FPD,
    /// last = base + FPD − 1. `ContinuousFrameRandomisation` (+0x302) → frame = **draw `10015a0c`** `R(base,
    /// last)` (+0xc2 is not consulted). Else, unless stopped, repeat `FrameDelta` times while not stopped: forward
    /// (+0xc0 = 0) at last → `!DoLoopAnimation` (+0x301): stopped (+0xc2 = 1); `DoAnimateBackwards` (+0x300):
    /// +0xc0 = 1, frame = last − 1; else frame = base; not at last → frame + 1. Backward at base → not looping:
    /// stopped; `DoAnimateBackwards`: +0xc0 = 0, frame = base + 1; else frame = last; not at base → frame − 1.
    /// Then (both paths, also when already stopped) +0xbc = now, +0x34 = 1 (`10015b00..10015b08`); the frame
    /// pointer +0x50 re-fetch (`FUN_10019ad0`) has no replica field.
    public mutating func stepAnimation(_ i: Int, now: Int32) {
        guard world.entities[i].animates, let st = currentState(i) else { return }   // 1001594c..10015968
        let delta = st.stateFrameDelta
        guard delta > 0, !st.stateDoRotateToTarget else { return }             // 1001596c..10015980
        guard now > world.entities[i].lastFrameStep &+ st.stateFrameDelay else { return }   // 10015984..10015994
        let q: Float = Float(world.entities[i].heading) / Float(360)           // 10015998..100159dc
        let dir = EntityDraw.fctiwz(Float(st.stateNumDirections) * q)          // 100159b0..100159fc
        let fpd = st.stateFramesPerDirection
        let base = dir &* fpd                                                  // 10015a00
        let last = base &+ (fpd &- 1)                                          // 100159d8, 10015a04
        // FramesPerDirection 0 makes last = base − 1: `FUN_10046580(base, base − 1)` divides by a zero span — undefined
        // `divw` in the original, a trap here (MSLRandom.range's precondition). Unreachable: every shipped random-frame
        // state has FPD ≥ 1 (11 states: plsh FPD 8, spla/spsm/spme/spti FPD 5).
        if st.stateContinuousFrameRandomisation {                              // 100159d0, 10015a08
            world.entities[i].object.frame = rng.range(base, last)             // 10015a0c..10015a14
        } else if !world.entities[i].animationStopped {                        // 10015a1c..10015a24
            var e = world.entities[i]
            for _ in 0..<delta {                                               // 10015a28..10015afc (CTR)
                if e.animationStopped { break }                                // 10015a38..10015a40
                let f = e.object.frame
                if !e.animationBackwards {                                     // 10015a44..10015a4c
                    if f == last {                                             // 10015a50..10015a58
                        if !st.stateDoLoopAnimation { e.animationStopped = true }          // 10015a90..10015a94
                        else if st.stateDoAnimateBackwards {                   // 10015a68..10015a80
                            e.animationBackwards = true
                            e.object.frame = last &- 1
                        } else { e.object.frame = base }                       // 10015a88
                    } else { e.object.frame = f &+ 1 }                         // 10015a9c..10015aa0
                } else {
                    if f == base {                                             // 10015aa8..10015ab0
                        if !st.stateDoLoopAnimation { e.animationStopped = true }          // 10015ae8..10015aec
                        else if st.stateDoAnimateBackwards {                   // 10015ac0..10015ad8
                            e.animationBackwards = false
                            e.object.frame = base &+ 1
                        } else { e.object.frame = last }                       // 10015ae0
                    } else { e.object.frame = f &- 1 }                         // 10015af4..10015af8
                }
            }
            world.entities[i] = e
        }
        world.entities[i].lastFrameStep = now                                  // 10015b00
        world.entities[i].object.sizeDirty = true                              // 10015b04..10015b08
    }

    /// `FUN_10017150(e, now) @ 10017150` — the rotation gate, called first by the spawn-set executor
    /// `FUN_10015b40` (`10015b64`; loose-ends-combat §7.1): not `DoRotateToTarget` → +0xc1 = 0, returns 1.
    /// Else +0xc4 > 0 → +0xc4 − 1 (floored at 0); still > 0 → hold (returns 0). Else for each spawn-set record k of
    /// the current state (`10017204..10017290`): skip a set whose `Spawn_ID` is `none`; hold if the record is
    /// active (+0x14), the set has `PauseAnyRotationWhileSpawning` (+0x48) and `0 < remaining < volley`
    /// (`10017268..1001727c`). Not held → `FUN_100172d0` and its result.
    @discardableResult
    public mutating func rotationGate(_ i: Int, now: Int32) -> Bool {
        guard let st = currentState(i) else { return false }
        guard st.stateDoRotateToTarget else {                                  // 10017180..10017198
            world.entities[i].rotating = false
            return true
        }
        if world.entities[i].rotationPause > 0 {                               // 1001719c..100171c0
            world.entities[i].rotationPause &-= 1
            if world.entities[i].rotationPause < 0 { world.entities[i].rotationPause = 0 }
        }
        if world.entities[i].rotationPause > 0 { return false }                // 100171c4..100171d8
        let s = Int(world.entities[i].state)
        let records = world.entities[i].spawnRecords.indices.contains(s) ? world.entities[i].spawnRecords[s] : []
        for k in records.indices where k < st.spawnSets.count {                // 10017204..10017290
            let set = st.spawnSets[k]
            if set.stateSpawnSetSpawn == .none { continue }                    // 10017224..10017230
            let r = records[k]
            if r.active && set.stateSpawnSetPauseAnyRotationWhileSpawning
                && r.remaining > 0 && r.remaining < r.volley {                 // 10017250..1001727c
                return false
            }
        }
        return turnTowardTarget(i, now: now)                                   // 100172a4
    }

    /// `FUN_100172d0(e, now) @ 100172d0` — turn one direction step toward the target (units-movement §8.2): not
    /// `DoRotateToTarget` → +0xc1 = 0, returns 1. Not fleeing: no tracked player (+0x118 == −1) → +0xc1 = 0,
    /// returns 0; else +0xc1 = 1 (fleeing leaves +0xc1 alone). `now > +0xbc + FrameDelay` else returns 0.
    /// want = `FUN_10042ad0(trunc x, trunc y, trunc tx, trunc ty)` (compass); `frame(of:forHeading: want)` ==
    /// frame → returns 1 (no time stamp). Else cur = `facing(of:)` (inline `FUN_100161c0`), d = want − cur,
    /// `> 180 → −360`, then `< −180 → +360`; total = FPD · NumDirections; d > 0 → frame + 1 repeated FPD times
    /// (`≥ total → 0`), else frame − 1 repeated FPD times (`< 0 → total − 1`); +0xbc = now, +0x34 = 1, returns 0.
    @discardableResult
    public mutating func turnTowardTarget(_ i: Int, now: Int32) -> Bool {
        guard let st = currentState(i) else { return false }
        guard st.stateDoRotateToTarget else {                                  // 10017300..10017318
            world.entities[i].rotating = false
            return true
        }
        if !world.entities[i].fleeing {                                        // 1001731c..10017324
            if world.entities[i].trackedPlayer == -1 {                         // 10017328..10017340
                world.entities[i].rotating = false
                return false
            }
            world.entities[i].rotating = true                                  // 10017344..10017348
        }
        guard now > world.entities[i].lastFrameStep &+ st.stateFrameDelay else { return false }   // 1001734c..1001735c
        let e = world.entities[i]
        let want = Trig.headingTo(x: EntityDraw.fctiwz(e.object.x), y: EntityDraw.fctiwz(e.object.y),
                                  tx: EntityDraw.fctiwz(e.targetX), ty: EntityDraw.fctiwz(e.targetY))   // 10017360..100173b8
        if frame(of: i, forHeading: want) == e.object.frame { return true }   // 100173bc..100173d8
        var d = want &- facing(of: i)                                          // 100173dc..10017438
        if d > 180 { d &-= 360 }                                               // 10017440..1001744c
        if d < -180 { d &+= 360 }                                              // 10017450..10017458
        let fpd = st.stateFramesPerDirection
        let total = fpd &* st.stateNumDirections                               // 10017444
        var f = e.object.frame
        if d > 0 {                                                             // 1001745c..10017498
            for _ in 0..<max(fpd, 0) {
                f &+= 1
                if !(f < total) { f = 0 }
            }
        } else {                                                               // 1001749c..100174cc
            for _ in 0..<max(fpd, 0) {
                f &-= 1
                if f < 0 { f = total &- 1 }
            }
        }
        world.entities[i].object.frame = f
        world.entities[i].lastFrameStep = now                                  // 100174d0
        world.entities[i].object.sizeDirty = true                              // 100174d4..100174d8
        return false
    }
}

import Foundation
import HectorResources

/// `FUN_100146f0`'s two out-bytes: the target name was `"Delete"` / `"Destroy"` (the caller removes the
/// entity), directly or through the on-counter recursion.
public struct StateEntryOutcome: Equatable, Sendable {
    public var delete = false
    public var destroy = false

    public init(delete: Bool = false, destroy: Bool = false) {
        self.delete = delete
        self.destroy = destroy
    }
}

/// State entry and its helpers (units-movement.md §4, spawn-and-waves.md §2.2, §3.2 step 6, §4; plan C8).
///
/// **`FUN_100146f0(e, spawning, name, now, &del, &destroy) @ 100146f0`** (`100146f0..10014f0c`, read for C8):
/// 1. del = destroy = 0; `strcmp(name, "Delete")` == 0 → del, return; `"Destroy"` → destroy, return.
/// 2. The state is found by name over `numStates` with **no break** (a duplicated name resolves to the last);
///    none → return with nothing changed.
/// 3. The **old** state is read before +0xa8 is overwritten: its `OrbitOwner` (+0x330) with the orbit angle
///    +0xe0, and whether its `stateFlee_ID` (+0x320) ≠ `none`. At spawn +0xa8 = −1, so the "old state" is the
///    0x5e0 block below state 0 — unit+0x230 (orbit) and unit+0x220 (flee), both in the zeroed no-key region
///    0x1c4…0x25b: no orbit, flee word 0 ≠ `none` (harmless: fleeing is 0 at spawn).
/// 4. +0xa8 = new; +0xa4 = now; enterCount[new] += 1; +0xd0 = now; +0xd4 = 0; +0xe8 = 0; +0xf4 = 0; +0xc2 = 0
///    (`10014858..10014894`).
/// 5. **Draw `100148dc`**: timer +0xb8 = `R(OnTimerMin, OnTimerMax)`.
/// 6. Pickup appearance: unit `pickup_Type_ID` `grnd`/`air `/`spec` → `PEAG`/`PEAA`/`SPEC`; unless the state's
///    `Pickup_DoNotChangeAppearanceOnStateChange` (+0x357), `FUN_1002adb0(code, +0xf8, sector)` (the select
///    cycle, no draws) → +0xf8 = its ID, face +0x1c = its `scoreBarPreviewFace`, +0x50 = 0. A pickup unit skips
///    step 7 either way (`100149ac li r5,1`).
/// 7. Otherwise face +0x1c = the state's face; when spawning or the face changed: frame = **draw `100149f0`**
///    `R(FrameMin, FrameMax)`, or — with `initialHeadingSetInEditor` — `FUN_10016230(e, +0x138)` (no draw).
/// 8. +0x36 = `stateDrawToTerrain`. Spawning: visibility / target / step, glow / target / step from the unit and
///    state ints (exact int → float); scale% = `initialScalePercent` + (tol ≠ 0: **draw `10014b14`**
///    `R(−(tol/2), tol/2)`), < 0 → 0; +0x84/+0x88/+0x8c = `FUN_1001a260` (= float(p) / 100.0, `fdivs`).
/// 9. Spawning, face changed or frame changed → `FUN_10012940` (the half-size refresh, itself gated on +0x34).
/// 10. +0xc0 = `DoAnimateBackwards`.
/// 11. Velocity set-up (units-movement §4, `10014bac..10014d78`): new `LockToOwnerLoc` → v, accel, desired =
///     0.0. Else s = `FUN_10042c90(v)` = fl32(sqrt(fl32(vx·vx) + fl32(vy·vy))) (two `fmuls`, `fadds`, MathLib
///     sqrt, `frsp`); h′ = spawning ? internal(+0x138) : (old Orbit ? +0xe0 : `headingOf(v)`); M = MaxSpeed,
///     diff = |M − s|, step = min(Delta, diff), s1 = M > s ? s + step : s − step; accel = vector(h′, s1) − v;
///     desired = vector(h′, M). Not spawning and +0xa0 ≠ −1 → `FUN_10033600` (at spawn `FUN_10035cd0` calls it
///     after this function).
/// 12. New `stateFlee_ID` ≠ `none` → `FUN_10017510` (its draws, FleePoint.swift); else fleeing and the old flee
///     ≠ `none` → fleeing = 0.
/// 13. `FUN_10017cb0(e, now)` — spawn-set arming (its draws).
/// 14. On-counter: `OnCounter` > 0 and enterCount[new] == OnCounter → target `OnCounterChangeTo`: `"Delete"` /
///     `"Destroy"` → the out-byte, return; non-empty and ≠ `"none"` → enterCount[new] = 0 and the recursive
///     `FUN_100146f0(e, 0, target, now)`.
/// 15. +0xc8 = face ≠ `none` ∧ the **outer** state's `FrameDelta` > 0 (written after a recursion too — kept);
///     then two debug asserts (numDirections, framesPerDirection > 0) with no effect.
extension GameState {
    /// The current state of entity `i` (`FUN_10014650`: unit + 0x4e0 + state·0x5e0), nil outside the states read.
    func currentState(_ i: Int) -> UnitState? {
        let e = world.entities[i]
        guard e.unit >= 0 else { return nil }
        let states = assets.definitions.units[e.unit].states
        return states.indices.contains(Int(e.state)) ? states[Int(e.state)] : nil
    }

    /// `FUN_100146f0` — enter the state named `name` (see the type comment).
    @discardableResult
    public mutating func enterState(_ i: Int, named name: String, spawning: Bool, now: Int32) -> StateEntryOutcome {
        if name == "Delete" { return StateEntryOutcome(delete: true) }         // 1001473c..10014754
        if name == "Destroy" { return StateEntryOutcome(destroy: true) }       // 10014758..10014778
        let u = assets.definitions.units[world.entities[i].unit]
        var found = -1
        for s in 0..<min(Int(u.numStates), u.states.count) where u.states[s].stateName == name {   // 10014790..100147c4
            found = s                                                          // no break: the last match wins
        }
        guard found >= 0 else { return StateEntryOutcome() }                   // 100147c8..100147cc
        let old = currentState(i)                                              // 100147d0..10014818
        let oldOrbit = old?.stateOrbitOwner ?? false
        let oldOrbitAngle = world.entities[i].orbitAngle
        let oldFleeSet = old.map { $0.stateFlee != .none } ?? true             // spawn: unit+0x220 = 0 ≠ 'none'
        let oldFace = world.entities[i].object.face
        let oldFrame = world.entities[i].object.frame
        let st = u.states[found]
        do {
            var e = world.entities[i]
            e.state = Int32(found)                                             // 10014858
            e.stateStart = now                                                 // 1001485c
            e.enterCount[found] &+= 1                                          // 10014860..10014880
            e.collisionSpawnTime = now                                         // 10014884
            e.collisionSpawnCount = 0                                          // 10014888
            e.soundCount = 0                                                   // 1001488c
            e.burstCount = 0                                                   // 10014890
            e.animationStopped = false                                         // 10014894
            world.entities[i] = e
        }
        world.entities[i].timer = rng.range(st.stateOnTimerMin, st.stateOnTimerMax)   // 100148b8..100148e4
        let pickupCode: FourCC
        switch u.pickupType {                                                  // 100148e8..10014954
        case UnitDefinition.ground: pickupCode = FourCC("PEAG")!
        case UnitDefinition.air: pickupCode = FourCC("PEAA")!
        case FourCC("spec")!: pickupCode = FourCC("SPEC")!
        default: pickupCode = .none
        }
        if pickupCode != .none {                                               // 10014958..100149ac
            if !st.statePickupDoNotChangeAppearanceOnStateChange {
                let w = Player.nextWeapon(type: pickupCode, after: world.entities[i].shownWeapon,
                                          sector: flags.sector, weapons: assets.definitions.weapons)
                if let w {                                                     // 1001498c..10014998
                    world.entities[i].shownWeapon = w.id
                    world.entities[i].object.face = w.scoreBarPreviewFace      // 1001499c..100149a4
                }
                // nil: the original reads +0x130 of a null pointer (10014990 beq skips only the +0xf8 store) —
                // not reachable with shipped data (every pickup code has a weapon at every sector); face kept.
            }
        } else {
            world.entities[i].object.face = st.stateSpriteFace                 // 100149b8..100149c0
            if spawning || world.entities[i].object.face != oldFace {          // 100149bc..100149d4
                if !u.initialHeadingSetInEditor {                              // 100149d8..100149e4
                    world.entities[i].object.frame = rng.range(st.stateSpriteFrameMin, st.stateSpriteFrameMax)   // 100149f0
                } else {
                    world.entities[i].object.frame = frame(of: i, forHeading: world.entities[i].heading)  // 10014a08
                }
            }
        }
        world.entities[i].object.drawToTerrain = st.stateDrawToTerrain        // 10014a28..10014a30
        if spawning {                                                          // 10014a34..10014b54
            var o = world.entities[i].object
            o.visibility = Float(u.initialVisibilityPercent)                   // 10014a44..10014a68
            o.visibilityTarget = Float(st.stateRequiredVisibilityPercent)      // 10014a6c..10014a8c
            o.visibilityStep = Float(st.stateVisibilityDeltaPercent)           // 10014a90..10014aa4
            o.glow = Float(st.stateTintPercent)                                // 10014aa8..10014abc
            o.glowTarget = Float(st.stateTintPercent)                          // 10014ac0..10014ad4
            o.glowStep = Float(st.stateTintDeltaPercent)                       // 10014ad8..10014aec
            world.entities[i].object = o
            var pct = u.initialScalePercent                                    // 10014af0..10014af8
            let tol = u.initialScalePercentTolerance
            if tol != 0 {                                                      // 10014afc..10014b00
                let half = tol / 2                                             // 10014b04..10014b10
                pct = pct &+ rng.range(0 &- half, half)                        // 10014b14
                if pct < 0 { pct = 0 }                                         // 10014b1c..10014b24
            }
            world.entities[i].object.scale = Self.percentScale(pct)            // 10014b28..10014b34
            world.entities[i].object.scaleTarget = Self.percentScale(st.stateRequiredScalePercent)   // 10014b38..b44
            world.entities[i].object.scaleStep = Self.percentScale(st.stateScaleDeltaPercent)        // 10014b48..b54
        }
        if spawning || world.entities[i].object.face != oldFace || world.entities[i].object.frame != oldFrame {
            refreshEntitySize(i)                                               // 10014b58..10014b84 FUN_10012940
        }
        world.entities[i].animationBackwards = st.stateDoAnimateBackwards      // 10014b8c..10014ba8
        setUpVelocity(i, state: st, spawning: spawning, oldOrbit: oldOrbit, oldOrbitAngle: oldOrbitAngle)
        if st.stateFlee != .none {                                             // 10014d7c..10014d94
            setFleePoint(i, code: st.stateFlee)
        } else if world.entities[i].fleeing && oldFleeSet {                    // 10014d9c..10014db4
            world.entities[i].fleeing = false
        }
        armSpawnSets(i, now: now)                                              // 10014db8..10014dc0
        var outcome = StateEntryOutcome()
        if st.stateOnCounter > 0, world.entities[i].enterCount[found] == st.stateOnCounter {   // 10014dc8..10014de8
            let target = st.stateOnCounterChangeTo
            if target == "Delete" { return StateEntryOutcome(delete: true) }   // 10014dec..10014e0c
            if target == "Destroy" { return StateEntryOutcome(destroy: true) } // 10014e10..10014e30
            if !target.isEmpty && target != "none" {                           // 10014e34..10014e58
                world.entities[i].enterCount[found] = 0                        // 10014e5c..10014e70
                outcome = enterState(i, named: target, spawning: false, now: now)   // 10014e74..10014e88
            }
        }
        world.entities[i].animates = world.entities[i].object.face != .none && st.stateFrameDelta > 0   // 10014e8c..10014eb0
        return outcome
    }

    /// `FUN_1001a260(p)` — float(p) / 100.0 (`fsubs` magic, `fdivs` by `*(float*)0x100d6d38`).
    static func percentScale(_ p: Int32) -> Float { Float(p) / Float(100) }

    /// `FUN_10012940` on entity `i` (gated on +0x34; the frame's size at the current scale).
    mutating func refreshEntitySize(_ i: Int) {
        let a = assets
        world.entities[i].object.refreshSize { Player.frameSize(a, $0, $1, $2) }
    }

    /// `FUN_10019ee0(face)` — the face's frame count (0 for `none` or a group that does not load).
    func frameCount(_ face: FourCC) -> Int32 {
        guard face != .none, let g = try? assets.spriteGroup(face) else { return 0 }
        return Int32(g.frames.count)
    }

    /// The velocity block of `FUN_100146f0` (step 11 of the type comment).
    private mutating func setUpVelocity(_ i: Int, state st: UnitState, spawning: Bool, oldOrbit: Bool,
                                        oldOrbitAngle: Int32) {
        if st.stateLockToOwnerLoc {                                            // 10014bb4..10014bdc / 10014c88..10014cb0
            var e = world.entities[i]
            e.object.vx = 0; e.object.vy = 0
            e.accelX = 0; e.accelY = 0
            e.desiredVX = 0; e.desiredVY = 0
            world.entities[i] = e
            return
        }
        let vx = world.entities[i].object.vx, vy = world.entities[i].object.vy
        let s = Self.speedOf(vx, vy)                                           // 10014be4 / 10014cb8 FUN_10042c90
        let h: Int32
        if spawning {
            h = Trig.internalHeading(world.entities[i].heading)                // 10014bec..10014bfc
        } else {
            h = oldOrbit ? oldOrbitAngle : Trig.headingOf(vx: vx, vy: vy)      // 10014cc0..10014cdc
        }
        let m = st.stateMaxSpeed                                               // 10014c04 / 10014ce0
        let diff: Float = s < m ? m - s : s - m                                // 10014c08..10014c18
        var step = st.stateDelta                                               // 10014c1c
        if step > diff { step = diff }                                         // 10014c20..10014c28
        let s1: Float = m > s ? s + step : s - step                            // 10014c2c..10014c40
        let t = Trig.vector(heading: h, speed: s1)                             // 10014c48
        let d = Trig.vector(heading: h, speed: m)                              // 10014c7c
        var e = world.entities[i]
        e.accelX = t.x - vx                                                    // 10014c50..10014c64
        e.accelY = t.y - vy                                                    // 10014c68..10014c74
        e.desiredVX = d.x; e.desiredVY = d.y
        world.entities[i] = e
        if !spawning && world.entities[i].groupID != -1 {                      // 10014d64..10014d74
            initOwnerRelation(i)
        }
    }

    /// `FUN_10042c90(&v)` — fl32(sqrt(fl32(vx·vx) + fl32(vy·vy))).
    static func speedOf(_ vx: Float, _ vy: Float) -> Float {
        let xx: Float = vx * vx                                                // 10042ca4
        let yy: Float = vy * vy                                                // 10042ca8
        let sum: Float = xx + yy                                               // 10042cac
        return Float(Foundation.sqrt(Double(sum)))                             // 10042cb0..10042cb8
    }

    /// `FUN_10017cb0(e, now) @ 10017cb0` — spawn-set arming at state entry (spawn-and-waves §2.2,
    /// `10017cb0..10017e04`): +0xc3 = (the state's record count > 0); per set in list order: `Spawn_ID` `none` →
    /// {last = now, rate = 0, active = 0}, +0xc4 = 0; else **draw `10017d64`** rate = `R(RateMin, RateMax)`,
    /// last = now, **draw `10017d7c`** volley = `R(NumInVolleyMin, Max)`, active = rate ≥ 0 ∧ volley > 0,
    /// remaining = volley, **draw `10017dbc`** countdown = `R(DelayMin, DelayMax)`, +0xc4 =
    /// `TimeToPauseRotationAfterSpawning` (unconditional; the last set wins).
    mutating func armSpawnSets(_ i: Int, now: Int32) {
        let s = Int(world.entities[i].state)
        let records = world.entities[i].spawnRecords.indices.contains(s) ? world.entities[i].spawnRecords[s] : []
        world.entities[i].hasSpawnSets = !records.isEmpty                      // 10017ccc..10017d0c
        guard !records.isEmpty, let st = currentState(i) else { return }
        for k in records.indices {                                             // 10017d18..10017df0
            let set = st.spawnSets[k]
            var r = world.entities[i].spawnRecords[s][k]
            if set.stateSpawnSetSpawn == .none {                               // 10017d4c..10017d58
                r.lastArm = now; r.rate = 0; r.active = false                  // 10017dd4..10017de0
                world.entities[i].rotationPause = 0                            // 10017de4
            } else {
                r.rate = rng.range(set.stateSpawnSetRateMin, set.stateSpawnSetRateMax)      // 10017d5c..10017d6c
                r.lastArm = now                                                // 10017d70
                r.volley = rng.range(set.stateSpawnSetNumInVolleyMin, set.stateSpawnSetNumInVolleyMax)   // 10017d74..84
                r.active = r.rate >= 0 && r.volley > 0                         // 10017d88..10017da8
                r.remaining = r.volley                                         // 10017dac..10017db0
                r.countdown = rng.range(set.stateSpawnSetDelayBetweenEntitiesMin,
                                        set.stateSpawnSetDelayBetweenEntitiesMax)          // 10017db4..10017dc4
                world.entities[i].rotationPause = set.stateSpawnSetTimeToPauseRotationAfterSpawning   // 10017dc8..dcc
            }
            world.entities[i].spawnRecords[s][k] = r
        }
    }

    /// `FUN_10036ab0(&e+0x140)` — the owner link is valid: a pointer, the ids agree, the owner not deleted.
    func ownerLinkValid(_ i: Int) -> Bool {
        guard let o = world.entities[i].owner else { return false }            // 10036ab0..10036ab8
        return world.entities[i].ownerSerial == world.entities[o].serial       // 10036abc..10036acc
            && !world.entities[o].deleted                                      // 10036ad0..10036ad8
    }

    /// `FUN_10033600(e) @ 10033600` — the owner-relative initialisation (spawn-and-waves §4, `10033600..
    /// 10033844`): offset and owner-last = 0.0; when the current state has `OrbitOwner`, `LockToOwnerLoc` or
    /// `LinkToOwnerLoc`: owner position = the linked owner's (valid link), else the owning player's when in
    /// state 4 (`FUN_10006090`); none → done. owner-last = owner pos; Orbit → offset per axis (o < s ? s − o :
    /// −(o − s)), radius = float(trunc(`FUN_10042e90`(owner, self))), angle = internal(`FUN_10042ad0`(trunc
    /// owner, trunc self)); Lock → the same offset again.
    mutating func initOwnerRelation(_ i: Int) {
        var e = world.entities[i]
        e.ownerOffsetX = 0; e.ownerOffsetY = 0                                 // 10033628..1003362c
        e.ownerLastX = 0; e.ownerLastY = 0                                     // 10033630..10033634
        world.entities[i] = e
        guard let st = currentState(i), st.stateOrbitOwner || st.stateLockToOwnerLoc || st.stateLinkToOwnerLoc
        else { return }                                                        // 10033638..10033664
        var ox: Float = 0, oy: Float = 0
        if ownerLinkValid(i), let o = world.entities[i].owner {                // 10033668..10033690
            ox = world.entities[o].object.x; oy = world.entities[o].object.y
        } else {
            let p = Int(world.entities[i].ownerPlayer)                         // 10033694..100336b0
            guard p != -1, players.indices.contains(p), players[p].lifeState == 4 else { return }
            ox = players[p].object.x; oy = players[p].object.y
        }
        let sx = world.entities[i].object.x, sy = world.entities[i].object.y   // 100336d4 FUN_100128d0
        func offset(_ o: Float, _ s: Float) -> Float { o < s ? s - o : -(o - s) }
        world.entities[i].ownerLastX = ox; world.entities[i].ownerLastY = oy   // 100336bc..100336d0
        if st.stateOrbitOwner {                                                // 100336dc..100336e4
            world.entities[i].ownerOffsetX = offset(ox, sx)                    // 100336e8..1003370c
            world.entities[i].ownerOffsetY = offset(oy, sy)                    // 10033710..10033734
            let d = Trig.distance(x0: ox, y0: oy, x1: sx, y1: sy)              // 10033738..10033740
            world.entities[i].orbitRadius = Float(EntityDraw.fctiwz(d))        // 10033748..10033774
            let compass = Trig.headingTo(x: EntityDraw.fctiwz(ox), y: EntityDraw.fctiwz(oy),
                                         tx: EntityDraw.fctiwz(sx), ty: EntityDraw.fctiwz(sy))   // 10033778..100337c0
            world.entities[i].orbitAngle = Trig.internalHeading(compass)       // 100337c4..100337c8
        }
        if st.stateLockToOwnerLoc {                                            // 100337d0..10033828
            world.entities[i].ownerOffsetX = offset(ox, sx)
            world.entities[i].ownerOffsetY = offset(oy, sy)
        }
    }

    /// `FUN_100161c0(e) @ 100161c0` — the facing in compass degrees from the sprite frame: `numDirections == 1`
    /// → frame · (360 / framesPerDirection); else max(frame / framesPerDirection, 0) · (360 / numDirections)
    /// (C divisions). 0 without a current state (the original would read the zeroed unit header for +0xa8 = −1
    /// and divide by 0 — no caller reaches that: owners are always in a state); a zero divisor (the original's
    /// undefined `divw`) gives 0 here.
    func facing(of i: Int) -> Int32 {
        guard let st = currentState(i) else { return 0 }
        let n = st.stateNumDirections, fpd = st.stateFramesPerDirection
        let frame = world.entities[i].object.frame
        if n == 1 {                                                            // 100161dc..100161fc
            guard fpd != 0 else { return 0 }
            return frame &* (360 / fpd)
        }
        guard fpd != 0, n != 0 else { return 0 }
        var q = frame / fpd                                                    // 10016200..10016210
        if q < 0 { q = 0 }
        return q &* (360 / n)                                                  // 10016214..1001621c
    }

    /// `FUN_10016230(e, h) @ 10016230` — the frame for a compass heading (micro-wave §3.2): n =
    /// `numDirections` (≤ 0 → 1), step = 360 / n, q = fl32(float(h) / float(step)), k = trunc(q), q − k ≥ 0.5 →
    /// k + 1; k < 0 → n − 1; k > n − 1 → 0; × `framesPerDirection`.
    func frame(of i: Int, forHeading h: Int32) -> Int32 {
        guard let st = currentState(i) else { return 0 }
        var n = st.stateNumDirections                                          // 10016244..10016250
        if n <= 0 { n = 1 }
        let step = 360 / n                                                     // 10016254..1001625c
        let q: Float = Float(h) / Float(step)                                  // 10016268..10016298
        var k = EntityDraw.fctiwz(q)                                           // 1001629c..100162a4
        if q - Float(k) >= 0.5 { k &+= 1 }                                     // 100162a8..100162c8
        if k < 0 { k = n &- 1 }                                                // 100162cc..100162d8
        else if k > n &- 1 { k = 0 }                                           // 100162dc..100162e8
        return k &* st.stateFramesPerDirection                                 // 100162ec..100162f0
    }
}

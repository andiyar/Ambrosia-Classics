import Foundation
import HectorResources

/// Owner relations per tick (spawn-and-waves.md §4, loose-ends-combat.md §5.2, gameplay-leftovers.md §7.3; plan
/// C9). Listings read for C9: `FUN_10037130` (`10037130..1003722c`), `FUN_10037230` (`10037230..10037340`),
/// `FUN_10037350` (`10037350..1003757c`), `FUN_10036930` (`10036930..100369e0`), `FUN_10006090`
/// (`10006090..10006108`), and their call sites in `FUN_10033850` (`10033f10..10033f58`, `1003401c..10034054`).
/// The set-up `FUN_10033600` is C8's `initOwnerRelation`. No RNG draws.
extension GameState {
    /// The "owner position" of all three helpers (`10037148..100371c4` and the same block in each): the owner
    /// entity's position when the link is valid (`FUN_10036ab0` inline: a pointer, +0x144 == owner +0x9c, owner
    /// not deleted); else, when +0xd8 ≠ −1, the owning player's position if that player is in state 4
    /// (`FUN_10006090`: `FUN_10026c60(p, 4)` then `FUN_100128d0`); else none — the helper does nothing.
    func ownerPosition(_ i: Int) -> (x: Float, y: Float)? {
        if ownerLinkValid(i), let o = world.entities[i].owner {
            return (world.entities[o].object.x, world.entities[o].object.y)
        }
        let p = Int(world.entities[i].ownerPlayer)                             // 100371a4..100371b0 (extsb)
        guard p != -1, players.indices.contains(p), players[p].lifeState == 4 else { return nil }
        return (players[p].object.x, players[p].object.y)
    }

    /// `FUN_10037130(e) @ 10037130` — lock to the owner: when the owner position differs from the entity's
    /// (`fcmpu` x, then y), position = owner + offset (+0x124/+0x128, `fadds`, `100371fc..10037214`).
    mutating func lockToOwner(_ i: Int) {
        guard let o = ownerPosition(i) else { return }                         // 100371c4..100371c8
        let e = world.entities[i]
        guard o.x != e.object.x || o.y != e.object.y else { return }           // 100371dc..100371f8
        world.entities[i].object.x = o.x + e.ownerOffsetX                      // 1003720c
        world.entities[i].object.y = o.y + e.ownerOffsetY                      // 10037210
    }

    /// `FUN_10037230(e) @ 10037230` — link to the owner: d = ownerLast − ownerNow (`fsubs`), position −= d
    /// (`fsubs`), ownerLast (+0x12c/+0x130) = ownerNow (`100372d4..10037324`). No equality test.
    mutating func linkToOwner(_ i: Int) {
        guard let o = ownerPosition(i) else { return }                         // 100372cc..100372d0
        var e = world.entities[i]
        let dx: Float = e.ownerLastX - o.x                                     // 100372ec
        let dy: Float = e.ownerLastY - o.y                                     // 100372f0
        e.object.x = e.object.x - dx                                           // 10037308
        e.object.y = e.object.y - dy                                           // 1003730c
        e.ownerLastX = o.x; e.ownerLastY = o.y                                 // 10037318..10037324
        world.entities[i] = e
    }

    /// `FUN_10037350(e) @ 10037350` — orbit the owner: skipped when the owner position equals the entity's
    /// (`fcmpu`, `10037404..10037418`). Radius +0xdc == 0.0 (`*(double*)(0x100d7228 + 0x10)`) → position = owner +
    /// offset. Else step = `fctiwz(vx)` (degrees per tick; `FUN_10014650`'s result is unused); 0 → owner + offset;
    /// else +0xe0 += step, `> 359 → −360`, else `< 0 → +360` (one wrap), position = owner +
    /// `FUN_10042b80(+0xe0, radius)`. Then (all three paths) the offset is re-derived from the new position per
    /// axis: o < s ? s − o : −(o − s) (`1003751c..10037568`).
    mutating func orbitOwner(_ i: Int) {
        guard let o = ownerPosition(i) else { return }                         // 100373e4..100373e8
        var e = world.entities[i]
        guard o.x != e.object.x || o.y != e.object.y else { return }           // 100373fc..10037418
        let step = EntityDraw.fctiwz(e.object.vx)                              // 1003743c..10037448
        if e.orbitRadius == 0 || step == 0 {                                   // 10037420..1003742c, 1003744c..10037450
            e.object.x = o.x + e.ownerOffsetX                                  // 100374c4..100374e4 / 100374ec..10037504
            e.object.y = o.y + e.ownerOffsetY
        } else {
            e.orbitAngle &+= step                                              // 10037454..1003745c
            if e.orbitAngle > 359 { e.orbitAngle &-= 360 }                     // 10037460..10037470
            else if e.orbitAngle < 0 { e.orbitAngle &+= 360 }                  // 10037478..10037484
            let v = Trig.vector(heading: e.orbitAngle, speed: e.orbitRadius)   // 10037488..10037494
            e.object.x = o.x + v.x                                             // 100374b0
            e.object.y = o.y + v.y                                             // 100374b4
        }
        func offset(_ o: Float, _ s: Float) -> Float { o < s ? s - o : -(o - s) }
        e.ownerOffsetX = offset(o.x, e.object.x)                               // 1003751c..10037540
        e.ownerOffsetY = offset(o.y, e.object.y)                               // 10037544..10037568
        world.entities[i] = e
    }

    /// The per-tick owner block of `FUN_10033850` after a kept integration (`1003401c..10034054`): `LockToOwnerLoc`
    /// → lock, `LinkToOwnerLoc` → link, `OrbitOwner` → orbit, each gated on **the caller's state pointer r18** —
    /// the state read after the rules (`10033e00..10033e08`), i.e. before the motion controller: a range trigger
    /// that switched the state this tick does not change these gates until the next tick (C12 passes that state).
    public mutating func followOwner(_ i: Int, state st: UnitState) {
        if st.stateLockToOwnerLoc { lockToOwner(i) }                           // 1003401c..1003402c
        if st.stateLinkToOwnerLoc { linkToOwner(i) }                           // 10034030..10034040
        if st.stateOrbitOwner { orbitOwner(i) }                                // 10034044..10034054
    }

    /// The owner copies (`10033f10..10033f58` → `FUN_10036930(e, owner, vis, scale, hits) @ 10036930`), gated on
    /// any of the state's `useOwnersVisibility` (+0x327), `useOwnersScale` (+0x328), `visuallyReflectOwnerHits`
    /// (+0x32c) and a valid owner link (`FUN_10036ab0`; no player fallback). Visibility +0x68; scale: +0x34, then
    /// +0x84/+0x88/+0x8c, then `FUN_10012940` on the entity; hit glow: +0x74, +0x78, +0x75, +0x7c, +0x80.
    /// `state` is the caller's r18 (as `followOwner`).
    public mutating func copyFromOwner(_ i: Int, state st: UnitState) {
        guard st.useOwnersVisibility || st.useOwnersScale || st.visuallyReflectOwnerHits else { return }
        guard ownerLinkValid(i), let oi = world.entities[i].owner else { return }   // 10033f34..10033f40
        let o = world.entities[oi].object
        if st.useOwnersVisibility {                                            // 10036950..10036960
            world.entities[i].object.visibility = o.visibility
        }
        if st.useOwnersScale {                                                 // 10036964..10036990
            world.entities[i].object.sizeDirty = o.sizeDirty
            world.entities[i].object.scale = o.scale
            world.entities[i].object.scaleTarget = o.scaleTarget
            world.entities[i].object.scaleStep = o.scaleStep
            refreshEntitySize(i)
        }
        if st.visuallyReflectOwnerHits {                                       // 10036998..100369c4
            world.entities[i].object.hitGlowOn = o.hitGlowOn
            world.entities[i].object.hitGlowLevel = o.hitGlowLevel
            world.entities[i].object.hitGlowFalling = o.hitGlowFalling
            world.entities[i].object.hitGlowStep = o.hitGlowStep
            world.entities[i].object.hitGlowColour = o.hitGlowColour
        }
    }
}

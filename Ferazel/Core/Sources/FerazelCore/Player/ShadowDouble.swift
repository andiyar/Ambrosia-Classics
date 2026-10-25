import Foundation

/// The Shadow Double (sphere 1330; held-item-melee §2, spells-items §2 item 6 and §5): the sprite 0x1b39 row 11 of
/// `.HandlePlayerSprite` makes and removes (M l. 44674–44685), `.SetupShadowSprite @ 1004b7d4` (M l. 43167–43182),
/// `.HandleShadowSprite @ 1004b4f0` (M l. 43052–43166), `.ShadowBob @ 1004b410` (M l. 43008–43050) and the pose ring
/// `PTR_DAT_100a0520` row 42 writes (M l. 46535–46614). Its only game effect is `.CastSpell`'s 0-damage copies
/// (`CastSpell.shadowCopy`): its hot rect is never set (the cleared record's), so it collides with nothing. No routine
/// here draws `FastRand` (plan Invariant 4).
public enum ShadowDouble {
    /// The double's type (`MTNewSprite(0x1b39, …)`, M l. 44681).
    public static let spriteType: Int16 = 0x1b39
    /// `+0xb8 = 0x1000b` (`lis 1; addi 0xb`, raw `1004b728`).
    public static let tint: UInt32 = 0x1000b
    /// The bob table at `0x100a5fda` (24 shorts, the PEF data).
    static let bobTable: [Int16] = [0, 2, 4, 7, 8, 9, 10, 9, 8, 7, 4, 2, 0, -2, -4, -7, -8, -9, -10, -9, -8, -7, -4, -2]

    /// `.SetupShadowSprite` (M l. 43169–43182), inside `.MTNewSprite`: `.InitSprite` (the record's defaults), no hit
    /// callback (`+0x5c` 0), no tile callback (`+0x1f8` 0), the Handle `.HandleShadowSprite` (`PTR_PTR_100a0500`).
    static func setup(_ s: inout SpriteSlot) {
        s.hasHit = false
        s.hasTileHit = false
        s.handler = .shadow
    }

    /// Row 11 (M l. 44674–44685), after `.StandardSpriteHandles`, on last frame's flag (row 14 re-derives it later in
    /// the Handle): `0654` on and no double → `MTNewSprite(0x1b39, +0xc, +0xa, +0x80 − 1, −1, .SetupShadowSprite)` into
    /// `_DAT_100a0658` (nil when no record is free, Ruling 16 — tried again next frame); `0654` off with one → its
    /// `+0xe9 = 1` and `_DAT_100a0658 = 0`. The blink toggles of `.TickTock` thus remove the double and make a new one.
    static func row11(_ w: SpriteWorld, player id: Int) {
        guard let p = w.active.record(id: id) else { return }
        if w.player.shadowDouble {
            guard w.player.shadowDoubleSprite == nil else { return }
            w.player.shadowDoubleSprite = w.newSprite(type: spriteType, x: p.x, y: p.y,
                                                      layer: Int16(truncatingIfNeeded: p.layer - 1), handler: .shadow,
                                                      record: -1) { setup(&$0) }
        } else if let d = w.player.shadowDoubleSprite {
            w.active.update(id: d) { $0.killCount = 1 }
            w.player.shadowDoubleSprite = nil
        }
    }

    /// Row 42's ring write (M l. 46535–46614), after the riding ramps: while not standing still (`PTR_DAT_100a0674`
    /// 0) entries 1…13 move down to 0…12 (the `lwzu`/`stwu` copy loops) and entry 13 takes the player's (y, x)
    /// `+0xa`/`+0xc`, "grounded" (`+0xce ≠ 0 ∧ +0xdc == 0`), face `+0xc0` and mirror `+0x17e`; `0674 = 0` again.
    static func record(_ w: SpriteWorld, player id: Int) {
        guard !w.player.standingStill, let s = w.active.record(id: id) else { return }
        w.player.shadowRing.removeFirst()
        w.player.shadowRing.append(PlayerState.ShadowPose(
            y: Int16(truncatingIfNeeded: s.y), x: Int16(truncatingIfNeeded: s.x),
            grounded: s.groundKind != 0 && s.ridden == nil, face: s.face, mirrored: s.mirrored))
        w.player.standingStill = false
    }

    /// The bob decay outside `.ShadowBob`: one pixel per frame toward 0 (M l. 43083–43091 and the three copies).
    static func decay(_ p: inout PlayerState) {
        if 0 < p.shadowBob { p.shadowBob -= 1 } else if p.shadowBob < 0 { p.shadowBob += 1 }
    }

    /// `.ShadowBob` (M l. 43012–43050; raw `1004b410..1004b4d0`): not yet synced (`0608` 0) → the re-sync search — as
    /// shipped it compares the **same** `table[phase]` (a halfword index of `phase`, not `phase >> 1`) with the bob 24
    /// times, so the phase becomes 23·2 = 46 when |that − bob| < 2, else 0; synced → phase + 1, past 46 → 0. Then
    /// `0608 = 1` and bob = `table[phase >> 1]`.
    static func bob(_ p: inout PlayerState) {
        if !p.shadowBobSynced {
            let near: Bool
            if let v = resyncRead(p, Int(p.shadowBobPhase)) {
                let d = Int(v) - Int(p.shadowBob)
                near = (d < 0 ? -d : d) < 2
            } else {
                near = false
            }
            p.shadowBobPhase = near ? 0x2e : 0
        } else {
            p.shadowBobPhase += 1
            if 0x2e < p.shadowBobPhase { p.shadowBobPhase = 0 }
        }
        p.shadowBobSynced = true
        p.shadowBob = bobTable[Int(p.shadowBobPhase >> 1)]
    }

    /// The halfword the re-sync reads at `0x100a5fda + 2·phase` (phase 0…46): the table for 0…23; past it the PEF
    /// data the table runs into — 24…27 the max speeds `_DAT_100a600a/600c/600e/6010` (as the player globals hold
    /// them now), 28 the halfword 0 at `0x100a6012`; 29 and on lie in words that hold relocated addresses (the PEF's
    /// 0x0004d204, 0x0004d310, …) and are load-address dependent [LOW]: nil, taken as never within 2 of a bob of
    /// −10…10 (a high half is the address's segment, far above 11; a low half matching is a 1-in-13107 accident).
    static func resyncRead(_ p: PlayerState, _ phase: Int) -> Int16? {
        switch phase {
        case 0..<24: return bobTable[phase]
        case 24: return p.maxWalk
        case 25: return p.maxRun
        case 26: return p.airWalk
        case 27: return p.airRun
        case 28: return 0
        default: return nil
        }
    }

    /// `.HandleShadowSprite(s)` (M l. 43056–43166; raw `1004b4f0..1004b7d0`), with entry E = ring[`0590 >> 1`]:
    /// - `0654` off → face 0, return;
    /// - E's x == −1 → face 0; else, with the wand phase w `_DAT_100a06d4` and the wand-held count h `_DAT_100a06d0`:
    ///   - not casting (w < 1, or h > 3 and not standing still): crouching (`_DAT_100a071c` c ≠ 0) and E grounded →
    ///     bob decay, face 1011[c − 1]; else not still → bob decay, E's face; still and E airborne → `.ShadowBob`, E's
    ///     face; still and E grounded → face 1003[`0590 >> 1`], `0608 = 0`, bob decay;
    ///   - casting: s = w, but not still with h 2 → 2, h 3 → 1; E airborne → `.ShadowBob`, else bob decay; face
    ///     1014[s − 1];
    /// - then (y, x) = E's, the mirror E's, `+0xb8 = 0x1000b`, x += `_DAT_100a05bc >> 1`, y += the bob, `+0x88 = 0`.
    /// No `.StandardSpriteHandles` / `.StandardSpriteCleanup`: only the pixel position `+0xa`/`+0xc` is written.
    public static func handle(world w: SpriteWorld, id: Int) {
        guard w.active.record(id: id) != nil else { return }
        guard w.player.shadowDouble else {
            w.active.update(id: id) { $0.face = nil }
            return
        }
        var p = w.player
        let k = Int(p.rideRamp >> 1)
        // The index is 0…13 for every ramp value row 42 writes (0…0x1b).
        let e = p.shadowRing.indices.contains(k) ? p.shadowRing[k] : PlayerState.ShadowPose()
        var face: FaceRef?
        if e.x != -1 {
            let still = p.standingStill
            let wand = p.wandPhase
            let held = p.wandHeld
            if wand < 1 || (3 < held && !still) {
                let c = p.crouch
                if c == 0 || !e.grounded {
                    if !still {
                        decay(&p)
                        face = e.face
                    } else if !e.grounded {
                        bob(&p)
                        face = e.face
                    } else {
                        face = PlayerStates.face(PlayerStates.stand, k)
                        p.shadowBobSynced = false
                        decay(&p)
                    }
                } else {
                    decay(&p)
                    face = PlayerStates.face(PlayerStates.crouch, Int(c) - 1)
                }
            } else {
                var step = wand
                if !still {
                    if held == 2 { step = 2 } else if held == 3 { step = 1 }
                }
                if !e.grounded { bob(&p) } else { decay(&p) }
                face = PlayerStates.face(PlayerStates.cast, Int(step) - 1)
            }
        }
        let dx = p.rideRamp2 >> 1, dy = p.shadowBob
        w.player = p
        w.active.update(id: id) { s in
            s.face = face
            s.y = Int(e.y &+ dy)
            s.x = Int(e.x &+ dx)
            s.mirrored = e.mirrored
            s.mode = tint
            s.lightOverlay = false
        }
    }
}

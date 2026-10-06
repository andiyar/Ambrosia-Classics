import Foundation
import HectorResources

/// ◇ Phase-1 stub of the player update `FUN_10028170` (plan S2; player-physics.md §2). Listing reads
/// recorded for plan C4 (`disasm-review3-all.txt`):
///
/// - `FUN_1002a150` state 2 (`1002a1b4..1002a1e4`): `lwz r5,0x94; lwz r0,0xc8; lwz r5,0xb8(r5); add;
///   cmpw now; ble` → only when `now > enter + entry_InitialDelay` (55) `bl FUN_10029cc0`; otherwise
///   `FUN_10031710(+0xcc, pf[0] = 0.0)` (score-bar displayed shield ← 0). The whole step is skipped when
///   `+0xc4` is 0 (`1002a17c..1002a184`). State 4 (`1002a1e8..1002a23c`): the invulnerability expiry —
///   only with `+0xce` set, which Phase 1 never sets.
/// - `FUN_10029cc0` (`10029d00..10029e34`): if in game — `FUN_10029f10` (ship sprite, frame 0, `+0xd4` 0,
///   layer `play`), `FUN_10012940`, position solo (`+0x90/+0x94` when `+0xcd == 1`) or multi
///   (`+0x98/+0x9c`) via `FUN_10012930`, velocity (0, 0) from `0x100d6ec8`, `+0x20c` = 0, overload and
///   tint cleared inline (`10029dd0..10029dfc`, = `FUN_10026ea0`), `+0xc5` = 1, **state 4, enter = now**
///   (`10029e04`/`10029e08`), appear fade flli 163/164/165 (`10029e0c..10029e34`); then the `entry_Spawn_ID`
///   spawn (`plen`), `FUN_10029fe0` (multiplier unit) — not built in Phase 1 — and `FUN_1003af90(h, 0)`.
/// - `FUN_10012750` (`10012750..10012838`): see `GameObject.stepRamps` — agrees with the contract.
/// - Crosshair reset in `FUN_1003af90` (`1003b148..1003b15c`): `+0xf4` (crosshair +0x68) = 0.0, `+0xf8` =
///   100.0 (`*(r2−0x6e6c)` → `0x100d72b0` = {0.0, 100.0}), `+0xfc` = `+0x124` (flli 149 = 6).
/// - Crosshair step in `FUN_1003b3c0` (`1003b9ec..1003ba30`): `+0x120` = 1, face/frame ← ground weapon
///   `+0x168/+0x16c`, `+0x121` = 0, `+0xc4` (crosshair +0x38, draw shadow) = 0, `FUN_10012940` on `+0x8c`,
///   then `FUN_10012750` on `+0x8c` only when the face is not `none` (`1003ba18..1003ba2c`).
///
/// Order in `FUN_10028170` when in game (`10028f30..100298a8`): defence bonus (needs level complete — not
/// in Phase 1); `FUN_1002a150`; `FUN_1002a3a0` input; `FUN_10012840` scale ramp; `FUN_10026ee0` overload
/// (inactive: no-op); `FUN_10012750`; `+0xc5` clear; `FUN_10012940`; `FUN_10012c10` glow tick (glow off:
/// no-op); then state 4 only: handler tick `FUN_1003b3c0` (when scale `+0x84` == 1.0, `100290d0`), velocity,
/// banking, integrate, view shift, clamps, `FUN_1003bb00`, crosshair. **Stubbed (gate card):** velocity,
/// integration and clamps (the ship stays at its start point; with v = 0 the `fadds` of 0 is exact), and of
/// the handler tick everything but the crosshair part (no firing, power-up, select, overload).
extension Player {
    /// The banking jump tables (player-physics §2.4; image `r2+0x3074`, `+0x3058`, `+0x303c`): new frame
    /// for frame 0…6 with no left/right, left held, right held (not left).
    public static let bankingNone: [Int32] = [0, 0, 1, 2, 0, 4, 5]
    public static let bankingLeft: [Int32] = [1, 2, 3, 3, 3, 4, 5]
    public static let bankingRight: [Int32] = [4, 0, 1, 2, 5, 6, 6]

    /// One tick of the player, `FUN_10028170`'s Phase-1 subset (see the type's comment). `scoreBar`
    /// receives the life-state step's `FUN_10031710` call; `scroll` the view-shift calls `FUN_100100b0`.
    public mutating func updatePhase1(now: Int32, input source: PlayerInput, scroll: inout ScrollState,
                                      scoreBar: inout ScoreBarState) {
        guard inGame else { return }                                 // 10028f30..10028f38
        lifeStateStep(now: now, scoreBar: &scoreBar)                 // 10029048 FUN_1002a150
        if lifeState == 4 { input = source }                         // 1002905c FUN_1002a3a0 (state 4 only)
        object.stepScale()                                           // 10029068 FUN_10012840
        object.stepRamps()                                           // 10029080 FUN_10012750
        if appearing && object.visibility == object.visibilityTarget {   // 10029088..100290a8 (fcmpu)
            appearing = false
        }
        refreshSize()                                                // 100290b0 FUN_10012940
        guard lifeState == 4 else { return }                         // 100290c4..100290cc
        if object.scale == 1 { handlerCrosshairTick() }              // 100290d0..100290fc FUN_1003b3c0
        bankingStep(now: now)                                        // 10029360..100294dc
        if input.contains(.left) {                                   // 10029504..10029524
            scroll.shift(right: false)
        } else if input.contains(.right) {
            scroll.shift(right: true)
        }
        let bottomPinned = false                                     // 1002952c (set only by the clamp, 100296e0)
        handler.x = object.x; handler.y = object.y                   // 100296fc FUN_1003bb00
        crosshairStep(bottomPinned: bottomPinned)                    // 10029704..100298a0
    }

    /// `FUN_1002a150` — states 2 and 4 (1 and 3 are unreachable in Phase 1: no death, no game over).
    mutating func lifeStateStep(now: Int32, scoreBar: inout ScoreBarState) {
        switch lifeState {
        case 2:
            if now > stateEntered &+ definition.entryInitialDelay {  // 1002a1b4..1002a1c8
                respawn(now: now)                                    // 1002a1cc FUN_10029cc0
            } else {
                scoreBar.setShownShield(index: Int(index), 0)        // 1002a1d4..1002a1dc FUN_10031710
            }
        case 4:
            if invulnerable && now > stateEntered &+ definition.entryInvulnerabilityTime
                && inGame && !invulnerableSticky {                   // 1002a1e8..1002a23c (level complete: never)
                invulnerable = false
                invulnerableSticky = false
            }
        default:
            break
        }
    }

    /// `FUN_10029cc0 @ 10029cc0(player, now)` — become active (see the type's comment).
    mutating func respawn(now: Int32) {
        guard inGame else { return }                                 // 10029ce0..10029ce8
        resetShipSprite()                                            // 10029cec FUN_10029f10
        refreshSize()                                                // 10029cf8 FUN_10012940
        if playerCount == 1 {                                        // 10029d00..10029d50
            object.x = Float(definition.entrySoloStartX)
            object.y = Float(definition.entrySoloStartY)
        } else {                                                     // 10029d5c..10029da0
            object.x = Float(definition.entryMultiStartX)
            object.y = Float(definition.entryMultiStartY)
        }
        object.vx = 0; object.vy = 0                                 // 10029da8..10029dc4
        crosshairAdjust = 0                                          // 10029dd0
        clearOverload()                                              // 10029dd4..10029dfc
        appearing = true                                             // 10029e00
        setLifeState(4, now: now)                                    // 10029e04..10029e08
        setAppearFade()                                              // 10029e0c..10029e34
        // 10029e38..10029ee8: entry spawn (`plen`) and FUN_10029fe0 — entities are Phase 2.
        resetHandler(levelStart: false)                              // 10029ef4 FUN_1003af90(h, 0)
    }

    /// The crosshair part of `FUN_1003b3c0` (`1003b9ec..1003ba30`).
    mutating func handlerCrosshairTick() {
        handler.crosshairShown = true                                // 1003b9ec
        handler.crosshair.face = handler.ground.crosshairFace        // 1003b9f0..1003b9f8
        handler.crosshair.frame = handler.ground.crosshairFrame      // 1003b9fc..1003ba04
        handler.crosshairLocked = false                              // 1003ba08
        handler.crosshair.drawShadow = false                         // 1003ba0c (+0xc4 = +0x8c + 0x38)
        handler.crosshair.refreshSize(frameSize)                     // 1003ba10
        if handler.crosshair.face != .none {                         // 1003ba18..1003ba24
            handler.crosshair.stepRamps()                            // 1003ba2c
        }
    }

    /// Banking frame (player-physics §2.4): `k = int(flli 166)`; when `now > +0xd4 + k` → `+0xd4` = now and
    /// the frame steps by the left table (left held), else the right table (right held), else the none table.
    /// Frames above 6 are left alone (`cmplwi r0,0x6; bgt`).
    mutating func bankingStep(now: Int32) {
        let k = Int32(assets.floats[166])                            // 10029360..1002936c fctiwz
        guard now > lastBankingTick &+ k else { return }             // 10029370..10029384
        lastBankingTick = now                                        // 1002938c
        let table: [Int32]
        if input.contains(.left) { table = Self.bankingLeft }        // 10029404..10029428
        else if input.contains(.right) { table = Self.bankingRight } // 10029474..10029498
        else { table = Self.bankingNone }                            // 10029394..100293b8
        guard (0...6).contains(object.frame) else { return }
        object.frame = table[Int(object.frame)]
    }

    /// Crosshair position (player-physics §2.6, `10029704..100298a0`): only when handler `+0x120`. Adjust:
    /// down held and pinned at the bottom → `+= int(flli 185)`, capped at `int(flli 187)`; else if > 0 →
    /// `+= int(flli 186)`, floored at 0. cx = x + crosshairXOffset; cy = (y + crosshairYOffset) + adj (two
    /// `fadds`); ch = crosshair h′ / 2 (C division); `cy − ch < 0.0` → cy = ch; `FUN_10012910`.
    mutating func crosshairStep(bottomPinned: Bool) {
        guard handler.crosshairShown else { return }                 // 10029704..1002970c
        if input.contains(.down) && bottomPinned {                   // 10029710..1002971c
            crosshairAdjust &+= Int32(assets.floats[185])            // 10029720..10029744
            let cap = Int32(assets.floats[187])
            if crosshairAdjust > cap { crosshairAdjust = cap }       // 10029748..10029768
        } else if crosshairAdjust > 0 {                              // 10029770..10029778
            crosshairAdjust &+= Int32(assets.floats[186])            // 1002977c..1002979c
            if crosshairAdjust < 0 { crosshairAdjust = 0 }           // 100297a0..100297b0
        }
        let g = handler.ground
        let cx: Float = object.x + Float(g.crosshairXOffset)         // 100297b4..100297f4
        var cy: Float = object.y + Float(g.crosshairYOffset)         // 100297f8..10029814
        cy = cy + Float(crosshairAdjust)                             // 10029818..10029834
        let ch = handler.crosshair.scaledHeight / 2                  // 10029838..1002985c FUN_10012ba0
        if cy - Float(ch) < 0 { cy = Float(ch) }                     // 10029864..10029894
        handler.crosshair.x = cx                                     // 10029898..100298a0 FUN_10012910
        handler.crosshair.y = cy
    }
}

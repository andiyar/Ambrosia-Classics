import Foundation
import HectorResources

/// The player update `FUN_10028170 @ 10028170(player, gate, —, now, film, playback, levelEnd)` (player-physics.md
/// §2; plan C14). Called by the logic tick `FUN_10006b50` for P1 then P2 (`10006bf8..10006c28`) with the P1-active
/// gate byte (`r1+0x3b` of `FUN_100051a0` = `GameFlags.p1Active`), game time, the film object, G+0x20 (film
/// playing) and G+0x39 (level end reached).
///
/// Listing reads (`disasm-review3-all.txt`): the integrity check `100281a4..10028f2c` runs only when `+0x23c`
/// (registration) is set and draws nothing — not modelled. Then, when `+0xc4` (in game) is set (`10028f30`):
/// 1. defence bonus `10028f3c..10029034` (`PlayerScoring.payDefenceBonus`);
/// 2. `FUN_1002a150(p, now, gate)` life-state step `10029048` (`PlayerLife`);
/// 3. `FUN_1002a3a0(p, film, playback)` input `1002905c` — state 4 only: the 7 bytes cleared, then the film's next
///    byte (`FUN_100097a0`, playback) or the ISp read + the recorder `FUN_10009830` (`1002a414..1002a42c`: the
///    score at the write — the "Last Film" recorder is not modelled; the replay stores the score at the read);
/// 4. `FUN_10012840` scale ramp `10029068`; 5. `FUN_10026ee0` overload tick `10029078`; 6. `FUN_10012750` ramps
///    `10029080`; 7. `+0xc5` = 0 when `+0x68 == +0x6c` (`10029088..100290a8`, `fcmpu`); 8. `FUN_10012940`
///    `100290b0`, `FUN_10012c10` hit-glow tick `100290bc`;
/// 9. state 4 only (`100290c4`): handler tick `FUN_1003b3c0` only when `+0x84 == 1.0` (`100290d0..100290fc`),
///    the select flag → `FUN_10029f60` (`10029104..10029118`), return code 1 → overload start under the gate
///    state 4 ∧ ¬G+0x39 ∧ ¬`+0x210` (`10029140..1002919c`), 2 → overload cancelled (`100291a4..100291d8`);
///    velocity `100291dc..1002935c`; banking `10029360..100294dc`; integrate `100294e0..10029500`; view shift
///    `10029504..10029528`; clamps `1002952c..100296f0`; `FUN_1003bb00` `100296fc`; crosshair `10029704..100298a0`.
/// Nothing in the update draws from the RNG itself; its callees do (spawns, the overload sound).
extension GameState {
    /// One tick of player `i` (`FUN_10028170`), at game time `flags.gameTime`. `input` is the keys' `PlayerInput`
    /// (the ISp read), used only when no film is playing.
    public mutating func updatePlayer(_ i: Int, input keys: PlayerInput) {
        guard players[i].inGame else { return }                              // 10028f30..10028f38
        let now = flags.gameTime
        if flags.levelEnding && !players[i].hitThisLevel {                   // 10028f3c..10028f4c
            payDefenceBonus(i)                                               // 10028f50..10029034
        }
        playerLifeStateStep(i, now: now, gate: flags.p1Active)               // 10029048 FUN_1002a150
        readPlayerInput(i, keys: keys)                                       // 1002905c FUN_1002a3a0
        players[i].object.stepScale()                                        // 10029068 FUN_10012840
        overloadTick(i, now: now)                                            // 10029078 FUN_10026ee0
        players[i].object.stepRamps()                                        // 10029080 FUN_10012750
        if players[i].appearing
            && players[i].object.visibility == players[i].object.visibilityTarget {   // 10029088..100290a0
            players[i].appearing = false                                     // 100290a4..100290a8
        }
        players[i].refreshSize()                                             // 100290b0 FUN_10012940
        players[i].object.stepHitGlow()                                      // 100290bc FUN_10012c10
        guard players[i].lifeState == 4 else { return }                      // 100290c4..100290cc
        if players[i].object.scale == 1 {                                    // 100290d0..100290dc (pf[3])
            let code = tickWeapons(i, input: players[i].input)               // 100290e0..100290fc FUN_1003b3c0
            switch code {                                                    // 10029120..1002913c
            case 1:
                if players[i].lifeState == 4 && !flags.levelEnding && !players[i].overloadActive {   // 10029140..10029164
                    startOverload(i, now: now)                               // 10029168..1002919c
                }
            case 2:
                players[i].clearOverload()                                   // 100291a4..100291d8 (= FUN_10026ea0)
            default:
                break                                                        // 0, ≥ 3
            }
        }
        playerVelocityStep(i)                                                // 100291dc..1002935c
        playerBankingStep(i, now: now)                                       // 10029360..100294dc
        players[i].object.x = players[i].object.x + players[i].object.vx     // 100294e0..100294f0
        players[i].object.y = players[i].object.y + players[i].object.vy     // 100294f4..10029500
        if players[i].input.contains(.left) {                                // 10029504..10029514
            scroll.shift(right: false)
        } else if players[i].input.contains(.right) {                        // 10029518..10029524
            scroll.shift(right: true)
        }
        let pinned = clampPlayerToArea(i)                                    // 1002952c..100296f0
        players[i].handler.x = players[i].object.x                           // 100296fc FUN_1003bb00
        players[i].handler.y = players[i].object.y
        playerCrosshairStep(i, bottomPinned: pinned)                         // 10029704..100298a0
    }

    /// `FUN_1002a3a0 @ 1002a3a0(p, film, playback)` (`1002a3c4..1002a434`): state 4 only — the input bytes
    /// cleared (`FUN_1000cd90(+0x1fc, 7)`); playback (G+0x20 == 1) → `FUN_100097a0(film, +0xcc, +0x1fc)`: the
    /// byte at the cursor unpacked bit 0 left, 1 right, 2 up, 3 down, 4 fire ground, 5 fire air, 6 select
    /// (`100097cc..10009818`), and through `FilmCursor.next(player:score:)` the player's decoded score
    /// (`+0xb0 − 0x5532a3e`, the value the recorder stored at `1002a414..1002a42c`) is recorded at that read
    /// (plan G4.1); no read past the recording leaves the bytes cleared. Otherwise the keys (the ISp read).
    mutating func readPlayerInput(_ i: Int, keys: PlayerInput) {
        guard players[i].lifeState == 4 else { return }                      // 1002a3c4..1002a3cc
        players[i].input = []                                                // 1002a3d0..1002a3d8
        if flags.filmPlaying {                                               // 1002a3e0..1002a3e8
            let p = Int(players[i].index)
            guard film != nil, p == 0 || p == 1 else { return }
            let byte = film!.next(player: p, score: players[i].score)        // 1002a3f8 FUN_100097a0
            players[i].input = PlayerInput(rawValue: byte & 0x7f)
        } else {
            players[i].input = keys                                          // 1002a40c FUN_1004ab50
        }
    }

    /// Velocity (player-physics §2.1, `100291dc..1002935c`): step = plde `active_VelocityDelta` (+0xd8), cap =
    /// `+0xa4`; up → vy −= step, < −cap → −cap; down → vy += step, > cap → cap; left / right likewise on vx;
    /// neither left nor right → vx decays one step toward 0, snapping to 0.0; neither up nor down → vy likewise.
    /// Single precision (`fsubs`/`fadds`; the decay compares against the double 0.0 `pd[2]`).
    mutating func playerVelocityStep(_ i: Int) {
        let input = players[i].input
        let up = input.contains(.up), down = input.contains(.down)
        let left = input.contains(.left), right = input.contains(.right)
        let cap = players[i].maxSpeed                                        // 100291f4
        let step = players[i].definition.activeVelocityDelta                 // 100291f8
        var vx = players[i].object.vx, vy = players[i].object.vy
        if up {                                                              // 100291fc..1002921c
            vy = vy - step
            if vy < -cap { vy = -cap }
        }
        if down {                                                            // 10029220..10029240
            vy = vy + step
            if vy > cap { vy = cap }
        }
        if left {                                                            // 10029244..10029268
            vx = vx - step
            if vx < -cap { vx = -cap }
        }
        if right {                                                           // 1002926c..1002928c
            vx = vx + step
            if vx > cap { vx = cap }
        }
        if !left && !right {                                                 // 10029290..100292f4
            Self.decay(&vx, step)
        }
        if !up && !down {                                                    // 100292f8..1002935c
            Self.decay(&vy, step)
        }
        players[i].object.vx = vx
        players[i].object.vy = vy
    }

    /// One linear decay step toward 0 (`100292a0..100292f4`): > 0 → −step, < 0 → 0.0; then (re-read) < 0 →
    /// +step, > 0 → 0.0. The first snap is kept as the listing has it (`100292c4..100292c8`) though it is masked:
    /// when v − step < 0, the second block gives (v − step) + step ∈ [0, v] and snaps it to 0.0 anyway.
    static func decay(_ v: inout Float, _ step: Float) {
        if v > 0 {
            v = v - step
            if v < 0 { v = 0 }
        }
        if v < 0 {
            v = v + step
            if v > 0 { v = 0 }
        }
    }

    /// The banking jump tables (player-physics §2.4; image `r2+0x3074` / `+0x3058` / `+0x303c`, each case
    /// `li r0,N; stw r0,0x20(r31)` or the exit `100294e0` = unchanged; re-read from `mem/100de330.bin`): the new
    /// frame for frame 0…6 with no left/right, left held, right held (not left).
    static let bankNone: [Int32] = [0, 0, 1, 2, 0, 4, 5]
    static let bankLeft: [Int32] = [1, 2, 3, 3, 3, 4, 5]
    static let bankRight: [Int32] = [4, 0, 1, 2, 5, 6, 6]

    /// Banking frame (player-physics §2.4, `10029360..100294dc`): `k = trunc(flli 166)`; only when `now > +0xd4 + k`
    /// → `+0xd4` = now and the frame steps by the left table (left held), else the right table (right held), else
    /// the none table; frames outside 0…6 (unsigned `cmplwi 6; bgt`) are left alone.
    mutating func playerBankingStep(_ i: Int, now: Int32) {
        let k = EntityDraw.fctiwz(assets.floats[166])                        // 10029360..1002936c
        guard now > players[i].lastBankingTick &+ k else { return }          // 10029370..10029384
        players[i].lastBankingTick = now                                     // 1002938c
        let input = players[i].input
        let table = input.contains(.left) ? Self.bankLeft                    // 10029388 / 10029404
            : input.contains(.right) ? Self.bankRight : Self.bankNone        // 10029394 / 10029474
        let f = players[i].object.frame
        guard UInt32(bitPattern: f) <= 6 else { return }
        players[i].object.frame = table[Int(f)]
    }

    /// Clamp to the game area (player-physics §2.3, `1002952c..100296f0`): `W`/`H`/`T` = trunc(flli 54/55/183),
    /// `hw`/`hh` = `+0x2c`/`+0x30` (int → float exact). x − hw < −32.0 → x = hw − 32, vx = 0; else x + hw > W + 32
    /// → x = W − hw + 32, vx = 0. y − hh < T → y = T + hh, vy = 0; else y + hh > H → y = H − hh, vy = 0 and the
    /// ship is pinned at the bottom (`100296e0 li r15,1`, returned — the crosshair's flag).
    mutating func clampPlayerToArea(_ i: Int) -> Bool {
        let w = EntityDraw.fctiwz(assets.floats[54])                         // 10029530..10029548
        let h = EntityDraw.fctiwz(assets.floats[55])                         // 10029540..10029584
        var o = players[i].object
        let hw = o.halfWidth, hh = o.halfHeight
        var pinned = false
        if o.x - Float(hw) < -32 {                                           // 10029578..10029590 (pf[4])
            o.x = Float(hw &- 32); o.vx = 0                                  // 10029594..100295b4
        } else if o.x + Float(hw) > Float(w &+ 32) {                         // 100295bc..100295ec
            o.x = Float(w &- hw &+ 32); o.vx = 0                             // 100295f0..10029614
        }
        let t = EntityDraw.fctiwz(assets.floats[183])                        // 10029618..10029624
        if o.y - Float(hh) < Float(t) {                                      // 10029628..10029670
            o.y = Float(t &+ hh); o.vy = 0                                   // 10029674..10029694
        } else if o.y + Float(hh) > Float(h) {                               // 1002969c..100296c8
            o.y = Float(h &- hh); o.vy = 0                                   // 100296cc..100296f0
            pinned = true                                                    // 100296e0
        }
        players[i].object = o
        return pinned
    }

    /// Crosshair (player-physics §2.6, loose-ends-combat §6.3; `10029704..100298a0`): only with handler `+0x120`
    /// (player +0x360). Down held and pinned → adj += trunc(flli 185), capped at trunc(flli 187); else adj > 0 →
    /// adj += trunc(flli 186), floored at 0. cx = x + float(ground crosshairXOffset); cy = (y + float(yOffset)) +
    /// float(adj) (two `fadds`); ch = crosshair h′ / 2 (C division, `FUN_10012ba0`); cy − ch < 0.0 → cy = ch;
    /// `FUN_10012910` sets the crosshair position.
    mutating func playerCrosshairStep(_ i: Int, bottomPinned: Bool) {
        guard players[i].handler.crosshairShown else { return }              // 10029704..1002970c
        var adj = players[i].crosshairAdjust
        if players[i].input.contains(.down) && bottomPinned {                // 10029710..1002971c
            adj = adj &+ EntityDraw.fctiwz(assets.floats[185])               // 10029720..10029744
            let cap = EntityDraw.fctiwz(assets.floats[187])                  // 10029748..1002975c
            if adj > cap { adj = cap }                                       // 10029760..10029768
        } else if adj > 0 {                                                  // 10029770..10029778
            adj = adj &+ EntityDraw.fctiwz(assets.floats[186])               // 1002977c..1002979c
            if adj < 0 { adj = 0 }                                           // 100297a0..100297b0
        }
        players[i].crosshairAdjust = adj
        let g = players[i].handler.ground                                    // 100297b4 lwz r6,0x2b4(r31)
        let o = players[i].object
        let cx: Float = o.x + Float(g.crosshairXOffset)                      // 100297c4..100297f4
        var cy: Float = o.y + Float(g.crosshairYOffset)                      // 100297f8..10029814
        cy = cy + Float(adj)                                                 // 10029818..10029834
        let ch = players[i].handler.crosshair.scaledHeight / 2               // 10029838..1002985c
        if cy - Float(ch) < 0 { cy = Float(ch) }                             // 10029864..10029894
        players[i].handler.crosshair.x = cx                                  // 10029898..100298a0 FUN_10012910
        players[i].handler.crosshair.y = cy
    }
}

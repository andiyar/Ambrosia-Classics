import Foundation

/// `.HandleBreathing @ 1004bb44` (decompile l. 43314–43404; physics-sprites §8.8) — the panting cadence, called by
/// `.HandlePlayerSprite` row 30 (l. 45140) every frame, and `.ShouldEmitBubbles @ 1004ba14` (l. 43260–43277).
public enum Breathing {
    /// `.ShouldEmitBubbles(s)`: not while dying (`_DAT_100a069c > 0`); else `0 < +0x120 < 0xf`.
    public static func shouldEmitBubbles(world w: SpriteWorld, id: Int) -> Bool {
        if 0 < w.player.dying { return false }
        guard let s = w.active.record(id: id) else { return false }
        return 0 < s.lastWater && s.lastWater < 0xf
    }

    /// `.HandleBreathing(s)`, only while not dying (`_DAT_100a069c < 1`):
    /// - exertion E (`_DAT_100a06a4`) −2 while > 0;
    /// - oxygen `G+6` < health `G+4`: f = (1.0 − (f32)`G+4`)·400.0 (f32 constants `0x100a1a48` / `0x100a1a44`); when
    ///   (f32)E + f < 220.0 (`0x100a1a40`), E = (i16)fctiwz((f32)E + f) — as written f ≤ 0 for any health ≥ 1, so E is
    ///   driven negative and wraps (physics-sprites §8.8, LOW intent);
    /// - E capped at 600; level L = clamp((min(E, 600) − 100) >> 6, 2, 6) (srawi);
    /// - the period counter `_DAT_100a06b0` −1; at < 1 it reloads with 9 − L and, unless (chest `PTR_DAT_100a04fc`
    ///   == 1 ∧ E < 0xa0 ∧ last phase `_DAT_100a06a8` ≥ 2), the breath phase `sRam100a5f5e` advances — so with
    ///   E < 0xa0 the calm cycle **holds at chest frame 1** (phase 5) once it gets there (l. 43367; Bank correction
    ///   A11); at phase 2: bubbling with oxygen → `.EmitBubble` (P4); else oxygen > 0 → the breath sound
    ///   (408 `_DAT_100a0400` when 9 − L < 4, else 409 `_DAT_100a03fc`; prio 1, vol 0x37);
    /// - the phase wraps after 5; chest = phase, 6 − phase above 3 (2 while bubbling); last phase = phase.
    public static func handle(world w: SpriteWorld, id: Int) {
        guard w.player.dying < 1 else { return }
        if 0 < w.player.exertion { w.player.exertion -= 2 }
        let health = w.globals.health, oxygen = w.globals.breath
        if oxygen < health {
            let f: Float = (Float(1.0) - Float(health)) * Float(400.0)
            let sum: Float = Float(w.player.exertion) + f
            if sum < Float(220.0) {
                w.player.exertion = Int16(truncatingIfNeeded: TileSolver.fctiwz(Double(sum)))
            }
        }
        if 600 < w.player.exertion { w.player.exertion = 600 }
        let e = min(w.player.exertion, 600)
        var level = Int16(truncatingIfNeeded: (Int32(e) - 100) >> 6)
        if level < 2 { level = 2 } else if 6 < level { level = 6 }
        w.player.breathPeriod &-= 1
        if w.player.breathPeriod < 1 {
            w.player.breathPeriod = 9 - level
            if w.player.chestFrame != 1 || 0x9f < e || w.player.lastBreathPhase < 2 {
                w.player.breathPhase &+= 1
                if w.player.breathPhase == 2 {
                    if !shouldEmitBubbles(world: w, id: id) || oxygen < 1 {
                        if 0 < oxygen {
                            let snd: Int16 = 9 - level < 4 ? 408 : 409          // `_DAT_100a0400` / `_DAT_100a03fc`
                            w.player.cue(PlayerCue(call: .reg, snd: snd, priority: 1, volume: 0x37))
                        }
                    } else {
                        PlayerLiquids.emitBubble(w, id: id)                // `.EmitBubble @ 1004ba74` (P4)
                    }
                }
            }
        }
        if 5 < w.player.breathPhase { w.player.breathPhase = 0 }
        if !shouldEmitBubbles(world: w, id: id) {
            w.player.chestFrame = w.player.breathPhase
            if 3 < w.player.chestFrame { w.player.chestFrame = 6 - w.player.chestFrame }
        } else {
            w.player.chestFrame = 2
        }
        w.player.lastBreathPhase = w.player.breathPhase
    }
}

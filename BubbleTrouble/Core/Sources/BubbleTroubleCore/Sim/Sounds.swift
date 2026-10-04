// Sound cues from the simulation (plan 2026-10-04 btx-playable C2; Invariant 2: transcribe at the original's call
// site, in order; Invariant 3: no RNG draw added or moved), transcribed from `_PlayMySnd @ 00026a7b`,
// `_Sounds_CheckDelayedSounds @ 000268a1` and `_Sounds_InitDelayedSounds @ 00026888`.
//
// `_PlayMySnd(slot, priority, delay)`: `delay != 0` → the first free entry of the 5-entry `_delayedSound` queue
// (slot −1 = free) takes (slot, `delay + gFrameCounter`, priority) and nothing plays now; no free entry (or delay 0)
// → `ST_PlaySound(gSound[slot], priority, volume)` at once. `_Sounds_CheckDelayedSounds` (called once per frame by
// `_PlayGame` between `_TimeBonus_Process` and `_EraseNotice`/the draw pass) walks entries 0…4: occupied and
// `(ushort)fireAt <= (ushort)gFrameCounter` → freed, then played only when slot < 0x30. The SFX-volume pref (short
// 0x33: 1 off, 2 → 0x10, 3 → 0x40, 4 → 0x100) only gates `ST_PlaySound`; queueing is unconditional — the App
// applies the volume, the core always emits.
//
// `FrameReport.sounds` lists this frame's `ST_PlaySound` calls in call order: every cue in it plays NOW.
// `SoundCue.delayFrames` is the `delay` argument the originating `_PlayMySnd` call passed (provenance only: a cue
// with delayFrames > 0 either waited that long in the queue or found the queue full and played at once).
//
// Every `_PlayMySnd` call site reachable from the `_PlayGame` frame body (151 call sites in the binary: 149 `call`s +
// 2 tail `jmp`s; listed as slot, priority, delay; `fn @ addr` = function entry, then the call addresses):
//
//   _PlayGame @ 00018247 (FrameStep.swift)
//     000188ef  8, 20, 0   hero appears (state 1 → 2), not demo
//     0001890b  27, 10, 0  hero appears, every mode
//     0001898d  34, 20, 0  state 3 → 4 (death groan), every mode
//     00018a74  3, 30, 0   state 4 → 1 respawn with lives < 1 (with notice 2)
//     00018a3e  2, 20, 0   state 4 → 1 respawn with lives ≥ 1 and not end of level (with notice 1)
//     00018af5  33, 20, 0  last normal bubble gone (before the +2000)
//     00018d19  35, 30, 0  all enemies squished (gIsEndOfLevel set), not demo
//   _TimeBonus_Process @ 00006a15 (TimeBonus.swift)
//     00006a95 30, 20, 0 + 00006ab1 23, 20, 0   bonus reaches exactly 0 (Hurry Up! / No Bonus Points)
//     00006aee 21, 20, 0                         bonus −50 while < 500
//   _Multiplier_Process @ 00019dae (Bonus.swift)  00019e5d 32, 30, 0 — flash-on steps (bit in 0x155, counter < 9)
//   _Bonus_Process @ 0001a92b (Bonus.swift)
//     0001aa77 19, 10, 5   frame == launch frame (harp)
//     0001aad9 6, 10, 0    flying bonus leaves the top; 0001ac1c 6, 10, 0 popped bonus leaves the top
//   _Bonus_Pop @ 0001a6fd (Bonus.swift)  0001a71e 6, 10, 0 + 0001a73a 26, 20, 0 — before anything else
//   _Bonus_Reward @ 0001a2c5 (Bonus.swift), by type: 1 → 15,10; 2 → 31,20 + 4,20 + 15,10; 4 → 31,20 + 4,20;
//     5…8 → 44,20; 9…13 → 31,20; 14 → 26,20 then (5000 / 10000 only) 40, 20, 5 — 18 sites 0001a302…0001a6aa
//   _PopEnemy @ 00011254 (EnemyMutations.swift)  0001129c 0, 10, 0
//   _SquishEnemy @ 0001131b (EnemyMutations.swift)  0001139d 0, 10, 0; 00011541 38, 10, 15 (n == 3 only)
//   _Balloons_PopBalloon @ 00023a84 (EnemyMutations.swift)  00023add 16, 10, 0
//   _CheckForBombKills @ 000116eb (Dynamite.swift)  000117ba 43, 10, 5 (blast catches the hero, before _HeroCaught)
//   _ExplodeBombBlock @ 0001c032 (Dynamite.swift)  0001c0a4 25, 20, 0
//   _HeroCaught @ 00021dfa (Catch.swift)
//     00021e80 kind 1: GetRandomFast(0,1) == 0 ? 37 : 10, 20, 0 (the draw the core already makes)
//     00021ea1 kind 2: 0, 20, 0; 00021eef then GetRandomFast(0,1) == 0 ? 45 : 11, 20, 5
//   _HeroPushCrushCheck @ 000220d8 (Hero.swift)  00022367 7, 10, 0 (jewel thud); 00022285 7, 10, 0 (wall / cluster)
//   _PushBlock @ 0001bd62 (BlockCreation.swift)  0001be36 tail jmp: 5, 10, 0
//   _CrushBlock @ 0001bc14 (BlockCreation.swift)  0001bcda 6, 10, 0
//   _KillEggBlock @ 0001be3b (BlockCreation.swift)  0001bf19 6, 20, 0 + 0001bf35 0, 20, 0
//   _ActivateBombBlock @ 0001c1c4 (BlockCreation.swift)  0001c286 24, 10, 0 (no lit block → new fuse)
//   _CheckJewelMovement @ 0001ca05 (Jewels.swift)  0001cae8 / 0001cbf6 9, 20, 0 (partial join, after the stars)
//   _Jewels_GiveBonus @ 0001c7c5 (Jewels.swift)  0001c876 33, 20, 0 (before _AddToScore)
//   _MoveBlock @ 0001cccb (MoveBlock.swift)  0001d07e / 0001d103 / 0001d16a / 0001d211 20, 10, 0 at bounce step 3
//     (up / down / left / right); 0001d002 20, 10, 0 at step 4 for up / down / left only — the right-moving block's
//     step-4 reversal (0001d221) jumps past it: no sound, replicated.
//   _ProcessBlocks @ 0001d2b8 (ProcessBlocks.swift)  0001d4c4 16, 10, 0 (egg → pop); 0001d6b9 20, 10, 0 (block pair)
//   _AddHero @ 00022d62 (Scoring.swift)  00022dab + 00022dc7 13, 20, 0 (twice)
//   _Balloons_New @ 000237f9 (Balloons.swift)  00023a63 14, 10, 0
//   _Balloons_CaptureHero @ 00023cbb (Balloons.swift)  00023cf6 15, 10, 0 + 00023d12 39, 10, 5
//   _Balloons_CheckBalloonEnemyHit @ 00023f90 (Balloons.swift)  00024068 15, 10, 0
//   _Balloons_CaptureAllEnemies @ 000240dd (Balloons.swift)  00024253 15, 10, 0 — normal end only (the
//     `29 < numActive` early return plays nothing)
//   _Bubbles_NewGroup @ 0001657e (AirBubblePool.swift)  000166bc tail jmp, args set per group: 4, 5, 6, 9, 10 →
//     28, 1, 0; 7 → 29, 1, 0 (0001676a); 8 → 27, 1, 0 (0001681d → 000169ce); 0xb → 27, 10, 0; 0…3 and ≥ 0xc → none
//
// NOT here (outside the frame body; the session task C4 owns them): `_NewLevel @ 0001735f` 00017658 (2, 20, 0, not
// demo); `_PlayGame` 00018dc9 (27, 30, 0 after `_TimeBonus_CountDown`) and 00019304 (27, 30, 0 on game exit);
// `_TimeBonus_CountDown @ 00006dcb` (00006e16, 00006e8c, 00006f07); `_Multiplier_Flash @ 00019d23` 00019d90 (called
// only by the countdown); `_PauseGame @ 0001767b` (30 sites); `_ResumeGame @ 0000a28e` 0000a32d. The rest are front
// end / dialogs (C6/C7/A4).

/// One `_delayedSound` entry (6 bytes in the original: slot, fire frame, priority — all `short`).
public struct DelayedSound: Equatable, Sendable {
    /// −1 (0xffff) = free.
    public internal(set) var slot: Int16 = -1
    /// `delay + gFrameCounter` at the `_PlayMySnd` call (16-bit, wraps).
    public internal(set) var fireAt: UInt16 = 0
    public internal(set) var priority: Int16 = 0
    /// The `delay` the call passed — kept for the cue's provenance (`SoundCue.delayFrames`).
    public internal(set) var delay: Int16 = 0

    public var isFree: Bool { slot == -1 }
}

extension GameState {
    /// `_delayedSound` holds 5 entries (`_Sounds_InitDelayedSounds` walks to `_gShowWhichNotice`, 30 bytes on).
    public static let delayedSoundCapacity = 5

    /// `_PlayMySnd(slot, priority, delay) @ 00026a7b`.
    mutating func playMySnd(_ slot: Int, priority: Int, delay: Int = 0) {
        let d = Int16(truncatingIfNeeded: delay)
        if d != 0 {
            if let i = delayedSounds.firstIndex(where: { $0.isFree }) {
                delayedSounds[i].slot = Int16(truncatingIfNeeded: slot)
                delayedSounds[i].fireAt = UInt16(bitPattern: d) &+ frame
                delayedSounds[i].priority = Int16(truncatingIfNeeded: priority)
                delayedSounds[i].delay = d
                return
            }
            // All five busy: falls through and plays at once.
        }
        soundsThisFrame.append(SoundCue(slot: slot, priority: priority, delayFrames: delay))
    }

    /// `_Sounds_CheckDelayedSounds @ 000268a1`: entries 0…4 in order; occupied and `fireAt <= frame` (unsigned
    /// 16-bit) → freed, and played when the slot is < 0x30.
    mutating func soundsCheckDelayedSounds() {
        let now = frame
        for i in delayedSounds.indices {
            let entry = delayedSounds[i]
            guard !entry.isFree, entry.fireAt <= now else { continue }
            delayedSounds[i] = DelayedSound()
            if UInt16(bitPattern: entry.slot) < 0x30 {
                soundsThisFrame.append(SoundCue(slot: Int(entry.slot), priority: Int(entry.priority),
                                                delayFrames: Int(entry.delay)))
            }
        }
    }

    /// `_Sounds_InitDelayedSounds @ 00026888` (`_NewLevel` only): every entry free.
    mutating func soundsInitDelayedSounds() {
        delayedSounds = Array(repeating: DelayedSound(), count: Self.delayedSoundCapacity)
    }
}

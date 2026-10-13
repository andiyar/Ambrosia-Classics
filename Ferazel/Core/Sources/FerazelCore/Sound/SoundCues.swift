import Foundation

/// The Sound Tool's cue arithmetic (S1; decompile l. 40605–41010; sprites-backgrounds-sounds §6.3): what each `STPlay*`
/// entry hands the play list `FUN_10091208`, as a `SoundCue`. Volume and stereo arithmetic and conversion only — no
/// `FastRand` (plan Invariant 4: `.STPlay3DSoundRand`'s `FastRand(10000)` is drawn at its call site, sound on or off,
/// and rides the `PlayerCue`).
///
/// - global volume `iRam100a510c` = prefs+0xe · 0x1c (l. 7248; 7 → 196); every entry scales the call's volume as
///   `(uint)(vol · global) >> 8`;
/// - every entry returns at once with sound off (prefs+0xb == 0) or a nil snd handle (`SoundSlots`);
/// - `.STPlayRegSound @ 10047580`: both sides ((vol · global) >> 8 as u16) >> 1, rate 0x10000;
/// - `.STPlayRegSoundPitched @ 10047c98`: both sides (vol · global) >> 8, not halved, the caller's rate;
/// - `.STPlay3DSound @ 10047ac0`: `.CalcStereoVolume` then each side >> 1, rate 0x10000;
/// - `.STPlay3DSoundPitched @ 10047b8c`: position (0, 0) → 0x80/0x80, else `.CalcStereoVolume`, not halved; dropped
///   (returns 0) when L + R < 0x14; the caller's rate;
/// - `.STPlay3DSoundRand @ 10047d44`: Pitched with rate `FastRand(10000) + 0xec77` (the `PlayerCue`'s rate).
/// Stops `FUN_10091504(snd)` and stop-if-playing `if (FUN_100916dc(snd)) FUN_10091504(snd)` are the same call to the
/// mixer (stopping a sound no voice plays does nothing) → `FrameOps.soundStops`; neither is gated by sound on.
public enum SoundCues {
    /// One converted call.
    public enum Output: Equatable, Sendable {
        case play(SoundCue)
        case stop(Int16)
    }

    /// `iRam100a510c = *(short *)(prefs + 0xe) * 0x1c`.
    public static func globalVolume(_ prefs: FerazelPrefs) -> Int32 { Int32(prefs.soundVolume) &* 0x1c }

    /// `(uint)(vol · global) >> 8` (logical shift of the 32-bit product).
    static func scaled(_ volume: Int16, _ global: Int32) -> UInt32 {
        UInt32(bitPattern: Int32(volume) &* global) >> 8
    }

    /// `.STPlayRegSound(snd, prio, vol)`.
    public static func regSound(snd: Int16, priority: Int, volume: Int16, global: Int32) -> SoundCue {
        let side = Int(UInt16(truncatingIfNeeded: scaled(volume, global)) >> 1)
        return SoundCue(snd: snd, priority: priority, left: side, right: side, rate: 0x10000)
    }

    /// `.STPlayRegSoundPitched(snd, prio, vol, rate)`.
    public static func regSoundPitched(snd: Int16, priority: Int, volume: Int16, rate: UInt32, global: Int32) -> SoundCue {
        let side = Int(Int16(truncatingIfNeeded: scaled(volume, global)))
        return SoundCue(snd: snd, priority: priority, left: side, right: side, rate: rate)
    }

    /// `.STPlay3DSound(snd, prio, vol, pos)`.
    public static func play3D(snd: Int16, priority: Int, volume: Int16, position: SpriteSlot.Point, scrollH: Int,
                              scrollV: Int, global: Int32) -> SoundCue {
        let (l, r) = StereoVolume.calc(volume: Int16(truncatingIfNeeded: scaled(volume, global)), position: position,
                                       scrollH: scrollH, scrollV: scrollV)
        return SoundCue(snd: snd, priority: priority, left: Int(l >> 1), right: Int(r >> 1), rate: 0x10000)
    }

    /// `.STPlay3DSoundPitched(snd, prio, vol, pos, rate)` (and `.STPlay3DSoundRand` with its drawn rate); nil = dropped.
    public static func play3DPitched(snd: Int16, priority: Int, volume: Int16, position: SpriteSlot.Point, rate: UInt32,
                                     scrollH: Int, scrollV: Int, global: Int32) -> SoundCue? {
        var l: Int16 = 0x80, r: Int16 = 0x80
        if Int16(truncatingIfNeeded: position.x) != 0 || Int16(truncatingIfNeeded: position.y) != 0 {
            (l, r) = StereoVolume.calc(volume: Int16(truncatingIfNeeded: scaled(volume, global)), position: position,
                                       scrollH: scrollH, scrollV: scrollV)
        }
        // `(uint)local_28 + (uint)local_26 < 0x14` (u16 halves).
        guard Int(UInt16(bitPattern: l)) + Int(UInt16(bitPattern: r)) >= 0x14 else { return nil }
        return SoundCue(snd: snd, priority: priority, left: Int(l), right: Int(r), rate: rate)
    }

    /// One call as the Sound Tool takes it; nil when it plays nothing.
    public static func convert(_ call: PlayerState.SoundCall, prefs: FerazelPrefs) -> Output? {
        let c = call.cue
        switch c.call {
        case .stop, .stopIfPlaying:
            return .stop(c.snd)
        case .reg, .regPitched, .threeD, .threeDPitched, .threeDRand:
            break
        }
        guard prefs.soundOn != 0, SoundSlots.isLoaded(c.snd) else { return nil }
        let g = globalVolume(prefs)
        let prio = Int(c.priority)
        let pos = c.position ?? SpriteSlot.Point()
        let rate = c.rate.map { UInt32(bitPattern: $0) } ?? 0x10000
        var cue: SoundCue?
        switch c.call {
        case .reg:
            cue = regSound(snd: c.snd, priority: prio, volume: c.volume, global: g)
        case .regPitched:
            cue = regSoundPitched(snd: c.snd, priority: prio, volume: c.volume, rate: rate, global: g)
        case .threeD:
            cue = play3D(snd: c.snd, priority: prio, volume: c.volume, position: pos, scrollH: call.scrollH,
                         scrollV: call.scrollV, global: g)
        case .threeDPitched, .threeDRand:
            cue = play3DPitched(snd: c.snd, priority: prio, volume: c.volume, position: pos, rate: rate,
                                scrollH: call.scrollH, scrollV: call.scrollV, global: g)
        case .stop, .stopIfPlaying:
            break
        }
        cue?.onlyIfIdle = c.onlyIfIdle
        return cue.map { .play($0) }
    }

    /// The iteration's calls, in call order, into `ops.sounds` / `ops.soundStops`, each stop with its place among the
    /// plays (`ops.soundStopAt`; the mixer takes plays and stops in call order, l. 78217–78310 — no play is dropped).
    public static func emit(_ calls: [PlayerState.SoundCall], prefs: FerazelPrefs, into ops: inout FrameOps) {
        for call in calls {
            switch convert(call, prefs: prefs) {
            case .play(let cue)?:
                ops.sounds.append(cue)
            case .stop(let snd)?:
                ops.stopSound(snd)
            case nil:
                break
            }
        }
    }
}

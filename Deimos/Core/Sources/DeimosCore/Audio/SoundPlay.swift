import Foundation

/// The two sound-play entry points that build a `SoundCue` (sound-music §2.3). The mixer's own checks — sound
/// on, `none`, AllowOnlyOneInstance, the `min(P, 100)` priority clamp of `FUN_10047bf0` — are DeimosAudio's (A1).
/// ★ LOCKED (plan S2).
public enum SoundPlay {
    /// `FUN_100475e0` (`10047600–1004764c`) over a 0x18 sound record (+0 id, +4 MinVol, +8 MaxVol, +0xc
    /// Priority, +0x10/+0x14 Min/MaxPitch): id `none` → no draw, no cue (`10047604..1004760c`); pitch =
    /// `RandomRange(minPitch, maxPitch)` (`10047618`, the only draw); volume = `RandomRange(MinVol, MinVol)`
    /// (`10047620..1004762c`: r3 = r4 = +4 — MaxVol is never read, no draw); priority = `Priority & 0xFF`
    /// (`10047644`).
    public static func record(_ sound: SoundRecord, allowMultiple: Bool, rng: inout MSLRandom) -> SoundCue? {
        guard sound.id != .none else { return nil }
        let pitch = rng.range(sound.minPitch, sound.maxPitch)
        let volume = rng.range(sound.minVolume, sound.minVolume)
        return SoundCue(id: sound.id, priority: sound.priority & 0xFF, volume: volume, pitch: pitch,
                        allowMultiple: allowMultiple)
    }

    /// `FUN_10047670`: the caller's id, priority and volume, pitch = `*(*(r2 − 0x6dbc))` = 1.0 (`0x100d7414`);
    /// no draw. `none` is passed through (the mixer drops it, `10047c18`).
    public static func perm(_ id: FourCC, priority: Int32, volume: Int32, allowMultiple: Bool) -> SoundCue {
        SoundCue(id: id, priority: priority, volume: volume, pitch: 1.0, allowMultiple: allowMultiple)
    }
}

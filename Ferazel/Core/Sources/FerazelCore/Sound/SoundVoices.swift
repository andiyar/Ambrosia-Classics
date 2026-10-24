import Foundation

/// VS (plan S2, Ruling 5): the answer to `FUN_100916dc(snd)` (M l. 78378 — the Sound Tool's count of list entries
/// playing `snd`'s handle; `param_1 == 0`, a nil handle, counts every entry) at an idle-only call site
/// (`if (!FUN_100916dc(snd)) .STPlay3DSoundRand(…)`, e.g. the gate 2940, M l. 61047/61056): the decision is Core's, so
/// the call's `FastRand(10000)` is drawn exactly when the original draws it (Invariant 4).
///
/// The set is the shell's playing set at the iteration's start (`FrontInput.playing`, from FerazelRender's
/// `SoundTool.playingSounds()`) with the calls made since applied in call order (the `FrameOps.soundStopAt`
/// interleave): a play that the Sound Tool takes (`SoundCues.convert` → `.play`) adds its snd, a stop
/// (`FUN_10091504(snd)`) removes it. Known deviation 2: a sound that ends inside the iteration counts until the next
/// tick; a play evicting another entry (all 16 busy) is not modelled. A play the Sound Tool turns away (all 16 entries
/// outrank it: `FUN_10091208` takes no entry and returns 0, M l. 78265/78312) counts here until the next tick's shell set.
public struct SoundVoices: Equatable, Sendable {
    /// The `snd ` ids some entry plays at the iteration's start (the shell's set, plus — on a tick that runs more than
    /// one part — what the tick's earlier parts started and stopped).
    public var playing: Set<Int16>
    /// The live prefs the iteration's calls are converted under (sound off: no play takes an entry).
    public var prefs: FerazelPrefs

    public init(playing: Set<Int16> = [], prefs: FerazelPrefs = FerazelPrefs()) {
        self.playing = playing
        self.prefs = prefs
    }

    /// `FUN_100916dc(snd) != 0` after `calls` (the iteration's sound calls so far, in call order).
    public func isPlaying(_ snd: Int16, after calls: [PlayerState.SoundCall] = []) -> Bool {
        var set = playing
        for call in calls {
            switch SoundCues.convert(call, prefs: prefs) {
            case .play(let cue)?: set.insert(cue.snd)
            case .stop(let s)?: Self.stop(s, in: &set)
            case nil: break
            }
        }
        return SoundSlots.isLoaded(snd) ? set.contains(snd) : !set.isEmpty
    }

    /// This set with emitted plays and stops applied in the `soundStopAt` order (stop k before play `stopAt[k]`).
    public func applying(sounds: [SoundCue], stops: [Int16], stopAt: [Int]) -> SoundVoices {
        var v = self
        v.playing = Self.playing(playing, applying: sounds, stops: stops, stopAt: stopAt)
        return v
    }

    /// `set` with emitted plays and stops applied in the `soundStopAt` order (no prefs: the ops are already converted).
    public static func playing(_ base: Set<Int16>, applying sounds: [SoundCue], stops: [Int16],
                               stopAt: [Int]) -> Set<Int16> {
        var set = base
        var k = 0
        for i in 0...sounds.count {
            while k < stops.count, (k < stopAt.count ? stopAt[k] : sounds.count) <= i {
                Self.stop(stops[k], in: &set)
                k += 1
            }
            guard i < sounds.count else { break }
            set.insert(sounds[i].snd)
        }
        while k < stops.count {
            Self.stop(stops[k], in: &set)
            k += 1
        }
        return set
    }

    /// `FUN_10091504(snd)`: every entry playing `snd`'s handle — every entry for a nil handle (an unloaded snd).
    private static func stop(_ snd: Int16, in set: inout Set<Int16>) {
        if SoundSlots.isLoaded(snd) { set.remove(snd) } else { set.removeAll() }
    }
}

extension SpriteWorld {
    /// `FUN_100916dc(snd) != 0` at a call site: the iteration's `voices` after the sound calls made so far.
    public func isSoundPlaying(_ snd: Int16) -> Bool { voices.isPlaying(snd, after: player.soundCalls) }
}

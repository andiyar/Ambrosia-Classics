import Foundation
import DeimosCore
import HectorAudio
import Synchronization

/// What the driver feeds the game's audio with, in pass order (plan S5; H2 routes a pass's `CueBuffer` here when the
/// pass begins). There is no volume parameter: Q4 RULED by Ben 2026-10-07 (D31) — no in-game master gain.
public protocol DeimosAudioSink: AnyObject, Sendable {
    /// Start `sounds[0..<k]`, halt every effect when `haltEffectsAt = k` (`FUN_100476a0`), start `sounds[k...]`,
    /// then apply the music cues in order.
    func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?)
}

/// The game's audio: the 16-voice / 8-audible effects mixer (`EffectMixer`, A1) and the music streamer
/// (`MusicStream`) behind ONE pull source (HectorKit `PCMPullSource`, K2) — interleaved stereo float32 at 44.1 kHz.
/// All shared state sits under one `Mutex`; `render` (audio thread) never allocates: the effects are preloaded at
/// `init`, a music stream's buffers are allocated by `apply` (`.play`, game thread) before it is swapped in, and a
/// replaced stream is released by `apply` after the lock, never on the audio thread.
///
/// **Unity gain (Q4 RULED by Ben 2026-10-07, D31).** The original's master "Sound Volume" wrote the Mac's device
/// volume (`FUN_10047b80` → `FUN_100d16d0` → `SetDefaultOutputVolume`, bank sound-music §4.1), and every such write
/// is skipped on Mac OS X (`FUN_100461b0`: `Gestalt('sysv') ≥ 0x0A00`). So effects mix at the mixer's own unity
/// (gain 0x80 = volume 100) and music at its `ampCmd` level only; the OS volume controls set the loudness. No master
/// gain stage exists here, and `apply` takes no volume.
///
/// **The `FUN_10047bf0` gates** (`10047c28` sound available `-0x60a0(r2)`, `10047c34` effects enabled `-0x609f(r2)`)
/// are both set at `FUN_10047160` `10047228`/`10047230` exactly when the mixer opens, and the effects-enabled byte is
/// never cleared (its only store is `10047230`; bank §2.3 step 1). A constructed engine IS an opened mixer, so both
/// are constantly true here and not stored; a mixer that fails to open is an engine that was never made (A3: the
/// app stays silent, like `FUN_10047160`'s "Sound not available" path) and the driver has `audio == nil` (H2).
/// Music has no such gate (`FUN_10047f90` tests nothing but `none`), and with no engine there is no music either —
/// the original would stream music at amp 255 with the mixer down (§6.2); not reachable with a working output.
public final class DeimosAudioEngine: DeimosAudioSink, PCMPullSource {
    /// `FUN_100d1400(numChannels, 0xAC440000)`: 44.1 kHz.
    public let outputRate: Double = 44100

    struct State: Sendable {
        var effects: EffectMixer
        var music: MusicStream?
        /// `0x100e072e`, the music level `m` ≤ 0x100 (`FUN_100d0470`). An engine exists only after sound init
        /// succeeded, and sound init applies the music pref (`FUN_10047160` → `FUN_10047920` → `FUN_10048280`):
        /// int pref 1, default 100 (`FUN_100050f0`) → 128. A different pref arrives as `MusicCue.level`.
        var musicLevel: UInt16 = MusicStream.level(pref: 100)
    }

    private let state: Mutex<State>
    private let loadMusic: @Sendable (FourCC) -> Data?
    /// Parsed tracks by tag (game thread only; music restarts from the top every level, §6.4).
    private let tracks = Mutex<[FourCC: MusicTrack]>([:])

    /// Opens the mixer (`FUN_10047160`, numChannels = flli 38 `SoundNumChannels`) and preloads every effect: each
    /// `soun` tag in `assets.index` (first record of an id, as `TagIndex.record` finds it) that passes the effect
    /// load (`FUN_100d1780`: AIFF/AIFC, channels < 2, `ima4`) — the music tracks are stereo and fall out. A tag whose
    /// conversion fails is not registered (`FUN_10047330`: "couldn't convert an AIFF sound…", no record).
    public convenience init(assets: DeimosAssets) throws {
        let channels = assets.floats.count > 38 ? Int(EffectMixer.fctiwz(assets.floats[38])) : 8
        var mixer = EffectMixer(numChannels: channels)
        let soun = FourCC("soun")!
        var seen = Set<FourCC>()
        for record in assets.index.records(ofType: soun) where seen.insert(record.id).inserted {
            guard let first = assets.index.record(type: soun, id: record.id),
                  let data = try? assets.index.data(for: first),
                  let sound = try? IMAContinuous(soundFile: data) else { continue }
            mixer.register(record.id, sound)
        }
        let index = assets.index
        self.init(effects: mixer) { id in
            guard let r = index.record(type: soun, id: id) else { return nil }
            return try? index.data(for: r)
        }
    }

    /// An engine over a ready mixer and a music-file source (tests: synthetic effects and AIFC tracks).
    init(effects: EffectMixer, music: @escaping @Sendable (FourCC) -> Data?) {
        state = Mutex(State(effects: effects))
        loadMusic = music
    }

    // MARK: DeimosAudioSink (game thread)

    public func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?) {
        // `.play` streams are built (track parsed once, buffers allocated, first packet decoded) before the lock.
        var prepared: [MusicStream?] = []
        for cue in music {
            if case let .play(id, loop) = cue { prepared.append(stream(id, loop: loop)) } else { prepared.append(nil) }
        }
        let halt = haltEffectsAt.map { $0 < 0 ? 0 : ($0 > sounds.count ? sounds.count : $0) }
        var released: [MusicStream] = []
        released.reserveCapacity(music.count)
        state.withLock { s in
            for (i, cue) in sounds.enumerated() {
                if i == halt { s.effects.stopAll() }                    // FUN_100476a0 → FUN_100d1be0(0)
                s.effects.play(cue)
            }
            if halt == sounds.count { s.effects.stopAll() }
            for (i, cue) in music.enumerated() {
                switch cue {
                case .play:
                    // FUN_10047f90: pause the current stream, stop it (FUN_10048120(0)); `none` → nothing plays;
                    // a missing or unreadable track logs "MUSIC ERROR" and nothing plays (`100480fc`).
                    // A swap, not a copy: the new stream's buffers stay uniquely owned (render mutates them in
                    // place), and the old stream lands in `prepared`, released after the lock on this thread.
                    swap(&s.music, &prepared[i])
                case .stop:
                    // FUN_10048120(0): pause and dispose (`FUN_100d0250`) — no fade from a cue.
                    if let old = s.music { released.append(old) }
                    s.music = nil
                case .pause:
                    s.music?.paused = true                              // FUN_10048220(1) → FUN_100d039c
                case .resume:
                    s.music?.paused = false                             // FUN_10048220(0) → FUN_100d040c
                case let .level(v):
                    s.musicLevel = MusicStream.level(pref: v)           // FUN_10048280 → FUN_100d0470
                }
            }
        }
        _ = (released, prepared)                                        // replaced streams die here, not in render
    }

    /// A fresh stream for `id` (nil for `none` or a track that will not load).
    private func stream(_ id: FourCC, loop: Bool) -> MusicStream? {
        guard id != .none else { return nil }                           // 10047ff0 subis r0,r28,0x6e6f; cmplwi 0x6e65
        let cached = tracks.withLock { $0[id] }
        let track: MusicTrack
        if let cached { track = cached } else {
            guard let data = loadMusic(id), let t = try? MusicTrack(soundFile: data) else { return nil }
            tracks.withLock { $0[id] = t }
            track = t
        }
        return MusicStream(track: track, loop: loop)
    }

    // MARK: PCMPullSource (audio thread)

    /// Effects (the mixer's 1024-frame blocks, Int16 / 32768, unity) plus music × `amp/255`, interleaved stereo
    /// float32, `frames × 2` values overwritten. One lock, no allocation.
    public func render(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int) {
        let n = min(frames, buffer.count / 2)
        guard n > 0 else { return }
        state.withLock { s in
            s.effects.render(into: buffer, frames: n)
            let gain = MusicStream.gain(amp: MusicStream.amp(level: s.musicLevel))
            s.music?.mix(into: buffer, frames: n, gain: gain)
        }
    }

    // MARK: Inspection (tests)

    func withState<R>(_ body: (inout State) -> R) -> R {
        state.withLock { s in body(&s) }
    }
}

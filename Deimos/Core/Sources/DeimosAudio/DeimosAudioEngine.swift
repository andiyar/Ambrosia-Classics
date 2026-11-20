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
    /// `FUN_100476e0(id)`: the effect's last started voice is still in the mixer's list ("voice ended" = false). The
    /// host asks it only to end a `HostWait.voiceEnd` (Phase 4, plan S1a); Core never reads it (standing rule 10).
    /// Required: every sink answers (a sink with no mixer behind it answers false — nothing sounds).
    func isPlaying(_ id: FourCC) -> Bool
    /// `FUN_100d05a8`: the music's fade-out (`MusicCue.stopWithFade`, `FUN_100d04d8(1000)`) is still running — its
    /// rate `0x100e075c` is non-zero until the level reaches 0 (`100d0750..100d0848`). The host asks it only to end a
    /// `HostWait.musicStopped` (Phase 4); Core never reads it (standing rule 10). Required: a sink with no music
    /// behind it answers false. It moves only while the sink renders: with no audio rendering a fade never ends and
    /// the wait releases at its bound.
    func isMusicFading() -> Bool
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
        /// `FUN_10048120(1)` in progress (Phase 4, `MusicCue.stopWithFade`): output frames rendered since the fade
        /// began. The fade level (`0x100e0730`) falls 0x100 → 0 linearly over `fadeOutFrames` (1000 ms,
        /// `FUN_100d04d8(1000)`: one level per 1/256 of the stream's bytes per second × 1 s, stepped by the
        /// double-buffer callback, `100d0750..100d0848` — here stepped once per `render` call); at 0 the stream is
        /// paused, and the next `apply` disposes of it (game thread). nil = no fade.
        var musicFadeFrames: Int?
    }

    /// 1000 ms of output (`FUN_10048120(1)` → `FUN_100d04d8(1000)`).
    static let fadeOutFrames = 44_100

    private let state: Mutex<State>
    /// Every music track by tag, read and parsed at `init` so `.play` does no file I/O on the game thread (music
    /// restarts from the top every level, §6.4). Immutable; the compressed bytes stay resident (≈ 13.6 MB for the
    /// three shipped tracks — the original streamed them from disk, §6.3; only the decode is per packet here).
    private let tracks: [FourCC: MusicTrack]

    /// Opens the mixer (`FUN_10047160`, numChannels = flli 38 `SoundNumChannels`) and preloads every effect: each
    /// `soun` tag in `assets.index` (first record of an id, as `TagIndex.record` finds it) that passes the effect
    /// load (`FUN_100d1780`: AIFF/AIFC, channels < 2, `ima4`) — the music tracks are stereo and fall out. A tag whose
    /// conversion fails is not registered (`FUN_10047330`: "couldn't convert an AIFF sound…", no record; DEBUG builds
    /// log it). Every `soun` tag that fails the effect gate and parses as an `ima4` track (`mu03`, `ammu`, `inmu`) is
    /// loaded as music.
    public convenience init(assets: DeimosAssets) throws {
        let channels = assets.floats.count > 38 ? Int(EffectMixer.fctiwz(assets.floats[38])) : 8
        var mixer = EffectMixer(numChannels: channels)
        let soun = FourCC("soun")!
        var music: [FourCC: MusicTrack] = [:]
        var seen = Set<FourCC>()
        for record in assets.index.records(ofType: soun) where seen.insert(record.id).inserted {
            guard let first = assets.index.record(type: soun, id: record.id),
                  let data = try? assets.index.data(for: first) else { continue }
            do {
                mixer.register(record.id, try IMAContinuous(soundFile: data))
            } catch {
                if let track = try? MusicTrack(soundFile: data) {
                    music[record.id] = track
                } else {
                    #if DEBUG
                    print("DeimosAudio: couldn't convert an AIFF sound to the internal format: soun '\(record.id)' (\(error))")
                    #endif
                }
            }
        }
        self.init(effects: mixer, tracks: music)
    }

    /// An engine over a ready mixer and parsed music tracks (tests: synthetic effects and AIFC tracks). Init
    /// parameters are owned anyway; `consuming` only records that the engine takes the mixer. `EffectMixer` is
    /// copyable, so nothing enforces it: a caller that keeps a copy leaves the buffers shared, and the first
    /// mutation in `render` would copy them on the audio thread — so callers must not keep one.
    init(effects: consuming EffectMixer, tracks: [FourCC: MusicTrack]) {
        state = Mutex(State(effects: effects))
        self.tracks = tracks
    }

    // MARK: DeimosAudioSink (game thread)

    public func apply(sounds: [SoundCue], music: [MusicCue], haltEffectsAt: Int?) {
        // `.play` streams are built (buffers allocated, first packet decoded; no I/O) before the lock.
        var prepared: [MusicStream?] = []
        for cue in music {
            if case let .play(id, loop) = cue { prepared.append(stream(id, loop: loop)) } else { prepared.append(nil) }
        }
        let halt = haltEffectsAt.map { $0 < 0 ? 0 : ($0 > sounds.count ? sounds.count : $0) }
        var released: [MusicStream] = []
        released.reserveCapacity(music.count)
        state.withLock { s in
            if let f = s.musicFadeFrames, f >= Self.fadeOutFrames {    // a finished fade-out: dispose (FUN_100d0250)
                if let old = s.music { released.append(old) }
                s.music = nil
                s.musicFadeFrames = nil
            }
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
                    s.musicFadeFrames = nil
                case .stop:
                    // FUN_10048120(0): pause and dispose (`FUN_100d0250`) — no fade.
                    if let old = s.music { released.append(old) }
                    s.music = nil
                    s.musicFadeFrames = nil
                case .pause:
                    s.music?.paused = true                              // FUN_10048220(1) → FUN_100d039c
                case .resume:
                    // FUN_10048220(0) → FUN_100d040c. A stream fading out is being disposed of (the original's game
                    // thread is inside FUN_10048120(1) until then): no resume.
                    if s.musicFadeFrames == nil { s.music?.paused = false }
                case let .level(v):
                    s.musicLevel = MusicStream.level(pref: v)           // FUN_10048280 → FUN_100d0470
                case .stopWithFade:
                    // FUN_10048120(1): no stream → nothing (FUN_100481e0); playing → the fade (FUN_100d04d8(1000)),
                    // then pause and dispose (render, then the next apply); paused → dispose at once (10048130..).
                    if let m = s.music, s.musicFadeFrames == nil {
                        if m.paused {
                            released.append(m)
                            s.music = nil
                        } else {
                            s.musicFadeFrames = 0
                        }
                    }
                }
            }
        }
        _ = (released, prepared)                                        // replaced streams die here, not in render
    }

    /// A fresh stream for `id` (nil for `none` or a tag that is not a loaded track — "MUSIC ERROR", nothing plays).
    private func stream(_ id: FourCC, loop: Bool) -> MusicStream? {
        guard id != .none, let track = tracks[id] else { return nil }   // 10047ff0 subis r0,r28,0x6e6f; cmplwi 0x6e65
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
            var fade: UInt16 = 0x100
            if let f = s.musicFadeFrames {                              // FUN_10048120(1)'s fade, per callback
                let down = f >= Self.fadeOutFrames ? 0x100 : f * 0x100 / Self.fadeOutFrames
                fade = UInt16(0x100 - down)
                s.musicFadeFrames = f + n
                if fade == 0 { s.music?.paused = true }                 // 100481b0 FUN_10048220(1)
            }
            let gain = MusicStream.gain(amp: MusicStream.amp(level: s.musicLevel, fade: fade))
            s.music?.mix(into: buffer, frames: n, gain: gain)
        }
    }

    /// `FUN_100476e0(id)` on the mixer (`EffectMixer.isPlaying`), under the lock (game thread; Phase 4).
    public func isPlaying(_ id: FourCC) -> Bool {
        state.withLock { s in s.effects.isPlaying(id) }
    }

    /// `FUN_100d05a8` (game thread; Phase 4): a `stopWithFade` fade has begun on a stream and `render` has not yet
    /// brought its level to 0 (the render that does pauses the stream, `100481b0`); a `.play` or `.stop` ends it, and
    /// no stream means no fade.
    public func isMusicFading() -> Bool {
        state.withLock { s in
            guard s.musicFadeFrames != nil, let m = s.music else { return false }
            return !m.paused
        }
    }

    // MARK: Inspection (tests)

    func withState<R>(_ body: (inout State) -> R) -> R {
        state.withLock { s in body(&s) }
    }
}

import Foundation

/// The QuickTime music player's state and fades as `MusicCue`s (plan S2, FE0; M l. 41852–42140, digest C §6 grounded on
/// the dump). One `SetMovieVolume` call = one `.volume` cue, except a call repeating the volume the same call sequence
/// set just before (a no-op on the movie, e.g. the blocking fade's first `SetMovieVolume` and its step 0).
/// Volumes are the movie's 0…256 scale; V = prefs+0x10 · 256 / 9 (signed divide, `mulhw 0x38e38e39`, raw `10049c30`).
public struct MusicFade: Equatable, Sendable {
    /// `DAT_100a5104`: QuickTime present — always true in the replica.
    public var quickTimePresent = true
    /// `DAT_100a1992`: a movie is loaded (`SetAIFFMusic` succeeded, `ShutDownAIFFMusic` clears it).
    public var loaded = false
    /// `_DAT_100a5be0`: the current track (data-section initial −1).
    public var currentTrack: Int16 = -1
    /// `*_DAT_100a0448`: the music is faded (silent): `SetAIFFMusic` sets it, a fade-out sets it, a fade-in clears it.
    public var musicFaded = false
    /// `*_DAT_1009fd6c`: the current-volume global (updated by the fades' ends and the async steps).
    public var volume: Int16 = 0
    /// `cRam100a5be2`: no async fade running (data-section initial 1).
    public var asyncDone = true
    /// `_DAT_100a198e`: the async fade's direction (0 out, 1 in).
    public var asyncDirection: Int16 = 0
    /// `_DAT_100a198c`: the async fade's frame count N (data-section initial 1).
    public var asyncFrames: Int16 = 1
    /// `_DAT_100a1990`: the async fade's frame counter i.
    public var asyncFrame: Int16 = 0

    public init() {}

    /// V = prefs+0x10 · 256 / 9, truncated toward zero, as a short.
    public static func fullVolume(_ prefs: FerazelPrefs) -> Int {
        Int(Int16(truncatingIfNeeded: (Int32(prefs.musicVolume) << 8) / 9))
    }

    /// `.SetAIFFMusic(n) @ 10049388` (M l. 41852ff): n −1 → nothing at all (the current music is not stopped); else
    /// n < 1 or > 32 → 1, `ShutDownAIFFMusic` (`.stop`), then the movie opened, `SetMovieVolume(0)` before the start,
    /// `*0448 = 1`, `1992 = 1`, `5be0 = n`, load, preroll, start → `.play(track: n)` (which starts at volume 0: no
    /// separate `.volume(0)`). A missing file's retry with n − 1 stays the App's resolver (`FerazelAudio.resolveTrack`).
    public mutating func setAIFFMusic(_ n: Int) -> [MusicCue] {
        guard quickTimePresent else { return [] }
        var track = Int16(truncatingIfNeeded: n)
        guard track != -1 else { return [] }
        if track < 1 || track > 0x20 { track = 1 }
        loaded = true
        musicFaded = true
        currentTrack = track
        return [.stop, .play(track: Int(track))]
    }

    /// `.ShutDownAIFFMusic @ 10049644`: stops and disposes the movie when one is loaded.
    public mutating func shutDown() -> [MusicCue] {
        guard quickTimePresent, loaded else { return [] }
        loaded = false
        return [.stop]
    }

    /// `.FadeAIFFMusic(dir, t) @ 1004974c` (M l. 41993–42050), blocking: gated on QuickTime, music on (prefs+0x0c) and
    /// a loaded movie; out (dir 0) only when `*0448 == 0` (sets it), in (dir ≠ 0) only when `*0448 ≠ 0` (clears it at
    /// its start). 24 steps s = 0…23, each `SetMovieVolume(V·(24−s)/24)` (out) / `V·s/24` (in) then a wait of t ticks
    /// (`TickCount − t ≥ start`), then 0 / V and the current-volume global — at tick 24·t, the block's end.
    public mutating func fadeAIFFMusic(direction: Int, ticks t: Int, prefs: FerazelPrefs) -> FrontTimeline {
        guard quickTimePresent, prefs.musicOn != 0, loaded else { return .none }
        let out = Int16(truncatingIfNeeded: direction) == 0
        if out {
            guard !musicFaded else { return .none }
            musicFaded = true
        } else {
            guard musicFaded else { return .none }
            musicFaded = false
        }
        let v = Self.fullVolume(prefs), step = max(0, t)
        var events: [FrontTimeline.Event] = []
        var last = out ? v : 0                                   // the first `SetMovieVolume` (V out, 0 in)
        var first = true
        for s in 0..<24 {
            let vol = Int(Int16(truncatingIfNeeded: v * (out ? 24 - s : s) / 24))
            var cues: [MusicCue] = []
            if first { cues.append(.volume(last)) }
            if !(first && vol == last) { cues.append(.volume(vol)) }
            first = false
            last = vol
            events.append(.init(at: s * step, output: FrontOutput(music: cues)))
        }
        let end = out ? 0 : v
        events.append(.init(at: 24 * step, output: FrontOutput(music: [.volume(end)])))
        volume = Int16(truncatingIfNeeded: end)
        return FrontTimeline(events: events, duration: 24 * step)
    }

    /// `.FadeAIFFMusicAsync(dir, N) @ 10049bac` (M l. 42114–42140, raw `10049bac..10049c7c`): gated on QuickTime, music
    /// on and a loaded movie; arms the per-frame handler (`5be2 = 0`, i = 0, N, dir) regardless of `*0448`; out: when
    /// `*0448 == 0` sets it and `SetMovieVolume(V)`; in: when `*0448 ≠ 0` **clears it** (`stb r6` raw `10049c5c`) and
    /// `SetMovieVolume(0)`.
    public mutating func fadeAIFFMusicAsync(direction: Int, frames: Int, prefs: FerazelPrefs) -> [MusicCue] {
        guard quickTimePresent, prefs.musicOn != 0, loaded else { return [] }
        let dir = Int16(truncatingIfNeeded: direction)
        asyncDone = false
        asyncFrame = 0
        asyncFrames = Int16(truncatingIfNeeded: frames)
        asyncDirection = dir
        if dir == 0 {
            guard !musicFaded else { return [] }
            musicFaded = true
            return [.volume(Self.fullVolume(prefs))]
        }
        guard musicFaded else { return [] }
        musicFaded = false
        return [.volume(0)]
    }

    /// `.HandleAsyncAIFFMusicFade @ 100499c4` (M l. 42061–42105), once per frame: when QuickTime, a loaded movie and an
    /// armed fade (`5be2 == 0`) — out: `V·(N−i)/N`; in: `V·i/N`; i += 1; when i > N the fade ends (`5be2 = 1`) with 0
    /// (out) or `*0448 = 0` and V (in). Other directions do nothing. N = 0 → quotient 0 [LOW: a `divw` by 0].
    public mutating func handleAsyncFade(prefs: FerazelPrefs) -> [MusicCue] {
        guard quickTimePresent, !asyncDone, loaded, asyncDirection == 0 || asyncDirection == 1 else { return [] }
        let v = Int32(Self.fullVolume(prefs)), n = Int32(asyncFrames), i = Int32(asyncFrame)
        let num = v &* (asyncDirection == 0 ? n - i : i)
        let vol = Int16(truncatingIfNeeded: n == 0 ? 0 : num / n)
        var cues: [MusicCue] = [.volume(Int(vol))]
        volume = vol
        asyncFrame &+= 1
        if asyncFrames < asyncFrame {
            asyncDone = true
            let end: Int16 = asyncDirection == 0 ? 0 : Int16(truncatingIfNeeded: v)
            if asyncDirection == 1 { musicFaded = false }
            if end != vol { cues.append(.volume(Int(end))) }
            volume = end
        }
        return cues
    }
}

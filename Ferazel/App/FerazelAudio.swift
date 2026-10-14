import FerazelCore
import FerazelRender
import Foundation
import HectorShell

/// The music voice (plan A1, design §7.7): `.SetAIFFMusic @ decompile l. 41869–41921` plays the AIFC track `NN` from
/// `Ferazel's Wand Music` — −1 plays nothing, a number outside 1..32 is 1, a file that does not open falls back to
/// n − 1 (tracks 21 and 27 are absent, design §3.1) — decoded by the kit (`MusicTrack`), looped, on one `ShellMixer` voice at prefs+0x10's volume (music = v·256/9, so
/// the default 9 is 256/256 — full, the Sound Manager's 0x100 unity).
///
/// Sound effects (plan A3, S1/S2 as built): the original's Sound Tool mixer (`SoundTool`, FerazelRender) over every
/// `snd ` of the Sounds file, attached beside the music voice as a mixer stream. Each iteration's `FrameOps.sounds` /
/// `soundStops` are applied in the binary's call order (`soundStopAt`). The cues already carry the global sound volume
/// (prefs+0xe = 7 → 196, S1), so the stream plays at unity.
///
/// The music fade-out `.FadeAIFFMusic(0, n)` (M l. 41980–42025) is stepped by the caller one step at a time
/// (`fadeOutStep`), since the original blocks in it (24 steps, `n` ticks each).
@MainActor final class FerazelAudio {
    static let musicVoice = 0
    /// "Looped": the mixer's play count, as good as forever.
    static let musicLoops = Int.max

    private let mixer: ShellMixer?
    private let musicDirectory: URL
    private let prefs: FerazelPrefs
    private var loadedTrack: Int?
    /// `DAT_100a1992`: a track is playing (set by a play, cleared by `.ShutDownAIFFMusic`).
    private var musicPlaying = false
    /// The Sound Tool, attached to `mixer` as a stream; nil when there is no mixer or no Sounds file.
    private let soundTool: SoundTool?
    /// Every `snd ` id the Sound Tool holds (the stop-everything sweep; `SoundTool` has no `0 = all`, S2 carries).
    private let soundIDs: [Int16]

    /// - Parameter mixer: nil when the audio device cannot start (the game runs silent).
    /// - Parameter sounds: the Sounds file's `snd ` bank; nil plays no effects.
    init(mixer: ShellMixer?, musicDirectory: URL, prefs: FerazelPrefs, sounds: SoundBank?) {
        self.mixer = mixer
        self.musicDirectory = musicDirectory
        self.prefs = prefs
        if let mixer, let sounds {
            let tool = SoundTool(bank: sounds)
            _ = mixer.attachStream(tool)
            soundTool = tool
            soundIDs = sounds.sounds.map(\.id)
        } else {
            soundTool = nil
            soundIDs = []
        }
    }

    // MARK: Sound effects

    /// One iteration's effects, in the binary's call order (S1 as built, `FrameOps.soundStopAt`): for i in
    /// 0 … sounds.count, every stop made before play i (`FUN_10091504(snd)`), then play i (`FUN_10091208`) — a cue
    /// marked `onlyIfIdle` is made only while no entry plays its `snd` (`if (!FUN_100916dc(snd))`).
    func apply(sounds: [SoundCue], stops: [Int16], stopAt: [Int]) {
        guard let tool = soundTool else { return }
        var k = 0
        for i in 0...sounds.count {
            while k < stops.count, (k < stopAt.count ? stopAt[k] : sounds.count) <= i {
                tool.stop(snd: stops[k])
                k += 1
            }
            guard i < sounds.count else { break }
            let cue = sounds[i]
            if cue.onlyIfIdle && tool.isPlaying(snd: cue.snd) { continue }
            tool.play(snd: cue.snd, priority: UInt16(clamping: cue.priority), left: UInt16(clamping: cue.left),
                      right: UInt16(clamping: cue.right), rate: Int32(bitPattern: cue.rate))
        }
        while k < stops.count {           // defensive: a stop recorded without its place goes last
            tool.stop(snd: stops[k])
            k += 1
        }
    }

    /// Silences every effect (on quit, `stopAll`): each `snd ` id's `FUN_10091504`.
    func stopEffects() {
        guard let tool = soundTool else { return }
        for id in soundIDs { tool.stop(snd: id) }
    }

    // MARK: Music

    /// prefs+0x10 (0…9) → the mixer's volume (0x100 = full).
    static func musicVolume(_ v: Int) -> Float {
        Float(v * 256 / 9)
    }

    /// `.SetAIFFMusic`'s file choice: nil for −1 (or when no file down to 01 opens); outside 1..32 → 1; a missing
    /// `NN` → `NN − 1`, recursively (l. 41879–41883, 41918–41919).
    static func resolveTrack(_ requested: Int, exists: (Int) -> Bool) -> Int? {
        guard requested != -1 else { return nil }
        var n = (1...0x20).contains(requested) ? requested : 1
        while !exists(n) {
            guard n > 1 else { return nil }
            n -= 1
        }
        return n
    }

    /// Resolves and decodes `requested` into the mixer ahead of its `.play` (no-op when already loaded). Returns the
    /// track that will play.
    @discardableResult
    func prepare(track requested: Int) -> Int? {
        guard let mixer else { return nil }
        let dir = musicDirectory
        guard let track = Self.resolveTrack(requested, exists: { n in
            FileManager.default.fileExists(atPath: dir.appendingPathComponent(MusicTrack.fileName(n)).path)
        }) else { return nil }
        if loadedTrack != track {
            do {
                let pcm = try MusicTrack(number: track, in: musicDirectory).decode()
                mixer.load(id: track, samples: pcm.samples, channels: pcm.channels, sampleRate: pcm.sampleRate)
                loadedTrack = track
            } catch {
                NSLog("Ferazel's Wand: music track %d: %@", track, "\(error)")
                return nil
            }
        }
        return track
    }

    func handle(_ cue: MusicCue) {
        guard let mixer else { return }
        switch cue {
        case .play(let requested):
            guard prefs.musicOn != 0, let track = prepare(track: requested) else { return }
            mixer.play(id: track, on: Self.musicVoice, volume: Self.musicVolume(Int(prefs.musicVolume)),
                       loops: Self.musicLoops)
            musicPlaying = true
        case .stop:
            mixer.stop(voice: Self.musicVoice)
            musicPlaying = false
        case .volume(let v):
            // Not emitted in Phase 1; read as prefs+0x10's 0…9 scale.
            mixer.setVolume(voice: Self.musicVoice, Self.musicVolume(v))
        }
    }

    /// `.FadeAIFFMusic(0, n)`'s steps (`sVar6 < 0x18`).
    static let fadeSteps = 24

    /// `.FadeAIFFMusic(0, n)`'s gate (l. 41993–41996): music on (prefs+0xc) and a track playing. (The "already faded"
    /// flag `_DAT_100a0448` is not modelled: M13 plays every track at full volume, never faded in — Phase 3.) When
    /// false the call returns at once, without its waits.
    var canFadeOut: Bool {
        mixer != nil && prefs.musicOn != 0 && musicPlaying
    }

    /// `.FadeAIFFMusic(0, n)`'s step s (0 … 23): volume (V·(24 − s)) / 24 with V = prefs+0x10 · 256 / 9 (l. 42003–
    /// 42010); the caller then waits n ticks. Step 24 is the closing `SetMovieVolume(0)` (l. 42016).
    func fadeOutStep(_ s: Int) {
        let v = Int(prefs.musicVolume) * 256 / 9
        let volume = s >= Self.fadeSteps ? 0 : v * (Self.fadeSteps - s) / Self.fadeSteps
        mixer?.setVolume(voice: Self.musicVoice, Float(volume))
    }

    /// `.ShutDownAIFFMusic` (l. 41948–41958): the track stops and is let go (only while one plays).
    func shutDownMusic() {
        guard musicPlaying else { return }
        mixer?.stop(voice: Self.musicVoice)
        musicPlaying = false
    }

    func stopAll() {
        mixer?.stopAll()
        stopEffects()
        musicPlaying = false
    }
}

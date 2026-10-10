import FerazelCore
import FerazelRender
import Foundation
import HectorShell

/// The music voice (plan A1, design §7.7): `.SetAIFFMusic @ decompile l. 41869–41921` plays the AIFC track `NN` from
/// `Ferazel's Wand Music` — −1 plays nothing, a number outside 1..32 is 1, a file that does not open falls back to
/// n − 1 (tracks 21 and 27 are absent, design §3.1) — decoded by the kit (`MusicTrack`), looped, on one `ShellMixer` voice at prefs+0x10's volume (music = v·256/9, so
/// the default 9 is 256/256 — full, the Sound Manager's 0x100 unity). Sound effects are not in Phase 1.
@MainActor final class FerazelAudio {
    static let musicVoice = 0
    /// "Looped": the mixer's play count, as good as forever.
    static let musicLoops = Int.max

    private let mixer: ShellMixer?
    private let musicDirectory: URL
    private let prefs: FerazelPrefs
    private var loadedTrack: Int?

    /// - Parameter mixer: nil when the audio device cannot start (the game runs silent).
    init(mixer: ShellMixer?, musicDirectory: URL, prefs: FerazelPrefs) {
        self.mixer = mixer
        self.musicDirectory = musicDirectory
        self.prefs = prefs
    }

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
        case .stop:
            mixer.stop(voice: Self.musicVoice)
        case .volume(let v):
            // Not emitted in Phase 1; read as prefs+0x10's 0…9 scale.
            mixer.setVolume(voice: Self.musicVoice, Self.musicVolume(v))
        }
    }

    func stopAll() {
        mixer?.stopAll()
    }
}

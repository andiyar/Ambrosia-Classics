import FerazelCore
import FerazelRender
import Foundation

/// The music voice (plan S5, A1a; design §7.7): `.SetAIFFMusic @ decompile l. 41869–41921` plays the AIFC track `NN`
/// from `Ferazel's Wand Music` — −1 plays nothing, a number outside 1..32 is 1, a file that does not open falls back to
/// n − 1 (tracks 21 and 27 are absent, design §3.1) — decoded by the kit (`MusicTrack`), looped, on one `ShellMixer`
/// voice. Core's `MusicFade` owns every volume: `.play` stops the voice, loads the track under the one fixed mixer id
/// `musicID` (`ShellMixer.load(id:)` replaces the previous track, so a track is never kept once another plays) and
/// starts it at volume 0 (`SetMovieVolume(0)` before the start); `.volume(v)` is the movie's 0…256 scale (0x100 =
/// unity) straight into the voice; `.stop` (`ShutDownAIFFMusic`) stops it. No prefs are read here: the fades already
/// carry prefs+0x10's V (`MusicFade.fullVolume`) and the music-off gate.
///
/// Sound effects (plan A3, S1/S2 as built): the original's Sound Tool mixer (`SoundTool`, FerazelRender) over the
/// Sounds file's `snd `s, attached beside the music voice as a mixer stream when the flow's sound load runs
/// (`loadSounds`). Each tick's sounds / stops are applied in the binary's call order (`soundStopAt`). The cues already
/// carry the global sound volume (prefs+0xe, S1), so the stream plays at unity.
/// Shared by both shells (Phase W, WF1 — moved from the Mac app unchanged in logic): the mixer is a `FerazelMixer` (the
/// Mac's `ShellMixer`; Windows' SDL output; the headless frames mode's `FerazelSilentMixer`), and failures go to the
/// injected `log` (the Mac's `NSLog`).
@MainActor final class FerazelAudio {
    static let musicVoice = 0
    /// The one mixer id every music track is loaded under (S5).
    static let musicID = 0
    /// "Looped": the mixer's play count, as good as forever.
    static let musicLoops = Int.max

    private let mixer: FerazelMixer?
    private let musicDirectory: URL
    private let log: (String) -> Void
    /// The track now held under `musicID` (nil before the first).
    private var loadedTrack: Int?
    /// The Sound Tool, attached to `mixer` as a stream by `loadSounds`; nil before, or with no mixer.
    private var soundTool: SoundTool?
    /// The `snd ` ids loaded (`.InitSounds` loads none with F1 at boot — only 4803 / 4804, `.InitAppGlobals`).
    private var loaded: Set<Int16> = []

    /// - Parameter mixer: nil when the audio device cannot start (the game runs silent).
    init(mixer: FerazelMixer?, musicDirectory: URL, log: @escaping (String) -> Void) {
        self.mixer = mixer
        self.musicDirectory = musicDirectory
        self.log = log
    }

    // MARK: Sound effects

    /// The boot's sound load (`.InitSounds` + `.InitAppGlobals`, M l. 8324–8326): `bank`'s sounds, or only `only`
    /// (F1 held at boot: `.InitSounds` loads nothing, the menu button sounds still load). A sound not loaded plays
    /// nothing. Once.
    func loadSounds(_ bank: SoundBank, only: Set<Int16>?) {
        guard let mixer, soundTool == nil else { return }
        let tool = SoundTool(bank: bank)
        mixer.attach(stream: tool)
        soundTool = tool
        loaded = Set(bank.sounds.map(\.id).filter { only?.contains($0) ?? true })
    }

    /// One tick's effects, in the binary's call order (S1 as built, `FrameOps.soundStopAt`): for i in
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
            guard loaded.contains(cue.snd) else { continue }
            if cue.onlyIfIdle && tool.isPlaying(snd: cue.snd) { continue }
            tool.play(snd: cue.snd, priority: UInt16(clamping: cue.priority), left: UInt16(clamping: cue.left),
                      right: UInt16(clamping: cue.right), rate: Int32(bitPattern: cue.rate))
        }
        while k < stops.count {           // defensive: a stop recorded without its place goes last
            tool.stop(snd: stops[k])
            k += 1
        }
    }

    /// VS: the `snd ` ids the Sound Tool is playing now (`FrontInput.playing`); empty with no Sound Tool.
    func playingSounds() -> Set<Int16> { soundTool?.playingSounds() ?? [] }

    /// Silences every effect (on quit, `stopAll`): each loaded `snd ` id's `FUN_10091504`.
    func stopEffects() {
        guard let tool = soundTool else { return }
        for id in loaded { tool.stop(snd: id) }
    }

    // MARK: Music

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

    /// Resolves `requested` and makes it the sound under `musicID` (decoded only when another track is held there).
    /// Nil when nothing opens.
    private func load(track requested: Int) -> Int? {
        guard let mixer else { return nil }
        let dir = musicDirectory
        guard let track = Self.resolveTrack(requested, exists: { n in
            FileManager.default.fileExists(atPath: dir.appendingPathComponent(MusicTrack.fileName(n)).path)
        }) else { return nil }
        if loadedTrack != track {
            do {
                let pcm = try MusicTrack(number: track, in: musicDirectory).decode()
                mixer.load(id: Self.musicID, samples: pcm.samples, channels: pcm.channels, sampleRate: pcm.sampleRate)
                loadedTrack = track
            } catch {
                log("music track \(track): \(error)")
                return nil
            }
        }
        return track
    }

    func handle(_ cue: MusicCue) {
        guard let mixer else { return }
        switch cue {
        case .play(let requested):
            mixer.stop(voice: Self.musicVoice)
            guard load(track: requested) != nil else { return }
            mixer.play(id: Self.musicID, on: Self.musicVoice, volume: 0, loops: Self.musicLoops)
        case .stop:
            mixer.stop(voice: Self.musicVoice)
        case .volume(let v):
            mixer.setVolume(voice: Self.musicVoice, Float(v))
        }
    }

    func stopAll() {
        mixer?.stopAll()
        stopEffects()
    }
}

/// What `FerazelAudio` needs from a mixer (WF1): the Mac's `ShellMixer` has the voice calls exactly (`attach(stream:)`
/// is its `attachStream`); Windows' SDL output and the headless `FerazelSilentMixer` provide the same. Volumes are the
/// Sound Manager's 8.8 fixed point as a Float (0x100 = unity).
@MainActor protocol FerazelMixer: AnyObject {
    /// Registers sound `id`: interleaved Int16 `samples`, `channels` 1 or 2, at `sampleRate`.
    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double)
    /// Cuts whatever `voice` was playing and plays `id` `loops` times at `volume`.
    func play(id: Int, on voice: Int, volume: Float, loops: Int)
    func stop(voice: Int)
    func stopAll()
    func setVolume(voice: Int, _ volume: Float)
    /// Adds the Sound Tool as a stream beside the voices (pulled at its own 22,050 Hz).
    func attach(stream: SoundTool)
}

/// No device (Ruling 20, the headless `--frames` dumps of both builds): the music voice plays nothing, and the attached
/// Sound Tool is drained once per game tick — 22,050 / 60 = 367.5 output frames per tick, the fraction accumulated (a
/// running total of 22,050 × ticks / 60, drained to its whole part: 367, 368, 367, 368 …, 367 on the first tick) — so
/// "playing" follows the sounds exactly as with real output, the same on every run and on both builds.
@MainActor final class FerazelSilentMixer: FerazelMixer {
    static let ticksPerSecond = 60
    private var stream: SoundTool?
    /// Game ticks drained so far.
    private(set) var ticks = 0
    /// Output frames drained so far (= ⌊rate × ticks / 60⌋).
    private(set) var framesDrained = 0
    private var scratch: [Float] = []

    init() {}

    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double) {}
    func play(id: Int, on voice: Int, volume: Float, loops: Int) {}
    func stop(voice: Int) {}
    func stopAll() {}
    func setVolume(voice: Int, _ volume: Float) {}
    func attach(stream: SoundTool) { self.stream = stream }

    /// One game tick's output: renders (and discards) the frames the running total owes; returns how many.
    @discardableResult
    func tick() -> Int {
        ticks += 1
        let rate = Int(stream?.outputRate ?? 22_050)
        let total = rate * ticks / Self.ticksPerSecond
        let frames = total - framesDrained
        framesDrained = total
        guard let stream, frames > 0 else { return frames }
        if scratch.count < 2 * frames { scratch = [Float](repeating: 0, count: 2 * frames) }
        scratch.withUnsafeMutableBufferPointer { stream.render(into: $0, frames: frames) }
        return frames
    }
}

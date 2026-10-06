import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorAudio

/// What `WinAudio` needs from a mixer — the same surface as the Mac's `BTXAudioOutput` (HectorShell `ShellMixer`),
/// which HectorAudio's `PCMMixer` has exactly. Volumes are the Sound Manager's 8.8 fixed point as a Float: 0x100 =
/// full, linear. Unknown ids and out-of-range voices are no-ops.
public protocol WinAudioOutput: AnyObject {
    /// Registers sound `id`: interleaved Int16 `samples`, `channels` 1 or 2, at the exact `sampleRate`.
    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double)
    /// Cuts whatever `voice` was playing and plays `id` `loops` times back to back at `volume`.
    func play(id: Int, on voice: Int, volume: Float, loops: Int)
    func stop(voice: Int)
    func pause(voice: Int)
    func resume(voice: Int)
    func setVolume(voice: Int, _ volume: Float)
    /// True while `voice` has frames left to render (also while paused).
    func isPlaying(voice: Int) -> Bool
}

/// The real output: HectorAudio's software mixer (W1), pulled by HectorSDL's audio stream.
extension PCMMixer: WinAudioOutput {}

/// A mixer that plays nothing: the fallback when no audio device opens, so the game still runs. A voice is never
/// "playing", so every cue finds a free voice (the Mac's `SilentAudioOutput`).
public final class SilentWinAudioOutput: WinAudioOutput {
    public init() {}
    public func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double) {}
    public func play(id: Int, on voice: Int, volume: Float, loops: Int) {}
    public func stop(voice: Int) {}
    public func pause(voice: Int) {}
    public func resume(voice: Int) {}
    public func setVolume(voice: Int, _ volume: Float) {}
    public func isPlaying(voice: Int) -> Bool { false }
}

/// The game's sound — a port of the Mac's `BubbleTroubleX/App/BTXAudio.swift` (the spec), rule for rule: the
/// AmbrosiaTools Sound Tool's 4 effect channels (`ST_Open(4,0)`) and the music channel (`gMusicChannel`), as voices
/// 0…3 and 4 of one `WinAudioOutput`. It executes the core's `SoundCue`s (`_PlayMySnd @ 00026a7b` → `ST_PlaySound`)
/// and `MusicCue`s immediately; it never delays a cue and never fades on its own (D14).
public final class WinAudio {
    public static let effectVoices = 4
    public static let musicVoice = 4
    /// `_StartMusic` queues the music segment 50 times.
    public static let musicLoops = 50

    private let output: any WinAudioOutput
    private let pcm: (Int) -> SndPCM?
    private let musicResourceID: (Int) throws -> Int
    private let log: (String) -> Void

    /// Short pref 0x33 (effects) and 0x35 (music): 1 off, 2, 3, 4.
    public var sfxVolumePref = 3
    public var musicVolumePref = 4
    /// Bool pref 0x40 "Title screen music".
    public var titleMusicPref = true
    /// `gPlayGame`: a game (or demo) is running.
    public var gameRunning = false

    private var voicePriority = [Int](repeating: 0, count: effectVoices)
    private var voiceSerial = [Int](repeating: 0, count: effectVoices)
    private var serial = 0
    private var loaded: Set<Int> = []
    /// `gMusicLoaded`: the `snd` id `_LoadMusic` loaded, nil when unloaded.
    public private(set) var musicID: Int?

    /// - Parameters:
    ///   - pcm: the decoded `snd` for an id (nil when it does not decode).
    ///   - musicResourceID: `BTXGameData.musicResourceID(set:)`.
    public init(output: any WinAudioOutput, pcm: @escaping (Int) -> SndPCM?,
                musicResourceID: @escaping (Int) throws -> Int, log: @escaping (String) -> Void = { _ in }) {
        self.output = output
        self.pcm = pcm
        self.musicResourceID = musicResourceID
        self.log = log
        for id in SoundBankPCM.effectIDs { upload(id) }
    }

    public convenience init(output: any WinAudioOutput, sounds: SoundBankPCM, data: BTXGameData,
                            log: @escaping (String) -> Void = { _ in }) {
        self.init(output: output, pcm: { try? sounds.pcm($0) }, musicResourceID: { try data.musicResourceID(set: $0) },
                  log: log)
    }

    // MARK: Effects

    /// `_PlayMySnd`'s Sound Tool volume for short pref 0x33: 2 → 0x10, 3 → 0x40, 4 → 0x100; else (1 = off) nothing.
    public static func sfxVolume(pref: Int) -> Float? {
        switch pref {
        case 2: 0x10
        case 3: 0x40
        case 4: 0x100
        default: nil
        }
    }

    /// The Sound Tool's 0x80-unity volume (clamped at 0x80) on the output's 0x100-unity law: `min(v, 0x80) * 2`
    /// (D14.2). Effect voices only.
    public static func effectOutputVolume(_ soundToolVolume: Float) -> Float {
        min(soundToolVolume, 0x80) * 2
    }

    /// `_StartMusic`'s volume for short pref 0x35: 1 → 0, 2 → 0x40, 3 → 0x80, 4 → 0x100.
    public static func musicVolume(pref: Int) -> Float {
        switch pref {
        case 2: 0x40
        case 3: 0x80
        case 4: 0x100
        default: 0
        }
    }

    /// `ST_PlaySoundParam`'s voice choice: a free voice; else steal the lowest-priority busy voice whose priority ≤
    /// the new one (the oldest of equals); else nil (dropped).
    public static func chooseVoice(priority: Int, busy: [Bool], priorities: [Int], serials: [Int]) -> Int? {
        if let free = busy.firstIndex(of: false) { return free }
        var best: Int?
        for v in priorities.indices where priorities[v] <= priority {
            if let b = best {
                if priorities[v] < priorities[b] || (priorities[v] == priorities[b] && serials[v] < serials[b]) {
                    best = v
                }
            } else {
                best = v
            }
        }
        return best
    }

    /// `_PlayMySnd`. `sfxLevel` stands in for short 0x33 on this one play (the prefs Music popup's snd 13).
    public func play(_ cue: SoundCue, sfxLevel: Int? = nil) {
        guard let volume = Self.sfxVolume(pref: sfxLevel ?? sfxVolumePref) else { return }
        let id = 9000 + cue.slot
        guard SoundBankPCM.effectIDs.contains(id), loaded.contains(id) else { return }
        let busy = (0..<Self.effectVoices).map { output.isPlaying(voice: $0) }
        guard let voice = Self.chooseVoice(priority: cue.priority, busy: busy, priorities: voicePriority,
                                           serials: voiceSerial) else { return }
        serial += 1
        voicePriority[voice] = cue.priority
        voiceSerial[voice] = serial
        output.play(id: id, on: voice, volume: Self.effectOutputVolume(volume), loops: 1)
    }

    /// `ST_HaltSound(0)`: every effect channel stops (the music channel is not the Sound Tool's).
    public func haltEffects() {
        for v in 0..<Self.effectVoices { output.stop(voice: v) }
    }

    // MARK: Music

    public func apply(_ cue: MusicCue) {
        let voice = Self.musicVoice
        switch cue {
        case let .load(set):
            guard musicID == nil else { return }
            let id: Int
            do { id = try musicResourceID(set) } catch {
                log("no music for set \(set): \(error)")
                return
            }
            upload(id)
            if loaded.contains(id) { musicID = id }
        case .start:
            // `_StartMusic`: on a busy channel the 50 queued plays wait behind the current sound (no flush), so
            // playing music carries on at the new volume and a paused channel stays paused (D14.3).
            guard let id = musicID else { return }
            let volume: Float = gameRunning || titleMusicPref ? Self.musicVolume(pref: musicVolumePref) : 0
            if output.isPlaying(voice: voice) {
                output.setVolume(voice: voice, volume)
            } else {
                output.play(id: id, on: voice, volume: volume, loops: Self.musicLoops)
            }
        case .stopNow:
            if musicID != nil { output.stop(voice: voice) }
        case .pause:
            if musicID != nil { output.pause(voice: voice) }
        case .resume:
            if musicID != nil { output.resume(voice: voice) }
        case .unload:
            if musicID != nil { output.stop(voice: voice) }
            musicID = nil
        case let .volume(v):
            output.setVolume(voice: voice, Float(v))
        }
    }

    /// `_UpdateMusicVolume @ 0001b0d5`.
    public func updateMusicVolume() {
        guard musicID != nil else { return }
        let voice = Self.musicVoice
        if !output.isPlaying(voice: voice) && !gameRunning {
            apply(.start)
            return
        }
        output.setVolume(voice: voice, !gameRunning && !titleMusicPref ? 0 : Self.musicVolume(pref: musicVolumePref))
    }

    private func upload(_ id: Int) {
        guard !loaded.contains(id), let p = pcm(id) else { return }
        output.load(id: id, samples: p.samples, channels: p.channels, sampleRate: p.sampleRate)
        loaded.insert(id)
    }
}

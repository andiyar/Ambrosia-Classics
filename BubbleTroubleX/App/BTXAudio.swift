import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorShell

/// What `BTXAudio` needs from a mixer: exactly the HectorShell `ShellMixer` (K3) surface it uses, so the adapter is
/// the one-line extension below. Volumes are the Sound
/// Manager's 8.8 fixed point as a Float: 0x100 = full, linear. Unknown ids and out-of-range voices are no-ops.
@MainActor protocol BTXAudioOutput: AnyObject {
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

/// The real output: HectorShell's real-time mixer, whose surface is exactly `BTXAudioOutput`.
extension ShellMixer: BTXAudioOutput {}

/// A mixer that plays nothing (no CoreAudio at all): the fallback when `ShellMixer` cannot start (no audio
/// device), so the game still runs. A voice is never "playing", so every cue finds a free voice.
@MainActor final class SilentAudioOutput: BTXAudioOutput {
    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double) {}
    func play(id: Int, on voice: Int, volume: Float, loops: Int) {}
    func stop(voice: Int) {}
    func pause(voice: Int) {}
    func resume(voice: Int) {}
    func setVolume(voice: Int, _ volume: Float) {}
    func isPlaying(voice: Int) -> Bool { false }
}

/// The game's sound: the AmbrosiaTools Sound Tool's 4 effect channels (`ST_Open(4,0)`, FI §7) and the music
/// channel (`gMusicChannel`), as voices 0…3 and 4 of one `BTXAudioOutput`. It executes the core's `SoundCue`s
/// (`_PlayMySnd @ 00026a7b` → `ST_PlaySound`) and `MusicCue`s (`_LoadMusic` / `_StartMusic @ 0001ad8c` /
/// `_StopMusicWithoutFade @ 0001af21` / `_PauseMusic` / `_ResumeMusic` / `_UnloadMusic`) immediately; it never
/// delays a cue and never fades on its own (the core's `.volume` cues are the `_StopMusic` fade, plan R4).
@MainActor final class BTXAudio {
    static let effectVoices = 4
    static let musicVoice = 4
    /// `_StartMusic` queues the music segment 50 times (`local_2e` loop to 0x33).
    static let musicLoops = 50

    private let output: any BTXAudioOutput
    private let sounds: SoundBankPCM
    private let data: BTXGameData

    /// Short pref 0x33 (effects) and 0x35 (music): 1 off, 2, 3, 4.
    var sfxVolumePref = 3
    var musicVolumePref = 4
    /// Bool pref 0x40 "Title screen music".
    var titleMusicPref = true
    /// `gPlayGame`: a game (or demo) is running — `_StartMusic` plays at the music volume then, and outside a game
    /// only when bool 0x40 is set.
    var gameRunning = false

    /// Per effect voice: the priority it was started at and a start serial (oldest = lowest).
    private var voicePriority = [Int](repeating: 0, count: effectVoices)
    private var voiceSerial = [Int](repeating: 0, count: effectVoices)
    private var serial = 0
    /// Sound ids already handed to the output.
    private var loaded: Set<Int> = []
    /// `gMusicLoaded`: the `snd` id `_LoadMusic` loaded, nil when unloaded.
    private(set) var musicID: Int?

    init(output: any BTXAudioOutput, sounds: SoundBankPCM, data: BTXGameData) {
        self.output = output
        self.sounds = sounds
        self.data = data
        for id in SoundBankPCM.effectIDs { upload(id) }
    }

    // MARK: Effects

    /// `_PlayMySnd`'s volume for short pref 0x33: 2 → 0x10, 3 → 0x40, 4 → 0x100; anything else (1 = off) plays
    /// nothing.
    static func sfxVolume(pref: Int) -> Float? {
        switch pref {
        case 2: 0x10
        case 3: 0x40
        case 4: 0x100
        default: nil
        }
    }

    /// `_StartMusic`'s volume for short pref 0x35: 1 → 0, 2 → 0x40, 3 → 0x80, 4 → 0x100.
    static func musicVolume(pref: Int) -> Float {
        switch pref {
        case 2: 0x40
        case 3: 0x80
        case 4: 0x100
        default: 0
        }
    }

    /// The voice an effect of `priority` takes (plan Q6 default — the Sound Tool's own rule is unrecovered, U5):
    /// a free voice; else steal the lowest-priority busy voice whose priority ≤ the new one (the oldest of equals);
    /// else nil (dropped).
    static func chooseVoice(priority: Int, busy: [Bool], priorities: [Int], serials: [Int]) -> Int? {
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

    /// `_PlayMySnd`. `sfxLevel` stands in for short 0x33 on this one play (the prefs Music popup's snd 13 is played
    /// with short 0x33 set to the music level for the call — `_PrefsDialog` case 0x1b).
    func play(_ cue: SoundCue, sfxLevel: Int? = nil) {
        guard let volume = Self.sfxVolume(pref: sfxLevel ?? sfxVolumePref) else { return }
        let id = 9000 + cue.slot
        guard SoundBankPCM.effectIDs.contains(id), loaded.contains(id) else { return }
        let busy = (0..<Self.effectVoices).map { output.isPlaying(voice: $0) }
        guard let voice = Self.chooseVoice(priority: cue.priority, busy: busy, priorities: voicePriority,
                                           serials: voiceSerial) else { return }
        serial += 1
        voicePriority[voice] = cue.priority
        voiceSerial[voice] = serial
        output.play(id: id, on: voice, volume: volume, loops: 1)
    }

    /// `ST_HaltSound(0)`: every effect channel stops (the music channel is not the Sound Tool's).
    func haltEffects() {
        for v in 0..<Self.effectVoices { output.stop(voice: v) }
    }

    // MARK: Music

    func apply(_ cue: MusicCue) {
        let voice = Self.musicVoice
        switch cue {
        case let .load(set):
            // `_LoadMusic(1)`: no-op while loaded; the named "Level set N music.1" resource.
            guard musicID == nil else { return }
            let id: Int
            do { id = try data.musicResourceID(set: set) } catch {
                NSLog("Bubble Trouble X: no music for set %d: %@", set, "\(error)")
                return
            }
            upload(id)
            if loaded.contains(id) { musicID = id }
        case .start:
            guard let id = musicID else { return }
            let volume: Float = gameRunning || titleMusicPref ? Self.musicVolume(pref: musicVolumePref) : 0
            output.play(id: id, on: voice, volume: volume, loops: Self.musicLoops)
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

    /// `_UpdateMusicVolume @ 0001b0d5` (the Music menu toggle, `_PrefsButton`): nothing unless music is loaded; out of
    /// a game with the music not playing → `_StartMusic`; else the channel's volume = 0 out of a game without bool 0x40,
    /// else short 0x35's (1 → 0, 2 → 0x40, 3 → 0x80, 4 → 0x100).
    func updateMusicVolume() {
        guard musicID != nil else { return }
        let voice = Self.musicVoice
        if !output.isPlaying(voice: voice) && !gameRunning {
            apply(.start)
            return
        }
        output.setVolume(voice: voice, !gameRunning && !titleMusicPref ? 0 : Self.musicVolume(pref: musicVolumePref))
    }

    /// Hands sound `id` to the output once (decoded by `SoundBankPCM`, prewarmed at launch).
    private func upload(_ id: Int) {
        guard !loaded.contains(id), let pcm = try? sounds.pcm(id) else { return }
        output.load(id: id, samples: pcm.samples, channels: pcm.channels, sampleRate: pcm.sampleRate)
        loaded.insert(id)
    }
}

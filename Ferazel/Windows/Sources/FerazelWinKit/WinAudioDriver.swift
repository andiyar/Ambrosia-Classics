import FerazelRender
import Foundation
import HectorAudio

/// The Windows mute switch's SDL side (D42, D43 Ruling 20): which SDL audio driver to force before any audio opens.
public enum WinAudioDriver {
    /// HectorSDL's own name for SDL_AUDIO_DRIVER (CrossOver strips SDL_*, `SDLHost.applyDriverOverridesFromEnvironment`).
    public static let driverEnvironment = "HECTOR_SDL_AUDIO_DRIVER"
    public static let dummy = "dummy"

    /// Muted — `--mute`, the hidden `-FerazelMute YES` (the Mac's argument-domain read) or `FERAZEL_MUTE=1`, all read
    /// by `WinArgs.parse` — → "dummy" (whatever else is asked); else `HECTOR_SDL_AUDIO_DRIVER` as given; else nil
    /// (SDL's default). From the PARSED arguments, so an option's value (`--data --mute`) is never read as a switch.
    /// The executable applies it with override priority after `SDLHost.applyDriverOverridesFromEnvironment()`,
    /// before any audio opens.
    public static func hint(arguments: WinArgs, environment: [String: String]) -> String? {
        if arguments.muted { return dummy }
        if let d = environment[driverEnvironment], !d.isEmpty { return d }
        return nil
    }
}

/// Where the executable plays a source (D43 Ruling 13): each `open` is one SDL playback stream on the default device
/// (`SDLAudioOut`; SDL3 mixes the streams). Foundation + HectorAudio only — the SDL half lives in `FerazelWin`.
@MainActor public protocol WinAudioDevice: AnyObject {
    /// Opens and starts a stream pulling `source`; false when the device cannot (the game then runs without it).
    func open(_ source: any PCMPullSource) -> Bool
}

/// Windows' `FerazelMixer` (Ruling 13): the music voice on a `PCMMixer(voices: 1, outputRate: 48000)` through one
/// stream, the Sound Tool (22,050 Hz) through a second — as the Mac's `ShellMixer.attachStream` puts it beside the
/// voice. Volumes are the Sound Manager's 8.8 fixed point (0x100 = unity), `PCMMixer`'s unit. Made only when the game
/// is neither muted nor headless (`FerazelDriver` never calls the factory then), so a muted game opens no device.
@MainActor final class WinMixer: FerazelMixer {
    static let musicVoices = 1
    static let musicRate = 48_000.0

    let music: PCMMixer
    private let device: any WinAudioDevice
    private let log: (String) -> Void

    /// Nil when the music stream cannot open (the game runs silent, as the Mac's with no `ShellMixer`).
    init?(device: any WinAudioDevice, log: @escaping (String) -> Void) {
        music = PCMMixer(voices: Self.musicVoices, outputRate: Self.musicRate)
        self.device = device
        self.log = log
        log("audio: opening the music stream")
        guard device.open(music) else {
            log("no sound: the audio device could not open")
            return nil
        }
    }

    func load(id: Int, samples: [Int16], channels: Int, sampleRate: Double) {
        log("music: load \(samples.count / max(channels, 1)) frames, \(channels) ch, \(Int(sampleRate)) Hz")
        music.load(id: id, samples: samples, channels: channels, sampleRate: sampleRate)
    }

    func play(id: Int, on voice: Int, volume: Float, loops: Int) {
        log("music: play")
        music.play(id: id, on: voice, volume: volume, loops: loops)
    }

    func stop(voice: Int) { music.stop(voice: voice) }
    func stopAll() { log("music: stop all"); music.stopAll() }
    func setVolume(voice: Int, _ volume: Float) { music.setVolume(voice: voice, volume) }

    func attach(stream: SoundTool) {
        log("audio: opening the sound-effects stream")
        if !device.open(stream) { log("no sound effects: their audio stream could not open") }
    }
}

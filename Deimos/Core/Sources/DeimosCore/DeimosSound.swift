import Foundation
import HectorAudio

/// Why a `soun` tag fails the original's load gate (beyond the kit's own `AudioFileError`s).
public enum DeimosSoundError: Error, Equatable, Sendable {
    /// An effect with 2 channels: the loader takes effects only when channels < 2
    /// (`FUN_100d1780`, bank sound-music.md §2.2; the music tracks are the stereo ones).
    case stereoEffect(channels: Int)
    /// The stored rate is not a positive finite number (the kit reports the COMM / `fmt ` rate as
    /// stored, so ±inf, NaN, ±0 and negative rates reach here). Refused rather than played at a
    /// rate nothing in the data shows (plan invariant 4; R-B review carry).
    case invalidSampleRate(Double)
}

/// The `soun` load gate (Deimos Phase 0 plan, Task C6; Research notes 20–22).
///
/// The original's `FUN_100d1780` (bank sound-music.md §2.2, sprite-sound-containers.md §4) accepts
/// AIFF/AIFC or RIFF/WAVE with compression `NONE` or `ima4`; effects (`soun` via `FUN_10047330`)
/// must also have channels < 2. Music streams the pak byte range itself through the Sound Manager
/// (no channel gate). The format rules (signature, codec, 1–2 channels, sizes) are HectorKit's
/// `SoundFile` / `AIFFAudio` / `WAVEAudio` (HectorKit D10), whose named `AudioFileError`s pass
/// through unchanged; this type adds only the game's own gate on top.
///
/// The PCM here is the KIT's decode (= CoreAudio's ima4, sample-exact vs `afconvert`), not the
/// game mixer's: the original re-packs ima4 into one continuous IMA nibble stream (drops every
/// packet header, carries predictor/index across packets, 66·P samples for P packets). That
/// faithful effect decode is Phase 1's (Research note 21).
public enum DeimosSound {
    /// An effect's bytes → mono linear PCM. The gate runs on the header BEFORE any decode (the
    /// original refuses at load, before conversion): signature dispatch is `SoundFile`'s
    /// (`FORM` → AIFF/AIFC, `RIFF`…`WAVE` → WAVE, else `AudioFileError.notAIFF`).
    public static func effectPCM(_ data: Data) throws -> SndPCM {
        let channels: Int, rate: Double, decode: () throws -> SndPCM
        if isRIFFWAVE(data) {
            let wave = try WAVEAudio(data: data)
            (channels, rate, decode) = (wave.channels, wave.sampleRate, wave.linearPCM)
        } else if data.starts(with: Array("FORM".utf8)) {
            let aiff = try AIFFAudio(data: data)
            (channels, rate, decode) = (aiff.channels, aiff.sampleRate, aiff.linearPCM)
        } else {
            throw AudioFileError.notAIFF
        }
        guard channels < 2 else { throw DeimosSoundError.stereoEffect(channels: channels) }
        try checkRate(rate)
        return try decode()
    }

    /// A music track's header (AIFF/AIFC only — the shipped tracks are stereo `ima4` AIFC): no
    /// channel gate; `soundData` is the byte range Phase 1 streams. Nothing is decoded.
    public static func musicInfo(_ data: Data) throws -> AIFFAudio {
        let aiff = try AIFFAudio(data: data)
        try checkRate(aiff.sampleRate)
        return aiff
    }

    private static func checkRate(_ rate: Double) throws {
        guard rate.isFinite, rate > 0 else { throw DeimosSoundError.invalidSampleRate(rate) }
    }

    /// `SoundFile`'s WAVE test: `RIFF` at 0 and `WAVE` at 8 (a shorter RIFF is not a WAVE → `notAIFF`).
    private static func isRIFFWAVE(_ data: Data) -> Bool {
        guard data.count >= 12 else { return false }
        let b = data.startIndex
        return data[b..<b + 4].elementsEqual("RIFF".utf8) && data[b + 8..<b + 12].elementsEqual("WAVE".utf8)
    }
}

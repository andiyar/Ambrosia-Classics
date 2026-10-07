import Foundation
import DeimosCore
import HectorAudio

/// Why a `soun` tag cannot be streamed as music.
public enum MusicStreamError: Error, Equatable, Sendable {
    /// Not `ima4` (every shipped track — `mu03`, `ammu`, `inmu` — is stereo AIFC `ima4` at 44.1 kHz). The original
    /// hands the bytes to the Sound Manager, which would also play PCM; no shipped track is PCM, so that path is
    /// refused by name rather than built untested.
    case notIMA4
    /// COMM declares no packets: nothing to stream.
    case empty
}

/// One music track as the streamer reads it: the SSND body (`FUN_100cfe64` → `FUN_100d0ef8`: the SSND start/length
/// inside the pak entry) with its COMM header. Immutable and never decoded whole (bank sound-music §6.3: "music is
/// never resident" in the original — here the compressed bytes are, and only one packet at a time is decoded).
public struct MusicTrack: Sendable {
    public let channels: Int
    /// COMM `numSampleFrames` = ima4 PACKETS per channel (the kit's `AIFFAudio.frameCount`); frames = 64 × packets.
    public let packets: Int
    public let sampleRate: Double
    /// The SSND body after its offset field (≥ packets × 34 × channels, checked by the kit's parser).
    let soundData: Data

    /// A `soun` tag's bytes through `DeimosSound.musicInfo` (AIFF/AIFC, positive finite rate, no channel gate).
    public init(soundFile data: Data) throws {
        let aiff = try DeimosSound.musicInfo(data)
        guard aiff.encoding == .ima4 else { throw MusicStreamError.notIMA4 }
        guard aiff.frameCount > 0 else { throw MusicStreamError.empty }
        channels = aiff.channels
        packets = aiff.frameCount
        sampleRate = aiff.sampleRate
        soundData = aiff.soundData
    }
}

/// The music streamer (M_Music.cpp + the library's double-buffer streamer, bank sound-music §6): one track,
/// decoded **on demand one ima4 packet at a time** into a buffer allocated when the stream is made (`.play`, on the
/// game thread), looped over the whole sound data, linearly resampled to 44.1 kHz when the file rate differs, and
/// added to the output at the music level. A value type with no locks: the engine holds it under its one `Mutex`;
/// after `init` nothing here allocates (plan A2, leg B I9 ruling a).
///
/// The decoder is Apple's `ima4` exactly as HectorKit's `IMA4` decodes it (the kit is the oracle in the tests): the
/// original played these bytes through the Sound Manager's own ima4 decompressor (`SndPlayDoubleBuffer` on a
/// sampled-synth channel, §6.3), not through the effects mixer's continuous-nibble decoder (§2.2) — so the
/// preamble re-sync rule of the kit (continue at full precision when the header agrees, else load the header) applies.
///
/// Loop (§6.3, `FUN_100d0968` resets the read position to the SSND start): the frame after the last is frame 0.
/// The decoder state is reset at the wrap (frame 0 decodes exactly as on the first pass). Whether the Sound
/// Manager carried its predictor across the wrap is not read (bank NOT RESOLVED #6, "the exact byte at which a
/// looping stream wraps"); with the kit's re-sync rule a carry could differ from the reset only in the low 7 bits
/// of the first packet's predictor — inaudible.
public struct MusicStream: Sendable {
    public let track: MusicTrack
    /// Every caller passes loop 1 (`FUN_10047f90` callers, §6.1); a non-looping stream goes silent at its end.
    public let loop: Bool
    /// `FUN_10048220(1)` (`rateCmd 0` with the rate saved, `FUN_100d039c`): the stream holds its sample.
    public internal(set) var paused = false
    /// A non-looping stream has output its last frame.
    public private(set) var ended = false
    /// The decoder has read past the last packet of a non-looping track (`b` is padding).
    private var exhausted = false
    private var bIsPad = false

    // Decoder (per channel; the kit's running state — index −1 = no packet decoded yet).
    private var runPredictor: [Int]
    private var runIndex: [Int]
    /// The packet decoded last, interleaved `64 × channels` Int16 — preallocated here, refilled in place.
    private var decoded: [Int16]
    /// The next packet (per channel) to decode, and the next frame of `decoded` to hand out (64 = none left).
    private var nextPacket = 0
    private var frameInPacket = IMA4.framesPerPacket

    // Linear resampler: output = a + (b − a)·frac; `step` = file rate / 44100.
    private let step: Double
    private var frac: Double = 0
    private var a: (Float, Float) = (0, 0)
    private var b: (Float, Float) = (0, 0)

    /// The output rate (`FUN_10047160` / `FUN_100d1400`: 44.1 kHz; the music channel plays at the file rate and the
    /// Sound Manager resamples — here linearly).
    public static let outputRate: Double = 44100

    /// `.play` (`FUN_100cfe64`): the stream starts at frame 0, playing. Allocates (call off the audio thread).
    public init(track: MusicTrack, loop: Bool) {
        self.track = track
        self.loop = loop
        runPredictor = [Int](repeating: 0, count: track.channels)
        runIndex = [Int](repeating: -1, count: track.channels)
        decoded = [Int16](repeating: 0, count: IMA4.framesPerPacket * track.channels)
        step = track.sampleRate / Self.outputRate
        let f0 = nextFrame(), f1 = nextFrame()
        a = (Float(f0.0), Float(f0.1))
        b = (Float(f1.0), Float(f1.1))
        bIsPad = exhausted
    }

    // MARK: Level (`FUN_100482c0`, `FUN_100d0470`, `FUN_100d136c`; bank §6.2)

    /// `FUN_100482c0(v)`: `clamp(128.0f × (float)v / 100.0f, 0, 128)` in single precision, `fctiwz` (listing
    /// `100482c0..1004831c`; table `0x100d7430` = {128.0, 100.0, 0.0}; `fcmpo; bge` / `fcmpo; ble` inclusive).
    public static func level(pref v: Int32) -> UInt16 {
        var f = Float(128) * (Float(v) / Float(100))      // 100482e8 fsubs (exact int→float); fdivs; fmuls
        if !(f >= 0) { f = 0 } else if f > 128 { f = 128 } // 100482f8 fcmpo f1,f0(0.0); bge — NaN takes the 0
        return UInt16(EffectMixer.fctiwz(f))               // 1004829c rlwinm r3,r3,0,16,31
    }

    /// `FUN_100d0470(m)` then `FUN_100d136c`: `m` capped at 0x100 (`100d048c cmplwi r0,0x100; bge → 0x100`),
    /// `amp = min(255, (m × fade) >> 8)` (`100d139c mullw; rlwinm …,24,8,31; cmplwi r31,0xff`). `fade` stays 0x100
    /// (data image `0x100e0730` = 0x00000100): the only fade is `stopMusic(fade: 1)` at quit (§6.2), not a cue.
    public static func amp(level m: UInt16, fade: UInt16 = 0x100) -> Int {
        let capped = UInt32(m >= 0x100 ? 0x100 : m)
        let v = (capped &* UInt32(fade)) >> 8
        return v >= 0xFF ? 0xFF : Int(v)
    }

    /// The `ampCmd` level as a linear gain: `amp / 255` (**Q3 default: 255 is full scale** — Inside Macintosh:
    /// Sound, 0–255; bank NOT RESOLVED #2). Music pref 100 → m 128 → amp 128 → 128/255 of a full effect.
    public static func gain(amp: Int) -> Float { Float(amp) / 255 }

    // MARK: Decode

    /// The next decoded frame of the track (L, R; mono → both), advancing through packets and the loop. A
    /// non-looping stream returns silence after its last frame. Non-allocating.
    mutating func nextFrame() -> (Int16, Int16) {
        if frameInPacket == IMA4.framesPerPacket {
            if nextPacket == track.packets {
                guard loop else { exhausted = true; return (0, 0) }
                nextPacket = 0                                        // FUN_100d0968: back to the SSND start
                for ch in 0..<track.channels { runIndex[ch] = -1; runPredictor[ch] = 0 }
            }
            decodePacket(nextPacket)
            nextPacket += 1
            frameInPacket = 0
        }
        let c = track.channels
        let o = frameInPacket * c
        frameInPacket += 1
        return c == 1 ? (decoded[o], decoded[o]) : (decoded[o], decoded[o + 1])
    }

    /// Packet-frame `p` (one 34-byte packet per channel, interleaved) into `decoded` — `IMA4.decode`'s arithmetic,
    /// in place: preamble = predictor high 9 bits + step index (clamped to 88); continue from the running predictor
    /// when the index matches and the header predictor is within 0x7F of it; low nibble first; shift-and-add diff;
    /// predictor clamped to Int16, index stepped and clamped 0…88.
    private mutating func decodePacket(_ p: Int) {
        let channels = track.channels
        // Move (not copy) the buffers out so the closures below touch locals only — no allocation, no overlap.
        var out: [Int16] = [], runP: [Int] = [], runI: [Int] = []
        swap(&out, &decoded); swap(&runP, &runPredictor); swap(&runI, &runIndex)
        track.soundData.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            out.withUnsafeMutableBufferPointer { dst in
                for ch in 0..<channels {
                    let base = (p * channels + ch) * IMA4.packetBytes
                    let preamble = Int(raw[base]) << 8 | Int(raw[base + 1])
                    let headerPredictor = Int(Int16(truncatingIfNeeded: preamble & 0xFF80))
                    let headerIndex = min(preamble & 0x7F, 88)
                    var predictor = headerPredictor
                    var index = headerIndex
                    if runI[ch] == headerIndex && abs(headerPredictor - runP[ch]) <= 0x7F {
                        predictor = runP[ch]                          // continue at full precision
                    }
                    var stepSize = Self.stepTable[index]
                    var o = ch
                    for i in 0..<64 {
                        let byte = Int(raw[base + 2 + (i >> 1)])
                        let nibble = i & 1 == 0 ? byte & 0x0F : byte >> 4     // low nibble first
                        var diff = stepSize >> 3
                        if nibble & 4 != 0 { diff += stepSize }
                        if nibble & 2 != 0 { diff += stepSize >> 1 }
                        if nibble & 1 != 0 { diff += stepSize >> 2 }
                        predictor += (nibble & 8 != 0) ? -diff : diff
                        predictor = min(max(predictor, -32768), 32767)
                        index = min(max(index + Self.indexTable[nibble], 0), 88)
                        stepSize = Self.stepTable[index]
                        dst[o] = Int16(predictor)
                        o += channels
                    }
                    runP[ch] = predictor
                    runI[ch] = index
                }
            }
        }
        swap(&out, &decoded); swap(&runP, &runPredictor); swap(&runI, &runIndex)
    }

    // MARK: Output

    /// Adds `frames` resampled frames × `gain` into interleaved stereo float32 `buffer` (Int16 / 32768), each
    /// sum clamped to ±1 (the two Sound Manager channels meet in the output mixer; full scale is its limit). A
    /// paused or ended stream adds nothing and does not advance. Audio thread: non-allocating.
    public mutating func mix(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int, gain: Float) {
        guard !paused else { return }
        for f in 0..<frames {
            if ended { return }
            let l = (a.0 + (b.0 - a.0) * Float(frac)) / 32768
            let r = (a.1 + (b.1 - a.1) * Float(frac)) / 32768
            buffer[2 * f] = Self.clamp(buffer[2 * f] + l * gain)
            buffer[2 * f + 1] = Self.clamp(buffer[2 * f + 1] + r * gain)
            frac += step
            while frac >= 1 {
                frac -= 1
                if bIsPad { ended = true; return }
                a = b
                let n = nextFrame()
                b = (Float(n.0), Float(n.1))
                bIsPad = exhausted
            }
        }
    }

    @inline(__always)
    static func clamp(_ v: Float) -> Float { v > 1 ? 1 : (v < -1 ? -1 : v) }

    // The standard IMA tables (as the kit's `IMA4`, whose tables are internal).
    private static let indexTable: [Int] = [-1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8]
    private static let stepTable: [Int] = Voice.stepTable.map { Int($0) }
}

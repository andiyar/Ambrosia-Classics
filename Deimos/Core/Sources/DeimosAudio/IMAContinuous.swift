import Foundation
import DeimosCore
import HectorAudio

/// Why a `soun` tag cannot become a mixer sound.
public enum IMAContinuousError: Error, Equatable, Sendable {
    /// An effect with 2 channels (`FUN_100d1780` `100d1870`: channels ≤ 1, else −0x1b5b).
    case stereoEffect(channels: Int)
    /// Not `ima4`. The original re-encodes 8/16-bit PCM to IMA (`FUN_100d3170`, the `100d1e74…100d2138`
    /// branches of `FUN_100d1d90`); every shipped effect is `ima4` (bank sound-music §2.2), so that encoder is
    /// not modelled — a PCM effect is refused by name instead of being played some other way.
    case pcmNotModelled
    /// A RIFF/WAVE effect: accepted by the original's gate, never shipped (all 96 effects are AIFC `ima4`).
    case waveNotModelled
    /// `ima4` whose COMM sample size is not 16: `FUN_100d1d90` takes the `ima4` path only when `+8 == 16`
    /// (`100d1db4 lhz r0,0x8(r31); cmplwi r0,0x10; bne`) and otherwise falls into the PCM re-encoder, reading the
    /// IMA bytes as PCM — never shipped (all 96 effects say 16), refused by name.
    case imaSampleSize(Int)
    /// A rate whose 16.16 value is 0 (0, negative, NaN, or below 1/65536 Hz). The original would load it and
    /// `FixDiv(44100, 0)` = 0 (`FUN_1006e2b0` `1006e2d0`) gives step 0: a voice that decodes silently and ends.
    /// No shipped effect has one (all 44100 Hz); refused rather than played as an invisible voice.
    case invalidRate(Double)
}

/// The mixer's in-memory sound: Apple `ima4` turned into ONE continuous IMA nibble stream — the
/// `{'asnd', sampleCount, rate, 'mIMA'}` block built by `FUN_100d1d90` (called from `FUN_100d1780` at
/// `100d1888`). Bank sound-music §2.2 (MED on the dump; re-read on the listing for Phase 2 A1, below).
///
/// Listing `FUN_100d1d90` (disassembled for A1 with `DisasmRange.java`; there was no listing before):
/// * Gate `100d1da4..100d1dbc`: compression `'ima4'` (`subis r0,r3,0x696d; cmplwi r0,0x6134`) AND sample size
///   16 (`lhz r0,0x8(r31); cmplwi r0,0x10`) — otherwise the PCM → IMA path.
/// * `bytes` = input `+0x10` = the SSND chunk size − 8 − its offset field (`FUN_100d2400` `100d2674..100d2684`):
///   the WHOLE SSND body after the offset, not COMM's packet count × 34. HectorKit's `AIFFAudio.soundData` is
///   exactly that range.
/// * `100d1dc0..100d1dd8`: `r30 = bytes / 34` (`mulhwu` by 0xF0F0F0F1, `>> 5`); the block is
///   `bytes + 16 − bytes/34` bytes, allocated and then zeroed (`100d1ddc..100d1dfc`).
/// * Loop `100d1e28..100d1e64`, `bytes >> 1` big-endian 16-bit words `w`, word index `k` from 0:
///   `k % 17 == 0` → skipped (**word 0 of every 34-byte packet — the predictor/step-index header — is dropped**;
///   `mulhwu` /17, `mulli 0x11`, `subf.`, `beq`); else stored as `((w << 4) & 0xF0F0) | ((w >> 4) & 0x0F0F)` —
///   **the two nibbles of every byte swapped** (`rlwinm r3,r8,4,12,27; andi. 0xf0f0` / `rlwinm r0,r8,28,20,31;
///   andi. 0x0f0f`). An odd final byte is not copied (word count `bytes >> 1`).
/// * `100d1e68..100d1e6c`: `sampleCount = (bytes − bytes/34) × 2` (= 66·P for P packets: only 64·P samples carry
///   data; the last 2·P nibbles are the zeroed tail of the block, bank §2.2).
/// * Header `100d215c..100d217c`: `+0 'asnd'`, `+4 sampleCount`, `+8` the input rate (16.16 Fixed: COMM's 80-bit
///   rate × 65536 converted to an integer, `FUN_100d2400` `100d26a4..100d26b0`), `+0xC 'mIMA'`; data at `+0x10`.
///
/// Nibble order: the decoder `FUN_100d32d0` reads big-endian 32-bit words and takes nibble `pos` at shift
/// `28 − 4·(pos & 7)` (`100d3318..100d3330`, `100d3360`) = the HIGH nibble of each byte first. After the swap that is
/// Apple's low nibble — so the decode order equals Apple's; the swap only re-packs for the word reader.
public struct IMAContinuous: Sendable, Equatable {
    /// One Apple `ima4` packet: a 2-byte header + 32 bytes of nibbles (64 samples).
    public static let packetBytes = 34

    /// The declared sample count (`asnd+4`): `(bytes − bytes/34) × 2`.
    public let sampleCount: UInt32
    /// The sound's rate as 16.16 Fixed (`asnd+8`); 44100 Hz = 0xAC44_0000.
    public let rate: UInt32
    /// The continuous nibble stream (`asnd+0x10…`), `bytes − bytes/34` bytes, zero tail included; high nibble first.
    public let bytes: [UInt8]

    /// `FUN_100d1d90`'s `ima4` branch over an SSND body (`soundData`), at a 16.16 `rate`.
    public init(ima4 soundData: Data, rate: UInt32) {
        let byteCount = soundData.count
        let packets = byteCount / Self.packetBytes
        let dataBytes = byteCount - packets                     // block size − 16 header bytes
        var out = [UInt8](repeating: 0, count: dataBytes)       // the zeroed block
        let words = byteCount >> 1
        var o = 0
        soundData.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            for k in 0..<words where k % 17 != 0 {
                let hi = raw[2 * k], lo = raw[2 * k + 1]
                out[o] = Self.swapNibbles(hi)
                out[o + 1] = Self.swapNibbles(lo)
                o += 2
            }
        }
        self.bytes = out
        self.sampleCount = UInt32(truncatingIfNeeded: dataBytes * 2)
        self.rate = rate
    }

    /// A ready-made continuous stream (synthetic sounds in tests; the shape `FUN_100d1d90` produces).
    public init(nibbleBytes: [UInt8], sampleCount: UInt32, rate: UInt32 = 0xAC44_0000) {
        self.bytes = nibbleBytes
        self.sampleCount = sampleCount
        self.rate = rate
    }

    /// A `soun` tag's file bytes through the original's effect load (`FUN_100d1780`: AIFF/AIFC, channels ≤ 1,
    /// `NONE`/`ima4`), then the `ima4` conversion. The kit's `AIFFAudio` parses the header (HectorKit D10).
    public init(soundFile data: Data) throws {
        if DeimosSound.isRIFFWAVE(data) { throw IMAContinuousError.waveNotModelled }
        let aiff = try AIFFAudio(data: data)
        guard aiff.channels < 2 else { throw IMAContinuousError.stereoEffect(channels: aiff.channels) }
        guard aiff.encoding == .ima4 else { throw IMAContinuousError.pcmNotModelled }
        let size = Self.commSampleSize(data)
        guard size == 16 else { throw IMAContinuousError.imaSampleSize(size) }
        let rate = Self.fixedRate(aiff.sampleRate)
        guard rate != 0 else { throw IMAContinuousError.invalidRate(aiff.sampleRate) }
        self.init(ima4: aiff.soundData, rate: rate)
    }

    /// The first COMM chunk's `sampleSize` (signed 16-bit at body + 6), the field `FUN_100d2400` copies to the
    /// converter's `+8` (`100d266c lha r4,0x6a(r1); sth r4,0x8(r29)`); −1 when absent (the kit has already
    /// refused a file without COMM). `AIFFAudio` does not expose it for `ima4`.
    static func commSampleSize(_ data: Data) -> Int {
        let b = [UInt8](data)
        func u32(_ o: Int) -> Int { Int(b[o]) << 24 | Int(b[o + 1]) << 16 | Int(b[o + 2]) << 8 | Int(b[o + 3]) }
        var o = 12
        while o + 8 <= b.count {
            let size = u32(o + 4)
            if b[o..<o + 4].elementsEqual("COMM".utf8) {
                guard o + 16 <= b.count else { return -1 }
                return Int(Int16(bitPattern: UInt16(b[o + 14]) << 8 | UInt16(b[o + 15])))
            }
            o += 8 + size + (size & 1)
        }
        return -1
    }

    /// The rate as 16.16 Fixed: `rate × 65536` truncated (`FUN_100d2400` `100d26a4 lfd; fmul; bl 0x1004d5c0`).
    public static func fixedRate(_ hz: Double) -> UInt32 {
        let v = (hz * 65536).rounded(.towardZero)
        guard v.isFinite, v > 0 else { return 0 }
        return v >= 4_294_967_295 ? .max : UInt32(v)
    }

    /// Nibble `pos` of the stream (high nibble of byte `pos/2` first); past the block → 0 (the zeroed tail).
    @inline(__always)
    public func nibble(at pos: UInt32) -> UInt8 {
        let i = Int(pos >> 1)
        guard i < bytes.count else { return 0 }
        return pos & 1 == 0 ? bytes[i] >> 4 : bytes[i] & 0x0F
    }

    @inline(__always)
    static func swapNibbles(_ b: UInt8) -> UInt8 { (b << 4) | (b >> 4) }
}

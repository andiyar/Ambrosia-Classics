import Foundation
import DeimosCore

/// The game's own software effects mixer — the statically linked sound library under M_Sound.cpp (bank
/// sound-music §1–§3): ONE stereo 16-bit 44.1 kHz output fed in 1024-frame blocks, a ranked list of up to 16
/// voices of which only the first `numChannels` (flli 38 `SoundNumChannels` = 8) are heard, every sound an
/// in-memory continuous-IMA stream (`IMAContinuous`).
///
/// A value type with no locks: the engine (A2) holds it under its one `Mutex` and pulls it on the audio thread.
/// After `register` (load time) nothing here allocates — the voice table, the block and the sound table are
/// preallocated; `play`, `mixBlock` and `render` only mutate in place.
///
/// Not modelled (each unreachable with shipped data, bank §2.3 step 4 / §2.4 / §8 "implementation detail"):
/// the on-demand load of a sound that was not preloaded (and its wrong-sound bug — the engine preloads every
/// effect, A2), the completion callbacks (Deimos passes none), the PCM → IMA encoder, the `data pointer == x`
/// arm of `FUN_100d1b30`/`FUN_100d1be0` (an `asnd` address never equals a voice id).
public struct EffectMixer: Sendable {
    /// The voice-list size (`memset 0x380` = 16 × 0x38, `100d1524`; insertion refuses at 16, `100d19bc`).
    public static let voiceSlots = 16
    /// Frames per mix block (`FUN_100d1400` `100d1574 li r5,0x400`).
    public static let blockFrames = 1024
    /// The output rate as 16.16 Fixed: 44100 (`FUN_10047160` `100471e8 lis r4,-0x53bc` = 0xAC44 << 16).
    public static let outputRate: UInt32 = 0xAC44_0000

    /// One loaded sound record (`FUN_10047330`: `{magic, id, asnd*, lastVoice = −1}`).
    struct Record: Sendable {
        var id: FourCC
        var sound: Int
        /// `+0xC`: the id `FUN_100d18d0` returned for the last start (0 when refused); −1 never played.
        var lastVoice: UInt32
    }

    /// The mixer request built by `FUN_10047bf0` on its stack (`10047d88..10047e10`).
    struct Request {
        var sound: Int
        var id: UInt32 = 0
        var pitch: UInt32
        var priority: UInt16
        var gainLeft: UInt16
        var gainRight: UInt16
    }

    /// The audible limit (`0x100dee74`): `numChannels & 0xFFFF`, capped at 16 (`100d14ec..100d150c`).
    public let audibleVoices: Int
    /// Live voices (`0x100dee6c`).
    public private(set) var voiceCount = 0
    private var voices = [Voice](repeating: .empty, count: EffectMixer.voiceSlots)
    /// The voice-id counter (`0x100dee..` via TOC `r2−0x74c0`): starts at 1 (`100d1520`), +2 per voice.
    private var nextVoiceID: UInt32 = 1
    private var sounds: [IMAContinuous] = []
    private var records: [Record] = []
    /// The current mixed block, interleaved L R Int16, and how many of its frames `render` has handed out.
    public private(set) var block = [Int16](repeating: 0, count: 2 * EffectMixer.blockFrames)
    private var blockCursor = EffectMixer.blockFrames

    public init(numChannels: Int = 8) {
        let n = numChannels & 0xFFFF
        audibleVoices = n > 16 ? 16 : n
    }

    // MARK: Load

    /// Load a sound under a `soun` id (`FUN_10047330`: the record is appended; lookups walk from the front).
    public mutating func register(_ id: FourCC, _ sound: IMAContinuous) {
        sounds.append(sound)
        records.append(Record(id: id, sound: sounds.count - 1, lastVoice: 0xFFFF_FFFF))
    }

    // MARK: The play primitive (M_Sound.cpp)

    /// `FUN_10047bf0` (listing `10047bf0..10047e34`, bank §2.3) for one cue. Returns the voice id the mixer gave
    /// (0 = refused by a full list) or nil when nothing reached the mixer: id `none`, an `allowMultiple == false`
    /// cue whose last instance still lives (`10047c40`, `FUN_100476e0`), or an unregistered id.
    @discardableResult
    public mutating func play(_ cue: SoundCue) -> UInt32? {
        guard cue.id != .none else { return nil }
        if !cue.allowMultiple, isPlaying(cue.id) { return nil }
        let p = UInt32(bitPattern: cue.priority) & 0xFF                    // 10047c54 rlwinm r0,r27,0,24,31
        let priority = UInt16(p > 100 ? 100 : p)                            // cmplwi r0,0x64; ble; li r27,0x64
        guard let r = recordIndex(cue.id) else { return nil }
        let gain = Self.gain(volume: cue.volume)
        let request = Request(sound: records[r].sound, pitch: Self.pitch16(cue.pitch), priority: priority,
                              gainLeft: gain, gainRight: gain)
        let id = start(request)
        records[r].lastVoice = id                                           // 10047e1c stw r3,0xc(r29)
        return id
    }

    /// `FUN_100476e0`: the record's LAST started voice is still in the list — `FUN_100d1b30(record+0xC) != 0`,
    /// which also counts every voice when `+0xC` is 0 (a refused start; bank §2.4).
    public func isPlaying(_ id: FourCC) -> Bool {
        guard id != .none, let r = recordIndex(id) else { return false }
        return count(matching: records[r].lastVoice) != 0
    }

    /// `FUN_100476a0` → `FUN_100d1be0(0)`: stop every effect voice now.
    public mutating func stopAll() { stop(matching: 0) }

    /// 128·volume/100 in single precision, truncated (`10047dcc fdivs` then `10047de0 fmuls; fctiwz`), stored
    /// as a halfword: 100 → 128, 90 → 115, 80 → 102, 75 → 96, 70 → 89, 50 → 64 (bank §2.3). The mixer clamps
    /// anything above 0x80 (`100d1930`).
    public static func gain(volume: Int32) -> UInt16 {
        UInt16(truncatingIfNeeded: fctiwz(Float(128) * (Float(volume) / Float(100))))
    }

    /// `(int)(65536.0f × pitch)` (`10047d98 lfs f0,0x10(r30)` = 65536.0; `fmuls`; `fctiwz`) as the request's 16.16.
    public static func pitch16(_ pitch: Float) -> UInt32 {
        UInt32(bitPattern: fctiwz(Float(65536) * pitch))
    }

    // MARK: The voice list (sound library)

    /// `FUN_100d18d0` (listing `100d18d0..100d1b20`, bank §3.1): ranked insertion. Returns the new voice id, or 0
    /// when the new voice ranks below all 16 (refused, nothing evicted).
    mutating func start(_ r: Request) -> UInt32 {
        guard r.sound >= 0, r.sound < sounds.count else { return 0 }         // 100d1900: no data → 0
        let priority = r.priority < 1 ? 1 : r.priority                       // 100d191c
        let gainL = r.gainLeft > 0x80 ? 0x80 : r.gainLeft                    // 100d1940 (+0x16)
        let gainR = r.gainRight > 0x80 ? 0x80 : r.gainRight                  // 100d192c (+0x18)
        let sum = Int32(gainL) + Int32(gainR)
        var i = 0
        // A slot is live iff its data pointer is set (100d19b0) — slots ≥ voiceCount are zeroed.
        while i < Self.voiceSlots, i < voiceCount {
            let v = voices[i]
            if priority < v.priority { i += 1; continue }                     // 100d1978 cmplw; blt → next
            if sum < Int32(v.gainLeft) + Int32(v.gainRight) { i += 1; continue }   // 100d1998 cmpw; blt → next
            break                                                             // equals-or-beats on both: here
        }
        if i >= Self.voiceSlots { return 0 }                                  // 100d19cc..100d19e4
        if voiceCount >= Self.voiceSlots { voiceCount = Self.voiceSlots - 1 } // 100d19ec: the 16th is overwritten
        var j = voiceCount
        while j > i { voices[j] = voices[j - 1]; j -= 1 }                     // BlockMoveData(i → i+1)
        let ratio = Self.fixDiv(Self.outputRate, sounds[r.sound].rate)
        let id: UInt32
        if r.id != 0 { id = r.id } else { id = nextVoiceID; nextVoiceID &+= 2 }   // 100d1acc..100d1aec
        voices[i] = Voice(id: id, sound: r.sound, step: Self.fixMul(ratio, r.pitch), ratio: ratio, predictor: 0,
                          stepIndex: 0, position: 0, total: sounds[r.sound].sampleCount, lastLeft: 0, lastRight: 0,
                          gainLeft: gainL, gainRight: gainR, priority: priority, finished: false)
        voiceCount += 1
        return id
    }

    /// `FUN_100d1b30`: voices whose id is `x`, or all when `x == 0`.
    func count(matching x: UInt32) -> Int {
        var c = 0
        for i in 0..<voiceCount where voices[i].id == x || x == 0 { c += 1 }
        return c
    }

    /// `FUN_100d1be0(x)` (listing `100d1c30..100d1cc4`): remove the voices whose id is `x` (all when 0), compacting.
    mutating func stop(matching x: UInt32) {
        var i = 0
        while i < voiceCount {
            if voices[i].id == x || x == 0 { remove(at: i) } else { i += 1 }
        }
    }

    /// `FUN_100d1cf0(i)`: count −1, shift the voices below up, zero the freed slot.
    private mutating func remove(at i: Int) {
        voiceCount -= 1
        var j = i
        while j < voiceCount { voices[j] = voices[j + 1]; j += 1 }
        voices[voiceCount] = .empty
    }

    /// The live voices, top (most audible) first.
    public func voice(at i: Int) -> Voice { voices[i] }

    // MARK: Mixing

    /// `FUN_100d21a0` (listing `100d21a0..100d233c`, bank §3.2): zero the block; every voice `i < voiceCount` runs
    /// `FUN_100d32d0` — mixed when `i < audibleVoices` (`100d21f0 cmpw r26,r0; bge`), else advanced silently;
    /// then every finished voice is removed (`FUN_100d1cf0`), which moves the voices below it up.
    public mutating func mixBlock() {
        var out: [Int16] = []
        swap(&out, &block)                       // move, not copy: the block keeps its one allocation
        out.withUnsafeMutableBufferPointer { buf in
            buf.update(repeating: 0)
            let base = buf.baseAddress!
            for i in 0..<voiceCount {
                let sound = sounds[voices[i].sound]
                voices[i].finished = voices[i].render(sound, into: i < audibleVoices ? base : nil,
                                                      frames: Self.blockFrames)
            }
        }
        swap(&out, &block)
        var i = 0
        while i < voiceCount {
            if voices[i].finished { remove(at: i) } else { i += 1 }
        }
    }

    /// Interleaved stereo float32 (`frames × 2` values, overwritten), Int16 / 32768, pulled from 1024-frame
    /// blocks whatever `frames` is (a new block is mixed when the current one is used up).
    public mutating func render(into buffer: UnsafeMutableBufferPointer<Float>, frames: Int) {
        var f = 0
        while f < frames {
            if blockCursor == Self.blockFrames { mixBlock(); blockCursor = 0 }
            let take = min(frames - f, Self.blockFrames - blockCursor)
            for k in 0..<take {
                let s = 2 * (blockCursor + k), d = 2 * (f + k)
                buffer[d] = Float(block[s]) / 32768
                buffer[d + 1] = Float(block[s + 1]) / 32768
            }
            blockCursor += take
            f += take
        }
    }

    // MARK: Fixed-point helpers (the library's own, not the Toolbox's)

    /// `FUN_1006e250`: unsigned 32×32 → 64, `>> 16`, truncated; 0 if either is 0; overflow → 0xFFFFFFFF.
    static func fixMul(_ a: UInt32, _ b: UInt32) -> UInt32 {
        guard a != 0, b != 0 else { return 0 }
        let p = UInt64(a) * UInt64(b)
        return p >> 48 != 0 ? 0xFFFF_FFFF : UInt32(truncatingIfNeeded: p >> 16)
    }

    /// `FUN_1006e2b0`: `(a << 16) / b` in 64 bits, truncated; 0 if either is 0; overflow → 0xFFFFFFFF.
    static func fixDiv(_ a: UInt32, _ b: UInt32) -> UInt32 {
        guard a != 0, b != 0 else { return 0 }
        let q = (UInt64(a) << 16) / UInt64(b)
        return q >> 32 != 0 ? 0xFFFF_FFFF : UInt32(q)
    }

    /// PowerPC `fctiwz`: toward zero, saturating; NaN → 0x80000000.
    static func fctiwz(_ f: Float) -> Int32 {
        let d = Double(f)
        if d.isNaN { return Int32.min }
        if d >= 2_147_483_647 { return Int32.max }
        if d <= -2_147_483_648 { return Int32.min }
        return Int32(d.rounded(.towardZero))
    }

    private func recordIndex(_ id: FourCC) -> Int? {
        for i in 0..<records.count where records[i].id == id { return i }
        return nil
    }
}

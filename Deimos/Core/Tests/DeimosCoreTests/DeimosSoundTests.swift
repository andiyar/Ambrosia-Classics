import XCTest
import HectorAudio
import HectorResources
@testable import DeimosCore

/// `DeimosSound` — the original's `soun` load gate (`FUN_100d1780`, bank sound-music.md §2.2,
/// sprite-sound-containers.md §4) over HectorKit's `SoundFile` / `AIFFAudio` / `WAVEAudio`
/// (Deimos Phase 0 plan, Task C6; Research notes 20–22).
final class DeimosSoundTests: XCTestCase {

    private let soun = FourCC("soun")!

    /// The `soun` records stored in one pak, in index order.
    private func sounds(inPak name: String) throws -> [TagIndex.Record] {
        let index = try RealData.index()
        return index.records(ofType: soun).filter {
            guard case .pak(let archive, _) = $0.source else { return false }
            return index.paks[archive].lastPathComponent == name
        }
    }

    // MARK: Real data

    func testNinetySixEffectsPassTheGate() throws {
        let index = try RealData.index()
        let effects = try sounds(inPak: "Audio.pak")
        XCTAssertEqual(effects.count, 96)
        var totalFrames = 0
        for record in effects {
            let pcm = try DeimosSound.effectPCM(try index.data(for: record))
            XCTAssertEqual(pcm.channels, 1, record.displayName)
            XCTAssertEqual(pcm.sampleRate, 44100, record.displayName)
            XCTAssertEqual(pcm.samples.count, pcm.frames, record.displayName)
            totalFrames += pcm.frames
        }
        XCTAssertEqual(totalFrames, 3_133_376)
    }

    func testThreeMusicTracksAreStereoAndRejectedAsEffects() throws {
        let index = try RealData.index()
        let music = try sounds(inPak: "Music.pak")
        XCTAssertEqual(music.count, 3)
        var packets: [Int] = []
        for record in music {
            let data = try index.data(for: record)
            let info = try DeimosSound.musicInfo(data)
            XCTAssertEqual(info.channels, 2, record.displayName)
            XCTAssertEqual(info.encoding, .ima4, record.displayName)
            XCTAssertEqual(info.sampleRate, 44100, record.displayName)
            packets.append(info.frameCount)
            // One decoded track at a time at most (plan invariant 15): the gate refuses before keeping any PCM.
            XCTAssertThrowsError(try DeimosSound.effectPCM(data), record.displayName) {
                XCTAssertEqual($0 as? DeimosSoundError, .stereoEffect(channels: 2), record.displayName)
            }
        }
        XCTAssertEqual(packets, [134_892, 23_966, 41_153])
    }

    // MARK: Synthetic

    func testSyntheticWAVEEffectAccepted() throws {
        let samples: [Int16] = [0, 1000, -1000, 32767, -32768, 7]
        let pcm = try DeimosSound.effectPCM(Self.wave(channels: 1, rate: 22050, samples: samples))
        XCTAssertEqual(pcm, SndPCM(sampleRate: 22050, channels: 1, frames: 6, samples: samples))

        // The same file in stereo is refused by the gate (channels < 2), not by the kit.
        XCTAssertThrowsError(try DeimosSound.effectPCM(Self.wave(channels: 2, rate: 22050, samples: samples))) {
            XCTAssertEqual($0 as? DeimosSoundError, .stereoEffect(channels: 2))
        }
    }

    func testSyntheticUnsupportedCodecRejected() throws {
        // AIFC codecs other than NONE/ima4 (the kit names them; the gate lets the named error through).
        for codec in ["sowt", "fl32", "MAC3", "ulaw"] {
            let data = Self.aiff(compression: codec, sampleSize: 16, rate: Self.ext44100, samples: [0, 0])
            XCTAssertThrowsError(try DeimosSound.effectPCM(data), codec) {
                XCTAssertEqual($0 as? AudioFileError, .unsupportedCompression(codec), codec)
            }
            XCTAssertThrowsError(try DeimosSound.musicInfo(data), codec) {
                XCTAssertEqual($0 as? AudioFileError, .unsupportedCompression(codec), codec)
            }
        }
        // A WAVE that is not PCM (tag 2 = MS ADPCM).
        XCTAssertThrowsError(try DeimosSound.effectPCM(Self.wave(channels: 1, rate: 22050, samples: [0], formatTag: 2))) {
            XCTAssertEqual($0 as? AudioFileError, .unsupportedCompression("wav 0x0002"))
        }
        // Neither AIFF/AIFC nor RIFF/WAVE.
        let junk = Data("OggS\u{0}\u{2}not a sound".utf8)
        XCTAssertThrowsError(try DeimosSound.effectPCM(junk)) { XCTAssertEqual($0 as? AudioFileError, .notAIFF) }
        XCTAssertThrowsError(try DeimosSound.musicInfo(junk)) { XCTAssertEqual($0 as? AudioFileError, .notAIFF) }
        // Music streams AIFF/AIFC only: a WAVE is not a music track.
        XCTAssertThrowsError(try DeimosSound.musicInfo(Self.wave(channels: 2, rate: 22050, samples: [0, 0]))) {
            XCTAssertEqual($0 as? AudioFileError, .notAIFF)
        }
    }

    /// R-B review carry: the kit reports rates as stored (inf / NaN / ±0 / negative are possible);
    /// the gate refuses `!rate.isFinite || rate <= 0` by name, for effects and music alike.
    func testSyntheticNonFiniteOrNonPositiveRateRejected() throws {
        let rates: [(String, [UInt8])] = [
            ("+inf", [0x7F, 0xFF, 0x80, 0, 0, 0, 0, 0, 0, 0]),
            ("-inf", [0xFF, 0xFF, 0x80, 0, 0, 0, 0, 0, 0, 0]),
            ("NaN", [0x7F, 0xFF, 0xC0, 0, 0, 0, 0, 0, 0, 0]),
            ("+0", [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            ("-0", [0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            ("-44100", [0xC0, 0x0E, 0xAC, 0x44, 0, 0, 0, 0, 0, 0]),
        ]
        for (label, ext) in rates {
            let data = Self.aiff(compression: "NONE", sampleSize: 16, rate: ext, samples: [1, 2])
            XCTAssertThrowsError(try DeimosSound.effectPCM(data), label) { Self.assertBadRate($0, label) }
            XCTAssertThrowsError(try DeimosSound.musicInfo(data), label) { Self.assertBadRate($0, label) }
        }
        XCTAssertThrowsError(try DeimosSound.effectPCM(Self.wave(channels: 1, rate: 0, samples: [1]))) {
            Self.assertBadRate($0, "WAVE 0 Hz")
        }
        // Control: the same AIFC at +44100 passes.
        let ok = Self.aiff(compression: "NONE", sampleSize: 16, rate: Self.ext44100, samples: [1, 2])
        XCTAssertEqual(try DeimosSound.effectPCM(ok), SndPCM(sampleRate: 44100, channels: 1, frames: 2, samples: [1, 2]))
        XCTAssertEqual(try DeimosSound.musicInfo(ok).sampleRate, 44100)
    }

    // MARK: Builders

    static let ext44100: [UInt8] = [0x40, 0x0E, 0xAC, 0x44, 0, 0, 0, 0, 0, 0]

    private static func assertBadRate(_ error: Error, _ label: String,
                                      file: StaticString = #filePath, line: UInt = #line) {
        guard case .invalidSampleRate = error as? DeimosSoundError else {
            return XCTFail("\(label): expected invalidSampleRate, got \(error)", file: file, line: line)
        }
    }

    private static func be16(_ v: Int) -> [UInt8] { [UInt8(truncatingIfNeeded: v >> 8), UInt8(truncatingIfNeeded: v)] }
    private static func be32(_ v: Int) -> [UInt8] { [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: v >> $0) } }
    private static func le16(_ v: Int) -> [UInt8] { [UInt8(truncatingIfNeeded: v), UInt8(truncatingIfNeeded: v >> 8)] }
    private static func le32(_ v: Int) -> [UInt8] { [0, 8, 16, 24].map { UInt8(truncatingIfNeeded: v >> $0) } }

    /// A mono FORM/AIFC: FVER, COMM (with `compression`), SSND of big-endian 16-bit `samples`.
    static func aiff(compression: String, sampleSize: Int, rate: [UInt8], samples: [Int16]) -> Data {
        var comm = be16(1) + be32(samples.count) + be16(sampleSize) + rate + Array(compression.utf8)
        comm += [0, 0]                                     // empty Pascal name, padded to even
        let sound = samples.flatMap { be16(Int(UInt16(bitPattern: $0))) }
        let ssnd = be32(0) + be32(0) + sound
        var body = Array("AIFC".utf8)
        body += Array("FVER".utf8) + be32(4) + [0xA2, 0x80, 0x51, 0x40]
        body += Array("COMM".utf8) + be32(comm.count) + comm
        body += Array("SSND".utf8) + be32(ssnd.count) + ssnd
        return Data(Array("FORM".utf8) + be32(body.count) + body)
    }

    /// A RIFF/WAVE with a 16-byte `fmt ` (format tag, 16-bit) and little-endian `samples`.
    static func wave(channels: Int, rate: Int, samples: [Int16], formatTag: Int = 1) -> Data {
        let fmt = le16(formatTag) + le16(channels) + le32(rate) + le32(rate * channels * 2) + le16(channels * 2) + le16(16)
        let sound = samples.flatMap { le16(Int(UInt16(bitPattern: $0))) }
        var body = Array("WAVE".utf8)
        body += Array("fmt ".utf8) + le32(fmt.count) + fmt
        body += Array("data".utf8) + le32(sound.count) + sound
        return Data(Array("RIFF".utf8) + le32(body.count) + body)
    }
}

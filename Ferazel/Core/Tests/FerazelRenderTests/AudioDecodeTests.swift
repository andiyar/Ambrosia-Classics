import XCTest
import HectorAudio
import FerazelCore
@testable import FerazelRender

/// C3 (docs/plans/2026-10-06-ferazel-phase1.md): every `snd ` in Sounds and every AIFC music track, decoded
/// through HectorAudio, against the committed `Resources/Ferazel` (D26). Contract: sprites-backgrounds §6.1,
/// world-data §1, design §7.7. Every number is a planner probe (p07 = snd census, p08 = Research note 13).
/// A missing data file is a FAILURE naming the path, never a skip (plan invariant 5).
final class AudioDecodeTests: XCTestCase {

    private func resources() throws -> FerazelResources {
        try FerazelData.open(try FerazelData.dataDirectory())
    }

    func testAll172SndDecode() throws {
        let bank = try SoundBank(sounds: try resources().sounds)
        XCTAssertEqual(bank.sounds.count, 172)
        XCTAssertEqual(Set(bank.sounds.map(\.format)), [1])
        XCTAssertEqual(Set(bank.sounds.map(\.pcm.channels)), [1])
        let odd = Double(UInt32(0x56EE_8BA3)) / 65536   // 22254.545… Hz, the raw 16.16 rate un-truncated
        var rates: [Double: Int] = [:]
        for s in bank.sounds { rates[s.pcm.sampleRate, default: 0] += 1 }
        XCTAssertEqual(rates, [22050: 138, 11025: 33, odd: 1])
        XCTAssertEqual(bank.sounds.map(\.pcm.frames).reduce(0, +), 2_432_217)
        XCTAssertEqual(bank.sounds.map(\.pcm.samples.count).reduce(0, +), 2_432_217)
    }

    func testSnd128SoftImpact() throws {
        let bank = try SoundBank(sounds: try resources().sounds)
        let s = try XCTUnwrap(bank.sound(id: 128), "snd 128")
        XCTAssertEqual(s.name, "soft impact")
        XCTAssertEqual(s.pcm.frames, 8_896)
        XCTAssertEqual(s.pcm.sampleRate, 22050)
        XCTAssertEqual(Array(s.pcm.samples.prefix(3)), [512, 512, 256])   // (s − 128) << 8 of 0x82 0x82 0x81
    }

    func testTwentyEightAIFCTracksDecode() throws {
        let dir = try resources().musicDirectory
        let packets: [(Int, Int)] = [
            (1, 28_463), (2, 26_932), (3, 24_274), (4, 20_608), (5, 30_288), (6, 24_783), (7, 24_766),
            (8, 22_716), (9, 48_512), (10, 23_632), (11, 22_102), (12, 21_046), (13, 30_722), (14, 22_054),
            (15, 17_734), (16, 22_892), (17, 21_606), (18, 31_654), (19, 22_576), (20, 24_809), (22, 26_480),
            (23, 22_448), (24, 32_384), (25, 19_206), (26, 23_168), (28, 20_968), (29, 19_272), (30, 17_956),
        ]
        XCTAssertEqual(try MusicTrack.trackNumbers(in: dir), packets.map(\.0))
        var totalPackets = 0, totalFrames = 0
        for (number, count) in packets {   // one at a time: each decoded track is released before the next
            let track = try MusicTrack(number: number, in: dir)
            XCTAssertEqual(track.channels, 2, "track \(number)")
            XCTAssertEqual(track.sampleRate, 22050, "track \(number)")
            XCTAssertEqual(track.encoding, .ima4, "track \(number)")
            XCTAssertEqual(track.packetCount, count, "track \(number)")
            let pcm = try track.decode()
            XCTAssertEqual(pcm.frames, count * 64, "track \(number) frames")
            XCTAssertEqual(pcm.samples.count, count * 64 * 2, "track \(number) samples")
            totalPackets += count
            totalFrames += pcm.frames
        }
        XCTAssertEqual(totalPackets, 694_051)
        XCTAssertEqual(totalFrames, 44_419_264)
    }
}

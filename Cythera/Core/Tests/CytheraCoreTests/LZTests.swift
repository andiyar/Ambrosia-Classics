import CryptoKit
import XCTest
@testable import CytheraCore

/// C3 (docs/plans/2026-10-06-cythera-phase0.md): the LZ codec of data-format §2 (`FUN_1007573c`). Every number is
/// planner probe p04 (= `docs/cythera/tools/lz.py`, the oracle; Research notes 4–5).
final class LZTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    private func sha256(_ bytes: [UInt8]) -> String {
        SHA256.hash(data: Data(bytes)).map { String(format: "%02x", $0) }.joined()
    }

    func testSevenOpFormsSynthetic() throws {
        let stream: [UInt8] = [
            0xC0, 0x41, 0x42, 0x43, 0x44,       // 110 0xxxx: literal run of ((0)+1)*4 = 4  → "ABCD"
            0xD2, 0x45, 0x46,                   // 110 1xxxx: literal run of 2               → "EF"
            0x05, 0x08,                         // 0xxxxxxx: 1 literal, match len 3, dist 6
            0x47,                               //   literal "G"                             → "BCD"
            0x82, 0x01, 0x02,                   // 10xxxxxx: 2 literals, match len 4, dist 3
            0x48, 0x49,                         //   literals "HI"                           → "DHID" (overlap)
            0xE1, 0x5A,                         // 1110 xxxx: 'Z' × 4
            0xF3, 0x02, 0x59,                   // 11110 xxx: 'Y' × 5
            0xF8,                               // 11111 xxx: end
            0xAA, 0xBB,                         // trailing bytes are not consumed
        ]
        // Oracle (`lz.py` unlz): b"ABCDEFGBCDHIDHIDZZZZYYYYY", 22 consumed.
        let expected = Array("ABCDEFGBCDHIDHIDZZZZYYYYY".utf8)
        let (bytes, consumed) = try LZ.decode(Data(stream))
        XCTAssertEqual(bytes, expected)
        XCTAssertEqual(consumed, stream.count - 2)
        var census = LZ.OpCensus()
        _ = try LZ.decode(Data(stream), census: &census)
        XCTAssertEqual(census, LZ.OpCensus(a: 1, b: 1, c: 1, d: 1, e: 1, f: 1, end: 1))

        // The wide distance fields: 0xxxxxxx distance = 1 + (b&0x7f | (b1&0xe0)<<2) at 1,000;
        // 10xxxxxx distance = 1 + ((b2&0xfc)<<7 | b&0x3f | (b1&0xe0)<<1) at 2,000. 33 literal runs of 64 first.
        // Oracle (`lz.py`): 2,118 bytes out, 2,151 consumed.
        let literals = (0..<2_112).map { UInt8(($0 * 7 + 3) % 256) }
        var far: [UInt8] = []
        for k in 0..<33 { far.append(0xCF); far += literals[(k * 64)..<((k + 1) * 64)] }
        far += [0x67, 0xE0]                     // dist 1,000, len 3
        far += [0x8F, 0xE0, 0x0C, 0xF8]         // dist 2,000, len 3; end
        let (wide, wideConsumed) = try LZ.decode(Data(far))
        XCTAssertEqual(wideConsumed, 2_151)
        XCTAssertEqual(wide.count, 2_118)
        XCTAssertEqual(Array(wide[0..<2_112]), literals)
        XCTAssertEqual(Array(wide[2_112..<2_115]), Array(literals[1_112..<1_115]))
        XCTAssertEqual(Array(wide[2_115..<2_118]), Array(literals[115..<118]))

        // A slice whose startIndex is not 0 decodes the same.
        let padded = Data([0x00, 0x00] + stream)
        XCTAssertEqual(try LZ.decode(padded[2...]).bytes, expected)
    }

    func testTileSheet0x8E00() throws {
        let src = try XCTUnwrap(try segmentFile().segment(0x8E00))
        XCTAssertEqual(src.count, 5_378)
        let (bytes, consumed) = try LZ.decode(src)
        XCTAssertEqual(bytes.count, 16_384)
        XCTAssertEqual(consumed, 5_378)
        XCTAssertEqual(sha256(bytes), "9a5e259ec4ba72fbedf86ebbbfcd523f8f3272a01c726b70579db40f94645a7c")
    }

    func testPortraitAndSkyWorked() throws {
        let file = try segmentFile()
        let portrait = try XCTUnwrap(file.segment(0x8800))
        XCTAssertEqual(portrait.count, 1_482)
        let p = try LZ.decode(portrait)
        XCTAssertEqual(p.bytes.count, 4_096)
        XCTAssertEqual(p.consumed, 1_482)
        XCTAssertEqual(sha256(p.bytes), "86ef37d410f374f743514f916b0878ac3172fad770f246156c4e811331b4cafc")

        let sky = try XCTUnwrap(file.segment(0x8400))
        XCTAssertEqual(sky.count, 5_474)
        let s = try LZ.decode(sky)
        XCTAssertEqual(s.bytes.count, 9_216)
        XCTAssertEqual(s.consumed, 5_474)
        XCTAssertEqual(sha256(s.bytes), "4216bfb5925461c1aa5ecbdc1d64fcef0ef5befc8b82162fd40e8538ac60442a")
    }

    func testEveryLZSegmentConsumesExactly() throws {
        let file = try segmentFile()
        var census = LZ.OpCensus()
        var counts: [UInt8: Int] = [:]
        for id in file.ids {
            let page = UInt8(id >> 8)
            guard [0x8E, 0x88, 0x84, 0x8F].contains(page), id != 0x8EFF else { continue }
            let seg = try XCTUnwrap(file.segment(id))
            counts[page, default: 0] += 1
            if page == 0x8F {
                XCTAssertGreaterThanOrEqual(seg.count, 4, String(format: "%04X", id))
                let b = [UInt8](seg.prefix(4))
                let w = Int(b[0]) << 8 | Int(b[1]), h = Int(b[2]) << 8 | Int(b[3])
                let (bytes, consumed) = try LZ.decode(seg.dropFirst(4), census: &census)
                XCTAssertEqual(consumed, seg.count - 4, String(format: "%04X", id))
                XCTAssertEqual(bytes.count, ((w + 3) & ~3) * h, String(format: "%04X", id))
            } else {
                let (bytes, consumed) = try LZ.decode(seg, census: &census)
                XCTAssertEqual(consumed, seg.count, String(format: "%04X", id))
                let expected = [0x8E: 0x4000, 0x88: 4_096, 0x84: 9_216][page]!
                XCTAssertEqual(bytes.count, expected, String(format: "%04X", id))
            }
        }
        XCTAssertEqual(counts, [0x8E: 159, 0x88: 142, 0x84: 18, 0x8F: 59])
        XCTAssertEqual(census, LZ.OpCensus(a: 222_174, b: 301_737, c: 29_065, d: 56, e: 1_024, f: 362, end: 378))
    }

    func testStray0x8EFFThrowsMatchBeforeStart() throws {
        let src = try XCTUnwrap(try segmentFile().segment(0x8EFF))
        XCTAssertEqual(src.count, 4_694)
        XCTAssertThrowsError(try LZ.decode(src)) { error in
            XCTAssertEqual(error as? LZError, .matchBeforeStart)
        }
    }

    func testTruncatedAndHostileInputThrowsNeverTraps() throws {
        let src = try XCTUnwrap(try segmentFile().segment(0x8800))
        for n in 0..<src.count {
            XCTAssertThrowsError(try LZ.decode(src.prefix(n)), "prefix \(n)") { error in
                XCTAssertEqual(error as? LZError, .truncated, "prefix \(n)")
            }
        }
        XCTAssertNoThrow(try LZ.decode(src))
        // A match before any output, in each match form.
        XCTAssertThrowsError(try LZ.decode(Data([0x00, 0x00, 0xF8]))) { XCTAssertEqual($0 as? LZError, .matchBeforeStart) }
        XCTAssertThrowsError(try LZ.decode(Data([0x80, 0x00, 0x00, 0xF8]))) { XCTAssertEqual($0 as? LZError, .matchBeforeStart) }
        // A literal run that claims more bytes than remain.
        XCTAssertThrowsError(try LZ.decode(Data([0xCF, 0x01]))) { XCTAssertEqual($0 as? LZError, .truncated) }
    }
}

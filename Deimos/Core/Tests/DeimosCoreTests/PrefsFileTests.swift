import XCTest
@testable import DeimosCore

/// The settings file (Phase 4 S4 PF; grounding C §1a/§1b, §6a item 3): the 0x34f0-byte record as the original reads
/// (`FUN_10004f80`) and writes (`FUN_10004640`) it. Every expectation is built here from the grounding's arithmetic —
/// no original prefs file exists anywhere (C §1b), so there is no golden.
final class PrefsFileTests: XCTestCase {
    // The grounding's scrambling, written out independently of the codec: per byte swap the nibbles, then XOR 0xFF.
    private func scrambled(_ b: UInt8) -> UInt8 { ((b << 4) | (b >> 4)) ^ 0xFF }
    private func ascii(_ s: String) -> [UInt8] { Array(s.utf8) }
    private func putBE(_ v: UInt32, _ image: inout [UInt8], _ at: Int) {
        image[at] = UInt8(v >> 24); image[at + 1] = UInt8((v >> 16) & 0xFF)
        image[at + 2] = UInt8((v >> 8) & 0xFF); image[at + 3] = UInt8(v & 0xFF)
    }
    private func be(_ image: [UInt8], _ at: Int) -> UInt32 {
        UInt32(image[at]) << 24 | UInt32(image[at + 1]) << 16 | UInt32(image[at + 2]) << 8 | UInt32(image[at + 3])
    }

    private let names = ["Mars", "Supercobra", "Neurotik", "El B", "Dilvish", "Sam", "Vodi", "Fisj", "Alex",
                         "h'biki", "Goldenberry", "Leadfeather", "Troll", "Thomas", "Electrofryer"]

    /// The fresh record on disk, from C §1a's table and `FUN_10004540` → `FUN_10004ae0` → `FUN_10004f20(1)` →
    /// `FUN_100050f0`, then `FUN_10004640`'s scrambling: a zeroed block with only the listed fields set.
    private func expectedFreshFile() -> [UInt8] {
        var f = [UInt8](repeating: 0, count: 0x34f0)
        putBE(0x2714, &f, 0x0000)
        f[0x0008] = 1                                     // byte 4 "Full Screen"
        f[0x000e] = 1                                     // byte 10 FPS limiter
        putBE(50, &f, 0x68); putBE(100, &f, 0x6c); putBE(50, &f, 0x70); putBE(1, &f, 0x74)
        for k in 0..<15 {
            for (i, c) in ascii(names[k]).enumerated() { f[0x10f8 + 21 * k + i] = scrambled(c) }
            for (i, c) in ascii("New Atlantis").enumerated() { f[0x12d8 + 32 * k + i] = scrambled(c) }
            putBE(UInt32(16_000 - 1_000 * (k + 1)) &+ 0x024A_8903, &f, 0x1260 + 4 * k)
            putBE(0xA696_0430, &f, 0x129c + 4 * k)        // 0 − 0x5969FBD0
        }
        for (i, c) in ascii("Player 1").enumerated() { f[0x1233 + i] = c }   // plain
        for (i, c) in ascii("Player 2").enumerated() { f[0x1248 + i] = c }
        let keys: [UInt32] = [0x7E, 0x7B, 0x7C, 0x7D, 0x37, 0x3A, 0x31, 0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79]
        for (i, k) in keys.enumerated() { putBE(k, &f, 0x14b8 + 4 * i) }
        return f
    }

    func testFreshPrefsFileImage() {
        let file = PrefsFile.fresh.fileBytes
        XCTAssertEqual(file.count, 0x34f0)
        XCTAssertEqual(file, expectedFreshFile())
        // Spot literals worked by hand: "Mars" scrambled, score 0 = 15000 + 0x24A8903, the dead int, the first key.
        XCTAssertEqual(Array(file[0x10f8..<0x10fd]), [0x2B, 0xE9, 0xD8, 0xC8, 0x00])
        XCTAssertEqual(be(file, 0x1260), 0x024A_C39B)
        XCTAssertEqual(be(file, 0x1260 + 4 * 14), 0x024A_8CEB)     // 1000 + 0x24A8903
        XCTAssertEqual(be(file, 0x129c), 0xA696_0430)
        XCTAssertEqual(be(file, 0x14b8), 0x7E)
        XCTAssertEqual(Array(file[0x1233..<0x123c]), ascii("Player 1") + [0])
        // The fresh record's typed view is the locked fresh prefs.
        XCTAssertEqual(PrefsFile.fresh.prefs, DeimosPrefs.fresh)
    }

    func testPrefsRoundTrip() throws {
        // write(read(write(fresh))) is byte-equal.
        let fresh = PrefsFile.fresh.fileBytes
        let read = try XCTUnwrap(PrefsFile(fileBytes: fresh))
        XCTAssertEqual(read.fileBytes, fresh)
        XCTAssertEqual(read.prefs, DeimosPrefs.fresh)

        // Bytes the codec never reads survive: both reserved blocks, the pad, ints 4–99, byte pref 99, raw bytes after
        // a name's NUL, the dead ints on disk.
        var poked = fresh
        poked[0x01f8] = 0xA1; poked[0x10f7] = 0xA2                 // reserved block 1 ends
        poked[0x14f0] = 0xB1; poked[0x34ef] = 0xB2                 // reserved block 2 ends
        poked[0x125d] = 0xC1; poked[0x125e] = 0xC2; poked[0x125f] = 0xC3   // pad
        putBE(0xDEAD_BEEF, &poked, 0x78)                           // int 4
        putBE(0x0102_0304, &poked, 0x1f4)                          // int 99
        poked[0x67] = 0x5A                                         // byte pref 99
        poked[0x10f8 + 6] = 0x33                                   // after "Mars"'s NUL (raw both ways)
        poked[0x1233 + 10] = 0x44                                  // after "Player 1"'s NUL
        putBE(0x1234_5678, &poked, 0x129c + 4 * 7)                 // a dead int
        let pokedRead = try XCTUnwrap(PrefsFile(fileBytes: poked))
        XCTAssertEqual(pokedRead.fileBytes, poked)
        var pokedPrefs = DeimosPrefs.fresh
        pokedPrefs.bytePrefs[99] = 0x5A                            // the only typed field among them
        XCTAssertEqual(pokedRead.prefs, pokedPrefs)
        // Applying the unchanged typed view changes nothing.
        var same = pokedRead
        same.apply(pokedRead.prefs)
        XCTAssertEqual(same.fileBytes, poked)

        // Changed typed fields land at their offsets; the untouched bytes stay.
        var prefs = pokedRead.prefs
        prefs.highScores[0] = 99_999
        prefs.highScoreNames[1] = "Ben"
        prefs.intPrefs[3] = 7
        prefs.bytePrefs[11] = 1
        prefs.keyTable[13] = 0x31
        var changed = pokedRead
        changed.apply(prefs)
        let out = changed.fileBytes
        XCTAssertEqual(be(out, 0x1260), UInt32(99_999) &+ 0x024A_8903)
        XCTAssertEqual(Array(out[0x10f8 + 21..<0x10f8 + 25]), ascii("Ben").map(scrambled) + [0])
        XCTAssertEqual(be(out, 0x74), 7)
        XCTAssertEqual(out[0x0f], 1)
        XCTAssertEqual(be(out, 0x14ec), 0x31)
        for at in [0x01f8, 0x10f7, 0x14f0, 0x34ef, 0x125d, 0x125e, 0x125f, 0x67, 0x10f8 + 6, 0x1233 + 10] {
            XCTAssertEqual(out[at], poked[at], "byte 0x\(String(at, radix: 16)) moved")
        }
        XCTAssertEqual(be(out, 0x78), 0xDEAD_BEEF)
        XCTAssertEqual(be(out, 0x129c + 4 * 7), 0x1234_5678)
        XCTAssertEqual(try XCTUnwrap(PrefsFile(fileBytes: out)).prefs, prefs)
    }

    func testVersionMismatchIsFresh() throws {
        var wrong = PrefsFile.fresh.fileBytes
        putBE(0x2713, &wrong, 0)
        XCTAssertNil(PrefsFile(fileBytes: wrong))
        XCTAssertNil(PrefsFile(fileBytes: []))                     // an empty file reads version 0
        XCTAssertNil(PrefsFile(fileBytes: [0x00, 0x00, 0x27]))     // 3 bytes: 0x00002700

        // A short file with the right version is accepted (FSRead's count is ignored). The block is a static
        // 0x34f0 array in the zero-filled data (X: TOC 100e4844 → 100fdbf4, next symbol 101010e4), so what the
        // file does not reach stays 0 — and then gets the read's arithmetic: scores 0 − 0x24A8903.
        let full = PrefsFile.fresh.fileBytes
        let short = Array(full[0..<0x1260])
        let s = try XCTUnwrap(PrefsFile(fileBytes: short))
        XCTAssertEqual(s.prefs.highScores, Array(repeating: Int32(-38_439_171), count: 15))
        XCTAssertEqual(s.prefs.highScoreNames, names)
        XCTAssertEqual(s.prefs.highScoreSectorNames, Array(repeating: "", count: 15))
        XCTAssertEqual(s.prefs.keyTable, Array(repeating: 0, count: 14))
        XCTAssertEqual(s.prefs.intPrefs, [50, 100, 50, 1])
        XCTAssertEqual(s.fileBytes, short + [UInt8](repeating: 0, count: 0x34f0 - 0x1260))
        // A 4-byte file holding only the version is a record of zeros.
        XCTAssertNotNil(PrefsFile(fileBytes: [0x00, 0x00, 0x27, 0x14]))
        // A longer file: only 0x34f0 bytes are read.
        let long = try XCTUnwrap(PrefsFile(fileBytes: full + [0xEE, 0xEE]))
        XCTAssertEqual(long.fileBytes, full)
    }

    func testNameObfuscationOverStrlen() throws {
        var file = PrefsFile.fresh.fileBytes
        // Name 0 "Mars" + NUL + raw tail bytes: the tail is outside strlen, left raw both ways.
        file[0x10f8 + 5] = 0x11; file[0x10f8 + 6] = 0x22
        // Name 1 on disk: scrambled 'A', 0xFF, scrambled 'B', NUL. 0xFF unscrambles to 0x00 → the name is "A" and
        // the 'B' is now plain; written back, strlen("A") = 1 leaves both raw — the truncation quirk.
        let n1 = 0x10f8 + 21
        for i in 0..<21 { file[n1 + i] = 0 }
        file[n1] = scrambled(0x41); file[n1 + 1] = 0xFF; file[n1 + 2] = scrambled(0x42)
        let read = try XCTUnwrap(PrefsFile(fileBytes: file))
        XCTAssertEqual(read.prefs.highScoreNames[0], "Mars")
        XCTAssertEqual(Array(read.image[0x10f8..<0x10ff]), ascii("Mars") + [0, 0x11, 0x22])
        XCTAssertEqual(read.prefs.highScoreNames[1], "A")
        XCTAssertEqual(Array(read.image[n1..<n1 + 4]), [0x41, 0x00, 0x42, 0x00])
        let out = read.fileBytes
        XCTAssertEqual(Array(out[0x10f8..<0x10ff]), Array(file[0x10f8..<0x10ff]))
        XCTAssertEqual(Array(out[n1..<n1 + 4]), [scrambled(0x41), 0x00, 0x42, 0x00])
        XCTAssertEqual(try XCTUnwrap(PrefsFile(fileBytes: out)).prefs.highScoreNames[1], "A")

        // strlen is C's: a name with no NUL in its 21 bytes runs on into the next field. On disk name 2 = 21
        // scrambled 'x' (no NUL), name 3 = scrambled "El B" + NUL. Reading: pass 2's strlen is 25, so it unscrambles
        // the x's AND "El B"; pass 3's strlen("El B") = 4 scrambles "El B" again — in memory name 3 stays scrambled.
        // Writing runs the same two passes and restores the disk bytes exactly.
        var spill = PrefsFile.fresh.fileBytes
        let n2 = 0x10f8 + 42, n3 = 0x10f8 + 63
        for i in 0..<21 { spill[n2 + i] = scrambled(0x78) }
        let elB = ascii("El B").map(scrambled)
        XCTAssertEqual(Array(spill[n3..<n3 + 5]), elB + [0])       // the fresh file already holds it there
        let spillRead = try XCTUnwrap(PrefsFile(fileBytes: spill))
        XCTAssertEqual(Array(spillRead.image[n2..<n3]), [UInt8](repeating: 0x78, count: 21))
        XCTAssertEqual(Array(spillRead.image[n3..<n3 + 5]), elB + [0])
        XCTAssertEqual(spillRead.prefs.highScoreNames[2], String(repeating: "x", count: 21))   // field-capped view
        XCTAssertEqual(spillRead.fileBytes, spill)
    }

    func testNamesDecodedBeforeVersionCheck() throws {
        // FUN_10004f80 unscrambles names and scores in the live block first, then tests the version: the decode is
        // not gated on the version, and the version is read from the decoded block.
        var file = PrefsFile.fresh.fileBytes
        putBE(0x0000_0001, &file, 0)
        let image = PrefsFile.decodedImage(fileBytes: file)
        XCTAssertEqual(image.count, 0x34f0)
        XCTAssertEqual(Array(image[0x10f8..<0x10fd]), ascii("Mars") + [0])
        XCTAssertEqual(Array(image[0x12d8..<0x12e5]), ascii("New Atlantis") + [0])
        XCTAssertEqual(be(image, 0x1260), 15_000)
        XCTAssertEqual(be(image, 0x129c), 0)
        XCTAssertEqual(be(image, 0), 1)
        XCTAssertNil(PrefsFile(fileBytes: file))
        // The same file with the right version: the record's image is exactly that decoded block.
        putBE(0x2714, &file, 0)
        XCTAssertEqual(try XCTUnwrap(PrefsFile(fileBytes: file)).image, PrefsFile.decodedImage(fileBytes: file))
    }
}

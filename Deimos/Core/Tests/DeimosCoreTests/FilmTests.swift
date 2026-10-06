import XCTest
@testable import DeimosCore

/// `film` replays (bank engine-loop.md §7): 0x9d68 bytes, big-endian, version 0x2715.
final class FilmTests: XCTestCase {
    private func film(_ id: String) throws -> Film {
        let index = try RealData.index()
        return try Film(data: try index.data(for: XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC(id)!))))
    }

    /// A valid all-zero film image with the given P1 frame count.
    private func synthetic(version: UInt32 = 0x2715, frames: UInt32 = 0, size: Int = 0x9d68) -> Data {
        var b = [UInt8](repeating: 0, count: size)
        func put(_ v: UInt32, _ at: Int) { for i in 0..<4 where at + i < b.count { b[at + i] = UInt8(v >> UInt32(24 - 8 * i) & 0xFF) } }
        put(version, 0)
        if b.count > 0x0c { b[0x0c] = 1 }
        put(frames, 0x10)
        return Data(b)
    }

    func testFourDemosAndLastFilm() throws {
        let expected: [(String, String, UInt32, Int, Int32)] = [
            ("de01", "le07", 0x469c2, 4_809, 25_050), ("de02", "le06", 0x4f655, 8_357, 116_180),
            ("de03", "le02", 0x54c83, 10_058, 57_520), ("de04", "le08", 0x5afed, 5_649, 24_670),
            ("last", "le07", 0x469c2, 4_809, 25_050),
        ]
        for (id, level, seed, frames, score) in expected {
            let f = try film(id)
            XCTAssertEqual(f.version, 0x2715, id)
            XCTAssertEqual(f.seed, seed, id)
            XCTAssertEqual(f.level, FourCC(level), id)
            XCTAssertEqual(f.playerCount, 1, id)
            XCTAssertEqual(f.players.count, 2, id)
            let p1 = f.players[0]
            XCTAssertEqual(p1.frames, frames, id)
            XCTAssertEqual(p1.inputs.count, frames, id)
            XCTAssertEqual(p1.score, score, id)
            XCTAssertEqual(p1.level, FourCC(level), id)
            XCTAssertLessThanOrEqual(p1.inputs.max() ?? 0, 0x4a, id)
            XCTAssertFalse(p1.inputs.contains { $0 & 0x80 != 0 }, id)
            XCTAssertTrue(f.trailingBytesAreZero, "bytes after the last recorded tick are zero (\(id))")
        }
        XCTAssertEqual(try film("last"), try film("de01"))
    }

    func testInputBitsDecode() throws {
        let p1 = try film("de01").players[0]
        let first = try XCTUnwrap(p1.inputs.first { $0 != 0 })
        XCTAssertEqual(Film.Input(rawValue: first), .left)
        XCTAssertEqual(p1.input(at: p1.inputs.firstIndex(of: first)!), .left)
        XCTAssertEqual(Film.Input.left.rawValue, 1)
        XCTAssertEqual(Film.Input.right.rawValue, 2)
        XCTAssertEqual(Film.Input.up.rawValue, 4)
        XCTAssertEqual(Film.Input.down.rawValue, 8)
        XCTAssertEqual(Film.Input.fireGround.rawValue, 0x10)
        XCTAssertEqual(Film.Input.fireAir.rawValue, 0x20)
        XCTAssertEqual(Film.Input.selectWeapon.rawValue, 0x40)
        XCTAssertEqual(Film.Input(rawValue: 0x4a), [.right, .down, .selectWeapon])
    }

    func testVersionRefused() {
        XCTAssertThrowsError(try Film(data: synthetic(version: 0x2714))) {
            XCTAssertEqual($0 as? FilmError, .outOfDate(0x2714))
        }
        XCTAssertNoThrow(try Film(data: synthetic()))
    }

    func testWrongSizeRefused() {
        for size in [0, 3, 0x9d67, 0x9d69] {
            XCTAssertThrowsError(try Film(data: synthetic(size: size))) {
                XCTAssertEqual($0 as? FilmError, .wrongSize(size))
            }
        }
    }

    func testPlayerTwoBlockEmpty() throws {
        for id in ["de01", "de02", "de03", "de04", "last"] {
            let p2 = try film(id).players[1]
            XCTAssertEqual(p2.frames, 0, id)
            XCTAssertEqual(p2.inputs, [], id)
            XCTAssertEqual(p2.score, Int32(bitPattern: 0 &- 0xb3ac2), id)
            XCTAssertEqual(p2.level, FourCC.none, id)
        }
    }

    func testFramesCapped20000() throws {
        XCTAssertEqual(try Film(data: synthetic(frames: 20_000)).players[0].inputs.count, 20_000)
        XCTAssertThrowsError(try Film(data: synthetic(frames: 20_001))) {
            XCTAssertEqual($0 as? FilmError, .tooManyFrames(player: 0, frames: 20_001))
        }
    }
}

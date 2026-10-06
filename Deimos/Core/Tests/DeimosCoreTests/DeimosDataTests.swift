import XCTest
import HectorResources
@testable import DeimosCore

/// The committed original data (DECISIONS D24): never skips — the data is in git.
enum RealData {
    /// One index over `Resources/Deimos/Data` for the whole suite (the paks are memory-mapped).
    static let loaded: Result<TagIndex, Error> = Result {
        try TagIndex(dataDirectory: DeimosData.dataDirectory())
    }
    static func index() throws -> TagIndex { try loaded.get() }
}

final class DeimosDataTests: XCTestCase {
    func testFivePaksFilesPresentWithSizes() throws {
        let dir = try DeimosData.dataDirectory()
        let expected: [(String, Int)] = [
            ("Paks/Audio.pak", 1_702_614), ("Paks/Game.pak", 54_956_985), ("Paks/Interface.pak", 2_849_896),
            ("Paks/Music.pak", 13_601_894), ("Local/film/Last Film[last].film", 40_296),
        ]
        for (path, size) in expected {
            let attrs = try FileManager.default.attributesOfItem(atPath: dir.appendingPathComponent(path).path)
            XCTAssertEqual((attrs[.size] as? NSNumber)?.intValue, size, path)
        }
    }

    func testIndexHas872RecordsByType() throws {
        let index = try RealData.index()
        XCTAssertEqual(index.records.count, 872)
        var counts: [String: Int] = [:]
        for r in index.records { counts[r.type.description, default: 0] += 1 }
        XCTAssertEqual(counts, ["coli": 1, "film": 5, "flli": 1, "idli": 6, "im08": 250, "im16": 45, "leve": 12,
                                "plde": 2, "reli": 1, "soun": 99, "stli": 5, "tefo": 54, "unde": 386, "wede": 5])
        // No (type, ID) collides.
        let keys = Set(index.records.map { "\($0.type)/\($0.id)" })
        XCTAssertEqual(keys.count, 872)
        XCTAssertFalse(index.records.contains { $0.size <= 0 })
    }

    func testLastFilmIsLocalAndEqualsDemo01() throws {
        let index = try RealData.index()
        let film = FourCC("film")!
        let last = try XCTUnwrap(index.record(type: film, id: FourCC("last")!))
        XCTAssertTrue(last.isLocal)
        XCTAssertEqual(last.displayName, "Last Film")
        XCTAssertEqual(index.records.first, last, "the one Local record leads the index")
        XCTAssertEqual(index.records.filter(\.isLocal).count, 1)
        let demo = try XCTUnwrap(index.record(type: film, id: FourCC("de01")!))
        XCTAssertFalse(demo.isLocal)
        XCTAssertEqual(try index.data(for: last), try index.data(for: demo))
        XCTAssertEqual(index.records(ofType: film).map(\.id.description), ["last", "de01", "de02", "de03", "de04"])
    }

    func testPakOrderAndNoAlerts() throws {
        let index = try RealData.index()
        XCTAssertEqual(index.paks.map(\.lastPathComponent), ["Audio.pak", "Game.pak", "Interface.pak", "Music.pak"])
        XCTAssertEqual(index.alerts, [])
    }

    func testWeaponOrder() throws {
        let index = try RealData.index()
        XCTAssertEqual(index.records(ofType: FourCC("wede")!).map(\.id.description),
                       ["aibg", "aiic", "aipb", "airg", "plbo"])
    }

    func testInterfaceDecrBytes() throws {
        let index = try RealData.index()
        let decr = try XCTUnwrap(index.record(type: FourCC("im16")!, id: FourCC("decr")!))
        XCTAssertEqual(decr.size, 614_418)
        XCTAssertEqual(decr.displayName, "Developer Credit")
        guard case .pak(let archive, let entry) = decr.source else { return XCTFail("decr is a pak entry") }
        XCTAssertEqual(index.paks[archive].lastPathComponent, "Interface.pak")
        XCTAssertEqual(entry.localHeaderOffset, 106)
        XCTAssertEqual(entry.dataOffset, 185)
        let bytes = try index.data(for: decr)
        XCTAssertEqual(bytes.count, 614_418)
        // TGA header, as HectorKit K1's census pins it. Byte 7 (colour-map entry size) is 0x18 with
        // colour-map type 0 (known delta 3; `xxd -s 185 -l 18 Interface.pak` — the plan's literal had 00).
        XCTAssertEqual(Array(bytes.prefix(18)),
                       [0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00,
                        0x80, 0x02, 0xe0, 0x01, 0x10, 0x01])
        XCTAssertEqual(bytes[0], 0x00, "rebased: index 0 is the entry's first byte")
        XCTAssertEqual(bytes[2], 0x02)
    }
}

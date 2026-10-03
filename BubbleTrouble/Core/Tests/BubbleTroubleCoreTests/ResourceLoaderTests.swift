import BubbleTroubleCore
import Foundation
import XCTest

/// Task 2 — resource loaders: MAZE, LEVL, FILM
/// (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 2; numbers from Research notes 7–10,
/// data-formats.md §1–3). Every census value below was re-checked on 2026-10-03 against bytes extracted
/// with `docs/bubble-trouble/tools/rsrc_census.py --extract` and a Python count.
final class ResourceLoaderTests: XCTestCase {

    // MARK: - Synthetic

    func testMazeRejectsWrongSize() throws {
        XCTAssertThrowsError(try Maze(data: Data(count: 175))) { error in
            XCTAssertEqual(error as? BTXDataError, .badSize(type: "MAZE", id: 0, size: 175))
        }
        XCTAssertThrowsError(try Maze(data: Data(count: 177)))
        var maze = try Maze(data: Data(count: Maze.byteCount))
        // cells[col + 16·row] (_LoadMaze @ 0002626e).
        maze[7, 6] = CellCode.dynamite
        XCTAssertEqual(maze.cells[7 + 16 * 6], CellCode.dynamite)
        XCTAssertEqual(maze[7, 6], 52)
    }

    func testFilmRejectsWrongSize() throws {
        XCTAssertThrowsError(try Film(id: 9, data: Data(count: 10011))) { error in
            XCTAssertEqual(error as? BTXDataError, .badSize(type: "FILM", id: 9, size: 10011))
        }
        XCTAssertThrowsError(try Film(id: 9, data: Data(count: 10013)))
        // Layout: u32 BE count, seed, level-field, then up @12, down @2012, left @4012, right @6012, push @8012.
        var bytes = [UInt8](repeating: 0, count: Film.byteCount)
        bytes.replaceSubrange(0..<12, with: [0, 0, 0x04, 0x5e, 0, 0x46, 0x42, 0xa0, 0, 2, 0, 0])
        bytes[12 + 5] = 1; bytes[2012 + 6] = 1; bytes[4012 + 7] = 1; bytes[6012 + 8] = 1; bytes[8012 + 9] = 1
        let film = try Film(id: 1, data: Data(bytes))
        XCTAssertEqual(film.count, 1118)
        XCTAssertEqual(film.seed, 0x0046_42a0)
        XCTAssertEqual(film.levelField, 0x0002_0000)
        XCTAssertEqual(film.sample(5), FilmSample(up: true, down: false, left: false, right: false, push: false))
        XCTAssertEqual(film.sample(6), FilmSample(up: false, down: true, left: false, right: false, push: false))
        XCTAssertEqual(film.sample(7), FilmSample(up: false, down: false, left: true, right: false, push: false))
        XCTAssertEqual(film.sample(8), FilmSample(up: false, down: false, left: false, right: true, push: false))
        XCTAssertEqual(film.sample(9), FilmSample(up: false, down: false, left: false, right: false, push: true))
    }

    /// `_LoadLevel @ 00002ef7`: w6 clamped `sVar8 = 0x1e; if (w6 < 0x1f) sVar8 = w6;`;
    /// w12 clamped to 3...4. The raw words stay as stored.
    func testLevelClamps() throws {
        func record(w6: Int16, w12: Int16) throws -> LevelRecord {
            var words = [Int16](repeating: 0, count: 32)
            words[6] = w6; words[12] = w12
            words[15] = 140; words[16] = 170; words[18] = 4; words[23] = -2
            var data = Data()
            for w in words { data.append(UInt8(truncatingIfNeeded: UInt16(bitPattern: w) >> 8)); data.append(UInt8(truncatingIfNeeded: w)) }
            return try LevelRecord(data: data)
        }
        let a = try record(w6: 40, w12: 2)
        XCTAssertEqual(a.totalEnemies, 30)
        XCTAssertEqual(a.jewelCount, 3)
        XCTAssertEqual(a.words[6], 40)
        XCTAssertEqual(a.words[12], 2)
        XCTAssertEqual(a.balloonFlash, 140)
        XCTAssertEqual(a.balloonRelease, 170)
        XCTAssertEqual(a.pool, [4, 0, 0, 0, 0, -2])          // big-endian, signed
        let b = try record(w6: 31, w12: 7)
        XCTAssertEqual(b.totalEnemies, 30)
        XCTAssertEqual(b.jewelCount, 4)
        XCTAssertEqual(b.words[12], 7)
        let c = try record(w6: 30, w12: 4)
        XCTAssertEqual(c.totalEnemies, 30)
        XCTAssertEqual(c.jewelCount, 4)
        XCTAssertThrowsError(try LevelRecord(data: Data(count: 63))) { error in
            XCTAssertEqual(error as? BTXDataError, .badSize(type: "LEVL", id: 0, size: 63))
        }
    }

    // MARK: - Data-gated

    /// Research note 7: LEVL 50 × 64 B (1..50), MAZE 50 × 176 B (1..50), FILM 4 × 10012 B (1..4).
    func testLevelsCensus() throws {
        let files = try BTXTestData.files()
        XCTAssertEqual(files.levelIDs, Array(1...50))
        XCTAssertEqual(files.mazeIDs, Array(1...50))
        XCTAssertEqual(files.filmIDs, Array(1...4))
        for id in 1...50 {
            XCTAssertEqual(try files.level(id).words.count, 32)
            XCTAssertEqual(try files.maze(id).cells.count, Maze.byteCount)
        }
        for id in 1...4 {
            let film = try files.film(id)
            XCTAssertEqual(film.id, id)
            for array in [film.up, film.down, film.left, film.right, film.push] {
                XCTAssertEqual(array.count, Film.capacity)
            }
        }
        XCTAssertThrowsError(try files.maze(51)) { error in
            XCTAssertEqual(error as? BTXDataError, .missingResource(type: "MAZE", id: 51))
        }
        XCTAssertThrowsError(try files.film(5)) { error in
            XCTAssertEqual(error as? BTXDataError, .missingResource(type: "FILM", id: 5))
        }
    }

    /// Research note 10: (count, seed, level-field) per FILM.
    func testFilmHeaders() throws {
        let files = try BTXTestData.files()
        let expected: [(Int, UInt32, UInt32)] = [
            (1118, 0x0046_42a0, 0x0002_0000),
            (846, 0x0045_f1f8, 0x0002_0000),
            (943, 0x0046_1498, 0x0003_0000),
            (890, 0x0046_21ef, 0x0004_0000),
        ]
        for (index, triple) in expected.enumerated() {
            let film = try files.film(index + 1)
            XCTAssertEqual(film.count, triple.0, "FILM \(index + 1) count")
            XCTAssertEqual(film.seed, triple.1, "FILM \(index + 1) seed")
            XCTAssertEqual(film.levelField, triple.2, "FILM \(index + 1) level-field")
        }
    }

    /// Research note 10: every array byte is 0 or 1; FILM 1 held past the count (up, down, left, right,
    /// push) = 89/100/90/92/1, held within the count = 86/67/59/98/19.
    func testFilmArraysBinaryAndLeftovers() throws {
        let files = try BTXTestData.files()
        for id in files.filmIDs {
            let film = try files.film(id)
            for array in [film.up, film.down, film.left, film.right, film.push] {
                XCTAssertTrue(array.allSatisfy { $0 == 0 || $0 == 1 }, "FILM \(id) has a non-binary byte")
            }
        }
        let film = try files.film(1)
        let arrays = [film.up, film.down, film.left, film.right, film.push]
        let held = arrays.map { $0[..<film.count].reduce(0) { $0 + Int($1) } }
        let leftovers = arrays.map { $0[film.count...].reduce(0) { $0 + Int($1) } }
        XCTAssertEqual(held, [86, 67, 59, 98, 19])
        XCTAssertEqual(leftovers, [89, 100, 90, 92, 1])
    }

    /// Research note 10: FILM 1 first runs `..... ×16, ...R. ×25, ..... ×5, U.... ×37, ..... ×8, ..L.. ×7`;
    /// first push at sample 212.
    func testFilm1RunLengthsAndFirstPush() throws {
        let film = try BTXTestData.files().film(1)
        func key(_ s: FilmSample) -> String {
            [s.up ? "U" : ".", s.down ? "D" : ".", s.left ? "L" : ".", s.right ? "R" : ".", s.push ? "P" : "."]
                .joined()
        }
        var runs: [(String, Int)] = []
        for index in 0..<film.count {
            let k = key(film.sample(index))
            if let last = runs.last, last.0 == k { runs[runs.count - 1].1 += 1 } else { runs.append((k, 1)) }
        }
        let first = runs.prefix(6).map { "\($0.0)×\($0.1)" }
        XCTAssertEqual(first, [".....×16", "...R.×25", ".....×5", "U....×37", ".....×8", "..L..×7"])
        XCTAssertEqual((0..<film.count).first { film.sample($0).push }, 212)
    }

    /// Research note 10: samples (within the count) with more than one of up/down/left/right held —
    /// FILM 1–4 = 0 / 11 / 11 / 18.
    func testMultiDirectionSamples() throws {
        let files = try BTXTestData.files()
        var counts: [Int] = []
        for id in 1...4 {
            let film = try files.film(id)
            counts.append((0..<film.count).filter { index in
                let s = film.sample(index)
                return [s.up, s.down, s.left, s.right].filter { $0 }.count > 1
            }.count)
        }
        XCTAssertEqual(counts, [0, 11, 11, 18])
    }

    /// Research note 8: cell-code census over all 50 mazes
    /// `[(0,4747),(10,3692),(15,169),(16,115),(52,77)]`; cell (7,6) (byte 0x67) is empty in all 50.
    func testMazeCensusAndStartCell() throws {
        let files = try BTXTestData.files()
        var census: [UInt8: Int] = [:]
        for id in files.mazeIDs {
            let maze = try files.maze(id)
            for cell in maze.cells { census[cell, default: 0] += 1 }
            XCTAssertEqual(maze[7, 6], CellCode.empty, "MAZE \(id) (7,6)")
            XCTAssertEqual(maze.cells[0x67], CellCode.empty, "MAZE \(id) byte 0x67")
        }
        let sorted = census.sorted { $0.key < $1.key }.map { [Int($0.key), $0.value] }
        XCTAssertEqual(sorted, [[0, 4747], [10, 3692], [15, 169], [16, 115], [52, 77]])
    }

    /// Research note 9: the 32 words of LEVL 1.
    func testLevel1Words() throws {
        let level = try BTXTestData.files().level(1)
        let expected: [Int16] = [1, 912, 1, 1, 1, 1, 4, 2, 50, 2, 10, 20, 3, 10, 20, 140, 170, 300, 4]
            + [Int16](repeating: 0, count: 13)
        XCTAssertEqual(level.words, expected)
        XCTAssertEqual(level.mazeID, 1)
        XCTAssertEqual(level.pictID, 912)
        XCTAssertEqual(level.musicSet, 1)
        XCTAssertEqual(level.hurtFrameBubble, 1)
        XCTAssertEqual(level.hurtFrameJewel, 1)
        XCTAssertEqual(level.totalEnemies, 4)
        XCTAssertEqual(level.maxActive, 2)
        XCTAssertEqual(level.eggTime, 50)
        XCTAssertEqual(level.preEggDelay, 10)
        XCTAssertEqual(level.jewelCount, 3)
        XCTAssertEqual(level.balloonFlash, 140)
        XCTAssertEqual(level.balloonRelease, 170)
        XCTAssertEqual(level.pool, [4, 0, 0, 0, 0, 0])
    }

    /// Research note 9, over all 50 LEVLs: Σpool == clamped total; w15/w16 step table 140/170 (L1),
    /// 130/160 (L2), 120/150 (L3), 110/140 (L4–12), 100/130 (L13–15), 90/120 (L16–50); jewels 3 (L1–12),
    /// 4 (L13–50); w8 == 50, w10 == 10, w17 == 300 everywhere; mazeID == id.
    func testLevelTablesAllFifty() throws {
        let files = try BTXTestData.files()
        func balloon(_ id: Int) -> (Int, Int) {
            switch id {
            case 1: (140, 170)
            case 2: (130, 160)
            case 3: (120, 150)
            case 4...12: (110, 140)
            case 13...15: (100, 130)
            default: (90, 120)
            }
        }
        for id in 1...50 {
            let level = try files.level(id)
            XCTAssertEqual(level.pool.reduce(0) { $0 + Int($1) }, level.totalEnemies, "LEVL \(id) pool sum")
            XCTAssertEqual(level.balloonFlash, balloon(id).0, "LEVL \(id) w15")
            XCTAssertEqual(level.balloonRelease, balloon(id).1, "LEVL \(id) w16")
            XCTAssertEqual(level.jewelCount, id <= 12 ? 3 : 4, "LEVL \(id) jewels")
            XCTAssertEqual(level.eggTime, 50, "LEVL \(id) w8")
            XCTAssertEqual(level.preEggDelay, 10, "LEVL \(id) w10")
            XCTAssertEqual(level.words[17], 300, "LEVL \(id) w17")
            XCTAssertEqual(level.mazeID, id, "LEVL \(id) w0")
        }
    }
}

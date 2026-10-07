import XCTest
@testable import CytheraCore

/// C4 (docs/plans/2026-10-06-cythera-phase0.md): the 42 level maps 0x8000–0x8029 (data-format §3.1–§3.3).
/// Numbers are planner probes (p11, Research note 8) and the bank's xxd; the 0x8002 chunk-0 words and the
/// non-compo max tile are the orchestrator's 2026-10-07 rulings (the plan skipped two zero words).
final class LevelMapTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    /// (id, W, H, C) — Research note 8.
    static let expected: [(UInt16, Int, Int, Int)] = [
        (0x8000, 32, 32, 0), (0x8001, 256, 256, 0), (0x8002, 64, 64, 16), (0x8003, 64, 64, 0),
        (0x8004, 32, 32, 0), (0x8005, 8, 8, 0), (0x8006, 64, 64, 26), (0x8007, 32, 32, 0),
        (0x8008, 128, 128, 102), (0x8009, 128, 128, 0), (0x800A, 32, 32, 0), (0x800B, 64, 64, 1),
        (0x800C, 64, 64, 9), (0x800D, 64, 64, 36), (0x800E, 56, 72, 0), (0x800F, 32, 32, 0),
        (0x8010, 64, 64, 0), (0x8011, 16, 16, 2), (0x8012, 32, 64, 3), (0x8013, 64, 64, 0),
        (0x8014, 64, 32, 3), (0x8015, 64, 64, 0), (0x8016, 32, 32, 2), (0x8017, 32, 32, 0),
        (0x8018, 64, 64, 6), (0x8019, 64, 64, 0), (0x801A, 64, 32, 3), (0x801B, 64, 64, 0),
        (0x801C, 64, 64, 0), (0x801D, 48, 48, 0), (0x801E, 32, 32, 0), (0x801F, 48, 48, 9),
        (0x8020, 48, 48, 9), (0x8021, 64, 64, 0), (0x8022, 64, 64, 0), (0x8023, 64, 64, 0),
        (0x8024, 64, 64, 4), (0x8025, 64, 64, 0), (0x8026, 24, 16, 0), (0x8027, 64, 64, 2),
        (0x8028, 64, 64, 0), (0x8029, 32, 24, 0),
    ]

    func testAllMapHeaders() throws {
        let file = try segmentFile()
        let ids = file.ids.filter { $0 >> 8 == 0x80 }
        XCTAssertEqual(ids.count, 42)
        XCTAssertEqual(ids, Self.expected.map(\.0))
        var sumC = 0
        for (id, w, h, c) in Self.expected {
            let map = try LevelMap(file: file, level: Int(id & 0xFF))
            let hdr = map.header
            XCTAssertEqual(hdr.width, Int16(w), "\(id)"); XCTAssertEqual(hdr.height, Int16(h), "\(id)")
            XCTAssertEqual(hdr.chunkCount, Int16(c), "\(id)")
            XCTAssertEqual(hdr.firstChunk, hdr.chunkCount, "+6 == +8 in \(id)")
            XCTAssertFalse(hdr.isChunked, "\(id)")
            XCTAssertEqual(hdr.unused4, 0, "\(id)")
            XCTAssertTrue(hdr.raw[0x14..<0x20].allSatisfy { $0 == 0 }, "\(id)")
            XCTAssertEqual(file.entry(id)?.length, 0x20 + c * 0x80 + w * h * 2, "\(id)")
            XCTAssertEqual(map.chunks.count, c); XCTAssertTrue(map.chunks.allSatisfy { $0.count == 64 })
            XCTAssertEqual(map.cells.count, w * h)
            sumC += c
        }
        XCTAssertEqual(sumC, 233)
    }

    func testMap0x8002Worked() throws {
        let file = try segmentFile()
        let map = try LevelMap(file: file, level: 2)
        let h = map.header
        XCTAssertEqual(h.width, 64); XCTAssertEqual(h.height, 64); XCTAssertEqual(h.chunkCount, 16)
        XCTAssertEqual(h.wrapX, 4); XCTAssertEqual(h.wrapY, 8)
        XCTAssertEqual([h.exitNorth, h.exitEast, h.exitSouth, h.exitWest], [5, 5, 5, 5])
        XCTAssertEqual(Array(map.chunks[0].prefix(4)), [0x0000, 0x0000, 0x01F6, 0x01E4])
        XCTAssertEqual(LevelMap.bodyOffset(of: h), 0x820)
        // The body at segment offset 0x820, row-major.
        let seg = [UInt8](file.segment(0x8002)!)
        XCTAssertEqual(map.cells[0], UInt16(seg[0x820]) << 8 | UInt16(seg[0x821]))
        XCTAssertEqual(map.cell(x: 1, y: 0)?.raw, UInt16(seg[0x822]) << 8 | UInt16(seg[0x823]))
        XCTAssertEqual(map.cell(x: 0, y: 1)?.raw, UInt16(seg[0x820 + 128]) << 8 | UInt16(seg[0x821 + 128]))
        XCTAssertNil(map.cell(x: 64, y: 0)); XCTAssertNil(map.cell(x: 0, y: -1))
    }

    func testMap0x8026Exits() throws {
        let h = try LevelMap(file: try segmentFile(), level: 0x26).header
        XCTAssertEqual(h.exitNorth, 0); XCTAssertEqual(h.exitEast, 0x8E)
        XCTAssertEqual(h.exitSouth, 0); XCTAssertEqual(h.exitWest, 0x8F)
    }

    func testMapCellCensus() throws {
        let file = try segmentFile()
        var cells = 0, maxLow12 = 0, maxTile = 0, compo = 0, bit13 = 0, bit15 = 0, withExit = 0
        var wraps: [String: Int] = [:]
        for (id, _, _, _) in Self.expected {
            let map = try LevelMap(file: file, level: Int(id & 0xFF))
            let h = map.header
            wraps["\(h.wrapX),\(h.wrapY)", default: 0] += 1
            if h.exitNorth != 0 || h.exitEast != 0 || h.exitSouth != 0 || h.exitWest != 0 { withExit += 1 }
            for raw in map.cells {
                let c = MapCell(raw)
                cells += 1
                maxLow12 = max(maxLow12, Int(raw & 0xFFF))
                if c.isCompo { compo += 1 } else { maxTile = max(maxTile, c.tile) }
                if c.isTransposed { bit13 += 1 }
                if c.isSeen { bit15 += 1 }
            }
        }
        XCTAssertEqual(cells, 206_976)
        XCTAssertEqual(maxLow12, 0x429)                  // p11 measure over all cells
        XCTAssertEqual(maxTile, 0x32C)                   // non-compo cells (ruling 2026-10-07)
        XCTAssertEqual(compo, 19_650)
        XCTAssertEqual(bit13, 0); XCTAssertEqual(bit15, 0)
        XCTAssertEqual(wraps, ["8,8": 22, "0,0": 9, "4,8": 4, "4,4": 4, "0,4": 1, "8,4": 1, "2,8": 1])
        XCTAssertEqual(withExit, 23)
    }
}

import XCTest
@testable import CytheraCore

/// C4 (docs/plans/2026-10-06-cythera-phase0.md): the 40 prop segments 0x8101–0x8129 (data-format §4.2–§4.5) and
/// the hostile-input posture of the map and prop decoders (Invariants 4, 5). Numbers: p11 = data-format §4.3
/// census (`docs/cythera/tools/props_census.py` agrees).
final class PropTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    func testPropCensus() throws {
        let file = try segmentFile()
        let ids = file.ids.filter { $0 >> 8 == 0x81 }
        XCTAssertEqual(ids.count, 40)
        var records = 0, maxType = 0
        var kinds: [UInt8: Int] = [:], bFrames: [Int: Int] = [:]
        var slotNonZero = 0, byteFNonZero = 0, byteEHigh = 0
        for id in ids {
            XCTAssertEqual(file.entry(id)!.length % 16, 0, "\(id)")
            let seg = try PropSegment(file: file, level: Int(id & 0xFF))
            for r in seg.records {
                records += 1
                kinds[r.kind, default: 0] += 1
                if r.kind == 0x42 { bFrames[r.frame, default: 0] += 1 }
                if r.scriptSlot != 0 { slotNonZero += 1 }
                if r.bytes[0xF] != 0 { byteFNonZero += 1 }
                if r.bytes[0xE] & 0xC0 != 0 { byteEHigh += 1 }
                maxType = max(maxType, r.type)
            }
        }
        XCTAssertEqual(records, 14_485)
        XCTAssertEqual(kinds, [0: 12104, 1: 116, 2: 46, 8: 618, 9: 241, 10: 7, 0x10: 32, 0x11: 55, 0x18: 31,
                               0x1C: 1, 0x42: 879, 0x44: 298, 0x80: 52, 0xFF: 5])
        XCTAssertEqual(bFrames, [0: 312, 1: 30, 3: 330, 4: 8, 6: 2, 7: 3, 8: 170, 10: 24])
        XCTAssertEqual(slotNonZero, 0)
        XCTAssertEqual(byteFNonZero, 0)
        XCTAssertEqual(byteEHigh, 0)
        XCTAssertEqual(maxType, 800)
    }

    func testProp0x8102Worked() throws {
        let seg = try PropSegment(file: try segmentFile(), level: 2)
        let r2 = seg.records[2], r3 = seg.records[3]
        XCTAssertEqual(r2.kind, 0); XCTAssertEqual(r2.x, 10); XCTAssertEqual(r2.y, 32)
        XCTAssertEqual(r2.type, 39); XCTAssertEqual(r2.frame, 3); XCTAssertEqual(r2.byte6, 1)
        XCTAssertFalse(r2.mirror)
        XCTAssertEqual(r3.kind, 0x44); XCTAssertEqual(r3.x, 15); XCTAssertEqual(r3.y, 17); XCTAssertEqual(r3.type, 1)
        // Synthetic field accessors (§4.2): signed 12-bit coordinates, parent, mirror, sext6 sprite offset.
        let s = PropRecord(bytes: [0x08, 0xFF, 0xF0, 0x05, 0xFC, 0x27, 0x07, 0x09,
                                   0x12, 0x34, 0x00, 0x02, 0xAB, 0xCD, 0x3F, 0x00])!
        XCTAssertEqual(s.x, -1); XCTAssertEqual(s.y, 5); XCTAssertEqual(s.parent, Int16(bitPattern: 0xF005))
        XCTAssertTrue(s.mirror); XCTAssertEqual(s.frame, 0x1F); XCTAssertEqual(s.type, 0x027)
        XCTAssertEqual(s.byte7, 9); XCTAssertEqual(s.uniqueIndex, 0x1234); XCTAssertEqual(s.scriptSlot, 2)
        XCTAssertEqual(s.heapRef, 0xABCD); XCTAssertEqual(s.spriteOffset6, -1)
        XCTAssertNil(PropRecord(bytes: [UInt8](repeating: 0, count: 15)))
    }

    func testTruncatedMapAndPropThrowNeverTrap() throws {
        let file = try segmentFile()
        // Every prefix of map 0x8002 (0x2820 B) throws a named error, never traps (Invariant 5).
        let map = file.segment(0x8002)!
        for cut in 0..<map.count {
            XCTAssertThrowsError(try LevelMap(data: map.prefix(cut)), "prefix \(cut)") { e in
                XCTAssertTrue(e is LevelMapError, "prefix \(cut): \(e)")
            }
        }
        // A map whose length breaks 0x20 + C·0x80 + W·H·2 → named error (Invariant 4).
        XCTAssertThrowsError(try LevelMap(data: map + Data([0, 0]))) { e in
            XCTAssertEqual(e as? LevelMapError, .lengthMismatch(expected: 0x2820, actual: 0x2822))
        }
        var negative = Data(map); negative[0] = 0x80               // W < 0
        XCTAssertThrowsError(try LevelMap(data: negative)) { e in
            XCTAssertEqual(e as? LevelMapError, .badDimensions(width: Int16(bitPattern: 0x8040), height: 64, chunkCount: 16))
        }
        XCTAssertThrowsError(try LevelMap(file: file, level: 0x2A)) { e in
            XCTAssertEqual(e as? LevelMapError, .absent(0x802A))
        }

        // The chunked path (hdr[6] < hdr[8]; data-format §3.3) parsed as `LoadLevelMap` does and flagged:
        // block indices at 0x20 + C·0x40 (inside the chunk records), each block copies 8 rows of 8 bytes
        // with a row stride of W bytes. Synthetic W 16, H 8, first chunk 0, C 2 → 2×1 blocks.
        var chunked = [UInt8](repeating: 0, count: 0x20 + 2 * 0x80)
        chunked[1] = 16; chunked[3] = 8; chunked[7] = 0; chunked[9] = 2
        for i in 0x20..<0xA0 { chunked[i] = 0x11 }                // chunk 0
        for i in 0xA0..<0x120 { chunked[i] = 0x22 }               // chunk 1
        chunked[0xA0] = 0; chunked[0xA1] = 1; chunked[0xA2] = 0; chunked[0xA3] = 0   // indices [1, 0]
        let cm = try LevelMap(data: Data(chunked))
        XCTAssertTrue(cm.header.isChunked)
        XCTAssertEqual(LevelMap.bodyOffset(of: cm.header), 0xA0)
        XCTAssertEqual(cm.blockIndices, [1, 0])
        XCTAssertEqual(cm.cells.count, 128)
        XCTAssertEqual(cm.cells[0], 0x0001); XCTAssertEqual(cm.cells[1], 0x0000)
        XCTAssertEqual(cm.cells[2], 0x2222); XCTAssertEqual(cm.cells[4], 0x1111)
        XCTAssertEqual(cm.cells[8], 0x2222); XCTAssertEqual(cm.cells[12], 0x1111)
        XCTAssertTrue(cm.cells[64...].allSatisfy { $0 == 0 })
        // A block index past the loaded chunk records → named error.
        var badIndex = chunked; badIndex[0xA1] = 2
        XCTAssertThrowsError(try LevelMap(data: Data(badIndex))) { e in
            XCTAssertEqual(e as? LevelMapError, .chunkIndexOutOfRange(block: 0, chunk: 2, chunkCount: 2))
        }
        for cut in 0..<chunked.count {
            XCTAssertThrowsError(try LevelMap(data: Data(chunked.prefix(cut))), "chunked prefix \(cut)")
        }

        // Props: a prefix that is a whole number of records is a valid (shorter) segment; every other prefix
        // throws the named error.
        let props = file.segment(0x8102)!
        for cut in 0..<min(props.count, 0x400) {
            if cut % 16 == 0 {
                XCTAssertEqual(try PropSegment(data: props.prefix(cut)).records.count, cut / 16)
            } else {
                XCTAssertThrowsError(try PropSegment(data: props.prefix(cut)), "prefix \(cut)") { e in
                    XCTAssertEqual(e as? PropSegmentError, .lengthNotMultipleOf16(cut))
                }
            }
        }
        XCTAssertThrowsError(try PropSegment(file: file, level: 0x25)) { e in
            XCTAssertEqual(e as? PropSegmentError, .absent(0x8125))
        }
    }
}

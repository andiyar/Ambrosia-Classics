import XCTest
@testable import CytheraCore

/// C2 (docs/plans/2026-10-06-cythera-phase0.md): the segment file `Cythera Data` (data-format §1.1–§1.2), the
/// id-keyed cipher (§1.3), the stored-plaintext policy (script-census §2) and the overlay model (§1.4). Every
/// number is a planner probe (p02 = `docs/cythera/tools/seg.py`, p03, p05; Research notes 2, 3).
final class SegmentFileTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    private func rawFile() throws -> Data {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try Data(contentsOf: r.segmentFileURL, options: .alwaysMapped)
    }

    func testIsSegmentFileAndHeaderFields() throws {
        let raw = try rawFile()
        XCTAssertTrue(SegmentFile.isSegmentFile(raw))
        XCTAssertFalse(SegmentFile.isSegmentFile(raw.prefix(0x87)))
        let file = try segmentFile()
        let h = file.header
        XCTAssertEqual(h.title, "Cythera: Fate of Alaric")
        XCTAssertEqual(h.formatVersion, 0x1300)
        XCTAssertEqual(h.scenarioVersion, 0x0200)
        XCTAssertEqual(h.maxMapDimension, 0x0200)
        XCTAssertEqual(h.rawHeader.count, 0x80)
        let bytes = [UInt8](h.rawHeader)
        XCTAssertEqual(bytes[0x44], 0); XCTAssertEqual(bytes[0x45], 0)
        XCTAssertEqual(bytes[0x46], 0); XCTAssertEqual(bytes[0x47], 0)
        XCTAssertTrue(bytes[0x4A..<0x80].allSatisfy { $0 == 0 })

        // Hostile input (Invariant 5): truncations throw a named error, never trap.
        for cut in [0, 0x7F, 0x87, 0x87F, 0x545226 + 0x7FF, 0x5594F0 - 1] {
            XCTAssertThrowsError(try SegmentFile(data: Data(raw.prefix(cut))), "prefix \(cut)") { error in
                XCTAssertTrue(error is SegmentFileError, "prefix \(cut): \(error)")
            }
        }
        // A TOC entry pointing past EOF: segment 0x8000's offset rewritten to 0xFFFFFFF0.
        var hostile = Data(raw)
        hostile.replaceSubrange(0x551226..<0x55122A, with: [0xFF, 0xFF, 0xFF, 0xF0])
        XCTAssertThrowsError(try SegmentFile(data: hostile)) { error in
            XCTAssertEqual(error as? SegmentFileError, .entryOutOfBounds(id: 0x8000, offset: 0xFFFF_FFF0, length: 0x820))
        }
        // Not a segment file at all.
        var notSeg = Data(raw.prefix(0x880))
        notSeg[0x83] = 0x81
        XCTAssertThrowsError(try SegmentFile(data: notSeg)) { error in
            XCTAssertEqual(error as? SegmentFileError, .notSegmentFile)
        }
    }

    func testRootPageAndTOCPages() throws {
        let file = try segmentFile()
        XCTAssertEqual(file.root.count, 256)
        XCTAssertEqual(file.root[0], TOCEntry(offset: 0x80, length: 0x800))
        XCTAssertEqual(file.pages.count, 34)
        XCTAssertTrue(file.pages.values.allSatisfy { $0.length == 0x800 && $0.entries.count == 256 })
        XCTAssertEqual(file.ids.count, 1558)
        XCTAssertEqual(file.ids, file.ids.sorted())
        var spans: [(Int, Int)] = []
        for id in file.ids {
            let e = try XCTUnwrap(file.entry(id))
            spans.append((e.offset, e.length))
        }
        XCTAssertEqual(spans.reduce(0) { $0 + $1.1 }, 5_524_330)
        XCTAssertEqual(file.byteCount, 5_608_688)
        spans.sort { $0.0 < $1.0 }
        for (a, b) in zip(spans, spans.dropFirst()) {
            XCTAssertLessThanOrEqual(a.0 + a.1, b.0, "bodies overlap at \(a.0)")
        }
        XCTAssertEqual(spans.map { $0.0 + $0.1 }.max(), 0x5594F0)
    }

    func testKnownSegmentEntries() throws {
        let file = try segmentFile()
        let known: [(UInt16, Int, Int)] = [(0x8000, 0x78676, 0x820), (0x8001, 0x78E96, 0x20020),
                                           (0x8002, 0x98EB6, 0x2820)]
        for (id, offset, length) in known {
            let e = try XCTUnwrap(file.entry(id))
            XCTAssertEqual(e.offset, offset); XCTAssertEqual(e.length, length)
            let body = try XCTUnwrap(file.segment(id))
            XCTAssertEqual(body.count, length)
            XCTAssertEqual(body.startIndex, 0)
        }
    }

    func testAbsentSegmentsAreNil() throws {
        let file = try segmentFile()
        for id: UInt16 in [0xF003, 0xF006, 0xF00E, 0x8100, 0x8125, 0x8E96, 0x9128] {
            XCTAssertNil(file.entry(id), String(id, radix: 16))
            XCTAssertNil(file.segment(id), String(id, radix: 16))
            XCTAssertNil(file.scriptSegment(id), String(id, radix: 16))
        }
    }

    func testBandCounts() throws {
        let ids = try segmentFile().ids
        func count(_ range: ClosedRange<UInt16>) -> Int { ids.filter { range.contains($0) }.count }
        XCTAssertEqual(count(0x8000...0x8029), 42)
        XCTAssertEqual(count(0x8000...0x80FF), 42)
        XCTAssertEqual(ids.filter { $0 >> 8 == 0x81 }, (0x8101...0x8129).filter { $0 != 0x8125 })
        XCTAssertEqual(count(0x8400...0x84FF), 18)
        XCTAssertEqual(count(0x8800...0x88FF), 142)
        XCTAssertEqual(count(0x8A00...0x8AFF), 62)
        XCTAssertEqual(count(0x8E00...0x8E9F), 159)
        XCTAssertEqual(count(0x8EA0...0x8EFF), 1)
        XCTAssertTrue(ids.contains(0x8EFF))
        XCTAssertEqual(count(0x8F00...0x8FFF), 59)
        XCTAssertEqual(count(0x8F00...0x8F7F), 51)
        XCTAssertEqual(count(0x8F80...0x8FFF), 8)
        XCTAssertEqual(count(0x9000...0x90FF), 11)
        XCTAssertEqual(count(0x9100...0x91FF), 46)
        XCTAssertEqual(count(0xF000...0xF0FF), 20)
        XCTAssertEqual(count(0x0100...0x3FFF), 958)
        XCTAssertEqual(count(0x0410...0x0436), 14)
    }

    func testCipherKnownBytes() throws {
        let file = try segmentFile()
        let dict = try XCTUnwrap(file.scriptSegment(0x1802))
        XCTAssertEqual(Array(dict.prefix(2)), [0x28, 0x8E])
        let routine = try XCTUnwrap(file.scriptSegment(0x3000))
        XCTAssertEqual(routine.first, 0x81)
    }

    func testCipherIsInvolutionAndSkipContinuesTheLCG() {
        let original: [UInt8] = (0..<300).map { UInt8(truncatingIfNeeded: $0 &* 37 &+ 11) }
        for id: UInt16 in [0x0000, 0x0201, 0x1802, 0x3000, 0xFFFF] {
            var bytes = original
            SegmentCipher.apply(&bytes, id: id)
            // id 0 keys to mult 1, inc 0, seed 0: an all-zero stream (the identity), as the original computes.
            if id == 0 { XCTAssertEqual(bytes, original) } else { XCTAssertNotEqual(bytes, original, "id \(id)") }
            SegmentCipher.apply(&bytes, id: id)
            XCTAssertEqual(bytes, original, "id \(id)")

            // Ciphering [k..] with skip k equals the tail of ciphering the whole buffer.
            var whole = original
            SegmentCipher.apply(&whole, id: id)
            for k in [1, 7, 128] {
                var tail = Array(original[k...])
                SegmentCipher.apply(&tail, id: id, skip: k)
                XCTAssertEqual(tail, Array(whole[k...]), "id \(id) skip \(k)")
            }
        }
        // First key byte by hand for id 0x0201: mult 5, inc 8, seed 0x02 ^ 0x0201 = 0x0203;
        // next = 8 + 0x0203·5 = 0x0A17 → key byte 0x17.
        var one: [UInt8] = [0]
        SegmentCipher.apply(&one, id: 0x0201)
        XCTAssertEqual(one, [0x17])
    }

    func testStoredPlaintextPolicy() throws {
        let file = try segmentFile()
        XCTAssertEqual(SegmentFile.storedPlaintext, [0x0101, 0x0210])
        for id: UInt16 in [0x0101, 0x0210] {
            let raw = try XCTUnwrap(file.segment(id))
            XCTAssertEqual(file.scriptSegment(id), raw)
        }
        XCTAssertEqual(file.segment(0x0101)?.count, 1246)
        XCTAssertEqual(file.segment(0x0210)?.count, 13)
        let raw = try XCTUnwrap(file.segment(0x0201))
        let decrypted = try XCTUnwrap(file.scriptSegment(0x0201))
        XCTAssertNotEqual(decrypted, raw)
        XCTAssertEqual(decrypted.count, raw.count)
        XCTAssertEqual(Array(raw.prefix(4)), [0x86, 0x7B, 0xFE, 0x56])
    }

    func testOverlayTopmostWinsAndWritesGoToSlotZero() throws {
        let base = MemorySegmentStore([0x0001: Data([1]), 0x0002: Data([2])])
        let patch = MemorySegmentStore([0x0002: Data([22]), 0x0003: Data([33])])
        var overlay = SegmentOverlay()
        XCTAssertNil(overlay.segment(0x0001))
        overlay.push(base)
        overlay.push(patch)
        XCTAssertEqual(overlay.count, 2)
        XCTAssertEqual(overlay.segment(0x0001), Data([1]))   // only the bottom has it
        XCTAssertEqual(overlay.segment(0x0002), Data([22]))  // topmost wins
        XCTAssertEqual(overlay.segment(0x0003), Data([33]))
        XCTAssertNil(overlay.segment(0x0004))

        // Writes go to slot 0 (the last pushed), never to the store that already holds the id.
        let scratch = MemorySegmentStore()
        overlay.push(scratch)
        try overlay.write(0x0001, data: Data([111]))
        XCTAssertEqual(overlay.segment(0x0001), Data([111]))
        XCTAssertEqual(scratch.segment(0x0001), Data([111]))
        XCTAssertEqual(base.segment(0x0001), Data([1]))
        // An empty write is "absent = length 0": the lower store shows through again.
        try overlay.write(0x0001, data: Data())
        XCTAssertEqual(overlay.segment(0x0001), Data([1]))

        // Slot 0 that is not a writable store refuses the write (Phase 0 writes no file).
        var readOnly = SegmentOverlay()
        readOnly.push(try segmentFile())
        XCTAssertThrowsError(try readOnly.write(0x0001, data: Data([1]))) { error in
            XCTAssertEqual(error as? SegmentOverlayError, .slotZeroNotWritable)
        }
        let emptyOverlay = SegmentOverlay()
        XCTAssertThrowsError(try emptyOverlay.write(0x0001, data: Data([1]))) { error in
            XCTAssertEqual(error as? SegmentOverlayError, .slotZeroNotWritable)
        }

        // 16-slot cap: AddFile shifts slots 0xF..1 down, so a 17th push drops the bottom store.
        var full = SegmentOverlay()
        let bottom = MemorySegmentStore([0x0100: Data([0xBB])])
        full.push(bottom)
        for n in 1...15 { full.push(MemorySegmentStore([UInt16(0x0200 + n): Data([UInt8(n)])])) }
        XCTAssertEqual(full.count, 16)
        XCTAssertEqual(full.segment(0x0100), Data([0xBB]))
        full.push(MemorySegmentStore())
        XCTAssertEqual(SegmentOverlay.capacity, 16)
        XCTAssertEqual(full.count, 16)
        XCTAssertNil(full.segment(0x0100))
        XCTAssertEqual(full.segment(0x0201), Data([1]))
    }
}

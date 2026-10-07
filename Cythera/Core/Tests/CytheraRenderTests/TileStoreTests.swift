import CryptoKit
import XCTest
import CytheraCore
@testable import CytheraRender

/// C5 (docs/plans/2026-10-06-cythera-phase0.md): the tile store of data-format §3.4 (`LoadTiles__Fv @ 10005080`,
/// `BuildCompoTile__FPUcP15CompoTileRecord @ 100051a8`). Numbers: planner probes p04 / p11 (Research notes 4–5).
final class TileStoreTests: XCTestCase {

    private func segmentFile() throws -> SegmentFile {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        return try SegmentFile(contentsOf: r.segmentFileURL)
    }

    func testTileStoreBuilds0xA00Tiles() throws {
        let store = try TileStore(file: try segmentFile())
        XCTAssertEqual(TileStore.tileCount, 2_560)
        XCTAssertEqual(store.bytes.count, 0x280000)
        // Sheet 0x8E96 is absent → tiles 0x960–0x96F are all zero (Hazard 7).
        for n in 0x960...0x96F { XCTAssertTrue(store.tile(n).allSatisfy { $0 == 0 }, "tile \(n)") }
        let zeroTiles = (0..<TileStore.tileCount).filter { store.tile($0).allSatisfy { $0 == 0 } }.count
        XCTAssertEqual(zeroTiles, 130)
        // The UI tiles 0x19C–0x1AF (ui-toolkit §0) carry pixels.
        for n in 0x19C...0x1AF { XCTAssertTrue(store.tile(n).contains { $0 != 0 }, "UI tile \(n)") }
        XCTAssertEqual(store.tile(0).count, 1_024)
        XCTAssertTrue(store.tile(-1).isEmpty)
        XCTAssertTrue(store.tile(0xA00).isEmpty)
        let sha = SHA256.hash(data: Data(store.bytes)).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(sha, "5419637e2a87784239e837484206219cae1d23060c23ec73ce6d3079c94a7b80")
    }

    func testCompoTileQuadrants() throws {
        // Synthetic store: tile t's pixel (x, y) = (t·7 + y·32 + x) & 0xFF, never zero-filled.
        var bytes = [UInt8](repeating: 0, count: TileStore.tileCount * TileStore.tileBytes)
        for t in 0..<TileStore.tileCount {
            for p in 0..<TileStore.tileBytes { bytes[t * TileStore.tileBytes + p] = UInt8((t * 7 + p) & 0xFF) }
        }
        let store = try TileStore(bytes: bytes)
        // Entry k (row-major in the 4×4 record) = tile 0x100 + k, quadrant column k % 4, quadrant row k / 4 —
        // so the compo tile reproduces the quadrant layout; then a transposed variant (column = row of k).
        func entry(tile: Int, col: Int, row: Int) -> UInt16 { UInt16(tile | row << 12 | col << 14) }
        let entries = (0..<16).map { entry(tile: 0x100 + $0, col: $0 % 4, row: $0 / 4) }
        let out = try store.compoTile(entries)
        XCTAssertEqual(out.count, 1_024)
        for y in 0..<32 {
            for x in 0..<32 {
                let k = (y / 8) * 4 + x / 8
                let src = (0x100 + k) * TileStore.tileBytes + y * 32 + x
                XCTAssertEqual(out[y * 32 + x], bytes[src], "(\(x),\(y))")
            }
        }
        let swapped = (0..<16).map { entry(tile: 0x200, col: $0 / 4, row: $0 % 4) }
        let out2 = try store.compoTile(swapped)
        for y in 0..<32 {
            for x in 0..<32 {
                let col = y / 8, row = x / 8      // entry at (x/8, y/8) took quadrant (col = y/8, row = x/8)
                let src = 0x200 * TileStore.tileBytes + (row * 8 + y % 8) * 32 + col * 8 + x % 8
                XCTAssertEqual(out2[y * 32 + x], bytes[src], "swapped (\(x),\(y))")
            }
        }
        XCTAssertThrowsError(try store.compoTile(Array(entries.prefix(15))))
        XCTAssertThrowsError(try store.compoTile([UInt16](repeating: 0x0A00, count: 16))) { error in
            XCTAssertEqual(error as? PixelError, .tileOutOfRange(0xA00))
        }

        // Every shipped non-zero record (segment 0xF013, 4,096 × 0x20 B) references tiles ≤ 0xFFF (p11).
        let file = try segmentFile()
        let f013 = [UInt8](try XCTUnwrap(file.segment(0xF013)))
        XCTAssertEqual(f013.count, 4_096 * 0x20)
        let real = try TileStore(file: file)
        var nonZero = 0
        for r in 0..<4_096 {
            let e = (0..<16).map { UInt16(f013[r * 32 + $0 * 2]) << 8 | UInt16(f013[r * 32 + $0 * 2 + 1]) }
            guard e.contains(where: { $0 != 0 }) else { continue }
            nonZero += 1
            XCTAssertTrue(e.allSatisfy { Int($0 & 0xFFF) <= 0xFFF })
            XCTAssertNoThrow(try real.compoTile(e), "record \(r)")
        }
        XCTAssertEqual(nonZero, 264)
    }
}

import Foundation
import CytheraCore

/// The tile store, as `LoadTiles__Fv @ 10005080` builds it (data-format §3.4, HIGH): one 0x280000-byte buffer
/// of 0xA00 tiles × 32×32 8-bit pixels, filled from the LZ sheets 0x8E00 + s for s = 0…0x9F only (the loop's
/// `0x9f < sVar6` break), each sheet → 0x4000 bytes = 16 tiles at `s × 0x4000`; an absent sheet is zero-filled
/// (0x8E96 is absent → tiles 0x960–0x96F are zero; Hazard 7). Segment 0x8EFF sits in the same TOC page but is
/// NOT a tile sheet and is never decoded (Landmine (g), plan Research note 5). Pixel value 0 is transparent to
/// the blitter (`FindBoundsRect`), an ordinary index here.
public struct TileStore: Sendable {
    public static let tileCount = 0xA00
    public static let tileBytes = 0x400
    /// The sheets `LoadTiles` reads.
    public static let sheetIDs: ClosedRange<UInt16> = 0x8E00...0x8E9F
    static let sheetBytes = 0x4000

    /// 0xA00 × 0x400 bytes, tile n at n × 0x400.
    public let bytes: [UInt8]

    public init(file: SegmentFile) throws {
        var bytes = [UInt8](repeating: 0, count: Self.tileCount * Self.tileBytes)
        for id in Self.sheetIDs {
            guard let sheet = file.segment(id) else { continue }       // absent → zero tiles (as `memset`)
            let pixels = try PixelSegments.unLZ(sheet, id: id, expected: Self.sheetBytes)
            let at = Int(id - Self.sheetIDs.lowerBound) * Self.sheetBytes
            bytes.replaceSubrange(at..<(at + Self.sheetBytes), with: pixels)
        }
        self.bytes = bytes
    }

    /// A store from a ready buffer of exactly 0xA00 × 0x400 bytes (tests, Phase 1 animation tables).
    public init(bytes: [UInt8]) throws {
        guard bytes.count == Self.tileCount * Self.tileBytes else {
            throw PixelError.image("tile store of \(bytes.count) bytes")
        }
        self.bytes = bytes
    }

    /// Tile n's 1,024 pixels (32 rows of 32); empty outside 0…0x9FF.
    public func tile(_ n: Int) -> ArraySlice<UInt8> {
        guard n >= 0, n < Self.tileCount else { return [] }
        return bytes[(n * Self.tileBytes)..<((n + 1) * Self.tileBytes)]
    }

    /// A compo tile per `BuildCompoTile__FPUcP15CompoTileRecord @ 100051a8` (data-format §3.4, HIGH): the
    /// record's 16 u16 entries (0x20 bytes, segment 0xF013) are 4 rows × 4 columns of 8×8 output quadrants,
    /// row-major; entry e copies the 8×8 block at
    /// `tile[e & 0xfff] + ((e>>8)>>3 & 0x18) + ((e>>8) & 0x30)*0x10` — bits 14–15 = source quadrant column
    /// (× 8 px), bits 12–13 = source quadrant row (× 8 rows). The original indexes its current-frame tile
    /// pointer table (0xA00 entries) with `e & 0xfff`; an index past 0x9FF is refused here
    /// (`tileOutOfRange`) rather than read past the table. Output: 32×32 = 1,024 bytes.
    public func compoTile(_ entries: [UInt16]) throws -> [UInt8] {
        guard entries.count == 16 else { throw PixelError.compoEntries(entries.count) }
        var out = [UInt8](repeating: 0, count: Self.tileBytes)
        for (k, e) in entries.enumerated() {
            let tile = Int(e & 0xFFF)
            guard tile < Self.tileCount else { throw PixelError.tileOutOfRange(tile) }
            let hi = Int(e >> 8)
            let src = tile * Self.tileBytes + ((hi >> 3) & 0x18) + (hi & 0x30) * 0x10
            let dst = (k / 4) * 8 * 32 + (k % 4) * 8
            for row in 0..<8 {
                for x in 0..<8 { out[dst + row * 32 + x] = bytes[src + row * 32 + x] }
            }
        }
        return out
    }
}

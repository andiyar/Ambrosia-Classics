import Foundation

/// A malformed level map. Every read is bounds-checked; nothing traps (Invariant 5).
public enum LevelMapError: Error, Equatable, Sendable {
    /// Segment 0x8000 + L is absent.
    case absent(UInt16)
    /// Fewer bytes than the 0x20-byte header.
    case truncatedHeader(Int)
    /// W or H outside 1...`LevelMap.maxDimension`, or C negative — a shape the 42 shipped maps never show
    /// (Invariant 4; bounds every allocation, Invariant 5).
    case badDimensions(width: Int16, height: Int16, chunkCount: Int16)
    /// A flat map whose length is not `0x20 + C·0x80 + W·H·2` (Invariant 4).
    case lengthMismatch(expected: Int, actual: Int)
    /// A chunked map shorter than its chunk records plus its block-index array.
    case chunkedTruncated(need: Int, have: Int)
    /// A chunked map whose block `block` names chunk `first + index` outside the `chunkCount` loaded records.
    case chunkIndexOutOfRange(block: Int, chunk: Int, chunkCount: Int)
    /// A chunked map whose byte-wise block copy would leave the W·H·2 cell buffer.
    case chunkedCopyOutOfBounds(block: Int)
}

/// A level map, segment 0x8000 + L (data-format §3, HIGH): the 0x20-byte header, C chunk records of 0x80 bytes
/// (8×8 u16, §3.3 — roof masks for kind-0x44 props), then the W·H u16 cell body.
public struct LevelMap: Sendable {
    /// The largest map side the engine sizes for: `InitWorld` takes the segment-file header's +0x48
    /// (0x0200 shipped) and 0 means 0x400 (data-format §1.1). Shipped maps are at most 256.
    public static let maxDimension: Int16 = 0x400

    public let header: MapHeader
    /// C chunk records, 64 u16 each, as `LoadSegment(…, 0x20, C << 7)` loads them.
    public let chunks: [[UInt16]]
    /// W·H cells, row-major.
    public let cells: [UInt16]
    /// A chunked map's (W/8)·(H/8) block indices (§3.3); empty for a flat map.
    public let blockIndices: [Int16]

    public var width: Int { Int(header.width) }
    public var height: Int { Int(header.height) }

    /// The cell at (x, y), or nil outside the map (wrapping is the viewer's, Phase 1).
    public func cell(x: Int, y: Int) -> MapCell? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        return MapCell(cells[y * width + x])
    }

    /// Where `LoadLevelMap` reads the body: `0x20 + C·0x80` on the flat path (`rlwinm r6,r7,7` at 0x10005DEC),
    /// `0x20 + C·0x40` on the chunked path (`rlwinm r6,r8,6` at 0x10005EAC) — the chunked offset is literal in
    /// the code and lands inside the chunk records: a latent defect never reached by shipped data, kept as
    /// the code reads it and flagged here (data-format §3.3, open-items-2026-10-03 §4; Invariant 3).
    public static func bodyOffset(of h: MapHeader) -> Int {
        MapHeader.size + Int(h.chunkCount) * (h.isChunked ? 0x40 : 0x80)
    }

    /// Reads level map `0x8000 + level` from the segment file.
    public init(file: some SegmentStore, level: Int) throws {
        let id = UInt16(truncatingIfNeeded: 0x8000 + (level & 0xFF))
        guard let data = file.segment(id) else { throw LevelMapError.absent(id) }
        try self.init(data: data)
    }

    /// Parses one map segment (any start index).
    public init(data: Data) throws {
        let b = [UInt8](data)
        guard b.count >= MapHeader.size else { throw LevelMapError.truncatedHeader(b.count) }
        let h = MapHeader(bytes: b)
        guard (1...Self.maxDimension).contains(h.width), (1...Self.maxDimension).contains(h.height),
              h.chunkCount >= 0 else {
            throw LevelMapError.badDimensions(width: h.width, height: h.height, chunkCount: h.chunkCount)
        }
        let w = Int(h.width), ht = Int(h.height), c = Int(h.chunkCount)
        let chunkBytes = c * 0x80
        func u16(_ o: Int) -> UInt16 { UInt16(b[o]) << 8 | UInt16(b[o + 1]) }

        if !h.isChunked {
            let expected = MapHeader.size + chunkBytes + w * ht * 2
            guard b.count == expected else { throw LevelMapError.lengthMismatch(expected: expected, actual: b.count) }
            chunks = (0..<c).map { k in (0..<64).map { u16(MapHeader.size + k * 0x80 + $0 * 2) } }
            let body = Self.bodyOffset(of: h)
            cells = (0..<(w * ht)).map { u16(body + $0 * 2) }
            blockIndices = []
            header = h
            return
        }

        // Chunked path, as `LoadLevelMap` does it (Ghidra `Cythera_pef.decompiled.c` LoadLevelMap): the block
        // grid is (W>>3)×(H>>3); block indices are read at 0x20 + C·0x40; block k copies, from chunk
        // `hdr[6] + index`, 8 rows of 8 BYTES (64 of the record's 128) into the cell buffer with a row stride of
        // W bytes, advancing 8 bytes per block and `(W·7) & ~3` bytes after each block row — a byte-cell
        // layout inside the u16 buffer. Reproduced literally (Invariant 3); never reached by shipped data.
        let blocksX = w >> 3, blocksY = ht >> 3
        let indexOffset = Self.bodyOffset(of: h)
        let need = max(MapHeader.size + chunkBytes, indexOffset + blocksX * blocksY * 2)
        guard b.count >= need else { throw LevelMapError.chunkedTruncated(need: need, have: b.count) }
        chunks = (0..<c).map { k in (0..<64).map { u16(MapHeader.size + k * 0x80 + $0 * 2) } }
        let indices = (0..<(blocksX * blocksY)).map { Int16(bitPattern: u16(indexOffset + $0 * 2)) }
        var out = [UInt8](repeating: 0, count: w * ht * 2)
        var p = 0, block = 0
        for _ in 0..<blocksY {
            for _ in 0..<blocksX {
                let chunk = Int(h.firstChunk) + Int(indices[block])
                guard chunk >= 0, chunk < c else {
                    throw LevelMapError.chunkIndexOutOfRange(block: block, chunk: chunk, chunkCount: c)
                }
                guard p + 7 * w + 8 <= out.count else { throw LevelMapError.chunkedCopyOutOfBounds(block: block) }
                let src = MapHeader.size + chunk * 0x80
                for r in 0..<8 {
                    for i in 0..<8 { out[p + r * w + i] = b[src + r * 8 + i] }
                }
                p += 8
                block += 1
            }
            p += (w * 7) & ~3
        }
        cells = (0..<(w * ht)).map { UInt16(out[$0 * 2]) << 8 | UInt16(out[$0 * 2 + 1]) }
        blockIndices = indices
        header = h
    }
}

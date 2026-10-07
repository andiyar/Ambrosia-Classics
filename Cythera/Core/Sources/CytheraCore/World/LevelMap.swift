import Foundation

/// A malformed level map. Every read is bounds-checked; nothing traps (Invariant 5).
public enum LevelMapError: Error, Equatable, Sendable {
    /// Segment 0x8000 + L is absent.
    case absent(UInt16)
    /// A level outside 0...0xFF (ids 0x8000–0x80FF); refused, not wrapped.
    case levelOutOfRange(Int)
    /// Fewer bytes than the 0x20-byte header.
    case truncatedHeader(Int)
    /// W or H outside 1...D (D = the segment-file header's maximum map dimension, `LevelMap.cellBufferSide`),
    /// or C negative — a shape the 42 shipped maps never show (Invariant 4; bounds every allocation, Invariant 5).
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
    public let header: MapHeader
    /// C chunk records, 64 u16 each, as `LoadSegment(…, 0x20, C << 7)` loads them.
    public let chunks: [[UInt16]]
    /// W·H cells, row-major.
    public let cells: [UInt16]
    /// A chunked map's (W/8)·(H/8) block indices (§3.3); empty for a flat map.
    public let blockIndices: [Int16]

    public var width: Int { Int(header.width) }
    public var height: Int { Int(header.height) }

    /// The side D of the engine's cell buffer: `InitWorld @ 10012e38` passes the segment-file header's +0x48
    /// (0x0200 shipped) to `CreateGlobals__Fs @ 10004d0c`, which replaces 0 by 0x400 and allocates the map as
    /// `NewPtr(D * D * 2)` (data-format §1.1). A map side above D is refused.
    public static func cellBufferSide(maxMapDimension: Int16) -> Int16 {
        maxMapDimension == 0 ? 0x400 : maxMapDimension
    }

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

    /// Reads level map `0x8000 + level` (level 0...0xFF), capped by the file header's maximum map dimension.
    public init(file: SegmentFile, level: Int) throws {
        guard (0...0xFF).contains(level) else { throw LevelMapError.levelOutOfRange(level) }
        let id = UInt16(0x8000 + level)
        guard let data = file.segment(id) else { throw LevelMapError.absent(id) }
        try self.init(data: data, maxMapDimension: file.header.maxMapDimension)
    }

    /// Parses one map segment (any start index). `maxMapDimension` is the segment-file header's +0x48
    /// (`SegmentFileHeader.maxMapDimension`; 0 → 0x400, `cellBufferSide`).
    public init(data: Data, maxMapDimension: Int16) throws {
        let side = Self.cellBufferSide(maxMapDimension: maxMapDimension)
        let b = [UInt8](data)
        guard b.count >= MapHeader.size else { throw LevelMapError.truncatedHeader(b.count) }
        let h = MapHeader(bytes: b)
        guard side > 0, (1...side).contains(h.width), (1...side).contains(h.height), h.chunkCount >= 0 else {
            throw LevelMapError.badDimensions(width: h.width, height: h.height, chunkCount: h.chunkCount)
        }
        let w = Int(h.width), ht = Int(h.height), c = Int(h.chunkCount)
        let chunkBytes = c * 0x80
        func u16(_ o: Int) -> UInt16 { be16(b, o) }

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

        // Chunked path, as `LoadLevelMap__Fs @ 10005cb8` does it: the block grid is (W>>3)×(H>>3); block indices
        // are read at 0x20 + C·0x40; block k copies, from chunk `hdr[6] + index`, 8 rows of 8 BYTES (64 of the
        // record's 128) into the cell buffer with a row stride of W bytes, advancing 8 bytes per block and
        // `(W·7) & ~3` bytes after each block row — a byte-cell layout inside the u16 buffer. Reproduced
        // literally (Invariant 3); never reached by shipped data. The data length, every block index and every
        // copy are checked BEFORE the W·H·2 buffer is allocated (Invariant 5).
        let blocksX = w >> 3, blocksY = ht >> 3
        let indexOffset = Self.bodyOffset(of: h)
        let need = max(MapHeader.size + chunkBytes, indexOffset + blocksX * blocksY * 2)
        guard b.count >= need else { throw LevelMapError.chunkedTruncated(need: need, have: b.count) }
        let indices = (0..<(blocksX * blocksY)).map { Int16(bitPattern: u16(indexOffset + $0 * 2)) }
        let outCount = w * ht * 2
        var sources: [(dst: Int, src: Int)] = []
        sources.reserveCapacity(indices.count)
        var p = 0, block = 0
        for _ in 0..<blocksY {
            for _ in 0..<blocksX {
                let chunk = Int(h.firstChunk) + Int(indices[block])
                guard chunk >= 0, chunk < c else {
                    throw LevelMapError.chunkIndexOutOfRange(block: block, chunk: chunk, chunkCount: c)
                }
                guard p + 7 * w + 8 <= outCount else { throw LevelMapError.chunkedCopyOutOfBounds(block: block) }
                sources.append((p, MapHeader.size + chunk * 0x80))
                p += 8
                block += 1
            }
            p += (w * 7) & ~3
        }
        chunks = (0..<c).map { k in (0..<64).map { u16(MapHeader.size + k * 0x80 + $0 * 2) } }
        var out = [UInt8](repeating: 0, count: outCount)
        for (dst, src) in sources {
            for r in 0..<8 {
                for i in 0..<8 { out[dst + r * w + i] = b[src + r * 8 + i] }
            }
        }
        cells = (0..<(w * ht)).map { be16(out, $0 * 2) }
        blockIndices = indices
        header = h
    }
}

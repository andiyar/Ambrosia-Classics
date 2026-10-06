import Foundation
import HectorResources

/// Why a world-data resource was refused (plan C2; HectorKit D2/D5 style: refuse, never guess).
public enum WorldDataError: Error, Equatable {
    /// No resource of this type and id in World Data.
    case missing(type: String, id: Int16)
    /// The resource's length is not the one its layout demands.
    case wrongLength(type: String, id: Int16, expected: Int, actual: Int)
    /// A read ran past the end of the resource (a malformed `STR#` count or Pascal string).
    case truncated(type: String, id: Int16, offset: Int)
    /// A header width or height is negative (a forged `Mlvl`; no layout length can be derived).
    case badDimensions(type: String, id: Int16, widths: [Int], heights: [Int])
}

/// One `Mlvl` resource — a level (world-data §3; resource id = level number). Layout §3.1
/// (`.SetupLevelTilemapPtrs @ 1004913c`): a 0xb29c-byte header, then PxBack w0×h0, PxMid w1×h1, then BG, FG,
/// map #5 and overlay at w2×h2 (u16 big-endian, row-major). The six runtime pointers at 0xb284..0xb298 are
/// stale in the file and ignored. A resource whose length is not exactly
/// `0xb29c + 2(w0h0 + w1h1) + 8·w2h2` is refused.
public struct LevelFile: Sendable, Equatable {
    public static let headerSize = 0xb29c
    public static let placementCount = 511
    public static let factorRows = 8192

    public let id: Int16
    public let header: LevelHeader
    /// All 511 placement records, in record order (§3.4).
    public let placements: [Placement]
    /// PxBack map (128-px tiles, whole u16 = tile index; §3.3).
    public let pxBack: TileMap
    /// PxMid map (whole u16; 0xFFFF present in every level, read as −1 by `pxMidTile`; §3.3).
    public let pxMid: TileMap
    public let bg: TileMap
    public let fg: TileMap
    /// Map #5: no reader anywhere, all zero in all 24 levels (§3.1) — kept for layout fidelity.
    public let map5: TileMap
    public let overlay: TileMap
    /// PxBack per-scanline x-parallax factors (/256), header 0x326c (§3.2).
    public let backFactors: [Int16]
    /// PxMid per-scanline x-parallax factors (/256) and row-mode selector, header 0x726c (§3.2).
    public let midFactors: [Int16]

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "Mlvl", id: id)
        guard b.count >= Self.headerSize else {
            throw WorldDataError.wrongLength(type: "Mlvl", id: id, expected: Self.headerSize, actual: b.count)
        }
        let header = try LevelHeader(b)
        let w0 = Int(header.pxBackWidth), h0 = Int(header.pxBackHeight)
        let w1 = Int(header.pxMidWidth), h1 = Int(header.pxMidHeight)
        let w2 = Int(header.gridWidth), h2 = Int(header.gridHeight)
        guard w0 >= 0, h0 >= 0, w1 >= 0, h1 >= 0, w2 >= 0, h2 >= 0 else {
            throw WorldDataError.badDimensions(type: "Mlvl", id: id, widths: [w0, w1, w2], heights: [h0, h1, h2])
        }
        let expected = Self.headerSize + 2 * (w0 * h0 + w1 * h1) + 8 * w2 * h2
        guard b.count == expected else {
            throw WorldDataError.wrongLength(type: "Mlvl", id: id, expected: expected, actual: b.count)
        }
        self.id = id
        self.header = header

        var placements: [Placement] = []
        placements.reserveCapacity(Self.placementCount)
        for i in 0..<Self.placementCount { placements.append(try Placement(b, index: i)) }
        self.placements = placements

        var offset = Self.headerSize
        func map(_ w: Int, _ h: Int) throws -> TileMap {
            let cells = try b.u16Array(at: offset, count: w * h)
            offset += 2 * w * h
            return TileMap(width: w, height: h, cells: cells)
        }
        pxBack = try map(w0, h0)
        pxMid = try map(w1, h1)
        bg = try map(w2, h2)
        fg = try map(w2, h2)
        map5 = try map(w2, h2)
        overlay = try map(w2, h2)

        backFactors = try b.i16Array(at: 0x326c, count: Self.factorRows)
        midFactors = try b.i16Array(at: 0x726c, count: Self.factorRows)
    }

    public init(resource: Resource) throws {
        try self.init(id: resource.id, data: resource.data)
    }

    /// `Mlvl <level>` from World Data (`.OpenDefaultWorldLevel`).
    public static func load(from resources: FerazelResources, level: Int16) throws -> LevelFile {
        guard let r = resources.world.resource(type: "Mlvl", id: level) else {
            throw WorldDataError.missing(type: "Mlvl", id: level)
        }
        return try LevelFile(resource: r)
    }

    /// Records with flag 1 (`.SetupLevelSprites` spawns `*(char*)(rec+4) == 1` only; §3.4).
    public var activePlacements: [Placement] { placements.filter { $0.flag == 1 } }

    /// The `.SetupLevelSprites @ 10003cd0` order (§3.4): three passes over records 0..<0x1ff, each gated on flag
    /// == 1 exactly — every active record of type 0x51b first, then types 0x578..0x595 (platforms), then
    /// everything else; passes 2–3 also require `type != 0` (pass 2 by its range). Record order within each pass.
    public var spawnOrder: [Placement] {
        let active = activePlacements
        let isPlatform: (Placement) -> Bool = { (0x578...0x595).contains($0.type) }
        return active.filter { $0.type == 0x51b }
            + active.filter(isPlatform)
            + active.filter { $0.type != 0 && $0.type != 0x51b && !isPlatform($0) }
    }

    // MARK: Cell decodes (world-data §3.3; (column, row), clamped by `.ConstrainXY`)

    /// `.GetPxBackTile`: whole u16 as a signed tile index. (The OmniPx-active "returns 0" arm is runtime state,
    /// not data — the caller's.)
    public func pxBackTile(col: Int, row: Int) -> Int { Int(Int16(bitPattern: pxBack.cell(col: col, row: row))) }
    /// `.GetPxMidTile`: whole u16 as a signed tile index; 0xFFFF is kept as −1.
    public func pxMidTile(col: Int, row: Int) -> Int { Int(Int16(bitPattern: pxMid.cell(col: col, row: row))) }
    /// `.GetBGTile`: low byte − 1 (−1 = none).
    public func bgTile(col: Int, row: Int) -> Int { Int(bg.cell(col: col, row: row) & 0xff) - 1 }
    /// `.GetLightTile`: high byte − 1 (the per-cell darkness level; data 0..11).
    public func lightByte(col: Int, row: Int) -> Int { Int(bg.cell(col: col, row: row) >> 8) - 1 }
    /// `.GetFGTile`: bits 0–7 − 1 (−1 = none; 95 = the pattern tile).
    public func fgTile(col: Int, row: Int) -> Int { Int(fg.cell(col: col, row: row) & 0xff) - 1 }
    /// `.GetFGCrunchKindTile`: bits 8–11.
    public func crunchKind(col: Int, row: Int) -> Int { Int((fg.cell(col: col, row: row) >> 8) & 0xf) }
    /// `.GetFGCrunchDirTile`: bits 12–15.
    public func crunchDir(col: Int, row: Int) -> Int { Int(fg.cell(col: col, row: row) >> 12) }
    /// `.GetFGOverlay1Tile`: low byte − 1.
    public func overlay1(col: Int, row: Int) -> Int { Int(overlay.cell(col: col, row: row) & 0xff) - 1 }
    /// `.GetFGOverlay2Tile`: high byte − 1.
    public func overlay2(col: Int, row: Int) -> Int { Int(overlay.cell(col: col, row: row) >> 8) - 1 }

    // MARK: Tile kinds (`.LookupFGTileKind` / `.LookupBGTileKind` after `.LoadTileDefinitions`)

    /// The header FG table (0x28e0) with tiles 0x50..0x5f overwritten by the identity 80..95; −1 outside 0..95.
    public func fgKind(tile: Int) -> Int {
        guard (0..<96).contains(tile) else { return -1 }
        if (0x50...0x5f).contains(tile) { return tile }
        return Int(header.fgKindTable[tile])
    }

    /// The header BG table (0x29a0); −1 outside 0..95.
    public func bgKind(tile: Int) -> Int {
        guard (0..<96).contains(tile) else { return -1 }
        return Int(header.bgKindTable[tile])
    }
}

/// Bounds-checked big-endian reads over a resource body (internal; every read names the resource on failure).
struct BigEndianBytes {
    let bytes: [UInt8]
    let type: String
    let id: Int16

    init(_ data: Data, type: String, id: Int16) {
        self.bytes = [UInt8](data)
        self.type = type
        self.id = id
    }

    var count: Int { bytes.count }

    private func check(_ offset: Int, _ length: Int) throws {
        guard offset >= 0, length >= 0, offset + length <= bytes.count else {
            throw WorldDataError.truncated(type: type, id: id, offset: offset)
        }
    }

    func u8(_ offset: Int) throws -> UInt8 {
        try check(offset, 1)
        return bytes[offset]
    }

    func u16(_ offset: Int) throws -> UInt16 {
        try check(offset, 2)
        return UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }

    func i16(_ offset: Int) throws -> Int16 { Int16(bitPattern: try u16(offset)) }

    func u32(_ offset: Int) throws -> UInt32 {
        try check(offset, 4)
        return UInt32(bytes[offset]) << 24 | UInt32(bytes[offset + 1]) << 16
            | UInt32(bytes[offset + 2]) << 8 | UInt32(bytes[offset + 3])
    }

    func u16Array(at offset: Int, count n: Int) throws -> [UInt16] {
        try check(offset, 2 * n)
        return (0..<n).map { UInt16(bytes[offset + 2 * $0]) << 8 | UInt16(bytes[offset + 2 * $0 + 1]) }
    }

    func i16Array(at offset: Int, count n: Int) throws -> [Int16] {
        try u16Array(at: offset, count: n).map { Int16(bitPattern: $0) }
    }

    /// A Pascal string (length byte + Mac Roman bytes) at `offset`; bytes after the length are never read.
    func pascalString(at offset: Int) throws -> String {
        let length = Int(try u8(offset))
        try check(offset + 1, length)
        return MacRoman.decode(bytes[(offset + 1)..<(offset + 1 + length)])
    }
}

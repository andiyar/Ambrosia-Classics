import Foundation

/// The 0x20-byte level-map header (data-format §3.1, HIGH), loaded by `LoadLevelMap__Fs @ 10005cb8` into the
/// global at `PTR_DAT_100cdbd4`. Exits are **teleport indices** into 0xF00C, not level numbers
/// (`TeleportTo__8TGameSysFsss @ 10050e98`); when the hit edge's exit is 0, `MoveCommand` falls back to the
/// perpendicular edge's exit by half of the map (Phase 1's rule — stored here as read).
public struct MapHeader: Equatable, Sendable {
    public static let size = 0x20

    /// +0x00 i16 width W in tiles.
    public let width: Int16
    /// +0x02 i16 height H.
    public let height: Int16
    /// +0x04 i16 — no reader (0 in all 42 maps; open-items-2026-10-03 §4).
    public let unused4: Int16
    /// +0x06 i16 first chunk index used by a chunked map (§3.3).
    public let firstChunk: Int16
    /// +0x08 i16 number C of 0x80-byte chunk records following the header.
    public let chunkCount: Int16
    /// +0x0A u8 X wrap span (power of 2, 0 = no wrap; `SetStage` masks `x & (span-1)`).
    public let wrapX: UInt8
    /// +0x0B u8 Y wrap span.
    public let wrapY: UInt8
    /// +0x0C i16 exit across the north edge (`y == 0`), a teleport index.
    public let exitNorth: Int16
    /// +0x0E i16 exit east (`x ≥ W`).
    public let exitEast: Int16
    /// +0x10 i16 exit south (`y ≥ H`).
    public let exitSouth: Int16
    /// +0x12 i16 exit west (`x == 0`).
    public let exitWest: Int16
    /// The 0x20 bytes as stored (+0x14–0x1F reserved, zero in all 42 maps).
    public let raw: [UInt8]

    /// `LoadLevelMap` takes the chunked path when `hdr[6] < hdr[8]` (§3.3) — never by shipped data
    /// (`+6 == +8` in all 42 maps).
    public var isChunked: Bool { firstChunk < chunkCount }

    /// `bytes` must hold at least 0x20 bytes; only the first 0x20 are read.
    init(bytes: [UInt8]) {
        func i16(_ o: Int) -> Int16 { Int16(bitPattern: be16(bytes, o)) }
        width = i16(0); height = i16(2); unused4 = i16(4); firstChunk = i16(6); chunkCount = i16(8)
        wrapX = bytes[0x0A]; wrapY = bytes[0x0B]
        exitNorth = i16(0x0C); exitEast = i16(0x0E); exitSouth = i16(0x10); exitWest = i16(0x12)
        raw = Array(bytes[0..<Self.size])
    }
}

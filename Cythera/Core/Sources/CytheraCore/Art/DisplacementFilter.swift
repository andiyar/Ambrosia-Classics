import Foundation

/// A `FILT` resource — a displacement filter (shimmer / heat / water), data-format §3.4 [HIGH], read by
/// `LoadDisplacementFilters__Fv @ 100052a0`: byte 0 = frame hold count, byte 1 = running counter (bytes 0–3
/// are copied as one word; bytes 2–3 have no reader), bytes 4…0x23 = 256-bit colour mask, then N frames of
/// 0x400 signed offsets (to the end of the handle). `DisplacementFilterTile @ 100053e8`: a pixel whose colour
/// bit is set takes `in[i + offset[i]]`; `AdvanceDisplacementFilters @ 10005520` steps a frame when the counter
/// hits 0 and wraps at the end. Seven ship, `FILT 128…134` in `Cythera Data.rsrc` (p07). The length must be
/// exactly 0x24 + N × 0x400 with N ≥ 1 (the advance loop has no N = 0 case).
public struct DisplacementFilter: Equatable, Sendable {
    public let holdCount: UInt8
    public let counter: UInt8
    /// Bytes 2–3 as stored (no reader).
    public let unusedHeaderBytes: [UInt8]
    /// 32 bytes as stored; colour index i is bit (i & 7) of byte (i >> 3) — the reader's order.
    public let colorMask: [UInt8]
    /// N frames of 1,024 signed offsets, one per tile pixel.
    public let frames: [[Int8]]

    public init(data: Data) throws {
        let b = ArtBytes(data, type: "FILT")
        try b.require(0, 0x24, "header")
        let body = b.count - 0x24
        guard body > 0, body % 0x400 == 0 else {
            throw ArtRecordError.length("FILT", expected: 0x24 + max(1, (body + 0x3FF) / 0x400) * 0x400,
                                        actual: b.count)
        }
        holdCount = b.bytes[0]
        counter = b.bytes[1]
        unusedHeaderBytes = Array(b.bytes[2..<4])
        colorMask = Array(b.bytes[4..<0x24])
        frames = (0..<(body / 0x400)).map { f in
            b.bytes[(0x24 + f * 0x400)..<(0x24 + (f + 1) * 0x400)].map { Int8(bitPattern: $0) }
        }
    }

    /// True when colour index `index` is displaced by this filter.
    public func displaces(_ index: UInt8) -> Bool {
        colorMask[Int(index >> 3)] & (1 << (index & 7)) != 0
    }
}

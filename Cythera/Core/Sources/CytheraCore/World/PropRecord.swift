/// One 16-byte `PropItem` (data-format §4.2). Accessors decode exactly the reads the bank cites; the raw bytes
/// are kept for everything else.
public struct PropRecord: Equatable, Sendable {
    public static let size = 16
    /// The 16 bytes as stored.
    public let bytes: [UInt8]

    /// nil unless `bytes` is exactly 16 long.
    public init?(bytes: [UInt8]) {
        guard bytes.count == Self.size else { return nil }
        self.bytes = bytes
    }

    /// For callers that sliced exactly 16 bytes (`PropSegment`).
    init(record bytes: ArraySlice<UInt8>) { self.bytes = Array(bytes) }

    private var u24: UInt32 { UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3]) }
    private func u16(_ o: Int) -> UInt16 { be16(bytes, o) }

    /// Byte 0: kind (§4.3) — 0 on map, 0x08–0x0B in a container, 0x10 inventory, 0x18 equipped, 0x1C skill,
    /// 0x42 'B' marker, 0x44 'D' roof zone, bit 0x80 hidden, 0xFF free.
    public var kind: UInt8 { bytes[0] }
    /// On map: x = bits 12–23 of bytes 1..3, signed 12-bit (`SetStage`: `((u32>>8)<<16>>16)>>4`).
    public var x: Int { Int(Int16(bitPattern: UInt16(truncatingIfNeeded: u24 >> 8)) >> 4) }
    /// On map: y = bits 0–11, signed 12-bit (`(short)(u16@2 << 20) >> 20`).
    public var y: Int { Int(Int16(bitPattern: UInt16(truncatingIfNeeded: u24 << 4)) >> 4) }
    /// Contained: the parent index, the low 16 bits (`GetPropParent__FP8PropItem @ 10055d4c` returns `(short)u32`).
    public var parent: Int16 { Int16(bitPattern: u16(2)) }
    /// Bytes 4..5 bits 0–9: object type (`& 0x3ff`).
    public var type: Int { Int(u16(4) & 0x3FF) }
    /// Byte 4 bits 2–6: frame / state 0..31 (`(byte[4]>>2)&0x1f`; tile = base[type] + frame).
    public var frame: Int { Int(bytes[4] >> 2) & 0x1F }
    /// Byte 4 bit 7: mirror (swaps the 0x40/0x80 extension; `Render` transposes every tile — render.md §2.5).
    public var mirror: Bool { bytes[4] & 0x80 != 0 }
    /// Byte 6: quality / letter / timer / sub-position, type-flag dependent (§4.4).
    public var byte6: UInt8 { bytes[6] }
    /// Byte 7: u8 count (type flag 0x100) or a character's facing/activity copy.
    public var byte7: UInt8 { bytes[7] }
    /// Bytes 6..7 as a u16: the count when the type has flag 0x200 (`GetItemCount__FP8PropItem @ 1005577c`).
    public var count16: UInt16 { u16(6) }
    /// Bytes 8..9: index into the unique-object table (`AllocateFrame__8PropItemFv @ 10007c5c`).
    public var uniqueIndex: UInt16 { u16(8) }
    /// Bytes 0xA..0xB: script slot, field 0x0F (no script uses it; 0 in all 14,485 records — open-items §5).
    public var scriptSlot: UInt16 { u16(0xA) }
    /// Bytes 0xC..0xD: script heap reference (a THeapObj frame).
    public var heapRef: UInt16 { u16(0xC) }
    /// Byte 0xE bits 0–5: signed 6-bit sprite offset (script field 0x10), `sext6(byte E) << 2` px in `Render`.
    public var spriteOffset6: Int { Int(Int8(bitPattern: bytes[0xE] << 2) >> 2) }
}

/// One 0xF005 triple {u8 first index, u8 count, u8 third} (open-items-2026-10-06 §5): five contiguous ranges
/// 0xD0–0xEB then a 0 terminator. Data present, **no reader** (HIGH): `ColorCycle__FP8GrafPort @ 10008694` is a
/// bare `blr`. Role "colour-cycling table" is MED; the third byte (1 in all five) is unnamed.
public struct PaletteCycleRange: Equatable, Sendable {
    public let first: UInt8
    public let count: UInt8
    public let byte2: UInt8
    init(first: UInt8, count: UInt8, byte2: UInt8) { self.first = first; self.count = count; self.byte2 = byte2 }
}

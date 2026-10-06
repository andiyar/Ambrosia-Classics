/// One 16-byte sprite placement record at header `+4 + 16·index`, `index < 511` (world-data §3.4).
/// `flag` 1 = spawn (cleared to 0 when the sprite dies); `byte1` is read by nothing (0 in every active record);
/// `y`/`x` are the sprite's top-left in px; `p1..p4` are per-class parameters.
public struct Placement: Sendable, Equatable {
    public let index: Int
    public let flag: UInt8
    public let byte1: UInt8
    public let type: Int16
    public let p1: Int16
    public let p2: Int16
    public let p3: Int16
    public let p4: Int16
    public let y: Int16
    public let x: Int16

    public init(index: Int, flag: UInt8, byte1: UInt8, type: Int16, p1: Int16, p2: Int16, p3: Int16, p4: Int16,
                y: Int16, x: Int16) {
        self.index = index
        self.flag = flag
        self.byte1 = byte1
        self.type = type
        self.p1 = p1
        self.p2 = p2
        self.p3 = p3
        self.p4 = p4
        self.y = y
        self.x = x
    }

    init(_ b: BigEndianBytes, index: Int) throws {
        let o = 4 + 16 * index
        self.init(index: index, flag: try b.u8(o), byte1: try b.u8(o + 1), type: try b.i16(o + 2),
                  p1: try b.i16(o + 4), p2: try b.i16(o + 6), p3: try b.i16(o + 8), p4: try b.i16(o + 10),
                  y: try b.i16(o + 12), x: try b.i16(o + 14))
    }
}

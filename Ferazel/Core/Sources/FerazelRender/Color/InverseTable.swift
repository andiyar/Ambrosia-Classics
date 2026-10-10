import FerazelCore

/// An n-bit inverse table over a 256-entry CLUT: 2^(3n) cells, cell (r, g, b) coloured by each channel's n-bit
/// level **bit-replicated** to 16 bits (4 bits: 0x1111 steps), each cell mapped to the exact-nearest entry
/// (least squared Euclidean distance on the 16-bit channels, ties → `tieBreak`'s pick: lowest index by default,
/// highest under Ben's `.highest` — D26, 2026-10-07). A request is looked up by
/// the top n bits of each channel. This is the model under which lighting-tables §1.2's 39..153 / 66..157 and
/// §1.4's per-table level spread reproduce exactly (plan Research note 9; DECISIONS D26) [LOW as a model of
/// QuickDraw's `MakeITable`/`Color2Index`].
public struct InverseTable: Sendable {
    public let bits: Int
    public let tieBreak: ColorSearch.TieBreak
    /// Cell `((r·2^n) + g)·2^n + b` → index.
    public let cells: [UInt8]

    public init(clut: ColorLUT, bits: Int, tieBreak: ColorSearch.TieBreak = .lowest) {
        self.init(channels: ColorSearch.Channels(clut), bits: bits, tieBreak: tieBreak)
    }

    init(channels: ColorSearch.Channels, bits: Int, tieBreak: ColorSearch.TieBreak = .lowest) {
        precondition((1...6).contains(bits), "inverse table bits \(bits)")
        self.bits = bits
        self.tieBreak = tieBreak
        let n = 1 << bits
        let levels = (0..<n).map { Int(Self.cellColor($0, bits: bits)) }
        var out = [UInt8](repeating: 0, count: n * n * n)
        var cell = 0
        for r in levels {
            for g in levels {
                for b in levels {
                    out[cell] = channels.nearest(r, g, b, tieBreak: tieBreak)
                    cell += 1
                }
            }
        }
        cells = out
    }

    /// The 16-bit channel value of n-bit level `level`, the bits repeated down to bit 0 (5 bits: 1 → 0x0842).
    public static func cellColor(_ level: Int, bits: Int) -> UInt16 {
        var x = 0
        var shift = 16 - bits
        while shift > -bits {
            x |= shift >= 0 ? level << shift : level >> -shift
            shift -= bits
        }
        return UInt16(x & 0xffff)
    }

    /// The cell index of a request: the top `bits` of each channel.
    @inline(__always) public func cell(of rgb: RGB16) -> Int {
        let s = 16 - bits
        return ((Int(rgb.red) >> s) << (2 * bits)) | ((Int(rgb.green) >> s) << bits) | (Int(rgb.blue) >> s)
    }

    @inline(__always) public func index(of rgb: RGB16) -> UInt8 { cells[cell(of: rgb)] }
}

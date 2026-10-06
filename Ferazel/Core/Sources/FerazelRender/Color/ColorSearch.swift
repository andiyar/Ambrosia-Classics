import Foundation
import FerazelCore

/// The colour search every table builder and the face conversion run in place of QuickDraw's `Color2Index`
/// (lighting-tables §1.2: `MakeITable(c, nil, 0)` then `Color2Index` per request — the ROM's rule is not in the
/// binary, NOT RESOLVED 1). Design §6 / DECISIONS D26 rule the model: `.ruled` = an entry whose RGB equals the
/// request → the lowest such index, else the 4-bit inverse table. `.exactNearest` and `.inverseTable(bits:)` stay
/// selectable; every caller takes the model as a parameter (plan invariant 7). Every chosen index is [LOW].
///
/// Caches (per CLUT, built on first use): the exact-nearest result per distinct request, the exact-match map,
/// and the inverse tables per bit count. A CLUT is keyed by (id, seed) and confirmed by its entries — every
/// shipped `clut` stores seed 0, so the seed alone would not tell them apart.
public final class ColorSearch: @unchecked Sendable {

    public enum Model: Hashable, Sendable {
        /// Least squared Euclidean distance on the 16-bit channels over all 256 entries, ties → lowest index.
        case exactNearest
        /// Exact RGB match → lowest such index, else `.inverseTable(bits: 4)` (design §6, the app default).
        case ruled
        /// The n-bit bit-replicated inverse table (`InverseTable`).
        case inverseTable(bits: Int)
    }

    public let model: Model

    public init(model: Model = .ruled) {
        if case .inverseTable(let bits) = model { precondition((1...6).contains(bits), "inverse table bits \(bits)") }
        self.model = model
    }

    /// The index `Color2Index` is modelled to return for `rgb` with `clut` as the device's colour table.
    public func index(of rgb: RGB16, in clut: ColorLUT) -> UInt8 {
        lock.lock()
        defer { lock.unlock() }
        return palette(for: clut).index(of: rgb, model: model)
    }

    /// `index(of:in:)` for many requests against one CLUT (one cache lookup).
    public func indices(of requests: [RGB16], in clut: ColorLUT) -> [UInt8] {
        lock.lock()
        defer { lock.unlock() }
        let p = palette(for: clut)
        return requests.map { p.index(of: $0, model: model) }
    }

    // MARK: - caches

    private let lock = NSLock()
    private var palettes: [Key: [Palette]] = [:]

    private struct Key: Hashable {
        let id: Int16
        let seed: UInt32
    }

    private func palette(for clut: ColorLUT) -> Palette {
        let key = Key(id: clut.id, seed: clut.seed)
        if let found = palettes[key]?.first(where: { $0.entries == clut.entries }) { return found }
        let p = Palette(clut)
        palettes[key, default: []].append(p)
        return p
    }

    /// One CLUT's flattened channels and its search caches.
    final class Palette {
        let entries: [ColorLUT.Entry]
        private let red: [Int]
        private let green: [Int]
        private let blue: [Int]
        private var exact: [UInt64: UInt8] = [:]
        private let exactMatch: [UInt64: UInt8]
        private var inverse: [Int: InverseTable] = [:]

        init(_ clut: ColorLUT) {
            entries = clut.entries
            red = clut.entries.map { Int($0.red) }
            green = clut.entries.map { Int($0.green) }
            blue = clut.entries.map { Int($0.blue) }
            var match: [UInt64: UInt8] = [:]
            for (i, e) in clut.entries.enumerated() where match[Self.key(RGB16(e))] == nil {
                match[Self.key(RGB16(e))] = UInt8(i)   // first = lowest index
            }
            exactMatch = match
        }

        @inline(__always) static func key(_ c: RGB16) -> UInt64 {
            UInt64(c.red) << 32 | UInt64(c.green) << 16 | UInt64(c.blue)
        }

        /// Exact nearest by least squared distance, ties → lowest index (strict `<`).
        func nearest(_ r: Int, _ g: Int, _ b: Int) -> UInt8 {
            red.withUnsafeBufferPointer { pr in
                green.withUnsafeBufferPointer { pg in
                    blue.withUnsafeBufferPointer { pb in
                        var best = Int.max
                        var bi = 0
                        for i in 0..<pr.count {
                            let dr = pr[i] &- r, dg = pg[i] &- g, db = pb[i] &- b
                            let d = dr &* dr &+ dg &* dg &+ db &* db
                            if d < best { best = d; bi = i }
                        }
                        return UInt8(bi)
                    }
                }
            }
        }

        func exactNearest(_ c: RGB16) -> UInt8 {
            let k = Self.key(c)
            if let hit = exact[k] { return hit }
            let v = nearest(Int(c.red), Int(c.green), Int(c.blue))
            exact[k] = v
            return v
        }

        func inverseTable(bits: Int) -> InverseTable {
            if let t = inverse[bits] { return t }
            let t = InverseTable(palette: self, bits: bits)
            inverse[bits] = t
            return t
        }

        func index(of c: RGB16, model: Model) -> UInt8 {
            switch model {
            case .exactNearest:
                return exactNearest(c)
            case .inverseTable(let bits):
                return inverseTable(bits: bits).index(of: c)
            case .ruled:
                if let i = exactMatch[Self.key(c)] { return i }
                return inverseTable(bits: 4).index(of: c)
            }
        }
    }
}

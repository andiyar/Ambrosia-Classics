import Foundation
import FerazelCore

/// The colour search every table builder and the face conversion run in place of QuickDraw's `Color2Index`
/// (lighting-tables §1.2: `MakeITable(c, nil, 0)` then `Color2Index` per request — the ROM's rule is not in the
/// binary, NOT RESOLVED 1). Design §6 / DECISIONS D26 rule the model: `.ruled` = an entry whose RGB equals the
/// request → the lowest such index, else the 4-bit inverse table. `.exactNearest` and `.inverseTable(bits:)` stay
/// selectable; every caller takes the model as a parameter (plan invariant 7). Every chosen index is [LOW].
///
/// Per-pixel callers (the face conversion) take a `Prepared` searcher once per CLUT and call it without a lock;
/// `index(of:in:)` answers through the same `Prepared` (cached per CLUT, keyed by (id, seed) and confirmed by its
/// entries — every shipped `clut` stores seed 0, so the seed alone would not tell them apart). No per-request memo
/// outlives a call: exact-nearest is computed directly over flat channel arrays.
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
        prepared(for: clut).index(of: rgb)
    }

    /// `index(of:in:)` for many requests against one CLUT (one cache lookup). `.exactNearest` answers each distinct
    /// request once per call (a memo that lives only for the call).
    public func indices(of requests: [RGB16], in clut: ColorLUT) -> [UInt8] {
        let p = prepared(for: clut)
        guard case .exactNearest = model else { return requests.map(p.index(of:)) }
        var memo: [RGB16: UInt8] = [:]
        return requests.map { rq in
            if let hit = memo[rq] { return hit }
            let v = p.index(of: rq)
            memo[rq] = v
            return v
        }
    }

    /// This search's model prepared on `clut` (cached): the lock-free per-pixel fast path.
    public func prepared(for clut: ColorLUT) -> Prepared {
        lock.lock()
        defer { lock.unlock() }
        let key = Key(id: clut.id, seed: clut.seed)
        if let found = cache[key]?.first(where: { $0.entries == clut.entries }) { return found.prepared }
        let p = Prepared(clut: clut, model: model)
        cache[key, default: []].append((clut.entries, p))
        return p
    }

    // MARK: - cache

    private let lock = NSLock()
    private var cache: [Key: [(entries: [ColorLUT.Entry], prepared: Prepared)]] = [:]

    private struct Key: Hashable {
        let id: Int16
        let seed: UInt32
    }

    /// One model on one CLUT, everything precomputed: the flat channels (exact-nearest), the inverse table
    /// (`.inverseTable`, and 4 bits for `.ruled`), and for `.ruled` the palette entries bucketed by their own
    /// 4-bit cell in ascending index order, so an exact match is a scan of the request's cell (lowest index first).
    public struct Prepared: Sendable {
        public let model: Model
        let channels: Channels
        let table: InverseTable?
        /// `.ruled`: bucket `cell` is `bucketEntries[bucketStart[cell] ..< bucketStart[cell + 1]]`.
        private let bucketStart: [Int32]
        private let bucketEntries: [UInt8]
        private let packed: [UInt64]

        public init(clut: ColorLUT, model: Model) {
            self.model = model
            channels = Channels(clut)
            switch model {
            case .exactNearest:
                table = nil
            case .inverseTable(let bits):
                table = InverseTable(channels: channels, bits: bits)
            case .ruled:
                table = InverseTable(channels: channels, bits: 4)
            }
            guard case .ruled = model, let t = table else {
                bucketStart = []; bucketEntries = []; packed = []
                return
            }
            let colors = clut.entries.map(RGB16.init)
            packed = colors.map(Self.key)
            var counts = [Int32](repeating: 0, count: t.cells.count + 1)
            for c in colors { counts[t.cell(of: c) + 1] += 1 }
            for i in 1..<counts.count { counts[i] += counts[i - 1] }
            var fill = counts
            var entries = [UInt8](repeating: 0, count: colors.count)
            for (i, c) in colors.enumerated() {   // ascending i: each bucket lists its lowest index first
                let cell = t.cell(of: c)
                entries[Int(fill[cell])] = UInt8(i)
                fill[cell] += 1
            }
            bucketStart = counts
            bucketEntries = entries
        }

        @inline(__always) static func key(_ c: RGB16) -> UInt64 {
            UInt64(c.red) << 32 | UInt64(c.green) << 16 | UInt64(c.blue)
        }

        /// The index `Color2Index` is modelled to return for `rgb` on this CLUT.
        @inline(__always) public func index(of rgb: RGB16) -> UInt8 {
            switch model {
            case .exactNearest:
                return channels.nearest(Int(rgb.red), Int(rgb.green), Int(rgb.blue))
            case .inverseTable:
                return table.unsafelyUnwrapped.index(of: rgb)
            case .ruled:
                let t = table.unsafelyUnwrapped
                let cell = t.cell(of: rgb)
                let k = Self.key(rgb)
                var j = Int(bucketStart[cell])
                let end = Int(bucketStart[cell + 1])
                while j < end {
                    let i = bucketEntries[j]
                    if packed[Int(i)] == k { return i }
                    j += 1
                }
                return t.cells[cell]
            }
        }
    }

    /// A CLUT's channels as flat arrays.
    struct Channels: Sendable {
        let red: [Int]
        let green: [Int]
        let blue: [Int]

        init(_ clut: ColorLUT) {
            red = clut.entries.map { Int($0.red) }
            green = clut.entries.map { Int($0.green) }
            blue = clut.entries.map { Int($0.blue) }
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
    }
}

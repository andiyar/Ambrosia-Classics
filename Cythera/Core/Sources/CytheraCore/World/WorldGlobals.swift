import Foundation
import HectorResources

/// A malformed world global. Every read is bounds-checked; nothing traps; nothing is allocated before the
/// segment's length has been checked against the shape (Invariants 4, 5).
public enum WorldGlobalsError: Error, Equatable, Sendable {
    /// One of the 20 shipped globals is absent.
    case missing(UInt16)
    /// A global whose length differs from the one its shape implies (fixed size, or a count-derived size).
    case lengthMismatch(id: UInt16, expected: Int, actual: Int)
    /// A variable-length global whose length fits no whole number of its records.
    case badLength(id: UInt16, length: Int)
    /// A terminated list (0xF001, 0xF004, 0xF005) that runs off the end without its terminator.
    case missingTerminator(UInt16)
    /// Bytes after a terminator where the census shows none (0xF001, 0xF005).
    case trailingBytes(id: UInt16, after: Int, count: Int)
    /// A C string with no NUL before the end of the segment.
    case unterminatedString(id: UInt16, offset: Int)
    /// A 0xF001 record outside the census: tile not in 1..<0xA00, or nframes/divisor ≤ 0 (`LoadGlobals` divides).
    case badAnimationRecord(index: Int)
    /// A negative 0xF00B count.
    case negativeScheduleCount(character: Int, count: Int16)
    /// A 0xF00D tile above 0x2000 (the `TViewer` ctor asserts tile ≤ 0x2000).
    case wallTileOutOfRange(index: Int, tile: UInt16)
}

/// The world globals 0xF000–0xF016 (data-format §5, `LoadGlobals__Fv @ 10005798` / `NewModel`), every shipped
/// row as a typed member. 0xF003, 0xF006 and 0xF00E are absent from the scenario file (F00E exists only in
/// saves) and are not read here.
public struct WorldGlobals: Sendable {
    /// The 20 shipped ids, ascending (p03).
    public static let ids: [UInt16] = [
        0xF000, 0xF001, 0xF002, 0xF004, 0xF005, 0xF007, 0xF008, 0xF009, 0xF00A, 0xF00B,
        0xF00C, 0xF00D, 0xF00F, 0xF010, 0xF011, 0xF012, 0xF013, 0xF014, 0xF015, 0xF016,
    ]
    /// Fixed-size globals: `LoadSegment(…, 0, size)` lengths in `LoadGlobals` / §5 (F009: 0x4000 as shipped).
    static let fixedSizes: [UInt16: Int] = [
        0xF000: 0x800, 0xF002: 0x8000, 0xF009: 0x4000, 0xF00A: 0x400, 0xF00C: 0x1000, 0xF00F: 0x400,
        0xF010: 0x4000, 0xF011: 0x8000, 0xF012: 0x8000, 0xF013: 0x20000, 0xF016: 0x2000,
    ]

    /// 0xF000: u16 base tile per object type (0x400); tile = base[type] + frame.
    public let baseTiles: [UInt16]
    /// 0xF001: tile-animation records up to (not including) the zero-tile terminator (§3.4).
    public let animations: [AnimationRecord]
    /// Byte offset of 0xF001's zero i16 terminator (64 shipped; nothing follows it).
    public let animationTerminatorOffset: Int
    /// 0xF002: u32 tile flags per tile (0x2000). Bits 0–1 = light-emitter size class (`Lite` 128/130/132),
    /// 0x10000 = flicker (open-items-2026-10-03 §10); render bits per data-format §5.
    public let tileFlags: [UInt32]
    /// 0xF004: tile names.
    public let tileNames: TileNameTable
    /// 0xF005: palette ranges (no reader).
    public let paletteCycles: [PaletteCycleRange]
    /// 0xF007 as stored: u16 count 33 + 33 × 5-byte records (no reader; role LOW — open-items-2026-10-06 §5).
    public let f007: Data
    /// 0xF008: the 128 creature-species records of the first 0x800 bytes (unused ones zero).
    public let creatures: [CreatureRecord]
    /// 0xF008 past +0x800: the `(size − 0x800) >> 4` tail list (`PTR_DAT_100cdc30`; empty in 1.0.4).
    public let creatureTail: [CreatureRecord]
    /// 0xF009: the runtime CharEntry table, 512 entries. `LoadGlobals` loads the segment and zeroes the upper
    /// 0x2000 bytes (`FUN_100b46a0(base + 0x2000, 0, 0x2000)`), so entries 256..511 are zero here (§6.1).
    public let characters: [CharEntry]
    /// 0xF00B: schedules.
    public let schedules: ScheduleTable
    /// 0xF00C: 1024 × u32 packed teleport locations (`WorldLocation(packed:)`).
    public let teleports: [UInt32]
    /// 0xF00D: wall-face substitution records.
    public let wallSubstitutions: [WallRecord]
    /// 0xF00F: arrival screen transition per teleport index (0x400).
    public let arrivalTransitions: [UInt8]
    /// 0xF010: u16 per tile; non-zero spawns a kind-0x40 pseudo-prop (MED).
    public let tilePseudoProps: [UInt16]
    /// 0xF011 / 0xF012: per (type, frame) sprite x / y pixel offsets, `[type*0x20 + frame]`.
    public let spriteOffsetsX: [Int16]
    public let spriteOffsetsY: [Int16]
    /// 0xF013: CompoTileRecord[4096].
    public let compoTiles: [CompoTileRecord]
    /// 0xF016: displacement-filter id per tile (`FILT` resource id; 0 = none).
    public let filterIDs: [UInt8]
    /// 0xF00A as stored (1024 bytes, all zero; no reader).
    public let f00A: Data
    /// 0xF014: frame-variable symbol table.
    public let frameVariableNames: SymbolTable
    /// 0xF015: object-name symbol table.
    public let objectNames: SymbolTable

    public init(file: SegmentFile) throws {
        try self.init(store: file)
    }

    /// Reads the 20 globals from any segment store (a segment file, or an overlay slot in a test).
    public init(store: some SegmentStore) throws {
        var seg: [UInt16: [UInt8]] = [:]
        for id in Self.ids {
            guard let d = store.segment(id), !d.isEmpty else { throw WorldGlobalsError.missing(id) }
            let b = [UInt8](d)
            if let size = Self.fixedSizes[id], b.count != size {
                throw WorldGlobalsError.lengthMismatch(id: id, expected: size, actual: b.count)
            }
            seg[id] = b
        }
        func u16s(_ id: UInt16) -> [UInt16] { let b = seg[id]!; return (0..<(b.count / 2)).map { be16(b, $0 * 2) } }
        func i16s(_ id: UInt16) -> [Int16] { u16s(id).map { Int16(bitPattern: $0) } }

        baseTiles = u16s(0xF000)
        let f002 = seg[0xF002]!
        tileFlags = (0..<(f002.count / 4)).map { be32(f002, $0 * 4) }
        tilePseudoProps = u16s(0xF010)
        spriteOffsetsX = i16s(0xF011)
        spriteOffsetsY = i16s(0xF012)
        filterIDs = seg[0xF016]!
        arrivalTransitions = seg[0xF00F]!
        f00A = Data(seg[0xF00A]!)
        let f00C = seg[0xF00C]!
        teleports = (0..<(f00C.count / 4)).map { be32(f00C, $0 * 4) }
        let f013 = seg[0xF013]!
        compoTiles = (0..<(f013.count / CompoTileRecord.size)).map { r in
            CompoTileRecord(entries: (0..<16).map { be16(f013, r * CompoTileRecord.size + $0 * 2) })
        }
        let f009 = seg[0xF009]!
        characters = (0..<512).map { k in
            k < 256 ? CharEntry(bytes: Array(f009[(k * 0x20)..<(k * 0x20 + 0x20)]))
                    : CharEntry(bytes: [UInt8](repeating: 0, count: CharEntry.size))
        }

        (animations, animationTerminatorOffset) = try Self.parseAnimations(seg[0xF001]!)
        tileNames = try Self.parseTileNames(seg[0xF004]!)
        paletteCycles = try Self.parsePaletteCycles(seg[0xF005]!)

        let f007 = seg[0xF007]!
        guard f007.count >= 2 else { throw WorldGlobalsError.badLength(id: 0xF007, length: f007.count) }
        let f007Expected = 2 + Int(be16(f007, 0)) * 5
        guard f007.count == f007Expected else {
            throw WorldGlobalsError.lengthMismatch(id: 0xF007, expected: f007Expected, actual: f007.count)
        }
        self.f007 = Data(f007)

        let f008 = seg[0xF008]!
        guard f008.count >= 0x800, (f008.count - 0x800) % CreatureRecord.size == 0 else {
            throw WorldGlobalsError.badLength(id: 0xF008, length: f008.count)
        }
        let creatureRecords = (0..<(f008.count / CreatureRecord.size)).map {
            CreatureRecord(bytes: Array(f008[($0 * 16)..<($0 * 16 + 16)]))
        }
        creatures = Array(creatureRecords[0..<128])
        creatureTail = Array(creatureRecords[128...])

        schedules = try Self.parseSchedules(seg[0xF00B]!)

        let f00D = seg[0xF00D]!
        guard f00D.count % WallRecord.size == 0 else { throw WorldGlobalsError.badLength(id: 0xF00D, length: f00D.count) }
        wallSubstitutions = try (0..<(f00D.count / WallRecord.size)).map { k in
            let o = k * WallRecord.size
            let tile = be16(f00D, o)
            guard tile <= 0x2000 else { throw WorldGlobalsError.wallTileOutOfRange(index: k, tile: tile) }
            return WallRecord(tile: tile, alternates: (1...4).map { be16(f00D, o + $0 * 2) })
        }

        frameVariableNames = try Self.parseSymbols(seg[0xF014]!, id: 0xF014)
        objectNames = try Self.parseSymbols(seg[0xF015]!, id: 0xF015)
    }

    /// 0xF001 (§3.4; note 7 as ruled 2026-10-07): 8-byte records until a zero i16 tile, then nothing. The
    /// original stops at the zero and ignores what follows; the census shows nothing after it, so trailing
    /// bytes are refused (Invariant 4).
    static func parseAnimations(_ b: [UInt8]) throws -> ([AnimationRecord], Int) {
        var out: [AnimationRecord] = []
        var k = 0
        while true {
            guard k + 2 <= b.count else { throw WorldGlobalsError.missingTerminator(0xF001) }
            let tile = Int16(bitPattern: be16(b, k))
            if tile == 0 { break }
            guard k + 8 <= b.count else { throw WorldGlobalsError.missingTerminator(0xF001) }
            let r = AnimationRecord(tile: tile, base: Int16(bitPattern: be16(b, k + 2)),
                                    frameCount: Int16(bitPattern: be16(b, k + 4)),
                                    divisor: Int16(bitPattern: be16(b, k + 6)))
            guard (1..<0xA00).contains(r.tile), r.frameCount > 0, r.divisor > 0 else {
                throw WorldGlobalsError.badAnimationRecord(index: out.count)
            }
            out.append(r)
            k += 8
        }
        guard k + 2 == b.count else {
            throw WorldGlobalsError.trailingBytes(id: 0xF001, after: k + 2, count: b.count - (k + 2))
        }
        return (out, k)
    }

    /// 0xF004 (§5): {u16 last tile, C string}… until an id > 0x2000; the bytes after it are kept, unread.
    static func parseTileNames(_ b: [UInt8]) throws -> TileNameTable {
        var entries: [TileNameTable.Entry] = []
        var k = 0
        while true {
            guard k + 2 <= b.count else { throw WorldGlobalsError.missingTerminator(0xF004) }
            let t = be16(b, k)
            if t > 0x2000 {
                return TileNameTable(entries: entries, terminator: t, terminatorOffset: k,
                                     trailing: Array(b[(k + 2)...]))
            }
            let (name, next) = try cString(b, at: k + 2, id: 0xF004)
            entries.append(.init(lastTile: t, name: name))
            k = next
        }
    }

    /// 0xF005 (open-items-2026-10-06 §5): {first, count, third} triples until a zero first byte, then nothing.
    static func parsePaletteCycles(_ b: [UInt8]) throws -> [PaletteCycleRange] {
        var out: [PaletteCycleRange] = []
        var k = 0
        while true {
            guard k < b.count else { throw WorldGlobalsError.missingTerminator(0xF005) }
            if b[k] == 0 { break }
            guard k + 3 <= b.count else { throw WorldGlobalsError.missingTerminator(0xF005) }
            out.append(PaletteCycleRange(first: b[k], count: b[k + 1], byte2: b[k + 2]))
            k += 3
        }
        guard k + 1 == b.count else {
            throw WorldGlobalsError.trailingBytes(id: 0xF005, after: k + 1, count: b.count - (k + 1))
        }
        return out
    }

    /// 0xF00B (§6.3): 256 i16 counts, then each character's entries; the length must be exactly
    /// `0x200 + 8·Σcount` (checked before any entry is built).
    static func parseSchedules(_ b: [UInt8]) throws -> ScheduleTable {
        guard b.count >= 0x200 else { throw WorldGlobalsError.badLength(id: 0xF00B, length: b.count) }
        let counts = (0..<256).map { Int16(bitPattern: be16(b, $0 * 2)) }
        var total = 0
        for (c, n) in counts.enumerated() {
            guard n >= 0 else { throw WorldGlobalsError.negativeScheduleCount(character: c, count: n) }
            total += Int(n)
        }
        let expected = 0x200 + ScheduleEntry.size * total
        guard b.count == expected else {
            throw WorldGlobalsError.lengthMismatch(id: 0xF00B, expected: expected, actual: b.count)
        }
        var o = 0x200
        let entries: [[ScheduleEntry]] = counts.map { n in
            (0..<Int(n)).map { _ in
                defer { o += ScheduleEntry.size }
                return ScheduleEntry(hour: b[o], activity: b[o + 1], conditionOp: b[o + 2], conditionArg: b[o + 3],
                                     packedLocation: be32(b, o + 4))
            }
        }
        return ScheduleTable(counts: counts, entries: entries)
    }

    /// 0xF014 / 0xF015: {u16, C string}… consuming the whole segment.
    static func parseSymbols(_ b: [UInt8], id: UInt16) throws -> SymbolTable {
        var entries: [SymbolTable.Entry] = []
        var k = 0
        while k < b.count {
            guard k + 2 <= b.count else { throw WorldGlobalsError.badLength(id: id, length: b.count) }
            let (name, next) = try cString(b, at: k + 2, id: id)
            entries.append(.init(value: be16(b, k), name: name))
            k = next
        }
        return SymbolTable(entries: entries, byteCount: k)
    }

    /// A NUL-terminated MacRoman string at `offset`; returns it and the offset after the NUL.
    static func cString(_ b: [UInt8], at offset: Int, id: UInt16) throws -> (String, Int) {
        var e = offset
        while e < b.count, b[e] != 0 { e += 1 }
        guard e < b.count else { throw WorldGlobalsError.unterminatedString(id: id, offset: offset) }
        return (MacRoman.decode(b[offset..<e]), e + 1)
    }
}

/// Big-endian reads; callers have bounds-checked `o`.
@inline(__always) func be16(_ b: [UInt8], _ o: Int) -> UInt16 { UInt16(b[o]) << 8 | UInt16(b[o + 1]) }
@inline(__always) func be32(_ b: [UInt8], _ o: Int) -> UInt32 {
    UInt32(b[o]) << 24 | UInt32(b[o + 1]) << 16 | UInt32(b[o + 2]) << 8 | UInt32(b[o + 3])
}

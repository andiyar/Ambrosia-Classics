import Foundation

/// A malformed segment file. Every read is bounds-checked against the file; nothing traps (Invariant 5).
public enum SegmentFileError: Error, Equatable, Sendable {
    /// Fewer bytes than the header + root page need.
    case truncated(need: Int, have: Int)
    /// The u32 at 0x80 is not 0x80 (`IsSegFile`, data-format §1.1).
    case notSegmentFile
    /// The header's Pascal title is longer than its Str31 field.
    case titleTooLong(Int)
    /// A root entry whose TOC page is not 0x800 bytes (every page in the census is; `SaveTOC` writes 0x800).
    case pageLength(page: UInt8, length: Int)
    /// A root entry whose TOC page lies (partly) outside the file.
    case pageOutOfBounds(page: UInt8, offset: Int, length: Int)
    /// A TOC entry whose segment body lies (partly) outside the file.
    case entryOutOfBounds(id: UInt16, offset: Int, length: Int)
}

/// One {u32 offset, u32 length} TOC slot. Length 0 = absent (data-format §1.1).
public struct TOCEntry: Equatable, Sendable {
    public let offset: Int
    public let length: Int
    public init(offset: Int, length: Int) { self.offset = offset; self.length = length }
}

/// TOC page *n*: where it is stored (root entry *n*) and its 256 slots for ids 0xnn00..0xnnFF.
public struct TOCPage: Equatable, Sendable {
    public let offset: Int
    public let length: Int
    public let entries: [TOCEntry]
}

/// A source of segments by id: a segment file, or an in-memory store (the `TCachedSegFiles` slots, §1.4).
public protocol SegmentStore {
    /// {offset, length} of segment `id`; nil when absent (length 0).
    func entry(_ id: UInt16) -> (offset: Int, length: Int)?
    /// The stored bytes of segment `id`, zero-based; nil when absent.
    func segment(_ id: UInt16) -> Data?
}

/// The segment file `TSegFile` (data-format §1.1–§1.3): a 0x80-byte header, the root TOC page at 0x80
/// (256 × {u32 offset, u32 length}; root[0] is the root page itself, root[n] is TOC page n for ids
/// 0xnn00..0xnnFF), and segment bodies anywhere in the file. Read memory-mapped; every TOC page and every
/// present entry is bounds-checked at open, so lookups afterwards cannot leave the file.
public struct SegmentFile: SegmentStore {
    /// Script-band segments stored PLAINTEXT in the shipped file (script-census §2, HIGH mechanical):
    /// `GetEncryptedSegment` would decrypt them to garbage, and no code references either.
    /// `scriptSegment` returns them as stored (Invariant 3).
    public static let storedPlaintext: Set<UInt16> = [0x0101, 0x0210]
    static let rootOffset = 0x80
    static let pageSize = 0x800

    public let header: SegmentFileHeader
    /// The root page's 256 entries (root[0] = {0x80, 0x800}).
    public let root: [TOCEntry]
    /// The present TOC pages (root entries 1..255 with non-zero length), by page number.
    public let pages: [UInt8: TOCPage]
    /// Every present segment id, sorted.
    public let ids: [UInt16]
    /// The file's size in bytes.
    public var byteCount: Int { data.count }

    private let data: Data

    /// Opens the file memory-mapped.
    public init(contentsOf url: URL) throws {
        try self.init(data: Data(contentsOf: url, options: .alwaysMapped))
    }

    /// Parses `data` (any start index) as a segment file; throws `SegmentFileError` on any malformed shape.
    public init(data input: Data) throws {
        let data = input.startIndex == 0 ? input : Data(input)
        let need = Self.rootOffset + Self.pageSize
        guard data.count >= need else { throw SegmentFileError.truncated(need: need, have: data.count) }
        guard Self.isSegmentFile(data) else { throw SegmentFileError.notSegmentFile }
        header = try SegmentFileHeader(raw: data)
        let rootEntries = Self.readEntries(data, at: Self.rootOffset)

        var pages: [UInt8: TOCPage] = [:]
        var ids: [UInt16] = []
        for n in 1...255 where rootEntries[n].length != 0 {
            let r = rootEntries[n]
            let page = UInt8(n)
            guard r.length == Self.pageSize else { throw SegmentFileError.pageLength(page: page, length: r.length) }
            guard r.offset <= data.count - r.length else {
                throw SegmentFileError.pageOutOfBounds(page: page, offset: r.offset, length: r.length)
            }
            let entries = Self.readEntries(data, at: r.offset)
            for (slot, e) in entries.enumerated() where e.length != 0 {
                let id = UInt16(n) << 8 | UInt16(slot)
                guard e.offset <= data.count, e.length <= data.count - e.offset else {
                    throw SegmentFileError.entryOutOfBounds(id: id, offset: e.offset, length: e.length)
                }
                ids.append(id)
            }
            pages[page] = TOCPage(offset: r.offset, length: r.length, entries: entries)
        }
        self.data = data
        self.root = rootEntries
        self.pages = pages
        self.ids = ids                       // pages ascend, slots ascend: already sorted
    }

    /// True iff the u32 at 0x80 is 0x80 (`IsSegFile__8TSegFileFs @ 100795dc`).
    public static func isSegmentFile(_ data: Data) -> Bool {
        guard data.count >= rootOffset + 8 else { return false }
        let b = data.startIndex + rootOffset
        return data[b] == 0 && data[b + 1] == 0 && data[b + 2] == 0 && data[b + 3] == 0x80
    }

    public func entry(_ id: UInt16) -> (offset: Int, length: Int)? {
        guard let page = pages[UInt8(id >> 8)] else { return nil }
        let e = page.entries[Int(id & 0xFF)]
        return e.length == 0 ? nil : (e.offset, e.length)
    }

    /// The bytes as stored (encrypted for script segments), zero-based; nil when absent.
    public func segment(_ id: UInt16) -> Data? {
        guard let e = entry(id) else { return nil }
        return data.subdata(in: e.offset..<(e.offset + e.length))
    }

    /// The segment as the interpreter sees it (`GetEncryptedSegment @ 1007d148`, data-format §1.3):
    /// decrypted with `SegmentCipher`, except the two stored-plaintext ids returned as stored.
    public func scriptSegment(_ id: UInt16) -> Data? {
        guard let raw = segment(id) else { return nil }
        if Self.storedPlaintext.contains(id) { return raw }
        var bytes = [UInt8](raw)
        SegmentCipher.apply(&bytes, id: id)
        return Data(bytes)
    }

    /// 256 big-endian {u32, u32} at `offset`; the caller has checked `offset + 0x800 ≤ data.count`.
    private static func readEntries(_ data: Data, at offset: Int) -> [TOCEntry] {
        data.withUnsafeBytes { buf in
            func u32(_ o: Int) -> Int {
                Int(buf[o]) << 24 | Int(buf[o + 1]) << 16 | Int(buf[o + 2]) << 8 | Int(buf[o + 3])
            }
            return (0..<256).map { TOCEntry(offset: u32(offset + $0 * 8), length: u32(offset + $0 * 8 + 4)) }
        }
    }
}

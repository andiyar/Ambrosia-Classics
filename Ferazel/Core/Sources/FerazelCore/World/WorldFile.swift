import Foundation
import HectorResources

/// `Mwld 0` — the world record (world-data §2.1; 70,664 B; resource name "Mascot World"). Only `stamp` and
/// `startLevel` have readers; the rest is decoded for completeness, labelled as the bank labels it.
public struct WorldFile: Sendable, Equatable {
    /// The smallest body holding every field below.
    public static let minimumLength = 0x1c8

    /// 0x000 pstr — "Teraknorn" in the shipped file (stale bytes after the length are not read); no reader found.
    public let name: String
    /// 0x100 — world identity stamp, copied into saves and compared on resume.
    public let stamp: UInt32
    /// 0x144 — no reader found.
    public let field144: Int16
    /// 0x1c4 — New Game start level (read only with the debug flag or a non-default world; §4.1).
    public let startLevel: Int16
    /// 0x1c6 — no reader found.
    public let field1c6: Int16

    public init(id: Int16 = 0, data: Data) throws {
        let b = BigEndianBytes(data, type: "Mwld", id: id)
        guard b.count >= Self.minimumLength else {
            throw WorldDataError.wrongLength(type: "Mwld", id: id, expected: Self.minimumLength, actual: b.count)
        }
        name = try b.pascalString(at: 0x000)
        stamp = try b.u32(0x100)
        field144 = try b.i16(0x144)
        startLevel = try b.i16(0x1c4)
        field1c6 = try b.i16(0x1c6)
    }

    /// `Mwld 0` from World Data (`.OpenDefaultWorld`).
    public static func load(from resources: FerazelResources) throws -> WorldFile {
        guard let r = resources.world.resource(type: "Mwld", id: 0) else {
            throw WorldDataError.missing(type: "Mwld", id: 0)
        }
        return try WorldFile(id: r.id, data: r.data)
    }
}

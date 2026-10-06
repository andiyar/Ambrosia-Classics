import Foundation
import HectorResources

/// An `Mcnv` resource — one conversation (conversations-mcnv §2.2; world-data §5): a 0x100-byte header pstr
/// (the conversation's name; unread by the game) and 20 line records of 0x72a bytes, line `i` at
/// `0x100 + i·0x72a` (36,936 B). A resource of any other length is refused. Offsets below are record-relative
/// (the code's offsets are these + 0x100, `Mcnv + i·0x72a` framing). Pascal strings are Mac Roman; bytes after
/// a length are stale editor residue and never read.
public struct Conversation: Sendable, Equatable {
    public static let headerSize = 0x100
    public static let lineCount = 20
    public static let lineSize = 0x72a
    public static let length = headerSize + lineCount * lineSize

    /// An action slot: type, A, B (conversations-mcnv §3.4).
    public struct Action: Sendable, Equatable {
        public let type: Int16
        public let a: Int16
        public let b: Int16
    }

    /// One line record.
    public struct Line: Sendable, Equatable {
        /// +0x000 pstr — the spoken text.
        public let text: String
        /// +0x100 pstr — the speaker's name.
        public let speaker: String
        /// +0x200 + 0x100·k pstr × 5 — response texts.
        public let responses: [String]
        /// +0x700 + 2·k i16 × 5 — response targets (0 = no response k; slot 0 = 0 ⇒ no menu).
        public let responseTargets: [Int16]
        /// +0x70a — portrait PICT id (0 = never displayed: a logic node).
        public let portrait: Int16
        /// +0x70c / +0x70e / +0x710 / +0x712 — condition type, args A / B, target when true.
        public let conditionType: Int16
        public let conditionA: Int16
        public let conditionB: Int16
        public let conditionTarget: Int16
        /// +0x71c / +0x722 — the two actions. (+0x714..+0x71b is unread.)
        public let action1: Action
        public let action2: Action
        /// +0x728 — next target (0 = sequential).
        public let next: Int16
    }

    public let id: Int16
    /// Header pstr (e.g. "Rojinko Conv").
    public let name: String
    /// The 20 line records, index 0..19 (index 19 is the entry/logic node).
    public let lines: [Line]

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "Mcnv", id: id)
        guard b.count == Self.length else {
            throw WorldDataError.wrongLength(type: "Mcnv", id: id, expected: Self.length, actual: b.count)
        }
        self.id = id
        name = try b.pascalString(at: 0)
        var lines: [Line] = []
        for i in 0..<Self.lineCount {
            let o = Self.headerSize + i * Self.lineSize
            lines.append(Line(
                text: try b.pascalString(at: o),
                speaker: try b.pascalString(at: o + 0x100),
                responses: try (0..<5).map { try b.pascalString(at: o + 0x200 + 0x100 * $0) },
                responseTargets: try b.i16Array(at: o + 0x700, count: 5),
                portrait: try b.i16(o + 0x70a),
                conditionType: try b.i16(o + 0x70c),
                conditionA: try b.i16(o + 0x70e),
                conditionB: try b.i16(o + 0x710),
                conditionTarget: try b.i16(o + 0x712),
                action1: Action(type: try b.i16(o + 0x71c), a: try b.i16(o + 0x71e), b: try b.i16(o + 0x720)),
                action2: Action(type: try b.i16(o + 0x722), a: try b.i16(o + 0x724), b: try b.i16(o + 0x726)),
                next: try b.i16(o + 0x728)))
        }
        self.lines = lines
    }

    /// `Mcnv <id>` from World Data (`.OpenDefaultWorldConv`).
    public static func load(from resources: FerazelResources, id: Int16) throws -> Conversation {
        guard let r = resources.world.resource(type: "Mcnv", id: id) else {
            throw WorldDataError.missing(type: "Mcnv", id: id)
        }
        return try Conversation(id: r.id, data: r.data)
    }
}

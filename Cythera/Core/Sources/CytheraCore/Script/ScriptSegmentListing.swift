import Foundation

/// What a script-band segment holds, measured on its bytes the way `docs/cythera/tools/scriptdis.py`
/// (`Store._probe`) measures it (script-census.md §1).
public enum ScriptSegmentKind: String, Equatable, Hashable, Sendable {
    /// Page 0x10–0x1F: a u16 dictionary offset whose target is a 0xA0–0xAF dictionary that fits.
    case `class`
    /// Starts with the frame op 0x81.
    case routine
    /// A 0x90–0x9F array whose non-Nil entries point (low 16 bits) at C strings after the table.
    case strtab
    /// A bare 0xA0–0xAF dictionary.
    case dict
    /// A bare 0x90–0x9F array that fits.
    case array
    /// None of these: words read by 0x49 and written by 0x85.
    case data
    /// Page 0x04: a compiled combat-AI script (ai-scripts.md §3), stored plain, not VM bytecode.
    case ai
}

/// A class-dictionary value that `scriptdis.py` books as a method: a code pointer (tag −1) whose target byte is
/// 0x80–0x8F, in this segment or in another class/routine segment (a shared method). The tool's first-byte
/// heuristic — the engine runs whatever value a sent selector finds as code (script-census.md §5).
public struct ScriptMethod: Equatable, Hashable, Sendable {
    public let selector: UInt16
    /// The segment holding the code: the listing's own id, or another segment for a shared method.
    public let segment: UInt16
    public let offset: Int

    public init(selector: UInt16, segment: UInt16, offset: Int) {
        self.selector = selector
        self.segment = segment
        self.offset = offset
    }
}

/// One script-band segment as `scriptdis.py` lists it (plan S2): its kind, its TOC length and one
/// `ScriptInstruction` per listing line that starts with an offset — statements (flagged reached, jump target or
/// dead), literal blocks (`.hdr`, `.dict`, `.array`, `.string`, `.strtab`, `.word`, `.odd`), undecoded bytes
/// (`.bytes`), data lines (`.data`) and the combat-AI `name` / `entry` lines — in listing order.
public struct ScriptSegmentListing: Equatable, Sendable {
    public let id: UInt16
    public let kind: ScriptSegmentKind
    /// The TOC length in bytes.
    public let length: Int
    public let instructions: [ScriptInstruction]
    /// `.class` only: the dictionary offset in the u16 at 0.
    public let dictionaryOffset: Int?
    /// `.class` only, in dictionary slot order: same-segment and shared methods.
    public let methods: [ScriptMethod]
    /// `.class` only: the selectors whose values are not methods, sorted.
    public let properties: [UInt16]
    /// Runs of consecutive dead statements (the listing header's "dead-code runs").
    public let deadCodeRuns: Int
    /// `.ai` only: the decoded header and entries.
    public let combatAI: CombatAISegment?
    /// The structural shapes `scriptdis.py` lists with an "ANOMALY" note, in the order the walk meets them;
    /// none in the shipped data (every listing header says "anomalies: 0").
    public let anomalies: [ScriptAnomaly]

    public init(id: UInt16, kind: ScriptSegmentKind, length: Int, instructions: [ScriptInstruction],
                dictionaryOffset: Int? = nil, methods: [ScriptMethod] = [], properties: [UInt16] = [],
                deadCodeRuns: Int = 0, combatAI: CombatAISegment? = nil, anomalies: [ScriptAnomaly] = []) {
        self.id = id
        self.kind = kind
        self.length = length
        self.instructions = instructions
        self.dictionaryOffset = dictionaryOffset
        self.methods = methods
        self.properties = properties
        self.deadCodeRuns = deadCodeRuns
        self.combatAI = combatAI
        self.anomalies = anomalies
    }
}

/// A shape the walk lists the way `scriptdis.py` does but the tool flags as an anomaly (`Dis.anoms`). The
/// structural categories only: the tool's expression-stack notes (no value, extra values, underflow, a send with
/// no receiver), the 0x82 slot ≥ 0x40 and 0x90 terminator notes and its string-reference notes are not modelled.
public struct ScriptAnomaly: Equatable, Hashable, Sendable {
    public enum Kind: Equatable, Hashable, Sendable {
        /// A same-segment code pointer past the end; `offset` = its target (not followed).
        case pointerPastEnd
        /// A jump target past the end; `offset` = the target (not followed).
        case jumpPastEnd
        /// The walk reached the middle of a non-text statement; `offset` = where (the path stops).
        case midInstruction
        /// The walk reached a literal block other than a word; `offset` = where (the path stops).
        case intoLiteral
        /// A statement covers a byte another (non-text pair) statement owns; `offset` = that byte, one per byte.
        case overlappingDecode
        /// An array or dictionary header claims more entries than fit; `offset` = the block (clamped).
        case arrayPastEnd, dictPastEnd
        /// A literal block whose header byte is none of string/array/dictionary; `offset` = the block.
        case oddLiteral
        /// A 0x45 block whose literal parses past its length; `offset` = the block's first byte.
        case inlineBlockOverrun
        /// A 0x47/0x83 segment word past the end; `offset` = the word offset.
        case wordPastEnd
    }

    public let kind: Kind
    public let offset: Int

    public init(_ kind: Kind, at offset: Int) {
        self.kind = kind
        self.offset = offset
    }
}

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

    public init(id: UInt16, kind: ScriptSegmentKind, length: Int, instructions: [ScriptInstruction],
                dictionaryOffset: Int? = nil, methods: [ScriptMethod] = [], properties: [UInt16] = [],
                deadCodeRuns: Int = 0, combatAI: CombatAISegment? = nil) {
        self.id = id
        self.kind = kind
        self.length = length
        self.instructions = instructions
        self.dictionaryOffset = dictionaryOffset
        self.methods = methods
        self.properties = properties
        self.deadCodeRuns = deadCodeRuns
        self.combatAI = combatAI
    }
}

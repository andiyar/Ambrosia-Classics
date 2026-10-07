/// 0xF014 / 0xF015: {u16 value, C string}… filling the whole segment — compiler symbol tables of frame-variable
/// names (F014) and small object ids (F015) (data-format §5; open-items-2026-10-03 §6). No PPC reader (HIGH);
/// role MED/LOW.
public struct SymbolTable: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public let value: UInt16
        public let name: String
    }
    public let entries: [Entry]
    /// Bytes consumed (= the segment length; a remainder is refused).
    public let byteCount: Int
    init(entries: [Entry], byteCount: Int) { self.entries = entries; self.byteCount = byteCount }
}

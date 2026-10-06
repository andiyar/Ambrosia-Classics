import Foundation

/// The text-resource obfuscation (`FUN_10046470`; bank pak-format.md §3): every byte becomes
/// `~rotl8(b, 4)` (swap nibbles, invert). It is an involution — the same call encodes and decodes.
/// All 473 shipped text entries are encoded. Loaders decode unconditionally, except `unde` (only if
/// `#name_STR` is absent) and `wede` (only if `#type_ID` is absent) — those decisions are the callers'.
public enum DeimosText {
    public static func decode(_ bytes: [UInt8]) -> [UInt8] {
        bytes.map { ~($0 >> 4 | $0 << 4) }
    }
}

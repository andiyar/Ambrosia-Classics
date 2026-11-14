import Foundation
import HectorResources

/// A compiled combat-AI segment the census has not shown (plan Invariant 3).
public enum CombatAIError: Error, Equatable, Sendable {
    /// Shorter than the 0x20-byte header.
    case truncated(length: Int)
    /// The bytes after the header are not a whole number of 8-byte entries (every shipped one is).
    case raggedEntries(length: Int)
    /// A name length byte past 0x17 (ai-scripts.md §3.1: the name occupies 1..0x17).
    case nameTooLong(Int)
}

/// One compiled combat-AI script (page 0x04, ids 0x0410–0x0436; ai-scripts.md §3): `CompileAIFile` writes a
/// 0x20-byte header (`SCombatAIHeader`: name length, name, zero) and 8-byte entries (`SCombatAIEntry`).
/// `PerformAI` reads it with plain `GetSegment`, so it is stored plain (`SegmentFile.storedPlaintextBand`).
/// Listed as `scriptdis.py` `ai_listing` does: a `name` line at 0 and one `entry` line per 8 bytes from 0x20.
public struct CombatAISegment: Equatable, Sendable {
    public static let headerSize = 0x20
    public static let entrySize = 8

    /// The header's Pascal name, MacRoman.
    public let name: String
    /// The entries as stored, 8 bytes each (§3.2: op/weight, index, object base, parameter, modifiers, 0).
    public let entries: [[UInt8]]

    public init(bytes: [UInt8]) throws {
        guard bytes.count >= Self.headerSize else { throw CombatAIError.truncated(length: bytes.count) }
        guard (bytes.count - Self.headerSize) % Self.entrySize == 0 else {
            throw CombatAIError.raggedEntries(length: bytes.count)
        }
        let n = Int(bytes[0])
        guard n <= 0x17 else { throw CombatAIError.nameTooLong(n) }
        name = MacRoman.decode(bytes[1..<(1 + n)])
        entries = stride(from: Self.headerSize, to: bytes.count, by: Self.entrySize).map {
            Array(bytes[$0..<($0 + Self.entrySize)])
        }
    }

    /// The listing lines: `name` at 0, then `entry` at 0x20 + 8·i; length 0 (the canonical form's rule).
    var instructions: [ScriptInstruction] {
        [ScriptInstruction(offset: 0, length: 0, mnemonic: "name", kind: .literal)]
            + entries.indices.map {
                ScriptInstruction(offset: Self.headerSize + Self.entrySize * $0, length: 0, mnemonic: "entry",
                                  kind: .literal)
            }
    }
}

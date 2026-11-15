import Foundation

/// The canonical parity form (plan C9 contract 3): the same bytes `docs/cythera/tools/script_canon.py` derives
/// from a committed `scriptdis.py` listing, hashed per segment into `docs/cythera/script-parity.sha256`.
///
///     seg <ID4> kind <kind> len <TOC length>
///     <OFFS4> <LEN> <MNEMONIC> <FLAG>
///
/// one line per listing instruction in listing order, each ending in "\n"; `ID4`/`OFFS4` four upper-case hex
/// digits, `LEN` decimal bytes (0 for `name`/`entry`), `FLAG` `-` reached, `>` jump target, `x` dead.
public enum ScriptCanonical {
    public static func text(_ listing: ScriptSegmentListing) -> String {
        var out = "seg \(hex4(Int(listing.id))) kind \(listing.kind.rawValue) len \(listing.length)\n"
        for i in listing.instructions {
            out += "\(hex4(i.offset)) \(i.length) \(i.mnemonic) \(flag(i.flag))\n"
        }
        return out
    }

    private static func flag(_ f: ScriptInstruction.Flag) -> String {
        switch f {
        case .reached: return "-"
        case .jumpTarget: return ">"
        case .dead: return "x"
        }
    }

    private static func hex4(_ v: Int) -> String {
        let s = String(v, radix: 16, uppercase: true)
        return String(repeating: "0", count: max(0, 4 - s.count)) + s
    }
}

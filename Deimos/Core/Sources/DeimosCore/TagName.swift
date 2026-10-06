import Foundation
import HectorResources

/// A classic four-character code, big-endian (`'BOCR'` = 0x424F4352). Tag IDs are case-sensitive
/// (`bocr` ≠ `BOCR`); `none` means "no resource" everywhere in the engine (bank pak-format.md §2.1).
public struct FourCC: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UInt32

    public init(rawValue: UInt32) { self.rawValue = rawValue }

    /// Exactly four Mac Roman bytes, else nil.
    public init?(_ s: String) {
        guard let bytes = MacRoman.encode(s, lossy: false), bytes.count == 4 else { return nil }
        self.init(bytes: bytes)
    }

    /// Four bytes, big-endian.
    init(bytes b: [UInt8]) {
        rawValue = UInt32(b[0]) << 24 | UInt32(b[1]) << 16 | UInt32(b[2]) << 8 | UInt32(b[3])
    }

    public var bytes: [UInt8] {
        [UInt8(rawValue >> 24), UInt8(rawValue >> 16 & 0xFF), UInt8(rawValue >> 8 & 0xFF), UInt8(rawValue & 0xFF)]
    }

    public static let none = FourCC(rawValue: 0x6e6f_6e65)

    /// The four bytes as Mac Roman text (`"bop "`).
    public var description: String { MacRoman.decode(bytes) }
}

/// A pak entry or Local file name → (display name, tag ID, resource type), the original's rules
/// (bank pak-format.md §2.1 `FUN_100021a0`/`FUN_10003a40`, §2.2 `FUN_10003b20`; listings
/// `100021a0–10002330`, `10003a40–10003b14`):
/// - the zip path up to the last `/` is stripped (`FUN_10004150`);
/// - a name that, lower-cased, contains `.zip` or `.pak` is refused first (`FUN_100040c0` at
///   `100021e8`, "Zip files are not supported in the Local directory" — the same check, and the same
///   text, for pak ENTRY names);
/// - the name is scanned for a `[`; with none, a name containing `.DS_Store` or `icon` (both
///   case-sensitive `strstr`, `0x100e33cc`/`0x100e361c`, `10002264–1000229c`) is dropped silently and
///   any other logs "no valid information". These two words are silent ONLY on this no-`[` path:
///   `Big icon[icon].gif` is a valid tag, and `.DS_Store[abcd].gif` is refused by the suffix rule
///   (its first `.` starts `.DS_Store[abcd]`), with the suffix alert, not silently;
/// - display name = the text before the first `[` (copied into a 32-byte record field, `1000222c–10002248`;
///   the copy is not bounded, so a display name over 31 characters would overrun into the record's
///   type/ID words — none ships; this port keeps the whole text);
/// - tag ID = `strtok(dup, "[")` then `strtok(NULL, "]")` (`10003a8c–10003ac4`), which must be
///   exactly 4 characters (spaces allowed: `[bop ]`). `strtok` skips leading delimiters, so
///   `[abcd].gif` has no ID (the first token is `abcd].gif`, there is no second) and `X[]abcd].gif`
///   has ID `abcd`;
/// - type = the suffix copied from the FIRST `.` in the name (at most 15 characters), matched
///   against 15 fixed tables in order, first match wins. The folder an entry sits in does NOT type it.
public struct TagName: Sendable, Equatable {
    public let displayName: String
    public let id: FourCC
    public let type: FourCC

    /// Why a name has no tag, in the order `FUN_100021a0` tests: `.zipFile` (lower-cased name
    /// contains `.zip`/`.pak`), `.ignored` (no `[` and contains `.DS_Store` or `icon` — silent),
    /// `.noValidInformation` (no `[` otherwise), `.noTagID`, `.noValidSuffix`. `TagIndex` turns each
    /// into the original's log line (`TagIndex.alertText`).
    public enum Failure: Error, Equatable, Sendable { case zipFile, ignored, noValidInformation, noTagID, noValidSuffix }

    /// The 15 resource types in suffix-table order (also the Local folder scan order, bank
    /// app-pak-music-library.md §2.1).
    public static let typeOrder: [FourCC] = suffixTables.map(\.type)

    /// pak-format.md §2.2, table bytes as dumped (loop counts 8/8/14/12/9/8/9/9/12/7/6/3/3/7/9).
    static let suffixTables: [(type: FourCC, suffixes: [String])] = [
        ("im08", [".im08", ".Im08", ".IM08", ".gif", ".GIF", ".giff", ".GIFf", ".GIFF"]),
        ("im16", [".im16", ".Im16", ".IM16", ".tga", ".TGA", ".Targa", ".targa", ".TARGA"]),
        ("soun", [".snd", ".Snd", ".SND", ".sound", ".Sound", ".SOUND", ".aif", ".Aif", ".AIF", ".aiff", ".Aiff",
                  ".AIFF", ".ima", ".IMA"]),
        ("stli", [".txt", ".Txt", ".TXT", ".text", ".Text", ".TEXT", ".string", ".String", ".STRING", ".stli",
                  ".Stli", ".STLI"]),
        ("flli", [".flt", ".Flt", ".FLT", ".float", ".Float", ".FLOAT", ".flli", ".Flli", ".FLLI"]),
        ("wede", [".we", ".WE", ".wep", ".Wep", ".WEP", ".wede", ".Wede", ".WEDE"]),
        ("reli", [".rect", ".Rect", ".RECT", ".reli", ".Reli", ".RELI", ".rectlist", ".RectList", ".RECTLIST"]),
        ("idli", [".id", ".ID", ".Id", ".idli", ".IDLI", ".Idli", ".idlist", ".IDLIST", ".IDList"]),
        ("coli", [".co", ".CO", ".Co", ".coli", ".COLI", ".Coli", ".color", ".COLOR", ".Color", ".colorlist",
                  ".COLORLIST", ".ColorList"]),
        ("tefo", [".tefo", ".Tefo", ".TEFO", ".textformat", ".TEXTFORMAT", ".Textformat", ".TextFormat"]),
        ("plde", [".plde", ".Plde", ".PLDE", ".player", ".PLAYER", ".Player"]),
        ("pref", [".pref", ".Pref", ".PREF"]),
        ("film", [".film", ".Film", ".FILM"]),
        ("unde", [".unde", ".Unde", ".UNDE", ".unitdef", ".UnitDef", ".UNITDEF", ".unit"]),
        ("leve", [".lvl", ".Lvl", ".LVL", ".leve", ".Leve", ".LEVE", ".level", ".Level", ".LEVEL"]),
    ].map { (FourCC($0.0)!, $0.1) }

    public init(displayName: String, id: FourCC, type: FourCC) {
        self.displayName = displayName
        self.id = id
        self.type = type
    }

    /// nil when the name is not a tag (see `parse` for the reason).
    public init?(entryName: String) {
        guard case .success(let t) = Self.parse(entryName) else { return nil }
        self = t
    }

    /// The same rules, reporting why a name was refused.
    public static func parse(_ entryName: String) -> Result<TagName, Failure> {
        let name = entryName.split(separator: "/", omittingEmptySubsequences: false).last.map(String.init) ?? entryName
        if isZipName(name) { return .failure(.zipFile) }
        // The '[' scan; with none, '.DS_Store' / 'icon' (case-sensitive) are silent, else "no valid information".
        guard let open = name.firstIndex(of: "[") else {
            return .failure(name.contains(".DS_Store") || name.contains("icon") ? .ignored : .noValidInformation)
        }
        guard let idText = strtokID(name), let id = FourCC(idText) else { return .failure(.noTagID) }
        // Suffix: from the FIRST '.', max 15 characters, then the 15 tables in order.
        guard let dot = name.firstIndex(of: ".") else { return .failure(.noValidSuffix) }
        let suffix = String(name[dot...].prefix(15))
        guard let type = suffixTables.first(where: { $0.suffixes.contains(suffix) })?.type else {
            return .failure(.noValidSuffix)
        }
        return .success(TagName(displayName: String(name[..<open]), id: id, type: type))
    }

    /// `FUN_100040c0`: the name, lower-cased, contains `.zip` or `.pak` (`strstr`, anywhere — not a
    /// suffix test; `100040d4–1000411c`).
    public static func isZipName(_ name: String) -> Bool {
        let l = name.lowercased()
        return l.contains(".zip") || l.contains(".pak")
    }

    /// `strtok(dup, "[")`, then `strtok(NULL, "]")`: the second token, or nil when either is missing.
    static func strtokID(_ name: String) -> String? {
        let c = Array(name)
        var i = 0
        // Token 1: skip leading '[', then run to the next '[' (or the end).
        while i < c.count, c[i] == "[" { i += 1 }
        guard i < c.count else { return nil }
        while i < c.count, c[i] != "[" { i += 1 }
        guard i < c.count else { return nil }     // strtok saved the end: the next call returns NULL
        i += 1                                    // past the '[' strtok overwrote
        // Token 2: skip leading ']', then run to the next ']' (or the end).
        while i < c.count, c[i] == "]" { i += 1 }
        guard i < c.count else { return nil }
        let start = i
        while i < c.count, c[i] != "]" { i += 1 }
        return String(c[start..<i])
    }
}

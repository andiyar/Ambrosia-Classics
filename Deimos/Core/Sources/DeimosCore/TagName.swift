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
/// (bank pak-format.md §2.1 `FUN_100021a0`/`FUN_10003a40`, §2.2 `FUN_10003b20`):
/// - the zip path up to the last `/` is stripped;
/// - a name containing `.DS_Store` is rejected (silently, by the caller);
/// - display name = the text before the first `[`; tag ID = the text from there to the next `]`,
///   exactly 4 characters (spaces allowed: `[bop ]`);
/// - type = the suffix copied from the FIRST `.` in the name (at most 15 characters), matched
///   against 15 fixed tables in order, first match wins. The folder an entry sits in does NOT type it.
public struct TagName: Sendable, Equatable {
    public let displayName: String
    public let id: FourCC
    public let type: FourCC

    /// Why a name has no tag: the original's two log lines (`"FILE ALERT.  Could not find Tag ID in
    /// file:  %s"`, `"… a valid suffix …"`), or `.ignored` for `.DS_Store` (silent).
    public enum Failure: Error, Equatable, Sendable { case ignored, noTagID, noValidSuffix }

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
        if name.contains(".DS_Store") { return .failure(.ignored) }
        // ID: strtok "[" then "]" — the text between the first '[' and the next ']', exactly 4 chars.
        guard let open = name.firstIndex(of: "[") else { return .failure(.noTagID) }
        let afterOpen = name[name.index(after: open)...]
        let idText = afterOpen.firstIndex(of: "]").map { afterOpen[..<$0] } ?? afterOpen
        guard let id = FourCC(String(idText)) else { return .failure(.noTagID) }
        // Suffix: from the FIRST '.', max 15 characters, then the 15 tables in order.
        guard let dot = name.firstIndex(of: ".") else { return .failure(.noValidSuffix) }
        let suffix = String(name[dot...].prefix(15))
        guard let type = suffixTables.first(where: { $0.suffixes.contains(suffix) })?.type else {
            return .failure(.noValidSuffix)
        }
        return .success(TagName(displayName: String(name[..<open]), id: id, type: type))
    }
}

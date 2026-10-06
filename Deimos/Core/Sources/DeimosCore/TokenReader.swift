import Foundation
import HectorResources

// `MacRect` (top, left, bottom, right) lives in MacRect.swift (shared with the sprite-plate scan).

/// The U_Token reader (U_Token.cc; bank data-tags.md §1, unit-def-struct.md §2), over decoded text with
/// C-string semantics (everything from the first NUL on is invisible).
///
/// Locator (`FUN_1002c550`): `strstr(buf + cursor, key)`, then `<` searched from the key hit, then `>`;
/// the value is the bytes between; on success `cursor` := the position of `>`. The cursor only moves
/// forward, so keys must appear in call order — a key before the cursor is not found (and a key missing
/// from one block is taken from the next: the original's misparse, reproduced). A miss leaves the cursor.
///
/// Readers: STR (missing key silent, nil = default kept; at most `maxLength − 1` bytes; `<>` → "") ·
/// ID (exactly 4 bytes) · INT (`sscanf "%i"` on the first 31 chars) · FLOAT (`sscanf "%f"`, float32, first
/// 31 chars) · BOOL (`strcmp(v, "TRUE") == 0`) · COLOR (`RRGGBB` → x1R5G5B5 `c >> 3`) · RECT (`strtok ","`
/// + 4 × `%i`, text l,t,r,b). A reader returns nil when it does not store (dest untouched, the caller's
/// default kept); which nils also raise the original's error flag (`DAT_100e01e1`; strict mode is the
/// caller's) follows the listings:
/// - INT/FLOAT (`1002c880–1002c950`, `1002c960–1002ca30`): a missing key ("Couldn't find KEY for an
///   Integer/a Float") and a zero-length value ("Invalid Integer/Floating Point Length") flag; a value
///   with no digits does NOT — `sscanf`'s return is unchecked (`1002c924–1002c92c`, `1002ca04–1002ca0c`),
///   so the destination is simply not written. A value over 31 chars is scanned on its first 31.
/// - COLOR (`FUN_10010990`, `100109c0–100109f0`; wrapper `FUN_1002cbd0`): anything but six hex digits —
///   including the string `"0"` — makes the converter return false without its own log; the wrapper logs
///   "Invalid COLOR.", flags, and leaves the destination untouched.
/// - RECT is the one reader that WRITES on failure: the original zeroes all four destination words before
///   the lookup (`1002ccbc–1002ccd4`), so a missing RECT key leaves a zero rect (and flags); a value with
///   fewer than 4 tokens ends its loop with the words read so far and no flag. This port returns nil +
///   flag for any malformed RECT (no shipped RECT is malformed, and no RECT default is non-zero — C3), and
///   `DefinitionReader.rect` keeps the caller's (zero) default.
/// - ID: missing key or length ≠ 4 flags.
///
/// `orderIndependent = true` (and `findAnywhere`) is the G_Text style (`FUN_1002c630`, used by `tefo`):
/// a fresh search from the start for every key.
public struct TokenReader {
    public let text: [UInt8]
    public var cursor: Int = 0
    public var orderIndependent = false
    public private(set) var errors: [String] = []
    public var errorCount: Int { errors.count }

    public init(_ bytes: [UInt8]) {
        text = bytes.firstIndex(of: 0).map { Array(bytes[..<$0]) } ?? bytes
    }

    // MARK: locator

    /// The value bytes of `key` (cursor rules above), or nil.
    public mutating func value(_ key: String) -> [UInt8]? {
        let start = orderIndependent ? 0 : cursor
        guard let (value, gt) = Self.locate(text, key: Array(key.utf8), from: start) else { return nil }
        if !orderIndependent { cursor = gt }
        return value
    }

    /// The G_Text search: `key` from the start of `text` (to its first NUL), then `<`, then `>`.
    public static func findAnywhere(_ text: [UInt8], key: String) -> [UInt8]? {
        let visible = text.firstIndex(of: 0).map { Array(text[..<$0]) } ?? text
        return locate(visible, key: Array(key.utf8), from: 0)?.value
    }

    static func locate(_ text: [UInt8], key: [UInt8], from: Int) -> (value: [UInt8], gt: Int)? {
        guard let hit = find(key, in: text, from: from),
              let lt = find([UInt8(ascii: "<")], in: text, from: hit),
              let gt = find([UInt8(ascii: ">")], in: text, from: lt) else { return nil }
        return (Array(text[(lt + 1)..<gt]), gt)
    }

    /// `strstr` from `from`.
    static func find(_ needle: [UInt8], in hay: [UInt8], from: Int) -> Int? {
        guard !needle.isEmpty, from >= 0, hay.count >= needle.count else { return needle.isEmpty ? from : nil }
        var i = from
        let last = hay.count - needle.count
        while i <= last {
            if hay[i] == needle[0] {
                var j = 1
                while j < needle.count && hay[i + j] == needle[j] { j += 1 }
                if j == needle.count { return i }
            }
            i += 1
        }
        return nil
    }

    /// The keys of the generic `#…<…>` walk, in file order (`#` + the text up to `<`, trailing white
    /// space trimmed) — what the positional lists read; used by the census.
    public static func itemKeys(_ text: [UInt8]) -> [String] { items(text).map { "#" + $0.key } }

    /// The generic walk (`FUN_1002c700(buf, cursor, "#", …, "<", ">")`): find `#`, then `<`, then `>`;
    /// key = the bytes between `#` and `<` with surrounding white space trimmed (Mac Roman).
    /// The original is `strstr(buf + cursor, "#")`, then `strtok(hit, "<")` and `strtok(NULL, ">")`, with the
    /// cursor set to the value's start (`1002c724–1002c7b0`). `strtok` skips leading delimiters, so an
    /// empty `<>` value there would read the text after the `>` instead of "" (and its NUL writes cut the
    /// buffer); this find-based walk returns "". No shipped positional list (flli/idli/reli/coli) or
    /// `tefo` has an empty value, so the two walks agree on every shipped file.
    public static func items(_ bytes: [UInt8]) -> [(key: String, value: [UInt8])] {
        let text = bytes.firstIndex(of: 0).map { Array(bytes[..<$0]) } ?? bytes
        var out: [(String, [UInt8])] = []
        var c = 0
        while let hash = find([UInt8(ascii: "#")], in: text, from: c),
              let lt = find([UInt8(ascii: "<")], in: text, from: hash),
              let gt = find([UInt8(ascii: ">")], in: text, from: lt) {
            let key = trimmed(Array(text[(hash + 1)..<lt]))
            out.append((MacRoman.decode(key), Array(text[(lt + 1)..<gt])))
            c = gt
        }
        return out
    }

    static func trimmed(_ b: [UInt8]) -> [UInt8] {
        let ws: Set<UInt8> = [0x20, 0x09, 0x0d, 0x0a]
        guard let first = b.firstIndex(where: { !ws.contains($0) }), let last = b.lastIndex(where: { !ws.contains($0) })
        else { return [] }
        return Array(b[first...last])
    }

    /// Raise the error flag for `key` (a caller-side malformation).
    public mutating func markError(_ key: String) { errors.append(key) }

    private mutating func fail<T>(_ key: String) -> T? {
        errors.append(key)
        return nil
    }

    // MARK: readers

    /// STR: nil when the key is missing (silent — the caller keeps its default); else at most
    /// `maxLength − 1` bytes, Mac Roman.
    public mutating func string(_ key: String, maxLength: Int) -> String? {
        stringBytes(key, maxLength: maxLength).map(MacRoman.decode)
    }

    public mutating func stringBytes(_ key: String, maxLength: Int) -> [UInt8]? {
        guard let v = value(key) else { return nil }
        return Array(v.prefix(max(0, maxLength - 1)))
    }

    public mutating func id(_ key: String) -> FourCC? {
        guard let v = value(key) else { return fail(key) }
        guard let id = Self.parseID(v) else { return fail(key) }
        return id
    }

    /// nil + error for a missing key or an empty value; nil WITHOUT an error when `%i` matches nothing.
    public mutating func int(_ key: String) -> Int32? {
        guard let v = value(key), !v.isEmpty else { return fail(key) }
        return Self.parseInt(v)
    }

    /// nil + error for a missing key or an empty value; nil WITHOUT an error when `%f` matches nothing.
    public mutating func float(_ key: String) -> Float? {
        guard let v = value(key), !v.isEmpty else { return fail(key) }
        return Self.parseFloat(v)
    }

    public mutating func bool(_ key: String) -> Bool? {
        guard let v = value(key) else { return fail(key) }
        return Self.parseBool(v)
    }

    public mutating func color(_ key: String) -> UInt16? {
        guard let v = value(key), let c = Self.parseColor(v) else { return fail(key) }
        return c
    }

    public mutating func rect(_ key: String) -> MacRect? {
        guard let v = value(key), let r = Self.parseRect(v) else { return fail(key) }
        return r
    }

    // MARK: value parsers (shared with the positional lists)

    static func parseID(_ v: [UInt8]) -> FourCC? { v.count == 4 ? FourCC(bytes: v) : nil }

    static func parseBool(_ v: [UInt8]) -> Bool { v == Array("TRUE".utf8) }

    /// INT: first 31 chars, `%i`; nil for an empty value or no match (the caller decides what flags).
    static func parseInt(_ v: [UInt8]) -> Int32? {
        guard !v.isEmpty else { return nil }
        return scanInt(Array(v.prefix(31)))
    }

    static func parseFloat(_ v: [UInt8]) -> Float? {
        guard !v.isEmpty else { return nil }
        return scanFloat(Array(v.prefix(31)))
    }

    /// `sscanf(s, "%i")`: skip white space, optional sign, `0x`/`0X` hex, leading `0` octal, else
    /// decimal; stops at the first byte that is not a digit of the base. nil when nothing matched.
    /// Out-of-range values clamp to Int32 (strtol-style).
    static func scanInt(_ s: [UInt8]) -> Int32? {
        var i = 0
        while i < s.count, isSpace(s[i]) { i += 1 }
        var negative = false
        if i < s.count, s[i] == UInt8(ascii: "+") || s[i] == UInt8(ascii: "-") { negative = s[i] == UInt8(ascii: "-"); i += 1 }
        var base: Int64 = 10
        if i < s.count, s[i] == UInt8(ascii: "0") {
            if i + 2 < s.count, s[i + 1] | 0x20 == UInt8(ascii: "x"), digit(s[i + 2], base: 16) != nil {
                base = 16; i += 2
            } else {
                base = 8
            }
        }
        var value: Int64 = 0, any = false
        while i < s.count, let d = digit(s[i], base: base) {
            value = min(value * base + Int64(d), Int64(Int32.max) + 1)
            any = true
            i += 1
        }
        guard any else { return nil }
        let signed = negative ? -value : value
        return Int32(clamping: signed)
    }

    /// `sscanf(s, "%f")` to float32: white space, sign, digits, `.`, digits, optional exponent.
    static func scanFloat(_ s: [UInt8]) -> Float? {
        var i = 0
        while i < s.count, isSpace(s[i]) { i += 1 }
        let start = i
        if i < s.count, s[i] == UInt8(ascii: "+") || s[i] == UInt8(ascii: "-") { i += 1 }
        var digits = 0
        while i < s.count, digit(s[i], base: 10) != nil { i += 1; digits += 1 }
        if i < s.count, s[i] == UInt8(ascii: ".") {
            i += 1
            while i < s.count, digit(s[i], base: 10) != nil { i += 1; digits += 1 }
        }
        guard digits > 0 else { return nil }
        if i < s.count, s[i] | 0x20 == UInt8(ascii: "e") {
            var j = i + 1
            if j < s.count, s[j] == UInt8(ascii: "+") || s[j] == UInt8(ascii: "-") { j += 1 }
            var e = 0
            while j < s.count, digit(s[j], base: 10) != nil { j += 1; e += 1 }
            if e > 0 { i = j }
        }
        return Float(String(decoding: s[start..<i], as: UTF8.self))
    }

    /// COLOR ("HTML RGB", `FUN_10010990`): exactly six hex digits `RRGGBB` → `(r>>3)<<10 | (g>>3)<<5 | b>>3`
    /// (≡ the original's `trunc(65535·c/255)` path for every c, INDEX #40); anything else — `"0"` too —
    /// is nil (an error, `100109c0–100109f0`).
    static func parseColor(_ v: [UInt8]) -> UInt16? {
        guard v.count == 6 else { return nil }
        var c: [UInt16] = []
        for k in stride(from: 0, to: 6, by: 2) {
            guard let hi = digit(v[k], base: 16), let lo = digit(v[k + 1], base: 16) else { return nil }
            c.append(UInt16(hi * 16 + lo))
        }
        return (c[0] >> 3) << 10 | (c[1] >> 3) << 5 | c[2] >> 3
    }

    /// RECT: `strtok(v, ",")` (empty tokens skipped) + `%i` × 4; text (left, top, right, bottom).
    static func parseRect(_ v: [UInt8]) -> MacRect? {
        let tokens = v.split(separator: UInt8(ascii: ","), omittingEmptySubsequences: true)
        guard tokens.count >= 4 else { return nil }
        var n: [Int32] = []
        for t in tokens.prefix(4) {
            guard let x = scanInt(Array(t)) else { return nil }
            n.append(x)
        }
        return MacRect(top: n[1], left: n[0], bottom: n[3], right: n[2])
    }

    static func isSpace(_ b: UInt8) -> Bool { b == 0x20 || (0x09...0x0d).contains(b) }

    static func digit(_ b: UInt8, base: Int64) -> Int? {
        let d: Int
        switch b {
        case UInt8(ascii: "0")...UInt8(ascii: "9"): d = Int(b) - 48
        case UInt8(ascii: "a")...UInt8(ascii: "f"): d = Int(b) - 87
        case UInt8(ascii: "A")...UInt8(ascii: "F"): d = Int(b) - 55
        default: return nil
        }
        return d < base ? d : nil
    }
}

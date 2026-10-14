import Foundation
import HectorResources

/// The saved-game name the Save panel proposes (prefs +0x42).
public enum SaveName {
    /// "Ferazel Saved Game" (pstr `0x100a586c`, also the `'FWSg'` resource name).
    public static let defaultName = "Ferazel Saved Game"

    /// `.IncrementLastSGString @ 1004811c` (M l. 41115) on a pstr[256] field (length byte + 255; shorter fields are
    /// read as 0-padded). Chars 1…4 all '@' — read whatever the length byte says — → "Ferazel Saved Game". Else, only
    /// when the length is < 31 (`< 0x1f`): a trailing run of digits → the run's value + 1 (`NumToString`, the prefix
    /// kept; the value accumulates in 32 bits as the PPC's does); a trailing space → append "2"; anything else
    /// (including the length byte itself when the length is 0) → append " 2". Bytes past the new length keep what
    /// was there, as in the original.
    public static func increment(field: [UInt8]) -> [UInt8] {
        var p = field
        if p.count < 0x100 { p += [UInt8](repeating: 0, count: 0x100 - p.count) }
        if p[1...4].allSatisfy({ $0 == 0x40 }) {
            let body = MacRoman.bytes(defaultName)
            p[0] = UInt8(body.count)
            p.replaceSubrange(1...body.count, with: body)
            return p
        }
        let len = Int(p[0])
        guard len < 0x1f else { return p }
        if !isDigit(p[len]) {
            if p[len] == 0x20 {
                p[0] = UInt8(len + 1)
                p[len + 1] = 0x32
            } else {
                p[0] = UInt8(len + 2)
                p[len + 1] = 0x20
                p[len + 2] = 0x32
            }
            return p
        }
        var n = len, scale: Int32 = 1, value: Int32 = 0
        while n > 0, isDigit(p[n]) {
            value = value &+ scale &* Int32(p[n] - 0x30)
            scale = scale &* 10
            n -= 1
        }
        let digits = Array(String(value &+ 1).utf8)          // NumToString
        p[0] = UInt8(n + digits.count)                       // ConcatPString (n + digits ≤ 30 + 11 < 255)
        p.replaceSubrange((n + 1)...(n + digits.count), with: digits)
        return p
    }

    /// `increment(field:)` on a name whose field holds 0 past its length.
    public static func increment(_ name: String) -> String {
        let body = Array(MacRoman.bytes(name).prefix(255))
        let out = increment(field: [UInt8(body.count)] + body)
        return MacRoman.decode(out[1...Int(out[0])].map { $0 })
    }

    /// `_IsDigit`: '0'…'9'.
    private static func isDigit(_ c: UInt8) -> Bool { (0x30...0x39).contains(c) }
}

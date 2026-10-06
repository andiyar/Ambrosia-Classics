import Foundation
import HectorResources

/// `tefo` — a text format (G_Text.cc `FUN_1000ef90`; bank data-tags.md §5, hud-scorebar.md §9). The 16 keys
/// the original reads, each by a fresh search from the start of the text (order-independent). `#Size_INT`,
/// present in every shipped file, is never read (the string does not exist in the binary).
///
/// Fields keep the format template's defaults (`0x100e52e4`: LEFT, everything else 0/false) when a key is
/// missing or malformed; such keys are listed in `errors`. `#Format_ID`: the strings "0"–"4" map to LEFT CENT
/// RIGH CEBU CEGA (`<3>` = CEBU, `<4>` = CEGA: the value is cut at `>` by strtok, INDEX #5); otherwise its
/// first 4 characters are the 4CC (`RIGHT` → `RIGH`), and anything not among the five logs "Unknown Text
/// Format Flag" and becomes LEFT. BlendAmount (0 opaque … 32 invisible) is kept as read; the original asserts
/// the colour-strip blend lies in 0…32. The original scans the two BlendAmount keys with `%u` (unsigned);
/// this port uses the shared `%i` reader — identical for the shipped values (all plain non-negative
/// decimals ≤ 32); a negative or `0x`/leading-`0` value would differ.
public struct TextFormat: Sendable, Equatable {
    public enum Alignment: String, Sendable, Equatable, Hashable {
        case left = "LEFT", center = "CENT", right = "RIGH", centerInBuffer = "CEBU", centerInGameArea = "CEGA"
    }

    public var locX: Int32 = 0
    public var locY: Int32 = 0
    public var format: Alignment = .left
    public var monospaced = false
    public var drawShadows = false
    public var blendAmount: Int32 = 0
    public var spaceBetweenChars: Int32 = 0
    public var coloriseDo = false
    public var coloriseColor: UInt16 = 0
    public var colorStripDo = false
    public var colorStripHOffset: Int32 = 0
    public var colorStripVOffset: Int32 = 0
    public var colorStripBlendAmount: Int32 = 0
    public var colorStripColor: UInt16 = 0
    public var colorStripMinWidth: Int32 = 0
    public var colorStripMinHeight: Int32 = 0
    /// Keys missing or malformed (the token error flag).
    public private(set) var errors: [String] = []
    /// The original's log lines (unknown format flag).
    public private(set) var alerts: [String] = []

    /// `data` = the tag's stored (obfuscated) bytes; `tagName` only labels the alert.
    public init(data: Data, tagName: String = "") {
        self.init(text: DeimosText.decode(Array(data)), tagName: tagName)
    }

    public init(text: [UInt8], tagName: String = "") {
        var r = TokenReader(text)
        r.orderIndependent = true
        locX = r.int("#Loc_X_INT") ?? locX
        locY = r.int("#Loc_Y_INT") ?? locY
        if let v = r.value("#Format_ID") {
            if let a = Self.alignment(v) {
                format = a
            } else {
                alerts.append("FILE DATA ERROR: Unknown Text Format Flag (\(MacRoman.decode(v.prefix(4)))) in Tag \"\(tagName)\"")
                format = .left
            }
        } else {
            r.markError("#Format_ID")
        }
        monospaced = r.bool("#Monospaced_BOOL") ?? monospaced
        drawShadows = r.bool("#DrawShadows_BOOL") ?? drawShadows
        blendAmount = r.int("#BlendAmount_0To32_INT") ?? blendAmount
        spaceBetweenChars = r.int("#SpaceBetweenChars_INT") ?? spaceBetweenChars
        coloriseDo = r.bool("#Colorise_Do_BOOL") ?? coloriseDo
        coloriseColor = r.color("#ColoriseColor_RGB") ?? coloriseColor
        colorStripDo = r.bool("#ColorStrip_Do_BOOL") ?? colorStripDo
        colorStripHOffset = r.int("#ColorStrip_HOffset_INT") ?? colorStripHOffset
        colorStripVOffset = r.int("#ColorStrip_VOffset_INT") ?? colorStripVOffset
        colorStripBlendAmount = r.int("#ColorStrip_BlendAmount_0To32_INT") ?? colorStripBlendAmount
        colorStripColor = r.color("#ColorStrip_Color_RGB") ?? colorStripColor
        colorStripMinWidth = r.int("#ColorStrip_MinWidth_INT") ?? colorStripMinWidth
        colorStripMinHeight = r.int("#ColorStrip_MinHeight_INT") ?? colorStripMinHeight
        errors = r.errors
    }

    static func alignment(_ v: [UInt8]) -> Alignment? {
        let digits: [[UInt8]: Alignment] = [
            Array("0".utf8): .left, Array("1".utf8): .center, Array("2".utf8): .right,
            Array("3".utf8): .centerInBuffer, Array("4".utf8): .centerInGameArea,
        ]
        if let a = digits[v] { return a }
        guard v.count >= 4 else { return nil }
        return Alignment(rawValue: MacRoman.decode(v.prefix(4)))
    }
}

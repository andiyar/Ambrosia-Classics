import BubbleTroubleCore
import Foundation
import HectorGraphics
import HectorResources

/// One classic dialog item as the Dialog Manager reads it from a `DITL` (Inside Mac I-421) — the Windows port of the
/// Mac app's `DialogItem` (`BubbleTroubleX/App/BTXDialogResources.swift`, read-only to this package): its 1-based
/// number, its rect in dialog-local QuickDraw coordinates (top-left origin, y down), its kind, the "disabled" bit
/// (0x80: the item never makes `ModalDialog` return its number) and its text — or, for control / icon / picture items,
/// the resource id the item names.
public struct DialogItem: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case user, button, checkBox, radio
        /// `ctrlItem` + `resCtrl`: a `CNTL` resource (the prefs popups, `CNTL 1000/1001/1009`).
        case control(cntl: Int)
        case staticText, editText
        case icon(Int)
        case picture(pict: Int)
        case other(UInt8)
    }

    public let number: Int
    public let rect: DialogRect
    public let kind: Kind
    public let enabled: Bool
    public let text: String

    public init(number: Int, rect: DialogRect, kind: Kind, enabled: Bool, text: String) {
        self.number = number
        self.rect = rect
        self.kind = kind
        self.enabled = enabled
        self.text = text
    }
}

/// An integer rect in dialog-local QuickDraw coordinates (x = left, y = top, y down) — Foundation-only, so the
/// Windows build needs no CoreGraphics.
public struct DialogRect: Equatable, Hashable, Sendable {
    public var x: Int, y: Int, width: Int, height: Int
    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x; self.y = y; self.width = width; self.height = height
    }
    public var minX: Int { x }
    public var minY: Int { y }
    public var maxX: Int { x + width }
    public var maxY: Int { y + height }
    /// QuickDraw `PtInRect`: left/top inclusive, right/bottom exclusive.
    public func contains(_ px: Int, _ py: Int) -> Bool { px >= x && px < maxX && py >= y && py < maxY }
    /// QuickDraw `InsetRect` (negative = outset).
    public func insetBy(_ dx: Int, _ dy: Int) -> DialogRect {
        DialogRect(x: x + dx, y: y + dy, width: width - 2 * dx, height: height - 2 * dy)
    }
    public func offsetBy(_ dx: Int, _ dy: Int) -> DialogRect {
        DialogRect(x: x + dx, y: y + dy, width: width, height: height)
    }
}

/// A dialog's window template: `DLOG` (proc 1 = `dBoxProc` for every BTX dialog) or `ALRT`.
public struct DialogTemplate: Equatable, Sendable {
    public let id: Int
    public let width: Int
    public let height: Int
    /// `DLOG`/`ALRT` positioning word: 0xa80a `alertPositionParentWindowScreen`, 0x700a `alertPositionMainScreen`.
    public let position: UInt16
    public let items: [DialogItem]
    /// `ALRT` only: the stage word (BTX: 0x5555 = every stage draws, bolds item 1, sounds `SysBeep` once).
    public let alertStages: UInt16?
}

/// `CNTL` popup record (`popupMenuProc` 1008 + variation): value = title justification, min = `MENU` id, max = title width.
public struct DialogPopupTemplate: Equatable, Sendable {
    public let title: String
    public let titleWidth: Int
    public let menuID: Int
}

/// Classic dialog resources read straight from the shipped `Bubble Trouble X.rsrc` (through `BTXGameData`) — a
/// Foundation-only port of the Mac app's `BTXDialogResources` (same record walks; MacRoman through HectorResources,
/// D16.2, since Foundation's `.macOSRoman` is mis-tabled on Windows).
public enum DialogResources {
    public static func dialog(_ id: Int, data: BTXGameData) -> DialogTemplate? {
        guard let dlog = data.data(type: "DLOG", id: id), dlog.count >= 20,
              let bounds = Ditl.dlogBounds(dlog) else { return nil }
        let b = [UInt8](dlog)
        let ditlID = Int(Int16(bitPattern: UInt16(b[18]) << 8 | UInt16(b[19])))
        // The position word follows the Pascal title, padded to even.
        let titleLength = Int(b[20])
        var o = 21 + titleLength
        if o % 2 == 1 { o += 1 }
        let position: UInt16 = o + 1 < b.count ? UInt16(b[o]) << 8 | UInt16(b[o + 1]) : 0
        guard let items = Self.items(ditl: ditlID, data: data) else { return nil }
        return DialogTemplate(id: id, width: Int(bounds.width), height: Int(bounds.height), position: position,
                              items: items, alertStages: nil)
    }

    public static func alert(_ id: Int, data: BTXGameData) -> DialogTemplate? {
        guard let alrt = data.data(type: "ALRT", id: id), alrt.count >= 12,
              let bounds = Ditl.dlogBounds(alrt) else { return nil }
        let b = [UInt8](alrt)
        let ditlID = Int(Int16(bitPattern: UInt16(b[8]) << 8 | UInt16(b[9])))
        let stages = UInt16(b[10]) << 8 | UInt16(b[11])
        let position: UInt16 = b.count >= 14 ? UInt16(b[12]) << 8 | UInt16(b[13]) : 0
        guard let items = Self.items(ditl: ditlID, data: data) else { return nil }
        return DialogTemplate(id: id, width: Int(bounds.width), height: Int(bounds.height), position: position,
                              items: items, alertStages: stages)
    }

    /// A `DITL`'s items, numbered from `firstNumber` (`AppendDITL` continues the dialog's numbering).
    public static func items(ditl id: Int, data: BTXGameData, firstNumber: Int = 1) -> [DialogItem]? {
        guard let blob = data.data(type: "DITL", id: id), let decoded = Ditl.decode(blob) else { return nil }
        let b = [UInt8](blob)
        var o = 2
        var out: [DialogItem] = []
        for item in decoded {
            o += 4 + 8 + 1
            guard o < b.count else { return nil }
            let length = Int(b[o]); o += 1
            guard o + length <= b.count else { return nil }
            let payload = Array(b[o..<(o + length)])
            o += length + (length % 2)
            let resID = payload.count >= 2 ? Int(Int16(bitPattern: UInt16(payload[0]) << 8 | UInt16(payload[1]))) : 0
            let kind: DialogItem.Kind = switch item.type & 0x7f {
            case 0: .user
            case 4: .button
            case 5: .checkBox
            case 6: .radio
            case 7: .control(cntl: resID)
            case 8: .staticText
            case 16: .editText
            case 32: .icon(resID)
            case 64: .picture(pict: resID)
            default: .other(item.type & 0x7f)
            }
            let text: String = switch kind {
            case .control, .icon, .picture: ""
            default: Self.macRoman(payload)
            }
            let r = item.rect
            out.append(DialogItem(number: firstNumber + item.number - 1,
                                  rect: DialogRect(x: Int(r.minX), y: Int(r.minY), width: Int(r.width),
                                                   height: Int(r.height)),
                                  kind: kind, enabled: item.type & 0x80 == 0, text: text))
        }
        return out
    }

    public static func popupControl(_ id: Int, data: BTXGameData) -> DialogPopupTemplate? {
        guard let c = data.data(type: "CNTL", id: id), c.count >= 23 else { return nil }
        let b = [UInt8](c)
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        let titleLength = Int(b[22])
        guard 23 + titleLength <= b.count else { return nil }
        return DialogPopupTemplate(title: macRoman(Array(b[23..<(23 + titleLength)])), titleWidth: i16(12),
                                   menuID: i16(14))
    }

    /// A `MENU`'s item titles (`"-"` / `"(-"` = separator, as the Menu Manager reads them).
    public static func menuItems(_ id: Int, data: BTXGameData) -> [String] {
        guard let m = data.data(type: "MENU", id: id), m.count > 15 else { return [] }
        let b = [UInt8](m)
        var o = 14 + 1 + Int(b[14])
        var out: [String] = []
        while o < b.count, b[o] != 0 {
            let length = Int(b[o])
            guard o + 1 + length + 4 <= b.count else { break }
            out.append(macRoman(Array(b[(o + 1)..<(o + 1 + length)])))
            o += 1 + length + 4
        }
        return out
    }

    /// MacRoman text with the Mac line break (CR) as a newline. (`replacingEvery`, not Foundation's
    /// `replacingOccurrences`, which traps on Windows for non-ASCII text — W7 review.)
    public static func macRoman(_ bytes: [UInt8]) -> String {
        MacRoman.decode(bytes).replacingEvery("\r", with: "\n")
    }

    /// The text as the original's C/Pascal buffers hold it: its MacRoman byte count (`strlen`).
    public static func byteLength(_ s: String) -> Int {
        MacRoman.encode(s, lossy: true)?.count ?? s.utf8.count
    }

    /// `s` cut to its first `n` MacRoman bytes (`local_128 = 0` in `_PrefsDialog`'s new-set loop).
    public static func truncated(_ s: String, bytes n: Int) -> String {
        guard let d = MacRoman.encode(s, lossy: true), d.count > n else { return s }
        return MacRoman.decode(d.prefix(n))
    }
}

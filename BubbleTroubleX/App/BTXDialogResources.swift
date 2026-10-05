import AppKit
import BubbleTroubleCore
import BubbleTroubleRender
import HectorGraphics

/// One classic dialog item as the Dialog Manager reads it from a `DITL` (Inside Mac I-421): its 1-based number, its
/// rect in dialog-local QuickDraw coordinates (top-left origin, y down), its kind, the "disabled" bit (0x80: the item
/// never makes `ModalDialog` return its number) and its text — or, for control / icon / picture items, the resource id
/// the item names. Rects and type bytes come from HectorGraphics `Ditl.decode`; the payload walk is the same record walk.
struct DialogItem {
    enum Kind: Equatable {
        case user, button, checkBox, radio
        /// `ctrlItem` + `resCtrl`: a `CNTL` resource (here: the prefs popups, `CNTL 1000/1001/1009`).
        case control(cntl: Int)
        case staticText, editText
        case icon(Int)
        case picture(pict: Int)
        case other(UInt8)
    }

    let number: Int
    let rect: CGRect
    let kind: Kind
    let enabled: Bool
    let text: String
}

/// A dialog's window template: `DLOG` (proc 1 = `dBoxProc` for every BTX dialog) or `ALRT`.
struct DialogTemplate {
    let id: Int
    let size: CGSize
    /// `DLOG`/`ALRT` positioning word: 0xa80a `alertPositionParentWindowScreen`, 0x700a `alertPositionMainScreen`.
    let position: UInt16
    let items: [DialogItem]
    /// `ALRT` only: the stage word (BTX: 0x5555 = every stage draws, bolds item 1, sounds `SysBeep` once).
    let alertStages: UInt16?
}

/// `CNTL` popup record (`popupMenuProc` 1008 + variation): value = title justification, min = `MENU` id, max = title width.
struct PopupControlTemplate {
    let title: String
    let titleWidth: Int
    let menuID: Int
}

/// Classic dialog resources read straight from the shipped `Bubble Trouble X.rsrc` (through `BTXGameData`).
enum BTXDialogResources {
    static func dialog(_ id: Int, data: BTXGameData) -> DialogTemplate? {
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
        return DialogTemplate(id: id, size: bounds.size, position: position, items: items, alertStages: nil)
    }

    static func alert(_ id: Int, data: BTXGameData) -> DialogTemplate? {
        guard let alrt = data.data(type: "ALRT", id: id), alrt.count >= 12,
              let bounds = Ditl.dlogBounds(alrt) else { return nil }
        let b = [UInt8](alrt)
        let ditlID = Int(Int16(bitPattern: UInt16(b[8]) << 8 | UInt16(b[9])))
        let stages = UInt16(b[10]) << 8 | UInt16(b[11])
        let position: UInt16 = b.count >= 14 ? UInt16(b[12]) << 8 | UInt16(b[13]) : 0
        guard let items = Self.items(ditl: ditlID, data: data) else { return nil }
        return DialogTemplate(id: id, size: bounds.size, position: position, items: items, alertStages: stages)
    }

    /// A `DITL`'s items, numbered from `firstNumber` (`AppendDITL` continues the dialog's numbering).
    static func items(ditl id: Int, data: BTXGameData, firstNumber: Int = 1) -> [DialogItem]? {
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
            out.append(DialogItem(number: firstNumber + item.number - 1, rect: item.rect, kind: kind,
                                  enabled: item.type & 0x80 == 0, text: text))
        }
        return out
    }

    static func popupControl(_ id: Int, data: BTXGameData) -> PopupControlTemplate? {
        guard let c = data.data(type: "CNTL", id: id), c.count >= 23 else { return nil }
        let b = [UInt8](c)
        func i16(_ o: Int) -> Int { Int(Int16(bitPattern: UInt16(b[o]) << 8 | UInt16(b[o + 1]))) }
        let titleLength = Int(b[22])
        guard 23 + titleLength <= b.count else { return nil }
        return PopupControlTemplate(title: macRoman(Array(b[23..<(23 + titleLength)])), titleWidth: i16(12),
                                    menuID: i16(14))
    }

    /// A `MENU`'s item titles (`"-"` / `"(-"` = separator, as the Menu Manager reads them).
    static func menuItems(_ id: Int, data: BTXGameData) -> [String] {
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

    /// MacRoman text with the Mac line break (CR) as a newline.
    static func macRoman(_ bytes: [UInt8]) -> String {
        (String(bytes: bytes, encoding: .macOSRoman) ?? "").replacingOccurrences(of: "\r", with: "\n")
    }

    /// The text as the original's C/Pascal buffers hold it: its MacRoman byte count (`strlen`).
    static func byteLength(_ s: String) -> Int {
        s.data(using: .macOSRoman, allowLossyConversion: true)?.count ?? s.utf8.count
    }

    /// `s` cut to its first `n` MacRoman bytes (`local_128 = 0` in `_PrefsDialog`'s new-set loop).
    static func truncated(_ s: String, bytes n: Int) -> String {
        guard let d = s.data(using: .macOSRoman, allowLossyConversion: true), d.count > n else { return s }
        return String(data: d.prefix(n), encoding: .macOSRoman) ?? s
    }

    /// An `RGBAImage` (0xAARRGGBB, top row first) as a `CGImage` (straight alpha).
    static func cgImage(_ image: RGBAImage) -> CGImage? {
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        for (i, p) in image.pixels.enumerated() {
            bytes[4 * i] = UInt8(p >> 16 & 0xff)
            bytes[4 * i + 1] = UInt8(p >> 8 & 0xff)
            bytes[4 * i + 2] = UInt8(p & 0xff)
            bytes[4 * i + 3] = UInt8(p >> 24)
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: image.width, height: image.height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}

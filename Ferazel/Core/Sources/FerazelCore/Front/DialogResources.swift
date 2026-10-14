import Foundation
import HectorResources

// R1 (docs/plans/2026-10-14-ferazel-phase3.md S2): Foundation-only parsers for the app fork's Dialog/Menu Manager
// templates — DLOG/ALRT, DITL, CNTL, MENU, MBAR (layouts: Inside Macintosh: Toolbox Essentials). Text is Mac Roman
// (`HectorResources.MacRoman`, via `BigEndianBytes.pascalString`). No drawing: O1 (prefs dialog model) and A1b
// (AppKit dialogs and menus) consume these. Reads resolve on the `.frontEnd` chain (Sprites → Sounds → Titles → app;
// plan Hazards), which is where the Dialog/Menu Manager would find them; every one of these lives in the app fork.
// A read past the end throws `WorldDataError.truncated`; an absent resource throws `WorldDataError.missing`.

/// A QuickDraw `Rect` as stored: top, left, bottom, right (big-endian i16 each).
public struct MacRect: Sendable, Equatable, Hashable {
    public var top: Int16
    public var left: Int16
    public var bottom: Int16
    public var right: Int16

    public init(top: Int16, left: Int16, bottom: Int16, right: Int16) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public var width: Int { Int(right) - Int(left) }
    public var height: Int { Int(bottom) - Int(top) }

    init(_ b: BigEndianBytes, at offset: Int) throws {
        self.init(top: try b.i16(offset), left: try b.i16(offset + 2),
                  bottom: try b.i16(offset + 4), right: try b.i16(offset + 6))
    }
}

private func loadResource(_ resources: FerazelResources, type: String, id: Int16) throws -> Resource {
    guard let r = resources.resource(type: type, id: id, chain: .frontEnd) else {
        throw WorldDataError.missing(type: type, id: id)
    }
    return r
}

/// A `DLOG` or `ALRT` template. DLOG = rect(8) procID(2) visible(1) pad(1) goAway(1) pad(1) refCon(4) itemsID(2)
/// title pstr [position word]; ALRT = rect(8) itemsID(2) stages(2) [position word] (ALRT 500/501: stages 0x4444;
/// position 0x300A for ALRT 500, 0x280A for ALRT 501).
public struct DialogTemplate: Sendable, Equatable {
    public enum Kind: Sendable, Equatable { case dialog, alert }

    public let kind: Kind
    public let id: Int16
    public let bounds: MacRect
    /// The `DITL` id.
    public let itemsID: Int16
    /// DLOG only (nil for ALRT): window definition id, visible, goAway, refCon, title.
    public let procID: Int16?
    public let visible: Bool?
    public let goAway: Bool?
    public let refCon: Int32?
    public let title: String?
    /// ALRT only (nil for DLOG): the stages word (four 4-bit stage fields) as stored.
    public let stages: UInt16?
    /// The optional trailing positioning word (System 7), nil when absent.
    public let position: UInt16?

    public init(type: String, id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: type, id: id)
        self.id = id
        bounds = try MacRect(b, at: 0)
        switch type {
        case "ALRT":
            kind = .alert
            itemsID = try b.i16(8)
            stages = try b.u16(10)
            procID = nil; visible = nil; goAway = nil; refCon = nil; title = nil
            position = b.count >= 14 ? try b.u16(12) : nil
        default:
            kind = .dialog
            procID = try b.i16(8)
            visible = try b.u8(10) != 0
            goAway = try b.u8(12) != 0
            refCon = Int32(bitPattern: try b.u32(14))
            itemsID = try b.i16(18)
            title = try b.pascalString(at: 20)
            stages = nil
            // The position word follows the title, word-aligned.
            var end = 21 + Int(try b.u8(20))
            if end % 2 != 0 { end += 1 }
            position = b.count >= end + 2 ? try b.u16(end) : nil
        }
    }

    /// `DLOG`/`ALRT <id>` from the app fork (`.frontEnd` chain).
    public static func load(from resources: FerazelResources, type: String, id: Int16) throws -> DialogTemplate {
        let r = try loadResource(resources, type: type, id: id)
        return try DialogTemplate(type: type, id: r.id, data: r.data)
    }
}

/// A `DITL`: a count−1 word, then per item placeholder(4) rect(8) type(1) length(1) payload, padded to even.
public struct DialogItemList: Sendable, Equatable {
    public enum Kind: Sendable, Equatable, Hashable {
        case userItem, helpItem, button, checkBox, radioButton, control, staticText, editText, icon, picture
        case other(UInt8)

        /// The type byte without the 0x80 disabled bit.
        public init(code: UInt8) {
            switch code {
            case 0: self = .userItem
            case 1: self = .helpItem
            case 4: self = .button          // ctrlItem + btnCtrl
            case 5: self = .checkBox        // ctrlItem + chkCtrl
            case 6: self = .radioButton     // ctrlItem + radCtrl
            case 7: self = .control         // ctrlItem + resCtrl
            case 8: self = .staticText
            case 16: self = .editText
            case 32: self = .icon
            case 64: self = .picture
            default: self = .other(code)
            }
        }

        var carriesText: Bool {
            switch self {
            case .button, .checkBox, .radioButton, .staticText, .editText: return true
            default: return false
            }
        }

        var carriesResourceID: Bool {
            switch self {
            case .control, .icon, .picture: return true
            default: return false
            }
        }
    }

    public struct Item: Sendable, Equatable {
        public let kind: Kind
        public let rect: MacRect
        /// The type byte's 0x80 bit.
        public let disabled: Bool
        /// Mac Roman text for button/check/radio/static/edit; nil otherwise.
        public let text: String?
        /// `CNTL`/`ICON`/`PICT` id for control/icon/picture; nil otherwise.
        public let resourceID: Int16?
        /// The payload bytes as stored (help items and unknown kinds keep theirs here).
        public let payload: [UInt8]
    }

    public let id: Int16
    /// Items in order; dialog item n is `items[n − 1]`.
    public let items: [Item]

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "DITL", id: id)
        self.id = id
        let count = Int(try b.i16(0)) + 1
        var offset = 2
        var items: [Item] = []
        for _ in 0..<max(count, 0) {
            let rect = try MacRect(b, at: offset + 4)
            let typeByte = try b.u8(offset + 12)
            let length = Int(try b.u8(offset + 13))
            let start = offset + 14
            if length > 0 { _ = try b.u8(start + length - 1) }
            let payload = Array(b.bytes[start..<(start + length)])
            let kind = Kind(code: typeByte & 0x7f)
            let text = kind.carriesText ? MacRoman.decode(payload) : nil
            let resID: Int16? = kind.carriesResourceID && length >= 2 ? try b.i16(start) : nil
            items.append(Item(kind: kind, rect: rect, disabled: typeByte & 0x80 != 0, text: text,
                              resourceID: resID, payload: payload))
            offset = start + length + (length % 2)
        }
        self.items = items
    }

    /// `DITL <id>` from the app fork (`.frontEnd` chain).
    public static func load(from resources: FerazelResources, id: Int16) throws -> DialogItemList {
        let r = try loadResource(resources, type: "DITL", id: id)
        return try DialogItemList(id: r.id, data: r.data)
    }
}

/// A `CNTL`: rect(8) value(2) visible(1) fill(1) max(2) min(2) procID(2) refCon(4) title pstr. For the popup
/// controls (procID 1008) the `min` field is the `MENU` id (CNTL 605 → MENU 601 on the shipped data).
public struct ControlTemplate: Sendable, Equatable {
    public let id: Int16
    public let bounds: MacRect
    public let value: Int16
    public let visible: Bool
    public let max: Int16
    public let min: Int16
    public let procID: Int16
    public let refCon: Int32
    public let title: String

    /// The popup menu's `MENU` id (the `min` field).
    public var menuID: Int16 { min }

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "CNTL", id: id)
        self.id = id
        bounds = try MacRect(b, at: 0)
        value = try b.i16(8)
        visible = try b.u8(10) != 0
        max = try b.i16(12)
        min = try b.i16(14)
        procID = try b.i16(16)
        refCon = Int32(bitPattern: try b.u32(18))
        title = try b.pascalString(at: 22)
    }

    /// `CNTL <id>` from the app fork (`.frontEnd` chain).
    public static func load(from resources: FerazelResources, id: Int16) throws -> ControlTemplate {
        let r = try loadResource(resources, type: "CNTL", id: id)
        return try ControlTemplate(id: r.id, data: r.data)
    }
}

/// A `MENU`: id(2) width(2) height(2) procID(2) filler(2) enableFlags(4) title pstr, then items — name pstr
/// (an empty name ends the list), icon(1) keyEquiv(1) mark(1) style(1).
public struct MenuTemplate: Sendable, Equatable {
    public struct Item: Sendable, Equatable {
        public let name: String
        public let icon: UInt8
        /// The ⌘ key as a one-character string; nil when the byte is 0.
        public let keyEquivalent: String?
        /// The mark character byte (0 = none).
        public let mark: UInt8
        /// The QuickDraw style bits.
        public let style: UInt8
    }

    public let id: Int16
    public let width: Int16
    public let height: Int16
    public let procID: Int16
    /// Bit 0 = the whole menu, bit n = item n (items past 31 are always enabled).
    public let enableFlags: UInt32
    /// The title pstr, MacRoman-decoded. MENU 128's title is the single byte 0x14 (the Apple-logo character, decoded
    /// U+0014); A1b recognises the Apple menu by it.
    public let title: String
    public let items: [Item]

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "MENU", id: id)
        self.id = try b.i16(0)
        width = try b.i16(2)
        height = try b.i16(4)
        procID = try b.i16(6)
        enableFlags = try b.u32(10)
        title = try b.pascalString(at: 14)
        var offset = 15 + Int(try b.u8(14))
        var items: [Item] = []
        while offset < b.count, try b.u8(offset) != 0 {
            let name = try b.pascalString(at: offset)
            offset += 1 + Int(try b.u8(offset))
            let key = try b.u8(offset + 1)
            items.append(Item(name: name, icon: try b.u8(offset),
                              keyEquivalent: key == 0 ? nil : MacRoman.decode([key]),
                              mark: try b.u8(offset + 2), style: try b.u8(offset + 3)))
            offset += 4
        }
        self.items = items
    }

    /// The menu's enable bit (bit 0).
    public var isEnabled: Bool { enableFlags & 1 != 0 }

    /// Item n's (1-based) enable bit; items past 31 are always enabled.
    public func isItemEnabled(_ n: Int) -> Bool {
        guard n >= 1, n <= 31 else { return n >= 1 }
        return enableFlags & (1 << UInt32(n)) != 0
    }

    /// `MENU <id>` from the app fork (`.frontEnd` chain).
    public static func load(from resources: FerazelResources, id: Int16) throws -> MenuTemplate {
        let r = try loadResource(resources, type: "MENU", id: id)
        return try MenuTemplate(id: r.id, data: r.data)
    }
}

/// An `MBAR`: count(2) then that many `MENU` ids.
public struct MenuBarTemplate: Sendable, Equatable {
    public let id: Int16
    public let menuIDs: [Int16]

    public init(id: Int16, data: Data) throws {
        let b = BigEndianBytes(data, type: "MBAR", id: id)
        self.id = id
        menuIDs = try b.i16Array(at: 2, count: Int(try b.u16(0)))
    }

    /// `MBAR <id>` from the app fork (`.frontEnd` chain).
    public static func load(from resources: FerazelResources, id: Int16) throws -> MenuBarTemplate {
        let r = try loadResource(resources, type: "MBAR", id: id)
        return try MenuBarTemplate(id: r.id, data: r.data)
    }
}

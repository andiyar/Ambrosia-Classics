import Foundation

// Phase 4 S6 DG (plan ruling 8; grounding C §2, §3): Foundation-only readers for the app fork's Dialog Manager
// templates — the resource map itself, `DLOG`, `DITL`, `CNTL`, `STR#`, `tab#` (layouts: Inside Macintosh: Toolbox
// Essentials; Appearance Manager for `tab#`). Text stays Mac Roman bytes (the dialog font is keyed by the byte; no
// `String.Encoding`). The shell hands Core the fork's resources as raw bytes (`FrontEndState.shellResources`); the
// tests read the committed `Resources/Deimos/Deimos Rising.rsrc` with `readFork`. Nothing here draws (DialogDraw.swift)
// and nothing traps: a short or absent resource throws.

/// Why a dialog resource did not read.
public enum DialogResourceError: Error, Equatable {
    /// The bytes are not a classic resource map.
    case notAResourceFile
    /// The resource is not in the set handed in.
    case missing(type: FourCC, id: Int16)
    /// A read past the end of the resource.
    case truncated(type: FourCC, id: Int16)
}

/// The resource map and the lookup.
public enum DialogResources {
    /// Every resource of a classic resource-fork image (header: data offset, map offset, data length, map length; map
    /// +24 type-list offset, +26 name-list offset; type list: count − 1, then type, count − 1, reference-list offset;
    /// references: id, name offset, attributes + 3-byte data offset, handle; data: a 4-byte length, then the bytes).
    ///
    /// Bounded by the fork's length: each type entry is read from its own 8 bytes and the fork can hold at most
    /// `count / 12` references, so a map that names more (type entries sharing one reference list, say) is refused
    /// rather than read over and over.
    public static func readFork(_ bytes: [UInt8]) throws -> [ShellResourceKey: [UInt8]] {
        let b = DialogBytes(bytes, FourCC(rawValue: 0), 0)
        guard bytes.count >= 16 else { throw DialogResourceError.notAResourceFile }
        do {
            let dataOff = Int(try b.u32(0)), mapOff = Int(try b.u32(4))
            let typeList = mapOff + Int(try b.u16(mapOff + 24))
            let types = (Int(try b.u16(typeList)) + 1) & 0xFFFF
            guard typeList + 2 + types * 8 <= bytes.count else { throw DialogResourceError.notAResourceFile }
            var room = bytes.count / 12                         // references the fork has room for
            var out: [ShellResourceKey: [UInt8]] = [:]
            for t in 0..<types {
                let e = typeList + 2 + t * 8
                let type = FourCC(rawValue: try b.u32(e))
                let count = Int(try b.u16(e + 4)) + 1
                let refs = typeList + Int(try b.u16(e + 6))
                room -= count
                guard room >= 0, refs + count * 12 <= bytes.count else { throw DialogResourceError.notAResourceFile }
                for k in 0..<count {
                    let r = refs + k * 12
                    let id = try b.i16(r)
                    let at = dataOff + Int(try b.u32(r + 4) & 0x00FF_FFFF)
                    let length = Int(try b.u32(at))
                    out[ShellResourceKey(type, id)] = try b.slice(at + 4, length)
                }
            }
            return out
        } catch {
            throw DialogResourceError.notAResourceFile
        }
    }

    /// The bytes of `type` `id`, or `missing`.
    public static func data(_ type: FourCC, _ id: Int16, in resources: [ShellResourceKey: [UInt8]]) throws -> [UInt8] {
        guard let d = resources[ShellResourceKey(type, id)] else { throw DialogResourceError.missing(type: type, id: id) }
        return d
    }

    static let dlog = FourCC(rawValue: 0x444C_4F47)     // 'DLOG'
    static let ditl = FourCC(rawValue: 0x4449_544C)     // 'DITL'
    static let cntl = FourCC(rawValue: 0x434E_544C)     // 'CNTL'
    static let strList = FourCC(rawValue: 0x5354_5223)  // 'STR#'
    static let tabList = FourCC(rawValue: 0x7461_6223)  // 'tab#'
}

/// Big-endian reads over one resource's bytes; a read past the end throws `truncated`.
struct DialogBytes {
    let b: [UInt8]
    let type: FourCC
    let id: Int16

    init(_ b: [UInt8], _ type: FourCC, _ id: Int16) {
        self.b = b
        self.type = type
        self.id = id
    }

    var count: Int { b.count }

    private func need(_ at: Int, _ n: Int) throws {
        guard at >= 0, n >= 0, at + n <= b.count else { throw DialogResourceError.truncated(type: type, id: id) }
    }

    func u8(_ at: Int) throws -> UInt8 { try need(at, 1); return b[at] }
    func u16(_ at: Int) throws -> UInt16 { try need(at, 2); return UInt16(b[at]) << 8 | UInt16(b[at + 1]) }
    func i16(_ at: Int) throws -> Int16 { Int16(bitPattern: try u16(at)) }
    func u32(_ at: Int) throws -> UInt32 {
        try need(at, 4)
        return UInt32(b[at]) << 24 | UInt32(b[at + 1]) << 16 | UInt32(b[at + 2]) << 8 | UInt32(b[at + 3])
    }
    func slice(_ at: Int, _ n: Int) throws -> [UInt8] { try need(at, n); return Array(b[at..<(at + n)]) }
    /// A Pascal string's bytes.
    func pascal(_ at: Int) throws -> [UInt8] { try slice(at + 1, Int(try u8(at))) }
    /// A QuickDraw `Rect`: top, left, bottom, right.
    func rect(_ at: Int) throws -> MacRect {
        MacRect(top: Int32(try i16(at)), left: Int32(try i16(at + 2)), bottom: Int32(try i16(at + 4)),
                right: Int32(try i16(at + 6)))
    }
}

/// A `DLOG`: rect(8) procID(2) visible(1) pad(1) goAway(1) pad(1) refCon(4) itemsID(2) title pstr, then (System 7)
/// the positioning word at the next even offset.
public struct DialogTemplate: Equatable, Sendable {
    public let id: Int16
    /// The window's content rect as stored (global coordinates on the original's screen).
    public let bounds: MacRect
    /// The window definition: 1 = `dBoxProc` (the modal frame, no title bar).
    public let procID: Int16
    public let visible: Bool
    public let goAway: Bool
    public let refCon: Int32
    /// The `DITL` id.
    public let itemsID: Int16
    public let title: [UInt8]
    /// 0x280A = centre on the main screen; nil when absent.
    public let position: UInt16?

    public init(bytes: [UInt8], id: Int16) throws {
        let b = DialogBytes(bytes, DialogResources.dlog, id)
        self.id = id
        bounds = try b.rect(0)
        procID = try b.i16(8)
        visible = try b.u8(10) != 0
        goAway = try b.u8(12) != 0
        refCon = Int32(bitPattern: try b.u32(14))
        itemsID = try b.i16(18)
        title = try b.pascal(20)
        var end = 21 + title.count
        if end % 2 != 0 { end += 1 }
        position = b.count >= end + 2 ? try b.u16(end) : nil
    }

    public static func load(_ id: Int16, from resources: [ShellResourceKey: [UInt8]]) throws -> DialogTemplate {
        try DialogTemplate(bytes: try DialogResources.data(DialogResources.dlog, id, in: resources), id: id)
    }
}

/// One `DITL` item.
public struct DialogItem: Equatable, Sendable {
    /// The item's type byte without the 0x80 disabled bit.
    public enum Kind: Equatable, Hashable, Sendable {
        case userItem, helpItem, button, checkBox, radioButton, control, staticText, editText, icon, picture
        case other(UInt8)

        init(code: UInt8) {
            switch code {
            case 0: self = .userItem
            case 1: self = .helpItem
            case 4: self = .button                  // ctrlItem + btnCtrl
            case 5: self = .checkBox                // ctrlItem + chkCtrl
            case 6: self = .radioButton             // ctrlItem + radCtrl
            case 7: self = .control                 // ctrlItem + resCtrl: a CNTL id
            case 8: self = .staticText
            case 16: self = .editText
            case 32: self = .icon
            case 64: self = .picture
            default: self = .other(code)
            }
        }
    }

    /// 1-based, as the Dialog Manager numbers items.
    public let number: Int
    public let kind: Kind
    /// The 0x80 bit clear: a click on the item is reported (`ModalDialog` returns it).
    public let enabled: Bool
    /// Local to the window's content: top, left, bottom, right.
    public let rect: MacRect
    /// The title or text (Mac Roman) of buttons, check boxes, radio buttons, static and edit text; empty otherwise.
    public let text: [UInt8]
    /// The resource the item names: `CNTL` (control), `ICON`/`cicn` (icon), `PICT` (picture), `HMnu`-style help ids.
    public let resourceID: Int16?
}

/// A `DITL`: a count − 1 word, then per item: placeholder(4) rect(8) type(1) length(1) data, padded to even.
public struct DialogItemList: Equatable, Sendable {
    public let id: Int16
    public let items: [DialogItem]

    public init(bytes: [UInt8], id: Int16) throws {
        let b = DialogBytes(bytes, DialogResources.ditl, id)
        self.id = id
        let count = Int(try b.i16(0)) + 1
        guard count >= 0 else { throw DialogResourceError.truncated(type: DialogResources.ditl, id: id) }
        var at = 2
        var items: [DialogItem] = []
        for n in stride(from: 1, through: count, by: 1) {
            let rect = try b.rect(at + 4)
            let type = try b.u8(at + 12)
            let length = Int(try b.u8(at + 13))
            let data = try b.slice(at + 14, length)
            let kind = DialogItem.Kind(code: type & 0x7F)
            var text: [UInt8] = []
            var res: Int16?
            switch kind {
            case .button, .checkBox, .radioButton, .staticText, .editText: text = data
            case .control, .icon, .picture, .helpItem:
                if data.count >= 2 { res = Int16(bitPattern: UInt16(data[0]) << 8 | UInt16(data[1])) }
            default: break
            }
            items.append(DialogItem(number: n, kind: kind, enabled: type & 0x80 == 0, rect: rect, text: text,
                                    resourceID: res))
            at += 14 + length + (length & 1)
        }
        self.items = items
    }

    public static func load(_ id: Int16, from resources: [ShellResourceKey: [UInt8]]) throws -> DialogItemList {
        try DialogItemList(bytes: try DialogResources.data(DialogResources.ditl, id, in: resources), id: id)
    }

    /// Item `number` (1-based); nil when the list has no such item.
    public subscript(number: Int) -> DialogItem? { items.indices.contains(number - 1) ? items[number - 1] : nil }
}

/// A `CNTL`: rect(8) value(2) visible(1) pad(1) max(2) min(2) procID(2) refCon(4) title pstr. (CNTL 191's value is
/// its `tab#` id, 6000; the group boxes CNTL 200–202 are proc 164 with their titles.)
public struct ControlTemplate: Equatable, Sendable {
    public let id: Int16
    public let rect: MacRect
    public let value: Int16
    public let visible: Bool
    public let max: Int16
    public let min: Int16
    public let procID: Int16
    public let refCon: Int32
    public let title: [UInt8]

    public init(bytes: [UInt8], id: Int16) throws {
        let b = DialogBytes(bytes, DialogResources.cntl, id)
        self.id = id
        rect = try b.rect(0)
        value = try b.i16(8)
        visible = try b.u8(10) != 0
        max = try b.i16(12)
        min = try b.i16(14)
        procID = try b.i16(16)
        refCon = Int32(bitPattern: try b.u32(18))
        title = try b.pascal(22)
    }

    public static func load(_ id: Int16, from resources: [ShellResourceKey: [UInt8]]) throws -> ControlTemplate {
        try ControlTemplate(bytes: try DialogResources.data(DialogResources.cntl, id, in: resources), id: id)
    }
}

/// A `STR#`: a count word, then that many Pascal strings.
public enum ResourceStringList {
    public static func parse(bytes: [UInt8], id: Int16) throws -> [[UInt8]] {
        let b = DialogBytes(bytes, DialogResources.strList, id)
        let count = Int(try b.u16(0))
        var at = 2
        var out: [[UInt8]] = []
        out.reserveCapacity(count)
        for _ in 0..<count {
            let s = try b.pascal(at)
            out.append(s)
            at += 1 + s.count
        }
        return out
    }

    public static func load(_ id: Int16, from resources: [ShellResourceKey: [UInt8]]) throws -> [[UInt8]] {
        try parse(bytes: try DialogResources.data(DialogResources.strList, id, in: resources), id: id)
    }
}

/// A `tab#` (the tab control's titles): version(2) count(2), then per tab: icon suite id(2), name pstr, 6 reserved
/// bytes (tab# 6000: "Player 1", "Player 2", both icon 0).
public struct TabList: Equatable, Sendable {
    public struct Tab: Equatable, Sendable {
        public let iconSuite: Int16
        public let name: [UInt8]
    }

    public let id: Int16
    public let tabs: [Tab]

    public init(bytes: [UInt8], id: Int16) throws {
        let b = DialogBytes(bytes, DialogResources.tabList, id)
        self.id = id
        let count = Int(try b.u16(2))
        var at = 4
        var tabs: [Tab] = []
        for _ in 0..<count {
            let icon = try b.i16(at)
            let name = try b.pascal(at + 2)
            tabs.append(Tab(iconSuite: icon, name: name))
            at += 2 + 1 + name.count + 6
        }
        self.tabs = tabs
    }

    public static func load(_ id: Int16, from resources: [ShellResourceKey: [UInt8]]) throws -> TabList {
        try TabList(bytes: try DialogResources.data(DialogResources.tabList, id, in: resources), id: id)
    }
}

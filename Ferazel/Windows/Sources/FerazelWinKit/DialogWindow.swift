import FerazelCore
import Foundation

// WF4a (D43 Ruling 4): one Dialog Manager window drawn inside the game picture — the Windows port of the Mac's
// `FerazelCarbonDialog` (`Ferazel/App/Dialogs/FerazelCarbonDialog.swift`, itself the transcription), adapted from BTX's
// `BTXWinKit/DialogWindow.swift` (BTX's package untouched). Foundation only: no SDL, no AppKit.

/// A dialog-local rect (top-left origin, y down), as `CGRect` is in the Mac's flipped views.
public struct DialogRect: Equatable, Hashable, Sendable {
    public var x: Int, y: Int, width: Int, height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public init(_ r: MacRect) { self.init(x: Int(r.left), y: Int(r.top), width: r.width, height: r.height) }

    public var maxX: Int { x + width }
    public var maxY: Int { y + height }

    /// `NSRect.contains`: the left / top edges in, the right / bottom out.
    public func contains(_ px: Int, _ py: Int) -> Bool { px >= x && px < maxX && py >= y && py < maxY }

    /// `InsetRect(dx, dy)` (negative = outset).
    public func insetBy(_ dx: Int, _ dy: Int) -> DialogRect {
        DialogRect(x: x + dx, y: y + dy, width: width - 2 * dx, height: height - 2 * dy)
    }
}

/// One dialog item as the Dialog Manager holds it: R1's `DialogItemList.Item`, numbered, its rect in content
/// coordinates (the Mac's `DialogItem`).
public struct DialogItem: Equatable, Sendable {
    public let number: Int
    public let item: DialogItemList.Item
    public var rect: DialogRect { DialogRect(item.rect) }
    public var enabled: Bool { !item.disabled }
}

extension String {
    /// Literal find-and-replace in pure Swift (Ruling 18; BTX `TextReplace.swift`): Foundation-on-Windows'
    /// replace-occurrences call traps on non-ASCII strings. Matching on Unicode scalars, left to right,
    /// non-overlapping — as Foundation's literal search over UTF-16 matches (a "\r" inside a "\r\n" grapheme is found).
    public func replacingEvery(_ target: String, with replacement: String) -> String {
        let needle = Array(target.unicodeScalars)
        guard !needle.isEmpty else { return self }
        let hay = Array(unicodeScalars)
        guard hay.count >= needle.count else { return self }
        var out = String.UnicodeScalarView()
        var i = 0
        var replaced = false
        while i < hay.count {
            if hay[i] == needle[0], i + needle.count <= hay.count, hay[i ..< i + needle.count].elementsEqual(needle) {
                out.append(contentsOf: replacement.unicodeScalars)
                i += needle.count
                replaced = true
            } else {
                out.append(hay[i])
                i += 1
            }
        }
        return replaced ? String(out) : self
    }
}

/// One `GetNewDialog(id)` (the `DLOG` + its `DITL`, R1's parsers) inside the game picture: the dBoxProc frame round
/// the DLOG rect, the `dctb` content colour, the items at their DITL rects, `ParamText` (`^0`…`^3`), the game's own
/// `FrameRoundRect` default rings, and `ModalDialog`'s standard filter (Return / Enter → the default item, its button
/// hilited 8 ticks first; no cancel item — Esc does nothing, as the Mac's `handleKeyDown`), push-button tracking
/// (`TrackControl`). Events reach it through `DialogSystem`, in canvas pixels.
@MainActor public final class DialogWindow {
    /// The dBoxProc frame's width outside the content rect (the Mac's `DialogRootView.frameWidth`).
    public static let frameWidth = 6

    public let template: DialogTemplate
    public private(set) var items: [DialogItem] = []
    /// `ParamText(^0, ^1, ^2, ^3)` at creation.
    public let params: [String]
    /// The `dctb`'s `wContentColor` as 0xRRGGBB (8-bit channels, the 16-bit value's high byte); 0xEEEEEE when absent
    /// (the Mac's `DialogRootView.content` default).
    public let contentRGB: UInt32
    /// The picture items' `PICT`s, as QuickDraw drew them under the current CLUT (R, G, B, A rows).
    public private(set) var pictures: [Int: (rgba: [UInt8], width: Int, height: Int)] = [:]
    /// The panel's top-left in canvas pixels (`DialogSystem` centres it, `show(over:)`).
    public internal(set) var originX = 0, originY = 0

    /// Item text after `ParamText` (CR → line end).
    private var texts: [Int: String] = [:]

    /// The standard filter's default item (the Dialog Manager's `aDefItem`, 1): Return / Enter press it.
    public var defaultItem: Int? = 1
    /// `ModalDialog` returned this item.
    public var itemHit: ((Int) -> Void)?
    /// The `FrameRoundRect` rings the game draws on the update event (`outlineDefault`).
    public private(set) var outlines: [Int] = []

    /// The flash: the button hilited and the TickCount it began (`Task.sleep(8 ticks)` on the Mac).
    public private(set) var flashItem: Int?
    private var flashStart: UInt32 = 0
    public var flashing: Bool { flashItem != nil }
    /// A press being tracked: the button, and whether the mouse is inside it now.
    public private(set) var tracking: (item: Int, inside: Bool)?

    /// Bumped on every visual change; `onChange` is told each time (`DialogSystem.revision`).
    public private(set) var revision = 0
    var onChange: (() -> Void)?

    /// `GetNewDialog(id)` from `resources`: nil when the DLOG or its DITL is missing (the original beeps or quits).
    init?(dialog id: Int16, resources: FerazelResources,
          picture: (Int16) -> (rgba: [UInt8], width: Int, height: Int)?, params: [String] = []) {
        guard let t = try? DialogTemplate.load(from: resources, type: "DLOG", id: id),
              let list = try? DialogItemList.load(from: resources, id: t.itemsID) else { return nil }
        template = t
        self.params = params
        contentRGB = Self.contentColor(dctb: resources.resource(type: "dctb", id: id, chain: .frontEnd)?.data)
            ?? 0xEEEEEE
        for (i, item) in list.items.enumerated() {
            let d = DialogItem(number: i + 1, item: item)
            items.append(d)
            if item.kind.carriesDialogText { texts[d.number] = Self.substitute(item.text ?? "", params: params) }
            if item.kind == .picture, let pid = item.resourceID, let p = picture(pid) { pictures[d.number] = p }
        }
    }

    /// The `dctb`'s part-0 colour: ctSeed(4) ctFlags(2) ctSize(2), then (part, r, g, b) words (the Mac's
    /// `contentColor(dctb:)`).
    static func contentColor(dctb: Data?) -> UInt32? {
        guard let d = dctb, d.count >= 8 else { return nil }
        let b = [UInt8](d)
        func u16(_ o: Int) -> UInt32 { UInt32(b[o]) << 8 | UInt32(b[o + 1]) }
        let n = Int(u16(6)) + 1
        for i in 0..<n {
            let o = 8 + 8 * i
            guard o + 8 <= b.count else { break }
            if u16(o) == 0 { return (u16(o + 2) >> 8) << 16 | (u16(o + 4) >> 8) << 8 | u16(o + 6) >> 8 }
        }
        return nil
    }

    /// `ParamText` as the Mac substitutes it: `^0`… by the params, the remaining of `^0`…`^3` by nothing, then the
    /// original's CR as a line end — with the pure-Swift replace (Ruling 18).
    static func substitute(_ s: String, params: [String]) -> String {
        var out = s
        for (i, p) in params.enumerated() { out = out.replacingEvery("^\(i)", with: p) }
        for i in min(params.count, 4)..<4 { out = out.replacingEvery("^\(i)", with: "") }
        return out.replacingEvery("\r", with: "\n")
    }

    private func touch() {
        revision &+= 1
        onChange?()
    }

    // MARK: Geometry

    /// The panel (frame included) in canvas pixels.
    public var frame: DialogRect {
        DialogRect(x: originX, y: originY, width: template.bounds.width + 2 * Self.frameWidth,
                   height: template.bounds.height + 2 * Self.frameWidth)
    }

    /// The content's top-left in canvas pixels (item rects are relative to it).
    public var contentX: Int { originX + Self.frameWidth }
    public var contentY: Int { originY + Self.frameWidth }

    public func item(_ n: Int) -> DialogItem? { items.first { $0.number == n } }

    /// The item's text after `ParamText` (buttons and static text).
    public func text(_ n: Int) -> String { texts[n] ?? "" }

    /// `FrameRoundRect` round `item` on every update (`.ConfirmAbortGameDialog`, `.GenericMessage`).
    func outlineDefault(_ item: Int) {
        outlines.append(item)
        touch()
    }

    /// The button is drawn hilited (inverted): flashing, or pressed with the mouse inside.
    public func isHighlighted(_ n: Int) -> Bool {
        flashItem == n || (tracking.map { $0.item == n && $0.inside } ?? false)
    }

    // MARK: Hits, the flash

    private func hit(_ item: Int) {
        guard !flashing else { return }
        itemHit?(item)
    }

    /// The standard filter's Return / Enter: the button hilited, 8 ticks, unhilited, then the hit (`flash(_:)`).
    func flash(_ item: Int, now: UInt32) {
        guard !flashing else { return }
        guard self.item(item)?.item.kind == .button else { hit(item); return }
        flashItem = item
        flashStart = now
        touch()
    }

    /// TickCount `now`: the flash ends 8 ticks after it began.
    func tick(now: UInt32) {
        guard let f = flashItem, now &- flashStart >= 8 else { return }
        flashItem = nil
        touch()
        hit(f)
    }

    // MARK: Keys

    /// `ModalDialog`'s key handling (`handleKeyDown`): nothing while it flashes or a button is pressed; Return /
    /// Enter without ⌘ → the default item through the flash; every other key does nothing (no filter, no TextEdit
    /// field). `char` is the event record's character code.
    func handleKey(char: UInt8, command: Bool, now: UInt32) {
        guard !flashing, tracking == nil else { return }
        if !command, char == 0x0d || char == 0x03, let d = defaultItem { flash(d, now: now) }
    }

    /// The event record's character code for the keys the standard filter reads (Return 0x0d, keypad Enter 0x03,
    /// Esc 0x1b); 0 for the rest (no dialog of these reads another).
    static func charCode(keyCode: UInt16) -> UInt8 {
        switch keyCode {
        case 0x24: 0x0d
        case 0x4C: 0x03
        case 0x35: 0x1b
        default: 0
        }
    }

    // MARK: Mouse (content coordinates)

    /// The button a press at (x, y) tracks: the topmost enabled button whose rect holds it (static text and pictures
    /// take no click — `hitTest` nil on the Mac).
    private func button(at x: Int, _ y: Int) -> DialogItem? {
        items.last { $0.item.kind == .button && $0.enabled && $0.rect.contains(x, y) }
    }

    /// A press inside the panel: a button is tracked (hilited while the mouse is inside), anything else does nothing;
    /// while it flashes the press is eaten.
    func mouseDown(_ x: Int, _ y: Int) {
        guard !flashing, tracking == nil, let b = button(at: x, y) else { return }
        tracking = (b.number, true)
        touch()
    }

    func mouseMoved(_ x: Int, _ y: Int) {
        guard let t = tracking, let r = item(t.item)?.rect else { return }
        let inside = r.contains(x, y)
        if inside != t.inside {
            tracking = (t.item, inside)
            touch()
        }
    }

    /// The release: unhilited; inside the button it is the hit (`TrackControl` true).
    func mouseUp(_ x: Int, _ y: Int) {
        mouseMoved(x, y)
        guard let t = tracking else { return }
        tracking = nil
        touch()
        if t.inside { hit(t.item) }
    }
}

extension DialogItemList.Kind {
    /// Items whose text `ParamText` reaches and the dialog draws (buttons, check boxes, radios, static and edit text).
    var carriesDialogText: Bool {
        switch self {
        case .button, .checkBox, .radioButton, .staticText, .editText: true
        default: false
        }
    }
}

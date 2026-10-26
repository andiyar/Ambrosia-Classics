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

/// A key event as a `ModalFilterProc` sees it (the event record; the Mac's `DialogKey`): the character code
/// (`message & 0xff`), the virtual key code (`message >> 8 & 0xff`), the modifiers word (`cmdKey` 0x100, `shiftKey`
/// 0x200, `alphaLock` 0x400, `optionKey` 0x800, `controlKey` 0x1000; `btnState` 0x80 set while the button is UP) and
/// whether it is an auto-key.
public struct DialogKeyEvent: Equatable, Sendable {
    public let char: UInt8
    public let keyCode: Int
    public let modifiers: UInt16
    public let isRepeat: Bool

    public init(char: UInt8, keyCode: Int, modifiers: UInt16, isRepeat: Bool) {
        self.char = char
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isRepeat = isRepeat
    }

    /// The event record's modifiers word for `m` (Ctrl = ⌘, Alt = ⌥, the Windows key = ⌃, D18.5) and the button.
    public static func modifiers(_ m: WinModifiers, buttonDown: Bool) -> UInt16 {
        var w: UInt16 = buttonDown ? 0 : 0x80
        if m.contains(.command) { w |= 0x100 }
        if m.contains(.shift) { w |= 0x200 }
        if m.contains(.capsLock) { w |= 0x400 }
        if m.contains(.option) { w |= 0x800 }
        if m.contains(.control) { w |= 0x1000 }
        return w
    }
}

/// A popup's menu while it is open (`PopUpMenuSelect`, the Mac's `NSMenu.popUp`), in content coordinates.
public struct DialogPopupMenu: Equatable, Sendable {
    public let item: Int
    public let rect: DialogRect
    /// One row per menu item (0-based).
    public let rows: [DialogRect]
    public internal(set) var highlighted: Int?
    /// Opened by a press released on the popup itself: it stays up until the next click.
    var sticky = false
    /// Where the press that opened it was, until the mouse moves away from it.
    var press: (x: Int, y: Int)?

    public static func == (a: Self, b: Self) -> Bool {
        a.item == b.item && a.rect == b.rect && a.rows == b.rows && a.highlighted == b.highlighted
            && a.sticky == b.sticky && a.press?.x == b.press?.x && a.press?.y == b.press?.y
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
    private let resources: FerazelResources
    private let picture: (Int16) -> (rgba: [UInt8], width: Int, height: Int)?

    // WF4b: the Options dialog's controls (`PrefsDialogView` / `FerazelCarbonDialog` on the Mac).

    /// Control values (`SetControlValue`): a check box 0 / 1, a popup its 1-based item.
    private var values: [Int: Int] = [:]
    /// A popup's `MENU` item names (its `CNTL`'s menu).
    public private(set) var popupTitles: [Int: [String]] = [:]
    private var hidden: Set<Int> = []
    /// `HiliteControl(255)` / the disabled bit (`setActive(_, false)`).
    private var inactive: Set<Int> = []
    /// The edit item with TextEdit's selection (`SelectDialogItemText(item, 0, 0x7fff)`).
    public private(set) var selected: Int?
    /// TextEdit's insertion point (an empty selected item shows it, blinking).
    public var caretVisible = true { didSet { if caretVisible != oldValue { touch() } } }
    /// The edit items' selection colour (`HiliteColor`), 0xRRGGBB.
    public var hiliteRGB: UInt32 = 0x7575FF
    /// User items drawn by `.DrawGreyOutline` (Options' item 5).
    public private(set) var greyOutlines: [Int] = []
    /// Buttons hilited for good (`HiliteControl(item, 1)`).
    private var hilited: Set<Int> = []
    /// The popup menu open, if any.
    public private(set) var menu: DialogPopupMenu?
    /// The `ModalFilterProc` for keyDown / autoKey: true = handled (nil: the standard filter only).
    var keyFilter: ((DialogKeyEvent) -> Bool)?
    /// Called once per tick while this dialog is frontmost (the filter's null events).
    var nullEvent: (() -> Void)?
    /// A dialog run by its own clock (the credits): every mouse event is the dialog's, nothing is tracked, nothing
    /// beeps at the press — its loop reads `Button()` and the pointer itself.
    public internal(set) var takesAllClicks = false
    /// The pointer in content coordinates, the button, and a press not yet seen by `Button()` (the credits' loop).
    public internal(set) var pointer: (x: Int, y: Int)?
    public internal(set) var buttonDown = false
    var pressSeen: (x: Int, y: Int)?
    /// The content's pixels when the dialog paints them itself (the credits' persistent window): drawn instead of
    /// the items.
    var canvas: DialogRenderer.Image?

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
          picture: @escaping (Int16) -> (rgba: [UInt8], width: Int, height: Int)?, params: [String] = []) {
        guard let t = try? DialogTemplate.load(from: resources, type: "DLOG", id: id),
              let list = try? DialogItemList.load(from: resources, id: t.itemsID) else { return nil }
        template = t
        self.params = params
        self.resources = resources
        self.picture = picture
        contentRGB = Self.contentColor(dctb: resources.resource(type: "dctb", id: id, chain: .frontEnd)?.data)
            ?? 0xEEEEEE
        append(list)
    }

    /// `AppendDITL(dialog, ditl, overlayDITL)`: the items keep their own rects, numbered after the dialog's; a
    /// popup's titles and initial value from its `CNTL` → `MENU` (value `max(1, CNTL value)`).
    func append(_ list: DialogItemList) {
        let first = items.count + 1
        for (i, item) in list.items.enumerated() {
            let d = DialogItem(number: first + i, item: item)
            items.append(d)
            if item.kind.carriesDialogText { texts[d.number] = Self.substitute(item.text ?? "", params: params) }
            if item.kind == .picture, let pid = item.resourceID, let p = picture(pid) { pictures[d.number] = p }
            if item.kind == .control, let cid = item.resourceID,
               let c = try? ControlTemplate.load(from: resources, id: cid),
               let m = try? MenuTemplate.load(from: resources, id: c.menuID) {
                popupTitles[d.number] = m.items.map(\.name)
                values[d.number] = max(1, Int(c.value))
            }
        }
        touch()
    }

    /// `ShortenDITL` to `count` items.
    func shorten(to count: Int) {
        while items.count > count, let last = items.popLast() {
            let n = last.number
            texts[n] = nil
            pictures[n] = nil
            values[n] = nil
            popupTitles[n] = nil
            hidden.remove(n)
            inactive.remove(n)
            hilited.remove(n)
            if selected == n { selected = nil }
            if menu?.item == n { menu = nil }
            if tracking?.item == n { tracking = nil }
        }
        touch()
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

    // MARK: Values, text, visibility (WF4b)

    /// `GetControlValue` (0 when the item has none).
    public func value(_ n: Int) -> Int { values[n] ?? 0 }

    /// `SetControlValue` on a check box, radio or popup.
    func setValue(_ n: Int, _ v: Int) {
        guard let k = item(n)?.item.kind, k == .checkBox || k == .radioButton || k == .control, values[n] != v
        else { return }
        values[n] = v
        touch()
    }

    /// `SetDialogItemText` (static and edit text).
    func setText(_ n: Int, _ s: String) {
        guard let k = item(n)?.item.kind, k == .staticText || k == .editText, texts[n] != s else { return }
        texts[n] = s
        touch()
    }

    /// `SelectDialogItemText(item, 0, 0x7fff)` — the TextEdit focus there (nil: none).
    func select(_ n: Int?) {
        let target = n.flatMap { item($0)?.item.kind == .editText ? $0 : nil }
        guard target != selected else { return }
        selected = target
        touch()
    }

    /// `ShowDialogItem` / `HideDialogItem`.
    func setHidden(_ n: Int, _ isHidden: Bool) {
        guard self.isHidden(n) != isHidden else { return }
        if isHidden { hidden.insert(n) } else { hidden.remove(n) }
        touch()
    }

    public func isHidden(_ n: Int) -> Bool { hidden.contains(n) }

    /// `HiliteControl(0 / 255)` and the item's disabled bit (`.UpdateDisabledItems`): an inactive control is drawn
    /// dimmed and takes no click.
    func setActive(_ n: Int, _ active: Bool) {
        guard isActive(n) != active else { return }
        if active { inactive.remove(n) } else { inactive.insert(n) }
        touch()
    }

    public func isActive(_ n: Int) -> Bool { !inactive.contains(n) }

    /// The item takes clicks: its DITL enable bit and not deactivated (the Mac's `view.enabled`).
    func takesClicks(_ n: Int) -> Bool { (item(n)?.enabled ?? false) && isActive(n) }

    /// `.DrawGreyOutline` as `item`'s user-item proc.
    func greyOutline(_ n: Int) {
        greyOutlines.append(n)
        touch()
    }

    /// `HiliteControl(item, 1)` for the rest of the dialog's life (the Options filter's Return / Esc).
    func hilite(_ n: Int) {
        guard hilited.insert(n).inserted else { return }
        touch()
    }

    /// A check box / radio pressed with the mouse inside (drawn with the 2-px frame).
    public func isPressed(_ n: Int) -> Bool { tracking.map { $0.item == n && $0.inside } ?? false }

    /// Repaints (`InvalWindowRect`): the caller changed `canvas`'s pixels in place.
    func invalidate() { touch() }

    /// The pad's Return / Esc reach only a plain message (the Mac's `padKeyPanel`): not Options (its key capture),
    /// not Credits (closed by a click) — D37.
    var takesPadKeys: Bool { keyFilter == nil && !takesAllClicks && nullEvent == nil }

    /// `FrameRoundRect` round `item` on every update (`.ConfirmAbortGameDialog`, `.GenericMessage`).
    func outlineDefault(_ item: Int) {
        outlines.append(item)
        touch()
    }

    /// The button is drawn hilited (inverted): flashing, or pressed with the mouse inside.
    public func isHighlighted(_ n: Int) -> Bool {
        flashItem == n || hilited.contains(n) || (tracking.map { $0.item == n && $0.inside } ?? false)
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

    /// `ModalDialog`'s key handling (`handleKeyDown`): nothing while it flashes or a control is pressed; an open
    /// popup menu takes the key (Esc closes it); then the filter (`keyFilter`, Options); then the standard filter:
    /// Return / Enter without ⌘ → the default item through the flash. Every other key does nothing (no TextEdit
    /// field edits here: Options' key fields change only through its filter).
    func handleKey(_ key: DialogKeyEvent, now: UInt32) {
        guard !flashing, tracking == nil else { return }
        if menu != nil {
            if key.char == 0x1b { closeMenu() }
            return
        }
        if let f = keyFilter, f(key) { return }
        if key.modifiers & 0x100 == 0, key.char == 0x0d || key.char == 0x03, let d = defaultItem { flash(d, now: now) }
    }

    /// The event record's character code for the keys the filters read (Return 0x0d, keypad Enter 0x03, Esc 0x1b,
    /// the period 0x2e of ⌘.); 0 for the rest (Options takes the key code, no dialog reads another character).
    static func charCode(keyCode: UInt16) -> UInt8 {
        switch keyCode {
        case 0x24: 0x0d
        case 0x4C: 0x03
        case 0x35: 0x1b
        case 0x2F: 0x2e
        default: 0
        }
    }

    // MARK: Mouse (content coordinates)

    /// The item a press at (x, y) goes to, as the Mac's views hit-test front to back: hidden items, static text and
    /// pictures (and disabled user items) pass the click on; an edit item's view is its rect outset by 4. Nil = none.
    private func clickTarget(_ x: Int, _ y: Int) -> DialogItem? {
        for d in items.reversed() where !hidden.contains(d.number) {
            switch d.item.kind {
            case .staticText, .picture: continue
            case .userItem, .helpItem, .icon, .other: if !d.enabled { continue }
            default: break
            }
            let r = d.item.kind == .editText ? d.rect.insetBy(-4, -4) : d.rect
            if r.contains(x, y) { return d }
        }
        return nil
    }

    /// A press inside the panel (or on its open menu): with a menu open, on a row it tracks (chosen on release),
    /// elsewhere it closes the menu; a button, check box or radio is tracked (`TrackControl`); a popup opens its
    /// menu; an edit item or an enabled user item is hit at once (the Mac views' `mouseDown`); while it flashes the
    /// press is eaten.
    func mouseDown(_ x: Int, _ y: Int) {
        guard !flashing, tracking == nil else { return }
        if var m = menu {
            if m.rect.contains(x, y) {
                m.highlighted = row(in: m, x, y)
                m.sticky = false
                m.press = nil
                menu = m
                touch()
            } else {
                closeMenu()
            }
            return
        }
        guard let d = clickTarget(x, y), takesClicks(d.number) else { return }
        switch d.item.kind {
        case .button, .checkBox, .radioButton:
            tracking = (d.number, true)
            touch()
        case .control:
            openMenu(d, x, y)
        default:
            hit(d.number)
        }
    }

    func mouseMoved(_ x: Int, _ y: Int) {
        if var m = menu {
            if let p = m.press, p.x == x, p.y == y { return }
            m.press = nil
            let r = row(in: m, x, y)
            if r != m.highlighted || m != menu {
                m.highlighted = r
                menu = m
                touch()
            }
            return
        }
        guard let t = tracking, let r = item(t.item)?.rect else { return }
        let inside = r.contains(x, y)
        if inside != t.inside {
            tracking = (t.item, inside)
            touch()
        }
    }

    /// The release: a tracked control unhilited, a hit when inside (`TrackControl` true — the Dialog Manager does not
    /// toggle a check box: the game sets its value); on a menu row the popup takes that value and is hit; released
    /// on the popup that opened it, the menu stays up; anywhere else it closes.
    func mouseUp(_ x: Int, _ y: Int) {
        mouseMoved(x, y)
        if var m = menu {
            if let r = m.highlighted {
                closeMenu()
                values[m.item] = r + 1
                touch()
                hit(m.item)
            } else if !m.sticky, let d = item(m.item), d.rect.contains(x, y) {
                m.sticky = true
                menu = m
            } else {
                closeMenu()
            }
            return
        }
        guard let t = tracking else { return }
        tracking = nil
        touch()
        if t.inside { hit(t.item) }
    }

    // MARK: Popup menus

    /// The menu's row height, its top and bottom margin, the text's left inset and the check mark's column.
    public static let menuRowHeight = 18, menuMargin = 4, menuTextInset = 18

    /// `PopUpMenuSelect` as the Mac's `NSMenu.popUp(positioning: current, at: (0, h − 2))`: the current item's row over
    /// the popup's box, at least the box's width, kept inside the 640×480 canvas.
    private func openMenu(_ d: DialogItem, _ x: Int, _ y: Int) {
        guard let titles = popupTitles[d.number], !titles.isEmpty else { return }
        let widest = titles.map { Int(measure($0).rounded(.up)) }.max() ?? 0
        let width = max(d.rect.width, widest + Self.menuTextInset + 16)
        let height = titles.count * Self.menuRowHeight + 2 * Self.menuMargin
        let current = max(0, min(value(d.number) - 1, titles.count - 1))
        var mx = d.rect.x
        var my = d.rect.y + (d.rect.height - Self.menuRowHeight) / 2 - (Self.menuMargin + current * Self.menuRowHeight)
        mx = min(max(mx, -contentX), WinCanvas.width - contentX - width)
        my = min(max(my, -contentY), WinCanvas.height - contentY - height)
        let rows = titles.indices.map {
            DialogRect(x: mx, y: my + Self.menuMargin + $0 * Self.menuRowHeight, width: width, height: Self.menuRowHeight)
        }
        menu = DialogPopupMenu(item: d.number, rect: DialogRect(x: mx, y: my, width: width, height: height), rows: rows,
                               highlighted: nil, sticky: false, press: (x, y))
        touch()
    }

    private func closeMenu() {
        menu = nil
        touch()
    }

    private func row(in m: DialogPopupMenu, _ x: Int, _ y: Int) -> Int? {
        guard m.rect.contains(x, y) else { return nil }
        return m.rows.firstIndex { $0.contains(x, y) }
    }

    /// The width of a string in the dialog face (set by `DialogSystem` from its renderer).
    var measure: (String) -> Double = { Double($0.count * 7) }

    /// (x, y) — canvas pixels — lies on the panel or on its open menu.
    func containsCanvas(_ x: Int, _ y: Int) -> Bool {
        if frame.contains(x, y) { return true }
        if let m = menu, m.rect.contains(x - contentX, y - contentY) { return true }
        return false
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

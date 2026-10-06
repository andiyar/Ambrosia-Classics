import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import HectorResources

/// A key press as the host hands it to the dialogs (W6's own event parameter — no dependency on the driver's event
/// type): the Mac virtual key code (`kVK_*`, as HectorSDL maps physical US/ANSI keys, D18.5), the text the key typed
/// (layout-aware when the host has it — SDL text input — else empty: the US layout is assumed from the key code), and
/// the modifiers (Ctrl on Windows arrives as `command`, D15.3).
public struct DialogKeyEvent: Equatable, Sendable {
    public var keyCode: UInt16
    public var characters: String
    public var command: Bool
    public var shift: Bool
    public var option: Bool
    public var control: Bool

    public init(keyCode: UInt16, characters: String = "", command: Bool = false, shift: Bool = false,
                option: Bool = false, control: Bool = false) {
        self.keyCode = keyCode
        self.characters = characters
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
    }

    /// True for a key that types a printable character on the US layout — a host with layout-aware text input pairs
    /// such a key with the text it produces before calling `DialogSystem.keyDown`; every other key goes at once.
    public static func typesText(keyCode: UInt16) -> Bool {
        DialogKey.controlChars[keyCode] == nil && DialogKey.usLayout[keyCode] != nil
    }
}

/// A key event as a Carbon `ModalFilterProc` sees it — the port of the Mac app's `DialogKey`: the event record's
/// `charCode` (`message & 0xff`, MacRoman), its virtual key code, and whether ⌘ (Ctrl on Windows) was down.
public struct DialogKey: Equatable, Sendable {
    public let char: UInt8
    public let keyCode: UInt16
    public let command: Bool

    public init(char: UInt8, keyCode: UInt16, command: Bool) {
        self.char = char
        self.keyCode = keyCode
        self.command = command
    }

    /// The classic `charCode` the Mac's Event Manager put in the record: function keys by their key code (arrows
    /// 0x1c–0x1f, Delete 0x08, Forward Delete 0x7f, Return 0x0d, Enter 0x03, Esc 0x1b, Tab 0x09, Home 0x01, End 0x04,
    /// Page Up/Down 0x0b/0x0c, Help 0x05, F-keys 0x10); otherwise the typed character's MacRoman byte (0 when MacRoman
    /// has none), from `characters` or — when the host gave none — from the US layout.
    public init(_ e: DialogKeyEvent) {
        keyCode = e.keyCode
        command = e.command
        if let c = Self.controlChars[e.keyCode] {
            char = c
        } else if let scalar = e.characters.unicodeScalars.first {
            if scalar.value < 0x80 {
                char = UInt8(scalar.value)
            } else {
                char = MacRoman.encode(String(Character(scalar)), lossy: false)?.first ?? 0
            }
        } else if let pair = Self.usLayout[e.keyCode] {
            char = e.shift ? pair.shifted : pair.plain
        } else {
            char = 0
        }
    }

    /// ⌘ + the char upper-cased as the filters do (`c + 0x9f < 0x1a` → `c − 0x20`).
    public var commandUppercased: UInt8 { char &+ 0x9f < 0x1a ? char &- 0x20 : char }

    static let controlChars: [UInt16: UInt8] = {
        var m: [UInt16: UInt8] = [0x24: 0x0d, 0x4c: 0x03, 0x35: 0x1b, 0x33: 0x08, 0x75: 0x7f, 0x30: 0x09,
                                  0x7b: 0x1c, 0x7c: 0x1d, 0x7e: 0x1e, 0x7d: 0x1f, 0x73: 0x01, 0x77: 0x04,
                                  0x74: 0x0b, 0x79: 0x0c, 0x72: 0x05, 0x47: 0x1b]
        // F1–F15.
        for k: UInt16 in [0x7a, 0x78, 0x63, 0x76, 0x60, 0x61, 0x62, 0x64, 0x65, 0x6d, 0x67, 0x6f, 0x69, 0x6b, 0x71] {
            m[k] = 0x10
        }
        return m
    }()

    /// US/ANSI layout: key code → (unshifted, shifted) ASCII.
    static let usLayout: [UInt16: (plain: UInt8, shifted: UInt8)] = {
        let rows: [(UInt16, String, String)] = [
            (0x00, "a", "A"), (0x01, "s", "S"), (0x02, "d", "D"), (0x03, "f", "F"), (0x04, "h", "H"),
            (0x05, "g", "G"), (0x06, "z", "Z"), (0x07, "x", "X"), (0x08, "c", "C"), (0x09, "v", "V"),
            (0x0b, "b", "B"), (0x0c, "q", "Q"), (0x0d, "w", "W"), (0x0e, "e", "E"), (0x0f, "r", "R"),
            (0x10, "y", "Y"), (0x11, "t", "T"), (0x12, "1", "!"), (0x13, "2", "@"), (0x14, "3", "#"),
            (0x15, "4", "$"), (0x16, "6", "^"), (0x17, "5", "%"), (0x18, "=", "+"), (0x19, "9", "("),
            (0x1a, "7", "&"), (0x1b, "-", "_"), (0x1c, "8", "*"), (0x1d, "0", ")"), (0x1e, "]", "}"),
            (0x1f, "o", "O"), (0x20, "u", "U"), (0x21, "[", "{"), (0x22, "i", "I"), (0x23, "p", "P"),
            (0x25, "l", "L"), (0x26, "j", "J"), (0x27, "'", "\""), (0x28, "k", "K"), (0x29, ";", ":"),
            (0x2a, "\\", "|"), (0x2b, ",", "<"), (0x2c, "/", "?"), (0x2d, "n", "N"), (0x2e, "m", "M"),
            (0x2f, ".", ">"), (0x31, " ", " "), (0x32, "`", "~"),
            (0x41, ".", "."), (0x43, "*", "*"), (0x45, "+", "+"), (0x4b, "/", "/"), (0x4e, "-", "-"),
            (0x51, "=", "="), (0x52, "0", "0"), (0x53, "1", "1"), (0x54, "2", "2"), (0x55, "3", "3"),
            (0x56, "4", "4"), (0x57, "5", "5"), (0x58, "6", "6"), (0x59, "7", "7"), (0x5b, "8", "8"),
            (0x5c, "9", "9"),
        ]
        var m: [UInt16: (plain: UInt8, shifted: UInt8)] = [:]
        for (k, p, s) in rows { m[k] = (p.utf8.first!, s.utf8.first!) }
        return m
    }()
}

/// One Carbon dialog built from its `DLOG`/`ALRT` + `DITL`, drawn inside the game window — the Windows port of the
/// Mac app's `CarbonDialog` (`BubbleTroubleX/App/BTXCarbonDialog.swift`): items in dialog coordinates, `ParamText`
/// substitution, `SetDialogDefaultItem` / `SetDialogCancelItem`, a modal filter for keys, `_FlashMyDialogItem` (button
/// hilited 8 ticks, then the hit), `AppendDITL` / `ShortenDITL`, show / hide / activate items, control values — and,
/// where AppKit did it for the Mac, the controls themselves: push-button / checkbox tracking, a single-line TextEdit
/// field (caret, selection, typing, Delete, arrows, Tab), popup menus. Events reach it through `DialogSystem`.
public final class DialogWindow {
    public let template: DialogTemplate
    public private(set) var items: [DialogItem] = []
    /// `ParamText(^0, ^1, ^2, ^3)` at creation.
    public let params: [String]
    /// The dialog's top-left in canvas coordinates (`DialogSystem` places it).
    public internal(set) var originX = 0, originY = 0
    /// The canvas the dialog sits on (popup menus stay inside it).
    var canvasWidth = DialogSystem.canvasWidth, canvasHeight = DialogSystem.canvasHeight

    private let data: BTXGameData?
    private let art: ArtBank?
    /// Item text (titles, static and edit text) after `ParamText` and `SetDialogItemText`.
    private var texts: [Int: String] = [:]
    /// Control values (`GetControlValue`): checkbox 0/1, popup 1-based item.
    private var values: [Int: Int] = [:]
    private var hidden: Set<Int> = []
    private var inactive: Set<Int> = []
    /// Popup controls: their `CNTL` and current menu titles.
    private(set) var popups: [Int: (control: DialogPopupTemplate, titles: [String])] = [:]
    private(set) var pictures: [Int: RGBAImage] = [:]

    /// `SetDialogDefaultItem`: drawn as the default button; Return / Enter press it when the filter lets the key through.
    public var defaultItem: Int? { didSet { touch() } }
    /// `SetDialogCancelItem`: Esc / ⌘. press it when the filter lets the key through.
    public var cancelItem: Int?
    /// The `ModalFilterProc` for keyDown / autoKey: true = handled (the event goes no further).
    public var keyFilter: ((DialogKey) -> Bool)?
    /// Called once per tick while this dialog is frontmost (the filter's null events).
    public var nullEvent: (() -> Void)?
    /// `ModalDialog` returned this item.
    public var itemHit: ((Int) -> Void)?
    /// `_WaitUntilKeyOrMousePress` dialogs (DLOG 290/291): any key or click anywhere ends it.
    public var endsOnAnyPress = false

    /// `_FlashMyDialogItem`: the button hilited and the ticks left (`Delay(8)` blocks everything).
    public private(set) var flashItem: Int?
    private var flashTicks = 0
    public var flashing: Bool { flashItem != nil }

    /// `_OutlineItem` rings (drawn on every update).
    public private(set) var outlines: [Int] = []
    /// 1-px frames painted by the app on update (`_TouchUpPrefsDialog`), colour 0xRRGGBB.
    var frames: [(rect: DialogRect, rgb: UInt32)] = []
    /// Images plotted over the items by the app (`PlotCIconHandle` — the prefs area icons), `darkened` =
    /// `kTransformSelected`.
    var overlays: [(rect: DialogRect, image: RGBAImage, darkened: Bool)] = [] { didSet { touch() } }
    /// `NoteAlert` / `StopAlert`: the icon at (20, 10), 32×32.
    private(set) var alertIcon: RGBAImage?

    // TextEdit state.
    public private(set) var focusedEditItem: Int?
    private(set) var selStart = 0, selEnd = 0
    /// Ticks since the caret last moved (it blinks on `caretPeriod` ticks, then off as long).
    private(set) var caretTicks = 0
    static let caretPeriod = 32
    /// The field's horizontal scroll (px) so the caret stays visible.
    var scroll: [Int: Int] = [:]

    /// The mouse in dialog coordinates (`GetMouse` in the dialog port); nil before the first move.
    public internal(set) var mouseLocation: (x: Int, y: Int)?

    enum Tracking: Equatable {
        case none
        /// A push button / checkbox / radio pressed: hilited while the mouse is inside (`TrackControl`).
        case control(item: Int, inside: Bool)
        /// A TextEdit drag selection from `anchor`.
        case editDrag(item: Int, anchor: Int)
        /// A popup's menu open.
        case popup(PopupMenu)
    }

    struct PopupMenu: Equatable {
        var item: Int
        /// The menu's rect in dialog coordinates.
        var rect: DialogRect
        /// Row rects (dialog coordinates) per menu item index (0-based), separators included.
        var rows: [DialogRect]
        var highlighted: Int?
        /// Opened by a click and released on the button: stays open until the next click.
        var sticky: Bool
        /// Where the press that opened it happened, until the mouse moves away (a release there keeps it open).
        var pressX: Int?, pressY: Int?
    }

    private(set) var tracking: Tracking = .none { didSet { touch() } }

    /// Bumped on every visual change (the renderer caches by it).
    public private(set) var revision = 0
    var cache: (key: Int, image: RGBAImage)?

    /// Text width in the dialog font (set by `DialogSystem` from its renderer; 7 px a character until then).
    var measure: (String) -> Int = { $0.count * 7 }

    public init(template: DialogTemplate, data: BTXGameData?, art: ArtBank?, params: [String] = []) {
        self.template = template
        self.data = data
        self.art = art
        self.params = params
        append(template.items)
        if template.alertStages != nil { alertIcon = Self.alertIconImage(art: art) }
    }

    /// The application icon `NoteAlert` / `StopAlert` drew on Mac OS X — the Mac replica draws the app's own icon;
    /// the data's colour application icon (`cicn 128`) stands in for it here.
    static func alertIconImage(art: ArtBank?) -> RGBAImage? { try? art?.cicn(128) }

    private func touch() { revision &+= 1 }

    // MARK: - Items

    /// `AppendDITL(dialog, ditl, overlayDITL)`: the items keep their own rects, numbered after the dialog's.
    public func append(_ newItems: [DialogItem]) {
        for item in newItems {
            items.append(item)
            switch item.kind {
            case .button, .staticText, .editText:
                texts[item.number] = substituted(item.text)
            case .checkBox, .radio:
                texts[item.number] = substituted(item.text)
                values[item.number] = 0
            case .picture(let id):
                if let p = try? art?.pict(id) { pictures[item.number] = p }
            case .control(let cntl):
                if let data, let c = DialogResources.popupControl(cntl, data: data) {
                    popups[item.number] = (c, DialogResources.menuItems(c.menuID, data: data))
                }
                values[item.number] = 1
            case .user, .icon, .other:
                break
            }
        }
        touch()
    }

    /// `ShortenDITL` to `count` items.
    public func shorten(to count: Int) {
        while items.count > count, let last = items.popLast() {
            let n = last.number
            texts.removeValue(forKey: n)
            values.removeValue(forKey: n)
            popups.removeValue(forKey: n)
            pictures.removeValue(forKey: n)
            scroll.removeValue(forKey: n)
            hidden.remove(n)
            inactive.remove(n)
            if focusedEditItem == n { focusedEditItem = nil }
            if case .popup(let m) = tracking, m.item == n { tracking = .none }
        }
        touch()
    }

    public func item(_ n: Int) -> DialogItem? { items.first { $0.number == n } }

    private func substituted(_ s: String) -> String {
        var out = s
        for (i, p) in params.enumerated() { out = out.replacingOccurrences(of: "^\(i)", with: p) }
        return out
    }

    // MARK: - Values, text, visibility

    public func value(_ item: Int) -> Int { values[item] ?? 0 }

    /// `SetControlValue`.
    public func setValue(_ item: Int, _ v: Int) {
        values[item] = v
        touch()
    }

    /// The popup's menu items; `"-"` / `"(-"` are separators (Menu Manager metacharacters).
    public func setMenu(_ item: Int, titles: [String]) {
        guard let p = popups[item] else { return }
        popups[item] = (p.control, titles)
        touch()
    }

    /// `GetDialogItemText`.
    public func text(_ item: Int) -> String { texts[item] ?? "" }

    /// `SetDialogItemText` (a focused field's caret goes to the end, as the field editor's does).
    public func setText(_ item: Int, _ s: String) {
        guard let kind = self.item(item)?.kind, kind == .staticText || kind == .editText else { return }
        texts[item] = s
        if focusedEditItem == item {
            let n = s.count
            selStart = n
            selEnd = n
        }
        touch()
    }

    /// The focused edit item's selection length (`teSelEnd − teSelStart`).
    public var selectionLength: Int { focusedEditItem == nil ? 0 : selEnd - selStart }

    /// The focused field's selection (character offsets).
    public var selection: Range<Int>? { focusedEditItem == nil ? nil : selStart..<selEnd }

    /// `SelectDialogItemText(dialog, item, start, end)` — also moves the TextEdit focus there.
    public func selectText(_ item: Int, from start: Int = 0, to end: Int = 0x7fff) {
        guard let it = self.item(item), it.kind == .editText, !hidden.contains(item) else { return }
        focusedEditItem = item
        let length = text(item).count
        let s = min(max(start, 0), length), e = min(max(end, s), length)
        selStart = s
        selEnd = e
        caretTicks = 0
        touch()
    }

    /// `ShowDialogItem` / `HideDialogItem`.
    public func setHidden(_ item: Int, _ isHidden: Bool) {
        if isHidden {
            hidden.insert(item)
            if focusedEditItem == item { focusedEditItem = nil }
        } else {
            hidden.remove(item)
        }
        touch()
    }

    public func isHidden(_ item: Int) -> Bool { hidden.contains(item) }

    /// `ActivateControl` / `DeactivateControl` (`_ActivateItem` / `_DeactivateItem`).
    public func setActive(_ item: Int, _ active: Bool) {
        if active { inactive.remove(item) } else { inactive.insert(item) }
        touch()
    }

    public func isActive(_ item: Int) -> Bool { !inactive.contains(item) }

    /// The first (lowest-numbered) shown item whose rect holds `point` (dialog coordinates) — `_MouseInWhichPrefsItem`'s
    /// `GetDialogItem` + `PtInRect` scan. Hidden items are skipped: `HideDialogItem` moves their rects off by 16384.
    public func item(at x: Int, _ y: Int) -> Int? {
        for item in items where !hidden.contains(item.number) && item.rect.contains(x, y) { return item.number }
        return nil
    }

    // MARK: - Decorations

    /// `_OutlineItem(dialog, item)` on every update event (`_NewSetDlgFilter`, `_HiScoreEraseFilter`).
    public func outline(_ item: Int) {
        outlines.append(item)
        touch()
    }

    /// `FrameRect` in `rgb` on every update (`_TouchUpPrefsDialog`).
    func frame(_ rect: DialogRect, rgb: UInt32) {
        frames.append((rect, rgb))
        touch()
    }

    // MARK: - Hits

    private func hit(_ item: Int) {
        guard !flashing else { return }
        itemHit?(item)
    }

    /// `_FlashMyDialogItem`: `HiliteControl(1)`, `Delay(8)`, `HiliteControl(0)` — then `ModalDialog` returns `item`.
    public func flash(_ item: Int) {
        guard !flashing else { return }
        guard self.item(item)?.kind == .button else { hit(item); return }
        flashItem = item
        flashTicks = 8
        touch()
    }

    /// One 1/60 s tick: the flash's `Delay(8)`, the caret's blink.
    func tick() {
        let wasOn = caretVisible
        caretTicks &+= 1
        if wasOn != caretVisible { touch() }
        if let f = flashItem {
            flashTicks -= 1
            if flashTicks <= 0 {
                flashItem = nil
                touch()
                hit(f)
            }
        }
    }

    /// The caret is drawn (focused field, empty selection, on-phase of the blink).
    var caretVisible: Bool {
        focusedEditItem != nil && selStart == selEnd && (caretTicks / Self.caretPeriod) % 2 == 0
    }

    // MARK: - Mouse (dialog coordinates)

    /// The item a click at (x, y) goes to: the topmost shown item that takes clicks — buttons, checkboxes, radios,
    /// popups and edit fields while active, enabled user / icon items. Static text, pictures and disabled items pass
    /// the click to the item under them (`FindDialogItem`).
    func clickTarget(_ x: Int, _ y: Int) -> DialogItem? {
        for item in items.reversed() where !hidden.contains(item.number) && item.rect.contains(x, y) {
            switch item.kind {
            case .button, .checkBox, .radio, .control:
                if !inactive.contains(item.number) { return item }
            case .editText:
                return item
            case .user, .icon, .other:
                if item.enabled { return item }
            case .staticText, .picture:
                break
            }
        }
        return nil
    }

    /// True when (x, y) is on this dialog or its open popup menu.
    func contains(_ x: Int, _ y: Int) -> Bool {
        if x >= 0, y >= 0, x < template.width, y < template.height { return true }
        if case .popup(let m) = tracking, m.rect.contains(x, y) { return true }
        return false
    }

    func mouseDown(_ x: Int, _ y: Int) {
        mouseLocation = (x, y)
        guard !flashing else { return }
        if case .popup(var m) = tracking {
            // A click with the menu held open: on a row it tracks (chosen on release); elsewhere it closes the menu.
            if m.rect.contains(x, y) {
                m.highlighted = row(in: m, x, y)
                m.sticky = false
                tracking = .popup(m)
            } else {
                tracking = .none
            }
            return
        }
        guard let item = clickTarget(x, y) else { return }
        switch item.kind {
        case .button, .checkBox, .radio:
            tracking = .control(item: item.number, inside: true)
        case .control:
            openPopup(item, x, y)
        case .editText:
            let i = index(in: item, atX: x)
            focusedEditItem = item.number
            selStart = i
            selEnd = i
            caretTicks = 0
            tracking = .editDrag(item: item.number, anchor: i)
        default:
            hit(item.number)
        }
    }

    func mouseMoved(_ x: Int, _ y: Int) {
        mouseLocation = (x, y)
        switch tracking {
        case .none:
            break
        case .control(let n, let inside):
            let now = item(n)?.rect.contains(x, y) ?? false
            if now != inside { tracking = .control(item: n, inside: now) }
        case .editDrag(let n, let anchor):
            guard let it = item(n) else { return }
            let i = index(in: it, atX: x)
            let (s, e) = (min(anchor, i), max(anchor, i))
            if (s, e) != (selStart, selEnd) {
                selStart = s
                selEnd = e
                caretTicks = 0
                touch()
            }
        case .popup(var m):
            if m.pressX == x, m.pressY == y { return }
            m.pressX = nil
            m.pressY = nil
            let r = row(in: m, x, y)
            if r != m.highlighted || tracking != .popup(m) {
                m.highlighted = r
                tracking = .popup(m)
            }
        }
    }

    func mouseUp(_ x: Int, _ y: Int) {
        mouseMoved(x, y)
        switch tracking {
        case .none:
            break
        case .control(let n, let inside):
            tracking = .none
            // Carbon does not toggle a dialog checkbox: ModalDialog returns the item and the app sets the value.
            if inside { hit(n) }
        case .editDrag(let n, _):
            tracking = .none
            hit(n)
        case .popup(var m):
            if let r = m.highlighted {
                tracking = .none
                values[m.item] = r + 1
                touch()
                hit(m.item)
            } else if !m.sticky, let it = item(m.item), it.rect.contains(x, y) {
                m.sticky = true                                     // click-release on the button: menu stays up
                tracking = .popup(m)
            } else {
                tracking = .none
            }
        }
    }

    // MARK: - Popup menus

    static let menuRowHeight = 20, menuSeparatorHeight = 10, menuPadding = 5
    /// The popup button's rect inside the control item (right of its title).
    func popupButtonRect(_ item: DialogItem) -> DialogRect {
        let w = popups[item.number]?.control.titleWidth ?? 0
        return DialogRect(x: item.rect.x + w, y: item.rect.y, width: item.rect.width - w, height: item.rect.height)
    }

    static func isSeparator(_ t: String) -> Bool { t == "-" || t == "(-" }

    private func openPopup(_ item: DialogItem, _ x: Int, _ y: Int) {
        guard let p = popups[item.number], !p.titles.isEmpty else { return }
        let button = popupButtonRect(item)
        let widest = p.titles.filter { !Self.isSeparator($0) }.map(measure).max() ?? 0
        let width = max(button.width + 20, widest + 44)
        var rows: [DialogRect] = []
        var top = Self.menuPadding
        for t in p.titles {
            let h = Self.isSeparator(t) ? Self.menuSeparatorHeight : Self.menuRowHeight
            rows.append(DialogRect(x: 0, y: top, width: width, height: h))
            top += h
        }
        let height = top + Self.menuPadding
        // The checked item's row sits over the button (NSPopUpButton / `PopUpMenuSelect`), the text aligned with the
        // button's; then the menu is kept inside the canvas.
        let selected = max(0, min(value(item.number) - 1, rows.count - 1))
        var mx = button.x - 10
        var my = button.y + (button.height - Self.menuRowHeight) / 2 - rows[selected].y
        mx = min(max(mx, -originX + 4), canvasWidth - originX - width - 4)
        my = min(max(my, -originY + 4), canvasHeight - originY - height - 4)
        let placed = rows.map { $0.offsetBy(mx, my) }
        let rect = DialogRect(x: mx, y: my, width: width, height: height)
        tracking = .popup(PopupMenu(item: item.number, rect: rect, rows: placed, highlighted: nil, sticky: false,
                                     pressX: x, pressY: y))
    }

    /// The selectable menu row under (x, y), 0-based.
    private func row(in m: PopupMenu, _ x: Int, _ y: Int) -> Int? {
        guard m.rect.contains(x, y), let titles = popups[m.item]?.titles else { return nil }
        for (i, r) in m.rows.enumerated() where r.contains(x, y) {
            return i < titles.count && !Self.isSeparator(titles[i]) ? i : nil
        }
        return nil
    }

    // MARK: - Keys (ModalDialog: filter, then the standard filter, then TextEdit)

    func handleKey(_ key: DialogKey) {
        if flashing { return }
        if case .popup = tracking {
            // The menu tracks the mouse only; Esc dismisses it.
            if key.char == 0x1b { tracking = .none }
            return
        }
        if let f = keyFilter, f(key) { return }
        // The standard filter (`SetDialogDefaultItem` / `SetDialogCancelItem`).
        if !key.command, key.char == 0x0d || key.char == 0x03 {
            if let d = defaultItem { flash(d) }
            return
        }
        if (!key.command && key.char == 0x1b) || (key.command && key.char == UInt8(ascii: ".")) {
            if let c = cancelItem { flash(c) }
            return
        }
        // App-modal: no menu command reaches the app while a dialog is up, and TextEdit takes no ⌘ keys.
        if key.command { return }
        if key.char == 0x09 {
            tabToNextEditField()
            return
        }
        guard let f = focusedEditItem else { return }
        edit(f, key.char)
    }

    /// TextEdit: printable characters, Delete and the arrows edit; other control characters are dropped.
    private func edit(_ item: Int, _ c: UInt8) {
        var chars = Array(text(item))
        switch c {
        case 0x08:
            if selStart < selEnd {
                chars.removeSubrange(selStart..<selEnd)
            } else if selStart > 0 {
                chars.remove(at: selStart - 1)
                selStart -= 1
            }
            selEnd = selStart
        case 0x1c:
            selStart = selStart < selEnd ? selStart : max(0, selStart - 1)
            selEnd = selStart
        case 0x1d:
            selStart = selStart < selEnd ? selEnd : min(chars.count, selEnd + 1)
            selEnd = selStart
        case 0x1e:
            selStart = 0
            selEnd = 0
        case 0x1f:
            selStart = chars.count
            selEnd = chars.count
        default:
            guard c >= 0x20, c != 0x7f else { return }
            let typed = Array(MacRoman.decode([c]))
            chars.replaceSubrange(selStart..<selEnd, with: typed)
            selStart += typed.count
            selEnd = selStart
        }
        texts[item] = String(chars)
        caretTicks = 0
        touch()
    }

    /// Dialog Manager Tab: the next shown edit item, all of its text selected.
    private func tabToNextEditField() {
        let edits = items.filter { $0.kind == .editText && !hidden.contains($0.number) }.map(\.number)
        guard !edits.isEmpty else { return }
        let current = focusedEditItem.flatMap { edits.firstIndex(of: $0) } ?? -1
        selectText(edits[(current + 1) % edits.count])
    }

    // MARK: - Edit-field geometry (shared with the renderer)

    /// Text inset of an edit field: the text starts 3 px right of the item rect's left (the Mac replica's Aqua field
    /// is the item rect outset by 3; its text sits 3 px inside the item rect).
    static let editTextInset = 3

    /// The character index nearest to x (dialog coordinates) in an edit field.
    func index(in item: DialogItem, atX x: Int) -> Int {
        let chars = Array(text(item.number))
        let local = x - item.rect.x - Self.editTextInset + (scroll[item.number] ?? 0)
        var best = 0, bestDistance = Int.max
        for i in 0...chars.count {
            let w = measure(String(chars[0..<i]))
            let d = abs(w - local)
            if d < bestDistance { best = i; bestDistance = d }
        }
        return best
    }

    /// Updates a field's scroll so the caret / selection end is visible; returns it.
    @discardableResult
    func scrollToCaret(_ item: DialogItem) -> Int {
        let chars = Array(text(item.number))
        let visible = item.rect.width - 2 * Self.editTextInset
        var s = scroll[item.number] ?? 0
        let caretX = measure(String(chars[0..<min(selEnd, chars.count)]))
        if caretX - s > visible { s = caretX - visible }
        if caretX < s { s = caretX }
        let total = measure(String(chars))
        s = max(0, min(s, max(0, total - visible)))
        scroll[item.number] = s
        return s
    }
}

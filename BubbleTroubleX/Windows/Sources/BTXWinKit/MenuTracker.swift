import Foundation

/// What a row shows: the item, or its ⌥ alternate while Alt is held.
public struct MenuShownItem: Equatable, Sendable {
    public var title: String
    public var key: Character?
    /// Including Shift for an upper-case key.
    public var modifiers: MenuModifiers
    public var command: MenuCommand?
    public var rule: MenuEnableRule
}

/// Mouse tracking for the in-window bar, on logical window coordinates (the driver's own events mapped to these
/// calls; nothing here depends on its event type).
///
/// Behaviour (the Mac's, both ways it tracks):
/// - **Press-drag-release:** press on a title opens its menu; dragging highlights enabled items (disabled items and
///   separators never highlight), moving over another title switches menus, resting on Key Sets opens its submenu;
///   releasing over an enabled item chooses it.
/// - **Click-release-click (sticky):** releasing over a title (or a submenu's parent item) leaves the menu open;
///   the pointer then highlights without a button; a click on an enabled item chooses it, a click on a disabled item or
///   a separator keeps the menu open, a click on the open title or outside every menu closes it (that click is not
///   passed on).
/// - Released after a drag over nothing (disabled item, separator, outside): closed, nothing chosen.
/// - **Esc** closes. Alt (⌥) shows the Window menu's alternates while held. No arrow-key navigation (the Mac's is an
///   AppKit affordance; Carbon 2008 menus had none) and no choice-blink.
public struct MenuTracker: Equatable, Sendable {
    public enum Mode: Equatable, Sendable { case pressed, sticky }

    /// The open menu (index into `MenuBar.menus`); nil = closed.
    public private(set) var openMenu: Int?
    /// The highlighted entry of the open menu (an enabled item; a submenu's parent stays lit while it is open).
    public private(set) var highlighted: Int?
    /// The entry whose submenu is open.
    public private(set) var openSubmenu: Int?
    /// The highlighted entry of the open submenu.
    public private(set) var subHighlighted: Int?
    public private(set) var mode: Mode = .pressed
    public private(set) var optionHeld = false
    /// The button went down inside a drop-down (sticky mode): a release over nothing keeps the menu open.
    private var pressBeganInMenu = false
    private var pointer: (x: Int, y: Int)?

    public init() {}

    public static func == (a: MenuTracker, b: MenuTracker) -> Bool {
        a.openMenu == b.openMenu && a.highlighted == b.highlighted && a.openSubmenu == b.openSubmenu
            && a.subHighlighted == b.subHighlighted && a.mode == b.mode && a.optionHeld == b.optionHeld
    }

    public var isOpen: Bool { openMenu != nil }

    public mutating func close() {
        openMenu = nil; highlighted = nil; openSubmenu = nil; subHighlighted = nil
        mode = .pressed; pressBeganInMenu = false
    }

    static func shown(_ item: MenuItem, option: Bool) -> MenuShownItem {
        if option, let alt = item.alternate {
            return MenuShownItem(title: alt.title, key: alt.key, modifiers: alt.effectiveModifiers,
                                 command: alt.command, rule: alt.rule)
        }
        return MenuShownItem(title: item.title, key: item.key, modifiers: item.effectiveModifiers,
                             command: item.command, rule: item.rule)
    }

    // MARK: Events

    /// Button down. True when the press belongs to the menu bar (the bar strip, or anything while a menu is open) —
    /// the driver must then not pass it to the game.
    public mutating func mouseDown(x: Int, y: Int, modifiers: MenuModifiers = [], bar: MenuBar,
                                   geometry: MenuGeometry) -> Bool {
        optionHeld = modifiers.contains(.option)
        pointer = (x, y)
        if let t = geometry.title(at: x, y) {
            if openMenu == t && mode == .sticky {
                close()
            } else {
                open(t)
                mode = .pressed
                pressBeganInMenu = false
            }
            return true
        }
        guard isOpen else { return y < geometry.barHeight }
        if insideDropdowns(x, y, geometry) {
            mode = .pressed
            pressBeganInMenu = true
            track(x, y, bar: bar, geometry: geometry)
        } else {
            close()
        }
        return true
    }

    /// Pointer moved (dragging, or hovering in sticky mode).
    public mutating func mouseMoved(x: Int, y: Int, modifiers: MenuModifiers = [], bar: MenuBar,
                                    geometry: MenuGeometry) {
        optionHeld = modifiers.contains(.option)
        pointer = (x, y)
        guard isOpen else { return }
        track(x, y, bar: bar, geometry: geometry)
    }

    /// Button up: the chosen command, if any (the menu then closes).
    public mutating func mouseUp(x: Int, y: Int, modifiers: MenuModifiers = [], bar: MenuBar,
                                 geometry: MenuGeometry) -> MenuCommand? {
        optionHeld = modifiers.contains(.option)
        pointer = (x, y)
        guard let open = openMenu, mode == .pressed else { return nil }
        track(x, y, bar: bar, geometry: geometry)
        if geometry.title(at: x, y) != nil {
            mode = .sticky
            return nil
        }
        let menu = bar.menus[open]
        let d = geometry.dropdowns[open]
        var hit: MenuItem?
        if let p = openSubmenu, let sd = d.submenus[p], let row = sd.row(at: x, y) {
            hit = menu.entries[p].item?.submenu?.entries[row.entry].item
        } else if let row = d.row(at: x, y) {
            hit = menu.entries[row.entry].item
        }
        if let item = hit {
            let s = Self.shown(item, option: optionHeld)
            if bar.isEnabled(s.rule) {
                if item.submenu != nil { mode = .sticky; return nil }
                if let c = s.command { close(); return c }
            }
        }
        if pressBeganInMenu && insideDropdowns(x, y, geometry) {
            mode = .sticky
            return nil
        }
        close()
        return nil
    }

    /// Alt pressed or released: the alternates swap in place.
    public mutating func modifiersChanged(_ modifiers: MenuModifiers, bar: MenuBar, geometry: MenuGeometry) {
        optionHeld = modifiers.contains(.option)
        if isOpen, let p = pointer { track(p.x, p.y, bar: bar, geometry: geometry) }
    }

    /// A key while a menu is open: consumed (true); Esc (0x35) closes. False when no menu is open.
    public mutating func keyDown(keyCode: UInt16) -> Bool {
        guard isOpen else { return false }
        if keyCode == 0x35 { close() }
        return true
    }

    // MARK: Tracking

    private mutating func open(_ menu: Int) {
        openMenu = menu; highlighted = nil; openSubmenu = nil; subHighlighted = nil
    }

    private func insideDropdowns(_ x: Int, _ y: Int, _ g: MenuGeometry) -> Bool {
        guard let open = openMenu else { return false }
        let d = g.dropdowns[open]
        if d.frame.contains(x, y) { return true }
        if let p = openSubmenu, let sd = d.submenus[p], sd.frame.contains(x, y) { return true }
        return false
    }

    private mutating func track(_ x: Int, _ y: Int, bar: MenuBar, geometry g: MenuGeometry) {
        guard let open = openMenu else { return }
        if let t = g.title(at: x, y) {
            if t != open { self.open(t) }
            return
        }
        let menu = bar.menus[open]
        let d = g.dropdowns[open]
        func enabled(_ e: MenuEntry?) -> Bool {
            guard let item = e?.item else { return false }
            return bar.isEnabled(Self.shown(item, option: optionHeld).rule)
        }
        // The open submenu first: it is drawn over its parent.
        if let p = openSubmenu, let sd = d.submenus[p], sd.frame.contains(x, y) {
            let entries = menu.entries[p].item?.submenu?.entries ?? []
            if let row = sd.row(at: x, y), enabled(entries[row.entry]) {
                subHighlighted = row.entry
            } else {
                subHighlighted = nil
            }
            highlighted = p
            return
        }
        if d.frame.contains(x, y) {
            if let row = d.row(at: x, y), enabled(menu.entries[row.entry]) {
                highlighted = row.entry
                if menu.entries[row.entry].item?.submenu != nil {
                    if openSubmenu != row.entry { openSubmenu = row.entry; subHighlighted = nil }
                } else {
                    openSubmenu = nil; subHighlighted = nil
                }
            } else {
                highlighted = nil; openSubmenu = nil; subHighlighted = nil
            }
            return
        }
        // Outside: an open submenu stays (its parent lit); otherwise nothing is lit.
        if openSubmenu != nil { subHighlighted = nil } else { highlighted = nil }
    }
}

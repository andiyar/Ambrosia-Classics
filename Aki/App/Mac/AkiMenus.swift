import AppKit
import AkiCore

/// The menu bar of the shipped `MainMenu.nib` (Research note 7), built from its `designable.nib` XML in
/// the preferred localization (English or Japanese) — the 1.2 app loaded the same nib as `NSMainNibFile`.
/// Every title, key equivalent, modifier mask, tag and action comes from the nib; nothing is added.
/// The three out-of-scope items (Known delta 1, Q11) are dropped: "Register Aki…" (`showRegistration:`),
/// "Check for Updates…" (`checkForUpdates:`) and "Download Levels…" (tag 15), then the separators left
/// leading, trailing or doubled are collapsed. An item the nib wires to no action (the Japanese
/// "Undo Last Move", Edit tag 3) is built with no action — shipped data, nothing invented.
@MainActor enum AkiMenus {
    /// Actions whose items are out of scope (Known delta 1).
    private static let droppedActions: Set<String> = ["showRegistration:", "checkForUpdates:"]
    /// "Download Levels…" (method-map §4, tag 15).
    private static let droppedTag = 15
    /// The nib's title for the `showPreferences:` item ("Preferences…"), which AppKit renames "Settings…".
    private(set) static var preferencesTitle: String?
    /// The Edit menu as built from the nib (the submenu holding `copy:`) and the items the nib gave it.
    private static var editMenu: NSMenu?
    private static var nibEditItems: [NSMenuItem] = []

    /// The main menu: `AMainMenu` of `MainMenu.nib/designable.nib`. Items the nib targets at "Controller"
    /// get the app delegate (the nib's `Controller`) as target; the rest (FirstResponder) target nil. Also sets `NSApp.windowsMenu` to
    /// the submenu holding `arrangeInFront:` (the nib's Window menu).
    static func build(app: AkiAppDelegate) throws -> NSMenu {
        let nib = try CocoaNib(data: app.controller.assets.lproj("MainMenu.nib/designable.nib"))
        let menu = makeMenu(title: "AMainMenu", items: nib.mainMenu, controller: app)
        NSApp.windowsMenu = menu.items.compactMap(\.submenu).first { submenu in
            submenu.items.contains { $0.action == #selector(NSApplication.arrangeInFront(_:)) }
        }
        editMenu = menu.items.compactMap(\.submenu).first { submenu in
            submenu.items.contains { $0.action == #selector(NSText.copy(_:)) }
        }
        nibEditItems = editMenu?.items ?? []
        // Runs after the caller's `NSApp.mainMenu =` (an immediate re-set does not stick, measured).
        app.perform(#selector(AkiAppDelegate.restoreNibMenu), with: nil, afterDelay: 0)
        return menu
    }

    /// Undoes what AppKit adds to the installed bar and the nib lacks: the Preferences item's nib title
    /// comes back over "Settings…", and every Edit item the nib did not build (AutoFill) is removed.
    /// Start Dictation… and Emoji & Symbols are switched off by registered defaults in `AkiMain`; the ⌥
    /// alternates, the Window menu's tiling items and Clear Current Layer's dropped ⌘X are left alone.
    static func restoreNibItems() {
        if let title = preferencesTitle, let item = NSApp.mainMenu?.items.lazy.compactMap(\.submenu)
            .compactMap({ $0.items.first { $0.action == #selector(AkiAppDelegate.showPreferences(_:)) } }).first {
            item.title = title
        }
        guard let editMenu else { return }
        for item in editMenu.items where !nibEditItems.contains(where: { $0 === item }) {
            editMenu.removeItem(item)
        }
    }

    private static func makeMenu(title: String, items: [CocoaNib.MenuItem], controller: AkiAppDelegate) -> NSMenu {
        let menu = NSMenu(title: title)
        for item in collapsingSeparators(items.filter(isInScope)) {
            menu.addItem(makeItem(item, controller: controller))
        }
        return menu
    }

    private static func isInScope(_ item: CocoaNib.MenuItem) -> Bool {
        if let action = item.action, droppedActions.contains(action) { return false }
        return item.tag != droppedTag
    }

    /// Drops leading and trailing separators and every separator that follows another.
    private static func collapsingSeparators(_ items: [CocoaNib.MenuItem]) -> [CocoaNib.MenuItem] {
        var result: [CocoaNib.MenuItem] = []
        for item in items where !(item.isSeparator && (result.last?.isSeparator ?? true)) {
            result.append(item)
        }
        while result.last?.isSeparator == true { result.removeLast() }
        return result
    }

    private static func makeItem(_ item: CocoaNib.MenuItem, controller: AkiAppDelegate) -> NSMenuItem {
        if item.isSeparator { return .separator() }
        let menuItem = NSMenuItem(title: item.title, action: item.action.map(NSSelectorFromString),
                                  keyEquivalent: item.keyEquivalent)
        menuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(UInt32(truncatingIfNeeded: item.modifierMask)))
            .intersection(.deviceIndependentFlagsMask)
        menuItem.tag = item.tag
        if item.action == "showPreferences:" {
            preferencesTitle = item.title
        }
        if item.action != nil, item.target == "Controller" {
            menuItem.target = controller
        }
        if let submenu = item.submenu {
            menuItem.submenu = makeMenu(title: item.title, items: submenu, controller: controller)
        }
        return menuItem
    }
}

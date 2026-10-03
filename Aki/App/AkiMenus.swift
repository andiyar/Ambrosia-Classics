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

    /// The main menu: `AMainMenu` of `MainMenu.nib/designable.nib`. Items the nib targets at "Controller"
    /// get `controller` as target; the rest (FirstResponder) target nil. Also sets `NSApp.windowsMenu` to
    /// the submenu holding `arrangeInFront:` (the nib's Window menu).
    static func build(controller: AkiController) throws -> NSMenu {
        let nib = try CocoaNib(data: controller.assets.lproj("MainMenu.nib/designable.nib"))
        let menu = makeMenu(title: "AMainMenu", items: nib.mainMenu, controller: controller)
        NSApp.windowsMenu = menu.items.compactMap(\.submenu).first { submenu in
            submenu.items.contains { $0.action == #selector(NSApplication.arrangeInFront(_:)) }
        }
        return menu
    }

    private static func makeMenu(title: String, items: [CocoaNib.MenuItem], controller: AkiController) -> NSMenu {
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

    private static func makeItem(_ item: CocoaNib.MenuItem, controller: AkiController) -> NSMenuItem {
        if item.isSeparator { return .separator() }
        let menuItem = NSMenuItem(title: item.title, action: item.action.map(NSSelectorFromString),
                                  keyEquivalent: item.keyEquivalent)
        menuItem.keyEquivalentModifierMask = NSEvent.ModifierFlags(rawValue: UInt(UInt32(truncatingIfNeeded: item.modifierMask)))
            .intersection(.deviceIndependentFlagsMask)
        menuItem.tag = item.tag
        if item.action != nil, item.target == "Controller" {
            menuItem.target = controller
        }
        if let submenu = item.submenu {
            menuItem.submenu = makeMenu(title: item.title, items: submenu, controller: controller)
        }
        return menuItem
    }
}

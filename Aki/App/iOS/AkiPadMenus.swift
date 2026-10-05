import AkiCore
import UIKit

/// The iPadOS 26 menu bar built from the shipped `MainMenu.nib` (plan C5), as `Aki/App/Mac/AkiMenus.swift`
/// builds the Mac's: the nib's titles, key equivalents (+ modifier masks) and tags (in each command's
/// `propertyList`), the same three out-of-scope items dropped (Register, Check for Updates, Download Levels)
/// and separators collapsed the same way (a separator → an inline section break).
///
/// Omitted on iPad (no iPad meaning): Hide Aki, Hide Others, Show All (`hide:`, `hideOtherApplications:`,
/// `unhideAllApplications:`), Close (`performClose:` — no secondary windows), Toggle Fullscreen (always full
/// screen), and the Window menu's Minimize, Zoom, Bring All to Front (the system's Window menu stays). The
/// system menus the nib lacks are removed (Format, View); the nib's File, Edit, Level Editor and Help menus
/// replace the system ones. Clear Current Layer's ⌘X is dropped (it collides with Cut; AppKit drops it too).
/// Added, as on the Mac (D11): the checkable "Remastered Art" directly after Preferences.
@MainActor enum AkiPadMenus {
    private static let droppedActions: Set<String> = [
        "showRegistration:", "checkForUpdates:",                       // Known delta 1 (as the Mac)
        "hide:", "hideOtherApplications:", "unhideAllApplications:",   // iPad: no meaning
        "performClose:", "toggleFullscreen:",
        "performMiniaturize:", "performZoom:", "arrangeInFront:",
    ]
    private static let droppedTag = 15                                  // Download Levels…
    private static let levelEditorMenu = UIMenu.Identifier("com.ambrosiaclassics.aki.levelEditor")
    private static let fileMenu = UIMenu.Identifier("com.ambrosiaclassics.aki.file")
    private static let editMenu = UIMenu.Identifier("com.ambrosiaclassics.aki.edit")
    private static let helpMenu = UIMenu.Identifier("com.ambrosiaclassics.aki.help")

    /// Rebuilds the main menu bar from the nib (`buildMenu(with:)`). A missing nib leaves the system bar.
    static func build(_ builder: any UIMenuBuilder, assets: AkiAssets) {
        guard let data = try? assets.lproj("MainMenu.nib/designable.nib"), let nib = try? CocoaNib(data: data) else { return }
        let top = nib.mainMenu
        func submenu(containing test: (CocoaNib.MenuItem) -> Bool) -> CocoaNib.MenuItem? {
            top.first { $0.submenu?.contains(where: test) ?? false }
        }
        let app = submenu { $0.action == "showAboutBox:" }
        let file = submenu { $0.tag == 2 }
        let edit = submenu { $0.action == "copy:" }
        let editor = submenu { $0.tag == 10 }
        let help = submenu { $0.action == "showHelp:" }

        builder.remove(menu: .format)
        builder.remove(menu: .view)
        if let app {
            builder.replaceChildren(ofMenu: .application) { _ in elements(app.submenu ?? []) }
        }
        if let file {
            builder.replace(menu: .file, with: UIMenu(title: file.title, identifier: fileMenu, children: elements(file.submenu ?? [])))
        }
        if let edit {
            builder.replace(menu: .edit, with: UIMenu(title: edit.title, identifier: editMenu, children: elements(edit.submenu ?? [])))
        }
        if let editor {
            let menu = UIMenu(title: editor.title, identifier: levelEditorMenu, children: elements(editor.submenu ?? []))
            builder.insertSibling(menu, afterMenu: edit == nil ? .file : editMenu)
        }
        if let help {
            builder.replace(menu: .help, with: UIMenu(title: help.title, identifier: helpMenu, children: elements(help.submenu ?? [])))
        }
    }

    /// One nib menu's items as menu elements: in scope, separators collapsed, each run between separators an
    /// inline section.
    private static func elements(_ items: [CocoaNib.MenuItem]) -> [UIMenuElement] {
        var sections: [[UIMenuElement]] = [[]]
        for item in collapsingSeparators(items.filter(isInScope)) {
            if item.isSeparator {
                sections.append([])
            } else if let element = element(item) {
                sections[sections.count - 1].append(element)
                if item.action == "showPreferences:" {             // D11: "Remastered Art" right after Preferences
                    sections[sections.count - 1].append(
                        UICommand(title: "Remastered Art", action: #selector(AkiPadAppDelegate.akiToggleRemasteredArt(_:))))
                }
            }
        }
        sections.removeAll { $0.isEmpty }
        if sections.count == 1 { return sections[0] }
        return sections.map { UIMenu(title: "", options: .displayInline, children: $0) }
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

    /// The selector an item's nib action maps to on iPad.
    private static func selector(_ item: CocoaNib.MenuItem) -> Selector {
        if item.tag >= 1, item.action == "gameMenuAction:" { return #selector(AkiPadAppDelegate.akiMenuCommand(_:)) }
        switch item.action {
        case "showAboutBox:": return #selector(AkiPadAppDelegate.akiShowAbout(_:))
        case "showPreferences:": return #selector(AkiPadAppDelegate.akiShowPreferences(_:))
        case "terminate:": return #selector(AkiPadAppDelegate.akiQuit(_:))
        case "showHelp:": return #selector(AkiPadAppDelegate.akiShowHelp(_:))
        case "showHandbook:": return #selector(AkiPadAppDelegate.akiShowHandbook(_:))
        case "showReleaseNotes:": return #selector(AkiPadAppDelegate.akiShowReleaseNotes(_:))
        case "cut:": return #selector(UIResponderStandardEditActions.cut(_:))
        case "copy:": return #selector(UIResponderStandardEditActions.copy(_:))
        case "paste:": return #selector(UIResponderStandardEditActions.paste(_:))
        case "delete:": return #selector(UIResponderStandardEditActions.delete(_:))
        case "selectAll:": return #selector(UIResponderStandardEditActions.selectAll(_:))
        default: return #selector(AkiPadAppDelegate.akiNoAction(_:))   // nib item wired to no action
        }
    }

    private static func element(_ item: CocoaNib.MenuItem) -> UIMenuElement? {
        if let submenu = item.submenu {
            return UIMenu(title: item.title, children: elements(submenu))
        }
        let action = selector(item)
        let propertyList: Any? = item.tag >= 1 ? ["tag": item.tag] : nil
        var key = item.keyEquivalent
        if item.tag == 16 { key = "" }                                  // Clear Current Layer: ⌘X dropped
        guard !key.isEmpty else {
            return UICommand(title: item.title, action: action, propertyList: propertyList)
        }
        var flags = modifierFlags(item.modifierMask)
        if key.count == 1, let c = key.first, c.isLetter, c.isUppercase {
            key = key.lowercased()
            flags.insert(.shift)
        }
        return UIKeyCommand(title: item.title, action: action, input: key, modifierFlags: flags, propertyList: propertyList)
    }

    /// `NSEventModifierFlags` (device-independent bits) → UIKit.
    private static func modifierFlags(_ mask: Int) -> UIKeyModifierFlags {
        var flags: UIKeyModifierFlags = []
        if mask & 0x20000 != 0 { flags.insert(.shift) }
        if mask & 0x40000 != 0 { flags.insert(.control) }
        if mask & 0x80000 != 0 { flags.insert(.alternate) }
        if mask & 0x100000 != 0 { flags.insert(.command) }
        return flags
    }
}

import Foundation
import BubbleTroubleCore
import HectorInput

/// Bubble Trouble X's gamepad layout (Classics D36, HectorKit D16): the pad acts as the ORIGINAL keys — the current
/// key set from Preferences, so remapping a key remaps the button. Foundation + HectorInput + the core's `KeySet`
/// only: the Mac shell and (later, W1) the Windows shell compile this same file.
///
/// Kid-friendly: every face button does the same thing (Nintendo and Xbox swap the A/B, X/Y labels), the d-pad and
/// left stick both move (the stick folds into the d-pad in HectorInput). Shoulders, triggers and stick clicks do
/// nothing.
///
/// | context | d-pad / left stick | face buttons | + / Menu (start) | − / View (back) |
/// |---|---|---|---|---|
/// | play, no dialog | the set's left / right / up / down | the set's push | Caps Lock toggle (pause) | Esc after a 1 s hold |
/// | play, dialog up | arrows | Return | Caps Lock toggle (the pause survives the dialog) | Esc |
/// | anything else (menu, splash, screens, demo, dialogs) | arrows | Return | Return | Esc |
///
/// Outside play the d-pad is the fixed arrows, never the key set: the main menu acts on characters, so a letter key
/// set (J/L/I/K, Z/X, Q/W/E/R) would fire menu commands; the menu ignores the arrows.
enum BTXPadLayout {
    static let returnKey: UInt16 = 0x24
    static let escapeKey: UInt16 = 0x35
    static let leftArrow: UInt16 = 0x7B
    static let rightArrow: UInt16 = 0x7C
    static let downArrow: UInt16 = 0x7D
    static let upArrow: UInt16 = 0x7E
    /// How long − must be held in play before it is Esc (a stray press does nothing).
    static let escapeHoldSeconds = 1.0

    static let faceButtons: [ShellPadButton] = [.south, .east, .west, .north]

    /// The layout for one poll. `inPlay`: a play-mode session (not a demo) is in its game; `dialogUp`: a dialog
    /// waits for the user.
    static func mapping(keySet: KeySet, inPlay: Bool, dialogUp: Bool) -> ShellPadMapping {
        var b: [ShellPadButton: ShellPadBinding] = [:]
        if inPlay && !dialogUp {
            b[.left] = .key(keySet.left)
            b[.right] = .key(keySet.right)
            b[.up] = .key(keySet.up)
            b[.down] = .key(keySet.down)
            for f in faceButtons { b[f] = .key(keySet.push) }
            b[.start] = .capsLockToggle
            b[.back] = .keyAfterHold(escapeKey, seconds: escapeHoldSeconds)
        } else {
            b[.left] = .key(leftArrow)
            b[.right] = .key(rightArrow)
            b[.up] = .key(upArrow)
            b[.down] = .key(downArrow)
            for f in faceButtons { b[f] = .key(returnKey) }
            b[.start] = inPlay ? .capsLockToggle : .key(returnKey)
            b[.back] = .key(escapeKey)
        }
        return ShellPadMapping(bindings: b)
    }
}

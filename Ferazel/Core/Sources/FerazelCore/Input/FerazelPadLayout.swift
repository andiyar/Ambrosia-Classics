import Foundation
import HectorInput

/// Ferazel's Wand's gamepad layout (D37, task GP; the Bubble Trouble X mechanism, Classics D36 / HectorKit D16): the
/// pad presses keys the ORIGINAL reads — in a level the nine action keys of the live prefs (`keys[0…8]`, engine §7.1,
/// `.IsInputKeyPressed`), so remapping a key in Options remaps the button; + is a Caps Lock latch (the pause). The
/// codes are Mac virtual key codes, the `GetKeys` bits `KeyState` holds — the codes the keyboard path emits for the
/// same keys. Foundation + HectorInput only: the Mac shell and Phase 7's Windows shell compile this same file.
///
/// Buttons by position (Nintendo and Xbox swap the A/B, X/Y labels); the left stick folds into the d-pad.
///
/// | context | d-pad | south + east | west | north | L / R | ZL / ZR | + | − |
/// |---|---|---|---|---|---|---|---|---|
/// | `.playing` | keys 0–3 | keys 5 jump | keys 4 run | keys 6 use | keys 7 / 8 | keys 4 | Caps Lock toggle | Esc after 1 s |
/// | `.paused` | — | — | — | — | — | — | Caps Lock toggle | — |
/// | `.mainMenu` | — | N | — | — | — | — | N | — |
/// | `.map`, `.deathScreen` | arrows | Return | Return | Return | — | — | Return | Esc after 1 s |
/// | `.conversation` | keys 0–3 | Return | Return | Return | — | — | Return | Esc |
/// | `.other` | arrows | Return | Return | Return | — | — | Return | Esc |
///
/// With a dialog up (a confirm or report over any context): arrows, Return, Esc, and + stays the latch inside a level
/// (`.playing` / `.paused`), so a pause survives the dialog. Outside a level the d-pad is the fixed arrows, never the
/// key set (the menu acts on letters). A conversation's menu moves on the up / down INPUT keys (`ConversationRun`'s
/// inputs 2 / 3, C1), so its d-pad is the move keys; Return confirms there and is "any key" for its waits. On the map
/// Esc opens the abort question (whose default OK Return presses, Esc ignored) and on the death screen Esc gives up
/// with no question, so − is a 1 s hold there as in a level (D37: a stray press must not abort a kid's game).
public enum FerazelPadLayout {
    public static let returnKey: UInt16 = 0x24
    public static let escapeKey: UInt16 = 0x35
    public static let leftArrow: UInt16 = 0x7B
    public static let rightArrow: UInt16 = 0x7C
    public static let downArrow: UInt16 = 0x7D
    public static let upArrow: UInt16 = 0x7E
    /// N: the main menu's New Game key (`MainMenu.newGameKey`).
    public static let newGameKey = UInt16(MainMenu.newGameKey)
    /// How long − must be held in play before it is Esc (a stray press must not abort a kid's game).
    public static let escapeHoldSeconds = 1.0

    private static let faceButtons: [ShellPadButton] = [.south, .east, .west, .north]

    /// The layout for one poll: `keys` = the live prefs' nine action key codes, `context` = `GameFlow.padContext`,
    /// `dialogUp` = a dialog waits for the user.
    public static func mapping(keys: [Int16], context: GameFlow.PadContext, dialogUp: Bool) -> ShellPadMapping {
        var b: [ShellPadButton: ShellPadBinding] = [:]
        /// Action `i`'s key, when it is a key `GetKeys` can report (0…127).
        func action(_ i: Int) -> ShellPadBinding? {
            guard keys.indices.contains(i), (0...0x7f).contains(keys[i]) else { return nil }
            return .key(UInt16(keys[i]))
        }
        func arrowsReturnEscape() {
            b[.left] = .key(leftArrow)
            b[.right] = .key(rightArrow)
            b[.down] = .key(downArrow)
            b[.up] = .key(upArrow)
            for f in faceButtons { b[f] = .key(returnKey) }
            b[.start] = .key(returnKey)
            b[.back] = .key(escapeKey)
        }
        if dialogUp {
            arrowsReturnEscape()
            if context == .playing || context == .paused { b[.start] = .capsLockToggle }
            return ShellPadMapping(bindings: b)
        }
        switch context {
        case .playing:
            b[.left] = action(0)
            b[.right] = action(1)
            b[.up] = action(2)
            b[.down] = action(3)
            b[.west] = action(4)
            b[.leftTrigger] = action(4)
            b[.rightTrigger] = action(4)
            b[.south] = action(5)
            b[.east] = action(5)
            b[.north] = action(6)
            b[.leftShoulder] = action(7)
            b[.rightShoulder] = action(8)
            b[.start] = .capsLockToggle
            b[.back] = .keyAfterHold(escapeKey, seconds: escapeHoldSeconds)
        case .paused:
            b[.start] = .capsLockToggle
        case .mainMenu:
            b[.south] = .key(newGameKey)
            b[.east] = .key(newGameKey)
            b[.start] = .key(newGameKey)
        case .conversation:
            arrowsReturnEscape()
            b[.left] = action(0)
            b[.right] = action(1)
            b[.up] = action(2)
            b[.down] = action(3)
        case .map, .deathScreen:
            arrowsReturnEscape()
            b[.back] = .keyAfterHold(escapeKey, seconds: escapeHoldSeconds)
        case .other:
            arrowsReturnEscape()
        }
        return ShellPadMapping(bindings: b)
    }
}

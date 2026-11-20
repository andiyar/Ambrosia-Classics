import Foundation
import HectorInput

/// Deimos Rising's gamepad layout (Phase 4 S7 GP; grounding C §4, ruling 17; the Bubble Trouble X / Ferazel mechanism,
/// Classics D36 / D37, HectorKit D16): the pad presses keys the ORIGINAL reads. In play the d-pad and face buttons
/// press P1's LIVE key set (`KeyTable`, prefs `+0x14b8`), so remapping a key in the controls window remaps the button;
/// + is a Caps Lock latch (the pause is the Caps Lock state, `FrameKeys`). One pad, player 1 only (the kit unions every
/// connected pad; two pads need a kit change, question 3). The codes are Mac virtual key codes, the `GetKeys` bits
/// `HeldKeys.held` carries. Foundation + HectorInput only. The shell assigns the mapping before each poll (S8a).
///
/// Buttons by position (Nintendo and Xbox swap the A/B, X/Y labels); the left stick folds into the d-pad.
///
/// | context | d-pad | face (S W N E) | shoulders / triggers | + | − |
/// |---|---|---|---|---|---|
/// | `.playing` | P1 slots 0–3 | P1 slots per `faceSlots` | — | Caps Lock latch | Esc after 1 s |
/// | `.paused` | — | — | — | Caps Lock latch | — |
/// | `.levelSelect` | ← → = P1 slots 1 / 2 | P1 slots per `faceSlots` (4–6 all accept) | — | Caps Lock latch | Esc |
/// | `.mainMenu`, `.screens` | arrows | Return | — | Return | Esc |
/// | `.demo` | — | — | — | — | Esc |
///
/// The demo row: grounding C §4's table has "—" for − (keys never end a film, D45 ruling 1), but ruling 17 says −
/// ends a demo, and the ruling wins — − is Esc at once there. + is unbound in a demo (a demo may run through the
/// game's pause too — low confidence, for Ben's gate). F6 (interlace), − / = (volume) and ~ (console) are not on the
/// pad. The original's own gamepad windows (DITL 192/193) are not built; "Set Gamepad Controls…" stays hidden.
///
/// The level select's +: Caps Lock pauses there as in play (grounding A §5.3, `LevelSelect`'s end of frame). While the
/// latch is on the shell (S8a) polls with `.paused`; the + that turns it off brings back `.levelSelect`.
///
/// − "at once" at the demo and the level select is Esc held from the first poll, but it still passes through the
/// game's own Esc hold check (`FrameController.escCheck`): with the Hold Escape pref on, a tap shorter than that hold
/// does nothing (BTX D36 has the same limit).
///
/// A button held across a change of context: the kit's `ShellPadTranslator` ignores it until released whenever its
/// binding changes (the app cannot call its `ignoreHeldButtons()`). So a context that reads held keys and shares a
/// key with a context it is entered from binds that key differently: the level select binds its keys as
/// `.keyAfterHold(code, seconds: 0)` — held on the first poll exactly as `.key`, but unlike play's `.key` (P1's set on
/// the same buttons) and the menu screens' `.key` (the arrows, Esc) — and the demo binds − the same way, unlike the
/// screens' Esc it is entered from. The main menu and the screens share every binding but read key presses, not held
/// keys, so a key held across them presses nothing; play and the screens share the arrows (fresh prefs) the same way,
/// and play is entered only from the level select.
public enum DeimosPadLayout {
    /// Which screen the pad serves this poll (the shell decides it — S8a).
    public enum Context: Sendable, Hashable, CaseIterable {
        /// A session running, not paused.
        case playing
        /// A session paused (the Caps Lock state on).
        case paused
        /// The level select (it reads P1's key set).
        case levelSelect
        /// The main menu (Return = 1 PLAYER). Kept apart from `.screens` so its − can change on its own (question 5).
        case mainMenu
        /// Name entry, the scores, the credits, any dialog.
        case screens
        /// A demo film playing.
        case demo
    }

    public static let returnKey: UInt16 = 0x24
    public static let escapeKey: UInt16 = FrameKeys.escKey
    public static let upArrow: UInt16 = 0x7E
    public static let leftArrow: UInt16 = 0x7B
    public static let rightArrow: UInt16 = 0x7C
    public static let downArrow: UInt16 = 0x7D
    /// How long − must be held in play before it is Esc (a stray press must not end a game; it stacks with the
    /// game's own 16-frame Esc hold).
    public static let escapeHoldSeconds = 1.0

    /// The d-pad → P1's key-set slot (`KeyTable.slotBits`: up, left, right, down).
    public static let dpadSlots: [ShellPadButton: Int] = [.up: 0, .left: 1, .right: 2, .down: 3]

    /// THE face-button assignment (question 5, Ben 2026-11-20: "we may need to work on button mapping" — a remap is a
    /// change here): face button → P1's key-set slot (4 fire air, 5 fire ground, 6 select).
    public static let faceSlots: [ShellPadButton: Int] = [.south: 4, .west: 5, .north: 6, .east: 6]

    /// The layout for one poll: `keySet` = the live prefs key table (only P1's seven slots are read), `context` =
    /// what the shell is showing.
    public static func mapping(keySet: KeyTable, context: Context) -> ShellPadMapping {
        var b: [ShellPadButton: ShellPadBinding] = [:]
        /// P1's slot `i`, when it holds a key `GetKeys` can report (0…0x7F).
        func slot(_ i: Int) -> ShellPadBinding? {
            guard keySet.codes.indices.contains(i), keySet.codes[i] <= 0x7F else { return nil }
            return .key(keySet.codes[i])
        }
        /// `binding` as a 0-second hold: the same key on the same poll, a different binding (see the header).
        func atOnce(_ binding: ShellPadBinding?) -> ShellPadBinding? {
            guard case .key(let code)? = binding else { return binding }
            return .keyAfterHold(code, seconds: 0)
        }
        func faces(_ form: (ShellPadBinding?) -> ShellPadBinding? = { $0 }) {
            for (button, i) in faceSlots { b[button] = form(slot(i)) }
        }
        switch context {
        case .playing:
            for (button, i) in dpadSlots { b[button] = slot(i) }
            faces()
            b[.start] = .capsLockToggle
            b[.back] = .keyAfterHold(escapeKey, seconds: escapeHoldSeconds)
        case .paused:
            b[.start] = .capsLockToggle
        case .levelSelect:
            b[.left] = atOnce(slot(1))
            b[.right] = atOnce(slot(2))
            faces(atOnce)
            b[.start] = .capsLockToggle                 // Caps Lock pauses here too; paused, the shell passes `.paused`
            b[.back] = atOnce(.key(escapeKey))
        case .mainMenu, .screens:
            b[.up] = .key(upArrow)
            b[.left] = .key(leftArrow)
            b[.right] = .key(rightArrow)
            b[.down] = .key(downArrow)
            for button: ShellPadButton in [.south, .east, .west, .north] { b[button] = .key(returnKey) }
            b[.start] = .key(returnKey)
            b[.back] = .key(escapeKey)
        case .demo:
            b[.back] = atOnce(.key(escapeKey))          // ruling 17 over C §4's "—": − ends a demo
        }
        return ShellPadMapping(bindings: b)
    }
}

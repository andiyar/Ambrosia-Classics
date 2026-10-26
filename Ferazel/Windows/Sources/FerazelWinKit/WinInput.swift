import FerazelCore
import Foundation
import HectorInput

// The Windows shell's input (plan WF3, D43 Rulings 5–7, 14): SDL's events in Mac terms (HectorSDL already maps the
// keys to Carbon codes, Ctrl → ⌘, Alt → ⌥, the Windows key → ⌃, D18.5), turned into what the Mac's `FerazelController`
// polls each tick — the held keys (`GetKeys`), Caps Lock, the pointer on the canvas, the button, whether the window
// is active — with the gamepad merged in as the original keys (D37). Foundation + FerazelCore + HectorInput only: no
// SDL types here, so all of it is `swift test`-able on the Mac.

/// The modifier keys, as the Mac names them (Caps Lock = its lock state).
public struct WinModifiers: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let shift = WinModifiers(rawValue: 1 << 0)
    /// Ctrl on Windows.
    public static let command = WinModifiers(rawValue: 1 << 1)
    /// Alt on Windows.
    public static let option = WinModifiers(rawValue: 1 << 2)
    /// The Windows key.
    public static let control = WinModifiers(rawValue: 1 << 3)
    public static let capsLock = WinModifiers(rawValue: 1 << 4)
}

/// One input event in Mac terms (HectorSDL's `HostEvent`, restated so FerazelWinKit needs no SDL). Key codes are
/// Carbon `kVK_*`; mouse coordinates are pixels of the 640×480 canvas, unclamped (the letterbox maps outside it).
public enum WinEvent: Sendable, Hashable {
    case keyDown(keyCode: UInt16, modifiers: WinModifiers, isRepeat: Bool)
    case keyUp(keyCode: UInt16)
    case mouseDown(x: Int, y: Int)
    case mouseUp(x: Int, y: Int)
    case mouseMoved(x: Int, y: Int)
    /// The window's close box, Alt+F4, the taskbar's Close — the Mac's Dock Quit (D40).
    case quit
    case focusLost
    case focusGained
}

/// The keyboard, the pointer and the pad as the game polls them (the Mac's `pollInput` — `ShellView.pollKeyState`
/// with the pad merged — plus `canvasMouse`, `NSEvent.pressedMouseButtons` and `NSApp.isActive`).
@MainActor struct WinInput {
    static let capsLockCode: UInt16 = 0x39
    /// Shift, ⌘, Caps Lock, ⌥, ⌃ (left and right) and fn — the keys the Mac reports through flagsChanged.
    static let modifierKeyCodes: Set<UInt16> = [0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x3F]
    static let canvasWidth = FerazelDriver.width
    static let canvasHeight = FerazelDriver.height

    /// The keyboard's keys held now (Mac codes as SDL reported them; folded at `frontInput`). Caps Lock never.
    private(set) var held: Set<UInt16> = []
    /// The last pointer position seen (canvas pixels, unclamped); nil before the first.
    private(set) var mouse: (x: Int, y: Int)?
    private(set) var button = false
    /// The window has the keyboard (SDL focus) — `FrontInput.active`.
    private(set) var focused = true
    private var padTranslator = ShellPadTranslator()
    /// The last pad translation.
    private(set) var padFrame = ShellPadFrame()

    /// Where a key-down went.
    enum Route: Equatable {
        /// Into the held keys (the game polls it).
        case held
        /// Alt+Enter: full screen on / off (Ruling 14), eaten.
        case fullScreen
        /// A menu command's Ctrl + letter (Ruling 5), eaten — the game never sees the key.
        case shortcut(PauseRun.MenuItem)
        /// A dialog is up: the key is the dialog's.
        case dialog
        /// Caps Lock: a lock, reported through the modifier state only.
        case ignored
    }

    /// A key-down, routed as the Mac's menu bar and window would: Caps Lock is a lock; a modifier key is held (the
    /// Mac's flagsChanged); Alt+Enter toggles full screen; with a dialog up the dialog takes it; a Ctrl + letter the
    /// menus take (`WinShortcuts.take`) is eaten; anything else is held. Repeats route the same way (the caller picks
    /// a shortcut again on a repeat, as AppKit does, and ignores a repeat's full-screen toggle).
    mutating func keyDown(_ code: UInt16, modifiers: WinModifiers, isRepeat: Bool, shortcuts: WinShortcuts,
                          menus: MenuState, modalUp: Bool, dialogUp: Bool) -> Route {
        if code == Self.capsLockCode { return .ignored }
        if Self.modifierKeyCodes.contains(code) {
            held.insert(code)
            return .held
        }
        if WinShortcuts.isFullScreenToggle(keyCode: code, modifiers: modifiers) { return .fullScreen }
        if dialogUp { return .dialog }
        if let item = shortcuts.take(keyCode: code, modifiers: modifiers, menus: menus, modalUp: modalUp) {
            return .shortcut(item)
        }
        held.insert(code)
        return .held
    }

    mutating func keyUp(_ code: UInt16) { held.remove(code) }

    mutating func mouseMoved(x: Int, y: Int) { mouse = (x, y) }

    mutating func mouseDown(x: Int, y: Int) {
        mouse = (x, y)
        button = true
    }

    mutating func mouseUp(x: Int, y: Int) {
        mouse = (x, y)
        button = false
    }

    /// Another window came forward: every key is up (the pad too, from the next poll, and a button still held when
    /// the focus returns is ignored until released — BTX `WinGameDriver`'s rule, HectorShell's inactive app).
    mutating func focusLost() {
        held.removeAll()
        focused = false
        padTranslator.ignoreHeldButtons()
    }

    mutating func focusGained() { focused = true }

    /// A native file dialog came down (plan WF5): the keys and the button held when it went up had their releases
    /// taken by the dialog, so every key and the button are up, and a pad button still held is ignored until
    /// released — no stuck keys. The focus is SDL's to report.
    mutating func flushAfterModal() {
        held.removeAll()
        button = false
        padTranslator.ignoreHeldButtons()
    }

    /// The pointer in canvas coordinates, nil off the 640×480 canvas (or before any was seen).
    var mouseInCanvas: (h: Int, v: Int)? {
        guard let m = mouse, (0..<Self.canvasWidth).contains(m.x), (0..<Self.canvasHeight).contains(m.y) else {
            return nil
        }
        return (h: m.x, v: m.y)
    }

    /// Reads the pad through `mapping` (`FerazelPadLayout` for this poll); without the focus it reads as nothing and
    /// buttons held on return are ignored until released (`ShellView.pollKeyState`). Returns the translation, whose
    /// `pressed` edges the caller delivers (a dialog's Return / Esc).
    mutating func pollPad(_ state: ShellPadState, mapping: ShellPadMapping, now: Double) -> ShellPadFrame {
        let frame = padTranslator.update(focused ? state : .empty, mapping: mapping, now: now)
        if !focused { padTranslator.ignoreHeldButtons() }
        padFrame = frame
        return frame
    }

    /// The tick's `FrontInput`: the keyboard's and the pad's held keys with right-hand modifiers folded to the left
    /// (`FerazelDriver.keyMapCode`), Caps Lock (the lock state) ORed with the pad's latch, the pointer on the canvas,
    /// the button, the focus, and the sounds playing.
    func frontInput(capsLock: Bool, playing: Set<Int16>) -> FrontInput {
        let codes = held.union(padFrame.held).map { FerazelDriver.keyMapCode(Int($0)) }
        return FrontInput(keys: KeyState(pressed: codes), capsLock: capsLock || padFrame.capsLock, mouse: mouseInCanvas,
                          button: button, active: focused, playing: playing)
    }
}

/// The cursor rule (Ruling 14, the Mac's `updateCursor`): the game's hide is honoured only while the pointer is over
/// the canvas, the window has the focus and no dialog or file dialog is up; the pointer comes back anywhere else.
public enum WinCursorRule {
    public static func hidden(wanted: Bool, modalUp: Bool, focused: Bool, overCanvas: Bool) -> Bool {
        wanted && !modalUp && focused && overCanvas
    }
}

import Foundation

/// The keys held down at one poll, as the original's `GetKeys` sees them: Mac virtual key codes
/// (`0x7B` ←, `0x31` Space, …), plus Caps Lock's toggle state (the pause key, Phase 2). The shells
/// deliver it; `DeimosSession.pass` maps it through the prefs key table (`KeyTable`, `DeimosPrefs.keyTable`).
/// ★ LOCKED seam (plan S3).
///
/// Phase 4 (plan S1a SK-a; grounding B §5, A §7, C §3a) adds, by addition only, everything else the shell hands the
/// game: the mouse (`GetMouse`, `Button()` / `StillDown`, mouseDown events), every key event with its auto-repeat
/// mark (`keyDown` / `autoKey`), and the shell's own events (the menu commands, the system's Quit request, suspend
/// and resume, the answer to a question). It is the ONE channel from the shell to the game. The held state
/// (`held`, `capsLock`, `mouse`, `mouseButton`) is sampled at a pass's begin; the event lists are the events since
/// the last pass, in order — the host queues them across `idle` calls and waits, never drops them, except where
/// the original flushes its event queue (`FlushEvents`, the OS queue only: `typed`, `keyEvents`, `mouseDowns`).
public struct HeldKeys: Equatable, Sendable {
    public var held: Set<UInt16>
    public var capsLock: Bool
    /// The key-down Mac charCodes since the last pass, in order, no auto-repeat (`GetOSEvent` keyDown — the
    /// console and the typed keys; the codes are `Console`'s pinned charCodes, `Console.upArrow` … `tildeKey`).
    /// Phase 2 (plan S3).
    public var typed: [UInt8]
    /// The mouse location in the game's 640×480 picture (`GetMouse`, local to the window's port: x right, y down),
    /// nil when the shell has no pointer over the picture to report (headless, or no mouse). Phase 4.
    public var mouse: MousePoint?
    /// The mouse button is down at this poll (`Button()` / `StillDown`). Phase 4.
    public var mouseButton: Bool
    /// The mouseDown events since the last pass, in order, each at its location in the picture (`EventRecord
    /// .where` made local). Phase 4.
    public var mouseDowns: [MousePoint]
    /// Every keyDown AND autoKey event since the last pass, in order (event codes 3 and 5 — name entry and the
    /// controls window take both, B §2c, C §3a). `typed` stays the keyDown-only charCodes the game reads; a shell
    /// fills both. Phase 4.
    public var keyEvents: [KeyEvent]
    /// The shell's own events since the last pass, in order (menu commands, the system's Quit, suspend / resume,
    /// the answer to a question). Phase 4.
    public var events: [ShellEvent]

    public init(held: Set<UInt16> = [], capsLock: Bool = false, typed: [UInt8] = [], mouse: MousePoint? = nil,
                mouseButton: Bool = false, mouseDowns: [MousePoint] = [], keyEvents: [KeyEvent] = [],
                events: [ShellEvent] = []) {
        self.held = held
        self.capsLock = capsLock
        self.typed = typed
        self.mouse = mouse
        self.mouseButton = mouseButton
        self.mouseDowns = mouseDowns
        self.keyEvents = keyEvents
        self.events = events
    }
}

/// A point in the game's 640×480 picture (QuickDraw `Point` made local: `h` across, `v` down). Phase 4.
public struct MousePoint: Equatable, Hashable, Sendable {
    public var h: Int32
    public var v: Int32

    public init(h: Int32, v: Int32) {
        self.h = h
        self.v = v
    }
}

/// One keyDown or autoKey event (`EventRecord.message`: charCode = low byte, virtual key code = `(message >> 8) &
/// 0xFF`, the controls window's capture, C §3a). Phase 4.
public struct KeyEvent: Equatable, Sendable {
    public var charCode: UInt8
    public var keyCode: UInt16
    /// An autoKey event (the key held past the system's repeat delay), not a fresh keyDown.
    public var autoRepeat: Bool

    public init(charCode: UInt8, keyCode: UInt16, autoRepeat: Bool = false) {
        self.charCode = charCode
        self.keyCode = keyCode
        self.autoRepeat = autoRepeat
    }
}

/// What the shell tells the game outside the keyboard and mouse (Phase 4; B §5, C §5, ruling 12, question 8).
public enum ShellEvent: Equatable, Sendable {
    /// The app menu's "About Deimos Rising…" was chosen (ruling 12: opens the credits).
    case aboutChosen
    /// File ▸ Quit / ⌘Q was chosen (`10023368`; the menu's quit flag b8).
    case quitChosen
    /// The system asked the app to quit (the Quit AppleEvent handler `10049c70` → `FUN_10022ed0`).
    case quitRequested
    /// The app went to the background (the suspend handler `10023db4`).
    case suspend
    /// The app came back (the resume handler `10023e10`).
    case resume
    /// The answer to the question `ShellRequest.ask` put (question 8).
    case answer(QuestionButton)
}

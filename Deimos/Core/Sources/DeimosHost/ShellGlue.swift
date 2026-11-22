import Foundation
import DeimosCore

// Phase 4 S8a AW: the few decisions the app makes that a test can reach — which gamepad layout the screen on top
// takes, which character a pad key types, and how a decoded picture becomes the game's 16-bit pixels. The AppKit
// side (`Deimos/App`) only reads the system and calls these.

/// Which gamepad layout (`DeimosPadLayout.Context`) the screen on top takes, or nil for the pad switched off (the
/// app then assigns an empty mapping). The S7 handoff's items 2 and 4, the seat's ruling for the controls window.
public enum PadContext {
    /// - `top`: the front end's top screen (`FrontEnd.screens.last`; nil before the first pass or once finished).
    /// - `levelSelectPaused`: the level select's own pause is up (`FrontEnd.levelSelectPaused`).
    /// - `game`: the running game, if one runs — whether it plays a film, whether its pause is up.
    ///
    /// The level select → `.levelSelect`, or `.paused` while its pause is up (plus is the latch there too). A running
    /// game under start/return → `.demo` for a film (a demo or the Last Film: minus ends it), `.paused` while paused,
    /// else `.playing`; start/return with no game running (its fades) → `.screens`. The menu → `.mainMenu`. The controls
    /// window → nil: the pad is off there, so a pad press can never be captured as a key binding. Every other screen
    /// (the boot, the scores, name entry, the credits, the films screen, the configuration window) → `.screens`.
    public static func choose(top: FrontEndScreen.Kind?, levelSelectPaused: Bool,
                              game: (film: Bool, paused: Bool)?) -> DeimosPadLayout.Context? {
        switch top {
        case .mainMenu?:
            return .mainMenu
        case .levelSelect?:
            return levelSelectPaused ? .paused : .levelSelect
        case .startReturn?:
            guard let game else { return .screens }
            if game.film { return .demo }
            return game.paused ? .paused : .playing
        case .controlsDialog?:
            return nil
        case .boot?, .scores?, .nameEntry?, .credits?, .films?, .configDialog?, nil:
            return .screens
        }
    }
}

extension DeimosDriver {
    /// The gamepad layout for this poll (`PadContext.choose` on the front end as it stands), nil = the pad is off.
    public var padContext: DeimosPadLayout.Context? {
        let fe = frontEnd
        var game: (film: Bool, paused: Bool)?
        if fe.state.gameRunning, let s = fe.session {
            game = (film: s.start.film != nil, paused: s.controller.paused)
        }
        return PadContext.choose(top: fe.screens.last, levelSelectPaused: fe.levelSelectPaused, game: game)
    }

    /// The live key table the play layout reads (P1's seven slots): the running game's, else the front end's.
    public var padKeySet: KeyTable { KeyTable(prefs: frontEnd.livePrefs) }
}

/// The app's background pump (Phase 4 S8a AW; `osx-build.md` D10): the system asked the app to quit while it was in
/// the background, so the app runs the driver unseen — with no live input (nothing held, the mouse button up, no
/// position, Caps Lock as last seen while active) — and asks this, after every pumped `idle`, whether to stop. It
/// stops when:
/// - the front end has finished (the shell was asked to quit);
/// - the front end holds the request for the menu (`FrontEnd.quitRequestPending`: the screens other than the menu
///   and the level select), or the driver holds a running game for the resume (`gameHeldWhileSuspended`, D11: the
///   request waits in its queue, to be held for the menu by the game's first pass after the return);
/// - the request was taken (the quit flag b8) by a screen that does not act on it unseen — the level select reads
///   the flag nowhere (D10), so it would run forever. The menu (its quit flash clears the flag, then its fade and the
///   shell's quit) and start/return (a game the pause let go on b8: the game's end, then the menu) do act on it, so
///   the pump runs on through them;
/// - `maxTurns` pumped `idle` calls have run, whatever the state (a host wait on a click or a key never ends with no
///   live input).
public struct BackgroundQuitPump {
    /// The hard bound: 10 seconds of the app's 1/240 s idle timer.
    public static let maxTurns = 2_400
    /// Pumped `idle` calls so far.
    public private(set) var turns = 0

    public init() {}

    /// After one pumped `idle` of `driver`: true when the pump stops (see the type's comment).
    public mutating func shouldStop(after driver: DeimosDriver) -> Bool {
        turns += 1
        let fe = driver.frontEnd
        if turns >= Self.maxTurns || fe.isFinished || fe.quitRequestPending || driver.gameHeldWhileSuspended {
            return true
        }
        if fe.state.quit {
            switch fe.screens.last {
            case .mainMenu?, .startReturn?: return false
            default: return true
            }
        }
        return false
    }
}

/// The character a pad key "types" (S8a): a pad button presses a key the original reads, and a key-down on the
/// Mac carries its charCode, so the screens that read key events (the menu, the scores, name entry, the credits)
/// see the pad's Return, Esc and arrows as the keyboard's. Only the keys a pad layout binds outside play have one;
/// the modifier keys (P1's fresh fire keys, Command and Option) type nothing — on the keyboard they make no key-down
/// either — and a key not in the table makes no key event (it is still held).
public enum PadKeys {
    /// Mac virtual key code → classic Mac charCode (the codes `MainMenu`, `NameEntry` and the console switch on).
    public static let charCodes: [UInt16: UInt8] = [
        0x24: 0x0D,     // Return
        0x4C: 0x03,     // keypad Enter
        0x35: 0x1B,     // Esc
        0x30: 0x09,     // Tab
        0x31: 0x20,     // Space
        0x33: 0x08,     // Delete (backspace)
        0x7E: 0x1E,     // ↑
        0x7D: 0x1F,     // ↓
        0x7B: 0x1C,     // ←
        0x7C: 0x1D,     // →
    ]

    /// The key event a pad key-down makes (never an auto-repeat: a held pad button repeats nothing, the S7 handoff's
    /// item 3), or nil when the key types no character.
    public static func keyEvent(forPadKey keyCode: UInt16) -> KeyEvent? {
        guard let c = charCodes[keyCode] else { return nil }
        return KeyEvent(charCode: c, keyCode: keyCode, autoRepeat: false)
    }
}

/// When the full-screen game takes the keyboard back (Ben's first playtest, 2026-11-22). A quick double tap of left
/// Option (the bomb) is another app's global shortcut: its non-activating panel takes the keyboard without making the
/// game inactive, and opens hidden behind the full-screen window. From then on no key-down or key-up reaches the app
/// (the arrows, Space and Esc go dead; the modifier fire keys still work) until a click makes the window key again.
/// So while the app is active, in full screen, not suspended and showing none of its own questions, a game window that
/// is not key, or whose first responder is not the game view, takes the keyboard back. Windowed mode is left alone on
/// purpose: there the other app's panel is visible, and the player may want it.
///
/// A reclaim that does not take is tried again every quarter second, but only `maxAttempts` times (about two seconds)
/// after the window was last key with the view first responder; then the game stops trying until that is true again.
/// Accepted limit: on a Mac with a second display, a panel another app opens there while the game is full screen
/// loses the keyboard to the game for up to two seconds of tries, then keeps it.
///
/// Losing key drops every key the view held (HectorKit's `ShellView` releases them all), so a key the player holds
/// across the steal — an arrow, or Command held to fire, whose code comes back only with a re-press — would stay dead.
/// So for `recoveryTicks` after each attempt, any of the game's bound keys that the hardware reports down and the view
/// does not hold is picked up as a recovered key. A recovered key then stays held until the hardware reads it up,
/// however long that is (Command never repeats, so the view would never get it back), or until the view holds it
/// again from a repeat or a fresh press, after which the view's own key-up releases it (`stepRecovered`).
public enum KeyboardFocus {
    /// The wait between attempts, in Mac ticks (a quarter second at 60): a reclaim that does not take is retried
    /// without asking the window server every poll.
    public static let retryTicks: UInt32 = 15
    /// The attempts made since the window was last key with the view first responder after which the game gives up
    /// (about two seconds of tries at `retryTicks`).
    public static let maxAttempts = 8
    /// How long after an attempt new recovered keys are picked up from the hardware, in Mac ticks (two seconds at 60:
    /// longer than the slowest initial key-repeat delay). Keys already recovered outlast it (`stepRecovered`).
    public static let recoveryTicks: UInt32 = 120

    /// - `ticksSinceLastAttempt`: Mac ticks since the last reclaim was tried, nil when none has been.
    /// - `attemptsSinceKey`: attempts made since the window was last key with the view first responder.
    ///
    /// True when the app should take the keyboard back now (see the type's comment).
    public static func shouldReclaim(appActive: Bool, fullScreen: Bool, suspended: Bool, questionUp: Bool,
                                     windowIsKey: Bool, firstResponderIsView: Bool,
                                     ticksSinceLastAttempt: UInt32?, attemptsSinceKey: Int) -> Bool {
        guard appActive, fullScreen, !suspended, !questionUp else { return false }
        guard !windowIsKey || !firstResponderIsView else { return false }
        guard attemptsSinceKey < maxAttempts else { return false }
        if let since = ticksSinceLastAttempt, since < retryTicks { return false }
        return true
    }

    /// True while new recovered keys are picked up from the hardware: there was an attempt, fewer than
    /// `recoveryTicks` ago. The caller measures `ticksSinceLastAttempt` with wrapping subtraction (`now &- last`), so
    /// the Mac tick counter rolling over still gives the small true difference.
    public static func inRecovery(ticksSinceLastAttempt: UInt32?) -> Bool {
        guard let since = ticksSinceLastAttempt else { return false }
        return since < recoveryTicks
    }

    /// One step of the recovered keys (once per Mac tick). Each key of `recovered` that the view does not hold again
    /// stays while `isDown` still reports it down; and only when `inRecovery`, each code of `bound` that the view does
    /// not hold and `isDown` reports down joins. `isDown` is asked at most once per code, never about a code in
    /// `viewHeld`, and not at all when nothing is recovered and recovery is over.
    public static func stepRecovered(recovered: Set<UInt16>, viewHeld: Set<UInt16>, bound: [UInt16], inRecovery: Bool,
                                     isDown: (UInt16) -> Bool) -> Set<UInt16> {
        var asked: Set<UInt16> = []
        var out: Set<UInt16> = []
        for code in recovered where !viewHeld.contains(code) {
            asked.insert(code)
            if isDown(code) { out.insert(code) }
        }
        if inRecovery {
            for code in bound where !viewHeld.contains(code) && !asked.contains(code) {
                asked.insert(code)
                if isDown(code) { out.insert(code) }
            }
        }
        return out
    }
}

/// A picture the shell decoded (HectorKit's PICT path: RGBA, 8 bits a channel, row 0 at the top) as the game's
/// x1R5G5B5 pixels (`ShellPicture`, ruling 9): each channel's top five bits, as `DrawPicture` into a 16-bit GWorld
/// keeps them; alpha is dropped (the top bit stays 0). nil when `rgba` is not `width × height × 4` bytes.
public enum ShellPictures {
    public static func picture(width: Int, height: Int, rgba: [UInt8]) -> ShellPicture? {
        guard width >= 0, height >= 0, rgba.count == width * height * 4 else { return nil }
        var pixels = [UInt16](repeating: 0, count: width * height)
        for i in pixels.indices {
            let r = UInt16(rgba[4 * i] >> 3), g = UInt16(rgba[4 * i + 1] >> 3), b = UInt16(rgba[4 * i + 2] >> 3)
            pixels[i] = r << 10 | g << 5 | b
        }
        return ShellPicture(width: width, height: height, pixels: pixels)
    }
}

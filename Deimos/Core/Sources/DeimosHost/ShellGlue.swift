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

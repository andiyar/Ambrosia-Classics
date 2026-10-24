import Foundation

/// What the original asked of the Mac outside the game screen (`HideCursorSafe`, the menu bar) — plan S3, LOCKED.
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
    case hideMenuBar
    case showMenuBar
    /// W4 (`LevelFlow`, D33): a session not hosted by `LevelRun` (a directly built one — Core tests) ended at a level
    /// exit: the level the exit unlocks (`LevelFlow.next`), else the current level. The app's sessions are hosted by
    /// `LevelRun` (A1a), whose level end goes to `GameFlow`; the app ignores this request.
    case loadLevel(Int)
    /// W4: a directly built session's game loop ended with G+4 < 1 (M l. 5302–5306) — `.DeathEffect`. Hosted sessions
    /// leave it to `LevelRun` (its `.DeathEffect` steps through `LevelServices.deathEffectStep`); the app ignores it.
    case deathEffect

    // MARK: Phase 3 (FE0 adds every case; F1b, S1, P1, A1b use them)

    /// Run a modal dialog; the answer comes back through `GameFlow.dialogDone`.
    case dialog(FerazelDialog)
    /// Standard File's `CustomPutFile` (DITL 1003) — the App shows a save panel; the answer comes back through
    /// `GameFlow.fileDone`.
    case putFile(PutFileRequest)
    /// Standard File's `CustomGetFile` (DITL 1500) with this prompt; the answer comes back through `GameFlow.fileDone`.
    case getFile(prompt: String)
    /// `ExitToShell` after the original's quit sequence.
    case quit
    /// What the menu bar shows and accepts from now on.
    case showMenuBarItems(MenuState)
}

/// A `CustomPutFile` request (`.SaveSG`, M l. 41179ff): the prompt ("Please name your saved game."), the default name
/// (already incremented, `SaveName.increment`), and DITL 1003 item 13's static text.
public struct PutFileRequest: Equatable, Sendable {
    public var prompt: String
    public var defaultName: String
    public var message: String

    public init(prompt: String, defaultName: String, message: String) {
        self.prompt = prompt
        self.defaultName = defaultName
        self.message = message
    }
}

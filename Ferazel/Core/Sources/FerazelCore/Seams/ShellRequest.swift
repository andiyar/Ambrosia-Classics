import Foundation

/// What the original asked of the Mac outside the game screen (`HideCursorSafe`, the menu bar) — plan S3, LOCKED.
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
    case hideMenuBar
    case showMenuBar
    /// W4 (◇ `LevelFlow`, D33): load level n — the shell rebuilds the session with the old one's `rngSeed` and
    /// `carry`, and the renderer. A level exit asks for the level it unlocks (Phase 2: 1…2, else the current level);
    /// `FerazelSession.deathEffectDone()` asks for the current level.
    case loadLevel(Int)
    /// W4: the game loop ended with G+4 < 1 (M l. 5302–5306) — run `.DeathEffect` (E2's `DeathEffect.frame(step:on:)`),
    /// then call `FerazelSession.deathEffectDone()`.
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

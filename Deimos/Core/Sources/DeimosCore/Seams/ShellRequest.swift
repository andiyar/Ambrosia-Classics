import Foundation

/// Something only the shell can do. ★ LOCKED seam (plan S3).
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
    /// The app menu's "About Deimos Rising…" item on or off (`FUN_10049320(1)` / `(0)`, `1002352c..10023550`;
    /// ruling 12: disabled during a game). Phase 4.
    case aboutEnabled(Bool)
    /// Quit the app now (the menu's exit → shutdown `FUN_10000630`). Phase 4.
    case quit
    /// Write the Last Film (`FUN_100095b0(film, 'last')`, `10005b00..10005b18`; ruling 7): the film file's bytes.
    /// Phase 4.
    case saveLastFilm([UInt8])
    /// Put a two-button question (question 8: the "erase all scores?" alert); the answer comes back as
    /// `ShellEvent.answer` in `HeldKeys.events`. Phase 4.
    case ask(ShellQuestion)
}

/// A two-button question the shell puts to the player (question 8 default: a normal macOS alert). Phase 4.
public struct ShellQuestion: Equatable, Sendable {
    public var message: String
    public var firstButton: String
    public var secondButton: String

    public init(message: String, firstButton: String, secondButton: String) {
        self.message = message
        self.firstButton = firstButton
        self.secondButton = secondButton
    }
}

/// Which of a `ShellQuestion`'s two buttons the player chose. Phase 4.
public enum QuestionButton: Equatable, Sendable {
    case first
    case second
}

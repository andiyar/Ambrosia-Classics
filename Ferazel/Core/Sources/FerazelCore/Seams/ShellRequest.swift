import Foundation

/// What the original asked of the Mac outside the game screen (`HideCursorSafe`, the menu bar) — plan S3, LOCKED.
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
    case hideMenuBar
    case showMenuBar
}

import Foundation

/// Something only the shell can do. ★ LOCKED seam (plan S3).
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
}

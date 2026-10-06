import Foundation

/// The keys held down at one poll, as the original's `GetKeys` sees them: Mac virtual key codes
/// (`0x7B` ←, `0x31` Space, …), plus Caps Lock's toggle state (the pause key, Phase 2). The shells
/// deliver it; `DeimosSession.pass` maps it through the prefs key table (`KeyTable`, `DeimosPrefs.keyTable`).
/// ★ LOCKED seam (plan S3).
public struct HeldKeys: Equatable, Sendable {
    public var held: Set<UInt16>
    public var capsLock: Bool

    public init(held: Set<UInt16> = [], capsLock: Bool = false) {
        self.held = held
        self.capsLock = capsLock
    }
}

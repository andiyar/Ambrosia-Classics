import Foundation

/// What the menu bar shows and accepts (plan S3, FE0; LOCKED; A1b honours it): the original processes menu events only
/// in the main-menu loop and the pause loop (`menusLive`); the Music / Sound Effects items carry checkmarks.
public struct MenuState: Equatable, Sendable {
    /// The main-menu or the pause loop is running.
    public var menusLive: Bool
    public var paused: Bool
    /// prefs+0x0c.
    public var musicOn: Bool
    /// prefs+0x0b.
    public var soundOn: Bool

    public init(menusLive: Bool, paused: Bool, musicOn: Bool, soundOn: Bool) {
        self.menusLive = menusLive
        self.paused = paused
        self.musicOn = musicOn
        self.soundOn = soundOn
    }
}

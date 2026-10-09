import Foundation

/// The game-globals block `G` (`_DAT_1009ffc0`; engine §9) — Phase 1 keeps the start values the status bar and the
/// player read. `.InitGameGlobals @ 10001498` (decompile l. 582; tail stores l. 799–812): `+0xc = +0xa = 0x230`
/// (max magic, max health), `+4` health = `+6` breath = `+0xa`, `+8` 0, `+0xe` magic = `+0xc`, `+0x10` coins 0,
/// `+0x12 = 3`, `+0x172` selected slot 0, `+0x14` 0, `+0` score 0. `+0x16` (start facing) is the header's 0x26c8,
/// copied by `.NewGame` before `.GameLoop` (l. 5821).
public struct GameGlobals: Equatable, Sendable {
    /// `+0x00`.
    public var score: Int32 = 0
    /// `+0x04`.
    public var health: Int16 = 0x230
    /// `+0x06` (oxygen).
    public var breath: Int16 = 0x230
    /// `+0x08` suffocation countdown.
    public var suffocation: Int16 = 0
    /// `+0x0a`.
    public var maxHealth: Int16 = 0x230
    /// `+0x0c`.
    public var maxMagic: Int16 = 0x230
    /// `+0x0e`.
    public var magic: Int16 = 0x230
    /// `+0x10`.
    public var coins: Int16 = 0
    /// `+0x12` (write-only, save-continue §8.1).
    public var unread12: Int16 = 3
    /// `+0x14` gold-Xichron counter.
    public var xichrons: Int16 = 0
    /// `+0x16` start facing (≠ 0 → left).
    public var startFacing: Int16
    /// `+0x172` selected inventory slot.
    public var selectedSlot: Int16 = 0

    /// `.InitGameGlobals`' start values, `+0x16` from the level header (`.NewGame`).
    public init(header: LevelHeader) {
        startFacing = Int16(header.startFacingLeft)
    }

    /// What `.UpdateStatusBar` draws.
    public func statusBar(levelName: String) -> StatusBarState {
        StatusBarState(score: Int(score), coins: Int(coins), health: Int(health), breath: Int(breath),
                       magic: Int(magic), levelName: levelName, selectedSlot: Int(selectedSlot))
    }
}

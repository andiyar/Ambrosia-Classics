import Foundation

/// The values `.UpdateStatusBar(1, 0, 0)` draws into the 640×88 status bar (engine §3; plan S3).
public struct StatusBarState: Equatable, Sendable {
    public var score: Int
    public var coins: Int
    public var health: Int
    public var breath: Int
    public var magic: Int
    public var levelName: String
    public var selectedSlot: Int

    public init(score: Int = 0, coins: Int = 0, health: Int = 0, breath: Int = 0, magic: Int = 0, levelName: String = "",
                selectedSlot: Int = 0) {
        self.score = score
        self.coins = coins
        self.health = health
        self.breath = breath
        self.magic = magic
        self.levelName = levelName
        self.selectedSlot = selectedSlot
    }
}

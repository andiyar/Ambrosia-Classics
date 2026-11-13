import Foundation

/// The replay trace (plan G4.3, S6): one row per ticked pass, recorded by H2's `ReplayTrace` from the
/// session's public state. C7 declares the row shape only. ★ LOCKED (plan S2).
public struct TickTrace: Equatable, Sendable {
    public struct Row: Equatable, Sendable {
        /// G+0x1c at the end of the tick.
        public var gameTime: Int32
        /// P1's film cursor (−1 when no film plays).
        public var cursor: Int32
        /// P1: life state (+0xc6), decoded score, lives, displayed shield, money, multiplier.
        public var p1State: UInt8
        public var p1Score: Int32
        public var p1Lives: Int32
        public var p1Shield: Float
        public var p1Money: Int32
        public var p1Multiplier: UInt8
        /// `MSLRandom.draws` — rand() calls since srand.
        public var draws: UInt64
        /// Pool entities in use; active groups.
        public var entities: Int
        public var groups: Int
        /// The scroll's window top (map row).
        public var scrollTop: Int32
        /// The scroll is paused (speed 0).
        public var paused: Bool
        /// G+0x39.
        public var levelEnding: Bool

        public init(gameTime: Int32, cursor: Int32, p1State: UInt8, p1Score: Int32, p1Lives: Int32,
                    p1Shield: Float, p1Money: Int32, p1Multiplier: UInt8, draws: UInt64, entities: Int,
                    groups: Int, scrollTop: Int32, paused: Bool, levelEnding: Bool) {
            self.gameTime = gameTime
            self.cursor = cursor
            self.p1State = p1State
            self.p1Score = p1Score
            self.p1Lives = p1Lives
            self.p1Shield = p1Shield
            self.p1Money = p1Money
            self.p1Multiplier = p1Multiplier
            self.draws = draws
            self.entities = entities
            self.groups = groups
            self.scrollTop = scrollTop
            self.paused = paused
            self.levelEnding = levelEnding
        }
    }

    public var rows: [Row] = []

    public init() {}
}

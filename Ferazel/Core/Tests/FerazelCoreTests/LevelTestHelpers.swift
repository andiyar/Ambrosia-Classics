import XCTest
@testable import FerazelCore

/// Inserts the level exit of record `rec` (its Setup) and puts the player inside its rect, then runs the player pass's
/// contact (`HitPlayerSprite.hit`) — shared by `LevelFlowTests` and `GameFlowGameTests` (F1b: moved out of
/// `LevelFlowTests`).
func touchExit(_ s: FerazelSession, record rec: Int) throws {
    let c = SetupFaces.Context(level: s.level, playerX: 0)
    let e = try SetupFaces.setup(s.level.placements[rec], context: c)
    let exit = s.world.active.insert(e.slot)
    let pid = try XCTUnwrap(s.world.playerID)
    s.world.active.update(id: pid) { $0.x = e.slot.x; $0.y = e.slot.y }
    HitPlayerSprite.hit(s.world, player: pid, other: exit)
}

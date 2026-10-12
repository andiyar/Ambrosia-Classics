import XCTest
import HectorResources
@testable import FerazelCore

/// P1a (docs/plans/2026-10-10-ferazel-phase2.md): the player skeleton — `.SetupPlayerSprite @ 1004aefc` +
/// `.ClearPlayerVars @ 1004aa48`, `.HandlePlayerSprite @ 1004d5fc`'s row order, gravity / terminal / submerged brake,
/// `.HandleKeys @ 10052ac0`'s jump impulse, sustain and counter rules. Synthetic 16×16 grid with a flat FG kind-3
/// floor on row 12 (surface Y + 16 = 400); the tile callback is a test double that hands FG cells to `.WallBounce`
/// the way `.HitPlayerTileSprite` does (`&sStack_72` = the hot rect's vertical centre, factor 0, the `+0x34` rect;
/// decompile l. 48259) — P2 replaces it with the real callback. Numbers: plan P1a (probe A `jumpcycle.out`,
/// `kinematics.out`) and the hand arithmetic next to each assertion.
final class PlayerMotionTests: XCTestCase {

    /// The player stands with his hot-rect bottom (`y + 0x55`) on the floor surface 400.
    private let standY = 400 - 0x55

    private func world(floor: Bool = true) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if floor { for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 } }     // tile 3 (cell = tile + 1), kind = tile
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    /// The test double for `.HitPlayerTileSprite` (P2): FG cells → `.WallBounce`, nothing else.
    private let floorHit: TileHit = { solver, id, cell, kind, layer in
        guard layer == .foreground, let s = solver.world.active.sprite(id: id) else { return }
        var p = cell
        let r = s.hotRect
        solver.wallBounce(id, kind: kind, tile: &p, vCentre: r.top + ((r.bottom - r.top) >> 1), factor: 0, rect: r,
                          bounce: false)
    }

    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        Player.handle(world: w, keys: keys, solver: solver, tileHit: floorHit)
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// Spawn on the floor and settle: frame 1 lands (`+0xce` 3), frame 2 refills the jump counter to 6.
    private func standing(_ w: SpriteWorld) -> TileSolver {
        _ = Player.spawn(world: w, x: 100, y: standY)
        let solver = TileSolver(world: w)
        frame(w, solver)
        frame(w, solver)
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)
        XCTAssertEqual(player(w).groundKind, 3)
        XCTAssertEqual(w.player.jumpCounter, 6)
        return solver
    }

    func testJumpImpulseAtRestWalkRun() throws {
        // J − 0xc80 − ((|vx| + 0x4e2) >> 3), J = 0: rest −3200 − 156 = −3356; walk max 1900: −3200 − 393 = −3593;
        // run max 3200: −3200 − 556 = −3756 (raw `100541c4`/`10054240 addi r0,r3,0x4e2`).
        for (vx, expected) in [(Int32(0), Int32(-3356)), (1900, -3593), (3200, -3756)] {
            let w = try world()
            _ = standing(w)
            w.active.update(id: w.playerID!) { $0.vx = vx }
            HandleKeys.run(world: w, keys: .jump, ridden: nil)
            XCTAssertEqual(player(w).vy, expected, "vx \(vx)")
            XCTAssertEqual(w.player.jumpCounter, 5)
            XCTAssertEqual(w.player.exertion, 8)
            XCTAssertEqual(w.player.postJumpGuard, 2)
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 414, priority: 1, volume: 0x9c)])
        }
    }

    func testFullJumpApex() throws {
        // Held 6 frames: −2916 (= −3356 + 440) × 6, then +440/frame: −2476 … −276 on frame 12, +164 on frame 13.
        let w = try world()
        let solver = standing(w)
        let y0 = player(w).y256
        var dy: [Int32] = []
        for f in 1...14 {
            frame(w, solver, f <= 6 ? .jump : [])
            dy.append(player(w).y256 - y0)
        }
        XCTAssertEqual(dy.min(), -25752)                               // −25752 / 256 = 100.59 px
        XCTAssertEqual(dy.firstIndex(of: -25752).map { $0 + 1 }, 12)
        XCTAssertEqual(dy[0], -2916)
        XCTAssertEqual(dy[5], -2916 * 6)
        XCTAssertEqual(player(w).vy, 164 + 440)
    }

    func testTapJumpApex() throws {
        // Held 1 frame: −2916, then −2476 … −276 (frame 7) = −11172 (43.64 px); frame 8 descends (+164).
        let w = try world()
        let solver = standing(w)
        let y0 = player(w).y256
        var dy: [Int32] = []
        for f in 1...9 {
            frame(w, solver, f == 1 ? .jump : [])
            dy.append(player(w).y256 - y0)
        }
        XCTAssertEqual(dy.min(), -11172)
        XCTAssertEqual(dy[6], -11172)
        XCTAssertGreaterThan(dy[7], dy[6])                              // first descending frame: 8
        XCTAssertEqual(dy[7] - dy[6], 164)
        XCTAssertEqual(w.player.jumpCounter, 0)                         // released in the air: the else-refill → 0
    }

    func testNoAutoRepeatOrMidAirSpinRefill() throws {
        // JUMP held through the whole arc and the landing: the arm is taken every frame, so the else-refill never
        // runs — the counter stays 0 on the ground until JUMP is released (main l. 47823–47832).
        let w = try world()
        let solver = standing(w)
        for _ in 1...40 { frame(w, solver, .jump) }
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)              // landed again
        XCTAssertEqual(player(w).groundKind, 3)
        XCTAssertEqual(w.player.jumpCounter, 0)
        frame(w, solver, [])
        XCTAssertEqual(w.player.jumpCounter, 6)                         // released on the ground: refill 6
        // DOWN + JUMP in the air with counter 3: the DOWN block sets the spin first (0 < counter < 6, raw
        // `10053cec..10053d28`), so the refill arm's `spin == 0` test (raw `10053fc4`) fails — no refill, the
        // sustain runs and the counter goes 3 → 2 (Bank correction A2).
        frame(w, solver, .jump)                                          // 6 → 5
        frame(w, solver, .jump)                                          // 5 → 4
        frame(w, solver, .jump)                                          // 4 → 3
        XCTAssertEqual(w.player.jumpCounter, 3)
        frame(w, solver, [.down, .jump])
        XCTAssertTrue(w.player.spin)
        XCTAssertEqual(w.player.jumpCounter, 2)
        XCTAssertEqual(w.player.spinCooldown, 0)
        XCTAssertTrue(w.player.cues.contains(PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba)))
    }

    func testTerminalVelocityAndZeroBump() throws {
        // Free fall (no floor): vy 1 + 440k; frame 27 → 11881, frame 28 → 12321 → clamped 12000.
        let w = try world(floor: false)
        let id = Player.spawn(world: w, x: 100, y: 0)
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vy = 1 }
        var vys: [Int32] = []
        for _ in 1...29 {
            frame(w, solver)
            vys.append(player(w).vy)
        }
        XCTAssertEqual(vys[26], 11881)
        XCTAssertEqual(vys.firstIndex(of: 12000).map { $0 + 1 }, 28)
        XCTAssertEqual(vys[28], 12000)
        // −440 + 440 = 0 → 1 (raw: `if vy == 0 → 1` after the clamp).
        w.active.update(id: id) { $0.vy = -440 }
        frame(w, solver)
        XCTAssertEqual(player(w).vy, 1)
    }

    func testSubmergedBrake() throws {
        // Fully submerged (`+0x11c == 1`, set by last frame's water pass), airborne, not spinning: gravity 0x50 and
        // vy 2000 > 0x6a4 → 2000 − 0x200 = 1488 (raw `1004daec..1004daf8`); the frame's gravity add → 1568.
        let w = try world(floor: false)
        let id = Player.spawn(world: w, x: 100, y: 0)
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vy = 2000; $0.waterRow = 1 }
        Player.selectGravity(world: w, id: id)
        XCTAssertEqual(player(w).vy, 1488)
        XCTAssertEqual(player(w).gravity, 0x50)
        XCTAssertEqual(w.player.swim, 1)                                // swim entry (liquid kind ≠ 5)
        w.active.update(id: id) { $0.vy = 2000; $0.waterRow = 1 }
        w.player.swim = 0
        frame(w, solver)
        XCTAssertEqual(player(w).vy, 1568)
    }
}

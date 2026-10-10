import XCTest
import HectorResources
@testable import FerazelCore

/// F3 (docs/plans/2026-10-10-ferazel-phase2.md): the tile solver — `.SeparateFromTiles2 @ 1003c804`,
/// `.WallBounce @ 10037a54`, `.WallBounceBG @ 1003a2e8`, `.ApplySpeedAndSeparateFromTiles @ 1004b83c`,
/// `.AccelerateBasedOnSlope @ 10037350` (physics §2–§3, player-states-2 §9–§14). Synthetic 8×8 tile grids: FG kind =
/// tile number (so each kind's `perTile[k]` rect is its natural one), the cell under test at X 64, Y 96 unless named.
/// Expected numbers are hand arithmetic from the dump, shown next to each assertion.
final class TileSolverTests: XCTestCase {

    /// The mover rect (top, left, bottom, right): 16 wide, 32 tall; centred column = left 8, right 9.
    private let tall = IdleSprites.Rect(top: 0, left: 0, bottom: 32, right: 16)

    private func solver(fg: [(col: Int, row: Int, cell: UInt16)] = [], bgAll: UInt16 = 0,
                        bgKinds: [Int: Int] = [:]) throws -> TileSolver {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let world = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fgCells = [UInt16](repeating: 0, count: 64)
        for t in fg { fgCells[t.row * 8 + t.col] = t.cell }
        var bk = [Int](repeating: 0, count: 0x60)
        for (t, k) in bgKinds { bk[t] = k }
        let grid = TileGrid(fg: TileMap(width: 8, height: 8, cells: fgCells),
                            bg: TileMap(width: 8, height: 8, cells: [UInt16](repeating: bgAll, count: 64)),
                            fgKinds: Array(0..<0x60), bgKinds: bk)
        return TileSolver(world: world, grid: grid)
    }

    private func mover(_ t: TileSolver, x: Int, y: Int, vx: Int32 = 0, vy: Int32 = 0,
                       rect: IdleSprites.Rect? = nil) -> Int {
        let r = rect ?? tall
        return t.world.newSprite(type: 0x45, x: x, y: y, layer: 10, handler: .player) {
            $0.hotRect = r
            $0.vx = vx
            $0.vy = vy
        }!
    }

    private func bounce(_ t: TileSolver, _ id: Int, kind: Int, at pos: TilePos = TilePos(x: 64, y: 96)) -> Bool {
        var p = pos
        return t.wallBounce(id, kind: kind, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false)
    }

    private func sprite(_ t: TileSolver, _ id: Int) -> SpriteSlot { t.world.active.sprite(id: id)! }

    func testKind3FloorLandsOnlyFalling() throws {
        let t = try solver()
        // Falling: bottom 84 + 32 = 116 > Y+16 = 112 → vy 0, `+0xce` 3, bottom on 112 (y 80), 24.8 re-synced.
        let a = mover(t, x: 64, y: 84, vy: 0x300)
        XCTAssertTrue(bounce(t, a, kind: 3))
        XCTAssertEqual(sprite(t, a).y, 80)
        XCTAssertEqual(sprite(t, a).y256, 80 << 8)
        XCTAssertEqual(sprite(t, a).vy, 0)
        XCTAssertEqual(sprite(t, a).groundKind, 3)
        // Rising: no landing (`+0xce` stays 0, vy kept) — the position store is outside the `vy > 0` test
        // (decompile case 3), so the bottom is still put on Y+16.
        let b = mover(t, x: 64, y: 84, vy: -0x300)
        XCTAssertTrue(bounce(t, b, kind: 3))
        XCTAssertEqual(sprite(t, b).groundKind, 0)
        XCTAssertEqual(sprite(t, b).vy, -0x300)
        XCTAssertEqual(sprite(t, b).y, 80)
    }

    func testKind0WallPush() throws {
        let t = try solver()
        // Left edge 70 < X+16 = 80 (real left: kind 0 is not centred) → vx 0, x = 80; no ground kind.
        let a = mover(t, x: 70, y: 96, vx: -0x200)
        XCTAssertTrue(bounce(t, a, kind: 0))
        XCTAssertEqual(sprite(t, a).x, 80)
        XCTAssertEqual(sprite(t, a).x256, 80 << 8)
        XCTAssertEqual(sprite(t, a).vx, 0)
        XCTAssertEqual(sprite(t, a).groundKind, 0)
    }

    func testSlope45LandingVy() throws {
        let t = try solver()
        // Centre column c = 64 + 8 → s = clamp(c − X, 0, 32) = 8; surface Y+8 = 104 < bottom 112 → vy = |vx| + 0x100.
        let a = mover(t, x: 64, y: 80, vx: 1000, vy: 0x100)
        XCTAssertTrue(bounce(t, a, kind: 0xc))
        XCTAssertEqual(sprite(t, a).vy, 1256)
        XCTAssertEqual(sprite(t, a).groundKind, 0xc)
        XCTAssertEqual(sprite(t, a).y, 104 - 32)
    }

    func testKind2cSnapsWhileRising() throws {
        let t = try solver()
        // c = 80 + 8 → t = 24, s = 2(t − 16) = 16; bottom 116 > 112 → vy = 2|vx| + 0x100 even rising (raw 10039824..44).
        let a = mover(t, x: 80, y: 84, vx: 300, vy: -500)
        XCTAssertTrue(bounce(t, a, kind: 0x2c))
        XCTAssertEqual(sprite(t, a).vy, 2 * 300 + 0x100)
        XCTAssertEqual(sprite(t, a).groundKind, 0x2c)
        XCTAssertEqual(sprite(t, a).y, 112 - 32)
    }

    func testKind3cIsFloor8pxHigher() throws {
        let t = try solver()
        // 0x3c → kind 3 at Y − 8 (the caller's point is rewritten): bottom on Y+8 = 104 → y 72 (kind 3: 80); `+0xce` 3.
        let a = mover(t, x: 64, y: 84, vy: 0x300)
        var p = TilePos(x: 64, y: 96)
        XCTAssertTrue(t.wallBounce(a, kind: 0x3c, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false))
        XCTAssertEqual(p.y, 88)
        XCTAssertEqual(sprite(t, a).y, 72)
        XCTAssertEqual(sprite(t, a).groundKind, 3)
        XCTAssertEqual(sprite(t, a).vy, 0)
    }

    func testNoCollisionKinds() throws {
        let t = try solver()
        for kind in [0x30, 0x31, 0x3a, 0x3b, 0x4e] + Array(80...95) {
            let a = mover(t, x: 64, y: 84, vx: 0x100, vy: 0x300)
            let before = sprite(t, a)
            XCTAssertFalse(bounce(t, a, kind: kind), "kind \(kind)")
            XCTAssertEqual(sprite(t, a), before, "kind \(kind)")
        }
    }

    func testOneWayLandsOnlyFromAbove() throws {
        let t = try solver()
        var p = TilePos(x: 64, y: 96)
        // BG 103 → `.WallBounceBG(3)`, vy 0x400 (4 px): Bprev = bottom − 4. y 85: B 117, Bprev 113 = Y+17 → lands.
        let a = mover(t, x: 64, y: 85, vy: 0x400)
        XCTAssertTrue(t.wallBounceBG(a, kind: 103 - 100, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false))
        XCTAssertEqual(sprite(t, a).y, 112 - 32)
        XCTAssertEqual(sprite(t, a).vy, 0)
        XCTAssertEqual(sprite(t, a).groundKind, 3)
        XCTAssertTrue(sprite(t, a).oneWayLanded)
        // y 86: Bprev 114 = Y+18 → passes through.
        let b = mover(t, x: 64, y: 86, vy: 0x400)
        XCTAssertFalse(t.wallBounceBG(b, kind: 3, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false))
        XCTAssertEqual(sprite(t, b).y, 86)
        XCTAssertEqual(sprite(t, b).vy, 0x400)
        XCTAssertFalse(sprite(t, b).oneWayLanded)
        // BG ceiling 0xd is two-way: s = clamp(32 − (72 − 64), 0, 32) = 24; top 106 < Y+24 → pushed to 120 whether
        // moving down (no `+0xcf`, vy kept) or up (`+0xcf`, vy 0).
        let c = mover(t, x: 72, y: 106, vy: 0x200)
        XCTAssertTrue(t.wallBounceBG(c, kind: 0xd, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false))
        XCTAssertEqual(sprite(t, c).y, 120)
        XCTAssertEqual(sprite(t, c).vy, 0x200)
        XCTAssertFalse(sprite(t, c).ceilingHit)
        XCTAssertTrue(sprite(t, c).oneWayLanded)
        let d = mover(t, x: 72, y: 106, vy: -0x200)
        XCTAssertTrue(t.wallBounceBG(d, kind: 0xd, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false))
        XCTAssertEqual(sprite(t, d).y, 120)
        XCTAssertEqual(sprite(t, d).vy, 0)
        XCTAssertTrue(sprite(t, d).ceilingHit)
    }

    func testRestoreUsesCallEntryPosition() throws {
        let t = try solver()
        // Each mover: `.SeparateFromTiles2` (no callback) writes `+0x8`/`+0x6` = its entry E over a stale copy; the
        // 24.8 position then moves (an earlier push in the same call); `.WallBounce` 4–7 reverts to E, not to the
        // moved position. (E, moved, vx/vy, expected (x, y)) — arithmetic per player-states-2 §9.2 rows 4–7:
        let cases: [(kind: Int, e: (Int, Int), moved: (Int, Int), vy: Int32, want: (Int, Int))] = [
            (4, (60, 90), (68, 94), 0x100, (60, 112 - 32)),   // (Y+32 − Bprev) 3 ≥ (Lprev − X) −4 → floor; x = E.x
            (5, (60, 86), (68, 90), 0, (80 - 8, 86)),         // (T − Y) −6 < (c − X) 12 → wall c = X+16; y = E.y
            (6, (70, 86), (76, 90), 0, (80 - 9, 86)),         // (T − Y) −6 < (X+32 − (c+1)) 11 → wall; y = E.y
            (7, (70, 90), (76, 94), 0x100, (80 - 16, 90)),    // 3 < (X+32 − Rprev) 10 → wall R = X+16; y = E.y
        ]
        for c in cases {
            let a = mover(t, x: c.e.0, y: c.e.1, vy: c.vy)
            t.world.active.update(id: a) { $0.oldPosition = SpriteSlot.Point(x: 1, y: 1) }
            t.separateFromTiles(a, pass: nil)
            XCTAssertEqual(sprite(t, a).oldPosition, SpriteSlot.Point(x: c.e.0, y: c.e.1), "kind \(c.kind)")
            t.world.active.update(id: a) {
                $0.x256 = Int32(c.moved.0) << 8
                $0.y256 = Int32(c.moved.1) << 8
            }
            XCTAssertTrue(bounce(t, a, kind: c.kind), "kind \(c.kind)")
            XCTAssertEqual(sprite(t, a).x, c.want.0, "kind \(c.kind)")
            XCTAssertEqual(sprite(t, a).y, c.want.1, "kind \(c.kind)")
            XCTAssertEqual(sprite(t, a).x256, Int32(c.want.0) << 8, "kind \(c.kind)")
            XCTAssertEqual(sprite(t, a).y256, Int32(c.want.1) << 8, "kind \(c.kind)")
        }
    }

    func testApplySpeedStepsOf0x400() throws {
        // Every BG cell is tile 0 with BG kind 600 (no solid; still a callback), a 1×1 hot rect meets one cell: one
        // BG callback per `.SeparateFromTiles2`.
        let dot = IdleSprites.Rect(top: 0, left: 0, bottom: 1, right: 1)
        var separations = 0
        let pass: TileHit = { solver, id, cell, kind, layer in
            switch layer {
            case .background: separations += 1
            case .foreground:
                var p = cell
                solver.wallBounce(id, kind: kind, tile: &p, vCentre: 0, factor: 0, rect: dot, bounce: false)
            case .crunch: break
            }
        }
        // Free fall at 0x1000: 4 steps of 0x400 then the zero remainder = 5 separations (M l. 43226–43245).
        let t = try solver(bgAll: 1, bgKinds: [0: 600])
        let a = mover(t, x: 10, y: 0, vy: 0x1000, rect: dot)
        let free = t.applySpeedAndSeparate(a, pass: pass)
        XCTAssertEqual(separations, 5)
        XCTAssertEqual(sprite(t, a).y256, 0x1000)
        XCTAssertFalse(free.zeroJumpCounter)
        XCTAssertEqual(free.playerY, 16)
        // With a kind-3 floor at cell (0, 1) (hot rect y 48…80): y 40 → 44 (step 1), 48 (step 2 lands: vy 0, y 47) —
        // vy changed, so the loop stops at the landing step with no remainder separation.
        separations = 0
        let f = try solver(fg: [(0, 1, 3 + 1)], bgAll: 1, bgKinds: [0: 600])
        let b = mover(f, x: 10, y: 40, vy: 0x1000, rect: dot)
        f.applySpeedAndSeparate(b, pass: pass)
        XCTAssertEqual(separations, 2)
        XCTAssertEqual(sprite(f, b).y, 47)
        XCTAssertEqual(sprite(f, b).vy, 0)
        XCTAssertEqual(sprite(f, b).groundKind, 3)
        // vy ≤ 0x400 into a kind-1 ceiling (hot rect y 0…16): vy 0, not grounded, climb 0 → the jump counter is
        // zeroed (raw 1004b998..1004b9c8, Bank correction A3); climbing → not.
        let c = try solver(fg: [(0, 0, 1 + 1)], bgAll: 1, bgKinds: [0: 600])
        let up = mover(c, x: 10, y: 20, vy: -0x600, rect: dot)
        XCTAssertTrue(c.applySpeedAndSeparate(up, pass: pass).zeroJumpCounter)
        XCTAssertEqual(sprite(c, up).y, 16)
        XCTAssertEqual(sprite(c, up).vy, 0)
        let climbing = mover(c, x: 10, y: 20, vy: -0x600, rect: dot)
        XCTAssertFalse(c.applySpeedAndSeparate(climbing, climb: 1, pass: pass).zeroJumpCounter)
    }

    func testSlopeFactorsF32() {
        // f32 factors (`lfs`, `fmuls`): accel (int)(335·F), cap (int)(1900·F) — probe A misc.out.
        func run(kind: UInt8, a: Int16, vx: Int32) -> Int32 {
            var s = SpriteSlot(type: 0x45, x: 0, y: 0)
            s.groundKind = kind
            s.vx = vx
            s.accelerateBasedOnSlope(a, cap: 1900)
            return s.vx
        }
        XCTAssertEqual(run(kind: 0xf, a: 335, vx: 0), 236)              // 45° uphill, 0.707f
        XCTAssertEqual(run(kind: 0xf, a: 335, vx: 2000), 1343)
        XCTAssertEqual(run(kind: 0xc, a: -335, vx: 0), -236)            // mirrored
        XCTAssertEqual(run(kind: 0xc, a: -335, vx: -2000), -1343)
        XCTAssertEqual(run(kind: 0x22, a: 335, vx: 0), 309)             // 1:2, 0.923f
        XCTAssertEqual(run(kind: 0x22, a: 335, vx: 2000), 1753)
        XCTAssertEqual(run(kind: 0x2e, a: 335, vx: 0), 127)             // 2:1, 0.382f
        XCTAssertEqual(run(kind: 0x2e, a: 335, vx: 2000), 725)
        XCTAssertEqual(run(kind: 0xf, a: -335, vx: 0), -335)            // downhill: no factor
        XCTAssertEqual(run(kind: 0xf, a: -335, vx: -2000), -1900)
    }
}

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
        world.tiles = grid              // the one tile map: the world's (F3 review); the solver reads it
        return TileSolver(world: world)
    }

    private func mover(_ t: TileSolver, x: Int, y: Int, vx: Int32 = 0, vy: Int32 = 0,
                       rect: IdleSprites.Rect? = nil) -> Int {
        let r = rect ?? tall
        return t.world.newSprite(type: 0x45, x: x, y: y, layer: 10, handler: .player) {
            $0.x = x; $0.y = y          // the pixel copies (`.MTNewSprite` leaves `+0xc` = y, `+0xa` = 0; F2 review)
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
        XCTAssertEqual(sprite(t, c).ceilingHit, 0)          // `+0xcf` untouched
        XCTAssertTrue(sprite(t, c).oneWayLanded)
        let d = mover(t, x: 72, y: 106, vy: -0x200)
        XCTAssertTrue(t.wallBounceBG(d, kind: 0xd, tile: &p, vCentre: 16, factor: 0, rect: tall, bounce: false))
        XCTAssertEqual(sprite(t, d).y, 120)
        XCTAssertEqual(sprite(t, d).vy, 0)
        XCTAssertEqual(sprite(t, d).ceilingHit, 0xd)        // `+0xcf` = the kind byte (uVar9, l. 34197)
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
        let free = t.applySpeedAndSeparate(a, climb: { 0 }, pass: pass)
        XCTAssertEqual(separations, 5)
        XCTAssertEqual(sprite(t, a).y256, 0x1000)
        XCTAssertFalse(free.zeroJumpCounter)
        XCTAssertEqual(free.playerY, 16)
        // With a kind-3 floor at cell (0, 1) (hot rect y 48…80): y 40 → 44 (step 1), 48 (step 2 lands: vy 0, y 47) —
        // vy changed, so the loop stops at the landing step with no remainder separation.
        separations = 0
        let f = try solver(fg: [(0, 1, 3 + 1)], bgAll: 1, bgKinds: [0: 600])
        let b = mover(f, x: 10, y: 40, vy: 0x1000, rect: dot)
        f.applySpeedAndSeparate(b, climb: { 0 }, pass: pass)
        XCTAssertEqual(separations, 2)
        XCTAssertEqual(sprite(f, b).y, 47)
        XCTAssertEqual(sprite(f, b).vy, 0)
        XCTAssertEqual(sprite(f, b).groundKind, 3)
        // vy ≤ 0x400 into a kind-1 ceiling (hot rect y 0…16): vy 0, not grounded, climb 0 → the jump counter is
        // zeroed (raw 1004b998..1004b9c8, Bank correction A3); climbing → not.
        let c = try solver(fg: [(0, 0, 1 + 1)], bgAll: 1, bgKinds: [0: 600])
        let up = mover(c, x: 10, y: 20, vy: -0x600, rect: dot)
        XCTAssertTrue(c.applySpeedAndSeparate(up, climb: { 0 }, pass: pass).zeroJumpCounter)
        XCTAssertEqual(sprite(c, up).y, 16)
        XCTAssertEqual(sprite(c, up).vy, 0)
        let climbing = mover(c, x: 10, y: 20, vy: -0x600, rect: dot)
        XCTAssertFalse(c.applySpeedAndSeparate(climbing, climb: { 1 }, pass: pass).zeroJumpCounter)
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
        // F3 review: inputs where the single-precision product differs from a double one. f32 0.923 = 0x3f6c49ba =
        // 0.92299997806549…, f32 0.382 = 0x3ec39581 = 0.38199999928474…
        //   1000·0.923f: `fmuls` rounds 922.99997806… to the nearest f32, 923.0 → 923   (f64 product: 922.99997… → 922)
        //   500·0.382f:  190.99999964… rounds to the f32 191.0 → 191                     (f64 product → 190)
        func runCap(kind: UInt8, a: Int16, vx: Int32, cap: Int32) -> Int32 {
            var s = SpriteSlot(type: 0x45, x: 0, y: 0)
            s.groundKind = kind
            s.vx = vx
            s.accelerateBasedOnSlope(a, cap: cap)
            return s.vx
        }
        XCTAssertEqual(runCap(kind: 0x22, a: 1000, vx: 0, cap: 5000), 923)     // accel, 0.923f (f64: 922)
        XCTAssertEqual(runCap(kind: 0x2e, a: 500, vx: 0, cap: 5000), 191)      // accel, 0.382f (f64: 190)
        // The cap: cap₃₂ = f32(1000)·F — 0.923f → 923.0 (f64 922.99997 → 922); 0.382f → 382.0 (f64 381.99999 → 381).
        XCTAssertEqual(runCap(kind: 0x22, a: 335, vx: 2000, cap: 1000), 923)   // 2000 + 309 > 923 → 923
        XCTAssertEqual(runCap(kind: 0x2e, a: 335, vx: 2000, cap: 1000), 382)   // 2000 + 127 > 382 → 382
    }

    // MARK: - F3 review additions (mutation-proofing; every number from the dump, arithmetic beside it)

    /// A recording tile callback: (cell x, cell y, kind, layer) per call.
    private final class Log { var calls: [(x: Int, y: Int, kind: Int, layer: TileLayer)] = [] }

    private func recorder(_ log: Log) -> TileHit {
        { _, _, cell, kind, layer in log.calls.append((cell.x, cell.y, kind, layer)) }
    }

    /// `.ApplySpeedAndSeparateFromTiles` reads `*_DAT_100a0758` (climb) **after** the separation (raw `1004b9b0..bc`,
    /// following the `bl 0x1003c804` at `1004b990`), so a tile callback that starts a climb during the separation keeps
    /// the jump counter.
    func testClimbIsReadAfterSeparation() throws {
        let dot = IdleSprites.Rect(top: 0, left: 0, bottom: 1, right: 1)
        var climb: Int16 = 0
        var setClimb = false
        let pass: TileHit = { _, _, _, _, layer in if layer == .background && setClimb { climb = 1 } }
        // BG kind 600 everywhere (a callback, no solid). vy 0 airborne, `+0xce` 0: the apex — zeroed while climb is 0.
        let t = try solver(bgAll: 1, bgKinds: [0: 600])
        let a = mover(t, x: 10, y: 20, vy: 0, rect: dot)
        XCTAssertTrue(t.applySpeedAndSeparate(a, climb: { climb }, pass: pass).zeroJumpCounter)
        // The same step with the callback setting climb = 1 during the separation: read after → not zeroed.
        setClimb = true
        let b = mover(t, x: 10, y: 20, vy: 0, rect: dot)
        XCTAssertFalse(t.applySpeedAndSeparate(b, climb: { climb }, pass: pass).zeroJumpCounter)
        XCTAssertEqual(climb, 1)
    }

    /// The jump counter needs `+0xce == 0` (`lbz r0,0xce; cmplwi; bne`, raw `1004b9a4..1004b9ac`): a vy ≤ 0x400 step
    /// that lands has vy 0 but `+0xce` 3, and keeps it.
    func testLandingDoesNotZeroJumpCounter() throws {
        let dot = IdleSprites.Rect(top: 0, left: 0, bottom: 1, right: 1)
        let pass: TileHit = { solver, id, cell, kind, layer in
            guard layer == .foreground else { return }
            var p = cell
            solver.wallBounce(id, kind: kind, tile: &p, vCentre: 0, factor: 0, rect: dot, bounce: false)
        }
        // Kind-3 floor at cell (0, 1): perTile[3] = (top 16, bottom 48) at Y 32 → 48…80. y 46 + vy 0x300 (3 px) = 49:
        // the dot meets it; kind 3: Y+16 = 48 < 49 + 1 → vy 0, `+0xce` 3, y = 48 − 1 = 47.
        let t = try solver(fg: [(0, 1, 3 + 1)])
        let a = mover(t, x: 10, y: 46, vy: 0x300, rect: dot)
        let r = t.applySpeedAndSeparate(a, climb: { 0 }, pass: pass)
        XCTAssertEqual(sprite(t, a).y, 47)
        XCTAssertEqual(sprite(t, a).vy, 0)
        XCTAssertEqual(sprite(t, a).groundKind, 3)
        XCTAssertFalse(r.zeroJumpCounter)
    }

    /// `+0xeb` set: before the FG callback of a cell whose FG hot rect meets, the 2×2 cells (c−1…c, r−1…r), column
    /// outer, each nibble > 0 whose box (cx+16, cy+16)…(cx+48, cy+48) meets → `callback((cx, cy), nibble, 2)`
    /// (decompile l. 35230ff., physics §3.1).
    func testCrunchNibblesPrecedeTheForegroundCall() throws {
        // Hot rect 8×8 at (76, 76): rect 76…84; centre 80 → cell (2, 2), X = Y = 64. FG tile 0x30 only at (2, 2)
        // (kind 0x30: perTile full (0,0)…(32,48) → 64…96 × 64…112, meets). Nibbles (bits 12–15): (1,1)=1, (1,2)=2,
        // (2,1)=3, (2,2)=4. Boxes: (1,1) 48…80 × 48…80, (1,2) x 48…80 y 80…112, (2,1) x 80…112 y 48…80,
        // (2,2) 80…112 × 80…112 — each meets 76…84. Column outer → nibbles 1, 2, 3, 4 (row outer would give 1, 3, 2, 4).
        let t = try solver(fg: [(1, 1, 0x1000), (1, 2, 0x2000), (2, 1, 0x3000), (2, 2, 0x4000 | 0x31)])
        let a = mover(t, x: 76, y: 76, rect: IdleSprites.Rect(top: 0, left: 0, bottom: 8, right: 8))
        t.world.active.update(id: a) { $0.crunches = 1 }
        let log = Log()
        t.separateFromTiles(a, pass: recorder(log))
        let fg = log.calls.filter { $0.layer != .background }
        XCTAssertEqual(fg.map(\.layer), [.crunch, .crunch, .crunch, .crunch, .foreground])
        XCTAssertEqual(fg.map(\.kind), [1, 2, 3, 4, 0x30])
        XCTAssertEqual(fg.map(\.x), [32, 32, 64, 64, 64])
        XCTAssertEqual(fg.map(\.y), [32, 64, 32, 64, 64])
        // `+0xeb` clear: the FG call alone.
        t.world.active.update(id: a) { $0.crunches = 0 }
        log.calls = []
        t.separateFromTiles(a, pass: recorder(log))
        XCTAssertEqual(log.calls.filter { $0.layer != .background }.map(\.layer), [.foreground])
    }

    /// The 9-cell order (c,r), (c−1,r−1), (c,r−1), (c+1,r−1), (c−1,r), (c+1,r), (c−1,r+1), (c,r+1), (c+1,r+1)
    /// (decompile l. 35206ff.); per cell the FG call precedes the BG call.
    func testNineCellOrder() throws {
        // FG tile 0x30 (kind 0x30, full rect 32 × 48) everywhere; BG cells 0 → tile −1, kind −1 ≠ 0 → a BG call too.
        // Hot rect 90×90 at (40, 40): rect 40…130; centre 40 + 45 = 85 → (c, r) = (2, 2). Every cell of cols / rows 1…3
        // (X, Y ∈ {32, 64, 96}) meets both its FG rect (X…X+32 × Y…Y+48) and its full cell.
        let all = (0..<8).flatMap { r in (0..<8).map { (col: $0, row: r, cell: UInt16(0x31)) } }
        let t = try solver(fg: all)
        let a = mover(t, x: 40, y: 40, rect: IdleSprites.Rect(top: 0, left: 0, bottom: 90, right: 90))
        let log = Log()
        t.separateFromTiles(a, pass: recorder(log))
        let order = [(64, 64), (32, 32), (64, 32), (96, 32), (32, 64), (96, 64), (32, 96), (64, 96), (96, 96)]
        XCTAssertEqual(log.calls.count, 18)
        for (i, cell) in order.enumerated() {
            XCTAssertEqual(log.calls[2 * i].x, cell.0, "cell \(i)")
            XCTAssertEqual(log.calls[2 * i].y, cell.1, "cell \(i)")
            XCTAssertEqual(log.calls[2 * i].layer, .foreground, "cell \(i)")
            XCTAssertEqual(log.calls[2 * i + 1].x, cell.0, "cell \(i)")
            XCTAssertEqual(log.calls[2 * i + 1].y, cell.1, "cell \(i)")
            XCTAssertEqual(log.calls[2 * i + 1].layer, .background, "cell \(i)")
            XCTAssertEqual(log.calls[2 * i + 1].kind, -1, "cell \(i)")
        }
    }

    /// The hot rect is built once at entry (stack `0x7a`, raw `1003c878..1003c8b4`; plan Hazard "Entry rect", Bank
    /// correction A12): a callback that moves the sprite 256 px down does not change which of the 9 cells are met.
    func testEntryRectFixedDuringLoop() throws {
        let all = (0..<8).flatMap { r in (0..<8).map { (col: $0, row: r, cell: UInt16(0x31)) } }
        let t = try solver(fg: all)
        let a = mover(t, x: 40, y: 40, rect: IdleSprites.Rect(top: 0, left: 0, bottom: 90, right: 90))
        let log = Log()
        let pass: TileHit = { solver, id, cell, kind, layer in
            if log.calls.isEmpty { solver.world.active.update(id: id) { $0.y256 &+= 0x100 << 8 } }   // +256 px
            log.calls.append((cell.x, cell.y, kind, layer))
        }
        t.separateFromTiles(a, pass: pass)
        // A rect rebuilt at y 296 would meet none of the Y 32…96 cells (bottoms ≤ 144): all 9 × (FG + BG) still come.
        XCTAssertEqual(log.calls.filter { $0.layer == .foreground }.count, 9)
        XCTAssertEqual(log.calls.filter { $0.layer == .background }.count, 9)
        XCTAssertEqual(sprite(t, a).y256, (40 + 256) << 8)
    }

    /// `.WallBounce`'s hundreds loop (`while (k > 99) { k −= 100; material++ }`) and `+0xd8 = material` on a hit when
    /// material > 0 (player-states-2 §9.1).
    func testHundredsAreMaterial() throws {
        let t = try solver()
        // 103 → kind 3, material 1; the landing is kind 3's (y 84 → 80, `+0xce` 3), `+0xd8` 1.
        let a = mover(t, x: 64, y: 84, vy: 0x300)
        XCTAssertTrue(bounce(t, a, kind: 103))
        XCTAssertEqual(sprite(t, a).material, 1)
        XCTAssertEqual(sprite(t, a).groundKind, 3)
        XCTAssertEqual(sprite(t, a).y, 80)
        // 203 → material 2.
        let b = mover(t, x: 64, y: 84, vy: 0x300)
        XCTAssertTrue(bounce(t, b, kind: 203))
        XCTAssertEqual(sprite(t, b).material, 2)
        // Plain kind 3 (material 0): `+0xd8` not written — a stale 7 stays.
        let c = mover(t, x: 64, y: 84, vy: 0x300)
        t.world.active.update(id: c) { $0.material = 7 }
        XCTAssertTrue(bounce(t, c, kind: 3))
        XCTAssertEqual(sprite(t, c).material, 7)
        // No hit (rising sprite above the tile's hot rect: bottom 84 < Y+16 = 112, rect misses): `+0xd8` untouched.
        let d = mover(t, x: 64, y: 40, vy: -0x300)
        XCTAssertFalse(bounce(t, d, kind: 203))
        XCTAssertEqual(sprite(t, d).material, 0)
    }

    /// The ice slide runs once per `.SeparateFromTiles2` call: `+0x181` is cleared at every call's entry (raw
    /// `1003c868 stb r0,0x181`) and set by the first slide (player-states-2 §9.2, kind 0xc).
    func testIceSlideOncePerSeparationCall() throws {
        let t = try solver()
        // Kind 0xc, x 64: s = 8, surface 104 < bottom 112 → lands; slip 16: vx = (int)(7.07·16 + vx) (`fmadd`, f64
        // 0x401c47ae147ae148): 1000 + 113.12 = 1113.12 → 1113; vx > 0 so vy keeps |1000| + 0x100.
        let a = mover(t, x: 64, y: 80, vx: 1000, vy: 0x100)
        t.world.active.update(id: a) { $0.slip = 16 }
        XCTAssertTrue(bounce(t, a, kind: 0xc))
        XCTAssertEqual(sprite(t, a).vx, 1113)
        XCTAssertTrue(sprite(t, a).slideLatch)
        // A second kind-0xc hit in the same separation (no `.SeparateFromTiles2` between): latched, no slide.
        t.world.active.update(id: a) { $0.y256 = 80 << 8 }
        XCTAssertTrue(bounce(t, a, kind: 0xc))
        XCTAssertEqual(sprite(t, a).vx, 1113)
        // The next separation clears `+0x181`: slides again, 1113 + 113.12 = 1226.12 → 1226.
        t.separateFromTiles(a, pass: nil)
        XCTAssertFalse(sprite(t, a).slideLatch)
        t.world.active.update(id: a) { $0.y256 = 80 << 8 }
        XCTAssertTrue(bounce(t, a, kind: 0xc))
        XCTAssertEqual(sprite(t, a).vx, 1226)
    }

    /// `.ApplyGravityAndSeparateFromTiles @ 100375b0` (decompile l. 32922–32980).
    func testApplyGravityAndSeparate() throws {
        let dot = IdleSprites.Rect(top: 0, left: 0, bottom: 1, right: 1)
        var separations = 0
        let pass: TileHit = { _, _, _, _, layer in if layer == .background { separations += 1 } }
        let t = try solver(bgAll: 1, bgKinds: [0: 600])
        func run(y: Int, vx: Int32, vy: Int32, g: Int16, water: Int32 = 0) -> SpriteSlot {
            separations = 0
            let a = mover(t, x: 10, y: y, vx: vx, vy: vy, rect: dot)
            t.world.active.update(id: a) { $0.gravity = g; $0.waterRow = water; $0.groundKind = 5 }
            t.applyGravityAndSeparate(a, pass: pass)
            return sprite(t, a)
        }
        // Dry, vy 0x1700 + g 0x80 = 0x1780 > 0xc00: one separation first, then +0xc00 (sep), remainder 0xb80 (sep)
        // = 3; y256 0 + 0x1780 → y 23; x256 0xa00 + 0x100 → x 11; `+0xce` cleared (5 → 0, no floor).
        let down = run(y: 0, vx: 0x100, vy: 0x1700, g: 0x80)
        XCTAssertEqual(separations, 3)
        XCTAssertEqual(down.vy, 0x1780)
        XCTAssertEqual(down.y256, 0x1780)
        XCTAssertEqual(down.x256, 0xb00)
        XCTAssertEqual(down.groundKind, 0)
        XCTAssertEqual(down.oldPosition, SpriteSlot.Point(x: 11, y: 23))
        // Rising, vy −0x2000 + 0x80 = −0x1f80: −0xc00, −0xc00, remainder −0x780 → 1 + 3 = 4; y256 0x4000 − 0x1f80 =
        // 0x2080 → y 32.
        let up = run(y: 64, vx: 0, vy: -0x2000, g: 0x80)
        XCTAssertEqual(separations, 4)
        XCTAssertEqual(up.y256, 0x2080)
        XCTAssertEqual(up.y, 32)
        // In range (|vy| ≤ 0xc00): 1 + 1 = 2.
        _ = run(y: 0, vx: 0, vy: 0, g: 0x80)
        XCTAssertEqual(separations, 2)
        // In water (`+0x11c ≠ 0`): g = (short)(int)(g · 0.7) (f64 0x3fe6666666666666): 0x200 → 358.39… → 358;
        // 0x100 → 179.19… → 179 < 0x100 → 0x100.
        XCTAssertEqual(run(y: 0, vx: 0, vy: 0, g: 0x200, water: 1).vy, 358)
        XCTAssertEqual(run(y: 0, vx: 0, vy: 0, g: 0x100, water: 1).vy, 0x100)
        XCTAssertEqual(run(y: 0, vx: 0, vy: 0, g: 0x80).vy, 0x80)                   // dry: no 0x100 floor
        // The centre `+0x10` = x + left + ((right − left) >> 1), `+0xe` = y + top + ((bottom − top) >> 1): hot rect
        // (2, 4, 12, 20) at (11, 23) → (11 + 4 + 8, 23 + 2 + 5) = (23, 30).
        let c = mover(t, x: 10, y: 0, vx: 0x100, vy: 0x1700, rect: IdleSprites.Rect(top: 2, left: 4, bottom: 12, right: 20))
        t.world.active.update(id: c) { $0.gravity = 0x80 }
        t.applyGravityAndSeparate(c, pass: nil)
        XCTAssertEqual(sprite(t, c).centre.x, 23)
        XCTAssertEqual(sprite(t, c).centre.y, 30)
    }

    /// `.AccelerateSprite @ 1003713c` (decompile l. 32762ff.) and the water rule of `.AccelerateBasedOnSlope`, through
    /// the `TileSolver` names (plan S2).
    func testAccelerateSpriteWaterFactor() throws {
        let t = try solver()
        func accel(vx: Int32, vy: Int32, row: Int32 = 0, last: Int32 = 0, maxX: Int32 = 1901, maxY: Int32 = 120)
            -> (Int32, Int32) {
            let a = mover(t, x: 0, y: 0, vx: vx, vy: vy)
            t.world.active.update(id: a) { $0.waterRow = row; $0.lastWater = last }
            t.accelerateSprite(a, ax: 333, ay: -50, maxX: maxX, maxY: maxY)
            return (sprite(t, a).vx, sprite(t, a).vy)
        }
        // Dry: 1500 + 333 = 1833 ≤ 1901; −100 − 50 = −150, |−150| > 120 → −120.
        XCTAssertTrue(accel(vx: 1500, vy: -100) == (1833, -120))
        // Water by `+0x120` alone (`+0x11c ∨ +0x120`), f64 0.8 (0x3fe999999999999a): ax (int)266.4 = 266, ay
        // (int)−40.000…01 = −40, maxX (int)1520.8 = 1520, maxY (int)96.000…01 = 96 → 1766 > 1520 → 1520; −140 → −96.
        XCTAssertTrue(accel(vx: 1500, vy: -100, last: 1) == (1520, -96))
        XCTAssertTrue(accel(vx: 1500, vy: -100, row: 1) == (1520, -96))
        // max 0 → no clamp.
        XCTAssertTrue(accel(vx: 5000, vy: -5000, maxX: 0, maxY: 0) == (5333, -5050))
        // `.AccelerateBasedOnSlope` tests `+0x11c` only (raw `10037354`): flat ground, a 335, cap 1900 — `+0x120` alone
        // → 335; `+0x11c` → a = (short)(int)(335·0.8 = 268.0…) = 268.
        func slope(row: Int32, last: Int32) -> Int32 {
            let a = mover(t, x: 0, y: 0)
            t.world.active.update(id: a) { $0.waterRow = row; $0.lastWater = last }
            t.accelerateBasedOnSlope(a, 335, cap: 1900)
            return sprite(t, a).vx
        }
        XCTAssertEqual(slope(row: 0, last: 1), 335)
        XCTAssertEqual(slope(row: 1, last: 0), 268)
    }
}

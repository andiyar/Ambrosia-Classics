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

    /// One frame: the previous frame's cues are drained first (the frame driver's `drainFrameOutputs()`, P2), so
    /// `w.player.cues` reads this frame's.
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        _ = w.player.drainFrameOutputs()
        Player.handle(world: w, keys: keys, solver: solver, tileHit: floorHit)
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// Spawn on the floor and settle: frame 1 lands (`+0xce` 3), frame 2 refills the jump counter to 6.
    private func standing(_ w: SpriteWorld) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
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
        // run max 3200: −3200 − 556 = −3756 (raw `100541c4`/`10054240 addi r0,r3,0x4e2`). Negative vx takes |vx|
        // (−1900 → −3593); vx ±6 pins 0x4e2: (6 + 1250) >> 3 = 157 → −3357, where 0x4e0 would give 156.
        for (vx, expected) in [(Int32(0), Int32(-3356)), (1900, -3593), (3200, -3756), (-1900, -3593), (-3200, -3756),
                               (6, -3357), (-6, -3357)] {
            let w = try world()
            _ = standing(w)
            w.active.update(id: w.playerID!) { $0.vx = vx }
            HandleKeys.run(world: w, keys: .jump, ridden: nil)
            XCTAssertEqual(player(w).vy, expected, "vx \(vx)")
            XCTAssertEqual(w.player.jumpCounter, 5)
            XCTAssertEqual(w.player.exertion, 8)
            XCTAssertEqual(w.player.postJumpGuard, 2)
            // ⚑ P3: the last settle frame's grounded-arm `stop 427` (raw `1005074c`/`10050760`) comes first — the
            // cues are not drained before this direct `.HandleKeys` call.
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .stopIfPlaying, snd: 427),
                                           PlayerCue(call: .reg, snd: 414, priority: 1, volume: 0x9c)])
        }
        // W1: off a ridden sprite J = its `+0x194` (l. 47808–47813), read by this jump's impulse; J ≠ 0 on a
        // springboard 0x58c (`+0xb0`) adds `.STPlayRegSound(604, 1, 0x100)`; any other ridden mode: no 604.
        for mode in [PlatformSprite.springboard, 2] {
            let w = try world()
            _ = standing(w)
            let board = try XCTUnwrap(w.newSprite(type: 1400, x: 0, y: 0, layer: -1, handler: .inert))
            w.active.update(id: board) { c in
                c.subtype = mode
                c.jumpBonus = -0x300
            }
            HandleKeys.run(world: w, keys: .jump, ridden: board)
            XCTAssertEqual(player(w).vy, -3356 - 0x300, "mode \(mode)")
            XCTAssertEqual(w.player.jumpBase, -0x300)
            XCTAssertEqual(w.player.cues.map(\.snd).filter { $0 == 604 }.count, mode == PlatformSprite.springboard ? 1 : 0)
            if mode == PlatformSprite.springboard {
                XCTAssertEqual(w.player.cues.last, PlayerCue(call: .reg, snd: 604, priority: 1, volume: 0x100))
            }
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
            if f <= 6 {
                // Exertion +8 on the jump frame and on every sustained frame (l. 47779), less
                // `.HandleBreathing`'s −2 per frame while > 0 (raw `1004bb8c..1004bb90`, row 30, P3): net +6; counter 6 → 0.
                XCTAssertEqual(w.player.exertion, Int16(6 * f), "frame \(f)")
                XCTAssertEqual(w.player.jumpCounter, Int16(6 - f), "frame \(f)")
            }
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
            if f == 2 { w.active.update(id: w.playerID!) { $0.vx = 1000 } }
            frame(w, solver, f == 1 ? .jump : [])
            dy.append(player(w).y256 - y0)
            if f == 2 { XCTAssertEqual(player(w).vx, 900) }           // air drag 100 every airborne frame (l. 44972)
            if f == 3 { XCTAssertEqual(player(w).vx, 800) }
        }
        XCTAssertEqual(dy.min(), -11172)
        XCTAssertEqual(dy[6], -11172)
        XCTAssertGreaterThan(dy[7], dy[6])                              // first descending frame: 8
        XCTAssertEqual(dy[7] - dy[6], 164)
        XCTAssertEqual(w.player.jumpCounter, 0)                         // released in the air: the else-refill → 0
    }

    func testNoAutoRepeatOrMidAirSpinRefill() throws {
        // JUMP held through the whole arc and the landing: the arm is taken every frame, so the else-refill never
        // runs — the counter stays 0 on the ground until JUMP is released (main l. 47870–47880).
        let w = try world()
        let solver = standing(w)
        for _ in 1...40 { frame(w, solver, .jump) }
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)              // landed again
        XCTAssertEqual(player(w).groundKind, 3)
        XCTAssertEqual(w.player.jumpCounter, 0)
        frame(w, solver, [])
        XCTAssertEqual(w.player.jumpCounter, 6)                         // released on the ground: refill 6
        // Ground deceleration without input (l. 45009–45052): 800 per frame, clamped at 0; 300 while stunned.
        w.active.update(id: w.playerID!) { $0.vx = 1000 }
        frame(w, solver, [])
        XCTAssertEqual(player(w).vx, 200)
        frame(w, solver, [])
        XCTAssertEqual(player(w).vx, 0)
        w.active.update(id: w.playerID!) { $0.vx = -1000 }
        frame(w, solver, [])
        XCTAssertEqual(player(w).vx, -200)
        w.player.stun = 1
        w.active.update(id: w.playerID!) { $0.vx = 1000 }
        frame(w, solver, [])
        XCTAssertEqual(player(w).vx, 700)
        w.player.stun = 0
        w.active.update(id: w.playerID!) { $0.vx = 0 }
        frame(w, solver, [])
        XCTAssertEqual(w.player.jumpCounter, 6)
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
        let id = Player.spawn(world: w, x: 100, y: 0)!
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vy = 1 }
        var vys: [Int32] = []
        for _ in 1...29 {
            Player.handle(world: w, keys: [])                           // the locked S2 call (no floor: no callback needed)
            vys.append(player(w).vy)
        }
        XCTAssertEqual(vys[26], 11881)
        XCTAssertEqual(vys.firstIndex(of: 12000).map { $0 + 1 }, 28)
        XCTAssertEqual(vys[28], 12000)
        // −440 + 440 = 0 → 1 (raw: `if vy == 0 → 1` after the clamp).
        w.active.update(id: id) { $0.vy = -440 }
        frame(w, solver)
        XCTAssertEqual(player(w).vy, 1)
        // Row 3's ride-on cue: stepping onto a 0x6a4 from no ridden sprite draws `FastRand(10000)` at the call site
        // (`STPlay3DSoundRand(509, 1, 0xbf, +0xe)`); riding on next frame draws nothing.
        let solidID = w.newSprite(type: 0x6a4, x: 100, y: 200, layer: 5, handler: .inert) { s in
            s.x = 100; s.y = 200; s.drawnX = 100; s.drawnY = 200
        }!
        w.active.update(id: id) { $0.ridden = solidID }
        var expected = w.rng
        let rate = expected.soundRate()
        frame(w, solver)
        // ⚑ P3: riding is grounded (`+0xce` 3) → the grounded arm's per-frame `stop 427` (raw `1005074c`/`10050760`, P3).
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 509, priority: 1, volume: 0xbf,
                                                 position: w.active.sprite(id: solidID)!.centre, rate: rate),
                                       PlayerCue(call: .stopIfPlaying, snd: 427)])
        XCTAssertEqual(w.rng.seed, expected.seed)
        w.active.update(id: id) { $0.ridden = solidID }
        frame(w, solver)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .stopIfPlaying, snd: 427)])   // no 509; P3's grounded stop
        XCTAssertEqual(w.rng.seed, expected.seed)
    }

    func testSubmergedBrake() throws {
        // Fully submerged (`+0x11c == 1`, set by last frame's water pass), airborne, not spinning: gravity 0x50 and
        // vy 2000 > 0x6a4 → 2000 − 0x200 = 1488 (raw `1004daec..1004daf8`); the frame's gravity add → 1568.
        let w = try world(floor: false)
        let id = Player.spawn(world: w, x: 100, y: 0)!
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vy = 2000; $0.waterRow = 1 }
        Player.selectGravity(world: w, id: id)
        XCTAssertEqual(player(w).vy, 1488)
        XCTAssertEqual(player(w).gravity, 0x50)
        XCTAssertEqual(w.player.swim, 1)                                // swim entry (liquid kind ≠ 5)
        // Thresholds: `cmpwi 0x6a4; ble` — 0x6a4 keeps, 0x6a5 brakes; spinning `cmpwi 0xbb8; ble` — 3000 keeps,
        // 3001 brakes, gravity 0x118 (raw `1004dac8`, `1004db04`).
        for (spin, vy, out) in [(false, Int32(0x6a4), Int32(0x6a4)), (false, 0x6a5, 0x6a5 - 0x200),
                                (true, 3000, 3000), (true, 3001, 3001 - 0x200)] {
            w.player.spin = spin
            w.active.update(id: id) { $0.vy = vy; $0.waterRow = 1 }
            Player.selectGravity(world: w, id: id)
            XCTAssertEqual(player(w).vy, out, "spin \(spin) vy \(vy)")
            XCTAssertEqual(player(w).gravity, spin ? 0x118 : 0x50)
        }
        w.player.spin = false
        w.active.update(id: id) { $0.vy = 2000; $0.waterRow = 1 }
        w.player.swim = 0
        frame(w, solver)
        XCTAssertEqual(player(w).vy, 1568)
    }

    // MARK: P1b — the L/R block (`.HandleKeys` raw `100534f0..100539c0`; plan P1b, probe A `kinematics.out`)

    /// Runs `n` frames with `keys` held and returns vx after each.
    private func vxs(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions, _ n: Int) -> [Int32] {
        (0..<n).map { _ in frame(w, solver, keys); return player(w).vx }
    }

    func testWalkRightFromRestReachesMaxIn4() throws {
        // Grounded RIGHT from rest: `.AccelerateBasedOnSlope(0x14f, walk max 0x76c)` (vx < 1, no ice; raw `100538b4`),
        // later 0x104 (raw `10053898`), then +0x14a while vx < air max 0x76c (raw `100539a4`): 335 + 330 = 665,
        // + 260 + 330 = 1255, 1845; 2105 → capped 1900, not < 1900 so no +0x14a.
        let w = try world()
        let solver = standing(w)
        w.player.facing = 1
        XCTAssertEqual(vxs(w, solver, .right, 4), [665, 1255, 1845, 1900])
        XCTAssertEqual(vxs(w, solver, .right, 2), [1900, 1900])
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)              // `.FootPressure` is undone by the floor
        XCTAssertEqual(player(w).groundKind, 3)
        XCTAssertTrue(w.player.walkRight)
        XCTAssertFalse(w.player.walkLeft)
        XCTAssertFalse(w.player.runFlag)
        XCTAssertEqual(w.player.facing, 2)                              // vx > 0 → F 2 (raw `100539b8`)
        // Exertion +1 per walking frame while < 0xb9 (raw `1005385c..1005386c`), less
        // `.HandleBreathing`'s −2 per frame while > 0 (raw `1004bb8c..1004bb90`, row 30, P3): 1 → −1, then 0 → 1 → −1 …: 6 frames → 0;
        // 0xb8 → 0xb9 − 2 = 0xb7 → 0xb8 − 2 = 0xb6. The cap itself, on `.HandleKeys` alone: 0xb9 stays 0xb9.
        XCTAssertEqual(w.player.exertion, 0)
        w.player.exertion = 0xb8
        frame(w, solver, .right)
        XCTAssertEqual(w.player.exertion, 0xb7)
        frame(w, solver, .right)
        XCTAssertEqual(w.player.exertion, 0xb6)
        w.player.exertion = 0xb9
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(w.player.exertion, 0xb9)
        // `.FootPressure` (raw `100538f8`) presses y down by |vx| after the accel and before the +0x14a: from rest
        // y += 335 (vx 335 at the call), not 665.
        let id = w.playerID!
        w.active.update(id: id) { $0.vx = 0 }
        let y0 = player(w).y256
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 665)
        XCTAssertEqual(player(w).y256 - y0, 335)
        // …not with the post-jump guard set (raw `100538e8`), nor with the air counter ≠ 0 (raw `100538c8`).
        w.active.update(id: id) { $0.vx = 0; $0.y256 = y0 }
        w.player.postJumpGuard = 1
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).y256, y0)
        w.player.postJumpGuard = 0
        w.player.airCounter = 1
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).y256, y0)
        w.player.airCounter = 0
        // `.FootPressure` itself (raw `100431ec..100433bc`): no push on kinds 4/7/0x13/0x14, a one-way top, or uphill
        // (vx > 0 on 0xf; vx ≤ 0 on 0xc); downhill pushes |vx|. Riding a slope: |vx·slope| >> 8, + min(d, 0x800)
        // with the slope's sign (vx 0 counts as +), −d against it.
        var probe = player(w)
        for (kind, vx, push) in [(UInt8(7), Int32(600), Int32(0)), (0x13, 600, 0), (0xf, 600, 0), (0xf, -600, 600),
                                 (0xc, -600, 0), (0xc, 600, 600), (0x36, 600, 0), (0x39, 600, 0), (0x3a, 600, 600), (0x32, -600, 0),
                                 (0x35, -600, 0), (0x36, -600, 600), (3, -600, 600), (4, 600, 0), (0x14, -600, 0),
                                 (0x20, -600, 0), (0x21, -600, 0), (0x2c, -600, 0), (0x2d, -600, 0),
                                 (0x20, 600, 600), (0x21, 600, 600), (0x2c, 600, 600), (0x2d, 600, 600),
                                 (0x22, 600, 0), (0x23, 600, 0), (0x2e, 600, 0), (0x2f, 600, 0),
                                 (0x22, -600, 600), (0x23, -600, 600), (0x2e, -600, 600), (0x2f, -600, 600)] {
            probe.groundKind = kind
            probe.vx = vx
            probe.y256 = 0
            HandleKeys.footPressure(&probe)
            XCTAssertEqual(probe.y256, push, "kind \(kind) vx \(vx)")
        }
        probe.groundKind = 3
        probe.oneWayLanded = true
        probe.y256 = 0
        HandleKeys.footPressure(&probe)
        XCTAssertEqual(probe.y256, 0)
        probe.oneWayLanded = false
        probe.ridden = id
        for (slope, vx, push) in [(Int16(0), Int32(600), Int32(0)), (2, 600, 4), (-2, 600, -4), (-2, -600, 4),
                                  (2, 0, 0), (0x100, 0x900, 0x800), (-0x100, 0x900, -0x900)] {
            probe.slope = slope
            probe.vx = vx
            probe.y256 = 0
            HandleKeys.footPressure(&probe)
            XCTAssertEqual(probe.y256, push, "slope \(slope) vx \(vx)")
        }
        // On ice (`_DAT_100a0694 ≠ 0`) RIGHT from rest takes the continuing 0x104 (raw `10053884..10053898`):
        // 260 + 330 = 590. Double Speed skips `.FootPressure` (raw `100538d8..100538e4`).
        w.player.ice = 1
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 590)
        w.player.ice = 0
        w.player.doubleSpeed = true
        w.active.update(id: id) { $0.vx = 0; $0.y256 = y0 }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 665)
        XCTAssertEqual(player(w).y256, y0)
        w.player.doubleSpeed = false
        // Each L/R press zeroes idle and fidgets (raw `10053560..10053568`, `100537c0..100537c8`).
        w.player.idle = 5
        w.player.fidgets = 2
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(w.player.idle, 0)
        XCTAssertEqual(w.player.fidgets, 0)
        w.player.idle = 5
        w.player.fidgets = 2
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(w.player.idle, 0)
        XCTAssertEqual(w.player.fidgets, 0)
        // The gates (raw `100534f0..10053548`): glider, climb ≠ 0, crouch ≠ 0, carpet, |teleporter charge| ≥ 0x15
        // each skip the whole block — vx, walk flag and exertion untouched.
        let gates: [(String, (inout PlayerState) -> Void)] = [
            ("glider", { $0.glider = true }), ("climb", { $0.climb = 1 }), ("crouch", { $0.crouch = 1 }),
            ("carpet", { $0.carpet = true }), ("charge", { $0.teleporterCharge = -0x15 }),
        ]
        for (name, gate) in gates {
            let saved = w.player
            w.active.update(id: id) { $0.vx = 0 }
            w.player.exertion = 0
            gate(&w.player)
            HandleKeys.run(world: w, keys: [.right, .run], ridden: nil)
            XCTAssertEqual(player(w).vx, 0, name)
            XCTAssertFalse(w.player.walkRight, name)
            XCTAssertEqual(w.player.exertion, 0, name)
            w.player = saved
        }
        w.active.update(id: id) { $0.vx = 0 }
        w.player.teleporterCharge = 0x14                                 // 0x14 still walks (`cmpwi 0x14; bgt`)
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 665)
    }

    func testWalkLeftFromRestReachesMaxIn8() throws {
        // Grounded LEFT: −0x14f from rest (vx ≥ 0, no ice; raw `10053654`), then −0x104 (raw `10053638`), and **no
        // −0x14a on the ground** (only the air path has it, raw `10053780`): −335, −595 … −1895, −1900.
        let w = try world()
        let solver = standing(w)
        w.player.facing = 2
        XCTAssertEqual(vxs(w, solver, .left, 8), [-335, -595, -855, -1115, -1375, -1635, -1895, -1900])
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)
        XCTAssertTrue(w.player.walkLeft)
        XCTAssertFalse(w.player.walkRight)
        XCTAssertEqual(w.player.facing, 1)                              // vx < 0 ∧ stun 0 → F 1 (raw `100537a4`)
        XCTAssertEqual(w.player.exertion, 0)                            // +1 per walking frame (raw `100535fc..1005360c`)
                                                                        // − 2 by `.HandleBreathing` (raw `1004bb8c`), P3
        // Stunned: LEFT does not turn him (raw `10053794..100537a0`).
        let id = w.playerID!
        w.player.facing = 2
        w.player.stun = 1
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(w.player.facing, 2)
        w.player.stun = 0
        // The left-only ground slip (raw `100536a4..100536d0`; Bank correction A14): `+0x112 > 0` → y += 2|vx| +
        // 0x200 after `.FootPressure`'s |vx|: from rest vx −335 → 335 + 670 + 512 = 1517. RIGHT never slips.
        w.active.update(id: id) { $0.vx = 0; $0.slip = 1 }
        var y0 = player(w).y256
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).y256 - y0, 1517)
        w.active.update(id: id) { $0.vx = 0 }
        y0 = player(w).y256
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).y256 - y0, 335)
        // `+0x112 == 0`: no slip (`cmpwi; ble`, raw `100536a8`) — only `.FootPressure`'s 335.
        w.active.update(id: id) { $0.vx = 0; $0.slip = 0 }
        y0 = player(w).y256
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).y256 - y0, 335)
        // Double Speed skips `.FootPressure` (raw `10053678..10053684`) but not the slip: 670 + 512.
        w.active.update(id: id) { $0.vx = 0; $0.slip = 1 }
        w.player.doubleSpeed = true
        y0 = player(w).y256
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).y256 - y0, 670 + 512)
        w.player.doubleSpeed = false
        w.active.update(id: id) { $0.slip = 0 }
        // On ice LEFT from rest takes the continuing −0x104 (raw `10053624..10053638`).
        w.player.ice = 1
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, -0x104)
        w.player.ice = 0
        // Facing boundary: LEFT from +0x14f lands on vx 0 exactly — `cmpwi 0; bge` keeps F (raw `1005378c..10053790`).
        w.player.facing = 2
        w.active.update(id: id) { $0.vx = 0x14f }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(w.player.facing, 2)
        w.active.update(id: id) { $0.slip = 1 }
        // The post-jump guard skips `.FootPressure` but not the slip (raw `10053688..100536a4`); the air counter skips
        // both (raw `10053668..10053674`).
        w.active.update(id: id) { $0.vx = 0 }
        w.player.postJumpGuard = 1
        y0 = player(w).y256
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).y256 - y0, 670 + 512)
        w.player.postJumpGuard = 0
        w.player.airCounter = 1
        w.active.update(id: id) { $0.vx = 0 }
        y0 = player(w).y256
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).y256, y0)
    }

    func testRunRightOvershootsThenClamps() throws {
        // RUN + RIGHT: 500 from rest (raw `10053844`), 300 after (raw `10053828`), cap run max 0xc80; +0x14a while vx
        // < air run max 0xc80 (run flag set, raw `10053980`): 830, 1460, 2090, 2720, 3020 + 330 = 3350 (the
        // overshoot), then 3650 → capped 3200, not < 3200 → 3200.
        let w = try world()
        let solver = standing(w)
        XCTAssertEqual(vxs(w, solver, [.right, .run], 6), [830, 1460, 2090, 2720, 3350, 3200])
        XCTAssertTrue(w.player.runFlag)
        // +3 per running frame (raw `100537f8..10053800`) − 2 by `.HandleBreathing`'s −2 per frame while > 0 (raw `1004bb8c..1004bb90`, row 30, P3): net +1.
        XCTAssertEqual(w.player.exertion, 6)
        // +3 has no 0xb9 ceiling: 0xb9 + 3 − 2.
        w.player.exertion = 0xb9
        frame(w, solver, [.right, .run])
        XCTAssertEqual(w.player.exertion, 0xba)
        // RUN + LEFT (raw `10053598..100535f8`): −500 from rest, −300 after, no −0x14a on the ground; +3 each.
        w.active.update(id: w.playerID!) { $0.vx = 0 }
        w.player.exertion = 0
        XCTAssertEqual(vxs(w, solver, [.left, .run], 3), [-500, -800, -1100])
        XCTAssertEqual(w.player.exertion, 3)                            // (+3 − 2) × 3, P3 breathing
        // Releasing RUN clears the run flag (raw `10053610..10053614`).
        frame(w, solver, .left)
        XCTAssertFalse(w.player.runFlag)
    }

    func testStopFromWalkAndRun() throws {
        // Walk to max, release: ground deceleration 800 on the side with no input (row 24): 1100, 300, 0.
        // Run to max, release: 2400, 1600, 800, 0.
        let w = try world()
        let solver = standing(w)
        XCTAssertEqual(vxs(w, solver, .right, 4).last, 1900)
        XCTAssertEqual(vxs(w, solver, [], 3), [1100, 300, 0])
        XCTAssertFalse(w.player.walkRight)
        XCTAssertEqual(vxs(w, solver, [.right, .run], 6).last, 3200)
        XCTAssertEqual(vxs(w, solver, [], 4), [2400, 1600, 800, 0])
        // The walk flags are cleared at the top of every call (`_DAT_100a0730/0734 = 0`), so a released frame
        // decelerates.
        XCTAssertFalse(w.player.walkRight)
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)
    }

    func testTurnRightFromWalkMax() throws {
        // At −1900 hold RIGHT: +0x14f (vx < 1) + 0x14a = −1235; LEFT is not held, so row 24 decelerates the vx < 0
        // side +800 → −435; then 230 (F 2 now: vx > 0), 820, 1410, 2000, 1900.
        let w = try world()
        let solver = standing(w)
        w.active.update(id: w.playerID!) { $0.vx = -1900 }
        w.player.facing = 1
        XCTAssertEqual(vxs(w, solver, .right, 1), [-435])
        XCTAssertEqual(w.player.facing, 1)                              // vx −1235 after the keys: no turn yet
        XCTAssertEqual(vxs(w, solver, .right, 5), [230, 820, 1410, 2000, 1900])
        XCTAssertEqual(w.player.facing, 2)
        // RIGHT turns him even while stunned (no stun test, raw `100539ac..100539bc`).
        w.player.facing = 1
        w.player.stun = 1
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(w.player.facing, 2)
        w.player.stun = 0
        // The mirror turn: at +1900 hold LEFT → 1900 − 335 − 800 = 765, then 765 − 335 − 800 → 0, then −335 …
        w.active.update(id: w.playerID!) { $0.vx = 1900 }
        XCTAssertEqual(vxs(w, solver, .left, 4), [765, 0, -335, -595])
    }

    func testAirHoldRightOscillates() throws {
        // Airborne RIGHT: only the +0x14a while vx < air max 0x76c (raw `100539a4`), then the air drag 100 (row 24):
        // 1900 → 1800, 2130 − 100 = 2030, 1930, 1830, 2060, 1960, 1860, 2090.
        let w = try world(floor: false)
        let id = Player.spawn(world: w, x: 100, y: 0)!
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vx = 1900 }
        XCTAssertEqual(vxs(w, solver, .right, 8), [1800, 2030, 1930, 1830, 2060, 1960, 1860, 2090])
        XCTAssertEqual(player(w).groundKind, 0)
        XCTAssertFalse(w.player.walkRight)                              // walk flags are ground-only
        XCTAssertEqual(w.player.exertion, 0)                            // no exertion in the air
        // Released: the drag alone coasts 1900 to 0 in 19 frames (probe A `kinematics.out`).
        w.active.update(id: id) { $0.vx = 1900 }
        var coast = 0
        while player(w).vx != 0 && coast < 100 {
            frame(w, solver)
            coast += 1
        }
        XCTAssertEqual(coast, 19)
        // Airborne LEFT: −0x14a while vx > −air max (raw `10053770..10053784`) — the mirror sequence.
        w.active.update(id: id) { $0.vx = -1900 }
        XCTAssertEqual(vxs(w, solver, .left, 4), [-1800, -2030, -1930, -1830])
        // The run flag (left from the last grounded frame) raises the air max to 0xc80 (raw `10053980`, `10053754`).
        w.player.runFlag = true
        w.active.update(id: id) { $0.vx = 1900 }
        XCTAssertEqual(vxs(w, solver, .right, 1), [2130])
        w.active.update(id: id) { $0.vx = -1900 }
        XCTAssertEqual(vxs(w, solver, .left, 1), [-2130])
        w.player.runFlag = false
        // Swimming (direct calls, no drag): RIGHT +0xd2 while < 0x76c (raw `1005393c`) and still +0x14a; LEFT −0xd2
        // while > −0x76c (raw `1005370c`), no −0x14a.
        w.player.swim = 1
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 0xd2 + 0x14a)
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, -0xd2)
        w.player.runFlag = true                                         // the swim cap is 0x76c even running
        w.active.update(id: id) { $0.vx = -0x76c }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, -0x76c)
        w.active.update(id: id) { $0.vx = 0x76c }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 0x76c + 0x14a)                     // no +0xd2 at the cap; +0x14a (< 0xc80)
        // One inside each cap still strokes (`vx < 0x76c`, `-0x76c < vx`; raw `10053908..10053940`, `100536d8..10053710`).
        w.active.update(id: id) { $0.vx = 0x76b }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 0x76b + 0xd2 + 0x14a)
        w.active.update(id: id) { $0.vx = -0x76b }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, -0x76b - 0xd2)
        w.player.runFlag = false
        w.player.swim = 0
        // On a rope: ±1000 clamped ±0x960 (raw `10053954..10053970`, `10053724..10053740`); RIGHT still +0x14a.
        w.player.rope = true
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 1000 + 0x14a)
        w.active.update(id: id) { $0.vx = 2000 }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 0x960)
        w.active.update(id: id) { $0.vx = -2000 }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, -0x960)
        w.active.update(id: id) { $0.vx = 0 }
        HandleKeys.run(world: w, keys: .left, ridden: nil)
        XCTAssertEqual(player(w).vx, -1000)                             // unclamped, no −0x14a on a rope
        w.player.rope = false
        // Facing boundary: airborne RIGHT from −0x14a lands on vx 0 exactly — `cmpwi 0; ble` keeps F (raw `100539b4`).
        w.player.facing = 1
        w.active.update(id: id) { $0.vx = -0x14a }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(w.player.facing, 1)
    }

    /// `.PlayerConstraints @ 1004cb4c` (main l. 43991–44123; raw `1004cb4c..1004cc0c`), row 38: x < −64 → −64, else
    /// x > 32·W − 32 → that (hdr `+0xb280`); `+0x14 = x << 8` only on a clamp. y < −128 → −128, `+0x1c = y << 8`, and
    /// then vy < −0x100 → 0. On the glider (`_DAT_100a05e0`) vy < −0x9c4 → −0x9c4. The tests are strict (`cmpwi; bge`).
    func testPlayerConstraintsMapClamps() throws {
        let w = try world(floor: false)
        let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 100))
        let right = Int(w.level.header.gridWidth) * 32 - 32
        func place(x: Int, y: Int, vy: Int32 = 0) {
            w.active.update(id: id) { s in
                s.x = x
                s.y = y
                s.x256 = 0x1234
                s.y256 = 0x5678
                s.vy = vy
            }
        }
        place(x: -65, y: 100)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).x, -64)
        XCTAssertEqual(player(w).x256, -64 << 8)
        XCTAssertEqual(player(w).y256, 0x5678)                          // y in range: untouched
        place(x: -64, y: 100)                                            // the edge itself: no clamp, no x256 store
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).x, -64)
        XCTAssertEqual(player(w).x256, 0x1234)
        place(x: right + 1, y: 100)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).x, right)
        XCTAssertEqual(player(w).x256, Int32(right) << 8)
        place(x: right, y: 100)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).x, right)
        XCTAssertEqual(player(w).x256, 0x1234)
        // y: −129 → −128, y256 stored; vy −0x101 → 0, vy −0x100 kept (`cmpwi r0,-0x100; bge`), vy untouched at −128.
        place(x: 100, y: -129, vy: -0x101)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).y, -128)
        XCTAssertEqual(player(w).y256, -128 << 8)
        XCTAssertEqual(player(w).vy, 0)
        XCTAssertEqual(player(w).x256, 0x1234)
        place(x: 100, y: -129, vy: -0x100)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).vy, -0x100)
        place(x: 100, y: -128, vy: -5000)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).y, -128)
        XCTAssertEqual(player(w).y256, 0x5678)
        XCTAssertEqual(player(w).vy, -5000)                             // off the glider: no vy floor
        // Glider: vy floor −0x9c4 (raw `1004cbec..1004cc0c`), after the y clamp (which zeroes it first).
        w.player.glider = true
        place(x: 100, y: 100, vy: -0x9c5)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).vy, -0x9c4)
        place(x: 100, y: 100, vy: -0x9c4)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).vy, -0x9c4)
        place(x: 100, y: -200, vy: -0x2000)
        Player.constraints(w, id: id)
        XCTAssertEqual(player(w).vy, 0)
        // Through the Handle (row 38, before row 39 re-derives `+0xc` from `+0x14`): spawned left of −64 and above −128,
        // one frame. Row 39 also copies the pixel position and the centre to `fe68`/`fe64` and `fd94`/`fd90`, which no
        // later row rewrites (the record's `+8`/`+0x10` are re-derived by the end pass and `.StandardSpriteCleanup`): a
        // clamp run after row 39 would leave them at (−100, −199) and (−50, −140).
        let w2 = try world(floor: false)
        _ = try XCTUnwrap(Player.spawn(world: w2, x: -100, y: -200))
        frame(w2, TileSolver(world: w2))
        let p2 = player(w2)
        XCTAssertEqual(p2.x, -64)
        XCTAssertEqual(p2.x256, -64 << 8)
        XCTAssertEqual(p2.y, -128)
        XCTAssertEqual(p2.y256, -128 << 8)
        XCTAssertEqual(w2.player.pixelX, -64)
        XCTAssertEqual(w2.player.pixelY, -128)
        XCTAssertEqual(w2.player.centreX, Int16(-64 + p2.hotRect.left + ((p2.hotRect.right - p2.hotRect.left) >> 1)))
        XCTAssertEqual(w2.player.centreY, Int16(-128 + p2.hotRect.top + ((p2.hotRect.bottom - p2.hotRect.top) >> 1)))
    }
}

import XCTest
import HectorResources
@testable import FerazelCore

/// P2 (docs/plans/2026-10-10-ferazel-phase2.md): the player's tile callback `.HitPlayerTileSprite @ 10054ca8` (decompile
/// l. 48113–48358, raw `10054ca8..10055408`) as `Player.handle`'s default — landing / ceiling effects
/// (`.CheckGroundCeilingHitEffects @ 100544d8`), cling and pull-up, the post-jump guard, `.CrunchTile @ 10044928` with
/// the crumble overlay 1210 and `DrawOp.setTile`, and the dust sprite 1201 (`.HandleEffectSprite @ 10061160`).
/// Synthetic 16×16 grids with the FG kind = the tile (as `PlayerMotionTests`), except the crunch test (level 1's own
/// map). Numbers: plan P2 (probe A `jumpcycle.out`), the P1a carry list, and the arithmetic next to each assertion.
final class PlayerTileTests: XCTestCase {

    /// The player stands with his hot-rect bottom (`y + 0x55`) on a kind-3 floor on row 12 (surface Y + 16 = 400).
    private let standY = 400 - 0x55

    private func level1() throws -> LevelFile {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        return try LevelFile.load(from: r, level: 1)
    }

    /// A 16×16 grid: `cells` = (col, row, tile); FG kind = tile; BG empty (kind −1 everywhere, so every cell also
    /// reaches the callback's BG arm, which hands −1 to `.WallBounce` — no collision).
    private func world(_ cells: [(Int, Int, Int)], floor: Bool = true) throws -> SpriteWorld {
        let w = SpriteWorld(level: try level1())
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if floor { for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 } }
        for (c, r, t) in cells { fg[r * 16 + c] = UInt16(t + 1) }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        return w
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// One `.HandlePlayerSprite` with the real tile callback (the default `tileHit`). The previous frame's outputs are
    /// drained first, as the frame driver does after each handle pass, so `cues` / `tileOps` read this frame's.
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        _ = w.player.drainFrameOutputs()
        Player.handle(world: w, keys: keys, solver: solver)
    }

    /// A player standing on the floor with the landing state crafted for a direct `.CheckGroundCeilingHitEffects`:
    /// `+0xce` 3, `0738` 0, not latched, cues drained.
    private func landingState(impact: Int32, lastWater: Int32 = 0) throws -> SpriteWorld {
        let w = try world([])
        _ = standing(w)
        w.active.update(id: w.playerID!) { s in
            s.groundKind = 3
            s.lastWater = lastWater
        }
        w.player.groundLast = 0
        w.player.landedLatch = false
        w.player.impact = impact
        _ = w.player.drainFrameOutputs()
        return w
    }

    /// Spawn on the floor at x 100 and settle: frame 1 lands, frame 2 refills the jump counter to 6.
    private func standing(_ w: SpriteWorld) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        frame(w, solver)
        frame(w, solver)
        XCTAssertEqual(player(w).y256, Int32(standY) << 8)
        XCTAssertEqual(w.player.jumpCounter, 6)
        return solver
    }

    private func dusts(_ w: SpriteWorld) -> [SpriteSlot] { w.active.sprites.filter { $0.type == 0x4b1 } }

    private func landingCues(_ w: SpriteWorld) -> [PlayerCue] {
        w.player.cues.filter { [600, 601, 603].contains($0.snd) }
    }

    // MARK: - landing

    func testFullJumpLandsFrame24() throws {
        // JUMP held 6 frames: apex −25752 at frame 12, then +164 + 440k; at frame 23 the 24.8 position is 252/256 px
        // below the surface — the pixel copy (y256 >> 8) has not crossed it, so the landing is frame 24, impact = the
        // vy before that frame's gravity = 164 + 440·10 = 4564 (row 20, `_DAT_100a0660`).
        let w = try world([])
        let solver = standing(w)
        for f in 1...23 {
            frame(w, solver, f <= 6 ? .jump : [])
            XCTAssertEqual(landingCues(w), [], "frame \(f)")
            XCTAssertEqual(dusts(w).count, 0, "frame \(f)")
        }
        w.player.launched = true                                        // a spring/tumble flag: the landing clears it
        frame(w, solver)
        XCTAssertEqual(w.player.impact, 4564)
        XCTAssertEqual(w.player.carpetLock, 2)                          // FG `.WallBounce` hit → `059c` = 2
        XCTAssertEqual(w.player.impact >> 7, 35)                        // v = 35 < 0x30 → 0 (raw `1005458c`)
        // Landing (`+0xce` ≠ 0, `0738` == 0, `0724` == 0): stop 414 and 427 if playing (Bank correction C7), then
        // v == 0 ∧ impact > 700 ∧ dry → 601 prio 0x14 vol 0x3c (raw `10054658..10054680`).
        // ⚑ P3: then the landing frame's grounded arm, the grounded arm's per-frame `stop 427` (raw `1005074c`/`10050760`, P3).
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .stopIfPlaying, snd: 414), PlayerCue(call: .stopIfPlaying, snd: 427),
                                       PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c),
                                       PlayerCue(call: .stopIfPlaying, snd: 427)])
        XCTAssertTrue(w.player.landedLatch)
        XCTAssertFalse(w.player.launched)
        XCTAssertEqual(player(w).groundKind, 3)
        // Dry and impact > 0x400: `MTNewSprite(0x4b1, +0xc + 0x18, (y256 >> 8) + 0x53, 0xb, −1, .SetupEffectSprite)`
        // after `.WallBounce` put the player on the floor: (100 + 24, 315 + 83).
        let d = dusts(w)
        XCTAssertEqual(d.count, 1)
        XCTAssertEqual(d[0].x256, 124 << 8)
        XCTAssertEqual(d[0].y256, 398 << 8)
        XCTAssertEqual(d[0].x, 124)
        XCTAssertEqual(d[0].y, 398)
        XCTAssertEqual(d[0].layer, 0xb)
        XCTAssertEqual(d[0].handler, .effect)
        XCTAssertTrue(d[0].hasHit)                                     // `.HitEffectSprite` (empty) is installed
        XCTAssertNil(d[0].face)
        XCTAssertFalse(d[0].lightOverlay)                              // Setup `+0x88 = 0`
        XCTAssertEqual(d[0].hotRect, IdleSprites.Rect(top: 16, left: 16, bottom: 32, right: 32))
        // The Effect Handle for 1201: `+0x46` += 1; faces 1…5 of PICT 1201; the 6th call kills it (face 0).
        for k in 1...5 {
            EffectSprite.handle(world: w, id: d[0].id)
            let s = w.active.sprite(id: d[0].id)!
            XCTAssertEqual(s.face, FaceRef(pict: 0x4b1, index: k, set: .encoded))
            XCTAssertFalse(s.dead)
            XCTAssertTrue(s.lightOverlay)                               // `+0x88 = 1` every Handle
        }
        EffectSprite.handle(world: w, id: d[0].id)
        XCTAssertTrue(w.active.sprite(id: d[0].id)!.dead)
        XCTAssertNil(w.active.sprite(id: d[0].id)!.face)
        // Next frame: still on the floor, latched by `0738` = 3 → no second landing.
        frame(w, solver)
        XCTAssertEqual(landingCues(w), [])
        XCTAssertEqual(dusts(w).count, 1)
    }

    func testTapJumpLandsFrame15() throws {
        // JUMP 1 frame: apex −11172 at frame 7; from frame 8 (+164) the 8th descending frame (frame 15) crosses the
        // surface; impact = 164 + 440·6 = 2804 → v = 21 → 0 → 601; 2804 > 0x400 → dust.
        let w = try world([])
        let solver = standing(w)
        for f in 1...14 {
            frame(w, solver, f == 1 ? .jump : [])
            XCTAssertEqual(landingCues(w), [], "frame \(f)")
        }
        frame(w, solver)
        XCTAssertEqual(w.player.impact, 2804)
        XCTAssertEqual(landingCues(w), [PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c)])
        XCTAssertEqual(dusts(w).count, 1)
        XCTAssertEqual(dusts(w)[0].x, 124)
    }

    func testHardLandingVolumes() throws {
        // v = impact >> 7 (srawi), ≥ 0x30 kept, capped at 100; 600 prio 0x14 vol 2v + 0x14 when dry.
        // 6400 → v 50 → vol 120; 20000 → v 156 → 100 → vol 220 (row 23 then clamps vy to 12000 — the impact is
        // read at row 20, before it).
        for (vy, volume) in [(Int32(6400), Int16(120)), (20000, 220)] {
            let w = try world([])
            let solver = standing(w)
            w.active.update(id: w.playerID!) { s in
                s.y256 = Int32(self.standY - 10) << 8
                s.vy = vy
                s.groundKind = 0                                        // airborne last frame: `0738` = 0 at row 20
            }
            frame(w, solver)
            XCTAssertEqual(w.player.impact, vy)
            XCTAssertEqual(landingCues(w), [PlayerCue(call: .reg, snd: 600, priority: 0x14, volume: volume)], "vy \(vy)")
            XCTAssertEqual(dusts(w).count, 1)
        }
        // Wet (`+0x120` ≠ 0): no dust, no 600 (v 50) and no 601 (2000: v 15 → 0, impact > 700) — only the stops.
        for vy in [Int32(6400), 2000] {
            let w = try world([])
            let solver = standing(w)
            w.active.update(id: w.playerID!) { s in
                s.y256 = Int32(self.standY - 5) << 8                    // 5 px up: both land this frame
                s.vy = vy
                s.groundKind = 0
                s.waterRow = 3                                         // `.StandardSpriteHandles` copies it to `+0x120`
            }
            frame(w, solver)
            XCTAssertEqual(w.player.impact, vy)
            XCTAssertEqual(landingCues(w), [], "vy \(vy)")
            XCTAssertEqual(dusts(w).count, 0)
            XCTAssertEqual(w.player.cues.filter { $0.call == .stopIfPlaying }.map(\.snd), [414, 427, 427])  // + P3's grounded stop
        }
        // A BG one-way top (BG kind 103 → `.WallBounceBG` kind 3) landed on sets the timer `04cc` = 0xf (raw
        // `100551fc..10055218`); row 42 counts it down once the same frame → 14.
        do {
            let w = try world([], floor: false)
            var bg = [UInt16](repeating: 0, count: 16 * 16)
            for c in 0..<16 { bg[12 * 16 + c] = 1 }                    // BG tile 0
            var bgKinds = [Int](repeating: 0, count: 0x60)
            bgKinds[0] = 103
            w.tiles = TileGrid(fg: w.tiles.fg, bg: TileMap(width: 16, height: 16, cells: bg), fgKinds: Array(0..<0x60),
                               bgKinds: bgKinds)
            let id = Player.spawn(world: w, x: 100, y: standY - 5)!
            let solver = TileSolver(world: w)
            var landed = false
            for _ in 1...4 where !landed {
                frame(w, solver)
                landed = w.active.sprite(id: id)!.groundKind != 0
            }
            XCTAssertTrue(landed)
            XCTAssertTrue(w.active.sprite(id: id)!.oneWayLanded)
            XCTAssertEqual(w.player.oneWayTimer, 0xe)
        }
        // Exact boundaries, read directly (raw `10054538..10054680`): dust only when impact > 0x400; v = impact >> 7
        // kept from 0x30 (impact 0x1800 → v 48 → 600 vol 116; 0x17ff → v 47 → 0 → 601); 601 only when impact > 700.
        for (impact, dust, cue) in [(Int32(0x400), false, PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c)),
                                    (0x401, true, PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c)),
                                    (0x17ff, true, PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c)),
                                    (0x1800, true, PlayerCue(call: .reg, snd: 600, priority: 0x14, volume: 116))] {
            let w = try landingState(impact: impact)
            GroundCeilingEffects.check(w, id: w.playerID!)
            XCTAssertEqual(dusts(w).count, dust ? 1 : 0, "impact \(impact)")
            XCTAssertEqual(landingCues(w), [cue], "impact \(impact)")
        }
        for (impact, cues) in [(Int32(700), [PlayerCue]()), (701, [PlayerCue(call: .reg, snd: 601, priority: 0x14, volume: 0x3c)])] {
            let w = try landingState(impact: impact)
            GroundCeilingEffects.check(w, id: w.playerID!)
            XCTAssertEqual(landingCues(w), cues, "impact \(impact)")
            XCTAssertEqual(dusts(w).count, 0)
        }
        // The landing gate `0738` == 0 (raw `1005451c..10054528`): last frame's pre-move ground kind 3 → nothing at all.
        do {
            let w = try landingState(impact: 6400)
            w.player.groundLast = 3
            GroundCeilingEffects.check(w, id: w.playerID!)
            XCTAssertEqual(w.player.cues, [])
            XCTAssertFalse(w.player.landedLatch)
            XCTAssertEqual(dusts(w).count, 0)
        }
        // The springboard branch, read directly (`.HitPlayerTileSprite` cannot reach it: a ridden player has `0738` = 3
        // from row 20; `.HitPlayerSprite`, W1, can): ridden `+0xb0` == 0x58c → 603 prio 1 vol 0x55 only when impact
        // > 0x578, and never 600/601.
        for (impact, cue) in [(Int32(0x579), [PlayerCue(call: .reg, snd: 603, priority: 1, volume: 0x55)]),
                              (0x578, [])] {
            let w = try world([])
            _ = standing(w)
            let board = w.newSprite(type: 0x58c, x: 100, y: 400, layer: 5, handler: .platform) { $0.subtype = 0x58c }!
            w.active.update(id: w.playerID!) { s in
                s.groundKind = 3
                s.ridden = board
            }
            w.player.groundLast = 0
            w.player.landedLatch = false
            w.player.impact = impact
            w.player.cues = []
            GroundCeilingEffects.check(w, id: w.playerID!)
            XCTAssertEqual(landingCues(w), cue, "impact \(impact)")
            XCTAssertTrue(w.player.landedLatch)
            XCTAssertEqual(dusts(w).count, 1)                           // impact > 0x400, dry
        }
    }

    // MARK: - cling and pull-up

    func testClingOnKind0() throws {
        // A kind-0 tile (hot rect = the cell's left half, face at X + 16) at (5, 10): X 160, Y 320. The player, airborne,
        // moves left into it with LEFT held: hot-rect left x + 0x26 = 175 < 176.
        let w = try world([(5, 10, 0), (5, 11, 0)], floor: false)
        let id = Player.spawn(world: w, x: 137, y: 279)!
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vx = -500 }
        let expectedRate = { () -> Int32 in var r = w.rng; return r.soundRate() }()
        // Row 19 alone (the pre-move pass) with the callback as `Player.handle` builds it.
        w.player.cues = []
        w.player.jumpCounter = 4                                        // e.g. mid-sustain: the first cling zeroes it
        solver.separateFromTiles(id, pass: PlayerTiles.hit(keys: .left))
        XCTAssertEqual(w.player.climb, 1)
        XCTAssertEqual(w.player.facing, 1)                              // `_DAT_100a5f5a` = r23 = 1 (the LEFT side)
        XCTAssertEqual(w.player.wallSide, 1)
        XCTAssertTrue(player(w).mirrored)                               // `+0x17e = 1`
        XCTAssertEqual(w.player.jumpCounter, 0)                         // first cling frame (`0754` == 0)
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(player(w).vy, 0)
        XCTAssertEqual(player(w).x, 138)                                // `.WallBounce` kind 0: X + 16 − 0x26
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 455, priority: 1, volume: 0x3c,
                                                 position: player(w).centre, rate: expectedRate)])
        // Cling gates (raw `10054f04..10054f40`): `0738` ≠ 0, rope, no-cling > 0, glider each block it.
        for gate in 0..<4 {
            let g = try world([(5, 10, 0), (5, 11, 0)], floor: false)
            let gid = Player.spawn(world: g, x: 137, y: 279)!
            g.active.update(id: gid) { $0.vx = -500 }
            switch gate {
            case 0: g.player.groundLast = 3
            case 1: g.player.rope = true
            case 2: g.player.noCling = 1
            default: g.player.glider = true
            }
            TileSolver(world: g).separateFromTiles(gid, pass: PlayerTiles.hit(keys: .left))
            XCTAssertEqual(g.player.climb, 0, "gate \(gate)")
        }
        // Kind 5 (the top-left quarter) clings only while dy < 4 (raw `10054e58..10054e6c`): y 280 → dy 3, y 281 → 4.
        for (y, clings) in [(280, true), (281, false)] {
            let g = try world([(5, 10, 5)], floor: false)
            let gid = Player.spawn(world: g, x: 137, y: y)!
            g.active.update(id: gid) { $0.vx = -500 }
            TileSolver(world: g).separateFromTiles(gid, pass: PlayerTiles.hit(keys: .left))
            XCTAssertEqual(g.player.climb, clings ? 1 : 0, "y \(y)")
        }
        // The kind is taken mod 100 (raw `10054da4..10054dec`, `mulhw` by 0x51eb851f): FG kind 100 (material 1, base 0)
        // clings like 0; kind 1 (a ceiling) never clings.
        for (kind, clings) in [(100, true), (1, false)] {
            let g = try world([(5, 10, 9), (5, 11, 9)], floor: false)
            var kinds = Array(0..<0x60)
            kinds[9] = kind
            g.tiles = TileGrid(fg: g.tiles.fg, bg: g.tiles.bg, fgKinds: kinds, bgKinds: g.tiles.bgKinds)
            let gid = Player.spawn(world: g, x: 137, y: 279)!
            g.active.update(id: gid) { $0.vx = -500 }
            TileSolver(world: g).separateFromTiles(gid, pass: PlayerTiles.hit(keys: .left))
            XCTAssertEqual(g.player.climb, clings ? 1 : 0, "kind \(kind)")
        }
        // No LEFT and not clinging last frame: no cling, `.WallBounce` stops vx.
        do {
            let g = try world([(5, 10, 0), (5, 11, 0)], floor: false)
            let gid = Player.spawn(world: g, x: 137, y: 279)!
            g.active.update(id: gid) { $0.vx = -500 }
            TileSolver(world: g).separateFromTiles(gid, pass: PlayerTiles.hit(keys: []))
            XCTAssertEqual(g.player.climb, 0)
            XCTAssertEqual(g.active.sprite(id: gid)!.vx, 0)
        }

        // The rest of frame 1: row 21's else-refill makes the counter 3 (airborne, clinging — P1a carry); the move
        // re-clings through `0754` (no second 455).
        w.player.cues = []
        frame(w, solver, .left)
        XCTAssertEqual(w.player.climb, 1)
        XCTAssertEqual(w.player.jumpCounter, 3)
        XCTAssertFalse(w.player.cues.contains { $0.snd == 455 })
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(player(w).vy, 0)
        XCTAssertEqual(player(w).x, 138)
        // Row 33's cling arm (l. 45750–45790), no pull-up: crouch 0, air counter 0, the climb phase wraps (13 → 1,
        // 0 → 12, 12 kept); with a wand phase ≥ 1 the phase is 1. Faces (P3): 1012[(phase − 1) >> 1]; with a wand phase
        // 1031[wand], 6 drawn as 5 (`07a8`, l. 45800–45806).
        for (phase, wand, expected) in [(Int16(13), Int16(0), Int16(1)), (0, 0, 12), (12, 0, 12), (5, 1, 1), (5, 6, 1)] {
            w.player.climbPhase = phase
            w.player.wandPhase = wand
            w.player.crouch = 3
            w.player.airCounter = 5
            frame(w, solver, .left)
            XCTAssertEqual(w.player.climb, 1)
            XCTAssertEqual(w.player.climbPhase, expected, "phase \(phase) wand \(wand)")
            XCTAssertEqual(player(w).face, wand == 0
                           ? FaceRef(pict: 1012, index: Int(expected - 1) >> 1, set: .encoded)
                           : FaceRef(pict: 1031, index: wand == 6 ? 5 : Int(wand), set: .encoded))
            XCTAssertEqual(w.player.crouch, 0)
            XCTAssertEqual(w.player.airCounter, 0)
        }
        w.player.wandPhase = 0
        // Climb ±1000 (the climb block, l. 47681–47724) eased 100 toward 0 by row 26 before the move: UP moves −900,
        // DOWN +900 (vy is zeroed again by the cling).
        var y0 = player(w).y256
        frame(w, solver, .up)
        XCTAssertEqual(player(w).y256 - y0, -900)
        y0 = player(w).y256
        frame(w, solver, .down)
        XCTAssertEqual(player(w).y256 - y0, 900)
        XCTAssertEqual(w.player.climb, 1)
        // Double Speed: ±0x578 (raw `10053e4c..`) → −0x578 + 100 = −1300.
        w.player.doubleSpeed = true
        y0 = player(w).y256
        frame(w, solver, .up)
        XCTAssertEqual(player(w).y256 - y0, -1300)
        w.player.doubleSpeed = false
        // A cast begun this call (`06e0` == 0) or a wand phase with the wand held < 5: vy 0 instead of the climb.
        for (began, wand, held) in [(true, Int16(0), Int16(0)), (false, 1, 4)] {
            w.player.noCastBegan = !began
            w.player.wandPhase = wand
            w.player.wandHeld = held
            w.active.update(id: id) { $0.vy = 77 }
            HandleKeys.climbBlock(w, id: id, keys: .up)
            XCTAssertEqual(player(w).vy, 0, "began \(began)")
        }
        w.player.wandPhase = 0
        w.player.wandHeld = 0
        // Row 26 on its own: ease ±100 (clamp ±4000) and vx ∓0x800 into the wall, climb cleared.
        for (side, vy, ey, ex) in [(Int16(1), Int32(-1000), Int32(-900), Int32(-0x800)), (1, 1000, 900, -0x800),
                                   (2, -4500, -4000, 0x800), (2, 4500, 4000, 0x800), (1, 50, 0, -0x800)] {
            let g = try world([], floor: false)
            let gid = Player.spawn(world: g, x: 100, y: 100)!
            g.player.climb = 1
            g.player.wallSide = side
            g.active.update(id: gid) { $0.vy = vy }
            Player.climbPreMove(g, id: gid)
            XCTAssertEqual(g.active.sprite(id: gid)!.vy, ey, "vy \(vy)")
            XCTAssertEqual(g.active.sprite(id: gid)!.vx, ex)
            XCTAssertEqual(g.player.climb, 0)
            XCTAssertEqual(g.player.lastClimb, 1)
        }
        // Wall jump from the cling (counter 3): vx +0x8ca (wall on the left), vy −0x8cb overwritten in the same call by
        // the sustain: −3200 − ((0x8ca + 0x4e2) >> 3) = −3637; counter 2; climb 0; 414; guard 2.
        do {
            let g = try world([(5, 10, 0), (5, 11, 0)], floor: false)
            let gid = Player.spawn(world: g, x: 137, y: 279)!
            let gs = TileSolver(world: g)
            g.active.update(id: gid) { $0.vx = -500 }
            Player.handle(world: g, keys: .left, solver: gs)
            XCTAssertEqual(g.player.jumpCounter, 3)
            HandleKeys.run(world: g, keys: .jump, ridden: nil)
            XCTAssertEqual(g.active.sprite(id: gid)!.vx, 0x8ca)
            XCTAssertEqual(g.active.sprite(id: gid)!.vy, -3637)
            XCTAssertEqual(g.player.jumpCounter, 2)
            XCTAssertEqual(g.player.climb, 0)
            XCTAssertEqual(g.player.postJumpGuard, 2)
            XCTAssertEqual(g.player.cues.last, PlayerCue(call: .reg, snd: 414, priority: 1, volume: 0x9c))
        }
        // The mirror: wall on the right (kind 2 face at X + 16, approached moving right with RIGHT) → wall side 2, F 2,
        // `+0x17e` 0, and the wall jump goes −0x8ca.
        do {
            let g = try world([(5, 10, 2), (5, 11, 2)], floor: false)
            let gid = Player.spawn(world: g, x: 115, y: 279)!       // right edge 115 + 0x3e = 177 > 176
            let gs = TileSolver(world: g)
            g.active.update(id: gid) { $0.vx = 500 }
            Player.handle(world: g, keys: .right, solver: gs)
            XCTAssertEqual(g.player.climb, 1)
            XCTAssertEqual(g.player.wallSide, 2)
            XCTAssertEqual(g.player.facing, 2)
            XCTAssertFalse(g.active.sprite(id: gid)!.mirrored)
            HandleKeys.run(world: g, keys: .jump, ridden: nil)
            XCTAssertEqual(g.active.sprite(id: gid)!.vx, -0x8ca)
            XCTAssertEqual(g.active.sprite(id: gid)!.vy, -3637)
        }
        // Wall jump with DOWN held: the refill arm sets spin, cooldown 0x14 and counter 6, then the sustain → 5.
        do {
            let g = try world([(5, 10, 0), (5, 11, 0)], floor: false)
            let gid = Player.spawn(world: g, x: 137, y: 279)!
            g.active.update(id: gid) { $0.vx = -500 }
            Player.handle(world: g, keys: .left, solver: TileSolver(world: g))
            HandleKeys.run(world: g, keys: [.jump, .down], ridden: nil)
            XCTAssertTrue(g.player.spin)
            XCTAssertEqual(g.player.spinCooldown, 0x14)
            XCTAssertEqual(g.player.jumpCounter, 5)
            XCTAssertTrue(g.player.cues.contains(PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba)))
        }
        // Lost the wall (row 29): the wall goes away while clinging → the move does not re-cling → vx = vy = 0.
        let empty = try world([], floor: false)
        w.tiles = empty.tiles
        w.active.update(id: id) { $0.vy = 0 }
        frame(w, solver, .up)                                           // climb −1000 → −900 before the move
        XCTAssertEqual(w.player.climb, 0)
        XCTAssertEqual(w.player.lastClimb, 1)
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(player(w).vy, 0)
    }

    func testLedgePullUp() throws {
        // A kind-4 ledge (hot rect = the lower-left quarter: top Y + 16, face X + 16) at (5, 10): X 160, Y 320; the cell
        // above (5, 9) empty. dy = (y + 59) − (Y + 16) = 2 > 0 → cling; (y + 59 − 4) − (Y + 16) = −2 < 1 → pull-up 1 and
        // 416 vol 0xab (raw `10054fd8..10055044`).
        let w = try world([(5, 10, 4)], floor: false)
        let id = Player.spawn(world: w, x: 137, y: 279)!
        let solver = TileSolver(world: w)
        w.active.update(id: id) { $0.vx = -500 }
        let rate = { () -> Int32 in var r = w.rng; return r.soundRate() }()
        let c0 = player(w).centre                                       // `+0xe` as the Setup left it (row 39 later)
        frame(w, solver, .left)
        XCTAssertEqual(Array(w.player.cues.prefix(2)), [
            PlayerCue(call: .threeDRand, snd: 455, priority: 1, volume: 0x3c, position: c0, rate: rate),
            PlayerCue(call: .reg, snd: 416, priority: 1, volume: 0xab)])
        XCTAssertEqual(w.player.climb, 1)
        XCTAssertEqual(w.player.pullUp, 2)                              // set 1 in row 19, row 33 counts it up
        XCTAssertEqual(player(w).face, FaceRef(pict: 1023, index: 0, set: .encoded))   // P3: 1023[(n − 1) >> 1], n 1
        // The move's vx −0x800 is pushed back by kind 4 (X + 16 − 0x26 = 138); row 40 then draws him 0x14 px left while
        // pulling up, mirrored (`+0xc` only — the 24.8 position stays).
        XCTAssertEqual(SpriteWorld.pixel(player(w).x256), 138)
        XCTAssertEqual(player(w).x, 138 - 0x14)
        let x0 = SpriteWorld.pixel(player(w).x256), y0 = player(w).y
        for f in 2...19 {
            frame(w, solver)
            XCTAssertEqual(w.player.pullUp, Int16(f + 1), "frame \(f)")
            XCTAssertEqual(player(w).face, FaceRef(pict: 1023, index: (f - 1) >> 1, set: .encoded), "frame \(f)")
            XCTAssertEqual(SpriteWorld.pixel(player(w).x256), x0)
            XCTAssertEqual(player(w).y, y0)
            XCTAssertEqual(w.player.crouch, 0)
        }
        // Frame 20: `_DAT_100a06a0` 21 > 0x14 → x256 −= 0x2000 (`+0x17e` set: wall on the left), y256 −= 0x1600, pull-up
        // 0, climb 0, crouch 2, `0738` = 1, `+0xce` = 1 (l. 45792–45812). Row 39 copies the moved position into
        // `fe68`/`fe64`. The end pass reaches the ledge cell, but `.WallBounce` kind 4 tests the centred rect (left
        // 106 + 0x26 = 144, right 106 + 0x33 = 157), which misses the ledge face at 160: no snap — he is left 6 px into
        // the ledge's corner, on `+0xce` 1.
        frame(w, solver)
        XCTAssertEqual(w.player.pullUp, 0)
        XCTAssertEqual(w.player.climb, 0)
        XCTAssertEqual(w.player.crouch, 2)
        XCTAssertEqual(player(w).face, FaceRef(pict: 1011, index: 2, set: .encoded))   // P3: landed crouched, `07e0 + 0x68`
        XCTAssertEqual(w.player.groundLast, 1)
        XCTAssertEqual(player(w).groundKind, 1)
        XCTAssertEqual(Int(w.player.pixelX), x0 - 32)
        XCTAssertEqual(Int(w.player.pixelY), y0 - 22)
        XCTAssertEqual(player(w).x, x0 - 32)                            // no draw offset once the pull-up is over
        XCTAssertEqual(player(w).y, y0 - 22)
        XCTAssertEqual(player(w).y256, Int32(y0) << 8 - 0x1600)
        // Occupied above → no pull-up: y += 1000, vy 0, climb 1 (raw `10055050..1005507c`).
        let g = try world([(5, 10, 4), (5, 9, 1)], floor: false)
        let gid = Player.spawn(world: g, x: 137, y: 279)!
        g.active.update(id: gid) { $0.vx = -500 }
        let yBefore = g.active.sprite(id: gid)!.y256
        TileSolver(world: g).separateFromTiles(gid, pass: PlayerTiles.hit(keys: .left))
        XCTAssertEqual(g.player.pullUp, 0)
        XCTAssertEqual(g.player.climb, 1)
        XCTAssertEqual(g.active.sprite(id: gid)!.vy, 0)
        XCTAssertFalse(g.player.cues.contains { $0.snd == 416 })
        // Exactly +1000: `.WallBounce` kind 4's restore returns to `+6`, which the branch rewrote (282), so the integer
        // does not change and the 24.8 position is not re-synced.
        XCTAssertEqual(g.active.sprite(id: gid)!.y256, yBefore + 1000)
        // dy ≤ 0 on a ledge kind: no cling at all.
        let h = try world([(5, 10, 4)], floor: false)
        let hid = Player.spawn(world: h, x: 137, y: 277)!               // dy = 336 − 336 = 0
        h.active.update(id: hid) { $0.vx = -500 }
        TileSolver(world: h).separateFromTiles(hid, pass: PlayerTiles.hit(keys: .left))
        XCTAssertEqual(h.player.climb, 0)
        // Every ledge kind (raw `10054e2c..10054e4c` left: 4, 0x14, 0x2d; `10054eb4..10054ed4` right: 7, 0x13, 0x2f), each
        // touched with its hot rect: dy 2 → cling and pull-up 1 with 416; dy 0 → nothing. Left x puts the hot-rect left
        // edge (x + 0x26) one px inside the tile rect's right edge; right x puts x + 0x3e one px inside its left edge.
        for (kind, right, x) in [(4, false, 137), (0x14, false, 153), (0x2d, false, 137),
                                 (7, true, 115), (0x13, true, 99), (0x2f, true, 115)] {
            for (y, clings) in [(279, true), (277, false)] {
                let k = try world([(5, 10, kind)], floor: false)
                let kid = Player.spawn(world: k, x: x, y: y)!
                k.active.update(id: kid) { $0.vx = right ? 500 : -500 }
                TileSolver(world: k).separateFromTiles(kid, pass: PlayerTiles.hit(keys: right ? .right : .left))
                XCTAssertEqual(k.player.climb, clings ? 1 : 0, "kind \(kind) y \(y)")
                XCTAssertEqual(k.player.pullUp, clings ? 1 : 0, "kind \(kind) y \(y)")
                XCTAssertEqual(k.player.cues.contains(PlayerCue(call: .reg, snd: 416, priority: 1, volume: 0xab)), clings)
                if clings { XCTAssertEqual(k.player.wallSide, right ? 2 : 1) }
            }
        }
        // The pull-up start `((y >> 8) + 59 − 4) − (Y + 16) < 1` (raw `10055004..10055028`): y 281 → 0 → pull-up;
        // y 282 → 1 → a cling without a pull-up.
        for (y, pulls) in [(281, true), (282, false)] {
            let k = try world([(5, 10, 4)], floor: false)
            let kid = Player.spawn(world: k, x: 137, y: y)!
            k.active.update(id: kid) { $0.vx = -500 }
            TileSolver(world: k).separateFromTiles(kid, pass: PlayerTiles.hit(keys: .left))
            XCTAssertEqual(k.player.climb, 1)
            XCTAssertEqual(k.player.pullUp, pulls ? 1 : 0, "y \(y)")
        }
        // Kind 6 (top-right quarter) clings on the right only while dy < 4: y 280 → 3, y 281 → 4.
        for (y, clings) in [(280, true), (281, false)] {
            let k = try world([(5, 10, 6)], floor: false)
            let kid = Player.spawn(world: k, x: 115, y: y)!
            k.active.update(id: kid) { $0.vx = 500 }
            TileSolver(world: k).separateFromTiles(kid, pass: PlayerTiles.hit(keys: .right))
            XCTAssertEqual(k.player.climb, clings ? 1 : 0, "y \(y)")
        }
        // The right-wall pull-up: kind 7 at (5, 10), `+0x17e` 0 → x256 += 0x2000 on frame 20 (no draw offset: not
        // mirrored). Kind 7 keeps its right edge: the wall puts him at X + 16 − 0x3e = 114.
        let k = try world([(5, 10, 7)], floor: false)
        let kid = Player.spawn(world: k, x: 115, y: 279)!
        let ks = TileSolver(world: k)
        k.active.update(id: kid) { $0.vx = 500 }
        frame(k, ks, .right)
        XCTAssertEqual(k.player.pullUp, 2)
        XCTAssertEqual(SpriteWorld.pixel(k.active.sprite(id: kid)!.x256), 114)
        for _ in 2...19 { frame(k, ks) }
        XCTAssertEqual(k.player.pullUp, 20)
        frame(k, ks)
        XCTAssertEqual(k.player.pullUp, 0)
        XCTAssertEqual(k.player.pixelX, 114 + 32)
        XCTAssertEqual(k.active.sprite(id: kid)!.x256, (114 << 8) + 0x2000)   // the wall re-synced 24.8 to 114 first
        XCTAssertEqual(k.player.pixelY, 279 - 22)
    }

    // MARK: - the post-jump guard, ceilings

    func testPostJumpGuardSkipsFG() throws {
        // A kind-0 wall (face X + 16 = 112) on col 3, rows 10–11, beside the floor. Standing at x 75 (left edge 113).
        // vx −1000 without LEFT (no cling). The jump frame sets `04d8` = 2: that frame and the next the FG `.WallBounce`
        // is skipped (raw `1005508c..10055098`), so he passes into the wall; row 13 counts it to 0 on the third frame,
        // and the wall pushes him back out (x = 112 − 0x26 = 74, vx 0).
        let w = try world([(3, 10, 0), (3, 11, 0)])
        XCTAssertNotNil(Player.spawn(world: w, x: 75, y: standY))
        let solver = TileSolver(world: w)
        frame(w, solver)
        frame(w, solver)
        XCTAssertEqual(player(w).x, 75)
        w.active.update(id: w.playerID!) { $0.vx = -1000 }
        frame(w, solver, .jump)
        XCTAssertEqual(w.player.postJumpGuard, 2)
        XCTAssertEqual(player(w).vx, -900)                              // air drag 100, not stopped
        XCTAssertLessThan(player(w).x + 0x26, 112)
        frame(w, solver)
        XCTAssertEqual(w.player.postJumpGuard, 1)
        XCTAssertEqual(player(w).vx, -800)
        XCTAssertLessThan(player(w).x + 0x26, 112)
        frame(w, solver)
        XCTAssertEqual(w.player.postJumpGuard, 0)
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(player(w).x, 74)
    }

    func testHeadBonkOncePerAirtime() throws {
        // A kind-1 ceiling (hot rect = the top half, underside Y + 16) at row 8 (Y 256 → 272) over the whole width. A full
        // jump reaches head y 249 < 272: the bonk frame plays 404 prio 0x14 vol 0xa0 once — the move pass latches
        // `0720`, the end pass sees `+0xcf` again but the latch holds; the next frame's pre-move pass sees the stale
        // `+0xcf` (cleared at row 25) under the latch, and after that vy ≥ 0 (no new `+0xcf`).
        let w = try world((0..<16).map { ($0, 8, 1) })
        let solver = standing(w)
        var bonks: [Int] = []
        for f in 1...40 {
            frame(w, solver, f <= 6 ? .jump : [])
            bonks += w.player.cues.filter { $0.snd == 404 }.map { _ in f }
            if bonks.count == 1 && bonks[0] == f {
                XCTAssertEqual(w.player.cues.filter { $0.snd == 404 },
                               [PlayerCue(call: .reg, snd: 404, priority: 0x14, volume: 0xa0)])
                XCTAssertTrue(w.player.bumpedLatch)
                XCTAssertEqual(player(w).vy, 0)
                XCTAssertEqual(player(w).y + 0x22, 272)
            }
        }
        XCTAssertEqual(bonks.count, 1)
        XCTAssertEqual(player(w).groundKind, 3)                         // landed again
        // The latch clears before the next move: a second jump bonks again, once.
        bonks = []
        for f in 1...40 {
            frame(w, solver, f <= 6 ? .jump : [])
            bonks += w.player.cues.filter { $0.snd == 404 }.map { _ in f }
        }
        XCTAssertEqual(bonks.count, 1)
        // Dying blocks it (raw `100546bc..100546c8`).
        let g = try world([])
        _ = standing(g)
        g.active.update(id: g.playerID!) { $0.ceilingHit = 1 }
        g.player.bumpedLatch = false
        g.player.dying = 1
        g.player.cues = []
        GroundCeilingEffects.check(g, id: g.playerID!)
        XCTAssertEqual(g.player.cues, [])
        g.player.dying = 0
        GroundCeilingEffects.check(g, id: g.playerID!)
        XCTAssertEqual(g.player.cues, [PlayerCue(call: .reg, snd: 404, priority: 0x14, volume: 0xa0)])
        // The glider skips the whole routine (raw `10054504..1005450c`).
        g.player.bumpedLatch = false
        g.player.glider = true
        g.player.cues = []
        GroundCeilingEffects.check(g, id: g.playerID!)
        XCTAssertEqual(g.player.cues, [])
        XCTAssertFalse(g.player.bumpedLatch)
    }

    func testHeadBumpZeroesJumpCounter() throws {
        // A kind-1 ceiling at row 9 (underside 304), head at 349: JUMP held, the 4th frame (−45.6 px) bonks during the
        // sustain → vy 0 after the move's one step, `+0xce` 0, climb 0 → counter 0 (raw `1004b998..1004b9c8`, Bank
        // correction A3); JUMP still held then finds counter 0: no more sustain, gravity takes over.
        let w = try world((0..<16).map { ($0, 9, 1) })
        let solver = standing(w)
        for f in 1...3 {
            frame(w, solver, .jump)
            XCTAssertEqual(w.player.jumpCounter, Int16(6 - f))
        }
        frame(w, solver, .jump)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 404 }.count, 1)
        XCTAssertEqual(player(w).vy, 0)
        XCTAssertEqual(w.player.jumpCounter, 0)                         // would be 2 without the bump
        frame(w, solver, .jump)
        XCTAssertEqual(w.player.jumpCounter, 0)
        XCTAssertEqual(player(w).vy, 440)                               // no sustain: 0 + gravity
    }

    // MARK: - crunch tiles

    func testCrunchKind3Collapses() throws {
        // Level 1, row 36, cols 119…121: FG cells 0x1334, 0x1304, 0x1304 — crunch direction 1 (bits 12–15), crunch kind
        // 3 (bits 8–11), tiles 51 / 3 / 3 (FG kind 3: floor at Y + 16 = 1168); row 37 is tile 95. The player stands
        // centred on col 120 (x 3806: hot rect 3844…3868; y 1168 − 0x55 = 1083), alone in the world.
        // Derivation (triggers-background-2 §2.3; `.SeparateFromTiles2` l. 35330–35352, `.CrunchTile` raw
        // `10044928..10044c34`, `.HandleEffectSprite` 1210 arm l. 54099–54125, `.DestroyCrunchTile` raw
        // `100445b0..100446f0`, `.ReshapeCrunchedTile` raw `10043f14..100444c4`):
        // - frame 1 lands from the spawn (`+0xeb` 0 at row 12: not grounded yet);
        // - frame 2: `+0xeb` 1 (grounded); the move's 1.7 px sink meets FG cell (120, 36) (the first of the nine whose
        //   hot rect he touches) → its 2×2 crunch scan (119…120, 35…36), `+0xeb` tested once before the scan: the
        //   boxes (+16…+48) of (119, 36) and (120, 36) both meet him → two layer-2 calls in one scan. Each: vy 440 ≤
        //   0x9c4 → `+0xeb` = 0 → `.CrunchTile(pos, 0)`: crunch kind 3 is crunched even at strength 0 → no overlay yet →
        //   `.MakeCrunchSprite(tx, 36, 2)` (1210 at (tx·32 + 16, 1168); `.SetupEffectSprite` stores layer 0xb, after the
        //   player), armed (`+0x16c` 1), 423, `+0x46` = R(3) + 1 then 0xf — two overlays, slots 0 and 1, two draws;
        //   they are not handled this frame (inserted after the walk's saved next);
        // - frames 3…17: their Handles count `+0x46` 15 → 0; at 0 (frame 17) hp 2 → 1, face `+0x14c` − hp = 1; the
        //   player's two `.CrunchTile`s each frame see `+0x46` > 0 (he runs first) and do nothing;
        // - frame 18: the first call sees `+0x46` 0 → hp 0 → destroy (119, 36): overlay killed (its slot stays), 424,
        //   `.DestroyCrunchTile(119, 36, 1, 1, 1, 0)`: (119, 36) pos 5 kind 3 → tile 4; (120, 36) pos 7 kind 3 → 7;
        //   (119, 37) pos 6, tile 95 (≥ 0x50: the tile itself) → 10; (120, 37) pos 8, 95 → 9; direction of (119, 36) → 0.
        //   The second call destroys (120, 36) the same way, on the cells as just rewritten: (120, 36) pos 5, now tile 7
        //   (kind 7) → −1; (121, 36) pos 7 kind 3 → 7; (120, 37) pos 6, now 9 → 3; (121, 37) pos 8, 95 → 9; direction
        //   of (120, 36) → 0. Each write keeps the high byte (crunch kind and direction): ten `setTile`s.
        func run() throws -> (log: [String], world: SpriteWorld) {
            let w = SpriteWorld(level: try level1())
            XCTAssertNotNil(Player.spawn(world: w, x: 3806, y: 1083))
            w.player.tileCacheValid = true                              // as if E1b's `.FillCachedTileArray` had run
            let solver = TileSolver(world: w)
            var log: [String] = []
            for f in 1...18 {
                w.handleSprites { w, id in
                    switch w.active.record(id: id)!.handler {
                    case .player: Player.handle(world: w, keys: [], solver: solver)
                    case .effect: EffectSprite.handle(world: w, id: id)
                    default: break
                    }
                }
                // The frame driver's drain, once after the whole handle pass (the overlay's outputs included).
                let out = w.player.drainFrameOutputs()
                for c in out.cues where c.snd == 423 || c.snd == 424 { log.append("\(f): \(c)") }
                for op in out.tileOps { log.append("\(f): \(op)") }
                if let o = w.active.sprites.first(where: { $0.type == 0x4ba }) {
                    log.append("\(f): overlay \(o.phase) \(o.hp) \(o.face?.index ?? -1) \(o.dead)")
                }
            }
            return (log, w)
        }
        let (log, w) = try run()
        let overlays = w.active.sprites.filter { $0.type == 0x4ba }
        XCTAssertEqual(overlays.map(\.x), [3824, 3856])
        XCTAssertEqual(overlays.map(\.y), [1168, 1168])
        XCTAssertEqual(overlays.map(\.layer), [0xb, 0xb])
        XCTAssertEqual(overlays.map(\.classTimer), [2, 2])               // `+0x14c` = hp at creation
        XCTAssertEqual(overlays.map(\.classWord154), [119, 120])
        XCTAssertEqual(overlays.map(\.classWord158), [36, 36])
        XCTAssertEqual(overlays.map(\.classWord15c), [1, 1])
        XCTAssertEqual(overlays.map(\.classWord16c), [1, 1])
        XCTAssertEqual(overlays.map(\.classWord150), [0, 1])
        XCTAssertEqual(overlays.map(\.dead), [true, true])
        // Not freed: killed by `.CrunchTile`, so their Handles (which free the slot) never reach hp < 1.
        XCTAssertEqual(Array(w.player.crunchSprites.prefix(3)), [overlays[0].id, overlays[1].id, nil])
        // `.STPlay3DSound(423 / 424, 1, 0x100, pos)` at the crunch point (`stw r3,0x78(r1)` … `lwz r6,0x78(r1)`): no draw,
        // no idle gate on these.
        func c3d(_ snd: Int16, _ x: Int) -> String {
            "\(PlayerCue(call: .threeD, snd: snd, priority: 1, volume: 0x100, position: SpriteSlot.Point(x: x, y: 1152)))"
        }
        XCTAssertEqual(Array(log.prefix(2)), ["2: \(c3d(423, 3808))", "2: \(c3d(423, 3840))"])
        XCTAssertEqual(log.filter { $0.hasPrefix("2: overlay") }, ["2: overlay 15 2 -1 false"])
        XCTAssertEqual(log.filter { $0.hasPrefix("3: overlay") }, ["3: overlay 14 2 0 false"])
        XCTAssertEqual(log.filter { $0.hasPrefix("16: overlay") }, ["16: overlay 1 2 0 false"])
        XCTAssertEqual(log.filter { $0.hasPrefix("17: overlay") }, ["17: overlay 0 1 1 false"])
        XCTAssertEqual(log.filter { $0.hasPrefix("18:") }, [
            "18: \(c3d(424, 3808))", "18: \(c3d(424, 3840))",
            "18: \(DrawOp.setTile(col: 119, row: 36, fg: 0x1305))",
            "18: \(DrawOp.setTile(col: 120, row: 36, fg: 0x1308))",
            "18: \(DrawOp.setTile(col: 119, row: 37, fg: 0x000b))",
            "18: \(DrawOp.setTile(col: 120, row: 37, fg: 0x000a))",
            "18: \(DrawOp.setTile(col: 119, row: 36, fg: 0x0305))",
            "18: \(DrawOp.setTile(col: 120, row: 36, fg: 0x1300))",
            "18: \(DrawOp.setTile(col: 121, row: 36, fg: 0x1308))",
            "18: \(DrawOp.setTile(col: 120, row: 37, fg: 0x0004))",
            "18: \(DrawOp.setTile(col: 121, row: 37, fg: 0x000a))",
            "18: \(DrawOp.setTile(col: 120, row: 36, fg: 0x0300))",
            "18: overlay 0 0 1 true"])
        XCTAssertEqual(log.filter { $0.contains("setTile") }.count, 10)    // no map change before frame 18
        XCTAssertEqual(w.tiles.fg.cell(col: 119, row: 36), 0x0305)
        XCTAssertEqual(w.tiles.fg.cell(col: 120, row: 36), 0x0300)
        XCTAssertEqual(w.tiles.fg.cell(col: 121, row: 36), 0x1308)       // still a crunch anchor (direction 1, kind 3)
        XCTAssertEqual(w.tiles.fg.cell(col: 119, row: 37), 0x000b)
        XCTAssertEqual(w.tiles.fg.cell(col: 120, row: 37), 0x0004)
        XCTAssertEqual(w.tiles.fg.cell(col: 121, row: 37), 0x000a)
        XCTAssertEqual(w.globals.crunchLog, [CrunchLogEntry(level: 1, col: 119, row: 36),
                                            CrunchLogEntry(level: 1, col: 120, row: 36)])
        XCTAssertFalse(w.player.tileCacheValid)
        // The two R(3) draws of frame 2 are the only draws: the stream is 2 steps past the seed. ⚠️ These RNG numbers
        // hold up to the destroy only: the frame-18 destroys omit `.ExplodeFaceIntoParticles`' 4 draws per pixel
        // ("⚑ P2 carry → E1a"), so the stream after them is not the original's yet.
        var expected = FastRand(seed: 1)
        _ = expected.next(3)
        _ = expected.next(3)
        XCTAssertEqual(w.rng.seed, expected.seed)
        // The same crunch through `FerazelSession.step` (P3 wiring): the level-start player is replaced by one spawned
        // at the crunch spot (its held item and trails stay, inert). The ten `setTile`s reach `FrameOps.draws` on
        // iteration 18 inside the handle pass — after `.WrapCopyToScreen` and the potion's twinkle (earlier in the
        // list), from the overlay's Handle (layer 0xb), before `.WrapEraseSprites` — as `.ChangedTile @ 10012a50`
        // redraws each cell at once.
        let session = try FerazelSession(resources: try FerazelData.open(try FerazelData.dataDirectory()),
                                          prefs: FerazelPrefs(), level: 1)
        _ = session.world.active.remove(id: session.playerID)
        XCTAssertNotNil(Player.spawn(world: session.world, x: 3806, y: 1083))
        var frames: [FrameOps] = []
        for _ in 1...18 { frames.append(session.step(keys: KeyState())) }
        XCTAssertEqual(frames.prefix(17).map { $0.draws.filter { if case .setTile = $0 { true } else { false } }.count },
                       [Int](repeating: 0, count: 17))
        let draws = frames[17].draws
        let tiles = draws.filter { if case .setTile = $0 { true } else { false } }
        XCTAssertEqual(tiles, [
            .setTile(col: 119, row: 36, fg: 0x1305), .setTile(col: 120, row: 36, fg: 0x1308),
            .setTile(col: 119, row: 37, fg: 0x000b), .setTile(col: 120, row: 37, fg: 0x000a),
            .setTile(col: 119, row: 36, fg: 0x0305), .setTile(col: 120, row: 36, fg: 0x1300),
            .setTile(col: 121, row: 36, fg: 0x1308), .setTile(col: 120, row: 37, fg: 0x0004),
            .setTile(col: 121, row: 37, fg: 0x000a), .setTile(col: 120, row: 36, fg: 0x0300)])
        let copy = try XCTUnwrap(draws.firstIndex { if case .copyToScreen = $0 { true } else { false } })
        let twinkle = try XCTUnwrap(draws.firstIndex { if case .changeLightFace = $0 { true } else { false } })
        let first = try XCTUnwrap(draws.firstIndex { if case .setTile = $0 { true } else { false } })
        let erase = try XCTUnwrap(draws.firstIndex { if case .wrapEraseSprites = $0 { true } else { false } })
        XCTAssertEqual([copy + 1, twinkle + 1, first + 10], [twinkle, first, erase])
        XCTAssertEqual(session.world.tiles.fg.cell(col: 120, row: 36), 0x0300)
        // Strength 1 — a fall faster than 0x9c4 while crunch-capable (spinning): `+0xeb` 1 → the overlay is made (423, R(3))
        // and the player bounces off the block (raw `100552c8..100553f4`). Spawned 5 px above at vy 3000: row 23 → 3440;
        // the move's second 0x400 step sinks him to y 1086 (bottom 1171) → (119, 36): vy 3440 > 0x9c4 ∧ cooldown 0 →
        // strength 1; bounce v = (int)(−0.9 · 3440) = −3096; `.RectBounceFake2` against (pos + 16) + (−2, −2, 0x22, 0x22)
        // = (1166, 3822, 1202, 3858), centre (3840, 1184): his centre (3856, 1145) is right of it and above, and
        // 1184 − 1145 = 39 ≥ 3856 − 3840 = 16 → out through the top: y = 1166 − 0x55 = 1081. DOWN held → 427 vol 0xba,
        // spin, vy −3096; cooldown 5, `+0xce` 0. The scan's second call ((120, 36)) then has the cooldown: strength 0,
        // an overlay only. Without DOWN: spin 0, stop 427, vy 0.
        for down in [true, false] {
            let w = SpriteWorld(level: try level1())
            let pid = Player.spawn(world: w, x: 3806, y: 1078)!
            w.active.update(id: pid) { $0.vy = 3000 }
            w.player.spin = true
            Player.handle(world: w, keys: down ? .down : [], solver: TileSolver(world: w))
            let p = w.active.sprite(id: pid)!
            XCTAssertEqual(p.y, 1081, "down \(down)")
            XCTAssertEqual(p.y256, 1081 << 8)
            XCTAssertEqual(p.x256, 3806 << 8)
            XCTAssertEqual(p.vy, down ? -3096 : 0)
            XCTAssertEqual(w.player.spin, down)
            XCTAssertEqual(w.player.crunchCooldown, 5)
            XCTAssertEqual(p.crunches, 0)
            XCTAssertEqual(w.player.cues.filter { $0.snd == 423 }.count, 2)
            XCTAssertTrue(w.player.cues.contains(down ? PlayerCue(call: .reg, snd: 427, priority: 1, volume: 0xba)
                                                      : PlayerCue(call: .stopIfPlaying, snd: 427)))
            XCTAssertEqual(w.active.sprites.filter { $0.type == 0x4ba }.map(\.classWord154), [119, 120])
        }
        // The strength boundary `vy > 0x9c4` (raw `10055290..10055298`): vy 2060 + 440 = 2500 → strength 0 (no bounce: the
        // FG pass lands him, vy 0); 2061 → 2501 → bounce (int)(−0.9 · 2501) = −2250 with DOWN; and the cooldown gate
        // `060c` == 0: cooldown 2 (row 13 → 1) at vy 3440 → strength 0.
        for (vy0, cooldown, bounces) in [(Int32(2060), Int16(0), false), (2061, 0, true), (3000, 2, false)] {
            let w = SpriteWorld(level: try level1())
            let pid = Player.spawn(world: w, x: 3806, y: 1078)!
            w.active.update(id: pid) { $0.vy = vy0 }
            w.player.spin = true
            w.player.crunchCooldown = cooldown
            Player.handle(world: w, keys: .down, solver: TileSolver(world: w))
            let p = w.active.sprite(id: pid)!
            XCTAssertEqual(p.vy, bounces ? -2250 : 0, "vy0 \(vy0) cooldown \(cooldown)")
            XCTAssertEqual(p.y, bounces ? 1081 : 1083)
            XCTAssertEqual(w.player.crunchCooldown, bounces ? 5 : cooldown - (cooldown > 0 ? 1 : 0))
        }
        // The overlay's own collapse (the player gone): `.CrunchTile(pos, 0)` arms it (phase 15); 15 Handles count it to
        // 0 and take hp 2 → 1; the 16th takes hp → 0: killed, slot 0 freed, 424 at its centre `+0xe` (x + 16 + 8,
        // y + 16 + 8), `.DestroyCrunchTile(119, 36, 1, 1, 1, 0)` (the five writes above) and the log (l. 54099–54125).
        do {
            let w = SpriteWorld(level: try level1())
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: TilePos(x: 3808, y: 1152), strength: 0), 1)
            let o = w.player.crunchSprites[0]!
            _ = w.player.drainFrameOutputs()
            for k in 1...15 {
                EffectSprite.handle(world: w, id: o)
                XCTAssertEqual(w.active.sprite(id: o)!.phase, Int16(15 - k))
            }
            XCTAssertEqual(w.active.sprite(id: o)!.hp, 1)
            XCTAssertEqual(w.active.sprite(id: o)!.face, FaceRef(pict: 0x4ba, index: 1, set: .encoded))
            XCTAssertEqual(w.player.drainFrameOutputs().cues, [])
            EffectSprite.handle(world: w, id: o)
            let out = w.player.drainFrameOutputs()
            XCTAssertEqual(out.cues, [PlayerCue(call: .threeD, snd: 424, priority: 1, volume: 0x100,
                                                position: SpriteSlot.Point(x: 3848, y: 1192))])
            XCTAssertEqual(out.tileOps, [.setTile(col: 119, row: 36, fg: 0x1305), .setTile(col: 120, row: 36, fg: 0x1308),
                                         .setTile(col: 119, row: 37, fg: 0x000b), .setTile(col: 120, row: 37, fg: 0x000a),
                                         .setTile(col: 119, row: 36, fg: 0x0305)])
            XCTAssertTrue(w.active.sprite(id: o)!.dead)
            XCTAssertNil(w.active.sprite(id: o)!.face)
            XCTAssertNil(w.player.crunchSprites[0])
            XCTAssertEqual(w.globals.crunchLog, [CrunchLogEntry(level: 1, col: 119, row: 36)])
        }
        // Crunch kinds 0, 1, 2, 4 on a synthetic cell (5, 5) = direction 1, kind k, no tile (raw `10044988..10044b68`).
        func crunchWorld(_ cells: [(Int, Int, UInt16)]) throws -> SpriteWorld {
            let w = try world([], floor: false)
            var fg = [UInt16](repeating: 0, count: 16 * 16)
            for (c, r, v) in cells { fg[r * 16 + c] = v }
            w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: w.tiles.bg, fgKinds: w.tiles.fgKinds,
                               bgKinds: w.tiles.bgKinds)
            return w
        }
        let at = TilePos(x: 160, y: 160)
        let p423 = SpriteSlot.Point(x: 160, y: 160)
        // Kind 0: strength 0 returns the kind byte 0 and does nothing; strength 1 breaks it at once (424, no overlay).
        do {
            let w = try crunchWorld([(5, 5, 0x1000)])
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 0), 0)
            XCTAssertEqual(w.player.cues, [])
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 1), 1)
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 424, priority: 1, volume: 0x100, position: p423)])
            XCTAssertEqual(w.tiles.fg.cell(col: 5, row: 5), 0x0000)
            XCTAssertEqual(w.active.sprites.count, 0)
        }
        // Kinds 2 / 4: below strength 2 / 4 only `if (!playing(423)) 423` (onlyIfIdle), no overlay, return 1; at strength
        // 2 both break (`p == 2 ∧ kind < 4` / kind 2 ∧ p 2), kind 4 at 4. Strength 0 returns the kind byte.
        for (kind, strong) in [(UInt16(2), UInt8(2)), (4, 4)] {
            let w = try crunchWorld([(5, 5, 0x1000 | kind << 8)])
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 0), UInt8(kind))
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 1), 1)
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 423, priority: 1, volume: 0x100, position: p423,
                                                     onlyIfIdle: true)])
            XCTAssertEqual(w.active.sprites.count, 0)
            w.player.cues = []
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: strong), 1)
            XCTAssertEqual(w.player.cues.map(\.snd), [424], "kind \(kind)")
            XCTAssertEqual(w.tiles.fg.cell(col: 5, row: 5) >> 12, 0)
        }
        // Kind 1 at strength 1: an overlay, not armed (`+0x16c` 0) — its Handle counts the phase but takes no hp;
        // each player hit at phase 0 takes 1 hp and re-arms the delay with 423 + R(3) + 1; at hp 0 it breaks.
        do {
            let w = try crunchWorld([(5, 5, 0x1100), (5, 6, 0x1100)])
            var rng = w.rng
            let r1 = rng.next(3)
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 1), 1)
            let o = w.player.crunchSprites[0]!
            XCTAssertEqual(w.active.sprite(id: o)!.classWord16c, 0)
            XCTAssertEqual(w.active.sprite(id: o)!.phase, r1 + 1)
            XCTAssertEqual(w.active.sprite(id: o)!.hp, 2)
            XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 423, priority: 1, volume: 0x100, position: p423)])
            for _ in 0..<5 { EffectSprite.handle(world: w, id: o) }
            XCTAssertEqual(w.active.sprite(id: o)!.phase, 0)
            XCTAssertEqual(w.active.sprite(id: o)!.hp, 2)                // unarmed: the Handle takes no hp
            let r2 = rng.next(3)
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 1), 1)
            XCTAssertEqual(w.active.sprite(id: o)!.hp, 1)
            XCTAssertEqual(w.active.sprite(id: o)!.phase, r2 + 1)
            XCTAssertEqual(w.rng.seed, rng.seed)
            w.active.update(id: o) { $0.phase = 0 }
            w.player.cues = []
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: at, strength: 1), 1)
            XCTAssertTrue(w.active.sprite(id: o)!.dead)
            XCTAssertEqual(w.player.cues.map(\.snd), [424])
            // `.FindCrunchSprite` matches x and y: the cell below gets its own overlay.
            XCTAssertEqual(CrunchTiles.crunchTile(w, pos: TilePos(x: 160, y: 192), strength: 1), 1)
            XCTAssertEqual(w.active.sprites.filter { $0.type == 0x4ba }.map(\.classWord158), [5, 6])
        }
        // The 40-slot table full: the 41st overlay kills slot 0's and takes slot 0 (`+0x150` 0; l. 39160–39178).
        do {
            let w = try crunchWorld([])
            let ids = (0..<40).map { CrunchTiles.makeCrunchSprite(w, col: $0 % 16, row: $0 / 16, hp: 2)! }
            XCTAssertEqual(w.player.crunchSprites, ids.map { Optional($0) })
            let extra = CrunchTiles.makeCrunchSprite(w, col: 0, row: 10, hp: 2)!
            XCTAssertTrue(w.active.sprite(id: ids[0])!.dead)
            XCTAssertEqual(w.player.crunchSprites[0], extra)
            XCTAssertEqual(w.active.sprite(id: extra)!.classWord150, 0)
            XCTAssertEqual(w.active.sprite(id: ids[39])!.classWord150, 39)
        }
        // `.ReshapeCrunchedTile`, every arm (expected outputs read from the disasm's branch tree, raw `10043f14..100444c4`;
        // arm addresses per row): (position, k, new tile or nil = untouched, cascade anchor or nil). Block anchor (5, 5):
        // position 5 = (5, 5), 7 = (6, 5), 6 = (5, 6), 8 = (6, 6). The cell holds tile k (FG kind = tile; k ≥ 0x50 is the
        // tile itself). A cascade is `.DestroyCrunchTile` of the neighbouring block, seen as its direction nibble cleared.
        let arms: [(Int, Int, Int?, (Int, Int)?)] = [
            (5, 2, 6, nil),            // 100440b4
            (5, 3, 4, nil),            // 1004401c
            (5, 7, -1, nil),           // 100440a0
            (5, 8, 1, nil),            // 100440c8
            (5, 9, 6, (4, 5)),         // 10044030: + Destroy(tx − 1, ty)
            (5, 0xa, 0, nil),          // 10044064
            (5, 0x18, 0x14, nil),      // 10044078
            (5, 0x1c, 0x10, nil),      // 100440dc
            (5, 0x1e, 0x12, nil),      // 1004400c → 100440f0
            (5, 0x2a, 0x12, nil),      // 10043fe4 → 100440f0
            (5, 0x5f, 0xb, nil),       // 1004408c
            (5, 0, nil, nil), (5, 1, nil, nil), (5, 4, nil, nil), (5, 0xb, nil, nil), (5, 0x1d, nil, nil),
            (5, 0x1f, nil, nil),
            (7, 0, 5, nil),            // 1004420c
            (7, 3, 7, nil),            // 10044160
            (7, 4, -1, nil),           // 100441f8
            (7, 9, 2, nil),            // 10044174
            (7, 0xa, 5, (6, 5)),       // 10044188: + Destroy(tx + 1, ty)
            (7, 0xb, 1, nil),          // 100441bc
            (7, 0x1f, 0x13, nil),      // 100441e4
            (7, 0x5f, 8, nil),         // 100441d0
            (7, 1, nil, nil), (7, 2, nil, nil), (7, 5, nil, nil), (7, 0xc, nil, nil),
            (6, 1, 5, nil),            // 100442a4
            (6, 2, 7, nil),            // 100442b8
            (6, 6, -1, nil),           // 100442cc
            (6, 8, 5, (5, 6)),         // 100442e0: + Destroy(tx, ty + 1)
            (6, 9, 3, nil),            // 10044314
            (6, 0xb, 0, nil),          // 10044328
            (6, 0x1b, 0x17, nil),      // 10044284 → 10044350
            (6, 0x2e, 0x17, nil),      // 1004426c → 10044350
            (6, 0x1d, 0x11, nil),      // 1004433c
            (6, 0x5f, 0xa, nil),       // 10044364
            (6, 0, nil, nil), (6, 3, nil, nil), (6, 7, nil, nil), (6, 0xa, nil, nil), (6, 0x1c, nil, nil),
            (8, 0, 4, nil),            // 100443f8
            (8, 1, 6, nil),            // 100443e4
            (8, 5, -1, nil),           // 1004440c
            (8, 8, 2, nil),            // 10044420
            (8, 0xa, 3, nil),          // 10044434
            (8, 0xb, 4, (6, 5)),       // 10044448: + Destroy(tx + 1, ty)
            (8, 0x1a, 0x16, nil),      // 1004447c
            (8, 0x1c, 0x10, nil),      // 10044490
            (8, 0x5f, 9, nil),         // 100444a4
            (8, 2, nil, nil), (8, 6, nil, nil), (8, 0x1b, nil, nil),
        ]
        let cellOf = [5: (5, 5), 7: (6, 5), 6: (5, 6), 8: (6, 6)]
        let anchors = [(4, 5), (6, 5), (5, 6)]
        for (position, k, out, cascade) in arms {
            let (c, r) = cellOf[position]!
            // Each candidate neighbour anchor carries direction 1 (and keeps whatever tile the case puts there).
            var cells = anchors.map { ($0.0, $0.1, UInt16(0x1000)) }
            if let i = cells.firstIndex(where: { $0.0 == c && $0.1 == r }) { cells.remove(at: i) }
            let dir: UInt16 = anchors.contains { $0 == (c, r) } ? 0x1000 : 0
            cells.append((c, r, dir | UInt16(k + 1)))
            let w = try crunchWorld(cells)
            CrunchTiles.reshape(w, col: c, row: r, block: (5, 5), position: position, dir: 1, explode: false,
                                clearDir: true)
            let tile = Int(w.tiles.fg.cell(col: c, row: r) & 0xff) - 1
            XCTAssertEqual(tile, out ?? k, "position \(position) k \(k)")
            for a in anchors {
                let cleared = w.tiles.fg.cell(col: a.0, row: a.1) >> 12 == 0
                XCTAssertEqual(cleared, cascade.map { $0 == a } ?? false, "position \(position) k \(k) anchor \(a)")
            }
        }
        // Hundreds stripped while > 100 (raw `10043f5c..10043f68`): kind 103 at position 5 acts as 3 → tile 4; kind 100 is
        // not > 100 and has no arm.
        for (kind, out) in [(103, 4), (100, 9)] {
            let w = try crunchWorld([(5, 5, UInt16(9 + 1))])
            var kinds = Array(0..<0x60)
            kinds[9] = kind
            w.tiles = TileGrid(fg: w.tiles.fg, bg: w.tiles.bg, fgKinds: kinds, bgKinds: w.tiles.bgKinds)
            CrunchTiles.reshape(w, col: 5, row: 5, block: (5, 5), position: 5, dir: 1, explode: false, clearDir: true)
            XCTAssertEqual(Int(w.tiles.fg.cell(col: 5, row: 5) & 0xff) - 1, out, "kind \(kind)")
        }
        // `.RectBounceFake2` axis rule (raw `1003edd8..1003edec` and its mirror): the push is horizontal only when the
        // vertical distance is strictly the smaller; a tie goes vertical. Solid at pos (0, 0) + (−2, −2, 0x22, 0x22),
        // centre (16, 16); the player's centre = (x + 50, y + 59). x −24, y −53: |dy| 10 = |dx| 10 → y = −2 − 0x55;
        // y −52: 9 < 10 → x = 0x22 − 0x26.
        for (y, ex, ey) in [(-53, -24, -2 - 0x55), (-52, 0x22 - 0x26, -52)] {
            let w = try world([], floor: false)
            let pid = Player.spawn(world: w, x: -24, y: y)!
            w.active.update(id: pid) { s in
                s.x = -24
                s.y = y
            }
            PlayerTiles.rectBounceFake2(w, id: pid, pos: TilePos(x: 0, y: 0), rect: PlayerTiles.crunchRect, cx: 50,
                                        cy: 59, hotRect: HandleKeys.standardHotRect)
            XCTAssertEqual(w.active.sprite(id: pid)!.x, ex, "y \(y)")
            XCTAssertEqual(w.active.sprite(id: pid)!.y, ey, "y \(y)")
        }
        // Deterministic: a second run gives the same log and map.
        let again = try run()
        XCTAssertEqual(again.log, log)
        XCTAssertEqual(again.world.tiles, w.tiles)
        XCTAssertEqual(again.world.rng.seed, w.rng.seed)
    }
}

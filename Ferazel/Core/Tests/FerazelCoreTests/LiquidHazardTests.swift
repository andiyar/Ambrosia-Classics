import XCTest
import HectorResources
@testable import FerazelCore

/// P4 (docs/plans/2026-10-10-ferazel-phase2.md): liquids, hazards, breath, death — `.HandleUnderWater @ 10042e30`,
/// `.HandleFlotation @ 10042d04`, `.HandlePlayerSprite @ 1004d5fc` rows 17 (liquid damage / heal), 28 (the damaging
/// surface), 35 (oxygen, drowning, bubbles), 41 (the death trigger, the breath refill), 42 (below the map) and
/// `.EmitBubble @ 1004ba74`.
///
/// Fixtures: the census, the surface walk and the FG-203 floor read the shipped levels; the others a synthetic 16×16
/// grid (cells outside clamp, `.ConstrainXY`) on a level's header: an FG kind-3 floor on row 12 (surface Y + 16 = 400,
/// the player stands at y 400 − 0x55 = 315) and BG liquid (tile 1, kind 200 + k) on the named rows. Level 2's header
/// has no water current (hdr 0x2714 = 0) and no side push. "Frame 0" is the entry frame: its row 17 sees no liquid
/// yet (`+0x120` = `+0x11c` = 0 — the end pass of that frame is the first `.HandleUnderWater`); frames 1, 2, … follow.
final class LiquidHazardTests: XCTestCase {

    // MARK: - fixtures

    private let standY = 400 - 0x55

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// `Mlvl n` with header bytes patched (offset → big-endian bytes).
    private func level(_ n: Int16, patch: [Int: [UInt8]] = [:]) throws -> LevelFile {
        let r = try resources()
        let res = try XCTUnwrap(r.world.resource(type: "Mlvl", id: n))
        var d = res.data
        for (o, bytes) in patch {
            for (i, b) in bytes.enumerated() { d[d.startIndex + o + i] = b }
        }
        return try LevelFile(id: n, data: d)
    }

    /// The synthetic grid: floor on row 12 (FG tile 3, kind `floorKind`), BG tile 1 (kind 200 + `liquid`) on `rows`.
    private func pool(_ L: LevelFile, liquid: Int = 0, rows: ClosedRange<Int>? = 6...11, floorKind: Int = 3,
                      floor: Bool = true) -> SpriteWorld {
        let w = SpriteWorld(level: L)
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if floor { for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 } }
        var bg = [UInt16](repeating: 0, count: 16 * 16)
        if let rows { for r in rows { for c in 0..<16 { bg[r * 16 + c] = 1 + 1 } } }
        var fgKinds = Array(0..<0x60)
        fgKinds[3] = floorKind
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[1] = 200 + liquid
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: TileMap(width: 16, height: 16, cells: bg),
                           fgKinds: fgKinds, bgKinds: bgKinds)
        return w
    }

    /// One frame of the player: the previous frame's outputs drained first (the frame driver's
    /// `drainFrameOutputs()`), so `w.player.cues` reads this frame's.
    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        _ = w.player.drainFrameOutputs()
        Player.handle(world: w, keys: keys, solver: solver)
    }

    /// One frame of the whole handle pass (the player and the Effect Handles, list order), as the session runs it.
    private func frameAll(_ w: SpriteWorld, _ solver: TileSolver) {
        _ = w.player.drainFrameOutputs()
        w.handleSprites { w, id in
            switch w.active.record(id: id)!.handler {
            case .player: Player.handle(world: w, keys: [], solver: solver)
            case .effect: EffectSprite.handle(world: w, id: id)
            default: break
            }
        }
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// Spawn at (100, y) and run the entry frame (frame 0).
    private func enter(_ w: SpriteWorld, y: Int? = nil) -> TileSolver {
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: y ?? standY))
        let solver = TileSolver(world: w)
        frame(w, solver)
        return solver
    }

    // MARK: - tests

    func testLiquidCensusLevels1And2() throws {
        // Every BG cell whose kind passes `.IsWaterTile` (199 < kind < 0xd2, i16), by `.GetWaterTileKind` (kind − 200).
        let r = try resources()
        var census: [Int16: [Int16: Int]] = [:]
        for n: Int16 in [1, 2] {
            let g = TileGrid(level: try LevelFile.load(from: r, level: n))
            for row in 0..<Int(g.bg.height) {
                for col in 0..<Int(g.bg.width) {
                    let k = g.bgKind(tile: g.bgTile(col: col, row: row))
                    if UnderWater.isWaterTile(k) { census[n, default: [:]][UnderWater.waterKind(k), default: 0] += 1 }
                }
            }
        }
        XCTAssertEqual(census[1], [0: 268, 1: 24])
        XCTAssertEqual(census[2], [0: 433, 1: 114, 3: 12])
        // The bounds of `.IsWaterTile`.
        XCTAssertEqual([199, 200, 209, 210, -1, 0x100c8].map(UnderWater.isWaterTile), [false, true, true, false, false, true])
    }

    func testSurfaceRowWalk() throws {
        // Level 2's raft pool (cols 45…61, water from row 17; the rafts 0x580 float at y 532/533): a hit on row 18 walks
        // up while the BG cell above is water → row 17, surfaceY = 17·32 = 544.
        let w = SpriteWorld(level: try level(2))
        XCTAssertEqual(UnderWater.surfaceY(w.tiles, col: 50, row: 18), 544)
        XCTAssertEqual(UnderWater.surfaceY(w.tiles, col: 50, row: 17), 544)
        // `.HandleUnderWater` on a sprite whose face top is at y 520 (24.8 at 520.5): `+0x11c` = 544 − 520 − 0 (the
        // face's first i16 is its frame rect's top, 0) = 24; `+0x128` 0; entering (`+0x120` 0) → `+0x148` = 544;
        // `+0x140` 1; the pixel copies refreshed from 24.8.
        let id = try XCTUnwrap(w.newSprite(type: 1, x: 1600, y: 520, layer: 5, handler: .inert))
        w.active.update(id: id) { $0.y256 = 520 << 8 | 0x80 }
        UnderWater.handle(world: w, id: id, pos: TilePos(x: 50 * 32, y: 18 * 32))
        var s = w.active.sprite(id: id)!
        XCTAssertEqual(s.waterRow, 24)
        XCTAssertEqual(s.waterKind, 0)
        XCTAssertEqual(s.quicksandSurface, 544)
        XCTAssertTrue(s.underwaterDone)
        XCTAssertEqual(s.y, 520)
        XCTAssertEqual(s.x, 1600)
        // Below the surface: clamped to 1. Already in the water (`+0x120` ≠ 0): `+0x148` is not rewritten.
        w.active.update(id: id) { p in
            p.y256 = 600 << 8
            p.lastWater = 7
            p.quicksandSurface = 99
            p.underwaterDone = false
        }
        UnderWater.handle(world: w, id: id, pos: TilePos(x: 50 * 32, y: 18 * 32))
        s = w.active.sprite(id: id)!
        XCTAssertEqual(s.waterRow, 1)
        XCTAssertEqual(s.quicksandSurface, 99)
        XCTAssertEqual(s.y, 600)
        // The clamp's boundary: S − y − inset = 544 − 544 − 0 = 0 → 1 (`+0x11c < 1`, l. 38181).
        w.active.update(id: id) { p in p.y256 = 544 << 8; p.underwaterDone = false }
        UnderWater.handle(world: w, id: id, pos: TilePos(x: 50 * 32, y: 18 * 32))
        XCTAssertEqual(w.active.sprite(id: id)!.waterRow, 1)
        w.active.update(id: id) { p in p.y256 = 543 << 8 }
        UnderWater.handle(world: w, id: id, pos: TilePos(x: 50 * 32, y: 18 * 32))
        XCTAssertEqual(w.active.sprite(id: id)!.waterRow, 1)
        // `.HandleFlotation(s, 544)` when `+0x19e` > 0: hot rect (top 6, bottom 0x1e) → mid 6 + 12 = 18; target T =
        // `+0x1a0` 10 + 544 − 18 = 536. y 600 > T → b = −0x50: vy 0 → −80 → (int)(−80 · 0.93) = −74. Then y 536,
        // vy 60 (< 0x46): b = +0x50 (T − y = 0 is not < 0) → 140 → (int)(140 · 0.86) = 120; T == y but |120| ≥ 0x46 → no
        // snap. vy −100: −20 → (int)(−17.2) = −17 → |−17| < 0x46 → vy 0, y256 = 536·256. b capped at 0x15e.
        func float(y: Int32, vy: Int32, buoyancy: Int16 = 0x50) -> SpriteSlot {
            w.active.update(id: id) { p in
                p.y256 = y << 8 | 0x40
                p.vy = vy
                p.buoyancy = buoyancy
                p.floatOffset = 10
                p.hotRect = IdleSprites.Rect(top: 6, left: 0x10, bottom: 0x1e, right: 0x3d)
                p.underwaterDone = false
            }
            UnderWater.handle(world: w, id: id, pos: TilePos(x: 50 * 32, y: 18 * 32))
            return w.active.sprite(id: id)!
        }
        XCTAssertEqual(float(y: 600, vy: 0).vy, -74)
        XCTAssertEqual(float(y: 536, vy: 60).vy, 120)
        XCTAssertEqual(float(y: 536, vy: 60).y256, 536 << 8 | 0x40)
        s = float(y: 536, vy: -100)
        XCTAssertEqual(s.vy, 0)
        XCTAssertEqual(s.y256, 536 << 8)
        // The settle bound: (2 + 80) · 0.86 = 70.52 → 70 = 0x46 is kept; (1 + 80) · 0.86 → 69 snaps.
        XCTAssertEqual(float(y: 536, vy: 2).vy, 0x46)
        XCTAssertEqual(float(y: 536, vy: 2).y256, 536 << 8 | 0x40)
        XCTAssertEqual(float(y: 536, vy: 1).vy, 0)
        XCTAssertEqual(float(y: 536, vy: 1).y256, 536 << 8)
        XCTAssertEqual(float(y: 500, vy: 0, buoyancy: 0x200).vy, 301)      // b 0x15e = 350 → (int)(350 · 0.86) = 301
        XCTAssertEqual(float(y: 600, vy: 0, buoyancy: 0).vy, 0)            // no flotation without buoyancy
        // The cap pinned where a one-off cap would truncate apart: (1 + 350) · 0.86 = 301.86 → 301 (0x15f: 302.72 → 302);
        // sinking side −350 · 0.93 = −325.5 → −325 (0x15f: −326.43 → −326); b = 0x15e itself passes uncapped.
        XCTAssertEqual(float(y: 500, vy: 1, buoyancy: 0x200).vy, 301)
        XCTAssertEqual(float(y: 600, vy: 0, buoyancy: 0x200).vy, -325)
        XCTAssertEqual(float(y: 500, vy: 1, buoyancy: 0x15e).vy, 301)
        XCTAssertEqual(float(y: 500, vy: 1, buoyancy: 0x15d).vy, 301)      // 350 · 0.86 = 301.0
        XCTAssertEqual(float(y: 500, vy: 0, buoyancy: 0x15d).vy, 300)      // 349 · 0.86 = 300.14

        // Kind 5 (quicksand; synthetic — no level 1/2 cell): BG kind 205 on rows 6…11 → surface 192; hot rect bottom
        // b = 0x1e. Entering at y 250 (vy 100, depth `+0x144` 0x1000): `+0x148` = 192; depth += 0xc0 → 0x10c0; y 251;
        // F = 192 + (0x10c0 >> 8) = 208; y256 += 0x100; y + b = 281 ≥ F and vy ≥ 1 → y = 208 − 30 = 178, vy 0, ground
        // kind `+0xce` 3, y256 = 178·256; `+0x11c` = 192 − 178 = 14.
        let q = pool(try level(2), liquid: 5)
        let qid = try XCTUnwrap(q.newSprite(type: 1, x: 100, y: 250, layer: 5, handler: .inert))
        func sink(y256: Int32, vy: Int32, depth: Int32, entering: Bool = false) -> SpriteSlot {
            q.active.update(id: qid) { p in
                p.y256 = y256
                p.vy = vy
                p.quicksandDepth = depth
                p.lastWater = entering ? 0 : 3
                p.hotRect = IdleSprites.Rect(top: 6, left: 0x10, bottom: 0x1e, right: 0x3d)
                p.groundKind = 0
                p.underwaterDone = false
            }
            UnderWater.handle(world: q, id: qid, pos: TilePos(x: 100, y: 8 * 32))
            return q.active.sprite(id: qid)!
        }
        s = sink(y256: 250 << 8, vy: 100, depth: 0x1000, entering: true)
        XCTAssertEqual(s.waterKind, 5)
        XCTAssertEqual(s.quicksandSurface, 192)
        XCTAssertEqual(s.quicksandDepth, 0x10c0)
        XCTAssertEqual(s.y, 178)
        XCTAssertEqual(s.vy, 0)
        XCTAssertEqual(s.groundKind, 3)
        XCTAssertEqual(s.y256, 178 << 8)
        XCTAssertEqual(s.waterRow, 14)
        // Rising (vy −50) at y 170 → 171, depth 0x1000 → 0x10c0, F 208: y + b = 201 < F → the pull: min(0x10c0,
        // 171 + 30 + 8 − 192 = 17) = 17 → << 8 = 0x1100; y256 + 0x100; vy kept; `+0x11c` = 192 − 171 = 21.
        s = sink(y256: 170 << 8, vy: -50, depth: 0x1000)
        XCTAssertEqual(s.quicksandDepth, 17 << 8)
        XCTAssertEqual(s.y, 171)
        XCTAssertEqual(s.y256, 171 << 8)
        XCTAssertEqual(s.vy, -50)
        XCTAssertEqual(s.groundKind, 0)
        XCTAssertEqual(s.waterRow, 21)
        // The pull below 0 → 0 (y 150 → 151: 151 + 38 − 192 = −3); vy 0 below the floor: depth only += 0xc0.
        XCTAssertEqual(sink(y256: 150 << 8, vy: -50, depth: 0x1000).quicksandDepth, 0)
        XCTAssertEqual(sink(y256: 150 << 8, vy: 0, depth: 0x1000).quicksandDepth, 0x10c0)
        // Sunk past the surface: `+0x11c` from `+0x148` clamps to 1 (y 200 → 201, vy 0, F 208: 192 − 201 < 1).
        XCTAssertEqual(sink(y256: 200 << 8, vy: 0, depth: 0x1000).waterRow, 1)
        XCTAssertEqual(sink(y256: 191 << 8, vy: 0, depth: 0x1000).waterRow, 1)        // 192 − 192 = 0 → 1
    }

    func testDrownFromFullBreath() throws {
        // Kind 0 (no acid), fully submerged (surface 192, y 315 → `+0x11c` 1). Oxygen G+6 = 560 − 1 per frame from
        // frame 1; at 0 the suffocation countdown G+8 (30, set by the refill on frame 0) runs 30 frames, then 443 (prio 1,
        // vol 0x100), HP −0x70, invulnerable 0x28, G+8 = 30 again — every 40 + 30 = 70 frames. HP 560 → 0 on the fifth
        // hit, and with no stun the trigger fires the same frame (row 41).
        // The bubbles ride along (the Effect Handles run in the same pass; neither they nor `.EmitBubble` draw
        // `FastRand`).
        let w = pool(try level(2))
        let solver = enter(w)
        XCTAssertEqual(w.globals.suffocation, 0x1e)
        var hits: [Int] = [], trigger: Int?
        var bubble: Int?
        for f in 1...880 {
            let hp = player(w).hp
            frameAll(w, solver)
            bubbles(f)
            let c = w.player.cues
            if player(w).hp != hp {
                hits.append(f)
                XCTAssertEqual(hp - player(w).hp, 0x70, "frame \(f)")
                XCTAssertEqual(player(w).invulnerable, 0x28)
                XCTAssertEqual(w.globals.breath, 0)
                XCTAssertEqual(w.globals.suffocation, 0x1e)
                XCTAssertTrue(c.contains(PlayerCue(call: .reg, snd: 443, priority: 1, volume: 0x100)))
            }
            if trigger == nil && w.player.dying != 0 {
                trigger = f
                XCTAssertTrue(c.contains(PlayerCue(call: .reg, snd: 417, priority: 1, volume: 0x100)))
                XCTAssertTrue(w.player.diedInLiquid)
                XCTAssertEqual(player(w).windScale, 0)
            }
            if f == 559 { XCTAssertEqual(w.globals.breath, 1) }
            if f == 560 { XCTAssertEqual(w.globals.suffocation, 29) }
            if f == 589 { XCTAssertEqual(w.globals.suffocation, 0) }
        }
        XCTAssertEqual(hits, [590, 660, 730, 800, 870])
        XCTAssertEqual(trigger, 870)
        XCTAssertEqual(w.player.dying, 1 + 10)                              // 10 frames of the dying arm after 870

        /// The first bubbles. Frame 20 (measured: `.HandleBreathing` reaches phase 2 under P3's exertion wrap):
        /// `.EmitBubble` → 0x410 at (`+0x10` + 16, `+0xe` − 16) = (166, 358), layer 0xb, the 0x410 hot rect, 415 (prio 1,
        /// vol 0xab), cooldown 2 — inserted after the player, so first handled on frame 21: `+0x46` 1, face 1040[0],
        /// vy −500, y256 358·256 − 500, in the liquid (`+0x11c` 1). Row 35's timer (0x28 at `.ClearPlayerVars`, −1 from
        /// frame 1) is 0 after frame 40; frame 41 → `.EmitBubble` only counts the cooldown down (2 → 1); timer = R(0x96) + 200 =
        /// 38 + 200 (seed 1's first draw). Frame 105: its hot rect (y − 10 … y − 2 at y 193) no longer meets row 6 →
        /// `+0x11c` 0 → face 0, killed; the tail still moves it to y 191.
        func bubbles(_ f: Int) {
            switch f {
            case 20:
                XCTAssertEqual(w.player.cues.filter { $0.snd == 415 }, [PlayerCue(call: .reg, snd: 415, priority: 1, volume: 0xab)])
                XCTAssertEqual(w.player.bubbleCooldown, 2)
                let b = w.active.sprites.filter { $0.type == PlayerLiquids.bubble }
                XCTAssertEqual(b.count, 1)
                bubble = b.first?.id
                XCTAssertEqual(b.first?.layer, 0xb)
                XCTAssertEqual(b.first.map { [$0.x256, $0.y256] }, [166 << 8, 358 << 8])
                XCTAssertEqual(b.first.map { [$0.x, $0.y] }, [166, 358])
                XCTAssertEqual(b.first?.hotRect, IdleSprites.Rect(top: -10, left: 0, bottom: -2, right: 8))
                XCTAssertEqual(b.first?.handler, .effect)
                XCTAssertNil(b.first?.face)
            case 21:
                let b = w.active.sprite(id: bubble!)!
                XCTAssertEqual(b.phase, 1)
                XCTAssertEqual(b.face, FaceRef(pict: 0x410, index: 0, set: .encoded))
                XCTAssertEqual(b.vy, -500)
                XCTAssertEqual(b.y256, 358 << 8 - 500)
                XCTAssertEqual(b.waterRow, 1)
            case 26:
                XCTAssertEqual(w.active.sprite(id: bubble!)!.face, FaceRef(pict: 0x410, index: 3, set: .encoded))
            case 28:
                XCTAssertEqual(w.active.sprite(id: bubble!)!.phase, 0)          // 7 → 8 → 0
            case 39:
                XCTAssertEqual(w.player.bubbleTimer, 1)
            case 40:
                XCTAssertEqual(w.player.bubbleTimer, 0)
                XCTAssertEqual(w.player.bubbleCooldown, 2)
            case 41:
                XCTAssertEqual(w.player.bubbleCooldown, 1)
                // ⚑ E1a (Invariant-10, revert-verified): was 238 — the entry `.Splash(s, 3)` now draws its 32 × 3.
                XCTAssertEqual(w.player.bubbleTimer, 209)
                XCTAssertEqual(w.player.cues.filter { $0.snd == 415 }, [])
            case 104:
                XCTAssertFalse(w.active.sprite(id: bubble!)!.dead)
            case 105:
                let b = w.active.sprite(id: bubble!)!
                XCTAssertTrue(b.dead)
                XCTAssertNil(b.face)
                XCTAssertEqual(b.waterRow, 0)
                XCTAssertEqual(b.y, 191)
            default:
                break
            }
        }
        // Mirrored (`+0x17e` set): 16 px to the left; kind 5: nothing at all (not even the cooldown).
        let v = pool(try level(2))
        XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
        v.active.update(id: v.playerID!) { p in
            p.mirrored = true
            p.centre = SpriteSlot.Point(x: 150, y: 374)
        }
        PlayerLiquids.emitBubble(v, id: v.playerID!)
        XCTAssertEqual(v.active.sprites.filter { $0.type == 0x410 }.map { [$0.x256 >> 8, $0.y256 >> 8] }, [[134, 358]])
        v.active.update(id: v.playerID!) { $0.waterKind = 5 }
        PlayerLiquids.emitBubble(v, id: v.playerID!)
        XCTAssertEqual(v.player.bubbleCooldown, 2)
        // Row 35 in kind 5 (quicksand; synthetic — `0 < +0x120 < 0xf`): oxygen −8 per tick (16 → 8 → 0), and at < 1
        // with the countdown 0: 443, HP −0x70, invulnerable 0x28, G+8 = 0xf (not 0x1e); no bubble.
        v.active.update(id: v.playerID!) { p in
            p.lastWater = 5
            p.invulnerable = 0
        }
        v.globals.breath = 16
        v.globals.suffocation = 0
        let hp = player(v).hp
        PlayerLiquids.bubbles(v, id: v.playerID!)
        XCTAssertEqual(v.globals.breath, 8)
        XCTAssertEqual(player(v).hp, hp)
        PlayerLiquids.bubbles(v, id: v.playerID!)
        XCTAssertEqual(v.globals.breath, 0)
        XCTAssertEqual(player(v).hp, hp - 0x70)
        XCTAssertEqual(player(v).invulnerable, 0x28)
        XCTAssertEqual(v.globals.suffocation, 0xf)
        XCTAssertEqual(v.active.sprites.filter { $0.type == 0x410 }.count, 1)    // the mirrored one above only
        // Not invulnerable again, countdown 0xf → −1 per tick; kind 0 at the countdown 0 → 0x1e.
        v.active.update(id: v.playerID!) { $0.invulnerable = 0 }
        PlayerLiquids.bubbles(v, id: v.playerID!)
        XCTAssertEqual(v.globals.breath, -8)
        XCTAssertEqual(v.globals.suffocation, 0xe)
        v.active.update(id: v.playerID!) { $0.waterKind = 0 }
        v.globals.suffocation = 0
        PlayerLiquids.bubbles(v, id: v.playerID!)
        XCTAssertEqual(v.globals.suffocation, 0x1e)
    }

    func testBreathRefill() throws {
        // Row 41, not bubbling (dry): oxygen < `+0xa4` → +8; < 0 → 1; > `+0xa4` → `+0xa4`; G+8 = 0x1e every frame.
        let w = pool(try level(2), rows: nil)
        let solver = enter(w)
        w.globals.breath = 100
        w.globals.suffocation = 3
        var seen: [Int16] = []
        for _ in 1...3 {
            frame(w, solver)
            seen.append(w.globals.breath)
            XCTAssertEqual(w.globals.suffocation, 0x1e)
        }
        XCTAssertEqual(seen, [108, 116, 124])
        w.globals.breath = 556                                              // 564 → capped at HP 560
        frame(w, solver)
        XCTAssertEqual(w.globals.breath, 560)
        w.globals.breath = 600                                              // above HP: down to it
        frame(w, solver)
        XCTAssertEqual(w.globals.breath, 560)
        w.globals.breath = -20                                              // −12, still < 0 → 1
        frame(w, solver)
        XCTAssertEqual(w.globals.breath, 1)
        w.globals.breath = -8                                               // 0 is not < 0
        frame(w, solver)
        XCTAssertEqual(w.globals.breath, 0)
        // Bubbling (in the water, `0 < +0x120 < 0xf`): no refill — oxygen −1, and G+8 is left alone.
        let wet = pool(try level(2))
        let s2 = enter(wet)
        wet.globals.breath = 100
        frame(wet, s2)
        XCTAssertEqual(wet.globals.breath, 99)
        XCTAssertEqual(wet.globals.suffocation, 0x1e)
    }

    func testDamagingFloorFG203() throws {
        // Level 1, FG kind 203 (material 2) on row 37, cols 59…64 (surface 37·32 + 16 = 1200): the player stands on it
        // (x 1886, y 1200 − 0x55 = 1115). Row 28: not invulnerable, not dying → damage hdr 0x270e (112), stun 1, spin
        // 0, stop 427 if playing, 450 (prio 1, vol 0x100), invulnerable 60, flash 0x12. Hits every 60 frames; the fifth
        // takes HP to 0 on frame 241, but the stun it set (row 33 counts it 2…10, then 11 → 0 on frame 250) holds the
        // death trigger to frame 250.
        let w = SpriteWorld(level: try level(1))
        XCTAssertNotNil(Player.spawn(world: w, x: 1886, y: 1115))
        let solver = TileSolver(world: w)
        var hits: [Int] = [], trigger: Int?
        for f in 1...260 {
            let hp = player(w).hp
            if f == 61 { w.player.spin = true }
            frame(w, solver)
            if player(w).hp != hp {
                hits.append(f)
                XCTAssertEqual(hp - player(w).hp, 112)
                XCTAssertEqual(player(w).invulnerable, 60)
                XCTAssertEqual(player(w).flash, 0x12)
                XCTAssertEqual(w.player.stun, 2)                            // 1, then row 33's first count
                XCTAssertFalse(w.player.spin)
                // Row 28's stop-if-playing 427 right before its 450 (row 33's hurt-stun arm stops 427 again after).
                let c = w.player.cues
                let i = try XCTUnwrap(c.firstIndex { $0.snd == 450 })
                XCTAssertEqual(Array(c[(i - 1)...(i + 1)]), [PlayerCue(call: .stopIfPlaying, snd: 427),
                                                            PlayerCue(call: .reg, snd: 450, priority: 1, volume: 0x100),
                                                            PlayerCue(call: .stopIfPlaying, snd: 427)])
            }
            if trigger == nil && w.player.dying != 0 { trigger = f }
        }
        XCTAssertEqual(hits, [1, 61, 121, 181, 241])
        XCTAssertEqual(trigger, 250)
        // hdr 0x270e: 0 → 0x70; 50 → 50.
        for (patch, damage) in [([UInt8](arrayLiteral: 0, 0), Int16(0x70)), ([0, 50], 50)] {
            let w2 = SpriteWorld(level: try level(1, patch: [0x270e: patch]))
            XCTAssertNotNil(Player.spawn(world: w2, x: 1886, y: 1115))
            frame(w2, TileSolver(world: w2))
            XCTAssertEqual(player(w2).hp, 560 - damage)
        }
    }

    func testAcidFromThirdFrame() throws {
        // Kind 1 (acid): the counter `PTR_DAT_100a0538` counts frames 1 and 2; frame 3: 407 (prio 1, vol 0x100), HP
        // −112, invulnerable 60, flash 13, cooldown `_DAT_100a06d8` 35 (row 18 counts it to 34 the same frame).
        let w = pool(try level(2), liquid: 1)
        let solver = enter(w)
        XCTAssertEqual(w.player.liquidCounter, 0)
        var hits: [Int] = []
        for f in 1...64 {
            let hp = player(w).hp
            frame(w, solver)
            if f <= 2 { XCTAssertEqual(w.player.liquidCounter, Int16(f)) }
            if player(w).hp != hp {
                hits.append(f)
                XCTAssertEqual(hp - player(w).hp, 112)
                XCTAssertEqual(player(w).invulnerable, 60)
                XCTAssertEqual(player(w).flash, 13)
                XCTAssertEqual(w.player.countdown06d8, 34)
                XCTAssertEqual(w.player.cues.filter { $0.snd == 407 },
                               [PlayerCue(call: .reg, snd: 407, priority: 1, volume: 0x100)])
            }
        }
        XCTAssertEqual(hits, [3, 63])                                       // then every 60 (the invulnerability)
        // Row 17 alone (counter 2, in kind k): the written values, and the gates.
        func row17(kind: Int16, hp: Int16, invul: Int16 = 0, cooldown: Int16 = 0, level L: LevelFile? = nil)
            throws -> (hp: Int16, cues: [PlayerCue], cooldown: Int16) {
            let v = pool(try L ?? level(2))
            XCTAssertNotNil(Player.spawn(world: v, x: 100, y: standY))
            let id = v.playerID!
            v.active.update(id: id) { p in
                p.lastWater = 1
                p.waterKind = kind
                p.hp = hp
                p.invulnerable = invul
            }
            v.player.liquidCounter = 2
            v.player.countdown06d8 = cooldown
            PlayerLiquids.liquidDamage(v, id: id)
            return (v.active.sprite(id: id)!.hp, v.player.cues, v.player.countdown06d8)
        }
        XCTAssertEqual(try row17(kind: 1, hp: 4).hp, 4)                     // HP 4 → none
        XCTAssertEqual(try row17(kind: 1, hp: 4).cues, [])
        XCTAssertEqual(try row17(kind: 1, hp: 5).hp, 5 - 112)
        XCTAssertEqual(try row17(kind: 1, hp: 5).cooldown, 35)
        XCTAssertEqual(try row17(kind: 2, hp: 200).hp, 88)
        XCTAssertEqual(try row17(kind: 1, hp: 200, invul: 1).hp, 200)
        XCTAssertEqual(try row17(kind: 1, hp: 200, cooldown: 1).hp, 200)
        XCTAssertEqual(try row17(kind: 4, hp: 200).hp, 200)                 // kinds ≥ 4: nothing
        XCTAssertEqual(try row17(kind: -1, hp: 200).hp, 200)
        XCTAssertEqual(try row17(kind: 0, hp: 200).hp, 200)                 // kind 0 without hdr 0x26cd: counter 0
        XCTAssertEqual(try row17(kind: 0, hp: 200, level: level(2, patch: [0x26cd: [1]])).hp, 88)
        XCTAssertEqual(try row17(kind: -1, hp: 200, level: level(2, patch: [0x26cd: [1]])).hp, 200)
    }

    func testHealingPool() throws {
        // Kind 3 from the third frame, while `+0xa4` > 0: oxygen +8 (≤ G+0xa); G+4 < G+0xa → `+0xa4` +4 (no cap on
        // `+0xa4`); G+0xe < G+0xc → magic +4; healing → 803 (prio 1, vol 0xab) only if it is not playing, else nothing
        // heals → stop 803. Row 35 then spends 1 oxygen (bubbling).
        let w = pool(try level(2), liquid: 3)
        let solver = enter(w)
        let id = w.playerID!
        w.active.update(id: id) { $0.hp = 552 }
        w.globals.health = 552
        w.globals.magic = 556
        var trace: [String] = []
        for _ in 1...5 {
            frame(w, solver)
            let heal = w.player.cues.filter { $0.snd == 803 }.map { "\($0.call)\($0.onlyIfIdle ? "!" : "")" }
            trace.append("\(player(w).hp) \(w.globals.magic) \(w.globals.breath) \(heal)")
        }
        // Frames 1–2: nothing (oxygen 559, 558); 3: oxygen 566 → 560 → 559, HP 556, magic 560; 4: HP 560 (G+4 556 <
        // 560), magic full; 5: G+4 560, magic full → nothing heals → stop.
        XCTAssertEqual(trace, ["552 556 559 []", "552 556 558 []", "556 560 559 [\"reg!\"]",
                               "560 560 559 [\"reg!\"]", "560 560 559 [\"stop\"]"])
        XCTAssertEqual(w.player.cues.filter { $0.snd == 803 }, [PlayerCue(call: .stop, snd: 803)])
        // The cue's fields, and no cap on `+0xa4`: HP 558 with G+4 558 → 562.
        let v = pool(try level(2), liquid: 3)
        let vs = enter(v)
        v.active.update(id: v.playerID!) { $0.hp = 558 }
        v.globals.health = 558
        for _ in 1...3 { frame(v, vs) }
        XCTAssertEqual(player(v).hp, 562)
        XCTAssertEqual(v.player.cues.filter { $0.snd == 803 },
                       [PlayerCue(call: .reg, snd: 803, priority: 1, volume: 0xab, onlyIfIdle: true)])
        // `+0xa4` ≤ 0: the heal block is skipped → nothing heals → stop (row 17 alone, counter 2).
        let z = pool(try level(2), liquid: 3)
        XCTAssertNotNil(Player.spawn(world: z, x: 100, y: standY))
        z.active.update(id: z.playerID!) { p in
            p.lastWater = 1
            p.waterKind = 3
            p.hp = 0
        }
        z.player.liquidCounter = 2
        z.globals.breath = 10
        z.globals.magic = 0
        PlayerLiquids.liquidDamage(z, id: z.playerID!)
        XCTAssertEqual(z.player.cues, [PlayerCue(call: .stop, snd: 803)])
        XCTAssertEqual(z.globals.breath, 10)
        XCTAssertEqual(z.globals.magic, 0)
        // Row 17's heal alone (counter 2, `+0xa4` 100, max health G+0xa 560, max magic G+0xc 560): oxygen +8, capped
        // only above G+0xa (`G+0xa < G+6`); healing on G+4 < G+0xa (strict); magic +4 on G+0xe < G+0xc (strict, no cap).
        func heal(breath: Int16, health: Int16, magic: Int16) -> (breath: Int16, hp: Int16, magic: Int16, cue: PlayerCue.Call?) {
            z.active.update(id: z.playerID!) { $0.hp = 100 }
            z.player.liquidCounter = 2
            _ = z.player.drainFrameOutputs()
            z.globals.maxHealth = 560
            z.globals.maxMagic = 560
            z.globals.breath = breath
            z.globals.health = health
            z.globals.magic = magic
            PlayerLiquids.liquidDamage(z, id: z.playerID!)
            return (z.globals.breath, player(z).hp, z.globals.magic, z.player.cues.first { $0.snd == 803 }?.call)
        }
        var h = heal(breath: 100, health: 560, magic: 560)
        XCTAssertEqual([h.breath, h.hp, h.magic], [108, 100, 560])
        XCTAssertEqual(h.cue, .stop)
        h = heal(breath: 552, health: 559, magic: 560)                      // 560: at the cap, kept; G+4 559 heals
        XCTAssertEqual([h.breath, h.hp, h.magic], [560, 104, 560])
        XCTAssertEqual(h.cue, .reg)
        h = heal(breath: 553, health: 560, magic: 559)                      // 561 → 560; magic 559 → 563
        XCTAssertEqual([h.breath, h.hp, h.magic], [560, 100, 563])
        XCTAssertEqual(h.cue, .reg)
        h = heal(breath: 559, health: 561, magic: 561)                      // above the maxima: nothing heals
        XCTAssertEqual([h.breath, h.hp, h.magic], [560, 100, 561])
        XCTAssertEqual(h.cue, .stop)
    }

    func testSwimStrokeImpulse() throws {
        // Wading: water on rows 10–11 (surface 320), standing at y 315 → `+0x11c` = 5 → near-surface 1 next frame,
        // grounded → jump counter 6. JUMP → the swim stroke: J − 0x640 − ((|vx| + 200) >> 3) = −1625 at rest, not
        // halved (near the surface), through `.AccelerateSprite`'s in-water ×0.8 → −1300 (cap 2000 × 0.8).
        let w = pool(try level(2), rows: 10...11)
        let solver = enter(w)
        frame(w, solver)
        XCTAssertTrue(w.player.nearSurface)
        XCTAssertEqual(player(w).waterRow, 5)
        XCTAssertEqual(w.player.jumpCounter, 6)
        let e = w.player.exertion
        _ = w.player.drainFrameOutputs()
        HandleKeys.run(world: w, keys: .jump, ridden: nil)
        XCTAssertEqual(player(w).vy, -1300)
        XCTAssertEqual(w.player.swim, 3)
        XCTAssertEqual(w.player.strokeCooldown, 0xc)
        XCTAssertEqual(w.player.exertion, e + 8)
        XCTAssertEqual(w.player.jumpCounter, 5)
        XCTAssertEqual(player(w).gravity, 0x50)
        XCTAssertEqual(player(w).face, FaceRef(pict: 1027, index: 0, set: .encoded))
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .reg, snd: 497, priority: 1, volume: 0x9c)])
        // vx 800: −0x640 − (1000 >> 3) = −1725 → −1380. Below the band, already swimming: halved (srawi) −863 → −690.
        w.active.update(id: w.playerID!) { p in p.vx = 800; p.vy = 0 }
        w.player.jumpCounter = 6
        HandleKeys.run(world: w, keys: .jump, ridden: nil)
        XCTAssertEqual(player(w).vy, -1380)
        w.player.nearSurface = false
        w.player.swim = 1
        w.player.jumpCounter = 6
        w.active.update(id: w.playerID!) { p in p.vx = 0; p.vy = 0 }
        HandleKeys.run(world: w, keys: .jump, ridden: nil)
        XCTAssertEqual(player(w).vy, -650)                                  // −1625 >> 1 = −813 → −650.4
    }

    func testNearSurfaceBand() throws {
        // Row 15 (l. 44815–44826): `+0x120` 1…21 → near-surface 1 (not kind 5); ≥ 44 or grounded → 0; 22…43 keeps the
        // previous value. First from the water itself: wading (surface 320, y 315) gives `+0x11c` 5 → 1.
        let w = pool(try level(2), rows: 10...11)
        let solver = enter(w)
        XCTAssertFalse(w.player.nearSurface)                                // frame 0: `+0x120` 0
        frame(w, solver)
        XCTAssertTrue(w.player.nearSurface)
        // Then `+0x11c` set before each frame (`.StandardSpriteHandles` copies it to `+0x120` before row 15), with a
        // tile callback that does nothing (airborne, dry end pass).
        let v = pool(try level(2), rows: nil, floor: false)
        XCTAssertNotNil(Player.spawn(world: v, x: 100, y: 100))
        let vs = TileSolver(world: v)
        func band(_ water: Int32, kind: Int16 = 0, grounded: Bool = false) -> Bool {
            v.active.update(id: v.playerID!) { p in
                p.waterRow = water
                p.waterKind = kind
                p.groundKind = grounded ? 3 : 0
            }
            Player.handle(world: v, keys: [], solver: vs, tileHit: { _, _, _, _, _ in })
            return v.player.nearSurface
        }
        XCTAssertEqual([band(1), band(30), band(43), band(44), band(22), band(21), band(22, grounded: true)],
                       [true, true, true, false, false, true, false])
        XCTAssertEqual([band(10), band(0), band(10), band(10, kind: 5), band(-1), band(10, kind: 5, grounded: true)],
                       [true, false, true, true, true, false])
        // Kind 5 never sets it: from 0, `+0x120` 10 in kind 5 keeps 0 (kind 0 would set 1).
        XCTAssertEqual([band(0), band(10, kind: 5), band(1, kind: 5), band(10)], [false, false, false, true])
    }

    func testBelowMapKills() throws {
        // Level 1 (hdr 0xb282 = 50 rows): row 42 sets HP 0 once y > 50·32 + 100 = 1700, after the frame's death test —
        // the trigger (417, dying 1, died dry) comes on the next frame. Empty grid: falling from y 1700, frame 1 moves
        // 440/256 → y 1701.
        let w = pool(try level(1), rows: nil, floor: false)
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: 1700))
        let solver = TileSolver(world: w)
        frame(w, solver)
        XCTAssertEqual(player(w).y, 1701)
        XCTAssertEqual(player(w).hp, 0)
        XCTAssertEqual(w.globals.health, 560)                               // G+4 = HP before the below-map test
        XCTAssertEqual(w.player.dying, 0)
        frame(w, solver)
        XCTAssertEqual(w.player.dying, 1)
        XCTAssertFalse(w.player.diedInLiquid)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 417 }, [PlayerCue(call: .reg, snd: 417, priority: 1, volume: 0x100)])
        XCTAssertEqual(w.globals.health, 0)
        frame(w, solver)                                                    // dying: no second trigger
        XCTAssertEqual(w.player.dying, 2)
        XCTAssertEqual(w.player.cues.filter { $0.snd == 417 }, [])
        // y 1700 is not below the map.
        let v = pool(try level(1), rows: nil, floor: false)
        XCTAssertNotNil(Player.spawn(world: v, x: 100, y: 1699))
        frame(v, TileSolver(world: v))
        XCTAssertEqual(player(v).y, 1700)
        XCTAssertEqual(player(v).hp, 560)
        // The trigger waits for the stun and does not re-fire while dying.
        let u = pool(try level(1), rows: nil, floor: false)
        XCTAssertNotNil(Player.spawn(world: u, x: 100, y: 1700))
        let us = TileSolver(world: u)
        frame(u, us)
        u.player.stun = 5
        frame(u, us)
        XCTAssertEqual(u.player.dying, 0)
        // Died-in-liquid `PTR_DAT_100a0560` = 0 only when `+0x11c` and `+0x120` are both 0 (l. 46442–46444): either
        // one alone → 1.
        for (row, last, wet) in [(Int32(5), Int32(0), true), (0, 5, true), (0, 0, false), (5, 5, true)] {
            let t = pool(try level(1), rows: nil, floor: false)
            XCTAssertNotNil(Player.spawn(world: t, x: 100, y: 100))
            t.active.update(id: t.playerID!) { p in
                p.hp = 0
                p.waterRow = row
                p.lastWater = last
            }
            PlayerLiquids.deathAndRefill(t, id: t.playerID!)
            XCTAssertEqual(t.player.dying, 1)
            XCTAssertEqual(t.player.diedInLiquid, wet, "+0x11c \(row), +0x120 \(last)")
        }
    }
}

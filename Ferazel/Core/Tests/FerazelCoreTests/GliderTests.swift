import XCTest
@testable import FerazelCore

/// GL (docs/plans/2026-10-24-ferazel-phase4.md): the hang glider — row 8's pitch gravity and wind scale (M l.
/// 44622–44655), row 33's glider arm (M l. 45219–45471: deploy, the glide with its loop / pitch / cast / turn faces,
/// the dive and pull-up, landing, the stow and its dropped 0xbea, dying on the glider) and `.HandleKeys`' steering
/// (M l. 47494–47541); spells-detail §5.1–§5.4, spells-detail-2 §1 (`PTR_DAT_100a04cc`). Synthetic 16×16 grid as
/// PlayerMotionTests (a flat FG floor on row 12 when asked, surface 400) over level 1's data.
final class GliderTests: XCTestCase {

    private let standY = 400 - 0x55

    private func world(floor: Bool) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        if floor { for c in 0..<16 { fg[12 * 16 + c] = 3 + 1 } }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg),
                           bg: TileMap(width: 16, height: 16, cells: [UInt16](repeating: 0, count: 16 * 16)),
                           fgKinds: Array(0..<0x60), bgKinds: [Int](repeating: 0, count: 0x60))
        w.globals.health = 0x230
        w.globals.maxHealth = 0x230
        w.globals.breath = 0x230
        return w
    }

    /// The `.HitPlayerTileSprite` double of PlayerMotionTests: FG cells → `.WallBounce`.
    private let floorHit: TileHit = { solver, id, cell, kind, layer in
        guard layer == .foreground, let s = solver.world.active.sprite(id: id) else { return }
        var p = cell
        let r = s.hotRect
        solver.wallBounce(id, kind: kind, tile: &p, vCentre: r.top + ((r.bottom - r.top) >> 1), factor: 0, rect: r,
                          bounce: false)
    }

    private func frame(_ w: SpriteWorld, _ solver: TileSolver, _ keys: InputActions = []) {
        _ = w.player.drainFrameOutputs()
        Player.handle(world: w, keys: keys, solver: solver, tileHit: floorHit)
    }

    private func player(_ w: SpriteWorld) -> SpriteSlot { w.active.sprite(id: w.playerID!)! }

    /// The pickup's state writes (PK, M l. 48920–48936): glider on, phase 1, ground count 0.
    private func pickUp(_ w: SpriteWorld) {
        w.player.glider = true
        w.player.gliderExit = 1
        w.player.glider05c8 = 0
    }

    private func f(_ pict: Int16, _ i: Int) -> FaceRef { FaceRef(pict: pict, index: i, set: .encoded) }

    func testDeployTimeline() throws {
        let w = try world(floor: false)
        let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
        let solver = TileSolver(world: w)
        pickUp(w)
        w.active.update(id: id) { $0.vx = 0x500 }
        var vys: [Int32] = [], gravities: [Int16] = [], faces: [FaceRef?] = []
        for _ in 1...33 {
            frame(w, solver)
            vys.append(player(w).vy)
            gravities.append(player(w).gravity)
            faces.append(player(w).face)
        }
        // Frame 1 (phase 1): vy 0, gravity 0, vx 0; frames 2–16 hang still (row 23's vy 0 → 1). Frames 1…23 face
        // 1050[phase >> 2] and vx 0; the gravity −0x78 is set once the phase passes 16 (frames 16…23) and so applied
        // on frames 17…24 — eight frames, where spells-detail §5.2 counts seven.
        XCTAssertEqual(vys[0], 0)
        XCTAssertEqual(Array(vys[1...15]), [Int32](repeating: 1, count: 15))
        XCTAssertEqual(Array(gravities[0...14]), [Int16](repeating: 0, count: 15))
        XCTAssertEqual(Array(gravities[15...22]), [Int16](repeating: -0x78, count: 8))
        for k in 1...23 { XCTAssertEqual(faces[k - 1], f(0x41a, k >> 2), "frame \(k)") }
        XCTAssertEqual(Array(vys[16...23]), (1...8).map { 1 - 120 * Int32($0) })
        // Phase 24 (frames 24…31): gravity + 0x1e while < 100 with the loop faces 1051[c >> 3]; frame 32 → phase 0.
        XCTAssertEqual(Array(gravities[23...30]), [-90, -60, -30, 0, 30, 60, 90, 120])
        XCTAssertEqual(faces[23], f(1051, 0))
        XCTAssertEqual(w.player.gliderLoop, 10)                          // frames 24…33: ten loop steps
        XCTAssertEqual(Array(vys[24...31]), [-1049, -1109, -1139, -1139, -1109, -1049, -959, -839])
        // Gliding: exactly −839 when the phase reaches 0 (frame 32; the bank's "≈ −720" counts seven −120 frames);
        // frame 33 sinks at the level pitch's gravity 60 with wind scale 256.
        XCTAssertEqual(gravities[31], 120)
        XCTAssertEqual(w.player.gliderExit, 0)
        XCTAssertEqual(vys[32], -839 + 60)
        XCTAssertEqual(gravities[32], 60)
        XCTAssertEqual(player(w).windScale, 0x100)
        XCTAssertEqual(player(w).hotRect, IdleSprites.Rect(top: 0x3e, left: 0x37, bottom: 0x61, right: 99))
        XCTAssertEqual(faces[32], f(1051, 1))
    }

    func testPitchTable() throws {
        let w = try world(floor: false)
        let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
        w.player.glider = true
        let expected: [(Int16, Int16, Int16)] = [
            (-5, 20, 506), (-4, 40, 381), (-3, 47, 339), (-2, 50, 318), (-1, 52, 306), (0, 60, 256),
            (1, 72, 212), (2, 75, 201), (3, 80, 183), (4, 90, 146), (5, 120, 36),
        ]
        for (pitch, gravity, wind) in expected {
            w.player.gliderPitch = pitch
            w.player.gliderExit = 0
            w.active.update(id: id) { $0.gravity = 7; $0.windScale = 7; $0.groundKind = 0 }
            Player.selectGravity(world: w, id: id)
            XCTAssertEqual([player(w).gravity, player(w).windScale], [gravity, wind], "pitch \(pitch)")
        }
        // Deploying / stowing (phase ≠ 0): row 8 leaves both alone; grounded: 0x1b8; off the glider: 0x1b8.
        for phase: Int16 in [5, -3] {
            w.player.gliderExit = phase
            w.active.update(id: id) { $0.gravity = 7; $0.windScale = 7 }
            Player.selectGravity(world: w, id: id)
            XCTAssertEqual([player(w).gravity, player(w).windScale], [7, 7])
        }
        w.player.gliderExit = 0
        w.active.update(id: id) { $0.groundKind = 3; $0.windScale = 7 }
        Player.selectGravity(world: w, id: id)
        XCTAssertEqual([player(w).gravity, player(w).windScale], [0x1b8, 7])

        // Dying on the glider (row 33, M l. 45405–45470): gravity 0x17c, pitch + 1 (≤ 5), phase 0, vx 0 and no face
        // of its own (the glide arm's 1052[5] stays); its end is the game over even holding the Resurrection Necklace.
        w.globals.inventory = [InventorySlot](repeating: .empty, count: GameGlobals.inventorySlots)
        w.globals.inventory[1] = InventorySlot(id: 0x17, count: 1, field4: -1, field6: 0, isSpell: 0)
        w.player.gliderPitch = 4
        w.player.dying = 1
        w.active.update(id: id) { $0.vx = 0x300; $0.groundKind = 0; $0.onSprite = 0 }
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual([player(w).gravity, w.player.gliderPitch, w.player.dying, w.player.gliderExit], [0x17c, 5, 2, 0])
        XCTAssertEqual(player(w).vx, 0)
        XCTAssertEqual(player(w).face, FaceRef(pict: 1052, index: 5, set: .encoded))
        w.player.dying = 0x50
        PlayerStates.select(world: w, id: id)
        XCTAssertTrue(w.player.gameOver)
        XCTAssertEqual(w.player.revive, 0)
    }

    func testSteerAndTurn() throws {
        let w = try world(floor: false)
        let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
        w.player.glider = true
        w.active.update(id: id) { $0.mirrored = false }                  // facing right (`+0x17e` 0)
        // RIGHT from rest: +0x96 per frame while vx < 0xc80 — the 22nd press overshoots to 0xce4, then holds.
        var vxs: [Int32] = []
        for _ in 0..<23 {
            HandleKeys.run(world: w, keys: .right, ridden: nil)
            vxs.append(player(w).vx)
        }
        XCTAssertEqual(Array(vxs[0...20]), (1...21).map { 0x96 * Int32($0) })
        XCTAssertEqual(Array(vxs[21...22]), [0xce4, 0xce4])
        XCTAssertEqual(w.player.gliderTurn, 0)                           // pushing with the facing: no turn
        // LEFT facing right from 0: the turn starts once vx < −0x300 (the sixth press, −0x384) → counter 12; LEFT
        // wins over RIGHT.
        w.active.update(id: id) { $0.vx = 0 }
        for n in 1...6 {
            HandleKeys.run(world: w, keys: [.left, .right], ridden: nil)
            XCTAssertEqual(w.player.gliderTurn, n < 6 ? 0 : 12, "press \(n)")
        }
        XCTAssertEqual(player(w).vx, -0x384)
        // RIGHT facing left past 0x300 → −12; a running turn is not restarted.
        w.player.gliderTurn = 0
        w.active.update(id: id) { $0.vx = 0x300; $0.mirrored = true }
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(w.player.gliderTurn, -12)
        w.player.gliderTurn = 3
        HandleKeys.run(world: w, keys: .right, ridden: nil)
        XCTAssertEqual(w.player.gliderTurn, 3)
        // UP / DOWN pitch ±1 within −5…5; neither decays 1 toward 0. HP 0: no steering at all.
        w.player.gliderPitch = 0
        for _ in 0..<7 { HandleKeys.run(world: w, keys: .up, ridden: nil) }
        XCTAssertEqual(w.player.gliderPitch, -5)
        HandleKeys.run(world: w, keys: [], ridden: nil)
        XCTAssertEqual(w.player.gliderPitch, -4)
        for _ in 0..<12 { HandleKeys.run(world: w, keys: .down, ridden: nil) }
        XCTAssertEqual(w.player.gliderPitch, 5)
        w.active.update(id: id) { $0.hp = 0; $0.vx = 0 }
        HandleKeys.run(world: w, keys: [.left, .up], ridden: nil)
        XCTAssertEqual([player(w).vx, Int32(w.player.gliderPitch)], [0, 5])
        w.active.update(id: id) { $0.hp = 0x230 }

        // The turn's faces (row 33, phase 0): counter 12 → 11 shows 1050[5] still facing right; the facing flips
        // once |t| >> 1 < 3 (1050[5 − k]); at 0 → 1051[0].
        w.player.gliderExit = 0
        w.player.gliderTurn = 12
        w.active.update(id: id) { $0.mirrored = false; $0.groundKind = 0; $0.onSprite = 0 }
        var seen: [(FaceRef?, Bool, Int16)] = []
        for _ in 0..<12 {
            PlayerStates.select(world: w, id: id)
            seen.append((player(w).face, player(w).mirrored, w.player.facing))
        }
        let idx = seen.map { $0.0?.index ?? -1 }
        XCTAssertEqual(idx, [5, 5, 4, 4, 3, 3, 3, 3, 4, 4, 5, 0])
        XCTAssertEqual(seen.map { $0.0?.pict ?? 0 }, [Int16](repeating: 0x41a, count: 11) + [1051])
        XCTAssertEqual(seen.map(\.1), [Bool](repeating: false, count: 6) + [Bool](repeating: true, count: 6))
        XCTAssertEqual(seen.map(\.2), [Int16](repeating: 2, count: 6) + [Int16](repeating: 1, count: 6))

        // The dive (pitch 4…5, no turn, wand step < 3): counter + 1 up to 30 and vx +0x50 facing right while
        // < 0xc80 (−0x50 facing left); face 1052[k + 3]. Pull-up (pitch 1…3, counter c > 0): vy += trunc(−0x640·c/30).
        w.active.update(id: id) { $0.mirrored = false; $0.vx = 0xc40; $0.vy = 0 }
        w.player.gliderPitch = 5
        w.player.gliderDive = 29
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual([player(w).vx, Int32(w.player.gliderDive)], [0xc90, 30])
        XCTAssertEqual(player(w).face, f(1052, 5))
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual([player(w).vx, Int32(w.player.gliderDive)], [0xc90, 30])
        w.player.gliderPitch = 2
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(player(w).vy, -1600)
        XCTAssertEqual(player(w).face, f(1052, 4))
        w.player.gliderDive = 7
        w.active.update(id: id) { $0.vy = 0 }
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(player(w).vy, -373)                               // trunc(−11200 / 30)
        // Nose up: 1052[k], no lift; pitch 0 resets the counter; wand step ≥ 3 → 1053[step − 3], nothing else.
        w.player.gliderPitch = -5
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual([player(w).vy, Int32(w.player.gliderDive)], [-373, 7])
        XCTAssertEqual(player(w).face, f(1052, 2))
        w.player.gliderPitch = 0
        w.player.wandPhase = 4
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(player(w).face, f(1053, 1))
        XCTAssertEqual(w.player.gliderDive, 7)
        w.player.wandPhase = 0
        PlayerStates.select(world: w, id: id)
        XCTAssertEqual(w.player.gliderDive, 0)
    }

    func testLandAndStow() throws {
        let w = try world(floor: true)
        let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        w.player.glider = true
        w.active.update(id: id) { $0.vx = 0x400 }
        // The first frame's vy 60 (pitch 0) moves less than a pixel: no contact yet, count 0, only the drag 0x14.
        frame(w, solver)
        XCTAssertEqual([Int32(w.player.glider05c8), player(w).vx], [0, 0x400 - 0x14])
        // Every grounded frame: count + 1, vx = trunc(vx · 0.5) after the drag, vy 0x100; the 13th → phase −23, and
        // the stow arm runs on that same frame (→ −22).
        var vxs: [Int32] = []
        for n in 1...13 {
            frame(w, solver)
            XCTAssertEqual(w.player.glider05c8, Int16(n))
            vxs.append(player(w).vx)
            if n < 13 { XCTAssertEqual(w.player.gliderExit, 0) }
        }
        XCTAssertEqual(Array(vxs[0...3]), [492, 236, 108, 44])
        XCTAssertEqual(w.player.gliderExit, -22)
        XCTAssertEqual(player(w).face, f(0x41a, 5))
        XCTAssertEqual([player(w).vx, player(w).vy, Int32(player(w).gravity)], [0, 0x100, 0])
        // 23 stow frames in all (the landing frame the first); the last drops the glider.
        for _ in 1...21 { frame(w, solver) }
        XCTAssertTrue(w.player.glider)
        XCTAssertEqual(w.player.gliderExit, -1)
        XCTAssertEqual(player(w).face, f(0x41a, 0))
        let before = w.active.sprites.count
        frame(w, solver)
        XCTAssertFalse(w.player.glider)
        XCTAssertEqual(w.player.countdown05c4, 0xb4)
        XCTAssertEqual(w.active.sprites.count, before + 1)
        let drop = try XCTUnwrap(w.active.sprites.first { $0.type == 0xbea })
        XCTAssertEqual(drop.handler, .bonus)
        XCTAssertEqual(drop.face, f(0xbea, 0))

        // The stow's last step in isolation: the 0xbea at the player's (+0xc, +0xa), then x += 30 px, y += 32 px
        // (10 px while `PTR_DAT_100a04cc`), gravity 0x1b8, the stand face and the standard rect.
        for timer: Int8 in [0, 3] {
            let w = try world(floor: false)
            let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: 200))
            w.player.glider = true
            w.player.gliderExit = -1
            w.player.oneWayTimer = timer
            w.active.update(id: id) { $0.x256 = 0x6440; $0.y256 = 0xc880; $0.x = 0x64; $0.y = 0xc8 }
            PlayerStates.select(world: w, id: id)
            let p = player(w)
            XCTAssertEqual([p.x256, p.y256], [0x6440 + 0x1e00, 0xc880 + (timer == 0 ? 0x2000 : 0xa00)])
            XCTAssertEqual(p.gravity, 0x1b8)
            XCTAssertEqual(p.face, f(1003, 0))
            XCTAssertEqual(p.hotRect, HandleKeys.standardHotRect)
            XCTAssertEqual(w.player.countdown05c4, 180)
            let g = try XCTUnwrap(w.active.sprites.first { $0.type == 0xbea })
            XCTAssertEqual([g.x, g.y], [0x64, 0xc8])
            XCTAssertEqual([g.x256, g.y256], [0x6400, 0xc800])
            XCTAssertEqual(g.hotRect, IdleSprites.Rect(top: 0x44, left: 0x47, bottom: 0x6d, right: 0x5a))
        }
        // Stowing above −17 lifts the player 2 px a frame (`+0x1c` −= 0x200, `+0xa` from it).
        let w2 = try world(floor: false)
        let id2 = try XCTUnwrap(Player.spawn(world: w2, x: 100, y: 200))
        w2.player.glider = true
        w2.player.gliderExit = -17
        w2.active.update(id: id2) { $0.y256 = 0xc880 }
        PlayerStates.select(world: w2, id: id2)
        XCTAssertEqual([player(w2).y256, Int32(player(w2).y)], [0xc680, 0xc6])
        PlayerStates.select(world: w2, id: id2)
        XCTAssertEqual(player(w2).y256, 0xc680)                         // phase −16: no lift
    }

    func testCooldownBlocksRepickup() throws {
        let w = try world(floor: true)
        let id = try XCTUnwrap(Player.spawn(world: w, x: 100, y: standY))
        let solver = TileSolver(world: w)
        w.player.glider = true
        w.player.gliderExit = -1
        PlayerStates.select(world: w, id: id)
        let gid = try XCTUnwrap(w.active.sprites.first { $0.type == 0xbea }?.id)
        var lights = LightTable()
        func touch() { HitPlayerSprite.hit(w, player: id, other: gid, keys: [], lights: &lights, effects: 1) }
        // Within the 180-frame cooldown (row 13 counts it down): nothing.
        for _ in 0..<179 { frame(w, solver) }
        XCTAssertEqual(w.player.countdown05c4, 1)
        touch()
        XCTAssertFalse(w.player.glider)
        XCTAssertEqual(w.active.record(id: gid)?.killCount, 0)
        // At 0: deploy again — phase 1, then the first deploy frame shows 1050[0] with vy 0.
        frame(w, solver)
        XCTAssertEqual(w.player.countdown05c4, 0)
        touch()
        XCTAssertTrue(w.player.glider)
        XCTAssertEqual(w.player.gliderExit, 1)
        XCTAssertEqual(w.active.record(id: gid)?.killCount, 1)
        frame(w, solver)
        XCTAssertEqual(w.player.gliderExit, 2)
        XCTAssertEqual(player(w).face, f(0x41a, 0))
        XCTAssertEqual(player(w).vy, 0)
    }
}

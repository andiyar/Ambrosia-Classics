import XCTest
import HectorResources
@testable import FerazelCore

/// SW (docs/plans/2026-10-24-ferazel-phase4.md): the spells' world effects — the Ice Wall's floes and ledges
/// (`.HandlePlayerShotSprite` M l. 50797–50803, `.HitPlayerShotTileSprite` M l. 51263–51297), the Tree Trunk's
/// segments (M l. 51312–51327, 51005–51030; the trunk arms of `.SetupBoxSprite` M l. 58967–58980 and
/// `.HandleBoxSprite` M l. 60198–60216) and the Statue (`.HitPlatformSprite` M l. 55798–55803, `.TurnIntoStatue` M l.
/// 38244–38272, `.HandleStatueSprite` M l. 56521–56555). Synthetic 16×16 grids over level 1's header (as `CastTests`).
final class SpellWorldTests: XCTestCase {

    /// A 16×16 grid with the FG `cells` (col, row, raw cell value); BG tile 5 = kind 200 (water) on rows ≥ `waterRow`.
    private func world(_ cells: [(Int, Int, UInt16)] = [], waterRow: Int? = nil) throws -> SpriteWorld {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let w = SpriteWorld(level: try LevelFile.load(from: r, level: 1))
        var fg = [UInt16](repeating: 0, count: 16 * 16)
        for (c, row, v) in cells { fg[row * 16 + c] = v }
        var bg = [UInt16](repeating: 0, count: 16 * 16)
        var bgKinds = [Int](repeating: 0, count: 0x60)
        if let wr = waterRow {
            for row in wr..<16 { for c in 0..<16 { bg[row * 16 + c] = 5 + 1 } }
            bgKinds[5] = 200
        }
        w.tiles = TileGrid(fg: TileMap(width: 16, height: 16, cells: fg), bg: TileMap(width: 16, height: 16, cells: bg),
                           fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        return w
    }

    /// An FG floor of kind 3 on row 12 (the surface at y 400).
    private var floor: [(Int, Int, UInt16)] { (0..<16).map { ($0, 12, 4) } }
    /// A column of FG `kind` at col 8 (x 256…287).
    private func wall(_ kind: UInt16) -> [(Int, Int, UInt16)] { (0..<16).map { (8, $0, kind + 1) } }

    private func handleShots(_ w: SpriteWorld, _ solver: TileSolver, lights: inout LightTable) {
        for id in w.active.sprites.filter({ $0.handler == .playerShot }).map(\.id) {
            PlayerShot.handle(world: w, id: id, solver: solver, lights: &lights, effects: 2)
        }
    }

    private func run(_ w: SpriteWorld, until id: Int, frames: Int = 40) -> LightTable {
        let solver = TileSolver(world: w)
        var lights = LightTable()
        var n = 0
        while w.active.sprite(id: id)?.dead == false && n < frames {
            handleShots(w, solver, lights: &lights)
            n += 1
        }
        return lights
    }

    private func sprites(_ w: SpriteWorld, _ type: Int16, _ handler: SpriteHandler) -> [SpriteSlot] {
        w.active.sprites.filter { $0.type == type && $0.handler == handler }
    }

    func testIceWallFloe() throws {
        // An Ice Wall shot (id 3) falling into water: the liquid rule (M l. 50789–50803) — effect 5 at (+0xc − 8, +0xa −
        // 0xc), `+0xe9 = 1`, then (id 3, `+0x128 == 0`) `.CalcCenterPos` and `MTNewSprite(0x57c, +0xc − 10, +0xe − 4, 2, −1,
        // .SetupPlatformSprite)` with `+0xa6 = 0xb4`, `+0xb0 = 4`, `+0x13a = 4`; `+0x16c` stays 0 (the floe variant).
        let w = try world(waterRow: 10)
        let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0301, x: 100, y: 250))
        w.active.update(id: id) { $0.vy = 0x800 }
        _ = run(w, until: id)
        let s = try XCTUnwrap(w.active.sprite(id: id))
        XCTAssertTrue(s.dead)
        let e = try XCTUnwrap(sprites(w, 5, .effect).first)
        let floes = sprites(w, 0x57c, .platform)
        XCTAssertEqual(floes.count, 1)
        let f = try XCTUnwrap(floes.first)
        // x = +0xc − 10 = (effect x + 8) − 10; the centre y from the shot's hot rect (3…12): +0xa + 3 + 4.
        let shotY = e.y + 0xc
        XCTAssertEqual([f.x, f.y], [e.x + 8 - 10, shotY + 3 + 4 - 4])
        XCTAssertEqual([Int(f.counterA6), Int(f.subtype), Int(f.sag), Int(f.classWord16c), Int(f.layer)],
                       [0xb4, 4, 4, 0, -1])                         // the Setup's `+0x80 = −1` beats the layer 2 passed
        XCTAssertFalse(f.setupDone)                                     // `.DoSetupPlatformSprite` on its first Handle
        // Spell 7 (the second Ice Wall) tests `+4 == 3` nowhere: no floe (spells-detail §3.6).
        let w7 = try world(waterRow: 10)
        let id7 = try XCTUnwrap(PlayerShot.spawn(w7, type: 0x0701, x: 100, y: 250))
        w7.active.update(id: id7) { $0.vy = 0x800 }
        _ = run(w7, until: id7)
        XCTAssertTrue(try XCTUnwrap(w7.active.sprite(id: id7)).dead)
        XCTAssertTrue(sprites(w7, 0x57c, .platform).isEmpty)
    }

    func testIceWallLedge() throws {
        // An Ice Wall shot flying right into an FG wall: `.WallBounce` reports the contact (M l. 51259–51263), then the
        // side test (M l. 51263–51297): kind 2 → `MTNewSprite(0x57c, pos.h − 0x17, +0xe, 2, −1, …)`, `+0x16c = 1`; kind 0
        // → (pos.h + 0xf, +0xe), `+0x16c = 2`; both `+0xa6 = 0xb4`, `+0xb0 = 4` (no `+0x13a`). The contact rule then kills
        // the shot (snd 301). pos.h is the cell's left edge 256 (col 8).
        for (kind, dx, variant) in [(UInt16(2), -0x17, 1), (0, 0xf, 2)] {
            let w = try world(wall(kind))
            let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0301, x: 200, y: 200))
            w.active.update(id: id) { s in
                s.gravity = 0
                s.vx = 0x800
            }
            _ = run(w, until: id, frames: 20)
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual(s.killCount, 1, "kind \(kind)")
            let ledges = sprites(w, 0x57c, .platform)
            XCTAssertEqual(ledges.count, 1, "kind \(kind)")
            let l = try XCTUnwrap(ledges.first)
            XCTAssertEqual([l.x, l.y], [256 + dx, 200 + 3 + 4], "kind \(kind)")      // y = the shot's centre +0xe
            XCTAssertEqual([Int(l.counterA6), Int(l.subtype), Int(l.classWord16c), Int(l.sag)], [0xb4, 4, variant, 0x50],
                           "kind \(kind)")                              // the Setup's sag 0x50 stays (no `+0x13a` store)
            XCTAssertEqual(w.player.cues.map(\.snd), [301], "kind \(kind)")
        }
        // Kinds 4…7 need the shot stopped (`+0x24 == 0` after the bounce): a kind-4 corner (its rect the cell's lower
        // left quarter) met with vx 0 makes the kind-0 side's ledge (pos.h + 0xf, variant 2); met moving right, the
        // bounce leaves vx and nothing is made. Called straight (the tile callback at the cell (256, 192)).
        for (vx, made) in [(Int32(0), true), (0x100, false)] {
            let wk = try world()
            var k = SpriteSlot(type: 3, x: 251, y: 205)
            k.handler = .playerShot
            k.hotRect = IdleSprites.Rect(top: 3, left: 8, bottom: 0xc, right: 0xf)
            k.oldPosition = SpriteSlot.Point(x: 251, y: 205)
            k.centre = SpriteSlot.Point(x: 262, y: 212)
            k.vx = vx
            k.vy = 0x200
            let kID = wk.active.insert(k)
            var lk = LightTable()
            PlayerShot.hitTile(TileSolver(world: wk), kID, TilePos(x: 256, y: 192), 4, .foreground, lights: &lk, effects: 2)
            XCTAssertEqual(sprites(wk, 0x57c, .platform).map { [$0.x, Int($0.classWord16c)] }, made ? [[256 + 0xf, 2]] : [],
                           "vx \(vx)")
        }
        // A floor contact (kind 3) makes nothing; the shot dies on it.
        let wf = try world(floor)
        let down = try XCTUnwrap(PlayerShot.spawn(wf, type: 0x0301, x: 180, y: 300))
        wf.active.update(id: down) { $0.vy = 0x400 }
        _ = run(wf, until: down)
        XCTAssertTrue(try XCTUnwrap(wf.active.sprite(id: down)).dead)
        XCTAssertTrue(sprites(wf, 0x57c, .platform).isEmpty)
        // Spell 7 into the kind-2 wall: no ledge.
        let w7 = try world(wall(2))
        let id7 = try XCTUnwrap(PlayerShot.spawn(w7, type: 0x0701, x: 200, y: 200))
        w7.active.update(id: id7) { s in
            s.gravity = 0
            s.vx = 0x800
        }
        _ = run(w7, until: id7, frames: 20)
        XCTAssertEqual(try XCTUnwrap(w7.active.sprite(id: id7)).killCount, 1)
        XCTAssertTrue(sprites(w7, 0x57c, .platform).isEmpty)
    }

    func testTrunkPlanted() throws {
        // A power-2 Tree Trunk landing on the floor (M l. 51312–51327): the trunk bottom `MTNewSprite(0x2c8, +0x10 − 8,
        // +0xe − 6, 2, −1, .SetupBoxSprite)` — its arm (M l. 58974–58980): face 0x2c8, gravity 0x15e, rect (3, 4, 0x1d,
        // 0x18), `+0x88 = 0` — with `+0xa6 = *_DAT_1009fd30 + 0x78`; effect 2 at (trunk +0xc − 6, +0xa − 9); snd 302 at
        // the shot's centre; the shot's `+0xe9 = 1` directly — its follower flies on.
        for parity in [false, true] {
            let w = try world(floor)
            w.parity = parity
            let id = try XCTUnwrap(PlayerShot.spawn(w, type: 0x0402, x: 180, y: 300))
            let follower = try XCTUnwrap(w.active.sprite(id: id)?.siblings.first)
            w.active.update(id: id) { $0.vy = 0x400 }
            _ = run(w, until: id)
            XCTAssertTrue(try XCTUnwrap(w.active.sprite(id: id)).dead)
            XCTAssertEqual(w.active.sprite(id: follower)?.killCount, 0)
            let at = try XCTUnwrap(w.player.cues.first { $0.snd == 302 }?.position)
            XCTAssertEqual(w.player.cues.map(\.snd), [302])
            let trunks = sprites(w, 0x2c8, .box)
            XCTAssertEqual(trunks.count, 1)
            let t = try XCTUnwrap(trunks.first)
            XCTAssertEqual([t.x, t.y], [at.x - 8, at.y - 6])
            XCTAssertEqual([Int(t.counterA6), Int(t.gravity), Int(t.layer)], [parity ? 121 : 120, 0x15e, 2])
            XCTAssertEqual(t.hotRect, IdleSprites.Rect(top: 4, left: 3, bottom: 0x18, right: 0x1d))
            XCTAssertEqual(t.face, FaceRef(pict: 0x2c8, index: 0, set: .encoded))
            XCTAssertFalse(t.lightOverlay)
            XCTAssertEqual(t.recordIndex, -1)
            let e = try XCTUnwrap(sprites(w, 2, .effect).first)
            XCTAssertEqual([e.x, e.y, Int(e.phase)], [t.x - 6, t.y - 9, 8])
        }
        // On an underground floor (BG kind 103 = `.WallBounceBG` kind 3, M l. 51352–51358): a trunk bottom with `+0xa6 =
        // 0x78` (no parity), no effect 2 or snd 302 of its own; the contact rule then kills the shot (snd 301, its
        // effect 2 — the only one).
        let wb = try world()
        wb.parity = true
        var bgKinds = [Int](repeating: 0, count: 0x60)
        bgKinds[3] = 103
        wb.tiles = TileGrid(fg: wb.tiles.fg, bg: TileMap(width: 16, height: 16,
                                                          cells: (0..<16 * 16).map { $0 / 16 == 12 ? 4 : 0 }),
                            fgKinds: Array(0..<0x60), bgKinds: bgKinds)
        let ub = try XCTUnwrap(PlayerShot.spawn(wb, type: 0x0401, x: 180, y: 300))
        wb.active.update(id: ub) { $0.vy = 0x400 }
        _ = run(wb, until: ub)
        XCTAssertEqual(try XCTUnwrap(wb.active.sprite(id: ub)).killCount, 1)
        let under = sprites(wb, 0x2c8, .box)
        XCTAssertEqual(under.map { Int($0.counterA6) }, [0x78])
        XCTAssertEqual(wb.player.cues.map(\.snd), [301])
        XCTAssertEqual(sprites(wb, 2, .effect).count, 1)
        // The trunk's Handle arm (M l. 60198–60216): `+0xa6 − 1` a frame; below 0x17 the blink 0xb0001, below 0x15
        // 0xb0000, below 0xb 0xb0002; below 1 `+0xe9 = 1`.
        let w = try world()
        var t = SpriteSlot(type: 0x2c8, x: 1000, y: 100)
        t.handler = .box
        t.counterA6 = 0x18
        let tID = w.active.insert(t)
        var seen: [[Int]] = []
        for _ in 0..<0x18 {
            BoxSprite.handle(world: w, id: tID)
            let c = try XCTUnwrap(w.active.sprite(id: tID))
            seen.append([Int(c.counterA6), Int(c.mode), c.dead ? 1 : 0])
        }
        XCTAssertEqual(seen[0], [0x17, 0, 0])
        XCTAssertEqual(seen[1], [0x16, 0xb0001, 0])
        XCTAssertEqual(seen[2], [0x15, 0xb0001, 0])
        XCTAssertEqual(seen[3], [0x14, 0xb0000, 0])
        XCTAssertEqual(seen[13], [0xa, 0xb0002, 0])
        XCTAssertEqual(seen[22], [1, 0xb0002, 0])
        XCTAssertEqual(seen[23], [0, 0xb0002, 1])
    }

    func testTrunkGrows() throws {
        // A Tree Trunk shot into a trunk (M l. 51005–51030): walk `+0x1d4` to the top; `MTNewSprite(0x2c9, top +0xc,
        // top +0xa − 0x10, 2, −1, .SetupBoxSprite)` — its arm (M l. 58967–58972): face 0x2c9, gravity 0, rect (3, 3,
        // 0x1d, 0x15), `+0x88 = 0` — linked as `top +0x1d4` with `+0xa6 = parity + 0x78`; the old top's `+0xa6` raised to
        // 0x23 when below; the effect at the segment; the shot `+0xe9 = 1`.
        let w = try world()
        w.parity = true
        var base = SpriteSlot(type: 0x2c8, x: 4000, y: 1000)
        base.handler = .box
        base.counterA6 = 0x10
        let baseID = w.active.insert(base)
        var shot = SpriteSlot(type: 4, x: 4000, y: 1000)
        shot.handler = .playerShot
        shot.hasHit = true
        let shotID = w.active.insert(shot)
        var lights = LightTable()
        FerazelSession.hitCallback(w, shotID, baseID, lights: &lights)
        XCTAssertTrue(try XCTUnwrap(w.active.sprite(id: shotID)).dead)
        let seg1 = try XCTUnwrap(w.active.sprite(id: baseID)?.siblings.first)
        let s1 = try XCTUnwrap(w.active.sprite(id: seg1))
        XCTAssertEqual([Int(s1.type), s1.x, s1.y, Int(s1.counterA6), Int(s1.gravity), Int(s1.layer)],
                       [0x2c9, 4000, 1000 - 0x10, 121, 0, 2])
        XCTAssertEqual(s1.handler, .box)
        XCTAssertEqual(s1.hotRect, IdleSprites.Rect(top: 3, left: 3, bottom: 0x15, right: 0x1d))
        XCTAssertEqual(s1.face, FaceRef(pict: 0x2c9, index: 0, set: .encoded))
        XCTAssertEqual(w.active.sprite(id: baseID)?.counterA6, 0x23)
        let e = try XCTUnwrap(sprites(w, 2, .effect).first)
        XCTAssertEqual([e.x, e.y], [4000 - 6, 1000 - 0x10 - 9])
        // A second shot walks base → seg1 and stacks seg2 on seg1 (seg1's 121 is kept: not below 0x23).
        w.parity = false
        var shot2 = SpriteSlot(type: 4, x: 4000, y: 1000)
        shot2.handler = .playerShot
        let shot2ID = w.active.insert(shot2)
        FerazelSession.hitCallback(w, shot2ID, baseID, lights: &lights)
        let seg2 = try XCTUnwrap(w.active.sprite(id: seg1)?.siblings.first)
        let s2 = try XCTUnwrap(w.active.sprite(id: seg2))
        XCTAssertEqual([s2.x, s2.y, Int(s2.counterA6)], [4000, 1000 - 0x20, 120])
        XCTAssertEqual(w.active.sprite(id: seg1)?.counterA6, 121)
        XCTAssertEqual(w.active.sprite(id: baseID)?.counterA6, 0x23)
        XCTAssertEqual(w.player.cues.map(\.snd), [302, 302])
        // The raise is `< 0x23` (M l. 51016): an old top at 0x22 → 0x23, at 0x23 and 0x24 unchanged.
        for (a6, after) in [(Int16(0x22), Int16(0x23)), (0x23, 0x23), (0x24, 0x24)] {
            let wr = try world()
            var top = SpriteSlot(type: 0x2c8, x: 4000, y: 1000)
            top.handler = .box
            top.counterA6 = a6
            let topID = wr.active.insert(top)
            var sh = SpriteSlot(type: 4, x: 4000, y: 1000)
            sh.handler = .playerShot
            let shID = wr.active.insert(sh)
            FerazelSession.hitCallback(wr, shID, topID, lights: &lights)
            XCTAssertEqual(wr.active.sprite(id: topID)?.counterA6, after, "a6 \(a6)")
        }
        // A segment that lands becomes a bottom (`.HitBoxTileSprite`'s FG arm, M l. 61574–61580): 0x2c9 grounded →
        // 0x2c8, gravity 0.
        let wf = try world(floor)
        var lone = SpriteSlot(type: 0x2c9, x: 100, y: 400 - 0x15 + 2)        // 2 px into the surface
        lone.handler = .box
        lone.hotRect = IdleSprites.Rect(top: 3, left: 3, bottom: 0x15, right: 0x1d)
        lone.vy = 0x100
        let loneID = wf.active.insert(lone)
        let solver = TileSolver(world: wf)
        var l2 = LightTable()
        BoxSprite.hitTile(solver, id: loneID, pos: TilePos(x: 96, y: 384), kind: 3, layer: .foreground, lights: &l2,
                          effects: 1)
        let landed = try XCTUnwrap(wf.active.sprite(id: loneID))
        XCTAssertNotEqual(landed.groundKind, 0)
        XCTAssertEqual([Int(landed.type), Int(landed.gravity)], [0x2c8, 0])
    }

    /// A platform 0x578 (mode `+0xb0` 1) at (2000, 2000) moving right, through `.SetupPlatformSprite`.
    private func platform(_ w: SpriteWorld) throws -> Int {
        let id = try XCTUnwrap(PlatformSprite.newPlatform(w, type: 0x578, x: 2000, y: 2000, layer: 2))
        w.active.update(id: id) { p in
            p.subtype = 1
            p.vx = 0x300
            p.vy = 0x40
            p.hp = 500
            p.mode = 0x10003
            p.centre = SpriteSlot.Point(x: 2040, y: 2020)
        }
        return id
    }

    private func statueShot(_ w: SpriteWorld, power: Int32) -> Int {
        var s = SpriteSlot(type: 1, x: 2000, y: 2000)
        s.handler = .playerShot
        s.hasHit = true
        s.power = power
        return w.active.insert(s)
    }

    func testStatueFreezesPlatform() throws {
        // `.HitPlatformSprite` (M l. 55798–55803): a player shot with `+4 == 1` → shot `+0xe9 = 1`, platform `+0x190 = 0`,
        // `.TurnIntoStatue(platform)` (M l. 38244–38272): `.STPlay3DSound(302, 1, 0x32, +0xe)`; the Handle, hit and tile
        // callbacks saved and replaced by the Statue's (`.HandleStatueSprite`, `.HitBoxSprite`, `.HitBoxTileSprite`);
        // `+0x130 = 0x78`, `+0x134 = +0xb8`, v = 0.
        let w = try world()
        let pID = try platform(w)
        let sID = statueShot(w, power: 1)
        var lights = LightTable()
        FerazelSession.hitCallback(w, pID, sID, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: sID)?.killCount, 1)
        var p = try XCTUnwrap(w.active.sprite(id: pID))
        XCTAssertEqual(p.handler, .statue)
        XCTAssertEqual([p.savedHandler], [.platform])
        XCTAssertTrue(p.hasHit && p.hasTileHit)
        XCTAssertEqual([Int(p.reentry), Int(p.statueSavedMode), Int(p.vx), Int(p.vy)], [0x78, 0x10003, 0, 0])
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeD, snd: 302, priority: 1, volume: 0x32,
                                                 position: SpriteSlot.Point(x: 2040, y: 2020))])
        // While a Statue, its hit callback is `.HitBoxSprite`: a second Statue shot no longer petrifies it, and a
        // shot's own side takes the Box/Statue arm (M l. 51038): the platform is one-way → `.PlatformBounce`.
        let again = statueShot(w, power: 1)
        FerazelSession.hitCallback(w, pID, again, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: again)?.killCount, 0)
        XCTAssertEqual(w.active.sprite(id: pID)?.reentry, 0x78)
        // A Button pressed by the Statue (`.HitButtonSprite` M l. 61829–61835): level + 8.
        var b = SpriteSlot(type: 0x528, x: 2000, y: 2000)
        b.handler = .button
        b.hasHit = true
        let bID = w.active.insert(b)
        FerazelSession.hitCallback(w, bID, pID, lights: &lights)
        XCTAssertEqual(w.active.sprite(id: bID)?.phase, 8)
        // The four Statue arms, on a second frozen platform with the 0x578 rect DoSetup gives (0x10, 6, 0x3d, 0x1e):
        let w2 = try world()
        let q = try platform(w2)
        w2.active.update(id: q) { $0.hotRect = IdleSprites.Rect(top: 6, left: 0x10, bottom: 0x1e, right: 0x3d) }
        FerazelSession.hitCallback(w2, q, statueShot(w2, power: 1))
        XCTAssertEqual(w2.active.sprite(id: q)?.handler, .statue)
        w2.player.cues = []
        // (a) the shot's side (M l. 51038–51058): a Fireball falling onto the Statue takes the Statue/Box arm; the
        // platform's one-way top (`+0x185`) → `.PlatformBounce`, a contact → `.KillPlayerShot(s, 1, 1)` (snd 301).
        var fb = SpriteSlot(type: 0, x: 2020, y: 2000 + 6 - 0xc + 2)          // its rect bottom 2 px into the top
        fb.handler = .playerShot
        fb.hasHit = true
        fb.hotRect = IdleSprites.Rect(top: 3, left: 8, bottom: 0xc, right: 0xf)
        fb.oldPosition = SpriteSlot.Point(x: 2020, y: 2000 + 6 - 0xc - 4)
        fb.vy = 0x600
        let fbID = w2.active.insert(fb)
        var l2 = LightTable()
        FerazelSession.hitCallback(w2, fbID, q, lights: &l2)
        XCTAssertEqual(w2.active.sprite(id: fbID)?.killCount, 1)
        XCTAssertEqual(w2.player.cues.map(\.snd), [301])
        // (b) the player's side (M l. 49506–49513): `.PlatformBounce(player, statue, …)` lands him on it and returns —
        // the Platform arm's latch clears (`_DAT_100a0720`) and its ground effects are not reached.
        let pl = try XCTUnwrap(Player.spawn(world: w2, x: 2000, y: 2000 + 6 - 0x55 + 3))
        w2.active.update(id: pl) { s in                                  // the pixel copy `.MTNewSprite` scrambles
            s.x = 2000
            s.y = 2000 + 6 - 0x55 + 3
            s.x256 = Int32(s.x) << 8
            s.y256 = Int32(s.y) << 8
            s.vy = 0x400
            s.oldPosition = SpriteSlot.Point(x: 2000, y: 2000 + 6 - 0x55 - 6)
        }
        w2.player.bumpedLatch = true
        w2.player.landedLatch = true
        HitPlayerSprite.hit(w2, player: pl, other: q, lights: &l2, effects: 1)
        let ps = try XCTUnwrap(w2.active.sprite(id: pl))
        XCTAssertEqual([Int(ps.vy), ps.y], [0, 2000 + 6 - 0x55])
        XCTAssertTrue(w2.player.bumpedLatch && w2.player.landedLatch)
        // (c) `.HitBoxSprite`'s pair arm takes a Statue partner (M l. 61393): a Box against the Statue latches both;
        // (d) a Statue's own hit is `.HitBoxSprite` (`PTR_PTR_100a01f4`): the Statue against a Box latches both too.
        var box = SpriteSlot(type: 0x42e, x: 5000, y: 5000)
        box.handler = .box
        box.hasHit = true
        box.hotRect = IdleSprites.Rect(top: 0, left: 4, bottom: 0x1c, right: 0x1c)
        let boxID = w2.active.insert(box)
        FerazelSession.hitCallback(w2, boxID, q, lights: &l2)
        XCTAssertEqual([w2.active.sprite(id: boxID)?.boxPairLatch, w2.active.sprite(id: q)?.boxPairLatch], [true, true])
        w2.active.update(id: boxID) { $0.boxPairLatch = false }
        w2.active.update(id: q) { $0.boxPairLatch = false }
        FerazelSession.hitCallback(w2, q, boxID, lights: &l2)
        XCTAssertEqual([w2.active.sprite(id: boxID)?.boxPairLatch, w2.active.sprite(id: q)?.boxPairLatch], [true, true])
        // `.HandleStatueSprite` (M l. 56521–56555), 120 frames: a light (face 820, colour 0x21) at the centre once;
        // `+0xb8 = 0x1000b` (0 on odd counts below 20); v = 0; `+0x80 = 2`; at 0 the callbacks and `+0xb8` back, HP −200,
        // the light removed.
        var modes: [UInt32] = []
        for _ in 0..<0x78 {
            StatueSprite.handle(world: w, id: pID, lights: &lights)
            p = try XCTUnwrap(w.active.sprite(id: pID))
            modes.append(p.mode)
            if p.handler == .statue {
                XCTAssertEqual([Int(p.vx), Int(p.vy), Int(p.layer)], [0, 0, 2])
                XCTAssertEqual(lights.slots[Int(p.light)].face, LightFaceRef(pict: 0x334, width: 0x80, height: 0x80))
                XCTAssertEqual(lights.slots[Int(p.light)].colour, 0x21)
                XCTAssertEqual([Int(lights.slots[Int(p.light)].x), Int(lights.slots[Int(p.light)].y)], [2040, 2020])
            }
        }
        XCTAssertEqual(lights.count, 0)
        XCTAssertEqual(Array(modes[0..<0x64]), [UInt32](repeating: 0x1000b, count: 0x64))      // counts 119…20
        XCTAssertEqual(modes[0x64], 0)                                  // count 19: odd
        XCTAssertEqual(modes[0x65], 0x1000b)                            // 18
        XCTAssertEqual(modes[0x76], 0)                                  // 1
        XCTAssertEqual(modes[0x77], 0x10003)                            // 0: restored
        XCTAssertEqual(p.handler, .platform)
        XCTAssertEqual([Int(p.hp), Int(p.light), Int(p.reentry)], [300, -1, 0])
        XCTAssertTrue(p.hasHit && p.hasTileHit)
    }

    func testFollowerPetrifies() throws {
        // The site tests only `+4 == 1` (M l. 55798–55799): a power-0 follower of a Statue shot petrifies too.
        let w = try world()
        let pID = try platform(w)
        let fID = statueShot(w, power: 0)
        FerazelSession.hitCallback(w, pID, fID)
        XCTAssertEqual(w.active.sprite(id: fID)?.killCount, 1)
        XCTAssertEqual(w.active.sprite(id: pID)?.handler, .statue)
        // Any other id: nothing (a Fireball is not the platform's business).
        let w2 = try world()
        let p2 = try platform(w2)
        var fire = SpriteSlot(type: 0, x: 2000, y: 2000)
        fire.handler = .playerShot
        let fireID = w2.active.insert(fire)
        FerazelSession.hitCallback(w2, p2, fireID)
        XCTAssertEqual(w2.active.sprite(id: fireID)?.killCount, 0)
        XCTAssertEqual(w2.active.sprite(id: p2)?.handler, .platform)
        // The cannon arm of `.HitBackgroundSprite` (M l. 63682) excludes the Statue Handle: a Statue is not captured.
        var k = SpriteSlot(type: 0x442, x: 2000, y: 2000)
        k.handler = .background
        k.hasHit = true
        let kID = w.active.insert(k)
        FerazelSession.hitCallback(w, kID, pID)
        XCTAssertEqual(w.active.sprite(id: pID)?.handler, .statue)
    }
}

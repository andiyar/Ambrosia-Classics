import XCTest
@testable import FerazelCore

/// W2a (docs/plans/2026-10-10-ferazel-phase2.md): the Background class's radial bars and balls 1480–1489
/// (`.SetupBackgroundSprite @ 10071710`, `.HandleBackgroundSprite @ 10073afc`), their mace chains 0x59a / 0x59c
/// (`.HandleChainSprite`), the pendulum arm of `.HitPlayerSprite` and `.HurtPlayer @ 1005473c`, and the Handle's
/// re-face tail (plants, tunnels), against the committed `Resources/Ferazel` (D26). Triggers-background §2.2/§2.5/§2.11.
/// A missing data file is a FAILURE, never a skip.
final class BackgroundMoverTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func session() throws -> FerazelSession {
        try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1)
    }

    /// The record sprite `record` of the Background class.
    private func mace(_ s: FerazelSession, record: Int16) throws -> Int {
        try XCTUnwrap(s.active.sprites.first { $0.recordIndex == record && $0.handler == .background }).id
    }

    private static func width(_ f: FaceRef) -> Int { 0x80 }

    /// A world on level 1 holding a player (spawned at (x, y)) and nothing else.
    private func world(playerX: Int = 2000, playerY: Int = 1000) throws -> (SpriteWorld, Int) {
        let L = try LevelFile.load(from: try resources(), level: 1)
        let w = SpriteWorld(level: L)
        let p = try XCTUnwrap(Player.spawn(world: w, x: playerX, y: playerY))
        w.playerID = p
        // The pixel copy as the first separation leaves it (`.MTNewSprite` stores y into `+0xc`).
        w.active.update(id: p) { $0.x = playerX; $0.y = playerY }
        return (w, p)
    }

    /// A Background sprite of `type` made as `.MTNewSprite` + `.SetupBackgroundSprite` would for record `p`
    /// (synthetic records: no level slot).
    private func addBackground(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        let e = try SetupFaces.setup(p, context: c)
        let id = w.active.insert(e.slot)
        BackgroundSprite.makeRadial(w, id: id, record: e.record)
        return id
    }

    // MARK: -

    func testPendulumHarmfulBand() throws {
        // `.HandleBackgroundSprite` modes 12–14 (raw `100743a4..100743bc`): depth D = radial `+0x40`; D < 0x80 → layer
        // 0x7ef4 and harmful, except mode 12 with D < 0x60; D ≥ 0x80 → layer −300, harmless.
        let band = { (m: Int16, d: Int16) -> [Int] in
            let r = BackgroundSprite.depthBand(mode: m, depth: d)
            return [Int(r.layer), r.harmful ? 1 : 0]
        }
        XCTAssertEqual(band(12, 0x5f), [0x7ef4, 0])
        XCTAssertEqual(band(12, 0x60), [0x7ef4, 1])
        XCTAssertEqual(band(12, 0x7f), [0x7ef4, 1])
        XCTAssertEqual(band(12, 0x80), [-300, 0])
        XCTAssertEqual(band(12, 0), [0x7ef4, 0])
        XCTAssertEqual(band(13, 0x5f), [0x7ef4, 1])
        XCTAssertEqual(band(13, 0x80), [-300, 0])
        XCTAssertEqual(band(14, 0), [0x7ef4, 1])
        XCTAssertEqual(band(14, 0x7f), [0x7ef4, 1])
        XCTAssertEqual(band(14, 0x80), [-300, 0])

        // The Setup on synthetic records (`.SetupBackgroundSprite` l. 62312–62427): p1 0 → mode 0xb, p2 0 → 0x8c and
        // p3 0 → 0x1e written back to the record; `+0x5c`/`+0x1f8` 0, `+0xa6` 3 → 0 (modes 10–14), `+0xa4` 6, `+0x8a`
        // 0, one-way `+0x185` 1; rect (0x12, 0x2c, 0x6e, 0x44) below 0x5cd, (0x16, 0x16, 0x4e, 0x4e) from it.
        let (w, pID) = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        let e0 = try SetupFaces.setup(Placement(index: 0, flag: 1, byte1: 0, type: 1480, p1: 0, p2: 0, p3: 0, p4: 0,
                                                y: 600, x: 400), context: c)
        XCTAssertEqual([e0.record.p1, e0.record.p2, e0.record.p3, e0.record.p4], [0, 0x8c, 0x1e, 0])
        XCTAssertEqual(e0.slot.subtype, 0xb)
        XCTAssertEqual(e0.slot.hotRect, IdleSprites.Rect(top: 0x2c, left: 0x12, bottom: 0x44, right: 0x6e))
        XCTAssertEqual([Int(e0.slot.hp), Int(e0.slot.counterA6), Int(e0.slot.layer)], [6, 0, 1])
        XCTAssertEqual([e0.slot.hasHit, e0.slot.hasTileHit, e0.slot.currentApplies, e0.slot.oneWay],
                       [false, false, false, true])
        XCTAssertTrue(e0.slot.lightOverlay)                               // persp 0 keeps `+0x88`
        let e1 = try SetupFaces.setup(Placement(index: 1, flag: 1, byte1: 0, type: 1486, p1: 12, p2: 50, p3: 7, p4: 0,
                                                y: 600, x: 400), context: c)
        XCTAssertEqual([e1.record.p2, e1.record.p3], [50, 7])             // non-zero: kept
        XCTAssertEqual(e1.slot.hotRect, IdleSprites.Rect(top: 0x16, left: 0x16, bottom: 0x4e, right: 0x4e))
        XCTAssertFalse(e1.slot.lightOverlay)                              // persp ≠ 0 clears `+0x88`
        // Modes 3–9 / 15+: no radial, `+0xa6` stays 3, not one-way.
        let e2 = try SetupFaces.setup(Placement(index: 2, flag: 1, byte1: 0, type: 1485, p1: 5, p2: 0, p3: 0, p4: 0,
                                                y: 600, x: 400), context: c)
        XCTAssertEqual([Int(e2.slot.counterA6), e2.slot.oneWay ? 1 : 0, Int(e2.record.p2)], [3, 0, 0x8c])

        // `.MakeRadial`: hub (x + 0x32, y + 0x32)·256; modes 10/13/14 (r = p2, speed = p3, angle = p4, g 0); 11/12
        // (r = p2, speed 0, angle = p4, g = p3); persp 0 (10, 11), 1 (12, 13), 2 (14). Spokes p2/16 (C division) of
        // 0x59a (0x59c for mode 14), size 0x18, layer 0.
        func radial(_ type: Int16, _ m: Int16, _ p2: Int16, _ p3: Int16, _ p4: Int16) throws -> (SpriteSlot, Radial) {
            let id = try addBackground(w, Placement(index: 3, flag: 1, byte1: 0, type: type, p1: m, p2: p2, p3: p3,
                                                    p4: p4, y: 600, x: 400))
            let s = try XCTUnwrap(w.active.sprite(id: id))
            return (s, try XCTUnwrap(s.radial))
        }
        let (_, b10) = try radial(1480, 10, 40, 300, 90)
        XCTAssertEqual([b10.hubX, b10.hubY, b10.radius, b10.speed, b10.angle, Int32(b10.gravity), Int32(b10.persp)],
                       [450 << 8, 650 << 8, 40 << 8, 300, 90 << 8, 0, 0])
        XCTAssertEqual(b10.spokes.count, 2)                               // 40 / 16
        let (_, b12) = try radial(1485, 12, -33, 30, 190)
        XCTAssertEqual([b12.radius, b12.speed, b12.angle, Int32(b12.gravity), Int32(b12.persp)],
                       [-33 << 8, 0, 190 << 8, 30, 1])
        XCTAssertEqual(b12.spokes.count, 0)                               // −33 / 16 = −2 → none
        let (_, b13) = try radial(1485, 13, 50, 25, 7)
        XCTAssertEqual([b13.speed, Int32(b13.gravity), Int32(b13.persp)], [25, 0, 1])
        let (_, b14) = try radial(1485, 14, 47, 25, 7)
        XCTAssertEqual([Int32(b14.persp), Int32(b14.spokes.count)], [2, 2])
        let sp14 = try XCTUnwrap(w.active.sprite(id: try XCTUnwrap(b14.spokes[0])))
        XCTAssertEqual([Int(sp14.type), Int(sp14.layer)], [0x59c, 0])
        XCTAssertEqual(sp14.handler, .chain)
        let sp10 = try XCTUnwrap(w.active.sprite(id: try XCTUnwrap(b10.spokes[0])))
        XCTAssertEqual(sp10.type, 0x59a)
        XCTAssertEqual(sp10.hotRect, IdleSprites.Rect(top: 0, left: 0, bottom: 0x18, right: 0x18))

        // The Handle on a mode-12 ball (1486, rect (0x16, …)): the layer and `+0x170` from the band, every frame.
        let id12 = try addBackground(w, Placement(index: 4, flag: 1, byte1: 0, type: 1486, p1: 12, p2: 64, p3: 0,
                                                  p4: 0, y: 600, x: 400))
        // angle 0 (cos 1): D = 256·(R − R)/(2R) = 0 → front, D < 0x60 → harmless.
        BackgroundSprite.handle(world: w, id: id12, faceWidth: Self.width)
        var s12 = try XCTUnwrap(w.active.sprite(id: id12))
        XCTAssertEqual([Int(s12.layer), Int(s12.classWord170), Int(try XCTUnwrap(s12.radial).depth)], [0x7ef4, 0, 0])
        XCTAssertEqual(w.active.sprites.last?.id, id12)                   // moved to the tail of the list
        // angle 180 (cos −1): D = 256 → behind.
        w.active.update(id: id12) { $0.radial?.angle = 180 << 8 }
        BackgroundSprite.handle(world: w, id: id12, faceWidth: Self.width)
        s12 = try XCTUnwrap(w.active.sprite(id: id12))
        XCTAssertEqual([Int(s12.layer), Int(s12.classWord170), Int(try XCTUnwrap(s12.radial).depth)], [-300, 0, 256])
        XCTAssertEqual(w.active.sprites.first?.id, id12)                  // the head: below every layer
        // angle 85·256 with speed 0 and the written-back g 30: the pull toward 270° gives speed −30 → 84°, dx = (64 ·
        // cosT[84] 6850) / 256 = 1712, D = (int)(256 · (16384 − 1712) / 32768) = 114 (0x72) → front, harmful.
        w.active.update(id: id12) { $0.radial?.angle = 85 << 8; $0.classWord170 = 7 }
        BackgroundSprite.handle(world: w, id: id12, faceWidth: Self.width)
        s12 = try XCTUnwrap(w.active.sprite(id: id12))
        XCTAssertEqual([Int(s12.layer), Int(s12.classWord170), Int(try XCTUnwrap(s12.radial).depth)], [0x7ef4, 1, 114])
        XCTAssertEqual([s12.vx, s12.vy, s12.jumpBonus], [0, 0, 0])

        // Modes 10/11: harmful every frame, rotation (angle >> 8) + 90 (− 360 past 359), `+0x88` 0, `+0x89` 1; the layer
        // untouched.
        let id10 = try addBackground(w, Placement(index: 5, flag: 1, byte1: 0, type: 1481, p1: 10, p2: 32, p3: 0x200,
                                                  p4: 268, y: 600, x: 400))
        w.active.update(id: id10) { $0.vx = 5; $0.vy = 6; $0.jumpBonus = 9; $0.counterA6 = -2 }
        BackgroundSprite.handle(world: w, id: id10, faceWidth: Self.width)
        var s10 = try XCTUnwrap(w.active.sprite(id: id10))
        // angle 268·256 + 0x200 = 270° → rotation 360 → 0.
        XCTAssertEqual([Int(s10.classWord170), Int(s10.rotation), Int(s10.layer), Int(s10.counterA6)], [1, 0, 1, -1])
        XCTAssertEqual([s10.lightOverlay, s10.dynamicLight], [false, true])
        XCTAssertEqual([s10.vx, s10.vy, s10.jumpBonus], [0, 0, 0])
        // Type < 0x5cd: the centre is forced to (x + 0x40, y + 0x32) before `.UpdateRadialPos`, so the position is the
        // hub + offset − (0x40, 0x32): hub (450, 650), R 32 at 270° (dy = +32 down) → (386, 632).
        XCTAssertEqual([s10.x, s10.y], [450 - 0x40, 650 + 32 - 0x32])
        BackgroundSprite.handle(world: w, id: id10, faceWidth: Self.width)
        s10 = try XCTUnwrap(w.active.sprite(id: id10))
        XCTAssertEqual([Int(s10.rotation), Int(s10.counterA6)], [2, 0])   // 272° + 90 − 360; −1 → 0
        _ = pID

        // The per-frame re-face (`+0xc0` from the class cache): a mace, a plant and a tunnel get their own PICT again
        // whatever the face was; a W2b type (cannon 1090) is not run yet (its Handle untouched: no `.StandardSpriteHandles`).
        w.active.update(id: id10) { $0.face = FaceRef(pict: SetupFaces.placeholderPict, index: 0, set: .encoded) }
        BackgroundSprite.handle(world: w, id: id10, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: id10)?.face, FaceRef(pict: 1481, index: 0, set: .encoded))
        for t: Int16 in [2710, 2714, 3002] {
            let id = try addBackground(w, Placement(index: 6, flag: 1, byte1: 0, type: t, p1: 0, p2: 0, p3: 0, p4: 0,
                                                    y: 600, x: 400))
            w.active.update(id: id) { $0.face = FaceRef(pict: SetupFaces.placeholderPict, index: 0, set: .encoded)
                $0.invulnerable = 3 }
            BackgroundSprite.handle(world: w, id: id, faceWidth: Self.width)
            let s = try XCTUnwrap(w.active.sprite(id: id))
            XCTAssertEqual(s.face, FaceRef(pict: t, index: 0, set: .encoded))
            XCTAssertEqual(s.invulnerable, 2)                             // `.StandardSpriteHandles` ran
            XCTAssertEqual(s.centre, SpriteSlot.Point(x: 400, y: 600))    // `.StandardSpriteCleanup` ran (empty rect)
        }
        let cannon = w.active.insert(SpriteSlot(type: 1090, x: 400, y: 600, recordIndex: -1, layer: 1000,
                                                face: FaceRef(pict: 0x442, index: 3, set: .encoded)))
        w.active.update(id: cannon) { $0.invulnerable = 3 }
        BackgroundSprite.handle(world: w, id: cannon, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: cannon)?.invulnerable, 3)
        XCTAssertEqual(w.active.sprite(id: cannon)?.face, FaceRef(pict: 0x442, index: 3, set: .encoded))
        // `+0xe9` / `+0x1b2` → the Handle returns at once.
        w.active.update(id: id10) { $0.handleSkip = true; $0.face = nil }
        BackgroundSprite.handle(world: w, id: id10, faceWidth: Self.width)
        XCTAssertNil(w.active.sprite(id: id10)?.face)
    }

    func testPendulumL1HarmfulFrames() throws {
        // L1 records 16 and 44: 1485, mode 12 (pendulum, persp 1), r 120, g 30 (written back from 0), angles 190 / 350.
        // Harmful (`+0x170 == 1` after the frame's Handles) iff 0x60 ≤ D < 0x80. Seed 1, no keys.
        let s = try session()
        let r16 = try mace(s, record: 16), r44 = try mace(s, record: 44)
        var harm16: [Int] = [], harm44: [Int] = []
        for f in 1...150 {
            _ = s.step(keys: KeyState())
            if s.active.record(id: r16)?.classWord170 == 1 { harm16.append(f) }
            if s.active.record(id: r44)?.classWord170 == 1 { harm44.append(f) }
        }
        XCTAssertEqual(harm16, [37, 38, 39, 106, 107, 108, 109])
        XCTAssertEqual(harm44, [32, 33, 34, 35, 110, 111, 112])
    }

    func testPendulumDoubleHandleFrames() throws {
        // A layer change to 0x7ef4 during the handle pass moves the sprite to the tail: `.MTHandleSprites` reaches it
        // again the same frame (the F2 guard: an unchanged layer is no move). The pass is driven here with the
        // Background and chain Handles only — the pendulums read nothing else.
        let s = try session()
        let w = s.world
        let r16 = try mace(s, record: 16), r44 = try mace(s, record: 44)
        // The record defaults as the Setup leaves them: r 120 kept, g 0 → 30 written back.
        XCTAssertEqual([w.records[16].p2, w.records[16].p3, w.records[44].p2, w.records[44].p3], [120, 30, 120, 30])
        XCTAssertEqual([w.level.placements[16].p3, w.level.placements[44].p3], [0, 0])
        let b16 = try XCTUnwrap(w.active.sprite(id: r16)?.radial)
        XCTAssertEqual([b16.radius, Int32(b16.gravity), b16.angle, b16.speed, Int32(b16.persp)],
                       [120 << 8, 30, 190 << 8, 0, 1])
        // The spokes: 120 / 16 = 7 mace chains 0x59a per ball, made by the Setup (layer 0, faceless until their Handle).
        XCTAssertEqual(b16.spokes.count, 7)
        let chains = w.active.sprites.filter { $0.type == 0x59a }
        XCTAssertEqual(chains.count, 14)
        XCTAssertTrue(chains.allSatisfy { $0.layer == 0 && $0.face == nil && $0.handler == .chain && !$0.hasHit })

        var doubles16: [Int] = [], doubles44: [Int] = []
        for f in 1...260 {
            var n16 = 0, n44 = 0
            w.handleSprites { w, id in
                guard let r = w.active.record(id: id) else { return }
                switch r.handler {
                case .background:
                    if id == r16 { n16 += 1 }
                    if id == r44 { n44 += 1 }
                    BackgroundSprite.handle(world: w, id: id, faceWidth: Self.width)
                case .chain: ChainSprite.handle(world: w, id: id)
                default: break
                }
            }
            if n16 > 1 { doubles16.append(f) }
            if n44 > 1 { doubles44.append(f) }
            XCTAssertTrue((1...2).contains(n16) && (1...2).contains(n44))
        }
        XCTAssertEqual(doubles16, [37, 184])
        XCTAssertEqual(doubles44, [1, 110, 257])
        // The spokes after their Handle: face 0x59a, layer = scale − 0x100 (`.HandleChainSprite` l. 55990–56005),
        // rotation (`+0xb0` −90 + 90) % 360 = 0; persp 1 spoke j scale = 0xcb + (j·(2(drawScale − 0xcb)))/7.
        let ball = try XCTUnwrap(w.active.sprite(id: r16))
        let b = try XCTUnwrap(ball.radial)
        for (j, spID) in b.spokes.enumerated() {
            let c = try XCTUnwrap(w.active.sprite(id: try XCTUnwrap(spID)))
            XCTAssertEqual(c.face, FaceRef(pict: 0x59a, index: 0, set: .encoded))
            XCTAssertEqual(c.layer, Int32(c.scale) - 0x100)
            let span = Int32(Int16(truncatingIfNeeded: (Int32(b.drawScale) - 0xcb) * 2))
            XCTAssertEqual(Int32(c.scale), 0xcb + (Int32(j) * span) / 7)
            XCTAssertEqual([Int(c.rotation), Int(c.subtype)], [0, -90])
        }
        let spoke0 = try XCTUnwrap(w.active.sprite(id: try XCTUnwrap(b.spokes[0])))
        XCTAssertEqual([Int(spoke0.scale), Int(spoke0.layer)], [0xcb, 0xcb - 0x100])
    }

    func testPendulumHitCosts224And5Coins() throws {
        // The pendulum arm (`.HitPlayerSprite` l. 49583–49592): `+0x116 == 0` and `+0x170 == 1` → `.HurtPlayer(…, 0xe0,
        // blood, invul 0x3c, coins 5)`, then `+0x116 = 0x1e`.
        let (w, p) = try world()
        // The player carries 5 coins: the hit asks for 5, `.HurtPlayer` makes it FastRand(3) + 4 (seed 1: R = 2 → 6), and
        // the cap at `G+0x10` takes all 5.
        w.globals.coins = 5
        let m = try addBackground(w, Placement(index: 7, flag: 1, byte1: 0, type: 1485, p1: 12, p2: 120, p3: 30,
                                               p4: 0, y: 1000, x: 2000))
        w.active.update(id: m) { $0.classWord170 = 1 }
        w.active.update(id: p) { $0.hp = 0x230; $0.vx = 0x100; $0.vy = 0x40 }
        w.player.exertion = 7
        w.player.climb = 2
        w.player.pullUp = 3
        w.player.spin = true
        var r = w.rng
        let rate1 = Int32(r.next(10000)) + 50000, rate2 = Int32(r.next(10000)) + 65000
        let coins = r.next(3) + 5 - 1
        let rate3 = r.soundRate()
        for _ in 0..<5 { for n: Int16 in [8, 8, 0x640, 100, 0xdac] { _ = r.next(n) } }
        HitPlayerSprite.hit(w, player: p, other: m)
        let s = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual(s.hp, 0x230 - 224)
        XCTAssertEqual(s.invulnerable, 30)                                // 0x3c from `.HurtSprite`, then 0x1e
        XCTAssertEqual(w.player.coinsLost, 5)
        XCTAssertEqual(coins, 6)
        XCTAssertEqual(w.globals.coins, 0)
        XCTAssertEqual(w.rng.seed, r.seed)                                // every draw, in order
        XCTAssertEqual([s.vx, s.vy, Int32(s.flash)], [0x100, 0x40 - 1000, 0xc])   // the ball's vx is 0
        XCTAssertEqual([w.player.stun, w.player.carpetLock, w.player.exertion, w.player.climb, w.player.pullUp],
                       [1, 5, 7 + 0x50, 0, 0])
        XCTAssertFalse(w.player.spin)
        // dmg ≥ 0xe0: 450 (Reg), 508 Pitched at R + 50000 and R + 65000, then the coin 489 (3D Rand).
        let pos = SpriteSlot.Point(x: s.centre.x, y: s.centre.y)
        XCTAssertEqual(w.player.cues, [
            PlayerCue(call: .reg, snd: 450, priority: 1, volume: 0xab),
            PlayerCue(call: .regPitched, snd: 508, priority: 1, volume: 0x100, rate: rate1),
            PlayerCue(call: .regPitched, snd: 508, priority: 1, volume: 0x100, rate: rate2),
            PlayerCue(call: .threeDRand, snd: 489, priority: 1, volume: 0x100, position: pos, rate: rate3),
        ])
        XCTAssertEqual([rate1, rate2, rate3], [50000 + 2564, 65000 + 2302, 0xec77 + 475])

        // Invulnerable: no hurt, `+0x116` not re-set; harmless (`+0x170` 0): neither.
        w.player.cues = []
        w.active.update(id: p) { $0.invulnerable = 5 }
        HitPlayerSprite.hit(w, player: p, other: m)
        XCTAssertEqual(w.active.sprite(id: p)?.invulnerable, 5)
        XCTAssertEqual(w.active.sprite(id: p)?.hp, 0x230 - 224)
        w.active.update(id: p) { $0.invulnerable = 0 }
        w.active.update(id: m) { $0.classWord170 = 0 }
        HitPlayerSprite.hit(w, player: p, other: m)
        XCTAssertEqual(w.active.sprite(id: p)?.invulnerable, 0)
        XCTAssertEqual(w.player.cues, [])
        // `+0x116 = 0x1e` is set even when `.HurtPlayer` refuses (a player at HP 0: `.HurtSprite` returns 0).
        w.active.update(id: m) { $0.classWord170 = 1 }
        w.active.update(id: p) { $0.hp = 0 }
        HitPlayerSprite.hit(w, player: p, other: m)
        XCTAssertEqual([w.active.sprite(id: p)?.invulnerable, w.active.sprite(id: p)?.hp], [30, 0])
        XCTAssertEqual(w.player.cues, [])

        // One-way `+0x185` (modes 10–14) → no `.PlatformBounce`; cleared → `.PlatformBounce(player, ball, (cx − x,
        // cy − y), 0, player rect, 0)`: a player falling onto the ball lands on it.
        let (w2, p2) = try world(playerX: 2000, playerY: 1000)
        let ball = try addBackground(w2, Placement(index: 8, flag: 1, byte1: 0, type: 1485, p1: 12, p2: 120, p3: 30,
                                                   p4: 0, y: 1060, x: 1990))
        // The player's centre as `.StandardSpriteCleanup` leaves it: (2000 + 0x26 + 12, 1000 + 0x22 + 25) → d = (60, −1).
        w2.active.update(id: p2) { $0.vy = 0x300; $0.centre = SpriteSlot.Point(x: 2050, y: 1059) }
        HitPlayerSprite.hit(w2, player: p2, other: ball)
        XCTAssertNil(w2.active.sprite(id: p2)?.ridden)
        w2.active.update(id: ball) { $0.oneWay = false }
        HitPlayerSprite.hit(w2, player: p2, other: ball)
        XCTAssertEqual(w2.active.sprite(id: p2)?.ridden, ball)
        XCTAssertEqual(w2.active.sprite(id: ball)?.rider, p2)

        // `.HurtPlayer` itself (l. 47955–48105).
        let (w3, p3) = try world()
        w3.globals.coins = 1
        let atk = w3.active.insert(SpriteSlot(type: 1485, x: 0, y: 0))
        // The attacker gate: HP < 1 and not an EnemyShot / Box Handle → no hurt, no draw.
        w3.active.update(id: atk) { $0.hp = 0; $0.handler = .background; $0.vx = -0x12345 }
        w3.active.update(id: p3) { $0.hp = 0x230; $0.vx = 0; $0.vy = 0 }
        let seed0 = w3.rng.seed
        XCTAssertFalse(HurtPlayer.hurt(w3, player: p3, attacker: atk, damage: 0x70, blood: false, invulnerable: 0x3c,
                                       coins: 3))
        XCTAssertEqual([w3.active.sprite(id: p3)?.hp, Int16(w3.rng.seed == seed0 ? 1 : 0)], [0x230, 1])
        // A Box attacker at HP 0 hurts; knockback vx += (i16) attacker vx (−0x12345 → −0x2345), vy −1000, flash 0xc.
        w3.active.update(id: atk) { $0.handler = .box }
        var r3 = w3.rng
        let rate = Int32(r3.next(10000)) + 65000
        let pick = r3.next(3)
        _ = r3.next(3)
        let coinRate = r3.soundRate()
        XCTAssertTrue(HurtPlayer.hurt(w3, player: p3, attacker: atk, damage: 0xdf, blood: true, invulnerable: 0x3c,
                                      coins: 3))
        let q = try XCTUnwrap(w3.active.sprite(id: p3))
        XCTAssertEqual([Int32(q.hp), q.vx, q.vy, Int32(q.invulnerable), Int32(q.flash)],
                       [0x230 - 0xdf, -0x2345, -1000, 0x3c, 0xc])
        // dmg < 0xe0: 508 Pitched at 0x97 with R + 65000, then 401 / 402 / 403 by R(3) (0 → 401, 1 → 402, 2 → 403).
        XCTAssertEqual(w3.player.cues, [
            PlayerCue(call: .regPitched, snd: 508, priority: 1, volume: 0x97, rate: rate),
            PlayerCue(call: .reg, snd: [401, 402, 403][Int(pick)], priority: 1, volume: 0xab),
            PlayerCue(call: .threeDRand, snd: 489, priority: 1, volume: 0x100, position: SpriteSlot.Point(), rate: coinRate),
        ])
        XCTAssertEqual([rate, Int32(pick)], [65000 + 2564, 0])
        // coins 3 > 2 → R(3) + 2, capped at G+0x10 = 1: one coin, its 3D Rand cue and five draws.
        XCTAssertEqual([w3.globals.coins, w3.player.coinsLost], [0, 1])
        // A positive attacker vx pushes right; an attacker with HP ≥ 1 needs no exemption; ≤ 2 coins draw no R(3);
        // G+0x10 = 0 → no coin, no cue.
        let (w4, p4) = try world()
        let atk4 = w4.active.insert(SpriteSlot(type: 1485, x: 0, y: 0))
        w4.active.update(id: atk4) { $0.hp = 1; $0.handler = .inert; $0.vx = 0x80 }
        w4.active.update(id: p4) { $0.hp = 0x230; $0.vx = 0; $0.vy = 0 }
        w4.globals.coins = 9
        var r4 = w4.rng
        let rA = Int32(r4.next(10000)) + 50000, rB = Int32(r4.next(10000)) + 65000, rC = r4.soundRate()
        for _ in 0..<2 { for n: Int16 in [8, 8, 0x640, 100, 0xdac] { _ = r4.next(n) } }
        XCTAssertTrue(HurtPlayer.hurt(w4, player: p4, attacker: atk4, damage: 0xe0, blood: false, invulnerable: 0x10,
                                      coins: 2))
        XCTAssertEqual([w4.active.sprite(id: p4)?.vx, Int32(w4.active.sprite(id: p4)?.invulnerable ?? 0)], [0x80, 0x10])
        XCTAssertEqual([w4.globals.coins, w4.player.coinsLost], [7, 2])
        XCTAssertEqual(w4.rng.seed, r4.seed)
        XCTAssertEqual(w4.player.cues.map(\.snd), [450, 508, 508, 489])
        XCTAssertEqual(w4.player.cues.compactMap(\.rate), [rA, rB, rC])
        w4.globals.coins = 0
        w4.player.cues = []
        w4.active.update(id: p4) { $0.invulnerable = 0 }
        XCTAssertTrue(HurtPlayer.hurt(w4, player: p4, attacker: atk4, damage: 0xe0, blood: false, invulnerable: 0x3c,
                                      coins: 5))
        XCTAssertEqual(w4.player.cues.map(\.snd), [450, 508, 508])
        XCTAssertEqual([w4.globals.coins, w4.player.coinsLost], [0, 2])
        // On a magic carpet, a rising ridden sprite stops (`+0x2c < 0` → 0); a sinking one keeps its vy.
        let carpet = w4.active.insert(SpriteSlot(type: 0x438, x: 0, y: 0))
        w4.active.update(id: carpet) { $0.vy = -0x300 }
        w4.player.carpet = true
        w4.player.ridden = carpet
        w4.active.update(id: p4) { $0.invulnerable = 0 }
        HurtPlayer.hurt(w4, player: p4, attacker: atk4, damage: 0x10, blood: false, invulnerable: 1, coins: 0)
        XCTAssertEqual(w4.active.sprite(id: carpet)?.vy, 0)
        w4.active.update(id: carpet) { $0.vy = 0x300 }
        w4.active.update(id: p4) { $0.invulnerable = 0 }
        HurtPlayer.hurt(w4, player: p4, attacker: atk4, damage: 0x10, blood: false, invulnerable: 1, coins: 0)
        XCTAssertEqual(w4.active.sprite(id: carpet)?.vy, 0x300)
        // `.HurtSprite` refuses damage < 1.
        w4.active.update(id: p4) { $0.invulnerable = 0 }
        w4.player.cues = []
        XCTAssertFalse(HurtPlayer.hurt(w4, player: p4, attacker: atk4, damage: 0, blood: false, invulnerable: 1,
                                       coins: 0))
        XCTAssertEqual(w4.player.cues, [])
    }
}

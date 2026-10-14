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
        // whatever the face was; a type whose arm is not built (fire 0x4b8 — W2b ran the cannons' arm) is not run (its
        // Handle untouched: no `.StandardSpriteHandles`).
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
            // `.StandardSpriteCleanup` ran: plants have an empty rect; the tunnel has W2b's (−8, −10, 200, 150).
            XCTAssertEqual(s.centre, t == 3002 ? SpriteSlot.Point(x: 496, y: 670) : SpriteSlot.Point(x: 400, y: 600))
        }
        let fire = w.active.insert(SpriteSlot(type: 0x4b8, x: 400, y: 600, recordIndex: -1, layer: 1000,
                                              face: FaceRef(pict: 0x4b8, index: 3, set: .encoded)))
        w.active.update(id: fire) { $0.invulnerable = 3 }
        BackgroundSprite.handle(world: w, id: fire, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: fire)?.invulnerable, 3)
        XCTAssertEqual(w.active.sprite(id: fire)?.face, FaceRef(pict: 0x4b8, index: 3, set: .encoded))
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
        for _ in 0..<80 { _ = r.next(0x96) }                // E1a: `.BloodSpray`'s 40 × (vy, vx) draws, before the rates
        let rate1 = Int32(r.next(10000)) + 50000, rate2 = Int32(r.next(10000)) + 65000
        let coins = r.next(3) + 5 - 1
        let rate3 = r.soundRate()
        for _ in 0..<5 { for n: Int16 in [8, 8, 9, 6, 3, 0x3c, 0x640, 100, 0xdac] { _ = r.next(n) } }
        HitPlayerSprite.hit(w, player: p, other: m)
        let s = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual(s.hp, 0x230 - 224)
        XCTAssertEqual(s.invulnerable, 30)                                // 0x3c from `.HurtSprite`, then 0x1e
        XCTAssertEqual(w.player.coinsLost, 5)
        XCTAssertEqual(coins, 6)
        XCTAssertEqual(w.globals.coins, 0)
        // Every draw, in order — each coin's Bonus Setup (`.SetupBonusSprite` R(9) R(6) R(3), M l. 52576–52581, and
        // the tail R(0x3c), M l. 52795) between its dx and vx draws (phase-end fix; rate1–3 precede the coins). ⚑ E1a
        // (Invariant-10, revert-verified): the blood spray (`.BloodSpray`, 80 draws before the 508 rates) now draws —
        // rates were 50000 + 2564, 65000 + 2302, 0xec77 + 475.
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.particles.counters, ParticlePool.Counters(count: 40, hint: 39, highWater: 39))
        XCTAssertEqual(Set(w.particles.records.prefix(40).map(\.kind)), [2])
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
        XCTAssertEqual([rate1, rate2, rate3], [50000 + 9172, 65000 + 9726, 0xec77 + 3032])
        // Uncapped (`G+0x10` = 9): the arm's coins 5 → FastRand(3) + 5 − 1 = 2 + 4 = 6 lost, 3 left.
        let (wG, pG) = try world()
        wG.globals.coins = 9
        let mG = try addBackground(wG, Placement(index: 7, flag: 1, byte1: 0, type: 1485, p1: 12, p2: 120, p3: 30,
                                                 p4: 0, y: 1000, x: 2000))
        wG.active.update(id: mG) { $0.classWord170 = 1 }
        wG.active.update(id: pG) { $0.hp = 0x230 }
        HitPlayerSprite.hit(wG, player: pG, other: mG)
        XCTAssertEqual([wG.player.coinsLost, wG.globals.coins], [6, 3])

        // Invulnerable: no hurt, `+0x116` not re-set; harmless (`+0x170` 0): neither.
        w.player.cues = []
        w.active.update(id: p) { $0.invulnerable = 5 }
        HitPlayerSprite.hit(w, player: p, other: m)
        XCTAssertEqual(w.active.sprite(id: p)?.invulnerable, 5)
        XCTAssertEqual(w.active.sprite(id: p)?.hp, 0x230 - 224)
        w.active.update(id: p) { $0.invulnerable = 0 }
        // An idled pendulum (`+0x4c` 0, `handleCleared`) matches no arm's Handle: harmful or not, no hurt.
        w.active.update(id: m) { $0.handleCleared = true }
        let seedIdled = w.rng.seed
        HitPlayerSprite.hit(w, player: p, other: m)
        XCTAssertEqual([w.active.sprite(id: p)?.hp, w.active.sprite(id: p)?.invulnerable], [0x230 - 224, 0])
        XCTAssertEqual(w.player.cues, [])
        XCTAssertEqual(w.rng.seed, seedIdled)
        w.active.update(id: m) { $0.handleCleared = false }
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
        // Landed on the top: y = solid top (1060 + 0x16) − rect bottom 85 = 997, vy 0.
        XCTAssertEqual([w2.active.sprite(id: p2)?.y, w2.active.sprite(id: p2).map { Int($0.vy) }], [997, 0])
        // d decides the side (`.RectBounce` l. 36196–36442: the previous centre `pos + d − (v >> 8)` against the solid's
        // centre lines (2040, 1110); gaps from the previous rect). One pixel either side of each line, vx 0, vy 0x300:
        // - player (1990, 1010): gapAbove −10 ≥ gapLeft −41 > gapBelow −97 — prevMidY = cy − 53: 1109 lands on the top
        //   (y 997, vy 0, ridden), 1110 is from the left (x 2012 − 62 = 1950, y and vy kept);
        // - player (1990, 1051): gapAbove −51 < gapLeft = gapRight −41 — prevMidX = cx: 2039 from the left (x 1950),
        //   2040 from the right (x 2068 − 38 = 2030).
        func bounce(_ x: Int, _ y: Int, centre cx: Int, _ cy: Int) throws -> [Int] {
            w2.active.update(id: p2) {
                $0.x = x; $0.y = y; $0.x256 = Int32(x) << 8; $0.y256 = Int32(y) << 8; $0.vx = 0; $0.vy = 0x300
                $0.centre = SpriteSlot.Point(x: cx, y: cy); $0.ridden = nil
            }
            HitPlayerSprite.hit(w2, player: p2, other: ball)
            let q = try XCTUnwrap(w2.active.sprite(id: p2))
            return [q.x, q.y, Int(q.vy), q.ridden == ball ? 1 : 0]
        }
        XCTAssertEqual(try bounce(1990, 1010, centre: 2000, 1162), [1990, 997, 0, 1])
        XCTAssertEqual(try bounce(1990, 1010, centre: 2000, 1163), [1950, 1010, 0x300, 0])
        XCTAssertEqual(try bounce(1990, 1051, centre: 2039, 1100), [1950, 1051, 0x300, 0])
        XCTAssertEqual(try bounce(1990, 1051, centre: 2040, 1100), [2030, 1051, 0x300, 0])

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
        // coins 3 > 2 → R(3) + 2, capped at G+0x10 = 1: one coin, its 3D Rand cue and nine draws.
        XCTAssertEqual([w3.globals.coins, w3.player.coinsLost], [0, 1])
        // Invulnerable (`+0x116` 5): `.HurtSprite` refuses → 0, the player untouched (no knockback, stun, coin, cue).
        w3.active.update(id: p3) { $0.invulnerable = 5 }
        w3.globals.coins = 4
        let before = (try XCTUnwrap(w3.active.sprite(id: p3)), w3.player, w3.globals, w3.rng.seed)
        XCTAssertFalse(HurtPlayer.hurt(w3, player: p3, attacker: atk, damage: 0x70, blood: true, invulnerable: 0x3c,
                                       coins: 5))
        XCTAssertEqual(w3.active.sprite(id: p3), before.0)
        XCTAssertEqual(w3.player, before.1)
        XCTAssertEqual(w3.globals, before.2)
        XCTAssertEqual(w3.rng.seed, before.3)
        // The R(3) choice on seeds 2 and 3 (R(10000) then R(3): 5129, 1 / 7693, 2) → 402 / 403.
        for (seed, snd): (Int32, Int16) in [(2, 402), (3, 403)] {
            let (w5, p5) = try world()
            let a5 = w5.active.insert(SpriteSlot(type: 1485, x: 0, y: 0))
            w5.active.update(id: a5) { $0.hp = 1 }
            w5.active.update(id: p5) { $0.hp = 0x230 }
            w5.rng.seed = seed
            XCTAssertTrue(HurtPlayer.hurt(w5, player: p5, attacker: a5, damage: 0x70, blood: false, invulnerable: 1,
                                          coins: 0))
            XCTAssertEqual(w5.player.cues.map(\.snd), [508, snd])
        }
        // A positive attacker vx pushes right; an attacker with HP ≥ 1 needs no exemption; ≤ 2 coins draw no R(3);
        // G+0x10 = 0 → no coin, no cue.
        let (w4, p4) = try world()
        let atk4 = w4.active.insert(SpriteSlot(type: 1485, x: 0, y: 0))
        w4.active.update(id: atk4) { $0.hp = 1; $0.handler = .inert; $0.vx = 0x80 }
        w4.active.update(id: p4) { $0.hp = 0x230; $0.vx = 0; $0.vy = 0 }
        w4.globals.coins = 9
        var r4 = w4.rng
        let rA = Int32(r4.next(10000)) + 50000, rB = Int32(r4.next(10000)) + 65000, rC = r4.soundRate()
        for _ in 0..<2 { for n: Int16 in [8, 8, 9, 6, 3, 0x3c, 0x640, 100, 0xdac] { _ = r4.next(n) } }
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

    // MARK: - W2b: cannons, wall tunnels, passages, springs

    private typealias Rect = IdleSprites.Rect

    private func placement(_ index: Int, _ type: Int16, p1: Int16 = 0, p2: Int16 = 0, p3: Int16 = 0, x: Int16,
                           y: Int16) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: type, p1: p1, p2: p2, p3: p3, p4: 0, y: y, x: x)
    }

    func testCoinLossDrawsTheBonusSetupPerCoin() throws {
        // `.HurtPlayer`'s coin loop (M l. 48088–48104): per coin R(8) dy, R(8) dx, `MTNewSprite(0x516, …,
        // .SetupBonusSprite)` — whose arm `LAB_1005e02c` draws R(9) `+0x46`, R(6) `+0x112`, R(3) `+0x114` (M l.
        // 52576–52581, raw `1005e050..1005e078`) and the shared tail R(0x3c) `+0x14c` (`LAB_1005e8bc`, M l. 52795, raw
        // `1005e8bc`) — then R(0x640) vx, R(100) sign, R(0xdac) vy: nine draws per coin. The sprite itself is Phase 4.
        for lost in [Int16(1), 2] {
            let (w, p) = try world()
            let atk = w.active.insert(SpriteSlot(type: 1485, x: 0, y: 0))
            w.active.update(id: atk) { $0.hp = 1 }
            w.active.update(id: p) { $0.hp = 0x230 }
            w.globals.coins = lost
            var r = w.rng
            _ = r.next(10000)                                   // 508's rate (damage < 0xe0)
            _ = r.next(3)                                       // 401 / 402 / 403
            _ = r.soundRate()                                   // 489 (3D Rand); coins ≤ 2 → no R(3) on n
            var draws = 0
            for _ in 0..<lost {
                for n: Int16 in [8, 8, 9, 6, 3, 0x3c, 0x640, 100, 0xdac] {
                    _ = r.next(n)
                    draws += 1
                }
            }
            XCTAssertEqual(draws, 9 * Int(lost))
            XCTAssertTrue(HurtPlayer.hurt(w, player: p, attacker: atk, damage: 0x70, blood: false, invulnerable: 1,
                                          coins: lost))
            XCTAssertEqual([w.globals.coins, w.player.coinsLost], [0, lost])
            XCTAssertEqual(w.rng.seed, r.seed, "coins \(lost)")
        }
    }

    func testCannonP0LaunchUp() throws {
        // `.SetupBackgroundSprite` cannon arm (l. 62057–62184) on L1 record 41: 1090, p1 0, at (4117, 560).
        let (w, p) = try world(playerX: 4100, playerY: 540)
        let rec = w.level.placements[41]
        XCTAssertEqual([Int(rec.type), Int(rec.p1), Int(rec.x), Int(rec.y)], [1090, 0, 4117, 560])
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        let e = try SetupFaces.setup(rec, context: c)
        let k0 = e.slot
        XCTAssertEqual(e.spawn, .idle)
        XCTAssertEqual(e.record, rec)                                     // no write-back
        // aim 0, layer 1000, home (4117, 560), `+0x154` 0, S = 9000 (M l. 62114), dry (`+0x16c` 0).
        XCTAssertEqual([Int(k0.phase), Int(k0.layer), Int(k0.classTimer), Int(k0.classWord150), Int(k0.classWord154),
                        Int(k0.launchSpeed), Int(k0.classWord16c), Int(k0.counterA6), Int(k0.hp)],
                       [0, 1000, 4117, 560, 0, 9000, 0, 3, 6])
        XCTAssertEqual(k0.hotRect, Rect(top: 0x38, left: 0x35, bottom: 0x5b, right: 0x61))
        XCTAssertEqual([k0.hasHit, k0.hasTileHit], [true, false])
        XCTAssertEqual(k0.handler, .background)
        XCTAssertEqual([k0.x256, k0.y256], [4117 << 8, 560 << 8])
        // On a water BG cell (`.IsWaterTile` 200…209): `+0x16c` 1 — L1 cell (188, 17) is kind 201.
        XCTAssertEqual(w.level.bgKind(tile: w.level.bgTile(col: 188, row: 17)), 201)
        XCTAssertEqual(try SetupFaces.setup(placement(1, 1090, x: 188 * 32, y: 17 * 32), context: c).slot.classWord16c, 1)
        // Aim `(type − 0x442)·4` for every cannon type; p1 ≠ 0 (path, rotating) is not built.
        for t: Int16 in 1090...1098 {
            let a = try SetupFaces.setup(placement(1, t, x: 400, y: 400), context: c)
            XCTAssertEqual(Int(a.slot.phase), (Int(t) - 1090) * 4)
        }
        for p1: Int16 in [-1, -2, 1, 101, 105, 106, 107] {
            XCTAssertThrowsError(try SetupFaces.setup(placement(1, 1090, p1: p1, x: 400, y: 400), context: c)) {
                XCTAssertEqual($0 as? SetupFaces.Error, .notTranscribed(type: 1090))
            }
        }

        let k = w.active.insert(k0)
        // The Handle (l. 62944–63069): aim 0 → face 0x442[0], not mirrored, rotation 0, `+0xb8` 0, `+0x88` 0; the
        // centre (4117 + 0x35 + 22, 560 + 0x38 + 17).
        w.active.update(id: k) { $0.mode = 7; $0.rotation = 9; $0.mirrored = true }
        BackgroundSprite.handle(world: w, id: k, faceWidth: Self.width)
        var ks = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual(ks.face, FaceRef(pict: 0x442, index: 0, set: .encoded))
        XCTAssertEqual([ks.centre.x, ks.centre.y, Int(ks.rotation), Int(ks.mode)], [4192, 633, 0, 0])
        XCTAssertEqual([ks.mirrored, ks.lightOverlay], [false, false])
        XCTAssertEqual([ks.x, ks.y, Int(ks.waterRow)], [4117, 560, 0])            // at home: no ease; dry
        // The aim → face / mirror / rotation (mod 4 == 0: face aim / 4, ≥ 5 mirrored 8 − k; else face 0 rotated by
        // 2·(((0x20 − aim)·0xb4 / 16) / 2) of the raw aim — the fold 0x21 − aim from 0x12 on only sets the mirror
        // (raw `10073fc8` reloads `+0x46`); the aim wrapped to 0…31).
        func aim(_ a: Int16) throws -> [Int] {
            w.active.update(id: k) { $0.phase = a }
            BackgroundSprite.handle(world: w, id: k, faceWidth: Self.width)
            let q = try XCTUnwrap(w.active.sprite(id: k))
            return [Int(q.phase), try XCTUnwrap(q.face).index, q.mirrored ? 1 : 0, Int(q.rotation)]
        }
        XCTAssertEqual(try aim(4), [4, 1, 0, 0])
        XCTAssertEqual(try aim(16), [16, 4, 0, 0])
        XCTAssertEqual(try aim(20), [20, 3, 1, 0])
        XCTAssertEqual(try aim(28), [28, 1, 1, 0])
        XCTAssertEqual(try aim(2), [2, 0, 0, 336])                         // (30·180 / 16) / 2 = 168
        XCTAssertEqual(try aim(0x13), [0x13, 0, 0, 146])                   // raw 19: (13·180 / 16) / 2 = 73
        XCTAssertEqual(try aim(-3), [29, 0, 0, 32])                        // 29: (3·180 / 16) / 2 = 16
        XCTAssertEqual(try aim(0x22), [2, 0, 0, 336])
        XCTAssertEqual(try aim(0x11), [0x11, 0, 0, 168])                   // < 0x12, not folded: (15·180 / 16) / 2 = 84
        w.active.update(id: k) { $0.phase = 0 }
        BackgroundSprite.handle(world: w, id: k, faceWidth: Self.width)
        // Submerged (`+0x16c` 1): `+0x120 = +0x11c = 1` after `.StandardSpriteHandles`.
        w.active.update(id: k) { $0.classWord16c = 1 }
        BackgroundSprite.handle(world: w, id: k, faceWidth: Self.width)
        XCTAssertEqual([Int(try XCTUnwrap(w.active.sprite(id: k)).waterRow),
                        Int(try XCTUnwrap(w.active.sprite(id: k)).lastWater)], [1, 1])
        w.active.update(id: k) { $0.classWord16c = 0; $0.waterRow = 0; $0.lastWater = 0 }

        // The capture: `.HitBackgroundSprite` → `.TurnIntoCannoned(player, cannon)` (M l. 49930): 484 (3D Rand, vol
        // 0x97, at the player's centre before the move), the Handles saved, `+0x130` 15, v 0, pinned at the cannon's
        // centre − (50, 59), launched; the cannon's `+0x154` = 6.
        w.active.update(id: p) { s in
            s.hp = 0x230; s.vx = 0x123; s.vy = 0x456; s.hasTileHit = true
            s.centre = SpriteSlot.Point(x: 4150, y: 599)
        }
        var r = w.rng
        let rate484 = r.soundRate()
        BackgroundSprite.hit(w, id: k, other: p)
        var q = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual(q.handler, .cannoned)
        XCTAssertEqual(q.savedHandler, .player)
        XCTAssertEqual([q.savedHasHit, q.savedHasTileHit, q.hasHit, q.hasTileHit], [false, true, false, false])
        XCTAssertEqual([Int(q.reentry), Int(q.vx), Int(q.vy), q.x, q.y, q.centre.x, q.centre.y],
                       [15, 0, 0, 4142, 574, 4192, 633])
        XCTAssertEqual([q.x256, q.y256], [4142 << 8, 574 << 8])
        XCTAssertEqual(q.cannon, k)
        XCTAssertTrue(w.player.launched)
        XCTAssertEqual(w.active.sprite(id: k)?.classWord154, 6)
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 484, priority: 1, volume: 0x97,
                                                 position: SpriteSlot.Point(x: 4150, y: 599), rate: rate484)])
        XCTAssertEqual(w.rng.seed, r.seed)
        // The player pass reaches the cannon's callback again the same frame: the captive's Handle is now the Cannoned
        // one (excluded) — nothing, no draw.
        BackgroundSprite.hit(w, id: k, other: p)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.player.cues.count, 1)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).reentry, 15)

        // `.HandleCannonedSprite` (M l. 49976): 14 hold frames — `+0x130` 14 … 1, face 0, v 0, `+0x80` 2, pinned.
        w.player.cues = []
        w.player.flag05a0 = false
        for f in 1...14 {
            BackgroundSprite.handleCannoned(world: w, id: p, keys: [])
            q = try XCTUnwrap(w.active.sprite(id: p))
            XCTAssertEqual([Int(q.reentry), Int(q.vx), Int(q.vy), Int(q.layer), q.x, q.y], [15 - f, 0, 0, 2, 4142, 574])
            XCTAssertNil(q.face)
            XCTAssertEqual(q.handler, .cannoned)
        }
        XCTAssertEqual([w.player.flag05a0 ? 1 : 0, Int(w.player.centreX), Int(w.player.centreY)], [1, 4192, 633])
        XCTAssertEqual(w.player.cues, [])
        // Frame 15 fires (aim 0 mod 4 == 0): the three smokes' draws (each Setup's 45 × (R(2000), R(2000), R(2)), then
        // R(2) mirror, R(4) phase; R(8) dy, R(8) dx before the 2nd and the 3rd), then 483's rate.
        var r2 = w.rng
        var mirror: [Int16] = [], phase: [Int16] = [], d: [Int16] = []
        for n in 0..<3 {
            if n > 0 { d.append(r2.next(8)); d.append(r2.next(8)) }
            for _ in 0..<45 { _ = r2.next(2000); _ = r2.next(2000); _ = r2.next(2) }
            mirror.append(r2.next(2))
            phase.append(r2.next(4))
        }
        let rate483 = r2.soundRate()
        let before = Set(w.active.sprites.map(\.id))
        // The launch resets (l. 50190–50197): launched 1; swim, spin, climb 0 (`_DAT_100a0714`, `0668`, `0758`).
        w.player.launched = false
        w.player.swim = 3
        w.player.spin = true
        w.player.climb = 2
        BackgroundSprite.handleCannoned(world: w, id: p, keys: [])
        XCTAssertEqual(w.rng.seed, r2.seed)
        q = try XCTUnwrap(w.active.sprite(id: p))
        // v (0, −9000) (aim 0: vy = −S); `+0x130` −5; the Handles restored; position += v: y256 574·256 − 9000.
        XCTAssertEqual([Int(q.vx), Int(q.vy), Int(q.reentry)], [0, -9000, -5])
        XCTAssertEqual(q.handler, .player)
        XCTAssertEqual([q.hasHit, q.hasTileHit], [false, true])
        XCTAssertEqual([q.x256, q.y256], [4142 << 8, (574 << 8) - 9000])
        XCTAssertEqual([q.x, q.y, q.oldPosition.x, q.oldPosition.y, q.centre.x, q.centre.y],
                       [4142, 538, 4142, 538, 4192, 597])
        XCTAssertEqual([Int(w.player.pixelX), Int(w.player.pixelY), Int(w.player.centreX), Int(w.player.centreY)],
                       [4142, 538, 4192, 597])
        XCTAssertTrue(w.player.launched)                                  // `_DAT_100a05b8 = 1`
        XCTAssertEqual([Int(w.player.swim), w.player.spin ? 1 : 0, Int(w.player.climb)], [0, 0, 0])
        XCTAssertEqual(q.face, FaceRef(pict: 1015, index: Int(w.player.tumbleFrame), set: .encoded))
        XCTAssertEqual(w.player.cues, [PlayerCue(call: .threeDRand, snd: 483, priority: 1, volume: 0x100,
                                                 position: SpriteSlot.Point(x: 4192, y: 633), rate: rate483)])
        // The smokes: Effect 0x442 at ((int)(1.5·0/256 + 4192 − 24), (int)(1.5·−9000/256 + 633 − 24)) = (4168, 556),
        // then (−dx, −dy) and (+dx, +dy) of their own draws; layer 0x7fbc (the Setup's), no face until their Handle.
        let smokes = w.active.sprites.filter { !before.contains($0.id) }
        XCTAssertEqual(smokes.count, 3)
        XCTAssertTrue(smokes.allSatisfy { $0.type == 0x442 && $0.handler == .effect && $0.layer == 0x7fbc
                                          && $0.face == nil && $0.hasHit && $0.light == -1 })
        let byPos = smokes.map { [$0.x, $0.y] }
        XCTAssertEqual(Set(byPos), Set([[4168, 556], [4168 - Int(d[1]), 556 - Int(d[0])],
                                         [4168 + Int(d[3]), 556 + Int(d[2])]]))
        XCTAssertEqual(Set(smokes.map { [$0.mirrored ? 1 : 0, Int($0.phase)] }),
                       Set((0..<3).map { [Int(mirror[$0]), Int(phase[$0])] }))
        // The smoke's Handle: `+0xb8` 0x10005, `+0x46` += 1, face 0x4b0[`+0x46` >> 1] below 0x1a, then killed.
        let sm = try XCTUnwrap(smokes.first { $0.x == 4168 && $0.y == 556 }).id
        EffectSprite.handle(world: w, id: sm)
        let smq = try XCTUnwrap(w.active.sprite(id: sm))
        XCTAssertEqual([Int(smq.mode), Int(smq.phase)], [0x10005, Int(phase[0]) + 1])
        XCTAssertEqual(smq.face, FaceRef(pict: 0x4b0, index: Int(phase[0] + 1) >> 1, set: .encoded))
        var life = 1
        while w.active.sprite(id: sm)?.dead == false { EffectSprite.handle(world: w, id: sm); life += 1 }
        XCTAssertEqual(life, 0x1a - Int(phase[0]))
        XCTAssertNil(w.active.sprite(id: sm)?.face)
        // The recoil (cannon p1 ≥ 0): pos = (int)−(1.6·v − pos) → y256 + 14400; then the ease home (0.8·pos + 0.2·home)
        // every Handle while the pixel position is off home: y 616 → 605 → 596 … 560, then still.
        ks = try XCTUnwrap(w.active.sprite(id: k))
        XCTAssertEqual([ks.x256, ks.y256, Int32(ks.x), Int32(ks.y)], [4117 << 8, (560 << 8) + 14400, 4117, 616])
        var ys: [Int] = []
        for _ in 0..<30 {
            BackgroundSprite.handle(world: w, id: k, faceWidth: Self.width)
            ys.append(try XCTUnwrap(w.active.sprite(id: k)).y)
        }
        XCTAssertEqual(Array(ys.prefix(3)), [605, 596, 588])
        XCTAssertEqual(ys.last, 560)
        let settled = try XCTUnwrap(w.active.sprite(id: k)).y256
        XCTAssertEqual(settled >> 8, 560)
        BackgroundSprite.handle(world: w, id: k, faceWidth: Self.width)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: k)).y256, settled)    // at home: untouched
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: k)).x256, 4117 << 8)

        // Re-entry: `+0x130` < 0 refuses the capture; `.StandardSpriteHandles` counts it up, 0 is capturable.
        w.player.cues = []
        BackgroundSprite.hit(w, id: k, other: p)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).handler, .player)
        for _ in 0..<5 { w.standardSpriteHandles(p) }
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).reentry, 0)
        BackgroundSprite.hit(w, id: k, other: p)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).handler, .cannoned)

        // The launch vectors for S = 9000 by aim / 4 (fctiwz of each rounded double product; 0.707·9000 rounds to 6363).
        XCTAssertEqual((0...8).map { o -> [Int32] in
            let v = BackgroundSprite.launchVector(octant: Int32(o), speed: 9000); return [v.vx, v.vy] },
                       [[0, -9000], [6363, -6363], [9000, -2115], [7200, 3150], [0, 9000], [-7200, 3150],
                        [-9000, -2115], [-6363, -6363], [0, 0]])

        // A non-player captive in a downward cannon (1094, aim 16): `+0x130` −35, position += (0, 9000), stored v
        // ((int)(0·0.7), (int)(9000·0.55)) = (0, 4950); no launched flag, no face.
        let (w2, p2) = try world(playerX: 100, playerY: 100)
        let k2 = w2.active.insert(try SetupFaces.setup(placement(41, 1094, x: 1000, y: 600), context: c).slot)
        BackgroundSprite.handle(world: w2, id: k2, faceWidth: Self.width)
        let walker = w2.active.insert(SpriteSlot(type: 0x6a4, x: 1000, y: 600))
        w2.active.update(id: walker) { $0.hp = 5; $0.centre = SpriteSlot.Point(x: 1010, y: 620) }
        BackgroundSprite.hit(w2, id: k2, other: walker)
        XCTAssertEqual(w2.active.sprite(id: walker)?.handler, .cannoned)
        XCTAssertFalse(w2.player.launched)
        // Aim not a multiple of 4 (18: even, not mod 4): held past 0 (no fire).
        w2.active.update(id: k2) { $0.phase = 18 }
        for _ in 0..<17 { BackgroundSprite.handleCannoned(world: w2, id: walker, keys: []) }
        XCTAssertEqual([Int(try XCTUnwrap(w2.active.sprite(id: walker)).reentry)], [-2])
        XCTAssertEqual(w2.active.sprite(id: walker)?.handler, .cannoned)
        w2.active.update(id: k2) { $0.phase = 16 }
        let wy = try XCTUnwrap(w2.active.sprite(id: walker)).y256
        BackgroundSprite.handleCannoned(world: w2, id: walker, keys: [])
        let wq = try XCTUnwrap(w2.active.sprite(id: walker))
        XCTAssertEqual([Int(wq.reentry), Int(wq.vx), Int(wq.vy), Int(wq.y256 - wy)], [-0x23, 0, 4950, 9000])
        XCTAssertEqual(wq.handler, .inert)
        XCTAssertNil(wq.face)
        XCTAssertFalse(w2.player.launched)
        XCTAssertEqual(w2.player.cues.map(\.snd), [484, 483])
        // A type-0x5a captive fired at aim 12 (octant 3, (7200, 3150)): `+0x110` gravity 0x15e (l. 50168); vy > 0 →
        // stored v ((int)(7200·0.7), (int)(3150·0.55)) = (5040, 1732).
        let bat = w2.active.insert(SpriteSlot(type: 0x5a, x: 1000, y: 600))
        w2.active.update(id: bat) { $0.hp = 5; $0.gravity = 7 }
        BackgroundSprite.hit(w2, id: k2, other: bat)
        XCTAssertEqual(w2.active.sprite(id: bat)?.handler, .cannoned)
        w2.active.update(id: k2) { $0.phase = 12 }
        for _ in 0..<15 { BackgroundSprite.handleCannoned(world: w2, id: bat, keys: []) }
        let bq = try XCTUnwrap(w2.active.sprite(id: bat))
        XCTAssertEqual([Int(bq.vx), Int(bq.vy), Int(bq.gravity)], [5040, 1732, 0x15e])
        _ = p2

        // Not captured: an Effect, a Background (a mace), the types 0x41f / 0x434 / 0x771 / 0x772 / 0xb7c / 0x5c3 /
        // 0x5c4, a Button, `+0x130` < 0, a dead player (HP < 1) — no cue, no draw.
        let (w3, p3) = try world(playerX: 100, playerY: 100)
        let k3 = w3.active.insert(try SetupFaces.setup(placement(41, 1090, x: 1000, y: 600), context: c).slot)
        func refused(_ slot: SpriteSlot, _ body: (inout SpriteSlot) -> Void = { _ in }) -> Bool {
            let id = w3.active.insert(slot)
            w3.active.update(id: id, body)
            let seed = w3.rng.seed
            BackgroundSprite.hit(w3, id: k3, other: id)
            return w3.active.sprite(id: id)?.handler != .cannoned && w3.rng.seed == seed
        }
        var fx = SpriteSlot(type: 0x4b1, x: 1000, y: 600)
        fx.handler = .effect
        XCTAssertTrue(refused(fx))
        XCTAssertTrue(refused(SpriteSlot(type: 1485, x: 1000, y: 600)))
        for t: Int16 in [0x41f, 0x434, 0x771, 0x772, 0xb7c, 0x5c3, 0x5c4] {
            var s = SpriteSlot(type: t, x: 1000, y: 600)
            s.handler = .inert
            XCTAssertTrue(refused(s), "type \(t)")
        }
        XCTAssertTrue(refused(SpriteSlot(type: 1320, x: 1000, y: 600)))  // a Button (inert)
        XCTAssertFalse(refused(SpriteSlot(type: 0x6a4, x: 1000, y: 600)))  // a walker (inert): captured
        XCTAssertTrue(refused(SpriteSlot(type: 0x6a4, x: 1000, y: 600)) { $0.reentry = -1 })
        // An idled record (`+0x4c` 0) is none of the excluded Handles: captured, its Handle 0 saved (and restored).
        let idledID = w3.active.insert(SpriteSlot(type: 1485, x: 1000, y: 600))
        w3.active.update(id: idledID) { $0.handleCleared = true }
        BackgroundSprite.hit(w3, id: k3, other: idledID)
        let idled = try XCTUnwrap(w3.active.sprite(id: idledID))
        XCTAssertEqual(idled.handler, .cannoned)
        XCTAssertEqual([idled.handleCleared, idled.savedHandleCleared], [false, true])
        // Fired (aim 0, 15 Cannoned Handles): `+0x4c` restored to the saved 0 — idled again, the Background handler kept.
        for _ in 0..<15 { BackgroundSprite.handleCannoned(world: w3, id: idledID, keys: []) }
        let fired = try XCTUnwrap(w3.active.sprite(id: idledID))
        XCTAssertEqual([Int(fired.reentry), Int(fired.vy)], [-0x23, -9000])
        XCTAssertTrue(fired.handleCleared)
        XCTAssertEqual(fired.handler, .background)
        w3.active.update(id: p3) { $0.hp = 0 }
        let seed3 = w3.rng.seed
        BackgroundSprite.hit(w3, id: k3, other: p3)
        XCTAssertEqual(w3.active.sprite(id: p3)?.handler, .player)
        XCTAssertEqual(w3.rng.seed, seed3)

        // The player in a path cannon (record p1 < 0): below 2 the hold steps only while JUMP is held; no recoil.
        let (w4, p4) = try world(playerX: 100, playerY: 100)
        let k4 = w4.active.insert(try SetupFaces.setup(placement(41, 1090, x: 1000, y: 600), context: c).slot)
        w4.records[41] = placement(41, 1090, p1: -1, x: 1000, y: 600)
        BackgroundSprite.handle(world: w4, id: k4, faceWidth: Self.width)
        w4.active.update(id: p4) { $0.hp = 0x230 }
        BackgroundSprite.hit(w4, id: k4, other: p4)
        for _ in 0..<14 { BackgroundSprite.handleCannoned(world: w4, id: p4, keys: []) }
        XCTAssertEqual(w4.active.sprite(id: p4)?.reentry, 1)
        for _ in 0..<3 { BackgroundSprite.handleCannoned(world: w4, id: p4, keys: []) }
        XCTAssertEqual(w4.active.sprite(id: p4)?.reentry, 1)
        let ky = try XCTUnwrap(w4.active.sprite(id: k4)).y256
        BackgroundSprite.handleCannoned(world: w4, id: p4, keys: [.jump])
        XCTAssertEqual([Int(try XCTUnwrap(w4.active.sprite(id: p4)).vy), Int(try XCTUnwrap(w4.active.sprite(id: p4)).reentry)],
                       [-9000, -5])
        XCTAssertEqual(try XCTUnwrap(w4.active.sprite(id: k4)).y256, ky)  // no recoil

        // In a level-1 session: the player captured by the L1 cannon (record 41) is handled by `.HandleCannonedSprite`
        // through `.MTHandleSprites` — held 14 iterations, launched on the 15th (v (0, −9000), `+0x130` −5).
        let s5 = try session()
        let sw = s5.world
        _ = s5.step(keys: KeyState())
        var cs = try SetupFaces.setup(sw.records[41], context: SetupFaces.Context(level: sw.level, playerX: 0)).slot
        cs.recordIndex = 41
        let k5 = sw.active.insert(cs)
        BackgroundSprite.hit(sw, id: k5, other: s5.playerID)
        XCTAssertEqual(sw.active.sprite(id: s5.playerID)?.handler, .cannoned)
        for n in 1...15 {
            _ = s5.step(keys: KeyState())
            let pq = try XCTUnwrap(sw.active.sprite(id: s5.playerID))
            if n < 15 {
                XCTAssertEqual([Int(pq.reentry), Int(pq.vy)], [15 - n, 0], "step \(n)")
            } else {
                XCTAssertEqual([Int(pq.reentry), Int(pq.vy)], [-5, -9000])
                XCTAssertEqual(pq.handler, .player)
            }
        }
    }

    func testWallTunnelWindowL1() throws {
        // L1 record 56: the wall tunnel 3002 at (4403, 1065) (`.SetupBackgroundSprite` l. 62620–62627).
        let (w, p) = try world(playerX: 4450, playerY: 1100)
        let rec = w.level.placements[56]
        XCTAssertEqual([Int(rec.type), Int(rec.x), Int(rec.y)], [3002, 4403, 1065])
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        let e = try SetupFaces.setup(rec, context: c)
        XCTAssertEqual(e.slot.hotRect, Rect(top: -10, left: -8, bottom: 0x96, right: 0x88 + 2 * 0x20))
        XCTAssertEqual([Int(e.slot.layer), e.slot.hasHit ? 1 : 0], [0, 1])
        XCTAssertEqual(e.source, .setupCached)
        XCTAssertEqual(e.slot.face, FaceRef(pict: 3002, index: 0, set: .encoded))
        XCTAssertEqual(e.record, rec)
        let t = w.active.insert(e.slot)
        // `.HitBackgroundSprite` (M l. 63730–63740): any hitter whose Handle is not the Background's gets
        // (x + rect.left + 0x2e, x + rect.right − 0x2f, y + rect.top − 0x2c, y + rect.bottom + 0x27).
        BackgroundSprite.hit(w, id: t, other: p)
        let window = SpriteSlot.Occluder(left: 4441, right: 4556, bottom: 1254, top: 1011)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).occluder, window)
        // Through the collision pass and the session's hit dispatch, from the default occluder.
        w.active.update(id: p) { $0.occluder = SpriteSlot.Occluder() }
        w.collideSprites(FerazelSession.hitCallback)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).occluder, window)
        // Never reset: `.StandardSpriteHandles` and `.StandardSpriteCleanup` keep it; the clip reads it — x 4450, no face
        // (w 0x80): 4450 + 64 ≥ the middle 4498 → left skip `+0x1b6` = 4556 − 4450; at x 4400 → `+0x1b8` = 4441 − 4400.
        w.standardSpriteHandles(p)
        w.standardSpriteCleanup(p, faceWidth: Self.width)
        var q = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual(q.occluder, window)
        XCTAssertEqual([q.clip.left, q.clip.right], [106, 32000])
        w.active.update(id: p) { $0.x = 4400 }
        w.standardSpriteHandles(p)
        w.standardSpriteCleanup(p, faceWidth: Self.width)
        q = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual([q.clip.left, q.clip.right], [0, 41])
        // Moved out of the window, it stays (and the clip no longer applies): the tunnel never clears it.
        w.active.update(id: p) { $0.x = 100 }
        w.standardSpriteHandles(p)
        w.standardSpriteCleanup(p, faceWidth: Self.width)
        q = try XCTUnwrap(w.active.sprite(id: p))
        XCTAssertEqual(q.occluder, window)
        XCTAssertEqual([q.clip.left, q.clip.right], [0, 32000])
        // Both window edges move with the tunnel's 24.8 position (not `+0xc`) and its rect's width (3000 / 3009; their
        // faces are not in the level-1 table, so the arm is called directly).
        let edges: [(Int16, Int16)] = [(3000, 4492), (3009, 4780)]       // x + 0x88 − 0x2f, x + 0x88 + 9·0x20 − 0x2f
        for (type, right) in edges {
            var slot = SpriteSlot(type: type, x: 0, y: 0)
            slot.x256 = 4403 << 8
            slot.y256 = 1065 << 8
            BackgroundSprite.setupTunnel(&slot)
            XCTAssertEqual([slot.hotRect.right, Int(slot.layer), slot.hasHit ? 1 : 0], [Int(right) - 4403 + 0x2f, 0, 1])
            let id = w.active.insert(slot)
            BackgroundSprite.hit(w, id: id, other: p)
            XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: p)).occluder,
                           SpriteSlot.Occluder(left: 4441, right: right, bottom: 1254, top: 1011))
        }
        // A Background hitter (a mace) is not occluded; an idled one (`+0x4c` 0) is.
        let m = try addBackground(w, Placement(index: 3, flag: 1, byte1: 0, type: 1485, p1: 12, p2: 64, p3: 0, p4: 0,
                                               y: 1100, x: 4450))
        BackgroundSprite.hit(w, id: t, other: m)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: m)).occluder, SpriteSlot.Occluder())
        w.active.update(id: m) { $0.handleCleared = true }
        BackgroundSprite.hit(w, id: t, other: m)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: m)).occluder, window)
        // The tunnel's own Handle re-faces it from the cache (W2a tail) and moves nothing.
        BackgroundSprite.handle(world: w, id: t, faceWidth: Self.width)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: t)).face, FaceRef(pict: 3002, index: 0, set: .encoded))
    }

    func testPassagePairsLevel2() throws {
        // Level 2's six passages 2900, from the parsed Mlvl 2 placements (no session: a level-2 session needs W4).
        let L2 = try LevelFile.load(from: try resources(), level: 2)
        let w = SpriteWorld(level: L2)
        let c = SetupFaces.Context(level: L2, playerX: 0)
        var pairs: [[Int]] = []
        var slots: [Int: SpriteSlot] = [:]
        for i in [43, 44, 166, 167, 171, 172] {
            let e = try SetupFaces.setup(L2.placements[i], context: c)
            XCTAssertEqual(e.type, 2900)
            XCTAssertEqual(e.spawn, .idle)
            XCTAssertEqual(e.record, L2.placements[i])
            XCTAssertEqual(e.slot.hotRect, Rect(top: 0x28, left: 0x20, bottom: 0x57, right: 0x24))
            XCTAssertEqual([e.slot.hasHit ? 1 : 0, Int(e.slot.layer), e.source == .setupCached ? 1 : 0], [0, 1, 1])
            pairs.append([i, Int(e.record.p1)])
            slots[i] = e.slot
            w.idle.add(e.slot, faceRect: .noFace)
        }
        XCTAssertEqual(pairs, [[43, 44], [44, 43], [166, 167], [167, 166], [171, 172], [172, 171]])
        let p2901 = try SetupFaces.setup(placement(0, 2901, x: 0, y: 0), context: c)
        XCTAssertEqual(p2901.slot.hotRect, Rect(top: 0x28, left: 0x2c, bottom: 100, right: 0x2e))
        // The Handle's face: 2900 with p3 0 → its cached face, p3 ≠ 0 → none; 2901 → its face.
        let a43 = w.active.insert(try XCTUnwrap(slots[43]))
        w.active.update(id: a43) { $0.face = nil }
        BackgroundSprite.handle(world: w, id: a43, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: a43)?.face, FaceRef(pict: 2900, index: 0, set: .encoded))
        w.records[43] = placement(43, 2900, p1: 44, p3: 1, x: 4898, y: 250)
        BackgroundSprite.handle(world: w, id: a43, faceWidth: Self.width)
        XCTAssertNil(w.active.sprite(id: a43)?.face)
        w.records[43] = L2.placements[43]
        let o2901 = w.active.insert(p2901.slot)
        BackgroundSprite.handle(world: w, id: o2901, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: o2901)?.face, FaceRef(pict: 2901, index: 0, set: .encoded))

        // The player at passage 43 (4898, 250), offset (−16, −8).
        let pID = try XCTUnwrap(Player.spawn(world: w, x: 4882, y: 242))
        w.playerID = pID
        w.active.update(id: pID) { $0.x = 4882; $0.y = 242 }
        var snaps: [[Int]] = [], redraws = 0
        w.passageView = PassageView(snap: { w in
            snaps.append(w.active.sprite(id: pID).map { [$0.x, $0.y] } ?? [])        // moved before the snap
        }, redraw: { _ in redraws += 1 })
        var ops: [DrawOp] = []
        func contact(_ o: Int, _ keys: InputActions = []) {
            HitPlayerSprite.hit(w, player: pID, other: o, keys: keys)
            if let g = w.gammaFade.handle() { ops.append(g) }               // `.HandleAsyncGammaFade`, same iteration
        }
        // Count 0 without UP: nothing.
        contact(a43)
        XCTAssertEqual([Int(w.player.doorTransit), Int(w.player.animation05f8), ops.count], [0, 0, 0])
        // UP: the walk counter 1, the 20-step fade-out; then 21 frozen contacts (input locked while `06f0` ≠ 0).
        w.player.lookAhead = 0x1234
        for n in 1...21 {
            if n == 21 { w.player.lookAhead = 0x777 }
            contact(a43, n == 1 ? [.up] : [])
            XCTAssertEqual(w.player.doorTransit, Int16(n))
            XCTAssertEqual(w.active.sprite(id: pID).map { [$0.x, $0.y] }, [4882, 242])
            if n == 20 { XCTAssertEqual(w.player.lookAhead, 0x1234) }
        }
        XCTAssertEqual([Int(w.player.lookAhead), Int(w.player.animation05f8)], [0, 1])   // 0x15 → look-ahead 0
        let black = RGB16(red: 0, green: 0, blue: 0)
        XCTAssertEqual(ops, (0...20).map { DrawOp.gammaStep(numerator: $0, denominator: 20, toward: black) })
        XCTAssertTrue(w.gammaFade.fadedOut)
        XCTAssertEqual([snaps.count, redraws], [0, 0])
        // Contact 22: the jump to the idle entry whose record is p1 = 44 (189, 472), keeping (−16, −8).
        w.player.lookAhead = 0x555
        contact(a43)
        var q = try XCTUnwrap(w.active.sprite(id: pID))
        XCTAssertEqual([q.x, q.y, q.centre.x, q.centre.y], [173, 464, 173 + 50, 464 + 59])
        XCTAssertEqual([q.x256, q.y256], [173 << 8, 464 << 8])
        XCTAssertEqual([w.player.pixelX, w.player.pixelY, w.player.centreX, w.player.centreY, w.player.focusX,
                        w.player.focusY], [173, 464, 223, 523, 223, 523])
        XCTAssertEqual([Int(w.player.doorTransit), Int(w.player.animation05f8), Int(w.player.lookAhead)], [-22, -15, 0])
        XCTAssertEqual(snaps, [[173, 464]])
        XCTAssertEqual(redraws, 1)
        XCTAssertEqual(ops.last, DrawOp.gammaStep(numerator: 0, denominator: 20, toward: nil))   // fade-in begins
        // The walk-out faces (row 33's door arm): 1030[min((|n| >> 1) >> 1, 2)] while n climbs −15 … −1, idle 0.
        w.player.idle = 9
        var walk: [Int] = []
        for n in 0..<16 {
            PlayerStates.select(world: w, id: pID)
            if n == 0 { XCTAssertEqual(w.player.idle, 0) }                 // `_DAT_100a068c = 0` in the door arm
            walk.append(try XCTUnwrap(w.active.sprite(id: pID)?.face).pict == 1030
                        ? try XCTUnwrap(w.active.sprite(id: pID)?.face).index : -1)
        }
        XCTAssertEqual(Array(walk.prefix(15)), [2, 2, 2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 0, 0, 0])
        XCTAssertEqual([Int(w.player.animation05f8), Int(w.player.idle)], [0, 0])
        // The recovery −22 → 0, one contact with the partner (the player kept the offset) at a time; 22 frozen frames.
        let a44 = w.active.insert(try XCTUnwrap(slots[44]))
        for n in 1...22 {
            contact(a44)
            XCTAssertEqual(w.player.doorTransit, Int16(-22 + n))
        }
        XCTAssertEqual(ops.count, 42)                                       // 21 out + 21 in
        XCTAssertEqual(Array(ops.suffix(21)), (0...20).map { DrawOp.gammaStep(numerator: $0, denominator: 20, toward: nil) })
        XCTAssertFalse(w.gammaFade.fadedOut)
        // Unlocked: a new transit needs UP again.
        contact(a44)
        XCTAssertEqual(w.player.doorTransit, 0)
        q = try XCTUnwrap(w.active.sprite(id: pID))
        XCTAssertEqual([q.x, q.y], [173, 464])
        // The walk-in faces: 1033[min(n >> 1, 5)], n = 1, 2, …
        w.player.animation05f8 = 1
        var walkIn: [Int] = []
        for _ in 0..<12 {
            PlayerStates.select(world: w, id: pID)
            let f = try XCTUnwrap(w.active.sprite(id: pID)?.face)
            walkIn.append(f.pict == 1033 ? f.index : -1)
        }
        XCTAssertEqual(walkIn, [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 5])
        w.player.animation05f8 = 0
        // The other two pairs keep the offset: 166 (5230, 24) → 167 (2717, 1464), 171 (6191, 1401) → 172 (3995, 761).
        for (a, b) in [(166, 167), (171, 172)] {
            let from = L2.placements[a], to = L2.placements[b]
            let o = w.active.insert(try XCTUnwrap(slots[a]))
            w.active.update(id: pID) { $0.x = Int(from.x) + 7; $0.y = Int(from.y) - 3 }
            w.player.doorTransit = 0x15
            contact(o)
            q = try XCTUnwrap(w.active.sprite(id: pID))
            XCTAssertEqual([q.x, q.y], [Int(to.x) + 7, Int(to.y) - 3])
            XCTAssertEqual(w.player.doorTransit, -22)
        }
        XCTAssertEqual(snaps, [[173, 464], [2717 + 7, 1464 - 3], [3995 + 7, 761 - 3]])
        XCTAssertEqual(redraws, 3)

        // The async gamma gates: a fade-out while faded out, or a fade-in while not, does nothing.
        var g = AsyncGammaFade()
        g.fadeIn(steps: 4)
        XCTAssertNil(g.handle())
        g.fadeOut(steps: 2, toward: black)
        XCTAssertEqual([g.handle(), g.handle(), g.handle(), g.handle()],
                       [.gammaStep(numerator: 0, denominator: 2, toward: black),
                        .gammaStep(numerator: 1, denominator: 2, toward: black),
                        .gammaStep(numerator: 2, denominator: 2, toward: black), nil])
        g.fadeOut(steps: 2, toward: black)
        XCTAssertNil(g.handle())
        XCTAssertTrue(g.fadedOut)

        // In a session (level 1, a synthetic pair in records 509 / 510): UP held, the 22nd iteration jumps — the
        // camera snapped to (x − 0x142, y − 0xc0) and eased by 90 `.FindUpperLeftCorner` passes, the jump's draws
        // (two `.RedrawEntireScrollGrid`, one more `.WrapDrawSprites`) after the player pass, and the gamma steps at the
        // iteration's end.
        let s = try session()
        let sw = s.world
        XCTAssertEqual([sw.records[509].type, sw.records[510].type], [0, 0])
        _ = s.step(keys: KeyState())                                      // the player lands at (83, 123)
        let pp = try XCTUnwrap(sw.active.sprite(id: s.playerID))
        XCTAssertEqual([pp.x, pp.y], [83, 123])
        sw.records[509] = placement(509, 2900, p1: 510, x: Int16(pp.x + 0x10), y: Int16(pp.y))
        sw.records[510] = placement(510, 2900, p1: 509, x: 1600, y: 500)
        var aSlot = try SetupFaces.setup(sw.records[509], context: SetupFaces.Context(level: sw.level, playerX: 0)).slot
        aSlot.recordIndex = 509
        _ = sw.active.insert(aSlot)
        sw.idle.add(try SetupFaces.setup(sw.records[510], context: SetupFaces.Context(level: sw.level, playerX: 0)).slot,
                    faceRect: .noFace)
        let up = KeyState(pressed: [Int(s.prefs.keys[2])])
        var frames: [FrameOps] = []
        for _ in 0..<22 { frames.append(s.step(keys: up)) }
        let jumped = try XCTUnwrap(sw.active.sprite(id: s.playerID))
        XCTAssertEqual(s.player.doorTransit, -22)
        XCTAssertEqual([jumped.x - 1600, jumped.y - 500], [pp.x - (pp.x + 0x10), 0])
        func count(_ f: FrameOps, _ match: (DrawOp) -> Bool) -> Int { f.draws.filter(match).count }
        let redrawAll = { (d: DrawOp) -> Bool in if case .redrawEntireScrollGrid = d { return true }; return false }
        let wrapDraw = { (d: DrawOp) -> Bool in if case .wrapDrawSprites = d { return true }; return false }
        let gamma = { (d: DrawOp) -> Bool in if case .gammaStep = d { return true }; return false }
        XCTAssertEqual([count(frames[21], redrawAll), count(frames[21], wrapDraw)], [2, 2])
        XCTAssertEqual([count(frames[20], redrawAll), count(frames[20], wrapDraw)], [0, 1])
        // The jump's `.HandleIdleSprites` at the new view activates the partner (record 510), drawn by the jump's
        // `.WrapDrawSprites`.
        XCTAssertTrue(sw.active.sprites.contains { $0.recordIndex == 510 && $0.type == 2900 })
        let draws21 = frames[21].draws.compactMap { d -> [SpriteDraw]? in
            if case .wrapDrawSprites(let a) = d { return a }; return nil }
        XCTAssertTrue(draws21[1].contains { $0.face.pict == 2900 })
        // `.WrapEraseSprites` on the jump frame reads the live scroll point — the post-snap one, not the frame's paint.
        let erase21 = frames[21].draws.compactMap { d -> [Int]? in
            if case .wrapEraseSprites(_, let h, let v) = d { return [h, v] }; return nil }
        let copy21 = frames[21].draws.compactMap { d -> [Int]? in
            if case .copyToScreen(let h, let v, _, _) = d { return [h, v] }; return nil }
        XCTAssertEqual(erase21, [[s.camera.scrollH, s.camera.scrollV]])
        XCTAssertNotEqual(erase21, copy21)
        XCTAssertEqual(frames.map { count($0, gamma) }, Array(repeating: 1, count: 22))
        XCTAssertEqual(frames[21].draws.last, .gammaStep(numerator: 0, denominator: 20, toward: nil))
        // The camera: from the snap (x − 0x142, y − 0xc0) the 90 passes reach the focus target (centre − (0x130, 0xc0)
        // + the header offsets, the 16-px snap of h), clamped.
        var cam = try Camera(header: sw.level.header, spriteX: 0, spriteY: 0)
        cam.snap(playerX: jumped.x, playerY: jumped.y)
        XCTAssertEqual([cam.h, cam.v], [jumped.x - 0x142, jumped.y - 0xc0])
        for _ in 0..<FerazelSession.passagePasses {
            cam.findUpperLeftCorner(focusX: jumped.centre.x, focusY: jumped.centre.y)
        }
        XCTAssertEqual([s.camera.h, s.camera.v, s.camera.scrollH, s.camera.scrollV],
                       [cam.h, cam.v, cam.scrollH, cam.scrollV])
    }

    func testBackgroundRecordDefaultsWrittenBack() throws {
        // Of the Background Setups, only the 1480–1489 arm writes p2 0 → 0x8c (140) and p3 0 → 0x1e (30) back to the
        // record (l. 62329–62336); no W2b type does (the cannons' 105 / 106 p2 → 4 write-back, l. 62083–62086, belongs
        // to the rotating cannons, which are not built) — so the defaults are pinned on mace records whose p2 / p3 are 0.
        let (w, _) = try world()
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        let e = try SetupFaces.setup(placement(7, 1480, x: 400, y: 600), context: c)
        XCTAssertEqual([e.record.p1, e.record.p2, e.record.p3, e.record.p4], [0, 140, 30, 0])
        XCTAssertEqual(e.slot.subtype, 0xb)                               // p1 0 → mode 0xb, not written back
        let e1 = try SetupFaces.setup(placement(7, 1488, p1: 12, p2: 0, p3: 5, x: 400, y: 600), context: c)
        XCTAssertEqual([e1.record.p2, e1.record.p3], [140, 5])
        let e2 = try SetupFaces.setup(placement(7, 1484, p1: 13, p2: 7, p3: 0, x: 400, y: 600), context: c)
        XCTAssertEqual([e2.record.p2, e2.record.p3], [7, 30])
        let e3 = try SetupFaces.setup(placement(7, 1484, p1: 13, p2: -1, p3: -1, x: 400, y: 600), context: c)
        XCTAssertEqual([e3.record.p2, e3.record.p3], [-1, -1])
        // The radial block takes the written-back values: r 140, g 30 (mode 0xb ≥ 10 → `.MakeRadial`).
        let id = try addBackground(w, placement(7, 1480, x: 400, y: 600))
        let b = try XCTUnwrap(w.active.sprite(id: id)?.radial)
        XCTAssertEqual([b.radius, Int32(b.gravity), b.speed], [140 << 8, 30, 0])
        XCTAssertEqual(b.spokes.count, 140 / 16)
        // In a level-1 session: records 16 and 44 (1485, p2 120, p3 0) become p3 30; every other record as loaded.
        let s = try session()
        for i in 0..<LevelFile.placementCount {
            if i == 16 || i == 44 {
                XCTAssertEqual([s.world.records[i].p2, s.world.records[i].p3], [120, 30])
                XCTAssertEqual(s.level.placements[i].p3, 0)
            } else {
                XCTAssertEqual(s.world.records[i], s.level.placements[i], "record \(i)")
            }
        }
        // The W2b arms leave their records as read: the cannon (p1 0, p2 / p3 0), the tunnel, the springs, the passages.
        for p in [w.level.placements[41], w.level.placements[56], placement(7, 1150, x: 400, y: 600),
                  placement(7, 1153, x: 400, y: 600), placement(7, 2900, p1: 8, x: 400, y: 600),
                  placement(7, 2901, p1: 8, x: 400, y: 600), placement(7, 1095, x: 400, y: 600)] {
            XCTAssertEqual(try SetupFaces.setup(p, context: c).record, p, "type \(p.type)")
        }
        XCTAssertThrowsError(try SetupFaces.setup(placement(7, 1090, p1: 105, x: 400, y: 600), context: c))
    }

    func testSuperSpring() throws {
        // `.SetupBackgroundSprite` spring arms (l. 62046–62219): rects, the hit callback, `+0x1ba` 32000; the Handle's
        // sheets 0x47e / 0x47f / 0x480 (0x481 = 0x480 mirrored).
        let (w, p) = try world(playerX: 2000, playerY: 1000)
        let c = SetupFaces.Context(level: w.level, playerX: 0)
        for (t, r, sheet): (Int16, Rect, Int16) in [
            (1150, Rect(top: 10, left: 4, bottom: 0x3c, right: 0x38), 1150),
            (1151, Rect(top: 0, left: 4, bottom: 0x32, right: 0x38), 1151),
            (1152, Rect(top: 4, left: 0, bottom: 0x2e, right: 0x32), 1152),
            (1153, Rect(top: 4, left: 10, bottom: 0x2e, right: 0x3c), 1152),
        ] {
            let e = try SetupFaces.setup(placement(9, t, x: 2010, y: 1040), context: c)
            XCTAssertEqual(e.slot.hotRect, r)
            XCTAssertEqual([e.slot.hasHit ? 1 : 0, e.slot.clip.bottom, Int(e.slot.mode), Int(e.slot.layer)],
                           [1, 32000, 0, 1])
            XCTAssertEqual(e.sheet?.pict, sheet)
            XCTAssertEqual(e.spawn, .idle)
        }
        for t: Int16 in [1154, 1159] {
            XCTAssertThrowsError(try SetupFaces.setup(placement(9, t, x: 2010, y: 1040), context: c))
        }
        // A synthetic 1150 under the player (centre (2040, 1075) once its Handle has run), in view.
        let sp = try addBackground(w, placement(9, 1150, x: 2010, y: 1040))
        BackgroundSprite.handle(world: w, id: sp, faceWidth: Self.width)
        XCTAssertEqual(try XCTUnwrap(w.active.sprite(id: sp)).centre, SpriteSlot.Point(x: 2040, y: 1075))
        w.player.scrollH = 2040 - 0x130 + 10
        w.player.scrollV = 1075 - 0xd0 - 10
        // Each frame: the Handles (`+0x46` −1, clamped 0…3, face `+0x46`), then the hits — a fire in frame n sets 4, so
        // the next fire is in frame n + 4 (faces 3, 2, 1, 0 between).
        var fires: [Int] = [], faces: [Int] = []
        for f in 1...12 {
            BackgroundSprite.handle(world: w, id: sp, faceWidth: Self.width)
            faces.append(try XCTUnwrap(w.active.sprite(id: sp)?.face).index)
            w.active.update(id: p) { $0.vx = 0x77; $0.vy = 0x100 }
            w.player.cues = []
            var r = w.rng
            let rate = r.soundRate()
            BackgroundSprite.hit(w, id: sp, other: p)
            if w.active.sprite(id: p)?.vy == -0x2292 {
                fires.append(f)
                XCTAssertEqual(w.active.sprite(id: p)?.vx, 0x77)             // vx += 0
                XCTAssertEqual(w.active.sprite(id: sp)?.phase, 4)
                XCTAssertEqual(w.player.cues, [
                    PlayerCue(call: .stop, snd: 493),
                    PlayerCue(call: .threeDRand, snd: 493, priority: 1, volume: 0x100,
                              position: SpriteSlot.Point(x: 2040, y: 1075), rate: rate),
                ])
                XCTAssertEqual(w.rng.seed, r.seed)
            } else {
                XCTAssertEqual(w.player.cues, [])
            }
        }
        XCTAssertEqual(fires, [1, 5, 9])
        XCTAssertEqual(faces, [0, 3, 2, 1, 0, 3, 2, 1, 0, 3, 2, 1])
        XCTAssertEqual([Int(w.player.jumpBase), Int(w.player.airCounter)], [1, 2])
        XCTAssertEqual(w.active.sprite(id: sp)?.occluder.bottom, 32000)
        // The clamp 0…3 after the decrement (a hit sets 4, so only a larger stored value meets the upper clamp).
        w.active.update(id: sp) { $0.phase = 9 }
        BackgroundSprite.handle(world: w, id: sp, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: sp).map { [Int($0.phase), $0.face?.index ?? -1] }, [3, 3])
        w.active.update(id: sp) { $0.phase = -4 }
        BackgroundSprite.handle(world: w, id: sp, faceWidth: Self.width)
        XCTAssertEqual(w.active.sprite(id: sp).map { [Int($0.phase), $0.face?.index ?? -1] }, [0, 0])
        // The view test: |h + 0x130 − cx| < 300 and |v + 0xd0 − cy| < 200; outside, no cue and no draw.
        func cueAt(_ dh: Int, _ dv: Int) -> Bool {
            w.player.scrollH = 2040 - 0x130 + dh
            w.player.scrollV = 1075 - 0xd0 + dv
            w.active.update(id: sp) { $0.phase = 0 }
            w.player.cues = []
            let seed = w.rng.seed
            BackgroundSprite.hit(w, id: sp, other: p)
            XCTAssertEqual(w.active.sprite(id: p)?.vy, -0x2292)
            XCTAssertEqual(w.rng.seed == seed, w.player.cues.isEmpty)
            return !w.player.cues.isEmpty
        }
        XCTAssertEqual([cueAt(299, 0), cueAt(300, 0), cueAt(-299, 199), cueAt(-300, 0), cueAt(0, -199),
                        cueAt(0, 200), cueAt(0, -200)], [true, false, true, false, true, false, false])
        // 1151: vy = 0xa28, J 1; 1152 / 1153: v = (±0x1900, −0xd48) and, for the player, climb 0 and launched.
        func fire(_ t: Int16, _ hitter: Int) throws -> [Int] {
            let id = try addBackground(w, placement(9, t, x: 2010, y: 1040))
            w.active.update(id: hitter) { $0.vx = 0x77; $0.vy = 0x100 }
            BackgroundSprite.hit(w, id: id, other: hitter)
            let h = try XCTUnwrap(w.active.sprite(id: hitter))
            return [Int(h.vx), Int(h.vy)]
        }
        w.player.jumpBase = 0
        w.player.airCounter = 0
        XCTAssertEqual(try fire(1151, p), [0x77, 0xa28])
        XCTAssertEqual([Int(w.player.jumpBase), Int(w.player.airCounter)], [1, 0])
        w.player.climb = 2
        w.player.launched = false
        XCTAssertEqual(try fire(1152, p), [0x1900, -0xd48])
        XCTAssertEqual([Int(w.player.climb), w.player.launched ? 1 : 0], [0, 1])
        XCTAssertEqual(try fire(1153, p), [-0x1900, -0xd48])
        // A non-player hitter: v set, the player's globals untouched.
        let box = w.active.insert(SpriteSlot(type: 0xc12, x: 2000, y: 1000))
        w.player.climb = 2
        w.player.launched = false
        XCTAssertEqual(try fire(1152, box), [0x1900, -0xd48])
        XCTAssertEqual([Int(w.player.climb), w.player.launched ? 1 : 0], [2, 0])
        // Refused: another spring, an Effect, a dying (`+0xe9`) hitter, a spring still cooling down; a mace is not.
        let sp2 = try addBackground(w, placement(9, 1151, x: 2010, y: 1040))
        func refused(_ hitter: Int) -> Bool {
            w.active.update(id: sp) { $0.phase = 0 }
            w.active.update(id: hitter) { $0.vy = 0x100 }
            BackgroundSprite.hit(w, id: sp, other: hitter)
            return w.active.sprite(id: hitter)?.vy == 0x100 && w.active.sprite(id: sp)?.phase == 0
        }
        XCTAssertTrue(refused(sp2))
        var fx = SpriteSlot(type: 0x4b1, x: 2000, y: 1000)
        fx.handler = .effect
        XCTAssertTrue(refused(w.active.insert(fx)))
        let dying = w.active.insert(SpriteSlot(type: 0xc12, x: 2000, y: 1000))
        w.active.update(id: dying) { $0.dead = true }
        XCTAssertTrue(refused(dying))
        let mace = try addBackground(w, placement(9, 1485, p1: 12, p2: 64, x: 2010, y: 1040))
        XCTAssertFalse(refused(mace))
        w.active.update(id: sp) { $0.phase = 1 }
        w.active.update(id: p) { $0.vy = 0x100 }
        BackgroundSprite.hit(w, id: sp, other: p)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, 0x100)
        // Both passes in one frame (`.MTCollideSprites`, then the player pass's contact hit): one fire, one cue pair.
        w.player.scrollH = 2040 - 0x130
        w.player.scrollV = 1075 - 0xd0
        for id in [sp2, mace, box, dying] { w.active.update(id: id) { $0.x = 9000 } }
        w.active.update(id: sp) { $0.phase = 0 }
        w.active.update(id: p) { $0.vy = 0x100 }
        w.player.cues = []
        w.collideSprites(FerazelSession.hitCallback)
        w.collideSpecial(hitPlayer: { w, p, c in HitPlayerSprite.hit(w, player: p, other: c) },
                         hit: FerazelSession.hitCallback)
        XCTAssertEqual(w.active.sprite(id: p)?.vy, -0x2292)
        XCTAssertEqual(w.player.cues.map(\.snd), [493, 493])
    }
}

import XCTest
@testable import FerazelCore

/// EC (docs/plans/2026-10-30-ferazel-phase5.md): what the enemy classes share — the counting window, the Kill
/// bookkeeping, contact damage by Handle (`.HitPlayerSprite` steps 6–7, `.HurtPlayer`), the burn-away
/// (`.HandleBurn` / `.BurnFaceRow`), the goblin voices and `.SmiteEnemies` by Handle. The enemy cases are set by hand
/// here: every class's `forClass` row still answers `.inert` until its own task maps it.
final class EnemyCommonTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private func world() throws -> SpriteWorld { SpriteWorld(level: try LevelFile.load(from: try resources(), level: 1)) }

    /// The first seed ≥ 1 whose stream makes `pick` true.
    private func seed(_ pick: (inout FastRand) -> Bool) -> Int32 {
        var s: Int32 = 1
        while true {
            var r = FastRand(seed: s)
            if pick(&r) { return s }
            s += 1
        }
    }

    /// The player at (200, 300) with HP 1000 and an enemy of `handler` / `type` on top of him (same hot rect), HP 100.
    private func contact(_ w: SpriteWorld, handler: SpriteHandler, type: Int16) throws -> (player: Int, enemy: Int) {
        let pid = try XCTUnwrap(Player.spawn(world: w, x: 200, y: 300))
        w.active.update(id: pid) { $0.hp = 1000; $0.invulnerable = 0 }
        let p = try XCTUnwrap(w.active.record(id: pid))
        let rect = p.hotRect
        let eid = try XCTUnwrap(w.newSprite(type: type, x: p.x, y: p.y, layer: 0xb, handler: handler) { s in
            s.x = p.x                                                   // past `.MTNewSprite`'s `+0xc` quirk
            s.y = p.y
            s.hp = 100
            s.hotRect = rect
        })
        w.globals.coins = 10
        w.player.cues = []
        return (pid, eid)
    }

    private func particles(_ w: SpriteWorld, kind: Int16) -> Int {
        w.particles.records.filter { $0.alive && $0.kind == kind }.count
    }

    // MARK: - the counting window

    func testCountingWindow() throws {
        // `.SetupWalkerSprite` M l. 57090–57094: `if (*_DAT_1009fe8c) { +0x1b5 = 1; *_DAT_1009ffb4 += 1 }`.
        let L = try LevelFile.load(from: try resources(), level: 1)
        let c = SetupFaces.Context(level: L, playerX: 0)
        let walker = try XCTUnwrap(L.activePlacements.first {
            SpriteClassTable.classify(type: $0.type, p1Negative: $0.p1 < 0)?.0 == .walker
        })
        var lightsA = LightTable(), lightsB = LightTable()
        var rngA = FastRand(seed: 7), rngB = FastRand(seed: 7)
        var open = EnemyCounting(window: true)
        let inside = try SetupFaces.setup(walker, context: c, lights: &lightsA, counting: &open, rng: &rngA)
        XCTAssertTrue(inside.slot.countedInTotals)
        XCTAssertEqual(open.live, 1)
        var shut = EnemyCounting()
        let outside = try SetupFaces.setup(walker, context: c, lights: &lightsB, counting: &shut, rng: &rngB)
        XCTAssertFalse(outside.slot.countedInTotals)
        XCTAssertEqual(shut.live, 0)
        XCTAssertEqual(rngA.seed, rngB.seed, "the window changes no draw")
        // The idiom itself.
        var s = SpriteSlot(type: 0x6b0, x: 0, y: 0)
        shut.countIfWindow(&s)
        XCTAssertEqual([s.countedInTotals, shut.live == 0], [false, true])
        open.countIfWindow(&s)
        XCTAssertEqual([s.countedInTotals, open.live == 2], [true, true])
        // Level 1's total, unchanged from before EC: 0xf (7 Walkers, 3 Crawlers, 5 Roaches — LevelRunTests' 15), the
        // window shut again after the spawn.
        let session = try FerazelSession(resources: try resources(), prefs: FerazelPrefs(), level: 1)
        XCTAssertEqual(session.tallies.enemies, 0xf)
        XCTAssertEqual(session.world.enemies, EnemyCounting(window: false, live: 0xf))
        // The spawn's secrets / Xichrons tally runs only while the window is set (raw `10004da4..10004dc0`).
        func spawned(_ window: Bool) throws -> SetupFaces.Tallies {
            var rng = FastRand(seed: 7)
            var counting = EnemyCounting(window: window)
            return try SetupFaces.spawnLevelSprites(context: c, rng: &rng, counting: &counting, idleFaceRect: { _ in
                IdleSprites.Rect(top: 0, left: 0, bottom: 0, right: 0)
            }).tallies
        }
        let opened = try spawned(true), shutTally = try spawned(false)
        XCTAssertEqual(opened.enemies, 0xf)
        XCTAssertGreaterThan(opened.secrets + opened.xichrons, 0)
        XCTAssertEqual([shutTally.enemies, shutTally.secrets, shutTally.xichrons], [0, 0, 0])
    }

    // MARK: - kills

    func testKillBookkeeping() throws {
        // `.KillCrawler` M l. 56695–56701: `+0xe9 == 0 && +0x1b5` → live − 1, `G+0x306+2L` + 1; `+0xe9 = 1`; `+0xea = 1`.
        let w = try world()
        w.levelIndex = 2
        w.enemies = EnemyCounting(live: 5)
        // The Kill proc runs against the world by id (SpriteWorld rule 2).
        func enemy(_ type: Int16, _ h: SpriteHandler, counted: Bool = true, dying: Bool = false) throws -> Int {
            try XCTUnwrap(w.newSprite(type: type, x: 0, y: 0, layer: 0xb, handler: h) { s in
                s.countedInTotals = counted
                s.killCount = dying ? 1 : 0
            })
        }
        func slot(_ id: Int) throws -> SpriteSlot { try XCTUnwrap(w.active.record(id: id)) }
        let crawler = try enemy(0x6b0, .crawler)
        EnemyCommon.killProc(w, id: crawler)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [4, 1])
        XCTAssertEqual([try slot(crawler).killCount == 1, try slot(crawler).killedForGood], [true, true])
        EnemyCommon.killProc(w, id: crawler)                    // once: `+0xe9` is set now
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [4, 1])
        // `.KillWalker` (M l. 58624–58629) stores no `+0xea`.
        let walker = try enemy(0x6a4, .walker)
        EnemyCommon.killProc(w, id: walker)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [3, 2])
        XCTAssertEqual([try slot(walker).killCount == 1, try slot(walker).killedForGood], [true, false])
        // An uncounted kill (a pipe child, a spawned or re-activated sprite: `+0x1b5` 0): no count, no stat, `+0xe9` 1.
        let child = try enemy(0x6b8, .roach, counted: false)
        EnemyCommon.killProc(w, id: child)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [3, 2])
        XCTAssertEqual([try slot(child).killCount == 1, try slot(child).killedForGood], [true, true])
        // `.KillGremlinSprite` (M l. 69736–69738, raw 100810e0 `bnelr`): `+0xe9 ≠ 0` → return at once — no count, no
        // stat, no `+0xea`; the first call counts as the others do.
        let gremlin = try enemy(0x6f4, .gremlin)
        EnemyCommon.killProc(w, id: gremlin)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [2, 3])
        XCTAssertEqual([try slot(gremlin).killCount == 1, try slot(gremlin).killedForGood], [true, true])
        let dying = try enemy(0x6f4, .gremlin, dying: true)
        EnemyCommon.killProc(w, id: dying)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [2, 3])
        XCTAssertFalse(try slot(dying).killedForGood, "no `+0xea` store")
        // The `+0xea` classes (scan of the enemy Kills).
        XCTAssertEqual(SpriteHandler.allEnemyCases.filter(EnemyCounting.killsForGood),
                       [.crawler, .roach, .dillo, .bat, .gremlin, .frog, .salamander, .blob, .warrior])
        // Without a Kill proc (`+0x50 == 0`): `+0xe9 = 1` only.
        let other = try enemy(1, .box)
        EnemyCommon.killProc(w, id: other)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [2, 3])
        XCTAssertTrue(try slot(other).dead)
    }

    // MARK: - contact damage

    func testContactDamageWalker() throws {
        // Step 7 (M l. 49802–49912): Walker 0x70, invulnerability 0x3c; `FastRand(100)` > 0x50 → 3 coins, drawn before
        // `.HurtPlayer`; blood on (`.BloodSpray(player, walker, 0x28, 500, 0x96, 2)`).
        for coinsDrop in [true, false] {
            let w = try world()
            let (pid, eid) = try contact(w, handler: .walker, type: 0x6a4)
            let sd = seed { r in (0x50 < r.next(100)) == coinsDrop }
            w.rng = FastRand(seed: sd)
            var replay = FastRand(seed: sd)
            _ = replay.next(100)
            for _ in 0..<2 * 0x28 { _ = replay.next(0x96) }           // `.HurtPlayer`'s blood: vy, vx per particle
            let pitch = Int32(replay.next(10000)) + 65000             // then its 508 (damage < 0xe0)
            HitPlayerSprite.hit(w, player: pid, other: eid)
            let p = try XCTUnwrap(w.active.record(id: pid))
            XCTAssertEqual([Int(p.hp), Int(p.invulnerable)], [1000 - 0x70, 0x3c])
            // 3 coins → `.HurtPlayer` knocks out R(3) + 2 of them (2…4); none → none.
            XCTAssertEqual(coinsDrop ? (2...4).contains(w.player.coinsLost) : w.player.coinsLost == 0, true)
            XCTAssertEqual(w.globals.coins, 10 - w.player.coinsLost)
            XCTAssertEqual(w.player.cues.first, PlayerCue(call: .regPitched, snd: 508, priority: 1, volume: 0x97,
                                                         rate: pitch), "R(100) is the first draw")
            XCTAssertEqual(particles(w, kind: 2), 0x28)
        }
        // Ferazel invulnerable, or the attacker dead: the R(100) is still drawn — and nothing else.
        for dead in [false, true] {
            let w = try world()
            let (pid, eid) = try contact(w, handler: .walker, type: 0x6a4)
            if dead { w.active.update(id: eid) { $0.hp = 0 } } else { w.active.update(id: pid) { $0.invulnerable = 5 } }
            w.rng = FastRand(seed: 99)
            var one = FastRand(seed: 99)
            _ = one.next(100)
            HitPlayerSprite.hit(w, player: pid, other: eid)
            XCTAssertEqual(w.rng.seed, one.seed)
            XCTAssertEqual(w.active.record(id: pid)?.hp, 1000)
            XCTAssertEqual([w.globals.coins, Int16(w.player.cues.count), Int16(particles(w, kind: 2))], [10, 0, 0])
        }
        // The Walker's crush (`.HitWalkerSprite` M l. 58584–58589): `+0xb0 ≠ 4` is tested before `.PlatformBounce` is
        // called at all; then bounce 2, not one-way, not an enemy pipe 0x5d2…0x5d6.
        var walkerSlot = SpriteSlot(type: 0x6a4, x: 0, y: 0)
        let box = SpriteSlot(type: 0x4b0, x: 0, y: 0)
        var bounces = 0
        let two: () -> Int16 = { bounces += 1; return 2 }
        XCTAssertTrue(EnemyCommon.crushesWalker(mover: walkerSlot, solid: box, bounce: two))
        walkerSlot.subtype = 4
        XCTAssertFalse(EnemyCommon.crushesWalker(mover: walkerSlot, solid: box, bounce: two))
        XCTAssertEqual(bounces, 1, "no `.PlatformBounce` at `+0xb0 == 4`")
        walkerSlot.subtype = 3
        XCTAssertFalse(EnemyCommon.crushesWalker(mover: walkerSlot, solid: box, bounce: { 1 }))
        var oneWay = box
        oneWay.oneWay = true
        XCTAssertFalse(EnemyCommon.crushesWalker(mover: walkerSlot, solid: oneWay, bounce: two))
        XCTAssertFalse(EnemyCommon.crushesWalker(mover: walkerSlot, solid: SpriteSlot(type: 0x5d4, x: 0, y: 0),
                                                 bounce: two))
        // The liquids rows (Walker M l. 58426–58450, Crawler 56497–56512, Roach 65103–65110, Dillo 72828–72842).
        typealias Liquid = (EnemyCommon.LiquidClass, Int32, Int16, Int16, Int16, [Int16])  // row, kind, hp, invul → hp invul flash
        let ouchHurt: [Int16] = [100 - 100, 0x13, 0x11]
        for (c, row, kind, hp, invul, after) in [
            (.walker, 1, 0, 100, 0, [100 - 0x96, 0xc, 0xc]), (.walker, 2, 0, 100, 0, [100, 0, 0]),
            (.walker, 0, 1, 100, 0, [100, 0, 0]), (.walker, 2, 1, 100, 0, ouchHurt),
            (.walker, 1, 2, 100, 0, ouchHurt), (.walker, 1, 3, 100, 0, [104, 0, 0]), (.walker, 1, 3, 500, 0, [500, 0, 0]),
            (.walker, 1, 1, 100, 5, [100, 5, 0]),
            (.crawler, 1, 0, 100, 0, [100, 0, 0]), (.crawler, 1, 1, 100, 0, ouchHurt),
            (.crawler, 1, 3, 100, 0, [104, 0, 0]),
            (.dillo, 1, 1, 100, 0, [100, 0, 0]), (.dillo, 1, 2, 100, 0, ouchHurt), (.dillo, 1, 3, 100, 0, [104, 0, 0]),
            (.roach, 1, 0, 100, 0, ouchHurt), (.roach, 1, 3, 100, 0, ouchHurt), (.roach, 2, 0, 100, 0, [100, 0, 0]),
        ] as [Liquid] {
            let v = try world()
            let id = try XCTUnwrap(v.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) { s in
                s.waterRow = row
                s.waterKind = kind
                s.hp = hp
                s.invulnerable = invul
            })
            v.player.cues = []
            EnemyCommon.liquids(v, id: id, class: c)
            let s = try XCTUnwrap(v.active.record(id: id))
            XCTAssertEqual([s.hp, s.invulnerable, s.flash], after, "\(c) row \(row) kind \(kind)")
            let hurt = after[1] != invul
            XCTAssertEqual(v.player.cues.map { [$0.snd, $0.volume] }, hurt ? [[EnemyCommon.ouch, 0x55]] : [],
                           "\(c) row \(row) kind \(kind)")
        }
        // The environmental hazards (`.HitWalkerSprite` M l. 58590–58595; the Crawler's `+0x150` test raw `1006687c`).
        func hazard(_ type: Int16, _ h: SpriteHandler, _ set: (inout SpriteSlot) -> Void = { _ in }) -> SpriteSlot {
            var o = SpriteSlot(type: type, x: 0, y: 0)
            o.handler = h
            set(&o)
            return o
        }
        let boom = hazard(0x4b7, .effect) { $0.phase = 7 }
        XCTAssertEqual([EnemyCommon.environmentalHazard(boom),
                        EnemyCommon.environmentalHazard(hazard(0x4b7, .effect) { $0.phase = 8 }),
                        EnemyCommon.environmentalHazard(hazard(0x4b6, .effect) { $0.phase = 7 }),
                        EnemyCommon.environmentalHazard(hazard(0x4b7, .inert) { $0.phase = 7 }),
                        EnemyCommon.environmentalHazard(hazard(0x4b7, .effect) { $0.phase = 7; $0.handleCleared = true })],
                       [true, false, false, false, false])
        for (t, timer, w150, walker, crawler) in [(Int16(0x5a0), Int32(1), Int32(0), true, true),
                                                   (0x5a0, 2, 0, true, false), (0x5a0, 0, 2, false, true),
                                                   (0x5a0, 3, 0, false, false), (0x5a1, 1, 2, false, false)] {
            let o = hazard(t, .inert) { $0.classTimer = timer; $0.classWord150 = w150 }
            XCTAssertEqual([EnemyCommon.environmentalHazard(o), EnemyCommon.environmentalHazard(o, crawlerFields: true)],
                           [walker, crawler], "\(t) \(timer) \(w150)")
        }
        // A class Handle not yet mapped is `.inert`: no contact damage (the ◈ switch-off).
        let w = try world()
        let (pid, eid) = try contact(w, handler: .inert, type: 0x6a4)
        let before = w.rng.seed
        HitPlayerSprite.hit(w, player: pid, other: eid)
        XCTAssertEqual([w.rng.seed, Int32(w.active.record(id: pid)?.hp ?? 0)], [before, 1000])
    }

    func testContactDamage0x6d6Invul() throws {
        // Type 0x6d6 (the Ax goblin's body) → 0x70 with invulnerability 0x24 (M l. 49896–49899).
        let w = try world()
        let (pid, eid) = try contact(w, handler: .walker, type: 0x6d6)
        HitPlayerSprite.hit(w, player: pid, other: eid)
        let p = try XCTUnwrap(w.active.record(id: pid))
        XCTAssertEqual([Int(p.hp), Int(p.invulnerable)], [1000 - 0x70, 0x24])
        // The class row otherwise: a Crawler 0x38 and no coin draw; a Gremlin 0xe0 → 5 coins, no draw.
        for (h, damage, lost) in [(SpriteHandler.crawler, 0x38, 0...0), (.bat, 0x38, 0...0), (.blob, 0x38, 0...0),
                                  (.roach, 0x38, 0...0), (.gremlin, 0xe0, 4...6)]
                as [(SpriteHandler, Int, ClosedRange<Int16>)] {
            let v = try world()
            let (q, e) = try contact(v, handler: h, type: 0x6b0)
            HitPlayerSprite.hit(v, player: q, other: e)
            XCTAssertEqual([Int(v.active.record(id: q)?.hp ?? 0), Int(v.active.record(id: q)?.invulnerable ?? 0)],
                           [1000 - damage, 0x3c], "\(h)")
            XCTAssertTrue(lost.contains(v.player.coinsLost), "\(h): 5 coins → R(3) + 4")
        }
        // Step 6's enemy rows (M l. 49514–49573), no blood, with R(100) = 70: Salamander 0x70 (70 < 0x51 → no coins);
        // Floater only at `+0x46 > 12`; Crab 0x70 (70 ≥ 0x3d → 3); Dillo 0x74e 0xe0 (→ 4), 0x74f 0x1c0 (6, no draw),
        // any other Dillo type nothing.
        let at70 = seed { r in r.next(100) == 70 }
        for (h, type, phase, damage, lost) in [
            (SpriteHandler.salamander, Int16(0x73a), Int16(0), 0x70, 0...0), (.floater, 0x6f9, 13, 0x70, 0...0),
            (.floater, 0x6f9, 12, 0, 0...0), (.crab, 0x46c, 0, 0x70, 2...4), (.dillo, 0x74e, 0, 0xe0, 3...5),
            (.dillo, 0x74f, 0, 0x1c0, 5...7), (.dillo, 0x74d, 0, 0, 0...0),
        ] as [(SpriteHandler, Int16, Int16, Int, ClosedRange<Int16>)] {
            let v = try world()
            let (q, e) = try contact(v, handler: h, type: type)
            v.active.update(id: e) { $0.phase = phase }
            v.rng = FastRand(seed: at70)
            HitPlayerSprite.hit(v, player: q, other: e)
            let p = try XCTUnwrap(v.active.record(id: q))
            XCTAssertEqual([Int(p.hp), Int(p.invulnerable)], [1000 - damage, damage == 0 ? 0 : 0x3c], "\(h) \(type)")
            XCTAssertTrue(lost.contains(v.player.coinsLost), "\(h) \(type)")
            XCTAssertEqual(particles(v, kind: 2), 0, "no blood")
            if damage == 0 { XCTAssertEqual(v.rng.seed, at70, "\(h) \(type): no draw") }
        }
    }

    func testDeadEnemyHarmless() throws {
        // `.HurtPlayer` M l. 47983–47985: an attacker with HP < 1 whose Handle is neither the EnemyShot's nor the Box's
        // hurts not at all.
        for (h, hurts) in [(SpriteHandler.walker, false), (.crawler, false), (.enemyShot, true), (.box, true)] {
            let w = try world()
            let (pid, eid) = try contact(w, handler: h, type: 0x6a4)
            w.active.update(id: eid) { $0.hp = 0 }
            let landed = HurtPlayer.hurt(w, player: pid, attacker: eid, damage: 0x70, blood: false, invulnerable: 0x3c,
                                         coins: 0)
            XCTAssertEqual(landed, hurts, "\(h)")
            XCTAssertEqual(w.active.record(id: pid)?.hp, hurts ? 1000 - 0x70 : 1000, "\(h)")
        }
        // Step 7's exclusions (M l. 49802ff): 0x76c…0x775 or 0x754 with `+0x110 > 0`; 0x6e6 with `+0x164 ≥ 2`; 0x74d;
        // 0x73a…0x73e with `+0x160 ≠ 0` — no hit, no draw. The same types otherwise hurt.
        for (type, set, hurts) in [
            (Int16(0x76c), { (s: inout SpriteSlot) in s.gravity = 1 }, false), (0x775, { $0.gravity = 1 }, false),
            (0x754, { $0.gravity = 1 }, false), (0x76c, { $0.gravity = 0 }, true),
            (0x6e6, { $0.launchSpeed = 2 }, false), (0x6e6, { $0.launchSpeed = 1 }, true),
            (0x74d, { _ in }, false), (0x73a, { $0.classWord160 = 1 }, false), (0x73e, { $0.classWord160 = 1 }, false),
            (0x73a, { $0.classWord160 = 0 }, true),
        ] as [(Int16, (inout SpriteSlot) -> Void, Bool)] {
            let w = try world()
            let (pid, eid) = try contact(w, handler: .walker, type: type)
            w.active.update(id: eid, set)
            let before = w.rng.seed
            HitPlayerSprite.hit(w, player: pid, other: eid)
            XCTAssertEqual(w.active.record(id: pid)?.hp, hurts ? 1000 - 0x70 : 1000, "\(type)")
            if !hurts { XCTAssertEqual(w.rng.seed, before, "\(type): no draw") }
        }
    }

    // MARK: - the burn-away

    /// A 4-wide, 6-row face: rows 2…4 opaque (four literal pixels each), so face `+8` (top) 2 and `+0xc` (bottom) 5.
    private static let burnFace: ParticleFace = {
        var t: [UInt8] = []
        func token(_ op: UInt32, _ n: UInt32) {
            let v = op << 24 | n
            t += [UInt8(v >> 24), UInt8((v >> 16) & 0xff), UInt8((v >> 8) & 0xff), UInt8(v & 0xff)]
        }
        for row in 0..<6 {
            token(1, 0)
            if (2...4).contains(row) {
                token(2, 4)
                t += [9, 9, 9, 9]
            }
        }
        token(0, 0)
        return ParticleFace(frame: [0, 0, 6, 4], bounds: [2, 0, 5, 4], tokens: t)
    }()

    func testBurnAwayClipsAndKills() throws {
        // `.HandleBurn` M l. 38765–38840 from `.StandardSpriteCleanup`: `+0x1a2 = 1` → the opaque top (2), then
        // `+0x8d + 1` rows a frame: `+0x1bc` 3, 4, 5; past the opaque bottom 5 → the Kill proc (`.KillWalker`).
        let w = try world()
        w.particleFaces = ParticleFaces(sprite: { _ in Self.burnFace })
        var prefs = FerazelPrefs()
        prefs.effects = 2                                               // no Enhanced second pass (no R(100))
        w.voices = SoundVoices(prefs: prefs)
        w.levelIndex = 1
        w.enemies = EnemyCounting(live: 1)
        let id = try XCTUnwrap(w.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) { s in
            s.face = FaceRef(pict: 0x6a4, index: 0, set: .encoded)
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 6, right: 0x20)
            s.countedInTotals = true
            EnemyCommon.startBurn(&s)
        })
        var tops: [Int] = []
        for frame in 0..<3 {
            w.player.cues = []
            let before = particles(w, kind: 1)
            w.standardSpriteCleanup(id, faceWidth: { _ in 4 })
            let s = try XCTUnwrap(w.active.record(id: id))
            tops.append(s.clip.top)
            XCTAssertEqual([s.burning, s.dead], [true, false])
            XCTAssertEqual(particles(w, kind: 1) - before, 2, "four pixels at spacing 2, frame \(frame)")
            // The burn sound once, at `+0x1a2 == 1` (`.STPlay3DSoundRand(462, 1, 0xab, +0xe)`).
            XCTAssertEqual(w.player.cues.map(\.snd), frame == 0 ? [Burn.sound] : [])
        }
        XCTAssertEqual(tops, [3, 4, 5])
        XCTAssertEqual(w.active.record(id: id)?.burnRow, 5)
        w.standardSpriteCleanup(id, faceWidth: { _ in 4 })              // row 6 > 5: past the opaque bottom
        let s = try XCTUnwrap(w.active.record(id: id))
        XCTAssertEqual([s.dead, s.killedForGood], [true, false])
        // SpriteWorld rule 2: the burn's copy is written back before the Kill proc (which writes the slot by id) and
        // re-read after — the Kill's `+0xe9` and the burn's row 6 / top clip 6 both survive the Cleanup's write-back.
        XCTAssertEqual([Int(s.burnRow), s.clip.top], [6, 6])
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][1])], [0, 1])
        // `+0x8d = 1` (the Chief): two rows a frame.
        let fast = try XCTUnwrap(w.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) { s in
            s.face = FaceRef(pict: 0x6a4, index: 0, set: .encoded)
            s.burnSpeed = 1
            s.burnRow = 1
        })
        w.standardSpriteCleanup(fast, faceWidth: { _ in 4 })
        XCTAssertEqual(w.active.record(id: fast)?.clip.top, 4)
        // A delay: a negative `+0x1a2` counts up with nothing burnt.
        let late = try XCTUnwrap(w.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) { s in
            s.face = FaceRef(pict: 0x6a4, index: 0, set: .encoded)
            s.burnRow = -2
        })
        w.standardSpriteCleanup(late, faceWidth: { _ in 4 })
        XCTAssertEqual([Int(w.active.record(id: late)?.burnRow ?? 0), w.active.record(id: late)?.clip.top ?? -1], [-1, 0])
        // No face pixels (a headless session: no provider): the dump always has the face record behind `+0xc0`, so the
        // burn is a no-op here — no sound, no draw, no state — never a sound replayed every frame.
        let bare = try world()
        let still = try XCTUnwrap(bare.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) { s in
            s.face = FaceRef(pict: 0x6a4, index: 0, set: .encoded)
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 6, right: 0x20)
            s.burnRow = 1
        })
        let seed0 = bare.rng.seed
        for _ in 0..<3 {
            bare.player.cues = []
            bare.standardSpriteCleanup(still, faceWidth: { _ in 4 })
            XCTAssertEqual(bare.player.cues, [])
        }
        let b = try XCTUnwrap(bare.active.record(id: still))
        XCTAssertEqual([Int(b.burnRow), b.clip.top, Int(bare.rng.seed == seed0 ? 1 : 0)], [1, 0, 1])
        XCTAssertEqual([b.burning, b.dead], [false, false])
    }

    // MARK: - goblin voices

    func testGoblinCriesGlobal() throws {
        // `.GoblinRandomCry` M l. 56848–56897: R(100), R(500); at 50 only with none of 465 / 466 / 467 playing.
        let w = try world()
        let id = try XCTUnwrap(w.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) { s in
            s.voicePitch = 0x10000
        })
        let sd = seed { r in _ = r.next(100); return r.next(500) == 0x32 }
        w.voices = SoundVoices(playing: [EnemyCommon.growl1])            // another goblin's 465
        w.rng = FastRand(seed: sd)
        var two = FastRand(seed: sd)
        let r100 = two.next(100)
        _ = two.next(500)
        EnemyCommon.goblinRandomCry(w, id: id)
        XCTAssertEqual(w.player.cues, [])
        XCTAssertEqual(w.rng.seed, two.seed, "no draw beyond R(500)")
        for other in [EnemyCommon.growl2, EnemyCommon.taunt] {           // 466 or 467 on another goblin: the same
            w.voices = SoundVoices(playing: [other])
            w.rng = FastRand(seed: sd)
            EnemyCommon.goblinRandomCry(w, id: id)
            XCTAssertEqual([w.player.cues.count, Int(w.rng.seed == two.seed ? 1 : 0)], [0, 1], "\(other)")
        }
        w.voices = SoundVoices(playing: [EnemyCommon.hurtCry])           // 468 is not tested: the cry plays
        w.rng = FastRand(seed: sd)
        EnemyCommon.goblinRandomCry(w, id: id)
        XCTAssertEqual(w.player.cues.count, 1)
        w.player.cues = []
        w.player.soundCalls = []                                         // this frame's 467 counts as playing
        // Nothing playing: the cry, pitch `+0xf0` + 55000 + R(10000) − 0xffff.
        w.voices = SoundVoices()
        w.rng = FastRand(seed: sd)
        var three = two
        let p = Int32(three.next(10000))
        EnemyCommon.goblinRandomCry(w, id: id)
        let snd: Int16 = r100 < 0x29 ? EnemyCommon.taunt : r100 < 0x47 ? EnemyCommon.growl2 : EnemyCommon.growl1
        XCTAssertEqual(w.player.cues.map(\.snd), [snd])
        XCTAssertEqual(w.player.cues.first?.rate, 0x10000 + 55000 + p - 0xffff)
        XCTAssertEqual(w.rng.seed, three.seed)
        // `.GoblinHurtCry` M l. 56802–56847: R(100) ≥ 0x38 → stop every 465, 466, 468 voice, then the cry; below, silent.
        let loud = seed { r in r.next(100) >= 0x38 }
        w.player.cues = []
        w.rng = FastRand(seed: loud)
        EnemyCommon.goblinHurtCry(w, id: id)
        XCTAssertEqual(w.player.cues.prefix(3).map { [$0.snd, $0.call == .stop ? 1 : 0] },
                       [[EnemyCommon.growl1, 1], [EnemyCommon.growl2, 1], [EnemyCommon.hurtCry, 1]])
        XCTAssertEqual(w.player.cues.count, 4)
        let quiet = seed { r in r.next(100) < 0x38 }
        w.player.cues = []
        w.rng = FastRand(seed: quiet)
        EnemyCommon.goblinHurtCry(w, id: id)
        XCTAssertEqual(w.player.cues, [])
        // `.HurtGoblin` M l. 58472–58505: `.HurtSprite`; the hurt cry (here silent); type 0x6d6 → R(100) > 0x4b → 611,
        // 0x33…0x4b → 612 (`.STPlay3DSoundRandGob`, R(10000)); blood 0x28; HP still > 0 → 701 vol 0x55.
        let rect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x20, right: 0x20)
        let attacker = try XCTUnwrap(w.newSprite(type: 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) {
            $0.hotRect = rect
        })
        for (axe, pick, hp, expected) in [
            (true, 0x4c..<0x4d, Int16(100), [EnemyCommon.axHit1, EnemyCommon.ouch]),     // the boundaries
            (true, 0x4b..<0x4c, 100, [EnemyCommon.axHit2, EnemyCommon.ouch]),
            (true, 0x33..<0x34, 100, [EnemyCommon.axHit2, EnemyCommon.ouch]),
            (true, 0x32..<0x33, 100, [EnemyCommon.ouch]),
            (false, 0x4c..<100, 100, [EnemyCommon.ouch]),
            (true, 0x4c..<100, 5, [EnemyCommon.axHit1]),
        ] as [(Bool, Range<Int16>, Int16, [Int16])] {
            let g = try XCTUnwrap(w.newSprite(type: axe ? 0x6d6 : 0x6a4, x: 100, y: 50, layer: 0xb, handler: .walker) {
                $0.hp = hp
                $0.voicePitch = 0x10000
                $0.hotRect = rect
            })
            w.player.cues = []
            w.particles = ParticlePool()
            w.rng = FastRand(seed: seed { r in r.next(100) < 0x38 && pick.contains(Int16(r.next(100))) })
            XCTAssertTrue(EnemyCommon.hurtGoblin(w, id: g, attacker: attacker, damage: 10, dvx: 0, dvy: 0,
                                                 invulnerable: 4, flash: 8))
            XCTAssertEqual(w.player.cues.map(\.snd), expected, "\(axe) \(pick) \(hp)")
            XCTAssertEqual(particles(w, kind: 2), 0x28)
            XCTAssertEqual(w.active.record(id: g)?.hp, hp - 10)
            XCTAssertFalse(EnemyCommon.hurtGoblin(w, id: g, attacker: attacker, damage: 10, dvx: 0, dvy: 0,
                                                  invulnerable: 4, flash: 8), "invulnerable now: no hurt")
        }
    }

    // MARK: - the Ring of Smiting

    func testSmiteMatchesEnemyHandles() throws {
        // `.SmiteEnemies` M l. 46981–47046: the 15 Handles (TOC 0x100a048c…0x100a04c4; the Warrior's 0x100a0494
        // included — Ruling 3a), the first 16 matches, a seed at the **stored** `+0x10` − 4, `+0xe` − 4 (M l. 47036).
        let w = try world()
        XCTAssertNotNil(Player.spawn(world: w, x: 100, y: 100))
        // The Warrior first, with a stale stored centre (its hot rect would say (100 + 8, 200 + 8)).
        w.newSprite(type: 0x7a8, x: 100, y: 200, layer: 4, handler: .warrior) { s in
            s.hotRect = IdleSprites.Rect(top: 0, left: 0, bottom: 0x10, right: 0x10)
            s.centre = SpriteSlot.Point(x: 31, y: 47)
        }
        w.newSprite(type: 0x6a4, x: 0, y: 0, layer: 4, handler: .inert)            // an unmapped class: no match
        w.newSprite(type: 0x532, x: 0, y: 0, layer: 4, handler: .bonus)
        let idled = try XCTUnwrap(w.newSprite(type: 0x6cc, x: 0, y: 0, layer: 4, handler: .bat))
        w.active.update(id: idled) { $0.handleCleared = true }                   // Handle 0: no match
        let rest = Smite.enemyHandlers.filter { $0 != .warrior }
        for k in 0..<17 {
            w.newSprite(type: 0x6b8, x: 0, y: 0, layer: 4, handler: rest[k % rest.count]) { s in
                s.centre = SpriteSlot.Point(x: 300 + k, y: 400 + k)
                if k == 0 { s.dead = true }                                      // no `+0xe9` test
            }
        }
        Smite.smiteEnemies(w)
        let seeds = w.active.sprites.filter { $0.handler == .playerShot && $0.id != w.player.heldItem }
        XCTAssertEqual(seeds.count, 16)
        XCTAssertEqual(seeds.map(\.oldPosition),
                       [SpriteSlot.Point(x: 27, y: 43)] + (0..<15).map { SpriteSlot.Point(x: 296 + $0, y: 396 + $0) })
        XCTAssertEqual(Smite.enemyHandlers.count, 11)
        XCTAssertTrue(Smite.enemyHandlers.contains(.warrior))
    }
}

extension SpriteHandler {
    /// The EC enemy cases, in declaration order (tests).
    static let allEnemyCases: [SpriteHandler] = [.walker, .crawler, .roach, .dillo, .bat, .swarmMember, .insectBody,
                                                 .gremlin, .floater, .frog, .salamander, .blob, .deadBlob, .crab,
                                                 .crabSegment, .enemyShot, .geyserSegment, .warrior]
}

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
    }

    // MARK: - kills

    func testKillBookkeeping() throws {
        // `.KillCrawler` M l. 56695–56701: `+0xe9 == 0 && +0x1b5` → live − 1, `G+0x306+2L` + 1; `+0xe9 = 1`; `+0xea = 1`.
        let w = try world()
        w.levelIndex = 2
        w.enemies = EnemyCounting(live: 5)
        var crawler = SpriteSlot(type: 0x6b0, x: 0, y: 0)
        crawler.handler = .crawler
        crawler.countedInTotals = true
        EnemyCommon.killProc(w, &crawler)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [4, 1])
        XCTAssertEqual([crawler.killCount == 1, crawler.killedForGood], [true, true])
        EnemyCommon.killProc(w, &crawler)                       // once: `+0xe9` is set now
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [4, 1])
        // `.KillWalker` (M l. 58624–58629) stores no `+0xea`.
        var walker = SpriteSlot(type: 0x6a4, x: 0, y: 0)
        walker.handler = .walker
        walker.countedInTotals = true
        EnemyCommon.killProc(w, &walker)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [3, 2])
        XCTAssertEqual([walker.killCount == 1, walker.killedForGood], [true, false])
        // An uncounted kill (a pipe child, a spawned or re-activated sprite: `+0x1b5` 0): no count, no stat, `+0xe9` 1.
        var child = SpriteSlot(type: 0x6b8, x: 0, y: 0)
        child.handler = .roach
        EnemyCommon.killProc(w, &child)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [3, 2])
        XCTAssertEqual([child.killCount == 1, child.killedForGood], [true, true])
        // `.KillGremlinSprite` (M l. 69739) tests `+0x1b5` only: a second call counts again.
        var gremlin = SpriteSlot(type: 0x6f4, x: 0, y: 0)
        gremlin.handler = .gremlin
        gremlin.countedInTotals = true
        gremlin.killCount = 1
        EnemyCommon.killProc(w, &gremlin)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [2, 3])
        // The `+0xea` classes (scan of the enemy Kills).
        XCTAssertEqual(SpriteHandler.allEnemyCases.filter(EnemyCounting.killsForGood),
                       [.crawler, .roach, .dillo, .bat, .gremlin, .frog, .salamander, .blob, .warrior])
        // Without a Kill proc (`+0x50 == 0`): `+0xe9 = 1` only.
        var other = SpriteSlot(type: 1, x: 0, y: 0)
        other.handler = .box
        other.countedInTotals = true
        EnemyCommon.killProc(w, &other)
        XCTAssertEqual([w.enemies.live, Int32(w.globals.achieved[0][2])], [2, 3])
        XCTAssertTrue(other.dead)
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
        for (h, damage, lost) in [(SpriteHandler.crawler, 0x38, 0...0), (.gremlin, 0xe0, 4...6)]
                as [(SpriteHandler, Int, ClosedRange<Int16>)] {
            let v = try world()
            let (q, e) = try contact(v, handler: h, type: 0x6b0)
            HitPlayerSprite.hit(v, player: q, other: e)
            XCTAssertEqual([Int(v.active.record(id: q)?.hp ?? 0), Int(v.active.record(id: q)?.invulnerable ?? 0)],
                           [1000 - damage, 0x3c], "\(h)")
            XCTAssertTrue(lost.contains(v.player.coinsLost), "\(h): 5 coins → R(3) + 4")
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

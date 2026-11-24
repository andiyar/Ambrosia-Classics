import XCTest
@testable import FerazelCore

/// 6A-BD (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-BD`; docs/ferazel/phase6-engine-contracts.md
/// §2.9): the rotating blade 0xbf4 (3060) — the Setup arm of `.SetupBackgroundSprite` (M l. 62571–62583), the Handle arm
/// (M l. 63511–63530), the `.HitPlayerSprite` arm (M l. 49684–49724) and the segment routines `.SectLineSegs` (M l.
/// 39507–39561) and `.SectRectLineSeg` (M l. 39562–39601). The Setup is read per record from the level files (levels
/// 20, 22, 30, 62 place the blade; `SetupFaces.setup`, no level opened); the Handle and the hit run on synthetic blades
/// in level 20's world; the segment routines on synthetic segments. A missing data file is a FAILURE, never a skip.
final class BladeTests: XCTestCase {

    private typealias Rect = IdleSprites.Rect

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The blade's records on `level`, from the level file.
    private func blades(_ level: Int) throws -> (LevelFile, [Placement]) {
        let L = try LevelFile.load(from: try resources(), level: Int16(level))
        return (L, L.activePlacements.filter { $0.type == 3060 })
    }

    /// Level 20's world (its records as `w.records`) holding a player at (px, py) with the standard hot rect.
    private func world(playerX px: Int = 1100, playerY py: Int = 1035) throws -> (SpriteWorld, Int) {
        let w = SpriteWorld(level: try LevelFile.load(from: try resources(), level: 20))
        let p = try XCTUnwrap(Player.spawn(world: w, x: px, y: py))
        w.playerID = p
        place(w, p, x: px, y: py)
        return (w, p)
    }

    /// Sprite `id` moved to (x, y) with its centre recomputed from its hot rect (`.StandardSpriteCleanup`'s rule).
    private func place(_ w: SpriteWorld, _ id: Int, x: Int, y: Int) {
        w.active.update(id: id) { s in
            s.x = x
            s.y = y
            s.centre.x = x + s.hotRect.left + ((s.hotRect.right - s.hotRect.left) >> 1)
            s.centre.y = y + s.hotRect.top + ((s.hotRect.bottom - s.hotRect.top) >> 1)
        }
    }

    private func rec(p1: Int16 = 0, p2: Int16 = 0, p3: Int16 = 0, p4: Int16 = 1, index: Int = 93, x: Int16 = 1000,
                     y: Int16 = 1000) -> Placement {
        Placement(index: index, flag: 1, byte1: 0, type: 3060, p1: p1, p2: p2, p3: p3, p4: p4, y: y, x: x)
    }

    /// A blade set up for record `p` (`SetupFaces.setup`) and inserted into `w` at (x, y); `w.records[p.index]` = `p`
    /// so the Handle reads its p4 from it, as the original reads the live record.
    private func blade(_ w: SpriteWorld, _ p: Placement) throws -> Int {
        let e = try SetupFaces.setup(p, context: SetupFaces.Context(level: w.level, playerX: 0))
        if w.records.indices.contains(p.index) { w.records[p.index] = p }
        let id = w.active.insert(e.slot)
        place(w, id, x: Int(p.x), y: Int(p.y))
        return id
    }

    /// One Handle of sprite `id`.
    @discardableResult
    private func handle(_ w: SpriteWorld, _ id: Int) throws -> SpriteSlot {
        let r = try resources()
        BackgroundSprite.handle(world: w, id: id) { FerazelSession.frameRect($0, resources: r).right }
        return try XCTUnwrap(w.active.sprite(id: id))
    }

    // MARK: - the Setup arm (M l. 62571–62583)

    func testBladeSetupFields() throws {
        // The data (ENG §2.9 "Switch", re-read): 28 on level 20 (p4 1; p1 1 on one, record 257), 13 on 22 (p4 0), 3
        // on 30 (p4 1; p1 180 on one), 9 on 62 (p4 0); every p2 and p3 0.
        var census: [Int: [Int]] = [:]
        for level in [20, 22, 30, 62] {
            let (L, list) = try blades(level)
            census[level] = [list.count, list.filter { $0.p4 == 0 }.count, list.filter { $0.p1 != 0 }.count]
            let c = SetupFaces.Context(level: L, playerX: 0)
            for p in list {
                XCTAssertEqual([p.p2, p.p3], [0, 0], "level \(level) record \(p.index)")
                var rng = FastRand(seed: 7)
                let e = try SetupFaces.setup(p, context: c, rng: &rng)
                XCTAssertEqual(rng.seed, FastRand(seed: 7).seed, "level \(level) record \(p.index): no random draw")
                XCTAssertEqual(e.spriteClass, .background)
                XCTAssertEqual(e.record, p, "the Setup writes nothing back")
                let s = e.slot
                // `+0x46` = p2 (M l. 62573–62574); `+0x150` = p3, 0 → 8 (M l. 62575–62579).
                XCTAssertEqual(s.phase, p.p2, "level \(level) record \(p.index)")
                XCTAssertEqual(s.classWord150, 8, "level \(level) record \(p.index)")
                // `.SetRect(+0x34, 5, 5, 0xb5, 0xb5)`; callbacks `+0x5c` / `+0x1f8` 0 (M l. 62580–62582).
                XCTAssertEqual(s.hotRect, Rect(top: 5, left: 5, bottom: 0xb5, right: 0xb5))
                XCTAssertEqual([s.hasHit, s.hasTileHit], [false, false])
                // The common head (`setupCommon`): layer 1, HP 6, `+0xa6` 3.
                XCTAssertEqual([Int(s.layer), Int(s.hp), Int(s.counterA6)], [1, 6, 3])
                // None of the Handle's stores at Setup: no rotation, no dynamic light, the open clip, mode 0.
                XCTAssertEqual([Int(s.rotation), Int(s.mode)], [0, 0])
                XCTAssertFalse(s.dynamicLight)
                XCTAssertEqual(s.clip, SpriteClip(left: 0, right: 32000, bottom: 32000, top: 0))
                // `+0xc0` stays 0 (M l. 62571–62583 store no face): the face is the Handle's (`.handle`, the cache
                // single 0xbf4 the level-start draw names).
                XCTAssertEqual(e.source, .handle)
                XCTAssertEqual(s.face, FaceRef(pict: 0xbf4, index: 0, set: .encoded))
                XCTAssertEqual(e.sheet, .single(0xbf4))
            }
        }
        XCTAssertEqual(census, [20: [28, 0, 1], 22: [13, 13, 0], 30: [3, 0, 1], 62: [9, 9, 0]])
        XCTAssertEqual(try blades(20).1.first { $0.p1 != 0 }.map { [$0.index, Int($0.p1)] }, [257, 1])
        XCTAssertEqual(try blades(30).1.first { $0.p1 != 0 }.map { Int($0.p1) }, 180)
        // The cache single `_DAT_100a0b0c` (`.InitBackgroundSprite` M l. 61876–61878, under the conversion CLUT clut 200)
        // is marked: `*(_DAT_100a0b0c + 1) = 1` (M l. 62572) — single #136 (0-based 135).
        XCTAssertEqual(CachedFaces.markedRecords(type: 3060), [.single(135)])
        XCTAssertEqual(CachedFaces.record(.single(135)).pict, 0xbf4)
        XCTAssertEqual(SetupFaces.sheet(pict: 0xbf4), .single(0xbf4, clut: 200))
        // p3 ≠ 0 is the speed as written (synthetic: no level places one).
        let (w, _) = try world()
        let e = try SetupFaces.setup(rec(p2: -30, p3: -5), context: SetupFaces.Context(level: w.level, playerX: 0))
        XCTAssertEqual([Int(e.slot.phase), Int(e.slot.classWord150)], [-30, -5])
    }

    // MARK: - the Handle arm (M l. 63511–63530)

    func testBladeHandleSpinsAndWraps() throws {
        let (w, _) = try world()
        let id = try blade(w, rec())
        // Every Handle: the face from the cache single (M l. 63512) — taken even when the record had none; angle +=
        // speed (16-bit); rotation `+0x1aa` = angle; `+0x88 = 0`, `+0x89 = 1` (M l. 63524–63526).
        var angles: [Int] = []
        for k in 0..<46 {
            w.active.update(id: id) { $0.face = nil; $0.lightOverlay = true; $0.dynamicLight = false }
            let s = try handle(w, id)
            XCTAssertEqual(s.face, FaceRef(pict: 0xbf4, index: 0, set: .encoded), "Handle \(k)")
            XCTAssertFalse(s.lightOverlay, "Handle \(k): +0x88 = 0")
            XCTAssertTrue(s.dynamicLight, "Handle \(k): +0x89 = 1")
            XCTAssertEqual(s.rotation, s.phase, "Handle \(k)")
            angles.append(Int(s.phase))
        }
        // Speed 8 (p3 0): 8, 16, …, 352, then 360 → 0 (≥ 360 → − 360, M l. 63521–63522), a turn every 45 Handles.
        XCTAssertEqual(Array(angles.prefix(45)), (1...45).map { ($0 * 8) % 360 })
        XCTAssertEqual(angles[44], 0)
        XCTAssertEqual(angles[45], 8)

        // The negative wrap (< 0 → + 360, M l. 63517–63518): p3 −8 from 0 → 352, 344, …
        let back = try blade(w, rec(p3: -8, index: 95))
        XCTAssertEqual(try handle(w, back).phase, 352)
        XCTAssertEqual(try handle(w, back).phase, 344)
        // One step each way only (synthetic speeds no level places): 0 + 400 → 40; 0 − 400 → −40 (still negative);
        // 300 + 500 = 800 → 440 (still ≥ 360).
        XCTAssertEqual(try handle(w, try blade(w, rec(p3: 400, index: 241))).phase, 40)
        XCTAssertEqual(try handle(w, try blade(w, rec(p3: -400, index: 242))).phase, -40)
        XCTAssertEqual(try handle(w, try blade(w, rec(p2: 300, p3: 500, index: 243))).phase, 440)
        // 16-bit: 0x7ff0 + 0x20 wraps to −0x7ff0 before the test, then + 360.
        XCTAssertEqual(try handle(w, try blade(w, rec(p2: 0x7ff0, p3: 0x20, index: 244))).phase, -0x7ff0 + 360)
        // The bounds exactly (M l. 63515–63522: `< 0x168`, then `< 0`): 359 stays, 0 stays, −1 → 359.
        XCTAssertEqual(try handle(w, try blade(w, rec(p2: 351, p3: 8, index: 245))).phase, 359)
        XCTAssertEqual(try handle(w, try blade(w, rec(p2: 8, p3: -8, index: 246))).phase, 0)
        XCTAssertEqual(try handle(w, try blade(w, rec(p2: 7, p3: -8, index: 247))).phase, 359)
        // The Handle draws no random.
        let seed = w.rng.seed
        for _ in 0..<10 { try handle(w, id) }
        XCTAssertEqual(w.rng.seed, seed)
    }

    func testBladeBottomClipWhenP4Zero() throws {
        // p4 = 0 → bottom clip `+0x1ba = 0x5e` every Handle (M l. 63527–63529), after `.StandardSpriteHandles`' reset to
        // 32000 — read from the live record. Every blade of levels 22 and 62 has p4 0; every one of 20 and 30 p4 1.
        for level in [20, 22, 30, 62] {
            let (L, list) = try blades(level)
            let w = SpriteWorld(level: L)
            for p in list {
                let id = try blade(w, p)
                for k in 0..<2 {
                    let s = try handle(w, id)
                    XCTAssertEqual(s.clip, SpriteClip(left: 0, right: 32000, bottom: p.p4 == 0 ? 0x5e : 32000, top: 0),
                                   "level \(level) record \(p.index) Handle \(k)")
                }
            }
        }
        // The live record decides: a blade whose record's p4 turns 0 is clipped from the next Handle; back to 1, the
        // reset leaves 32000.
        let (w, _) = try world()
        let id = try blade(w, rec(p4: 1))
        XCTAssertEqual(try handle(w, id).clip.bottom, 32000)
        w.records[93] = rec(p4: 0)
        XCTAssertEqual(try handle(w, id).clip.bottom, 0x5e)
        w.records[93] = rec(p4: 7)
        XCTAssertEqual(try handle(w, id).clip.bottom, 32000)
    }

    // MARK: - the segment routines (M l. 39507–39601)

    func testSectLineSegsCrossTouchAndMiss() throws {
        let s = LineSegments.sectLineSegs
        XCTAssertTrue(s(0, 0, 10, 10, 0, 10, 10, 0), "an X")
        XCTAssertTrue(s(0, 0, 10, 0, 5, 0, 5, 10), "a T: one end on the other segment (a zero product)")
        XCTAssertTrue(s(0, 0, 10, 0, 10, 0, 20, 5), "end to end")
        XCTAssertFalse(s(0, 0, 10, 0, 0, 5, 10, 5), "parallel")
        XCTAssertFalse(s(0, 0, 10, 0, 20, -5, 20, 5), "the second's line crosses the first's, not the segment")
        XCTAssertFalse(s(0, 0, 10, 10, 20, 0, 11, 9), "both of the second's ends on one side")
        XCTAssertTrue(s(0, 10, 10, 0, 0, 0, 10, 10), "order-free")
        // i32 arithmetic (`mullw`, wrapping): coordinates whose products pass 2³¹ give the wrapped answer, not the
        // exact one — measured: exact arithmetic says crossing for the first and none for the second.
        XCTAssertFalse(s(23218, 21652, -17182, -26976, -26878, 16751, 10610, 3810))
        XCTAssertTrue(s(-6755, 23578, -26299, -31046, 30283, -16933, -10248, 6538))
    }

    func testSectLineSegsCollinearDisjointHits() throws {
        // Collinear segments: every product is 0, so neither "same side" test fires — a hit even with a gap between
        // them (ENG §2.9 assert 5).
        let s = LineSegments.sectLineSegs
        XCTAssertTrue(s(0, 0, 1, 0, 5, 0, 6, 0))
        XCTAssertTrue(s(0, 0, 1, 1, 50, 50, 60, 60))
        XCTAssertTrue(s(3, 0, 3, 2, 3, 100, 3, 200))
        // A point (zero-length segment) on the other's line, anywhere along it.
        XCTAssertTrue(s(0, 0, 10, 0, 40, 0, 40, 0))
        // Off the line by one: no hit.
        XCTAssertFalse(s(0, 0, 1, 0, 5, 1, 6, 1))
    }

    func testSectRectLineSegEdgesAndInside() throws {
        let r = Rect(top: 100, left: 200, bottom: 150, right: 260)
        let s = LineSegments.sectRectLineSeg
        XCTAssertTrue(s(r, 230, 80, 230, 120), "across the top")
        XCTAssertTrue(s(r, 230, 130, 230, 170), "across the bottom")
        XCTAssertTrue(s(r, 180, 120, 210, 120), "across the left")
        XCTAssertTrue(s(r, 250, 120, 280, 120), "across the right")
        XCTAssertTrue(s(r, 180, 90, 280, 160), "through")
        XCTAssertTrue(s(r, 260, 150, 300, 190), "from a corner (touching)")
        XCTAssertTrue(s(r, 230, 60, 230, 100), "ending on the top edge (touching)")
        XCTAssertFalse(s(r, 210, 110, 250, 140), "wholly inside: no containment test")
        XCTAssertFalse(s(r, 100, 10, 150, 60), "wholly outside")
        XCTAssertFalse(s(r, 230, 151, 230, 190), "below, one off the bottom edge")
        // Collinear with an edge's line but off the edge: still a hit (the edge's segment test).
        XCTAssertTrue(s(r, 400, 100, 420, 100), "on the top edge's line, beyond it")
        // The edges are the 16-bit fields as stored: a field past 16 bits reads as its low half.
        let wide = Rect(top: 100 + 0x10000, left: 200, bottom: 150 + 0x10000, right: 260)
        XCTAssertTrue(s(wide, 230, 80, 230, 120), "across the top at 100, not 65636")
    }

    // MARK: - the player arm (M l. 49684–49724)

    func testBladeArmEndpoints() throws {
        // P1 = (fctiwz(16·cos + cx), fctiwz(cy − 16·sin)), P2 the same with 88 (`fmadd` / `fnmsub`, raw
        // `1005827c..100582a8`; the tables `.BuildTintTable` builds with π = 3.1415926535 as stored). With that π
        // cos 90° and sin 180° are not 0 and cos 270° is negative: truncation moves those ends by one pixel.
        let e = { (a: Int16) in BackgroundSprite.bladeArm(angle: a, cx: 1000, cy: 500).map { [$0.x1, $0.y1, $0.x2, $0.y2] } }
        XCTAssertEqual(e(0), [1016, 500, 1088, 500])
        XCTAssertEqual(e(90), [1000, 484, 1000, 412])
        XCTAssertEqual(e(180), [984, 499, 912, 499])
        XCTAssertEqual(e(270), [999, 516, 999, 588])
        XCTAssertEqual(e(45), [1011, 488, 1062, 437])
        XCTAssertEqual(e(352), [1015, 502, 1087, 512])
        // fctiwz truncates toward zero, not down: a hub near the origin puts the ends at negative fractions.
        XCTAssertEqual(BackgroundSprite.bladeArm(angle: 135, cx: 10, cy: 10).map { [$0.x1, $0.y1, $0.x2, $0.y2] },
                       [-1, -1, -52, -52])
        // The table entries as built.
        XCTAssertEqual(BackgroundSprite.bladeCos[0], 1.0)
        XCTAssertEqual(BackgroundSprite.bladeSin[90], 1.0)
        XCTAssertEqual(BackgroundSprite.bladeCos[90], 4.489659216976159e-11)
        XCTAssertEqual(BackgroundSprite.bladeSin[180], 8.979318433952318e-11)
        XCTAssertEqual(BackgroundSprite.bladeCos.count, 360)
        // An angle outside the 360-entry tables reads other memory in the original: no arm (no level reaches one).
        XCTAssertNil(e(360))
        XCTAssertNil(e(-1))
    }

    /// The player's body rect as the arm builds it (M l. 49685–49689): his rect at his position, top + 6, bottom − 8.
    private func body(_ s: SpriteSlot) -> Rect {
        Rect(top: s.y + s.hotRect.top + 6, left: s.x + s.hotRect.left, bottom: s.y + s.hotRect.bottom - 8,
             right: s.x + s.hotRect.right)
    }

    func testBladeHitKnockbackAndCoins() throws {
        // A crossing: `.HurtPlayer(player, blade, 0x70, blood 0, invul 0x3c, coins)` with the blade's vx at +0x8fc
        // (blade centre x < player's) or −0x8fc, coins = R(100) < 0x33 ? 0 : 4 drawn before the hurt.
        var arms: Set<Int16> = []
        for seed: Int32 in 1...40 {
            // Angle 0: the arm runs from (1109, 1093) to (1181, 1093); the player's body x 1138…1162, y 1075…1112.
            let (w, p) = try world()
            let b = try blade(w, rec())
            XCTAssertTrue(LineSegments.sectRectLineSeg(body(try XCTUnwrap(w.active.sprite(id: p))), 1109, 1093, 1181, 1093))
            w.globals.coins = 10
            w.active.update(id: p) { $0.hp = 0x230; $0.vx = 0x40; $0.vy = 0 }
            w.rng = FastRand(seed: seed)
            var r = FastRand(seed: seed)
            let coinsArm: Int16 = r.next(100) < 0x33 ? 0 : 4
            arms.insert(coinsArm)
            _ = r.next(10000); let cry = r.next(3)                            // dmg < 0xe0: 508 pitched, then 401–403
            var lost: Int16 = 0
            if coinsArm == 4 { lost = r.next(3) + 3 }                          // n > 2 → R(3) + n − 1, capped at 10
            HitPlayerSprite.hit(w, player: p, other: b)
            let s = try XCTUnwrap(w.active.sprite(id: p))
            XCTAssertEqual(s.hp, 0x230 - 0x70, "seed \(seed)")
            XCTAssertEqual(s.invulnerable, 0x3c, "seed \(seed)")
            XCTAssertEqual(s.vx, 0x40 + 0x8fc, "seed \(seed): the blade is left of him")
            XCTAssertEqual(s.vy, -1000)
            XCTAssertEqual(w.player.coinsLost, lost, "seed \(seed)")
            XCTAssertEqual(w.globals.coins, 10 - lost, "seed \(seed)")
            XCTAssertEqual(w.particles.counters.count, 0, "blood 0: no spray")
            XCTAssertEqual(w.player.cues.prefix(2).map(\.snd), [508, [401, 402, 403][Int(cry)]], "seed \(seed)")
            if lost == 0 { XCTAssertEqual(w.rng.seed, r.seed, "seed \(seed): R(100), R(10000), R(3) and nothing else") }
        }
        XCTAssertEqual(arms, [0, 4], "both coin arms met")
        // The coin threshold exactly (M l. 49723 `< 0x33`): a draw of 0x32 loses nothing, 0x33 loses coins.
        for (draw, loses) in [(Int16(0x32), false), (Int16(0x33), true)] {
            let seed = try XCTUnwrap((Int32(1)...Int32(100_000)).first { var r = FastRand(seed: $0); return r.next(100) == draw })
            let (w, p) = try world()
            let b = try blade(w, rec())
            w.globals.coins = 10
            w.rng = FastRand(seed: seed)
            HitPlayerSprite.hit(w, player: p, other: b)
            XCTAssertEqual(w.player.coinsLost > 0, loses, "R(100) = \(draw)")
        }

        // The strict `<` (M l. 49716): equal centres push −0x8fc. Angle 90 runs the arm up from (1093, 1077) to
        // (1093, 1005); his body x 1081…1105 (centre 1093), y 1040…1077.
        let (w, p) = try world(playerX: 1043, playerY: 1000)
        let b = try blade(w, rec(p2: 90))
        XCTAssertEqual(w.active.sprite(id: p)?.centre.x, w.active.sprite(id: b)?.centre.x)
        w.active.update(id: p) { $0.vx = 0 }
        HitPlayerSprite.hit(w, player: p, other: b)
        XCTAssertEqual(w.active.sprite(id: p)?.vx, -0x8fc)
        // The blade right of him (angle 180: the arm from (1077, 1092) left to (1005, 1092)): −0x8fc.
        let (w2, p2) = try world(playerX: 990, playerY: 1035)
        let b2 = try blade(w2, rec(p2: 180))
        w2.active.update(id: p2) { $0.vx = 0; $0.hp = 0x230 }
        HitPlayerSprite.hit(w2, player: p2, other: b2)
        XCTAssertEqual(w2.active.sprite(id: p2)?.vx, -0x8fc)
        XCTAssertEqual(w2.active.sprite(id: p2)?.hp, 0x230 - 0x70)
    }

    func testBladeNoDrawWithoutCrossing() throws {
        // Overlapping rects but no crossing → return before the R(100) (M l. 49711–49713): no draw, no hurt, no cue.
        // Angle 0 at y 1093; the body band is the rect's top + 6 … bottom − 8.
        func hitAt(playerY py: Int, angle: Int16 = 0) throws -> (hurt: Bool, draws: Bool) {
            let (w, p) = try world(playerX: 1100, playerY: py)
            let b = try blade(w, rec(p2: angle))
            let seed = w.rng.seed
            let hp = w.active.sprite(id: p)?.hp
            HitPlayerSprite.hit(w, player: p, other: b)
            return (w.active.sprite(id: p)?.hp != hp, w.rng.seed != seed || !w.player.cues.isEmpty)
        }
        // His rect's top at 1090 (py 1056): inside the rect's top 6 rows but above the body's top 1096 → no crossing.
        XCTAssertEqual(try hitAt(playerY: 1056).hurt, false)
        XCTAssertEqual(try hitAt(playerY: 1056).draws, false)
        // py 1053: the body's top is 1093, the arm's row — touching counts.
        XCTAssertEqual(try hitAt(playerY: 1053).hurt, true)
        // His rect's bottom at 1095 (py 1010): within the rect's last 8 rows → the body's bottom 1087 is above the arm.
        XCTAssertEqual(try hitAt(playerY: 1010).hurt, false)
        XCTAssertEqual(try hitAt(playerY: 1010).draws, false)
        XCTAssertEqual(try hitAt(playerY: 1016).hurt, true)
        // One row off each band edge (the + 6 and − 8 exactly): py 1054 → body top 1094; py 1015 → body bottom 1092.
        XCTAssertEqual(try hitAt(playerY: 1054).hurt, false)
        XCTAssertEqual(try hitAt(playerY: 1015).hurt, false)
        // The arm wholly inside his body (no containment test): a body around the whole arm — none here, the arm is 72
        // px long and his body 24 wide; instead the arm pointing away (angle 180 from a blade left of him) misses.
        XCTAssertEqual(try hitAt(playerY: 1035, angle: 180).draws, false)
        // The arm's first 16 px are not part of it: the body over the hub only (x 1081…1105 against an arm from 1109).
        let (w, p) = try world(playerX: 1043, playerY: 1035)
        let b = try blade(w, rec())
        let seed = w.rng.seed, hp = w.active.sprite(id: p)?.hp
        HitPlayerSprite.hit(w, player: p, other: b)
        XCTAssertEqual(w.rng.seed, seed)
        XCTAssertEqual(w.active.sprite(id: p)?.hp, hp)
    }

    func testBladeHitRestoresVx() throws {
        // The blade's vx is saved before the push and restored after `.HurtPlayer` (M l. 49715, 49730), whether or not
        // the hurt landed; the R(100) is drawn either way.
        let (w, p) = try world()
        let b = try blade(w, rec())
        w.active.update(id: b) { $0.vx = 0x123 }
        w.active.update(id: p) { $0.vx = 0; $0.hp = 0x230 }
        HitPlayerSprite.hit(w, player: p, other: b)
        XCTAssertEqual(w.active.sprite(id: b)?.vx, 0x123)
        XCTAssertEqual(w.active.sprite(id: p)?.vx, 0x8fc, "the push was the blade's ±0x8fc, not its own 0x123")
        // Invulnerable: no hurt, but the R(100) is drawn and the vx restored.
        let seed = w.rng.seed
        w.active.update(id: b) { $0.vx = -77 }
        HitPlayerSprite.hit(w, player: p, other: b)
        var r = FastRand(seed: seed)
        _ = r.next(100)
        XCTAssertEqual(w.rng.seed, r.seed)
        XCTAssertEqual(w.active.sprite(id: b)?.vx, -77)
        XCTAssertEqual(w.active.sprite(id: p)?.hp, 0x230 - 0x70)
        XCTAssertEqual(w.active.sprite(id: p)?.vx, 0x8fc)
    }

    func testBladeIgnoresP1() throws {
        // Neither arm reads p1 (M l. 62571–62583, 63511–63530; the hit arm reads no record): level 20's record 257
        // (p1 1) and level 30's p1-180 blade behave as the same record with p1 0, Setup, Handles and hit.
        func run(_ p: Placement) throws -> [Int] {
            let (w, pl) = try world()
            let b = try blade(w, Placement(index: 93, flag: 1, byte1: 0, type: 3060, p1: p.p1, p2: p.p2, p3: p.p3,
                                           p4: p.p4, y: 1000, x: 1000))
            var out: [Int] = []
            for _ in 0..<45 {
                let s = try handle(w, b)
                out += [Int(s.phase), Int(s.rotation), Int(s.clip.bottom), s.dynamicLight ? 1 : 0]
            }
            w.active.update(id: b) { $0.phase = 0 }
            HitPlayerSprite.hit(w, player: pl, other: b)
            out += [Int(w.active.sprite(id: pl)?.hp ?? 0), Int(w.rng.seed)]
            return out
        }
        let twenty = try XCTUnwrap(try blades(20).1.first { $0.index == 257 })
        let thirty = try XCTUnwrap(try blades(30).1.first { $0.p1 == 180 })
        for p in [twenty, thirty] {
            let zero = Placement(index: p.index, flag: 1, byte1: 0, type: 3060, p1: 0, p2: p.p2, p3: p.p3, p4: p.p4,
                                 y: p.y, x: p.x)
            XCTAssertEqual(try run(p), try run(zero), "p1 \(p.p1)")
            let c = SetupFaces.Context(level: try LevelFile.load(from: try resources(), level: 20), playerX: 0)
            XCTAssertEqual(try SetupFaces.setup(p, context: c).slot, try SetupFaces.setup(zero, context: c).slot)
        }
    }
}

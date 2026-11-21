import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L15 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L15`): level 15 "Storm Valley" enterable —
/// every one of its 183 records sets up (38 types; LL §4 "Level 15"; none refused since 6A-BG1c), its header switches as
/// read (OmniPx mode 1 — the rain, thunder and side push 6A-RN built —, the water-surface effect, the landing damage,
/// the music), the picture cache's marks, `BuiltLevels.list` = [1…5, 10, 11, 15], and the Gremlins' composite parts and
/// the Dillos across the level's idling. The parameter trace ("Every level task"): every built type placed here whose
/// p1…p4 take a value no level 1–5, 10 or 11 record of that type has, and the types first placed here that the card
/// names (the springs, the Bonus 1293 / 3102 / 3219 / 3223, the Gremlin, the Dillo), each traced through its Setup /
/// Handle arm in the dump and pinned by one assert inside `testLevel15SetsUpEveryRecord`. Against the committed
/// `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip. Proof-B rules: plain Swift, no
/// `@MainActor` class, no Foundation string search.
final class LevelFifteenTests: XCTestCase {

    func testLevel15SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 15)
        let census = try TenEleven.census(r, level: 15)
        XCTAssertEqual(census.records, 183)
        XCTAssertEqual(census.types, 38)
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record (the card's 38 are built)")
        XCTAssertEqual(census.created, 183)
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")

        // The header switches new against levels 1–5 (LL §4 "Level 15" item 1), as read.
        let h = L.header
        XCTAssertEqual(h.name, "Storm Valley")
        XCTAssertEqual([Int(h.omniPxMode), Int(h.waterSurfaceEffect)], [1, 1], "0x26c7 / 0x26c9")
        XCTAssertEqual([h.landingDamage, h.sidePush, h.music], [56, -320, 5], "0x270e / 0x272c / 0x284a")
        XCTAssertEqual([Int(h.submergedFaces), Int(h.parallaxRipple), Int(h.startFacingLeft), Int(h.inLiquid)],
                       [0, 0, 0, 0], "0x26c6 / 0x26ca / 0x26c8 / 0x26cd")
        XCTAssertEqual([h.cameraOffsetY, h.iceSlipperiness, h.waterCurrent, h.stripPict, h.autoScrollEnable,
                        h.arenaBound, h.flameMode, h.chapter, h.darknessEnable], [0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual([h.startX, h.startY], [104, 1254])
        // The music cue: New Game at level 15 (the hidden `FerazelLevel` switch) plays the level's own track 5; no
        // chapter card (hdr 0x273c 0); the player starts facing right.
        let rig = TenElevenRig(r, start: 15)
        rig.newGame(level: 15)
        XCTAssertEqual(rig.plays, [5])
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 5)
        let session = try XCTUnwrap(run.session)
        XCTAssertEqual([session.globals.startFacing, session.world.player.facing], [0, 2], "facing right")
        // The landing damage at work at level 15's own value: the damaging surface takes 0x270e = 56 HP (`Player
        // .surfaceMaterial`, the player's 0 → 0x70 default not reached); no ice (0x2710 0 → `0694` 800, `+0x112` 0).
        do {
            let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 15)
            let w = s.world
            let pid = try XCTUnwrap(w.playerID)
            w.active.update(id: pid) { $0.material = 3 }
            Player.surfaceMaterial(w, id: pid)
            XCTAssertEqual([Int(w.player.ice), Int(try XCTUnwrap(w.active.record(id: pid)).slip)], [800, 0])
            w.active.update(id: pid) { $0.material = 2; $0.invulnerable = 0 }
            let hp0 = try XCTUnwrap(w.active.record(id: pid)).hp
            Player.surfaceMaterial(w, id: pid)
            XCTAssertEqual(hp0 - (try XCTUnwrap(w.active.record(id: pid)).hp), 56)
        }

        // The picture cache (LL §4 item 6, the new types' marks as 1-based list positions — `.set(n − 1)` here): every
        // one is marked; the opened session needs exactly the Setups' marks; the bar on a fresh cache, measured.
        let expected: [CachedFaces.RecordKey] = [
            .set(14), .set(15), .set(16), .set(17), .set(28), .set(29), .set(31), .set(50), .set(51), .set(52), .set(53),
            .set(88), .set(89), .set(90), .single(1), .single(12), .single(82), .single(140), .single(141), .single(142),
            .single(160), .single(161), .single(162), .single(165), .single(171),
        ]
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(h))
        let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
        XCTAssertEqual(setUp.count, L.activePlacements.count)
        let marks = Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) })
        for k in expected { XCTAssertTrue(marks.contains(k), "\(k)") }
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 15)
        let needed = CachedFaces.needed(by: s)
        XCTAssertEqual(Set(needed.records), marks, "the opened session needs the Setups' marks")
        var cache = CachedFaces()
        cache.enterLevel(screenClut: h.screenClut)
        let bars = cache.load(needed: needed)
        let q = Int(bars.first?.1 ?? 0)
        XCTAssertEqual([marks.count, q / 2, q, bars.count], [32, 111, 222, 32], "measured (needed records, n, q, steps)")
        // The bar's own steps: p starts at n and grows by each record's faces, so the last step fills it (p = q).
        XCTAssertEqual([bars.first?.0, bars.last?.0], [119, 222], "measured: the first step; the last fills the bar")

        try traceLevel15(r, L)
    }

    /// The parameter trace of level 15 (the script's list and each value's dump line are in the commit body). One
    /// assert each.
    private func traceLevel15(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 15)
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }
        /// Record `i` with p1…p4 replaced (all 0 by default).
        func with(_ i: Int, _ p1: Int16 = 0, _ p2: Int16 = 0, _ p3: Int16 = 0, _ p4: Int16 = 0) -> Placement {
            let p = rec(i)
            return Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: p1, p2: p2, p3: p3, p4: p4,
                             y: p.y, x: p.x)
        }

        // The springs 1150 (0x47e, ×9), 1152 (0x480, record 134), 1153 (0x481, records 132 / 133), p1…p4 all 0 — the
        // spring arms of `.SetupBackgroundSprite` (M l. 62186–62219; no record word read): the hot rect by type
        // (`SetRect(l, t, r, b)` 0x47e (4, 10, 0x38, 0x3c), 0x480 (0, 4, 0x32, 0x2e), 0x481 (10, 4, 0x3c, 0x2e)),
        // `+0xb8` untouched (hdr 0x26cd 0); the Handle's arm (`BackgroundSprite.spring`) faces 0x481 from 0x480's set,
        // mirrored.
        XCTAssertEqual(L.activePlacements.filter { $0.type == 1150 }.count, 9)
        for (i, rect) in [(3, [10, 4, 0x3c, 0x38]), (134, [4, 0, 0x2e, 0x32]), (132, [4, 10, 0x2e, 0x3c]),
                          (133, [4, 10, 0x2e, 0x3c])] {
            let k = try setup(i).slot
            XCTAssertEqual([k.hotRect.top, k.hotRect.left, k.hotRect.bottom, k.hotRect.right], rect, "spring \(i)")
            XCTAssertEqual(k.mode, 0, "spring \(i)")
            let id = s.world.active.insert(k)
            BackgroundSprite.spring(s.world, id: id)
            let q = try XCTUnwrap(s.world.active.record(id: id))
            let t = Int(rec(i).type)
            XCTAssertEqual([Int(q.face?.pict ?? 0), q.mirrored ? 1 : 0], [t == 1153 ? 0x480 : t, t == 1153 ? 1 : 0],
                           "spring \(i)")
            _ = s.world.active.remove(id: id)
        }

        // The Bonus types first placed here (`.SetupBonusSprite` M l. 52372–52800):
        // 1293 (0x50d, the big bag, records 173 / 174): the bags arm (M l. 52508–52527) — friction 0x32, gravity 0x151,
        // the Handle-faced 0x50d.
        for i in [173, 174] {
            let e = try setup(i)
            XCTAssertEqual([Int(e.slot.friction), Int(e.slot.gravity), Int(e.sheet?.pict ?? 0)], [0x32, 0x151, 0x50d],
                           "bag \(i)")
        }
        // 3102 (0xc1e, a candelabra, ×8, p4 0): the candelabra arm (M l. 52740–52794) — `+0x114` 1 (p4 0: lit and
        // touchable), gravity 0, the light colour 99 at (x + 0x11, y + 8).
        for i in [15, 16, 17, 18, 19, 20, 136, 176] {
            let e = try setup(i)
            XCTAssertEqual([Int(rec(i).type), Int(rec(i).p4)], [3102, 0], "candelabra \(i)")
            XCTAssertEqual([Int(e.slot.pickupDelay), Int(e.slot.gravity), e.slot.hasHit ? 1 : 0], [1, 0, 1],
                           "candelabra \(i)")
            XCTAssertEqual(e.light?.colour, 99, "candelabra \(i)")
        }
        // 3219 (0xc93) p1 1 (records 116 / 117) and p1 0 (175): the item arm (M l. 52665–52710) — p1 ≠ 0 → gravity 0
        // (M l. 52704–52706), else the default 200; the light colour 0x4d.
        for (i, g) in [(116, 0), (117, 0), (175, 200)] {
            let e = try setup(i)
            XCTAssertEqual([Int(e.slot.gravity), Int(e.light?.colour ?? -1)], [g, 0x4d], "item 3219 \(i)")
        }
        // 3223 (0xc97, record 135, p1 0): the item arm — rect top + 0xd, bottom 0x26, light 0x21, gravity 200; picked
        // up it is item 0x17 (`.HitPlayerSprite` M l. 48977–49022: type − 3200).
        do {
            let e = try setup(135)
            XCTAssertEqual([e.slot.hotRect.top, e.slot.hotRect.bottom, Int(e.light?.colour ?? -1), Int(e.slot.gravity)],
                           [4 + 0xd, 0x26, 0x21, 200])
            let id = s.world.active.insert(e.slot)
            HitPlayerSprite.hit(s.world, player: try XCTUnwrap(s.world.playerID), other: id)
            XCTAssertTrue(s.world.globals.inventory.contains { $0.id == 0x17 && $0.count == 1 }, "item 0x17 picked up")
            _ = s.world.active.remove(id: id)
        }

        // The Gremlin 1770 (×6; records 22–24, 94–96): p1 1 → path mode 1 (`.SetupProgrammedPath` M l. 39288–39351):
        // bounds y256 + 8·p3 and y256 + 256·p2 − 8·p3, vy = p3 = 600; p4 (150 on record 95) is read only by the radial
        // modes 10 / 11 (M l. 39359–39378): the same Setup as p4 0.
        for i in [22, 23, 24, 94, 95, 96] {
            let p = rec(i), k = try setup(i).slot
            XCTAssertEqual([Int(p.p1), Int(p.p3)], [1, 600], "gremlin \(i)")
            XCTAssertEqual([k.pathMode, k.pathSpeed, k.pathLow, k.pathHigh, k.vy, k.vx],
                           [1, 600, k.y256 + 8 * 600, k.y256 + Int32(p.p2) * 256 - 8 * 600, 600, 0], "gremlin \(i)")
        }
        XCTAssertEqual(rec(95).p4, 150)
        XCTAssertEqual(try setup(95).slot, try SetupFaces.setup(with(95, 1, 150, 600), context: c).slot)

        // The Dillo 1870 (×7, p1…p4 all 0): `.SetupDilloSprite` (M l. 72354–72363) — p2 0 → 150 written back into the
        // record, the patrol bounds x ∓ 75; p1 0 (`.RandomDilloAttack` M l. 72502) → never the roll (`+0x154` 3).
        for i in [97, 98, 99, 159, 160, 161, 171] {
            let e = try setup(i)
            XCTAssertEqual(e.record.p2, 150, "dillo \(i)")
            XCTAssertEqual([e.slot.classWord15c, e.slot.classWord160], [Int32(rec(i).x) - 75, Int32(rec(i).x) + 75],
                           "dillo \(i)")
        }
        do {
            var modes: Set<Int32> = [], rolled: Set<Int32> = []
            let d = try setup(97).slot
            let p = s.world.records[97]
            for seed: Int32 in 1...60 {
                var a = d, b = d
                s.world.rng = FastRand(seed: seed)
                Dillo.randomAttack(s.world, &a)
                modes.insert(a.classWord154)
                s.world.records[97] = Placement(index: p.index, flag: p.flag, byte1: p.byte1, type: p.type, p1: 1,
                                                p2: p.p2, p3: p.p3, p4: p.p4, y: p.y, x: p.x)
                s.world.rng = FastRand(seed: seed)
                Dillo.randomAttack(s.world, &b)
                rolled.insert(b.classWord154)
                s.world.records[97] = p
            }
            XCTAssertEqual(modes, [0, 1, 2], "p1 0: spines, jump, egg — no roll")
            XCTAssertTrue(rolled.contains(3), "the same streams with p1 1 roll")
        }

        // 1090 p1 105 (records 156 / 157; levels 1–5, 10, 11: 0, 101, 103), p2 0: the rotating arm (M l. 62120–62170)
        // — record p2 0 → 4 written back, `+0xa6` 4, `+0x158` 4 (p3 0), step 0 (p1 105 turns only when a player shot
        // steers it, `BackgroundSprite.steer`), `+0x160` 4, speed 9000 (p4 0).
        for i in [156, 157] {
            let e = try setup(i)
            XCTAssertEqual(e.record.p2, 4, "cannon \(i)")
            XCTAssertEqual([Int(e.slot.counterA6), Int(e.slot.classWord158), Int(e.slot.classWord15c),
                            Int(e.slot.classWord160), Int(e.slot.launchSpeed)], [4, 4, 0, 4, 9000], "cannon \(i)")
        }
        // 1092 p1 101, p2 15 (record 158; level 11: p1 0): the pause 15, the step +1, `+0x158` 4 / 1, speed 9000.
        do {
            let k = try setup(158).slot
            XCTAssertEqual([Int(k.counterA6), Int(k.classWord158), Int(k.classWord15c), Int(k.launchSpeed)],
                           [15, 4, 1, 9000])
        }
        // 1402 p1 1 (levels 1–5: 11), p2 200 / 300, p3 1600 / 1000, p4 0 / 180 (records 110–114, 170): the vertical
        // shuttle (`.DoSetupPlatformSprite` M l. 54650–54664) — bounds y256 + 8·p3 and y256 + 256·p2 − 8·p3, y256 +=
        // 256·p4, vy = p3, vx 0, sag 0.
        for i in [110, 111, 112, 113, 114, 170] {
            let p = rec(i)
            let id = s.world.active.insert(try setup(i).slot)
            let y0 = try XCTUnwrap(s.world.active.record(id: id)).y256
            PlatformSprite.doSetup(s.world, id: id)
            let q = try XCTUnwrap(s.world.active.record(id: id))
            XCTAssertEqual([Int32(q.subtype), q.classWord150, q.classWord154, q.y256, q.vy, q.vx, Int32(q.sag)],
                           [1, y0 + 8 * Int32(p.p3), y0 + 256 * Int32(p.p2) - 8 * Int32(p.p3), y0 + 256 * Int32(p.p4),
                            Int32(p.p3), 0, 0], "platform \(i)")
            _ = s.world.active.remove(id: id)
        }
        // 1750 p3 6 (records 12, 13, 142, 153, 154; levels 10, 11: 0, 1, 5) and 1760 p3 6 (record 21; levels 1–11: 0):
        // tier 6 (`.SetupWalkerSprite` M l. 57059–57067) — cooldown 6, HP 0x546 (0x6d6) / 0x2ee (0x6e0), `+0xb8`
        // 0x10015; p3 also weighs the coins (`.PopupGoblinCoins` M l. 57424–57428: 0x14, 0x1e, 0x28, 10 — the table
        // `WalkerTests` pins per p3).
        for (i, hp) in [(12, 0x546), (13, 0x546), (142, 0x546), (153, 0x546), (154, 0x546), (21, 0x2ee)] {
            let w = try setup(i).slot
            XCTAssertEqual(rec(i).p3, 6)
            XCTAssertEqual([Int(w.classWord158), Int(w.hp), Int(w.mode)], [6, hp, 0x10015], "walker \(i)")
        }
        // 1800 p1 2 (record 14; levels 1–11: 0): the Frog's p1 arm — Setup HP 0x15e, `+0xb8` 0x10017 (M l.
        // 70184–70187); the spit's `+0xb8` 0x10017 (M l. 70302–70303); the Kill's score + 600 (M l. 70577–70579).
        do {
            var f = try setup(14).slot
            XCTAssertEqual([Int(f.hp), Int(f.mode), Int(f.classWord15c)], [0x15e, 0x10017, 2])
            let id = s.world.active.insert(f)
            // The stand-in carries its store id: `frogSpit` writes its `s` back by id (with id 0 the Frog itself
            // would be the "new" sprite below, and the assert would read the Frog's own `+0xb8`).
            f.id = id
            let before = Set(s.world.active.sprites.map(\.id))
            FrogSalamander.frogSpit(s.world, id: id, &f)
            let shot = try XCTUnwrap(s.world.active.sprites.first { !before.contains($0.id) })
            XCTAssertEqual([Int(shot.type), Int(shot.mode)], [0x709, 0x10017], "the spit 0x709's `+0xb8`")
            _ = s.world.active.remove(id: shot.id)
            let score = s.world.globals.score
            FrogSalamander.killFrog(s.world, &f)
            XCTAssertEqual(s.world.globals.score - score, 600)
            _ = s.world.active.remove(id: id)
        }
        // The earlier plants 2710 (record 81) and 2714 (40, 66), p2 22 (level 1: 6 / 7): the plant arm (M l.
        // 62659–62665) — `+0xb8` = 0x10000 + p2; record 40's p1 1 → mirrored.
        for i in [81, 40, 66] {
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.mode), k.mirrored ? 1 : 0], [0x10016, Int(rec(i).p1)], "plant \(i)")
        }
        // 2853 (0xb25, a rock outcrop) record 84, p1 1, p3 22 (level 1: 0): the outcrop arm (M l. 59683–59704) and its
        // Handle re-face (M l. 61116–61143) read no record word — the same Setup as p1…p4 0.
        XCTAssertEqual([rec(84).p1, rec(84).p3], [1, 22])
        XCTAssertEqual(try setup(84).slot, try SetupFaces.setup(with(84), context: c).slot)
        // 2902 signs p1 16 / 17 (records 59, 63; levels 1, 2: 4…13): the sign arm (M l. 49287–49297) —
        // `.SimpleConv(4020, "Wooden Sign", GetIndString(500, p1))`, both strings present.
        let signs = try StringList.load(from: r, id: 500)
        for (i, n) in [(59, 16), (63, 17)] {
            XCTAssertEqual([Int(rec(i).type), Int(rec(i).p1)], [2902, n])
            let text = try XCTUnwrap(signs.string(n), "STR# 500[\(n)]")
            XCTAssertFalse(text.isEmpty)
            let id = s.world.active.insert(try setup(i).slot)
            s.world.player.countdown06cc = 0
            XCTAssertTrue(HitPlayerSprite.talk(s.world, other: id, keys: InputActions()), "sign \(i)")
            XCTAssertEqual(s.world.suspension, .sign(text: MacRoman.bytes(text)), "sign \(i)")
            s.world.suspension = nil
            _ = s.world.active.remove(id: id)
        }
        // The crates 3090 (0xc12) p2 1290 / 3206 (level 1: 1291, 1293, 3219), p3 2 (level 1: 0, 1, 3): `.KillCrate`
        // (M l. 61257–61316) — p3 drops of type p2: 1290 (a Bonus drop, `isBonusDrop`) through `.SetupBonusSprite`, 3206
        // through `.GenerateSprite`.
        for (i, type, n) in [(25, 1290, 1), (27, 1290, 1), (178, 1290, 3), (88, 1290, 2), (89, 1291, 2), (90, 1293, 2),
                             (179, 1291, 2), (91, 3206, 3), (26, 1291, 1)] {
            XCTAssertEqual([Int(rec(i).type), Int(rec(i).p2), Int(rec(i).p3)], [3090, type, n], "crate \(i)")
            let id = s.world.active.insert(try setup(i).slot)
            s.world.active.update(id: id) { $0.hp = 0 }
            let before = Set(s.world.active.sprites.map(\.id))
            var lights = LightTable()
            BoxSprite.killCrate(s.world, id: id, lights: &lights, effects: 1)
            let made = s.world.active.sprites.filter { !before.contains($0.id) }
            XCTAssertEqual(made.filter { $0.type == Int16(type) }.count, n, "crate \(i)")
            // The two paths of `.KillCrate`, told apart: a Bonus drop through `.SetupBonusSprite` gets `+0x114` 0xc;
            // a type > 0xc7f through `.GenerateSprite` gets gravity 0x151; both leave with vy −2000 − R(1000).
            for d in made where d.type == Int16(type) {
                if type == 3206 {
                    XCTAssertEqual(d.gravity, 0x151, "crate \(i): 3206 through `.GenerateSprite`")
                } else {
                    XCTAssertEqual(d.pickupDelay, 0xc, "crate \(i): \(type) through `.SetupBonusSprite`")
                }
                XCTAssertTrue((-2999...(-2000)).contains(d.vy), "crate \(i): vy \(d.vy)")
            }
            for d in made { _ = s.world.active.remove(id: d.id) }
            _ = s.world.active.remove(id: id)
        }
        // The exits 3249 p1 1, p2 2 (records 61, 62; levels 1–11: p2 0): `.HitPlayerSprite`'s exit arm (M l.
        // 49733–49741) — exit1 = p1, exit2 = p2 (stored when ≠ 0); node 15's links [10, 20, 30] (`Mmap 200`): the map
        // unlocks nodes 20 and 30 and, exit2 ≥ 0, cancels the walk — the player stays on node 15
        // (`testBuiltLevelsFifteen`).
        for i in [61, 62] {
            let t = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 15)
            try touchExit(t, record: i)
            XCTAssertEqual([t.world.player.exitIndex, t.world.player.exit2], [1, 2], "exit \(i)")
        }
    }

    func testLevel15IdleChildLinks() throws {
        let r = try TenEleven.resources()
        // The Gremlins 1770 (records 22–24, 94–96). Each is three sprites: the body (the record), its back layer
        // (`+0xec` 1) and the rider (`+0xec` 2), the two parts `.MTNewSprite(type, …, 0x1ff, .SetupGremlinSprite)`
        // children of the body's Setup; the links are the body's `+0x1d4` (back layer) / `+0x1d8` (rider) and the rider's
        // own `+0x1d4` back to the body (M l. 69205–69223). The dump over the card: a Gremlin never idles —
        // `.GenerateSprite` spawns 0x6ea…0x6f3 at once (M l. 1856–1858: `bVar1` false → `.MTNewSprite`, never
        // `.AddIdleSprite`), so no idle entry holds it and `.HandleIdleSprites` never reaches it; the parts are no
        // idle entries either. The three run on together wherever the player is, the body placing its parts each frame
        // (M l. 69393–69420).
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 15, seed: 1)
        let bodies: [Int16] = [22, 23, 24, 94, 95, 96]
        func gremlins(_ tag: String) throws -> [SpriteSlot] {
            XCTAssertFalse(s.world.idle.entries.contains { $0?.saved.handler == .gremlin }, "\(tag): no Gremlin idle entry")
            XCTAssertEqual(s.world.active.sprites.filter { $0.handler == .gremlin }.count, 18, "\(tag): 6 × 3 sprites")
            var out: [SpriteSlot] = []
            for rec in bodies {
                let b = try XCTUnwrap(s.world.active.sprites.first { $0.recordIndex == rec }, "\(tag): body \(rec) active")
                let back = try XCTUnwrap(b.siblings.first.flatMap { s.world.active.sprite(id: $0) }, "\(tag): \(rec)")
                let rider = try XCTUnwrap(b.siblings.second.flatMap { s.world.active.sprite(id: $0) }, "\(tag): \(rec)")
                XCTAssertEqual([Int(b.partIndex), Int(b.layer), b.countedInTotals ? 1 : 0], [0, 10, 1], "\(tag): body \(rec)")
                XCTAssertEqual([Int(back.partIndex), Int(back.recordIndex), Int(back.layer), Int(back.mode),
                                back.countedInTotals ? 1 : 0, back.hasHit ? 1 : 0], [1, 0x1ff, 9, 0xb0000, 0, 0],
                               "\(tag): back layer \(rec)")
                XCTAssertEqual([Int(rider.partIndex), Int(rider.recordIndex), Int(rider.layer), rider.countedInTotals ? 1 : 0],
                               [2, 0x1ff, 12, 0], "\(tag): rider \(rec)")
                XCTAssertEqual(rider.siblings.first, b.id, "\(tag): the rider's `+0x1d4` is its body")
                XCTAssertNil(rider.siblings.second, "\(tag): the rider's own `+0x1d8` is never set")
                XCTAssertEqual(rider.classTimer, 0, "\(tag): mounted")
                XCTAssertEqual([back.x, back.y], [b.x, b.y], "\(tag): the back layer on the body")
                out += [b, back, rider]
            }
            return out
        }
        // At the level start (the Setups' positions): the rider at the body + (0x26, 0x1b).
        for g in stride(from: 0, to: 18, by: 3) {
            let start = try gremlins("start")
            XCTAssertEqual([start[g + 2].x, start[g + 2].y], [start[g].x + 0x26, start[g].y + 0x1b])
        }
        XCTAssertEqual(s.world.enemies.live, 24, "every body counted once, no part")
        // 60 frames from the level start (every Gremlin out of view, 2,000 px and more from the player), then 60 with
        // the player put at the level's far end (x 12,500): never idled, the links unchanged, the parts on the body —
        // the mounted rider at the body + (0x26 facing left | 0x3e facing right, 0x1b).
        var positions: [Int] = []
        for (frames, put) in [(60, false), (60, true)] {
            if put {
                let pid = try XCTUnwrap(s.world.playerID)
                s.world.active.update(id: pid) { p in
                    p.x = 12500; p.y = 1000; p.x256 = 12500 << 8; p.y256 = 1000 << 8; p.vx = 0; p.vy = 0
                }
            }
            for _ in 0..<frames { _ = s.step(keys: KeyState()) }
            let g = try gremlins(put ? "far end" : "f60")
            for k in stride(from: 0, to: 18, by: 3) {
                let b = g[k], rider = g[k + 2]
                XCTAssertEqual([rider.x, rider.y], [b.x + (b.mirrored ? 0x3e : 0x26), b.y + 0x1b], "the rider on its body")
                positions += [b.x, b.y]
            }
        }
        // Measured (seed 1): the six bodies' pixel positions after the two 60-frame spans, in record order.
        XCTAssertEqual(String(TenEleven.fnv(positions), radix: 16), "d9e5bf39bd47e6b0")
        XCTAssertEqual(Array(positions.prefix(2)), [7813, 1606])
        XCTAssertNotEqual(Array(positions.prefix(12)), Array(positions.suffix(12)), "the bodies flew on while far away")

        // The Dillo 1870 (records 97–99, 159–161, 171) has no parts (`.SetupDilloSprite` M l. 72291–72378 makes no
        // sprite): the carry is its own state across idling. At the level start all seven are idle entries (the Setup
        // ran in `.AddIdleSprite`: the record's p2 0 → 150 written back, M l. 72354–72357). Record 97: brought in by the
        // player, run 120 frames, idled when he leaves, brought back — `.IdleToActiveSprite` (M l. 4215–4275) re-runs no
        // Setup: the snapshot's state comes back (the attack in hand, the patrol bounds the Setup took from the record's
        // x, not from where it idled), `+0x14`/`+0x1c` from the entry's pixels (the fraction dropped), `+0xe9` 0, `+0xa8`
        // the entry; a re-activated sprite is never counted again (Invariant 5).
        let e = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 15, seed: 1)
        XCTAssertNil(e.world.active.sprites.first { $0.handler == .dillo }, "no Dillo active at the start")
        let entries = e.world.idle.entries.compactMap { $0 }.filter { $0.saved.handler == .dillo }
        XCTAssertEqual(entries.map(\.saved.recordIndex), [97, 98, 99, 159, 160, 161, 171])
        for x in entries {
            XCTAssertEqual(e.world.records[Int(x.saved.recordIndex)].p2, 150, "dillo \(x.saved.recordIndex): p2 written back")
        }
        func put(_ x: Int, _ y: Int) throws {
            let pid = try XCTUnwrap(e.world.playerID)
            e.world.active.update(id: pid) { p in
                p.x = x; p.y = y; p.x256 = Int32(x) << 8; p.y256 = Int32(y) << 8; p.vx = 0; p.vy = 0
            }
        }
        func dillo() -> SpriteSlot? { e.world.active.sprites.first { $0.recordIndex == 97 } }
        _ = e.step(keys: KeyState())
        let live = e.world.enemies.live
        XCTAssertEqual(live, 24)
        try put(3700, 1500)
        var k = 0
        while dillo() == nil && k < 200 { _ = e.step(keys: KeyState()); k += 1 }
        let woke = try XCTUnwrap(dillo(), "dillo 97 brought in")
        XCTAssertEqual([k, woke.x, Int(woke.classWord15c), Int(woke.classWord160), Int(woke.idleEntry)],
                       [17, 3937, 3862, 4012, 89], "measured: in on the 17th frame, the Setup's bounds")
        for _ in 0..<120 { _ = e.step(keys: KeyState()) }
        // `+0xe9` planted 1 before it idles, so the snapshot carries it and the waking's clear (M l. 4264) is seen.
        e.world.active.update(id: try XCTUnwrap(dillo()).id) { $0.killCount = 1 }
        try put(1200, 1500)
        k = 0
        while dillo() != nil && k < 200 { _ = e.step(keys: KeyState()); k += 1 }
        let entry = try XCTUnwrap(e.world.idle.entries[89])
        XCTAssertNil(entry.activeID)
        let idled = entry.saved
        XCTAssertGreaterThan(idled.killCount, 0, "the snapshot carries a non-zero `+0xe9`")
        // Measured: idled on the second frame, mid-attack (state 8, phase 1, volley 3), 69 px left of its spawn.
        XCTAssertEqual([k, idled.x, Int(idled.x256), Int(idled.subtype), Int(idled.subState), Int(idled.classTimer)],
                       [2, 3868, 990462, 8, 1, 3])
        for _ in 0..<30 { _ = e.step(keys: KeyState()) }
        XCTAssertEqual(try XCTUnwrap(e.world.idle.entries[89]).saved, idled, "the snapshot holds while idle")
        try put(3700, 1500)
        k = 0
        var back: SpriteSlot?
        while back == nil && k < 200 { _ = e.step(keys: KeyState()); k += 1; back = dillo() }
        let b = try XCTUnwrap(back)
        XCTAssertEqual(k, 13, "measured: back on the 13th frame")
        // No Setup: a re-run would put state 6, phase 0 and the bounds 3868 ∓ 75 (3793 / 3943).
        XCTAssertEqual([Int(b.subtype), Int(b.subState), Int(b.classTimer), Int(b.classWord15c), Int(b.classWord160),
                        Int(b.hp), Int(b.bonusP4)], [8, 1, 3, 3862, 4012, 500, 500])
        XCTAssertEqual([b.x, Int(b.x256), Int(b.idleEntry), Int(b.killCount)], [3868, 3868 << 8, 89, 0],
                       "the entry's pixels, the fraction dropped; `+0xa8` the entry; `+0xe9` 0")
        XCTAssertTrue(b.countedInTotals)
        XCTAssertEqual(e.world.enemies.live, live, "not counted again")
    }

    func testBuiltLevelsFifteen() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5, 10, 11, 15, 18])     // 6A-L18: + 18
        XCTAssertTrue(BuiltLevels.contains(15))
        for n in [12, 16, 20] { XCTAssertFalse(BuiltLevels.contains(n), "level \(n)") }
        let r = try TenEleven.resources()
        // `startLevel` 15 (the hidden `FerazelLevel` switch) is accepted: New Game there, nothing asked.
        let rig = TenElevenRig(r, start: 15)
        rig.newGame(level: 15)
        XCTAssertEqual(rig.flow.levelNumber, 15)
        XCTAssertEqual(rig.levels.prepared, [15])
        XCTAssertEqual(rig.asked, [])
        // Level 10's exit p1 2 (record 249) → node 15 (node 10's links [5, 11, 15]) → Return → level 15 entered (before
        // 6A-L15: "Level 15 is not built yet (Phase 6).").
        let ten = TenElevenRig(r, start: 10)
        ten.newGame(level: 10)
        XCTAssertEqual(try LevelFile.load(from: r, level: 10).placements[249].p1, 2)
        try ten.exit(249, toNode: 15)
        ten.drive { f in f.levelRun?.levelNumber == 15 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(ten.asked, [])
        XCTAssertEqual(ten.levels.prepared, [10, 15])
        // Level 15's exit p1 1, p2 2 (record 61) → the map unlocks node 20 (links[1]) and draws its link, then — exit2 ≥
        // 0 — unlocks node 30 (links[2]), draws that link and cancels the walk (`.ShowWorldMap` M l. 67545–67559: the
        // walk target back to the current node, step 0): the player stays on node 15. Return → level 15 again.
        let s15 = try XCTUnwrap(ten.flow.levelRun?.session)
        XCTAssertEqual([s15.globals.unlocked[20], s15.globals.unlocked[30]], [0, 0])
        try touchExit(s15, record: 61)
        ten.drive { f in (f.worldMap.map { $0.iterations >= 2 && $0.walkStep == 0 && $0.result == nil }) ?? false }
        let m = try XCTUnwrap(ten.flow.worldMap)
        XCTAssertEqual(m.cur, try XCTUnwrap(m.map.findCurrNode(level: 15)).index, "no walk: still on node 15")
        XCTAssertEqual([m.globals.unlocked[20], m.globals.unlocked[30]], [1, 1], "both links unlocked")
        ten.drive({ f in f.worldMap?.result == nil ? [0x24] : [] }) { f in
            f.levelRun?.levelNumber == 15 && (f.levelRun?.iterations ?? 0) >= 1
        }
        XCTAssertEqual(ten.asked, [])
        XCTAssertEqual(ten.levels.prepared, [10, 15, 15])
        // A save made on level 15 (a save point's block, the level's own records) continues there through
        // `.ContinueGame`: level 15 runs, nothing asked.
        let L = try LevelFile.load(from: r, level: 15)
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 15, x: L.header.startX, y: L.header.startY,
                           stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L.placements)
        let cont = TenElevenRig(r, start: 1)
        cont.files.block = save
        cont.drive { $0.state == .mainMenu }
        cont.drive({ _ in [0x0f] }) { _ in true }                          // R: Continue
        cont.drive { _ in cont.askedFile }
        cont.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/fifteen"),
                                                displayName: "fifteen")))
        cont.drive { f in f.levelRun?.levelNumber == 15 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(cont.asked, [])
        XCTAssertEqual(cont.flow.levelNumber, 15)
        XCTAssertEqual(cont.levels.prepared, [15])
    }
}

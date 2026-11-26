import XCTest
import HectorResources
@testable import FerazelCore

/// 6A-L22 (docs/superpowers/plans/2026-11-04-ferazel-remainder.md `#### 6A-L22`): level 22 "The Labyrinth" enterable —
/// every one of its 510 records sets up (49 types; LL §4 "Level 22"; the blades, maces, faces, talkers and the carpet
/// built by 6A-BD / 6A-MP / 6A-BX1b / 6A-CP, none refused), its header as read (music 8, chapter card 5, the start, the
/// darkness switch 0x2706 = 2 over a light grid whose every byte is 0…12, inside the ambient table's 16 rows), the
/// picture cache's marks and load bar, `BuiltLevels.list` = [1…5, 10, 11, 15, 18, 20, 21, 22] with the way in (level
/// 21's exit) and on, and Dimbo's conversation 221 played in the level (actions 9 and 10), which arms level 11's
/// dormant Dimbo (record 283, Mcnv 220) for the revisit (D70.1). The parameter trace ("Every level task"): every built
/// type placed here whose p1…p4 take a value no level 1–5, 10, 11, 15, 18, 20 or 21 record of that type has, and the
/// types the card names, each traced through its Setup / Handle arm in the dump and pinned inside
/// `testLevel22SetsUpEveryRecord`. The level's first frame is `LevelFrameGoldenTests.testLevel22FirstFrameGolden`.
/// Against the committed `Resources/Ferazel` (D26); a missing data file is a FAILURE, never a skip. Proof-B rules: plain
/// Swift, no `@MainActor` class, no Foundation string search.
final class LevelTwentyTwoTests: XCTestCase {

    func testLevel22SetsUpEveryRecord() throws {
        let r = try TenEleven.resources()
        let L = try LevelFile.load(from: r, level: 22)
        let census = try TenEleven.census(r, level: 22)
        XCTAssertEqual(census.records, 510, "records")
        XCTAssertEqual(census.types, 49, "types")
        XCTAssertEqual(census.refused, [], "every record sets up — no `notTranscribed`, per record (the card's 52 are built)")
        XCTAssertEqual(census.created, 510, "records created")
        XCTAssertEqual(census.refusedSpawns, 0, "no spawn dropped for want of a record (known deviation 6)")
        var perType: [Int16: Int] = [:]
        for p in L.activePlacements { perType[p.type, default: 0] += 1 }
        XCTAssertEqual([1060, 1080, 1480, 1485, 1732, 1851, 1870, 1871, 1900, 1901, 1902, 1903, 2956, 3060, 3090, 3091]
                        .map { perType[Int16($0)] ?? 0 },
                       [8, 1, 2, 38, 3, 2, 12, 1, 10, 15, 5, 3, 1, 13, 7, 14], "records per type")

        // The header (LL §4 "Level 22" item 1: the darkness switch's value 2 and the music 8 are the values new against
        // 1–5; the chapter card 5 is PICT 4650 / clut 285).
        let h = L.header
        XCTAssertEqual(h.name, "The Labyrinth", "the name")
        XCTAssertEqual([h.music, h.chapter, h.levelClut, h.screenClut], [8, 5, 245, 246], "0x284a / 0x273c")
        XCTAssertEqual([h.startX, h.startY, Int16(h.startFacingLeft)], [166, 3798, 0], "the start, facing right")
        XCTAssertEqual([Int(h.parallaxRipple), Int(h.omniPxMode), Int(h.waterSurfaceEffect), Int(h.submergedFaces),
                        Int(h.inLiquid)], [0, 0, 0, 0, 0], "0x26ca / 0x26c7 / 0x26c9 / 0x26c6 / 0x26cd")
        XCTAssertEqual([h.sidePush, h.stripPict, h.autoScrollEnable, h.flameMode, h.darknessEnable, h.cameraOffsetX,
                        h.cameraOffsetY, h.landingDamage, h.iceSlipperiness, h.waterCurrent, h.arenaBound,
                        h.secondArenaBound], [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0], "0x2706 = 2, the others 0")
        XCTAssertEqual([Int(h.gridWidth), Int(h.gridHeight)], [256, 128], "the grid")
        // The darkness grid: every light byte 0…12 (no −1, none past the ambient table's 16 rows), so the tile light
        // pass (`.GetAmbDarkVal`, M l. 13643–13652) reads a defined ambient row on every cell (measured counts).
        var bytes: [Int: Int] = [:]
        for row in 0..<Int(h.gridHeight) { for col in 0..<Int(h.gridWidth) { bytes[L.lightByte(col: col, row: row), default: 0] += 1 } }
        XCTAssertEqual(bytes.keys.sorted(), Array(0...12), "every light byte 0…12 occurs")
        XCTAssertEqual([bytes[0], bytes[12]], [20438, 307], "measured: the unlit and the darkest cells")
        // The music: New Game at level 22 (the hidden `FerazelLevel` switch; chapter card 5 first) plays the level's own
        // track 8; the player starts facing right; `.SetupLevel` copies the darkness switch into G+0x22 (M l. 2377).
        let rig = TenElevenRig(r, start: 22)
        rig.newGame(level: 22)
        XCTAssertEqual(rig.plays, [8], "the music")
        let run = try XCTUnwrap(rig.flow.levelRun)
        XCTAssertEqual(run.music.currentTrack, 8, "the music")
        let session = try XCTUnwrap(run.session)
        XCTAssertEqual([session.globals.startFacing, session.world.player.facing], [0, 2], "facing right")
        XCTAssertEqual([Int(session.world.globals.savedDarkness), Int(session.world.globals.darknessOverride)], [2, 0],
                       "G+0x22 the switch, no override")

        // The picture cache (LL §4 item 6, the new types' marks as 1-based list positions — `.set(n − 1)` here): every
        // one is marked but set #48 (0x73b), which the Bat 1851 marks only for p1 < 0 (M l. 68262–68267; level 22's
        // two have p1 2 — LL §4's note); the opened session needs exactly the Setups' marks.
        let expected: [CachedFaces.RecordKey] = [
            .set(14), .set(15), .set(16), .set(17), .set(26), .set(27), .set(28), .set(36), .set(37), .set(38), .set(46),
            .set(48), .set(50), .set(51), .set(52), .set(53), .single(1), .single(60), .single(135), .single(150),
        ]
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(h))
        let setUp = SetupFaces.spawnOrder(L.placements).filter { (try? SetupFaces.setup($0, context: c)) != nil }
        XCTAssertEqual(setUp.count, L.activePlacements.count, "every record sets up")
        let marks = Set(setUp.flatMap { CachedFaces.markedRecords(type: $0.type, p1: $0.p1) })
        for k in expected { XCTAssertTrue(marks.contains(k), "\(k)") }
        XCTAssertFalse(marks.contains(.set(47)), "set #48 (0x73b) not marked: the 1851s have p1 2")
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 22)
        let needed = CachedFaces.needed(by: s)
        XCTAssertEqual(Set(needed.records), marks, "the opened session needs the Setups' marks")
        // The card's assert: the opened level's needs equal `CachedFacesTests.testLevel22LoadBarMarks`' count and total
        // as last re-derived (6A-CP: [36, 176, 352, 36]) — the bar on a fresh cache.
        var cache = CachedFaces()
        cache.enterLevel(screenClut: h.screenClut)
        let bars = cache.load(needed: needed)
        let q = Int(bars.first?.1 ?? 0), n = needed.records.reduce(0) { $0 + CachedFaces.record($1).faces }
        XCTAssertEqual([needed.records.count, n, q, bars.count], [36, 176, 352, 36],
                       "needed records, n, q, steps = `testLevel22LoadBarMarks`' pin")

        try traceLevel22(r, L)
    }

    /// The parameter trace of level 22 (the script's list and each value's dump line are in the commit body). One
    /// assert each.
    private func traceLevel22(_ r: FerazelResources, _ L: LevelFile) throws {
        let s = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 22, seed: 1)
        let w = s.world
        let c = SetupFaces.Context(level: L, playerX: SetupFaces.Context.levelStartPlayerX(L.header))
        func rec(_ i: Int) -> Placement { L.placements[i] }
        func setup(_ i: Int) throws -> SetupFaces.Entry { try SetupFaces.setup(rec(i), context: c) }
        /// Record `i`'s Setup slot put on the session's list (its record index kept), as a Handle finds it.
        func put(_ i: Int) throws -> Int {
            var slot = try setup(i).slot
            slot.recordIndex = Int16(i)
            return w.active.insert(slot)
        }
        /// Record `i`'s sprite as the level spawn left it (on the list, or its idle entry's snapshot).
        func spawned(_ i: Int) throws -> SpriteSlot {
            try XCTUnwrap(w.active.sprites.first { Int($0.recordIndex) == i }
                          ?? w.idle.entries.compactMap { $0 }.first { Int($0.saved.recordIndex) == i }?.saved,
                          "record \(i) spawned")
        }
        func indices(_ t: Int16) -> [Int] { L.activePlacements.filter { $0.type == t }.map(\.index) }

        // The teleporters 1060 (0x424, 8 records; first placed here): p1 is the partner's record index, read by the
        // landing's teleport (`.HitPlayerSprite` M l. 49418–49462, the live record's `+8`) against every in-use idle
        // entry. Four pairs: 411/412, 438/439, 451/452, 464/465; exactly one entry holds each partner at the spawn.
        let teleporters = indices(1060)
        XCTAssertEqual(teleporters, [411, 412, 438, 439, 451, 452, 464, 465], "teleporters")
        XCTAssertEqual(teleporters.map { Int(rec($0).p1) }, [412, 411, 439, 438, 452, 451, 465, 464], "teleporters' p1")
        for i in teleporters {
            let partner = rec(i).p1
            XCTAssertEqual(rec(Int(partner)).type, 1060, "teleporter \(i)")
            XCTAssertEqual(w.idle.inUseEntries(record: partner).count, 1, "teleporter \(i): one entry holds \(partner)")
        }
        // …and the port's teleport reads them (`HitPlayerSprite.teleportMove`, M l. 49418–49462): each teleporter, its
        // record index kept, moves the player to the one entry holding its p1, the player's offset from the teleporter
        // kept. On a session of its own (the move leaves the player there).
        do {
            let ts = try FerazelSession(resources: r, prefs: FerazelPrefs(), level: 22, seed: 1)
            let tw = ts.world
            let pid = try XCTUnwrap(tw.playerID)
            let home = try XCTUnwrap(tw.active.record(id: pid))
            for i in teleporters {
                var slot = try setup(i).slot
                slot.recordIndex = Int16(i)
                let tel = tw.active.insert(slot)
                tw.active.update(id: pid) { $0 = home }
                let p0 = try XCTUnwrap(tw.active.record(id: pid)), o = try XCTUnwrap(tw.active.record(id: tel))
                tw.player.teleportTail = tel
                let matched = HitPlayerSprite.teleportMove(tw, player: pid) {}
                XCTAssertEqual(matched.map { tw.idle.entries[$0]?.saved.recordIndex }, [rec(i).p1], "teleporter \(i)")
                let e = try XCTUnwrap(tw.idle.entries[try XCTUnwrap(matched.first, "teleporter \(i)")])
                let p1 = try XCTUnwrap(tw.active.record(id: pid))
                XCTAssertEqual([p1.x - e.saved.x, p1.y - e.saved.y], [p0.x - o.x, p0.y - o.y],
                               "teleporter \(i) → \(rec(i).p1): the offset kept")
                tw.player.teleportTail = nil
                _ = tw.active.remove(id: tel)
            }
        }
        // The cannons 1091 (record 140), 1094 (450, 473, 474) and 1096 (204, 205, 392, 437), p1 0 (as on levels 10, 11,
        // 20): the p1 < 1 arm (M l. 62112–62118) — `+0x164` 9000, no turn.
        for i in indices(1091) + indices(1094) + indices(1096) {
            XCTAssertEqual([rec(i).p1, rec(i).p4], [0, 0], "cannon \(i)")
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.launchSpeed), Int(k.classWord15c)], [9000, 0], "cannon \(i)")
        }
        // The Bonus (`.SetupBonusSprite`): the big crystals 1291 (108, 470) — p1 ≠ 0 alone zeroes the gravity (M l.
        // 52496–52500), both p1 0 here; the money bags 1293 (342, 343, 442) read no record word (M l. 52508–52527);
        // the spheres 1337 / 1338 (0x539 / 0x53a; first placed here — 1337 record 379 p1 1): the spheres' arm (M l.
        // 52710–52720) — `+0x110` 200 from the shared default (M l. 52642–52645), 0 for p1 ≠ 0; the items 3206 (record
        // 443 p1 1; levels 20, 21: p1 0), 3219 and 3223 (0xc97) — gravity 0 only for p1 ≠ 0 (M l. 52704–52706); 0xc97's
        // rect top + 0xd, bottom 0x26 (M l. 52685–52687).
        for i in indices(1291) + indices(1293) + indices(1337) + indices(1338) + indices(3206) + indices(3219)
            + indices(3223) {
            let p = rec(i), k = try setup(i).slot
            let want: Int16 = p.p1 != 0 ? 0 : (p.type == 1291 || p.type == 1293 ? 0x151 : 200)
            XCTAssertEqual(k.gravity, want, "Bonus \(i) (type \(p.type), p1 \(p.p1))")
        }
        XCTAssertEqual([rec(379).p1, rec(443).p1, rec(259).p1, rec(440).p1], [1, 1, 0, 0], "the p1-1 sphere and item")
        do {
            let k = try setup(182).slot
            XCTAssertEqual([Int(rec(182).type), k.hotRect.top, k.hotRect.bottom], [3223, 4 + 0xd, 0x26], "item 182")
        }
        // The radial maces 1480 (0x5c8, records 236 / 445; level 20: p1 10) p1 11, p2 140 / 150, p3 0, p4 0, and the
        // radial balls 1485 of modes 10 (224, 422, 423, 479), 12 (341), 13 (288, 291) and 14 (289, 290): the Setup
        // (M l. 62312–62427) writes p2 0 → 0x8c and p3 0 → 0x1e back (M l. 62329–62336), then `.MakeRadial(x + 0x32,
        // y + 0x32, r = p2, …)` — modes 10, 13, 14 speed p3, angle p4, g 0; modes 11, 12 speed 0, angle p4, g = p3
        // (M l. 62389–62402); persp 1 for 12, 13, 2 for 14, else 0 (M l. 62373–62383); p2 / 16 spokes 0x59a (0x59c for
        // 14, M l. 62366–62371, 62403–62423); `+0x188 = 1` (M l. 62363).
        let radial: [(Int, Int16, Int16, Int16, Int16, Int16, Int16)] = [
            // record, mode, r, speed, angle, g, persp
            (236, 11, 140, 0, 0, 0x1e, 0), (445, 11, 150, 0, 0, 0x1e, 0),
            (224, 10, 108, 2000, 0, 0, 0), (422, 10, 135, 1200, 0, 0, 0), (423, 10, 135, 1200, 0, 0, 0),
            (479, 10, 100, 800, 0, 0, 0), (341, 12, 100, 0, 0, 0x1e, 1), (288, 13, 140, 1200, 0, 0, 1),
            (291, 13, 140, 1200, 180, 0, 1), (289, 14, 140, 1000, 0, 0, 2), (290, 14, 140, 1000, 180, 0, 2),
        ]
        for (i, mode, radius, speed, angle, g, persp) in radial {
            XCTAssertEqual(rec(i).p1, mode, "mace \(i)")
            let ball = try spawned(i)
            let rad = try XCTUnwrap(ball.radial, "mace \(i)")
            XCTAssertEqual([Int(ball.subtype), Int(rad.radius), Int(rad.speed), Int(rad.angle), Int(rad.gravity),
                            Int(rad.persp), Int(rad.spokeCount)],
                           [Int(mode), Int(radius) << 8, Int(speed), Int(angle) << 8, Int(g), Int(persp), Int(radius) / 16],
                           "mace \(i)")
            XCTAssertTrue(ball.keepRecord, "mace \(i): `+0x188 = 1`")
            XCTAssertEqual([Int(w.records[i].p2), Int(w.records[i].p3)], [Int(radius), rec(i).p3 == 0 ? 0x1e : Int(rec(i).p3)],
                           "mace \(i): p2 / p3 as written back")
        }
        let chains = w.active.sprites.filter { $0.type == ChainSprite.maceChain2 }.count
            + w.idle.entries.compactMap { $0 }.filter { $0.saved.type == ChainSprite.maceChain2 }.count
        XCTAssertEqual(chains, 2 * (140 / 16), "the two mode-14 balls' spokes are 0x59c")
        // The path balls 1485 of modes 1 (×23) and 2 (×6): 6A-MP's `MacePathTests` holds every one record by record.
        var modes: [Int16: Int] = [:]
        for i in indices(1485) { modes[rec(i).p1, default: 0] += 1 }
        XCTAssertEqual(modes, [1: 23, 2: 6, 10: 4, 12: 1, 13: 2, 14: 2], "the 1485 modes")
        // The dart traps 1900…1903 (0x76c…0x76f, 33 records, first placed here, p1…p4 all 0): the Setup arm (M l.
        // 62495–62520) — `+0x46 = 0x10`; p1 0 → 0x2d and p2 0 → 0x32 written back to the live record; `+0x14c` = `+0xa6`
        // = p1, `+0x150` = p2.
        for t: Int16 in [1900, 1901, 1902, 1903] {
            for i in indices(t) {
                XCTAssertEqual([rec(i).p1, rec(i).p2, rec(i).p3, rec(i).p4], [0, 0, 0, 0], "dart trap \(i)")
                let k = try setup(i).slot
                XCTAssertEqual([Int(k.phase), Int(k.classTimer), Int(k.counterA6), Int(k.classWord150)], [0x10, 0x2d, 0x2d, 0x32],
                               "dart trap \(i)")
                XCTAssertEqual([w.records[i].p1, w.records[i].p2], [0x2d, 0x32], "dart trap \(i): written back")
            }
        }
        // The Blob 1732 (0x6c4, records 350, 354, 402; first placed here): `.SetupBlobSprite`'s type arm (M l.
        // 67699–67701) — HP 0x5dc, `+0xb8` 0x1000c. The Dillo 1871 (0x74f, record 326; first placed here):
        // `.SetupDilloSprite` (M l. 72338–72340) — HP 1100, `+0xb8` 0x1000b (1870: 500, none); every Dillo's p2 0 → 150
        // written back (M l. 72355–72356).
        for i in indices(1732) {
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.hp), Int(k.mode)], [0x5dc, 0x1000c], "Blob \(i)")
        }
        for i in indices(1870) + indices(1871) {
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.hp), Int(k.mode)], rec(i).type == 1871 ? [1100, 0x1000b] : [500, 0], "Dillo \(i)")
            XCTAssertEqual(w.records[i].p2, 150, "Dillo \(i): p2 written back")
        }
        // The Walker 1700 (0x6a4) record 265 p3 6 (no 1700 of levels 1–4, 10, 11, 21 has p3 6): the tier arm (M l. 57059–57068) —
        // `+0x158` 6, HP 0x2ee, `+0xb8` 0x10015; the other three p3 0: the defaults 8 / 500 / 0.
        for i in indices(1700) {
            let k = try setup(i).slot
            XCTAssertEqual([Int(k.classWord158), Int(k.hp), Int(k.mode)], rec(i).p3 == 6 ? [6, 0x2ee, 0x10015] : [8, 500, 0],
                           "Walker \(i) (p3 \(rec(i).p3))")
        }
        XCTAssertEqual(indices(1700).map { Int(rec($0).p3) }, [0, 0, 0, 6], "the 1700s' p3")
        // The spikes 1840 / 1841 / 1842 (0x730…0x732; p3 40…70, 1841 p4 60, 1842 p2 60 / 80, p3 24…60, p4 20 / 40 — new
        // against levels 3, 11, 21): `+0x150` = p2 (0 → 32000, never retracting), `+0x154` = p3, `+0xa6` = p4, out
        // (`+0x46` 0) when p4 < `+0x150`, else in (0xb); 0x732 `+0x158` = y (M l. 61982–62015, 62279–62309, 62459–62490).
        for p in L.activePlacements where (1840...1843).contains(p.type) {
            let k = try SetupFaces.setup(p, context: c).slot
            let out = p.p2 == 0 ? 32000 : Int(p.p2)
            XCTAssertEqual([Int(k.classWord150), Int(k.classWord154), Int(k.counterA6), Int(k.phase)],
                           [out, Int(p.p3), Int(p.p4), Int(p.p4) < out ? 0 : 0xb], "spike \(p.index)")
            if p.type == 1842 { XCTAssertEqual(Int(k.classWord158), k.y, "spike \(p.index)") }
        }
        // The path bats 1851 (= 0x73b, records 393, 394) p1 2, p2 360, p3 1200 (no level-11 1851 has p3 1200): the 0x73b arm
        // (M l. 68108–68316) — gravity 0, `.SetupProgrammedPath` (M l. 39288–39381) mode 2: `+0x100` = x256 + 8·p3,
        // `+0x104` = x256 + 256·p2 − 8·p3, vx = p3; p1 ≥ 0 → not the back arm (M l. 68262–68273): layer kept, `+0x160` 0,
        // counted.
        for i in indices(1851) {
            let p = rec(i), k = try setup(i).slot
            XCTAssertEqual([p.p1, p.p2, p.p3, p.p4], [2, 360, 1200, 0], "bat \(i)")
            let x256 = Int32(p.x) << 8
            XCTAssertEqual([k.pathMode, k.pathLow, k.pathHigh, k.vx, Int32(k.gravity), k.classWord160],
                           [2, x256 + 8 * 1200, x256 + 256 * 360 - 8 * 1200, 1200, 0, 0], "bat \(i)")
            XCTAssertNotEqual(k.layer, 8, "bat \(i): not the back arm")
            XCTAssertTrue(k.countedInTotals, "bat \(i): counted")
        }
        // The platforms 1400 (0x578; their Setup is the first Handle's `.DoSetupPlatformSprite`, M l. 54541–55025):
        // records 180, 241, 419 mode 1 (the vertical shuttle, M l. 54652–54664) and 242, 321, 409, 485 mode 2 (the
        // horizontal shuttle, M l. 54665–54677), p2 130…448, p3 1000…1800 (new): bounds `+0x150` = v + 8·p3, `+0x154` =
        // v + 256·p2 − 8·p3, the speed p3, p4 0; mode 1 sag 0, mode 2 keeps 0x50.
        func doSetup(_ i: Int) throws -> SpriteSlot {
            let id = try put(i)
            PlatformSprite.doSetup(w, id: id)
            return try XCTUnwrap(w.active.record(id: id))
        }
        XCTAssertEqual(indices(1400).map { Int(rec($0).p1) }, [1, 1, 2, 2, 2, 1, 2], "the 1400s' modes")
        for i in indices(1400) {
            let p = rec(i)
            let before = try setup(i).slot
            let k = try doSetup(i)
            let horizontal = p.p1 == 2
            let v: Int = Int(horizontal ? before.x256 : before.y256)
            let p2 = Int(p.p2), p3 = Int(p.p3)
            XCTAssertEqual([Int(k.subtype), Int(k.classWord150), Int(k.classWord154), Int(horizontal ? k.vx : k.vy),
                            Int(horizontal ? k.vy : k.vx), Int(horizontal ? k.x256 : k.y256), Int(k.sag)],
                           [Int(p.p1), v + 8 * p3, v + 256 * p2 - 8 * p3, p3, 0, v, horizontal ? Int(before.sag) : 0],
                           "platform \(i)")
            _ = w.active.remove(id: k.id)
        }
        // The crates 3090 (0xc12; record 92 p3 5 — levels 1, 15: p3 ≤ 3) and 3091 (0xc13, 14 records, first placed
        // here): `.KillCrate` (M l. 61257–61316) — p1 0 → p3 drops of type p2 through `.SetupBonusSprite` (a Bonus drop),
        // p3 ≠ 1 → each its own vx (M l. 61286–61289); p1 2 → snd 435 and an Effect 0x4b7, no drop (M l. 61259–61263).
        let crates = indices(3090) + indices(3091)
        XCTAssertEqual(crates.filter { rec($0).p1 == 2 }, [262, 263, 264, 293, 295, 296, 298, 300, 301], "the p1-2 crates")
        for i in crates {
            let p = rec(i)
            let id = try put(i)
            XCTAssertEqual(try XCTUnwrap(w.active.record(id: id)).classTimer, Int32(p.p1), "crate \(i): `+0x14c` = p1")
            w.active.update(id: id) { $0.hp = 0 }
            let before = Set(w.active.sprites.map(\.id))
            _ = w.player.drainFrameOutputs()
            var lights = LightTable()
            BoxSprite.killCrate(w, id: id, lights: &lights, effects: 1)
            let made = w.active.sprites.filter { !before.contains($0.id) }
            let cues = w.player.drainFrameOutputs().cues.map(\.snd)
            if p.p1 == 2 {
                XCTAssertEqual([p.p2, p.p3], [0, 0], "crate \(i)")
                XCTAssertEqual(made.filter { $0.type == 0x4b7 }.count, 1, "crate \(i): the explosion")
                XCTAssertTrue(cues.contains(435), "crate \(i): the bang")
                XCTAssertEqual(made.filter { (0x50a...0x50d).contains($0.type) }.count, 0, "crate \(i): no drop")
            } else {
                XCTAssertEqual(p.p1, 0, "crate \(i)")
                let drops = made.filter { $0.type == p.p2 - 1290 + 0x50a }
                XCTAssertEqual(drops.count, Int(p.p3), "crate \(i): p3 drops of \(p.p2)")
                for d in drops { XCTAssertEqual(d.pickupDelay, 0xc, "crate \(i): through `.SetupBonusSprite`") }
                if p.p3 == 1 { XCTAssertEqual(drops.map(\.vx), [0], "crate \(i): one drop, no vx") }
                XCTAssertFalse(cues.contains(435), "crate \(i): no bang")
            }
            for d in made { _ = w.active.remove(id: d.id) }
            _ = w.active.remove(id: id)
        }
        XCTAssertEqual([Int(rec(92).p2), Int(rec(92).p3)], [1290, 5], "crate 92")
        // The ropes 3022 (0xbce, 8 records, their two ends p1…p4 new): `.SetupRopeSegArray` (M l. 71245–71455) — span
        // p3 − p1 → (span + 12) / 24 segments of 24, dy = p4 − p2.
        var ropes: [[Int]] = []
        for i in indices(3022) {
            let id = try put(i)
            RopeSprite.setupSegArray(w, id: id)
            let k = try XCTUnwrap(w.active.record(id: id))
            ropes.append([i, Int(k.classWord150), Int(k.classTimer), Int(k.rope?.dy ?? 0)])
            _ = w.active.remove(id: id)
        }
        XCTAssertEqual(ropes, [[216, 9, 216, 15], [225, 10, 240, 41], [226, 8, 192, -7], [228, 17, 408, 7],
                               [232, 6, 144, -1], [233, 6, 144, 1], [234, 6, 144, 0], [235, 10, 240, 34]], "ropes")
        // The blades 3060 (0xbf4, 13 records) p4 0 (level 20: p4 1): the Handle's bottom clip `+0x1ba = 0x5e` (M l.
        // 63527–63529) — `BladeTests.testBladeBottomClipWhenP4Zero` runs every one; here the census.
        XCTAssertEqual(Set(indices(3060).map { rec($0).p4 }), [0], "every blade p4 0")
        // The carpet 1080 (record 486, p1…p4 0) is 6A-CP's (`CarpetTests`); Dimbo 2956 (record 405) p1 221 is
        // `testDimboConversationActions`'s.
        XCTAssertEqual([Int(rec(486).type), Int(rec(405).type), Int(rec(405).p1)], [1080, 2956, 221])
    }

    func testBuiltLevelsTwentyTwo() throws {
        XCTAssertEqual(BuiltLevels.list, [1, 2, 3, 4, 5, 10, 11, 15, 18, 20, 21, 22], "the built levels")
        XCTAssertTrue(BuiltLevels.contains(22), "level 22")
        for n in [12, 16, 19, 23, 25, 30, 40] { XCTAssertFalse(BuiltLevels.contains(n), "level \(n)") }
        XCTAssertEqual(BuiltLevels.notBuiltReport(25), "Level 25 is not built yet (Phase 6).", "level 25's report")
        let r = try TenEleven.resources()
        // `startLevel` 22 (the hidden `FerazelLevel` switch) is accepted: New Game there, nothing asked.
        let rig = TenElevenRig(r, start: 22)
        rig.newGame(level: 22)
        XCTAssertEqual(rig.flow.levelNumber, 22, "New Game at 22")
        XCTAssertEqual(rig.levels.prepared, [22], "level 22 prepared")
        XCTAssertEqual(rig.asked, [], "nothing asked")
        // The map: node 22's links [21, 25] (node 21's [20, 22, 70]: level 21's exit 140 → node 22, `LevelTwentyOneTests`).
        let map = try WorldMap.load(from: r)
        XCTAssertEqual(try XCTUnwrap(map.findCurrNode(level: 22)).links, [21, 25, 0, 0, 0, 0, 0], "node 22's links")
        // Level 22's exits: record 13 p1 −1, record 208 p1 1. Exit 208 → node 25 (links[1]) → Return → the not-built
        // report, still on the map.
        let L = try LevelFile.load(from: r, level: 22)
        XCTAssertEqual(L.activePlacements.filter { $0.type == 3249 }.map { [$0.index, Int($0.p1)] }, [[13, -1], [208, 1]],
                       "level 22's exits")
        try rig.exit(208, toNode: 25)
        XCTAssertEqual(rig.asked.last, .report(text: "Level 25 is not built yet (Phase 6)."), "the not-built report")
        XCTAssertNil(rig.flow.levelRun, "still on the map")
        XCTAssertEqual(rig.levels.prepared, [22], "no level prepared after 22")
        // A save made on level 22 (a save point's block, the level's own records) continues there through
        // `.ContinueGame`: level 22 runs, nothing asked.
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 22, x: L.header.startX, y: L.header.startY,
                           stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L.placements)
        let cont = TenElevenRig(r, start: 1)
        cont.files.block = save
        cont.drive { $0.state == .mainMenu }
        cont.drive({ _ in [0x0f] }) { _ in true }                          // R: Continue
        cont.drive { _ in cont.askedFile }
        cont.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/twentyTwo"),
                                                displayName: "twentyTwo")))
        cont.drive { f in f.levelRun?.levelNumber == 22 && (f.levelRun?.iterations ?? 0) >= 1 }
        XCTAssertEqual(cont.asked, [], "Continue: nothing asked")
        XCTAssertEqual(cont.flow.levelNumber, 22, "Continue: level 22")
        XCTAssertEqual(cont.levels.prepared, [22], "Continue: level 22 prepared")
    }

    /// Dimbo's conversation 221 (level 22, record 405, type 2956; LL §5: condition 5, actions 5, 9 and 10) played in the
    /// level through the level runner and the real conversation code (`.HitPlayerSprite`'s NPC arm → `.Conversation`,
    /// `ConversationRun`, `ConvActions` — M l. 66164–66376), with world flag 5 set as Nimbo leaves it and level 11's
    /// snapshot as leaving level 11 stored it (`.EndLevelSGUpdate`, M l. 6501ff): line #20's condition 5 holds → #5…#9;
    /// action 5 sets world flag 6, action 9 kills the talker and zeroes its record's spawn byte (M l. 66339–66344),
    /// action 10 sets the spawn byte of level 11's snapshot record 283 (`+0x19998 + 0x2000·11 + 16·283`, M l.
    /// 66346–66347). Then level 11 opened with that save and that G (a revisit: `.SetupLevel` restores the snapshot, M
    /// l. 2405–2409) spawns record 283 — the dormant Dimbo (spawn byte 99 in the level file) — and it talks: Mcnv 220
    /// (D70.1). The twin with world flag 5 clear shows line #1 only and arms nothing.
    func testDimboConversationActions() throws {
        let r = try TenEleven.resources()
        let L11 = try LevelFile.load(from: r, level: 11), L22 = try LevelFile.load(from: r, level: 22)
        XCTAssertEqual([Int(L22.placements[405].type), Int(L22.placements[405].flag), Int(L22.placements[405].p1)],
                       [2956, 1, 221], "level 22 record 405")
        XCTAssertEqual([Int(L11.placements[283].type), Int(L11.placements[283].flag), Int(L11.placements[283].p1)],
                       [2956, 99, 220], "level 11 record 283")
        // Mcnv 221's actions, as read: line #7 action 5 (flag 6 = 1); line #8 action 9 (its A 1 read by no arm) and action
        // 10 (record 283, level 11).
        let lines = try Conversation.load(from: r, id: 221).lines
        var acts: [[Int]] = []
        for (n, l) in lines.enumerated() {
            for a in [l.action1, l.action2] where a.type != 0 { acts.append([n + 1, Int(a.type), Int(a.a), Int(a.b)]) }
        }
        XCTAssertEqual(acts, [[7, 5, 6, 1], [8, 9, 1, 0], [8, 10, 283, 11]], "Mcnv 221's actions (line, type, A, B)")

        let prefs = FerazelPrefs()
        func run(level: Int, carry: LevelCarry, save: SaveBlock) throws -> LevelRun {
            try LevelRun(resources: r, prefs: prefs, level: level, seed: 1, carry: carry, save: save, fade: ScreenFade(),
                         music: MusicFade(), services: LevelFixture.Headless(),
                         sounds: StageSounds(prefs: prefs, lengths: [:]))
        }
        var now: UInt32 = 0
        func tick(_ run: LevelRun, keys: [Int] = []) throws {
            _ = try run.tick(now: now, input: FrontInput(keys: KeyState(pressed: keys)))
            now &+= 1
        }
        func put(_ run: LevelRun, x: Int, y: Int) throws {
            let s = try XCTUnwrap(run.session)
            let pid = try XCTUnwrap(s.world.playerID)
            s.world.active.update(id: pid) { p in
                p.x = x; p.y = y; p.x256 = Int32(x) << 8; p.y256 = Int32(y) << 8; p.vx = 0; p.vy = 0
            }
        }
        /// The level run to its 45th loop iteration (past the chapter card; `TenElevenRig.newGame`'s point), then the
        /// player put on `rec` (x, y − 0x20) until a conversation opens.
        func talk(_ run: LevelRun, record p: Placement) throws -> ConversationRun {
            var k = 0
            while run.iterations < 45 && k < 8000 { try tick(run); k += 1 }
            try put(run, x: Int(p.x), y: Int(p.y) - 0x20)
            k = 0
            while run.conversation == nil && k < 600 { try tick(run); k += 1 }
            return try XCTUnwrap(run.conversation, "a conversation within 600 ticks")
        }
        /// The conversation answered: every "press any key" by one tick of a key ('S').
        func finish(_ run: LevelRun, _ conv: ConversationRun) throws {
            var k = 0
            while run.conversation != nil && k < 40000 {
                try tick(run, keys: conv.wait == .anyKey ? [0x01] : [])
                k += 1
            }
            XCTAssertNil(run.conversation, "the conversation ended")
        }

        // Leaving level 11 (records as the level file has them) stores its snapshot and sets `hasSnapshot[11]`; Nimbo
        // set world flag 5.
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.endLevelSGUpdate(level: 11, x: L11.header.startX, y: L11.header.startY,
                              stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g, records: L11.placements)
        g.worldFlags[5] = 1
        XCTAssertEqual([Int(g.hasSnapshot[11]), Int(save.snapshots[11][283].flag)], [1, 99], "level 11 left, record 283 dormant")
        var carry = LevelCarry()
        carry.globals = g

        // The twin first: world flag 5 clear — line #1 only, nothing written.
        do {
            var g0 = g
            g0.worldFlags[5] = 0
            var c0 = LevelCarry()
            c0.globals = g0
            let twin = try run(level: 22, carry: c0, save: save)
            let conv = try talk(twin, record: L22.placements[405])
            try finish(twin, conv)
            XCTAssertEqual(conv.shown, [1], "flag 5 clear: line #1")
            XCTAssertEqual(Int(twin.save.snapshots[11][283].flag), 99, "flag 5 clear: record 283 still dormant")
            XCTAssertEqual(Int(try XCTUnwrap(twin.session).world.records[405].flag), 1, "flag 5 clear: Dimbo stays")
        }

        // Level 22, flag 5 set: the conversation as the game plays it.
        let l22 = try run(level: 22, carry: carry, save: save)
        let conv = try talk(l22, record: L22.placements[405])
        guard case .conversation(let id, let record, _) = conv.kind else { return XCTFail("a conversation") }
        XCTAssertEqual([Int(id), record], [221, 405], "Mcnv 221 on record 405")
        try finish(l22, conv)
        XCTAssertEqual(conv.shown, [5, 6, 7, 8, 9], "flag 5 set: #20 → #5…#9")
        let s22 = try XCTUnwrap(l22.session)
        XCTAssertEqual(s22.world.globals.worldFlags[6], 1, "action 5: world flag 6")
        XCTAssertEqual(Int(s22.world.records[405].flag), 0, "action 9: the talker's spawn byte 0")
        XCTAssertFalse(s22.world.active.sprites.contains { $0.recordIndex == 405 && !$0.dead }, "action 9: the talker killed")
        XCTAssertEqual(Int(l22.save.snapshots[11][283].flag), 1, "action 10: level 11's record 283 armed")
        XCTAssertEqual(l22.save.snapshots[11].filter { $0.flag == 1 }.count,
                       save.snapshots[11].filter { $0.flag == 1 }.count + 1, "action 10 arms that record alone")

        // Level 11 opened with what level 22 left (its save block and its G): a revisit; record 283 spawns and talks.
        let l11 = try run(level: 11, carry: l22.carry, save: l22.save)
        let p283 = L11.placements[283]
        let conv11 = try talk(l11, record: p283)
        XCTAssertTrue(l11.revisit, "a revisit (`hasSnapshot[11]`)")
        let w11 = try XCTUnwrap(l11.session).world
        XCTAssertEqual([Int(w11.records[283].type), Int(w11.records[283].flag), Int(w11.records[283].x), Int(w11.records[283].y)],
                       [2956, 1, Int(p283.x), Int(p283.y)], "record 283 restored, armed, at the level file's place")
        guard case .conversation(let id11, let record11, _) = conv11.kind else { return XCTFail("a conversation on level 11") }
        XCTAssertEqual([Int(id11), record11], [220, 283], "the armed Dimbo talks: Mcnv 220")
        try finish(l11, conv11)
        XCTAssertEqual(conv11.shown, [1], "Mcnv 220: one line")
    }
}

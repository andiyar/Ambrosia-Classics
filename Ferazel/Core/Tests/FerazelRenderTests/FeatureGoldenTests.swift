import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// The 6A feature goldens (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, "Verification-model additions for
/// 6A": "New goldens are new values, not moves"): each engine-feature task pins its feature on a level fixture (6A-FX)
/// — the fixture's world, never the real level's. Measured by the build (D46.4), never invented; a later change is a
/// STOP unless a task marked ◈ names this golden. A missing data file is a FAILURE, never a skip.
final class FeatureGoldenTests: XCTestCase {

    /// 6A-S8: level 10's fixture (`HorizonStripTests.level10`, 31 records left out), the player started at
    /// `HorizonStripTests.stripStart` (600, 1150) (the header's start never shows the strip), seed 1, `FerazelPrefs()` —
    /// the fixture's first presented frame (`LevelFixtureServices.firstPresentedFrame`), which is also the first in which
    /// the horizon strip changed a frame byte inside the view (`HorizonStripTests.firstStripFrame`, asserted equal); then
    /// the first presented frame in which a drawn tile hides strip pixels. Kept at 6A-L10L11; 6A-WD may move it (◈: wind
    /// cells in the frame).
    func testLevel10StripFeatureGolden() throws {
        let (plain, plainServices) = try LevelFixtureServices.open(level: 10, leaveOut: HorizonStripTests.level10,
                                                                   start: HorizonStripTests.stripStart)
        let first = try plainServices.firstPresentedFrame(plain)
        // The same run with its sprite pass split around the strip: the same frame, and the strip's bytes in it.
        let (run, services) = try LevelFixtureServices.open(level: 10, leaveOut: HorizonStripTests.level10,
                                                            start: HorizonStripTests.stripStart)
        let f = try HorizonStripTests.firstStripFrame(run, services)
        XCTAssertEqual(f.ticks, first.ticks)
        XCTAssertEqual(f.fnv, first.fnv)
        XCTAssertGreaterThan(f.changed, 0)
        // Measured at 6A-S8 (FNV-1a 64 of the 640×480 screen indices after that tick's level draws, the test colour
        // model): the first presented frame — the first `.GameLoop` iteration, after level 10's chapter card — on the
        // 1,612th tick (now 1611).
        XCTAssertEqual(run.iterations, 1)
        XCTAssertEqual(f.changed, 9526, "the frame bytes the strip changed in view")
        XCTAssertEqual(first.ticks, 1612)
        XCTAssertEqual(String(first.fnv, radix: 16), "e471fa3eeca627d3", "the level-10 strip feature golden")
        // At tick 1612 the strip lies wholly over open sky (frame 0 under a 0xff mask), so that frame cannot tell mode 8
        // from a plain copy. The first presented frame in which a drawn tile hides strip pixels (measured, 6A-S8 review):
        // the 1,658th tick (now 1657).
        var now = first.ticks
        var presented = false
        while now < 1658 { presented = try plainServices.step(plain, now: now); now += 1 }
        XCTAssertTrue(presented)
        XCTAssertEqual(String(LevelFixtureServices.fnv1a(try XCTUnwrap(plainServices.renderer).screen.pixels), radix: 16),
                       "e8fc9d1805afb1d5", "the strip behind tiles")
    }

    // MARK: - 6A-WD: wind cells

    /// 6A-WD's player start on level 10's fixture (`LevelRun`'s `start:` override): the player's hot-rect centre
    /// (x + 50, y + 59) = (7152, 1168), in tile column 223 — the first column with strength-50 wind cells (o1 9, the
    /// updraft) — and row 36. There the updraft's push 14·50 = 700 beats gravity 440, so the wind holds the player
    /// bobbing in rows 33–36 of the column (row 33 is strength 20, rows 34–36 strength 50). The literal first o1 = 9
    /// column (222) holds only strength-20 cells (push 280 < gravity): a player there falls through (6A-WD review).
    static let windStart = (x: 7102, y: 1109)

    /// One game frame of the player (after that `.GameLoop` iteration): `+0x14` x256, `+0x2c` vy, the ramp `+0x96`,
    /// `+0x98`, the in-wind flag `+0x92` and the centre's cell.
    struct WindFrame: Equatable {
        let x256: Int32, vy: Int32, ramp: Int16, last: Int16, inWind: Bool, col: Int, row: Int
    }

    /// The level-10 wind trace: the fixture (`HorizonStripTests.level10`, 31 left out), seed 1, `FerazelPrefs()`, the
    /// player started at `windStart`, no input; the player's slot after each of the first `frames` `.GameLoop`
    /// iterations (the first is the first presented frame, after the chapter card), and the FNV of the screen after the
    /// last one (each iteration presents).
    static func windTrace(frames: Int = 60) throws -> (trace: [WindFrame], ticks: UInt32, fnv: UInt64) {
        let (run, services) = try LevelFixtureServices.open(level: 10, leaveOut: HorizonStripTests.level10,
                                                            start: windStart)
        let first = try services.firstPresentedFrame(run)
        XCTAssertEqual(run.iterations, 1)
        let session = try XCTUnwrap(run.session)
        func sample() throws -> WindFrame {
            let p = try XCTUnwrap(session.world.active.sprite(id: session.playerID))
            XCTAssertEqual(p.windScale, 0x100)
            return WindFrame(x256: p.x256, vy: p.vy, ramp: p.windRamp, last: p.windLast, inWind: p.inWind,
                             col: p.centre.x >> 5, row: p.centre.y >> 5)
        }
        var trace = [try sample()]
        var now = first.ticks, fnv = first.fnv
        while trace.count < frames {
            let before = run.iterations
            let presented = try services.step(run, now: now)
            now += 1
            guard run.iterations != before else { XCTAssertFalse(presented); continue }
            XCTAssertEqual(run.iterations, before + 1)
            XCTAssertTrue(presented, "every iteration presents")
            trace.append(try sample())
            fnv = LevelFixtureServices.fnv1a(try XCTUnwrap(services.renderer).screen.pixels)
        }
        return (trace, now, fnv)
    }

    /// FNV-1a 64 over the trace's fields (big-endian), in order.
    static func hash(_ trace: [WindFrame]) -> UInt64 {
        var bytes: [UInt8] = []
        func put(_ v: Int32) { bytes += [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: v >> $0) } }
        for f in trace {
            put(f.x256); put(f.vy); put(Int32(f.ramp)); put(Int32(f.last)); put(f.inWind ? 1 : 0)
            put(Int32(f.col)); put(Int32(f.row))
        }
        return LevelFixtureServices.fnv1a(bytes)
    }

    /// 6A-WD: 60 frames of the player held by the updraft in level 10's column 223 (ENG §2.2 "First level / golden"),
    /// frame by frame. What this trace cannot show: o1 9 is mode 27, whose push is vertical only (h = 0), so the
    /// sideways push, the ramp's effect on x and the leaving arm's x never move anything here (`+0x98` stays 0), the
    /// player never leaves the wind, and o1 9 never takes the crossed gates — those are WindTests' synthetic cells.
    /// Kept for good (6A-L10L11 keeps it on the fixture).
    func testLevel10WindTrace() throws {
        let t = try Self.windTrace()
        XCTAssertEqual(t.trace.count, 60)
        // In wind every frame but the first: before the player's first Handle its centre is (0, 0) (no
        // `.StandardSpriteCleanup` yet). With h = 0 and vx = 0 the x-gate (h ≥ vx) is always open, so `+0x92` is
        // earned even on the frames the y-gate shuts the push.
        XCTAssertEqual(t.trace.map(\.inWind), [false] + [Bool](repeating: true, count: 59))
        // The ramp `+0x96`: up 1 a frame in wind to 33, then held.
        XCTAssertEqual(t.trace.map(\.ramp), [0] + (1...33).map { Int16($0) } + [Int16](repeating: 33, count: 26))
        // Mode 27's h = 0: `+0x98` stores 0 and x256 never moves; the centre never leaves column 223.
        XCTAssertEqual(Set(t.trace.map(\.last)), [0])
        XCTAssertEqual(Set(t.trace.map(\.x256)), [7102 << 8])
        XCTAssertEqual(Set(t.trace.map(\.col)), [223])
        XCTAssertEqual(t.trace.map(\.row), [Int](repeating: 36, count: 10) + [Int](repeating: 35, count: 13)
                       + [Int](repeating: 34, count: 12) + [Int](repeating: 33, count: 7)
                       + [Int](repeating: 34, count: 6) + [Int](repeating: 33, count: 5)
                       + [Int](repeating: 34, count: 4) + [Int](repeating: 33, count: 3))
        XCTAssertEqual(t.trace.map(\.vy), [440, 180, -80, -340, -600, -860, -420, -680, -940, -500,
                                           -760, -320, -580, -840, -400, -660, -920, -480, -740, -1000,
                                           -560, -820, -380, -640, -900, -460, -720, -980, -540, -800,
                                           -360, -620, -880, -440, -700, -960, -520, -80, 80, 240,
                                           400, 560, 720, 460, 200, -60, -320, -580, -840, -400,
                                           40, 200, 360, 520, 260, 1, -259, -519, -79, 81])
        // Each frame's vy step: the wind first (`.StandardSpriteHandles`, on the cell under the previous frame's
        // centre: row 33 is o2 20, rows 34–36 o2 50; the y-gate passes while vy ≥ −15·o2 and pushes −14·o2, scale
        // 0x100 so no shift, never ramped), then gravity 440 in the player's Handle — whose step ends `vy == 0 → 1`
        // (`Player.swift:286`, `.HandlePlayerSprite` M l. 44958–44968). That lands once: index 55
        // (260 − 700 + 440 = 0).
        var zeroes: [Int] = []
        for i in 1..<60 {
            let prev = t.trace[i - 1]
            let o2: Int32 = prev.row == 33 ? 20 : 50
            let push: Int32 = prev.vy >= -15 * o2 ? 14 * o2 : 0
            var vy = prev.vy - push + 440
            if vy == 0 { zeroes.append(i); vy = 1 }
            XCTAssertEqual(t.trace[i].vy, vy, "frame \(i)")
        }
        XCTAssertEqual(zeroes, [55], "the gravity step's 0 becomes 1")
        // The whole trace (measured at the 6A-WD review fix round, seed 1): FNV-1a 64 of its fields.
        XCTAssertEqual(String(Self.hash(t.trace), radix: 16), "20b0a649c605b4d0", "the level-10 wind trace")
        XCTAssertEqual(t.ticks, 1730)
    }

    // MARK: - 6A-RC: rotating cannons

    /// 6A-RC's level-10 leave-out list (ENG §7.2; the card): the 27 records the port still refuses there once the
    /// rotating cannons are built — the trees and the Box scenery, by type. A literal list, never computed from what the
    /// port refuses today; not 6A-S8's 31 (those also leave the four rotating cannons out).
    static let level10Cannons: [LevelFixture.LeaveOut] = [
        // The trees (6A-TR): 3080 ×2, 3081 ×4, 3082 ×4, 3083 ×3.
        .type(3080), .type(3081), .type(3082), .type(3083),
        // The Box scenery (6A-BX1a): 2816 ×5, 2817, 2837 ×3, 2846 ×2, 2847 ×2, 2861.
        .type(2816), .type(2817), .type(2837), .type(2846), .type(2847), .type(2861),
    ]

    /// Where the player stands still (`LevelRun`'s `start:`; the cell's floor, no separation move) with a rotating
    /// cannon's Handle running: (4350, 627) beside record 89 (1090 at (4516, 869), p1 101, p2 15, p3 2) — the camera
    /// settles at (4096, 494), so 89 sits low in the view; (8400, 133) left of record 200 (1090 at (8551, 241), p1 103,
    /// p2 8, p3 1) — the camera settles at (8144, 0) with the whole cannon cell (screen x 407…557, y 241…391) in the
    /// 640 × 416 view.
    static let cannon89Start = (x: 4350, y: 627), cannon200Start = (x: 8400, y: 133)

    /// One game frame of a cannon (after that `.GameLoop` iteration): the aim `+0x46`, the pause `+0xa6`, the turn
    /// counter `+0x160`, the face cell, mirror and rotation `+0x1aa`, and the pixel position.
    struct CannonFrame: Equatable {
        let aim: Int16, pause: Int16, counter: Int32, face: Int, mirrored: Bool, rotation: Int16, x: Int, y: Int
    }

    /// Level 10's fixture (`level10Cannons`, 27 left out), seed 1, `FerazelPrefs()`, the player started at `start`, no
    /// input: record `record`'s cannon after each of the first `frames` `.GameLoop` iterations (the first is the first
    /// presented frame), the player's position and the camera after each, the screen FNV after each, the ticks run
    /// through each (its `now` + 1; two ticks an iteration after the first), and whether that iteration's cues
    /// (`FerazelSession.frameCues`) hold the pause's click 485 (from any cannon).
    static func cannonTrace(record: Int16, start: (x: Int, y: Int), frames: Int) throws
        -> (trace: [CannonFrame], player: [SpriteSlot.Point], scroll: [SpriteSlot.Point], fnv: [UInt64], ticks: [UInt32],
            clicks: [Bool]) {
        let (run, services) = try LevelFixtureServices.open(level: 10, leaveOut: level10Cannons, start: start)
        let first = try services.firstPresentedFrame(run)
        XCTAssertEqual(run.iterations, 1)
        let session = try XCTUnwrap(run.session)
        func sample() throws -> (CannonFrame, SpriteSlot.Point, SpriteSlot.Point) {
            let k = try XCTUnwrap(session.world.active.sprites.first { $0.recordIndex == record && $0.handler == .background },
                                  "record \(record) is active")
            let p = try XCTUnwrap(session.world.active.sprite(id: session.playerID))
            return (CannonFrame(aim: k.phase, pause: k.counterA6, counter: k.classWord160, face: k.face?.index ?? -1,
                                mirrored: k.mirrored, rotation: k.rotation, x: k.x, y: k.y),
                    SpriteSlot.Point(x: p.x, y: p.y),
                    SpriteSlot.Point(x: session.world.player.scrollH, y: session.world.player.scrollV))
        }
        func clicked() -> Bool { session.frameCues.contains { $0.snd == 485 } }
        let s0 = try sample()
        var trace = [s0.0], player = [s0.1], scroll = [s0.2], fnv = [first.fnv], ticks = [first.ticks]
        var clicks = [clicked()]
        var now = first.ticks
        while trace.count < frames {
            let before = run.iterations
            let presented = try services.step(run, now: now)
            now += 1
            guard run.iterations != before else { XCTAssertFalse(presented); continue }
            XCTAssertTrue(presented, "every iteration presents")
            let s = try sample()
            trace.append(s.0)
            player.append(s.1)
            scroll.append(s.2)
            fnv.append(LevelFixtureServices.fnv1a(try XCTUnwrap(services.renderer).screen.pixels))
            ticks.append(now)
            clicks.append(clicked())
        }
        return (trace, player, scroll, fnv, ticks, clicks)
    }

    /// FNV-1a 64 over a cannon trace's fields (big-endian), in order.
    static func hash(_ trace: [CannonFrame]) -> UInt64 {
        var bytes: [UInt8] = []
        func put(_ v: Int32) { bytes += [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: v >> $0) } }
        for f in trace {
            put(Int32(f.aim)); put(Int32(f.pause)); put(f.counter); put(Int32(f.face)); put(f.mirrored ? 1 : 0)
            put(Int32(f.rotation)); put(Int32(f.x)); put(Int32(f.y))
        }
        return LevelFixtureServices.fnv1a(bytes)
    }

    /// 6A-RC: two full turns of level 10's rotating cannons 89 (p1 101) and 200 (p1 103) on the fixture (ENG §2.3
    /// "First level / golden"), frame by frame: the aim, the pause and its count-down, the turn counter, and the face the
    /// aim gives. Kept for good (6A-L10L11 keeps it on the fixture).
    func testLevel10CannonTrace() throws {
        // The fixture's 27 records, by type, re-derived from the level file; the four rotating cannons are not among them.
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 10)
        let out = try LevelFixture.leftOut(real, Self.level10Cannons)
        XCTAssertEqual(out.count, 27, "the 27 refused records")
        var perType: [Int16: Int] = [:]
        for i in out { perType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(perType, [3080: 2, 3081: 4, 3082: 4, 3083: 3, 2816: 5, 2817: 1, 2837: 3, 2846: 2, 2847: 2,
                                 2861: 1])
        // Every listed type leaves at least one record out (no dead entry in the literal list).
        XCTAssertEqual(perType.count, Self.level10Cannons.count)
        let cannons = real.activePlacements.filter { BackgroundSprite.cannons.contains($0.type) && $0.p1 != 0 }
        XCTAssertEqual(cannons.map { [$0.index, Int($0.type), Int($0.p1), Int($0.p2), Int($0.p3), Int($0.p4)] },
                       [[89, 1090, 101, 15, 2, 0], [108, 1097, 101, 10, 1, 0], [200, 1090, 103, 8, 1, 0],
                        [250, 1090, 103, 15, 2, 1]])

        // Record 89 (101: step +1; p3 2 → 16 frames a turn; p2 15 → 15 frames' pause, the click as it reaches 0).
        let a = try Self.cannonTrace(record: 89, start: Self.cannon89Start, frames: 130)
        XCTAssertEqual(Set(a.player.map { [$0.x, $0.y] }), [[4350, 627]], "the player stands still")
        XCTAssertEqual(a.scroll.last, SpriteSlot.Point(x: 4096, y: 494))
        // Iteration 1 already ran the cannon's Handle once (the pause 15 → 14); it turns on iterations 16–31, 47–62,
        // 78–93, 109–124 — 64 steps, two full turns — and pauses 15 iterations between.
        XCTAssertEqual(a.trace.map(\.pause), (1...130).map { f -> Int16 in
            let k = (f - 16) % 31
            return f < 16 ? Int16(15 - f) : (k < 15 ? 0 : (k == 15 ? 15 : Int16(30 - k)))
        })
        XCTAssertEqual(a.trace.map(\.aim), (1...130).map { f -> Int16 in
            let turned = f < 16 ? 0 : ((f - 16) / 31) * 16 + min((f - 16) % 31 + 1, 16)
            return Int16(turned % 32)
        })
        XCTAssertEqual(a.trace.prefix(16).map(\.counter), [Int32](repeating: 16, count: 15) + [15])
        // The click 485 in the running level: every iteration whose count-down takes the pause 1 → 0 holds one (no voice
        // is playing it in the fixture: `FrontInput()`'s playing set is empty; another cannon's click in the same
        // iteration also counts) — iterations 15, 46, 77, 108.
        let ends89 = a.trace.indices.dropFirst().filter { a.trace[$0].pause == 0 && a.trace[$0 - 1].pause == 1 }
        XCTAssertEqual(ends89.map { $0 + 1 }, [15, 46, 77, 108])
        XCTAssertEqual(ends89.filter { a.clicks[$0] }, ends89, "record 89's pause ends click")
        XCTAssertEqual(Set(a.trace.map { [$0.x, $0.y] }), [[4516, 869]], "never recoiled: nothing fired")
        // The face as the aim gives it (built at W2b): a multiple of 4 → cell aim / 4 (≥ 5 mirrored, 8 − k), unrotated;
        // else cell 0 rotated 2·(((0x20 − aim)·0xb4 / 16) / 2).
        for f in a.trace {
            if f.aim % 4 == 0 {
                let k = Int(f.aim / 4)
                XCTAssertEqual([f.face, f.mirrored ? 1 : 0, Int(f.rotation)], k < 5 ? [k, 0, 0] : [8 - k, 1, 0])
            } else {
                XCTAssertEqual([f.face, f.mirrored ? 1 : 0, Int(f.rotation)],
                               [0, 0, Int((Int16(((32 - Int(f.aim)) * 0xb4 / 16) / 2)) << 1)], "aim \(f.aim)")
            }
        }

        // Record 200 (103: step +2; p3 1 → 8 / 2 = 4 frames a turn; p2 8 → 8 frames' pause): turns on iterations 9–12,
        // 21–24, … 93–96 — 64 steps — then pauses 8.
        let b = try Self.cannonTrace(record: 200, start: Self.cannon200Start, frames: 130)
        XCTAssertEqual(Set(b.player.map { [$0.x, $0.y] }), [[8400, 133]], "the player stands still")
        XCTAssertEqual(b.scroll.last, SpriteSlot.Point(x: 8144, y: 0))
        XCTAssertEqual(b.trace.map(\.aim), (1...130).map { f -> Int16 in
            let turned = f < 9 ? 0 : ((f - 9) / 12) * 4 + min((f - 9) % 12 + 1, 4)
            return Int16((turned * 2) % 32)
        })
        XCTAssertEqual(b.trace.map(\.pause), (1...130).map { f -> Int16 in
            let k = (f - 9) % 12
            return f < 9 ? Int16(8 - f) : (k < 3 ? 0 : (k == 3 ? 8 : Int16(11 - k)))
        })
        XCTAssertEqual(Set(b.trace.map { [$0.x, $0.y] }), [[8551, 241]])
        let ends200 = b.trace.indices.dropFirst().filter { b.trace[$0].pause == 0 && b.trace[$0 - 1].pause == 1 }
        XCTAssertEqual(ends200.count, 11)
        XCTAssertEqual(ends200.filter { b.clicks[$0] }, ends200, "record 200's pause ends click")

        // The two traces (measured at 6A-RC, seed 1): FNV-1a 64 of their fields.
        XCTAssertEqual(String(Self.hash(a.trace), radix: 16), "a94f59ac15d64d04", "record 89's trace")
        XCTAssertEqual(String(Self.hash(b.trace), radix: 16), "2970c03ffb33c302", "record 200's trace")
        XCTAssertEqual([a.ticks.first, a.ticks.last, b.ticks.first, b.ticks.last], [1612, 1870, 1612, 1870])
    }

    // MARK: - 6A-TR: trees and their branches

    /// 6A-TR's level-10 leave-out list (ENG §2.4 / §7.2; the card): the 14 records the port still refuses there once the
    /// trees are built — the Box scenery, by type. A literal list, never computed from what the port refuses today.
    static let level10Trees: [LevelFixture.LeaveOut] = [
        // The Box scenery (6A-BX1a): 2816 ×5, 2817, 2837 ×3, 2846 ×2, 2847 ×2, 2861.
        .type(2816), .type(2817), .type(2837), .type(2846), .type(2847), .type(2861),
    ]

    /// Where the player is dropped onto a mirrored tree's branch (`LevelRun`'s `start:`): level 10's record 35 (0xc08 at
    /// (4929, 1358), p1 1, face 226 wide) plants its first branch, `SetRect(0x62, 0xc, 0xb4, 0x24)` flipped to (46, 12,
    /// 128, 36), at (4975, 1370)…(5057, 1394). From (4945, 1270) the player's hot rect (x + 0x26…x + 0x3e, feet y + 0x55)
    /// spans 4983…5007 — inside that branch, outside where the unflipped one would be (5027…5109) — with the feet 15 px
    /// above its top.
    static let treeStart = (x: 4945, y: 1270)

    /// 6A-TR: level 10's fixture (`level10Trees`, 14 left out), seed 1, `FerazelPrefs()`, the player started at
    /// `treeStart`, no input — the first presented frame that shows the player standing on a tree's mirrored branch.
    /// Kept at 6A-L10L11 unless that task rules the frame redundant with level 10's first-frame golden (ENG §2.4).
    func testLevel10TreeFeatureGolden() throws {
        // The fixture's 14 records, by type, re-derived from the level file; the 13 trees are not among them.
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 10)
        let out = try LevelFixture.leftOut(real, Self.level10Trees)
        XCTAssertEqual(out.count, 14, "the 14 refused records")
        var perType: [Int16: Int] = [:]
        for i in out { perType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(perType, [2816: 5, 2817: 1, 2837: 3, 2846: 2, 2847: 2, 2861: 1])
        XCTAssertEqual(perType.count, Self.level10Trees.count)
        XCTAssertEqual(real.activePlacements.filter { BackgroundSprite.trees.contains($0.type) }.count, 13)
        let p35 = real.placements[35]
        XCTAssertEqual([Int(p35.type), Int(p35.p1), Int(p35.x), Int(p35.y)], [0xc08, 1, 4929, 1358])

        let (run, services) = try LevelFixtureServices.open(level: 10, leaveOut: Self.level10Trees, start: Self.treeStart)
        let first = try services.firstPresentedFrame(run)
        XCTAssertEqual(run.iterations, 1)
        let session = try XCTUnwrap(run.session)
        let w = session.world
        // The tree's first Handle (iteration 1, after that iteration's draw) planted its three branches, mirrored.
        let tree = try XCTUnwrap(w.active.sprites.first { $0.recordIndex == 35 && $0.handler == .background })
        XCTAssertTrue(tree.setupDone)
        XCTAssertTrue(tree.mirrored)
        let ids = [tree.siblings.first, tree.siblings.second, tree.siblings.third].compactMap { $0 }
        let branches = try ids.map { try XCTUnwrap(w.active.sprite(id: $0)) }
        XCTAssertEqual(branches.map { [$0.x, $0.y] }, [[4929 + 226 - 0xb4, 1358 + 0xc], [4929 + 226 - 0x66, 1358 + 0x31],
                                                       [4929 + 226 - 0xd6, 1358 + 0x4b]])
        // The planting frame's branches are solid Boxes in `.SetupBoxSprite`'s head state (ENG §2.4 item 5): the two
        // Xichrons (1055) placed on tree 35 are moved up onto the first and second branch in iteration 1's pass, and the
        // one on the first branch (from y 1360 to 1340) is collected by the player above it — score 10, one Xichron
        // (with the planting stubbed neither moves and nothing is collected in iteration 1; the falling player still takes
        // one later, by iteration 6).
        XCTAssertEqual([Int(w.globals.score), Int(w.globals.xichrons)], [10, 1])
        var now = first.ticks, fnv = [first.fnv], ticks = [first.ticks], riding: [Int?] = [], ys: [Int] = []
        func sample() throws {
            let p = try XCTUnwrap(w.active.sprite(id: session.playerID))
            riding.append(p.ridden)
            ys.append(p.y)
        }
        try sample()
        while fnv.count < 6 {
            let before = run.iterations
            let presented = try services.step(run, now: now)
            now += 1
            guard run.iterations != before else { XCTAssertFalse(presented); continue }
            XCTAssertTrue(presented, "every iteration presents")
            try sample()
            fnv.append(LevelFixtureServices.fnv1a(try XCTUnwrap(services.renderer).screen.pixels))
            ticks.append(now)
        }
        // The player falls (iterations 1–3) and lands on the first branch in iteration 4's pass: he rides it, feet on
        // its top (y + 0x55 = 1370). An iteration draws before its handle pass, so the landing first shows in iteration
        // 5's frame — the golden.
        XCTAssertEqual(ys, [1271, 1275, 1280, 1285, 1285, 1285])
        XCTAssertEqual(riding.prefix(3).map { $0 == nil }, [true, true, true])
        XCTAssertEqual(riding[3], ids.first, "standing on the mirrored first branch")
        XCTAssertEqual(riding[4], ids.first)
        // Measured at 6A-TR (FNV-1a 64 of the 640×480 screen indices after the iteration's draws, the test colour model).
        // With the branch planting stubbed (one local patch, never committed) the player falls past and this frame is
        // 707aa87324dfbee3 (he is at y 1295, still falling).
        XCTAssertEqual(ticks[4], 1620)
        XCTAssertEqual(String(fnv[4], radix: 16), "d7ba88433f138e72", "the level-10 tree feature golden")
    }

    // MARK: - 6A-RP: the river ripple

    /// 6A-RP's player start on level 11's fixture (`LevelRun`'s `start:` override): the header's start column (x 16299)
    /// dropped to y 600, just above the river (BG water fills rows 20–31, y 640…1023, across the level). From the
    /// header's own start (16299, 275) the camera opens at v 31 and settles at v 56, so no backdrop row ≥ 512 is ever on
    /// screen (measured, 6A-RP); from here it opens at v 388 — view rows 388…771 — with water cells in view. The moved
    /// start is ratified by the seat (6A-RP review round, as D51.1 for the tree): the level's own start never shows the
    /// ripple. So this golden must be KEPT when 6A-L10L11 adds level 11's own first-frame golden — that frame will not
    /// show the ripple, and this one is the only golden that does.
    static let rippleStart = (x: 16299, y: 600)

    /// Level 11's fixture (`RippleTests.level11`, 27 left out) with `header` patched, seed 1, `FerazelPrefs()`, the
    /// player started at `rippleStart` — its first presented frame (the first tick whose level draws hold a
    /// `.copyToScreen`, as `LevelFixtureServices.firstPresentedFrame`), the ops applied one at a time so that, at the
    /// copy, the same copy is also made with the ripple table emptied: the tick count, the renderer, the FNV of the
    /// screen indices, the screen bytes the ripple changed, and the copy's v.
    static func level11RippleFrame(header: [LevelFixture.HeaderPatch])
        throws -> (ticks: UInt32, renderer: FrameRenderer, fnv: UInt64, changed: Int, v: Int) {
        let (run, services) = try LevelFixtureServices.open(level: 11, leaveOut: RippleTests.level11, header: header,
                                                            start: rippleStart)
        var now: UInt32 = 0
        while now < 4000 {
            let out = try run.tick(now: now, input: FrontInput())
            now += 1
            var copied: (changed: Int, v: Int)?
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer, "a level draw before the renderer exists")
                for op in g.output.draws {
                    guard case .copyToScreen(let h, let v, let graphicsMode, let backdrop) = op else {
                        try r.apply(FrameOps(draws: [op]))
                        continue
                    }
                    var flat = r.parallax
                    flat.rippleTable = []
                    var plain = r.screen.pixels
                    try flat.copyToScreen(ports: r.ports, h: h, v: v, graphicsMode: graphicsMode, backdrop: backdrop,
                                          parallax: Int(r.prefs.parallax), screen: &plain)
                    try r.apply(FrameOps(draws: [op]))
                    copied = (zip(plain, r.screen.pixels).filter { $0 != $1 }.count, v)
                }
            }
            if let copied, let r = services.renderer {
                return (now, r, LevelFixtureServices.fnv1a(r.screen.pixels), copied.changed, copied.v)
            }
        }
        throw LevelFixtureServices.FrameFailure(now: now, description: "no presented level-11 frame within 4000 ticks")
    }

    /// 6A-RP: level 11's fixture (`RippleTests.level11`, 27 left out), seed 1, `FerazelPrefs()`, the player started at
    /// `rippleStart`, no input — the first presented frame, which is the first frame whose view shows a PxBack row ≥
    /// 512 (rows 388…771; yb = 256, so backdrop rows track the view 1:1), the ripple table non-zero there. Kept at
    /// 6A-L10L11 (not frame 1 of the level's own start, ENG §2.5).
    func testLevel11RippleFeatureGolden() throws {
        // The fixture's 27 records, by type, re-derived from the level file.
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 11)
        let out = try LevelFixture.leftOut(real, RippleTests.level11)
        XCTAssertEqual(out.count, 27, "the 27 refused records")
        var perType: [Int16: Int] = [:]
        for i in out { perType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(perType, [2816: 4, 2817: 2, 2831: 3, 2837: 1, 2857: 2, 2872: 6, 2873: 3, 2875: 2, 2876: 3,
                                 2955: 1])
        XCTAssertEqual(perType.count, RippleTests.level11.count)
        XCTAssertEqual([Int(real.header.parallaxRipple), Int(real.header.pxBackYFactor)], [1, 256])

        let f = try Self.level11RippleFrame(header: [])
        // The same frame through the fixture's own first-presented-frame helper (all of a tick's ops at once).
        let (run, services) = try LevelFixtureServices.open(level: 11, leaveOut: RippleTests.level11,
                                                            start: Self.rippleStart)
        let first = try services.firstPresentedFrame(run)
        XCTAssertEqual(run.iterations, 1)
        XCTAssertEqual(first.ticks, f.ticks)
        XCTAssertEqual(first.fnv, f.fnv)
        // The view's rows reach the river band (virtual rows 0x200…0x47f); the table is filled there (the phase this
        // first drawn call found is 0x200: row 0x200 −64, offset 1 px; row 0x280 −1651, 7 px), and the ripple moved
        // screen bytes in this frame.
        XCTAssertEqual(f.v, 388)
        XCTAssertGreaterThanOrEqual(f.v + 383, 0x200)
        XCTAssertEqual([f.renderer.parallax.rippleTable[0x200], f.renderer.parallax.rippleTable[0x280]], [-64, -1651])
        // Measured at 6A-RP (FNV-1a 64 of the 640×480 screen indices after that tick's level draws, the test colour
        // model): the first presented frame — the first `.GameLoop` iteration — on the 143rd tick (now 142). With the
        // drawn-frame fill stubbed (one local patch, never committed) the table stays 0, nothing moves and the frame is
        // 974417c1b079fa29.
        XCTAssertEqual(f.changed, 4912, "the screen bytes the ripple moved")
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual(String(f.fnv, radix: 16), "c92fbe9fb87250c3", "the level-11 ripple feature golden")
    }

    // MARK: - 6A-RN: the rain and the thunder

    /// A rain particle as `.DrawParticles` hands it on (`ParticleDraw`): one `.GenerateRain` made — the record in its
    /// slot has the rain's velocity (vx −700 light / −1200 heavy, vy 2100 / 3600), shape (4 / 5) and kind (5…7).
    static func isRain(_ d: ParticleDraw, _ pool: ParticlePool) -> Bool {
        let r = pool.records[d.slot]
        guard (5...7).contains(Int(d.kind)) else { return false }
        return (r.vx == -700 && d.shape == 4) || (r.vx == -1200 && d.shape == 5)
    }

    /// Level 15's fixture (nothing left out), seed 1, `FerazelPrefs()`, the header's start, no input: the first `count`
    /// presented frames — each one's tick count, the FNV-1a 64 of the screen indices and the rain particles its
    /// `.DrawParticles` held. `dropRain`: the twin — every frame's rain particles taken out of its `.DrawParticles`
    /// before the renderer draws it (the same run otherwise: Core never sees the change). `dropOmniPx` (6A-L15): the
    /// twin whose `.UpdateOmniPx` ops are taken out — the rain sheets never painted into the backdrop port. Used by
    /// `LevelFrameGoldenTests.testLevel15FirstFrameGolden`, which took over this file's rain golden at 6A-L15.
    static func level15Frames(count: Int, dropRain: Bool, dropOmniPx: Bool = false) throws
        -> [(ticks: UInt32, fnv: UInt64, rain: Int)] {
        let (run, services) = try LevelFixtureServices.open(level: 15, leaveOut: [])
        var now: UInt32 = 0, frames: [(ticks: UInt32, fnv: UInt64, rain: Int)] = []
        while frames.count < count && now < 4000 {
            let out = try run.tick(now: now, input: FrontInput())
            now += 1
            var presented = false, rain = 0
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer, "a level draw before the renderer exists")
                let pool = try XCTUnwrap(run.session).world.particles
                let draws = g.output.draws.compactMap { op -> DrawOp? in
                    if dropOmniPx, case .omniPx(.update) = op { return nil }
                    guard case .drawParticles(let list) = op else { return op }
                    let keep = list.filter { !isRain($0, pool) }
                    rain += list.count - keep.count
                    return dropRain ? .drawParticles(keep) : op
                }
                try r.apply(FrameOps(draws: draws))
                presented = presented || draws.contains { if case .copyToScreen = $0 { true } else { false } }
            }
            if presented, let r = services.renderer {
                frames.append((now, LevelFixtureServices.fnv1a(r.screen.pixels), rain))
            }
        }
        XCTAssertEqual(frames.count, count, "\(count) presented frames within 4000 ticks")
        return frames
    }

    /// 6A-RN: the first thunder's flash on level 15's fixture (nothing left out, seed 1, `FerazelPrefs()`; fading on,
    /// the default). The rain's own picture (6A-RN's `testLevel15RainFeatureGolden`, retired at 6A-L15) is now
    /// `LevelFrameGoldenTests.testLevel15FirstFrameGolden`'s, with both its twins. The first call's T = R(90) + 90
    /// counts down one a call; at 0 the thunder sets the flash count 3 (M l. 8458) and that same pass's flash step
    /// turns the toggle on (M l. 9426–9432, after the rain at M l. 9228): its `.WrapCopyToScreen` takes the mask port
    /// (`.copyMaskToScreen`). The twin is the same copy from the frame port (no flash). The frame is measured from the
    /// seed: iteration (T after the first call) + 2. Kept at 6A-L15.
    func testLevel15ThunderFlashFeatureGolden() throws {
        let (run, services) = try LevelFixtureServices.open(level: 15, leaveOut: [])
        var now: UInt32 = 0, afterFirst: Int?
        while now < 6000 {
            let out = try run.tick(now: now, input: FrontInput())
            now += 1
            if afterFirst == nil, run.iterations >= 1 { afterFirst = Int(try XCTUnwrap(run.session).rain.timer) }
            var flash: (twin: UInt64, changed: Int)?
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer)
                for op in g.output.draws {
                    guard case .copyMaskToScreen(let h, let v, let graphicsMode, let backdrop) = op else {
                        try r.apply(FrameOps(draws: [op]))
                        continue
                    }
                    var plain = r.screen.pixels
                    try r.parallax.copyToScreen(ports: r.ports, h: h, v: v, graphicsMode: graphicsMode,
                                                backdrop: backdrop, parallax: Int(r.prefs.parallax), screen: &plain)
                    try r.apply(FrameOps(draws: [op]))
                    flash = (LevelFixtureServices.fnv1a(plain), zip(plain, r.screen.pixels).filter { $0 != $1 }.count)
                }
            }
            guard let flash else { continue }
            let s = try XCTUnwrap(run.session)
            let r = try XCTUnwrap(services.renderer)
            let fnv = LevelFixtureServices.fnv1a(r.screen.pixels)
            // The thunder's pass: T −1, the count stepped once (3 → 2), the toggle on.
            XCTAssertEqual(s.rain.timer, -1)
            XCTAssertEqual(s.world.flash, ScreenFlash(count: 2, on: true))
            let t1 = try XCTUnwrap(afterFirst)
            XCTAssertEqual(run.iterations, t1 + 2, "the first thunder's iteration, from the seed")
            XCTAssertNotEqual(fnv, flash.twin, "the flash is in the picture")
            XCTAssertGreaterThan(flash.changed, 0)
            // Measured at 6A-RN (FNV-1a 64 of the screen indices, the test colour model): T after the first call 127
            // (R(90) = 38), so the thunder falls in iteration 129, on the 399th tick (now 398). With the rain's
            // generation stubbed (one local patch, never committed) no flash comes within 6000 ticks.
            XCTAssertEqual([t1, run.iterations, Int(now)], [127, 129, 399])
            XCTAssertEqual(flash.changed, 49797, "the screen bytes the flash changed")
            XCTAssertEqual(String(flash.twin, radix: 16), "1cc38d5f30226d2f", "the same frame with no flash")
            XCTAssertEqual(String(fnv, radix: 16), "597cd03adccc11ce", "the level-15 thunder flash feature golden")
            return
        }
        XCTFail("no flash within 6000 ticks")
    }

    // MARK: - 6A-CL: the clouds of Hangnabit

    /// 6A-CL's level-20 leave-out list (ENG §7.2; the card): the blades 3060 (28) and the maces 1485 (16), by type — 44
    /// records. The same literal as `CloudTests.level20` (the Render target cannot see a Core test's list); never
    /// computed from what the port refuses today.
    static let level20Clouds: [LevelFixture.LeaveOut] = [.type(3060), .type(1485)]

    /// One presented frame of level 20's fixture: its tick count, the screen's indices and their FNV-1a 64, and the
    /// cloud draws (faces 0xb4a…0xb4d) its `.WrapDrawSprites` held, as (PICT, x, y).
    struct CloudFrame {
        let ticks: UInt32
        let pixels: [UInt8]
        let fnv: UInt64
        let clouds: [[Int]]
    }

    /// Level 20's fixture (`level20Clouds`), seed 1, `FerazelPrefs()`, the header's start, no input: the first `count`
    /// presented frames. `dropClouds`: the twin — every cloud draw taken out of each `.WrapDrawSprites` before the
    /// renderer draws it (the same run otherwise: Core never sees the change).
    /// `leaveOut` (6A-L20): the level's real first frames use `[]` (nothing left out: the real level).
    static func level20CloudFrames(count: Int, dropClouds: Bool,
                                   leaveOut: [LevelFixture.LeaveOut] = level20Clouds) throws -> [CloudFrame] {
        let (run, services) = try LevelFixtureServices.open(level: 20, leaveOut: leaveOut)
        var now: UInt32 = 0, frames: [CloudFrame] = []
        while frames.count < count && now < 4000 {
            let out = try run.tick(now: now, input: FrontInput())
            now += 1
            var presented = false, clouds: [[Int]] = []
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer, "a level draw before the renderer exists")
                let draws = g.output.draws.map { op -> DrawOp in
                    guard case .wrapDrawSprites(let list) = op else { return op }
                    let keep = list.filter { !(0xb4a...0xb4d).contains($0.face.pict) }
                    clouds += list.filter { (0xb4a...0xb4d).contains($0.face.pict) }.map { [Int($0.face.pict), $0.x, $0.y] }
                    return dropClouds ? .wrapDrawSprites(keep) : op
                }
                try r.apply(FrameOps(draws: draws))
                presented = presented || draws.contains { if case .copyToScreen = $0 { true } else { false } }
            }
            if presented, let r = services.renderer {
                frames.append(CloudFrame(ticks: now, pixels: r.screen.pixels, fnv: LevelFixtureServices.fnv1a(r.screen.pixels),
                                         clouds: clouds))
            }
        }
        XCTAssertEqual(frames.count, count, "\(count) presented frames within 4000 ticks")
        return frames
    }

    /// 6A-CL: the first presented frame of level 20's fixture (44 left out, seed 1, `FerazelPrefs()`, the header's
    /// start, no input) with a cloud on screen — proved by its twin with every cloud draw removed, which differs. It is
    /// the level's frame 1 (the first `.GameLoop` iteration), so the clouds there stand where their Setups put them:
    /// the Handle pass runs after the draw (M l. 9207, 9453). Frame 2 is pinned beside it — the first frame drawn after
    /// the clouds' first Handle, their parallax applied. The clouds draw with mode 0xb arg 4 (translucency table 4) at
    /// layer 0x7ef4, in front of everything.
    /// - Frame 1 is a first-load frame, and there the port knowingly differs from the original: on a level's first
    ///   load the original's cloud Setup copies the placeholder PICT 150 face (the cached face is not loaded yet), so
    ///   the original would still show placeholders here, while the port draws the loaded cloud faces (the ruled port
    ///   difference noted at `SetupFaces.swift:21`, `FaceSource.setupCached`). 6A-L20 deleted the frame-1 pin here
    ///   (ENG §2.8 "First level / golden"); frame 1 is still drawn and proved by its twin.
    /// - Frame 2 matches the original: the clouds' first Handle has re-read their faces from the loaded cache. It is
    ///   the value that is kept.
    func testLevel20CloudFeatureGolden() throws {
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 20)
        let out = try LevelFixture.leftOut(real, Self.level20Clouds)
        XCTAssertEqual(out.count, 44, "the 44 refused records")
        var perType: [Int16: Int] = [:]
        for i in out { perType[real.placements[i].type, default: 0] += 1 }
        XCTAssertEqual(perType, [3060: 28, 1485: 16])

        let frames = try Self.level20CloudFrames(count: 2, dropClouds: false)
        let twin = try Self.level20CloudFrames(count: 2, dropClouds: true)
        guard frames.count == 2, twin.count == 2 else { return }          // a failure above, never a crash
        XCTAssertEqual(frames.map(\.ticks), twin.map(\.ticks))
        XCTAssertEqual(frames.map(\.clouds), twin.map(\.clouds), "the twin's run is the same run")
        let changed = (0..<2).map { k in zip(frames[k].pixels, twin[k].pixels).filter { $0 != $1 }.count }
        XCTAssertNotEqual(frames[0].fnv, twin[0].fnv, "a cloud is on screen in frame 1")
        XCTAssertNotEqual(frames[1].fnv, twin[1].fnv, "and in frame 2")
        // Frame 1: every cloud drawn at its record's own position (no Handle has run yet); frame 2: moved.
        let placed = Set(real.activePlacements.filter { (0xb4a...0xb4d).contains($0.type) }
            .map { [Int($0.type), Int($0.x), Int($0.y)] })
        XCTAssertEqual(placed.count, 164)
        XCTAssertFalse(frames[0].clouds.isEmpty)
        XCTAssertTrue(Set(frames[0].clouds).isSubset(of: placed))
        XCTAssertEqual(frames[0].clouds.count, frames[1].clouds.count)
        let moved = zip(frames[0].clouds, frames[1].clouds).filter { $0 != $1 }.count
        // Measured at 6A-CL (FNV-1a 64 of the 640×480 screen indices after that tick's level draws, the test colour
        // model). With the Handle's parallax stubbed (one local patch, never committed) frame 1 holds and frame 2 is
        // e63ae32a71d4526: no cloud moved, and the clouds change 25,886 bytes there, as in frame 1.
        XCTAssertEqual([Int(frames[0].ticks), Int(frames[1].ticks)], [143, 145])
        XCTAssertEqual([frames[0].clouds.count, moved], [164, 164], "all 164 drawn (none idled), all moved")
        XCTAssertEqual(changed, [25886, 31081], "the screen bytes the clouds changed")
        XCTAssertEqual(String(twin[0].fnv, radix: 16), "8964bdab39954f49", "frame 1 with no cloud drawn")
        // Frame 2: matches the original (faces re-read by the first Handle); kept.
        XCTAssertEqual(String(twin[1].fnv, radix: 16), "4679418e47ef711b", "frame 2 with no cloud drawn")
        XCTAssertEqual(String(frames[1].fnv, radix: 16), "37eb1f7eb12e8f76", "frame 2, the parallax applied")
    }

    // MARK: - 6A-BD: the rotating blade

    /// 6A-BD's level-20 leave-out list (ENG §2.9 / §7.2; the card): the 16 maces 1485 (every one a mode-1 path, 6A-MP),
    /// by type. The 28 blades are in. A literal list, never computed from what the port refuses today.
    static let level20Blades: [LevelFixture.LeaveOut] = [.type(1485)]

    /// Where the player starts (`LevelRun`'s `start:`): beside level 20's first blade cluster — records 93 (8149, 244),
    /// 95 (8150, 499), 241 (8149, 18), 244 (8756, 497) and 248 (8500, 146) — 160 px right of record 93's hub (8242, 337),
    /// beyond its arm's reach (hub + 88 = 8330 < his rect's left 8338).
    static let bladeStart = (x: 8300, y: 300)

    /// One presented frame of level 20's blade fixture: its tick count, the screen's indices and their FNV-1a 64, and the
    /// blade draws (face 0xbf4) its `.WrapDrawSprites` held, as (x, y, rotation, mode, bottom clip).
    struct BladeFrame {
        let ticks: UInt32
        let pixels: [UInt8]
        let fnv: UInt64
        let blades: [[Int]]
    }

    /// Level 20's fixture with `leaveOut`, seed 1, `FerazelPrefs()`, the player at `bladeStart`, no input: the first
    /// `count` presented frames. `dropBlades`: every blade draw taken out of each `.WrapDrawSprites` before the renderer
    /// draws it (the same run otherwise: Core never sees the change).
    static func level20BladeFrames(count: Int, leaveOut: [LevelFixture.LeaveOut],
                                   dropBlades: Bool) throws -> [BladeFrame] {
        let (run, services) = try LevelFixtureServices.open(level: 20, leaveOut: leaveOut, start: bladeStart)
        var now: UInt32 = 0, frames: [BladeFrame] = []
        while frames.count < count && now < 4000 {
            let out = try run.tick(now: now, input: FrontInput())
            now += 1
            var presented = false, blades: [[Int]] = []
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer, "a level draw before the renderer exists")
                let draws = g.output.draws.map { op -> DrawOp in
                    guard case .wrapDrawSprites(let list) = op else { return op }
                    blades += list.filter { $0.face.pict == BackgroundSprite.blade }
                        .map { [$0.x, $0.y, Int($0.rotation), Int($0.mode), $0.clip.bottom] }
                    return dropBlades ? .wrapDrawSprites(list.filter { $0.face.pict != BackgroundSprite.blade }) : op
                }
                try r.apply(FrameOps(draws: draws))
                presented = presented || draws.contains { if case .copyToScreen = $0 { true } else { false } }
            }
            if presented, let r = services.renderer {
                frames.append(BladeFrame(ticks: now, pixels: r.screen.pixels, fnv: LevelFixtureServices.fnv1a(r.screen.pixels),
                                         blades: blades))
            }
        }
        XCTAssertEqual(frames.count, count, "\(count) presented frames within 4000 ticks")
        return frames
    }

    /// 6A-BD: level 20's fixture (the 16 maces left out, seed 1, `FerazelPrefs()`, the player at `bladeStart`, no input).
    /// Frame 1 holds no blade: the blades were idled at the spawn (far from the header's start) and `.HandleIdleSprites`
    /// wakes them in iteration 1, after its draw; their first Handle (the same iteration) turns them 8° and sets the
    /// dynamic light. Frame 2 — the first frame with a blade on screen — is the golden; frame 3 (16°) is pinned beside
    /// it. Each is proved by its twin with every blade draw removed, which differs, while frame 1 does not; the twin is
    /// also the fixture with the 28 blades left out as well (the same three frames byte for byte), so the blades change
    /// nothing in these frames but their own pixels. Every blade here sits on a light byte −1 (level 20's grid is all
    /// −1) with no light near: L < 1 and F < 1 → `+0xb8 = 0`, a plain rotated copy (D67.1: an F ≥ 1 word there is formed as F 0's).
    func testLevel20BladeFeatureGolden() throws {
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 20)
        let out = try LevelFixture.leftOut(real, Self.level20Blades)
        XCTAssertEqual(out.count, 16, "the 16 refused records")
        XCTAssertEqual(Set(out.map { real.placements[$0].type }), [1485])
        XCTAssertEqual(real.activePlacements.filter { $0.type == BackgroundSprite.blade }.count, 28)

        let frames = try Self.level20BladeFrames(count: 3, leaveOut: Self.level20Blades, dropBlades: false)
        let twin = try Self.level20BladeFrames(count: 3, leaveOut: Self.level20Blades, dropBlades: true)
        let none = try Self.level20BladeFrames(count: 3, leaveOut: Self.level20Blades + [.type(3060)], dropBlades: false)
        guard frames.count == 3, twin.count == 3, none.count == 3 else { return }    // a failure above, never a crash
        XCTAssertEqual(frames.map(\.ticks), [143, 145, 147])
        XCTAssertEqual(twin.map(\.ticks), frames.map(\.ticks))
        XCTAssertEqual(frames.map(\.blades), twin.map(\.blades), "the twin's run is the same run")
        XCTAssertEqual(none.map(\.fnv), twin.map(\.fnv), "no blade drawn = no blade placed, in these frames")
        XCTAssertEqual(none.map(\.blades), [[], [], []])
        // Frame 1: no blade on the list. Frames 2 and 3: the five of the cluster, at their record positions, turned 8°
        // then 16°, mode 0 (the light word on light byte −1, F 0), the bottom clip open (p4 1).
        XCTAssertEqual(frames[0].blades, [])
        let cluster = [[8149, 244], [8150, 499], [8149, 18], [8756, 497], [8500, 146]]
        for (k, rot) in [(1, 8), (2, 16)] {
            XCTAssertEqual(Set(frames[k].blades.map { [$0[0], $0[1]] }), Set(cluster), "frame \(k + 1)")
            XCTAssertEqual(Set(frames[k].blades.map { [$0[2], $0[3], $0[4]] }), [[rot, 0, 32000]], "frame \(k + 1)")
        }
        for b in cluster {
            XCTAssertEqual(real.lightByte(col: (b[0] + 0x5d) >> 5, row: (b[1] + 0x5d) >> 5), -1, "under \(b)")
        }
        let changed = (0..<3).map { k in zip(frames[k].pixels, twin[k].pixels).filter { $0 != $1 }.count }
        XCTAssertEqual(frames[0].fnv, twin[0].fnv, "frame 1: no blade drawn")
        XCTAssertNotEqual(frames[1].fnv, twin[1].fnv, "a blade is on screen in frame 2")
        XCTAssertNotEqual(frames[2].fnv, twin[2].fnv, "and in frame 3")
        // Measured at 6A-BD (FNV-1a 64 of the 640×480 screen indices after that tick's level draws, the test colour
        // model).
        XCTAssertEqual(changed, [0, 1520, 1358], "the screen bytes the blades changed")
        XCTAssertEqual(String(twin[1].fnv, radix: 16), "9a2b74440c941f4c", "frame 2 with no blade drawn")
        XCTAssertEqual(String(frames[1].fnv, radix: 16), "91d21e527fca201f", "the level-20 blade feature golden")
        XCTAssertEqual(String(twin[2].fnv, radix: 16), "dd63720402386079", "frame 3 with no blade drawn")
        XCTAssertEqual(String(frames[2].fnv, radix: 16), "62cc02eb7433cde1", "frame 3, the blades turned 16°")
    }

    // MARK: - 6A-MP: the programmed-path maces

    /// 6A-MP's level-20 leave-out list (ENG §7.2; the card): none — the last level-20 feature, every record in. The
    /// level was a fixture only because it was not yet in `BuiltLevels` (it is since 6A-L20; the fixture's open is the
    /// real level's, with the moved start).
    static let level20Maces: [LevelFixture.LeaveOut] = []

    /// Where the player starts (`LevelRun`'s `start:`): between level 20's first path balls — records 266 (10436, 436)
    /// and 267 (10527, 436; p4 440) to the left, 268 (10913, 477) to the right — out of their reach; the level's wind
    /// holds him near y 300 and the camera settles at about (10432, 160), the balls' upper turning points in view.
    static let maceStart = (x: 10700, y: 300)

    /// One run of level 20's fixture (`leaveOut`, seed 1, `FerazelPrefs()`, the player at `maceStart`, no input) for
    /// `iterations` `.GameLoop` iterations: after each, record 266's ball (x, y, vy, direction `+0xf8`), the player's
    /// (x, hp), the number of balls 1485 on the list; and per presented frame its ticks, screen FNV-1a 64 and the
    /// ball draws (face 1485) as (x, y). Returns the last frame's pixels too. 6A-L20: record 267's ball beside 266's
    /// (`trace267`); the twin that dropped the ball draws went with the retired picture.
    struct MaceRun {
        var trace: [[Int]] = [], trace267: [[Int]] = [], player: [[Int]] = [], balls: [Int] = []
        var ticks: [UInt32] = [], fnv: [UInt64] = [], draws: [[[Int]]] = []
        var pixels: [UInt8] = []
    }

    static func level20MaceRun(iterations: Int, leaveOut: [LevelFixture.LeaveOut] = level20Maces) throws -> MaceRun {
        let (run, services) = try LevelFixtureServices.open(level: 20, leaveOut: leaveOut, start: maceStart)
        var out = MaceRun(), now: UInt32 = 0
        let session = { try XCTUnwrap(run.session) }
        while out.trace.count < iterations && now < 6000 {
            let before = run.iterations
            let tick = try run.tick(now: now, input: FrontInput())
            now += 1
            var presented = false, draws: [[Int]] = []
            for g in tick.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer, "a level draw before the renderer exists")
                let ops = g.output.draws
                for op in ops {
                    if case .wrapDrawSprites(let list) = op { draws += list.filter { $0.face.pict == 1485 }.map { [$0.x, $0.y] } }
                }
                try r.apply(FrameOps(draws: ops))
                presented = presented || ops.contains { if case .copyToScreen = $0 { true } else { false } }
            }
            if presented, let r = services.renderer {
                out.ticks.append(now)
                out.fnv.append(LevelFixtureServices.fnv1a(r.screen.pixels))
                out.draws.append(draws)
                out.pixels = r.screen.pixels
            }
            guard run.iterations != before else { continue }
            let s = try session()
            let p = try XCTUnwrap(s.world.active.sprite(id: s.playerID))
            out.player.append([p.x, Int(p.hp)])
            out.balls.append(s.world.active.sprites.filter { $0.type == 1485 }.count)
            if let m = s.world.active.sprites.first(where: { $0.recordIndex == 266 && $0.handler == .background }) {
                out.trace.append([m.x, m.y, Int(m.vy), Int(m.pathDirection)])
            } else {
                out.trace.append([])
            }
            if let m = s.world.active.sprites.first(where: { $0.recordIndex == 267 && $0.handler == .background }) {
                out.trace267.append([m.x, m.y, Int(m.vy), Int(m.pathDirection)])
            } else {
                out.trace267.append([])
            }
        }
        XCTAssertEqual(out.trace.count, iterations, "\(iterations) iterations within 6000 ticks")
        return out
    }

    /// 6A-MP: record 266's ball on level 20's fixture (nothing left out) over one full shuttle (ENG §2.10 "First level /
    /// golden"), frame by frame: iterations 1…124 run its Handle 124 times — down from its Setup position (436) at
    /// 2600 / 256 px a frame, the far bound (794) passed and the turn on Handle 37, the slow-down and the climb, the near
    /// bound (517) passed and the turn on Handle 99, and down again: one period. Kept for good: 6A-L20 retired the
    /// picture beside it (`testLevel20MacePathFeatureGolden`; the level's real first frame covers the level) and added
    /// record 267 (the p4 offset) here.
    func testLevel20MacePathTrace() throws {
        // The fixture: nothing left out (a literal empty list); level 20's path balls re-derived from the level file —
        // 16, every one 1485 in mode 1.
        let real = try LevelFile.load(from: try LevelFixture.base.get(), level: 20)
        XCTAssertEqual(try LevelFixture.leftOut(real, Self.level20Maces).count, 0)
        let paths = real.activePlacements.filter { BackgroundSprite.maces.contains($0.type) && (1...2).contains($0.p1) }
        XCTAssertEqual(paths.count, 16)
        XCTAssertEqual(Set(paths.map { [Int($0.type), Int($0.p1)] }), [[1485, 1]])
        let r266 = try XCTUnwrap(paths.first { $0.index == 266 })
        XCTAssertEqual([r266.x, r266.y, r266.p2, r266.p3, r266.p4], [10436, 436, 440, 2600, 0])

        let a = try Self.level20MaceRun(iterations: 124)
        guard a.trace.count == 124 else { return }                     // a failure above, never a crash
        XCTAssertEqual(Set(a.balls), [16], "all 16 balls on the list every frame (never idled)")
        XCTAssertEqual(Set(a.player), [[10700, 560]], "the player neither moved sideways nor was hurt")
        XCTAssertEqual(Set(a.trace.map { $0[0] }), [10436], "mode 1 never moves x")
        let ys = a.trace.map { $0[1] }, vs = a.trace.map { $0[2] }, ds = a.trace.map { $0[3] }
        let turns = ds.indices.dropFirst().filter { ds[$0] != ds[$0 - 1] }.map { $0 + 1 }
        XCTAssertEqual(turns, [37, 99], "the turns on Handles 37 and 99 (`MacePathTests`' record-266 shuttle)")
        XCTAssertEqual([ys.first, ys.min(), ys.max(), ys.last], [446, 421, 888, 449])
        XCTAssertEqual(Array(ys.prefix(36)), (1...36).map { 436 + (2600 * $0) >> 8 }, "down at 2600 / 256 px a frame")
        XCTAssertEqual(Set(vs.map { abs($0) }).max(), 2600)
        // Between the turns vy steps by p3 >> 4 = 162, or by less onto ±2600 (the clamp), or stays.
        for k in 1..<124 where ds[k] == ds[k - 1] {
            let dv = abs(vs[k] - vs[k - 1])
            XCTAssertTrue(dv == 0 || dv == 162 || (dv < 162 && abs(vs[k]) == 2600), "Handle \(k + 1)")
        }
        // The trace (measured at 6A-MP, seed 1): FNV-1a 64 of its fields, big-endian i32s in order — the same value a
        // model written from the dump alone (M l. 62337–62359, 39319–39341, 39419–39446; y += vy) gives.
        var bytes: [UInt8] = []
        for f in a.trace { for v in f { bytes += [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: Int32(v) >> $0) } } }
        XCTAssertEqual(String(LevelFixtureServices.fnv1a(bytes), radix: 16), "76e08997895b6e89", "record 266's trace")
        XCTAssertEqual([a.ticks.first, a.ticks.last], [143, 389])

        // 6A-L20 (run 66's carry, when the mace picture was retired): record 267 beside it — the same path (p2 440, p3
        // 2600) with p4 440, the Setup's offset (M l. 62343–62361): the bounds come from the position before it (y 436:
        // `+0x100` = 436·256 + 8·2600, `+0x104` = 436·256 + 440·256 − 8·2600, as record 266's), then y += p4, so the
        // ball starts 440 px lower, past its far bound (794), and turns on its first Handle (direction −1 after it),
        // runs on down while vy decays, climbs past the near bound (517) and turns down again on Handle 70; x never
        // moves.
        let r267 = try XCTUnwrap(paths.first { $0.index == 267 })
        XCTAssertEqual([r267.x, r267.y, r267.p2, r267.p3, r267.p4], [10527, 436, 440, 2600, 440])
        guard a.trace267.count == 124, a.trace267.allSatisfy({ $0.count == 4 }) else {
            return XCTFail("record 267 on the list every iteration")
        }
        XCTAssertEqual(Set(a.trace267.map { $0[0] }), [10527], "mode 1 never moves x")
        let ys7 = a.trace267.map { $0[1] }, ds7 = a.trace267.map { $0[3] }
        let turns7 = ds7.indices.dropFirst().filter { ds7[$0] != ds7[$0 - 1] }.map { $0 + 1 }
        XCTAssertEqual(ds7.first, -1, "turned on its first Handle")
        XCTAssertEqual(turns7, [70], "measured: record 267's next turn")
        XCTAssertEqual([ys7.first, ys7.min(), ys7.max(), ys7.last], [886, 424, 962, 733], "measured")
        var bytes7: [UInt8] = []
        for f in a.trace267 { for v in f { bytes7 += [24, 16, 8, 0].map { UInt8(truncatingIfNeeded: Int32(v) >> $0) } } }
        XCTAssertEqual(String(LevelFixtureServices.fnv1a(bytes7), radix: 16), "77379b19446b30c6", "record 267's trace (measured)")
    }
}

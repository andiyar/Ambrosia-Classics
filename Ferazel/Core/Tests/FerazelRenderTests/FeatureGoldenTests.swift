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

    /// 6A-WD: the trace's last frame (the 60th iteration's presented screen). Deleted at 6A-L10L11 (the wind draws
    /// nothing of its own; the trace and level 10's first-frame golden cover it).
    func testLevel10WindFeatureGolden() throws {
        let t = try Self.windTrace()
        XCTAssertEqual(String(Self.hash(t.trace), radix: 16), "20b0a649c605b4d0", "the same trace")
        // Measured at the 6A-WD review fix round (FNV-1a 64 of the 640×480 screen indices after the 60th iteration's
        // draws, the test colour model), on the 1,730th tick (now 1729). With the wind branch stubbed the trace and this
        // frame differ (checked once at the fix round, never committed).
        XCTAssertEqual(t.ticks, 1730)
        XCTAssertEqual(String(t.fnv, radix: 16), "c9ad94cdb8b2d287", "the level-10 wind feature golden")
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

    /// 6A-RC: the first presented frame on which a rotating cannon on screen has turned — record 200 from
    /// `cannon200Start`, whole in the view. Deleted at 6A-L10L11 (the trace pins the turning; level 10's first-frame
    /// golden pins the draw).
    func testLevel10RotatingCannonFeatureGolden() throws {
        let t = try Self.cannonTrace(record: 200, start: Self.cannon200Start, frames: 12)
        // The first Handle that turns it: iteration 9's (its pause 8 counted down on iterations 1…8).
        let i = try XCTUnwrap(t.trace.firstIndex { $0.aim != t.trace[0].aim })
        XCTAssertEqual(i + 1, 9)
        let k = t.trace[i]
        XCTAssertEqual([Int(t.trace[i - 1].aim), t.trace[i - 1].face, Int(t.trace[i - 1].rotation)], [0, 0, 0])
        XCTAssertEqual([Int(k.aim), k.face, Int(k.rotation)], [2, 0, 336])   // cell 0 at 2·((30·180 / 16) / 2)
        // An iteration draws (`.PaintFrameWrap`'s `.WrapDrawSprites`) BEFORE its `.HandleSprites`, so iteration 9's frame
        // still shows aim 0: the turned cannon is first drawn by iteration 10 — the golden frame. On screen there: its
        // 150 × 150 cell inside the 640 × 416 view.
        let g = i + 1, view = t.scroll[i]
        XCTAssertTrue(view.x <= k.x && k.x + 0x96 <= view.x + 640 && view.y <= k.y && k.y + 0x96 <= view.y + 416)
        XCTAssertNotEqual(t.fnv[g], t.fnv[i])
        // Measured at 6A-RC (FNV-1a 64 of the 640×480 screen indices after that iteration's draws, the test colour
        // model), on the 1,630th tick (now 1629). With the rotation stubbed (one local patch, never committed) this
        // frame is 5189680b496e8bbd and iteration 9's is unchanged (1fe12083e4c9326e) — the turn first shows here.
        XCTAssertEqual(t.ticks[g], 1630)
        XCTAssertEqual(String(t.fnv[i], radix: 16), "1fe12083e4c9326e", "iteration 9: the cannon still drawn at aim 0")
        XCTAssertEqual(String(t.fnv[g], radix: 16), "1f159e3178d4733", "the level-10 rotating-cannon feature golden")
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
    /// screen (measured, 6A-RP); from here it opens at v 388 — view rows 388…771 — with water cells in view.
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
}

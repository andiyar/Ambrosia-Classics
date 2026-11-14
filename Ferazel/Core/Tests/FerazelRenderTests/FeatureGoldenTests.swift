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
}

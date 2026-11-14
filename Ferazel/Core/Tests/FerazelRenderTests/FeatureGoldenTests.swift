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
    /// (x + 50, y + 59) = (7120, 1072), in tile column 222 — the first column with an o1 = 9 wind cell (the updraft,
    /// o2 20 in this column) — and row 33, the column's top wind cell. The column's wind cells are rows 33, 35, 37, 38,
    /// 40 and 41, so the falling player leaves and re-enters the wind; it lands in the same column (row 49).
    static let windStart = (x: 7070, y: 1013)

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

    /// 6A-WD: 60 frames of the player in the first o1 = 9 column of level 10 (ENG §2.2 "First level / golden"): the
    /// updraft pushes vy (h = 0 on o1 9, so x256 never moves and `+0x98` stays 0), the ramp counts up to 33 in wind and
    /// down out of it, and the flag is re-earned each frame. Kept for good (6A-L10L11 keeps it on the fixture).
    func testLevel10WindTrace() throws {
        let t = try Self.windTrace()
        XCTAssertEqual(t.trace.count, 60)
        // Held in the column: the centre stays in tile column 222 for all 60 frames.
        XCTAssertEqual(Set(t.trace.map(\.col)), [222])
        // o1 9 is mode 27 (h = 0): the push is vertical only, so `+0x98` stays 0 and the leaving arm adds nothing.
        XCTAssertEqual(Set(t.trace.map(\.last)), [0])
        // The ramp `+0x96` (measured): up 1 a frame in wind, down 1 a frame out of it, to 0 after the column. Frame 1
        // is not in wind: before the player's first Handle its centre is (0, 0) (no `.StandardSpriteCleanup` yet).
        XCTAssertEqual(t.trace.map(\.ramp), [0, 1, 2, 3, 4, 5, 4, 3, 2, 1, 2, 3, 2, 1, 2, 3, 4, 5, 4, 3, 4, 5, 4, 3, 2, 1]
                       + [Int16](repeating: 0, count: 34))
        XCTAssertEqual(t.trace.map(\.inWind).enumerated().filter(\.element).map(\.offset),
                       [1, 2, 3, 4, 5, 10, 11, 14, 15, 16, 17, 20, 21])
        // While falling (frames 1–25) vy gains gravity 440 a frame, less the updraft's 14·20 = 280 (scale 0x100, no
        // shift, no ramp on the vertical) in wind.
        for i in 1...25 {
            XCTAssertEqual(t.trace[i].vy - t.trace[i - 1].vy, t.trace[i].inWind ? 160 : 440, "frame \(i + 1)")
        }
        XCTAssertEqual(Array(t.trace.prefix(6).map(\.vy)), [440, 600, 760, 920, 1080, 1240])
        XCTAssertEqual(Array(t.trace.prefix(6).map(\.row)), [33, 33, 33, 33, 33, 34])
        XCTAssertEqual(t.trace[0].x256, 7070 << 8)
        XCTAssertEqual(t.trace[59].x256, 1_807_125)
        XCTAssertEqual(t.trace[59].row, 49)
        // The whole trace (measured at 6A-WD, seed 1): FNV-1a 64 of its fields.
        XCTAssertEqual(String(Self.hash(t.trace), radix: 16), "bd379d4131e9b1fb", "the level-10 wind trace")
        XCTAssertEqual(t.ticks, 1730)
    }

    /// 6A-WD: the trace's last frame (the 60th iteration's presented screen). Deleted at 6A-L10L11 (the wind draws
    /// nothing of its own; the trace and level 10's first-frame golden cover it).
    func testLevel10WindFeatureGolden() throws {
        let t = try Self.windTrace()
        XCTAssertEqual(String(Self.hash(t.trace), radix: 16), "bd379d4131e9b1fb", "the same trace")
        // Measured at 6A-WD (FNV-1a 64 of the 640×480 screen indices after the 60th iteration's draws, the test colour
        // model), on the 1,730th tick (now 1729). With the wind branch stubbed the trace and this frame differ (checked
        // once at 6A-WD, never committed).
        XCTAssertEqual(t.ticks, 1730)
        XCTAssertEqual(String(t.fnv, radix: 16), "89b3fd52662b07dc", "the level-10 wind feature golden")
    }
}

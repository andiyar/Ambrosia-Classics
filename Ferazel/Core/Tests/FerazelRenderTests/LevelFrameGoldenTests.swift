import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// The 6A level first-frame goldens (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, "Verification-model
/// additions for 6A": "New goldens are new values, not moves"): each level task pins its level's first presented frame
/// on the **real** level — the committed data unpatched, opened through the level runner (`LevelFixture.open` on the
/// data set itself, nothing left out) with the fixture's renderer side (`LevelFixtureServices`: the Render tests'
/// colour model, FNV-1a 64 of the 640×480 screen indices). Measured by the build (D46.4), never invented; a later
/// change is a STOP. The Windows references of the same frames are `WinLevelReferenceTests` (presented RGBA through
/// the Windows shell). A missing data file is a FAILURE, never a skip.
final class LevelFrameGoldenTests: XCTestCase {

    /// The real level `level`, seed 1, `FerazelPrefs()`, the header's start: its first presented frame
    /// (`LevelFixtureServices.firstPresentedFrame`), the run, and the camera's scroll after it.
    static func firstFrame(level: Int) throws
        -> (ticks: UInt32, fnv: UInt64, run: LevelRun, renderer: FrameRenderer, scroll: (h: Int, v: Int)) {
        let res = try LevelFixture.base.get()
        let services = LevelFixtureServices(resources: res)
        let run = try LevelFixture.open(resources: res, level: level, services: services)
        let f = try services.firstPresentedFrame(run)
        let s = try XCTUnwrap(run.session)
        return (f.ticks, f.fnv, run, f.renderer, (s.camera.scrollH, s.camera.scrollV))
    }

    /// Checks the frame shows the level: the first `.GameLoop` iteration, the player on screen inside the 640 × 416
    /// view, and the frame not one colour.
    private func checkShowsLevel(_ f: (ticks: UInt32, fnv: UInt64, run: LevelRun, renderer: FrameRenderer,
                                       scroll: (h: Int, v: Int)), _ level: Int) throws {
        XCTAssertEqual(f.run.iterations, 1, "level \(level): the first loop iteration")
        let s = try XCTUnwrap(f.run.session)
        let p = try XCTUnwrap(s.world.playerID.flatMap { s.world.active.record(id: $0) })
        let sx = p.x - f.scroll.h, sy = p.y - f.scroll.v
        XCTAssertTrue((0..<640).contains(sx) && (0..<416).contains(sy), "level \(level): the player in view (\(sx), \(sy))")
        XCTAssertGreaterThan(Set(f.renderer.screen.pixels).count, 16, "level \(level): a level picture, not a card")
    }

    /// 6A-L10L11: level 10 "Unemployed In Greenland" — the first presented frame comes after chapter card 2 (the
    /// card's own golden is `ScreenTests.testChapterCard2FrameGolden`). No horizon strip pixel is in this frame (from
    /// the header's start none appears in 6,000 ticks — 6A-S8); `FeatureGoldenTests.testLevel10StripFeatureGolden`
    /// stays the strip's picture.
    func testLevel10FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 10)
        try checkShowsLevel(f, 10)
        // Measured at 6A-L10L11 (seed 1): the 1,612th tick (now 1611) — ticks 1…1,611 are the chapter card, as on the
        // strip fixture (6A-S8) — with the camera at (0, 634).
        XCTAssertEqual(f.run.levelFile.header.chapter, 2)
        XCTAssertEqual(f.ticks, 1612)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [0, 634])
        XCTAssertEqual(String(f.fnv, radix: 16), "e76116216b6d605", "the level-10 first-frame golden")
    }

    /// 6A-L10L11: level 11 "River of Fears" — no chapter card; the first presented frame. Its view does not reach the
    /// river band (D53.1: from the header's start the camera never shows a backdrop row ≥ 512), so the ripple is not
    /// in it; `FeatureGoldenTests.testLevel11RippleFeatureGolden` stays the ripple's picture.
    func testLevel11FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 11)
        try checkShowsLevel(f, 11)
        // Measured at 6A-L10L11 (seed 1): the 143rd tick (now 142), no card, the camera at (15744, 31) — the view's
        // rows 31…414 stay below the river band's 512 (yb 256: backdrop rows track the view 1:1).
        XCTAssertEqual(f.run.levelFile.header.chapter, 0)
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [15744, 31])
        XCTAssertLessThan(f.scroll.v + 383, 0x200, "no ripple row in view")
        XCTAssertEqual(String(f.fnv, radix: 16), "5d78b001424a6898", "the level-11 first-frame golden")
    }

    /// 6A-L15: level 15 "Storm Valley" — no chapter card; the first presented frame, the backdrop replaced by the two
    /// rain sheets (OmniPx mode 1, 6000 / 6001). It is 6A-RN's frame 1 on the same world (that fixture left nothing out,
    /// and this open is the fixture's: `LevelFixture.open` on the data set itself), and it supersedes 6A-RN's rain
    /// feature golden (ENG §2.7), whose pins it carries with their twins (D54.2): frame 1 shows the sheets — the twin
    /// without the `.UpdateOmniPx` ops differs — and no drop (a drop is made at age 0 and `.DrawParticles` draws only
    /// ages > 0, M l. 29787: the twin without the rain particles is the same picture); frame 2 is the first with drops.
    func testLevel15FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 15)
        try checkShowsLevel(f, 15)
        XCTAssertEqual(f.run.levelFile.header.chapter, 0)
        XCTAssertEqual(f.run.levelFile.header.omniPxMode, 1)
        // Measured at 6A-L15 (seed 1): the 143rd tick (now 142), no card, the camera at (0, 1018) — the same value
        // as 6A-RN's frame 1: the opening paths agree (the level runner, no chapter or stage screen before it).
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [0, 1018])
        XCTAssertEqual(String(f.fnv, radix: 16), "49eddc24d9989d95", "the level-15 first-frame golden (6A-RN's frame 1)")
        let plain = try FeatureGoldenTests.level15Frames(count: 2, dropRain: false)
        let noDrops = try FeatureGoldenTests.level15Frames(count: 2, dropRain: true)
        let noSheets = try FeatureGoldenTests.level15Frames(count: 1, dropRain: false, dropOmniPx: true)
        XCTAssertEqual(plain.map(\.ticks), [143, 145])
        XCTAssertEqual(noDrops.map(\.ticks), [143, 145])
        XCTAssertEqual(plain[0].fnv, f.fnv, "the fixture helper's frame 1 is this frame")
        XCTAssertNotEqual(noSheets[0].fnv, f.fnv, "frame 1 shows the rain sheets")
        XCTAssertEqual(String(noSheets[0].fnv, radix: 16), "75d168572f6f029c", "measured: frame 1 without the sheets")
        XCTAssertEqual([plain[0].rain, plain[1].rain], [0, 15], "frame 1 no drop drawn; frame 2 the first call's five")
        XCTAssertEqual(plain[0].fnv, noDrops[0].fnv, "frame 1 shows no drop")
        XCTAssertNotEqual(plain[1].fnv, noDrops[1].fnv, "frame 2 shows the drops")
        XCTAssertEqual(String(noDrops[1].fnv, radix: 16), "b8b5b520071e980e", "frame 2 with the drops taken out (6A-RN)")
        XCTAssertEqual(String(plain[1].fnv, radix: 16), "343813c4727ef0e0", "the rain picture, frame 2 (6A-RN)")
    }

    /// 6A-L18: level 18 "Goblin Chief" — no chapter card; the first presented frame. Two things are new on this level:
    /// the ripple (hdr 0x26ca 1, 6A-RP) and the level-coloured pictures (the Chief's single 0x776 and sets 0x777…0x77a,
    /// loaded under colour table 224 — D62.1). The first frame shows the ripple and not the Chief (D51.1 / D54.2, the
    /// twins inside the test): the view's backdrop rows reach the ripple band (yb 256: rows track the view 1:1, rows
    /// 338…721 ≥ 0x200), and the twin opened with hdr 0x26ca patched to 0 (no table, no fill) differs; the Chief stands
    /// at x 897, his 256-wide cell left of the view (h 1408), so no level-coloured picture is in this frame — they first
    /// show at his activation (`testLevel18ChiefActivationFrame`), through the fight (`BossKillLevelRunTests`).
    func testLevel18FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 18)
        try checkShowsLevel(f, 18)
        let h = f.run.levelFile.header
        XCTAssertEqual([Int(h.chapter), Int(h.parallaxRipple), Int(h.pxBackYFactor)], [0, 1, 256])
        // Measured at 6A-L18 (seed 1): the 143rd tick (now 142), no card, the camera at (1408, 338) — the player starts
        // at (1996, 605), right of the arena.
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [1408, 338])
        XCTAssertGreaterThanOrEqual(f.scroll.v + 383, 0x200, "ripple rows in view")
        XCTAssertEqual(String(f.fnv, radix: 16), "d3ce9327fd19d8b4", "the level-18 first-frame golden")
        let s = try XCTUnwrap(f.run.session)
        let chief = try XCTUnwrap(s.world.active.sprites.first { $0.handler == .chief })
        XCTAssertEqual([chief.x, chief.y], [897, 412])
        XCTAssertLessThanOrEqual(chief.x + 0x100, f.scroll.h, "the Chief's cell is left of the view")
        // The twin: the same open with hdr 0x26ca patched to 0 (no ripple table, no fill: the backdrop rows unshifted).
        let res = try LevelFixture.resources(level: 18, leaveOut: [], header: [(0x26ca, [0])])
        let services = LevelFixtureServices(resources: res)
        let run = try LevelFixture.open(resources: res, level: 18, services: services)
        let flat = try services.firstPresentedFrame(run)
        XCTAssertEqual(flat.renderer.parallax.rippleTable.count, 0)
        XCTAssertEqual(flat.ticks, f.ticks)
        XCTAssertNotEqual(flat.fnv, f.fnv, "frame 1 shows the ripple")
        // Measured: 23,852 screen bytes the ripple moved; the frame without it.
        XCTAssertEqual(zip(flat.renderer.screen.pixels, f.renderer.screen.pixels).filter { $0 != $1 }.count, 23_852)
        XCTAssertEqual(String(flat.fnv, radix: 16), "3267c6feda5903c7", "measured: frame 1 without the ripple")
    }

    /// 6A-L20: level 20 "Hangnabit" — no chapter card; the first presented frame. Its new features in view from the
    /// start are the 164 clouds (6A-CL; mode 0xb arg 4, in front of everything): the first frame shows them — the twin
    /// with every cloud draw taken out (the same run: Core never sees it) differs (D51.1 / D54.2). The frame is the
    /// cloud fixture's frame 1 (`FeatureGoldenTests.testLevel20CloudFeatureGolden`: that fixture leaves out only the
    /// blades and the path balls, none of which is drawn here), so it carries the ruled first-load difference
    /// (`SetupFaces.swift:21–23`, `FaceSource.setupCached`): the clouds' Setup copies the cache entry's face pointer
    /// before `.LoadCachedSpriteFaces` (M l. 62533–62550, `.SetupLevel` M l. 2526 / 2537), so on the level's first load
    /// the original would draw the placeholder PICT 150 there, the port the loaded cloud faces. Frame 2 — drawn after
    /// the clouds' first Handle re-read their faces (M l. 63308) — matches the original and is pinned beside it, with
    /// its own twin. No blade is drawn: all 28 were idled at the spawn and none is on the list in frames 1 and 2, so
    /// the blade Setup's stand-in face (`SetupFaces`' `.handle` cell 0xbf4, where the original's `+0xc0` stays 0 —
    /// M l. 62571–62583) never reaches a draw before the blade's first Handle faces it (M l. 63511).
    func testLevel20FirstFrameGolden() throws {
        let f = try Self.firstFrame(level: 20)
        try checkShowsLevel(f, 20)
        let h = f.run.levelFile.header
        XCTAssertEqual([Int(h.chapter), Int(h.startX), Int(h.startY)], [0, 86, 886])
        // Measured at 6A-L20 (seed 1): the 143rd tick (now 142), no card, the camera at (0, 640).
        XCTAssertEqual(f.ticks, 143)
        XCTAssertEqual([f.scroll.h, f.scroll.v], [0, 640])
        XCTAssertEqual(String(f.fnv, radix: 16), "9f0b821fbbc60084", "the level-20 first-frame golden")
        let s = try XCTUnwrap(f.run.session)
        XCTAssertEqual(s.world.active.sprites.filter { $0.type == BackgroundSprite.blade }.count, 0, "no blade on the list")
        XCTAssertEqual(s.world.idle.entries.compactMap { $0 }.filter { $0.saved.type == BackgroundSprite.blade }.count, 28)
        // The real level's first two frames, and the twin without the cloud draws.
        let frames = try FeatureGoldenTests.level20CloudFrames(count: 2, dropClouds: false, leaveOut: [])
        let twin = try FeatureGoldenTests.level20CloudFrames(count: 2, dropClouds: true, leaveOut: [])
        guard frames.count == 2, twin.count == 2 else { return }          // a failure above, never a crash
        XCTAssertEqual(frames.map(\.ticks), [143, 145])
        XCTAssertEqual(twin.map(\.ticks), frames.map(\.ticks))
        XCTAssertEqual(frames[0].fnv, f.fnv, "the helper's frame 1 is this frame")
        XCTAssertEqual(frames.map(\.clouds), twin.map(\.clouds), "the twin's run is the same run")
        XCTAssertEqual(frames.map { $0.clouds.count }, [164, 164], "every cloud drawn")
        XCTAssertNotEqual(frames[0].fnv, twin[0].fnv, "frame 1 shows the clouds")
        XCTAssertNotEqual(frames[1].fnv, twin[1].fnv, "and frame 2")
        // Measured: the screen bytes the clouds changed; the frames without them; frame 2. Every value equals the cloud
        // fixture's (6A-CL): the blades and path balls that fixture leaves out draw nothing in these two frames.
        let changed = (0..<2).map { k in zip(frames[k].pixels, twin[k].pixels).filter { $0 != $1 }.count }
        XCTAssertEqual(changed, [25886, 31081])
        XCTAssertEqual(String(twin[0].fnv, radix: 16), "8964bdab39954f49", "measured: frame 1 without the clouds")
        XCTAssertEqual(String(twin[1].fnv, radix: 16), "4679418e47ef711b", "measured: frame 2 without the clouds")
        XCTAssertEqual(String(frames[1].fnv, radix: 16), "37eb1f7eb12e8f76",
                       "frame 2: the clouds' faces re-read, their parallax applied")
    }

    /// 6A-L18: the Chief's activation on the real level with real pictures (BOS §9.3, D61.3) — level 18 through the
    /// level runner with the renderer-backed services (`LevelFixtureServices`: the wake rectangle is his picture's
    /// opaque bounds), seed 1, LEFT held from the level start: he is active on the first frame (the camera's pan), idle
    /// from the second, the arena locks, he wakes for good when the view meets his picture's bounds, jumps on his 56th
    /// locked-and-awake frame and lands 36 frames later. The twin through the headless stub (the whole 256×254 cell
    /// for a wake rectangle, `ChiefTests.testChiefFirstJumpAfterLock`'s run) wakes three frames sooner — the measured
    /// difference the pictures make.
    func testLevel18ChiefActivationFrame() throws {
        func measure(_ services: LevelServices) throws -> [Int?] {
            let run = try LevelFixture.open(resources: try LevelFixture.base.get(), level: 18, services: services)
            let left = Int(FerazelPrefs().keys[0])
            var now: UInt32 = 0
            func tick(_ keys: [Int]) throws {
                if let r = services as? LevelFixtureServices {
                    _ = try r.step(run, now: now, input: FrontInput(keys: KeyState(pressed: keys)))
                } else {
                    _ = try run.tick(now: now, input: FrontInput(keys: KeyState(pressed: keys)))
                }
                now &+= 1
            }
            while run.session == nil && now < 4000 { try tick([]) }
            let w = try XCTUnwrap(run.session).world
            func chief() -> SpriteSlot? { w.active.sprites.first { $0.handler == .chief } }
            var firstActive: Int?, asleep: Int?, lock: Int?, awake: Int?, jump: Int?, land: Int?
            while land == nil && run.iterations < 3000 {
                let was = chief()?.subtype
                let before = run.iterations
                var k = 0
                while run.iterations == before && k < 400 { try tick([left]); k += 1 }
                if lock == nil && w.arena.locked { lock = run.iterations }
                guard let c = chief() else {
                    if firstActive != nil && asleep == nil { asleep = run.iterations }
                    continue
                }
                if firstActive == nil { firstActive = run.iterations }
                if asleep != nil && awake == nil { awake = run.iterations }
                if jump == nil && c.subtype == 1 { jump = run.iterations }
                if jump != nil && was == 3 && c.phase == 1 && c.onSprite != 0 && c.subtype == 3 { land = run.iterations }
            }
            return [firstActive, asleep, lock, awake, jump, land]
        }
        let res = try LevelFixture.base.get()
        let real = try measure(LevelFixtureServices(resources: res))
        // Measured at 6A-L18 (seed 1, game-loop frames): active 1, idle from 2, the arena locked on 111, awake for good
        // on 124 — the activation frame —, the first jump's state 1 on 179 (124 + 55), the first landing on 215.
        XCTAssertEqual(real, [1, 2, 111, 124, 179, 215], "measured with real pictures (seed 1)")
        let headless = try measure(LevelFixture.Headless())
        XCTAssertEqual(headless, [1, 2, 111, 121, 176, 212], "the whole-cell wake rectangle (ChiefTests' frames)")
    }
}

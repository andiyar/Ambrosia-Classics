import XCTest
import FerazelCore
@testable import FerazelRender

/// GD (docs/plans/2026-10-10-ferazel-phase2.md, wave 2.5): the Phase 2 goldens — level 2's first frame, a level-1
/// jump and landing, a level-1 walk into the first water body, and 600 frames of scripted play. Every number is a
/// self-derived first measurement under `FrameGoldenTests`' configuration (`.ruled`, tie-break `.lowest`, error
/// diffusion, the box rasterizer, default prefs) with `FastRand` seed 1. Unlike `FrameGoldenTests`, each session gets
/// the renderer's face pixels for the face emitters (`particleFaces`), as the app does. The key scripts are inline:
/// original keys only (`FerazelPrefs.defaultKeys`). A missing data file is a FAILURE.
final class Phase2GoldenTests: XCTestCase {

    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    // The original default keys (engine §7.1): keypad 4 / 6 / 8 / 5, Shift (run), Option (jump).
    private static let left = Int(FerazelPrefs.defaultKeys[0]), right = Int(FerazelPrefs.defaultKeys[1])
    private static let up = Int(FerazelPrefs.defaultKeys[2]), down = Int(FerazelPrefs.defaultKeys[3])
    private static let run = Int(FerazelPrefs.defaultKeys[4]), jump = Int(FerazelPrefs.defaultKeys[5])

    /// A key script: each step holds `keys` for `frames` iterations.
    private typealias Script = [(keys: [Int], frames: Int)]

    private func renderer(level: Int) throws -> FrameRenderer {
        try FrameRenderer(resources: try Self.resources.get(), level: level,
                          search: ColorSearch(model: .ruled, tieBreak: .lowest),
                          dither: .errorDiffusion, text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
    }

    /// The level's session at seed 1 with the renderer's face bounds and face pixels, its Setup lights and
    /// `.BuildTintTable` draws handed to the renderer (as `FerazelController` builds them).
    private func session(_ r: FrameRenderer, level: Int) throws -> FerazelSession {
        let s = try FerazelSession(resources: try Self.resources.get(), prefs: FerazelPrefs(), level: level, seed: 1,
                                   faceBounds: r.faceBounds, particleFaces: r.particleFaces)
        try r.addLights(s.lights)
        try r.buildTintTable(s.tintTableDraws)
        return s
    }

    private func fnv1a(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes { h = (h ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        return h
    }

    /// Little-endian bytes of each value as 64 bits (the chain encoding of `FrameGoldenTests.testPanFrameGoldens`).
    private func bytes(_ values: [UInt64]) -> [UInt8] { values.flatMap { v in (0..<8).map { UInt8(v >> (8 * $0) & 0xff) } } }
    private func bytes(_ values: [Int]) -> [UInt8] { bytes(values.map { UInt64(bitPattern: Int64($0)) }) }

    private func hex(_ v: UInt64) -> String { String(v, radix: 16) }

    /// One iteration's cues in call order: every `SoundCue` field, then the stops and where each fell (`soundStopAt`).
    private func cueWords(_ ops: FrameOps) -> [Int] {
        var w = [ops.sounds.count]
        for c in ops.sounds {
            w += [Int(c.snd), c.priority, c.left, c.right, Int(c.rate), c.onlyIfIdle ? 1 : 0]
        }
        w.append(ops.soundStops.count)
        for (snd, at) in zip(ops.soundStops, ops.soundStopAt) { w += [Int(snd), at] }
        return w
    }

    private func player(_ s: FerazelSession) throws -> SpriteSlot {
        try XCTUnwrap(s.active.record(id: s.playerID))
    }

    /// The live particles of a liquid kind (200…209, `.Splash`'s kind floor).
    private func liquidParticles(_ s: FerazelSession) -> Int {
        s.world.particles.records.filter { $0.alive && (200..<210).contains($0.kind) }.count
    }

    func testLevel2FirstFrameGolden() throws {
        let r = try renderer(level: 2)
        let s = try session(r, level: 2)
        let ops = s.step(keys: KeyState())
        try r.apply(ops)
        // Measured 2026-10-14 (GD, three runs): level 2's start + iteration 1 — its camera opens at the start scroll
        // (631, 20), not level 1's (0, 0); 91 Setup lights at Effects 1.
        XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [631, 20])
        XCTAssertEqual(r.lights.slots.filter(\.active).count, 91)
        XCTAssertEqual(hex(fnv1a(r.screen.pixels)), "565e867a02736c18")
    }

    func testLevel1JumpAndLandGolden() throws {
        let r = try renderer(level: 1)
        let s = try session(r, level: 1)
        let script: Script = [([], 10), ([Self.jump], 6), ([], 14)]
        var chain: [UInt64] = []
        for (keys, n) in script { for _ in 0..<n {
            try r.apply(s.step(keys: KeyState(pressed: keys)))
            chain.append(fnv1a(r.screen.pixels))
        } }
        // Measured 2026-10-14 (GD, three runs): he stands at (83, 123), the jump takes him to y 22 (iteration 22) and
        // at iteration 30 he is still falling (y 75, vy 3244) — the landing back on y 123 falls after the 30 frames
        // the plan fixes. The FNV-1a of the 30 frame hashes (little-endian bytes).
        let p = try player(s)
        XCTAssertEqual(chain.count, 30)
        XCTAssertEqual([p.x, p.y, Int(p.vy)], [83, 75, 3244])
        XCTAssertEqual(hex(fnv1a(bytes(chain))), "73c35838c0f30060")
    }

    /// The route from the start (centre cell (4, 5)) to the first water body (BG liquid, cols 56…81, row 19): found
    /// by a scratch search over key scripts and minimised; it is a fixed input, not a walkthrough.
    private static let swimRoute: Script = [
        ([right], 14), ([right, jump], 3), ([right], 14), ([right, jump], 6), ([right], 14), ([right, jump], 1),
        ([right, run], 19), ([right, down], 7), ([left, jump], 8), ([down, jump], 24), ([up, right], 13),
        ([right], 22), ([right, jump], 2), ([up], 27), ([right, run], 25), ([left], 20), ([right, run, jump], 4),
        ([right, down], 4), ([right, run, jump], 3), ([up, right], 6), ([down, jump], 21), ([up, right], 11),
        ([right, run], 48), ([right, run, jump], 6), ([right, run], 35),
    ]

    func testLevel1SwimGolden() throws {
        let r = try renderer(level: 1)
        let s = try session(r, level: 1)
        var chain: [UInt64] = []
        var entry: (frame: Int, col: Int, row: Int, before: Int, after: Int, sounds: [Int16])?
        var i = 0
        let wall = s.world.tiles.fgTile(col: 24, row: 13)
        var broken: Int?
        for (keys, n) in Self.swimRoute { for _ in 0..<n {
            let before = liquidParticles(s)
            let wasDry = try player(s).waterRow == 0
            let ops = s.step(keys: KeyState(pressed: keys))
            try r.apply(ops)
            i += 1
            chain.append(fnv1a(r.screen.pixels))
            if broken == nil, s.world.tiles.fgTile(col: 24, row: 13) != wall { broken = i }
            let p = try player(s)
            if wasDry, p.waterRow != 0, entry == nil {
                entry = (i, p.centre.x >> 5, p.centre.y >> 5, before, liquidParticles(s), ops.sounds.map(\.snd))
            }
        } }
        // Measured 2026-10-14 (GD, three runs). The walk right from the start cannot reach any liquid on foot: the
        // start rooms are closed by crunch walls (`.CrunchTile`, direction nibbles at cols 12…20 rows 2…4 and col 24
        // rows 10…15). The route drops into the lower room and breaks the col-24 wall with a spin-jump fall
        // (blocks (24…25, 13…14) gone on iteration 259), then runs right along rows 15…18 and drops into the
        // first water body (BG liquid cols 56…81, row 19) on iteration 357, the last of the script: centre cell
        // (60, 18), the big splash 405 (hot rect 24 wide) and `.Splash(s, 3)`'s (24 + 8) × 3 = 96 liquid particles.
        XCTAssertEqual(broken, 259)
        let e = try XCTUnwrap(entry)
        XCTAssertEqual([e.frame, e.col, e.row, e.before, e.after], [357, 60, 18, 0, 96])
        XCTAssertEqual(e.sounds, [Splash.bigSnd])
        XCTAssertEqual(chain.count, 357)
        XCTAssertEqual(hex(fnv1a(bytes(chain))), "22899ab83d5d14a0")
    }

    /// 600 iterations of a fixed walk / run / jump cycle (60 frames, repeated 10 times).
    private static let playCycle: Script = [
        ([right], 12), ([right, run], 12), ([right, run, jump], 8), ([right], 6), ([], 4), ([left], 6),
        ([left, jump], 6), ([right, jump], 6),
    ]

    func testLevel1ScriptedPlayGolden() throws {
        let r = try renderer(level: 1)
        let s = try session(r, level: 1)
        var chain: [UInt64] = []
        var cues: [Int] = []
        var i = 0
        for _ in 0..<10 { for (keys, n) in Self.playCycle { for _ in 0..<n {
            let ops = s.step(keys: KeyState(pressed: keys))
            try r.apply(ops)
            chain.append(fnv1a(r.screen.pixels))
            cues += [i] + cueWords(ops)
            i += 1
        } } }
        // Measured 2026-10-14 (GD, three runs): the FNV-1a of the 600 frame hashes; of the cue words (per iteration:
        // its index, the `SoundCue`s in order with every field, the stops with their `soundStopAt`); and the final
        // state — the player (x, y, vx, vy), the scroll, the `FastRand` seed, the live particles.
        let p = try player(s)
        XCTAssertEqual(s.iterations, 600)
        XCTAssertEqual(hex(fnv1a(bytes(chain))), "2b06ca5447084169")
        XCTAssertEqual(cues.count, 3244)
        XCTAssertEqual(hex(fnv1a(bytes(cues))), "a332f94ec91c2744")
        XCTAssertEqual([p.x, p.y, Int(p.vx), Int(p.vy)], [182, 75, 230, 3520])
        XCTAssertEqual([s.camera.scrollH, s.camera.scrollV], [0, 0])
        XCTAssertEqual(s.rngSeed, 1348255379)
        XCTAssertEqual(s.world.particles.live, 0)
    }
}

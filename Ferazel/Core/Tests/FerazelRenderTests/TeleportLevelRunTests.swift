import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// SP (docs/plans/2026-10-30-ferazel-phase5.md; Q15 items 1 and 4): level 1's teleporter urn (record 148 → 149) through
/// `LevelRun`, every level op executed in the level's `FrameRenderer` as the shells execute it, with the renderer side
/// built as `FerazelDriver.prepare` builds it. Each mode-5 draw's walk (`DiffuseRandomsAt`) is checked against the
/// renderer that draws it: asked at the scroll point and drawn pair the renderer holds for that `.wrapDrawSprites`, from
/// the draw's seed, ending where the renderer's replay ends. A missing data file is a FAILURE, never a skip.
final class TeleportLevelRunTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// Every `DiffuseRandomsAt` call, in call order: the pair it was asked at and the stream before and after.
    final class WalkLog: @unchecked Sendable {
        struct Call: Equatable { var h: Int, v: Int, drawnH: Int, drawnV: Int, before: Int32, after: Int32 }
        var calls: [Call] = []

        /// `r`'s walk, logged.
        func walk(_ r: FrameRenderer) -> DiffuseRandomsAt {
            let w = r.diffuseRandomsAt
            return { [self] d, h, v, dh, dv, rng in
                let before = rng.seed
                w(d, h, v, dh, dv, &rng)
                calls.append(Call(h: h, v: v, drawnH: dh, drawnV: dv, before: before, after: rng.seed))
            }
        }
    }

    static func renderer(level: Int) throws -> FrameRenderer {
        try FrameRenderer(resources: try resources.get(), level: level,
                          search: ColorSearch(model: .ruled, tieBreak: .lowest), dither: .errorDiffusion,
                          text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
    }

    /// `FerazelDriver.prepare` / `attach` (`Ferazel/Shared/FerazelDriver.swift`), the walk logged.
    final class Services: LevelServices {
        let log = WalkLog()
        private(set) var renderer: FrameRenderer?
        func prepare(level: Int) throws -> LevelFaces {
            let r = try TeleportLevelRunTests.renderer(level: level)
            renderer = r
            return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces, diffuseRandoms: r.diffuseRandoms,
                              diffuseRandomsAt: log.walk(r))
        }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
            guard let r = renderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
            try r.addLights(lights)
            try r.buildTintTable(tintTableDraws)
        }
        func deathEffectStep(_ k: Int) throws {}
    }

    /// Executes `ops` on `r` in order; before each `.wrapDrawSprites` checks its mode-5 draws against `log` from call
    /// `next` on (asked at `r.scroll` and the grid's drawn pair as `r` holds them for that op, from the draw's seed, and
    /// `r`'s replay there ends at the walk's end). Returns the number of mode-5 draws.
    @discardableResult
    static func apply(_ ops: [DrawOp], to r: FrameRenderer, log: WalkLog, next: inout Int, _ label: String,
                      file: StaticString = #filePath, line: UInt = #line) throws -> Int {
        var pending: [DrawOp] = [], diffuse = 0
        for op in ops {
            if case .wrapDrawSprites(let draws) = op {
                try r.apply(FrameOps(draws: pending))
                pending = []
                let at = [r.scroll.h, r.scroll.v, r.grid.drawnH, r.grid.drawnV]
                for d in draws where d.mode >> 16 == 5 {
                    diffuse += 1
                    guard next < log.calls.count, let seed = d.randomSeed else {
                        XCTFail("\(label): a mode-5 draw with no walk", file: file, line: line)
                        continue
                    }
                    let c = log.calls[next]
                    next += 1
                    XCTAssertEqual([c.h, c.v, c.drawnH, c.drawnV], at, "\(label): the walk's pair", file: file, line: line)
                    XCTAssertEqual(c.before, seed, "\(label): the draw's seed", file: file, line: line)
                    var replay = FastRand(seed: seed)
                    r.sprites.diffuseRandoms(d, h: at[0], v: at[1], drawn: (at[2], at[3]), rng: &replay)
                    XCTAssertEqual(replay.seed, c.after, "\(label): the replay's end", file: file, line: line)
                }
            }
            pending.append(op)
        }
        try r.apply(FrameOps(draws: pending))
        return diffuse
    }

    /// Level 1, Ferazel standing on the urn record 148: the charge climbs to 80, the stage-1 out-mosaic, the move to
    /// record 149's idle entry, stage 2, the in-mosaic, then the frames after arrival with the charge at −59 climbing
    /// back through the sparkle (`PlayerStates.tint`, M l. 46242–46346; `HitPlayerSprite.teleportDone`). Every level op
    /// executes with no refusal and every mode-5 walk matches the renderer's draw — so `LevelRun` handed the session
    /// the renderer's `DiffuseRandomsAt`.
    func testTeleportThroughLevelRun() throws {
        let res = try Self.resources.get()
        let L = try LevelFile.load(from: res, level: 1)
        let p = L.placements[148]
        let prefs = FerazelPrefs()
        let services = Services()
        let run = try LevelRun(resources: res, prefs: prefs, level: 1, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: services,
                               sounds: StageSounds(prefs: prefs, lengths: [:]),
                               start: (Int(p.x) + 0x10 - 50, Int(p.y) - 4 - 85 + 1))
        var next = 0, t: UInt32 = 0
        var stage1 = false, stage2 = false, mosaicSeen = false, arrived = false
        var d: (x: Int, y: Int)?, moved: (x: Int, y: Int)?
        var before = 0, during = 0, after = 0, framesAfter = 0
        while t < 9000 && framesAfter < 60 {
            let out = try run.tick(now: t, input: FrontInput())
            t &+= 1
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer)
                let n: Int
                do { n = try Self.apply(g.output.draws, to: r, log: services.log, next: &next, "tick \(t)") } catch {
                    return XCTFail("tick \(t): \(error)")
                }
                if arrived { after += n } else if mosaicSeen { during += n } else { before += n }
            }
            guard let s = run.session else { continue }
            let player = s.world.playerID.flatMap { s.world.active.record(id: $0) }
            switch s.suspension {
            case .teleport(record: 148, stage: 1)?:
                if !stage1, let q = player, let tp = s.world.active.sprites.first(where: {
                    $0.recordIndex == 148 && (0x424...0x426).contains($0.type) }) {
                    d = (q.x - tp.x, q.y - tp.y)
                }
                stage1 = true
            case .teleport(record: 148, stage: 2)?:
                if !stage2, let q = player { moved = (q.x, q.y) }
                stage2 = true
            default: break
            }
            if run.mosaic != nil { mosaicSeen = true }
            if mosaicSeen && run.mosaic == nil && s.suspension == nil {
                arrived = true
            }
            if arrived && out.merged.draws.contains(where: { if case .wrapEraseSprites = $0 { true } else { false } }) {
                framesAfter += 1
            }
        }
        XCTAssertTrue(stage1, "the charge reached 80 and the out-mosaic began")
        XCTAssertTrue(stage2, "the move and the in-mosaic")
        // The move: record 149's idle entry (2493, 1523) + the player's offset on 148 (TeleporterTests).
        let dd = try XCTUnwrap(d), m = try XCTUnwrap(moved)
        XCTAssertEqual([m.x, m.y], [2493 + dd.x, 1523 + dd.y])
        XCTAssertEqual(framesAfter, 60)
        XCTAssertEqual(try XCTUnwrap(run.session).player.teleporterCharge, 0, "the charge back at 0 after arrival")
        // The sparkle while charging, inside the mosaics' own `.WrapDrawSprites`, and after arrival.
        XCTAssertGreaterThan(before, 0)
        XCTAssertGreaterThan(during, 0)
        XCTAssertGreaterThan(after, 0)
        XCTAssertEqual(next, services.log.calls.count, "every walk was drawn")
    }
}

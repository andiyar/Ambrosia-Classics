import XCTest
@testable import FerazelCore
@testable import FerazelRender

/// Phase 5 cross-check (2026-11-10): an enemy's burn-away death completes through the REAL renderer's face store.
/// `Burn.handle` returns silently when the face lookup gives nothing (a headless session), and the Core tests feed it
/// made-up faces. Here level 1 runs through `LevelRun` with the renderer side built as `FerazelDriver.prepare` builds it
/// (`FrameRenderer.particleFaces`; every level op executed in the level's renderer); the axe thrower of record 17 takes
/// a lethal hit and its death plays out. A missing data file is a FAILURE, never a skip.
final class GoblinBurnLevelRunTests: XCTestCase {
    nonisolated(unsafe) private static let resources = Result { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// The lookups into the renderer's face store for the Walker death set 0x6a8 that found a face.
    final class FaceLog: @unchecked Sendable {
        var found = 0
    }

    /// `FerazelDriver.prepare` / `attach` (`Ferazel/Shared/FerazelDriver.swift`), the death-set lookups counted.
    final class Services: LevelServices {
        let log = FaceLog()
        private(set) var renderer: FrameRenderer?
        func prepare(level: Int) throws -> LevelFaces {
            let r = try FrameRenderer(resources: try GoblinBurnLevelRunTests.resources.get(), level: level,
                                      search: ColorSearch(model: .ruled, tieBreak: .lowest), dither: .errorDiffusion,
                                      text: StatusBarTests.BoxRasterizer(), prefs: FerazelPrefs())
            renderer = r
            let faces = r.particleFaces, log = log
            let counted = ParticleFaces(sprite: { ref in
                let f = faces.sprite(ref)
                if f != nil && ref.pict == Walker.deathSet { log.found += 1 }
                return f
            }, fgTile: faces.fgTile)
            return LevelFaces(faceBounds: r.faceBounds, particleFaces: counted, diffuseRandoms: r.diffuseRandoms,
                              diffuseRandomsAt: r.diffuseRandomsAt)
        }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
            guard let r = renderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
            try r.addLights(lights)
            try r.buildTintTable(tintTableDraws)
        }
        func deathEffectStep(_ k: Int) throws {}
    }

    /// Ferazel starts 200 px left of the 1700 (record 17, p3 1) and stands still. Once its first Handle has run, the hit
    /// that a player shot makes (`Walker.hit`'s shot arm: `.HurtSprite(s, dmg = the shot's HP, 0, −1000, 4, 8)`, M l.
    /// 58506–58611) takes its HP to 0. Then, as the dump has it:
    /// - the death entry (`LAB_10069a8c`, M l. 58307–58328): state 4, face 0x6a8[0], score + 500 (M l. 58328) — in the
    ///   frame that makes it;
    /// - the dying frames (M l. 57740–57790): past 50, dry, `+0x15c` past 2 → the burn (`+0x1a2 = 1`); the player
    ///   within 451 × 351 px keeps the corpse for the burn (the far arm's direct `.KillWalker` is not taken);
    /// - `.HandleBurn` (M l. 38765–38840) through the renderer's store: the row jumps to the real face's opaque top
    ///   (face `+8`) and steps one row before each row is burnt, so the rows are the top + 1 … the bottom (face `+0xc`)
    ///   with the clip `+0x1bc` on the row, one a frame; past the opaque bottom (M l. 38825) the Kill proc `+0x50`;
    /// - `.KillWalker` (M l. 58612–58633): `+0xe9 == 0 && +0x1b5` → live − 1 and `G+0x306 + 2·L` + 1, `+0xe9 = 1`;
    /// - `.UpdateSprites` counts `+0xe9` up and unlinks the sprite at 4 (M l. 4983).
    func testGoblinBurnsAwayThroughRenderer() throws {
        let res = try Self.resources.get()
        let record = 17
        let L = try LevelFile.load(from: res, level: 1)
        let p = L.placements[record]
        XCTAssertEqual([Int(p.type), Int(p.x), Int(p.y), Int(p.p3)], [Int(Walker.thrower), 3649, 429, 1],
                       "level 1's record 17: the axe thrower")
        let prefs = FerazelPrefs()
        let services = Services()
        let run = try LevelRun(resources: res, prefs: prefs, level: 1, seed: 1, carry: LevelCarry(), save: SaveBlock(),
                               fade: ScreenFade(), music: MusicFade(), services: services,
                               sounds: StageSounds(prefs: prefs, lengths: [:]),
                               start: (Int(p.x) - 200, Int(p.y)))
        var t: UInt32 = 0
        var goblin: Int?
        var live0: Int32 = 0, defeated0: Int16 = 0, level = 0
        var deathScore: Int32?
        var opaque: (top: Int16, bottom: Int16)?
        var rows: [Int16] = [], clips: [Int] = []
        var killedAt: Int16?, gone = false
        while t < 4000 && !gone {
            let before = run.session.map { (score: $0.world.globals.score,
                                            sub: goblin.flatMap($0.world.active.sprite(id:))?.subtype) }
            let out = try run.tick(now: t, input: FrontInput())
            t &+= 1
            for g in out.segments where g.target == .level {
                let r = try XCTUnwrap(services.renderer)
                do { try r.apply(FrameOps(draws: g.output.draws)) } catch { return XCTFail("tick \(t): \(error)") }
            }
            guard let s = run.session else { continue }
            let w = s.world
            guard let id = goblin else {
                guard let g = w.active.sprites.first(where: { $0.recordIndex == record && $0.handler == .walker }),
                      g.setupDone else { continue }
                XCTAssertTrue(g.countedInTotals, "set up inside the counting window")
                goblin = g.id
                level = w.levelIndex
                live0 = w.enemies.live
                defeated0 = w.globals.achieved[0][level]
                XCTAssertTrue(HurtSprite.apply(w, id: g.id, damage: g.hp, dvx: 0, dvy: -1000, invulnerable: 4, flash: 8))
                XCTAssertEqual(w.active.sprite(id: g.id)?.hp, 0)
                continue
            }
            guard let g = w.active.sprite(id: id) else {
                gone = true
                break
            }
            if g.subtype == 4, let b = before, b.sub != 4 {
                deathScore = w.globals.score - b.score
            }
            if killedAt == nil && g.killCount == 0 && 0 < g.burnRow, rows.last != g.burnRow {
                XCTAssertTrue(g.burning)
                let face = try XCTUnwrap(g.face)
                XCTAssertEqual(face.pict, Walker.deathSet)
                let real = try XCTUnwrap(services.renderer?.particleFaces.sprite(face), "the store has the dying face")
                if opaque == nil { opaque = (real.bounds[0], real.bounds[2]) }
                rows.append(g.burnRow)
                clips.append(g.clip.top)
            }
            if killedAt == nil && g.killCount != 0 {
                killedAt = g.burnRow
                XCTAssertEqual(w.enemies.live, live0 - 1, "counted once")
                XCTAssertEqual(w.globals.achieved[0][level], defeated0 + 1, "the level's defeated enemies + 1")
            }
        }
        XCTAssertNotNil(goblin, "the 1700 became active and took the hit")
        XCTAssertEqual(deathScore, 500, "the death entry's score (M l. 58328)")
        let o = try XCTUnwrap(opaque, "the burn ran on a face from the renderer's store")
        XCTAssertGreaterThan(o.bottom, o.top)
        // The burn from below the opaque top to past the opaque bottom, one row and one clip a frame, each burn frame (the
        // Kill's included) a face found in the store — the silent no-op finds none and never moves the row.
        XCTAssertEqual(rows, Array((o.top + 1)...o.bottom), "the burn rows")
        XCTAssertEqual(clips, rows.map(Int.init), "the clip follows the row")
        XCTAssertEqual(services.log.found, rows.count + 1, "one store lookup a burn frame")
        XCTAssertEqual(killedAt, o.bottom + 1, "the Kill past the opaque bottom (M l. 38825)")
        XCTAssertTrue(gone, "the sprite unlinked")
        let w = try XCTUnwrap(run.session?.world)
        XCTAssertEqual(w.enemies.live, live0 - 1)
        XCTAssertEqual(w.globals.achieved[0][level], defeated0 + 1)
        XCTAssertFalse(w.active.sprites.contains { $0.recordIndex == record && $0.handler == .walker })
    }
}

import XCTest
import HectorResources
@testable import DeimosCore

/// The level transition (plan LT; appendix A §1, §6): on the pass where the tallies finish, a non-film session with a
/// player in game runs `FUN_10007170`'s tail (`10007200..1000725c`: music stop, `tran`, the fade to black, the flags,
/// `FUN_100302e0`) and the level start `FUN_100064d0` for sector + 1 (`10006594..100066c8`) inside the same game;
/// after sector 12 the level is `none` and the session ends. An input-less pilot dies long before a level ends on its
/// own, so each test pokes the scroll one row from the map's end (`progress = 3599`); the level end then makes the
/// in-game players invulnerable and the tallies finish a few hundred passes later.
final class LevelTransitionTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private func session(sector: Int, players: Int = 1) throws -> DeimosSession {
        try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: sector, players: players, film: nil),
                          seed: 0x469c2)
    }

    /// An op no rule emits, put into `tickOps` before each pass so it stands where that pass's terrain stamps stand.
    private static let stampMarker = RenderOp.copy(from: .scoreSave, to: .scoreSave,
                                                   src: MacRect(top: 1, left: 2, bottom: 3, right: 4), dst: nil,
                                                   interlaced: true)

    private static func isPresent(_ op: RenderOp) -> Bool {
        if case .present = op { return true }
        return false
    }

    private static func isTerrainBlit(_ op: RenderOp) -> Bool {
        if case .copy(from: .terrain, to: .back, _, _, _) = op { return true }
        return false
    }

    /// `tran` as `FUN_10007170` plays it (`1000720c..10007224`: PermSoundID 3, priority 0x4b, volume 0x64, multiple 1).
    private func tran() throws -> SoundCue {
        SoundPlay.perm(try assets().sounds[3], priority: 75, volume: 100, allowMultiple: true)
    }

    /// Pokes progress 3599 and runs passes until levels started changes: returns that pass's output (the transition
    /// pass). With `marker`, `stampMarker` goes into `tickOps` before every pass. Bound: 3,000 passes.
    private func runToTransition(_ s: inout DeimosSession, marker: Bool = false) -> PassOutput? {
        s.game.scroll.progress = 3599
        let started = s.game.flags.levelsStarted
        for _ in 0..<3000 {
            if marker { s.game.tickOps.append(Self.stampMarker) }
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            if s.game.flags.levelsStarted != started { return out }
            if out.sessionEnded { XCTFail("the session ended before a transition"); return nil }
        }
        XCTFail("bound: no transition within 3,000 passes")
        return nil
    }

    /// A bare `GameState` as `FUN_100051a0` + `FUN_100064d0` leave sector 1 (`le07`, one level started), both players
    /// set up and level-started at game time 0 — no session around it.
    private func bareWorld(players n: UInt8) throws -> GameState {
        var s = GameState(assets: try assets(), prefs: .fresh, seed: 0x469c2)
        s.flags.numPlayers = n
        s.flags.sector = 1
        s.flags.level = FourCC("le07")!
        s.flags.levelsStarted = 1
        s.flags.running = true
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        s.tally.reset()
        return s
    }

    func testTransitionPassStartsNextSector() throws {
        var s = try session(sector: 1)
        XCTAssertEqual(s.game.flags.levelsStarted, 1)
        XCTAssertEqual(s.players[0].handler.air.id, FourCC("aiic"), "the sector-1 start weapon")
        // The last level was perfect (G+0x0b, as FUN_100072c0 sets it at 100% ground accuracy, 10007384); the
        // accuracy tier at this level's end only ever sets it.
        s.game.flags.perfectThisLevel = true
        XCTAssertFalse(s.game.flags.rewardArmed)
        let out = try XCTUnwrap(runToTransition(&s))
        XCTAssertFalse(out.sessionEnded, "a mid-game transition does not end the session")
        XCTAssertTrue(s.running)
        XCTAssertEqual(s.game.flags.levelsStarted, 2)                       // 1000667c..10006684
        XCTAssertEqual(s.sector, 2)                                         // 100066e8
        XCTAssertEqual(s.level, FourCC("le06"))                             // 100065c4..100065cc FUN_10011f00(2)
        XCTAssertEqual(s.levelInfo.id, FourCC("le06"))                      // 100065dc FUN_10011fd0 reloads the info
        XCTAssertEqual(s.gameTime, 1, "10006500 sets 0, the loop's 100059e0 adds 1")
        XCTAssertFalse(s.appeared)                                          // 10006510
        XCTAssertFalse(s.game.flags.levelComplete)                          // 1000723c..10007240
        XCTAssertFalse(s.game.flags.levelEnding)                            // 10007248
        XCTAssertFalse(s.game.flags.levelEndHandled)                        // 10006504
        XCTAssertTrue(s.game.flags.rewardArmed, "G+0x0c takes the perfect flag (10006524..10006544)")
        XCTAssertFalse(s.game.flags.perfectThisLevel, "… and G+0x0b is cleared (1000653c)")
        // The weapon handler's level start reads G+0x14 (1003b0dc), set at 100066e8 before the players' level start
        // (10006798): entering sector 2 equips the PEAA whose minimum level is 2 — the Bacta Gun (appendix A §4).
        XCTAssertEqual(s.players[0].handler.air.id, FourCC("aibg"), "sector 2's forced air weapon")
        let fade = try XCTUnwrap(out.ops.firstIndex(of: .fade(.toBlack, .gameLayout)))
        XCTAssertFalse(out.ops[fade...].contains(where: Self.isPresent), "no present: appeared is 0 (10030d90)")
        // The new level's state: the scroll at its start (FUN_1000fa90), the le06 mask (FUN_1000fbc0), P1 waiting to
        // appear (state 2 at game time 0, 10026a20).
        XCTAssertEqual(s.scroll.window.top, 3120)
        XCTAssertEqual(s.scroll.progress, 481)
        XCTAssertFalse(s.scroll.levelEnded)
        XCTAssertEqual(s.game.mask, try LevelSet.loadMask(s.levelInfo, assets: assets()))
        XCTAssertEqual(s.players[0].lifeState, 2)
        XCTAssertEqual(s.players[0].stateEntered, 0)
    }

    func testTransitionOpOrder() throws {
        var s = try session(sector: 1)
        let out = try XCTUnwrap(runToTransition(&s, marker: true))
        let ops = out.ops
        XCTAssertEqual(s.levelInfo.backgroundImage, FourCC("inm3"))
        let fade = try XCTUnwrap(ops.firstIndex(of: .fade(.toBlack, .gameLayout)))        // 1000722c..10007234
        let stamps = try XCTUnwrap(ops.lastIndex(of: Self.stampMarker))
        let load = try XCTUnwrap(ops.firstIndex(of: .loadTerrain(image: FourCC("inm3")!)))  // 100067ec
        let fill = try XCTUnwrap(ops[load...].firstIndex(of: .fill(.back, colour: 0)))     // 1000690c
        let blit = try XCTUnwrap(ops[fill...].firstIndex(where: Self.isTerrainBlit))       // 10006974
        XCTAssertLessThan(stamps, fade, "the tick's terrain stamps land on the old map, before the fade")
        XCTAssertLessThan(fade, load, "the new map loads after the fade")
        XCTAssertLessThan(load, fill)
        XCTAssertLessThan(fill, blit)
        XCTAssertEqual(ops[fade + 1], .clearLayers, "FUN_100302e0's layer clear (100302f4)")
        XCTAssertEqual(ops.filter { $0 == .fade(.toBlack, .gameLayout) }.count, 1)
        XCTAssertEqual(ops.filter { if case .loadTerrain = $0 { return true } else { return false } }.count, 1)
        // The score bar's level start (two `scor` loads) between the fill and the first terrain blit (10006914..10006934).
        XCTAssertEqual(ops[fill..<blit].filter { if case .loadImage = $0 { return true } else { return false } }.count, 2)
        XCTAssertEqual(ops[blit], s.scroll.terrainBlit(interlaced: false))
        // Then the draw world (the new level's notice no02 among it) and the end frame: no present.
        XCTAssertFalse(ops[blit...].contains(where: Self.isPresent))
    }

    func testTransitionCues() throws {
        var s = try session(sector: 1)
        let out = try XCTUnwrap(runToTransition(&s))
        // 10007204 stop; [1000676c..10006788 ◇ ammu]; 100067c8 stop; the engine's level seam.
        XCTAssertEqual(out.music, [.stop, .play(FourCC("ammu")!, loop: true), .stop, .level(s.prefs.intPrefs[1])])
        XCTAssertEqual(out.sounds.last, try tran())
        XCTAssertNil(out.haltEffectsAt)
        XCTAssertEqual(out.fadeToBlackAt, CueMark(sounds: out.sounds.count, music: 1),
                       "the fade falls after the stop and tran, before the new level's cues")
        // The next pass carries no mark.
        let next = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertNil(next.fadeToBlackAt)
    }

    func testNextLevelAppearsOnItsSecondTick() throws {
        var s = try session(sector: 1)
        _ = try XCTUnwrap(runToTransition(&s))
        XCTAssertEqual(s.gameTime, 1)
        XCTAssertEqual(s.scroll.window.top, 3120)
        // T+1: the appear test (game time 1 ≠ fctiwz(flli 18) = 2) fails; the new level's first tick runs at game time 1.
        let t1 = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertTrue(t1.ticked)
        XCTAssertEqual(s.gameTime, 2)
        XCTAssertEqual(s.scroll.window.top, 3119, "the first scroll step of the new level")
        XCTAssertFalse(t1.music.contains { if case .play = $0 { return true } else { return false } })
        XCTAssertFalse(t1.ops.contains(.fade(.fromBlack, .gameLayout)))
        XCTAssertFalse(t1.ops.contains(where: Self.isPresent))
        XCTAssertFalse(s.appeared)
        // T+2: the appear at game time 2 (10005930..100059b8): the new level's music, the fade from black, a present.
        let t2 = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(s.levelInfo.music, FourCC("mu03"))
        XCTAssertEqual(t2.music.first, .play(FourCC("mu03")!, loop: true))
        XCTAssertTrue(t2.ops.contains(.fade(.fromBlack, .gameLayout)))
        XCTAssertTrue(t2.ops.contains(where: Self.isPresent))
        XCTAssertTrue(s.appeared)
        XCTAssertEqual(s.gameTime, 3)
    }

    func testNoReseedBetweenLevels() throws {
        let a = try assets()
        for n in [1, 2] {
            // A bare game state crosses the transition: no session around it.
            var s = try bareWorld(players: UInt8(n))
            s.flags.gameTime = 900
            s.flags.levelComplete = true
            s.flags.levelEnding = true
            var c = FrameController(fpsMaxRate: 30)
            var console = try Console(assets: a)
            let before = s.rng
            s.levelCompleteStep(controller: &c, console: &console, ticks: 0)
            XCTAssertEqual(s.flags.sector, 2, "\(n) players")
            XCTAssertEqual(s.flags.levelsStarted, 2)
            XCTAssertTrue(s.flags.running)
            // The first draw is P1's R(400, 2000) at game time 0 (10026a9c), from the state the level ended with.
            var r = before
            XCTAssertEqual(s.players[0].integrityCheckTick, 0 &+ r.range(Int32(400), Int32(2000)), "\(n) players")
            // Exactly the draws a fresh sector-2 start makes after its seed (the players' level starts, the load
            // pass, the notice), continuing the same generator — no srand (FUN_10055400 only at 100057d4 / 10006b28).
            let fresh = try session(sector: 2, players: n)
            XCTAssertEqual(s.rng.draws, before.draws + fresh.rng.draws, "\(n) players")
            for _ in 1..<fresh.rng.draws { _ = r.rand() }
            XCTAssertEqual(s.rng, r, "\(n) players")
        }
    }

    func testSectorTwelveCompleteEndsSession() throws {
        var s = try session(sector: 12)
        let tran = try tran()
        XCTAssertEqual(s.level, FourCC("le09"))
        s.game.scroll.progress = 3599
        var last = PassOutput()
        var passes = 0
        while s.running {
            let first = s.game.world.nextSerial
            last = s.pass(keys: HeldKeys(), ticks: 0)
            if passes == 0 {
                // The level end's first tick: `nole`, not `noal` (sector 12 but only one level started, 10006de8..10006dfc).
                let units = s.game.assets.definitions.units
                let made = s.game.world.entities.indices
                    .filter { s.game.world.inUse[$0] && s.game.world.entities[$0].serial >= first }
                    .map { units[s.game.world.entities[$0].unit].id }
                XCTAssertTrue(made.contains(FourCC("nole")!))
                XCTAssertFalse(made.contains(FourCC("noal")!))
            }
            passes += 1
            if passes > 3000 { return XCTFail("bound: the session still runs after 3,000 passes") }
        }
        XCTAssertTrue(last.sessionEnded)
        XCTAssertFalse(s.game.flags.allLevels)
        XCTAssertEqual(s.game.flags.levelsStarted, 2, "+= 1 before the none test (1000667c)")
        XCTAssertEqual(s.level, .none)                                      // 10006620..10006628
        XCTAssertEqual(s.sector, 12, "G+0x14 is set only after the none exit (100066e8)")
        XCTAssertEqual(s.gameTime, 1, "10006500 runs before the branch; the loop adds 1")
        XCTAssertFalse(s.appeared)
        // 10007204 stop, 1000669c resume (FUN_10048220(0)), 10005ae4 the session end's stop.
        XCTAssertEqual(last.music, [.stop, .resume, .stop])
        XCTAssertEqual(last.sounds.last, tran)
        XCTAssertEqual(last.fadeToBlackAt, CueMark(sounds: last.sounds.count, music: 1))
        XCTAssertEqual(last.haltEffectsAt, last.sounds.count, "the session end's halt (10005ad8) falls after the fade")
        XCTAssertTrue(last.ops.contains(.fade(.toBlack, .gameLayout)))
        XCTAssertFalse(last.ops.contains { if case .loadTerrain = $0 { return true } else { return false } })
        // Nothing after the none exit ran: no player level start, no level info reload, no scroll reset.
        XCTAssertEqual(s.players[0].levelRef, FourCC("le09"))
        XCTAssertEqual(s.players[0].lifeState, 4)
        XCTAssertEqual(s.levelInfo.id, FourCC("le09"))
        XCTAssertTrue(s.scroll.levelEnded)
        XCTAssertEqual(s.scroll.progress, 3600)
        // A pass after the end: an empty output.
        XCTAssertEqual(s.pass(keys: HeldKeys(), ticks: 0), PassOutput(sessionEnded: true))
    }
}

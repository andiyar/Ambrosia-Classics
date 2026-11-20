import XCTest
import HectorResources
@testable import DeimosCore

/// The Last Film recorder (Phase 4 S5 FR; grounding B §4a–§4c): every non-film session records both players' input,
/// score and current level each life-state-4 tick into the 0x9d68-byte film image — the constructor `FUN_10009390`
/// (`100093b0..100093e0`), the set-up `FUN_10009710` (`100057ec`), the write `FUN_10009830` from the player update's
/// live input branch (`1002a40c..1002a42c`).
final class FilmRecorderTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static func film(_ id: String) throws -> (bytes: [UInt8], film: Film) {
        let index = try RealData.index()
        let record = try XCTUnwrap(index.record(type: FourCC("film")!, id: FourCC(id)!), "film \(id)")
        let data = try index.data(for: record)
        return ([UInt8](data), try Film(data: data))
    }

    /// The held keys that make the fresh key table read `input` for player `player` (`KeyTable.slotBits` order).
    private static func held(_ input: PlayerInput, player: Int, prefs: DeimosPrefs = .fresh) -> Set<UInt16> {
        var keys = Set<UInt16>()
        for (slot, bit) in KeyTable.slotBits.enumerated() where input.contains(bit) {
            keys.insert(prefs.keyTable[KeyTable.slotBits.count * player + slot])
        }
        return keys
    }

    /// One trace row per ticked pass: the session's public state (`TickTrace.Row`, cursor −1 for both sides) plus
    /// player 2's life state, score and lives.
    private struct Row: Equatable {
        var p1: TickTrace.Row
        var p2State: UInt8
        var p2Score: Int32
        var p2Lives: Int32
    }

    private static func row(_ s: DeimosSession) -> Row {
        let p = s.players[0], q = s.players[1]
        let g = s.game
        return Row(p1: TickTrace.Row(gameTime: s.gameTime, cursor: -1, p1State: p.lifeState, p1Score: p.score,
                                     p1Lives: p.lives, p1Shield: p.shield, p1Money: p.money,
                                     p1Multiplier: p.multiplier, draws: s.rng.draws, entities: g.world.liveCount,
                                     groups: g.world.groups.count, scrollTop: s.scroll.window.top,
                                     paused: s.scroll.speed == 0, levelEnding: g.flags.levelEnding,
                                     sector: g.flags.sector),
                   p2State: q.lifeState, p2Score: q.score, p2Lives: q.lives)
    }

    /// The strongest pin: a non-film session (seed 0x469c2, sector 1, one player) fed de01's 4,809 input bytes as
    /// player 1's keys — byte n held while the recorder's P1 cursor is n, so each recorded read takes the next byte —
    /// and Esc, records de01's 40,296 bytes exactly. Esc is held with the LAST byte (4,808, no player key): the quit
    /// pass still ticks (`1000591c` falls through to the tick test `10005920`) and, the speed divider being 0, every
    /// pass ticks, so the original's Esc pass recorded de01's last byte itself; an Esc one pass later would record a
    /// 4,810th byte.
    func testRecordReproducesDemo01() throws {
        let (de01, film) = try Self.film("de01")
        XCTAssertEqual(de01.count, 40_296)
        let inputs = film.players[0].inputs
        XCTAssertEqual(inputs.count, 4_809)
        var s = try DeimosSession(assets: assets(), prefs: .fresh,
                                  start: SessionStart(sector: 1, players: 1, film: nil), seed: 0x469c2)
        XCTAssertNotNil(s.game.recorder)
        let bound = 20_000
        var passes = 0
        while s.running {
            if passes >= bound { XCTFail("bound \(bound) passes reached at game time \(s.gameTime)"); break }
            let n = try XCTUnwrap(s.game.recorder).cursors[0]
            XCTAssertLessThan(n, inputs.count, "a read past de01's last byte")
            var held = n < inputs.count ? Self.held(PlayerInput(rawValue: inputs[n]), player: 0) : []
            if n >= inputs.count - 1 { held.insert(FrameKeys.escKey) }
            let keys = HeldKeys(held: held)
            _ = s.pass(keys: keys, ticks: 0)
            passes += 1
        }
        let result = try XCTUnwrap(s.result)
        XCTAssertEqual(result.end, .escape)
        let recorded = result.recordedFilm
        XCTAssertEqual(recorded.count, de01.count)
        let differing = zip(recorded, de01).enumerated().filter { $0.element.0 != $0.element.1 }.map(\.offset)
        XCTAssertEqual(differing.count, 0, "first differing offsets: \(differing.prefix(16).map { String($0, radix: 16) })")
        XCTAssertTrue(recorded == de01)
    }

    /// A scripted two-player run (3,000 passes, or fewer if both pilots are lost first — the game over is then part of
    /// the recording), recorded, then replayed as a film: the replay's per-tick trace matches the recorded run's for
    /// the start level, tick for tick, over every tick both have.
    func testRecordRoundTrip() throws {
        let a = try assets()
        var s = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 2, film: nil),
                                  seed: 0x1234567)
        let p1Script: [PlayerInput] = [[.fireAir, .fireGround], [.left, .fireAir, .fireGround], [.fireAir],
                                       [.right, .fireAir, .fireGround], [.fireGround], [.up, .right, .select]]
        let p2Script: [PlayerInput] = [[.right, .fireGround, .fireAir], [.fireAir], [.left, .down, .fireGround],
                                       [.fireGround], [.left, .fireAir]]
        var recordedRows: [Row] = []
        let passesToRun = 3_000
        var passes = 0
        while s.running && passes < passesToRun {
            let k1 = p1Script[(passes / 37) % p1Script.count], k2 = p2Script[(passes / 23) % p2Script.count]
            let out = s.pass(keys: HeldKeys(held: Self.held(k1, player: 0).union(Self.held(k2, player: 1))), ticks: 0)
            passes += 1
            if out.ticked && s.sector == 1 { recordedRows.append(Self.row(s)) }
        }
        XCTAssertGreaterThan(passes, 1_500, "the scripted run is long enough")
        let image = try XCTUnwrap(s.game.recorder).image
        let film = try Film(data: Data(image))
        XCTAssertEqual(film.playerCount, 2)
        XCTAssertEqual(film.seed, 0x1234567)
        XCTAssertEqual(film.level, FourCC("le07"))
        XCTAssertGreaterThan(film.players[0].frames, 1_000)
        XCTAssertGreaterThan(film.players[1].frames, 1_000)
        XCTAssertNotEqual(film.players[0].score, 0, "the script scores")

        var r = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: film),
                                  seed: 0)
        var replayRows: [Row] = []
        let bound = 10_000
        var replayPasses = 0
        while r.running {
            if replayPasses >= bound { XCTFail("bound \(bound) replay passes reached"); break }
            let out = r.pass(keys: HeldKeys(), ticks: 0)
            replayPasses += 1
            if out.ticked && r.sector == 1 { replayRows.append(Self.row(r)) }
        }
        XCTAssertEqual(r.result?.end, .filmEnded)
        // The replay runs one tick past the recording (the read at cursor == frames), so it may be one row longer
        // than the recorded run's rows up to P1's last recorded read; compare every row both have.
        XCTAssertGreaterThan(replayRows.count, 1_000)
        XCTAssertLessThanOrEqual(abs(replayRows.count - recordedRows.count), 1)
        let common = min(recordedRows.count, replayRows.count)
        for i in 0..<common where recordedRows[i] != replayRows[i] {
            XCTFail("first divergent tick row \(i): recorded \(recordedRows[i]) vs replayed \(replayRows[i])")
            break
        }
    }

    /// The cap (`10009854..1000985c`, `cmplwi r7,0x4e20; bge`): a write happens only while the cursor is below
    /// 20,000 (unsigned); after that the block is frozen — frames, score and level as the 20,000th write left them.
    func testFramesCapTwentyThousand() throws {
        var rec = FilmRecorder(seed: 7, level: FourCC("le07")!, players: 1)
        let bound = 20_010
        for n in 0..<bound {
            rec.record(player: 0, input: n.isMultiple(of: 2) ? [.left] : [.fireAir], score: Int32(n),
                       level: n < Film.maxFrames ? FourCC("le07")! : FourCC("le06")!)
        }
        XCTAssertEqual(rec.cursors, [Film.maxFrames, 0])
        let film = try Film(data: Data(rec.image))
        XCTAssertEqual(film.players[0].frames, 20_000)
        XCTAssertEqual(film.players[0].score, 19_999)
        XCTAssertEqual(film.players[0].level, FourCC("le07"))
        XCTAssertEqual(film.players[0].inputs.first, PlayerInput.left.rawValue)
        XCTAssertEqual(film.players[0].inputs.last, PlayerInput.fireAir.rawValue)
        // Player 2's block is untouched: frames 0, score raw 0 (not biased), level `none`.
        XCTAssertEqual(film.players[1].frames, 0)
        XCTAssertEqual(Array(rec.image[0x4ebc..<0x4ec8]), [0, 0, 0, 0, 0, 0, 0, 0, 0x6e, 0x6f, 0x6e, 0x65])
        XCTAssertEqual(Array(rec.image[0..<0x10]),
                       [0, 0, 0x27, 0x15, 0, 0, 0, 7, 0x6c, 0x65, 0x30, 0x37, 1, 0, 0, 0])
    }

    /// A film session makes no recorder (`FUN_10009710` is on the not-a-film branch, `100057ec`; the film branch's
    /// input step reads, `1002a3f8`), and its result carries no film.
    func testNoRecordInFilm() throws {
        let (_, film) = try Self.film("de01")
        var s = try DeimosSession(assets: assets(), prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: film),
                                  seed: 0)
        XCTAssertNil(s.game.recorder)
        let bound = 400
        for _ in 0..<bound { _ = s.pass(keys: HeldKeys(), ticks: 0) }
        XCTAssertNil(s.game.recorder)
        XCTAssertGreaterThan(s.game.film?.cursors[0] ?? 0, 0, "the film was read")
        let escBound = 10
        var passes = 0
        while s.running {
            if passes >= escBound { XCTFail("Esc did not end the film within \(escBound) passes"); break }
            _ = s.pass(keys: HeldKeys(held: [FrameKeys.escKey]), ticks: 0)
            passes += 1
        }
        XCTAssertEqual(s.result?.isFilm, true)
        XCTAssertEqual(s.result?.recordedFilm, [])
    }

    /// A game Esc'd before player 1 first reaches life state 4 records frames 0 (B §4b); replayed, it ends on player
    /// 1's first state-4 tick (≈ 56 ticks): the read at cursor 0 = frames takes the zero byte past the recording and
    /// leaves the cursor at 1 > 0 (`FUN_10009750`).
    func testEmptyFilmEndsAtFirstAppear() throws {
        let a = try assets()
        var s = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                  seed: 0x469c2)
        let escBound = 10
        var passes = 0
        while s.running {
            if passes >= escBound { XCTFail("Esc did not end the game within \(escBound) passes"); break }
            _ = s.pass(keys: HeldKeys(held: [FrameKeys.escKey]), ticks: 0)
            passes += 1
        }
        let bytes = try XCTUnwrap(s.result).recordedFilm
        XCTAssertEqual(bytes.count, Film.size)
        let film = try Film(data: Data(bytes))
        XCTAssertEqual(film.players[0].frames, 0)
        XCTAssertEqual(film.seed, 0x469c2)

        // Player 1's first state-4 tick, from a keyless game on the same seed: the game time after that tick.
        var ref = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: nil),
                                    seed: 0x469c2)
        let bound = 1_000
        var firstAppear: Int32?
        for _ in 0..<bound where firstAppear == nil {
            _ = ref.pass(keys: HeldKeys(), ticks: 0)
            if ref.players[0].lifeState == 4 { firstAppear = ref.gameTime }
        }
        let appear = try XCTUnwrap(firstAppear, "player 1 never reached state 4 within \(bound) passes")

        var r = try DeimosSession(assets: a, prefs: .fresh, start: SessionStart(sector: 1, players: 1, film: film),
                                  seed: 0)
        passes = 0
        while r.running {
            if passes >= bound { XCTFail("bound \(bound) replay passes reached"); break }
            _ = r.pass(keys: HeldKeys(), ticks: 0)
            passes += 1
        }
        XCTAssertEqual(r.result?.end, .filmEnded)
        XCTAssertEqual(r.game.film?.cursors[0], 1)
        XCTAssertEqual(r.gameTime, appear)
        XCTAssertTrue((50...60).contains(appear), "first state-4 tick at game time \(appear)")
    }
}

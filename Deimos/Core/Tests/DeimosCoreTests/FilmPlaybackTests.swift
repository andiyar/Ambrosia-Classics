import XCTest
import HectorResources
@testable import DeimosCore

/// `DeimosSession` Phase 2 (plan C18a): the full level start `FUN_100064d0`, the pass of `FUN_100051a0`
/// (`100058b0..10005ab8`) with the end frame `FUN_10030bc0`, film playback (`FUN_100069b0`, the overlay
/// `10005a1c..10005aa0`, `FUN_10009750`) and the Caps Lock pause (`FUN_10030870` → `FUN_10022ef0`).
final class FilmPlaybackTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private func session(seed: UInt32 = 0x469c2, film: Film? = nil, prefs: DeimosPrefs = .fresh) throws -> DeimosSession {
        try DeimosSession(assets: assets(), prefs: prefs, start: SessionStart(sector: 1, players: 1, film: film),
                          seed: seed)
    }

    /// A one-player film of `frames` zero input bytes on `le07` (sector 1), seed 0x469c2.
    private static func film(frames: Int) throws -> Film {
        var b = [UInt8](repeating: 0, count: Film.size)
        func put(_ v: UInt32, _ at: Int) {
            b[at] = UInt8(v >> 24); b[at + 1] = UInt8(v >> 16 & 0xff); b[at + 2] = UInt8(v >> 8 & 0xff)
            b[at + 3] = UInt8(v & 0xff)
        }
        put(Film.version, 0)
        put(0x469c2, 4)
        put(FourCC("le07")!.rawValue, 8)
        b[0x0c] = 1
        put(UInt32(frames), 0x10)
        put(Film.scoreBias, 0x14)
        put(FourCC("le07")!.rawValue, 0x18)
        return try Film(data: Data(b))
    }

    private static func draws(_ ops: [RenderOp]) -> [DrawCommand] {
        ops.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
    }

    /// The index of the first op of `sub` as a contiguous run in `ops`, nil when absent.
    private static func run(_ sub: [RenderOp], in ops: [RenderOp]) -> Int? {
        guard !sub.isEmpty, sub.count <= ops.count else { return nil }
        for i in 0...(ops.count - sub.count) where Array(ops[i..<(i + sub.count)]) == sub { return i }
        return nil
    }

    /// Non-film start seeded 0x469c2 (`FUN_100064d0`, order recorded in `DeimosSession`'s comment): the only RNG
    /// draw of the whole start is P1's `R(400, 2000)` = 1446 (`10026a9c`) — the load pass and `no01` make none;
    /// `no01` (PermObjectID sector + 9) stands at (208, 240); the music is `[play(ammu), stop]` (stand-in 4) then
    /// `.level(int pref 1)`; the accuracy tally is clean (`FUN_10007280`) and the ground counts 0 (`FUN_10007150`);
    /// the media mask is loaded as a tight row-major grid (`FUN_1000fbc0`).
    func testLevelStartDrawsAndOrder() throws {
        let a = try assets()
        let s = try session()
        var check = MSLRandom(seed: 0x469c2)
        XCTAssertEqual(check.range(Int32(400), Int32(2000)), 1446)
        XCTAssertEqual(s.rng.draws, 1)
        XCTAssertEqual(s.rng, check)
        XCTAssertEqual(s.players[0].integrityCheckTick, 1446)

        let no01 = a.objects[s.sector + 9]
        XCTAssertEqual(no01, FourCC("no01"))
        let made = s.game.world.entities.indices.filter { s.game.world.inUse[$0] }
        let notices = made.filter { a.definitions.units[s.game.world.entities[$0].unit].id == no01 }
        XCTAssertEqual(notices.count, 1)
        if let n = notices.first {
            XCTAssertEqual(s.game.world.entities[n].object.x, 208)
            XCTAssertEqual(s.game.world.entities[n].object.y, 240)
        }

        XCTAssertEqual(s.game.cues.music, [.play(FourCC("ammu")!, loop: true), .stop, .level(DeimosPrefs.fresh.intPrefs[1])])
        XCTAssertEqual(s.game.cues.music.last, .level(100))
        var clean = TallyState()
        clean.reset()
        XCTAssertEqual(s.game.tally.state, clean.state)
        XCTAssertEqual(s.game.tally.alpha, 32)
        XCTAssertEqual(s.game.tally.text, [])
        XCTAssertEqual(s.game.tally.percent, 0)
        XCTAssertEqual(s.game.flags.groundCreated, 0)
        XCTAssertEqual(s.game.flags.groundDestroyed, 0)
        XCTAssertEqual(s.game.flags.levelsStarted, 1)
        XCTAssertTrue(s.running)

        // The mask: `jum2`'s media mask, 96 × 720, scale 480 / 96 = 5, cells == width × height.
        let m = s.game.mask
        XCTAssertEqual([m.width, m.height, m.scale], [96, 720, 5])
        XCTAssertEqual(m.cells.count, Int(m.width) * Int(m.height))
        let index = a.index
        let maskID = try XCTUnwrap(a.definitions.levels.first { $0.id == s.level }).mediaMask
        let tga = try TGAImage(data: index.data(for: XCTUnwrap(index.record(type: FourCC("im16")!, id: maskID))))
        XCTAssertEqual(m.cells, tga.pixels)

        // The first pass hands the start's music out, first in its list.
        var t = s
        let out = t.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(Array(out.music.prefix(3)), [.play(FourCC("ammu")!, loop: true), .stop, .level(100)])
        XCTAssertEqual(t.game.cues, CueBuffer(), "the pass moves the cues out")
    }

    /// The appear (`10005930..100059b8`, game time fctiwz(flli 18) = 2): not a film → the level's music
    /// `FUN_10047f90(+0x27c, 1, 0)` = `.play(mu03, loop: true)` (`10005968..10005974`) before the fade
    /// (`10005984`); a film plays no music at all.
    func testAppearStartsLevelMusic() throws {
        let a = try assets()
        XCTAssertEqual(a.floats[18], 2)
        var s = try session()
        let music = try XCTUnwrap(a.definitions.levels.first { $0.id == s.level }).music
        XCTAssertEqual(music, FourCC("mu03"))
        _ = s.pass(keys: HeldKeys(), ticks: 0)
        let p1 = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertFalse(p1.music.contains(.play(music, loop: true)))
        let p2 = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(p2.music, [.play(music, loop: true)])
        XCTAssertTrue(p2.ops.contains(.fade(.fromBlack, .gameLayout)))
        XCTAssertTrue(s.appeared)

        var f = try session(film: Self.film(frames: 60))
        let first = f.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(first.music, [.level(100)], "a film: no ammu, only the engine level")
        for k in 1..<10 {
            let out = f.pass(keys: HeldKeys(), ticks: 0)
            XCTAssertEqual(out.music, [], "film pass \(k)")
            if k == 2 { XCTAssertTrue(out.ops.contains(.fade(.fromBlack, .gameLayout))) }
        }
    }

    /// Film playback: seed, level and players from the film (`FUN_100069b0`, `FUN_10009680`); P1 reads one byte per
    /// tick in life state 4 only (`FUN_1002a3a0`); after frames + 1 reads `FUN_10009750` (cursor > frames) is true
    /// and the session ends on that pass (`10005a38..10005a48`), with no effects halt and no music stop
    /// (`10005ad0..10005ad4`). Bound: frames + 200 passes.
    func testFilmInputsAndEnd() throws {
        let frames = 60
        let film = try Self.film(frames: frames)
        var s = try DeimosSession(assets: assets(), prefs: .fresh,
                                  start: SessionStart(sector: 5, players: 2, film: film), seed: 1)
        XCTAssertEqual(s.sector, 1, "the film's level le07 is sector 1")
        XCTAssertEqual(s.game.flags.numPlayers, 1)
        XCTAssertTrue(s.game.flags.filmPlaying)
        XCTAssertEqual(s.rng, MSLRandom(seed: 0x469c2).advanced(by: 1))
        var reads = 0, passes = 0
        var ended: PassOutput?
        while passes < frames + 200 {
            let before = s.players[0].lifeState
            let cursor = s.game.film!.cursors[0]
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            passes += 1
            let after = s.players[0].lifeState
            let advanced = s.game.film!.cursors[0] != cursor
            XCTAssertEqual(advanced, after == 4 || (before == 4 && after == 3), "pass \(passes): read only in state 4")
            if advanced { reads += 1 }
            if out.sessionEnded { ended = out; break }
        }
        guard let end = ended else { return XCTFail("bound frames + 200 reached") }
        XCTAssertEqual(reads, frames + 1)
        XCTAssertEqual(s.game.film!.cursors[0], Int32(frames + 1))
        XCTAssertTrue(s.game.film!.finished)
        XCTAssertNil(end.haltEffectsAt)
        XCTAssertFalse(end.music.contains(.stop))
        XCTAssertEqual(s.pass(keys: HeldKeys(), ticks: 0), PassOutput(sessionEnded: true))

        // Held keys other than Esc neither end a film nor reach it: `FUN_10048e60` is the mouse button only
        // (`10048e6c`); the film ends on film finished (`10005a38`), the mouse button (not modelled), Esc through the
        // begin frame (`10005904` → `FUN_100307c0` key 0x35), level complete or game over. The same film with P1's
        // keys, P2's and plain letters held in turn runs pass for pass as the key-less film above, ending on the same
        // pass. Bound: frames + 200 passes.
        let keySets: [Set<UInt16>] = [[0x7E], [0x7B, 0x37], [0x7C, 0x3A, 0x31], [0x7D], [0x00, 0x0C, 0x5B, 0x77]]
        var keyed = try DeimosSession(assets: assets(), prefs: .fresh,
                                      start: SessionStart(sector: 5, players: 2, film: film), seed: 1)
        var plain = try DeimosSession(assets: assets(), prefs: .fresh,
                                      start: SessionStart(sector: 5, players: 2, film: film), seed: 1)
        var keyedPasses = 0
        while keyedPasses < frames + 200 {
            let held = HeldKeys(held: keySets[keyedPasses % keySets.count])
            let out = keyed.pass(keys: held, ticks: 0)
            let ref = plain.pass(keys: HeldKeys(), ticks: 0)
            keyedPasses += 1
            guard out == ref else { return XCTFail("keyed film pass \(keyedPasses) differs from the key-less film") }
            XCTAssertEqual(keyed.game.film!.cursors[0], plain.game.film!.cursors[0], "pass \(keyedPasses): film input")
            if out.sessionEnded { break }
            XCTAssertTrue(keyed.running, "pass \(keyedPasses): held keys do not end the film")
        }
        XCTAssertEqual(keyedPasses, passes, "the keyed film ends on the key-less film's pass")
        XCTAssertTrue(keyed.game.film!.finished)
        XCTAssertEqual(keyed.game.film!.cursors[0], Int32(frames + 1))
    }

    /// The film overlay (`10005a50..10005a9c`): format 0x26 = 38, GameString 9 ("REPLAY"), +0x10c = 15, +0x10d = 1,
    /// +0x110 = 0, drawn after the draw world and before the end frame — on every film pass except the one that ends
    /// the film (`10005a48 → 10005aa4`); never in a non-film session.
    func testReplayBanner() throws {
        let a = try assets()
        let layout = try TextLayout(assets: a)
        var req = TextRequest(format: a.formats[0x26], text: a.gameStrings[9])
        req.layer = 15
        req.keepTemplateClip = true
        req.drawNow = false
        let banner = layout.draw(req).map { RenderOp.draw($0) }
        XCTAssertFalse(banner.isEmpty)

        var s = try session(film: Self.film(frames: 30))
        var n = 0
        while n < 300 {
            let out = s.pass(keys: HeldKeys(), ticks: 0)
            n += 1
            let at = Self.run(banner, in: out.ops)
            if out.sessionEnded {
                XCTAssertNil(at, "no banner on the ending pass")
                break
            }
            guard let i = at else { return XCTFail("pass \(n): no banner") }
            let flush = try XCTUnwrap(out.ops.firstIndex(of: .flushLayers(0...1)))
            XCTAssertLessThan(i, flush, "the banner precedes the end frame")
        }
        XCTAssertLessThan(n, 300, "bound 300 passes reached")

        var plain = try session()
        for _ in 0..<5 { XCTAssertNil(Self.run(banner, in: plain.pass(keys: HeldKeys(), ticks: 0).ops)) }
    }

    /// A tick pass in order: begin (`clearLayers`) → the tick → its `tickOps` drained → draw world `FUN_10007070`
    /// (groups, blurs, players, the accuracy tally text `FUN_10007d60`, the notice `FUN_100184b0`, the score bar)
    /// → end frame `FUN_10030bc0` (messages, flush 0–1, terrain, flush 2–5, `.particles`, flush 6–15, limit,
    /// present).
    func testDrawAndEndFrameOrder() throws {
        let a = try assets()
        let layout = try TextLayout(assets: a)
        var s = try session()
        for _ in 0..<120 { _ = s.pass(keys: HeldKeys(), ticks: 0) }
        let marker = RenderOp.fill(.terrain, colour: 0x1234)
        s.game.tickOps = [marker]
        s.game.tally.state = 1
        s.game.tally.alpha = 0
        s.game.tally.text = Array("TALLY".utf8)
        s.game.notice.post(NoticeSlot.Post(text: Array("NOTICE".utf8), hold: true, fadeIn: false, delay: 0,
                                           sound: SoundRecord(), alignment: .centerInGameArea), now: s.gameTime)
        let out = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertTrue(out.ticked)
        let ops = out.ops
        let tally = s.game.tallyTextCommands(text: layout).map { RenderOp.draw($0) }
        let notice = s.game.notice.drawCommands(text: layout, formats: a.formats).map { RenderOp.draw($0) }
        XCTAssertFalse(tally.isEmpty); XCTAssertFalse(notice.isEmpty)
        let m = try XCTUnwrap(ops.firstIndex(of: marker))
        let ship = try XCTUnwrap(ops.firstIndex { if case let .draw(c) = $0 { return c.face == FourCC("pl1o") } else { return false } })
        let t = try XCTUnwrap(Self.run(tally, in: ops))
        let n = try XCTUnwrap(Self.run(notice, in: ops))
        let bar = try XCTUnwrap(ops.firstIndex { if case .copy(from: .scoreSave, _, _, _, _) = $0 { return true } else { return false } })
        XCTAssertEqual(ops.first, .clearLayers)
        XCTAssertLessThan(m, ship, "tickOps before the draw world")
        XCTAssertLessThan(ship, t, "the tally text after the players")
        XCTAssertLessThan(t, n, "the tally text before the notice")
        XCTAssertLessThan(n, bar, "the notice before the score bar")
        let f01 = try XCTUnwrap(ops.firstIndex(of: .flushLayers(0...1)))
        let f25 = try XCTUnwrap(ops.firstIndex(of: .flushLayers(2...5)))
        let f615 = try XCTUnwrap(ops.firstIndex(of: .flushLayers(6...15)))
        let particles = try XCTUnwrap(ops.firstIndex { if case .particles = $0 { return true } else { return false } })
        XCTAssertLessThan(bar, f01)
        XCTAssertTrue(f01 < f25 && f25 < particles && particles < f615, "particles between flush 2–5 and 6–15")
        XCTAssertEqual(Array(ops.suffix(2)), [.limit, .present(.gameScreen)])
    }

    /// Caps Lock (`10030420..100304dc` then `FUN_10030870` → `FUN_10022ef0`): the pause pass draws the posted
    /// notice, presents, then the pause wait is its last op; its cues hold the halt (`FUN_100476a0`) just before
    /// `gaso 8`, and its music ends with `.pause`. The resume (`10022fb4`) is the first music of the next pass; the
    /// halt does not carry over.
    func testCapsLockPassSequence() throws {
        let a = try assets()
        let layout = try TextLayout(assets: a)
        var s = try session()
        for _ in 0..<100 { _ = s.pass(keys: HeldKeys(), ticks: 0) }
        XCTAssertTrue(s.appeared)
        var g = s.game
        g.notice.post(.pressCapsLock(text: a.gameStrings[0], controllerMode: 1), now: g.flags.gameTime)
        g.notice.tick(gameTime: g.flags.gameTime, rng: &g.rng, cues: &g.cues)
        let notice = g.notice.drawCommands(text: layout, formats: a.formats).map { RenderOp.draw($0) }
        XCTAssertFalse(notice.isEmpty)

        let out = s.pass(keys: HeldKeys(capsLock: true), ticks: 0)
        XCTAssertNotNil(Self.run(notice, in: out.ops), "the pause notice is drawn on the pause pass")
        XCTAssertEqual(Array(out.ops.suffix(2)), [.present(.gameScreen), .pauseWait(.gameScreen)])
        let halt = try XCTUnwrap(out.haltEffectsAt)
        XCTAssertLessThan(halt, out.sounds.count)
        XCTAssertEqual(out.sounds[halt].id, a.sounds[8])
        XCTAssertEqual(out.sounds[halt], SoundPlay.perm(a.sounds[8], priority: 0x32, volume: 100, allowMultiple: true))
        XCTAssertEqual(out.music.last, .pause)
        XCTAssertFalse(out.sessionEnded)

        XCTAssertEqual(s.game.cues, CueBuffer(music: [.resume]), "only the resume waits for the next pass")
        let next = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertEqual(next.music.first, .resume)
        XCTAssertNil(next.haltEffectsAt)
        XCTAssertFalse(next.ops.contains { if case .pauseWait = $0 { return true } else { return false } })
        XCTAssertEqual(s.game.cues, CueBuffer())
    }

    /// Level complete in a film (`FUN_10007170` `100071e8..100071f4`): the session ends on the tick the flag is
    /// seen, after the world update, with no music stop or halt (film).
    func testLevelCompleteEndsFilmSession() throws {
        var s = try session(film: Self.film(frames: 500))
        for _ in 0..<80 { XCTAssertFalse(s.pass(keys: HeldKeys(), ticks: 0).sessionEnded) }
        s.game.flags.levelComplete = true
        let out = s.pass(keys: HeldKeys(), ticks: 0)
        XCTAssertTrue(out.sessionEnded)
        XCTAssertTrue(out.ticked)
        XCTAssertEqual(s.gameTime, 81, "the tick ran to its end (game time + 1)")
        XCTAssertNil(out.haltEffectsAt)
        XCTAssertEqual(out.music, [])
        XCTAssertFalse(s.game.film!.finished)
    }

    /// Esc ends a non-film session (`10005ad8..10005ae4`): the halt at the end of the pass's sounds and a music
    /// stop last. In a film the same Esc ends the session without either.
    func testSessionEndHaltsAudio() throws {
        var s = try session()
        for _ in 0..<30 { _ = s.pass(keys: HeldKeys(), ticks: 0) }
        let out = s.pass(keys: HeldKeys(held: [FrameKeys.escKey]), ticks: 0)
        XCTAssertTrue(out.sessionEnded)
        XCTAssertEqual(out.haltEffectsAt, out.sounds.count)
        XCTAssertEqual(out.music.last, .stop)
        XCTAssertEqual(s.game.cues, CueBuffer())

        var f = try session(film: Self.film(frames: 500))
        for _ in 0..<30 { _ = f.pass(keys: HeldKeys(), ticks: 0) }
        let fo = f.pass(keys: HeldKeys(held: [FrameKeys.escKey]), ticks: 0)
        XCTAssertTrue(fo.sessionEnded)
        XCTAssertNil(fo.haltEffectsAt)
        XCTAssertFalse(fo.music.contains(.stop))
    }
}

private extension MSLRandom {
    func advanced(by n: Int) -> MSLRandom {
        var r = self
        for _ in 0..<n { _ = r.rand() }
        return r
    }
}

import XCTest
import HectorResources
@testable import DeimosCore

/// G_Console.cc and the cheats (messages-notices-console §5; listing `disasm-review3-all.txt`: `FUN_1002d040`,
/// `FUN_1002d080`, `FUN_1002d1a0`, `FUN_1002d230`, `FUN_1002d410`, `FUN_1002d770`, the registration block
/// `1000527c..100054f4`, handlers `10007eb0`, `10008660`, `10008990`, `100089f0..10009228`) — plan C19.
final class ConsoleTests: XCTestCase {
    /// A level-1 game, one player set up and level-started, P1 forced to life state 4 (active).
    private func game(active: Bool = true) throws -> GameState {
        let a = try TestAssets.loaded.get()
        var s = GameState(assets: a, prefs: DeimosPrefs.fresh, seed: 0x469c2)
        s.flags.numPlayers = 1
        s.flags.sector = 1
        s.flags.level = FourCC("le07")!
        s.scroll.levelStart(rect: MacRect(top: 0, left: 0, bottom: 3600, right: 480))
        try s.setupPlayer(0)
        try s.setupPlayer(1)
        s.playerLevelStart(0)
        s.playerLevelStart(1)
        if active { s.players[0].lifeState = 4 }
        return s
    }

    private func bytes(_ s: String) -> [UInt8] { MacRoman.encode(s, lossy: true) ?? [] }
    private func texts(_ g: GameState) -> [String] { g.messages.messages.map { MacRoman.decode($0.text) } }
    private func perm(_ g: GameState, _ n: Int) -> SoundCue {
        SoundPlay.perm(g.assets.sounds[n], priority: 0x32, volume: 100, allowMultiple: true)
    }
    private func run(_ c: inout Console, _ g: inout GameState, _ line: String) {
        g.messages.reset(); g.cues = CueBuffer()
        c.execute(bytes(line), game: &g)
    }

    /// §5.1: open on key 0x32 (FlushEvents — the tilde is discarded; gaso 1 (0x32, 100, 1)), one keyDown event
    /// per frame, Backspace, `~`/`` ` `` set the redraw flag only, the up-arrow recall, the 30-char cap and the
    /// 120-frame expiry (both turn the key into Return), input withheld while open, the 8-frame fade-out.
    func testConsoleTyping() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        var c = FrameController(fpsMaxRate: 30)
        FrameKeys.startSession(controller: &c, console: &con, game: &g, filmPlayback: false, gameScreenLayout: true,
                               autoInterlaceAllowed: true, ticks: 0)
        XCTAssertEqual(g.assets.sounds[1], FourCC("clic"))
        func frame(_ held: Set<UInt16> = [], _ typed: [UInt8] = []) -> FrameKeysResult {
            let r = FrameKeys.beginFrame(controller: &c, console: &con, game: &g,
                                         keys: HeldKeys(held: held, typed: typed))
            _ = FrameKeys.endFrameWrapper(controller: &c, console: &con, game: &g, keys: HeldKeys(held: held),
                                          ticks: 0)
            return r
        }
        XCTAssertFalse(frame().inputWithheld)
        let o = frame([0x32], [0x60])
        XCTAssertTrue(con.isOpen)
        XCTAssertTrue(o.inputWithheld, "the ship gets no input while the console is open")
        XCTAssertTrue(o.tick, "the game does not pause")
        XCTAssertEqual(con.text, [], "the tilde keystroke is flushed")
        XCTAssertEqual(g.cues.sounds, [perm(g, 1)])
        XCTAssertEqual(con.lastKey, 1, "last key = the frame passed (fc+8 before this end frame)")

        _ = frame([], bytes("abc"))
        XCTAssertEqual(con.text, bytes("a"), "one event per frame")
        _ = frame(); _ = frame()
        XCTAssertEqual(con.text, bytes("abc"))
        _ = frame([], [0x08])
        XCTAssertEqual(con.text, bytes("ab"))
        _ = frame([], [0x7E]); _ = frame([], [0x60])
        XCTAssertEqual(con.text, bytes("ab"), "~ and ` are not appended and do not close")
        XCTAssertTrue(con.isOpen && con.visible)
        _ = frame([], [0x1E])
        XCTAssertEqual(con.text, bytes("ab"), "no last line yet → up-arrow does nothing")

        // 30-char cap: the 29th..30th appends land, the next key becomes Return → executes the 30-char line.
        _ = frame([], [0x08]); _ = frame([], [0x08])
        for _ in 0..<30 { _ = frame([], bytes("x")) }
        XCTAssertEqual(con.text.count, 30)
        XCTAssertTrue(con.isOpen)
        g.messages.reset()
        _ = frame([], bytes("y"))
        XCTAssertFalse(con.isOpen)
        XCTAssertEqual(texts(g), ["Unknown Command"])
        XCTAssertEqual(g.messages.messages.first?.kind, .error)
        XCTAssertFalse(frame().inputWithheld)

        // Fade-out: visible while fade < 32, += 4 per drawn end frame → gone after 8 draws.
        var calls = 0, drawn: [Int32] = []
        while con.visible && calls < 20 {
            let r = con.drawRequests(formats: g.assets.formats)
            if let first = r.first { drawn.append(first.format.blendAmount) }
            calls += 1
        }
        XCTAssertEqual(calls, 8, "the fade-out lasts 8 frames")
        XCTAssertEqual(drawn, [4, 8, 12, 16, 20, 24, 28])
        XCTAssertEqual(con.fade, 32)
        XCTAssertTrue(con.drawRequests(formats: g.assets.formats).isEmpty)

        // Recall: execute "fps" (a known command), reopen, up-arrow.
        _ = frame([0x32])
        for ch in bytes("fps") { _ = frame([], [ch]) }
        _ = frame([], [0x0D])
        XCTAssertFalse(con.isOpen)
        XCTAssertEqual(g.prefs.bytePrefs[9], 1)
        _ = frame([0x32])
        XCTAssertEqual(con.text, [], "open clears the line")
        let shown = con.drawRequests(formats: g.assets.formats)
        XCTAssertEqual(shown.count, 1, "an empty line draws the prompt only")
        XCTAssertEqual(shown.first?.format.locX, g.assets.formats[33].locX)
        XCTAssertEqual(shown.first?.text, bytes(">"))
        _ = frame([], [0x1E])
        XCTAssertEqual(con.text, bytes("fps"))
        let both = con.drawRequests(formats: g.assets.formats)
        XCTAssertEqual(both.map(\.text), [bytes(">"), bytes("fps")])
        XCTAssertEqual(both.map(\.layer), [15, 15])

        // Expiry: no key for 120 frames keeps it open; frame lastKey + 121 executes (as typed).
        let opened = con.lastKey
        var n = 0
        while con.isOpen && n < 200 { _ = frame(); n += 1 }
        XCTAssertEqual(con.lastKey, opened &+ 121, "frame > lastKey + flli 22 (120), unsigned")
        XCTAssertEqual(g.prefs.bytePrefs[9], 0, "the recalled FPS ran on expiry")
    }

    /// §5.2: exactly the ten registrations of `FUN_100051a0` with r7 = 0, in order; everything else is
    /// `Unknown Command` (type 1, no sound, the last line kept). Names are uppercased; the line's first
    /// whitespace (MSL ctype & 6: 0x09–0x0D, 0x20, 0xCA) ends the name; the handler gets the whole line.
    func testRegisteredCommandsOnly() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        XCTAssertEqual(con.commands.map { MacRoman.decode($0.name) },
                       ["FPS", "VERSION", "VERS", "SUPERMUNKI", "LIFE", "ACCURACY", "FUNDS", "SCORE", "SHIELDS",
                        "MULT"])
        XCTAssertEqual(con.commands.map(\.resultSound), [true, true, true, true, false, false, false, false, false,
                                                         false])
        XCTAssertEqual(con.commands.map(\.hidden), [false, false, false, true, true, true, true, true, true, true])

        run(&con, &g, "fps")
        XCTAssertEqual(g.prefs.bytePrefs[9], 1)
        XCTAssertEqual(texts(g), ["Frame Rate Monitor Enabled"])
        XCTAssertEqual(g.cues.sounds, [perm(g, 4)], "result sound: handler true → gaso 4")
        XCTAssertEqual(g.assets.sounds[4], FourCC("incl"))
        XCTAssertEqual(con.lastLine, bytes("fps"))

        for bad in ["LIMITFPS", "help", "PLAYERACTIVESPAWNS", "shadows", "player god", "alllevels", " fps", "fpsx"] {
            run(&con, &g, bad)
            XCTAssertEqual(texts(g), ["Unknown Command"], bad)
            XCTAssertEqual(g.messages.messages.first?.kind, .error)
            XCTAssertTrue(g.cues.sounds.isEmpty, "\(bad): no sound")
            XCTAssertEqual(con.lastLine, bytes("fps"), "\(bad): an unknown line is not recalled")
        }
        XCTAssertEqual(g.prefs.bytePrefs[9], 1)

        run(&con, &g, "FpS\tand more")
        XCTAssertEqual(g.prefs.bytePrefs[9], 0)
        XCTAssertEqual(texts(g), ["Frame Rate Monitor Disabled"])
        XCTAssertEqual(con.lastLine, bytes("FpS\tand more"))

        run(&con, &g, "")
        XCTAssertTrue(g.messages.messages.isEmpty, "an empty line does nothing")
        XCTAssertTrue(g.cues.sounds.isEmpty)
    }

    /// §5.3–5.4: the cheat word decodes to `supermunki` (`FUN_10046470`), sets byte pref 11 and posts `Cheat Codes
    /// Allowed` (+ gaso 4). Gate order: film → `Not During a Film, Buddy!` (type 1); pref 11 off → silently nothing.
    /// `life`: counter spent, `FUN_10026d70(p, 0)` (no `noel`), cheated, message + gaso 22 only if a player was
    /// active.
    func testCheatWordAndGate() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        XCTAssertEqual(Console.cheatWord, bytes("supermunki"))
        let lives = g.players[0].lives

        run(&con, &g, "life")
        XCTAssertEqual(g.flags.cheatLife, 0)
        XCTAssertEqual(g.players[0].lives, lives)
        XCTAssertTrue(g.messages.messages.isEmpty, "pref 11 off: silently nothing")
        XCTAssertTrue(g.cues.sounds.isEmpty, "cheats have no result sound")

        run(&con, &g, "SuperMunki")
        XCTAssertEqual(g.prefs.bytePrefs[11], 1)
        XCTAssertEqual(texts(g), ["Cheat Codes Allowed"])
        XCTAssertEqual(g.cues.sounds, [perm(g, 4)])

        g.flags.filmPlaying = true
        for code in ["life", "accuracy", "funds", "score", "shields", "mult"] {
            run(&con, &g, code)
            XCTAssertEqual(texts(g), ["Not During a Film, Buddy!"], code)
            XCTAssertEqual(g.messages.messages.first?.kind, .error)
            XCTAssertTrue(g.cues.sounds.isEmpty)
        }
        XCTAssertEqual(g.flags.cheatLife, 0)
        XCTAssertEqual(g.flags.groundCreated, 0)
        g.flags.filmPlaying = false

        let live = g.world.liveCount
        run(&con, &g, "life")
        XCTAssertEqual(g.flags.cheatLife, 1)
        XCTAssertEqual(g.players[0].lives, lives + 1)
        XCTAssertTrue(g.players[0].cheated)
        XCTAssertFalse(g.players[1].cheated, "P2 not in game / not active")
        XCTAssertEqual(g.world.liveCount, live, "fx 0: no noel unit")
        XCTAssertEqual(texts(g), ["Extra Life Awarded!"])
        XCTAssertEqual(g.assets.sounds[22], FourCC("acbo"))
        XCTAssertEqual(g.cues.sounds, [perm(g, 22)])

        // No active player: the counter is still spent, but no message and no sound.
        var h = try game(active: false)
        h.prefs.bytePrefs[11] = 1
        var hc = try Console(assets: h.assets)
        run(&hc, &h, "life")
        XCTAssertEqual(h.flags.cheatLife, 1)
        XCTAssertTrue(h.messages.messages.isEmpty)
        XCTAssertTrue(h.cues.sounds.isEmpty)
        XCTAssertFalse(h.players[0].cheated)
    }

    /// §5.4 limits: life 1, funds 3 (+20 money), score 2 (`FUN_10029a10(p, 10000, 0)` × multiplier), shields 1
    /// (`FUN_10027490(p, 100.0)`), mult 1 (`FUN_10029b20`); accuracy has none (G+0x3c = G+0x40 = 100). Success:
    /// type 0 + gaso 22; refusal: type 1 + gaso 5.
    func testCheatLimits() throws {
        var g = try game()
        g.prefs.bytePrefs[11] = 1
        var con = try Console(assets: g.assets)
        XCTAssertEqual(g.assets.sounds[5], FourCC("lsna"))
        let yes = [perm(g, 22)], no = [perm(g, 5)]
        func check(_ code: String, _ text: String, ok: Bool, line: UInt = #line) {
            run(&con, &g, code)
            XCTAssertEqual(texts(g), [text], line: line)
            XCTAssertEqual(g.messages.messages.first?.kind, ok ? .normal : .error, line: line)
            XCTAssertEqual(g.cues.sounds, ok ? yes : no, line: line)
        }

        check("life", "Extra Life Awarded!", ok: true)
        check("life", "Tut tut!  What a greedy piggy!", ok: false)
        XCTAssertEqual(g.flags.cheatLife, 1)

        let money = g.players[0].money
        for _ in 0..<3 { check("funds", "Money Money Money!", ok: true) }
        check("funds", "Money Can't Buy You Love (Just a Porsche!)", ok: false)
        XCTAssertEqual(g.players[0].money, money + 60)
        XCTAssertEqual(g.flags.cheatFunds, 3)

        g.players[0].multiplier = 2
        let score = g.players[0].score
        for _ in 0..<2 { check("score", "Points Points Points!", ok: true) }
        check("score", "I Think Not, Young Kitty!", ok: false)
        XCTAssertEqual(g.players[0].score, score + 2 * 10_000 * 2, "not raw: × multiplier")
        XCTAssertEqual(g.flags.cheatScore, 2)

        g.players[0].shield = 10
        check("shields", "Maximum Shields!", ok: true)
        XCTAssertEqual(g.players[0].shield, 100)
        g.players[0].shield = 10
        check("shields", "Use The Force, Luke!", ok: false)
        XCTAssertEqual(g.players[0].shield, 10)

        check("mult", "Bonus Multiplier!", ok: true)
        XCTAssertEqual(g.players[0].multiplier, 3)
        check("mult", "Play Bubble Trouble!", ok: false)
        XCTAssertEqual(g.players[0].multiplier, 3)

        for _ in 0..<5 {
            g.flags.groundCreated = 7; g.flags.groundDestroyed = 3
            check("accuracy", "Ground Accuracy 100%", ok: true)
            XCTAssertEqual(g.flags.groundCreated, 100)
            XCTAssertEqual(g.flags.groundDestroyed, 100)
        }
        XCTAssertTrue(g.players[0].cheated)
    }

    /// `10008660`: `"Version: %s, %s, %s"` of `1.0.6`, `Jan  2 2004`, `11:55:08` (data image), type 0; result
    /// sound gaso 4. `VERS` is the same handler.
    func testVersionText() throws {
        var g = try game()
        var con = try Console(assets: g.assets)
        for line in ["version", "VERS"] {
            run(&con, &g, line)
            XCTAssertEqual(texts(g), ["Version: 1.0.6, Jan  2 2004, 11:55:08"], line)
            XCTAssertEqual(g.messages.messages.first?.kind, .normal)
            XCTAssertEqual(g.cues.sounds, [perm(g, 4)])
        }
    }
}

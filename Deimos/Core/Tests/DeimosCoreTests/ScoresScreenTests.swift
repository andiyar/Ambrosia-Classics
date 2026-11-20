import XCTest
import HectorResources
@testable import DeimosCore

/// Phase 4 S4 HS — the scores screen `FUN_10021950`, its table layout `FUN_100222f0(list, prefs, edit, dim, slot,
/// player)` (front-end.md §4.1, §4.2; grounding B §2d) and the Option-click erase question (front-end.md §2.7, plan
/// question 8; `FUN_10004ae0`, grounding B §2a). Positions and formats are read from the dump and the data
/// (PermFloats 76, 77, 78, 80, 81; formats 10–21; the header strings at `0x100e8ba1/ba6/bac`; `inte` 24–27).
/// No frame golden: this bundle has no renderer, so the checks are on the element list and the draw-side calls.
final class ScoresScreenTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private static let full = MacRect(top: 0, left: 0, bottom: 480, right: 640)
    private static let back = FourCC("back")!

    private func step(_ sc: inout Scores, _ s: inout FrontEndState, ticks: UInt32,
                      keys: HeldKeys = HeldKeys()) -> ScreenStep<Scores.Exit> {
        sc.pass(keys: keys, ticks: ticks, returned: nil, state: &s)
    }

    private func exit(_ st: ScreenStep<Scores.Exit>) -> Scores.Exit? {
        if case let .finish(x) = st.next { return x }
        return nil
    }

    /// Headers "Name" / "Score" / "Sector" (formats 10 / 11 / 12 at their own Loc: x 110, 377 right, 463; y 83);
    /// then 15 rows from y = F77 107, F76 19 apart, four elements each: the symbol (the template at `0x100e8968`:
    /// empty text, at x F80 73, y row + F81 7; a sprite only on the edited row), the name, the score `%i` and the
    /// sector name, at y = row. Formats: the edited row hilite 14 / 17 / 20, else dim 15 / 18 / 21 or normal 13 / 16
    /// / 19. The screen: back ← black, `back` → back and save, present, the list drawn once (no restore, no
    /// present), present — no fade. It leaves when more than F78 = 600 ticks have passed, on a click (silent), or
    /// on any key or autoKey; `N` / `n` play gaso 2 and ask for a one-player game. Leaving restores the back
    /// buffer from the save buffer and presents. Input queued before its first pass is flushed (`FUN_10048e30`).
    func testScoresScreenLayout() throws {
        let a = try assets()
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[77]), 107)
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[76]), 19)
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[80]), 73)
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[81]), 7)
        XCTAssertEqual(EntityDraw.fctiwz(a.floats[78]), 600)
        var prefs = DeimosPrefs.fresh
        prefs.highScores[2] = 123_456
        prefs.highScoreNames[2] = "ACE"
        prefs.highScoreSectorNames[2] = "Darius"
        var s = try FrontEndState(assets: a, prefs: prefs)
        var sc = Scores()
        let first = step(&sc, &s, ticks: 1_000,
                         keys: HeldKeys(mouseDowns: [MousePoint(h: 1, v: 1)], keyEvents: [KeyEvent(charCode: 0x6e, keyCode: 0x2d)]))
        XCTAssertNil(exit(first), "queued input before the screen is flushed")
        let list = sc.list
        XCTAssertEqual(list.count, 3 + 4 * 15)
        let headers = [("Name", 10, Int32(110), TextFormat.Alignment.left), ("Score", 11, 377, .right),
                       ("Sector", 12, 463, .left)]
        for (i, (text, fmt, x, align)) in headers.enumerated() {
            let e = list.elements[i]
            XCTAssertTrue(e.isText)
            XCTAssertEqual(MacRoman.decode(e.record.text), text)
            XCTAssertEqual(e.record.format, a.formats[fmt])
            XCTAssertEqual(e.record.format.locX, x)
            XCTAssertEqual(e.record.format.locY, 83)
            XCTAssertEqual(e.record.format.format, align)
        }
        for r in 0..<15 {
            let y = Int32(107 + 19 * r)
            let sym = list.elements[3 + 4 * r], name = list.elements[4 + 4 * r]
            let score = list.elements[5 + 4 * r], sector = list.elements[6 + 4 * r]
            XCTAssertTrue(sym.isText, "row \(r): no ship on the scores screen")
            XCTAssertEqual(sym.record.text, [])
            XCTAssertEqual(sym.record.format.locX, 73)
            XCTAssertEqual(sym.record.format.locY, y + 7)
            XCTAssertEqual(sym.record.format.format, .left)
            XCTAssertEqual(sym.record.layer, 8)
            XCTAssertTrue(sym.record.drawNow)
            XCTAssertEqual(sym.record.scale, 1)
            XCTAssertEqual(MacRoman.decode(name.record.text), prefs.highScoreNames[r])
            XCTAssertEqual(MacRoman.decode(score.record.text), String(prefs.highScores[r]))
            XCTAssertEqual(MacRoman.decode(sector.record.text), prefs.highScoreSectorNames[r])
            var want = a.formats[13]; want.locY = y
            XCTAssertEqual(name.record.format, want, "row \(r) name: normal format 13 at y \(y)")
            want = a.formats[16]; want.locY = y
            XCTAssertEqual(score.record.format, want)
            want = a.formats[19]; want.locY = y
            XCTAssertEqual(sector.record.format, want)
        }
        XCTAssertEqual(list.elements[6 + 4 * 14].record.format.locY, 373, "row 14 at 107 + 14·19")
        XCTAssertEqual(a.formats[11].locX, 377)
        XCTAssertEqual(a.formats[16].format, .right, "scores right-aligned")
        // The draw-side calls.
        let ops = first.output.ops
        XCTAssertEqual(Array(ops.prefix(4)), [.fill(.back, colour: 0),
                                              .loadImage(image: Self.back, into: .back, dst: Self.full),
                                              .loadImage(image: Self.back, into: .terrain, dst: Self.full),
                                              .present(.fullScreen)])
        XCTAssertEqual(ops.last, .present(.fullScreen))
        let draws = ops.dropFirst(4).dropLast()
        XCTAssertTrue(draws.allSatisfy { if case .draw = $0 { return true } else { return false } },
                      "drawn once: no restore, no per-element present, no wait, no fade")
        // The "Name" header's first glyph: LEFT at Loc X 110 — cell = 110 + spacing, centre x = cell + w/2.
        let glyphs = draws.compactMap { op -> DrawCommand? in
            if case let .draw(c) = op, c.face == s.text.font { return c } else { return nil }
        }
        let n = try XCTUnwrap(glyphs.first, "no glyph")
        let fmt10 = a.formats[10]
        let w = s.text.measure(0x4e, scale: 1).size
        XCTAssertEqual(n.x, 110 + fmt10.spaceBetweenChars + w.width / 2)
        XCTAssertEqual(n.y, 83 + w.height / 2)
        XCTAssertEqual(first.output.sounds, [])
        XCTAssertEqual(first.output.requests, [])

        // 600 ticks: 1000 + 600 is not past; 1601 leaves.
        XCTAssertNil(exit(step(&sc, &s, ticks: 1_600)))
        let timeout = step(&sc, &s, ticks: 1_601)
        XCTAssertEqual(exit(timeout), .leave)
        XCTAssertEqual(timeout.output.ops, [.copy(from: .terrain, to: .back, src: nil, dst: nil, interlaced: false),
                                            .present(.fullScreen)])
        XCTAssertEqual(timeout.output.sounds, [])
        // The time test comes before the events: at 1601 a queued `N` is not read.
        var late = Scores()
        _ = step(&late, &s, ticks: 1_000)
        XCTAssertEqual(exit(step(&late, &s, ticks: 1_601, keys: HeldKeys(keyEvents: [KeyEvent(charCode: 0x4e, keyCode: 0x2d)]))),
                       .leave)
        // A click leaves silently; a key leaves; `N` / `n` (keyDown or autoKey) start a game with gaso 2.
        let incl = SoundPlay.perm(a.sounds[2], priority: 0x32, volume: 100, allowMultiple: true)
        let cases: [(HeldKeys, Scores.Exit, [SoundCue])] = [
            (HeldKeys(mouseDowns: [MousePoint(h: 320, v: 240)]), .leave, []),
            (HeldKeys(keyEvents: [KeyEvent(charCode: 0x78, keyCode: 0x07)]), .leave, []),
            (HeldKeys(keyEvents: [KeyEvent(charCode: 0x4e, keyCode: 0x2d)]), .newGame, [incl]),
            (HeldKeys(keyEvents: [KeyEvent(charCode: 0x6e, keyCode: 0x2d, autoRepeat: true)]), .newGame, [incl]),
        ]
        for (keys, want, sounds) in cases {
            var x = Scores()
            _ = step(&x, &s, ticks: 50)
            XCTAssertNil(exit(step(&x, &s, ticks: 60)), "no input, no exit")
            let st = step(&x, &s, ticks: 70, keys: keys)
            XCTAssertEqual(exit(st), want)
            XCTAssertEqual(st.output.sounds, sounds)
        }
        XCTAssertEqual(s.prefs, prefs, "the scores screen changes nothing")

        // Name entry's layout (edit 1, dim 1, slot 6, player 1): row 6 hilite with player 2's ship, others dim.
        var ne = NameEntry(player: 1, slot: 6, prefs: prefs)
        _ = ne.pass(keys: HeldKeys(), ticks: 0, returned: nil, state: &s)
        let plde = try XCTUnwrap(a.definitions.players.first { $0.id == a.objects[1] })
        for r in 0..<15 {
            let y = Int32(107 + 19 * r)
            let sym = ne.list.elements[3 + 4 * r]
            let fmts = r == 6 ? [14, 17, 20] : [15, 18, 21]
            for (k, f) in fmts.enumerated() {
                var want = a.formats[f]; want.locY = y
                XCTAssertEqual(ne.list.elements[4 + 4 * r + k].record.format, want, "row \(r) element \(k)")
            }
            if r == 6 {
                XCTAssertEqual(sym.sprite, plde.spriteHighScore, "player def +0x28")
                XCTAssertEqual(sym.frame, Int(plde.spriteHighScoreFrame), "player def +0x2c")
                XCTAssertEqual(sym.record.format.locX, 73)
                XCTAssertEqual(sym.record.format.locY, y + 7)
            } else {
                XCTAssertTrue(sym.isText)
            }
        }
        XCTAssertEqual(a.formats[14].coloriseColor, 0x03ff, "hilite colourises cyan 00ffff")
    }

    /// Option-click on SCORES (front-end.md §2.7): the menu asks the question (`inte` 24 "Erase High Scores", 25,
    /// buttons 26 "Erase" / 27 "Cancel") through the question wait; "Erase" runs `FUN_10004ae0`, which writes the
    /// default table AND resets both remembered player names to "Player %i" (its first loop, dump line 2842) — live
    /// prefs only. "Cancel" changes nothing. The scores screen itself never asks.
    func testEraseResetsPlayerNames() throws {
        let a = try assets()
        let inte = try a.interfaceStrings()
        var prefs = DeimosPrefs.fresh
        prefs.highScores = (0..<15).map { Int32(90_000 - 10 * $0) }
        prefs.highScoreNames = (0..<15).map { "N\($0)" }
        prefs.highScoreSectorNames = Array(repeating: "Darius", count: 15)
        prefs.playerNames = ["ACE", "BOB"]
        prefs.intPrefs[3] = 7
        prefs.keyTable[0] = 0x0c
        // The table routine alone.
        let erased = HighScoreTable.erase(prefs)
        XCTAssertEqual(erased.highScores, (1...15).map { Int32(16_000 - 1_000 * $0) })
        XCTAssertEqual(erased.highScoreNames, ["Mars", "Supercobra", "Neurotik", "El B", "Dilvish", "Sam", "Vodi", "Fisj",
                                               "Alex", "h'biki", "Goldenberry", "Leadfeather", "Troll", "Thomas",
                                               "Electrofryer"])
        XCTAssertEqual(erased.highScoreSectorNames, Array(repeating: "New Atlantis", count: 15))
        XCTAssertEqual(erased.playerNames, ["Player 1", "Player 2"])
        XCTAssertEqual(erased.intPrefs, prefs.intPrefs, "only the table and the player names")
        XCTAssertEqual(erased.keyTable, prefs.keyTable)

        // The question the menu asks (inte 24–27), and the answer applied: "Erase" (first) erases, "Cancel" does not.
        let q = HighScoreTable.eraseQuestion(a)
        XCTAssertEqual(q.message, try XCTUnwrap(inte.string(at: 24)) + "\n" + XCTUnwrap(inte.string(at: 25)))
        XCTAssertEqual(inte.string(at: 24), "Erase High Scores")
        XCTAssertEqual(q.firstButton, inte.string(at: 26))
        XCTAssertEqual(q.secondButton, inte.string(at: 27))
        XCTAssertEqual(q.firstButton, "Erase")
        XCTAssertEqual(q.secondButton, "Cancel")
        XCTAssertEqual(HighScoreTable.erase(prefs, answer: .first), erased)
        XCTAssertEqual(HighScoreTable.erase(prefs, answer: .second), prefs, "Cancel changes nothing")
        // The scores screen shows whatever table it is given; it never asks.
        var s = try FrontEndState(assets: a, prefs: erased)
        var sc = Scores()
        let shown = step(&sc, &s, ticks: 400)
        XCTAssertEqual(shown.output.requests, [], "the question is the menu's")
        XCTAssertEqual(MacRoman.decode(sc.list.elements[4].record.text), "Mars")
    }
}

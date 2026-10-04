@testable import BubbleTroubleCore
import Foundation
import XCTest

/// C7 — high-score entry, the scores screen and the credits (plan 2026-10-04 btx-playable §C7; FI §3e) against
/// `_RequestGame @ 0000a9a1`, `_CheckHiScore @ 00024b34`, `_DisplayHiScores @ 00025733`, `_DrawSingleHiScore
/// @ 0002553a`, `_CreditsButton @ 0000ae16`, `_DisplayCredits @ 0002145a` and `_DrawCredit @ 0001eee4`.
/// Data-gated on `HECTORKIT_DATA_BTX` (always set under G1).
final class HighScoreScreenTests: XCTestCase {

    // MARK: Helpers

    private func gameData() throws -> BTXGameData {
        try BTXGameData(resourcesDirectory: BTXTestData.resourcesDirectory())
    }

    private func frontEnd(_ data: BTXGameData, scores: HighScoreTable) -> FrontEnd {
        FrontEnd(data: data, prefs: .defaults, highScores: scores, registeredName: "Ben", today: { (3, 3) })
    }

    private static let away = MousePoint(h: 600, v: 20, button: false)

    /// Every score negative, so even a 0-point game qualifies (rank 0); slot 0 = "Ben".
    private func lowTable() -> HighScoreTable {
        var t = HighScoreTable.empty
        for i in 0..<HighScoreTable.entryCount { t.setEntry(i, name: "Low\(i)", score: Int32(-1 - i), level: 1) }
        t.defaultName = "Ben"
        return t
    }

    /// One screen tick per TickCount, from `now`; returns the outputs, one per tick.
    private func run(_ s: FrontEndScreen, _ n: Int, now: inout UInt32, keys: HeldKeys = HeldKeys()) -> [SessionOutput] {
        (0..<n).map { _ in
            defer { now += 1 }
            return s.tick(now: now, keys: keys, mouse: Self.away)
        }
    }

    @discardableResult
    private func ticks(_ fe: FrontEnd, now: inout UInt32, keys: HeldKeys = HeldKeys(), limit: Int = 6000,
                       while condition: (FrontEnd) -> Bool) -> SessionOutput {
        var all = SessionOutput()
        var n = 0
        while condition(fe) && n < limit {
            all.append(fe.tick(now: now, keys: keys, mouse: Self.away))
            now += 1
            n += 1
        }
        XCTAssertLessThan(n, limit, "tick loop did not finish")
        return all
    }

    /// Runs the current game to its end with `frameKeys` held on every frame (ticks while it wants no frames).
    private func playToEnd(_ fe: FrontEnd, now: inout UInt32, frameKeys: HeldKeys) -> SessionOutput {
        var all = SessionOutput()
        var n = 0
        while fe.session != nil && n < 20000 {
            if fe.wantsFrameTimer {
                all.append(fe.frame(keys: frameKeys))
            } else {
                all.append(fe.tick(now: now, keys: HeldKeys(), mouse: Self.away))
                now += 1
            }
            n += 1
        }
        XCTAssertNil(fe.session, "game did not end")
        return all
    }

    private static let esc = HeldKeys(codes: [0x35])
    private static let click = SoundCue(slot: 0x11, priority: 10, delayFrames: 0)

    private func nameDialogs(_ out: SessionOutput) -> [String] {
        out.requests.compactMap { if case .highScoreNameDialog(let d) = $0 { d } else { nil } }
    }

    // MARK: Eligibility

    func testHighScoreOnlyFromLevel1() throws {
        XCTAssertTrue(FrontEnd.checksHighScore(mode: .play, startLevel: 1, cheating: false))
        XCTAssertFalse(FrontEnd.checksHighScore(mode: .play, startLevel: 2, cheating: false))
        XCTAssertFalse(FrontEnd.checksHighScore(mode: .play, startLevel: 1, cheating: true))
        XCTAssertFalse(FrontEnd.checksHighScore(mode: .demo, startLevel: 1, cheating: false))

        let data = try gameData()
        // A level-1 game quit with Esc still gets `_CheckHiScore`: 0 points beat this table's seventh entry.
        var fe = frontEnd(data, scores: lowTable())
        var now: UInt32 = 1000
        ticks(fe, now: &now) { $0.phase != .menu }
        _ = fe.key(0x2d, chars: "n", modifiers: KeyModifiers())
        ticks(fe, now: &now) { $0.session == nil }
        XCTAssertFalse(try XCTUnwrap(fe.session).playerIsCheating)
        var out = playToEnd(fe, now: &now, frameKeys: Self.esc)
        XCTAssertEqual(nameDialogs(out), ["Ben"])
        XCTAssertEqual(fe.highScores.entry(0).score, 0)
        XCTAssertEqual(fe.highScores.entry(0).level, 1)
        // The answer goes through the front end: snd 15, "Dog" → "Nonny" + snd 46; then (C6's `_RequestGame` path)
        // snd 19 and the scores screen with the new row.
        let named = fe.highScoreNameEntered("Dog")
        XCTAssertEqual(Array(named.sounds.prefix(3)), [SoundCue(slot: 15, priority: 10, delayFrames: 0),
                                                        SoundCue(slot: 46, priority: 10, delayFrames: 0),
                                                        SoundCue(slot: 19, priority: 0x14, delayFrames: 0)])
        XCTAssertTrue(named.drawOps.contains(.string(text: "Nonny", h: 116, v: 188, highlighted: false, fixedPitch: nil,
                                                     target: .comp)))
        XCTAssertEqual(fe.highScores.entry(0).name, "Nonny")
        XCTAssertEqual(fe.highScores.defaultName, "Nonny")
        XCTAssertEqual(fe.phase, .busy)

        // Level select (start 5) sets `gPlayerIsCheating`: no check, straight back to the menu.
        fe = frontEnd(data, scores: lowTable())
        now = 1000
        ticks(fe, now: &now) { $0.phase != .menu }
        _ = fe.key(0x25, chars: "l", modifiers: KeyModifiers())
        _ = fe.tick(now: now, keys: HeldKeys(), mouse: Self.away)
        now += 1
        _ = fe.levelSelectDone(typed: 5)
        ticks(fe, now: &now) { $0.session == nil }
        XCTAssertTrue(try XCTUnwrap(fe.session).playerIsCheating)
        out = playToEnd(fe, now: &now, frameKeys: Self.esc)
        out.append(ticks(fe, now: &now) { $0.phase != .menu })
        XCTAssertTrue(nameDialogs(out).isEmpty)
        XCTAssertEqual(fe.highScores, lowTable())
    }

    // MARK: `_CheckHiScore`

    func testEntryDialogRequestDefaults() throws {
        let data = try gameData()
        let factory = try HighScoreTable.factory(from: data)          // Potsie 4500 … Sherman 500; slot 0 "The Fonz"
        var fe = frontEnd(data, scores: factory)
        var now: UInt32 = 500
        // Not above entry #7 (500): no overlay, no dialog, no row.
        var s = fe.makeHighScoreCheck(score: 500, level: 9)
        XCTAssertEqual(run(s, 1, now: &now)[0], SessionOutput())
        XCTAssertEqual(s.result, .highScoreEntered(rank: nil))
        XCTAssertEqual(fe.highScores, factory)

        // 1200 at level 3 → row 1 (below Potsie 4500): the overlay on comp, shown; snd 13; DLOG 1000 preset to slot 0.
        s = fe.makeHighScoreCheck(score: 1200, level: 3)
        let open = run(s, 1, now: &now)[0]
        XCTAssertEqual(open.drawOps, [.patternOverlay(index: 4), .compToScreen(QDRect(top: 0, left: 0, bottom: 480,
                                                                                      right: 640))])
        XCTAssertEqual(open.sounds, [SoundCue(slot: 13, priority: 10, delayFrames: 0)])
        XCTAssertEqual(open.requests, [.highScoreNameDialog(defaultName: "The Fonz"), .setCursor(id: nil)])
        XCTAssertEqual(fe.highScores.entries.map(\.score), [4500, 1200, 1000, 500, 500, 500, 500])
        XCTAssertEqual(fe.highScores.entry(1).level, 3)
        // The dialog is modal: ticks and keys do nothing until it is answered.
        _ = s.key(0x00, chars: "x", modifiers: KeyModifiers())
        XCTAssertTrue(run(s, 100, now: &now).allSatisfy { $0 == SessionOutput() })
        XCTAssertNil(s.result)
        // OK with "Wareing": snd 15, then the joke name "Swoop!" with snd 13; entry and slot 0 both; `_UpdateScreen`.
        let ok = s.dialogAnswered(.name("Wareing"))
        XCTAssertEqual(ok.sounds, [SoundCue(slot: 15, priority: 10, delayFrames: 0),
                                   SoundCue(slot: 13, priority: 10, delayFrames: 0)])
        XCTAssertEqual(ok.drawOps, [.compToScreen(QDRect(top: 0, left: 0, bottom: 480, right: 640))])
        XCTAssertEqual(s.result, .highScoreEntered(rank: 1))
        XCTAssertEqual(fe.highScores.entry(1).name, "Swoop!")
        XCTAssertEqual(fe.highScores.defaultName, "Swoop!")

        // An empty field → "Maniac" (0) / "Swoop" (1) by `GetRandomFast(0, 1)` on the front end's stream, no extra snd.
        fe = frontEnd(data, scores: factory)
        s = fe.makeHighScoreCheck(score: 600, level: 2)
        XCTAssertEqual(run(s, 1, now: &now)[0].requests.first, .highScoreNameDialog(defaultName: "The Fonz"))
        var stream = fe.random
        let expected = stream.fast(0, 1) == 0 ? "Maniac" : "Swoop"
        XCTAssertEqual(s.dialogAnswered(.name("")).sounds, [SoundCue(slot: 15, priority: 10, delayFrames: 0)])
        XCTAssertEqual(fe.random.seed, stream.seed)
        XCTAssertEqual(fe.highScores.entry(2).name, expected)          // 600 > Ritchie 500 → row 2
        XCTAssertEqual(fe.highScores.entry(2).score, 600)
        XCTAssertEqual(fe.highScores.defaultName, expected)
    }

    // MARK: `_DisplayHiScores`

    private func expectedRow(_ e: HighScoreTable.Entry, v: Int) -> [DrawOp] {
        [.string(text: e.name, h: 116, v: v, highlighted: false, fixedPitch: nil, target: .comp),
         .string(text: "\(e.score)", h: 340, v: v, highlighted: false, fixedPitch: 15, target: .comp),
         .string(text: "\(e.level)", h: 472, v: v, highlighted: false, fixedPitch: 15, target: .comp)]
    }

    func testScoresScreenLayoutOps() throws {
        let data = try gameData()
        var table = try HighScoreTable.factory(from: data)
        table.setEntry(3, name: "Ben^", score: 500, level: 1)
        let fe = frontEnd(data, scores: table)
        let backdrop = MainMenu.centred(data: data, pict: 912)
        XCTAssertEqual(backdrop, QDRect(top: 0, left: 0, bottom: 480, right: 640))
        var expected: [DrawOp] = [.pict(id: 912, dst: backdrop, target: .bgnd), .pict(id: 912, dst: backdrop, target: .comp),
                                  .pict(id: 9020, dst: QDRect(top: 80, left: 209, bottom: 117, right: 431), target: .comp),
                                  .string(text: "Name", h: 116, v: 145, highlighted: true, fixedPitch: nil, target: .comp),
                                  .string(text: "Score", h: 337, v: 145, highlighted: true, fixedPitch: nil, target: .comp),
                                  .string(text: "Level", h: 451, v: 145, highlighted: true, fixedPitch: nil, target: .comp)]
        for i in 0..<7 {
            var row = expectedRow(table.entry(i), v: 188 + 35 * i)
            if i == 3 {   // the "^" badge, PICT 9077 at L49 T v R96 B v+23
                row.insert(.pict(id: 9077, dst: QDRect(top: 293, left: 49, bottom: 316, right: 96), target: .comp), at: 1)
            }
            expected += row
        }
        expected.append(.wipe(step: 12))
        let s = fe.makeScoresScreen(newEntryRank: nil)
        var now: UInt32 = 2000
        let outs = run(s, 40, now: &now)
        XCTAssertEqual(outs[0].drawOps, expected)
        XCTAssertEqual(outs[0].sounds, [])
        XCTAssertTrue(outs[1...].allSatisfy { $0 == SessionOutput() })
        // A key during the wipe (22 advances) is flushed: still on the screen afterwards.
        let s2 = fe.makeScoresScreen(newEntryRank: nil)
        now = 3000
        _ = run(s2, 5, now: &now)
        _ = s2.key(0x07, chars: "x", modifiers: KeyModifiers())
        _ = s2.mouseDown(h: 10, v: 10, modifiers: KeyModifiers())
        XCTAssertTrue(run(s2, 30, now: &now).allSatisfy { $0 == SessionOutput() })
        XCTAssertNil(s2.result)
        _ = s2.key(0x07, chars: "x", modifiers: KeyModifiers())
        XCTAssertEqual(run(s2, 1, now: &now)[0].sounds, [Self.click])
        XCTAssertEqual(s2.result, .finished)
    }

    func testNewEntryFlashes6() throws {
        let data = try gameData()
        let table = try HighScoreTable.factory(from: data)
        let fe = frontEnd(data, scores: table)
        let s = fe.makeScoresScreen(newEntryRank: 2)
        var now: UInt32 = 1000
        let outs = run(s, 700, now: &now)
        // Wipe: 22 advances → done at +22; `_WaitFor(20)` → the first off half at +42; halves of 5 ticks.
        let r = QDRect(top: 253, left: 116, bottom: 286, right: 521)                // 0xb7 + 70 … 0xd8 + 70
        let off: [DrawOp] = [.restoreBgnd(QDRect(top: 253, left: 116, bottom: 286, right: 524), target: .comp),
                             .compToScreen(r)]
        let on = expectedRow(table.entry(2), v: 258) + [.compToScreen(QDRect(top: 253, left: 106, bottom: 286, right: 521))]
        var times: [Int] = []
        for (t, o) in outs.enumerated().dropFirst() where o != SessionOutput() {
            times.append(t)
            XCTAssertEqual(o.drawOps, (t - 42) % 10 == 0 ? off : on, "tick +\(t)")
            XCTAssertTrue(o.sounds.isEmpty)
        }
        XCTAssertEqual(times, [42, 47, 52, 57, 62, 67, 72, 77, 82, 87, 92, 97])        // 6 × (off, on)
        // 600 ticks from entry, flash included: back at +601, silently.
        XCTAssertEqual(s.result, .finished)
        let s2 = fe.makeScoresScreen(newEntryRank: 2)
        now = 5000
        _ = run(s2, 601, now: &now)
        XCTAssertNil(s2.result)
        _ = run(s2, 1, now: &now)
        XCTAssertEqual(s2.result, .finished)
    }

    func testScoresTimeout600() throws {
        let data = try gameData()
        let fe = frontEnd(data, scores: try HighScoreTable.factory(from: data))
        // No input: `TickCount() > start + 600` → back at +601, no sound.
        var s = fe.makeScoresScreen(newEntryRank: nil)
        var now: UInt32 = 100
        var outs = run(s, 601, now: &now)
        XCTAssertNil(s.result)
        outs += run(s, 1, now: &now)
        XCTAssertEqual(s.result, .finished)
        XCTAssertTrue(outs.allSatisfy { $0.sounds.isEmpty })
        // N / n → new game; another key or a click → back; each with snd 17.
        for (chars, result) in [("N", FrontEndScreenResult.newGame), ("n", .newGame), ("x", .finished)] {
            s = fe.makeScoresScreen(newEntryRank: nil)
            _ = run(s, 30, now: &now)
            _ = s.key(0x2d, chars: chars, modifiers: KeyModifiers())
            XCTAssertEqual(run(s, 1, now: &now)[0].sounds, [Self.click], chars)
            XCTAssertEqual(s.result, result, chars)
        }
        s = fe.makeScoresScreen(newEntryRank: nil)
        _ = run(s, 30, now: &now)
        _ = s.mouseDown(h: 1, v: 1, modifiers: KeyModifiers())
        XCTAssertEqual(run(s, 1, now: &now)[0].sounds, [Self.click])
        XCTAssertEqual(s.result, .finished)
        // Suspend / resume are handled in place (`_SuspendGame` / `_ResumeGame`), the screen stays.
        s = fe.makeScoresScreen(newEntryRank: nil)
        _ = run(s, 30, now: &now)
        _ = s.appDeactivated()
        _ = run(s, 1, now: &now)
        XCTAssertTrue(fe.suspended)
        _ = s.appActivated()
        XCTAssertEqual(run(s, 1, now: &now)[0].requests, [.setCursor(id: 200), .showCursor])
        XCTAssertFalse(fe.suspended)
        XCTAssertNil(s.result)

        // ⌘Q held with no event pending → `gFinished`: back to the menu (wipe), then the loop quits.
        let fe2 = frontEnd(data, scores: try HighScoreTable.factory(from: data))
        now = 1000
        ticks(fe2, now: &now) { $0.phase != .menu }
        _ = fe2.key(0x01, chars: "s", modifiers: KeyModifiers())
        ticks(fe2, now: &now) { !($0.activeScreen is HighScoresScreen) }
        for _ in 0..<40 { _ = fe2.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1 }   // past the wipe
        XCTAssertTrue(fe2.activeScreen is HighScoresScreen)
        let quit = ticks(fe2, now: &now, keys: HeldKeys(codes: [0x0c], command: true)) { $0.phase != .quit }
        XCTAssertTrue(fe2.finished)
        XCTAssertTrue(quit.drawOps.contains(.wipe(step: 12)))
        XCTAssertTrue(quit.requests.contains(.quit))
    }

    // MARK: Credits

    /// Runs a credits screen to its end; returns (tick offset, ops) of every page drawn.
    private func pages(_ s: FrontEndScreen, now: inout UInt32) -> [(t: Int, ops: [DrawOp])] {
        let start = now
        var drawn: [(Int, [DrawOp])] = []
        var n = 0
        while s.result == nil && n < 20000 {
            let o = s.tick(now: now, keys: HeldKeys(), mouse: Self.away)
            XCTAssertTrue(o.sounds.isEmpty)
            if !o.drawOps.isEmpty { drawn.append((Int(now - start), o.drawOps)) }
            now += 1
            n += 1
        }
        return drawn
    }

    private func firstLine(_ ops: [DrawOp]) -> String? {
        for op in ops { if case .string(let text, _, _, _, _, _) = op { return text } }
        return nil
    }

    func testCreditsPageTiming() throws {
        let data = try gameData()
        let fe = frontEnd(data, scores: .empty)
        let s = fe.makeCreditsScreen(secret: 0)
        var now: UInt32 = 1000
        let drawn = pages(s, now: &now)
        XCTAssertEqual(s.result, .finished)
        XCTAssertEqual(drawn.count, 14)
        let full = QDRect(top: 0, left: 0, bottom: 480, right: 640)
        XCTAssertEqual(drawn[0].ops, [.pict(id: 912, dst: full, target: .comp),
                                      .string(text: "Coding + Design Maestros", h: -1, v: 200, highlighted: true,
                                              fixedPitch: nil, target: .comp),
                                      .string(text: "Alex Metcalf", h: -1, v: 230, highlighted: false, fixedPitch: nil,
                                              target: .comp),
                                      .string(text: "David Wareing", h: -1, v: 260, highlighted: false, fixedPitch: nil,
                                              target: .comp),
                                      .wipe(step: 8)])
        // Page 0 timed from entry (> +240 → +241); later pages from the end of their 32-advance wipe (+32 + 241).
        XCTAssertEqual(drawn.map(\.t), [0] + (0..<13).map { 241 + 273 * $0 })
        XCTAssertEqual(Int(now - 1000), 241 + 273 * 12 + 32 + 241 + 1)            // back after page 13's 240 ticks
        XCTAssertEqual(drawn.map { firstLine($0.ops) ?? "" }, [
            "Coding + Design Maestros", "Title + Background Artwork", "Sprite Artwork", "OS X Transmogrifying",
            "Ambrosia Software Crew", "Musicians", "Sound FX", "Ambrosia Software Tools", "OS X Testing Team",
            "OS X Testing Team", "Original Testing Team", "Original Testing Team", "Original Testing Team",
            "Original Testing Team",
        ])
        XCTAssertTrue(drawn[9].ops.contains(.string(text: "Benjamin 'Andiyar' Thomas", h: -1, v: 410, highlighted: false,
                                                    fixedPitch: nil, target: .comp)))
        XCTAssertTrue(drawn.allSatisfy { $0.ops.first == .pict(id: 912, dst: full, target: .comp)
                                         && $0.ops.last == .wipe(step: 8) })
    }

    func testSecretPagesByModifier() throws {
        // `_CreditsButton`: the first modifier of control / option / ⌘ / shift picks the set and its sound.
        XCTAssertTrue(FrontEnd.creditsSecret(KeyModifiers()) == (0, 19))
        XCTAssertTrue(FrontEnd.creditsSecret(KeyModifiers(control: true)) == (1, 38))
        XCTAssertTrue(FrontEnd.creditsSecret(KeyModifiers(option: true)) == (2, 40))
        XCTAssertTrue(FrontEnd.creditsSecret(KeyModifiers(command: true)) == (3, 44))
        XCTAssertTrue(FrontEnd.creditsSecret(KeyModifiers(shift: true)) == (4, 39))
        XCTAssertTrue(FrontEnd.creditsSecret(KeyModifiers(command: true, shift: true, option: true, control: true))
                      == (1, 38))
        let data = try gameData()
        let fe = frontEnd(data, scores: .empty)
        var now: UInt32 = 1000
        let sets: [(Int, [String])] = [
            (1, ["Recommended Reading Follows...", "The Selfish Gene", "Hannibal", "The Forge of God",
                 "Fear and Loathing in Las Vegas", "Brave New World", "The Kraken Wakes", "All The Trouble in the World",
                 "The Tao Of Pooh"]),
            (2, ["David's Recommended Viewing", "Alex's Recommended Viewing", "David's Recommended Listening",
                 "Alex's Recommended Listening"]),
            (3, ["Some Human Rights Abusers", "Some Things To Do On A Rainy Day or Night", "In memorium"]),
            (4, ["Alex's favourite things in life", "Alex's reasons for you to pay shareware fee", "Some truly great people",
                 "Have you seen these (young looking) men?"]),
        ]
        var drawnBySet: [Int: [(t: Int, ops: [DrawOp])]] = [:]
        for (secret, firsts) in sets {
            let drawn = pages(fe.makeCreditsScreen(secret: secret), now: &now)
            XCTAssertEqual(drawn.map { firstLine($0.ops) ?? "" }, firsts, "secret \(secret)")
            drawnBySet[secret] = drawn
        }
        // Page 29: Carl Sagan's picture is IMAG 128 (`_DrawSecretPictInRect`) at L227 T166 R412 B313, after the text.
        let sagan = try XCTUnwrap(drawnBySet[3]?.last?.ops)
        XCTAssertEqual(Array(sagan.suffix(4)), [
            .string(text: "In memorium", h: -1, v: 112, highlighted: true, fixedPitch: nil, target: .comp),
            .string(text: "Carl Sagan,  1934 - 1996", h: -1, v: 343, highlighted: true, fixedPitch: nil, target: .comp),
            .imag(id: 128, dst: QDRect(top: 166, left: 227, bottom: 313, right: 412), target: .comp),
            .wipe(step: 8),
        ])
        // Page 31 is left-aligned at x 40; page 33 has the two photos (PICT 29402 Alex, 29401 David).
        let reasons = try XCTUnwrap(drawnBySet[4]?[1].ops)
        XCTAssertTrue(reasons.contains(.string(text: "7. Beer is expensive.", h: 40, v: 335, highlighted: false,
                                               fixedPitch: nil, target: .comp)))
        let wanted = try XCTUnwrap(drawnBySet[4]?[3].ops)
        XCTAssertEqual(Array(wanted.suffix(3)), [
            .pict(id: 29402, dst: QDRect(top: 129, left: 100, bottom: 301, right: 248), target: .comp),
            .pict(id: 29401, dst: QDRect(top: 129, left: 400, bottom: 301, right: 548), target: .comp),
            .wipe(step: 8),
        ])
        XCTAssertTrue(wanted.contains(.string(text: "David Wareing", h: 390, v: 318, highlighted: true, fixedPitch: nil,
                                              target: .comp)))

        // Through the menu: a control-click on the logo → snd 17, snd 38, then the reading list.
        let fe2 = frontEnd(data, scores: .empty)
        ticks(fe2, now: &now) { $0.phase != .menu }
        _ = fe2.mouseDown(h: 320, v: 100, modifiers: KeyModifiers(control: true))   // control-click on the logo
        let out = ticks(fe2, now: &now) { !($0.activeScreen is CreditsScreen) }
        XCTAssertTrue(out.sounds.contains(SoundCue(slot: 38, priority: 0x14, delayFrames: 0)))
        XCTAssertTrue(out.drawOps.contains(.string(text: "Recommended Reading Follows...", h: -1, v: 215,
                                                   highlighted: true, fixedPitch: nil, target: .comp)))
    }

    func testCreditsNStartsGame() throws {
        let data = try gameData()
        let fe = frontEnd(data, scores: .empty)
        var now: UInt32 = 1000
        // N / n → snd 17 and a new game; another key or a click → snd 17 and back.
        for (chars, result) in [("N", FrontEndScreenResult.newGame), ("n", .newGame), ("q", .finished)] {
            let s = fe.makeCreditsScreen(secret: 0)
            _ = run(s, 40, now: &now)
            _ = s.key(0x2d, chars: chars, modifiers: KeyModifiers())
            XCTAssertEqual(run(s, 1, now: &now)[0].sounds, [Self.click], chars)
            XCTAssertEqual(s.result, result, chars)
        }
        var s = fe.makeCreditsScreen(secret: 0)
        _ = run(s, 40, now: &now)
        _ = s.mouseDown(h: 5, v: 5, modifiers: KeyModifiers())
        XCTAssertEqual(run(s, 1, now: &now)[0].sounds, [Self.click])
        XCTAssertEqual(s.result, .finished)
        // Input during the first wipe is flushed; during a later page's wipe it waits and acts when the wipe ends.
        s = fe.makeCreditsScreen(secret: 0)
        let start = now
        _ = run(s, 10, now: &now)
        _ = s.key(0x07, chars: "x", modifiers: KeyModifiers())
        _ = run(s, 241, now: &now)                                                   // to +251: page 1's wipe runs
        XCTAssertNil(s.result)
        _ = s.key(0x07, chars: "x", modifiers: KeyModifiers())
        let rest = run(s, 30, now: &now)                                             // the wipe ends at +273
        XCTAssertEqual(s.result, .finished)
        XCTAssertEqual(rest.firstIndex { !$0.sounds.isEmpty }.map { Int(now) - 30 + $0 - Int(start) }, 273)
        // Resume (`_ResumeGame`): `pageStart = TickCount − 240` → the next page at the next tick.
        s = fe.makeCreditsScreen(secret: 0)
        _ = run(s, 50, now: &now)
        _ = s.appActivated()
        let resumed = run(s, 2, now: &now)
        XCTAssertEqual(resumed[0].requests, [.setCursor(id: 200), .showCursor])
        XCTAssertEqual(firstLine(resumed[1].drawOps), "Title + Background Artwork")

        // Through the menu: C → credits; N there → `_NewGameButton` → a level-1 game.
        let fe2 = frontEnd(data, scores: .empty)
        ticks(fe2, now: &now) { $0.phase != .menu }
        _ = fe2.key(0x08, chars: "c", modifiers: KeyModifiers())
        ticks(fe2, now: &now) { !($0.activeScreen is CreditsScreen) }
        for _ in 0..<40 { _ = fe2.tick(now: now, keys: HeldKeys(), mouse: Self.away); now += 1 }
        _ = fe2.key(0x2d, chars: "n", modifiers: KeyModifiers())
        ticks(fe2, now: &now) { $0.session == nil }
        let game = try XCTUnwrap(fe2.session)
        XCTAssertEqual(game.mode, .play)
        XCTAssertEqual(game.state.level, 1)
    }
}

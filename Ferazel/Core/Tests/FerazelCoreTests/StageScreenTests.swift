import XCTest
@testable import FerazelCore

/// L2 (docs/plans/2026-10-14-ferazel-phase3.md): the screens between two levels — `.ChapterScreen` (M l. 5038–5089),
/// `.PopupStageLoad` / `.UpdateStageLoad` (M l. 2946–3029), `.StageCompleteEffect` (M l. 2870–2943), `.CalcPercent`
/// (M l. 2843–2865) and `.FillPercent` (M l. 2752–2836). Bank: world-data-format §4.3 (BC9). Rects are built by field
/// name (`Rect16` = QuickDraw {top, left, bottom, right}). A missing data file is a FAILURE, never a skip.
final class StageScreenTests: XCTestCase {

    /// Synthetic play lengths (ticks) except 804, whose 2304 samples at 22,050 Hz are 7 ticks rounded up [MED].
    private static let lengths: [Int16: Int] = [800: 30, 801: 40, 802: 50, 803: 5,
                                                804: StageSounds.ticks(sampleCount: 2304, sampleRate: 22_050), 805: 20]

    private func sounds(on: Bool = true) -> StageSounds {
        var prefs = FerazelPrefs()
        prefs.soundOn = on ? 1 : 0
        return StageSounds(prefs: prefs, lengths: Self.lengths)
    }

    private func cue(_ snd: Int16, _ volume: Int16) -> SoundCue {
        SoundCues.regSound(snd: snd, priority: 1, volume: volume, global: SoundCues.globalVolume(FerazelPrefs()))
    }

    /// Every (tick, op) of a timeline, in order: `.draw(op)`, `.play(cue)`, `.stop(snd)`.
    private enum Item: Equatable {
        case draw(DrawOp)
        case play(SoundCue)
        case stop(Int16)
    }

    private func items(_ t: FrontTimeline) -> [(at: Int, item: Item)] {
        var out: [(Int, Item)] = []
        for e in t.events {
            // Plays and stops interleave by `soundStopAt`; draws first within an event (no event mixes them here
            // except where the order is asserted through separate events).
            for d in e.output.draws { out.append((e.at, .draw(d))) }
            var stops = Array(zip(e.output.soundStopAt, e.output.soundStops))
            for (i, s) in e.output.sounds.enumerated() {
                while let f = stops.first, f.0 <= i { out.append((e.at, .stop(f.1))); stops.removeFirst() }
                out.append((e.at, .play(s)))
            }
            for f in stops { out.append((e.at, .stop(f.1))) }
        }
        return out
    }

    private func barRows(_ t: FrontTimeline) -> [(at: Int, row: Int, dest: Rect16)] {
        items(t).compactMap { at, item in
            guard case .draw(.copyPicture(141, .frontEnd, let s, let d, 200, false)) = item else { return nil }
            XCTAssertEqual([s.left, s.right, s.bottom - s.top], [0, 52, 14])
            return (at, Int(s.top) / 14, d)
        }
    }

    private func plays(_ t: FrontTimeline) -> [(at: Int, cue: SoundCue)] {
        items(t).compactMap { at, item in
            if case .play(let c) = item { return (at, c) } else { return nil }
        }
    }

    func testCalcPercentTable() {
        let cases: [(Int16, Int16, Int)] = [(0, 0, 100), (0, 5, 0), (1, 100, 2), (7, 7, 100), (9, 8, 100), (1, 3, 33)]
        for (a, b, pct) in cases {
            XCTAssertEqual(StageScreens.calcPercent(a, b), pct, "CalcPercent(\(a), \(b))")
        }
    }

    func testFillPercentTimeline() {
        func fill(_ pct: Int, sounds s: StageSounds? = nil) -> FrontTimeline {
            StageScreens.fillPercent(h: 0xfd, v: 0x32, percent: pct, offsetH: 0xa0, offsetV: 0x96,
                                     sounds: s ?? sounds())
        }
        // pct 0: no 803; the final row 0 with 804; 7 + 4 ticks; 800; its 30 ticks; 22.
        let p0 = fill(0)
        XCTAssertEqual(barRows(p0).map(\.row), [0])
        XCTAssertEqual(barRows(p0)[0].dest, Rect16(top: 200, left: 413, bottom: 214, right: 465))
        XCTAssertEqual(plays(p0).map(\.at), [0, 11])
        XCTAssertEqual(plays(p0).map(\.cue), [cue(804, 0x100), cue(800, 0x100)])
        XCTAssertEqual(p0.duration, 11 + 30 + 22)

        // pct 11: n2 10 → rows 0…4 at 2 ticks, 803 restarted when its voice ends (5 ticks), stopped; row 5 + 804; 800.
        let p11 = fill(11)
        XCTAssertEqual(barRows(p11).map(\.row), [0, 1, 2, 3, 4, 5])
        XCTAssertEqual(barRows(p11).map(\.at), [0, 2, 4, 6, 8, 10])
        XCTAssertEqual(plays(p11).map(\.at), [0, 5, 10, 21])
        XCTAssertEqual(plays(p11).map(\.cue), [cue(803, 0xab), cue(803, 0xab), cue(804, 0x100), cue(800, 0x100)])
        XCTAssertTrue(items(p11).contains { $0.at == 10 && $0.item == .stop(803) })
        XCTAssertEqual(p11.duration, 21 + 30 + 22)

        // pct 46: 23 rows at 1 tick; 801 at 0xab; 12.
        let p46 = fill(46)
        XCTAssertEqual(barRows(p46).map(\.row), Array(0...23))
        XCTAssertEqual(barRows(p46).map(\.at), Array(0...23))
        XCTAssertEqual(plays(p46).map(\.at), [0, 5, 10, 15, 20, 23, 34])
        XCTAssertEqual(plays(p46).last?.cue, cue(801, 0xab))
        XCTAssertEqual(p46.duration, 34 + 40 + 12)
        // pct 45: `pct > 45` is false → still 2 ticks per row (n2 44 → rows 0…21, then row 22 + 804).
        let p45 = fill(45)
        XCTAssertEqual(barRows(p45).map(\.row), Array(0...22))
        XCTAssertEqual(barRows(p45).map(\.at), Array(stride(from: 0, through: 44, by: 2)))
        // Sound off: `STPlayRegSound` returns −1, no voice is ever playing, so no waits on the sounds.
        let quiet = fill(46, sounds: sounds(on: false))
        XCTAssertTrue(plays(quiet).isEmpty)
        XCTAssertEqual(quiet.duration, 23 + 4 + 12)

        // pct 100: 50 rows, row 50 last, 802, 12.
        let p100 = fill(100)
        XCTAssertEqual(barRows(p100).map(\.row), Array(0...50))
        XCTAssertEqual(barRows(p100).last?.dest, Rect16(top: 200, left: 413, bottom: 214, right: 465))
        XCTAssertEqual(plays(p100).last.map { [$0.at] }, [61])
        XCTAssertEqual(plays(p100).last?.cue, cue(802, 0x100))
        XCTAssertEqual(p100.duration, 61 + 50 + 12)
    }

    func testStageCompleteTimeline() {
        var g = GameGlobals()
        let level = 1
        g.achieved[0][level] = 3; g.totals[0][level] = 6        // enemies 50 %
        g.achieved[1][level] = 0; g.totals[1][level] = 0        // Xichrons 100 %
        g.achieved[2][level] = 0; g.totals[2][level] = 4        // secrets 0 %
        let t = StageScreens.stageCompleteEffect(globals: g, level: level, sounds: sounds())
        let all = items(t)
        XCTAssertEqual(all.first?.at, 0)
        XCTAssertEqual(all.first?.item, .play(cue(805, 0x100)))
        let panel = all.compactMap { at, item -> (Int, Rect16, Rect16)? in
            guard case .draw(.copyPicture(140, .frontEnd, let s, let d, 200, false)) = item else { return nil }
            return (at, s, d)
        }
        XCTAssertEqual(panel.count, 27)
        XCTAssertEqual(panel.map(\.0), Array(0..<27))
        for (i, p) in panel.enumerated() {
            let s = Int16(52 - 2 * i)
            XCTAssertEqual(p.1, Rect16(top: 0, left: 0, bottom: 110, right: 320))
            XCTAssertEqual(p.2, Rect16(top: 150 + s, left: 160, bottom: 260 - s, right: 480))
        }
        // 27 + 15: the bars, in order at y 200 / 218 / 236 (50 % → 88 ticks, 100 % → 123, 0 % → 63), then 40.
        let rows = barRows(t)
        XCTAssertEqual(rows.first?.at, 42)
        let tops = rows.map(\.dest.top)
        XCTAssertEqual(Array(Set(tops)).sorted(), [200, 218, 236])
        XCTAssertEqual(tops, tops.sorted())
        XCTAssertEqual(rows.filter { $0.dest.top == 200 }.count, 26)
        XCTAssertEqual(rows.filter { $0.dest.top == 218 }.count, 51)
        XCTAssertEqual(rows.filter { $0.dest.top == 236 }.count, 1)
        XCTAssertEqual(rows.first { $0.dest.top == 218 }?.at, 42 + 88)
        XCTAssertEqual(rows.first { $0.dest.top == 236 }?.at, 42 + 88 + 123)
        XCTAssertEqual(rows.allSatisfy { $0.dest.left == 413 && $0.dest.right == 465 }, true)
        XCTAssertEqual(t.duration, 42 + 88 + 123 + 63 + 40)
    }

    func testChapterScreenLevel1() throws {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let bar = StatusBarState(score: 5, levelName: "x")
        func run(keyAt: Int?, keyCode: Int? = 0x31, capsLock: Bool = false) -> [(Int, FrontOutput)] {
            var fade = ScreenFade()
            fade.faded = true                                   // the level entry's fade-out came first (L1)
            guard var m = ChapterScreenRun(chapter: 1, levelClut: 201, statusBar: bar, resources: r) else {
                XCTFail("clut 281 missing"); return []
            }
            var out: [(Int, FrontOutput)] = []
            let start: UInt32 = 1000
            var t = 0
            while !m.isDone, t < 3000 {
                var input = FrontInput()
                if let k = keyAt, t >= k {
                    if let c = keyCode { input.keys = KeyState(pressed: [c]) }
                    input.capsLock = capsLock
                }
                let o = m.tick(now: start + UInt32(t), input: input, fade: &fade)
                out.append((t, o))
                t += 1
            }
            XCTAssertTrue(fade.faded)
            return out
        }
        func gammaCounts(_ out: [(Int, FrontOutput)]) -> (fadeIn: Int, fadeOut: Int) {
            var fin = 0, fout = 0
            for (_, o) in out {
                for d in o.draws {
                    if case .screenGamma(.timedFadeToColor) = d { fin += 1 }
                    if case .screenGamma(.tint(3, _)) = d { fout += 1 }
                }
            }
            return (fin, fout)
        }

        let keyed = run(keyAt: 300)
        let first = keyed[0].1.draws
        XCTAssertEqual(Array(first.prefix(2)), [
            .setScreenClut(id: 281),
            .copyPicture(id: 4610, chain: .level, source: Rect16(top: 0, left: 0, bottom: 480, right: 640),
                         dest: Rect16(top: 0, left: 0, bottom: 480, right: 640), forceClut: nil, transparent: false),
        ])
        XCTAssertEqual(gammaCounts(keyed).fadeIn, 109)
        XCTAssertEqual(gammaCounts(keyed).fadeOut, 160)
        // The fade-in ends at 109; the waits poll from 109; the key on tick 300 finishes that tick (301), then the
        // fade-out's 160 ticks, then the level clut, PICT 129 and the status bar on 461.
        let tints = keyed.filter { $0.1.draws.contains { if case .screenGamma(.tint) = $0 { return true }; return false } }
        XCTAssertEqual(tints.first?.0, 301)
        XCTAssertEqual(tints.last?.0, 460)
        XCTAssertEqual(keyed.last?.0, 461)
        XCTAssertEqual(keyed.last?.1.draws, [.setScreenClut(id: 201), .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0),
                                            .statusBar(bar)])

        // Untouched: 1200 one-tick waits (109 … 1308), fade-out 1309 … 1468, restore on 1469.
        let idle = run(keyAt: nil)
        XCTAssertEqual(idle.filter { $0.1.requests.contains(.hideCursor) }.count, 1200)
        XCTAssertEqual(idle.last?.0, 1469)
        // A key held on entry: the first wait (109) sees it.
        XCTAssertEqual(run(keyAt: 0).last?.0, 110 + 160)
        // `.IsAnyKeyDown` (M l. 31579–31595) scans key codes 1…127 only: key code 0 (A) alone never ends the card.
        XCTAssertEqual(run(keyAt: 0, keyCode: 0).last?.0, 1469)
        // `GetKeys` reports a locked Caps Lock (0x39) as down, so a locked Caps Lock ends it at the first wait.
        XCTAssertEqual(run(keyAt: 0, keyCode: nil, capsLock: true).last?.0, 110 + 160)

        // No clut 280 + n → nothing at all.
        XCTAssertNil(ChapterScreenRun(chapter: 90, levelClut: 201, statusBar: bar, resources: r))
    }

    func testPopupAndLoadBar() {
        let t = StageScreens.popupStageLoad()
        XCTAssertEqual(t.duration, 16)
        let copies = items(t).compactMap { at, item -> (Int, Rect16, Rect16)? in
            guard case .draw(.copyPicture(142, .frontEnd, let s, let d, 199, false)) = item else { return nil }
            return (at, s, d)
        }
        XCTAssertEqual(copies.map(\.0), Array(0..<16))
        XCTAssertEqual(copies.first?.2, Rect16(top: 203, left: 160, bottom: 207, right: 480))
        XCTAssertEqual(copies.last?.2, Rect16(top: 173, left: 160, bottom: 237, right: 480))
        for (i, c) in copies.enumerated() {
            let s = Int16(30 - 2 * i)
            XCTAssertEqual(c.1, Rect16(top: 0, left: 0, bottom: 64, right: 320))
            XCTAssertEqual(c.2, Rect16(top: 173 + s, left: 160, bottom: 237 - s, right: 480))
        }

        XCTAssertEqual([25, 50, 100].map { StageScreens.stageLoadWidth($0, of: 100) }, [73, 146, 293])
        XCTAssertEqual(StageScreens.stageLoadWidth(150, of: 100), 293)
        XCTAssertEqual(StageScreens.stageLoadWidth(1, of: 0), 0)
        let grey = RGB16(red: 0x59d8, green: 0x59d8, blue: 0x59d8)
        XCTAssertEqual(StageScreens.updateStageLoad(50, of: 100),
                       FrontOutput(draws: [.fillRect(left: 172, top: 213, right: 318, bottom: 224, rgb: grey)],
                                   present: true))
    }
}

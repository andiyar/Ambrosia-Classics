import XCTest
@testable import FerazelCore

/// D1 (docs/plans/2026-10-14-ferazel-phase3.md): the death screen — `.AskToContinue @ 10007190` (M l. 3718–3858),
/// `.TrackClickOnCommandButtonDeath @ 10006970` (M l. 3440–3500), `.WandGlow @ 10006b6c` (M l. 3503–3540),
/// `.TurnGray @ 10006ca4` (M l. 3543–3714). Bank: save-continue §5 (BC10). Rects are built by field name
/// (`Rect16` = QuickDraw {top, left, bottom, right}). A missing data file is a FAILURE, never a skip.
final class DeathScreenTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    private static let continueRect = Rect16(top: 390, left: 252, bottom: 412, right: 390)
    private static let abortRect = Rect16(top: 413, left: 262, bottom: 434, right: 379)
    private static let glowRect = Rect16(top: 286, left: 138, bottom: 368, right: 220)

    private func screen(saved: Bool = true, prefs: FerazelPrefs = FerazelPrefs()) throws -> DeathScreen {
        try DeathScreen(saved: saved, prefs: prefs, resources: try resources(), scrollH: 0x300, scrollV: 0x200)
    }

    /// Ticks `screen` from `start` until done (or `limit` ticks), `input(t)` the poll at tick t; every tick's output.
    private func run(_ s: inout DeathScreen, fade: inout ScreenFade, start: UInt32 = 1000, limit: Int = 600,
                     input: (Int) -> FrontInput = { _ in FrontInput() }) -> [(t: Int, out: FrontOutput)] {
        var outs: [(Int, FrontOutput)] = []
        for t in 0..<limit {
            outs.append((t, s.tick(now: start &+ UInt32(t), input: input(t), fade: &fade)))
            if s.isDone { break }
        }
        return outs
    }

    private func cue(_ snd: Int16, _ volume: Int16) -> SoundCue {
        SoundCues.regSound(snd: snd, priority: 10, volume: volume, global: SoundCues.globalVolume(FerazelPrefs()))
    }

    private func face(_ id: Int16, _ dest: Rect16) -> DrawOp {
        .copyPicture(id: id, chain: .frontEnd, source: Rect16(top: 0, left: 0, bottom: dest.bottom - dest.top,
                                                              right: dest.right - dest.left),
                     dest: dest, forceClut: nil, transparent: false)
    }

    /// The (tick, face op) pairs of the button faces (PICTs 4970/4971/4980/4981).
    private func faces(_ outs: [(t: Int, out: FrontOutput)]) -> [(Int, Int16)] {
        outs.flatMap { t, o in o.draws.compactMap { d -> (Int, Int16)? in
            if case .copyPicture(let id, _, _, _, _, _) = d, (4970...4981).contains(id) { return (t, id) }
            return nil
        } }
    }

    private func sounds(_ outs: [(t: Int, out: FrontOutput)]) -> [(Int, Int16)] {
        outs.flatMap { t, o in o.sounds.map { (t, $0.snd) } }
    }

    private func keys(_ codes: [Int]) -> FrontInput { FrontInput(keys: KeyState(pressed: codes)) }

    private static let loopStart = 21   // GammaFadeIn(6) from faded: 21 one-tick steps, the loop's first pass at 21

    func testNoSaveNoDeathScreen() throws {
        var s = try screen(saved: false)
        var fade = ScreenFade()
        fade.faded = true
        let out = s.tick(now: 5, input: keys([0x24]), fade: &fade)
        XCTAssertEqual(out, FrontOutput(), "fe00 == 0: no drawing, no sound, no cursor")
        XCTAssertTrue(s.isDone)
        XCTAssertEqual(s.continues, false)
        XCTAssertNil(s.chosen)
        XCTAssertTrue(fade.faded, "no GammaFadeIn")
    }

    func testDeathButtonsKeysAndMouse() throws {
        // The entry: clut 132, PICT 138 full screen, GammaFadeIn(6), the cursor shown.
        var s = try screen()
        var fade = ScreenFade()
        fade.faded = true
        var outs = run(&s, fade: &fade, limit: 40)
        XCTAssertEqual(Array(outs[0].out.draws.prefix(2)), [.setScreenClut(id: 132),
                                                            .drawPicture(id: 138, chain: .frontEnd, h: 0, v: 0)])
        XCTAssertEqual(outs[0].out.draws[2], .screenGamma(.fadeToColor(percent: 0, rgb: nil)))
        XCTAssertTrue(outs[Self.loopStart].out.requests.contains(.showCursor))
        XCTAssertFalse(fade.faded)
        XCTAssertFalse(s.isDone)
        XCTAssertTrue(faces(outs).isEmpty)

        // Return (and Enter) → button 1: pressed face + 4803 (10, 0x55), Delay(10), idle face + 4804.
        for key in [0x24, 0x4c] {
            var s = try screen()
            var fade = ScreenFade()
            fade.faded = true
            outs = run(&s, fade: &fade) { $0 == 30 ? self.keys([key]) : FrontInput() }
            XCTAssertEqual(faces(outs).map { $0.0 }, [30, 40])
            XCTAssertEqual(faces(outs).map { $0.1 }, [4980, 4970])
            XCTAssertEqual(outs[30].out.draws, [face(4980, Self.continueRect)])
            XCTAssertEqual(outs[30].out.sounds, [cue(4803, 0x55)])
            XCTAssertEqual(outs[40].out.draws.first, face(4970, Self.continueRect))
            XCTAssertEqual(outs[40].out.sounds.first, cue(4804, 0x55))
            XCTAssertEqual(s.chosen, 1)
            XCTAssertEqual(s.continues, true)
        }

        // Esc → button 2; ⌘Q → button 2; ⌘ alone and Q alone → nothing.
        for combo in [[0x35], [0x37, 0x0c]] {
            var s = try screen()
            var fade = ScreenFade()
            outs = run(&s, fade: &fade) { t in
                t == 3 ? self.keys([0x37]) : t == 4 ? self.keys([0x0c]) : t == 25 ? self.keys(combo) : FrontInput()
            }
            XCTAssertEqual(faces(outs).map { $0.0 }, [25, 35], "not faded: the loop starts at once; \(combo)")
            XCTAssertEqual(faces(outs).map { $0.1 }, [4981, 4971])
            XCTAssertEqual(outs[25].out.draws, [face(4981, Self.abortRect)])
            XCTAssertEqual(s.chosen, 2)
            XCTAssertEqual(s.continues, false)
        }

        // The mouse: the hit test is `PointInRect(252, 390, 389, 411)` (l, t, r, b) — 1 px smaller than the tracked
        // rect (252, 390, 390, 412). A press at h 389 is inside the tracked rect but misses the hit rect: nothing.
        func click(_ at: (h: Int, v: Int), release: (h: Int, v: Int)? = nil) throws
            -> (DeathScreen, [(t: Int, out: FrontOutput)]) {
            var s = try screen()
            var fade = ScreenFade()
            let outs = run(&s, fade: &fade, limit: 60) { t in
                switch t {
                case 10...12: return FrontInput(mouse: at, button: true)
                case 13: return FrontInput(mouse: release ?? at, button: true)
                case 14: return FrontInput(mouse: release ?? at, button: false)
                default: return FrontInput(mouse: (0, 0))
                }
            }
            return (s, outs)
        }
        var (c, o) = try click((389, 400))
        XCTAssertTrue(faces(o).isEmpty, "h 389 is outside the hit rect")
        XCTAssertFalse(c.isDone)
        (c, o) = try click((300, 411))
        XCTAssertTrue(faces(o).isEmpty, "v 411 is outside the hit rect")
        // Hovering without the button does nothing.
        do {
            var s = try screen()
            var fade = ScreenFade()
            let outs = run(&s, fade: &fade, limit: 30) { _ in FrontInput(mouse: (300, 400)) }
            XCTAssertTrue(faces(outs).isEmpty)
            XCTAssertFalse(s.isDone)
        }
        // A click at the hit rect's last pixel (388, 410): pressed at 10, released at 14 → idle face, button 1.
        (c, o) = try click((388, 410))
        XCTAssertEqual(faces(o).map { $0.0 }, [10, 14])
        XCTAssertEqual(faces(o).map { $0.1 }, [4980, 4970])
        XCTAssertEqual(sounds(o).prefix(2).map { $0.1 }, [4803, 4804])
        XCTAssertEqual(c.chosen, 1)
        // Abort by mouse at (262, 413), the hit rect's first pixel.
        (c, o) = try click((262, 413))
        XCTAssertEqual(faces(o).map { $0.1 }, [4981, 4971])
        XCTAssertEqual(c.chosen, 2)
        // Slide out before release: 4804 + idle face on the crossing, no choice.
        (c, o) = try click((300, 400), release: (300, 300))
        XCTAssertEqual(faces(o).map { $0.0 }, [10, 13])
        XCTAssertEqual(faces(o).map { $0.1 }, [4980, 4970])
        XCTAssertEqual(sounds(o).map { $0.1 }, [4803, 4804])
        XCTAssertNil(c.chosen)
        XCTAssertFalse(c.isDone)
    }

    func testWandGlowTimeline() throws {
        var s = try screen()
        var fade = ScreenFade()
        let outs = run(&s, fade: &fade) { $0 == 5 ? self.keys([0x24]) : FrontInput() }
        // The loop ends on the tick the idle face draws (5 + 10); `.WandGlow` waits 6 ticks, plays 606 (10, 0x100),
        // then 11 frames of 5 ticks.
        let begin = 15
        let glow = outs.flatMap { t, o in o.draws.compactMap { d -> (Int, Int16, Rect16)? in
            if case .copyPicture(let id, .frontEnd, _, let dest, nil, false) = d, (172...177).contains(id) {
                return (t, id, dest)
            }
            return nil
        } }
        XCTAssertEqual(glow.map { $0.1 }, [172, 173, 174, 175, 176, 177, 176, 175, 174, 173, 172])
        XCTAssertEqual(glow.map { $0.0 }, (0..<11).map { begin + 6 + 5 * $0 })
        XCTAssertTrue(glow.allSatisfy { $0.2 == Self.glowRect })
        XCTAssertEqual(outs[begin + 6].out.sounds, [cue(606, 0x100)])
        XCTAssertEqual(sounds(outs).map { $0.1 }, [4803, 4804, 606])
        XCTAssertEqual(outs.last?.t, begin + 6 + 55, "6 + 55 ticks")
        XCTAssertTrue(s.isDone)
        XCTAssertEqual(s.continues, true)
        // Sound off: no cue at all, same timeline.
        var off = FerazelPrefs()
        off.soundOn = 0
        var q = try screen(prefs: off)
        var fade2 = ScreenFade()
        let quiet = run(&q, fade: &fade2) { $0 == 5 ? self.keys([0x24]) : FrontInput() }
        XCTAssertTrue(sounds(quiet).isEmpty)
        XCTAssertEqual(quiet.last?.t, begin + 6 + 55)
    }

    func testTurnGrayClut() throws {
        let clut = try ColorLUT.load(id: 132, from: try resources(), chain: .frontEnd)
        // Two clut-132 entries: 1 = (63479, 63479, 61423), 100 = (21074, 14649, 2056).
        XCTAssertEqual(clut.entries[1].rgb, [63479, 63479, 61423])
        XCTAssertEqual(clut.entries[100].rgb, [21074, 14649, 2056])
        let black = RGB16(0, 0, 0)
        let f0 = DeathScreen.turnGray(clut, frame: 0, entry255: black)
        XCTAssertEqual(f0.count, 256)
        XCTAssertEqual(f0[1], RGB16(63479, 63479, 61423), "f 0: unchanged")
        XCTAssertEqual(f0[100], RGB16(21074, 14649, 2056))
        // f 75: k = 0 → every channel the gray (r + g + b) >> 2.
        let f75 = DeathScreen.turnGray(clut, frame: 75, entry255: black)
        XCTAssertEqual(f75[1], RGB16(47095, 47095, 47095))     // 188,381 >> 2
        XCTAssertEqual(f75[100], RGB16(9444, 9444, 9444))      // 37,779 >> 2
        // f 30: k = (float)(1 − (float)0.4) = 0.6f; red 1 = trunc((float)(63479 · 0.6f) + 47095 · (1 − 0.6f)) = 56925.
        XCTAssertEqual(DeathScreen.turnGray(clut, frame: 30, entry255: black)[1].red, 56925)
        // f 113: gray scaled by (float)(37 / 75) — trunc(47095f · 0.49333334f) = 23233.
        XCTAssertEqual(DeathScreen.turnGray(clut, frame: 113, entry255: black)[1], RGB16(23233, 23233, 23233))
        // f 150: black. Entry 255 is never computed: it comes from the level working copy (`SetEntries(0, 0xff)`).
        let f150 = DeathScreen.turnGray(clut, frame: 150, entry255: RGB16(1, 2, 3))
        XCTAssertEqual(f150[1], black)
        XCTAssertEqual(f150[100], black)
        XCTAssertEqual(f150[255], RGB16(1, 2, 3))

        // The run: Esc → `.TurnGray` on the tick the idle face draws: snd 435 via `STPlay3DSoundPitched(10, 0x100,
        // view centre, 35000)`, then 151 `.clut` ops one tick apart; the restore writes only the level working copy —
        // no screen op follows.
        var s = try screen()
        var fade = ScreenFade()
        let outs = run(&s, fade: &fade) { $0 == 5 ? self.keys([0x35]) : FrontInput() }
        let begin = 15
        let ops = outs.flatMap { t, o in o.draws.compactMap { d -> (Int, [RGB16])? in
            if case .screenGamma(.clut(let e)) = d { return (t, e) } else { return nil }
        } }
        XCTAssertEqual(ops.count, 151)
        XCTAssertEqual(ops.map { $0.0 }, (0...150).map { begin + $0 })
        XCTAssertEqual(ops.first?.1, f0)
        XCTAssertEqual(ops.last?.1, DeathScreen.turnGray(clut, frame: 150, entry255: black))
        let pitched = SoundCues.play3DPitched(snd: 435, priority: 10, volume: 0x100,
                                              position: SpriteSlot.Point(x: 0x300 + 0x140, y: 0x200 + 0xc0),
                                              rate: 35000, scrollH: 0x300, scrollV: 0x200,
                                              global: SoundCues.globalVolume(FerazelPrefs()))
        XCTAssertNotNil(pitched)
        XCTAssertEqual(outs[begin].out.sounds, [cue(4804, 0x55), pitched!], "the idle face's 4804, then 435")
        XCTAssertEqual(outs.last?.t, begin + 151)
        XCTAssertTrue(outs.last!.out.draws.isEmpty, "the restore is not a screen op")
        XCTAssertTrue(s.isDone)
        XCTAssertEqual(s.continues, false)
        XCTAssertEqual(s.chosen, 2)
    }
}

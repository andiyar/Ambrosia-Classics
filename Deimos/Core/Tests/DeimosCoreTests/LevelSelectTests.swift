import XCTest
@testable import DeimosCore
import HectorResources

/// Phase 4 S3b LS — the level select `FUN_1002e310` on the frame controller (grounding A §3, §5.3, §6, §10;
/// `osx-build.md` D10). One pass is one frame; the clock moves two ticks a pass (the frame controller's 30 Hz), so a
/// count kept in ticks instead of frames would be off by two. Every loop names its bound and fails on it (G11).
final class LevelSelectTests: XCTestCase {
    private func assets() throws -> DeimosAssets { try TestAssets.loaded.get() }

    private struct Run {
        var screen = LevelSelect()
        var state: FrontEndState
        var t: UInt32 = 1_000
    }

    /// Default P1 keys (fresh prefs): ← 0x7B, → 0x7C, Space (select) 0x31; Esc 0x35.
    private static let left: UInt16 = 0x7b, right: UInt16 = 0x7c, space: UInt16 = 0x31, esc: UInt16 = 0x35
    private static func held(_ k: UInt16...) -> HeldKeys { HeldKeys(held: Set(k)) }

    private func entered(highest: Int32 = 1, escHold: UInt8? = nil) throws -> (Run, ScreenStep<Int?>) {
        var prefs = DeimosPrefs.fresh
        prefs.intPrefs[3] = highest
        if let escHold { prefs.bytePrefs[8] = escHold }
        var run = Run(state: try FrontEndState(assets: try assets(), prefs: prefs))
        let s = step(&run)
        return (run, s)
    }

    @discardableResult
    private func step(_ run: inout Run, _ keys: HeldKeys = HeldKeys()) -> ScreenStep<Int?> {
        let s = run.screen.pass(keys: keys, ticks: run.t, returned: nil, state: &run.state)
        run.t &+= 2                                                   // a 2-tick frame
        return s
    }

    private func cue(_ a: DeimosAssets, _ gaso: Int, _ priority: Int32 = 0x32, multiple: Bool = true) -> SoundCue {
        SoundPlay.perm(a.sounds[gaso], priority: priority, volume: 100, allowMultiple: multiple)
    }

    /// The queued button sprites the pass drew (layer 15, faces gasp 6 / 7).
    private func buttons(_ ops: [RenderOp], _ a: DeimosAssets) -> [DrawCommand] {
        ops.compactMap { if case let .draw(c) = $0, c.layer == 15, c.face == a.sprites[6] || c.face == a.sprites[7] {
            return c } else { return nil } }
    }

    private func washes(_ ops: [RenderOp]) -> [DrawCommand] {
        ops.compactMap { if case let .draw(c) = $0, c.face == FourCC("COST")!, c.drawNow,
                            c.clip == DrawCommand.template.clip { return c } else { return nil } }
    }

    private func scaledCopies(_ ops: [RenderOp]) -> [MacRect] {
        ops.compactMap { if case let .scaledCopy(_, _, dst, _) = $0 { return dst } else { return nil } }
    }

    // MARK: -

    func testLevelSelectInitial() throws {
        let a = try assets()
        let (run, entry) = try entered()
        XCTAssertNil(entry.finished)
        let ops = entry.output.ops
        // Previews 12 | 1 | 2 at x 55 / 246 / 437, y 76, each its 146×306 picture.
        XCTAssertEqual(run.screen.previews.map(\.sector), [12, 1, 2])
        XCTAssertEqual(run.screen.previews.map(\.x), [55, 246, 437])
        XCTAssertEqual(run.screen.previews.map(\.y), [76, 76, 76])
        for p in run.screen.previews {
            XCTAssertEqual(p.rect, MacRect(top: 76, left: p.x, bottom: 382, right: p.x + 146))
            XCTAssertTrue(ops.contains(.loadImage(image: p.image, into: .back, dst: p.rect)), "preview \(p.sector)")
        }
        XCTAssertEqual(run.screen.previews[1].image, a.definitions.levels.first { $0.id == a.levelOrder.level(sector: 1) }?.previewImage)
        // The set-up: lese into the back and save buffers, the picture copied back → save.
        XCTAssertEqual(Array(ops.prefix(5)), [.clearLayers, .fill(.back, colour: 0),
                                              .loadImage(image: FourCC("lese")!, into: .back,
                                                         dst: MacRect(top: 0, left: 0, bottom: 480, right: 640)),
                                              .loadTerrain(image: FourCC("lese")!),
                                              .copy(from: .back, to: .terrain, src: nil, dst: nil, interlaced: false)])
        // Buttons: `<` frame 12 at (128, 228), START 10 at (320, 228), `>` 13 at (511, 228); unhovered gasp 6, 1.0.
        let b = buttons(ops, a)
        XCTAssertEqual(b.map(\.frame), [12, 10, 13])
        XCTAssertEqual(b.map(\.x), [128, 320, 511])
        XCTAssertEqual(b.map(\.y), [228, 228, 228])
        XCTAssertTrue(b.allSatisfy { $0.face == a.sprites[6] && $0.scale == 1 && !$0.drawNow
                                     && $0.clip == MacRect(top: 0, left: 0, bottom: 480, right: 640) })
        // The name in `lsde` (25) and the number "01" in `lsnu` (22), both queued.
        let t = run.screen.textRequests(assets: a)
        XCTAssertEqual(MacRoman.decode(t[0].text), "Mariner Valley")
        XCTAssertEqual(t[0].format, a.formats[25])
        XCTAssertEqual(MacRoman.decode(t[1].text), "01")
        XCTAssertEqual(t[1].format, a.formats[22])
        XCTAssertFalse(t[0].drawNow || t[1].drawNow)
        // The grid: vigr tiles queued on layer 15, clipped to each preview rect.
        let grid = ops.compactMap { if case let .draw(c) = $0, c.face == a.sprites[0] { return c } else { return nil } }
        XCTAssertFalse(grid.isEmpty)
        XCTAssertEqual(Set(grid.map(\.clip)), Set(run.screen.previews.map(\.rect)))
        XCTAssertTrue(grid.allSatisfy { $0.layer == 15 && !$0.drawNow })
        // The end frame with no present, then the fade in (9 steps, full screen); ShowCursor.
        XCTAssertFalse(ops.contains(.present(.fullScreen)))
        XCTAssertEqual(ops.last, .fade(.fromBlack, .fullScreen))
        XCTAssertEqual(run.state.prefs.bytePrefs[10], 1, "fresh prefs: the frame limiter on")
        XCTAssertEqual(Array(ops.suffix(5)), [.flushLayers(0...1), .flushLayers(2...5), .flushLayers(6...15), .limit,
                                              .fade(.fromBlack, .fullScreen)])
        XCTAssertEqual(entry.output.requests, [.showCursor])
        XCTAssertEqual(run.screen.controller.framesPresented, 1, "the end frame counted the set-up frame")
    }

    func testLevelSelectUnlock() throws {
        let a = try assets()
        // Fresh prefs (pref 3 = 1): sector 1 START, the rest NO ACCESS (frame 11) in red.
        var (run, _) = try entered(highest: 1)
        XCTAssertEqual(run.screen.previews.map(\.reachable), [false, true, false])
        var s = step(&run, Self.held(Self.right))
        XCTAssertEqual(run.screen.previews[1].sector, 2)
        XCTAssertFalse(run.screen.previews[1].reachable)
        // The START frame is chosen before the move is read (`1002eaa0..1002eacc` reads the middle first), so the
        // frame of the move still shows START; NO ACCESS from the next frame.
        XCTAssertEqual(buttons(s.output.ops, a)[1].frame, 10)
        s = step(&run)
        XCTAssertEqual(buttons(s.output.ops, a)[1].frame, 11, "NO ACCESS")
        let t = run.screen.textRequests(assets: a)
        XCTAssertEqual(t[0].format, a.formats[24])
        XCTAssertEqual(t[1].format, a.formats[23])
        // pref 3 = 12: every sector START. Bound: 12 moves (24 passes).
        (run, _) = try entered(highest: 12)
        for n in 1...12 {
            XCTAssertTrue(run.screen.previews.allSatisfy(\.reachable), "sector \(run.screen.previews[1].sector)")
            s = step(&run, Self.held(Self.right))
            XCTAssertEqual(buttons(s.output.ops, a)[1].frame, 10, "START at move \(n)")
            step(&run)
        }
        XCTAssertEqual(run.screen.previews[1].sector, 1, "12 moves come back round")
    }

    func testLevelSelectMoveEdgeAndWrap() throws {
        let a = try assets()
        var (run, _) = try entered(highest: 1)
        // Held → one move per press, with `lsch`; 1 → 2. Bound: 30 frames.
        var moves = 0
        for f in 0..<30 {
            let s = step(&run, Self.held(Self.right))
            if s.output.sounds.contains(cue(a, 13)) { moves += 1 }
            if f == 0 { XCTAssertEqual(s.output.sounds, [cue(a, 13)]) }
        }
        XCTAssertEqual(moves, 1)
        XCTAssertEqual(run.screen.index, 1)
        // A refused accept puts the message up; the next move clears it.
        step(&run, Self.held(Self.space))
        XCTAssertTrue(run.screen.message.active)
        step(&run)
        let back = step(&run, Self.held(Self.left))
        XCTAssertFalse(run.screen.message.active)
        XCTAssertEqual(back.output.sounds, [cue(a, 13)])
        XCTAssertEqual(run.screen.previews[1].sector, 1)
        // 1 ← wraps to 12; → wraps back to 1.
        step(&run)
        step(&run, Self.held(Self.left))
        XCTAssertEqual(run.screen.previews.map(\.sector), [11, 12, 1])
        step(&run)
        step(&run, Self.held(Self.right))
        XCTAssertEqual(run.screen.previews.map(\.sector), [12, 1, 2])
        // A click on the left preview moves too.
        step(&run)
        let click = step(&run, HeldKeys(mouse: MousePoint(h: 100, v: 200), mouseButton: true))
        XCTAssertEqual(run.screen.previews[1].sector, 12)
        XCTAssertEqual(click.output.sounds, [cue(a, 11, 0x4b, multiple: false), cue(a, 13)], "mbro on entry, lsch")
    }

    func testAcceptFlash() throws {
        let a = try assets()
        var (run, _) = try entered(highest: 1)
        XCTAssertEqual(a.floats[44], 0.18); XCTAssertEqual(a.floats[45], 2.0)
        let go = step(&run, Self.held(Self.space))
        XCTAssertEqual(go.output.sounds, [cue(a, 12)])
        XCTAssertEqual(run.screen.flash.mode, 1)
        XCTAssertEqual(run.screen.flash.alpha, a.formats[27].blendAmount)
        XCTAssertEqual(run.screen.flash.alpha, 16)
        XCTAssertEqual(run.screen.flash.colour, a.formats[27].coloriseColor)
        XCTAssertTrue(scaledCopies(go.output.ops).isEmpty, "the flash starts after this frame's step")
        // Steps 1–15 drawn; the scale as fadds / fsubs leave it; zoom + wash only on steps 1–11.
        var scale: Float = 1, growing = true
        let mid = run.screen.previews[1].rect
        for k in 1...20 {
            let held = k == 3 ? Self.held(Self.left) : HeldKeys()     // input is not read while the flash runs
            let s = step(&run, held)
            if k == 16 {
                XCTAssertEqual(s.finished, .some(1), "step 16: mode 0 → leave before drawing")
                XCTAssertEqual(s.output.ops, [.clearLayers, .fade(.toBlack, .fullScreen)])
                XCTAssertEqual(s.output.requests, [.hideCursor])
                return
            }
            XCTAssertNil(s.finished, "step \(k)")
            if growing { scale = scale + a.floats[44]; if scale >= 2 { scale = 2; growing = false } }
            else { scale = scale - a.floats[44]; if scale <= 1 { scale = 1 } }
            XCTAssertEqual(run.screen.flash.alpha, Int32(16 + k))
            XCTAssertEqual(run.screen.flash.scale.bitPattern, scale.bitPattern, "step \(k)")
            XCTAssertTrue(s.output.ops.contains(.present(.fullScreen)))
            XCTAssertEqual(run.screen.previews[1].sector, 1)
            let w = washes(s.output.ops), z = scaledCopies(s.output.ops)
            if k <= 11 {
                XCTAssertEqual(z.count, 1, "step \(k)")
                XCTAssertEqual(w.map(\.costRect), [mid])
                XCTAssertEqual(w.first?.alpha, UInt32(16 + k))
                XCTAssertEqual(w.first?.costColour, a.formats[27].coloriseColor)
            } else {
                XCTAssertTrue(z.isEmpty && w.isEmpty, "step \(k): scale 1.0 draws the plain preview")
            }
            if k == 6 {                                               // scale 2.0: 292×612 centred on (319, 229)
                XCTAssertEqual(z, [MacRect(top: -77, left: 173, bottom: 535, right: 465)])
            }
        }
        XCTFail("no exit within 20 frames")
    }

    func testFailFlash() throws {
        let a = try assets()
        var (run, _) = try entered(highest: 1)
        step(&run, Self.held(Self.right))                             // sector 2: not reached
        step(&run)
        let no = step(&run, Self.held(Self.space))
        XCTAssertEqual(no.output.sounds, [cue(a, 14)])
        let p = run.screen.message.time
        XCTAssertTrue(run.screen.message.active)
        XCTAssertEqual(run.screen.message.text, Array(a.gameStrings[4].prefix { $0 != 0 }))
        XCTAssertEqual(MacRoman.decode(run.screen.message.text), "Sector Not Reached")
        XCTAssertEqual(run.screen.message.colour, a.formats[26].coloriseColor)
        XCTAssertEqual(run.screen.message.blend, a.formats[26].blendAmount)
        XCTAssertEqual(run.screen.flash.mode, 2)
        XCTAssertEqual(run.screen.flash.colour, a.formats[28].coloriseColor)
        let msg = run.screen.textRequests(assets: a)[0]
        XCTAssertEqual(msg.format.coloriseDo, true)
        XCTAssertEqual(msg.text, run.screen.message.text)
        // Scale 1.25 … 2.0 (step 4) … 1.0 (step 8); mode 0 at step 16; the screen stays. Bound: 80 frames.
        let expected: [Float] = [1.25, 1.5, 1.75, 2.0, 1.75, 1.5, 1.25, 1.0]
        var off: Int32?
        for k in 1...80 {
            let s = step(&run)
            XCTAssertNil(s.finished)
            XCTAssertTrue(s.output.ops.contains(.present(.fullScreen)))
            if k <= 8 { XCTAssertEqual(run.screen.flash.scale, expected[k - 1], "step \(k)") }
            if k <= 7 { XCTAssertEqual(scaledCopies(s.output.ops).count, 1) }
            if k == 15 { XCTAssertEqual(run.screen.flash.mode, 2) }
            if k == 16 { XCTAssertEqual(run.screen.flash, LevelSelect.Flash()) }
            // Held 40 frames, then blend + 1 a frame to 32 (frames, not ticks).
            let now = run.screen.controller.framesPresented - 1       // the frame the fade just read
            if run.screen.message.active {
                XCTAssertEqual(run.screen.message.blend, max(0, now - (p + 40)))
            } else if off == nil {
                off = now
            }
        }
        XCTAssertEqual(off, p + 72, "40 frames held, then 32 fade steps")
        XCTAssertEqual(run.screen.message.blend, 32)
        XCTAssertEqual(MacRoman.decode(run.screen.textRequests(assets: a)[0].text), run.screen.previews[1].name)
        // A new press restarts it from step 0.
        step(&run, Self.held(Self.space))
        XCTAssertEqual(run.screen.flash.alpha, 16)
        XCTAssertTrue(run.screen.message.active)
    }

    func testLevelSelectEsc() throws {
        // pref 8 = 0: the next frame leaves with 'none', no HideCursor.
        var (run, _) = try entered(escHold: 0)
        let s = step(&run, Self.held(Self.esc))
        XCTAssertEqual(s.finished, .some(nil))
        XCTAssertEqual(s.output.ops, [.clearLayers, .fade(.toBlack, .fullScreen)])
        XCTAssertEqual(s.output.requests, [])
        // pref 8 = 1: the 16th held frame. Bound: 20 frames.
        (run, _) = try entered(escHold: 1)
        for f in 1...20 {
            let s = step(&run, Self.held(Self.esc))
            if f < 16 { XCTAssertNil(s.finished, "frame \(f)"); continue }
            XCTAssertEqual(f, 16)
            XCTAssertEqual(s.finished, .some(nil))
            return
        }
        XCTFail("Esc never left within 20 frames")
    }

    func testLevelSelectPause() throws {
        let a = try assets()
        var (run, _) = try entered()
        step(&run)
        let s = step(&run, HeldKeys(capsLock: true))
        XCTAssertNil(s.finished)
        // The notice "Press Caps Lock" was up in the frame presented before the wait.
        let notice = run.screen.game?.notice
        XCTAssertEqual(notice?.text, Array(a.gameStrings[0].prefix { $0 != 0 }.prefix(0x3f)))
        XCTAssertEqual(MacRoman.decode(notice?.text ?? []), "Press Caps Lock")
        let glyphs = notice?.drawCommands(text: run.state.text, formats: a.formats) ?? []
        XCTAssertFalse(glyphs.isEmpty)
        let draws = s.output.ops.compactMap { if case let .draw(c) = $0 { return c } else { return nil } }
        XCTAssertEqual(Array(draws.prefix(glyphs.count)), glyphs, "the notice is the frame's first draw (FUN_100184b0)")
        // START hidden; `<` and `>` drawn.
        XCTAssertEqual(buttons(s.output.ops, a).map(\.x), [128, 511])
        // Halt, gaso 8 `incl`, music pause; the present, then the wait (full screen).
        XCTAssertEqual(s.output.sounds, [cue(a, 8)])
        XCTAssertEqual(s.output.haltEffectsAt, 0)
        XCTAssertEqual(s.output.music, [.pause])
        XCTAssertEqual(Array(s.output.ops.suffix(2)), [.present(.fullScreen), .pauseWait(.fullScreen)])
        // The next frame resumes the music first.
        let after = step(&run)
        XCTAssertEqual(after.output.music.first, .resume)
        XCTAssertEqual(buttons(after.output.ops, a).map(\.x), [128, 320, 511])
        // A Quit that let the wait go (the driver sets b8): the controller's +2, no resume, out as with Esc.
        var (quitRun, _) = try entered()
        step(&quitRun)
        step(&quitRun, HeldKeys(capsLock: true))
        quitRun.state.quit = true
        let out = step(&quitRun)
        XCTAssertEqual(out.finished, .some(nil))
        XCTAssertFalse(out.output.music.contains(.resume))
    }
}

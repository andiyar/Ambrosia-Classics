#if canImport(AppKit)
import AppKit
#endif
@testable import FerazelCore
@testable import FerazelWinKit
import Foundation
import HectorInput
import XCTest

/// WF4a (D43 Ruling 4): DLOG 202 (confirm) and DLOG 200 (report / error) drawn inside the game picture, behaving as
/// the Mac's transcription (`Ferazel/App/Dialogs/FerazelCarbonDialog.swift`, `FerazelDialogs.swift`): layout from the
/// DLOG / DITL, `ParamText`, the OK ring, Return / Enter → OK through the 8-tick flash, Esc doing nothing (the standard
/// filter has no cancel item: `ModalDialog(nil)`, no `SetDialogCancelItem`), button tracking, outside clicks beeping,
/// the pad's Return / Esc, the flow held still. No window, no audio, no SDL; a missing data file is a FAILURE.
@MainActor final class WinDialogTests: XCTestCase {
    /// A booted driver (its resources, its dialog pictures, its mute-gated beep) and the dialogs over it, with a test
    /// clock for the flash.
    @MainActor final class Bench {
        let rig: Rig
        let dialogs: DialogSystem
        var now: UInt32 = 5000
        var answers: [DialogResult] = []

        init(mute: Bool = false) throws {
            rig = try Rig(mute: mute, text: try BakedTextTests.baked())
            dialogs = DialogSystem(text: try BakedTextTests.baked())
            let driver = rig.driver
            dialogs.attach(WinDialogServices(resources: driver.resources, picture: { driver.dialogPicture($0) },
                                             beep: { driver.beep() }, ticks: { [unowned self] in now }))
        }

        func show(_ d: FerazelDialog) { dialogs.show(d) { [unowned self] in answers.append($0) } }

        /// `n` ticks pass, the dialogs told at each.
        func ticks(_ n: Int) {
            for _ in 0..<n {
                now &+= 1
                dialogs.tick(now: now)
            }
        }

        var front: DialogWindow { dialogs.stack.last! }

        /// A canvas point at dialog-content coordinates (`x`, `y`) of the front dialog.
        func canvas(_ x: Int, _ y: Int) -> (x: Int, y: Int) { (front.contentX + x, front.contentY + y) }

        func click(_ p: (x: Int, y: Int)) {
            dialogs.mouseDown(x: p.x, y: p.y)
            dialogs.mouseUp(x: p.x, y: p.y)
        }

        var beeps: Int { rig.counters.beeps }
    }

    static let abort = GameLoopKeys.abortText
    static let diskFull = SavedGameFile.writeErrorReport(osErr: SaveWriteError.diskFull).message

    static func rect(_ x: Int, _ y: Int, _ w: Int, _ h: Int) -> DialogRect { DialogRect(x: x, y: y, width: w, height: h) }

    // MARK: 1 · layout from the DLOG / DITL

    func testLayoutFromDITL202And200() throws {
        let b = try Bench()
        b.show(.confirm(text: Self.abort))
        XCTAssertTrue(b.dialogs.isShowing)
        let d = b.front
        XCTAssertEqual(d.template.id, 202)
        // The DLOG rect 295 × 142 inside the dBoxProc frame (6 px each side), centred on the 640×480 screen as the
        // Mac's `show(over:)` centres the panel (x rounded, the bottom-up y rounded — 163 either way here).
        XCTAssertEqual(d.frame, Self.rect(167, 163, 307, 154))
        XCTAssertEqual([d.contentX, d.contentY], [173, 169])
        XCTAssertEqual(d.items.map(\.number), [1, 2, 3, 4])
        XCTAssertEqual(d.items.map(\.item.kind), [.button, .button, .picture, .staticText])
        XCTAssertEqual(d.items.map(\.rect), [Self.rect(226, 113, 58, 20), Self.rect(161, 113, 58, 20),
                                             Self.rect(10, 10, 32, 32), Self.rect(53, 10, 211, 87)])
        XCTAssertEqual(d.items[2].item.resourceID, 145)
        XCTAssertEqual(d.defaultItem, 1)
        XCTAssertEqual(d.outlines, [1], "the ring round OK")
        XCTAssertEqual(DialogRenderer.ringRect(d.items[0].rect), Self.rect(222, 109, 66, 28), "InsetRect(−4, −4)")
        XCTAssertEqual(d.contentRGB, 0xEEEEEE, "the dctb's wContentColor")
        XCTAssertNotNil(d.pictures[3], "PICT 145 under the current clut")

        let r = try Bench()
        r.show(.report(text: GameFlow.levelLoadError))
        let e = r.front
        XCTAssertEqual(e.template.id, 200)
        // 318 × 155 → 330 × 167: x = (320 − 165) = 155; bottom-up y = (240 − 83.5).rounded() = 157 → top 480 − 157 − 167.
        XCTAssertEqual(e.frame, Self.rect(155, 156, 330, 167))
        XCTAssertEqual(e.items.map(\.item.kind), [.button, .picture, .staticText, .staticText])
        XCTAssertEqual(e.items.map(\.rect), [Self.rect(242, 121, 58, 20), Self.rect(10, 10, 32, 32),
                                             Self.rect(53, 10, 249, 98), Self.rect(10, 123, 191, 20)])
        XCTAssertEqual(e.outlines, [1])
        XCTAssertEqual(e.contentRGB, 0xEEEEEE)
    }

    // MARK: 2 · ParamText

    func testParamsSubstituted() throws {
        let b = try Bench()
        b.show(.confirm(text: GameLoopKeys.quitText))
        XCTAssertEqual(b.front.params, [GameLoopKeys.quitText])
        XCTAssertEqual(b.front.text(4), "Are you sure you want to quit?")
        XCTAssertEqual([b.front.text(1), b.front.text(2)], ["OK", "Cancel"])
        // `.ReportDialog`: ^0 = the text, ^1 = ""; the original's CR ends a line.
        let r = try Bench()
        r.show(.report(text: GameFlow.noMoreCheating))
        XCTAssertEqual(r.front.params, [GameFlow.noMoreCheating, ""])
        XCTAssertEqual(r.front.text(3), "Ferazel sez:\nNo more cheating!")
        XCTAssertEqual(r.front.text(4), "")
        // `.ReportError`: ^1 = NumToString(code).
        let e = try Bench()
        e.show(.error(text: Self.diskFull, code: SaveWriteError.diskFull))
        XCTAssertEqual(e.front.text(3), Self.diskFull)
        XCTAssertEqual(e.front.text(4), "-34")
        let z = try Bench()
        z.show(.error(text: "Error showing world map", code: 0))
        XCTAssertEqual(z.front.text(4), "0")
        // The pure-Swift replace (Ruling 18: never `replacingOccurrences`): every match, scalar-wise (a "\r" inside a
        // "\r\n" grapheme is found), unchanged when nothing matches.
        XCTAssertEqual("^0 and ^0".replacingEvery("^0", with: "x"), "x and x")
        XCTAssertEqual("a\r\nb".replacingEvery("\r", with: "\n"), "a\n\nb")
        XCTAssertEqual("abc".replacingEvery("^1", with: "z"), "abc")
        XCTAssertEqual(DialogWindow.substitute("^0^1^2^3!", params: ["a"]), "a!", "absent params are empty")
        // TETextBox-style wrap in the item's width (the Mac's NSStringDrawing breaks, test 11).
        let renderer = DialogRenderer(text: try BakedTextTests.baked())
        XCTAssertEqual(renderer.wrap(SavedGameFile.writeErrorReport(osErr: SaveWriteError.ioError).message, width: 249),
                       ["The game could not be saved. Check that", "there is enough space and the volume is",
                        "not locked."])
        XCTAssertEqual(renderer.wrap("Ferazel sez:\nNo more cheating!", width: 249), ["Ferazel sez:", "No more cheating!"])
    }

    // MARK: 3 · keyboard answers

    func testKeyboardAnswers() throws {
        // DLOG 202: Return and Enter press OK (after the flash); Esc, ⌘Return and other keys do nothing.
        for code: UInt16 in [0x24, 0x4C] {
            let b = try Bench()
            b.show(.confirm(text: Self.abort))
            b.dialogs.keyDown(code, modifiers: [])
            b.ticks(8)
            XCTAssertEqual(b.answers, [.ok], "key 0x\(String(code, radix: 16))")
            XCTAssertFalse(b.dialogs.isShowing)
        }
        for report in [true, false] {
            let b = try Bench()
            b.show(report ? .report(text: GameFlow.levelLoadError) : .confirm(text: Self.abort))
            b.dialogs.keyDown(0x35, modifiers: [])                         // Esc
            b.dialogs.keyDown(0x24, modifiers: .command)                   // ⌘Return
            b.dialogs.keyDown(0x00, modifiers: [])                         // A
            b.dialogs.keyDown(0x31, modifiers: [])                         // Space
            b.ticks(30)
            XCTAssertEqual(b.answers, [], "nothing answers but Return / Enter (report \(report))")
            XCTAssertTrue(b.dialogs.isShowing)
            XCTAssertNil(b.front.flashItem)
            b.dialogs.keyDown(0x24, modifiers: .shift)                     // Shift does not stop Return
            b.ticks(8)
            XCTAssertEqual(b.answers, [.ok])
        }
    }

    // MARK: 4 · the OK flash

    func testOKFlashLastsEightTicksAndIgnoresInput() throws {
        let b = try Bench()
        b.show(.confirm(text: Self.abort))
        let r0 = b.dialogs.revision
        b.dialogs.keyDown(0x24, modifiers: [])
        XCTAssertEqual(b.front.flashItem, 1, "OK hilited")
        XCTAssertTrue(b.front.isHighlighted(1))
        XCTAssertNotEqual(b.dialogs.revision, r0)
        for i in 1...7 {
            b.ticks(1)
            XCTAssertEqual(b.answers, [], "tick \(i)")
            XCTAssertTrue(b.front.isHighlighted(1))
            if i == 3 {
                // A key and a click on Cancel while it flashes: nothing (`handleKeyDown`'s `flashing` guard, the
                // panel's clicks consumed).
                b.dialogs.keyDown(0x24, modifiers: [])
                let cancel = b.canvas(190, 123)
                b.dialogs.mouseDown(x: cancel.x, y: cancel.y)
                XCTAssertNil(b.front.tracking, "a press on Cancel while it flashes is not tracked")
                XCTAssertFalse(b.front.isHighlighted(2), "pressed while flashing: Cancel stays unhilited")
                b.dialogs.mouseUp(x: cancel.x, y: cancel.y)
                XCTAssertEqual(b.answers, [], "released on Cancel while flashing: no hit")
            }
        }
        b.ticks(1)
        XCTAssertEqual(b.answers, [.ok], "8 ticks, then the hit — once, OK, never the Cancel pressed meanwhile")
        XCTAssertFalse(b.dialogs.isShowing)
        b.ticks(20)
        XCTAssertEqual(b.answers, [.ok])
        XCTAssertEqual(b.beeps, 0)
    }

    // MARK: 5 · mouse tracking

    func testMouseTrackingPressDragOutReleaseIsNothing() throws {
        let b = try Bench()
        b.show(.confirm(text: Self.abort))
        let cancel = b.canvas(190, 123), outside = b.canvas(190, 60)
        b.dialogs.mouseDown(x: cancel.x, y: cancel.y)
        XCTAssertTrue(b.front.isHighlighted(2), "pressed: hilited")
        b.dialogs.mouseMoved(x: outside.x, y: outside.y)
        XCTAssertFalse(b.front.isHighlighted(2), "dragged out: unhilited")
        b.dialogs.mouseUp(x: outside.x, y: outside.y)
        XCTAssertEqual(b.answers, [], "released outside: nothing")
        XCTAssertTrue(b.dialogs.isShowing)
        // Keys while a button is held down are dropped: Return / Enter neither flash OK nor answer, even after the
        // flash's 8 ticks; the release outside is then nothing.
        b.dialogs.mouseDown(x: cancel.x, y: cancel.y)
        XCTAssertTrue(b.front.isHighlighted(2))
        b.dialogs.keyDown(0x24, modifiers: [])
        b.dialogs.keyDown(0x4C, modifiers: [])
        XCTAssertNil(b.front.flashItem, "no flash while Cancel is held")
        b.ticks(10)
        XCTAssertEqual(b.answers, [])
        b.dialogs.mouseMoved(x: outside.x, y: outside.y)
        b.dialogs.mouseUp(x: outside.x, y: outside.y)
        b.ticks(10)
        XCTAssertEqual(b.answers, [], "held, Return, released outside: nothing")
        XCTAssertNil(b.front.flashItem)
        // Out and back in: the release inside hits — at once, no flash.
        let ok = b.canvas(250, 120)
        b.dialogs.mouseDown(x: ok.x, y: ok.y)
        b.dialogs.mouseMoved(x: outside.x, y: outside.y)
        b.dialogs.mouseMoved(x: ok.x + 5, y: ok.y)
        XCTAssertTrue(b.front.isHighlighted(1))
        b.dialogs.mouseUp(x: ok.x + 5, y: ok.y)
        XCTAssertEqual(b.answers, [.ok])
        XCTAssertFalse(b.dialogs.isShowing)
        // Cancel clicked: `.cancel`. Static text and the picture take no click; none of it beeps.
        let c = try Bench()
        c.show(.confirm(text: Self.abort))
        c.click(c.canvas(100, 30))
        c.click(c.canvas(20, 20))
        XCTAssertEqual(c.answers, [])
        c.click(c.canvas(190, 123))
        XCTAssertEqual(c.answers, [.cancel])
        XCTAssertEqual(c.beeps, 0)
    }

    // MARK: 6 · the pad's Return / Esc

    func testPadReturnAnswersAndPadEscDoesNothing() throws {
        for report in [false, true] {
            let b = try Bench()
            b.show(report ? .error(text: Self.diskFull, code: -34) : .confirm(text: Self.abort))
            // The Mac posts the pad's Esc to the panel as a key: the standard filter ignores it.
            b.dialogs.padKeyDown(FerazelPadLayout.escapeKey)
            b.ticks(20)
            XCTAssertEqual(b.answers, [])
            b.dialogs.padKeyDown(FerazelPadLayout.returnKey)
            XCTAssertEqual(b.front.flashItem, 1, "the pad's Return flashes OK as the keyboard's does")
            b.ticks(7)
            XCTAssertEqual(b.answers, [])
            b.ticks(1)
            XCTAssertEqual(b.answers, [.ok], "report \(report)")
        }
    }

    // MARK: 7 · a click outside the dialog beeps (never when muted)

    func testOutsideClickBeepsOnceUnmutedNeverMuted() throws {
        for mute in [false, true] {
            let b = try Bench(mute: mute)
            b.show(.confirm(text: Self.abort))
            let f = b.front.frame
            b.click((10, 10))                                              // the game picture
            XCTAssertEqual(b.beeps, mute ? 0 : 1, "mute \(mute)")
            b.click((-5, 240))                                             // the letterbox, off the canvas
            XCTAssertEqual(b.beeps, mute ? 0 : 2)
            b.click((f.x + 2, f.y + 2))                                    // the dialog's own frame
            b.click(b.canvas(100, 100))                                    // its content, no item
            XCTAssertEqual(b.beeps, mute ? 0 : 2, "inside the panel: no beep")
            XCTAssertEqual(b.answers, [])
            XCTAssertTrue(b.dialogs.isShowing)
            // During the flash a click outside still beeps (the panel's own clicks are what the flash eats).
            b.dialogs.keyDown(0x24, modifiers: [])
            b.click((600, 20))
            XCTAssertEqual(b.beeps, mute ? 0 : 3)
            b.ticks(8)
            XCTAssertEqual(b.answers, [.ok])
        }
    }

    // MARK: 8 · the flow holds still; the answer reaches `GameFlow.dialogDone`

    func testFlowHoldsStillWhileUpAndPadAnswerReachesTheFlow() throws {
        let dialogs = DialogSystem(text: try BakedTextTests.baked())
        var pad = ShellPadState()
        let (game, host) = try WinGameTests.game(script: "1440 down n", dialogs: dialogs, padSource: { pad })
        WinGameTests.run(game, host) { $0.flow.padContext == .playing }
        let free = game.flowSteps
        WinGameTests.run(game, host) { $0.flowSteps == free + WinGameTests.settleSteps }
        host.inject(.keyDown(keyCode: 0x35, modifiers: [], isRepeat: false))                 // Esc: abort?
        WinGameTests.run(game, host, max: 400) { _ in dialogs.isShowing }
        host.inject(.keyUp(keyCode: 0x35))
        XCTAssertEqual(dialogs.stack.last?.text(4), GameLoopKeys.abortText)
        let held = game.flowSteps
        let gameFrame = try XCTUnwrap(game.gameFrame)
        for _ in 0..<400 { game.step(); host.advance() }
        XCTAssertEqual(game.flowSteps, held, "100 ticks with the dialog up: the flow never ran")
        // The picture is the game's last frame with the dialog drawn into it.
        let shown = try XCTUnwrap(game.lastPresented)
        var expected = gameFrame
        dialogs.draw(into: &expected)
        XCTAssertEqual(shown, expected)
        XCTAssertNotEqual(shown, gameFrame)
        let f = try XCTUnwrap(dialogs.stack.last).frame
        XCTAssertEqual(Array(shown[4 * (f.y * 640 + f.x) ..< 4 * (f.y * 640 + f.x) + 4]), [0, 0, 0, 255], "frame")
        let c = 4 * ((f.y + 100) * 640 + f.x + 30)                      // content (24, 94): no item there
        XCTAssertEqual(Array(shown[c ..< c + 4]), [0xEE, 0xEE, 0xEE, 255], "the dctb grey")
        // The pad's south button is Return in a dialog (D37): OK flashes 8 ticks, the flow gets `.ok` (abort).
        pad = ShellPadState(buttons: [.south])
        WinGameTests.run(game, host, max: 4 * 20) { _ in !dialogs.isShowing }
        pad = ShellPadState()
        XCTAssertEqual(game.flowSteps, held)
        XCTAssertEqual(game.lastPresented, gameFrame, "the dialog gone: the game's picture again")
        WinGameTests.run(game, host) { $0.flow.state == .mainMenu }
        XCTAssertGreaterThan(game.flowSteps, held)
    }

    // MARK: 9, 10 · goldens (self-derived; FERAZEL_WRITE_GOLDENS=1 rewrites them)

    nonisolated static let goldens = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().appendingPathComponent("Goldens", isDirectory: true)

    func golden(_ name: String, _ dialog: FerazelDialog) throws {
        let b = try Bench()
        b.show(dialog)
        var rgba = [UInt8](repeating: 0, count: 640 * 480 * 4)
        for i in stride(from: 3, to: rgba.count, by: 4) { rgba[i] = 255 }
        b.dialogs.draw(into: &rgba)
        let ppm = WinGame.ppm(rgba: rgba)
        let url = Self.goldens.appendingPathComponent(name)
        if ProcessInfo.processInfo.environment["FERAZEL_WRITE_GOLDENS"] == "1" {
            try FileManager.default.createDirectory(at: Self.goldens, withIntermediateDirectories: true)
            try Data(ppm).write(to: url)
        }
        let committed = try [UInt8](Data(contentsOf: url))
        XCTAssertEqual(committed.count, ppm.count, name)
        XCTAssertTrue(committed == ppm, "\(name): FNV \(hex(fnv1a64(ppm))) ≠ committed \(hex(fnv1a64(committed)))")
    }

    func testGolden202() throws {
        try golden("Dialog-202.ppm", .confirm(text: Self.abort))
    }

    func testGolden200() throws {
        try golden("Dialog-200.ppm", .error(text: Self.diskFull, code: SaveWriteError.diskFull))
    }

    // MARK: 11 · the dialog face against the Mac (NSFont widths, NSStringDrawing breaks, CoreText masks)

    #if canImport(AppKit)
    /// Every DLOG 202 / 200 string the game can show (the closed set: `.dialog(.confirm / .report / .error)` call
    /// sites in Core — `WorldMapRun`, `GameLoopKeys`, `ContinueGame`, `BootSequence`, `NewGame`, `SavedGameFile`,
    /// `ConversationRun`), the buttons' titles and every `^1` code (0…32767 conversation ids, −32768, the four File
    /// Manager codes).
    static func closedSet() -> (texts: [String], codes: [String]) {
        let texts = [
            GameLoopKeys.quitText, GameLoopKeys.abortText, WorldMapRun.quitText, WorldMapRun.abortText,
            GameFlow.previewRefusal, GameFlow.demoRefusal, BootSequence.fadingDisabledReport,
            BootSequence.soundLoadingReport, GameFlow.noMoreCheating, GameFlow.levelLoadError,
            WorldMapRun.errorShowingMap, WorldMapRun.nodeNotFound, ConversationRun.loadError,
        ] + [SaveWriteError.diskFull, SaveWriteError.directoryFull, SaveWriteError.volumeLocked, SaveWriteError.ioError]
            .map { SavedGameFile.writeErrorReport(osErr: $0).message }
        let codes = (0...32767).map { String($0) } + ["-32768", "-34", "-33", "-44", "-36"]
        return (texts, codes)
    }

    func testDialogFaceMatchesTheMacsFontWidthsBreaksAndCoreText() throws {
        // The Mac's `ClassicFont.system` pick (`DialogViews.swift:12–13`), and the baked face's family through
        // `CoreTextRasterizer` (font 0 face 1): ◇W13 is kept only if they differ.
        let classic = NSFont(name: "Charcoal", size: 12) ?? NSFont(name: "Chicago", size: 12) ?? .boldSystemFont(ofSize: 12)
        let ct = CoreTextRasterizer()
        XCTAssertEqual(classic.familyName, CTFontCopyFamilyName(ct.ctFont(0, size: 12, face: 1)) as String)
        let renderer = DialogRenderer(text: try BakedTextTests.baked())
        let attrs: [NSAttributedString.Key: Any] = [.font: classic]
        let (texts, codes) = Self.closedSet()
        XCTAssertEqual(texts.count, 17)
        // Line breaks as the Mac's NSStringDrawing makes them in each text item's width (DITL 202 item 4: 211;
        // DITL 200 item 3: 249), and the line height / baseline the renderer uses.
        let lm = NSLayoutManager()
        XCTAssertEqual(lm.defaultLineHeight(for: classic), CGFloat(DialogRenderer.lineHeight))
        XCTAssertEqual(lm.defaultBaselineOffset(for: classic), CGFloat(DialogRenderer.ascent))
        var lines: Set<String> = ["OK", "Cancel"]
        for text in texts {
            let s = DialogWindow.substitute("^0", params: [text])
            for width in [211, 249] {
                let mine = renderer.wrap(s, width: width)
                XCTAssertEqual(mine, Self.appKitLines(s, width: width, attrs: attrs), "\(width): \(s)")
                lines.formUnion(mine)
            }
        }
        // Every line drawn, the titles and every code: widths within 1 px of AppKit's `size()` (the Mac centres the
        // button titles by it).
        var worst = 0.0
        for s in lines.sorted() + codes {
            let mac = NSAttributedString(string: s, attributes: attrs).size().width
            worst = max(worst, abs(mac - renderer.width(s)))
        }
        // The oracle is the Mac's `ClassicFont` pick on this machine: with Charcoal or Chicago installed it changes,
        // and this exact-equality check would then rightly fail (◇W13 would be kept).
        XCTAssertLessThanOrEqual(worst, 0.001, "dialog-face widths vs NSFont: equal (measured 0.0 px)")
        // Every line drawn, and every code, byte for byte against CoreText (WF2: the baked format models
        // two-character ligatures only — this closes the dialog strings).
        let baked = try BakedTextTests.baked()
        var misses: [String] = []
        for s in lines.sorted() + codes where !BakedTextTests.same(ct.rasterize(s, font: 0, size: 12, face: 1),
                                                                     baked.rasterize(s, font: 0, size: 12, face: 1)) {
            misses.append(s)
        }
        XCTAssertEqual(misses, [])
    }

    /// AppKit's lines for `s` in a `width`-wide container (no line-fragment padding, word wrapping), trailing
    /// whitespace and line ends dropped.
    static func appKitLines(_ s: String, width: Int, attrs: [NSAttributedString.Key: Any]) -> [String] {
        let storage = NSTextStorage(string: s, attributes: attrs)
        let lm = NSLayoutManager()
        let container = NSTextContainer(size: NSSize(width: CGFloat(width), height: 10_000))
        container.lineFragmentPadding = 0
        lm.addTextContainer(container)
        storage.addLayoutManager(lm)
        lm.ensureLayout(for: container)
        var out: [String] = []
        var i = 0
        let ns = s as NSString
        while i < lm.numberOfGlyphs {
            var range = NSRange()
            _ = lm.lineFragmentRect(forGlyphAt: i, effectiveRange: &range)
            var line = ns.substring(with: lm.characterRange(forGlyphRange: range, actualGlyphRange: nil))
            while let last = line.last, last == " " || last == "\n" || last == "\r" { line.removeLast() }
            out.append(line)
            i = NSMaxRange(range)
        }
        return out
    }
    #endif
}

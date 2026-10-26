@testable import FerazelCore
@testable import FerazelRender
@testable import FerazelWinKit
import Foundation
import HectorAudio
import HectorInput
import XCTest

/// WF4b (D43 Ruling 4): DLOG 6900 (Options) and DLOG 600 (Credits) drawn inside the game picture, behaving as the Mac's
/// `PrefsDialogView` over O1's `PrefsDialogModel` and `CreditsDialog` over `CreditsScroll` (`Ferazel/App/Dialogs/`):
/// every control into the model, the key capture with the original's refusal, the music cues at once, Cancel / OK, the
/// credits' 3-tick steps, its picture under the current clut, a click closing it, no pad keys (D37). No window, no
/// audio, no SDL; a missing data file is a FAILURE.
@MainActor final class WinOptionsCreditsTests: XCTestCase {
    /// A booted driver and the dialogs over it, the flow's Options model and credits held here (the services the game
    /// wires to `GameFlow.prefsDialog` / `credits` and `FerazelDriver.handle`), a test clock and modifier state.
    @MainActor final class Bench {
        let rig: Rig
        let dialogs: DialogSystem
        var now: UInt32 = 5000
        var model: PrefsDialogModel?
        var credits: CreditsScroll?
        var modifiers: WinModifiers = []
        /// Every music cue the dialog handed on, with the tick it came at.
        var cues: [(cue: MusicCue, at: UInt32)] = []
        var answers: [DialogResult] = []
        /// Calls into the model (every event the dialog fed it).
        var updates = 0

        init(record: FerazelPrefs = FerazelPrefs(), live: PrefsToggles? = nil, mute: Bool = false) throws {
            rig = try Rig(mute: mute, text: try BakedTextTests.baked())
            dialogs = DialogSystem(text: try BakedTextTests.baked())
            model = PrefsDialogModel(record: record, live: live ?? PrefsToggles(live: record), paused: false,
                                     keyCharacter: { ShellKeyCharacters.characters(forKeyCode: UInt16(bitPattern: $0)) })
            let driver = rig.driver
            dialogs.attach(WinDialogServices(
                resources: driver.resources, picture: { driver.dialogPicture($0) }, beep: { driver.beep() },
                ticks: { [unowned self] in now },
                prefs: { [unowned self] in model },
                updatePrefs: { [unowned self] body in
                    guard var m = model else { return }
                    updates += 1
                    let made = body(&m)
                    model = m
                    cues += made.map { ($0, now) }
                },
                credits: { [unowned self] in credits },
                modifiers: { [unowned self] in modifiers }))
        }

        func show(_ d: FerazelDialog) { dialogs.show(d) { [unowned self] in answers.append($0) } }

        func ticks(_ n: Int) {
            for _ in 0..<n {
                now &+= 1
                dialogs.tick(now: now)
            }
        }

        var front: DialogWindow { dialogs.stack.last! }
        func canvas(_ x: Int, _ y: Int) -> (x: Int, y: Int) { (front.contentX + x, front.contentY + y) }

        func click(_ p: (x: Int, y: Int)) {
            dialogs.mouseDown(x: p.x, y: p.y)
            dialogs.mouseUp(x: p.x, y: p.y)
        }

        /// The centre of item `n` of the front dialog, in canvas pixels.
        func centre(_ n: Int) -> (x: Int, y: Int) {
            let r = front.item(n)!.rect
            return canvas(r.x + r.width / 2, r.y + r.height / 2)
        }

        func clickItem(_ n: Int) { click(centre(n)) }

        /// A popup's menu opened by a click on its box (released there it stays up), then its row `value` clicked.
        func pick(_ n: Int, _ value: Int) {
            click(centre(n))
            guard let m = front.menu else { return XCTFail("item \(n): no menu up") }
            XCTAssertEqual(m.item, n)
            let row = m.rows[value - 1]
            click(canvas(row.x + row.width / 2, row.y + row.height / 2))
            XCTAssertNil(front.menu, "the pick closes the menu")
        }

        func key(_ code: UInt16, _ mods: WinModifiers = [], isRepeat: Bool = false) {
            dialogs.keyDown(code, modifiers: mods, isRepeat: isRepeat)
        }

        var m: PrefsDialogModel { model! }
        var beeps: Int { rig.counters.beeps }
    }

    // MARK: 1 · every Options control into the model

    func testEveryOptionsControlReachesTheModel() throws {
        let b = try Bench()
        b.show(.preferences)
        XCTAssertTrue(b.dialogs.isShowing)
        let d = b.front
        XCTAssertEqual(d.template.id, 6900)
        XCTAssertEqual(d.items.count, 14, "DITL 6900's six + DITL 6901 appended")
        XCTAssertEqual(d.outlines, [1])
        XCTAssertNil(d.defaultItem, "the filter handles Return / Enter")
        XCTAssertEqual([d.value(3), d.value(7), d.value(10), d.value(11)], [1, 0, 1, 1])
        // Game Options: the checkboxes toggle the working copy and the boxes; the popups set graphics / effects.
        for n in [7, 8, 9] { b.clickItem(n) }
        XCTAssertEqual([b.m.working.reduceFrameRate, b.m.working.reuseSavedGames, b.m.working.backgroundTasks], [1, 1, 1])
        XCTAssertEqual([d.value(7), d.value(8), d.value(9)], [1, 1, 1], "the boxes drawn checked")
        b.clickItem(14)
        XCTAssertEqual(b.m.working.resolutionSwitch, 1)
        XCTAssertEqual(d.value(14), 0, "the original updates control 16, which Game Options lacks")
        b.pick(10, 3)
        b.pick(11, 2)
        XCTAssertEqual([b.m.working.graphics, b.m.working.effects], [3, 2])
        XCTAssertEqual([d.value(10), d.value(11)], [3, 2])
        b.clickItem(4)                                                     // Default Settings: into the record
        XCTAssertEqual(b.m.record.graphics, 1)
        XCTAssertEqual(b.m.working.graphics, 3, "Game Options' defaults go to the record, not the working copy")
        // The panel popup: Controls (DITL 6902 from item 7); the key fields, the focus, InputSprocket disabled.
        b.pick(3, 2)
        XCTAssertEqual(b.m.panel, .controls)
        XCTAssertEqual(d.items.count, 27)
        XCTAssertEqual((7...15).map { d.text($0) }, ["Keypad 4", "Keypad 6", "Keypad 8", "Keypad 5", "Shift", "Option",
                                                    "Command", "Keypad 7", "Keypad 9"])
        XCTAssertEqual(d.selected, 7)
        XCTAssertFalse(d.isActive(26))
        XCTAssertFalse(d.isActive(27))
        b.clickItem(10)
        XCTAssertEqual([b.m.focus, d.selected], [10, 10], "a click in a key field selects it")
        let fed = b.updates
        b.clickItem(26)
        b.clickItem(27)
        XCTAssertEqual(b.m.working.useInputSprocket, 0, "disabled items take no click")
        XCTAssertEqual(b.updates, fed, "the dialog's own gate: a disabled item's click never reaches the model")
        // Sound & Music (DITL 6903): the QuickTime line hidden; the boxes and the volume popups (value v ↔ 10 − v).
        b.pick(3, 3)
        XCTAssertEqual(b.m.panel, .soundAndMusic)
        XCTAssertEqual(d.items.count, 16)
        XCTAssertTrue(d.isHidden(13))
        XCTAssertNil(d.selected)
        b.clickItem(7)
        XCTAssertEqual(b.m.working.soundOn, 0)
        b.pick(9, 4)
        XCTAssertEqual(b.m.working.soundVolume, 6)
        b.pick(15, 2)
        XCTAssertEqual(b.m.working.systemVolumeBy28, 8)
        b.clickItem(16)
        XCTAssertEqual(b.m.working.useSystemVolume, 1)
        XCTAssertEqual(d.value(16), 1)
        b.clickItem(4)                                                     // Default Settings: the working copy
        XCTAssertEqual([Int(b.m.working.soundOn), Int(b.m.working.soundVolume), Int(b.m.working.useSystemVolume)], [1, 7, 0])
        XCTAssertEqual([d.value(7), d.value(9), d.value(16)], [1, 3, 0])
        // Static text and the panel's outline take no click; nothing beeped, nothing answered.
        b.clickItem(6)
        b.click(b.canvas(20, 200))
        XCTAssertEqual(b.answers, [])
        XCTAssertEqual(b.beeps, 0)
    }

    // MARK: 2 · key capture: accepted

    func testKeyCaptureAccepted() throws {
        let b = try Bench()
        b.show(.preferences)
        b.pick(3, 2)
        let d = b.front
        b.key(0x0C)                                                        // Q into Walk Left
        XCTAssertEqual(b.m.working.keys[0], 0x0C)
        XCTAssertEqual(d.text(7), "Q", "the US layout's character, uppercased (◇W1)")
        XCTAssertEqual(d.selected, 8, "the focus moves on")
        b.key(0x0D, isRepeat: true)                                        // an autorepeat: swallowed
        XCTAssertEqual(b.m.working.keys[1], 0x58)
        XCTAssertEqual(d.selected, 8)
        b.key(0x24)                                                        // Return is a key here, not OK
        XCTAssertEqual(b.m.working.keys[1], 0x24)
        XCTAssertEqual(d.text(8), "Return")
        XCTAssertEqual(b.answers, [])
        // A modifier held is taken by the null events, once: the Windows key is ⌃ (Control, 0x3b, unused).
        XCTAssertEqual(d.selected, 9)
        // While a popup's menu is open no null event runs (`PopUpMenuSelect` tracks modally): nothing is taken.
        b.click(b.centre(3))
        XCTAssertNotNil(d.menu)
        b.modifiers = .control
        b.ticks(3)
        XCTAssertEqual(b.m.working.keys[2], 0x5b, "no modifier capture with the menu open")
        b.key(0x35)                                                        // Esc: closes the menu, nothing else
        XCTAssertNil(d.menu)
        XCTAssertEqual(b.m.working.keys[2], 0x5b)
        b.ticks(3)
        XCTAssertEqual(b.m.working.keys[2], 0x3b)
        XCTAssertEqual(d.text(9), "Control")
        XCTAssertEqual(d.selected, 10, "held three ticks: taken once")
        b.modifiers = []
        b.ticks(1)
        // The focus wraps 15 → 7.
        b.clickItem(15)
        b.key(0x01)                                                        // S
        XCTAssertEqual([d.text(15)], ["S"])
        XCTAssertEqual(d.selected, 7)
        // A key field takes clicks in its own rect only (the binary's `FindDialogItem`), not 2 px outside it.
        let r12 = try XCTUnwrap(d.item(12)).rect
        b.click(b.canvas(r12.x - 2, r12.y + 5))
        b.click(b.canvas(r12.x + 3, r12.maxY + 1))
        XCTAssertEqual(d.selected, 7)
        b.click(b.canvas(r12.x, r12.y))
        XCTAssertEqual(d.selected, 12, "its top-left pixel is inside")
        XCTAssertTrue(b.dialogs.isShowing)
        XCTAssertEqual(b.dialogs.stack.count, 1)
    }

    // MARK: 3 · key capture: refused ("already used")

    func testKeyCaptureRefusedWithTheOriginalsMessage() throws {
        for mute in [false, true] {
            let b = try Bench(mute: mute)
            b.show(.preferences)
            b.pick(3, 2)
            let options = b.front
            // A — key code 0 reads as used (the tenth short +0x24 is 0, D35 ruling 9): DLOG 200 over Options.
            b.key(0x00)
            XCTAssertEqual(b.dialogs.stack.count, 2)
            XCTAssertEqual(b.front.template.id, 200)
            XCTAssertEqual(b.front.text(3), PrefsDialogModel.keyInUseMessage)
            XCTAssertEqual(b.m.working.keys, FerazelPrefs.defaultKeys, "nothing taken")
            XCTAssertEqual(options.selected, 7, "the focus stays")
            // Keys go to the report now (Options' filter sees none); Return closes it after the flash.
            b.key(0x0C)
            XCTAssertEqual(b.m.working.keys[0], 0x56)
            b.key(0x24)
            b.ticks(8)
            XCTAssertEqual(b.dialogs.stack.count, 1)
            XCTAssertTrue(b.front === options)
            XCTAssertEqual(b.answers, [], "the report's OK is not the Options answer")
            // A key another action holds (Keypad 6 = Walk Right) is refused for Walk Left too.
            b.key(0x58)
            XCTAssertEqual(b.front.text(3), PrefsDialogModel.keyInUseMessage)
            b.click(b.centre(1))
            XCTAssertEqual(b.dialogs.stack.count, 1)
            b.clickItem(9)
            b.key(0x38)                                                    // Shift (Run's) on Climb Up
            XCTAssertEqual(b.dialogs.stack.count, 2)
            b.key(0x24)
            b.ticks(8)
            XCTAssertEqual(b.m.working.keys, FerazelPrefs.defaultKeys)
            XCTAssertEqual(b.beeps, 0, "a refusal is a report, never a beep (mute \(mute))")
        }
    }

    // MARK: 4 · the Music checkbox and the volume popup act at once

    func testMusicCuesActAtOnce() throws {
        var music = MusicFade()
        _ = music.setAIFFMusic(24)
        let live = PrefsToggles(live: FerazelPrefs(), music: music, appliedMusicOn: 1)
        let b = try Bench(live: live)
        var reference = PrefsDialogModel(record: FerazelPrefs(), live: live, paused: false, keyCharacter: { _ in nil })
        b.show(.preferences)
        b.pick(3, 3)
        reference.hit(3, value: 3)
        let at = b.now
        b.pick(10, 5)
        let volume = reference.hit(10, value: 5)
        XCTAssertFalse(volume.isEmpty)
        XCTAssertEqual(b.cues.map(\.cue), volume, "the music volume popup's cue")
        b.clickItem(8)
        let off = reference.hit(8)
        XCTAssertEqual(off, [.volume(0), .stop])
        XCTAssertEqual(b.cues.map(\.cue), volume + off, "the Music checkbox off: volume 0, then the shutdown")
        XCTAssertTrue(b.cues.allSatisfy { $0.at == at }, "handed on at the click, not at a later tick")
        XCTAssertEqual(b.m.live.live.musicOn, 0, "the live side changed at once")
        XCTAssertEqual(b.m.result, nil)
    }

    // MARK: 5 · Cancel restores

    func testCancelRestoresTheRecord() throws {
        var record = FerazelPrefs()
        record.graphics = 2
        // Cancel clicked, Esc, ⌘. (Ctrl+.) and ⌘ + the keypad's period — the filter's cancel off the Controls panel
        // (`.PrefDialogFilter`); ⌘⇧. is '>' (the Mac's `charactersIgnoringModifiers` keeps Shift): no cancel.
        for way in 0..<4 {
            let b = try Bench(record: record)
            b.show(.preferences)
            b.clickItem(7)
            b.pick(10, 3)
            XCTAssertNotEqual(b.m.working, b.m.record)
            let d = b.front
            switch way {
            case 0: b.clickItem(2)
            case 1: b.key(0x35)
            case 2:
                b.key(0x2F, [.command, .shift])
                XCTAssertEqual(b.answers, [], "Ctrl+Shift+. is no cancel")
                XCTAssertTrue(b.dialogs.isShowing)
                b.key(0x2F, .command)
            default: b.key(0x41, .command)
            }
            if way > 0 { XCTAssertTrue(d.isHighlighted(2), "the filter's HiliteControl(Cancel, 1), way \(way)") }
            XCTAssertEqual(b.answers, [.cancel], "way \(way)")
            XCTAssertEqual(b.m.result, .cancel)
            XCTAssertEqual(b.m.record, record, "the record unchanged")
            XCTAssertFalse(b.dialogs.isShowing)
            b.ticks(20)
            XCTAssertEqual(b.answers, [.cancel])
        }
    }

    // MARK: 6 · OK returns .ok

    func testOKReturnsOKAndKeepsTheWorkingCopy() throws {
        for way in 0..<3 {
            let b = try Bench()
            b.show(.preferences)
            b.clickItem(8)
            b.pick(11, 3)
            let d = b.front
            switch way {
            case 0: b.clickItem(1)
            case 1: b.key(0x24)                                            // Return: at once (the filter's OK)
            default: b.key(0x4C)                                           // keypad Enter
            }
            XCTAssertEqual(b.answers, [.ok], "way \(way)")
            if way > 0 { XCTAssertTrue(d.isHighlighted(1), "the filter's HiliteControl(OK, 1), way \(way)") }
            XCTAssertEqual(b.m.result, .ok)
            XCTAssertEqual(b.m.record.reuseSavedGames, 1)
            XCTAssertEqual(b.m.record.effects, 3)
            XCTAssertEqual(b.m.record, b.m.working)
            XCTAssertFalse(b.dialogs.isShowing)
        }
    }

    // MARK: 7 · the credits scroll: one pixel every 3 ticks

    static func rgb(_ p: (rgba: [UInt8], width: Int, height: Int), _ x: Int, _ y: Int) -> UInt32 {
        let at = 4 * (y * p.width + x)
        return UInt32(p.rgba[at]) << 16 | UInt32(p.rgba[at + 1]) << 8 | UInt32(p.rgba[at + 2])
    }

    func testCreditsScrollPositionAtFixedTicks() throws {
        let b = try Bench()
        b.credits = CreditsScroll(start: b.now)
        b.show(.credits)
        let d = b.front
        XCTAssertEqual(d.template.id, 600)
        XCTAssertTrue(d.takesAllClicks)
        let strip = try XCTUnwrap(b.rig.driver.dialogPicture(CreditsScroll.stripPicture))
        XCTAssertEqual([strip.width, strip.height], [144, 811])
        let back = try XCTUnwrap(b.rig.driver.dialogPicture(4804))
        // Step k copies the strip with its top at 270 − k, clipped to (34, 120)–(170, 270): at the opening (k 0)
        // nothing of it shows.
        var canvas = try XCTUnwrap(d.canvas)
        XCTAssertEqual(canvas[100, 269], Self.rgb(back, 100, 269))
        for (tick, k) in [(2, 0), (3, 1), (30, 10), (300, 100), (3 * 500 + 1, 500)] {
            b.ticks(tick - Int(b.now &- 5000))
            canvas = try XCTUnwrap(d.canvas)
            if k == 0 {
                XCTAssertEqual(canvas[100, 269], Self.rgb(back, 100, 269), "tick \(tick): not yet moved")
                continue
            }
            for (x, y) in [(34, 269), (100, 269), (169, max(120, 270 - k)), (60, max(120, 270 - (k + 1) / 2))] {
                XCTAssertEqual(canvas[x, y], Self.rgb(strip, x - 34, y - (270 - k)), "tick \(tick) (\(x), \(y))")
            }
            // Outside the clip the background stays — sampled where the strip's pixel would differ from it (right of
            // the clip the strip runs on to x 178; above and below it the strip's rows go on). The left edge is the
            // strip's own (dest left = clip left = 34): nothing of it lies left of the clip.
            let top = 270 - k
            func differing(_ xs: Range<Int>, _ ys: Range<Int>) -> (Int, Int)? {
                for y in ys where y - top >= 0 && y - top < strip.height {
                    for x in xs where Self.rgb(strip, x - 34, y - top) != Self.rgb(back, x, y) { return (x, y) }
                }
                return nil
            }
            let bands: [(String, Range<Int>, Range<Int>)] = [("right", 170..<178, 120..<270), ("above", 34..<170, 0..<120),
                                                             ("below", 34..<170, 270..<276)]
            for (band, xs, ys) in bands {
                let found = differing(xs, ys)
                if k == 500, band != "right" { XCTAssertNotNil(found, "\(band): a differing sample exists at step 500") }
                if let (x, y) = found {
                    XCTAssertEqual(canvas[x, y], Self.rgb(back, x, y), "tick \(tick): \(band) of the clip (\(x), \(y))")
                }
            }
        }
        XCTAssertEqual(b.answers, [])
        // The cycle: step 961 is step 0 again (the rect reset).
        XCTAssertEqual(CreditsScroll(start: 0).dest(now: 3 * 961), CreditsScroll(start: 0).dest(now: 0))

        // Through the real game: the main menu's C opens DLOG 600 over `GameFlow.credits`, scrolled by the game's
        // ticks (the loop wakes 4 times a tick; one null event a tick, one step every 3).
        let dialogs = DialogSystem(text: try BakedTextTests.baked())
        let (game, host) = try WinGameTests.game(dialogs: dialogs)
        WinGameTests.run(game, host) { $0.flow.state == .mainMenu }
        host.inject(.keyDown(keyCode: 0x08, modifiers: [], isRepeat: false))
        WinGameTests.run(game, host, max: 400) { _ in dialogs.isShowing }
        host.inject(.keyUp(keyCode: 0x08))
        let cd = try XCTUnwrap(dialogs.stack.last)
        XCTAssertEqual(cd.template.id, 600)
        let scroll = try XCTUnwrap(game.flow.credits)
        let gstrip = try XCTUnwrap(game.driver.dialogPicture(CreditsScroll.stripPicture))
        let gback = try XCTUnwrap(game.driver.dialogPicture(4804))
        var last = host.ticks
        for _ in 0..<(4 * 100 + 1) {
            last = host.ticks
            game.step()
            host.advance()
        }
        let gk = Int(last &- scroll.start) / CreditsScroll.ticksPerStep
        XCTAssertGreaterThan(gk, 30)
        let gc = try XCTUnwrap(cd.canvas)
        let gtop = 270 - gk
        XCTAssertEqual(gc[100, gtop + 5], Self.rgb(gstrip, 66, 5), "step \(gk): the strip 5 rows down")
        _ = gback
        // Exactly that many steps: at a pixel where strip rows r and r + 1 differ, the canvas holds row r (one step
        // more or fewer would show r + 1 or r − 1 there).
        func px(_ x: Int, _ r: Int) -> UInt32 { Self.rgb(gstrip, x - 34, r) }
        var pin: (x: Int, r: Int)?
        search: for r in 1..<(gk - 1) {
            for x in 34..<170 where px(x, r) != px(x, r + 1) && px(x, r) != px(x, r - 1) {
                pin = (x, r)
                break search
            }
        }
        let at = try XCTUnwrap(pin)
        XCTAssertEqual(gc[at.x, gtop + at.r], Self.rgb(gstrip, at.x - 34, at.r), "exactly \(gk) steps")
        var shown = try XCTUnwrap(game.gameFrame)
        dialogs.draw(into: &shown)
        XCTAssertEqual(game.lastPresented, shown, "the scrolled credits are on screen")
    }

    // MARK: 8 · the credits close on a click inside; outside beeps

    func testCreditsCloseOnClickInsideAndBeepOutside() throws {
        for mute in [false, true] {
            let b = try Bench(mute: mute)
            b.credits = CreditsScroll(start: b.now)
            b.show(.credits)
            let f = b.front.frame
            b.key(0x24)
            b.key(0x35)
            b.ticks(6)
            XCTAssertEqual(b.answers, [], "keys do nothing")
            // The loop reads the live `Button()` at each 3-tick check: a short click between two checks is missed.
            b.click((10, 10))
            b.click(b.canvas(100, 200))
            b.ticks(3)
            XCTAssertEqual(b.beeps, 0, "short clicks released before the check: missed")
            XCTAssertTrue(b.dialogs.isShowing)
            b.dialogs.mouseDown(x: 10, y: 10)                              // held outside: a beep at the next check
            XCTAssertEqual(b.beeps, 0, "the press is seen by the scroll loop's Button(), not at once")
            b.ticks(3)
            XCTAssertEqual(b.beeps, mute ? 0 : 1, "mute \(mute)")
            b.ticks(3)
            XCTAssertEqual(b.beeps, mute ? 0 : 2, "still held: a beep each check")
            b.dialogs.mouseUp(x: 10, y: 10)
            XCTAssertEqual(b.answers, [])
            b.dialogs.mouseDown(x: f.x + 2, y: f.y + 2)                    // the frame: outside the port rect
            b.ticks(3)
            b.dialogs.mouseUp(x: f.x + 2, y: f.y + 2)
            XCTAssertEqual(b.beeps, mute ? 0 : 3)
            XCTAssertTrue(b.dialogs.isShowing)
            let inside = b.canvas(100, 200)                                // held inside: closed at the next check
            b.dialogs.mouseDown(x: inside.x, y: inside.y)
            XCTAssertTrue(b.dialogs.isShowing)
            b.ticks(3)
            XCTAssertEqual(b.answers, [.ok])
            XCTAssertFalse(b.dialogs.isShowing)
            b.dialogs.mouseUp(x: inside.x, y: inside.y)
            XCTAssertEqual(b.beeps, mute ? 0 : 3)
        }
        // No `GameFlow.credits` (a stale request): the scroll starts now.
        let n = try Bench()
        n.show(.credits)
        XCTAssertTrue(n.dialogs.isShowing)
    }

    // MARK: 9 · the credits' pictures under the current clut

    func testCreditsPicturesUnderTheCurrentClut() throws {
        func strip(_ b: Bench) throws -> [UInt32] {
            b.credits = CreditsScroll(start: b.now)
            b.show(.credits)
            b.ticks(300)
            let c = try XCTUnwrap(b.front.canvas)
            return (120..<270).flatMap { y in (34..<170).map { c[$0, y] } }
        }
        let system = try Bench()
        let underSystem = try strip(system)
        let other = try Bench()
        let surface = try XCTUnwrap(other.rig.driver.surface)
        surface.clut = try ColorLUT.load(id: 700, from: other.rig.driver.resources, chain: .frontEnd)
        let underOther = try strip(other)
        XCTAssertNotEqual(underSystem, underOther, "the strip follows the screen's clut")
        // Exactly `dialogPicture` under that clut: the strip and the background.
        let p = try XCTUnwrap(other.rig.driver.dialogPicture(CreditsScroll.stripPicture))
        let c = try XCTUnwrap(other.front.canvas)
        // After 100 steps the strip's top is at 170 (above it, inside the clip, nothing was ever copied).
        for (x, y) in [(34, 200), (90, 180), (169, 269)] {
            XCTAssertEqual(c[x, y], Self.rgb(p, x - 34, y - 170))
        }
        let back = try XCTUnwrap(other.rig.driver.dialogPicture(4804))
        XCTAssertEqual(other.front.pictures[1]?.rgba, back.rgba, "item 1 (PICT 4804) as dialogPicture draws it")
        XCTAssertEqual(c[5, 5], Self.rgb(back, 5, 5))
        XCTAssertEqual(c[199, 275], Self.rgb(back, 199, 275))
        XCTAssertEqual(c[100, 280], 0xDDDDDD, "below the picture: the dctb 600 grey")
    }

    // MARK: 10 · golden 6900 (self-derived; FERAZEL_WRITE_GOLDENS=1 rewrites it)

    @discardableResult
    func golden(_ b: Bench, _ name: String) throws -> [UInt8] {
        var rgba = [UInt8](repeating: 0, count: 640 * 480 * 4)
        for i in stride(from: 3, to: rgba.count, by: 4) { rgba[i] = 255 }
        b.dialogs.draw(into: &rgba)
        let ppm = WinGame.ppm(rgba: rgba)
        let url = WinDialogTests.goldens.appendingPathComponent(name)
        if ProcessInfo.processInfo.environment["FERAZEL_WRITE_GOLDENS"] == "1" {
            try Data(ppm).write(to: url)
        }
        let committed = try [UInt8](Data(contentsOf: url))
        XCTAssertTrue(committed == ppm, "\(name): FNV \(hex(fnv1a64(ppm))) ≠ committed \(hex(fnv1a64(committed)))")
        return rgba
    }

    func testGolden6900() throws {
        // b: Sound & Music — the checked boxes' X, the hidden QuickTime line, Sound Volume's menu open (row 2 under
        // the mouse, the current item checked).
        let s = try Bench()
        s.show(.preferences)
        s.pick(3, 3)
        XCTAssertTrue(s.front.isHidden(13))
        s.click(s.centre(9))
        let row = try XCTUnwrap(s.front.menu).rows[1]
        let over = s.canvas(row.x + 10, row.y + 5)
        s.dialogs.mouseMoved(x: over.x, y: over.y)
        XCTAssertEqual(s.front.menu?.highlighted, 1)
        try golden(s, "Dialog-6900-b.ppm")
        // c: Controls — the dimmed InputSprocket items, an empty selected key field's insertion point (a key with no
        // character on the US layout, `.ConvertKeyName` → ""), the picture.
        let c = try Bench()
        c.show(.preferences)
        c.pick(3, 2)
        c.clickItem(14)
        c.key(0x0A)
        XCTAssertEqual(c.front.text(14), "")
        c.clickItem(14)
        XCTAssertEqual(c.front.selected, 14)
        XCTAssertTrue(c.front.caretVisible)
        try golden(c, "Dialog-6900-c.ppm")

        let b = try Bench()
        b.show(.preferences)
        let rgba = try golden(b, "Dialog-6900.ppm")
        // A few pixels by hand: the frame, the content grey, OK's ring, a checkbox's box, the popup's shadow.
        let f = b.front.frame
        func px(_ x: Int, _ y: Int) -> [UInt8] { Array(rgba[4 * (y * 640 + x) ..< 4 * (y * 640 + x) + 3]) }
        XCTAssertEqual(f, DialogRect(x: 89, y: 97, width: 463, height: 286), "451 × 274 + the frame, centred")
        XCTAssertEqual(px(f.x, f.y), [0, 0, 0])
        XCTAssertEqual(px(b.front.contentX + 1, b.front.contentY + 1), [0xEE, 0xEE, 0xEE])
        let ring = DialogRenderer.ringRect(b.front.item(1)!.rect)
        XCTAssertEqual(px(b.front.contentX + ring.x + ring.width / 2, b.front.contentY + ring.y + 1), [0, 0, 0])
        let box = b.front.item(7)!.rect
        XCTAssertEqual(px(b.front.contentX + box.x + 2, b.front.contentY + box.y + 3), [0, 0, 0], "box outline")
        XCTAssertEqual(px(b.front.contentX + box.x + 5, b.front.contentY + box.y + 6), [0xFF, 0xFF, 0xFF], "unchecked")
        let pop = b.front.item(10)!.rect
        XCTAssertEqual(px(b.front.contentX + pop.x + 10, b.front.contentY + pop.maxY - 1), [0, 0, 0], "shadow")
        XCTAssertEqual(px(b.front.contentX + pop.x + 1, b.front.contentY + pop.maxY - 1), [0xEE, 0xEE, 0xEE])
    }

    // MARK: 11 · Ctrl+P (⌘P) from a level opens Options; the flow holds still and gets the answer

    /// The scripted host with modifier keys held on top of the script's (the Options null events read them).
    @MainActor final class ModifierHost: WinHost {
        let inner: WinScriptedHost
        var held: WinModifiers = []
        init(_ inner: WinScriptedHost) { self.inner = inner }
        var ticks: UInt32 { inner.ticks }
        var seconds: Double { inner.seconds }
        var modifiers: WinModifiers { inner.modifiers.union(held) }
        var wallClock: (secondsSince1904: UInt32, ticks: UInt32) { inner.wallClock }
        func pollEvents(script: Bool) -> [WinEvent] { inner.pollEvents(script: script) }
        func present(rgba: [UInt8]) { inner.present(rgba: rgba) }
        func setCursorVisible(_ visible: Bool) { inner.setCursorVisible(visible) }
        func toggleFullScreen() { inner.toggleFullScreen() }
    }

    /// An audio device that opens every stream and keeps it (nothing plays): the music's `PCMMixer` is the first.
    @MainActor final class KeptStreams: WinAudioDevice {
        var sources: [any PCMPullSource] = []
        func open(_ source: any PCMPullSource) -> Bool {
            sources.append(source)
            return true
        }
        var music: PCMMixer? { sources.first as? PCMMixer }
    }

    func testCtrlPFromALevelOpensOptions() throws {
        // The real game, not headless (its audio through a kept device), so the Music box's cues reach the mixer.
        let dialogs = DialogSystem(text: try BakedTextTests.baked())
        let inner = WinScriptedHost(script: try WinKeyScript(text: "1440 down n"), wallClock: (0x1111_1111, 77))
        let host = ModifierHost(inner)
        let device = KeptStreams()
        let game = WinGame(args: try WinArgs.parse([], environment: [:]), host: host, text: try BakedTextTests.baked(),
                           files: WinFiles(prefsURL: nil, savesFolder: nil), dialogs: dialogs, audio: device)
        try game.boot(dataDirectory: FerazelData.dataDirectory())
        func wakes(_ n: Int) { for _ in 0..<n { game.step(); inner.advance() } }
        func click(_ d: DialogWindow, _ x: Int, _ y: Int) {
            inner.inject(.mouseDown(x: d.contentX + x, y: d.contentY + y))
            inner.inject(.mouseUp(x: d.contentX + x, y: d.contentY + y))
            wakes(1)
        }
        func clickItem(_ d: DialogWindow, _ n: Int) {
            let r = d.item(n)!.rect
            click(d, r.x + r.width / 2, r.y + r.height / 2)
        }
        func pick(_ d: DialogWindow, _ n: Int, _ value: Int) throws {
            clickItem(d, n)
            let row = try XCTUnwrap(d.menu).rows[value - 1]
            click(d, row.x + row.width / 2, row.y + row.height / 2)
        }
        WinGameTests.run(game, inner) { $0.flow.padContext == .playing }
        let free = game.flowSteps
        WinGameTests.run(game, inner) { $0.flowSteps == free + WinGameTests.settleSteps }
        // In a running level ⌘P is the polled chord (⌘ 0x37 + P 0x23, `GameLoopKeys`), not a menu key: Ctrl held, P.
        inner.inject(.keyDown(keyCode: 0x37, modifiers: .command, isRepeat: false))     // Ctrl
        inner.inject(.keyDown(keyCode: 0x23, modifiers: .command, isRepeat: false))     // P
        WinGameTests.run(game, inner, max: 400) { _ in dialogs.isShowing }
        inner.inject(.keyUp(keyCode: 0x23))
        inner.inject(.keyUp(keyCode: 0x37))
        XCTAssertEqual(game.shortcutsTaken, [], "no menu took it")
        let d = try XCTUnwrap(dialogs.stack.last)
        XCTAssertEqual(d.template.id, 6900)
        XCTAssertNotNil(game.flow.prefsDialog)
        let held = game.flowSteps
        // A click on "Reuse saved game files" reaches the flow's model (the services are the flow's).
        clickItem(d, 8)
        wakes(40)
        XCTAssertEqual(game.flow.prefsDialog?.working.reuseSavedGames, 1)
        XCTAssertEqual(game.flowSteps, held, "the flow never ran with Options up")
        var expected = try XCTUnwrap(game.gameFrame)
        dialogs.draw(into: &expected)
        XCTAssertEqual(game.lastPresented, expected, "the dialog drawn into the game's picture")
        // Sound & Music: the Music box off stops the level's music in the mixer at once (the same wake, no tick).
        try pick(d, 3, 3)
        let mixer = try XCTUnwrap(device.music)
        XCTAssertTrue(mixer.isPlaying(voice: 0), "the level's music plays")
        clickItem(d, 8)
        XCTAssertEqual(game.flow.prefsDialog?.live.live.musicOn, 0)
        XCTAssertFalse(mixer.isPlaying(voice: 0), "the Music box's cues reached the audio at once")
        // Controls: an autorepeat reaches the dialog flagged (swallowed); a plain key is taken.
        try pick(d, 3, 2)
        XCTAssertEqual(d.selected, 7)
        inner.inject(.keyDown(keyCode: 0x0C, modifiers: [], isRepeat: true))
        wakes(1)
        XCTAssertEqual(game.flow.prefsDialog?.working.keys[0], 0x56, "an auto-key is swallowed")
        inner.inject(.keyDown(keyCode: 0x0C, modifiers: [], isRepeat: false))
        inner.inject(.keyUp(keyCode: 0x0C))
        wakes(1)
        XCTAssertEqual(game.flow.prefsDialog?.working.keys[0], 0x0C)
        // A modifier held (the Windows key = ⌃) is taken by the game's null events.
        host.held = .control
        wakes(8)
        host.held = []
        XCTAssertEqual(game.flow.prefsDialog?.working.keys[1], 0x3b)
        XCTAssertEqual(d.text(8), "Control")
        // Cancel: the level runs again.
        clickItem(d, 2)
        WinGameTests.run(game, inner, max: 400) { $0.flow.prefsDialog == nil && $0.flow.padContext == .playing }
        XCTAssertFalse(dialogs.isShowing)
        XCTAssertGreaterThan(game.flowSteps, held, "the level runs again")
        game.shutDown()
    }

    // MARK: 12 · Options and Credits take no pad keys (D37)

    func testOptionsAndCreditsIgnorePadKeys() throws {
        let b = try Bench()
        b.show(.preferences)
        for code in [FerazelPadLayout.returnKey, FerazelPadLayout.escapeKey] { b.dialogs.padKeyDown(code) }
        b.ticks(10)
        XCTAssertEqual(b.answers, [], "Game Options: the pad's Return / Esc are not OK / Cancel")
        b.pick(3, 2)
        for code in [FerazelPadLayout.returnKey, FerazelPadLayout.escapeKey] { b.dialogs.padKeyDown(code) }
        XCTAssertEqual(b.m.working.keys, FerazelPrefs.defaultKeys, "Controls: no key captured from the pad")
        // A report over Options is a plain message: the pad's Return reaches it (the Mac's `padKeyPanel`).
        b.key(0x00)
        XCTAssertEqual(b.front.template.id, 200)
        b.dialogs.padKeyDown(FerazelPadLayout.returnKey)
        b.ticks(8)
        XCTAssertEqual(b.front.template.id, 6900)
        XCTAssertTrue(b.dialogs.isShowing)
        XCTAssertEqual(b.answers, [])

        let c = try Bench()
        c.credits = CreditsScroll(start: c.now)
        c.show(.credits)
        for code in [FerazelPadLayout.returnKey, FerazelPadLayout.escapeKey] { c.dialogs.padKeyDown(code) }
        c.ticks(12)
        XCTAssertEqual(c.answers, [])
        XCTAssertTrue(c.dialogs.isShowing)
    }
}

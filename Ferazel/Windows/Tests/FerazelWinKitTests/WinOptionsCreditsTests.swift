@testable import FerazelCore
@testable import FerazelRender
@testable import FerazelWinKit
import Foundation
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
        b.clickItem(26)
        b.clickItem(27)
        XCTAssertEqual(b.m.working.useInputSprocket, 0, "disabled items take no click")
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
        b.modifiers = .control
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
        // Cancel clicked, Esc and ⌘. (Ctrl+.) — the filter's cancel off the Controls panel (`.PrefDialogFilter`).
        for way in 0..<3 {
            let b = try Bench(record: record)
            b.show(.preferences)
            b.clickItem(7)
            b.pick(10, 3)
            XCTAssertNotEqual(b.m.working, b.m.record)
            switch way {
            case 0: b.clickItem(2)
            case 1: b.key(0x35)
            default: b.key(0x2F, .command)
            }
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
            switch way {
            case 0: b.clickItem(1)
            case 1: b.key(0x24)                                            // Return: at once (the filter's OK)
            default: b.key(0x4C)                                           // keypad Enter
            }
            XCTAssertEqual(b.answers, [.ok], "way \(way)")
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
            XCTAssertEqual(canvas[170, 260], Self.rgb(back, 170, 260), "right of the clip: the background")
            XCTAssertEqual(canvas[33, 260], Self.rgb(back, 33, 260), "left of the clip")
            XCTAssertEqual(canvas[100, 119], Self.rgb(back, 100, 119), "above the clip")
        }
        XCTAssertEqual(b.answers, [])
        // The cycle: step 961 is step 0 again (the rect reset).
        XCTAssertEqual(CreditsScroll(start: 0).dest(now: 3 * 961), CreditsScroll(start: 0).dest(now: 0))
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
            b.click((10, 10))                                              // outside: a beep at the next step
            XCTAssertEqual(b.beeps, 0, "the click is seen by the scroll loop's Button(), not at once")
            b.ticks(3)
            XCTAssertEqual(b.beeps, mute ? 0 : 1, "mute \(mute)")
            XCTAssertEqual(b.answers, [])
            b.click((f.x + 2, f.y + 2))                                    // the frame: outside the port rect
            b.ticks(3)
            XCTAssertEqual(b.beeps, mute ? 0 : 2)
            XCTAssertTrue(b.dialogs.isShowing)
            b.click(b.canvas(100, 200))                                    // inside: closed at the next step
            XCTAssertTrue(b.dialogs.isShowing)
            b.ticks(3)
            XCTAssertEqual(b.answers, [.ok])
            XCTAssertFalse(b.dialogs.isShowing)
            XCTAssertEqual(b.beeps, mute ? 0 : 2)
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

    func testGolden6900() throws {
        let b = try Bench()
        b.show(.preferences)
        var rgba = [UInt8](repeating: 0, count: 640 * 480 * 4)
        for i in stride(from: 3, to: rgba.count, by: 4) { rgba[i] = 255 }
        b.dialogs.draw(into: &rgba)
        let ppm = WinGame.ppm(rgba: rgba)
        let url = WinDialogTests.goldens.appendingPathComponent("Dialog-6900.ppm")
        if ProcessInfo.processInfo.environment["FERAZEL_WRITE_GOLDENS"] == "1" {
            try Data(ppm).write(to: url)
        }
        let committed = try [UInt8](Data(contentsOf: url))
        XCTAssertTrue(committed == ppm, "Dialog-6900: FNV \(hex(fnv1a64(ppm))) ≠ committed \(hex(fnv1a64(committed)))")
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

    func testCtrlPFromALevelOpensOptions() throws {
        let dialogs = DialogSystem(text: try BakedTextTests.baked())
        let (game, host) = try WinGameTests.game(script: "1440 down n", dialogs: dialogs)
        WinGameTests.run(game, host) { $0.flow.padContext == .playing }
        let free = game.flowSteps
        WinGameTests.run(game, host) { $0.flowSteps == free + WinGameTests.settleSteps }
        // In a running level ⌘P is the polled chord (⌘ 0x37 + P 0x23, `GameLoopKeys`), not a menu key: Ctrl held, P.
        host.inject(.keyDown(keyCode: 0x37, modifiers: .command, isRepeat: false))      // Ctrl
        host.inject(.keyDown(keyCode: 0x23, modifiers: .command, isRepeat: false))      // P
        WinGameTests.run(game, host, max: 400) { _ in dialogs.isShowing }
        host.inject(.keyUp(keyCode: 0x23))
        host.inject(.keyUp(keyCode: 0x37))
        XCTAssertEqual(game.shortcutsTaken, [], "no menu took it")
        let d = try XCTUnwrap(dialogs.stack.last)
        XCTAssertEqual(d.template.id, 6900)
        XCTAssertNotNil(game.flow.prefsDialog)
        let held = game.flowSteps
        // A click on "Reuse saved game files" reaches the flow's model (the services are the flow's).
        let r = try XCTUnwrap(d.item(8)).rect
        let p = (d.contentX + r.x + r.width / 2, d.contentY + r.y + r.height / 2)
        host.inject(.mouseDown(x: p.0, y: p.1))
        host.inject(.mouseUp(x: p.0, y: p.1))
        for _ in 0..<40 { game.step(); host.advance() }
        XCTAssertEqual(game.flow.prefsDialog?.working.reuseSavedGames, 1)
        XCTAssertEqual(game.flowSteps, held, "the flow never ran with Options up")
        var expected = try XCTUnwrap(game.gameFrame)
        dialogs.draw(into: &expected)
        XCTAssertEqual(game.lastPresented, expected, "the dialog drawn into the game's picture")
        // Esc on Game Options: Cancel; the level runs again.
        host.inject(.keyDown(keyCode: 0x35, modifiers: [], isRepeat: false))
        host.inject(.keyUp(keyCode: 0x35))
        WinGameTests.run(game, host, max: 400) { $0.flow.prefsDialog == nil && $0.flow.padContext == .playing }
        XCTAssertFalse(dialogs.isShowing)
        XCTAssertGreaterThan(game.flowSteps, held, "the level runs again")
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

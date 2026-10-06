@testable import BTXWinKit
import BubbleTroubleCore
import BubbleTroubleRender
import Foundation
import XCTest

// MARK: - Fixture

/// The real BTX data (`HECTORKIT_DATA_BTX`; XCTSkip when unset) and the baked fonts (`Resources/Fonts`, by #filePath).
enum DialogFixture {
    static let variable = "HECTORKIT_DATA_BTX"
    nonisolated(unsafe) private static var cached: (BTXGameData, ArtBank)?
    nonisolated(unsafe) private static var cachedRenderer: DialogRenderer?

    static var packageDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    static func data() throws -> (BTXGameData, ArtBank) {
        if let c = cached { return c }
        guard let path = ProcessInfo.processInfo.environment[variable], !path.isEmpty else {
            throw XCTSkip("\(variable) unset — set it to Bubble Trouble X.app/Contents/Resources")
        }
        let data = try BTXGameData(resourcesDirectory: URL(fileURLWithPath: path))
        let c = (data, ArtBank(data: data))
        cached = c
        return c
    }

    static func renderer() throws -> DialogRenderer {
        if let r = cachedRenderer { return r }
        let r = try DialogRenderer(fontsDirectory: packageDirectory.appendingPathComponent("Resources/Fonts"))
        cachedRenderer = r
        return r
    }

    static func system() throws -> (DialogSystem, DialogRecorder) {
        let (data, art) = try data()
        let s = DialogSystem(data: data, art: art, renderer: try renderer())
        let r = DialogRecorder()
        s.delegate = r
        return (s, r)
    }
}

final class DialogRecorder: DialogSystemDelegate {
    var sounds: [(cue: SoundCue, volume: Int?)] = []
    var live: [(prefs: BTXPrefs, music: Bool)] = []
    var beeps = 0
    var modalChanges = 0

    func dialogPlaySound(_ cue: SoundCue, volumeOverride: Int?) { sounds.append((cue, volumeOverride)) }
    func dialogLivePrefs(_ prefs: BTXPrefs, updateMusic: Bool) { live.append((prefs, updateMusic)) }
    func dialogBeep() { beeps += 1 }
    func dialogModalStateChanged() { modalChanges += 1 }
    var slots: [Int] { sounds.map(\.cue.slot) }
}

/// Input helpers (canvas coordinates; Mac virtual key codes).
extension DialogSystem {
    static let kReturn: UInt16 = 0x24, kEnter: UInt16 = 0x4c, kEscape: UInt16 = 0x35, kDelete: UInt16 = 0x33
    static let kTab: UInt16 = 0x30, kLeft: UInt16 = 0x7b, kRight: UInt16 = 0x7c, kUp: UInt16 = 0x7e, kDown: UInt16 = 0x7d
    static let kPeriod: UInt16 = 0x2f

    func press(_ code: UInt16, _ chars: String = "", command: Bool = false, shift: Bool = false) {
        keyDown(DialogKeyEvent(keyCode: code, characters: chars, command: command, shift: shift))
    }

    /// Types `s` as text-input characters (key code unknown to the US table).
    func type(_ s: String) {
        for c in s { keyDown(DialogKeyEvent(keyCode: 0xFFFF, characters: String(c))) }
    }

    func ticks(_ n: Int, held: Set<UInt16> = []) { for _ in 0..<n { tick(heldKeys: held) } }

    /// The canvas point at the centre of `item` of the front dialog.
    func centre(of item: Int, in d: DialogWindow? = nil) -> (x: Int, y: Int) {
        let w = d ?? frontDialog!
        let r = w.item(item)!.rect
        return (w.originX + r.x + r.width / 2, w.originY + r.y + r.height / 2)
    }

    func click(_ item: Int) {
        let p = centre(of: item)
        mouseDown(x: p.x, y: p.y)
        mouseUp(x: p.x, y: p.y)
    }
}

// MARK: - Templates and layout

final class DialogLayoutTests: XCTestCase {
    func testEveryTableDialogParsesFromItsDLOGAndDITL() throws {
        let (data, _) = try DialogFixture.data()
        // (id, width, height, item count) straight from the shipped DLOGs / DITLs.
        let expected: [(Int, Int, Int, Int)] = [
            (160, 350, 104, 5), (190, 450, 350, 25), (200, 285, 129, 5), (290, 160, 234, 1), (291, 331, 356, 1),
            (1000, 329, 91, 4), (1001, 300, 104, 4), (3000, 286, 244, 4), (3001, 286, 244, 4),
        ]
        for (id, w, h, n) in expected {
            let t = try XCTUnwrap(DialogResources.dialog(id, data: data), "DLOG \(id)")
            XCTAssertEqual(t.width, w, "DLOG \(id) width")
            XCTAssertEqual(t.height, h, "DLOG \(id) height")
            XCTAssertEqual(t.items.count, n, "DLOG \(id) items")
            XCTAssertNil(t.alertStages)
            XCTAssertEqual(t.position & 0xFFFF, id == 1000 ? 0xa80a : t.position, "DLOG \(id)")
        }
    }

    func testDLOG1000ItemRects() throws {
        let (data, _) = try DialogFixture.data()
        let t = try XCTUnwrap(DialogResources.dialog(1000, data: data))
        XCTAssertEqual(t.position, 0xa80a)
        let items = t.items
        XCTAssertEqual(items[0], DialogItem(number: 1, rect: DialogRect(x: 240, y: 58, width: 75, height: 20),
                                            kind: .button, enabled: true, text: "OK!"))
        XCTAssertEqual(items[1], DialogItem(number: 2, rect: DialogRect(x: 78, y: 60, width: 138, height: 16),
                                            kind: .editText, enabled: true, text: ""))
        XCTAssertEqual(items[2].kind, .staticText)
        XCTAssertEqual(items[2].rect, DialogRect(x: 78, y: 12, width: 238, height: 42))
        XCTAssertEqual(items[2].text, "You made it into the High Scores!  Please enter your name:")
        XCTAssertEqual(items[3].kind, .picture(pict: 999))
        XCTAssertFalse(items[3].enabled)
    }

    func testDLOG190ItemsAndAppendedAreaNumbering() throws {
        let (data, _) = try DialogFixture.data()
        let t = try XCTUnwrap(DialogResources.dialog(190, data: data))
        XCTAssertEqual(t.items.map(\.kind).prefix(4), [.button, .button, .button, .button])
        XCTAssertEqual(t.items[0].text, "Save")
        XCTAssertEqual(t.items[0].rect, DialogRect(x: 360, y: 310, width: 75, height: 20))
        XCTAssertEqual(t.items[4].kind, .user)
        XCTAssertTrue(t.items[4].enabled)
        XCTAssertEqual(t.items[23].kind, .picture(pict: 7000))
        let sound = try XCTUnwrap(DialogResources.items(ditl: 191, data: data, firstNumber: 26))
        XCTAssertEqual(sound.map(\.number), [26, 27, 28])
        XCTAssertEqual(sound[0].kind, .control(cntl: 1001))
        XCTAssertEqual(sound[2], DialogItem(number: 28, rect: DialogRect(x: 200, y: 110, width: 200, height: 18),
                                            kind: .checkBox, enabled: true, text: "Title screen music"))
        let keys = try XCTUnwrap(DialogResources.items(ditl: 192, data: data, firstNumber: 26))
        XCTAssertEqual(keys.count, 18)
        XCTAssertEqual(keys[7].kind, .control(cntl: 1009))
        let popup = try XCTUnwrap(DialogResources.popupControl(1001, data: data))
        XCTAssertEqual(popup, DialogPopupTemplate(title: "Sound FX", titleWidth: 70, menuID: 1001))
        XCTAssertEqual(DialogResources.menuItems(1000, data: data), ["Off", "Quiet", "Medium", "Full"])
    }

    func testAlertTemplates201And202() throws {
        let (data, _) = try DialogFixture.data()
        let a201 = try XCTUnwrap(DialogResources.alert(201, data: data))
        XCTAssertEqual(a201.alertStages, 0x5555)
        XCTAssertEqual(a201.width, 280)
        XCTAssertEqual(a201.height, 106)
        XCTAssertEqual(a201.items[0].rect, DialogRect(x: 190, y: 70, width: 75, height: 20))
        XCTAssertEqual(a201.items[1].text, "Please make the set name less than 10 characters long.")
        let a202 = try XCTUnwrap(DialogResources.alert(202, data: data))
        XCTAssertEqual(a202.items[0].text, "Cancel")
        XCTAssertEqual(a202.items[1].text, "You can't have more than 20 key sets.")
        // Every ALRT the 1.1 code can show loads.
        for id in [129, 201, 202, 203, 208, 215, 217, 1920, 8000, 8001, 9000, 9001, 9002, 9003, 9004, 9005] {
            XCTAssertNotNil(DialogResources.alert(id, data: data), "ALRT \(id)")
        }
    }

    func testPlacementIsCentredAThirdDownTheCanvas() throws {
        let (s, _) = try DialogFixture.system()
        s.present(.highScoreNameDialog(defaultName: "Ben"), prefs: .defaults) { _ in }
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(d.originX, 156)                                   // (640 − 329) / 2 = 155.5 → 156
        XCTAssertEqual(d.originY, 130)                                   // (480 − 91) / 3 = 129.67 → 130
        XCTAssertEqual(DialogSystem.origin(width: 450, height: 350).x, 95)
        XCTAssertEqual(DialogSystem.origin(width: 450, height: 350).y, 43)
    }

    func testParamTextSubstitution() throws {
        let (s, _) = try DialogFixture.system()
        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { _ in }
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(d.text(3), "Start at which level (2 - 37)?\nHigh Scores will be disabled.")
        XCTAssertEqual(d.text(4), "2")                                   // `SetDialogItemText(4, "2")` over "^0"
        s.alert(129, params: ["Couldn't load the orbit data."])
        XCTAssertEqual(s.frontDialog?.text(2), "Couldn't load the orbit data.")
        s.alert(9002, params: ["Oops", "PICT", "128"])
        XCTAssertEqual(s.frontDialog?.text(3), "Resource type: PICT   Resource ID: 128")
    }
}

// MARK: - Keys

final class DialogKeyTests: XCTestCase {
    func testClassicCharCodes() {
        func c(_ code: UInt16, _ chars: String = "", shift: Bool = false) -> UInt8 {
            DialogKey(DialogKeyEvent(keyCode: code, characters: chars, shift: shift)).char
        }
        XCTAssertEqual(c(0x24), 0x0d)
        XCTAssertEqual(c(0x4c), 0x03)
        XCTAssertEqual(c(0x35), 0x1b)
        XCTAssertEqual(c(0x33), 0x08)
        XCTAssertEqual(c(0x7b), 0x1c)
        XCTAssertEqual(c(0x7c), 0x1d)
        XCTAssertEqual(c(0x7e), 0x1e)
        XCTAssertEqual(c(0x7d), 0x1f)
        XCTAssertEqual(c(0x30), 0x09)
        XCTAssertEqual(c(0x00), UInt8(ascii: "a"))                      // US layout from the key code
        XCTAssertEqual(c(0x00, shift: true), UInt8(ascii: "A"))
        XCTAssertEqual(c(0x00, "q"), UInt8(ascii: "q"))                 // the host's text wins
        XCTAssertEqual(c(0xFFFF, "é"), 0x8E)                             // MacRoman byte
        XCTAssertEqual(c(0xFFFF, "€"), 0xDB)
        XCTAssertEqual(c(0xFFFF, "😀"), 0)                               // no MacRoman byte: dropped by TextEdit
        let cmdPeriod = DialogKey(DialogKeyEvent(keyCode: 0x2f, command: true))
        XCTAssertEqual(cmdPeriod.char, UInt8(ascii: "."))
        XCTAssertEqual(DialogKey(DialogKeyEvent(keyCode: 0x0c, command: true)).commandUppercased, UInt8(ascii: "Q"))
        XCTAssertTrue(DialogKeyEvent.typesText(keyCode: 0x00))
        XCTAssertFalse(DialogKeyEvent.typesText(keyCode: 0x24))
    }

    func testStringToNum() {
        XCTAssertEqual(DialogSystem.stringToNum(""), 0)
        XCTAssertEqual(DialogSystem.stringToNum("15"), 15)
        XCTAssertEqual(DialogSystem.stringToNum("-3"), -3)
        XCTAssertEqual(DialogSystem.stringToNum("+7"), 7)
        XCTAssertEqual(DialogSystem.stringToNum("1a"), 59)                // no validation: ('a' − '0') = 49
        XCTAssertEqual(DialogSystem.stringToNum("99999999999"), Int(Int32(truncatingIfNeeded: 99_999_999_999 as Int64)))
    }
}

// MARK: - DLOG 160 Level Select

final class DialogLevelSelectTests: XCTestCase {
    func testTypingDigitsAndReturnAnswersThenHoldsUntilClose() throws {
        let (s, r) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { answers.append($0) }
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(d.defaultItem, 1)
        XCTAssertEqual(d.focusedEditItem, 4)
        XCTAssertEqual(d.selection, 0..<1)                               // "2" all selected
        s.type("1")                                                      // replaces the selection
        s.type("x")                                                      // `_LevelSelectFilter`: beep, eaten
        XCTAssertEqual(r.beeps, 1)
        s.type("5")
        XCTAssertEqual(d.text(4), "15")
        s.press(DialogSystem.kDelete)
        XCTAssertEqual(d.text(4), "1")
        s.type("2")
        s.press(DialogSystem.kReturn)
        XCTAssertEqual(d.flashItem, 1)
        s.ticks(7)
        XCTAssertTrue(answers.isEmpty)                                   // `Delay(8)`
        s.type("9")                                                      // blocked while flashing
        s.ticks(1)
        XCTAssertEqual(answers, [.levelSelect(typed: 12)])
        XCTAssertEqual(d.text(4), "12")
        XCTAssertTrue(s.isShowing)
        XCTAssertFalse(s.isModal)                                        // the front end's 30-tick hold
        s.type("3")
        XCTAssertEqual(d.text(4), "12")                                  // keys eaten after the answer
        s.close()
        XCTAssertFalse(s.isShowing)
        XCTAssertGreaterThanOrEqual(r.modalChanges, 3)
    }

    func testRejectedLevelShowsZeroAndEscCancels() throws {
        let (s, _) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { answers.append($0) }
        s.type("99")
        s.press(DialogSystem.kEnter)
        s.ticks(8)
        XCTAssertEqual(answers, [.levelSelect(typed: 99)])
        XCTAssertEqual(s.frontDialog?.text(4), "0")
        s.close()

        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { answers.append($0) }
        s.press(DialogSystem.kEscape)
        s.ticks(8)
        XCTAssertEqual(answers.last, .levelSelect(typed: nil))
        s.close()

        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { answers.append($0) }
        s.press(DialogSystem.kPeriod, command: true)                     // ⌘. (Ctrl+. on Windows)
        s.ticks(8)
        XCTAssertEqual(answers.count, 3)
        XCTAssertEqual(answers.last, .levelSelect(typed: nil))
    }

    func testMouseOnButtonsAnswers() throws {
        let (s, r) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { answers.append($0) }
        // Press on Go, slide off, release: nothing (TrackControl).
        let go = s.centre(of: 1)
        s.mouseDown(x: go.x, y: go.y)
        XCTAssertEqual(s.frontDialog?.tracking, .control(item: 1, inside: true))
        s.mouseMoved(x: go.x, y: go.y + 40)
        s.mouseUp(x: go.x, y: go.y + 40)
        XCTAssertTrue(answers.isEmpty)
        // A click outside the dialog is refused with a beep, and so is one on the menu strip.
        s.mouseDown(x: 5, y: 5)
        s.mouseDown(x: 300, y: -10)
        XCTAssertEqual(r.beeps, 2)
        s.click(1)
        XCTAssertEqual(answers, [.levelSelect(typed: 2)])
        s.close()
        s.present(.levelSelectDialog(max: 37), prefs: .defaults) { answers.append($0) }
        s.click(2)
        XCTAssertEqual(answers.last, .levelSelect(typed: nil))
    }
}

// MARK: - DLOG 1000 High Score Name

final class DialogHighScoreNameTests: XCTestCase {
    func testNameFilterSoundsBeepsAndOK() throws {
        let (s, r) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.highScoreNameDialog(defaultName: "Andrew"), prefs: .defaults) { answers.append($0) }
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(d.text(2), "Andrew")
        XCTAssertEqual(d.selection, 0..<6)                               // `SelectDialogItemText(2, 0, 0x400)`
        s.type("Bubblemast")                                             // 10 characters, the first replacing all
        XCTAssertEqual(d.text(2), "Bubblemast")
        XCTAssertEqual(r.sounds.map(\.cue), Array(repeating: SoundCue(slot: 1, priority: 0x14, delayFrames: 0), count: 10))
        s.type("e")                                                      // ≥ 10 and no selection → SysBeep, swallowed
        XCTAssertEqual(r.beeps, 1)
        XCTAssertEqual(d.text(2), "Bubblemast")
        XCTAssertEqual(r.sounds.count, 10)
        s.press(DialogSystem.kLeft)                                      // arrows: snd 6, passed on
        s.press(DialogSystem.kDelete)                                    // backspace: snd 6, deletes the s before the t
        XCTAssertEqual(r.slots.suffix(2), [6, 6])
        XCTAssertEqual(d.text(2), "Bubblemat")
        s.press(DialogSystem.kEscape)                                    // no Cancel item: nothing
        s.ticks(10)
        XCTAssertTrue(answers.isEmpty)
        XCTAssertTrue(s.isShowing)
        s.press(DialogSystem.kReturn)
        XCTAssertEqual(d.flashItem, 1)
        s.ticks(8)
        XCTAssertEqual(answers, [.highScoreName("Bubblemat")])
        XCTAssertFalse(s.isShowing)
    }

    func testTypingOverASelectionAtTenCharactersIsAllowed() throws {
        let (s, r) = try DialogFixture.system()
        s.present(.highScoreNameDialog(defaultName: "0123456789"), prefs: .defaults) { _ in }
        s.type("Z")                                                      // selection non-empty → snd 1, replaces
        XCTAssertEqual(s.frontDialog?.text(2), "Z")
        XCTAssertEqual(r.beeps, 0)
        XCTAssertEqual(r.slots, [1])
    }

    func testOKByMouseAndCaretByClick() throws {
        let (s, _) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.highScoreNameDialog(defaultName: "Andrew"), prefs: .defaults) { answers.append($0) }
        let d = try XCTUnwrap(s.frontDialog)
        // Click at the far left of the field: the caret goes before the first character.
        let field = d.item(2)!.rect
        s.mouseDown(x: d.originX + field.x + 1, y: d.originY + field.y + 8)
        s.mouseUp(x: d.originX + field.x + 1, y: d.originY + field.y + 8)
        XCTAssertEqual(d.selection, 0..<0)
        s.type("X")
        XCTAssertEqual(d.text(2), "XAndrew")
        // Drag from the start to past the end selects everything.
        s.mouseDown(x: d.originX + field.x + 1, y: d.originY + field.y + 8)
        s.mouseMoved(x: d.originX + field.maxX - 2, y: d.originY + field.y + 8)
        s.mouseUp(x: d.originX + field.maxX - 2, y: d.originY + field.y + 8)
        XCTAssertEqual(d.selection, 0..<7)
        s.click(1)
        XCTAssertEqual(answers, [.highScoreName("XAndrew")])
    }
}

// MARK: - DLOG 1001, 290/291, 3000/3001, alerts

final class DialogSimpleTests: XCTestCase {
    func testHiScoreEraseKeysAndMouse() throws {
        let (s, r) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.hiScoreEraseDialog, prefs: .defaults) { answers.append($0) }
        XCTAssertEqual(r.sounds.first?.cue, SoundCue(slot: 0x16, priority: 10, delayFrames: 0))
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertEqual(d.defaultItem, 2)
        XCTAssertEqual(d.cancelItem, 2)
        XCTAssertEqual(d.outlines, [1])                                  // `_OutlineItem(1)` on Reset
        s.press(DialogSystem.kReturn)                                    // Return means Cancel here
        XCTAssertEqual(d.flashItem, 2)
        s.ticks(8)
        XCTAssertEqual(answers, [.hiScoreErase(reset: false)])
        XCTAssertFalse(s.isShowing)
        s.present(.hiScoreEraseDialog, prefs: .defaults) { answers.append($0) }
        s.press(0x0c, command: true)                                     // ⌘Q eaten
        s.ticks(8)
        XCTAssertEqual(answers.count, 1)
        s.click(1)
        XCTAssertEqual(answers.last, .hiScoreErase(reset: true))
        s.present(.hiScoreEraseDialog, prefs: .defaults) { answers.append($0) }
        s.press(DialogSystem.kEscape)
        s.ticks(8)
        XCTAssertEqual(answers.last, .hiScoreErase(reset: false))
    }

    func testPoemAndQuoteEndOnAnyPress() throws {
        let (s, r) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        s.present(.modalDialog(id: 290), prefs: .defaults) { answers.append($0) }
        XCTAssertNotNil(s.frontDialog?.pictures[1])                      // PICT 8001
        s.press(0x00)
        XCTAssertEqual(answers, [.dismissed])
        XCTAssertFalse(s.isShowing)
        s.present(.modalDialog(id: 291), prefs: .defaults) { answers.append($0) }
        s.mouseDown(x: 2, y: 2)                                          // anywhere, even outside
        XCTAssertEqual(answers, [.dismissed, .dismissed])
        XCTAssertEqual(r.beeps, 0)
    }

    func testBirthdaysUntilItemOne() throws {
        let (s, _) = try DialogFixture.system()
        var answers: [DialogSystem.Answer] = []
        for id in [3000, 3001] {
            s.present(.modalDialog(id: id), prefs: .defaults) { answers.append($0) }
            s.press(0x00)
            s.press(DialogSystem.kEscape)
            s.ticks(10)
            XCTAssertTrue(s.isShowing)
            s.press(DialogSystem.kReturn)
            s.ticks(8)
            XCTAssertFalse(s.isShowing)
        }
        s.present(.modalDialog(id: 3000), prefs: .defaults) { answers.append($0) }
        s.click(1)
        XCTAssertEqual(answers, [.dismissed, .dismissed, .dismissed])
    }

    func testAlertBeepsAndDismissesOnItemOne() throws {
        let (s, r) = try DialogFixture.system()
        var done = 0
        s.alert(201) { done += 1 }
        XCTAssertEqual(r.beeps, 1)                                        // stage word 0x5555 → `SysBeep`
        let d = try XCTUnwrap(s.frontDialog)
        XCTAssertNotNil(d.alertIcon)
        XCTAssertEqual(d.defaultItem, 1)
        s.press(DialogSystem.kReturn)
        s.ticks(8)
        XCTAssertEqual(done, 1)
        XCTAssertFalse(s.isShowing)
    }

    func testNonDialogRequestsAreRefused() throws {
        let (s, _) = try DialogFixture.system()
        XCTAssertFalse(s.present(.beep, prefs: .defaults) { _ in })
        XCTAssertFalse(s.isShowing)
    }

    func testDeliverHandsPrefsToTheFrontEnd() throws {
        let (data, _) = try DialogFixture.data()
        let fe = FrontEnd(data: data, prefs: .defaults, highScores: .empty, registeredName: "Ben", today: { (3, 3) })
        var p = BTXPrefs.defaults
        p.showStars.toggle()
        _ = DialogSystem.deliver(.prefs(p), to: fe)
        XCTAssertEqual(fe.prefs, p)                                      // `prefsDialogDone(prefs:)`
    }
}

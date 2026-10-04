import AppKit
import BubbleTroubleCore
import BubbleTroubleRender

/// The original's Carbon dialogs and alerts (plan A4), rebuilt from their `DLOG`/`ALRT`/`DITL` resources by
/// `CarbonDialog`, driven exactly as the 1.1 code drives them, and answered back into `FrontEnd`.
///
/// Dialogs (front-end inventory §1d):
/// | DLOG | request | code | behaviour transcribed |
/// |---|---|---|---|
/// | 160 Level Select | `.levelSelectDialog(max:)` | `_DoLevelSelect @ 0000d31e`, `_LevelSelectFilter @ 0000dce3` | `ParamText(^0 = max)`; default item 1; edit 4 = "2", all selected; digits / Delete pass, any other key beeps; Return/Enter → "Go go go!", Esc / ⌘. → Cancel (flashed); OK shows the validated level (0 when rejected) and stays up until `.closeDialog` |
/// | 190 Preferences | `.prefsDialog` | `_PrefsDialog @ 0000ea93` | `BTXPrefsWindow` |
/// | 200 Key set name | (inside prefs) | `_PrefsDialog` case 0x1f, `_NewSetDlgFilter @ 0000dc38` | `BTXPrefsWindow` |
/// | 290 / 291 | `.modalDialog(id:)` | `_DisplayPoem @ 0000ce2b` / `_DisplayQuote @ 0000ceb4` | drawn, then `_WaitUntilKeyOrMousePress` (any key or click anywhere) |
/// | 1000 High Score Name | `.highScoreEntry(rank:)` | `_CheckHiScore @ 00024b34`, `_HiScoreNameFilter @ 00024890` | default 1; edit 2 = slot-0 name, selected 0…0x400; Return/Enter → "OK!" (flashed); arrows / Delete → snd 6, a key when the text is ≥ 10 characters and nothing is selected → `SysBeep` (swallowed), else snd 1 (priority 0x14) |
/// | 1001 High Score Erase | `.hiScoreEraseDialog` | `_HiScoreEraseDialog @ 00024670`, `_HiScoreEraseFilter @ 0000dd8d` | snd 22; default AND cancel item 2; Return / Enter / Esc / ⌘. → Cancel (flashed); `_OutlineItem(1)` ring on Reset on every update |
/// | 3000 / 3001 birthdays | `.modalDialog(id:)` | `_DoBirthdaysCheck @ 0000c78e` | default 1, no filter, until item 1 |
///
/// Sounds the FRONT END already emits are not repeated here: snd 22 for level select (`_DoLevelSelect`, C6), snd 13
/// before DLOG 1000 and snd 15 after it (`_CheckHiScore`, C7's screen).
///
/// Alerts (amendment R10 — every `ALRT` the 1.1 code shows, with its call site; `alert(_:params:)` shows any of them):
/// | ALRT | call site | reachable in the replica |
/// |---|---|---|
/// | 129 `^0` (Quit) | `_DeathAlert @ 0000c6f2` ← `_LoadOrbitData`, `_DrawPICTBasic`/`_DrawPICTResource`/`_DrawPictInRect` (STR# 128 #6), `_InitMac` resource-file open (#15) — `StopAlert`, then `_CleanUp` + `ExitToShell` | data failures only |
/// | 201 set name ≥ 10 | `_PrefsDialog` case 0x1f, name longer than 10 bytes (`NoteAlert(0xc9)`) | yes (`BTXPrefsWindow`) |
/// | 202 > 20 sets | `_PrefsDialog` case 0x1f, `short 0x37 ≥ 20` (`NoteAlert(0xca)`) | yes (`BTXPrefsWindow`) |
/// | 203 next launch | `_PrefsDialog` Misc items 0x19 ("OS 9 Drawing") / 0x1f (depth switch), once each (`NoteAlert(0xcb)`) | no: DITL 193 has neither item on OS X |
/// | 208 timing | `_DisplayOneTime @ 00017244` ← `_FinishTimeCheck` (no caller in 1.1) | no |
/// | 215 FSSpec error | `_InitMac` resource-file open (`StopAlert(0xd7)`) | data failures only |
/// | 217 CopyBits bounds | `_CheckValidity @ 000054f2` ← `_InitMac` | no |
/// | 1920 shift held | `_CheckQDOverride @ 0000cff2` (no caller in 1.1) | no |
/// | 8000 debug | `_DebugValues @ 00014373` | no |
/// | 8001 error | `_StdError @ 00014741` (e.g. "Can't plot cicn for prefs dialog.") | data failures only |
/// | 9000 / 9001 / 9002 / 9003 / 9004 / 9005 | `_LocationErrorInt` / `_ResultErrorInt` / `_ResourceError` / `_OutOfMemory` / `_LocationError` / `_ResultError` (`@ 00014373…00014741`) | data failures only |
/// | 132, 204, 205, 206, 209–214, 216, 218 | none in the 1.1 UB binary (older builds, OS 9 paths) | no |
@MainActor final class BTXDialogs {
    /// What a dialog answered; `deliver(_:to:)` hands it to the front end.
    enum Answer: Equatable {
        /// DLOG 160: the number in the field on OK (`StringToNum`), nil for Cancel.
        case levelSelect(typed: Int?)
        /// DLOG 1000: the field's text on OK.
        case highScoreName(String)
        /// DLOG 1001: Reset (true) or Cancel.
        case hiScoreErase(reset: Bool)
        /// DLOG 190: the prefs after Save, or the prefs as they were at open after Cancel.
        case prefs(BTXPrefs)
        /// DLOG 290 / 291 / 3000 / 3001 dismissed.
        case dismissed
    }

    let data: BTXGameData
    let art: ArtBank
    /// `_PlayMySnd` from inside a dialog. The `Int?` is a stand-in for short 0x33 (the sound-effects level) for
    /// this one play — the prefs Music popup plays snd 13 at the MUSIC level (`_PrefsDialog` case 0x1b).
    var playSound: (SoundCue, Int?) -> Void = { _, _ in }
    /// `_UpdateSoundVol` / `_UpdateMusicVolume` while the prefs dialog is up: the edited prefs, live.
    var livePrefs: (BTXPrefs) -> Void = { _ in }

    /// Dialogs and alerts on screen, front last.
    private(set) var stack: [CarbonDialog] = []
    /// The dialog `.closeDialog` disposes (DLOG 160 after the front end's 30-tick hold).
    private var pendingClose: CarbonDialog?
    private var monitor: Any?
    private var nullTimer: Timer?
    private var keyObserver: NSObjectProtocol?

    /// True while any dialog is up — A3 disables the menu bar's items then (Carbon `ModalDialog` is app-modal).
    var isShowing: Bool { !stack.isEmpty }

    init(data: BTXGameData, art: ArtBank) {
        self.data = data
        self.art = art
    }

    static func level(fullScreen: Bool) -> NSWindow.Level {
        // `_CheckHiScore` / `_PrefsDialog`: the dialog's window group at `CGShieldingWindowLevel()` in full screen,
        // else `CGWindowLevelForKey(kCGFloatingWindowLevelKey)`.
        fullScreen ? NSWindow.Level(rawValue: Int(CGShieldingWindowLevel())) : .floating
    }

    // MARK: - Requests

    /// Shows the dialog a `ShellRequest` asks for; `completion` gets its answer (pass it to `deliver(_:to:)`).
    /// Returns false for requests that are not dialogs. `prefs` / `highScores` are the front end's current ones.
    @discardableResult
    func present(_ request: ShellRequest, prefs: BTXPrefs, highScores: HighScoreTable, fullScreen: Bool,
                 completion: @escaping (Answer) -> Void) -> Bool {
        switch request {
        case .levelSelectDialog(let max):
            levelSelect(max: max, fullScreen: fullScreen, completion: completion)
        case .highScoreEntry:
            highScoreName(defaultName: highScores.defaultName, fullScreen: fullScreen, completion: completion)
        case .hiScoreEraseDialog:
            hiScoreErase(fullScreen: fullScreen, completion: completion)
        case .modalDialog(let id):
            modal(id, fullScreen: fullScreen, completion: completion)
        case .prefsDialog:
            let window = BTXPrefsWindow(dialogs: self, prefs: prefs, fullScreen: fullScreen) { completion(.prefs($0)) }
            window.open()
        default:
            return false
        }
        return true
    }

    /// `.closeDialog`: `_DoLevelSelect`'s `_DisposeDialog` after its hold.
    func close() {
        guard let d = pendingClose else { return }
        pendingClose = nil
        pop(d)
    }

    /// Hands an answer to the front end (`FrontEnd`'s answer methods); handle the returned output as any other.
    static func deliver(_ answer: Answer, to frontEnd: FrontEnd) -> SessionOutput {
        switch answer {
        case .levelSelect(let typed): frontEnd.levelSelectDone(typed: typed)
        case .highScoreName(let name): frontEnd.highScoreNameEntered(name)
        case .hiScoreErase(let reset): frontEnd.hiScoreEraseDone(reset: reset)
        case .prefs(let p): frontEnd.prefsDialogDone(prefs: p)
        case .dismissed: frontEnd.dialogDone()
        }
    }

    // MARK: - The dialogs

    private func makeDialog(_ id: Int, params: [String] = []) -> CarbonDialog? {
        guard let t = BTXDialogResources.dialog(id, data: data) else { return nil }
        return CarbonDialog(template: t, data: data, art: art, params: params)
    }

    /// `_DoLevelSelect @ 0000d31e`.
    private func levelSelect(max: Int, fullScreen: Bool, completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(160, params: [String(max)]) else { completion(.levelSelect(typed: nil)); return }
        d.defaultItem = 1
        d.setText(4, "2")
        d.keyFilter = { [unowned d] key in
            // `_LevelSelectFilter`.
            if !key.command {
                if key.char == 0x0d || key.char == 0x03 { d.flash(1); return true }
                if key.char == 0x1b { d.flash(2); return true }
                if key.char &- 0x30 < 10 || key.char == 0x08 { return false }
                NSSound.beep()
                return true
            }
            if key.commandUppercased == UInt8(ascii: ".") { d.flash(2) }
            return true
        }
        var answered = false
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 || item == 2, !answered else { return }
            answered = true
            d.keyFilter = { _ in true }
            pendingClose = d
            guard item == 1 else { completion(.levelSelect(typed: nil)); return }
            let typed = Self.stringToNum(d.text(4))
            // The field shows the level `_DoLevelSelect` returns (0 when rejected) through the 30-tick hold.
            let level = FrontEnd.levelSelectChoice(typed: typed, max: max) ?? 0
            d.setText(4, String(level))
            completion(.levelSelect(typed: typed))
        }
        push(d, fullScreen: fullScreen)
        d.selectText(4)
    }

    /// `_CheckHiScore`'s DLOG 1000 with `_HiScoreNameFilter`.
    private func highScoreName(defaultName: String, fullScreen: Bool, completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(1000) else { completion(.highScoreName(defaultName)); return }
        d.defaultItem = 1
        d.setText(2, defaultName)
        d.keyFilter = { [unowned self, unowned d] key in
            if key.char == 0x0d || key.char == 0x03 { d.flash(1); return true }
            let slot: Int
            if key.char &- 0x1c < 4 || key.char == 0x08 {
                slot = 6
            } else {
                if BTXDialogResources.byteLength(d.text(2)) > 9, d.selectionLength <= 0 {
                    NSSound.beep()
                    return true
                }
                slot = 1
            }
            playSound(SoundCue(slot: slot, priority: 0x14, delayFrames: 0), nil)
            return false
        }
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            let name = d.text(2)
            pop(d)
            completion(.highScoreName(name))
        }
        push(d, fullScreen: fullScreen)
        d.selectText(2, from: 0, to: 0x400)
    }

    /// `_HiScoreEraseDialog @ 00024670`.
    private func hiScoreErase(fullScreen: Bool, completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(1001) else { completion(.hiScoreErase(reset: false)); return }
        playSound(SoundCue(slot: 0x16, priority: 10, delayFrames: 0), nil)
        d.defaultItem = 2
        d.cancelItem = 2
        d.outline(1)
        d.keyFilter = { [unowned d] key in
            // `_HiScoreEraseFilter`: Return, Enter and Esc all mean Cancel; ⌘ keys other than ⌘. are eaten.
            if !key.command {
                guard key.char == 0x0d || key.char == 0x03 || key.char == 0x1b else { return false }
            } else if key.commandUppercased != UInt8(ascii: ".") {
                return true
            }
            d.flash(2)
            return true
        }
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 || item == 2 else { return }
            pop(d)
            completion(.hiScoreErase(reset: item == 1))
        }
        push(d, fullScreen: fullScreen)
    }

    /// DLOG 290 / 291 (`_WaitUntilKeyOrMousePress`) and 3000 / 3001 (`ModalDialog` until item 1).
    private func modal(_ id: Int, fullScreen: Bool, completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(id) else { completion(.dismissed); return }
        if id == 290 || id == 291 {
            d.endsOnAnyPress = true
            d.itemHit = { [unowned self, unowned d] _ in
                pop(d)
                completion(.dismissed)
            }
        } else {
            d.defaultItem = 1
            d.itemHit = { [unowned self, unowned d] item in
                guard item == 1 else { return }
                pop(d)
                completion(.dismissed)
            }
        }
        push(d, fullScreen: fullScreen)
    }

    /// `NoteAlert` / `StopAlert(id)` after `ParamText(params…)`: the alert's stage sound (`SysBeep`), item 1 the
    /// default button; `completion` runs when it is dismissed. Shown at the front dialog's level, else `fullScreen`'s.
    func alert(_ id: Int, params: [String] = [], fullScreen: Bool, completion: (() -> Void)? = nil) {
        guard let t = BTXDialogResources.alert(id, data: data) else { completion?(); return }
        let d = CarbonDialog(template: t, data: data, art: art, params: params)
        d.defaultItem = 1
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            pop(d)
            completion?()
        }
        if let stages = t.alertStages, stages & 0x3 != 0 { NSSound.beep() }
        push(d, fullScreen: fullScreen)
    }

    /// `StringToNum`: optional sign, decimal digits, 32-bit wrap-around.
    static func stringToNum(_ s: String) -> Int {
        var value: Int32 = 0
        var negative = false
        for (i, c) in s.unicodeScalars.enumerated() {
            if i == 0, c == "-" || c == "+" { negative = c == "-"; continue }
            value = value &* 10 &+ Int32(truncatingIfNeeded: Int(c.value) - 0x30)
        }
        return Int(negative ? 0 &- value : value)
    }

    // MARK: - The modal stack and event routing

    /// Puts `d` on screen in front of every other dialog and routes the app's events to it.
    func push(_ d: CarbonDialog, fullScreen: Bool) {
        let level = stack.last?.panel.level ?? Self.level(fullScreen: fullScreen)
        stack.append(d)
        d.show(level: level, fullScreen: fullScreen)
        startRouting()
    }

    /// Disposes `d` (and anything in front of it) and gives the key focus back to the dialog behind, if any.
    func pop(_ d: CarbonDialog) {
        guard let i = stack.firstIndex(where: { $0 === d }) else { return }
        for dialog in stack[i...].reversed() { dialog.dispose() }
        stack.removeSubrange(i...)
        if pendingClose.map({ c in !stack.contains { $0 === c } }) == true { pendingClose = nil }
        if let front = stack.last {
            front.panel.makeKeyAndOrderFront(nil)
        } else {
            stopRouting()
        }
    }

    private func startRouting() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown,
                                                              .rightMouseDown, .otherMouseDown]) { [weak self] event in
            nonisolated(unsafe) let e = event
            let consumed = MainActor.assumeIsolated { self?.consumes(e) ?? false }
            return consumed ? nil : event
        }
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.stack.last?.nullEvent?() }
        }
        RunLoop.main.add(timer, forMode: .common)
        nullTimer = timer
        // App-modal: if another of the app's windows takes the key focus, give it back to the front dialog.
        keyObserver = NotificationCenter.default.addObserver(forName: NSWindow.didBecomeKeyNotification, object: nil,
                                                             queue: .main) { [weak self] note in
            let window = note.object as? NSWindow
            MainActor.assumeIsolated {
                guard let self, let front = self.stack.last, window !== front.panel,
                      !self.stack.contains(where: { $0.panel === window }) else { return }
                front.panel.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func stopRouting() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        nullTimer?.invalidate()
        nullTimer = nil
        if let keyObserver { NotificationCenter.default.removeObserver(keyObserver) }
        keyObserver = nil
    }

    /// The `ModalDialog` loop's view of an event (true = consumed): the front dialog gets keys; a click in any
    /// other window is refused with a beep (an app-modal dialog); `_WaitUntilKeyOrMousePress` takes either.
    private func consumes(_ event: NSEvent) -> Bool {
        guard let front = stack.last else { return false }
        if front.endsOnAnyPress {
            front.itemHit?(0)
            return true
        }
        if event.type == .keyDown { return front.handleKeyDown(event) }
        if event.window === front.panel { return front.flashing }
        NSSound.beep()
        return true
    }
}

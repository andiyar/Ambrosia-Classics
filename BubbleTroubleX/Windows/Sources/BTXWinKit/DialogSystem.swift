import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// What a dialog needs from the driver while it is up (W6 → W4 integration). Every call comes from inside one of
/// `DialogSystem`'s entry points, on the driver's thread.
public protocol DialogSystemDelegate: AnyObject {
    /// `_PlayMySnd` from inside a dialog. `volumeOverride` is a stand-in for short 0x33 (the sound-effects level) for
    /// this one play — the prefs Music popup plays snd 13 at the MUSIC level (`_PrefsDialog` case 0x1b); nil = the
    /// current prefs' level.
    func dialogPlaySound(_ cue: SoundCue, volumeOverride: Int?)
    /// `_UpdateSoundVol` / `_UpdateMusicVolume` while the prefs dialog is up: the edited prefs, live; `updateMusic`
    /// says whether the original called `_UpdateMusicVolume` here (Music popup, Title screen music, Defaults, Revert).
    func dialogLivePrefs(_ prefs: BTXPrefs, updateMusic: Bool)
    /// `SysBeep(1)` (refused keys, a click outside the front dialog, an alert's stage sound).
    func dialogBeep()
    /// `isShowing` / `isModal` may have changed (the driver stops / restarts its clocks and greys its menu bar).
    func dialogModalStateChanged()
}

/// The original's Carbon dialogs and alerts drawn inside the game window (plan W6, D15.3) — the Windows port of the
/// Mac app's `BTXDialogs` (`BubbleTroubleX/App/BTXDialogs.swift`, its table of DLOG / ALRT call sites is the spec):
/// rebuilt from their `DLOG`/`ALRT`/`DITL` resources (`DialogWindow`), driven exactly as the 1.1 code drives them, and
/// answered back into `FrontEnd` through `deliver(_:to:)`.
///
/// | DLOG | request | behaviour |
/// |---|---|---|
/// | 160 Level Select | `.levelSelectDialog(max:)` | `_LevelSelectFilter`; OK shows the validated level and stays up until `.closeDialog` |
/// | 190 Preferences (+ 200, ALRT 201 / 202) | `.prefsDialog` | `WinPrefsDialog` |
/// | 290 / 291 | `.modalDialog(id:)` | any key or click anywhere |
/// | 1000 High Score Name | `.highScoreNameDialog(defaultName:)` | `_HiScoreNameFilter` |
/// | 1001 High Score Erase | `.hiScoreEraseDialog` | `_HiScoreEraseFilter`, ring on Reset |
/// | 3000 / 3001 birthdays | `.modalDialog(id:)` | until item 1 |
///
/// Alerts: `alert(_:params:completion:)` shows any `ALRT` (129, 201, 202, 203, 208, 215, 217, 1920, 8000, 8001,
/// 9000–9005 — every one the 1.1 code shows; see the Mac table for call sites).
///
/// **Host contract.** The dialogs sit modally over the 640×480 canvas, placed as `alertPositionParentWindowScreen`
/// places them on their parent (horizontally centred, a third of the free height above). While `isShowing` the host
/// routes every key and mouse event here (canvas coordinates; the menu strip above the canvas is negative y — a click
/// there beeps, as the app-modal Carbon dialog refused other windows), calls `tick(heldKeys:)` once per 1/60 s, and
/// draws with `draw(into:canvasX:canvasY:)` after the game frame. While `isModal` the game clocks stop.
public final class DialogSystem {
    /// What a dialog answered; `deliver(_:to:)` hands it to the front end.
    public enum Answer: Equatable, Sendable {
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

    public static let canvasWidth = 640, canvasHeight = 480

    public let data: BTXGameData
    public let art: ArtBank
    public let renderer: DialogRenderer
    public weak var delegate: DialogSystemDelegate?

    /// Dialogs and alerts on screen, front last.
    public private(set) var stack: [DialogWindow] = []
    /// The dialog `.closeDialog` disposes (DLOG 160 after the front end's 30-tick hold).
    private var pendingClose: DialogWindow? { didSet { delegate?.dialogModalStateChanged() } }
    /// The open Preferences dialog (held here; its closures hold it only weakly).
    public private(set) var prefsDialog: WinPrefsDialog?
    /// `_PrefsDialog`'s statics (`_firstTime_73946`, the eggs, the modifier latches): for the app's life.
    var prefsStatics = WinPrefsDialog.Statics()
    /// The keys held at the last tick (Mac virtual key codes) — `GetKeys` for the prefs' modifier capture.
    public private(set) var heldKeys: Set<UInt16> = []
    /// The mouse in canvas coordinates (last move / press / release).
    public private(set) var mouse: (x: Int, y: Int)?

    /// True while any dialog is on screen — the menu bar is disabled then (Carbon `ModalDialog` is app-modal).
    public var isShowing: Bool { !stack.isEmpty }
    /// True while a dialog waits for the user (`ModalDialog` / `_WaitUntilKeyOrMousePress` block the original's
    /// loop): the clocks stop. False for DLOG 160 after its OK / Cancel, held up through the front end's hold.
    public var isModal: Bool { stack.contains { $0 !== pendingClose } }
    public var frontDialog: DialogWindow? { stack.last }

    public init(data: BTXGameData, art: ArtBank, renderer: DialogRenderer) {
        self.data = data
        self.art = art
        self.renderer = renderer
    }

    func beep() { delegate?.dialogBeep() }
    func playSound(_ cue: SoundCue, _ volumeOverride: Int? = nil) {
        delegate?.dialogPlaySound(cue, volumeOverride: volumeOverride)
    }

    // MARK: - Requests

    /// Shows the dialog a `ShellRequest` asks for; `completion` gets its answer (pass it to `deliver(_:to:)`).
    /// Returns false for requests that are not dialogs. `prefs` are the front end's (or the paused game's) current ones.
    /// `completion` may run before this returns (a resource that fails to load answers as Cancel at once).
    @discardableResult
    public func present(_ request: ShellRequest, prefs: BTXPrefs, completion: @escaping (Answer) -> Void) -> Bool {
        switch request {
        case .levelSelectDialog(let max):
            levelSelect(max: max, completion: completion)
        case .highScoreNameDialog(let name):
            highScoreName(defaultName: name, completion: completion)
        case .hiScoreEraseDialog:
            hiScoreErase(completion: completion)
        case .modalDialog(let id):
            modal(id, completion: completion)
        case .prefsDialog:
            let p = WinPrefsDialog(system: self, prefs: prefs) { [weak self] result in
                self?.prefsDialog = nil
                completion(.prefs(result))
            }
            prefsDialog = p
            p.open()
        default:
            return false
        }
        return true
    }

    /// `.closeDialog`: `_DoLevelSelect`'s `_DisposeDialog` after its hold.
    public func close() {
        guard let d = pendingClose else { return }
        pop(d)                                                          // clears `pendingClose`
    }

    /// Hands an answer to the front end (`FrontEnd`'s answer methods); handle the returned output as any other.
    public static func deliver(_ answer: Answer, to frontEnd: FrontEnd) -> SessionOutput {
        switch answer {
        case .levelSelect(let typed): frontEnd.levelSelectDone(typed: typed)
        case .highScoreName(let name): frontEnd.highScoreNameEntered(name)
        case .hiScoreErase(let reset): frontEnd.hiScoreEraseDone(reset: reset)
        case .prefs(let p): frontEnd.prefsDialogDone(prefs: p)
        case .dismissed: frontEnd.dialogDone()
        }
    }

    // MARK: - The dialogs

    func makeDialog(_ id: Int, params: [String] = []) -> DialogWindow? {
        guard let t = DialogResources.dialog(id, data: data) else { return nil }
        return DialogWindow(template: t, data: data, art: art, params: params)
    }

    /// `_DoLevelSelect @ 0000d31e`.
    private func levelSelect(max: Int, completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(160, params: [String(max)]) else { completion(.levelSelect(typed: nil)); return }
        d.defaultItem = 1
        d.setText(4, "2")
        d.keyFilter = { [unowned self, unowned d] key in
            // `_LevelSelectFilter`.
            if !key.command {
                if key.char == 0x0d || key.char == 0x03 { d.flash(1); return true }
                if key.char == 0x1b { d.flash(2); return true }
                if key.char &- 0x30 < 10 || key.char == 0x08 { return false }
                beep()
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
        push(d)
        d.selectText(4)
    }

    /// `_CheckHiScore`'s DLOG 1000 with `_HiScoreNameFilter`.
    private func highScoreName(defaultName: String, completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(1000) else { completion(.highScoreName(defaultName)); return }
        d.defaultItem = 1
        d.setText(2, defaultName)
        d.keyFilter = { [unowned self, unowned d] key in
            if key.char == 0x0d || key.char == 0x03 { d.flash(1); return true }
            let slot: Int
            if key.char &- 0x1c < 4 || key.char == 0x08 {
                slot = 6
            } else {
                if DialogResources.byteLength(d.text(2)) > 9, d.selectionLength <= 0 {
                    beep()
                    return true
                }
                slot = 1
            }
            playSound(SoundCue(slot: slot, priority: 0x14, delayFrames: 0))
            return false
        }
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            let name = d.text(2)
            d.keyFilter = { _ in true }
            // `_CheckHiScore` plays snd 15 and the joke-name sound with the dialog still up: the answer's output is
            // applied (synchronously, by the driver) before `_DisposeDialog`.
            completion(.highScoreName(name))
            pop(d)
        }
        push(d)
        d.selectText(2, from: 0, to: 0x400)
    }

    /// `_HiScoreEraseDialog @ 00024670`.
    private func hiScoreErase(completion: @escaping (Answer) -> Void) {
        guard let d = makeDialog(1001) else { completion(.hiScoreErase(reset: false)); return }
        playSound(SoundCue(slot: 0x16, priority: 10, delayFrames: 0))
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
        push(d)
    }

    /// DLOG 290 / 291 (`_WaitUntilKeyOrMousePress`) and 3000 / 3001 (`ModalDialog` until item 1).
    private func modal(_ id: Int, completion: @escaping (Answer) -> Void) {
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
        push(d)
    }

    /// `NoteAlert` / `StopAlert(id)` after `ParamText(params…)`: the alert's stage sound (`SysBeep`), item 1 the
    /// default button; `completion` runs when it is dismissed.
    public func alert(_ id: Int, params: [String] = [], completion: (() -> Void)? = nil) {
        guard let t = DialogResources.alert(id, data: data) else { completion?(); return }
        let d = DialogWindow(template: t, data: data, art: art, params: params)
        d.defaultItem = 1
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            pop(d)
            completion?()
        }
        if let stages = t.alertStages, stages & 0x3 != 0 { beep() }
        push(d)
    }

    /// `StringToNum`: optional sign, decimal digits, 32-bit wrap-around.
    public static func stringToNum(_ s: String) -> Int {
        var value: Int32 = 0
        var negative = false
        for (i, c) in s.unicodeScalars.enumerated() {
            if i == 0, c == "-" || c == "+" { negative = c == "-"; continue }
            value = value &* 10 &+ Int32(truncatingIfNeeded: Int(c.value) - 0x30)
        }
        return Int(negative ? 0 &- value : value)
    }

    // MARK: - The modal stack

    /// `WinPrefsDialog`: DLOG 190 itself, and DLOG 200 over it.
    func open(_ d: DialogWindow) { push(d) }

    /// `WinPrefsDialog`: `_DisposeDialog`.
    func dismiss(_ d: DialogWindow) { pop(d) }

    /// The `alertPositionParentWindowScreen` place on the canvas: horizontally centred, a third of the free height
    /// above (the Mac replica's rule, applied to the game window as the parent).
    static func origin(width: Int, height: Int) -> (x: Int, y: Int) {
        let x = (Double(canvasWidth) / 2 - Double(width) / 2).rounded()
        let y = (Double(canvasHeight - height) / 3).rounded()
        return (Int(x), Int(max(0, y)))
    }

    /// Puts `d` on screen in front of every other dialog and routes the events to it.
    private func push(_ d: DialogWindow) {
        let o = Self.origin(width: d.template.width, height: d.template.height)
        d.originX = o.x
        d.originY = o.y
        d.measure = { [unowned renderer] in renderer.width($0) }
        if let m = mouse { d.mouseLocation = (m.x - o.x, m.y - o.y) }
        stack.append(d)
        updateFrontmost()
        delegate?.dialogModalStateChanged()
    }

    /// Only the front dialog draws active.
    private func updateFrontmost() {
        for d in stack { d.isFrontmost = d === stack.last }
    }

    /// Disposes `d` (and anything in front of it).
    private func pop(_ d: DialogWindow) {
        guard let i = stack.firstIndex(where: { $0 === d }) else { return }
        stack.removeSubrange(i...)
        updateFrontmost()
        if pendingClose.map({ c in !stack.contains { $0 === c } }) == true { pendingClose = nil }
        delegate?.dialogModalStateChanged()
    }

    // MARK: - Events (canvas coordinates)

    /// A mouse press — the `ModalDialog` loop's view: the front dialog takes it; a press anywhere else is refused
    /// with a beep (an app-modal dialog); `_WaitUntilKeyOrMousePress` takes it anywhere.
    public func mouseDown(x: Int, y: Int) {
        setMouse(x, y)
        guard let front = stack.last else { return }
        if front.endsOnAnyPress {
            front.itemHit?(0)
            return
        }
        let lx = x - front.originX, ly = y - front.originY
        if front.contains(lx, ly) {
            front.mouseDown(lx, ly)
        } else if case .popup = front.tracking {
            front.mouseDown(lx, ly)                                      // closes the menu
        } else {
            beep()
        }
    }

    public func mouseMoved(x: Int, y: Int) {
        setMouse(x, y)
        guard let front = stack.last else { return }
        front.mouseMoved(x - front.originX, y - front.originY)
    }

    public func mouseUp(x: Int, y: Int) {
        setMouse(x, y)
        guard let front = stack.last else { return }
        front.mouseUp(x - front.originX, y - front.originY)
    }

    private func setMouse(_ x: Int, _ y: Int) {
        mouse = (x, y)
        for d in stack { d.mouseLocation = (x - d.originX, y - d.originY) }
    }

    /// A key press (and auto-repeat): the front dialog's filter, then the standard filter, then TextEdit.
    public func keyDown(_ event: DialogKeyEvent) {
        guard let front = stack.last else { return }
        if front.endsOnAnyPress {
            front.itemHit?(0)
            return
        }
        front.handleKey(DialogKey(event))
    }

    /// One 1/60 s tick while dialogs are up: the front dialog's flash and caret, then its null event (the prefs
    /// help line and modifier capture read `heldKeys` — Mac virtual key codes held now).
    public func tick(heldKeys: Set<UInt16> = []) {
        self.heldKeys = heldKeys
        guard let front = stack.last else { return }
        front.tick()
        if stack.last === front { front.nullEvent?() }
    }

    /// Draws every dialog, back to front, over the canvas whose top-left is at (`canvasX`, `canvasY`) in `image`.
    public func draw(into image: inout RGBAImage, canvasX: Int, canvasY: Int) {
        for d in stack { renderer.composite(d, into: &image, canvasX: canvasX, canvasY: canvasY) }
    }
}

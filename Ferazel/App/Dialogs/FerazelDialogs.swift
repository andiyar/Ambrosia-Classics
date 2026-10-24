import AppKit
import FerazelCore

/// The original's Dialog Manager windows for `ShellRequest.dialog` (plan A1b), built from R1's templates by
/// `FerazelCarbonDialog`, driven as the PPC code drives them, answered back into `GameFlow.dialogDone`:
///
/// | request | DLOG | code | behaviour transcribed |
/// |---|---|---|---|
/// | `.confirm(text)` | 202 | `.ConfirmAbortGameDialog @ 10006784` (M l. 3380–3433) | `ParamText(^0 = text)`; ring round OK (item 1, `InsetRect(−4)`, pen 3, oval 15); `ModalDialog(nil)` until item 1 (OK) or 2 (Cancel) — the standard filter: Return / Enter → item 1; item 5 (Save) does not exist in DITL 202 (BC26) |
/// | `.report(text)` | 200 | `.ReportDialog @ 1003d33c` → `.GenericMessage(1) @ 1003cf04` (M l. 35429–35480, 35553–35562) | `ParamText(^0 = text, ^1 = "")`; ring round OK; until item 1 |
/// | `.error(text, code)` | 200 | `.ReportError @ 1003d2a0` (M l. 35537–35550) | the same with `^1 = NumToString(code)` |
/// | `.preferences` | 6900 | `.PreferencesDialog @ 100760dc` | `PrefsDialogView` over `GameFlow.prefsDialog` (O1) |
/// | `.credits` | 600 | `.DoAboutDialog(600, 4803) @ 1007853c` | `CreditsDialog` over `GameFlow.credits` |
///
/// Every one is modal: while any is up the App's clock does not tick the flow (`isShowing`), the menu bar is disabled,
/// clicks outside the front dialog beep (an app-modal `ModalDialog`), every key goes to the front dialog.
@MainActor final class FerazelDialogs {
    let resources: FerazelResources
    /// A `PICT` (by id, on the `.frontEnd` chain) as QuickDraw drew it into a dialog: under the screen's current CLUT.
    let picture: (Int16) -> CGImage?
    /// The game image's rect in screen coordinates and the game window's level (the dialogs sit just above it).
    let gameArea: () -> (rect: NSRect, level: NSWindow.Level)
    /// Called whenever `isShowing` may have changed (the App stops / restarts its clock and menus).
    var modalStateChanged: () -> Void = {}

    /// Dialogs on screen, front last.
    private var stack: [FerazelCarbonDialog] = []
    private var monitor: Any?
    private var nullTimer: Timer?
    private var keyObserver: NSObjectProtocol?
    /// The open Options and Credits controllers (held here; their closures hold them weakly).
    private var prefs: PrefsDialogView?
    private var credits: CreditsDialog?

    var isShowing: Bool { !stack.isEmpty }

    init(resources: FerazelResources, picture: @escaping (Int16) -> CGImage?,
         gameArea: @escaping () -> (rect: NSRect, level: NSWindow.Level)) {
        self.resources = resources
        self.picture = picture
        self.gameArea = gameArea
    }

    func make(_ id: Int16, params: [String] = []) -> FerazelCarbonDialog? {
        FerazelCarbonDialog(dialog: id, resources: resources, picture: picture, params: params)
    }

    // MARK: - DLOG 202 / 200

    /// `.ConfirmAbortGameDialog`: OK (true) or Cancel.
    func confirm(_ text: String, completion: @escaping (Bool) -> Void) {
        guard let d = make(202, params: [text]) else { NSSound.beep(); completion(false); return }
        d.outlineDefault(1)
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 || item == 2 else { return }
            dismiss(d)
            completion(item == 1)
        }
        open(d)
    }

    /// `.GenericMessage(1)` after `.ReportDialog` (`code` nil, `^1` empty) or `.ReportError` (`^1` = the code).
    func report(_ text: String, code: Int16? = nil, completion: @escaping () -> Void) {
        guard let d = make(200, params: [text, code.map { String($0) } ?? ""]) else { completion(); return }
        d.outlineDefault(1)
        d.itemHit = { [unowned self, unowned d] item in
            guard item == 1 else { return }
            dismiss(d)
            completion()
        }
        open(d)
    }

    // MARK: - DLOG 6900 / 600

    /// `.PreferencesDialog` over the flow's model; `completion` once its `result` is set (and the dialog gone).
    func preferences(model: @escaping () -> PrefsDialogModel?, update: @escaping ((inout PrefsDialogModel) -> [MusicCue]) -> Void,
                     completion: @escaping () -> Void) {
        guard model() != nil, let v = PrefsDialogView(dialogs: self, model: model, update: update, completion: {
            [weak self] in
            self?.prefs = nil
            completion()
        }) else { completion(); return }
        prefs = v
        v.open()
    }

    /// `.DoAboutDialog(600, 4803)` over `scroll`; `completion` after a click inside closed it.
    func credits(_ scroll: CreditsScroll, completion: @escaping () -> Void) {
        guard let c = CreditsDialog(dialogs: self, scroll: scroll, completion: { [weak self] in
            self?.credits = nil
            completion()
        }) else { NSSound.beep(); completion(); return }
        credits = c
        c.open()
    }

    // MARK: - The modal stack and event routing

    /// Puts `d` on screen in front of every other dialog and routes the app's events to it.
    func open(_ d: FerazelCarbonDialog) {
        let area = gameArea()
        let level = stack.last?.panel.level ?? NSWindow.Level(rawValue: max(area.level.rawValue + 1,
                                                                              NSWindow.Level.modalPanel.rawValue))
        stack.append(d)
        d.show(over: area.rect, level: level)
        startRouting()
        modalStateChanged()
    }

    /// `DisposeDialog(d)` (and anything in front of it); the key focus back to the dialog behind, if any.
    func dismiss(_ d: FerazelCarbonDialog) {
        guard let i = stack.firstIndex(where: { $0 === d }) else { return }
        for dialog in stack[i...].reversed() { dialog.dispose() }
        stack.removeSubrange(i...)
        if let front = stack.last {
            front.panel.makeKeyAndOrderFront(nil)
        } else {
            stopRouting()
        }
        modalStateChanged()
    }

    private func startRouting() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .leftMouseDown, .rightMouseDown,
                                                              .otherMouseDown]) { [weak self] event in
            nonisolated(unsafe) let e = event
            let consumed = MainActor.assumeIsolated { self?.consumes(e) ?? false }
            return consumed ? nil : event
        }
        // `ModalDialog`'s null events (and the TextEdit caret): once per tick.
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

    /// The `ModalDialog` loop's view of an event (true = consumed): the front dialog gets every key (no menu key
    /// reaches the app meanwhile); a click in another window beeps; a dialog run by its own clock takes every click.
    private func consumes(_ event: NSEvent) -> Bool {
        guard let front = stack.last else { return false }
        if front.takesAllClicks, event.type != .keyDown, event.type != .keyUp { return true }
        switch event.type {
        case .keyDown:
            front.handleKeyDown(event)
            return true
        case .keyUp:
            return true
        default:
            if event.window === front.panel { return front.flashing }
            NSSound.beep()
            return true
        }
    }
}

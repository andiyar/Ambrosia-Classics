import AppKit
import FerazelCore

/// DLOG 6900 "Preferences" over O1's `PrefsDialogModel` — `.PreferencesDialog @ 100760dc` (M l. 64233–64575):
/// `GetNewDialog(6900)`, `HiliteColor(30000, 30000, 65535)` (the edit items' selection colour; restored at close),
/// item 5's user-item proc `.DrawGreyOutline @ 100757b8` (a white `FrameRect` of the item rect, the same rect offset
/// (−1, −1) in grey 0x5000, then `Draw1Control(item 3)` over it), `.SwitchPrefsPanel(1)` (`ShortenDITL` to the six base
/// items + `AppendDITL(6900 + n)`), the ring round OK, then `ModalDialog(.PrefDialogFilter)` until item 1 or 2.
///
/// The model holds every decision (panels, values, key capture, `.AlreadyUsingKey`, `.ConvertKeyName`, Default
/// Settings); this view feeds it `ModalDialog`'s events — item hits (popups with their new value), clicks in an edit
/// item (`SelectDialogItemText`), key events (`.PrefDialogFilter`'s keyDown / autoKey branch) and the null events'
/// modifiers (its modifier capture) — and redraws from it. A refused key shows `.ReportDialog` (DLOG 200) over it.
@MainActor final class PrefsDialogView {
    static let dialogID: Int16 = 6900
    /// `HiliteColor` while the dialog is up.
    static let hiliteColor = rgbColor(30000, 30000, 65535)
    /// `GetCaretTime`'s default (32 ticks): TextEdit's insertion point blink (`TEIdle` in `ModalDialog`).
    static let caretTicks = 32

    private unowned let dialogs: FerazelDialogs
    private let dialog: FerazelCarbonDialog
    private let model: () -> PrefsDialogModel?
    private let update: ((inout PrefsDialogModel) -> [MusicCue]) -> Void
    private let completion: () -> Void
    /// The panel whose DITL is appended (`_DAT_100a694c`).
    private var shownPanel: PrefsDialogModel.Panel?
    private var caretTicks = 0
    private var closed = false

    /// - Parameters:
    ///   - model: the flow's model (`GameFlow.prefsDialog`), read after every event.
    ///   - update: mutates the flow's model; the music cues a hit made are the App's to play at once.
    init?(dialogs: FerazelDialogs, model: @escaping () -> PrefsDialogModel?,
          update: @escaping ((inout PrefsDialogModel) -> [MusicCue]) -> Void, completion: @escaping () -> Void) {
        guard let d = dialogs.make(Self.dialogID) else { return nil }
        self.dialogs = dialogs
        dialog = d
        self.model = model
        self.update = update
        self.completion = completion
        if let r = d.item(5)?.rect {
            // `.DrawGreyOutline` (item 5's proc): a white `FrameRect`, then the rect offset (−1, −1) framed in RGB
            // 0x5000 — under every item, as `Draw1Control(item 3)` then redraws the popup over it.
            d.root.decorations.append { cg in
                cg.setLineWidth(1)
                cg.setStrokeColor(NSColor.white.cgColor)
                cg.stroke(r.insetBy(dx: 0.5, dy: 0.5))
                cg.setStrokeColor(rgbColor(0x5000, 0x5000, 0x5000).cgColor)
                cg.stroke(r.offsetBy(dx: -1, dy: -1).insetBy(dx: 0.5, dy: 0.5))
            }
        }
        d.outlineDefault(1)
        d.defaultItem = nil                                            // the filter handles Return / Enter itself
        d.itemHit = { [weak self] item in self?.hit(item) }
        d.keyFilter = { [weak self] key in
            self?.key(key)
            return true
        }
        d.nullEvent = { [weak self] in self?.null() }
        sync()
    }

    func open() {
        dialogs.open(dialog)
    }

    // MARK: - Events into the model

    private func hit(_ item: Int) {
        guard !closed else { return }
        if let e = dialog.view(item) as? ClassicEditText, e.enabled {
            // `.PrefDialogFilter`'s mouse-down on an edit item: `SelectDialogItemText(item, 0, 0x7fff)`.
            update { m in
                m.focus(item: item)
                return []
            }
        } else {
            let value = (dialog.view(item) as? ClassicPopup)?.value
            update { m in m.hit(item, value: value) }
        }
        sync()
    }

    private func key(_ k: DialogKey) {
        guard !closed else { return }
        var outcome = PrefsDialogModel.KeyOutcome.passed
        update { m in
            outcome = m.keyDown(char: k.char, keyCode: k.keyCode, modifiers: k.modifiers, isRepeat: k.isRepeat)
            return []
        }
        switch outcome {
        case .ok: dialog.hilite(1)
        case .cancel: dialog.hilite(2)
        case .refused(let text):
            // `.ReportDialog(&DAT_100a694e)` from inside the filter: DLOG 200 over the Options dialog.
            dialogs.report(text) {}
        default: break
        }
        sync()
    }

    /// A null event: the modifiers held (the filter's modifier capture), the caret blink.
    private func null() {
        guard !closed else { return }
        let modifiers = DialogKey.modifiers(NSEvent.modifierFlags)
        var outcome = PrefsDialogModel.KeyOutcome.passed
        update { m in
            outcome = m.idle(modifiers: modifiers)
            return []
        }
        caretTicks += 1
        if caretTicks % Self.caretTicks == 0 {
            for item in dialog.items.map(\.number) {
                if let e = dialog.view(item) as? ClassicEditText { e.caretVisible.toggle() }
            }
        }
        if case .captured = outcome { sync() }
    }

    // MARK: - The model onto the dialog

    /// `.SwitchPrefsPanel` when the model's panel changed, then every value, text, focus, disabled and hidden item.
    private func sync() {
        guard let m = model() else { return }
        if m.panel != shownPanel {
            shownPanel = m.panel
            dialog.shorten(to: 6)
            if let list = try? DialogItemList.load(from: dialogs.resources, id: Self.dialogID + Int16(m.panel.rawValue)) {
                dialog.append(list)
            }
            for item in dialog.items.map(\.number) {
                (dialog.view(item) as? ClassicEditText)?.hilite = Self.hiliteColor
            }
        }
        for (item, v) in m.controlValues { dialog.setValue(item, v) }
        for (item, s) in m.itemTexts { dialog.setText(item, s) }
        dialog.select(m.focus)
        for item in dialog.items.map(\.number) where item >= 7 {
            dialog.setActive(item, !m.disabledItems.contains(item))
            dialog.setHidden(item, m.hiddenItems.contains(item))
        }
        if m.result != nil, !closed {
            closed = true
            // `HideWindow`, `HiliteColor` restored, `DisposeDialog` — then `.Options` writes the record back.
            dialogs.dismiss(dialog)
            completion()
        }
    }
}

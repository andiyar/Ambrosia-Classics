import FerazelCore
import Foundation

/// DLOG 6900 "Preferences" over O1's `PrefsDialogModel`, drawn in the game picture (WF4b, D43 Ruling 4, ◇W10) — the
/// Windows port of the Mac's `PrefsDialogView` (`Ferazel/App/Dialogs/PrefsDialogView.swift`, transcribed there from
/// `.PreferencesDialog @ 100760dc`, M l. 64233–64575), adapted from BTX's `WinPrefsDialog` shape (BTX untouched):
/// `GetNewDialog(6900)`, `HiliteColor(30000, 30000, 65535)` for the key fields' selection, item 5's
/// `.DrawGreyOutline`, `.SwitchPrefsPanel(1)` (`ShortenDITL` to the six base items + `AppendDITL(6900 + n)`), the
/// ring round OK, then `ModalDialog(.PrefDialogFilter)` until item 1 or 2.
///
/// The model holds every decision (panels, values, key capture, `.AlreadyUsingKey`, `.ConvertKeyName`, Default
/// Settings; off the Controls panel ⌘. / Esc → Cancel and Return / Enter → OK at once, no flash); this feeds it
/// `ModalDialog`'s events — item hits (popups with their new value), clicks in a key field, key events (auto-keys
/// flagged) and each tick's null event with the modifiers held — and redraws from it. A refused key shows DLOG 200 over
/// it (`.ReportDialog`, answered into nothing). The music cues a hit makes are the services' to play at once.
@MainActor final class WinPrefsDialog {
    static let dialogID: Int16 = 6900
    /// `HiliteColor(30000, 30000, 65535)` as 8-bit channels (each 16-bit value's high byte).
    static let hiliteRGB: UInt32 = 0x7575FF
    /// `GetCaretTime`'s default (32 ticks): TextEdit's insertion point blink.
    static let caretTicks = 32

    private unowned let system: DialogSystem
    private let services: WinDialogServices
    let dialog: DialogWindow
    private let completion: (DialogResult) -> Void
    /// The panel whose DITL is appended (`_DAT_100a694c`).
    private var shownPanel: PrefsDialogModel.Panel?
    private var caretCount = 0
    private var closed = false

    init?(system: DialogSystem, services: WinDialogServices, completion: @escaping (DialogResult) -> Void) {
        guard let d = system.make(Self.dialogID) else { return nil }
        self.system = system
        self.services = services
        self.completion = completion
        dialog = d
        d.hiliteRGB = Self.hiliteRGB
        if d.item(5) != nil { d.greyOutline(5) }
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
        system.open(dialog)
    }

    // MARK: Events into the model

    private func hit(_ item: Int) {
        guard !closed else { return }
        if dialog.item(item)?.item.kind == .editText, dialog.takesClicks(item) {
            // `.PrefDialogFilter`'s mouse-down on an edit item: `SelectDialogItemText(item, 0, 0x7fff)`.
            services.updatePrefs { m in
                m.focus(item: item)
                return []
            }
        } else {
            let value = dialog.item(item)?.item.kind == .control ? dialog.value(item) : nil
            services.updatePrefs { m in m.hit(item, value: value) }
        }
        sync()
    }

    private func key(_ k: DialogKeyEvent) {
        guard !closed else { return }
        var outcome = PrefsDialogModel.KeyOutcome.passed
        services.updatePrefs { m in
            outcome = m.keyDown(char: k.char, keyCode: k.keyCode, modifiers: k.modifiers, isRepeat: k.isRepeat)
            return []
        }
        switch outcome {
        case .ok: dialog.hilite(1)
        case .cancel: dialog.hilite(2)
        case .refused(let text):
            // `.ReportDialog(&DAT_100a694e)` from inside the filter: DLOG 200 over the Options dialog.
            system.report(text, code: nil) { _ in }
        default: break
        }
        sync()
    }

    /// A null event: the modifiers held (the filter's modifier capture), the caret blink.
    private func null() {
        guard !closed else { return }
        let modifiers = DialogKeyEvent.modifiers(services.modifiers(), buttonDown: false)
        var outcome = PrefsDialogModel.KeyOutcome.passed
        services.updatePrefs { m in
            outcome = m.idle(modifiers: modifiers)
            return []
        }
        caretCount += 1
        if caretCount % Self.caretTicks == 0 { dialog.caretVisible.toggle() }
        if case .captured = outcome { sync() }
    }

    // MARK: The model onto the dialog

    /// `.SwitchPrefsPanel` when the model's panel changed, then every value, text, focus, disabled and hidden item.
    private func sync() {
        guard let m = services.prefs() else { return }
        if m.panel != shownPanel {
            shownPanel = m.panel
            dialog.shorten(to: 6)
            if let list = try? DialogItemList.load(from: services.resources,
                                                   id: Self.dialogID + Int16(m.panel.rawValue)) {
                dialog.append(list)
            }
        }
        for (item, v) in m.controlValues { dialog.setValue(item, v) }
        for (item, s) in m.itemTexts { dialog.setText(item, s) }
        dialog.select(m.focus)
        for item in dialog.items.map(\.number) where item >= 7 {
            dialog.setActive(item, !m.disabledItems.contains(item))
            dialog.setHidden(item, m.hiddenItems.contains(item))
        }
        if let r = m.result, !closed {
            closed = true
            // `HideWindow`, `HiliteColor` restored, `DisposeDialog` — then `.Options` writes the record back.
            dialog.keyFilter = nil
            dialog.nullEvent = nil
            dialog.itemHit = nil
            system.dismiss(dialog)
            completion(r == .ok ? .ok : .cancel)
        }
    }
}

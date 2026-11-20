import Foundation

/// The controls window — DLOG/DITL 191 "Game - Controls", X `FUN_100435d0(prefs + 0x14b8, prefs + 0x14d4)`
/// (100435d0..10043924; fill X `10043930`, name X `10043b40`, assign X `10043c00`, filter X `10043f90`; grounding C
/// §3, §3a; `osx-build.md` D4 and Item 2 — the item-hit and assign jump tables). Called by the configuration window's
/// "Set Controls…" (X 100115fc..10011614).
///
/// **Frozen entry.** `init()` — the original's arguments are the live prefs' two key sets
/// (`FrontEndState.prefs.keyTable`); it edits working copies and writes both sets back on Save. **Returns** true for
/// Save (X returns 1), false for Cancel.
///
/// **What X does, built here:**
/// - **Open** (100435d0..10043728): the focus variable (r2 − 0x5e10) = 5, the player (r2 − 0x5e04) = P1; both sets
///   copied into the working copies (7 ints each, 100435d8..100436c4); `GetNewDialog(191)` (nil asserts); the fields
///   filled from P1's set (`10043930`); field 5 selected (`SelectDialogItemText`); `ModalDialog` with the filter
///   `10043f90` until item 1 or 2.
/// - **Items hit** (the jump table at 0x100f57a0, items 3–17): the tab control (3, X 10043798) sets the focus
///   variable to 5, then reads the control's value: a change of player refills the fields and selects field 5; the
///   tab already up changes nothing else (the selection stays where it was — a quirk kept, ruling 15). A field
///   (5, 7, …, 17, X 10043774) is focused and selected (`ModalDialog`'s `TEClick` already made it the active one); a
///   picture (4, 6, …, 16) does nothing.
/// - **The filter** (`10043f90`): every keyDown / autoKey → the virtual key code `(message >> 8) & 0xFF`, sign-extended
///   (`extsb`), assigned and consumed — Return, Enter, Esc, Tab, arrows and F-keys are bindable and never press Save or
///   Cancel (`screenFiltersKeys`). A null event polls `GetKeys` for left Control 0x3B, Shift 0x38, Option 0x3A and
///   Command 0x37 in that order: the first one down and not latched is assigned and latched, and the null event ends
///   there; one that is up is unlatched (10044014..100441ac). Caps Lock, the right-hand modifiers and Fn never bind.
/// - **Assign** (`10043c00`): the name (below); refused when the code equals any of the 14 working slots unless the
///   focused field's text equals the name (a self-match by name) — `FlushEvents` + `SysBeep`, nothing changes;
///   otherwise the focused field shows the name, the current player's slot takes the code (the jump table at
///   0x100f57dc: fields 5, 7, …, 17 → slots 0–6) and the focus advances 5→7→9→11→13→15→17→5 and is selected.
/// - **The name** (`10043b40`): `STR# 130` "Game Keys" entry code + 1; a code outside 0…0x7F or an empty entry →
///   "??" (data 0x100f5835).
/// - **Save** (item 1, 1004386c..100438ec): both working sets copied into the prefs; returns 1. **Cancel** (item 2):
///   returns 0. `DisposeDialog`; no `FlushEvents` at the close.
///
/// **Modifier keys in the replica.** A Mac keyboard makes no keyDown for a modifier key, so the original sees them
/// only through `GetKeys`; here they come from the pass's `keys.held`, once a pass (the null event) while no press is
/// being followed. A key event carrying a modifier's code (0x36–0x3F: a shell that reports them as keys) is consumed
/// and binds nothing, so only the four left-hand edges ever bind one. The original's four latches live in its globals
/// for the whole run, set up once; here they live in the window and start released.
///
/// **How it is drawn** (ruling 8; Ben 2026-11-20: the classic grey Mac look, as S6's configuration window): by the
/// game, on `ModalDialogRunner`, centred on the picture. It is nested in the configuration window, so it saves and
/// restores nothing; the parent redraws itself whole when it returns. The tab control, the edit-text fields (with the
/// focus ring and the selected text) and the pictures are this screen's own items. The pictures (PICT 190–197) are the
/// shell's (ruling 9): `.drawPicture` at the item's top left, at the picture's own size; a picture the shell did not
/// hand in draws nothing.
///
/// **No resources** (`DLOG`/`DITL`/`CNTL` 191 or its `tab#` not handed in, or malformed): the original asserts on a
/// nil `GetNewDialog`; the replica finishes at once with false, draws nothing, prefs untouched. A missing `STR# 130`
/// names every key "??" (`GetIndString` gives an empty string).
public struct ControlsDialog: Sendable {
    public typealias Result = Bool

    enum Phase: Equatable, Sendable {
        case opening, running, closed
    }

    private(set) var phase = Phase.opening
    /// DITL 191 as parsed.
    private(set) var items: DialogItemList?
    /// The modal loop. Empty until the window opens.
    private(set) var runner = ModalDialogRunner(items: [], content: MacRect(top: 0, left: 0, bottom: 0, right: 0),
                                                defaultItem: ControlsDialog.save, cancelItem: ControlsDialog.cancel)
    /// The tab control's titles (`tab#` 6000: "Player 1", "Player 2").
    private(set) var tabNames: [[UInt8]] = []
    /// `STR# 130` "Game Keys".
    private(set) var keyNames: [[UInt8]] = []
    /// The working copies (r2 − 0x6be0 P1, r2 − 0x6be4 P2), 7 ints each.
    private(set) var sets: [[Int32]] = [[], []]
    /// r2 − 0x5e04: 0 = Player 1, 1 = Player 2 (the tab up).
    private(set) var player = 0
    /// r2 − 0x5e10: the field a key goes to.
    private(set) var focus = ControlsDialog.fields[0]
    /// The field the Dialog Manager shows selected (`SelectDialogItemText`, or the field last clicked).
    private(set) var shown = ControlsDialog.fields[0]
    /// The filter's four latches (r2 − 0x5e0b Control, − 0x5e05 Shift, − 0x5e07 Option, − 0x5e09 Command).
    private var latched = [false, false, false, false]
    /// The tab a press on the tab control began on.
    private var tabPress: Int?
    /// What the runner cannot see that the picture shows: the selected field and the tab up.
    private var drawnLook: [Int]?
    /// The answer the close gave (Save = true).
    private(set) var result = false

    public init() {}

    // MARK: - Items (DITL 191)

    static let dialogID: Int16 = 191
    static let save = 1, cancel = 2, tabControl = 3
    /// The edit fields in focus order; field `fields[i]` stores into slot i (X 0x100f57dc).
    static let fields = [5, 7, 9, 11, 13, 15, 17]
    /// The picture items (PICT 190–193, 195–197).
    static let pictures = [4, 6, 8, 10, 12, 14, 16]
    /// The modifier keys a null event binds, in the filter's order: left Control, Shift, Option, Command.
    static let modifiers: [UInt16] = [0x3B, 0x38, 0x3A, 0x37]
    /// Codes a key event may carry that bind nothing: ⌘R, ⌘, ⇧, ⇪, ⌥, ⌃, ⇧R, ⌥R, ⌃R, Fn.
    static let modifierCodes: ClosedRange<UInt16> = 0x36...0x3F
    /// The key-name list.
    static let keyNamesID: Int16 = 130
    /// "??" (X data 0x100f5835).
    static let unknownName: [UInt8] = [0x3F, 0x3F]

    /// X `10043b40`: `STR# 130` entry `code + 1`; outside 0…0x7F, past the list or empty → "??".
    static func keyName(_ code: Int32, strings: [[UInt8]]) -> [UInt8] {
        guard (0...0x7F).contains(code), Int(code) < strings.count, !strings[Int(code)].isEmpty else {
            return unknownName
        }
        return strings[Int(code)]
    }

    // MARK: - The pass

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        var out = PassOutput()
        switch phase {
        case .opening:
            guard open(state: state) else {
                phase = .closed
                return .finish(false)
            }
            phase = .running
            redraw(&out)
            return .stay(out)
        case .closed:
            return .finish(result)                                      // not reached through the front end
        case .running:
            break
        }
        runner.begin(keys: keys)
        for _ in 0...runner.turnsLeft {                                 // each `next` uses at least one turn
            guard let action = runner.next(keys: keys, &out) else { break }
            if let step = act(action, keys: keys, state: &state, &out) { return step }
        }
        if runner.tracking == nil { nullEvent(keys, &out) }             // TrackControl calls no filter
        redraw(&out)
        return .stay(out)
    }

    /// The window's set-up (100435d0..10043728). False when its resources are missing or malformed.
    private mutating func open(state: FrontEndState) -> Bool {
        let res = state.shellResources
        guard let dlog = try? DialogTemplate.load(Self.dialogID, from: res),
              let ditl = try? DialogItemList.load(dlog.itemsID, from: res), ditl.items.count >= 17,
              let cntlID = ditl[Self.tabControl]?.resourceID, let cntl = try? ControlTemplate.load(cntlID, from: res),
              let tabs = try? TabList.load(cntl.value, from: res) else { return false }
        items = ditl
        tabNames = tabs.tabs.map(\.name)
        keyNames = (try? ResourceStringList.load(Self.keyNamesID, from: res)) ?? []
        runner = ModalDialogRunner(items: ditl.items, content: DialogDraw.centred(dlog.bounds), defaultItem: Self.save,
                                   cancelItem: Self.cancel)
        runner.ownItems = Set([Self.tabControl] + Self.fields + Self.pictures)
        runner.screenFiltersKeys = true                                 // the filter 10043f90 takes every key
        var table = state.prefs.keyTable.map { Int32($0) }              // 100435d8..100436c4
        if table.count < 14 { table += Array(repeating: 0, count: 14 - table.count) }
        sets = [Array(table[0..<7]), Array(table[7..<14])]
        player = 0
        focus = Self.fields[0]                                          // 10043628..10043630
        fill()                                                          // 1004370c
        shown = Self.fields[0]                                          // 10043718 SelectDialogItemText(5)
        return true
    }

    /// X `10043930`: the seven fields from the current player's set.
    private mutating func fill() {
        for (slot, n) in Self.fields.enumerated() {
            runner.labels[n] = Self.keyName(sets[player][slot], strings: keyNames)
        }
    }

    // MARK: - Input

    /// One thing the runner handed back.
    private mutating func act(_ action: ModalDialogRunner.Action, keys: HeldKeys, state: inout FrontEndState,
                              _ out: inout PassOutput) -> ScreenStep<Result>? {
        switch action {
        case let .hit(n):
            if n == Self.save { return close(saved: true, state: &state) }
            if n == Self.cancel { return close(saved: false, state: &state) }
        case let .ownPress(n, p):
            if n == Self.tabControl, let tab = tabIndex(at: p) {
                tabPress = tab
                pollTab(keys: keys)
            } else {
                if Self.fields.contains(n) { focusField(n) }             // the pictures: nothing (X 10043850)
                runner.endOwnPress()
            }
        case .ownPoll:
            pollTab(keys: keys)
        case let .key(k, _):
            // keyDown / autoKey (100441b4..100441c4): `(message >> 8) & 0xFF`, sign-extended.
            guard !Self.modifierCodes.contains(k.keyCode & 0xFF) else { break }
            assign(Int32(Int8(truncatingIfNeeded: k.keyCode)), &out)
        }
        return nil
    }

    /// A field clicked (X 10043774): focused and selected.
    private mutating func focusField(_ n: Int) {
        focus = n
        shown = n
    }

    /// The press on a tab, polled: on release over the tab it began on, that tab is chosen (`TrackControl` sets the
    /// value, `ModalDialog` returns item 3).
    private mutating func pollTab(keys: HeldKeys) {
        guard let tab = tabPress else {
            runner.endOwnPress()
            return
        }
        guard !keys.mouseButton else { return }
        tabPress = nil
        runner.endOwnPress()
        if let m = keys.mouse, tabIndex(at: m) == tab { chooseTab(tab) }
    }

    /// Item 3 hit with the control's value `tab + 1` (X 10043798..10043848).
    private mutating func chooseTab(_ tab: Int) {
        focus = Self.fields[0]                                          // 10043798..1004379c, always
        guard tab != player, tab < 2 else { return }
        player = tab
        fill()                                                          // 100437f4 / 10043830
        shown = Self.fields[0]                                          // SelectDialogItemText(5)
    }

    /// X `10043c00`.
    private mutating func assign(_ code: Int32, _ out: inout PassOutput) {
        let name = Self.keyName(code, strings: keyNames)
        var refused = sets[0].contains(code) || sets[1].contains(code) // 10043ca4..10043d88
        if refused && runner.label(focus) == name { refused = false }   // 10043d90..10043dc0: the self-match
        if refused {
            runner.flush()                                              // 1004a170 FlushEvents
            out.requests.append(.beep)                                  // 1004aa50 SysBeep
            return
        }
        runner.labels[focus] = name                                     // 10043de0..10043df0
        if let slot = Self.fields.firstIndex(of: focus) {               // the jump table 0x100f57dc
            sets[player][slot] = code
            focus = Self.fields[(slot + 1) % Self.fields.count]
        } else {
            focus = Self.fields[0]                                      // 10043f58
        }
        shown = focus                                                   // 10043f6c SelectDialogItemText
    }

    /// A null event (10044014..100441ac): the first left-hand modifier down and not latched is assigned and latched;
    /// one up is unlatched; the event ends at an assignment.
    private mutating func nullEvent(_ keys: HeldKeys, _ out: inout PassOutput) {
        for (i, code) in Self.modifiers.enumerated() {
            let down = keys.held.contains(code)
            if down && !latched[i] {
                assign(Int32(code), &out)
                latched[i] = true
                return
            }
            if !down { latched[i] = false }
        }
    }

    /// Item 1 or 2 ended the loop: Save copies both working sets into the prefs (1004386c..100438ec).
    private mutating func close(saved: Bool, state: inout FrontEndState) -> ScreenStep<Result> {
        if saved {
            var table = state.prefs.keyTable
            if table.count < 14 { table += Array(repeating: 0, count: 14 - table.count) }
            for (i, code) in (sets[0] + sets[1]).enumerated() { table[i] = UInt16(truncatingIfNeeded: code) }
            state.prefs.keyTable = table
        }
        tabPress = nil
        runner.close()
        phase = .closed
        result = saved
        return .finish(saved)                                           // nested: nothing restored
    }

    // MARK: - The tab control

    /// The large tabs' height and layout (proc 128, `kControlTabLargeProc`): left-aligned from 8 pixels in, each tab
    /// its title's width plus 12 pixels a side.
    static let tabHeight: Int32 = 24
    static let tabIndent: Int32 = 8
    static let tabPad: Int32 = 12

    /// Tab `tab` (1-based, as the control's value) in the picture; nil when there is none.
    func tabRect(_ tab: Int) -> MacRect? {
        guard tab >= 1, tab <= tabNames.count, let r = runner.rect(Self.tabControl) else { return nil }
        return Self.tabRects(in: r, names: tabNames)[tab - 1]
    }

    static func tabRects(in r: MacRect, names: [[UInt8]]) -> [MacRect] {
        var x = r.left + tabIndent
        return names.map { name in
            let w = DialogFont.geneva9.width(name) + 2 * tabPad
            defer { x += w }
            return MacRect(top: r.top, left: x, bottom: r.top + tabHeight, right: x + w)
        }
    }

    /// The tab (0-based) under `p`, nil when none.
    private func tabIndex(at p: MousePoint) -> Int? {
        guard let r = runner.rect(Self.tabControl) else { return nil }
        return Self.tabRects(in: r, names: tabNames).firstIndex { DialogDraw.contains($0, p) }
    }

    // MARK: - Drawing

    /// The focus ring (Platinum's default accent, 0x9999 0x9999 0xCCCC) and the selected text's highlight (the default
    /// highlight colour, 0xCCCC 0xCCCC 0xFFFF), x1R5G5B5.
    static let focusRing: UInt16 = 0x4E79
    static let highlight: UInt16 = 0x673F
    /// Back tabs (0xDDDD).
    static let backTab: UInt16 = DialogDraw.Colour.frameGrey

    /// The whole window when its picture changed, then its rect to the screen. The buttons are the runner's.
    private mutating func redraw(_ out: inout PassOutput) {
        guard items != nil else { return }
        let look = [shown, player]
        if look != drawnLook {
            drawnLook = look
            runner.invalidate()
        }
        guard runner.needsRedraw() else { return }
        let now = runner, names = tabNames, up = player, selected = shown
        out.ops += now.draw { item, r, _ in
            let n = item.number
            if n == Self.tabControl { return Self.drawTabs(r, names: names, up: up) }
            if Self.fields.contains(n) { return Self.drawField(r, text: now.label(n), selected: n == selected) }
            if Self.pictures.contains(n) {
                guard let id = item.resourceID else { return [] }
                return [.drawPicture(id: id, into: .back, top: r.top, left: r.left)]
            }
            return nil
        }
    }

    /// The tab control: the pane (an etched frame below the tabs), the back tabs, then the front tab joined to it.
    static func drawTabs(_ r: MacRect, names: [[UInt8]], up: Int) -> [RenderOp] {
        let pane = MacRect(top: r.top + tabHeight - 1, left: r.left, bottom: r.bottom, right: r.right)
        var ops = DialogDraw.frame(pane, DialogDraw.Colour.shadow)
        ops += [DialogDraw.rect(MacRect(top: pane.top + 1, left: pane.left + 1, bottom: pane.top + 2,
                                        right: pane.right - 1), DialogDraw.Colour.white),
                DialogDraw.rect(MacRect(top: pane.top + 1, left: pane.left + 1, bottom: pane.bottom - 1,
                                        right: pane.left + 2), DialogDraw.Colour.white)].compactMap { $0 }
        let rects = tabRects(in: r, names: names)
        for (i, t) in rects.enumerated() where i != up { ops += tab(t, title: names[i], front: false) }
        if rects.indices.contains(up) { ops += tab(rects[up], title: names[up], front: true) }
        return ops
    }

    /// One tab: its outline with the top corners cut, filled; the front tab opens into the pane below it.
    static func tab(_ t: MacRect, title: [UInt8], front: Bool) -> [RenderOp] {
        let line = DialogDraw.Colour.shadow
        let fill = front ? DialogDraw.Colour.content : backTab
        let bottom = front ? t.bottom + 1 : t.bottom                    // the front tab covers the pane's top line
        var ops = [DialogDraw.rect(MacRect(top: t.top + 1, left: t.left + 1, bottom: bottom, right: t.right - 1), fill),
                   DialogDraw.rect(MacRect(top: t.top, left: t.left + 2, bottom: t.top + 1, right: t.right - 2), line),
                   DialogDraw.rect(MacRect(top: t.top + 2, left: t.left, bottom: t.bottom, right: t.left + 1), line),
                   DialogDraw.rect(MacRect(top: t.top + 2, left: t.right - 1, bottom: t.bottom, right: t.right), line),
                   DialogDraw.rect(MacRect(top: t.top + 1, left: t.left + 1, bottom: t.top + 2, right: t.left + 2), line),
                   DialogDraw.rect(MacRect(top: t.top + 1, left: t.right - 2, bottom: t.top + 2, right: t.right - 1),
                                   line)].compactMap { $0 }
        if front {
            ops += [DialogDraw.rect(MacRect(top: t.top + 1, left: t.left + 2, bottom: t.top + 2, right: t.right - 2),
                                    DialogDraw.Colour.white),
                    DialogDraw.rect(MacRect(top: t.top + 2, left: t.left + 1, bottom: bottom, right: t.left + 2),
                                    DialogDraw.Colour.white)].compactMap { $0 }
        } else {
            if let base = DialogDraw.rect(MacRect(top: t.bottom - 1, left: t.left, bottom: t.bottom, right: t.right), line) {
                ops.append(base)
            }
        }
        let font = DialogFont.geneva9
        let x = t.left + (t.right - t.left - font.width(title)) / 2
        let baseline = t.top + (tabHeight + font.ascent - font.descent) / 2
        ops += DialogDraw.text(title, x: x, baseline: baseline, colour: DialogDraw.Colour.text)
        return ops
    }

    /// An edit-text field: the etched outer line and black frame 3 and 2 pixels outside its rect, white inside, the
    /// text from its left edge; the selected field shows its text highlighted (`SelectDialogItemText(n, 0, 32767)`)
    /// and the 2-pixel focus ring outside the frame.
    static func drawField(_ r: MacRect, text: [UInt8], selected: Bool) -> [RenderOp] {
        let outer = DialogDraw.inset(r, -3)
        var ops: [RenderOp] = []
        if selected { ops += DialogDraw.frame(DialogDraw.inset(r, -5), focusRing, thickness: 2) }
        ops += [DialogDraw.rect(MacRect(top: outer.top, left: outer.left, bottom: outer.top + 1, right: outer.right),
                                DialogDraw.Colour.shadow),
                DialogDraw.rect(MacRect(top: outer.top + 1, left: outer.left, bottom: outer.bottom, right: outer.left + 1),
                                DialogDraw.Colour.shadow),
                DialogDraw.rect(MacRect(top: outer.bottom - 1, left: outer.left + 1, bottom: outer.bottom,
                                        right: outer.right), DialogDraw.Colour.white),
                DialogDraw.rect(MacRect(top: outer.top + 1, left: outer.right - 1, bottom: outer.bottom - 1,
                                        right: outer.right), DialogDraw.Colour.white)].compactMap { $0 }
        ops += DialogDraw.frame(DialogDraw.inset(r, -2), DialogDraw.Colour.black)
        if let inside = DialogDraw.rect(DialogDraw.inset(r, -1), DialogDraw.Colour.white) { ops.append(inside) }
        let font = DialogFont.geneva9
        if selected, !text.isEmpty,
           let hl = DialogDraw.rect(MacRect(top: r.top, left: r.left, bottom: min(r.top + font.lineHeight, r.bottom),
                                            right: min(r.left + font.width(text), r.right)), highlight) {
            ops.append(hl)
        }
        ops += DialogDraw.text(text, x: r.left, baseline: r.top + font.ascent, colour: DialogDraw.Colour.text, clip: r)
        return ops
    }
}

import Foundation

/// The configuration window — DLOG/DITL 190 "Game - Preferences", `FUN_100047c0(firstLaunch)` → X `FUN_10011240(prefs,
/// firstLaunch)` (10011240..100117a0; the refresh X `100117a0`; grounding C §2; `osx-build.md` D2–D5, ruling 5: as X).
/// Opened by the boot (`FUN_100047c0(1)` when byte pref 2 is 0 or Option is held) and by the menu's PREFERENCES
/// (`FUN_10024e40` → `FUN_100047c0(0)`, then b6).
///
/// **Frozen entry.** `init(firstLaunch:)` — the original's argument (a first launch has no Cancel). It edits the live
/// prefs (`FrontEndState.prefs`) in place and keeps its own snapshot for Cancel and Revert; "Set Controls…" calls the
/// controls window. **Returns** true when it was closed with Save, false otherwise.
///
/// **What X does, built here:**
/// - **Open** (10011240..10011448): the whole prefs block copied as the snapshot (`FUN_1000cfe0(…, 0x34f0)`);
///   `GetNewDialog(190)`; default item 1; the cancel item 2 only when not a first launch (10011310..10011320); "Set
///   Gamepad Controls…" (19) hidden when the HID layer is down (10011328..10011340 — plan ruling 17 hides it always);
///   items 10, 12, 11, 13 deactivated (10011348..10011380: Bypass System Volume, the sound slider and its two labels —
///   not L's item 8, D2); the refresh; on a first launch item 2 deactivated (10011418..10011428); Revert (4)
///   deactivated (10011430..10011438).
/// - **The refresh** (X `100117a0`): items 8, 9, 10, 17 ← bytes 4, 5, 7, 8; the sliders 12, 15 ← ints 0, 1 and their
///   labels 13, 16 ← "%i%%" of them; item 12 active iff byte 7 (10011904..10011934).
/// - **The loop** (10011450..10011738): before each `ModalDialog`, Revert comes alive once anything changed; then by
///   item: 3 Defaults (`FUN_10004f80(0)` = `FUN_10004f20(0)` → `10005150`: bytes 4–8, ints 0–2, both key sets), refresh,
///   changed; 4 Revert (the snapshot copied back, the volume re-applied, refresh, 4 greyed, unchanged); 8, 9, 17 toggle
///   bytes 4, 5, 8; 10 toggles byte 7 and sets item 12's activity; 12, 15 set int 0, 1 from the control, re-apply the
///   volume, `SysBeep(1)`; 18 the controls window (changed only when it returns Save, D4); until item 1 or 2. Item 2
///   copies the snapshot back (keys included). Nothing reaches the disk (C §1b: at quit only).
/// - **Keys:** the standard filter — Return or Enter = item 1; Esc or ⌘. = item 2 when there is a cancel item. A click
///   outside the window beeps (`ModalDialog`). A press on a control is tracked until the button comes up.
///
/// **How it is drawn** (ruling 8, question 6's default): by the game, with `DialogDraw`, centred on the picture; the
/// picture under the window is saved at open and put back at close (the window repaints what it covered: the boot's
/// black and the menu's screen are whole again with no help from the caller). The window redraws only when its picture
/// changes (a click, a key, a press moving in or out of its control, a slider moving) — about 1,800 commands each time.
///
/// **No resources** (`DLOG`/`DITL` 190 not handed in, or malformed): the original asserts on a nil `GetNewDialog`
/// (X 100112cc..100112dc); the replica finishes at once with false, prefs untouched.
public struct ConfigDialog: Sendable {
    public typealias Result = Bool

    public let firstLaunch: Bool

    enum Phase: Equatable, Sendable {
        case opening, running, closed
    }

    /// What a press is following.
    enum Tracking: Equatable, Sendable {
        /// A button or check box.
        case press(DialogDraw.Press)
        /// A slider's thumb, grabbed `grab` pixels right of its centre.
        case thumb(item: Int, grab: Int32)
        /// A slider's track beside the thumb: −10 or +10 a pass while the mouse stays on that side.
        case page(item: Int, step: Int)
    }

    /// One queued input, in the order the menu reads its queue (key events, then mouse-downs).
    enum Event: Equatable, Sendable {
        case key(KeyEvent, command: Bool)
        case click(MousePoint)
    }

    /// Everything the window's picture depends on: a change redraws.
    struct Look: Equatable, Sendable {
        var inactive: Set<Int>
        var values: [Int: Int]
        var labels: [Int: [UInt8]]
        var tracking: Tracking?
    }

    private(set) var phase = Phase.opening
    /// DITL 190 as parsed.
    private(set) var items: DialogItemList?
    /// The group boxes' titles (CNTL 200–202).
    private(set) var groupTitles: [Int: [UInt8]] = [:]
    /// The content's top left in the picture.
    private(set) var origin = MousePoint(h: 0, v: 0)
    /// The window's whole rect in the picture (content and frame): what it saves and restores.
    private(set) var windowRect = MacRect(top: 0, left: 0, bottom: 0, right: 0)
    /// The prefs block at open (the 0x34f0-byte copy at `r1+0x40`).
    private(set) var snapshot: DeimosPrefs?
    /// The cancel item: 2, or nil on a first launch.
    private(set) var cancelItem: Int?
    /// r29: something changed since open or the last Revert.
    private(set) var changed = false
    private(set) var inactive: Set<Int> = []
    private(set) var hidden: Set<Int> = []
    /// The controls' values (check boxes 0/1, sliders 0…100).
    private(set) var values: [Int: Int] = [:]
    /// The two percentage labels.
    private(set) var labels: [Int: [UInt8]] = [:]
    private var tracking: Tracking?
    private var queue: [Event] = []
    /// The picture last drawn; nil = draw at the next pass.
    private var drawn: Look?

    public init(firstLaunch: Bool) {
        self.firstLaunch = firstLaunch
    }

    // MARK: - Items (DITL 190)

    static let dialogID: Int16 = 190
    static let save = 1, cancel = 2, defaults = 3, revert = 4
    static let groups: Set<Int> = [5, 6, 7]
    /// Check box → byte pref (X 10011660 / 100116a4 / 1001150c / 100116e8).
    static let checkBoxBytes: [Int: Int] = [8: 4, 9: 5, 10: 7, 17: 8]
    /// Slider → int pref, and its label (X 10011588 / 100115bc; refresh 1001183c..100118dc).
    static let sliderInts: [Int: Int] = [12: 0, 15: 1]
    static let sliderLabels: [Int: Int] = [12: 13, 15: 16]
    static let setControls = 18, setGamepad = 19
    /// The sliders' range (CNTL 2000/2001 are not in the fork; C §7 assumes 0…100, the prefs' own range).
    static let sliderMin = 0, sliderMax = 100
    static let pageStep = 10

    /// Item `n` is live (not deactivated).
    func isActive(_ n: Int) -> Bool { !inactive.contains(n) }
    func isHidden(_ n: Int) -> Bool { hidden.contains(n) }
    /// Item `n`'s control value.
    func value(_ n: Int) -> Int { values[n] ?? 0 }
    /// Item `n`'s text as shown (the percentage labels as set, else the DITL's).
    func label(_ n: Int) -> [UInt8] { labels[n] ?? items?[n].text ?? [] }

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
            out.ops.append(DialogDraw.saveUnder(windowRect))
            phase = .running
            redraw(state: state, &out)
            return .stay(out)
        case .closed:
            return .finish(false)
        case .running:
            break
        }
        if case let .controlsDialog(saved)? = returned {                // 1001160c..10011614
            if saved { changed = true }
            drawn = nil                                                 // the controls window drew over this one
        }
        let command = keys.held.contains(0x37) || keys.held.contains(0x36)
        queue += keys.keyEvents.map { Event.key($0, command: command) }
        queue += keys.mouseDowns.map(Event.click)
        // Bound: each turn either polls the press once (and stops while it is held) or consumes one queued event; the
        // press a click starts is polled once in its own turn. Events behind a held press wait for its release.
        for _ in 0...(queue.count + 1) {
            if tracking != nil {
                if let step = follow(keys: keys, state: &state, &out) { return step }
                if tracking != nil { break }
                continue
            }
            guard !queue.isEmpty else { break }
            let event = queue.removeFirst()
            if let step = dispatch(event, keys: keys, state: &state, &out) { return step }
            if tracking != nil { break }
        }
        if changed { inactive.remove(Self.revert) }                     // 10011450..1001147c
        redraw(state: state, &out)
        return .stay(out)
    }

    /// The window's set-up (10011240..10011448). False when its resources are missing or malformed.
    private mutating func open(state: FrontEndState) -> Bool {
        let res = state.shellResources
        guard let dlog = try? DialogTemplate.load(Self.dialogID, from: res),
              let ditl = try? DialogItemList.load(dlog.itemsID, from: res), ditl.items.count >= 20 else { return false }
        items = ditl
        for n in Self.groups {
            if let id = ditl[n].resourceID, let c = try? ControlTemplate.load(id, from: res) { groupTitles[n] = c.title }
        }
        let content = DialogDraw.centred(dlog.bounds)
        origin = MousePoint(h: content.left, v: content.top)
        windowRect = DialogDraw.frameRect(content: content)
        snapshot = state.prefs                                          // 1001129c..100112a8
        cancelItem = firstLaunch ? nil : Self.cancel                    // 10011310..10011320
        hidden = [Self.setGamepad]                                      // 10011328..10011340 (ruling 17)
        inactive = [10, 12, 11, 13]                                     // 10011348..10011380
        refresh(state.prefs)                                            // 10011414
        if firstLaunch { inactive.insert(Self.cancel) }                 // 10011418..10011428
        inactive.insert(Self.revert)                                    // 10011430..10011438
        return true
    }

    /// X `100117a0`.
    private mutating func refresh(_ p: DeimosPrefs) {
        for (item, byte) in Self.checkBoxBytes { values[item] = min(Int(p.bytePrefs[byte]), 1) }   // SetControlValue pins
        for (item, n) in Self.sliderInts {
            let v = p.intPrefs[n]
            values[item] = min(max(Int(v), Self.sliderMin), Self.sliderMax)
            labels[Self.sliderLabels[item]!] = Array("\(v)%".utf8)      // "%i%%"
        }
        if p.bytePrefs[7] != 0 { inactive.remove(12) } else { inactive.insert(12) }   // 10011904..10011934
    }

    // MARK: - Input

    /// One queued event.
    private mutating func dispatch(_ event: Event, keys: HeldKeys, state: inout FrontEndState,
                                   _ out: inout PassOutput) -> ScreenStep<Result>? {
        switch event {
        case let .key(k, command):
            if k.charCode == 0x0D || k.charCode == 0x03 { return hit(Self.save, state: &state, &out) }   // Return, Enter
            if let c = cancelItem, k.charCode == 0x1B || (command && k.charCode == 0x2E) {             // Esc, ⌘.
                return hit(c, state: &state, &out)
            }
            return nil
        case let .click(p):
            guard let items else { return nil }
            guard DialogDraw.contains(windowRect, p) else {             // outside the modal window
                out.requests.append(.beep)
                return nil
            }
            guard let n = DialogDraw.hit(p, items: items.items, origin: origin, candidate: { item in
                item.enabled && !self.hidden.contains(item.number) && !self.inactive.contains(item.number)
                    && !Self.groups.contains(item.number)
                    && [.button, .checkBox, .control].contains(item.kind)
            }) else { return nil }
            let rect = DialogDraw.offset(items[n].rect, by: origin)
            if Self.sliderInts[n] != nil {
                let thumb = DialogDraw.sliderThumb(rect, value: value(n), min: Self.sliderMin, max: Self.sliderMax)
                if DialogDraw.contains(thumb, p) {
                    tracking = .thumb(item: n, grab: p.h - (thumb.left + thumb.right) / 2)
                } else {
                    let step = p.h < thumb.left ? -Self.pageStep : Self.pageStep
                    page(n, step)                                       // the action proc runs at the press
                    tracking = .page(item: n, step: step)
                    return pollPage(keys: keys, fresh: true, state: &state, &out)
                }
            } else {
                tracking = .press(DialogDraw.Press(item: n, rect: rect, at: p))
            }
            return follow(keys: keys, state: &state, &out)
        }
    }

    /// One poll of the press being followed; the item's action when it comes up over the control.
    private mutating func follow(keys: HeldKeys, state: inout FrontEndState,
                                 _ out: inout PassOutput) -> ScreenStep<Result>? {
        guard let t = tracking, let items else { return nil }
        switch t {
        case var .press(press):
            let up = press.poll(mouse: keys.mouse, down: keys.mouseButton)
            guard let inside = up else {
                tracking = .press(press)
                return nil
            }
            tracking = nil
            return inside ? hit(press.item, state: &state, &out) : nil
        case let .thumb(n, grab):
            let rect = DialogDraw.offset(items[n].rect, by: origin)
            if let m = keys.mouse { setSlider(n, DialogDraw.sliderValue(rect, x: m.h - grab, min: Self.sliderMin,
                                                                       max: Self.sliderMax)) }
            guard !keys.mouseButton else { return nil }
            tracking = nil
            return hit(n, state: &state, &out)                          // the thumb always reports its part
        case .page:
            return pollPage(keys: keys, fresh: false, state: &state, &out)
        }
    }

    /// The track press: another page each pass while the mouse stays in the control on the thumb's far side; on
    /// release, the item is hit when the mouse is over the control.
    private mutating func pollPage(keys: HeldKeys, fresh: Bool, state: inout FrontEndState,
                                   _ out: inout PassOutput) -> ScreenStep<Result>? {
        guard case let .page(n, step)? = tracking, let items else { return nil }
        let rect = DialogDraw.offset(items[n].rect, by: origin)
        if keys.mouseButton {
            if !fresh, let m = keys.mouse, DialogDraw.contains(rect, m) {
                let thumb = DialogDraw.sliderThumb(rect, value: value(n), min: Self.sliderMin, max: Self.sliderMax)
                if step < 0 ? m.h < thumb.left : m.h >= thumb.right { page(n, step) }
            }
            return nil
        }
        tracking = nil
        return DialogDraw.contains(rect, keys.mouse) ? hit(n, state: &state, &out) : nil
    }

    private mutating func page(_ n: Int, _ step: Int) { setSlider(n, value(n) + step) }

    /// The slider's value, pinned, and its label live (the action proc's relabel).
    private mutating func setSlider(_ n: Int, _ v: Int) {
        let pinned = min(max(v, Self.sliderMin), Self.sliderMax)
        values[n] = pinned
        labels[Self.sliderLabels[n]!] = Array("\(pinned)%".utf8)
    }

    // MARK: - Items hit

    /// `ModalDialog` returned item `n` (10011490..10011738).
    private mutating func hit(_ n: Int, state: inout FrontEndState, _ out: inout PassOutput) -> ScreenStep<Result>? {
        guard let snapshot else { return nil }
        switch n {
        case Self.save:
            return close(saved: true, state: &state, &out)
        case Self.cancel:
            state.prefs = snapshot                                      // 10011744..10011750
            return close(saved: false, state: &state, &out)
        case Self.defaults:                                             // 100114b4..100114cc
            Self.defaults(&state.prefs)
            refresh(state.prefs)
            changed = true
        case Self.revert:                                               // 100114d0..10011508
            state.prefs = snapshot
            refresh(state.prefs)
            inactive.insert(Self.revert)
            changed = false
        case 8, 9, 10, 17:                                              // the toggles
            let byte = Self.checkBoxBytes[n]!
            let v: UInt8 = state.prefs.bytePrefs[byte] == 0 ? 1 : 0     // cntlzw: !value
            state.prefs.bytePrefs[byte] = v
            values[n] = Int(v)
            if n == 10 {                                                // 10011548..1001157c
                if v != 0 { inactive.remove(12) } else { inactive.insert(12) }
            }
            changed = true
        case 12, 15:                                                    // 10011588..100115ec
            let i = Self.sliderInts[n]!
            state.prefs.intPrefs[i] = Int32(value(n))
            labels[Self.sliderLabels[n]!] = Array("\(value(n))%".utf8)
            out.requests.append(.beep)                                  // 1004aa50: SysBeep(1)
            changed = true
        case Self.setControls:                                          // 100115f0..10011624 (D4)
            if changed { inactive.remove(Self.revert) }
            redraw(state: state, &out)
            return .call(.controlsDialog(ControlsDialog()), out)
        default:
            break
        }
        return nil
    }

    /// `FUN_10004f20(0)` → `FUN_100050f0` (X 10004f80 → 10005150): byte 7 = 0; ints 0, 1, 2 = 50, 100, 50; bytes 5, 6 = 0;
    /// byte 4 = 1; byte 8 = 0; both key sets.
    static func defaults(_ p: inout DeimosPrefs) {
        p.bytePrefs[7] = 0
        p.intPrefs[0] = 50
        p.intPrefs[1] = 100
        p.intPrefs[2] = 50
        p.bytePrefs[5] = 0
        p.bytePrefs[6] = 0
        p.bytePrefs[4] = 1
        p.bytePrefs[8] = 0
        p.keyTable = DeimosPrefs.fresh.keyTable
    }

    /// Item 1 or 2 ended the loop (10011728..10011788): the window disposed of — the picture under it put back.
    private mutating func close(saved: Bool, state: inout FrontEndState,
                                _ out: inout PassOutput) -> ScreenStep<Result> {
        tracking = nil
        queue = []
        phase = .closed
        out.ops += DialogDraw.restoreUnder(windowRect)
        return .finish(saved, out)
    }

    // MARK: - Drawing

    private var look: Look {
        var shownTracking = tracking
        if case let .page(n, _)? = tracking { shownTracking = .page(item: n, step: 0) }   // the side does not show
        if case let .thumb(n, _)? = tracking { shownTracking = .thumb(item: n, grab: 0) }
        return Look(inactive: inactive, values: values, labels: labels, tracking: shownTracking)
    }

    /// The whole window, when its picture changed; then its rect to the screen.
    private mutating func redraw(state: FrontEndState, _ out: inout PassOutput) {
        let now = look
        guard now != drawn, let items else { return }
        drawn = now
        let content = MacRect(top: windowRect.top + DialogDraw.frameWidth, left: windowRect.left + DialogDraw.frameWidth,
                              bottom: windowRect.bottom - DialogDraw.frameWidth,
                              right: windowRect.right - DialogDraw.frameWidth)
        var ops = DialogDraw.window(content: content)
        var pressed: Int?
        if case let .press(p)? = tracking, p.inside { pressed = p.item }
        for item in items.items where !hidden.contains(item.number) {
            let n = item.number, r = DialogDraw.offset(item.rect, by: origin), active = isActive(n)
            if Self.groups.contains(n) {
                ops += DialogDraw.groupBox(r, title: groupTitles[n] ?? [], active: active)
            } else if Self.sliderInts[n] != nil {
                ops += DialogDraw.slider(r, value: value(n), min: Self.sliderMin, max: Self.sliderMax, active: active)
            } else {
                switch item.kind {
                case .button:
                    let look: DialogDraw.ButtonLook = !active ? .inactive : pressed == n ? .pressed : .normal
                    ops += DialogDraw.pushButton(r, title: item.text, look: look, isDefault: n == Self.save)
                case .checkBox:
                    ops += DialogDraw.checkBox(r, title: item.text, checked: value(n) != 0, pressed: pressed == n,
                                               active: active)
                case .staticText:
                    ops += DialogDraw.textBox(label(n), in: r,
                                              colour: active ? DialogDraw.Colour.text : DialogDraw.Colour.greyText)
                default:
                    break
                }
            }
        }
        out.ops += ops
        out.ops.append(.screenBlit(src: windowRect, dst: windowRect))
    }
}

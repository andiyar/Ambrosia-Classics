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
///   copies the snapshot back (keys included); then, Save or Cancel, the volume is re-applied (10011758). Nothing
///   reaches the disk (C §1b: at quit only).
/// - **The volume** (X `10048c20`, at Revert, a slider's release and the close): its sound half is skipped on OS X,
///   its music half sets the music level from int pref 1 — `MusicCue.level` (`applyVolume`).
/// - **Keys and clicks** are `ModalDialogRunner`'s (the standard filter, `ModalDialog`, `TrackControl`): Return or
///   Enter = item 1; Esc or ⌘. = item 2 when there is a cancel item; a click outside the window beeps, a click on its
///   frame or on no live item does nothing; any other key comes back unhandled and is ignored. The two sliders are
///   this screen's own items (the runner's extension point).
///
/// **How it is drawn** (ruling 8, question 6's default): by the game, with `DialogDraw`, centred on the picture; the
/// picture under the window is saved at open and put back at close (the window repaints what it covered: the boot's
/// black and the menu's screen are whole again with no help from the caller). The window redraws only when its picture
/// changes (a click, a key, a press moving in or out of its control, a slider moving) — about 2,470 commands each time
/// (measured: the opening pass is 2,473 ops, the save under the window included).
///
/// **No resources** (`DLOG`/`DITL` 190 not handed in, or malformed): the original asserts on a nil `GetNewDialog`
/// (X 100112cc..100112dc); the replica finishes at once with false, prefs untouched.
public struct ConfigDialog: Sendable {
    public typealias Result = Bool

    public let firstLaunch: Bool

    enum Phase: Equatable, Sendable {
        case opening, running, closed
    }

    /// What a press on a slider is following (the sliders are the screen's own items: CNTL 2000/2001).
    enum Slide: Equatable, Sendable {
        /// The thumb, grabbed `grab` pixels right of its centre.
        case thumb(item: Int, grab: Int32)
        /// The track beside the thumb: −10 or +10 a pass while the mouse stays on that side.
        case page(item: Int, step: Int)
    }

    private(set) var phase = Phase.opening
    /// DITL 190 as parsed.
    private(set) var items: DialogItemList?
    /// The modal loop: the item states, the queued input, the press, the redraw check. Empty until the window opens.
    private(set) var runner = ModalDialogRunner(items: [], content: MacRect(top: 0, left: 0, bottom: 0, right: 0),
                                                defaultItem: ConfigDialog.save, cancelItem: nil)
    /// The group boxes' titles (CNTL 200–202).
    private(set) var groupTitles: [Int: [UInt8]] = [:]
    /// The prefs block at open (the 0x34f0-byte copy at `r1+0x40`).
    private(set) var snapshot: DeimosPrefs?
    /// r29: something changed since open or the last Revert.
    private(set) var changed = false
    private var slide: Slide?
    /// The answer the close gave (Save = true). The front end pops a finished screen and never passes it again; a
    /// stray pass after the close repeats this answer rather than inventing one.
    private(set) var result = false

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

    /// The cancel item: 2, or nil on a first launch.
    var cancelItem: Int? { runner.cancelItem }
    /// Item `n` is live (not deactivated).
    func isActive(_ n: Int) -> Bool { runner.isActive(n) }
    func isHidden(_ n: Int) -> Bool { runner.hidden.contains(n) }
    /// Item `n`'s control value.
    func value(_ n: Int) -> Int { runner.value(n) }
    /// Item `n`'s text as shown (the percentage labels as set, else the DITL's).
    func label(_ n: Int) -> [UInt8] { runner.label(n) }

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
            out.ops.append(DialogDraw.saveUnder(runner.windowRect))
            phase = .running
            redraw(&out)
            return .stay(out)
        case .closed:
            return .finish(result)                                      // not reached through the front end
        case .running:
            break
        }
        if case let .controlsDialog(saved)? = returned {                // 1001160c..10011614
            if saved { changed = true }
            runner.invalidate()                                         // the controls window drew over this one
        }
        runner.begin(keys: keys)
        for _ in 0...runner.turnsLeft {                                 // each `next` uses at least one turn
            guard let action = runner.next(keys: keys, &out) else { break }
            if let step = act(action, keys: keys, state: &state, &out) { return step }
        }
        if changed { runner.inactive.remove(Self.revert) }              // 10011450..1001147c
        redraw(&out)
        return .stay(out)
    }

    /// The window's set-up (10011240..10011448). False when its resources are missing or malformed.
    private mutating func open(state: FrontEndState) -> Bool {
        let res = state.shellResources
        guard let dlog = try? DialogTemplate.load(Self.dialogID, from: res),
              let ditl = try? DialogItemList.load(dlog.itemsID, from: res), ditl.items.count >= 20 else { return false }
        items = ditl
        for n in Self.groups {
            if let id = ditl[n]?.resourceID, let c = try? ControlTemplate.load(id, from: res) { groupTitles[n] = c.title }
        }
        runner = ModalDialogRunner(items: ditl.items, content: DialogDraw.centred(dlog.bounds), defaultItem: Self.save,
                                   cancelItem: firstLaunch ? nil : Self.cancel)   // 10011310..10011320
        runner.ownItems = Set(Self.sliderInts.keys)
        snapshot = state.prefs                                          // 1001129c..100112a8
        runner.hidden = [Self.setGamepad]                               // 10011328..10011340 (ruling 17)
        runner.inactive = [10, 12, 11, 13]                              // 10011348..10011380
        refresh(state.prefs)                                            // 10011414
        if firstLaunch { runner.inactive.insert(Self.cancel) }          // 10011418..10011428
        runner.inactive.insert(Self.revert)                             // 10011430..10011438
        return true
    }

    /// X `100117a0`.
    private mutating func refresh(_ p: DeimosPrefs) {
        for (item, byte) in Self.checkBoxBytes { runner.values[item] = min(Int(p.bytePrefs[byte]), 1) }   // pinned
        for (item, n) in Self.sliderInts {
            let v = p.intPrefs[n]
            runner.values[item] = min(max(Int(v), Self.sliderMin), Self.sliderMax)
            runner.labels[Self.sliderLabels[item]!] = Array("\(v)%".utf8)  // "%i%%"
        }
        if p.bytePrefs[7] != 0 { runner.inactive.remove(12) } else { runner.inactive.insert(12) }   // 10011904..10011934
    }

    // MARK: - Input

    /// One thing the runner handed back.
    private mutating func act(_ action: ModalDialogRunner.Action, keys: HeldKeys, state: inout FrontEndState,
                              _ out: inout PassOutput) -> ScreenStep<Result>? {
        switch action {
        case let .hit(n):
            return hit(n, state: &state, &out)
        case let .ownPress(n, p):                                       // a slider
            guard let rect = runner.rect(n) else {
                runner.endOwnPress()
                return nil
            }
            let thumb = DialogDraw.sliderThumb(rect, value: value(n), min: Self.sliderMin, max: Self.sliderMax)
            if DialogDraw.contains(thumb, p) {
                slide = .thumb(item: n, grab: p.h - (thumb.left + thumb.right) / 2)
                return followSlide(keys: keys, state: &state, &out)
            }
            let step = p.h < thumb.left ? -Self.pageStep : Self.pageStep
            page(n, step)                                               // the action proc runs at the press
            slide = .page(item: n, step: step)
            return pollPage(keys: keys, fresh: true, state: &state, &out)
        case .ownPoll:
            return followSlide(keys: keys, state: &state, &out)
        case .key:                                                      // no item here takes typing
            return nil
        }
    }

    /// One poll of a slider's thumb or track press.
    private mutating func followSlide(keys: HeldKeys, state: inout FrontEndState,
                                      _ out: inout PassOutput) -> ScreenStep<Result>? {
        switch slide {
        case let .thumb(n, grab)?:
            if let m = keys.mouse, let rect = runner.rect(n) {
                setSlider(n, DialogDraw.sliderValue(rect, x: m.h - grab, min: Self.sliderMin, max: Self.sliderMax))
            }
            guard !keys.mouseButton else { return nil }
            endSlide()
            return hit(n, state: &state, &out)                          // the thumb always reports its part
        case .page?:
            return pollPage(keys: keys, fresh: false, state: &state, &out)
        case nil:
            runner.endOwnPress()
            return nil
        }
    }

    /// The track press: another page each pass while the mouse stays in the control on the thumb's far side; on
    /// release, the item is hit when the mouse is over the control.
    private mutating func pollPage(keys: HeldKeys, fresh: Bool, state: inout FrontEndState,
                                   _ out: inout PassOutput) -> ScreenStep<Result>? {
        guard case let .page(n, step)? = slide, let rect = runner.rect(n) else { return nil }
        if keys.mouseButton {
            if !fresh, let m = keys.mouse, DialogDraw.contains(rect, m) {
                let thumb = DialogDraw.sliderThumb(rect, value: value(n), min: Self.sliderMin, max: Self.sliderMax)
                if step < 0 ? m.h < thumb.left : m.h >= thumb.right { page(n, step) }
            }
            return nil
        }
        endSlide()
        return DialogDraw.contains(rect, keys.mouse) ? hit(n, state: &state, &out) : nil
    }

    private mutating func endSlide() {
        slide = nil
        runner.endOwnPress()
    }

    private mutating func page(_ n: Int, _ step: Int) { setSlider(n, value(n) + step) }

    /// The slider's value, pinned, and its label live (the action proc's relabel).
    private mutating func setSlider(_ n: Int, _ v: Int) {
        let pinned = min(max(v, Self.sliderMin), Self.sliderMax)
        runner.values[n] = pinned
        runner.labels[Self.sliderLabels[n]!] = Array("\(pinned)%".utf8)
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
        case Self.defaults:                                             // 100114b4..100114cc (no volume call)
            Self.defaults(&state.prefs)
            refresh(state.prefs)
            changed = true
        case Self.revert:                                               // 100114d0..10011508
            state.prefs = snapshot
            Self.applyVolume(state.prefs, &out)                         // 100114e4
            refresh(state.prefs)
            runner.inactive.insert(Self.revert)
            changed = false
        case 8, 9, 10, 17:                                              // the toggles
            let byte = Self.checkBoxBytes[n]!
            let v: UInt8 = state.prefs.bytePrefs[byte] == 0 ? 1 : 0     // cntlzw: !value
            state.prefs.bytePrefs[byte] = v
            runner.values[n] = Int(v)
            if n == 10 {                                                // 10011548..1001157c
                if v != 0 { runner.inactive.remove(12) } else { runner.inactive.insert(12) }
            }
            changed = true
        case 12, 15:                                                    // 10011588..100115ec
            let i = Self.sliderInts[n]!
            state.prefs.intPrefs[i] = Int32(value(n))
            runner.labels[Self.sliderLabels[n]!] = Array("\(value(n))%".utf8)
            Self.applyVolume(state.prefs, &out)                         // 100115a4 / 100115d8
            out.requests.append(.beep)                                  // 1004aa50: SysBeep(1)
            changed = true
        case Self.setControls:                                          // 100115f0..10011624 (D4)
            if changed { runner.inactive.remove(Self.revert) }
            redraw(&out)
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

    /// X `10048c20`, the volume routine. Its gate is the music system being up (`-0x5dd8(r2)`, set when the stream
    /// library opened, `10048528`): the host's — with no audio engine no sink hears the cue. Its sound half
    /// (10048c38..10048c74) writes the device volume from int pref 0 only when byte 7 is set and the system is older
    /// than 10.0 (`FUN_100474b0`: Gestalt 'sysv' ≥ 0x0A00), so never on OS X — and the replica has no master gain
    /// (D31). Its music half, `FUN_10049580` (10048c78), sets the music level from int pref 1 (`FUN_100495c0` →
    /// `100d4d54`): `MusicCue.level`, the cue the session sends for the same pref at a level start.
    static func applyVolume(_ prefs: DeimosPrefs, _ out: inout PassOutput) {
        out.music.append(.level(prefs.intPrefs[1]))
    }

    /// Item 1 or 2 ended the loop (10011728..10011788): the volume re-applied (10011758), the window disposed of — the
    /// picture under it put back.
    private mutating func close(saved: Bool, state: inout FrontEndState,
                                _ out: inout PassOutput) -> ScreenStep<Result> {
        slide = nil
        runner.close()
        phase = .closed
        result = saved
        Self.applyVolume(state.prefs, &out)
        out.ops += DialogDraw.restoreUnder(runner.windowRect)
        return .finish(saved, out)
    }

    // MARK: - Drawing

    /// The whole window when its picture changed (the runner's check), then its rect to the screen. The group boxes
    /// and the sliders are this screen's own drawing; the runner draws the buttons, check boxes and text.
    private mutating func redraw(_ out: inout PassOutput) {
        guard items != nil, runner.needsRedraw() else { return }
        let titles = groupTitles, now = runner
        out.ops += now.draw { item, r, active in
            let n = item.number
            if Self.groups.contains(n) { return DialogDraw.groupBox(r, title: titles[n] ?? [], active: active) }
            if Self.sliderInts[n] != nil {
                return DialogDraw.slider(r, value: now.value(n), min: Self.sliderMin, max: Self.sliderMax, active: active)
            }
            return nil
        }
    }
}

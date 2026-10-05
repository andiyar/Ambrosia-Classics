import AppKit
import BubbleTroubleCore
import BubbleTroubleRender

/// The Preferences dialog (DLOG 190), transcribed from `_PrefsDialog @ 0000ea93` and its filter `_PrefsDlgFilter
/// @ 0000e209` (closes U9 — the item ↔ pref wiring below is read from those two functions and their helpers):
///
/// - Frame (DITL 190): 1 Save (default), 2 Cancel (cancel item), 3 Defaults, 4 Revert, 5–7 the area buttons (user
///   items; 8–10 their `cicn 1000/1001/1002`, the current area's plotted `kTransformSelected` by
///   `_HiliteCurrentPrefsArea @ 0000e150`), 11–13 "Sound" / "Keys" / "Misc", 14–22 framed in RGB 0x7fff grey by
///   `_TouchUpPrefsDialog @ 0000e083`, 23 the help line, 24 `PICT 7000`, 25 the top-left corner.
/// - Areas (`_ChangeArea @ 0000e9d8`: snd 17, `ShortenDITL` to 25, `AppendDITL(190 + area)`):
///   1 Sound (DITL 191): 26 `CNTL 1001` "Sound FX" popup = short 0x33 (≠ Off → short 0x34; snd 18), 27 `CNTL 1000`
///     "Music" popup = short 0x35 (≠ Off → short 0x36; snd 13 played at the music level), 28 "Title screen music" =
///     bool 0x40 (`_ResetPrefsSoundValues @ 0000d978`);
///   2 Keys (DITL 192): 26–30 key fields Left/Right/Up/Down/Push of the current set (short 0x38), 31 "New Set...",
///     32 "Delete Set", 33 `CNTL 1009` "Key Sets" popup, 34–38 the same names as static text (set 1 "Defaults"
///     cannot be edited), 39–43 labels (`_ResetPrefsKeysValues @ 0000e491`);
///   3 Misc (DITL 193): 26 "Full screen mode" = bool 0x37, 27 "Show Bubbles" = bool 0x36, 28 "Show Stars" = bool
///     0x35, 29 "Hold Escape to exit" = bool 0x3d (`_ResetPrefsGameValues @ 0000d8dc`).
/// - Help line (`_CheckPrefsHelp @ 0000d1c7` on null events): the first shown item under the mouse picks STR# 135
///   item n (n ≤ 25) or STR# 131+area item n − 25; the very first check of the run is item 24 ("Welcome…").
/// - Keys: a key typed in the Keys area (set ≠ 1) is the virtual key code for the target field (`_SetPrefsKey @
///   0000de4c`: beep if another field has it, else name from STR# 130, advance the target, `_SaveKeys`); Control /
///   Shift / Option / Command are taken on null events. Return/Enter → Save, Esc / ⌘. → Cancel (flashed), Tab moves
///   the TextEdit focus only; every other key is eaten.
/// - Save keeps the edited prefs, Cancel restores the ones at open; both then `_SaveGamePrefs` — the caller's job.
@MainActor final class BTXPrefsWindow {
    // `_firstTime_73946`, `_played_74034`, `_playedTwo_74035`, `_keyDown1…4_7397x`: statics for the app's life.
    private static var helpFirstTime = true
    private static var playedEggOne = false
    private static var playedEggTwo = false
    private static var shiftLatch = false, optionLatch = false, commandLatch = false, controlLatch = false

    private let dialogs: BTXDialogs
    /// `gPrefsData`, edited live.
    private var prefs: BTXPrefs
    /// `gSavedPrefsData`: Revert / Cancel.
    private let saved: BTXPrefs
    private let fullScreen: Bool
    private var completion: ((BTXPrefs) -> Void)?
    private var dialog: CarbonDialog?
    /// `gWhichPrefs`: 1 Sound, 2 Keys, 3 Misc.
    private var area = 1
    /// `gKeyTarget`: the key field the next key goes to (0x1a…0x1e).
    private var keyTarget = 0x1a
    /// `gLastHelpInfo`: (STR# id, index) on the help line.
    private var lastHelp = (list: 0, index: 0)
    /// `gLeftCode` … `gPushCode` + `gKeySetName` as `_InitControls` loads them.
    private var keys: KeySet
    private var areaIcons: [DialogPictureView] = []
    private let keyNames: [String]

    init(dialogs: BTXDialogs, prefs: BTXPrefs, fullScreen: Bool, completion: @escaping (BTXPrefs) -> Void) {
        self.dialogs = dialogs
        self.prefs = prefs
        saved = prefs
        self.fullScreen = fullScreen
        self.completion = completion
        keys = prefs.currentKeySet
        keyNames = (try? dialogs.data.strings(130)) ?? []
    }

    // MARK: - Open / close

    func open() {
        guard let t = BTXDialogResources.dialog(190, data: dialogs.data) else { finish(saved); return }
        let d = CarbonDialog(template: t, data: dialogs.data, art: dialogs.art)
        dialog = d
        d.defaultItem = 1
        d.cancelItem = 2
        area = 1
        lastHelp = (0, 0)
        touchUp(d)
        for (i, n) in (8...10).enumerated() {
            guard let r = d.item(n)?.rect else { continue }
            let v = DialogPictureView(frame: r)
            v.image = (try? dialogs.art.cicn(1000 + i)).flatMap(BTXDialogResources.cgImage)
            d.root.addSubview(v)
            areaIcons.append(v)
        }
        hiliteCurrentArea()
        dialogs.playSound(SoundCue(slot: 0x16, priority: 10, delayFrames: 0), nil)
        addItems(d)
        resetSoundValues(d)
        // `BTXDialogs` holds this window while it is open; the dialog's closures only point back weakly.
        d.keyFilter = { [weak self] key in self?.filter(key) ?? true }
        d.nullEvent = { [weak self] in self?.nullEvent() }
        d.itemHit = { [weak self] item in self?.hit(item) }
        dialogs.open(d, grouped: true, fullScreen: fullScreen)
    }

    private func finish(_ result: BTXPrefs) {
        if let d = dialog {
            d.keyFilter = nil
            d.nullEvent = nil
            d.itemHit = nil
            dialogs.dismiss(d)
        }
        dialog = nil
        let done = completion
        completion = nil
        done?(result)
    }

    // MARK: - Drawing helpers

    /// `_TouchUpPrefsDialog`: `FrameRect` of items 14…22 in RGB (0x7fff, 0x7fff, 0x7fff), pen 1×1.
    private func touchUp(_ d: CarbonDialog) {
        let rects = (14...22).compactMap { d.item($0)?.rect }
        d.root.decorations.append { cg in
            cg.setFillColor(CGColor(red: 0x7fff / 65535.0, green: 0x7fff / 65535.0, blue: 0x7fff / 65535.0, alpha: 1))
            for r in rects {
                cg.fill(CGRect(x: r.minX, y: r.minY, width: r.width, height: 1))
                cg.fill(CGRect(x: r.minX, y: r.maxY - 1, width: r.width, height: 1))
                cg.fill(CGRect(x: r.minX, y: r.minY, width: 1, height: r.height))
                cg.fill(CGRect(x: r.maxX - 1, y: r.minY, width: 1, height: r.height))
            }
        }
    }

    /// `_HiliteCurrentPrefsArea`.
    private func hiliteCurrentArea() {
        for (i, v) in areaIcons.enumerated() { v.darkened = i + 1 == area }
    }

    // MARK: - Areas

    /// `_AddItems(dialog, 190 + area)` — `AppendDITL` numbering from 26.
    private func addItems(_ d: CarbonDialog) {
        if let items = BTXDialogResources.items(ditl: 190 + area, data: dialogs.data, firstNumber: d.items.count + 1) {
            d.append(items)
        }
        // The area icons stay above the appended items' views.
        for v in areaIcons { d.root.addSubview(v) }
    }

    /// `_ChangeArea`.
    private func changeArea(_ d: CarbonDialog, to newArea: Int) {
        dialogs.playSound(SoundCue(slot: 0x11, priority: 10, delayFrames: 0), nil)
        area = newArea
        hiliteCurrentArea()
        d.shorten(to: 0x19)
        addItems(d)
        switch area {
        case 2:
            keyTarget = 0x1a
            resetKeysValues(d)
        case 3: resetGameValues(d)
        case 1: resetSoundValues(d)
        default: break
        }
    }

    private func resetCurrentArea(_ d: CarbonDialog) {
        switch area {
        case 2: resetKeysValues(d)
        case 3: resetGameValues(d)
        case 1: resetSoundValues(d)
        default: break
        }
    }

    /// `_ResetPrefsSoundValues @ 0000d978`.
    private func resetSoundValues(_ d: CarbonDialog) {
        d.setValue(0x1a, prefs.sfxVolume)
        d.setValue(0x1b, prefs.musicVolume)
        d.setValue(0x1c, prefs.titleMusic ? 1 : 0)
    }

    /// `_ResetPrefsGameValues @ 0000d8dc`.
    private func resetGameValues(_ d: CarbonDialog) {
        d.setValue(0x1a, prefs.fullScreen ? 1 : 0)
        d.setValue(0x1b, prefs.showAirBubbles ? 1 : 0)
        d.setValue(0x1c, prefs.showStars ? 1 : 0)
        d.setValue(0x1d, prefs.holdEscapeToExit ? 1 : 0)
    }

    /// `_ResetPrefsKeysValues @ 0000e491`.
    private func resetKeysValues(_ d: CarbonDialog) {
        let fields: ClosedRange<Int>
        if prefs.currentKeySetIndex == 1 {
            for n in 0x22...0x26 { d.setHidden(n, false) }
            for n in 0x1a...0x1e { d.setHidden(n, true) }
            d.setActive(0x20, false)
            fields = 0x22...0x26
        } else {
            for n in 0x22...0x26 { d.setHidden(n, true) }
            for n in 0x1a...0x1e { d.setHidden(n, false) }
            d.setActive(0x20, true)
            fields = 0x1a...0x1e
        }
        keys = prefs.currentKeySet                                   // `_InitControls`
        for (n, code) in zip(fields, keys.codes) { d.setText(n, codeToName(code)) }
        if prefs.currentKeySetIndex != 1 { d.selectText(keyTarget, from: 0, to: 0xff) }
        // The Key Sets popup: item 1 ("Defaults") kept, then "(-" and sets 2…short 0x37 by name.
        var titles = Array(BTXDialogResources.menuItems(1009, data: dialogs.data).prefix(1))
        if prefs.keySetCount > 1 { titles.append("(-") }
        if prefs.keySetCount >= 2 {
            for s in 2...prefs.keySetCount { titles.append(prefs.keySet(s).name) }
        }
        d.setMenu(0x21, titles: titles)
        d.setValue(0x21, prefs.currentKeySetIndex < 2 ? 1 : prefs.currentKeySetIndex + 1)
        // InputSprockets items 0x2c / 0x2d are not in the OS X DITL 192; `_CanUseISp()` is false, so the tail
        // activates New Set, Delete Set (again — even for set 1) and the popup.
        d.setActive(0x1f, true)
        d.setActive(0x20, true)
        d.setActive(0x21, true)
    }

    /// `_CodeToName @ 0001948c`: STR# 130 item code + 1, "??" when empty or code ≥ 0x80.
    private func codeToName(_ code: UInt16) -> String {
        if code < 0x80, Int(code) < keyNames.count, !keyNames[Int(code)].isEmpty { return keyNames[Int(code)] }
        return "??"
    }

    // MARK: - ModalDialog item hits (`_PrefsDialog`'s loop)

    private func hit(_ item: Int) {
        guard let d = dialog else { return }
        switch item {
        case 1:
            finish(prefs)
            return
        case 2:
            finish(saved)
            return
        case 3:
            prefs.applyAlexPrefsSoundInit()
            prefs.applyAlexPrefsKeysInit()
            prefs.applyAlexPrefsGameInit()
            resetCurrentArea(d)
            dialogs.livePrefs(prefs, true)                            // `_UpdateSoundVol`, `_UpdateMusicVolume`
        case 4:
            prefs = saved
            resetCurrentArea(d)
            dialogs.livePrefs(prefs, true)
        case 5, 6, 7:
            if area != item - 4 { changeArea(d, to: item - 4) }
        default:
            break
        }
        switch area {
        case 2: keysAreaHit(d, item)
        case 1: soundAreaHit(d, item)
        case 3: gameAreaHit(d, item)
        default: break
        }
    }

    private func soundAreaHit(_ d: CarbonDialog, _ item: Int) {
        switch item {
        case 0x1a:
            prefs.sfxVolume = d.value(0x1a)
            if prefs.sfxVolume != 1 { prefs.lastSfxVolume = prefs.sfxVolume }
            dialogs.livePrefs(prefs, false)                           // `_PlayMySnd` reads short 0x33 live
            dialogs.playSound(SoundCue(slot: 0x12, priority: 10, delayFrames: 0), nil)
        case 0x1b:
            prefs.musicVolume = d.value(0x1b)
            if prefs.musicVolume != 1 { prefs.lastMusicVolume = prefs.musicVolume }
            // short 0x33 is swapped to the music level for this one `_PlayMySnd(0xd)`, then restored.
            dialogs.playSound(SoundCue(slot: 0x0d, priority: 10, delayFrames: 0), prefs.musicVolume)
            dialogs.livePrefs(prefs, true)                            // `_UpdateMusicVolume`
        case 0x1c:
            prefs.titleMusic.toggle()
            d.setValue(0x1c, prefs.titleMusic ? 1 : 0)
            dialogs.livePrefs(prefs, true)
        default:
            break
        }
    }

    private func gameAreaHit(_ d: CarbonDialog, _ item: Int) {
        switch item {
        case 0x1a: prefs.fullScreen.toggle(); d.setValue(item, prefs.fullScreen ? 1 : 0)
        case 0x1b: prefs.showAirBubbles.toggle(); d.setValue(item, prefs.showAirBubbles ? 1 : 0)
        case 0x1c: prefs.showStars.toggle(); d.setValue(item, prefs.showStars ? 1 : 0)
        case 0x1d: prefs.holdEscapeToExit.toggle(); d.setValue(item, prefs.holdEscapeToExit ? 1 : 0)
        default: break
        }
    }

    private func keysAreaHit(_ d: CarbonDialog, _ item: Int) {
        switch item {
        case 0x1a...0x1e:
            keyTarget = item
            if prefs.currentKeySetIndex != 1 { d.selectText(item, from: 0, to: 0xff) }
        case 0x1f:
            if prefs.keySetCount < 0x14 {
                newSet(d)
            } else {
                dialogs.alert(202, fullScreen: fullScreen)
            }
        case 0x20:
            guard prefs.currentKeySetIndex > 1 else { return }
            var s = prefs.currentKeySetIndex
            while s < prefs.keySetCount {
                prefs.setKeySet(s, prefs.keySet(s + 1))
                s += 1
            }
            prefs.currentKeySetIndex -= 1
            prefs.keySetCount -= 1
            resetKeysValues(d)
        case 0x21:
            var v = d.value(0x21)
            if v > 1 { v -= 1 }
            prefs.currentKeySetIndex = v
            resetKeysValues(d)
        default:
            break
        }
    }

    /// `_PrefsDialog` case 0x1f: DLOG 200 in the prefs' window group, `_NewSetDlgFilter`; names longer than 10
    /// bytes get ALRT 201 and are cut to 10; Create appends a set with ← → ↑ ↓ Space and makes it current.
    private func newSet(_ prefsDialog: CarbonDialog) {
        guard let t = BTXDialogResources.dialog(200, data: dialogs.data) else { return }
        let n = CarbonDialog(template: t, data: dialogs.data, art: dialogs.art)
        n.outline(1)
        n.keyFilter = { [unowned n] key in
            if !key.command {
                if key.char == 0x0d || key.char == 0x03 { n.flash(1); return true }
                guard key.char == 0x1b else { return false }
            } else if key.commandUppercased != UInt8(ascii: ".") {
                return true
            }
            n.flash(2)
            return true
        }
        n.itemHit = { [weak self, unowned n] item in
            guard let self else { return }
            switch item {
            case 2:
                dialogs.dismiss(n)
            case 1:
                let name = n.text(3)
                guard BTXDialogResources.byteLength(name) < 11 else {
                    dialogs.alert(201, fullScreen: fullScreen) { [unowned n] in
                        n.setText(3, BTXDialogResources.truncated(name, bytes: 10))
                        n.selectText(3, from: 0, to: 0xff)
                    }
                    return
                }
                dialogs.dismiss(n)
                prefs.keySetCount += 1
                prefs.currentKeySetIndex = prefs.keySetCount
                prefs.setKeySet(prefs.keySetCount, KeySet(name: name, left: 0x7b, right: 0x7c, up: 0x7e, down: 0x7d,
                                                          push: 0x31))
                resetKeysValues(prefsDialog)
            default:
                break
            }
        }
        dialogs.open(n, grouped: true, fullScreen: fullScreen)
        n.selectText(3, from: 0, to: 0xff)
    }

    // MARK: - `_PrefsDlgFilter`

    private func filter(_ key: DialogKey) -> Bool {
        guard let d = dialog else { return true }
        if !key.command {
            if key.char == 0x0d || key.char == 0x03 { d.flash(1); return true }
            if key.char == 0x1b { d.flash(2); return true }
            if key.char == 0x09 { return false }
            if area == 2, prefs.currentKeySetIndex != 1 { setPrefsKey(key.keyCode) }
            return true
        }
        if key.commandUppercased == UInt8(ascii: ".") { d.flash(2) }
        return true
    }

    /// The filter's null event: `_CheckPrefsHelp`, then (Keys area, set ≠ 1) one modifier key per event, each on
    /// its press only — Control (0x3b), Shift (0x38), Option (0x3a), Command (0x37), in that order. `_GameKeyDown`
    /// reads those KeyMap bits: the LEFT-side keys only (the right-side ones are 0x3e / 0x3c / 0x3d / 0x36).
    private func nullEvent() {
        checkHelp()
        guard area == 2, prefs.currentKeySetIndex != 1 else { return }
        func down(_ code: CGKeyCode) -> Bool { CGEventSource.keyState(.combinedSessionState, key: code) }
        let control = down(0x3b), shift = down(0x38), option = down(0x3a), command = down(0x37)
        if control && !Self.controlLatch {
            setPrefsKey(0x3b); Self.controlLatch = true
            return
        }
        if !control { Self.controlLatch = false }
        if shift && !Self.shiftLatch {
            setPrefsKey(0x38); Self.shiftLatch = true
            return
        }
        if !shift { Self.shiftLatch = false }
        if option && !Self.optionLatch {
            setPrefsKey(0x3a); Self.optionLatch = true
            return
        }
        if !option { Self.optionLatch = false }
        if command && !Self.commandLatch {
            setPrefsKey(0x37); Self.commandLatch = true
        } else if !command {
            Self.commandLatch = false
        }
    }

    /// `_CheckPrefsHelp` + `_MouseInWhichPrefsItem @ 0000d0a1`.
    private func checkHelp() {
        guard let d = dialog else { return }
        let item: Int
        if Self.helpFirstTime {
            Self.helpFirstTime = false
            item = 0x18
        } else {
            guard let i = d.item(at: d.mouseLocation) else { return }
            item = i
        }
        let list = item < 0x1a ? 0x87 : area + 0x83
        let index = item < 0x1a ? item : item - 0x19
        guard (list, index) != lastHelp else { return }
        lastHelp = (list, index)
        let strings = (try? dialogs.data.strings(list)) ?? []
        d.setText(0x17, index >= 1 && index <= strings.count ? strings[index - 1] : "")
    }

    /// `_SetPrefsKey @ 0000de4c`.
    private func setPrefsKey(_ code: UInt16) {
        guard let d = dialog else { return }
        if (code == keys.left && keyTarget != 0x1a) || (code == keys.right && keyTarget != 0x1b)
            || (code == keys.up && keyTarget != 0x1c) || (code == keys.down && keyTarget != 0x1d)
            || (code == keys.push && keyTarget != 0x1e) {
            NSSound.beep()
            return
        }
        if (0x1a...0x1e).contains(keyTarget) {
            d.setText(keyTarget, codeToName(code))
            switch keyTarget {
            case 0x1a: keys.left = code; keyTarget = 0x1b
            case 0x1b: keys.right = code; keyTarget = 0x1c
            case 0x1c: keys.up = code; keyTarget = 0x1d
            case 0x1d: keys.down = code; keyTarget = 0x1e
            default: keys.push = code; keyTarget = 0x1a
            }
            d.selectText(keyTarget, from: 0, to: 0xff)
            prefs.setKeySet(prefs.currentKeySetIndex, keys)                 // `_SaveKeys`
        }
        // Two eggs, once each per run: A L E X . → snd 13; D W A R E → snd 9.
        if keys.codes == [0x00, 0x25, 0x0e, 0x07, 0x2f], !Self.playedEggOne {
            Self.playedEggOne = true
            dialogs.playSound(SoundCue(slot: 0x0d, priority: 10, delayFrames: 0), nil)
        } else if keys.codes == [0x02, 0x0d, 0x00, 0x0f, 0x0e], !Self.playedEggTwo {
            Self.playedEggTwo = true
            dialogs.playSound(SoundCue(slot: 0x09, priority: 10, delayFrames: 0), nil)
        }
    }
}

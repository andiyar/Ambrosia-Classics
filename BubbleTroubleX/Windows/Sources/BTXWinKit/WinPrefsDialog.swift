import BubbleTroubleCore
import BubbleTroubleRender
import Foundation

/// The Preferences dialog (DLOG 190) in the game window — the Windows port of the Mac app's `BTXPrefsWindow`
/// (`BubbleTroubleX/App/BTXPrefsWindow.swift`, transcribed there from `_PrefsDialog @ 0000ea93` and `_PrefsDlgFilter
/// @ 0000e209`; its header lists every item ↔ pref). Same items, same hits, same filter; what AppKit / Quartz did on
/// the Mac comes from `DialogSystem` here: the beep and sounds through its delegate, the held modifier keys from
/// `DialogSystem.heldKeys` (`CGEventSource.keyState` on the Mac), the mouse for the help line from the last mouse
/// event, the area icons as plotted overlays.
public final class WinPrefsDialog {
    /// `_firstTime_73946`, `_played_74034`, `_playedTwo_74035`, `_keyDown1…4_7397x`: statics for the app's life
    /// (held by `DialogSystem`).
    struct Statics {
        var helpFirstTime = true
        var playedEggOne = false, playedEggTwo = false
        var shiftLatch = false, optionLatch = false, commandLatch = false, controlLatch = false
    }

    private unowned let system: DialogSystem
    /// `gPrefsData`, edited live.
    public private(set) var prefs: BTXPrefs
    /// `gSavedPrefsData`: Revert / Cancel.
    private let saved: BTXPrefs
    private var completion: ((BTXPrefs) -> Void)?
    public private(set) var dialog: DialogWindow?
    /// The DLOG 200 "new key set" dialog while it is up.
    public private(set) var newSetDialog: DialogWindow?
    /// `gWhichPrefs`: 1 Sound, 2 Keys, 3 Misc.
    public private(set) var area = 1
    /// `gKeyTarget`: the key field the next key goes to (0x1a…0x1e).
    public private(set) var keyTarget = 0x1a
    /// `gLastHelpInfo`: (STR# id, index) on the help line.
    private var lastHelp = (list: 0, index: 0)
    /// `gLeftCode` … `gPushCode` + `gKeySetName` as `_InitControls` loads them.
    private var keys: KeySet
    private var areaIcons: [(rect: DialogRect, image: RGBAImage)] = []
    private let keyNames: [String]

    init(system: DialogSystem, prefs: BTXPrefs, completion: @escaping (BTXPrefs) -> Void) {
        self.system = system
        self.prefs = prefs
        saved = prefs
        self.completion = completion
        keys = prefs.currentKeySet
        keyNames = (try? system.data.strings(130)) ?? []
    }

    // MARK: - Open / close

    func open() {
        guard let t = DialogResources.dialog(190, data: system.data) else { finish(saved); return }
        let d = DialogWindow(template: t, data: system.data, art: system.art)
        dialog = d
        d.defaultItem = 1
        d.cancelItem = 2
        area = 1
        lastHelp = (0, 0)
        touchUp(d)
        for (i, n) in (8...10).enumerated() {
            guard let r = d.item(n)?.rect, let image = try? system.art.cicn(1000 + i) else { continue }
            areaIcons.append((r, image))
        }
        hiliteCurrentArea()
        system.playSound(SoundCue(slot: 0x16, priority: 10, delayFrames: 0))
        addItems(d)
        resetSoundValues(d)
        d.keyFilter = { [weak self] key in self?.filter(key) ?? true }
        d.nullEvent = { [weak self] in self?.nullEvent() }
        d.itemHit = { [weak self] item in self?.hit(item) }
        system.open(d)
    }

    private func finish(_ result: BTXPrefs) {
        if let d = dialog {
            d.keyFilter = nil
            d.nullEvent = nil
            d.itemHit = nil
            system.dismiss(d)
        }
        dialog = nil
        let done = completion
        completion = nil
        done?(result)
    }

    // MARK: - Drawing helpers

    /// `_TouchUpPrefsDialog`: `FrameRect` of items 14…22 in RGB (0x7fff, 0x7fff, 0x7fff), pen 1×1.
    private func touchUp(_ d: DialogWindow) {
        for n in 14...22 { if let r = d.item(n)?.rect { d.frame(r, rgb: 0x7F7F7F) } }
    }

    /// `_HiliteCurrentPrefsArea`: the current area's `cicn` plotted `kTransformSelected`.
    private func hiliteCurrentArea() {
        dialog?.overlays = areaIcons.enumerated().map { (i, icon) in (icon.rect, icon.image, i + 1 == area) }
    }

    // MARK: - Areas

    /// `_AddItems(dialog, 190 + area)` — `AppendDITL` numbering from 26.
    private func addItems(_ d: DialogWindow) {
        if let items = DialogResources.items(ditl: 190 + area, data: system.data, firstNumber: d.items.count + 1) {
            d.append(items)
        }
    }

    /// `_ChangeArea`.
    private func changeArea(_ d: DialogWindow, to newArea: Int) {
        system.playSound(SoundCue(slot: 0x11, priority: 10, delayFrames: 0))
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

    private func resetCurrentArea(_ d: DialogWindow) {
        switch area {
        case 2: resetKeysValues(d)
        case 3: resetGameValues(d)
        case 1: resetSoundValues(d)
        default: break
        }
    }

    /// `_ResetPrefsSoundValues @ 0000d978`.
    private func resetSoundValues(_ d: DialogWindow) {
        d.setValue(0x1a, prefs.sfxVolume)
        d.setValue(0x1b, prefs.musicVolume)
        d.setValue(0x1c, prefs.titleMusic ? 1 : 0)
    }

    /// `_ResetPrefsGameValues @ 0000d8dc`.
    private func resetGameValues(_ d: DialogWindow) {
        d.setValue(0x1a, prefs.fullScreen ? 1 : 0)
        d.setValue(0x1b, prefs.showAirBubbles ? 1 : 0)
        d.setValue(0x1c, prefs.showStars ? 1 : 0)
        d.setValue(0x1d, prefs.holdEscapeToExit ? 1 : 0)
    }

    /// `_ResetPrefsKeysValues @ 0000e491`.
    private func resetKeysValues(_ d: DialogWindow) {
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
        var titles = Array(DialogResources.menuItems(1009, data: system.data).prefix(1))
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
            system.delegate?.dialogLivePrefs(prefs, updateMusic: true)  // `_UpdateSoundVol`, `_UpdateMusicVolume`
        case 4:
            prefs = saved
            resetCurrentArea(d)
            system.delegate?.dialogLivePrefs(prefs, updateMusic: true)
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

    private func soundAreaHit(_ d: DialogWindow, _ item: Int) {
        switch item {
        case 0x1a:
            prefs.sfxVolume = d.value(0x1a)
            if prefs.sfxVolume != 1 { prefs.lastSfxVolume = prefs.sfxVolume }
            system.delegate?.dialogLivePrefs(prefs, updateMusic: false)   // `_PlayMySnd` reads short 0x33 live
            system.playSound(SoundCue(slot: 0x12, priority: 10, delayFrames: 0))
        case 0x1b:
            prefs.musicVolume = d.value(0x1b)
            if prefs.musicVolume != 1 { prefs.lastMusicVolume = prefs.musicVolume }
            // short 0x33 is swapped to the music level for this one `_PlayMySnd(0xd)`, then restored.
            system.playSound(SoundCue(slot: 0x0d, priority: 10, delayFrames: 0), prefs.musicVolume)
            system.delegate?.dialogLivePrefs(prefs, updateMusic: true)    // `_UpdateMusicVolume`
        case 0x1c:
            prefs.titleMusic.toggle()
            d.setValue(0x1c, prefs.titleMusic ? 1 : 0)
            system.delegate?.dialogLivePrefs(prefs, updateMusic: true)
        default:
            break
        }
    }

    private func gameAreaHit(_ d: DialogWindow, _ item: Int) {
        switch item {
        case 0x1a: prefs.fullScreen.toggle(); d.setValue(item, prefs.fullScreen ? 1 : 0)
        case 0x1b: prefs.showAirBubbles.toggle(); d.setValue(item, prefs.showAirBubbles ? 1 : 0)
        case 0x1c: prefs.showStars.toggle(); d.setValue(item, prefs.showStars ? 1 : 0)
        case 0x1d: prefs.holdEscapeToExit.toggle(); d.setValue(item, prefs.holdEscapeToExit ? 1 : 0)
        default: break
        }
    }

    private func keysAreaHit(_ d: DialogWindow, _ item: Int) {
        switch item {
        case 0x1a...0x1e:
            keyTarget = item
            if prefs.currentKeySetIndex != 1 { d.selectText(item, from: 0, to: 0xff) }
        case 0x1f:
            if prefs.keySetCount < 0x14 {
                newSet(d)
            } else {
                system.alert(202)
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

    /// `_PrefsDialog` case 0x1f: DLOG 200 over the prefs, `_NewSetDlgFilter`; names longer than 10 bytes get
    /// ALRT 201 and are cut to 10; Create appends a set with ← → ↑ ↓ Space and makes it current.
    private func newSet(_ prefsDialog: DialogWindow) {
        guard let n = system.makeDialog(200) else { return }
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
                newSetDialog = nil
                system.dismiss(n)
            case 1:
                let name = n.text(3)
                guard DialogResources.byteLength(name) < 11 else {
                    system.alert(201) { [unowned n] in
                        n.setText(3, DialogResources.truncated(name, bytes: 10))
                        n.selectText(3, from: 0, to: 0xff)
                    }
                    return
                }
                newSetDialog = nil
                system.dismiss(n)
                prefs.keySetCount += 1
                prefs.currentKeySetIndex = prefs.keySetCount
                prefs.setKeySet(prefs.keySetCount, KeySet(name: name, left: 0x7b, right: 0x7c, up: 0x7e, down: 0x7d,
                                                          push: 0x31))
                resetKeysValues(prefsDialog)
            default:
                break
            }
        }
        newSetDialog = n
        system.open(n)
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
        let held = system.heldKeys
        let control = held.contains(0x3b), shift = held.contains(0x38)
        let option = held.contains(0x3a), command = held.contains(0x37)
        if control && !system.prefsStatics.controlLatch {
            setPrefsKey(0x3b); system.prefsStatics.controlLatch = true
            return
        }
        if !control { system.prefsStatics.controlLatch = false }
        if shift && !system.prefsStatics.shiftLatch {
            setPrefsKey(0x38); system.prefsStatics.shiftLatch = true
            return
        }
        if !shift { system.prefsStatics.shiftLatch = false }
        if option && !system.prefsStatics.optionLatch {
            setPrefsKey(0x3a); system.prefsStatics.optionLatch = true
            return
        }
        if !option { system.prefsStatics.optionLatch = false }
        if command && !system.prefsStatics.commandLatch {
            setPrefsKey(0x37); system.prefsStatics.commandLatch = true
        } else if !command {
            system.prefsStatics.commandLatch = false
        }
    }

    /// `_CheckPrefsHelp` + `_MouseInWhichPrefsItem @ 0000d0a1`.
    private func checkHelp() {
        guard let d = dialog else { return }
        let item: Int
        if system.prefsStatics.helpFirstTime {
            system.prefsStatics.helpFirstTime = false
            item = 0x18
        } else {
            guard let m = d.mouseLocation, let i = d.item(at: m.x, m.y) else { return }
            item = i
        }
        let list = item < 0x1a ? 0x87 : area + 0x83
        let index = item < 0x1a ? item : item - 0x19
        guard (list, index) != lastHelp else { return }
        lastHelp = (list, index)
        let strings = (try? system.data.strings(list)) ?? []
        d.setText(0x17, index >= 1 && index <= strings.count ? strings[index - 1] : "")
    }

    /// `_SetPrefsKey @ 0000de4c`.
    private func setPrefsKey(_ code: UInt16) {
        guard let d = dialog else { return }
        if (code == keys.left && keyTarget != 0x1a) || (code == keys.right && keyTarget != 0x1b)
            || (code == keys.up && keyTarget != 0x1c) || (code == keys.down && keyTarget != 0x1d)
            || (code == keys.push && keyTarget != 0x1e) {
            system.beep()
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
        if keys.codes == [0x00, 0x25, 0x0e, 0x07, 0x2f], !system.prefsStatics.playedEggOne {
            system.prefsStatics.playedEggOne = true
            system.playSound(SoundCue(slot: 0x0d, priority: 10, delayFrames: 0))
        } else if keys.codes == [0x02, 0x0d, 0x00, 0x0f, 0x0e], !system.prefsStatics.playedEggTwo {
            system.prefsStatics.playedEggTwo = true
            system.playSound(SoundCue(slot: 0x09, priority: 10, delayFrames: 0))
        }
    }
}

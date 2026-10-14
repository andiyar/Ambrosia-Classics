import Foundation

/// The Options dialog's logic (plan O1; save-continue §8.2, engine §8): `.PreferencesDialog @ 100760dc`,
/// `.SwitchPrefsPanel`, `.UpdatePrefsPanel`, `.UpdateDisabledItems`, `.PrefDialogFilter @ 10075990`,
/// `.AlreadyUsingKey @ 100758f8` and `.ConvertKeyName @ 10077250` (M l. 63963–64838). The App draws DLOG 6900 from
/// `controlValues` / `itemTexts` / `focus` / `disabledItems` / `hiddenItems` (A1b) and feeds ModalDialog's events in.
/// Item numbers are **dialog** numbers: DITL 6900's six items, then the panel's DITL appended from 7.
///
/// `.Options @ 1000e470` (M l. 7254–7289) around it: `FlushEvents`, `InputActivate(0,0)`, cursor shown, the prefs
/// file opened and **re-read** (`.InitPrefs`) — that record is `init(record:)`; after the dialog closes the record
/// (`record`, OK or Cancel) is written back on **every** close, `MTRedraw`, `PrefsToggles.makeCurrPrefs(record,…)`
/// (with `live` taken back), `.UpdateMenus`, the file closed, `*fe0c = 1`, `511e = 1`.
public struct PrefsDialogModel {
    /// The panel popup (item 3, CNTL 600 → MENU 600); `_DAT_100a694c`, DITL `6900 + n`.
    public enum Panel: Int, Sendable {
        case gameOptions = 1, controls = 2, soundAndMusic = 3
    }

    /// The item that ended the dialog (1 OK, 2 Cancel).
    public enum Close: Sendable, Equatable { case ok, cancel }

    /// What `.PrefDialogFilter` did with an event. `.passed` = the filter returned false (ModalDialog's own handling).
    public enum KeyOutcome: Sendable, Equatable {
        case passed
        case swallowed
        case ok
        case cancel
        case captured(item: Int)
        case refused(String)
    }

    /// pstr `0x100a694e`, shown by `ReportDialog`.
    public static let keyInUseMessage = "That key is already being used for another action. Please try another one."
    /// `*PTR_DAT_100a0458`: InputSprocket present — never in the replica (design §3.3).
    public static let inputSprocketPresent = false

    /// The working copy `PTR_DAT_100a0b6c` (the record copied in at open; OK copies it back).
    public var working: FerazelPrefs
    /// The `'Pref'` handle's record (`*_DAT_1009fdf4`). Changed only by OK and by Game Options' Default Settings.
    public private(set) var record: FerazelPrefs
    /// The live side; the Music checkbox and the volume popups act on it at once. The caller takes it back at close.
    public private(set) var live: PrefsToggles
    /// `*_DAT_100a0050` (paused) for the dialog's whole life.
    public let paused: Bool
    /// The panel up (`_DAT_100a694c`; −1 at every opening, so the first switch always builds panel 1).
    public var panel: Panel { shownPanel ?? .gameOptions }
    private var shownPanel: Panel?
    /// Each control's value as last set (`SetControlValue` / tracking); items ≥ 7 are the current panel's.
    public private(set) var controlValues: [Int: Int] = [3: 1]
    /// The Controls panel's edit-text items 7…15 (`.ConvertKeyName`).
    public private(set) var itemTexts: [Int: String] = [:]
    /// The text item with the selection (`dialog+0xa4` + 1); nil off the Controls panel.
    public private(set) var focus: Int?
    public private(set) var disabledItems: Set<Int> = []
    public private(set) var hiddenItems: Set<Int> = []
    /// `*PTR_DAT_100a0b64`: the modifier key last captured (a held modifier is taken once). A global: the caller may
    /// carry it across openings.
    public private(set) var lastModifier: Int16
    public private(set) var result: Close?

    private let processorType: Int
    private let systemVolume: UInt16
    private let keyCharacter: @Sendable (Int16) -> String?

    /// Opens the dialog over the re-read `record`. `systemVolume` is `STGetVolume` (only read for +0x38 when +0x36 is
    /// 0; `STSetVolume` is never applied, D35 Known deviation 8); `processorType` is `Gestalt('cput')` for Game
    /// Options' Default Settings; `keyCharacter` is the keyboard layout's character for a key code (`KeyTranslate`).
    public init(record: FerazelPrefs, live: PrefsToggles, paused: Bool, systemVolume: UInt16 = 0,
                processorType: Int = FerazelPrefs.modernProcessorType, lastModifier: Int16 = 0,
                keyCharacter: @escaping @Sendable (Int16) -> String?) {
        self.record = record
        self.live = live
        self.paused = paused
        self.processorType = processorType
        self.systemVolume = systemVolume
        self.lastModifier = lastModifier
        self.keyCharacter = keyCharacter
        working = record
        if working.useSystemVolume == 0 { working.systemVolumeBy28 = Self.systemVolumeSetting(systemVolume) }
        switchPanel(.gameOptions)
    }

    /// min(9, `STGetVolume`/28) (M l. 64288–64315 and the Sound & Music defaults).
    static func systemVolumeSetting(_ v: UInt16) -> Int16 { Int16(min(9, Int(v) / 0x1c)) }

    // MARK: - ModalDialog's item hits

    /// ModalDialog returned `item`; `value` is the control's value after tracking (popups, item 3). Disabled items
    /// never come back from ModalDialog and are ignored. Returns the music cues the hit made at once.
    @discardableResult
    public mutating func hit(_ item: Int, value: Int? = nil) -> [MusicCue] {
        guard result == nil, !disabledItems.contains(item), !hiddenItems.contains(item) else { return [] }
        if let value { controlValues[item] = value }
        let shown = controlValues[3] ?? panel.rawValue        // sVar11: item 3's value, read after the hit
        var cues: [MusicCue] = []
        switch item {
        case 1: close(.ok)
        case 2: close(.cancel)
        case 3: if let p = Panel(rawValue: controlValues[3] ?? 0) { switchPanel(p) }
        case 4: defaultSettings(shown)
        case 7...:
            switch shown {
            case 1: gameOptionsHit(item)
            case 2: controlsHit(item)
            case 3: cues = soundHit(item)
            default: break
            }
        default: break
        }
        return cues
    }

    /// Item 1 or 2: OK copies the working copy into the record; Cancel restores only the system volume
    /// (`STSetVolume(local_6c)`, a no-op here). `694c = −1` (the next opening rebuilds panel 1).
    private mutating func close(_ r: Close) {
        if r == .ok { record = working }
        result = r
    }

    /// `.SwitchPrefsPanel` (M l. 64577–64601): `ShortenDITL` to the six base items, `AppendDITL(6900 + n)`, then
    /// `.UpdatePrefsPanel(n)`. A no-op when `n` is already up.
    private mutating func switchPanel(_ p: Panel) {
        if p == shownPanel { return }
        shownPanel = p
        controlValues = controlValues.filter { $0.key < 7 }
        itemTexts = [:]
        focus = nil
        disabledItems = []
        hiddenItems = []
        updatePanel(p)
    }

    /// `.UpdatePrefsPanel(n) @ 10076e30` (M l. 64603–64671).
    private mutating func updatePanel(_ p: Panel) {
        switch p {
        case .gameOptions:
            controlValues[7] = Int(working.reduceFrameRate)
            controlValues[8] = Int(working.reuseSavedGames)
            controlValues[9] = Int(working.backgroundTasks)
            controlValues[14] = Int(working.resolutionSwitch)
            controlValues[10] = Int(working.graphics)
            controlValues[11] = Int(working.effects)
        case .controls:
            for item in [13, 14, 15, 12, 11, 10, 9, 8, 7] { convertKeyName(working.keys[item - 7], item: item) }
            focus = 7
            controlValues[26] = Int(working.useInputSprocket)
        case .soundAndMusic:
            if live.music.quickTimePresent { hiddenItems.insert(13) }   // else +0x0c = 0 and item 8 disabled
            controlValues[7] = Int(working.soundOn)
            controlValues[8] = Int(working.musicOn)
            controlValues[9] = 10 - Int(working.soundVolume)
            controlValues[10] = 10 - Int(working.musicVolume)
            controlValues[15] = 10 - Int(working.systemVolumeBy28)
            controlValues[16] = Int(working.useSystemVolume)
        }
        updateDisabledItems()
    }

    /// `.UpdateDisabledItems @ 10075f68`: Controls only — no InputSprocket → +0x0a = 0 and item 26 disabled;
    /// item 27 "Configure…" disabled while +0x0a is 0.
    private mutating func updateDisabledItems() {
        guard panel == .controls else { return }
        if !Self.inputSprocketPresent {
            working.useInputSprocket = 0
            disabledItems.insert(26)
        }
        if working.useInputSprocket == 0 { disabledItems.insert(27) } else { disabledItems.remove(27) }
    }

    /// Item 4 "Default Settings" (M l. 64356–64422). Game Options writes the defaults into the **record**, not the
    /// working copy (raw `10076528`, M l. 64375–64389), so nothing visibly changes; OK then overwrites them, Cancel keeps
    /// them. Controls and Sound & Music reset the working copy.
    private mutating func defaultSettings(_ shown: Int) {
        switch shown {
        case 1:
            record.plainCopy = 0
            record.reduceFrameRate = 0
            record.reuseSavedGames = 0
            record.graphics = 1
            record.effects = processorType < 0x108 ? 2 : 1
            record.parallax = 2
            record.resolutionSwitch = 0
            record.unread3c = 0
            record.unread3e = 0
            record.unread40 = 0
            updatePanel(.gameOptions)
        case 2:
            working.keys = FerazelPrefs.defaultKeys
            working.key2a = 0x30
            working.key30 = 0x4c
            working.useInputSprocket = 0
            updatePanel(.controls)
        case 3:
            working.soundOn = 1
            working.musicOn = 1
            working.soundVolume = 7
            working.musicVolume = 9
            working.useSystemVolume = 0
            working.systemVolumeBy28 = Self.systemVolumeSetting(systemVolume)
            updatePanel(.soundAndMusic)
        default: break
        }
    }

    /// Game Options items (M l. 64440–64487). Item 14 updates control **16**, which does not exist on this panel
    /// (raw `100767fc`): the box keeps its old value until the panel is rebuilt. The item-12 → +0x04 branch is dead
    /// (item 12 is the disabled "Graphics:" text) and is not built.
    private mutating func gameOptionsHit(_ item: Int) {
        switch item {
        case 7:
            working.reduceFrameRate = working.reduceFrameRate == 0 ? 1 : 0
            controlValues[7] = Int(working.reduceFrameRate)
        case 8:
            working.reuseSavedGames = working.reuseSavedGames == 0 ? 1 : 0
            controlValues[8] = Int(working.reuseSavedGames)
        case 9:
            working.backgroundTasks = working.backgroundTasks == 0 ? 1 : 0
            controlValues[9] = Int(working.backgroundTasks)
        case 14:
            working.resolutionSwitch = working.resolutionSwitch == 0 ? 1 : 0
            setControlValue(16, Int(working.resolutionSwitch))
        case 10:
            working.graphics = Int16(truncatingIfNeeded: controlValues[10] ?? 0)
        case 11:
            working.effects = Int16(truncatingIfNeeded: controlValues[11] ?? 0)
        default: return
        }
        updateDisabledItems()
    }

    /// Controls items: 26 toggles +0x0a and updates control **30** (no such item, raw `10076944`) — unreachable
    /// here, item 26 is disabled; 27 "Configure…" (`ISpConfigure`) is disabled too.
    private mutating func controlsHit(_ item: Int) {
        if item == 26 {
            working.useInputSprocket = working.useInputSprocket == 0 ? 1 : 0
            setControlValue(30, Int(working.useInputSprocket))
            updateDisabledItems()
        }
    }

    /// Sound & Music items (M l. 64488–64560; the Music checkbox 64494–64524): popups map control value v ↔ pref 10 − v (MENU 601 "9"…"1").
    private mutating func soundHit(_ item: Int) -> [MusicCue] {
        var cues: [MusicCue] = []
        switch item {
        case 7:
            working.soundOn = working.soundOn == 0 ? 1 : 0
            controlValues[7] = Int(working.soundOn)
        case 8:
            // The live +0x0c is written directly. Off: volume 0 (not paused), shutdown. On: the live +0x10 and
            // `SetMusicAIFFVolume(V)` only — a no-op after the shutdown (`1992` clear, M l. 41959–41971): the dialog never
            // restarts the music. (QuickTime absent: +0x0c back to 0 and a report — unreachable here.)
            working.musicOn = working.musicOn == 0 ? 1 : 0
            live.live.musicOn = working.musicOn
            if working.musicOn == 0 {
                if !paused { cues += live.setMusicVolume(0) }
                cues += live.music.shutDown()
            } else {
                live.live.musicVolume = working.musicVolume
                if !paused { cues += live.setMusicVolume(MusicFade.fullVolume(working)) }
            }
            controlValues[8] = Int(working.musicOn)
        case 9:
            working.soundVolume = Int16(truncatingIfNeeded: 10 - (controlValues[9] ?? 0))
            if working.soundOn != 0 {
                live.live.soundOn = 1
                live.soundScale = Int(working.soundVolume) * 0x1c
            }
        case 10:
            working.musicVolume = Int16(truncatingIfNeeded: 10 - (controlValues[10] ?? 0))
            if !paused {
                cues += live.setMusicVolume(working.musicOn == 0 ? 0 : MusicFade.fullVolume(working))
            }
        case 15:
            // `STSetVolume(+0x38·28)`: stored, never applied (D35 Known deviation 8).
            working.systemVolumeBy28 = Int16(truncatingIfNeeded: 10 - (controlValues[15] ?? 0))
        case 16:
            working.useSystemVolume = working.useSystemVolume == 0 ? 1 : 0
            controlValues[16] = Int(working.useSystemVolume)
        default: break
        }
        return cues
    }

    /// `SetControlValue` on a `GetDialogItem` result: items the panel does not have are dropped.
    private mutating func setControlValue(_ item: Int, _ v: Int) {
        if Self.panelItems[panel]?.contains(item) == true { controlValues[item] = v }
    }

    /// The dialog item numbers each panel has (DITL 6901: 7…14, 6902: 7…27, 6903: 7…16).
    private static let panelItems: [Panel: ClosedRange<Int>] = [.gameOptions: 7...14, .controls: 7...27,
                                                                 .soundAndMusic: 7...16]

    // MARK: - `.PrefDialogFilter`

    /// A click in an edit-text item selects it (`SelectDialogItemText(item, 0, 0x7fff)`).
    public mutating func focus(item: Int) {
        guard panel == .controls, (7...15).contains(item) else { return }
        focus = item
    }

    /// A keyDown (or autoKey, `isRepeat`) event. Off the Controls panel, ⌘. / Esc → Cancel and Return / Enter → OK.
    /// With an edit item focused, the key code (`message >> 8 & 0xff`) is taken unless `.AlreadyUsingKey`; the event
    /// is consumed either way and focus moves on (15 → 7) only when taken.
    public mutating func keyDown(char: UInt8, keyCode: Int, modifiers: UInt16 = 0, isRepeat: Bool = false)
        -> KeyOutcome {
        guard result == nil else { return .swallowed }
        if isRepeat { return .swallowed }                           // what 5: handled, nothing done
        if panel != .controls {
            if (modifiers & 0x100 != 0 && char == 0x2e) || char == 0x1b { close(.cancel); return .cancel }
            if char == 0x0d || char == 0x03 { close(.ok); return .ok }
        }
        guard let item = focus else { return .passed }
        let code = Int16(keyCode & 0xff)
        if Self.alreadyUsingKey(code, slot: item - 7, in: working) {
            return .refused(Self.keyInUseMessage)
        }
        take(code, item: item)
        return .captured(item: item)
    }

    /// Any other event (null events included) with its modifier bits: with an edit item focused, the first of ⌘
    /// (0x100 → 0x37), Shift (0x200 → 0x38), Option (0x800 → 0x3a), Control (0x1000 → 0x3b) held is taken once
    /// (`lastModifier`), unless already in use — then ignored silently. No modifier bits (0xff00) → `lastModifier = 0`.
    public mutating func idle(modifiers: UInt16) -> KeyOutcome {
        guard result == nil else { return .passed }
        if modifiers & 0xff00 == 0 { lastModifier = 0; return .passed }
        guard let item = focus else { return .passed }
        let code: Int16
        if modifiers & 0x100 != 0 { code = 0x37 }
        else if modifiers & 0x200 != 0 { code = 0x38 }
        else if modifiers & 0x800 != 0 { code = 0x3a }
        else if modifiers & 0x1000 != 0 { code = 0x3b }
        else { lastModifier = 0; return .passed }
        guard lastModifier != code, !Self.alreadyUsingKey(code, slot: item - 7, in: working) else { return .passed }
        take(code, item: item)
        lastModifier = code
        return .captured(item: item)
    }

    private mutating func take(_ code: Int16, item: Int) {
        working.keys[item - 7] = code
        convertKeyName(code, item: item)
        focus = item < 15 ? item + 1 : 7
    }

    private mutating func convertKeyName(_ code: Int16, item: Int) {
        itemTexts[item] = Self.keyName(code, keyCharacter: keyCharacter)
    }

    /// `.AlreadyUsingKey(code, slot) @ 100758f8`: scans the **ten** shorts +0x12…+0x24 (+0x24, slot 9, is never
    /// written by `.InitPrefs` and 0 in the replica — so key code 0x00 'A' reads as used, D35 ruling 15). Every
    /// match on another slot sets the verdict to 1, except Up (2) with Jump (5) either way, which sets 0: the result is
    /// the **last** matching slot's verdict.
    public static func alreadyUsingKey(_ code: Int16, slot: Int, in prefs: FerazelPrefs) -> Bool {
        let rec = [UInt8](prefs.record())
        var used = false
        for i in 0..<10 {
            let o = 0x12 + 2 * i
            let v = Int16(bitPattern: UInt16(rec[o]) << 8 | UInt16(rec[o + 1]))
            guard v == code, i != slot else { continue }
            used = !((slot == 2 && i == 5) || (slot == 5 && i == 2))
        }
        return used
    }

    /// `.ConvertKeyName @ 10077250`'s fixed table (pstrs in the data section, M l. 64686–64836).
    public static let keyNames: [Int16: String] = [
        0x24: "Return", 0x30: "Tab", 0x31: "Space Bar", 0x32: "`", 0x33: "Delete", 0x35: "Esc",
        0x37: "Command", 0x38: "Shift", 0x3a: "Option", 0x3b: "Control", 0x47: "Clear", 0x4c: "Enter",
        0x53: "Keypad 1", 0x54: "Keypad 2", 0x55: "Keypad 3", 0x56: "Keypad 4", 0x57: "Keypad 5", 0x58: "Keypad 6",
        0x59: "Keypad 7", 0x5b: "Keypad 8", 0x5c: "Keypad 9",
        0x60: "F5", 0x61: "F6", 0x62: "F7", 0x63: "F3", 0x64: "F8", 0x65: "F9", 0x67: "F11", 0x69: "F13",
        0x6b: "F14", 0x6d: "F10", 0x6f: "F12", 0x71: "F15",
        0x72: "Help", 0x73: "Home", 0x74: "Page Up", 0x75: "Del", 0x76: "F4", 0x77: "End", 0x78: "F2",
        0x79: "Page Down", 0x7a: "F1", 0x7b: "Left Arrow", 0x7c: "Right Arrow", 0x7d: "Down Arrow", 0x7e: "Up Arrow",
    ]

    /// The edit item's text for a key code: the table, else the layout's character (`KeyTranslate` + `TEKey` over the
    /// selected text) uppercased (`UpperString`); no character → empty.
    public static func keyName(_ code: Int16, keyCharacter: (Int16) -> String?) -> String {
        if let name = keyNames[code] { return name }
        return keyCharacter(code)?.uppercased() ?? ""
    }
}

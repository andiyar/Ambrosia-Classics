import Foundation

/// The `'Pref'` 0 record (0x942 bytes, file `Ferazel's Wand Prefs`) with `.InitPrefs @ 1000f180`'s defaults (engine §8,
/// save-continue §8.2; decompile l. 7694–7770). Offsets are the record's.
public struct FerazelPrefs: Equatable, Sendable {
    /// Number of input actions (`.IsInputKeyPressed` 0..8, engine §7.1).
    public static let actionCount = 9
    /// `Gestalt('cput')` of a modern Mac: every PowerPC G3 or later answers ≥ 0x108, so Effects defaults to 1
    /// (save-continue §8.2).
    public static let modernProcessorType = 0x108
    /// The engine §7.1 defaults: keypad 4, keypad 6, keypad 8, keypad 5, Shift, Option, Command, keypad 7, keypad 9.
    public static let defaultKeys: [Int16] = [0x56, 0x58, 0x5b, 0x57, 0x38, 0x3a, 0x37, 0x59, 0x5c]

    /// +0x00 "Reduce frame rate" (`.GameLoop`).
    public var reduceFrameRate: UInt8
    /// +0x01 "Reuse saved game files" (`SaveSG(prefs[1] == 0)`).
    public var reuseSavedGames: UInt8
    /// +0x02 Graphics: 1 High Detail, 2 Low Detail, 3 Line-skipped.
    public var graphics: Int16
    /// +0x04 Parallax: 1 Super, 2 Parallax, 3 No — no control in the shipped dialog, so always 2.
    public var parallax: Int16
    /// +0x06 Effects: 1 Enhanced, 2 Normal, 3 Reduced (3 skips `.DrawLightsOntoTiles`).
    public var effects: Int16
    /// +0x08 "Allow background tasks".
    public var backgroundTasks: UInt8
    /// +0x09: passed as "!flag" to `.WrapCopyToScreen` (≠ 0 → plain `CopyBits`, no backdrop) [LOW].
    public var plainCopy: UInt8
    /// +0x0a "Use InputSprocket" (not built; design §3.3).
    public var useInputSprocket: UInt8
    /// +0x0b sound on.
    public var soundOn: UInt8
    /// +0x0c music on.
    public var musicOn: UInt8
    /// +0x0e sound volume [MED].
    public var soundVolume: Int16
    /// +0x10 music volume (music = v·256/9).
    public var musicVolume: Int16
    /// +0x12..+0x22: the nine action key codes (engine §7.1).
    public var keys: [Int16]
    /// +0x2a (0x30, Tab) [LOW].
    public var key2a: Int16
    /// +0x30 (0x4c, Enter) [LOW].
    public var key30: Int16
    /// +0x32 switch the monitor to 640×480 (`.ResSwitch`).
    public var resolutionSwitch: Int16
    /// +0x34 ask the resolution question on launch (`DLOG 1300`).
    public var askResolution: Int16
    /// +0x36 use the system volume.
    public var useSystemVolume: Int16
    /// +0x38 the system output volume / 28 at first launch (`(v & 0xffff) / 0x1c`, l. 7745).
    public var systemVolumeBy28: Int16
    /// +0x3a machine hash for the CD check (out of scope).
    public var machineHash: Int16
    /// +0x3c, +0x3e, +0x40: written by `.InitPrefs` and "Default Settings" only; no reader.
    public var unread3c: Int16
    public var unread3e: Int16
    public var unread40: Int16
    /// +0x42 the last saved-game file name (pstr; default "@@@@@", `0x100a3193`). (+0x142, eight empty pstrs, is
    /// write-only and not modelled.)
    public var savedGameName: String

    /// `.InitPrefs`' fresh record. `processorType` is `Gestalt('cput')` (Effects 2 below 0x108, else 1);
    /// `systemVolume` the output volume `.InitPrefs` reads for +0x38.
    public init(processorType: Int = FerazelPrefs.modernProcessorType, systemVolume: UInt16 = 0) {
        reduceFrameRate = 0
        reuseSavedGames = 0
        graphics = 1
        parallax = 2
        effects = processorType < 0x108 ? 2 : 1
        backgroundTasks = 0
        plainCopy = 0
        useInputSprocket = 0
        soundOn = 1
        musicOn = 1
        soundVolume = 7
        musicVolume = 9
        keys = Self.defaultKeys
        key2a = 0x30
        key30 = 0x4c
        resolutionSwitch = 0
        askResolution = 1
        useSystemVolume = 0
        systemVolumeBy28 = Int16(systemVolume / 0x1c)
        machineHash = -1
        unread3c = 0
        unread3e = 0
        unread40 = 0
        savedGameName = "@@@@@"
    }
}

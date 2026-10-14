import Foundation
import HectorResources

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
    /// +0x0e sound-effects volume (play scale v·28; engine §8 BC17).
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
    /// +0x36 "Set system volume on startup" (engine §8 BC17; the replica never sets it, D35 deviation 8).
    public var useSystemVolume: Int16
    /// +0x38 the system output volume / 28 at first launch (`(v & 0xffff) / 0x1c`, l. 7745).
    public var systemVolumeBy28: Int16
    /// +0x3a machine hash for the CD check (out of scope).
    public var machineHash: Int16
    /// +0x3c, +0x3e, +0x40: written by `.InitPrefs` and "Default Settings" only; no reader.
    public var unread3c: Int16
    public var unread3e: Int16
    public var unread40: Int16
    /// +0x42 the last saved-game file name (pstr[256]; default "@@@@@", `0x100a3193`), Mac Roman. Setting it is
    /// `CopyPString`: the length byte and the characters are stored, the bytes past them keep what was there.
    public var savedGameName: String {
        get { pstr(at: FerazelPrefs.savedGameNameOffset) }
        set { setPstr(newValue, at: FerazelPrefs.savedGameNameOffset) }
    }
    /// +0x142 eight pstr[256] — write-only (only `.InitPrefs` touches them: `CopyPString("")`, raw `1000f410`),
    /// carried so a record read back is written back unchanged. Same `CopyPString` rule as `savedGameName`.
    public var recentNames: [String] {
        get { (0..<FerazelPrefs.recentNameCount).map { pstr(at: FerazelPrefs.recentNamesOffset + 0x100 * $0) } }
        set {
            precondition(newValue.count == FerazelPrefs.recentNameCount, "eight recent names")
            for (k, name) in newValue.enumerated() { setPstr(name, at: FerazelPrefs.recentNamesOffset + 0x100 * k) }
        }
    }

    /// The record's size (`NewHandle(0x942)` / `SetHandleSize(h, 0x942)`, M l. 7708, 7764).
    public static let byteCount = 0x942
    public static let savedGameNameOffset = 0x42
    public static let recentNamesOffset = 0x142
    public static let recentNameCount = 8

    /// Every byte of the record no stored property models — +0x0d, +0x24..+0x29, +0x2c..+0x2f — plus the pstr
    /// fields (+0x42, +0x142) whole, and anything past 0x942 in a longer record; the modelled scalar ranges are held
    /// 0 here (so `==` is record equality). A fresh record has 0 in every byte `.InitPrefs` never writes (NewHandle
    /// junk in the original [MED]; Phase 3 Invariant 7).
    private var bytes: [UInt8]

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
        bytes = [UInt8](repeating: 0, count: FerazelPrefs.byteCount)
        savedGameName = "@@@@@"                 // CopyPString(0x100a3193, +0x42)
        recentNames = Array(repeating: "", count: FerazelPrefs.recentNameCount)   // CopyPString(0x100a1530, +0x142+256k)
    }

    /// Reads a `'Pref'` 0 record. A record shorter than 0x942 is grown to 0x942 (`SetHandleSize`, no version check,
    /// M l. 7760–7766), the grown tail 0 (junk in the original; the replica's choice, Invariant 7); a longer one keeps
    /// its extra bytes (the original never shrinks the handle). Bytes no field models are preserved.
    public init(record: Data) {
        var b = [UInt8](record)
        if b.count < FerazelPrefs.byteCount { b += [UInt8](repeating: 0, count: FerazelPrefs.byteCount - b.count) }
        func u16(_ o: Int) -> UInt16 { UInt16(b[o]) << 8 | UInt16(b[o + 1]) }
        func i16(_ o: Int) -> Int16 { Int16(bitPattern: u16(o)) }
        reduceFrameRate = b[0x00]
        reuseSavedGames = b[0x01]
        graphics = i16(0x02)
        parallax = i16(0x04)
        effects = i16(0x06)
        backgroundTasks = b[0x08]
        plainCopy = b[0x09]
        useInputSprocket = b[0x0a]
        soundOn = b[0x0b]
        musicOn = b[0x0c]
        soundVolume = i16(0x0e)
        musicVolume = i16(0x10)
        keys = (0..<FerazelPrefs.actionCount).map { i16(0x12 + 2 * $0) }
        key2a = i16(0x2a)
        key30 = i16(0x30)
        resolutionSwitch = i16(0x32)
        askResolution = i16(0x34)
        useSystemVolume = i16(0x36)
        systemVolumeBy28 = i16(0x38)
        machineHash = i16(0x3a)
        unread3c = i16(0x3c)
        unread3e = i16(0x3e)
        unread40 = i16(0x40)
        for r in FerazelPrefs.modelledRanges { for o in r { b[o] = 0 } }
        bytes = b
    }

    /// The record as the PPC lays it out: big-endian, every field at its offset (engine §8), the unmodelled bytes as
    /// read (0 in a fresh record). 0x942 bytes, or the longer record's size.
    public func record() -> Data {
        var w = BigEndianWriter(count: 0)
        w.bytes = bytes
        w.u8(0x00, reduceFrameRate)
        w.u8(0x01, reuseSavedGames)
        w.i16(0x02, graphics)
        w.i16(0x04, parallax)
        w.i16(0x06, effects)
        w.u8(0x08, backgroundTasks)
        w.u8(0x09, plainCopy)
        w.u8(0x0a, useInputSprocket)
        w.u8(0x0b, soundOn)
        w.u8(0x0c, musicOn)
        w.i16(0x0e, soundVolume)
        w.i16(0x10, musicVolume)
        precondition(keys.count == FerazelPrefs.actionCount, "nine key codes")
        w.i16Array(0x12, keys)
        w.i16(0x2a, key2a)
        w.i16(0x30, key30)
        w.i16(0x32, resolutionSwitch)
        w.i16(0x34, askResolution)
        w.i16(0x36, useSystemVolume)
        w.i16(0x38, systemVolumeBy28)
        w.i16(0x3a, machineHash)
        w.i16(0x3c, unread3c)
        w.i16(0x3e, unread3e)
        w.i16(0x40, unread40)
        return Data(w.bytes)
    }

    /// `.IncrementLastSGString @ 1004811c` (M l. 41115) on +0x42, reading the bytes past the length as the original
    /// does (`SaveName.increment(field:)`).
    public mutating func incrementSavedGameName() {
        let o = FerazelPrefs.savedGameNameOffset
        let field = SaveName.increment(field: Array(bytes[o..<(o + 0x100)]))
        bytes.replaceSubrange(o..<(o + 0x100), with: field)
    }

    /// The scalar fields' byte ranges (held 0 in `bytes`; `record()` writes them from the properties).
    private static let modelledRanges: [Range<Int>] = [0x00..<0x0d, 0x0e..<0x24, 0x2a..<0x2c, 0x30..<0x42]

    private func pstr(at o: Int) -> String {
        MacRoman.decode(bytes[(o + 1)..<(o + 1 + Int(bytes[o]))])
    }

    /// `CopyPString` into a pstr[256]: length byte + characters (Mac Roman, at most 255), the rest untouched.
    private mutating func setPstr(_ s: String, at o: Int) {
        let body = MacRoman.bytes(s).prefix(255)
        bytes[o] = UInt8(body.count)
        bytes.replaceSubrange((o + 1)..<(o + 1 + body.count), with: body)
    }
}

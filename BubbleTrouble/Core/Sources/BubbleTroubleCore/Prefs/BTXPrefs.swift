import Foundation

/// The original's prefs blob `gPrefsData`: 0x800 bytes, big-endian, exactly as `_SaveGamePrefs @ 00026b36`
/// writes it to the data fork of "Bubble Trouble X Prefs" (data-formats §9):
///
/// | off | field |
/// |---|---|
/// | 0x000 | u16 version = 0x17 |
/// | 0x002 + (n−1) | bool n = 1…100 (byte n+1; `_SetBooleanPref @ 00026db5`) |
/// | 0x066 + 2(n−1) | i16 short n (`_SetShortPref @ 00026fe7`) |
/// | 0x12e + 4(n−1) | i32 long n |
/// | 0x2be + 22(n−1) | key set n = 1…20 (`KeySet`) |
/// | 0x476 + 40(n−1) | legacy score list n = 1…10: C name (30) + C decimal score at +0x1e (`_SetHighScore @ 00026df9`) |
///
/// Out-of-range indices trap (the original calls `_LocationErrorInt`, a fatal alert).
public struct BTXPrefs: Equatable, Sendable {
    public static let size = 0x800
    public static let currentVersion: UInt16 = 0x17

    public private(set) var data: Data

    /// Wraps a stored blob; nil unless exactly 0x800 bytes. No version check here — `BTXPrefsStore` gates it.
    public init?(data: Data) {
        guard data.count == Self.size else { return nil }
        self.data = Data(data)          // rebase to startIndex 0
    }

    /// `_ZeroPrefs @ 0002722d`: version 0x17, bools/shorts/longs 0, legacy list "Bubble Trouble X" 10000…1000.
    /// Bytes the original never writes (`NewPtr` garbage: key-set area, string tails) are zero here.
    public static func zeroed() -> BTXPrefs {
        var p = BTXPrefs(data: Data(count: size))!
        p.version = currentVersion
        for n in 1...10 { p.setLegacyScore(n, name: "Bubble Trouble X", score: 10000 - (n - 1) * 1000) }
        return p
    }

    /// Launch state before any prefs file is read: `_InitPrefs` (= `_ZeroPrefs`) then `_AlexPrefsInit @ 0000fa93`
    /// (`_main`), on OS X.
    public static var defaults: BTXPrefs {
        var p = zeroed()
        p.applyAlexPrefsInit()
        return p
    }

    // MARK: original init routines (the prefs dialog's Defaults button calls Sound + Keys + Game)

    /// `_AlexPrefsInit @ 0000fa93`.
    public mutating func applyAlexPrefsInit() {
        setBool(0x33, false)
        setBool(0x38, false)
        setBool(0x34, false)
        setBool(0x3a, false)
        setShort(0x3a, 10)
        setBool(0x3e, false)
        applyAlexPrefsSoundInit()
        applyAlexPrefsKeysInit()
        applyAlexPrefsGameInit()
    }

    /// `_AlexPrefsSoundInit @ 0000f6b8`.
    public mutating func applyAlexPrefsSoundInit() {
        setShort(0x33, 3)
        setShort(0x34, 3)
        setBool(0x39, false)
        setBool(0x3b, false)
        setBool(0x3c, false)
        setShort(0x35, 4)
        setShort(0x36, 4)
        setBool(0x40, true)
    }

    /// `_AlexPrefsKeysInit @ 0000f790`: InputSprockets off, 8 sets, current set 1, sets 1–8 = `KeySet.builtIn`.
    public mutating func applyAlexPrefsKeysInit() {
        setBool(0x41, false)
        setShort(0x37, 8)
        setShort(0x38, 1)
        for (i, set) in KeySet.builtIn.enumerated() { setKeySet(i + 1, set) }
    }

    /// `_AlexPrefsGameInit @ 0000fa24` (bool 0x3f = `!IsOSX()` = 0 — the replica is OS X).
    public mutating func applyAlexPrefsGameInit() {
        setShort(0x39, 2)
        setBool(0x37, false)
        setBool(0x3f, false)
        setBool(0x3d, false)
        setBool(0x35, true)
        setBool(0x36, true)
    }

    // MARK: generic accessors (pref numbers as the original's call sites use them)

    public var version: UInt16 {
        get { BigEndian.uint16(data, at: 0) }
        set { put16(newValue, at: 0) }
    }

    public func bool(_ n: Int) -> Bool { data[Self.boolOffset(n)] != 0 }
    public mutating func setBool(_ n: Int, _ value: Bool) { data[Self.boolOffset(n)] = value ? 1 : 0 }

    public func short(_ n: Int) -> Int16 { BigEndian.int16(data, at: Self.shortOffset(n)) }
    public mutating func setShort(_ n: Int, _ value: Int16) { put16(UInt16(bitPattern: value), at: Self.shortOffset(n)) }

    public func long(_ n: Int) -> Int32 { Int32(bitPattern: BigEndian.uint32(data, at: Self.longOffset(n))) }
    public mutating func setLong(_ n: Int, _ value: Int32) {
        let o = Self.longOffset(n), v = UInt32(bitPattern: value)
        data[o] = UInt8(v >> 24); data[o + 1] = UInt8(v >> 16 & 0xff)
        data[o + 2] = UInt8(v >> 8 & 0xff); data[o + 3] = UInt8(v & 0xff)
    }

    /// Key set n = 1…20 (`_GetKeySetPref @ 00027140`).
    public func keySet(_ n: Int) -> KeySet {
        let o = Self.keySetOffset(n)
        let codes = (0..<5).map { BigEndian.uint16(data, at: o + 12 + 2 * $0) }
        return KeySet(name: MacText.cString(data, at: o, capacity: 12),
                      left: codes[0], right: codes[1], up: codes[2], down: codes[3], push: codes[4])
    }

    /// `_SetKeySetPref @ 00027030`: 12 name bytes (C string, ≤ 11 characters, zero-padded here), then 5 × i16.
    public mutating func setKeySet(_ n: Int, _ set: KeySet) {
        let o = Self.keySetOffset(n)
        MacText.putCString(set.name, into: &data, at: o, capacity: 12)
        for (i, code) in set.codes.enumerated() { put16(code, at: o + 12 + 2 * i) }
    }

    /// Legacy score list n = 1…10 (written only by `_ZeroPrefs`; never read by 1.1).
    public func legacyScore(_ n: Int) -> (name: String, score: String) {
        let o = Self.legacyOffset(n)
        return (MacText.cString(data, at: o, capacity: 0x1e), MacText.cString(data, at: o + 0x1e, capacity: 10))
    }

    mutating func setLegacyScore(_ n: Int, name: String, score: Int) {
        let o = Self.legacyOffset(n)
        MacText.putCString(name, into: &data, at: o, capacity: 0x1e)
        MacText.putCString(String(score), into: &data, at: o + 0x1e, capacity: 10)
    }

    // MARK: typed accessors (every pref FI §8 names)

    /// short 0x33 — sound-effects volume 1–4 (0 = off).
    public var sfxVolume: Int { get { Int(short(0x33)) } set { setShort(0x33, Int16(newValue)) } }
    /// short 0x34 — last non-off sound-effects volume.
    public var lastSfxVolume: Int { get { Int(short(0x34)) } set { setShort(0x34, Int16(newValue)) } }
    /// short 0x35 — music volume 1–4 (0 = off).
    public var musicVolume: Int { get { Int(short(0x35)) } set { setShort(0x35, Int16(newValue)) } }
    /// short 0x36 — last non-off music volume.
    public var lastMusicVolume: Int { get { Int(short(0x36)) } set { setShort(0x36, Int16(newValue)) } }
    /// short 0x37 — number of key sets (1…20).
    public var keySetCount: Int { get { Int(short(0x37)) } set { setShort(0x37, Int16(newValue)) } }
    /// short 0x38 — current key set (1-based).
    public var currentKeySetIndex: Int { get { Int(short(0x38)) } set { setShort(0x38, Int16(newValue)) } }
    /// short 0x39 — sprite plotting (QuickDraw / QuickerDraw; forced QuickDraw on OS X).
    public var spritePlotting: Int { get { Int(short(0x39)) } set { setShort(0x39, Int16(newValue)) } }
    /// short 0x3a — highest level offered by level select; `_LoadLevel` raises it to any level reached if < 31.
    public var levelSelectMax: Int { get { Int(short(0x3a)) } set { setShort(0x3a, Int16(newValue)) } }

    /// bool 0x35 — show stars (gates `_NewStarGroup`, an RNG consumer).
    public var showStars: Bool { get { bool(0x35) } set { setBool(0x35, newValue) } }
    /// bool 0x36 — show air bubbles (gates `_Bubbles`, an RNG consumer).
    public var showAirBubbles: Bool { get { bool(0x36) } set { setBool(0x36, newValue) } }
    /// bool 0x37 — full screen.
    public var fullScreen: Bool { get { bool(0x37) } set { setBool(0x37, newValue) } }
    /// bool 0x3d — Escape must be held > 30 frames to end a game.
    public var holdEscapeToExit: Bool { get { bool(0x3d) } set { setBool(0x3d, newValue) } }
    /// bool 0x3e (byte 0x3f) — "default scores loaded" (`_LoadGamePrefs @ 00027306`).
    public var defaultScoresLoaded: Bool { get { bool(0x3e) } set { setBool(0x3e, newValue) } }
    /// bool 0x3f — QuickerDraw-related, `!IsOSX()`.
    public var quickerDraw: Bool { get { bool(0x3f) } set { setBool(0x3f, newValue) } }
    /// bool 0x40 — title-screen music.
    public var titleMusic: Bool { get { bool(0x40) } set { setBool(0x40, newValue) } }
    /// bool 0x41 — InputSprockets (stubs on OS X).
    public var inputSprockets: Bool { get { bool(0x41) } set { setBool(0x41, newValue) } }

    /// The key set `_InitControls` loads: set `currentKeySetIndex`.
    public var currentKeySet: KeySet { keySet(currentKeySetIndex) }

    /// The two RNG-gating cosmetic prefs as the simulation takes them.
    public var cosmetic: CosmeticPrefs { CosmeticPrefs(stars: showStars, airBubbles: showAirBubbles) }

    // MARK: layout

    static func boolOffset(_ n: Int) -> Int { precondition((1...100).contains(n), "bool pref \(n)"); return n + 1 }
    static func shortOffset(_ n: Int) -> Int { precondition((1...100).contains(n), "short pref \(n)"); return 0x66 + 2 * (n - 1) }
    static func longOffset(_ n: Int) -> Int { precondition((1...100).contains(n), "long pref \(n)"); return 0x12e + 4 * (n - 1) }
    static func keySetOffset(_ n: Int) -> Int { precondition((1...20).contains(n), "key set \(n)"); return 0x2be + 22 * (n - 1) }
    static func legacyOffset(_ n: Int) -> Int { precondition((1...10).contains(n), "legacy score \(n)"); return 0x476 + 40 * (n - 1) }

    private mutating func put16(_ v: UInt16, at o: Int) {
        data[o] = UInt8(v >> 8); data[o + 1] = UInt8(v & 0xff)
    }
}

/// Mac Roman C/Pascal string fields in fixed-size slots.
enum MacText {
    static func bytes(_ s: String) -> [UInt8] {
        [UInt8](s.data(using: .macOSRoman, allowLossyConversion: true) ?? Data())
    }

    static func string(_ bytes: some Collection<UInt8>) -> String {
        String(data: Data(bytes), encoding: .macOSRoman) ?? ""
    }

    /// C string in `capacity` bytes (terminator included).
    static func cString(_ data: Data, at o: Int, capacity: Int) -> String {
        let slot = data[(data.startIndex + o)..<(data.startIndex + o + capacity)]
        return string(slot.prefix { $0 != 0 })
    }

    /// Writes ≤ capacity−1 bytes + NUL, zero-padding the rest of the slot.
    static func putCString(_ s: String, into data: inout Data, at o: Int, capacity: Int) {
        let b = bytes(s).prefix(capacity - 1)
        for i in 0..<capacity { data[data.startIndex + o + i] = i < b.count ? b[b.startIndex + i] : 0 }
    }

    /// Pascal string in `capacity` bytes (length byte included).
    static func pString(_ data: Data, at o: Int, capacity: Int) -> String {
        let i = data.startIndex + o
        let length = min(Int(data[i]), capacity - 1)
        return string(data[(i + 1)..<(i + 1 + length)])
    }

    /// Writes length + ≤ capacity−1 bytes, zero-padding the rest of the slot.
    static func putPString(_ s: String, into data: inout Data, at o: Int, capacity: Int) {
        let b = bytes(s).prefix(capacity - 1)
        let i = data.startIndex + o
        data[i] = UInt8(b.count)
        for k in 0..<(capacity - 1) { data[i + 1 + k] = k < b.count ? b[b.startIndex + k] : 0 }
    }
}

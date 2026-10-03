import Foundation

/// The original's `_p` preferences + statistics as the 1.2 `GameSettings` defaults blob:
/// 143 bytes, packed, big-endian multi-byte fields (docs/aki/file-formats.md §2.2; `_SavePrefs`
/// @ 0x2882c writes, `_LoadPrefs` @ 0x293f6 reads). Field widths and signedness are the original's.
public struct GameSettings: Equatable, Sendable {
    /// Level i unlocked (12 bytes, p+0x200).
    public var unlocked: [UInt8]
    /// p+0x20c: 0 Hard / 1 Medium / 2 Easy / 3 Practice (other values are stored as-is).
    public var difficultyRaw: Int16
    /// p+0x20e: bit1 = Music on (Preferences checkbox), bit0 = registered.
    public var musicFlags: Int16
    /// p+0x210: bit1 = Sound on (Preferences checkbox); `_PlaySound` tests `!= 0`.
    public var soundFlags: Int16
    /// p+0x212 … p+0x216.
    public var fullscreen: UInt8, tileAnimation: UInt8, showDescription: UInt8, firstLaunch: UInt8, unused216: UInt8
    /// Per level (12 each): p+0x218 wins, p+0x230 losses, p+0x248 give-ups.
    public var wins: [Int16], losses: [Int16], giveUps: [Int16]
    /// p+0x260: best time per level in seconds, 0 = none (12).
    public var bestTimes: [Int32]

    public static let blobLength = 143
    public static let defaultsKey = "GameSettings"

    /// `_LoadPrefs`' no-key branch (= 1.1 `SetDefaultPrefs`).
    public static let defaults = GameSettings(
        unlocked: [1] + [UInt8](repeating: 0, count: 11), difficultyRaw: 1, musicFlags: 2, soundFlags: 2,
        fullscreen: 0, tileAnimation: 1, showDescription: 1, firstLaunch: 1, unused216: 1,
        wins: [Int16](repeating: 0, count: 12), losses: [Int16](repeating: 0, count: 12),
        giveUps: [Int16](repeating: 0, count: 12), bestTimes: [Int32](repeating: 0, count: 12))

    public init(unlocked: [UInt8], difficultyRaw: Int16, musicFlags: Int16, soundFlags: Int16,
                fullscreen: UInt8, tileAnimation: UInt8, showDescription: UInt8, firstLaunch: UInt8, unused216: UInt8,
                wins: [Int16], losses: [Int16], giveUps: [Int16], bestTimes: [Int32]) {
        self.unlocked = unlocked
        self.difficultyRaw = difficultyRaw
        self.musicFlags = musicFlags
        self.soundFlags = soundFlags
        self.fullscreen = fullscreen
        self.tileAnimation = tileAnimation
        self.showDescription = showDescription
        self.firstLaunch = firstLaunch
        self.unused216 = unused216
        self.wins = wins
        self.losses = losses
        self.giveUps = giveUps
        self.bestTimes = bestTimes
    }

    public enum DecodeError: Error, Equatable { case tooShort(Int) }

    /// Decodes the first 143 bytes of `blob`. The original reads without a length check; the
    /// replica refuses a short blob (the store then falls back to the defaults).
    public init(blob: Data) throws {
        let bytes = [UInt8](blob)
        guard bytes.count >= Self.blobLength else { throw DecodeError.tooShort(bytes.count) }
        self.init(bytes: bytes, layout: .blob)
    }

    /// The 143-byte blob `_SavePrefs` appends, in its order.
    public var blob: Data {
        var out = [UInt8]()
        out.reserveCapacity(Self.blobLength)
        func put16(_ v: Int16) { let u = UInt16(bitPattern: v); out += [UInt8(u >> 8), UInt8(u & 0xFF)] }
        func put32(_ v: Int32) { let u = UInt32(bitPattern: v); out += [UInt8(u >> 24), UInt8((u >> 16) & 0xFF), UInt8((u >> 8) & 0xFF), UInt8(u & 0xFF)] }
        for i in 0..<12 { out.append(Self.at(unlocked, i, 0)) }
        put16(difficultyRaw); put16(musicFlags); put16(soundFlags)
        out += [fullscreen, tileAnimation, showDescription, firstLaunch, unused216]
        for i in 0..<12 { put16(Self.at(wins, i, 0)) }
        for i in 0..<12 { put16(Self.at(losses, i, 0)) }
        for i in 0..<12 { put16(Self.at(giveUps, i, 0)) }
        for i in 0..<12 { put32(Self.at(bestTimes, i, 0)) }
        return Data(out)
    }

    /// The 1.1 `Aki Prefs` file (file-formats §2.3, §3): the raw 0x290-byte `PrefsType`, big-endian,
    /// fields at `_p`'s offsets 0x200…0x28f. nil when shorter than 0x290 bytes.
    public static func migrating(akiPrefs11 data: Data) -> GameSettings? {
        let bytes = [UInt8](data)
        guard bytes.count >= 0x290 else { return nil }
        return GameSettings(bytes: bytes, layout: .prefs11)
    }

    // MARK: - Accessors

    public func isUnlocked(_ level: Int) -> Bool { unlocked.indices.contains(level) && unlocked[level] != 0 }
    public var difficulty: Difficulty? { Difficulty(rawValue: difficultyRaw) }
    public var musicOn: Bool { musicFlags >= 2 }
    public var soundAudible: Bool { soundFlags != 0 }
    /// `_updateUI`: the Preferences checkboxes are on when the flag is > 1.
    public var soundCheckbox: Bool { soundFlags > 1 }
    public var musicCheckbox: Bool { musicFlags > 1 }
    public var registered: Bool { musicFlags & 1 != 0 }

    /// `-[Preferences save:]`: p+0x210 = old % 2 + 2 · checkbox.
    public mutating func setSoundCheckbox(_ on: Bool) { soundFlags = soundFlags % 2 + (on ? 2 : 0) }
    /// `-[Preferences save:]`: p+0x20e = old % 2 + 2 · checkbox.
    public mutating func setMusicCheckbox(_ on: Bool) { musicFlags = musicFlags % 2 + (on ? 2 : 0) }

    /// `_LoopMusic(1)` after `_LoadPrefs`, registered path (the replica behaves as registered):
    /// 3 → 2, 1 → 0, then > 1 → 3, < 1 → 1.
    public mutating func applyLaunchRegistration() {
        if musicFlags == 3 { musicFlags = 2 }
        if musicFlags == 1 { musicFlags = 0 }
        if musicFlags > 1 { musicFlags = 3 }
        if musicFlags < 1 { musicFlags = 1 }
    }

    // MARK: - Private

    private enum Layout {
        case blob, prefs11
        /// Byte offsets of unlock, difficulty, music, sound, flags, wins, losses, give-ups, best.
        var offsets: (unlock: Int, difficulty: Int, music: Int, sound: Int, flags: Int, wins: Int, losses: Int, giveUps: Int, best: Int) {
            switch self {
            case .blob: (0, 12, 14, 16, 18, 23, 47, 71, 95)
            case .prefs11: (0x200, 0x20c, 0x20e, 0x210, 0x212, 0x218, 0x230, 0x248, 0x260)
            }
        }
    }

    private init(bytes b: [UInt8], layout: Layout) {
        let o = layout.offsets
        func s16(_ at: Int) -> Int16 { Int16(bitPattern: UInt16(b[at]) << 8 | UInt16(b[at + 1])) }
        func s32(_ at: Int) -> Int32 {
            Int32(bitPattern: UInt32(b[at]) << 24 | UInt32(b[at + 1]) << 16 | UInt32(b[at + 2]) << 8 | UInt32(b[at + 3]))
        }
        self.init(unlocked: Array(b[o.unlock..<o.unlock + 12]), difficultyRaw: s16(o.difficulty),
                  musicFlags: s16(o.music), soundFlags: s16(o.sound),
                  fullscreen: b[o.flags], tileAnimation: b[o.flags + 1], showDescription: b[o.flags + 2],
                  firstLaunch: b[o.flags + 3], unused216: b[o.flags + 4],
                  wins: (0..<12).map { s16(o.wins + 2 * $0) }, losses: (0..<12).map { s16(o.losses + 2 * $0) },
                  giveUps: (0..<12).map { s16(o.giveUps + 2 * $0) }, bestTimes: (0..<12).map { s32(o.best + 4 * $0) })
    }

    private static func at<T>(_ array: [T], _ i: Int, _ fallback: T) -> T { array.indices.contains(i) ? array[i] : fallback }
}

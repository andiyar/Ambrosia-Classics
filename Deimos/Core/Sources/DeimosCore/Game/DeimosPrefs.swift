import Foundation

/// The fields of the 0x34f0-byte prefs record (`_DAT_100def40`; engine-loop §10, timing-frame §6) the build
/// uses so far, with the original's fresh-prefs defaults. File I/O (the on-disk layout and obfuscation) is
/// Phase 4. ★ LOCKED seam (plan S2 / design §3).
public struct DeimosPrefs: Equatable, Sendable {
    /// +0x0000: 0x2714 (10004).
    public var version: UInt32
    /// +0x0004+n: byte pref n (0x64 bytes up to the int prefs). 2 config dialog done, 4 "Full Screen" (never
    /// read), 5 interlacing, 6 auto-interlacing, 7 bypass system volume, 8 Esc-hold, 9 FPS display,
    /// 10 FPS limiter.
    public var bytePrefs: [UInt8]
    /// +0x0068+4n: int pref n, 0…3: sound volume, music volume, (no reader), highest sector reached.
    public var intPrefs: [Int32]
    /// +0x14b8…+0x14ec: 14 Mac virtual key codes (stored as 4-byte ints), P1 then P2, seven each in slot
    /// order up, left, right, down, then three buttons (slot meaning LOW — design §7.3).
    public var keyTable: [UInt16]
    /// +0x1260: 15 high scores (in memory, not the on-disk +0x24a8903 form).
    public var highScores: [Int32]
    /// +0x10f8: 15 high-score names (≤ 20 characters each).
    public var highScoreNames: [String]
    /// +0x12d8: 15 per-entry sector names.
    public var highScoreSectorNames: [String]
    /// +0x1233: the two player names.
    public var playerNames: [String]

    public init(version: UInt32, bytePrefs: [UInt8], intPrefs: [Int32], keyTable: [UInt16], highScores: [Int32],
                highScoreNames: [String], highScoreSectorNames: [String], playerNames: [String]) {
        self.version = version
        self.bytePrefs = bytePrefs
        self.intPrefs = intPrefs
        self.keyTable = keyTable
        self.highScores = highScores
        self.highScoreNames = highScoreNames
        self.highScoreSectorNames = highScoreSectorNames
        self.playerNames = playerNames
    }

    /// Byte pref count: +0x04 up to the int prefs at +0x68.
    public static let bytePrefCount = 0x64

    /// Fresh prefs (`FUN_10004540` when no prefs file loads): zeroed block, version 0x2714, the defaults of
    /// `FUN_10004ae0` (scores `16000 − 1000·k`, names from the table at `0x100d61c0`, "Player %i",
    /// "New Atlantis"), then `FUN_10004f20(1)` → `FUN_100050f0` (byte 4 = 1, ints 0/1/2 = 50/100/50, the key
    /// table `1000515c..10005194`) and byte 10 = 1 (FPS limiter ON), int 3 = 1 (timing-frame §6).
    public static let fresh: DeimosPrefs = {
        var bytes = [UInt8](repeating: 0, count: bytePrefCount)
        bytes[4] = 1
        bytes[10] = 1
        return DeimosPrefs(
            version: 0x2714,
            bytePrefs: bytes,
            intPrefs: [50, 100, 50, 1],
            keyTable: [0x7E, 0x7B, 0x7C, 0x7D, 0x37, 0x3A, 0x31,
                       0x5B, 0x56, 0x58, 0x57, 0x77, 0x75, 0x79],
            highScores: (1...15).map { Int32(16_000 - 1_000 * $0) },
            highScoreNames: ["Mars", "Supercobra", "Neurotik", "El B", "Dilvish", "Sam", "Vodi", "Fisj", "Alex",
                             "h'biki", "Goldenberry", "Leadfeather", "Troll", "Thomas", "Electrofryer"],
            highScoreSectorNames: Array(repeating: "New Atlantis", count: 15),
            playerNames: ["Player 1", "Player 2"])
    }()
}

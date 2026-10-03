import Foundation

/// One LEVL resource: 32 big-endian `Int16` words, copied raw into `level` by `_LoadLevel @ 00002ef7`
/// (Research note 9, data-formats.md §2). `words` keeps them as stored; the accessors apply
/// `_LoadLevel`'s clamps where it has them (w6, w12).
public struct LevelRecord: Equatable, Sendable {
    public static let wordCount = 32, byteCount = 64

    public var words: [Int16]

    public init(data: Data) throws {
        try self.init(data: data, id: 0)
    }

    init(data: Data, id: Int16) throws {
        guard data.count == Self.byteCount else {
            throw BTXDataError.badSize(type: "LEVL", id: id, size: data.count)
        }
        words = (0..<Self.wordCount).map { BigEndian.int16(data, at: 2 * $0) }
    }

    private func word(_ index: Int) -> Int { Int(words[index]) }

    /// w0 — MAZE id (= level id in all 50).
    public var mazeID: Int { word(0) }
    /// w1 — background PICT id (912 lives in `Bubble Trouble X.rsrc`; 13000–13005 in `BT Levels.rsrc`).
    public var pictID: Int { word(1) }
    /// w2 — music set 1..4.
    public var musicSet: Int { word(2) }
    /// w3 — "hurt block" redraw frame, bubble (draw only).
    public var hurtFrameBubble: Int { word(3) }
    /// w4 — "hurt block" redraw frame, jewel (draw only).
    public var hurtFrameJewel: Int { word(4) }
    /// w6 clamped: `sVar8 = 0x1e; if (w6 < 0x1f) sVar8 = w6;` (`_LoadLevel`).
    public var totalEnemies: Int { word(6) < 31 ? word(6) : 30 }
    /// w7 — max active enemies.
    public var maxActive: Int { word(7) }
    /// w8 — egg time (50 in all shipped levels).
    public var eggTime: Int { word(8) }
    /// w10 — pre-egg delay (10 in all shipped levels).
    public var preEggDelay: Int { word(10) }
    /// w12 clamped to 3...4 (`_LoadLevel`: `if (2 < w12) …; if (4 < s) 4`).
    public var jewelCount: Int { min(max(word(12), 3), 4) }
    /// w15 — balloon flash frame.
    public var balloonFlash: Int { word(15) }
    /// w16 — balloon release frame.
    public var balloonRelease: Int { word(16) }
    /// w18...w23 — enemy pool per type 1..6 (mutated at run time by the game state, not here).
    public var pool: [Int16] { Array(words[18...23]) }
}

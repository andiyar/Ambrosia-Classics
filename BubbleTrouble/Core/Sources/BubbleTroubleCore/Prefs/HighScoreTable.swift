import Foundation

/// The 0x8a high-score block `highScores` (data-formats §8): `SCOR 128` is the factory copy, and the same
/// bytes follow the 0x800 prefs blob in the prefs file. Big-endian, as stored:
///
/// | off | field |
/// |---|---|
/// | 0x00 | Pascal string (12): default name offered in the entry dialog = last name entered |
/// | 0x0c + 12i | Pascal names, entries i = 0…6 (0 = best) |
/// | 0x60 + 4i | i32 scores |
/// | 0x7c + 2i | i16 level reached |
///
/// Entry rules transcribe `_CheckHiScore @ 00024b34`. Custom-level "^" suffix (PICT 9077 badge) is not built
/// (plan Known delta 3).
public struct HighScoreTable: Equatable, Sendable {
    public static let size = 0x8a
    public static let entryCount = 7
    /// Name slots are 12-byte Pascal strings: ≤ 11 characters.
    public static let nameCapacity = 12

    public struct Entry: Equatable, Sendable {
        public var name: String
        public var score: Int32
        public var level: Int
    }

    public private(set) var data: Data

    /// Wraps a stored block; nil unless exactly 0x8a bytes.
    public init?(data: Data) {
        guard data.count == Self.size else { return nil }
        self.data = Data(data)
    }

    /// All-zero block (empty names, zero scores).
    public static var empty: HighScoreTable { HighScoreTable(data: Data(count: size))! }

    /// `_LoadDefaultHiScores @ 000249d4`: `SCOR 128` from the app file.
    public static func factory(from game: BTXGameData) throws -> HighScoreTable {
        guard let raw = game.data(type: "SCOR", id: 128) else {
            throw BTXDataError.missingResource(type: "SCOR", id: 128)
        }
        guard let table = HighScoreTable(data: raw) else {
            throw BTXDataError.badSize(type: "SCOR", id: 128, size: raw.count)
        }
        return table
    }

    // MARK: fields

    /// Slot 0: the name pre-filled in DLOG 1000 (`SetDialogString(dlg, 2, highScores)`).
    public var defaultName: String {
        get { MacText.pString(data, at: 0, capacity: Self.nameCapacity) }
        set { MacText.putPString(newValue, into: &data, at: 0, capacity: Self.nameCapacity) }
    }

    public func entry(_ i: Int) -> Entry {
        precondition((0..<Self.entryCount).contains(i), "high-score entry \(i)")
        return Entry(name: MacText.pString(data, at: 0x0c + 12 * i, capacity: Self.nameCapacity),
                     score: Int32(bitPattern: BigEndian.uint32(data, at: 0x60 + 4 * i)),
                     level: Int(BigEndian.int16(data, at: 0x7c + 2 * i)))
    }

    public var entries: [Entry] { (0..<Self.entryCount).map(entry) }

    /// Overwrites entry i (name, score, level); the default-name slot is left alone.
    public mutating func setEntry(_ i: Int, name: String, score: Int32, level: Int) {
        precondition((0..<Self.entryCount).contains(i), "high-score entry \(i)")
        MacText.putPString(name, into: &data, at: 0x0c + 12 * i, capacity: Self.nameCapacity)
        setScore(i, score: score, level: level)
    }

    // MARK: _CheckHiScore

    /// Qualifies when the score is strictly greater than entry #7 (`GetScore() <= highScores+0x78` → no).
    public func qualifies(score: Int32) -> Bool { score > entry(Self.entryCount - 1).score }

    /// The shift-down loop of `_CheckHiScore`: from entry 5 upwards, while `score > entry[k]`, entry k moves to
    /// k+1 (name, score, level); the score and level land at k+1. Returns that index, or nil if the score does
    /// not qualify. The slot's name is the shifted-out one until `setName(_:at:)` (the dialog comes after).
    public mutating func insertScore(score: Int32, level: Int) -> Int? {
        guard qualifies(score: score) else { return nil }
        var k = Self.entryCount - 2
        while k >= 0, score > entry(k).score {
            let moved = rawEntry(k)
            putRawEntry(k + 1, moved)
            k -= 1
        }
        setScore(k + 1, score: score, level: level)
        return k + 1
    }

    /// After DLOG 1000: the (already resolved) name goes into entry `index` and into the default-name slot
    /// (`memmove(highScores, entry, 12)`).
    public mutating func setName(_ name: String, at index: Int) {
        precondition((0..<Self.entryCount).contains(index), "high-score entry \(index)")
        MacText.putPString(name, into: &data, at: 0x0c + 12 * index, capacity: Self.nameCapacity)
        defaultName = entry(index).name
    }

    /// `insertScore` then `setName`; nil (table untouched) when the score does not qualify.
    @discardableResult
    public mutating func insert(name: String, score: Int32, level: Int) -> Int? {
        guard let index = insertScore(score: score, level: level) else { return nil }
        setName(name, at: index)
        return index
    }

    // MARK: name rules

    public struct JokeName: Equatable, Sendable {
        /// The typed name (exact, case-sensitive C-string compare: `rep cmpsb` over strlen+1 bytes).
        public let typed: String
        public let replacement: String
        /// `_PlayMySnd(sound, 10, 0)` on a match: snd 9000 + sound.
        public let sound: Int
        /// Disasm address of the compare (`movl $<string>, %edi`).
        public let anchor: UInt32
    }

    /// The compare chain of `_CheckHiScore @ 00024b34`, in order; each test runs on the (possibly already
    /// substituted) name, so at most one matches. Compare strings at 0x32d28…0x32d7c in `__cstring`.
    public static let jokeNames: [JokeName] = [
        JokeName(typed: "Wareing", replacement: "Swoop!", sound: 13, anchor: 0x0002_5048),    // snd @ 0002509d
        JokeName(typed: "Metcalf", replacement: "Maniac!", sound: 13, anchor: 0x0002_50a2),   // snd @ 000250f1
        JokeName(typed: "Luke", replacement: "Skywalker", sound: 13, anchor: 0x0002_50f6),    // snd @ 0002514e
        JokeName(typed: "Dog", replacement: "Nonny", sound: 46, anchor: 0x0002_5153),         // → 0002519a, snd @ 000251c4
        JokeName(typed: "Woof", replacement: "Nonny", sound: 46, anchor: 0x0002_5177),        // → 0002519a, snd @ 000251c4
        JokeName(typed: "Han", replacement: "Solo", sound: 13, anchor: 0x0002_51c9),          // snd @ 00025215
        JokeName(typed: "Darth", replacement: "Vader", sound: 13, anchor: 0x0002_521a),       // snd @ 00025268
        JokeName(typed: "Ben", replacement: "Obi Wan", sound: 13, anchor: 0x0002_526d),       // snd @ 000252bc
        JokeName(typed: "Apple", replacement: "Moof", sound: 13, anchor: 0x0002_52c1),        // snd @ 0002530d
        JokeName(typed: "Bart", replacement: "Simpson", sound: 13, anchor: 0x0002_5312),      // snd @ 00025361
        JokeName(typed: "Homer", replacement: "Doh", sound: 13, anchor: 0x0002_5366),         // snd @ 000253ab
        JokeName(typed: "Steve", replacement: "Woz", sound: 13, anchor: 0x0002_53b0),         // snd @ 000253f5
        JokeName(typed: "Oogle", replacement: "Boogle", sound: 13, anchor: 0x0002_53fa),      // snd @ 0002544f
    ]

    /// The name that goes into the table for what was typed in DLOG 1000, and the extra sound (if any) played
    /// after the OK click (snd 15, played by the caller). Empty → `GetRandomFast(0, 1)`: 0 "Maniac", else "Swoop"
    /// (no extra sound; disasm 00024fbd). `randomFast(lo, hi)` is the session's front-end generator, never the
    /// simulation's RNG.
    public static func resolveName(typed: String, randomFast: (Int, Int) -> Int) -> (name: String, sound: Int?) {
        if typed.isEmpty {
            return (randomFast(0, 1) == 0 ? "Maniac" : "Swoop", nil)
        }
        var name = typed
        var sound: Int?
        for joke in jokeNames where name == joke.typed {
            name = joke.replacement
            sound = joke.sound
        }
        return (name, sound)
    }

    // MARK: raw slots

    private mutating func setScore(_ i: Int, score: Int32, level: Int) {
        let s = UInt32(bitPattern: score), so = data.startIndex + 0x60 + 4 * i
        data[so] = UInt8(s >> 24); data[so + 1] = UInt8(s >> 16 & 0xff)
        data[so + 2] = UInt8(s >> 8 & 0xff); data[so + 3] = UInt8(s & 0xff)
        let l = UInt16(bitPattern: Int16(truncatingIfNeeded: level)), lo = data.startIndex + 0x7c + 2 * i
        data[lo] = UInt8(l >> 8); data[lo + 1] = UInt8(l & 0xff)
    }

    private func rawEntry(_ i: Int) -> (name: Data, score: Data, level: Data) {
        (data.subdata(in: (0x0c + 12 * i)..<(0x18 + 12 * i)),
         data.subdata(in: (0x60 + 4 * i)..<(0x64 + 4 * i)),
         data.subdata(in: (0x7c + 2 * i)..<(0x7e + 2 * i)))
    }

    private mutating func putRawEntry(_ i: Int, _ e: (name: Data, score: Data, level: Data)) {
        data.replaceSubrange((0x0c + 12 * i)..<(0x18 + 12 * i), with: e.name)
        data.replaceSubrange((0x60 + 4 * i)..<(0x64 + 4 * i), with: e.score)
        data.replaceSubrange((0x7c + 2 * i)..<(0x7e + 2 * i), with: e.level)
    }
}

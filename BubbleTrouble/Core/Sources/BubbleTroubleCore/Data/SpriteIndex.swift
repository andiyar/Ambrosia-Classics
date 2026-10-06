import Foundation

/// The sprite addressing table: `SpIL 128` lists the `SpIc` resources ("sprite data sets"), each `SpIc`
/// lists its sprite sets as {start cicn id, frame count} (data-formats §4; `TMPL 25000/25001`).
///
/// Transcribes `_InitCompiledSprites @ 00015784`: the SpIL count field is stored n−1 (`for i = 0; i <= n`)
/// and capped at 0x13 (`_LocationErrorInt(0x7d2, 2)`); each SpIc count field is stored n−1 too (`+ 1`;
/// 0x33 → 52 sets in `SpIc 1000`, amendment R9), capped at 100 (`_LocationErrorInt(0x7d2, 4)`).
/// `_SpriteToComp(dataSet, h, v, s, f)` plots frame `f` (1-based) of set `s` (1-based) =
/// `cicn start[s−1] + f − 1`. On OS X every sprite is that `cicn` (`_IsDoubleBuffered` → `gUsePlotIcon`).
public struct SpriteIndex: Equatable, Sendable {
    public struct Entry: Equatable, Sendable {
        public let startID: Int
        public let frameCount: Int
    }

    /// The SpIc ids listed by `SpIL 128`, in order (`gSpriteDataIDs`); the shipped game lists only 1000.
    public let dataSetIDs: [Int]
    /// `entries[d][s − 1]` = sprite set `s` of data set `d`.
    public let dataSets: [[Entry]]

    /// Parses `SpIL` bytes, then each listed `SpIc` through `spicData` (nil → missing resource).
    public init(spilData: Data, spicData: (Int) -> Data?) throws {
        guard spilData.count >= 2 else { throw BTXDataError.badSize(type: "SpIL", id: 128, size: spilData.count) }
        let last = Int(BigEndian.int16(spilData, at: 0))
        guard last <= 0x13, last >= 0, spilData.count >= 2 + 2 * (last + 1) else {
            throw BTXDataError.badSize(type: "SpIL", id: 128, size: spilData.count)
        }
        var ids: [Int] = []
        var sets: [[Entry]] = []
        for i in 0...last {
            let id = Int(BigEndian.int16(spilData, at: 2 + 2 * i))
            guard let spic = spicData(id) else {
                throw BTXDataError.missingResource(type: "SpIc", id: Int16(truncatingIfNeeded: id))
            }
            ids.append(id)
            sets.append(try Self.parseSpIc(spic, id: id))
        }
        dataSetIDs = ids
        dataSets = sets
    }

    static func parseSpIc(_ data: Data, id: Int) throws -> [Entry] {
        let bad = BTXDataError.badSize(type: "SpIc", id: Int16(truncatingIfNeeded: id), size: data.count)
        guard data.count >= 2 else { throw bad }
        let count = Int(BigEndian.int16(data, at: 0)) + 1
        guard count >= 0, count <= 100, data.count >= 2 + 4 * count else { throw bad }
        return (0..<count).map { s in
            Entry(startID: Int(BigEndian.int16(data, at: 2 + 4 * s)),
                  frameCount: Int(BigEndian.int16(data, at: 4 + 4 * s)))
        }
    }

    /// Number of sprite sets in data set 0 (52 in the shipped game).
    public var setCount: Int { dataSets.first?.count ?? 0 }

    /// The `cicn` id of 1-based `frame` of 1-based sprite `set` in data set `dataSet` (0 for every call in
    /// the shipped game): `start[set − 1] + frame − 1`. Like the original, the frame is not range-checked.
    public func cicnID(set: Int, frame: Int, dataSet: Int = 0) -> Int {
        dataSets[dataSet][set - 1].startID + frame - 1
    }

    /// The number of frames in 1-based sprite `set`.
    public func frameCount(set: Int, dataSet: Int = 0) -> Int {
        dataSets[dataSet][set - 1].frameCount
    }
}

import Foundation

/// The films from the menu (grounding B §3, §4): DEMOS and `D` — `FUN_10024de0` → `FUN_100234d0(2, 1)`, the next
/// film whose name holds "Demo" by the counter G+0x24 (`FrontEndState.demoCounter`); `F` — `FUN_10024e10` →
/// `FUN_100234d0(1, 1)`, Last Film (the film held in memory, `FrontEndState.lastFilm`, else the one on disk).
/// Phase 4 S5 DM.
///
/// **Frozen entry.** `init(kind:)`. **Returns** nothing (`ScreenDone`): it chooses the film and plays it through
/// start/return (`StartReturn(mode: .demo / .lastFilm, players: 1, film:)`), then returns to the menu.
///
/// **The choice** (`FUN_100069b0`, dump `4157..4215`, before the film loads). A demo: walk the tag index's `film`
/// records in index order (`FUN_10002340`), counting those whose tag name holds "Demo" (`FUN_10057a30` = `strstr`,
/// case kept); take the one at position G+0x24 and add 1. None there: G+0x24 = 0, walk again, take the first and set
/// G+0x24 = 1 — or, with no "Demo" film at all, leave it 0 and ask for `none`, which does not load. Last Film: tag
/// `last` (`10006aec..10006af0`) — here the recording held in memory (`FrontEndState.lastFilm`, what the original had just
/// written to disk and re-indexed, B §4b), else the index's `last`. **A film that does not load** (no record, or
/// bytes that do not decode as a film) is handed to start/return as nil: `FUN_100051a0` returns at `100056dc..100056f0`
/// with the result still zero (B §9 item 3), which is start/return's `SessionResult.filmLoadFailed`. The counter has
/// already moved: the choice comes before the load.
public struct Films: Sendable {
    public enum Kind: Equatable, Sendable {
        case demo
        case lastFilm
    }

    public typealias Result = ScreenDone

    public let kind: Kind

    /// Start/return has been called with the film.
    private var played = false

    public init(kind: Kind) {
        self.kind = kind
    }

    public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                              state: inout FrontEndState) -> ScreenStep<Result> {
        if played { return .finish(ScreenDone()) }                   // start/return came back: to the menu
        played = true
        let mode: StartReturn.Mode = kind == .demo ? .demo : .lastFilm
        let film = kind == .demo ? Self.nextDemo(&state) : Self.lastFilm(state)
        return .call(.startReturn(StartReturn(mode: mode, players: 1, film: film)))   // FUN_100234d0(mode, 1)
    }

    /// The tag name that marks a demo (`_DAT_100e00f8`).
    static let demoMark = "Demo"

    /// `FUN_100069b0` mode 2: the demo at position G+0x24 among the "Demo" films, G+0x24 moved on; nil when it
    /// does not load.
    static func nextDemo(_ state: inout FrontEndState) -> Film? {
        guard let type = FourCC("film") else { return nil }
        let demos = state.assets.index.records(ofType: type).filter { $0.tagName.contains(demoMark) }
        let record: TagIndex.Record?
        if demos.indices.contains(state.demoCounter) {
            record = demos[state.demoCounter]                        // 10006a18..10006a2c
            state.demoCounter += 1
        } else {
            state.demoCounter = 0                                    // 10006a6c..10006a74
            record = demos.first
            if record != nil { state.demoCounter = 1 }               // 10006aa0..10006ab4
        }
        return record.flatMap { load($0, from: state.assets.index) }
    }

    /// `F`: the Last Film held in memory, else the index's `last`; nil when neither loads.
    static func lastFilm(_ state: FrontEndState) -> Film? {
        if !state.lastFilm.isEmpty { return try? Film(data: Data(state.lastFilm)) }
        guard let type = FourCC("film"), let id = FourCC("last"),
              let record = state.assets.index.record(type: type, id: id) else { return nil }
        return load(record, from: state.assets.index)
    }

    /// `FUN_100094a0` (`10006afc`): the record's bytes as a film, nil when they cannot be read or decoded.
    private static func load(_ record: TagIndex.Record, from index: TagIndex) -> Film? {
        guard let data = try? index.data(for: record) else { return nil }
        return try? Film(data: data)
    }
}

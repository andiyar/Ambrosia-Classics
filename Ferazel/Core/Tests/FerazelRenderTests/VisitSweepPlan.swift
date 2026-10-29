import FerazelCore
import Foundation

// The "visit every object" sweep (2026-10-29, after the Windows beta's teleporter and level-2 light-face quits): the
// shared half — the scope, the visits, the key script, the failure rows and the table. Foundation + FerazelCore only.
// Compiled by FerazelRenderTests (the Core path, `VisitSweepTests`) and, through a git symlink, by FerazelWinKitTests
// (the Windows shell path, `WinVisitSweepTests`). Runner: tools/ferazel-visit-sweep.sh (its header says how the loop
// runs it at every phase end).
//
// A visit: Ferazel is put beside one placement record by the save trick — a checkpoint save (`SaveBlock.savePointSave`)
// of the level's own records with the player's start at an offset from the record — which the real flow continues
// (`GameFlow.openDocument` at the main menu → `.ContinueGame` → `LevelRun`), drawn by the real renderers; then a few
// seconds of scripted keys. Every modal is answered as the shells answer it (dialogs OK, the save panel a file,
// conversations Return), so only a real refusal, throw or stuck suspension becomes a row.

enum VisitSweep {
    /// The playable scope: the levels the sweep visits. Later phases extend `BuiltLevels.range`; the sweep follows.
    static let levels: [Int] = Array(BuiltLevels.range)

    /// Where Ferazel starts relative to the record's top-left (px; the save's start is the player sprite's top-left).
    enum Offset: String, CaseIterable, Sendable {
        case on, left, right, above

        var delta: (dx: Int, dy: Int) {
            switch self {
            case .on: (0, 0)
            case .left: (-48, 0)
            case .right: (48, 0)
            case .above: (0, -64)
            }
        }

        /// The direction that walks into the record from here (nil: on it / above it).
        var toward: Int? {
            switch self {
            case .left: 1      // input 1 = right
            case .right: 0     // input 0 = left
            case .on, .above: nil
            }
        }
    }

    /// One visit: a record of a level, a start offset.
    struct Visit: Sendable {
        let level: Int
        let record: Placement
        let offset: Offset

        var label: String { "L\(level) rec \(record.index) type \(VisitSweep.hex(record.type)) @\(offset.rawValue)" }
    }

    /// The offsets each record is visited from (`FERAZEL_VISIT_OFFSETS=on,above` narrows it).
    static var offsets: [Offset] {
        guard let s = ProcessInfo.processInfo.environment["FERAZEL_VISIT_OFFSETS"], !s.isEmpty else {
            return Offset.allCases
        }
        return s.split(separator: ",").compactMap { Offset(rawValue: String($0)) }
    }

    /// Every spawned record (`flag == 1`, the ones `.SetupLevel` builds — those its Setup idles included) of `level`,
    /// from each offset, in record order.
    static func visits(level: Int, records: [Placement], offsets: [Offset] = VisitSweep.offsets) -> [Visit] {
        records.filter { $0.flag == 1 && $0.type != 0 }.flatMap { r in offsets.map { Visit(level: level, record: r, offset: $0) } }
    }

    // MARK: The save trick

    /// A checkpoint save of `level`'s own records with Ferazel's start at the visit's offset (`.SavePointSave`'s block,
    /// as a save point writes it); Continue restores the snapshot and starts the loop there.
    static func save(for visit: Visit, records: [Placement], stamp: UInt32) -> SaveBlock {
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        let d = visit.offset.delta
        let x = Int16(clamping: Int(visit.record.x) + d.dx), y = Int16(clamping: Int(visit.record.y) + d.dy)
        save.savePointSave(level: Int16(visit.level), x: max(x, 0), y: max(y, 0), stamp: stamp, date: 0,
                           globals: &g, records: records)
        return save
    }

    // MARK: The key script

    /// Game ticks of scripted play once the level's loop runs (≈ 4 s at 60 ticks a second).
    static let playTicks = 240
    /// Ticks allowed after the script for a modal to finish (a conversation, a mosaic, the save flash) and, after a
    /// level exit, for the stage-complete screens to reach the world map.
    static let drainTicks = 1500

    /// The input actions held at script tick `k` (`FerazelPrefs.keys` indices: 0 left, 1 right, 2 up, 3 down, 5 jump,
    /// 6 cast, 8 use): stand; walk into the record; tap up (doors, talkers, switches); tap down; tap cast; jump toward
    /// it; tap use; stand.
    static func actions(at k: Int, offset: Offset) -> [Int] {
        let tap = (k / 5) % 2 == 0
        let toward = offset.toward.map { [$0] } ?? []
        switch k {
        case 0..<20: return []
        case 20..<70: return toward
        case 70..<100: return tap ? [2] : []
        case 100..<130: return tap ? [3] : []
        case 130..<160: return tap ? [6] : []
        case 160..<190: return (tap ? [5] : []) + toward
        case 190..<220: return tap ? [8] : []
        default: return []
        }
    }

    /// The keys a player holds at script tick `k` in `context` — a conversation (or sign, hint) is read through and
    /// answered with Return, tapped, as a player does; the script's own keys otherwise.
    static func keys(at k: Int, offset: Offset, context: GameFlow.PadContext, prefs: FerazelPrefs) -> [Int] {
        switch context {
        case .conversation: return (k / 4) % 2 == 0 ? [0x24] : []
        case .playing: return actions(at: k, offset: offset).map { Int(prefs.keys[$0]) }
        default: return []
        }
    }

    // MARK: Failures

    struct Failure: Sendable, CustomStringConvertible {
        let level: Int
        let record: String
        let type: String
        let offset: String
        /// The visit tick (script tick once playing, else "start+n") and the input held.
        let frame: String
        let error: String

        var description: String { [String(level), record, type, offset, frame, error].joined(separator: " | ") }
        var tsv: String {
            [String(level), record, type, offset, frame, error.replacingOccurrences(of: "\t", with: " ")
                .replacingOccurrences(of: "\n", with: " ")].joined(separator: "\t")
        }
    }

    static func failure(_ v: Visit, frame: String, _ error: String) -> Failure {
        Failure(level: v.level, record: String(v.record.index), type: hex(v.record.type), offset: v.offset.rawValue,
                frame: frame, error: error)
    }

    static func table(_ rows: [Failure]) -> String {
        let header = "level | record | type | offset | frame / input | error"
        return ([header, String(repeating: "-", count: header.count)] + rows.map(\.description)).joined(separator: "\n")
    }

    static func hex(_ v: Int16) -> String { "0x" + String(UInt16(bitPattern: v), radix: 16) }

    // MARK: Coverage notes (not failures)

    /// What a visit saw: the teleport arrivals, a level exit through to the world map, the suspensions met.
    struct Seen: Sendable {
        var teleportArrived = false
        var exitReachedMap = false
        var levelCompleted = false
        var suspensions: Set<String> = []
    }

    // MARK: Configuration (the runner script's shards)

    /// `FERAZEL_VISIT_SWEEP=1` runs the sweep; anything else skips it (the normal suites stay as they are).
    static var enabled: Bool { ProcessInfo.processInfo.environment["FERAZEL_VISIT_SWEEP"] == "1" }

    /// `FERAZEL_VISIT_LEVELS=2,3` narrows the levels (default `levels`).
    static var selectedLevels: [Int] {
        guard let s = ProcessInfo.processInfo.environment["FERAZEL_VISIT_LEVELS"], !s.isEmpty else { return levels }
        return s.split(separator: ",").compactMap { Int($0) }.filter(levels.contains)
    }

    /// `FERAZEL_VISIT_SHARD=i/n`: only visits whose index in the level's list ≡ i (mod n).
    static var shard: (index: Int, count: Int) {
        let parts = (ProcessInfo.processInfo.environment["FERAZEL_VISIT_SHARD"] ?? "0/1").split(separator: "/")
        guard parts.count == 2, let i = Int(parts[0]), let n = Int(parts[1]), n > 0, (0..<n).contains(i) else {
            return (0, 1)
        }
        return (i, n)
    }

    /// `FERAZEL_VISIT_LIMIT=n`: at most n visits per level (a quick look; the gate runs them all).
    static var limit: Int { Int(ProcessInfo.processInfo.environment["FERAZEL_VISIT_LIMIT"] ?? "") ?? .max }

    /// `FERAZEL_VISIT_FROM=k`: start at the level list's visit k (the runner resumes after a trap with it).
    static var from: Int { Int(ProcessInfo.processInfo.environment["FERAZEL_VISIT_FROM"] ?? "") ?? 0 }

    /// `FERAZEL_VISIT_OUT=dir`: where the rows (`failures.tsv`), the coverage (`seen.tsv`) and the progress file
    /// (`progress` — the visit about to run, so a trap that kills the process names its visit) are appended.
    static var outDirectory: URL? {
        ProcessInfo.processInfo.environment["FERAZEL_VISIT_OUT"].map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    static func append(_ line: String, to name: String) {
        guard let dir = outDirectory else { return }
        let url = dir.appendingPathComponent(name)
        let data = Data((line + "\n").utf8)
        if let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile()
            h.write(data)
            try? h.close()
        } else {
            try? data.write(to: url)
        }
    }

    /// Marks the visit about to run (overwritten each visit): "level\tindex-in-list\tlabel".
    static func progress(_ v: Visit, index: Int) {
        guard let dir = outDirectory else { return }
        try? Data("\(v.level)\t\(index)\t\(v.label)\t\(v.record.index)\t\(hex(v.record.type))\t\(v.offset.rawValue)\n".utf8)
            .write(to: dir.appendingPathComponent("progress"))
    }
}

// MARK: - The visit, over either shell

/// A booted game the sweep drives one game tick at a time: the Core path's `SweepShell` (FerazelRenderTests) or the
/// Windows `WinGame` behind its scripted host (FerazelWinKitTests). Each answers the modals as its shell does.
protocol SweepGame: AnyObject {
    var flow: GameFlow { get }
    /// One game tick with `keys` held (Mac key codes); throws what the shell would have quit on.
    func tick(keys: [Int]) throws -> FrontOutput
    /// What the shell logged or swallowed since the last call (a renderer `prepare`/`attach` throw, a log line).
    func takeProblems() -> [String]
}

extension VisitSweep {
    /// Boots `game` to the main menu (the flow's boot, its loads answered by the shell); a throw or a timeout is a
    /// failure of every visit, reported once by the caller.
    @MainActor static func toMainMenu(_ game: SweepGame, max: Int = 3000) throws {
        for _ in 0..<max {
            _ = try game.tick(keys: [])
            if game.flow.state == .mainMenu { return }
        }
        throw SweepError("the main menu was not reached in \(max) ticks (state \(game.flow.state))")
    }

    struct SweepError: Error, CustomStringConvertible {
        let description: String
        init(_ s: String) { description = s }
    }

    /// One visit on a game at the main menu: Continue `ref` (the visit's save), wait for the loop, play the script,
    /// then let any modal finish (and a level exit reach the world map). Returns the rows (empty = clean) and what it saw.
    @MainActor static func run(_ v: Visit, game: SweepGame, ref: SavedGameRef) -> ([Failure], Seen) {
        var rows: [Failure] = []
        var seen = Seen()
        var phase = "start"
        var k = 0
        var held: [Int] = []
        var lastSuspension: FrameSuspension?
        let flow = game.flow
        func frame() -> String {
            let keys = held.isEmpty ? "-" : held.map { "0x" + String($0, radix: 16) }.joined(separator: "+")
            return "\(phase)+\(k) keys \(keys)"
        }
        /// One tick; false when the visit must stop (a throw, a quit).
        func step(_ keys: [Int]) -> Bool {
            held = keys
            let out: FrontOutput
            do {
                out = try game.tick(keys: keys)
            } catch {
                rows.append(failure(v, frame: frame(), "\(error)"))
                return false
            }
            for p in game.takeProblems() { rows.append(failure(v, frame: frame(), p)) }
            for r in out.requests {
                switch r {
                case .dialog(.error(let text, let code)):
                    rows.append(failure(v, frame: frame(), "error dialog: \(text) (\(code))"))
                case .dialog(.report(let text)):
                    rows.append(failure(v, frame: frame(), "report dialog: \(text)"))
                case .quit:
                    rows.append(failure(v, frame: frame(), "the game quit"))
                    return false
                default: break
                }
            }
            if let run = flow.levelRun {
                let s = run.session?.suspension
                if let s {
                    seen.suspensions.insert(Self.name(s))
                }
                if case .teleport(_, 2)? = lastSuspension, s == nil { seen.teleportArrived = true }
                lastSuspension = s
                if case .completed? = run.end { seen.levelCompleted = true }
            }
            if seen.levelCompleted, let m = flow.worldMap, m.iterations >= 2, m.result == nil { seen.exitReachedMap = true }
            if flow.state == .quit {
                rows.append(failure(v, frame: frame(), "the flow quit"))
                return false
            }
            return true
        }

        flow.openDocument(ref)
        // To the loop: `.ContinueGame` reads the save, `LevelRun` sets the level up (popup, load bars, fades).
        while !(flow.padContext == .playing) {
            guard step([]) else { return (rows, seen) }
            k += 1
            if !rows.isEmpty { return (rows, seen) }
            if k > 2000 {
                rows.append(failure(v, frame: frame(), "the level never started (state \(flow.state), context \(flow.padContext))"))
                return (rows, seen)
            }
        }
        // The script.
        phase = "play"
        k = 0
        let prefs = flow.levelRun?.prefs ?? FerazelPrefs()
        while k < playTicks {
            guard step(keys(at: k, offset: v.offset, context: flow.padContext, prefs: prefs)) else { return (rows, seen) }
            k += 1
            if seen.exitReachedMap { break }
        }
        // The drain: hands off; a conversation still read through; a level exit on to the map.
        phase = "drain"
        k = 0
        func settled() -> Bool {
            if seen.levelCompleted { return seen.exitReachedMap }
            if flow.padContext == .deathScreen { return true }
            guard let run = flow.levelRun else { return true }
            if run.end != nil { return false }
            return flow.padContext == .playing && run.session?.suspension == nil && run.upgrade == nil
                && run.mosaic == nil
        }
        while !settled() {
            guard k < drainTicks else {
                let s = flow.levelRun?.session?.suspension.map(Self.name) ?? "none"
                rows.append(failure(v, frame: frame(),
                                    "stuck: suspension \(s), context \(flow.padContext), state \(flow.state)"))
                break
            }
            guard step(keys(at: k, offset: .on, context: flow.padContext, prefs: prefs).filter { $0 == 0x24 }) else { break }
            k += 1
        }
        return (rows, seen)
    }

    static func name(_ s: FrameSuspension) -> String {
        switch s {
        case .savePoint: "savePoint"
        case .conversation: "conversation"
        case .sign: "sign"
        case .gameLoopKeys(let e): "gameLoopKeys(\(e))"
        case .upgrade: "upgrade"
        case .hint: "hint"
        case .teleport(_, let stage): "teleport\(stage)"
        }
    }
}

import FerazelCore
import Foundation

// The random-play bot (Phase 5 task RB, D44; Ben's "yes" to Q15 item 5): the shared half — the input generator, the
// play loop over a `SweepGame` (VisitSweepPlan.swift), the scope, the failure rows and the counts. Foundation +
// FerazelCore only, and no XCTestCase here: compiled by FerazelRenderTests (the Core path, `RandomPlayTests`) and,
// through a git symlink, by FerazelWinKitTests (the Windows shell path, `WinRandomPlayTests`). Runner:
// tools/ferazel-random-play.sh (its header says how the loop runs it at every phase end).
//
// One run: a booted game; New Game at the level (the hidden `FerazelLevel` switch, `GameFlow.startLevel`); then
// `FERAZEL_BOT_MINUTES` of steps (a step = two game ticks, the 30-a-second cap's one loop iteration, keys held across
// both). In play the keys are the generator's; every other context is answered as a player and the shells answer it:
// a conversation read through and left by its last answer, the death screen's Continue (Return), the main menu's
// New Game, the world map walked back to the level's node and entered again, the pause left when Caps Lock comes up,
// dialogs as the shells answer them (OK; Cancel for a confirm and Options; a file for a save point's panel).
// Any render refusal, thrown error, error/report dialog, quit, stuck modal (600 ticks with nothing moving) or trap
// (the process dies — the runner records the run and step from the progress file) is a failure row.

/// The bot's input stream: its own seeded generator (SplitMix64) — never the game's `FastRand`. A step's input in play:
/// a held direction (runs of 5–60 steps, sometimes with Run held), and one program at a time — jump or use taps and
/// holds, item stepping (actions 7 / 8), mashing bursts, now and then Esc, ⌘P or the Caps Lock latch. Outside play
/// nothing is pressed (the play loop answers those contexts) but the Caps Lock latch, which runs out on its own.
struct RandomPlayGenerator {
    /// One step's input: prefs action indices (0 left, 1 right, 2 up, 3 down, 4 run, 5 jump, 6 use/cast — ⌘ by default,
    /// 7 previous item, 8 next item), raw keys (0x35 Esc, 0x23 P — with action 6's ⌘ it is ⌘P), the Caps Lock lock.
    struct Input: Equatable, Sendable, CustomStringConvertible {
        var actions: [Int] = []
        var keys: [Int] = []
        var capsLock = false

        var description: String {
            let a = actions.isEmpty ? "-" : actions.map(String.init).joined(separator: ",")
            let k = keys.isEmpty ? "-" : keys.map { "0x" + String($0, radix: 16) }.joined(separator: ",")
            return "a \(a) k \(k)" + (capsLock ? " caps" : "")
        }
    }

    private var state: UInt64
    private var direction: [Int] = []
    private var directionLeft = 0
    private var running = false
    /// The program running: one (actions, keys) per step, consumed in order.
    private var program: [(actions: [Int], keys: [Int])] = []
    private var capsLeft = 0

    init(seed: UInt64) {
        state = seed
    }

    /// SplitMix64.
    private mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    /// 0..<n.
    private mutating func int(_ n: Int) -> Int { Int(next() % UInt64(n)) }

    private mutating func int(_ r: ClosedRange<Int>) -> Int { r.lowerBound + int(r.count) }

    /// The directions (left, right, up, down and the diagonals) and their weights out of 100.
    private static let directions: [(dir: [Int], weight: Int)] = [
        ([], 10), ([0], 25), ([1], 30), ([2], 8), ([3], 7), ([0, 2], 5), ([1, 2], 5), ([0, 3], 5), ([1, 3], 5),
    ]

    mutating func step(context: GameFlow.PadContext) -> Input {
        let caps = capsLeft > 0
        if capsLeft > 0 { capsLeft -= 1 }
        guard context == .playing else { return Input(capsLock: caps) }
        if directionLeft == 0 {
            var r = int(100)
            for d in Self.directions {
                if r < d.weight { direction = d.dir; break }
                r -= d.weight
            }
            directionLeft = int(5...60)
            running = int(10) < 4
        }
        directionLeft -= 1
        if program.isEmpty { start() }
        let now = program.isEmpty ? (actions: [Int](), keys: [Int]()) : program.removeFirst()
        var actions = direction + now.actions
        if running { actions.append(4) }
        return Input(actions: Array(Set(actions)).sorted(), keys: now.keys, capsLock: caps)
    }

    /// Maybe starts a program (most steps start none).
    private mutating func start() {
        func taps(_ action: Int) -> [(actions: [Int], keys: [Int])] {
            var p: [(actions: [Int], keys: [Int])] = []
            for _ in 0..<int(1...3) {
                p += Array(repeating: ([action], []), count: int(1...3))
                p += Array(repeating: ([], []), count: int(2...8))
            }
            return p
        }
        let r = int(1000)
        switch r {
        case 0..<50: program = taps(5)                                                       // jump taps
        case 50..<75: program = Array(repeating: ([5], []), count: int(8...40))              // jump held
        case 75..<110: program = taps(6)                                                     // use / cast taps
        case 110..<125: program = Array(repeating: ([6], []), count: int(10...60))           // use / cast held
        case 125..<140: program = taps(7 + int(2))                                           // item stepping
        case 140..<150:                                                                      // mashing
            program = (0..<int(10...40)).map { _ in ([4, 5, 6, 7, 8].filter { _ in int(2) == 0 }, []) }
        case 150..<152: program = Array(repeating: ([], [0x35]), count: 2) + Array(repeating: ([], []), count: 4)
        case 152..<154: program = Array(repeating: ([6], [0x23]), count: 3) + Array(repeating: ([], []), count: 4)
        case 154..<156: capsLeft = int(10...60)                                              // the pause latch
        default: break
        }
    }
}

enum RandomPlay {
    /// The playable scope (the visit sweep's): `BuiltLevels.range`.
    static let levels: [Int] = Array(BuiltLevels.range)
    /// Two game ticks a step: 30 steps a second.
    static let ticksPerStep = 2
    static let stepsPerMinute = 1800
    /// Ticks with nothing moving that count as stuck (the visit sweep's).
    static let stuckTicks = VisitSweep.stuckTicks
    /// Ticks on the world map with no way back to the level before it is a failure.
    static let mapTicks = 3000

    private static var env: [String: String] { ProcessInfo.processInfo.environment }

    /// `FERAZEL_BOT=1` runs the bot; anything else skips it.
    static var enabled: Bool { env["FERAZEL_BOT"] == "1" }
    /// `FERAZEL_BOT_SEEDS` (default 4).
    static var seeds: Int { max(Int(env["FERAZEL_BOT_SEEDS"] ?? "") ?? 4, 1) }
    /// `FERAZEL_BOT_MINUTES` (default 3 = 5,400 steps).
    static var minutes: Int { max(Int(env["FERAZEL_BOT_MINUTES"] ?? "") ?? 3, 1) }
    static var steps: Int { minutes * stepsPerMinute }
    /// `FERAZEL_BOT_LEVELS=2,3` narrows the levels (default `levels`).
    static var selectedLevels: [Int] {
        guard let s = env["FERAZEL_BOT_LEVELS"], !s.isEmpty else { return levels }
        return s.split(separator: ",").compactMap { Int($0) }.filter(levels.contains)
    }

    /// One run: a level, a seed (1-based).
    struct Run: Sendable {
        let level: Int
        let seed: Int
        /// The generator's seed: the level and the seed together, so every run has its own stream.
        var generatorSeed: UInt64 { UInt64(level) << 32 | UInt64(seed) }
    }

    /// Every run, levels outer, seeds inner — the runner's indices.
    static func runs() -> [Run] {
        selectedLevels.flatMap { l in (1...seeds).map { Run(level: l, seed: $0) } }
    }

    /// `FERAZEL_BOT_SHARD=i/n`: only runs whose index ≡ i (mod n).
    static var shard: (index: Int, count: Int) {
        let parts = (env["FERAZEL_BOT_SHARD"] ?? "0/1").split(separator: "/")
        guard parts.count == 2, let i = Int(parts[0]), let n = Int(parts[1]), n > 0, (0..<n).contains(i) else {
            return (0, 1)
        }
        return (i, n)
    }

    /// `FERAZEL_BOT_FROM=k`: skip the runs before index k (the runner resumes after a trap with it).
    static var from: Int { Int(env["FERAZEL_BOT_FROM"] ?? "") ?? 0 }

    static func mine(index i: Int) -> Bool { i >= from && i % shard.count == shard.index }

    // MARK: Files (the runner's)

    /// `FERAZEL_BOT_OUT=dir`: where the rows (`failures.tsv`), the run counts (`runs.tsv`) and the progress file
    /// (`progress` — the run and step, so a trap that kills the process names them) are written.
    static var outDirectory: URL? { env["FERAZEL_BOT_OUT"].map { URL(fileURLWithPath: $0, isDirectory: true) } }

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

    /// "index\tlevel\tseed\tstep" (overwritten as the run goes).
    static func progress(_ run: Run, index: Int, step: Int) {
        guard let dir = outDirectory else { return }
        try? Data("\(index)\t\(run.level)\t\(run.seed)\t\(step)\n".utf8).write(to: dir.appendingPathComponent("progress"))
    }

    // MARK: Rows and counts

    struct Failure: Sendable, CustomStringConvertible {
        let level: Int
        let seed: Int
        /// The step, the context and the keys held.
        let frame: String
        let error: String

        var description: String { [String(level), String(seed), frame, error].joined(separator: " | ") }
        var tsv: String { [String(level), String(seed), frame, RandomPlay.oneLine(error)].joined(separator: "\t") }
    }

    /// Tabs and newlines as spaces (plain Swift: no Foundation string calls in the Wine-run test targets).
    static func oneLine(_ s: String) -> String {
        String(s.map { $0 == "\t" || $0 == "\n" || $0 == "\r" ? " " : $0 })
    }

    static func table(_ rows: [Failure]) -> String {
        let header = "level | seed | step / context / keys | error"
        return ([header, String(repeating: "-", count: header.count)] + rows.map(\.description)).joined(separator: "\n")
    }

    struct Stats: Sendable {
        var steps = 0
        var deaths = 0
        var exits = 0
        var conversations = 0
        var saves = 0

        mutating func add(_ o: Stats) {
            steps += o.steps
            deaths += o.deaths
            exits += o.exits
            conversations += o.conversations
            saves += o.saves
        }

        /// "level\tseed\tsteps\tdeaths\texits\tconversations\tsaves".
        func tsv(_ run: Run) -> String {
            [run.level, run.seed, steps, deaths, exits, conversations, saves].map(String.init).joined(separator: "\t")
        }

        func summary(levels: Int, seeds: Int) -> String {
            "levels \(levels), seeds \(seeds), steps \(steps), deaths \(deaths), exits \(exits), "
                + "conversations \(conversations), saves \(saves)"
        }
    }
}

// MARK: - The run, over either shell

/// A `SweepGame` whose Caps Lock the bot sets (the lock state the next ticks poll).
protocol BotGame: SweepGame {
    var capsLock: Bool { get set }
}

extension RandomPlay {
    /// One run on a freshly made game (not booted): to the main menu, New Game at `run.level` (the flow's
    /// `startLevel` is the caller's), then `steps` steps. Returns the rows (empty = clean; the run stops at the first)
    /// and the counts.
    @MainActor static func play(_ run: Run, index: Int, game: BotGame, steps: Int = RandomPlay.steps)
        -> ([Failure], Stats) {
        var rows: [Failure] = []
        var stats = Stats()
        var gen = RandomPlayGenerator(seed: run.generatorSeed)
        let flow = game.flow
        var step = 0
        var held: [Int] = []
        var context = GameFlow.PadContext.other
        func frame() -> String {
            let keys = held.isEmpty ? "-" : held.map { "0x" + String($0, radix: 16) }.joined(separator: "+")
            return "step \(step) \(context) keys \(keys)" + (game.capsLock ? " caps" : "")
        }
        do {
            try VisitSweep.toMainMenu(game)
        } catch {
            return ([Failure(level: run.level, seed: run.seed, frame: "boot", error: "\(error)")], stats)
        }

        // What the counts follow: the level run (its end read once it is gone or ended), the conversation, the map.
        var lastRun: LevelRun?
        var lastRunCounted = false
        var lastConversation: ObjectIdentifier?
        var conversationTick = 0
        var onMap = 0
        func count(_ r: LevelRun?) {
            guard let r, !lastRunCounted, let end = r.end else { return }
            lastRunCounted = true
            switch end {
            case .died: stats.deaths += 1
            case .completed: stats.exits += 1
            default: break
            }
        }

        // The watchdog (the visit sweep's): unchanged for `stuckTicks` ticks = stuck.
        var lastMark = ""
        var still = 0
        func mark() -> String {
            let r = flow.levelRun
            let c = r?.conversation.map { "\(ObjectIdentifier($0).hashValue)/\($0.wait)/\($0.shown.count)/\($0.index)" }
            return "\(flow.state)|\(r?.iterations ?? -1)|\(String(describing: c))|\(r?.mosaic != nil)|"
                + "\(r?.upgrade != nil)|\(flow.worldMap?.iterations ?? -1)|\(flow.padContext)|\(flow.deathScreen != nil)"
        }

        /// The keys this tick in `context` (`input` = the generator's for the step).
        func keys(_ input: RandomPlayGenerator.Input, tick: Int) -> [Int] {
            let prefs = flow.levelRun?.prefs ?? FerazelPrefs()
            switch context {
            case .playing:
                return input.actions.map { Int(prefs.keys[$0]) } + input.keys
            case .conversation:
                return VisitSweep.keys(at: conversationTick, offset: .on, context: .conversation, prefs: prefs)
            case .deathScreen:
                return (tick / 4) % 2 == 0 ? [0x24] : []                                    // Continue
            case .mainMenu:
                return [MainMenu.newGameKey]                                                 // New Game
            case .map:
                guard let m = flow.worldMap else { return [] }
                return mapKeys(m, level: run.level)
            case .other:
                // A level not yet looping: the chapter card waits up to 1,200 ticks for any key — a player taps one
                // (Space: no action, no shortcut). Elsewhere (the boot, the stage screens) hands off.
                if let r = flow.levelRun, r.end == nil, r.iterations == 0 { return (tick / 4) % 2 == 0 ? [0x31] : [] }
                return []
            case .paused:
                return []
            }
        }

        /// One tick; false when the run must stop (a row, a quit, stuck).
        var tick = 0
        func tickOnce(_ input: RandomPlayGenerator.Input) -> Bool {
            context = flow.padContext
            if let c = flow.levelRun?.conversation.map(ObjectIdentifier.init) {
                if c != lastConversation {
                    lastConversation = c
                    conversationTick = 0
                    stats.conversations += 1
                } else {
                    conversationTick += 1
                }
            } else {
                lastConversation = nil
            }
            held = keys(input, tick: tick)
            game.capsLock = input.capsLock
            tick += 1
            let out: FrontOutput
            do {
                out = try game.tick(keys: held)
            } catch {
                rows.append(Failure(level: run.level, seed: run.seed, frame: frame(), error: "\(error)"))
                return false
            }
            for p in game.takeProblems() {
                rows.append(Failure(level: run.level, seed: run.seed, frame: frame(), error: p))
            }
            for r in out.requests {
                switch r {
                case .dialog(.error(let text, let code)):
                    rows.append(Failure(level: run.level, seed: run.seed, frame: frame(),
                                        error: "error dialog: \(text) (\(code))"))
                case .dialog(.report(let text)):
                    rows.append(Failure(level: run.level, seed: run.seed, frame: frame(), error: "report dialog: \(text)"))
                case .quit:
                    rows.append(Failure(level: run.level, seed: run.seed, frame: frame(), error: "the game quit"))
                case .putFile:
                    stats.saves += 1
                default: break
                }
            }
            if flow.state == .quit {
                rows.append(Failure(level: run.level, seed: run.seed, frame: frame(), error: "the flow quit"))
            }
            // The counts: a level run's end, once.
            if flow.levelRun !== lastRun {
                count(lastRun)
                lastRun = flow.levelRun
                lastRunCounted = false
            }
            count(lastRun)
            // The map: walked back to the level's node; no way back for `mapTicks` is a row.
            if flow.worldMap != nil { onMap += 1 } else { onMap = 0 }
            if onMap > mapTicks {
                let m = flow.worldMap
                rows.append(Failure(level: run.level, seed: run.seed, frame: frame(),
                                    error: "the map: no way back to level \(run.level) in \(mapTicks) ticks (on the "
                                        + "node of level \(m.flatMap { $0.map.node($0.cur)?.level } ?? -1))"))
            }
            let mk = mark()
            if mk == lastMark { still += 1 } else { still = 0; lastMark = mk }
            if still >= stuckTicks {
                let s = flow.levelRun?.session?.suspension.map(VisitSweep.name) ?? "none"
                var levelRun = "none"
                if let r = flow.levelRun {
                    levelRun = "end \(String(describing: r.end)) iterations \(r.iterations) loop ended "
                        + "\(r.session?.loopEnded ?? false)"
                }
                rows.append(Failure(level: run.level, seed: run.seed, frame: frame(),
                                    error: "stuck \(stuckTicks) ticks: suspension \(s), context \(flow.padContext), "
                                        + "state \(flow.state), level run \(levelRun), options \(flow.prefsDialog != nil), "
                                        + "map \(flow.worldMap != nil), death screen \(flow.deathScreen != nil)"))
            }
            return rows.isEmpty
        }

        while step < steps {
            let input = gen.step(context: flow.padContext)
            for _ in 0..<ticksPerStep {
                guard tickOnce(input) else {
                    stats.steps = step
                    return (rows, stats)
                }
            }
            step += 1
            if step % 30 == 0 { progress(run, index: index, step: step) }
        }
        stats.steps = step
        count(lastRun)
        return (rows, stats)
    }

    /// The world map: walk back to the node of `level` (a breadth-first search over the moves the held arrows make,
    /// `WorldMapRun.checkPlayerNodeMovement`), then Return. Nothing while the map walks or before its loop runs.
    static func mapKeys(_ m: WorldMapRun, level: Int) -> [Int] {
        guard m.result == nil, m.pause == nil, m.iterations >= 1, m.walkStep == 0 else { return [] }
        if m.map.node(m.cur)?.level == Int16(level) { return [0x24] }
        let arrows = [0x7b, 0x7c, 0x7e, 0x7d]
        func moves(_ node: Int) -> [(key: Int, to: Int)] {
            arrows.compactMap { k in
                let t = WorldMapRun.checkPlayerNodeMovement(map: m.map, node: node, globals: m.globals,
                                                            keys: KeyState(pressed: [k]), prefs: m.prefs)
                return t == 0 ? nil : (k, Int(t))
            }
        }
        var first: [Int: Int] = [:]      // node → the first key on the way there
        var queue: [Int] = []
        for mv in moves(m.cur) where first[mv.to] == nil && mv.to != m.cur {
            first[mv.to] = mv.key
            queue.append(mv.to)
        }
        var i = 0
        while i < queue.count {
            let n = queue[i]
            i += 1
            if m.map.node(n)?.level == Int16(level), let k = first[n] { return [k] }
            for mv in moves(n) where first[mv.to] == nil && mv.to != m.cur {
                first[mv.to] = first[n]
                queue.append(mv.to)
            }
        }
        return []
    }
}

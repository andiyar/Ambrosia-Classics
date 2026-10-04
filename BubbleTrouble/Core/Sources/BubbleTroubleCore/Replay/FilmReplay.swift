// The FILM replay harness (plan §Task 11.1; Invariant 14; FILM-oracle paragraph (b); G2, G4): one demo game per FILM,
// driven frame by frame through `GameState.stepFrame` until `_PlayGame @ 00018247`'s loop-top `gPlayGame == 0` exit.
//
// Start-up (replay-oracle.md §2–§3): `PlayGame(level = id, mode 1)` — the level is the FILM's resource id, NOT the
// FILM's level field (unused, NR-1); `SetQDGlobalsRandomSeed(FILM.seed)` installs the seed the first `Random()` uses.
// The demo stops at the top of the next loop iteration after any of: hero state-4 timeout, level complete + 70,
// `FILM.count <= gRecordingCounter` (Invariant 14) — all recorded by `stepFrame` in `FrameReport.stops`.
//
// The bar is behavioural self-consistency, not equality with the original: the bank derives no FILM end state
// (replay-oracle.md §6). Phrase results as "the core replays FILM n to count exhaustion", never "matches the original".

/// One FILM's replay outcome (plan §Task 11.1).
public struct FilmReplayResult: Equatable, Sendable {
    public let filmID: Int, level: Int, count: Int, frames: Int, samplesConsumed: Int, totalDraws: Int
    public let score: Int32, lives: Int16, stops: Set<StopReason>, firstCatchFrame: Int?
    /// `gEndOfLevelTime` if `gIsEndOfLevel` was set when the demo stopped (plan review A10) — whether or not its +70
    /// stop had fired.
    public let levelCompletedFrame: Int?
    /// One report per frame, filled when tracing.
    public let reports: [FrameReport]?

    public init(filmID: Int, level: Int, count: Int, frames: Int, samplesConsumed: Int, totalDraws: Int,
                score: Int32, lives: Int16, stops: Set<StopReason>, firstCatchFrame: Int?,
                levelCompletedFrame: Int?, reports: [FrameReport]?) {
        self.filmID = filmID; self.level = level; self.count = count; self.frames = frames
        self.samplesConsumed = samplesConsumed; self.totalDraws = totalDraws; self.score = score; self.lives = lives
        self.stops = stops; self.firstCatchFrame = firstCatchFrame; self.levelCompletedFrame = levelCompletedFrame
        self.reports = reports
    }

    /// Invariant 14 + brief bar (b): the FILM count ran out with every sample consumed, the hero was not caught before
    /// the final frame (a catch ON the final frame is reported, not failed), and the original did not abort.
    public var accepted: Bool {
        stops.contains(.countExhausted) && samplesConsumed == count
            && (firstCatchFrame == nil || firstCatchFrame == frames)
            && !stops.contains(where: { if case .originalWouldAbort = $0 { true } else { false } })
    }

    /// Orchestrator ruling R2: accepted, and the level completed at all — necessarily within the final 70 frames,
    /// since a `.levelCompleted` stop before the count ran out would have ended the demo first. Still counts toward
    /// `ACCEPT n/4`.
    public var flagged: Bool {
        accepted && levelCompletedFrame != nil
    }

    /// The end reasons, comma-separated in fixed order: `count`, `death`, `gameover`, `level`, `abort:<msg>`.
    /// `level` is printed whenever the level completed (`levelCompletedFrame != nil`), even if its +70 stop had not
    /// fired. `max-frames` when no stop fired before the harness's frame cap.
    public var end: String {
        var parts: [String] = []
        if stops.contains(.countExhausted) { parts.append("count") }
        if stops.contains(.heroDeathAnimationDone) { parts.append("death") }
        if stops.contains(.gameOverNoLives) { parts.append("gameover") }
        if stops.contains(.levelCompleted) || levelCompletedFrame != nil { parts.append("level") }
        for case .originalWouldAbort(let message) in stops.sorted(by: { "\($0)" < "\($1)" }) {
            parts.append("abort:\(message)")
        }
        return parts.isEmpty ? "max-frames" : parts.joined(separator: ",")
    }

    /// The table header (plan §Task 11.1 output format); `row` pads to the same columns.
    public static let header = Self.format(["film", "level", "count", "frames", "samples", "draws", "score", "lives",
                                            "end", "first-catch"])

    /// One table row; a flagged row ends with ` FLAG`.
    public var row: String {
        let cells = ["\(filmID)", "\(level)", "\(count)", "\(frames)", "\(samplesConsumed)", "\(totalDraws)",
                     "\(score)", "\(lives)", end, firstCatchFrame.map { "\($0)" } ?? "-"]
        return Self.format(cells) + (flagged ? " FLAG" : "")
    }

    /// `FLAGGED: film <n> level completed at frame <E>, count exhausted at frame <F>` for a flagged FILM (the
    /// orchestrator's gate message to Ben), else nil.
    public var flagLine: String? {
        guard flagged, let completed = levelCompletedFrame else { return nil }
        return "FLAGGED: film \(filmID) level completed at frame \(completed), count exhausted at frame \(frames)"
    }

    private static let widths = [6, 7, 7, 8, 9, 7, 7, 7, 20]

    private static func format(_ cells: [String]) -> String {
        var line = ""
        for (i, cell) in cells.enumerated() {
            if i < widths.count {
                let padding = max(1, widths[i] - cell.count)
                line += cell + String(repeating: " ", count: padding)
            } else {
                line += cell
            }
        }
        return line
    }
}

/// Runs one FILM through the frame step (plan §Task 11.1).
public enum FilmReplay {
    /// Replays FILM `filmID` at level `filmID` (replay-oracle.md §2) with `FILM.seed`, until the demo stops or
    /// `maxFrames` frames ran (hitting the cap is never accepted). `trace` fills `reports`.
    public static func run(filmID: Int, files: BTXResourceFiles, config: SessionConfig = SessionConfig(),
                           trace: Bool = false, maxFrames: Int = 65_535) throws -> FilmReplayResult {
        try run(filmID: filmID, files: files, config: config, trace: trace, maxFrames: maxFrames,
                observe: { _, _ in })
    }

    /// `run` with a per-frame observer (the frame's report and the state after it) — `btx-replay --trace` reads
    /// fields the report does not carry (`gNumEnemiesActive`).
    public static func run(filmID: Int, files: BTXResourceFiles, config: SessionConfig = SessionConfig(),
                           trace: Bool = false, maxFrames: Int = 65_535,
                           observe: (FrameReport, GameState) -> Void) throws -> FilmReplayResult {
        let film = try files.film(filmID)
        var state = try GameState.newGame(level: filmID, mode: .demo, seed: film.seed, files: files, config: config)
        var input = FilmInput(film: film)
        var reports: [FrameReport] = []
        var frames = 0
        var firstCatchFrame: Int?
        while state.playing && frames < maxFrames {
            let report = state.stepFrame(input: &input)
            frames += 1
            if report.heroCaughtThisFrame && firstCatchFrame == nil {
                firstCatchFrame = Int(report.frame)
            }
            // Invariant 14: `.levelCompleted` (like every stop) is recorded only on the frame that ends the demo.
            precondition(!report.stops.contains(.levelCompleted) || !state.playing,
                         "FILM \(filmID): .levelCompleted on frame \(report.frame) but the demo kept playing")
            if trace { reports.append(report) }
            observe(report, state)
        }
        return FilmReplayResult(
            filmID: filmID, level: filmID, count: film.count, frames: Int(state.frame),
            samplesConsumed: input.samplesConsumed, totalDraws: state.rng.drawCount, score: state.score,
            lives: state.lives, stops: state.pendingStops, firstCatchFrame: firstCatchFrame,
            levelCompletedFrame: state.isEndOfLevel ? Int(state.endOfLevelTime) : nil,
            reports: trace ? reports : nil)
    }

    /// One `--trace` line: `frame=<n> draws=<this> total=<n> sample=<consumed> hero=<state>@<col>,<row> score=<n>
    /// enemies=<active>` (plan §Task 11.1).
    public static func traceLine(_ report: FrameReport, enemiesActive: Int8) -> String {
        "frame=\(report.frame) draws=\(report.drawsThisFrame) total=\(report.totalDraws) "
            + "sample=\(report.samplesConsumed) hero=\(report.heroState)@\(report.heroCell.col),\(report.heroCell.row) "
            + "score=\(report.score) enemies=\(enemiesActive)"
    }
}

import Foundation
import DeimosCore
import DeimosRender
import DeimosHost

/// `deimos-replay <film tag>… [--trace file.csv] [--frames dir --every N] [--all]` (plan H3; the replay gate G4).
///
/// Replays each shipped demo film through `HeadlessRunner` (seed, sector and players from the film; logic only unless
/// `--frames`) and prints, per film, the triage numbers of plan G4 step 3 and then the G4 line
/// `<tag> <level> seed 0x<seed>: score <n> at read <frames> (end: <reason>) PASS|FAIL`. "Read N" is the N-th film
/// read, the one that consumes byte N − 1 (cursor N − 1 → N): "score at read 4809" is
/// `FilmCursor.score(player: 0, atRead: 4808)`, the instant the recorder stored the film's score (G4.1). Every film
/// is asserted (H3 fix round ruling): PASS when the replica's score there equals the film's stored score and the
/// session really ended (an end at the pass bound is FAIL). Data: the committed `Resources/Deimos/Data`, or
/// `DEIMOS_DATA`. Exit 0 iff every film named ran and passed and every requested trace was written; 1 otherwise
/// (a film that cannot be found or replayed counts as failed); 2 on bad usage.
///
/// `--trace file.csv` writes the per-tick `ReplayTrace` CSV (with several films, `file-<tag>.csv`) after the film's
/// lines are printed, so a failed write (reported on stderr) never hides the G4 line. `--frames dir`
/// renders and writes every N-th pass's window (`--every N`, default 60) as binary PPM `dir/<tag>-<pass>.ppm`
/// (Foundation only — no image frameworks below the app, plan G7).
enum DeimosReplay {
    static let allFilms = ["de01", "de02", "de03", "de04"]
    /// The pass bound for every replay (the longest shipped film is well under it).
    static let maxPasses = 20_000
    static let usage = "usage: deimos-replay <film tag>... [--trace file.csv] [--frames dir --every N] [--all]"

    struct UsageError: Error, CustomStringConvertible {
        let description: String
    }

    /// The command line.
    struct Options: Equatable {
        var films: [String] = []
        var trace: String?
        var frames: String?
        var every = 60

        init(arguments: [String]) throws {
            var all = false
            var i = 0
            func value(_ flag: String) throws -> String {
                guard i + 1 < arguments.count else { throw UsageError(description: "\(flag) needs a value") }
                i += 1
                return arguments[i]
            }
            while i < arguments.count {
                let a = arguments[i]
                switch a {
                case "--all": all = true
                case "--trace": trace = try value(a)
                case "--frames": frames = try value(a)
                case "--every":
                    let v = try value(a)
                    guard let n = Int(v), n > 0 else { throw UsageError(description: "--every needs a count > 0, not \(v)") }
                    every = n
                default:
                    guard !a.hasPrefix("-") else { throw UsageError(description: "unknown option \(a)") }
                    films.append(a)
                }
                i += 1
            }
            if all { films = Self.merge(DeimosReplay.allFilms, films) }
            guard !films.isEmpty else { throw UsageError(description: "no film named") }
        }

        private static func merge(_ a: [String], _ b: [String]) -> [String] {
            var out = a
            for t in b where !out.contains(t) { out.append(t) }
            return out
        }
    }

    /// One P1 death: the game time `killPlayer` ran (`stateEntered` of life state 3) and what caused it — `hit`
    /// (the shield went below 0, `FUN_10027100` `100271bc..100271dc`) or `overload` (`FUN_10026ee0` `1002705c`).
    struct Death {
        var tick: Int32
        var cause: String
    }

    /// Everything one film's replay produced.
    struct Report {
        var tag: String
        var film: Film
        var result = ReplayResult(endReason: .bound, cursor: -1, scoreAtRead4808: nil, endScore: 0, passes: 0)
        var endGameTime: Int32 = 0
        /// P1's decoded score at every read (index = consumed byte).
        var readScores: [Int32] = []
        var deaths: [Death] = []
        /// Game time at which G+0x39 (level ending) first rose.
        var levelEndAt: Int32?
        /// G+0x160 once the accuracy tally has run (`1000735c`).
        var accuracy: Int32?
        var groundCreated: Int32 = 0
        var groundDestroyed: Int32 = 0
        /// P1's coin tally start: the game time and the money it started from (player +0x1ec).
        var coinTally: (gameTime: Int32, money: Int32)?
        /// P1's multiplier at the start and at every change.
        var multipliers: [(gameTime: Int32, value: UInt8)] = []
        var framesWritten = 0

        /// The score at the N-th read (byte N − 1), nil if that read never happened.
        func score(atRead n: Int) -> Int32? {
            n >= 1 && n <= readScores.count ? readScores[n - 1] : nil
        }
        /// The score at the read of the last recorded byte — the instant the recorder stored the film's score.
        var scoreAtLastRead: Int32? { score(atRead: film.players[0].frames) }
    }

    /// Replay `film` to its end (or `maxPasses`), one pass at a time, watching P1 between passes.
    static func replay(tag: String, film: Film, assets: DeimosAssets,
                       frames: (dir: URL, every: Int)? = nil) throws -> Report {
        var runner = try HeadlessRunner(assets: assets, film: film, render: frames != nil)
        runner.trace = ReplayTrace()
        var r = Report(tag: tag, film: film)
        r.multipliers = [(runner.session.gameTime, runner.session.players[0].multiplier)]
        if let frames { try FileManager.default.createDirectory(at: frames.dir, withIntermediateDirectories: true) }
        while runner.ended == nil && runner.passes < maxPasses {
            let lifeBefore = runner.session.players[0].lifeState
            let endingBefore = runner.session.game.flags.levelEnding
            let coinBefore = runner.session.game.tally.coin[0].state
            _ = runner.run(maxPasses: runner.passes + 1)
            let s = runner.session
            let p = s.players[0]
            if lifeBefore == 4 && p.lifeState == 3 {
                r.deaths.append(Death(tick: p.stateEntered, cause: deathCause(p)))
            }
            if p.multiplier != r.multipliers.last?.value { r.multipliers.append((s.gameTime, p.multiplier)) }
            if s.game.flags.levelEnding && !endingBefore && r.levelEndAt == nil {
                r.levelEndAt = s.gameTime
            }
            if coinBefore == 0 && s.game.tally.coin[0].state != 0 && r.coinTally == nil {
                r.coinTally = (s.gameTime, s.game.tally.coin[0].moneyAtStart)
            }
            if s.game.tally.state != 0 { r.accuracy = s.game.tally.percent }
            if let frames, runner.passes % frames.every == 0, let screen = runner.screen {
                let name = "\(tag)-" + String(repeating: "0", count: max(0, 5 - String(runner.passes).count))
                    + "\(runner.passes).ppm"
                try ppm(screen).write(to: frames.dir.appendingPathComponent(name), options: .atomic)
                r.framesWritten += 1
            }
        }
        let s = runner.session
        r.result = runner.result
        r.endGameTime = s.gameTime
        r.readScores = s.game.film?.readScores[0] ?? []
        r.groundCreated = s.game.flags.groundCreated
        r.groundDestroyed = s.game.flags.groundDestroyed
        return r
    }

    static func deathCause(_ p: Player) -> String {
        if p.shield < 0 { return "hit, shield \(p.shield)" }
        if p.overloadActive && p.overloadCount == p.definition.powerupOverloadNumWarnings { return "overload" }
        return "unknown"
    }

    /// The reads reported: every 1,000th below the recording's length, then the last recorded byte's.
    static func reportedReads(frames: Int) -> [Int] {
        Array(stride(from: 1000, to: frames, by: 1000)) + [frames]
    }

    /// The per-film lines: the triage numbers (G4 step 3), the end score and trace hash, then the G4 line last.
    static func lines(_ r: Report, traceNote: String? = nil) -> [String] {
        let t = r.tag
        var out: [String] = []
        out.append("\(t) end: \(r.result.endReason) after \(r.result.passes) passes, game time \(r.endGameTime)")
        out.append("\(t) cursor at session end: \(r.result.cursor) (recording \(r.film.players[0].frames) bytes)")
        out.append("\(t) P1 deaths: " + (r.deaths.isEmpty ? "none"
            : r.deaths.map { "tick \($0.tick) (\($0.cause))" }.joined(separator: "; ")))
        out.append("\(t) P1 score at reads: " + reportedReads(frames: r.film.players[0].frames)
            .map { "\($0) = " + (r.score(atRead: $0).map(String.init) ?? "none") }.joined(separator: ", "))
        out.append("\(t) level end at game time: " + (r.levelEndAt.map(String.init) ?? "none"))
        out.append("\(t) accuracy: " + (r.accuracy.map { "\($0)%" } ?? "none")
            + " (ground destroyed \(r.groundDestroyed) of \(r.groundCreated))")
        out.append("\(t) money at the coin tally: "
            + (r.coinTally.map { "\($0.money) (game time \($0.gameTime))" } ?? "none"))
        out.append("\(t) multiplier history: " + r.multipliers.map { "x\($0.value) at \($0.gameTime)" }
            .joined(separator: ", "))
        out.append("\(t) end score: \(r.result.endScore); trace hash 0x\(String(traceHash(r.result.trace ?? ReplayTrace()), radix: 16))"
            + (r.framesWritten > 0 ? "; \(r.framesWritten) frames written" : ""))
        if let traceNote { out.append("\(t) trace: \(traceNote)") }
        out.append(summaryLine(tag: t, film: r.film, scoreAtLastRead: r.scoreAtLastRead, end: r.result.endReason))
        return out
    }

    /// The G4 line, for every film.
    static func summaryLine(tag: String, film: Film, scoreAtLastRead: Int32?, end: ReplayResult.EndReason) -> String {
        "\(tag) \(film.level) seed 0x\(String(film.seed, radix: 16)): score "
            + (scoreAtLastRead.map(String.init) ?? "none") + " at read \(film.players[0].frames) (end: \(end))"
            + (passes(film: film, scoreAtLastRead: scoreAtLastRead, end: end) ? " PASS" : " FAIL")
    }

    /// A film passes iff the replica's score at the read of its last recorded byte equals the score the recorder
    /// stored AND the session really ended (not the pass bound).
    static func passes(film: Film, scoreAtLastRead: Int32?, end: ReplayResult.EndReason) -> Bool {
        end != .bound && scoreAtLastRead == film.players[0].score
    }

    /// 0 iff at least one film ran, every film run passed and every requested file was written; 1 otherwise.
    static func exitCode(filmsPassed: [Bool], writeFailed: Bool) -> Int32 {
        !filmsPassed.isEmpty && filmsPassed.allSatisfy { $0 } && !writeFailed ? 0 : 1
    }

    /// FNV-1a 64 of the trace's CSV text — a stable fingerprint across runs and processes.
    static func traceHash(_ trace: ReplayTrace) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in trace.csv().utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01b3
        }
        return h
    }

    /// The window as binary PPM (P6), each 5-bit channel widened like the shell's (`ScreenRGBA`).
    static func ppm(_ screen: Pixmap555) -> Data {
        var argb = [UInt32](repeating: 0, count: screen.width * screen.height)
        argb.withUnsafeMutableBufferPointer { ScreenRGBA.convert(screen, into: $0.baseAddress!) }
        var rgb = [UInt8]()
        rgb.reserveCapacity(argb.count * 3)
        for p in argb {
            rgb.append(UInt8(truncatingIfNeeded: p >> 16))
            rgb.append(UInt8(truncatingIfNeeded: p >> 8))
            rgb.append(UInt8(truncatingIfNeeded: p))
        }
        var d = Data("P6\n\(screen.width) \(screen.height)\n255\n".utf8)
        d.append(contentsOf: rgb)
        return d
    }

    /// The trace path for `tag`: as given for one film; `name-<tag>.ext` with several.
    static func tracePath(_ path: String, tag: String, several: Bool) -> URL {
        let url = URL(fileURLWithPath: path)
        guard several else { return url }
        let ext = url.pathExtension
        let base = url.deletingPathExtension().lastPathComponent + "-\(tag)"
        return url.deletingLastPathComponent().appendingPathComponent(ext.isEmpty ? base : base + "." + ext)
    }

    static func fail(_ message: String) {
        FileHandle.standardError.write(Data("deimos-replay: \(message)\n".utf8))
    }

    /// The tool: returns the exit status.
    static func main(_ arguments: [String]) -> Int32 {
        let options: Options
        do { options = try Options(arguments: arguments) } catch {
            fail("\(error)\n\(usage)")
            return 2
        }
        let assets: DeimosAssets
        let dataDirectory: URL
        do {
            dataDirectory = try DeimosData.dataDirectory()
            assets = try DeimosAssets.load(index: TagIndex(dataDirectory: dataDirectory))
        } catch {
            fail("cannot load the game data: \(error)")
            return 1
        }
        var filmsPassed: [Bool] = []
        var writeFailed = false
        for tag in options.films {
            let report: Report
            do {
                let film: Film
                do { film = try FilmLookup.film(tag, in: assets) } catch is FilmLookup.NoSuchFilm {
                    fail("no film '\(tag)' in \(dataDirectory.path)")
                    filmsPassed.append(false)
                    continue
                }
                let frames = options.frames.map { (dir: URL(fileURLWithPath: $0, isDirectory: true), every: options.every) }
                report = try replay(tag: tag, film: film, assets: assets, frames: frames)
            } catch {
                fail("\(tag): \(error)")
                filmsPassed.append(false)
                continue
            }
            // The result is settled and printed before any file is written: a failed write cannot hide it.
            filmsPassed.append(passes(film: report.film, scoreAtLastRead: report.scoreAtLastRead,
                                      end: report.result.endReason))
            let traceURL = options.trace.map { tracePath($0, tag: tag, several: options.films.count > 1) }
            for line in lines(report, traceNote: traceURL?.path) { print(line) }
            if let traceURL {
                do { try (report.result.trace ?? ReplayTrace()).write(to: traceURL) } catch {
                    fail("\(tag): cannot write the trace \(traceURL.path): \(error)")
                    writeFailed = true
                }
            }
        }
        return exitCode(filmsPassed: filmsPassed, writeFailed: writeFailed)
    }
}

exit(DeimosReplay.main(Array(CommandLine.arguments.dropFirst())))

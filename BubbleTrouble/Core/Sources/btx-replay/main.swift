// btx-replay — the FILM replay harness (docs/plans/2026-10-03-btx-core-and-film-harness.md §Task 11.1; G2).
//
// Replays FILMs 1–4 (level = FILM id, seed = FILM.seed; replay-oracle.md §2–§3) through `FilmReplay` and prints one
// row per FILM, `ACCEPT n/4`, and a `FLAGGED:` line per flagged FILM (orchestrator ruling R2); exit 0 iff 4/4 accepted.
// `--trace N` prints FILM N frame by frame, then its summary row. `--rng-variant` exists for the Diagnosis protocol
// only (NR-3: the QuickDraw `Random()` step is [LOW]). Run the built binary, never `swift run` (Invariant 16).
import BubbleTroubleCore
import Foundation

let usage = "usage: btx-replay [--data DIR] [--trace FILM] [--rng-variant qd|qd-no8000]"

func fail(_ message: String, code: Int32) -> Never {
    FileHandle.standardError.write(Data("btx-replay: \(message)\n".utf8))
    exit(code)
}

var dataPath: String?
var traceFilm: Int?
var variant = "qd"
var arguments = CommandLine.arguments.dropFirst()
while let argument = arguments.popFirst() {
    switch argument {
    case "--data":
        guard let value = arguments.popFirst() else { fail("--data needs a directory\n\(usage)", code: 64) }
        dataPath = value
    case "--trace":
        guard let value = arguments.popFirst(), let id = Int(value) else {
            fail("--trace needs a FILM id\n\(usage)", code: 64)
        }
        traceFilm = id
    case "--rng-variant":
        guard let value = arguments.popFirst(), value == "qd" || value == "qd-no8000" else {
            fail("--rng-variant must be qd or qd-no8000\n\(usage)", code: 64)
        }
        variant = value
    case "-h", "--help":
        print(usage)
        exit(0)
    default:
        fail("unknown argument \(argument)\n\(usage)", code: 64)
    }
}

guard let directory = dataPath ?? ProcessInfo.processInfo.environment["HECTORKIT_DATA_BTX"].flatMap({
    $0.isEmpty ? nil : $0
}) else {
    fail("no data — pass --data DIR or set HECTORKIT_DATA_BTX to Bubble Trouble X.app/Contents/Resources\n\(usage)",
         code: 64)
}

let files: BTXResourceFiles
do {
    files = try BTXResourceFiles(resourcesDirectory: URL(fileURLWithPath: directory))
} catch {
    fail("cannot load \(directory): \(error)", code: 66)
}

var config = SessionConfig()
if variant == "qd-no8000" {
    config.rngStep = QuickDrawRandom.stepWithout8000Adjustment
    print("rng-variant: qd-no8000")
}

do {
    if let filmID = traceFilm {
        guard files.filmIDs.contains(filmID) else {
            fail("no FILM \(filmID) (have \(files.filmIDs.map(String.init).joined(separator: ", ")))", code: 64)
        }
        let result = try FilmReplay.run(filmID: filmID, files: files, config: config) { report, state in
            print(FilmReplay.traceLine(report, enemiesActive: state.numEnemiesActive))
        }
        print(FilmReplayResult.header)
        print(result.row)
        exit(result.accepted ? 0 : 1)
    }

    print(FilmReplayResult.header)
    var results: [FilmReplayResult] = []
    for filmID in 1...4 {
        let result = try FilmReplay.run(filmID: filmID, files: files, config: config)
        print(result.row)
        results.append(result)
    }
    let accepted = results.filter(\.accepted).count
    print("ACCEPT \(accepted)/4")
    for line in results.compactMap(\.flagLine) {
        print(line)
    }
    exit(accepted == 4 ? 0 : 1)
} catch {
    fail("replay failed: \(error)", code: 70)
}

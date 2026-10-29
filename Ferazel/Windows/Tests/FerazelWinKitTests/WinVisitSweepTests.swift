import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// The "visit every object" sweep, Windows shell path (VisitSweepPlan.swift, a symlink to the Core suite's, has the
/// visit): each visit is a fresh headless `WinGame` (`--frames`, the scripted host, the baked fonts, the shared
/// `FerazelDriver` — the code the Windows build runs, quit-on-draw-failure included), its keys delivered as key-down /
/// key-up events at 240 wakes a second. Dialogs are the stub's answers (OK; Cancel for a confirm); a save point's
/// panel gets a file in a temporary folder; Continue reads the visit's save from a real saved-game file.
///
/// Runs only with `FERAZEL_VISIT_SWEEP=1` (skipped otherwise): `FERAZEL_VISIT_SWEEP=1 swift test --filter
/// WinVisitSweepTests`, or tools/ferazel-visit-sweep.sh.
@MainActor final class WinVisitSweepTests: XCTestCase {

    func testVisitEveryObjectThroughWinGame() throws {
        guard VisitSweep.enabled else { throw XCTSkip("set FERAZEL_VISIT_SWEEP=1 (tools/ferazel-visit-sweep.sh)") }
        let resources = try FerazelData.open(try FerazelData.dataDirectory())
        let stamp = try WorldFile.load(from: resources).stamp
        let text = try BakedTextTests.baked()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ferazel-visit-sweep-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        var rows: [VisitSweep.Failure] = []
        var visited = 0, teleporters = 0, arrived = 0, exits = 0, exitsToMap = 0
        for level in VisitSweep.selectedLevels {
            let records = try LevelFile.load(from: resources, level: Int16(level)).placements
            let visits = VisitSweep.visits(level: level, records: records)
            var done = 0
            for (i, v) in visits.enumerated() where VisitSweep.mine(level: level, index: i) {
                guard done < VisitSweep.limit else { break }
                done += 1
                VisitSweep.progress(v, index: i)
                let url = folder.appendingPathComponent("visit.fwsg")
                try SavedGameFile.write(VisitSweep.save(for: v, records: records, stamp: stamp), to: url)
                let game = try WinSweepGame(text: text, folder: folder)
                do {
                    try VisitSweep.toMainMenu(game)
                } catch {
                    rows.append(VisitSweep.failure(v, frame: "boot", "\(error)"))
                    continue
                }
                let (failures, seen) = VisitSweep.run(v, game: game,
                                                      ref: SavedGameRef(url: url, displayName: url.lastPathComponent))
                visited += 1
                rows += failures
                for f in failures { VisitSweep.append(f.tsv, to: "failures.tsv") }
                if seen.suspensions.contains("teleport1") { teleporters += 1 }
                if seen.teleportArrived { arrived += 1 }
                if seen.levelCompleted { exits += 1 }
                if seen.exitReachedMap { exitsToMap += 1 }
                VisitSweep.append("\(v.level)\t\(v.record.index)\t\(VisitSweep.hex(v.record.type))\t\(v.offset.rawValue)"
                                  + "\t\(seen.teleportArrived)\t\(seen.levelCompleted)\t\(seen.exitReachedMap)"
                                  + "\t\(seen.suspensions.sorted().joined(separator: ","))", to: "seen.tsv")
            }
        }
        let summary = "visits \(visited); teleports fired in \(teleporters) (arrived \(arrived)); "
            + "level exits taken in \(exits) (reached the world map \(exitsToMap))"
        print("VISIT SWEEP (Windows): " + summary)
        XCTAssertTrue(rows.isEmpty, "\(rows.count) visit failures — \(summary)\n" + VisitSweep.table(rows))
    }
}

/// A save panel that names a file in the sweep's folder (a player choosing a name); the open panel is cancelled.
@MainActor final class SweepFilePanels: WinFilePanels {
    let folder: URL
    private var n = 0
    init(folder: URL) { self.folder = folder }
    func run(_ request: WinFileRequest) -> URL? {
        guard request.kind == .save else { return nil }
        n += 1
        return folder.appendingPathComponent("save-\(n).fwsg")
    }
}

/// `WinGame` headless as one game tick per `tick`: the held keys become key-down / key-up events, then loop wakes
/// (1/240 s each) until the flow has stepped once. A finished game (the shell's quit — on a draw failure) throws its
/// last log line.
@MainActor final class WinSweepGame {
    let game: WinGame
    let host: WinScriptedHost
    private var held: Set<UInt16> = []
    private var logs: [String] = []
    private var reported = 0

    init(text: BakedTextRasterizer, folder: URL) throws {
        let args = try WinArgs.parse(["--frames", "100000000"], environment: [:])
        host = WinScriptedHost()
        let box = LogBox()
        game = WinGame(args: args, host: host, text: text, files: WinFiles(prefsURL: nil, savesFolder: folder),
                       dialogs: WinStubDialogs(), panels: SweepFilePanels(folder: folder),
                       log: { box.lines.append($0) })
        logBox = box
        try game.boot(dataDirectory: FerazelData.dataDirectory())
    }

    private final class LogBox { var lines: [String] = [] }
    private let logBox: LogBox
}

extension WinSweepGame: @MainActor SweepGame {
    var flow: GameFlow { game.flow }

    func tick(keys: [Int]) throws -> FrontOutput {
        let want = Set(keys.map { UInt16($0) })
        for k in held.subtracting(want).sorted() { host.inject(.keyUp(keyCode: k)) }
        for k in want.subtracting(held).sorted() { host.inject(.keyDown(keyCode: k, modifiers: [], isRepeat: false)) }
        held = want
        let before = game.flowSteps
        for _ in 0..<64 where game.flowSteps == before && !game.finished {
            game.step()
            host.advance()
        }
        if game.finished {
            throw VisitSweep.SweepError("WinGame ended (exit \(game.exitCode)): " + (logBox.lines.last ?? "no log"))
        }
        return game.lastOutput
    }

    func takeProblems() -> [String] {
        defer { reported = logBox.lines.count }
        return Array(logBox.lines[reported...])
    }
}

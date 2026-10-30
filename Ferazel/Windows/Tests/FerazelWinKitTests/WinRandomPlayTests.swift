import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import XCTest

/// The random-play bot, Windows shell path (RandomPlayPlan.swift, a symlink to the Core suite's, has the generator and
/// the play loop): each run is a fresh headless `WinGame` (`--frames`, the baked fonts, the shared `FerazelDriver` —
/// the code the Windows build runs, quit-on-draw-failure included) launched with `-FerazelLevel N`, the hidden switch
/// New Game starts at. The bot's keys are key-down / key-up events with the modifiers the held modifier keys make (so
/// Ctrl+P reaches the shortcuts as on Windows), Caps Lock is the host's lock state, 240 wakes a second. Dialogs are the
/// stub's answers (OK; Cancel for a confirm and Options); a save point's panel gets a file in a temporary folder.
///
/// Runs only with `FERAZEL_BOT=1` (skipped otherwise): `FERAZEL_BOT=1 swift test --filter WinRandomPlayTests`, or
/// tools/ferazel-random-play.sh.
@MainActor final class WinRandomPlayTests: XCTestCase {

    func testRandomPlayThroughWinGame() throws {
        guard RandomPlay.enabled else { throw XCTSkip("set FERAZEL_BOT=1 (tools/ferazel-random-play.sh)") }
        let text = try BakedTextTests.baked()
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ferazel-random-play-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        var rows: [RandomPlay.Failure] = []
        var total = RandomPlay.Stats()
        var levels: Set<Int> = [], seeds: Set<Int> = []
        for (i, run) in RandomPlay.runs().enumerated() where RandomPlay.mine(index: i) {
            RandomPlay.progress(run, index: i, step: 0)
            let game = try WinBotGame(text: text, folder: folder, level: run.level)
            let (failures, stats) = RandomPlay.play(run, index: i, game: game)
            rows += failures
            total.add(stats)
            levels.insert(run.level)
            seeds.insert(run.seed)
            for f in failures { RandomPlay.append(f.tsv, to: "failures.tsv") }
            RandomPlay.append(stats.tsv(run), to: "runs.tsv")
        }
        let summary = total.summary(levels: levels.count, seeds: seeds.count)
        print("RANDOM PLAY (Windows): " + summary)
        XCTAssertTrue(rows.isEmpty, "\(rows.count) random-play failures — \(summary)\n" + RandomPlay.table(rows))
    }
}

/// The scripted host with a Caps Lock the bot sets (`WinScriptedHost`'s comes only from a key script).
@MainActor final class BotHost: WinHost {
    let inner = WinScriptedHost()
    var capsLock = false

    var ticks: UInt32 { inner.ticks }
    var seconds: Double { inner.seconds }
    var modifiers: WinModifiers { capsLock ? inner.modifiers.union(.capsLock) : inner.modifiers }
    var wallClock: (secondsSince1904: UInt32, ticks: UInt32) { inner.wallClock }
    func pollEvents(script: Bool) -> [WinEvent] { inner.pollEvents(script: script) }
    func present(rgba: [UInt8]) { inner.present(rgba: rgba) }
    func setCursorVisible(_ visible: Bool) { inner.setCursorVisible(visible) }
    func toggleFullScreen() { inner.toggleFullScreen() }
    func advance() { inner.advance() }
    func inject(_ event: WinEvent) { inner.inject(event) }
}

/// `WinGame` headless as one game tick per `tick` (`WinSweepGame`'s stepping), with the held keys' modifiers and the
/// bot's Caps Lock. A finished game (the shell's quit — on a draw failure) throws its last log line.
@MainActor final class WinBotGame {
    let game: WinGame
    let host: BotHost
    private var held: Set<UInt16> = []
    private let logBox: LogBox
    private var reported = 0

    private final class LogBox { var lines: [String] = [] }

    init(text: BakedTextRasterizer, folder: URL, level: Int) throws {
        let args = try WinArgs.parse(["--frames", "100000000", "-FerazelLevel", String(level)], environment: [:])
        let box = LogBox(), host = BotHost()
        logBox = box
        self.host = host
        game = WinGame(args: args, host: host, text: text, files: WinFiles(prefsURL: nil, savesFolder: folder),
                       dialogs: WinStubDialogs(), panels: SweepFilePanels(folder: folder),
                       log: { box.lines.append($0) })
        try game.boot(dataDirectory: FerazelData.dataDirectory())
    }

    /// The modifiers the held modifier keys make (⌘ 0x37 = Ctrl, ⇧ 0x38, ⌥ 0x3a = Alt).
    private static func modifiers(_ keys: Set<UInt16>) -> WinModifiers {
        var m: WinModifiers = []
        if keys.contains(0x37) { m.insert(.command) }
        if keys.contains(0x38) { m.insert(.shift) }
        if keys.contains(0x3a) { m.insert(.option) }
        return m
    }
}

extension WinBotGame: @MainActor BotGame {
    var flow: GameFlow { game.flow }

    var capsLock: Bool {
        get { host.capsLock }
        set { host.capsLock = newValue }
    }

    func tick(keys: [Int]) throws -> FrontOutput {
        let want = Set(keys.map { UInt16($0) })
        for k in held.subtracting(want).sorted() { host.inject(.keyUp(keyCode: k)) }
        // Modifier keys first, so a letter pressed with them carries them (Ctrl+P).
        let down = want.subtracting(held).sorted { (WinInput.modifierKeyCodes.contains($0) ? 0 : 1, $0)
            < (WinInput.modifierKeyCodes.contains($1) ? 0 : 1, $1) }
        let mods = Self.modifiers(want)
        for k in down { host.inject(.keyDown(keyCode: k, modifiers: mods, isRepeat: false)) }
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

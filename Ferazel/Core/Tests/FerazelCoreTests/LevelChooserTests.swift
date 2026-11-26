import XCTest
@testable import FerazelCore

/// LC (docs/superpowers/plans/2026-11-04-ferazel-remainder.md, D72.1 (a)): the level chooser — on the main menu the L
/// key (Mac virtual key 0x25) steps `GameFlow.startLevel` through `BuiltLevels.list`, wrapping, and says so in the
/// game's own report box; the next New Game starts there. A named departure from the original (known deviation 9).
/// Driven tick by tick from the boot against the committed `Resources/Ferazel` (D26). A missing data file is a FAILURE,
/// never a skip. Plain Swift only (Proof B).
final class LevelChooserTests: XCTestCase {

    private func resources() throws -> FerazelResources { try FerazelData.open(try FerazelData.dataDirectory()) }

    /// No prefs; `save`, when set, is every saved game's block.
    private final class NoFiles: FrontFiles {
        var save: SaveBlock?
        func loadPrefs() -> Data? { nil }
        func storePrefs(_ record: Data) throws {}
        func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock { save ?? SaveBlock() }
        func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) {}
    }

    private final class Levels: LevelServices {
        var prepared: [Int] = []
        func prepare(level: Int) throws -> LevelFaces { prepared.append(level); return LevelFaces() }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {}
        func deathEffectStep(_ k: Int) throws {}
    }

    private final class Rig {
        let flow: GameFlow
        let files = NoFiles()
        let levels = Levels()
        var t: UInt32 = 1000
        var last = FrontOutput()

        init(_ r: FerazelResources) {
            flow = GameFlow(resources: r, prefs: FerazelPrefs(), seed: 1, files: files, levels: levels)
        }

        /// One tick; the loads are answered at once.
        @discardableResult
        func tick(_ input: FrontInput = FrontInput()) -> FrontOutput {
            if case .loading = flow.state { flow.loadFinished() }
            last = flow.tick(now: t, input: input)
            t &+= 1
            return last
        }

        /// Ticks until `until` holds (checked after each tick) or `max` ticks.
        func drive(max: Int = 6000, input: (GameFlow) -> FrontInput = { _ in FrontInput() },
                   until: (GameFlow) -> Bool) {
            for _ in 0..<max {
                tick(input(flow))
                if until(flow) { return }
            }
            XCTFail("the flow did not reach the condition in \(max) ticks (state \(flow.state))")
        }

        func toMenu() { drive { $0.state == .mainMenu } }
    }

    private static func keys(_ k: [Int]) -> FrontInput { FrontInput(keys: KeyState(pressed: k)) }

    private static func reports(_ o: FrontOutput) -> [String] {
        o.requests.compactMap { if case .dialog(.report(let text)) = $0 { return text }; return nil }
    }

    private static func askedFile(_ o: FrontOutput) -> Bool {
        o.requests.contains { if case .getFile = $0 { return true }; return false }
    }

    /// A checkpoint save at level 1's save point (record 24, its face p1 2), as `.SavePointSave` writes it.
    private static func checkpoint(_ r: FerazelResources) throws -> SaveBlock {
        let L = try LevelFile.load(from: r, level: 1)
        var records = L.placements
        let p = records[24]
        records[24] = Placement(index: 24, flag: p.flag, byte1: p.byte1, type: p.type, p1: 2, p2: p.p2, p3: p.p3,
                                p4: p.p4, y: p.y, x: p.x)
        var g = GameGlobals.initGameGlobals(previous: nil)
        var save = SaveBlock()
        save.savePointSave(level: 1, x: 2371, y: 872, stamp: try WorldFile.load(from: r).stamp, date: 0, globals: &g,
                           records: records)
        return save
    }

    /// FNV-1a 64 over bytes.
    private static func fnv(_ bytes: some Sequence<UInt8>, _ h0: UInt64 = 0xcbf2_9ce4_8422_2325) -> UInt64 {
        var h = h0
        for b in bytes {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01b3
        }
        return h
    }

    // MARK: - Tests

    /// A player who never presses L: a scripted menu session (the boot, the pointer over every button, the X joke held
    /// across its cooldown, keys the menu does not poll, then N into level 1) gives tick for tick the same output as on
    /// the commit before LC (2087b9d) — the digest of every tick's output and state was measured there.
    func testMenuSessionWithoutLIsUnchanged() throws {
        let rig = Rig(try resources())
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        var ticks = 0
        var jokes = 0
        func record(_ o: FrontOutput) {
            h = Self.fnv(Array("\(ticks) \(rig.flow.state) \(o)".utf8), h)
            ticks += 1
            if !Self.reports(o).isEmpty {
                jokes += 1
                rig.flow.dialogDone(.ok)
            }
        }
        for _ in 0..<2000 {
            record(rig.tick())
            if rig.flow.state == .mainMenu { break }
        }
        XCTAssertEqual(rig.flow.state, .mainMenu)
        // The pointer across the five buttons and up to the menu bar, no click.
        for v in stride(from: 470, through: 0, by: -10) { record(rig.tick(FrontInput(mouse: (460, v)))) }
        record(rig.tick(FrontInput(mouse: (700, 300))))
        // X held for 70 ticks (the joke at passes 0, 30 and 60), then keys the menu does not poll (J, K, A, S).
        for _ in 0..<70 { record(rig.tick(Self.keys([0x07]))) }
        for k in [0x26, 0x28, 0x00, 0x01] {
            for _ in 0..<5 { record(rig.tick(Self.keys([k]))) }
        }
        // N: New Game into level 1, 300 ticks of it.
        record(rig.tick(Self.keys([0x2d])))
        for _ in 0..<600 {
            record(rig.tick())
            if let run = rig.flow.levelRun, run.iterations >= 1 { break }
        }
        for _ in 0..<300 { record(rig.tick()) }
        XCTAssertEqual(jokes, 3, "the X joke at passes 0, 30 and 60")
        XCTAssertEqual(rig.flow.levelNumber, 1)
        XCTAssertEqual(rig.levels.prepared, [1])
        XCTAssertEqual(rig.flow.startLevel, 1)
        XCTAssertEqual("\(ticks) 0x" + String(h, radix: 16), Self.noLSessionDigest)
    }

    /// Measured on 2087b9d (before LC): ticks, then the FNV-1a 64 of every tick's index, state and output.
    static let noLSessionDigest = "1400 0xcd052bcd075d40d2"

    /// L, one pass at a time with the cooldown run out in between, steps through the whole of `BuiltLevels.list` in
    /// order and wraps from the last to the first; each step reports the level's number and its STR# 1000 name.
    func testLStepsThroughTheBuiltLevelsAndWraps() throws {
        let r = try resources()
        let names = try StringList.load(from: r, id: 1000)
        let rig = Rig(r)
        rig.toMenu()
        XCTAssertEqual(rig.flow.startLevel, 1)
        var chosen: [Int] = []
        for _ in 0..<BuiltLevels.list.count {
            let o = rig.tick(Self.keys([MainMenu.levelChooserKey]))
            let n = rig.flow.startLevel
            chosen.append(n)
            XCTAssertEqual(Self.reports(o), [MainMenu.levelChoiceReport(n, name: names.string(n))], "level \(n)")
            XCTAssertEqual(rig.tick(Self.keys([MainMenu.levelChooserKey])), FrontOutput(), "unanswered: nothing moves")
            rig.flow.dialogDone(.ok)
            for _ in 0..<MainMenu.levelChooserCooldown { rig.tick() }
        }
        XCTAssertEqual(chosen, Array(BuiltLevels.list.dropFirst()) + [BuiltLevels.list[0]])
        // The text: the number, the name, and the next press.
        XCTAssertEqual(MainMenu.levelChoiceReport(3, name: names.string(3)),
                       "New Game will start at level 3, Western Reaches. Press L again for the next level.")
        XCTAssertEqual(MainMenu.levelChoiceReport(3, name: nil),
                       "New Game will start at level 3. Press L again for the next level.")
        XCTAssertEqual(MainMenu.levelChoiceReport(3, name: ""),
                       "New Game will start at level 3. Press L again for the next level.")
        XCTAssertEqual(MainMenu.levelChooserKey, 0x25)
        // The step from a start level outside the list (the switch refused it: New Game would start level 1) is the
        // step from level 1.
        XCTAssertEqual(MainMenu.levelChoice(after: 7), 2)
        XCTAssertEqual(MainMenu.levelChoice(after: 0), 2)
        XCTAssertEqual(MainMenu.levelChoice(after: 22), 1)
        XCTAssertEqual(MainMenu.levelChoice(after: 5), 10)
    }

    /// New Game after k presses opens the chosen level, through the real flow: N after three (level 4), the New Game
    /// button after one (level 2).
    func testNewGameAfterLOpensTheChosenLevel() throws {
        let r = try resources()
        for (presses, mouse, expected) in [(3, false, 4), (1, true, 2)] {
            let rig = Rig(r)
            rig.toMenu()
            for _ in 0..<presses {
                XCTAssertEqual(Self.reports(rig.tick(Self.keys([MainMenu.levelChooserKey]))).count, 1)
                rig.flow.dialogDone(.ok)
                for _ in 0..<MainMenu.levelChooserCooldown { rig.tick() }
            }
            XCTAssertEqual(rig.flow.startLevel, expected)
            if mouse {
                rig.tick(FrontInput(mouse: (430, 270), button: true))
                rig.tick(FrontInput(mouse: (430, 270), button: false))
            } else {
                rig.tick(Self.keys([MainMenu.newGameKey]))
            }
            rig.drive { f in
                guard let run = f.levelRun, run.levelNumber == expected else { return false }
                return run.iterations >= 1
            }
            XCTAssertEqual(rig.flow.levelNumber, expected, "\(presses) presses")
            XCTAssertEqual(rig.levels.prepared, [expected], "\(presses) presses")
        }
    }

    /// L held steps once per cooldown (passes 0, 30 and 60 over 70 ticks, as the X joke), and has its own cooldown: X
    /// right after L still jokes at once, and L right after X still steps at once.
    func testLHeldStepsOncePerCooldownAndLeavesTheJokeAlone() throws {
        let rig = Rig(try resources())
        rig.toMenu()
        var stepTicks: [Int] = []
        for tick in 0..<70 {
            let o = rig.tick(Self.keys([MainMenu.levelChooserKey]))
            if !Self.reports(o).isEmpty {
                stepTicks.append(tick)
                rig.flow.dialogDone(.ok)
            }
        }
        XCTAssertEqual(stepTicks, [0, 31, 62])                       // passes 0, 30 and 60 (the report holds its pass)
        XCTAssertEqual(rig.flow.startLevel, BuiltLevels.list[3])
        // X right after L: the joke at once.
        rig.tick()                                                    // the held report's pass end
        XCTAssertGreaterThan(rig.flow.levelChooserCooldown, 0)
        XCTAssertEqual(rig.flow.jokeCooldown, 0)
        XCTAssertEqual(Self.reports(rig.tick(Self.keys([MainMenu.jokeKey]))), [MainMenu.comingSoon])
        rig.flow.dialogDone(.ok)
        for _ in 0..<MainMenu.levelChooserCooldown { rig.tick() }
        // L right after X: the step at once.
        XCTAssertEqual(Self.reports(rig.tick(Self.keys([MainMenu.jokeKey]))), [MainMenu.comingSoon])
        rig.flow.dialogDone(.ok)
        rig.tick()
        let before = rig.flow.startLevel
        XCTAssertEqual(Self.reports(rig.tick(Self.keys([MainMenu.levelChooserKey]))).count, 1)
        XCTAssertEqual(rig.flow.startLevel, MainMenu.levelChoice(after: before))
        rig.flow.dialogDone(.ok)
        // X and L in one pass: the joke (first in the loop's order); L steps on the next pass where the joke does not
        // fire (X may still be held, cooling down).
        for _ in 0..<(MainMenu.jokeCooldown + 1) { rig.tick() }
        let held = rig.flow.startLevel
        XCTAssertEqual(Self.reports(rig.tick(Self.keys([MainMenu.jokeKey, MainMenu.levelChooserKey]))),
                       [MainMenu.comingSoon])
        XCTAssertEqual(rig.flow.startLevel, held)
    }

    /// L does nothing anywhere but the main menu's key block: held through the boot, a menu button's keyboard track, a
    /// report left up, New Game's fade and the level.
    func testLOutsideTheMainMenuDoesNothing() throws {
        let rig = Rig(try resources())
        let l = Self.keys([MainMenu.levelChooserKey])
        var reports: [String] = []
        // The boot, L held: the start level untouched and no report until the menu is reached; its first pass (on the
        // tick the menu is reached) steps once and leaves the report up — L held under it moves nothing.
        var bootTicks = 0
        for _ in 0..<6000 {
            let o = rig.tick(l)
            if rig.flow.state == .mainMenu {
                reports += Self.reports(o)
                break
            }
            XCTAssertEqual(Self.reports(o), [])
            XCTAssertEqual(rig.flow.startLevel, 1)
            bootTicks += 1
        }
        XCTAssertGreaterThan(bootTicks, 100)
        XCTAssertEqual(reports.count, 1)
        XCTAssertEqual(rig.flow.startLevel, 2)
        for _ in 0..<40 { XCTAssertEqual(rig.tick(l), FrontOutput()) }
        XCTAssertEqual(rig.flow.startLevel, 2)
        rig.flow.dialogDone(.ok)
        for _ in 0..<MainMenu.levelChooserCooldown { rig.tick() }
        // N with L held from then on: the keyboard track, New Game's fade, the chapter card and the level — L never
        // steps again.
        reports += Self.reports(rig.tick(Self.keys([MainMenu.newGameKey, MainMenu.levelChooserKey])))
        var iterations = 0
        for _ in 0..<6000 {
            reports += Self.reports(rig.tick(l))
            iterations = rig.flow.levelRun.map { $0.levelNumber == 2 ? $0.iterations : 0 } ?? 0
            if iterations >= 60 { break }
        }
        XCTAssertGreaterThanOrEqual(iterations, 60, "level 2 played on with L held")
        XCTAssertEqual(rig.flow.state, .newGame)
        XCTAssertEqual(rig.flow.startLevel, 2)
        XCTAssertEqual(rig.levels.prepared, [2])
        XCTAssertEqual(reports, [MainMenu.levelChoiceReport(2, name: try StringList.load(from: rig.flow.resources,
                                                                                          id: 1000).string(2))])
    }

    /// L is read only in the key block: held with the pointer on the canvas over no button (the mouse block's own path,
    /// which hides the menu bar) it steps once per cooldown, one level a step, as with no pointer — a second reader in
    /// the mouse block would step twice. In passes where the app is inactive (neither block runs) it does nothing.
    func testLIsReadOnlyInTheKeyBlock() throws {
        let rig = Rig(try resources())
        rig.toMenu()
        let off = (h: 100, v: 300)
        XCTAssertNil(MainMenu.button(h: off.h, v: off.v))
        XCTAssertGreaterThanOrEqual(off.v, MainMenu.menuBarRevealV)
        let l = KeyState(pressed: [MainMenu.levelChooserKey])
        // Inactive, L held across two cooldowns with the pointer there: nothing.
        for _ in 0..<(2 * MainMenu.levelChooserCooldown + 10) {
            XCTAssertEqual(Self.reports(rig.tick(FrontInput(keys: l, mouse: off, active: false))), [])
        }
        XCTAssertEqual(rig.flow.startLevel, 1)
        XCTAssertEqual(rig.flow.levelChooserCooldown, 0)
        // Active, the pointer over no button: a step at passes 0, 30 and 60, one report and one level each.
        var stepTicks: [Int] = []
        var chosen: [Int] = []
        for tick in 0..<70 {
            let reports = Self.reports(rig.tick(FrontInput(keys: l, mouse: off)))
            XCTAssertLessThanOrEqual(reports.count, 1, "tick \(tick)")
            if !reports.isEmpty {
                stepTicks.append(tick)
                chosen.append(rig.flow.startLevel)
                rig.flow.dialogDone(.ok)
            }
        }
        XCTAssertEqual(stepTicks, [0, 31, 62])                       // as with no pointer (the report holds its pass)
        XCTAssertEqual(chosen, Array(BuiltLevels.list[1...3]))
    }

    /// Continue ignores the chooser: with L moved to level 4, Continue from a level-1 checkpoint save through the real
    /// flow (R, the file dialog, the save) opens the save's own level 1; the chosen level stays for New Game.
    func testContinueOpensTheSavesLevelNotTheChosenOne() throws {
        let r = try resources()
        let rig = Rig(r)
        rig.files.save = try Self.checkpoint(r)
        rig.toMenu()
        for _ in 0..<3 {
            XCTAssertEqual(Self.reports(rig.tick(Self.keys([MainMenu.levelChooserKey]))).count, 1)
            rig.flow.dialogDone(.ok)
            for _ in 0..<MainMenu.levelChooserCooldown { rig.tick() }
        }
        XCTAssertEqual(rig.flow.startLevel, 4)
        rig.tick(Self.keys([0x0f]))                                   // R
        if !Self.askedFile(rig.last) { rig.drive { _ in Self.askedFile(rig.last) } }
        rig.flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/nonexistent/one"), displayName: "one")))
        rig.drive { _ in !rig.levels.prepared.isEmpty }
        XCTAssertEqual(rig.levels.prepared, [1], "the save's level, not the chosen 4")
        guard rig.levels.prepared == [1] else { return }
        rig.drive { f in
            guard let run = f.levelRun, run.levelNumber == 1 else { return false }
            return run.iterations >= 1
        }
        XCTAssertEqual(rig.flow.state, .continueGame)
        XCTAssertEqual(rig.flow.levelNumber, 1)
        XCTAssertEqual(rig.flow.startLevel, 4)
    }
}

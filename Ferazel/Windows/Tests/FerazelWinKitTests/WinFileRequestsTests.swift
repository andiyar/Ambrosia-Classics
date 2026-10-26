import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import HectorInput
import XCTest

/// WF5 (D43 Rulings 3, 10): saved games on Windows — the native Open / Save dialogs' requests and answers, the input
/// flushed after one, the command line's saved game, and a save written and read back through `WinFiles`. No SDL, no
/// window, no dialog shown (the panels here record and answer).
@MainActor final class WinFileRequestsTests: XCTestCase {
    /// A panel that records each request and answers `answer` (and runs `during` while "up").
    final class RecordingPanels: WinFilePanels {
        var requests: [WinFileRequest] = []
        var answer: URL?
        var during: () -> Void = {}

        func run(_ request: WinFileRequest) -> URL? {
            requests.append(request)
            during()
            return answer
        }
    }

    func temporaryFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("WinFileRequestsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    /// A level-1 save-point save (Core's `GameFlowGameTests.checkpoint`): continued, it starts at (2371, 872).
    static func checkpoint() throws -> SaveBlock {
        let r = try FerazelData.open(try FerazelData.dataDirectory())
        let L = try LevelFile.load(from: r, level: 1)
        var records = L.placements
        let p = records[24]
        records[24] = Placement(index: 24, flag: p.flag, byte1: p.byte1, type: p.type, p1: 2, p2: p.p2, p3: p.p3,
                                p4: p.p4, y: p.y, x: p.x)
        var g = GameGlobals.initGameGlobals(previous: nil)
        g.startFacing = 7
        g.coins = 23
        var save = SaveBlock()
        save.savePointSave(level: 1, x: 2371, y: 872, stamp: try WorldFile.load(from: r).stamp, date: 0x1234,
                           globals: &g, records: records)
        return save
    }

    // MARK: 1 · Windows-legal default names (Ruling 10)

    func testSaveNamesAreMadeWindowsLegal() {
        for c in ["\\", "/", ":", "*", "?", "\"", "<", ">", "|"] {
            XCTAssertEqual(WinFiles.legalSaveName("a\(c)b"), "a-b", "illegal \(c)")
        }
        for c: Unicode.Scalar in ["\u{0}", "\u{1}", "\u{9}", "\u{1F}", "\u{7F}"] {
            XCTAssertEqual(WinFiles.legalSaveName("a\(Character(c))b"), "a-b", "control \(c.value)")
        }
        XCTAssertEqual(WinFiles.legalSaveName("Ferazel: a/b\\c*?\"<>|\u{1}"), "Ferazel- a-b-c-------")
        // Trailing dots and spaces dropped (Windows strips them itself); leading and inner ones kept.
        XCTAssertEqual(WinFiles.legalSaveName("Game."), "Game")
        XCTAssertEqual(WinFiles.legalSaveName("Game "), "Game")
        XCTAssertEqual(WinFiles.legalSaveName("Saved Game 2. . "), "Saved Game 2")
        XCTAssertEqual(WinFiles.legalSaveName(" .a. b"), " .a. b")
        // Reserved device names, any case, also before an extension (Windows' rule) — "_" after the stem.
        XCTAssertEqual(WinFiles.legalSaveName("CON"), "CON_")
        XCTAssertEqual(WinFiles.legalSaveName("con"), "con_")
        XCTAssertEqual(WinFiles.legalSaveName("com3"), "com3_")
        XCTAssertEqual(WinFiles.legalSaveName("LPT9"), "LPT9_")
        XCTAssertEqual(WinFiles.legalSaveName("nul.txt"), "nul_.txt")
        XCTAssertEqual(WinFiles.legalSaveName("Aux."), "Aux_")
        XCTAssertEqual(WinFiles.legalSaveName("COM0"), "COM0")
        XCTAssertEqual(WinFiles.legalSaveName("CONSOLE"), "CONSOLE")
        XCTAssertEqual(WinFiles.legalSaveName("Prn Game"), "Prn Game")
        // Empty stays empty; a legal default (the flow's) is unchanged; no extension is added.
        XCTAssertEqual(WinFiles.legalSaveName(""), "")
        XCTAssertEqual(WinFiles.legalSaveName("Ferazel's Wand Saved Game 1"), "Ferazel's Wand Saved Game 1")
    }

    // MARK: 2 · the Save request's fields

    func testSaveRequestFieldsFromAPutFileRequest() throws {
        let folder = try temporaryFolder()
        let r = PutFileRequest(prompt: "Please name your saved game.", defaultName: "Saved: Game 2.",
                               message: "DITL 1003 item 13")
        let request = WinFileRequests.save(r, files: WinFiles(prefsURL: nil, savesFolder: folder))
        XCTAssertEqual(request, WinFileRequest(kind: .save, title: "Please name your saved game.",
                                               defaultName: "Saved- Game 2", folder: folder,
                                               filters: [WinFileFilter(name: "All files (*.*)", pattern: "*.*")],
                                               options: [.explorer, .overwritePrompt, .pathMustExist, .noChangeDir]))
        // The name field starts with the full path, so the dialog always opens in the saves folder (Windows 7+ may
        // otherwise prefer the last-used folder over `lpstrInitialDir`); no folder → the name alone; Open → empty.
        XCTAssertEqual(WinFileRequests.initialFile(request), folder.appendingPathComponent("Saved- Game 2").path)
        var noFolder = request
        noFolder.folder = nil
        XCTAssertEqual(WinFileRequests.initialFile(noFolder), "Saved- Game 2")
        var noName = request
        noName.defaultName = ""
        XCTAssertEqual(WinFileRequests.initialFile(noName), "")
        // The message line is nowhere in the request (◇W9: comdlg32 has none).
        XCTAssertFalse([request.title, request.defaultName].contains(r.message))
        // The Open request: the prompt as title, no name, the file must exist.
        let open = WinFileRequests.open(prompt: "Open which game?", files: WinFiles(prefsURL: nil, savesFolder: folder))
        XCTAssertEqual(open, WinFileRequest(kind: .open, title: "Open which game?", defaultName: "", folder: folder,
                                            filters: [WinFileRequests.allFiles],
                                            options: [.explorer, .overwritePrompt, .pathMustExist, .fileMustExist,
                                                      .noChangeDir]))
        XCTAssertEqual(WinFileRequests.initialFile(open), "", "Open: an empty name, the folder from lpstrInitialDir")
    }

    // MARK: 3 · Save's start folder is created first

    func testSaveStartFolderIsCreatedWhenMissing() throws {
        let saves = try temporaryFolder().appendingPathComponent("Ambrosia Classics/Ferazel's Wand", isDirectory: true)
        XCTAssertFalse(FileManager.default.fileExists(atPath: saves.path))
        let request = WinFileRequests.save(PutFileRequest(prompt: "p", defaultName: "n", message: "m"),
                                           files: WinFiles(prefsURL: nil, savesFolder: saves))
        XCTAssertEqual(request.folder, saves)
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: saves.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        // A folder that cannot be made (a file in its way): logged, the dialog starts in its own.
        let blocked = try temporaryFolder().appendingPathComponent("file")
        try Data([1]).write(to: blocked)
        var logs: [String] = []
        let r2 = WinFileRequests.save(PutFileRequest(prompt: "p", defaultName: "n", message: "m"),
                                      files: WinFiles(prefsURL: nil, savesFolder: blocked.appendingPathComponent("x")),
                                      log: { logs.append($0) })
        XCTAssertNil(r2.folder)
        XCTAssertEqual(logs.count, 1)
        // No saves folder (a `--frames` run): none, nothing made.
        XCTAssertNil(WinFileRequests.save(PutFileRequest(prompt: "p", defaultName: "n", message: "m"),
                                          files: WinFiles(prefsURL: nil, savesFolder: nil)).folder)
    }

    // MARK: 4 · Open's start folder only when it exists, never created

    func testOpenStartFolderOnlyWhenItExistsNeverCreated() throws {
        let missing = try temporaryFolder().appendingPathComponent("not yet", isDirectory: true)
        XCTAssertNil(WinFileRequests.open(prompt: "p", files: WinFiles(prefsURL: nil, savesFolder: missing)).folder)
        XCTAssertFalse(FileManager.default.fileExists(atPath: missing.path), "the Open dialog never creates it")
        try FileManager.default.createDirectory(at: missing, withIntermediateDirectories: true)
        XCTAssertEqual(WinFileRequests.open(prompt: "p", files: WinFiles(prefsURL: nil, savesFolder: missing)).folder,
                       missing)
        XCTAssertNil(WinFileRequests.open(prompt: "p", files: WinFiles(prefsURL: nil, savesFolder: nil)).folder)
    }

    // MARK: 5 · the answer → `fileDone`; the Mac SDL build's --save-as / --open answers

    func testAnswerMapping() throws {
        let url = URL(fileURLWithPath: "/tmp/Saves/Ferazel Game 3")
        XCTAssertEqual(WinFileRequests.result(url),
                       .chosen(SavedGameRef(url: url, displayName: "Ferazel Game 3")))
        XCTAssertEqual(WinFileRequests.result(nil), .cancelled)
        // The Mac SDL development build: `--save-as FILE` answers every Save, `--open FILE` every Open; else cancelled.
        let args = try WinArgs.parse(["--save-as", "/tmp/a", "--open", "/tmp/b"], environment: [:])
        XCTAssertEqual([args.saveAsPath, args.openPath], ["/tmp/a", "/tmp/b"])
        let save = WinFileRequests.save(PutFileRequest(prompt: "p", defaultName: "n", message: "m"),
                                        files: WinFiles(prefsURL: nil, savesFolder: nil))
        let open = WinFileRequests.open(prompt: "p", files: WinFiles(prefsURL: nil, savesFolder: nil))
        let answers = WinAnswerFilePanels(args)
        XCTAssertEqual(answers.run(save)?.path, "/tmp/a")
        XCTAssertEqual(answers.run(open)?.path, "/tmp/b")
        let none = WinAnswerFilePanels(try WinArgs.parse([], environment: [:]))
        XCTAssertNil(none.run(save))
        XCTAssertNil(none.run(open))
        XCTAssertThrowsError(try WinArgs.parse(["--save-as"], environment: [:]))
        // The stub (`--frames`) asks nothing of anyone: cancelled, recorded.
        let stub = WinStubFilePanels()
        XCTAssertNil(stub.run(save))
        XCTAssertNil(stub.run(open))
        XCTAssertEqual(stub.asked, ["save n", "open p"])
    }

    // MARK: 6 · no stuck keys after a dialog

    func testInputHeldBeforeADialogIsFlushedAfterIt() throws {
        let panels = RecordingPanels()
        let host = WinScriptedHost()
        let game = WinGame(args: try WinArgs.parse(["--frames", "100000"], environment: [:]), host: host,
                           text: try BakedTextTests.baked(), files: WinFiles(prefsURL: nil, savesFolder: nil),
                           panels: panels)
        try game.boot(dataDirectory: FerazelData.dataDirectory())
        WinGameTests.run(game, host) { $0.flow.state == .mainMenu && $0.menuState.menusLive }
        // Ctrl+O (the menu pass reads ⌘O polled: Restore Game) with an arrow held; their key-ups go to the dialog,
        // never to the game window.
        host.inject(.keyDown(keyCode: 0x7B, modifiers: [], isRepeat: false))
        host.inject(.keyDown(keyCode: 0x37, modifiers: .command, isRepeat: false))
        host.inject(.keyDown(keyCode: 0x1F, modifiers: .command, isRepeat: false))
        var heldWhileUp: Set<UInt16>?
        var buttonWhileUp: Bool?
        var stepsWhileUp: Int?
        panels.during = {
            heldWhileUp = game.input.held
            // The dialog stays up for 32 loop wakes (8 ticks): the loop's wakes reach the game, the flow never ticks.
            // A mouse-down reaches the game window meanwhile (the click that ends the dialog; its mouse-up is the
            // dialog's).
            let before = game.flowSteps
            host.inject(.mouseDown(x: 100, y: 100))
            for _ in 0..<32 {
                host.advance()
                game.step()
            }
            stepsWhileUp = game.flowSteps - before
            buttonWhileUp = game.input.button
        }
        WinGameTests.run(game, host, max: 400) { _ in !panels.requests.isEmpty }
        XCTAssertEqual(panels.requests.map(\.kind), [.open])
        XCTAssertEqual(heldWhileUp, [0x7B, 0x37, 0x1F], "held when the dialog came up")
        XCTAssertEqual(buttonWhileUp, true, "the button down while the dialog was up")
        XCTAssertEqual(stepsWhileUp, 0, "the flow is held still while the dialog is up")
        XCTAssertEqual(game.input.held, [], "flushed after it: no stuck keys")
        XCTAssertFalse(game.input.button, "nor a stuck mouse button")
        XCTAssertEqual(game.input.frontInput(capsLock: false, playing: []).keys, KeyState(pressed: []))
        // The cancel took it back to the menu.
        WinGameTests.run(game, host, max: 4000) { $0.flow.state == .mainMenu && $0.menuState.menusLive }
        XCTAssertEqual(panels.requests.count, 1)
        // The pad: a button pressed while a dialog was up (the game polls no pad then) is ignored after it until
        // released, then works again. (Shown on `WinInput` itself: in the game the menu's pad layout changes across
        // the dialog's continue-game tick, which ignores a held button on its own.)
        var input = WinInput()
        let mapping = FerazelPadLayout.mapping(keys: [], context: .mainMenu, dialogUp: false)
        _ = input.pollPad(ShellPadState(), mapping: mapping, now: 0)
        input.flushAfterModal()
        let south = ShellPadState(buttons: [.south])
        XCTAssertEqual(input.pollPad(south, mapping: mapping, now: 0.1).held, [], "held across the dialog: nothing")
        XCTAssertEqual(input.frontInput(capsLock: false, playing: []).keys, KeyState(pressed: []))
        _ = input.pollPad(ShellPadState(), mapping: mapping, now: 0.2)
        XCTAssertEqual(input.pollPad(south, mapping: mapping, now: 0.3).held, [FerazelPadLayout.newGameKey],
                       "pressed again, it is the game's")
    }

    // MARK: 7 · the command line's saved game, at the menu pass

    func testLaunchPathOpensTheDocumentAtTheMenuPass() throws {
        let folder = try temporaryFolder()
        let url = folder.appendingPathComponent("Ferazel's Wand Saved Game 1")
        try SavedGameFile.write(try Self.checkpoint(), to: url)
        let panels = RecordingPanels()
        let host = WinScriptedHost()
        let game = WinGame(args: try WinArgs.parse(["--frames", "100000", url.path], environment: [:]), host: host,
                           text: try BakedTextTests.baked(), files: WinFiles(prefsURL: nil, savesFolder: nil),
                           panels: panels)
        try game.boot(dataDirectory: FerazelData.dataDirectory())
        // Queued once at the boot (the Mac's Finder open), waiting for the main menu's `.CheckEvent`.
        XCTAssertEqual(game.flow.appleEvents.events, [.open(SavedGameRef(url: url, displayName: url.lastPathComponent))])
        // It stays queued through the boot (the logo, the load, the idle wait — `.idle` ends on it but leaves it) and
        // the first menu pass's `.CheckEvent` takes it: `.ContinueGame(&reply)` straight from the boot's menu entry.
        var states: [GameFlow.State] = []
        var queuedUntilContinued = true
        WinGameTests.run(game, host) {
            let state = $0.flow.state
            if case .loading = state {} else if states.last != state { states.append(state) }
            if $0.flow.state != .continueGame, $0.flow.appleEvents.isEmpty { queuedUntilContinued = false }
            return $0.flow.levelRun?.session != nil
        }
        XCTAssertTrue(queuedUntilContinued, "taken only by the menu pass")
        XCTAssertEqual(states, [.boot, .continueGame], "no main-menu pick, no file dialog: straight from the boot")
        XCTAssertEqual(game.flow.lastReply?.url, url)
        XCTAssertEqual(game.flow.levelRun?.levelNumber, 1)
        XCTAssertEqual([game.flow.levelRun?.session?.startX, game.flow.levelRun?.session?.startY], [2371, 872])
        XCTAssertTrue(game.flow.appleEvents.isEmpty, "opened once")
        XCTAssertTrue(panels.requests.isEmpty, "no file dialog")
    }

    // MARK: 8 · a round trip through WinFiles

    func testSavedGameRoundTripThroughWinFiles() throws {
        let folder = try temporaryFolder().appendingPathComponent("Saves", isDirectory: true)
        let files = WinFiles(prefsURL: nil, savesFolder: folder)
        try files.ensureSavesFolder()
        let block = try Self.checkpoint()
        let ref = SavedGameRef(url: folder.appendingPathComponent(WinFiles.legalSaveName("Game: 1.")),
                               displayName: "Game- 1")
        try files.writeSavedGame(block, to: ref)
        XCTAssertTrue(FileManager.default.fileExists(atPath: ref.url.path))
        XCTAssertEqual(ref.url.lastPathComponent, "Game- 1")
        let back = try files.readSavedGame(ref)
        XCTAssertEqual(back, block)
        XCTAssertEqual([back.level, Int16(back.playerX), Int16(back.playerY)], [1, 2371, 872])
        XCTAssertEqual(back.date, 0x1234)
        // Saving again over it (the Save dialog's overwrite): the new block wins.
        var second = block
        second.date = 0x5678
        try files.writeSavedGame(second, to: ref)
        XCTAssertEqual(try files.readSavedGame(ref), second)
    }
}

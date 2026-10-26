import FerazelCore
import FerazelRender
@testable import FerazelWinKit
import Foundation
import HectorInput
import XCTest

/// WF3 (D43 Rulings 5–7, 9–12, 14, 20): the Windows shell's rules, without SDL — keys, shortcuts, the pad merge, the
/// cursor, the files, the arguments, the audio driver hint, the start-up check, the key script.
@MainActor final class WinShellTests: XCTestCase {
    static let mainMenu = MenuState(menusLive: true, paused: false, musicOn: true, soundOn: true)
    static let paused = MenuState(menusLive: true, paused: true, musicOn: true, soundOn: true)
    static let inPlay = MenuState(menusLive: false, paused: false, musicOn: true, soundOn: true)

    static func shortcuts() throws -> WinShortcuts {
        WinShortcuts(resources: try FerazelData.open(try FerazelData.dataDirectory()))
    }

    // MARK: 3 · right-hand modifiers

    func testRightHandModifiersFoldIntoTheLeftKeys() throws {
        var input = WinInput()
        let s = try Self.shortcuts()
        for code: UInt16 in [0x36, 0x3C, 0x3D, 0x3E] {   // right ⌘ (Ctrl), Shift, ⌥ (Alt), ⌃ (Windows key)
            XCTAssertEqual(input.keyDown(code, modifiers: [], isRepeat: false, shortcuts: s, menus: Self.inPlay,
                                         modalUp: false, dialogUp: false), .held)
        }
        XCTAssertEqual(input.held, [0x36, 0x3C, 0x3D, 0x3E], "held as SDL reported them")
        XCTAssertEqual(input.frontInput(capsLock: false, playing: []).keys, KeyState(pressed: [0x37, 0x38, 0x3A, 0x3B]))
        // The script names reach the same codes.
        XCTAssertEqual(["rcommand", "rshift", "roption", "rcontrol"].map { WinKeyNames.table[$0]?.code },
                       [0x36, 0x3C, 0x3D, 0x3E])
    }

    // MARK: 4 · the shortcut table over MenuState

    func testShortcutTableFollowsMenuStateAndTheMenuResources() throws {
        let s = try Self.shortcuts()
        // The letters are the MENU resources' key equivalents (MENU 129 then 130), never a list in the code.
        XCTAssertEqual(s.entries.map(\.letter), ["n", "o", "w", "q", "m", "f", "p"])
        XCTAssertEqual(s.entries.map(\.keyCode), [0x2D, 0x1F, 0x0D, 0x0C, 0x2E, 0x03, 0x23])
        XCTAssertEqual(s.entries.map(\.item), [.newGame, .restoreGame, .abortGame, .quit, .music, .soundEffects,
                                               .preferences])
        func take(_ letter: String, _ mods: WinModifiers, _ m: MenuState, modal: Bool = false) -> PauseRun.MenuItem? {
            s.take(keyCode: WinKeyNames.table[letter]!.code, modifiers: mods, menus: m, modalUp: modal)
        }
        // Ctrl alone takes; Ctrl+Shift, Ctrl+Alt, Ctrl+Windows key and Alt alone do not. Caps Lock is no modifier.
        XCTAssertEqual(take("m", .command, Self.mainMenu), .music)
        XCTAssertEqual(take("f", [.command, .capsLock], Self.mainMenu), .soundEffects)
        XCTAssertNil(take("m", [.command, .shift], Self.mainMenu))
        XCTAssertNil(take("m", [.command, .option], Self.mainMenu))
        XCTAssertNil(take("m", [.command, .control], Self.mainMenu))
        XCTAssertNil(take("m", .option, Self.mainMenu))
        // The main menu's own letters fall through to its polled keys; Abort Game is off there.
        for l in ["n", "o", "q", "p"] { XCTAssertNil(take(l, .command, Self.mainMenu), l) }
        XCTAssertNil(take("w", .command, Self.mainMenu))
        // Paused: Abort Game on, New Game / Restore Game off, the rest on.
        XCTAssertEqual(["n", "o", "w", "q", "m", "f", "p"].map { take($0, .command, Self.paused) },
                       [nil, nil, .abortGame, .quit, .music, .soundEffects, .preferences])
        // A dialog or a file panel up blocks every shortcut; outside the menu loops every key is the game's.
        for l in ["n", "o", "w", "q", "m", "f", "p"] {
            XCTAssertNil(take(l, .command, Self.paused, modal: true), l)
            XCTAssertNil(take(l, .command, Self.inPlay), l)
        }
        XCTAssertNil(take("x", .command, Self.paused), "no item")
    }

    // MARK: 5 · a taken shortcut never enters the held keys

    func testATakenShortcutIsNotHeldAndAFallThroughIs() throws {
        let s = try Self.shortcuts()
        var input = WinInput()
        _ = input.keyDown(0x37, modifiers: .command, isRepeat: false, shortcuts: s, menus: Self.mainMenu,
                          modalUp: false, dialogUp: false)
        XCTAssertEqual(input.keyDown(0x2E, modifiers: .command, isRepeat: false, shortcuts: s, menus: Self.mainMenu,
                                     modalUp: false, dialogUp: false), .shortcut(.music))
        XCTAssertEqual(input.held, [0x37], "Ctrl (⌘) is held, M is not")
        input.keyUp(0x2E)
        // Ctrl+N in the main menu falls through: the game polls ⌘ + N.
        XCTAssertEqual(input.keyDown(0x2D, modifiers: .command, isRepeat: false, shortcuts: s, menus: Self.mainMenu,
                                     modalUp: false, dialogUp: false), .held)
        // In a level Ctrl+Q is ⌘Q in the polled keys (the level's own quit confirm).
        XCTAssertEqual(input.keyDown(0x0C, modifiers: .command, isRepeat: false, shortcuts: s, menus: Self.inPlay,
                                     modalUp: false, dialogUp: false), .held)
        XCTAssertEqual(input.frontInput(capsLock: false, playing: []).keys, KeyState(pressed: [0x37, 0x2D, 0x0C]))
        // With a dialog up the key is the dialog's, not the game's.
        XCTAssertEqual(input.keyDown(0x24, modifiers: [], isRepeat: false, shortcuts: s, menus: Self.inPlay,
                                     modalUp: true, dialogUp: true), .dialog)
        XCTAssertFalse(input.held.contains(0x24))
    }

    // MARK: 6 · Alt+Enter

    func testAltEnterTogglesFullScreenAndIsEaten() throws {
        let s = try Self.shortcuts()
        var input = WinInput()
        XCTAssertEqual(input.keyDown(0x24, modifiers: .option, isRepeat: false, shortcuts: s, menus: Self.inPlay,
                                     modalUp: false, dialogUp: false), .fullScreen)
        XCTAssertEqual(input.keyDown(0x4C, modifiers: [.option, .capsLock], isRepeat: false, shortcuts: s,
                                     menus: Self.inPlay, modalUp: false, dialogUp: false), .fullScreen)
        XCTAssertTrue(input.held.isEmpty)
        XCTAssertEqual(input.keyDown(0x24, modifiers: [], isRepeat: false, shortcuts: s, menus: Self.inPlay,
                                     modalUp: false, dialogUp: false), .held, "Return alone is the game's")
        // Through the loop: one toggle per press, a repeat eaten too; Ctrl+Alt+Enter is no toggle.
        let host = WinScriptedHost(script: try WinKeyScript(text: "0 down return option\n"))
        let game = WinGame(args: try WinArgs.parse([], environment: [:]), host: host, text: StubGlyphRasterizer(),
                           files: WinFiles(prefsURL: nil, savesFolder: nil))
        game.step()
        host.advance()
        host.inject(.keyDown(keyCode: 0x24, modifiers: .option, isRepeat: true))
        host.inject(.keyDown(keyCode: 0x24, modifiers: [.option, .command], isRepeat: false))
        game.step()
        XCTAssertEqual(host.fullScreenToggles, 1)
    }

    // MARK: 7 · Caps Lock

    func testCapsLockIsALockNeverAHeldKey() throws {
        let s = try Self.shortcuts()
        var scripted = WinScriptedInput(script: try WinKeyScript(text: "0 down capslock\n0 caps on\n8 caps off\n"))
        var input = WinInput()
        for e in scripted.events() {
            if case let .keyDown(code, mods, rep) = e {
                _ = input.keyDown(code, modifiers: mods, isRepeat: rep, shortcuts: s, menus: Self.inPlay,
                                  modalUp: false, dialogUp: false)
            }
        }
        XCTAssertTrue(input.held.isEmpty, "Caps Lock never enters the key map")
        XCTAssertTrue(scripted.modifiers.contains(.capsLock))
        XCTAssertTrue(input.frontInput(capsLock: scripted.modifiers.contains(.capsLock), playing: []).capsLock)
        for _ in 0..<8 { scripted.advance() }
        _ = scripted.events()
        XCTAssertFalse(scripted.modifiers.contains(.capsLock))
        XCTAssertFalse(input.frontInput(capsLock: scripted.modifiers.contains(.capsLock), playing: []).capsLock)
    }

    // MARK: 8 · the pad merge (D37)

    func testPadMergesAsTheOriginalKeys() throws {
        let keys = FerazelPrefs().keys
        let playing = FerazelPadLayout.mapping(keys: keys, context: .playing, dialogUp: false)
        var input = WinInput()
        _ = input.pollPad(.empty, mapping: playing, now: 0)
        // South = jump (action key 5) in a level, merged with the keyboard's held keys.
        _ = input.keyDown(0x31, modifiers: [], isRepeat: false, shortcuts: WinShortcuts(entries: []),
                          menus: Self.inPlay, modalUp: false, dialogUp: false)
        _ = input.pollPad(ShellPadState(buttons: [.south]), mapping: playing, now: 0.1)
        XCTAssertEqual(input.frontInput(capsLock: false, playing: []).keys,
                       KeyState(pressed: [0x31, Int(keys[5])]))
        // + toggles the Caps Lock latch, ORed into Caps Lock.
        _ = input.pollPad(ShellPadState(buttons: [.start]), mapping: playing, now: 0.2)
        XCTAssertTrue(input.frontInput(capsLock: false, playing: []).capsLock)
        _ = input.pollPad(.empty, mapping: playing, now: 0.3)
        XCTAssertTrue(input.frontInput(capsLock: false, playing: []).capsLock, "a latch")
        _ = input.pollPad(ShellPadState(buttons: [.start]), mapping: playing, now: 0.4)
        XCTAssertFalse(input.frontInput(capsLock: false, playing: []).capsLock)
        // − is Esc only after a 1 s hold.
        _ = input.pollPad(ShellPadState(buttons: [.back]), mapping: playing, now: 1.0)
        XCTAssertFalse(input.frontInput(capsLock: false, playing: []).keys.isPressed(0x35))
        _ = input.pollPad(ShellPadState(buttons: [.back]), mapping: playing, now: 1.99)
        XCTAssertFalse(input.frontInput(capsLock: false, playing: []).keys.isPressed(0x35))
        let f = input.pollPad(ShellPadState(buttons: [.back]), mapping: playing, now: 2.0)
        XCTAssertEqual(f.pressed, [0x35])
        XCTAssertTrue(input.frontInput(capsLock: false, playing: []).keys.isPressed(0x35))
        // Without the focus the pad reads as nothing, and a button still held on return is ignored until released.
        input.focusLost()
        _ = input.pollPad(ShellPadState(buttons: [.south]), mapping: playing, now: 2.1)
        input.focusGained()
        _ = input.pollPad(ShellPadState(buttons: [.south]), mapping: playing, now: 2.2)
        XCTAssertEqual(input.frontInput(capsLock: false, playing: []).keys, KeyState())
        XCTAssertTrue(input.frontInput(capsLock: false, playing: []).active)
    }

    // MARK: 11 · the cursor

    func testCursorHidesOnlyOverTheCanvasFocusedAndNoModal() {
        XCTAssertTrue(WinCursorRule.hidden(wanted: true, modalUp: false, focused: true, overCanvas: true))
        XCTAssertFalse(WinCursorRule.hidden(wanted: false, modalUp: false, focused: true, overCanvas: true))
        XCTAssertFalse(WinCursorRule.hidden(wanted: true, modalUp: true, focused: true, overCanvas: true))
        XCTAssertFalse(WinCursorRule.hidden(wanted: true, modalUp: false, focused: false, overCanvas: true))
        XCTAssertFalse(WinCursorRule.hidden(wanted: true, modalUp: false, focused: true, overCanvas: false))
        // The canvas: 640×480 pixels; the letterbox (negative or past the edge) is off it.
        var input = WinInput()
        XCTAssertNil(input.mouseInCanvas, "no pointer seen yet")
        input.mouseMoved(x: 639, y: 479)
        XCTAssertEqual(input.mouseInCanvas.map { [$0.h, $0.v] }, [639, 479])
        input.mouseMoved(x: 640, y: 10)
        XCTAssertNil(input.mouseInCanvas)
        input.mouseMoved(x: -1, y: 10)
        XCTAssertNil(input.frontInput(capsLock: false, playing: []).mouse)
        input.mouseDown(x: 5, y: 6)
        XCTAssertTrue(input.frontInput(capsLock: false, playing: []).button)
        XCTAssertEqual(input.frontInput(capsLock: false, playing: []).mouse.map { [$0.h, $0.v] }, [5, 6])
        input.mouseUp(x: 5, y: 6)
        XCTAssertFalse(input.frontInput(capsLock: false, playing: []).button)
    }

    // MARK: 12 · the prefs and saves folder

    func testFilesFolderFromAPPDATA() throws {
        let home = URL(fileURLWithPath: "/Users/someone", isDirectory: true)
        let win = try WinFiles.defaultFolder(environment: ["APPDATA": "C:\\Users\\someone\\AppData\\Roaming"],
                                             windows: true, home: home)
        XCTAssertEqual(win.lastPathComponent, "Ferazel's Wand")
        XCTAssertEqual(win.deletingLastPathComponent().lastPathComponent, "Ambrosia Classics")
        XCTAssertTrue(win.path.hasPrefix(URL(fileURLWithPath: "C:\\Users\\someone\\AppData\\Roaming").path))
        XCTAssertThrowsError(try WinFiles.defaultFolder(environment: [:], windows: true, home: home)) { e in
            XCTAssertEqual(e as? WinFiles.FolderError, .noAppData)
            XCTAssertEqual((e as? WinFiles.FolderError)?.message,
                           "APPDATA is not set: the prefs and saved games cannot be kept")
        }
        XCTAssertThrowsError(try WinFiles.defaultFolder(environment: ["APPDATA": ""], windows: true, home: home))
        // The Mac SDL development build: its own folder, never the Mac app's.
        let mac = try WinFiles.defaultFolder(environment: [:], windows: false, home: home)
        XCTAssertEqual(mac.path, "/Users/someone/Library/Application Support/Ambrosia Classics/Ferazel's Wand (SDL)")
        // In memory: the prefs round-trip without a file.
        let files = WinFiles(prefsURL: nil, savesFolder: nil)
        XCTAssertNil(files.loadPrefs())
        try files.storePrefs(Data([1, 2, 3]))
        XCTAssertEqual(files.loadPrefs(), Data([1, 2, 3]))
        // Where a launch keeps its files: interactive — the folder; headless — only what the command line names, so
        // a `--frames` run never creates or reads a player's folder (the stub save panel gets no folder to create).
        let f = URL(fileURLWithPath: "/tmp/F", isDirectory: true)
        let live = WinFiles.locations(try WinArgs.parse([], environment: [:]), folder: f)
        XCTAssertEqual(live.prefsURL?.lastPathComponent, PrefsFile.fileName)
        XCTAssertEqual(live.savesFolder, f)
        let frames = WinFiles.locations(try WinArgs.parse(["--frames", "4"], environment: [:]), folder: f)
        XCTAssertNil(frames.prefsURL)
        XCTAssertNil(frames.savesFolder)
        XCTAssertNil(try WinFiles(prefsURL: frames.prefsURL, savesFolder: frames.savesFolder).ensureSavesFolder())
        let named = WinFiles.locations(try WinArgs.parse(["--frames", "4", "--saves", "/tmp/S", "--prefs", "/tmp/P"],
                                                         environment: [:]), folder: f)
        XCTAssertEqual(named.savesFolder?.path, "/tmp/S")
        XCTAssertEqual(named.prefsURL?.path, "/tmp/P")
        // A default save name made Windows-legal (Ruling 10).
        XCTAssertEqual(WinFiles.legalSaveName("Ferazel: a/b\\c*?\"<>|\u{1}"), "Ferazel- a-b-c-------")
        XCTAssertEqual(WinFiles.legalSaveName("Saved Game 2. . "), "Saved Game 2")
        XCTAssertEqual(WinFiles.legalSaveName("con"), "con_")
        XCTAssertEqual(WinFiles.legalSaveName("LPT9"), "LPT9_")
        XCTAssertEqual(WinFiles.legalSaveName("Ferazel's Wand Saved Game 1"), "Ferazel's Wand Saved Game 1")
    }

    // MARK: 13 · the arguments

    func testArgumentsReadAsTheMacArgumentDomain() throws {
        func parse(_ a: [String], _ env: [String: String] = [:]) throws -> WinArgs { try WinArgs.parse(a, environment: env) }
        let none = try parse([])
        XCTAssertEqual(none.settings, FerazelSettings())
        XCTAssertFalse(none.headless)
        let all = try parse(["-FerazelLevel", "3", "-ColorTieBreak", "lowest", "-MacGamma", "YES", "-FerazelMute", "true",
                             "--data", "D", "--prefs", "P", "--saves", "S", "--fonts", "F", "C:\\Saved Game 1"])
        XCTAssertEqual(all.settings.startLevel, 3)
        XCTAssertEqual(all.settings.tieBreak, .lowest)
        XCTAssertTrue(all.settings.macGamma)
        XCTAssertTrue(all.settings.mute)
        XCTAssertEqual([all.dataPath, all.prefsPath, all.savesPath, all.fontsPath, all.document],
                       ["D", "P", "S", "F", "C:\\Saved Game 1"])
        // The measured argument-domain reads (WF1): "2abc" → 0 (level 1), "y" / "t" → false, a "-" value is a new key.
        XCTAssertEqual(try parse(["-FerazelLevel", "2abc"]).settings.startLevel, 1)
        XCTAssertEqual(try parse(["-FerazelLevel", "4"]).settings.startLevel, 4)
        XCTAssertEqual(try parse(["-FerazelLevel", "9"]).settings.startLevel, 1)
        XCTAssertFalse(try parse(["-MacGamma", "y"]).settings.macGamma)
        XCTAssertFalse(try parse(["-FerazelMute", "t"]).settings.mute)
        XCTAssertTrue(try parse(["-FerazelMute", "1"]).settings.mute)
        XCTAssertEqual(try parse(["-ColorTieBreak", "LOWEST"]).settings.tieBreak, .highest)
        let dash = try parse(["-FerazelLevel", "-1", "4"])
        XCTAssertEqual(dash.defaults["FerazelLevel"], nil)
        XCTAssertEqual(dash.defaults["1"], "4")
        XCTAssertEqual(dash.settings.startLevel, 1)
        XCTAssertNil(try parse(["-MacGamma"]).defaults["MacGamma"], "a key with no value is unset")
        // --mute and FERAZEL_MUTE=1 mute; FERAZEL_MUTE=0 does not.
        XCTAssertTrue(try parse(["--mute"]).settings.mute)
        XCTAssertTrue(try parse([], ["FERAZEL_MUTE": "1"]).settings.mute)
        XCTAssertFalse(try parse([], ["FERAZEL_MUTE": "0"]).settings.mute)
        // The headless switches.
        let h = try parse(["--frames", "1437", "--dump", "m.ppm", "--keys", "k.txt", "--seed", "-5"])
        XCTAssertEqual([h.frames], [1437])
        XCTAssertEqual([h.dumpPath, h.keysPath], ["m.ppm", "k.txt"])
        XCTAssertEqual(h.seed, -5)
        XCTAssertTrue(h.headless)
        XCTAssertEqual(try parse(["--frames", "1", "--seed", "0x10"]).seed, 16)
        // Usage errors (exit 64).
        for bad in [["--frames"], ["--frames", "0"], ["--dump", "x"], ["--seed", "3"], ["--frames", "2", "--seed", "q"],
                    ["--bogus"]] {
            XCTAssertThrowsError(try parse(bad), "\(bad)")
        }
    }

    // MARK: 14 · the audio driver hint (Ruling 20) and the muted beep

    func testAudioDriverHintAndMutedBeeps() throws {
        func hint(_ a: [String], _ env: [String: String] = [:]) throws -> String? {
            WinAudioDriver.hint(arguments: try WinArgs.parse(a, environment: env), environment: env)
        }
        XCTAssertEqual(try hint(["--mute"]), "dummy")
        XCTAssertEqual(try hint([], ["FERAZEL_MUTE": "1"]), "dummy")
        XCTAssertEqual(try hint(["--mute"], ["HECTOR_SDL_AUDIO_DRIVER": "wasapi"]), "dummy")
        XCTAssertEqual(try hint(["-FerazelMute", "YES"], ["HECTOR_SDL_AUDIO_DRIVER": "wasapi"]), "dummy",
                       "the hidden switch mutes the driver too")
        XCTAssertEqual(try hint(["-FerazelMute", "y"], ["HECTOR_SDL_AUDIO_DRIVER": "wasapi"]), "wasapi", "\"y\" is false")
        XCTAssertEqual(try hint(["--data", "--mute"], ["HECTOR_SDL_AUDIO_DRIVER": "wasapi"]), "wasapi",
                       "--mute as --data's value is no switch")
        XCTAssertEqual(try hint([], ["HECTOR_SDL_AUDIO_DRIVER": "wasapi"]), "wasapi")
        XCTAssertNil(try hint([]))
        XCTAssertNil(try hint([], ["FERAZEL_MUTE": "0", "HECTOR_SDL_AUDIO_DRIVER": ""]))
        // Muted, `MessageBeep` (the injected beeper) is never called; unmuted, once per beep.
        for (args, beeps) in [(["--mute"], 0), (["-FerazelMute", "YES"], 0), ([], 1)] {
            var count = 0
            let game = WinGame(args: try WinArgs.parse(args, environment: [:]), host: WinScriptedHost(),
                               text: StubGlyphRasterizer(), files: WinFiles(prefsURL: nil, savesFolder: nil),
                               beeper: { count += 1 })
            game.beep()
            XCTAssertEqual(count, beeps, "\(args)")
        }
    }

    // MARK: 15 · the start-up check

    func testStartupNamesEveryMissingFile() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ferazel-wf3-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir.appendingPathComponent("Fonts"), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: dir.appendingPathComponent(FerazelData.appFile).path, contents: Data())
        FileManager.default.createFile(atPath: dir.appendingPathComponent("Fonts/3-9-0.fzfont").path, contents: Data())
        XCTAssertEqual(WinStartup.missingData(in: dir), [
            FerazelData.worldFile, FerazelData.backgroundsFile, FerazelData.spritesFile, FerazelData.soundsFile,
            FerazelData.titlesFile, FerazelData.musicFolder,
            "Fonts\\0-12-1.fzfont", "Fonts\\20-12-1.fzfont", "Fonts\\20-18-0.fzfont", "Fonts\\3-8-1.fzfont",
        ])
        // The repository's data and fonts are complete.
        XCTAssertEqual(WinStartup.missingData(in: try FerazelData.dataDirectory(),
                                              fonts: BakedTextTests.fontsDirectory), [])
        let text = WinStartup.dataMissingMessage(dataDirectory: dir, missing: ["Fonts\\3-8-1.fzfont"], logURL: nil)
        XCTAssertTrue(text.contains("Missing: Fonts\\3-8-1.fzfont"), text)
        XCTAssertTrue(text.hasPrefix("Ferazel's Wand cannot find its game data."), text)
        XCTAssertEqual(WinLog.fileName, "Ferazel's Wand.log")
    }

    // MARK: 16 · the shared menu rules = the Mac's old ones

    func testMenuRulesAreTheMacsOldRules() {
        /// `FerazelMenus.swift` before WF3 (`enabled` :114–121, the fall-through :132–138), transcribed as the oracle.
        func oldEnabled(_ item: PauseRun.MenuItem, _ s: MenuState, _ modalUp: Bool) -> Bool {
            guard s.menusLive, !modalUp else { return false }
            switch item {
            case .newGame, .restoreGame: return !s.paused
            case .abortGame: return s.paused
            case .quit, .about, .music, .soundEffects, .preferences: return true
            }
        }
        let oldLetters: Set<Int> = [0x2d, 0x08, 0x0c, 0x07, 0x1f, 0x0f, 0x22, 0x23]
        func oldTakes(_ item: PauseRun.MenuItem, _ code: Int, _ s: MenuState, _ modalUp: Bool) -> Bool {
            guard oldEnabled(item, s, modalUp) else { return false }
            if s.menusLive && !s.paused, oldLetters.contains(code) { return false }
            return true
        }
        XCTAssertEqual(FerazelMenuRules.mainMenuLetters, oldLetters)
        let items: [PauseRun.MenuItem] = [.about, .newGame, .restoreGame, .abortGame, .quit, .music, .soundEffects,
                                          .preferences]
        var rows = 0
        for live in [false, true] {
            for paused in [false, true] {
                for music in [false, true] {
                    let s = MenuState(menusLive: live, paused: paused, musicOn: music, soundOn: !music)
                    for modal in [false, true] {
                        for item in items {
                            XCTAssertEqual(FerazelMenuRules.enabled(item, state: s, modalUp: modal),
                                           oldEnabled(item, s, modal))
                            for code in 0..<0x80 {
                                XCTAssertEqual(FerazelMenuRules.takesKeyEquivalent(item, keyCode: code, state: s,
                                                                                    modalUp: modal),
                                               oldTakes(item, code, s, modal))
                                rows += 1
                            }
                        }
                    }
                }
            }
        }
        XCTAssertEqual(rows, 16 * 8 * 128)
        XCTAssertEqual(FerazelMenuRules.picks(menu: 129), [1: .newGame, 2: .restoreGame, 4: .abortGame, 6: .quit])
        XCTAssertEqual(FerazelMenuRules.picks(menu: 130), [1: .music, 2: .soundEffects, 4: .preferences])
    }

    // MARK: 17 · the key script

    func testKeyScriptParses() throws {
        let s = try WinKeyScript(text: """
            # comment
            10 press n
            12 down q cmd
            20 up q ctrl
            30 click 100 200
            31 move 5 6
            40 caps on
            41 caps off
            50 quit
            60 press 0x7e
            """)
        XCTAssertEqual(s.actions(at: 10), [.event(.keyDown(keyCode: 0x2D, modifiers: [], isRepeat: false))])
        XCTAssertEqual(s.actions(at: 14), [.event(.keyUp(keyCode: 0x2D))], "a press lasts one game tick (4 wakes)")
        XCTAssertEqual(s.actions(at: 12), [.event(.keyDown(keyCode: 0x0C, modifiers: .command, isRepeat: false))])
        XCTAssertEqual(s.actions(at: 20), [.event(.keyUp(keyCode: 0x0C))])
        XCTAssertEqual(s.actions(at: 30), [.event(.mouseMoved(x: 100, y: 200)), .event(.mouseDown(x: 100, y: 200))])
        XCTAssertEqual(s.actions(at: 34), [.event(.mouseUp(x: 100, y: 200))])
        XCTAssertEqual(s.actions(at: 31), [.event(.mouseMoved(x: 5, y: 6))])
        XCTAssertEqual(s.actions(at: 40), [.capsLock(true)])
        XCTAssertEqual(s.actions(at: 41), [.capsLock(false)])
        XCTAssertEqual(s.actions(at: 50), [.event(.quit)])
        XCTAssertEqual(s.actions(at: 60), [.event(.keyDown(keyCode: 0x7E, modifiers: [], isRepeat: false))])
        XCTAssertEqual(s.actions(at: 11), [])
        for bad in ["x press n", "1 press", "1 press nokey", "1 press n hyper", "1 click 1", "1 caps maybe", "1 jump"] {
            XCTAssertThrowsError(try WinKeyScript(text: bad), bad)
        }
        // The scripted clock: 240 wakes a second, a tick every 4.
        var input = WinScriptedInput(script: s)
        XCTAssertEqual(input.ticks, 1000, "the shared driver tests' first tick (Rig)")
        for _ in 0..<7 { input.advance() }
        XCTAssertEqual(input.ticks, 1001)
        XCTAssertEqual(input.seconds, 7.0 / 240.0, accuracy: 1e-12)
    }
}

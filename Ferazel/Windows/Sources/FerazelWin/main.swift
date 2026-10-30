// Ferazel's Wand for Windows (plan 2026-10-26-ferazel-windows WF3, D43): thin SDL glue over `WinGame` (FerazelWinKit),
// BTX `BubbleTroubleXWin/main.swift`'s shape. Builds and runs on the Mac too (brew sdl3) as the SDL development build;
// cross-built with tools/windows/build.sh --sdl. See `WinArgs` for the command line.
//
// --data   the folder with the six .rsrc files and "Ferazel's Wand Music" (default: Data\ beside the executable).
// --fonts  the baked faces (*.fzfont; default: <data>\Fonts — the shipped layout is Data\Fonts\ beside the exe; the Mac
//          SDL development build passes Ferazel/Windows/Resources/Fonts).
// --prefs  the prefs file (default: %APPDATA%\Ambrosia Classics\Ferazel's Wand\Ferazel's Wand Prefs on Windows;
//          ~/Library/Application Support/Ambrosia Classics/Ferazel's Wand (SDL)/ on the Mac).
// --saves  the saved games' start folder (default: the prefs folder).
// --save-as FILE / --open FILE  the Mac SDL development build's answers to the Save / Open dialogs (else cancelled);
//          Windows shows its native dialogs (comdlg32, `WinFileDialogs`). A SAVED-GAME argument (Explorer's "Open
//          with", a file dropped on the exe) is continued at the main menu's first pass, as the Mac's Finder open.
// --mute   no sound: SDL's audio driver forced to `dummy`, no audio opened, no beeps (D42, Ruling 20); also
//          FERAZEL_MUTE=1 or -FerazelMute YES.
// --frames HEADLESS MODE: N loop wakes of exactly 1/240 s (N/4 game ticks), the dummy SDL drivers forced, no audio
//          device (the shared silent mixer drains the effects), in-memory prefs unless --prefs, no pad, the seed fixed
//          (--seed N) and GetDateTime scripted; real input is ignored except the close box. --dump writes the last
//          presented 640×480 frame as binary PPM; --keys plays a WinKeyScript. Prints a "video=… audio=…" line (SDL's
//          real drivers; audio=none, as no audio subsystem starts) and a last line with the presented frame's RGBA FNV.
//
// SDL drivers: SDL_VIDEO_DRIVER / SDL_AUDIO_DRIVER, or HECTOR_SDL_VIDEO_DRIVER / HECTOR_SDL_AUDIO_DRIVER (which win;
// CrossOver strips SDL_*). Exit 0 on a normal quit, 1 on a failure, 64 on bad arguments.
//
// A GUI-subsystem .exe has no console (Ruling 18): a failure to start is shown in a message box (never headless) and
// every report also goes to "Ferazel's Wand.log" beside the prefs (`WinLog`); stderr is written with C stdio, which
// drops the text without a console (FileHandle.standardError / NSLog would trap).
//
// Windows logoff / shutdown (Ruling 9, read for D43): SDL 3.4.16's window procedure has no case for
// WM_QUERYENDSESSION (0x11) or WM_ENDSESSION (0x16) — its message switch sends both to the default branch, i.e.
// CallWindowProc(DefWindowProc …), which answers TRUE / 0 (disassembled from the shipped SDL3.dll, 2026-10-27), and
// SDL_EVENT_TERMINATING is documented for iOS / Android only. So a logoff produces no SDL event at all: no confirm is
// ever shown, Windows ends the process after WM_ENDSESSION returns, and nothing is lost (`.Quit` writes no prefs).
import FerazelCore
import FerazelRender
import FerazelWinKit
import Foundation
import HectorAudio
import HectorInput
import HectorSDL
#if os(Windows)
import WinSDK
#endif

nonisolated(unsafe) var startupLog: WinLog?

/// True once stderr is redirected into the log (test build 2, Windows, not headless): `report` then writes once.
nonisolated(unsafe) var stderrInLog = false

func report(_ message: String) {
    if !stderrInLog { fputs("Ferazel's Wand: \(message)\n", stderr) }
    startupLog?.write(message)
}

func fail(_ message: String, code: Int32 = 1) -> Never {
    report(message)
    exit(code)
}

// MARK: Arguments

let environment = ProcessInfo.processInfo.environment
let argv = Array(CommandLine.arguments.dropFirst())
let args: WinArgs
do {
    args = try WinArgs.parse(argv, environment: environment)
} catch {
    fail(error.message, code: 64)
}
let headless = args.headless

var script = WinKeyScript()
if let keysPath = args.keysPath {
    do {
        script = try WinKeyScript(text: String(contentsOfFile: keysPath, encoding: .utf8))
    } catch {
        fail("cannot read --keys \(keysPath): \(error)", code: 64)
    }
}

let executableDir = (Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0]))
    .resolvingSymlinksInPath().deletingLastPathComponent()
let dataDir = args.dataPath.map { URL(fileURLWithPath: $0, isDirectory: true) }
    ?? executableDir.appendingPathComponent("Data", isDirectory: true)
let fontsOverride = args.fontsPath.map { URL(fileURLWithPath: $0, isDirectory: true) }
let fontsDir = fontsOverride ?? dataDir.appendingPathComponent("Fonts", isDirectory: true)

// MARK: Files and the log

var folder: URL?
do {
    folder = try WinFiles.defaultFolder()
} catch {
    if !headless { report(error.message) }
}
let (prefsURL, savesFolder) = WinFiles.locations(args, folder: folder)
if let prefsURL { startupLog = WinLog(besidePrefs: prefsURL) }
let files = WinFiles(prefsURL: prefsURL, savesFolder: savesFolder)
startupLog?.write("Ferazel's Wand for Windows (Ambrosia Classics) starting")
startupLog?.write("os: \(ProcessInfo.processInfo.operatingSystemVersionString)")
startupLog?.write("executable: \(WinStartup.displayPath(Bundle.main.executableURL ?? executableDir))")
startupLog?.write("arguments: \(argv.joined(separator: " "))")
startupLog?.write("data: \(WinStartup.displayPath(dataDir)); fonts: \(WinStartup.displayPath(fontsDir))")
startupLog?.write("prefs: \(prefsURL.map(WinStartup.displayPath) ?? "in memory")")

// MARK: Crash notes (test build 2)

#if os(Windows)
// Swift's own fatal-error text goes to stderr, which a windowed program throws away: append it to the log instead.
if !headless, let logURL = startupLog?.url {
    let path = WinStartup.displayPath(logURL)
    let reopened = path.withCString(encodedAs: UTF16.self) { p in
        "a".withCString(encodedAs: UTF16.self) { m in _wfreopen(p, m, stderr) }
    }
    if reopened != nil {
        setvbuf(stderr, nil, _IONBF, 0)
        stderrInLog = true
    }
}

/// Any crash: the exception code and where (module + offset) into the log, then Windows' own handling (its crash
/// record in Event Viewer is still made).
let crashFilter: @convention(c) (UnsafeMutablePointer<EXCEPTION_POINTERS>?) -> LONG = { info in
    guard let rec = info?.pointee.ExceptionRecord?.pointee else { return 0 }
    let code = String(UInt32(truncatingIfNeeded: rec.ExceptionCode), radix: 16)
    let address = UInt(bitPattern: rec.ExceptionAddress)
    var where_ = "0x" + String(address, radix: 16)
    var module: HMODULE?
    let flags = DWORD(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS) | DWORD(GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT)
    _ = GetModuleHandleExW(flags, rec.ExceptionAddress?.assumingMemoryBound(to: WCHAR.self), &module)
    if let module {
        var buf = [WCHAR](repeating: 0, count: 1024)
        let n = Int(GetModuleFileNameW(module, &buf, DWORD(buf.count)))
        let name = String(decoding: buf[..<n], as: UTF16.self).split(separator: "\\").last.map(String.init) ?? "?"
        where_ = "\(name)+0x" + String(address &- UInt(bitPattern: module), radix: 16)
    }
    startupLog?.write("CRASH: exception 0x\(code) at \(where_) (please send this log)")
    return 0   // EXCEPTION_CONTINUE_SEARCH
}
if !headless { _ = SetUnhandledExceptionFilter(crashFilter) }
#endif

/// A failure to start: reported (stderr + log) and, unless headless, shown in a message box; exit 1.
func startupFailure(_ message: String) -> Never {
    report(WinStartup.oneLine(message))
    if !headless { _ = SDLMessageBox.show(.error, title: "Ferazel's Wand", message: message) }
    exit(1)
}

// MARK: SDL drivers (Ruling 20)

SDLHost.applyDriverOverridesFromEnvironment()
let audioHint = WinAudioDriver.hint(arguments: args, environment: environment)
if let audioHint { SDLHost.setHint("SDL_AUDIO_DRIVER", audioHint, override: true) }
if args.muted { startupLog?.write("muted: the SDL audio driver is forced to dummy; no audio opens, no beeps") }
if headless {
    // A headless run never reaches a real display or audio device, whatever the environment says.
    SDLHost.forceDummyDrivers()
}

// MARK: The data

let missing = WinStartup.missingData(in: dataDir, fonts: fontsOverride)
if !missing.isEmpty {
    startupFailure(WinStartup.dataMissingMessage(dataDirectory: dataDir, missing: missing, logURL: startupLog?.url))
}
let text: BakedTextRasterizer
do {
    text = try BakedTextRasterizer(fontsDirectory: fontsDir, log: report)
} catch {
    startupFailure(WinStartup.failureMessage("cannot load the fonts from \(WinStartup.displayPath(fontsDir))",
                                             error: error, logURL: startupLog?.url))
}

// MARK: The host

/// `WinHost` over HectorSDL. Headless, the clock and the input are the script's (`WinScriptedHost`); only the
/// window's close box gets through from SDL.
@MainActor final class SDLWinHost: WinHost {
    let sdl: SDLHost
    let scripted: WinScriptedHost?
    /// When the window was last drawn (host nanoseconds), and how many times.
    private(set) var lastDrawn: UInt64 = 0
    private(set) var draws = 0

    init(sdl: SDLHost, scripted: WinScriptedHost?) {
        self.sdl = sdl
        self.scripted = scripted
    }

    var nanoseconds: UInt64 { SDLClock.nanoseconds }
    var ticks: UInt32 { scripted?.ticks ?? WinClock.ticks(nanoseconds: SDLClock.nanoseconds) }
    var seconds: Double { scripted?.seconds ?? SDLClock.now }
    var modifiers: WinModifiers { scripted?.modifiers ?? Self.convert(sdl.modifiers) }
    var wallClock: (secondsSince1904: UInt32, ticks: UInt32) {
        let c = FastRand.systemClock()
        return (c.secondsSince1904, c.ticks)
    }

    func pollEvents(script: Bool) -> [WinEvent] {
        let real = sdl.pollEvents()
        if real.contains(.exposed) { redraw() }
        guard let scripted else { return real.compactMap(Self.convert) }
        if real.contains(.quit) { scripted.inject(.quit) }
        return scripted.pollEvents(script: script)
    }

    func present(rgba: [UInt8]) {
        sdl.present(rgba: rgba)
        lastDrawn = SDLClock.nanoseconds
        draws += 1
    }

    /// The last frame again (uncovered, resized, restored — or nothing drawn for a while).
    func redraw() {
        sdl.redraw()
        lastDrawn = SDLClock.nanoseconds
        draws += 1
    }

    func setCursorVisible(_ visible: Bool) { sdl.setCursorVisible(visible) }

    func toggleFullScreen() { sdl.setFullscreen(!sdl.isFullscreen) }

    static func convert(_ m: HostModifiers) -> WinModifiers {
        var w: WinModifiers = []
        if m.contains(.shift) { w.insert(.shift) }
        if m.contains(.command) { w.insert(.command) }
        if m.contains(.option) { w.insert(.option) }
        if m.contains(.control) { w.insert(.control) }
        if m.contains(.capsLock) { w.insert(.capsLock) }
        return w
    }

    static func convert(_ e: HostEvent) -> WinEvent? {
        switch e {
        case let .keyDown(code, _, mods, isRepeat): .keyDown(keyCode: code, modifiers: convert(mods), isRepeat: isRepeat)
        case let .keyUp(code, _): .keyUp(keyCode: code)
        case let .mouseDown(x, y): .mouseDown(x: x, y: y)
        case let .mouseUp(x, y): .mouseUp(x: x, y: y)
        case let .mouseMoved(x, y): .mouseMoved(x: x, y: y)
        case .quit: .quit
        case .focusLost: .focusLost
        case .focusGained: .focusGained
        case .textInput, .exposed: nil
        }
    }
}

/// The audio device (Ruling 13): one `SDLAudioOut` per stream on SDL's default device — the music mixer, then the
/// Sound Tool. Never asked when muted or headless (the driver does not call the mixer factory then).
@MainActor final class SDLAudioDevice: WinAudioDevice {
    private(set) var outputs: [SDLAudioOut] = []

    func open(_ source: any PCMPullSource) -> Bool {
        do {
            let out = try SDLAudioOut(source: source)
            out.start()
            outputs.append(out)
            report("audio: stream \(outputs.count) open and started")
            return true
        } catch {
            report("cannot open the audio device: \(error)")
            return false
        }
    }

    func closeAll() {
        for out in outputs { out.stop() }
        outputs = []
    }
}

// MARK: Launch

// The window (Ruling 14): the largest whole scale k ≤ 3 whose window fits the usable area (the Mac's rule); 1× headless.
let windowScale = headless ? 1 : min(3, SDLHost.initialScale(logicalWidth: WinCanvas.width,
                                                             logicalHeight: WinCanvas.height))
let sdl: SDLHost
do {
    sdl = try SDLHost(title: "Ferazel's Wand", logicalWidth: WinCanvas.width, logicalHeight: WinCanvas.height,
                      scale: windowScale)
} catch {
    startupFailure(WinStartup.failureMessage("cannot open the window", error: error, logURL: startupLog?.url))
}
let host = SDLWinHost(sdl: sdl, scripted: headless ? WinScriptedHost(script: script) : nil)
let audioDevice: SDLAudioDevice? = headless ? nil : SDLAudioDevice()

// The original's DLOG 202 / 200 drawn inside the picture (WF4a; `--frames` runs too: a scripted Return answers them and
// the dump shows them). Their `SysBeep` (a click outside) is the beeper below, through the driver's mute gate.
let game = WinGame(args: args, host: host, text: text, files: files, dialogs: DialogSystem(text: text),
                   panels: WinFileDialogs.panels(args, log: report), audio: audioDevice,
                   beeper: {
                       #if os(Windows)
                       _ = MessageBeep(UINT(MB_OK))   // `SysBeep`; the driver never calls this when muted
                       #endif                         // the Mac SDL development build: silent
                   },
                   log: report, padSource: headless ? nil : { sdl.padState() },
                   trace: headless ? nil : { startupLog?.write($0) })
host.present(rgba: [UInt8](repeating: 0, count: WinCanvas.width * WinCanvas.height * 4).enumerated()
    .map { $0.offset % 4 == 3 ? 0xff : 0 })                               // black until the flow first presents
// A quit that arrives before the flow exists ends at once (the Mac's `applicationShouldTerminate` before launch). Each
// scripted event reaches the game once, after the boot: this pre-boot poll takes only the system's events
// (`WinGame.step`, `WinScriptedHost.pollEvents(script:)`).
game.step()
if game.finished {
    startupLog?.write("quit before the game started")
    exit(0)
}
do {
    try game.boot(dataDirectory: dataDir)
} catch {
    startupFailure(WinStartup.failureMessage("cannot load the original data from \(WinStartup.displayPath(dataDir))",
                                             error: error, logURL: startupLog?.url))
}
// SDL's real drivers (BTX `main.swift`). The audio subsystem starts only with an output: headless and muted runs open
// none (HectorSDL has no way to start the subsystem alone), so they print `audio=none` — nothing was started.
let audioName = audioDevice?.outputs.isEmpty == false ? SDLHost.currentAudioDriver : "none"
let launchLine = "window: scale \(windowScale), video=\(SDLHost.currentVideoDriver) audio=\(audioName)"
startupLog?.write(launchLine)
startupLog?.write(sdl.gamepadsAvailable ? "gamepads: \(sdl.connectedGamepadCount) connected" : "gamepads: unavailable")

// MARK: The loop

if let frames = args.frames {
    print("FerazelWin: \(launchLine)")
    let rgba = game.runFrames(frames, scripted: host.scripted)   // shared with WinReferenceFramesTests
    if let dumpPath = args.dumpPath {
        do {
            try Data(WinGame.ppm(rgba: rgba)).write(to: URL(fileURLWithPath: dumpPath))
        } catch {
            fail("cannot write \(dumpPath): \(error)")
        }
    }
    let fnv = "0x" + String(WinGame.fnv1a64(rgba), radix: 16)
    print("FerazelWin: \(frames) frames, \(game.flowSteps) ticks, state \(game.stateDescription), "
          + "presented RGBA FNV \(fnv)\(args.dumpPath.map { ", wrote \($0)" } ?? "")")
} else {
    // While the window is dragged or resized, Windows' modal move/size loop blocks the poll inside `step()`; SDL's
    // live-resize exposes come from inside it, and the game keeps its time and its picture from there (Ruling 18).
    sdl.setLiveRedrawHandler {
        MainActor.assumeIsolated {
            let drawn = host.draws
            game.liveStep()
            if host.draws == drawn { host.redraw() }        // nothing new: the last frame at the window's new size
        }
    }
    // Wake every 1/240 s (Ruling 8); a late wake is not caught up (the flow runs once per new tick anyway).
    let period: UInt64 = 1_000_000_000 / 240
    var next = SDLClock.nanoseconds
    while !game.finished {
        game.step()
        let now = SDLClock.nanoseconds
        if now &- host.lastDrawn > 250_000_000 { host.redraw() }   // never leave the window undrawn for long
        next += period
        if next > now { SDLClock.sleepPrecise(nanoseconds: next - now) } else { next = now }
    }
    sdl.setLiveRedrawHandler(nil)
}
game.shutDown()
audioDevice?.closeAll()
startupLog?.write("quit normally")
exit(game.exitCode)

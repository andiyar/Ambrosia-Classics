// Bubble Trouble X for Windows (plan 2026-10-06-btx-windows W4): thin SDL glue over `WinGameDriver` (BTXWinKit).
// Builds and runs on the Mac too (brew sdl3) for development; cross-built with tools/windows/build.sh --sdl.
//
//   BubbleTroubleXWin [--data DIR] [--prefs FILE] [--scale N] [--name NAME]
//                     [--frames N [--dump FILE.ppm] [--keys SCRIPT]]
//
// --data    the folder with the five .rsrc files, Fonts/ and Decoded/ (default: Data/ beside the executable).
// --prefs   the prefs file (default: %APPDATA%\Ambrosia Classics\Bubble Trouble X\Prefs.bin on Windows;
//           ~/Library/Application Support/Ambrosia Classics/Bubble Trouble X (SDL)/Prefs.bin on the Mac).
// --scale   window size multiple of the 640×500 canvas (default 1; the window is resizable, integer-fit).
// --name    info message 2's "Registered To:" name (default: the account's full name).
// --frames  HEADLESS SMOKE MODE: run N main-loop iterations on a fixed-step clock (one TickCount, 1/60 s, each —
//           reproducible on any machine), then write the last presented 640×500 canvas to --dump as binary PPM and
//           quit with exit 0. The audio driver is forced to SDL's `dummy` (never a real device from automation);
//           prefs live in memory unless --prefs is given; the name is "Player" and the date 3 March unless given;
//           focus events are ignored. --keys plays a timed input script (format: BTXWinKit `WinKeyScript`).
//
// SDL drivers: SDL_VIDEO_DRIVER / SDL_AUDIO_DRIVER, or HECTOR_SDL_VIDEO_DRIVER / HECTOR_SDL_AUDIO_DRIVER (which win;
// CrossOver strips SDL_* — tools/windows/README.md). Exit 0 on a normal quit, 1 on a failure, 64 on bad arguments.
import BTXWinKit
import BubbleTroubleCore
import CSDL3
import Foundation
import HectorAudio
import HectorSDL

func report(_ message: String) {
    FileHandle.standardError.write(Data("Bubble Trouble X: \(message)\n".utf8))
}

func fail(_ message: String, code: Int32 = 1) -> Never {
    report(message)
    exit(code)
}

// MARK: Arguments

var dataPath: String?
var prefsPath: String?
var scale = 1
var name: String?
var frames: Int?
var dumpPath: String?
var keysPath: String?
var args = CommandLine.arguments.dropFirst()
@MainActor func value(_ flag: String) -> String {
    guard let v = args.popFirst() else { fail("\(flag) needs a value", code: 64) }
    return v
}
while let arg = args.popFirst() {
    switch arg {
    case "--data": dataPath = value(arg)
    case "--prefs": prefsPath = value(arg)
    case "--scale":
        guard let v = Int(value(arg)), (1...8).contains(v) else { fail("--scale needs 1…8", code: 64) }
        scale = v
    case "--name": name = value(arg)
    case "--frames":
        guard let v = Int(value(arg)), v > 0 else { fail("--frames needs a count > 0", code: 64) }
        frames = v
    case "--dump": dumpPath = value(arg)
    case "--keys": keysPath = value(arg)
    default:
        fail("usage: BubbleTroubleXWin [--data DIR] [--prefs FILE] [--scale N] [--name NAME] "
             + "[--frames N [--dump FILE.ppm] [--keys SCRIPT]]", code: 64)
    }
}
if frames == nil && (dumpPath != nil || keysPath != nil) { fail("--dump and --keys need --frames", code: 64) }
let headless = frames != nil

var script = WinKeyScript()
if let keysPath {
    do {
        script = try WinKeyScript(text: String(contentsOfFile: keysPath, encoding: .utf8))
    } catch {
        fail("cannot read --keys \(keysPath): \(error)", code: 64)
    }
}

let executableDir = (Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0]))
    .resolvingSymlinksInPath().deletingLastPathComponent()
let dataDir = dataPath.map { URL(fileURLWithPath: $0, isDirectory: true) }
    ?? executableDir.appendingPathComponent("Data", isDirectory: true)

let prefsBacking: any BTXPrefsBacking
if let prefsPath {
    prefsBacking = WinPrefsFile(fileURL: URL(fileURLWithPath: prefsPath), log: report)
} else if headless {
    prefsBacking = WinMemoryPrefs()
} else if let url = WinPrefsFile.defaultURL() {
    prefsBacking = WinPrefsFile(fileURL: url, log: report)
} else {
    report("no APPDATA: the prefs will not be kept")
    prefsBacking = WinMemoryPrefs()
}

// MARK: SDL

SDLHost.applyDriverOverridesFromEnvironment()
if headless {
    // Belt and braces: a smoke never opens a real audio device, whatever the environment says.
    _ = SDL_SetHintWithPriority("SDL_AUDIO_DRIVER", "dummy", SDL_HINT_OVERRIDE)
}

/// `WinHost` over HectorSDL. In headless mode the clock and the input are the script's (`WinScriptedInput`).
final class SDLWinHost: WinHost {
    let sdl: SDLHost
    var scripted: WinScriptedInput?
    var lastFrame: WinFrame?
    var quitRequested = false
    private var capsLock = false

    init(sdl: SDLHost, scripted: WinScriptedInput?) {
        self.sdl = sdl
        self.scripted = scripted
    }

    var nanoseconds: UInt64 { scripted?.nanoseconds ?? SDL_GetTicksNS() }

    var modifiers: WinModifiers {
        if let scripted { return scripted.modifiers }
        return Self.convert(sdl.modifiers)
    }

    func pollEvents() -> [WinEvent] {
        let real = sdl.pollEvents()
        guard scripted != nil else { return real.compactMap(Self.convert) }
        // Headless: only the window's close box gets through; the rest is the script's.
        var events: [WinEvent] = real.contains(.quit) ? [.quit] : []
        events += scripted!.events()
        return events
    }

    func present(_ frame: WinFrame) {
        lastFrame = frame
        sdl.present(rgba: frame.rgba)
    }

    func setCursorVisible(_ visible: Bool) {
        _ = visible ? SDL_ShowCursor() : SDL_HideCursor()
    }

    /// The hand (`crsr 200`) is not built yet: the system arrow stays (recorded by the driver).
    func setCursor(_ cursor: WinCursor) {}

    /// The Mac warps the pointer to the screen's centre and decouples it in play; HectorSDL has no capture call
    /// yet, so the hidden pointer stays free (the game reads no mouse in play).
    func setMouseCaptured(_ captured: Bool) {}

    func restoreMousePosition() {}

    /// SDL has no system beep; `_SysBeep` is silent here (recorded by the driver).
    func beep() {}

    func quit() { quitRequested = true }

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
        case let .keyDown(code, chars, mods, isRepeat):
            .keyDown(keyCode: code, characters: chars, modifiers: convert(mods), isRepeat: isRepeat)
        case let .keyUp(code, mods): .keyUp(keyCode: code, modifiers: convert(mods))
        case let .mouseDown(x, y): .mouseDown(x: x, y: y)
        case let .mouseUp(x, y): .mouseUp(x: x, y: y)
        case let .mouseMoved(x, y): .mouseMoved(x: x, y: y)
        case .quit: .quit
        case .focusLost: .focusLost
        case .focusGained: .focusGained
        }
    }
}

// MARK: Launch

let assets: WinGameAssets
do {
    assets = try WinGameAssets(dataDirectory: dataDir)
} catch {
    fail("cannot load the original data from \(dataDir.path): \(error)")
}

let sdl: SDLHost
do {
    sdl = try SDLHost(title: "Bubble Trouble X", logicalWidth: WinCanvas.width, logicalHeight: WinCanvas.height,
                      scale: scale)
} catch {
    fail("cannot open the window: \(error)")
}
let host = SDLWinHost(sdl: sdl, scripted: headless ? WinScriptedInput(script: script) : nil)

// 4 effect voices (`ST_Open(4,0)`) + `gMusicChannel`, mixed in software and pulled by SDL's audio thread.
let mixer = PCMMixer(voices: WinAudio.effectVoices + 1, outputRate: 48_000)
var audioOut: SDLAudioOut?
do {
    audioOut = try SDLAudioOut(mixer: mixer)
    audioOut?.start()
} catch {
    report("no sound — cannot open the audio device: \(error)")
}
let output: any WinAudioOutput = audioOut != nil ? mixer : SilentWinAudioOutput()

func accountName() -> String {
    let full = NSFullUserName()
    return full.isEmpty ? (ProcessInfo.processInfo.environment["USERNAME"] ?? "") : full
}
let registeredName: String = name ?? (headless ? "Player" : accountName())
var today: () -> (month: Int, day: Int) = FrontEnd.systemToday
if headless { today = { (month: 3, day: 3) } }
let options = WinGameDriver.Options(registeredName: registeredName, today: today, log: report)

let driver: WinGameDriver
do {
    driver = try WinGameDriver(assets: assets, host: host, audioOutput: output, prefsBacking: prefsBacking,
                               dialogs: WinDialogsStub(), options: options)
} catch {
    fail("cannot start: \(error)")
}
driver.start()

// MARK: The loop

if let frames {
    for _ in 0..<frames where !driver.finished {
        driver.step()
        host.scripted?.advance()
    }
    let frame = host.lastFrame ?? driver.currentFrame
    if let dumpPath {
        do {
            try Data(frame.ppm).write(to: URL(fileURLWithPath: dumpPath))
        } catch {
            fail("cannot write \(dumpPath): \(error)")
        }
    }
    let video = SDL_GetCurrentVideoDriver().map { String(cString: $0) } ?? "?"
    let audio = SDL_GetCurrentAudioDriver().map { String(cString: $0) } ?? "?"
    print("BubbleTroubleXWin: \(frames) frames (tick \(driver.ticksNow())), phase \(driver.frontEnd.phase), "
          + "video=\(video) audio=\(audio)\(dumpPath.map { ", wrote \($0)" } ?? "")")
} else {
    while !driver.finished {
        driver.step()
        // Sleep until the running clock's next fire, at most 1 ms at a time so input stays prompt.
        let now = host.nanoseconds
        if let next = driver.nextDeadline, next > now {
            SDL_DelayNS(min(next - now, 1_000_000))
        } else if driver.nextDeadline == nil {
            SDL_DelayNS(1_000_000)
        }
    }
}
audioOut?.stop()
exit(0)

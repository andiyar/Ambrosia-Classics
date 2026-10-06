// Bubble Trouble X for Windows (plan 2026-10-06-btx-windows W4, W4.5): thin SDL glue over `WinGameDriver` (BTXWinKit).
// Builds and runs on the Mac too (brew sdl3) for development; cross-built with tools/windows/build.sh --sdl.
//
//   BubbleTroubleXWin [--data DIR] [--prefs FILE] [--scale N] [--name NAME] [--auto-dialogs]
//                     [--frames N [--dump FILE.ppm] [--keys SCRIPT]]
//
// --data    the folder with the five .rsrc files, Fonts/ and Decoded/ (default: Data/ beside the executable).
// --prefs   the prefs file (default: %APPDATA%\Ambrosia Classics\Bubble Trouble X\Prefs.bin on Windows;
//           ~/Library/Application Support/Ambrosia Classics/Bubble Trouble X (SDL)/Prefs.bin on the Mac).
// --scale   window size multiple of the 640×500 canvas (default: the largest that fits the screen — 2 on 1080p;
//           the window is resizable, integer-fit; Window ▸ Zoom toggles 1× / the largest).
// --name    info message 2's "Registered To:" name (default: the account's full name).
// --auto-dialogs  every dialog answers at once with its default (Cancel, prefs unchanged, the default name) instead
//           of showing — the scripted dialog policy (`WinAutoDialogs`).
// --frames  HEADLESS SMOKE MODE: run N main-loop iterations on a fixed-step clock (one TickCount, 1/60 s, each —
//           reproducible on any machine), then write the last presented canvas (640×500; 640×480 in full screen) to
//           --dump as binary PPM and quit with exit 0. The audio driver is forced to SDL's `dummy` (never a real
//           device from automation); prefs live in memory unless --prefs is given; the name is "Player" and the date
//           3 March unless given; the window opens at 1×; real input is ignored except the close box. --keys plays a
//           timed input script (format: BTXWinKit `WinKeyScript` — keys, clicks, pointer moves, typed text).
//
// SDL drivers: SDL_VIDEO_DRIVER / SDL_AUDIO_DRIVER, or HECTOR_SDL_VIDEO_DRIVER / HECTOR_SDL_AUDIO_DRIVER (which win;
// CrossOver strips SDL_* — tools/windows/README.md). Exit 0 on a normal quit, 1 on a failure, 64 on bad arguments.
import BTXWinKit
import BubbleTroubleCore
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
var scale: Int?
var name: String?
var frames: Int?
var dumpPath: String?
var keysPath: String?
var autoDialogs = false
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
    case "--auto-dialogs": autoDialogs = true
    case "--frames":
        guard let v = Int(value(arg)), v > 0 else { fail("--frames needs a count > 0", code: 64) }
        frames = v
    case "--dump": dumpPath = value(arg)
    case "--keys": keysPath = value(arg)
    default:
        fail("usage: BubbleTroubleXWin [--data DIR] [--prefs FILE] [--scale N] [--name NAME] [--auto-dialogs] "
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
    SDLHost.setHint("SDL_AUDIO_DRIVER", "dummy", override: true)
}

/// `WinHost` over HectorSDL. In headless mode the clock and the input are the script's (`WinScriptedInput`).
/// The canvas is 640×500 (menu strip + game screen) windowed and 640×480 in full screen; mouse positions go back to
/// the driver in 640×500 window-canvas coordinates either way.
final class SDLWinHost: WinHost {
    let sdl: SDLHost
    var scripted: WinScriptedInput?
    var lastFrame: WinFrame?
    var quitRequested = false
    /// When the window was last drawn (present or redraw), host nanoseconds.
    private(set) var lastDrawn: UInt64 = 0

    init(sdl: SDLHost, scripted: WinScriptedInput?) {
        self.sdl = sdl
        self.scripted = scripted
    }

    var nanoseconds: UInt64 { scripted?.nanoseconds ?? SDLClock.nanoseconds }

    var modifiers: WinModifiers {
        if let scripted { return scripted.modifiers }
        return Self.convert(sdl.modifiers)
    }

    /// The canvas rows above the game screen that the window does not show (full screen hides the menu strip).
    private var hiddenRows: Int { WinCanvas.height - sdl.logicalHeight }

    func pollEvents() -> [WinEvent] {
        let real = sdl.pollEvents()
        if real.contains(.exposed) { redraw() }
        guard scripted != nil else { return real.compactMap(convert) }
        // Headless: only the window's close box gets through; the rest is the script's.
        var events: [WinEvent] = real.contains(.quit) ? [.quit] : []
        events += scripted!.events()
        return events
    }

    func present(_ frame: WinFrame) {
        lastFrame = frame
        if frame.width != sdl.logicalWidth || frame.height != sdl.logicalHeight {
            do {
                try sdl.setLogicalSize(width: frame.width, height: frame.height)
            } catch {
                report("cannot resize the canvas: \(error)")
                return
            }
        }
        sdl.present(rgba: frame.rgba)
        lastDrawn = nanoseconds
    }

    /// The last frame again (the window was uncovered, resized or restored — or nothing was drawn for a while).
    func redraw() {
        sdl.redraw()
        lastDrawn = nanoseconds
    }

    func setCursorVisible(_ visible: Bool) { sdl.setCursorVisible(visible) }

    /// The hand (`crsr 200`) is not built yet: the system arrow stays (recorded by the driver).
    func setCursor(_ cursor: WinCursor) {}

    /// The Mac warps the pointer to the screen's centre and decouples it in play; HectorSDL has no capture call
    /// yet, so the hidden pointer stays free (the game reads no mouse in play).
    func setMouseCaptured(_ captured: Bool) {}

    func restoreMousePosition() {}

    /// SDL has no system beep; `_SysBeep` is silent here (recorded by the driver).
    func beep() {}

    func quit() { quitRequested = true }

    func setFullScreen(_ on: Bool) -> Bool {
        sdl.setFullscreen(on)
        return sdl.isFullscreen
    }

    func minimize() { sdl.minimize() }

    /// Window ▸ Zoom: 1× ↔ the largest integer scale that fits the screen.
    func zoom() {
        guard !sdl.isFullscreen else { return }
        let best = SDLHost.initialScale(logicalWidth: WinCanvas.width, logicalHeight: WinCanvas.height)
        let current = sdl.windowSize.width / WinCanvas.width
        sdl.setWindowScale(current > 1 ? 1 : best)
        redraw()
    }

    func setTextInput(_ on: Bool) {
        guard scripted == nil else { return }
        if on { sdl.startTextInput() } else { sdl.stopTextInput() }
    }

    static func convert(_ m: HostModifiers) -> WinModifiers {
        var w: WinModifiers = []
        if m.contains(.shift) { w.insert(.shift) }
        if m.contains(.command) { w.insert(.command) }
        if m.contains(.option) { w.insert(.option) }
        if m.contains(.control) { w.insert(.control) }
        if m.contains(.capsLock) { w.insert(.capsLock) }
        return w
    }

    func convert(_ e: HostEvent) -> WinEvent? {
        let dy = hiddenRows
        switch e {
        case let .keyDown(code, chars, mods, isRepeat):
            return .keyDown(keyCode: code, characters: chars, modifiers: Self.convert(mods), isRepeat: isRepeat)
        case let .keyUp(code, mods): return .keyUp(keyCode: code, modifiers: Self.convert(mods))
        case let .mouseDown(x, y): return .mouseDown(x: x, y: y + dy)
        case let .mouseUp(x, y): return .mouseUp(x: x, y: y + dy)
        case let .mouseMoved(x, y): return .mouseMoved(x: x, y: y + dy)
        case .quit: return .quit
        case .focusLost: return .focusLost
        case .focusGained: return .focusGained
        case let .textInput(text): return .textInput(text)
        case .exposed: return nil
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

let windowScale = scale ?? (headless ? 1 : SDLHost.initialScale(logicalWidth: WinCanvas.width,
                                                                 logicalHeight: WinCanvas.height))
let sdl: SDLHost
do {
    sdl = try SDLHost(title: "Bubble Trouble X", logicalWidth: WinCanvas.width, logicalHeight: WinCanvas.height,
                      scale: windowScale)
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
                               dialogs: autoDialogs ? WinAutoDialogs() : nil, options: options)
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
    print("BubbleTroubleXWin: \(frames) frames (tick \(driver.ticksNow())), phase \(driver.frontEnd.phase), "
          + "dialog \(driver.dialogs.isShowing), menu \(driver.tracker.openMenu.map(String.init) ?? "-"), "
          + "video=\(SDLHost.currentVideoDriver) audio=\(SDLHost.currentAudioDriver)"
          + "\(dumpPath.map { ", wrote \($0)" } ?? "")")
} else {
    while !driver.finished {
        driver.step()
        let now = host.nanoseconds
        // Never leave the window undrawn for long (an expose the platform did not report).
        if now &- host.lastDrawn > 250_000_000 { host.redraw() }
        // Sleep until the next fire, at most 1 ms at a time so input stays prompt.
        if let next = driver.nextDeadline, next > now {
            SDLClock.sleep(nanoseconds: min(next - now, 1_000_000))
        } else if driver.nextDeadline == nil {
            SDLClock.sleep(nanoseconds: 1_000_000)
        }
    }
}
audioOut?.stop()
exit(0)

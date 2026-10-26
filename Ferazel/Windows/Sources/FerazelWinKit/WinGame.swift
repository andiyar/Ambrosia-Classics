import FerazelCore
import FerazelRender
import Foundation
import HectorInput

/// What `WinGame` needs from the platform (plan WF3): a clock, the modifier state, the event queue, the window. The
/// executable implements it over HectorSDL; the tests and the `--frames` runs over `WinScriptedInput`. No SDL types.
@MainActor public protocol WinHost: AnyObject {
    /// TickCount now (1/60 s, absolute, wrapping at 2³² like `ShellClock.ticks()`).
    var ticks: UInt32 { get }
    /// Seconds on a monotonic clock (the pad's hold timer; only differences matter).
    var seconds: Double { get }
    /// The modifier keys now (Caps Lock = its lock state), read once per tick like `GetKeys`.
    var modifiers: WinModifiers { get }
    /// The wall clock the interactive game seeds from and reads `GetDateTime` from (`FastRand.systemClock`); never
    /// read in `--frames` mode (Ruling 20).
    var wallClock: (secondsSince1904: UInt32, ticks: UInt32) { get }
    /// Drains the input queue. `script` false (before the boot, when no shortcuts or menu state exist yet): only the
    /// system's events (the close box); a scripted host keeps the script's for the first poll that takes it, so each
    /// scripted event reaches the game exactly once and only once the game is booted.
    func pollEvents(script: Bool) -> [WinEvent]
    /// Shows one 640×480 frame of R, G, B, A bytes.
    func present(rgba: [UInt8])
    func setCursorVisible(_ visible: Bool)
    /// Full screen on / off (Alt+Enter).
    func toggleFullScreen()
}

/// TickCount from monotonic nanoseconds without overflow, wrapping at 2³² (BTX `WinClock`).
/// The canvas: the 640×480 game screen alone (D21) — `FerazelDriver.width` × `height`, public for the executable.
public enum WinCanvas {
    public static let width = 640
    public static let height = 480
}

public enum WinClock {
    public static func ticks(nanoseconds n: UInt64) -> UInt32 {
        let whole = n / 1_000_000_000, rest = n % 1_000_000_000
        return UInt32(truncatingIfNeeded: whole &* 60 &+ rest * 60 / 1_000_000_000)
    }
}

/// Ferazel's Wand on Windows (plan WF3, D43 Rulings 5–14, 18–20): the Mac's `FerazelController` without AppKit, over
/// the shared `FerazelDriver`. One `step()` per loop wake (240 a second): the queued events (keys routed to the Ctrl
/// shortcuts, Alt+Enter, a dialog or the held keys; the pointer; the focus; the quit), then — at most once per new
/// 60 Hz tick, never while a dialog or a file dialog is up (the Mac's `idleFired`) — the flow's tick with the polled
/// input and the pad, the present, the requests (cursor; menu-bar requests ignored, D21; the menu state → the
/// shortcuts; dialogs → `WinDialogs`; file panels → `WinFilePanels`, after the tick; quit), the boot's loads.
///
/// Headless (`--frames`, Ruling 20): the driver's silent mixer (no device), the seed `--seed` or `headlessSeed`, and
/// `GetDateTime` = `headlessDateTime` + the elapsed ticks / 60 — the host's wall clock is never read — so the same
/// run gives the same frames on the Mac SDL build and on Windows, at any hour.
@MainActor public final class WinGame {
    /// WF1's test seed (the shared driver tests' `Rig.seed`): the `--frames` default.
    public static let headlessSeed: Int32 = 0x1234_5678
    /// The `--frames` runs' `GetDateTime` at the first tick (the driver tests' `Rig.dateTime`).
    public static let headlessDateTime: UInt32 = 0xBA00_0000

    public let args: WinArgs
    let driver: FerazelDriver
    private let host: any WinHost
    private let files: WinFiles
    private let dialogs: any WinDialogs
    private let panels: any WinFilePanels
    private let padSource: (() -> ShellPadState)?
    private let log: (String) -> Void
    private var input = WinInput()
    private var shortcuts = WinShortcuts(entries: [])
    /// What the flow last sent (`.showMenuBarItems`): the shortcuts take by it.
    private(set) var menuState = MenuState(menusLive: false, paused: false, musicOn: true, soundOn: true)
    /// The tick the flow last ran.
    private(set) var lastTick: UInt32?
    /// The tick the pad was last polled while a dialog held the flow.
    private var lastModalPoll: UInt32?
    /// TickCount when this game was made (the headless `GetDateTime` counts from it).
    private let startTick: UInt32
    private var wantsCursorHidden = false
    private var cursorHidden = false
    private var panelUp = false
    private enum Panel { case save(PutFileRequest), open(String) }
    private var pendingPanel: Panel?
    /// Inside `step()`'s host poll (`liveStep` may run there) / inside `liveStep`.
    private var polling = false
    private var inLiveStep = false

    /// The flow's `.quit` came, a quit arrived before the flow existed, or a draw failed.
    public private(set) var finished = false
    public private(set) var exitCode: Int32 = 0
    /// The last frame presented (R, G, B, A; 640×480), nil before the first.
    public private(set) var lastPresented: [UInt8]?
    /// Flow ticks run so far.
    public private(set) var flowSteps = 0
    /// The seed the flow got (nil before the boot).
    public private(set) var seedUsed: Int32?
    /// The last tick's output.
    private(set) var lastOutput = FrontOutput()
    /// Every Ctrl shortcut taken, in order (tests).
    private(set) var shortcutsTaken: [PauseRun.MenuItem] = []

    /// - Parameters:
    ///   - text: the baked fonts (`BakedTextRasterizer`).
    ///   - audio: where the music and the effects play (nil: silent); never opened when muted or headless.
    ///   - beeper: `MessageBeep` (never called when muted).
    ///   - padSource: every connected pad, unioned (nil: no pad — headless runs).
    public init(args: WinArgs, host: any WinHost, text: any TextRasterizer, files: WinFiles,
                dialogs: any WinDialogs = WinStubDialogs(), panels: any WinFilePanels = WinStubFilePanels(),
                audio: (any WinAudioDevice)? = nil, beeper: @escaping () -> Void = {},
                log: @escaping (String) -> Void = { _ in }, padSource: (() -> ShellPadState)? = nil) {
        self.args = args
        self.host = host
        self.files = files
        self.dialogs = dialogs
        self.panels = panels
        self.padSource = padSource
        self.log = log
        startTick = host.ticks
        let headless = args.headless
        let seed = args.seed ?? Self.headlessSeed
        // The closures reach this game through a box filled below (they are made before `self` is whole).
        let box = Box()
        driver = FerazelDriver(
            settings: args.settings, text: text, files: files,
            seed: {
                if headless { return seed }
                let c = host.wallClock
                return FastRand.clockSeed(secondsSince1904: c.secondsSince1904, ticks: c.ticks)
            },
            // `KeyTranslate` (the Options key names): the US layout (◇ the Mac asks the live layout, Ruling 6).
            keyCharacter: { code in ShellKeyCharacters.characters(forKeyCode: UInt16(bitPattern: code)) },
            dateTime: { MainActor.assumeIsolated { box.game?.dateTimeNow() ?? Self.headlessDateTime } },
            mixer: { audio.flatMap { WinMixer(device: $0, log: log) } },
            beeper: beeper, log: log, headless: headless)
        box.game = self
    }

    private final class Box: @unchecked Sendable {
        weak var game: WinGame?
    }

    /// The flow (nil before `boot`).
    var flow: GameFlow! { driver.flow }

    /// `GetDateTime`: headless, `headlessDateTime` + the ticks since this game was made / 60; else the wall clock.
    public func dateTimeNow() -> UInt32 {
        guard args.headless else { return host.wallClock.secondsSince1904 }
        return Self.headlessDateTime &+ (host.ticks &- startTick) / 60
    }

    /// The game half of the launch (`FerazelDriver.boot`), the shortcuts from the MENU resources, then the saved game
    /// the command line named (the Mac's Finder open). A throw is the executable's to report.
    public func boot(dataDirectory: URL) throws {
        try driver.boot(dataDirectory: dataDirectory)
        seedUsed = driver.flow.rng.seed
        shortcuts = WinShortcuts(resources: driver.resources)
        if let path = args.document {
            let url = URL(fileURLWithPath: path)
            driver.flow.openDocument(SavedGameRef(url: url, displayName: url.lastPathComponent))
        }
    }

    // MARK: The loop

    /// One loop wake: the queued events, then the flow's tick when a new one is due.
    public func step() {
        guard !finished else { return }
        polling = true
        let events = host.pollEvents(script: driver.flow != nil)
        polling = false
        for e in events {
            guard !finished else { return }   // a live redraw inside the poll may have ended the game
            handle(e)
        }
        guard !finished else { return }
        runDueTick()
    }

    /// The window is being dragged or resized and Windows' modal move/size loop blocks the poll inside `step()`
    /// (HectorSDL's live-redraw handler calls this from inside `pollEvents`): the tick if one is due, so the game
    /// keeps its time and the window its picture (BTX `main.swift`). Nothing outside `step()`'s poll, never re-entered.
    public func liveStep() {
        guard polling, !inLiveStep, !finished else { return }
        inLiveStep = true
        defer { inLiveStep = false }
        runDueTick()
    }

    /// A dialog or a file dialog is up: the flow does not tick (BTX D13.6 precedent).
    private var modalUp: Bool { panelUp || dialogs.isShowing }

    private func runDueTick() {
        guard driver.flow != nil else { return }
        defer { updateCursor() }
        let now = host.ticks
        if modalUp {
            // A dialog's 1/60 s null timer: the pad's only poll (the Mac's `pollPadInDialog`).
            if dialogs.isShowing, now != lastModalPoll {
                lastModalPoll = now
                pollPad()
            }
            return
        }
        guard now != lastTick else { return }
        lastTick = now
        pollPad()
        let polled = input.frontInput(capsLock: host.modifiers.contains(.capsLock), playing: driver.playingSounds())
        let out: FrontOutput
        do {
            out = try driver.tick(now: now, input: polled)
        } catch {
            log("the screen could not be drawn: \(error)")
            finish(1)
            return
        }
        flowSteps += 1
        lastOutput = out
        if out.present { present() }
        for request in out.requests {
            honour(request)
            if finished { return }
        }
        driver.serviceLoad()
        runPendingPanel()
    }

    /// The pad (D37): the layout for this poll (the live prefs' keys, the flow's pad context, a dialog up), merged
    /// into the held keys and Caps Lock at the tick; with a dialog up its Return / Esc go to the dialog.
    private func pollPad() {
        guard let padSource, let flow = driver.flow else { return }
        let keys = flow.levelRun?.prefs.keys ?? flow.toggles.live.keys
        let dialogUp = dialogs.isShowing
        let mapping = FerazelPadLayout.mapping(keys: keys, context: flow.padContext, dialogUp: dialogUp)
        let frame = input.pollPad(padSource(), mapping: mapping, now: host.seconds)
        guard dialogUp else { return }
        for code in frame.pressed where code == FerazelPadLayout.returnKey || code == FerazelPadLayout.escapeKey {
            dialogs.padKeyDown(code)
        }
    }

    private func present() {
        let rgba = driver.presentRGBA()
        lastPresented = rgba
        host.present(rgba: rgba)
    }

    /// Shows the last frame again (Alt+Enter; the executable's redraws use the host's own copy).
    private func represent() {
        guard let lastPresented else { return }
        host.present(rgba: lastPresented)
    }

    // MARK: Events

    private func handle(_ event: WinEvent) {
        switch event {
        case let .keyDown(code, mods, isRepeat):
            switch input.keyDown(code, modifiers: mods, isRepeat: isRepeat, shortcuts: shortcuts, menus: menuState,
                                 modalUp: modalUp, dialogUp: dialogs.isShowing) {
            case .held, .ignored: break
            case .fullScreen:
                guard !isRepeat else { break }
                host.toggleFullScreen()
                represent()
            case .shortcut(let item):
                // An autorepeat picks again, as AppKit's menu key equivalents do on the Mac (`FerazelMenus` takes
                // every key-down `menuHasKeyEquivalent` is asked about, repeats included).
                shortcutsTaken.append(item)
                driver.flow?.menuChosen(item)
            case .dialog:
                dialogs.keyDown(code, modifiers: mods)
            }
        case let .keyUp(code):
            input.keyUp(code)
        case let .mouseMoved(x, y): input.mouseMoved(x: x, y: y)
        case let .mouseDown(x, y): input.mouseDown(x: x, y: y)
        case let .mouseUp(x, y): input.mouseUp(x: x, y: y)
        case .quit:
            // The Mac's `applicationShouldTerminate` (D40): before the flow exists the quit ends at once; else the
            // flow's `systemQuit` — a level running free asks "Are you sure you want to quit?", elsewhere the quit
            // event is queued as the original's. (A Windows logoff never arrives here: SDL 3.4.16 passes
            // WM_QUERYENDSESSION / WM_ENDSESSION to DefWindowProc and Windows ends the process — D43 ◇W11.)
            guard let flow = driver.flow else { finish(0); return }
            flow.systemQuit()
        case .focusLost: input.focusLost()
        case .focusGained: input.focusGained()
        }
        updateCursor()
    }

    // MARK: Requests

    private func honour(_ request: ShellRequest) {
        switch request {
        case .hideCursor: wantsCursorHidden = true
        case .showCursor: wantsCursorHidden = false
        case .hideMenuBar, .showMenuBar:
            break   // no menu bar (D21)
        case .loadLevel, .deathEffect:
            break   // a directly built session's (Core tests); the game's sessions are hosted by `LevelRun`
        case .dialog(let d):
            dialogs.show(d) { [weak self] result in self?.driver.flow?.dialogDone(result) }
        case .putFile(let r): pendingPanel = .save(r)
        case .getFile(let prompt): pendingPanel = .open(prompt)
        case .quit: finish(0)
        case .showMenuBarItems(let s): menuState = s
        }
        updateCursor()
    }

    /// A file dialog after the tick (the Mac's `runModal` runs its panel after `idleFired` returns), modal and
    /// synchronous: the flow is held still until it returns.
    private func runPendingPanel() {
        guard let panel = pendingPanel, let flow = driver.flow else { return }
        pendingPanel = nil
        panelUp = true
        updateCursor()
        let result: FileResult
        switch panel {
        case .save(let r):
            let folder: URL?
            do { folder = try files.ensureSavesFolder() } catch {
                log("saves folder: \(error)")
                folder = nil
            }
            result = panels.save(r, folder: folder)
        case .open(let prompt):
            let folder = files.savesFolder.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
            result = panels.open(prompt: prompt, folder: folder)
        }
        panelUp = false
        flow.fileDone(result)
    }

    private func updateCursor() {
        let hide = WinCursorRule.hidden(wanted: wantsCursorHidden, modalUp: modalUp, focused: input.focused,
                                        overCanvas: input.mouseInCanvas != nil)
        guard hide != cursorHidden else { return }
        cursorHidden = hide
        host.setCursorVisible(!hide)
    }

    // MARK: Quit, beep

    private func finish(_ code: Int32) {
        guard !finished else { return }
        finished = true
        exitCode = code
        shutDown()
    }

    /// Silences the music and every effect (on quit), and gives the cursor back.
    public func shutDown() {
        driver.stopAudio()
        if cursorHidden {
            cursorHidden = false
            host.setCursorVisible(true)
        }
    }

    /// `SysBeep` through the driver: nothing when muted (Ruling 20).
    public func beep() { driver.beep() }

    // MARK: The dump

    /// Binary PPM (P6) of a 640×480 RGBA frame — the `--dump` format (HectorSDL's smoke uses the same).
    public static func ppm(rgba: [UInt8], width: Int = WinCanvas.width, height: Int = WinCanvas.height) -> [UInt8] {
        var out = Array("P6\n\(width) \(height)\n255\n".utf8)
        out.reserveCapacity(out.count + width * height * 3)
        for p in 0..<min(width * height, rgba.count / 4) { out.append(contentsOf: rgba[4 * p ..< 4 * p + 3]) }
        return out
    }

    /// FNV-1a 64 of bytes (the gates compare frames by it).
    public static func fnv1a64(_ bytes: [UInt8]) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in bytes {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01b3
        }
        return h
    }

    /// The flow's state, for the headless run's last line.
    public var stateDescription: String { driver.flow.map { "\($0.state)" } ?? "not booted" }
}

/// The scripted host (`--frames` / `--keys`, and the tests): the fixed-step clock and the script's input
/// (`WinScriptedInput`), the frames kept, nothing shown. `inject` adds events (a test's quit, the executable's
/// close box); `wallClock` is counted, never needed headless.
@MainActor public final class WinScriptedHost: WinHost {
    public private(set) var scripted: WinScriptedInput
    private let clock: (secondsSince1904: UInt32, ticks: UInt32)
    private var injected: [WinEvent] = []
    /// Every frame presented, in order (the tests keep the last only: `keepFrames` = 1).
    public private(set) var presented: [[UInt8]] = []
    public var keepFrames = 1
    public private(set) var fullScreenToggles = 0
    public private(set) var cursorVisible = true
    public private(set) var wallClockReads = 0

    public init(script: WinKeyScript = WinKeyScript(), wallClock: (UInt32, UInt32) = (0, 0)) {
        scripted = WinScriptedInput(script: script)
        clock = (wallClock.0, wallClock.1)
    }

    public var ticks: UInt32 { scripted.ticks }
    public var seconds: Double { scripted.seconds }
    public var modifiers: WinModifiers { scripted.modifiers }

    public var wallClock: (secondsSince1904: UInt32, ticks: UInt32) {
        wallClockReads += 1
        return clock
    }

    /// The injected events (the system's: a test's quit, the executable's close box), then — when `script` and on
    /// the first such poll of this wake only — the script's (the pre-boot poll takes none, so wake 0's script
    /// reaches the booted game; a second poll in the same wake never delivers a scripted event twice).
    public func pollEvents(script: Bool) -> [WinEvent] {
        var events = injected
        injected = []
        if script, deliveredFrame != scripted.frame {
            deliveredFrame = scripted.frame
            events += scripted.events()
        }
        return events
    }

    /// The wake whose script was delivered last.
    private var deliveredFrame: Int?

    public func present(rgba: [UInt8]) {
        presented.append(rgba)
        if presented.count > keepFrames { presented.removeFirst(presented.count - keepFrames) }
    }

    public func setCursorVisible(_ visible: Bool) { cursorVisible = visible }
    public func toggleFullScreen() { fullScreenToggles += 1 }

    /// The next wake.
    public func advance() { scripted.advance() }

    /// `n` wakes pass without a step (a late wake).
    public func skip(iterations n: Int) { scripted.skip(n) }

    /// An event delivered at the next poll, before the script's.
    public func inject(_ event: WinEvent) { injected.append(event) }
}

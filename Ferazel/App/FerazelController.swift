import AppKit
import FerazelCore
import FerazelRender
import HectorShell

/// The app delegate and shell owner (plan S5, A1): opens level 1 (Phase 1 has no front end), shows the 640×480 screen
/// at a whole-number scale (Ben's ruling 4, design §5), and runs `.GameLoop`'s clock — one `FerazelSession.step` per
/// iteration, its `FrameOps` executed by `FrameRenderer`, the indexed screen presented through the screen CLUT. Keys are
/// polled once per step (`GetKeys`). The session owns the draw/skip parity; the App owns only the timing.
@MainActor final class FerazelController: NSObject, NSApplicationDelegate, ShellInputHandler {
    static let width = IndexedFrame.width
    static let height = IndexedFrame.height
    static let title = "Ferazel's Wand"
    /// Phase 1 opens "A Scent Of Peril" directly (the chapter screen and front end are later phases).
    static let level = 1
    /// The hidden defaults key for Ben's duplicate-colour tie-break (D26, 2026-10-07): "lowest" → `.lowest`, anything
    /// else → `.highest` — the app's default since Ben's ruling of 2026-10-10 (his Let's Play at 02:12: clean FG rock
    /// edges, no yellow specks). `-ColorTieBreak lowest` on the command line sets it for one launch. Core's
    /// `ColorSearch` default stays `.lowest`, so its goldens are untouched.
    static let tieBreakKey = "ColorTieBreak"
    /// The hidden defaults key for Ben's Mac display-gamma toggle (D26, 2026-10-10), off by default: when true, each
    /// frame is presented as the classic Mac (gamma 1.8) showed it on a modern 2.2 display. `-MacGamma YES` on the
    /// command line sets it for one launch. Presentation only — FerazelCore and its goldens never see it.
    static let macGammaKey = "MacGamma"
    /// The Let's Play measured ≈ 0.76 (colour-measurement-2026-10-10 Q2); the toggle uses the display ratio 1.8/2.2.
    static let macGammaExponent = 1.8 / 2.2
    /// v' = 255·(v/255)^(1.8/2.2), rounded, per 8-bit channel; applied to the 256-entry palette, not per pixel.
    static let macGammaLUT: [UInt8] = (0...255).map { v in
        UInt8((255 * pow(Double(v) / 255, macGammaExponent)).rounded())
    }

    private var session: FerazelSession!
    private var renderer: FrameRenderer!
    private var audio: FerazelAudio?
    private var shell: ShellWindowController!
    private var timer: ShellIdleTimer!
    private let prefs = FerazelPrefs()
    private let bitmap = ShellBitmap(width: FerazelController.width, height: FerazelController.height)
    /// `MacGamma`, read once at launch.
    private let macGamma = FerazelController.macGamma()

    /// `TickCount()` at the start of the step the next wait is measured from (`.GameLoop`'s `start`); nil before the
    /// first step.
    private var lastStepStart: UInt32?

    /// The game asked for the menu bar hidden (`.hideMenuBar`); honoured in full screen only (design §7.4).
    private var wantsMenuBarHidden = false
    /// The game asked for the cursor hidden (`.hideCursor`, `_HideCursorSafe`).
    private var wantsCursorHidden = false
    /// `NSCursor.hide` is counted: whether this controller's one hide is in effect.
    private var cursorHidden = false

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMenuBar()
        guard let dataDirectory = FerazelAssets.dataDirectory() else {
            #if DEBUG
            let alert = NSAlert()
            alert.messageText = "Ferazel's Wand's original data folder is missing from this app."
            alert.informativeText = "Run tools/stage-ferazel.sh (or set FERAZEL_DATA to Resources/Ferazel)."
            alert.runModal()
            #endif
            fail("no data folder at Contents/Resources/Ferazel")
            return
        }
        do {
            let resources = try FerazelData.open(dataDirectory)
            let search = ColorSearch(model: .exactNearest, tieBreak: Self.tieBreak())  // D26 LP measurement 2026-10-10 (Ben)
            renderer = try FrameRenderer(resources: resources, level: Self.level, search: search,
                                         dither: .errorDiffusion, text: CoreTextRasterizer(), prefs: prefs)
            session = try FerazelSession(resources: resources, prefs: prefs, level: Self.level,
                                         faceBounds: renderer.faceBounds)
            try renderer.addLights(session.lights)
            audio = FerazelAudio(mixer: try? ShellMixer(voices: 1), musicDirectory: resources.musicDirectory,
                                 prefs: prefs)
            // Step 1's `.SetAIFFMusic(hdr+0x284a)` (l. 5221): decoded now, not inside the first step.
            audio?.prepare(track: Int(session.level.header.music))
        } catch {
            #if DEBUG
            let alert = NSAlert()
            alert.messageText = "Ferazel's Wand's original data could not be loaded."
            alert.informativeText = "\(dataDirectory.path)\n\n\(error)"
            alert.runModal()
            #endif
            fail("cannot load the original data: \(error)")
            return
        }

        shell = ShellWindowController(title: Self.title, logicalWidth: Self.width, logicalHeight: Self.height,
                                      styleMask: Self.windowStyle, scalingPolicy: .integerFit)
        shell.view.inputHandler = self
        sizeToWholeScale(shell.windowedWindow)
        shell.view.present(bitmap)                                      // black until the first step presents
        shell.windowedWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        timer = ShellIdleTimer(interval: 1.0 / 240.0) { [weak self] in self?.idleFired() }
        timer.start()
        idleFired()
    }

    static func tieBreak(_ defaults: UserDefaults = .standard) -> ColorSearch.TieBreak {
        defaults.string(forKey: tieBreakKey) == "lowest" ? .lowest : .highest
    }

    static func macGamma(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: macGammaKey)
    }

    /// A title bar, collapsible, no close box (⌘Q quits) and not resizable (whole-number scale) — the Deimos window.
    static let windowStyle: NSWindow.StyleMask = [.titled, .miniaturizable]

    /// Content 640k × 480k points: k = 3 when the main screen's visible frame holds the k = 3 window (title bar
    /// included), else 2 when it holds the k = 2 window, else 1 (plan A1); centred in that area.
    private func sizeToWholeScale(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { window.center(); return }
        let area = screen.visibleFrame
        let k = [3, 2].first { k in
            let frame = window.frameRect(forContentRect: NSRect(x: 0, y: 0, width: Self.width * k,
                                                                height: Self.height * k))
            return frame.width <= area.width && frame.height <= area.height
        } ?? 1
        window.setContentSize(NSSize(width: Self.width * k, height: Self.height * k))
        let size = window.frame.size
        window.setFrameOrigin(NSPoint(x: (area.midX - size.width / 2).rounded(),
                                      y: (area.midY - size.height / 2).rounded()))
    }

    private func fail(_ message: String) {
        NSLog("Ferazel's Wand: %@", message)
        NSApp.terminate(nil)
    }

    // MARK: Menu

    /// The app menu only (the original hides its menu bar in play): Quit ⌘Q, plus a hidden Full Screen ⌃⌘F item whose
    /// shortcut goes through key-equivalent matching (the Deimos/BTX pattern); the original had no such entry.
    private func makeMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: Self.title)
        let fullScreen = NSMenuItem(title: "Full Screen", action: #selector(toggleFullScreenChosen(_:)),
                                    keyEquivalent: "f")
        fullScreen.keyEquivalentModifierMask = [.control, .command]
        fullScreen.target = self
        fullScreen.isHidden = true
        fullScreen.allowsKeyEquivalentWhenHidden = true
        appMenu.addItem(fullScreen)
        appMenu.addItem(NSMenuItem(title: "Quit \(Self.title)", action: #selector(NSApplication.terminate(_:)),
                                   keyEquivalent: "q"))
        appItem.submenu = appMenu
        bar.addItem(appItem)
        return bar
    }

    // MARK: Clock

    /// One 1/240 s fire (Deimos precedent: a 60 Hz timer against the 60 Hz tick beats into 3-tick gaps; four fires
    /// a tick never miss a boundary by more than a quarter tick). `.GameLoop` (decompile l. 5229–5296) takes `start = TickCount()` at the top of each iteration
    /// and waits at the bottom: with prefs[0] = 0 until 2 ticks after its start; with prefs[0] set, the non-drawing
    /// iteration does not wait and the drawing one waits until 4 ticks after its own start. Here a fire runs the next
    /// iteration once that wait is over — with prefs[0] set, the non-drawing iteration and its drawing partner back to
    /// back. A late fire runs one iteration (or pair): missed steps are dropped, never caught up.
    private func idleFired() {
        guard session != nil else { return }
        defer { updateCursor() }
        let now = ShellClock.ticks()
        if prefs.reduceFrameRate == 0 {
            if let last = lastStepStart, now &- last < 2 { return }
            lastStepStart = now
            runStep()
        } else {
            if let last = lastStepStart, now &- last < 4 { return }
            // The session's parity decides which iteration draws (the first skips, R5); run until one has drawn.
            if !runStep() {
                lastStepStart = ShellClock.ticks()
                runStep()
            } else {
                lastStepStart = now
            }
        }
    }

    /// One `.GameLoop` iteration: keys → `session.step` → `renderer.apply` → present. Returns `FrameOps.drawn`.
    @discardableResult
    private func runStep() -> Bool {
        let held = shell.view.pollKeyState().held
        let ops = session.step(keys: KeyState(pressed: held.map { Self.keyMapCode(Int($0)) }))
        do {
            try renderer.apply(ops)
        } catch {
            timer.invalidate()
            fail("the frame could not be drawn: \(error)")
            return ops.drawn
        }
        for cue in ops.music { audio?.handle(cue) }
        for request in ops.requests { honour(request) }
        if ops.drawn { present() }               // a skipped iteration leaves the screen as it was
        return ops.drawn
    }

    /// Right Shift, Option and ⌘ (0x3C, 0x3D, 0x36) as the left keys (0x38, 0x3A, 0x37): the classic `KeyMap`
    /// reports either side of a modifier under the left key's bit.
    static func keyMapCode(_ code: Int) -> Int {
        switch code {
        case 0x3c: return 0x38
        case 0x3d: return 0x3a
        case 0x36: return 0x37
        default: return code
        }
    }

    /// The renderer's 8-bit screen through the current screen CLUT, written straight into the window bitmap (the
    /// `IndexedFrame.rgba(through:)` mapping, without allocating a 640×480 word array per frame). With `MacGamma` on,
    /// each palette channel goes through `macGammaLUT` first.
    private func present() {
        let lut = macGamma ? Self.macGammaLUT : nil
        let table = renderer.screenClut.entries.map { e -> UInt32 in
            var (r, g, b) = (Int(e.red >> 8), Int(e.green >> 8), Int(e.blue >> 8))
            if let lut { (r, g, b) = (Int(lut[r]), Int(lut[g]), Int(lut[b])) }
            return 0xff00_0000 | UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b)
        }
        let out = bitmap.pixels
        renderer.screen.pixels.withUnsafeBufferPointer { src in
            for i in 0..<min(src.count, Self.width * Self.height) { out[i] = table[Int(src[i])] }
        }
        shell.view.present(bitmap)
    }

    // MARK: Shell requests

    private func honour(_ request: ShellRequest) {
        switch request {
        case .hideCursor: wantsCursorHidden = true
        case .showCursor: wantsCursorHidden = false
        case .hideMenuBar: wantsMenuBarHidden = true
        case .showMenuBar: wantsMenuBarHidden = false
        }
        updateMenuBar()
        updateCursor()
    }

    /// The menu bar is hidden only in full screen and only while the game asks (design §7.4: windowed macOS keeps it).
    private func updateMenuBar() {
        let hide = shell.isFullscreen && wantsMenuBarHidden
        let options: NSApplication.PresentationOptions = hide ? [.hideDock, .hideMenuBar] : []
        if NSApp.presentationOptions != options { NSApp.presentationOptions = options }
    }

    /// The hide is honoured only over the game image while the window is key (Deimos precedent); the pointer comes
    /// back anywhere else.
    private func updateCursor() {
        let window = shell.currentWindow
        var hide = wantsCursorHidden && NSApp.isActive && window.isKeyWindow
        if hide {
            let inView = shell.view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            hide = shell.view.imageRectInPoints.contains(inView)
        }
        guard hide != cursorHidden else { return }
        if hide { NSCursor.hide() } else { NSCursor.unhide() }
        cursorHidden = hide
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
        audio?.stopAll()
        if cursorHidden {
            NSCursor.unhide()
            cursorHidden = false
        }
        NSApp.presentationOptions = []
    }

    // MARK: ShellInputHandler

    /// Play reads the keyboard by polling; key-downs do nothing (Caps Lock pause and the Esc dialog are Phase 3;
    /// ⌘Q and ⌃⌘F are menu key equivalents).
    func shellView(_ view: ShellView, keyDown event: NSEvent) {}

    func shellView(_ view: ShellView, mouseDown event: NSEvent) {}

    /// ⌃⌘F: full screen (the largest whole multiple, black border — `.integerFit`) or back to the window.
    @objc private func toggleFullScreenChosen(_ sender: Any?) {
        if shell.isFullscreen { shell.exitFullscreen() } else { shell.enterFullscreen() }
        updateMenuBar()
        updateCursor()
        present()
    }
}

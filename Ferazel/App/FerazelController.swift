import AppKit
import Carbon
import FerazelCore
import FerazelRender
import HectorShell

/// The app delegate and shell owner (plan S5, A1a): the whole game runs in Core's `GameFlow` (boot, main menu, New
/// Game / Continue, levels, the map, the death screen) — the App ticks it once per 60 Hz tick with the polled input
/// (`GetKeys` as `KeyState`, Caps Lock, the mouse in canvas coordinates, the button, whether the app is active), draws
/// each tick's `segments` in order on the one shared `ScreenSurface` — `.screen` → the level-less `ScreenRenderer`
/// (inside a level: the level-chain `ScreenRenderer`, the conversation's own ops the level's `ConversationRenderer`),
/// `.level` → the level's `FrameRenderer` (built per level through `LevelServices`), `.map` → `MapRenderer` — plays
/// the tick's sounds and music cues, honours its requests (cursor, menu bar, dialogs, file panels, quit), presents the
/// surface through its presented CLUT (then MacGamma) when the tick asks. The 640×480 screen is shown at a
/// whole-number scale (Ben's ruling 4, design §5).
@MainActor final class FerazelController: NSObject, NSApplicationDelegate, ShellInputHandler {
    static let width = IndexedFrame.width
    static let height = IndexedFrame.height
    static let title = "Ferazel's Wand"
    /// The hidden defaults key for the starting level (Ben D33, D35 kept as a hidden test path): `-FerazelLevel 2` on
    /// the command line makes New Game start at level 2 for one launch (`GameFlow.startLevel`); absent or outside
    /// `BuiltLevels.range` → level 1, "A Scent Of Peril".
    static let levelKey = "FerazelLevel"
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
    /// The screen's CLUT before the game sets one: `SwitchTo8BitColorMT` leaves the system's 8-bit table, which the
    /// game's clut 801 "System CLUT" holds (PICT 131, the logo, is drawn under it, M l. 8277–8281).
    static let systemClut: Int16 = 0x321

    private var flow: GameFlow!
    private var resources: FerazelResources!
    private var search: ColorSearch!
    private var surface: ScreenSurface!
    /// The front end's executor (`.frontEnd` chain): the boot, menu, stage, death screens; the map's screen ops.
    private var frontScreen: ScreenRenderer!
    /// A level's `.screen` segments before its renderer exists (the popup), on the level chain.
    private var levelScreen: ScreenRenderer!
    private var mapRenderer: MapRenderer!
    /// The running level's renderer and its conversation renderer (`LevelServices.prepare`); the last level's stay
    /// until the next is prepared.
    private var levelRenderer: FrameRenderer?
    private var conversationRenderer: ConversationRenderer?
    /// The `LevelRun` that was running when `conversationRenderer` was built (`prepare`).
    private weak var conversationRun: LevelRun?
    private let rasterizer = CoreTextRasterizer()
    /// The conversation text's measures (C1/C2: the 214-px wrap and the typing timeline need real widths).
    private var conversationText = ConversationText.unmeasured
    /// The `LevelRun` last given `conversationText` (held, so a new run is never mistaken for it).
    private var configuredRun: LevelRun?
    private var audio: FerazelAudio?
    private let files = FerazelFiles()
    private var shell: ShellWindowController!
    private var timer: ShellIdleTimer!
    private let bitmap = ShellBitmap(width: FerazelController.width, height: FerazelController.height)
    /// `MacGamma`, read once at launch.
    private let macGamma = FerazelController.macGamma()
    /// The tick the flow last ran (the flow runs once per 60 Hz tick).
    private var lastTick: UInt32?
    /// The boot's two App loads, done (`GameFlow.LoadPhase`).
    private var loadedPhases: Set<GameFlow.LoadPhase> = []

    /// The game asked for the menu bar hidden (`.hideMenuBar`); honoured in full screen only (design §7.4).
    private var wantsMenuBarHidden = false
    /// The game asked for the cursor hidden (`.hideCursor`, `_HideCursorSafe`).
    private var wantsCursorHidden = false
    /// `NSCursor.hide` is counted: whether this controller's one hide is in effect.
    private var cursorHidden = false
    /// MBAR 128 (A1b): built once the data is open; `.showMenuBarItems` sets its check marks and paused state.
    private var menus: FerazelMenus?
    /// The original's Dialog Manager windows (A1b).
    private var dialogs: FerazelDialogs?
    /// A file panel is up.
    private var panelUp = false
    /// A live menu is down (`MenuSelect` tracking blocks the loop that called it — the main menu's or the pause's).
    private var menuTracking = false
    /// A dialog or a file panel is up: the flow does not tick meanwhile (BTX D13.6 precedent).
    private var modalUp: Bool { panelUp || (dialogs?.isShowing ?? false) }
    /// A Finder open that came before the flow existed.
    private var pendingOpen: SavedGameRef?
    /// The flow's `.quit` came (or a launch failure): the terminate the App then makes is not asked again.
    private var quitApproved = false

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
            self.resources = resources
            search = ColorSearch(model: .exactNearest, tieBreak: Self.tieBreak())  // D26 LP measurement 2026-10-10 (Ben)
            surface = ScreenSurface(clut: try ColorLUT.load(id: Self.systemClut, from: resources, chain: .frontEnd))
            frontScreen = ScreenRenderer(surface: surface, resources: resources, search: search, dither: .errorDiffusion,
                                         text: rasterizer, chain: .frontEnd)
            levelScreen = ScreenRenderer(surface: surface, resources: resources, search: search, dither: .errorDiffusion,
                                         text: rasterizer, chain: .level)
            mapRenderer = MapRenderer(screen: frontScreen)
            conversationText = TextLayout.conversationText(rasterizer)
            audio = FerazelAudio(mixer: try? ShellMixer(voices: 1), musicDirectory: resources.musicDirectory)
            // `.SetPrefFile` + `.InitPrefs` (M l. 8192–8243): the stored record, else the defaults, written at once.
            let prefs: FerazelPrefs
            if let record = files.loadPrefs() {
                prefs = FerazelPrefs(record: record)
            } else {
                prefs = FerazelPrefs()
                do { try files.storePrefs(prefs.record()) } catch {
                    NSLog("Ferazel's Wand: prefs file: %@", "\(error)")
                }
            }
            // `.InitAppGlobals`' `_FastRand(0)` (M l. 334; `LMGetTime` + `LMGetTicks`, M l. 31295–31298): the stream is
            // seeded once from Time + Ticks and never again.
            let clock = FastRand.systemClock()
            let flow = GameFlow(resources: resources, prefs: prefs,
                                seed: FastRand.clockSeed(secondsSince1904: clock.secondsSince1904, ticks: clock.ticks),
                                files: files, levels: self)
            flow.startLevel = Self.startLevel()
            // `KeyTranslate` (the Options key names): the flow calls it on the main thread (its ticks, the dialog).
            flow.keyCharacter = { code in MainActor.assumeIsolated { Self.layoutCharacter(code) } }
            flow.dateTime = { FastRand.systemClock().secondsSince1904 }   // `GetDateTime`
            self.flow = flow
            if let ref = pendingOpen {
                pendingOpen = nil
                flow.openDocument(ref)
            }
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
        installMenus()
        installDialogs()
        sizeToWholeScale(shell.windowedWindow)
        shell.view.present(bitmap)                                      // black until the flow first presents
        shell.windowedWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        timer = ShellIdleTimer(interval: 1.0 / 240.0) { [weak self] in self?.idleFired() }
        timer.start()
        idleFired()
    }

    /// `FerazelLevel` (Ben D33): 1 when absent or outside `BuiltLevels.range`.
    static func startLevel(_ defaults: UserDefaults = .standard) -> Int {
        let n = defaults.integer(forKey: levelKey)
        return BuiltLevels.range.contains(n) ? n : 1
    }

    static func tieBreak(_ defaults: UserDefaults = .standard) -> ColorSearch.TieBreak {
        defaults.string(forKey: tieBreakKey) == "lowest" ? .lowest : .highest
    }

    static func macGamma(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: macGammaKey)
    }

    /// A title bar, collapsible, no close box (the game quits through its own Quit) and not resizable (whole-number
    /// scale) — the Deimos window.
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
        timer?.invalidate()
        quitApproved = true
        NSApp.terminate(nil)
    }

    // MARK: Menu

    /// The hidden Full Screen ⌃⌘F item, whose shortcut goes through key-equivalent matching (the Deimos/BTX pattern; the
    /// original had no such entry).
    private lazy var fullScreenItem: NSMenuItem = {
        let item = NSMenuItem(title: "Full Screen", action: #selector(toggleFullScreenChosen(_:)), keyEquivalent: "f")
        item.keyEquivalentModifierMask = [.control, .command]
        item.target = self
        item.isHidden = true
        item.allowsKeyEquivalentWhenHidden = true
        return item
    }()

    /// Until the data is open: the app menu with the hidden Full Screen item only (no Quit — a system quit goes through
    /// `applicationShouldTerminate`).
    private func makeMenuBar() -> NSMenu {
        let bar = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: Self.title)
        appMenu.addItem(fullScreenItem)
        appItem.submenu = appMenu
        bar.addItem(appItem)
        return bar
    }

    /// MBAR 128 (A1b, `FerazelMenus`): its picks go to `GameFlow.menuChosen` where the original listened for them.
    private func installMenus() {
        fullScreenItem.menu?.removeItem(fullScreenItem)
        let m = FerazelMenus(resources: resources, title: Self.title, fullScreen: fullScreenItem)
        m.modalUp = { [weak self] in self?.modalUp ?? true }
        m.chosen = { [weak self] item in self?.flow?.menuChosen(item) }
        menus = m
        NSApp.mainMenu = m.bar
        let center = NotificationCenter.default
        center.addObserver(forName: NSMenu.didBeginTrackingNotification, object: m.bar, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.menuTracking = (self.menus?.state.menusLive ?? false) && !self.modalUp
            }
        }
        center.addObserver(forName: NSMenu.didEndTrackingNotification, object: m.bar, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.menuTracking = false }
        }
    }

    /// The dialogs (A1b, `FerazelDialogs`), drawn over the game image's centre, just above the game window.
    private func installDialogs() {
        let d = FerazelDialogs(resources: resources, picture: { [weak self] id in self?.dialogPicture(id) },
                               gameArea: { [weak self] in
            guard let self else { return (NSScreen.main?.frame ?? .zero, .normal) }
            let view = shell.view
            let window = shell.currentWindow
            let rect = window.convertToScreen(view.convert(view.imageRectInPoints, to: nil))
            return (rect, window.level)
        })
        d.modalStateChanged = { [weak self] in
            self?.updateCursor()
            if self?.modalUp == false { self?.shell.currentWindow.makeKeyAndOrderFront(nil) }
        }
        d.nullTick = { [weak self] in self?.pollPadInDialog() }
        dialogs = d
    }

    /// A `PICT` as QuickDraw drew it into a dialog window: converted under the screen's current CLUT (`ColorSearch`,
    /// the screen's inverse table), shown through it (and MacGamma when on).
    private func dialogPicture(_ id: Int16) -> CGImage? {
        guard let source = try? PictureSource.load(id: id, from: resources, chain: .frontEnd),
              let picture = try? ConvertedPicture(source: source, clut: surface.clut, search: search) else { return nil }
        let lut = macGamma ? Self.macGammaLUT : nil
        let table: [(UInt8, UInt8, UInt8)] = surface.clut.entries.map { e in
            var (r, g, b) = (Int(e.red >> 8), Int(e.green >> 8), Int(e.blue >> 8))
            if let lut { (r, g, b) = (Int(lut[r]), Int(lut[g]), Int(lut[b])) }
            return (UInt8(r), UInt8(g), UInt8(b))
        }
        var bytes = [UInt8](repeating: 0xff, count: picture.width * picture.height * 4)
        for (i, v) in picture.pixels.enumerated() where Int(v) < table.count {
            let c = table[Int(v)]
            (bytes[4 * i], bytes[4 * i + 1], bytes[4 * i + 2]) = c
        }
        guard picture.width > 0, picture.height > 0,
              let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: picture.width, height: picture.height, bitsPerComponent: 8, bitsPerPixel: 32,
                       bytesPerRow: picture.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    /// `KeyTranslate` for the Options dialog's key names (`.ConvertKeyName`'s fallback): the character the current
    /// keyboard layout gives `code` with no modifiers; nil when it gives none.
    static func layoutCharacter(_ code: Int16) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(raw).takeUnretainedValue() as Data
        var dead: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        let status = data.withUnsafeBytes { buffer -> OSStatus in
            guard let layout = buffer.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return -1 }
            return UCKeyTranslate(layout, UInt16(bitPattern: code), UInt16(kUCKeyActionDisplay), 0,
                                  UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysMask), &dead,
                                  chars.count, &length, &chars)
        }
        guard status == noErr, length > 0 else { return nil }
        let s = String(utf16CodeUnits: chars, count: length)
        return s.unicodeScalars.allSatisfy({ $0.value >= 0x20 && $0.value != 0x7f }) ? s : nil
    }

    // MARK: Clock

    /// One 1/240 s fire: the flow runs once per new 60 Hz tick (`ShellClock.ticks()`, absolute — Core times every
    /// sequence and the level cadence from it, Invariants 3–4); never while a dialog or a panel is up.
    private func idleFired() {
        guard flow != nil, !modalUp, !menuTracking else { return }
        defer { updateCursor() }
        let now = ShellClock.ticks()
        guard now != lastTick else { return }
        lastTick = now
        let out = flow.tick(now: now, input: pollInput())
        // A run created inside this tick is set up (and the last level's conversation renderer dropped) before the
        // tick's segments are routed — its first popup draws go to `levelScreen`.
        configureLevelRun()
        do {
            try draw(flow.segments)
        } catch {
            fail("the screen could not be drawn: \(error)")
            return
        }
        audio?.apply(sounds: out.sounds, stops: out.soundStops, stopAt: out.soundStopAt)
        for cue in out.music { audio?.handle(cue) }
        if let p = out.prefs {
            // `.MakeCurrPrefs` (⌘P, the pause's ⌘M / ⌘F, a save): the live record the renderers read per copy —
            // `FrameRenderer`'s parallax (prefs+4, every `copyToScreen`), the conversation's `restoreView`.
            levelRenderer?.prefs = p
            conversationRenderer?.prefs = p
        }
        if out.present { present() }
        for request in out.requests { honour(request) }
        serviceLoad()
    }

    /// The tick's input: the held keys (`GetKeys`), Caps Lock, the pointer in 640×480 canvas coordinates (nil off the
    /// canvas), the button, the app active — with the gamepad merged in as the original keys (GP, D37): its held keys
    /// into the key map, its pause latch ORed into Caps Lock (`ShellView.pollKeyState`).
    private func pollInput() -> FrontInput {
        updatePadMapping()
        let state = shell.view.pollKeyState()
        let keys = KeyState(pressed: state.held.map { Self.keyMapCode(Int($0)) })
        return FrontInput(keys: keys, capsLock: state.capsLock, mouse: canvasMouse(),
                          button: NSEvent.pressedMouseButtons & 1 != 0, active: NSApp.isActive,
                          playing: audio?.playingSounds() ?? [])
    }

    /// The pointer in 640×480 canvas coordinates, nil when it is not over the game image (or there is no window):
    /// tested before truncating (HectorShell's `logicalMouseLocation` truncates toward zero, so −0.5 would read 0, and
    /// answers (0, 0) without a window). Same mapping as `ShellScaling.logicalPoint(viewPoint:…)`.
    private func canvasMouse() -> (h: Int, v: Int)? {
        let view = shell.view
        guard let window = view.window else { return nil }
        let p = view.convert(window.convertPoint(fromScreen: NSEvent.mouseLocation), from: nil)
        let r = view.imageRectInPoints
        guard r.width > 0, r.height > 0 else { return nil }
        let x = (Double(p.x) - Double(r.minX)) * Double(Self.width) / Double(r.width)
        let y = Double(Self.height) - (Double(p.y) - Double(r.minY)) * Double(Self.height) / Double(r.height)
        guard x >= 0, x < Double(Self.width), y >= 0, y < Double(Self.height) else { return nil }   // NaN fails too
        return (h: Int(x), v: Int(y))
    }

    /// Right Shift, Option, Control and ⌘ (0x3C, 0x3D, 0x3E, 0x36) as the left keys (0x38, 0x3A, 0x3B, 0x37): the
    /// classic `KeyMap` reports either side of a modifier under the left key's bit, and the game reads every key the
    /// same way (`.IsInputKeyPressed` → `_IsPressed(prefs+0x12 + 2n)`, one `GetKeys` bit test, M l. 42340–42353).
    static func keyMapCode(_ code: Int) -> Int {
        switch code {
        case 0x3c: return 0x38
        case 0x3d: return 0x3a
        case 0x3e: return 0x3b
        case 0x36: return 0x37
        default: return code
        }
    }

    /// A new `LevelRun` gets the conversation measures before its session can step (its popup blocks the first 16
    /// ticks, L2), and the previous level's conversation renderer goes — unless `prepare` already built this run's.
    private func configureLevelRun() {
        guard let run = flow.levelRun else { return }
        guard run !== configuredRun else { return }
        configuredRun = run
        run.conversationText = conversationText
        if conversationRun !== run { conversationRenderer = nil }
    }

    /// The tick's draws, renderer by renderer, in order (F1b: the segments only).
    private func draw(_ segments: [FlowSegment]) throws {
        for segment in segments {
            switch segment {
            case .screen(let ops):
                guard flow.levelRun != nil else {
                    try frontScreen.apply(ops)
                    break
                }
                // In a level each op goes to the renderer that draws it as the original: the conversation's own ops
                // (`ConversationRun`, C2) to `ConversationRenderer`; the pause, stage, load-bar and every other screen
                // op to the level-chain `ScreenRenderer` (`DrawString` text, pictures under the screen CLUT).
                var run: [DrawOp] = []
                var toConversation = false
                func flush() throws {
                    guard !run.isEmpty else { return }
                    if toConversation, let c = conversationRenderer { try c.apply(run) } else { try levelScreen.apply(run) }
                    run = []
                }
                for op in ops {
                    let c = Self.isConversationOp(op)
                    if c != toConversation { try flush(); toConversation = c }
                    run.append(op)
                }
                try flush()
            case .level(let ops):
                guard let r = levelRenderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
                try r.apply(FrameOps(draws: ops))
            case .map(let ops):
                try mapRenderer.apply(ops)
            }
        }
    }

    /// The ops only `ConversationRun` makes (C1/C2): `DrawChar` text, the conversation GWorld's transparent copies
    /// (no forced CLUT), the end's `restoreView` and its mode-3 `drawBlackLines`.
    static func isConversationOp(_ op: DrawOp) -> Bool {
        switch op {
        case .drawText, .restoreView, .drawBlackLines: return true
        case .copyPicture(_, _, _, _, nil, true): return true
        default: return false
        }
    }

    /// The boot's App loads (`GameFlow.state` `.loading`): the sound effects under the logo (`.InitSounds` +
    /// `.InitAppGlobals`), the faces under the loading screen (`.InitSprites`' `.InitMapFaces` — the only faces the
    /// App keeps from boot; a level's faces load with its renderer).
    private func serviceLoad() {
        guard case .loading(let phase) = flow.state, !loadedPhases.contains(phase) else { return }
        loadedPhases.insert(phase)
        switch phase {
        case .sounds: loadSounds()
        case .faces: loadFaces()
        }
        flow.loadFinished()
    }

    /// Every `snd ` of the Sounds file — or with F1 at boot (`soundLoading` off) only the four `.InitAppGlobals` loads
    /// unconditionally (M l. 350–356): 198 (the pause, `uRam100ab9bc`), 4801 and the menu buttons' 4803 / 4804 — and
    /// their play lengths for the stage screens.
    private func loadSounds() {
        let only: Set<Int16>? = flow.soundLoading ? nil
            : [PauseRun.sound, 4801, MainMenu.enterSound, MainMenu.exitSound]
        do {
            let bank = try SoundBank(sounds: resources.sounds)
            audio?.loadSounds(bank, only: only)
            var lengths: [Int16: Int] = [:]
            for s in bank.sounds where only?.contains(s.id) ?? true {
                lengths[s.id] = StageSounds.ticks(sampleCount: s.pcm.frames, sampleRate: s.pcm.sampleRate)
            }
            flow.soundLengths = lengths
        } catch {
            NSLog("Ferazel's Wand: sounds: %@", "\(error)")   // the game runs without effects
        }
    }

    /// The map faces (`.InitMapFaces`, clut 700): one `loadProgress` per face (`.Update3DProgBar`).
    private func loadFaces() {
        var n = 0
        for (set, count) in [(FrontFaceSet.mapMarker, 1), (.mapNode, 8), (.mapBoss, 8), (.mapAmbient, 8)] {
            for i in 0..<count {
                do { _ = try mapRenderer.face(set, i) } catch {
                    NSLog("Ferazel's Wand: map face %d/%d: %@", Int(set.pict), i, "\(error)")
                }
                n += 1
                flow.loadProgress(faces: n)
            }
        }
    }

    /// The shared screen through its presented CLUT (the screen CLUT through `ScreenGamma`), written straight into the
    /// window bitmap (the `IndexedFrame.rgba(through:)` mapping, without allocating a 640×480 word array per frame).
    /// With `MacGamma` on, each palette channel then goes through `macGammaLUT`.
    private func present() {
        let lut = macGamma ? Self.macGammaLUT : nil
        let table = surface.presentedClut.entries.map { e -> UInt32 in
            var (r, g, b) = (Int(e.red >> 8), Int(e.green >> 8), Int(e.blue >> 8))
            if let lut { (r, g, b) = (Int(lut[r]), Int(lut[g]), Int(lut[b])) }
            return 0xff00_0000 | UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b)
        }
        let out = bitmap.pixels
        surface.frame.pixels.withUnsafeBufferPointer { src in
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
        case .loadLevel, .deathEffect:
            break   // a directly built session's (Core tests); the app's sessions are hosted by `LevelRun`
        case .dialog(let d): showDialog(d)
        case .putFile(let r): showSavePanel(r)
        case .getFile(let prompt): showOpenPanel(prompt)
        case .quit: quitNow()
        case .showMenuBarItems(let s): menus?.update(s)    // `.UpdateMenus`: the check marks, paused or not
        }
        updateMenuBar()
        updateCursor()
    }

    /// `ShellRequest.dialog` → the original's Dialog Manager window (`FerazelDialogs`), answered into
    /// `GameFlow.dialogDone` once it closes. While it is up the flow does not tick.
    private func showDialog(_ d: FerazelDialog) {
        guard let dialogs else { flow.dialogDone(.cancel); return }
        switch d {
        case .confirm(let text):
            dialogs.confirm(text) { [weak self] ok in self?.flow.dialogDone(ok ? .ok : .cancel) }
        case .report(let text):
            dialogs.report(text) { [weak self] in self?.flow.dialogDone(.ok) }
        case .error(let text, let code):
            dialogs.report(text, code: code) { [weak self] in self?.flow.dialogDone(.ok) }
        case .preferences:
            dialogs.preferences(model: { [weak self] in self?.flow.prefsDialog }, update: { [weak self] body in
                guard let self, var m = flow.prefsDialog else { return }
                let cues = body(&m)
                flow.prefsDialog = m
                for cue in cues { audio?.handle(cue) }              // the Music checkbox and popup act at once
            }, completion: { [weak self] in
                guard let self else { return }
                flow.dialogDone(flow.prefsDialog?.result == .ok ? .ok : .cancel)
            })
        case .credits:
            let scroll = flow.credits ?? CreditsScroll(start: ShellClock.ticks())
            dialogs.credits(scroll) { [weak self] in self?.flow.dialogDone(.ok) }
        }
    }

    /// Runs `body` (a modal panel) after this tick, with the flow held still until it returns.
    private func runModal(_ body: @escaping @MainActor () -> Void) {
        panelUp = true
        updateCursor()
        DispatchQueue.main.async { [weak self] in
            body()
            self?.panelUp = false
        }
    }

    /// `.SaveSG`'s `CustomPutFile` (DITL 1003): the macOS save panel — "Please name your saved game.", DITL 1003 item
    /// 13's text, the incremented default name, in the Ferazel's Wand folder (D35 Known deviation: Standard File).
    private func showSavePanel(_ r: PutFileRequest) {
        runModal { [weak self] in
            guard let self else { return }
            let panel = NSSavePanel()
            panel.title = r.prompt
            panel.nameFieldLabel = r.prompt
            panel.message = r.message
            panel.nameFieldStringValue = r.defaultName
            panel.canCreateDirectories = true
            panel.directoryURL = try? self.files.ensureFolder()
            if panel.runModal() == .OK, let url = panel.url {
                self.flow.fileDone(.chosen(SavedGameRef(url: url, displayName: url.lastPathComponent)))
            } else {
                self.flow.fileDone(.cancelled)
            }
        }
    }

    /// `.OpenSG`'s `CustomGetFile` (DITL 1500, type 'FWSg'): the macOS open panel, any file (Core refuses a file that
    /// is not a saved game with the original's text).
    private func showOpenPanel(_ prompt: String) {
        runModal { [weak self] in
            guard let self else { return }
            let panel = NSOpenPanel()
            panel.message = prompt
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = false
            if FileManager.default.fileExists(atPath: self.files.folder.path) { panel.directoryURL = self.files.folder }
            if panel.runModal() == .OK, let url = panel.url {
                self.flow.fileDone(.chosen(SavedGameRef(url: url, displayName: url.lastPathComponent)))
            } else {
                self.flow.fileDone(.cancelled)
            }
        }
    }

    /// The menu bar is hidden only in full screen and only while the game asks (design §7.4: windowed macOS keeps it).
    /// In full screen the game window sits at the shielding level, above the menu bar: while the game shows the bar
    /// (`.ShowTheMenuBar` — the pointer at the main menu's top edge, the pause) the window goes just below the menu bar's
    /// level, and back to the shielding level when it hides.
    private func updateMenuBar() {
        let full = shell.isFullscreen
        let hide = full && wantsMenuBarHidden
        let options: NSApplication.PresentationOptions = hide ? [.hideDock, .hideMenuBar] : full ? [.hideDock] : []
        if NSApp.presentationOptions != options { NSApp.presentationOptions = options }
        guard full else { return }
        let level = wantsMenuBarHidden ? NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
                                       : NSWindow.Level(rawValue: NSWindow.Level.mainMenu.rawValue - 1)
        if shell.currentWindow.level != level { shell.currentWindow.level = level }
    }

    /// The hide is honoured only over the game image while the window is key and no dialog is up (Deimos
    /// precedent); the pointer comes back anywhere else.
    private func updateCursor() {
        guard let shell else { return }
        let window = shell.currentWindow
        var hide = wantsCursorHidden && !modalUp && NSApp.isActive && window.isKeyWindow
        if hide {
            let inView = shell.view.convert(window.mouseLocationOutsideOfEventStream, from: nil)
            hide = shell.view.imageRectInPoints.contains(inView)
        }
        guard hide != cursorHidden else { return }
        if hide { NSCursor.hide() } else { NSCursor.unhide() }
        cursorHidden = hide
    }

    // MARK: Quit and Finder open

    /// The flow's `.quit` (`ExitToShell` after `.Quit`'s sequence): terminate, not asked again.
    private func quitNow() {
        quitApproved = true
        NSApp.terminate(nil)
    }

    /// A terminate the flow did not ask for (the app menu's Quit, logout — the quit Apple event, `.DoQuitAppAE`): the
    /// event is queued in the flow and the terminate is cancelled at once — no terminate stays pending through play
    /// (AppKit would hold its run loop in the modal-panel mode). As the original: a `.CheckEvent` — the main menu's
    /// pass or the pause loop's — dispatches it and `.Quit` runs, whose `.quit` terminates (`quitNow`); `.GameLoop`
    /// with "Allow background tasks" fetches it and drops it (nothing more happens, the game goes on); anywhere else it
    /// waits (a level with the pref off holds it until a pause or the menu). A terminate while a quit is already
    /// queued, or while `.Quit` runs, adds nothing. File ▸ Quit (A1b) is a menu pick, not a terminate.
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let flow, !quitApproved else { return .terminateNow }
        if !flow.quitting && !flow.appleEvents.quit { flow.quitEvent() }
        return .terminateCancel
    }

    /// Finder open (`.DoOpenDocAE`): queued in the flow like the quit — the menu pass's `.CheckEvent` continues with the
    /// first file (`DAT_100a5106` set); inside a game the pause loop's ignores it (`5106` clear) and `.GameLoop`'s
    /// background-tasks fetch drops it; with neither it waits for the menu after the game.
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        let ref = SavedGameRef(url: url, displayName: url.lastPathComponent)
        guard let flow else {
            pendingOpen = ref
            return
        }
        flow.openDocument(ref)
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

    // MARK: Gamepad (GP, D37; HectorKit D16)

    /// The pad layout for the poll about to run (`FerazelPadLayout`): the live prefs' action keys (the running level's,
    /// which ⌘P's Options and the pause replace; else the flow's), the flow's `padContext`, whether a dialog is up.
    /// Assigning an equal mapping is a no-op in HectorShell.
    private func updatePadMapping() {
        guard let flow else { return }
        let keys = flow.levelRun?.prefs.keys ?? flow.toggles.live.keys
        shell.view.padMapping = FerazelPadLayout.mapping(keys: keys, context: flow.padContext,
                                                         dialogUp: dialogs?.isShowing == true)
    }

    /// The dialogs' 1/60 s null timer: while a dialog is up the flow does not tick, so this is the only poll — it turns
    /// pad presses into the dialog's Return / Esc (`shellView(_:padKeyDown:)`).
    private func pollPadInDialog() {
        guard dialogs?.isShowing == true else { return }
        updatePadMapping()
        _ = shell.view.pollKeyState()
    }

    /// A pad key went down. The game reads the keyboard by polling only (the held keys reach it through
    /// `pollInput`), so outside a dialog nothing more happens — as for a keyboard key-down. With a confirm or report
    /// up, Return and Esc reach it as a synthesized key-down + key-up posted to its panel — through the event queue, so
    /// `FerazelDialogs`' local event monitor sees them as it sees the keyboard's; Options and Credits take none.
    func shellView(_ view: ShellView, padKeyDown keyCode: UInt16) {
        guard dialogs?.isShowing == true,
              keyCode == FerazelPadLayout.returnKey || keyCode == FerazelPadLayout.escapeKey,
              let panel = dialogs?.padKeyPanel else { return }
        let chars = ShellKeyCharacters.characters(forKeyCode: keyCode) ?? ""
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            guard let event = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: [],
                                               timestamp: ProcessInfo.processInfo.systemUptime,
                                               windowNumber: panel.windowNumber, context: nil,
                                               characters: chars, charactersIgnoringModifiers: chars,
                                               isARepeat: false, keyCode: keyCode) else { return }
            NSApp.postEvent(event, atStart: false)
        }
    }

    // MARK: ShellInputHandler

    /// The game reads the keyboard and the mouse by polling (`GetKeys`, `Button`, `GetMouse`); events do nothing
    /// (⌃⌘F is a menu key equivalent).
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

// MARK: - LevelServices

/// The renderer side of a level (plan S2 `LevelServices`, L1; today's `openLevel` order): the level's `FrameRenderer`
/// on the shared surface (it leaves the surface's CLUT alone until the level's `setScreenClut`, FE0 — `.SetupLevel`'s
/// tail draws it before the loop, so the death wipe always paints under the level CLUT), then its lights and tint
/// table from the session.
extension FerazelController: @MainActor LevelServices {
    func prepare(level: Int) throws -> LevelFaces {
        let r = try FrameRenderer(resources: resources, level: level, search: search, dither: .errorDiffusion,
                                  text: rasterizer, prefs: flow.toggles.live, surface: surface)
        levelRenderer = r
        conversationRenderer = ConversationRenderer(frame: r, text: rasterizer, prefs: flow.toggles.live)
        conversationRun = flow.levelRun
        return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces)
    }

    func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
        guard let r = levelRenderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
        try r.addLights(lights)
        try r.buildTintTable(tintTableDraws)   // tint 0xa from the session's stream (E2 Part A)
    }

    /// `.DeathEffect`'s step k: the bands only — the step's gamma op is `LevelRun`'s (it rides the tick's output).
    func deathEffectStep(_ k: Int) throws {
        guard let r = levelRenderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
        guard (0..<DeathEffect.steps).contains(k) else { throw FrameRenderer.Refusal.deathEffectStep(k) }
        _ = r.deathEffect.frame(step: k, on: &surface.frame)
    }
}

import Foundation

/// How the App answered a `.dialog` request (`GameFlow.dialogDone`): OK (or the report's only button, or a click that
/// closed the credits) / Cancel.
public enum DialogResult: Equatable, Sendable {
    case ok
    case cancel
}

/// The whole game's front end as one tick machine (plan S2 `GameFlow`, F1a part 1; Invariant 3): `.main @ 1000ffc0`
/// (M l. 8136–8358) — the logo, the boot music, the boot keys, the loading screen and its 3-D bar — then
/// `.MainMenu @ 1000e618` (M l. 7303–7445): the buttons (`.TrackClickOnCommandButton`, mouse and keyboard), the
/// letter keys, the X joke, the menu bar at the top edge, `.Options` (M l. 7254–7288), `.Credits` (M l. 7291–7299) and
/// `.Quit @ 1000e9d4` (M l. 7447–7482). New Game (`.NewGame`) and Continue (`.ContinueGame`) end in the states
/// `.newGame` / `.continueGame`, which F1b fills (`// later: F1b`).
///
/// The original's nested blocking calls run as a queue of work items: each item is the code between two blocking
/// calls and may start one block (a `FrontTimeline`, a dialog, a load, the menu's idle, a button track); the queue
/// waits until the block ends — on the tick a timeline's trailing events are emitted — and goes on in the same tick.
/// One main-menu pass per tick (`.CheckEvent`'s `WaitNextEvent(…, 1, …)`), the next on the tick after a pass ends.
///
/// The App's side: tick with `ShellClock.ticks()` and the polled input; answer `.dialog` requests with `dialogDone`
/// (the Options dialog is driven through `prefsDialog`, the credits drawn from `credits`); while `state` is
/// `.loading(.sounds)` load the sound effects (none when `soundLoading` is false — F1 at boot), while
/// `.loading(.faces)` load the faces calling `loadProgress(faces:)`; then `loadFinished()`.
public final class GameFlow {
    /// What the App loads while the flow waits (`.InitSounds` + `.InitAppGlobals` under the logo, M l. 8324–8326;
    /// `.InitSprites`, `.InitFaces`, `.InitTiles` under the loading screen, M l. 8341–8343).
    public enum LoadPhase: Equatable, Sendable {
        case sounds
        case faces
    }

    public enum State: Equatable, Sendable {
        /// `.main` and the main menu's entry (fades, logo, loading screen).
        case boot
        /// Waiting for the App's load (`loadFinished()`).
        case loading(LoadPhase)
        /// The menu loop.
        case mainMenu
        /// DLOG 6900 up (`prefsDialog`).
        case options
        /// DLOG 600 up (`credits`).
        case credits
        /// `.NewGame` — later: F1b.
        case newGame
        /// `.ContinueGame(reply)` — later: F1b.
        case continueGame
        /// `ExitToShell` asked.
        case quit
    }

    public let resources: FerazelResources
    public let files: FrontFiles
    /// L1's renderer seam — unused until F1b opens a level.
    public let levels: LevelServices

    public private(set) var state: State = .boot
    /// O1's model while DLOG 6900 is up (nil otherwise); the App feeds the dialog's events into it and answers with
    /// `dialogDone` once its `result` is set.
    public var prefsDialog: PrefsDialogModel?
    /// The credits scroll while DLOG 600 is up.
    public private(set) var credits: CreditsScroll?
    /// The keyboard layout's character for a key code (`KeyTranslate`), for the Options dialog's key names (App).
    public var keyCharacter: @Sendable (Int16) -> String? = { _ in nil }

    /// The game's one random stream (Invariant 5), seeded once at launch.
    public internal(set) var rng: FastRand
    /// G and the save block (`_DAT_100a0054`) — F1b's.
    public internal(set) var globals = GameGlobals()
    public internal(set) var saveBlock = SaveBlock()
    /// The gamma-fade globals (`53c2`, `*fde8`, `53d6`).
    public private(set) var fade = ScreenFade()
    /// The live prefs, `fd20`, the sound scale and the music player.
    public internal(set) var toggles: PrefsToggles
    /// The boot bar.
    public private(set) var progressBar = ProgressBar3D()
    /// `DAT_100a5105`: sound effects are loaded (F1 at boot clears it; `.InitSounds` then loads none, M l. 39746).
    public private(set) var soundLoading = true
    /// `*_DAT_100a0220`: the menu bar is hidden (`.HideTheMenuBar` / `.ShowTheMenuBar` act only on a change).
    public private(set) var menuBarHidden = false
    /// `*_DAT_1009fd48`: a Continue was requested from inside a game (F1b sets it); each menu pass then runs
    /// `.ContinueGame(*_DAT_1009fd18)`.
    public internal(set) var continueRequested = false
    /// `_DAT_1009fd18`: the last Standard File reply (the saved game last opened or saved) — F1b's.
    public internal(set) var lastReply: SavedGameRef?
    /// `*_DAT_1009fd5c`: set to 1 before `.NewGame` from the menu (the default world).
    public internal(set) var defaultWorld: UInt8 = 0
    /// The status-bar redraw flags `*_DAT_1009fe0c` and `uRam100a511e`, set at the end of `.Options` (M l. 7285–7286).
    public internal(set) var statusBarRedrawFe0c = false
    public internal(set) var statusBarRedraw511e = false
    /// The menu loop's `sVar5`: the X joke's cooldown in passes.
    public private(set) var jokeCooldown = 0
    /// `*PTR_DAT_100a0b64`: the modifier the Options dialog last captured (a global, carried across openings).
    private var lastModifier: Int16 = 0

    private typealias Work = (GameFlow, UInt32, FrontInput, inout FrontOutput) -> Void

    /// A blocking call in progress.
    private enum Wait {
        case timeline(TimelineRun)
        case dialog
        case load
        /// `WaitNextEvent(…, 0x3c, …)`: up to 60 ticks, ended early by an event.
        case idle(start: UInt32)
        case track(ButtonTrack)
        /// The F1b seams: nothing ends it yet.
        case later
    }

    private var started = false
    private var queue: [Work] = []
    private var wait: Wait?
    /// Output made outside `tick` (the boot bar), emitted by the next tick.
    private var pending = FrontOutput()
    private var dialogAnswer: DialogResult?
    /// The answer the last dialog got.
    public private(set) var lastDialogResult: DialogResult?
    private var fileAnswer: FileResult?
    private var loadDone = false
    private var facesLoaded = 0
    private var trackResult = false
    private var lastPassEnd: UInt32?

    /// `prefs` = the live record `.main` built (`.InitPrefs` + `.MakeCurrPrefs`, M l. 8192–8243 — the App read it with
    /// `files.loadPrefs()`); `seed` = `FastRand.clockSeed` at launch (`.InitAppGlobals`' `FastRand(0)`).
    public init(resources: FerazelResources, prefs: FerazelPrefs, seed: Int32, files: FrontFiles,
                levels: LevelServices) {
        self.resources = resources
        self.files = files
        self.levels = levels
        rng = FastRand(seed: seed)
        toggles = PrefsToggles(live: prefs)
    }

    // MARK: - The App's calls

    public func tick(now: UInt32, input: FrontInput) -> FrontOutput {
        var out = pending
        pending = FrontOutput()
        if !started {
            started = true
            queue = bootWork() + menuEntryWork()
        }
        while true {
            if wait != nil {
                guard advance(now: now, input: input, out: &out) else { break }
            }
            if queue.isEmpty {
                guard state == .mainMenu, lastPassEnd != now else { break }
                queue = menuPass(active: input.active)
                continue
            }
            let work = queue.removeFirst()
            work(self, now, input, &out)
        }
        return out
    }

    /// The modal dialog the flow asked for was answered; the flow goes on at the next tick.
    public func dialogDone(_ result: DialogResult) {
        dialogAnswer = result
    }

    /// A Standard File dialog was answered (later: F1b — `.putFile` / `.getFile` are F1b's).
    public func fileDone(_ result: FileResult) {
        fileAnswer = result
    }

    /// `faces` faces loaded so far (cumulative): one `.Update3DProgBar(*018c + 0x48)` per new face; the redraws ride
    /// the next tick's output.
    public func loadProgress(faces: Int) {
        while facesLoaded < faces {
            facesLoaded += 1
            let ops = progressBar.update(progressBar.progress &+ ProgressBar3D.perFace)
            if !ops.isEmpty {
                pending.draws += ops
                pending.present = true
            }
        }
    }

    /// The App finished the load `state` asked for; the flow goes on at the next tick.
    public func loadFinished() {
        loadDone = true
    }

    // MARK: - Blocking calls

    private func advance(now: UInt32, input: FrontInput, out: inout FrontOutput) -> Bool {
        guard let w = wait else { return true }
        switch w {
        case .timeline(var run):
            out.append(run.tick(now: now))
            guard run.isDone(now: now) else { wait = .timeline(run); return false }
        case .dialog:
            guard let a = dialogAnswer else { return false }
            lastDialogResult = a
            dialogAnswer = nil
        case .load:
            guard loadDone else { return false }
            loadDone = false
        case .idle(let start):
            let event = input.button || input.keys != KeyState()
            guard event || Int(now &- start) >= BootSequence.menuIdleTicks else { return false }
        case .track(var track):
            let (events, result) = track.step(button: input.button, mouse: input.mouse)
            emit(events, button: track.button, &out)
            guard let result else { wait = .track(track); return false }
            trackResult = result
        case .later:
            return false
        }
        wait = nil
        return true
    }

    /// Starts a blocking timeline at `now` (its tick-0 events emitted now); a gated-off call does nothing.
    private func block(_ t: FrontTimeline, _ now: UInt32, _ out: inout FrontOutput) {
        guard !t.isEmpty else { return }
        var run = TimelineRun(t, start: now)
        out.append(run.tick(now: now))
        if !run.isDone(now: now) { wait = .timeline(run) }
    }

    /// Runs `items` before the rest of the queue (a nested call's body).
    private func run(_ items: [Work]) {
        queue.insert(contentsOf: items, at: 0)
    }

    /// `ReportDialog(text)` (DLOG 200), modal.
    private func report(_ text: String, _ out: inout FrontOutput) {
        out.requests.append(.dialog(.report(text: text)))
        wait = .dialog
    }

    private func draw(_ ops: [DrawOp], _ out: inout FrontOutput) {
        guard !ops.isEmpty else { return }
        out.draws += ops
        out.present = true
    }

    private func gammaFadeOut(_ now: UInt32, _ out: inout FrontOutput) {
        block(fade.gammaFadeOut(6, rgb: RGB16(0, 0, 0)), now, &out)   // `_DAT_100a53d0…`: the async colour only
    }

    private func gammaFadeIn(_ now: UInt32, _ out: inout FrontOutput) {
        block(fade.gammaFadeIn(6), now, &out)
    }

    /// `.HideTheMenuBar` (`MT_HideMenubar` + `MTRedraw` when shown).
    private func hideMenuBar(_ out: inout FrontOutput) {
        guard !menuBarHidden else { return }
        menuBarHidden = true
        out.requests.append(.hideMenuBar)
        out.present = true
    }

    /// `.ShowTheMenuBar`.
    private func showMenuBar(_ out: inout FrontOutput) {
        guard menuBarHidden else { return }
        menuBarHidden = false
        out.requests.append(.showMenuBar)
    }

    /// `.UpdateMenus` (M l. 28763ff): the menus live in the menu loop, the Music / Sound Effects check marks.
    private func updateMenus(_ out: inout FrontOutput) {
        out.requests.append(.showMenuBarItems(MenuState(menusLive: true, paused: false,
                                                        musicOn: toggles.live.musicOn != 0,
                                                        soundOn: toggles.live.soundOn != 0)))
    }

    /// `.STPlayRegSound(snd, 10, 0x55)`: nothing with sound off (prefs+0x0b). F1 at boot does not silence it:
    /// 4803 / 4804 are loaded by `.InitAppGlobals` unconditionally (M l. 352–357); only `.InitSounds` checks `5105`
    /// (M l. 39746).
    private func buttonSound(_ snd: Int16, _ out: inout FrontOutput) {
        guard toggles.live.soundOn != 0 else { return }
        out.sounds.append(SoundCues.regSound(snd: snd, priority: MainMenu.soundPriority, volume: MainMenu.soundVolume,
                                             global: SoundCues.globalVolume(toggles.live)))
    }

    /// `.MTGetandDrawPICTResInRect(id, rect)`: `DrawPicture` into the rect (scaled from the picFrame); a missing
    /// picture only beeps.
    private func pictureInRect(_ id: Int16, _ rect: Rect16) -> [DrawOp] {
        guard let size = ChapterScreenRun.frameSize(resources.resource(type: "PICT", id: id, chain: .frontEnd)?.data)
        else { return [] }
        let source = Rect16(top: 0, left: 0, bottom: Int16(truncatingIfNeeded: size.height),
                            right: Int16(truncatingIfNeeded: size.width))
        return [.copyPicture(id: id, chain: .frontEnd, source: source, dest: rect, forceClut: nil, transparent: false)]
    }

    private func emit(_ events: [ButtonTrack.Event], button n: Int, _ out: inout FrontOutput) {
        for e in events {
            switch e {
            case .highlight:
                draw(pictureInRect(MainMenu.highlightPicture(n), MainMenu.rects[n - 1]), &out)
                buttonSound(MainMenu.enterSound, &out)
            case .normal:
                draw(pictureInRect(MainMenu.normalPicture(n), MainMenu.rects[n - 1]), &out)
                buttonSound(MainMenu.exitSound, &out)
            }
        }
    }

    // MARK: - .main (M l. 8264–8350)

    private func bootWork() -> [Work] {
        [
            // `GammaFadeOut(6)` before `.InitEngine` (M l. 8273).
            { f, now, _, out in f.gammaFadeOut(now, &out) },
            { f, now, _, out in
                // `SwitchTo8BitColorMT`, PICT 131, `MTShowWindow`, `.HideTheMenuBar`, `MTRedraw` (M l. 8277–8281).
                f.draw([.drawPicture(id: BootSequence.logoPicture, chain: .frontEnd, h: 0, v: 0)], &out)
                f.hideMenuBar(&out)
                // The Sound Tool's init and the startup system volume (M l. 8282–8295): never the Mac's volume (Known
                // deviation 8). `.InitMusic`; QuickTime is always present (M l. 8297–8303).
                let v = MusicFade.fullVolume(f.toggles.live)
                out.music += f.toggles.setMusicVolume(v)            // no movie loaded: nothing
                f.block(f.toggles.music.fadeAIFFMusic(direction: 0, ticks: 99, prefs: f.toggles.live), now, &out)
            },
            { f, _, _, out in out.music += f.toggles.music.setAIFFMusic(BootSequence.bootTrack) },
            { f, now, _, out in
                f.block(f.toggles.music.fadeAIFFMusic(direction: 1, ticks: 6, prefs: f.toggles.live), now, &out)
            },
            { f, now, _, out in f.gammaFadeIn(now, &out) },
            { f, _, input, out in
                // The boot keys, polled once (M l. 8311–8320).
                let (n, fKey) = BootSequence.fadingDisabledKeys
                if input.keys.isPressed(n), input.keys.isPressed(fKey) {
                    f.fade.fadingEnabled = false
                    f.report(BootSequence.fadingDisabledReport, &out)
                }
            },
            { f, _, input, out in
                guard input.keys.isPressed(BootSequence.soundLoadingKey) else { return }
                f.report(BootSequence.soundLoadingReport, &out)
                f.run([{ f, _, _, _ in f.soundLoading = false }])
            },
            { f, _, _, _ in
                // `*fd20 = prefs+0x0c` (M l. 8322), `ResetCursor`, then `.InitSounds` + `.InitAppGlobals`: the App's load.
                f.toggles.appliedMusicOn = f.toggles.live.musicOn
                f.state = .loading(.sounds)
                f.wait = .load
            },
            { f, now, _, out in
                f.state = .boot
                f.gammaFadeOut(now, &out)                           // M l. 8328
            },
            { f, now, _, out in
                f.draw([.setScreenClut(id: BootSequence.loadingClut),
                        .drawPicture(id: BootSequence.loadingPicture, chain: .frontEnd, h: 0, v: 0)], &out)
                f.gammaFadeIn(now, &out)                            // M l. 8336
            },
            { f, _, _, _ in
                // `SetWatchCursor`, `MTRedraw`, `*fcd4 = 1`, `.Init3DProgBar(36, 440, 190)`, then the face loads.
                f.progressBar = ProgressBar3D()
                f.facesLoaded = 0
                f.state = .loading(.faces)
                f.wait = .load
            },
            { f, _, _, out in
                f.state = .boot
                f.draw(f.progressBar.update(0x10000), &out)         // M l. 8344
                // `ResetCursor`, `MTSetPortScreen`, then `.MainMenu`.
            },
        ]
    }

    // MARK: - .MainMenu (M l. 7303–7445)

    private func menuEntryWork() -> [Work] {
        [
            { f, now, _, _ in f.wait = .idle(start: now) },          // `WaitNextEvent(0xffff, …, 0x3c)`
            { f, now, _, out in f.gammaFadeOut(now, &out) },
            { f, now, _, out in
                // `.DrawMainMenu` (no sprites alive at the menu: `KillAllSprites` has nothing to do), `.UpdateMenus`,
                // `MTRedraw`, `GammaFadeIn(6)`.
                f.draw([.setScreenClut(id: MainMenu.clut),
                        .drawPicture(id: MainMenu.picture, chain: .frontEnd, h: 0, v: 0)], &out)
                f.updateMenus(&out)
                f.gammaFadeIn(now, &out)
            },
            { f, _, _, _ in f.state = .mainMenu },
        ]
    }

    /// One loop pass. The mouse and the keys are read only while the app is active (`DAT_100a5108`).
    private func menuPass(active: Bool) -> [Work] {
        var items: [Work] = []
        if active {
            items.append { f, _, input, out in f.mouseBlock(input, &out) }
            items.append { f, now, input, out in f.keyBlock(now, input, &out) }
        }
        items.append { f, _, _, out in
            if f.continueRequested { f.continueGame(f.lastReply, &out) }
        }
        items.append { f, now, _, _ in
            if f.jokeCooldown > 0 { f.jokeCooldown -= 1 }
            f.lastPassEnd = now                                     // `.CheckEvent`, `MusicAIFFTickle`
        }
        return items
    }

    /// The hot rects (M l. 7332–7386).
    private func mouseBlock(_ input: FrontInput, _ out: inout FrontOutput) {
        guard let m = input.mouse else { return }       // off the canvas: no button, no global position to test
        guard let n = MainMenu.button(h: m.h, v: m.v) else {
            if m.v < MainMenu.menuBarRevealV { showMenuBar(&out) } else { hideMenuBar(&out) }
            return
        }
        mouseTrack(n, input, &out)
        run([{ f, _, _, out in if f.trackResult { f.buttonAction(n, mouse: true, &out) } }])
    }

    /// `.TrackClickOnCommandButton(n, 1)` — and `(n, 0)` with the button down: the mouse loop; the button up → 0.
    private func mouseTrack(_ n: Int, _ input: FrontInput, _ out: inout FrontOutput) {
        trackResult = false
        guard input.button else { return }
        var track = ButtonTrack(button: n)
        let (events, _) = track.step(button: true, mouse: input.mouse)
        emit(events, button: n, &out)
        wait = .track(track)
    }

    /// `.TrackClickOnCommandButton(n, 0)` with the button up: highlight + 4803, `Delay(10)`, normal + 4804.
    private func keyTrack(_ n: Int, _ now: UInt32, _ input: FrontInput, _ out: inout FrontOutput) {
        guard !input.button else { mouseTrack(n, input, &out); return }
        var on = FrontOutput(), off = FrontOutput()
        emit([.highlight], button: n, &on)
        emit([.normal], button: n, &off)
        trackResult = true
        block(FrontTimeline(events: [.init(at: 0, output: on), .init(at: MainMenu.keyboardTrackTicks, output: off)],
                            duration: MainMenu.keyboardTrackTicks), now, &out)
    }

    /// The letter keys (M l. 7388–7431), in the loop's order; the keyboard New Game has no `GammaFadeIn(6)`.
    private func keyBlock(_ now: UInt32, _ input: FrontInput, _ out: inout FrontOutput) {
        let k = input.keys
        let n: Int
        if k.isPressed(MainMenu.newGameKey) { n = 1 }
        else if MainMenu.continueKeys.contains(where: k.isPressed) { n = 2 }
        else if MainMenu.optionsKeys.contains(where: k.isPressed) { n = 3 }
        else if k.isPressed(MainMenu.creditsKey) { n = 4 }
        else if k.isPressed(MainMenu.quitKey) { n = 5 }
        else {
            if k.isPressed(MainMenu.jokeKey), jokeCooldown == 0 {
                jokeCooldown = MainMenu.jokeCooldown
                report(MainMenu.comingSoon, &out)
            }
            return
        }
        keyTrack(n, now, input, &out)
        run([{ f, _, _, out in f.buttonAction(n, mouse: false, &out) }])
    }

    private func buttonAction(_ n: Int, mouse: Bool, _ out: inout FrontOutput) {
        switch n {
        case 1:
            defaultWorld = 1
            var items: [Work] = [{ f, _, _, out in f.newGame(&out) }]
            if mouse { items.append { f, now, _, out in f.gammaFadeIn(now, &out) } }
            run(items)
        case 2: continueGame(nil, &out)
        case 3: options()
        case 4: creditsDialog()
        default: quit()
        }
    }

    // MARK: - The buttons' calls

    /// `.NewGame @ 1000b11c` (M l. 5704ff) — later: F1b (G init, the save block, the first level, the level ⇄ map loop).
    private func newGame(_ out: inout FrontOutput) {
        state = .newGame
        wait = .later
    }

    /// `.ContinueGame(reply) @ 1000d004` (M l. 6663ff; 0 from the menu, `fd18` when `fd48` is set) — later: F1b.
    private func continueGame(_ reply: SavedGameRef?, _ out: inout FrontOutput) {
        state = .continueGame
        wait = .later
    }

    /// `.Options @ 1000e470` (M l. 7254–7288).
    private func options() {
        run([
            { f, _, _, out in
                // `FlushEvents`, `InputActivate(0,0)` (no InputSprocket), `ShowCursorSafe`, the prefs file re-read.
                out.requests.append(.showCursor)
                let record = f.files.loadPrefs().map(FerazelPrefs.init(record:)) ?? FerazelPrefs()
                f.prefsDialog = PrefsDialogModel(record: record, live: f.toggles, paused: false,
                                                 lastModifier: f.lastModifier, keyCharacter: f.keyCharacter)
                f.state = .options
                out.requests.append(.dialog(.preferences))
                f.wait = .dialog
            },
            { f, _, _, out in
                // The record written back on every close, `MTRedraw`, `.MakeCurrPrefs`, `.UpdateMenus`, fe0c / 511e.
                guard let model = f.prefsDialog else { return }
                try? f.files.storePrefs(model.record.record())
                out.present = true
                f.toggles = model.live
                f.lastModifier = model.lastModifier
                out.append(f.toggles.makeCurrPrefs(model.record, paused: false))
                f.updateMenus(&out)
                f.statusBarRedrawFe0c = true
                f.statusBarRedraw511e = true
                f.prefsDialog = nil
                f.state = .mainMenu
            },
        ])
    }

    /// `.Credits` → `.DoAboutDialog(600, 4803)`: modal until a click inside closes it (the App's, `CreditsScroll`).
    private func creditsDialog() {
        run([
            { f, now, _, out in
                let size = ChapterScreenRun.frameSize(
                    f.resources.resource(type: "PICT", id: CreditsScroll.stripPicture, chain: .frontEnd)?.data)
                    ?? (144, 811)
                f.credits = CreditsScroll(start: now, stripWidth: size.width, stripHeight: size.height)
                f.state = .credits
                out.requests.append(.dialog(.credits))
                f.wait = .dialog
            },
            { f, _, _, _ in
                f.credits = nil
                f.state = .mainMenu
            },
        ])
    }

    /// `.Quit @ 1000e9d4` (M l. 7447–7482). The prefs are not written; `STSetVolume` of the startup volume is not
    /// reproduced (Known deviation 8).
    private func quit() {
        run([
            { f, now, _, out in
                // `InitCursor`, `ShowCursorSafe`, `SetWatchCursor`, `FlushEvents`, `FadeAIFFMusic(0,1)`.
                out.requests.append(.showCursor)
                f.block(f.toggles.music.fadeAIFFMusic(direction: 0, ticks: 1, prefs: f.toggles.live), now, &out)
            },
            { f, now, _, out in
                out.music += f.toggles.music.shutDown()
                f.hideMenuBar(&out)                                 // after `FlameDispose`
                f.gammaFadeOut(now, &out)
            },
            { f, _, _, out in
                // `SetScreenClut(clut 801)` (`_DAT_100a0038`, M l. 358), `.ShowTheMenuBar`, `DrawMenuBar`, the
                // window hidden, `ExitToShell`.
                f.draw([.setScreenClut(id: 0x321)], &out)
                f.showMenuBar(&out)
                out.requests.append(.quit)
                f.state = .quit
                f.wait = .later
            },
        ])
    }
}

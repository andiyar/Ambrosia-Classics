import Foundation

/// How the App answered a `.dialog` request (`GameFlow.dialogDone`): OK (or the report's only button, or a click that
/// closed the credits) / Cancel.
public enum DialogResult: Equatable, Sendable {
    case ok
    case cancel
}

/// One renderer's run of draws in a `GameFlow` tick (F1b; A1a routes them, in order, onto the one shared screen):
/// the level-less `ScreenRenderer` (the flow's own draws, the stage screens, the death screen and the `.screen`
/// segments of a `LevelRun`), the level `FrameRenderer` (a `LevelRun`'s `.level` segments), the map's `MapRenderer`.
public enum FlowSegment: Equatable, Sendable {
    case screen([DrawOp])
    case level([DrawOp])
    case map([MapOp])
}

/// The Apple events the system sent that no `.CheckEvent` has dispatched yet (A1a; the high-level event queue,
/// first in first out like the Event Manager's). Only two calls take them: `.CheckEvent` (`WaitNextEvent(0xffff, …, 1,
/// …)` + `.HandleEvent`'s `AEProcessAppleEvent`, M l. 7487–7530) in the menu loop (M l. 7441) and the pause loop (M l.
/// 3218) dispatches one; `.GameLoop`'s `WaitNextEvent(0xffff, …)` when prefs+0x08 "Allow background tasks" is set
/// fetches one per finished iteration and never handles it (M l. 5277–5279). `.MainMenu`'s 60-tick idle (M l. 7323)
/// leaves them: the pending activate / update events come back first, so a queued Apple event reaches the menu pass.
/// Elsewhere (the stage screens, the map loop, the death screen, `.Quit`'s sequence) they stay queued.
public struct PendingAppleEvents: Equatable, Sendable {
    public enum Event: Equatable, Sendable {
        /// `'quit'` → `.DoQuitAppAE` → `.Quit` (M l. 31240–31245).
        case quit
        /// `'odoc'` → `.DoOpenDocAE`: `.ContinueGame(&reply)` only while `DAT_100a5106` is set (M l. 31166–31236).
        case open(SavedGameRef)
    }

    /// The queue, oldest first.
    public private(set) var events: [Event] = []

    public init(_ events: [Event] = []) {
        self.events = events
    }

    /// A `'quit'` is waiting.
    public var quit: Bool { events.contains(.quit) }
    /// The oldest `'odoc'` waiting (its first file).
    public var open: SavedGameRef? {
        for case .open(let ref) in events { return ref }
        return nil
    }

    public var isEmpty: Bool { events.isEmpty }

    /// The system sent `event`: queued behind the others.
    public mutating func post(_ event: Event) {
        events.append(event)
    }

    /// The oldest event out of the queue, or nil.
    public mutating func takeFirst() -> Event? {
        events.isEmpty ? nil : events.removeFirst()
    }
}

/// The whole game's front end as one tick machine (plan S2 `GameFlow`, F1a part 1; Invariant 3): `.main @ 1000ffc0`
/// (M l. 8136–8358) — the logo, the boot music, the boot keys, the loading screen and its 3-D bar — then
/// `.MainMenu @ 1000e618` (M l. 7303–7445): the buttons (`.TrackClickOnCommandButton`, mouse and keyboard), the
/// letter keys, the X joke, the menu bar at the top edge, `.Options` (M l. 7254–7288), `.Credits` (M l. 7291–7299) and
/// `.Quit @ 1000e9d4` (M l. 7447–7482). F1b: New Game (`.NewGame`, `NewGame.swift`) and Continue (`.ContinueGame`,
/// `ContinueGame.swift`) — the level ⇄ map loop over `LevelRun` and `WorldMapRun`, death → `DeathScreen`.
///
/// The original's nested blocking calls run as a queue of work items: each item is the code between two blocking
/// calls and may start one block (a `FrontTimeline`, a dialog, a load, the menu's idle, a button track); the queue
/// waits until the block ends — on the tick a timeline's trailing events are emitted — and goes on in the same tick.
/// One main-menu pass per tick (`.CheckEvent`'s `WaitNextEvent(…, 1, …)`), the next on the tick after a pass ends.
///
/// The App's side: tick with `ShellClock.ticks()` and the polled input; answer `.dialog` requests with `dialogDone`
/// (the Options dialog is driven through `prefsDialog`, the credits drawn from `credits`); while `state` is
/// `.loading(.sounds)` load the sound effects (none when `soundLoading` is false — F1 at boot), while
/// `.loading(.faces)` load the faces calling `loadProgress(faces:)`; then `loadFinished()`. Draw each tick's
/// `segments` on their renderers in order (F1b); answer `.getFile` with `fileDone`.
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
        /// `.NewGame` running (its level ⇄ map loop, the death screen, the menu return).
        case newGame
        /// `.ContinueGame(reply)` running (the file dialog, the refusals, its loop, the death screen, the menu return).
        case continueGame
        /// `ExitToShell` asked.
        case quit
    }

    public let resources: FerazelResources
    public let files: FrontFiles
    /// L1's renderer seam (each `LevelRun`'s).
    public let levels: LevelServices

    public internal(set) var state: State = .boot
    /// O1's model while DLOG 6900 is up (nil otherwise); the App feeds the dialog's events into it and answers with
    /// `dialogDone` once its `result` is set. P1: inside a level, ⌘P's model is the `LevelRun`'s.
    /// A1b: the pause's Game ▸ Preferences… model (in a level or on the map) comes through here too.
    public var prefsDialog: PrefsDialogModel? {
        get { levelRun?.prefsDialog ?? levelRun?.pausePrefsDialog ?? worldMap?.pausePrefsDialog ?? menuPrefsDialog }
        set {
            if let run = levelRun, run.prefsDialog != nil {
                run.prefsDialog = newValue
            } else if let run = levelRun, run.pausePrefsDialog != nil {
                run.pausePrefsDialog = newValue
            } else if let m = worldMap, m.pausePrefsDialog != nil {
                m.pausePrefsDialog = newValue
            } else {
                menuPrefsDialog = newValue
            }
        }
    }
    private var menuPrefsDialog: PrefsDialogModel?
    /// The credits scroll while DLOG 600 is up — the main menu's, or (A1b) the pause's Apple ▸ About.
    public var credits: CreditsScroll? { menuCredits ?? levelRun?.pause?.credits ?? worldMap?.pause?.credits }
    private var menuCredits: CreditsScroll?
    /// The keyboard layout's character for a key code (`KeyTranslate`), for the Options dialog's key names (App).
    public var keyCharacter: @Sendable (Int16) -> String? = { _ in nil }

    /// The game's one random stream (Invariant 5), seeded once at launch.
    public internal(set) var rng: FastRand
    /// G and the save block (`_DAT_100a0054`) — F1b's.
    public internal(set) var globals = GameGlobals()
    public internal(set) var saveBlock = SaveBlock()
    /// The gamma-fade globals (`53c2`, `*fde8`, `53d6`).
    public internal(set) var fade = ScreenFade()
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
    /// `*PTR_DAT_100a0b64`: the modifier the Options dialog last captured (a global, carried across openings — and into
    /// a level's ⌘P, P1).
    var lastModifier: Int16 = 0

    // MARK: F1b — the game's state

    /// The hidden `FerazelLevel` switch (D35, kept): New Game starts at this level instead of the literal 1 (raw
    /// `1000b2b8..1000b2cc`). The App passes it (A1a); a level outside `BuiltLevels.range` starts level 1.
    public var startLevel = 1
    /// The stage screens' sound lengths (snd id → ticks; `StageSounds`) — the App fills them from its `SoundBank` (A1a).
    public var soundLengths: [Int16: Int] = [:]
    /// `GetDateTime` (seconds since 1904) for `.EndLevelSGUpdate` — Core never reads a clock; the App supplies it.
    public var dateTime: @Sendable () -> UInt32 = { 0 }
    /// `*_DAT_1009feac` / `_DAT_100ab9ba`: the level being played (the one `OpenDefaultWorldLevel` last opened).
    public internal(set) var levelNumber = 0
    /// `*PTR_DAT_1009fe00`: something was saved or loaded this game (`.OpenSG` and the save-point save set it; New
    /// Game clears it) — `.AskToContinue` shows nothing without it.
    public internal(set) var savedThisGame = false
    /// `*_DAT_1009fd54`: the saved-game file is known (`.OpenSG` sets it; New Game clears it).
    public internal(set) var saveFileKnown = false
    /// `*_DAT_1009ffa8`: the player died in the last level (`LevelRun.died`); `.InitGameGlobals`' tail clears it
    /// (M l. 818). Continue's after-loop test reads it (raw `1000d7ac`), New Game's reads G+4.
    public internal(set) var died = false
    /// `DAT_100a5106`: the game loop is over (death, an abort, the map's −1).
    public internal(set) var loopEnded = false
    /// `*_DAT_100a0088`: the last level was completed (the exit sprite; `.GameLoop` clears it on entry, M l. 5151).
    public internal(set) var levelComplete = false
    /// `*_DAT_1009fd4c`: the game was aborted on the map. `*_DAT_1009fd50`: ⌘Q's OK on the map — Quit.
    public internal(set) var aborted = false
    public internal(set) var quitRequested = false
    /// `sRam100a5116` / `_DAT_100a5118`: the exit globals (the exit sprite's p1 / p2); `.ShowWorldMap` resets them to −1.
    public internal(set) var exit1: Int16 = -1
    public internal(set) var exit2: Int16 = -1
    /// `*_DAT_1009fd64`: skip the next `.StageCompleteEffect` (`LevelRun` clears it at a completion).
    public internal(set) var skipStageComplete = false
    /// The last level's scroll point and working-CLUT entry 255 when it ended (the death screen's, D1).
    var deathScroll = (h: 0, v: 0)
    var deathEntry255 = RGB16(0, 0, 0)
    /// `.AskToContinue`'s last return (nil before any death screen).
    public internal(set) var lastAskToContinue: Bool?
    /// The level running, the map up, the death screen up (nil otherwise).
    public internal(set) var levelRun: LevelRun?
    public internal(set) var worldMap: WorldMapRun?
    public internal(set) var deathScreen: DeathScreen?
    /// What runs on from level to level **and from game to game** (L1 carry): the parity, the particle counters, the
    /// water-effects cache, the tileset globals `DAT_100a267d` / `_DAT_100a267e` and the class face cache are globals
    /// only the launch data section initialises; G (and its crunch log) is set per game.
    public internal(set) var levelCarry = LevelCarry()
    /// The node-sprite list (`_DAT_100a0c30`, count `*_DAT_100a0c50`): carried from map run to map run (emptied on
    /// each map exit, M l. 67652, and by `.InitPlayerMapData` on a new game, M l. 66610).
    public internal(set) var mapSprites: [MapSprite] = []
    /// This tick's draws by renderer, in order (F1b; A1a routes them): the tick's `FrontOutput` holds every sound,
    /// music cue and request, and the `.screen` / `.level` draws in order — the map's ops are only here.
    public private(set) var segments: [FlowSegment] = []
    /// `out.draws` up to here are in `segments`.
    private var segmentMark = 0

    typealias Work = (GameFlow, UInt32, FrontInput, inout FrontOutput) -> Void

    /// A blocking call in progress.
    enum Wait {
        case timeline(TimelineRun)
        case dialog
        case load
        /// `WaitNextEvent(…, 0x3c, …)`: up to 60 ticks, ended early by an event.
        case idle(start: UInt32)
        case track(ButtonTrack)
        /// A level (`LevelRun.end`), the map (`WorldMapRun.result`), the death screen (`isDone`).
        case level
        case map
        case death
        /// A Standard File dialog (`fileDone`).
        case file
        /// `ExitToShell`: nothing ends it.
        case later
    }

    private var started = false
    var queue: [Work] = []
    var wait: Wait?
    /// Output made outside `tick` (the boot bar), emitted by the next tick.
    private var pending = FrontOutput()
    private var dialogAnswer: DialogResult?
    /// The answer the last dialog got.
    public private(set) var lastDialogResult: DialogResult?
    var fileAnswer: FileResult?
    private var loadDone = false
    private var facesLoaded = 0
    private var trackResult = false
    private var lastPassEnd: UInt32?
    /// The running level threw (a session or renderer failure) — reported as the level-load error.
    var levelFailed = false
    /// A1a: the Apple events no `.CheckEvent` has taken yet (`openDocument`, `quitEvent`; `PendingAppleEvents`). A
    /// running `LevelRun` / `WorldMapRun` takes them over for its tick (its game loop and its pause loop).
    public internal(set) var appleEvents = PendingAppleEvents()
    /// `.Quit` has started (by any path): it never returns, so no later event is ever dispatched.
    public internal(set) var quitting = false

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
        segments = []
        segmentMark = 0
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
        flushScreen(out)
        return out
    }

    /// The modal dialog the flow asked for was answered (the map's confirms — and its pause's — go to the map, a level's
    /// to its `LevelRun`); the flow goes on at the next tick.
    public func dialogDone(_ result: DialogResult) {
        if case .map = wait, let m = worldMap {
            m.dialogDone(ok: result == .ok)
            lastDialogResult = result
            return
        }
        // Inside a level every modal belongs to the `LevelRun`: a save point's error report (S1), the
        // `.CheckGameLoopKeys` confirms, ⌘P's Options and the pause's Abort Game confirm (P1).
        if case .level = wait, let run = levelRun {
            run.dialogDone(result)
            lastDialogResult = result
            return
        }
        dialogAnswer = result
    }

    /// A Standard File dialog (`.getFile`, or a save point's `.putFile` inside a level) was answered; the flow goes on
    /// at the next tick. A level's answer goes to its `LevelRun` and never reaches the flow's own `fileAnswer` (so no
    /// stale reply can feed Continue's `.OpenSG`).
    public func fileDone(_ result: FileResult) {
        if case .level = wait, let run = levelRun {
            run.fileDone(result)
            return
        }
        fileAnswer = result
    }

    // MARK: - Segments

    /// The flow's own draws since the last mark → a `.screen` segment.
    private func flushScreen(_ out: FrontOutput) {
        guard out.draws.count > segmentMark else { return }
        addSegment(.screen(Array(out.draws[segmentMark...])))
        segmentMark = out.draws.count
    }

    private func addSegment(_ g: FlowSegment) {
        switch (segments.last, g) {
        case (.screen(let a)?, .screen(let b)): segments[segments.count - 1] = .screen(a + b)
        case (.level(let a)?, .level(let b)): segments[segments.count - 1] = .level(a + b)
        case (.map(let a)?, .map(let b)): segments[segments.count - 1] = .map(a + b)
        default: segments.append(g)
        }
    }

    /// A `LevelRun` tick's output: its segments kept as tagged (`.level` → the level renderer, `.screen` → the screen
    /// renderer); everything appended to `out` in order.
    func emit(_ o: LevelRunOutput, _ out: inout FrontOutput) {
        flushScreen(out)
        for g in o.segments {
            out.append(g.output)
            if !g.output.draws.isEmpty {
                addSegment(g.target == .level ? .level(g.output.draws) : .screen(g.output.draws))
            }
        }
        segmentMark = out.draws.count
    }

    /// A `WorldMapRun` tick's output: its ops as a `.map` segment, its cues and requests into `out`.
    func emit(_ o: WorldMapOutput, _ out: inout FrontOutput) {
        flushScreen(out)
        out.append(o.output)
        if !o.ops.isEmpty { addSegment(.map(o.ops)) }
        segmentMark = out.draws.count
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

    // MARK: - The Apple events (A1a)

    /// `.DoOpenDocAE @ 10033dbc` (M l. 31166–31236; save-continue §4): the Finder opened `ref` → `.ContinueGame(&reply)`
    /// while `DAT_100a5106` is set (no game loop running; data-section initial 1). The event waits in the queue
    /// (`appleEvents`) until a `.CheckEvent` dispatches it: the menu pass's end continues with it; the pause loop's (in a
    /// level or on the map: `5106` clear) takes it and does nothing more (M l. 31221–31225); `.GameLoop`'s
    /// background-tasks fetch drops it.
    public func openDocument(_ ref: SavedGameRef) {
        appleEvents.post(.open(ref))
    }

    // MARK: - The menu bar (A1b)

    /// The menu bar takes picks now: the original handles menu events only in `.CheckEvent` — the main-menu loop's pass
    /// (M l. 7441) and the pause loop's poll (M l. 3218). Elsewhere (the boot, a level or the map not paused, the stage
    /// screens, the death screen, `.Quit`) the App disables every item, so the ⌘ keys reach the polled game keys.
    public var menusLive: Bool {
        if quitting { return false }
        if let run = levelRun { return run.pause?.acceptsMenus ?? false }
        if let m = worldMap { return m.pause?.acceptsMenus ?? false }
        return state == .mainMenu && pendingMenu == nil
    }

    /// A menu item was chosen (`MenuSelect` / `MenuKey` → `.HandleMenuSelection`, M l. 28795ff): in a pause loop it
    /// goes to the `LevelRun` / `WorldMapRun` (their pause's next poll); in the main menu it waits for the pass's
    /// `.CheckEvent`. Anywhere `menusLive` is false it is dropped.
    public func menuChosen(_ item: PauseRun.MenuItem) {
        guard menusLive else { return }
        if let run = levelRun { run.menuChosen(item); return }
        if let m = worldMap { m.menuChosen(item); return }
        pendingMenu = item
    }

    /// The main menu's pick waiting for the pass's `.CheckEvent` — an event in the OS queue: a pick made while a
    /// button flashes waits there, and the `FlushEvents(0xff7f, 0)` that opens each button's call (`.NewGame`,
    /// `.ContinueGame`, `.Options`, `.Credits`, `.Quit` — M l. 5745, 6705, 7266, 7296, 7458) drops it (`flushEvents`).
    private var pendingMenu: PauseRun.MenuItem?

    /// `FlushEvents(0xff7f, 0)`: every OS event but disk events — a waiting menu pick is dropped (the high-level queue,
    /// `appleEvents`, is not touched).
    func flushEvents() {
        pendingMenu = nil
    }

    /// The menu-loop liveness the App was last sent (`MenuState.menusLive` — the App's one source for the menu bar):
    /// `.UpdateMenus` in the menu loop sends it live; leaving the loop for a game (`.NewGame`, `.ContinueGame`) sends it
    /// dead, and a Continue that comes back without a game (cancelled, refused, a level-load error) live again. Inside a
    /// game the pause and the level's Options send their own.
    private var menuBarListening = false

    /// Sends `MenuState(menusLive: live)` (not paused, the live check marks) when it changes.
    func menuLoopListening(_ live: Bool, _ out: inout FrontOutput) {
        guard live != menuBarListening else { return }
        menuBarListening = live
        out.requests.append(menuState(live: live))
    }

    private func menuState(live: Bool) -> ShellRequest {
        .showMenuBarItems(MenuState(menusLive: live, paused: false, musicOn: toggles.live.musicOn != 0,
                                    soundOn: toggles.live.soundOn != 0))
    }

    /// `.HandleMenuSelection` in the menu loop (not paused: Abort Game is disabled).
    private func menuSelection(_ item: PauseRun.MenuItem, _ out: inout FrontOutput) {
        switch item {
        case .newGame:
            // `*_DAT_1009fd5c = 1`, `.NewGame()` (M l. 28859–28860) — no button track, no `GammaFadeIn(6)` after.
            defaultWorld = 1
            run([{ f, _, _, out in f.newGame(&out) }])
        case .restoreGame: continueGame(nil, &out)                    // `.ContinueGame(0)`
        case .abortGame: break                                         // disabled when not paused
        case .quit: quit()
        case .about: creditsDialog()                                   // `.Credits`
        case .preferences: options()
        case .music, .soundEffects:
            // `.ToggleMusic` / `.ToggleSound` (M l. 7105–7214): the record re-read, toggled, written back,
            // `.MakeCurrPrefs` (not paused), `.UpdateMenus`.
            var record = files.loadPrefs().map(FerazelPrefs.init(record:)) ?? FerazelPrefs()
            let o = item == .music ? toggles.toggleMusic(&record, paused: false)
                                   : toggles.toggleSound(&record, paused: false)
            try? files.storePrefs(record.record())
            out.append(o)
            updateMenus(&out)
        }
    }

    /// `.DoQuitAppAE @ 10033f24` (M l. 31240–31245): the system's quit → `.Quit` (no confirm) when a `.CheckEvent`
    /// dispatches it — the menu pass's end or the pause loop's poll (M l. 3218: in a level the run ends `.quit`, on the
    /// map `quitEventDispatched`); `.GameLoop`'s background-tasks fetch drops it (`appleEvents`). The App cancels the
    /// system's terminate and terminates at the flow's `.quit`.
    public func quitEvent() {
        appleEvents.post(.quit)
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
            // `WaitNextEvent(0xffff, …, 0x3c)` (M l. 7323): any event ends it. A queued Apple event ends it too, but the
            // event it returns is the pending activate / update one — the Apple event stays for the menu pass.
            let event = input.button || input.keys != KeyState() || !appleEvents.isEmpty
            guard event || Int(now &- start) >= BootSequence.menuIdleTicks else { return false }
        case .track(var track):
            let (events, result) = track.step(button: input.button, mouse: input.mouse)
            emit(events, button: track.button, &out)
            guard let result else { wait = .track(track); return false }
            trackResult = result
        case .level:
            guard let run = levelRun else { break }
            run.appleEvents = appleEvents
            defer { appleEvents = run.appleEvents }
            do {
                emit(try run.tick(now: now, input: input), &out)
            } catch {
                levelFailed = true
                break
            }
            guard run.end != nil else { return false }
        case .map:
            guard let m = worldMap else { break }
            m.appleEvents = appleEvents
            emit(m.tick(now: now, input: input), &out)
            appleEvents = m.appleEvents
            guard m.result != nil || m.quitRequested || m.quitEventDispatched else { return false }
        case .death:
            guard var d = deathScreen else { break }
            out.append(d.tick(now: now, input: input, fade: &fade))
            deathScreen = d
            guard d.isDone else { return false }
        case .file:
            guard fileAnswer != nil else { return false }
        case .later:
            return false
        }
        wait = nil
        return true
    }

    /// Starts a blocking timeline at `now` (its tick-0 events emitted now); a gated-off call does nothing.
    func block(_ t: FrontTimeline, _ now: UInt32, _ out: inout FrontOutput) {
        guard !t.isEmpty else { return }
        var run = TimelineRun(t, start: now)
        out.append(run.tick(now: now))
        if !run.isDone(now: now) { wait = .timeline(run) }
    }

    /// Runs `items` before the rest of the queue (a nested call's body).
    func run(_ items: [Work]) {
        queue.insert(contentsOf: items, at: 0)
    }

    /// `ReportDialog(text)` (DLOG 200), modal.
    func report(_ text: String, _ out: inout FrontOutput) {
        out.requests.append(.dialog(.report(text: text)))
        wait = .dialog
    }

    func draw(_ ops: [DrawOp], _ out: inout FrontOutput) {
        guard !ops.isEmpty else { return }
        out.draws += ops
        out.present = true
    }

    func gammaFadeOut(_ now: UInt32, _ out: inout FrontOutput, _ n: Int = 6) {
        block(fade.gammaFadeOut(n, rgb: RGB16(0, 0, 0)), now, &out)   // `_DAT_100a53d0…`: the async colour only
    }

    func gammaFadeIn(_ now: UInt32, _ out: inout FrontOutput, _ n: Int = 6) {
        block(fade.gammaFadeIn(n), now, &out)
    }

    /// `.HideTheMenuBar` (`MT_HideMenubar` + `MTRedraw` when shown).
    func hideMenuBar(_ out: inout FrontOutput) {
        guard !menuBarHidden else { return }
        menuBarHidden = true
        out.requests.append(.hideMenuBar)
        out.present = true
    }

    /// `.ShowTheMenuBar`.
    func showMenuBar(_ out: inout FrontOutput) {
        guard menuBarHidden else { return }
        menuBarHidden = false
        out.requests.append(.showMenuBar)
    }

    /// `.DrawMainMenu`: `KillAllSprites` (no sprites alive outside a level), clut 130, PICT 130.
    func drawMainMenu(_ out: inout FrontOutput) {
        draw([.setScreenClut(id: MainMenu.clut), .drawPicture(id: MainMenu.picture, chain: .frontEnd, h: 0, v: 0)], &out)
    }

    /// `.UpdateMenus` (M l. 28763ff): the menus live in the menu loop, the Music / Sound Effects check marks.
    func updateMenus(_ out: inout FrontOutput) {
        menuBarListening = true
        out.requests.append(menuState(live: true))
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
                // `.DrawMainMenu`, `.UpdateMenus`, `MTRedraw`, `GammaFadeIn(6)`.
                f.drawMainMenu(&out)
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
        items.append { f, _, _, out in
            // `.CheckEvent` takes one event: a menu pick (A1b — the OS queue's events come before the high-level ones),
            // else `AEProcessAppleEvent` (A1a): the quit, or the Finder's open (`5106` set: no game loop runs at the
            // menu).
            if let item = f.pendingMenu {
                f.pendingMenu = nil
                f.menuSelection(item, &out)
                return
            }
            switch f.appleEvents.takeFirst() {
            case .quit?: f.quit()
            case .open(let ref)?: f.continueGame(ref, &out)
            case nil: break
            }
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

    // `.NewGame` (`newGame(_:)`) and `.ContinueGame` (`continueGame(_:_:)`): NewGame.swift, ContinueGame.swift (F1b).

    /// `.Options @ 1000e470` (M l. 7254–7288).
    private func options() {
        run([
            { f, _, _, out in
                // `FlushEvents`, `InputActivate(0,0)` (no InputSprocket), `ShowCursorSafe`, the prefs file re-read.
                f.flushEvents()
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
                // `FlushEvents(0xff7f, 0)`, then `.DoAboutDialog(600, 4803)`: it closes on `Button()` down inside
                // (`FlushEvents(mDownMask)` takes only the mouse-down) and `.Credits` returns at once — nothing waits
                // for the button to come up; the polled button reads down until it does, as the original's.
                f.flushEvents()
                let size = ChapterScreenRun.frameSize(
                    f.resources.resource(type: "PICT", id: CreditsScroll.stripPicture, chain: .frontEnd)?.data)
                    ?? (144, 811)
                f.menuCredits = CreditsScroll(start: now, stripWidth: size.width, stripHeight: size.height)
                f.state = .credits
                out.requests.append(.dialog(.credits))
                f.wait = .dialog
            },
            { f, _, _, _ in
                f.menuCredits = nil
                f.state = .mainMenu
            },
        ])
    }

    /// `.Quit @ 1000e9d4` (M l. 7447–7482). The prefs are not written; `STSetVolume` of the startup volume is not
    /// reproduced (Known deviation 8).
    func quit() {
        quitting = true
        run([
            { f, now, _, out in
                // `InitCursor`, `ShowCursorSafe`, `SetWatchCursor`, `FlushEvents`, `FadeAIFFMusic(0,1)`.
                f.flushEvents()
                out.requests.append(.showCursor)
                // No menu event is processed again (main menu or pause loop): the App's menus dead, unconditionally —
                // a pause loop's own live state never went through `menuBarListening` (A1b).
                f.menuBarListening = false
                out.requests.append(f.menuState(live: false))
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

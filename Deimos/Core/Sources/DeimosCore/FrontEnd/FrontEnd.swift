import Foundation

// MARK: - Stores (handed in by the host; Phase 4 plan S1b ruling 7)

/// Where the settings live (the original's prefs file, `U_Prefs.cc`; grounding C §1). Core never touches a disk: the
/// host builds the store (S4's `PrefsStore`, given a folder) and the driver hands the live prefs to it at shutdown.
public protocol SettingsStore: Sendable {
    /// The settings at launch (a missing or unreadable file is the store's to turn into the fresh record).
    func load() throws -> DeimosPrefs
    /// Write the settings (at quit only, as the original: `FUN_10000630 → FUN_100045f0`).
    func save(_ prefs: DeimosPrefs) throws
}

/// Where Last Film lives (`FUN_100095b0(film, 'last')`, grounding B §4b). The driver saves a pass's
/// `ShellRequest.saveLastFilm` bytes through it; S5 builds the real one.
public protocol LastFilmStore: Sendable {
    func save(_ film: [UInt8]) throws
    func load() throws -> [UInt8]?
}

/// The do-nothing settings store: the fresh record in, nothing out (the default until S4 / S8a).
public struct NoSettingsStore: SettingsStore {
    public init() {}
    public func load() throws -> DeimosPrefs { .fresh }
    public func save(_ prefs: DeimosPrefs) throws {}
}

/// The do-nothing Last Film store (the default until S5 / S8a).
public struct NoLastFilmStore: LastFilmStore {
    public init() {}
    public func save(_ film: [UInt8]) throws {}
    public func load() throws -> [UInt8]? { nil }
}

// MARK: - Shared state

/// The modifier keys held at launch, read once by the boot (`1000015c` Option 0x3A, `1000016c` Command 0x37;
/// grounding A §1 step 2): Command = the quiet launch, Option = the configuration window first.
public struct LaunchModifiers: Equatable, Sendable {
    public var command: Bool
    public var option: Bool

    public init(command: Bool = false, option: Bool = false) {
        self.command = command
        self.option = option
    }
}

/// One resource of the app's own resource fork (`Deimos Rising.rsrc`: DITL 190 / 191, STR# 130, DLOG, `tab#` …),
/// by type and id — the key of `FrontEndState.shellResources`.
public struct ShellResourceKey: Hashable, Sendable {
    public var type: FourCC
    public var id: Int16

    public init(_ type: FourCC, _ id: Int16) {
        self.type = type
        self.id = id
    }
}

/// The value a screen returns when it returns nothing (boot, the main menu, the films).
public struct ScreenDone: Equatable, Sendable {
    public init() {}
}

/// Everything the screens share, owned by the front end for the app's life (grounding B §6, plan S1b ruling 3).
/// Every later screen reads and writes it; nothing here belongs to one screen. The original keeps these as globals
/// (`r2`-relative bytes) and in the prefs record.
public struct FrontEndState: Sendable {
    public let assets: DeimosAssets
    /// The text layout every screen draws with (`ElementList`'s functions take it).
    public let text: TextLayout
    /// The live prefs (`_DAT_100def40`: the settings, the score table and its names, the player names). A game gets
    /// a copy when it starts and hands its own back on the pass that ends it (`GameRun`).
    public var prefs: DeimosPrefs
    /// G+0x24: the demo cycle counter (grounding B §3) — which demo DEMOS / `D` plays next; it lasts the app's life.
    public var demoCounter = 0
    /// b6: the menu restarts or resumes its music on its next pass (A §2.2, B §1b step 12).
    public var menuMusic = false
    /// b8 (`DAT_100e01b8`, r2−0x6178): quit chosen (Q, File ▸ Quit, a Quit request). Set by the front end itself
    /// when `ShellEvent.quitChosen` / `.quitRequested` reaches a pass (and by the pause's quit, `FrontEnd
    /// .quitDuringPause`); never cleared by the frame (the menu clears it after its QUIT flash, `10022ad4`).
    public var quit = false
    /// b9: leave the main menu (A §2.3).
    public var leave = false
    /// The menu's copyright-flip clock t0 (A §2.2: flips strictly after flli 68 = 240 ticks). It outlives a demo
    /// (B §3, the flip glitch), so it is here, not in the menu.
    public var copyrightClock: UInt32 = 0
    /// The sound system started (`FUN_10047160`'s "Sound not available" path is false).
    public var soundAvailable: Bool
    /// b7: the app is suspended. Set by the front end itself from `ShellEvent.suspend` / `.resume` as they reach a
    /// pass; the screens do their own suspend and resume work on the same events.
    public var suspended = false
    /// The modifiers held at launch.
    public let launch: LaunchModifiers
    /// The app's own resource-fork data, handed in by the shell at launch and read-only here: raw bytes by resource
    /// type and id (the configuration and controls windows' DITL 190 / 191, STR# 130 and the like — `DeimosAssets`
    /// holds only the data files). Empty by default; a screen that needs a resource reads it from here and parses
    /// it itself.
    public let shellResources: [ShellResourceKey: [UInt8]]
    /// This is the first launch: no settings file existed when the app started (Ben 2026-11-20; the host reads it from
    /// its settings store, `PrefsStore.fileExisted`). It stands in for the original's missing units cache
    /// (`FUN_1003cf10` → `FUN_100420f0`): only a first launch lists the unit names on the loading screen (`Boot`).
    public let firstLaunch: Bool
    /// The last recorded film's bytes (the Last Film image, B §4a), empty until a game records one (S5). Written by
    /// the front end on the pass that ends a non-film game with a recording (plan ruling 7: saved at the end of every
    /// non-film game — that pass also carries `ShellRequest.saveLastFilm` — and replayed from here within one run).
    public var lastFilm: [UInt8] = []
    /// The main menu's element list — the original's one global list (G_Interface, `FUN_10000ce0` / `FUN_100009e0`),
    /// shared by the screens that draw it. The menu (S2) fills it as it builds its screen; start/return (S3a) fades it
    /// out as a game starts and fades it in / redraws it on the way back. Empty until the menu builds it.
    public var menuElements = ElementList()
    /// The menu's lit button: an index into `menuElements.elements`, nil when none is lit. The menu (S2) sets it;
    /// start/return (S3a) reads it to redraw the list as the menu left it.
    public var menuLit: Int?
    /// A music stream exists (`FUN_100481e0`: playing or paused) — the menu's b6 rule (resume it, or `inmu` from the
    /// start). Kept by the front end from the music cues of every pass in order: a play makes one, a stop or a
    /// stop-with-fade ends it; pause, resume and the level leave it.
    public var musicAlive = false
    /// The twelve levels' masks and definitions, loaded by the first game and reused by every later one (a new game
    /// decodes nothing).
    public internal(set) var levels: LevelSet?
    /// The current game, or the last one once it has ended (its session stays readable until the next game
    /// replaces it). Run through `startGame` / `gamePass`.
    public internal(set) var game: GameRun?
    /// Games started (each first pass of a game) — the host resets its limiter stamp when it moves (the new frame
    /// controller, `FUN_10030190`, zeroes +0x1c).
    public internal(set) var gamesStarted = 0
    /// Tests (`@testable`): stands in for the recorder (S5) — when set, every game that ends is taken to have
    /// recorded these bytes (`SessionResult.recordedFilm`, empty until then).
    var recordedFilmForTests: [UInt8]?

    /// "THIS COPY IS REGISTERED TO …" (pgsl 35, A §2.2): one constant until Ben names it (question 2).
    public static let registeredName = "AMBROSIA CLASSICS"
    public var registeredName: String { Self.registeredName }

    public init(assets: DeimosAssets, prefs: DeimosPrefs, launch: LaunchModifiers = LaunchModifiers(),
                soundAvailable: Bool = true, shellResources: [ShellResourceKey: [UInt8]] = [:],
                firstLaunch: Bool = true) throws {
        self.assets = assets
        text = try TextLayout(assets: assets)
        self.prefs = prefs
        self.launch = launch
        self.soundAvailable = soundAvailable
        self.shellResources = shellResources
        self.firstLaunch = firstLaunch
    }

    /// A game is in progress (started and not yet ended).
    public var gameRunning: Bool { game?.session.running ?? false }

    /// Build a game (`FUN_100051a0`'s set-up) from the live prefs and the shared level set, with `srand(TickCount())`
    /// and the frame controller's FPS clock = `ticks` (`100057c8`, `FUN_100305e0`). It replaces the last game. Its
    /// first pass is `gamePass`'s.
    public mutating func startGame(_ start: SessionStart, ticks: UInt32) throws {
        let session = try DeimosSession(assets: assets, prefs: prefs, start: start, seed: ticks, ticks: ticks,
                                        levels: levels)
        levels = session.game.levels
        game = GameRun(session: session, provisional: false)
    }

    /// The direct start's game, built before any clock exists (seed 0) only to validate the start: its first pass
    /// rebuilds it with that pass's TickCount (as the driver's first `idle` used to).
    mutating func startProvisionalGame(_ start: SessionStart) throws {
        let session = try DeimosSession(assets: assets, prefs: prefs, start: start, seed: 0, levels: levels)
        levels = session.game.levels
        game = GameRun(session: session, provisional: true)
    }

    /// One pass of the current game (`DeimosSession.pass`). Its first pass: the provisional game rebuilt with
    /// `ticks` (if it cannot be, the provisional one plays), `gamesStarted` + 1, and the session start's FlushEvents
    /// (`FUN_10030210`): the OS queue — typed, key events, mouse-downs — never reaches the game; the shell's events
    /// do (the front end has already read them). The pass that ends the game hands its prefs back to the live prefs,
    /// and — a game that is not a film, ended with a recording (`SessionResult.recordedFilm`) — keeps that recording
    /// as the Last Film (`lastFilm`) and carries `ShellRequest.saveLastFilm` with it (plan ruling 7; B §4b). A film,
    /// or an empty recording, changes nothing.
    public mutating func gamePass(keys: HeldKeys, ticks: UInt32) -> PassOutput {
        guard var run = game else { preconditionFailure("FrontEndState.gamePass: no game was started") }
        game = nil                                                    // one owner while the pass mutates it
        var keys = keys
        if !run.begun {
            run.begun = true
            if run.provisional, let made = try? DeimosSession(assets: assets, prefs: prefs, start: run.session.start,
                                                              seed: ticks, ticks: ticks,
                                                              levels: run.session.game.levels) {
                run.session = made
            }
            run.provisional = false
            gamesStarted += 1
            keys.typed = []                                           // FUN_10030210 FlushEvents
            keys.keyEvents = []
            keys.mouseDowns = []
        }
        run.lastKeys = keys
        var out = run.session.pass(keys: keys, ticks: ticks)
        if out.sessionEnded && !run.prefsReturned {
            run.prefsReturned = true
            prefs = run.session.prefs                                 // the game's prefs, live again
            if var result = run.session.result {
                if let stand = recordedFilmForTests { result.recordedFilm = stand }
                if !result.isFilm && !result.recordedFilm.isEmpty {   // the Last Film, at every non-film game's end
                    lastFilm = result.recordedFilm
                    out.requests.append(.saveLastFilm(result.recordedFilm))
                }
            }
        }
        game = run
        return out
    }
}

/// One game: the session and the front end's bookkeeping around it (`FrontEndState.startGame` / `gamePass`).
public struct GameRun: Sendable {
    public internal(set) var session: DeimosSession
    /// Built before any clock (the direct start's validation): the first pass rebuilds it.
    var provisional: Bool
    /// The first pass has run.
    var begun = false
    /// The ending pass has handed the prefs back.
    var prefsReturned = false
    /// The keys the session's last pass was handed, after the front end's flush (inspection, tests).
    var lastKeys = HeldKeys()

    init(session: DeimosSession, provisional: Bool) {
        self.session = session
        self.provisional = provisional
    }
}

// MARK: - Screens

/// A screen on the front end's call stack — one case per screen, each its own value type in its own file under
/// `FrontEnd/` (plan S1b ruling 2). The original's screens are nested calls (menu → start/return → level select /
/// the game / scores / name entry → back); here each is a resumable value whose `pass` runs one pass of it.
///
/// A screen's frozen entry signature (ruling 3) is its initialiser, its `Result` (what it returns to its caller) and
/// `pass(keys:ticks:returned:state:) -> ScreenStep<Result>`. Later sections fill in the body and add stored state to
/// their own struct only. A screen may own large buffers (the level select's bare `GameState`): the front end moves
/// it off the stack and out of its enum case for its pass and puts it back after, so it is never copied.
///
/// **Input in a chained pass.** A pass's queued input — typed characters, key events, mouse-downs AND the shell's
/// events (`HeldKeys.events`: Quit, suspend / resume, answers, About) — reaches only the FIRST step of that pass. A
/// screen reached in the same pass by a call or a return (a chained step) sees the held state (`held`, `capsLock`,
/// `mouse`, `mouseButton`) with empty queues. The front end itself reads the shell's events before any step (the
/// quit flag, `suspended`), so those two are in `FrontEndState` for every step; any other queued input of that pass
/// went to its first step and never reaches the chained one.
public enum FrontEndScreen: Sendable {
    case boot(Boot)
    case mainMenu(MainMenu)
    case startReturn(StartReturn)
    case levelSelect(LevelSelect)
    case scores(Scores)
    case nameEntry(NameEntry)
    case credits(Credits)
    case films(Films)
    case configDialog(ConfigDialog)
    case controlsDialog(ControlsDialog)

    /// Which screen (inspection).
    public enum Kind: Equatable, Sendable {
        case boot, mainMenu, startReturn, levelSelect, scores, nameEntry, credits, films, configDialog, controlsDialog
    }

    public var kind: Kind {
        switch self {
        case .boot: return .boot
        case .mainMenu: return .mainMenu
        case .startReturn: return .startReturn
        case .levelSelect: return .levelSelect
        case .scores: return .scores
        case .nameEntry: return .nameEntry
        case .credits: return .credits
        case .films: return .films
        case .configDialog: return .configDialog
        case .controlsDialog: return .controlsDialog
        }
    }

    /// What a callee handed back, as its caller receives it.
    typealias Next = ScreenStep<ScreenResult>.Next

    /// One pass of this screen, its result wrapped for the stack. The screen is moved out of `self` (`consume`) for
    /// its pass and put back after it, so it has one owner while it runs — its buffers are never copied.
    mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?,
                       state: inout FrontEndState) -> (PassOutput, Next) {
        switch consume self {
        case var .boot(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .boot(s)
            return Self.lift(step, ScreenResult.boot)
        case var .mainMenu(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .mainMenu(s)
            return Self.lift(step, ScreenResult.mainMenu)
        case var .startReturn(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .startReturn(s)
            return Self.lift(step, ScreenResult.startReturn)
        case var .levelSelect(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .levelSelect(s)
            return Self.lift(step, ScreenResult.levelSelect)
        case var .scores(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .scores(s)
            return Self.lift(step, ScreenResult.scores)
        case var .nameEntry(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .nameEntry(s)
            return Self.lift(step, ScreenResult.nameEntry)
        case var .credits(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .credits(s)
            return Self.lift(step, ScreenResult.credits)
        case var .films(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .films(s)
            return Self.lift(step, ScreenResult.films)
        case var .configDialog(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .configDialog(s)
            return Self.lift(step, ScreenResult.configDialog)
        case var .controlsDialog(s):
            let step = s.pass(keys: keys, ticks: ticks, returned: returned, state: &state)
            self = .controlsDialog(s)
            return Self.lift(step, ScreenResult.controlsDialog)
        }
    }

    private static func lift<R>(_ step: ScreenStep<R>, _ wrap: (R) -> ScreenResult) -> (PassOutput, Next) {
        switch step.next {
        case .stay: return (step.output, .stay)
        case let .call(callee): return (step.output, .call(callee))
        case let .finish(value): return (step.output, .finish(wrap(value)))
        }
    }
}

/// What a screen returned, as its caller receives it in `returned` on its next pass — one case per screen, carrying
/// that screen's `Result`.
public enum ScreenResult: Equatable, Sendable {
    case boot(Boot.Result)
    case mainMenu(MainMenu.Result)
    case startReturn(StartReturn.Result)
    case levelSelect(LevelSelect.Result)
    case scores(Scores.Result)
    case nameEntry(NameEntry.Result)
    case credits(Credits.Result)
    case films(Films.Result)
    case configDialog(ConfigDialog.Result)
    case controlsDialog(ControlsDialog.Result)
}

/// One pass of a screen: what it drew and played this pass, and what happens next — stay (its next pass runs it
/// again), call another screen (which runs from the next step; this one resumes when that one returns, handed its
/// result), or finish with its result (`Value`: the screen's `Result`).
public struct ScreenStep<Value> {
    public enum Next {
        case stay
        case call(FrontEndScreen)
        case finish(Value)
    }

    public var output: PassOutput
    public var next: Next

    public init(_ output: PassOutput = PassOutput(), next: Next = .stay) {
        self.output = output
        self.next = next
    }

    public static func stay(_ output: PassOutput = PassOutput()) -> ScreenStep {
        ScreenStep(output, next: .stay)
    }

    public static func call(_ callee: FrontEndScreen, _ output: PassOutput = PassOutput()) -> ScreenStep {
        ScreenStep(output, next: .call(callee))
    }

    public static func finish(_ result: Value, _ output: PassOutput = PassOutput()) -> ScreenStep {
        ScreenStep(output, next: .finish(result))
    }

    /// The result, when this step finishes (inspection).
    public var finished: Value? {
        if case let .finish(r) = next { return r }
        return nil
    }

    /// The screen this step calls (inspection).
    public var callee: FrontEndScreen.Kind? {
        if case let .call(s) = next { return s.kind }
        return nil
    }
}

// MARK: - The front end

/// The front end (Phase 4, plan S1b; grounding B §6 option A, D Part 3 option a): the driver's ONLY client. It owns
/// the screens — a call stack, as the original's screens are nested calls — the games they start and the state they
/// share, and it has the session's shape: `pass(keys:ticks:)` → `PassOutput`, plus what the host calls between
/// passes (`transitionFadeEnded`, `quitDuringPause`).
///
/// - **Entries.** The boot entry (`FUN_100000a0`): boot, then the main menu; when the menu returns, the shutdown —
///   `ShellRequest.quit`. The direct start (ruling 10): no boot, no menu — start/return's game at a given start, a
///   new one at the same start when it ends (seed = the TickCount of the pass that starts it), and after a game that
///   ends with the quit flag set, `ShellRequest.quit` and no new game. The app runs the direct start until the menu
///   lands (S2), and the tests keep it for good (G12). Today the app's `-film` runs on the direct start too (the film
///   as the start, a new run of it each time it ends); S8a changes that (ruling 10): `-film` then takes the boot
///   entry, plays the film after the boot and returns to the menu, as a demo does.
/// - **One pass.** Shell events are read first: Quit chosen or requested sets the quit flag (it does not end a game
///   in play), suspend / resume set `suspended`. Then the top screen runs. A step that calls or returns runs on into
///   the next screen in the same pass as long as it drew nothing (no ops) and did not end a game, merging the
///   outputs in order, up to `maxChainedSteps` (a screen loop traps, G11). The queued input (typed characters, key
///   events, mouse-downs, shell events) goes to the pass's first step only — a chained step sees the held state.
///   One pass holds at most one halt and one transition fade (`merge` traps on a second of either), so a chained
///   pass may carry only one: a screen's return sequence with two (a fade out, then a fade in) must split them across
///   passes. The "did not end a game" clause cannot act today — a game's ending pass always draws, so the ops
///   stop the chain first — and is there for a game pass that some day ends without drawing.
/// - **Music.** `state.musicAlive` follows the pass's music cues in order.
public struct FrontEnd: Sendable {
    /// The most screen steps one pass may chain without drawing (G11): a front end that exceeds it is looping.
    public static let maxChainedSteps = 32

    public var state: FrontEndState
    /// The direct start's game (nil for the boot entry).
    public let directStart: SessionStart?

    private enum Root: Sendable {
        case direct
        case boot
        case menu
        case finished
    }
    private var root: Root
    private var stack: [FrontEndScreen]
    /// A finished screen's result, for its caller's next step.
    private var pending: ScreenResult?
    /// The film the menu plays first (`-film`, ruling 10).
    private let menuFilm: Film?

    /// The boot entry: boot (`FUN_100000e0`), then the main menu, with `film` played as soon as the menu is up, as a
    /// demo is (ruling 10's `-film`). `shellResources`: the app's own resource-fork data; `firstLaunch`: no settings
    /// file existed at launch (`FrontEndState`).
    public init(assets: DeimosAssets, prefs: DeimosPrefs, launch: LaunchModifiers = LaunchModifiers(),
                soundAvailable: Bool = true, film: Film? = nil,
                shellResources: [ShellResourceKey: [UInt8]] = [:], firstLaunch: Bool = true) throws {
        state = try FrontEndState(assets: assets, prefs: prefs, launch: launch, soundAvailable: soundAvailable,
                                  shellResources: shellResources, firstLaunch: firstLaunch)
        directStart = nil
        root = .boot
        stack = [.boot(Boot())]
        menuFilm = film
    }

    /// The direct start (ruling 10): `start`'s game — validated here, built at the first pass with its TickCount —
    /// and a new one at `start` each time one ends.
    public init(direct start: SessionStart, assets: DeimosAssets, prefs: DeimosPrefs,
                soundAvailable: Bool = true, shellResources: [ShellResourceKey: [UInt8]] = [:],
                firstLaunch: Bool = true) throws {
        state = try FrontEndState(assets: assets, prefs: prefs, soundAvailable: soundAvailable,
                                  shellResources: shellResources, firstLaunch: firstLaunch)
        try state.startProvisionalGame(start)
        directStart = start
        root = .direct
        stack = [.startReturn(StartReturn(direct: start))]
        menuFilm = nil
    }

    /// The screens on the stack, bottom first (inspection).
    public var screens: [FrontEndScreen.Kind] { stack.map(\.kind) }

    /// The shell has been asked to quit; every later pass is empty.
    public var isFinished: Bool { root == .finished }

    /// The current game's session (or the last game's, once it has ended, until the next replaces it); nil before
    /// the first game. Set: tests poke the running game (standing rule 7).
    public var session: DeimosSession? {
        get { state.game?.session }
        set {
            guard let newValue else { return }
            precondition(state.game != nil, "FrontEnd.session: no game to set")
            state.game?.session = newValue
        }
    }

    /// The prefs the shutdown saves: the running game's while one runs (its F6, volume … since it started), else
    /// the live prefs.
    public var livePrefs: DeimosPrefs {
        if let game = state.game, game.begun, game.session.running { return game.session.prefs }
        return state.prefs
    }

    /// A transition's fade to black has presented its last step (the game's `transitionFadeEnded`).
    public mutating func transitionFadeEnded(ticks: UInt32) {
        state.game?.session.transitionFadeEnded(ticks: ticks)
    }

    /// The pause screen's wait let go on the quit flag (grounding B §5 `10022f8c`, `10022fa8`; X `10023374`, the
    /// paused-frame hook `10030cb8`): the flag is set (a Quit request the host found queued during the wait sets it
    /// here, as X's pump inside the pause does) and the game's frame controller is told, so its next pass ends it.
    public mutating func quitDuringPause() {
        state.quit = true
        state.game?.session.quitDuringPause()
    }

    /// One pass of the front end (see the type's comment).
    public mutating func pass(keys: HeldKeys, ticks: UInt32) -> PassOutput {
        for event in keys.events {
            switch event {
            case .quitChosen, .quitRequested: state.quit = true
            case .suspend: state.suspended = true
            case .resume: state.suspended = false
            case .aboutChosen, .answer: break
            }
        }
        var out = PassOutput()
        var stepKeys = keys
        for _ in 0..<Self.maxChainedSteps {
            var output = PassOutput()
            var stop = true
            if stack.isEmpty {
                (output, stop) = rootStep()
            } else {
                let returned = pending
                pending = nil
                var top = stack.removeLast()
                let (o, next) = top.pass(keys: stepKeys, ticks: ticks, returned: returned, state: &state)
                output = o
                switch next {
                case .stay:
                    stack.append(top)
                    stop = true
                case let .call(callee):
                    stack.append(top)
                    stack.append(callee)
                    stop = false
                case let .finish(result):
                    pending = result
                    stop = false
                }
            }
            Self.merge(output, into: &out)
            stepKeys = HeldKeys(held: keys.held, capsLock: keys.capsLock, mouse: keys.mouse,
                                mouseButton: keys.mouseButton)            // the queue is read once per pass
            if !output.ops.isEmpty || output.sessionEnded { stop = true }   // (a game end always draws today)
            if stop {
                trackMusic(out.music)
                return out
            }
        }
        preconditionFailure("FrontEnd.pass: \(Self.maxChainedSteps) screen steps chained without drawing — a loop")
    }

    /// The bottom of the stack (`FUN_100000a0` for the boot entry; the direct start's loop).
    private mutating func rootStep() -> (PassOutput, stop: Bool) {
        pending = nil
        switch root {
        case .direct:
            if state.quit {
                root = .finished
                return (PassOutput(requests: [.quit]), true)
            }
            guard let directStart else { preconditionFailure("FrontEnd: a direct root with no start") }
            stack.append(.startReturn(StartReturn(direct: directStart)))
            return (PassOutput(), false)
        case .boot:
            root = .menu
            stack.append(.mainMenu(MainMenu(film: menuFilm)))
            return (PassOutput(), false)
        case .menu:
            root = .finished                                          // FUN_10000630: the shutdown
            return (PassOutput(requests: [.quit]), true)
        case .finished:
            return (PassOutput(), true)
        }
    }

    /// `b` after `a`, in order: ops, cues and requests appended; the halt and the fade mark re-indexed past `a`'s
    /// cues (one pass holds at most one of each).
    static func merge(_ b: PassOutput, into a: inout PassOutput) {
        if let h = b.haltEffectsAt {
            precondition(a.haltEffectsAt == nil, "FrontEnd: two halts in one pass")
            a.haltEffectsAt = a.sounds.count + h
        }
        if let m = b.fadeToBlackAt {
            precondition(a.fadeToBlackAt == nil, "FrontEnd: two transition fades in one pass")
            a.fadeToBlackAt = CueMark(sounds: a.sounds.count + m.sounds, music: a.music.count + m.music)
        }
        a.ops += b.ops
        a.sounds += b.sounds
        a.music += b.music
        a.requests += b.requests
        a.ticked = a.ticked || b.ticked
        a.sessionEnded = a.sessionEnded || b.sessionEnded
        a.result = b.result ?? a.result
    }

    private mutating func trackMusic(_ music: [MusicCue]) {
        for cue in music {
            switch cue {
            case .play: state.musicAlive = true
            case .stop, .stopWithFade: state.musicAlive = false
            case .pause, .resume, .level: break
            }
        }
    }
}

# Handoff — Deimos Rising Phase 4, section S1b: the front end's frame (closed 2026-11-20)

Seat: Claude Fable 5.2. Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section S1b of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. **S2, S4, S5 and S6 may start** (each also
needs S0, which is on main).

## What a player would notice
Nothing. The app still opens straight into a game and starts another when one ends. Underneath, the game is now run
by a new "front end" that will hold the menu and the other screens; every screen exists as an empty placeholder.

## What landed

| Commit | What |
|---|---|
| `71b1257` | SK-b: the `FrontEnd`, ten placeholder screens, the driver re-pointed at it; the driver's own restart is gone |
| `17ec58b` | fix round: Last Film kept in memory, a channel for the app's resource data, the menu's list in shared state, no per-pass copy of a screen |
| `5739b80` | fix round 2: three untested paths pinned by tests, one "suspended" flag, final public names |

## Gates, measured by the seat from the merge head

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **392 / 0 / 0** (385 + 7) |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki and BubbleTroubleX not built: no `project.yml` or kit change) |
| G8 `DeimosCampaignTests`, one test at a time | **3 / 0** (463 s, 256 s, 28 s) |
| G12 the direct start matches a bare session over 3,200 passes | passes (`DriverTests.testDirectStartMatchesBareSession`, inside G2) |
| G3 census, G6 scope, G7 layering, G10 clean tree | empty diff; inside the fence; prints nothing; clean |
| G1 | not run (no kit change) |

G8 filter that works: `swift test --filter "CampaignSweepTests/<test name>"`.
**G2 base for the next sections: 392.** The phase now ends at **478** (unchanged from S1a's handoff).

## How the frame works (read this before building a screen)

- **`FrontEnd`** (`Deimos/Core/Sources/DeimosCore/FrontEnd/FrontEnd.swift`) has the session's shape:
  `pass(keys:ticks:) -> PassOutput`. The driver holds a `FrontEnd` and nothing else.
- **Screens are a call stack**, as the original's are nested calls. The top screen gets each pass. Its pass returns
  a `ScreenStep`: its `PassOutput` plus one of **stay**, **call** another screen, or **finish** with a value. When
  a called screen finishes, its caller's next pass receives the value in `returned` (a `ScreenResult` case).
- **Chaining:** steps that end in a call or a finish run on inside the same front-end pass (bound
  `FrontEnd.maxChainedSteps` = 32; it traps). Their outputs are merged. **Only the first step of a chained pass sees
  the queued input** (typed, key events, mouse-downs, shell events); held state reaches every step. **Two halts or
  two fades in one merged pass trap**, so a return sequence with two fades must be split across passes (end a pass
  with `.stay`).
- **Cue timing** is S1a's: the driver sends all of a pass's cues when the pass begins. A cue that must follow a wait
  or a fade goes in a later pass.
- **Shared state** is `FrontEndState`, handed to every screen pass as `state: inout`. A screen keeps its private
  state as stored properties of its own struct (add what you need; the struct is yours).
- **The game** lives in `state.game`, not inside a screen. A screen starts one with
  `state.startGame(_:ticks:)` and runs it with `state.gamePass(keys:ticks:)`. The frame, not the screen, does what
  the old restart did: carries the prefs back, reuses the level list, flushes input at a game start, hides the
  cursor on the game's first pass, and at the end of a non-film game with a recording stores it in `state.lastFilm`
  and emits `ShellRequest.saveLastFilm`.
- **Quit:** a `quitChosen` / `quitRequested` event sets `state.quit`; it does not end a game in play. Inside the
  Caps Lock wait the driver lets the wait go without the music resume (resuming the app first if it is suspended,
  as the OS X build does), sets the session's controller "+2", and the game ends on its next pass. When the root
  screen finishes with `state.quit` set, the front end emits `ShellRequest.quit` and is finished.

## The frozen entry signatures

Every screen: `public mutating func pass(keys: HeldKeys, ticks: UInt32, returned: ScreenResult?, state: inout FrontEndState) -> ScreenStep<Result>`.
A later section edits only the body of its screen's file and adds stored properties; the initialiser arguments, the
`Result` type and the pass signature do not change.

| File (`FrontEnd/`) | Entry | Returns (`Result`) | What the stub does today |
|---|---|---|---|
| `Boot.swift` | `Boot()` | `ScreenDone` | finishes at once; the front end then opens the menu |
| `MainMenu.swift` | `MainMenu(film: Film? = nil)` (`film` = the `-film` switch, for S8a) | `ScreenDone` (the front end then asks the shell to quit) | with `state.quit` set it finishes; otherwise calls `StartReturn(mode: .play, players: 1)`; when that returns it starts another |
| `StartReturn.swift` | `StartReturn(mode: .play / .lastFilm / .demo, players: Int, film: Film? = nil)`; also `StartReturn(direct: SessionStart)` (the direct start; keep) | `SessionResult?` (nil = level select cancelled) | `.play` calls `LevelSelect()`, starts a game at the sector it returns, runs it, emits `.showCursor`, finishes with the result; films skip the level select |
| `LevelSelect.swift` | `LevelSelect()` | `Int?` (the sector; nil = Esc) | finishes at once with sector 1 |
| `Scores.swift` | `Scores()` | `Scores.Exit` (`.leave` / `.newGame`) | finishes at once with `.leave` |
| `NameEntry.swift` | `NameEntry(player: Int, slot: Int, prefs: DeimosPrefs, fromGame: Bool = true)` | `DeimosPrefs` (as edited) | finishes at once with `prefs` unchanged |
| `Credits.swift` | `Credits()` | `Credits.Exit` (`.leave` / `.newGame`) | finishes at once with `.leave` |
| `Films.swift` | `Films(kind: .demo / .lastFilm)` | `ScreenDone` | finishes at once |
| `ConfigDialog.swift` | `ConfigDialog(firstLaunch: Bool)` | `Bool` (saved) | finishes at once with `false` |
| `ControlsDialog.swift` | `ControlsDialog()` | `Bool` (saved) | finishes at once with `false` |

To call a screen: `.call(.scores(Scores()))`; to read what it returned: `if case let .scores(exit)? = returned`.
Level select returns only the sector, so "music already playing" (`SessionStart.musicAlreadyPlaying`) is set by
start/return, not by level select.

### `FrontEnd.swift` — the other frozen declarations
```swift
public protocol SettingsStore: Sendable { func load() throws -> DeimosPrefs; func save(_ prefs: DeimosPrefs) throws }
public protocol LastFilmStore: Sendable { func save(_ film: [UInt8]) throws; func load() throws -> [UInt8]? }
public struct NoSettingsStore: SettingsStore      // load = .fresh, save = nothing
public struct NoLastFilmStore: LastFilmStore      // save = nothing, load = nil
public struct LaunchModifiers { var command: Bool; var option: Bool; init(command: Bool = false, option: Bool = false) }
public struct ShellResourceKey: Hashable { var type: FourCC; var id: Int16; init(_ type: FourCC, _ id: Int16) }
public struct ScreenDone { init() }

public struct FrontEndState
    public let assets: DeimosAssets
    public let text: TextLayout
    public var prefs: DeimosPrefs                 // live prefs: score table, names, keys, byte and int prefs
    public var demoCounter = 0                    // G+0x24: which demo is next
    public var menuMusic = false                  // the menu-music flag
    public var quit = false                       // b8
    public var leave = false                      // b9
    public var copyrightClock: UInt32 = 0         // outlives a demo
    public var soundAvailable: Bool
    public var suspended = false                  // kept in step with the driver's
    public let launch: LaunchModifiers
    public let shellResources: [ShellResourceKey: [UInt8]]   // the app's resource-fork data (DITL, STR#, …), from the shell
    public var lastFilm: [UInt8] = []             // the last recorded game, in memory
    public var menuElements = ElementList()       // the menu's one list: S2 fills it, S3a fades it
    public var menuLit: Int?                      // which element is lit
    public var musicAlive = false                 // tracked from the music cues that pass through
    public internal(set) var levels: LevelSet?
    public internal(set) var game: GameRun?
    public internal(set) var gamesStarted = 0
    public static let registeredName = "AMBROSIA CLASSICS"
    public var gameRunning: Bool
    public mutating func startGame(_ start: SessionStart, ticks: UInt32) throws
    public mutating func gamePass(keys: HeldKeys, ticks: UInt32) -> PassOutput

public enum FrontEndScreen     // one case per screen: .boot(Boot) … .controlsDialog(ControlsDialog); .kind
public enum ScreenResult       // one case per screen, holding that screen's Result
public struct ScreenStep<Value>
    public static func stay(_ output: PassOutput = PassOutput()) -> ScreenStep
    public static func call(_ callee: FrontEndScreen, _ output: PassOutput = PassOutput()) -> ScreenStep
    public static func finish(_ result: Value, _ output: PassOutput = PassOutput()) -> ScreenStep

public struct FrontEnd
    public static let maxChainedSteps = 32
    public var state: FrontEndState
    public let directStart: SessionStart?
    public init(assets:prefs:launch:soundAvailable:film:shellResources:) throws        // boot → menu
    public init(direct: SessionStart, assets:prefs:soundAvailable:shellResources:) throws
    public var screens: [FrontEndScreen.Kind]
    public var isFinished: Bool
    public var session: DeimosSession?
    public var livePrefs: DeimosPrefs
    public mutating func transitionFadeEnded(ticks: UInt32)
    public mutating func quitDuringPause()
    public mutating func pass(keys: HeldKeys, ticks: UInt32) -> PassOutput
```

### `DeimosHost/DeimosDriver.swift`
```swift
public init(frontEnd: FrontEnd, rate: TickRate = .classic, audio: (any DeimosAudioSink)? = nil,
            settingsStore: any SettingsStore = NoSettingsStore(), lastFilmStore: any LastFilmStore = NoLastFilmStore())
public init(assets:prefs:rate:start:audio:settingsStore:lastFilmStore:) throws   // the direct start; what the app uses today
@discardableResult public func shutdown() -> DeimosPrefs    // live prefs → the settings store, and returned
public var prefs: DeimosPrefs        // forwards to the front end
public var start: SessionStart?      // now optional (nil with the boot entry)
var session: DeimosSession           // internal forwarding accessor, for tests
```
The driver calls the Last Film store when a pass carries `saveLastFilm`. `suspend()` / `resume()` also set
`state.suspended`. Its `restarts` counter now counts game ends, including the last one before a quit.

## Departures from the plan's card (the seat's rulings; for the gate-4 card where marked)

1. **The count is 392, not 391** (S1a's extra test; already recorded).
2. **Three of the seven new tests live in `DriverTests`** (tick wait, event wait, quit in the Caps Lock wait), because
   only the driver runs waits. `FrontEndSkeletonTests` holds the other three; `testDirectStartMatchesBareSession` is G12.
3. **The app needed no code change**: the driver's old initialiser now builds the direct start. One comment changed.
4. **Added beyond the card, because the shared file closes now:** Last Film kept in memory by the frame; the
   resource-data channel; the menu's list and lit index; `musicAlive`; the `film` argument on the menu.
5. **For the gate-4 card:** `docs/deimos/osx-build.md` D9 says the OS X build leaves "About" enabled during a game,
   which contradicts plan ruling 12 (disabled during a game). S2 / S8a should follow ruling 5 (follow X) unless Ben
   says otherwise; nothing built here depends on it.

## Known and left (none blocks the next sections)

- Level select's own pause (S3b) gets no "quit during the pause" call; the driver's call reaches only a running
  game. Level select reads `state.quit` instead.
- A store's write error is swallowed by the driver (`shutdown`, Last Film save); the store reports its own errors.
- Setting `FrontEnd.session` to nil does nothing. `LastFilmStore.load()` has no caller yet (S5 / S8a).
- Two internal test-only fields sit in production types (`FrontEndState.recordedFilmForTests`, `GameRun.lastKeys`).
  S5's recorder makes the first one unnecessary but cannot remove it (the file is closed); S8a may.
- The driver passes on the requests and cues of an "ended, no ops" pass; no test reaches that path (only a game that
  cannot be built produces it).
- `testTickWaitYieldsAndResumes` and `testEventWaitQueuesAndFlushes` splice waits into a game pass, not a screen;
  the first real screen (S2) is the first true user of a wait from a screen.
- Stale comment in a closed file: `SessionResult.swift` ~line 24 still says the pause-quit byte is never set.

## For the next sections

Start from main. Build only inside your own screen file(s) and the new files your card names. If you find the frame
is missing something, STOP and tell the Coordinator (ruling 2): the seat adds it as a small commit on main first.

## Worktree

`.claude/worktrees/intelligent-volhard-809322` (branch `claude/intelligent-volhard-809322`), removed at the close; it
held this section's three commits (all merged) and nothing else. Build products were in the session scratch folder.

# Handoff — Deimos Rising Phase 4, section S1a: seams and the element list (closed 2026-11-20)

Seat: Claude Fable 5.2. Helpers: Opus 5.5 (`fk-implementer`, `fk-reviewer`), foreground. Section S1a of
`docs/superpowers/plans/2026-11-20-deimos-phase4.md` is done and on main. **S1b may start.**

## What a player would notice
Nothing. The app still opens straight into a game. This section only widened the joins between the game's parts so the
menu and the other screens can be built on them.

## What landed

| Commit | What |
|---|---|
| `0be422b` | SK-a: the seam additions (mouse, key events, shell events, waits, the session's result, the music flag) |
| `ef17c3d` | SK-a fix round: beep request, the scaled copy, the music-fade wait, "is it still playing" made mandatory |
| `1125bdc` | EL: the element list with its fades |
| `15773a0` | fix round: draw-once for the list; contract comments; a sharper scaled-copy test |
| `bd4e1eb` | the list's fades follow the OS X build (16 passes, not 32) |

## Gates, measured by the seat from the merge head

| Gate | Result |
|---|---|
| G2 `Deimos/Core` without the replay and campaign bundles | **385 / 0 / 0** |
| G4 `DeimosReplayTests`; `deimos-replay --all` | **4 / 0**; four PASS lines, exit 0 (de01 25050 at read 4809, unchanged) |
| G5 Deimos Debug and Release | both `** BUILD SUCCEEDED **` (Aki and BubbleTroubleX not built: no `project.yml` or kit change) |
| G3 census, G7 layering, G10 clean tree | empty diff; prints nothing; clean |
| G1, G8 | not run (no kit change; G8 is owed at the close of S1b, S5 and S8b) |

## Three departures from the plan's cards (the seat's rulings; each is for the gate-4 card)

1. **The ladder is one higher: 385 here, so 478 at the phase end, not 477.** The extra test is `testElementDrawOnce`.
   Three later screens (menu redraw, scores, name entry) need a plain "draw the list once" and may not edit the shared
   file, so it was added now with its own test. Every later section's G2 is still "main's count when it merges plus its
   own deltas".
2. **Element fades run 16 passes, not the card's 32** (in: levels 30, 28 … 0; out: 2, 4 … 32; the wait per pass is
   unchanged). The card carried the OS 9 figure; S0 then found the OS X build steps by two (`docs/deimos/osx-build.md`
   D1), and ruling 5 says follow X. Two review legs re-read the X listing and agree. The one-element fade and
   draw-once are the same in both builds.
3. **Seams added beyond the card's list**, because reviewers found later cards need them and the files close now:
   a system beep request (controls window), the opaque scaled copy (level select previews), a "music has stopped, at
   most N ticks" wait (the menu's quit), a virtual key code on key events (key capture), and two required questions on
   the audio sink (`isPlaying`, `isMusicFading`).

## The final seam signatures, in full (frozen; `Deimos/Core/Sources/…`)

### `DeimosCore/Seams/HeldKeys.swift`
```swift
public struct HeldKeys: Equatable, Sendable
    public var held: Set<UInt16>
    public var capsLock: Bool
    public var typed: [UInt8]
    public var mouse: MousePoint?
    public var mouseButton: Bool
    public var mouseDowns: [MousePoint]
    public var keyEvents: [KeyEvent]
    public var events: [ShellEvent]
    public init(held: Set<UInt16> = [], capsLock: Bool = false, typed: [UInt8] = [], mouse: MousePoint? = nil,
                mouseButton: Bool = false, mouseDowns: [MousePoint] = [], keyEvents: [KeyEvent] = [],
                events: [ShellEvent] = [])
public struct MousePoint: Equatable, Hashable, Sendable
    public var h: Int32
    public var v: Int32
    public init(h: Int32, v: Int32)
public struct KeyEvent: Equatable, Sendable
    public var charCode: UInt8
    public var keyCode: UInt16
    public var autoRepeat: Bool
    public init(charCode: UInt8, keyCode: UInt16, autoRepeat: Bool = false)
public enum ShellEvent: Equatable, Sendable
    case aboutChosen
    case quitChosen
    case quitRequested
    case suspend
    case resume
    case answer(QuestionButton)
```

### `DeimosCore/Seams/MusicCue.swift`
```swift
public enum MusicCue: Equatable, Sendable
    case play(FourCC, loop: Bool)
    case stop
    case pause
    case resume
    case level(Int32)
    case stopWithFade
```

### `DeimosCore/Seams/ShellRequest.swift`
```swift
public enum ShellRequest: Equatable, Sendable
    case hideCursor
    case showCursor
    case aboutEnabled(Bool)
    case quit
    case saveLastFilm([UInt8])
    case ask(ShellQuestion)
    case beep
public struct ShellQuestion: Equatable, Sendable
    public var message: String
    public var firstButton: String
    public var secondButton: String
    public init(message: String, firstButton: String, secondButton: String)
public enum QuestionButton: Equatable, Sendable
    case first
    case second
```

### `DeimosCore/Seams/RenderOp.swift`
```swift
public enum BufferID: Sendable
    case back
    case terrain
    case scoreSave
public enum PresentKind: Sendable
    case gameScreen
    case gameLayout
    case fullScreen
public enum FadeKind: Sendable
    case fromBlack
    case toBlack
public enum RenderOp: Equatable, Sendable
    case loadTerrain(image: FourCC)
    case fill(BufferID, colour: UInt16)
    case loadImage(image: FourCC, into: BufferID, dst: MacRect)
    case copy(from: BufferID, to: BufferID, src: MacRect?, dst: MacRect?, interlaced: Bool)
    case draw(DrawCommand)
    case clearLayers
    case flushLayers(ClosedRange<Int>)
    case screenBlit(src: MacRect, dst: MacRect)
    case fade(FadeKind, PresentKind)
    case limit
    case present(PresentKind)
    case particles([ParticleStamp])
    case pauseWait(PresentKind)
    case hostWait(HostWait)
    case drawPicture(id: Int16, into: BufferID, top: Int32, left: Int32)
    case scaledCopy(image: FourCC, into: BufferID, dst: MacRect, clip: MacRect)
    public static func isHostOp(_ op: RenderOp) -> Bool
        // host ops: .fade, .limit, .pauseWait, .hostWait
```

### `DeimosCore/Seams/PassOutput.swift`
```swift
public struct CueMark: Equatable, Sendable
    public var sounds: Int
    public var music: Int
    public init(sounds: Int, music: Int)
public struct PassOutput: Equatable, Sendable
    public var ops: [RenderOp]
    public var sounds: [SoundCue]
    public var music: [MusicCue]
    public var requests: [ShellRequest]
    public var ticked: Bool
    public var sessionEnded: Bool
    public var haltEffectsAt: Int?
    public var fadeToBlackAt: CueMark?
    public var result: SessionResult?
    public init(ops: [RenderOp] = [], sounds: [SoundCue] = [], music: [MusicCue] = [],
                requests: [ShellRequest] = [], ticked: Bool = false, sessionEnded: Bool = false,
                haltEffectsAt: Int? = nil, fadeToBlackAt: CueMark? = nil, result: SessionResult? = nil)
```

### `DeimosCore/FrontEnd/FrontEndWaits.swift`
```swift
public enum HostWait: Equatable, Sendable
    case ticks(UInt32)
    case voiceEnd(FourCC)
    case clickOrKey
    case answer
    case musicStopped(maxTicks: UInt32)
```

### `DeimosCore/FrontEnd/SessionResult.swift`
```swift
public struct SessionResult: Equatable, Sendable
    public enum End: Equatable, Sendable
        case gameOver
        case escape
        case finale
        case filmEnded
        case filmLoadFailed
    public var end: End
    public var isFilm: Bool
    public var startSector: Int
    public var present: [Bool]
    public var scores: [Int32]
    public var levels: [FourCC]
    public var allLevels: Bool
    public var cheated: Bool
    public var recordedFilm: [UInt8]
    public init(end: End, isFilm: Bool, startSector: Int, present: [Bool], scores: [Int32], levels: [FourCC],
                allLevels: Bool, cheated: Bool, recordedFilm: [UInt8] = [])
    public static func filmLoadFailed(startSector: Int) -> SessionResult
```

### `DeimosCore/FrontEnd/ElementList.swift`
```swift
public struct ElementList: Equatable, Sendable
    public struct Element: Equatable, Sendable
        public var record: TextRequest
        public var sprite: FourCC
        public var frame: Int
        public static func text(_ record: TextRequest) -> Element
        public static func sprite(_ face: FourCC, frame: Int, record: TextRequest) -> Element
        public var isText: Bool { sprite == .none }
    public var elements: [Element]
    public init(_ elements: [Element] = [])
    public var count: Int { elements.count }
    public mutating func append(_ element: Element)
    public static func fadeRate(floats: [Float]) -> UInt32
    public func bounds(of index: Int, text: TextLayout, assets: DeimosAssets) -> MacRect
    public func fadeIn(rate: UInt32, text: TextLayout, assets: DeimosAssets) -> [RenderOp]
    public func fadeOut(rate: UInt32, text: TextLayout, assets: DeimosAssets) -> [RenderOp]
    public static func fadeOne(_ record: TextRequest, text: TextLayout) -> [RenderOp]
    public func drawOnce(restoreText: Bool, present: Bool, text: TextLayout, assets: DeimosAssets) -> [RenderOp]
```

### Other declarations added

```swift
// DeimosCore/Game/DeimosSession.swift
public struct SessionStart   // gains:
    public var musicAlreadyPlaying: Bool
    public init(sector: Int, players: Int, film: Film?, musicAlreadyPlaying: Bool = false)
public struct DeimosSession  // gains:
    public private(set) var result: SessionResult?        // set on the ending pass; also in PassOutput.result
    public mutating func levelStart(film: Bool, musicPlaying: Bool = false)

// DeimosCore/Game/DeimosAssets.swift
    public var shellPictures: [Int16: ShellPicture] = [:]  // ruling 9: filled by the shell at start-up, keyed by PICT id
    public func interfaceStrings() throws -> StringList    // stli 'inte'
    public func credits() throws -> StringList             // 'cred'
public struct ShellPicture: Equatable, Sendable
    public let width: Int
    public let height: Int
    public let pixels: [UInt16]                            // 16-bit, row-major
    public init?(width: Int, height: Int, pixels: [UInt16])

// DeimosAudio/DeimosAudioEngine.swift — protocol DeimosAudioSink, both now REQUIRED (no default)
    func isPlaying(_ id: FourCC) -> Bool
    func isMusicFading() -> Bool

// DeimosHost/HeadlessRunner.swift — the end-reason enum gains
    case quit

// DeimosHost/DeimosDriver.swift — internal, for tests (@testable)
    var waitingOn: HostWait? { get }
    // `insertOps` (internal): hands the driver a list of ops to run as if a pass had emitted them
```

## What each seam means (the contract in words)

- **Input (`HeldKeys`)** is the one channel from the shell into Core. `mouse` is in the game's 640×480 picture, `nil`
  when outside it. `mouseDowns` are press events since the last pass; `mouseButton` is the held state. `typed` keeps
  its old meaning; `keyEvents` carries the same key presses with the virtual key code and an auto-repeat mark.
  `events` carries menu commands (About, Quit), a system Quit request, suspend, resume, and the answer to a question.
- **Waits (`RenderOp.hostWait`)** are run by the driver the way it runs a fade: it holds at the op and comes back to
  it on later `idle` calls. `.ticks(n)` counts from the tick of the `idle` call in which it is reached (the driver
  reads its clock once per call, and a screen blit does not end the call — so a wait after a pass's draws counts from
  the pass's start). `.voiceEnd(id)` releases when the sink says that sound is no longer playing. `.clickOrKey`
  releases on a mouse-down or a key event. `.answer` releases when a `ShellEvent.answer` arrives.
  `.musicStopped(maxTicks:)` releases when the music fade is over or strictly after `maxTicks` (the original's bound
  is 600, so it lets go at start + 601). Input that arrives during any wait is queued and delivered after it.
- **Cue timing:** the driver sends ALL of a pass's sound and music cues when the pass begins, before any of its ops.
  A screen that wants a cue to start after a wait or a fade puts it in a later pass. (So a stop-with-fade and its
  `.musicStopped` wait can share a pass.)
- **The flush** that clears typed characters now also clears queued mouse-downs and key events; shell events survive
  it, as Apple events survived the original's flush — a queued Quit is not lost.
- **`SessionResult`** rides on the ending pass (`PassOutput.result`) and stays readable on the session. Both player
  slots are "present" even in a one-player game, as the original. An Esc during a film reports `.escape` with
  `isFilm` true: start/return (S3a) must test `isFilm` before the kind of end. `recordedFilm` is empty until S5.
  An unexplained session end is a trap, not a quiet default.
- **`musicAlreadyPlaying`** (default false): with it true the level start leaves the music alone instead of starting
  the level track. Every existing test holds.
- **Shell requests:** the App does nothing yet with `aboutEnabled`, `quit`, `saveLastFilm`, `ask` and `beep`
  (S8a wires them). `showCursor` / `hideCursor` behave as before.
- **`drawPicture`** draws `assets.shellPictures[id]`; **`scaledCopy`** is the level select's preview copy: a whole
  im16 image stretched into `dst`, point-sampled with integer truncation, opaque, drawn only inside `clip`.
- **`ElementList`**: `fadeRate(floats:)` is the rate every caller passes (1 tick). `bounds(of:…)` is what the plan
  calls the hit rectangle; the point-in-rectangle test is the menu's own. `drawOnce(restoreText:present:…)`: menu
  redraw and scores pass (false, false); the name-entry redraw passes (true, true). A sprite always restores its
  rectangle and uses its own alpha and scale. Sprite elements use the format's Loc X / Y as their centre.

## Known and left (small; none blocks S1b)

- The engine's own `isMusicFading` and stop-with-fade have no test (only fakes are tested); the audio test bundle was
  outside this section's files.
- With no audio rendering (headless) a music fade never ends by itself; `.musicStopped` lets go at its bound.
- A suspend during `.musicStopped` ends the wait early (the original cannot be suspended there).
- In `drawOnce` the two flags are only tested as (false, false) and (true, true), the pairs the game uses.
- `LevelOneFrameTests` hands ops straight to the renderer, which traps on a host wait; nothing emits one there today.
- `fadeOne` traps on a negative blend (the original would loop about four billion times); its only caller passes 32.

## Corrections for the docs (not applied — outside this section's files)

- The plan's EL card, grounding A §5.2 and B §1a, `docs/deimos/text-metrics-lists.md` §3.1 and
  `docs/deimos/function-roles.md` still give 32 passes for the element fades; X runs 16 (a note is added under the
  plan's EL card).
- Grounding A §2.1 labels plate sizes as frame sizes: the menu logo's frame is 158×109; 163×114 is its plate.
- `ParticleStampTests.testIsHostOpMatchesRendererTraps` now also holds the picture and scaled-copy pixel checks.

## For S1b

Start from main. `FE/` already exists (`Deimos/Core/Sources/DeimosCore/FrontEnd/`) with `SessionResult.swift`,
`FrontEndWaits.swift` and `ElementList.swift`. The driver still drives a session and still has its restart block; S1b
replaces that with the front end. The App's debug audio wrapper already forwards both sink questions. G2 base for
S1b: **385**.

## Worktree

`.claude/worktrees/dazzling-bun-2a02ce` (branch `claude/dazzling-bun-2a02ce`), removed at the close; it held this
section's commits (all merged) and build products only.

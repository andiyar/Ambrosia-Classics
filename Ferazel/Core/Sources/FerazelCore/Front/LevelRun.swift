import Foundation
import HectorResources

/// How a `LevelRun` ended (plan S2, L1) — what `.GameLoop @ 10009d48` leaves for its caller (M l. 5296–5325).
public enum LevelEnd: Equatable, Sendable {
    /// G+4 < 1 after the loop (tested first, M l. 5302): `*_DAT_1009ffa8 = 1`, the music faded, `.DeathEffect`.
    case died
    /// `*_DAT_100a0088` (the exit sprite 0xcb1, M l. 49733–49741): `exit1` = `uRam100a5116` (the record's p1),
    /// `exit2` = `_DAT_100a5118` (p2, stored only when ≠ 0; −1 otherwise). Carry → M1 / F1b: `_DAT_100a5118` is a
    /// global that only `.ShowWorldMap` resets (to −1, M l. 67561), so in the original a p2 stored on one level stays
    /// until the next map; the replica's comes from the session's `PlayerState` (fresh per level).
    case completed(exit1: Int16, exit2: Int16)
    /// `DAT_100a5106` with HP ≥ 1 and the level not complete (Esc / ⌘W OK, P1): neither after-loop branch.
    case aborted
    /// ⌘Q OK (P1, `.CheckGameLoopKeys`) or the pause loop's quit event (A1a, `LevelRun.quitEventDispatched`):
    /// `.Quit` follows — the flow quits; the iteration is never finished and no exit sequence runs.
    case quit
}

/// Which renderer executes a `LevelRunOutput` segment's draws (A1a): both draw on the one shared `ScreenSurface`.
public enum LevelRunTarget: Equatable, Sendable {
    /// The level `FrameRenderer` (`apply(FrameOps(draws: …))`): the grid, lights, sprites, copy / erase, status bar,
    /// tiles, water, particles, and the level CLUT (the one its tables are built for).
    case level
    /// The level-less `ScreenRenderer` (`apply(_:)`): the front-end ops (fills, picture copies, faces, lines, text,
    /// the view restore, the timed gamma) and every other CLUT (the chapter card's 280 + n).
    case screen
}

/// A run of consecutive draws for one renderer, with the cues and requests that came with them.
public struct LevelRunSegment: Equatable, Sendable {
    public let target: LevelRunTarget
    public var output: FrontOutput

    public init(target: LevelRunTarget, output: FrontOutput) {
        self.target = target
        self.output = output
    }
}

/// One `LevelRun.tick`'s work (L1 review fix, for A1a): the segments in the order the original makes them — execute
/// each segment's draws on its target's renderer, in order; `merged` is the whole tick as one `FrontOutput` (the
/// sounds, music and requests in order, `present` / `prefs` merged).
///
/// Routing: an op only one renderer executes goes to it (`FrameRenderer.swift` silently drops the front-end ops;
/// `ScreenRenderer` refuses the level ops, `Refusal.levelOp`); `setScreenClut(id)` goes to `.level` when `id` is the level's
/// screen CLUT (the one `FrameRenderer`'s tables are built for — it refuses any other, e.g. clut 281) and to `.screen`
/// otherwise; `drawPicture` and `gammaStep` (both renderers execute them on the shared surface) stay with the
/// renderer of the draw before them (`.screen` before any). A cue- or request-only output joins the last segment; an
/// output split across renderers carries its sounds, music and requests on its first part (a `FrontOutput` does not
/// order them against its draws).
public struct LevelRunOutput: Equatable, Sendable {
    public var segments: [LevelRunSegment] = []

    public init(segments: [LevelRunSegment] = []) { self.segments = segments }

    /// Every segment's output appended in order.
    public var merged: FrontOutput {
        var o = FrontOutput()
        for g in segments { o.append(g.output) }
        return o
    }

    /// `o` split into segments by target; `owner` is the renderer of the last draw so far (carried across ticks).
    mutating func append(_ o: FrontOutput, levelClut: Int16, owner: inout LevelRunTarget) {
        var rest = o
        rest.draws = []
        var first = true
        func add(_ draws: [DrawOp], _ t: LevelRunTarget) {
            var part = first ? rest : FrontOutput(present: o.present)
            part.draws = draws
            first = false
            if let last = segments.last, last.target == t {
                segments[segments.count - 1].output.append(part)
            } else {
                segments.append(LevelRunSegment(target: t, output: part))
            }
        }
        var run: [DrawOp] = []
        for op in o.draws {
            let t = Self.target(of: op, levelClut: levelClut, owner: owner)
            if t != owner, !run.isEmpty {
                add(run, owner)
                run = []
            }
            owner = t
            run.append(op)
        }
        if !run.isEmpty {
            add(run, owner)
        } else if first, rest != FrontOutput() {
            if segments.isEmpty {
                segments.append(LevelRunSegment(target: owner, output: rest))
            } else {
                segments[segments.count - 1].output.append(rest)
            }
        }
    }

    /// The renderer `op` belongs to (the routing rule above).
    static func target(of op: DrawOp, levelClut: Int16, owner: LevelRunTarget) -> LevelRunTarget {
        switch op {
        case .setScreenClut(let id): return id == levelClut ? .level : .screen
        case .drawPicture, .gammaStep: return owner
        case .fillRect, .copyPicture, .drawFace, .drawLine, .drawText, .restoreView, .screenGamma: return .screen
        case .redrawScrollGrid, .redrawEntireScrollGrid, .drawLightsOntoTiles, .wrapDrawSprites, .copyToScreen,
             .copyMaskToScreen, .changeLightFace, .wrapEraseSprites, .statusBar, .setTile, .wrapDrawWaterEffects, .drawParticles,
             .eraseParticles, .drawBlackLines, .lightTable:
            return .level
        }
    }
}

/// One level, as `.GameLoop @ 10009d48` runs it (plan S2 `LevelRun`, L1; M l. 5093–5325 with `.SetupLevel @
/// 1000430c`, M l. 2189–2590), as a tick machine over absolute 60 Hz ticks (Invariant 3): every blocking original loop
/// (the music fades, `.PopupStageLoad`, the gamma fades, `.ChapterScreen`, `.StageCompleteEffect`, `.DeathEffect`)
/// blocks the run — no game step — for exactly its tick count; the game loop steps the hosted `FerazelSession` at
/// the binary's cadence (Invariant 4).
///
/// **Entry, in the binary's order:** `.ClearCrunchSprites` (the session init), `FadeAIFFMusic(0, 4)` +
/// `ShutDownAIFFMusic` (M l. 5161–5163 — inside `.GameLoop`, so every caller gets them); `.SetupLevel`:
/// `.PopupStageLoad` (L2), the load bars (`StageScreens.updateStageLoad`): the restart fast path (same level,
/// tilesets not disposed, M l. 2252–2271) 25 %, else `.LoadLevelTilesets` 15, 20, 25, 35, 40 % (M l. 1588–1629);
/// `G+0x20 = 0`, `G+0x22 ← hdr+0x2706`, F4 (key 0x76) held → `hasSnapshot[L] = 0` (ungated, raw `100047e0..10004810`);
/// on `hasSnapshot[L] == 1` the crunch log's re-apply (in the session init, no `FastRand`) and the snapshot restore
/// (`records:`); 50 % (M l. 2519); `.SetupLevelSprites` (the session init); a first visit's totals (M l. 2528–2536);
/// `.LoadCachedSpriteFaces`' bars (`CachedFaces`, M l. 73832–73864); `G+0x174 = 0`; 100 % (M l. 2569);
/// `GammaFadeOut(6)` (M l. 2570); the level CLUT, PICT 129, the scroll point zeroed and `.RedrawEntireScrollGrid`
/// (M l. 2571–2582). `.GameLoop`'s pre-loop: `unlocked[L] = 1` and the player spawn (the session init),
/// `GammaFadeIn(8)` only with param_4 and hdr+0x2712 ≠ 0 (M l. 5196–5197), `DAT_100a5106 = 0`, `HideCursorSafe`
/// (M l. 5203), the session's `startOps()` (M l. 5209–5216), the boss-music rule (M l. 5218–5220),
/// `SetAIFFMusic(hdr+0x284a)` + the blocking `FadeAIFFMusic(1, 4)` (M l. 5221–5222), the chapter gate (hdr+0x273c ≠ 0
/// ∧ `hasSnapshot[L] == 0` → `InputActivate(1, 1)` — InputSprocket, never active in the replica — then L2's
/// `ChapterScreenRun`, M l. 5223–5227), `GammaFadeInAsync(0x28)` on every entry (M l. 5228), then the loop.
///
/// **Exit (M l. 5296–5325):** the session's last step has stopped 452 and 511 (and 452, 453, 511 on a completion);
/// died → `*ffa8 = 1`, `FadeAIFFMusic(0, 2)`, `.DeathEffect` (50 one-tick steps: `GammaFadeOutAsync(0x30)` before,
/// one `.HandleAsyncGammaFade` per step, the bands through `LevelServices.deathEffectStep`); completed →
/// `.EndLevelSGUpdate` (SV1), `.StageCompleteEffect` unless `fd64` (L2), `fd64 = 0`, `FadeAIFFMusic(0, 2)`,
/// `GammaFadeOut(6)`; aborted → neither; all → `ShutDownAIFFMusic`, `InputActivate(0, 0)`, `ShowCursorSafe`.
///
/// **A save point (S1, Invariant 6):** the session suspends inside its special pass (`FrameSuspension.savePoint`); the
/// run does `.SavePointSave` at that moment (`SaveGame.swift`: the block, `.SaveSG` with its panel / error report
/// answered through `fileDone` / `dialogDone`, the redraw tail), then `resume` finishes the same iteration. No
/// iteration runs meanwhile; the cadence measures the next one from the suspended iteration's start.
///
/// **`.CheckGameLoopKeys` (P1, `Pause.swift`):** the session suspends after its `.PaintFrameWrap`
/// (`FrameSuspension.gameLoopKeys`); the run asks the confirm (`ShellRequest.dialog`, answered through `dialogDone`),
/// runs `.Options` (`prefsDialog`, then `dialogDone`; the new live prefs into the session) or `.Pause` (`PauseRun`,
/// ticked until it returns; its menu items through `menuChosen`), and resumes the same iteration. ⌘Q's OK ends the run
/// `.quit` at once; ⌘W / Esc OK (and the pause's Abort Game) end the loop after the iteration — `.aborted`, no fades.
///
/// **A conversation or a sign (C1):** the session suspends inside its special pass (`FrameSuspension.conversation` /
/// `.sign`, also inside a nested `.PaintFrameWrap`); the run ticks `ConversationRun` (`.Conversation` / `.SimpleConv`
/// over the live G, records and save block) until it returns, then `resume` finishes the same iteration.
public final class LevelRun {
    public let resources: FerazelResources
    /// The live prefs (`_DAT_1009fe44`): the cadence and the fades read them; P1's `.Options` and the pause's toggles
    /// replace them (the session's too).
    public private(set) var prefs: FerazelPrefs
    public let levelNumber: Int
    /// The level file (`Mlvl`), loaded at `init`.
    public let levelFile: LevelFile
    /// The session, built at `.SetupLevel` (after the popup); nil before.
    public private(set) var session: FerazelSession?
    /// The game's save block (`*_DAT_100a0054`): read by the revisit restore, written by `.EndLevelSGUpdate`.
    public private(set) var save: SaveBlock
    /// The global gamma state (`ScreenFade`): while the loop runs, the session's `AsyncGammaFade` holds the async part
    /// and is handed back at the loop's end.
    public private(set) var fade: ScreenFade
    /// The music player's state.
    public private(set) var music: MusicFade
    /// `*_DAT_1009fd64`: skip the next `.StageCompleteEffect` (cleared at every completion, M l. 5313).
    public private(set) var skipStageComplete: Bool
    /// `*_DAT_1009ffa8`: set on the death path (M l. 5303).
    public private(set) var died = false
    /// How the run ended; nil while it runs.
    public private(set) var end: LevelEnd?
    /// The `FrameOps` of the iterations the last `tick` stepped (empty when none ran); their draws, sounds and cues are
    /// also in that tick's `LevelRunOutput` (`.level` segments) — which, unlike these, also holds the level-start draws
    /// (`.SetupLevel`'s tail, the crunch re-apply's `setTile`s, `startOps()`), so A1a drives the renderers from it.
    /// S1: a suspended iteration appears as its parts — the part up to the suspension (`suspension` set) in the tick
    /// it stopped, the resumed rest in the tick the modal was answered (`.SavePointSave`'s redraw lies between them,
    /// in the output only).
    public private(set) var lastSteps: [FrameOps] = []
    /// The `.GameLoop` iterations stepped.
    public private(set) var iterations = 0

    private let services: LevelServices
    private let sounds: StageSounds
    private var carryIn: LevelCarry
    private let seed: Int32
    private let start: (x: Int, y: Int)?
    private let param3: Int16
    private let param4: Bool
    private let refreshFacing: Bool
    private let worldStamp: UInt32
    private let date: () -> UInt32
    /// The tilesets / cached faces state after `.SetupLevel` (carried on to the next level).
    private var tilesetLevel: Int16
    private var tilesetsDisposed: Bool
    private var cachedFaces: CachedFaces
    /// `hasSnapshot[L] == 1` when `.SetupLevel` tested it (after F4): a revisit (`bVar1` false).
    public private(set) var revisit = false

    private enum Stage {
        case musicOut, popup, setupLevel, setupLevelTail, gammaIn8, preLoop, chapterGate, armFade
        case exit, deathEffect, completeSave, stageComplete, completeMusic, completeFade, finish
    }

    private var stages: [Stage] = [.musicOut, .popup, .setupLevel, .setupLevelTail, .gammaIn8, .preLoop,
                                   .chapterGate, .armFade]
    private var blocking: TimelineRun?
    private var chapter: ChapterScreenRun?
    /// The loop: running, and the start tick of the iteration the next wait is measured from.
    private var playing = false
    private var lastStart: UInt32?
    /// The last iteration's bottom-of-loop wait (M l. 5285–5294) still to run out before the exit sequence.
    private var exitAt: UInt32?
    /// `.DeathEffect`'s next step and the tick it may run.
    private var deathStep = 0
    private var deathNext: UInt32 = 0
    /// The renderer of the last draw emitted (`LevelRunOutput`'s routing of the shared ops; carried across ticks).
    private var drawOwner: LevelRunTarget = .screen

    /// - Parameters:
    ///   - carry: the previous level's carry (`globals` nil → a fresh `GameGlobals(header:)`, as the session).
    ///   - save: the flow's save block.
    ///   - fade / music: the flow's gamma and music state.
    ///   - sounds: the stage screens' sounds (L2).
    ///   - start: `.GameLoop`'s (x, y); nil → hdr+0x2848 − 32, hdr+0x2846 − 32 (`.NewGame`, M l. 5823).
    ///   - param3: `.GameLoop`'s param_3 → the player's `+0x46` (always 0 from both callers).
    ///   - param4: `.GameLoop`'s param_4 (`.NewGame` 1, Continue 0): gates `GammaFadeIn(8)`.
    ///   - refreshFacing: the session's (`G+0x16 ← hdr+0x26c8` on a carried G).
    ///   - skipStageComplete: `*_DAT_1009fd64`.
    ///   - date: `GetDateTime` (seconds since 1904) for `.EndLevelSGUpdate` — Core never reads a clock.
    public init(resources: FerazelResources, prefs: FerazelPrefs, level: Int, seed: Int32, carry: LevelCarry,
                save: SaveBlock, fade: ScreenFade, music: MusicFade, services: LevelServices, sounds: StageSounds,
                start: (x: Int, y: Int)? = nil, param3: Int16 = 0, param4: Bool = true, refreshFacing: Bool = true,
                skipStageComplete: Bool = false, date: @escaping () -> UInt32 = { 0 }, files: FrontFiles? = nil,
                saveState: SaveGameState = SaveGameState()) throws {
        self.resources = resources
        self.prefs = prefs
        levelNumber = level
        levelFile = try LevelFile.load(from: resources, level: Int16(level))
        worldStamp = try WorldFile.load(from: resources).stamp
        self.save = save
        self.fade = fade
        self.music = music
        self.services = services
        self.sounds = sounds
        carryIn = carry
        self.seed = seed
        self.start = start
        self.param3 = param3
        self.param4 = param4
        self.refreshFacing = refreshFacing
        self.skipStageComplete = skipStageComplete
        self.date = date
        tilesetLevel = carry.tilesetLevel
        tilesetsDisposed = carry.tilesetsDisposed
        cachedFaces = carry.cachedFaces
        self.files = files
        self.saveState = saveState
        prefsAfterSaves = prefs
    }

    // MARK: S1 — the save point

    /// fe00 / fd54 / fd18 (`SaveGameState`), as the flow handed them in and the save points left them.
    public private(set) var saveState: SaveGameState
    /// The live prefs (`_DAT_1009fe44`) as `.SaveSG` leaves them (prefs+0x42 incremented / named / restored,
    /// `.UpdateSGString`'s `.MakeCurrPrefs`) — while the panel is up, with the incremented default name in it; the
    /// session keeps its own copy (P1 makes `FerazelSession.prefs` settable).
    public var livePrefs: FerazelPrefs { saveSG?.prefs ?? prefsAfterSaves }
    private var prefsAfterSaves: FerazelPrefs
    /// The prefs file and saved-game seam (`.SaveSG`'s writes; GameFlow always passes its own). Nil is allowed only
    /// for a run that never reaches a save point (a precondition failure there).
    private let files: FrontFiles?
    /// `.SaveSG` in progress (the frame is suspended meanwhile) and the answers the App gave.
    private var saveSG: SaveSG?
    private var saveStep: SaveSG.Step?
    private var fileAnswer: FileResult?
    private var dialogAnswered = false

    /// The save panel (`ShellRequest.putFile`) was answered; the run goes on at the next tick.
    public func fileDone(_ result: FileResult) {
        fileAnswer = result
    }

    /// The dialog the run asked for (`ShellRequest.dialog`) was answered — a save point's error report, a
    /// `.CheckGameLoopKeys` confirm, the Options dialog (once `prefsDialog.result` is set), or the pause's Abort Game
    /// confirm; the run goes on at the next tick.
    public func dialogDone(_ result: DialogResult) {
        if let c = conversation {
            c.dialogDone()
        } else if saveSG != nil {
            dialogAnswered = true
        } else if case .pause? = keysModal, var p = pause {
            p.dialogDone(ok: result == .ok)
            pause = p
        } else if keysModal != nil {
            keysAnswer = result
        } else {
            dialogAnswered = true
        }
    }

    // MARK: P1 — `.CheckGameLoopKeys`

    /// `.Pause` while it runs (nil otherwise).
    public private(set) var pause: PauseRun?
    /// O1's model while ⌘P's DLOG 6900 is up (nil otherwise); the App drives it and answers `dialogDone` once its
    /// `result` is set (as `GameFlow.prefsDialog`).
    public var prefsDialog: PrefsDialogModel?
    /// The keyboard layout's character for a key code (the Options dialog's key names; `GameFlow.keyCharacter`).
    public var keyCharacter: @Sendable (Int16) -> String? = { _ in nil }
    /// `*PTR_DAT_100a0b64`: the modifier the Options dialog last captured (a global the flow carries).
    public var lastModifier: Int16 = 0

    /// A menu item chosen while paused (A1b): taken at the pause loop's next poll; ignored when not paused.
    public func menuChosen(_ item: PauseRun.MenuItem) {
        guard var p = pause else { return }
        p.menuChosen(item)
        pause = p
    }

    /// A1b: the pause's Game ▸ Preferences… model while it is up (nil otherwise) — `GameFlow.prefsDialog` forwards here.
    public var pausePrefsDialog: PrefsDialogModel? {
        get { pause?.prefsDialog }
        set { pause?.prefsDialog = newValue }
    }

    /// The Apple events queued (A1a; the flow hands its queue in before each `tick` and takes it back after): every
    /// finished iteration drops one when prefs+0x08 "Allow background tasks" is set (`.GameLoop`'s
    /// `WaitNextEvent(0xffff, …, 0, 0)`, its event never handled, M l. 5277–5279); the pause loop dispatches one
    /// (`PauseRun.appleEvents`).
    public var appleEvents = PendingAppleEvents()
    /// The pause loop dispatched the quit event: the run ended `.quit` (`.Quit` from inside `.Pause`).
    public private(set) var quitEventDispatched = false

    /// The `.CheckGameLoopKeys` modal in progress.
    private enum KeysModal {
        case confirm(GameLoopKeyEvent)
        case options
        case pausePaint
        case pause
    }

    private var keysModal: KeysModal?
    private var keysAnswer: DialogResult?

    // MARK: C1 — conversations and signs

    /// `.Conversation` / `.SimpleConv` while it runs (nil otherwise).
    public private(set) var conversation: ConversationRun?
    /// PK: the upgrade arm's blocking animation while it runs (nil otherwise).
    public private(set) var upgrade: UpgradeAnimation?
    /// The conversation text's measures (Render's font, C2; the App sets them, A1a). Default: unmeasured.
    public var conversationText = ConversationText.unmeasured

    /// What the next level's run takes: the session's carry (parity, particle counters, water cache, G — the live
    /// G after this level, crunch log included) plus the tileset and cached-face state `.SetupLevel` left. Carry →
    /// F1b: the class face cache and the tileset globals `DAT_100a267d` / `_DAT_100a267e` persist across games in the
    /// original (only the launch data section initialises them), while a `LevelCarry()` starts them fresh — the flow
    /// must hand this carry on from game to game, not only from level to level.
    public var carry: LevelCarry {
        var c = session?.carry ?? carryIn
        c.tilesetLevel = tilesetLevel
        c.tilesetsDisposed = tilesetsDisposed
        c.cachedFaces = cachedFaces
        return c
    }

    /// One tick at absolute 60 Hz `now` with this tick's polled input: its draws split by renderer, in order
    /// (`LevelRunOutput`). Throws what the session init or the level services throw.
    public func tick(now: UInt32, input: FrontInput) throws -> LevelRunOutput {
        var out = LevelRunOutput()
        lastSteps = []
        tickPlaying = input.playing
        while end == nil {
            if var run = blocking {
                emit(&out, run.tick(now: now))
                guard run.isDone(now: now) else {
                    blocking = run
                    return out
                }
                blocking = nil
            }
            if var c = chapter {
                var o = c.tick(now: now, input: input, fade: &fade)
                if c.isDone, let s = session {
                    // HU: the card's closing `.UpdateStatusBar(0, 0, 0)` (M l. 5087) runs the key step on the live G
                    // with this tick's keys — the session makes it (the card holds no G).
                    for (k, op) in o.draws.enumerated() {
                        guard case .statusBar = op else { continue }
                        let bar = s.updateStatusBar(.chapterScreen, keys: input.keys)
                        o.draws[k] = bar.draws[0]
                        o.sounds += bar.sounds                      // its snd 442, at the call (M l. 4492)
                    }
                }
                emit(&out, o)
                guard c.isDone else {
                    chapter = c
                    return out
                }
                chapter = nil
            }
            if playing {
                guard try loop(now: now, input: input, out: &out) else { return out }
                continue
            }
            if let t = exitAt {
                guard Int32(bitPattern: now &- t) >= 0 else { return out }
                exitAt = nil
            }
            if !stages.isEmpty, stages[0] == .deathEffect {
                guard try deathEffect(now: now, out: &out) else { return out }
                continue
            }
            guard !stages.isEmpty else { return out }
            let stage = stages.removeFirst()
            try run(stage, now: now, input: input, out: &out)
        }
        return out
    }

    private func emit(_ out: inout LevelRunOutput, _ o: FrontOutput) {
        out.append(o, levelClut: ColorLUT.screenClutId(levelFile.header), owner: &drawOwner)
        tickPlaying = SoundVoices.playing(tickPlaying, applying: o.sounds, stops: o.soundStops, stopAt: o.soundStopAt)
    }

    /// VS: the tick's playing set (`FrontInput.playing`) with every play and stop this tick has already handed the
    /// shell applied — what each `step` / `resume` of the tick reads (a resume or the second iteration of a pair on
    /// the same tick follows the calls made before it).
    private var tickPlaying: Set<Int16> = []

    private func block(_ t: FrontTimeline, now: UInt32) {
        if !t.isEmpty { blocking = TimelineRun(t, start: now) }
    }

    // MARK: Entry

    private func run(_ stage: Stage, now: UInt32, input: FrontInput, out: inout LevelRunOutput) throws {
        let h = levelFile.header
        switch stage {
        case .musicOut:
            // `_FadeAIFFMusic(0, 4)` (M l. 5161), then `_ShutDownAIFFMusic()` (M l. 5163) on the tick it ends.
            var t = music.fadeAIFFMusic(direction: 0, ticks: 4, prefs: prefs)
            let stop = music.shutDown()
            if !stop.isEmpty { t.events.append(.init(at: t.duration, output: FrontOutput(music: stop))) }
            block(t, now: now)
        case .popup:
            block(StageScreens.popupStageLoad(), now: now)
        case .setupLevel:
            try setupLevel(input: input, out: &out)
            // `_UpdateStageLoad(100, 100)` (M l. 2569), then `_GammaFadeOut(6, …)` (M l. 2570). The colour argument
            // (`_DAT_100a53d0…` halves) only feeds the async fade-out colour [LOW: black, as L2's chapter card].
            emit(&out, StageScreens.updateStageLoad(100, of: 100))
            block(fade.gammaFadeOut(6, rgb: RGB16(red: 0, green: 0, blue: 0)), now: now)
        case .setupLevelTail:
            // `_SetScreenClut(*piVar8)` (the level CLUT, hdr+0x285e, 0 → 202), `_DrawPICTToBackScreen(0x81)`, the
            // scroll point zeroed, `_RedrawEntireScrollGrid` (M l. 2571–2582).
            emit(&out, FrontOutput(draws: [.setScreenClut(id: ColorLUT.screenClutId(h)),
                                           .drawPicture(id: 129, chain: .frontEnd, h: 0, v: 0),
                                           .redrawEntireScrollGrid(h: 0, v: 0)], present: true))
        case .gammaIn8:
            // `if (param_4 && hdr+0x2712 ≠ 0) _GammaFadeIn(8)` (M l. 5196–5197; no level in the data sets it).
            if param4 && h.gammaFadeIn != 0 { block(fade.gammaFadeIn(8), now: now) }
        case .preLoop:
            guard let s = session else { return }
            // `_LoadLevelSounds()` (M l. 5199: header+0x26d0 = 0 on every level — no per-level sounds), `DAT_100a5106
            // = 0` (M l. 5200), `_HideCursorSafe()` (M l. 5203), then the start draws (M l. 5206–5216). Carry: a
            // hosted session no longer sends `.hideMenuBar` — `_HideTheMenuBar` is `.main`'s (M l. 8280) and
            // `.MainMenu`'s (M l. 7349) → F1a, and `.ContinueGame`'s (M l. 6877) → F1b; `.GameLoop` never calls it. `*fd74 = 0x200`
            // (M l. 5217) and `fe0c`/`511e` (status-bar redraw flags) have no Core reader.
            var start = s.startOps(keys: input.keys)
            start.requests = [.hideCursor]
            start.present = true
            emit(&out, start)
            // The boss-music rule (M l. 5218–5220): hdr+0x2724 ≠ 0 ∧ `*_DAT_1009fed0` ("no boss alive": cleared by a
            // boss Setup, set by its Kill — engine §4) → `hdr+0x284a = 0x1e`. // later: Phase 5 — the boss Setups and
            // Kills that write `fed0` are not transcribed; no Phase-3 level has hdr+0x2724 ≠ 0 (levels 1–2: 0).
            let noBossAlive = false
            let track = h.arenaBound != 0 && noBossAlive ? 0x1e : Int(h.music)
            emit(&out, FrontOutput(music: music.setAIFFMusic(track)))
            block(music.fadeAIFFMusic(direction: 1, ticks: 4, prefs: prefs), now: now)
        case .chapterGate:
            guard let s = session else { return }
            if h.chapter != 0 && s.globals.hasSnapshot[levelNumber] == 0 {
                // `_InputActivate(1, 1)` (M l. 5224): InputSprocket — never active in the replica (prefs+0x0a forced
                // 0, O1): no op. Then `.ChapterScreen(hdr+0x273c)` (L2; nil = no clut 280 + n → skipped).
                chapter = ChapterScreenRun(chapter: h.chapter, levelClut: ColorLUT.screenClutId(h),
                                           statusBar: s.globals.statusBar(levelName: h.name), resources: resources)
            }
        case .armFade:
            guard let s = session else { return }
            // `_GammaFadeInAsync(0x28)` on every entry (M l. 5228; BC13), stepped once per iteration by the session's
            // `.HandleAsyncGammaFade` (M l. 5282) — 41 iterations from `.SetupLevel`'s fade-out.
            var g = AsyncGammaFade(fadedOut: fade.faded, done: fade.noAsyncFade, fadingEnabled: fade.fadingEnabled)
            g.fadeIn(steps: 0x28)
            s.world.gammaFade = g
            playing = true
            lastStart = nil
        case .exit:
            exitSequence(now: now)
        case .deathEffect:
            break                                                      // `tick` runs it step by step
        case .completeSave:
            guard let s = session else { return }
            // `.EndLevelSGUpdate @ 1000c8d8` (M l. 6501ff): `FlushEvents`, the stamp (`Mwld+0x100`), `GetDateTime`,
            // `+6 = 1`, `+8 = L`, `hasSnapshot[L] = 1` in the live G, the G copy, x / y = `*fe68` / `*fe64` (M l.
            // 6541–6542) — the player's whole-px position as `.HandlePlayerSprite` last wrote it (M l. 46367–46376,
            // every frame): where the player stood at the exit (`PlayerState.pixelX/Y`) — the live records −6.
            var g = s.world.globals
            save.endLevelSGUpdate(level: Int16(levelNumber), x: s.world.player.pixelX, y: s.world.player.pixelY,
                                  stamp: worldStamp, date: date(), globals: &g, records: s.world.records)
            s.world.globals = g
        case .stageComplete:
            guard let s = session else { return }
            if !skipStageComplete {
                // `.STPlayRegSound` reads the live prefs+0x0b and `iRam100a510c` (M l. 40605ff): an in-level
                // `.MakeCurrPrefs` (⌘P, the pause's ⌘F, a save's `.UpdateSGString`) is heard here.
                let live = StageSounds(prefs: livePrefs, lengths: sounds.lengths)
                block(StageScreens.stageCompleteEffect(globals: s.globals, level: levelNumber, sounds: live), now: now)
            }
            skipStageComplete = false                                  // `*_DAT_1009fd64 = 0` (M l. 5313)
        case .completeMusic:
            block(music.fadeAIFFMusic(direction: 0, ticks: 2, prefs: prefs), now: now)   // M l. 5314
        case .completeFade:
            block(fade.gammaFadeOut(6, rgb: RGB16(red: 0, green: 0, blue: 0)), now: now) // M l. 5315
        case .finish:
            // `_ShutDownAIFFMusic`, `_TurnOffOmniPx`, `_KillOmniPx` (no OmniPx in Phase 3), `_InputActivate(0, 0)`
            // (no op), `_ShowCursorSafe` (M l. 5320–5324).
            emit(&out, FrontOutput(music: music.shutDown(), requests: [.showCursor]))
            end = levelEnd()
        }
    }

    /// `.SetupLevel`'s body up to `.LoadCachedSpriteFaces` (M l. 2252–2568): the bars, the G writes, the session
    /// init (crunch re-apply, records, the Setups, the player), the totals, the cached-face bars.
    private func setupLevel(input: FrontInput, out: inout LevelRunOutput) throws {
        let h = levelFile.header
        let L = levelNumber
        // `if (*psVar6 == _DAT_100a267e && DAT_100a267d == 0)` (M l. 2252): the restart fast path → 25 % (M l. 2270);
        // else `.LoadLevelTilesets` (M l. 2359) → 15, 20, 25, 35, 40 % (M l. 1588–1629), then `_DAT_100a267e = L`,
        // `DAT_100a267d = 0` (M l. 2360–2361). Data-section initial 267d = 1, 267e = −1 (`const.py 100a267c`:
        // 01 01 ff ff), so the first level after launch takes the long path.
        let fast = Int16(truncatingIfNeeded: L) == tilesetLevel && !tilesetsDisposed
        for p: Int16 in fast ? [0x19] : [0xf, 0x14, 0x19, 0x23, 0x28] {
            emit(&out, StageScreens.updateStageLoad(p, of: 100))
        }
        if !fast {
            // The CLUT ids (M l. 2331–2332, inside the other-level branch, before `.LoadLevelTilesets`).
            cachedFaces.enterLevel(screenClut: h.screenClut)
            tilesetLevel = Int16(truncatingIfNeeded: L)
            tilesetsDisposed = false
        }
        // `G+0x20 = 0` (byte), `G+0x22 ← hdr+0x2706` (M l. 2376–2377); F4 held → `hasSnapshot[L] = 0` (M l. 2378–2381).
        var g = carryIn.globals ?? GameGlobals(header: h)
        g.darknessOverride = 0
        g.savedDarkness = h.darknessEnable
        if input.keys.isPressed(0x76) { g.hasSnapshot[L] = 0 }
        revisit = g.hasSnapshot[L] == 1
        var carry = carryIn
        carry.globals = g
        carry.crunchLog = g.crunchLog
        let faces = try services.prepare(level: L)
        let s = try FerazelSession(resources: resources, prefs: prefs, level: L, seed: seed, carry: carry,
                                   faceBounds: faces.faceBounds, particleFaces: faces.particleFaces, start: start,
                                   refreshFacing: refreshFacing,
                                   records: revisit ? save.restoreSnapshot(level: Int16(L)) : nil,
                                   hostedByLevelRun: true)
        session = s
        try services.attach(lights: s.lights, tintTableDraws: s.tintTableDraws)
        // `*(G + player +0x46) = param_3` (M l. 5188).
        if let pid = s.world.playerID { s.world.active.update(id: pid) { $0.phase = self.param3 } }
        // The re-apply's tile writes (M l. 2382–2393), then `_UpdateStageLoad(0x32, 100)` (M l. 2519).
        emit(&out, FrontOutput(draws: s.setupLevelTileOps))
        emit(&out, StageScreens.updateStageLoad(0x32, of: 100))
        if !revisit {
            // A first visit (`bVar1`, M l. 2528–2536): achieved 0, totals ← the Setups' tallies.
            for k in 0..<3 { s.world.globals.achieved[k][L] = 0 }
            s.world.globals.totals[0][L] = s.tallies.enemies
            s.world.globals.totals[1][L] = s.tallies.xichrons
            s.world.globals.totals[2][L] = s.tallies.secrets
        }
        // `.LoadCachedSpriteFaces` (M l. 2537): one bar per face set / single loaded, then 100 % (M l. 73864).
        for (p, q) in cachedFaces.load(needed: CachedFaces.needed(by: s)) {
            emit(&out, StageScreens.updateStageLoad(p, of: q))
        }
        emit(&out, StageScreens.updateStageLoad(100, of: 100))
        // `*(char *)(G + 0x174) = 0` (M l. 2539).
        s.world.globals.omniPxActive = 0
    }

    // MARK: The loop

    /// The loop's part of a tick (Invariant 4): returns false when the run waits for a later tick.
    private func loop(now: UInt32, input: FrontInput, out: inout LevelRunOutput) throws -> Bool {
        guard let s = session else { return false }
        var ops: FrameOps
        if saveSG != nil || keysModal != nil || conversation != nil || upgrade != nil {
            // S1 / P1: a suspended frame waits for the modal; its answer finishes the same iteration.
            guard let resumed = advanceModal(s, now: now, input: input, out: &out) else { return false }
            ops = resumed
        } else {
            let reduce = prefs.reduceFrameRate != 0
            // `.GameLoop`'s bottom-of-loop wait (M l. 5285–5294): prefs[0] = 0 → until 2 ticks after the iteration's
            // start; prefs[0] ≠ 0 → the non-drawing iteration does not wait, the drawing one waits until 4 ticks after
            // its own start. A late tick runs one iteration (or pair): fixed step, no catch-up.
            if let last = lastStart, now &- last < (reduce ? 4 : 2) { return false }
            lastStart = now
            ops = step(s, input: input, out: &out)
        }
        let reduce = prefs.reduceFrameRate != 0
        while true {
            if let suspension = ops.suspension {
                beginModal(s, suspension: suspension, now: now, out: &out)
                guard end == nil, let resumed = advanceModal(s, now: now, input: input, out: &out) else { return false }
                ops = resumed
                continue
            }
            if reduce && !ops.drawn && !s.loopEnded {
                ops = step(s, input: input, out: &out)
                continue
            }
            break
        }
        guard s.loopEnded else { return false }
        // The loop is over after this iteration (M l. 5229); its own wait still runs out first.
        playing = false
        exitAt = now &+ UInt32(reduce ? (ops.drawn ? 4 : 0) : 2)
        stages = [.exit]
        return true
    }

    private func step(_ s: FerazelSession, input: FrontInput, out: inout LevelRunOutput) -> FrameOps {
        let ops = s.step(keys: input.keys, capsLock: input.capsLock, playing: tickPlaying)
        iterations += 1
        emitFrame(ops, out: &out)
        return ops
    }

    /// One iteration's ops (or a suspended part of one) into the tick's output. `present`: a part after a
    /// `.CheckGameLoopKeys` answer (its redraws and nested `.PaintFrameWrap` change the screen whatever the iteration's
    /// draw flag).
    private func emitFrame(_ ops: FrameOps, out: inout LevelRunOutput, present: Bool = false) {
        lastSteps.append(ops)
        var o = FrontOutput(draws: ops.draws, sounds: ops.sounds, soundStops: ops.soundStops,
                            soundStopAt: ops.soundStopAt, music: ops.music, requests: ops.requests)
        // A skipped iteration leaves the screen as it was, but its `.HandleAsyncGammaFade` still moves the gamma.
        o.present = present || ops.drawn || ops.draws.contains { if case .gammaStep = $0 { true } else { false } }
        // `_HandleAsyncAIFFMusicFade()` (M l. 5281), after `.UpdateStatusBar(1, 0, 0)` — at the iteration's end, so
        // not in a suspended part: nothing armed outside the boss rule's in-loop block (M l. 5257–5266, // later:
        // Phase 5).
        if ops.suspension == nil { o.music += music.handleAsyncFade(prefs: prefs) }
        emit(&out, o)
        // `if (prefs+0x08) WaitNextEvent(0xffff, …, 0, 0)` after `_UpdateSprites` (M l. 5277–5279): an iteration's
        // end fetches one queued event and never handles it — a quit or an open is lost.
        if ops.suspension == nil && prefs.backgroundTasks != 0 { _ = appleEvents.takeFirst() }
    }

    // MARK: The save point (S1)

    /// The session suspended: a save point (S1) or `.CheckGameLoopKeys` (P1).
    private func beginModal(_ s: FerazelSession, suspension: FrameSuspension, now: UInt32,
                            out: inout LevelRunOutput) {
        if case .gameLoopKeys(let e) = suspension {
            beginKeys(s, e, now: now, out: &out)
        } else {
            beginSave(s, suspension: suspension, out: &out)
        }
    }

    /// The modal's answers so far: the rest of the frame when it has returned (nil while it waits).
    private func advanceModal(_ s: FerazelSession, now: UInt32, input: FrontInput,
                              out: inout LevelRunOutput) -> FrameOps? {
        if let c = conversation {
            // C1: `.Conversation` / `.SimpleConv` until it returns, then the rest of the arm and the frame.
            emit(&out, c.tick(now: now, input: input, save: &save))
            guard c.isDone else { return nil }
            conversation = nil
            // The rest of the frame reads the input of this tick (live in the original; the run ended on all keys up).
            if case .simple = c.kind {
                return resumeTalk(s, .sign(keys: input.keys, capsLock: input.capsLock), out: &out)
            }
            return resumeTalk(s, .conversation(keys: input.keys, capsLock: input.capsLock), out: &out)
        }
        if var u = upgrade {
            // PK: the upgrade's tick loops (`UpgradeAnimation`), then the rest of the frame — the arm's remainder
            // returns; the later contacts and `.CheckGameLoopKeys` read the input of this tick (live in the original).
            emit(&out, u.tick(now: now, session: s, keys: input.keys))
            guard u.isDone else { upgrade = u; return nil }
            upgrade = nil
            let rest = s.resume(.upgrade(keys: input.keys, capsLock: input.capsLock), playing: tickPlaying)
            emitFrame(rest, out: &out, present: true)
            return rest
        }
        if saveSG != nil { return advanceSave(s, input: input, out: &out) }
        guard let m = keysModal else { return nil }
        switch m {
        case .confirm:
            guard let a = keysAnswer else { return nil }
            keysAnswer = nil
            keysModal = nil
            return resumeKeys(s, .confirm(ok: a == .ok), input: input, out: &out)
        case .options:
            guard keysAnswer != nil else { return nil }
            keysAnswer = nil
            keysModal = nil
            closeOptions(s, out: &out)
            return resumeKeys(s, .optionsClosed, input: input, out: &out)
        case .pausePaint:
            keysModal = nil
            return resumeKeys(s, .pausePaint, input: input, out: &out)
        case .pause:
            guard var p = pause else { return nil }
            p.appleEvents = appleEvents
            emit(&out, p.tick(now: now, input: input))
            appleEvents = p.appleEvents
            pause = p
            if p.quitDispatched {
                // `.DoQuitAppAE` → `.Quit` inside the pause loop: it never returns (no pause exit, no rest of frame).
                quitEventDispatched = true
                pause = nil
                keysModal = nil
                playing = false
                end = .quit
                return nil
            }
            guard p.isDone else { return nil }
            // The pause's live side back: the music player, the prefs ⌘M / ⌘F / Preferences… re-made current, the
            // Options dialog's last captured modifier.
            music = p.live.music
            lastModifier = p.lastModifier
            if p.live.live != livePrefs { applyPrefs(p.live.live, s) }
            pause = nil
            keysModal = nil
            return resumeKeys(s, .pauseEnded(aborted: p.aborted), input: input, out: &out)
        }
    }

    /// `.CheckGameLoopKeys`' modal starts (`GameLoopKeys`; the session has made `ShowCursorSafe`).
    private func beginKeys(_ s: FerazelSession, _ e: GameLoopKeyEvent, now: UInt32, out: inout LevelRunOutput) {
        switch e {
        case .confirmQuit, .confirmAbort:
            // `ParamText(…)`, `.ConfirmAbortGameDialog` (DLOG 202).
            let text = e == .confirmQuit ? GameLoopKeys.quitText : GameLoopKeys.abortText
            emit(&out, FrontOutput(requests: [.dialog(.confirm(text: text))]))
            keysModal = .confirm(e)
            keysAnswer = nil
        case .options:
            // `.Options @ 1000e470` (M l. 7254ff): `FlushEvents`, `InputActivate(0, 0)`, `ShowCursorSafe`, the prefs
            // file re-read (`.SetPrefFile` + `.InitPrefs`), `.PreferencesDialog` — not paused.
            let record = files?.loadPrefs().map(FerazelPrefs.init(record:)) ?? FerazelPrefs()
            prefsDialog = PrefsDialogModel(record: record, live: PrefsToggles(live: livePrefs, music: music),
                                           paused: false, lastModifier: lastModifier, keyCharacter: keyCharacter)
            emit(&out, FrontOutput(requests: [.showCursor, .dialog(.preferences)]))
            keysModal = .options
            keysAnswer = nil
        case .pause:
            var p = PauseRun(resources: resources, onMap: false, prefs: livePrefs, music: music,
                             levelClut: ColorLUT.screenClutId(levelFile.header),
                             scroll: PauseRun.Scroll(h: s.camera.scrollH, v: s.camera.scrollV), files: files)
            p.keyCharacter = keyCharacter
            p.lastModifier = lastModifier
            emit(&out, p.enter())
            pause = p
            keysModal = .pausePaint
        case .paused:
            guard var p = pause else { return }
            emit(&out, p.painted(now: now))
            pause = p
            keysModal = .pause
        case .quit:
            // `.Quit()` (the flow's `GameFlow.quit`) never returns: no exit sequence.
            playing = false
            end = .quit
        }
    }

    /// `.Options`' close (M l. 7275–7286): the record written back, `MTRedraw`, `.MakeCurrPrefs` (not paused: a changed
    /// music flag re-applies at once), `.UpdateMenus` (the bar stays hidden in a level), `fe0c` / `511e` (no Core
    /// reader); the new live prefs into the run and the session.
    private func closeOptions(_ s: FerazelSession, out: inout LevelRunOutput) {
        guard let model = prefsDialog else { return }
        try? files?.storePrefs(model.record.record())
        var toggles = model.live
        lastModifier = model.lastModifier
        var o = FrontOutput(present: true)
        o.append(toggles.makeCurrPrefs(model.record, paused: false))
        o.requests.append(.showMenuBarItems(MenuState(menusLive: false, paused: false,
                                                      musicOn: toggles.live.musicOn != 0,
                                                      soundOn: toggles.live.soundOn != 0)))
        music = toggles.music
        applyPrefs(toggles.live, s)
        prefsDialog = nil
        emit(&out, o)
    }

    /// The live prefs replaced (`.MakeCurrPrefs` in a level): the run's, the saves', the session's.
    private func applyPrefs(_ p: FerazelPrefs, _ s: FerazelSession) {
        prefs = p
        prefsAfterSaves = p
        s.prefs = p
    }

    /// The session's frame on from a `.gameLoopKeys` suspension with this tick's input.
    private func resumeKeys(_ s: FerazelSession, _ reply: GameLoopKeyAnswer.Reply, input: FrontInput,
                            out: inout LevelRunOutput) -> FrameOps {
        let rest = s.resume(.gameLoopKeys(GameLoopKeyAnswer(reply: reply, keys: input.keys,
                                                            capsLock: input.capsLock)),
                            playing: tickPlaying)
        emitFrame(rest, out: &out, present: true)
        return rest
    }

    /// The session suspended at a save point (`HitPlayerSprite.savePoint`): `.SavePointSave` (M l. 6322ff) —
    /// `InputActivate(0, 0)` and `FlushEvents(0xff7f)` (nothing in Core), the block written at that moment, then
    /// `.SaveSG(prefs[1] == 0)`.
    private func beginSave(_ s: FerazelSession, suspension: FrameSuspension, out: inout LevelRunOutput) {
        switch suspension {
        case .savePoint:
            SavePointSave.write(&save, session: s, stamp: worldStamp, date: date())
            var sg = SaveSG(state: saveState, prefs: livePrefs)
            saveStep = sg.start(prompt: livePrefs.reuseSavedGames == 0,
                                message: SaveSG.putFileMessage(resources: resources), block: save, files: files,
                                musicFade: &music)
            saveSG = sg
            fileAnswer = nil
            dialogAnswered = false
            switch saveStep {
            case .putFile(let req)?: emit(&out, FrontOutput(requests: [.putFile(req)]))
            case .report(let d)?: emit(&out, FrontOutput(requests: [.dialog(d)]))      // a reuse save's write error
            default: break
            }
        case .conversation(let id, let record, let sprite):
            conversation = ConversationRun(.conversation(id: id, record: record, sprite: sprite), world: s.world,
                                           resources: resources, prefs: livePrefs, levelName: levelFile.header.name,
                                           text: conversationText)
        case .sign(let text):
            conversation = ConversationRun(.simple(pict: HitPlayerSprite.signPortrait,
                                                   name: MacRoman.bytes(HitPlayerSprite.signName), text: text),
                                           world: s.world, resources: resources, prefs: livePrefs,
                                           levelName: levelFile.header.name, text: conversationText)
        case .upgrade(let type):
            upgrade = UpgradeAnimation(type: type)
        case .gameLoopKeys:
            preconditionFailure("beginModal routes the keys")
        }
    }

    /// The session's frame on from a conversation / sign suspension (C1).
    private func resumeTalk(_ s: FerazelSession, _ outcome: FrameSuspension.Outcome,
                            out: inout LevelRunOutput) -> FrameOps {
        let rest = s.resume(outcome, playing: tickPlaying)
        emitFrame(rest, out: &out, present: true)
        return rest
    }

    /// `.SaveSG` on from its last step with the App's answers; when it has returned: `.SavePointSave`'s tail and the
    /// session's `resume` — the rest of the frame's ops (nil while still waiting).
    private func advanceSave(_ s: FerazelSession, input: FrontInput, out: inout LevelRunOutput) -> FrameOps? {
        guard var sg = saveSG, var step = saveStep else { return nil }
        while true {
            switch step {
            case .putFile:
                guard let a = fileAnswer else { saveSG = sg; return nil }
                fileAnswer = nil
                step = sg.fileDone(a, block: save, files: files, musicFade: &music)
                if case .report(let d) = step { emit(&out, FrontOutput(requests: [.dialog(d)])) }
            case .report:
                guard dialogAnswered else { saveSG = sg; saveStep = step; return nil }
                dialogAnswered = false
                step = sg.reportDone()
            case .done(let saved):
                saveSG = nil
                saveStep = nil
                saveState = sg.state
                // `.SaveSG` edits the live prefs (prefs+0x42) and `.UpdateSGString` re-makes them current: the run's
                // and the session's copies follow (P1 review fix).
                applyPrefs(sg.prefs, s)
                if sg.madeCurrent || !sg.music.isEmpty {
                    emit(&out, FrontOutput(music: sg.music, prefs: sg.madeCurrent ? sg.prefs : nil))
                }
                // The tail reads the live prefs (`_DAT_1009fe44 + 2`, `5107`) as `.UpdateSGString` left them.
                emit(&out, SavePointSave.redraw(session: s, prefs: livePrefs, keys: input.keys))
                let rest = s.resume(.savePoint(saved: saved), playing: tickPlaying)
                emitFrame(rest, out: &out)
                return rest
            }
            saveStep = step
        }
    }

    // MARK: Exit

    /// After the loop (M l. 5296–5302): the session's async gamma back into `ScreenFade`, then the branch.
    private func exitSequence(now: UInt32) {
        guard let s = session else { return }
        syncFade(from: s)
        if s.globals.health < 1 {
            died = true                                                // `*_DAT_1009ffa8 = 1` (M l. 5303)
            s.world.playerDead = true
            let t = music.fadeAIFFMusic(direction: 0, ticks: 2, prefs: prefs)   // M l. 5304
            stages = [.deathEffect, .finish]
            deathStep = -1
            block(t, now: now)
        } else if s.world.player.levelDone {
            stages = [.completeSave, .stageComplete, .completeMusic, .completeFade, .finish]
        } else {
            stages = [.finish]
        }
    }

    /// `.DeathEffect` (M l. 2676–2738): `GammaFadeOutAsync(0x30, black)` first (gated: fading enabled, not faded
    /// out — with the entry's fade-in still running the screen is still "faded", so the fade-in keeps going), then
    /// 50 steps one tick apart: the bands (`LevelServices`), one `.HandleAsyncGammaFade`. Returns false while waiting.
    private func deathEffect(now: UInt32, out: inout LevelRunOutput) throws -> Bool {
        guard let s = session else { return false }
        if deathStep < 0 {
            var g = s.world.gammaFade
            let armed = g.fadeOut(steps: 0x30, toward: RGB16(red: 0, green: 0, blue: 0))
            s.world.gammaFade = g
            // `.GammaFadeOutAsync` calls `HideCursorSafe` when it arms (M l. 31905).
            if armed { emit(&out, FrontOutput(requests: [.hideCursor])) }
            deathStep = 0
            deathNext = now
        }
        while deathStep < 50 {
            guard Int32(bitPattern: now &- deathNext) >= 0 else { return false }
            try services.deathEffectStep(deathStep)
            var g = s.world.gammaFade
            let fadingIn = !g.done && g.fadingIn
            let op = g.handle()
            s.world.gammaFade = g
            // The entry's fade-in ending here: `_ShowCursorSafe()` (M l. 31945), as in the session's step.
            emit(&out, FrontOutput(draws: op.map { [$0] } ?? [], requests: fadingIn && g.done ? [.showCursor] : [],
                                   present: true))
            deathStep += 1
            deathNext = now &+ 1
            return false
        }
        guard Int32(bitPattern: now &- deathNext) >= 0 else { return false }
        syncFade(from: s)
        stages.removeFirst()                                           // `.deathEffect` done
        return true
    }

    private func syncFade(from s: FerazelSession) {
        fade.faded = s.world.gammaFade.fadedOut
        fade.noAsyncFade = s.world.gammaFade.done
    }

    private func levelEnd() -> LevelEnd {
        guard let s = session else { return .aborted }
        if died { return .died }
        if s.world.player.levelDone {
            return .completed(exit1: s.world.player.exitIndex, exit2: s.world.player.exit2)
        }
        return .aborted
    }
}

/// The class face cache (`.CacheEncFaceSetFromPICT @ 10089250` / `.Cache1EncFaceFromPICT @ 100893d4`, registered at
/// boot by `.InitSprites`' Init routines, M l. 106–145) as far as `.LoadCachedSpriteFaces @ 10088fa8`'s load bars need
/// it (L1): which records are loaded (`+0`), which the level's Setups mark needed (`+1 = 1`, after `FUN_10088ae0`
/// cleared every mark, M l. 2520, 73578ff), and the two CLUT ids `.NeedToReloadForThisClut` compares.
///
/// `.LoadCachedSpriteFaces` (M l. 73769–73868): `.DisposeUnneededCachedSpriteFaces` (M l. 73661ff — a loaded record
/// not needed, or with flag 1 while `sRam100a3eb2 ≠ _DAT_100a3eae`, is unloaded), n = `.CountNeededCachedSpriteFaces`
/// (needed ∧ not loaded: a set counts its faces, a single 1), q = 2n, p = n; each needed unloaded set in list order,
/// then each single: p += its faces, `UpdateStageLoad(p, q)`; then `UpdateStageLoad(100, 100)` (the caller's).
///
/// Self-derived for the types levels 1–2 place (L1 research, every mark read from its Setup; `docs/plans` L1 as
/// executed): level 1 after launch n 90, q 180 → p 96, 102, 108, 114, 120, 128, 134, 137, 139, 148, 157, 162 (twelve
/// sets) then 163 … 180 (eighteen singles) — widths 156, 166, 175, 185, 195, 208, 218, 223, 226, 240, 255, 263, 265,
/// 266, 268, 270, 271, 273, 275, 276, 278, 279, 281, 283, 284, 286, 288, 289, 291, 293; level 2 after level 1 n 31,
/// q 62 → 35, 46, 54 (sets 0x5be, 0x6cc, 0x708), 55 … 62; the level-1 restart n 6, q 12 → 7 … 12 (the six flag-1
/// singles reload: the fast path never updates the two CLUT ids, so −1 ≠ 202 still holds).
public struct CachedFaces: Equatable, Sendable {
    /// A cache record: a face set (its face count) or a single, and its `*_DAT_100a0a48` flag at registration.
    struct Record: Sendable {
        let pict: Int16
        let faces: Int
        let flag: Int16
    }

    /// The set list `_DAT_100a12b4` in registration order — the records levels 1–2 can mark (Crawler M l. 56142–56144,
    /// Roach 64893–64894, Walker 56757–56768, Box 58806, Background 61875, Bat 68099, Frog 70116). // later: Phase 4–6 —
    /// the other 50-odd sets, as their Setups are transcribed.
    static let sets: [Record] = [
        Record(pict: 0x6ae, faces: 6, flag: 0), Record(pict: 0x6af, faces: 6, flag: 0),
        Record(pict: 0x6b1, faces: 6, flag: 0),
        Record(pict: 0x6b8, faces: 6, flag: 0), Record(pict: 0x6b9, faces: 6, flag: 0),
        Record(pict: 0x6a5, faces: 8, flag: 0), Record(pict: 0x6a6, faces: 6, flag: 0),
        Record(pict: 0x6a9, faces: 3, flag: 0), Record(pict: 0x6aa, faces: 2, flag: 0),
        Record(pict: 0x6ab, faces: 9, flag: 0), Record(pict: 0x6e0, faces: 9, flag: 0),
        Record(pict: 0x5be, faces: 4, flag: 0), Record(pict: 0x442, faces: 5, flag: 0),
        Record(pict: 0x6cc, faces: 11, flag: 0), Record(pict: 0x708, faces: 8, flag: 0),
    ]

    /// The singles list `PTR_DAT_100a12b8` in registration order (the same subset): Walker 0x6a4 (M l. 56755); Box
    /// loops 0xaf5+i (58776), 0xb86+i (58781), the flag-1 block 0x5b4…0x5bb (58798–58805, raw `1006af78` / `1006b014`),
    /// 0xb22+i (flag 1, 58818–58823), 0xb36+i (58825), 0xb68+i (58830); Background 0xb54 (61862), 3000+i (flag 1,
    /// 61899), 0x5c8+i (61905), 0xa8c+i (flag 1, 61911).
    static let singles: [Record] = [
        Record(pict: 0x6a4, faces: 1, flag: 0),
        Record(pict: 0xb1a, faces: 1, flag: 0), Record(pict: 0xb20, faces: 1, flag: 0),
        Record(pict: 0xb21, faces: 1, flag: 0),
        Record(pict: 0xb87, faces: 1, flag: 0), Record(pict: 0xb88, faces: 1, flag: 0),
        Record(pict: 0xb8a, faces: 1, flag: 0),
        Record(pict: 0x5b5, faces: 1, flag: 1), Record(pict: 0x5b8, faces: 1, flag: 1),
        Record(pict: 0xb25, faces: 1, flag: 1),
        Record(pict: 0xb36, faces: 1, flag: 0), Record(pict: 0xb37, faces: 1, flag: 0),
        Record(pict: 0xb3a, faces: 1, flag: 0), Record(pict: 0xb43, faces: 1, flag: 0),
        Record(pict: 0xb6a, faces: 1, flag: 0), Record(pict: 0xb6c, faces: 1, flag: 0),
        Record(pict: 0xb6d, faces: 1, flag: 0), Record(pict: 0xb6e, faces: 1, flag: 0),
        Record(pict: 0xb6f, faces: 1, flag: 0), Record(pict: 0xb70, faces: 1, flag: 0),
        Record(pict: 0xb54, faces: 1, flag: 0),
        Record(pict: 0xbba, faces: 1, flag: 1),
        Record(pict: 0x5cd, faces: 1, flag: 0),
        Record(pict: 0xa96, faces: 1, flag: 1), Record(pict: 0xa99, faces: 1, flag: 1),
        Record(pict: 0xa9a, faces: 1, flag: 1),
    ]

    /// What a level's Setups mark needed: (sets, singles) by PICT.
    public struct Needed: Equatable, Sendable {
        public var sets: Set<Int16> = []
        public var singles: Set<Int16> = []
    }

    /// The marks each placed type's Setup makes (`rec+1 = 1`), for the types levels 1–2 place: Walker 0x6a4 → single
    /// 0x6a4 + sets 0x6a5, 0x6a6 (M l. 56966–56969), 0x6a9 → 0x6a9, 0x6aa, 0x6ab (56977–56980), 0x6e0…0x6e9 → 0x6e0
    /// (56989); Crawler 0x6b0 → 0x6ae, 0x6af, 0x6b1 (56188–56190); Roach 0x6b8 → 0x6b8, 0x6b9 (64931–64932);
    /// Background 0x442 → set 0x442 (62061), 0x5c8+i → single 0x5c8+i (≈ 62320), 0xa8c+i / 3000+i → their singles,
    /// 0xb54 (62434); Box 0x5b8 (59213), 0x5b5 / 0x5b6 → 0x5b5 (59200 / 59204), 0x5be → set 0x5be (59260), the
    /// decoration, outcrop, mushroom, furniture and NPC singles of the same id; Bat 0x6cc → set 0x6cc (68286); Frog
    /// 0x708 → set 0x708 (70211). Every other level-1/2 type marks nothing. // later: Phase 4–6 — the other types'.
    static func marks(type t: Int16) -> (sets: [Int16], singles: [Int16]) {
        switch t {
        case 0x6a4: return ([0x6a5, 0x6a6], [0x6a4])
        case 0x6a9: return ([0x6a9, 0x6aa, 0x6ab], [])
        case 0x6e0...0x6e9: return ([0x6e0], [])
        case 0x6b0: return ([0x6ae, 0x6af, 0x6b1], [])
        case 0x6b8: return ([0x6b8, 0x6b9], [])
        case 0x442: return ([0x442], [])
        case 0x5be: return ([0x5be], [])
        case 0x6cc: return ([0x6cc], [])
        case 0x708: return ([0x708], [])
        case 0x5b5, 0x5b6: return ([], [0x5b5])
        case 0x5b8, 0x5cd, 0xa96, 0xa99, 0xa9a, 0xbba, 0xb54, 0xb1a, 0xb20, 0xb21, 0xb87, 0xb88, 0xb8a, 0xb25,
             0xb36, 0xb37, 0xb3a, 0xb43, 0xb6a, 0xb6c, 0xb6d, 0xb6e, 0xb6f, 0xb70:
            return ([], [t])
        default: return ([], [])
        }
    }

    /// The marks of every record `.SetupLevelSprites` ran a Setup for (the session's live records, spawn order).
    public static func needed(by s: FerazelSession) -> Needed {
        var n = Needed()
        for p in SetupFaces.spawnOrder(s.world.records) {
            let m = marks(type: p.type)
            n.sets.formUnion(m.sets)
            n.singles.formUnion(m.singles)
        }
        return n
    }

    /// Loaded sets / singles (`rec+0 ≠ 0`).
    public private(set) var loadedSets: Set<Int16> = []
    public private(set) var loadedSingles: Set<Int16> = []
    /// `_DAT_100a3eae` (the level CLUT id, hdr+0x285e as stored) and `sRam100a3eb2` (the one before): data-section
    /// initial −1 / −2 (`const.py 100a3eac`: ffff ffff fffe fffe).
    public private(set) var levelClut: Int16 = -1
    public private(set) var previousLevelClut: Int16 = -2

    public init() {}

    /// `.SetupLevel`'s other-level branch (M l. 2331–2332): `3eb2 = 3eae; 3eae = hdr+0x285e`. The restart fast path
    /// leaves both.
    mutating func enterLevel(screenClut raw: Int16) {
        previousLevelClut = levelClut
        levelClut = raw
    }

    /// `.LoadCachedSpriteFaces`' dispose, count and loads; the (p, q) of each `UpdateStageLoad` before the final
    /// (100, 100). Every PICT is taken as present (all are in `Ferazel Sprites`).
    mutating func load(needed n: Needed) -> [(Int16, Int16)] {
        let reload = previousLevelClut != levelClut              // `.NeedToReloadForThisClut` (M l. 73651)
        for r in Self.sets where loadedSets.contains(r.pict) && (!n.sets.contains(r.pict) || (r.flag == 1 && reload)) {
            loadedSets.remove(r.pict)
        }
        for r in Self.singles
        where loadedSingles.contains(r.pict) && (!n.singles.contains(r.pict) || (r.flag == 1 && reload)) {
            loadedSingles.remove(r.pict)
        }
        let toSets = Self.sets.filter { n.sets.contains($0.pict) && !loadedSets.contains($0.pict) }
        let toSingles = Self.singles.filter { n.singles.contains($0.pict) && !loadedSingles.contains($0.pict) }
        let count = toSets.reduce(0) { $0 + $1.faces } + toSingles.count
        var p = count
        let q = Int16(truncatingIfNeeded: count * 2)
        var bars: [(Int16, Int16)] = []
        for r in toSets {
            p += r.faces
            loadedSets.insert(r.pict)
            bars.append((Int16(truncatingIfNeeded: p), q))
        }
        for r in toSingles {
            p += 1
            loadedSingles.insert(r.pict)
            bars.append((Int16(truncatingIfNeeded: p), q))
        }
        return bars
    }
}

/// PK: the upgrade arm's six blocking loops (1340 / 1341, `.HitPlayerSprite` M l. 48820–48917; pickups-boxes §1.3,
/// BC35), run by the flow over ticks while the frame is suspended (`FrameSuspension.upgrade`), on the session's state:
/// 1. 5 × (wait 2 ticks, `.HandleAsyncGammaFade`) — the arm's `GammaFadeOutAsync(2, …)` (3 steps) runs out;
/// 2. `.GammaFadeInAsync(0x28)`; 10 × (`.HandleAsyncGammaFade`, wait 1);
/// 3. the flash (`PTR_DAT_1009fdbc` for 1340, `_DAT_1009fdb8` for 1341) = 11; 11 × (flash − 1, `.UpdateStatusBar(1, 0,
///    1)`, `.HandleAsyncGammaFade`, wait 2);
/// 4. the refill — 1340: breath `G+6` = health `G+4` = max `G+0xa`, `G+8 = 8`; 1341: magic `G+0xe` = max `G+0xc`;
/// 5. 14 × (max + 8, bar, step, wait 2); 6. 14 × (1340: health + 8, breath + 8, the player's `+0xa4` = health; 1341:
///    magic + 8; bar, step, wait 2);
/// 7. the flash = 11; 11 × (flash − 1, bar, step, wait 2).
/// 120 ticks in all. Each wait is `TickCount() − n < t0` with t0 read at the loop iteration's start (`now` of the tick
/// that started it). A fade-in that ends inside the loops makes its `_ShowCursorSafe` (M l. 31945; a `.showCursor`
/// request). The bar calls are outside the frame's ops: their snd 442 goes out with them (`FerazelSession
/// .updateStatusBar`).
public struct UpgradeAnimation: Equatable, Sendable {
    public let type: Int16
    private enum Step: Equatable, Sendable {
        case wait(UInt32), handle, fadeIn, flashSet, flashDown, refill, maxUp, valueUp, bar
    }
    private let steps: [Step]
    private var next = 0
    private var until: UInt32?

    public init(type: Int16) {
        self.type = type
        var s: [Step] = []
        for _ in 0..<5 { s += [.wait(2), .handle] }
        s.append(.fadeIn)
        for _ in 0..<10 { s += [.handle, .wait(1)] }
        s.append(.flashSet)
        for _ in 0..<11 { s += [.flashDown, .bar, .handle, .wait(2)] }
        s.append(.refill)
        for _ in 0..<14 { s += [.maxUp, .bar, .handle, .wait(2)] }
        for _ in 0..<14 { s += [.valueUp, .bar, .handle, .wait(2)] }
        s.append(.flashSet)
        for _ in 0..<11 { s += [.flashDown, .bar, .handle, .wait(2)] }
        steps = s
    }

    /// The loops have run out: the flow resumes the frame (`.upgrade`).
    public var isDone: Bool { next == steps.count && until == nil }

    /// The steps due by `now`, with `keys` the live poll the bar calls' key step reads.
    public mutating func tick(now: UInt32, session s: FerazelSession, keys: KeyState) -> FrontOutput {
        var out = FrontOutput()
        let health = type == HitPlayerSprite.healthUpgrade, magic = type == HitPlayerSprite.magicUpgrade
        while true {
            if let u = until {
                guard Int32(bitPattern: now &- u) >= 0 else { return out }
                until = nil
            }
            guard next < steps.count else { return out }
            let step = steps[next]
            next += 1
            let w = s.world
            switch step {
            case .wait(let n):
                until = now &+ n
            case .handle:
                let fadingIn = !w.gammaFade.done && w.gammaFade.fadingIn
                if let op = w.gammaFade.handle() {
                    out.draws.append(op)
                    out.present = true
                }
                if fadingIn && w.gammaFade.done { out.requests.append(.showCursor) }
            case .fadeIn:
                w.gammaFade.fadeIn(steps: 0x28)
            case .flashSet:
                if health { w.statusBar.flashes.health = 0xb } else if magic { w.statusBar.flashes.magic = 0xb }
            case .flashDown:
                if health { w.statusBar.flashes.health &-= 1 } else if magic { w.statusBar.flashes.magic &-= 1 }
            case .refill:
                if health {
                    w.globals.breath = w.globals.maxHealth
                    w.globals.health = w.globals.maxHealth
                    w.globals.suffocation = 8
                } else if magic {
                    w.globals.magic = w.globals.maxMagic
                }
            case .maxUp:
                if health { w.globals.maxHealth &+= 8 } else if magic { w.globals.maxMagic &+= 8 }
            case .valueUp:
                if health {
                    w.globals.health &+= 8
                    w.globals.breath &+= 8
                    let hp = w.globals.health
                    if let p = w.playerID { w.active.update(id: p) { $0.hp = hp } }
                } else if magic {
                    w.globals.magic &+= 8
                }
            case .bar:
                var bar = s.updateStatusBar(.upgradeStep, keys: keys)
                bar.present = true
                out.append(bar)
            }
        }
    }
}

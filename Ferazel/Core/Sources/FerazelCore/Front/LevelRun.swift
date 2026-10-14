import Foundation

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
    /// ⌘Q OK (P1): the flow quits. // later: P1 (no Phase-3 writer before P1).
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
/// Routing: an op only one renderer executes goes to it (`FrameRenderer.swift` refuses the front-end ops,
/// `ScreenRenderer.Refusal.levelOp` the level ops); `setScreenClut(id)` goes to `.level` when `id` is the level's
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
             .changeLightFace, .wrapEraseSprites, .statusBar, .setTile, .wrapDrawWaterEffects, .drawParticles,
             .eraseParticles:
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
public final class LevelRun {
    public let resources: FerazelResources
    public let prefs: FerazelPrefs
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
                skipStageComplete: Bool = false, date: @escaping () -> UInt32 = { 0 }) throws {
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
    }

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
                emit(&out, c.tick(now: now, input: input, fade: &fade))
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
    }

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
            emit(&out, FrontOutput(draws: s.startOps(), requests: [.hideCursor], present: true))
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
                block(StageScreens.stageCompleteEffect(globals: s.globals, level: levelNumber, sounds: sounds), now: now)
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
        let reduce = prefs.reduceFrameRate != 0
        // `.GameLoop`'s bottom-of-loop wait (M l. 5285–5294): prefs[0] = 0 → until 2 ticks after the iteration's start;
        // prefs[0] ≠ 0 → the non-drawing iteration does not wait, the drawing one waits until 4 ticks after its own
        // start. A late tick runs one iteration (or pair): fixed step, no catch-up.
        if let last = lastStart, now &- last < (reduce ? 4 : 2) { return false }
        lastStart = now
        var ops = step(s, input: input, out: &out)
        if reduce && !ops.drawn && !s.loopEnded { ops = step(s, input: input, out: &out) }
        guard s.loopEnded else { return false }
        // The loop is over after this iteration (M l. 5229); its own wait still runs out first.
        playing = false
        exitAt = now &+ UInt32(reduce ? (ops.drawn ? 4 : 0) : 2)
        stages = [.exit]
        return true
    }

    private func step(_ s: FerazelSession, input: FrontInput, out: inout LevelRunOutput) -> FrameOps {
        let ops = s.step(keys: input.keys)
        iterations += 1
        lastSteps.append(ops)
        var o = FrontOutput(draws: ops.draws, sounds: ops.sounds, soundStops: ops.soundStops,
                            soundStopAt: ops.soundStopAt, music: ops.music, requests: ops.requests)
        // A skipped iteration leaves the screen as it was, but its `.HandleAsyncGammaFade` still moves the gamma.
        o.present = ops.drawn || ops.draws.contains { if case .gammaStep = $0 { true } else { false } }
        // `_HandleAsyncAIFFMusicFade()` (M l. 5281), after `.UpdateStatusBar(1, 0, 0)`: nothing armed outside the
        // boss rule's in-loop block (M l. 5257–5266, // later: Phase 5).
        o.music += music.handleAsyncFade(prefs: prefs)
        emit(&out, o)
        return ops
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
            let before = g
            g.fadeOut(steps: 0x30, toward: RGB16(red: 0, green: 0, blue: 0))
            s.world.gammaFade = g
            // `.GammaFadeOutAsync` calls `HideCursorSafe` when it arms (M l. 31905).
            if g != before { emit(&out, FrontOutput(requests: [.hideCursor])) }
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

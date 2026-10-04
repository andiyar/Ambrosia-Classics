// The LOCKED seam types of the playable app (plan 2026-10-04 btx-playable, Shared architecture S2, amended by R1).
// Types only, no behaviour: the simulation fills `SoundCue`s (C2) and `DrawOp`s (C3) into `FrameReport`; `GameSession`
// (C4) and `FrontEnd` (C6) return `SessionOutput`; the renderer (R1) executes `DrawOp`s; the App (A1+) plays cues,
// applies `MusicCue`s and `ShellRequest`s and feeds `HeldKeys` / `KeyModifiers`. Later tasks may ADD cases, never
// rename (S2). `GameMode` (also an R1 seam) already lives in `Sim/SessionConfig.swift` (`gGameMode`).
//
// Foundation-only (Invariant 1): these cross the Core → Render → App boundary as plain values.

/// One `_PlayMySnd @ 00026a7b` call: slot n plays `snd 9000+n` (`gSound[n]`, loaded 9000…9047 by
/// `_LoadSounds @ 00026a20`), at the priority the call site passes (1 / 10 / 20 / 30). Every cue a report or
/// session output carries plays NOW: the core itself runs the 5-slot delayed queue (`_Sounds_CheckDelayedSounds
/// @ 000268a1`, `Sim/Sounds.swift`) and emits a delayed cue in the frame it fires. `delayFrames` is the `delay` the
/// originating `_PlayMySnd` passed — provenance only; the App must never delay a cue again.
public struct SoundCue: Equatable, Sendable {
    /// 0…47 → `snd 9000+slot`.
    public let slot: Int
    public let priority: Int
    public let delayFrames: Int

    public init(slot: Int, priority: Int, delayFrames: Int) {
        self.slot = slot
        self.priority = priority
        self.delayFrames = delayFrames
    }
}

/// What the music voice must do (`_LoadMusic` / `_StartMusic` / `_StopMusic @ 0001afac` / pause …; FI §7).
/// There is no "fade" cue: `_StopMusic`'s fade is a blocking loop (−5 per tick, plan R4), so the session emits one
/// `volume` per tick and then `stopNow`. The App never fades on its own.
public enum MusicCue: Equatable, Sendable {
    /// Load music set `set` (snd 11001…11004).
    case load(set: Int)
    /// `_StartMusic @ 0001ad8c`: set the music voice's volume from prefs short 0x35 (1 → 0, 2 → 0x40, 3 → 0x80,
    /// 4 → 0x100; 0 when the game is not running and bool 0x40 is off) — undoing any earlier `volume` fade — then
    /// queue the set's loop. The App must apply that volume reset on every `start`.
    case start
    case stopNow
    case pause
    case resume
    case unload
    /// The music voice's volume this tick, in the original's 0…0x100 scale (R4).
    case volume(Int)
}

/// The offscreen GWorlds (and the window) a `DrawOp` can draw into (`_SetToBgndGWorld`, `_SetToCompGWorld`,
/// `_SetToScreen`, the 640×40 score GWorld of `_PrepareScoreBar @ 00025c65`). Ops that draw into a buffer name it,
/// because the original's front end deliberately draws into bgnd and leaves it clobbered (Invariant 2).
public enum DrawTarget: Equatable, Sendable {
    case bgnd, comp, screen, score
}

/// One QuickDraw-level call of the original, recorded at the original's call site (Invariant 2). The compositor
/// executes these on persistent bgnd / comp / screen / score buffers exactly as QuickDraw did.
///
/// Sprite addressing (data-formats §4): `set` is the SpIc entry argument `s` of `_SpriteToComp(0, h, v, s, f)` /
/// `_SpriteToBgnd(0, h, v, s, f)` (entry `s − 1`; the leading graphics-set argument is 0 at every call site), and
/// `frame` is the 1-based `f`. `h`/`v` are the top-left in the 640×480 screen.
public enum DrawOp: Equatable, Sendable {
    /// How `.sprite` plots a SpIc frame into comp.
    public enum SpriteMode: Equatable, Sendable {
        /// `_SpriteToComp @ 00015398` — the masked plot (`_PlotCompiledGraphicToComp` / `_ASWPlotCIcon`).
        case normal
        /// `_TransSpriteToComp @ 0001566e` — the translucent plot (`_PlotCompiledTransToComp` /
        /// `_ASWPlotCIconHandle(r, 0, 1, icon)`); SpIc call sites: `_DrawStarsToComp @ 00004de0` and the invisible
        /// hero in `_DrawHeroToComp @ 00022b8b`.
        ///
        /// Not to be confused with `_SpriteToCompTransparent @ 0001518d`, which is a `CopyBits` mode 0x24
        /// (transparent) rect copy from the sprite GWorld with no SpIc addressing; its only caller is
        /// `_DrawLetter @ 0001e3be`, i.e. it belongs to `.string`, not to `.sprite`.
        case transparent
        /// `_SpriteToComp` with `gGhostIcons` set (pause cheat 0x21dd0a7): `_PlotCIconHandle(r, 0, 3, icon)`
        /// (`kTransformOpen`) instead of `_ASWPlotCIcon` — drawn lightened like the disabled transform.
        case ghost
    }

    /// `_DrawMaze @ 00025daa`: PICT `pictID` (LEVL word 1) into bgnd and comp.
    case drawMaze(pictID: Int)
    /// `_RestoreBgnd @ 00015dbe` → `_RestoreBgndRect`: bgnd → `target` over one dirty rect. On OS X (double
    /// buffered) `_PlayGame`'s `_RestoreBgnd(0)` takes the `_BgndToScreen` branch (00015cda) → `target: .screen`;
    /// `.comp` is `_BgndToComp` (the `param_2 != 0` / not-double-buffered branch).
    case restoreBgnd(QDRect, target: DrawTarget = .comp)
    /// `_SpriteToComp` / `_TransSpriteToComp` (see `SpriteMode`), plotted into the CURRENT port: `_PlayGame` on OS X
    /// has `_SetToScreen` in force (00018bac–00018bc8), so its sprites go to `.screen`.
    case sprite(set: Int, frame: Int, h: Int, v: Int, mode: SpriteMode, target: DrawTarget = .comp)
    /// `_SpriteToBgnd @ 00015567`.
    case spriteToBgnd(set: Int, frame: Int, h: Int, v: Int)
    /// `_PrepareScoreBar @ 00025c65`.
    case prepareScoreBar
    /// `_ScoreToComp @ 0001507f`: score GWorld → comp over one rect (`CopyBits` mode 0, srcCopy).
    case scoreToComp(QDRect)
    /// `_CompToScreen @ 00014bfe`: comp → screen over one rect (`_AddRectToScreen @ 0002635a`).
    case compToScreen(QDRect)
    /// `_ScreenToComp @ 00014dda`: screen → comp over one rect (srcCopy) — `_PlayGame`'s conditional copy after
    /// the flush on OS X.
    case screenToComp(QDRect)
    /// `_DrawPicture` of a whole PICT into `dst` of `target` (e.g. `_DrawPictInRect @ 0000bfbc`,
    /// `_DrawAndCentrePict @ 0000bd14`; `_FlashButton @ 000078e0` draws PICT 9100 into **bgnd** at (0,0,300,300)).
    case pict(id: Int, dst: QDRect, target: DrawTarget)
    /// `_BgndToCompTransparent @ 00015028`: copy `src` of the **bgnd buffer as it stands** to `dst` in comp,
    /// transparent. `id` names the PICT the caller drew into bgnd just before (the preceding `.pict(…, target: .bgnd)`
    /// op does the drawing; bgnd stays clobbered afterwards, as in `_FlashButton @ 000078e0`). `target` is the
    /// destination buffer (comp at every known call site).
    case pictSlice(id: Int, src: QDRect, dst: QDRect, target: DrawTarget)
    /// `_DrawCustomString @ 0001e4c0`: the Letters font (PICT 9001, or 9002 when `highlighted`) via `_DrawLetter`.
    /// `h == -1` → the string is centred on 640 (`(640 − width) / 2`). `fixedPitch` nil = each glyph advances by its
    /// own width; 15 = the fixed 15-px pitch (`param_5 != 0`, the high-score number columns — `DC` 24106/24109).
    case string(text: String, h: Int, v: Int, highlighted: Bool, fixedPitch: Int?, target: DrawTarget)
    /// The info text box (`_DrawInterfaceText @ 0000898d`): Geneva 9 centred in `gTextRect`; `colour` is the
    /// original's colour index (0x111 cyan, 0x45 yellow — FI §1b).
    case infoText(String, colour: Int)
    /// A 50 % darkened rect in `target`.
    case darkenRect(QDRect, target: DrawTarget)
    /// A framed rect (`_FrameRect`) in `target`, `rgb` = 0xRRGGBB.
    case frameRect(QDRect, rgb: UInt32, target: DrawTarget)
    /// The whole `target` filled black.
    case fillBlack(target: DrawTarget)
    case patternOverlay(index: Int)
    /// The WHOLE `_WipeScreen @ 000076d3` reveal, blocking: two `step`-row bands copied comp → screen — one starting
    /// at row 0 moving down, one starting at row 480 − `step` moving up — each advancing `step` rows whenever
    /// TickCount has moved on, until `2·step + 240` rows have been swept. The op is recorded once; the session holds a
    /// tick phase (input ignored) while the renderer steps it one advance per tick (its `applyWipe(row)`).
    case wipe(step: Int)
    /// The FPS cheat readout (`_DrawFPS @ 00016f72`).
    case fps(Int)
}

/// A mouse position in the 640×480 logical screen plus the button state, for `FrontEnd` (menu hot rects, Rect 1…7).
public struct MousePoint: Equatable, Sendable {
    public var h: Int
    public var v: Int
    public var button: Bool

    public init(h: Int, v: Int, button: Bool) {
        self.h = h
        self.v = v
        self.button = button
    }
}

/// The keys held this frame, as Mac virtual key codes (S2). Level-sampled: no repeat semantics.
public struct HeldKeys: Equatable, Sendable {
    public var codes: Set<UInt16>
    /// Caps Lock state (the pause key, 0x39 — C4).
    public var capsLock: Bool
    public var command: Bool

    public init(codes: Set<UInt16> = [], capsLock: Bool = false, command: Bool = false) {
        self.codes = codes
        self.capsLock = capsLock
        self.command = command
    }
}

/// Modifier state carried with a key or mouse event (R1: replaces the plan's undefined `ShellModifiersLite`).
public struct KeyModifiers: Equatable, Sendable {
    public var command: Bool
    public var shift: Bool
    public var option: Bool
    public var control: Bool
    public var capsLock: Bool

    public init(command: Bool = false, shift: Bool = false, option: Bool = false, control: Bool = false,
                capsLock: Bool = false) {
        self.command = command
        self.shift = shift
        self.option = option
        self.control = control
        self.capsLock = capsLock
    }
}

/// Something the core asks the App shell to do (S2; C4 / R8 may add cases).
public enum ShellRequest: Equatable, Sendable {
    case hideCursor
    case showCursor
    case enableMenus(Bool)
    case haltAllSound
    case highScoreEntry(rank: Int)
    /// ⌘Q in play: quit at once, no prefs save (R7).
    case quitNow
    case savePrefs
    /// `_SetCursor`: nil = the arrow (`_InitCursor`), 200 = `crsr 200` (the hand, `_PauseGame` — R8).
    case setCursor(id: Int?)
    /// `_PauseGame @ 0001767b` puts the mouse back where it was on exit (R8).
    case restoreMousePosition
    /// `_DisableAboutMenu @ 0000886c` (true) / `_EnableAboutMenu @ 00008850` (false).
    case disableAbout(Bool)
    /// `_SysBeep(1)`.
    case beep
}

/// Why a session ended (C4 / C6 may add cases).
public enum SessionEnd: Equatable, Sendable {
    /// Lives exhausted: FIN! then the game ends 95 frames later.
    case gameOver
    /// Esc ended the game (at once, or after the hold when bool 0x3d is set).
    case escaped
    /// Demo: the level completed (+70 frames).
    case levelCompleted
    /// Demo: the core's own stops fired (FILM samples exhausted, death timeout).
    case demoStopped(Set<StopReason>)
    /// Demo: any key / mouse / activate event.
    case demoInterrupted
    /// The original would quit the application here (`_CleanUp` / `_LocationError` / `ExitToShell` — a level or maze
    /// that fails to load, `StopReason.originalWouldAbort`). Added by C4.
    case originalWouldQuit(String)
    /// ⌘Q in play (`_PlayGame` 00018eb0: `_StopMusic` then `_CleanUp` — quit, no prefs save, R7). Added by C4.
    case quit
}

/// Everything one `GameSession.frame` / `.tick` or `FrontEnd` call hands the App (S2).
///
/// Order of application: the App applies `requests` BEFORE `sounds` (so a `.haltAllSound` never cuts this output's own
/// cues). Producers keep that true: when an output carries `.haltAllSound`, any cue the original played before the
/// halt in the same instant is dropped from `sounds` (it would have been cut at once) — e.g. pause entry = halt →
/// snd 22, game exit = halt → snd 27.
public struct SessionOutput: Equatable, Sendable {
    public var sounds: [SoundCue]
    public var music: [MusicCue]
    public var drawOps: [DrawOp]
    public var requests: [ShellRequest]
    public var ended: SessionEnd?

    public init(sounds: [SoundCue] = [], music: [MusicCue] = [], drawOps: [DrawOp] = [],
                requests: [ShellRequest] = [], ended: SessionEnd? = nil) {
        self.sounds = sounds
        self.music = music
        self.drawOps = drawOps
        self.requests = requests
        self.ended = ended
    }
}

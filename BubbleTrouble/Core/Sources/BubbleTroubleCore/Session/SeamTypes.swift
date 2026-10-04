// The LOCKED seam types of the playable app (plan 2026-10-04 btx-playable, Shared architecture S2, amended by R1).
// Types only, no behaviour: the simulation fills `SoundCue`s (C2) and `DrawOp`s (C3) into `FrameReport`; `GameSession`
// (C4) and `FrontEnd` (C6) return `SessionOutput`; the renderer (R1) executes `DrawOp`s; the App (A1+) plays cues,
// applies `MusicCue`s and `ShellRequest`s and feeds `HeldKeys` / `KeyModifiers`. Later tasks may ADD cases, never
// rename (S2). `GameMode` (also an R1 seam) already lives in `Sim/SessionConfig.swift` (`gGameMode`).
//
// Foundation-only (Invariant 1): these cross the Core → Render → App boundary as plain values.

/// One `_PlayMySnd @ 00026a7b` call: slot n plays `snd 9000+n` (`gSound[n]`, loaded 9000…9047 by
/// `_LoadSounds @ 00026a20`), at the priority the call site passes (10 / 20 / 30). `delayFrames > 0` is the
/// 5-slot delayed queue flushed by `_Sounds_CheckDelayedSounds @ 000268a1` (C2).
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
/// The App never fades on its own: a fade arrives as one `volume` per tick (plan R4: `_StopMusic` −5 per tick).
public enum MusicCue: Equatable, Sendable {
    /// Load music set `set` (snd 11001…11004).
    case load(set: Int)
    case start
    case stopFade
    case stopNow
    case pause
    case resume
    case unload
    /// The music voice's volume this tick, in the original's 0…0x100 scale (R4).
    case volume(Int)
}

/// One QuickDraw-level call of the original, recorded at the original's call site (Invariant 2). The compositor
/// executes these on persistent bgnd / comp / screen buffers exactly as QuickDraw did.
///
/// Sprite addressing (data-formats §4): `set` is the SpIc entry argument `s` of `_SpriteToComp(0, h, v, s, f)` /
/// `_SpriteToBgnd(0, h, v, s, f)` (entry `s − 1`; the leading graphics-set argument is 0 at every call site), and
/// `frame` is the 1-based `f`. `h`/`v` are the top-left in the 640×480 screen.
public enum DrawOp: Equatable, Sendable {
    /// How `.sprite` plots into comp.
    public enum SpriteMode: Equatable, Sendable {
        /// `_SpriteToComp @ 00015398` — mask-keyed copy.
        case normal
        /// `_SpriteToCompTransparent @ 0001518d` — the blended plot.
        case transparent
    }

    /// `_DrawMaze @ 00025daa`: PICT `pictID` (LEVL word 1) into bgnd and comp.
    case drawMaze(pictID: Int)
    /// `_RestoreBgnd @ 00015dbe`: bgnd → comp over one dirty rect.
    case restoreBgnd(QDRect)
    /// `_SpriteToComp` / `_SpriteToCompTransparent`.
    case sprite(set: Int, frame: Int, h: Int, v: Int, mode: SpriteMode)
    /// `_SpriteToBgnd @ 00015567`.
    case spriteToBgnd(set: Int, frame: Int, h: Int, v: Int)
    /// `_PrepareScoreBar @ 00025c65`.
    case prepareScoreBar
    /// `_CompToScreen @ 00014bfe`: comp → screen over one rect (`_AddRectToScreen @ 0002635a`).
    case compToScreen(QDRect)
    /// A whole PICT drawn into `dst`.
    case pict(id: Int, dst: QDRect)
    /// `_BgndToCompTransparent @ 00015028`: the `src` slice of a PICT into `dst`.
    case pictSlice(id: Int, src: QDRect, dst: QDRect)
    /// `_DrawCustomString @ 0001e4c0`: the Letters font (PICT 9001, or 9002 when `highlighted`).
    case string(text: String, h: Int, v: Int, highlighted: Bool)
    /// The info text box (`_DrawInterfaceText @ 0000898d`): Geneva 9 centred in `gTextRect`; `colour` is the
    /// original's colour index (0x111 cyan, 0x45 yellow — FI §1b).
    case infoText(String, colour: Int)
    /// A 50 % darkened rect.
    case darkenRect(QDRect)
    /// A framed rect, `rgb` = 0xRRGGBB.
    case frameRect(QDRect, rgb: UInt32)
    case fillBlack
    case patternOverlay(index: Int)
    /// One step of the level-start wipe.
    case wipe(step: Int)
    /// The FPS cheat readout (`_DrawFPS @ 00016f72`).
    case fps(Int)
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
}

/// Everything one `GameSession.frame` / `.tick` or `FrontEnd` call hands the App (S2).
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

import FerazelCore
import FerazelRender
import Foundation

/// The hidden switches, for one launch (Ruling 11, 20): `-FerazelLevel N`, `-ColorTieBreak lowest`, `-MacGamma YES`,
/// `-FerazelMute YES` (or `FERAZEL_MUTE=1` in the environment). Read with the Mac's `UserDefaults` semantics: the Mac's
/// lookup is `UserDefaults.standard` itself; Windows' is `arguments(_:)` over the command line's strings, which reads a
/// string as the Mac's argument domain does (measured, WF1).
struct FerazelSettings: Equatable {
    /// The hidden defaults key for the starting level (Ben D33, D35 kept as a hidden test path): `-FerazelLevel 2` on
    /// the command line makes New Game start at level 2 for one launch (`GameFlow.startLevel`); absent or outside
    /// `BuiltLevels.range` (1…5) → level 1, "A Scent Of Peril".
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
    /// The mute switch (D42, Ruling 20): no audio output is opened and the system beeps are suppressed.
    static let muteKey = "FerazelMute"
    static let muteEnvironment = "FERAZEL_MUTE"

    var startLevel = 1
    var tieBreak = ColorSearch.TieBreak.highest
    var macGamma = false
    var mute = false

    /// The three typed reads `UserDefaults` offers for a key (absent → 0, nil, false).
    struct Lookup {
        var integer: (String) -> Int
        var string: (String) -> String?
        var bool: (String) -> Bool
    }

    /// The switches from `lookup` and `environment`. `FerazelLevel` (Ben D33): 1 when absent or outside
    /// `BuiltLevels.range` (1…5 since Phase 5 LV5).
    static func parse(lookup: Lookup, environment: [String: String]) -> FerazelSettings {
        var s = FerazelSettings()
        let n = lookup.integer(levelKey)
        s.startLevel = BuiltLevels.range.contains(n) ? n : 1
        s.tieBreak = lookup.string(tieBreakKey) == "lowest" ? .lowest : .highest
        s.macGamma = lookup.bool(macGammaKey)
        s.mute = lookup.bool(muteKey) || environment[muteEnvironment] == "1"
        return s
    }

    /// The argument domain's reads over `-Key value` strings, as measured on the Mac (WF1, 2026-10-26): `bool` is true
    /// for "yes" / "true" in any case and the exact "1", false for everything else ("y", "t", "2", "01", " YES");
    /// `integer` reads the whole string as an optionally signed decimal after leading white space — anything else
    /// ("2abc", "1.9", "1 ", "0x10", "") is 0 — clamped to Int32; `string` is the value itself.
    static func arguments(_ values: [String: String]) -> Lookup {
        Lookup(integer: { key in values[key].map(argumentInteger) ?? 0 },
               string: { key in values[key] },
               bool: { key in values[key].map(argumentBool) ?? false })
    }

    static func argumentBool(_ s: String) -> Bool {
        let lower = s.lowercased()
        return lower == "yes" || lower == "true" || s == "1"
    }

    static func argumentInteger(_ s: String) -> Int {
        var scalars = Substring(s).unicodeScalars[...]
        while let c = scalars.first, c.properties.isWhitespace { scalars = scalars.dropFirst() }
        var negative = false
        if let c = scalars.first, c == "+" || c == "-" {
            negative = c == "-"
            scalars = scalars.dropFirst()
        }
        guard !scalars.isEmpty else { return 0 }
        var value = 0
        for c in scalars {
            guard ("0"..."9").contains(c) else { return 0 }
            value = min(value * 10 + Int(c.value - 48), Int(Int32.max) + 1)
        }
        return negative ? max(-value, Int(Int32.min)) : min(value, Int(Int32.max))
    }
}

/// The platform-neutral half of the shell (Phase W, WF1, Ruling 1; moved from the Mac's `FerazelController` with the
/// same order and results): the boot (resources, the colour search, the shared `ScreenSurface`, the renderers, the
/// prefs, the seed, `GameFlow`), one game tick (the flow's tick, the new level run's set-up, the segments routed to
/// their renderers, the sounds and music, the prefs to the renderers), the boot's two loads, the present (the Mac's
/// ARGB words or RGBA bytes, MacGamma through the palette), the dialogs' pictures and the `LevelServices`. The shell
/// injects what is its own: the text renderer, the seed, `KeyTranslate`, `GetDateTime`, the mixer, the beep, the log.
/// Compiled by the Mac app (`Ferazel/Shared`) and by `FerazelWinKit` (a symlink). Foundation + FerazelCore/Render only.
@MainActor final class FerazelDriver {
    static let width = IndexedFrame.width
    static let height = IndexedFrame.height
    /// The Let's Play measured ≈ 0.76 (colour-measurement-2026-10-10 Q2); the toggle uses the display ratio 1.8/2.2.
    static let macGammaExponent = 1.8 / 2.2
    /// v' = 255·(v/255)^(1.8/2.2), rounded, per 8-bit channel; applied to the 256-entry palette, not per pixel.
    static let macGammaLUT: [UInt8] = (0...255).map { v in
        UInt8((255 * pow(Double(v) / 255, macGammaExponent)).rounded())
    }
    /// The screen's CLUT before the game sets one: `SwitchTo8BitColorMT` leaves the system's 8-bit table, which the
    /// game's clut 801 "System CLUT" holds (PICT 131, the logo, is drawn under it, M l. 8277–8281).
    static let systemClut: Int16 = 0x321

    let settings: FerazelSettings
    private(set) var flow: GameFlow!
    private(set) var resources: FerazelResources!
    private(set) var search: ColorSearch!
    private(set) var surface: ScreenSurface!
    /// The front end's executor (`.frontEnd` chain): the boot, menu, stage, death screens; the map's screen ops.
    private var frontScreen: ScreenRenderer!
    /// A level's `.screen` segments before its renderer exists (the popup), on the level chain.
    private var levelScreen: ScreenRenderer!
    private var mapRenderer: MapRenderer!
    /// The running level's renderer and its conversation renderer (`LevelServices.prepare`); the last level's stay
    /// until the next is prepared.
    private(set) var levelRenderer: FrameRenderer?
    private(set) var conversationRenderer: ConversationRenderer?
    /// The `LevelRun` that was running when `conversationRenderer` was built (`prepare`).
    private weak var conversationRun: LevelRun?
    private let rasterizer: TextRasterizer
    /// The conversation text's measures (C1/C2: the 214-px wrap and the typing timeline need real widths).
    private(set) var conversationText = ConversationText.unmeasured
    /// The `LevelRun` last given `conversationText` (held, so a new run is never mistaken for it).
    private var configuredRun: LevelRun?
    private(set) var audio: FerazelAudio?
    /// The headless frames mode's mixer (`headless`): no device, drained once per game tick (Ruling 20).
    private(set) var silentMixer: FerazelSilentMixer?
    /// The headless `--frames` mode (Ruling 20): the silent mixer, never the factory — muted or not.
    let headless: Bool
    /// The boot's two App loads, done (`GameFlow.LoadPhase`).
    private var loadedPhases: Set<GameFlow.LoadPhase> = []

    private let files: FrontFiles
    private let seed: () -> Int32
    private let keyCharacter: @Sendable (Int16) -> String?
    private let dateTime: @Sendable () -> UInt32
    private let makeMixer: () -> FerazelMixer?
    private let beeper: () -> Void
    private let log: (String) -> Void

    /// - Parameters:
    ///   - text: `DrawString` / `CharWidth` / `GetFontInfo` (the Mac's `CoreTextRasterizer`; Windows' baked fonts).
    ///   - files: the prefs file and saved games (`FrontFiles`).
    ///   - seed: `.InitAppGlobals`' `FastRand(0)` seed, read once at the flow's creation (the Mac: Time + Ticks).
    ///   - keyCharacter: `KeyTranslate`, for the Options dialog's key names.
    ///   - dateTime: `GetDateTime`.
    ///   - mixer: the audio output, called at most once (at boot) and never when `settings.mute` or `headless`.
    ///   - beeper: `SysBeep`, never called when `settings.mute`.
    ///   - log: a failure the game survives (the Mac: `NSLog("Ferazel's Wand: %@", …)`).
    ///   - headless: the `--frames` dumps (Ruling 20): no audio device at all; the Sound Tool is drained by a
    ///     `FerazelSilentMixer` once per tick so `playing` follows the sounds, whatever `settings.mute` says (mute
    ///     governs the real output and the beeps only).
    init(settings: FerazelSettings, text: TextRasterizer, files: FrontFiles, seed: @escaping () -> Int32,
         keyCharacter: @escaping @Sendable (Int16) -> String?, dateTime: @escaping @Sendable () -> UInt32,
         mixer: @escaping () -> FerazelMixer?, beeper: @escaping () -> Void, log: @escaping (String) -> Void,
         headless: Bool = false) {
        self.settings = settings
        rasterizer = text
        self.files = files
        self.seed = seed
        self.keyCharacter = keyCharacter
        self.dateTime = dateTime
        makeMixer = mixer
        self.headless = headless
        self.beeper = beeper
        self.log = log
    }

    // MARK: Boot

    /// The launch's game half, in the original order: the data, the colour search (`.exactNearest`, D26 LP measurement
    /// 2026-10-10, Ben), the shared surface under the system CLUT, the renderers, the conversation measures, the audio,
    /// the prefs, the seed and the flow. A throw is the shell's to report (the Mac terminates).
    func boot(dataDirectory: URL) throws {
        let resources = try FerazelData.open(dataDirectory)
        self.resources = resources
        search = ColorSearch(model: .exactNearest, tieBreak: settings.tieBreak)  // D26 LP measurement 2026-10-10 (Ben)
        surface = ScreenSurface(clut: try ColorLUT.load(id: Self.systemClut, from: resources, chain: .frontEnd))
        frontScreen = ScreenRenderer(surface: surface, resources: resources, search: search, dither: .errorDiffusion,
                                     text: rasterizer, chain: .frontEnd)
        levelScreen = ScreenRenderer(surface: surface, resources: resources, search: search, dither: .errorDiffusion,
                                     text: rasterizer, chain: .level)
        mapRenderer = MapRenderer(screen: frontScreen)
        conversationText = TextLayout.conversationText(rasterizer)
        // Headless (Ruling 20): the silent mixer, no device, whatever the mute. Mute (D42): no audio output is opened
        // at all — `FerazelAudio` runs silent with no mixer.
        let mixer: FerazelMixer?
        if headless {
            let silent = FerazelSilentMixer()
            silentMixer = silent
            mixer = silent
        } else {
            mixer = settings.mute ? nil : makeMixer()
        }
        audio = FerazelAudio(mixer: mixer, musicDirectory: resources.musicDirectory, log: log)
        // `.SetPrefFile` + `.InitPrefs` (M l. 8192–8243): the stored record, else the defaults, written at once.
        let prefs: FerazelPrefs
        if let record = files.loadPrefs() {
            prefs = FerazelPrefs(record: record)
        } else {
            prefs = FerazelPrefs()
            do { try files.storePrefs(prefs.record()) } catch {
                log("prefs file: \(error)")
            }
        }
        // `.InitAppGlobals`' `_FastRand(0)` (M l. 334; `LMGetTime` + `LMGetTicks`, M l. 31295–31298): the stream is
        // seeded once from Time + Ticks and never again (the shell's `seed`).
        // The flow and its runs reach this driver through `LevelServicesLink` (weak), never directly: the driver owns
        // the flow, so a strong back-reference would keep a dropped game alive (2026-11-10).
        // WARNING: the driver itself still conforms to `LevelServices` (FerazelDriverTests drives it directly), so
        // `levels: self` here would compile — and bring back the leak that kept every dropped game alive (~70 MB a
        // visit on the Windows-path sweep; with four workers it grew to tens of GB and panicked the Mac twice). Always
        // hand the flow `LevelServicesLink(driver: self)`; WinGameReleaseTests fails if a dropped game is not freed.
        let flow = GameFlow(resources: resources, prefs: prefs, seed: seed(), files: files,
                            levels: LevelServicesLink(driver: self))
        flow.startLevel = settings.startLevel
        // `KeyTranslate` (the Options key names): the flow calls it on the main thread (its ticks, the dialog).
        flow.keyCharacter = keyCharacter
        flow.dateTime = dateTime   // `GetDateTime`
        self.flow = flow
    }

    // MARK: Tick

    /// One game tick: the flow runs once with `input`; a run created inside this tick is set up (and the last level's
    /// conversation renderer dropped) before the tick's segments are routed — its first popup draws go to
    /// `levelScreen`; then the sounds and music cues, and the prefs to the renderers. A draw failure throws before the
    /// audio (the shell reports it). The shell then presents when `present`, honours the requests, and calls
    /// `serviceLoad()`.
    func tick(now: UInt32, input: FrontInput) throws -> FrontOutput {
        let out = flow.tick(now: now, input: input)
        configureLevelRun()
        try draw(flow.segments)
        audio?.apply(sounds: out.sounds, stops: out.soundStops, stopAt: out.soundStopAt)
        for cue in out.music { audio?.handle(cue) }
        silentMixer?.tick()
        if let p = out.prefs {
            // `.MakeCurrPrefs` (⌘P, the pause's ⌘M / ⌘F, a save): the live record the renderers read per copy —
            // `FrameRenderer`'s parallax (prefs+4, every `copyToScreen`), the conversation's `restoreView`.
            levelRenderer?.prefs = p
            conversationRenderer?.prefs = p
        }
        return out
    }

    /// VS: the `snd ` ids the Sound Tool is playing now (`FrontInput.playing`); empty with no Sound Tool.
    func playingSounds() -> Set<Int16> { audio?.playingSounds() ?? [] }

    /// A music cue outside the tick (the Options dialog's Music checkbox and popup act at once).
    func handle(_ cue: MusicCue) { audio?.handle(cue) }

    /// Silences the music and every effect (on quit).
    func stopAudio() { audio?.stopAll() }

    /// `SysBeep` through the shell, unless muted (Ruling 20).
    func beep() {
        guard !settings.mute else { return }
        beeper()
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

    // MARK: The boot's loads

    /// The boot's App loads (`GameFlow.state` `.loading`): the sound effects under the logo (`.InitSounds` +
    /// `.InitAppGlobals`), the faces under the loading screen (`.InitSprites`' `.InitMapFaces` — the only faces the
    /// App keeps from boot; a level's faces load with its renderer).
    func serviceLoad() {
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
            log("sounds: \(error)")   // the game runs without effects
        }
    }

    /// The map faces (`.InitMapFaces`, clut 700): one `loadProgress` per face (`.Update3DProgBar`).
    private func loadFaces() {
        var n = 0
        for (set, count) in [(FrontFaceSet.mapMarker, 1), (.mapNode, 8), (.mapBoss, 8), (.mapAmbient, 8)] {
            for i in 0..<count {
                do { _ = try mapRenderer.face(set, i) } catch {
                    log("map face \(Int(set.pict))/\(i): \(error)")
                }
                n += 1
                flow.loadProgress(faces: n)
            }
        }
    }

    // MARK: Present

    /// The shared screen's presented CLUT (the screen CLUT through `ScreenGamma`) as 8-bit (r, g, b), each channel then
    /// through `macGammaLUT` with `MacGamma` on.
    private func palette(_ clut: ColorLUT) -> [(UInt8, UInt8, UInt8)] {
        let lut = settings.macGamma ? Self.macGammaLUT : nil
        return clut.entries.map { e in
            var (r, g, b) = (Int(e.red >> 8), Int(e.green >> 8), Int(e.blue >> 8))
            if let lut { (r, g, b) = (Int(lut[r]), Int(lut[g]), Int(lut[b])) }
            return (UInt8(r), UInt8(g), UInt8(b))
        }
    }

    /// The Mac's present: the shared screen through its presented CLUT (then MacGamma), written straight into `out`
    /// (640 × 480 words, 0xAARRGGBB — the `IndexedFrame.rgba(through:)` mapping, without allocating a word array per
    /// frame).
    func presentARGB(into out: UnsafeMutablePointer<UInt32>) {
        let table = palette(surface.presentedClut).map { c -> UInt32 in
            0xff00_0000 | UInt32(c.0) << 16 | UInt32(c.1) << 8 | UInt32(c.2)
        }
        surface.frame.pixels.withUnsafeBufferPointer { src in
            for i in 0..<min(src.count, Self.width * Self.height) { out[i] = table[Int(src[i])] }
        }
    }

    /// The same frame as R, G, B, A bytes (A = 0xff), 640 × 480 × 4 — what `SDLHost.present(rgba:)` takes.
    func presentRGBA() -> [UInt8] {
        let table = palette(surface.presentedClut)
        var bytes = [UInt8](repeating: 0xff, count: Self.width * Self.height * 4)
        surface.frame.pixels.withUnsafeBufferPointer { src in
            for i in 0..<min(src.count, Self.width * Self.height) {
                let c = table[Int(src[i])]
                (bytes[4 * i], bytes[4 * i + 1], bytes[4 * i + 2]) = c
            }
        }
        return bytes
    }

    /// A `PICT` as QuickDraw drew it into a dialog window: converted under the screen's current CLUT (`ColorSearch`,
    /// the screen's inverse table), shown through it (and MacGamma when on) — R, G, B, 0xff bytes; nil when the
    /// picture does not load or is empty.
    func dialogPicture(_ id: Int16) -> (rgba: [UInt8], width: Int, height: Int)? {
        guard let source = try? PictureSource.load(id: id, from: resources, chain: .frontEnd),
              let picture = try? ConvertedPicture(source: source, clut: surface.clut, search: search) else { return nil }
        let table = palette(surface.clut)
        var bytes = [UInt8](repeating: 0xff, count: picture.width * picture.height * 4)
        for (i, v) in picture.pixels.enumerated() where Int(v) < table.count {
            let c = table[Int(v)]
            (bytes[4 * i], bytes[4 * i + 1], bytes[4 * i + 2]) = c
        }
        guard picture.width > 0, picture.height > 0 else { return nil }
        return (bytes, picture.width, picture.height)
    }
}

// MARK: - LevelServices

/// The renderer side of a level (plan S2 `LevelServices`, L1; today's `openLevel` order): the level's `FrameRenderer`
/// on the shared surface (it leaves the surface's CLUT alone until the level's `setScreenClut`, FE0 — `.SetupLevel`'s
/// tail draws it before the loop, so the death wipe always paints under the level CLUT), then its lights and tint
/// table from the session.
///
/// WARNING: this conformance is for `LevelServicesLink` (which forwards here) and for FerazelDriverTests, which calls
/// the three methods on the driver directly. Never hand the driver itself to `GameFlow(…, levels:)` or a `LevelRun`:
/// the driver owns the flow and the flow owns its runs, so a run or flow holding the driver strongly is a cycle that
/// keeps every dropped game alive — the leak behind the Windows-path sweep's kernel panics (2026-11-08, 2026-11-10).
/// Hand them `LevelServicesLink(driver:)`, which holds the driver weakly.
extension FerazelDriver: @MainActor LevelServices {
    func prepare(level: Int) throws -> LevelFaces {
        let r = try FrameRenderer(resources: resources, level: level, search: search, dither: .errorDiffusion,
                                  text: rasterizer, prefs: flow.toggles.live, surface: surface)
        levelRenderer = r
        conversationRenderer = ConversationRenderer(frame: r, text: rasterizer, prefs: flow.toggles.live)
        conversationRun = flow.levelRun
        return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces, diffuseRandoms: r.diffuseRandoms,
                          diffuseRandomsAt: r.diffuseRandomsAt)
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

/// The `LevelServices` the driver hands `GameFlow` (2026-11-10): each call forwarded to the driver, held **weakly**.
/// The driver owns the flow (`flow`), the flow its `LevelRun` (`levelRun`), and the driver the run it configured
/// (`configuredRun`); the flow (`levels`) and every run (`services`) hold their `LevelServices` strongly — so with the
/// driver itself there, a game the shell let go of was never freed (~70 MB a game on the Windows-path visit sweep,
/// which builds one per visit; the Mac panics of 2026-11-08 and 2026-11-10). With this link nothing below the driver
/// holds it. Both shells hold their driver for as long as they use its flow, so the driver is there for every call;
/// were it gone, the call throws.
@MainActor final class LevelServicesLink: @MainActor LevelServices {
    /// The driver was freed while its flow still ran (never in a shell: each holds its driver while the game runs).
    struct DriverReleased: Error {}

    private weak var driver: FerazelDriver?

    init(driver: FerazelDriver) { self.driver = driver }

    private func live() throws -> FerazelDriver {
        guard let driver else { throw DriverReleased() }
        return driver
    }

    func prepare(level: Int) throws -> LevelFaces { try live().prepare(level: level) }

    func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
        try live().attach(lights: lights, tintTableDraws: tintTableDraws)
    }

    func deathEffectStep(_ k: Int) throws { try live().deathEffectStep(k) }
}

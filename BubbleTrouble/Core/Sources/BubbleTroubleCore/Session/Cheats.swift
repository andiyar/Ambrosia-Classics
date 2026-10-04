// Pause-screen cheats (plan 2026-10-04 btx-playable C8; FI §3h), transcribed from `_PauseGame @ 0001767b` — its event
// kind 3 (key-down) case, 000178df…0001801f — and from `_PlayGame @ 00018247` for the flags the cheats set:
// `_gLimitFrames = 1`, `_gDaddyMode = 0`, `_gGhostIcons = 0`, `_SetHacked(0)` at entry (000182a3…000182bf), the
// frame-limit wait (00018f5d…00019122) and the FPS readout (00019129…0001916a).
//
// Sound sites (slot, priority, delay) — every `_PlayMySnd` of the kind-3 case, in `Cheats.Effect.steps`:
//   0001794c (0,30,0) FPS · 00017992 (3,30,0) score reset · 000179db (i,30,0) i = 0…47 + `_Delay(10)` · 00017a24
//   (47,30,0) daddy · 00017a63 (0,30,0) star burst · 00017acc→00017cfb (46,30,0) · 00017af6 (41,30,0) frame limit ·
//   00017b3b (0,30,0) ×3 + `_Delay(20)` · 00017b7d/00017b99/00017bb5 (31,20,0) (4,20,0) (15,10,0) regenerate ·
//   00017be9 (0,30,0) + 00017c19 (35,30,0) end level · 00017c48 (41,20,0) ghost icons · 00017c89/00017cb8/00017ce4
//   (47,30,0) with `_Delay(25)` between · 00017d13 (0,30,0) +1 life · 00017d56 (0,30,0) +9000 · 00017d96 (0,30,0)
//   invisibility · 00017dce (0,30,0) capture all · 00017e0a/00017e50/00017e90/00017ee6/00017f1b (0,30,0) EXTRA ·
//   00017f53/00017f80/00017fb5/00017fef (0,30,0) multiplier. Callee cues (`_AddHero` 13 ×2, `_Balloons_Capture…`
//   15, …) come from the simulation in call order after the site's own.

/// The pause-screen cheat codes: the five-character buffer, its hash, and what each matching hash does.
public enum Cheats {
    /// `builtin_strncpy(local_2b, "OOGLE", 6)` at every `_PauseGame` entry.
    public static let bufferSeed: [UInt8] = Array("OOGLE".utf8)

    /// 00017908…0001793d: `(c0+0x19a)(c1+0x6a)(c2+0x14d) + 3 + (c3+0x118)(c4+0x230)` over the buffer after the new
    /// character is shifted in. Each byte is sign-extended (`movsbl`, so a Mac Roman high character is negative);
    /// the products are 32-bit `imull` and the sum a `leal` — wrapping `Int32` arithmetic (no byte value overflows).
    public static func hash(_ buffer: [UInt8]) -> Int32 {
        precondition(buffer.count == 5, "the cheat buffer is five characters")
        func c(_ i: Int) -> Int32 { Int32(Int8(bitPattern: buffer[i])) }
        let a = (c(0) &+ 0x19a) &* (c(1) &+ 0x6a) &* (c(2) &+ 0x14d)
        return a &+ 3 &+ (c(3) &+ 0x118) &* (c(4) &+ 0x230)
    }

    /// What a matching hash does. Names follow the effect, not the (unpublished) typed code.
    public enum Effect: Equatable, Sendable {
        /// 0x227742c: toggle `_gShowFPS`.
        case toggleFPS
        /// 0x20ec7c5: `_ResetScore(0)`.
        case resetScore
        /// 0x242795e: every sound 0…47, `_Delay(10)` after each.
        case playAllSounds
        /// 0x22a51cf: `_gDaddyMode = 1` (15 fps — only on the non-OS X TickCount path, so a flag only here).
        case daddyMode
        /// 0x211e290: `_NewStarGroup(hero col·40, hero row·40, 10)` — the orbit stars (never drawn on Intel).
        case starBurst
        /// 0x239b951: snd 46 "Non the dog" once (absent from FI §3h's list).
        case dogBark
        /// 0x249007e: toggle `_gLimitFrames`.
        case toggleFrameLimit
        /// 0x20df815: snd 0 three times, `_Delay(20)` after each.
        case threeSquishes
        /// 0x224fc15: `_RegenerateBlocks`.
        case regenerateBubbles
        /// 0x21d95f1: `gEndOfLevelTime = gFrameCounter; gIsEndOfLevel = 1`.
        case endLevel
        /// 0x21dd0a7: toggle `_gGhostIcons`.
        case toggleGhostIcons
        /// 0x22badb8: snd 47 three times, `_Delay(25)` between.
        case threeSqueaks
        /// 0x252bb8b: `_AddHero(1, 1)`.
        case extraLife
        /// 0x21ba771: `_AddToScore(9000, 0)` (not multiplied).
        case addScore9000
        /// 0x23ba91e: `_SetHeroInvisibility(1)`.
        case invisibility
        /// 0x20a59aa: `_Balloons_CaptureAllEnemies`.
        case captureAll
        /// 0x26e29e4 / 0x26e4547 / 0x26e3f83 / 0x26e3ca1 / 0x26e2420: `_EXTRA_Change(1…5, 0)`.
        case extraLetter(Int)
        /// 0x232858f / 0x23286f2 / 0x2328855 / 0x23289b8: `_Multiplier_Change(2…5)`.
        case multiplier(Int16)

        /// Sets `gPlayerIsCheating` (no high score): the paths through 00017def, and the EXTRA / multiplier sites.
        public var setsPlayerIsCheating: Bool {
            switch self {
            case .daddyMode, .regenerateBubbles, .endLevel, .extraLife, .addScore9000, .invisibility, .captureAll,
                 .extraLetter, .multiplier:
                return true
            case .toggleFPS, .resetScore, .playAllSounds, .starBurst, .dogBark, .toggleFrameLimit, .threeSquishes,
                 .toggleGhostIcons, .threeSqueaks:
                return false
            }
        }

        /// The site's own calls in order: its `_PlayMySnd`s, `_Delay`s (ticks) and the effect itself.
        var steps: [CheatStep] {
            func snd(_ slot: Int, _ priority: Int = 0x1e) -> CheatStep {
                .sound(SoundCue(slot: slot, priority: priority, delayFrames: 0))
            }
            let fx = CheatStep.apply(self)
            switch self {
            case .toggleFPS, .starBurst, .extraLife, .addScore9000, .invisibility, .captureAll, .extraLetter,
                 .multiplier:
                return [snd(0), fx]
            case .resetScore: return [snd(3), fx]
            case .playAllSounds: return (0..<0x30).flatMap { [snd($0), CheatStep.delay(10)] }
            case .daddyMode: return [snd(0x2f), fx]
            case .dogBark: return [snd(0x2e)]
            case .toggleFrameLimit: return [snd(0x29), fx]
            case .threeSquishes: return (0..<3).flatMap { _ in [snd(0), CheatStep.delay(0x14)] }
            case .regenerateBubbles: return [snd(0x1f, 0x14), snd(4, 0x14), snd(0xf, 10), fx]
            case .endLevel: return [snd(0), fx, snd(0x23)]
            case .toggleGhostIcons: return [snd(0x29, 0x14), fx]
            case .threeSqueaks: return [snd(0x2f), .delay(0x19), snd(0x2f), .delay(0x19), snd(0x2f)]
            }
        }
    }

    /// The constants of the compare chain at 00017944…00017fe9.
    public static let table: [Int32: Effect] = [
        0x227742c: .toggleFPS, 0x20ec7c5: .resetScore, 0x242795e: .playAllSounds, 0x22a51cf: .daddyMode,
        0x211e290: .starBurst, 0x239b951: .dogBark, 0x249007e: .toggleFrameLimit, 0x20df815: .threeSquishes,
        0x224fc15: .regenerateBubbles, 0x21d95f1: .endLevel, 0x21dd0a7: .toggleGhostIcons, 0x22badb8: .threeSqueaks,
        0x252bb8b: .extraLife, 0x21ba771: .addScore9000, 0x23ba91e: .invisibility, 0x20a59aa: .captureAll,
        0x26e29e4: .extraLetter(1), 0x26e4547: .extraLetter(2), 0x26e3f83: .extraLetter(3), 0x26e3ca1: .extraLetter(4),
        0x26e2420: .extraLetter(5),
        0x232858f: .multiplier(2), 0x23286f2: .multiplier(3), 0x2328855: .multiplier(4), 0x23289b8: .multiplier(5),
    ]

    /// 00017e85: the chain's last compare before `_SetHacked(1)` at 00017ec8. Every other hash — cheat or not —
    /// reaches that call (the compiler's tail merge), so any key typed while paused sets gHacked except this value,
    /// which does nothing. gHacked itself is read by nothing (`_IsHacked @ 000105b0` has no caller).
    public static let noHackHash: Int32 = 0x5792ca4

    public static func effect(forHash h: Int32) -> Effect? { table[h] }
}

/// One step of a cheat site, run by the pause loop: `_Delay` blocks `_PauseGame` (events wait in the queue).
enum CheatStep: Equatable, Sendable {
    case sound(SoundCue)
    case delay(UInt32)
    case apply(Cheats.Effect)
}

/// The cheat flags of one `_PlayGame` run (and gShowFPS, which outlives it).
struct CheatFlags {
    /// gHacked (`_SetHacked(0)` at `_PlayGame` entry).
    var hacked = false
    /// `_gDaddyMode` (0 at `_PlayGame` entry).
    var daddyMode = false
    /// `_gLimitFrames` (1 at `_PlayGame` entry).
    var limitFrames = true
    /// `_gShowFPS` — never reset by `_PlayGame`.
    var showFPS = false
    /// `local_e2`: frames counted since the last `_DrawFPS` (0x1e at `_PlayGame` entry).
    var fpsFrames: Int16 = 0x1e
    /// `local_e8`: TickCount at the last `_DrawFPS` (TickCount at `_PlayGame` entry — the first tick seen).
    var fpsLastTick: UInt32?
    /// The loop iteration that entered `_PauseGame` still owes its FPS check (it runs after the pause).
    var fpsDeferred = false
    /// The latest TickCount the shell gave the session.
    var now: UInt32 = 0
}

extension GameSession {
    // MARK: Cheat state (public reads)

    /// gHacked: set by any key typed while paused (see `Cheats.noHackHash`). Read by nothing in the original.
    public var hacked: Bool { cheats.hacked }
    /// `_gDaddyMode`: the 15 fps wait exists only on the non-OS X path, so this is a flag with no effect.
    public var daddyMode: Bool { cheats.daddyMode }
    /// `_gLimitFrames`: when false the App runs frames back to back (the original's `ReceiveNextEvent` spin with a
    /// 0.001 s timeout instead of waiting for the 0.033 s timer — 00019122).
    public var limitFrames: Bool { cheats.limitFrames }
    /// `_gShowFPS`. `_PlayGame` never resets it: it lasts for the app's run, so the front end copies it from one
    /// session into the next.
    public var showFPS: Bool {
        get { cheats.showFPS }
        set { cheats.showFPS = newValue }
    }
    /// `_gGhostIcons` (`_SpriteToComp` plots `.ghost`).
    public var ghostIcons: Bool { state.presentation.ghostIcons }
    /// `_PauseGame`'s `local_2b` while paused, else nil.
    public var cheatBuffer: [UInt8]? { pause?.cheatBuffer }

    /// One 0.033 s frame with the shell's TickCount (the FPS readout counts against it). `frame(keys:)` uses the
    /// last TickCount seen.
    public func frame(keys: HeldKeys, now: UInt32) -> SessionOutput {
        noteTick(now)
        return frame(keys: keys)
    }

    // MARK: Driving (GameSession hooks)

    func noteTick(_ now: UInt32) {
        cheats.now = now
        if cheats.fpsLastTick == nil { cheats.fpsLastTick = now }
    }

    /// The end of a `_PlayGame` loop iteration (00019129): with `_gShowFPS`, count the frame; once TickCount has
    /// passed the last readout + 60, `_DrawFPS(count before this frame)` and restart at 0.
    func endOfLoopIteration() -> [DrawOp] {
        switch phase {
        case .paused:
            cheats.fpsDeferred = true
            return []
        case .playing:
            return fpsCheck()
        default:
            return []
        }
    }

    func fpsCheck() -> [DrawOp] {
        cheats.fpsDeferred = false
        guard cheats.showFPS else { return [] }
        let last = cheats.fpsLastTick ?? cheats.now
        guard last &+ 0x3c < cheats.now else {
            cheats.fpsFrames &+= 1
            return []
        }
        let count = cheats.fpsFrames
        cheats.fpsLastTick = cheats.now
        cheats.fpsFrames = 0
        return [.fps(Int(count))]
    }

    /// A key-down (event kind 3) while paused. ⌘ held → ignored (000178e8). While a cheat's `_Delay` blocks the
    /// pause loop the character waits in the queue.
    func cheatKeyTyped(_ char: UInt8, command: Bool) -> SessionOutput {
        guard phase == .paused, var p = pause, !command else { return SessionOutput() }
        if p.cheatScriptBusy {
            p.backlog.append(char)
            pause = p
            return SessionOutput()
        }
        pause = p
        enqueueCheat(char)
        return runCheatScript(now: cheats.now)
    }

    /// The buffer shift and the hash compare chain; queues the matching site's steps.
    private func enqueueCheat(_ char: UInt8) {
        guard var p = pause else { return }
        p.cheatBuffer.removeFirst()
        p.cheatBuffer.append(char)
        let h = Cheats.hash(p.cheatBuffer)
        if let effect = Cheats.effect(forHash: h) {
            p.steps = effect.steps
            if effect.setsPlayerIsCheating { playerIsCheating = true }
        }
        if h != Cheats.noHackHash { cheats.hacked = true }                 // 00017ec8 `_SetHacked(1)`
        pause = p
    }

    /// Runs queued steps until a `_Delay` is pending; then the queued characters. Called on every paused tick.
    func runCheatScript(now: UInt32) -> SessionOutput {
        var out = SessionOutput()
        while var p = pause {
            if let until = p.waitUntil {
                guard until <= now else { break }
                p.waitUntil = nil
                pause = p
                continue
            }
            if !p.steps.isEmpty {
                let step = p.steps.removeFirst()
                pause = p
                switch step {
                case let .sound(cue):
                    out.sounds.append(cue)
                case let .delay(ticks):
                    pause?.waitUntil = now &+ ticks
                case let .apply(effect):
                    out.append(applyCheat(effect))
                }
                continue
            }
            if !p.backlog.isEmpty {
                let c = p.backlog.removeFirst()
                pause = p
                enqueueCheat(c)
                continue
            }
            break
        }
        return out
    }

    /// The effect call of each site, with the cues and draw calls the callee makes.
    private func applyCheat(_ effect: Cheats.Effect) -> SessionOutput {
        switch effect {
        case .toggleFPS: cheats.showFPS.toggle()
        case .resetScore: state.cheatResetScore()
        case .daddyMode: cheats.daddyMode = true
        case .starBurst: state.cheatStarBurst(orbitTable: Self.orbitTable(data))
        case .toggleFrameLimit: cheats.limitFrames.toggle()
        case .regenerateBubbles: state.cheatRegenerateBlocks()
        case .endLevel: state.cheatEndLevel()
        case .toggleGhostIcons: state.cheatToggleGhostIcons()
        case .extraLife: state.cheatAddHero()
        case .addScore9000: state.cheatAddToScore(9000)
        case .invisibility: state.cheatSetHeroInvisibility()
        case .captureAll: state.cheatCaptureAllEnemies()
        case let .extraLetter(n): state.cheatEXTRAChange(n)
        case let .multiplier(v): state.cheatMultiplierChange(v)
        case .playAllSounds, .dogBark, .threeSquishes, .threeSqueaks: break
        }
        var out = SessionOutput()
        out.sounds = state.takeSounds()
        out.drawOps = state.takeCheatOps()
        return out
    }

    /// `_LoadOrbitData @ 000031a6`: `SPIN 1` memmoved raw into `gOrbit_Table` and read as native shorts — on i386 each
    /// big-endian pair is byte-swapped (data-formats §5). Nil when the data has no `SPIN 1` (the original stops at
    /// launch with `_DeathAlert(6)`).
    static func orbitTable(_ data: BTXGameData) -> [Int16]? {
        guard let bytes = data.data(type: "SPIN", id: 1) else { return nil }
        let b = [UInt8](bytes)
        return stride(from: 0, to: b.count - 1, by: 2).map { Int16(bitPattern: UInt16(b[$0]) | UInt16(b[$0 + 1]) << 8) }
    }
}

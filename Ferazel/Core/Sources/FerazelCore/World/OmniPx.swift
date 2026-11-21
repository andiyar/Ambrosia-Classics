import Foundation

/// One drawn frame's `.UpdateOmniPx @ 1001a434` (M l. 13393–13519; rendering-omnipx-titles §3.4), as `DrawOp.omniPx`
/// hands it to the renderer: the base cell copied over the 128×128 port, then each loaded face blitted at its (x, y)
/// — and, unless both are 0, at (x + 128, y), (x + 128, y + 128), (x, y + 128) so it wraps toroidally — in face-slot
/// order. The port is PxBack slot 0 while OmniPx is on (`.TurnOnOmniPx`, M l. 13055–13056).
public struct OmniPxFrame: Equatable, Sendable {
    /// One face's blit: `BlitEncFaceClipX(face, port, (0, 0), (y, x), 128, 128)` (M l. 13497–13504).
    public struct Face: Equatable, Sendable {
        /// The face's PICT (`.Load1EncFaceFromPICT(pict, 0, 0, 0)` at `.SetupOmniPx`, the level+sprite CLUT).
        public var pict: Int16
        /// x, y ∈ (−128, 128): the negated truncating remainder (M l. 13488–13496).
        public var x: Int
        public var y: Int

        public init(pict: Int16, x: Int, y: Int) {
            self.pict = pict; self.x = x; self.y = y
        }

        /// The blit points [x, y] in call order: (x, y), then the three wraps when x ≠ 0 or y ≠ 0 (M l. 13498–13505).
        public var draws: [[Int]] {
            guard x != 0 || y != 0 else { return [[x, y]] }
            return [[x, y], [x + 0x80, y], [x + 0x80, y + 0x80], [x, y + 0x80]]
        }
    }

    /// Header `0x26c7` (1, 2, 4 or 5 on a level that opens: `LevelRun.refuseUndrawnHeader`).
    public var omniPxMode: UInt8
    /// Modes 2 / 4 / 5: the PxBack slot `6 + (c >> 1)` copied over the port first (M l. 13429–13436); nil = no base
    /// (mode 1, 6A-RN: the port keeps what it held and the faces are blitted over it).
    public var baseCell: Int?
    /// The loaded faces' blits, face slots 0…15 in order (null faces skipped, M l. 13469).
    public var faces: [Face]

    public init(omniPxMode: UInt8, baseCell: Int?, faces: [Face]) {
        self.omniPxMode = omniPxMode; self.baseCell = baseCell; self.faces = faces
    }
}

/// What `DrawOp.omniPx` hands the renderer: OmniPx turned on at the level's set-up, or one drawn frame's update.
public enum OmniPxOp: Equatable, Sendable {
    /// The renderer's half of `.TurnOnOmniPx @ 10019ac4` (M l. 13019–13060), run by `.SetupOmniPx(0)` inside
    /// `.SetupLevel` (M l. 2540) — before the player spawn (M l. 5181) and before any frame, so the first frame's sprite
    /// pass already reads the zeroed PxBack factors and the port in slot 0 (`.CalcPxRowContents`, M l. 23165–23167).
    /// Once per level start, only when the level's mode turns OmniPx on (1, 2, 4, 5).
    case turnOn(omniPxMode: UInt8)
    /// One drawn frame's `.UpdateOmniPx` (`.PaintFrameWrap` M l. 9434).
    case update(OmniPxFrame)
}

/// OmniPx (header `0x26c7`; rendering-omnipx-titles §3, M l. 13019–13547): a 128×128 port that replaces PxBack cell 0
/// and is rebuilt on every drawn frame from an animated base (other PxBack cells) and up to 16 wrapping faces, each
/// scrolled by its own parallax factor and drift. Core holds the state — the mode, the 16 face refs, the six 16-entry
/// `Int16` arrays (fx `0x100a373c`, fy `375c`, vx `377c`, vy `379c`, accX `37bc`, accY `37dc`), the counter `c`
/// (`0x100f97e8`, BSS: never reset between levels — `LevelCarry.omniPxCounter`) and the factor backup
/// (`0x100f00a8` / `0x100f40a8`); the on-flag is G+0x174 (`GameGlobals.omniPxActive`). The port's pixels are Render's.
///
/// Life cycle (§3.2): `.SetupLevel` clears G+0x174 and calls `setup` (M l. 2539–2540); each drawn `.PaintFrameWrap`
/// calls `update` after `.DrawParticles` (M l. 9434); `.GameLoop`'s exit calls `turnOff` and `kill` (M l. 5321–5322).
/// Refused at level open (`LevelRun.refuseUndrawnHeader`): 6 interlace (◇ 6C-L55…L70); 3, 7, ≥ 8 unplaced. Mode 1 (the
/// rain sheets, level 15) opens since 6A-RN — faces only, no base; its weather is `OmniPxRain`.
public struct OmniPx: Equatable, Sendable {
    /// The 16 layer slots.
    public static let layers = 0x10
    /// The port's side.
    public static let size = 0x80

    /// Header `0x26c7`, as `.SetupOmniPx` read it (every reader re-reads the header byte; it never changes).
    public internal(set) var omniPxMode: UInt8 = 0
    /// `0x100a36fc`: the 16 face pointers, as the PICT each was loaded from (nil = none).
    public internal(set) var faces = [Int16?](repeating: nil, count: OmniPx.layers)
    /// Per-face parallax factors (/256) and drift (1/256 px per drawn frame), and the drift accumulators.
    public internal(set) var fx = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var fy = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var vx = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var vy = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var accX = [Int16](repeating: 0, count: OmniPx.layers)
    public internal(set) var accY = [Int16](repeating: 0, count: OmniPx.layers)
    /// `c`, the i16 at `0x100f97e8` (slot `PTR_DAT_100a008c`): loaded only by `.UpdateOmniPx`.
    public internal(set) var counter: Int16
    /// `0x100f00a8` (8192 i16) / `0x100f40a8`: `.TurnOnOmniPx`'s backup of hdr+0x326c / hdr+0xb26c. BSS: zero until a
    /// zeroing mode backs them up (Core keeps them per level; the copy back into an ending level is unseen, §3.2).
    /// The `yb` backup is 0 even then: the binary re-saves the zeroed field (`turnOn`).
    var backFactorsBackup = [Int16](repeating: 0, count: LevelFile.factorRows)
    var backYFactorBackup: Int16 = 0

    public init(counter: Int16 = 0) {
        self.counter = counter
    }

    /// The faces `.SetupOmniPx` loads for a mode (M l. 13246–13291), face 0 first: modes 2 and 4 → 6201 / 6200
    /// (`0x1839` / `0x1838`); 5 → 6301 / 6300 (`0x189d` / `0x189c`); 1 → 6000 / 6001 (`0x1770` / `0x1771`); every
    /// other mode none.
    public static func facePicts(omniPxMode m: UInt8) -> [Int16] {
        switch m {
        case 2, 4: return [0x1839, 0x1838]
        case 5: return [0x189d, 0x189c]
        case 1: return [0x1770, 0x1771]
        default: return []
        }
    }

    /// `.TurnOnOmniPx`'s test (M l. 13045): `mode != 4 && (byte)(mode − 5) > 2` — every mode outside 4…7 backs up and
    /// zeroes the PxBack factors (the grid fixed to the view, §3.5).
    public static func turnOnZeroesFactors(omniPxMode m: UInt8) -> Bool { m != 4 && m &- 5 > 2 }

    /// `.SetupOmniPx @ 10019d78` (M l. 13125–13297). The once-only clear of the 16 face pointers (`*0x100a00b0`, M l.
    /// 13158–13170) is this type's initial `faces`. Mode 0: G+0x174 = 0 and return. Else the port
    /// (`NewBlitPort(128, 128, level+sprite CLUT)`, Render's; its failure path — `ReportError`, off — is not
    /// reachable here), the six arrays zeroed, the mode's faces and parameters, then `.TurnOnOmniPx`.
    public mutating func setup(level: inout LevelFile, globals: inout GameGlobals) {
        omniPxMode = level.header.omniPxMode
        guard omniPxMode != 0 else {
            globals.omniPxActive = 0                                  // M l. 13172–13175
            return
        }
        let zero = [Int16](repeating: 0, count: Self.layers)          // M l. 13186–13238
        fx = zero; fy = zero; vx = zero; vy = zero; accX = zero; accY = zero
        let picts = Self.facePicts(omniPxMode: omniPxMode)
        for (i, p) in picts.enumerated() { faces[i] = p }
        switch omniPxMode {
        case 2, 4, 5:
            // M l. 13246–13256 (mode 5) and 13282–13291 (modes 2, 4): the same parameters.
            fx[0] = 0x40; fy[0] = 0x40; fx[1] = 0x80; fy[1] = 0x80
            vx[0] = -0x80; vy[0] = -0x200                            // 0xff80, 0xfe00
            vx[1] = 0x80; vy[1] = 0x400
        case 1:
            // M l. 13261–13277: faces 6000 / 6001. The stores to layers 3…5 (and `0x100a3802`, past the accY array)
            // are dead: those faces are never loaded, and the face loop skips a null face (§3.3).
            fx[0] = 0x40; fy[0] = 0x40; fx[1] = 0x80; fy[1] = 0x80
            vx[0] = 0x100; vy[0] = 0x500; vx[1] = 0x200; vy[1] = 0x800
            fx[3] = 0xc0; fy[3] = 0xc0; fx[4] = 0xd2; fy[4] = 0xd2; fx[5] = 0xe6; fy[5] = 0xe6
        default:
            break                                                     // 3, 6, 7, ≥ 8: no faces
        }
        turnOn(level: &level, globals: &globals)                     // LAB_1001a14c (M l. 13292–13293)
    }

    /// `.TurnOnOmniPx @ 10019ac4` (M l. 13019–13060): nothing when G+0x174 is already set; else set it and, for a mode
    /// outside 4…7, back up and zero the 8192 PxBack x-factors (hdr+0x326c) and `yb` (hdr+0xb26c) — Core's copy of
    /// the header, so every later Core read sees zeros. Saving PxBack slot 0 and storing the port there is Render's.
    public mutating func turnOn(level: inout LevelFile, globals: inout GameGlobals) {
        guard globals.omniPxActive == 0 else { return }
        globals.omniPxActive = 1
        guard Self.turnOnZeroesFactors(omniPxMode: level.header.omniPxMode) else { return }
        backFactorsBackup = level.backFactors
        level.backFactors = [Int16](repeating: 0, count: level.backFactors.count)
        // `yb`: the loop (M l. 13043–13054) saves and zeroes it on every one of its 8192 passes through a pointer it
        // never advances (`*puVar4 = hdr[0xb26c]`, M l. 13048; `hdr[0xb26c] = 0`, M l. 13050): pass 0 saves the real
        // value, then zeroes the field, and passes 1…0x1fff save that 0 over it — the backup ends 0, so
        // `.TurnOffOmniPx` restores `yb` as 0 (the bank, rendering-omnipx-titles §3.2, says it restores the value).
        level.header.pxBackYFactor = 0
        backYFactorBackup = level.header.pxBackYFactor                // the last pass's save: 0
    }

    /// `.TurnOffOmniPx @ 10019bac` (M l. 13061–13121): when G+0x174 is set, clear it and copy the backup back into
    /// hdr+0x326c / hdr+0xb26c — always, also after modes 4…7, whose backup is stale (§3.2: harmless, every level start
    /// re-reads `Mlvl`). `yb`'s backup is always 0 (`turnOn`), so `yb` comes back 0. Restoring PxBack slot 0 is
    /// Render's.
    public mutating func turnOff(level: inout LevelFile, globals: inout GameGlobals) {
        guard globals.omniPxActive != 0 else { return }
        globals.omniPxActive = 0
        level.backFactors = backFactorsBackup
        level.header.pxBackYFactor = backYFactorBackup
    }

    /// `.KillOmniPx @ 1001a86c` (M l. 13520–13547): every face disposed (the port is Render's).
    public mutating func kill() {
        faces = [Int16?](repeating: nil, count: Self.layers)
    }

    /// `.UpdateOmniPx @ 1001a434` (M l. 13393–13519) at scroll (h, v) (`PTR_DAT_1009fe78`): nil while G+0x174 is clear.
    /// Modes 2, 4, 5: `if c > 0x11 { c = 0 }`, then the base cell `6 + (c >> 1)` — c is not incremented there. Then
    /// each loaded face i: `c += 1`; `accX += vx`, `accY −= vy` as shorts, each > 0x7fff → − 0x8000 (never true of a
    /// short) and negative → − 0x8000 as a 16-bit short; x = −(((accX >> 8) + (H·fx >> 8)) rem 128), y likewise with
    /// accY, V and fy (truncating remainder, 16-bit results). No RNG.
    public mutating func update(globals: GameGlobals, h: Int, v: Int) -> OmniPxFrame? {
        guard globals.omniPxActive != 0 else { return nil }
        var base: Int?
        switch omniPxMode {
        case 2, 4, 5:
            if counter > 0x11 { counter = 0 }                         // M l. 13430–13432
            base = 6 + Int(counter >> 1)                              // `0x100a4f2c + 4·(c >> 1)` = slot 6 + (c >> 1)
        default:
            // later: Phase 6 (6C-L55…L70, level 70) — mode 6's `.InterlaceBlit128` base (M l. 13438–13446), its own `c`
            // step; mode 7's ping-pong copy (M l. 13447–13465) is on no level: unplaced, stays refused at level open.
            break
        }
        let H = Int32(Int16(truncatingIfNeeded: h)), V = Int32(Int16(truncatingIfNeeded: v))
        var drawn: [OmniPxFrame.Face] = []
        for i in 0..<Self.layers {
            guard let pict = faces[i] else { continue }
            counter &+= 1                                             // M l. 13471
            accX[i] = accX[i] &+ vx[i]                                // M l. 13474
            accY[i] = accY[i] &- vy[i]                                // M l. 13475
            // `if (0x7fff < acc) acc −= 0x8000` (M l. 13476–13481): a short is never above 0x7fff.
            if accX[i] < 0 { accX[i] = Int16(truncatingIfNeeded: Int(accX[i]) - 0x8000) }   // M l. 13482–13484
            if accY[i] < 0 { accY[i] = Int16(truncatingIfNeeded: Int(accY[i]) - 0x8000) }   // M l. 13485–13487
            drawn.append(OmniPxFrame.Face(pict: pict, x: Self.offset(acc: accX[i], scroll: H, factor: fx[i]),
                                          y: Self.offset(acc: accY[i], scroll: V, factor: fy[i])))
        }
        return OmniPxFrame(omniPxMode: omniPxMode, baseCell: base, faces: drawn)
    }

    /// `u = (acc >> 8) + (scroll·factor >> 8)` (int), then `−((short)u + (short)(u / 128)·−0x80)` as a short — the
    /// negated truncating remainder (M l. 13488–13496).
    static func offset(acc: Int16, scroll: Int32, factor: Int16) -> Int {
        let u = Int32(acc >> 8) &+ ((scroll &* Int32(factor)) >> 8)
        let r = Int32(Int16(truncatingIfNeeded: u)) &+ Int32(Int16(truncatingIfNeeded: u / 0x80)) &* -0x80
        return Int(Int16(truncatingIfNeeded: -r))
    }
}

/// 6A-RN: `.GenerateRain @ 100109c0` (M l. 8429–8531; ENG §2.7) — OmniPx mode 1's weather (level 15, "Storm Valley").
/// `.PaintFrameWrap` calls it on every pass while header `0x26c7` is 1 (M l. 9228–9229, raw `10011ee4..10011ef0`:
/// after `.WrapDrawSprites`, before the drawn-frame test) — drawn or not, and on the extra passes `.Pause` (M l. 3190)
/// and `.CheckGameLoopKeys`' dialogs make (M l. 3918, 3922, 3980, 4005). The session holds the state; the call runs on
/// the world (the stream, the particle pool, the flash, the async fade, the sound calls).
///
/// - First call (`*_DAT_1009fe88 == 0`): the flag set; T = R(90) + 90; `.STPlayLoopedSound(snd 452, 1, 0x55)` — the
///   rain loop (M l. 8449–8454; no stream draw: `.STPlayLoopedSound`, M l. 40978ff, draws nothing, sound on or off).
///   The flag is cleared by `.SetupLevel` after `.SetupOmniPx` (M l. 2541: a new session), by `.Pause` after it stops
///   the voices (M l. 3203: `FerazelSession.clearRainFirstCall`, called by `LevelRun` right after `PauseRun.painted`)
///   and by `.GameLoop`'s exit (M l. 5300).
/// - Thunder (M l. 8456–8480), T after the first-call block: T > 0 → T − 1; T = 0 → the flash count 3
///   (`ScreenFlash`), `.STPlayRegSound(snd 453, 1, 0xab)`, T = −1; −1 → −2; −2 → `.GammaFadeOutAsync(2, white)`
///   (the six bytes at `0x100a53ca`, FFFF ×3; r6 / r7 0xc / 0x10 unread), three `.HandleAsyncGammaFade`,
///   `.GammaFadeInAsync(0x6e)`, T = −3 — each gated on fading enabled and the faded flag (`AsyncGammaFade`); T < −2
///   → T = R(150) + 210.
/// - Drops (M l. 8481–8527): x = H + R(50); while x < H + 660: s = R(2); the point (v = V, h = x); three
///   `.NewParticle(kind, 0, point, shape, vx, vy, 0, mode 1)` — s = 0 heavy: shape 5, vx −1200, vy 3600, kinds 7, 6,
///   5, the point moved v + 4, h − 1 before each of the next two; s = 1 light: shape 4, vx −700, vy 2100, kinds 7, 7,
///   6, before each of the next two R(100) > 50 → h − 1, then v + 2. Then x += R(200) + 50. (H, V) is the scroll point
///   `PTR_DAT_1009fe78`; every coordinate is a 16-bit short.
public struct OmniPxRain: Equatable, Sendable {
    /// snd 452 (`*_DAT_1009fe24`), the looped rain; snd 453 (`*_DAT_1009fd68`), the thunder.
    public static let rainLoop: Int16 = 452
    public static let thunder: Int16 = 453
    /// `.GammaFadeOutAsync(2, …)`'s colour: the six bytes at `0x100a53ca` (the save point's flash colour).
    public static let thunderColour = HitPlayerSprite.savePointFlashColour

    /// `*_DAT_1009fe88`: the first call has been made.
    public internal(set) var started = false
    /// `sRam100a381c`: the thunder timer T.
    public internal(set) var timer: Int16 = 0
    /// The stream (`_DAT_100a17e8`) as the last call found it on entry — for tests, which re-derive every draw.
    public internal(set) var entrySeed: Int32 = 0

    public init() {}

    /// One `.GenerateRain` call at scroll point (h, v): its `.HandleAsyncGammaFade` steps and the `HideCursorSafe` a
    /// fade-out arm makes (M l. 31905), in call order.
    public mutating func generate(world w: SpriteWorld, h: Int, v: Int) -> (draws: [DrawOp], requests: [ShellRequest]) {
        entrySeed = w.rng.seed
        var draws: [DrawOp] = [], requests: [ShellRequest] = []
        if !started {                                                 // M l. 8449–8454
            started = true
            timer = w.rng.next(0x5a) &+ 0x5a
            w.player.cue(PlayerCue(call: .looped, snd: Self.rainLoop, priority: 1, volume: 0x55))
        }
        if timer < 1 {                                                // M l. 8456–8480
            if timer == 0 {
                w.flash.count = 3                                     // `*_DAT_100a00fc = 3`
                w.player.cue(PlayerCue(call: .reg, snd: Self.thunder, priority: 1, volume: 0xab))
                timer &-= 1
            } else if timer == -1 {
                timer = -2
            } else if timer == -2 {
                if w.gammaFade.fadeOut(steps: 2, toward: Self.thunderColour) { requests.append(.hideCursor) }
                for _ in 0..<3 { if let op = w.gammaFade.handle() { draws.append(op) } }
                w.gammaFade.fadeIn(steps: 0x6e)
                timer &-= 1
            } else {
                timer = w.rng.next(0x96) &+ 0xd2
            }
        } else {
            timer &-= 1
        }
        // The drops (M l. 8481–8530): `sVar4` and the point's halves are shorts; the loop test is an int compare
        // `H + 0x294 <= sVar4` with H the scroll point's h (a short).
        let H = Int16(truncatingIfNeeded: h), V = Int16(truncatingIfNeeded: v)
        var x = H &+ w.rng.next(0x32)
        while !(Int(H) + 0x294 <= Int(x)) {
            let light = w.rng.next(2) != 0                            // `sVar5`: 0 heavy, 1 light
            let shape = light ? 4 : 5
            let vx = light ? -700 : -0x4b0
            let vy = light ? 0x834 : 0xe10
            var pv = V, ph = x
            func particle(_ kind: Int) {
                w.particles.newParticle(kind: kind, gravity: 0, v: Int(pv), h: Int(ph), shape: shape, vx: vx, vy: vy,
                                        delay: 0, mode: 1)
            }
            /// Between two particles: light → `R(100) > 0x32` → h − 1, then v + 2; heavy → v + 4, h − 1.
            func move() {
                if light {
                    if 0x32 < w.rng.next(100) { ph &-= 1 }
                    pv &+= 2
                } else {
                    pv &+= 4
                    ph &-= 1
                }
            }
            particle(7)
            move()
            particle(light ? 7 : 6)
            move()
            particle(light ? 6 : 5)
            x = w.rng.next(200) &+ x &+ 0x32
        }
        return (draws, requests)
    }
}
